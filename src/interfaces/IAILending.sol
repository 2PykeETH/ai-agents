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
}
