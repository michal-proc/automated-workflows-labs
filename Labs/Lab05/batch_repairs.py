def classify_member(context):
    if context['active_attempt']:
        return {'state': 'unresolved', 'reason': 'Execution is still recorded as active'}
    if context['verified_result']:
        return {'state': 'complete', 'reason': 'Output verified'}
    if context['validation_error']:
        return {'state': 'failed', 'reason': context['validation_error']}
    if context['missing_inputs']:
        return {'state': 'blocked', 'reason': 'Missing inputs: ' + ', '.join(context['missing_inputs'])}
    if context['last_attempt'] and context['last_attempt']['status'] == 'failed':
        return {'state': 'failed', 'reason': 'Investigate the failed application attempt'}
    if context['attempts_used'] >= context['max_attempts']:
        return {'state': 'failed', 'reason': 'Attempt budget exhausted'}
    return {'state': 'ready', 'reason': 'Inputs verified and attempt budget available'}


def verify_result(member, evidence):
    return (
        bool(member.get('request_id'))
        and evidence.get('request_id') == member['request_id']
        and all(isinstance(evidence.get(key), str) and evidence[key].strip()
                for key in ('attempt_id', 'artifact_id', 'sha256', 'actual_sha256'))
        and len(evidence['sha256']) == 64
        and evidence['sha256'] == evidence['actual_sha256']
        and type(evidence.get('size_bytes')) is int
        and evidence['size_bytes'] > 0
        and type(evidence.get('actual_size_bytes')) is int
        and evidence['size_bytes'] == evidence['actual_size_bytes']
        and all(evidence.get(key) is True for key in
                ('catalogue_link_verified', 'grid_verified', 'provenance_verified'))
    )


def summarize_batch(rows):
    latest = {}
    for row in rows:
        member = row['member_id']
        if member not in latest or row['observation_id'] > latest[member]['observation_id']:
            latest[member] = row
    members = {s: [] for s in ('ready', 'complete', 'blocked', 'unresolved', 'failed', 'unobserved')}
    for member, row in sorted(latest.items()):
        members[row['state'] or 'unobserved'].append(member)
    return {'expected': len(latest), 'counts': {s: len(ids) for s, ids in members.items()}, 'members': members}
