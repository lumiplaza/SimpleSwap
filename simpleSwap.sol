// SPDX-License-Identifier: MIT
// License identifier (MIT open source)
pragma solidity ^0.8.0;
// Compiler version requirement (0.8.0 or higher)

/**
 * @dev Standard ERC20 Interface
 */
interface IERC20 {
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Functions
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @dev SimpleSwap Interface - Core DEX functions
 */
interface ISimpleSwap {
    // Adds liquidity to the pool
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    // Removes liquidity from the pool
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    // Swaps exact tokens for another token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    // Gets price ratio between tokens
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price);
    
    // Calculates output amount for a swap
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
}

/**
 * @dev SimpleSwap DEX Implementation
 */
contract SimpleSwap is ISimpleSwap {
    // Contract state variables
    address public factory;         // Address of factory that created this pool
    address public tokenA;          // Address of first token in pair
    address public tokenB;          // Address of second token in pair
    
    uint256 public reserveA;        // Reserve amount of tokenA
    uint256 public reserv
