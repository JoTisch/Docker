FROM nipype/nipype:py36

SHELL ["/bin/bash", "-c"]
WORKDIR /work/

# Add all used tools rogether. Dockerfile "ADD" untars into folders
ADD --chown=neuro:users ./*.tar.gz /work/

USER root

# build on mac m1 
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list
RUN sed -i 's|security.debian.org|archive.debian.org/|g' /etc/apt/sources.list
RUN sed -i '/stretch-updates/d' /etc/apt/sources.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y insighttoolkit4-python \
	imagemagick libinsighttoolkit4-dev build-essential cmake libvtk6-dev libvtk6-qt-dev \
	libtclap-dev libncurses5 libncurses5-dev ann-tools libann-dev \
	libgdcm2-dev libvtkgdcm2-dev libgdcm-tools libvtkgdcm-tools nano xorg wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER neuro

# PYTHON CONDA ENV: NIFETAL
#COPY ./fetal_brain_seg_condareq.yml /work/fetal_brain_seg_condareq.yml
COPY --chown=neuro:users ./nifetal_conda_requirements.yml /work/nifetal_conda_requirements.yml
RUN conda env create -f /work/nifetal_conda_requirements.yml && conda init && \
    source activate nifetal && pip install numpy==1.17.3

# FETAL_BRAIN_SEG
# fetal_brain_seg git including Demic 0.1 git inside
# COPY --chown=neuro:users ./fetal_brain_seg /work/fetal_brain_seg

# ANTS (Neurodocker build like in https://github.com/nipreps/nibabies/blob/master/Dockerfile)
# Source: https://dl.dropbox.com/s/gwf51ykkk5bifyj/ants-Linux-centos6_x86_64-v2.3.4.tar.gz
# COPY --chown=neuro:users ./ants-Linux-centos6_x86_64-v2.3.4 /work/ants-Linux-centos6_x86_64-v2.3.4

# mialsuperresolutiontoolkit
# git clone --depth 1 --branch v1.0 https://github.com/Medical-Image-Analysis-Laboratory/mialsuperresolutiontoolkit.git
# COPY --chown=neuro:users ./mialsuperresolutiontoolkit /work/mialsuperresolutiontoolkit
RUN cd /work/mialsuperresolutiontoolkit/src && mkdir -p build && cd build && \
	sed "s/ -Wno-gnu//g" ../CMakeLists.txt > ../CMakeLists.tmp && \
	sed "s/ -Werror//g" ../CMakeLists.tmp > ../CMakeLists.txt && \
	cmake -D USE_OMP=ON .. && \
	make -j 8

# C3D
# curl 'https://downloads.sourceforge.net/project/c3d/c3d/Experimental/c3d-1.1.0-Linux-x86_64.tar.gz
# COPY --chown=neuro:users ./c3d-1.1.0-Linux-x86_64 /work/c3d-1.1.0-Linux-x86_64

# fbrain
# Binaries Linux64: https://github.com/downloads/rousseau/fbrain/BTK-v1.0-Linux-x64.tar.gz
# ALT: RUN git clone --depth 1 --branch "Btk_1.0" https://github.com/rousseau/fbrain && \
#   mkdir -p fbrain/build && cd fbrain/build && \
#	cmake -D USE_OMP=ON .. && make -j8
# COPY --chown=neuro:users ./fbrain /work/fbrain

# elastix
# COPY --chown=neuro:users ./elastix /work/elastix

# Ezys registration
# COPY --chown=neuro:users ./registrationWithEzys /work/registrationWithEzys

# FetalMOCO
# License & Download: https://www.doc.ic.ac.uk/~dr/software/download.html
# COPY --chown=neuro:users ./FetalMOCO_UCL /work/FetalMOCO_UCL
# Not used in codebase except _sandbox

# SVPASEG
# COPY --chown=neuro:users ./SVPASEG /work/SVPASEG

# hierarchicalmaxflow
# COPY --chown=neuro:users ./hierarchicalMaxFlow /work/hierarchicalMaxFlow

# MIRTK
# COPY --chown=neuro:users ./MIRTK /work/MIRTK

# PICSL-MALF
# COPY --chown=neuro:users ./PICSL_MALF /work/PICSL_MALF

# SLICER-CLI
# COPY --chown=neuro:users ./SlicerCLI /work/SlicerCLI

# ITK_NiftyMIC
# COPY --chown=neuro:users ./ITK_NiftyMIC /work/ITK_NiftyMIC
RUN source activate nifetal && \
	mkdir -p ITK_NiftyMIC/ITK_NiftyMIC-build && \
	cd ITK_NiftyMIC/ITK_NiftyMIC-build && \
	cmake \
	  -D CMAKE_BUILD_TYPE=Release \
	  -D BUILD_TESTING=OFF \
	  -D BUILD_EXAMPLES=OFF \
	  -D BUILD_SHARED_LIBS=ON \
	  -D ITK_WRAP_PYTHON=ON \
	  -D ITK_LEGACY_SILENT=ON \
	  -D ITK_WRAP_float=ON \
	  -D ITK_WRAP_double=ON \
	  -D ITK_WRAP_signed_char=ON \
	  -D ITK_WRAP_signed_long=ON \
	  -D ITK_WRAP_signed_short=ON \
	  -D ITK_WRAP_unsigned_char=ON \
	  -D ITK_WRAP_unsigned_long=ON \
	  -D ITK_WRAP_unsigned_short=ON \
	  -D ITK_WRAP_vector_float=ON \
	  -D ITK_WRAP_vector_double=ON \
	  -D ITK_WRAP_covariant_vector_double=ON \
	  -D Module_ITKReview=ON \
	  -D Module_SmoothingRecursiveYvvGaussianFilter=ON \
	  -D Module_BridgeNumPy=ON \
	  ../ && \
	make -j 8 && \
	cp Wrapping/Generators/Python/WrapITK.pth /opt/miniconda-latest/envs/nifetal/lib/python3.7/site-packages/

ENV NIFTYMIC_ITK_DIR=/work/ITK_NiftyMIC/ITK_NiftyMIC-build

# niftyreg
# https://github.com/KCL-BMEIS/niftyreg/wiki/install
# COPY --chown=neuro:users ./niftyreg /work/niftyreg
RUN cd niftyreg && mkdir -p ./niftyreg_build && mkdir -p ./niftyreg_install && \
	cd niftyreg_build && cmake -DCMAKE_INSTALL_PREFIX=../niftyreg_install .. && \
	make -j 8 && make install
ENV NIFTYREG_INSTALL=/work/niftyreg/niftyreg_install
ENV PATH=${PATH}:${NIFTYREG_INSTALL}/bin

# SimpleReg
# https://github.com/gift-surg/SimpleReg/wiki/simplereg-dependencies
# Contained in conda env nifetal requirements.yml

# NiftyMIC
# git clone --depth 1 --branch=v0.7.2 https://github.com/gift-surg/NiftyMIC.git
# COPY --chown=neuro:users ./NiftyMIC /work/NiftyMIC
RUN cd NiftyMIC && \
	source activate nifetal && \
	pip install -e .
	# sed '/numpy/'d requirements.txt > requirements.txt && \
	# pip install -r requirements.txt --ignore-installed certifi && \

# MCR 2019a / v96
# Adapted from: https://github.com/demartis/matlab_runtime_docker/blob/master/R2019a/Dockerfile
# Download the MCR from MathWorks site an install with -mode silent
USER root
RUN mkdir /mcr-install && \
    mkdir /opt/mcr && \
    cd /mcr-install && \
    wget --no-check-certificate -q https://ssd.mathworks.com/supportfiles/downloads/R2019a/Release/9/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019a_Update_9_glnxa64.zip && \
    unzip -q MATLAB_Runtime_R2019a_Update_9_glnxa64.zip && \
    rm -f MATLAB_Runtime_R2019a_Update_9_glnxa64.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    cd / && \
    rm -rf mcr-install  

# Configure environment variables for MCR  
ENV LD_LIBRARY_PATH /opt/mcr/v96/runtime/glnxa64:/opt/mcr/v96/bin/glnxa64:/opt/mcr/v96/sys/os/glnxa64:/opt/mcr/v96/extern/bin/glnxa64  
ENV XAPPLRESDIR /etc/X11/app-default

USER neuro
LABEL org.label-schema.name="NIFETAL" \
      org.label-schema.description="NIFETAL - fetal neuroimaging" \
      org.label-schema.url="https://www.cir.meduniwien.ac.at"
