// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * Reboot the device to a specific mode
 *
 * Copyright (C) 2019 Daniele Debernardi <drebrez@gmail.com>
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <linux/reboot.h>

void usage(char* appname)
{
	printf("Usage: %s [-h] MODE\n\n", appname);
	printf("Reboot the device to the MODE specified (e.g. recovery, bootloader)\n\n");
	printf("WARNING: the reboot is instantaneous\n\n");
	printf("optional arguments:\n");
	printf("  -h    Show this help message and exit\n");
}

int main(int argc, char** argv)
{
	if (argc != 2)
	{
		usage(argv[0]);
		exit(1);
	}

	int opt;
	while ((opt = getopt(argc, argv, "h")) != -1)
	{
		switch (opt)
		{
		case 'h':
		default:
			usage(argv[0]);
			exit(1);
		}
	}

	sync();

	int ret;
	ret = syscall(__NR_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, LINUX_REBOOT_CMD_RESTART2, argv[1]);

	if (ret) {
		printf("Error: %s", strerror(ret));
	}

	return ret;
}
