def test_opencv_import():
    import cv2


def test_opencv_version():
    import cv2
    from packaging import version

    assert version.parse(cv2.__version__) >= version.parse("4.8.0")


def test_opencv_sift():
    import cv2

    sift = cv2.SIFT_create()
    assert sift is not None


def test_opencv_surf():
    import cv2

    surf = cv2.xfeatures2d.SURF_create()
    assert surf is not None


def test_pyflann():
    import pyflann
