#include <libnss_determined.h>

static char *parse_status_names[] = {
    "PARSE_OK",      "PARSE_SHORT_BUFFER", "PARSE_EOF",
    "PARSE_INVALID", "PARSE_FAIL",
};

#define EXPECT_STATUS(got, exp)                                            \
    do {                                                                   \
        if (got != exp) {                                                  \
            fprintf(stderr, "%s():%d: got %s but expected %s\n", __func__, \
                    __LINE__, parse_status_names[got],                     \
                    parse_status_names[exp]);                              \
            return 1;                                                      \
        }                                                                  \
    } while (0)

#define EXPECT_STRING(got, exp)                                          \
    do {                                                                 \
        if (strncmp(got, exp, strlen(exp) + 1) != 0) {                   \
            fprintf(stderr, "%s():%d: got \"%s\" but expected \"%s\"\n", \
                    __func__, __LINE__, got, exp);                       \
            return 1;                                                    \
        }                                                                \
    } while (0)

#define EXPECT_NULL_STRING(got)                                        \
    do {                                                               \
        if (got != NULL) {                                             \
            fprintf(stderr, "%s():%d: got \"%s\" but expected NULL\n", \
                    __func__, __LINE__, got);                          \
            return 1;                                                  \
        }                                                              \
    } while (0)

#define EXPECT_UINT(got, exp)                                              \
    do {                                                                   \
        if (got != exp) {                                                  \
            fprintf(stderr, "%s():%d: got %u but expected %u\n", __func__, \
                    __LINE__, got, exp);                                   \
            return 1;                                                      \
        }                                                                  \
    } while (0)

#define EXPECT_LONG(got, exp)                                                \
    do {                                                                     \
        if (got != exp) {                                                    \
            fprintf(stderr, "%s():%d: got %ld but expected %ld\n", __func__, \
                    __LINE__, got, exp);                                     \
            return 1;                                                        \
        }                                                                    \
    } while (0)

#define EXPECT_ULONG(got, exp)                                               \
    do {                                                                     \
        if (got != exp) {                                                    \
            fprintf(stderr, "%s():%d: got %lu but expected %lu\n", __func__, \
                    __LINE__, got, exp);                                     \
            return 1;                                                        \
        }                                                                    \
    } while (0)

int test_get_field(void) {
    parse_status_t status;
    char line[] = "a:sdf::  :zxcv\n";
    char *field = line;
    char *next;

    status = get_field(field, ':', &next);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(field, "a");
    field = next;

    status = get_field(field, ':', &next);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(field, "sdf");
    field = next;

    status = get_field(field, ':', &next);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(field, "");
    field = next;

    status = get_field(field, ':', &next);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(field, "  ");
    field = next;

    // Fail if you expect too many ':' separators.
    status = get_field(field, ':', &next);
    EXPECT_STATUS(status, PARSE_INVALID);

    status = get_field(field, '\n', &next);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(field, "zxcv");
    field = next;

    // Fail on an empty string
    status = get_field(field, ':', &next);
    EXPECT_STATUS(status, PARSE_INVALID);

    return 0;
}

int test_read_uint(void) {
    parse_status_t status;
    char *field;
    unsigned int result;

    field = "0";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_UINT(result, 0);

    field = "";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_UINT(result, 0);

    field = "12345";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_UINT(result, 12345);

    field = "12345 ";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "12.345";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "-12345";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = " ";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "99999999999999999999";
    status = read_uint(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    return 0;
}

int test_read_long(void) {
    parse_status_t status;
    char *field;
    long int result;

    field = "0";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, 0L);

    // For shadow.h: empty fields become -1.
    field = "";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, -1L);

    field = "12345";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, 12345L);

    field = "-12345";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, -12345L);

    field = "12345 ";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "12.345";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = " ";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "99999999999999999999";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "-99999999999999999999";
    status = read_long(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    return 0;
}

int test_read_ulong(void) {
    parse_status_t status;
    char *field;
    unsigned long int result;

    field = "0";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, 0UL);

    // For shadow.h: empty fields become -1.
    field = "";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, -1UL);

    field = "12345";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_LONG(result, 12345UL);

    field = "12345 ";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "12.345";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "-12345";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = " ";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    field = "99999999999999999999";
    status = read_ulong(field, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    return 0;
}

int test_parse_pwd_line(void) {
    parse_status_t status;
    struct passwd result;
    char line[100];

    strncpy(line, "root:x:0:0::/root:/bin/bash\n", sizeof(line));
    status = parse_pwd_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.pw_name, "root");
    EXPECT_STRING(result.pw_passwd, "x");
    EXPECT_UINT(result.pw_uid, 0);
    EXPECT_UINT(result.pw_gid, 0);
    EXPECT_STRING(result.pw_gecos, "");
    EXPECT_STRING(result.pw_dir, "/root");
    EXPECT_STRING(result.pw_shell, "/bin/bash");

    // Reject extra fields.
    strncpy(line, "root:x:0:0::/root:/bin/bash:\n", sizeof(line));
    status = parse_pwd_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    // Reject malformed lines.
    strncpy(line, "root:x:0:0::/root:/bin/bash", sizeof(line));
    status = parse_pwd_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    strncpy(line, "root:x:0:0::/root", sizeof(line));
    status = parse_pwd_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    // No segfault on empty strings.
    strncpy(line, "", sizeof(line));
    status = parse_pwd_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    return 0;
}

