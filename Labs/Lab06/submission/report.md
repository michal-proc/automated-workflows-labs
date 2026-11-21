# Lab 06 investigation

Name and package version: micha; eo_processing 1.0.0, Python 3.13.7, NumPy 2.5.5, Rasterio 1.5.2.

## Common exercise

Expected requests, first-run attempts, second-run attempts: 6, 6, 0; all eighteen declared output rasters were produced.

Why six requests are not six acquisition dates: Each of three acquisitions supplies two AOIs.

How a third input band enters the processing interface: Add its role to required_bands, acquire/register it with SCL, and access the prepared reflectance in calculate; preparation and runner already support arbitrary declared band sets.

Cloudy/clear river comparison:

| Date / configuration | Raw coverage | Usable coverage | Candidate water area, m2 |
| --- | ---: | ---: | ---: |
| 4 June, SCL, threshold 0 | 100% | 47.6019% | 130000 |
| 5 June, SCL, threshold 0 | 100% | 99.3963% | 231200 |
| 4 June, nodata_only | 100% | 100% | 233600 |
| 5 June, threshold 0.15 | 100% | 99.3963% | 181600 |

The first two areas describe different observed footprints, so they do not prove actual water expansion; compare common clear pixels on the same grid and validate classifications against independent observations.

What disabling cloud screening changed: Usable coverage rose from 47.6019% to 100%, but retained cloudy observations caused QC to request review rather than establish scientific usefulness.

Effect of changing the MNDWI threshold: Candidate water area decreased from 231200 to 181600 m2 with unchanged usable coverage, and a distinct request was created because the classification parameter changed.
Thresholds should be selected against independent labelled water observations for the intended conditions, not map appearance.

QC policy change: Assessment IDs 1-6 used minimum coverage 0.5; IDs 9-14 reassessed the same six attempts at 0.995, with zero new processing attempts (8 existed including both comparison experiments).
The original conclusions were 4 accepted and 2 rejected; all six stricter assessments were rejected, while execution statuses remained succeeded because scientific acceptance is separate from execution history.

Changing minimum QC coverage reuses measured metrics, while changing cloud screening changes the pixels entering the calculation and therefore requires a new scientific request.

One useful SQL query and actual output: The first query in queries.sql returns six succeeded attempts whose latest assessment rejected coverage; the output-role query returns 24 rows for eight three-output MNDWI attempts, and assessment history contains 14 rows.
The appended NDMI query returns four personal producing attempts with their thresholds, coverage and measured areas; an empty result means no succeeded NDMI attempt is registered in that catalogue.

## My scientific product

Question and science plan: Compare the moisture-related NDMI response between 5 and 10 June in the my_aoi AOI; see [science_plan.md](science_plan.md).

Method: (NIR - SWIR1) / (NIR + SWIR1), using Sentinel-2 B08/B11; source: https://www.usgs.gov/landsat-missions/normalized-difference-moisture-index.

These commands document creation in order; existing manifests/workspaces/reports are retained, so rerun processing rather than recreating them.

Input bundle: work/personal/inputs/manifest.json records source scene IDs S2C_T34UDA_20250605T095638_L2A and S2B_T34UDA_20250610T095316_L2A, nir/swir16/scl, per-file SHA-256, native calibration and source URLs; all six real subsets and both STAC items remain in that directory (6815750 downloaded bytes).
Submit this small directory together with the frozen manifests and generated HTML/JSON reports; work/ is deliberately excluded from Git.

Extension path/version: extensions/my_product.py, ndmi 1.0.0; editable settings are config/personal_acquisition.json, config/personal_batch.json and config/personal_threshold03.json, with frozen manifests work/personal/my_aoi_batch.json and work/personal/my_aoi_threshold03_batch.json.

Repeat/reuse evidence: The initial personal batch launched two attempts and the repeat launched zero; threshold 0.3 created two different requests, again reused without new attempts on repetition.

| Date | Usable coverage | Mean NDMI | Area > 0.2, m2 | Area > 0.3, m2 |
| --- | ---: | ---: | ---: | ---: |
| 2025-06-05 | 100% | 0.36376682 | 1073200 | 1016000 |
| 2025-06-10 | 100% | 0.40212485 | 1085200 | 1052400 |

Independent check: Scalar arithmetic for three actual prepared pixels per date matched saved index values within 1e-6; on 5 June pixel (0,1), expected 0.367203132 and measured 0.367203146.
The personal automated test also confirms invalid observations stay NaN, input arrays remain unchanged and all-masked inputs produce no mean or threshold area.

Scientific finding: All 2777 valid pixels were common to both dates; their mean NDMI difference was +0.03835804, a spectral change rather than proof of a change in measured water content.
SCL may miss contamination, and mixed/bare boundary pixels and illumination can cause false interpretations; the thresholds are exploratory, not validated moisture classes.

Core verification: check-core returned identical_to_class_release=true; all 14 tests passed, including the personal real-pixel check.

Assistance: An LLM helped select a simple product, implement the extension, execute comparisons and draft this report; suggestions were checked against USGS, preserved metadata, real pixels and tests.
The offset-zero interpretation from the older Lab04 example was not transferred: these Collection 1 inputs retain their verified metadata calibration.
