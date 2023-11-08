
inactiveProxy=`curl -sX POST https:/your_Zabbix_server.com/api_jsonrpc.php HTTP/1.1  --insecure -H "Content-Type: application/json" -d ' {   "jsonrpc": "2.0",  "method": "proxy.get", "params": {},  "auth":"yourauthtoken", "id": youruserID}' | jq '.result[] | select( (.proxy_address|test("proxy-01")) or (.proxy_address|test("proxy-02")) ) | .lastaccess' | tr -d '"' | sort -nr| tail -n 1`

inactiveproxyID=`curl -sX POST https:/your_Zabbix_server.com/api_jsonrpc.php HTTP/1.1  --insecure -H "Content-Type: application/json" -d ' {   "jsonrpc": "2.0",  "method": "proxy.get", "params": {},  "auth":"yourauthtoken", "id": youruserID}' | jq '.result[] | select(.lastaccess == "'$inactiveProxy'") | .proxyid'`

simpleID=` echo $inactiveproxyID | tr -d '"'`

activeproxyID=`curl -sX POST https:/your_Zabbix_server.com/api_jsonrpc.php HTTP/1.1  --insecure -H "Content-Type: application/json" -d ' {   "jsonrpc": "2.0",  "method": "proxy.get", "params": {},  "auth":"yourauthtoken", "id": youruserID}' | jq '.result[] | select((.lastaccess != "'$inactiveProxy'") and (.proxy_address|test("proxy-01")) or (.proxy_address|test("proxy-02"))) | .proxyid' | tr -d '"' | grep -v $simpleID`


listOfHosts=`curl -sX POST https:/your_Zabbix_server.com/api_jsonrpc.php HTTP/1.1  --insecure -H "Content-Type: application/json" -d '{     "jsonrpc": "2.0",     "method": "host.get",     "params": {         "output": "extend"     },     "auth":"yourauthtoken",      "id": youruserID }' | jq '.result[] | select(.proxy_hostid|test('$inactiveproxyID')) | .hostid'`

if [ -z "$listOfHosts" ]
then

	echo List of Hosts is empty. Nothing do to. Quitting...

	exit 0

else 

cat << EOF > proxyUpdate.json 
{
  "jsonrpc": "2.0",
  "method": "proxy.update",
  "params": {
    "proxyid": "",
    "hosts":
    [
    ]
  },
  "auth": "yourauthtoken",
  "id": youruserid
}
EOF

 
listOfProxyHosts=`for host in $listOfHosts; do echo { \"hostid\": "$host" },;done | sed '$ s/.$/]/' | sed '1s/^/[/'`

sed -i "s/\"proxyid\":.*/\"proxyid\": \"$activeproxyID\",/" proxyUpdate.json

list=`jq  --argjson hostids "$(echo $listOfProxyHosts)" '.params.hosts  += $hostids' proxyUpdate.json`


	curl -sX POST https:/your_zabbix_server.com/api_jsonrpc.php HTTP/1.1  --insecure -H "Content-Type: application/json" -d "$(echo $list)"
fi

