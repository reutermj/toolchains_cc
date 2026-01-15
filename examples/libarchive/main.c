#include <archive.h>
#include <archive_entry.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    struct archive *a;
    struct archive_entry *entry;
    char buffer[8192];
    size_t used;

    // Create an in-memory tar archive
    a = archive_write_new();
    archive_write_set_format_pax_restricted(a);
    archive_write_open_memory(a, buffer, sizeof(buffer), &used);

    // Add a file entry to the archive
    entry = archive_entry_new();
    archive_entry_set_pathname(entry, "hello.txt");
    archive_entry_set_size(entry, 13);
    archive_entry_set_filetype(entry, AE_IFREG);
    archive_entry_set_perm(entry, 0644);
    archive_write_header(a, entry);
    archive_write_data(a, "Hello, world!", 13);
    archive_entry_free(entry);

    // Close the archive
    archive_write_close(a);
    archive_write_free(a);

    printf("Created in-memory tar archive: %zu bytes\n", used);
    printf("libarchive version: %s\n", archive_version_string());

    return 0;
}
