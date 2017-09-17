#!env /bin/bash

CLI='bitcoin-cli -regtest'

# Complex Raw Transaction

# Use the `listunspent` RPC to get the UTXOs belonging to this wallet.
UTXOS=`$CLI listunspent`

# Create a transaction with two inputs and two outputs.

# For our two inputs, we select two UTXOs
UTXO1=`echo "$UTXOS" | jq '.[] | select (.amount == 50.00000000)'`
UTXO2=`echo "$UTXOS" | jq '.[] | select ((.amount > 39) and (.amount < 40))'`

UTXO1_TXID=`echo "$UTXO1" | jq '.txid' | tr -d '"'`
UTXO1_VOUT=`echo "$UTXO1" | jq '.vout'`
UTXO1_ADDRESS=`echo "$UTXO1" | jq '.address' | tr -d '"'`

UTXO2_TXID=`echo "$UTXO2" | jq '.txid' | tr -d '"'`
UTXO2_VOUT=`echo "$UTXO2" | jq '.vout'`
UTXO2_ADDRESS=`echo "$UTXO2" | jq '.address' | tr -d '"'`

# Use the `dumpprivkey` RPC get the private keys corresponding to the
# public keys used in the two UTXOs out inputs we will be spending. We
# need the private keys to we can sign each of the inputs separately.
UTXO1_PRIVATE_KEY='"'`$CLI dumpprivkey $UTXO1_ADDRESS`'"'
UTXO2_PRIVATE_KEY='"'`$CLI dumpprivkey $UTXO2_ADDRESS`'"'

# Get two new address for two outputs
NEW_ADDRESS1=`$CLI getnewaddress`
NEW_ADDRESS2=`$CLI getnewaddress`

# Create the raw transaction using `createrawtransaction` much the same
# as in Simple Raw Transaction, except now we have two inputs and two
# outputs
RAW_TX=`$CLI createrawtransaction '''
  [
    {
      "txid": "'$UTXO1_TXID'",
      "vout": '$UTXO1_VOUT'
    },
    {
      "txid": "'$UTXO2_TXID'",
      "vout": '$UTXO2_VOUT'
    }
  ]
  ''' '''
  {
    "'$NEW_ADDRESS1'": 79.9999,
    "'$NEW_ADDRESS2'": 10
  }'''`

# Signing the raw transaction with `signrawtransaction`
# We need three arguments:
# 1. The unsigned raw transaction
# 2. An empty array
# 3. The private key we want to use to sign one of the inputs
PARTLY_SIGNED_RAW_TX_BODY=`$CLI signrawtransaction $RAW_TX '[]' '''
  [
    '$UTXO1_PRIVATE_KEY'
  ]'''`
PARTLY_SIGNED_RAW_TX=`echo "$PARTLY_SIGNED_RAW_TX_BODY" | jq '.hex' | tr -d '"'`

# To sign the second input, we repeat the process we used to sign the first
# input using the second private key.
$CLI signrawtransaction $PARTLY_SIGNED_RAW_TX '[]' '''
  [
    '$UTXO2_PRIVATE_KEY'
  ]'''
