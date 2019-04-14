// HOSTSPEC is defined at compile time, see APKBUILD

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <libgen.h>
#include <errno.h>
#include <limits.h>
#include <unistd.h>

#define NATIVE_BIN_DIR "/native/usr/lib/ccache/bin"

void exit_userfriendly() {
	fprintf(stderr, "Please report this at: https://gitlab.com/postmarketOS/pmaports/issues\n");
	fprintf(stderr, "As a workaround, you can compile without crossdirect.\n");
	fprintf(stderr, "See 'pmbootstrap -h' for related options.\n");
	exit(1);
}

bool argv_has_arg(int argc, char** argv, const char* arg) {
	size_t arg_len = strlen(arg);

	for (int i=1; i < argc; i++) {
		if (strlen(argv[i]) < arg_len)
			continue;

		if (!memcmp(argv[i], arg, arg_len))
			return true;
	}
	return false;
}

int main(int argc, char** argv) {
	// we have a max of four extra args ("-target", "HOSTSPEC", "--sysroot=/", "-Wl,-rpath-link=/lib:/usr/lib"), plus one ending null
	char* newargv[argc + 5];
	char* executableName = basename(argv[0]);
	char newExecutable[PATH_MAX];
	bool isClang = (strcmp(executableName, "clang") == 0 || strcmp(executableName, "clang++") == 0);
	bool startsWithHostSpec = (strncmp(HOSTSPEC, executableName, sizeof(HOSTSPEC) -1) == 0);

	// linker is involved: just use qemu binary (to avoid broken cross-ld, pmaports#227)
	if (!argv_has_arg(argc, argv, "-c")) {
		snprintf(newExecutable, sizeof(newExecutable), "/usr/bin/%s", executableName);
		if (execv(newExecutable, argv) == -1) {
			fprintf(stderr, "ERROR: crossdirect: failed to execute %s: %s\n", newExecutable, strerror(errno));
			fprintf(stderr, "NOTE: this is a foreign arch binary that would run with qemu (linker is involved).\n");
			exit_userfriendly();
		}
	}

	if (isClang || startsWithHostSpec) {
	   snprintf(newExecutable, sizeof(newExecutable), NATIVE_BIN_DIR "/%s", executableName);
	} else {
	   snprintf(newExecutable, sizeof(newExecutable), NATIVE_BIN_DIR "/" HOSTSPEC "-%s", executableName);
	}

	char** newArgsPtr = newargv;
	*newArgsPtr++ = newExecutable;
	if (isClang) {
		*newArgsPtr++ = "-target";
		*newArgsPtr++ = HOSTSPEC;
	}
	*newArgsPtr++ = "--sysroot=/";

	memcpy(newArgsPtr, argv + 1, sizeof(char*)*(argc - 1));
	newArgsPtr += (argc - 1);
	*newArgsPtr = NULL;

	// new arguments prepared; now setup environmental vars
	char* env[] = {"LD_PRELOAD=",
		"LD_LIBRARY_PATH=/native/lib:/native/usr/lib",
		"CCACHE_PATH=/native/usr/bin",
		NULL};
	char* ldPreload = getenv("LD_PRELOAD");
	if (ldPreload) {
		if (strcmp(ldPreload, "/usr/lib/libfakeroot.so") == 0) {
			env[0] = "LD_PRELOAD=/native/usr/lib/libfakeroot.so";
		} else {
			fprintf(stderr, "ERROR: crossdirect: can't handle LD_PRELOAD: %s\n", ldPreload);
			exit_userfriendly();
		}
	}

	if (execve(newExecutable, newargv, env) == -1) {
		fprintf(stderr, "ERROR: crossdirect: failed to execute %s: %s\n", newExecutable, strerror(errno));
		fprintf(stderr, "Maybe the target arch is missing in the ccache-cross-symlinks package?\n");
		exit_userfriendly();
	}
	return 1;
}
