import numpy as np
from eo_processing.products import ProductResult, normalized_difference


class NDMI:
    name = 'ndmi'
    version = '1.0.0'
    required_bands = ('nir', 'swir16')
    output_roles = ('index',)
    primary_role = 'index'
    nominal_range = (-1.0, 1.0)
    default_parameters = {'epsilon': 0.000001, 'threshold': 0.2}

    def calculate(self, bands, valid, parameters, pixel_area_m2):
        index = normalized_difference(bands['nir'], bands['swir16'], parameters['epsilon'])
        index[~valid] = np.nan
        observed = np.isfinite(index)
        return ProductResult({'index': index}, {
            'mean_ndmi': float(index[observed].mean()) if observed.any() else None,
            'observed_area_m2': float(observed.sum() * pixel_area_m2),
            'above_threshold_area_m2': float(np.count_nonzero(observed & (index > parameters['threshold'])) * pixel_area_m2),
            'threshold': parameters['threshold'],
        })


PRODUCT = NDMI()
