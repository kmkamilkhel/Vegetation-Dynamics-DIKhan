// GEE Script: SRTM Elevation and Slope Extraction
// Author: Kaleem Mehmood
// Region: Dera Ismail Khan

// Define AOI
var dikhan = table;

// Load SRTM DEM (30 m)
var dem = ee.Image("USGS/SRTMGL1_003").clip(dikhan);

// Derive Slope in degrees
var terrain = ee.Terrain.products(dem);
var slope = terrain.select('slope');

// Visualize
Map.centerObject(dikhan, 9);
Map.addLayer(dem, {min: 0, max: 1000, palette: ['white', 'green']}, 'Elevation (SRTM)');
Map.addLayer(slope, {min: 0, max: 60, palette: ['yellow', 'red']}, 'Slope');

// Export to Drive
Export.image.toDrive({
  image: dem,
  description: 'DEM_DIKHAN_30m',
  folder: 'GEE_Exports',
  region: dikhan,
  scale: 30,
  maxPixels: 1e13
});

Export.image.toDrive({
  image: slope,
  description: 'Slope_DIKHAN_30m',
  folder: 'GEE_Exports',
  region: dikhan,
  scale: 30,
  maxPixels: 1e13
});
