#include <stdio.h>
#include <string.h>
#include <zstd.h>

int main(void) {
    const char *original = "Hello, zstd! This is a compression test.";
    size_t original_len = strlen(original) + 1;

    // Allocate buffer for compressed data
    size_t compressed_bound = ZSTD_compressBound(original_len);
    char compressed[256];

    // Compress
    size_t compressed_len = ZSTD_compress(compressed, sizeof(compressed),
                                          original, original_len, 1);
    if (ZSTD_isError(compressed_len)) {
        fprintf(stderr, "ZSTD_compress() failed: %s\n",
                ZSTD_getErrorName(compressed_len));
        return 1;
    }

    printf("Original size: %zu bytes\n", original_len);
    printf("Compressed size: %zu bytes\n", compressed_len);

    // Decompress
    char decompressed[256];
    size_t decompressed_len = ZSTD_decompress(decompressed, sizeof(decompressed),
                                              compressed, compressed_len);
    if (ZSTD_isError(decompressed_len)) {
        fprintf(stderr, "ZSTD_decompress() failed: %s\n",
                ZSTD_getErrorName(decompressed_len));
        return 1;
    }

    printf("Decompressed: %s\n", decompressed);
    printf("zstd version: %u\n", ZSTD_versionNumber());

    return 0;
}
