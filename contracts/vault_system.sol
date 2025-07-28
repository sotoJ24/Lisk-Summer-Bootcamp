// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ========================================
// MATH LIBRARY
// ========================================

/**
 * @title SafeMath
 * @dev Library for safe mathematical operations with overflow/underflow protection
 */
library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function percentage(uint256 amount, uint256 percentage, uint256 precision) 
        internal 
        pure 
        returns (uint256) 
    {
        return div(mul(amount, percentage), precision);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// ========================================
// BASE CONTRACT - VAULT BASE
// ========================================

/**
 * @title VaultBase
 * @dev Base contract that defines the structure and shared logic for vault systems
 */
abstract contract VaultBase {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    uint256 internal _totalSupply;
    address public owner;

    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error ZeroAmount();
    error InsufficientBalance();
    error UnauthorizedAccess();
    error TransferFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert UnauthorizedAccess();
        _;
    }

    modifier validAmount(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    /**
     * @dev Constructor sets the deployer as owner
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the balance of a specific user
     * @param user The address to query
     * @return The user's balance
     */
    function balanceOf(address user) public view returns (uint256) {
        return _balances[user];
    }

    /**
     * @dev Returns the total supply of deposited Ether
     * @return The total amount of Ether in the vault
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the vault's Ether balance
     * @return The contract's Ether balance
     */
    function vaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfer ownership to a new address
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "VaultBase: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Internal function to update balances safely
     * @param user The user's address
     * @param amount The amount to add
     */
    function _increaseBalance(address user, uint256 amount) internal {
        _balances[user] = _balances[user].add(amount);
        _totalSupply = _totalSupply.add(amount);
    }

    /**
     * @dev Internal function to decrease balances safely
     * @param user The user's address
     * @param amount The amount to subtract
     */
    function _decreaseBalance(address user, uint256 amount) internal {
        if (_balances[user] < amount) revert InsufficientBalance();
        _balances[user] = _balances[user].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
    }

    function deposit() external payable virtual;
    function withdraw(uint256 amount) external virtual;
}

// ========================================
// DERIVED CONTRACT - VAULT MANAGER
// ========================================

/**
 * @title VaultManager
 * @dev Implements the deposit and withdraw functions with additional features
 */
contract VaultManager is VaultBase {
    using SafeMath for uint256;

    uint256 public constant MIN_DEPOSIT = 0.001 ether; 
    uint256 public constant MAX_DEPOSIT = 100 ether;   
    uint256 public withdrawalFee = 50; 
    uint256 public constant FEE_PRECISION = 10000;
    
    bool public emergencyMode = false;
    uint256 public totalDepositors;
    
    mapping(address => bool) public isDepositor;
    mapping(address => uint256) public depositCount;
    mapping(address => uint256) public lastDepositTime;

    // Additional events
    event EmergencyModeToggled(bool enabled);
    event WithdrawalFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesCollected(address indexed owner, uint256 amount);

    // Additional modifiers
    modifier notInEmergency() {
        require(!emergencyMode, "VaultManager: emergency mode active");
        _;
    }

    modifier validDepositAmount() {
        require(msg.value >= MIN_DEPOSIT, "VaultManager: deposit below minimum");
        require(msg.value <= MAX_DEPOSIT, "VaultManager: deposit exceeds maximum");
        _;
    }

    function deposit() 
        external 
        payable 
        override 
        validAmount(msg.value)
        validDepositAmount
        notInEmergency
    {
        address user = msg.sender;
        uint256 amount = msg.value;

        if (!isDepositor[user]) {
            isDepositor[user] = true;
            totalDepositors = totalDepositors.add(1);
        }

        depositCount[user] = depositCount[user].add(1);
        lastDepositTime[user] = block.timestamp;

        _increaseBalance(user, amount);

        emit Deposit(user, amount, _balances[user]);
    }

    function withdraw(uint256 amount) 
        external 
        override 
        validAmount(amount)
        notInEmergency
    {
        address user = msg.sender;
        
        if (_balances[user] < amount) revert InsufficientBalance();

        uint256 fee = SafeMath.percentage(amount, withdrawalFee, FEE_PRECISION);
        uint256 withdrawAmount = amount.sub(fee);

        _decreaseBalance(user, amount);

        (bool success, ) = payable(user).call{value: withdrawAmount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(user, withdrawAmount, _balances[user]);
    }


    function withdrawAll() external view notInEmergency {
        uint256 userBalance = _balances[msg.sender];
        require(userBalance > 0, "VaultManager: no funds to withdraw");
    }


    function emergencyWithdraw(address user, uint256 amount) 
        external 
        onlyOwner 
        validAmount(amount)
    {
        if (_balances[user] < amount) revert InsufficientBalance();

        _decreaseBalance(user, amount);

        (bool success, ) = payable(user).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(user, amount, _balances[user]);
    }


    function toggleEmergencyMode() external onlyOwner {
        emergencyMode = !emergencyMode;
        emit EmergencyModeToggled(emergencyMode);
    }

    function setWithdrawalFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "VaultManager: fee too high"); // Max 10%
        uint256 oldFee = withdrawalFee;
        withdrawalFee = newFee;
        emit WithdrawalFeeUpdated(oldFee, newFee);
    }

    function collectFees() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 userFunds = _totalSupply;
        
        if (contractBalance > userFunds) {
            uint256 fees = contractBalance.sub(userFunds);
            
            (bool success, ) = payable(owner).call{value: fees}("");
            if (!success) revert TransferFailed();
            
            emit FeesCollected(owner, fees);
        }
    }

    function getUserStats(address user) 
        external 
        view 
        returns (uint256 balance, uint256 deposits, uint256 lastDeposit) 
    {
        return (_balances[user], depositCount[user], lastDepositTime[user]);
    }

    function getVaultStats() 
        external 
        view 
        returns (
            uint256 totalBalance,
            uint256 totalUsers,
            uint256 contractBalance,
            uint256 accumulatedFees
        ) 
    {
        contractBalance = address(this).balance;
        accumulatedFees = contractBalance > _totalSupply ? 
            contractBalance.sub(_totalSupply) : 0;
        
        return (_totalSupply, totalDepositors, contractBalance, accumulatedFees);
    }

    function calculateWithdrawal(uint256 amount) 
        external 
        view 
        returns (uint256 netAmount, uint256 feeAmount) 
    {
        feeAmount = SafeMath.percentage(amount, withdrawalFee, FEE_PRECISION);
        netAmount = amount.sub(feeAmount);
        return (netAmount, feeAmount);
    }

    receive() external payable {
        revert("VaultManager: use deposit() function");
    }

    fallback() external payable {
        revert("VaultManager: function not found");
    }
}



contract VaultFactory {
    using SafeMath for uint256;

    address[] public deployedVaults;
    mapping(address => address[]) public userVaults;
    mapping(address => bool) public isVault;

    event VaultCreated(address indexed creator, address indexed vaultAddress, uint256 vaultId);

    function createVault() external returns (address) {
        VaultManager newVault = new VaultManager();
        address vaultAddress = address(newVault);
    
        newVault.transferOwnership(msg.sender);

        deployedVaults.push(vaultAddress);
        userVaults[msg.sender].push(vaultAddress);
        isVault[vaultAddress] = true;
        
        emit VaultCreated(msg.sender, vaultAddress, deployedVaults.length - 1);
        
        return vaultAddress;
    }

    function getTotalVaults() external view returns (uint256) {
        return deployedVaults.length;
    }

    function getUserVaults(address user) external view returns (address[] memory) {
        return userVaults[user];
    }

    function isValidVault(address vaultAddress) external view returns (bool) {
        return isVault[vaultAddress];
    }
}



