#!/bin/sh
set -e
set -u

fn_mount_share() {
    a_smb_share="${1:-}"
    # ex: /usr/bin/osascript -e 'mount volume "smb://jon@truenas.local/TimeMachineBackups"'
    /usr/bin/osascript -e "mount volume \"${a_smb_share}\""
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
    while IFS= read -r b_share_url; do
        fn_mount_share "${b_share_url}"
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