int test_parse_shadow_line(void) {
    parse_status_t status;
    struct spwd result;
    char line[100];

    strncpy(line, "user:THE_HASH:18035:0:99999:7:::\n", sizeof(line));
    status = parse_shadow_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.sp_namp, "user");
    EXPECT_STRING(result.sp_pwdp, "THE_HASH");
    EXPECT_LONG(result.sp_lstchg, 18035L);
    EXPECT_LONG(result.sp_min, 0L);
    EXPECT_LONG(result.sp_max, 99999L);
    EXPECT_LONG(result.sp_warn, 7L);
    EXPECT_LONG(result.sp_inact, -1L);
    EXPECT_LONG(result.sp_expire, -1L);
    EXPECT_ULONG(result.sp_flag, -1UL);

    // Reject extra fields.
    strncpy(line, "user:THE_HASH:18035:0:99999:7::::\n", sizeof(line));
    status = parse_shadow_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    // Reject malformed lines.
    strncpy(line, "user:THE_HASH:18035:0:99999:7::\n", sizeof(line));
    status = parse_shadow_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    strncpy(line, "user:THE_HASH:18035:0:99999:7:::", sizeof(line));
    status = parse_shadow_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    // No segfault on empty strings.
    strncpy(line, "", sizeof(line));
    status = parse_shadow_line(line, strlen(line), strlen(line) + 1, &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    return 0;
}

int test_parse_group_line(void) {
    parse_status_t status;
    struct group result;
    char line[100];

    strncpy(line, "sudo:x:1:a,b,c\n", sizeof(line));
    status = parse_group_line(line, strlen(line), sizeof(line), &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.gr_name, "sudo");
    EXPECT_STRING(result.gr_passwd, "x");
    EXPECT_STRING(result.gr_mem[0], "a");
    EXPECT_STRING(result.gr_mem[1], "b");
    EXPECT_STRING(result.gr_mem[2], "c");
    EXPECT_NULL_STRING(result.gr_mem[3]);

    // Empty membership list.
    strncpy(line, "sudo:x:1:\n", sizeof(line));
    status = parse_group_line(line, strlen(line), sizeof(line), &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.gr_name, "sudo");
    EXPECT_STRING(result.gr_passwd, "x");
    EXPECT_NULL_STRING(result.gr_mem[0]);

    // No commas in membership list.
    strncpy(line, "sudo:x:1:a\n", sizeof(line));
    status = parse_group_line(line, strlen(line), sizeof(line), &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.gr_name, "sudo");
    EXPECT_STRING(result.gr_passwd, "x");
    EXPECT_STRING(result.gr_mem[0], "a");
    EXPECT_NULL_STRING(result.gr_mem[1]);

    // No segfault on empty strings.
    strncpy(line, "", sizeof(line));
    status = parse_group_line(line, strlen(line), sizeof(line), &result);
    EXPECT_STATUS(status, PARSE_INVALID);

    // Buffer too short.
    strncpy(line, "sudo:x:1:\n", sizeof(line));
    status = parse_group_line(line, strlen(line),
                              (strlen(line) + 1) + sizeof(*result.gr_mem) - 1,
                              &result);
    EXPECT_STATUS(status, PARSE_SHORT_BUFFER);

    strncpy(line, "sudo:x:1:a\n", sizeof(line));
    status = parse_group_line(
        line, strlen(line), (strlen(line) + 1) + 2 * sizeof(*result.gr_mem) - 1,
        &result);
    EXPECT_STATUS(status, PARSE_SHORT_BUFFER);

    // Buffer just long enough.
    strncpy(line, "sudo:x:1:a\n", sizeof(line));
    status = parse_group_line(
        line, strlen(line), (strlen(line) + 1) + 2 * sizeof(*result.gr_mem) - 1,
        &result);
    EXPECT_STATUS(status, PARSE_SHORT_BUFFER);

    // Buffer just long enough.
    strncpy(line, "sudo:x:1:a\n", sizeof(line));
    status = parse_group_line(line, strlen(line),
                              (strlen(line) + 1) + 2 * sizeof(*result.gr_mem),
                              &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.gr_name, "sudo");
    EXPECT_STRING(result.gr_passwd, "x");
    EXPECT_STRING(result.gr_mem[0], "a");
    EXPECT_NULL_STRING(result.gr_mem[1]);

    // Ignore empty entries in membership list.
    strncpy(line, "sudo:x:1:a,,\n", sizeof(line));
    status = parse_group_line(line, strlen(line),
                              (strlen(line) + 1) + 2 * sizeof(*result.gr_mem),
                              &result);
    EXPECT_STATUS(status, PARSE_OK);
    EXPECT_STRING(result.gr_name, "sudo");
    EXPECT_STRING(result.gr_passwd, "x");
    EXPECT_STRING(result.gr_mem[0], "a");
    EXPECT_NULL_STRING(result.gr_mem[1]);

    return 0;
}

#define RUN_TEST(name)                            \
    do {                                          \
        if (name()) {                             \
            fprintf(stderr, #name "() failed\n"); \
            failed = true;                        \
        }                                         \
    } while (0)

int main() {
    bool failed = false;

    RUN_TEST(test_get_field);
    RUN_TEST(test_read_uint);
    RUN_TEST(test_read_long);
    RUN_TEST(test_read_ulong);
    RUN_TEST(test_parse_pwd_line);
    RUN_TEST(test_parse_shadow_line);
    RUN_TEST(test_parse_group_line);

    if (!failed) {
        printf("PASS\n");
    }

    return (int)failed;
}
