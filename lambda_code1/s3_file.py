import json
import boto3
import os
import requests

def lambda_handler(event, context):
    try:
        # Log the received event for debugging
        print("Received event:")
        print(json.dumps(event, indent=2))

        # Retrieve the endpoint from environment variables
        api_endpoint = os.getenv("API_ENDPOINT")
        if not api_endpoint:
            raise ValueError("API_ENDPOINT environment variable is not set.")

        # Handle S3 notification structure
        if 'Records' in event:
            for record in event['Records']:
                bucket_name = record['s3']['bucket']['name']
                object_key = record['s3']['object']['key']

                # Extract the username from the object key
                username = object_key.split('/')[0]

                # Fetch additional metadata from S3 (if present in the object's metadata)
                s3_client = boto3.client("s3")
                s3_head_object = s3_client.head_object(Bucket=bucket_name, Key=object_key)
                additional_metadata = s3_head_object.get("Metadata", {})

                # Combine predefined metadata with dynamic metadata
                metadata = {
                    "fileName": object_key.split("/")[-1],
                    "amlSupervisoryBody": username,
                    "fromLocation": f"/{username}",
                    "toLocation": f"/{username}"  # Include the username as 'amlBody'
                }

                # Define the API payload
                payload = {
                    "file": {
                        "s3_url": f"s3://{bucket_name}/{object_key}",
                        "fileName": object_key.split("/")[-1],
                        "bucket": bucket_name,
                        "filePath": object_key
                    },
                    "metadata": metadata
                }

                # Log the payload for debugging
                print("Prepared Payload:")
                print(json.dumps(payload, indent=2))

                # Send the payload to the internal API
                response = requests.post(
                    api_endpoint,  # Use the variable endpoint
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )

                # Log the response
                print(f"API Response: {response.status_code} - {response.text}")

            return {
                "statusCode": 200,
                "body": json.dumps("Lambda executed successfully!")
            }
        else:
            raise ValueError("Unexpected event format. 'Records' key not found.")

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error processing the event: {str(e)}")
        }
