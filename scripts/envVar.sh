#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/msp/tlscacerts/tlsca.csbn.net-cert.pem
# export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/server.crt
# export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/server.key


# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"

  if [ "$USING_ORG" == "courier" ]; then
    export CORE_PEER_LOCALMSPID="CourierMSP"
    export CORE_PEER_ADDRESS=localhost:20151
  elif [ "$USING_ORG" == "supp1" ]; then
    export CORE_PEER_LOCALMSPID="Supp1MSP"
    export CORE_PEER_ADDRESS=localhost:30151
  elif [ "$USING_ORG" == "supp2" ]; then
    export CORE_PEER_LOCALMSPID="Supp2MSP"
    export CORE_PEER_ADDRESS=localhost:30251
  elif [ "$USING_ORG" == "supp3" ]; then
    export CORE_PEER_LOCALMSPID="Supp3MSP"
    export CORE_PEER_ADDRESS=localhost:30351
  elif [ "$USING_ORG" == "cust1" ]; then
    export CORE_PEER_LOCALMSPID="Cust1MSP"
    export CORE_PEER_ADDRESS=localhost:40151
  elif [ "$USING_ORG" == "cust2" ]; then
    export CORE_PEER_LOCALMSPID="Cust2MSP"
    export CORE_PEER_ADDRESS=localhost:40251
  elif [ "$USING_ORG" == "cust3" ]; then
    export CORE_PEER_LOCALMSPID="Cust3MSP"
    export CORE_PEER_ADDRESS=localhost:40351
  else
    errorln "ORG Unknown"
  fi

  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/${USING_ORG}.csbn.net/peers/peer0.${USING_ORG}.csbn.net/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/${USING_ORG}.csbn.net/users/Admin@${USING_ORG}.csbn.net/msp

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container 
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  local PORT=00000

  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi


  if [ "$USING_ORG" == "courier" ]; then
    PORT=20151
  elif [ "$USING_ORG" == "supp1" ]; then
    PORT=30151
  elif [ "$USING_ORG" == "supp2" ]; then
    PORT=30251
  elif [ "$USING_ORG" == "supp3" ]; then
    PORT=30351
  elif [ "$USING_ORG" == "cust1" ]; then
    PORT=40151
  elif [ "$USING_ORG" == "cust2" ]; then
    PORT=40251
  elif [ "$USING_ORG" == "cust3" ]; then
    PORT=40351
  else
    errorln "ORG Unknown"
  fi

  export CORE_PEER_ADDRESS=peer0.${USING_ORG}.csbn.net:${PORT}
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.${1}"

    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles \$CORE_PEER_TLS_ROOTCERT_FILE")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
