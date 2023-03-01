#!/bin/bash

echo Building Polkadot...
cd polkadot || exit
cargo build --release --bin polkadot
cd ..

echo Building Cumulus...
cd cumulus || exit
cargo build --release --bin polkadot-parachain
cd ..

echo Building parachain collator...
cd substrate-parachain-node || exit
cargo build --release --bin parachain-template-node
cd ..

# Install subwasm
if ! which subwasm &> /dev/null
then
echo Installing subwasm...
cargo install --locked --git https://github.com/chevdor/subwasm --tag v0.16.1 || exit
echo Use \'cargo uninstall subwasm\' to remove...
fi

