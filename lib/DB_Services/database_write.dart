import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/DataModels/dm_reg_users.dart';
import 'package:optionxi/DataModels/dm_watchlist_stock.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';

class DatabaseWriteService {
  FirebaseDatabase db = FirebaseDatabase.instance;

  Future<bool> updateUserFCM(String uidkey, String fcmkey) async {
    // bool is_sucess = false;
    final ref = db.ref();
    if (uidkey == "null") {
      // GlobalSnackBarGet().showGetError("Error", "No user key found");
      return false;
    }
    try {
      // make sure to use await function for catching exception
      ref.child("fcmlist").child(uidkey).child("fcmkey").set(fcmkey);
    } on PlatformException catch (err) {
      print("Catched error: $err");
      return false;
    } catch (e) {
      print("Catched the database error:$e");
      return false;
    }

    return true;
  }

  //Add registered user details, logged in users
  Future<bool> addUserData(suid, dm_reg_user user) async {
    bool is_sucess = false;
    final ref = db.ref();

    try {
      // make sure to use await function for catching exception
      await ref.child('regusers').child(suid).set(user.toJson());
      GlobalSnackBarGet().showGetSucess("Registered", "Welcome ${user.rgName}");
      is_sucess = true;
    } on PlatformException catch (err) {
      GlobalSnackBarGet().showGetError("Error", err.toString());
      print("Catched error: $err");
    } catch (e) {
      print("Catched the database error:$e");
      GlobalSnackBarGet().showGetError("Error", "Something else went wrong");
    }

    return is_sucess;
  }

  // Add stock to favorites/watchlist
  Future<void> addToFavorites(String userId, dm_stock stock) async {
    final ref = db.ref();
    try {
      String stockKey = stock.stockName.replaceAll('.', '_');
      await ref.child('watchlists').child(userId).child(stockKey).set({
        'stockName': stock.stockName,
        'fullStockName': stock.fullStockName,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // GlobalSnackBarGet().showGetSuccessOnTop("Added to Favorites",
      //     "${stock.fullStockName} added to your watchlist");
    } catch (e) {
      print('Error adding to favorites: $e');
      GlobalSnackBarGet().showGetError(
          "Error", "Failed to add to favorites. Please try again.");
    }
  }

  Future<void> removeFromFavorites(String userId, String stockKey) async {
    final ref = db.ref();

    // Try removing both -EQ and -BE variants
    final String stockKeyEQ = stockKey.replaceAll('-BE', '-EQ');
    final String stockKeyBE = stockKey.replaceAll('-EQ', '-BE');

    try {
      // Attempt to remove both possibilities
      await ref.child('watchlists').child(userId).child(stockKeyEQ).remove();
      await ref.child('watchlists').child(userId).child(stockKeyBE).remove();

      // Optional: You could also check if either of the keys existed before removing,
      // and show a custom success message accordingly

      // Example: Show success snackbar
      // GlobalSnackBarGet().showGetSuccessOnTop("Removed from Favorites", "$stockKey removed from your watchlist");
    } catch (e) {
      print('Error removing from favorites: $e');
      GlobalSnackBarGet().showGetError(
        "Error",
        "Failed to remove from favorites. Please try again.",
      );
    }
  }

  // Toggle favorite status (add if not in favorites, remove if already in favorites)
  Future<void> toggleFavorite(String userId, dm_stock stock) async {
    final ref = db.ref();
    String stockKey = stock.stockName.replaceAll('.', '_');

    try {
      DataSnapshot snapshot =
          await ref.child('watchlists').child(userId).child(stockKey).get();

      if (snapshot.exists) {
        await removeFromFavorites(userId, stock.stockName.replaceAll('.', '_'));
      } else {
        await addToFavorites(userId, stock);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      GlobalSnackBarGet().showGetError(
          "Error", "Failed to update favorites. Please try again.");
    }
  }
}
