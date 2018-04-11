#! /bin/bash

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LGRAY='\033[0;37m'
DGRAY='\033[1;30m'
WHITE='\033[1;37m'
NC='\033[0m'

TESTNET_DIR='/tmp/testnet'

EOS=~/eeos/eos/build

BIOS_HTTP=8888
BIOS_P2P=9876

CLEOS=${EOS}/programs/cleos/cleos
NODEOS=${EOS}/programs/nodeos/nodeos
BIOS_PID=0
NODE_PIDS=()
PRODUCERS=()

NODES=0
if [ "$#" -gt "0" ] && [ "$1" -ge "1" ]; then
   NODES=$1
fi

IFS=$' =' read -a var <<< $(sort -t= -nr -k3 net.map | head -1)
NODES=$(( var[0] > var[2] ? var[0] : var[2] ))

fix_config() {
   sed -e 's/\${HTTP}/'"$2"'/g; s/\${P2P}/'"$3"'/g; s/\${STALE}/'"$4"'/g; s/\${PUB}/'"$5"'/g; s/\${PRIV}/'"$6"'/g; s/\${PROD_NAME}/'"$7"'/g' < config.ini > $1

}

run_bios() {
   BIOS_DIR=${TESTNET_DIR}/bios
   mkdir ${BIOS_DIR} 
   fix_config ${BIOS_DIR}/config.ini ${BIOS_HTTP} ${BIOS_P2P} true EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3 eosio

   printf "${CYAN}Starting Bios Node at [${WHITE}${BIOS_HTTP}, ${BIOS_P2P}${CYAN}]\n${NC}"
   ${NODEOS} -d ${BIOS_DIR} --config-dir ${BIOS_DIR} &> outputs/bios.out &
   BIOS_PID=$!
   sleep 0.3
   WALLET_PW=`${CLEOS} -p ${BIOS_HTTP} wallet create | grep -e "\".*\"" | sed -e "s/\"//g"`
   printf "${BLUE}Created wallet [${LGRAY}${WALLET_PW}${BLUE}]${NC}\n"
   printf "${BLUE}Unlocking wallet ${NC}\n"
   sleep 0.2
   echo "spawn ${CLEOS} -p ${BIOS_HTTP} wallet unlock; expect \"password:\" {send \"${WALLET_PW}\r\"}" | expect &>  /dev/null
   printf "${BLUE}Setting eosio.bios ${NC}\n"
   ${CLEOS} -p ${BIOS_HTTP} set contract eosio ${EOS}/contracts/eosio.bios &> /dev/null
   echo ""
}

run_node() {
   NODE_DIR=${TESTNET_DIR}/node.$1
   mkdir ${NODE_DIR} 
   KEY=`${CLEOS} -p ${BIOS_HTTP} create key`
   PRIV=`echo $KEY | sed -e "s/Private key: //g; s/ Public.*//g"`
   PUB=`echo $KEY | sed -e "s/.*Public key: //g"`

   fix_config ${NODE_DIR}/config.ini 880$1 980$1 false ${PUB} ${PRIV} node.$1
   
   cp ${BIOS_DIR}/genesis.json ${NODE_DIR}/genesis.json
   printf "${BLUE}Creating account ${BROWN}node.$1${BLUE} with keys \n\tpublic:${LGRAY}${PUB}\n\t${BLUE}private:${LGRAY} ${PRIV}\n${NC}"
   ${CLEOS} -p ${BIOS_HTTP} create account eosio node.$1 ${PUB} ${PUB} &> /dev/null
   printf "${CYAN}Starting node.$1 at [${WHITE}880$1, 980$1${CYAN}]\n${NC}"
   ${NODEOS} -d ${NODE_DIR} --config-dir ${NODE_DIR} &> outputs/node.$1.out &
   NODE_PIDS+=($!)
   PRODS+=("node.$1,${PUB}")
   echo ""
}

set_producers() {
   python set_prods.py ${PRODS[@]} > ${TESTNET_DIR}/prods.json
   printf "${CYAN}Setting producers\n${NC}"
   ${CLEOS} -p ${BIOS_HTTP} push action eosio setprods ${TESTNET_DIR}/prods.json -p eosio@active  &> /dev/null
   echo ""
}

