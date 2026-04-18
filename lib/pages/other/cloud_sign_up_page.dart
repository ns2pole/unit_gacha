// // lib/pages/other/cloud_sign_up_page.dart
// import 'dart:io' show Platform;
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../services/auth/firebase_auth_service.dart';
// import '../../services/problems/simple_data_manager.dart';
// import '../../widgets/home/background_image_widget.dart';

// /// クラウド新規登録ページ
// /// 3つの認証方法から選択できる（iOSなら4つ）
// class CloudSignUpPage extends StatefulWidget {
//   const CloudSignUpPage({super.key});

//   @override
//   State<CloudSignUpPage> createState() => _CloudSignUpPageState();
// }

// class _CloudSignUpPageState extends State<CloudSignUpPage> {
//   // 電話番号認証用
//   final _phoneController = TextEditingController();
//   final _smsCodeController = TextEditingController();
//   final _phoneFormKey = GlobalKey<FormState>();
//   final _smsFormKey = GlobalKey<FormState>();
//   bool _isPhoneAuth = false;
//   bool _isSmsCodeSent = false;
//   String? _verificationId;
  
//   // メール/パスワード新規登録用
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _emailFormKey = GlobalKey<FormState>();
//   bool _isEmailAuth = false;
//   bool _obscurePassword = true;
  
