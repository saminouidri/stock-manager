import 'package:stock_manager/model/stock.dart';

/// The StockStatistics class calculates and stores various statistics and data related to a stock.
class StockStatistics {
  final Stock _stock;

  double _price = 0.0;
  double _marketCap = 0.0;
  double _oneDayChange = 0.0;
  double _sevenDayChange = 0.0;
  double _oneMonthChange = 0.0;
  double _threeMonthChange = 0.0;
  double _oneYearChange = 0.0;
  int _stockVolume = 0;
  Map<int, double> _graphData = {};

  StockStatistics._create(this._stock);

  /// The function creates and computes statistics for a given stock.
  ///
  /// Args:
  ///   stock (Stock): The "stock" parameter is an instance of the Stock class. It represents a stock
  /// object that contains information about a particular stock, such as its symbol, name, price, and
  /// other relevant data.
  ///
  /// Returns:
  ///   The method is returning an instance of the StockStatistics class.
  static StockStatistics create(Stock stock) {
    var statistics = StockStatistics._create(stock);
    statistics._computeValues();
    return statistics;
  }

  /// The function `_computeValues` calculates various values related to a stock, such as price, market
  /// cap, and changes over different time periods.
  Future<void> _computeValues() async {
    _price = _stock.closePrice[0];
    _marketCap = _stock.marketCap * 1000000;
    _oneDayChange = (_stock.closePrice[0] / _stock.closePrice[1]) - 1;
    _sevenDayChange = (_stock.closePrice[0] / _stock.closePrice[7]) - 1;
    _oneMonthChange = (_stock.closePrice[0] / _stock.closePrice[30]) - 1;
    _threeMonthChange = (_stock.closePrice[0] / _stock.closePrice[90]) - 1;
    _oneYearChange = (_stock.closePrice[0] / _stock.closePrice[360]) - 1;
    _stockVolume = _stockVolume = _stock.tradedVolume;
    _graphData = _stock.closePrice.asMap();
  }

  //GETTERS
  double get price => _price;
  double get marketCap => _marketCap;
  double get oneDayChange => _oneDayChange;
  double get sevenDayChange => _sevenDayChange;
  double get oneMonthChange => _oneMonthChange;
  double get threeMonthChange => _threeMonthChange;
  double get oneYearChange => _oneYearChange;
  int get transactionVolume => _stockVolume;
  Map<int, double> get graphData => _graphData;
}
