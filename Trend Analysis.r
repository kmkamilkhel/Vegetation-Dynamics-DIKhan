# Load required libraries
library(Kendall)
library(trend)
library(zyp)
library(raster)
library(rgdal)
library(parallel)

# 1. Load your FVC raster stack (annual mean FVC from 2001 to 2024)
# Note: Make sure layers are named as FVC_2001, FVC_2002, ..., FVC_2024
fvc_stack <- stack("path_to/FVC_Stack_2001_2023.tif")

# 2. Function to apply TFPW-MK with Theil-Sen slope
analyze_pixel <- function(fvc_ts) {
  if (all(is.na(fvc_ts))) return(rep(NA, 4))  # Handle NA rows

  # Convert to numeric time series
  ts <- ts(fvc_ts)

  # Step 1: Check lag-1 autocorrelation
  acf_val <- acf(ts, plot = FALSE, lag.max = 1)$acf[2]
  sig_acf <- Box.test(ts, lag = 1, type = "Ljung-Box")$p.value < 0.05

  # Step 2: Apply TFPW if autocorrelation is significant
  if (sig_acf) {
    ts_detrended <- resid(lm(ts ~ seq_along(ts)))  # Remove trend
    acf_d <- acf(ts_detrended, plot = FALSE, lag.max = 1)$acf[2]
    ts_pw <- ts - acf_d * c(NA, head(ts, -1))  # Pre-whitened
    ts_pw <- ts_pw[!is.na(ts_pw)]
  } else {
    ts_pw <- ts
  }

  # Step 3: Apply Mann–Kendall test
  mk <- MannKendall(ts_pw)
  z_score <- qnorm((1 + mk$tau)/2)
  p_value <- mk$sl
  tau <- mk$tau

  # Step 4: Apply Theil–Sen slope
  slope <- zyp.sen(ts ~ seq_along(ts))$coefficients[2]

  return(c(tau, z_score, p_value, slope))
}

# 3. Apply the function to each pixel using parallel processing
beginCluster(n = detectCores() - 1)  # Start parallel backend
trend_results <- clusterR(fvc_stack, calc, args = list(fun = analyze_pixel))
endCluster()

# 4. Assign meaningful names to output bands
names(trend_results) <- c("Tau", "Z_score", "P_value", "Sen_Slope")

# 5. Export results as GeoTIFFs
writeRaster(trend_results, filename = "FVC_TFPW_MK_Trends.tif", bylayer = TRUE, format = "GTiff", overwrite = TRUE)
