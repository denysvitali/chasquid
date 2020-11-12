#!/bin/bash

set -e
. $(dirname ${0})/../util/lib.sh

init

mkdir -p .logs

if ! haproxy -v > /dev/null; then
	skip "haproxy binary not found"
	exit 0
fi

# Launch haproxy in the background.
haproxy -f haproxy.cfg > .logs/haproxy.log 2>&1 &

generate_certs_for testserver
add_user user@testserver secretpassword
add_user someone@testserver secretpassword

chasquid -v=2 --logfile=.logs/chasquid.log --config_dir=config &

wait_until_ready 1025 # haproxy
wait_until_ready 2025

run_msmtp someone@testserver < content

wait_for_file .mail/someone@testserver

mail_diff content .mail/someone@testserver

success
