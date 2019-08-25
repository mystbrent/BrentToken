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
    mapping(address => bool) private _isMinter;
    address[] public burners;
    mapping(address => bool) private _isBurner;

    bytes32 constant private TOKEN_SENDER_HASH = 0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;
    bytes32 constant private TOKEN_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
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

    /**
        ******************* ERC 20 ********************
    **/

    function transfer(address to, uint256 value)
    
    external returns (bool) {

    }

    /**
        ******************* Additional Functions ********************
    **/

    /**
        1. Check
        2. Effects
        3. Send
     */
    function _send(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData,
        bool _enforce
    ) validRecipient(_to) hasEnoughBalance(_amount) private returns (bool) {

        _callTokensToSend(_operator, _from, _to, _amount, _data, _operatorData);

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        _callTokensReceived(_operator, _from, _to, _amount, _data, _operatorData, _enforce);

        emit Sent(_operator, _from, _to, _amount, _data, _operatorData);
    }

    function _burn(
        address _operator,
        address _from,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    ) validRecipient(_from) hasEnoughBalance(_amount) private returns (bool) {

        _callTokensToSend(_operator, _from, address(0x0), _amount, _data, _operatorData);

        balances[_from] = balances[_from].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);

        emit Burned(_operator, _from, _amount, _data, _operatorData);
    }

    function mint(
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    ) isMinter external returns (bool) {

        require(_to != address(0x0), "Receiver is not a valid address.");

        _callTokensReceived(address(0x0), msg.sender, _to, _amount, _data, _operatorData, false);

        balances[_to] = balances[_to].add(_amount);
        _totalSupply = _totalSupply.add(_amount);

        emit Minted(msg.sender, _to, _amount, _data, _operatorData);
    }

    /**
        ******************* Hooks ********************
    **/

    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        private
    {
        address implementer = _erc1820.getInterfaceImplementer(from, TOKEN_SENDER_HASH);
        if (implementer != address(0)) {
            IERC777TokensSender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }
    
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool enforce
    )
        private
    {
        address implementer = _erc1820.getInterfaceImplementer(to, TOKEN_RECIPIENT_HASH);
        if (implementer != address(0)) {
            IERC777TokensRecipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (enforce) {
            require(!to.isContract(), "Recipient is a contract that does not implement ERC777TokensRecipient");
        }
    }


    /**
        ******************* Validators ********************
    **/

    modifier hasEnoughBalance(uint256 _amount) {
        require(balances[msg.sender] >= _amount, "Sender has insufficient balance.");
        _;
    }

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0x0), "Invalid Recipient.");
        _;
    }

    modifier isMinter() {
        require(_isMinter[msg.sender] == true, "Sender is not a minter.");
        _;
    }

    modifier isBurner() {
        require(_isBurner[msg.sender] == true, "Sender is not a burner.");
        _;
    }
}