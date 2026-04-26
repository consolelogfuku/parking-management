# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

  terraform applyで復活するもの

  - VPC、サブネット、ALB、ECS、RDS（空のDB）、ECR、IAMロール等

  復活しないもの

  - RDSのデータ — skip_final_snapshot = true なのでDBの中身は消える
  - ECRのDockerイメージ — リポジトリは作られるが中身は空
  - SSM Parameter Store — Terraformで管理していないので残る
  - ACM証明書のDNS検証 — 再度時間がかかる（5〜30分）

  Terraformで管理していない手動で作ったもの

  - SSM Parameter Store の値
  - 今回追加した GitHub Secrets

  復活後にやり直すこと：
  1. ECRにDockerイメージを再プッシュ（GitHub Actionsで）
  2. データを再投入したい場合はバックアップから復元
  3. Route53のネームサーバーが変わる場合はドメイン側でも変更必要
