#
# Makefile to build the c756 tool container
#

# using Github CR now
CREG=ghcr.io
REGID=overcoil
INAME=c756-tool
AINAME=$(CREG)/$(REGID)/$(INAME)

# override this (to arm) if you're on an M1 Mac
THIS_ARCH=x86

# this is the public repo name as communicated to students
PUBLICNAME=ghcr.io/scp756-221/tool


#-----
X86_K9S_ARCH=x86_64

ARM_ARCH_CLASS=aarch64
ARM_ARCH_BRAND=arm
ARM_K9S_ARCH=arm64

.PHONY=all local ghcr sfu x86 arm


all: local ghcr

local: x86 arm

ghcr: local
	docker push $(AINAME):x86
	docker push $(AINAME):arm


# publish this to the course's organization CR
# REMEMBER to change the package's repo to public manually!!!
sfu: ghcr
	docker tag $(AINAME):x86 $(PUBLICNAME):x86
	docker push $(PUBLICNAME):x86
	docker tag $(AINAME):arm $(PUBLICNAME):arm
	docker push $(PUBLICNAME):arm

# use the default values of ARCH_CLASS & ARCH_BRAND inside the Dockerfile 
# stay with default USER
x86:
	docker build --tag $(AINAME):x86 --build-arg K9S_ARCH=$(X86_K9S_ARCH) . 
	docker image ls | grep $(INAME)

# override for ARM
arm:
	docker build --tag $(AINAME):arm --build-arg ARCH_CLASS=$(ARM_ARCH_CLASS) --build-arg ARCH_BRAND=$(ARM_ARCH_BRAND) --build-arg K9S_ARCH=$(ARM_K9S_ARCH) . 
	docker image ls | grep $(INAME)

# convenient target to start the LOCAL copy
GHOME=/Users/gkyc/newroot/GitHub.nosync/sfu/c756.211.dead/sfu-cmpt756.203/gatling-charts-highcharts-bundle-3.5.0
CHOME=/Users/gkyc/newroot/GitHub.nosync/sfu/c756-cont
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
		$(AINAME):$(THIS_ARCH)
