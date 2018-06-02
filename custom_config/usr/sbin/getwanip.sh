#!/bin/sh


ip addr show $1 | sed -n 's/.*inet \([0-9]*.[0-9]*.[0-9]*.[0-9]*\).*/\1/p'
