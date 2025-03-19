provider "aws" {
  default_tags {
    tags = {
      App = "laravel-bookmark-db"
    }
  }
}

resource "aws_dynamodb_table" "bookmarks" {
  name           = "bookmarks"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "user_email"
  range_key      = "url"

  attribute {
    name = "user_email"
    type = "S"
  }

  attribute {
    name = "url"
    type = "S"
  }
}

resource "aws_dynamodb_table" "cache" {
  name           = "cache"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "key"

  attribute {
    name = "key"
    type = "S"
  }
}

resource "aws_dynamodb_table" "users" {
  name           = "users"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "email"

  attribute {
    name = "email"
    type = "S"
  }
}