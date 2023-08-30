import pytest

def test_imports():
    import skopt
    import lightgbm
    import catboost
    import missingno

def test_scikit_optimize():
    import numpy as np
    from skopt import gp_minimize

    np.random.seed(123)

    def f(x):
        return np.sin(5 * x[0]) * (1 - np.tanh(x[0] ** 2)) * np.random.randn() * 0.1

    res = gp_minimize(f, [(-2.0, 2.0)], n_calls=20)
    assert pytest.approx(res.x[0], 0.01) == 0.85
    assert pytest.approx(res.fun, 0.01) == -0.06
