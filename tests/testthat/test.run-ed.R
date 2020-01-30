outdir <- tempfile()
teardown(unlink(outdir, recursive = TRUE))

test_that("Running ED2 works", {

  p <- run_ed2(
    outdir,
    ED_MET_DRIVER_DB = file.path("test-meteorology", "ED_MET_DRIVER_HEADER"),
    IYEARA = 2004, IMONTHA = 6, IDATEA = 1,
    IYEARZ = 2004, IMONTHZ = 8, IDATEZ = 25
  )
  p$wait()

  # Make sure the run completed successfully
  plog <- readLines(p$get_output_file())
  expect_match(tail(plog, 1), "ED-2.2 execution ends", fixed = TRUE)

  # ...and produced output
  outfile <- file.path(outdir, "analysis-E-2004-07-00-000000-g01.h5")
  expect_true(file.exists(outfile))

})
