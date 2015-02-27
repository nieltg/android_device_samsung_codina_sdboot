#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <poll.h>

#include "util.h"
#include "devices.h"
#include "main.h"

static struct arguments arg;
static int is_done = FALSE;

/* == UTILS == */

void mkdev_link (const char *oldpath, const char *newpath)
{
	if (strcmp (newpath, arg.file) != 0)
		return;
	
	make_link (oldpath, newpath);
	is_done = TRUE;
}

void mkdev_node (const char *path, int block, int major, int minor)
{
	mode_t mode;
	
	if (strcmp (path, arg.file) != 0)
		return;
	
	mode = 0600 | (block ? S_IFBLK : S_IFCHR);
	
	make_node (path, mode, makedev (major, minor));
	is_done = TRUE;
}

void rmdev (const char *path)
{
	if (strcmp (path, arg.file) != 0)
		return;
	
	unlink (path);
}

/* == REAL MAIN == */

int parse_args (int argc, char **argv)
{
	int c;
	
	// Parse options using getopt() function.
	
	while ((c = getopt (argc, argv, "t:")) != -1)
	{
		switch (c)
		{
		case 't':
			arg.timeout = atoi (optarg);
			break;
		case '?':
			if (optopt == 't')
				fprintf (stderr, "%s: option requires argument", argv[0]);
			else
				fprintf (stderr, "%s: unknown option: %s\n", argv[0], optarg);
			goto parse_usage;
		}
	}
	
	// There should be one (only) file parameter after options.
	
	c = argc - optind;
	if (c < 1)
	{
		fprintf (stderr, "%s: missing file parameter\n", argv[0]);
		goto parse_usage;
	}
	else if (c > 1)
	{
		fprintf (stderr, "%s: excess parameter detected\n", argv[0]);
		goto parse_usage;
	}
	
	// File parameter must starts with /dev.
	
	arg.file = argv[optind];
	if (strncmp (arg.file, "/dev/", 5) != 0)
	{
		fprintf (stderr, "%s: file is not started with /dev\n", argv[0]);
		goto parse_usage;
	}
	
	return TRUE;
	
parse_usage:
	fprintf (stderr, "Usage: %s [-t TIMEOUT] /dev/...\n", argv[0]);
	return FALSE;
}

int main (int argc, char **argv)
{
	struct pollfd ufd;
	int nr = -1;
	
	// Initalize global vars.
	
	is_done = FALSE;
	arg.timeout = 5;
	arg.file = NULL;
	
	if (!parse_args (argc, argv))
		return EXIT_FAILURE;
	
	// Initalize ueventd device filter.
	
	device_init ();
	
	// Prepare to poll fd.
	
	ufd.events = POLLIN;
	ufd.fd = get_device_fd ();
	
	while (!is_done)
	{
		ufd.revents = 0;
		nr = poll (&ufd, 1, arg.timeout * 1000);
		
		if (nr <= 0) return EXIT_FAILURE;
		if (ufd.revents & POLLIN) handle_device_fd ();
	}
	
	return EXIT_SUCCESS;
}

