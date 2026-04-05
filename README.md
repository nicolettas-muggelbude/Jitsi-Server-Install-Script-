# Jitsi-Server-Install-Script
Insallations-Script für Jitsi auf Ubuntu 24.04 Server. On Prem und Cloud

##H inweis:

- Das Skript ist für eine frische Ubuntu Server 24.04.4-Installation ausgelegt.
- Für beispielsweise Hetzner Cloud musst du ggf. die Firewall-Regeln anpassen oder die Hetzner Firewall entsprechend konfigurieren.
- Das Skript setzt sudo-Rechte voraus.
--

## Anleitung zur Verwendung:

### DNS-Konfiguration:**

Stelle sicher, dass der Hostname des Servers (hostname -f) auf eine öffentliche IP zeigt (z. B. über einen A- oder AAAA-Eintrag).
Für beispielsweise Hetzner Cloud: Nutze die Hetzner DNS-Verwaltung oder einen externen DNS-Anbieter.

### Skript herunterladen und ausführbar machen:
```bash
wget https://raw.githubusercontent.com/nicolettas-muggelbude/jitsi-install.sh
chmod +x jitsi-install.sh
```

### Editiere und Ersetze:
meet.deine-domain.de und admin@deine-domain.de mit deinen tatsächlichen Werten.
```bash
# --- Konfiguration ---
EXPECTED_DOMAIN="meet.deine-domain.de"  # Ersetze mit deiner Domain
ADMIN_EMAIL="admin@deine-domain.de"     # Ersetze mit deiner Admin-E-Mail
```

Beispiel mit nano:
```bash
nano ./jitsi-install.sh
```

### Skript mit sudo ausführen:
```bash
sudo install ./jitsi-install.sh
```

### Das Skript prüft:

- Hostname (hostname -f)
- DNS-Auflösung (dig + ifconfig.me)
- SSL-Zertifikat (Port 443)

**Falls kein SSL-Zertifikat vorhanden ist** installiert das Skript automatisch eines mit Certbot.
