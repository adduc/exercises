resource "aws_dynamodb_table" "example" {
  billing_mode   = "PROVISIONED"
  hash_key       = "EntityId"
  name           = "example-table"
  range_key      = "Timestamp"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "EntityId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }
}