// HOSTSPEC is defined at compile time, see APKBUILD

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <libgen.h>
#include <errno.h>
#include <limits.h>
#include <unistd.h>

void exit_userfriendly() {
	fprintf(stderr, "Please report this at: https://gitlab.com/postmarketOS/pmaports/issues\n");
	fprintf(stderr, "As a workaround, you can compile without crossdirect.\n");
	fprintf(stderr, "See 'pmbootstrap -h' for related options.\n");
	exit(1);
}

int main(int argc, char** argv) {
	// we have a max of four extra args ("-target", "HOSTSPEC", "--sysroot=/", "-Wl,-rpath-link=/lib:/usr/lib"), plus one ending null
	char* newargv[argc + 5];
	char* executableName = basename(argv[0]);
	char newExecutable[PATH_MAX];
	bool isClang = (strcmp(executableName, "clang") == 0 || strcmp(executableName, "clang++") == 0);
	bool startsWithHostSpec = (strncmp(HOSTSPEC, executableName, sizeof(HOSTSPEC) -1) == 0);

	if (isClang || startsWithHostSpec) {
	   snprintf(newExecutable, sizeof(newExecutable), "/native/usr/bin/%s", executableName);
	} else {
	   snprintf(newExecutable, sizeof(newExecutable), "/native/usr/bin/" HOSTSPEC "-%s", executableName);
	}

	char** newArgsPtr = newargv;
	*newArgsPtr++ = newExecutable;
	if (isClang) {
		*newArgsPtr++ = "-target";
		*newArgsPtr++ = HOSTSPEC;
	}
	*newArgsPtr++ = "--sysroot=/";
	bool addrpath = true;
	if (isClang) {
		// clang gives a warning if the rpath parameter is passed when linker isn't invoked.
		// to avoid this warning, only add if we're actually linking at least one library.
		addrpath = false;
		for (int i = 1; i < argc; i++) {
			char* arg = argv[i];
			if (strlen(arg) >= 2 && arg[0] == '-' && arg[1] == 'l') {
				addrpath = true;
				break;
			}
		}
	}
	if (addrpath) {
		*newArgsPtr++ = "-Wl,-rpath-link=/lib:/usr/lib";
	}
	memcpy(newArgsPtr, argv + 1, sizeof(char*)*(argc - 1));
	newArgsPtr += (argc - 1);
	*newArgsPtr = NULL;

	// new arguments prepared; now setup environmental vars
	setenv("LD_LIBRARY_PATH", "/native/lib:/native/usr/lib", true);
	char* ldPreload = getenv("LD_PRELOAD");
	if (ldPreload) {
		if (strcmp(ldPreload, "/usr/lib/libfakeroot.so") == 0) {
			setenv("LD_PRELOAD", "/native/usr/lib/libfakeroot.so", true);
		} else {
			fprintf(stderr, "ERROR: crossdirect: can't handle LD_PRELOAD: %s\n", ldPreload);
			exit_userfriendly();
		}
	}

	if (execv(newExecutable, newargv) == -1) {
		fprintf(stderr, "ERROR: crossdirect: failed to execute %s: %s\n", newExecutable, strerror(errno));
		exit_userfriendly();
	}
	return 1;
}
