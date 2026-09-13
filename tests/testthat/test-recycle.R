test_that("recycle works with simple function", {
  # Create temp directory for cache
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Simple function
  add_fun <- function(x, y) {
    x + y
  }
  
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run - should execute
  result1 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result1, 3)
  expect_true(file.exists(path_res))
  
  # Second run - should use cache
  result2 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result2, 3)
  
  # Different args - should re-run
  result3 <- recycle(add_fun, list(x = 2, y = 3), path.res = path_res, quiet = TRUE)
  expect_equal(result3, 5)
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle works with custom read function", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Create a function that saves to CSV
  save_csv <- function(data, path) {
    write.csv(data, path, row.names = FALSE)
    return(data)
  }
  
  path_res <- file.path(cache_dir, "result.csv")
  
  # First run - function saves its own results
  test_data <- data.frame(x = 1:3, y = 4:6)
  result1 <- recycle(save_csv,
                     list(data = test_data, path = path_res),
                     path.res = path_res,
                     fun.read = function(p) read.csv(p),
                     save.res = FALSE,
                     quiet = TRUE)
  expect_equal(result1, test_data)
  expect_true(file.exists(path_res))
  
  # Second run - should use cache and custom read function
  result2 <- recycle(save_csv,
                     list(data = test_data, path = path_res),
                     path.res = path_res,
                     fun.read = function(p) read.csv(p),
                     save.res = FALSE,
                     quiet = TRUE)
  expect_equal(result2, test_data)
  
  # Different data - should re-run
  test_data2 <- data.frame(x = 7:9, y = 10:12)
  result3 <- recycle(save_csv,
                     list(data = test_data2, path = path_res),
                     path.res = path_res,
                     fun.read = function(p) read.csv(p),
                     save.res = FALSE,
                     quiet = TRUE)
  expect_equal(result3, test_data2)
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle save.res=FALSE skips saving results", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Function that saves to a text file
  save_text <- function(text, path) {
    writeLines(text, path)
    return(text)
  }
  
  path_res <- file.path(cache_dir, "result.txt")
  
  # First run
  result1 <- recycle(save_text,
                     list(text = "hello world", path = path_res),
                     path.res = path_res,
                     fun.read = function(p) readLines(p, warn = FALSE),
                     save.res = FALSE,
                     quiet = TRUE)
  expect_equal(result1, "hello world")
  
  # Verify it's a text file, not RDS
  content <- readLines(path_res, warn = FALSE)
  expect_equal(content, "hello world")
  
  # Should not be an RDS file
  expect_error(readRDS(path_res), "unknown input format")
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle default behavior saves with saveRDS", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  add_fun <- function(x, y) x + y
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run - default save.res=TRUE
  result1 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result1, 3)
  
  # Verify it's an RDS file
  result_from_file <- readRDS(path_res)
  expect_equal(result_from_file, 3)
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle works with file.args", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Create test file
  test_file <- tempfile(fileext = ".txt")
  writeLines("line1\nline2", test_file)
  
  # Function that uses file
  read_fun <- function(file, multiplier) {
    lines <- readLines(file, warn = FALSE)
    length(lines) * multiplier
  }
  
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run
  result1 <- recycle(read_fun, 
                     list(file = test_file, multiplier = 2),
                     path.res = path_res,
                     args.unwrap = list(file = function(x) readLines(x, warn = FALSE)),
                     quiet = TRUE)
  expect_equal(result1, 4)
  
  # Same file, same args - should use cache
  result2 <- recycle(read_fun,
                     list(file = test_file, multiplier = 2),
                     path.res = path_res,
                     args.unwrap = list(file = function(x) readLines(x, warn = FALSE)),
                     quiet = TRUE)
  expect_equal(result2, 4)
  
  # Modify file contents - should re-run
  writeLines("line1\nline2\nline3", test_file)
  result3 <- recycle(read_fun,
                     list(file = test_file, multiplier = 2),
                     path.res = path_res,
                     args.unwrap = list(file = function(x) readLines(x, warn = FALSE)),
                     quiet = TRUE)
  expect_equal(result3, 6)
  
  # Cleanup
  unlink(test_file)
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle works with function arguments", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Function that takes another function as argument
  apply_fun <- function(x, transform) {
    transform(x)
  }
  
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run with one transform function
  transform1 <- function(x) x * 2
  result1 <- recycle(apply_fun,
                     list(x = 5, transform = transform1),
                     path.res = path_res,
                     args.unwrap = list(transform = "function"),
                     quiet = TRUE)
  expect_equal(result1, 10)
  
  # Same function code - should use cache
  transform2 <- function(x) x * 2
  result2 <- recycle(apply_fun,
                     list(x = 5, transform = transform2),
                     path.res = path_res,
                     args.unwrap = list(transform = "function"),
                     quiet = TRUE)
  expect_equal(result2, 10)
  
  # Different function code - should re-run
  transform3 <- function(x) x * 3
  result3 <- recycle(apply_fun,
                     list(x = 5, transform = transform3),
                     path.res = path_res,
                     args.unwrap = list(transform = "function"),
                     quiet = TRUE)
  expect_equal(result3, 15)
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle force argument works", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Function with side effect to track calls
  call_count <- 0
  count_fun <- function(x) {
    call_count <<- call_count + 1
    x + 1
  }
  
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run
  call_count <- 0
  result1 <- recycle(count_fun, list(x = 5), path.res = path_res, quiet = TRUE)
  expect_equal(result1, 6)
  expect_equal(call_count, 1)
  
  # Second run - should use cache
  result2 <- recycle(count_fun, list(x = 5), path.res = path_res, quiet = TRUE)
  expect_equal(result2, 6)
  expect_equal(call_count, 1)  # Not incremented
  
  # Force re-run
  result3 <- recycle(count_fun, list(x = 5), path.res = path_res, force = TRUE, quiet = TRUE)
  expect_equal(result3, 6)
  expect_equal(call_count, 2)  # Incremented
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle handles missing results file", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  add_fun <- function(x, y) x + y
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run
  result1 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result1, 3)
  
  # Delete results file
  unlink(path_res)
  
  # Should re-run
  result2 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result2, 3)
  expect_true(file.exists(path_res))
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle validates inputs", {
  expect_error(recycle("not a function", list(x = 1), path.res = "test.rds"),
               "'fun' must be a function")
  
  expect_error(recycle(function(x) x, "not a list", path.res = "test.rds"),
               "'args' must be a named list")
  
  expect_error(recycle(function(x) x, list(1, 2), path.res = "test.rds"),
               "must be a named list with all elements named")
})

