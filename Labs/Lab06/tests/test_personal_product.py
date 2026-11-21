from pathlib import Path
import numpy as np
from eo_processing.cli import demo
from eo_processing.common import read_json
from eo_processing import database as db
from eo_processing.planning import find_inputs, DEFAULT_PREPARATION
from eo_processing.preparation import prepare
from eo_processing.products import load_product


def test_personal_ndmi_real_pixels_and_unknowns(tmp_path):
    workspace = tmp_path / 'demo'
    demo(workspace)
    job = read_json(workspace / 'batch_config.json')['jobs'][2]
    product, _ = load_product('ndmi', Path(__file__).parents[1] / 'extensions/my_product.py')
    with db.connect(workspace / 'catalogue.sqlite') as connection:
        records = find_inputs(connection, job, ('nir', 'swir16', 'scl'))
        paths = {role: db.location(connection, record['artifact_id']) for role, record in records.items()}
    bands, valid, _, _, metrics = prepare(records, paths, DEFAULT_PREPARATION, product.required_bands)
    original = {role: values.copy() for role, values in bands.items()}
    result = product.calculate(bands, valid, product.default_parameters, metrics['pixel_area_m2'])
    output = result.layers['index']
    pixels = np.argwhere(np.isfinite(output))[:3]
    assert len(pixels) == 3
    for row, col in pixels:
        nir, swir = float(bands['nir'][row, col]), float(bands['swir16'][row, col])
        expected = (nir - swir) / (nir + swir)
        assert np.isclose(output[row, col], expected, atol=1e-6)
    assert np.isnan(output[~valid]).all()
    assert all(np.array_equal(bands[role], original[role], equal_nan=True) for role in bands)
    empty = product.calculate(bands, np.zeros_like(valid), product.default_parameters, 400)
    assert np.isnan(empty.layers['index']).all()
    assert empty.metrics['mean_ndmi'] is None
    assert empty.metrics['above_threshold_area_m2'] == 0
