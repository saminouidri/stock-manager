import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stock_manager/model/firestore_user.dart';
import 'package:stock_manager/model/stock.dart';
import 'package:stock_manager/model/user_transaction.dart';
import 'package:stock_manager/repository/stock_repository.dart';
import 'package:stock_manager/repository/transaction_repository.dart';
import 'package:stock_manager/repository/user_repository.dart';
import 'naviguation.dart';

/// The Trade class is a StatefulWidget that represents a trade and has a stockName property.
class Trade extends StatefulWidget {
  late final String stockName;

  Trade({required this.stockName});

  @override
  TradeState createState() => TradeState();
}

/// The TradeState class is responsible for managing the state and UI of the Trade screen, including
/// fetching stock data, handling user transactions, and displaying relevant information and controls.
class TradeState extends State<Trade> {
  final List<bool> _selectedOrderMode = <bool>[true, false];
  late Future<FirestoreUser?> user;
  List<FlSpot> dataPoints = List.empty(growable: true);
  String? transactionTicker;
  bool _isUserConnected = false;

  late Future<Stock> stock;
  late final TextEditingController searchController;
  late final TextEditingController priceController;
  late final TextEditingController amountController;

  @override
  void initState() {
    super.initState();
    user = UserRepository.getInstance().getConnected();

    user.then((value) => setState(() {
          _isUserConnected = (value != null);
        }));

    searchController = TextEditingController();
    priceController = TextEditingController();
    amountController = TextEditingController();

    _fetchStockData(widget.stockName);
  }

  _fetchStockData(String stockName) {
    StockRepository sr = StockRepository.getInstance();
    stock = sr.get(stockName);
    stock.then((stockdata) {
      Map<int, double> invertedDataPoints =
          Map.from(stockdata.stockStatistics.graphData);
      invertedDataPoints.removeWhere((key, value) => key > 360);
      List<FlSpot> normalizedDataPoints = invertedDataPoints
          .map((key, value) => MapEntry(-key, value))
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();
      setState(() {
        dataPoints = normalizedDataPoints;
        transactionTicker = stockdata.ticker;
      });
    });
  }

  void _addTransaction(
      double? price, double? amount, bool buy, bool sell) async {
    final FirestoreUser? transactionUser =
        await UserRepository.getInstance().getConnected();
    if (transactionUser != null &&
        transactionTicker != null &&
        price != null &&
        amount != null) {
      TransactionRepository tr = TransactionRepository.getInstance();
      List<UserTransaction> transactionsList =
          await tr.get(transactionUser.uid);
      double userStockAmount = 0.0;
      for (UserTransaction transaction in transactionsList) {
        if (transaction.ticker == transactionTicker) {
          userStockAmount +=
              double.parse(transaction.amount.toStringAsFixed(2));
        }
      }
      if ((buy && !sell) || (!buy && sell)) {
        final transactionPrice = price.abs();
        var transactionAmount = double.parse(amount.abs().toStringAsFixed(2));
        if (buy || (sell && transactionAmount <= userStockAmount)) {
          if (sell) {
            transactionAmount = -transactionAmount;
          }
          UserTransaction newTransaction = UserTransaction(transactionUser.uid,
              transactionTicker!, transactionAmount, transactionPrice);
          await tr.save(newTransaction);
          setState(() {
            amountController.text = "";
          });
        }
      }
    }
  }

  void _searchStock(String search) async {
    try {
      String ticker = search.toUpperCase();
      _fetchStockData(ticker);
    } catch (e) {
      //ERROR
    }
  }

