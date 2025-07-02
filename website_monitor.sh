#!/bin/bash

# === CONFIGURAÇÕES ===
#SITE="http://localhost/"   # Site a ser monitorado
SITE="http://IP_INSTANCE/pag_web/index.html"
INTERVALO=60                                    # Intervalo entre verificações (segundos)
LOG="/var/log/website_monitor.log"              # Caminho do arquivo de log
BOT_TOKEN="..."
CHAT_ID="..."

# === MENSAGEM DE INÍCIO ===
echo "Monitorando $SITE..." >> "$LOG" 2>&1
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" -d text="📡 Iniciando monitoramento do site: $SITE" > /dev/null 2>&1

# === LOOP DE MONITORAMENTO ===
while true; do
  HORA=$(date +"%H:%M:%S")

  # Faz a requisição com timeout de 10s
  STATUS=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" "$SITE")

  # Se não recebeu resposta, trata como fora do ar ou erro
  if [ -z "$STATUS" ] || [ "$STATUS" != "200" ]; then
    echo "$HORA - Site fora do ar! (Status: ${STATUS:-sem resposta})" >> "$LOG" 2>&1
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d text="🚨 [$HORA] O site $SITE está FORA DO AR! (Status: ${STATUS:-sem resposta})" > /dev/null 2>&1
  else
    echo "$HORA - Site no ar (Status: $STATUS)" >> "$LOG" 2>&1
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d text="✅ [$HORA] O site $SITE está NO AR (Status: $STATUS)" > /dev/null 2>&1
  fi

  # Aguarda próximo ciclo
  sleep "$INTERVALO"
done
