import 'package:fl_chart/fl_chart.dart';
import 'package:stock_manager/UI/trade.dart';
import 'package:stock_manager/helper/portfolio_statistics.dart';
import 'package:stock_manager/model/firestore_user.dart';
import 'package:flutter/material.dart';
import 'package:stock_manager/UI/naviguation.dart';
import 'package:stock_manager/model/user_transaction.dart';
import 'package:stock_manager/repository/stock_repository.dart';
import 'package:stock_manager/repository/transaction_repository.dart';
import 'package:stock_manager/repository/user_repository.dart';

/// The Portfolio class is a StatefulWidget in Dart that represents a portfolio.
class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  PortfolioState createState() => PortfolioState();
}

UserRepository userRepository = UserRepository.getInstance();
TransactionRepository transactionRepository =
    TransactionRepository.getInstance();

StockRepository stockRepository = StockRepository.getInstance();

/// The `PortfolioState` class represents the state of a portfolio screen in a Flutter app, including
/// user information, transaction data, portfolio statistics, data points for a line chart, analytics,
/// and UI elements.
class PortfolioState extends State {
  FirestoreUser? user;
  Future<List<UserTransaction>>? transactions;
  Future<PortfolioStatistics>? pfStats;
  Future<List<FlSpot>>? dataPoints;
  Map<String, String> analytics = {
    'Top Performer': '...',
    'Least Volatile': '...',
  };
  bool noAnalytics = false;

  @override
  void initState() {
    super.initState();

    _loadData().then((value) => setState(() {}));
  }

  Future<void> _loadData() async {
    user = await UserRepository.getInstance().getConnected();
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/home');
    }

