
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
    # EOL since 2024-04: https://docs.pytorch.org/text/stable/index.html
    # import torchtext
    # assert version.parse(torchtext.__version__) >= version.parse('0.15.2')

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
    # Caused dependency conflicts, not installed
    # import ortools

    # mlca2024
    import openeo
    import imgaug
    import ipyleaflet
    # Failed to install because setup.py didn't recognise numpy, disabled
    # import fusets
    import eolearn
    # This import sometimes fails with a RecursionError related to enums,
    # disabiling for now
    #import sentinelhub

    # valueanalytics2024
    from openai import version as openai_version
    assert version.parse(openai_version.VERSION) >= version.parse("1.10.0")
    from openai import OpenAI

    # css2024
    import detoxify

    # gausproc2024
    import tensorflow_probability
    assert version.parse(tensorflow_probability.__version__) >= version.parse("0.22.0")
    import gpflow
    assert version.parse(gpflow.__version__) >= version.parse("2.9.0")

    # dbbb2024
    import vaderSentiment
    import niimpy
    import liwc

    # deeplearn2024
    import transformers
    assert version.parse(transformers.__version__) >= version.parse("4.46.0")

    # deeplearn2026, RT#30759
    import transformers
    import sentence_transformers
    import torch

    assert version.parse(transformers.__version__) >= version.parse("4.57.3")
    assert version.parse(torch.__version__) >= version.parse("2.9.1")
