import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AmazonDetailScreen extends StatefulWidget {
  const AmazonDetailScreen({Key? key}) : super(key: key);

  @override
  _AmazonDetailScreenState createState() => _AmazonDetailScreenState();
}

class _AmazonDetailScreenState extends State<AmazonDetailScreen>
    with SingleTickerProviderStateMixin {
  double currentPrice = 0.0;
  double priceChange = 0.0;
  List<FlSpot> priceSpots = [];
  List<String> dates = [];
  late TabController _tabController;

  final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'eu',
    symbol: '€',
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
    const apiKey = '27d93abda55e4e19a30af71578cdf523';
    final url = Uri.parse(
      'https://api.twelvedata.com/time_series?symbol=AMZN&interval=1day&outputsize=30&apikey=$apiKey',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) return;
    final body = json.decode(resp.body);
    if (body['status'] != 'ok') return;

    final List<dynamic> ts = body['values'];
    final reversed = ts.reversed.toList();

    final spots = <FlSpot>[];
    final lab = <String>[];

    for (var i = 0; i < reversed.length; i++) {
      final close = double.parse(reversed[i]['close']);
      final date = reversed[i]['datetime'].substring(0, 10);
      spots.add(FlSpot(i.toDouble(), close));
      lab.add(date);
    }

    setState(() {
      priceSpots = spots;
      dates = lab;
      if (spots.isNotEmpty) {
        currentPrice = spots.last.y;
        priceChange = spots.length > 1
            ? spots.last.y - spots[spots.length - 2].y
            : 0.0;
      }
    });
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
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add My List', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 3),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Chip(
                  label: Text('AMZN', style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(width: 8),
                const Text('Amazon', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Image.asset(
                  'assets/images/amazon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _priceFormat.format(currentPrice),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "${isPositive ? '+' : ''}${_priceFormat.format(priceChange)} "
                  "(${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)",
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
                Tab(text: '1D'),
                Tab(text: '1W'),
                Tab(text: '1M'),
                Tab(text: '1Y'),
                Tab(text: '5Y'),
                Tab(text: 'ALL'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: priceSpots.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (v, meta) {
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
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final idx = spot.x.toInt();
                        final date = (idx >= 0 && idx < dates.length)
                            ? dates[idx]
                            : '';
                        final price = spot.y;
                        return LineTooltipItem(
                          '$date\n${_priceFormat.format(price)}',
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
                        getDotPainter:
                            (spot, percent, bar, index) =>
                            FlDotCirclePainter(
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
            Text(
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
              child: Text(
                'Investment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9CFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/amazon.png',
                        width: 30,
                        height: 50,
                      ),
                      const SizedBox(width: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Value',
                              style: TextStyle(fontSize: 14)),
                          Text(
                            _priceFormat.format(536.25),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('+22,73%',
                              style: TextStyle(color: Colors.green)),
                          Text('23,56 AMZN', style: TextStyle(fontSize: 14)),
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
                        child: Text('Buy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Text('Sell'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                label: 'Stock',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.currency_bitcoin),
                label: 'Crypto',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wallet_travel),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
            currentIndex: 2,
            onTap: (i) {},
          ),
        ],
      ),
    );
  }
}
