import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:near_social_mobile/config/constants.dart';

class FirebaseDatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(firebaseNearSocialProject));

  static Future<Map<String, dynamic>> getAllRecordsOfCollection(
      String collectionName) async {
    final collection = _firestore.collection(collectionName);
    final querySnapshot = await collection.get();
    final allData = querySnapshot.docs.fold<Map<String, dynamic>>({},
        (previousValue, doc) => previousValue..addAll({doc.id: doc.data()}));
    return allData;
  }

  static Future<Map<String, dynamic>?> getUserSettingsCollection(
      String userId, String collectionName) async {
    final collection = _firestore
        .collection(FirebaseDatabasePathKeys.usersPath)
        .doc(userId)
        .collection(collectionName);
    final querySnapshot = await collection.get();
    final allData = querySnapshot.docs.fold<Map<String, dynamic>>({},
        (previousValue, doc) => previousValue..addAll({doc.id: doc.data()}));
    return allData;
  }

  static Future<Map<String, dynamic>?> getRecordByPath(String path) async {
    final documentReference = _firestore.doc(path);
    final data = (await documentReference.get()).data();
    return data;
  }

  static Future<void> deleteRecordByPath(String path) async {
    final documentReference = _firestore.doc(path);
    await documentReference.delete();
  }

  static Future<void> updateRecordByPath(
      String path, Map<String, dynamic> data) async {
    final documentReference = _firestore.doc(path);
    try {
      await documentReference.update(data);
    } catch (err) {
      log(err.toString());
    }
  }

  static Future<void> updateBySetWithMergeRecordByPath(
      String path, Map<String, dynamic> data) async {
    final documentReference = _firestore.doc(path);
    await documentReference.set(data, SetOptions(merge: true));
  }

  static Future<void> setRecordByPath(
      String path, Map<String, dynamic> data) async {
    final documentReference = _firestore.doc(path);
    await documentReference.set(data);
  }

  static Future<bool> isRecordExistsByPath(String path) async {
    try {
      final documentReference = _firestore.doc(path);
      final documentSnapshot = await documentReference.get();
      return documentSnapshot.exists;
    } catch (err) {
      if (err is AssertionError &&
          err.message.toString() ==
              "a document path must point to a valid document.") {
        return false;
      }
      rethrow;
    }
  }
}
