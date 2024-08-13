## Description
Link to [fuzzing code](https://github.com/rappie/fuzz-vs-fv/blob/main/comet/contracts/echidna/TestComet.sol).

Run with
```shell
cd comet
echidna . --contract TestComet --config config.yaml
```

## Broken Invariant Sequence
```
test_bit_per_balance(): failed!💥
  Call sequence:
    TestComet.supply(200,50951813222152630737590487381018564843764524130739086414974981058828678027319) from: 0x0000000000000000000000000000000000020000 Time delay: 601194 seconds Block delay: 60248
    TestComet.supply(60,115792089237316195423570985008687907853269984665640564039457584007913129639920) from: 0x0000000000000000000000000000000000010000 Time delay: 8 seconds Block delay: 9993
    TestComet.withdrawBaseToken(1099511627777) from: 0x0000000000000000000000000000000000020000 Time delay: 1700 seconds Block delay: 25831
    TestComet.setPrice(4370000,55944602810487043503190486917892490700392004581638913031223401667803164203943) from: 0x0000000000000000000000000000000000010000 Time delay: 114541 seconds Block delay: 193
    TestComet.absorb(17) from: 0x0000000000000000000000000000000000010000 Time delay: 478623 seconds Block delay: 3623
    TestComet.test_bit_per_balance() from: 0x0000000000000000000000000000000000010000 Time delay: 47 seconds Block delay: 254
```

## Original Readme
https://github.com/Certora/fuzz-vs-fv/blob/main/README.md
