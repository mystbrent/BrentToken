pragma solidity ^0.5.3;

import { Owned } from "./Owned.sol";
import { Token } from "./Token.sol";
import { ECRecovery } from "./ECRecovery.sol";

contract MetaOperator is Owned {
    using ECRecovery for bytes32;
    
    mapping(address => mapping(uint256 => bool)) usedNonces;
    bool chargeFees = false;
    uint256 price = 5;
    
    function toggleCharging() external onlyOwner returns (bool) {
        chargeFees = !chargeFees;
    }
    
    function setPrice(uint256 _price) external onlyOwner returns (bool) {
        price = _price;
    }
    
    function metaSend
    (
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _reward,
        uint256 _nonce,
        bytes calldata _data,
        bytes calldata _signature
    ) external returns (bool) {
        bytes32 hash = this.getTransferHash("metaSend(address,address,address,uint256,uint256,uint256,bytes,bytes)", _token, _from, _to, _amount, _reward, _nonce, _data);
        address signer = this.getSigner(hash, _signature);
        
        require(!usedNonces[signer][_nonce], "Nonce is already used.");
        usedNonces[signer][_nonce] = true;
        
        require(signer == _from, "Signer must be equal to from.");
        if (chargeFees) {
            require(_reward >= price, "Insufficient reward for relayer.");
        }
        Token(_token).operatorSend(_from, _to, _amount, _data, "");
    }
    
    function getTransferHash
    (
        string memory _function,
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _reward,
        uint256 _nonce,
        bytes memory _data
    ) public pure returns (bytes32) {
        return keccak256(abi.encodeWithSignature(_function, _token, _from, _to, _amount, _reward, _nonce, _data));
    }
    
    function getSigner
    (
        bytes32 _hash,
        bytes calldata _signature
    ) external pure returns (address signer) {
        signer = _hash.recover(_signature);
    }
}