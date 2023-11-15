

#' Create an AWS Lambda function
#'
#' @param aws_profile
#' @param function_name
#' @param aws_region
#' @param aws_account_id
#' @param aws_service_role
#' @param memory_size
#' @param skip
#' @param package
#'
#' @return
#' @export
#'
#' @examples
create_lambda_fun <- function(aws_profile = "default", function_name, aws_region = 'eu-west-2', aws_account_id = Sys.getenv("AWS_ACCOUNT_ID"), aws_service_role = Sys.getenv("AWS_SERVICE_ROLE"), memory_size = 1500, skip = FALSE, package = 'awslambdafuns') {
  do_lambda_fun('scripts/create-lambda-function.sh', aws_profile, function_name, aws_region, aws_account_id, aws_service_role, memory_size, skip, package)
}



#' Update an AWS Lambda function
#'
#' @param aws_profile
#' @param function_name
#' @param aws_region
#' @param account_id
#' @param skip
#' @param package
#'
#' @return
#' @export
#'
#' @examples
update_lambda_fun <- function(aws_profile, function_name, aws_region = 'eu-west-2', account_id, skip = FALSE, package = 'awslambdafuns') {
  do_lambda_fun('scripts/update-lambda-function.sh', aws_profile, function_name, aws_region, account_id, skip, package = package)
}


#' A low-level function to do something in AWS Lambda
#'
#' @param script
#' @param aws_profile
#' @param function_name Should match a folder placed in inst/lambda_funs
#' @param aws_region
#' @param aws_account_id
#' @param aws_service_role
#' @param memory_size
#' @param skip
#' @param package
#'
#' @return
#' @export
#'
#' @examples
do_lambda_fun <- function(script,
                          aws_profile = "default",
                          function_name,
                          aws_region,
                          aws_account_id = Sys.getenv("AWS_ACCOUNT_ID"),
                          aws_service_role = Sys.getenv("AWS_SERVICE_ROLE"),
                          memory_size = 1500,
                          skip = FALSE,
                          package = 'awslambdafuns') {

  if(!skip) {

    askYesNo("Is Docker running?")

    askYesNo("Have you setup your AWS creds?")
  }

  fun_loc <- system.file(paste0('lambda_funs/', function_name), package = package)

  if(fun_loc == "") {
    # Workaround
    fun_loc <- system.file(paste0('inst/lambda_funs/', function_name), package = package)
  }

  if(!dir.exists(fun_loc)) {
    stop(glue::glue("You need a folder name called {function_name} in inst/lambda_funs"))
  }

  prev_dir <- getwd()

  setwd(fun_loc)

  script <- system.file(script, package = 'awslambdafuns')

  cmd <- paste0(c(script, aws_profile, function_name, aws_region, aws_account_id, aws_service_role, memory_size), collapse =  " ")

  logging::loginfo("Running command: %s", cmd)

  system(cmd)

  setwd(prev_dir)
}


update_network_permissions <- function(function_name,
                                       subnet_ids = c("subnet-01b92deebd28a3758", "subnet-011766942b356235e"),
                                       security_group_ids = "sg-0115d70004551b14b") {
  # This comes from update-network-permissions.sh, but shell scripts are not good at taking arrays as input.
  # So we do this slightly differently:

  subnet_ids <- paste0(subnet_ids, collapse = ",")
  security_group_ids <- paste0(security_group_ids, collapse = ",")

  logging::loginfo("Updating network subnet_ids for %s", function_name)
  logging::loginfo("Subnet IDs: %s", function_name)
  logging::loginfo("Security Group IDS: %s", security_group_ids)

  vpc_config <- paste0("SubnetIds=", subnet_ids ,",SecurityGroupIds=", security_group_ids)

  system2("aws",
          args = c("lambda",
                  "update-function-configuration",
                   paste0("--function-name ", function_name),
                  paste0("--vpc-config ", vpc_config)
          ))
}


#' Create an API integration
#'
#' @param aws_profile
#' @param api_name
#' @param resource_name
#' @param aws_region
#' @param request_parameter
#' @param lambda_arn
#' @param deployment_stage
#' @param package
#'
#' @return
#' @export
#'
#' @examples
create_api_integration <- function(aws_profile, api_name, resource_name, aws_region, request_parameter, lambda_arn, deployment_stage, package = 'awslambdafuns') {

  askYesNo(paste0("Profile is ", aws_profile, ". Are you sure?"))

  script <- system.file("scripts/create-api-integration.sh", package = package)

  system(paste0(c(script, aws_profile, api_name, resource_name, aws_region, request_parameter, lambda_arn, deployment_stage), collapse = " "))
}


test_lambda_fun <- function(function_name, test_data) {

  payload <- rjson::toJSON(test_data)

  system(glue::glue("aws lambda invoke --function-name {function_name} --invocation-type RequestResponse --payload '{payload}' /tmp/response.json --cli-binary-format raw-in-base64-out"))
}


