# testnet_scripts
## Small set of scripts to run an n-node testnet.

To run:
1. modify the EOS variable in *run.sh* to point to your eosio build
2. modify *net.map* to reflect the desired network connections
    * node 0 is the bios node
    * the mapping is `n : m`, which means connect node *n* to *m*
3. run *run.sh*, it will start m nodes which is the max node from *net.map*

To use:
1. `c or C` will connect a node *n* to *m*
2. `d or D` will disconnect a node *n* from *m*
3. `k or K` will kill a node *n*
4. `x or X` will exit the testnet, kill all nodes and destroy any temporary data (this includes the chain data)

To analyze nodes:
1. Run *tail -f node.`n`.out* to see the nodes output in realtime.
