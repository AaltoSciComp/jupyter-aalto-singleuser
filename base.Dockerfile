ARG UPSTREAM_SCIPY_NOTEBOOK_VER
FROM jupyter/scipy-notebook:${UPSTREAM_SCIPY_NOTEBOOK_VER}

USER root

ADD scripts/clean-layer.sh /usr/local/bin/
RUN \
    # The upstream image jupyter/scipy-notebook pins a specific python
    # version. Uncomment the lines below if you want to install a different
    # version than the one in the upstream image.
    # sed -i '/python.*/d'                        /opt/conda/conda-meta/pinned && \
    # echo "python ==3.8.3"                    >> /opt/conda/conda-meta/pinned && \
    echo "numpy 1.18.*"                      >> /opt/conda/conda-meta/pinned && \
    echo "scipy 1.4.*"                       >> /opt/conda/conda-meta/pinned && \
    clean-layer.sh

# Debian package
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        clang \
        file \
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
    clean-layer.sh

RUN touch /.nbgrader.log && chmod 777 /.nbgrader.log
# sed -r -i 's/^(UMASK.*)022/\1002/' /etc/login.defs

# JupyterHub 1.0.0 is included in the current scipy-notebook image
# JupyterHub says we can use any existing jupyter image, as long as we properly
# pin the JupyterHub version
# https://github.com/jupyterhub/jupyterhub/tree/master/singleuser
RUN pip install --no-cache-dir jupyterhub==1.1.0 && \
    fix-permissions $CONDA_DIR /home/$NB_USER

# Conda 4.7.10 is included in scipy-notebook
# RUN conda install conda=4.7.10

# Custom extension installations
#   importnb allows pytest to test ipynb
RUN conda config --set auto_update_conda False && \
    conda install \
        conda-tree \
        pytest \
        nbval \
        && \
    pip install --no-cache-dir \
        bash_kernel \
        importnb \
        inotify \
        ipymd \
        ipywidgets \
        jupyter_contrib_nbextensions \
        pipdeptree \
        && \
    jupyter contrib nbextension install --sys-prefix && \
    python -m bash_kernel.install --sys-prefix && \
    ln -s /notebooks /home/jovyan/notebooks && \
    rm --dir /home/jovyan/work && \
    clean-layer.sh

    # JupyterLab 1.0.1 is included in scipy-notebook
    # conda install jupyterlab==1.1.0 && \
RUN \
    conda install jupyterlab==2.1.5 && \
    pip install --no-cache-dir \
        jupyterlab-git \
        nbdime \
        nbgitpuller \
        nbstripout \
        nbzip \
        && \
    jupyter serverextension enable --py nbdime --sys-prefix && \
    jupyter nbextension install --py nbdime --sys-prefix && \
    jupyter nbextension enable --py nbdime --sys-prefix && \
    jupyter nbextension enable varInspector/main --sys-prefix && \
    jupyter serverextension enable --py --sys-prefix jupyterlab_git && \
    jupyter serverextension enable --py nbzip --sys-prefix && \
    jupyter nbextension install --py nbzip && \
    jupyter nbextension enable --py nbzip && \
    jupyter labextension install \
                                # Deprecated, hub is now a built-in
                                #  @jupyterlab/hub-extension \
                                 @jupyter-widgets/jupyterlab-manager \
                                 @jupyterlab/google-drive \
                                 @jupyterlab/git \
                                 @fissio/hub-topbar-buttons \
                                # Incompatible with jupyterlab 1.0.2
                                 nbdime-jupyterlab \
                                 @lckr/jupyterlab_variableinspector \
                                jupyter-matplotlib \
                                && \
    jupyter labextension disable @jupyterlab/google-drive && \
    nbdime config-git --enable --system && \
    jupyter serverextension enable nbgitpuller --sys-prefix && \
    git config --system core.editor nano && \
    clean-layer.sh

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

# Commit on Aug 25, 2019, branch live
RUN pip install --no-cache-dir git+https://github.com/AaltoScienceIT/nbgrader@b5ae9f89 && \
    jupyter nbextension install --sys-prefix --py nbgrader --overwrite && \
    jupyter nbextension enable --sys-prefix --py nbgrader && \
    jupyter serverextension enable --sys-prefix --py nbgrader && \
    jupyter nbextension disable --sys-prefix formgrader/main --section=tree && \
    jupyter serverextension disable --sys-prefix nbgrader.server_extensions.formgrader && \
    jupyter nbextension disable --sys-prefix create_assignment/main && \
    jupyter nbextension disable --sys-prefix course_list/main --section=tree && \
    jupyter serverextension disable --sys-prefix nbgrader.server_extensions.course_list && \
    clean-layer.sh

# Hooks and scrips are also copied at the end of other Dockerfiles because they
# might update frequently
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod a+rx /usr/local/bin/*.sh

USER $NB_UID
