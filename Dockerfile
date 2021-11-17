#
# Define architecture
#
# Tools that require explicit specification of the architecture
# use one of two forms of specification:
# 1. "CLASS": The generic name for that class of architecture
# 2. "BRAND": A vendor brand associated with that architecture.
#
# k9s uses a third specification format.  See the Makefile for
# how K9S_ARCH is derived from the above two.
#
# When specifying an architecture, both must be given.
#
# X86_64
ARG ARCH_CLASS="x86_64"
ARG ARCH_BRAND="amd"
#
# ARM_64
#ARG ARCH_CLASS="aarch64"
#ARG ARCH_BRAND="arm"
#
# The Operating system that will be the base of the toolset
#
ARG OS_VER="ubuntu:20.04"
#
# Build the toolset container
#
FROM ${OS_VER}
#
# Repeat these inside the stage to put them into this stage's scope
#
ARG ARCH_CLASS
ARG ARCH_BRAND
ARG K9S_ARCH
#
#
# The user the container will run as
#
ARG USER=root
#
# Software versions
# Most software is just installed as "latest stable version" but
# some packages require explicit version numbers.
#
ENV ISTIO_VER=1.11.4
ENV HELM_VER=v3.7.1
ENV KUSTOMIZE_VER=v4.4.0
ENV GATLING_VER=3.4.2
ENV K9S_VER=v0.25.0
#
# Working directory for downloading etc. during installs
#
WORKDIR /build/work
#
# --- Utilities ---
# Note: man-db is required for the AWS CLI help feature.
# software-properties-common is required for add-apt-repository
# (which is required to install git)
#
RUN apt-get update \
&&  apt-get install -y --no-install-recommends \
        unzip \
        make \
        python3 \
        python3-pip \
	man-db \
        openssl \
        apt-transport-https \
        ca-certificates \
        curl \
	software-properties-common \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
