ARG BASE_IMAGE="quay.io/fedora/fedora:40"

FROM ${BASE_IMAGE}

ARG KERNEL_VERSION=''
ARG ENABLE_RT=''
ARG VCS_REF=''

USER root

RUN if test -z "${KERNEL_VERSION}" ; then \
      echo "The KERNEL_VERSION argument is mandatory. Exiting" ; \
      exit 1 ; \
    fi \
    && echo "Kernel version: ${KERNEL_VERSION}" \
    && if [ "$(ls -A /tmp/repos.d/)" ] ; then \
        echo "Adding or overriding repositories" ; \
        cp /tmp/repos.d/*.repo /etc/yum.repos.d/ ; \
    fi \
    && dnf -y install dnf-plugin-config-manager \
    && dnf config-manager --best --nodocs --setopt=install_weak_deps=False --save \
    && dnf -y update --exclude kernel* \
    && dnf -y install \
        kernel-${KERNEL_VERSION} \
        kernel-devel-${KERNEL_VERSION} \
        kernel-modules-${KERNEL_VERSION} \
        kernel-modules-extra-${KERNEL_VERSION} \
    && if [ "${ENABLE_RT}" ] && [ $(arch) == "x86_64" ]; then \
        dnf -y --enablerepo=rt install \
            kernel-rt-${KERNEL_VERSION} \
            kernel-rt-devel-${KERNEL_VERSION} \
            kernel-rt-modules-${KERNEL_VERSION} \
            kernel-rt-modules-extra-${KERNEL_VERSION}; \
    fi \
    && export INSTALLED_KERNEL=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-core-${KERNEL_VERSION}) \
    && export GCC_VERSION=$(cat /lib/modules/${INSTALLED_KERNEL}/config | grep -Eo "gcc \(GCC\) ([0-9\.]+)" | grep -Eo "([0-9\.]+)") \
    && dnf -y install \
        binutils \
        diffutils \
        elfutils-libelf-devel \
        jq \
        kabi-dw \
        kernel-abi-stablelists \
        keyutils \
        kmod \
        gcc-${GCC_VERSION} \
        git \
        make \
        mokutil \
        openssl \
        pinentry \
        rpm-build \
        xz \
    && dnf clean all \
    && useradd -u 1001 -m -s /bin/bash builder

USER builder

LABEL description="driver-toolkit is a container with the kernel packages necessary for building kernel modules/drivers" \
      name="driver-toolkit" \
      org.opencontainers.image.name="driver-toolkit" \
      org.opencontainers.image.version="${KERNEL_VERSION}" \
      vcs-ref="${VCS_REF}" \
      version="${KERNEL_VERSION}"
