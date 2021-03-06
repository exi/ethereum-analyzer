module Ethereum.Analyzer.TestData.StorageJson
  ( storageJson
  ) where

import Protolude hiding (show)

storageJson :: Text
storageJson =
  "{" <> "    \"contracts\": {" <> "        \"storage.sol:SimpleStorage\": {" <>
  "        }" <>
  "    }," <>
  "    \"sourceList\": [" <>
  "        \"storage.sol\"" <>
  "    ]," <>
  "    \"sources\": {" <>
  "        \"storage.sol\": {" <>
  "            \"AST\": {" <>
  "                \"children\": [" <>
  "                    {" <>
  "                        \"attributes\": {" <>
  "                            \"literals\": [" <>
  "                                \"solidity\"," <>
  "                                \"^\"," <>
  "                                \"0.4\"," <>
  "                                \".0\"" <>
  "                            ]" <>
  "                        }," <>
  "                        \"id\": 1," <>
  "                        \"name\": \"PragmaDirective\"," <>
  "                        \"src\": \"0:23:0\"" <>
  "                    }," <>
  "                    {" <>
  "                        \"attributes\": {" <>
  "                            \"fullyImplemented\": true," <>
  "                            \"isLibrary\": false," <>
  "                            \"linearizedBaseContracts\": [" <>
  "                                22" <>
  "                            ]," <>
  "                            \"name\": \"SimpleStorage\"" <>
  "                        }," <>
  "                        \"children\": [" <>
  "                            {" <>
  "                                \"attributes\": {" <>
  "                                    \"constant\": false," <>
  "                                    \"name\": \"storedData\"," <>
  "                                    \"storageLocation\": \"default\"," <>
  "                                    \"type\": \"uint256\"," <>
  "                                    \"visibility\": \"internal\"" <>
  "                                }," <>
  "                                \"children\": [" <>
  "                                    {" <>
  "                                        \"attributes\": {" <>
  "                                            \"name\": \"uint\"" <>
  "                                        }," <>
  "                                        \"id\": 2," <>
  "                                        \"name\": \"ElementaryTypeName\"," <>
  "                                        \"src\": \"52:4:0\"" <>
  "                                    }" <>
  "                                ]," <>
  "                                \"id\": 3," <>
  "                                \"name\": \"VariableDeclaration\"," <>
  "                                \"src\": \"52:15:0\"" <>
  "                            }," <>
  "                            {" <>
  "                                \"attributes\": {" <>
  "                                    \"constant\": false," <>
  "                                    \"name\": \"set\"," <>
  "                                    \"payable\": false," <>
  "                                    \"visibility\": \"public\"" <>
  "                                }," <>
  "                                \"children\": [" <>
  "                                    {" <>
  "                                        \"children\": [" <>
  "                                            {" <>
  "                                                \"attributes\": {" <>
  "                                                    \"constant\": false," <>
  "                                                    \"name\": \"x\"," <>
  "                                                    \"storageLocation\": \"default\"," <>
  "                                                    \"type\": \"uint256\"," <>
  "                                                    \"visibility\": \"internal\"" <>
  "                                                }," <>
  "                                                \"children\": [" <>
  "                                                    {" <>
  "                                                        \"attributes\": {" <>
  "                                                            \"name\": \"uint\"" <>
  "                                                        }," <>
  "                                                        \"id\": 4," <>
  "                                                        \"name\": \"ElementaryTypeName\"," <>
  "                                                        \"src\": \"85:4:0\"" <>
  "                                                    }" <>
  "                                                ]," <>
  "                                                \"id\": 5," <>
  "                                                \"name\": \"VariableDeclaration\"," <>
  "                                                \"src\": \"85:6:0\"" <>
  "                                            }" <>
  "                                        ]," <>
  "                                        \"id\": 6," <>
  "                                        \"name\": \"ParameterList\"," <>
  "                                        \"src\": \"84:8:0\"" <>
  "                                    }," <>
  "                                    {" <>
  "                                        \"children\": []," <>
  "                                        \"id\": 7," <>
  "                                        \"name\": \"ParameterList\"," <>
  "                                        \"src\": \"93:0:0\"" <>
  "                                    }," <>
  "                                    {" <>
  "                                        \"children\": [" <>
  "                                            {" <>
  "                                                \"children\": [" <>
  "                                                    {" <>
  "                                                        \"attributes\": {" <>
  "                                                            \"operator\": \"=\"," <>
  "                                                            \"type\": \"uint256\"" <>
  "                                                        }," <>
  "                                                        \"children\": [" <>
  "                                                            {" <>
  "                                                                \"attributes\": {" <>
  "                                                                    \"type\": \"uint256\"," <>
  "                                                                    \"value\": \"storedData\"" <>
  "                                                                }," <>
  "                                                                \"id\": 8," <>
  "                                                                \"name\": \"Identifier\"," <>
  "                                                                \"src\": \"99:10:0\"" <>
  "                                                            }," <>
  "                                                            {" <>
  "                                                                \"attributes\": {" <>
  "                                                                    \"type\": \"uint256\"," <>
  "                                                                    \"value\": \"x\"" <>
  "                                                                }," <>
  "                                                                \"id\": 9," <>
  "                                                                \"name\": \"Identifier\"," <>
  "                                                                \"src\": \"112:1:0\"" <>
  "                                                            }" <>
  "                                                        ]," <>
  "                                                        \"id\": 10," <>
  "                                                        \"name\": \"Assignment\"," <>
  "                                                        \"src\": \"99:14:0\"" <>
  "                                                    }" <>
  "                                                ]," <>
  "                                                \"id\": 11," <>
  "                                                \"name\": \"ExpressionStatement\"," <>
  "                                                \"src\": \"99:14:0\"" <>
  "                                            }" <>
  "                                        ]," <>
  "                                        \"id\": 12," <>
  "                                        \"name\": \"Block\"," <>
  "                                        \"src\": \"93:25:0\"" <>
  "                                    }" <>
  "                                ]," <>
  "                                \"id\": 13," <>
  "                                \"name\": \"FunctionDefinition\"," <>
  "                                \"src\": \"72:46:0\"" <>
  "                            }," <>
  "                            {" <>
  "                                \"attributes\": {" <>
  "                                    \"constant\": true," <>
  "                                    \"name\": \"get\"," <>
  "                                    \"payable\": false," <>
  "                                    \"visibility\": \"public\"" <>
  "                                }," <>
  "                                \"children\": [" <>
  "                                    {" <>
  "                                        \"children\": []," <>
  "                                        \"id\": 14," <>
  "                                        \"name\": \"ParameterList\"," <>
  "                                        \"src\": \"134:2:0\"" <>
  "                                    }," <>
  "                                    {" <>
  "                                        \"children\": [" <>
  "                                            {" <>
  "                                                \"attributes\": {" <>
  "                                                    \"constant\": false," <>
  "                                                    \"name\": \"\"," <>
  "                                                    \"storageLocation\": \"default\"," <>
  "                                                    \"type\": \"uint256\"," <>
  "                                                    \"visibility\": \"internal\"" <>
  "                                                }," <>
  "                                                \"children\": [" <>
  "                                                    {" <>
  "                                                        \"attributes\": {" <>
  "                                                            \"name\": \"uint\"" <>
  "                                                        }," <>
  "                                                        \"id\": 15," <>
  "                                                        \"name\": \"ElementaryTypeName\"," <>
  "                                                        \"src\": \"155:4:0\"" <>
  "                                                    }" <>
  "                                                ]," <>
  "                                                \"id\": 16," <>
  "                                                \"name\": \"VariableDeclaration\"," <>
  "                                                \"src\": \"155:4:0\"" <>
  "                                            }" <>
  "                                        ]," <>
  "                                        \"id\": 17," <>
  "                                        \"name\": \"ParameterList\"," <>
  "                                        \"src\": \"154:6:0\"" <>
  "                                    }," <>
  "                                    {" <>
  "                                        \"children\": [" <>
  "                                            {" <>
  "                                                \"children\": [" <>
  "                                                    {" <>
  "                                                        \"attributes\": {" <>
  "                                                            \"type\": \"uint256\"," <>
  "                                                            \"value\": \"storedData\"" <>
  "                                                        }," <>
  "                                                        \"id\": 18," <>
  "                                                        \"name\": \"Identifier\"," <>
  "                                                        \"src\": \"174:10:0\"" <>
  "                                                    }" <>
  "                                                ]," <>
  "                                                \"id\": 19," <>
  "                                                \"name\": \"Return\"," <>
  "                                                \"src\": \"167:17:0\"" <>
  "                                            }" <>
  "                                        ]," <>
  "                                        \"id\": 20," <>
  "                                        \"name\": \"Block\"," <>
  "                                        \"src\": \"161:28:0\"" <>
  "                                    }" <>
  "                                ]," <>
  "                                \"id\": 21," <>
  "                                \"name\": \"FunctionDefinition\"," <>
  "                                \"src\": \"122:67:0\"" <>
  "                            }" <>
  "                        ]," <>
  "                        \"id\": 22," <>
  "                        \"name\": \"ContractDefinition\"," <>
  "                        \"src\": \"25:166:0\"" <>
  "                    }" <>
  "                ]," <>
  "                \"name\": \"SourceUnit\"" <>
  "            }" <>
  "        }" <>
  "    }," <>
  "    \"version\": \"0.4.11+commit.68ef5810.Linux.g++\"" <>
  "}"
