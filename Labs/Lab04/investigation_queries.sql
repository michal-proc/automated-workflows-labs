-- Write and retain your diagnostic queries here. Use the notebook questions.
-- Enable enforcement when opening your own SQLite session:
PRAGMA foreign_keys = ON;

-- Q1. List requests with their number of attempts, grouped by outcome.
SELECT request_id, status, COUNT(*) AS attempts
FROM processing_attempts
GROUP BY request_id, status;

-- Q2. Starting from an NDVI artifact ID, find its successful producing attempt,
-- normalized request, each input role, original Lab 3 subset, scene, band and AOI.
-- Bind :artifact_id to the NDVI artifact being investigated.
SELECT o.artifact_id AS ndvi_artifact_id, p.attempt_id AS producing_attempt,
       r.request_id, r.normalized_json, i.role, f.artifact_id AS input_artifact_id,
       s.subset_id, a.collection, a.item_id, a.asset_key, s.aoi_json, s.recipe_version
FROM processing_outputs o
JOIN processing_attempts p ON p.attempt_id = o.attempt_id AND p.status = 'succeeded'
JOIN processing_requests r ON r.request_id = p.request_id
JOIN processing_inputs i ON i.request_id = r.request_id
JOIN processing_artifacts f ON f.artifact_id = i.artifact_id
JOIN artifacts original ON original.artifact_id = f.source_artifact_id
JOIN subset_requests s ON s.subset_id = original.subset_id
JOIN assets a ON a.asset_id = s.asset_id
JOIN scenes scene ON scene.collection = a.collection AND scene.item_id = a.item_id
WHERE o.artifact_id = :artifact_id AND o.role = 'ndvi'
ORDER BY i.role;

-- Q3. Find failed/interrupted attempts with stage and error; retain recovery rows.
SELECT p.attempt_id, p.request_id, p.status, p.stage, p.error_code, p.error_message,
       CASE WHEN l.status IS NOT NULL THEN i.role END AS unavailable_input_role,
       l.local_path, l.status AS location_status,
       recovered.attempt_id AS recovery_attempt, recovered.status AS recovery_status
FROM processing_attempts p
LEFT JOIN processing_inputs i ON i.request_id = p.request_id
LEFT JOIN processing_artifact_locations l
    ON l.artifact_id = i.artifact_id AND l.status != 'available'
LEFT JOIN processing_attempts recovered
    ON recovered.request_id = p.request_id AND recovered.started_at > p.started_at
    AND recovered.status = 'succeeded'
WHERE p.status IN ('failed', 'interrupted')
ORDER BY p.started_at, i.role;

-- Q4. Find succeeded attempts whose returned artifact has no available location.
-- Explain why SQL alone cannot prove current filesystem availability.
-- Locations describe the last check; verify bytes on disk before using a result.
SELECT p.attempt_id, o.artifact_id
FROM processing_attempts p
JOIN processing_outputs o ON o.attempt_id = p.attempt_id
WHERE p.status = 'succeeded'
  AND NOT EXISTS (
      SELECT 1 FROM processing_artifact_locations l
      WHERE l.artifact_id = o.artifact_id AND l.status = 'available'
  );

-- Q5. Find running attempts and inspect temp/final path, receipt and output links.
SELECT p.attempt_id, p.request_id, p.stage, p.temp_path, p.final_path,
       p.receipt_json, o.artifact_id AS published_artifact
FROM processing_attempts p
LEFT JOIN processing_outputs o ON o.attempt_id = p.attempt_id
WHERE p.status = 'running';

-- Q6. Compare original calibration metadata with the reviewed configuration.
SELECT r.request_id, i.role,
       json_extract(f.raster_json, '$.scale') AS original_scale,
       json_extract(f.raster_json, '$.offset') AS original_offset,
       json_extract(r.normalized_json, '$.settings.scaling') AS scaling,
       json_extract(r.normalized_json, '$.settings.calibration.' || i.role) AS calibration
FROM processing_requests r
JOIN processing_inputs i ON i.request_id = r.request_id
JOIN processing_artifacts f ON f.artifact_id = i.artifact_id;
