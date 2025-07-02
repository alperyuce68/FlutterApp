import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen10_profile.dart';
import 'package:flutter_application_1/screen7_crypto.dart';  // CryptoScreen
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'screen12_aapl.dart';          // AAPLDetailScreen
import 'screen13_THY.dart';           // THYDetailScreen
import 'screen17_amazon.dart';        // AmazonDetailScreen

const String TWELVEDATA_API_KEY = '27d93abda55e4e19a30af71578cdf523';

class Stock {
  final String symbol;
  final String name;
  final double price;
  final String iconUrl;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.iconUrl,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    String stockName;
    String stockIconUrl;
    switch (json['symbol']) {
      case 'AAPL':
        stockName = 'Apple Inc.';
        stockIconUrl =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1qzDUfdVdRa2_RvXC5K1SeguSkxcMWmjnjw&s';
        break;
      case 'THY':
        stockName = 'Turkish Airlines';
        stockIconUrl =
        'https://imgs.search.brave.com/W6DmJj9HcwUFbsaRHlBpFZvFEu7IlvtsYCPRh1S0Rwg/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9pbWFnZXMuc2Vla2xvZ28uY29tL2xvZ28tcG5nLzM2LzIvdHVya2lzaC1haXJsaW5lcy1sb2dvLXBuZ19zZWVrbG9nby0zNjYwNzguL3BuZw';
        break;
      case 'AMZN':
        stockName = 'Amazon.com, Inc.';
        stockIconUrl =
        'https://imgs.search.brave.com/EMxvXUYdtKMLmkVuAwxBgwqJoovYRbd2inxUlXqp6Dk/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9jZG4taWNvbnMtcG5nLmZyZWVwaWsuY29tLzI1Ni8xMTM3Ni8xMTM3NjMwMi5wbmc_c2VtPWFpc19oeWJyaWQ';
        break;
      default:
        stockName = json['symbol'];
        stockIconUrl = '';
    }
    return Stock(
      symbol: json['symbol'],
      name: stockName,
      price: double.tryParse(json['close'] ?? '0') ?? 0,
      iconUrl: stockIconUrl,
    );
  }
}

Future<List<Stock>> fetchStocks() async {
  final String apiUrl =
      'https://api.twelvedata.com/quote?symbol=AAPL,THY,AMZN&apikey=$TWELVEDATA_API_KEY';
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to load stocks: ${response.statusCode}');
  }
  final Map<String, dynamic> data = json.decode(response.body);
  if (data.containsKey('code')) {
    throw Exception('API Error: ${data['message']}');
  }
  final stocks = <Stock>[];
  data.forEach((_, value) {
    if (value is Map<String, dynamic>) stocks.add(Stock.fromJson(value));
  });
  if (stocks.isEmpty) throw Exception('No stock data received');
  return stocks;
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({Key? key}) : super(key: key);
  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  late Future<List<Stock>> futureStocks;
  int _selectedIndex = 2;
  String _locationMessage = 'Location information loading...';

  @override
  void initState() {
    super.initState();
    futureStocks = fetchStocks();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationMessage = 'Location services off.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationMessage = 'Location permission denied.');
        return;
      }
      final pos =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _locationMessage =
      'Location: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}');
    } catch (_) {
      setState(() => _locationMessage = 'Failed to get location.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.indigoAccent,
        title: Text(
          _locationMessage,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Asset section
            Row(
              children: [

                Expanded(
                  child: Center(
                    child: Text(
                      'My Asset',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
            SizedBox(height: 15),
            Card(
              elevation: 3,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your total asset portfolio',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '€ 2.240.560',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_upward, color: Colors.green, size: 15),
                        Text(
                          '+%12,2',
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 55),
            // Portfolio
            Text('My Portfolio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            FutureBuilder<List<Stock>>(
              future: futureStocks,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done)
                  return Center(child: CircularProgressIndicator());
                if (snap.hasError)
                  return Text('Error: ${snap.error}',
                      style: TextStyle(color: Colors.red));
                final unique = {for (var s in snap.data!) s.symbol: s}.values.toList();
                return Column(
                  children: unique.map((stock) {
                    // background & text color per stock
                    Color bg, fg;
                    switch (stock.symbol) {
                      case 'AAPL':
                        bg = Colors.black;
                        fg = Colors.white;
                        break;
                      case 'THY':
                        bg = Colors.red.shade800;
                        fg = Colors.white;
                        break;
                      case 'AMZN':
                        bg = Colors.orange.shade400;
                        fg = Colors.black87;
                        break;
                      default:
                        bg = Colors.grey.shade300;
                        fg = Colors.black87;
                    }
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12)],
                      ),
                      child: ListTile(
                        leading: stock.iconUrl.isNotEmpty
                            ? Image.network(
                          stock.iconUrl,
                          width: 36,
                          height: 36,
                          errorBuilder: (_, __, ___) {
                            // fallback icon if network fails
                            return Icon(
                              stock.symbol == 'THY'
                                  ? Icons.flight
                                  : Icons.shopping_cart,
                              size: 36,
                              color: fg,
                            );
                          },
                        )
                            : Icon(
                          stock.symbol == 'THY'
                              ? Icons.flight
                              : Icons.shopping_cart,
                          size: 36,
                          color: fg,
                        ),
                        title: Text(stock.symbol,
                            style: TextStyle(
                                color: fg, fontWeight: FontWeight.bold)),
                        trailing: Text(
                          '€ ${stock.price.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: fg, fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Widget page;
                          switch (stock.symbol) {
                            case 'AAPL':
                              page = AAPLDetailScreen();
                              break;
                            case 'THY':
                              page = THYDetailScreen();
                              break;
                            case 'AMZN':
                              page = AmazonDetailScreen();
                              break;
                            default:
                              page = PortfolioPage();
                          }
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => page));
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            SizedBox(height: 150),
            // History
            Text('History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            HistoryList(),
          ],
        ),
      ),

      // bottom nav
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (i) {
          if (i == _selectedIndex) return;
          setState(() => _selectedIndex = i);
          switch (i) {
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CryptoScreen()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PortfolioPage()));
              break;
            case 4:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProfilePage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stocks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_bitcoin), label: 'Crypto'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      historyItem('Buy "AAPL" Stock', 'WED 05 Apr 2025', '€ 20.000', false),
      historyItem('Sell "AAPL" Stock', 'TUE 04 Apr 2025', '€ 20.000', true),
      historyItem('Buy "AAPL" Stock', 'MON 03 Apr 2025', '€ 20.000', false),
    ],
  );

  Widget historyItem(
      String title, String date, String amount, bool isSell) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(amount,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSell ? Colors.green : Colors.black)),
            SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style:
                    TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
            Text(date,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
}
