const express = require('express');
const Razorpay = require('razorpay');
const stripe = require('stripe')('sk_test_your_stripe_secret_key_here'); // Replace with your Stripe secret key
const { spawn } = require('child_process'); // For AI processing
const multer = require('multer'); // For file uploads
const path = require('path');
const fs = require('fs');
const axios = require('axios'); // For external API calls
const jwt = require('jsonwebtoken'); // For authentication
const bcrypt = require('bcryptjs'); // For password hashing
const cors = require('cors'); // For CORS handling
const rateLimit = require('express-rate-limit'); // For rate limiting
const WebSocket = require('ws'); // For real-time features

const app = express();

// Middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(cors());
app.use('/uploads', express.static('uploads'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Limit each IP to 1000 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// Configure multer for file uploads
const upload = multer({ 
  dest: 'uploads/',
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  }
});

// Initialize payment gateways
const instance = new Razorpay({
  key_id: 'rzp_test_Rdhn5hZVFSFF2q',
  key_secret: 'lDYxL4Lf7mk1zvy4OlyBXVmP'
});

// ===============================
// AI RECOMMENDATION ENGINE APIs
// ===============================

// Get personalized recommendations
app.post('/ai/recommendations', async (req, res) => {
  try {
    const { userId, limit = 10, context = {} } = req.body;
    
    // Simulate AI processing
    const pythonProcess = spawn('python3', [
      'ai/ai_recommendation_engine.py',
      userId,
      limit.toString(),
      JSON.stringify(context)
    ]);
    
    let output = '';
    let error = '';
    
    pythonProcess.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    pythonProcess.stderr.on('data', (data) => {
      error += data.toString();
    });
    
    pythonProcess.on('close', (code) => {
      if (code === 0) {
        try {
          const recommendations = JSON.parse(output);
          res.json({
            success: true,
            data: recommendations,
            timestamp: new Date().toISOString()
          });
        } catch (e) {
          res.status(500).json({ error: 'Failed to parse AI recommendations' });
        }
      } else {
        console.error('AI Error:', error);
        res.status(500).json({ error: 'AI recommendation engine error' });
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get trending products
app.get('/ai/trending', async (req, res) => {
  try {
    const { limit = 10, timeRange = '7d' } = req.query;
    
    // Mock trending data - in production, this would use analytics
    const trendingProducts = [
      {
        id: 'prod_1',
        name: 'AI-Detected Viral Burger',
        trending_score: 95,
        order_count: 1247,
        growth_rate: 234,
        image_url: '/images/trending-burger.jpg'
      },
      {
        id: 'prod_2',
        name: 'Smart Suggested Pizza',
        trending_score: 89,
        order_count: 892,
        growth_rate: 156,
        image_url: '/images/trending-pizza.jpg'
      }
    ];
    
    res.json({
      success: true,
      data: trendingProducts,
      metadata: {
        timeRange,
        generated_at: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get contextual recommendations
app.post('/ai/contextual', async (req, res) => {
  try {
    const { 
      userId, 
      timeOfDay, 
      weather, 
      location, 
      mood,
      limit = 5 
    } = req.body;
    
    // AI contextual processing
    const contextData = {
      timeOfDay,
      weather,
      location,
      mood,
      userId,
      timestamp: new Date().toISOString()
    };
    
    const pythonProcess = spawn('python3', [
      'ai/contextual_recommendations.py',
      JSON.stringify(contextData),
      limit.toString()
    ]);
    
    let output = '';
    pythonProcess.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    pythonProcess.on('close', (code) => {
      if (code === 0) {
        const recommendations = JSON.parse(output);
        res.json({
          success: true,
          data: recommendations,
          context: contextData
        });
      } else {
        res.status(500).json({ error: 'Contextual AI processing failed' });
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// VOICE PROCESSING APIs
// ===============================

// Process voice order
app.post('/ai/voice/order', upload.single('voiceFile'), async (req, res) => {
  try {
    const { userId, language = 'en' } = req.body;
    const voiceFile = req.file;
    
    if (!voiceFile) {
      return res.status(400).json({ error: 'Voice file is required' });
    }
    
    // Voice-to-text processing
    const pythonProcess = spawn('python3', [
      'ai/voice_processor.py',
      voiceFile.path,
      language,
      'order'
    ]);
    
    let output = '';
    pythonProcess.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    pythonProcess.on('close', async (code) => {
      if (code === 0) {
        try {
          const voiceResult = JSON.parse(output);
          
          // Parse order from voice text
          const orderItems = await _parseOrderFromVoice(voiceResult.text);
          
          res.json({
            success: true,
            data: {
              original_text: voiceResult.text,
              processed_order: orderItems,
              confidence_score: voiceResult.confidence,
              language_detected: voiceResult.language
            }
          });
        } catch (e) {
          res.status(500).json({ error: 'Failed to process voice order' });
        }
      } else {
        res.status(500).json({ error: 'Voice processing failed' });
      }
      
      // Clean up uploaded file
      fs.unlink(voiceFile.path, () => {});
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Voice commands processing
app.post('/ai/voice/command', async (req, res) => {
  try {
    const { voiceText, userId } = req.body;
    
    // NLP processing for voice commands
    const command = await _processVoiceCommand(voiceText);
    
    res.json({
      success: true,
      data: {
        command: command.intent,
        parameters: command.parameters,
        confidence: command.confidence,
        action_required: command.actionRequired
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// REAL-TIME CHAT APIs
// ===============================

// Create chat room
app.post('/chat/room', async (req, res) => {
  try {
    const { 
      name, 
      type, 
      participants, 
      createdBy,
      metadata = {} 
    } = req.body;
    
    const roomId = `room_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const chatRoom = {
      id: roomId,
      name,
      type,
      participants,
      createdBy,
      createdAt: new Date().toISOString(),
      metadata,
      status: 'active',
      lastActivity: new Date().toISOString()
    };
    
    // In production, save to database
    // await db.collection('chatRooms').doc(roomId).set(chatRoom);
    
    res.json({
      success: true,
      data: chatRoom
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message
app.post('/chat/message', async (req, res) => {
  try {
    const { 
      chatRoomId, 
      senderId, 
      type = 'text', 
      content, 
      attachments = [],
      metadata = {} 
    } = req.body;
    
    const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const message = {
      id: messageId,
      chatRoomId,
      senderId,
      type,
      content,
      attachments,
      timestamp: new Date().toISOString(),
      status: 'sent',
      metadata,
      reactions: [],
      replyTo: null
    };
    
    // Save to database and broadcast to WebSocket clients
    // await db.collection('messages').doc(messageId).set(message);
    // broadcastToRoom(chatRoomId, 'new_message', message);
    
    res.json({
      success: true,
      data: message
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// AR/VR EXPERIENCE APIs
// ===============================

// Generate AR menu items
app.post('/ar/generate', async (req, res) => {
  try {
    const { restaurantId, menuItems } = req.body;
    
    const arItems = [];
    
    for (const item of menuItems) {
      // Generate 3D model data
      const arData = await _generateARModel(item);
      arItems.push({
        productId: item.id,
        arModel: arData,
        placementInstructions: arData.placement,
        animation: arData.animation,
        nutritionalOverlay: arData.nutrition
      });
    }
    
    res.json({
      success: true,
      data: arItems,
      restaurantId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// ROUTE OPTIMIZATION APIs
// ===============================

// Optimize delivery route
app.post('/routes/optimize', async (req, res) => {
  try {
    const { 
      deliveryIds, 
      startLocation, 
      endLocation,
      constraints = {} 
    } = req.body;
    
    // Route optimization using AI
    const optimizedRoute = await _optimizeRoute({
      deliveries: deliveryIds,
      start: startLocation,
      end: endLocation,
      constraints
    });
    
    res.json({
      success: true,
      data: optimizedRoute,
      estimatedTime: optimizedRoute.totalTime,
      estimatedDistance: optimizedRoute.totalDistance
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// SMART NOTIFICATION APIs
// ===============================

// Send AI-powered notification
app.post('/notifications/send', async (req, res) => {
  try {
    const { 
      userId, 
      type, 
      content, 
      data = {},
      scheduled = false,
      scheduleTime = null
    } = req.body;
    
    // AI-powered notification processing
    const notification = {
      id: `notif_${Date.now()}`,
      userId,
      type,
      content: await _enhanceNotificationContent(content, type, userId),
      data,
      timestamp: new Date().toISOString(),
      status: 'pending',
      ai_optimized: true
    };
    
    if (scheduled && scheduleTime) {
      // Schedule for later
      notification.scheduledFor = scheduleTime;
      // Add to scheduled notifications queue
    } else {
      // Send immediately
      await _sendNotification(notification);
    }
    
    res.json({
      success: true,
      data: notification
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// DYNAMIC PRICING APIs
// ===============================

// Calculate dynamic price
app.post('/pricing/calculate', async (req, res) => {
  try {
    const { 
      productId, 
      restaurantId, 
      currentDemand,
      userId,
      timeOfDay 
    } = req.body;
    
    // AI-powered dynamic pricing
    const priceCalculation = await _calculateDynamicPrice({
      productId,
      restaurantId,
      demand: currentDemand,
      userId,
      timestamp: new Date(),
      timeOfDay
    });
    
    res.json({
      success: true,
      data: priceCalculation
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// QR CODE DELIVERY APIs
// ===============================

// Generate delivery QR code
app.post('/qr/generate', async (req, res) => {
  try {
    const { 
      orderId, 
      deliveryId, 
      customerId, 
      deliveryInstructions = '' 
    } = req.body;
    
    const qrData = {
      orderId,
      deliveryId,
      customerId,
      timestamp: Date.now(),
      signature: await _generateQRCodeSignature(orderId, deliveryId),
      deliveryInstructions
    };
    
    const qrCodeUrl = await _generateQRCode(qrData);
    
    res.json({
      success: true,
      data: {
        qrCode: qrCodeUrl,
        qrData,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000) // 30 minutes
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// SUSTAINABILITY APIs
// ===============================

// Calculate carbon footprint
app.post('/sustainability/calculate', async (req, res) => {
  try {
    const { 
      orderItems, 
      deliveryDistance, 
      packagingType = 'standard' 
    } = req.body;
    
    const footprint = await _calculateCarbonFootprint({
      items: orderItems,
      distance: deliveryDistance,
      packaging: packagingType
    });
    
    res.json({
      success: true,
      data: footprint,
      recommendations: footprint.recommendations
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// LOYALTY SYSTEM APIs
// ===============================

// Process loyalty points
app.post('/loyalty/process', async (req, res) => {
  try {
    const { 
      userId, 
      action, 
      amount, 
      orderId, 
      metadata = {} 
    } = req.body;
    
    const loyaltyResult = await _processLoyaltyPoints({
      userId,
      action,
      amount,
      orderId,
      metadata
    });
    
    res.json({
      success: true,
      data: loyaltyResult
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// PAYMENT PROCESSING APIs
// ===============================

// Razorpay order creation
app.post('/create-order', async (req, res) => {
  const { amount, currency = 'INR', metadata = {} } = req.body;
  
  try {
    const options = {
      amount: amount * 100, // Amount in paise
      currency,
      receipt: `receipt_${Date.now()}`,
      notes: metadata
    };

    const order = await instance.orders.create(options);
    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Razorpay payment verification
app.post('/verify-payment', async (req, res) => {
  const { 
    razorpay_order_id, 
    razorpay_payment_id, 
    razorpay_signature 
  } = req.body;
  
  try {
    const generatedSignature = crypto
      .createHmac('sha256', 'lDYxL4Lf7mk1zvy4OlyBXVmP')
      .update(razorpay_order_id + "|" + razorpay_payment_id)
      .digest('hex');
    
    if (generatedSignature === razorpay_signature) {
      // Payment verified successfully
      await _processSuccessfulPayment(razorpay_order_id);
      res.json({ success: true, message: "Payment verified successfully" });
    } else {
      res.status(400).json({ success: false, message: "Invalid signature" });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Stripe payment intent
app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency = 'usd', metadata = {} } = req.body;
  
  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Amount in cents
      currency,
      metadata,
      automatic_payment_methods: {
        enabled: true,
      },
    });
    
    res.json({
      clientSecret: paymentIntent.client_secret,
      id: paymentIntent.id
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// SCHEDULED DELIVERY APIs
// ===============================

// Create scheduled delivery
app.post('/scheduled/create', async (req, res) => {
  try {
    const { 
      userId, 
      restaurantId, 
      items, 
      scheduledDateTime, 
      type = 'scheduled',
      specialInstructions = '' 
    } = req.body;
    
    const scheduledOrder = await _createScheduledDelivery({
      userId,
      restaurantId,
      items,
      scheduledDateTime,
      type,
      specialInstructions
    });
    
    res.json({
      success: true,
      data: scheduledOrder
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get available time slots
app.get('/scheduled/slots', async (req, res) => {
  try {
    const { restaurantId, date, orderCount = 1 } = req.query;
    
    const availableSlots = await _getAvailableTimeSlots({
      restaurantId,
      date,
      orderCount: parseInt(orderCount)
    });
    
    res.json({
      success: true,
      data: availableSlots
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// ANALYTICS & REPORTING APIs
// ===============================

// Get AI insights
app.get('/analytics/insights', async (req, res) => {
  try {
    const { 
      timeRange = '7d', 
      metric = 'sales',
      granularity = 'daily' 
    } = req.query;
    
    const insights = await _generateAIInsights({
      timeRange,
      metric,
      granularity
    });
    
    res.json({
      success: true,
      data: insights,
      ai_analyzed: true
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// HEALTH CHECK & MONITORING
// ===============================

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
    ai_features: {
      recommendations: 'active',
      voice_processing: 'active',
      route_optimization: 'active',
      smart_notifications: 'active',
      dynamic_pricing: 'active'
    }
  });
});

// ===============================
// UTILITY FUNCTIONS
// ===============================

// Mock AI functions (in production, these would be real AI services)
async function _parseOrderFromVoice(text) {
  // Simulate NLP parsing
  return {
    items: [
      { name: 'Burger', quantity: 2, size: 'large' },
      { name: 'Fries', quantity: 1, size: 'medium' }
    ],
    total_estimated: 25.99,
    confidence: 0.92
  };
}

async function _processVoiceCommand(text) {
  return {
    intent: 'order_status',
    parameters: { orderId: 'ORD123' },
    confidence: 0.88,
    actionRequired: true
  };
}

async function _generateARModel(menuItem) {
  return {
    model_url: `/ar/models/${menuItem.id}.glb`,
    placement: {
      position: { x: 0, y: 0, z: 0 },
      scale: 1.0,
      rotation: { x: 0, y: 0, z: 0 }
    },
    animation: 'spin_360',
    nutrition: {
      calories: 450,
      protein: 25,
      carbs: 35,
      fat: 18
    }
  };
}

async function _optimizeRoute({ deliveries, start, end, constraints }) {
  return {
    route: deliveries,
    totalTime: 45, // minutes
    totalDistance: 12.5, // km
    estimatedFuel: 2.1, // liters
    costEstimate: 15.75
  };
}

async function _enhanceNotificationContent(content, type, userId) {
  // AI-powered content enhancement
  return `Personalized: ${content} for user ${userId}`;
}

async function _sendNotification(notification) {
  console.log('Sending notification:', notification);
}

async function _calculateDynamicPrice({ productId, demand, userId, timestamp }) {
  return {
    originalPrice: 19.99,
    dynamicPrice: 22.49,
    priceChange: +2.50,
    factors: {
      demand_surge: +1.50,
      time_of_day: +0.50,
      user_preference: +0.50
    }
  };
}

async function _generateQRCode(data) {
  // Mock QR code generation
  return `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(JSON.stringify(data))}`;
}

async function _generateQRCodeSignature(orderId, deliveryId) {
  return crypto
    .createHash('sha256')
    .update(orderId + deliveryId + 'secret_key')
    .digest('hex');
}

async function _calculateCarbonFootprint({ items, distance, packaging }) {
  return {
    total_co2: 2.3, // kg
    breakdown: {
      food_production: 1.8,
      delivery: 0.3,
      packaging: 0.2
    },
    recommendations: [
      'Choose eco-friendly packaging',
      'Opt for bicycle delivery',
      'Select local restaurants'
    ]
  };
}

async function _processLoyaltyPoints({ userId, action, amount, orderId }) {
  return {
    pointsEarned: Math.floor(amount * 0.1),
    totalPoints: 1250,
    nextRewardAt: 1500,
    tier: 'Gold'
  };
}

async function _processSuccessfulPayment(orderId) {
  console.log('Processing successful payment for:', orderId);
}

async function _createScheduledDelivery({ userId, restaurantId, items, scheduledDateTime, type }) {
  return {
    id: `sched_${Date.now()}`,
    userId,
    restaurantId,
    items,
    scheduledDateTime,
    type,
    status: 'confirmed',
    confirmationCode: 'CONF123456'
  };
}

async function _getAvailableTimeSlots({ restaurantId, date, orderCount }) {
  return [
    {
      id: 'slot_1',
      startTime: '18:00',
      endTime: '19:00',
      available: true,
      capacity: 5,
      currentOrders: 2
    },
    {
      id: 'slot_2',
      startTime: '19:00',
      endTime: '20:00',
      available: true,
      capacity: 3,
      currentOrders: 1
    }
  ];
}

async function _generateAIInsights({ timeRange, metric, granularity }) {
  return {
    summary: 'Sales increased 15% week-over-week',
    trends: [
      { date: '2024-01-01', value: 1200 },
      { date: '2024-01-02', value: 1350 }
    ],
    recommendations: [
      'Increase burger inventory',
      'Extend evening hours'
    ]
  };
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`AI-Powered Food App Backend running on port ${PORT}`);
  console.log('AI Features Available:');
  console.log('✅ AI Recommendations');
  console.log('✅ Voice Processing');
  console.log('✅ Real-time Chat');
  console.log('✅ AR/VR Experience');
  console.log('✅ Route Optimization');
  console.log('✅ Smart Notifications');
  console.log('✅ Dynamic Pricing');
  console.log('✅ QR Code Delivery');
  console.log('✅ Sustainability Tracking');
  console.log('✅ Loyalty System');
  console.log('✅ Scheduled Deliveries');
});