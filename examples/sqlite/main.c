#include <sqlite3.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    sqlite3 *db;
    char *err_msg = NULL;
    int rc;

    printf("SQLite version: %s\n", sqlite3_libversion());

    // Open in-memory database
    rc = sqlite3_open(":memory:", &db);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(db));
        return 1;
    }

    // Create a table
    const char *create_sql = "CREATE TABLE users ("
                             "id INTEGER PRIMARY KEY,"
                             "name TEXT NOT NULL,"
                             "email TEXT NOT NULL);";

    rc = sqlite3_exec(db, create_sql, NULL, NULL, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", err_msg);
        sqlite3_free(err_msg);
        sqlite3_close(db);
        return 1;
    }
    printf("Created table 'users'\n");

    // Insert some data
    const char *insert_sql = "INSERT INTO users (name, email) VALUES "
                             "('Alice', 'alice@example.com'),"
                             "('Bob', 'bob@example.com'),"
                             "('Charlie', 'charlie@example.com');";

    rc = sqlite3_exec(db, insert_sql, NULL, NULL, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", err_msg);
        sqlite3_free(err_msg);
        sqlite3_close(db);
        return 1;
    }
    printf("Inserted 3 rows\n");

    // Query the data
    const char *select_sql = "SELECT id, name, email FROM users;";
    sqlite3_stmt *stmt;

    rc = sqlite3_prepare_v2(db, select_sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to prepare statement: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        return 1;
    }

    printf("\nQuery results:\n");
    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        int id = sqlite3_column_int(stmt, 0);
        const char *name = (const char *)sqlite3_column_text(stmt, 1);
        const char *email = (const char *)sqlite3_column_text(stmt, 2);
        printf("  id=%d, name=%s, email=%s\n", id, name, email);
    }

    sqlite3_finalize(stmt);
    sqlite3_close(db);

    return 0;
}
