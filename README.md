# Multipass VM setup for Oscar CI

This setup uses [Multipass](https://multipass.run/) to setup a local
VM for the Oscar CI system with a single shell command and allows
easy (re)configuration of jobs from the command line also.

It also has the option to run builds and tests within the VM outside
a docker environment. As a Multipass VM is a fully functioning Linux
system, this allows normal debugging from within the VM.

# Requirements

In order to use this, you must have Multipass installed. There are
official versions for Linux, macOS, and Windows.

# Usage

From within this directory, simply run:

    ./create-vm oscar-ci.yaml

This can take a few minutes, as this will provision a new Linux VM
and install a number of essential packages.

The `oscar-ci.yaml` file specifies the VM and Jenkins setup. The `vm`
section species the VM parameters, the `jenkins` sections specifies
the default user and password entries for the admin user, the `jobs`
section specifies any jobs you may want to preconfigure.

Current practical minimum requirements for the VM are 6GB of memory and
16GB of disk space, though the defaults are somewhat higher to leave
room for unexpected circumstances.

All commands take a `.yaml` file that describes the VM and Jenkins
configuration as an argument. While `oscar-ci.yaml` has useful default
settings, you can also create your own one and use that instead.

Once this process is complete, you can run:

    multipass list

to see the Multipass instances. The instance will be depicted with
its chosen name, status, and local IP address. The instance is not
publicly visible, but from your local computer, you can connect to
that address.

As a next step, execute:

    ./run-jenkins oscar-ci.yaml

This will start up jenkins. You can open a Jenkins session by running:

    ./webview oscar-ci.yaml

By default, both user and password are "jenkins" (see the entries in
`oscar-ci.yaml`).

SECURITY NOTE: If you are making this instance publicly available (by
default it can only be accessed from the computer you are running it
on), you need to change the password.

In order to start a job, click on the job item in the job list, then
click on "Build with parameters" in the menu on the left hand side and
then on the "Build" button.

NOTE: It is possible that the job stops during the "Preparation" stage
while trying to download from GitHub due to GitHub rate-limiting or
throttling requests (especially from residential IPs with CGNat). In
that case, please repeat the process until the job is past the
preparation stage.

# Creating and changing jobs from the command line

You can change the existing Job settings or add new jobs via the
`./reconf-jobs` script. For that, modify the jobs in the `oscar-ci.yaml`
file or add a new one, then run:

    ./reconf-jobs oscar-ci.yaml

Note that it may be a good idea not to modify `oscar-ci.yaml`. In that
case, copy `oscar-ci.yaml` to e.g. `my-ci.yaml`, then modify that and
run:

    ./reconf-jobs my-ci.yaml

# Inspecting the system

You can use

    multipass shell oscar-ci

(or whatever the name of the instance is in lieu of `oscar-ci` if you
changed it) to start a shell within the VM. This will log you in as
the `ubuntu` user. This user has full sudo permissions, so you can for
example install additional packages via `sudo apt install <pkgname>`.

The configuration of a Jenkins job can be found at:

    ~/jenkins/jobs/<jobname>

Of particular interest may be the workspace, which is at:

    ~/jenkins/jobs/<jobname>/workspace

The Julia environment can be found within the `julia-env` subdirectory
of the workspace, the `julia` implementation within `julia`
subdirectory. In order to start `julia` as the test runner sees it,
cd to the workspace and run:

    export JULIA_PROJECT=$PWD/julia-env
    export JULIA_DEPOT_PATH=$PWD/julia-env
    julia/bin/julia

It is then possible to run e.g. package tests from within that precise
environment. For convenience, there is also a `with-workspace` command,
which takes the name of a job as its argument which will set up the
necessary environment variables and starts a new shell inside the
workspace directory, e.g.:

    with-workspace oscar

You can use the `multipass transfer` command to copy files to and from
the VM. There is also a `multipass mount` command to mount arbitrary
directories from within the VM, but for that to work cleanly, you need
to specify a uid/gid mapping. For your convenience, there is a
`./mount-vm` script that takes care of it for you. Example usage:

    ./mount-vm oscar-ci.yaml ~ /mnt/my_home_directory

Jenkins can also be started from within the VM, e.g. from within a tmux
or screen session. For that, you can run

    ~/oscar-ci/bin/jenkins-nosetup

from a `multipass shell` session. In fact, the `run-jenkins` command
does basically that.

# Alternative CI configurations and package testing in a CI context

By changing the Jenkinsfile location for a job (either via the UI or
by adapting the `oscar-ci.yaml` entry for that job), one can test
with different configurations.

Relevant steps:

* Clone or fork `https://github.com/oscar-system/oscar-ci` to where
  you can modify it and the CI server can access it.
* Point the Jenkins configuration to the Jenkinsfile in that clone or
  fork as described above.
* The modified Jenkinsfile must itself be changed so that the `metarepo`
  variable points to the modified oscar-ci repository.

Optional:

* In order to test a specific version of an Oscar package, change
  the `packages.jl` file in the modified oscar-ci repository by
  adding an entry to the `locations` variable that points to the
  new package spec. The `locations` variable contains overrides for
  how to find a package and will be used in all circumstances.

# Managing the VM

You can use the usual multipass commands (such as `multipass start`,
`multipass stop`, `multipass shell`, `multipass delete` and `multipass
purge`) to manage the VM. There are also `./start-vm` and `./stop-vm`
scripts that take a YAML spec file as an argument (same as the other
commands) to start or stop this specific VM.

Please keep in mind that with Multipass, a VM will stay around (and
consume disk space) even after deletion. To really remove the VM
from your system, you also need to issue the `multipass purge` command,
which will actually remove deleted VMs.

Example:

    multipass delete oscar-ci
    multipass purge

Similarily, do not forget to stop a running VM that you currently don't
need so that it doesn't take up memory and CPU resources on your system.

# Known issues

The current non-dockerized setup has issues with dealing with Jupyter.
