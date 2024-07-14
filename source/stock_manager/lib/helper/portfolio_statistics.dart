import 'dart:async';
import 'package:stock_manager/model/stock.dart';
import 'package:stock_manager/model/user_transaction.dart';
import 'package:stock_manager/repository/stock_repository.dart';
import 'package:stock_manager/repository/transaction_repository.dart';

/// The `PortfolioStatistics` class is responsible for computing and storing various statistics related
/// to a user's stock portfolio.
class PortfolioStatistics {
  final String _userID;

  //GLOBAL STATS
  double _lastValuation = 0.0;
  double _oneDayChange = 0.0;
  double _sevenDayChange = 0.0;
  double _oneMonthChange = 0.0;
  double _threeMonthChange = 0.0;
  double _oneYearChange = 0.0;
  final Map<int, double> _graphData = {};

  //STOCK-RELATED STATS
  final Map<String, double> _totalStockQuantity = {};
  final Map<String, double> _totalStockValue = {};
  final Map<String, double> _changeSinceBuy = {};
  final Map<String, double> _totalBuyPrice = {};

  PortfolioStatistics._create(this._userID);

  /// The function creates a new instance of PortfolioStatistics for a given userID and computes its
  /// values asynchronously.
  ///
  /// Args:
  ///   userID (String): The userID parameter is a unique identifier for a user. It is used to create a
  /// new instance of the PortfolioStatistics class and perform computations on the statistics for that
  /// specific user.
  ///
  /// Returns:
  ///   a Future object that resolves to a PortfolioStatistics object.
  static Future<PortfolioStatistics> create(String userID) async {
    var statistics = PortfolioStatistics._create(userID);

    await statistics._computeValues();

    return statistics;
  }

  /// The `_computeValues` function calculates various statistics and values related to user
  /// transactions and stock data.
  Future<void> _computeValues() async {
    StockRepository sr = StockRepository.getInstance();
    TransactionRepository tr = TransactionRepository.getInstance();

    List<UserTransaction> userTransactions = await tr.get(_userID);
    Map<String, Stock> stockData = {};

    //LOOP THROUGH TRANSACTIONS
    for (UserTransaction transaction in userTransactions) {
      if (stockData[transaction.ticker] == null) {
        stockData[transaction.ticker] = await sr.get(transaction.ticker);
      }
      if (_totalStockQuantity[transaction.ticker] == null) {
        _totalStockQuantity[transaction.ticker] = transaction.amount;
        _totalBuyPrice[transaction.ticker] =
            transaction.amount * transaction.price;
      } else {
        _totalStockQuantity[transaction.ticker] =
            _totalStockQuantity[transaction.ticker]! + transaction.amount;
        _totalBuyPrice[transaction.ticker] =
            _totalBuyPrice[transaction.ticker]! +
                (transaction.amount * transaction.price);
      }
      _totalStockValue[transaction.ticker] =
          _totalStockQuantity[transaction.ticker]! *
              stockData[transaction.ticker]!.closePrice[0];
      _changeSinceBuy[transaction.ticker] =
          (_totalStockValue[transaction.ticker]! /
                  _totalBuyPrice[transaction.ticker]!) -
              1;
    }

    //COMPUTE GLOBAL STATISTICS
    for (int day = 0; day < 365; day++) {
      _graphData[day] = 0.0;
    }

    _totalStockQuantity.forEach((ticker, amount) {
      for (int day = 0; day < 365; day++) {
        _graphData[day] =
            _graphData[day]! + amount * stockData[ticker]!.closePrice[day];
      }
    });

    _lastValuation = _graphData[0]!;
    _oneDayChange = (_graphData[0]! / _graphData[1]!) - 1;
    _sevenDayChange = (_graphData[0]! / _graphData[7]!) - 1;
    _oneMonthChange = (_graphData[0]! / _graphData[30]!) - 1;
    _threeMonthChange = (_graphData[0]! / _graphData[90]!) - 1;
    _oneYearChange = (_graphData[0]! / _graphData[360]!) - 1;
  }

  //GETTERS
  double get lastValuation => _lastValuation;
  double get oneDayChange => _oneDayChange;
  double get sevenDayChange => _sevenDayChange;
  double get oneMonthChange => _oneMonthChange;
  double get threeMonthChange => _threeMonthChange;
  double get oneYearChange => _oneYearChange;
  Map<int, double> get graphData => _graphData;
  Map<String, double> get totalStockQuantity => _totalStockQuantity;
  Map<String, double> get totalStockValue => _totalStockValue;
  Map<String, double> get changeSinceBuy => _changeSinceBuy;
  Map<String, double> get totalBuyPrice => _totalBuyPrice;
}
