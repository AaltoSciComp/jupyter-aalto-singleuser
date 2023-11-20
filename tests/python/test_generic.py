import os

def test_utilities():
    assert os.system('nbstripout --version') == 0
    assert os.system('nbdime --version') >> 8 == 1

