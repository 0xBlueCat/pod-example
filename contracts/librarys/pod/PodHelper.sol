// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./WriteBuffer.sol";
import "./ReadBuffer.sol";
import "./IPodCore.sol";

library PodHelper {
    using WriteBuffer for *;
    using ReadBuffer for *;

    struct TagClassFieldBuilder {
        WriteBuffer.buffer _nBuf;
        WriteBuffer.buffer _tBuf;
    }

    function init(TagClassFieldBuilder memory builder)
        internal
        pure
        returns (TagClassFieldBuilder memory)
    {
        builder._nBuf.init(64);
        builder._tBuf.init(32);
        return builder;
    }

    function put(
        TagClassFieldBuilder memory builder,
        string memory fieldName,
        IPodCore.TagFieldType fieldType,
        bool isArray
    ) internal pure returns (TagClassFieldBuilder memory) {
        builder._nBuf.writeString(fieldName);
        if (isArray) {
            builder._tBuf.writeUint8(uint8(IPodCore.TagFieldType.Array));
        }
        builder._tBuf.writeUint8(uint8(fieldType));
        return builder;
    }

    function getFieldNames(TagClassFieldBuilder memory builder)
        internal
        pure
        returns (bytes memory)
    {
        return builder._nBuf.getBytes();
    }

    function getFieldTypes(TagClassFieldBuilder memory builder)
        internal
        pure
        returns (bytes memory)
    {
        return builder._tBuf.getBytes();
    }
}
