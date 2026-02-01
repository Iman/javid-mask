# Javid Mask - Privacy Protection Suite for Starlink Users in Iran

**[English](README.md)** | **[فارسی](README.fa.md)**

A comprehensive suite of Ansible-automated privacy protection solutions using Raspberry Pi, designed to protect Starlink users in Iran from identity correlation attacks.

**Author:** Iman Samizadeh
**Licence:** MIT
**Repository:** https://github.com/Iman/javid-mask
**Last Updated:** 2026-02-01

---

## The Problem: Identity Correlation Attack

When a Starlink user in Iran accidentally visits an Iranian website, their identity can be exposed through cookies, browser fingerprints, or login sessions:

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

**The risk**: Iranian authorities can identify Starlink users by correlating:
- Same cookies/fingerprints + foreign IP = Starlink user identified
- Login sessions from foreign IPs = identity exposed
- Browser fingerprints (Canvas, WebGL) identify devices across IPs

---

## The Solution: Three Privacy Architectures

This project provides three complementary architectures, each offering different levels of protection:

| Architecture | [Sifter](#sifter-dns-only) | [Singleton](#singleton-wifi-ap--proxy) | [Triangle](#triangle-wifi-ap--vpn) |
|--------------|--------|-----------|----------|
| **Complexity** | Simple | Moderate | Advanced |
| **Primary Use** | DNS Server | WiFi Gateway | VPN Gateway |
| **WiFi Access Point** | ❌ | ✅ | ✅ |
| **Proxy (VLESS/VMess)** | ❌ | ✅ | ❌ |
| **VPN (WireGuard)** | ❌ | ❌ | ✅ |
| **Traffic Encryption** | DNS only | Full (via proxy) | Full (via VPN) |
| **Exit IP** | Your IP | Your IP | VPS IP |
| **Kill Switch** | ❌ | ❌ | ✅ |
| **VPS Required** | ❌ | ❌ | ✅ |
| **DNS Filtering** | 1.6M+ | 1.6M+ | 3.2M+ (double) |
| **Iranian Domains Blocked** | 131K+ | 131K+ | 131K+ |
| **Iranian IPs Blocked** | 763 CIDRs | 763 CIDRs | 763 CIDRs |

---

## Project Architectures

### Sifter (DNS-Only)

**[View Sifter Documentation →](sifter/README.md)**

The simplest architecture - a pure DNS server that all your home devices point to.

**Best for:**
- Users wanting minimal setup
- Protecting all devices on existing network
- DNS-level blocking only

**Features:**
- Pi-hole DNS filtering (1.6M+ domains)
- Iranian domain blocking (131,576+ domains)
- Iranian IP blocking (763 CIDRs)
- DNS-over-HTTPS (Cloudflare)
- IPv6 leak prevention

```
Home Devices → DNS to Pi → Pi-hole → Cloudflared → Internet
                              ↓
                    Iranian domains blocked
```

---

### Singleton (WiFi AP + Proxy)

**[View Singleton Documentation →](singleton/README.md)**

A self-contained WiFi access point with built-in proxy support for VLESS/VMess protocols.

**Best for:**
- Users needing isolated WiFi network
- Proxy protocol support (anti-DPI)
- Single-device deployment

**Features:**
- Isolated WiFi network (10.50.0.0/24)
- Pi-hole DNS filtering (1.6M+ domains)
- 3x-UI/Xray proxy (VLESS/VMess/Reality)
- Iranian IP/domain blocking
- DNS-over-HTTPS

```
WiFi Clients → WiFi AP → Pi-hole → nftables → Xray Proxy → Internet
                            ↓           ↓
                    DNS filtered   Iranian IPs blocked
```

---

### Triangle (WiFi AP + VPN)

**[View Triangle Documentation →](triangle/README.md)**

A distributed architecture with WireGuard VPN tunnel to a VPS, providing IP masking and kill switch.

**Best for:**
- Maximum privacy protection
- Geographic IP masking
- ISP surveillance protection

**Features:**
- WireGuard VPN tunnel to VPS
- Double Pi-hole (Pi + VPS)
- All traffic exits via VPS IP
- Kill switch (blocks if tunnel fails)
- Iranian IP/domain blocking on both nodes

```
WiFi Clients → WiFi AP → Pi-hole → WireGuard → VPS Pi-hole → Internet
                            ↓                       ↓
                    DNS filtered (2x)      Traffic exits via VPS IP
```

---

## Protection Comparison

### Leak Protection Matrix

| Leak Type | Sifter | Singleton | Triangle |
|-----------|--------|-----------|----------|
| **DNS Leak** | ✅ DoH | ✅ DoH | ✅ Double DoH |
| **IPv6 Leak** | ✅ Disabled | ✅ Disabled | ✅ Disabled |
| **Iranian Domain** | ✅ 131K+ | ✅ 131K+ | ✅ 131K+ |
| **Iranian IP** | ✅ 763 CIDRs | ✅ 763 CIDRs | ✅ 763 CIDRs |
| **Cookie Correlation** | ✅ Blocked | ✅ Blocked | ✅ Blocked |
| **WebRTC Leak** | ⚠️ Browser | ⚠️ Browser | ⚠️ Browser |
| **IP Masking** | ❌ | ❌ | ✅ VPS IP |
| **Kill Switch** | ❌ | ❌ | ✅ |
| **DPI Resistance** | ❌ | ✅ Reality | ✅ WireGuard |

### Network vs Browser Protection

All architectures protect at the **network level** (automatic), but some threats require **browser configuration** (manual):

```
NETWORK LEVEL (Automatic):
├── DNS filtering (Pi-hole)
├── Iranian domain blocking (131K+)
├── Iranian IP blocking (763 CIDRs)
├── DNS encryption (DoH)
└── IPv6 blocking

BROWSER LEVEL (User must configure):
├── WebRTC leak prevention
├── Canvas/WebGL fingerprinting
├── Cookie management
└── JavaScript fingerprinting
```

---

## MikroTik vs Raspberry Pi Comparison

Some users may ask if a MikroTik router can provide the same protection. While MikroTik is excellent networking hardware, it has critical limitations for this privacy protection use case:

| Feature | MikroTik | Raspberry Pi | Winner |
|---------|----------|--------------|--------|
| **DNS Blocking (1.6M+ domains)** | ❌ Max ~100K | ✅ 1.6M+ unlimited | Raspberry Pi |
| **Iranian Domain Blocking (131K+)** | ❌ Insufficient resources | ✅ Full support | Raspberry Pi |
| **DNS-over-HTTPS (DoH)** | ⚠️ Limited (v7+ only) | ✅ Full (Cloudflared) | Raspberry Pi |
| **VLESS/VMess Proxy** | ❌ Not supported | ✅ Xray with Reality | Raspberry Pi |
| **Reality Protocol (Anti-DPI)** | ❌ Not supported | ✅ Full support | Raspberry Pi |
| **WireGuard VPN** | ✅ Supported | ✅ Full support | Tie |
| **Double DNS Filtering** | ❌ Complex | ✅ Easy (Pi + VPS) | Raspberry Pi |
| **Iranian IP Blocking (763 CIDRs)** | ✅ Supported | ✅ Supported | Tie |
| **Web Management** | ✅ WebFig/WinBox | ✅ Pi-hole/3x-UI | Tie |
| **Power Consumption** | ✅ ~5W | ⚠️ ~10-15W | MikroTik |
| **Cost** | ~$50-100 | ~$80-120 (Pi 5 + SD) | Tie |
| **Software Flexibility** | ⚠️ RouterOS limited | ✅ Full Linux | Raspberry Pi |

### Key MikroTik Limitations

**1. DNS Blocklist Capacity**

MikroTik devices have hardware limits on DNS regex entries:
- Entry-level models: ~10,000 entries
- Mid-range models: ~50,000 entries
- High-end models: ~100,000 entries

Our use case requires:
- Pi-hole blocklists: 1.6M+ domains
- Iranian domains: 131,576+ domains
- **Total**: Need 1.7M+ domain capacity

**2. No Proxy Protocol Support**

MikroTik cannot:
- Run VLESS/VMess proxies
- Implement Reality protocol (anti-DPI)
- Act as Xray endpoint
- Provide application-layer obfuscation

**3. DoH Limitations**

- Only RouterOS v7+ supports DoH
- More complex configuration than Cloudflared
- Lower performance under heavy load

### When MikroTik Is Suitable

MikroTik is excellent for:
- ✅ Simple DNS filtering (thousands, not millions)
- ✅ WireGuard/IPsec routing
- ✅ Bandwidth management and QoS
- ✅ Enterprise networks with advanced switching
- ✅ Implementations needing IP blocking only

**For our specific scenario** (Starlink identity protection with comprehensive DNS filtering, Iranian domains, and proxy obfuscation), **Raspberry Pi is the only practical choice**.

---

## Quick Start

### Choose Your Architecture

1. **[Sifter](sifter/README.md)** - If you want DNS-only protection with minimal setup
2. **[Singleton](singleton/README.md)** - If you want WiFi AP with proxy support
3. **[Triangle](triangle/README.md)** - If you want maximum protection with VPN and kill switch

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Raspberry Pi | Pi 3B+ | Pi 5 (4GB) |
| MicroSD Card | 16GB Class 10 | 32GB A2 |
| Ethernet | 100Mbps | 1Gbps |
| Power Supply | 5V 2.5A | 5V 5A (Pi 5) |
| VPS (Triangle only) | 512MB RAM | 1GB+ RAM |

### Software Requirements

- Raspberry Pi OS (Debian 13 "Trixie" or newer)
- Ansible 2.9+ on control machine
- SSH access to Raspberry Pi

---

## Directory Structure

```
javid-mask/
├── README.md                 # This file
├── README.fa.md              # Persian documentation
│
├── sifter/                   # DNS-Only Architecture
│   ├── README.md
│   ├── README.fa.md
│   ├── ansible/
│   └── diagrams/
│
├── singleton/                # WiFi AP + Proxy Architecture
│   ├── README.md
│   ├── README.fa.md
│   ├── ansible/
│   └── diagrams/
│
└── triangle/                 # WiFi AP + VPN Architecture
    ├── README.md
    ├── README.fa.md
    ├── ansible/
    └── diagrams/
```

---

## Iranian Domain & IP Sources

All architectures use the same comprehensive blocklists:

| Source | Type | Count | Updates |
|--------|------|-------|---------|
| bootmortis/iran-hosted-domains | Domains | 131,576+ | Weekly |
| liketolivefree/iran_domain-ip | Domains | ~50,000 | Weekly |
| herrbischoff/country-ip-blocks | IPs | 763 CIDRs | Daily |

---

## Browser Hardening (Required for All Architectures)

Network-level protection blocks Iranian connections, but browser-level threats require manual configuration:

### Firefox (Recommended)

```
about:config settings:
├── media.peerconnection.enabled → false     (Disable WebRTC)
├── privacy.resistFingerprinting → true      (Anti-fingerprinting)
├── network.dns.disableIPv6 → true           (Disable IPv6 DNS)
├── geo.enabled → false                      (Disable geolocation)
└── privacy.trackingprotection.enabled → true
```

### Recommended Extensions

| Extension | Purpose |
|-----------|---------|
| uBlock Origin | Ad/tracker blocking, WebRTC control |
| NoScript | JavaScript control |
| Cookie AutoDelete | Automatic cookie cleanup |

---

## Licence

MIT Licence

Copyright (c) 2026 Iman Samizadeh

---

## Credits

- **Pi-hole**: https://pi-hole.net/
- **WireGuard**: https://www.wireguard.com/
- **3x-UI/Xray**: https://github.com/MHSanaei/3x-ui
- **Cloudflared**: https://developers.cloudflare.com/
- **Iranian Domains**: https://github.com/bootmortis/iran-hosted-domains
- **Iranian IPs**: https://github.com/herrbischoff/country-ip-blocks

---

**Maintainer**: Iman Samizadeh
**Project**: javid-mask (Starlink Privacy Protection Suite)
