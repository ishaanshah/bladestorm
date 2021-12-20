#!/usr/bin/env bash

# Taken from PiHole installer
if [[ $EUID > 0 ]]
then
        echo "Script should be run as root"
        exit
fi

is_command() {
    # Checks for existence of string passed in as only function argument.
    # Exit value of 0 when exists, 1 if not exists. Value is the result
    # of the `command` shell built-in call.
    local check_command="$1"

    command -v "${check_command}" >/dev/null 2>&1
}

check_service_active() {
    # If systemctl exists,
    if is_command systemctl ; then
        # use that to check the status of the service
        systemctl is-enabled "${1}" &> /dev/null
    # Otherwise,
    else
        # fall back to service command
        service "${1}" status &> /dev/null
    fi
}

disable_resolved_stublistener() {
    printf "  %b Testing if systemd-resolved is enabled\\n" "${INFO}"
    # Check if Systemd-resolved's DNSStubListener is enabled and active on port 53
    if check_service_active "systemd-resolved"; then
        # Check if DNSStubListener is enabled
        printf "  %b  %b Testing if systemd-resolved DNSStub-Listener is active" "${OVER}" "${INFO}"
        if ( grep -E '#?DNSStubListener=yes' /etc/systemd/resolved.conf &> /dev/null ); then
            # Disable the DNSStubListener to unbind it from port 53
            # Note that this breaks dns functionality on host until dnsmasq/ftl are up and running
            printf "%b  %b Disabling systemd-resolved DNSStubListener" "${OVER}" "${TICK}"
            # Make a backup of the original /etc/systemd/resolved.conf
            # (This will need to be restored on uninstallation)
            sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
            printf " and restarting systemd-resolved\\n"
            systemctl reload-or-restart systemd-resolved
        else
            printf "%b  %b Systemd-resolved does not need to be restarted\\n" "${OVER}" "${INFO}"
        fi
    else
        printf "%b  %b Systemd-resolved is not enabled\\n" "${OVER}" "${INFO}"
    fi
}

disable_resolved_stublistener
