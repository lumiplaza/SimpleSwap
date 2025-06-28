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
    uint256 public reserveB;        // Reserve amount of tokenB
    uint256 public totalLiquidity;  // Total liquidity tokens minted
    mapping(address => uint256) public liquidity;  // LP token balances
    
    // Constructor sets the factory address
    constructor() {
        factory = msg.sender;
    }
    
    /**
     * @dev Initializes the token pair (can only be called by factory)
     */
    function initialize(address _tokenA, address _tokenB) external {
        require(msg.sender == factory, "Only factory can initialize");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
    
    /**
     * @dev Adds liquidity to the pool
     * Implements the constant product formula (x*y=k)
     */
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 _liquidity) {
        // Input validation
        require(deadline >= block.timestamp, "Expired deadline");
        require(_tokenA == tokenA && _tokenB == tokenB, "Invalid token pair");
        require(amountADesired > 0 && amountBDesired > 0, "Invalid amounts");
        require(amountAMin <= amountADesired && amountBMin <= amountBDesired, "Invalid minimum amounts");

        (uint256 _reserveA, uint256 _reserveB) = (reserveA, reserveB);
        
        // First liquidity provision
        if (_reserveA == 0 && _reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } 
        // Subsequent liquidity additions
        else {
            // Calculate optimal token amounts to maintain ratio
            uint256 amountBOptimal = (amountADesired * _reserveB) / _reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * _reserveA) / _reserveB;
                require(amountAOptimal <= amountADesired, "Invalid A amount");
                require(amountAOptimal >= amountAMin, "Insufficient A amount");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        // Transfer tokens from user to pool
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer A failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), "Transfer B failed");

        // Update reserves
        _update(_reserveA + amountA, _reserveB + amountB);

        // Calculate and mint liquidity tokens
        if (totalLiquidity == 0) {
            _liquidity = sqrt(amountA * amountB);  // Geometric mean for initial liquidity
        } else {
            _liquidity = min(
                (amountA * totalLiquidity) / _reserveA,
                (amountB * totalLiquidity) / _reserveB
            );
        }
        
        require(_liquidity > 0, "Insufficient liquidity minted");
        _mint(to, _liquidity);  // Mint LP tokens to provider
        
        return (amountA, amountB, _liquidity);
    }

    /**
     * @dev Removes liquidity from the pool
     */
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        // Input validation
        require(deadline >= block.timestamp, "Expired deadline");
        require(_tokenA == tokenA && _tokenB == tokenB, "Invalid token pair");
        require(_liquidity > 0, "Invalid liquidity amount");
        
        // Calculate proportional share of reserves
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        uint256 _totalLiquidity = totalLiquidity;
        
        amountA = (_liquidity * balanceA) / _totalLiquidity;
        amountB = (_liquidity * balanceB) / _totalLiquidity;
        
        // Verify minimum amounts are met
        require(amountA >= amountAMin && amountB >= amountBMin, "Insufficient output amounts");
        
        // Burn LP tokens and transfer underlying assets
        _burn(msg.sender, _liquidity);
        require(IERC20(tokenA).transfer(to, amountA), "Transfer A failed");
        require(IERC20(tokenB).transfer(to, amountB), "Transfer B failed");
        
        // Update reserves
        _update(balanceA - amountA, balanceB - amountB);
        
        return (amountA, amountB);
    }

    /**
     * @dev Swaps exact input tokens for output tokens
     * Implements 0.3% fee (Uniswap V2 style)
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        // Input validation
        require(deadline >= block.timestamp, "Expired deadline");
        require(path.length == 2, "Invalid path");
        
        address tokenIn = path[0];
        address tokenOut = path[1];
        require((tokenIn == tokenA && tokenOut == tokenB) || (tokenIn == tokenB && tokenOut == tokenA), "Invalid token pair");
        
        uint256 amountOut;
        if (tokenIn == tokenA && tokenOut == tokenB) {
            // Calculate output amount
            amountOut = getAmountOut(amountIn, reserveA, reserveB);
            require(amountOut >= amountOutMin, "Insufficient output amount");
            
            // Transfer tokens
            require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
            require(IERC20(tokenB).transfer(to, amountOut), "Transfer failed");
            
            // Update reserves
            _update(reserveA + amountIn, reserveB - amountOut);
        } else {
            // Reverse direction swap
            amountOut = getAmountOut(amountIn, reserveB, reserveA);
            require(amountOut >= amountOutMin, "Insufficient output amount");
            
            // Transfer tokens
            require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
            require(IERC20(tokenA).transfer(to, amountOut), "Transfer failed");
            
            // Update reserves
            _update(reserveA - amountOut, reserveB + amountIn);
        }
    }

    /**
     * @dev Returns the price ratio between tokens (scaled by 1e18)
     */
    function getPrice(address _tokenA, address _tokenB) external view returns (uint256 price) {
        require((_tokenA == tokenA && _tokenB == tokenB) || (_tokenA == tokenB && _tokenB == tokenA), "Invalid token pair");
        
        if (_tokenA == tokenA && _tokenB == tokenB) {
            price = (reserveB * 1e18) / reserveA;  // Price of A in terms of B
        } else {
            price = (reserveA * 1e18) / reserveB;  // Price of B in terms of A
        }
    }

    /**
     * @dev Calculates output amount for a given input (with 0.3% fee)
     * Uses the formula: (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
     */
    function getAmountOut(uint256 amountIn, uint256 _reserveIn, uint256 _reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input amount");
        require(_reserveIn > 0 && _reserveOut > 0, "Insufficient liquidity");
        
        uint256 amountInWithFee = amountIn * 997;  // 0.3% fee
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // ===== Internal Functions =====
    
    /**
     * @dev Updates reserve amounts
     */
    function _update(uint256 balanceA, uint256 balanceB) private {
        reserveA = balanceA;
        reserveB = balanceB;
    }
    
    /**
     * @dev Mints liquidity tokens
     */
    function _mint(address to, uint256 value) private {
        liquidity[to] += value;
        totalLiquidity += value;
    }
    
    /**
     * @dev Burns liquidity tokens
     */
    function _burn(address from, uint256 value) private {
        liquidity[from] -= value;
        totalLiquidity -= value;
    }
    
    /**
     * @dev Calculates square root (for initial liquidity calculation)
     */
    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    /**
     * @dev Returns the minimum of two numbers
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
