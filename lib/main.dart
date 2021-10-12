import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:date_format/date_format.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //declare class from imported file

  runApp(MyApp());
}

//creates instance of imported FireBaseService Class
FirebaseService service = new FirebaseService();
FirebaseStorage storage = FirebaseStorage.instance;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var UController = TextEditingController();
  var PController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    PController.dispose();
    UController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Center(
              //padding: EdgeInsets.fromLTRB(3.0, 20.0, 3.0, 0.0,),
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            TextField(
              controller: UController,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Email'),
            ),
            TextField(
                obscureText: true,
                controller: PController,
                decoration: const InputDecoration(
                    /*prefixText: 'prefix',*/
                    border: OutlineInputBorder(),
                    hintText: 'Password')),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
                primary: Colors.black,
                textStyle: const TextStyle(fontSize: 25),
              ),
              onPressed: () => {
                if (UController.text == "" || PController.text == "")
                  {
                    showDialog<String>(
                      //if password and username match database, allow login and navigate to mainpage (pictures, etc)
                      //Otherwise send a popup that the login credentials were incorrect
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Login Status'),
                        content:
                            const Text('Please enter your login information.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              UController.clear();
                              PController.clear();
                              Navigator.pop(context, 'OK');
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    )
                  }
                else
                  {
                    service.emailSignInWithPassword(UController.text, PController.text),
                    if (service.getCurrentUser() != null)
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ContentPage())),
                    }
                    //emailSignInWithPassword(UController.text, PController.text),
                    //Navigator.push(context, MaterialPageRoute(builder: (context) => ContentPage())),
                  }
              },
              child: const Text('Login'),
              //onPressed: () =>{attemptLogin()}
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
                primary: Colors.black,
                //textStyle: const TextStyle(Fontweight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationForm()),
                );
              },
              child: const Text('Create New Account'),
            ),
          ]))),
    );
  }
}

class RegistrationForm extends StatelessWidget {
  RegistrationForm({Key? key}) : super(key: key);
  //Controllers for first name, last name, etc
  //FNController, EController, PwController, bioController, homeController, ageController
  var FNController = TextEditingController();
  var EController = TextEditingController();
  var PwController = TextEditingController();
  var bioController = TextEditingController();
  var homeController = TextEditingController();
  var ageController = TextEditingController();

  //variable for storing image selected by user
  XFile? x_image;
  //var imageFile;
  //Image picker
  final ImagePicker picker = ImagePicker();


//code snippet provided by: https://medium.com/fabcoding/adding-an-image-picker-in-a-flutter-app-pick-images-using-camera-and-gallery-photos-7f016365d856
  _imgFromGallery(BuildContext context) async {
  final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, imageQuality: 50
  );
  x_image = image;
  ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Image Selected. But it will not be pushed to firestore")));
  //upload image to firebase storage
  /*storage.ref().put(x_image)
    .then(snapshot => {
        console.log('Uploaded.');
  //imageFile = File(x_image?.path);
    });*/
}

/*Future<Uri> uploadImageFile(XFile? image) async {
    var storageRef = storage.ref();
    UploadTaskSnapshot uploadTaskSnapshot = await storageRef.put(image).future;
    
    Uri imageUri = await uploadTaskSnapshot.ref.getDownloadURL();
    return imageUri;
}*/

  Future<void> addUser (String Name, String bio, String hometown, String age, String email, String pass, BuildContext context) async {
    // Call the user's Reference to add a new user
    bool errorThrown = true;
    try{
    UserCredential userCredential = await service.emailPassSignUp(email, pass);
    errorThrown = false;
    }
     on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        errorThrown = true;
        print('The password provided is too weak.');
        ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("The password provided is too weak.")));
          //return;
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("The account already exists for that email.")));
          errorThrown = true;
          //return;
      }
    } catch (e) {
      print(e);
      return;
    }
    //assuming everything went well with the email registration
    if (errorThrown == false && service.getCurrentUser() != null)
    {
      print('DATE' + DateTime.now().toString());
      var user = await service.getCurrentUser();
      String uid = user!.uid;

      //dateTime object
      var now = DateTime.now();
      var regisDate = formatDate(now, [mm, "/", dd, "/", yyyy]);
          service
          .getCollection('users')
          //.doc(userCredential.user!.uid)
          .add({
            //'Email': Email, // xyz@gmail.com
            'id': Name, // Stokes and Sons
            'Registration DateTime': regisDate, //insert function to grab time/date, format it, and convert it to string
            'Bio': bio,
            'HomeTown': hometown,
            'Age': age,
            'UID': uid,
             //'picture': defaultImageURL,
            //'UID': uid,
            //'Password': Pass
          })
          .then((value) => print("User Added"))
          .catchError((error) => 
          print("Failed to add user: $error"));
          Navigator.of(context).pop();
          //Navigator.of(context)..pop();

      //send popup showing that the user registered successfully. When the user clicks "ok", send them back to login page
    //} else {}
    }
  }

  @override
  //wall of textfields...
  Widget build(BuildContext context) {
    return Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: Center(
                        //padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0,),
                        child: new Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
	                            // Even Padding On All Sides
                              padding: EdgeInsets.all(20.0)),
                  TextField(
                    //scrollPadding: EdgeInsets.fromTLRB(0.0, 20.0, 0.0, 0.0),
                    controller: FNController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'User Name'),
                  ),
                  TextField(
                    controller: EController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Email'),
                  ),
                  TextField(
                    controller: PwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Password'),
                  ),
                  TextField(
                    controller: homeController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Hometown'),
                  ),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Bio'),
                  ),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Age'),
                  ),
                  new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('Upload photo from library'),
                    onTap: () {
                      _imgFromGallery(context);
                      //then display selected photo in preview
                      //Navigator.of(context).pop();
                    }),
                    
                    //child: CircleAvatar(
                    /*CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xffFDCF09),
                    child: imageFile != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        //imageFile,
                        width: 100,
                        height: 100,
                        fit: BoxFit.fitHeight,
                      ),
                    )
                    : Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(50)),
                      width: 100,
                      height: 100,
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.grey[800],
                        ),
                    ),
                  ),*/
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      primary: Colors.black,
                      //textStyle: const TextStyle(Fontweight.bold),
                    ),
                    //submit values to firestore
                    onPressed: () => {
                      //email/password authentication here

                      //1constructor String FName, String LName, String Email, String Pass, --String UID--, --String Role--
                      //user's data here
                          //service.emailPassSignUp(EController.text, PwController.text),
                          if(FNController.text == "" || EController.text == "" || PwController.text == "" ||
                           bioController.text == "" || homeController.text == "" || ageController.text == "")
                           {
                             showDialog<String>(
                            //if password and username match database, allow login and navigate to mainpage (pictures, etc)
                            //Otherwise send a popup that the login credentials were incorrect
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Login Status'),
                              content:
                                  const Text('Fill out all fields'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => {
                                    //navigates back to login page
                                    //Navigator.of(context)..pop()..pop()
                                    Navigator.pop(context, 'OK'),
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          )
                           }
                           else
                           {
                            addUser(FNController.text, bioController.text,
                            homeController.text, ageController.text, EController.text, PwController.text, context)
                          },
                    },
                    child: const Text('Register'),
                  )
                ])))));
  }
}

