// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./RealEstate.sol";

contract MultiTenantRent {
    address admin;
    RealEstate realEstate; // Reference to the RealEstate contract

    uint256 public propertyCount;

    constructor(address _realEstateAddress) {
        admin = msg.sender;
        realEstate = RealEstate(_realEstateAddress);
    }

    struct Property {
        uint256 id;
        address payable owner;
        uint256 rent;
        uint256 deposit;
        uint256 maxTenants; // Maximum number of tenants allowed
        address[] tenants;
    }

    mapping(uint256 => bool) public isListed;
    mapping(uint256 => Property) public properties;
    mapping(uint256 => mapping(address => bool)) public depositPaid; // Tenant-specific deposits
    mapping(address => uint256) public balances;

    modifier onlyOwner(uint256 _id) {
        require(msg.sender == properties[_id].owner, "Only the property owner can perform this action.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action.");
        _;
    }

    modifier isListedProperty(uint256 _id) {
        require(isListed[_id], "Property is not listed.");
        _;
    }

    /// @notice List a new property
    function list(
        string memory _tokenURI,
        address payable _owner,
        uint256 _rent,
        uint256 _deposit,
        uint256 _maxTenants
    ) public {
        uint256 _id = realEstate.mint(_tokenURI);
        Property memory property = Property({
            id: _id,
            owner: _owner,
            rent: _rent,
            deposit: _deposit,
            maxTenants: _maxTenants,
            tenants: new address 
        });

        isListed[_id] = true;
        properties[_id] = property;
        propertyCount++;
    }

    /// @notice Enroll a tenant for a property
    function enroll(uint256 _id) public payable isListedProperty(_id) {
        Property storage property = properties[_id];
        require(property.tenants.length < property.maxTenants, "Property is at full capacity.");
        require(!depositPaid[_id][msg.sender], "Deposit already paid.");
        require(msg.value >= property.deposit, "Insufficient deposit.");

        depositPaid[_id][msg.sender] = true;
        balances[property.owner] += msg.value; // Add deposit to owner's balance
    }

    /// @notice Add tenant to a property
    function addTenants(uint256 _id, address _tenant) public onlyOwner(_id) isListedProperty(_id) {
        require(depositPaid[_id][_tenant], "Tenant has not paid the deposit.");
        Property storage property = properties[_id];
        property.tenants.push(_tenant);
    }

    /// @notice Cancel rental contract and refund deposit
    function cancelContract(uint256 _id, address _tenant) public onlyOwner(_id) isListedProperty(_id) {
        Property storage property = properties[_id];

        // Find and remove tenant
        bool tenantFound = false;
        uint256 tenantIndex;

        for (uint256 i = 0; i < property.tenants.length; i++) {
            if (property.tenants[i] == _tenant) {
                tenantFound = true;
                tenantIndex = i;
                break;
            }
        }
        require(tenantFound, "Tenant not found.");

        for (uint256 i = tenantIndex; i < property.tenants.length - 1; i++) {
            property.tenants[i] = property.tenants[i + 1];
        }
        property.tenants.pop();

        // Refund deposit
        require(balances[property.owner] >= property.deposit, "Insufficient funds.");
        balances[property.owner] -= property.deposit;
        payable(_tenant).transfer(property.deposit);
    }

    /// @notice Withdraw owner's balance
    function withdrawMoney(address _client) public onlyAdmin {
        require(balances[_client] > 0, "No funds available.");
        uint256 amount = balances[_client];
        balances[_client] = 0;
        payable(_client).transfer(amount);
    }
}
