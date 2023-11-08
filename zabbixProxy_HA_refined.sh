#!/bin/bash

# Zabbix server URL
zabbix_server="https://your_Zabbix_server.com"

# Zabbix API credentials
auth_token="yourauthtoken"
user_id="youruserID"

# Function to make API requests
api_request() {
  local endpoint="$1"
  local data="$2"
  
  curl -sX POST "$zabbix_server/api_jsonrpc.php" HTTP/1.1 --insecure -H "Content-Type: application/json" -d "$data"
}

# Get the last access time for inactive proxies that match "proxy-01" or "proxy-02,"
# sort them in reverse order, and get the most recent one.
data='{
  "jsonrpc": "2.0",
  "method": "proxy.get",
  "params": {},
  "auth": "'$auth_token'",
  "id": '$user_id'
}'
inactiveProxy=$(api_request "$data" | jq '.result[] | select((.proxy_address|test("proxy-01")) or (.proxy_address|test("proxy-02"))) | .lastaccess' | tr -d '"' | sort -nr | tail -n 1)

# Get the proxy ID of the inactive proxy with the last access time matching the found inactiveProxy.
data='{
  "jsonrpc": "2.0",
  "method": "proxy.get",
  "params": {},
  "auth": "'$auth_token'",
  "id": '$user_id'
}'
inactiveproxyID=$(api_request "$data" | jq '.result[] | select(.lastaccess == "'$inactiveProxy'") | .proxyid')

# Remove quotes from the inactiveproxyID.
simpleID=$(echo $inactiveproxyID | tr -d '"')

# Get the proxy ID of active proxies (not matching the inactiveProxy) with "proxy-01" or "proxy-02."
data='{
  "jsonrpc": "2.0",
  "method": "proxy.get",
  "params": {},
  "auth": "'$auth_token'",
  "id": '$user_id'
}'
activeproxyID=$(api_request "$data" | jq '.result[] | select((.lastaccess != "'$inactiveProxy'") and (.proxy_address|test("proxy-01")) or (.proxy_address|test("proxy-02"))) | .proxyid' | tr -d '"' | grep -v $simpleID)

# Retrieve a list of hosts associated with the inactiveproxyID.
data='{
  "jsonrpc": "2.0",
  "method": "host.get",
  "params": {
    "output": "extend"
  },
  "auth": "'$auth_token'",
  "id": '$user_id'
}'
listOfHosts=$(api_request "$data" | jq '.result[] | select(.proxy_hostid|test('$inactiveproxyID')) | .hostid')

# Check if the list of hosts is empty.
if [ -z "$listOfHosts" ]; then
  echo "List of Hosts is empty. Nothing to do. Quitting..."
  exit 0
else
  # Create a JSON file to update the proxy with the activeproxyID and list of hosts.
  cat << EOF > proxyUpdate.json
{
  "jsonrpc": "2.0",
  "method": "proxy.update",
  "params": {
    "proxyid": "$activeproxyID",
    "hosts": []
  },
  "auth": "'$auth_token'",
  "id": '$user_id'
}
EOF

  # Format the list of proxy hosts and update the proxyUpdate.json file.
  listOfProxyHosts=$(for host in $listOfHosts; do echo { \"hostid\": "$host" },; done | sed '$ s/.$/]/' | sed '1s/^/[/')
  sed -i "s/\"proxyid\":.*/\"proxyid\": \"$activeproxyID\",/" proxyUpdate.json
  list=$(jq --argjson hostids "$(echo $listOfProxyHosts)" '.params.hosts += $hostids' proxyUpdate.json)

  # Use the updated JSON file to update the proxy with the list of hosts.
  data="$list"
  api_request "$data"
fi
