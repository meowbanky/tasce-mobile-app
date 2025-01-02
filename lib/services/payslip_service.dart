// lib/services/payslip_service.dart

import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/period.dart';
import '../providers/auth_provider.dart';

class PayslipService {
  final ApiService _apiService = ApiService();
  final AuthProvider _authProvider;

  PayslipService(this._authProvider);

  Future<List<Period>> getPeriods() async {
    try {
      final response = await _apiService.dio.get('/api/payroll/periods.php');

      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((period) => Period.fromJson(period))
            .toList();
      }
      throw 'Failed to load periods';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'Session expired. Please login again.';
      }
      throw 'Error loading periods: ${e.message}';
    } catch (e) {
      throw 'Error loading periods: $e';
    }
  }

  Future<Map<String, dynamic>> getPayslip(String periodId) async {
    try {
      // Get user ID from AuthProvider
      final userId = _authProvider.user?.id;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final response = await _apiService.dio.get(
        '/api/payroll/payslip.php',
        queryParameters: {
          'periodId': periodId,
          'userId': userId,
        },
      );

      if (response.data['success']) {
        return response.data['data'];
      }
      throw response.data['message'] ?? 'Failed to load payslip';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'Session expired. Please login again.';
      }
      throw 'Error loading payslip: ${e.message}';
    } catch (e) {
      throw 'Error loading payslip: $e';
    }
  }
}
