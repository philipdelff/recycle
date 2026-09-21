##' Derive digests of argument values or their contents
##' 
##' Get digests of argument values. Optionally, functions can be run
##' on some arguments before calculating digests. An example would be
##' reading contents of a file where the file path is an argument.
##' 
##' @param list Named list of elements to digest
##' @param funs.unwrap Named list of functions to be applied to elements (matched on names) in `args`. Optional.
##' @return A data.table with columns 'name' and 'res' (digest values)
##' @importFrom digest digest
##' @import data.table
##' @keywords internal
digest_list <- function(list, funs.unwrap = NULL) {
  
  # Apply unwrap functions if provided
  if (!is.null(funs.unwrap)) {
    nms.funs <- names(funs.unwrap)
    for (na in nms.funs) {
      if (na %in% names(list)) {
        if (is.null(list[[na]])) {
          list[[na]] <- NULL
        } else {
          list[[na]] <- funs.unwrap[[na]](list[[na]] )
        }
      }
    }
  }
  
  # Calculate digests for each argument
  result <- data.table(
    name = names(list),
    res = vapply(list, digest, character(1))
  )
  
  return(result)
}
