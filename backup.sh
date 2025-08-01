#!/bin/bash

CONFIG_FILE="$(dirname "$0")/backup_sh.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'EOF'
# diretório a ser feito backup
DIR=""

# diretório do script de backup
SCRIPT_DIR=""

# pasta de backups locais
LOCAL_BACKUPS=""

# dias para manter backups (0 para não apagar)
CLEAN_DAYS=

# configurações do agendamento
# use * para deixar vazio
MINUTE=""
HOUR=""
DAY=""
MONTH=""
WEEKDAY=""
CRON_LINE="$MINUTE $HOUR $DAY $MONTH $WEEKDAY $SCRIPT_DIR/backup.sh"

# pasta de backup no google drive
RCLONE_REMOTE="gdrive:Backup"
EOF
    exit 1
fi
source "$CONFIG_FILE"

(crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab - >/dev/null 2>&1
data=$(date +"[ %Y/%m/%d | %H:%M:%S ]::")
log="$LOCAL_BACKUPS/backup_log.log"
archive_backup="$LOCAL_BACKUPS/backup_$(date +"%Y-%m-%d").tar.gz"

mkdir -p "$LOCAL_BACKUPS"

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
        $SCRIPT_DIR/backup.sh
    fi
else
    echo "backup não sucedido!"
    echo "$data[ERRO]: houve uma falha ao fazer backup!" >> "$log"
    exit 1
fi
