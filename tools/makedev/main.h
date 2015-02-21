/* main.h */

#ifndef __MAIN_H
#define __MAIN_H

#include <stdio.h>

#define ERROR(x...)   fprintf(stderr, x)
#define NOTICE(x...)  fprintf(stderr, x)
#define INFO(x...)    fprintf(stderr, x)

#define TRUE (1==1)
#define FALSE (!TRUE)

struct arguments
{
	int timeout;
	char *file;
};

void mkdev_link (const char *oldpath, const char *newpath);
void mkdev_node (const char *path, int block, int major, int minor);

void rmdev (const char *path);

#endif	/* __MAIN_H */

