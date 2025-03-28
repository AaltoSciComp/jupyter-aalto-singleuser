ARG UPSTREAM_MINIMAL_NOTEBOOK_VER
FROM jupyter/minimal-notebook:${UPSTREAM_MINIMAL_NOTEBOOK_VER}

USER root

COPY --chmod=0755 scripts/clean-layer.sh /usr/local/bin/
# Prevent fix-permissions from touching targets of links again and again
RUN sed -i 's/-exec chgrp/-exec chgrp -h/' /usr/local/bin/fix-permissions

## Apt packages
# Some of these are copied from the scipy-notebook Dockerfile
# See https://github.com/jupyter/docker-stacks/blob/main/scipy-notebook/Dockerfile
#
# inkscape: for exporting notebooks containing SVGs using nbconvert
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # for cython: https://cython.readthedocs.io/en/latest/src/quickstart/install.html
        # and general use
        build-essential \
        # for latex labels
        cm-super \
        dvipng \
        # for matplotlib anim
        ffmpeg \
        # misc
        clang \
        ed \
        file \
        git-annex \
        git-lfs \
        git-svn \
        graphviz \
        gzip \
        less \
        lsb-release \
        man-db \
        psmisc \
        vim \
        ncdu \
        quota \
        zip \
        inkscape \
        && \
    clean-layer.sh

#RUN touch /.nbgrader.log && chmod 777 /.nbgrader.log
# sed -r -i 's/^(UMASK.*)022/\1002/' /etc/login.defs

# JupyterHub says we can use any existing jupyter image, as long as we properly
# pin the JupyterHub version
# https://github.com/jupyterhub/jupyterhub/tree/master/singleuser

# # NOTE: Upstream image contains a newer version of JupyterHub but the
# #       jupyterhub-cs image is still on v1.4.2. Upgrading to >v2 requires
# #       a database migration.
# RUN mamba install -y 'jupyterhub>=1.4.2,<2' && \
#     clean-layer.sh

# Custom extension installations
#   importnb allows pytest to test ipynb
RUN \
    conda config --system --set channel_priority strict && \
    mamba install -y \
        bash_kernel \
        conda-tree \
        importnb \
        inotify_simple \
        ipywidgets \
        # TODO: replace with https://jupyterlab-contrib.github.io/migrate_from_classical.html
        #       when switching to JupyterLab for good
        # jupyter_contrib_nbextensions \
        nbval \
        pipdeptree \
        pytest \
        voila \
        && \
    # jupyter contrib nbextension install --sys-prefix && \
    python -m bash_kernel.install --sys-prefix && \
    ln -s /notebooks /home/jovyan/notebooks && \
    rm --dir /home/jovyan/work && \
    clean-layer.sh

RUN \
    mamba install -y \
        jupyterlab-git \
        nbdime \
        nbgitpuller \
        nbstripout \
        && \
    pip install --no-cache-dir \
        envkernel \
        && \
    jupyter labextension install \
        @jupyter-widgets/jupyterlab-manager \
        @jupyterlab/git \
        # Incompatible with jupyterlab 3.*
        # @fissio/hub-top-buttons \
        nbdime-jupyterlab \
        # https://github.com/lckr/jupyterlab-variableInspector/issues/232
        #@lckr/jupyterlab_variableinspector \
        jupyter-matplotlib \
        && \
    nbdime config-git --enable --system && \
    jupyter serverextension enable nbgitpuller --sys-prefix && \
    git config --system core.editor nano && \
    clean-layer.sh

# Nbgrader
RUN \
    pip install --no-cache-dir \
        git+https://github.com/AaltoSciComp/nbgrader@v0.8.4.dev505 && \
    # jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    # jupyter nbextension enable --sys-prefix --py nbgrader && \
    jupyter serverextension enable --sys-prefix --py nbgrader && \
    \
    # jupyter nbextension disable --sys-prefix formgrader/main --section=tree && \
    jupyter serverextension disable --sys-prefix nbgrader.server_extensions.formgrader && \
    jupyter labextension disable --level=sys_prefix --no-build nbgrader/formgrader && \
    \
    # jupyter nbextension disable --sys-prefix create_assignment/main && \
    jupyter labextension disable --level=sys_prefix --no-build nbgrader/create-assignment && \
    \
    # jupyter nbextension disable --sys-prefix course_list/main --section=tree && \
    jupyter serverextension disable --sys-prefix nbgrader.server_extensions.course_list && \
    jupyter labextension disable --level=sys_prefix --no-build nbgrader/course-list && \
    clean-layer.sh

# RUN \
#     # jupyter_lsp gets installed as a dependency but it doesn't work with the
#     # legacy notebook interface. Should be enabled again after migrating to
#     # jupyter-server.
#     # https://github.com/jupyter-lsp/jupyterlab-lsp/issues/943
#     jupyter serverextension disable jupyter_lsp && \
#     clean-layer.sh

RUN \
    jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Hooks, scripts, and patches are also copied and applied at the end of other
# Dockerfiles because they might update frequently
COPY --chmod=0755 hooks/ scripts/ /usr/local/bin/

COPY patches/ /tmp/patches/
RUN \
    cd / && \
    for patch in /tmp/patches/*; do \
        echo $patch && \
        patch -p0 -u < $patch; \
    done

    # Save version information within the image
ARG IMAGE_VERSION
ARG UPSTREAM_MINIMAL_NOTEBOOK_VER
ARG GIT_DESCRIBE
RUN \
    truncate --size 0 /etc/cs-jupyter-release && \
    echo IMAGE_VERSION=${IMAGE_VERSION} >> /etc/cs-jupyter-release && \
    echo UPSTREAM_MINIMAL_NOTEBOOK_VER=${UPSTREAM_MINIMAL_NOTEBOOK_VER} >> /etc/cs-jupyter-release && \
    echo GIT_DESCRIBE=${GIT_DESCRIBE} >> /etc/cs-jupyter-release

USER $NB_UID
