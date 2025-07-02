import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class THYDetailScreen extends StatefulWidget {
  const THYDetailScreen({Key? key}) : super(key: key);

  @override
  _THYDetailScreenState createState() => _THYDetailScreenState();
}

class _THYDetailScreenState extends State<THYDetailScreen>
    with SingleTickerProviderStateMixin {
  double currentPrice = 0.0;
  double priceChange = 0.0;
  List<FlSpot> priceSpots = [];
  List<String> dates = [];
  late TabController _tabController;

  final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    fetchStockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchStockData() async {
    const apiKey = '50d3f35edfc940f2955b342f1c780c13';
    final url = Uri.parse(
        'https://api.twelvedata.com/time_series?symbol=THYAO.IS'
            '&interval=1day'
            '&outputsize=30'
            '&apikey=$apiKey'
    );

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body['status'] == 'ok') {
          final List<dynamic> values = body['values'];
          final reversed = values.reversed.toList();

          final spots = <FlSpot>[];
          final labels = <String>[];
          for (var i = 0; i < reversed.length; i++) {
            final entry = reversed[i];
            final close = double.parse(entry['close']);
            final date = entry['datetime'].substring(0, 10);
            spots.add(FlSpot(i.toDouble(), close));
            labels.add(date);
          }

          setState(() {
            priceSpots = spots;
            dates = labels;
            if (spots.length >= 2) {
              currentPrice = spots.last.y;
              priceChange = spots.last.y - spots[spots.length - 2].y;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching THY data: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = priceChange >= 0;
    final changePercent = currentPrice > 0
        ? (priceChange / currentPrice) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3557C2),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Add My List', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: const Text('THYAO', style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(width: 8),
                const Text('Turkish Airlines', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Icon(Icons.flight, size: 32, color: Colors.red.shade800),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _priceFormat.format(currentPrice),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${isPositive ? '+' : ''}${_priceFormat.format(priceChange)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: '1D'), Tab(text: '1W'), Tab(text: '1M'),
                Tab(text: '1Y'), Tab(text: '5Y'), Tab(text: 'ALL'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: priceSpots.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                LineChartData(
                  minX: 0,
                  maxX: priceSpots.length > 0 ? priceSpots.length - 1 : 0,
                  // Ensuring chart spans full data range
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= 0 && i < dates.length) {
                            return Text(
                              dates[i].substring(5),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final idx = s.x.toInt();
                        final date = idx >= 0 && idx < dates.length ? dates[idx] : '';
                        final price = s.y.toStringAsFixed(2);
                        return LineTooltipItem(
                          '$date\n₺ $price',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: priceSpots,
                      isCurved: true,
                      color: Colors.green.shade700,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.2),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 1,
                          strokeColor: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is the midpoint between buy and sell rates. Actual rate varies based on whether you buy or sell. Pricing data is provided by TrackVest.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text('Investment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFFE5E5FF), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.flight, size: 30, color: Colors.red.shade800),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Value', style: TextStyle(fontSize: 14)),
                          Text(_priceFormat.format(536.25), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('+22,73%', style: TextStyle(color: Colors.green)),
                          Text('23,56 THYAO', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Buy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Sell'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stock'),
              BottomNavigationBarItem(icon: Icon(Icons.currency_bitcoin), label: 'Crypto'),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.wallet_travel), label: 'Market'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
            currentIndex: 0,
            onTap: (i) {},
          ),
        ],
      ),
    );
  }
}
