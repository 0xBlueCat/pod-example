// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IPodCore.sol";

interface ITagClass {
    event NewTagClass(
        bytes18 indexed classId,
        string name,
        address indexed owner,
        bytes fieldNames,
        bytes fieldTypes,
        string desc,
        string url,
        uint8 flags,
        IPodCore.TagAgent agent,
        address logicContract
    );

    event TransferTagClassOwner(
        bytes18 indexed classId,
        address indexed newOwner
    );

    event UpdateTagClass(
        bytes18 indexed classId,
        uint8 flags,
        IPodCore.TagAgent agent,
        address logicContract
    );

    event UpdateTagClassInfo(
        bytes18 indexed classId,
        string name,
        string desc,
        string url
    );

    struct NewValueTagClassParams {
        string TagName;
        bytes FieldNames;
        bytes FieldTypes;
        string Desc;
        string Url;
        uint8 Flags;
        IPodCore.TagAgent Agent;
    }

    function newValueTagClass(NewValueTagClassParams calldata params)
        external
        returns (bytes18);

    struct NewLogicTagClassParams {
        string TagName;
        bytes FieldNames;
        bytes FieldTypes;
        string Desc;
        string Url;
        uint8 Flags;
        address LogicContract;
    }

    function newLogicTagClass(NewLogicTagClassParams calldata params)
        external
        returns (bytes18 classId);

    function updateValueTagClass(
        bytes18 classId,
        uint8 newFlags,
        IPodCore.TagAgent calldata newAgent
    ) external;

    function updateLogicTagClass(
        bytes18 classId,
        uint8 newFlags,
        address newLogicContract
    ) external;

    function updateTagClassInfo(
        bytes18 classId,
        string calldata tagName,
        string calldata desc,
        string calldata url
    ) external;

    function transferTagClassOwner(bytes18 classId, address newOwner) external;

    function getTagClass(bytes18 tagClassId)
        external
        view
        returns (IPodCore.TagClass memory tagClass);

    function getTagClassInfo(bytes18 tagClassId)
        external
        view
        returns (IPodCore.TagClassInfo memory classInfo);
}
