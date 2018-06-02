#!/bin/sh

WANIP=$(./getwanip.sh $1)

echo Our WAN IP is: ${WANIP}

echo Setting up Port Forwarding


