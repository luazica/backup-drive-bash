```instalação do script:
git clone https://github.com/luazica/backup-drive-bash.git
```

# como usar pela primeira vez.
1. antes de tudo, tornar o arquivo executável com "sudo chmod +x backup.sh".
2. ao executar pela primeira vez com "./backup.sh", será criado um arquivo de configurações, lá deverá ser inserido os caminhos de pastas e alguns parâmetros para a execução agendada do script.
3. após a instalação do rclone, ele iniciará o ajuste de configurações dele. digite "n" pra criar uma nova conexão remota de armazenamento. nomeie a conexão de "gdrive"; digite 22 para selecionar o google drive como opção de armazenamento; após isso, ignore a option client_id e o client_secret; digite 1 para total acesso aos arquivos do google drive; negue a service_account_file; aceite a ultima opção para logar o seu google drive no rclone; negue o shared drive; e por fim, digite y para salvar as alterações e FINALMENTE conseguir fazer o backup de sua pasta com apenas uma linha de comando no terminal!!

ta veno nem foi dificil :<
