# 001 プロジェクトセットアップ

## 概要
Flutter iOSプロジェクトの初期構築と開発環境整備

## 要件
- Flutter SDKセットアップ（iOS 16+対応）
- Xcode設定とiOS開発環境準備  
- プロジェクト基本構造作成
- 必要な依存関係の調査・追加

## Todo
- [ ] Flutter SDKインストール確認
- [ ] iOS 16+ deployment target設定
- [ ] pubspec.yaml基本構成
- [ ] プロジェクトディレクトリ構造作成
- [ ] カメラ・フォトライブラリ関連パッケージ調査
- [ ] HTTP通信用パッケージ調査  
- [ ] 画像処理・EXIF削除パッケージ調査
- [ ] iOS権限設定準備（Info.plist）
- [ ] 基本ビルド確認

## 完了条件
- iOSシミュレータでアプリが起動する
- 必要な権限設定がInfo.plistに記述済み
- 基本的な依存関係がpubspec.yamlに定義済み

## 技術要件
- Flutter SDK with iOS tools
- iOS 16+ minimum deployment target
- Camera and Photo Library permissions
- Network security configuration for HTTPS API calls