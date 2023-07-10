ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root

# Create software environment.
COPY environment.yml /opt/environment.yml
RUN \
    /opt/conda/bin/conda config --system --set channel_priority flexible && \
    /opt/conda/bin/mamba env create \
        -f /opt/environment.yml \
        -p /opt/software && \
    /opt/conda/bin/conda config --system --set channel_priority strict && \
    clean-layer.sh

# ========================================

RUN \
    # The software package that's imported as a tar includes an incorrect
    # condarc file, using a modified version of the jupyter default instead
    echo -n > /opt/software/.condarc && \
    /opt/software/bin/conda config --system --append channels conda-forge && \
    /opt/software/bin/conda config --system --append channels defaults && \
    /opt/software/bin/conda config --system --set auto_update_conda false && \
    /opt/software/bin/conda config --system --set show_channel_urls true && \
    /opt/software/bin/conda config --system --set channel_priority flexible && \
    /opt/software/bin/conda config --system --set ssl_verify /etc/ssl/certs/ca-certificates.crt && \
    /opt/software/bin/conda config --system --set allow_softlinks false

# ========================================

RUN /opt/software/bin/python -m ipykernel install --prefix=/opt/conda --display-name="Python 3"

ENV CC=clang CXX=clang++

RUN echo "import os ; os.environ['PATH'] = '/opt/software/bin:'+os.environ['PATH']" >> /etc/jupyter/jupyter_notebook_config.py
RUN echo "import os ; os.environ['PATH'] = '/opt/software/bin:'+os.environ['PATH']" >> /etc/jupyter/jupyter_server_config.py

ENV PATH=/opt/software/bin:${PATH}
ENV CONDA_DIR=/opt/software
# Make sure curl uses the correct system certificates from the ca-certificates
# package
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# ========================================

# requires bdaaccounting collection in the builder
RUN \
    echo [FreeTDS] >> /etc/odbcinst.ini && \
    echo Description=FreeTDS Driver >> /etc/odbcinst.ini && \
    echo Driver=/opt/software/lib/libtdsodbc.so >> /etc/odbcinst.ini && \
    echo Setup=/opt/software/lib/libtdsS.so >> /etc/odbcinst.ini

# ========================================

# Uncomment when ca-certificates requires an update
# RUN \
#     apt-get update && apt-get install -y --no-install-recommends \
#         ca-certificates \
#         && \
#     pip install --no-cache-dir \
#         'certifi>2021.10.8' \
#         && \
#     clean-layer.sh

# ========================================

RUN \
    # Already installed to /opt/conda, but needs to also exist in /opt/software
    /opt/software/bin/python -m bash_kernel.install --sys-prefix && \
    clean-layer.sh

#
# TODO: Last-added packages, move to builder when doing a full rebuild
#
# # coursecode, RT#00000
# RUN \
#     apt-get update && apt-get install -y --no-install-recommends \
#         packagename \
#         && \
#     /opt/software/bin/mamba install -y --freeze-installed \
#         packagename \
#         && \
#     pip install --no-cache-dir \
#         packagename \
#         && \
#     clean-layer.sh

# Install/update nbgrader
# RUN \
#     # Use the full path to pip to be more explicit about which environment
#     # we're installing to
#     /opt/conda/bin/pip uninstall nbgrader -y && \
#     /opt/conda/bin/pip install --no-cache-dir \
#         git+https://github.com/AaltoSciComp/nbgrader@v0.8.2.dev500 && \
#     jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
#     clean-layer.sh

# ========================================

# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.d
RUN chmod a+rx /usr/local/bin/*.sh /usr/local/bin/*/*.sh

# Save version information within the image
ARG VER_STD
ARG JUPYTER_SOFTWARE_IMAGE
RUN echo IMAGE_VERSION=${VER_STD} >> /etc/cs-jupyter-release && \
    prefix=$(grep prefix: /opt/environment.yml | cut -d' ' -f2) && \
    echo JUPYTER_SOFTWARE_VERSION=${prefix} >> /etc/cs-jupyter-release

USER $NB_UID
