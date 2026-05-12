import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../services/auth_service.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final token = await _authService.getToken();

    final headers = <String, String>{};

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final uri = Uri.parse('$baseUrl/dashboard');

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo cargar el panel principal.',
    );
  }

  Future<List<dynamic>> getProducts({bool lowStockOnly = false}) async {
    final uri = Uri.parse(
      lowStockOnly ? '$baseUrl/products/low-stock' : '$baseUrl/products',
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeListResponse(
      res,
      defaultMessage: 'No se pudieron cargar los productos.',
    );
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required int stock,
    required int lowStockThreshold,
    required double price,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/products');

    final res = await http.post(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': name.trim(),
        'stock': stock,
        'lowStockThreshold': lowStockThreshold,
        'price': price,
        'imageUrl': (imageUrl ?? '').trim(),
      }),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo crear el producto.',
    );
  }

  Future<Map<String, dynamic>> patchProduct(
      int id, {
        int? stock,
        double? price,
        int? lowStockThreshold,
        String? name,
        String? imageUrl,
      }) async {
    final uri = Uri.parse('$baseUrl/products/$id');

    final body = <String, dynamic>{};

    if (stock != null) body['stock'] = stock;
    if (price != null) body['price'] = price;
    if (lowStockThreshold != null) {
      body['lowStockThreshold'] = lowStockThreshold;
    }
    if (name != null) body['name'] = name.trim();
    if (imageUrl != null) body['imageUrl'] = imageUrl.trim();

    final res = await http.patch(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo actualizar el producto.',
    );
  }

  Future<void> deleteProduct(int id) async {
    final uri = Uri.parse('$baseUrl/products/$id');

    final res = await http.delete(
      uri,
      headers: await _headers(),
    );

    _checkVoidResponse(
      res,
      defaultMessage: 'No se pudo eliminar el producto.',
    );
  }

  Future<Map<String, dynamic>> uploadProductPhoto({
    required int id,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/products/$id/photo');

    final request = http.MultipartRequest('PATCH', uri);

    final token = await _authService.getToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo subir la foto del producto.',
    );
  }

  Future<List<dynamic>> getOrders() async {
    final uri = Uri.parse('$baseUrl/orders');

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeListResponse(
      res,
      defaultMessage: 'No se pudieron cargar los pedidos.',
    );
  }

  Future<Map<String, dynamic>> patchOrderStatus(
      int id,
      String status,
      ) async {
    final uri = Uri.parse('$baseUrl/orders/$id/status');

    final res = await http.patch(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode({'status': status}),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo cambiar el estado del pedido.',
    );
  }

  Future<List<dynamic>> getCustomers() async {
    final uri = Uri.parse('$baseUrl/customers');

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeListResponse(
      res,
      defaultMessage: 'No se pudieron cargar los clientes.',
    );
  }

  Future<Map<String, dynamic>> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/customers');

    final res = await http.post(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': name.trim(),
        'email': (email ?? '').trim(),
        'phone': (phone ?? '').trim(),
        'imageUrl': (imageUrl ?? '').trim(),
      }),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo crear el cliente.',
    );
  }

  Future<Map<String, dynamic>> updateCustomer({
    required int id,
    required String name,
    String? email,
    String? phone,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/customers/$id');

    final res = await http.patch(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': name.trim(),
        'email': (email ?? '').trim(),
        'phone': (phone ?? '').trim(),
        'imageUrl': (imageUrl ?? '').trim(),
      }),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo actualizar el cliente.',
    );
  }

  Future<void> deleteCustomer(int id) async {
    final uri = Uri.parse('$baseUrl/customers/$id');

    final res = await http.delete(
      uri,
      headers: await _headers(),
    );

    _checkVoidResponse(
      res,
      defaultMessage: 'No se pudo eliminar el cliente.',
    );
  }

  Future<Map<String, dynamic>> uploadCustomerPhoto({
    required int id,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/customers/$id/photo');

    final request = http.MultipartRequest('PATCH', uri);

    final token = await _authService.getToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo subir la foto del cliente.',
    );
  }

  Future<Map<String, dynamic>> createOrder({
    required int customerId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final uri = Uri.parse('$baseUrl/orders');

    final res = await http.post(
      uri,
      headers: await _headers(json: true),
      body: jsonEncode({
        'customerId': customerId,
        'lines': lines,
      }),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo crear el pedido.',
    );
  }

  Future<Map<String, dynamic>> getMonthlyAnalytics({
    int? year,
    int? month,
  }) async {
    final q = <String, String>{};

    if (year != null) q['year'] = year.toString();
    if (month != null) q['month'] = month.toString();

    final uri = Uri.parse('$baseUrl/analytics/monthly-v2').replace(
      queryParameters: q.isEmpty ? null : q,
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo cargar el analizador.',
    );
  }

  Future<Map<String, dynamic>> generateMonthlyReport({
    int? year,
    int? month,
  }) async {
    final q = <String, String>{};

    if (year != null) q['year'] = year.toString();
    if (month != null) q['month'] = month.toString();

    final uri = Uri.parse('$baseUrl/reports/monthly').replace(
      queryParameters: q.isEmpty ? null : q,
    );

    final res = await http.post(
      uri,
      headers: await _headers(),
    );

    return _decodeMapResponse(
      res,
      defaultMessage: 'No se pudo generar el reporte mensual.',
    );
  }

  String reportDownloadUrl(int reportId) {
    return '$baseUrl/reports/$reportId/download';
  }

  Map<String, dynamic> _decodeMapResponse(
      http.Response res, {
        required String defaultMessage,
      }) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw ApiException('La respuesta de la API no tiene el formato esperado.');
    }

    throw ApiException(
      _friendlyErrorMessage(
        res,
        defaultMessage: defaultMessage,
      ),
    );
  }

  List<dynamic> _decodeListResponse(
      http.Response res, {
        required String defaultMessage,
      }) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);

      if (decoded is List<dynamic>) {
        return decoded;
      }

      throw ApiException('La respuesta de la API no tiene el formato esperado.');
    }

    throw ApiException(
      _friendlyErrorMessage(
        res,
        defaultMessage: defaultMessage,
      ),
    );
  }

  void _checkVoidResponse(
      http.Response res, {
        required String defaultMessage,
      }) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    throw ApiException(
      _friendlyErrorMessage(
        res,
        defaultMessage: defaultMessage,
      ),
    );
  }

  String _friendlyErrorMessage(
      http.Response res, {
        required String defaultMessage,
      }) {
    final rawMessage = _extractApiMessage(res.body);

    if (res.statusCode == 401) {
      return 'Tu sesión ha caducado o no has iniciado sesión.';
    }

    if (res.statusCode == 403) {
      return 'No tienes permiso para realizar esta acción.';
    }

    if (res.statusCode == 409) {
      return _translateConflict(rawMessage);
    }

    if (res.statusCode == 400) {
      return _translateBadRequest(rawMessage, defaultMessage);
    }

    if (res.statusCode == 404) {
      return _translateNotFound(rawMessage);
    }

    if (res.statusCode == 500) {
      return '$defaultMessage Ha ocurrido un error interno en el servidor.';
    }

    if (rawMessage.isNotEmpty) {
      return _translateGeneric(rawMessage);
    }

    return '$defaultMessage Código: ${res.statusCode}.';
  }

  String _extractApiMessage(String body) {
    if (body.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }

        if (decoded['error'] != null) {
          return decoded['error'].toString();
        }
      }
    } catch (_) {
      return body;
    }

    return body;
  }

  String _translateConflict(String message) {
    final clean = message.trim();

    if (clean.toLowerCase().contains('not enough stock for product')) {
      final productName = clean.split(':').last.trim();

      if (productName.isNotEmpty) {
        return 'No hay stock suficiente para $productName.';
      }

      return 'No hay stock suficiente para crear el pedido.';
    }

    if (clean.toLowerCase().contains('constraint')) {
      return 'No se puede realizar esta acción porque el registro está asociado a otros datos.';
    }

    if (clean.isNotEmpty) {
      return _translateGeneric(clean);
    }

    return 'No se puede completar la operación porque hay un conflicto con los datos actuales.';
  }

  String _translateBadRequest(
      String message,
      String defaultMessage,
      ) {
    final clean = message.trim().toLowerCase();

    if (clean.contains('name is required')) {
      return 'El nombre es obligatorio.';
    }

    if (clean.contains('file is required')) {
      return 'Debes seleccionar una imagen.';
    }

    if (clean.contains('only image files are allowed')) {
      return 'Solo se permiten archivos de imagen.';
    }

    if (clean.contains('customer')) {
      return 'Debes seleccionar un cliente válido.';
    }

    if (clean.contains('product')) {
      return 'Debes seleccionar un producto válido.';
    }

    if (clean.contains('quantity')) {
      return 'La cantidad debe ser mayor que cero.';
    }

    if (message.trim().isNotEmpty) {
      return _translateGeneric(message.trim());
    }

    return defaultMessage;
  }

  String _translateNotFound(String message) {
    final clean = message.trim().toLowerCase();

    if (clean.contains('product')) {
      return 'No se encontró el producto indicado.';
    }

    if (clean.contains('customer')) {
      return 'No se encontró el cliente indicado.';
    }

    if (clean.contains('order')) {
      return 'No se encontró el pedido indicado.';
    }

    return 'No se encontró el recurso solicitado.';
  }

  String _translateGeneric(String message) {
    final clean = message.trim();

    if (clean.toLowerCase().contains('not enough stock for product')) {
      final productName = clean.split(':').last.trim();

      if (productName.isNotEmpty) {
        return 'No hay stock suficiente para $productName.';
      }

      return 'No hay stock suficiente para crear el pedido.';
    }

    if (clean.toLowerCase().contains('product not found')) {
      return 'No se encontró el producto indicado.';
    }

    if (clean.toLowerCase().contains('customer not found')) {
      return 'No se encontró el cliente indicado.';
    }

    if (clean.toLowerCase().contains('order not found')) {
      return 'No se encontró el pedido indicado.';
    }

    return clean;
  }
}