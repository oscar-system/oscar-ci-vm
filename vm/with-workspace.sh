#!/bin/sh
export WORKSPACE="$HOME/jenkins/jobs/$1/workspace"
export JULIA_PROJECT="$WORKSPACE/julia-env"
export JULIA_DEPOT_PATH="$WORKSPACE/julia-env"
export PATH="$WORKSPACE/local/bin:$PATH"
cd "$WORKSPACE"
exec $SHELL
