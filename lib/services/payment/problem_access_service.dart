// import 'revenuecat_service.dart'; // 課金チェック復元時に戻す
import 'problem_access_map.dart';
import '../../problems/unit/unit_expr_problem.dart' show UnitExprProblem;

/// Access checks for UnitExprProblem cards (expr|meaning based).
///
/// - If a problem key is not present in [requiredProductIdByExprKey], it is FREE.
/// - If present, it is unlocked only when the user has purchased that productId.
class ProblemAccessService {
  ProblemAccessService._();

  static final Map<String, Future<bool>> _purchaseCacheByProductId = {};

  static void clearCache() {
    _purchaseCacheByProductId.clear();
  }

  static String? requiredProductIdFor(UnitExprProblem ep) {
    final key = exprKey(ep);
    return requiredProductIdByExprKey[key];
  }

  /// 無料解放中: 常にアンロック。課金を再有効にするにはコメント内の旧実装を復元し、この先頭の `return true` を削除する。
  static Future<bool> isExprProblemUnlocked(UnitExprProblem ep) async {
    return true;
    /*
    final pid = requiredProductIdFor(ep);
    if (pid == null || pid.isEmpty) return true;

    final cached = _purchaseCacheByProductId[pid];
    if (cached != null) return cached;

    final fut = RevenueCatService.isProductPurchased(pid);
    _purchaseCacheByProductId[pid] = fut;
    return fut;
    */
  }
}
