/// The FirestoreUser class represents a user in Firestore with a unique ID and a name, and provides
/// getters and setters for accessing and modifying the user's name.
class FirestoreUser {
  final String _uid;
  String _name;

  FirestoreUser(this._uid, this._name);

  @override
  String toString() {
    return "$_name; $_uid";
  }

  //GETTERS
  String get name => _name;
  String get uid => _uid;

  //SETTERS
  set name(String name) {
    if (name.length > 20) {
      _name = name.substring(1, 21);
    } else {
      _name = name;
    }
  }
}
