#!/bin/sh -e

if [ -n "$CROSSDIRECT_DEBUG" ]; then
	set -x
fi

# return the correct host architecture when cargo requests it
if [ "$*" = "-vV" ]; then
	exec /usr/bin/rustc -vV
fi

# We expect the right target to be set in the arguments if compiling for the
# target architecture. Our cargo wrapper passes the right "--target" argument
# automatically. If no target is provided, this is probably a macro or a
# build script, so it should be compiled for the native architecture.
if echo "$*" | grep -qFe "--target"; then
	LD_LIBRARY_PATH=/native/lib:/native/usr/lib /native/usr/bin/rustc \
		-Clinker=/native/usr/lib/crossdirect/rust-qemu-linker \
		--sysroot=/usr \
		"$@"
else
	PATH=/native/usr/bin:/native/bin LD_LIBRARY_PATH=/native/lib:/native/usr/lib \
		/native/usr/bin/rustc \
		-Clink-arg=-Wl,-rpath,/native/lib:/native/usr/lib \
		"$@"
fi
