FROM ubuntu:22.04

# Start with actions for the user root 
USER root

# Assigning default values to environment variables
ENV RULES_FILE=/home/snorty/custom/local.rules
ENV SNORT_CONF_FILE=/home/snorty/custom/custom_snort.lua
ENV SNORT_ALERTS=/home/snorty/alerts
ENV VERBOSE=0


# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    asciidoc \
    autotools-dev \
    bison \
    build-essential \
    cmake \
    cpputest \
    dblatex \
    flex \
    git \
    hwloc \
    inotify-tools \
    iproute2 \
    iptables \
    libcap2-bin \
    libcmocka-dev \
    libdnet-dev \
    libdumbnet-dev \
    libfl-dev \
    libhwloc-dev \
    libhyperscan-dev \
    libluajit-5.1-dev \
    liblzma-dev \
    libmnl-dev \
    libnet1-dev \
    libnetfilter-queue-dev \
    libpcap-dev \
    libpcre3-dev \
    libsqlite3-dev \
    libssl-dev \
    libunwind-dev \
    luajit \
    nano \
    openssl \
    pkg-config \
    ranger \
    source-highlight \
    sudo \
    uuid-dev \
    vim \
    w3m \
    wget \
    zlib1g-dev 




# Create the snorty user and its home directory
RUN useradd -m -s /bin/bash snorty
# Set a default password for the snorty user
RUN echo "snorty:password" | chpasswd
# Add snorty to the sudoers file
RUN echo "snorty ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /home/snorty/snort3

# Install Snort DAQ
WORKDIR /tmp
RUN git clone https://github.com/snort3/libdaq.git
RUN cd libdaq && \
    ./bootstrap && \
    ./configure && \
    make && \
    make install


ARG LIBPCRE2_VERSION=10.44

# ===============+ DOUBLE CHECK +========================
# WORKDIR /tmpb
# Install PCRE2
RUN wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${LIBPCRE2_VERSION}/pcre2-${LIBPCRE2_VERSION}.tar.gz
RUN tar xzf pcre2-${LIBPCRE2_VERSION}.tar.gz
RUN cd pcre2-${LIBPCRE2_VERSION} && \
    ./configure --prefix=/usr/local --enable-jit && \
    make && \
    make install
# # Install PCRE2 development files
# RUN cp /usr/local/lib/libpcre2-8.so.* /usr/lib/x86_64-linux-gnu/
# # Install PCRE2 headers
# RUN cp -r /usr/local/include/pcre2* /usr/include/
# # Install PCRE2 pkg-config file 
# RUN cp /usr/local/lib/pkgconfig/pcre2-8.pc /usr/lib/x86_64-linux-gnu/pkgconfig/
# # Install PCRE2 shared library
# RUN ldconfig /usr/lib/x86_64-linux-gnu
# # Proposed by the PCRE2 documentation
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
RUN ldconfig

# =======================================================



ARG GPERFTOOLS_VERSION=2.9.1
# Install Gperftools
WORKDIR /tmp
RUN wget https://github.com/gperftools/gperftools/releases/download/gperftools-${GPERFTOOLS_VERSION}/gperftools-${GPERFTOOLS_VERSION}.tar.gz
RUN tar xzf gperftools-${GPERFTOOLS_VERSION}.tar.gz
RUN cd gperftools-${GPERFTOOLS_VERSION}/ && \
    ./configure && \
    make && \
    make install



# Clone and build Snort3
# https://github.com/snort3/snort3/tags
# Newest at the time of the build 3.9.1.0
WORKDIR /tmp
# Define a build-time argument for the Snort3 tag
ARG SNORT3_TAG=3.9.1.0
ARG SNORT_LOCATION=/home/snorty/snort3


# Use the argument in the RUN commands
RUN wget https://github.com/snort3/snort3/archive/refs/tags/${SNORT3_TAG}.tar.gz && \
    tar -xvzf ${SNORT3_TAG}.tar.gz && \
    cd snort3-${SNORT3_TAG} && \
    ./configure_cmake.sh --prefix=${SNORT_LOCATION} --enable-tcmalloc && \
    cd build && \
    make && \
    make install && \
    ldconfig

# Create directories and copy configuration
# RUN mkdir -p /etc/snort /var/log/snort
# COPY snort.lua /etc/snort/snort.lua

# Cleanup
# RUN rm -rf /tmp/snort3


# Set capabilities for snort binary 
RUN setcap cap_net_raw,cap_net_admin=eip ${SNORT_LOCATION}/bin/snort


# Copy the default custom rules and configuration files into the container
COPY volumes/scripts /home/snorty/scripts

RUN chmod +x /home/snorty/scripts/entrypoint.sh
RUN chmod +x /home/snorty/scripts/run_snort.sh
RUN chmod +x /home/snorty/scripts/run_snort_notify.sh

USER snorty
WORKDIR /home/snorty

# Set the PATH environment variable to include the snort3 binary directory
# ENV PATH="/home/snorty/snort3/bin:${PATH}"

ENTRYPOINT [  "/home/snorty/scripts/entrypoint.sh" ]

