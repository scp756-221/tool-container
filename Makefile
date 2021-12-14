#
# Makefile to build the c756 tool container
# Steps to build and publish an image:

# Set this to either "amd" or "arm"
# Left empty to require that it be specified on command line
TARGET_ARCH=

# Populate the arguments to Dockerfile
ifeq ($(TARGET_ARCH),amd)
  ARCH_BRAND=amd
  ARCH_CLASS=x86_64
  K9S_ARCH=x86_64
else ifeq ($(TARGET_ARCH),arm)
  ARCH_BRAND=arm
  ARCH_CLASS=aarch64
  K9S_ARCH=arm64
else
  $(error TARGET_ARCH must be defined as "arm" or "amd")
endif


# CREG is the development registry
# PUBCREG is the public registry used in the course
CREG=ghcr.io
PUBCREG=ghcr.io

# REGID is the development ID on CREG
# PUBREGID is the public ID on PUBCREG 
REGID=overcoil
PUBREGID=scp756-221

INAME=c756-tool
VER=v1.0beta3


# The development image name
AINAME=$(CREG)/$(REGID)/$(INAME):$(VER)-$(TARGET_ARCH)64

# The public package from which students will pull their image.
# This package must be made public. Note that the package need only
# be made public once and it will make ALL VERSIONS public.
PUBLIC_PACKAGE=$(PUBCREG)/$(PUBREGID)/$(INAME)

# The public repo image as communicated to students
PUBLICNAME=$(PUBLIC_PACKAGE):$(VER)-$(TARGET_ARCH)64


DOCKERFILE=Dockerfile


.PHONE=all local dev sfu manifest public-manifest


all: local dev


# Push the image to the registry under its development name
dev:
	docker push $(AINAME)


.PHONY=all local ghcr sfu x86 arm


# Publish this to the course's organization CR
sfu: dev
	docker tag $(AINAME) $(PUBLICNAME)
	docker push $(PUBLICNAME)


# Publish the combined manifest for the development image
manifest: 
	docker manifest create $(CREG)/$(REGID)/$(INAME):$(VER) \
	  --amend $(CREG)/$(REGID)/$(INAME):$(VER)-arm64 \
	  --amend $(CREG)/$(REGID)/$(INAME):$(VER)-amd64
	docker manifest push $(CREG)/$(REGID)/$(INAME):$(VER)


# Publish the combined manifest for the public image
public-manifest:
	make CREG=$(PUBCREG) REGID=$(PUBREGID) manifest


# Build the image on the current architecture
build:	${DOCKERFILE}
	docker image build -f ${DOCKERFILE} \
	--build-arg REGISTRY=$(CREG) \
	--build-arg USERID=$(REGID) \
	--build-arg VER=$(VER) \
	--build-arg ARCH_BRAND=$(ARCH_BRAND) \
	--build-arg ARCH_CLASS=$(ARCH_CLASS) \
	--build-arg K9S_ARCH=$(K9S_ARCH) \
	-t ${CREG}/${REGID}/${INAME}:${VER}-$(ARCH_BRAND)64 .

# TODO: suspect!
# Likely no longer needed now that file is parameterized
# override for ARM
arm:
	docker build --tag $(AINAME):arm \
		--build-arg ARCH_CLASS=$(ARM_ARCH_CLASS)  \
		--build-arg ARCH_BRAND=$(ARM_ARCH_BRAND)  \
		--build-arg K9S_ARCH=$(ARM_K9S_ARCH) . 
	docker image ls | grep $(INAME)

# convenient target to start the LOCAL copy
# This target's developer-specific
GHOME=~/newroot/GitHub.nosync/sfu/c756.211.dead/sfu-cmpt756.203/gatling-charts-highcharts-bundle-3.5.0
CHOME=~/newroot/GitHub.nosync/sfu/c756-cont
run:
	docker container run -it --rm \
		-v ~/.aws:/root/.aws \
		-v ~/.azure:/root/.azure \
		-v ~/.ssh:/root/.ssh \
		-v ~/.kube:/root/.kube \
		-v ~/.config:/root/.config \
		-v $(GHOME)/results:/opt/gatling/results \
		-v $(GHOME):/opt/gatling/user-files \
		-v $(GHOME)/target:/opt/gatling/target \
		-v $(CHOME):/home/k8s \
		-e TZ=Canada/Pacific \
		$(AINAME)
