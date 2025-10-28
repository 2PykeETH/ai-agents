// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IAILendingPool
 * @notice Interface for the lending pool contract
 */
interface IAILending {
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 lpTokens);
    event Withdraw(address indexed user, uint256 amount, uint256 lpTokens);
    event DepositCollateral(address indexed user, uint256 amount);
    event WithdrawCollateral(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Liquidation(
        address indexed liquidator, address indexed borrower, uint256 collateralSeized, uint256 debtRepaid
    );

    // Core functions
    function deposit(uint256 amount) external;
    function withdraw(uint256 lpTokenAmount) external;
    function depositCollateral(uint256 amount) external;
    function withdrawCollateral(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay(uint256 amount) external;
    function liquidate(address borrower, uint256 repayAmount) external;

    // View functions
    function getBorrowRate() external view returns (uint256);
    function getSupplyRate() external view returns (uint256);
    function getTotalAssets() external view returns (uint256);
    function getUserBorrowBalance(address user) external view returns (uint256);
    function getHealthFactor(address user) external view returns (uint256);
    function getUtilizationRate() external view returns (uint256);

    // State variables getters
    function totalDeposits() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
}
