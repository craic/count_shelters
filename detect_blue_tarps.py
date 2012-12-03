#!/usr/bin/env python

# detect_blue_tarps.py

# Copyright 2012  Robert Jones  jones@craic.com
# Code is freely distributed under the terms of the MIT license

# Given a portion of a satellite image, identify regions that are predominately blue
# with areas that fall below a cutoff value.
# Output the total area (in pixels) of blue regions
# Output the input image with blue regions outlined in red
# Output the binary thresholded image - white areas correspond to blue ares in original

# NOTE that this was developed specifically for use with images of Port-au-Prince slum areas
# from Google Maps imagery. Use test_image_1.png or test_image_2.png as examples:
# ./detect_blue_tarps.py test_image_1.png

import cv
import sys

if len(sys.argv) < 2:
    print "Usage: ", sys.argv[0], " <image filename>"
    sys.exit()

# Load image and split into RGB planes
image = cv.LoadImageM(sys.argv[1])
size = cv.GetSize(image)
r_plane = cv.CreateImage(size, 8, 1)
g_plane = cv.CreateImage(size, 8, 1)
b_plane = cv.CreateImage(size, 8, 1)
cv.Split(image, b_plane, g_plane, r_plane, None)

# Get the maximum between the Red and Green planes
diff    = cv.CreateImage(size, 8, 1)
out     = cv.CreateImage(size, 8, 1)
maxrg   = cv.CreateImage(size, 8, 1)

cv.Max(r_plane, g_plane, maxrg)
# Subtract that from the Blue plane
cv.Sub(b_plane, maxrg, diff, None)

# Apply a threshold to isolate the blue pixels
threshold = 64  # hard-wired threshold value - vary as needed (0-255)
colour    = 255
cv.Threshold(diff, out, threshold,colour,cv.CV_THRESH_BINARY)
# Smooth out noise by dilating with a 3x3 element
cv.Dilate(out, diff)

cv.ShowImage("Thresholded Image", diff)

# If there are any non-zero pixels in the difference image
# Find contours around those regions and compute their area
area_cutoff = 1000.0  # Ignore areas larger than 1000 pixels
sum_area = 0.0
if cv.CountNonZero(diff) > 0:

  contour_ptr = cv.FindContours(diff, cv.CreateMemStorage())
  # Step through the linked list of contours
  while contour_ptr is not None :
    contour = contour_ptr [ : ]
    area = cv.ContourArea(contour)
    if area < area_cutoff:
      sum_area += area
      # draw red contour around areas of interest
      cv.PolyLine( image , [contour] , True , cv.RGB(255, 0, 0) , 1 , 8 , 0 )
    contour_ptr = contour_ptr.h_next()

print "Total area : %d\n" % sum_area

cv.ShowImage("Annotated Image", image)
print "\nHit any key in the image to exit"
cv.WaitKey()



