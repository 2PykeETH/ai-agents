// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IAILending.sol";
import "./AILendingToken.sol";

/**
 * @title AILending
 * @notice A simple lending pool where users can deposit tokens to earn yield and borrow against collateral
 * @dev Implements a basic lending/borrowing mechanism with interest accrual
 */
contract AILending is IAILending, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    IERC20 public immutable asset;
    AILendingToken public immutable lpToken;

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

    constructor(address _asset, string memory _name, string memory _symbol) Ownable(msg.sender) {
        asset = IERC20(_asset);
        lpToken = new AILendingToken(_name, _symbol);
        borrowIndex = PRECISION;
        lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @notice Updates the borrow index based on accrued interest
     */
    function updateBorrowIndex() public {
        uint256 timeDelta = block.timestamp - lastUpdateTimestamp;
        if (timeDelta == 0) return;

        uint256 borrowRate = getBorrowRate();
        uint256 interestAccrued = (borrowRate * timeDelta * borrowIndex) / (SECONDS_PER_YEAR * BASIS_POINTS);
        borrowIndex += interestAccrued;
        lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @notice Deposits assets into the pool and mints LP tokens
     * @param amount Amount of assets to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        updateBorrowIndex();

        uint256 lpTokensToMint;
        if (lpToken.totalSupply() == 0) {
            lpTokensToMint = amount;
        } else {
            lpTokensToMint = (amount * lpToken.totalSupply()) / getTotalAssets();
        }

        asset.safeTransferFrom(msg.sender, address(this), amount);
        totalDeposits += amount;
        lpToken.mint(msg.sender, lpTokensToMint);

        emit Deposit(msg.sender, amount, lpTokensToMint);
    }

    /**
     * @notice Withdraws assets from the pool by burning LP tokens
     * @param lpTokenAmount Amount of LP tokens to burn
     */
       function withdraw(uint256 lpTokenAmount) external nonReentrant {
        require(lpTokenAmount > 0, "Amount must be greater than 0");
        require(lpToken.balanceOf(msg.sender) >= lpTokenAmount, "Insufficient LP tokens");
        updateBorrowIndex();
        
        uint256 assetsToWithdraw = (lpTokenAmount * getTotalAssets()) / lpToken.totalSupply();
        require(asset.balanceOf(address(this)) >= assetsToWithdraw, "Insufficient liquidity");
        
        lpToken.burn(msg.sender, lpTokenAmount);
        totalDeposits -= assetsToWithdraw;
        asset.safeTransfer(msg.sender, assetsToWithdraw);
        
        emit Withdraw(msg.sender, assetsToWithdraw, lpTokenAmount);
    }

   /**
     * @notice Deposits collateral to enable borrowing
     * @param amount Amount of collateral to deposit
     */
        function depositCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        asset.safeTransferFrom(msg.sender, address(this), amount);
        userInfo[msg.sender].collateralBalance += amount;
        
        emit DepositCollateral(msg.sender, amount);
    }
}
