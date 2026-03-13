# PARK-001 実装計画: 駐車場空き状況確認システム

## タスク概要

**Jiraチケット**: PARK-001
**スプリント**: Sprint 1
**期限**: -
**担当者**: -

## 要件

駐車場の空き状況を一般ユーザーがQRコードから確認できるシステムを構築する。
管理会社は専用画面から駐車場の登録・空き状況の更新を行い、開発者はActiveAdminで管理会社アカウントを発行する。

### 技術スタック
- Rails 8 + PostgreSQL + esbuild
- Docker環境（app / db / js の3コンテナ）
- Devise（認証）
- ActiveAdmin（開発者管理画面）
- enumerize（status管理）
- 主キー: UUIDv4（PostgreSQL `gen_random_uuid()` によるDB発番）

## 実装チェックリスト

### 1. 事前調査 📋

- [ ] Rails 8 + Devise の互換性確認
- [ ] Rails 8 + ActiveAdmin の互換性確認
- [ ] enumerize gem の最新バージョン確認
- [ ] PostgreSQL UUID 主キー設定方法の確認

### 2. ファイル調査 🔍

- [ ] Gemfile の現状確認
- [ ] config/application.rb の確認
- [ ] config/database.yml の確認
- [ ] config/routes.rb の確認

### 3. 実装 🚀

#### 3.1 Docker環境構築・DB接続確認
- [ ] Dockerfile の作成（Ruby + Node.js マルチステージビルド）
- [ ] compose.yml の作成（app / db / js）
- [ ] config/database.yml の設定
- [ ] `docker compose build` の実行・確認
- [ ] `docker compose run --rm app bin/rails db:create` の実行・確認
- [ ] `docker compose up` でRailsが起動することの確認

#### 3.2 UUID主キー設定
- [ ] config/application.rb に `primary_key_type: :uuid` を設定
- [ ] config/initializers/generators.rb の作成（uuid デフォルト設定）
- [ ] pgcrypto 拡張を有効化するマイグレーション作成・実行

#### 3.3 Devise導入・usersテーブル
- [ ] Gemfile に devise を追加・bundle install
- [ ] `rails generate devise:install` の実行
- [ ] Devise 初期設定（config/initializers/devise.rb）
- [ ] `rails generate devise User` の実行
- [ ] users マイグレーションを UUID 主キーに修正
- [ ] マイグレーション実行
- [ ] User モデルの確認

#### 3.4 ActiveAdmin導入・admin_usersテーブル
- [ ] Gemfile に activeadmin を追加・bundle install
- [ ] `rails generate active_admin:install` の実行
- [ ] admin_users マイグレーションを UUID 主キーに修正
- [ ] マイグレーション実行
- [ ] ActiveAdmin で users リソースを登録
- [ ] 管理会社ユーザーの作成・管理機能の確認

#### 3.5 parkingsテーブル・モデル
- [ ] Gemfile に enumerize を追加・bundle install
- [ ] parkings マイグレーション作成（UUID主キー、user_id外部キー、name、slug、status、phone_number）
- [ ] マイグレーション実行
- [ ] Parking モデル作成
  - [ ] `belongs_to :user` 関連付け
  - [ ] enumerize で status を定義（available / full）
  - [ ] slug のユニークバリデーション
  - [ ] name, phone_number のバリデーション
- [ ] User モデルに `has_many :parkings` を追加

#### 3.6 管理会社画面（認証・CRUD）
- [ ] Devise ビュー生成（管理会社ログイン画面）
- [ ] 管理会社用コントローラー作成
  - [ ] `Admin::ParkingsController`（index / new / create / edit / update）
- [ ] ルーティング設定（`/admin/parkings` 等）
- [ ] 管理会社ホーム画面（駐車場一覧）
- [ ] 駐車場作成画面・処理
- [ ] 駐車場情報更新画面・処理
- [ ] 認証フィルター（`authenticate_user!`）

#### 3.7 公開ページ
- [ ] `Public::ParkingsController` 作成（show アクション）
- [ ] ルーティング設定（`/p/:slug`）
- [ ] 公開ページビュー作成
  - [ ] 駐車場名の表示
  - [ ] 空き状況の表示（空きあり / 満車）
  - [ ] 電話番号の表示（tel リンク）
- [ ] スマートフォン向けレスポンシブ対応

#### 3.8 QRコード機能
- [ ] QRコード生成用 gem の選定・導入（rqrcode 等）
- [ ] QR表示画面の作成
  - [ ] 駐車場名の表示
  - [ ] 公開URLの表示
  - [ ] QRコード画像の表示
- [ ] QRコード画像ダウンロード機能（任意）

### 4. テスト 🧪

- [ ] ローカル環境での動作確認
  - [ ] Docker環境が正常に起動すること
  - [ ] DB接続・マイグレーションが成功すること
  - [ ] 開発者がActiveAdminにログインできること
  - [ ] 開発者が管理会社アカウントを作成できること
  - [ ] 管理会社がログインできること
  - [ ] 管理会社が駐車場を作成できること
  - [ ] 管理会社が空き状況を更新できること
  - [ ] 一般ユーザーが公開ページで空き状況を確認できること
  - [ ] QRコードが正しいURLを指すこと
- [ ] RSpec テスト
  - [ ] モデルテスト（User, Parking）
  - [ ] コントローラーテスト（管理会社画面、公開ページ）
- [ ] レスポンシブ表示の確認（スマートフォン）

### 5. 最終確認 ✅

- [ ] 全画面のデザイン・表示確認
- [ ] コードレビューの実施
- [ ] テスト完了の確認
- [ ] rubocop の実行・修正

## 参考リンク

- **Devise**: https://github.com/heartcombo/devise
- **ActiveAdmin**: https://github.com/activeadmin/activeadmin
- **enumerize**: https://github.com/brainspec/enumerize
- **rqrcode**: https://github.com/whomwah/rqrcode

## 進捗記録

- **開始日**: 2026-03-13
- **3.1 Docker環境構築**: ⏳ 進行中
- **3.2 UUID主キー設定**: ⏳ 未着手
- **3.3 Devise導入**: ⏳ 未着手
- **3.4 ActiveAdmin導入**: ⏳ 未着手
- **3.5 parkingsテーブル**: ⏳ 未着手
- **3.6 管理会社画面**: ⏳ 未着手
- **3.7 公開ページ**: ⏳ 未着手
- **3.8 QRコード機能**: ⏳ 未着手

## メモ

### 実装時の課題と対応

### 実装されたファイル

## 修正指示 📝
