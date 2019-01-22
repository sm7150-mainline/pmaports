/*
 * Copyright 2019 Attila Szollosi
 *
 * This file is part of postmarketos-android-recovery-installer.
 *
 * postmarketos-android-recovery-installer is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * postmarketos-android-recovery-installer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with postmarketos-android-recovery-installer.  If not, see <http:www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <fcntl.h>
#include <dirent.h>

void close_FDs()
{
    unsigned int fd;
    struct dirent* ep;
    DIR* dp = opendir("/proc/self/fd");
    if (dp != NULL) {
        // first two entries are . and ..
        readdir(dp);
        readdir(dp);

        while (ep = readdir(dp))
            if (sscanf(ep->d_name, "%u", &fd) != EOF)
                close(fd);
        closedir(dp);
    } else {
        // try to close all file descriptors by brute-force
        // in case the list of open FDs could not be read
        // from the procfs
        for (fd = 256; fd >= 0; fd--)
            close(fd);
    }
}

// Detach the program from the installation script
void daemonize()
{
    pid_t pid;

    pid = fork();
    if (pid < 0)
        exit(1);
    if (pid > 0)
        exit(0);

    if (setsid() < 0)
        exit(1);

    pid = fork();
    if (pid < 0)
        exit(1);
    if (pid > 0)
        exit(0);

    umask(0);
    chdir("/");
    close_FDs();
}

// Workaround to disable No OS warning in TWRP
// See: https://gitlab.com/postmarketOS/pmbootstrap/issues/1451
//
// Works by setting the variable tw_backup_system_size to a large
// value, so TWRP's check
// (tw_backup_system_size < tw_min_system) will result in
// false.
//
// TWRP doesn't allow issuing OpenRecoveryScript commands while
// the installation is running, so we have to daemonize the
// process to change the value after the installation script
// exited.
int main()
{
    daemonize();

    int orsin, orsout;

    char command[1024];
    char result[512];

    char* commands[] = {"set tw_backup_system_size 999",
                        "set tw_app_prompt 0"};

    sleep(4);

    int i;
    for (i = 0; i < sizeof(commands)/sizeof(char*); i++) {
        if ((orsin = open("/sbin/orsin", O_WRONLY)) == -1)
            return 1;
        strcpy(command, commands[i]);
        write(orsin, command, sizeof(command));
        close(orsin);

        // Have to read FIFO file, because it blocks
        // the thread processing the command
        // (see man 3 mkfifo)
        if ((orsout = open("/sbin/orsout", O_RDONLY)) == -1)
            return 1;
        read(orsout, result, sizeof(result));
        close(orsout);

        sleep(3);
    }

    return 0;
}
