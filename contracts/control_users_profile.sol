// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title UserProfile
 * @dev Smart contract for managing user profile information
 * @author Josue Soto
 */
contract UserProfile {
    
    // User struct
    struct User {
        string name;
        uint256 age;
        string email;
        address userAddress;
        uint256 registrationTimestamp;
        bool isRegistered;
    }
    
    // State variables
    mapping(address => User) private users;
    mapping(string => bool) private emailExists;
    address[] private registeredUsers;
    uint256 public totalUsers;
    
    // Events
    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, string name, uint256 timestamp);
    
    // Modifiers
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    modifier notRegistered() {
        require(!users[msg.sender].isRegistered, "User already registered");
        _;
    }
    
    modifier validInput(string memory _name, uint256 _age, string memory _email) {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_age > 0 && _age <= 150, "Invalid age");
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(isValidEmail(_email), "Invalid email format");
        _;
    }
    
    /**
     * @dev Register a new user with profile information
     * @param _name User's name
     * @param _age User's age
     * @param _email User's email address
     */
    function register(
        string memory _name, 
        uint256 _age, 
        string memory _email
    ) 
        public 
        notRegistered 
        validInput(_name, _age, _email) 
    {
        require(!emailExists[_email], "Email already registered");
        
        users[msg.sender] = User({
            name: _name,
            age: _age,
            email: _email,
            userAddress: msg.sender,
            registrationTimestamp: block.timestamp,
            isRegistered: true
        });
        
        emailExists[_email] = true;
        registeredUsers.push(msg.sender);
        totalUsers++;
        
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Update existing user profile information
     * @param _name New name
     * @param _age New age
     * @param _email New email address
     */
    function updateProfile(
        string memory _name, 
        uint256 _age, 
        string memory _email
    ) 
        public 
        onlyRegistered 
        validInput(_name, _age, _email) 
    {
        if (keccak256(bytes(users[msg.sender].email)) != keccak256(bytes(_email))) {
            require(!emailExists[_email], "Email already registered by another user");
            
            emailExists[users[msg.sender].email] = false;
            emailExists[_email] = true;
        }
        
        users[msg.sender].name = _name;
        users[msg.sender].age = _age;
        users[msg.sender].email = _email;
        
        emit ProfileUpdated(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Get profile information for the caller
     * @return name User's name
     * @return age User's age
     * @return email User's email
     * @return userAddress User's wallet address
     * @return registrationTimestamp When user registered
     */
    function getProfile() 
        public 
        view 
        onlyRegistered 
        returns (
            string memory name,
            uint256 age,
            string memory email,
            address userAddress,
            uint256 registrationTimestamp
        ) 
    {
        User memory user = users[msg.sender];
        return (
            user.name,
            user.age,
            user.email,
            user.userAddress,
            user.registrationTimestamp
        );
    }
    
    /**
     * @dev Get profile information for any user (public getter)
     * @param _userAddress Address of the user to query
     * @return name User's name
     * @return age User's age
     * @return email User's email
     * @return userAddress User's wallet address
     * @return registrationTimestamp When user registered
     */
    function getUserProfile(address _userAddress) 
        public 
        view 
        returns (
            string memory name,
            uint256 age,
            string memory email,
            address userAddress,
            uint256 registrationTimestamp
        ) 
    {
        require(users[_userAddress].isRegistered, "User not registered");
        
        User memory user = users[_userAddress];
        return (
            user.name,
            user.age,
            user.email,
            user.userAddress,
            user.registrationTimestamp
        );
    }
    
    /**
     * @dev Check if a user is registered
     * @param _userAddress Address to check
     * @return bool Registration status
     */
    function isUserRegistered(address _userAddress) public view returns (bool) {
        return users[_userAddress].isRegistered;
    }
    
    /**
     * @dev Get all registered user addresses
     * @return address[] Array of registered user addresses
     */
    function getAllUsers() public view returns (address[] memory) {
        return registeredUsers;
    }
    
    /**
     * @dev Get registration timestamp for a user
     * @param _userAddress User address to query
     * @return uint256 Registration timestamp
     */
    function getRegistrationTime(address _userAddress) public view returns (uint256) {
        require(users[_userAddress].isRegistered, "User not registered");
        return users[_userAddress].registrationTimestamp;
    }
    
    /**
     * @dev Basic email validation (checks for @ symbol)
     * @param _email Email to validate
     * @return bool Validation result
     */
    function isValidEmail(string memory _email) private pure returns (bool) {
        bytes memory emailBytes = bytes(_email);
        bool hasAtSymbol = false;
        bool hasTextBefore = false;
        bool hasTextAfter = false;
        
        for (uint i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == '@') {
                if (hasAtSymbol) return false; 
                hasAtSymbol = true;
                if (i > 0) hasTextBefore = true;
            } else if (hasAtSymbol && emailBytes[i] != ' ') {
                hasTextAfter = true;
            }
        }
        
        return hasAtSymbol && hasTextBefore && hasTextAfter;
    }
}