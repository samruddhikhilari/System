import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../models/supplier_model.dart';
import '../sources/remote/dio_provider.dart';

abstract class SupplierRepository {
  Future<SupplierModel> getSupplierDetail(String supplierId);
  Future<List<SupplierModel>> getSuppliersNear(String supplierId);
  Future<List<SupplierDependency>> getDependencies(String supplierId);
  Future<List<SupplierRecommendation>> getRecommendations(String supplierId);
}

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl({required this.dio});

  final Dio dio;

  @override
  Future<SupplierModel> getSupplierDetail(String supplierId) async {
    try {
      final response = await dio.get(ApiEndpoints.supplierById(supplierId));
      final payload = response.data as Map<String, dynamic>;
      final rawRisk = (payload['risk_score'] ?? payload['riskScore'] ?? 0).toDouble();
      final adjustment = (payload['manual_risk_adjustment'] ?? payload['manualRiskAdjustment'] ?? 0).toDouble();

      return SupplierModel.fromJson({
        ...payload,
        'risk_score': (rawRisk + adjustment).clamp(0, 100),
      });
    } on DioException catch (error) {
      final appException = error.error;
      if (appException is AppException) {
        throw appException;
      }
      throw ServerException(
        message: 'Unable to load supplier details.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<List<SupplierModel>> getSuppliersNear(String supplierId) async {
    final response = await dio.get('${ApiEndpoints.supplierById(supplierId)}/nearby');
    final list = response.data is List
        ? response.data as List<dynamic>
        : (response.data['suppliers'] as List<dynamic>? ?? <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(SupplierModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<SupplierDependency>> getDependencies(String supplierId) async {
    final response = await dio.get(ApiEndpoints.supplierDependencies(supplierId));
    final list = response.data is List
        ? response.data as List<dynamic>
        : (response.data['dependencies'] as List<dynamic>? ?? <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(SupplierDependency.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<SupplierRecommendation>> getRecommendations(String supplierId) async {
    final response = await dio.get(ApiEndpoints.supplierRecommendations(supplierId));
    final list = response.data is List
        ? response.data as List<dynamic>
        : (response.data['recommendations'] as List<dynamic>? ?? <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(SupplierRecommendation.fromJson)
        .toList(growable: false);
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SupplierRepositoryImpl(dio: dio);
});
