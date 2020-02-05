outdir <- tempfile()
teardown(unlink(outdir, recursive = TRUE))

test_that("Prescribed disturbance works", {

  sfilin <- file.path(outdir, "init")
  css_pss <- fortedata2ed(output_prefix = sfilin)
  p <- run_ed2(
    outdir, "2004-06-01", "2004-08-31",
    wd = wd,
    ED_MET_DRIVER_DB = test_met,
    IDOUTPUT = 3,
    EVENT_FILE = file.path("test-data", "events.xml")
  )
  p$wait()
  plog <- readLines(p$get_output_file())
  expect_match(tail(plog, 1), "ED-2.2 execution ends", fixed = TRUE,
               info = tail(plog, 50))

})
