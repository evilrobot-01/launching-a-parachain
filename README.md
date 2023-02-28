
# Launching a Parachain

## Build & Launch Relay chain
Build the Polkadot binary:
```shell
./scripts/build.sh
```

Launch the relay chain: uses zombienet to quickly bring up a `rococo-local` network.
```shell
./scripts/launch.sh
```
Keep this process running for the duration of the remaining steps, as closing it will reset the relay chain state.

Copy the raw chain spec of the relay chain from the temp directory located at the beginning of the zombienet output.
```shell
# For example,
cp  /var/folders/z6/nldslwt943vb8k0rhbsb1j180000gn/T/zombie-6cac64c7973f5be424b319d75db40e34_-630-9SmQU2dA6FGv/rococo-local-raw.json ./
```

## Reserve Parachain Identifier
- Open local [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9900#/explorer) to connect to the relay chain in browser
- Click **Network**, **Parachains**, **Parathreads**, **+ ParaId**
- Select **Ferdie** under 'reserve from', click **+ Submit** and **Sign and Submit**
- Check the list of recent events for `registrar.Reserved`

## Prepare Chain Specification
- Build the plain-text chain spec for the parachain template node:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node build-spec --disable-default-bootnode > plain-parachain-chainspec.json
  ```
- Open the resulting `plain-parachain-chainspec.json` file and:
  - set the `para_id` value to your reserved parachain identifier (e.g. 2000)
  - set the `parachainId` to your reserved parachain identifier
  - set the `protocolId` to a unique value describing your parachain (e.g. 'launching-a-parachain')
- Generate a raw chain spec from the modified chain spec file:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node build-spec --disable-default-bootnode --chain plain-parachain-chainspec.json --raw > raw-parachain-chainspec.json
  ```

## Prepare Parachain Collator
- Export WebAssembly runtime for parachain, required for relay chain to validate parachain blocks:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node export-genesis-wasm --chain raw-parachain-chainspec.json para-2000-wasm
  ```
- Generate parachain genesis state, required to register the parachain:
  ```shell
  ./substrate-parachain-node/target/release/parachain-template-node export-genesis-state --chain raw-parachain-chainspec.json para-2000-genesis-state
  ```
- Start a collator node, manually replacing the `ZOMBIENET_RELAY_BOOTNODE` placeholder below with the bootnode listed in the zombienet launch output:
  ```shell
  ./substrate-parachain-node/./target/release/parachain-template-node \
  --alice \
  --collator \
  --force-authoring \
  --chain raw-parachain-chainspec.json \
  --base-path /tmp/parachain/alice \
  --port 40333 \
  --ws-port 8844 \
  -- \
  --execution wasm \
  --chain rococo-local-raw.json \
  --port 30343 \
  --ws-port 9977 \
  --bootnodes ZOMBIENET_RELAY_BOOTNODE
  ```
  Note: the arguments after the `--` are for the embedded relay chain node.
  
The collator should now be running but will not produce blocks until it is registered on the relay chain. Verify that the collator's embedded relay node is peering with the relay chain (may require firewall adjustments).

## Register Parachain
- Open local [Polkadot/Substrate Portal](https://polkadot.js.org/apps/?rpc=ws://127.0.0.1:9900#/explorer) to connect to the relay chain in browser
- Click **Developer**, **Sudo**, **paraSudoWrapper** and then select **sudoScheduleParaInitialize(id,genesis)**
- Enter your reserved parachain identifier for the `id` parameter 
- Click file upload and select the `para-2000-genesis` file generated earlier for the `genesisHead` parameter
- Click file upload and select the `para-2000-wasm` file generated earlier for the `validationCode` parameter
- Select `Yes` for the `paraKind` parameter and then click **Submit Sudo** and finally `Sign and Submit`
- Navigate to **Network**, **Parachains** and wait for a new epoch to start, The parachain will show as onboarding under **Parathreads** until then.