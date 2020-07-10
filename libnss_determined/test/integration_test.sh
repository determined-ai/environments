#!/bin/sh

set -e

die () {
    echo -e "\x1b[31mfailed testing $@\x1b[m"
    exit 1
}

run_grep_test () {
    action="$1"
    answer="$2"

    echo -n "testing $action... "
    got="$(docker run libnss_determined_test $action)"
    echo "$got" | grep -q "$answer" || die $action
    echo "PASS"
}

run_exact_test () {
    action="$1"
    answer="$2"

    echo -n "testing $action... "
    got="$(docker run libnss_determined_test $action)"
    test "$got" = "$answer" || die $action
    echo "PASS"
}

docker build . -t libnss_determined_test || die build

passwd_line="user:x:1000:0:::"
shadow_line="user:!!:::::::"
group_line="user:x:1000:"

run_grep_test "getent passwd" "$passwd_line"
run_exact_test "getent passwd user" "$passwd_line"
run_exact_test "getent passwd 1000" "$passwd_line"

run_grep_test "getent shadow" "$shadow_line"
run_exact_test "getent shadow user" "$shadow_line"

run_grep_test "getent group" "$group_line"
run_exact_test "getent group user" "$group_line"
run_exact_test "getent group 1000" "$group_line"
