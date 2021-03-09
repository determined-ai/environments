#include "libnss_determined.h"

bool debug_mode = false;
bool debug_mode_checked = false;

enum nss_status set_errnop_and_return_nss_status(
    det_nss_status_t det_nss_status, int *errnop) {
    switch (det_nss_status) {
        case DET_NSS_STATUS_OK:
            // The docs say: "An NSS module should never set *errnop to zero".
            return NSS_STATUS_SUCCESS;

        case DET_NSS_STATUS_SHORT_BUFFER:
            *errnop = ERANGE;
            return NSS_STATUS_TRYAGAIN;

        case DET_NSS_STATUS_MISSING_FILE:
            *errnop = ENOENT;
            return NSS_STATUS_UNAVAIL;

        case DET_NSS_STATUS_END_OF_ENTRIES:
            /* Presumably, since this is a very specific error condition, the
               docs which say to never set *errnop to zero do not apply. */
            *errnop = 0;
            return NSS_STATUS_NOTFOUND;

        case DET_NSS_STATUS_ENTRY_NOT_FOUND:
            *errnop = ENOENT;
            return NSS_STATUS_NOTFOUND;

        case DET_NSS_STATUS_FAIL:
        default:
            *errnop = EAGAIN;
            return NSS_STATUS_TRYAGAIN;
    }
}

det_nss_status_t det_fopen(char *filename, FILE **f) {
    *f = fopen(filename, "r");
    if (!*f) {
        if (errno == ENOENT) {
            DEBUG("missing file");
            return DET_NSS_STATUS_MISSING_FILE;
        }
        DEBUG("unknown failure");
        return DET_NSS_STATUS_FAIL;
    }
    DEBUG("OK");
    return DET_NSS_STATUS_OK;
}

det_nss_status_t getent_any(char *filename, FILE **f, db_iface_t *db_iface,
                            void *result_any, char *buf, size_t buflen) {
    det_nss_status_t det_nss_status = DET_NSS_STATUS_OK;

    /* The docs indicate that setent might not have been called:

          "When the service was not formerly initialized by a call to
          _nss_DATABASE_setdbent all return values allowed for this function
          can also be returned here."

       So we detect that case and call fopen here instead.

       gnu.org/software/libc/manual/html_node/NSS-Module-Function-Internals.html
    */
    if (!*f) {
        det_nss_status = det_fopen(filename, f);
        if (det_nss_status) {
            goto done;
        }
    }

    parse_status_t parse;
    parse = fgetent_any(*f, db_iface->parse_line, result_any, buf, buflen);
    switch (parse) {
        case PARSE_OK:
            goto done;

        case PARSE_SHORT_BUFFER:
            det_nss_status = DET_NSS_STATUS_SHORT_BUFFER;
            goto done;

        case PARSE_EOF:
            det_nss_status = DET_NSS_STATUS_END_OF_ENTRIES;
            goto done;

        case PARSE_INVALID:
        case PARSE_FAIL:
            break;
    }
    det_nss_status = DET_NSS_STATUS_FAIL;

done:
    if (det_nss_status) {
        db_iface->clear_result(result_any, buf, buflen);
    }
    return det_nss_status;
}

det_nss_status_t searchent_any(char *filename, db_iface_t *db_iface,
                               match_fn match, void *id, void *result_any,
                               char *buf, size_t buflen) {
    FILE *f = NULL;
    det_nss_status_t det_nss_status = det_fopen(filename, &f);
    if (det_nss_status) {
        return det_nss_status;
    }

    while (true) {
        parse_status_t parse;
        parse = fgetent_any(f, db_iface->parse_line, result_any, buf, buflen);
        switch (parse) {
            case PARSE_OK:
                // Is this the right entry?
                if (match(id, result_any)) {
                    det_nss_status = DET_NSS_STATUS_OK;
                    goto done;
                }
                break;

            case PARSE_SHORT_BUFFER:
                det_nss_status = DET_NSS_STATUS_SHORT_BUFFER;
                goto done;

            case PARSE_EOF:
                det_nss_status = DET_NSS_STATUS_ENTRY_NOT_FOUND;
                goto done;

            case PARSE_INVALID:
            case PARSE_FAIL:
            default:
                det_nss_status = DET_NSS_STATUS_FAIL;
                goto done;
        }
    }

done:
    if (f) {
        fclose(f);
    }
    if (det_nss_status) {
        db_iface->clear_result(result_any, buf, buflen);
    }
    return det_nss_status;
}
