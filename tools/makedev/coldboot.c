/*
 * Copyright (C) 2007 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This file is modified version of file in Android repository which is
 * located at system/core/init/devices.c
 */

#include <stdio.h>
#include <fcntl.h>
#include <dirent.h>

#include "devices.h"
#include "coldboot.h"

/* Coldboot walks parts of the /sys tree and pokes the uevent files
** to cause the kernel to regenerate device add events that happened
** before init's device manager was started
**
** We drain any pending events from the netlink socket every time
** we poke another uevent file to make sure we don't overrun the
** socket's buffer.  
*/

static void do_coldboot(DIR *d)
{
    struct dirent *de;
    int dfd, fd;

    dfd = dirfd(d);

    fd = openat(dfd, "uevent", O_WRONLY);
    if(fd >= 0) {
        write(fd, "add\n", 4);
        close(fd);
        handle_device_fd();
    }

    while((de = readdir(d))) {
        DIR *d2;

        if(de->d_type != DT_DIR || de->d_name[0] == '.')
            continue;

        fd = openat(dfd, de->d_name, O_RDONLY | O_DIRECTORY);
        if(fd < 0)
            continue;

        d2 = fdopendir(fd);
        if(d2 == 0)
            close(fd);
        else {
            do_coldboot(d2);
            closedir(d2);
        }
    }
}

void coldboot(const char *path)
{
    DIR *d = opendir(path);
    if(d) {
        do_coldboot(d);
        closedir(d);
    }
}

