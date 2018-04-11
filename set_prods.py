#! /bin/python

import sys

prods_json = "{ \"version\":0, \"producers\": ["

if ( len(sys.argv) <= 1 ):
    print "Please specify producers"
    exit(-1)

for i in range(1, len(sys.argv)):
    name = sys.argv[i].split(",")[0]
    key = sys.argv[i].split(",")[1]
    prods_json += "{\"producer_name\":\""+name+"\", \"block_signing_key\": \""+key+"\"}"
    if ( i < len(sys.argv)-1 ):
        prods_json += ", "

prods_json += "] }"

print prods_json
