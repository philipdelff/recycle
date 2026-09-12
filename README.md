# recycle

Smart caching of function results with custom argument comparison.

## Overview

`recycle` provides intelligent caching of expensive function computations by comparing function arguments to determine if a re-run is necessary. Unlike simple memoization packages, `recycle` offers flexible, per-argument comparison logic that handles complex scenarios like:

- Comparing functions by their **code only** (ignoring environments)
- Reading **file contents** instead of comparing file paths
- Custom transformations of arguments before comparison
- Functions that save their own results in custom formats

## Installation

```r
# Install from GitHub
# devtools::install_github("philipdelff/recycle")

# For now, install locally
devtools::install()
```

## Documentation

Full documentation and vignettes are available at: **https://philipdelff.github.io/recycle/**

## Quick Start

```r
library(recycle)

# Simple caching
expensive_computation <- function(x, y) {
  Sys.sleep(2)  # Simulate expensive operation
  x + y
}

# First run - executes the function
result <- recycle(
  expensive_computation,
  args = list(x = 5, y = 10),
  path.res = "cache/result.rds"
)

# Second run with same arguments - uses cached result (instant!)
result <- recycle(
  expensive_computation,
  args = list(x = 5, y = 10),
  path.res = "cache/result.rds"
)
```

## Key Features

### 1. Automatic Function Comparison by Code

When you pass functions as arguments, `recycle` automatically compares them by their code (body and formals) rather than their environment. This means two functions with identical code but different environments are treated as equivalent.

```r
apply_transform <- function(data, transform_fun) {
  transform_fun(data)
}

# These two calls use the same cached result because the functions are identical
transform1 <- function(x) x * 2
result1 <- recycle(apply_transform, 
                   list(data = mtcars, transform_fun = transform1),
                   path.res = "cache/transformed.rds")

transform2 <- function(x) x * 2  # Same code, different object
result2 <- recycle(apply_transform,
                   list(data = mtcars, transform_fun = transform2),
                   path.res = "cache/transformed.rds")  # Uses cache!
```

### 2. File Contents Comparison

Compare file contents instead of file paths, so changes to files trigger re-computation:

```r
process_data <- function(input_file, param) {
  data <- read.csv(input_file)
  # ... expensive processing
  return(processed_data)
}

result <- recycle(
  process_data,
  args = list(input_file = "data.csv", param = 10),
  path.res = "cache/processed.rds",
  args.unwrap = list(input_file = function(x) readLines(x, warn = FALSE))
)

# If data.csv changes, the function will re-run automatically
```

### 3. Custom Argument Transformations

Apply custom functions to transform arguments before comparison:

```r
result <- recycle(
  my_function,
  args = list(
    data = my_data,
    transform = my_transform_fun,
    config_file = "config.json"
  ),
  path.res = "cache/result.rds",
  args.unwrap = list(
    transform = "function",  # Compare by code only
    config_file = function(x) jsonlite::read_json(x)  # Compare file contents
  )
)
```

### 4. Custom Save/Read Functions

Support for functions that save results in custom formats:

```r
library(fst)

save_as_fst <- function(data, path) {
  write_fst(data, path)
  return(data)
}

result <- recycle(
  save_as_fst,
  args = list(data = large_dataset, path = "cache/data.fst"),
  path.res = "cache/data.fst",
  fun.read = read_fst,      # Custom read function
  save.res = FALSE          # Function saves its own results
)
```

## Comparison with Other Packages

| Feature | `recycle` | `memoise` | `R.cache` | `targets` |
|---------|-----------|-----------|-----------|-----------|
| Simple function wrapping | ✅ | ✅ | ❌ | ❌ |
| Per-argument unwrapping | ✅ | ❌ | ❌ | Limited |
| Auto-detect function args | ✅ | ❌ | ❌ | ✅ |
| File contents tracking | ✅ (explicit) | ❌ | ❌ | ✅ (automatic) |
| Custom save/read formats | ✅ | ❌ | ❌ | ✅ |
| Works in packages | ✅ | ✅ | ✅ | ❌ |
| Interactive use | ✅ | ✅ | ✅ | Limited |

### Why not `memoise`?

`memoise` is excellent for simple caching but doesn't support:
- Per-argument transformation logic
- Comparing functions by code only (without custom hash functions)
- File contents comparison (without manual preprocessing)

### Why not `targets`?

`targets` is a powerful workflow management system but:
- Requires restructuring code into a pipeline
- Not designed for wrapping individual function calls
- Overkill for simple caching needs within packages or interactive sessions

### Why `recycle`?

`recycle` fills the gap between simple memoization and full workflow management:
- **Flexible**: Per-argument comparison logic
- **Simple**: Wrap any function call
- **Smart**: Auto-detects function arguments
- **Versatile**: Works interactively and within packages

## Advanced Usage

### Force Re-run

```r
result <- recycle(my_fun, args, path.res = "cache/result.rds", force = TRUE)
```

### Custom Digest Storage

```r
result <- recycle(
  my_fun, 
  args,
  path.res = "cache/result.rds",
  path.digest = "cache/custom_digests.rds"
)
```

### Multiple Unwrap Specifications

```r
result <- recycle(
  complex_function,
  args = list(
    fun1 = function(x) x + 1,
    fun2 = function(y) y * 2,
    file1 = "data1.csv",
    file2 = "data2.csv",
    param = 10
  ),
  path.res = "cache/result.rds",
  args.unwrap = list(
    # fun1 and fun2 auto-detected as functions
    file1 = readLines,
    file2 = function(x) read.csv(x)
  )
)
```

## How It Works

1. **Digest Calculation**: `recycle` computes digests (checksums) of all arguments
2. **Transformation**: Applies `args.unwrap` functions to specified arguments before digesting
3. **Comparison**: Compares new digests with stored digests from previous run
4. **Decision**: 
   - If digests match → return cached results
   - If digests differ → re-run function and update cache

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

GPL (>= 3)
