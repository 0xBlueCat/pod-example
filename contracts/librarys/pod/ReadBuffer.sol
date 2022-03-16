// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
 * @dev A library for reading bytes buffer in Solidity.
 * @author PodDB.
 */

library ReadBuffer {
    /**
     * @dev Represents a bytes buffer. Buffers have a value (buf) and
     *      an offset indicate the position to read.
     */
    struct buffer {
        bytes buf;
        uint256 off;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        return buf;
    }

    /**
     * @dev Forward offset according the specific size without read any bytes.
     * @param buf The buffer read from.
     * @param len The bytes size to skip.
     */
    function skip(buffer memory buf, uint256 len) internal pure {
        uint256 l = buf.off + len;
        require(l <= buf.buf.length, "skip out of bounds");
        buf.off = l;
    }

    /**
     * @dev Forward offset accord bytes type without read any bytes.
     *     The active skip size is zhe bytes size and the bytes self.
     * @param buf The buffer read from.
     */
    function skipBytes(buffer memory buf) internal pure returns (uint256) {
        uint256 len = readVarUint(buf, 2);
        skip(buf, len);
        return len;
    }

    /**
     * @dev Forward offset accord string type without read any bytes.
     *     The same to skipBytes in effect.
     * @param buf The buffer read from.
     */
    function skipString(buffer memory buf) internal pure returns (uint256) {
        return skipBytes(buf);
    }

    /**
     * @dev Read a bytes according the specific bytes size from buffer.
     * @param buf The buffer read from.
     * @param len The bytes size to read.
     * @return A bytes object.
     */
    function readFixedBytes(buffer memory buf, uint256 len)
        internal
        pure
        returns (bytes memory)
    {
        uint256 off = buf.off;
        uint256 l = buf.off + len;
        require(l <= buf.buf.length, "readFixedBytes out of bounds");

        bytes memory data = new bytes(len);
        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufPtr := mload(buf)
            src := add(add(bufPtr, 32), off)
            dest := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        if (len > 0) {
            // Copy remaining bytes
            uint256 mask = 256**(32 - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        buf.off = l;
        return data;
    }

    /**
     * @dev Read a length of an array or a bytes in the buffer.
     * @param buf The buffer read from.
     * @return The bytes size of the next array or next bytes.
     */
    function readLength(buffer memory buf) internal pure returns (uint256) {
        return readUint16(buf);
    }

    /**
     * @dev Read a bytes from buffer. Read the bytes size first from buffer, and then read the bytes self.
     * @param buf The buffer read from.
     * @return A bytes object.
     */
    function readBytes(buffer memory buf) internal pure returns (bytes memory) {
        uint256 len = readLength(buf);
        return readFixedBytes(buf, len);
    }

    /**
     * @dev Read a string from buffer. Read the bytes size first from buffer, and then read the string self.
     *      The same to readBytes in effect.
     * @param buf The buffer read from.
     * @return A bytes object.
     */
    function readString(buffer memory buf)
        internal
        pure
        returns (string memory)
    {
        return string(readBytes(buf));
    }

    /**
     * @dev Read a uint256 number from buffer. According the specific bytes size.
     * @param buf The buffer read from.
     * @param len the bytes size of uint256 number. For example: uint256 is 32, uint128 is 16, uint64 is 8, an so on.
     * @return data A uint256 number.
     */
    function readVarUint(buffer memory buf, uint256 len)
        internal
        pure
        returns (uint256 data)
    {
        uint256 off = buf.off;
        uint256 l = buf.off + len;
        require(len <= 32, "readVarUint len cannot larger than 32");
        require(l <= buf.buf.length, "readVarUint out of bounds");
        assembly {
            // Memory address of the buffer data
            let bufPtr := mload(buf)
            let src := add(add(bufPtr, 32), off)
            data := mload(src)
        }
        data = data >> ((32 - len) * 8);
        buf.off = l;
        return data;
    }

    /**
     * @dev Read a uint8 number from buffer.
     * @param buf The buffer read from.
     * @return A uint8 number.
     */
    function readUint8(buffer memory buf) internal pure returns (uint8) {
        return uint8(readVarUint(buf, 1));
    }

    /**
     * @dev Read a uint16 number from buffer.
     * @param buf The buffer read from.
     * @return A uint16 number.
     */
    function readUint16(buffer memory buf) internal pure returns (uint16) {
        return uint16(readVarUint(buf, 2));
    }

    /**
     * @dev Read a uint32 number from buffer.
     * @param buf The buffer read from.
     * @return A uint32 number.
     */
    function readUint32(buffer memory buf) internal pure returns (uint32) {
        return uint32(readVarUint(buf, 4));
    }

    /**
     * @dev Read a uint64 number from buffer.
     * @param buf The buffer read from.
     * @return A uint64 number.
     */
    function readUint64(buffer memory buf) internal pure returns (uint64) {
        return uint64(readVarUint(buf, 8));
    }

    /**
     * @dev Read a uint256 number from buffer.
     * @param buf The buffer read from.
     * @return A uint256 number.
     */
    function readUint256(buffer memory buf) internal pure returns (uint256) {
        return readVarUint(buf, 32);
    }

    /**
     * @dev Read an int8 number from buffer.
     * @param buf The buffer read from.
     * @return An int8 number.
     */
    function readInt8(buffer memory buf) internal pure returns (int8) {
        return int8(uint8(readVarUint(buf, 1)));
    }

    /**
     * @dev Read an int16 number from buffer.
     * @param buf The buffer read from.
     * @return An int16 number.
     */
    function readInt16(buffer memory buf) internal pure returns (int16) {
        return int16(uint16(readVarUint(buf, 2)));
    }

    /**
     * @dev Read an int32 number from buffer.
     * @param buf The buffer read from.
     * @return An int32 number.
     */
    function readInt32(buffer memory buf) internal pure returns (int32) {
        return int32(uint32(readVarUint(buf, 4)));
    }

    /**
     * @dev Read an int64 number from buffer.
     * @param buf The buffer read from.
     * @return An int64 number.
     */
    function readInt64(buffer memory buf) internal pure returns (int64) {
        return int64(uint64(readVarUint(buf, 8)));
    }

    /**
     * @dev Read an int256 number from buffer.
     * @param buf The buffer read from.
     * @return An int256 number.
     */
    function readInt256(buffer memory buf) internal pure returns (int256) {
        return int256(readVarUint(buf, 32));
    }

    /**
     * @dev Read a bytes32 from buffer. According the specific bytes size.
     * @param buf The buffer read from.
     * @param len The bytes size of bytes32. For example: byte32 is 32, byte16 is 16, byte8 is 8, an so on.
     * @return data A bytes object.
     */
    function readVarBytes32(buffer memory buf, uint256 len)
        internal
        pure
        returns (bytes32 data)
    {
        uint256 off = buf.off;
        uint256 l = buf.off + len;
        require(len <= 32, "readVarBytes32 len cannot larger than 32");
        require(l <= buf.buf.length, "readVarBytes32 out of bounds");
        assembly {
            // Memory address of the buffer data
            let bufPtr := mload(buf)
            let src := add(add(bufPtr, 32), off)
            data := mload(src)
        }
        buf.off = l;
        bytes32 mask = bytes32(~uint256(0)) << ((32 - len) * 8);
        data = data & mask;
        return data;
    }

    /**
     * @dev Read a bytes1 from buffer.
     * @param buf The buffer read from.
     * @return A bytes1 object.
     */
    function readBytes1(buffer memory buf) internal pure returns (bytes1) {
        return bytes1(readVarBytes32(buf, 1));
    }

    /**
     * @dev Read a bytes2 from buffer.
     * @param buf The buffer read from.
     * @return A bytes2 object.
     */
    function readBytes2(buffer memory buf) internal pure returns (bytes2) {
        return bytes2(readVarBytes32(buf, 2));
    }

    /**
     * @dev Read a bytes4 from buffer.
     * @param buf The buffer read from.
     * @return A bytes4 object.
     */
    function readBytes4(buffer memory buf) internal pure returns (bytes4) {
        return bytes4(readVarBytes32(buf, 4));
    }

    /**
     * @dev Read a bytes8 from buffer.
     * @param buf The buffer read from.
     * @return A bytes8 object.
     */
    function readBytes8(buffer memory buf) internal pure returns (bytes8) {
        return bytes8(readVarBytes32(buf, 8));
    }

    /**
     * @dev Read a bytes20 from buffer.
     * @param buf The buffer read from.
     * @return A bytes20 object.
     */
    function readBytes20(buffer memory buf) internal pure returns (bytes20) {
        return bytes20(readVarBytes32(buf, 20));
    }

    /**
     * @dev Read a bytes32 from buffer.
     * @param buf The buffer read from.
     * @return A bytes32 object.
     */
    function readBytes32(buffer memory buf) internal pure returns (bytes32) {
        return readVarBytes32(buf, 32);
    }

    /**
     * @dev Read an address from buffer.
     * @param buf The buffer read from.
     * @return An address object.
     */
    function readAddress(buffer memory buf) internal pure returns (address) {
        return address(bytes20(readVarBytes32(buf, 20)));
    }

    /**
     * @dev Read bool from buffer.
     * @param buf The buffer read from.
     * @return A bool object.
     */
    function readBool(buffer memory buf) internal pure returns (bool) {
        return readVarUint(buf, 1) > 0 ? true : false;
    }

    /**
     * @dev Reset the read offset to a specific value.
     * @param buf The buffer read from.
     * @param newOffset The specific offset to set.
     */
    function resetOffset(buffer memory buf, uint256 newOffset) internal pure {
        require(buf.buf.length >= newOffset, "new offset out of bound");
        buf.off = newOffset;
    }

    /**
     * @dev Return the bytes size unread.
     * @param buf The buffer read from.
     * @return The unread bytes size.
     */
    function left(buffer memory buf) internal pure returns (uint256) {
        return buf.buf.length - buf.off;
    }
}
