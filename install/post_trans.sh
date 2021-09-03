#!/bin/sh

# Generated by: tyk-ci/wf-gen
# Generated on: Fri  3 Sep 12:23:14 UTC 2021

# Generation commands:
# ./pr.zsh -title [TT-2932] systemd service restore for deb -base releng/upgrades -branch releng/upgrades -repos tyk-sink,tyk-identity-broker,tyk-pump,raava -p
# m4 -E -DxREPO=tyk-identity-broker


if command -V systemctl >/dev/null 2>&1; then
    if [ ! -f /lib/systemd/system/tyk-identity-broker.service ]; then
	cp /opt/tyk-identity-broker/install/tyk-identity-broker.service /lib/systemd/system/tyk-identity-broker.service
    fi
fi
