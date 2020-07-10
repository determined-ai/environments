#include "libnss_determined.h"

/*
shadow database functions for listing hashes of passwords:

    These are called to list passwords in the database:
        _nss_determined_setspent
        _nss_determined_getspent_r
        _nss_determined_endspent

    This is called to look up a password by username:
        _nss_determined_getspnam_r
*/

FILE *g_shadow_f = NULL;

static void clear_shadow_result(void *result_any, char *buf, size_t buflen) {
    struct spwd *result = result_any;
    *result = (struct spwd){0};
    memset(buf, 0, buflen);
}

static db_iface_t shadow_db = {
    .parse_line = parse_shadow_line,
    .clear_result = clear_shadow_result,
};

enum nss_status _nss_determined_setspent(int stayopen) {
    DEBUG("called, stayopen=%d", stayopen);

    det_nss_status_t det_nss_status = det_fopen(SHADOWFILE, &g_shadow_f);

    return set_errnop_and_return_nss_status(det_nss_status, &errno);
}

enum nss_status _nss_determined_getspent_r(struct spwd *result, char *buf,
                                           size_t buflen, int *errnop) {
    DEBUG("called");

    det_nss_status_t det_nss_status = getent_any(
        SHADOWFILE, &g_shadow_f, &shadow_db, (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}

enum nss_status _nss_determined_endspent(void) {
    DEBUG("called");
    if (g_shadow_f) fclose(g_shadow_f);
    return NSS_STATUS_SUCCESS;
}

bool shadow_match_name(void *id, void *result_any) {
    char *name = id;
    struct spwd *result = result_any;
    return strcmp(name, result->sp_namp) == 0;
}

enum nss_status _nss_determined_getspnam_r(const char *name,
                                           struct spwd *result, char *buf,
                                           size_t buflen, int *errnop) {
    DEBUG("called, name=%s", name);

    det_nss_status_t det_nss_status =
        searchent_any(SHADOWFILE, &shadow_db, shadow_match_name, (void *)name,
                      (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}
