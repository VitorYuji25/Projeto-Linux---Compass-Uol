#!/bin/bash

# === CONFIGURAÇÕES ===
SITE="http://3.147.31.252/pag_web/index.html"   # Site a ser monitorado
INTERVALO=60                                    # Intervalo entre verificações (segundos)
LOG="/tmp/monitor_site.log"                     # Caminho do arquivo de log
BOT_TOKEN="..."
CHAT_ID="..."

# === MENSAGEM DE INÍCIO ===
echo "Monitorando $SITE..." | tee -a "$LOG"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" -d text="📡 Iniciando monitoramento do site: $SITE"

# === LOOP DE MONITORAMENTO ===
while true; do
  HORA=$(date +"%H:%M:%S")

  # Faz a requisição com timeout de 10s
  STATUS=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" "$SITE")

  # Se não recebeu resposta, trata como fora do ar
  if [ -z "$STATUS" ] || [ "$STATUS" != "200" ]; then
    echo "$HORA - Site fora do ar! (Status: ${STATUS:-sem resposta})" | tee -a "$LOG"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d text="🚨 [$HORA] O site $SITE está FORA DO AR! (Status: ${STATUS:-sem resposta})"
  else
    echo "$HORA - Site no ar (Status: $STATUS)" | tee -a "$LOG"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d text="✅ [$HORA] O site $SITE está NO AR (Status: $STATUS)"
  fi

  # Aguarda próximo ciclo
  sleep "$INTERVALO"
done

