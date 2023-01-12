ARG VER_BASE
FROM aaltoscienceit/notebook-server-base:${VER_BASE}

## R support

USER root

ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.8.4

# https://julialang.org/downloads/
# wget -O- https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.4-linux-x86_64.tar.gz | sha256sum -
RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "f0427a4d7910c47dc7c31f65ba7ecaafedbbc0eceb39c320a37fa33598004fd5 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

RUN julia -e 'import Pkg; Pkg.update()' && \
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
    conda install \
        pyqt \
        && \
    conda clean --all --yes && \
    rm -rf /opt/conda/pkgs/cache/ && \
    fix-permissions $CONDA_DIR /home/$NB_USER


#RUN julia -e 'import Pkg; Pkg.update()' && \
#    julia -e "using Pkg; pkg\"add AAA BBB\"; pkg\"precompile\"" && \
#    echo "Done compiling..." && \
#    rm -rf $HOME/.local && \
#    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter && \
#    echo "done"


# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*.sh

USER $NB_UID
