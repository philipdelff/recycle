##' Check if function needs to be re-run based on argument changes
##'
##' Compares current arguments against stored digests to determine if
##' a function needs to be re-executed.
##'
##' @param args Named list of arguments
##' @param path.res Path to results file
##' @param path.digest Path to digest file
##' @param funs.unwrap Named list of functions to apply before digesting
##' @param force Logical, if TRUE always return that run is needed
##' @return List with elements: run (logical), digest.new (data.table), digest.all (data.table or NULL)
##' @import data.table
##' @keywords internal
check_need_run <- function(args, path.res, path.digest, funs.unwrap, force) {
  
  # If force=TRUE, always run
  if (force) {
    digest.new <- digest_elements(args, funs.unwrap)
    return(list(run = TRUE, digest.new = digest.new, digest.all = NULL))
  }
  
  # If results file doesn't exist, must run
  if (!file.exists(path.res)) {
    digest.new <- digest_elements(args, funs.unwrap)
    return(list(run = TRUE, digest.new = digest.new, digest.all = NULL))
  }
  
  # If digest file doesn't exist, must run
  if (!file.exists(path.digest)) {
    digest.new <- digest_elements(args, funs.unwrap)
    return(list(run = TRUE, digest.new = digest.new, digest.all = NULL))
  }
  
  # Calculate new digests
  digest.new <- digest_elements(args, funs.unwrap)
  
  # Load old digests
  digest.old <- readRDS(path.digest)
  
  # Compare digests
  res.new <- NULL
  res.old <- NULL
  name <- NULL
  V1 <- NULL
  
  digest.all <- merge(digest.new, digest.old, by = "name", 
                      suffixes = c(".new", ".old"), all = TRUE)
  
  # Check if any digests differ
  if (any(is.na(digest.all$res.new)) || 
      any(is.na(digest.all$res.old)) ||
      !all(digest.all$res.new == digest.all$res.old)) {
    return(list(run = TRUE, digest.new = digest.new, digest.all = digest.all))
  }
  
  # No changes detected
  return(list(run = FALSE, digest.new = digest.new, digest.all = digest.all))
}
