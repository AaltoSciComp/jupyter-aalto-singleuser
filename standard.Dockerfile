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

# Custom installations
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#           ... \
#           && \
#    clean-layer.sh

# Update nbgrader
RUN \
    pip uninstall nbgrader -y && \
    pip install --no-cache-dir \
        git+https://github.com/AaltoSciComp/nbgrader@live-2022#egg=nbgrader==0.7.0-dev3+aalto && \
    jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    clean-layer.sh

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

# ========================================

# dlpython2022, RT#22328
RUN \
    /opt/software/bin/mamba install -y --freeze-installed \
        jsonpickle \
        && \
    clean-layer.sh

# dhhb2022, RT#22440
RUN \
    /opt/software/bin/mamba install -y --freeze-installed -c conda-forge \
        vaderSentiment \
        && \
    pip install --no-cache-dir \
        liwc \
        && \
    clean-layer.sh

# deeplearn2023, RT#22643
RUN \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        && \
    pip install --no-cache-dir \
        einops \
        'certifi>2021.10.8' \
        && \
    clean-layer.sh

ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# ========================================

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

# css2023, RT#23019
RUN \
    /opt/software/bin/mamba install -y --freeze-installed \
        transformers \
        && \
    clean-layer.sh

# hona2023-brain, RT#22805
RUN \
    /opt/software/bin/mamba install -y --freeze-installed -c conda-forge\
        nilearn \
        nibabel \
        && \
    clean-layer.sh

# css2023, RT#23164
RUN \
    /opt/software/bin/pip install \
        'networkx==2.8.8' \
        && \
    clean-layer.sh

# gausproc2023, RT#23193
# This creates a 4GB layer because a lot of packages are updated, but
# couldn't figure out a more efficient way
RUN \
    /opt/software/bin/mamba install -y -c conda-forge\
        'tensorflow-cpu>=2.8' \
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
