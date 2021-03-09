#ifndef LIBNSS_DETERMINED_H
#define LIBNSS_DETERMINED_H

#include <errno.h>
#include <grp.h>
#include <limits.h>
#include <nss.h>
#include <pwd.h>
#include <shadow.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef PASSWDFILE
#define PASSWDFILE "/run/determined/etc/passwd"
#endif

#ifndef SHADOWFILE
#define SHADOWFILE "/run/determined/etc/shadow"
#endif

#ifndef GROUPFILE
#define GROUPFILE "/run/determined/etc/group"
#endif

// We only debug if LIBNSS_DETERMINED_DEBUG is true.
extern bool debug_mode;
extern bool debug_mode_checked;

/* DEBUG is like fprintf(stderr, ...), except each line is preceeded with the
   function name and line number of where it was called. */
#define DEBUG(msg, ...)                                                       \
    do {                                                                      \
        if (!debug_mode_checked) {                                            \
            debug_mode = (getenv("LIBNSS_DETERMINED_DEBUG") != NULL);         \
            debug_mode_checked = true;                                        \
        }                                                                     \
        if (debug_mode) {                                                     \
            fprintf(stderr, "libnss_determined:%s():%d: " msg "\n", __func__, \
                    __LINE__, ##__VA_ARGS__);                                 \
        }                                                                     \
    } while (0)

/* Custom parsing code is only necessary to be immune to LC_* issues, otherwise
   we would just call libc functions for fgetpwent, fgetspent, and fgetgrent */

typedef enum {
    PARSE_OK = 0,
    PARSE_SHORT_BUFFER,
    PARSE_EOF,
    PARSE_INVALID,
    PARSE_FAIL,
} parse_status_t;

parse_status_t read_line(FILE *f, char *buf, size_t buflen, size_t *linelen);
parse_status_t get_field(char *field, char sep, char **nextfield);
parse_status_t read_uint(char *field, unsigned int *uint);
parse_status_t read_long(char *field, long int *result);
parse_status_t read_ulong(char *field, unsigned long int *result);

/* A parse_line_fn takes a line of known linelen, backed by a buffer of buflen,
   and fills in the appropriate struct (such as a struct passwd) by parsing the
   line. */
typedef parse_status_t (*parse_line_fn)(char *line, size_t linelen,
                                        size_t buflen, void *result_any);

parse_status_t parse_pwd_line(char *line, size_t linelen, size_t buflen,
                              void *result_any);

parse_status_t parse_shadow_line(char *line, size_t linelen, size_t buflen,
                                 void *result_any);

parse_status_t parse_group_line(char *line, size_t linelen, size_t buflen,
                                void *result_any);

/* fgetent_any behaves like fgetpwent, fgetgrent, or fgetspent for reading the
   next valid line found in a FILE*, only it is more resilient to misconfigured
   LC_* environment variables. */
parse_status_t fgetent_any(FILE *f, parse_line_fn parse_line, void *result_any,
                           char *buf, size_t buflen);

/* Table of return values and *errnop settings for NSS plugin calls:
   (https://gnu.org/software/libc/manual/html_node/NSS-Modules-Interface.html)

    return val              errno       meaning
-------------------------------------------------------------------------------

    NSS_STATUS_OK           SUCCESS     The operation was successful.

    NSS_STATUS_TRYAGAIN     ERANGE      The provided buffer is not large
                                        enough.  The function should be called
                                        again with a larger buffer.

    NSS_STATUS_UNAVAIL      ENOENT      A necessary input file cannot be found.

    NSS_STATUS_NOTFOUND     SUCCESS     There are no entries. Use this to avoid
                                        returning errors for inactive services
                                        which may be enabled at a later time.
                                        This is not the same as the service
                                        being temporarily unavailable. This is
                                        also how you indicate in get*ent_r that
                                        there are no more entries to list.

    NSS_STATUS_NOTFOUND     ENOENT      The requested entry is not available.

    NSS_STATUS_TRYAGAIN     EAGAIN      One of the functions used ran
                                        temporarily out of resources or a
                                        service is currently not available.

   This is pretty confusing, so we abstract it away by returning
   det_nss_staus_t and translating it to an (errno, nss_status) pair as part
   of the set_errnop_and_return_nss_status() call.
*/

typedef enum {
    DET_NSS_STATUS_OK = 0,
    // The provided buffer is not long enough.
    DET_NSS_STATUS_SHORT_BUFFER,
    // The plugin can't find a necessary input value.
    DET_NSS_STATUS_MISSING_FILE,
    // There are no more entries to list in the database.
    DET_NSS_STATUS_END_OF_ENTRIES,
    // The requested entry is not in the database (after e.g. a name lookup).
    DET_NSS_STATUS_ENTRY_NOT_FOUND,
    // Any other failure.
    DET_NSS_STATUS_FAIL,
} det_nss_status_t;

enum nss_status set_errnop_and_return_nss_status(
    det_nss_status_t det_nss_status, int *errnop);

// det_fopen wraps fopen with return values that are specific to NSS plugins.
det_nss_status_t det_fopen(char *filename, FILE **f);

/* db_iface_t is a collection of function pointers that define the behavior
   of a specific database, such as the passwd, shadow, or group databases. */
typedef struct {
    parse_line_fn parse_line;
    void (*clear_result)(void *result_any, char *buf, size_t buflen);
} db_iface_t;

/* getent_any is the engine behind getpwent, getspent, and getgrent to iterate
   through each database. */
det_nss_status_t getent_any(char *filename, FILE **f, db_iface_t *db_iface,
                            void *result_any, char *buf, size_t buflen);

// A match_fn checks if an entry matches the identifer the caller requested.
typedef bool (*match_fn)(void *id, void *result_any);

/* searchent_any is the engine behind getpwnam, getpwuid, getspnam, getgrnam,
   and getgrgid for looking up particular entries in each database */
det_nss_status_t searchent_any(char *filename, db_iface_t *db_iface,
                               match_fn match, void *id, void *result_any,
                               char *buf, size_t buflen);

#endif  // LIBNSS_DETERMINED_H
