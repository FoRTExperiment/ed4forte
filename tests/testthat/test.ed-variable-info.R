test_that("ED2 variable info works", {
  expect_is(ed2_variable_info(), "data.frame")
  expect_equal(nrow(ed2_variable_info("FMEAN_GPP_CO")), 1)
  expect_warning(
    ed2_variable_info("My fake var"),
    "variables not found in ED2 variables table: My fake var"
  )
})
