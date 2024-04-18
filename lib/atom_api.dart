import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttomApi {
  static const String baseUrl = 'https://api.gateway.attomdata.com/propertyapi/v1.0.0/property/detail?attomid=184713191';
  static const String apiKey = '2b1e86b638620bf2404521e6e9e1b19e';

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'apikey': apiKey,
      },
    );
    if (response.statusCode == 200) {
      debugPrint("RESPONSE >>>>${json.decode(response.body)}");
      return json.decode(response.body);
    } else {
      throw Exception('RESPONSE >>>> Failed to load data');
    }
  }
}
