locals {
  movie_data = jsondecode(file("${path.module}/movies.json"))
}

resource "aws_dynamodb_table" "movies_db" {
  name         = "Movies"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "movieId"
  range_key    = "releaseYear"

  attribute {
    name = "movieId"
    type = "S"
  }
  attribute {
    name = "releaseYear"
    type = "N"
  }

  tags = {
    "Name"        = "Movies REST API"
    "Environment" = "Dev"
  }
}

resource "aws_dynamodb_table_item" "movie_item" {
  table_name = aws_dynamodb_table.movies_db.name
  hash_key   = aws_dynamodb_table.movies_db.hash_key
  range_key  = aws_dynamodb_table.movies_db.range_key

  count = length(local.movie_data)

  item = <<ITEM
  {
  "movieId": {"S": "${local.movie_data[count.index].movieId}"},
  "title": {"S": "${local.movie_data[count.index].title}"},
  "releaseYear": {"N": "${local.movie_data[count.index].releaseYear}"},
  "genre": {"S": "${local.movie_data[count.index].genre}"},
  "coverUrl": {"S": "${local.movie_data[count.index].coverUrl}"},
  "generatedSummary": {"S": ""}
  }
  ITEM
}
