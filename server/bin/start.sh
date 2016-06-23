#!/bin/sh

tclsh8.6 netmagis-restd \
	-d \
	-f netmagis.conf \
	-a 0.0.0.0 \
	-p 8080 \
	-l ../lib \
	-s ../www/static \
	-m 1 \
	-x 4 \
	-i 30 \
	-v 3.0.0alpha \
