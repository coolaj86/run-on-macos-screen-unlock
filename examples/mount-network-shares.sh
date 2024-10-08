#!/bin/sh
set -e
set -u

g_is_tty=""
if test -t 0; then
    g_is_tty="yes"
fi

fn_mount_share() {
    a_smb_share="${1:-}"

    # ex: //jon@truenas.local
    b_servername="$(dirname "${a_smb_share}" | sed 's:.*//://:')"

    # Note: If we're already connected to the server, we can connect "headless"
    #       and the existing network credentials session will be used.
    if mount | grep -q -F "${b_servername}"; then
        # ex: /usr/bin/osascript -e 'mount volume "smb://jon@truenas.local/TimeMachineBackups"'
        /usr/bin/osascript -e "mount volume \"${a_smb_share}\""
        return 0
    fi

    # Note: If we're NOT already connected, then we have to use Finder to get
    #       prompt for access to the system keychain for the stored password,
    #       otherwise we'd have to store the password in the URL or require
    #       more manual user interaction.
    #
    # Note: `security find-internet-password -w -s "192.168.1.101" -a "username"`
    #       will retrieve the password, but it prompts to type the login password
    #       and click Allow anyway, so we're better off with the single Connect
    #       click.
    printf "Connecting to %s" "${b_servername}"
    /usr/bin/open "${a_smb_share}"
    for i in 1 2 3 3 1; do
        printf "."
        if mount | grep -q -F "${b_servername}"; then
            break
        fi
        sleep "$i"
    done

    if mount | grep -q -F "${b_servername}"; then
        echo " done."
    else
        echo ""
        echo "ERROR"
        echo "    failed to connect to ${b_servername} after 5 retries over 10s"
        echo ""
        printf "Connect via the NETWORK SHARE POP-UP DIALOG"
        if test -n "${g_is_tty}"; then
            echo ", then press ENTER to continue"
            # shellcheck disable=SC2034 # just want the any key, not its value
            read -r g_dummy < /dev/tty
        else
            echo ''
        fi
    fi
}

fn_version() {
    echo "mount-macos-network-shares v1.0.0 (2024-08-19)"
    echo "Copyright AJ ONeal (MPL-2.0)"
}

fn_help() {
    echo ""
    echo "USAGE"
    echo "    mount-macos-network-shares [path-to-config]"
    echo ""
    echo "OPTIONS"
    echo "    --help - print this message"
    echo "    -V,--version - print the version"
    echo ""
    echo "CONFIG"
    echo "    Default config file:"
    echo "        ~/.config/macos-network-shares/urls.conf"
    echo ""
    echo "    Example config file contents:"
    echo "        smb://puter:secret@truenas.local/TimeMachineBackups"
    echo "        smb://wifu@192.168.1.101/Family Photos"
    echo ""
}

fn_mount_shares() {
    b_urls_file="${1}"
    # shellcheck disable=SC2002 # we don't want to steal stdin from the tty, if it exists
    while IFS= read -r b_share_url; do
        fn_mount_share >&2 "${b_share_url}"
    done < "${b_urls_file}"
}

main() {
    if ! test -f ~/.config/macos-network-shares/urls.conf; then
        mkdir -p ~/.config/macos-network-shares/ || true
        chmod 0700 ~/.config/macos-network-shares || true
        touch ~/.config/macos-network-shares/urls.conf || true
        chmod 0600 ~/.config/macos-network-shares/urls.conf || true
        echo "#smb://user:pass@truenas.local/TimeMachineBackups" >> ~/.config/macos-network-shares/urls.conf || true
    fi

    b_urls_file="${1-$HOME/.config/macos-network-shares/urls.conf}"
    case "${b_urls_file}" in
        --version | -V | version)
            fn_version
            exit 0
            ;;
        --help | help)
            fn_help
            exit 0
            ;;
        *) ;;
    esac

    if ! test -e "${b_urls_file}" && grep -q -v -E '^\s*(#.*)?$' "${b_urls_file}"; then
        {
            echo ""
            echo "ERROR"
            echo "    url list '${b_urls_file}' is empty or does not exist"
            echo ""
            fn_help
        } >&2
    fi

    {
        echo "Network URLs List: ${b_urls_file}"
    } >&2

    fn_mount_shares "${b_urls_file}"
}

main "$@"
