import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  List<Contact> _mytelContactList = [];
  List<String> _mytelList = [];
  var permission = 1;
  var loading = true;
  var message = "";
  _ContactListState() {
    checkPermission();
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Done'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'If you are using google contact, it will take time for sync but it was deleted in contact list. Please go and check.')
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void deleteMyTel() {
    setState(() {
      loading = true;
      message = "Deleting ...";
    });

    _mytelContactList.forEach((c) async {
      setState(() {
        message = "Deleting ${c.displayName}";
      });

      List<Item> notMyTel =
          c.phones.where((e) => !shouldRemove(e.value)).toList();
      c.phones = notMyTel;
      await Contacts.updateContact(c);
    });

    setState(() {
      loading = false;
      _mytelContactList = [];
      _mytelList = [];
    });

    _showMyDialog();
  }

  bool shouldRemove(String number) {
    RegExp exp = RegExp(r"(09|\+?959)6\d{8}$");
    return (exp.allMatches(number).length > 0);
  }

  void getList() async {
    List<Contact> mytelContactList = [];
    List<String> mytelList = [];

    await Contacts.streamContacts().forEach((contact) {
      setState(() {
        message = "Find in ${contact.displayName}";
      });
      var currentPhone = false;

      contact.phones.forEach((n) {
        var mytel = shouldRemove(n.value);

        if (mytel) {
          mytelList.add("${contact.displayName} : ${n.value}");
          currentPhone = true;
        }
        return mytel;
      });

      if (currentPhone) {
        mytelContactList.add(contact);
      }
    });

    setState(() {
      _mytelContactList.addAll(mytelContactList);
      _mytelList.addAll(mytelList);
      loading = false;
    });
  }

  Future<void> checkPermission() async {
    var contactPermission = await Permission.contacts.status;
    var askPermission = contactPermission.isUndetermined;
    var disablePermission = contactPermission.isRestricted;
    var ready = contactPermission.isGranted;

    print(ready);

    if (askPermission) {
      await Permission.contacts.request();
      checkPermission();
    } else if (disablePermission) {
      //not allopw
      setState(() {
        permission = 3;
      });
    } else if (ready) {
      getList();
      setState(() {
        permission = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
// You can can also directly ask the permission about its status.

    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("MyTel Remover"),
        ),
        body: buildBody());
  }

  Widget buildBody() {
    if (permission == 1) {
      return Text("Waiting Permission");
    } else if (permission == 3) {
      return Text("Please allow permission");
    }

    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(
              height: 12,
            ),
            Text(message)
          ],
        ),
      );
    }

    return Column(
      children: [
        RaisedButton(
          onPressed: () => deleteMyTel(),
          child: Text('Delete All (${_mytelList.length} Phone numbers)'),
        ),
        Expanded(
          child: ListView.separated(
              separatorBuilder: (context, index) {
                return Divider();
              },
              padding: const EdgeInsets.all(8),
              itemCount: _mytelList.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(_mytelList[index]);
              }),
        )
      ],
    );
  }
}
