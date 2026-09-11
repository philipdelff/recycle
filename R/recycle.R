##' Smart caching of function results with custom argument comparison
##'
##' Executes a function and caches its results, or returns cached results if
##' arguments haven't changed. Supports custom comparison logic for arguments,
##' such as comparing functions by code only (ignoring environments) or reading
##' file contents instead of comparing file paths.
##'
##' @param fun Function to execute (or retrieve cached results for)
##' @param args Named list of arguments to pass to `fun`
##' @param path.res Path to file where results will be stored (RDS format)
##' @param path.digest Path to file where argument digests will be stored (RDS format).
##'   If NULL, defaults to `path.res` with "_digests" appended before extension.
##' @param funs.unwrap Named list of functions to apply to specific arguments before
##'   computing digests. For example, to compare file contents instead of paths, or
##'   to compare function code without environments. If NULL, arguments are compared as-is.
##' @param file.args Character vector of argument names that should be treated as file
##'   paths and have their contents read before comparison. Convenience alternative to
##'   specifying `funs.unwrap` for file arguments.
##' @param force Logical. If TRUE, always re-run the function regardless of cached results.
##'   Default is FALSE.
##' @return The result of executing `fun` with `args`, either freshly computed or from cache
##' @export
##' @examples
##' \dontrun{
##' # Simple example
##' my_fun <- function(x, y) { Sys.sleep(1); x + y }
##' result <- recycle(my_fun, list(x = 1, y = 2), path.res = "cache/result.rds")
##' 
##' # With file contents comparison
##' process_file <- function(file, param) {
##'   data <- read.csv(file)
##'   # ... expensive processing
##' }
##' result <- recycle(process_file, 
##'                   list(file = "data.csv", param = 10),
##'                   path.res = "cache/processed.rds",
##'                   file.args = "file")
##' 
##' # With function argument (compare by code only)
##' apply_transform <- function(data, transform_fun) {
##'   transform_fun(data)
##' }
##' result <- recycle(apply_transform,
##'                   list(data = mtcars, transform_fun = function(x) x * 2),
##'                   path.res = "cache/transformed.rds",
##'                   funs.unwrap = list(
##'                     transform_fun = function(f) list(body(f), formals(f))
##'                   ))
##' }
recycle <- function(fun, args, path.res, path.digest = NULL, 
                    funs.unwrap = NULL, file.args = NULL, force = FALSE) {
  
  # Validate inputs
  if (!is.function(fun)) {
    stop("'fun' must be a function")
  }
  if (!is.list(args)) {
    stop("'args' must be a named list")
  }
  if (is.null(names(args)) || any(names(args) == "")) {
    stop("'args' must be a named list with all elements named")
  }
  
  # Set default path.digest if not provided
  if (is.null(path.digest)) {
    path.digest <- sub("(\\.[^.]+)$", "_digests\\1", path.res)
    if (path.digest == path.res) {
      path.digest <- paste0(path.res, "_digests.rds")
    }
  }
  
  # Create directory if needed
  dir.res <- dirname(path.res)
  if (!dir.exists(dir.res)) {
    dir.create(dir.res, recursive = TRUE)
  }
  dir.digest <- dirname(path.digest)
  if (!dir.exists(dir.digest)) {
    dir.create(dir.digest, recursive = TRUE)
  }
  
  # Build funs.unwrap from file.args if provided
  if (!is.null(file.args)) {
    if (is.null(funs.unwrap)) {
      funs.unwrap <- list()
    }
    for (arg in file.args) {
      if (is.null(funs.unwrap[[arg]])) {
        funs.unwrap[[arg]] <- function(x) {
          if (is.character(x) && length(x) == 1 && file.exists(x)) {
            readLines(x, warn = FALSE)
          } else {
            x
          }
        }
      }
    }
  }
  
  # Check if we need to run
  need_run <- check_need_run(args, path.res, path.digest, funs.unwrap, force)
  
  if (need_run$run) {
    # Execute function
    result <- do.call(fun, args)
    
    # Save results and digests
    saveRDS(result, path.res)
    saveRDS(need_run$digest.new, path.digest)
    
    return(result)
  } else {
    # Return cached results
    return(readRDS(path.res))
  }
}
