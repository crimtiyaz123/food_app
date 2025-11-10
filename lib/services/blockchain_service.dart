import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../models/blockchain_supply_chain.dart';
import '../utils/logger.dart';

class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  // Ethereum network configuration
  static const String _rpcUrl = 'https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID';
  static const String _contractAddress = '0x...'; // Supply chain contract address
  static const String _privateKey = 'YOUR_PRIVATE_KEY'; // For demo purposes only

  late Web3Client _web3Client;
  late EthPrivateKey _credentials;
  late DeployedContract _supplyChainContract;

  // Contract ABI (simplified for supply chain tracking)
  final String _contractAbi = jsonEncode([
    {
      "inputs": [
        {"internalType": "string", "name": "_productId", "type": "string"},
        {"internalType": "string", "name": "_batchId", "type": "string"},
        {"internalType": "uint8", "name": "_stage", "type": "uint8"},
        {"internalType": "string", "name": "_data", "type": "string"}
      ],
      "name": "addSupplyChainRecord",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"internalType": "string", "name": "_batchId", "type": "string"}
      ],
      "name": "getSupplyChainRecords",
      "outputs": [
        {"internalType": "string[]", "name": "", "type": "string[]"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {"internalType": "string", "name": "_batchId", "type": "string"}
      ],
      "name": "verifyBatch",
      "outputs": [
        {"internalType": "bool", "name": "", "type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ]);

  Future<void> initialize() async {
    try {
      _web3Client = Web3Client(_rpcUrl, http.Client());
      _credentials = EthPrivateKey.fromHex(_privateKey);

      // Load contract
      final contractAbi = ContractAbi.fromJson(_contractAbi, 'SupplyChain');
      _supplyChainContract = DeployedContract(
        contractAbi,
        EthereumAddress.fromHex(_contractAddress),
      );

      AppLogger.info('Blockchain service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize blockchain service', e);
      rethrow;
    }
  }

  Future<String> addSupplyChainRecord(SupplyChainRecord record) async {
    try {
      final function = _supplyChainContract.function('addSupplyChainRecord');
      final data = jsonEncode(record.data);

      final result = await _web3Client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _supplyChainContract,
          function: function,
          parameters: [
            record.productId,
            record.batchId,
            record.stage.index,
            data,
          ],
        ),
        chainId: 1, // Ethereum mainnet
      );

      AppLogger.info('Supply chain record added to blockchain: ${record.id}');
      return result;
    } catch (e) {
      AppLogger.error('Failed to add supply chain record to blockchain', e);
      rethrow;
    }
  }

  Future<List<String>> getSupplyChainRecords(String batchId) async {
    try {
      final function = _supplyChainContract.function('getSupplyChainRecords');

      final result = await _web3Client.call(
        contract: _supplyChainContract,
        function: function,
        params: [batchId],
      );

      return List<String>.from(result[0] as List);
    } catch (e) {
      AppLogger.error('Failed to get supply chain records from blockchain', e);
      rethrow;
    }
  }

  Future<bool> verifyBatchAuthenticity(String batchId) async {
    try {
      final function = _supplyChainContract.function('verifyBatch');

      final result = await _web3Client.call(
        contract: _supplyChainContract,
        function: function,
        params: [batchId],
      );

      return result[0] as bool;
    } catch (e) {
      AppLogger.error('Failed to verify batch authenticity', e);
      rethrow;
    }
  }

  Future<String> createBatchVerification(SupplyChainVerification verification) async {
    try {
      // Create a verification record on blockchain
      final verificationData = jsonEncode({
        'batchId': verification.batchId,
        'verifierId': verification.verifierId,
        'verifierName': verification.verifierName,
        'verificationDate': verification.verificationDate.toIso8601String(),
        'isAuthentic': verification.isAuthentic,
        'notes': verification.notes,
      });

      final function = _supplyChainContract.function('addVerification');
      if (function != null) {
        final result = await _web3Client.sendTransaction(
          _credentials,
          Transaction.callContract(
            contract: _supplyChainContract,
            function: function,
            parameters: [
              verification.batchId,
              verificationData,
            ],
          ),
          chainId: 1,
        );

        AppLogger.info('Batch verification added to blockchain: ${verification.id}');
        return result;
      } else {
        throw Exception('Verification function not found in contract');
      }
    } catch (e) {
      AppLogger.error('Failed to create batch verification on blockchain', e);
      rethrow;
    }
  }

  Future<EtherAmount> getGasPrice() async {
    try {
      return await _web3Client.getGasPrice();
    } catch (e) {
      AppLogger.error('Failed to get gas price', e);
      rethrow;
    }
  }

  Future<String> getTransactionReceipt(String transactionHash) async {
    try {
      final receipt = await _web3Client.getTransactionReceipt(transactionHash);
      return jsonEncode(receipt?.toString());
    } catch (e) {
      AppLogger.error('Failed to get transaction receipt', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _web3Client.dispose();
  }
}
