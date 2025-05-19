# Load required libraries
library(raster)
library(sp)
library(GWmodel)
library(rgdal)
library(sf)

# 1. Load dependent and independent variables (as raster layers)
fvc_trend <- raster("path_to/FVC_Sen_Slope.tif")

# Predictor rasters – ensure all are aligned and projected identically
precip    <- raster("path_to/precip_mean.tif")
tavg      <- raster("path_to/temp_mean.tif")
vpd       <- raster("path_to/vpd_mean.tif")
aet       <- raster("path_to/aet_mean.tif")
srad      <- raster("path_to/srad_mean.tif")
elevation <- raster("path_to/elevation.tif")
slope     <- raster("path_to/slope.tif")

# 2. Stack all rasters and convert to dataframe
all_vars <- stack(fvc_trend, precip, tavg, vpd, aet, srad, elevation, slope)
names(all_vars) <- c("fvc", "precip", "tavg", "vpd", "aet", "srad", "elev", "slope")

# Sample or mask to valid pixels
df <- as.data.frame(all_vars, xy = TRUE, na.rm = TRUE)

# Remove NA rows
df <- na.omit(df)

# Convert to spatial object
coordinates(df) <- ~x + y
proj4string(df) <- CRS("+proj=utm +zone=43 +datum=WGS84")  # Adjust if needed

# 3. Bandwidth selection (Golden section search, AICc minimization)
bw <- bw.gwr(fvc ~ precip + tavg + vpd + aet + srad + elev + slope,
             data = df,
             approach = "AICc", 
             kernel = "gaussian", 
             adaptive = FALSE)

cat("Optimal bandwidth:", bw, "\n")

# 4. Run GWR model
gwr_model <- gwr.basic(fvc ~ precip + tavg + vpd + aet + srad + elev + slope,
                       data = df,
                       bw = bw,
                       kernel = "gaussian",
                       adaptive = FALSE)

# 5. Extract coefficient rasters and diagnostics
gwr_out <- as.data.frame(gwr_model$SDF)
coordinates(gwr_out) <- coordinates(df)
proj4string(gwr_out) <- CRS("+proj=utm +zone=43 +datum=WGS84")

# Write selected coefficient surfaces to raster
coeff_vars <- c("precip", "tavg", "vpd", "aet", "srad", "elev", "slope")
for (var in coeff_vars) {
  r <- rasterFromXYZ(data.frame(coordinates(gwr_out), coeff = gwr_out[[paste0(var, "_Coef")]]))
  writeRaster(r, filename = paste0("GWR_Coeff_", var, ".tif"), format = "GTiff", overwrite = TRUE)
}

# 6. Residuals and local R²
resid_ras <- rasterFromXYZ(data.frame(coordinates(gwr_out), resid = gwr_out$residual))
localr2_ras <- rasterFromXYZ(data.frame(coordinates(gwr_out), localR2 = gwr_out$localR2))

writeRaster(resid_ras, filename = "GWR_Residuals.tif", overwrite = TRUE)
writeRaster(localr2_ras, filename = "GWR_LocalR2.tif", overwrite = TRUE)
