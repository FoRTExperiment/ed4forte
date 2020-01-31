test_that("Reading and writing config.xml works", {
  test_xml <- here::here("tests", "testthat", "test-data", "config.xml")
  example <- read_configxml(test_xml)
  expect_is(example, "data.frame")
  expect_equal(nrow(example), 3)
  expect_equal(example$num, c(9, 10, 11))
  expect_equal(example$clumping_factor, c(0.9, 0.65, 0.5))
  expect_equal(example$orient_factor, c(0.25, 0.3, 0.35))

  f1 <- tempfile()
  write_configxml(example, f1)
  ex2 <- read_configxml(f1)
  expect_identical(example, ex2)
})
