## Prerequisites
* cUrl
* Git
* Docker
* node 12 & npm 6.14.11 (npm 7 not work?)
* tsc (node-typescript)

menambahkan core hyperledger fabric:
```bash
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.2 1.4.9 -d -s
```

## Usage
```bash
 # membangun network serta CA server masing-masing
./network.sh up -ca

# membuat channel dan memassukan org yg terkait di dalamnya
./network.sh createChannel -c channel0
./network.sh createChannel -c channel1 
./network.sh createChannel -c channel2
./network.sh createChannel -c channel3
./network.sh createChannel -c channel4

# deploy chaincode ke masing-masing channel dengan org terkait di dalamnya
./network.sh deployCC -ccn basic -ccp chaincode-typescript -ccl typescript -c channel0
./network.sh deployCC -ccn basic -ccp chaincode-typescript -ccl typescript -c channel1
./network.sh deployCC -ccn basic -ccp chaincode-typescript -ccl typescript -c channel2
./network.sh deployCC -ccn basic -ccp chaincode-typescript -ccl typescript -c channel3
./network.sh deployCC -ccn basic -ccp chaincode-typescript -ccl typescript -c channel4

 # menghentikan container docker tanpa menghapus data (ledger)
./network.sh down

 # restart container docker tanpa menghapus data
./network.sh restart

 # menghapus semua container docker
./network.sh demolition
```




dev mode, satu channel, tiga Org
up network dan membuat channel:
```bash
./network.sh createChannel -ch1
```
