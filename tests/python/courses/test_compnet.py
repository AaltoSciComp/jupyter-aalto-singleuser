def test_networkx_version():
    import networkx
    from packaging import version
    assert version.parse(networkx.__version__) > version.parse("3")
