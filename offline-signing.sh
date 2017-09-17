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
OLD_SIGNED_RAW_TX_BODY=`$CLI signrawtransaction $PARTLY_SIGNED_RAW_TX '[]' '''
  [
    '$UTXO2_PRIVATE_KEY'
  ]'''`
OLD_SIGNED_RAW_TX=`echo "$OLD_SIGNED_RAW_TX_BODY" | jq '.hex' | tr -d '"'`

# Offline Signing

# Decode the signed raw transaction so we can get its txid
DECODE_RAW_TRANSACTION=`$CLI decoderawtransaction $OLD_SIGNED_RAW_TX`
# Get the txid
UTXO_TXID=`echo "$DECODE_RAW_TRANSACTION" | jq '.txid' | tr -d '"'`
UTXO_VOUTS_BODY=`echo "$DECODE_RAW_TRANSACTION" | jq '.vout'`
UTXO_VOUT_BODY=`echo "$UTXO_VOUTS_BODY" | jq '.[1]'`

# Choose a specific one of UTXOs to spend and save its output index number (vout)
# and hex pubkey script
UTXO_VOUT=1
UTXO_VOUT_SCRIPT_BODY=`echo "$UTXO_VOUT_BODY" | jq '.scriptPubKey'`
UTXO_OUTPUT_SCRIPT=`echo "$UTXO_VOUT_SCRIPT_BODY" | jq '.hex' | tr -d '"'`

# Get a new address to spend to satoshis to.
NEW_ADDRESS=`$CLI getnewaddress`

# Create the raw transaction the same way we've done in the previous
# subsections.
## Outputs - inputs = transaction fee, so always double-check you math!
RAW_TX_NEW=`$CLI createrawtransaction '''
  [
    {
      "txid": "'$UTXO_TXID'",
      "vout": '$UTXO_VOUT'
    }
  ]
  ''' '''
  {
    "'$NEW_ADDRESS'": 9.9999
  }'''`

# Attempt to sign the raw transaction without any special arguments.
# This call will fail and leave the raw transaction hex unchanged.
# $CLI signrawtransaction $RAW_TX_NEW

# Successfully sign the transaction by providing the previous pubkey 
# script and other required input data
SIGNED_RAW_TX_NEW_BODY=`$CLI signrawtransaction $RAW_TX_NEW '''
  [
    {
      "txid": "'$UTXO_TXID'", 
      "vout": '$UTXO_VOUT', 
      "scriptPubKey": "'$UTXO_OUTPUT_SCRIPT'"
    }
  ]'''`

NEW_SIGNED_RAW_TX=`echo "$SIGNED_RAW_TX_NEW_BODY" | jq '.hex' | tr -d '"'`

# Attemp to broadcast the second transaction (NEW_SIGNED_RAW_TX) before
# we've broadcast the first transaction (OLD_SIGNED_RAW_TX) will get 
# rejected.
# $CLI sendrawtransaction $NEW_SIGNED_RAW_TX

$CLI sendrawtransaction $OLD_SIGNED_RAW_TX
$CLI sendrawtransaction $NEW_SIGNED_RAW_TX

# We have once again not generated an additional block, so the transactions
# above have not yet become part of the regtest block chain. However, they 
# are part of the local node's memory pool
$CLI getrawmempool
