# SwiftBitCode
Reading LLVM-bitcode streams natively in Swift

There are many useful files stored in "LLVM BitCode" format, described here:
<http://llvm.org/docs/BitCodeFormat.html>

Among those are `LLVM-IR` files, and `.swiftmodule` and `.swiftdoc` files.

The `BitCode` class reads `Block` and `DataRecord` instances from a given bit code file.  However, since the magic cookies are different depending on the file, that portion of the data should be skipped.  To verify a given magic cookie as part of the process, use the `MagicCookieVerifyingBitCode` sub class; though for now, the cookie is just skipped.

This module is not responsible for interpreting the blocks or records, though block and record names provided in a BlockInfoBlock are stored, and can be output with `Block.dump()`

If you know the names and layouts, use the `RecordLayout` type to provide better read-out of the data, providing field names, interpreting blobs as UTF8 strings, and using integers as indexes into enums as configured.

This module has not been re-written to use its `BitCodeError` type yet, that is a future direction.  Right now, errors only happen when the Data does not contain a well-formed bit-code file, or the Data does not end precisely at the end of the top-level block.

Not all of the tests used in this module's development have been included in this package.  This module has been tested on several real-world .swiftmodule and .siftdoc files to verify reads happen correctly.  Because the bit-code format itself is self-describing, it is unlikely that would change.  Including those tests would involve distributing those files, which is not one of my goals.
