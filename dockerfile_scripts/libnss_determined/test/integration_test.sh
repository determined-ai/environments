#!/bin/sh

set -e

die () {
    echo -e "\x1b[31mfailed testing $@\x1b[m"
    exit 1
}

# Run tests in valgrind to ensure we don't have memory errors.
valgrind="valgrind --quiet --leak-check=full --show-leak-kinds=all"
valgrind="$valgrind --error-exitcode=255 --exit-on-first-error=yes"

run_grep_test () {
    action="$1"
    answer="$2"

    echo -n "testing $action... "
    got="$(docker run libnss_determined_test $valgrind $action)"
    echo "$got" | grep -q "$answer" || die $action
    echo "PASS"
}

run_exact_test () {
    action="$1"
    answer="$2"

    echo -n "testing $action... "
    got="$(docker run libnss_determined_test $valgrind $action)"
    test "$got" = "$answer" || die $action
    echo "PASS"
}

docker build . -t libnss_determined_test || die build

passwd_line="user:x:1000:1000::/home/user:/bin/bash"
shadow_line="user:THEHASH:18459::::::"
group_line="user:x:1000:"

run_grep_test "getent passwd" "$passwd_line"
run_exact_test "getent passwd user" "$passwd_line"
run_exact_test "getent passwd 1000" "$passwd_line"

run_grep_test "getent shadow" "$shadow_line"
run_exact_test "getent shadow user" "$shadow_line"

run_grep_test "getent group" "$group_line"
run_exact_test "getent group user" "$group_line"
run_exact_test "getent group 1000" "$group_line"
