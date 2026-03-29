[ -n "$__IS_LIB_RENDER_LOCAL_TOML" ] && return
__IS_LIB_RENDER_LOCAL_TOML=1

bool_true() {
    [ "$1" = ON ] || [ "$1" = 1 ] || [ "$1" = true ] || [ "$1" = TRUE ]
}

render_toml_array() {
    key="$1"
    file="$2"
    first=1

    printf '%s = [' "$key"
    if [ -f "$file" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            case "$line" in
                \#*) continue ;;
            esac
            [ "$first" = 1 ] || printf ', '
            printf '"%s"' "$line"
            first=0
        done < "$file"
    fi
    printf ']\n'
}

render_peer_blocks() {
    file="$1"
    [ -f "$file" ] || return 0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        case "$line" in
            \#*) continue ;;
        esac
        printf '[[peer]]\n'
        printf 'uri = "%s"\n' "$line"
    done < "$file"
}

render_local_toml() {
    mkdir -p "$TMPDIR" 2>/dev/null

    {
        printf 'instance_name = "%s"\n' "${instance_name:-default}"
        if bool_true "$dhcp"; then
            printf 'dhcp = true\n'
        else
            printf 'dhcp = false\n'
        fi
        [ -n "$ipv4" ] && printf 'ipv4 = "%s"\n' "$ipv4"
        [ -n "$ipv6" ] && printf 'ipv6 = "%s"\n' "$ipv6"
        [ -n "$hostname" ] && printf 'hostname = "%s"\n' "$hostname"
        printf 'rpc_portal = "%s"\n' "$rpc_portal"
        render_toml_array listeners "$APPDIR/configs/listeners.list"
        render_toml_array mapped_listeners "$APPDIR/configs/mapped_listeners.list"
        render_toml_array exit_nodes "$APPDIR/configs/exit_nodes.list"
        render_toml_array proxy_networks "$APPDIR/configs/proxy_networks.list"
        printf '\n[network_identity]\n'
        printf 'network_name = "%s"\n' "$network_name"
        printf 'network_secret = "%s"\n' "$network_secret"
        printf '\n[flags]\n'
        printf 'default_protocol = "%s"\n' "$default_protocol"
        if bool_true "$disable_encryption"; then
            printf 'enable_encryption = false\n'
        else
            printf 'enable_encryption = true\n'
        fi
        if bool_true "$disable_ipv6"; then
            printf 'enable_ipv6 = false\n'
        else
            printf 'enable_ipv6 = true\n'
        fi
        [ -n "$dev_name" ] && printf 'dev_name = "%s"\n' "$dev_name"
        [ -n "$mtu" ] && printf 'mtu = %s\n' "$mtu"
        bool_true "$latency_first" && printf 'latency_first = true\n' || printf 'latency_first = false\n'
        bool_true "$enable_exit_node" && printf 'enable_exit_node = true\n' || printf 'enable_exit_node = false\n'
        bool_true "$no_tun" && printf 'no_tun = true\n' || printf 'no_tun = false\n'
        bool_true "$use_smoltcp" && printf 'use_smoltcp = true\n' || printf 'use_smoltcp = false\n'
        bool_true "$disable_p2p" && printf 'disable_p2p = true\n' || printf 'disable_p2p = false\n'
        bool_true "$relay_all_peer_rpc" && printf 'relay_all_peer_rpc = true\n' || printf 'relay_all_peer_rpc = false\n'
        bool_true "$disable_udp_hole_punching" && printf 'disable_udp_hole_punching = true\n' || printf 'disable_udp_hole_punching = false\n'
        bool_true "$disable_tcp_hole_punching" && printf 'disable_tcp_hole_punching = true\n' || printf 'disable_tcp_hole_punching = false\n'
        printf '\n'
        render_peer_blocks "$APPDIR/configs/peers.list"
    } > "$ET_TOML_FILE"
}
