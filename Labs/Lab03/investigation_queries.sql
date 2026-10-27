SELECT r.run_id,r.command,a.item_id,a.asset_key,s.aoi_key,d.status,d.stage,
       d.network_bytes,d.http_status,d.error_code,d.error_message
FROM download_attempts d JOIN runs r ON r.run_id=d.run_id
JOIN subset_requests s ON s.subset_id=d.subset_id
JOIN assets a ON a.asset_id=s.asset_id
ORDER BY d.started_at,d.attempt_id;

SELECT r.run_id,r.status AS run_status,a.asset_key,d.status,d.stage,
       d.network_bytes,d.error_code,d.artifact_id,f.sha256
FROM download_attempts d JOIN runs r USING(run_id)
JOIN subset_requests s USING(subset_id) JOIN assets a USING(asset_id)
LEFT JOIN artifacts f ON f.artifact_id=d.artifact_id
ORDER BY d.started_at,d.attempt_id;

SELECT a.asset_key,d.status AS attempt_status,d.stage,d.error_code,
       f.artifact_id,f.sha256,f.size_bytes,l.local_path,l.status AS location_status
FROM download_attempts d JOIN subset_requests s USING(subset_id)
JOIN assets a USING(asset_id)
LEFT JOIN artifacts f ON f.artifact_id=d.artifact_id
LEFT JOIN artifact_locations l ON l.artifact_id=f.artifact_id
ORDER BY d.started_at,d.attempt_id;

SELECT a.asset_id,a.asset_key,s.subset_id,s.aoi_key,s.aoi_json,
       s.latest_artifact_id,l.local_path,l.status
FROM assets a JOIN subset_requests s USING(asset_id)
LEFT JOIN artifact_locations l ON l.artifact_id=s.latest_artifact_id
ORDER BY a.asset_id,s.aoi_key;
