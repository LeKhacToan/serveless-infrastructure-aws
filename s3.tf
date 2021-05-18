# S3 Bucket
resource "aws_s3_bucket" "s3-bucket-terrarom" {
  bucket = "s3-bucket-terrarom"
  acl    = "public-read"

  tags = {
    Name = "S3 website hosting"
  }
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForGetBucketObjects",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::s3-bucket-terrarom/*"
    }
  ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# cloulfront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.s3-bucket-terrarom.bucket}.s3.amazonaws.com"
    origin_id   = "S3-s3-bucket-terrarom"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront for s3"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags {
    Environment = "production"
  }
}
