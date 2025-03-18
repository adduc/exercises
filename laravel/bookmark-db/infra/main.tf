resource "aws_dynamodb_table" "bookmarks" {
  name           = "Bookmarks"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "Url"

  attribute {
    name = "Url"
    type = "S"
  }
}