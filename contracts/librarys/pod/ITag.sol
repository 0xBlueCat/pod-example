// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IPodCore.sol";

interface ITag {
    event SetTag(
        bytes20 indexed id,
        bytes18 indexed tagClassId,
        IPodCore.TagObject object,
        bytes data,
        address issuer,
        uint32 expiredAt
    );

    event DeleteTag(
        bytes20 indexed id,
        bytes18 indexed tagClassId,
        IPodCore.TagObject object
    );

    function setTag(
        bytes18 tagClassId,
        IPodCore.TagObject calldata object,
        bytes calldata data,
        uint32 expiredTime //Expiration time of tag in seconds, 0 means never expires
    ) external;

    function setTagWithSig(
        bytes18 tagClassId,
        IPodCore.TagObject calldata object,
        bytes calldata data,
        uint32 expiredTime, //Expiration time of tag in seconds, 0 means never expires
        bytes calldata signature //Signature of owner or agent
    ) external;

    struct SetTagParams {
        bytes18 TagClassId;
        IPodCore.TagObject Object;
        bytes Data;
        uint32 ExpiredTime; //Expiration time of tag in seconds, 0 means never expires
    }

    function batchSetTags(ITag.SetTagParams[] calldata params) external;

    struct DeleteTagParams {
        bytes18 TagClassId;
        IPodCore.TagObject Object;
    }

    function deleteTag(bytes18 classId, IPodCore.TagObject calldata object)
        external;

    function deleteTagWithSig(
        bytes18 tagClassId,
        IPodCore.TagObject calldata object,
        bytes calldata signature //Signature of owner or agent
    ) external;

    function batchDeleteTags(DeleteTagParams[] calldata params) external;

    function hasTag(bytes18 tagClassId, IPodCore.TagObject calldata object)
        external
        view
        returns (bool valid);

    function getTagData(bytes18 tagClassId, IPodCore.TagObject calldata object)
        external
        view
        returns (bytes memory data);

    function getTag(bytes18 tagClassId, IPodCore.TagObject calldata object)
        external
        view
        returns (IPodCore.Tag memory tag, bool valid);
}
