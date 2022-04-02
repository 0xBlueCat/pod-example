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

/**
 * @dev UserRank contract use to manage the UserRank Tag
 */
contract Airdrop is Ownable {
    using ReadBuffer for *;
    using WriteBuffer for *;
    using PodHelper for *;

    ITag public TagContract;
    ITagClass public TagClassContract;
    bytes18 public ActivatedTagClassId;
    IERC20 private _PLC;
    uint256 private _PLCFee;

    event UpdateTagContract(
        address indexed oldTagContractAddress,
        address indexed newTagContractAddress
    );

    event UpdateTagClassContract(
        address indexed oldTagClassContractAddress,
        address indexed newTagClassContractAddress
    );

    event UpdateActivatedTagClassOwner(address newOwner);

    event UpdatePLCFee(uint256 oldFee, uint256 newFee);

    event NewAirdropContract(
        address contractAddress,
        bytes18 activatedTagClassId
    );

    event UserActivate(bytes18 indexed tagClassId, address indexed user);
    event UserInit(bytes18 indexed tagClassId, address[] users);

    constructor(
        address tagClassContractAddress,
        address tagContractAddress,
        address plcContractAddress,
        uint256 plcFee
    ) Ownable() {
        TagContract = ITag(tagContractAddress);
        TagClassContract = ITagClass(tagClassContractAddress);
        _PLC = IERC20(plcContractAddress);
        _PLCFee = plcFee;

        PodHelper.TagClassFieldBuilder memory builder;
        builder.init().put("activated", IPodCore.TagFieldType.Uint8, false);

        ITagClass.NewValueTagClassParams memory params;
        params.TagName = "ActivatedTag";
        params.Desc = "Using to indicate whether the user was been activated";
        params.FieldNames = builder.getFieldNames();
        params.FieldTypes = builder.getFieldTypes();
        params.Agent = IPodCore.TagAgent(
            IPodCore.AgentType.Address,
            bytes20(address(this))
        );
        ActivatedTagClassId = TagClassContract.newValueTagClass(params);

        emit NewAirdropContract(address(this), ActivatedTagClassId);
    }

    function userInit(address[] calldata users) public onlyOwner {
        WriteBuffer.buffer memory buf;
        bytes memory data = buf.init(1).writeUint8(0).getBytes();
        ITag.SetTagParams[] memory params = new ITag.SetTagParams[](
            users.length
        );
        for (uint256 i = 0; i < users.length; i++) {
            IPodCore.TagObject memory object;
            object.Type = IPodCore.ObjectType.Address;
            object.Address = bytes20(users[i]);

            require(
                !TagContract.hasTag(ActivatedTagClassId, object),
                "User has already init"
            );

            ITag.SetTagParams memory param;
            param.Object = object;
            param.Data = data;
            param.TagClassId = ActivatedTagClassId;
            params[i] = param;
        }

        TagContract.batchSetTags(params);
        emit UserInit(ActivatedTagClassId, users);
    }

    function activate() public {
        IPodCore.TagObject memory object;
        object.Type = IPodCore.ObjectType.Address;
        object.Address = bytes20(msg.sender);

        bytes memory data = TagContract.getTagData(ActivatedTagClassId, object);
        require(data.length > 0, "Haven't init");

        ReadBuffer.buffer memory buffer = ReadBuffer.fromBytes(data);
        require(buffer.readUint8() == 0, "Has already activated");

        if (_PLCFee > 0) {
            _PLC.transferFrom(msg.sender, owner(), _PLCFee);
        }

        WriteBuffer.buffer memory buf;
        data = buf.init(1).writeUint8(1).getBytes();

        TagContract.setTag(ActivatedTagClassId, object, data, 0);

        emit UserActivate(ActivatedTagClassId, msg.sender);
    }

    function isInit(address account) public view returns (bool) {
        IPodCore.TagObject memory object;
        object.Type = IPodCore.ObjectType.Address;
        object.Address = bytes20(account);
        return TagContract.hasTag(ActivatedTagClassId, object);
    }

    function isActivate(address account) public view returns (bool) {
        IPodCore.TagObject memory object;
        object.Type = IPodCore.ObjectType.Address;
        object.Address = bytes20(account);
        bytes memory data = TagContract.getTagData(ActivatedTagClassId, object);
        if (data.length == 0) {
            return false;
        }
        ReadBuffer.buffer memory buffer = ReadBuffer.fromBytes(data);
        return buffer.readUint8() == 1;
    }

    function getActivateTag(address account) public view returns (uint8, bool) {
        IPodCore.TagObject memory object;
        object.Type = IPodCore.ObjectType.Address;
        object.Address = bytes20(account);
        bytes memory data = TagContract.getTagData(ActivatedTagClassId, object);
        if (data.length == 0) {
            return (0, false);
        }
        ReadBuffer.buffer memory buffer = ReadBuffer.fromBytes(data);
        return (buffer.readUint8(), true);
    }

    function transferActivatedTagClassOwner(address newOwner) public onlyOwner {
        TagClassContract.transferTagClassOwner(ActivatedTagClassId, newOwner);
        emit UpdateActivatedTagClassOwner(newOwner);
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

    function updatePLCFee(uint256 newFee) public onlyOwner {
        uint256 oldFee = _PLCFee;
        _PLCFee = newFee;
        emit UpdatePLCFee(oldFee, newFee);
    }
}
