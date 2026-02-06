import 'api_service.dart';

class FinanceService {
  final ApiService _api;

  FinanceService(this._api);

  Future<double> getBalance() async {
    try {
      final response = await _api.get('/finance/balance/my');
      return double.tryParse(response.data['balance'].toString()) ?? 0.0;
    } catch (e) {
      print('Get Balance Error: $e');
      return 0.0; // Or rethrow
    }
  }

  Future<void> requestHandover(double amount) async {
      await _api.post('/finance/handover', { 'amount': amount });
  }
}
