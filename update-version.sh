#!/bin/bash

quit() {
  docker kill broker > /dev/null
  exit $1
}

if [ $# -eq 0 ]; then
    echo -e "Please provide the version\nExample: $0 0.24.1"
    exit 1
fi

echo "--- Starting camunda/zeebe:$1 broker ---"

docker run --rm -d -p 26500:26500 -p 9600:9600 --name broker camunda/zeebe:$1
if [ $? -ne 0 ]; then
    echo -e "Could not start broker with tag $1"
    exit 1
fi

curl 0.0.0.0:9600/ready
while [ $?  -ne 0 ]; do
  echo -e "Broker not yet ready. Retrying in 4 seconds"
  sleep 4
  curl 0.0.0.0:9600/ready
done

echo -e "\n--- Updating Zeebe dependency v$1 ---"

sed -i -- "s/v.*/v$1/g" go.mod
go mod tidy
if [ $? -ne 0 ]; then
  echo -e "Could not update go.mod file with tag v$1"
  quit $?
fi

cd src 
for gofile in *.go; do
  echo -e "\n--- Running example '$gofile' ---"

  go run $gofile
  if [ $? -ne 0 ] ; then
    echo "Failed to execute '$file': error code '$?'"
    quit $?
  fi
done

echo -e "\n--- Done --"
quit 0
