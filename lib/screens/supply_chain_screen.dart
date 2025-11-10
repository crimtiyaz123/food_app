import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/blockchain_supply_chain.dart';
import '../services/blockchain_service.dart';
import '../theme/app_theme.dart';

class SupplyChainScreen extends StatefulWidget {
  const SupplyChainScreen({super.key});

  @override
  State<SupplyChainScreen> createState() => _SupplyChainScreenState();
}

class _SupplyChainScreenState extends State<SupplyChainScreen> {
  final BlockchainService _blockchainService = BlockchainService();
  List<SupplyChainBatch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplyChainData();
    _initializeBlockchain();
  }

  Future<void> _initializeBlockchain() async {
    try {
      await _blockchainService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize blockchain: $e')),
        );
      }
    }
  }

  Future<void> _loadSupplyChainData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load from Firestore service
      // For now, show empty state
      setState(() {
        _batches = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load supply chain data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supply Chain Transparency'),
        backgroundColor: AppColors.primaryRed,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupplyChainData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSupplyChainView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBatchDialog,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSupplyChainView() {
    if (_batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No supply chain batches found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showAddBatchDialog,
              child: const Text('Add First Batch'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        return _buildBatchCard(_batches[index]);
      },
    );
  }

  Widget _buildBatchCard(SupplyChainBatch batch) {
    final progress = batch.progressPercentage;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: batch.isComplete ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    batch.isComplete ? 'Complete' : 'In Progress',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Batch ID: ${batch.id}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 100 ? Colors.green : AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${progress.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showBatchDetails(batch),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showQRCode(batch),
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'Show QR Code',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchDetails(SupplyChainBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${batch.productName} - Supply Chain'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Batch ID', batch.id),
              _buildDetailRow('Quantity', '${batch.quantity} ${batch.unit}'),
              _buildDetailRow('Origin Farm', batch.originFarm),
              _buildDetailRow('Harvest Date', batch.harvestDate.toString()),
              _buildDetailRow('Created', batch.createdAt.toString()),
              if (batch.completedAt != null)
                _buildDetailRow('Completed', batch.completedAt.toString()),
              const SizedBox(height: 16),
              const Text(
                'Supply Chain Stages:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...batch.records.map(
                (record) => _buildStageRow(record),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _verifyBatch(batch),
            child: const Text('Verify Authenticity'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStageRow(SupplyChainRecord record) {
    final isCompleted = record.status == SupplyChainStatus.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.stage.displayName,
                  style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${record.participantName} - ${record.location}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.timestamp.toString().split(' ')[0],
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showQRCode(SupplyChainBatch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${batch.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: batch.id,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to verify supply chain authenticity',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyBatch(SupplyChainBatch batch) async {
    try {
      final isAuthentic = await _blockchainService.verifyBatchAuthenticity(batch.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isAuthentic ? 'Authentic' : 'Verification Failed'),
            content: Text(
              isAuthentic
                  ? 'This batch has been verified as authentic on the blockchain.'
                  : 'This batch could not be verified on the blockchain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  void _showAddBatchDialog() {
    // TODO: Implement add batch dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add batch feature coming soon!')),
    );
  }
}
