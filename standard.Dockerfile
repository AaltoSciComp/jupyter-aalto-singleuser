ARG VER_BASE
FROM aaltoscienceit/notebook-server-base:${VER_BASE}

USER root

ARG ENVIRONMENT_NAME
ARG ENVIRONMENT_VERSION
ARG ENVIRONMENT_HASH
ENV JUPYTER_SOFTWARE_IMAGE=${ENVIRONMENT_NAME}_${ENVIRONMENT_VERSION}_${ENVIRONMENT_HASH}

# NOTE: files contained in the tar archive must have gid=100 and file mode g=rw
#       if the user is supposed to be able to use `mamba install` on the base
#       environment when running the image
ADD conda/${JUPYTER_SOFTWARE_IMAGE}.tar.gz /opt/software
RUN chown --reference=/opt/software/environment.yml /opt/software && \
    chmod g+rw /opt/software

# NOTE: Running this would massively inflate the image size, permissions should
#       be set correctly when creating the archive, or we should mount the
#       archive and exctract manually. Currently fixed using make
# RUN fix-permissions /opt/software

# TODO: Move the scripts to the base image when updating
COPY scripts/tar-patch /usr/local/bin
COPY scripts/update-software.sh /usr/local/bin

# Incremental updates to the software stack:
COPY delta_560c880a-aaa369e3.tardiff /tmp/delta.tardiff
RUN /usr/local/bin/update-software.sh /tmp/delta.tardiff
# The delta file was generated using the following command:
#   tar-diff /m/scicomp/software/anaconda-ci/aalto-jupyter-anaconda/packs/jupyter-generic_2022-03-07_{560c880a,aaa369e3}.tar.gz delta_560c880a-aaa369e3.tardiff

# requires bdaaccounting collection in the builder
RUN \
    echo [FreeTDS] >> /etc/odbcinst.ini && \
    echo Description=FreeTDS Driver >> /etc/odbcinst.ini && \
    echo Driver=/opt/software/lib/libtdsodbc.so >> /etc/odbcinst.ini && \
    echo Setup=/opt/software/lib/libtdsS.so >> /etc/odbcinst.ini

# ========================================

RUN /opt/software/bin/python -m ipykernel install --prefix=/opt/conda --display-name="Python 3"

ENV CC=clang CXX=clang++

RUN echo "import os ; os.environ['PATH'] = '/opt/software/bin:'+os.environ['PATH']" >> /etc/jupyter/jupyter_notebook_config.py
RUN echo "import os ; os.environ['PATH'] = '/opt/software/bin:'+os.environ['PATH']" >> /etc/jupyter/jupyter_server_config.py

ENV PATH=/opt/software/bin:${PATH}
ENV CONDA_DIR=/opt/software

ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

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

# Update nbgrader
RUN \
    # TODO: remove this limitation when the base image contains a recent enough
    # node
    /opt/conda/bin/mamba install 'nodejs>=16,<18' && \
    /opt/conda/bin/pip uninstall nbgrader -y && \
    /opt/conda/bin/pip install --no-cache-dir \
        git+https://github.com/AaltoSciComp/nbgrader@dev-2023-3#egg=nbgrader==0.8.1.dev802 && \
    /opt/conda/bin/jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    clean-layer.sh


RUN \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        && \
    /opt/software/bin/mamba install -y --freeze-installed \
        # dlpython2022, RT#22328
        jsonpickle \
        # css2023, RT#23019
        transformers \
        # Updating jupyter_client to fix autograding timeout
        'jupyter_client>7.1.2,<8' \
        # dhhb2022, RT#22440
        vaderSentiment \
        # hona2023-brain, RT#22805
        nilearn \
        nibabel \
        # gausproc2023, RT#23193
        'tensorflow-cpu>=2.8' \
        # bdaaccounting2023
        statsforecast \
        # RT#23949
        sage \
        && \
    pip install --no-cache-dir \
        # dhhb2022, RT#22440
        liwc \
        # deeplearn2023, RT#22643
        einops \
        'certifi>2021.10.8' \
        # css2023, RT#23164
        'networkx>=2.8.8,<3' \
        # css2023, RT#23260
        Wikipedia-API \
        && \
    clean-layer.sh

# ========================================

# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.d
RUN chmod a+rx /usr/local/bin/*.sh /usr/local/bin/*/*.sh

# Save version information within the image
ARG VER_STD
RUN echo IMAGE_VERSION=${VER_STD} >> /etc/cs-jupyter-release && \
    echo JUPYTER_SOFTWARE_IMAGE=${JUPYTER_SOFTWARE_IMAGE} >> /etc/cs-jupyter-release

USER $NB_UID
