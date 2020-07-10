#include "libnss_determined.h"

/*
group database functions for listing groups:

    These are called to list groups in the database:
        _nss_determined_setgrent
        _nss_determined_getgrent_r
        _nss_determined_endgrent

    This is called to look up a group by name:
        _nss_determined_getgrnam_r

    This is called to look up a group by uid:
        _nss_determined_getgrgid_r
*/

FILE *g_group_f = NULL;

static void clear_group_result(void *result_any, char *buf, size_t buflen) {
    struct group *result = result_any;
    *result = (struct group){0};
    memset(buf, 0, buflen);
}

static db_iface_t group_db = {
    .parse_line = parse_group_line,
    .clear_result = clear_group_result,
};

enum nss_status _nss_determined_setgrent(int stayopen) {
    DEBUG("called, stayopen=%d", stayopen);

    det_nss_status_t det_nss_status = det_fopen(GROUPFILE, &g_group_f);

    return set_errnop_and_return_nss_status(det_nss_status, &errno);
}

enum nss_status _nss_determined_getgrent_r(struct group *result, char *buf,
                                           size_t buflen, int *errnop) {
    DEBUG("called");

    det_nss_status_t det_nss_status = getent_any(
        GROUPFILE, &g_group_f, &group_db, (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}

enum nss_status _nss_determined_endgrent(void) {
    DEBUG("called");
    if (g_group_f) fclose(g_group_f);
    return NSS_STATUS_SUCCESS;
}

bool group_match_name(void *id, void *result_any) {
    char *name = id;
    struct group *result = result_any;
    return strcmp(name, result->gr_name) == 0;
}

enum nss_status _nss_determined_getgrnam_r(const char *name,
                                           struct group *result, char *buf,
                                           size_t buflen, int *errnop) {
    DEBUG("called, name=%s", name);

    det_nss_status_t det_nss_status =
        searchent_any(GROUPFILE, &group_db, group_match_name, (void *)name,
                      (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}

bool group_match_gid(void *id, void *result_any) {
    unsigned int *gid = id;
    struct group *result = result_any;
    return *gid == result->gr_gid;
}

enum nss_status _nss_determined_getgrgid_r(gid_t gid, struct group *result,
                                           char *buf, size_t buflen,
                                           int *errnop) {
    DEBUG("called, gid=%u", gid);

    det_nss_status_t det_nss_status =
        searchent_any(GROUPFILE, &group_db, group_match_gid, (void *)&gid,
                      (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}
