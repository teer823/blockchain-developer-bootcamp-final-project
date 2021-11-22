// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./XABER.sol";
import "./Badges.sol";
import "./Employee.sol";

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract Employees is ERC2771Context {
    
    XABER tokenContract;
    Badges badgesContract;

    uint256 public constant NOOB = 1;
    uint256 public constant ROOKIE = 2;
    uint256 public constant NOVICE = 3;
    uint256 public constant COMMON = 4;
    uint256 public constant MAJOR = 5;
    uint256 public constant MASTER = 6;

    uint256[] private badgeIds;
    mapping(uint256 => uint256) private badgeExchangeRates;    

    
    mapping(address => Employee) public employees;
    mapping(uint256 => bool) public employeeIds;

    uint256 public employeeCount;

    modifier doesNotExist(uint256 _id, address _address)  {
        require(_id > 0 && !employeeIds[_id]  && employees[_address].id == 0);
        _;
    }
    
    /*
     * Events
     */
    event LogEmployeeAdded(uint256 id, string name, string email);
    
    constructor(address _tokenContract, address _badgesContract, address _trustedForwarder) 
    ERC2771Context(_trustedForwarder)
    {
        tokenContract = XABER(_tokenContract);
        badgesContract = Badges(_badgesContract);
        employeeCount = 0;

        badgeIds = [NOOB, ROOKIE, NOVICE, COMMON, MAJOR, MASTER];

        badgeExchangeRates[NOOB] = 5000000000000000000;
        badgeExchangeRates[ROOKIE] = 10000000000000000000;
        badgeExchangeRates[NOVICE] = 15000000000000000000;
        badgeExchangeRates[COMMON] = 30000000000000000000;
        badgeExchangeRates[MAJOR] = 50000000000000000000;
        badgeExchangeRates[MASTER]= 100000000000000000000;
    }
    
    function addEmployee(uint256 _id, string memory _name, string memory _email, string memory _image) 
    public 
    doesNotExist(_id, _msgSender()) 
    returns (bool) 
    {        
        Employee storage newEmployee = employees[_msgSender()];
        newEmployee.id = _id;
        newEmployee.name = _name;
        newEmployee.email = _email;
        newEmployee.image = _image;
        
        employeeIds[_id] = true;
        employeeCount += 1;

        tokenContract.mint(_msgSender(), 10000000000000000000);

        emit LogEmployeeAdded(_id, _name, _email);
        return true;
    }

    function getEmployees(address account) public view returns (Employee memory) {
        return employees[account];
    }

    function getAvailableBadges() public view returns (uint256[] memory) {                        
        return badgeIds;
    }

    function getBadgeExchangeRate (uint256 badgeId) public view returns (uint256) {
            return badgeExchangeRates[badgeId];
    }
    
    function exchangeBadge (uint256 badgeId) public returns (bool) {
        
        require(tokenContract.allowance(_msgSender(), address(this)) >= badgeExchangeRates[badgeId]);
        require(tokenContract.balanceOf(_msgSender()) >= badgeExchangeRates[badgeId]);
        
        tokenContract.burnFrom(_msgSender(), badgeExchangeRates[badgeId]);
        badgesContract.mint(_msgSender(), badgeId, 1, "");        
        employees[_msgSender()].badges.push(badgeId);

        return true;
    }
}