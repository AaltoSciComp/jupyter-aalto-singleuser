def test_opencv_import():
    import cv2


def test_opencv_sift():
    import cv2

    sift = cv2.SIFT_create()
    assert sift is not None
