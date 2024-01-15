#!/usr/bin/env python3
import datetime
import os


def make_dir(file_name):
    os.makedirs(file_name, exist_ok=True)

# Make example files for post

# Create test_file examples
make_dir("example_test_file")

for x in range(1, 11):
    open(f'example_test_file/{x:02d}_test_file.csv', "x")

# Create dataOnlineStore examples
make_dir("example_online_store")

for x in range(1, 11):
    open(f'example_online_store/dataOnlineStore ({x:01d}).csv', "x")

# Create data_station_demos examples, with datetimes
make_dir("example_station_demos")

now = datetime.datetime.now()
for x in range(1, 11):
    if x > 1:
        now += datetime.timedelta(days=1)
        open(f'example_station_demos/{now:%Y%m%d}_data_station_demos.csv', "x")
    else:
        open(f'example_station_demos/{now:%Y%m%d}_data_station_demos.csv', "x")

# Create website pageviews examples, with datetimes
make_dir("example_pageview")

now = datetime.datetime.now()
for x in range(1, 11):
    if x > 1:
        now += datetime.timedelta(days=1)
        open(f'example_pageview/{now:%Y%m%d}_WEBSITE_PAGEVIEWS.csv', "x")
    else:
        open(f'example_pageview/{now:%Y%m%d}_WEBSITE_PAGEVIEWS.csv', "x")
