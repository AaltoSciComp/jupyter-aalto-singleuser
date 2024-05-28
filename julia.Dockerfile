ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root

ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.9.4
ENV JULIA_HASH=07d20c4c2518833e2265ca0acee15b355463361aa4efdab858dad826cf94325c

# https://julialang.org/downloads/
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
    export JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)" && \
    (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")') && \
    julia -e "using Pkg; pkg\"add Gadfly RDatasets IJulia InstantiateFromURL Cbc Clp ECOS ForwardDiff GLPK Ipopt JuMP Plots PyPlot DataFrames Distributions CSV BenchmarkTools Test LaTeXStrings HiGHS JLD2\"; pkg\"precompile\"" && \
    echo "Done compiling..." && \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
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
#    julia -e "using Pkg; pkg\"add AAA BBB\"; pkg\"precompile\"" && \
#    echo "Done compiling..." && \
#    rm -rf $HOME/.local && \
#    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter && \
#    echo "done"

RUN \
    /opt/conda/bin/pip install --no-cache-dir \
        'jupyterhub>=4.0.1' && \
    clean-layer.sh


# linopt2024, RT#24964
RUN julia -e 'import Pkg; Pkg.update()' && \
    julia -e "using Pkg; pkg\"add https://github.com/gamma-opt/JuMPModelPlotting\"; pkg\"precompile\"" && \
    echo "Done compiling..." && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter && \
    echo "done"


# RT#25980, issue #17
RUN \
    apt-get update && apt-get install -y --no-install-recommends \
        # For exporting notebooks containing SVGs using nbconvert
        inkscape \
        && \
    clean-layer.sh


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
