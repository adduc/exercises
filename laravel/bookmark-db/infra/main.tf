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
  hash_key       = "url"

  attribute {
    name = "url"
    type = "S"
  }
}