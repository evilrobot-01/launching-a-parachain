#!/bin/bash

# Ensure yarn available
if ! which yarn &> /dev/null
then
echo Error: could not find yarn
exit
fi

# Install zombienet
if ! which zombienet &> /dev/null
then
echo Installing zombienet...
yarn global add --silent  --no-progress @zombienet/cli
echo Use \'yarn global remove "@zombienet/cli"\' to remove...
  if ! which zombienet &> /dev/null
  then
    echo Error: could not find \'"zombienet"\' after global install - ensure that the path reported by \'yarn global bin\' is in your PATH.
    exit
  fi
fi

# Launch network
echo Launching network...
zombienet spawn config.toml -p native