ARG UPSTREAM_SCIPY_NOTEBOOK_VER
FROM jupyter/scipy-notebook:${UPSTREAM_SCIPY_NOTEBOOK_VER}

USER root

ADD clean-layer.sh  /tmp/clean-layer.sh

# Debian package
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        clang \
        git-annex \
        git-lfs \
        git-svn \
        graphviz \
        less \
        man-db \
        openssh-client \
        tzdata \
        vim \
        && \
    /tmp/clean-layer.sh

RUN touch /.nbgrader.log && chmod 777 /.nbgrader.log
# sed -r -i 's/^(UMASK.*)022/\1002/' /etc/login.defs

# JupyterHub says we can use any exsting jupyter image, as long as we properly pin the JupyterHub version
# https://github.com/jupyterhub/jupyterhub/tree/master/singleuser
RUN pip install --no-cache-dir jupyterhub==1.0.0 && \
        fix-permissions $CONDA_DIR /home/$NB_USER

RUN conda install conda=4.7.10

# Custom extension installations
#   importnb allows pytest to test ipynb
RUN conda install \
        pytest \
        nbval \
        && \
    pip install --no-cache-dir \
        bash_kernel \
        importnb \
        ipymd \
        ipywidgets \
        jupyter_contrib_nbextensions \
        && \
    jupyter contrib nbextension install --sys-prefix && \
    python -m bash_kernel.install --sys-prefix && \
    ln -s /notebooks /home/jovyan/notebooks && \
    rm --dir /home/jovyan/work && \
    /tmp/clean-layer.sh

RUN \
    conda install jupyterlab==1.0.2 && \
    pip install --no-cache-dir \
        jupyterlab-git \
        nbdime \
        && \
    jupyter serverextension enable --py nbdime --sys-prefix && \
    jupyter nbextension install --py nbdime --sys-prefix && \
    jupyter nbextension enable --py nbdime --sys-prefix && \
    jupyter serverextension enable --py --sys-prefix jupyterlab_git && \
    jupyter labextension install \
                                # Deprecated, hub is now a built-in
                                #  @jupyterlab/hub-extension \
                                 @jupyter-widgets/jupyterlab-manager \
                                 @jupyterlab/google-drive \
                                 @jupyterlab/git \
                                # Incompatible with jupyterlab 1.0.2
                                #  nbdime-jupyterlab \
                                && \
    jupyter labextension disable @jupyterlab/google-drive && \
    nbdime config-git --enable --system && \
    git config --system core.editor nano && \
    /tmp/clean-layer.sh

#                                jupyterlab_voyager \

# @jupyterlab/google-drive disabled by default until the app can be
# verified.  To enable, use "jupyter labextension enable
# @jupyterlab/google-drive". or remove the line above.


#COPY drive.jupyterlab-settings /opt/conda/share/jupyter/lab/settings/@jupyterlab/google-drive/drive.jupyterlab-settings
#COPY drive.jupyterlab-settings /home/jovyan/.jupyter/lab/user-settings/@jupyterlab/google-drive/drive.jupyterlab-settings
RUN sed -i s/625147942732-t30t8vnn43fl5mvg1qde5pl84603dr6s.apps.googleusercontent.com/939684114235-busmrp8omdh9f0jdkrer6o4r85mare4f.apps.googleusercontent.com/ \
     /opt/conda/share/jupyter/lab/static/vendors~main.*.js* \
     /opt/conda/share/jupyter/lab/staging/build/vendors~main.*.js* \
     /opt/conda/share/jupyter/lab/staging/node_modules/@jupyterlab/google-drive/lib/gapi*

# Commit on Jun 19, 2019
RUN pip install --no-cache-dir git+https://github.com/AaltoScienceIT/nbgrader@110f922 && \
    jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    jupyter nbextension enable --sys-prefix --py nbgrader && \
    jupyter serverextension enable --sys-prefix --py nbgrader && \
    /tmp/clean-layer.sh

# Hooks and scrips are also copied at the end of other Dockerfiles because they
# might update frequently
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*.sh

USER $NB_UID