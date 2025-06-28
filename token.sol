// SPDX-License-Identifier: MIT
// Specifies the license type (MIT) for open-source usage
pragma solidity ^0.8.0;
// Sets the Solidity compiler version to 0.8.0 or higher

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * This defines the required functions and events for ERC20 compliance.
 */
interface IERC20 {
    // Returns the total token supply
    function totalSupply() external view returns (uint256);
    
    // Returns the token balance of a specific account
    function balanceOf(address account) external view returns (uint256);
    
    // Transfers tokens to a specified address
    function transfer(address to, uint256 amount) external returns (bool);
    
    // Returns remaining tokens approved for spender
    function allowance(address owner, address spender) external view returns (uint256);
    
    // Approves a spender to transfer tokens on behalf of owner
    function approve(address spender, uint256 amount) external returns (bool);
    
    // Transfers tokens from one address to another using allowance
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // Event emitted when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Event emitted when approval is granted
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Implementation of the ERC20 token standard.
 */
contract Token is IERC20 {
    // Token name (e.g., "MyToken")
    string public name;
    
    // Token symbol (e.g., "MTK")
    string public symbol;
    
    // Token decimals (standard is 18, like Ethereum)
    uint8 public decimals = 18;
    
    // Total supply of tokens
    uint256 public totalSupply;
    
    // Mapping of account balances (address => balance)
    mapping(address => uint256) public balanceOf;
    
    // Mapping of allowances (owner => (spender => amount))
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @dev Constructor that initializes the token.
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _initialSupply Initial token supply (before decimals)
     */
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        // Calculates total supply with decimals (e.g., 1000 * 10^18)
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        // Assigns all initial tokens to the deployer
        balanceOf[msg.sender] = totalSupply;
        // Emits transfer event from zero address (minting)
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev Transfers tokens to a specified address.
     * @param to Recipient address
     * @param value Amount to transfer
     * @return success Boolean indicating transfer success
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address"); // Prevent burning to zero address
        require(balanceOf[msg.sender] >= value, "Insufficient balance"); // Check sender balance
        
        // Perform the transfer
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        // Emit transfer event
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approves a spender to transfer tokens on behalf of owner.
     * @param spender Address allowed to spend
     * @param value Allowance amount
     * @return success Boolean indicating approval success
     */
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfers tokens using allowance mechanism.
     * @param from Sender address
     * @param to Recipient address
     * @param value Amount to transfer
     * @return success Boolean indicating transfer success
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance"); // Check sender balance
        require(allowance[from][msg.sender] >= value, "Allowance exceeded"); // Check allowance
        
        // Update balances and allowance
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
}
