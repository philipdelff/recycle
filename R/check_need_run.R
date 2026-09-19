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
##' @param quiet Logical, if FALSE prints messages about what changed
##' @return List with elements: run (logical), digest.new (data.table), digest.all (data.table or NULL)
##' @import data.table
##' @importFrom tools md5sum
##' @keywords internal
check_need_run <- function(args, path.res, path.digest, funs.unwrap, force = FALSE, quiet = FALSE) {
  
  # If force=TRUE, always run
  if (force) {
    if (!quiet) {
      message("Running function (force = TRUE)")
    }
    digest.new <- digest_elements(args, funs.unwrap)
    return(list(run = TRUE, digest.new = digest.new, digest.all = NULL))
  }
  
  # If results file doesn't exist, must run
  if (!file.exists(path.res)) {
    if (!quiet) {
      message(sprintf("Running function: results file does not exist (%s)", path.res))
    }
    digest.new <- digest_elements(args, funs.unwrap)
    return(list(run = TRUE, digest.new = digest.new, digest.all = NULL))
  }
  
  # If digest file doesn't exist, must run
  if (!file.exists(path.digest)) {
    if (!quiet) {
      message(sprintf("Running function: digest file does not exist (%s)", path.digest))
    }
    digest.new <- digest_elements(args, funs.unwrap)
    return(list(run = TRUE, digest.new = digest.new, digest.all = NULL))
  }
  
  # Calculate new digests
  digest.new <- digest_elements(args, funs.unwrap)
  
  # Add MD5 of results file to digests (for comparison with old)
  res_file_md5 <- tools::md5sum(path.res)
  digest.new <- rbind(
    digest.new,
    data.table(name = ".results_file_md5", res = as.character(res_file_md5))
  )
  
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
    
    if (!quiet) {
      # Identify what changed
      changed <- digest.all[is.na(res.new) | is.na(res.old) | res.new != res.old]
      
      if (nrow(changed) > 0) {
        change_msgs <- character(nrow(changed))
        for (i in seq_len(nrow(changed))) {
          arg_name <- changed$name[i]
          if (is.na(changed$res.old[i])) {
            change_msgs[i] <- sprintf("  - '%s': new argument", arg_name)
          } else if (is.na(changed$res.new[i])) {
            change_msgs[i] <- sprintf("  - '%s': argument removed", arg_name)
          } else if (arg_name == ".results_file_md5") {
            change_msgs[i] <- "  - Results file was modified externally"
          } else {
            change_msgs[i] <- sprintf("  - '%s': value changed", arg_name)
          }
        }
        message("Running function due to changes:")
        message(paste(change_msgs, collapse = "\n"))
      }
    }
    
    return(list(run = TRUE, digest.new = digest.new, digest.all = digest.all))
  }
  
  # No changes detected
  return(list(run = FALSE, digest.new = digest.new, digest.all = digest.all))
}
