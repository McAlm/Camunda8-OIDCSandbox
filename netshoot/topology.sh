#!/bin/bash
tokenep=$(curl -s http://idp:5000/.well-known/openid-configuration | jq -r '.token_endpoint')
echo
echo '---- token endpoint-----------'
echo $tokenep
at=$(curl -s -d "client_id=zeebe-client&client_secret=zeebe-clientsecret&grant_type=client_credentials" $tokenep | jq -r '.access_token')
ath=$(echo "Authorization: Bearer $at")
echo
echo '---- access token ------------'
echo $ath
echo
echo '---- topology no auth --------'
grpcurl -import-path /tmp/netshoot -proto /tmp/netshoot/gateway.proto -plaintext zeebe:26500 gateway_protocol.Gateway.Topology
echo
echo '---- topology with auth ------'
grpcurl -import-path /tmp/netshoot -proto /tmp/netshoot/gateway.proto -H "$ath" -plaintext zeebe:26500 gateway_protocol.Gateway.Topology
echo
echo '---- topology with auth via REST ------'
curl -H "$ath" http://zeebe:8080/v1/topology