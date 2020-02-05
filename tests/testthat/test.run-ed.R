outdir <- tempfile()
teardown(unlink(outdir, recursive = TRUE))

test_that("Running ED2 from bare ground works", {

  p <- run_ed2(
    outdir, start_date, end_date,
    configxml = data.frame(num = 9, SLA = 35),
    wd = wd,
    ED_MET_DRIVER_DB = test_met
  )
  p$wait()

  # Make sure the run completed successfully
  plog <- readLines(p$get_output_file())
  expect_match(tail(plog, 1), "ED-2.2 execution ends", fixed = TRUE,
               info = tail(plog, 50))

  # ...generated the right input files
  expect_true(file.exists(file.path(outdir, "ED2IN")))
  expect_true(file.exists(file.path(outdir, "config.xml")))
  expect_true(file.exists(file.path(outdir, "history.xml")))
  cfg <- read_configxml(file.path(outdir, "config.xml"))
  expect_equal(cfg$SLA, 35)
  expect_equal(cfg$num, 9)
  hist <- xml2::read_xml(file.path(outdir, "history.xml"))
  sla9 <- as.numeric(xml2::xml_text(xml2::xml_find_all(
    hist,
    "/config/pft[num=9]/SLA[text()]"
  ), trim = TRUE))
  expect_equal(sla9, 35)

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


# Test the overwrite argument. 
ptrue <- run_ed2(
  file.path(basedir, "default"),
  "1980-01-01", "1990-01-01",
  ED_MET_DRIVER_DB = narr_met, 
  overwrite = TRUE
)

pNull <- run_ed2(
  file.path(basedir, "default"),
  "1980-01-01", "1990-01-01",
  ED_MET_DRIVER_DB = narr_met, 
  overwrite = NULL
)

pFalse <- run_ed2(
  file.path(basedir, "default"),
  "1980-01-01", "1990-01-01",
  ED_MET_DRIVER_DB = narr_met, 
  overwrite = FALSE
)

testthat::expect_error({pError <- run_ed2(
  file.path(basedir, "default"),
  "1980-01-01", "1990-01-01",
  ED_MET_DRIVER_DB = narr_met, 
  overwrite = NA
)}, 'run canceled')