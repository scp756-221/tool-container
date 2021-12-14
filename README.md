# Files for building CMPT 756 toolset image

`Makefile` specifies the operations for building, pushing,
and publishing the image for both AMD64 and ARM64 architectures,
together with their combined manifest. The manifest associates the 
two images together under one tag for simplicity. I.e., users can
refer to the image uniformly without specifying the architecture explicitly 
(`docker pull ghcr.io/scp756-221/c756-tool:v1.0` instead of `docker pull ghcr.io/scp756-221/c756-tool:v1.0-arm64`. or `-amd64`)
and Docker will pick the appropriate architecture as appropriate. 

`Dockerfile` specifies how to build an image on one of
the two architectures.

## Steps to build and publish an image

The image must be built twice, once on each
architecture, with `TARGET_ARCH` set appropriately. Most of the time,
you will want to use the helper scripts described in the next section
rather than call `make` directly.

   ~~~
   TARGET_ARCH=amd
   TARGET_ARCH=arm
   ~~~

The steps (run on each architecture):

1. Build the basic image

   ~~~
   make TARGET_ARCH= ... build
   ~~~

2. Push the development version to the development registry

   ~~~
   make TARGET_ARCH= ... dev
   ~~~

4. Once *both* architectural images have been pushed to the
   development registry, push the combined manifest to the registry
   (note that although you specify an architecture to satisfy the
   Makefile, it is ignored because this command is run once and can be
   run on either architecture):

   ~~~
   make TARGET_ARCH= ... manifest
   ~~~

5. Once the image is ready for student use, push the public image:

   ~~~
   make TARGET_ARCH= ... sfu
   ~~~

6. Once *both* architectural images have been pushed to the public
   registry, push the combined manifest to the registry (note that
   although you specify an architecture to satisfy the Makefile, it is
   ignored because this command is run once and can be run on either
   architecture):

   ~~~
   make TARGET_ARCH= ... public-manifest
   ~~~

## Helper scripts

This repo includes a set of simple scripts to reduce the complexity of
specifying all the parameters on two different architectures.

### Parameter files

The scripts rely on several parameter files that each user must
create:

* `version.txt`: Version of the current image. Does not include the
   architecture. Example: `v1.0beta3`.

* `regid.txt`: Id to which the image will be pushed in the development
  registry.  The development registry is specified in `Makefile`. This
  id overrides the `REGID` variable in `Makefile`. Example:
  `bigcoder`.

* `iname.txt`: The name of the image in the development
  registry. Overrides the `INAME` variable in `Makefile`. Example:
  `c756-tool`.

* `ec2-pem-path.txt`: The (absolute or relative) path to the file
  containing the `.pem` file specifying the key for signing on to the
  EC2 instances. Example: `~/Documents/Security/Nov2021.pem`.

* `code-path.txt`: The *absolute* path to the top level of the course
  code. Example: `/Users/joe/Documents/Course/scp-756-211/sfu-cmpt756.211`.

* `token-path.txt`: The *absolute* path to the personal access tokens
  for the development image registry. Example:
  `/Users/joe/Documents/Security/tokens`. This is only used when
  running on an EC2 ARM instance.

* `ec2-ghcr-token.txt`: Located at the path in `token-path.txt`, this
  file contains an access token for `ghcr.io`. This is only used when
  running on an EC2 ARM instance.

These parameter files and scripts are only used when building
development versions of the images. Call `make` directly when building
an image to be published for students.

### Building for AMD architectures

For AMD architectures, the scripts assume that you are building on
your own machine and running from a directory containing this
repository. No special preparation is required.

The scripts do not require any special privileges when run on your own
machine. They presume that your install of the `docker` command-line
tools do not require `sudo` privilege.

### Building for ARM architectures

For ARM architectures, the scripts assume that you are signing in to a
fresh EC2 Graviton instance running Ubuntu 20.04. All scripts have
been tested on an `t4g.medium` instance with default RAM and storage
sizes. Cheaper instances may also work but the scripts have not been
tested on them.

Start with the scripts to transfer all the necessary files to
that instance and set it up:

1. `signon.sh EC2-INSTANCE_NAME`: Signs in to the EC2 instance and
   stores the name in `ec2-instance-name.txt` for later use by
   `transfer.sh` and `second-signon.sh`. Do not include the user name
   in the instance name; it is assumed to be `ubuntu` in all the
   scripts.

   The EC2 instance must use the SSH key whose path is specified in
   `ec2-pem-path.txt`.

   Example: `./signon.sh ec2-35-86-216-234.us-west-2.compute.amazonaws.com`

4. `send-to-arm.sh` (run on home machine): Transfers all the
   necessary files from your machine to the *home* directory on the
   EC2 instance. `setup-on-arm.sh` will move the transferred files to
   the correct directory on the EC2 instance.

   **Security note:** This script transfers your confidential access
   tokens for AWS and the development image registry to the EC2
   instance. These are required for the `aws` CLI commands and `docker
   image push` commands to work, respectively.

5. `setup-on-arm.sh` (run on remote EC2 instance): After all the
   files have been transferred to the EC2 instance, run this command
   to complete the setup. It installs the necessary packages, clones
   the course code repository, and does related setup.

Support scripts called by `setup-on-arm.sh`. You do not normally need
to call these, as they are called by `setup-on-arm.sh`.:

