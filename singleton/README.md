# Raspberry Pi Secure WiFi Proxy (Singleton)

**[English](README.md)** | **[فارسی](README.fa.md)**

A comprehensive Ansible-automated solution to transform a Raspberry Pi into a secure WiFi access point with DNS filtering, Iranian IP/domain blocking, and VLESS/VMess proxy support. All services run on a single device.

**Author:** Iman Samizadeh
**Licence:** MIT
**Repository:** https://github.com/Iman/javid-mask
**Last Updated:** 2026-02-01

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [Privacy Threats & Defence Architecture](#privacy-threats--defence-architecture)
- [Security Model](#security-model)
- [Features](#features)
- [Architecture](#architecture)
- [Starlink Integration](#starlink-integration)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [DNS Leak Prevention](#dns-leak-prevention)
- [Security Hardening](#security-hardening)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Licence](#licence)

---

## Architecture Diagrams

### Network Architecture

![Singleton Network Architecture](diagrams/network-architecture.drawio.png)

### Data Flow

![Singleton Data Flow](diagrams/data-flow-Data%20Flow%20Diagram.drawio.png)

### Leak Protection

![Singleton Leak Protection](diagrams/leak-protection.drawio.png)

---

## Executive Summary

The **Singleton** architecture provides a self-contained privacy gateway on a single Raspberry Pi. It creates an isolated WiFi network where all connected devices benefit from:

- **DNS-level filtering** blocking 1.6M+ malicious domains
- **Encrypted DNS** via DNS-over-HTTPS (DoH) to Cloudflare
- **Iranian IP blocking** preventing traffic to/from 763 CIDR ranges
- **Proxy support** for VLESS/VMess protocols with Reality obfuscation
- **Network isolation** separating WiFi clients from your home LAN

This solution is ideal for users who want comprehensive privacy protection without requiring a VPS or complex distributed infrastructure.

---

## Privacy Threats & Defence Architecture

### Why This Project Exists

Modern internet users face unprecedented surveillance and privacy threats from multiple vectors: government agencies, ISPs, corporations, and malicious actors. This project addresses critical privacy leaks that expose user identity, location, and online activities even when using VPNs or proxies.

### Threat Model

This project defends against:

| Threat Actor | Attack Vector | Defence Layer |
|--------------|---------------|---------------|
| ISP | DNS logging, traffic analysis | DoH encryption, proxy tunnelling |
| Government | DPI, IP correlation | Reality protocol, Iranian IP blocking |
| Advertisers | Tracking domains, fingerprinting | Pi-hole blocklists (1.6M+ domains) |
| Malware | C2 servers, phishing domains | Security blocklists, DNSSEC |
| Local attackers | Network sniffing, ARP spoofing | WPA2-PSK, network isolation |

### Critical Privacy Threats

#### 1. DNS-Based Tracking & Exploitation

**DNS Leaks**: The most dangerous privacy leak

- **ISP DNS logging**: Your ISP records every domain you query, creating a complete browsing profile
- **VPN DNS leaks**: Misconfigured VPNs may send DNS queries outside the encrypted tunnel
- **WebRTC leaks**: Browser WebRTC can expose DNS queries even through proxies
- **IPv6 DNS leaks**: When VPN/proxy only handles IPv4, IPv6 DNS queries leak
- **OS DNS cache**: Operating system DNS cache exposes browsing history to local attackers
- **Split-horizon DNS**: Corporate/ISP DNS may return different results based on source IP

**DNS Spoofing & Hijacking**:

- Man-in-the-middle attacks redirecting DNS queries
- ISP DNS injection inserting tracking/advertising
- Malicious DNS servers returning compromised IPs
- DNS rebinding attacks accessing internal networks

#### 2. IP Address Exposure

**Direct IP Leaks**:

- WebRTC STUN/TURN server queries expose real IP
- Torrent DHT announces reveal IP address
- Email headers may contain originating IP
- Browser plugins may bypass proxy settings

**IP Correlation Attacks**:

- Traffic timing analysis correlating entry/exit points
- Unique traffic patterns identifying users
- Geographic IP clustering revealing location patterns
- Multi-session tracking across IP changes

#### 3. Deep Packet Inspection (DPI)

**Protocol Fingerprinting**:

- TLS fingerprinting (JA3/JA4 hashes)
- HTTP header analysis
- Packet timing and size analysis
- Application-layer protocol identification

**Iranian DPI Capabilities**:

- Active probing of suspected proxy servers
- Protocol whitelisting (blocking unknown protocols)
- SNI-based filtering
- Certificate fingerprinting

#### 4. Identity Correlation Attack (Cookie/Fingerprint Leakage)

**The Starlink Identity Exposure Threat**:

When a user with Starlink (foreign IP) accidentally visits an Iranian website, their identity can be correlated:

```
BEFORE (Normal Iranian ISP):
┌──────────────┐      ┌─────────────────┐
│ User         │─────►│ Iranian Website │
│ Cookie: Reza │      │ (digikala.com)  │
│ IP: Iran     │      │ Logs: Reza=Iran │
└──────────────┘      └─────────────────┘

AFTER (Starlink - DANGEROUS):
┌──────────────┐      ┌─────────────────┐
│ User         │─────►│ Iranian Website │
│ Cookie: Reza │      │ (digikala.com)  │
│ IP: USA!     │      │ Logs: Reza=USA!!│  ◄── RED FLAG
└──────────────┘      └─────────────────┘       "Reza has Starlink"
```

**Attack Vectors**:

- **Cookie correlation**: Same user cookie + foreign IP = identity exposed
- **Browser fingerprint**: Canvas, WebGL, fonts identify device across IPs
- **Login sessions**: Authenticated sessions reveal identity
- **Referrer headers**: Show navigation patterns
- **Timing correlation**: Login patterns match previous behaviour

**Singleton's Defence**: Complete Iranian domain blocking at DNS level prevents ANY connection to Iranian servers, eliminating the correlation attack entirely.

#### 5. Iranian IP/Domain Tracking

**Why Iranian IP Blocking Matters**:

- **763 active CIDR ranges** covering major Iranian ISPs:
  - MCI (Mobile Communication Company of Iran)
  - Irancell (MTN Irancell)
  - Rightel
  - Shatel
  - ParsOnline
  - Mokhaberat (TCI)
  - Asiatech
  - Afranet
- Government data centres and surveillance infrastructure
- Traffic correlation across services hosted in Iran
- Mandatory data retention by Iranian ISPs

**Iranian Domain Blocking (Identity Protection)**:

- **131,576+ Iranian domains blocked** via bootmortis/iran-hosted-domains
- **Complete .ir TLD blocked** - all *.ir domains
- **Major Iranian services blocked**:
  - E-commerce: digikala.com, snapp.ir, tapsi.ir, divar.ir
  - Media: aparat.com, filimo.com, namava.ir
  - Social: rubika.ir, eitaa.com, bale.ai
  - Banking: All Iranian banks (*.bank*.ir)
  - Government: *.gov.ir, *.ac.ir
  - CDNs: arvancloud.com, cdn.ir
- **Why this matters**: Prevents cookie/fingerprint correlation attacks that could expose Starlink users

### How Singleton Defends Against These Threats

#### Defence Layer 1: Pi-hole DNS Filtering

```
WiFi Client → Pi-hole (10.50.0.1:53)
    ├── Query: ads.tracker.com
    │   └── BLOCKED (returns 0.0.0.0)
    │       Source: EasyPrivacy blocklist
    │
    └── Query: legitimate-site.com
        └── ALLOWED → Cloudflared (DoH)
            └── Cloudflare 1.1.1.1 (encrypted)
```

**Protection Provided**:

- 1.6M+ malicious/tracking domains blocked
- Queries never leave your network unencrypted
- No DNS logs stored on third-party servers
- DNSSEC validation prevents DNS spoofing

#### Defence Layer 2: DNS-over-HTTPS (Cloudflared)

```
Pi-hole → Cloudflared (127.0.0.1:5053)
    └── HTTPS/443 → Cloudflare 1.1.1.1
        ├── Encrypted DNS query
        ├── Certificate validation
        └── No ISP visibility into queries
```

**Protection Provided**:

- DNS queries encrypted with TLS 1.3
- ISP cannot see which domains you query
- Bypasses ISP DNS hijacking
- Cloudflare's privacy-focused DNS policy

#### Defence Layer 3: nftables Firewall + Iranian IP Blocking

```
table inet filter {
    set iranian_blocklist {
        type ipv4_addr
        flags interval
        auto-merge
        elements = {
            2.144.0.0/14,      # MCI
            5.52.0.0/15,       # Shatel
            5.160.0.0/15,      # Respina
            ... (763 ranges total)
        }
    }

    chain input {
        policy drop
        ct state established,related accept
        ip saddr @iranian_blocklist counter drop
    }

    chain forward {
        policy drop
        ip saddr @iranian_blocklist counter drop
        ip daddr @iranian_blocklist counter drop
    }

    chain output {
        policy accept
        ip daddr @iranian_blocklist counter drop
    }
}
```

**Protection Provided**:

- All traffic to/from Iranian IPs blocked
- Stateful connection tracking prevents spoofing
- Logging of blocked connection attempts
- Auto-merge optimises rule efficiency

#### Defence Layer 4: 3x-UI Xray Proxy (VLESS/VMess)

```
Application → V2RayNG/Clash Client
    └── VLESS/VMess (encrypted)
        └── Xray-core (10.50.0.1)
            ├── DNS: Pi-hole (filtered)
            ├── TLS: Certificate pinning
            └── Reality: Anti-DPI obfuscation
```

**Protection Provided**:

- Traffic encrypted with modern ciphers
- Reality protocol defeats DPI analysis
- Appears as legitimate HTTPS traffic
- No distinguishable proxy fingerprint

#### Defence Layer 5: Network Isolation

```
Home LAN (10.0.0.0/24)
    │
    └── Raspberry Pi
        ├── eth0: 10.0.0.242 (home network)
        └── wlan0: 10.50.0.1 (isolated WiFi)
            └── WiFi Clients (10.50.0.x)
                ├── Cannot access home LAN
                ├── All DNS via Pi-hole
                └── All traffic via nftables
```

**Protection Provided**:

- WiFi clients isolated from home network devices
- Compromised IoT devices cannot spread laterally
- All WiFi traffic forced through security stack
- Clear network segmentation

---

## Leak Protection Summary

### Current Protection Against Leaks

| Leak Type | Protection Status | Implementation |
|-----------|-------------------|----------------|
| **DNS Leak** | ✅ Protected | Pi-hole forces all DNS through local resolver → Cloudflared DoH (encrypted) |
| **IPv6 Leak** | ✅ Protected | IPv6 completely disabled at nftables level (DROP all ip6 traffic) |
| **WebRTC Leak** | ⚠️ Browser Config | Requires browser-level mitigation (not network-level) |
| **Iranian Domain Leak** | ✅ Protected | 131,576+ domains blocked at DNS level (bootmortis + liketolivefree) |
| **Iranian IP Leak** | ✅ Protected | 763 CIDR ranges blocked at firewall level |
| **Cookie Correlation** | ✅ Protected | Iranian domains blocked prevents cookie leakage to Iranian servers |

### What's Covered vs What Needs Browser Configuration

```
NETWORK LEVEL (✅ Fully Protected by Singleton):
├── DNS queries → Pi-hole → Cloudflared DoH (encrypted)
├── IPv6 traffic → DROP (nftables ip6 filter)
├── Iranian IPs → DROP (nftables, 763 CIDR ranges)
├── Iranian domains → 0.0.0.0 (Pi-hole, 131,576+ domains)
└── All WiFi traffic → Forced through security stack

BROWSER LEVEL (⚠️ User must configure):
├── WebRTC → Disable in browser settings
├── JavaScript fingerprinting → Use uBlock Origin, NoScript
├── Canvas fingerprinting → Firefox resistFingerprinting
└── Cookie tracking → Use Cookie AutoDelete extension
```

### Browser Hardening Guide

To achieve complete leak protection, configure your browser:

**Firefox (Recommended)**:

```
about:config settings:
├── media.peerconnection.enabled → false     (Disables WebRTC)
├── media.navigator.enabled → false          (Disables media devices)
├── privacy.resistFingerprinting → true      (Anti-fingerprinting)
├── network.dns.disableIPv6 → true           (Disable IPv6 DNS)
├── geo.enabled → false                      (Disable geolocation)
├── dom.battery.enabled → false              (Disable battery API)
└── privacy.trackingprotection.enabled → true
```

**Recommended Extensions**:

| Extension | Purpose |
|-----------|---------|
| uBlock Origin | Ad/tracker blocking, WebRTC control |
| NoScript | JavaScript control |
| Cookie AutoDelete | Automatic cookie cleanup |
| HTTPS Everywhere | Force HTTPS connections |
| Decentraleyes | Local CDN emulation |

**Chrome/Chromium**:

```
chrome://flags settings:
├── WebRTC IP handling policy → Disable non-proxied UDP
└── Enable: chrome://settings/content/sensors → Block

Extensions:
├── WebRTC Leak Prevent
├── uBlock Origin
└── Cookie AutoDelete
```

**Mobile (Android)**:

- Use **Firefox Focus** or **Brave Browser**
- V2RayNG/Clash: Enable "Block non-proxy connections"
- Disable WebRTC in browser settings

---

## Security Model

### Defence in Depth

The Singleton architecture implements multiple overlapping security layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 5: APPLICATION                      │
│         Xray/VLESS/VMess with Reality Protocol              │
│         Traffic encryption + DPI evasion                     │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 4: TRANSPORT                        │
│              TLS 1.3 + Certificate Pinning                   │
│              Encrypted tunnel to proxy server                │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 3: NETWORK                          │
│         nftables Firewall + Iranian IP Blocking              │
│         NAT Masquerade + Stateful Filtering                  │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 2: DNS                              │
│      Pi-hole (1.6M blocks) + Cloudflared (DoH)              │
│      DNSSEC Validation + Rate Limiting                       │
├─────────────────────────────────────────────────────────────┤
│                    LAYER 1: PHYSICAL                         │
│           WPA2-PSK (CCMP) + Network Isolation                │
│           Dedicated WiFi AP on separate subnet               │
└─────────────────────────────────────────────────────────────┘
```

### Trust Boundaries

| Component | Trust Level | Data Exposed | Mitigation |
|-----------|-------------|--------------|------------|
| Raspberry Pi | Full | All traffic | Physical security, SSH keys |
| Cloudflare DNS | Partial | Domain queries | DoH encryption, no IP correlation |
| Xray Proxy Server | Partial | Encrypted traffic | TLS, Reality protocol |
| WiFi Clients | Untrusted | Own traffic only | Network isolation |
| Home Router | Untrusted | Encrypted blobs | All traffic encrypted |
| ISP/Starlink | Untrusted | Encrypted blobs | DoH + Proxy tunnelling |

### Cryptographic Standards

| Function | Algorithm | Key Size | Standard |
|----------|-----------|----------|----------|
| WiFi Encryption | AES-CCMP | 256-bit | WPA2-PSK |
| DNS-over-HTTPS | TLS 1.3 | 256-bit | RFC 8484 |
| VLESS Transport | AEAD | 256-bit | Xray-core |
| Reality Obfuscation | X25519 | 256-bit | XTLS |
| DNSSEC | RSA/ECDSA | 2048/256-bit | RFC 4033-4035 |

---

## Features

### Network & WiFi

- **Isolated WiFi Network**: 10.50.0.0/24 (completely separate from home LAN)
- **WPA2-PSK Encryption**: CCMP cipher with 256-bit AES
- **DHCP Server**: Automatic IP assignment (10.50.0.10-250)
- **NAT Masquerading**: Transparent internet access for WiFi clients
- **IPv6 Disabled**: Prevents IPv6 leak vectors

### DNS & Privacy

- **Pi-hole v6 DNS Filtering**: 1.6M+ domains blocked
- **DNS-over-HTTPS**: Cloudflared bypasses ISP DNS interception
- **Comprehensive Blocklists**: Ads, trackers, malware, phishing, Iranian domains
- **DNSSEC Validation**: Cryptographic verification of DNS responses
- **DNS Rate Limiting**: 1000 queries/60 seconds per client
- **DNS Rebind Protection**: Prevents DNS rebinding attacks

### Blocklists Included

| Category | Source | Domains | Update Frequency |
|----------|--------|---------|------------------|
| Unified Hosts | StevenBlack/hosts | 150,000+ | Daily |
| Privacy | EasyPrivacy | 25,000+ | Weekly |
| Advertising | Prigent-Ads | 50,000+ | Daily |
| Phishing | Phishing Army | 30,000+ | Hourly |
| Malware | Malware Domains | 20,000+ | Daily |
| Tracking | BlocklistProject | 100,000+ | Daily |
| YouTube Ads | kboghdady | 5,000+ | Weekly |
| Crypto Miners | CoinBlockerLists | 10,000+ | Daily |
| Iranian Domains | bootmortis/iran-hosted-domains | 131,576+ | Weekly |
| Porn | BlocklistProject | 500,000+ | Weekly |
| TikTok | BlocklistProject | 1,000+ | Weekly |
| Spam | Spam404 | 10,000+ | Daily |
| Social Tracking | Disconnect.me | 5,000+ | Weekly |

### Proxy & Security

- **3x-UI Management Panel**: Web-based Xray-core configuration
- **VLESS/VMess Support**: Modern proxy protocols with WebSocket/gRPC transport
- **Reality Protocol**: Anti-DPI obfuscation mimicking legitimate TLS
- **QR Code Generation**: Easy mobile client setup
- **Traffic Statistics**: Real-time monitoring and bandwidth tracking
- **Multi-user Support**: Individual client management with limits

### Firewall & Blocking

- **nftables Firewall**: Stateful packet filtering with connection tracking
- **Iranian IP Blocking**: 763 CIDR ranges (input/forward/output chains)
- **Forward Chain Protection**: Blocks proxy traffic to Iranian IPs
- **Auto-Merge Optimisation**: Efficient IP range consolidation
- **Connection Logging**: Optional logging of blocked attempts
- **Rate Limiting**: Protection against brute-force attacks

### Automation

- **Ansible Deployment**: Complete infrastructure as code
- **Persistent Configuration**: All settings survive reboots
- **Automated Updates**: Daily blocklist refresh at 03:00 UTC
- **Idempotent Playbooks**: Safe to re-run anytime
- **Credential Generation**: Secure random password generation

---

## Architecture

### Network Topology with Starlink

```
                         ┌─────────────────────┐
                         │     INTERNET        │
                         │   (Public Web)      │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  STARLINK SATELLITE │
                         │   (LEO Orbit)       │
                         └──────────┬──────────┘
                                    │ Encrypted Downlink
                         ┌──────────▼──────────┐
                         │  STARLINK TERMINAL  │
                         │   (Dishy McFlatface)│
                         │   CGNAT: 100.x.x.x  │
                         └──────────┬──────────┘
                                    │ Ethernet
                         ┌──────────▼──────────┐
                         │   STARLINK ROUTER   │
                         │   (or Bypass Mode)  │
                         │   LAN: 10.0.0.1     │
                         └──────────┬──────────┘
                                    │ 10.0.0.0/24
               ┌────────────────────┼────────────────────┐
               │                    │                    │
    ┌──────────▼──────────┐        │         ┌──────────▼──────────┐
    │   OTHER LAN DEVICES │        │         │    OTHER DEVICES    │
    │   (Unprotected)     │        │         │    (Unprotected)    │
    │   10.0.0.x          │        │         │    10.0.0.x         │
    └─────────────────────┘        │         └─────────────────────┘
                                   │
                         ┌─────────▼─────────┐
                         │   RASPBERRY PI 5   │
                         │                    │
                         │ eth0: 10.0.0.242   │◄── From Starlink Router
                         │ wlan0: 10.50.0.1   │──► To WiFi Clients
                         │                    │
                         │ ┌────────────────┐ │
                         │ │   SECURITY     │ │
                         │ │    STACK       │ │
                         │ │                │ │
                         │ │ • Pi-hole DNS  │ │
                         │ │ • Cloudflared  │ │
                         │ │ • nftables     │ │
                         │ │ • Xray/3x-UI   │ │
                         │ │ • hostapd      │ │
                         │ └────────────────┘ │
                         └─────────┬─────────┘
                                   │ WPA2-PSK
                                   │ 10.50.0.0/24
               ┌───────────────────┼───────────────────┐
               │                   │                   │
    ┌──────────▼──────────┐ ┌──────▼──────┐ ┌─────────▼─────────┐
    │   MOBILE PHONE      │ │   LAPTOP    │ │   TABLET/OTHER    │
    │   (Protected)       │ │ (Protected) │ │   (Protected)     │
    │   10.50.0.x         │ │ 10.50.0.x   │ │   10.50.0.x       │
    │                     │ │             │ │                   │
    │ • V2RayNG client    │ │ • Clash     │ │ • Shadowrocket    │
    │ • All DNS filtered  │ │ • Filtered  │ │ • Filtered        │
    │ • Iranian IPs block │ │ • Protected │ │ • Protected       │
    └─────────────────────┘ └─────────────┘ └───────────────────┘
```

### Service Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                     WiFi CLIENT (10.50.0.x)                     │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Web Browser │  │ Mobile App  │  │ V2RayNG/Clash Client    │ │
│  └──────┬──────┘  └──────┬──────┘  └────────────┬────────────┘ │
│         │                │                       │              │
│         └────────────────┴───────────────────────┘              │
│                          │ All Traffic                          │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                      RASPBERRY PI (10.50.0.1)                    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    hostapd (WiFi AP)                        │ │
│  │   SSID: SecureProxy-XXXXXXXX | WPA2-PSK | Channel 6        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                Pi-hole v6 (DNS Filtering)                   │ │
│  │   Port 53 | 1.6M+ blocks | DNSSEC | Rate limiting          │ │
│  │                                                             │ │
│  │   Upstream: Cloudflared (127.0.0.1:5053)                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │               Cloudflared (DNS-over-HTTPS)                  │ │
│  │   Local: 127.0.0.1:5053 | Upstream: Cloudflare 1.1.1.1     │ │
│  │   Protocol: HTTPS/443 | TLS 1.3                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              nftables Firewall (Packet Filter)              │ │
│  │                                                             │ │
│  │   ┌─────────────────────────────────────────────────────┐  │ │
│  │   │ Iranian IP Blocklist (763 CIDR ranges)              │  │ │
│  │   │ • input chain: Drop inbound from Iranian IPs        │  │ │
│  │   │ • forward chain: Drop transit to/from Iranian IPs   │  │ │
│  │   │ • output chain: Drop outbound to Iranian IPs        │  │ │
│  │   └─────────────────────────────────────────────────────┘  │ │
│  │                                                             │ │
│  │   ┌─────────────────────────────────────────────────────┐  │ │
│  │   │ NAT Table                                           │  │ │
│  │   │ • postrouting: Masquerade wlan0 → eth0             │  │ │
│  │   └─────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 3x-UI / Xray-core (Proxy)                   │ │
│  │                                                             │ │
│  │   Management Panel: http://10.50.0.1:2053/                 │ │
│  │   Subscription: http://10.50.0.1:2096/sub/                 │ │
│  │                                                             │ │
│  │   Supported Protocols:                                      │ │
│  │   • VLESS (recommended)                                    │ │
│  │   • VMess                                                  │ │
│  │   • Trojan                                                 │ │
│  │   • Shadowsocks                                            │ │
│  │                                                             │ │
│  │   Transport Options:                                        │ │
│  │   • TCP                                                    │ │
│  │   • WebSocket                                              │ │
│  │   • gRPC                                                   │ │
│  │   • HTTP/2                                                 │ │
│  │                                                             │ │
│  │   Security Features:                                        │ │
│  │   • Reality protocol (anti-DPI)                            │ │
│  │   • TLS 1.3                                                │ │
│  │   • Certificate pinning                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   eth0 (10.0.0.242)                         │ │
│  │               Upstream to Starlink Router                   │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │   STARLINK ROUTER       │
              │   (10.0.0.1)            │
              └───────────┬─────────────┘
                          │
                          ▼
              ┌─────────────────────────┐
              │   STARLINK TERMINAL     │
              │   → SATELLITE           │
              │   → INTERNET            │
              └─────────────────────────┘
```

### Active Services

| Service | Port | Protocol | Function | Binding |
|---------|------|----------|----------|---------|
| hostapd | - | 802.11 | WiFi Access Point | wlan0 |
| pihole-FTL | 53 | UDP/TCP | DNS filtering & DHCP | 10.50.0.1 |
| pihole-FTL | 80 | HTTP | Web admin interface | 10.50.0.1 |
| cloudflared | 5053 | DoH | DNS-over-HTTPS proxy | 127.0.0.1 |
| x-ui | 2053 | HTTPS | 3x-UI management panel | 0.0.0.0 |
| x-ui | 2096 | HTTPS | Subscription service | 0.0.0.0 |
| xray-core | Custom | Various | VLESS/VMess proxy engine | 0.0.0.0 |
| nftables | - | - | Firewall with Iranian IP blocking | kernel |
| sing-box | 1080 | SOCKS5 | Alternative proxy (optional) | 0.0.0.0 |
| sing-box | 8080 | HTTP | Alternative proxy (optional) | 0.0.0.0 |
| sing-box | 7890 | Mixed | Alternative proxy (optional) | 0.0.0.0 |

---

## Starlink Integration

### Starlink Network Characteristics

**Understanding Starlink's Network Architecture**:

Starlink uses Carrier-Grade NAT (CGNAT), which means:

- Your Starlink terminal receives a private IP (100.x.x.x range)
- Multiple subscribers share public IP addresses
- Direct inbound connections are not possible without port forwarding (unavailable on residential plans)
- IP addresses change frequently (every few hours to days)

**Implications for Privacy**:

| Characteristic | Privacy Impact | Singleton Mitigation |
|----------------|----------------|----------------------|
| CGNAT (100.x.x.x) | Shared IP provides some anonymity | All traffic via proxy for additional layer |
| Dynamic IP | Harder to track long-term | Does not affect outbound privacy |
| SpaceX DNS | Potential logging | All DNS via Cloudflared DoH |
| Variable latency (20-100ms) | May affect VPN/proxy performance | Optimised buffer settings |
| No port forwarding | Cannot host services | Not required for Singleton |

### Starlink-Specific Configuration

**Network Configuration for Starlink Router**:

The Singleton is designed to work seamlessly behind Starlink's router:

```
Starlink Terminal (CGNAT: 100.x.x.x)
    │
    └── Starlink Router (10.0.0.1)
        │   • DHCP Server: 10.0.0.2-254
        │   • DNS: SpaceX DNS (bypassed by Singleton)
        │   • NAT: Double NAT acceptable
        │
        └── Raspberry Pi (10.0.0.242)
            │   • Static IP recommended
            │   • Gateway: 10.0.0.1
            │
            └── Secure WiFi (10.50.0.0/24)
```

**Recommended Starlink Router Settings**:

1. **Static IP Reservation**: Reserve 10.0.0.242 for the Raspberry Pi's MAC address
2. **DNS Settings**: Leave as default (Pi clients will use Pi-hole anyway)
3. **UPnP**: Can be disabled (not required for Singleton)
4. **IPv6**: Disable if available (prevents leak vectors)

**Alternative: Starlink Bypass Mode**:

For advanced users, Starlink bypass mode connects directly to the terminal:

```
Starlink Terminal (100.x.x.x)
    │
    └── Your Router (10.0.0.1)
        │   • Full control over network
        │   • Can configure static routes
        │   • Better for Triangle architecture
        │
        └── Raspberry Pi (10.0.0.242)
```

### Starlink Latency Considerations

Starlink's variable latency requires some configuration adjustments:

**DNS Timeout Settings** (in `/etc/pihole/pihole-FTL.conf`):

```ini
# Increased timeout for satellite latency
TIMEOUT=10
RATE_LIMIT=1000/60
BLOCK_TTL=300
```

**Proxy Timeout Settings** (in 3x-UI):

```json
{
  "connectionIdle": 300,
  "uplinkOnly": 2,
  "downlinkOnly": 5,
  "handshake": 10
}
```

---

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| Raspberry Pi | Pi 3B+ | Pi 5 (4GB) | Pi 5 significantly faster |
| MicroSD Card | 16GB Class 10 | 32GB A2 | A2 rating for better random I/O |
| WiFi | Built-in | Built-in or USB (5GHz) | USB adapter for 5GHz support |
| Ethernet | 100Mbps | 1Gbps | Gigabit for full Starlink speeds |
| Power Supply | 5V 2.5A | 5V 5A (Pi 5) | Official PSU recommended |
| Cooling | Passive | Active (fan) | Required for sustained load |

### Software on Raspberry Pi

- **Operating System**: Raspberry Pi OS (Debian 13 "Trixie" or later)
- **Kernel**: Linux 6.1+ (for nftables support)
- **SSH**: Enabled with user account (e.g., `admin`)
- **Sudo Privileges**: User must have passwordless sudo
- **Network**: Static or DHCP-reserved IP on LAN (default: 10.0.0.242)

### Software on Control Machine

- **Operating System**: macOS, Linux, or Windows (WSL2)
- **Ansible**: 2.9+ (`pip install ansible` or `brew install ansible`)
- **SSH**: Client with key-based or password authentication
- **Python**: 3.8+ (for Ansible)
- **Git**: For cloning the repository

### Network Requirements

| Requirement | Details |
|-------------|---------|
| Internet Connection | Starlink, fibre, or any broadband |
| LAN Access | Ethernet connection to router |
| IP Address | Static or DHCP reservation for Pi |
| DNS | Not required (Pi-hole provides) |
| Ports | No inbound ports required |

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Iman/javid-mask.git
cd javid-mask/singleton/ansible
```

### 2. Configure Inventory

Edit `inventory.yml`:

```yaml
all:
  hosts:
    raspberry_pi:
      ansible_host: 10.0.0.242        # Your Pi's IP address
      ansible_user: admin              # Your Pi's username
      ansible_python_interpreter: /usr/bin/python3
      # For password auth (not recommended):
      # ansible_ssh_pass: YourPassword
      # For key auth (recommended):
      # ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 3. Review Configuration

Edit `group_vars/all.yml` for your environment:

```yaml
# WiFi Settings
wifi_ssid: "SecureProxy"              # Your preferred SSID
wifi_password: "YourStrongPassword"   # Will be auto-generated if empty
wifi_channel: 6                       # 1, 6, or 11 for 2.4GHz
wifi_country_code: GB                 # Your country code

# Network Settings (usually no changes needed)
wifi_network: 10.50.0.0/24
wifi_gateway: 10.50.0.1
dhcp_range_start: 10.50.0.10
dhcp_range_end: 10.50.0.250

# Router Network (match your Starlink setup)
router_network: 10.0.0.0/24
router_gateway: 10.0.0.1

# Security Features
block_iranian_ips: true               # Enable Iranian IP blocking
cloudflared_enabled: true             # Enable DNS-over-HTTPS
pihole_dnssec_enabled: true           # Enable DNSSEC validation
```

### 4. Test Connectivity

```bash
# Test SSH connection
ansible all -i inventory.yml -m ping

# Expected output:
# raspberry_pi | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

### 5. Run Ansible Deployment

```bash
ansible-playbook -i inventory.yml playbook.yml
```

**Deployment Progress**:

```
PLAY [Deploy Secure WiFi Proxy] ************************************************

TASK [prerequisites : Install system packages] *********************************
changed: [raspberry_pi]

TASK [network : Configure static IP] *******************************************
changed: [raspberry_pi]

TASK [hostapd : Install and configure hostapd] *********************************
changed: [raspberry_pi]

TASK [pihole : Install Pi-hole] ************************************************
changed: [raspberry_pi]

TASK [cloudflared : Install Cloudflared] ***************************************
changed: [raspberry_pi]

TASK [firewall : Configure nftables with Iranian IP blocking] ******************
changed: [raspberry_pi]

TASK [3x-ui : Install 3x-UI management panel] **********************************
changed: [raspberry_pi]

PLAY RECAP *********************************************************************
raspberry_pi               : ok=47   changed=42   failed=0
```

### 6. Reboot the Raspberry Pi

```bash
ssh admin@10.0.0.242 'sudo reboot'
```

### 7. Retrieve Credentials

After reboot, get your access credentials:

```bash
cat credentials.txt
```

**Example Output**:

```
================================================================================
DEPLOYMENT CREDENTIALS
================================================================================

WiFi Network:
  SSID: SecureProxy-a1B2c3D4
  Password: Kj8mN2pQ5rT7vX9z

Pi-hole Admin:
  URL (WiFi): http://10.50.0.1/admin
  URL (LAN): http://10.0.0.242/admin
  Password: xY3zK8mN2pQ5rT7vX9zA4bC6dE8f

3x-UI Panel:
  URL (WiFi): http://10.50.0.1:2053/
  URL (LAN): http://10.0.0.242:2053/
  Username: admin
  Password: P7qR9sT2vX4z

================================================================================
```

### 8. Connect to WiFi

1. On your device, find the WiFi network: `SecureProxy-XXXXXXXX`
2. Enter the password from `credentials.txt`
3. Verify connection: `ping 10.50.0.1`
4. Test DNS: `nslookup google.com 10.50.0.1`

---

## Configuration

### WiFi Access Point

| Parameter | Default | Description |
|-----------|---------|-------------|
| Interface | wlan0 | WiFi interface |
| Network | 10.50.0.0/24 | Isolated WiFi subnet |
| Gateway | 10.50.0.1 | Pi's WiFi IP |
| DHCP Range | 10.50.0.10-250 | Client IP pool |
| DNS Server | 10.50.0.1 | Pi-hole |
| Security | WPA2-PSK/CCMP | Encryption standard |
| Channel | 6 | WiFi channel (1, 6, or 11) |
| Country | GB | Regulatory domain |

### 3x-UI Management Panel

Access at **http://10.50.0.1:2053/** (from WiFi) or **http://10.0.0.242:2053/** (from LAN).

**Configuration Options**:

| Feature | Description |
|---------|-------------|
| Inbounds | Create VLESS/VMess/Trojan/Shadowsocks endpoints |
| Clients | Manage users with individual traffic limits |
| QR Codes | Generate codes for mobile client apps |
| Statistics | Real-time bandwidth and connection monitoring |
| Logs | View Xray-core logs for debugging |
| Settings | Configure panel security and appearance |

**Recommended Inbound Configuration**:

```json
{
  "protocol": "vless",
  "settings": {
    "clients": [
      {
        "id": "your-uuid-here",
        "flow": "xtls-rprx-vision"
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "tcp",
    "security": "reality",
    "realitySettings": {
      "show": false,
      "dest": "www.microsoft.com:443",
      "serverNames": ["www.microsoft.com"],
      "privateKey": "your-private-key",
      "shortIds": ["abcd1234"]
    }
  }
}
```

### Firewall Rules

nftables configuration at `/etc/nftables.conf`:

```nft
#!/usr/sbin/nft -f

flush ruleset

# IPv4 Filter Table
table inet filter {
    # Iranian IP blocklist (763 ranges)
    set iranian_blocklist {
        type ipv4_addr
        flags interval
        auto-merge
        elements = {
            2.144.0.0/14,      # MCI
            5.52.0.0/15,       # Shatel
            5.160.0.0/15,      # Respina
            5.200.0.0/16,      # Shatel
            31.14.80.0/20,     # Afranet
            37.32.0.0/14,      # Respina
            37.129.0.0/16,     # ParsOnline
            37.191.64.0/19,    # Mokhaberat
            ... (763 total ranges)
        }
    }

    # Input chain - traffic TO the Pi
    chain input {
        type filter hook input priority filter; policy drop;

        # Allow established connections
        ct state established,related accept

        # Allow loopback
        iifname "lo" accept

        # Allow from WiFi clients
        iifname "wlan0" accept

        # Allow SSH from LAN
        iifname "eth0" tcp dport 22 accept

        # Block Iranian IPs
        ip saddr @iranian_blocklist counter drop comment "Block Iranian inbound"

        # Allow ICMP
        ip protocol icmp accept

        # Log dropped packets (optional)
        # counter log prefix "INPUT DROP: " drop
    }

    # Forward chain - traffic THROUGH the Pi
    chain forward {
        type filter hook forward priority filter; policy drop;

        # Allow established connections
        ct state established,related accept

        # Block Iranian IPs in both directions
        ip saddr @iranian_blocklist counter drop comment "Block Iranian source"
        ip daddr @iranian_blocklist counter drop comment "Block Iranian dest"

        # Allow WiFi to Internet
        iifname "wlan0" oifname "eth0" accept

        # Allow responses back
        iifname "eth0" oifname "wlan0" ct state established,related accept
    }

    # Output chain - traffic FROM the Pi
    chain output {
        type filter hook output priority filter; policy accept;

        # Block Iranian IPs
        ip daddr @iranian_blocklist counter drop comment "Block Iranian outbound"
    }
}

# NAT Table
table ip nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;

        # Masquerade WiFi traffic
        oifname "eth0" masquerade
    }
}

# IPv6 Filter (block all)
table ip6 filter {
    chain input {
        type filter hook input priority filter; policy drop;
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
    }
    chain output {
        type filter hook output priority filter; policy drop;
    }
}
```

---

## DNS Leak Prevention

### Understanding DNS Leaks

A DNS leak occurs when DNS queries bypass your secure tunnel and are sent directly to your ISP's DNS servers. This exposes:

- Every website you visit
- Timing of your internet activity
- Your approximate location
- Your browsing patterns

### Singleton's DNS Protection

```
┌─────────────────────────────────────────────────────────────┐
│                    WiFi CLIENT                               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Application DNS Query: "what is google.com's IP?"      │ │
│  └────────────────────────────────────────────────────────┘ │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                     Pi-hole (10.50.0.1:53)                    │
│                                                               │
│  1. Check if domain is in blocklists (1.6M+ domains)         │
│     └── If blocked: Return 0.0.0.0 (query ends here)         │
│                                                               │
│  2. Check local cache                                         │
│     └── If cached: Return cached IP (query ends here)        │
│                                                               │
│  3. Forward to Cloudflared                                    │
│                           │                                   │
└───────────────────────────┼───────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                 Cloudflared (127.0.0.1:5053)                  │
│                                                               │
│  1. Encrypt DNS query with TLS 1.3                           │
│  2. Send via HTTPS to Cloudflare (1.1.1.1)                   │
│  3. Receive encrypted response                                │
│  4. Return to Pi-hole                                         │
│                                                               │
│  ISP sees: HTTPS traffic to 1.1.1.1 (encrypted)              │
│  ISP cannot see: Which domain was queried                     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Configuration Steps

#### 1. Verify Cloudflared is Running

```bash
ssh admin@10.0.0.242
sudo systemctl status cloudflared
```

**Expected Output**:

```
● cloudflared.service - cloudflared DNS-over-HTTPS proxy
     Loaded: loaded (/etc/systemd/system/cloudflared.service; enabled)
     Active: active (running) since ...
```

#### 2. Configure Xray DNS Settings

Login to 3x-UI Panel: **http://10.50.0.1:2053/**

Navigate to: **Panel Settings → Xray Configs → DNS Settings**

Configure:

```json
{
  "servers": [
    "10.50.0.1",
    "localhost"
  ],
  "queryStrategy": "UseIPv4",
  "disableCache": false,
  "disableFallback": true
}
```

#### 3. Restart Services

```bash
sudo systemctl restart x-ui
sudo systemctl restart pihole-FTL
```

#### 4. Test for DNS Leaks

**Browser Test**:

1. Connect to SecureProxy WiFi
2. Visit https://dnsleaktest.com
3. Click "Extended test"
4. Results should show only Cloudflare servers (1.1.1.1)

**Command Line Test**:

```bash
# From WiFi-connected device
nslookup -type=TXT whoami.cloudflare.com 10.50.0.1

# Should return "resolver.cloudflare.com"
```

---

## Security Hardening

### SSH Hardening

```bash
# On Raspberry Pi
sudo nano /etc/ssh/sshd_config
```

**Recommended Settings**:

```
# Disable password authentication
PasswordAuthentication no
PubkeyAuthentication yes

# Disable root login
PermitRootLogin no

# Use strong ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org

# Limit users
AllowUsers admin

# Timeout settings
ClientRezaveInterval 300
ClientRezaveCountMax 2
```

### Pi-hole Hardening

```bash
# Edit Pi-hole FTL configuration
sudo nano /etc/pihole/pihole-FTL.conf
```

**Recommended Settings**:

```ini
# Rate limiting
RATE_LIMIT=1000/60

# Privacy level (0=show everything, 3=hide everything)
PRIVACYLEVEL=0

# Block TTL
BLOCK_TTL=300

# DNS rebind protection
DNSSEC=true
REV_SERVER=false
```

### Firewall Hardening

```bash
# View current rules
sudo nft list ruleset

# Check for blocked connections
sudo journalctl -u nftables | grep "DROP"
```

### Regular Security Audits

```bash
# Check for failed SSH attempts
sudo journalctl -u ssh | grep "Failed"

# Check DNS query logs
pihole -t

# Check firewall drops
sudo nft list counters
```

---

## Troubleshooting

### WiFi Not Visible

```bash
ssh admin@10.0.0.242

# Check hostapd status
sudo systemctl status hostapd

# Check interface
ip addr show wlan0

# Check for RF kill
sudo rfkill list

# View hostapd logs
sudo journalctl -u hostapd -f
```

**Common Issues**:

| Symptom | Cause | Solution |
|---------|-------|----------|
| hostapd failed | Driver issue | Check rfkill, reboot |
| No wlan0 | WiFi disabled | `sudo rfkill unblock wifi` |
| Channel blocked | Regulatory | Change country code |

### No Internet on WiFi

```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check NAT rules
sudo nft list table ip nat

# Test upstream connectivity
ping -c 3 10.0.0.1    # Router
ping -c 3 1.1.1.1     # Internet
```

### DNS Not Resolving

```bash
# Check Pi-hole
pihole status

# Check Cloudflared
sudo systemctl status cloudflared

# Test DNS resolution
nslookup google.com 10.50.0.1
dig @10.50.0.1 example.com

# Check DNS logs
pihole -t
```

### 3x-UI Panel Not Accessible

```bash
# Check x-ui service
sudo systemctl status x-ui

# Check port binding
sudo ss -tulpn | grep 2053

# Restart service
sudo systemctl restart x-ui

# Check logs
sudo journalctl -u x-ui -f
```

### Iranian IP Blocking Not Working

```bash
# Check nftables status
sudo systemctl status nftables

# Count blocked IPs
sudo nft list set inet filter iranian_blocklist | grep -c "/"

# Test blocking
curl --connect-timeout 5 http://185.55.224.1  # Should timeout

# Reload rules
sudo systemctl reload nftables
```

---

## Maintenance

### Daily Operations

**Automatic** (configured by Ansible):

- Blocklist updates at 03:00 UTC
- Log rotation
- DNS cache management

### Weekly Tasks

```bash
# Update system packages
ssh admin@10.0.0.242
sudo apt update && sudo apt upgrade -y

# Update Pi-hole
pihole -up

# Check disk space
df -h
```

### Monthly Tasks

```bash
# Update 3x-UI
sudo x-ui update

# Rotate credentials (recommended)
# Re-run Ansible with new passwords in group_vars/all.yml

# Review logs
sudo journalctl --since "1 month ago" | grep -i error
```

### Redeploy Configuration

```bash
# Full redeploy
ansible-playbook -i inventory.yml playbook.yml

# Specific roles
ansible-playbook -i inventory.yml playbook.yml --tags firewall
ansible-playbook -i inventory.yml playbook.yml --tags pihole
ansible-playbook -i inventory.yml playbook.yml --tags 3x-ui
```

### View Logs

```bash
# All services
sudo journalctl -f

# Specific services
sudo journalctl -u hostapd -f
sudo journalctl -u pihole-FTL -f
sudo journalctl -u cloudflared -f
sudo journalctl -u x-ui -f
sudo journalctl -u nftables -f
```

### Backup Configuration

```bash
# Create backup
ssh admin@10.0.0.242 "sudo tar -czvf /tmp/singleton-backup.tar.gz \
  /etc/hostapd/ \
  /etc/pihole/ \
  /etc/nftables.conf \
  /etc/cloudflared/ \
  /usr/local/x-ui/"

# Download backup
scp admin@10.0.0.242:/tmp/singleton-backup.tar.gz ./
```

---

## Directory Structure

```
singleton/
├── ansible/
│   ├── inventory.yml              # Host configuration
│   ├── playbook.yml               # Main Ansible playbook
│   ├── group_vars/
│   │   └── all.yml                # Central configuration
│   ├── files/
│   │   └── iranian-ips.txt        # 763 Iranian IP ranges
│   └── roles/
│       ├── prerequisites/         # System packages & config
│       │   └── tasks/main.yml
│       ├── network/               # Network interface setup
│       │   ├── tasks/main.yml
│       │   └── handlers/main.yml
│       ├── hostapd/               # WiFi access point
│       │   ├── tasks/main.yml
│       │   └── templates/
│       │       ├── hostapd.conf.j2
│       │       └── dnsmasq.conf.j2
│       ├── pihole/                # DNS filtering
│       │   ├── tasks/main.yml
│       │   ├── tasks/security-hardening.yml
│       │   └── templates/
│       │       ├── setupVars.conf.j2
│       │       └── pihole-security.conf.j2
│       ├── cloudflared/           # DNS-over-HTTPS
│       │   ├── tasks/main.yml
│       │   └── templates/
│       │       └── cloudflared-config.yml.j2
│       ├── firewall/              # nftables firewall
│       │   ├── tasks/main.yml
│       │   └── templates/
│       │       ├── nftables.conf.j2
│       │       └── update-firewall.sh.j2
│       ├── 3x-ui/                 # Xray management panel
│       │   ├── tasks/main.yml
│       │   └── templates/
│       │       └── xray-dns-config.json.j2
│       └── singbox/               # Alternative proxy (optional)
│           ├── tasks/main.yml
│           └── templates/
│               └── sing-box-config.json.j2
├── diagrams/
│   ├── network-architecture.drawio
│   ├── data-flow.drawio
│   ├── deployment.drawio
│   ├── privacy-threats-defense.drawio
│   └── privacy-threats-defense-fa.drawio
├── scripts/
│   └── update-blocklists.sh
├── credentials.txt                 # Generated after deployment
├── README.md                       # This file
├── README.fa.md                    # Persian documentation
└── LICENSE                         # MIT licence
```

---

## Security Considerations

### Critical Security Practices

1. **Change Default Passwords**: Immediately change WiFi, Pi-hole, and 3x-UI passwords after deployment
2. **SSH Key Authentication**: Use SSH keys instead of passwords for all access
3. **Regular Updates**: Keep all software updated (OS, Pi-hole, 3x-UI)
4. **Monitor Logs**: Regularly check logs for suspicious activity
5. **Network Segmentation**: Keep WiFi network isolated from home LAN
6. **Physical Security**: Secure the Raspberry Pi from unauthorised access

### What This Project Does NOT Protect Against

| Threat | Reason | Mitigation |
|--------|--------|------------|
| Endpoint compromise | Malware on client devices | Use endpoint security software |
| Traffic analysis | Timing/size patterns visible | Use constant-rate padding |
| Targeted surveillance | State-level resources | Consider Tor for high-risk activities |
| Browser fingerprinting | JavaScript-based tracking | Use Tor Browser or Brave |
| Physical device access | Local access to Pi | Physical security measures |

### Recommended Additional Security

- **VPN Layer**: Consider adding WireGuard to VPS (see Triangle architecture)
- **Tor Integration**: Route sensitive traffic through Tor
- **Browser Hardening**: Use Firefox with uBlock Origin, NoScript
- **Device Security**: Keep client devices updated and secured

---

## MikroTik vs Raspberry Pi Comparison

### Why Raspberry Pi Instead of MikroTik?

| Feature | MikroTik | Raspberry Pi (Singleton) |
|---------|----------|--------------------------|
| Iranian IP Blocking | ✅ Yes (address lists + firewall) | ✅ Yes (nftables, 763 ranges) |
| WireGuard VPN | ✅ Yes (RouterOS 7+) | ✅ Yes |
| WiFi Access Point | ✅ Yes | ✅ Yes (hostapd) |
| NAT/Routing | ✅ Yes | ✅ Yes |
| IPv6 Blocking | ✅ Yes | ✅ Yes |
| Policy Routing | ✅ Yes | ✅ Yes |
| DNS Filtering (1.6M+ domains) | ❌ Limited | ✅ Yes (Pi-hole) |
| Iranian Domain Blocking (131K+) | ❌ Impractical | ✅ Yes (Pi-hole) |
| DNS-over-HTTPS | ⚠️ Limited (RouterOS 7.1+) | ✅ Full (Cloudflared) |
| VLESS/VMess/Reality Proxy | ❌ No | ✅ Yes (3x-UI/Xray) |
| Web Dashboard for DNS | ❌ No | ✅ Yes (Pi-hole admin) |
| Automatic Blocklist Updates | ❌ Manual | ✅ Automatic (cron) |

### What MikroTik CAN Do

```
MikroTik Capabilities (RouterOS 7+):
├── ✅ WireGuard tunnel to VPS
├── ✅ Iranian IP blocking (763 CIDR ranges via address lists)
├── ✅ Kill switch (policy routing + firewall)
├── ✅ IPv6 DROP
├── ✅ NAT masquerade
└── ✅ WiFi AP with WPA2
```

### What MikroTik CANNOT Do Well

```
MikroTik Limitations:
├── ❌ DNS blocklists (address list limit ~65K practical)
│   └── Cannot handle 1.6M domains + 131K Iranian domains
├── ❌ DNS-over-HTTPS (basic, not flexible)
├── ❌ VLESS/VMess/Reality protocols
├── ❌ Pi-hole style web dashboard
└── ❌ Easy blocklist management
```

### Recommendation: Hybrid Setup

For maximum protection, consider using MikroTik + Raspberry Pi together:

```
Option 1: MikroTik as WireGuard endpoint
Internet → MikroTik (WireGuard + IP blocking) → Raspberry Pi (DNS filtering) → WiFi clients

Option 2: MikroTik as router only
Internet → MikroTik (routing only) → Raspberry Pi (full security stack) → WiFi clients
```

---

## Licence

MIT Licence

Copyright (c) 2026 Iman Samizadeh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## Credits

- **Pi-hole**: https://pi-hole.net/
- **3x-UI**: https://github.com/MHSanaei/3x-ui
- **Xray-core**: https://github.com/XTLS/Xray-core
- **Cloudflared**: https://developers.cloudflare.com/
- **hostapd**: https://w1.fi/hostapd/
- **nftables**: https://netfilter.org/projects/nftables/
- **Iranian IP Lists**: herrbischoff/country-ip-blocks, community research
- **Blocklists**: StevenBlack, Firebog, BlocklistProject, Phishing Army

---

## Deployment Status

| Component | Status | Details |
|-----------|--------|---------|
| WiFi Access Point | OPERATIONAL | WPA2-PSK, Channel 6 |
| Pi-hole DNS | OPERATIONAL | 1.6M+ domains blocked |
| Cloudflared DoH | OPERATIONAL | Cloudflare 1.1.1.1 |
| Iranian IP Blocking | OPERATIONAL | 763 CIDR ranges |
| 3x-UI Panel | OPERATIONAL | VLESS/VMess ready |
| nftables Firewall | OPERATIONAL | Stateful filtering |

---

**Last Updated**: 2026-02-01
**Maintainer**: Iman Samizadeh
**Architecture**: Singleton (All-in-One Raspberry Pi)
**Upstream Router**: Starlink Terminal
