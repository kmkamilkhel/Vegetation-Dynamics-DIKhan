// GEE Script: Extract TerraClimate Variables (2001–2023)
// Author: Kaleem Mehmood
// Study Region: Dera Ismail Khan, Pakistan
// Variables: Precipitation, Temperature, VPD, AET, Solar Radiation

// Define Area of Interest (AOI)
var dikhan = table;

// Define Years
var startYear = 2001;
var endYear = 2023;
var years = ee.List.sequence(startYear, endYear);

// Define function to compute annual mean for each variable
function getAnnualMean(datasetId, varName, years) {
  return ee.ImageCollection(years.map(function(year) {
    var start = ee.Date.fromYMD(year, 1, 1);
    var end = start.advance(1, 'year');
    var image = ee.ImageCollection(datasetId)
      .filterBounds(dikhan)
      .filterDate(start, end)
      .select(varName)
      .mean()
      .clip(dikhan)
      .set('year', year);
    return image.rename(varName);
  }));
}

// TerraClimate variables from dataset "IDAHO_EPSCOR/TERRACLIMATE"
var prec = getAnnualMean("IDAHO_EPSCOR/TERRACLIMATE", "pr", years);       // Precipitation (mm)
var tavg = getAnnualMean("IDAHO_EPSCOR/TERRACLIMATE", "tmmx", years);     // Max temperature (°C *10)
var vpd  = getAnnualMean("IDAHO_EPSCOR/TERRACLIMATE", "vpd", years);      // VPD (kPa)
var aet  = getAnnualMean("IDAHO_EPSCOR/TERRACLIMATE", "aet", years);      // Actual Evapotranspiration (mm)
var srad = getAnnualMean("IDAHO_EPSCOR/TERRACLIMATE", "srad", years);     // Solar radiation (W/m²)

// Merge collections into multi-band image per year (optional)
function mergeAnnualImages(year) {
  year = ee.Number(year);
  var image = ee.Image.cat([
    prec.filter(ee.Filter.eq('year', year)).first(),
    tavg.filter(ee.Filter.eq('year', year)).first(),
    vpd.filter(ee.Filter.eq('year', year)).first(),
    aet.filter(ee.Filter.eq('year', year)).first(),
    srad.filter(ee.Filter.eq('year', year)).first()
  ]).set('year', year);
  return image;
}

var annualClimateStack = ee.ImageCollection(years.map(mergeAnnualImages));

// Print and Inspect
print('Annual Climate Stack (2001–2023):', annualClimateStack);

// Optional: Export each year to Google Drive
annualClimateStack.evaluate(function(images) {
  images.features.forEach(function(imageInfo) {
    var year = imageInfo.properties.year;
    var img = ee.Image(imageInfo.id);
    Export.image.toDrive({
      image: img,
      description: 'TerraClimate_' + year,
      folder: 'GEE_Exports',
      region: dikhan,
      scale: 4638,  // Native TerraClimate resolution (~4.6km)
      maxPixels: 1e13
    });
  });
});