  Future<Iterable<String>> _suggestSearch(String search) async {
    final FirestoreUser? transactionUser =
        await UserRepository.getInstance().getConnected();
    String tickerSearched = search.toUpperCase();
    if (transactionUser != null) {
      TransactionRepository tr = TransactionRepository.getInstance();
      List<UserTransaction> transactionsList =
          await tr.get(transactionUser.uid);
      Set<String> tickerList = {};
      for (UserTransaction transaction in transactionsList) {
        if (transaction.ticker.contains(tickerSearched)) {
          tickerList.add(transaction.ticker);
        }
      }
      return Future.value(tickerList);
    }
    return Future.value(List.empty());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<Widget> orderMode = <Widget>[Text('Buy'), Text('Sell')];

    List<String> similarStocks = ['GOOG', 'AAPL', 'TSLA', 'AMZN', 'MSFT'];

    return Scaffold(
      appBar: AppBar(title: const Text('Trade')),
      body: Column(
        children: [
          // Top section
          Row(
            children: <Widget>[
              // stock rectangle
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 105, 13, 158), // Background color
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 50.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12.0),
                    FutureBuilder(
                      future: stock,
                      builder: (context, snapshot) => Text(
                          snapshot.hasData
                              ? snapshot.data!.ticker
                              : "Loading...",
                          style: const TextStyle(fontSize: 16.0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0), // space
              // Text outside the rounded rectangle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Price', style: TextStyle(fontSize: 12.0)),
                  const SizedBox(height: 8.0),
                  FutureBuilder(
                    future: stock,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          priceController.text =
                              '${snapshot.data!.closePrice[0]}';
                        });
                        return Text(
                          '${snapshot.data!.closePrice[0]} USD',
                          style: const TextStyle(fontSize: 16.0),
                        );
                      } else {
                        return const Text("Loading...",
                            style: TextStyle(fontSize: 16.0));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('24h Change', style: TextStyle(fontSize: 12.0)),
                  const SizedBox(height: 8.0),
                  FutureBuilder(
                    future: stock,
                    builder: (context, snapshot) {
                      bool isPositive = snapshot.hasData &&
                          snapshot.data!.stockStatistics.oneDayChange > 0;

                      return Text(
                        snapshot.hasData
                            ? '${(snapshot.data!.closePrice[0] - snapshot.data!.closePrice[1]).toStringAsFixed(2)} USD (${(snapshot.data!.stockStatistics.oneDayChange * 100).toStringAsFixed(2)} %)'
                            : "Loading...",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: isPositive
                              ? const Color.fromARGB(255, 2, 255, 11)
                              : Colors.red,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Market Cap', style: TextStyle(fontSize: 12.0)),
                  const SizedBox(height: 8.0),
                  FutureBuilder(
                    future: stock,
                    builder: (context, snapshot) => Text(
                        snapshot.hasData
                            ? '${snapshot.data!.marketCap} M'
                            : "Loading...",
                        style: const TextStyle(fontSize: 16.0)),
                  ),
                ],
              ),
              const SizedBox(width: 64.0),
              SizedBox(
                width: 200.0,
                child: Autocomplete<String>(
                  fieldViewBuilder: (context, textEditingController, focusNode,
                          onFieldSubmitted) =>
                      TextField(
                    controller: textEditingController,
                    onSubmitted: (value) {
                      _searchStock(value);
                      onFieldSubmitted();
                    },
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _suggestSearch(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _searchStock(selection);
                  },
                ),
              ),
              Expanded(child: Container()),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 8.0),
                    FutureBuilder(
                      future: user,
                      builder: (context, snapshot) => Text(
                          snapshot.hasData ? snapshot.data!.name : "Log in",
                          style: const TextStyle(fontSize: 16.0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(''),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text('Limit price',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 200.0, height: 8.0),
                                TextField(
                                  controller: priceController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: '...',
                                  ),
                                ),
                                const SizedBox(width: 200.0, height: 16.0),
                                // Second title and TextField
                                const Text('Quantity',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 200.0, height: 8.0),
                                TextField(
                                  controller: amountController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: '...',
                                  ),
                                ),
                                const SizedBox(width: 200.0, height: 16.0),
                                const SizedBox(height: 5),
                                ToggleButtons(
                                  direction: Axis.horizontal,
                                  onPressed: (int index) {
                                    setState(() {
                                      for (int i = 0;
                                          i < _selectedOrderMode.length;
                                          i++) {
                                        _selectedOrderMode[i] = i == index;
                                      }
                                    });
                                  },
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  selectedBorderColor:
                                      const Color.fromARGB(255, 147, 14, 187),
                                  selectedColor: Colors.white,
                                  fillColor:
                                      const Color.fromARGB(255, 99, 25, 236),
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  constraints: const BoxConstraints(
                                    minHeight: 40.0,
                                    minWidth: 80.0,
                                  ),
                                  isSelected: _selectedOrderMode,
                                  children: orderMode,
                                ),
                                const SizedBox(height: 16.0),

                                // Order button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: _isUserConnected
                                      ? () {
                                          final double? orderPrice =
                                              double.tryParse(
                                                  priceController.text);
                                          final double? orderQuantity =
                                              double.tryParse(
                                                  amountController.text);
                                          final bool buy =
                                              _selectedOrderMode[0];
                                          final bool sell =
                                              _selectedOrderMode[1];
                                          _addTransaction(orderPrice,
                                              orderQuantity, buy, sell);
                                        }
                                      : null,
                                  child: const Text('Order'),
                                ),
                                const SizedBox(height: 500.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Flexible(
                          flex: 2,
                          child: LineChart(
                            LineChartData(
                              titlesData: const FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(
                                  axisNameWidget: Text(
                                    "Price evolution over a year",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  axisNameWidget: Text("Price [USD]"),
                                  sideTitles: SideTitles(
                                      reservedSize: 44, showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  axisNameWidget: Text("Trading day"),
                                  sideTitles: SideTitles(
                                      reservedSize: 44, showTitles: true),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      reservedSize: 44, showTitles: true),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: dataPoints,
                                  isCurved: true,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
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
                                    cutOffY: dataPoints.firstOrNull?.y ?? 0,
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
                                    cutOffY: dataPoints.firstOrNull?.y ?? 0,
                                    applyCutOffY: true,
                                  ),
                                ),
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
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Browse Other Stocks',
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .start, // To align the rectangles to the left
              children: List.generate(
                similarStocks.length,
                (index) => Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          _fetchStockData(similarStocks[
                              index]); // This fetches data for TSLA and updates the UI
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
                          child: Center(child: Text(similarStocks[index])),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 1),
    );
  }
}
