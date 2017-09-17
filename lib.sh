#!env /bin/bash

CLI='bitcoin-cli -regtest'

# How to use jq
RESULT=`bitcoin-cli -regtest listunspent`
UTXO1=`echo "$RESULT" | jq '.[0]'` 
# $ getconf ARG_MAX    # Get argument limit in bytes
# E.g. on Cygwin this is 32000, and on the different Linux distros I use it is anywhere from 131072 to 2621440.
# When the object string passed to these two functions, the bash will complain that [Argument list too long], so be careful!
