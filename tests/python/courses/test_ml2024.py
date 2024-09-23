def test_ml2024_versions():
    import tabulate
    from packaging import version
    import gym
    assert version.parse(gym.__version__) == version.parse('0.21.0')
