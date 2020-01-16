ARG VER_BASE
FROM aaltoscienceit/notebook-server-base:${VER_BASE}

USER root

RUN echo "tensorflow 2.0.*"                  >> /opt/conda/conda-meta/pinned && \
    echo "#tensorflow-tensorboard 1.5.*"     >> /opt/conda/conda-meta/pinned && \
    echo "keras 2.3.*"                       >> /opt/conda/conda-meta/pinned && \
    echo "pytorch 1.3.*"                     >> /opt/conda/conda-meta/pinned && \
    echo "torchvision 0.4.*"                 >> /opt/conda/conda-meta/pinned && \
    clean-layer.sh




# Custom installations
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#           ... \
#           && \
#    clean-layer.sh


# Custom installations
# arviz: bayesian data analysis
# cma: ??
# folium: BE remote sensing course
# geopandas: BE remote sensing course
# igraph: complex networks (general)
# keras: general use (for gpu, keras-gpu)
# librarosa: datasci2018
# networkx: complex networks (general)
# nose: mlbp2018
# plotchecker: for nbgrader, mlbp2018
# plotly: student request
# pydotplus - dsfb2018 instructor request
# pydub: ???
# pytorch: general use
# pystan: general use, bayes course (updated prompt_toolkit needed as dependency)
# rasterio: BE remote sensing course
# scikit-learn: mlbp2018
# tensorflow, tensorflow-tensorboard (general use)
# cvxopt       - mlkern2019
# nbstripout   - generic package
# nltk         -  datasci2019  (use conda  when upgrading)
# lapack       - dependency for cvxpy
# cvxpy        - mlkern2019
# gpflow       - special course Gaussian Processes, 2019 (pinned to 2.0.0rc1 to force tf2.0 compat)
# bcolz        - introai2019
# tqdm         - introai2019
# qiskit       - Introduction to Quantum Technologies, Matti Raasakka, RT#14866
# wordcloud - datasci2019
# geopy - datasci2019
# imbalanced-learn (student request)
# opencv: mlpython
RUN \
    conda config --add channels conda-forge && \
    conda install \
        networkx \
        nose \
        pandas-datareader \
        plotly \
        pydotplus \
        scikit-learn \
        arviz \
        folium \
        python-igraph \
        feather-format \
        librosa \
        bcolz \
        tqdm \
        wordcloud \
        geopy \
        rasterio \
        geopandas \
        lapack \
        mlxtend \
        scikit-plot \
        imbalanced-learn \
        nltk \
        opencv \
        && \
    pip install --no-cache-dir \
        plotchecker \
        gpflow==2.0.0rc1 \
        calysto \
        cma \
        cvxopt \
        cvxpy \
        metakernel \
        pydub \
        qiskit \
        && \
    clean-layer.sh
# Currently non-functional packages:
#   geopandas (conda-forge)
#   rasterio (conda-forge)

## TODO: Combine layers
    # Installing from pip because the tensorflow and tensorboard versions found
    # from the anaconda repos don't support python 3.7 yet
RUN \
    conda install --freeze-installed \
        keras \
        pystan prompt_toolkit \
        && \
    pip install --no-cache-dir \
        tensorflow==2.0.0 \
        tensorboard \
        tensorflow-hub \
        && \
    clean-layer.sh
RUN conda install --freeze-installed -c pytorch \
        pytorch \
        torchvision \
        && \
    clean-layer.sh

# owslib: mlpython
RUN \
    conda install --freeze-installed \
        owslib \
        && \
    clean-layer.sh

RUN pip install --no-cache-dir \
        geoplotlib \
        ipympl \
        && \
    jupyter labextension install \
        jupyter-matplotlib \
        && \
    clean-layer.sh

#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#           ... \
#           && \
#    clean-layer.sh

# Fix nbgrader permissions problem
RUN \
    sed -i "s@assert '0600' ==.*@assert stat.S_IMODE(os.stat(fname).st_mode) \& 0o77 == 0@" /opt/conda/lib/python3.7/site-packages/jupyter_client/connect.py

ENV CC=clang CXX=clang++


# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*.sh

USER $NB_UID
