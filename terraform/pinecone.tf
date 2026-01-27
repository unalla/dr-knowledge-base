# 1. Pinecone Index for RAG (Knowledge Base)
resource "pinecone_index" "dr_knowledge" {
  name      = "dr-runbooks"
  dimension = 1536 # OpenAI standard
  metric    = "cosine"
  spec = {
    serverless = { cloud = "aws", region = "us-east-1" }
  }
}