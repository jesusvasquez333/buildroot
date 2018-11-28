FROM ubuntu:16.04

RUN apt-get -qq update && apt-get -qq install bzip2 wget make gcc g++ patch cpio python unzip rsync bc git locales
RUN locale-gen en_US.UTF-8

ENV TOP /usr/src/buildroot
ENV BR_VER buildroot-2016.11.1
ENV ARCH x86_64

# Prepare the TOP directory
RUN mkdir -p ${TOP}/${BR_VER};
WORKDIR ${TOP}/${BR_VER}

# Download buildroot
RUN wget -P download/ http://buildroot.uclibc.org/downloads/${BR_VER}.tar.bz2
RUN tar xfj download/${BR_VER}.tar.bz2
RUN mv ${BR_VER} buildroot

# Copy site-top configuration
ADD site-top.tar.gz .
RUN ln -s ../site-top buildroot/site

# Run SLAC preparation helper script
WORKDIR buildroot
RUN ./site/scripts/br-installconf.sh -a ${ARCH}

# Build
RUN make --quiet

# Prepare enviroment
ENV CROSS_COMPILE ${TOP}/${BR_VER}/host/linux-${ARCH}/${ARCH}/usr/bin/${ARCH}-buildroot-linux-gnu-
ENV KERNELDIR ${TOP}/${BR_VER}/buildroot/output/build/linux-4.8.11

# Prepare building area
ENV BUILD_HOME /home/build
RUN mkdir -p ${BUILD_HOME}
WORKDIR ${BUILD_HOME}

# Run make as default command
CMD ["make"]
