import 'package:optionxi/DB_Services/database_write.dart';
import 'package:optionxi/DataModels/dm_reg_users.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:optionxi/DataModels/dm_watchlist_stock.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';

class DatabaseReadService {
  FirebaseDatabase db = FirebaseDatabase.instance;

  //Get Adminlist
  Future<bool> getAdminList(suid) async {
    final ref = db.ref();
    bool isadmin = false;
    DataSnapshot snapshot = await ref.child('admins').child(suid).get();

    if (snapshot.exists) {
      isadmin = true;
    }
    return isadmin;
  }

  //Get User Details
  Future<bool?> getUserDetail(suid, dm_reg_user user) async {
    final ref = db.ref();
    bool foundflag = false;
    DataSnapshot snapshot = await ref.child('regusers').child(suid).get();

    if (snapshot.exists) {
      print("User Exist");
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Welcome", "Hi ${user.rgName}, welcome back to OptionXi");
    } else {
      print('No user found');

      //Create new User
      await DatabaseWriteService().addUserData(suid, user);
    }
    return foundflag;
  }

  // Realtime Listeners for Buy Sell LTP Stocks
  // Stream<dm_stock> getrealtime_BuySellLtp_Stocks(
  //     String whichNifty, String stockname) {
  //   return FirebaseDatabase.instance
  //       .ref("livedata")
  //       .child(whichNifty) // Nifty50 or Nifty 100 or nifty 200
  //       .child(stockname)
  //       // .limitToFirst(1)
  //       .onValue
  //       .map((event) => dm_stock.fromJson(
  //           {"stckname": stockname.toString(), "ltp": event.snapshot.value}));
  // }

  // Get User Favorites
  Future<List<dm_stock>> getFavoriteStocks(String userId) async {
    final ref = db.ref();
    List<dm_stock> favoriteStocks = [];

    try {
      DataSnapshot snapshot = await ref.child('watchlists').child(userId).get();

      if (snapshot.exists) {
        var datalist = snapshot.value as Map<dynamic, dynamic>;
        datalist.forEach((key, value) {
          dm_stock stock = dm_stock.fromJson(value);
          favoriteStocks.add(stock);
        });
      }
    } catch (e) {
      print('Error getting favorite stocks: $e');
    }

    return favoriteStocks;
  }

  // Check if stock is in favorites
  Future<bool> isStockInFavorites(String userId, String stockSymbol) async {
    final ref = db.ref();
    bool isFavorite = false;

    try {
      DataSnapshot snapshot = await ref
          .child('watchlists')
          .child(userId)
          .orderByChild('stockName')
          .equalTo(stockSymbol)
          .get();

      if (snapshot.exists) {
        isFavorite = true;
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }

    return isFavorite;
  }

  // Realtime listener for favorite stocks
  Stream<List<dm_stock>> streamFavoriteStocks(String userId) {
    return FirebaseDatabase.instance
        .ref("watchlists")
        .child(userId)
        .onValue
        .map((event) {
      List<dm_stock> stocks = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          dm_stock stock = dm_stock.fromJson(value);
          stocks.add(stock);
        });
      }
      return stocks;
    });
  }
}
