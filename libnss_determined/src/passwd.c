#include "libnss_determined.h"

/*
passwd database functions for listing users:

    These are called to list users in the database:
        _nss_determined_setpwent
        _nss_determined_getpwent_r
        _nss_determined_endpwent

    This is called to look up a user by name:
        _nss_determined_getpwnam_r

    This is called to look up a user by uid:
        _nss_determined_getpwuid_r
*/

FILE *g_passwd_f = NULL;

static void clear_pwd_result(void *result_any, char *buf, size_t buflen) {
    struct passwd *result = result_any;
    *result = (struct passwd){0};
    memset(buf, 0, buflen);
}

static db_iface_t pwd_db = {
    .parse_line = parse_pwd_line,
    .clear_result = clear_pwd_result,
};

enum nss_status _nss_determined_setpwent(int stayopen) {
    DEBUG("called, stayopen=%d", stayopen);

    det_nss_status_t det_nss_status = det_fopen(PASSWDFILE, &g_passwd_f);

    return set_errnop_and_return_nss_status(det_nss_status, &errno);
}

enum nss_status _nss_determined_getpwent_r(struct passwd *result, char *buf,
                                           size_t buflen, int *errnop) {
    DEBUG("called");

    det_nss_status_t det_nss_status = getent_any(
        PASSWDFILE, &g_passwd_f, &pwd_db, (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}

enum nss_status _nss_determined_endpwent(void) {
    DEBUG("called");
    if (g_passwd_f) fclose(g_passwd_f);
    return NSS_STATUS_SUCCESS;
}

bool pwd_match_name(void *id, void *result_any) {
    char *name = id;
    struct passwd *result = result_any;
    return strcmp(name, result->pw_name) == 0;
}

enum nss_status _nss_determined_getpwnam_r(const char *name,
                                           struct passwd *result, char *buf,
                                           size_t buflen, int *errnop) {
    DEBUG("called, name=%s", name);

    det_nss_status_t det_nss_status =
        searchent_any(PASSWDFILE, &pwd_db, pwd_match_name, (void *)name,
                      (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}

bool pwd_match_uid(void *id, void *result_any) {
    unsigned int *uid = id;
    struct passwd *result = result_any;
    return *uid == result->pw_uid;
}

enum nss_status _nss_determined_getpwuid_r(uid_t uid, struct passwd *result,
                                           char *buf, size_t buflen,
                                           int *errnop) {
    DEBUG("called, uid=%u", uid);

    det_nss_status_t det_nss_status =
        searchent_any(PASSWDFILE, &pwd_db, pwd_match_uid, (void *)&uid,
                      (void *)result, buf, buflen);

    return set_errnop_and_return_nss_status(det_nss_status, errnop);
}
