outdir <- tempfile()
teardown(unlink(outdir, recursive = TRUE))

test_that("Running ED2 with FoRTE inventories works", {
  sfilin <- file.path(outdir, "init")
  css_pss <- fortedata2ed(output_prefix = sfilin)
  p <- run_ed2(
    outdir, start_date, end_date,
    configxml = data.frame(num = 9, SLA = 35),
    wd = wd,
    ED_MET_DRIVER_DB = test_met,
    IED_INIT_MODE = 6,
    SFILIN = sfilin
  )
  p$wait()

  plog <- readLines(p$get_output_file())
  expect_match(tail(plog, 1), "ED-2.2 execution ends", fixed = TRUE,
               info = tail(plog, 50))

  expect_true(file.exists(file.path(outdir, "ED2IN")))
  expect_true(file.exists(file.path(outdir, "config.xml")))
  expect_true(file.exists(file.path(outdir, "history.xml")))
  expect_true(file.exists(coords_prefix(sfilin, "css")))
  expect_true(file.exists(coords_prefix(sfilin, "pss")))

  outfile <- file.path(outdir, "analysis-E-2004-07-00-000000-g01.h5")
  expect_true(file.exists(outfile))
})
