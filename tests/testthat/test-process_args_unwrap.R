test_that("process_args_unwrap handles 'function' keyword", {
  args.unwrap <- list(myfun = "function")
  result <- process_args_unwrap(args.unwrap)
  
  expect_type(result, "list")
  expect_equal(names(result), "myfun")
  expect_true(is.function(result$myfun))
  
  # Test that it extracts body and formals
  test_fun <- function(x) x + 1
  unwrapped <- result$myfun(test_fun)
  expect_equal(unwrapped, list(body(test_fun), formals(test_fun)))
})

test_that("process_args_unwrap handles custom functions", {
  custom_fun <- function(x) readLines(x, warn = FALSE)
  args.unwrap <- list(myfile = custom_fun)
  result <- process_args_unwrap(args.unwrap)
  
  expect_equal(result$myfile, custom_fun)
})

test_that("process_args_unwrap handles mixed specifications", {
  custom_fun <- function(x) x * 2
  args.unwrap <- list(
    myfun = "function",
    myfile = custom_fun,
    ignored = NULL
  )
  result <- process_args_unwrap(args.unwrap)
  
  expect_equal(length(result), 2)
  expect_true("myfun" %in% names(result))
  expect_true("myfile" %in% names(result))
  expect_false("ignored" %in% names(result))
})

test_that("process_args_unwrap validates inputs", {
  expect_error(process_args_unwrap("not a list"),
               "'args.unwrap' must be a named list")
  
  expect_error(process_args_unwrap(list(1, 2)),
               "must be a named list with all elements named")
  
  expect_error(process_args_unwrap(list(x = "invalid_keyword")),
               "Unknown keyword 'invalid_keyword'")
  
  expect_error(process_args_unwrap(list(x = 123)),
               "Invalid unwrap specification")
})

test_that("process_args_unwrap returns NULL for NULL input", {
  result <- process_args_unwrap(NULL)
  expect_null(result)
})

test_that("function keyword only unwraps actual functions", {
  args.unwrap <- list(x = "function")
  result <- process_args_unwrap(args.unwrap)
  
  # Should return non-function values unchanged
  expect_equal(result$x(5), 5)
  expect_equal(result$x("text"), "text")
  
  # Should unwrap functions
  test_fun <- function(a) a + 1
  unwrapped <- result$x(test_fun)
  expect_equal(unwrapped, list(body(test_fun), formals(test_fun)))
})

test_that("auto-detects function arguments and applies default unwrapping", {
  # Function argument without explicit args.unwrap
  args <- list(
    x = 5,
    myfun = function(a) a + 1,
    y = "text"
  )
  
  result <- process_args_unwrap(NULL, args)
  
  # Should have created unwrap function for myfun only
  expect_equal(length(result), 1)
  expect_true("myfun" %in% names(result))
  expect_false("x" %in% names(result))
  expect_false("y" %in% names(result))
  
  # Should unwrap the function
  test_fun <- function(a) a + 1
  unwrapped <- result$myfun(test_fun)
  expect_equal(unwrapped, list(body(test_fun), formals(test_fun)))
})

test_that("explicit args.unwrap overrides auto-detection", {
  custom_unwrap <- function(f) "custom"
  
  args <- list(
    myfun = function(a) a + 1
  )
  
  args.unwrap <- list(
    myfun = custom_unwrap
  )
  
  result <- process_args_unwrap(args.unwrap, args)
  
  # Should use the custom function, not auto-detected default
  expect_equal(result$myfun, custom_unwrap)
})

test_that("auto-detection works with mixed argument types", {
  args <- list(
    x = 5,
    fun1 = function(a) a + 1,
    file = "path.txt",
    fun2 = function(b) b * 2
  )
  
  args.unwrap <- list(
    file = readLines  # Explicit for file
  )
  
  result <- process_args_unwrap(args.unwrap, args)
  
  # Should have unwrap for fun1, fun2 (auto), and file (explicit)
  expect_equal(length(result), 3)
  expect_true("fun1" %in% names(result))
  expect_true("fun2" %in% names(result))
  expect_true("file" %in% names(result))
  expect_equal(result$file, readLines)
})
