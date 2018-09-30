/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
pragma solidity ^0.4.24;


import { ERC20Token } from "./ERC20Token.sol";
import { ERC777BaseToken } from "./ERC777BaseToken.sol";
import { DataStorage } from "./dataStorage.sol";


contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
     
    bool internal erc20compatible;
     
    constructor(
        address _dataStorageAddress)
        internal ERC777BaseToken(_dataStorageAddress) {
        DS = DataStorage(_dataStorageAddress);

        erc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    /// @notice This modifier is applied to erc20 obsolete methods that are
    ///  implemented only to maintain backwards compatibility. When the erc20
    ///  compatibility is disabled, this methods will fail.
    modifier erc20 () {
        require(erc20compatible);
        _;
    }

    // RETURN FUNCTIONS
    /// @notice For Backwards compatibility
    /// @return The decimals of the token. Forced to 18 in ERC777.
    function decimals() public erc20 constant returns (uint8) { return uint8(18); }

    /// @notice requests the name from the storage contract
    /// @return The name of the token as suggested in the name of the interface :)
    function name() public constant returns (string) { return DS.name(); }

    /// @notice requests the name from the storage contract
    /// @return The symbol of the token as suggested in the name of the interface :)
    function symbol() public constant returns (string) { return DS.symbol(); }

    /// @notice requests the totalSupply from the storage contract
    /// @return The total supply of the token as suggested in the name of the interface :)
    function totalSupply() public constant returns (uint256) { return DS.totalSupply(); }

    /// @notice requests the balance of a certain address
    /// @param _tokenHolder the address of the actual token holder from which we request the balance
    /// @return the balance of the specified address
    function balanceOf(address _tokenHolder) public constant returns (uint256) {
        return DS.balanceOf(_tokenHolder);
    }


    // SETTER FUNCTIONS
    /// @notice ERC20 backwards compatible transfer.
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible transferFrom.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= DS.checkAllowance(_from, msg.sender));

        // Cannot be after doSend because of tokensReceived re-entry
        DS.setAllowance(_from, msg.sender, _amount);
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible approve.
    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    /// @return `true`, if the approve can't be done, it should fail.
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        DS.setAllowance(msg.sender, _spender, _amount);
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice ERC20 backwards compatible allowance.
    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public erc20 constant returns (uint256 remaining) {
        uint256 all;
        all = DS.checkAllowance(_owner, _spender);
        return all;
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) internal {
        super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
        if (erc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
        internal {
        super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
        if (erc20compatible) { emit Transfer(_tokenHolder, 0x0, _amount); }
    }
}
