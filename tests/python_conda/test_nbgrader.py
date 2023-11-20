
def test_nbgrader_version():
    from packaging import version
    import nbgrader
    assert version.parse(nbgrader.__version__) >= version.parse("0.8.4")
    import nbgrader.nbgraderformat
    assert nbgrader.nbgraderformat.SCHEMA_VERSION == 3
