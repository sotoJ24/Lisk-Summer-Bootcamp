// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ========================================
// ORIGINAL VULNERABLE CONTRACT
// ========================================

contract VulnerablePiggyBank {
    address public owner;
    
    constructor() { 
        owner = msg.sender; 
    }
    
    function deposit() public payable {}
    
    function withdraw() public { 
        payable(msg.sender).transfer(address(this).balance); 
    }
    
    function attack() public {}
}

// ========================================
// ATTACK CONTRACT
// ========================================

contract PiggyBankAttacker {
    VulnerablePiggyBank public target;
    
    constructor(address _target) {
        target = VulnerablePiggyBank(_target);
    }

    function attackPiggyBank() public {
        target.withdraw();
        
        payable(msg.sender).transfer(address(this).balance);
    }
    
    receive() external payable {}
}

// ========================================
// SECURE VERSION WITH FIXES
// ========================================

contract SecurePiggyBank {
    address public owner;
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event OwnerWithdrawal(uint256 amount);
    
    error NotOwner();
    error InsufficientBalance();
    error WithdrawalFailed();
    error ZeroAmount();
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    constructor() { 
        owner = msg.sender; 
    }
    
    function deposit() public payable {
        if (msg.value == 0) revert ZeroAmount();
        
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) public {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawalFailed();
        
        emit Withdrawal(msg.sender, amount);
    }
   
    function withdrawAll() public {
        uint256 amount = balances[msg.sender];
        if (amount == 0) revert InsufficientBalance();
        
        balances[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawalFailed();
        
        emit Withdrawal(msg.sender, amount);
    }
    

    function emergencyWithdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        
        (bool success, ) = payable(owner).call{value: amount}("");
        if (!success) revert WithdrawalFailed();
        
        emit OwnerWithdrawal(amount);
    }
    
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// ========================================
// COMPREHENSIVE TEST CONTRACT
// ========================================

contract PiggyBankTest {
    VulnerablePiggyBank public vulnerableContract;
    SecurePiggyBank public secureContract;
    PiggyBankAttacker public attacker;
    
    event TestResult(string test, bool passed, string message);
    
    constructor() {
        vulnerableContract = new VulnerablePiggyBank();
        secureContract = new SecurePiggyBank();
        attacker = new PiggyBankAttacker(address(vulnerableContract));
    }
    
    function testVulnerability() public payable {
        require(msg.value >= 2 ether, "Need at least 2 ETH for test");

        vulnerableContract.deposit{value: 1 ether}();
        
        uint256 balanceBefore = address(this).balance;
        
        attacker.attackPiggyBank();
        
        uint256 balanceAfter = address(this).balance;
        
        bool attackSuccessful = balanceAfter > balanceBefore;
        
        emit TestResult(
            "Vulnerability Test", 
            attackSuccessful, 
            attackSuccessful ? "Attack successful - funds stolen!" : "Attack failed"
        );
    }
    
    function testSecureContract() public payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH for test");
        
        secureContract.deposit{value: 0.5 ether}();
        
        uint256 userBalance = secureContract.getBalance(address(this));
        bool depositWorked = userBalance == 0.5 ether;
        
        emit TestResult(
            "Secure Deposit Test", 
            depositWorked, 
            depositWorked ? "Deposit tracking works correctly" : "Deposit tracking failed"
        );
        
        secureContract.withdraw(0.2 ether);
        userBalance = secureContract.getBalance(address(this));
        bool withdrawalWorked = userBalance == 0.3 ether;
        
        emit TestResult(
            "Secure Withdrawal Test", 
            withdrawalWorked, 
            withdrawalWorked ? "Withdrawal works correctly" : "Withdrawal failed"
        );
    }
    
    receive() external payable {}
}

/*
========================================
VULNERABILITY ANALYSIS:
========================================

1. **Missing Access Control**: The withdraw() function lacks any access control.
   - Anyone can call withdraw() and drain all funds
   - No check if the caller is the owner or has deposited funds

2. **No Balance Tracking**: The contract doesn't track individual user balances
   - All deposits go to the contract balance
   - No way to determine who owns what funds

3. **Dangerous withdraw() Logic**: Transfers entire contract balance to caller
   - Should only allow withdrawal of user's own funds
   - Creates a honeypot where anyone can steal all funds

4. **Missing Events**: No logging for deposits/withdrawals
   - Poor transparency and debugging capability

5. **Use of transfer()**: While not critical here, transfer() has fixed gas limit
   - Can fail with contract recipients
   - call() is more flexible and recommended

========================================
SECURITY FIXES IMPLEMENTED:
========================================

1. **Access Control**: 
   - onlyOwner modifier for emergency functions
   - Users can only withdraw their own tracked balances

2. **Individual Balance Tracking**:
   - mapping(address => uint256) balances
   - Each user's deposits are tracked separately

3. **Safe Withdrawal Logic**:
   - withdraw(amount) allows partial withdrawals
   - withdrawAll() for convenience
   - Checks-Effects-Interactions pattern

4. **Better Error Handling**:
   - Custom errors for gas efficiency
   - Proper validation of amounts and balances

5. **Events for Transparency**:
   - Deposit, Withdrawal, and OwnerWithdrawal events
   - Better monitoring and debugging

6. **Modern Solidity Practices**:
   - Use call() instead of transfer()
   - Custom errors instead of strings
   - Proper state management

========================================
DEPLOYMENT & TESTING INSTRUCTIONS:
========================================

1. Deploy VulnerablePiggyBank
2. Deploy PiggyBankAttacker with vulnerable contract address
3. Deploy SecurePiggyBank
4. Deploy PiggyBankTest for automated testing
5. Fund test contract and call testVulnerability() and testSecureContract()

The attack demonstrates how the lack of access control allows anyone
to drain all funds from the vulnerable contract.
*/