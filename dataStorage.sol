pragma solidity ^0.4.24;

/**
 * The DataStorage contract serves as a vault to store
 * data from the asset tokens; makes teh logic upgradable and at the same time keeping
 * access to the relevant piece of data
 */
 
import { safeMath } from "./safeMath.sol";

contract DataStorage {
    
    using safeMath for uint256;

    string internal init_name;
    string internal init_symbol;
    uint256 internal init_granularity;
    uint256 internal init_totalSupply;
    uint256 internal rate;
    uint256 internal weiRaised;

    mapping(address => uint) internal balances;
    mapping(address => mapping(address => bool)) internal authorized;
    address[] internal init_defaultOperators;
    mapping(address => bool) internal isDefaultOperator;
    mapping(address => mapping(address => bool)) internal revokedDefaultOperator;
    mapping (address => bool) internal accessAllowed;
    mapping (address => mapping (address => uint256)) internal allowed;

   constructor(
        string _name,
        string _symbol,
        uint256 _granularity,
        uint256 _totalSupply,
        address[] _defaultOperators) public 
    {

        require(_granularity >= 1);
        require(_totalSupply > 0);
        
        init_name =_name;
        init_symbol = _symbol;
        init_granularity = _granularity;
        init_totalSupply = _totalSupply * (10 ** 18);
        init_defaultOperators = _defaultOperators;

        for (uint i = 0; i < _defaultOperators.length; i++) {       
            isDefaultOperator[_defaultOperators[i]] = true; 
        }

        accessAllowed[msg.sender] = true;

    }

    // ACCESS FUNCTIONS
    /// Allow modification of the contract 
    modifier Modify() { 
        require(accessAllowed[msg.sender] == true);
        _; 
    }

    /// Allow Access to contracts and accounts
    function allowAccess(address _address) Modify public {
        accessAllowed[_address] = true;
    }

    /// Deny Access to contracts and accounts 
    function denyAccess(address _address) Modify public {
        accessAllowed[_address] = false;
    }

    // RETURN FUNCTIONS
    /// @notice The full name of the asset linked to the specific token
    /// @return the name of the token
    function name() public constant returns (string) { 
        return init_name; 
    }
    
    /// @notice The symbol of the token is the abreviated representation of the token name
    /// @return the symbol of the token
    function symbol() public constant returns (string) { return init_symbol; }
    
    /// @notice Gives you back the smallest chunk of token that can be exchanged
    /// @return the granularity of the token
    function granularity() public constant returns (uint256) { 
        return init_granularity; 
    }

    /// @notice View function for the totalSUpply of the token / asset
    /// @return the total supply of the token
    function totalSupply() public constant returns (uint256) { 
        return init_totalSupply; 
    }

    /// @notice Return the account balance of some account
    /// @param _tokenHolder Address for which the balance is returned
    /// @return the balance of `_tokenAddress`.
    function balanceOf(address _tokenHolder) public constant returns (uint256) { 
        return balances[_tokenHolder]; 
    }

    /// @notice Return the list of default operators
    /// @return the list of all the default operators
    function defaultOperators() public view returns (address[]) { 
        return init_defaultOperators; 
    }
    
    /// @notice checks if an address is part of teh default operators
    /// @return a boolean that represents the status (true it is part, false it is not)
    /// @param _addressCheck is the address to be checked
    function checkIsDefaultOperator(address _addressCheck) public view returns (bool) {
        for (uint i = 0; i < init_defaultOperators.length; i++) {
            if(_addressCheck == init_defaultOperators[i]){
                return true;
            }
        }
        return false;
    }
    
    /// @notice checks if an address is part of teh default operators
    /// @return a boolean that represents the status (true it is part, false it is not)
    /// @param _addressCheck is the address to be checked
    function checkRevokedDefaultOperator(address _addressCheck, address _tokenHolder) public view returns (bool) {
        bool _status;
        if(revokedDefaultOperator[_addressCheck][_tokenHolder]) {
            _status = true;
        } else {
            _status = false;
        }
        return _status;
    }
    
    /// @notice checks if an address is authorized as an operator for a specific account
    /// @return a boolean that represents the status (true it is part, false it is not)
    /// @param _addressCheck the address to be checked as authorized or not
    /// @param _tokenHolder address that is supposed to detain teh tokens to be managed supposedly by the _addressCheck
    function checkAuthorized(address _addressCheck, address _tokenHolder) public view returns (bool) {
        bool _status;
        if(authorized[_addressCheck][_tokenHolder]) {
            _status = true;
        } else {
            _status = false;
        }
        return _status;
    }
    
    /// @notice Check allowance
    /// @param _from is the account address from which the token would be spent
    /// @param _to is the account address that will spend/send the quantity of token
    /// @return the allowance _from to _to
    function checkAllowance(address _from, address _to) public view returns (uint256) {
        uint256 allowance;
        allowance = allowed[_from][_to];
        return allowance;
    }

    // SETTER FUNCTIONS
    /// @notice Set allowance
    /// @param _from is the tokenholder address
    /// @param _to is the spender address
    /// @param _newAll is the amount in tokens _to will be able to spend
    function setAllowance(address _from, address _to, uint256 _newAll) Modify public returns (bool) {
        require(balanceOf(_from) >= _newAll.mul(10 ** 18));
        allowed[_from][_to] = _newAll.mul(10 ** 18);
        return true;
    }
    
    /// @notice Set balance of a specific address
    /// @param _address is the address concerned by the change in balances
    /// @param _balance is the new balance that the concerned address needs to have
    function setBalance(address _address, uint256 _balance) Modify public returns (bool) {
        require(_balance >= 0);
        balances[_address] = _balance;
        return true;
    }

    /// @notice Set the rate of the token (in token per ether)
    /// @param _rate is the new rate of the token
    function setRate(uint256 _rate) Modify public returns (bool) {
        rate = _rate;
        return true;
    }
    
    /// @notice Set wei raised
    /// @param _weiRaised is the amount of wei raised in total
    function setWeiRaised(uint256 _weiRaised) Modify public returns (bool) {
       weiRaised = weiRaised.add(_weiRaised);
        return true;
    }
    
    /// @notice set the smallest transferable chunk of token
    /// @param _newGranularity pretty self explanatory ¯\_(ツ)_/¯
    function setGranularity(uint256 _newGranularity) Modify public returns (bool) {
        init_granularity = _newGranularity;
        return true;
    }
    
    /// @notice set revoked operators
    /// @param _operator is the account not authorized to move the tokens
    /// @param _tokenholder is the account that holds the token to be moved
    /// @param _status is a boolean stating if a specific account not authorized or notice
    function setRevokedOperator(address _operator, address _tokenholder,bool _status) Modify public returns (bool) {
         revokedDefaultOperator[_operator][_tokenholder] = _status;
         return true;
    }
    
    /// @notice set revoked operators
    /// @param _operator is the account authorized to move the tokens
    /// @param _tokenholder is the account that holds the token to be moved
    /// @param _status is a boolean stating if a specific account authorized or notice
    function setAuthorizedOperator(address _operator, address _tokenholder,bool _status) Modify public returns (bool) {
         authorized[_operator][_tokenholder] = _status;
         return true;
    }
    
    /// @notice set teh new total supply (after a burn)
    /// @param _newTotalSupply is teh new total supply
    function setTotalSupply(uint256 _newTotalSupply) Modify public returns (bool) {
        init_totalSupply = _newTotalSupply;
        return true;
    }

}