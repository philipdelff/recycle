# Smart caching of function results with custom argument comparison

Executes a function and caches its results, or returns cached results if
arguments haven't changed. Supports custom comparison logic for
arguments, such as comparing functions by code only (ignoring
environments) or reading file contents instead of comparing file paths.

## Usage

``` r
recycle(
  fun,
  args,
  path.res,
  path.digest = NULL,
  args.unwrap = NULL,
  fun.read = NULL,
  save.res = TRUE,
  force = FALSE
)
```

## Arguments

- fun:

  Function to execute (or retrieve cached results for)

- args:

  Named list of arguments to pass to \`fun\`

- path.res:

  Path to file where results will be stored (RDS format)

- path.digest:

  Path to file where argument digests will be stored (RDS format). If
  NULL, defaults to \`path.res\` with "\_digests" appended before
  extension.

- args.unwrap:

  Named list specifying how to unwrap/transform arguments before
  computing digests. Values can be: - The string "function" to compare
  functions by code only (ignoring environments) - A function to apply
  to the argument value before digesting - NULL for arguments that
  should be compared as-is Examples: list(myfun = "function", myfile =
  readLines, x = NULL)

- fun.read:

  Function to read cached results. If NULL (default), uses
  \`readRDS(path.res)\`. Use this when \`fun\` saves results in a custom
  format (e.g., fst, parquet, csv). The function should take one
  argument: the file path.

- save.res:

  Logical. If TRUE (default), \`recycle()\` saves the result using
  \`saveRDS()\`. Set to FALSE if \`fun\` saves its own results to
  \`path.res\`.

- force:

  Logical. If TRUE, always re-run the function regardless of cached
  results. Default is FALSE.

## Value

The result of executing \`fun\` with \`args\`, either freshly computed
or from cache

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple example
my_fun <- function(x, y) { Sys.sleep(1); x + y }
result <- recycle(my_fun, list(x = 1, y = 2), path.res = "cache/result.rds")

# With file contents comparison
process_file <- function(file, param) {
  data <- read.csv(file)
  # ... expensive processing
}
result <- recycle(process_file, 
                  list(file = "data.csv", param = 10),
                  path.res = "cache/processed.rds",
                  args.unwrap = list(file = readLines))

# With function argument (compare by code only)
apply_transform <- function(data, transform_fun) {
  transform_fun(data)
}
result <- recycle(apply_transform,
                  list(data = mtcars, transform_fun = function(x) x * 2),
                  path.res = "cache/transformed.rds",
                  args.unwrap = list(transform_fun = "function"))

# With custom save/read (e.g., function saves its own fst file)
library(fst)
save_fst <- function(data, path) {
  write_fst(data, path)
  return(data)
}
result <- recycle(save_fst,
                  list(data = mtcars, path = "cache/data.fst"),
                  path.res = "cache/data.fst",
                  fun.read = read_fst,
                  save.res = FALSE)  # Function saves its own results
} # }
```
