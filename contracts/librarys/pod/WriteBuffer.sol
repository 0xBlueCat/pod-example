// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 *
 * @author PodDB.
 */

library WriteBuffer {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(buffer memory buf, uint256 capacity)
        internal
        pure
        returns (buffer memory)
    {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     *      Changes to the buffer may mutate the original value.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint256 capacity) private pure {
        bytes memory oldBuf = buf.buf;
        init(buf, capacity);
        if (oldBuf.length == 0) {
            return;
        }
        writeFixedBytes(buf, oldBuf);
    }

    /**
     * @dev Sets buffer length to 0.
     * @param buf The buffer to truncate.
     * @return The original buffer, for chaining..
     */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufPtr := mload(buf)
            mstore(bufPtr, 0)
        }
        return buf;
    }

    /**
     * @dev Append the bytes to buffer, without write bytes length.
     *     Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes to write.
     * @return The original buffer, for chaining.
     */
    function writeFixedBytes(buffer memory buf, bytes memory data)
        internal
        pure
        returns (buffer memory)
    {
        uint256 dataLen = data.length;
        if (buf.buf.length + dataLen > buf.capacity) {
            resize(buf, (buf.buf.length + dataLen) * 2);
        }
        uint256 dest;
        uint256 src;
        assembly {
            //Memory address of buffer data
            let bufPtr := mload(buf)
            //Length of exiting buffer data
            let bufLen := mload(bufPtr)
            //Incr length of buffer
            mstore(bufPtr, add(bufLen, dataLen))
            //Start address
            dest := add(add(bufPtr, 32), bufLen)
            src := add(data, 32)
        }

        for (uint256 size = 0; size < dataLen; size += 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        return buf;
    }

    /**
     * @dev Append uint to buffer, according to Uint byte size.
     *     Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The uint to write.
     * @param len the byte size to write. For example: uint256 len is 32, uint128 len is 16, uint64 len is 8, and so on.
     * @return The original buffer, for chaining.
     */
    function writeVarUint(
        buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= 32, "uint len cannot larger than 32");

        if (buf.buf.length + len > buf.capacity) {
            resize(buf, (buf.buf.length + len) * 2);
        }

        // Left-align data
        data = data << (8 * (32 - len));
        assembly {
            // Memory address of the buffer data
            let bufPtr := mload(buf)
            // Length of existing buffer data
            let bufLen := mload(bufPtr)
            let dest := add(add(bufPtr, 32), bufLen)
            mstore(dest, data)
            //Incr length of buffer
            mstore(bufPtr, add(bufLen, len))
        }
        return buf;
    }

    /**
     * @dev Write uint to buffer, according to Uint byte size.
     *     Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param offset The write position.
     * @param data The uint to write.
     * @param len the byte size to write. For example: uint256 len is 32, uint128 len is 16, uint64 len is 8, and so on.
     * @return The original buffer, for chaining.
     */
    function writeVarUintAt(
        buffer memory buf,
        uint256 offset,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(offset <= buf.buf.length, "offset out of bound");
        require(len <= 32, "uint len cannot larger than 32");
        uint256 newLen = offset + len;
        if (newLen > buf.capacity) {
            resize(buf, newLen * 2);
        }

        uint256 tmp = len * 8;
        // Left-align data
        data = data << ((32 - len) * 8);
        bytes32 mask = (~bytes32(0) << tmp) >> tmp;
        assembly {
            // Memory address of the buffer data
            let bufPtr := mload(buf)
            // Length of existing buffer data
            let bufLen := mload(bufPtr)
            let dest := add(add(bufPtr, 32), offset)
            mstore(dest, or(data, and(mload(dest), mask)))

            //Update buffer length if we extended it
            if gt(newLen, bufLen) {
                mstore(bufPtr, newLen)
            }
        }
        return buf;
    }

    /**
     * @dev Append a uint8 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeUint8(buffer memory buf, uint8 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, data, 1);
    }

    /**
     * @dev Append a uint16 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeUint16(buffer memory buf, uint16 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, data, 2);
    }

    /**
     * @dev Append a uint32 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeUint32(buffer memory buf, uint32 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, data, 4);
    }

    /**
     * @dev Append a uint64 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeUint64(buffer memory buf, uint64 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, data, 8);
    }

    /**
     * @dev Append a uint256 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeUint256(buffer memory buf, uint256 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, data, 32);
    }

    /**
     * @dev Append an int8 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeInt8(buffer memory buf, int8 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, uint8(data), 1);
    }

    /**
     * @dev Append an int16 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeInt16(buffer memory buf, int16 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, uint16(data), 2);
    }

    /**
     * @dev Append an int32 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeInt32(buffer memory buf, int32 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, uint32(data), 4);
    }

    /**
     * @dev Append an int64 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeInt64(buffer memory buf, int64 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, uint64(data), 8);
    }

    /**
     * @dev Append an int256 number to the buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The number to append.
     * @return The original buffer, for chaining.
     */
    function writeInt256(buffer memory buf, int256 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, uint256(data), 32);
    }

    /**
     * @dev Append a length of a array or bytes to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param len The length of array or bytes.
     * @return The original buffer, for chaining.
     */
    function writeLength(buffer memory buf, uint256 len)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, len, 2);
    }

    /**
     * @dev Append a bytes to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer to append to
     * @param data The bytes to append. Before append the bytes, append the length to buffer first.
     * @return The original buffer, for chaining.
     */
    function writeBytes(buffer memory buf, bytes memory data)
        internal
        pure
        returns (buffer memory)
    {
        writeLength(buf, data.length);
        return writeFixedBytes(buf, data);
    }

    /**
     * @dev Write bytes32 to buffer, according to bytes32 byte size.
     *     Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes32 to write.
     * @param len the byte size to write. For example: bytes32 len is 32, bytes16 len is 16, bytes64 len is 8, and so on.
     * @return The original buffer, for chaining.
     */
    function writeVarBytes32(
        buffer memory buf,
        bytes32 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= 32, "bytes32 len cannot larger than 32");

        if (buf.buf.length + len > buf.capacity) {
            resize(buf, (buf.buf.length + len) * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufPtr := mload(buf)
            // Length of existing buffer data
            let bufLen := mload(bufPtr)
            let dest := add(add(bufPtr, 32), bufLen)
            mstore(dest, data)
            //Incr length of buffer
            mstore(bufPtr, add(bufLen, len))
        }
        return buf;
    }

    /**
     * @dev Write a byte to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The byte to write.
     * @return The original buffer, for chaining.
     */
    function writeBytes1(buffer memory buf, bytes1 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, data, 1);
    }

    /**
     * @dev Write bytes2 to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes2 to write.
     * @return The original buffer, for chaining.
     */
    function writeBytes2(buffer memory buf, bytes2 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, data, 2);
    }

    /**
     * @dev Write bytes4 to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes4 to write.
     * @return The original buffer, for chaining.
     */
    function writeBytes4(buffer memory buf, bytes4 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, data, 4);
    }

    /**
     * @dev Write bytes8 to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes8 to write.
     * @return The original buffer, for chaining.
     */
    function writeBytes8(buffer memory buf, bytes8 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, data, 8);
    }

    /**
     * @dev Write bytes20 to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes20 to write.
     * @return The original buffer, for chaining.
     */
    function writeBytes20(buffer memory buf, bytes20 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, data, 20);
    }

    /**
     * @dev Write bytes32 to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bytes32 to write.
     * @return The original buffer, for chaining.
     */
    function writeBytes32(buffer memory buf, bytes32 data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, data, 32);
    }

    /**
     * @dev Write a bool to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The bool to write.
     * @return The original buffer, for chaining.
     */
    function writeBool(buffer memory buf, bool data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarUint(buf, data ? 1 : 0, 1);
    }

    /**
     * @dev Write an address to buffer. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The address to write.
     * @return The original buffer, for chaining.
     */
    function writeAddress(buffer memory buf, address data)
        internal
        pure
        returns (buffer memory)
    {
        return writeVarBytes32(buf, bytes20(data), 20);
    }

    /**
     * @dev Write a string to buffer. The same to writeBytes in effect. Resizes if doing so would exceed the capacity of the buffer.
     * @param buf The buffer write to.
     * @param data The string to write.
     * @return The original buffer, for chaining.
     */
    function writeString(buffer memory buf, string memory data)
        internal
        pure
        returns (buffer memory)
    {
        return writeBytes(buf, bytes(data));
    }

    /**
     * @dev return the bytes in buffer. The bytes object should not be stored between
     *      operations, as it may change due to resizing of the buffer.
     * @param buf The buffer to read.
     * @return The bytes in buffer.
     */
    function getBytes(buffer memory buf) internal pure returns (bytes memory) {
        return buf.buf;
    }

    /**
     * @dev return the bytes size in buffer.
     * @param buf The buffer to read size.
     * @return The bytes size in buffer.
     */
    function length(buffer memory buf) internal pure returns (uint256) {
        return buf.buf.length;
    }
}
