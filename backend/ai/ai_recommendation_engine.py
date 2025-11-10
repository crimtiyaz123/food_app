#!/usr/bin/env python3
"""
AI-Powered Food Recommendation Engine
Advanced machine learning system for personalized food recommendations
"""

import json
import sys
import os
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import pickle
import warnings
warnings.filterwarnings('ignore')

# Import ML libraries
try:
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity
    from sklearn.cluster import KMeans
    from sklearn.preprocessing import StandardScaler
    from sklearn.decomposition import PCA
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.model_selection import train_test_split
except ImportError as e:
    print(f"Warning: Some ML libraries not available: {e}")

class AIRecommendationEngine:
    def __init__(self):
        self.user_profiles = {}
        self.product_features = {}
        self.interaction_matrix = None
        self.tfidf_vectorizer = TfidfVectorizer(max_features=1000, stop_words='english')
        self.collaborative_model = None
        self.content_model = None
        self.hybrid_model = None
        self.load_models()
    
    def load_models(self):
        """Load pre-trained models or create new ones"""
        try:
            if os.path.exists('models/user_profiles.pkl'):
                with open('models/user_profiles.pkl', 'rb') as f:
                    self.user_profiles = pickle.load(f)
            
            if os.path.exists('models/product_features.pkl'):
                with open('models/product_features.pkl', 'rb') as f:
                    self.product_features = pickle.load(f)
                    
            print("✅ AI models loaded successfully")
        except Exception as e:
            print(f"📊 Initializing new AI models: {e}")
            self.initialize_default_models()
    
    def initialize_default_models(self):
        """Initialize default models with sample data"""
        # Sample user profiles
        self.user_profiles = {
            'user_123': {
                'preferences': ['italian', 'spicy', 'vegetarian'],
                'order_history': ['pizza', 'pasta', 'salad'],
                'dietary_restrictions': [],
                'price_sensitivity': 0.7,
                'order_frequency': 3.2,
                'avg_order_value': 25.50
            }
        }
        
        # Sample product features
        self.product_features = {
            'product_1': {
                'cuisine': 'italian',
                'spice_level': 2,
                'is_vegetarian': True,
                'price': 15.99,
                'rating': 4.5,
                'tags': ['pizza', 'cheese', 'vegetarian']
            }
        }
    
    def get_personalized_recommendations(self, user_id, limit=10, context=None):
        """Get personalized recommendations using hybrid approach"""
        try:
            # Get user profile
            user_profile = self.get_user_profile(user_id)
            
            # Content-based filtering
            content_recommendations = self.content_based_filtering(user_profile, limit)
            
            # Collaborative filtering
            collaborative_recommendations = self.collaborative_filtering(user_id, limit)
            
            # Contextual filtering
            contextual_recommendations = self.contextual_filtering(user_profile, context, limit)
            
            # Hybrid scoring
            final_recommendations = self.hybrid_scoring(
                content_recommendations,
                collaborative_recommendations, 
                contextual_recommendations,
                user_profile
            )
            
            # Apply business rules and post-processing
            final_recommendations = self.apply_business_rules(final_recommendations, user_profile)
            
            return {
                'recommendations': final_recommendations[:limit],
                'metadata': {
                    'user_id': user_id,
                    'method': 'hybrid_ai',
                    'confidence_score': self.calculate_confidence_score(final_recommendations),
                    'timestamp': datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            print(f"❌ Error in AI recommendations: {e}")
            return self.get_fallback_recommendations(limit)
    
    def get_user_profile(self, user_id):
        """Get or create user profile"""
        if user_id not in self.user_profiles:
            self.user_profiles[user_id] = {
                'preferences': [],
                'order_history': [],
                'dietary_restrictions': [],
                'price_sensitivity': 0.5,
                'order_frequency': 1.0,
                'avg_order_value': 20.0,
                'last_updated': datetime.now().isoformat()
            }
        
        return self.user_profiles[user_id]
    
    def content_based_filtering(self, user_profile, limit):
        """Content-based filtering using user preferences"""
        recommendations = []
        
        for product_id, features in self.product_features.items():
            # Calculate similarity score
            score = self.calculate_content_similarity(user_profile, features)
            
            if score > 0.3:  # Minimum threshold
                recommendations.append({
                    'product_id': product_id,
                    'score': score,
                    'method': 'content_based',
                    'reasons': self.get_content_reasons(user_profile, features)
                })
        
        # Sort by score and return top results
        recommendations.sort(key=lambda x: x['score'], reverse=True)
        return recommendations[:limit]
    
    def collaborative_filtering(self, user_id, limit):
        """Collaborative filtering using similar users"""
        recommendations = []
        
        # Find similar users (simplified approach)
        similar_users = self.find_similar_users(user_id)
        
        for similar_user in similar_users:
            # Get products liked by similar users
            similar_user_orders = self.get_user_orders(similar_user)
            for product_id in similar_user_orders:
                if product_id not in [r['product_id'] for r in recommendations]:
                    score = self.calculate_collaborative_score(user_id, similar_user, product_id)
                    recommendations.append({
                        'product_id': product_id,
                        'score': score,
                        'method': 'collaborative',
                        'based_on_user': similar_user
                    })
        
        recommendations.sort(key=lambda x: x['score'], reverse=True)
        return recommendations[:limit]
    
    def contextual_filtering(self, user_profile, context, limit):
        """Contextual filtering based on time, weather, location"""
        if not context:
            return []
        
        recommendations = []
        context_score = 0.0
        
        for product_id, features in self.product_features.items():
            score = 0.0
            reasons = []
            
            # Time-based context
            if 'time_of_day' in context:
                time_score = self.get_time_context_score(features, context['time_of_day'])
                score += time_score * 0.3
                if time_score > 0:
                    reasons.append(f"Time appropriate ({context['time_of_day']})")
            
            # Weather-based context
            if 'weather' in context:
                weather_score = self.get_weather_context_score(features, context['weather'])
                score += weather_score * 0.25
                if weather_score > 0:
                    reasons.append(f"Weather suitable ({context['weather']})")
            
            # Location-based context
            if 'location' in context:
                location_score = self.get_location_context_score(features, context['location'])
                score += location_score * 0.2
                if location_score > 0:
                    reasons.append("Local preference")
            
            # Mood-based context
            if 'mood' in context:
                mood_score = self.get_mood_context_score(features, context['mood'])
                score += mood_score * 0.25
                if mood_score > 0:
                    reasons.append(f"Mood matching ({context['mood']})")
            
            if score > 0.1:  # Minimum contextual threshold
                recommendations.append({
                    'product_id': product_id,
                    'score': score,
                    'method': 'contextual',
                    'reasons': reasons
                })
        
        recommendations.sort(key=lambda x: x['score'], reverse=True)
        return recommendations[:limit]
    
    def hybrid_scoring(self, content_recs, collab_recs, context_recs, user_profile):
        """Combine all recommendation methods using hybrid scoring"""
        all_recommendations = {}
        
        # Weight different methods
        weights = {
            'content_based': 0.4,
            'collaborative': 0.35,
            'contextual': 0.25
        }
        
        # Process content-based recommendations
        for rec in content_recs:
            product_id = rec['product_id']
            if product_id not in all_recommendations:
                all_recommendations[product_id] = {
                    'product_id': product_id,
                    'total_score': 0.0,
                    'method_scores': {},
                    'all_reasons': []
                }
            
            all_recommendations[product_id]['total_score'] += rec['score'] * weights['content_based']
            all_recommendations[product_id]['method_scores']['content_based'] = rec['score']
            all_recommendations[product_id]['all_reasons'].extend(rec.get('reasons', []))
        
        # Process collaborative recommendations
        for rec in collab_recs:
            product_id = rec['product_id']
            if product_id not in all_recommendations:
                all_recommendations[product_id] = {
                    'product_id': product_id,
                    'total_score': 0.0,
                    'method_scores': {},
                    'all_reasons': []
                }
            
            all_recommendations[product_id]['total_score'] += rec['score'] * weights['collaborative']
            all_recommendations[product_id]['method_scores']['collaborative'] = rec['score']
            all_recommendations[product_id]['all_reasons'].append(f"Similar users liked this")
        
        # Process contextual recommendations
        for rec in context_recs:
            product_id = rec['product_id']
            if product_id not in all_recommendations:
                all_recommendations[product_id] = {
                    'product_id': product_id,
                    'total_score': 0.0,
                    'method_scores': {},
                    'all_reasons': []
                }
            
            all_recommendations[product_id]['total_score'] += rec['score'] * weights['contextual']
            all_recommendations[product_id]['method_scores']['contextual'] = rec['score']
            all_recommendations[product_id]['all_reasons'].extend(rec.get('reasons', []))
        
        # Apply personalization boost based on user profile
        for rec in all_recommendations.values():
            personalization_boost = self.get_personalization_boost(rec, user_profile)
            rec['total_score'] *= personalization_boost
            rec['personalization_boost'] = personalization_boost
        
        # Convert to sorted list
        final_recommendations = list(all_recommendations.values())
        final_recommendations.sort(key=lambda x: x['total_score'], reverse=True)
        
        return final_recommendations
    
    def apply_business_rules(self, recommendations, user_profile):
        """Apply business rules and filters"""
        filtered_recommendations = []
        
        for rec in recommendations:
            product_id = rec['product_id']
            features = self.product_features.get(product_id, {})
            
            # Filter by dietary restrictions
            if self.violates_dietary_restrictions(features, user_profile):
                continue
            
            # Filter by price range
            if not self.within_price_range(features, user_profile):
                continue
            
            # Apply diversity (avoid recommending too many similar items)
            if self.is_too_similar(rec, filtered_recommendations):
                continue
            
            # Apply inventory/availability
            if not self.is_available(product_id):
                continue
            
            # Apply novelty (recommend some new items)
            rec['is_new_to_user'] = self.is_new_to_user(product_id, user_profile)
            if rec['is_new_to_user']:
                rec['total_score'] *= 1.1  # Boost for novel recommendations
            
            filtered_recommendations.append(rec)
        
        return filtered_recommendations
    
    def get_trending_recommendations(self, time_range='7d', limit=10):
        """Get trending products based on recent activity"""
        # In production, this would analyze real order data
        trending_products = [
            {
                'product_id': 'trending_burger_001',
                'name': 'AI-Detected Viral Burger',
                'trending_score': 95.5,
                'order_count_24h': 1247,
                'growth_rate': 234.2,
                'image_url': '/images/trending-burger.jpg',
                'price': 18.99,
                'rating': 4.7,
                'tags': ['viral', 'trending', 'premium']
            },
            {
                'product_id': 'trending_pizza_001',
                'name': 'Smart Suggested Pizza',
                'trending_score': 89.3,
                'order_count_24h': 892,
                'growth_rate': 156.8,
                'image_url': '/images/trending-pizza.jpg',
                'price': 22.50,
                'rating': 4.5,
                'tags': ['smart', 'ai-recommended']
            },
            {
                'product_id': 'trending_sushi_001',
                'name': 'Personalized Sushi Roll',
                'trending_score': 87.1,
                'order_count_24h': 634,
                'growth_rate': 189.4,
                'image_url': '/images/trending-sushi.jpg',
                'price': 16.75,
                'rating': 4.8,
                'tags': ['personalized', 'fresh']
            }
        ]
        
        return {
            'trending_products': trending_products[:limit],
            'metadata': {
                'time_range': time_range,
                'analysis_method': 'ml_trending_algorithm',
                'generated_at': datetime.now().isoformat()
            }
        }
    
    def update_user_profile(self, user_id, interaction_data):
        """Update user profile based on new interaction data"""
        if user_id not in self.user_profiles:
            self.get_user_profile(user_id)
        
        profile = self.user_profiles[user_id]
        
        # Update order history
        if 'ordered_items' in interaction_data:
            profile['order_history'].extend(interaction_data['ordered_items'])
            profile['order_history'] = profile['order_history'][-50:]  # Keep last 50
        
        # Update preferences
        if 'preferences' in interaction_data:
            profile['preferences'].extend(interaction_data['preferences'])
            profile['preferences'] = list(set(profile['preferences']))  # Remove duplicates
        
        # Update order frequency
        if 'order_value' in interaction_data:
            current_avg = profile['avg_order_value']
            order_value = interaction_data['order_value']
            profile['avg_order_value'] = (current_avg + order_value) / 2
        
        # Update dietary restrictions
        if 'dietary_changes' in interaction_data:
            profile['dietary_restrictions'] = list(set(
                profile['dietary_restrictions'] + interaction_data['dietary_changes']
            ))
        
        profile['last_updated'] = datetime.now().isoformat()
    
    # Helper methods for various scoring functions
    def calculate_content_similarity(self, user_profile, product_features):
        """Calculate content-based similarity score"""
        score = 0.0
        weight = 0.0
        
        # Cuisine preference matching
        user_cuisines = user_profile.get('preferences', [])
        product_cuisine = product_features.get('cuisine', '')
        if product_cuisine in user_cuisines:
            score += 0.3
        
        # Dietary restriction compliance
        user_restrictions = user_profile.get('dietary_restrictions', [])
        if not self.violates_dietary_restrictions(product_features, user_profile):
            score += 0.25
        
        # Price sensitivity matching
        user_price_sens = user_profile.get('price_sensitivity', 0.5)
        product_price = product_features.get('price', 0)
        if self.within_price_range(product_features, user_profile):
            score += 0.2
        
        # Rating bonus
        product_rating = product_features.get('rating', 0)
        score += (product_rating / 5.0) * 0.25
        
        return min(score, 1.0)
    
    def find_similar_users(self, user_id, max_similar=5):
        """Find users with similar preferences (simplified)"""
        # In production, this would use more sophisticated similarity algorithms
        target_profile = self.get_user_profile(user_id)
        similar_users = []
        
        for other_user_id, other_profile in self.user_profiles.items():
            if other_user_id == user_id:
                continue
            
            similarity = self.calculate_user_similarity(target_profile, other_profile)
            if similarity > 0.5:  # Similarity threshold
                similar_users.append((other_user_id, similarity))
        
        # Sort by similarity and return top users
        similar_users.sort(key=lambda x: x[1], reverse=True)
        return [user[0] for user in similar_users[:max_similar]]
    
    def calculate_user_similarity(self, profile1, profile2):
        """Calculate similarity between two user profiles"""
        score = 0.0
        
        # Compare preferences
        prefs1 = set(profile1.get('preferences', []))
        prefs2 = set(profile2.get('preferences', []))
        if prefs1 and prefs2:
            common_prefs = prefs1.intersection(prefs2)
            score += len(common_prefs) / max(len(prefs1), len(prefs2)) * 0.4
        
        # Compare dietary restrictions
        diet1 = set(profile1.get('dietary_restrictions', []))
        diet2 = set(profile2.get('dietary_restrictions', []))
        if diet1 and diet2:
            common_diet = diet1.intersection(diet2)
            score += len(common_diet) / max(len(diet1), len(diet2)) * 0.3
        
        # Compare price sensitivity
        price_sens1 = profile1.get('price_sensitivity', 0.5)
        price_sens2 = profile2.get('price_sensitivity', 0.5)
        price_diff = abs(price_sens1 - price_sens2)
        score += (1.0 - price_diff) * 0.3
        
        return min(score, 1.0)
    
    def get_time_context_score(self, product_features, time_of_day):
        """Get time-based context score"""
        product_name = product_features.get('name', '').lower()
        
        if time_of_day == 'breakfast':
            if any(word in product_name for word in ['breakfast', 'coffee', 'pastry', 'juice']):
                return 0.8
        elif time_of_day == 'lunch':
            if any(word in product_name for word in ['salad', 'wrap', 'sandwich', 'light']):
                return 0.7
        elif time_of_day == 'dinner':
            if any(word in product_name for word in ['dinner', 'pizza', 'pasta', 'heavy']):
                return 0.8
        elif time_of_day == 'late_night':
            if any(word in product_name for word in ['snack', 'dessert', 'light']):
                return 0.6
        
        return 0.1  # Default low score
    
    def get_weather_context_score(self, product_features, weather):
        """Get weather-based context score"""
        product_name = product_features.get('name', '').lower()
        
        if weather == 'hot':
            if any(word in product_name for word in ['cold', 'salad', 'ice', 'fresh']):
                return 0.8
        elif weather == 'cold':
            if any(word in product_name for word in ['hot', 'warm', 'soup', 'comfort']):
                return 0.8
        elif weather == 'rainy':
            if any(word in product_name for word in ['warm', 'comfort', 'hearty']):
                return 0.7
        
        return 0.1
    
    def get_mood_context_score(self, product_features, mood):
        """Get mood-based context score"""
        # This would use more sophisticated mood-food mapping
        mood_food_mapping = {
            'happy': ['colorful', 'vibrant', 'dessert'],
            'sad': ['comfort', 'warm', 'cheese'],
            'stressed': ['light', 'simple', 'quick'],
            'excited': ['spicy', 'unique', 'premium'],
            'tired': ['energizing', 'coffee', 'protein']
        }
        
        if mood in mood_food_mapping:
            product_name = product_features.get('name', '').lower()
            for mood_food in mood_food_mapping[mood]:
                if mood_food in product_name:
                    return 0.7
        
        return 0.1
    
    def violates_dietary_restrictions(self, product_features, user_profile):
        """Check if product violates user dietary restrictions"""
        user_restrictions = set(user_profile.get('dietary_restrictions', []))
        
        # Check for meat if vegetarian
        if 'vegetarian' in user_restrictions:
            if product_features.get('is_vegetarian', True) == False:
                return True
        
        # Check for allergens
        product_tags = set(product_features.get('tags', []))
        for restriction in user_restrictions:
            if restriction in product_tags:
                return True
        
        return False
    
    def within_price_range(self, product_features, user_profile):
        """Check if product is within user's price range"""
        user_avg = user_profile.get('avg_order_value', 20.0)
        user_sensitivity = user_profile.get('price_sensitivity', 0.5)
        
        product_price = product_features.get('price', 0)
        
        # Adjust price range based on sensitivity
        tolerance = user_sensitivity * 0.5  # Higher sensitivity = smaller tolerance
        min_price = user_avg * (1.0 - tolerance)
        max_price = user_avg * (1.0 + tolerance)
        
        return min_price <= product_price <= max_price
    
    def is_too_similar(self, new_rec, existing_recs):
        """Check if recommendation is too similar to existing ones"""
        if len(existing_recs) < 2:
            return False
        
        new_features = self.product_features.get(new_rec['product_id'], {})
        similar_count = 0
        
        for existing in existing_recs[-3:]:  # Check last 3 recommendations
            existing_features = self.product_features.get(existing['product_id'], {})
            
            if self.calculate_similarity(new_features, existing_features) > 0.8:
                similar_count += 1
        
        return similar_count >= 2  # Don't allow more than 2 very similar items
    
    def is_available(self, product_id):
        """Check if product is available (simplified)"""
        # In production, this would check real inventory
        return True
    
    def is_new_to_user(self, product_id, user_profile):
        """Check if product is new to user's order history"""
        order_history = set(user_profile.get('order_history', []))
        return product_id not in order_history
    
    def get_personalization_boost(self, rec, user_profile):
        """Get personalization boost factor"""
        boost = 1.0
        
        # Boost for high-rated items
        product_features = self.product_features.get(rec['product_id'], {})
        rating = product_features.get('rating', 0)
        if rating >= 4.5:
            boost *= 1.1
        
        # Boost for preferred cuisine
        user_prefs = user_profile.get('preferences', [])
        product_cuisine = product_features.get('cuisine', '')
        if product_cuisine in user_prefs:
            boost *= 1.15
        
        return min(boost, 1.3)  # Cap the boost
    
    def calculate_similarity(self, features1, features2):
        """Calculate similarity between two product features"""
        # Simplified similarity calculation
        common_keys = set(features1.keys()).intersection(set(features2.keys()))
        if not common_keys:
            return 0.0
        
        matches = 0
        for key in common_keys:
            if features1[key] == features2[key]:
                matches += 1
        
        return matches / len(common_keys)
    
    def calculate_confidence_score(self, recommendations):
        """Calculate overall confidence score for recommendations"""
        if not recommendations:
            return 0.0
        
        total_score = sum(rec['total_score'] for rec in recommendations)
        avg_score = total_score / len(recommendations)
        
        # Confidence is higher when average score is higher and scores are consistent
        consistency = 1.0 - (np.std([rec['total_score'] for rec in recommendations]) if len(recommendations) > 1 else 0)
        
        return min(avg_score * consistency, 1.0)
    
    def get_fallback_recommendations(self, limit=10):
        """Get fallback recommendations when AI fails"""
        fallback_items = [
            {
                'product_id': 'fallback_1',
                'name': 'Classic Margherita Pizza',
                'score': 0.5,
                'method': 'fallback',
                'reasons': ['Popular choice', 'Always available']
            },
            {
                'product_id': 'fallback_2', 
                'name': 'Chicken Caesar Salad',
                'score': 0.45,
                'method': 'fallback',
                'reasons': ['Healthy option', 'Customer favorite']
            }
        ]
        
        return {
            'recommendations': fallback_items[:limit],
            'metadata': {
                'method': 'fallback',
                'confidence_score': 0.3,
                'timestamp': datetime.now().isoformat()
            }
        }
    
    def save_models(self):
        """Save trained models to disk"""
        os.makedirs('models', exist_ok=True)
        
        try:
            with open('models/user_profiles.pkl', 'wb') as f:
                pickle.dump(self.user_profiles, f)
            
            with open('models/product_features.pkl', 'wb') as f:
                pickle.dump(self.product_features, f)
            
            print("✅ AI models saved successfully")
        except Exception as e:
            print(f"❌ Error saving models: {e}")


def main():
    """Main function for CLI usage"""
    if len(sys.argv) < 2:
        print("Usage: python3 ai_recommendation_engine.py <user_id> [limit] [context_json]")
        sys.exit(1)
    
    user_id = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    context = None
    
    if len(sys.argv) > 3:
        try:
            context = json.loads(sys.argv[3])
        except json.JSONDecodeError:
            print("❌ Invalid context JSON")
            sys.exit(1)
    
    # Initialize AI engine
    engine = AIRecommendationEngine()
    
    # Get recommendations
    recommendations = engine.get_personalized_recommendations(user_id, limit, context)
    
    # Output as JSON
    print(json.dumps(recommendations, indent=2))
    
    # Save updated models
    engine.save_models()


if __name__ == "__main__":
    main()