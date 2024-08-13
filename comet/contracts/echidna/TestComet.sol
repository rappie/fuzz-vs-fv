// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "@perimetersec/fuzzlib/src/IHevm.sol";

import "../Comet.sol";
import "../test/FaucetToken.sol";
import "../test/SimplePriceFeed.sol";

contract CometEchidnaHarness is Comet {
    constructor(Configuration memory config) Comet(config) {

    }

    function getTotalCollateral(address asset) public view returns (uint256) {
        return totalsCollateral[asset].totalSupplyAsset;
    }

    function getUserCollateral(address user, address asset, bool used) public view returns (uint256) {
        uint16 assetsIn = userBasic[user].assetsIn;
        Comet.AssetInfo memory assetInfo = getAssetInfoByAddress(asset);
        uint256 coll = 0;
        if (!used || isInAsset(assetsIn, assetInfo.offset)) {
            coll = userCollateral[user][asset].balance;
        }
        return coll;
    }

    function getAssetInfoByAddressExternal(address asset) external view returns (AssetInfo memory) {
        return getAssetInfoByAddress(asset);
    }
    function getAssetInOf(address user) external view returns (uint16) {
        return userBasic[user].assetsIn;
    }

    function isInAssetExternal(uint16 assetsIn, uint8 assetOffset) external view returns (bool) {
        return isInAsset(assetsIn, assetOffset);
    }

}

contract TestComet is FuzzBase {
    IHevm internal hevm = vm;

    uint256 internal constant STARTING_BALANCE = 1_000_000 ether;
    address internal currentActor;

    address[] internal ACTORS = [
        address(0x10000),
        address(0x20000),
        address(0x30000)
    ];

    modifier setCurrentActor() {
        address previousActor = currentActor;
        currentActor = msg.sender;
        _;
        currentActor = previousActor;
    }

    CometEchidnaHarness internal comet;
    Comet.AssetConfig[] internal assets;

    constructor() {
        string[15] memory symbols = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O"];
        uint8[15] memory decimals = [6, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18];
        uint16[15] memory price = [1, 175, 3000, 200, 100, 250, 60, 1400, 1700, 800, 800, 800, 800, 800, 800];
        FaucetToken token;
        SimplePriceFeed feed;

        for (uint8 i=0; i<15; ++i) {
            token = new FaucetToken(0, symbols[i], decimals[i], symbols[i]);
            feed = new SimplePriceFeed(int256(int16(price[i])) * 1e8, 8);
            assets.push(Comet.AssetConfig({
                asset: address(token),
                priceFeed: address(feed),
                decimals: decimals[i],
                borrowCollateralFactor: (1e18) - 1,
                liquidateCollateralFactor: 1e18,
                liquidationFactor: 1e18,
                supplyCap: uint128(1000000 * (10**decimals[i]))
            }));
        }
        
        Comet.Configuration memory config = Comet.Configuration({
            governor: address(0),
            pauseGuardian: address(0),
            baseToken: assets[0].asset,
            baseTokenPriceFeed: assets[0].priceFeed,
            kink: 8e17,
            perYearInterestRateBase: 5e15,
            perYearInterestRateSlopeLow: 1e17,
            perYearInterestRateSlopeHigh: 3e18,
            reserveRate: 1e17,
            trackingIndexScale: 1e15,
            baseTrackingSupplySpeed: 1e15,
            baseTrackingBorrowSpeed: 1e15,
            baseMinForRewards: 1e6,
            baseBorrowMin: 1e6,
            targetReserves: 0,
            assetConfigs: assets
        });

        comet = new CometEchidnaHarness(config);

        for (uint8 i = 0; i < 15; ++i) {
            token = FaucetToken(assets[i].asset);
            for(uint8 j = 0; j < ACTORS.length; ++j) {
                address actor = ACTORS[j];
                token.allocateTo(actor, STARTING_BALANCE);
                token.approveFrom(actor, address(comet), type(uint256).max);
            }
        }
    }

    function setPrice(uint256 assetId, uint256 price) public {
        assetId = assetId % 15;
        price = price % 100_000;
        SimplePriceFeed(assets[assetId].priceFeed).setPrice(int(price));
    }

    function supply(uint256 assetId, uint256 amount) public setCurrentActor {
        assetId = assetId % 15;
        address asset = assets[assetId].asset;

        amount = fl.clamp(amount, 0, FaucetToken(asset).balanceOf(currentActor));

        hevm.prank(currentActor);
        comet.supply(asset, amount);
    }

    function withdraw(uint256 assetId, uint amount) public setCurrentActor {
        assetId = assetId % 15;
        address asset = assets[assetId].asset;

        amount = amount % STARTING_BALANCE;

        hevm.prank(currentActor);
        comet.withdraw(asset, amount);
    }

    function withdrawBaseToken(uint amount) public {
        withdraw(0, amount);
    }

    function absorb(uint8 targetIndex) public setCurrentActor {
        targetIndex = uint8(fl.clamp(targetIndex, 0, ACTORS.length));
        address target = ACTORS[targetIndex];

        address[] memory accounts = new address[](1);
        accounts[0] = target;

        hevm.prank(currentActor);
        comet.absorb(currentActor, accounts);
    }

    function test_bit_per_balance() public {
        address[4] memory users = [address(this), address(0x10000), address(0x20000), address(0x30000)];
        for (uint8 u = 0; u < users.length; ++u) {
            address user = users[u];
            for (uint8 i = 0; i < assets.length; ++i) {
                address asset = assets[i].asset;
                uint16 assetsIn = comet.getAssetInOf(user);
                Comet.AssetInfo memory assetInfo = comet.getAssetInfoByAddressExternal(asset);
                bool bitOn = comet.isInAssetExternal(assetsIn, assetInfo.offset);
                bool hasColl = comet.collateralBalanceOf(user, asset) > 0;
                if (hasColl != bitOn) {
                    fl.t(false, "A userCollateral for a specific asset is greater than zero if and only if the corresponding flag is set");
                }
            }
        }
    }
}
