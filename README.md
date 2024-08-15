## Description
The purpose of this repository is to demonstrate that fuzzing is easily able to catch the bug mentioned [here](https://x.com/CertoraInc/status/1821588677111521380) with the invariant mentioned [here](https://x.com/CertoraInc/status/1821588670966841439).

Link to [fuzzing code](https://github.com/rappie/fuzz-vs-fv/blob/main/comet/contracts/echidna/TestComet.sol).

## Changes to the Fuzzing Suite
- Added function to fuzz price feed in order to allow `absorb` pass
- Introduced actors to significantly boost fuzzing efficiency
- Removed fuzzing repeat functionality
- Clamp transfer ERC20 token amounts to not exceed user balances

## Prerequisites

1. Install Echidna, follow the steps here: [Installation Guide](https://github.com/crytic/echidna#installation) using the latest master branch

2. Install dependencies with `yarn install`

## Instructions
Run with
```shell
cd comet
echidna . --contract TestComet --config config.yaml
```

## Broken Invariant Sequence
```
test_bit_per_balance(): failed!💥
  Call sequence:
    TestComet.supply(33599713855354106078310737180879058197,334849891882189)
    TestComet.supplyTo(1,188910566290528870039435775673750114489269716245,1002095)
    TestComet.withdrawBaseToken(1000144)
    TestComet.setPrice(2,0)
    TestComet.absorb(0)
    TestComet.test_bit_per_balance()
```

## Original Readme
https://github.com/Certora/fuzz-vs-fv/blob/main/README.md
