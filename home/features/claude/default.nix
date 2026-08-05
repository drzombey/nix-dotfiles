{ pkgs, lib, ... }: {

  home.packages = with pkgs; [
    claude-code
    rtk # Token-Proxy, wird vom PreToolUse-Hook in settings.json aufgerufen
    jq # von der statusLine benötigt
  ];

  # Globale Anweisungen (verweist auf RTK.md)
  home.file.".claude/CLAUDE.md".text = "@RTK.md\n";
  home.file.".claude/RTK.md".source = ./RTK.md;

  # Marker für das i-have-adhd-Plugin (always-on)
  home.file.".claude/.i-have-adhd-always".text = "";

  # settings.json muss schreibbar bleiben: Claude Code schreibt dort /config-
  # Änderungen und "immer erlauben"-Regeln hinein. Deshalb kein Symlink in den
  # Store, sondern eine Vorlage, die nur angelegt wird, wenn noch keine da ist.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.claude/settings.json" ]; then
      run mkdir -p "$HOME/.claude"
      run cp ${./settings.json} "$HOME/.claude/settings.json"
      run chmod 600 "$HOME/.claude/settings.json"
    fi
  '';

  # Nicht im Repo (Geheimnisse bzw. maschinenlokal):
  #   ~/.claude/.credentials.json  -> entsteht beim Login mit `claude`
  #   ~/.claude.json               -> MCP-Server samt Tokens, Verlauf
  #   ~/.claude/projects, history.jsonl -> Transkripte
}
