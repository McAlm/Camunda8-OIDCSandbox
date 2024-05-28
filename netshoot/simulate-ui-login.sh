#!/bin/bash
# application dependent definitions
# take operate as default
client_id="operate-client"
client_secret="operate-clientsecret"
redirect_uri="http://csb-operate.docker:5010/identity-callback"
username="Operate"
password="pwd"
if [[ $1 = "identity" ]]
    then
        client_id="identity-client"
        client_secret="identity-clientsecret"
        redirect_uri="http://csb-identity.docker:5010/auth/login-callback"
        username="Identity"
        password="pwd"
fi

# application independent definitions
idp_url="http://csb-idp.docker:5010"
loginpage_file="/tmp/idp-loginpage.html"
lastheader_file="/tmp/idp-lastheader.txt"
cookie_file1="/tmp/idp-cookies1.txt"
cookie_file2="/tmp/idp-cookies2.txt"
token_file="/tmp/idp-token.json"
loginpage_params_regex="<input [^>]*name=\"Input\.ReturnUrl\" [^>]*value=\"([^\"]+)\"[^>]*/>.*<input [^>]*name=\"__RequestVerificationToken\" [^>]*value=\"([^\"]+)\"[^>]*/>"
location_header_regex="Location: (\S+)\r\n"


# call login page as the corresponding app would do
curl -c $cookie_file1 -L -s -D - -o $loginpage_file-file "$idp_url/connect/authorize?client_id=$client_id&redirect_uri=$redirect_uri&response_type=code&scope=openid+email+offline_access&state="

if [[ $(cat $loginpage_file-file) =~ $loginpage_params_regex ]]
then
    return_url=$(echo ${BASH_REMATCH[1]} | perl -MHTML::Entities -pe 'decode_entities($_);')
    echo "return_url = $return_url"
    request_verification_token=${BASH_REMATCH[2]}
    echo "request_verification_token = $request_verification_token"
fi

echo
echo "Username = $username"
echo "Password = $password"
echo
echo

# Send the filled login form back
curl -s -D $lastheader_file -b $cookie_file1 -c $cookie_file2\
    -X POST $idp_url/Account/Login \
    --data-urlencode "Input.ReturnUrl=$return_url" \
    --data-urlencode "Input.Username=$username" \
    --data-urlencode "Input.Password=$password" \
    --data-urlencode "Input.Button=login" \
    --data-urlencode "__RequestVerificationToken=$request_verification_token"

if [[ $(cat $lastheader_file) =~ $location_header_regex ]]
then
    next_location=${BASH_REMATCH[1]}
    echo
    echo "next_location = $next_location"
    echo
    echo
fi

# 
curl -s -D $lastheader_file -b $cookie_file2 $idp_url$next_location

if [[ $(cat $lastheader_file) =~ $location_header_regex ]]
then
    next_location=${BASH_REMATCH[1]}
    echo
    echo "next_location = $next_location"
    echo
    echo
fi

code_key=$(echo $next_location | awk -F '[?&=]' '{print $2}')
code_value=$(echo $next_location | awk -F '[?&=]' '{print $3}')

echo
echo "code_key = $code_key"
echo "code_value = $code_value"
echo
echo

curl -s -D - -b $cookie_file2 -o $token_file \
    -X POST $idp_url/connect/token \
    --data-urlencode "client_id=$client_id" \
    --data-urlencode "client_secret=$client_secret" \
    --data-urlencode "redirect_uri=$redirect_uri" \
    --data-urlencode "code=$code_value" \
    --data-urlencode "grant_type=authorization_code"

echo
echo "---------- Received token for user $username -----------"
cat $token_file | jq --color-output
