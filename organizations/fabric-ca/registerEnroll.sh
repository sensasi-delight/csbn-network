#!/bin/bash

function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/csbn.net

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/csbn.net

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:10154 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10154-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10154-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10154-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10154-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/csbn.net/msp/config.yaml"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:10154 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/msp" --csr.hosts orderer.csbn.net --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/csbn.net/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/msp/config.yaml"

  infoln "Generating the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:10154 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls" --enrollment.profile tls --csr.hosts orderer.csbn.net --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/server.key"

  mkdir -p "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/msp/tlscacerts/tlsca.csbn.net-cert.pem"

  mkdir -p "${PWD}/organizations/ordererOrganizations/csbn.net/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/csbn.net/orderers/orderer.csbn.net/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/csbn.net/msp/tlscacerts/tlsca.csbn.net-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:10154 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/csbn.net/users/Admin@csbn.net/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/csbn.net/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/csbn.net/users/Admin@csbn.net/msp/config.yaml"
}

function createPeer() {
  local ORG=$1
  local PORT=$2

  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/${ORG}.csbn.net/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:${PORT} --caname ca-${ORG} --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${PORT}-ca-${ORG}.pem
    OrganizationalUnitIdentifier: orderer" > "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/msp/config.yaml"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-${ORG} --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-${ORG} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-${ORG} --id.name ${ORG}admin --id.secret ${ORG}adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${PORT} --caname ca-${ORG} -M "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/msp" --csr.hosts peer0.${ORG}.csbn.net --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${PORT} --caname ca-${ORG} -M "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls" --enrollment.profile tls --csr.hosts peer0.${ORG}.csbn.net --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/keystore/"* "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/tlsca"
  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/tlsca/tlsca.${ORG}.csbn.net-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/ca"
  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/peers/peer0.${ORG}.csbn.net/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/ca/ca.${ORG}.csbn.net-cert.pem"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:${PORT} --caname ca-${ORG} -M "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/users/User1@${ORG}.csbn.net/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/users/User1@${ORG}.csbn.net/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://${ORG}admin:${ORG}adminpw@localhost:${PORT} --caname ca-${ORG} -M "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/users/Admin@${ORG}.csbn.net/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${ORG}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${ORG}.csbn.net/users/Admin@${ORG}.csbn.net/msp/config.yaml"
}