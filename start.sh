#!/bin/sh

# create graph.config if not exists
echo "Checking Config"
if [ ! -f "graph.config" ]; then
    cp graph.config.def graph.config
    $EDITOR graph.config
fi

echo "\nStarting"
./graph.pl
