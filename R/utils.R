

#' Formulate an API response
#'
#' @param status
#' @param message
#'
#' @return
#' @export
#'
#' @examples
form_response <- function(status, message){

  response <- list(status = status, message = message)
  jsonlite::toJSON(response, auto_unbox = TRUE)
}
