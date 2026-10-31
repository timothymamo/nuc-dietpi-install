#!/bin/bash
# Runs on every container start, before fail2ban itself (linuxserver's
# /custom-cont-init.d hook). Copies the repo's jails and filters into the live
# config, rather than mounting them there, so fail2ban-ui can still edit them.
cp /seed/jail.d/* /config/fail2ban/jail.d/
cp /seed/filter.d/* /config/fail2ban/filter.d/
chown -R abc:abc /config/fail2ban/jail.d /config/fail2ban/filter.d
