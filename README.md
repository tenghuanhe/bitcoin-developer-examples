# Bitcoin Developer Examples Bash Scripts

This respository contains bash scripts corresponding to [Bitcoin Developer Examples](https://bitcoin.org/en/developer-examples) tutorials

## Prerequisites
```
sudo apt-add-repository ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install bitcoin-qt
sudo apt-get install jq
```

## How to use

First start the regtest server
```
./start-regtest-server.sh # bitcoind -regtest -daemon
```
Then run the following scripts in order
```
./simple-spending.sh
./simple-raw-transaction.sh
./complex-raw-transaction.sh
./offline-signing.sh
./p2sh-multisig.sh
```

## Note
You may need restart the regtest server, to clean all records
```
rm ~/.bitcoin/regtest/* -rf # or other regtest directory you specify
```
