

#' Formulate an API response
#'
#' @param status
#' @param message
#' @param other
#'
#' @return
#' @export
#'
#' @examples
form_response <- function(status, message, other = list()){

  response <- c(list(status = status, message = message), other)

  return(response)
  #jsonlite::toJSON(response, auto_unbox = TRUE, pretty = TRUE)

}
