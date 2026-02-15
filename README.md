# UbuntuServer_Router
Proyecto personal de configuración servidor Ubuntu como router, con monitoreo de DHCP y DNS

# Implementación | Descripción General
Este proyecto documenta la implementación de un servidor Ubuntu configurado como router de red.
El servidor proporciona servicios de DHCP, DNS, NAT y monitoreo de tráfico para una red local.

- El servidor es administrado remotamente desde una máquina cliente independiente.

# Objetivos principales
1. Configurar Ubuntu Server como router funcional
2. Implementar servicio DHCP utilizando dnsmasq
3. Configurar reenvío y registro de consultas DNS
4. Habilitar NAT usando iptables
5. Monitorear consultas DNS en tiempo real

# Topología de Red
Interfaz WAN (enp1s0): Conectada a módem mediante cable UTP
Interfaz LAN (wlp2s0): Red 172.16.10.0/24
Puerta de enlace: 172.16.10.1
Rango DHCP: 172.16.10.2 – 172.16.10.52

       Internet
      |
       192.168.0.1
      |
      [enp1s0] 192.168.0.50
      |
      Servidor Router
      |
      [wlp2s0] 172.16.10.1
      |
      Clientes WiFi (172.16.10.0/24)

# Servicios Implementados
> dnsmasq: Proporciona servicio DHCP y reenvío DNS para la red LAN.

> iptables: Implementa NAT (MASQUERADE) y permite el reenvío de paquetes entre LAN y WAN.

> Scripts en Bash para monitoreo de logs DNS y DHCP

# Archivos de Configuración Relevantes
> /etc/netplan/50-cloud-init.yaml

      network:
        version: 2

     ethernets:
       enp1s0:
         dhcp4: false
         addresses:
           - 192.168.0.50/24
         routes:
           - to: default
             via: 192.168.0.1
         nameservers:
           addresses:
             - 192.168.0.1
             - 8.8.8.8
          
> /etc/systemd/network/10-wlp2s0.network

      [Match]
      Name=wlp2s0

      [Network]
      Address=172.16.10.1/24

> /etc/hostapd/hostapd.conf

      interface=wlp2s0
      driver=nl80211

      ssid=YourSSID
      hw_mode=g
      channel=6
      country_code=YourCountry
      
      wmm_enabled=1
      auth_algs=1
      ignore_broadcast_ssid=0
      
      wpa=2
      wpa_passphrase=YourPassword
      wpa_key_mgmt=WPA-PSK
      rsn_pairwise=CCMP

> /etc/dnsmasq.conf

      interface=wlp2s0
      bind-interfaces
      port=53
      
      server=8.8.8.8
      server=1.1.1.1
      
      dhcp-range=172.16.10.2,172.16.10.52,12h
      dhcp-option=3,172.16.10.1
      dhcp-option=6,172.16.10.1,{dns_server}
      
      log-queries
      log-dhcp

# Reglas de iptables
NAT MASQUERADE
iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE

> Cuando un cliente WiFi (por ejemplo 172.16.10.44) intenta salir a internet:
Su IP privada no puede circular en internet, por lo que, la regla MASQUERADE reemplaza esa IP por la IP del servidor en la WAN (192.168.0.50).

> El tráfico sale correctamente hacia internet a través del módem del ISP.
> Las respuestas regresan al servidor, luego el servidor redirige la respuesta al cliente original.

Esto es lo que permite que múltiples dispositivos compartan una sola conexión a internet.

# Scripts personalizados de monitoreo

> /routing/scrits/dhcp.sh

      #!/bin/bash

      LOGFILE="/var/log/dnsmasq.log"
      
      if [ ! -f "$LOGFILE" ]; then
          echo "Archivo de log $LOGFILE no existe. Verifica la configuración de dnsmasq."
          exit 1
      fi
      
      echo "[+] Monitoreo conexiones DHCP en tiempo real desde $LOGFILE"
      echo "-----------------------------------------------------------------------"
      # Cabecera con separadores
      printf "| %-19s | %-14s | %-29s |\n" "Fecha y Hora" "IP" "Nombre del Dispositivo"
      echo "-----------------------------------------------------------------------"
      
      tail -F "$LOGFILE" | grep --line-buffered "DHCPACK" | while read -r linea; do
          FECHA=$(date "+%Y-%m-%d %H:%M:%S")
          IP=$(echo "$linea" | sed -n 's/.*DHCPACK([^)]*) \([^ ]*\) [^ ]* \(.*\)$/\1/p')
          DISPOSITIVO=$(echo "$linea" | sed -n 's/.*DHCPACK([^)]*) [^ ]* [^ ]* \(.*\)$/\1/p')
      
          # Imprimir filas con divisores
          printf "| %-19s | %-14s | %-29s |\n" "$FECHA" "$IP" "$DISPOSITIVO"
      done

> /routing/scripts/dns.sh

      #!/bin/bash
      
      LOGFILE="/var/log/dnsmasq.log"
      
      if [ ! -f "$LOGFILE" ]; then
          echo "Archivo de log $LOGFILE no existe. Verifica la configuración de dnsmasq."
          exit 1
      fi
      
      echo "[+] Monitoreo DNS en tiempo real desde $LOGFILE"
      echo "-------------------------------------------------------------------------------"
      # Cabecera con separadores
      printf "| %-19s | %-15s | %-40s |\n" "Fecha y Hora" "IP Origen" "Dominio Consultado"
      echo "-------------------------------------------------------------------------------"
      
      tail -F "$LOGFILE" | grep --line-buffered "query" | while read -r linea; do
          FECHA=$(date "+%Y-%m-%d %H:%M:%S")
          DOMINIO=$(echo "$linea" | sed -n 's/.*query\[[^]]*\] \([^ ]*\) from .*/\1/p')
          IP_ORIGEN=$(echo "$linea" | sed -n 's/.*from \([^ ]*\).*/\1/p')
      
          printf "| %-19s | %-15s | %-40s |\n" "$FECHA" "$IP_ORIGEN" "$DOMINIO"
      done

-- Scripts proporcionados por ChatGPT --

# Comandos Útiles

> networkctl status wlp2s0

      ● 3: wlp2s0
                         Link File: /usr/lib/systemd/network/99-default.link
                      Network File: /etc/systemd/network/10-wlp2s0.network
                             State: routable (configured)
                      Online state: online
                              Type: wlan
                              Path: pci-0000:02:00.0
                            Driver: iwlwifi
                            Vendor: Intel Corporation
                             Model: Wireless 8260
                  Hardware Address: 14:ab:c5:a0:77:65 (Intel Corporate)
                               MTU: 1500 (min: 256, max: 2304)
                             QDisc: noqueue
      IPv6 Address Generation Mode: eui64
                Wi-Fi access point: LABORATORIO (00:00:00:00:00:00)
          Number of Queues (Tx/Rx): 1/1
                           Address: 172.16.10.1
                                    fe80::16ab:c5ff:fea0:7765
                 Activation Policy: up
               Required For Online: yes

> sudo lshw -short

      H/W path           Device     Class          Description
      ========================================================
      /0/100/1c.7/0      wlp2s0     network        Wireless 8260