#
# Uncomment to install man pages, etc.
# This substantially increases the image size,
# to no particularly useful purpose.  Users can
# instead just look up Linux man pages on the Web
#
#unminimize
#
# --- Gnu tools ---
#
# Latest Git
RUN add-apt-repository ppa:git-core/ppa \
&& apt-get update \
&& apt-get install -y git \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
#
# --- Homebrew package manager ---
# Nov 2021: Homebrew does not currently support ARM64. Do not
# install it or any of the tools we install via `brew`.  Leave
# the lines in, commented, to be added later when Homebrew supports
# ARM64.
#
# Need Homebrew to install some tools later (such as k9s).
# Install it *early* in sequence because it takes a very long
# time to install and we want to cache this image layer now
# so it doesn't get rebuilt every time we change a later
# layer.
#
# First, install brew's required packages (sigh)
#RUN apt-get update
#&& apt-get install -y build-essential procps file \
#&& apt-get clean \
#&& rm -rf /var/lib/apt/lists/*
# Now install brew
#RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
#&& echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /${USER}/.profile
#
# --- AWS tools ---
#
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_CLASS}.zip" -o "awscliv2.zip" \
&& unzip awscliv2.zip \
&& ./aws/install \
&& rm -f awscliv2.zip
# eksctl
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_${ARCH_BRAND}64.tar.gz" | tar xz -C /tmp \
&& mv /tmp/eksctl /usr/local/bin
# AWS Python SDK
RUN pip install boto3
#
# --- Azure tools ---
#
# First delete outdated Azure CLI shipped with Ubuntu 20.04
# See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
# Now that we're cleaning the config files after every call, this fails,
# so we just assume Ubuntu doesn't have the old version
#RUN apt-get remove azure-cli -y \
#&& apt-get autoremove -y \
#&& apt-get clean \
#&& rm -rf /var/lib/apt/lists/*
# Install latest Azure CLI
# The install script uses apt-get
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
#
# --- Docker (to build and push from scripts) ---
# Nov 2021: No longer installed because everything runs from this container
#
# See
#   https://docs.docker.com/engine/install/ubuntu/#installation-methods
# Install required packages; ca-certificates and curl were installed above
#RUN apt-get install -y \
#      gnupg \
#      lsb-release
# Now install docker
#RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
#&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
#      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
#&& apt-get update \
#&& apt-get install -y docker-ce docker-ce-cli containerd.io
#
# --- Kubernetes tools ---
#
# Install kubectl. See
#   https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
# See https://askubuntu.com/questions/1100800/kubernetes-installation-failing-ubuntu-16-04
# for why I replaced "https://apt.kubernetes.io/" in the instructions with "http://packages.cloud.google.com/apt/"
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] http://packages.cloud.google.com/apt/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
&& apt-get update \
&& apt-get install -y kubectl \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
# helm
RUN curl -o - https://get.helm.sh/helm-${HELM_VER}-linux-${ARCH_BRAND}64.tar.gz | tar -zxvf - \
&& mv linux-${ARCH_BRAND}64/helm /usr/local/bin/helm
# istioctl
RUN cd /opt \
&& curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VER} TARGET_ARCH=${ARCH_CLASS} sh - \
&& cd istio-${ISTIO_VER} \
&& echo "export PATH=${PWD}/bin":'${PATH}' >> /${USER}/.profile
#
# --- General tools ---
#
#
# Golang (https://golang.org/)
# For building utilities from Go source
# NOW MOVED TO SEPARATE IMAGE (ghcr.io/tedkirkpatrick/k9s)
# In any case, no longer needed, as we directly download k9s.
#
#RUN rm -rf /usr/local/go \
#&& curl -OL https://golang.org/dl/go${GOLANG_VER}.linux-${ARCH_BRAND}64.tar.gz \
#&& tar -C /usr/local -xzf go${GOLANG_VER}.linux-${ARCH_BRAND}64.tar.gz \
#&& echo "export PATH=$/usr/local/go/bin":'${PATH}' >> /${USER}/.profile
#
# k9s (https://k9scli.io/)
# A TUI-based, enhanced kubectl.
#
# Installing k9s: A thrilling play in four Acts
#
# Act 1: Install using Homebrew (FAILED)
#   Failed because (as of Nov 2021) Linux Homebrew does not support ARM64.
#   When Linux Homebrew supports ARM as well as AMD/Intel, we can directly
#   install k9s
#RUN /home/linuxbrew/.linuxbrew/bin/brew install derailed/k9s/k9s
#
# Act 2: Compile from source in this image (PARTIALLY SUCCEEDED)
#  This worked on both AMD64 and ARM64 but increased image size by 2 GiB.
#  The code has been removed from this build and placed in a separate image
#  (ghcr.io/tedkirkpatrick/k9s).
#
# Act 3: Compile in a separate step or separate image (FAILED)
#  Both approaches (multi-step build and completely separate build)
#  successfully compiled k9s but copying the /opt/k9s directory did
#  not include the Golang packages required to run.
#
#  There's some Golang tool that bundles an executable with its
#  packages into a single binary but rather than digging around to
#  find its name and all its required parameters I moved
#  on to Act 4, which finally succeeded.
#
#  For historical reasons, I retained in comments all the false starts
#  I had for specifying the image name to the `--from` parameter. Fun!
#
#COPY --from=goutils  /opt/k9s /opt/k9s
#COPY --from=${REGISTRY}/${USERID}/k9s:${VER}-${ARCH_BRAND}64 /opt/k9s /opt/k9s
# ARG values are not accessible in COPY, so we define an ENV variable
#ENV K9S_IMAGE_NAME=${REGISTRY}/${USERID}/k9s:${VER}-${ARCH_BRAND}64
#COPY --from=${K9S_IMAGE_NAME} /opt/k9s /opt/k9s
# ENV VARIABLES DO NOT SEEM TO BE EXPANDED, EITHER!
# SO WE HAVE TO EXPLICITLY SPECIFY THE IMAGE NAME GRRRRRRRRRRRRRRRRRRRRR
#COPY --from=ghcr.io/tedkirkpatrick/k9s:v1.0beta2-amd64 /opt/k9s /opt/k9s
#
# Act 4: Download a binary from the GitHub repo (SUCCEEDED)
#  These bundles include both the core executable and all required
#  packages as a single binary, for both AMD64 and ARM64.
#
#  But even this solution has a wrinkle: The owner uses a unique format
#  for specifying the architecture.  See the Makefile for how
#  K9S_ARCH is defined.
#
RUN mkdir -p /opt/k9s \
&& cd /opt/k9s \
&& curl -L -o - https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_${K9S_ARCH}.tar.gz | tar xz \
&& echo "export PATH=/opt/k9s":'${PATH}' >> /${USER}/.profile
#
# jq (https://stedolan.github.io/jq/)
# Format and query JSON files
#
RUN apt-get update \
&& apt-get install -y jq \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
#
# yq (https://github.com/mikefarah/yq)
# Format and query YAML files
#
RUN curl -L -o - https://github.com/mikefarah/yq/releases/download/v4.14.1/yq_linux_${ARCH_BRAND}64.tar.gz | tar xz \
&& mv yq_linux_${ARCH_BRAND}64 /usr/bin/yq
#
# Gatling (https://gatling.io/)
# Load-test applications
#
RUN apt-get update \
&& apt-get install -y openjdk-8-jre \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& cd /build/work \
&& mkdir -p gatling \
&& cd gatling \
&& curl -L -o gatling-$GATLING_VER.zip https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/$GATLING_VER/gatling-charts-highcharts-bundle-$GATLING_VER-bundle.zip \
&& unzip gatling-$GATLING_VER.zip \
&& mkdir -p /opt/gatling \
&& mv -f gatling-charts-highcharts-bundle-$GATLING_VER/* /opt/gatling \
&& rm gatling-$GATLING_VER.zip \
&& rmdir gatling-charts-highcharts-bundle-$GATLING_VER
#
# --- Tools not explicitly called (yet!) but that may be of use ---
#
# argocd (https://argo-cd.readthedocs.io/en/stable/)
# Continuous delivery
# Nov 2021: Commented out because ARM version of brew unavailable
#
#RUN /home/linuxbrew/.linuxbrew/bin/brew install argocd
#
# task (https://taskfile.dev/)
# Modern substitute for `make`
# Nov 2021: Commented out because ARM version of brew unavailable
#
#RUN /home/linuxbrew/.linuxbrew/bin/brew install go-task/tap/go-task
#
# kustomize (https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
# Extend `kubectl`
#
RUN curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VER}/kustomize_${KUSTOMIZE_VER}_linux_${ARCH_BRAND}64.tar.gz \
&& tar xzf kustomize_${KUSTOMIZE_VER}_linux_${ARCH_BRAND}64.tar.gz \
&& mv kustomize /usr/bin/kustomize
#
# vim editor
#
RUN apt-get update \
&& apt-get install -y vim \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
#
# Tools for debugging DNS (including `dig`)
#
RUN apt-get update \
&& apt-get install -y dnsutils \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
#
# --- Set up for running ---
#
# Share user's home directory configurations
# (`docker container run` in Makefile must `-v` each of these)
VOLUME /${USER}/.aws
VOLUME /${USER}/.azure
VOLUME /${USER}/.ssh
VOLUME /${USER}/.kube
VOLUME /${USER}/.config
# Share Gatling scripts and results from e-k8s subdirectories
VOLUME ["/opt/gatling/results", "/opt/gatling/user-files", "/opt/gatling/target"]

# Map this to the user's working directory
VOLUME /home/k8s
WORKDIR /home/k8s
#
# By default, run a login shell that reads `.profile`
CMD ["bash", "-l"]
