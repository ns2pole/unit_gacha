// lib/services/revenuecat_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../util/platform_info.dart';

/// RevenueCatサービス
class RevenueCatService {
  // product IDs（実際の App Store Connect に合わせてください）
  static const String _learningHistoryOptionProductId =
      'learning_history_option_500yen';

  // entitlement IDs（RevenueCat ダッシュボードの entitlement 名）
  static const String _learningHistoryEntitlementId = 'learning_history_option';

  // RevenueCat の public SDK キー（--dart-define で渡す。CONFIGURE.md 参照）
  static const String _defaultIosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );
  static const String _defaultAndroidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  static bool _isInitialized = false;
  static String? _initializationError;

  static bool get isInitialized => _isInitialized;
  static String? get initializationError => _initializationError;

  /// 初期化。必要ならここでビルド引数や環境変数からキーを渡す。
  /// iosApiKey/androidApiKey を渡すとそれを優先して使います。
  static Future<bool> initialize({
    String? iosApiKey,
    String? androidApiKey,
  }) async {
    if (_isInitialized) return true;

    _initializationError = null;

    try {
      if (kIsWeb) {
        _initializationError = 'RevenueCat is not supported on web.';
        if (kDebugMode) {
          debugPrint('⚠️  [WARNING] RevenueCat: $_initializationError');
        }
        return false;
      }

      final isIos = PlatformInfo.isIOS;
      final providedKey = isIos
          ? (iosApiKey ?? _defaultIosApiKey)
          : (androidApiKey ?? _defaultAndroidApiKey);

      if (providedKey.isEmpty || providedKey.startsWith('YOUR_')) {
        _initializationError =
            'RevenueCat API key is not configured for ${isIos ? 'iOS' : 'Android'}.';
        // デバッグモードでのみ警告を表示（本番環境では静かに失敗）
        if (kDebugMode) {
          debugPrint(
            '⚠️  [WARNING] RevenueCat: 初期化に失敗しました - $_initializationError',
          );
        }
        return false;
      }

      final config = PurchasesConfiguration(providedKey);
      await Purchases.configure(config);

      if (kDebugMode) {
        // デバッグログ有効化（本番では無効化推奨）
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // 軽い接続チェック（失敗しても初期化自体は成功として扱う）
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        debugPrint(
          'RevenueCat: Initialized (Customer ID: ${customerInfo.originalAppUserId})',
        );
      } catch (e) {
        debugPrint('RevenueCat: Initialized but getCustomerInfo failed: $e');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _initializationError = e.toString();
      debugPrint('RevenueCat: Initialization exception: $e');
      return false;
    }
  }

  /// 簡易接続チェック
  static Future<bool> checkConnection() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      debugPrint(
        'RevenueCat: Connection OK (Customer ID: ${info.originalAppUserId})',
      );
      return true;
    } catch (e) {
      debugPrint('RevenueCat: Connection failed: $e');
      return false;
    }
  }

  /// StoreKit Configurationファイルのテスト（ネイティブSKProductsRequestを使用）
  /// RevenueCat SDKを使わずに、直接StoreKit APIで商品情報を取得できるか確認
  /// シミュレーターの場合、XcodeスキームでStoreKit Configurationファイルが設定されている必要があります
  static Future<Map<String, dynamic>?> testStoreKitConfiguration(
    String productId,
  ) async {
    if (!PlatformInfo.isIOS) {
      debugPrint('StoreKitTest: Only available on iOS');
      return {'success': false, 'error': 'Only available on iOS'};
    }

    try {
      const platform = MethodChannel('com.joymath/storekit_test');
      final result = await platform.invokeMethod('testProductRequest', {
        'productId': productId,
      });

      if (result is Map) {
        debugPrint('StoreKitTest: Result: $result');
        return Map<String, dynamic>.from(result);
      }

      return {'success': false, 'error': 'Invalid result type'};
    } catch (e) {
      debugPrint('StoreKitTest: Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// StoreKit Configurationファイルに登録されているすべての商品を取得
  /// どの商品が利用可能かを確認するために使用
  static Future<Map<String, dynamic>?> listAllAvailableProducts() async {
    if (!PlatformInfo.isIOS) {
      debugPrint('StoreKitTest: Only available on iOS');
      return {'success': false, 'error': 'Only available on iOS'};
    }

    try {
      const platform = MethodChannel('com.joymath/storekit_test');
      final result = await platform.invokeMethod('listAllAvailableProducts');

      if (result is Map) {
        debugPrint('StoreKitTest: Available products: $result');
        return Map<String, dynamic>.from(result);
      }

      return {'success': false, 'error': 'Invalid result type'};
    } catch (e) {
      debugPrint('StoreKitTest: Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 購入判定ヘルパー
  static bool _hasPurchasedProduct(
    CustomerInfo customerInfo,
    String productId,
    String entitlementId,
  ) {
    final hasEntitlement =
        entitlementId.isNotEmpty &&
        customerInfo.entitlements.active.containsKey(entitlementId);
    final hasAllPurchased = customerInfo.allPurchasedProductIdentifiers
        .contains(productId);
    final hasActiveSub = customerInfo.activeSubscriptions.contains(productId);
    return hasEntitlement || hasAllPurchased || hasActiveSub;
  }

  /// 学習履歴オプションの購入状態
  static Future<bool> isLearningHistoryOptionPurchased() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      return _hasPurchasedProduct(
        info,
        _learningHistoryOptionProductId,
        _learningHistoryEntitlementId,
      );
    } catch (e) {
      debugPrint('RevenueCat: Error checking learning history purchase: $e');
      return false;
    }
  }

  /// 指定されたproduct idで購入状態を確認（汎用メソッド）
  static Future<bool> isProductPurchased(String productId) async {
    if (productId.isEmpty) return false;
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      // unitGacha 規約: productId == entitlementId
      // entitlement を一次ソースにしつつ、念のため productId ベースのフォールバックも見る。
      return _hasPurchasedProduct(info, productId, productId);
    } catch (e) {
      debugPrint('RevenueCat: Error checking product purchase: $e');
      return false;
    }
  }

  /// 汎用：offerings から productId に紐づく Package を探す
  static Package? _findPackageForProduct(
    Offerings offerings,
    String productId,
  ) {
    final current = offerings.current;
    if (current == null) return null;
    for (final pkg in current.availablePackages) {
      try {
        if (pkg.storeProduct.identifier == productId) return pkg;
      } catch (_) {
        // 何らかの理由で storeProduct が null などの場合は無視
      }
    }
    return null;
  }

  /// 購入結果クラス
  /// (下に定義してある PurchaseResult を使用)
  /// 学習履歴オプション購入
  static Future<PurchaseResult> purchaseLearningHistoryOption() async {
    return _purchaseByProductId(
      _learningHistoryOptionProductId,
      _learningHistoryEntitlementId,
    );
  }

  /// 任意の productId を購入（汎用）
  ///
  /// unitGacha 規約: productId == entitlementId
  ///
  /// - 購入成功判定は entitlement を一次ソースにし、productId ベースもフォールバックとして見る。
  static Future<PurchaseResult> purchaseProduct(String productId) async {
    if (productId.isEmpty) {
      return PurchaseResult(success: false, error: 'Invalid productId');
    }
    return _purchaseByProductId(productId, productId);
  }

  /// 共通購入フロー（offerings -> package -> getProducts -> purchase）
  static Future<PurchaseResult> _purchaseByProductId(
    String productId,
    String entitlementId,
  ) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        return PurchaseResult(
          success: false,
          error: 'RevenueCat initialization failed',
        );
      }
    }

    try {
      // 1) Try offerings -> package
      try {
        final offerings = await Purchases.getOfferings();
        if (offerings.current != null &&
            offerings.current!.availablePackages.isNotEmpty) {
          final pkg = _findPackageForProduct(offerings, productId);
          if (pkg != null) {
            // package purchase
            final customerInfo = await Purchases.purchasePackage(pkg);
            if (_hasPurchasedProduct(customerInfo, productId, entitlementId)) {
              return PurchaseResult(success: true);
            } else {
              return PurchaseResult(
                success: false,
                error: 'Purchase completed but entitlement not active',
              );
            }
          }
        }
      } catch (e) {
        // offerings 取得に失敗した場合は次の手段へ（ログは残す）
        debugPrint(
          'RevenueCat: getOfferings failed or no matching package: $e',
        );
      }

      // 2) Fallback: getProducts -> purchaseStoreProduct
      try {
        final products = await Purchases.getProducts([productId]);
        if (products.isEmpty) {
          // プロダクトが見つからない場合、現時点の所有情報を再確認して成功判定する
          try {
            final info = await Purchases.getCustomerInfo();
            if (_hasPurchasedProduct(info, productId, entitlementId)) {
              return PurchaseResult(success: true);
            }
          } catch (_) {}
          return PurchaseResult(
            success: false,
            error: 'Product not found: $productId',
          );
        }

        final storeProduct = products.first;
        final customerInfo = await Purchases.purchaseStoreProduct(storeProduct);
        if (_hasPurchasedProduct(customerInfo, productId, entitlementId)) {
          return PurchaseResult(success: true);
        } else {
          return PurchaseResult(
            success: false,
            error: 'Purchase completed but entitlement not active',
          );
        }
      } catch (e) {
        // PlatformException の場合はエラーコード別に扱う
        if (e is PlatformException) {
          final errorCode = PurchasesErrorHelper.getErrorCode(e);
          if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
            return PurchaseResult(
              success: false,
              error: 'Purchase cancelled',
              cancelled: true,
            );
          } else if (errorCode == PurchasesErrorCode.networkError) {
            return PurchaseResult(
              success: false,
              error: 'Network error. Please check your connection.',
            );
          } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
            return PurchaseResult(
              success: false,
              error: 'Purchase not allowed',
            );
          } else if (errorCode == PurchasesErrorCode.purchaseInvalidError) {
            return PurchaseResult(success: false, error: 'Invalid purchase');
          }
        }
        return PurchaseResult(success: false, error: e.toString());
      }
    } catch (e) {
      debugPrint('RevenueCat: Unexpected purchase error: $e');
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    try {
      final info = await Purchases.restorePurchases();
      // entitlement が無い一括課金もあるため、購入済みプロダクト/サブスクも見る
      return info.entitlements.active.isNotEmpty ||
          info.allPurchasedProductIdentifiers.isNotEmpty ||
          info.activeSubscriptions.isNotEmpty;
    } catch (e) {
      debugPrint('RevenueCat: Restore error: $e');
      return false;
    }
  }

  /// 学習履歴オプションの商品価格を取得
  static Future<String?> getLearningHistoryOptionPrice() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return null;
    }

    try {
      // offerings から探す
      try {
        final offerings = await Purchases.getOfferings();
        if (offerings.current != null &&
            offerings.current!.availablePackages.isNotEmpty) {
          final pkg = _findPackageForProduct(
            offerings,
            _learningHistoryOptionProductId,
          );
          if (pkg != null) {
            final price = pkg.storeProduct.priceString;
            debugPrint(
              'RevenueCat: Found learning history price from offerings: $price (productId: ${pkg.storeProduct.identifier})',
            );
            return price;
          }
          // 商品IDが見つからない場合は、最初のパッケージを返さない（nullを返す）
          debugPrint(
            'RevenueCat: Learning history product not found in offerings. Looking for: $_learningHistoryOptionProductId',
          );
          debugPrint(
            'RevenueCat: Available packages: ${offerings.current!.availablePackages.map((p) => p.storeProduct.identifier).toList()}',
          );
        }
      } catch (e) {
        debugPrint('RevenueCat: getOfferings for price failed: $e');
      }

      // offerings 取得できないなら直接 getProducts
      try {
        debugPrint(
          'RevenueCat: Trying getProducts for learning history: $_learningHistoryOptionProductId',
        );
        final products = await Purchases.getProducts([
          _learningHistoryOptionProductId,
        ]);
        if (products.isNotEmpty) {
          final price = products.first.priceString;
          debugPrint(
            'RevenueCat: Found learning history price from getProducts: $price (productId: ${products.first.identifier})',
          );
          return price;
        } else {
          debugPrint(
            'RevenueCat: No products found for learning history: $_learningHistoryOptionProductId',
          );
        }
      } catch (e) {
        debugPrint('RevenueCat: getProducts for price failed: $e');
      }

      debugPrint(
        'RevenueCat: Could not get learning history price, returning null',
      );
      return null;
    } catch (e) {
      debugPrint(
        'RevenueCat: Error getting learning history product price: $e',
      );
      return null;
    }
  }
}

/// 購入結果
class PurchaseResult {
  final bool success;
  final String? error;
  final bool cancelled;

  PurchaseResult({required this.success, this.error, this.cancelled = false});
}
