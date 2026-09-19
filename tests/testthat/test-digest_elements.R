test_that("digest_list works without unwrap functions", {
  args <- list(x = 1, y = 2, z = "test")
  result <- digest_list(args)
  
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 3)
  expect_equal(result$name, c("x", "y", "z"))
  expect_true(all(nchar(result$res) > 0))
})

test_that("digest_list applies unwrap functions", {
  args <- list(x = 1, y = function(a) a + 1)
  
  # Without unwrap - function will include environment
  result1 <- digest_list(args)
  
  # With unwrap - function compared by code only
  funs.unwrap <- list(
    y = function(f) list(body(f), formals(f))
  )
  result2 <- digest_list(args, funs.unwrap)
  
  # Digests should be different
  expect_false(result1[name == "y"]$res == result2[name == "y"]$res)
  
  # x should be the same
  expect_equal(result1[name == "x"]$res, result2[name == "x"]$res)
})

test_that("digest_list handles NULL values", {
  args <- list(x = 1, y = NULL, z = 3)
  funs.unwrap <- list(y = function(x) x)
  
  result <- digest_list(args, funs.unwrap)
  
  # NULL should be removed
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("x", "z"))
})

test_that("digest_list is consistent", {
  args <- list(x = 1, y = 2)
  
  result1 <- digest_list(args)
  result2 <- digest_list(args)
  
  expect_equal(result1, result2)
})
