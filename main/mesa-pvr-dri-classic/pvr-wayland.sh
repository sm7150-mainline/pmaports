#!/bin/sh

# We need to explicitly set driver to pvr for the newer mesa, else it tries to find omapdrm
export MESA_LOADER_DRIVER_OVERRIDE=pvr
