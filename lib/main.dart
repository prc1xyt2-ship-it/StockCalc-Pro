import 'package:flutter/material.dart';
import 'dart:math';
import 'stock_price_fetcher.dart'; // 株価取得用コード（後述）

void main() {
  runApp(const StockCalcApp());
}

class StockCalcApp extends StatelessWidget {
  const StockCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '株購入可能数計算ツール',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const StockCalcHome(),
    );
  }
}

class StockCalcHome extends StatefulWidget {
  const StockCalcHome({super.key});

  @override
  State<StockCalcHome> createState() => _StockCalcHomeState();
}

class _StockCalcHomeState extends State<StockCalcHome> {
  final sellPriceCtrl = TextEditingController();
  final sellQtyCtrl = TextEditingController();
  final cashCtrl = TextEditingController();
  final buyPriceCtrl = TextEditingController();
  final stockCodeCtrl = TextEditingController();

  double? resultQty;
  int? remainingCash;
  bool isLoading = false;

  // 手数料計算ルール（小数切り捨て）
  int _calcFee(int amount) => (amount * 0.0055).floor();

  // 売却の受取額を計算
  int _calcSellReceive(int price, int qty) {
    int total = price * qty;
    int fee = _calcFee(total);
    return total - fee;
  }

  // 購入に必要な資金を計算
  int _calcBuyCost(int price, int qty) {
    int total = price * qty;
    int fee = _calcFee(total);
    return total + fee;
  }

  // 購入可能株数を算出（100株単位）
  void _calculate() {
    final sellPrice = int.tryParse(sellPriceCtrl.text) ?? 0;
    final sellQty = int.tryParse(sellQtyCtrl.text) ?? 0;
    final cash = int.tryParse(cashCtrl.text) ?? 0;
    final buyPrice = int.tryParse(buyPriceCtrl.text) ?? 0;

    if (buyPrice <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("購入株価が不正です（0 より大きい値を入力してください）")),
      );
      return;
    }

    int totalCash = _calcSellReceive(sellPrice, sellQty) + cash;
    final unitCostFor100 = _calcBuyCost(buyPrice, 100);
    if (unitCostFor100 <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("計算に使う単価が不正です")),
      );
      return;
    }

    int possibleQty = (totalCash / unitCostFor100).floor() * 100;
    int totalCost = _calcBuyCost(buyPrice, possibleQty);
    int remain = max(0, totalCash - totalCost);

    setState(() {
      resultQty = possibleQty.toDouble();
      remainingCash = remain;
    });
  }

  // 銘柄コードから株価取得
  Future<void> _fetchPrice() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final code = stockCodeCtrl.text;
    final fetched = await StockPriceFetcher.getPrice(code);

    if (!mounted) {
      // ウィジェットが破棄されていたら何もしない
      return;
    }

    if (fetched != null) {
      setState(() {
        buyPriceCtrl.text = fetched.toString();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("株価の取得に失敗しました")),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("株購入可能数計算ツール")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("【売却情報】", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "売却株価（円）")),
            TextField(controller: sellQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "売却株数（株）")),
            const SizedBox(height: 16),
            const Text("【所持金】", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: cashCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "現在の所持金（円）")),
            const SizedBox(height: 16),
            const Text("【購入情報】", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              Expanded(
                child: TextField(controller: stockCodeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "銘柄コード")),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isLoading ? null : _fetchPrice,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("株価取得"),
              ),
            ]),
            TextField(controller: buyPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "購入株価（円）")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text("計算する"),
            ),
            const SizedBox(height: 20),
            if (resultQty != null)
              Card(
                color: Colors.indigo[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("購入可能株数：${resultQty!.toInt()} 株", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("残金：${remainingCash!.toString()} 円"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    sellPriceCtrl.dispose();
    sellQtyCtrl.dispose();
    cashCtrl.dispose();
    buyPriceCtrl.dispose();
    stockCodeCtrl.dispose();
    super.dispose();
  }
}
