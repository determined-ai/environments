#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>
#include <errno.h>
#include <string.h>
#include <pwd.h>
#include <grp.h>
#include <shadow.h>
#include <nss.h>


#define AGENT_USER_GROUP_FILE "/run/determined/agent_user_group"

// we only debug if LIBNSS_DETERMINED_DEBUG is true
static bool debug_mode = false;
static bool debug_mode_check = false;

#define DEBUG(msg, ...) \
    do { \
        if(!debug_mode_check){ \
            debug_mode = (getenv("LIBNSS_DETERMINED_DEBUG") != NULL); \
            debug_mode_check = true; \
        } \
        if(debug_mode){ \
            fprintf(stderr, "libnss_determined:%s():%d: " msg, \
                    __func__, __LINE__, ##__VA_ARGS__); \
        } \
    } while(0)


typedef struct {
    // The contents of the file we are going to read.
    char filebuf[4096];
    size_t filelen;
    // The parsed contents of the file.
    char *user;
    unsigned int uid;
    char *group;
    unsigned int gid;
    // A pointer to the errno that glibc will return to the user.
    int *errnop;
    enum nss_status status;
} vars_t;


// Read a field, replace the separator with a '\0' to make it a c-string.
// Return non-zero on failure.
int get_field(char *field, char sep, size_t *fieldlen, char **nextfield){
    for(size_t i = 0; field[i] != '\0'; i++){
        if(field[i] == sep){
            field[i] = '\0';
            *fieldlen = i;
            *nextfield = &field[i] + 1;
            return 0;
        }
    }
    return 1;
};


// Return non-zero on failure.
int read_uint(char *field, size_t fieldlen, unsigned int *uint){
    for(size_t i = 0; i < fieldlen; i++){
        if(field[i] < '0' || field[i] > '9'){
            return 1;
        }
    }
    char *endptr;
    int base = 10;
    errno = 0;
    long int result = strtol(field, &endptr, base);
    // Check for conversion errors.
    if(errno){
    }
    // Check for extra characters (pointer comparison).
    if(endptr != field + fieldlen){
        return 1;
    }
    // Check for valid range.
    if(result > UINT_MAX || result < 0){
        return 1;
    }
    *uint = (unsigned int)result;
    return 0;
}


// Return non-zero on failure.
int read_file(char *path, vars_t *vars){
    FILE *f = fopen(path, "r");
    if(!f){
        if(errno == ENOENT){
            DEBUG("fopen ENOENT\n");
            *(vars->errnop) = ENOENT;
            vars->status = NSS_STATUS_UNAVAIL;
            return 1;
        }
        DEBUG("fopen EAGAIN\n");
        *(vars->errnop) = EAGAIN;
        vars->status = NSS_STATUS_TRYAGAIN;
        return 1;
    }

    size_t amnt_read = fread(
        vars->filebuf, sizeof(*(vars->filebuf)), sizeof(vars->filebuf) - 1, f
    );

    if(ferror(f)){
        *(vars->errnop) = EAGAIN;
        vars->status = NSS_STATUS_TRYAGAIN;
    }else if(!feof(f)){
        // We failed to read the whole file.
        *(vars->errnop) = ERANGE;
        vars->status = NSS_STATUS_TRYAGAIN;
    }else{
        vars->filelen = amnt_read;
        // NULL terminate.
        vars->filebuf[amnt_read] = '\0';
        vars->status = NSS_STATUS_SUCCESS;
    }

    fclose(f);

    return vars->status != NSS_STATUS_SUCCESS;
}


int parse_file(vars_t *vars){
    char *field = vars->filebuf;
    size_t fieldlen;
    char *next;

    // user
    if(get_field(field, ':', &fieldlen, &next)) return 1;
    vars->user = field;
    field = next;

    // uid
    if(get_field(field, ':', &fieldlen, &next)) return 1;
    if(read_uint(field, fieldlen, &vars->uid)) return 1;
    field = next;

    // group
    if(get_field(field, ':', &fieldlen, &next)) return 1;
    vars->group = field;
    field = next;

    // Detect and reject extra fields.
    if(!get_field(field, ':', &fieldlen, &next)) return 1;

    // gid
    if(get_field(field, '\n', &fieldlen, &next)) return 1;
    if(read_uint(field, fieldlen, &vars->gid)) return 1;

    return 0;
}


// passwd subplugin

// We only support a single entry in the database.
static bool passwd_sent = false;

enum nss_status _nss_determined_setpwent(int stayopen){
    (void)stayopen;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getpwent_r(struct passwd *result, char *buf,
        size_t buflen, int *errnop){
    *result = (struct passwd){0};

    if(passwd_sent){
        *errnop = 0;
        return NSS_STATUS_NOTFOUND;
    }
    passwd_sent = true;

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Make sure the buffer is long enough, including the phony passwd (x).
    size_t namelen = strlen(vars.user);
    if(buflen < namelen + 3){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.user, buflen);
    strncpy(buf + namelen + 1, "x", buflen - namelen - 1);

    *result = (struct passwd){
        .pw_name = buf,
        .pw_passwd = buf + namelen + 1,
        .pw_uid = vars.uid,
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_endpwent (void){
    passwd_sent = false;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getpwnam_r(const char *name,
        struct passwd *result, char *buf, size_t buflen, int *errnop){
    *result = (struct passwd){0};

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Is this the right user?
    if(strcmp(name, vars.user) != 0){
        *errnop = ENOENT;
        return NSS_STATUS_NOTFOUND;
    }

    // Make sure the buffer is long enough, including the phony passwd (x).
    size_t namelen = strlen(vars.user);
    if(buflen < namelen + 3){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.user, buflen);
    strncpy(buf + namelen + 1, "x", buflen - namelen - 1);

    *result = (struct passwd){
        .pw_name = buf,
        .pw_passwd = buf + namelen + 1,
        .pw_uid = vars.uid,
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getpwuid_r(uid_t uid, struct passwd *result,
        char *buf, size_t buflen, int *errnop){
    *result = (struct passwd){0};

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Is this the right user?
    if(uid != vars.uid){
        *errnop = ENOENT;
        return NSS_STATUS_NOTFOUND;
    }

    // Make sure the buffer is long enough, including the phony passwd (x).
    size_t namelen = strlen(vars.user);
    if(buflen < namelen + 3){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.user, buflen);
    strncpy(buf + namelen + 1, "x", buflen - namelen - 1);

    *result = (struct passwd){
        .pw_name = buf,
        .pw_passwd = buf + namelen + 1,
        .pw_uid = vars.uid,
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

// shadow subplugin

// We only support a single entry in the database.
static bool shadow_sent = false;

enum nss_status _nss_determined_setspent(int stayopen){
    (void)stayopen;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getspent_r(struct spwd *result, char *buf,
        size_t buflen, int *errnop){
    *result = (struct spwd){0};

    if(shadow_sent){
        *errnop = 0;
        return NSS_STATUS_NOTFOUND;
    }
    shadow_sent = true;

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Make sure the buffer is long enough, including the phony hash (!!).
    size_t namelen = strlen(vars.user);
    if(buflen < namelen + 1 + strlen("!!") + 1){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.user, buflen);
    strncpy(buf + namelen + 1, "!!", buflen - namelen - 1);

    *result = (struct spwd){
        .sp_namp = buf,
        .sp_pwdp = buf + namelen + 1,
        .sp_lstchg = -1L,
        .sp_min = -1L,
        .sp_max = -1L,
        .sp_warn = -1L,
        .sp_inact = -1L,
        .sp_expire = -1L,
        .sp_flag = (unsigned long int)-1,
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_endspent(void){
    shadow_sent = false;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getspnam_r (const char *name,
        struct spwd *result, char *buf, size_t buflen, int *errnop){
    *result = (struct spwd){0};

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Is this the right user?
    if(strcmp(name, vars.user) != 0){
        *errnop = ENOENT;
        return NSS_STATUS_NOTFOUND;
    }

    // Make sure the buffer is long enough, including the phony hash (!!).
    size_t namelen = strlen(vars.user);
    if(buflen < namelen + 1 + strlen("!!") + 1){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.user, buflen);
    strncpy(buf + namelen + 1, "!!", buflen - namelen - 1);

    *result = (struct spwd){
        .sp_namp = buf,
        .sp_pwdp = buf + namelen + 1,
        .sp_lstchg = -1L,
        .sp_min = -1L,
        .sp_max = -1L,
        .sp_warn = -1L,
        .sp_inact = -1L,
        .sp_expire = -1L,
        .sp_flag = (unsigned long int)-1,
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

// group subplugin

// We only support a single entry in the database.
static bool group_sent = false;

enum nss_status _nss_determined_setgrent(int stayopen){
    (void)stayopen;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getgrent_r(struct group *result, char *buf,
        size_t buflen, int *errnop){
    *result = (struct group){0};

    if(group_sent){
        *errnop = 0;
        return NSS_STATUS_NOTFOUND;
    }
    group_sent = true;

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Make sure the buffer is long enough, including a NULL member list.
    size_t namelen = strlen(vars.group);
    if(buflen < namelen + 3 + sizeof(char*)){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.group, buflen);
    strncpy(buf + namelen + 1, "x", buflen - namelen - 1);
    char **members = (char**)&buf[namelen + 3];
    members[0] = NULL;

    *result = (struct group){
        .gr_name = buf,
        .gr_passwd = buf + namelen + 1,
        .gr_gid = vars.gid,
        .gr_mem = (char**)&buf[namelen + 3],
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_endgrent(void){
    group_sent = false;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getgrnam_r(const char *name,
        struct group *result, char *buf, size_t buflen, int *errnop){
    *result = (struct group){0};

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Is this the right group?
    if(strcmp(name, vars.group) != 0){
        *errnop = ENOENT;
        return NSS_STATUS_NOTFOUND;
    }

    // Make sure the buffer is long enough, including a NULL member list.
    size_t namelen = strlen(vars.group);
    if(buflen < namelen + 3 + sizeof(char*)){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.group, buflen);
    strncpy(buf + namelen + 1, "x", buflen - namelen - 1);
    char **members = (char**)&buf[namelen + 3];
    members[0] = NULL;

    *result = (struct group){
        .gr_name = buf,
        .gr_passwd = buf + namelen + 1,
        .gr_gid = vars.gid,
        .gr_mem = (char**)&buf[namelen + 3],
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}

enum nss_status _nss_determined_getgrgid_r(gid_t gid, struct group *result,
        char *buf, size_t buflen, int *errnop){
    *result = (struct group){0};

    vars_t vars = {
        .errnop = errnop,
    };

    if(read_file(AGENT_USER_GROUP_FILE, &vars)){
        return vars.status;
    }

    if(parse_file(&vars)){
        *errnop = EAGAIN;
        return NSS_STATUS_TRYAGAIN;
    }

    // Is this the right group?
    if(gid != vars.gid){
        *errnop = ENOENT;
        return NSS_STATUS_NOTFOUND;
    }

    // Make sure the buffer is long enough, including a NULL member list.
    size_t namelen = strlen(vars.group);
    if(buflen < namelen + 3 + sizeof(char*)){
        *errnop = ERANGE;
        return NSS_STATUS_TRYAGAIN;
    }

    // Write the result.
    strncpy(buf, vars.group, buflen);
    strncpy(buf + namelen + 1, "x", buflen - namelen - 1);
    char **members = (char**)&buf[namelen + 3];
    members[0] = NULL;

    *result = (struct group){
        .gr_name = buf,
        .gr_passwd = buf + namelen + 1,
        .gr_gid = vars.gid,
        .gr_mem = (char**)&buf[namelen + 3],
    };

    *errnop = 0;
    return NSS_STATUS_SUCCESS;
}
