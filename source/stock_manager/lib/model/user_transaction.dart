/// The UserTransaction class represents a transaction made by a user, including the user ID, ticker
/// symbol, amount, and price.
class UserTransaction {
  final String _userID;
  final String _ticker;
  final double _amount;
  final double _price;

  UserTransaction(this._userID, this._ticker, this._amount, this._price);

  //GETTERS
  String get userID => _userID;
  String get ticker => _ticker;
  double get amount => _amount;
  double get price => _price;
}