class ContentPage extends StatefulWidget {
  const ContentPage({Key? key}) : super(key: key);
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  //allows change and access after role is fetched from firebase
  String userRole = "Customer";

  var MController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    MController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('FandomApp'),
        actions: <Widget>[
          FlatButton(
            textColor: Colors.white,
            //logout action here. Well... pop up asking if they want to log out. On ok press, logout and return to login screen
            onPressed: () {
              showDialog<String>(
                //confirm user signout
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  content: const Text('Are you sure you want to log out?'),
                  actions: <Widget>[
                    TextButton(
                      //This is where it would navigate to the actual app's content
                      onPressed: () => {
                        service.auth.signOut(),
                        Navigator.of(context).popUntil((route) => route.isFirst)
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: Text("Log Out"),
            shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder(
            //adapt
            stream: service
                .getCollection('users')
                //.orderBy('Date Time Posted')
                .snapshots(),
            //builder: buildMessageList,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                // <3> Retrieve `List<DocumentSnapshot>` from snapshot
                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                return ListView(
                    children: documents
                        .map((doc) => Card(
                              child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: Image.network('https://www.anime-planet.com/images/characters/71837.jpg?t=1556309919').image
                                    // ImageProvider.asset(doc['picture']), // no matter how big it is, it won't overflow
                                    ),
                                  title: //Text('Name'),
                                  Text(doc['id']),
                                  subtitle: //Text('Date')
                                  //Text(doc[])
                                  Text((doc['Registration DateTime'])),
                                  //Text((doc['Registration DateTime'].toDate().toString()))
                                  
                                  onTap: () => {
                                    //load a new page that pulls info from the clicked item's collections db
                                    //send doc.uid into the constructor
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => profilePage(
                                      //docID : doc['UID']
                                      ))),
                                  },
                                  //onTap: for each item, it should open a page with self-referenced data
                            )))
                        .toList());
              } else {
                return CircularProgressIndicator();
              }
            }),
      ),
    );
  }
}

class profilePage extends StatefulWidget {
  //final String docID;
  const profilePage({Key? key}) : super(key: key);

  @override  
  _profilePageState createState() => new _profilePageState();
}

class _profilePageState extends State<profilePage> {
//var docID = this.widget.docId;

Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('FandomApp')
      ),
      body: Center(
          child: Center(
              //padding: EdgeInsets.fromLTRB(3.0, 20.0, 3.0, 0.0,),
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /*StreamBuilder(
                      //adapt
                      stream: service
                      .getCollection('users')
                      //.orderBy('Date Time Posted')
                      .snapshots(),
                      //builder: buildMessageList,
                      builder:
                        (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) async{

                          if (snapshot.hasData) {
                            QuerySnapshot<Map<String, dynamic>> snapshot = await service.getCollection('users')
                            .where('UID', isEqualTo: uid)
                            .get();
                            List<QueryDocumentSnapshot> docs = snapshot.docs;
                            //should only be one doc associated with each user's ID, so it is equal to checking a single item
                            var checkDoc = docs[0].data() as Map<String, dynamic>;

                            Text(checkDoc['Bio']);
                          }}),*/
                    Text('Placeholder Name'),
                    Text('Placeholder Age'),
                    Text('Placeholder Bio'),
                    Text('Placeholder Hometown')
                  ]))),
    );
  }
}