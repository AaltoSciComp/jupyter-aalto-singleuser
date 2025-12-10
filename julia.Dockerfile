ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root

ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.12.2
ENV JULIA_HASH=a6d0c39ea57303ebcffa7a8d453429b86eb271e150c7cb0f5958fe65909b493a

# https://julialang.org/downloads/manual-downloads/
# wget -O- https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.4-linux-x86_64.tar.gz | sha256sum -
RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/$(echo ${JULIA_VERSION} | cut -d. -f 1,2)/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "${JULIA_HASH} *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

RUN julia -e 'import Pkg; Pkg.update()' && \
    # https://words.yuvi.in/post/pre-compiling-julia-docker/, RT#24964
    export JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1);znver2,clone_all" && \
    (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")') && \
    set -x; \
    julia -e \
        'using Pkg; Pkg.add([ \
            "Gadfly", \
            "RDatasets", \
            "IJulia", \
            "Cbc", \
            "Clp", \
            "ECOS", \
            "ForwardDiff", \
            "GLPK", \
            "Ipopt", \
            "JuMP", \
            "Plots", \
            "PyPlot", \
            "DataFrames", \
            "Distributions", \
            "CSV", \
            "BenchmarkTools", \
            "Test", \
            "LaTeXStrings", \
            "HiGHS", \
            "JLD2", \
        ]); \
        Pkg.add(url="https://github.com/gamma-opt/JuMPModelPlotting") # linopt2024, RT#24964 \
        Pkg.precompile()' && \
    echo "Done compiling..." && \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter && \
    echo "done"

# Try to disable Python kernel
# https://github.com/jupyter/jupyter_client/issues/144
#RUN  \
#    echo "c.KernelSpecManager.whitelist={'julia-1.6', 'bash'}" >> /etc/jupyter/jupyter_notebook_config.py

RUN \
    mamba install \
        pyqt \
        && \
    clean-layer.sh


#RUN julia -e 'import Pkg; Pkg.update()' && \
#    julia -e \
#        'using Pkg; Pkg.add([ \
#            "AAA", \
#            "BBB", \
#        ]); \
#        Pkg.precompile()' && \
#    echo "Done compiling..." && \
#    rm -rf $HOME/.local && \
#    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter && \
#    echo "done"

RUN \
    /opt/conda/bin/pip install --no-cache-dir \
        'jupyterhub>=4.0.1' && \
    clean-layer.sh


# matplotlib is required by the PyPlot package. The currently installed version
# of PyPlot uses a now-deprecated function `register_cmap`, so it requires an
# old version of matplotlib
RUN \
    /opt/conda/bin/pip install --no-cache-dir \
        'matplotlib<3.6.0' \
        # The requested version of matplotlib doesn't seem to work with numpy>=2
        'numpy<2' && \
    clean-layer.sh

# TODO: remove when base updates
RUN \
    rm /usr/local/bin/before-notebook-root.d/allow-client-build.sh

# TODO: remove when updating base
# Fixes https://github.com/jupyter/nbgrader/issues/1870
RUN \
    # Use the full path to pip to be more explicit about which environment
    # we're installing to
    /opt/conda/bin/pip uninstall nbgrader -y && \
    /opt/conda/bin/pip install --no-cache-dir \
        git+https://github.com/AaltoSciComp/nbgrader@v0.8.4.dev505 && \
    clean-layer.sh


# linopt2025 RT#27927
RUN julia -e 'import Pkg; Pkg.update()' && \
   julia -e \
       'using Pkg; Pkg.add([ \
            "Combinatorics", \
            "Polyhedra", \
            "PlotlyJS", \
       ]); \
       Pkg.precompile()' && \
   echo "Done compiling..." && \
   rm -rf $HOME/.local && \
   fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter && \
   echo "done"

# ========================================

# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY --chmod=0755 hooks/ scripts/ /usr/local/bin/

# Save version information within the image
ARG IMAGE_VERSION
ARG BASE_IMAGE
ARG GIT_DESCRIBE
RUN \
    truncate --size 0 /etc/cs-jupyter-release && \
    echo IMAGE_VERSION=${IMAGE_VERSION} >> /etc/cs-jupyter-release && \
    echo BASE_IMAGE=${BASE_IMAGE} >> /etc/cs-jupyter-release && \
    echo GIT_DESCRIBE=${GIT_DESCRIBE} >> /etc/cs-jupyter-release


USER $NB_UID