* `install-docker-on-arm.sh`: Installs docker. Must be called under `sudo`.
* `docker-ec2-login-ghcr.sh`: Logs in to `ghcr.io` using the token in
  file `ec2-ghcr-token.txt ` at path in file `token-path.txt`. Must be
  called under `sudo`.

Useful scripts to handle other situations:

1. `second-signon.sh`: Signs in to the EC2 instance any time after
   `signon.sh` has been used.  No parameter required as the instance
   name in `ec2-instance-name.txt` is used.

   A primary use case for this script is when managing a cluster from
   an EC2 instance, you will want to CLI sessions to the instance. One
   session will be to issue commands, such as `make -f k8s.mak
   provision`, while the other will run `k9s` to observe the results.

2. `transfer.sh PATH`: Transfers a file from *any* directory in your
   current machine to the *home* directory on the EC2 instance named
   in `ec2-instance-name.txt`. Often, you will need to then move the
   file to the desired directory on the EC2 instance.

   A primary use case for this script is when you discover a bug in
   one of the scripts / Makefile / Dockerfile while testing on an EC2
   instance. The preferred solution is to make the edit on your own
   machine and then use `transfer.sh` to refresh the value on the EC2
   instance. This ensures that the edit is not lost when the EC2
   instance is terminated.

   Example: `./transfer.sh ../test_script.txt` 

Then you build the image according to the instructions in the next
section.

### Building a development image

Once the current machine is set up (if necessary), run the following
scripts to build and push a development image.  Note that all calls to
`docker` in the ARM scripts (but not in the AMD scripts) are prefixed
by `sudo` because the default Docker install on Ubuntu requires `sudo`
privileges.

1. `build-on-amd.sh` and `build-on-arm.sh` (no parameters): Build a
   development image with the current version tag.

2. Test the new image by running it. First, `cd` to the `e-k8s` directory of
   the code repo. Then:

   * On a local amd machine, run `run-on-amd.sh`. This script requires
     the shell variable `VAR_HOME` to be set, defining the path to a
     directory containing the `version.txt` file.
     If you just want to use the image version specified in
     `Makefile`, you can run `tools/shell.sh` without an argument.
   * On a remote arm machine, run `run-on-arm.sh`. No shell variable
     is required for this---`version.txt` is assumed to be in the home
     directory, where it is placed by `send-to-arm.sh`

   Once in the container, a simple test of whether the build completed
   is to run `k9s`. There will be no cluster for it to connect to but
   if it starts up, that indicates that most of the build is correct.

   A full test requires the complete sequence to spin up, provision,
   and load test a cluster, which takes upwards of a half hour.
   See `test_script.txt` for instructions on doing a full test.

3. `push-dev-on-amd.sh` and `push-dev-on-arm.sh` (no parameters): Push
   the development image to the development image registry.

4. `build-manifest.sh` (no parameters): After both development images
   have been pushed to the development image registry, run this to
   build a combined manifest. This only needs to be run once for each
   new version and can be run on either architecture.

## Building a public image

An image for public release to students is typically just another name
for a development image that has passed testing and is ready for
use by the class. In this case, "building" is simply a matter of
assigning an additional tag to the existing development image and
pushing that image to the container registry. This will have to be
done once for each architecture.

On an amd machine, assuming the current defaults for `PUBCREG` and
`PUBREGID` in `Makefile`, the command typically would be:

~~~
$ docker image tag ghcr.io/REGID/INAME:VER-amd64 ghcr.io/scp756-221/c756-tool:VER-amd64
$ docker push ghcr.io/scp756-221/c756-tool:VER-amd64
~~~

And on an arm machine:

~~~
$ docker image tag ghcrio.io/REGID/INAME:VER-arm64 ghcr.io/scp756-221/c756-tool:VER-arm64
$ docker push ghcr.io/scp756-221/c756-tool:VER-arm64
~~~

Where:

* `REGID` is the contents of `regid.txt`
* `INAME` is the contents of `iname.txt`
* `VER` is the contents of `version.txt`

After these steps, build a combined manifest for the public image (see
next section).

## Publishing a combined manifest (development or public image)

Once images have been built for both architectures, a combined
manifest must be created on the container registry (currently
`ghcr.io`).  This combined manifest links the two images in that
registry, allowing clients to send an architecture-independent image
tag and have the registry return the image appropriate to the client's
OS and architecture. Our builds currently only support two such
combinations, Linux/amd64 and Linux/arm64.

As a prerequisite, the combined manifest can only be created after
both images have been pushed to the registry with the same name and
version, with the appropriate architecture appended, as requested for
the manifest. If at least one of the prerequisite images is missing,
you will get a `manifest unknown` message. Note that the images must
have been pushed to the registry---their presence or absence on the
local machine is irrelevant.

**Development version:** Use the `build-manifest.sh` script to create
  a combined manifest.

**Public version:** There is no helper script for creating the public
manifest but typically the defaults in the Makefile will be
correct. A command such as the following is usually enough:

~~~
make TARGET_ARCH=amd VER=... public-manifest
~~~

The `TARGET_ARCH` parameter is required to be either `amd` or `arm`
but is otherwise ignored.  The `VER` parameter must match whatever was
used for the two images.
