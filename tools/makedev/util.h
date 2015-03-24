/*
 * Copyright (C) 2010 The Android Open Source Project
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
 * located at system/core/init/util.h
 */

#ifndef _INIT_UTIL_H_
#define _INIT_UTIL_H_

#include <sys/stat.h>
#include <sys/types.h>

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

int mkdir_recursive(const char *pathname, mode_t mode);
void sanitize(char *p);
void make_link(const char *oldpath, const char *newpath);
void remove_link(const char *oldpath, const char *newpath);
int make_dir(const char *path, mode_t mode);

/* Custom utilities. */

void make_node(const char *path, mode_t mode, dev_t dev);

#endif

