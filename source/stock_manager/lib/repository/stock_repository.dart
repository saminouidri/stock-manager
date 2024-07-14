import 'dart:convert';

import 'package:stock_manager/model/stock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// The StockRepository class is responsible for fetching stock data from an API and storing it in a
/// local database, with a rate limit to prevent excessive API requests.
class StockRepository {
  static final StockRepository _instance = StockRepository._create();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _api = "_PPcWLqd2ZTTQjxoiM0H0SxWprPfqKTE";
  static const double _rateLimit = 2.5; //requests per minute
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  final _stockApi =
      "https://api.polygon.io/v2/aggs/ticker/{ticker}/range/1/day/{from}/{to}?adjusted=true&sort=desc&limit=5000&apiKey={api_key}";
  final _referenceApi =
      "https://api.polygon.io/v3/reference/tickers/{ticker}?apiKey={api_key}";

  StockRepository._create();

  /// The function returns an instance of the StockRepository class.
  ///
  /// Returns:
  ///   The method is returning an instance of the StockRepository class.
  static StockRepository getInstance() {
    return _instance;
  }

  /// The function retrieves stock data from a database, checks if it is older than 2 hours, and if so,
  /// updates it from an API and saves it back to the database.
  ///
  /// Args:
  ///   ticker (String): The `ticker` parameter is a string that represents the stock symbol or ticker
  /// symbol of a particular stock. It is used to identify and retrieve information about a specific
  /// stock.
  ///
  /// Returns:
  ///   a `Future<Stock>`.
  Future<Stock> get(String ticker) async {
    var stock = await _getFromDB(ticker);

    final unixTimestampNow =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1e6;

    // Check if Data is older than 2h, if so, update data from API
    if (unixTimestampNow - (stock?.lastUpdated ?? 0) >= 72e3) {
      try {
        stock = await _getFromAPI(ticker);
        await _saveToDB(stock);
      } catch (e) {}
    }

    return Future.value(stock);
  }

  /// The function retrieves stock data from a database based on a given ticker symbol and returns a
  /// Stock object.
  ///
  /// Args:
  ///   ticker (String): The ticker parameter is a string that represents the stock symbol or identifier
  /// for a particular stock.
  ///
  /// Returns:
  ///   The function `_getFromDB` returns a `Future` that resolves to a `Stock` object or `null`.
  Future<Stock?> _getFromDB(String ticker) async {
    final snapshot = await _db.collection("stocks").doc(ticker).get();

    if (!snapshot.exists) return Future(() => null);

    final data = snapshot.data() as Map<String, dynamic>;

    return Future(() => Stock(ticker, data['closeprice'].cast<double>(),
        data['lastupdated'], data['marketcap'], data['tradedVolume']));
  }

  /// The function `_saveToDB` saves stock data to a database.
  ///
  /// Args:
  ///   stock (Stock): The stock parameter is an object of the Stock class. It contains information
  /// about a particular stock, such as its ticker symbol, close price, market capitalization, traded
  /// volume, and last updated timestamp.
  Future<void> _saveToDB(Stock stock) async {
    await _db.collection("stocks").doc(stock.ticker).set({
      'closeprice': stock.closePrice,
      'marketcap': stock.marketCap,
      'tradedVolume': stock.tradedVolume,
      'lastupdated': stock.lastUpdated,
    });
  }

  /// The `_getFromAPI` function retrieves stock data from an API, including the ticker, close prices,
  /// market cap, and traded volume, and returns a `Stock` object.
  ///
  /// Args:
  ///   ticker (String): The `ticker` parameter is a string that represents the stock symbol or ticker
  /// symbol of a particular company. It is used to fetch the stock data for that specific company from
  /// an API.
  ///   retry (bool): The `retry` parameter is a boolean flag that determines whether the API call should
  /// be retried if it fails. By default, it is set to `true`, meaning that the API call will be retried
  /// if it fails. If set to `false`, the API call will not be retried. Defaults to true
  ///
  /// Returns:
  ///   The function `_getFromAPI` returns a `Future<Stock>`.
  Future<Stock> _getFromAPI(String ticker, {bool retry = true}) async {
    // Stock
    final now = DateTime.now();
    final past = now.subtract(const Duration(days: 600));

    final timeSinceLastRequest = now.difference(_lastRequest).inSeconds;

    if (timeSinceLastRequest < (60 / _rateLimit)) {
      await Future.delayed(const Duration(seconds: 30));
    }

    _lastRequest = DateTime.now();

    final to = DateFormat('yyy-MM-dd').format(now);
    final from = DateFormat('yyy-MM-dd').format(past);

    final requestStock = _stockApi
        .replaceAll(RegExp(r'{ticker}'), ticker)
        .replaceAll(RegExp(r'{from}'), from)
        .replaceAll(RegExp(r'{to}'), to)
        .replaceAll(RegExp(r'{api_key}'), _api);

    final requestReference = _referenceApi
        .replaceAll(RegExp(r'{ticker}'), ticker)
        .replaceAll(RegExp(r'{api_key}'), _api);

    final responseStock = await http.get(Uri.parse(requestStock));
    final responseReference = await http.get(Uri.parse(requestReference));
    // check if api call is successful
    if (responseStock.statusCode & responseReference.statusCode != 200) {
      if (retry) {
        await Future.delayed(const Duration(seconds: 30));
        return _getFromAPI(ticker, retry: false);
      } else {
        return Future(() => Stock("", List.empty(), 0, 0, 0));
      }
    }

    final jsonStock = jsonDecode(responseStock.body);

    final tickerStock = jsonStock['ticker'];
    final resultsStock = List.from(jsonStock['results']);
    final closePriceStock =
        resultsStock.map((stock) => stock['c']).toList().cast<double>();
    final tradedVolumeStock =
        ((resultsStock.first['v'] ?? 0) as double).round();

    // Reference
    final jsonReference = jsonDecode(responseReference.body);

    final marketCap = jsonReference['results']['market_cap'] ?? 0;

    return Future.value(Stock(
        tickerStock,
        closePriceStock,
        DateTime.now().toUtc().microsecondsSinceEpoch ~/ 1e6,
        (marketCap ~/ 1000000),
        tradedVolumeStock));
  }
}
