#! /usr/bin/python

import sys
from subprocess import call

http_port_base = 8801

if (len(sys.argv) < 3):
    print("Error, please specify a network map and path to cleos")
    exit(-1)

infile = open( sys.argv[1], "r")
cleos = sys.argv[2]

for line in infile:
    a = int(line.split(":")[0])
    b = int(line.split(":")[1]) 
    port_a = 0
    port_b = 0
    p2p_a = 0
    p2p_b = 0

    if ( a == 0 ):
        port_a = 8888 
        p2p_a  = 9876
    else:
        port_a = 8800+a
        p2p_a  = 9800+a

    if ( b == 0 ):
        port_b = 8888 
        p2p_b  = 9876
    else:
        port_b = 8800+b
        p2p_b  = 9800+b
      
    print "Connecting "+str(p2p_a)+" to "+str(p2p_b) 
    call([cleos,"-p"+str(port_a),"net", "connect", "localhost:"+str(p2p_b)])
