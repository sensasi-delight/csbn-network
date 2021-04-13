#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG_NAME}/$1/" \
        -e "s/\${ORG_NAME_LOWER}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG_NAME}/$1/" \
        -e "s/\${ORG_NAME_LOWER}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function generateCcp {
    local ORG_NAME=$1
    local ORG_NAME_LOWER=$2
    local P0PORT=$3
    local CAPORT=$4
    
    PEERPEM=organizations/peerOrganizations/$ORG_NAME_LOWER.csbn.net/tlsca/tlsca.$ORG_NAME_LOWER.csbn.net-cert.pem
    CAPEM=organizations/peerOrganizations/$ORG_NAME_LOWER.csbn.net/ca/ca.$ORG_NAME_LOWER.csbn.net-cert.pem

    echo "$(json_ccp $ORG_NAME $ORG_NAME_LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/$ORG_NAME_LOWER.csbn.net/connection-profile.json
    echo "$(yaml_ccp $ORG_NAME $ORG_NAME_LOWER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/$ORG_NAME_LOWER.csbn.net/connection-profile.yaml
}

generateCcp Courier courier 20151 20154
generateCcp Supp1 supp1 30151 30154
generateCcp Cust1 cust1 40151 40154

CH1=${1:-"false"}
if [ $CH1 = false ]; then
    generateCcp Supp2 supp2 30251 30254
    generateCcp Cust2 cust2 40251 40254
    generateCcp Supp3 supp3 30351 30354
    generateCcp Cust3 cust3 40351 40354
fi