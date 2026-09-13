# Introduction to recycle

``` r

library(recycle)
```

## Introduction

The `recycle` package provides intelligent caching of function results
by comparing function arguments. Unlike simple memoization, `recycle`
offers flexible per-argument comparison logic that handles complex
scenarios.

## Basic Usage

The simplest use case is caching an expensive computation:

``` r

# Define an expensive function
expensive_computation <- function(x, y) {
  Sys.sleep(2)  # Simulate expensive operation
  x^2 + y^2
}

# First call - executes the function (takes 2 seconds)
result1 <- recycle(
  expensive_computation,
  args = list(x = 3, y = 4),
  path.res = "cache/result.rds"
)
print(result1)  # 25

# Second call with same arguments - uses cache (instant!)
result2 <- recycle(
  expensive_computation,
  args = list(x = 3, y = 4),
  path.res = "cache/result.rds"
)
print(result2)  # 25

# Different arguments - re-runs the function
result3 <- recycle(
  expensive_computation,
  args = list(x = 5, y = 12),
  path.res = "cache/result.rds"
)
print(result3)  # 169
```

## Working with Function Arguments

One of `recycle`’s key features is intelligent handling of function
arguments. When you pass a function as an argument, `recycle`
automatically compares it by code (body and formals) rather than by
environment.

### Automatic Function Detection

``` r

# Function that takes another function as argument
apply_operation <- function(data, operation) {
  operation(data)
}

# First call
transform1 <- function(x) x * 2
result1 <- recycle(
  apply_operation,
  args = list(data = 1:10, operation = transform1),
  path.res = "cache/transformed.rds"
)

# Second call with identical function code - uses cache!
transform2 <- function(x) x * 2  # Same code, different object
result2 <- recycle(
  apply_operation,
  args = list(data = 1:10, operation = transform2),
  path.res = "cache/transformed.rds"
)

# Different function code - re-runs
transform3 <- function(x) x * 3
result3 <- recycle(
  apply_operation,
  args = list(data = 1:10, operation = transform3),
  path.res = "cache/transformed.rds"
)
```

### Explicit Function Unwrapping

You can also explicitly specify function unwrapping using the
`"function"` keyword:

``` r

result <- recycle(
  apply_operation,
  args = list(data = 1:10, operation = my_fun),
  path.res = "cache/result.rds",
  args.unwrap = list(operation = "function")
)
```

## Working with Files

A common use case is processing data files. You want to re-run your
analysis when the file contents change, not just when the file path
changes.

``` r

# Create a sample data file
write.csv(mtcars[1:10, ], "data.csv", row.names = FALSE)

# Function that processes a file
process_file <- function(file_path, multiplier) {
  data <- read.csv(file_path)
  data$mpg <- data$mpg * multiplier
  return(data)
}

# First run - processes the file
result1 <- recycle(
  process_file,
  args = list(file_path = "data.csv", multiplier = 2),
  path.res = "cache/processed.rds",
  args.unwrap = list(
    file_path = function(x) readLines(x, warn = FALSE)
  )
)

# Same file, same arguments - uses cache
result2 <- recycle(
  process_file,
  args = list(file_path = "data.csv", multiplier = 2),
  path.res = "cache/processed.rds",
  args.unwrap = list(
    file_path = function(x) readLines(x, warn = FALSE)
  )
)

# Modify the file
write.csv(mtcars[1:20, ], "data.csv", row.names = FALSE)

# Now it re-runs because file contents changed
result3 <- recycle(
  process_file,
  args = list(file_path = "data.csv", multiplier = 2),
  path.res = "cache/processed.rds",
  args.unwrap = list(
    file_path = function(x) readLines(x, warn = FALSE)
  )
)
```

## Custom Save and Read Functions

Sometimes your function saves results in a custom format (e.g., fst,
parquet, feather). `recycle` supports this through `fun.read` and
`save.res` parameters.

``` r

# Example with CSV format
save_as_csv <- function(data, output_path) {
  write.csv(data, output_path, row.names = FALSE)
  return(data)
}

result <- recycle(
  save_as_csv,
  args = list(data = mtcars, output_path = "cache/data.csv"),
  path.res = "cache/data.csv",
  fun.read = function(path) read.csv(path),  # Custom read function
  save.res = FALSE  # Function saves its own results
)

# On subsequent calls, uses the custom read function
result2 <- recycle(
  save_as_csv,
  args = list(data = mtcars, output_path = "cache/data.csv"),
  path.res = "cache/data.csv",
  fun.read = function(path) read.csv(path),
  save.res = FALSE
)
```

### Example with fst Package

``` r

library(fst)

save_as_fst <- function(data, output_path) {
  write_fst(data, output_path)
  return(data)
}

result <- recycle(
  save_as_fst,
  args = list(data = large_dataset, output_path = "cache/data.fst"),
  path.res = "cache/data.fst",
  fun.read = read_fst,
  save.res = FALSE
)
```

## Complex Example: Multiple Unwrap Specifications

Here’s a realistic example combining multiple features:

