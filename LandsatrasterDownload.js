// Google Earth Engine Script for Downloading Landsat Imagery for FVC Analysis
// Author: Kaleem Mehmood
// Study Area: Dera Ismail Khan, Pakistan
// Time Period: 2001–2024
// Sensors: Landsat 5 TM, Landsat 7 ETM+, Landsat 8 OLI

// Define the Area of Interest (AOI)
var dikhan = table;

// Define Time Range
var startYear = 2001;
var endYear = 2024;

// Define cloud mask function for Landsat
function maskLandsatSR(image) {
  var qa = image.select('pixel_qa');
  var cloud = qa.bitwiseAnd(1 << 5).eq(0);
  var cloudShadow = qa.bitwiseAnd(1 << 3).eq(0);
  return image.updateMask(cloud).updateMask(cloudShadow);
}

// Function to process Landsat collections
function getLandsatCollection(sensor, startYear, endYear) {
  var collection;
  if (sensor === 'L5') {
    collection = ee.ImageCollection('LANDSAT/LT05/C01/T1_SR');
  } else if (sensor === 'L7') {
    collection = ee.ImageCollection('LANDSAT/LE07/C01/T1_SR');
  } else if (sensor === 'L8') {
    collection = ee.ImageCollection('LANDSAT/LC08/C01/T1_SR');
  }

  return ee.ImageCollection(
    ee.List.sequence(startYear, endYear).map(function(year) {
      var start = ee.Date.fromYMD(year, 1, 1);
      var end = start.advance(1, 'year');
      var filtered = collection
        .filterBounds(dikhan)
        .filterDate(start, end)
        .map(maskLandsatSR)
        .map(function(image) {
          var ndvi = image.normalizedDifference(['B5', 'B4']); // Default L8 bands
          if (sensor === 'L5' || sensor === 'L7') {
            ndvi = image.normalizedDifference(['B4', 'B3']);
          }
          return ndvi.rename('NDVI')
                     .set('year', year)
                     .set('system:time_start', start.millis());
        });

      return filtered.mean().set('year', year);
    })
  ).flatten();
}

// Combine Landsat 5 (2001–2011), Landsat 7 (2001–2012), Landsat 8 (2013–2024)
var landsat5 = getLandsatCollection('L5', 2001, 2011);
var landsat7 = getLandsatCollection('L7', 2001, 2012);
var landsat8 = getLandsatCollection('L8', 2013, 2024);

// Merge and sort collections
var allLandsat = ee.ImageCollection(landsat5.merge(landsat7).merge(landsat8))
                  .sort('year');

// Print and visualize
print('Landsat NDVI collection (2001–2024):', allLandsat);

// Export yearly NDVI composites to Drive (optional)
allLandsat.evaluate(function(images) {
  images.features.forEach(function(imageInfo) {
    var img = ee.Image(imageInfo.id);
    var year = imageInfo.properties.year;
    Export.image.toDrive({
      image: img.clip(dikhan),
      description: 'NDVI_DIKHAN_' + year,
      folder: 'GEE_Exports',
      region: dikhan,
      scale: 30,
      maxPixels: 1e13
    });
  });
});
