#!env /bin/bash

CLI='bitcoin-cli -regtest'

# Simple Raw Transaction

# Use the `listunspent` RPC to get the UTXOs belonging to this wallet.
UTXOS=`$CLI listunspent`

# Now we have three UTXOs: the two transactions we created before plus
# the coinbase transaction from block #2. We save the txid and output
# index number (vout) of that coinbase UTXO to variables.
# Node: use double quote when reference $UTXOS since it contains multiple
# lines.
UTXO=`echo "$UTXOS" | jq '.[] | select (.amount == 50.00000000)'`
UTXO_TXID=`echo "$UTXO" | jq '.txid'`
UTXO_VOUT=`echo "$UTXO" | jq '.vout'`

# Get a new address to use in the raw transaction
NEW_ADDRESS=`$CLI getnewaddress`

# Create a new raw format transaction
# The first argument (a JSON array) references the txid of the coinbase
# transaction from block #2 and the index number (0) of the output from
# that transaction we want to spent.
# The second argument (a JSON object) creates the output with the address
# (public key hash) and number of the bitcoins we want to transfer.
RAW_TX=`$CLI createrawtransaction '''
  [
    {
      "txid": '$UTXO_TXID',
      "vout": '$UTXO_VOUT'
    }
  ]
  ''' '''
  {
    "'$NEW_ADDRESS'": 49.9999
  }'''`

# Use the `decoderawtransaction` RPC to see exactly what the transaction
# we just create does.
# $CLI decoderawtransaction "$RAW_TX"

# Use the `signrawtransaction` RPC to sign the transaction created by
# `createrawtransaction` and save the return "hex" raw format signed
# transaction to a shell variable
SIGNED_RAW_TX_BODY=`$CLI signrawtransaction $RAW_TX`
SIGNED_RAW_TX=`echo "$SIGNED_RAW_TX_BODY" | jq '.hex' | tr -d '"'`

# Send the transaction to the connected node using the `sendrawtransaction`
# RPC.
$CLI sendrawtransaction $SIGNED_RAW_TX

# Generate a block to confirm the transaction
$CLI generate 1