    transactions = transactionRepository.get(user!.uid);
    pfStats = PortfolioStatistics.create(user!.uid);
    pfStats?.then((data) {
      Map<int, double> invertedDataPoints = Map.from(data.graphData);

      invertedDataPoints.removeWhere((key, value) => key > 360);
      List<FlSpot> normalizedDataPoints = invertedDataPoints
          .map((key, value) => MapEntry(-key, value))
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();

      Map<String, double> stockChange = Map.from(data.changeSinceBuy);
      stockChange.removeWhere((key, value) =>
          double.parse(data.totalStockQuantity[key]!.toStringAsFixed(2)) ==
          0.0);
      List<MapEntry> performingStocks = List.from(stockChange.entries);

      String topPerformer = "No data";
      String leastVolatile = "No data";

      if (performingStocks.isNotEmpty) {
        performingStocks.sort((a, b) => a.value.compareTo(b.value));
        topPerformer = performingStocks.last.key;
        performingStocks.sort((a, b) => a.value.abs().compareTo(b.value.abs()));
        leastVolatile = performingStocks.first.key;
        noAnalytics = true;
      }

      setState(() {
        dataPoints = Future(() => normalizedDataPoints);
        analytics = {
          'Top Performer': topPerformer,
          'Least Volatile': leastVolatile,
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: Column(
        children: [
          // Top section
          Row(
            children: <Widget>[
              // stock rectangle
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 105, 13, 158),
                  borderRadius: BorderRadius.circular(8.0), // Rounded rectangle
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Soft shadow color
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // Shadow position
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 50.0,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 12.0),
                    Text('OVERVIEW'),
                  ],
                ),
              ),
              const SizedBox(width: 16.0), // space
              // Text outside the rounded rectangle

              FutureBuilder(
                  future: pfStats,
                  builder: (context, snapshot) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Valuation',
                              style: TextStyle(fontSize: 12.0)),
                          const SizedBox(
                              height: 8.0), // Spacing between the texts
                          Text(
                              '${snapshot.data?.lastValuation.toStringAsFixed(2) ?? "0"}USD',
                              style: const TextStyle(fontSize: 16.0)),
                        ],
                      )),
              const SizedBox(width: 16.0),
              FutureBuilder(
                  future: pfStats,
                  builder: (context, snapshot) {
                    double change =
                        snapshot.hasData && snapshot.data?.lastValuation != 0.0
                            ? double.parse(
                                snapshot.data!.oneYearChange.toStringAsFixed(2))
                            : 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('3M Change',
                            style: TextStyle(fontSize: 12.0)),
                        const SizedBox(
                            height: 8.0), // Spacing between the texts
                        Text(
                          '${snapshot.data?.lastValuation == 0.0 ? "-- " : ((snapshot.data?.lastValuation ?? 0) - ((1 / ((snapshot.data?.threeMonthChange ?? 0) + 1)) * (snapshot.data?.lastValuation ?? 0))).toStringAsFixed(2)}USD (${snapshot.data?.lastValuation == 0.0 ? "-- " : ((snapshot.data?.threeMonthChange ?? 0) * 100).toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: change > 0
                                ? const Color.fromARGB(255, 2, 255, 11)
                                : change < 0
                                    ? Colors.red
                                    : Colors.white,
                          ),
                        )
                      ],
                    );
                  }),
              const SizedBox(width: 16.0),
              FutureBuilder(
                  future: pfStats,
                  builder: (context, snapshot) {
                    double change =
                        snapshot.hasData && snapshot.data?.lastValuation != 0.0
                            ? double.parse(
                                snapshot.data!.oneYearChange.toStringAsFixed(2))
                            : 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('1Y Change',
                            style: TextStyle(fontSize: 12.0)),
                        const SizedBox(
                            height: 8.0), // Spacing between the texts
                        Text(
                          '${snapshot.data?.lastValuation == 0.0 ? "-- " : ((snapshot.data?.lastValuation ?? 0) - ((1 / ((snapshot.data?.oneYearChange ?? 0) + 1)) * (snapshot.data?.lastValuation ?? 0))).toStringAsFixed(2)}USD (${snapshot.data?.lastValuation == 0.0 ? "-- " : ((snapshot.data?.oneYearChange ?? 0) * 100).toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: change > 0
                                ? const Color.fromARGB(255, 2, 255, 11)
                                : change < 0
                                    ? Colors.red
                                    : Colors.white,
                          ),
                        )
                      ],
                    );
                  }),
              const SizedBox(width: 64.0),
              Expanded(child: Container()),
              FutureBuilder(
                  future: Future(() => user),
                  builder: (context, snapshot) => Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child:
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                            const SizedBox(width: 8.0),
                            Text(snapshot.data?.name ?? ""),
                          ],
                        ),
                      )),
            ],
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 600.0),
                            child: SingleChildScrollView(
                              child: FutureBuilder(
                                future: pfStats,
                                builder: (context, snapshot) {
                                  return Table(
                                    columnWidths: const <int, TableColumnWidth>{
                                      0: FixedColumnWidth(120),
                                      1: FixedColumnWidth(80),
                                      2: FixedColumnWidth(120),
                                      3: FlexColumnWidth(),
                                    },
                                    children: [
                                      const TableRow(
                                        children: [
                                          TableCell(
                                              child: Text('STOCK ASSETS')),
                                          TableCell(child: Text('QUANTITY')),
                                          TableCell(child: Text('TOTAL')),
                                          TableCell(child: Text('ROI')),
                                        ],
                                      ),
                                      const TableRow(children: [
                                        TableCell(
                                            child: Divider(
                                          thickness: 2,
                                          color: Colors.white,
                                        )),
                                        TableCell(
                                            child: Divider(
                                          thickness: 2,
                                          color: Colors.white,
                                        )),
                                        TableCell(
                                            child: Divider(
                                          thickness: 2,
                                          color: Colors.white,
                                        )),
                                        TableCell(
                                            child: Divider(
                                          thickness: 2,
                                          color: Colors.white,
                                        ))
                                      ]),
                                      if (snapshot.hasData)
                                        ...snapshot
                                            .data!.totalStockQuantity.entries
                                            .map((e) {
                                          double stockVal = double.parse(
                                              snapshot.data!
                                                  .totalStockQuantity[e.key]!
                                                  .toStringAsFixed(2));
                                          double change = double.parse((snapshot
                                                      .data!
                                                      .totalStockValue[e.key]! -
                                                  snapshot.data!
                                                      .totalBuyPrice[e.key]!)
                                              .toStringAsFixed(2));
                                          return TableRow(
                                            children: [
                                              TableCell(
                                                child: TextButton(
                                                  onPressed: () {
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              Trade(
                                                                  stockName:
                                                                      e.key)),
                                                    );
                                                  },
                                                  child: Text('\$${e.key}'),
                                                ),
                                              ),
                                              TableCell(
                                                child: Text(
                                                  (double.parse(e.value
                                                                      .toStringAsFixed(
                                                                          2)) *
                                                                  100) %
                                                              100 ==
                                                          0
                                                      ? e.value
                                                          .toStringAsFixed(0)
                                                      : e.value
                                                          .toStringAsFixed(2),
                                                  style: TextStyle(
                                                    fontSize: 16.0,
                                                    color: stockVal > 0
                                                        ? const Color.fromARGB(
                                                            255, 2, 255, 11)
                                                        : stockVal < 0
                                                            ? Colors.red
                                                            : Colors.white,
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                  child: Text(
                                                '${snapshot.data!.totalStockValue[e.key]!.toStringAsFixed(2)}\$',
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: stockVal > 0
                                                      ? const Color.fromARGB(
                                                          255, 2, 255, 11)
                                                      : stockVal < 0
                                                          ? Colors.red
                                                          : Colors.white,
                                                ),
                                              )),
                                              TableCell(
                                                child: Text(
                                                  '${(snapshot.data!.totalStockValue[e.key]! - snapshot.data!.totalBuyPrice[e.key]!) > 0 ? "+" : ""}${(snapshot.data!.totalStockValue[e.key]! - snapshot.data!.totalBuyPrice[e.key]!).toStringAsFixed(2)}\$ ${snapshot.data!.totalStockQuantity[e.key] != 0 ? "(${(snapshot.data!.changeSinceBuy[e.key]! * 100) > 0 ? "+" : ""}${(snapshot.data!.changeSinceBuy[e.key]! * 100).toStringAsFixed(2)}%)" : ""}',
                                                  style: TextStyle(
                                                    fontSize: 16.0,
                                                    color: change > 0
                                                        ? const Color.fromARGB(
                                                            255, 2, 255, 11)
                                                        : change < 0
                                                            ? Colors.red
                                                            : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList()
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  Flexible(
                      flex: 5,
                      child: FutureBuilder(
                          future: dataPoints,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return LineChart(LineChartData(
                                titlesData: const FlTitlesData(
                                  show: true,
                                  topTitles: AxisTitles(
                                    axisNameWidget: Text(
                                      "Price evolution over a year",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    axisNameWidget: Text("Price [USD]"),
                                    sideTitles: SideTitles(
                                        reservedSize: 60, showTitles: true),
                                  ),
                                  bottomTitles: AxisTitles(
                                    axisNameWidget: Text("Trading day"),
                                    sideTitles: SideTitles(
                                        reservedSize: 44, showTitles: true),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        reservedSize: 60, showTitles: true),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                      spots: snapshot.data!,
                                      isCurved: true,
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Color.fromARGB(0, 74, 255, 50),
                                            Color.fromARGB(255, 74, 255, 50)
                                          ],
                                        ),
                                        cutOffY:
                                            snapshot.data!.firstOrNull?.y ?? 0,
                                        applyCutOffY: true,
                                      ),
                                      aboveBarData: BarAreaData(
                                        show: true,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color.fromARGB(0, 226, 22, 0),
                                            Color.fromARGB(255, 226, 22, 0)
                                          ],
                                        ),
                                        cutOffY:
                                            snapshot.data!.firstOrNull?.y ?? 0,
                                        applyCutOffY: true,
                                      )),
                                ],
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: const Color(0xff37434d), width: 1),
                                ),
                                lineTouchData: LineTouchData(touchTooltipData:
                                    LineTouchTooltipData(
                                        getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((e) {
                                    return LineTooltipItem('${e.y}',
                                        const TextStyle(color: Colors.blue));
                                  }).toList();
                                })),
                                gridData: const FlGridData(show: false),
                              ));
                            } else {
                              return const CircularProgressIndicator(
                                semanticsLabel: 'Circular progress indicator',
                              );
                            }
                          })),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                ' Analytics at a quick glance',
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: analytics.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (noAnalytics)
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Trade(stockName: entry.value)),
                            );
                        },
                        child: Container(
                          width: 100.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 105, 13, 158),
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(child: Text(entry.value)),
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      Text(entry.key),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 2),
    );
  }
}
