#!/bin/bash

echo "Compile"

solc contracts/ReviewSystem.sol --abi --bin --pretty-json --overwrite -o out

cp out/ReviewLibrary.abi out/ReviewLibrary.json
cp out/ReviewSystem.abi out/ReviewSystem.json
cp out/TransactionLibrary.abi out/TransactionLibrary.json

echo "Done"

