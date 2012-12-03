#!/usr/bin/env python

# count_blue_pixels.py

# Copyright 2012  Robert Jones  jones@craic.com
# Code is freely distributed under the terms of the MIT license

# This is a trimmed down version of detect_blue_tarps.py
# See that script for more detailed comments

import cv
import sys

if len(sys.argv) < 2:
    print "Usage: ", sys.argv[0], " <image filename>"
    sys.exit()

image = cv.LoadImageM(sys.argv[1])

size    = cv.GetSize(image)
r_plane = cv.CreateImage(size, 8, 1)
g_plane = cv.CreateImage(size, 8, 1)
b_plane = cv.CreateImage(size, 8, 1)
diff    = cv.CreateImage(size, 8, 1)
out     = cv.CreateImage(size, 8, 1)
maxrg   = cv.CreateImage(size, 8, 1)

cv.Split(image, b_plane, g_plane, r_plane, None)
cv.Max(r_plane, g_plane, maxrg)
cv.Sub(b_plane, maxrg, diff, None)

threshold = 64
colour    = 255
cv.Threshold(diff, out, threshold,colour,cv.CV_THRESH_BINARY)
cv.Dilate(out, diff)

area_cutoff = 1000.0
sum_area = 0.0

if cv.CountNonZero(diff) > 0:
  contour_ptr = cv.FindContours(diff, cv.CreateMemStorage())

  while contour_ptr is not None :
    contour = contour_ptr [ : ]
    area = cv.ContourArea(contour)
    if area < area_cutoff:
      sum_area += area
    contour_ptr = contour_ptr.h_next()

print int(sum_area)




