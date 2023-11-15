# This script is run when local changes have been made to function image
# and you want to deploy to the lambda function
# command line argument - ./update-lambda-function.sh function_name aws_region
AWS_PROFILE="$1"
FUNCTION_NAME="$2"
AWS_REGION="$3"
ACCOUNT_ID="$4"
# 1. Build the image
echo "Building container $FUNCTION_NAME-lambda"
docker build -t $FUNCTION_NAME-lambda .
# 2. Tag
echo "Tagging container $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest"
docker tag $FUNCTION_NAME-lambda:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest
# 3. Get some fresh authorisation credentials and push
aws --profile $AWS_PROFILE  ecr get-login-password --region $AWS_REGION | docker login --username AWS \
--password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
echo "Pushing $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest to ECR"
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest
# 4. Deploy the image to the lambda function
echo "Updating lambda function $FUNCTION_NAME"
aws --profile $AWS_PROFILE  lambda update-function-code --function-name $FUNCTION_NAME --image-uri $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$FUNCTION_NAME-lambda:latest --region $AWS_REGION

