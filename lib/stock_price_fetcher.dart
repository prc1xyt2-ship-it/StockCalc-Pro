import 'dart:convert';
import 'package:flutter/foundation.dart'; // 追加: debugPrint を使うため
import 'package:http/http.dart' as http;

/// Yahoo!ファイナンスから株価を取得
/// 例: "7203" → トヨタ自動車の株価を取得
class StockPriceFetcher {
  static Future<int?> getPrice(String code) async {
    try {
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$code.T');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final price = data['chart']['result'][0]['meta']['regularMarketPrice'];
        if (price is num) return price.toInt();
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching stock price: $e");
      return null;
    }
  }
}
