pragma solidity ^0.5.3;

import { ERC777Token } from "./iERC777Token.sol";
import { ERC777TokensSender } from "./iERC777TokensSender.sol";
import { ERC777TokensRecipient } from "./iERC777TokensRecipient.sol";
import { ERC1820Registry } from "./ERC1820.sol";
import { CommonConstants } from "./Common.sol";
import { SafeMath } from "./SafeMath.sol";
import { Address } from "./Address.sol";

contract Token {
    using SafeMath for uint256;
    using Address for address;
}