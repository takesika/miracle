# 009 権限管理・プライバシー

## 概要
カメラ・フォトライブラリ権限の管理とプライバシー配慮実装

## 要件
- 権限ダイアログ前の事前説明画面
- 権限チェック・リクエスト機能
- Info.plist設定
- 権限拒否時の適切な案内

## Todo
- [ ] 権限事前説明画面作成
- [ ] permission_handler パッケージ統合
- [ ] カメラ権限チェック機能
- [ ] フォトライブラリ権限チェック機能
- [ ] 権限リクエスト処理
- [ ] 権限拒否時の案内画面
- [ ] Info.plist権限説明文設定
- [ ] 設定アプリへの誘導機能

## 完了条件
- 権限使用前に事前説明が表示される
- 各権限が適切にチェック・リクエストされる
- 権限拒否時に分かりやすい案内が表示される
- Info.plistの説明文が要件通り設定される
- 設定アプリへの誘導が機能する

## 技術詳細
- permission_handler パッケージ
- Permission.camera, Permission.photos
- Info.plist の NSCameraUsageDescription
- Info.plist の NSPhotoLibraryAddUsageDescription
- AppSettings.openAppSettings() での設定誘導

## プライバシー説明文
**カメラ**: 「撮影して加工するためにカメラを使用します。」
**フォトライブラリ**: 「加工した写真を保存するためにフォトライブラリを使用します。」