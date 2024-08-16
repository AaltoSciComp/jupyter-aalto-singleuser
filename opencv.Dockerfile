ARG STD_IMAGE
FROM ${STD_IMAGE}

USER root

# Installation steps from
# https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        # Enable HTTPS for wget
        ca-certificates \
        # Dependencies from the OpenCV documentation
        cmake \
        g++ \
        wget \
        unzip \
        && \
    clean-layer.sh

ARG OPENCV_VERSION=4.10.0

RUN \
    cd /usr/local/src && \
    wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip opencv.zip && \
    unzip opencv_contrib.zip && \
    mkdir -p build && cd build && \
    cmake \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/opt/opencv \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=ON \
        -D BUILD_EXAMPLES=ON \
        -D PYTHON3_EXECUTABLE=$(which python3) \
        -D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        -D PYTHON3_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var; from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')), get_config_var('LDLIBRARY')))") \
        -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") \
        -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-${OPENCV_VERSION}/modules \
        ../opencv-${OPENCV_VERSION} && \
    cmake --build . -j$(nproc) && \
    make install && \
    cd /usr/local/src && rm -r /usr/local/src/*

RUN conda install --quiet --yes pyflann line_profiler

# Save version information within the image
ARG IMAGE_VERSION
ARG STD_IMAGE
ARG GIT_DESCRIBE
RUN \
    truncate --size 0 /etc/cs-jupyter-release && \
    echo IMAGE_VERSION=${IMAGE_VERSION} >> /etc/cs-jupyter-release && \
    echo STD_IMAGE=${STD_IMAGE} >> /etc/cs-jupyter-release && \
    echo GIT_DESCRIBE=${GIT_DESCRIBE} >> /etc/cs-jupyter-release


USER $NB_UID
