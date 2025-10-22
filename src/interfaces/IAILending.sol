// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAILendingPool
 * @notice Interface for the lending pool contract
 */
interface IAILending {
    
    // Structs
    struct UserInfo {
        uint256 collateralBalance;
        uint256 borrowBalance;
        uint256 borrowIndex;
    }

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 lpTokens);
    event Withdraw(address indexed user, uint256 amount, uint256 lpTokens);
        event DepositCollateral(address indexed user, uint256 amount);
            event WithdrawCollateral(address indexed user, uint256 amount);
                event Borrow(address indexed user, uint256 amount);
}
