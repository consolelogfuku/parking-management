resource "aws_s3_bucket" "assets" {
  bucket = "parking-checker-assets-prod"

  tags = {
    Name = "parking-checker-assets"
  }
}

# パブリックアクセスをブロック
## ❌ ブラウザ → S3
## ⭕ ブラウザ → CloudFront → S3
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットポリシー（CloudFrontだけ許可）
resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# CORS設定
# このままだと静的ファイルの取得時に(xxx.comから、assets.xxx.com/assets/xxxx.jsにリクエスト)、レスポンスにAccess-Control-Allow-Origin ヘッダーがないため、ブラウザがレスポンスを読めない。⇒ S3からのレスポンスに、「Access-Control-Allow-Origin: ドメイン」がつくように設定する
# こうすることで、xxx.comはassets.xxx.com/assets/xxxx.jsへのリクエストのレスポンスを読むことができる
resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://parking-checker.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 86400
  }
}