# S-UI Management Panel Role

This Ansible role installs and configures [S-UI](https://github.com/alireza0/s-ui), an advanced web panel for managing SagerNet/Sing-Box proxy configurations.

## What is S-UI?

S-UI is a web-based management interface that provides:
- Visual configuration management for sing-box
- Real-time traffic statistics and monitoring
- Online client tracking
- Inbound/outbound connection management
- User subscription service with HTTPS support
- Support for multiple protocols: VLESS, VMess, Trojan, Shadowsocks, Hysteria2, and more

## Features

- **Web Interface**: Accessible at `http://192.168.50.1:2095/app/`
- **Subscription Service**: Available at `http://192.168.50.1:2096/sub/`
- **ARM64 Support**: Fully compatible with Raspberry Pi 5
- **Easy Management**: Command-line tools for service control
- **Automatic Installation**: One-click deployment via official installer

## Installation

This role automatically:
1. Downloads and runs the official S-UI installer
2. Enables the s-ui systemd service
3. Configures firewall rules to allow access on ports 2095 and 2096
4. Creates credential reminder file at `/tmp/.sui_credentials`
5. Adds S-UI access information to the credentials file

## Default Credentials

**CRITICAL SECURITY WARNING**: S-UI installs with default credentials:
- **Username**: admin
- **Password**: admin

**YOU MUST CHANGE THESE IMMEDIATELY AFTER FIRST LOGIN!**

## Access

### From WiFi Network
```
http://192.168.50.1:2095/app/
```

### From LAN
```
http://10.0.0.242:2095/app/
```

## Management Commands

S-UI provides command-line tools for service management:

```bash
s-ui start      # Start s-ui service
s-ui stop       # Stop s-ui service
s-ui restart    # Restart s-ui service
s-ui status     # Check service status
s-ui update     # Update to latest version
s-ui uninstall  # Remove s-ui
```

## Integration with Sing-box

S-UI manages sing-box configurations through its web interface. It can:
- Create and modify inbound/outbound rules
- Configure routing and DNS settings
- Monitor traffic in real-time
- Export/import configurations
- Manage user subscriptions

The existing sing-box installation will continue to work alongside S-UI. You can manage it through either:
- Configuration files (traditional method)
- S-UI web interface (visual method)

## Ports

- **2095**: Web panel interface
- **2096**: Subscription service

Both ports are accessible from:
- WiFi network (192.168.50.0/24)
- LAN network (10.0.0.0/24)

## Security Considerations

1. **Change Default Password**: Immediately after installation
2. **Firewall**: Ports are restricted to local networks only
3. **HTTPS**: Consider enabling HTTPS in S-UI settings for production
4. **Access Control**: Use S-UI's built-in user management

## Troubleshooting

### Service Not Starting
```bash
sudo journalctl -u s-ui -n 50
```

### Web Interface Not Accessible
Check if service is running:
```bash
s-ui status
```

Check if port is listening:
```bash
sudo ss -tuln | grep 2095
```

### Reset to Defaults
If you forget the password, you may need to reinstall:
```bash
s-ui uninstall
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
```

## Variables

This role uses the following variables from `group_vars/all.yml`:
- `wifi_gateway`: WiFi AP gateway IP (default: 192.168.50.1)
- `wifi_interface`: WiFi interface name (default: wlan0)
- `ethernet_interface`: Ethernet interface name (default: eth0)
- `credentials_file`: Path to credentials file

## Dependencies

- Sing-box must be installed (handled by `singbox` role)
- Firewall must be configured (handled by `firewall` role)

## Documentation

For more information about S-UI features and configuration:
- [S-UI GitHub Repository](https://github.com/alireza0/s-ui)
- [Sing-box Official Documentation](https://sing-box.sagernet.org/)

## Support

If you encounter issues:
1. Check S-UI logs: `sudo journalctl -u s-ui -f`
2. Verify service status: `s-ui status`
3. Check network connectivity to ports 2095/2096
4. Review S-UI GitHub issues for known problems
