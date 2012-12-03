#!/usr/bin/env ruby

# fetch_image_tiles.rb

# Copyright 2012  Robert Jones  jones@craic.com
# Code is freely distributed under the terms of the MIT license

# Experiment to generate tiled satellite images derived from from google maps across part of Port au Prince, Haiti

# Example of the URL used to fetch a static map from Google
# http://maps.googleapis.com/maps/api/staticmap?center=18.543012,-72.339585&zoom=19&size=640x640&maptype=satellite&sensor=false
# NOTE Be sure to check Google's terms of use for images, etc. etc

# Modify the hard wired parameters as needed then run with number of rows and columns
#
# ./fetch_image_tiles.rb 20 20 > output.csv


# Method to determine relative LatLon offsets given a starting coordinate and an offset, based on an average of the Earth's radius
def latlong_offset(lat, long, offset, units, direction)

  units.downcase!
  direction.downcase!

  # error check on units and direction

  earth_radius = { 'miles' => 3959.0, 'km' => 6371.0 }

  degrees_to_radians = Math::PI/180.0
  radians_to_degrees = 180.0/Math::PI

  new_lat  = 0.0
  new_long = 0.0

  if direction == 'n'
    new_lat = lat + (offset/earth_radius[units]) * radians_to_degrees
    new_long = long
  elsif direction == 's'
    new_lat = lat - (offset/earth_radius[units]) * radians_to_degrees
    new_long = long
  elsif direction == 'e'
    new_lat = lat
    r = earth_radius[units] * Math.cos(lat * degrees_to_radians)
    new_long = long + (offset/r) * radians_to_degrees
  elsif direction == 'w'
    new_lat = lat
    r = earth_radius[units] * Math.cos(lat * degrees_to_radians)
    new_long = long - (offset/r) * radians_to_degrees
  end
  return new_lat, new_long
end


# Main --------------------------------------------

abort "Usage: #{$0} <n_rows> <n_cols>" unless ARGV.length == 2

# Number of tiles to fetch
n_rows = ARGV[0].to_i
n_cols = ARGV[1].to_i

# Hard wired parameters.......

# Lat Lon of the NW / top left coordinate

top_left_lat  = 18.561
top_left_long = -72.339585



# Size of each image
units = 'km'
interval = 0.18
# Google zoom level
zoom = 19

# Directory in which to store the images
image_dir = File.join(File.expand_path(File.dirname(__FILE__)), 'images')
Dir.mkdir(image_dir) if not File.exists?(image_dir)

# Path to the Python script that will compute the area
script = File.join(File.expand_path(File.dirname(__FILE__)), 'count_blue_pixels.py')

# end of parameters----

# Compute the Lat and Lon offset for each image based on the interval + units (e.g. 0.18 km or 180m )
# Long will actually change slightly with latitude - but ignore that here
row_offset = 0
col_offset = 0

tmp_lat, tmp_long = latlong_offset(top_left_lat, top_left_long, interval, units, 's')
row_offset = tmp_lat - top_left_lat

tmp_lat, tmp_long = latlong_offset(top_left_lat, top_left_long, interval, units, 'e')
col_offset = tmp_long - top_left_long

# Output is a CSV file representing the area of blue pixels in each tile in the matrix
labels = [ '' ]
(0...n_cols).each { |i| labels << i.to_s }
puts labels.join(',')

# Step through all image locations - fecth image then compute areas
lat = top_left_lat
(0...n_rows).each do |row|
  long = top_left_long
  areas = []
  (0...n_cols).each do |col|

    # Fetch the image from Google Maps
    # NOTE that google maps will stop serving images if the number and frequency of requests exceeds some limit
    # so you probably want to 'sleep' between requests

    url = "http://maps.googleapis.com/maps/api/staticmap?center=#{lat},#{long}&zoom=#{zoom}&size=640x640&maptype=satellite&sensor=false"
    image_file = File.join(image_dir, "#{row}_#{col}_#{zoom}.png")
    `curl -s "#{url}" > #{image_file}`

    # Compute the area of blue pixels in this image
    text = `#{script} #{image_file}`

    count = 0
    text.each_line do |line|
      if line =~ /^(\d+)/
        count = $1.to_i
        break
      end
    end
    areas << count.to_s
    long += col_offset

    sleep 10   # sleep 10 seconds between requests
  end
  printf "%d,%s\n", row, areas.join(',')
  lat += row_offset
end


