# Driver Toolkit

The Driver Toolkit (DTK) is a container image which is meant to be used to
build out-of-tree kernel drivers.

The Driver Toolkit image 
[contains](https://github.com/openshift/driver-toolkit/blob/master/Dockerfile 
"contains") the kernel packages commonly required as dependencies to build or 
install kernel modules as well as a few tools needed in driver containers. The 
version of these packages will match the kernel version running on the machine.

Kernel modules and drivers are software libraries running with a high level of
privilege in the operating system kernel. They extend the kernel functionalities
or provide the hardware-specific code required to control new devices.  Examples
include hardware devices like FPGAs or GPUs, and software defined storage (SDS)
solutions like Lustre parallel filesystem, which all require kernel modules on
client machines.

The main benefits of DTK are that it provides a builder environment for
containerized supply chains and that it can be used to build kernel modules and 
drivers on the fly in a Kubernetes cluster.

The list of the packages installed in the `DTK` can be found in the 
[Dockerfile](./Dockerfile).

## How to build a Driver Toolkit image

> [!NOTE]
> To build a Driver Toolkit image for Red Hat Enterprise Linux (RHEL), we
> install packages that require a subscription. With podman on RHEL, the 
> entitlement of the host is passed to the containers, so it is recommended to 
> build the container on a RHEL machine.

> [!NOTE]
> The default container tool is `podman` and all the tests are run with it, so 
> if you choose another container tool, your experience may vary.

### Manual build of the container image

For convenience, we provide a Makefile that hides the steps to retrieve the 
build information and to pass the options to `podman build`. The main 
information we need is the Linux distribution (`fedora` (default), `centos` or
`redhat`). From this, we gather the kernel version from the `ostree.linux` label
on the current `bootc` image for the distribution.

Depending on the distribution, the base image has different labels and we need 
to override or unset some of them. The Makefile hides this and the final image 
only has labels for Driver Toolkit.

Below is an example for building a Driver Toolkit image CentOS Stream.

```shell
make DISTRO=centos
```

At the time of writing, the kernel version is `5.14.0-498.el9.x86_64`, so the 
resulting image will be `quay.io/centos/driver-toolkit:5.14.0-498.el9.x86_64`.

It is possible to override the image name with the following variables:

* `REGISTRY` replaces `quay.io`
* `REGISTRY_ORG` replaces `centos`
* `IMAGE_NAME` replaces `driver-toolkit`
* `IMAGE_TAG` replaces the kernel version

For that image to be usable for further builds, we simply push it. With the 
above example for CentOS Stream, the command is:

```shell
make push DISTRO=centos
```
