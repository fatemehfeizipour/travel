import json
import os
import uuid
from datetime import datetime, timezone

import boto3

# These clients are created once, when Lambda starts the function.
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")
ses = boto3.client("ses")

# Values that Terraform will pass in as environment variables.
TABLE_NAME = os.environ["TABLE_NAME"]
TOPIC_ARN = os.environ["TOPIC_ARN"]
SENDER_EMAIL = os.environ["SENDER_EMAIL"]
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "*")

table = dynamodb.Table(TABLE_NAME)

REQUIRED_FIELDS = ["name", "email", "phone", "message"]


def response(status_code, message):
    """Build the reply that API Gateway sends back to the browser."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        },
        "body": json.dumps({"message": message}),
    }


def lambda_handler(event, context):
    # 1. The form data arrives as a JSON string inside event["body"].
    try:
        data = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return response(400, "Invalid request.")

    if not isinstance(data, dict):
        return response(400, "Invalid request.")

    # 2. Honeypot: real visitors never see this field, so only bots fill it.
    #    Return a fake success, and write and send nothing.
    if data.get("website"):
        print("honeypot trigger")
        return response(200, "Thank you! We will get back to you soon.")

    # 3. Validate: every required field must be a non-empty string.
    for field in REQUIRED_FIELDS:
        value = data.get(field)
        if not isinstance(value, str) or not value.strip():
            return response(400, f"{field} is required.")

    email = data["email"].strip()
    if "@" not in email:
        return response(400, "Please enter a valid email address.")

    submission = {
        "submission_id": str(uuid.uuid4()),
        "name": data["name"].strip(),
        "email": email,
        "phone": data["phone"].strip(),
        "message": data["message"].strip(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    # 4. Write to DynamoDB first. If this fails, send nothing.
    try:
        table.put_item(Item=submission)
    except Exception as error:
        print(f"DynamoDB write failed: {error}")
        return response(500, "Something went wrong. Please try again later.")

    # 5. Notify the business through SNS. A failure here must not block step 6.
    try:
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="New contact form submission",
            Message=(
                f"Name: {submission['name']}\n"
                f"Email: {submission['email']}\n"
                f"Phone: {submission['phone']}\n"
                f"Message: {submission['message']}"
            ),
        )
    except Exception as error:
        print(f"SNS publish failed: {error}")

    # 6. Confirm to the customer through SES. A failure here must not block step 5.
    try:
        ses.send_email(
            Source=SENDER_EMAIL,
            Destination={"ToAddresses": [email]},
            Message={
                "Subject": {"Data": "We received your message"},
                "Body": {
                    "Text": {
                        "Data": (
                            f"Hi {submission['name']},\n\n"
                            "Thank you for contacting us. "
                            "We received your message and will get back to you soon."
                        )
                    }
                },
            },
        )
    except Exception as error:
        print(f"SES send failed: {error}")

    return response(200, "Thank you! We will get back to you soon.")