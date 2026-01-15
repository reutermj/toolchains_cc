#include <stdio.h>
#include <string.h>
#include <zlib.h>

int main(void) {
    const char *original = "Hello, zlib! This is a compression test.";
    size_t original_len = strlen(original) + 1;

    // Allocate buffer for compressed data
    uLongf compressed_len = compressBound(original_len);
    Bytef compressed[256];

    // Compress
    int ret = compress(compressed, &compressed_len, (const Bytef *)original, original_len);
    if (ret != Z_OK) {
        fprintf(stderr, "compress() failed: %d\n", ret);
        return 1;
    }

    printf("Original size: %zu bytes\n", original_len);
    printf("Compressed size: %lu bytes\n", compressed_len);

    // Decompress
    char decompressed[256];
    uLongf decompressed_len = sizeof(decompressed);

    ret = uncompress((Bytef *)decompressed, &decompressed_len, compressed, compressed_len);
    if (ret != Z_OK) {
        fprintf(stderr, "uncompress() failed: %d\n", ret);
        return 1;
    }

    printf("Decompressed: %s\n", decompressed);
    printf("zlib version: %s\n", zlibVersion());

    return 0;
}
