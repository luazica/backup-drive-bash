#!/bin/bash
CONFIG_FILE="$(dirname "$0")/backup.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# ------------------------ CONFIGURAÇÕES DE BACKUP -------------------------

# CAMINHO COMPLETO do diretório a ser feito backup (ex: /home/seu_user/documentos)
DIR=""

# CAMINHO COMPLETO da pasta de backups locais (ex: /home/seu_user/.backups) | caso não exista, será criada automaticamente
LOCAL_BACKUPS=""

# dias para manter backups (0 para não apagar; padrão = 7 dias)
CLEAN_DAYS=7

# configurações do agendamento | padrão = as 2:00AM às segundas-feiras
# use * para deixar vazio | em weekday, domingo="0" ->...-> sábado="6" | não mexa na cron_line
MINUTE="0"
HOUR="2"
DAY="*"
MONTH="*"
WEEKDAY="1"
CRON_LINE="$MINUTE $HOUR $DAY $MONTH $WEEKDAY $DIR/backup.sh"

# pasta de backup no google drive
RCLONE_REMOTE="gdrive:Backup"
EOF
    nano $CONFIG_FILE
    echo "CONFIGURAÇÕES SALVAS!"
    ./backup.sh
    exit 0
fi
source "$CONFIG_FILE"
mkdir -p "$LOCAL_BACKUPS"

(crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab - >/dev/null 2>&1
data=$(date +"[ %Y/%m/%d | %H:%M:%S ]::")
log="$LOCAL_BACKUPS/backup_log.log"
archive_backup="$LOCAL_BACKUPS/backup_$(date +"%Y-%m-%d").tar.gz"


if [ "$CLEAN_DAYS" -gt 0 ]; then
    find "$LOCAL_BACKUPS" -name "backup_*.tar.gz" -mtime +"$CLEAN_DAYS" -delete
fi

if tar -czPf "$archive_backup" "$DIR"; then
    tamanho=$(du -h "$archive_backup" | cut -f1)
    echo "backup concluído com sucesso!"
    echo "$data[SUCESSO]: backup concluído com êxito! - $tamanho - $archive_backup" >> "$log"

    rclone mkdir "$RCLONE_REMOTE"
    rclone delete "$RCLONE_REMOTE" --min-age "${CLEAN_DAYS}d"
    rclone copy "$archive_backup" "$RCLONE_REMOTE/"
    out=$?

    if [ $out -eq 0 ]; then
        echo "backup foi enviado com sucesso ao google drive!"
        echo -e "$data[SUCESSO]: backup enviado ao google drive com sucesso!\n" >> "$log"
    elif [ $out -eq 127 ]; then
        echo -e "$data[ERRO]: houve uma falha ao enviar o backup ao google drive\n" >> "$log"
        sudo -v ; curl https://rclone.org/install.sh | sudo bash
        rclone config
        ./backup.sh
    else
        rclone config
    fi
else
    echo "backup não sucedido!"
    echo "$data[ERRO]: houve uma falha ao fazer backup!" >> "$log"
    exit 1
fi
