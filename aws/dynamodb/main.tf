module "global_config" {
  source = "../modules/global_config" # Relative path to your global module

  # You can pass values here if you want to override the default in the global module
  # aws_region = "ap-south-1"
}

provider "aws" {
  region = module.global_config.aws_region
}

# Defines a block for local values, which are named expressions that can be used throughout a Terraform configuration.
locals {
  # Decodes the content of the "movies.json" file into a Terraform-readable data structure (a list or map).
  # `file("${path.module}/movies.json")` reads the content of the `movies.json` file,
  # which is expected to be in the same directory as the current Terraform configuration file (`path.module`).
  # `jsondecode` then parses this content as JSON.
  movie_data = jsondecode(file("${path.module}/movies.json"))
}

# This resource creates a new NoSQL database table in AWS DynamoDB.
resource "aws_dynamodb_table" "movies_db" {
  name = "Movies" # Name of the DynamoDB table.

  # 'PAY_PER_REQUEST' (On-Demand) means you pay only for the reads and writes your application performs.
  billing_mode = "PAY_PER_REQUEST" # Sets the billing mode. 
  hash_key     = "movieId"         # Defines the primary key. 'movieId' is the partition key (hash key).
  # range_key    = "releaseYear" # Defines the sort key (range key). 'releaseYear' is the sort key. Currently not using.

  # Defines the attributes that compose the primary key.
  # These attributes must be defined with their names and data types.
  attribute {
    name = "movieId" # Name of the hash key attribute.
    type = "S"       # Data type: "S" for String.
  }
  # attribute { 
  #   name = "releaseYear" # Name of the range key attribute. Currently not using.
  #   type = "N"           # Data type: "N" for Number.
  # }

  # Tags for better resource management
  tags = {
    Name        = module.global_config.project_name
    Environment = module.global_config.environment
  }
}

# This resource is used to insert individual items (rows) into a DynamoDB table.
# The 'count' meta-argument is used here to create multiple items based on the data
# loaded from the 'movies.json' file.
resource "aws_dynamodb_table_item" "movie_item" {
  table_name = aws_dynamodb_table.movies_db.name     # Specifies the name of the DynamoDB table to insert items into.
  hash_key   = aws_dynamodb_table.movies_db.hash_key # Specifies the hash key of the target table.
  # range_key  = aws_dynamodb_table.movies_db.range_key # Specifies the range key of the target table. Currently not using.

  # The 'count' meta-argument creates multiple instances of this resource.
  # 'length(local.movie_data)' determines how many items to create, based on
  # the number of movie objects found in the 'movies.json' file.
  count = length(local.movie_data)

  # 'item' defines the JSON content of the item to be inserted.
  # The `<<ITEM ITEM` syntax is a "heredoc" string, allowing multi-line strings.
  # It dynamically inserts values from the 'local.movie_data' list using `count.index`
  # to iterate through each movie object.
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
