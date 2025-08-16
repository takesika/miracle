# 奇跡の一枚

AIを使用して写真を自動補正し、1〜10段階の「かっこよさ」レベルで調整可能なiOSアプリ

## 機能

- カメラ撮影またはフォトライブラリから画像選択
- AI生成による画像補正（強度1-10段階）
- EXIF完全削除
- フォトライブラリへの保存

## 開発環境

- Flutter 3.19.6+
- iOS 16.0+
- Xcode 14.0+

## セットアップ

1. Flutter SDKをインストール
2. 依存関係をインストール: `flutter pub get`
3. iOSシミュレータで実行: `flutter run`

## ビルド

```bash
# 依存関係インストール
flutter pub get

# iOS実機向けビルド
flutter build ios --release

# アナライザー実行
flutter analyze

# フォーマット
dart format .
```

## プライバシー

- 個人情報収集なし
- 画像のサーバー保存なし
- EXIF完全削除
- 広告・課金なし