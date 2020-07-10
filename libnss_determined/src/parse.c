#include "libnss_determined.h"

// Read a line from a FILE*.
parse_status_t read_line(FILE *f, char *buf, size_t buflen, size_t *linelen) {
    if (!fgets(buf, (int)buflen, f)) {
        // End of file?
        if (feof(f)) {
            return PARSE_EOF;
        }
        // Unknown failure.
        return PARSE_FAIL;
    }

    *linelen = strnlen(buf, buflen);

    // Did we get a well-formed line?
    if (buf[*linelen - 1] != '\n') {
        // Discard any incomplete lines at the end of the file.
        if (*linelen != buflen - 1) {
            return PARSE_EOF;
        }
        return PARSE_SHORT_BUFFER;
    }

    return PARSE_OK;
}

// Read a field, replace the separator with a '\0' to make it a c-string.
parse_status_t get_field(char *field, char sep, char **nextfield) {
    char *end = strchr(field, sep);
    if (!end) {
        return PARSE_INVALID;
    }
    *end = '\0';
    *nextfield = end + 1;
    return PARSE_OK;
}

parse_status_t read_uint(char *field, unsigned int *uint) {
    size_t fieldlen = strlen(field);
    for (size_t i = 0; i < fieldlen; i++) {
        if (field[i] < '0' || field[i] > '9') {
            return PARSE_INVALID;
        }
    }
    char *endptr;
    int base = 10;
    errno = 0;
    long int result = strtol(field, &endptr, base);
    // Check for conversion errors.
    if (errno) {
        return PARSE_INVALID;
    }
    // Check for extra characters (pointer comparison).
    if (endptr != field + fieldlen) {
        return PARSE_INVALID;
    }
    // Check for valid range.
    if (result > UINT_MAX || result < 0) {
        return PARSE_INVALID;
    }
    *uint = (unsigned int)result;
    return PARSE_OK;
}

parse_status_t read_long(char *field, long int *result) {
    size_t fieldlen = strlen(field);
    // For shadow.h: treat empty fields specially.
    if (fieldlen == 0) {
        *result = -1;
        return PARSE_OK;
    }
    // Only allow 0-9 or '-'.
    for (size_t i = 0; i < fieldlen; i++) {
        if (field[i] != '-' && (field[i] < '0' || field[i] > '9')) {
            return PARSE_INVALID;
        }
    }
    char *endptr;
    int base = 10;
    errno = 0;
    *result = strtol(field, &endptr, base);
    // Check for conversion errors.
    if (errno) {
        return PARSE_INVALID;
    }
    // Check for extra characters (pointer comparison).
    if (endptr != field + fieldlen) {
        return PARSE_INVALID;
    }
    return PARSE_OK;
}

parse_status_t read_ulong(char *field, unsigned long int *result) {
    size_t fieldlen = strlen(field);
    // For shadow.h: treat empty fields specially.
    if (fieldlen == 0) {
        *result = (unsigned long int)-1;
        return PARSE_OK;
    }
    // Only allow 0-9.
    for (size_t i = 0; i < fieldlen; i++) {
        if (field[i] < '0' || field[i] > '9') {
            return PARSE_INVALID;
        }
    }
    char *endptr;
    int base = 10;
    errno = 0;
    *result = strtoul(field, &endptr, base);
    // Check for conversion errors.
    if (errno) {
        return PARSE_INVALID;
    }
    // Check for extra characters (pointer comparison).
    if (endptr != field + fieldlen) {
        return PARSE_INVALID;
    }
    return PARSE_OK;
}

#define READ_STR(sep, output)                  \
    do {                                       \
        status = get_field(field, sep, &next); \
        if (status) return status;             \
        output = field;                        \
        field = next;                          \
    } while (0)

#define READ_UINT(sep, output)                 \
    do {                                       \
        status = get_field(field, sep, &next); \
        if (status) return status;             \
        status = read_uint(field, output);     \
        if (status) return status;             \
        field = next;                          \
    } while (0)

#define READ_LONG(sep, output)                 \
    do {                                       \
        status = get_field(field, sep, &next); \
        if (status) return status;             \
        status = read_long(field, output);     \
        if (status) return status;             \
        field = next;                          \
    } while (0)

#define READ_ULONG(sep, output)                \
    do {                                       \
        status = get_field(field, sep, &next); \
        if (status) return status;             \
        status = read_ulong(field, output);    \
        if (status) return status;             \
        field = next;                          \
    } while (0)

#define ASSERT_FINAL_FIELD(sep)                            \
    do {                                                   \
        status = get_field(field, ':', &next);             \
        if (status != PARSE_INVALID) return PARSE_INVALID; \
    } while (0)

