
def test_modules():
    from packaging import version
    # Generic
    import igraph
    import imblearn
    import keras
    #import nbstripout        # not importable in tests/notebooks
    import networkx
    import nose
    #import pandas_datareader # currently broken
    import plotly
    import tables
    import sklearn
    import tensorflow
    assert version.parse(tensorflow.__version__) >= version.parse('2.0')
    import tensorflow_hub
    import torch
    assert version.parse(torch.__version__) >= version.parse('1.3.0')
    import torchvision
    assert version.parse(torchvision.__version__) >= version.parse('0.2.1')
    import torchtext
    assert version.parse(torchtext.__version__) >= version.parse('0.15.2')

    # Misc requested courses
    #import gpflow

    # BuiltEnv remote sensing course
    #import geopandas   # does not work at start of 2019.
    #import rasterio
    import folium

    # Bayes course
    import stan

    # DSFB
    import pydotplus

    # DataSci
    import librosa

    # mlkern2019
    import cvxopt
    import cvxpy

    # Intro to AI
    # import bcolz  # now unmaintained, python <3.7
    import tqdm

    # Introduction to Quantum Technologies, Matti Raasakka, RT#14866
    import qiskit

    # intcompmedia
    import pydub
    # import cma  # removed in 2021

    # ai2020
    import ortools
