// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./librarys/Ownable.sol";
import "./librarys/pod/ITag.sol";
import "./librarys/pod/WriteBuffer.sol";
import "./librarys/pod/ReadBuffer.sol";
import "./librarys/pod/IPodCore.sol";
import "./librarys/IERC20.sol";
import "./librarys/pod/ITagClass.sol";
import "./librarys/pod/PodHelper.sol";
import "./Airdrop.sol";

/**
 * @dev UserRank contract use to manage the UserRank Tag
 */
contract AirdropFactory is Ownable {
    using ReadBuffer for *;
    using WriteBuffer for *;
    using PodHelper for *;

    address public TagContract;
    address public TagClassContract;
    address private _PLCContractAddress;
    uint256 private _PLCFee;

    constructor(
        address tagClassContractAddress,
        address tagContractAddress,
        address _erc20A,
        uint256 _erc20AFee
    ) Ownable() {
        TagContract = tagContractAddress;
        TagClassContract = tagClassContractAddress;
        _PLCContractAddress = _erc20A;
        _PLCFee = _erc20AFee;
    }

    function updateTagContract(address newTagContract) public onlyOwner {
        TagContract = newTagContract;
    }

    function updateTagClassContract(address newTagClassContract)
        public
        onlyOwner
    {
        TagClassContract = newTagClassContract;
    }

    function createAirdropContract() public onlyOwner {
        Airdrop airdrop = new Airdrop(
            TagClassContract,
            TagContract,
            _PLCContractAddress,
            _PLCFee
        );
        airdrop.transferOwnership(msg.sender);
    }
}
