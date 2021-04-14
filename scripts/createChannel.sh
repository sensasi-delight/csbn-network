#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {
	set -x
	configtxgen -profile $CH_PROFILE -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	setGlobals $1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:10150 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.csbn.net -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  FABRIC_CFG_PATH=$PWD/config/
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  docker exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
}

if [ "${CHANNEL_NAME}" == "channel0" ]; then
	ORGS=("supp1" "supp2" "supp3" "cust1" "cust2" "cust3")
elif [ "${CHANNEL_NAME}" == "channel1" ]; then
	ORGS=("courier" "supp1" "cust1")
elif [ "${CHANNEL_NAME}" == "channel2" ]; then
	ORGS=("courier" "supp2" "cust2")
elif [ "${CHANNEL_NAME}" == "channel3" ]; then
	ORGS=("courier" "supp2" "supp3")
elif [ "${CHANNEL_NAME}" == "channel4" ]; then
	ORGS=("courier" "supp3" "cust3")
else
	fatalln "CHANNEL Unknown"
fi

CH_PROFILE=${CHANNEL_NAME}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channeltx
infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
createChannelTx

FABRIC_CFG_PATH=$PWD/config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel ${ORGS[0]}
successln "Channel '$CHANNEL_NAME' created"

for ORG in ${ORGS[@]}
do
	joinChannel $ORG
done

for ORG in ${ORGS[@]}
do
	setAnchorPeer $ORG
done

successln "Channel '$CHANNEL_NAME' joined"
