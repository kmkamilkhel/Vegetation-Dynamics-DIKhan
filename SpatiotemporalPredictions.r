# Load necessary libraries
library(xgboost)
library(data.table)
library(SHAPforxgboost)
library(caret)
library(dplyr)
library(terra)
library(doParallel)

# Step 1: Load and prepare the dataset
data <- read.csv("path_to/fvc_training_data.csv")  # 10,000 stratified samples
head(data)

# Separate predictors and response
predictors <- c("precip", "tavg", "vpd", "aet", "elev", "slope")
X <- as.matrix(data[, predictors])
y <- data$FVC

# Step 2: Train-test split (stratified spatial split done previously)
set.seed(2023)
train_idx <- createDataPartition(y, p = 0.7, list = FALSE)
X_train <- X[train_idx, ]
X_test  <- X[-train_idx, ]
y_train <- y[train_idx]
y_test  <- y[-train_idx]

# Step 3: Define hyperparameters (use tuned values)
params <- list(
  booster = "gbtree",
  objective = "reg:squarederror",
  eta = 0.05,
  max_depth = 6,
  subsample = 0.8,
  colsample_bytree = 0.7,
  lambda = 1,
  alpha = 0
)

# Step 4: Train XGBoost model
dtrain <- xgb.DMatrix(data = X_train, label = y_train)
dtest <- xgb.DMatrix(data = X_test, label = y_test)
model <- xgb.train(params, dtrain, nrounds = 200, watchlist = list(train = dtrain), verbose = 0)

# Step 5: SHAP Interpretation
shap_values <- shap.values(xgb_model = model, X_train = X_train)
shap.plot.summary(shap_values$shap_score, X_train, top_n = 6)

# Optional: dependence plots
shap.plot.dependence(data_long = shap.prep(shap_contrib = shap_values$shap_score, X_train = X_train), 
                     x = "elev", y = "elev")

# Step 6: Bootstrap Uncertainty Analysis
B <- 100
set.seed(123)
predictions <- matrix(NA, nrow = nrow(X), ncol = B)

cl <- makeCluster(detectCores() - 1)
registerDoParallel(cl)

predictions <- foreach(b = 1:B, .combine = cbind, .packages = c("xgboost")) %dopar% {
  boot_idx <- sample(1:nrow(X_train), replace = TRUE)
  dboot <- xgb.DMatrix(data = X_train[boot_idx, ], label = y_train[boot_idx])
  model_b <- xgb.train(params, dboot, nrounds = 200, verbose = 0)
  predict(model_b, newdata = xgb.DMatrix(X))
}
stopCluster(cl)

# Step 7: Ensemble Mean and Uncertainty (SD)
ensemble_mean <- rowMeans(predictions)
ensemble_sd <- apply(predictions, 1, sd)

# Step 8: Merge predictions and export
out_df <- data.frame(data[, c("x", "y")], FVC_pred = ensemble_mean, FVC_uncertainty = ensemble_sd)
write.csv(out_df, "fvc_predictions_uncertainty.csv", row.names = FALSE)

# Optional: Convert to raster
coordinates(out_df) <- ~x + y
gridded(out_df) <- TRUE
r_pred <- raster(out_df, layer = "FVC_pred")
r_sd <- raster(out_df, layer = "FVC_uncertainty")
writeRaster(stack(r_pred, r_sd), "FVC_XGBoost_Mean_SD.tif", overwrite = TRUE)
