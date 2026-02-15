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