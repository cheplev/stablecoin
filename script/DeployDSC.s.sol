//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    DecentralizedStableCoin private dsc;
    DSCEngine private dsce;
    HelperConfig private helperConfig;
    address[] public tokenAddreses;
    address[] public tokenPriceFeed;

    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        helperConfig = new HelperConfig();
        (address wEthUsdPriceFeed, 
            address wBtcPriceFeed, 
            address weth, 
            address wbtc, 
            uint256 deployerKey ) = helperConfig.activeNetworkConfig();

         tokenAddreses = [weth, wbtc];
         tokenPriceFeed = [wEthUsdPriceFeed, wBtcPriceFeed];

        vm.startBroadcast();
        dsc = new DecentralizedStableCoin();
        dsce = new DSCEngine(tokenAddreses, tokenPriceFeed, address(dsc));
        dsc.transferOwnership(address(dsce));
        vm.stopBroadcast();

        return (dsc, dsce, helperConfig);
    }
}