library(ncdf4)

# Replace with path to ED2 root directory
ed2_dir <- "~/Projects/edmodel/ed2-umbs-test/"

outdir <- file.path(
  ed2_dir,
  "EDTS/test-outputs/umbs.bg"
)
ncfiles <- list.files(outdir, full.names = TRUE)

# Look at one file
nc1 <- nc_open(ncfiles[1])

# List all available variable names
names(nc1$var)

# Read multiple variables from a single file as colums of a data.frame
read_vars <- function(file, vars) {
  nc <- ncdf4::nc_open(file)
  # Probably not strictly necessary, but good practice
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  result_list <- lapply(vars, ncdf4::ncvar_get, nc = nc)
  names(result_list) <- vars
  do.call(data.frame, result_list)
}

# Net (NPP) and Gross (GPP) primary productivity,
# heterotrophic respiration (RH), and autotrophic (plant) respiration (PLRESP).
# `MMEAN` means "monthly mean".
# `PY` means for the entire patch.
vars <- sprintf("MMEAN_%s_PY", c("NPP", "GPP", "RH", "PLRESP"))
results <- lapply(ncfiles, read_vars, vars = vars)
result_df <- do.call(rbind, results)

par(mfrow = c(2, 2))
for (v in vars) {
  plot(result_df[[v]], type = "l",
       xlab = "Month", ylab = v)
}
