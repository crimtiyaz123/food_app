import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/qr_delivery.dart';
import '../services/qr_delivery_service.dart';
import '../theme/app_theme.dart';

class QRDeliveryScreen extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String deliveryPersonId;

  const QRDeliveryScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.deliveryPersonId,
  });

  @override
  State<QRDeliveryScreen> createState() => _QRDeliveryScreenState();
}

class _QRDeliveryScreenState extends State<QRDeliveryScreen> {
  QRCodeDelivery? _qrDelivery;
  bool _isLoading = true;
  String _status = 'Setting up contactless delivery...';

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Setting up contactless delivery...';
      });

      final qrService = QRDeliveryService();
      
      final request = ContactlessDeliveryRequest(
        orderId: widget.orderId,
        customerId: widget.customerId,
        contactlessDelivery: true,
        dropOffInstructions: 'Please leave at the door',
        dropOffLocation: 'Front Door',
        leaveAtDoor: true,
        safetyMeasures: ['mask_required', 'no_contact', 'sanitized'],
        verificationMethod: 'qr_code',
        requestedAt: DateTime.now(),
      );

      final qrDelivery = await qrService.generateContactlessDeliveryQR(
        orderId: widget.orderId,
        customerId: widget.customerId,
        deliveryPersonId: widget.deliveryPersonId,
        request: request,
      );

      setState(() {
        _qrDelivery = qrDelivery;
        _isLoading = false;
        _status = 'Contactless delivery ready';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: ${e.toString()}';
      });
      debugPrint('Error setting up contactless delivery: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactless Delivery'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.lightTextWhite,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondaryBlack, AppColors.backgroundGray],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? _buildLoadingView()
            : _buildContactlessDeliveryView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: 20),
          Text(
            _status,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactlessDeliveryView() {
    if (_qrDelivery == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to set up contactless delivery',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateQRCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryRed, AppColors.accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.cardBorderRadius),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.security,
                  size: 48,
                  color: AppColors.lightTextWhite,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Contactless Delivery',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.lightTextWhite,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Your order will be delivered safely without direct contact',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.lightTextWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.large),

          // Delivery Information
          _buildDeliveryInfo(),

          const SizedBox(height: AppSpacing.large),

          // Safety Information
          _buildSafetyInfo(),

          const SizedBox(height: AppSpacing.large),

          // QR Code Information
          _buildQRCodeInfo(),

          const SizedBox(height: AppSpacing.large),

          // Status Information
          _buildStatusInfo(),

          const SizedBox(height: AppSpacing.large),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Information',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildInfoRow(
            Icons.location_on,
            'Drop-off Location',
            _qrDelivery!.contactInfo.dropOffLocation,
          ),
          _buildInfoRow(
            Icons.access_time,
            'Delivery Method',
            'Contactless',
          ),
          _buildInfoRow(
            Icons.schedule,
            'Instructions',
            _qrDelivery!.contactInfo.deliveryInstructions,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield,
                color: AppColors.successGreen,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                'Safety Protocols',
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ..._qrDelivery!.contactInfo.safetyRequirements.map((requirement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      requirement.replaceAll('_', ' ').toUpperCase(),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQRCodeInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        children: [
          const Icon(
            Icons.qr_code,
            size: 64,
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'QR Code Verification',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'A secure QR code will be generated for delivery verification',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(AppSpacing.small),
            ),
            child: Text(
              'QR Code: ${_qrDelivery!.id}',
              style: AppTextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusItem(
                Icons.security,
                'Secure',
                'Yes',
              ),
              _buildStatusItem(
                Icons.timer,
                'Active',
                'Now',
              ),
              _buildStatusItem(
                Icons.location_on,
                'Location',
                'Set',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          if (_qrDelivery!.contactInfo.specialNotes != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.small),
                border: Border.all(
                  color: AppColors.accentOrange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.note,
                    color: AppColors.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      'Special Notes: ${_qrDelivery!.contactInfo.specialNotes}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToScanner('customer', 'customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Test QR Scanner'),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generateQRCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Refresh Delivery Info'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryRed,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppColors.primaryRed,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          value,
          style: AppTextStyles.titleMedium,
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _navigateToScanner(String scannedBy, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          scannedBy: scannedBy,
          scannedByRole: role,
        ),
      ),
    );
  }
}

// QR Scanner Screen
class QRScannerScreen extends StatefulWidget {
  final String scannedBy;
  final String scannedByRole;

  const QRScannerScreen({
    super.key,
    required this.scannedBy,
    required this.scannedByRole,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  QRCodeDelivery? _qrDelivery;
  String _status = 'Ready to scan...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: AppColors.primaryRed,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondaryBlack, AppColors.backgroundGray],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: AppDecorations.elevatedCardDecoration,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'QR Code Scanner',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _status,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                ElevatedButton.icon(
                  onPressed: _simulateScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Simulate QR Scan'),
                ),
                if (_qrDelivery != null) ...[
                  const SizedBox(height: AppSpacing.large),
                  _buildScanResult(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _simulateScan() async {
    setState(() {
      _status = 'Processing QR scan...';
    });

    try {
      // This would typically use a QR scanner library
      // For demo purposes, we'll simulate a successful scan
      final qrService = QRDeliveryService();
      final result = await qrService.scanQRCode(
        qrCodeData: 'demo_contactless_delivery_${DateTime.now().millisecondsSinceEpoch}',
        scannedBy: widget.scannedBy,
        scannedByRole: widget.scannedByRole,
      );

      setState(() {
        _qrDelivery = result;
        _status = result != null ? 'QR Verification Successful' : 'QR Verification Failed';
      });
    } catch (e) {
      setState(() {
        _status = 'Scan Error: ${e.toString()}';
      });
    }
  }

  Widget _buildScanResult() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.elevatedCardDecoration,
      child: Column(
        children: [
          Icon(
            _qrDelivery != null ? Icons.check_circle : Icons.error,
            color: _qrDelivery != null ? AppColors.successGreen : AppColors.primaryRed,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            _qrDelivery != null ? 'QR Code Verified' : 'QR Verification Failed',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          if (_qrDelivery != null) ...[
            Text(
              'Order: ${_qrDelivery!.orderId}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Status: ${_qrDelivery!.status.toString().split('.').last}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Contactless: ${_qrDelivery!.isContactless ? "Yes" : "No"}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.medium),
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.small),
              ),
              child: const Text(
                'Delivery can proceed safely',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            Text(
              'Please try scanning again',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}