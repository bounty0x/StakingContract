# Bounty0xStakingContract

Staking contract based on Zeppelin Contracts

## Requirements

To run tests you need to install the following software:

- [Truffle v4.0.4+](https://github.com/trufflesuite/truffle-core)
- [npm 5.6.0+](https://www.npmjs.com) 

## Deployment

To deploy smart contracts to local network do the following steps:
1. Go to the smart contract folder and run truffle console:
```sh
$ cd Bounty0xStakingContract
$ npm install
$ truffle develop
```
2. Inside truffle console, invoke "migrate" command to deploy contracts:
```sh
truffle> migrate
```


## How to test

Open the terminal and run the following commands:

```sh
$ cd Bounty0xStakingContract
$ npm install
$ truffle test
```