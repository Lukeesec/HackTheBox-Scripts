#!/bin/env python3

from web3 import Web3, HTTPProvider
import json

# Target
web3 = Web3(HTTPProvider('<URL>'))
web3.eth.defaultAccount = web3.eth.accounts[0]

# Address changes everytime machine is restarted
address = ""

# Checks if the machine is up (website is workign)
if web3.isConnected():
	print('Website is up and running')
else:
	print('Website is down')

# Opens up the contract and puts it into a var
with open('<CONTRACT>','r') as fs:
	contract = json.load(fs)

# Setting up the contract & signing
abi = contract['abi']
contract = web3.eth.contract(address=address,abi=abi)