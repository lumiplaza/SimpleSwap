# SimpleSwap DEX

![Solidity](https://img.shields.io/badge/Solidity-0.8.0-blue) 
![License](https://img.shields.io/badge/License-MIT-green)
![AMM](https://img.shields.io/badge/AMM-x*y%3Dk-blueviolet)

A minimalistic decentralized exchange (DEX) implementing core AMM functionality with liquidity pools, token swaps, and price calculations.

## 📦 Core Smart Contracts

### 1. `SimpleSwap.sol` (Main DEX Contract)
**Inherits**: OpenZeppelin's `ERC20` (for LP tokens)



#### Key Functionality

| Function                     | Parameters                                                                 | Description                                                                 |
|------------------------------|----------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| `addLiquidity()`             | `tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline` | Deposits tokens into liquidity pool and mints LP tokens proportionally. Uses `sqrt(amountA * amountB)` for initial liquidity calculation. |
| `removeLiquidity()`          | `tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline`         | Burns LP tokens and returns proportional amounts of underlying tokens. Enforces minimum amounts via `amountAMin/amountBMin`. |
| `swapExactTokensForTokens()` | `amountIn, amountOutMin, path, to, deadline`                              | Executes token swaps using constant product formula (`x*y=k`). `path` must contain exactly 2 tokens. |
| `getPrice()`                 | `tokenA, tokenB`                                                          | Returns price ratio of `tokenB` relative to `tokenA` (scaled by 1e18). Reverts if reserves are insufficient. |
| `getAmountOut()`             | `amountIn, reserveIn, reserveOut`                                         | Pure function calculating output amount using `(amountIn * reserveOut) / (reserveIn + amountIn)` formula. |




#### 📊 State Variables & Parameters


##### Core Pool Variables
| Variable | Type | Description |
|----------|------|-------------|
| `totalSupply()` | `uint256` | Tracks total LP tokens minted (inherited from ERC20) |



#### Function Parameters
##### `addLiquidity()`
| Parameter | Type | Description |
|-----------|------|-------------|
| `tokenA` | `address` | Address of first token in liquidity pair |
| `tokenB` | `address` | Address of second token in liquidity pair |
| `amountADesired` | `uint256` | Maximum amount of Token A to deposit |
| `amountBDesired` | `uint256` | Maximum amount of Token B to deposit |
| `amountAMin` | `uint256` | Minimum acceptable amount of Token A (slippage protection) |
| `amountBMin` | `uint256` | Minimum acceptable amount of Token B (slippage protection) |
| `to` | `address` | Recipient address for LP tokens |
| `deadline` | `uint256` | Unix timestamp after which transaction reverts |

##### `removeLiquidity()`
| Parameter | Type | Description |
|-----------|------|-------------|
| `liquidity` | `uint256` | Amount of LP tokens to burn |
| `amountAMin` | `uint256` | Minimum acceptable amount of Token A |
| `amountBMin` | `uint256` | Minimum acceptable amount of Token B |

##### `swapExactTokensForTokens()`
| Parameter | Type | Description |
|-----------|------|-------------|
| `amountIn` | `uint256` | Exact amount of input tokens to swap |
| `amountOutMin` | `uint256` | Minimum acceptable output tokens (slippage protection) |
| `path` | `address[]` | Array with 2 elements: [inputToken, outputToken] |

##### Price Calculation Variables
| Variable | Formula | Description |
|----------|---------|-------------|
| `price` | `(reserveB * 1e18) / reserveA` | Price of TokenB in terms of TokenA (w/ 18 decimals) |
| `amountOut` | `(amountIn * reserveOut) / (reserveIn + amountIn)` | Output amount from swap |

##### Internal Math Utilities
| Variable | Type | Description |
|----------|------|-------------|
| `reserveA` | `uint256` | Current balance of TokenA in pool |
| `reserveB` | `uint256` | Current balance of TokenB in pool |
| `liquidity` | `uint256` | LP tokens to mint/burn (sqrt(amountA*amountB) for first deposit) |




#### Event Emissions
 
 // Emitted when liquidity is added to a pool
// Tracks: User, Token addresses, Amounts deposited, LP tokens minted
event LiquidityAdded(address indexed user, address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);

// Emitted when liquidity is removed from a pool
// Tracks: User, Token addresses, Amounts withdrawn, LP tokens burned
event LiquidityRemoved(address indexed user, address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);

// Emitted during token swaps
// Tracks: User, Input/Output tokens, Exact amounts exchanged
event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);



### 🏗 Technical Architecture

#### Dependencies
- OpenZeppelin Contracts ^4.9.0
- Solidity 0.8.0 (with built-in overflow checks)



#### 📝 Key Structs (Conceptual)
```solidity
struct Pool {
    uint256 reserveA;    // Token A reserves
    uint256 reserveB;    // Token B reserves
    uint256 totalLPs;    // Total LP tokens
}



#### File Structure
/contracts
  ├── SimpleSwap.sol       # Main DEX contract (inherits ERC20)
  ├── MyToken.sol          # Test ERC-20 token
  └── interfaces/          # Required interfaces
      └── IERC20.sol       # Standard ERC-20 interface
