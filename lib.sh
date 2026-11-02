# Funções comuns ao Linux (systemd) e ao macOS (launchd). Lido por plantao e rodar.sh.
# Funciona no bash 3.2 que vem no macOS.

SO="$(uname -s)"   # Linux | Darwin

# sed -i que funciona com o sed do GNU e com o do macOS
sed_i() { local f="${*: -1}"; sed -i.plantao-bak "$@" && rm -f "$f.plantao-bak"; }

# Horário HH:MM de um timestamp
hora_de() { date -d "@$1" '+%H:%M' 2>/dev/null || date -r "$1" '+%H:%M'; }

novo_uuid() { python3 -c 'import uuid; print(uuid.uuid4())'; }

# Trava de uma execução por quest. Linux: flock. macOS: pasta de trava com o PID do dono.
travar() {
  local base="$1"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$base.lock"
    flock -n 9
    return
  fi
  local dir="$base.lockdir" pid
  if ! mkdir "$dir" 2>/dev/null; then
    pid="$(cat "$dir/pid" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then return 1; fi
    rm -rf "$dir"
    mkdir "$dir" 2>/dev/null || return 1
  fi
  echo $$ > "$dir/pid"
  TRAVA_DIR="$dir"
  trap 'rm -rf "$TRAVA_DIR"' EXIT
}

# ---------- serviço por quest ----------
# Linux: plantao@<nome>.service (systemd do usuário)
# macOS: ~/Library/LaunchAgents/com.kanz.plantao.<nome>.plist (launchd), criado no "ligar"

rotulo_mac() { echo "com.kanz.plantao.$1"; }
plist_mac() { echo "$HOME/Library/LaunchAgents/$(rotulo_mac "$1").plist"; }

escrever_plist() {
  local nome="$1" raiz="$2" plist
  plist="$(plist_mac "$nome")"
  mkdir -p "$(dirname "$plist")" /tmp/plantao
  # caffeinate -is impede o Mac de dormir enquanto a quest roda (com a tampa fechada, só na tomada e com monitor)
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$(rotulo_mac "$nome")</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/caffeinate</string><string>-is</string>
    <string>$raiz/rodar.sh</string><string>$nome</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ThrottleInterval</key><integer>5</integer>
  <key>StandardOutPath</key><string>/tmp/plantao/$nome.servico.log</string>
  <key>StandardErrorPath</key><string>/tmp/plantao/$nome.servico.log</string>
</dict>
</plist>
EOF
}

# Liga agora e a cada login
servico_ligar() {
  local nome="$1" raiz="$2"
  if [ "$SO" = Darwin ]; then
    escrever_plist "$nome" "$raiz"
    launchctl bootout "gui/$(id -u)/$(rotulo_mac "$nome")" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$(plist_mac "$nome")"
  else
    systemctl --user enable --now "plantao@$nome"
  fi
}

# Para agora (no Linux continua habilitado; no macOS o próximo login roda e sai, pois a quest não está ativa)
servico_parar() {
  if [ "$SO" = Darwin ]; then
    launchctl bootout "gui/$(id -u)/$(rotulo_mac "$1")" 2>/dev/null || true
  else
    systemctl --user stop "plantao@$1" 2>/dev/null || true
  fi
}

# Para e não volta no próximo login
servico_desligar() {
  if [ "$SO" = Darwin ]; then
    servico_parar "$1"
    rm -f "$(plist_mac "$1")"
  else
    systemctl --user disable --now "plantao@$1"
  fi
}

# active | inactive (mesmas palavras do systemd)
servico_estado() {
  if [ "$SO" = Darwin ]; then
    if launchctl print "gui/$(id -u)/$(rotulo_mac "$1")" 2>/dev/null | grep -q 'state = running'; then
      echo active
    else
      echo inactive
    fi
  else
    systemctl --user is-active "plantao@$1" 2>/dev/null || true
  fi
}
