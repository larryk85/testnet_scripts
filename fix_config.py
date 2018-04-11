#! /usr/bin/python

import re, sys

if (len(sys.argv) < 7):
    print "Usage: python fix_config.py CONFIG_INI_PATH HTTP_PORT P2P_PORT STALE_PROD PUBLIC_KEY PRIVATE_KEY"
    print "\t`CONFIG_INI_PATH` : path to config.ini"
    print "\t`HTTP_PORT`       : port for http server"
    print "\t`P2P_PORT`        : port for p2p endpoint"
    print "\t`STALE`           : true/false for stale production"
    print "\t`PUB`             : public block signing key"
    print "\t`PRIV`            : private block signing key"
    exit(-1)

config = open(sys.argv[1], "r")

fixed_config = list()

http_re = re.compile("${HTTP}")
p2p_re = re.compile("${P2P}")
stale_re = re.compile("${STALE}")
pub_re = re.compile("${PUB}")
priv_re = re.compile("${PRIV}")
str_config = ""

for line in config:
    str_config += line

str_config = str_config.replace("${HTTP}", sys.argv[2])
str_config = str_config.replace("${P2P}", sys.argv[3])
str_config = str_config.replace("${STALE}", sys.argv[4])
str_config = str_config.replace("${PUB}", sys.argv[5])
str_config = str_config.replace("${PRIV}", sys.argv[6])

print str_config
