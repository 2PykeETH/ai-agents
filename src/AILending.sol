// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
//import "./interfaces/IAILending.sol";
//import "./LendingPoolToken.sol";

/**
 * @title AILending
 * @notice A simple lending pool where users can deposit tokens to earn yield and borrow against collateral
 * @dev Implements a basic lending/borrowing mechanism with interest accrual
 */
contract AILending is ILendingPool, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    IERC20 public immutable asset;
    LendingPoolToken public immutable lpToken;

    uint256 public totalDeposits;
    uint256 public totalBorrows;
    uint256 public lastUpdateTimestamp;
    uint256 public borrowIndex;

    // Interest rate model parameters (annual rates in basis points)
    uint256 public constant BASE_RATE = 200; // 2%
    uint256 public constant SLOPE1 = 1000; // 10%
    uint256 public constant SLOPE2 = 5000; // 50%
    uint256 public constant OPTIMAL_UTILIZATION = 8000; // 80%
    uint256 public constant MAX_UTILIZATION = 9500; // 95%

    // Collateralization parameters
    uint256 public constant COLLATERAL_FACTOR = 7500; // 75% - max borrow vs collateral
    uint256 public constant LIQUIDATION_THRESHOLD = 8500; // 85% - liquidation threshold
    uint256 public constant LIQUIDATION_BONUS = 500; // 5% - liquidator bonus

    // Precision constants
    uint256 public constant PRECISION = 1e18;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // User data
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 collateralBalance;
        uint256 borrowBalance;
        uint256 borrowIndex;
    }
}
