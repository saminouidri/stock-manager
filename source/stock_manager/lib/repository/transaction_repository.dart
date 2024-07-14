import 'package:stock_manager/model/user_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The `TransactionRepository` class is responsible for retrieving and saving user transactions from/to
/// a Firestore database.
class TransactionRepository {
  static final TransactionRepository _instance =
      TransactionRepository._create();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  TransactionRepository._create();

  /// The function returns an instance of the TransactionRepository class.
  ///
  /// Returns:
  ///   The method is returning an instance of the TransactionRepository class.
  static TransactionRepository getInstance() {
    return _instance;
  }

  /// The function retrieves a list of user transactions from a database based on the user ID.
  ///
  /// Args:
  ///   userID (String): The userID parameter is a string that represents the unique identifier of a
  /// user.
  ///
  /// Returns:
  ///   The method is returning a `Future` that resolves to a `List<UserTransaction>`.
  Future<List<UserTransaction>> get(String userID) async {
    List<UserTransaction> newTransactionsList =
        List<UserTransaction>.empty(growable: true);
    await _db
        .collection("transactions")
        .where("uid", isEqualTo: userID)
        .orderBy("ticker")
        .get()
        .then(
      (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          UserTransaction newTransaction = UserTransaction(
              userID,
              docSnapshot['ticker'],
              docSnapshot['amount'],
              docSnapshot['price']);
          newTransactionsList.add(newTransaction);
        }
      },
      onError: (e) => {},
    );
    return Future.value(newTransactionsList);
  }

  /// The function saves a user transaction to a database collection.
  ///
  /// Args:
  ///   transaction (UserTransaction): An object of type UserTransaction, which contains the details of
  /// a transaction made by a user.
  Future<void> save(UserTransaction transaction) async {
    await _db.collection("transactions").add({
      'uid': transaction.userID,
      'ticker': transaction.ticker,
      'amount': transaction.amount,
      'price': transaction.price,
    });
  }
}
