import re
import subprocess


ESC="\x1b["
GREEN=f"{ESC}32m"
RED=f"{ESC}31m"
RESET=f"{ESC}0m"

red_x = f"{RED} X"

def test_labextensions():
    result = subprocess.run(['/opt/conda/bin/jupyter', 'labextension', 'list'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert result.returncode == 0
    output = result.stderr.decode('utf-8')
    assert red_x not in output
