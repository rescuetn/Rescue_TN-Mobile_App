import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// An abstract class (a "contract") that defines what our caching service can do.
///
/// By depending on this abstract class rather than the concrete Hive implementation,
/// we make our app more modular. If we ever wanted to switch from Hive to another
//  caching library, we would only need to update this one file.
abstract class CacheService {
  /// Saves a value to a specific box with a given key.
  Future<void> saveData<T>(String boxName, String key, T value);

  /// Reads a value from a specific box using its key.
  T? getData<T>(String boxName, String key);
}

/// A Riverpod provider to make our CacheService available throughout the app.
final cacheServiceProvider = Provider<CacheService>((ref) {
  return HiveCacheService();
});

/// The concrete implementation of our [CacheService] using the Hive package.
/// This class handles the actual logic of interacting with the local database.
class HiveCacheService implements CacheService {
  /// Saves a key-value pair to a specified Hive box.
  /// Hive boxes are like tables in a SQL database.
  @override
  Future<void> saveData<T>(String boxName, String key, T value) async {
    // Before we can write to a box, we must ensure it's open.
    final box = await Hive.openBox<T>(boxName);
    // 'put' is the Hive command to save data. It will either create a new entry
    // or update an existing one with the same key.
    await box.put(key, value);
  }

  /// Retrieves data from a specified Hive box using a key.
  /// Returns null if the box isn't open or the key doesn't exist.
  @override
  T? getData<T>(String boxName, String key) {
    // It's good practice to check if a box is open before trying to read from it.
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box<T>(boxName);
      return box.get(key);
    }
    // Return null if the box doesn't exist or isn't open yet.
    return null;
  }
}

// --- IMPORTANT SETUP NOTE ---
// To use this service, you must initialize Hive when your app starts.
// Add `await Hive.initFlutter();` to your `main.dart` file before `runApp()`.
//
// Example `main.dart`:
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Hive.initFlutter(); // <-- ADD THIS LINE
//   await Firebase.initializeApp();
//   runApp(const ProviderScope(child: RescueTNApp()));
// }
