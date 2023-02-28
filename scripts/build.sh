#!/bin/bash

echo Building Polkadot...
cd polkadot || exit
cargo build --release --bin polkadot
cd ..

echo Building Cumulus...
cd cumulus || exit
cargo build --release --bin polkadot-parachain
cd ..

echo Building parachain...
cd substrate-parachain-node || exit
cargo build --release --bin parachain-template-node
cd ..