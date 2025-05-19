# Long-Term Analysis of Fractional Vegetation Cover (FVC) in Dera Ismail Khan, Pakistan (2001–2024)

This repository provides the full reproducible workflow used in the research article:

> Ahmad Anees, S., Mehmood, K., et al. (2024). *Spatiotemporal Dynamics and Environmental Drivers of Fractional Vegetation Cover in a Semi-Arid Region Using Machine Learning*. 
---

## Study Region

**Dera Ismail Khan (DIKhan), Pakistan**  
- Coordinates: ~70.5°E to 71.6°E, 31.5°N to 32.6°N  
- Climatic zone: Semi-arid  
- Application: Vegetation trend detection, climate response modeling, and uncertainty assessment

---

##  Repository Structure

```text
├── landsat_fvc_dikhan_2001_2024.js         # GEE script: Landsat NDVI & annual FVC composites
├── terraclimate_vars_dikhan_2001_2023.js   # GEE script: Precip, Temp, VPD, AET, Solar Radiation
├── srtm_elevation_slope_dikhan.js          # GEE script: Elevation & Slope extraction (SRTM)
├── fvc_tfpmk_analysis.R                    # R script: Modified Mann-Kendall + Sen's Slope
├── fvc_gwr_analysis.R                      # R script: GWR for climatic-topographic effects on FVC
├── xgboost_fvc_shap_uncertainty.R          # R script: XGBoost, SHAP interpretation & uncertainty
├── fvc_predictions_uncertainty.csv         # Output CSV: Ensemble mean FVC and standard deviation
├── FVC_XGBoost_Mean_SD.tif                 # Output raster: Mean FVC and uncertainty map
└── README.md                               # This file


## 🛰️ Data Sources

| Dataset       | Description                        | Source                                 |
|---------------|------------------------------------|----------------------------------------|
| Landsat 5/7/8 | Surface reflectance & NDVI (30 m)  | USGS / Google Earth Engine (GEE)       |
| TerraClimate  | Climate variables (4.6 km)         | [climatologylab.org](https://www.climatologylab.org/) |
| SRTM DEM      | Elevation and slope (30 m)         | USGS EarthExplorer                      |

---

##  Methodological Summary

### 1. Landsat NDVI & FVC Estimation
- Sensor fusion of **Landsat 5 TM**, **7 ETM+**, and **8 OLI** (2001–2024)
- NDVI computation and **Pixel Dichotomy Model (PDM)** for estimating FVC
- Exported as annual mean composites using **Google Earth Engine**

### 2. Trend Analysis
- Applied **Trend-Free Pre-Whitening Mann–Kendall (TFPW-MK)** test
- Calculated trend magnitude using **Theil–Sen slope estimator**
- Generated pixel-wise trend maps using `raster` and `zyp` packages in R

### 3. Climatic and Topographic Predictors
- Extracted long-term annual means or trends for:
  - **Precipitation**
  - **Temperature**
  - **Vapor Pressure Deficit (VPD)**
  - **Actual Evapotranspiration (AET)**
  - **Solar Radiation**
- Topographic variables:
  - **Elevation** (SRTM)
  - **Slope**

### 4. Geographically Weighted Regression (GWR)
- Modeled spatially varying relationships between FVC trends and environmental drivers
- Used **Gaussian spatial kernel**; bandwidth optimized via **AICc**
- Generated:
  - Local coefficient rasters
  - Local R²
  - Residual maps

### 5. Machine Learning (XGBoost)
- Trained on **10,000 stratified spatial samples**
- Predictors: Climatic and topographic variables
- Performance:
  - R² ≈ **0.93**
  - RMSE ≈ **0.026**

### 6. SHAP Analysis
- Used **SHAP (SHapley Additive exPlanations)** to decompose variable importance
- Produced:
  - Global SHAP summary plots
  - Dependence plots for nonlinear predictor effects

### 7. Uncertainty Quantification
- Applied **bootstrap ensemble (B = 100)** on XGBoost model
- Estimated **pixel-wise standard deviation** of FVC predictions
- Output: Spatial uncertainty map showing model confidence

---

##  Outputs

- `FVC_XGBoost_Mean_SD.tif` — Raster stack of mean FVC and uncertainty (σᵢ)
- `fvc_predictions_uncertainty.csv` — CSV export of spatial predictions with uncertainty
- `GWR_Coeff_*.tif` — Local coefficient rasters for predictors (e.g., elev, vpd, temp)

---

##  Citation

If you use this code or data, please cite:





---

##  Contact

**Kaleem Mehmood**  
College of Forestry, Beijing Forestry University  
📧 [kaleemmehmood73@gmail.com](mailto:kaleemmehmood73@gmail.com)

---

##  License

This project is released under the **MIT License**.















