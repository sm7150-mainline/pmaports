/*
Copyright (C) 2018 drebrez <drebrez@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <linux/fb.h>
#include <sys/ioctl.h>

void usage(char* appname)
{
    printf("Usage: %s [-d DEV] [-i] [-c length] [-p] [-m mode] [-h]\n\
    -d  Framebuffer device (default /dev/fb0)\n\
    -i  Show fixed and variable screen info\n\
    -c  Show colormap values (length 0-256)\n\
    -p  Perform the panning of the display\n\
    -m  Set mode: 0 => Normal\n\
                  2 => Standby\n\
                  3 => Suspend\n\
                  4 => Off\n\
    -h  Show this help\n", appname);
}

void print_fix_screeninfo(struct fb_fix_screeninfo* scr_fix)
{
    // ref: https://elixir.bootlin.com/linux/latest/ident/fb_fix_screeninfo
    printf("Fixed screen info:\n");
    printf("\tid           = %s\n", scr_fix->id);
    printf("\tsmem_start   = %lu\n", scr_fix->smem_start);
    printf("\tsmem_len     = %u\n", scr_fix->smem_len);
    printf("\ttype         = %u\n", scr_fix->type);
    printf("\ttype_aux     = %u\n", scr_fix->type_aux);
    printf("\tvisual       = %u\n", scr_fix->visual);
    printf("\txpanstep     = %hu\n", scr_fix->xpanstep);
    printf("\typanstep     = %hu\n", scr_fix->ypanstep);
    printf("\tywrapstep    = %hu\n", scr_fix->ywrapstep);
    printf("\tline_length  = %u\n", scr_fix->line_length);
    printf("\tmmio_start   = %lu\n", scr_fix->mmio_start);
    printf("\tmmio_len     = %u\n", scr_fix->mmio_len);
    printf("\taccel        = %u\n", scr_fix->accel);
    printf("\tcapabilities = %hu\n", scr_fix->capabilities);
    printf("\treserved[0]  = %hu\n", scr_fix->reserved[0]);
    printf("\treserved[1]  = %hu\n", scr_fix->reserved[1]);
}

void print_var_screeninfo(struct fb_var_screeninfo* scr_var)
{
    // ref: https://elixir.bootlin.com/linux/latest/ident/fb_var_screeninfo
    printf("Variable screen info:\n");
    printf("\txres             = %u\n", scr_var->xres);
    printf("\tyres             = %u\n", scr_var->yres);
    printf("\txres_virtual     = %u\n", scr_var->xres_virtual);
    printf("\tyres_virtual     = %u\n", scr_var->yres_virtual);
    printf("\txoffset          = %u\n", scr_var->xoffset);
    printf("\tyoffset          = %u\n", scr_var->yoffset);
    printf("\tbits_per_pixel   = %u\n", scr_var->bits_per_pixel);
    printf("\tgrayscale        = %u\n", scr_var->grayscale);
    printf("\tred.offset       = %u\n", scr_var->red.offset);
    printf("\tred.length       = %u\n", scr_var->red.length);
    printf("\tred.msb_right    = %u\n", scr_var->red.msb_right);
    printf("\tgreen.offset     = %u\n", scr_var->green.offset);
    printf("\tgreen.length     = %u\n", scr_var->green.length);
    printf("\tgreen.msb_right  = %u\n", scr_var->green.msb_right);
    printf("\tblue.offset      = %u\n", scr_var->blue.offset);
    printf("\tblue.length      = %u\n", scr_var->blue.length);
    printf("\tblue.msb_right   = %u\n", scr_var->blue.msb_right);
    printf("\ttransp.offset    = %u\n", scr_var->transp.offset);
    printf("\ttransp.length    = %u\n", scr_var->transp.length);
    printf("\ttransp.msb_right = %u\n", scr_var->transp.msb_right);
    printf("\tnonstd           = %u\n", scr_var->nonstd);
    printf("\tactivate         = %u\n", scr_var->activate);
    printf("\theight           = %u\n", scr_var->height);
    printf("\twidth            = %u\n", scr_var->width);
    printf("\taccel_flags      = %u\n", scr_var->accel_flags);
    printf("\tpixclock         = %u\n", scr_var->pixclock);
    printf("\tleft_margin      = %u\n", scr_var->left_margin);
    printf("\tright_margin     = %u\n", scr_var->right_margin);
    printf("\tupper_margin     = %u\n", scr_var->upper_margin);
    printf("\tlower_margin     = %u\n", scr_var->lower_margin);
    printf("\thsync_len        = %u\n", scr_var->hsync_len);
    printf("\tvsync_len        = %u\n", scr_var->vsync_len);
    printf("\tsync             = %u\n", scr_var->sync);
    printf("\tvmode            = %u\n", scr_var->vmode);
    printf("\trotate           = %u\n", scr_var->rotate);
    printf("\tcolorspace       = %u\n", scr_var->colorspace);
    printf("\treserved[0]      = %u\n", scr_var->reserved[0]);
    printf("\treserved[1]      = %u\n", scr_var->reserved[1]);
    printf("\treserved[2]      = %u\n", scr_var->reserved[2]);
    printf("\treserved[3]      = %u\n", scr_var->reserved[3]);
}

void print_cmap(struct fb_cmap* scr_cmap)
{
    // ref: https://elixir.bootlin.com/linux/latest/ident/fb_cmap
    printf("Colormap:\n");
    printf("\tstart  = %u\n", scr_cmap->start);
    printf("\tlen    = %u\n", scr_cmap->len);
    printf("\tred    = ");
    for (int i = 0; i < scr_cmap->len; i++) {
        if (i > 0 && i % 8 == 0) {
            printf("\n\t\t ");
        }
        printf("0x%04hX ", scr_cmap->red[i]);
    }
    printf("\n");
    printf("\tgreen  = ");
    for (int i = 0; i < scr_cmap->len; i++) {
        if (i > 0 && i % 8 == 0) {
            printf("\n\t\t ");
        }
        printf("0x%04hX ", scr_cmap->green[i]);
    }
    printf("\n");
    printf("\tblue   = ");
    for (int i = 0; i < scr_cmap->len; i++) {
        if (i > 0 && i % 8 == 0) {
            printf("\n\t\t ");
        }
        printf("0x%04hX ", scr_cmap->blue[i]);
    }
    printf("\n");
    printf("\ttransp = ");
    for (int i = 0; i < scr_cmap->len; i++) {
        if (i > 0 && i % 8 == 0) {
            printf("\n\t\t ");
        }
        printf("0x%04hX ", scr_cmap->transp[i]);
    }
    printf("\n");
}

int main(int argc, char** argv)
{
    const char *fb_device;
    struct fb_fix_screeninfo scr_fix;
    struct fb_var_screeninfo scr_var;
    struct fb_cmap scr_cmap;
    int fb_fd;

    // parse command line options
    fb_device = "/dev/fb0";
    bool show_info = false;
    bool show_cmap = false;
    int cmap_len;
    bool pan_display = false;
    bool set_fbmode = false;
    int fbmode;

    if (argc < 2)
    {
        usage(argv[0]);
        exit(1);
    }
    int opt;
    while ((opt = getopt(argc, argv, "d:ic:pm:h")) != -1)
    {
        switch (opt)
        {
            case 'd':
                fb_device = optarg;
                break;
            case 'i':
                show_info = true;
                break;
            case 'c':
                show_cmap = true;
                cmap_len = atoi(optarg);
                break;
            case 'p':
                pan_display = true;
                break;
            case 'm':
                set_fbmode = true;
                fbmode = atoi(optarg);
                break;
            case 'h':
            default:
                usage(argv[0]);
                exit(1);
        }
    }

    // open the framebuffer device
    fb_fd = open(fb_device, O_RDWR);
    if (fb_fd < 0)
    {
        printf("Unable to open %s.\n", fb_device);
        return 1;
    }

    // call ioctl. retrieve fixed screen info
    if (ioctl(fb_fd, FBIOGET_FSCREENINFO, &scr_fix) < 0)
    {
        printf("Unable to retrieve fixed screen info: %s\n",
            strerror(errno));
        close(fb_fd);
        return 1;
    }

    // print all the fixed screen info values
    if (show_info)
        print_fix_screeninfo(&scr_fix);

    // call ioctl. retrieve variable screen info
    if (ioctl(fb_fd, FBIOGET_VSCREENINFO, &scr_var) < 0)
    {
        printf("Unable to retrieve variable screen info: %s\n",
            strerror(errno));
        close(fb_fd);
        return 1;
    }

    // print all the variable screen info values
    if (show_info)
        print_var_screeninfo(&scr_var);

    // call ioctl. retrieve colormap
    if (show_cmap) {
        scr_cmap.start = 0;
        scr_cmap.len = cmap_len;
        scr_cmap.red = calloc(256, sizeof(unsigned short));
        scr_cmap.green = calloc(256, sizeof(unsigned short));
        scr_cmap.blue = calloc(256, sizeof(unsigned short));
        scr_cmap.transp = calloc(256, sizeof(unsigned short));
        if (ioctl(fb_fd, FBIOGETCMAP, &scr_cmap) < 0)
        {
            printf("Unable to retrieve cmap info: %s\n",
                strerror(errno));
            free(scr_cmap.red);
            free(scr_cmap.green);
            free(scr_cmap.blue);
            free(scr_cmap.transp);
            close(fb_fd);
            return 1;
        }

        // print all the cmap values
        print_cmap(&scr_cmap);

        free(scr_cmap.red);
        free(scr_cmap.green);
        free(scr_cmap.blue);
        free(scr_cmap.transp);
    }

    if (pan_display)
    {
        // call ioctl. pan the display
        if (ioctl(fb_fd, FBIOPAN_DISPLAY, &scr_var) < 0)
        {
            printf("Unable to pan the display: %s\n",
                strerror(errno));
            close(fb_fd);
            return 1;
        }
    }

    if (set_fbmode) {
        if (ioctl(fb_fd, FBIOBLANK, (void *)fbmode) < 0)
        {
            printf("Unable to set fb mode: %s\n",
                strerror(errno));
            close(fb_fd);
            return 1;
        }
    }

    // close the framebuffer device
    close(fb_fd);
}
