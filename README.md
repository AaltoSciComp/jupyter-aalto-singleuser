This branch contains a custom image built for the Aalto University
course CS-E4850 - Computer Vision in 2020.

This image is used for the Aalto teaching and light
computing JupyterHub at https://jupyter.cs.aalto.fi.

Submit issues and pull requests to this repository for user server
environment.  Note that some courses may possibly have different
images.

The built images are on DockerHub:  https://hub.docker.com/r/aaltoscienceit/notebook-server

# How it works

`base.Dockerfile` contains the basic setup for the Jupyter environment.

`standard.Dockerfile` contains Python packages (all via the conda
install at `/opt/conda`).

`r-ubuntu.Dockerfile` contains R packages, but installed via Ubuntu
instead of via conda since there were some difficulties with using the
conda ones.

The `Makefile` provides some basic automation - check the rules in
there to see what they do.

The `hooks/` directory contains automated scripts which are run in
different stages of notebook deployment.

The `scripts/` directory contains miscellaneous scripts.

The contents of `hooks/` and `scripts/` are placed under `/usr/local/bin`
in the built image.
