test_that("Reading ED2IN works", {
  d <- ed2in()
  expect_equal(d$IED_INIT_MODE, 0)
  expect_equal(
    d$ED_MET_DRIVER_DB,
    "unsynced-data/meteorology/hybrid-ED2/ED_MET_DRIVER_HEADER"
  )
  expect_equal(d$SLZ, c(-3, -2, -1, -0.6, -0.3, -0.15, -0.05))
})

test_that("Writing ED2IN works", {
  d1 <- ed2in()
  temp_file <- tempfile()
  write_ed2in(d1, temp_file)
  d2 <- read_ed2in(temp_file)
  expect_identical(d1, d2)
})

test_that("Modifying ED2IN works", {
  args <- list(INCLUDE_THESE_PFT = c(6, 9:11))
  d1 <- ed2in(!!!args)
  d1$SLZ[1] <- -3.12
  temp_file <- tempfile()
  write_ed2in(d1, temp_file)
  d2 <- read_ed2in(temp_file)
  expect_identical(d1, d2)
  expect_equal(d2$INCLUDE_THESE_PFT, c(6, 9:11))
})
