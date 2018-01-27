#!/bin/bash
SOURCE=$1

#### Give it time to start up 
sleep 15000


### Watch the Java process a
while :
do
	if [ ! $(pgrep java) ] ; then
	  kill $1
	  break
	fi   
   sleep 1000
done

