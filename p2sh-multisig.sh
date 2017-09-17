#!env /bin/bash

CLI='bitcoin-cli -regtest'

# P2SH Multisig

# Create three new P2PKH addresses.
# P2PKH addresses cannot be used in the multisig redeem script created below.
NEW_ADDRESS1=`$CLI getnewaddress`
NEW_ADDRESS2=`$CLI getnewaddress`
NEW_ADDRESS3=`$CLI getnewaddress`

# Use the `validateaddress` RPC to display the full (unhashed) public key for 
# one of the address.
NEW_ADDRESS3_PUBKEY_BODY=`$CLI validateaddress $NEW_ADDRESS3`
NEW_ADDRESS3_PUBLIC_KEY=`echo "$NEW_ADDRESS3_PUBKEY_BODY" | jq '.pubkey' | tr -d '"'`

# Use the `createmultisig` RPC with two arguments, the number (n) of signatures 
# required and a list of addresses or public keys.
P2SH_BODY=`$CLI createmultisig 2 '''
  [
    "'$NEW_ADDRESS1'",
    "'$NEW_ADDRESS2'", 
    "'$NEW_ADDRESS3_PUBLIC_KEY'"
  ]'''`

P2SH_ADDRESS=`echo "$P2SH_BODY" | jq '.address' | tr -d '"'`
P2SH_REDEEM_SCRIPT=`echo "$P2SH_BODY" | jq '.redeemScript' | tr -d '"'`

# Paying the P2SH multisig addresses with Bitcoin Core is as simple as paying a
# a more common P2PKH address.
UTXO_TXID=`$CLI sendtoaddress $P2SH_ADDRESS 10.00`

# We us `getrawtransaction` RPC with the optional second argument (true/1)a to 
# get the decoded transaction we just created with `sendtoaddress`.
TX_BODY=`$CLI getrawtransaction $UTXO_TXID 1`

# We choose one of the outputs to be out UTXO and get its output index number (
# vout) and pubkey script (scriptPubKey).
UTXO_VOUTS_BODY=`echo "$TX_BODY" | jq '.vout'`
UTXO_VOUT_BODY=`echo "$UTXO_VOUTS_BODY" | jq '.[] | select (.value == 10)'`
UTXO_VOUT=`echo "$UTXO_VOUT_BODY" | jq '.n'`
UTXO_OUTPUT_SCRIPT=`echo "$UTXO_VOUT_BODY" | jq '.scriptPubKey.hex' | tr -d '"'`

# We generate a new P2PKH address to use in the output we're about to create.
NEW_ADDRESS4=`$CLI getnewaddress`

# We generate the raw transaction the same way as we did in the Simple Raw 
# Transaction subsection
## Outputs - inputs = transaction fee, so always double-check your math!
RAW_TX=`$CLI createrawtransaction '''
  [
    {
      "txid": "'$UTXO_TXID'",
      "vout": '$UTXO_VOUT'
    }
  ]
  ''' '''
  {
    "'$NEW_ADDRESS4'": 9.998
  }'''`

# We get the private keys for two of the public keys we used to create the 
# transaction, the same way we got private keys in the Complex Raw Transaction
# subsection.
# Recall that we create a 2-of-3 multisig pubkey script, so signatures from two # private keys are needed.
NEW_ADDRESS1_PRIVATE_KEY=`$CLI dumpprivkey $NEW_ADDRESS1 | tr -d '"'`
NEW_ADDRESS3_PRIVATE_KEY=`$CLI dumpprivkey $NEW_ADDRESS3 | tr -d '"'`

# We make the first signature.
PARTLY_SIGNED_RAW_TX_BODY=`$CLI signrawtransaction $RAW_TX '''
  [
    {
      "txid": "'$UTXO_TXID'", 
      "vout": '$UTXO_VOUT', 
      "scriptPubKey": "'$UTXO_OUTPUT_SCRIPT'", 
      "redeemScript": "'$P2SH_REDEEM_SCRIPT'"
    }
  ]
  ''' '''
  [
    "'$NEW_ADDRESS1_PRIVATE_KEY'"
  ]'''`
PARTLY_SIGNED_RAW_TX=`echo "$PARTLY_SIGNED_RAW_TX_BODY" | jq '.hex' | tr -d '"'`

# The `signrawtransaction` call used here is nearly identical to the one used 
# above. The only difference is the private key used.
SIGNED_RAW_TX_BODY=`$CLI signrawtransaction $PARTLY_SIGNED_RAW_TX '''
  [
    {
      "txid": "'$UTXO_TXID'",
      "vout": '$UTXO_VOUT',
      "scriptPubKey": "'$UTXO_OUTPUT_SCRIPT'", 
      "redeemScript": "'$P2SH_REDEEM_SCRIPT'"
    }
  ]
  ''' '''
  [
    "'$NEW_ADDRESS3_PRIVATE_KEY'"
  ]'''`

SIGNED_RAW_TX=`echo "$SIGNED_RAW_TX_BODY" | jq '.hex' | tr -d '"'`

# We send the transaction spending the P2SH multisig output to the local node, 
# which accepts it.
