# arg1: profile to use
AWS_PROFILE="$1"
# arg2: Name to give to the API (doesn't appear in endpoint url)
API_NAME="$2"
# arg3: Name given to API resource (does appear in endpoint url)
RESOURCE_NAME="$3"
# arg4 AWS region in which to situate API
AWS_REGION="$4"
# arg5 name of parameter that must be sent in the request body
REQUEST_PARAMETER="$5"
# ARN of the lambda function to integrate API with
LAMBDA_ARN="$6"
# Stage to deploy API to
DEPLOYMENT_STAGE="$7"
# Example invocation ./create-api-integration.sh lucid-ranking recommend-survey eu-west-2 userid arn:aws:lambda:eu-west-2:892713415261:function:lucid-ranking test

# 1. Sucessful api creation returns a json with the name and id of the api
echo creating API $API_NAME in region $AWS_REGION
RESPONSE_1=$(aws --profile $AWS_PROFILE apigateway create-rest-api \
  --name $API_NAME --region $AWS_REGION)

# 2. extract the id argument from the json (requires the jq utility)
REST_API_ID=$(echo "$RESPONSE_1" | jq -r '.id')

# 3. Get the api resource information
echo API ID $REST_API_ID
RESPONSE_2=$(aws --profile $AWS_PROFILE apigateway get-resources --rest-api-id $REST_API_ID \
  --region $AWS_REGION)

# 4. Extract the root resource id
ROOT_RESOURCE_ID=$(echo "$RESPONSE_2" | jq -r '.items[0].id')
echo Root resource ID $ROOT_RESOURCE_ID

# 5. Create the resource
echo creating resource $RESOURCE_NAME
# RESPONSE_3=$(aws --profile $AWS_PROFILE apigateway create-resource --rest-api-id $REST_API_ID \
#   --region $AWS_REGION --parent-id $ROOT_RESOURCE_ID \
#   --path-part $RESOURCE_NAME)
RESPONSE_3=$(aws --profile $AWS_PROFILE apigateway create-resource  --rest-api-id $REST_API_ID \
  --region $AWS_REGION --parent-id $ROOT_RESOURCE_ID \
  --path-part {proxy+}
)

# 6. Extract the resource id
RESOURCE_ID=$(echo "$RESPONSE_3" | jq -r '.id')
echo Resource ID = $RESOURCE_ID

# 7. Create POST method, require that $REQUEST_PARAMETER in request body
# echo creating POST method for resource $RESOURCE_ID requiring $REQUEST_PARAMETER parameter
# aws --profile $AWS_PROFILE apigateway put-method --rest-api-id $REST_API_ID --region $AWS_REGION \
#   --resource-id $RESOURCE_ID --http-method POST \
#   --authorization-type "NONE" \
#   --request-parameters method.request.querystring.$REQUEST_PARAMETER=true

# 7. Create ANY method
echo creating ANY method for resource $RESOURCE_ID
aws --profile $AWS_PROFILE apigateway put-method --rest-api-id $REST_API_ID --region $AWS_REGION \
  --resource-id $RESOURCE_ID --http-method ANY \
  --authorization-type "NONE"

# 8. Set up 200 OK response to for POST method
# echo creating 200 OK method response
# aws --profile $AWS_PROFILE apigateway put-method-response --rest-api-id $REST_API_ID \
#     --region $AWS_REGION --resource-id $RESOURCE_ID --http-method POST \
#     --status-code 200

# 9. Set up integration with a lambda function with required input UserId
echo creating lamda integration with lambda function $LAMBDA_ARN
aws --profile $AWS_PROFILE apigateway put-integration --region $AWS_REGION \
  --rest-api-id $REST_API_ID --resource-id $RESOURCE_ID \
  --http-method ANY --type AWS_PROXY --integration-http-method POST \
  --uri arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations
#  --request-templates '{"application/json":"{\"UserId\":\"$input.params('userid')\"}"}'

# 10. Grant the API permission to invoke the lambda function
# echo editing $LAMBDA_ARN permissions so it can be invoked by api-gateway apis
# aws --profile $AWS_PROFILE lambda add-permission --statement-id $API_NAME-proxy \
# --principal apigateway.amazonaws.com \
# --function-name $LAMBDA_ARN \
# --action lambda:InvokeFunction


# 11. Set up integration response to pass lambda function output to
# client as 200 OK method response
# echo setting up api to return lambda response with 200 OK response
# aws --profile $AWS_PROFILE apigateway put-integration-response --region $AWS_REGION \
#   --rest-api-id $REST_API_ID --resource-id $RESOURCE_ID \
#   --http-method POST --status-code 200 --selection-pattern ""

# 12. Deploy API
echo deploying api to $DEPLOYMENT_STAGE stage
aws --profile $AWS_PROFILE apigateway create-deployment --rest-api-id $REST_API_ID \
  --stage-name $DEPLOYMENT_STAGE --region $AWS_REGION

# 13. print invocation url
echo invocation url = https://$REST_API_ID.execute-api.$AWS_REGION.amazonaws.com/$DEPLOYMENT_STAGE/$RESOURCE_NAME?$REQUEST_PARAMETER=
echo DONE
