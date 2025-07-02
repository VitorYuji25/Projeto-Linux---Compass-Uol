#!/bin/bash
# === Atualiza e instala pacotes ===
apt update -y && apt upgrade -y
apt install nginx curl -y

# === Cria página HTML ===
mkdir -p /var/www/html/pag_web
echo "<html><body><h1>Página Web EC2</h1></body></html>" > /var/www/html/pag_web/index.html

# === Instala screen para rodar monitoramento em segundo plano ===
apt install screen -y

# === Cria script de monitoramento ===
cat <<EOF > /usr/local/bin/site_monitor.sh
#!/bin/bash

# === CONFIGURAÇÕES ===
SITE="http://3.147.31.252/pag_web/index.html"   # Site a ser monitorado
INTERVALO=60                                    # Intervalo entre verificações (segundos)
LOG="/tmp/monitor_site.log"                     # Caminho do arquivo de log
BOT_TOKEN="SEU_BOT_TOKEN"
CHAT_ID="SEU_CHAT_ID"

# === MENSAGEM DE INÍCIO ===
echo "Monitorando \$SITE..." | tee -a "\$LOG"
curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \\
  -d chat_id="\$CHAT_ID" -d text="📡 Iniciando monitoramento do site: \$SITE"

# === LOOP DE MONITORAMENTO ===
while true; do
  HORA=\$(date +"%H:%M:%S")

  STATUS=\$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" "\$SITE")

  if [ -z "\$STATUS" ] || [ "\$STATUS" != "200" ]; then
    echo "\$HORA - Site fora do ar! (Status: \${STATUS:-sem resposta})" | tee -a "\$LOG"
    curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \\
      -d chat_id="\$CHAT_ID" \\
      -d text="🚨 [\$HORA] O site \$SITE está FORA DO AR! (Status: \${STATUS:-sem resposta})"
  else
    echo "\$HORA - Site no ar (Status: \$STATUS)" | tee -a "\$LOG"
    curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \\
      -d chat_id="\$CHAT_ID" \\
      -d text="✅ [\$HORA] O site \$SITE está NO AR (Status: \$STATUS)"
  fi

  sleep "\$INTERVALO"
done
EOF

# === Permissões de execução ===
chmod +x /usr/local/bin/site_monitor.sh

# === Executa o monitoramento em segundo plano com screen ===
screen -dmS monitoramento bash /usr/local/bin/site_monitor.sh

# === Inicia e habilita Nginx ===
systemctl enable nginx
systemctl start nginx
