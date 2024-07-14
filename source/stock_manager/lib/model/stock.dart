import 'package:stock_manager/helper/stock_statistics.dart';

/// The Stock class represents a stock with its ticker symbol, close prices, last updated timestamp,
/// market capitalization, traded volume, and optional stock statistics.
class Stock {
  final String _ticker;
  final List<double> _closePrice;
  //int(unix/3600) -> une heure de différence = récupération
  final int _lastUpdated;
  final int _marketCap;
  final int _tradedVolume;
  StockStatistics? _stockStatistics;

  Stock(this._ticker, this._closePrice, this._lastUpdated, this._marketCap,
      this._tradedVolume);

  @override
  String toString() {
    return "$_ticker; $_closePrice; $_lastUpdated; $_marketCap; $_tradedVolume";
  }

  //GETTERS
  String get ticker => _ticker;
  List<double> get closePrice => _closePrice;
  int get lastUpdated => _lastUpdated;
  int get marketCap => _marketCap;
  int get tradedVolume => _tradedVolume;
  StockStatistics get stockStatistics =>
      _stockStatistics ??= StockStatistics.create(this);
}
