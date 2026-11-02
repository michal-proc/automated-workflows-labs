"""Three plausible implementations to investigate and repair. No syntax puzzles."""
import hashlib
import json
import numpy as np

def make_request_spec(science, inputs, environment, runtime):
    """Identify the calculation and its environment independently of storage paths."""
    def normalize(value):
        if isinstance(value, dict):
            return {key: normalize(item) for key, item in value.items()}
        if isinstance(value, list):
            return [normalize(item) for item in value]
        if isinstance(value, float) and value.is_integer():
            return int(value)
        return value

    fields = ('artifact_id', 'sha256', 'size_bytes', 'raster', 'lineage')
    spec = normalize({
        'equivalence_policy': 'exact_environment_v1',
        'stage': science['stage'],
        'settings': science,
        'inputs': [
            {'role': role, **{key: inputs[role][key] for key in fields}}
            for role in ('red', 'nir')
        ],
        'environment': environment,
    })
    canonical = json.dumps(spec, sort_keys=True, separators=(',', ':'), allow_nan=False)
    fingerprint = hashlib.sha256(canonical.encode('utf-8')).hexdigest()
    return spec, fingerprint

def validate_pair(red, nir):
    """Raise ValueError if metadata cannot justify a red/NIR calculation."""
    for role, record in (('red', red), ('nir', nir)):
        if record['lineage']['asset_key'] != role:
            raise ValueError(f'Expected {role} band')
        meta = record['raster']
        for key in ('scale', 'offset', 'nodata'):
            value = meta[key]
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not np.isfinite(value):
                raise ValueError(f'{role}: {key} must be a finite number')
        if meta['scale'] <= 0:
            raise ValueError(f'{role}: scale must be positive')
    for key in ('collection', 'item_id', 'aoi_key', 'aoi', 'recipe_version'):
        if red['lineage'][key] != nir['lineage'][key]:
            raise ValueError(f'Input {key} differs')
    for key in ('crs', 'shape', 'transform'):
        if red['raster'][key] != nir['raster'][key]:
            raise ValueError(f'Input {key} differs')

def calculate_ndvi(red, nir, red_meta, nir_meta, epsilon):
    """Return float32 NDVI; invalid pixels must be NaN. Inputs are stored DN."""
    if red.shape != nir.shape:
        raise ValueError('Input shapes differ')
    if not np.isfinite(epsilon) or epsilon < 0:
        raise ValueError('Denominator threshold must be finite and nonnegative')
    valid = (red != red_meta['nodata']) & (nir != nir_meta['nodata'])
    r = red.astype('float64') * red_meta['scale'] + red_meta['offset']
    n = nir.astype('float64') * nir_meta['scale'] + nir_meta['offset']
    denominator = n + r
    valid &= np.isfinite(r) & np.isfinite(n) & np.isfinite(denominator)
    valid &= np.abs(denominator) > epsilon
    result = np.full(red.shape, np.nan, dtype='float32')
    result[valid] = (n[valid] - r[valid]) / denominator[valid]
    return result
