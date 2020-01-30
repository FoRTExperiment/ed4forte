test_that("Running ED2 works", {

  outdir <- tempfile()
  run_ed2(
    outdir,
    ED_MET_DRIVER_DB = "unsynced-data/meteorology/NARR-ED2/ED_MET_DRIVER_HEADER",
    IYEARA = 2004, IMONTHA = 7,
    IYEARZ = 2004, IMONTHZ = 8
  )
 
})
