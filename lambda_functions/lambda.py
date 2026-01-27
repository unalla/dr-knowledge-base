import json
import boto3
import os
from pinecone import Pinecone
from openai import OpenAI

# Initialize clients outside the handler for better performance
s3 = boto3.client('s3')
pc = Pinecone(api_key=os.environ['PINECONE_API_KEY'])
index = pc.Index("dr-runbooks")
openai_client = OpenAI(api_key=os.environ['OPENAI_API_KEY'])

def lambda_handler(event, context):
    # 1. Get bucket and file info from the S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    
    # 2. Read the file content
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    
   # 3. Simple Chunking (e.g., chunks of 1000 chars)
    chunks = [content[i:i+1000] for i in range(0, len(content), 1000)]
    
    vectors_to_upsert = []
    
    for i, chunk in enumerate(chunks):
        # 4. Generate Embedding
        res = openai_client.embeddings.create(
            input=[chunk],
            model="text-embedding-3-small"
        )
        embedding = res.data[0].embedding
        
        # 5. Prepare Vector Object
        # We include the original text in metadata for retrieval later
        vectors_to_upsert.append({
            "id": f"{key}#chunk{i}", 
            "values": embedding,
            "metadata": {
                "source": key,
                "text": chunk
            }
        })
    
    # 6. Upsert to Pinecone
    index.upsert(vectors=vectors_to_upsert)
    
    return {
            'statusCode': 200,
            'body': json.dumps(f"Successfully upserted {len(vectors_to_upsert)} chunks from {key}")
        }