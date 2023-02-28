#!/bin/bash

echo Building Polkadot...
cd polkadot || exit
cargo build --release --bin polkadot
cd ..

echo Building parachain...
cd substrate-parachain-node || exit
cargo build --release --bin parachain-template-node
cd ..