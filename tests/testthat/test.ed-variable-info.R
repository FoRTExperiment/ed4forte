test_that("ED2 variable info works", {
  expect_is(ed2_variable_info(), "data.frame")
  expect_equal(nrow(ed2_variable_info("FMEAN_GPP_CO")), 1)
  expect_warning(
    ed2_variable_info("My fake var"),
    "variables not found in ED2 variables table: My fake var"
  )
  out <- ed2_variable_info()
  df_results <- c(out$df_cohort, out$df_pft, out$df_scalar, out$df_soil)
  # Make sure that all of the df indicators are T/F and that there are no NAs. 
  expect_equal(sum(is.na(df_results)), 0)
  expect_true(is.logical(df_results))
  })

