DISTRO ?= fedora
ifeq ($(DISTRO), fedora)
	BASE_IMAGE = quay.io/fedora/fedora:40
	BOOTC_IMAGE = quay.io/fedora/fedora-bootc:40
else ifeq ($(DISTRO), centos)
	BASE_IMAGE = quay.io/centos/centos:stream9
	BOOTC_IMAGE = quay.io/centos-bootc/centos-bootc:stream9
	CENTOS_COMPOSE = $(shell skopeo inspect --format json docker://${BOOTC_IMAGE} | jq -r '.Labels["redhat.compose-id"]')
else ifeq ($(DISTRO), redhat)
	BASE_IMAGE = registry.redhat.io/ubi9/ubi:9.4
	BOOTC_IMAGE = registry.redhat.io/rhel9/rhel-bootc:9.4
	EXTRA_LABELS = --label=com.redhat.component=driver-toolkit
	EXTRA_LABELS := $(EXTRA_LABELS) --label=com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements\#DriverToolkit"
	EXTRA_LABELS := $(EXTRA_LABELS) --label=io.k8s.description="driver-toolkit is a container with the kernel packages necessary for building kernel modules/drivers"
	EXTRA_LABELS := $(EXTRA_LABELS) --label=io.k8s.display-name="Driver Toolkit"
	EXTRA_LABELS := $(EXTRA_LABELS) --label=summary="Provides a build environment for kernel modules/drivers"
	UNSET_LABELS = --unsetlabel=release
	UNSET_LABELS := $(UNSET_LABELS) --unsetlabel=url
endif

CONTAINER_TOOL ?= podman
CONTAINER_TOOL_EXTRA_ARGS ?=
BUILD_ARG_FILE ?=

AUTH_JSON ?=

SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct)
VCS_REF ?= $(shell git rev-parse HEAD)

ARCH ?= $(shell arch)

KERNEL_VERSION ?= $(shell skopeo inspect --format json docker://${BOOTC_IMAGE} | jq -r '.Labels["ostree.linux"]' | sed "s/\.${ARCH}//")

REGISTRY ?= quay.io
REGISTRY_ORG ?= smgglrs-ai
IMAGE_NAME ?= driver-toolkit
IMAGE_TAG ?= ${KERNEL_VERSION}
IMAGE ?= ${REGISTRY}/${REGISTRY_ORG}/${IMAGE_NAME}:${IMAGE_TAG}

ENABLE_RT ?=

.PHONY: default
default: build

.PHONY: build
build:
	echo "Building $(IMAGE)" ; \
	if [ "x${CENTOS_COMPOSE}x" != "xx" ] ; then \
		cp repos.tpl.d/$(DISTRO)/*.repo repos.d/ ; \
		for i in repos.d/*.repo ; do \
			sed -i "s/__CENTOS_COMPOSE__/$(CENTOS_COMPOSE)/g" $${i} ; \
		done ; \
	fi ; \
	"${CONTAINER_TOOL}" build \
		$(ARCH:%=--platform linux/%) \
		$(BUILD_ARG_FILE:%=--build-arg-file=%) \
		$(ENABLE_RT:%=--build-arg ENABLE_RC=%) \
		$(BASE_IMAGE:%=--build-arg BASE_IMAGE=%) \
		$(KERNEL_VERSION:%=--build-arg KERNEL_VERSION=%) \
		$(SOURCE_DATE_EPOCH:%=--timestamp=%) \
		$(VCS_REF:%=--build-arg VCS_REF=%) \
		$(EXTRA_LABELS) \
		$(UNSET_LABELS) \
		--volume $(shell pwd)/repos.d:/tmp/repos.d:ro,Z \
		--file Containerfile \
		--tag "${IMAGE}" \
		${CONTAINER_TOOL_EXTRA_ARGS} . ; \
	rm -f repos.d/*.repo

.PHONY: push
push:
	"${CONTAINER_TOOL}" push "${IMAGE}"

.PHONY: clean
clean:
	rm -rf build

.PHONY: all
all: clean build push
