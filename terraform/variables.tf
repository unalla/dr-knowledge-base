variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "pinecone_api_key" {
  description = "API Key for Pinecone Vector Database"
  type        = string
  sensitive   = true # Prevents the key from being logged in plain text  
}

variable "openai_api_key" {
  description = "API Key for OpenAI embeddings"
  type      = string
  sensitive = true
}


