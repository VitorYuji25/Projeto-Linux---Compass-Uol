# Projeto-Linux---Compass-Uol
Primeiro Projeto de Linux - Compass Uol

## Alocação de Recursos

### VPCs

- Foram criados 1 VPC com 2 Subnets Publicas, alocadas em 2 *Avaliable Zonas* diferentes de Ohio, para casos de problemas infra estruturais
- 2 Subnets Privadas alocadas em duas *Avaliable Zonas* diferentes de Ohio

### EC2

- Foi criado uma Instancia com, AMI (Ubuntu)
- Instancia Tipo t2.micro
- E foi criado um Key Pair (Arquivo.pem).
- Security Group
    - SSH com a origem My IP;
    - HTTP com origem Anywhere;

![Tags_EC2.png](Prints_Relatório/Tags_EC2.png)

![Sec_Group_1.png](Prints_Relatório/Sec_Group_1.png)

![Sec_Group_2.png](Prints_Relatório/Sec_Group_2.png)

![AMI.png](Prints_Relatório/AMI.png)

![Instance_EC2.png](Prints_Relatório/Instance_EC2.png)

- Alocação do IP elástico;

## Conexão com a Instancia EC2

```bash
ssh -i /caminho/para/sua-chave.pem ubuntu@IP_DA_INSTANCIA

```

## Instalação e Configuração do Nginx

```bash
sudo apt update
sudo apt install nginx -y

sudo systemctl start nginx
sudo systemctl enable nginx

sudo systemctl status nginx
```

### Colocando a Página Web

Comando para passar a pasta do meu Ubuntu para a EC2:

![Mover_Webpgae.png](Prints_Relatório/Mover_Webpgae.png)

- Colocando a pagina no root do nginx da EC2:

![Pag_nginx.png](Prints_Relatório/Pag_nginx.png)

Link: http://3.147.31.252/pag_web/index.html (IP elastico não mais associado)

## Script Bash de Monitoramento

```bash
#!/bin/bash

# Configurações
WEBSITE_URL="http://localhost/index.html"  # URL que deseja monitorar
LOG_FILE="/var/log/website_monitor.log"    # Caminho do log
CHECK_INTERVAL=60                          # Tempo entre verificações (em segundos)
TELEGRAM_BOT_TOKEN="7760269204:AAEAljGaxEEly0apEmdzF6TxTqORq7qQ7_k"  # Seu token
TELEGRAM_CHAT_ID="7943142177"              # Seu ID de chat no Telegram
HTTP_TIMEOUT=10                            # Tempo limite da requisição

# Cria arquivo de log se não existir
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chown "$(whoami)":"$(whoami)" "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
fi

# Função para registrar mensagens no log
log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $message" >> "$LOG_FILE"
}

# Função para checar o site
check_website() {
    local url="$1"
    local start_time end_time response_time http_code

    start_time=$(date +%s.%N)
    if curl -s -I -m "$HTTP_TIMEOUT" "$url" >/dev/null 2>&1; then
        http_code=$(curl -s -I -m "$HTTP_TIMEOUT" -w "%{http_code}" "$url" -o /dev/null)
        end_time=$(date +%s.%N)
        response_time=$(echo "($end_time - $start_time)*1000" | bc | cut -d. -f1)
        echo "$http_code $response_time"
    else
        echo "DOWN"
    fi
}

# Função para enviar notificação via Telegram
send_telegram_alert() {
    local message="$1"
    local url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
    curl -s -X POST "$url" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message" >/dev/null
}

# Início do monitoramento
log_message "Monitoramento iniciado para $WEBSITE_URL"
send_telegram_alert "📡 Monitoramento iniciado para o site: $WEBSITE_URL"

while true; do
    result=$(check_website "$WEBSITE_URL")

    if [ "$result" != "DOWN" ]; then
        http_code=$(echo "$result" | awk '{print $1}')
        response_time=$(echo "$result" | awk '{print $2}')
        log_message "Website está no ar. Status: $http_code, Tempo de resposta: ${response_time}ms"
        send_telegram_alert "✅ O site está no ar. Status: $http_code, Tempo de resposta: ${response_time}ms"
    else
        log_message "Website fora do ar!"
        send_telegram_alert "🚨 O site $WEBSITE_URL está fora do ar!"
    fi

    sleep "$CHECK_INTERVAL"
done

```

⇒ Troca para URL do site no EC2:

```bash
#!/bin/bash

# Configurações
WEBSITE_URL="http://3.147.31.252/pag_web/index.html"  # URL que deseja monitorar
LOG_FILE="/var/log/website_monitor.log"    # Caminho do log
CHECK_INTERVAL=60                          # Tempo entre verificações (em segundos)
TELEGRAM_BOT_TOKEN="7760269204:AAEAljGaxEEly0apEmdzF6TxTqORq7qQ7_k"  # Seu token
TELEGRAM_CHAT_ID="7943142177"              # Seu ID de chat no Telegram
HTTP_TIMEOUT=10                            # Tempo limite da requisição

# Cria arquivo de log se não existir
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chown "$(whoami)":"$(whoami)" "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
fi

# Função para registrar mensagens no log
log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $message" >> "$LOG_FILE"
}

# Função para checar o site
check_website() {
    local url="$1"
    local start_time end_time response_time http_code

    start_time=$(date +%s.%N)
    if curl -s -I -m "$HTTP_TIMEOUT" "$url" >/dev/null 2>&1; then
        http_code=$(curl -s -I -m "$HTTP_TIMEOUT" -w "%{http_code}" "$url" -o /dev/null)
        end_time=$(date +%s.%N)
        response_time=$(echo "($end_time - $start_time)*1000" | bc | cut -d. -f1)
        echo "$http_code $response_time"
    else
        echo "DOWN"
    fi
}

# Função para enviar notificação via Telegram
send_telegram_alert() {
    local message="$1"
    local url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
    curl -s -X POST "$url" -d chat_id="$TELEGRAM_CHAT_ID" -d text="$message" >/dev/null
}

# Início do monitoramento
log_message "Monitoramento iniciado para $WEBSITE_URL"
send_telegram_alert "📡 Monitoramento iniciado para o site: $WEBSITE_URL"

while true; do
    result=$(check_website "$WEBSITE_URL")

    if [ "$result" != "DOWN" ]; then
        http_code=$(echo "$result" | awk '{print $1}')
        response_time=$(echo "$result" | awk '{print $2}')
        log_message "Website está no ar. Status: $http_code, Tempo de resposta: ${response_time}ms"
        send_telegram_alert "✅ O site está no ar. Status: $http_code, Tempo de resposta: ${response_time}ms"
    else
        log_message "Website fora do ar!"
        send_telegram_alert "🚨 O site $WEBSITE_URL está fora do ar!"
    fi

    sleep "$CHECK_INTERVAL"
done

```

## Bot de Monitoramento (Telegram):

- Teste com site, localmente:

![Test_Local_Telegram,_1.png](Prints_Relatório/Test_Local_Telegram,_1.png)

![Test_Local_Telegram,_2.png](Prints_Relatório/Test_Local_Telegram,_2.png)

### Teste com Site na EC2:

![Teste_EC2_Monitor.png](Prints_Relatório/Teste_EC2_Monitor.png)

![Test_EC2_Telegram.png](Prints_Relatório/Test_EC2_Telegram.png)

![Site_EC2.png](Prints_Relatório/Site_EC2.png)
