#include <unistd.h>
#include <stdlib.h>
#include <libgen.h>
#include <stdio.h>
#include <time.h>
#include <poll.h>

#include "util.h"
#include "devices.h"
#include "coldboot.h"
#include "main.h"

char * app_name = NULL;
struct main_args app_args;

static int is_done = FALSE;

/* == UTILS == */

static inline int check_dev (const char *path, int is_done_val)
{
	if (strcmp (path, app_args.file) == 0)
	{
		is_done = is_done_val;
		return TRUE;
	}
	
	return FALSE;
}

void mkdev_link (const char *oldpath, const char *newpath)
{
	if (!check_dev (newpath, TRUE)) return;
	
	make_link (oldpath, newpath);
	MSG_TRACE ("created link: %s => %s", oldpath, newpath);
}

void mkdev_node (const char *path, int block, int major, int minor)
{
	mode_t mode;
	
	if (!check_dev (path, TRUE)) return;
	
	mode = 0600 | (block ? S_IFBLK : S_IFCHR);
	make_node (path, mode, makedev (major, minor));
	
	MSG_TRACE ("created node: %s (maj: %i, min: %i)", path, major, minor);
}

void rmdev (const char *path)
{
	if (!check_dev (path, FALSE)) return;
	
	unlink (path);
	MSG_TRACE ("removed: %s", path);
}

/* == REAL MAIN == */

int app_main (void)
{
	struct timespec ts_b, ts;
	struct pollfd ufd;
	long ms1, ms2, ms;
	int nr = -1;
	
	clock_gettime (CLOCK_MONOTONIC, &ts_b);
	
	device_init ();
	
	IF_ARG_BIT (BIT_COLDBOOT)
	{
		coldboot("/sys/class");
		coldboot("/sys/block");
		coldboot("/sys/devices");
		
		MSG_TRACE ("coldboot is done");
	}
	
	ufd.events = POLLIN;
	ufd.fd = get_device_fd ();
	
	while (!is_done)
	{
		clock_gettime (CLOCK_MONOTONIC, &ts);
		
		ms1 = (ts.tv_sec - ts_b.tv_sec) * 1e3;
		ms2 = (ts.tv_nsec - ts_b.tv_nsec) / 1e6;
		ms = app_args.timeout - (ms1 + ms2);
		
		if (ms <= 0)
		{
			MSG_TRACE ("timeout exceeded (%ld ms)", ms);
			return EXIT_FAILURE;
		}
		
		MSG_DEBUG ("poll() for %ld ms", ms);
		
		ufd.revents = 0;
		nr = poll (&ufd, 1, ms);
		
		if (nr <= 0)
		{
			MSG_TRACE ("timeout exceeded");
			return EXIT_FAILURE;
		}
		
		if (ufd.revents & POLLIN) handle_device_fd ();
	}
	
	return EXIT_SUCCESS;
}

int main (int argc, char **argv)
{
	int c = -1;
	
	app_name = basename (argv[0]);
	
	app_args.bits = 0;
	app_args.timeout = 5e3;
	app_args.file = NULL;
	
	// Parse parameters.
	
	while ((c = getopt (argc, argv, "cqdvt:")) != -1)
	{
		switch (c)
		{
		case 'c':
			app_args.bits = app_args.bits | BIT_COLDBOOT;
			break;
		case 'q':
			app_args.bits = app_args.bits & ~BIT_MSG;
			break;
		case 'd':
			app_args.bits = app_args.bits | BIT_MSG_DEBUG | BIT_MSG_VERBOSE;
			break;
		case 'v':
			app_args.bits = app_args.bits | BIT_MSG_VERBOSE;
			break;
		case 't':
			app_args.timeout = atoi (optarg) * 1e3;
			break;
		case '?':
			goto parse_usage;
		}
	}
	
	c = argc - optind;
	if (c < 1)
	{
		MSG_ERR ("missing dev-to-watch parameter");
		goto parse_usage;
	}
	else if (c > 1)
	{
		MSG_ERR ("excess parameter detected");
		goto parse_usage;
	}
	
	app_args.file = argv[optind];
	if (strncmp (app_args.file, "/dev/", 5) != 0)
	{
		MSG_ERR ("dev-to-watch must be started with /dev");
		goto parse_usage;
	}
	
	// Enter application.
	
	return app_main ();
	
parse_usage:
	PUT_ERR ("Usage: %s [-d|-v|-q] [-c] [-t timeout] dev-to-watch", app_name);
	return EXIT_FAILURE;
}

