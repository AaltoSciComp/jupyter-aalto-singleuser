ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root

ENV CC=clang CXX=clang++

# Make sure curl uses the correct system certificates from the ca-certificates
# package
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN echo Clear build cache 2026-08

RUN \
    apt-get update && \
    apt-get upgrade -y && \
    clean-layer.sh

# TODO: Remove this when upgrading base to jupyterlab>=4 and jupyter_server>=2
RUN \
    /opt/conda/bin/pip uninstall jupyter_server_terminals -y && \
    clean-layer.sh

# ========================================

RUN \
    /opt/conda/bin/pip install --no-cache-dir uv && \
    clean-layer.sh

ENV UV_ENV_NAME=elec-e8125-rl2026
COPY environments/ /opt/environments/

# TODO: remove when rebuilding with base >v6.8
COPY --chmod=0755 scripts/clean-layer.sh /usr/local/bin/

# rl2026, RT#33032
RUN \
    cd /opt/environments/${UV_ENV_NAME} && \
    export UV_PYTHON_INSTALL_DIR=/opt/uv-python && \
    /opt/conda/bin/uv venv && \
    /opt/conda/bin/uv pip install -r pyproject.toml && \
    clean-layer.sh

ENV PATH=/opt/environments/${UV_ENV_NAME}/.venv/bin:/opt/uv-python/bin:${PATH}
RUN \
    /opt/environments/${UV_ENV_NAME}/.venv/bin/python \
        -m ipykernel install \
        # using the default name to intentionally mask the base conda environment kernel
        --name python3 \
        --prefix=/opt/conda \
        --display-name="Python 3.12 (${UV_ENV_NAME})" && \
    echo "import os ; os.environ['PATH'] = '/opt/environments/${UV_ENV_NAME}/.venv/bin:'+os.environ['PATH']" \
        >> /etc/jupyter/jupyter_notebook_config.py && \
    echo "import os ; os.environ['PATH'] = '/opt/environments/${UV_ENV_NAME}/.venv/bin:'+os.environ['PATH']" \
        >> /etc/jupyter/jupyter_server_config.py && \
    clean-layer.sh

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

#
# TODO: Last-added packages, move to builder when doing a full rebuild
#
# # coursecode, RT#00000
# RUN \
#     apt-get update && apt-get install -y --no-install-recommends \
#         packagename \
#         && \
#     /opt/software/bin/mamba install -p /opt/software -y --freeze-installed \
#         packagename \
#         && \
#     /opt/software/bin/pip install --no-cache-dir \
#         packagename \
#         && \
#     clean-layer.sh

# Uncomment when nbgrader needs to be updated
# RUN \
#     # Use the full path to pip to be more explicit about which environment
#     # we're installing to
#     /opt/conda/bin/pip uninstall nbgrader -y && \
#     /opt/conda/bin/pip install --no-cache-dir \
#         git+https://github.com/AaltoSciComp/nbgrader@v0.8.4+aalto7 && \
#     clean-layer.sh

# ========================================

# Duplicate of base, but hooks and patches can update frequently and are small,
# so they're applied again here.
COPY --chmod=0755 hooks/ scripts/ /usr/local/bin/

COPY patches/ /tmp/patches/
RUN \
    cd / && \
    for patch in /tmp/patches/*.diff; do \
        echo $patch && \
        output=$(patch --reject-file=- --forward -p0 -u < $patch) || ret=$? \
        # If the patch fails, check if it has been applied previously (in base
        # image), otherqise exit with the error code
        echo $output | grep "previously applied" || exit $ret ; \
    done

# Save version information within the image
ARG IMAGE_VERSION
ARG BASE_IMAGE
ARG JUPYTER_SOFTWARE_IMAGE
ARG GIT_DESCRIBE
RUN \
    truncate --size 0 /etc/cs-jupyter-release && \
    echo IMAGE_VERSION=${IMAGE_VERSION} >> /etc/cs-jupyter-release && \
    echo BASE_IMAGE=${BASE_IMAGE} >> /etc/cs-jupyter-release && \
    echo JUPYTER_SOFTWARE_VERSION=${UV_ENV_NAME} >> /etc/cs-jupyter-release && \
    echo GIT_DESCRIBE=${GIT_DESCRIBE} >> /etc/cs-jupyter-release


USER $NB_UID
