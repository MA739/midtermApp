import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

//base authentication class for future projects

class FirebaseService {
  //add instances that allow use of each authentication method
  //create a method for each
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  static Map<String, UserEX> userMap = <String, UserEX>{};

  final StreamController<Map<String, UserEX>> _usersController =
      StreamController<Map<String, UserEX>>();

  FirebaseService() {
    _firestore.collection('users').snapshots().listen(_usersUpdated);
  }

  //method for performing simple currentUser login status
  Future<User?> getCurrentUser() async {
    return auth.currentUser;
  }

  //method for returning the a given collection. Needed for adding new users to the db
  CollectionReference getCollection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  Stream<Map<String, UserEX>> get users => _usersController.stream;

  void _usersUpdated(QuerySnapshot<Map<String, dynamic>> snapshot) {
    var users = _getUsersFromSnapshot(snapshot);
    _usersController.add(users);
  }

  Map<String, UserEX> _getUsersFromSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (var element in snapshot.docs) {
      UserEX user = UserEX.fromMap(element.id, element.data());
      userMap[user.id] = user;
    }

    return userMap;
  }

  //google sign-in method
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await auth.signInWithCredential(credential);
  }

  //facebook sign-in method
  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

    // Once signed in, return the UserCredential
    return auth.signInWithCredential(facebookAuthCredential);
  }

  //create account with email with password method
  Future<UserCredential> emailPassSignUp(String email, String password) async {
    //try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
    /*} on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }*/
    return userCredential;
  }

  Future<void> emailSignInWithPassword(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  //email without password method
  Future<void> emailSignInNoPassword() async {
    var acs = ActionCodeSettings(
        // URL you want to redirect back to. The domain (www.example.com) for this
        // URL must be whitelisted in the Firebase Console.
        url: 'https://www.example.com/finishSignUp?cartId=1234',
        // This must be true
        handleCodeInApp: true,
        //iOSBundleId: 'com.example.ios',
        androidPackageName: 'com.example.android',
        // installIfNotAvailable
        androidInstallApp: true,
        // minimumVersion
        androidMinimumVersion: '12');

    var emailAuth = 'someemail@domain.com';
    auth
        .sendSignInLinkToEmail(email: emailAuth, actionCodeSettings: acs)
        .catchError(
            (onError) => print('Error sending email verification $onError'))
        .then((value) => print('Successfully sent email verification'));

    //emailLink is placeholder for the DynamicLink that will be created for the app
    String emailLink = "";
    if (auth.isSignInWithEmailLink(emailLink)) {
      // The client SDK will parse the code from the link for you.
      auth
          .signInWithEmailLink(email: emailAuth, emailLink: emailLink)
          .then((value) {
        // You can access the new user via value.user
        var userEmail = value.user;
        print('Successfully signed in with email link!');
      }).catchError((onError) {
        print('Error signing in with email link $onError');
      });
    }
  }

  //phone # sign-in
  Future<void> phoneNumSignIn() async {
    await auth.verifyPhoneNumber(
      //dummy phone num value
      phoneNumber: '+44 7123 123 456',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        String smsCode = 'xxxx';
        // Create a PhoneAuthCredential with the code
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: smsCode);
        // Sign the user in (or link) with the credential
        await auth.signInWithCredential(credential);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //automatic resolution method timed out
      },
    );
  }

  //anonymous sign-in
  Future<UserCredential> anonSignIn() async {
    UserCredential userCredential = await auth.signInAnonymously();
    return userCredential;
  }

  //email verification
  Future<void> verifyEmail() async {
    User? user = auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  //signout method
  Future<void> signOut() async {
    await auth.signOut();
  }
}

class UserEX {
  UserEX({
    required this.id,
    required this.picture,
    required this.name,
  });

  factory UserEX.fromMap(String id, Map<String, dynamic> data) {
    return UserEX(id: id, picture: data['picture'], name: data['display_name']);
  }

  final String id;
  final String? picture;
  final String name;
}