``` r

# Complex analysis function
analyze_data <- function(input_file, transform_fun, config_file, threshold) {
  # Read data
  data <- read.csv(input_file)
  
  # Apply transformation
  data$value <- transform_fun(data$value)
  
  # Read configuration
  config <- jsonlite::read_json(config_file)
  
  # Filter based on threshold
  data <- data[data$value > threshold, ]
  
  return(data)
}

# Define transformation function
my_transform <- function(x) log(x + 1)

# Run with recycle
result <- recycle(
  analyze_data,
  args = list(
    input_file = "data.csv",
    transform_fun = my_transform,
    config_file = "config.json",
    threshold = 5
  ),
  path.res = "cache/analysis.rds",
  args.unwrap = list(
    # transform_fun automatically detected as function
    input_file = function(x) readLines(x, warn = FALSE),
    config_file = function(x) jsonlite::read_json(x)
    # threshold compared as-is (numeric value)
  )
)
```

In this example: - `transform_fun` is automatically compared by code
(auto-detected) - `input_file` is compared by contents (custom unwrap
function) - `config_file` is compared by parsed JSON contents (custom
unwrap function) - `threshold` is compared as-is (numeric value)

## Force Re-run

Sometimes you want to force a re-run regardless of whether arguments
changed:

``` r

result <- recycle(
  my_function,
  args = list(x = 1, y = 2),
  path.res = "cache/result.rds",
  force = TRUE  # Always re-run
)
```

## Custom Digest Storage

By default, digests are stored alongside results with `_digests`
appended to the filename. You can customize this:

``` r

result <- recycle(
  my_function,
  args = list(x = 1, y = 2),
  path.res = "cache/result.rds",
  path.digest = "cache/my_custom_digests.rds"
)
```

## Best Practices

1.  **Use descriptive cache paths**: Organize your cache files in a
    dedicated directory

    ``` r

    path.res = "cache/analysis/step1_results.rds"
    ```

2.  **Be explicit with file unwrapping**: Always specify how to read
    file contents

    ``` r

    args.unwrap = list(data_file = readLines)
    ```

3.  **Consider cache invalidation**: Use `force = TRUE` when you need to
    ensure fresh results

4.  **Clean up old caches**: Periodically remove outdated cache files

    ``` r

    unlink("cache", recursive = TRUE)
    ```

5.  **Use version control wisely**: Add cache directories to
    `.gitignore`

## Real-world Example: NONMEM Simulations with NMsim

Here’s a practical example using `recycle` with `NMsim` for NONMEM
simulations. This is particularly useful during model development when
you’re iterating on simulations that can take minutes to run.

``` r

library(NMsim)
library(recycle)

# Setup paths and configuration
file.mod <- "~/wdirs/NMsim/inst/examples/nonmem/xgxr021.mod"
dir.res <- "~/wdirs/NMsim/devel/needRun/res"

# Create a multiple-dose simulation dataset with a loading dose
data.sim <- NMcreateDoses(TIME = c(0, 24), AMT = c(300, 150), 
                          ADDL = 5, II = 24, CMT = 1) |>
  NMaddSamples(TIME = 0:(24*7), CMT = 2)

# Define the results file path
file.res <- file.path(dir.res, "xgxr021_noname_MetaData.rds")

# First run - executes simulation (may take several minutes)
res <- recycle(NMsim,
               args = list(file.mod = file.mod,
                          data = data.sim,
                          table.vars = c("PRED", "IPRED", "Y")),
               path.res = file.res,
               fun.read = NMreadSim,
               save.res = FALSE)

# Subsequent runs with same arguments - instant!
res <- recycle(NMsim,
               args = list(file.mod = file.mod,
                          data = data.sim,
                          table.vars = c("PRED", "IPRED", "Y")),
               path.res = file.res,
               fun.read = NMreadSim,
               save.res = FALSE)
# Using cached results from: ~/wdirs/NMsim/devel/needRun/res/xgxr021_noname_MetaData.rds

# Track changes to the model file
# If you edit the .mod file, recycle will detect it and re-run
res <- recycle(NMsim,
               args = list(file.mod = file.mod,
                          data = data.sim,
                          table.vars = c("PRED", "IPRED", "Y")),
               path.res = file.res,
               fun.read = NMreadSim,
               args.unwrap = list(file.mod = function(x) readLines(x, warn = FALSE)),
               save.res = FALSE)
# If model file changed:
# Running function due to changes:
#   - 'file.mod': value changed
```

### Why This Works Well

1.  **NMsim saves its own results**: We use `save.res = FALSE` because
    `NMsim` creates its own output files
2.  **Custom read function**: `fun.read = NMreadSim` reads the
    NMsim-specific format
3.  **Model file tracking**: Using `args.unwrap` with `readLines`
    ensures changes to the model file trigger re-runs
4.  **Data comparison**: The `data.sim` data.frame is compared directly,
    so changes trigger re-runs
5.  **Fast iteration**: During model development, you can re-run your
    analysis script instantly if nothing changed

This pattern works for any simulation or modeling tool that: - Takes
time to run - Saves its own output files - Has arguments you want to
track (model files, data, parameters)

## Conclusion

The `recycle` package provides a flexible and powerful caching solution
that goes beyond simple memoization. Its key strengths are:

- Automatic detection of function arguments
- Per-argument transformation logic
- Support for custom save/read formats
- Simple interface that works both interactively and within packages

For more information, see
[`?recycle`](https://philipdelff.github.io/recycle/reference/recycle.md)
or visit the package repository.