parse_status_t parse_pwd_line(char *line, size_t linelen, size_t buflen,
                              void *result_any) {
    struct passwd *result = result_any;
    (void)linelen;
    (void)buflen;

    /* field list of struct passwd (from pwd.h)
        char *pw_name;   // Username
        char *pw_passwd; // Hashed passphrase (deprecated)
        uid_t pw_uid;    // User ID
        gid_t pw_gid;    // Group ID
        char *pw_gecos;  // Real name
        char *pw_dir;    // Home directory
        char *pw_shell;  // Shell program
    */
    char *field = line;
    char *next;
    parse_status_t status;

    READ_STR(':', result->pw_name);
    READ_STR(':', result->pw_passwd);
    READ_UINT(':', &result->pw_uid);
    READ_UINT(':', &result->pw_gid);
    READ_STR(':', result->pw_gecos);
    READ_STR(':', result->pw_dir);
    ASSERT_FINAL_FIELD(':');
    READ_STR('\n', result->pw_shell);

    return PARSE_OK;
}

parse_status_t parse_shadow_line(char *line, size_t linelen, size_t buflen,
                                 void *result_any) {
    struct spwd *result = result_any;
    (void)linelen;
    (void)buflen;

    /* field list of struct spwd (from shadow.h)
        char *sp_namp;             // Login name
        char *sp_pwdp;             // Hashed passphrase
        long int sp_lstchg;        // Date of last change
        long int sp_min;           // Min days between changes
        long int sp_max;           // Max days between changes
        long int sp_warn;          // Days until warn user to change password
        long int sp_inact;         // Days until the account goes inactive
        long int sp_expire;        // Days since 1970-01-01 until expires
        unsigned long int sp_flag; // Reserved
    */
    char *field = line;
    char *next;
    parse_status_t status;

    READ_STR(':', result->sp_namp);
    READ_STR(':', result->sp_pwdp);
    READ_LONG(':', &result->sp_lstchg);
    READ_LONG(':', &result->sp_min);
    READ_LONG(':', &result->sp_max);
    READ_LONG(':', &result->sp_warn);
    READ_LONG(':', &result->sp_inact);
    READ_LONG(':', &result->sp_expire);
    ASSERT_FINAL_FIELD(':');
    READ_ULONG('\n', &result->sp_flag);

    return PARSE_OK;
}

parse_status_t parse_group_line(char *line, size_t linelen, size_t buflen,
                                void *result_any) {
    struct group *result = result_any;

    /* field list of struct group (from group.h)
        char *gr_name;   // Group name
        char *gr_passwd; // Password
        gid_t gr_gid;    // Group ID
        char **gr_mem;   // Member list
    */
    char *field = line;
    char *next;
    parse_status_t status;

    READ_STR(':', result->gr_name);
    READ_STR(':', result->gr_passwd);
    READ_UINT(':', &result->gr_gid);
    ASSERT_FINAL_FIELD(':');

    /* figure out how much space there is for the group member list, which
       gets embedded directly into the char* buf that the user provides */
    if (buflen < linelen + 1) {
        // This should never happen, but avoid underflow anyway.
        return PARSE_SHORT_BUFFER;
    }
    size_t leftover = buflen - (linelen + 1);
    size_t nmem_max = leftover / sizeof(*result->gr_mem);
    result->gr_mem = (char **)(line + linelen + 1);

    // Gr_mem must have space to be NULL-terminated.
    if (nmem_max < 1) {
        return PARSE_SHORT_BUFFER;
    }

    // Group membership, a comma-separated list.
    size_t nmem = 0;
    bool last = false;
    while (!last) {
        // Try to read a comma-separated field.
        status = get_field(field, ',', &next);
        if (status == PARSE_INVALID) {
            // Try again, this time looking for the end of the list.
            last = true;
            status = get_field(field, '\n', &next);
        }
        if (status) return status;

        if (field[0] != '\0') {
            if (nmem == nmem_max) return PARSE_SHORT_BUFFER;
            result->gr_mem[nmem++] = field;
        }

        field = next;
    }

    // NULL-terminate the list.
    if (nmem == nmem_max) return PARSE_SHORT_BUFFER;
    result->gr_mem[nmem++] = NULL;

    return PARSE_OK;
}

/* Generic logic for reading a file line-by-line, parsing each line according
   to a parse_line_fn, and returning the next valid result. */
parse_status_t fgetent_any(FILE *f, parse_line_fn parse_line, void *result_any,
                           char *buf, size_t buflen) {
    parse_status_t status;

    while (true) {
        // Record where we are in the stream.
        long start = ftell(f);

        // Read the next line in the file.
        size_t linelen;
        status = read_line(f, buf, buflen, &linelen);
        if (status == PARSE_SHORT_BUFFER) {
            DEBUG("short buffer after read_line");
            if (fseek(f, start, SEEK_SET)) {
                // Unknown failure.
                return PARSE_FAIL;
            }
        } else if (status) {
            return status;
        }

        // Parse the line using the parse_line function pointer.
        status = parse_line(buf, linelen, buflen, result_any);
        if (status == PARSE_SHORT_BUFFER) {
            DEBUG("short buffer after parse_line");
            // We'll try again from the same point in the file.
            if (fseek(f, start, SEEK_SET)) {
                // Unknown failure.
                return PARSE_FAIL;
            }
            return PARSE_SHORT_BUFFER;
        } else if (status == PARSE_INVALID) {
            DEBUG("skipping invalid line");
            continue;
        } else if (status) {
            return status;
        }

        break;
    }
    return PARSE_OK;
}
