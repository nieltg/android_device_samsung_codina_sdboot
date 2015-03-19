/* main.h */

#ifndef __MAIN_H
#define __MAIN_H

#include <stdio.h>

#define TRUE  (1==1)
#define FALSE (!TRUE)

// Argument processing section.

struct main_args
{
	int bits;
	long timeout;
	char * file;
};

extern char * app_name;
extern struct main_args app_args;


#define BIT_MSG_DEBUG   (1 << 0)
#define BIT_MSG_VERBOSE (1 << 1)
#define BIT_COLDBOOT    (1 << 2)
#define BIT_MSG (BIT_MSG_DEBUG | BIT_MSG_VERBOSE)

#define IS_ARG_BIT(x) (app_args.bits & (x))
#define IF_ARG_BIT(x) if (IS_ARG_BIT (x))

// Debugging messages section.

#define STD_ERR(f, a...) fprintf (stderr, f, ##a)
#define PUT_ERR(f, a...) STD_ERR (f "\n", ##a)

#define MSG(fmt, a...)    PUT_ERR ("%s: " fmt, app_name, ##a)
#define MSG_NL(fmt, a...) STD_ERR ("%s: " fmt, app_name, ##a)

#define MSG_DEBUG(f, a...) IF_ARG_BIT (BIT_MSG_DEBUG)   MSG (f, ##a)
#define MSG_TRACE(f, a...) IF_ARG_BIT (BIT_MSG_VERBOSE) MSG (f, ##a)
#define MSG_WARN(f, a...)  MSG ("warn:" f, ##a)
#define MSG_ERR(f, a...)   MSG (f, ##a)

// Function definitions.

void mkdev_link (const char *oldpath, const char *newpath);
void mkdev_node (const char *path, int block, int major, int minor);

void rmdev (const char *path);

#endif	/* __MAIN_H */

