#!/usr/bin/env bash
# =============================================================================
# SCRIPT  : nom_du_script.sh
# DESC    : Ce que fait le script en une ligne
# USAGE   : ./nom_du_script.sh <arg1> <arg2>
# AUTHOR  : MAGASSA Djiguiba
# DATE    : 2026-05-04
# VERSION : 1.0.0
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# CONSTANTES
# =============================================================================

readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.sh}_${TIMESTAMP}.log"

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}" | tee -a "$LOG_FILE"; }
info()    { log "INFO " "$*"; }
warn()    { log "WARN " "$*" >&2; }
die()     { log "ERROR" "$*" >&2; exit 1; }
success() { log "OK   " "$*"; }

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <arg1> <arg2>

Arguments:
  arg1    Description de l'argument 1
  arg2    Description de l'argument 2

Options:
  -h      Afficher cette aide

Exemples:
  $SCRIPT_NAME hosts.txt output.csv
EOF
    exit 0
}

cleanup() {
    info "Nettoyage..."
    # rm -f "$TMP_FILE"
}

# =============================================================================
# VALIDATION
# =============================================================================

check_dependencies() {
    local deps=("awk" "grep" "cut")
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || die "Dépendance manquante : $dep"
    done
}

validate_args() {
    [[ $# -ne 2 ]]  && { usage; }
    [[ ! -f "$1" ]] && die "Fichier introuvable : $1"
    [[ ! -r "$1" ]] && die "Fichier non lisible : $1"
}

# =============================================================================
# LOGIQUE METIER
# =============================================================================

do_something() {
    local input="$1"
    local result

    result=$(some_command "$input") || die "Échec de some_command sur : $input"

    echo "$result"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local input_file="$1"
    local output_file="$2"

    info "Démarrage de $SCRIPT_NAME"
    check_dependencies

    echo "col1;col2;col3" > "$output_file"

    while IFS= read -r line; do
        [[ -z "$line" || "$line" == "hostname" ]] && continue

        local result
        result=$(do_something "$line") || { warn "Échec sur : $line — on continue"; continue; }

        echo "$line;$result" >> "$output_file"

    done < "$input_file"

    success "Terminé. Résultat dans : $output_file"
}

# =============================================================================
# ENTRYPOINT
# =============================================================================

trap cleanup EXIT
trap 'die "Interruption reçue (SIGINT)"'  INT
trap 'die "Terminaison reçue (SIGTERM)"' TERM

[[ "${1:-}" == "-h" ]] && usage

validate_args "$@"
main "$@"
