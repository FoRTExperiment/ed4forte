outdir <- tempfile()
teardown(unlink(outdir, recursive = TRUE))

test_that("Running ED2 works", {

  p <- run_ed2(
    outdir, "2004-07-01", "2004-08-25",
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
