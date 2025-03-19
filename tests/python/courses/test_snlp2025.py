def test_stanza_version():
    import stanza
    from packaging import version
    assert version.parse(stanza.__version__) > version.parse("1.10")
    import umap
