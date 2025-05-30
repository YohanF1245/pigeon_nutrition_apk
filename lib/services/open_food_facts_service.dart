import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          return {
            'name': product['product_name_fr'] ?? product['product_name'] ?? '',
            'brands': product['brands'] ?? '',
            'nutriments': {
              'energy-kcal_100g': product['nutriments']?['energy-kcal_100g'] ?? 0.0,
              'proteins_100g': product['nutriments']?['proteins_100g'] ?? 0.0,
              'fat_100g': product['nutriments']?['fat_100g'] ?? 0.0,
              'carbohydrates_100g': product['nutriments']?['carbohydrates_100g'] ?? 0.0,
            },
          };
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return null;
    }
  }
} 