get_response() {
   printf "${WHITE}Press [x|X] to quit, [k|K] to kill a node, [c|C] to connect a node, or [d|D] to disconnect a node${NC}"
   read -r -p "" response

   case "${response}" in
      [kK])
         printf "${BROWN}Kill which node?${NC}"
         read -r -p "" _node
         case "${_node}" in
            [0])
               printf "${BROWN}Killing bios node\n${NC}"
               kill ${BIOS_PID}
               ;;
            *)
               printf "${BROWN}Killing node\n${NC}"
               kill ${NODE_PIDS[${_node}]}
               ;;
         esac
         get_response
         ;;
      [xX])
         for pid in "${NODE_PIDS[@]}"; do
            printf "${BROWN}Killing node\n${NC}"
            kill ${pid} &> /dev/null
         done

         printf "${BROWN}Killing bios node\n${NC}"
         kill ${BIOS_PID} &> /dev/null

         rm -r ${TESTNET_DIR}
         ;;
      [cC])
         printf "${BROWN}Which node to connect?\n${NC}"
         read -r -p "" _node
         case "${_node}" in
            [0])
               printf "${BROWN}Connecting to which node?\n${NC}"
               read -r -p "" __node
               case "${__node}" in
               [0])
                  printf "${BROWN}Connecting bios node to itself? ${__node}\n${NC}"
                  ${CLEOS} -p8888 net connect localhost:9876
                  get_response
                  ;;
               *)
                  printf "${BROWN}Connecting node ${_node} to node ${__node}\n${NC}"
                  ${CLEOS} -p880${_node} net connect localhost:980${__node}
                  get_response
                  ;;
               esac
               ;;
            *)
               printf "${BROWN}Connecting to which node?\n${NC}"
               read -r -p "" __node
               case "${__node}" in
               [0])
                  printf "${BROWN}Connecting node ${_node} to bios node\n${NC}"
                  ${CLEOS} -p880${_node} net connect localhost:9876
                  get_response
                  ;;
               ["${_node}"])
                  printf "${BROWN}Connecting node ${_node} to itself? ${__node}\n${NC}"
                  ${CLEOS} -p880${_node} net connect localhost:980${_node}
                  get_response
                  ;;

               *)
                  printf "${BROWN}Connecting node ${_node} to node ${__node}\n${NC}"
                  ${CLEOS} -p880${_node} net connect localhost:980${__node}
                  get_response
                  ;;
               esac
               ;;
         esac
         ;;
      [dD])
         printf "${BROWN}Which node to disconnect?\n${NC}"
         read -r -p "" _node
         case "${_node}" in
            [0])
               printf "${BROWN}Disconnecting to which node?\n${NC}"
               read -r -p "" __node
               case "${__node}" in
               [0])
                  printf "${BROWN}Disconnecting bios node to itself? ${__node}\n${NC}"
                  ${CLEOS} -p8888 net disconnect localhost:9876
                  get_response
                  ;;
               *)
                  printf "${BROWN}Disconnecting node ${_node} to node ${__node}\n${NC}"
                  ${CLEOS} -p880${_node} net disconnect localhost:980${__node}
                  get_response
                  ;;
               esac
               ;;
            *)
               printf "${BROWN}Disconnecting to which node?\n${NC}"
               read -r -p "" __node
               case "${__node}" in
               [0])
                  printf "${BROWN}Disconnecting node ${_node} to bios node\n${NC}"
                  ${CLEOS} -p880${_node} net disconnect localhost:9876
                  get_response
                  ;;
               ["${_node}"])
                  printf "${BROWN}Disconnecting node ${_node} to itself? ${__node}\n${NC}"
                  ${CLEOS} -p880${_node} net disconnect localhost:980${_node}
                  get_response
                  ;;

               *)
                  printf "${BROWN}Disconnecting node ${_node} to node ${__node}\n${NC}"
                  ${CLEOS} -p880${_node} net disconnect localhost:980${__node}
                  get_response
                  ;;
               esac
               ;;
         esac
         ;;

      *)
         get_response
         ;;
   esac
}

printf "${GREEN}\t--- Starting EOSIO Local Testnet ---\n\n${NC}"

printf "${RED}"
mkdir -p ${TESTNET_DIR} 
if [ $? != 0 ]; then
   printf "${RED}Error, ${LGRAY}Please verify that we are not overwriting anything, rm -r /tmp/testnet if not${NC}\n"
   exit -1
fi

run_bios

for i in $(seq 1 $NODES); do
  run_node $i 
done

if [ "${#PRODS[@]}" -gt "0" ]; then
   set_producers
fi
sleep 0.2
python parse_map.py net.map ${CLEOS}

get_response
