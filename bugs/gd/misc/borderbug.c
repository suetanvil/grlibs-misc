#/*

# Via the magic of C hackery, this program will compile itself when
# run as a shell script.

# This is a simple C program which will create a white 300x300 image,
# export it to "before.png", then scale it to 600x600 and output that
# as "after.png".  This will reveal that the rigth and bottom lines
# are now black.

gcc -g -Wall $0 -o ${0%.c} `pkg-config gdlib --cflags --libs`
exit $?

#*/
#include <stdio.h>

#include "gd.h"


void png(gdImagePtr im, const char *filename)
{    
    FILE *fh;
    fh = fopen(filename, "w");
    gdImagePng(im, fh);
    fclose(fh);
}/* png*/


gdImagePtr mkwhite(int x, int y)
{
    gdImagePtr im;

	im = gdImageCreateTrueColor(x, y);
	gdImageFilledRectangle(im, 0, 0, x-1, y-1,
                           gdImageColorExactAlpha(im, 255, 255, 255, 0));
    return im;
}/* mkwhite*/

int main(int argc, char **argv)
{
    gdImagePtr im, im2;

    im = mkwhite(300, 300);
    gdImageSetInterpolationMethod(im, GD_BICUBIC);

    png(im, "before.png");

    im2 = gdImageScale(im, 600, 600);

    png(im2, "after.png");

    return 0;
}
