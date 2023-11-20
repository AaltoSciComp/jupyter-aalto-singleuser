
def test_nbgrader_version():
    import nbgrader
    assert nbgrader.version_info == (0, 7, 0, 'dev')
    import nbgrader.nbgraderformat
    assert nbgrader.nbgraderformat.SCHEMA_VERSION == 3
