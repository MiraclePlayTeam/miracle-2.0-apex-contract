[
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "oldFeeRecipient",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "newFeeRecipient",
				"type": "address"
			}
		],
		"name": "ChangedFeeRecipient",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "token",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "enum ChainType",
				"name": "fromChain",
				"type": "uint8"
			},
			{
				"indexed": false,
				"internalType": "enum ChainType",
				"name": "toChain",
				"type": "uint8"
			},
			{
				"indexed": false,
				"internalType": "bytes32",
				"name": "metadata",
				"type": "bytes32"
			}
		],
		"name": "Exchange",
		"type": "event"
	},
	{
		"inputs": [],
		"name": "chainType",
		"outputs": [
			{
				"internalType": "enum ChainType",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_feeRecipient",
				"type": "address"
			}
		],
		"name": "changeFeeRecipient",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "contractType",
		"outputs": [
			{
				"internalType": "bytes32",
				"name": "",
				"type": "bytes32"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "contractVersion",
		"outputs": [
			{
				"internalType": "uint8",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "enum ChainType",
						"name": "toChain",
						"type": "uint8"
					},
					{
						"internalType": "address",
						"name": "token",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "tokenId",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "enum ErcType",
						"name": "ercType",
						"type": "uint8"
					},
					{
						"internalType": "bytes32",
						"name": "metadata",
						"type": "bytes32"
					}
				],
				"internalType": "struct Order",
				"name": "order",
				"type": "tuple"
			}
		],
		"name": "exchange",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "feeRecipient",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string",
				"name": "_name",
				"type": "string"
			},
			{
				"internalType": "address",
				"name": "_admin",
				"type": "address"
			},
			{
				"internalType": "enum ChainType",
				"name": "_chainType",
				"type": "uint8"
			},
			{
				"internalType": "address",
				"name": "_feeRecipient",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "_minterAndBurner",
				"type": "address"
			}
		],
		"name": "initialize",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "name",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "enum ChainType",
						"name": "fromChain",
						"type": "uint8"
					},
					{
						"internalType": "address",
						"name": "token",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "tokenId",
						"type": "uint256"
					},
					{
						"internalType": "address",
						"name": "receiver",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "bytes32",
						"name": "metadata",
						"type": "bytes32"
					},
					{
						"internalType": "address",
						"name": "currency",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "pricePerToken",
						"type": "uint256"
					},
					{
						"internalType": "bytes",
						"name": "data",
						"type": "bytes"
					}
				],
				"internalType": "struct AdminERC1155Order",
				"name": "order",
				"type": "tuple"
			}
		],
		"name": "sendERC1155ToUser",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "enum ChainType",
						"name": "fromChain",
						"type": "uint8"
					},
					{
						"internalType": "address",
						"name": "token",
						"type": "address"
					},
					{
						"internalType": "address",
						"name": "receiver",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "feeAmount",
						"type": "uint256"
					},
					{
						"internalType": "bytes32",
						"name": "metadata",
						"type": "bytes32"
					}
				],
				"internalType": "struct AdminERC20Order",
				"name": "order",
				"type": "tuple"
			}
		],
		"name": "sendERC20ToUser",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			},
			{
				"internalType": "enum ChainType",
				"name": "",
				"type": "uint8"
			},
			{
				"internalType": "enum ChainType",
				"name": "",
				"type": "uint8"
			}
		],
		"name": "txInfos",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]