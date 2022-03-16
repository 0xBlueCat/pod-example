// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./librarys/Ownable.sol";
import "./librarys/pod/ITag.sol";
import "./librarys/pod/WriteBuffer.sol";
import "./librarys/pod/ReadBuffer.sol";
import "./librarys/pod/IPodCore.sol";
import "./librarys/IERC20.sol";
import "./librarys/pod/PodHelper.sol";
import "./librarys/pod/ITagClass.sol";

/**
 * @dev UserRank contract use to manage the UserRank Tag
 */
contract UserRank is Ownable {
    using ReadBuffer for *;
    using WriteBuffer for *;
    using PodHelper for *;

    ITag public TagContract;
    ITagClass public TagClassContract;
    bytes18 public UserRankTagClassId;
    IERC20 private _PLC;
    IERC20 private _GDS;
    uint256[10] private _PLCFees;
    uint256[10] private _GDSFees;

    event UpgradeRank(address indexed user, uint8 oldRank, uint8 newRank);

    event UserRankTagClassCreate(
        address indexed contractAddress,
        bytes18 indexed userRankTagClassId
    );

    event UpdatePLCFees(uint256[10] oldFees, uint256[10] newFees);
    event UpdateGDSFees(uint256[10] oldFees, uint256[10] newFees);

    event UpdateUserRankTagClassOwner(address newOwner);

    event UpdateTagContract(
        address indexed oldTagContractAddress,
        address indexed newTagContractAddress
    );

    event UpdateTagClassContract(
        address indexed oldTagClassContractAddress,
        address indexed newTagClassContractAddress
    );

    constructor(
        address tagClassContractAddress,
        address tagContractAddress,
        address plcContractAddress,
        uint256[10] memory plcFees,
        address gdsContractAddress,
        uint256[10] memory gdsFees
    ) Ownable() {
        TagContract = ITag(tagContractAddress);
        TagClassContract = ITagClass(tagClassContractAddress);

        _PLC = IERC20(plcContractAddress);
        _PLCFees = plcFees;
        _GDS = IERC20(gdsContractAddress);
        _GDSFees = gdsFees;

        PodHelper.TagClassFieldBuilder memory builder;
        builder.init().put("rank", IPodCore.TagFieldType.Uint8, false);

        ITagClass.NewValueTagClassParams memory params;
        params.TagName = "UserRank";
        params.Desc = "Using to manage user rank";
        params.FieldNames = builder.getFieldNames();
        params.FieldTypes = builder.getFieldTypes();
        params.Agent = IPodCore.TagAgent(
            IPodCore.AgentType.Address,
            bytes20(address(this))
        );

        UserRankTagClassId = TagClassContract.newValueTagClass(params);

        emit UserRankTagClassCreate(address(this), UserRankTagClassId);
    }

    function upgradeRank() public {
        IPodCore.TagObject memory object;
        object.Type = IPodCore.ObjectType.Address;
        object.Address = bytes20(msg.sender);

        bytes memory data = TagContract.getTagData(UserRankTagClassId, object);
        uint8 oldRank = 0;
        if (data.length > 0) {
            ReadBuffer.buffer memory buffer = ReadBuffer.fromBytes(data);
            oldRank = buffer.readUint8();
        }
        uint8 newRank = oldRank + 1;

        require(newRank <= 10, "UserRank: rank cannot >= 10");

        uint256 plcFee = _PLCFees[newRank];
        if (plcFee > 0) {
            _PLC.transferFrom(msg.sender, owner(), plcFee);
        }
        uint256 gdsFee = _GDSFees[newRank];
        if (gdsFee > 0) {
            _GDS.transferFrom(msg.sender, owner(), gdsFee);
        }

        WriteBuffer.buffer memory buf;
        data = buf.init(1).writeUint8(newRank).getBytes();
        TagContract.setTag(UserRankTagClassId, object, data, 0);

        emit UpgradeRank(msg.sender, oldRank, newRank);
    }

    function getUserRank(address account) external view returns (uint8) {
        IPodCore.TagObject memory object;
        object.Type = IPodCore.ObjectType.Address;
        object.Address = bytes20(account);

        bytes memory data = TagContract.getTagData(UserRankTagClassId, object);
        ReadBuffer.buffer memory buffer = ReadBuffer.fromBytes(data);
        return buffer.readUint8();
    }

    function transferUserRankTagClassOwner(address newOwner) public onlyOwner {
        TagClassContract.transferTagClassOwner(UserRankTagClassId, newOwner);
        emit UpdateUserRankTagClassOwner(newOwner);
    }

    function updateTagContract(address newTagContractAddress) public onlyOwner {
        address oldTagContractAddress = address(TagContract);
        TagContract = ITag(newTagContractAddress);
        emit UpdateTagContract(oldTagContractAddress, newTagContractAddress);
    }

    function updateTagClassContract(address newTagClassContractAddress)
        public
        onlyOwner
    {
        address oldTagClassContractAddress = address(TagClassContract);
        TagClassContract = ITagClass(newTagClassContractAddress);
        emit UpdateTagClassContract(
            oldTagClassContractAddress,
            newTagClassContractAddress
        );
    }

    function updatePLCFees(uint256[10] calldata newFees) public onlyOwner {
        uint256[10] memory oldFees = _PLCFees;
        _PLCFees = newFees;
        emit UpdatePLCFees(oldFees, newFees);
    }

    function updateGDSFees(uint256[10] calldata newFees) public onlyOwner {
        uint256[10] memory oldFees = _GDSFees;
        _GDSFees = newFees;
        emit UpdateGDSFees(oldFees, newFees);
    }
}
