
# Launching a Parachain

## Overview:
This repository provides a guide for launching an initial parachain on a local test network followed by an upgrade.

It has two submodules which link to `polkadot` (0.9.37) and to a slightly modified version of the Substrate Cumulus parachain template: an `initial` runtime with the `sudo` pallet added and `pallet-template` removed, and then an `upgrade` runtime with the default template runtime restored. 

The [`build.sh`](./scripts/build.sh) script simply builds the initial binaries and [`launch.sh`](./scripts/launch.sh) launches a local relay chain using `zombienet`, as defined in [`config.toml`](./config.toml). The [`clean.sh`](./scripts/clean.sh) script removes files generated whilst following the guide.

### Tools:
- [Polkadot](./polkadot): relay chain
- [Substrate Cumulus Parachain Template](./substrate-parachain-node): parachain template
- [zombienet](https://github.com/paritytech/zombienet): launching relay chain
- [srtool](https://github.com/paritytech/srtool) (Substrate Runtime Tool): building deterministic runtimes
  - Note: Apple silicon incompatibility https://github.com/paritytech/srtool/issues/32, GitHub CI build as workaround
- [subwasm](https://github.com/chevdor/subwasm): verifying wasm blobs

## Build & Launch Relay chain
- Build the Polkadot and parachain collator binaries:
  ```shell
  ./scripts/build.sh
  ```
- Launch the relay chain using `zombienet` to quickly bring up a `rococo-local` network.
  ```shell
  zombienet spawn config.toml -p native # or ./scripts/launch.sh
  ```
  Keep this process running for the duration of the remaining steps, as closing it will reset the relay chain state.


- Copy the raw chain spec of the resulting relay chain from the temp directory located at the beginning of the zombienet output. This just simplifies the collator launch command later.
  ```shell
  # For example,
  cp /var/folders/z6/nldslwt943vb8k0rhbsb1j180000gn/T/zombie-6cac64c7973f5be424b319d75db40e34_-630-9SmQU2dA6FGv/rococo-local-raw.json ./
  ```

## Reserve Parachain Identifier
- Open local [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9900#/explorer) to connect to the relay chain in browser
- Click **Network**, **Parachains**, **Parathreads**, **+ ParaId** (or click [here](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9900#/parachains/parathreads))
- Select **Ferdie** under 'reserve from', click **+ Submit** and **Sign and Submit**
- Check the list of recent events for `registrar.Reserved` and also note the `balances.Reserved` event.

## Prepare Chain Specification
- Build the plain-text chain spec for the parachain template node:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node build-spec --disable-default-bootnode > plain-parachain-chainspec.json
  ```
- Open the resulting `plain-parachain-chainspec.json` file and:
  - set the `para_id` value to your reserved parachain identifier (e.g. 2000)
  - set the `parachainId` to your reserved parachain identifier
  - set the `protocolId` to a unique value describing the parachain (e.g. 'launching-a-parachain')
- Generate a raw chain spec from the modified chain spec file:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node build-spec --disable-default-bootnode --chain plain-parachain-chainspec.json --raw > raw-parachain-chainspec.json
  ```

## Prepare Parachain Collator
- Build WebAssembly runtime for parachain, required for relay chain to validate parachain blocks:
  - **Note:** Does not currently work on Apple silicon, `initial` WebAssembly runtime built via CI should be downloaded from [here](https://github.com/evilrobot-01/substrate-parachain-node/actions/workflows/build-runtime.yml).
  Verify wasm hashes using:
    ```shell
    subwasm info parachain_template_initial_runtime.compact.compressed.wasm
    ```
  - Local command would be as follows, but ignored:
    ```shell
    cd substrate-parachain-node && srtool build --runtime-dir ./runtime/initial --package parachain-template-initial-runtime; cd ..
    ```

- Generate parachain genesis state, required to register the parachain:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node export-genesis-state --chain raw-parachain-chainspec.json para-2000-genesis-state
  ```
- Start a collator node, manually replacing the `PORT` placeholder below with the port of the bootnode listed in the zombienet launch output:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node \
  --alice \
  --collator \
  --force-authoring \
  --chain raw-parachain-chainspec.json \
  --base-path /tmp/parachain/alice \
  --port 40333 \
  --ws-port 8844 \
  --wasm-runtime-overrides ./ \
  -- \
  --execution wasm \
  --chain rococo-local-raw.json \
  --port 30343 \
  --ws-port 9977 \
  --bootnodes /ip4/127.0.0.1/tcp/PORT/ws/p2p/12D3KooWQCkBm1BYtkHpocxCwMgR8yjitEeHGx8spzcDLGt2gkBm
  ```
  Note: the arguments after the `--` are for the embedded relay chain node.
  
  The collator should now be running but will not produce blocks until it is registered on the relay chain. Verify that the collator's embedded relay node is peering with the relay chain (may require firewall adjustments).


- Open [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:8844#/explorer) to connect to the local parachain in browser

## Register Parachain
- Open [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9900#/explorer) to connect to the local relay chain in browser
- Click **Developer**, **Sudo**, **paraSudoWrapper** and then select **sudoScheduleParaInitialize(id,genesis)**
- Enter your reserved parachain identifier for the `id` parameter 
- Click file upload and select the `para-2000-genesis-state` file generated earlier for the `genesisHead` parameter
- Click file upload and select the `parachain_template_initial_runtime.compact.compressed.wasm` file downloaded for the `validationCode` parameter
- Select `Yes` for the `paraKind` parameter and then click **Submit Sudo** and finally `Sign and Submit`
- Navigate to **Network**, **Parachains** and wait for a new epoch to start, The parachain will show as onboarding under **Parathreads** until then.
- Open [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:8844#/explorer) to verify the parachain is producing blocks.

## Upgrade Runtime
- Download the `upgrade` runtime from [here](https://github.com/evilrobot-01/substrate-parachain-node/actions/workflows/build-runtime.yml).
- Verify the wasm hashes:
  ```shell
  subwasm info parachain_template_upgrade_runtime.compact.compressed.wasm
  ```
- Open [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:8844#/explorer) to perform a parachain runtime upgrade.
- Navigate to **Developer**, **Sudo**, select **parachainSystem** and **authorizeUpgrade(codeHash)**.
- Click 'hash a file' and then browse for the upgrade runtime wasm file. Compare the resulting `codeHash` with the Blake2-256 hash shown by `subwasm`.
- Click **Submit Sudo** and then **Sign and Submit**. Check for the `parachainSystem.UpgradeAuthorized` event.
- Navigate to **Developer**, **Sudo**, select **parachainSystem** and **enactAuthorizedUpgrade(code)**.
- Click 'file upload' and then select the `upgrade` runtime.
- Click **Submit Sudo** and then **Sign and Submit**.
- Note:
  - the upgrade progress on the local relay chain via the [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9900#/parachains).
  - the `parachainSystem.ValidationFunctionStored` and `parachainSystem.ValidationFunctionApplied` events on the parachain.
  - the updated runtime version of the parachain.
  - the `templatePallet` has been added to the runtime and `sudo` has been removed, restoring the parachain template runtime to its default config.