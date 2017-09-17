#!env /bin/bash

CLI='bitcoin-cli -regtest'

# Simple Spending

# A block must have 100 confirmations before that reward can be spent,
# so we generate 101 blocks to get access to the coinbase transaction
# from block #1.
INIT_BLOCKS=`$CLI generate 101`

# Get a new Bitcoin address and save it in the variable $NEW_ADDRESS.
NEW_ADDRESS=`$CLI getnewaddress`

# Send 10 bitcoins to the address using the `sendtoaddress` RPC. The
# returned hex string is the transaction identifier (txid).
TXID=`$CLI sendtoaddress $NEW_ADDRESS 10.00`

# Create a new block to confirm the transaction above
CONFIRM_BLOCK=`$CLI generate 1`
