pragma solidity ^0.5.3;

import { IERC20Token } from "./iERC20Token.sol";
import { IERC777Token } from "./iERC777Token.sol";
import { IERC777TokensSender } from "./iERC777TokensSender.sol";
import { IERC777TokensRecipient } from "./iERC777TokensRecipient.sol";
import { ERC1820Registry } from "./ERC1820.sol";
import { CommonConstants } from "./Common.sol";
import { SafeMath } from "./SafeMath.sol";
import { Address } from "./Address.sol";

contract Token is IERC20Token, IERC777Token, CommonConstants {
    using SafeMath for uint256;
    using Address for address;

    string _name;
    string _symbol;
    uint256 _totalSupply;
    uint256 _granularity;

    mapping (address => uint256) private balances;
    
    address[] private _defaultOperators;
    mapping(address => bool) _isDefaultOperator;
    mapping(address => mapping(address => bool)) internal _authorizedOperators;
    mapping(address => mapping(address => bool)) internal _revokedOperators;

    address[] public minters;
    mapping(address => bool) _isMinter;
    address[] public burners;
    mapping(address => bool) _isBurner;

    // ERC1820Registry _erc1820 = ERC1820Registry(ERC1820_REGISTRY_ADDRESS);
    ERC1820Registry _erc1820 = ERC1820Registry(0xc4597A8611bD9013E770590AB795B9E6bDe99057);

    constructor(
        string memory _tName,
        string memory _tSymbol,
        uint256 _tTotalSupply,
        uint256 _tGranulary,
        address[] memory _defaultOps,
        address[] memory _minters,
        address[] memory _burners
    ) public {
      _name = _tName;
      _symbol = _tSymbol;
      _totalSupply = _tTotalSupply;
      _granularity = _tGranulary;
      _defaultOperators = _defaultOps;
      minters = _minters;
      burners = _burners;

      for (uint i = 0; i < _defaultOps.length; i++) {
          _isDefaultOperator[_defaultOps[i]] = true;
      }

      for (uint i = 0; i < _minters.length; i++) {
          _isMinter[_minters[i]] = true;
      }

      for (uint i = 0; i < _burners.length; i++) {
          _isBurner[_burners[i]] = true;
      }

      _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
      _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }
}