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