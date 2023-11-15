# This script should only be run once
# command line argument - ./create-lambda-function.sh FUNCTION_NAME $AWS_REGION
AWS_PROFILE="$1"
FUNCTION_NAME="$2"
AWS_REGION="$3"
ACCOUNT_ID="$4"
SERVICE_ROLE="$5"
MEMORY_SIZE="$6"

echo "Using AWS profile: $AWS_PROFILE"
# 0. Get some fresh authorisation credentials
aws --profile $AWS_PROFILE ecr get-login-password --region $AWS_REGION | docker login --username AWS \
--password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
# 1. Create repository
echo "Creating ECR repository $FUNCTION_NAME-lambda"
aws --profile $AWS_PROFILE ecr create-repository --repository-name $FUNCTION_NAME-lambda \
--image-scanning-configuration scanOnPush=true --region $AWS_REGION
# 2. Build the image
echo "Building container $FUNCTION_NAME-lambda"
docker build -t $FUNCTION_NAME-lambda .
# 3. Tag
echo "Tagging container $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest"
docker tag $FUNCTION_NAME-lambda:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest
# 4. Push
echo "Pushing $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest to ECR"
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest
# 5. Create the function using the image
echo "Creating lambda function $FUNCTION_NAME with $SERVICE_ROLE IAM role"
# Recommend survey role has permission to  list/read/write EC2, write Cloudwatch
# logs, read from ECR and read from the s3 bucket lucid-training-data
# May need to adjust timeout/ memory parameters as function require--timeout 50
aws --profile $AWS_PROFILE lambda create-function --function-name $FUNCTION_NAME --package-type Image \
--code ImageUri=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest \
--role arn:aws:iam::$ACCOUNT_ID:role/$SERVICE_ROLE -\
-memory-size $MEMORY_SIZE --region $AWS_REGION
