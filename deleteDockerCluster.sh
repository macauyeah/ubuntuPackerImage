#!/bin/bash

nodeName=("node21" "node22" "node23" "node24" "node25")
for ((i=0 ; i < 5 ; i++)) ; do
	multipass delete ${nodeName[i]}
done
multipass purge
