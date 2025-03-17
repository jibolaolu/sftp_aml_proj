import os
import pymongo

def lambda_handler(event, context):
    try:
        # Get the MongoDB URI from environment variables
        mongo_uri = os.getenv("MONGO_URI")

        if not mongo_uri:
            raise ValueError("MONGO_URI environment variable is not set")

        # Connect to the MongoDB instance
        client = pymongo.MongoClient(mongo_uri)

        # Access a database (renamed to 'mongodb')
        db = client["mongodb"]

        # Access a collection (replace 'mycollection' with your collection name)
        collection = db["mycollection"]

        # Perform a simple query or operation (e.g., find all documents)
        documents = list(collection.find())

        # Return the documents as the response
        return {
            "statusCode": 200,
            "body": {
                "message": "Successfully connected to MongoDB",
                "documents": documents
            }
        }

    except Exception as e:
        # Handle any errors that occur
        return {
            "statusCode": 500,
            "body": {
                "error": str(e)
            }
        }
