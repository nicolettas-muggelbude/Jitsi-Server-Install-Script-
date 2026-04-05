#!/bin/bash

# --- Konfiguration ---
EXPECTED_DOMAIN="meet.deine-domain.de"  # Ersetze mit deiner Domain
ADMIN_EMAIL="admin@deine-domain.de"     # Ersetze mit deiner Admin-E-Mail

# --- Hostname-Prüfung ---
echo "Prüfe Hostname..."
CURRENT_HOSTNAME=$(hostname -f)
if [ "$CURRENT_HOSTNAME" != "$EXPECTED_DOMAIN" ]; then
    echo "Fehler: Hostname ist nicht korrekt gesetzt."
    echo "Aktuell: $CURRENT_HOSTNAME"
    echo "Erwartet: $EXPECTED_DOMAIN"
    echo ""
    echo "Bitte setze den Hostnamen mit:"
    echo "  echo \"meet\" | sudo tee /etc/hostname"
    echo "  echo \"<SERVER_IP> $EXPECTED_DOMAIN meet\" | sudo tee -a /etc/hosts"
    echo "  sudo hostname -F /etc/hostname"
    exit 1
fi
echo "Hostname ist korrekt: $CURRENT_HOSTNAME"

# --- DNS-Prüfung ---
echo "Prüfe DNS-Auflösung..."
DNS_IP=$(dig +short "$EXPECTED_DOMAIN" | tail -n1)
SERVER_IP=$(curl -s ifconfig.me)
if [ "$DNS_IP" != "$SERVER_IP" ]; then
    echo "Fehler: DNS-Eintrag für $EXPECTED_DOMAIN zeigt nicht auf die Server-IP."
    echo "DNS-IP:   $DNS_IP"
    echo "Server-IP: $SERVER_IP"
    exit 1
fi
echo "DNS-Eintrag ist korrekt: $EXPECTED_DOMAIN -> $DNS_IP"

# --- SSL-Prüfung (Port 443) ---
echo "Prüfe SSL-Zertifikat..."
if ! timeout 5 openssl s_client -connect "$EXPECTED_DOMAIN":443 -servername "$EXPECTED_DOMAIN" -showcerts 2>/dev/null | openssl x509 -noout -dates | grep -q "notAfter"; then
    echo "Kein gültiges SSL-Zertifikat für $EXPECTED_DOMAIN gefunden."
    echo "Installiere zunächst ein Zertifikat mit Certbot (wird später im Skript angeboten)."
else
    echo "SSL-Zertifikat für $EXPECTED_DOMAIN ist vorhanden."
fi

# --- Systemupdate und Abhängigkeiten ---
echo "Führe Systemupdate durch..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y \
    apt-transport-https \
    curl \
    gnupg2 \
    software-properties-common \
    openjdk-17-jre-headless \
    nginx \
    fail2ban \
    certbot \
    python3-certbot-nginx

# --- Jitsi-Repository hinzufügen ---
echo "Füge Jitsi-Repository hinzu..."
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

# --- Jitsi installieren ---
echo "Installiere Jitsi Meet..."
sudo apt update -y
sudo apt install -y jitsi-meet

# --- SSL-Zertifikat mit Certbot (falls noch nicht vorhanden) ---
if [ ! -f "/etc/letsencrypt/live/$EXPECTED_DOMAIN/fullchain.pem" ]; then
    echo "Beantrage Let's Encrypt-Zertifikat..."
    sudo certbot --nginx -d "$EXPECTED_DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"
    sudo systemctl restart nginx
else
    echo "SSL-Zertifikat ist bereits vorhanden."
fi

# --- Firewall konfigurieren ---
echo "Konfiguriere Firewall..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp
sudo ufw allow 22/tcp
sudo ufw --force enable

# --- Dienste neu starten ---
echo "Starte Dienste neu..."
sudo systemctl restart nginx
sudo systemctl restart jitsi-videobridge2
sudo systemctl restart jicofo
sudo systemctl restart prosody

# --- Fertig ---
echo ""
echo "Jitsi Meet ist jetzt installiert und erreichbar unter:"
echo "https://$EXPECTED_DOMAIN"
