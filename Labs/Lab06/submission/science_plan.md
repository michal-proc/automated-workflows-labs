# My scientific product

Name: my_aoi NDMI comparison.

Scientific question: How does the NIR/SWIR1 moisture-related spectral response differ between 5 and 10 June 2025 within the same my_aoi AOI?

Product name, method/equation and authoritative source: NDMI = (NIR - SWIR1) / (NIR + SWIR1), following https://www.usgs.gov/landsat-missions/normalized-difference-moisture-index; Sentinel-2 B08 and B11 are used here rather than Landsat band numbers.

Required bands and why they measure the relevant property: nir (B08) and swir16 (B11) provide the NIR/SWIR1 contrast; scl supplies screening classes.

AOI name(s), exact bbox(es), and reason for selecting them: my_aoi, [19.842, 50.047, 19.856, 50.057], a small woodland-area selection west of central Krakow suitable for pixel inspection.

Acquisition IDs and dates; why these dates are appropriate: S2C_T34UDA_20250605T095638_L2A and S2B_T34UDA_20250610T095316_L2A, returned by the saved live search; the short same-season interval limits seasonal differences, but does not eliminate confounding.

Preparation choices: calibration source, target grid, SCL exclusions, domain restrictions: verified Collection 1 STAC/header scale and offset, 20 m UTM grid, excluded SCL [0,1,2,3,6,7,8,9,10,11], retaining observed land without restricting the mask to vegetation alone.

Output layers, metric(s), and their units: dimensionless index and runner-generated valid_mask, mean NDMI, observed area and area above an illustrative threshold in square metres.

One scientifically meaningful parameter to vary: NDMI threshold 0.2 versus 0.3, affecting the reported area rather than claiming a universal moisture class.

What observation or reference could reveal a wrong implementation: independently calculate real prepared pixels using scalar arithmetic and verify invalid pixels remain NaN.

Main limitation or confounding factor: SCL errors, mixed land cover, shadows and illumination can alter the index; two dates alone do not establish an actual change in vegetation water content.
