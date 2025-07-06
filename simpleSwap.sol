// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleSwap
 * @notice A minimal decentralized exchange (DEX) implementation supporting liquidity pools and token swaps
 * @dev Inherits from ERC20 to represent LP (Liquidity Provider) tokens
 */
contract SimpleSwap is ERC20 {
    /// @notice Emitted when liquidity is added to the pool
    /// @param user The address providing liquidity
    /// @param tokenA Address of first token in pair
    /// @param tokenB Address of second token in pair
    /// @param amountA Amount of tokenA deposited
    /// @param amountB Amount of tokenB deposited
    /// @param liquidity Amount of LP tokens minted
    event LiquidityAdded(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    /// @notice Emitted when liquidity is removed from the pool
    /// @param user The address removing liquidity
    /// @param tokenA Address of first token in pair
    /// @param tokenB Address of second token in pair
    /// @param amountA Amount of tokenA withdrawn
    /// @param amountB Amount of tokenB withdrawn
    /// @param liquidity Amount of LP tokens burned
    event LiquidityRemoved(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    /// @notice Emitted when a token swap occurs
    /// @param user The address executing the swap
    /// @param tokenIn Token being sold
    /// @param tokenOut Token being bought
    /// @param amountIn Amount of tokenIn transferred
    /// @param amountOut Amount of tokenOut transferred
    event TokensSwapped(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev Initializes the LP token with name "SimpleSwap" and symbol "SS"
     */
    constructor() ERC20("SimpleSwap", "SS") {}

    /**
     * @notice Adds liquidity to the token pair pool
     * @dev Mints LP tokens proportional to the square root of the product of amounts (Uniswap formula)
     * @param tokenA Address of first token in pair
     * @param tokenB Address of second token in pair
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @param to Address to receive LP tokens
     * @param deadline Unix timestamp after which transaction will revert
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(deadline >= block.timestamp, "Deadline expired");
    
        uint256 reserveA = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = ERC20(tokenB).balanceOf(address(this));
    
        // First liquidity provision
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = sqrt(amountA * amountB);
        } 
        // Subsequent liquidity additions
        else {
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
            liquidity = (amountA * totalSupply()) / reserveA;
        }

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        // Transfer tokens and mint LP tokens
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        _mint(to, liquidity);

        emit LiquidityAdded(to, tokenA, tokenB, amountA, amountB, liquidity);
        return (amountA, amountB, liquidity);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev Used for calculating initial liquidity
     * @param y Number to calculate square root of
     * @return z Square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        } 
        // else z = 0 (default)
    }

    /**
     * @notice Removes liquidity from the pool
     * @dev Burns LP tokens and returns underlying assets proportionally
     * @param tokenA Address of first token in pair
     * @param tokenB Address of second token in pair
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum acceptable amount of tokenA
     * @param amountBMin Minimum acceptable amount of tokenB
     * @param to Address to receive underlying tokens
     * @param deadline Unix timestamp after which transaction will revert
     * @return amountA Actual amount of tokenA received
     * @return amountB Actual amount of tokenB received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(deadline >= block.timestamp, "Deadline expired");
    
        amountA = (liquidity * ERC20(tokenA).balanceOf(address(this))) / totalSupply();
        amountB = (liquidity * ERC20(tokenB).balanceOf(address(this))) / totalSupply();
    
        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");
    
        _burn(msg.sender, liquidity);
        ERC20(tokenA).transfer(to, amountA);
        ERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(msg.sender, tokenA, tokenB, amountA, amountB, liquidity);
        return (amountA, amountB);
    }

    /**
     * @notice Swaps an exact amount of input tokens for minimum output tokens
     * @dev Uses constant product formula x*y=k
     * @param amountIn Exact amount of input tokens to swap
     * @param amountOutMin Minimum acceptable amount of output tokens
     * @param path Array with token addresses (must be length 2)
     * @param to Address to receive output tokens
     * @param deadline Unix timestamp after which transaction will revert
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(deadline >= block.timestamp, "Deadline expired");
        require(path.length == 2, "Invalid path");
    
        ERC20 tokenIn = ERC20(path[0]);
        ERC20 tokenOut = ERC20(path[1]);
    
        uint256 reserveIn = tokenIn.balanceOf(address(this));
        uint256 reserveOut = tokenOut.balanceOf(address(this));
        uint256 amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
    
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(to, amountOut);

        emit TokensSwapped(msg.sender, path[0], path[1], amountIn, amountOut);
    }

    /**
     * @notice Gets the current price ratio between two tokens
     * @dev Price is returned as tokenB per tokenA (scaled by 1e18)
     * @param tokenA Address of first token in pair
     * @param tokenB Address of second token in pair
     * @return price Price ratio (tokenB/tokenA)
     */
    function getPrice(address tokenA, address tokenB) public view returns (uint256) {
        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));
        require(balanceA > 0, "Insufficient reserves");
        return (balanceB * 1e18) / balanceA;
    }

    /**
     * @notice Calculates expected output amount for a given input
     * @dev Uses formula: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve amount of input token
     * @param reserveOut Reserve amount of output token
     * @return amountOut Expected output amount
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
