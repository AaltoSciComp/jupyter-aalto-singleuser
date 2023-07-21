ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root

RUN \
    /opt/conda/bin/pip install --no-cache-dir \
        jupyterhub==4.0.1 && \
    clean-layer.sh

USER ${NB_USER}
