#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define CAK_SQLITE_API __declspec(dllimport)
#define CAK_SQLITE_CALL __stdcall
#else
#define CAK_SQLITE_API
#define CAK_SQLITE_CALL
#endif

typedef struct sqlite3 sqlite3;
typedef struct sqlite3_stmt sqlite3_stmt;
typedef long long sqlite3_int64;
typedef unsigned long long sqlite3_uint64;
typedef void (CAK_SQLITE_CALL *sqlite3_destructor_type)(void *);
typedef int (CAK_SQLITE_CALL *sqlite3_callback)(void *, int, char **, char **);

#define SQLITE_OK           0
#define SQLITE_ERROR        1
#define SQLITE_BUSY         5
#define SQLITE_LOCKED       6
#define SQLITE_CORRUPT     11
#define SQLITE_NOTADB      26
#define SQLITE_ROW        100
#define SQLITE_DONE       101

#define SQLITE_INTEGER      1
#define SQLITE_FLOAT        2
#define SQLITE_TEXT         3
#define SQLITE_BLOB         4
#define SQLITE_NULL         5

#define SQLITE_OPEN_READONLY       0x00000001
#define SQLITE_OPEN_READWRITE      0x00000002
#define SQLITE_OPEN_CREATE         0x00000004
#define SQLITE_OPEN_URI            0x00000040
#define SQLITE_OPEN_NOMUTEX        0x00008000
#define SQLITE_OPEN_FULLMUTEX      0x00010000

#define SQLITE_STATIC      ((sqlite3_destructor_type)0)
#define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)

CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_open(const char *filename, sqlite3 **ppDb);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_open_v2(const char *filename, sqlite3 **ppDb, int flags, const char *zVfs);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_close(sqlite3 *db);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_close_v2(sqlite3 *db);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_busy_timeout(sqlite3 *db, int ms);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_changes(sqlite3 *db);
CAK_SQLITE_API sqlite3_int64 CAK_SQLITE_CALL sqlite3_last_insert_rowid(sqlite3 *db);
CAK_SQLITE_API const char *CAK_SQLITE_CALL sqlite3_errmsg(sqlite3 *db);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_errcode(sqlite3 *db);
CAK_SQLITE_API void CAK_SQLITE_CALL sqlite3_progress_handler(sqlite3 *db, int nOps, int (CAK_SQLITE_CALL *xProgress)(void *), void *pArg);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_exec(sqlite3 *db, const char *sql, sqlite3_callback callback, void *arg, char **errmsg);

CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_step(sqlite3_stmt *pStmt);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_reset(sqlite3_stmt *pStmt);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_clear_bindings(sqlite3_stmt *pStmt);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_finalize(sqlite3_stmt *pStmt);

CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_bind_blob(sqlite3_stmt *pStmt, int idx, const void *val, int nBytes, sqlite3_destructor_type destructor);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_bind_double(sqlite3_stmt *pStmt, int idx, double val);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_bind_int(sqlite3_stmt *pStmt, int idx, int val);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_bind_int64(sqlite3_stmt *pStmt, int idx, sqlite3_int64 val);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_bind_null(sqlite3_stmt *pStmt, int idx);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_bind_text(sqlite3_stmt *pStmt, int idx, const char *val, int nBytes, sqlite3_destructor_type destructor);

CAK_SQLITE_API const void *CAK_SQLITE_CALL sqlite3_column_blob(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_column_bytes(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API double CAK_SQLITE_CALL sqlite3_column_double(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_column_int(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API sqlite3_int64 CAK_SQLITE_CALL sqlite3_column_int64(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API const unsigned char *CAK_SQLITE_CALL sqlite3_column_text(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_column_type(sqlite3_stmt *pStmt, int iCol);
CAK_SQLITE_API int CAK_SQLITE_CALL sqlite3_column_count(sqlite3_stmt *pStmt);

#ifdef __cplusplus
}
#endif
