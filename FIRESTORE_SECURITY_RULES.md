# Firestore Security Rules Configuration

## 問題

ユーザーがFirestoreから設定を読み取る際に、`permission-denied`エラーが発生しています。

### エラーログの例
```
flutter: Local settings sync to Firestore completed
flutter: Error getting reserve problems settings from Firestore: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
flutter: Error getting user settings from Firestore: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
flutter: Error getting all other settings from Firestore: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
flutter: Error getting all gacha settings from Firestore: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

このエラーは、Firestoreのセキュリティルールが適切に設定されていない場合に発生します。

## 解決方法

### 方法1: Firebase CLIを使用してデプロイ（推奨）

プロジェクトルートに`firestore.rules`ファイルが作成されています。以下のコマンドでFirebase Consoleにデプロイできます：

```bash
# Firebase CLIがインストールされていることを確認
firebase --version

# Firebaseにログイン（初回のみ）
firebase login

# プロジェクトを選択
firebase use unitgacha

# Firestoreルールをデプロイ
firebase deploy --only firestore:rules
```

### 方法2: Firebase Consoleから手動で設定

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクト「unitgacha」を選択
3. 左メニューから「Firestore Database」を選択
4. 「Rules」タブを開く
5. `firestore.rules`ファイルの内容をコピー＆ペースト
6. 「公開」ボタンをクリック

## 必要なFirestore Security Rules

以下のセキュリティルールが`firestore.rules`ファイルに含まれています：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ユーザー認証チェック関数
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // ユーザーが自分のデータにアクセスしているかチェック
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ============================================================
    // ユーザー設定へのアクセス
    // ============================================================
    match /users/{userId} {
      // ユーザーは自分のドキュメントを読み書きできる
      allow read, write: if isOwner(userId);
      
      // ============================================================
      // 設定コレクション
      // ============================================================
      match /settings/{settingDoc} {
        // ユーザーは自分の設定ドキュメントを読み書きできる
        // settingDocには以下が含まれる:
        // - user_settings
        // - premium_purchased
        // - gacha_settings (サブコレクションの親)
        // - other_settings (サブコレクションの親)
        allow read, write: if isOwner(userId);
      }
      
      // ============================================================
      // ガチャ設定サブコレクション
      // ============================================================
      // パス: users/{userId}/settings/gacha_settings/gacha_types/{gachaType}
      match /settings/gacha_settings {
        allow read, write: if isOwner(userId);
        
        match /gacha_types/{gachaType} {
          allow read, write: if isOwner(userId);
        }
        match /gacha_types {
          allow list: if isOwner(userId);
        }
      }
      
      // ============================================================
      // その他の設定サブコレクション
      // ============================================================
      // パス: users/{userId}/settings/other_settings/keys/{key}
      match /settings/other_settings {
        allow read, write: if isOwner(userId);
        
        match /keys/{key} {
          allow read, write: if isOwner(userId);
        }
        match /keys {
          allow list: if isOwner(userId);
        }
      }
      
      // ============================================================
      // 学習記録コレクション
      // ============================================================
      // パス: users/{userId}/learning_records/{problemId}
      match /learning_records/{problemId} {
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

## トラブルシューティング

### 特定のユーザーがアクセスできない場合

1. **ユーザーIDを確認**: エラーログに表示されるユーザーIDを確認
2. **認証状態を確認**: ユーザーが正しく認証されているか確認
3. **ルールの構文を確認**: Firebase Consoleでルールの構文エラーがないか確認

### ログで確認できる情報

アプリのログに以下のような形式でエラーが表示されます：
```
Error getting reserve problems settings from Firestore for user: jtsa1JpsgCQJbGTkEDwlNo7McXC2 - [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

このログから、どのユーザーがどの操作でエラーが発生しているかを特定できます。

## 注意事項

- セキュリティルールは即座に反映されますが、最大1分程度かかる場合があります
- テストモードでは、開発中はすべての読み書きが許可されますが、本番環境では必ず適切なルールを設定してください
- 匿名認証ユーザーも `request.auth.uid` で識別できます





