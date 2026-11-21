SELECT m.member_id, m.planned_request_id
FROM batch_members m
WHERE m.batch_id = :batch_id
  AND NOT EXISTS (
      SELECT 1 FROM processing_attempts a WHERE a.request_id = m.planned_request_id
  )
ORDER BY m.member_id;

SELECT DISTINCT m.member_id, earlier.request_id,
       earlier.attempt_id AS earlier_attempt, earlier.status AS earlier_status,
       later.attempt_id AS producing_attempt, o.artifact_id
FROM batch_members m
JOIN processing_attempts earlier ON earlier.request_id = m.planned_request_id
JOIN processing_attempts later ON later.request_id = earlier.request_id
JOIN processing_outputs o ON o.attempt_id = later.attempt_id AND o.role = 'ndvi'
JOIN batch_observations verified ON verified.batch_id = m.batch_id
    AND verified.member_id = m.member_id AND verified.attempt_id = later.attempt_id
    AND verified.state = 'complete'
WHERE m.batch_id = :batch_id AND earlier.status IN ('failed', 'interrupted')
  AND later.status = 'succeeded' AND later.started_at > earlier.started_at;

SELECT m.member_id, a.attempt_id, o.artifact_id
FROM batch_members m
JOIN processing_attempts a ON a.request_id = m.planned_request_id
JOIN processing_outputs o ON o.attempt_id = a.attempt_id AND o.role = 'ndvi'
WHERE m.batch_id = :batch_id AND a.status = 'succeeded'
  AND NOT EXISTS (
      SELECT 1 FROM processing_artifact_locations l
      WHERE l.artifact_id = o.artifact_id AND l.status = 'available'
  );

SELECT m.member_id, o.state, o.observed_at
FROM batch_members m
LEFT JOIN batch_observations o ON o.batch_id = m.batch_id AND o.member_id = m.member_id
    AND o.observation_id = (
        SELECT MAX(x.observation_id) FROM batch_observations x
        WHERE x.batch_id = m.batch_id AND x.member_id = m.member_id
    )
WHERE m.batch_id = :batch_id AND (o.observed_at IS NULL OR o.observed_at < :before)
ORDER BY m.member_id;

SELECT m.member_id, json_extract(input.value, '$.role') AS role,
       l.local_path, l.status, latest.reason
FROM batch_members m
JOIN batch_observations latest ON latest.batch_id = m.batch_id AND latest.member_id = m.member_id
    AND latest.observation_id = (
        SELECT MAX(x.observation_id) FROM batch_observations x
        WHERE x.batch_id = m.batch_id AND x.member_id = m.member_id
    )
JOIN json_each(m.spec_json, '$.inputs') input
JOIN processing_artifact_locations l ON l.artifact_id = json_extract(input.value, '$.artifact_id')
WHERE m.batch_id = :batch_id AND latest.state = 'blocked' AND l.status != 'available';
