// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol"; 
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";


contract DSCEnigneTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address weth;
    address wbtc;
    address wEthUsdPriceFeed;
    address wBtcPriceFeed;

    uint256 public constant AMOUNT_COLLATERALL = 1;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    address public USER = makeAddr("User");
    address public LIQUDATOR = makeAddr("LIQUDATOR");
    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        
        (wEthUsdPriceFeed,
         wBtcPriceFeed, 
         weth,
         wbtc,
        ) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(LIQUDATOR, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                               PRICE TEST
    //////////////////////////////////////////////////////////////*/

    function testPriceFeed() public {
        uint256 ethPrice = dsce.getUsdValue(weth, 1);
        uint256 btcPrice = dsce.getUsdValue(wbtc, 1);

        assertEq(ethPrice, 2000);
        assertEq(btcPrice, 60000);
    }

    function testTokenAmountEthFromUsd() public {
        uint256 ethToUsd = dsce.getTokenAmountFromUsd(weth, 10e18);
        uint256 expectedEth = 0.005 ether;
        assertEq(ethToUsd, expectedEth);
    }

    function testTokenAmountBTCFromUsd() public {
        uint256 btcToUsd = dsce.getTokenAmountFromUsd(wbtc, 60e18);
        
        assertEq(btcToUsd, 1e15);
    }


    /*//////////////////////////////////////////////////////////////
                           DEPOSITCOLLATERAL
    //////////////////////////////////////////////////////////////*/

    function testDepositCollateralFailIfZeroCollateral() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERALL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    // function testTokenAmountFromUsd() public {
    //     console.log(dsce.getTokenAmountFromUsd(weth, 10e18));
    //     console.log(dsce.getUsdValue(weth, 1));
    // }


    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TEST
    //////////////////////////////////////////////////////////////*/
    
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wEthUsdPriceFeed);
        priceFeedAddresses.push(wBtcPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);

        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                            REVERTS MODIFIER
    //////////////////////////////////////////////////////////////*/

    function testRevertIfZeroSend() public {

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);

        dsce.depositCollateral(address(weth), 0);
    }

    function testRevertIfIsNotAllowedToken() public {
        vm.expectRevert(DSCEngine. DSCEngine__NotAllowedToken.selector);
       
        dsce.depositCollateral(address(0), 1);
    }



    function testIfCollateralDeposotedChangeArray() public {
        vm.startPrank(USER);

        uint256 amountToCollateral = 2 ether;
        ERC20Mock(weth).increaseAllowance(address(dsce), 6 ether);
        dsce.depositCollateral(address(weth), amountToCollateral);

        vm.stopPrank();

        uint256 realAmountOfCollateral = dsce.getCollateralDepositedByAddress(address(USER), address(weth));
        assertEq(amountToCollateral, realAmountOfCollateral);
    }


    function testDepositCollateralAndMintDsc() public {
        vm.startPrank(USER);

        uint256 amountToCollateral = 2 ether;
        uint256 amountToMint = 1 ether;
        ERC20Mock(weth).increaseAllowance(address(dsce), 6 ether);
        dsce.depositCollateralAndMintDsc(weth, amountToCollateral, amountToMint);
        vm.stopPrank();

        uint256 dscBalanceAfterMint = dsc.balanceOf(address(USER));

        uint256 realAmountOfCollateral = dsce.getCollateralDepositedByAddress(address(USER), address(weth));

        assertEq(amountToCollateral, realAmountOfCollateral);
        assertEq(dscBalanceAfterMint, amountToMint);
    }

     
    function testRevertIfMintZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);

        dsce.mintDsc(0);
    }


    function testDSCMintedArrayIncreaseVolumeAfterMint() public {
        uint256 amountToCollateral = 1 ether;
        uint256 dscToMint = 1000 ether;
        vm.startPrank(USER);

        ERC20Mock(weth).increaseAllowance(address(dsce), 6 ether);
        dsce.depositCollateral(address(weth), amountToCollateral);
        dsce.mintDsc(dscToMint);

        vm.stopPrank();
        uint256 actualValueInArray = dsce.getMintedDSCByUser(address(USER));
        
        assertEq(actualValueInArray, dscToMint);

    }


    function testIfRevertWithBrokenHealthFactor() public {
        uint256 amountToCollateral = 1 ether;
        uint256 dscToMint = 1001 ether;
        vm.startPrank(USER);

        ERC20Mock(weth).increaseAllowance(address(dsce), 6 ether);
        dsce.depositCollateral(address(weth), amountToCollateral);
        vm.expectRevert( 
            abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 999000999000999000)
        );
        dsce.mintDsc(dscToMint);

        vm.stopPrank();
    }

    modifier depositAndMint() {
        uint256 amountToCollateral = 1 ether;
        uint256 dscToMint = 1000 ether;
        vm.startPrank(USER);

        ERC20Mock(weth).increaseAllowance(address(dsce), amountToCollateral);
        dsce.depositCollateralAndMintDsc(address(weth), amountToCollateral,dscToMint);
        vm.stopPrank();
        _;
    }


    /*//////////////////////////////////////////////////////////////
                                  BURN
    //////////////////////////////////////////////////////////////*/


    function testBurnWillDecreaseAmountOfDsc() public {
        uint256 amountToCollateral = 1 ether;
        uint256 dscToMint = 1000 ether;
        uint256 dscToBurn = 500 ether;

        vm.startPrank(USER);

        ERC20Mock(weth).increaseAllowance(address(dsce), 6 ether);
        dsce.depositCollateral(address(weth), amountToCollateral);
        dsce.mintDsc(dscToMint);
        uint256 dscAmountBeforeBurn = dsce.getMintedDSCByUser(address(USER));
        ERC20Mock(address(dsc)).increaseAllowance(address(dsce), 500 ether);
        dsce.burnDsc(dscToBurn);
        vm.stopPrank();
        uint256 dscAfterBurn = dsce.getMintedDSCByUser(address(USER));

        assertEq(dscAmountBeforeBurn, dscAfterBurn + dscToBurn);
    }

    function testRedeemCollateralDropErrorBecauseOfHealthFactor() depositAndMint public  {
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 999999999999999500));
        vm.prank(USER);
        dsce.redeemCollateral(weth, 500 wei);
    }

    function testRedeemCollateralWorks() depositAndMint  public {

        uint256 amountToRedeem = 1 ether;
        uint256 amountToAdd = 3 ether;

        vm.startPrank(USER);
        ERC20Mock(weth).increaseAllowance(address(dsce), amountToAdd);

        dsce.depositCollateral(address(weth), amountToAdd);

        uint256 amountCollateralBeforeReedem = dsce.getCollateralDepositedByAddress(address(USER), weth);

        dsce.redeemCollateral(weth, amountToRedeem);

        vm.stopPrank();

        uint256 amountCollateralAfterReedem = dsce.getCollateralDepositedByAddress(address(USER), weth);

        assertEq(amountCollateralAfterReedem, amountCollateralBeforeReedem - amountToRedeem);

    }

    function testRedeemCollateralForDscWillRedeemCollateralAndBurnDsc() depositAndMint public {
        uint256 amountToRedeem = 1 ether;
        uint256 amountToAdd = 3 ether;
        uint256 amountDscToBurn = 500 ether;
        uint256 startedAmountToCollateral = 1 ether;

        vm.startPrank(USER);
        ERC20Mock(weth).increaseAllowance(address(dsce), amountToAdd);
        dsce.depositCollateral(address(weth), amountToAdd);
        uint256 dscBalanceBeforeBurn = dsc.balanceOf(USER);
        uint256 collateralDepositedByUserBeforeRedeem = dsce.getCollateralDepositedByAddress(USER, weth);
        dsc.increaseAllowance(address(dsce), amountDscToBurn);
        dsce.redeemCollateralForDsc(weth, amountToRedeem, amountDscToBurn);
        
        vm.stopPrank();

        uint256 dscBalanceAfterBurn = dsc.balanceOf(USER);
        uint256 collateralDepositedByUserAfterRedeem = dsce.getCollateralDepositedByAddress(USER, weth);
        assertEq(dscBalanceAfterBurn, dscBalanceBeforeBurn - amountDscToBurn);
        assertEq(collateralDepositedByUserAfterRedeem, collateralDepositedByUserBeforeRedeem - amountToRedeem);

        assertEq(
            ERC20Mock(weth).balanceOf(USER), 
            STARTING_ERC20_BALANCE - startedAmountToCollateral - 
            amountToAdd + amountToRedeem );
    }

    function testHealthFactor() depositAndMint public  {
        uint256 healthFactor =  dsce.getHealthFactor(USER);
        assertEq(healthFactor, 1e18);
    }

    function testLiquidateWillThrowErrorIfHealthFactorIsOk() depositAndMint public {
        vm.prank(LIQUDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        dsce.liquidate(weth, address(USER), 500 wei);
    }

    function testLiquidation() depositAndMint public {
        dsce.changeHealthFactor(USER, weth);
        uint256 amountToCollateral = 1 ether;
        uint256 dscToMint = 1000 ether;
        vm.startPrank(LIQUDATOR);
        dsc.increaseAllowance(address(dsce), 500 ether);
        ERC20Mock(weth).increaseAllowance(address(dsce), amountToCollateral);
        dsce.depositCollateralAndMintDsc(address(weth), amountToCollateral, dscToMint);
        console.log(ERC20Mock(weth).balanceOf(address(dsce)));
        dsce.liquidate(weth, address(USER), 500 ether);
        console.log(ERC20Mock(weth).balanceOf(address(dsce)));

        vm.stopPrank();

    } 
} 