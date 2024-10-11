// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol"; 
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {

    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;
    address currentCollateral;
    uint256 amountCollateralDeposited;

    constructor (DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;
        
        address[] memory collateralTokens = dsce.getCollateralTokens();

        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {

        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        currentCollateral = address(collateral);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
        amountCollateralDeposited = amountCollateral;
        address user = msg.sender;
        vm.startPrank(user);
        collateral.increaseAllowance(address(dsce), amountCollateral);
        collateral.mint(msg.sender, amountCollateral);
        console.log(collateral.balanceOf(address(this)), 'balance');
        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock) {

        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;

    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateralToRedeem) public {
        depositCollateral(collateralSeed, amountCollateralToRedeem);

        amountCollateralToRedeem = bound(amountCollateralToRedeem, 1, amountCollateralDeposited);

        vm.startPrank(msg.sender);
        dsce.redeemCollateral(address(currentCollateral), amountCollateralToRedeem);
        vm.stopPrank();
    }

    function mintDsc(uint256 amountDscToMint) public {
        amountDscToMint = bound(amountDscToMint, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        dsce.mintDsc(amountDscToMint);
        vm.stopPrank();
        // mintDsc
    }
}