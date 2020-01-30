outdir <- tempfile()
teardown(unlink(outdir, recursive = TRUE))

start_date <- "2004-07-01"
end_date <- "2004-08-31"
nmonths <- 1

test_that("Running ED2 works", {

  p <- run_ed2(
    outdir, start_date, end_date,
    ED_MET_DRIVER_DB = file.path("test-meteorology", "ED_MET_DRIVER_HEADER"),
  )
  p$wait()

  # Make sure the run completed successfully
  plog <- readLines(p$get_output_file())
  expect_match(tail(plog, 1), "ED-2.2 execution ends", fixed = TRUE,
               info = tail(plog, 50))

  # ...and produced output
  outfile <- file.path(outdir, "analysis-E-2004-07-00-000000-g01.h5")
  expect_true(file.exists(outfile))

})

test_that("Reading ED2 monthly output works", {
  suppressWarnings(results <- read_monthly_dir(outdir))
  expect_is(results, "data.frame")
  expect_equal(nrow(results[["df_scalar"]][[1]]), nmonths)
  expect_equal(nrow(results[["df_pft"]][[1]]), nmonths * 17)
  expect_equal(
    results[["df_scalar"]][[1]][["datetime"]],
    as.POSIXct("2004-07-01", tz = "UTC")
  )
  expect_true(file.exists(file.path(outdir, "monthly-output.rds")))
})