test_that("recycle creates directories if needed", {
  cache_dir <- file.path(tempdir(), "deep", "nested", "dir")
  
  add_fun <- function(x, y) x + y
  path_res <- file.path(cache_dir, "result.rds")
  
  result <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result, 3)
  expect_true(file.exists(path_res))
  
  # Cleanup
  unlink(file.path(tempdir(), "deep"), recursive = TRUE)
})

test_that("recycle auto-detects function arguments without explicit args.unwrap", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  # Function that takes another function as argument
  apply_fun <- function(x, transform) {
    transform(x)
  }
  
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run - no args.unwrap specified, should auto-detect
  transform1 <- function(x) x * 2
  result1 <- recycle(apply_fun,
                     list(x = 5, transform = transform1),
                     path.res = path_res,
                     quiet = TRUE)
  expect_equal(result1, 10)
  
  # Same function code - should use cache (auto-detection working)
  transform2 <- function(x) x * 2
  result2 <- recycle(apply_fun,
                     list(x = 5, transform = transform2),
                     path.res = path_res,
                     quiet = TRUE)
  expect_equal(result2, 10)
  
  # Different function code - should re-run
  transform3 <- function(x) x * 3
  result3 <- recycle(apply_fun,
                     list(x = 5, transform = transform3),
                     path.res = path_res,
                     quiet = TRUE)
  expect_equal(result3, 15)
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle detects external modification of results file", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  add_fun <- function(x, y) x + y
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run
  result1 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result1, 3)
  
  # Second run - should use cache
  result2 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result2, 3)
  
  # Modify results file externally
  Sys.sleep(0.1)  # Ensure file timestamp changes
  saveRDS(999, path_res)
  
  # Should detect change and re-run
  result3 <- recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  expect_equal(result3, 3)  # Should recompute correct value
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})

test_that("recycle quiet parameter controls messages", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  
  add_fun <- function(x, y) x + y
  path_res <- file.path(cache_dir, "result.rds")
  
  # First run with quiet=FALSE should show message
  expect_message(
    recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = FALSE),
    "results file does not exist"
  )
  
  # Second run with quiet=FALSE should show cache message
  expect_message(
    recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = FALSE),
    "Using cached results"
  )
  
  # With quiet=TRUE should not show messages
  expect_silent(
    recycle(add_fun, list(x = 1, y = 2), path.res = path_res, quiet = TRUE)
  )
  
  # Cleanup
  unlink(cache_dir, recursive = TRUE)
})
