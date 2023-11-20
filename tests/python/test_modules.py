
def test_modules():
    from packaging import version
    # Generic
    import igraph
    import imblearn
    import keras
    import nbgitpuller
    #import nbstripout        # not importable in tests/notebooks
    import networkx
    import nose
    #import pandas_datareader # currently broken
    import plotly
    import pystan
    import tables
    import sklearn
    import tensorflow
    assert version.parse(tensorflow.__version__) >= version.parse('2.0')
    import tensorflow_hub
    import torch
    assert version.parse(torch.__version__) >= version.parse('1.3.0')
    import torchvision
    assert version.parse(torchvision.__version__) >= version.parse('0.2.1')

    # Misc requested courses
    #import gpflow

    # BuiltEnv remote sensing course
    #import geopandas   # does not work at start of 2019.
    #import rasterio
    import folium

    # Bayes course
    import pystan

    # DSFB
    import pydotplus

    # DataSci
    import librosa

    # mlkern2019
    import cvxopt
    import cvxpy

    # Intro to AI
    import bcolz
    import tqdm

    # Introduction to Quantum Technologies, Matti Raasakka, RT#14866
    import qiskit

    # intcompmedia
    import pydub
    import cma

    # ai2020
    import ortools
