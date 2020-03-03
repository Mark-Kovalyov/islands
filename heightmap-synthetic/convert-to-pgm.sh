#!/bin/bash

find -regextype posix-extended -regex '.*\.(jpg|png|bmp)' -exec convert -compress none "{}" "{}.pgm" \;
