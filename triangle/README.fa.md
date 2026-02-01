<div dir="rtl" lang="fa">

# معماری مثلث: دروازه VPN با WireGuard

<div dir="ltr">

**[English](README.md)** | **[فارسی](README.fa.md)**

</div>

یک زیرساخت حریم خصوصی توزیع‌شده با استفاده از WireGuard VPN برای مسیریابی تمام ترافیک کلاینت‌های WiFi از طریق VPS. رزبری پای به عنوان یک دروازه متمرکز با فیلترینگ DNS، مسدودسازی IP‌های ایرانی و نقطه دسترسی WiFi عمل می‌کند، در حالی که VPS نقطه خروج تونل رمزشده را با Pi-hole خود فراهم می‌کند.

**نویسنده:** ایمان سمیع‌زاده
**مجوز:** MIT
**مخزن:** https://github.com/Iman/javid-mask
**آخرین بروزرسانی:** ۱۴۰۴/۱۱/۱۲

---

## فهرست مطالب

- [خلاصه اجرایی](#خلاصه-اجرایی)
- [معماری مثلث چیست](#معماری-مثلث-چیست)
- [مدل امنیتی](#مدل-امنیتی)
- [ویژگی‌ها](#ویژگی‌ها)
- [معماری](#معماری)
- [یکپارچه‌سازی با استارلینک](#یکپارچه‌سازی-با-استارلینک)
- [پیش‌نیازها](#پیش‌نیازها)
- [نصب](#نصب)
- [پیکربندی](#پیکربندی)
- [راه‌اندازی WireGuard](#راه‌اندازی-wireguard)
- [استفاده](#استفاده)
- [سخت‌سازی امنیتی](#سخت‌سازی-امنیتی)
- [عیب‌یابی](#عیب‌یابی)
- [نگهداری](#نگهداری)
- [مجوز](#مجوز)

---

## نمودارهای معماری

### معماری شبکه

![معماری شبکه مثلث](diagrams/triangle-architecture.drawio.png)

### جریان داده WireGuard

![جریان داده WireGuard مثلث](diagrams/wireguard-data-flow.drawio.png)

### حفاظت از نشت

![حفاظت از نشت مثلث](diagrams/leak-protection.drawio.png)

---

## خلاصه اجرایی

معماری **مثلث** حریم خصوصی سطح سازمانی را با توزیع سرویس‌های امنیتی در دو نود فراهم می‌کند:

1. **سرور VPS**: نقطه خروج تونل رمزشده با IP جهانی
2. **دروازه رزبری پای**: WiFi AP محلی با فیلترینگ DNS و فایروال

این معماری تضمین می‌کند:

- **تمام ترافیک از IP VPS خارج می‌شود** (نه IP خانه/استارلینک شما)
- **فیلترینگ دوگانه DNS** (Pi-hole روی هر دو پای و VPS)
- **رمزنگاری WireGuard** برای تمام ترافیک کلاینت WiFi
- **مسدودسازی IP ایرانی** در دروازه محلی
- **حفاظت Kill Switch** اگر VPN از کار بیفتد

این راه‌حل برای کاربرانی ایده‌آل است که نیاز به حداکثر حریم خصوصی، پوشش IP جغرافیایی و حفاظت از نظارت ISP دارند.

---

## معماری مثلث چیست

### سه جزء

<div dir="ltr">

```
                    ┌───────────────────────────┐
                    │         INTERNET          │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │       VPS SERVER          │
                    │   (نقطه خروج شما)         │
                    │                           │
                    │   IP: 206.189.15.223      │
                    │   موقعیت: آمستردام/لندن   │
                    │                           │
                    │   سرویس‌ها:               │
                    │   • WireGuard Server      │
                    │   • Pi-hole DNS           │
                    │   • Cloudflared DoH       │
                    │   • Health Endpoint       │
                    │                           │
                    │   ترافیک شما از این IP    │
                    │   خارج می‌شود             │
                    └─────────────┬─────────────┘
                                  │
                       WireGuard Tunnel
                       UDP Port 56821
                       (رمزشده)
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
            │     ┌───────────────▼───────────────┐    │
            │     │     STARLINK TERMINAL         │    │
            │     │     (CGNAT: 100.x.x.x)        │    │
            │     └───────────────┬───────────────┘    │
            │                     │                     │
            │     ┌───────────────▼───────────────┐    │
            │     │     STARLINK ROUTER           │    │
            │     │     (10.0.0.1)                │    │
            │     └───────────────┬───────────────┘    │
            │                     │                     │
            │     ┌───────────────▼───────────────┐    │
            │     │      RASPBERRY PI             │    │
            │     │      (Gateway)                │    │
            │     │                               │    │
            │     │  eth0: 10.0.0.242             │    │
            │     │  wlan0: 192.168.4.1           │    │
            │     │  wg0: 10.8.0.2                │    │
            │     │                               │    │
            │     │  سرویس‌ها:                   │    │
            │     │  • WireGuard Client           │    │
            │     │  • WiFi AP (hostapd)          │    │
            │     │  • Pi-hole DNS                │    │
            │     │  • nftables Firewall          │    │
            │     │  • Iranian IP Blocking        │    │
            │     │  • Kill Switch                │    │
            │     └───────────────┬───────────────┘    │
            │                     │                     │
            │          WiFi AP (WPA2-PSK)              │
            │          192.168.4.0/24                  │
            │                     │                     │
            │    ┌────────────────┼────────────────┐   │
            │    │                │                │   │
            │    ▼                ▼                ▼   │
            │ ┌──────┐       ┌──────┐       ┌──────┐  │
            │ │Phone │       │Laptop│       │Tablet│  │
            │ │.4.51 │       │.4.52 │       │.4.53 │  │
            │ └──────┘       └──────┘       └──────┘  │
            │                                          │
            └──────────────────────────────────────────┘
```

</div>

### چرا مثلث به جای سینگلتون

| ویژگی | سینگلتون | مثلث |
|-------|----------|------|
| IP خروجی | IP خانه (CGNAT استارلینک) | IP VPS (ثابت، موقعیت انتخابی) |
| قابلیت دید ISP | فقط DNS رمزشده | تونل رمزشده (بدون قابلیت دید محتوا) |
| فیلترینگ DNS | تک Pi-hole | دوگانه Pi-hole (پای + VPS) |
| تاخیر | کمتر (مستقیم) | بیشتر (+هاپ VPS) |
| پیچیدگی | ساده | متوسط |
| نیاز به VPS | خیر | بله |
| Kill Switch | غیرقابل اجرا | موجود |
| پوشش جغرافیایی | خیر | بله |

### چه زمانی از مثلث استفاده کنید

**از مثلث استفاده کنید وقتی**:

- نیاز دارید تمام ترافیک دستگاه از IP VPS خارج شود (پوشش جغرافیایی)
- نظارت ISP یک نگرانی اصلی است
- مزایای عملکرد WireGuard را نسبت به پروتکل‌های پراکسی می‌خواهید
- VPS در حوزه قضایی دوستدار حریم خصوصی در دسترس دارید
- فیلترینگ دوگانه DNS ارزش امنیتی اضافی فراهم می‌کند
- حفاظت Kill Switch مورد نیاز است

**از سینگلتون استفاده کنید وقتی**:

- VPS ندارید یا نمی‌خواهید آن را مدیریت کنید
- سادگی اولویت دارد
- فیلترینگ DNS محلی کافی است
- با خروج ترافیک از IP خانه راحت هستید

---

## خلاصه حفاظت از نشت

### وضعیت حفاظت فرضا در برابر نشت‌ها

| نوع نشت | وضعیت حفاظت | پیاده‌سازی |
|---------|-------------|------------|
| **نشت DNS** | ✅ محافظت شده | دوگانه Pi-hole (پای + VPS) → Cloudflared DoH (رمزشده) |
| **نشت IPv6** | ✅ محافظت شده | IPv6 به‌طور کامل در سطح nftables غیرفعال است (DROP تمام ترافیک ip6) |
| **نشت WebRTC** | ⚠️ نیاز به تنظیم مرورگر | نیاز به کاهش در سطح مرورگر دارد (نه سطح شبکه) |
| **نشت دامنه ایرانی** | ✅ محافظت شده | بیش از ۱۳۱,۵۷۶ دامنه در سطح DNS مسدود (bootmortis + liketolivefree) |
| **نشت IP ایرانی** | ✅ محافظت شده | ۷۶۳ رنج CIDR در سطح فایروال مسدود |
| **همبستگی کوکی** | ✅ محافظت شده | مسدودسازی دامنه‌های ایرانی از نشت کوکی به سرورهای ایرانی جلوگیری می‌کند |
| **شکست تونل** | ✅ محافظت شده | Kill switch تمام ترافیک را در صورت شکست WireGuard مسدود می‌کند |

### آنچه پوشش داده شده در مقابل آنچه نیاز به پیکربندی مرورگر دارد

<div dir="ltr">

```
NETWORK LEVEL (✅ توسط مثلث کاملاً محافظت شده):
├── DNS queries → Pi-hole (محلی) → Pi-hole (VPS) → Cloudflared DoH
├── IPv6 traffic → DROP (nftables ip6 filter)
├── Iranian IPs → DROP (nftables, 763 رنج CIDR)
├── Iranian domains → 0.0.0.0 (Pi-hole, 131,576+ دامنه)
├── All WiFi traffic → WireGuard tunnel → VPS exit
└── Kill switch → مسدود اگر تونل شکست بخورد (بدون ترافیک غیررمزشده)

BROWSER LEVEL (⚠️ کاربر باید پیکربندی کند):
├── WebRTC → غیرفعال در تنظیمات مرورگر
├── JavaScript fingerprinting → استفاده از uBlock Origin, NoScript
├── Canvas fingerprinting → Firefox resistFingerprinting
└── Cookie tracking → استفاده از افزونه Cookie AutoDelete
```

</div>

### راهنمای سخت‌سازی مرورگر

برای دستیابی به حفاظت کامل از نشت، مرورگر خود را پیکربندی کنید:

**Firefox (توصیه شده)**:

<div dir="ltr">

```
تنظیمات about:config:
├── media.peerconnection.enabled → false     (غیرفعال WebRTC)
├── media.navigator.enabled → false          (غیرفعال دستگاه‌های رسانه)
├── privacy.resistFingerprinting → true      (ضد فینگرپرینتینگ)
├── network.dns.disableIPv6 → true           (غیرفعال DNS IPv6)
├── geo.enabled → false                      (غیرفعال موقعیت‌یابی)
├── dom.battery.enabled → false              (غیرفعال API باتری)
└── privacy.trackingprotection.enabled → true
```

</div>

**افزونه‌های توصیه شده**:

| افزونه | هدف |
|--------|-----|
| uBlock Origin | مسدودسازی تبلیغ/ردیاب، کنترل WebRTC |
| NoScript | کنترل JavaScript |
| Cookie AutoDelete | پاکسازی خودکار کوکی |
| HTTPS Everywhere | اجبار اتصالات HTTPS |
| Decentraleyes | شبیه‌سازی CDN محلی |

**موبایل (Android)**:

- استفاده از **Firefox Focus** یا **Brave Browser**
- V2RayNG/Clash: فعال کردن "Block non-proxy connections"
- غیرفعال کردن WebRTC در تنظیمات مرورگر

---

## مدل امنیتی

### دفاع در عمق

معماری مثلث چندین لایه امنیتی همپوشان را در دو نود پیاده‌سازی می‌کند:

<div dir="ltr">

```
┌───────────────────────────────────────────────────────────────────┐
│                          VPS SERVER                                │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 6: EXIT POINT                                          │ │
│  │ • تمام ترافیک از IP VPS خارج می‌شود                         │ │
│  │ • پوشش IP جغرافیایی                                          │ │
│  │ • ISP نمی‌تواند سایت‌های مقصد را ببیند                       │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 5: VPS DNS FILTERING                                   │ │
│  │ • Pi-hole v6 (بیش از 1.6 میلیون دامنه مسدود)                │ │
│  │ • Cloudflared DoH (بالادست رمزشده)                           │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 4: VPS FIREWALL                                        │ │
│  │ • UFW/iptables                                               │ │
│  │ • WireGuard port (UDP 56821)                                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                              ▲
                              │ WireGuard Tunnel (رمزشده)
                              │ ChaCha20-Poly1305, Curve25519
                              │
┌─────────────────────────────┴─────────────────────────────────────┐
│                     RASPBERRY PI GATEWAY                           │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 3: WIREGUARD TUNNEL                                    │ │
│  │ • تمام ترافیک WiFi به VPS رمزشده                             │ │
│  │ • مسیریابی مبتنی بر سیاست (جدول 200)                         │ │
│  │ • Kill switch (مسدودسازی ترافیک اگر تونل بیفتد)             │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 2: LOCAL FIREWALL                                      │ │
│  │ • nftables با مسدودسازی IP ایرانی (763 رنج)                  │ │
│  │ • ردیابی اتصال Stateful                                      │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 1: LOCAL DNS FILTERING                                 │ │
│  │ • Pi-hole v6 (بیش از 1.6 میلیون دامنه مسدود)                │ │
│  │ • Cloudflared DoH                                            │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ LAYER 0: PHYSICAL ACCESS                                     │ │
│  │ • رمزنگاری WiFi با WPA2-PSK (CCMP)                          │ │
│  │ • جداسازی شبکه (192.168.4.0/24)                             │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

</div>

### مرزهای اعتماد

| جزء | سطح اعتماد | داده افشا شده | کاهش |
|-----|------------|---------------|------|
| سرور VPS | بالا | ترافیک رمزگشایی شده | ارائه‌دهنده معتبر انتخاب کنید |
| رزبری پای | کامل | تمام ترافیک محلی | امنیت فیزیکی، کلیدهای SSH |
| تونل WireGuard | کامل | بلاب‌های رمزشده | رمزنگاری مدرن |
| DNS Cloudflare | جزئی | کوئری‌های دامنه | رمزنگاری DoH |
| استارلینک/ISP | غیرقابل اعتماد | فقط تونل رمزشده | رمزنگاری WireGuard |

### استانداردهای رمزنگاری

| عملکرد | الگوریتم | اندازه کلید | استاندارد |
|--------|----------|-------------|-----------|
| تونل WireGuard | ChaCha20-Poly1305 | 256 بیت | RFC 8439 |
| تبادل کلید WireGuard | Curve25519 | 256 بیت | RFC 7748 |
| احراز هویت WireGuard | BLAKE2s | 256 بیت | RFC 7693 |
| رمزنگاری WiFi | AES-CCMP | 256 بیت | WPA2-PSK |
| DNS-over-HTTPS | TLS 1.3 | 256 بیت | RFC 8484 |

### پیاده‌سازی Kill Switch

Kill switch تضمین می‌کند که اگر تونل WireGuard بیفتد، هیچ ترافیکی نشت نکند:

<div dir="ltr">

```nft
table inet filter {
    chain output {
        type filter hook output priority filter; policy drop;

        # اجازه loopback
        oifname "lo" accept

        # اجازه برقراری WireGuard به VPS
        ip daddr 206.189.15.223 udp dport 56821 accept

        # فقط اجازه ترافیک از طریق تونل WireGuard
        oifname "wg0" accept

        # اجازه DHCP
        udp dport 67 accept
        udp sport 68 accept

        # مسدودسازی همه چیز دیگر (kill switch)
        counter drop comment "Kill switch"
    }
}
```

</div>

---

## ویژگی‌ها

### سرور VPS

- **سرور WireGuard**: تونل VPN با عملکرد بالا با رمزنگاری مدرن
- **فیلترینگ DNS با Pi-hole**: بیش از 1.6 میلیون دامنه مسدود (فیلتر ثانویه)
- **DNS-over-HTTPS**: Cloudflared کوئری‌های DNS بالادست را رمزنگاری می‌کند
- **لیست‌های مسدودی جامع**: تبلیغات، ردیاب‌ها، بدافزار، فیشینگ، دامنه‌های ایرانی
- **نقطه پایانی سلامت**: نقطه پایانی نظارت HTTP (پورت 62050)
- **فایروال UFW**: فایروال سختگیرانه با حداقل پورت‌های باز

### دروازه رزبری پای

- **کلاینت WireGuard**: تونل رمزشده به VPS با کلید از پیش مشترک
- **مسیریابی مبتنی بر سیاست**: تمام ترافیک WiFi از طریق WireGuard (جدول 200)
- **فیلترینگ DNS با Pi-hole**: DNS محلی با بیش از 1.6 میلیون مسدودی (فیلتر اولیه)
- **DNS-over-HTTPS**: Cloudflared برای DNS بالادست رمزشده
- **نقطه دسترسی WiFi**: AP رمزشده با WPA2-PSK (hostapd)
- **مسدودسازی IP ایرانی**: 763 رنج CIDR مسدود (nftables)
- **NAT Masquerade**: مسیریابی بدون درز برای کلاینت‌های WiFi
- **Kill Switch**: مسدودسازی تمام ترافیک اگر تونل WireGuard بیفتد

### ویژگی‌های امنیت شبکه

| ویژگی | موقعیت | توضیحات |
|-------|--------|---------|
| فیلترینگ دوگانه DNS | پای + VPS | دو لایه مسدودسازی دامنه |
| رمزنگاری WireGuard | تونل | تمام ترافیک انتها به انتها رمزشده |
| مسدودسازی IP ایرانی | پای | 763 رنج CIDR به صورت محلی مسدود |
| فایروال Stateful | هر دو | ردیابی اتصال روی هر دو نود |
| Kill Switch | پای | مسدودسازی ترافیک اگر تونل بیفتد |
| رمزنگاری DoH | هر دو | کوئری‌های DNS به Cloudflare رمزشده |

### لیست‌های مسدودی شامل

| دسته | منبع | دامنه‌ها | بروزرسانی |
|------|------|----------|-----------|
| میزبان‌های یکپارچه | StevenBlack/hosts | 150,000+ | روزانه |
| حریم خصوصی | EasyPrivacy | 25,000+ | هفتگی |
| تبلیغات | Prigent-Ads | 50,000+ | روزانه |
| فیشینگ | Phishing Army | 30,000+ | ساعتی |
| بدافزار | Malware Domains | 20,000+ | روزانه |
| ردیابی | BlocklistProject | 100,000+ | روزانه |
| دامنه‌های ایرانی | bootmortis/iran-hosted-domains | ۱۳۱,۵۷۶+ | هفتگی |

---

## معماری

### توپولوژی شبکه با استارلینک

<div dir="ltr">

```
┌─────────────────────────────────────────────────────────────────┐
│                          INTERNET                                │
└─────────────────────────────────┬───────────────────────────────┘
                                  │
                ┌─────────────────┴─────────────────┐
                │                                   │
    ┌───────────▼───────────┐       ┌───────────────▼───────────────┐
    │   STARLINK GATEWAY    │       │         VPS SERVER            │
    │   (Space & Ground)    │       │                               │
    │                       │       │   IP: 206.189.15.223          │
    │   • LEO Satellites    │       │   Location: Amsterdam         │
    │   • Ground Stations   │       │                               │
    │   • CGNAT (100.x.x.x) │       │   Services:                   │
    └───────────┬───────────┘       │   • WireGuard (UDP 56821)    │
                │                   │   • Pi-hole (53, 80)         │
    ┌───────────▼───────────┐       │   • Cloudflared (5053)       │
    │  STARLINK TERMINAL    │       │   • Health (62050)           │
    │  CGNAT IP: 100.x.x.x  │       │                               │
    └───────────┬───────────┘       └───────────────┬───────────────┘
                │                                   │
    ┌───────────▼───────────┐       WireGuard Tunnel
    │   STARLINK ROUTER     │       UDP 56821 (Encrypted)
    │   LAN: 10.0.0.1       │                   │
    └───────────┬───────────┘                   │
                │                               │
    ┌───────────▼───────────────────────────────┴───────────────┐
    │                                                            │
    │                      HOME NETWORK                          │
    │                      10.0.0.0/24                           │
    │                                                            │
    │   ┌────────────────────────────────────────────────────┐  │
    │   │                  RASPBERRY PI                       │  │
    │   │                  (Gateway)                          │  │
    │   │                                                     │  │
    │   │   Network Interfaces:                               │  │
    │   │   ┌─────────┬─────────────┬───────────┐            │  │
    │   │   │ eth0    │ wlan0       │ wg0       │            │  │
    │   │   │10.0.0.242│192.168.4.1 │ 10.8.0.2  │            │  │
    │   │   └─────────┴─────────────┴───────────┘            │  │
    │   │                                                     │  │
    │   │   Security Stack:                                   │  │
    │   │   • hostapd (WiFi AP)                              │  │
    │   │   • Pi-hole (DNS Filter)                           │  │
    │   │   • Cloudflared (DoH)                              │  │
    │   │   • nftables (Firewall + Iranian IPs)              │  │
    │   │   • WireGuard (VPN Client)                         │  │
    │   │   • Health Check (Kill Switch)                     │  │
    │   │                                                     │  │
    │   │   Traffic Flow:                                     │  │
    │   │   WiFi → Pi-hole → nftables → wg0 → VPS → Internet │  │
    │   └─────────────────────────────────────────────────────┘  │
    │                           │                                │
    │                    WiFi AP (WPA2-PSK)                      │
    │                    SSID: TriangleSecure                    │
    │                    Network: 192.168.4.0/24                 │
    │                           │                                │
    │      ┌────────────────────┼────────────────────┐          │
    │      │                    │                    │          │
    │      ▼                    ▼                    ▼          │
    │  ┌────────┐          ┌────────┐          ┌────────┐      │
    │  │ Phone  │          │ Laptop │          │ Tablet │      │
    │  │ .4.51  │          │ .4.52  │          │ .4.53  │      │
    │  └────────┘          └────────┘          └────────┘      │
    │                                                            │
    └────────────────────────────────────────────────────────────┘
```

</div>

### جریان ترافیک

**حل DNS**:

<div dir="ltr">

```
WiFi Client → Pi-hole (192.168.4.1:53)
    ├── بررسی لیست مسدودی (1.6M+)
    │   └── اگر مسدود: برگرداندن 0.0.0.0
    │
    └── اگر مجاز: Cloudflared (DoH)
        └── Cloudflare 1.1.1.1 (رمزشده)
```

</div>

**ترافیک داده**:

<div dir="ltr">

```
WiFi Client → nftables (Pi)
    ├── بررسی لیست مسدودی ایرانی
    ├── Drop اگر تطابق
    └── NAT masquerade → wg0
        └── VPS WireGuard Server
            └── Pi-hole VPS → Internet
```

</div>

### سرویس‌های فعال

**سرور VPS**:

| سرویس | پورت | پروتکل | عملکرد |
|-------|------|--------|--------|
| WireGuard | 56821 | UDP | سرور تونل VPN |
| Pi-hole | 53 | UDP/TCP | فیلترینگ DNS |
| Pi-hole | 80 | HTTP | ادمین وب |
| Cloudflared | 5053 | DoH | DNS-over-HTTPS |
| Health | 62050 | HTTP | نقطه پایانی نظارت |
| SSH | 22 | TCP | مدیریت راه دور |

**رزبری پای**:

| سرویس | پورت | پروتکل | عملکرد |
|-------|------|--------|--------|
| hostapd | - | 802.11 | WiFi AP |
| Pi-hole | 53 | UDP/TCP | فیلترینگ DNS |
| Cloudflared | 5053 | DoH | DNS-over-HTTPS |
| WireGuard | - | - | کلاینت VPN |
| nftables | - | - | فایروال |

---

## یکپارچه‌سازی با استارلینک

### ویژگی‌های شبکه استارلینک

**درک استارلینک برای استفاده VPN**:

| ویژگی | تأثیر | مدیریت مثلث |
|-------|-------|-------------|
| CGNAT (100.x.x.x) | بدون port forwarding | VPS هیچ اتصالی به خانه آغاز نمی‌کند |
| IP پویا | IP به طور مکرر تغییر می‌کند | WireGuard roaming را مدیریت می‌کند |
| تاخیر متغیر | 20-100ms معمول | WireGuard برای این طراحی شده |
| بدون IPv6 | فعلاً فقط IPv4 | IPv6 در پیکربندی غیرفعال |
| از دست دادن بسته | گاهی drops | WireGuard retransmission را مدیریت می‌کند |

**چرا مثلث با استارلینک خوب کار می‌کند**:

1. **فقط خروجی**: کلاینت WireGuard اتصال را آغاز می‌کند (نیازی به port forwarding نیست)
2. **پروتکل UDP**: WireGuard از UDP استفاده می‌کند (بهتر برای ماهواره)
3. **Roaming داخلی**: WireGuard تغییرات IP را به طور خودکار مدیریت می‌کند
4. **پروتکل کارآمد**: حداقل سربار برای پهنای باند ماهواره

### پیکربندی خاص استارلینک

**پیکربندی WireGuard برای استارلینک**:

<div dir="ltr">

```ini
# /etc/wireguard/wg0.conf (روی رزبری پای)

[Interface]
PrivateKey = <pi-private-key>
Address = 10.8.0.2/32
DNS = 1.1.1.1, 1.0.0.1
# MTU کاهش یافته برای سربار ماهواره
MTU = 1280

[Peer]
PublicKey = <vps-public-key>
PresharedKey = <preshared-key>
AllowedIPs = 0.0.0.0/0
Endpoint = 206.189.15.223:56821
# Keepalive برای عبور از NAT (مهم برای CGNAT)
PersistentKeepalive = 25
```

</div>

**چرا این تنظیمات**:

| تنظیم | مقدار | دلیل |
|-------|-------|------|
| MTU | 1280 | محافظه‌کارانه برای کپسوله‌سازی ماهواره |
| PersistentKeepalive | 25 | حفظ mapping NAT از طریق CGNAT |
| DNS | 1.1.1.1 | پشتیبان اگر Pi-hole در دسترس نباشد |

---

## پیش‌نیازها

### نیازمندی‌های سخت‌افزاری

**سرور VPS**:

| نیازمندی | حداقل | پیشنهادی |
|----------|-------|----------|
| RAM | 512MB | 1GB+ |
| ذخیره‌سازی | 10GB | 20GB |
| پهنای باند | 500GB/ماه | بدون محدودیت |
| موقعیت | هر جا | دوستدار حریم خصوصی (NL, CH, IS) |
| IPv4 | الزامی | IP ثابت |
| OS | Debian 11+ | Debian 12/Ubuntu 22.04 |

**رزبری پای**:

| نیازمندی | حداقل | پیشنهادی |
|----------|-------|----------|
| مدل | Pi 3B+ | Pi 5 (4GB) |
| ذخیره‌سازی | 16GB microSD | 32GB A2 microSD |
| WiFi | داخلی | داخلی یا USB 5GHz |
| اترنت | 100Mbps | گیگابیت |
| تغذیه | 5V 2.5A | 5V 5A (Pi 5) |

### نیازمندی‌های نرم‌افزاری

**ماشین کنترل** (لپ‌تاپ شما):

- Ansible 2.9+ (`brew install ansible` یا `pip install ansible`)
- کلاینت SSH با احراز هویت کلید
- Python 3.8+
- Git

---

## نصب

### مرحله 1: آماده‌سازی VPS

<div dir="ltr">

```bash
ssh root@206.189.15.223
apt update && apt upgrade -y
apt install curl wget git python3 python3-pip -y
```

</div>

### مرحله 2: آماده‌سازی رزبری پای

<div dir="ltr">

```bash
ssh admin@10.0.0.242
sudo apt update && sudo apt upgrade -y
sudo apt install python3 python3-pip -y
```

</div>

### مرحله 3: نصب Ansible (ماشین کنترل)

<div dir="ltr">

```bash
# macOS
brew install ansible

# Ubuntu/Debian
sudo apt install ansible sshpass -y
```

</div>

### مرحله 4: کلون مخزن

<div dir="ltr">

```bash
git clone https://github.com/Iman/javid-mask.git
cd javid-mask/triangle/ansible
```

</div>

### مرحله 5: پیکربندی Inventory

ویرایش `inventory.yml`:

<div dir="ltr">

```yaml
all:
  children:
    proxy_server:
      hosts:
        vps:
          ansible_host: 206.189.15.223
          ansible_user: root

    local_gateway:
      hosts:
        raspberry_pi:
          ansible_host: 10.0.0.242
          ansible_user: admin
          ansible_become: yes
```

</div>

### مرحله 6: پیکربندی متغیرها

ویرایش `group_vars/all.yml`:

<div dir="ltr">

```yaml
# پیکربندی VPS
vps_ip: 206.189.15.223

# پیکربندی WireGuard
wireguard_enabled: true
wireguard_port: 56821
wireguard_network: "10.8.0.0/24"
wireguard_server_address: "10.8.0.1/24"
wireguard_pi_address: "10.8.0.2/32"
wireguard_mtu: 1280  # محافظه‌کارانه برای استارلینک

# تنظیمات WiFi
wifi_ssid: "TriangleSecure"
wifi_password: "YourSecurePassword"
wifi_channel: 6
wifi_country_code: GB

# شبکه WiFi (زیرشبکه ایزوله)
wifi_network: 192.168.4.0/24
wifi_gateway: 192.168.4.1

# ویژگی‌های امنیتی
block_iranian_ips: true
kill_switch_enabled: true
```

</div>

### مرحله 7: تولید کلیدهای WireGuard

<div dir="ltr">

```bash
# تولید کلیدهای سرور
wg genkey | tee server_private.key | wg pubkey > server_public.key

# تولید کلیدهای پای
wg genkey | tee pi_private.key | wg pubkey > pi_public.key

# تولید کلید از پیش مشترک
wg genpsk > preshared.key

# افزودن به group_vars/all.yml
# حذف امن فایل‌های کلید
shred -u *.key
```

</div>

### مرحله 8: استقرار

<div dir="ltr">

```bash
# تست اتصال
ansible all -i inventory.yml -m ping

# ابتدا VPS را مستقر کنید
ansible-playbook -i inventory.yml playbook.yml --limit proxy_server

# پای را مستقر کنید
ansible-playbook -i inventory.yml playbook.yml --limit local_gateway
```

</div>

### مرحله 9: تایید استقرار

<div dir="ltr">

```bash
# بررسی WireGuard VPS
ssh root@206.189.15.223 "wg show"

# بررسی WireGuard پای
ssh admin@10.0.0.242 "sudo wg show"

# تایید تونل
ssh admin@10.0.0.242 "ping -c 3 10.8.0.1"
```

</div>

---

## استفاده

### اتصال به WiFi

1. SSID را پیدا کنید: `TriangleSecure-XXXXXXXX`
2. رمز عبور از `credentials.txt` را وارد کنید
3. تمام ترافیک به طور خودکار از طریق VPS مسیریابی می‌شود

### تایید اتصال VPN

<div dir="ltr">

```bash
# بررسی IP خارجی (باید IP VPS را نشان دهد)
curl https://ifconfig.me
# مورد انتظار: 206.189.15.223

# تست نشت DNS
# بازدید: https://dnsleaktest.com
# باید فقط DNS Cloudflare را نشان دهد
```

</div>

### دسترسی به پنل‌های ادمین

| پنل | URL | اعتبارنامه‌ها |
|-----|-----|--------------|
| Pi-hole VPS | http://206.189.15.223/admin | از credentials.txt |
| Pi-hole پای | http://192.168.4.1/admin | از credentials.txt |

---

## عیب‌یابی

### WireGuard متصل نمی‌شود

<div dir="ltr">

```bash
# بررسی وضعیت WireGuard پای
sudo wg show wg0

# اگر handshake نباشد، بررسی کنید:
# 1. فایروال VPS اجازه UDP 56821 را می‌دهد
ssh root@206.189.15.223 "ufw status | grep 56821"

# 2. کلیدها مطابقت دارند
# 3. Endpoint صحیح است

# راه‌اندازی مجدد WireGuard
sudo systemctl restart wg-quick@wg0
```

</div>

### بدون اینترنت روی کلاینت‌های WiFi

<div dir="ltr">

```bash
# بررسی IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # باید 1 باشد

# بررسی مسیریابی سیاستی
ip rule show
ip route show table 200

# بررسی NAT
sudo nft list table ip nat

# تایید تونل
ping -c 3 10.8.0.1
```

</div>

### Kill Switch فعال شده

اگر اینترنت قطع شد اما WiFi کار می‌کند:

<div dir="ltr">

```bash
# بررسی وضعیت WireGuard
sudo wg show wg0

# بررسی لاگ‌های سلامت
sudo journalctl -u health-check -f

# راه‌اندازی مجدد دستی تونل
sudo systemctl restart wg-quick@wg0
```

</div>

---

## نگهداری

### بروزرسانی سیستم‌ها

<div dir="ltr">

```bash
# VPS
ssh root@206.189.15.223
apt update && apt upgrade -y
pihole -up

# پای
ssh admin@10.0.0.242
sudo apt update && sudo apt upgrade -y
pihole -up
```

</div>

### بروزرسانی لیست‌های مسدودی

<div dir="ltr">

```bash
# روی هر دو VPS و پای
pihole -g
```

</div>

### استقرار مجدد

<div dir="ltr">

```bash
# استقرار کامل
ansible-playbook -i inventory.yml playbook.yml

# نقش‌های خاص
ansible-playbook -i inventory.yml playbook.yml --tags pi-wireguard
ansible-playbook -i inventory.yml playbook.yml --tags pi-firewall
```

</div>

### مشاهده لاگ‌ها

<div dir="ltr">

```bash
# VPS
journalctl -u wg-quick@wg0 -f
journalctl -u pihole-FTL -f

# پای
sudo journalctl -u wg-quick@wg0 -f
sudo journalctl -u pihole-FTL -f
sudo journalctl -u hostapd -f
```

</div>

---

## ساختار دایرکتوری

<div dir="ltr">

```
triangle/
├── ansible/
│   ├── inventory.yml
│   ├── playbook.yml
│   ├── group_vars/
│   │   └── all.yml
│   ├── files/
│   │   ├── iranian-ips.txt
│   │   └── blocklists/
│   └── roles/
│       ├── vps-prerequisites/
│       ├── vps-wireguard/
│       ├── vps-pihole/
│       ├── vps-cloudflared/
│       ├── vps-firewall/
│       ├── vps-health-endpoint/
│       ├── pi-prerequisites/
│       ├── pi-network/
│       ├── pi-hostapd/
│       ├── pi-pihole/
│       ├── pi-wireguard/
│       ├── pi-firewall/
│       └── pi-health-check/
├── diagrams/
├── credentials.txt
├── README.md
└── README.fa.md
```

</div>

---

## مقایسه MikroTik و رزبری پای

### چرا رزبری پای به جای MikroTik؟

برخی کاربران ممکن است بپرسند آیا روتر MikroTik می‌تواند همان محافظت را فراهم کند. در حالی که MikroTik سخت‌افزار شبکه عالی است، محدودیت‌های حیاتی برای این مورد استفاده حفاظت از حریم خصوصی دارد:

| ویژگی | MikroTik | رزبری پای | برنده |
|-------|----------|------------|-------|
| **مسدودسازی DNS (بیش از ۱.۶ میلیون دامنه)** | ❌ حداکثر ~۱۰۰ هزار | ✅ بیش از ۱.۶ میلیون بدون محدودیت | رزبری پای |
| **مسدودسازی دامنه ایرانی (۱۳۱ هزار+)** | ❌ منابع ناکافی | ✅ کامل | رزبری پای |
| **فیلترینگ دوگانه DNS (پای + VPS)** | ❌ پیچیده‌تر | ✅ آسان با دو Pi-hole | رزبری پای |
| **DNS-over-HTTPS (DoH)** | ⚠️ محدود (فقط v7+) | ✅ کامل (Cloudflared) | رزبری پای |
| **WireGuard VPN** | ✅ پشتیبانی می‌شود | ✅ پشتیبانی کامل | مساوی |
| **مسدودسازی IP ایرانی (۷۶۳ CIDR)** | ✅ پشتیبانی می‌شود | ✅ پشتیبانی می‌شود | مساوی |
| **Kill Switch** | ⚠️ پیکربندی دستی | ✅ خودکار | رزبری پای |
| **ابزارهای مدیریت وب** | ✅ WebFig/WinBox | ✅ پنل‌های Pi-hole | مساوی |
| **مصرف برق** | ✅ ~۵W | ⚠️ ~۱۰-۱۵W | MikroTik |
| **هزینه** | ~۵۰-۱۰۰ دلار | ~۸۰-۱۲۰ دلار (Pi 5 + کارت SD) | مساوی |
| **انعطاف نرم‌افزار** | ⚠️ RouterOS محدود | ✅ لینوکس کامل | رزبری پای |

### محدودیت‌های کلیدی MikroTik

**۱. محدودیت لیست مسدودی DNS**

دستگاه‌های MikroTik دارای محدودیت سخت‌افزاری روی ورودی‌های DNS regex هستند:
- مدل‌های سطح ورودی: ~۱۰,۰۰۰ ورودی
- مدل‌های میان‌رده: ~۵۰,۰۰۰ ورودی
- مدل‌های پیشرفته: ~۱۰۰,۰۰۰ ورودی

مورد استفاده ما نیاز دارد:
- لیست‌های مسدودی Pi-hole: بیش از ۱.۶ میلیون دامنه
- دامنه‌های ایرانی: بیش از ۱۳۱,۵۷۶ دامنه
- **کل**: نیاز به ظرفیت بیش از ۱.۷ میلیون دامنه

**۲. پیچیدگی فیلترینگ دوگانه DNS**

معماری مثلث از دو Pi-hole استفاده می‌کند (یکی روی پای، یکی روی VPS). با MikroTik:
- نیاز به سرویس DNS جداگانه روی VPS
- پیکربندی پیچیده‌تر
- همگام‌سازی لیست‌های مسدودی دشوارتر

**۳. محدودیت‌های DoH**

- فقط RouterOS v7+ از DoH پشتیبانی می‌کند
- پیکربندی پیچیده‌تر از Cloudflared
- عملکرد کمتر تحت بار سنگین

### چه زمانی MikroTik پیشنهاد می‌شود

MikroTik برای موارد زیر مناسب است:
- ✅ فیلترینگ ساده DNS (هزاران دامنه، نه میلیون‌ها)
- ✅ مسیریابی WireGuard/IPsec
- ✅ مدیریت پهنای باند و QoS
- ✅ شبکه‌های سازمانی با سوییچینگ پیشرفته
- ✅ پیاده‌سازی‌هایی که فقط به مسدودسازی IP نیاز دارند

برای سناریوی خاص ما (حفاظت هویت استارلینک با فیلترینگ DNS جامع، دامنه‌های ایرانی و VPN WireGuard)، **رزبری پای تنها گزینه عملی است**.

---

## ملاحظات امنیتی

### آنچه مثلث در برابرش حفاظت می‌کند

| تهدید | حفاظت |
|-------|-------|
| نظارت ISP | تمام ترافیک از طریق WireGuard رمزشده |
| ردیابی مبتنی بر IP | ترافیک از IP VPS خارج می‌شود |
| نشت DNS | دوگانه Pi-hole + DoH |
| ردیابی IP ایرانی | 763 رنج CIDR مسدود |
| همبستگی دامنه ایرانی | بیش از ۱۳۱,۵۷۶ دامنه مسدود (حفاظت هویت) |
| شکست تونل | Kill switch ترافیک غیررمزشده را مسدود می‌کند |

### جلوگیری از حمله همبستگی هویت

**تهدید افشای هویت استارلینک**:

وقتی کاربری با استارلینک (IP خارجی) به‌طور تصادفی از وب‌سایت ایرانی بازدید می‌کند، هویتش از طریق کوکی‌ها، فینگرپرینت مرورگر یا جلسات ورود قابل همبستگی است.

**دفاع چندلایه مثلث**:

1. **لایه DNS (Pi-hole)**: مسدودسازی بیش از ۱۳۱,۵۷۶ دامنه ایرانی در سطح DNS
2. **لایه IP (nftables)**: مسدودسازی ۷۶۳ رنج IP ایرانی
3. **لایه خروج (VPS)**: تمام ترافیک از VPS خارج می‌شود، نه IP خانه

**منابع دامنه ایرانی**:

| منبع | دامنه‌ها | توضیحات |
|------|---------|---------|
| bootmortis/iran-hosted-domains | ۱۳۱,۵۷۶+ | رجیستری جامع دامنه ایرانی |
| liketolivefree/iran_domain-ip | ~۵۰,۰۰۰ | دامنه‌های ایرانی اضافی |
| **ترکیبی** | ~۱۸۰,۰۰۰ | کل دامنه‌های منحصربه‌فرد مسدود |

### آنچه مثلث در برابرش حفاظت نمی‌کند

| تهدید | دلیل | کاهش |
|-------|------|------|
| دسترسی ارائه‌دهنده VPS | آنها سرور را کنترل می‌کنند | ارائه‌دهنده معتبر انتخاب کنید |
| آلودگی نقطه پایانی | بدافزار روی دستگاه‌ها | امنیت نقطه پایانی |
| تحلیل ترافیک | الگوهای زمان‌بندی قابل مشاهده | Tor برای پرخطر |

---

## مجوز

مجوز MIT - حق نسخه‌برداری (c) ۲۰۲۶ ایمان سمیع‌زاده

---

## اعتبارات

- **WireGuard**: https://www.wireguard.com/
- **Pi-hole**: https://pi-hole.net/
- **Cloudflared**: https://developers.cloudflare.com/
- **nftables**: https://netfilter.org/projects/nftables/

---

## وضعیت استقرار

| جزء | وضعیت | جزئیات |
|-----|-------|--------|
| WireGuard VPS | عملیاتی | UDP 56821 |
| Pi-hole VPS | عملیاتی | بیش از 1.6 میلیون دامنه |
| Health VPS | عملیاتی | پورت 62050 |
| WireGuard پای | عملیاتی | تونل فعال |
| WiFi AP پای | عملیاتی | WPA2-PSK |
| Pi-hole پای | عملیاتی | بیش از 1.6 میلیون دامنه |
| مسدودسازی ایرانی | عملیاتی | 763 رنج |
| Kill Switch | عملیاتی | فعال |

---

**نگهدارنده**: ایمان سمیع‌زاده
**معماری**: مثلث (دروازه VPN با WireGuard)
**روتر بالادست**: ترمینال استارلینک

</div>