//   bool _isLoading = false;
//   String? _errorMessage;

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _smsCodeController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _onAuthSuccess() async {
//     // バックグラウンドで同期処理を実行
//     _syncDataInBackground();
    
//     // 成功メッセージを表示してhomeに戻る
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('クラウドに保存しました'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
//       Navigator.of(context).pop(); // CloudBackupConfirmationPageに戻る
//       Navigator.of(context).pop(); // homeに戻る
//     }
//   }

//   Future<void> _syncDataInBackground() async {
//     try {
//       // UIが先に表示されるように、同期処理を遅延実行
//       // これにより、ログイン後の画面遷移がスムーズに行われる
//       await Future.delayed(const Duration(seconds: 2));
      
//       // 認証状態が確実に反映されるまで待機
//       // 最大1秒まで待機
//       int waitCount = 0;
//       const maxWaitCount = 10; // 100ms × 10 = 1秒
//       while (!FirebaseAuthService.isAuthenticated && waitCount < maxWaitCount) {
//         await Future.delayed(const Duration(milliseconds: 100));
//         waitCount++;
//       }
      
//       if (!FirebaseAuthService.isAuthenticated) {
//         print('Warning: Authentication state not ready after waiting, skipping sync');
//         return;
//       }
      
//       // UIスレッドに制御を戻す
//       await Future.delayed(Duration.zero);
      
//       // アカウント切り替えを検知
//       final isAccountSwitched = await SimpleDataManager.isAccountSwitched();
      
//       // UIスレッドに制御を戻す
//       await Future.delayed(const Duration(milliseconds: 50));
      
//       if (isAccountSwitched) {
//         // アカウント切り替え時：ローカルデータとFirestoreデータをタイムスタンプベースでマージ
//         // history配列はtimeフィールドで重複チェックしながら統合される
//         print('Account switch detected, merging local and Firestore data...');
//         await SimpleDataManager.syncOnAccountSwitch();
        
//         // UIスレッドに制御を戻す
//         await Future.delayed(const Duration(milliseconds: 50));
//       } else {
//         // 通常のクラウドに保存時：ローカルデータと設定をFirestoreに同期
//         // （既存のアカウントでクラウドに保存した場合）
//         await SimpleDataManager.syncLocalDataToFirestore();
        
//         // UIスレッドに制御を戻す
//         await Future.delayed(const Duration(milliseconds: 50));
        
//         await SimpleDataManager.syncLocalSettingsToFirestore();
        
//         // UIスレッドに制御を戻す
//         await Future.delayed(const Duration(milliseconds: 50));
        
//         // Firestoreから既存データを取得してマージ
//         await SimpleDataManager.initialize();
        
//         // UIスレッドに制御を戻す
//         await Future.delayed(const Duration(milliseconds: 50));
        
//         // 現在のユーザーIDを保存（次回のアカウント切り替え検知用）
//         final currentUserId = FirebaseAuthService.userId;
//         if (currentUserId != null) {
//           await SimpleDataManager.setLastUserId(currentUserId);
//         }
//       }
      
//       print('Background sync completed');
//     } catch (e) {
//       print('Error in background sync: $e');
//       // エラーが発生してもユーザーには影響しない（バックグラウンド処理のため）
//     }
//   }

//   Future<void> _signInWithGoogle() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final userCredential = await FirebaseAuthService.signInWithGoogle();
//       if (userCredential != null) {
//         await _onAuthSuccess();
//       } else {
//         setState(() {
//           _errorMessage = 'Google Sign-Inに失敗しました';
//         });
//       }
//     } catch (e) {
//       String errorMsg = 'Google Sign-Inに失敗しました';
//       if (e.toString().contains('credential-already-in-use')) {
//         errorMsg = 'このGoogleアカウントは既に使用されています。\n'
//                    '既存の認証方法を使用してください。';
//       } else if (e.toString().contains('account-exists-with-different-credential')) {
//         errorMsg = 'このGoogleアカウントは既に別の方法で登録されています。\n'
//                    '既存の認証方法を使用してください。';
//       } else if (e.toString().contains('network')) {
//         errorMsg = 'ネットワークエラーが発生しました。\n'
//                    'インターネット接続を確認してください。';
//       }
//       setState(() {
//         _errorMessage = errorMsg;
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _signInWithApple() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final userCredential = await FirebaseAuthService.signInWithApple();
//       if (userCredential != null) {
//         await _onAuthSuccess();
//       } else {
//         setState(() {
//           _errorMessage = 'Apple Sign-Inに失敗しました。\n'
//                          'Firebase ConsoleでApple Sign-Inが有効になっているか確認してください。';
//         });
//       }
//     } on FirebaseAuthException catch (e) {
//       // FirebaseAuthExceptionのエラーコードを適切に処理
//       String errorMsg = 'Apple Sign-Inに失敗しました';
      
//       switch (e.code) {
//         case 'invalid-credential':
//           errorMsg = '認証情報が無効です。\n'
//                      'もう一度お試しください。';
//           break;
//         case 'invalid-id-token':
//           errorMsg = '認証トークンが無効です。\n'
//                      'もう一度お試しください。';
//           break;
//         case 'credential-already-in-use':
//           errorMsg = 'このAppleアカウントは既に使用されています。\n'
//                      '既存の認証方法を使用してください。';
//           break;
//         case 'account-exists-with-different-credential':
//           errorMsg = 'このAppleアカウントは既に別の方法で登録されています。\n'
//                      '既存の認証方法を使用してください。';
//           break;
//         case 'operation-not-allowed':
//           errorMsg = 'Apple Sign-InがFirebase Consoleで有効になっていません。\n'
//                      'Firebase Console > Authentication > Sign-in method で\n'
//                      'Appleを有効にしてください。';
//           break;
//         default:
//           // エラーコードとメッセージを含めた詳細なメッセージ
//           errorMsg = 'Apple Sign-Inに失敗しました。\n'
//                      'エラーコード: ${e.code}\n'
//                      '${e.message ?? "詳細情報なし"}';
//           break;
//       }
      
//       setState(() {
//         _errorMessage = errorMsg;
//       });
//     } catch (e) {
//       String errorMsg = 'Apple Sign-Inに失敗しました';
//       if (e.toString().contains('CONFIGURATION_NOT_FOUND') || 
//           e.toString().contains('17999')) {
//         errorMsg = 'Apple Sign-InがFirebase Consoleで設定されていません。\n'
//                    'Firebase Console > Authentication > Sign-in method で\n'
//                    'Appleを有効にしてください。';
//       } else if (e.toString().contains('credential-already-in-use')) {
//         errorMsg = 'このAppleアカウントは既に使用されています。\n'
//                    '既存の認証方法を使用してください。';
//       } else if (e.toString().contains('account-exists-with-different-credential')) {
//         errorMsg = 'このAppleアカウントは既に別の方法で登録されています。\n'
//                    '既存の認証方法を使用してください。';
//       }
//       setState(() {
//         _errorMessage = errorMsg;
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _sendSmsCode() async {
//     if (!_phoneFormKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       String phoneNumber = _phoneController.text.trim();
//       // 電話番号が+で始まっていない場合は+を追加（日本の場合）
//       if (!phoneNumber.startsWith('+')) {
//         phoneNumber = phoneNumber.replaceAll(RegExp(r'[-\s]'), '');
//         if (phoneNumber.startsWith('0')) {
//           phoneNumber = '+81${phoneNumber.substring(1)}';
//         } else {
//           phoneNumber = '+81$phoneNumber';
//         }
//       }

//       await FirebaseAuthService.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         codeSent: (String verificationId) {
//           setState(() {
//             _verificationId = verificationId;
//             _isSmsCodeSent = true;
//             _isLoading = false;
//           });
//         },
//         verificationFailed: (String error) {
//           setState(() {
//             _errorMessage = error;
//             _isLoading = false;
//           });
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           setState(() {
//             _verificationId = verificationId;
//           });
//         },
//       );
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'SMSコードの送信に失敗しました: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _verifySmsCode() async {
//     if (!_smsFormKey.currentState!.validate()) {
//       return;
//     }

//     if (_verificationId == null) {
//       setState(() {
//         _errorMessage = '検証IDが取得できませんでした。もう一度お試しください。';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final userCredential = await FirebaseAuthService.signInWithPhoneNumber(
//         verificationId: _verificationId!,
//         smsCode: _smsCodeController.text.trim(),
//       );

//       if (userCredential != null) {
//         await _onAuthSuccess();
//       } else {
//         setState(() {
//           _errorMessage = 'SMSコードの認証に失敗しました';
//         });
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMsg = 'SMSコードの認証に失敗しました';
//       if (e.code == 'invalid-verification-code') {
//         errorMsg = 'SMSコードが正しくありません。\nもう一度確認してください。';
//       } else if (e.code == 'session-expired') {
//         errorMsg = 'セッションが期限切れです。\nもう一度SMSコードを送信してください。';
//       } else if (e.code == 'credential-already-in-use') {
//         errorMsg = 'この電話番号は既に使用されています。\n既存の認証方法を使用してください。';
//       }
//       setState(() {
//         _errorMessage = errorMsg;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'エラー: $e';
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _signUpWithEmailAndPassword() async {
//     if (!_emailFormKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final userCredential = await FirebaseAuthService.signUpWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );

//       if (userCredential != null) {
//         await _onAuthSuccess();
//       } else {
//         setState(() {
//           _errorMessage = '新規登録に失敗しました';
//         });
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMsg = 'エラー: ${e.message ?? e.code}';
//       switch (e.code) {
//         case 'email-already-in-use':
//           errorMsg = 'このメールアドレスは既に使用されています。\n'
//                      'クラウドに保存してください。';
//           break;
//         case 'weak-password':
//           errorMsg = 'パスワードが弱すぎます。\n'
//                      'より強力なパスワードを設定してください。';
//           break;
//         case 'invalid-email':
//           errorMsg = '無効なメールアドレスです。';
//           break;
//         case 'operation-not-allowed':
//           errorMsg = 'この認証方法は有効になっていません。';
//           break;
//         default:
//           errorMsg = '新規登録に失敗しました: ${e.message ?? e.code}';
//       }
//       setState(() {
//         _errorMessage = errorMsg;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'エラー: $e';
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => false, // 戻るボタンを無効化
//       child: Scaffold(
//         body: Stack(
//           children: [
//             // 背景画像（home_pageと同じスタイル）
//             Positioned.fill(
//               child: const BackgroundImageWidget(),
//             ),
//             // コンテンツ
//             SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 40),
//                     // タイトル
//                     const Text(
//                       'クラウドに保存する方法を選択',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 48),
                    
//                     // 電話番号認証のUI
//                     if (_isPhoneAuth) ...[
//                       Form(
//                         key: _phoneFormKey,
//                         child: Column(
//                           children: [
//                             if (!_isSmsCodeSent) ...[
//                               TextFormField(
//                                 controller: _phoneController,
//                                 decoration: const InputDecoration(
//                                   labelText: '電話番号',
//                                   hintText: '090-1234-5678',
//                                   border: OutlineInputBorder(),
//                                 ),
//                                 keyboardType: TextInputType.phone,
//                                 enabled: !_isLoading,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return '電話番号を入力してください';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 24),
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 56,
//                                 child: ElevatedButton(
//                                   onPressed: _isLoading ? null : _sendSmsCode,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.blue,
//                                     foregroundColor: Colors.white,
//                                   ),
//                                   child: _isLoading
//                                       ? const SizedBox(
//                                           width: 20,
//                                           height: 20,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2,
//                                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                           ),
//                                         )
//                                       : const Text(
//                                           'SMSコードを送信',
//                                           style: TextStyle(fontSize: 18),
//                                         ),
//                                 ),
//                               ),
//                             ] else ...[
//                               Form(
//                                 key: _smsFormKey,
//                                 child: Column(
//                                   children: [
//                                     TextFormField(
//                                       controller: _smsCodeController,
//                                       decoration: const InputDecoration(
//                                         labelText: 'SMSコード',
//                                         hintText: '6桁のコード',
//                                         border: OutlineInputBorder(),
//                                       ),
//                                       keyboardType: TextInputType.number,
//                                       enabled: !_isLoading,
//                                       validator: (value) {
//                                         if (value == null || value.isEmpty) {
//                                           return 'SMSコードを入力してください';
//                                         }
//                                         if (value.length != 6) {
//                                           return '6桁のコードを入力してください';
//                                         }
//                                         return null;
//                                       },
//                                     ),
//                                     const SizedBox(height: 24),
//                                     SizedBox(
//                                       width: double.infinity,
//                                       height: 56,
//                                       child: ElevatedButton(
//                                         onPressed: _isLoading ? null : _verifySmsCode,
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: Colors.blue,
//                                           foregroundColor: Colors.white,
//                                         ),
//                                         child: _isLoading
//                                             ? const SizedBox(
//                                                 width: 20,
//                                                 height: 20,
//                                                 child: CircularProgressIndicator(
//                                                   strokeWidth: 2,
//                                                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                                 ),
//                                               )
//                                             : const Text(
//                                                 '認証',
//                                                 style: TextStyle(fontSize: 18),
//                                               ),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 16),
//                                     TextButton(
//                                       onPressed: _isLoading
//                                           ? null
//                                           : () {
//                                               setState(() {
//                                                 _isSmsCodeSent = false;
//                                                 _smsCodeController.clear();
//                                                 _errorMessage = null;
//                                               });
//                                             },
//                                       child: const Text('電話番号を変更'),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                             const SizedBox(height: 16),
//                             TextButton(
//                               onPressed: _isLoading
//                                   ? null
//                                   : () {
//                                       setState(() {
//                                         _isPhoneAuth = false;
//                                         _isSmsCodeSent = false;
//                                         _phoneController.clear();
//                                         _smsCodeController.clear();
//                                         _errorMessage = null;
//                                       });
//                                     },
//                               child: const Text('戻る'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ]
//                     // メール/パスワード新規登録のUI
//                     else if (_isEmailAuth) ...[
//                       Form(
//                         key: _emailFormKey,
//                         child: Column(
//                           children: [
//                             TextFormField(
//                               controller: _emailController,
//                               decoration: const InputDecoration(
//                                 labelText: 'メールアドレス',
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.emailAddress,
//                               enabled: !_isLoading,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'メールアドレスを入力してください';
//                                 }
//                                 if (!value.contains('@')) {
//                                   return '有効なメールアドレスを入力してください';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 16),
//                             TextFormField(
//                               controller: _passwordController,
//                               decoration: InputDecoration(
//                                 labelText: 'パスワード',
//                                 border: const OutlineInputBorder(),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _obscurePassword ? Icons.visibility : Icons.visibility_off,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _obscurePassword = !_obscurePassword;
//                                     });
//                                   },
//                                 ),
//                               ),
//                               obscureText: _obscurePassword,
//                               enabled: !_isLoading,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'パスワードを入力してください';
//                                 }
//                                 if (value.length < 6) {
//                                   return 'パスワードは6文字以上で入力してください';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 24),
//                             SizedBox(
//                               width: double.infinity,
//                               height: 56,
//                               child: ElevatedButton(
//                                 onPressed: _isLoading ? null : _signUpWithEmailAndPassword,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   foregroundColor: Colors.white,
//                                 ),
//                                 child: _isLoading
//                                     ? const SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                         ),
//                                       )
//                                     : const Text(
//                                         '新規登録',
//                                         style: TextStyle(fontSize: 18),
//                                       ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             TextButton(
//                               onPressed: _isLoading
//                                   ? null
//                                   : () {
//                                       setState(() {
//                                         _isEmailAuth = false;
//                                         _emailController.clear();
//                                         _passwordController.clear();
//                                         _errorMessage = null;
//                                       });
//                                     },
//                               child: const Text('戻る'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ]
//                     // 認証方法選択画面
//                     else ...[
//                       // エラーメッセージ
//                       if (_errorMessage != null) ...[
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           margin: const EdgeInsets.only(bottom: 24),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             border: Border.all(color: Colors.red.shade300),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             _errorMessage!,
//                             style: TextStyle(color: Colors.red.shade900),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ],
                      
//                       // 1. 電話番号でクラウドに保存
//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed: _isLoading
//                               ? null
//                               : () {
//                                   setState(() {
//                                     _isPhoneAuth = true;
//                                     _errorMessage = null;
//                                   });
//                                 },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: const Text(
//                             '電話番号でクラウドに保存',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       // 2. メールアドレスでクラウドに保存
//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed: _isLoading
//                               ? null
//                               : () {
//                                   setState(() {
//                                     _isEmailAuth = true;
//                                     _errorMessage = null;
//                                   });
//                                 },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: const Text(
//                             'メールアドレスでクラウドに保存',
//                             style: TextStyle(fontSize: 18),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
                      
//                       // 3. Googleでクラウドに保存
//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : _signInWithGoogle,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             foregroundColor: Colors.black87,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(color: Colors.grey.shade300),
//                             ),
//                           ),
//                           child: _isLoading
//                               ? const SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
//                                   ),
//                                 )
//                               : Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(Icons.g_mobiledata, size: 24),
//                                     const SizedBox(width: 8),
//                                     const Text(
//                                       'Googleでクラウドに保存',
//                                       style: TextStyle(fontSize: 18),
//                                     ),
//                                   ],
//                                 ),
//                         ),
//                       ),
                      
//                       // 4. iOSのみAppleアカウントでクラウドに保存
//                       if (Platform.isIOS) ...[
//                         const SizedBox(height: 16),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 56,
//                           child: ElevatedButton(
//                             onPressed: _isLoading ? null : _signInWithApple,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.black,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: _isLoading
//                                 ? const SizedBox(
//                                     width: 20,
//                                     height: 20,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                     ),
//                                   )
//                                 : Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       const Icon(Icons.apple, size: 24),
//                                       const SizedBox(width: 8),
//                                       const Text(
//                                         'Appleアカウントでクラウドに保存',
//                                         style: TextStyle(fontSize: 18),
//                                       ),
//                                     ],
//                                   ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






