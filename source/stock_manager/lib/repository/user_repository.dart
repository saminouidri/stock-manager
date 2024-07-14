import 'package:firebase_auth/firebase_auth.dart';
import 'package:stock_manager/model/firestore_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The UserRepository class is responsible for handling user data in Firestore, including retrieving,
/// saving, and removing user information.
class UserRepository {
  static final UserRepository _instance = UserRepository._create();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRepository._create();

  /// The function returns an instance of the UserRepository class.
  ///
  /// Returns:
  ///   The method is returning an instance of the UserRepository class.
  static UserRepository getInstance() {
    return _instance;
  }

  /// The function `getConnected` returns a `Future` that resolves to a `FirestoreUser` object if the
  /// user is authenticated, otherwise it resolves to `null`.
  ///
  /// Returns:
  ///   The function `getConnected()` returns a `Future` that resolves to a `FirestoreUser` object or
  /// `null`.
  Future<FirestoreUser?> getConnected() async {
    User? usr = FirebaseAuth.instance.currentUser;
    if (usr != null) {
      return get(usr.uid);
    } else {
      return Future.value(null);
    }
  }

  /// The function retrieves a FirestoreUser object from the Firestore database based on the provided
  /// userID.
  ///
  /// Args:
  ///   userID (String): The `userID` parameter is a string that represents the unique identifier of a
  /// user in the Firestore database.
  ///
  /// Returns:
  ///   The method is returning a `Future<FirestoreUser>`.
  Future<FirestoreUser> get(String userID) async {
    FirestoreUser newUser = FirestoreUser("", "Unknown");
    await _db.collection("users").doc(userID).get().then(
      (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        newUser = FirestoreUser(userID, data['name']);
      },
      onError: (e) => {},
    );
    return Future.value(newUser);
  }

  /// The function removes a user document from a Firestore collection based on the provided userID.
  ///
  /// Args:
  ///   userID (String): The userID parameter is a string that represents the unique identifier of the
  /// user to be removed from the database.
  Future<void> remove(String userID) async {
    await _db.collection("users").doc(userID).delete();
  }

  /// The `save` function saves the user's name to the Firestore database.
  ///
  /// Args:
  ///   user (FirestoreUser): The user parameter is an instance of the FirestoreUser class, which
  /// represents a user in the Firestore database. It contains information about the user, such as their
  /// unique identifier (uid) and their name.
  Future<void> save(FirestoreUser user) async {
    await _db.collection("users").doc(user.uid).set({'name': user.name});
  }
}
