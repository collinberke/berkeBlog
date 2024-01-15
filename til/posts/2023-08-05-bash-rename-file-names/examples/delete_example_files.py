#!/usr/bin/env python3

import os
import shutil


# Define a function to check directory exists
# if so, then delete it
def del_dir(dir):
    if os.path.isdir(dir):
        shutil.rmtree(dir)


# List of directories to delete, created by make_example_files.py file
files = [
    'example_online_store', 'example_pageview',
    'example_station_demos', 'example_test_file'
    ]

# Loop through list of directory names and delete directory
# and all files within
for path in files:
    del_dir(path)
