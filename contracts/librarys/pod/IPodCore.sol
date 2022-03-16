// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPodCore {
    enum TagFieldType {
        Bool,
        Uint256,
        Uint8,
        Uint16,
        Uint32,
        Uint64,
        Int256,
        Int8,
        Int16,
        Int32,
        Int64,
        Bytes1,
        Bytes2,
        Bytes3,
        Bytes4,
        Bytes8,
        Bytes20,
        Bytes32,
        Address,
        Bytes,
        String,
        //if a field is array, the must be followed by a filedType, and max elem of array is 65535
        //note that array type doest not support nested array!
        Array
    }

    enum AgentType {
        Address, // eoa address or ca address,
        TagClass // address has this TagClass Tag
    }

    //TagClassAgent can delegate tagClass owner permission to agent
    struct TagAgent {
        AgentType Type; //indicate the type of agent
        bytes20 Address; //EOA or CA Address or ClassId
    }

    struct TagClass {
        bytes18 ClassId;
        uint8 Version;
        address Owner; // EOA address or CA address
        bytes FieldTypes; //field types
        //TagClass Flags:
        //0x80:deprecated flag, if a TagClass is marked as deprecated, you cannot set Tag under this TagClass
        uint8 Flags;
        TagAgent Agent;
        address LogicContract; //Contract address of logic tagClass
    }

    struct TagClassInfo {
        bytes18 ClassId;
        uint8 Version;
        string TagName;
        bytes FieldNames; //name of fields
        string Desc;
        string Url; //Url of tagClass
    }

    enum ObjectType {
        Address, // eoa address or ca address
        NFT, // nft
        TagClass // tagClass
    }

    struct TagObject {
        ObjectType Type; //indicate the type of object
        bytes20 Address; //EOA address, CA address, or tagClassId
        uint256 TokenId; //NFT tokenId
    }

    struct Tag {
        bytes20 TagId;
        uint8 Version;
        bytes18 ClassId;
        uint32 ExpiredAt; //Expired time
        bytes Data;
    }
}
