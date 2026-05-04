# Bash — Bonnes pratiques & Template

> Auteur : MAGASSA Djiguiba  
> Date : 2026-05-04  
> Version : 1.0

---

## Table des matières

1. [Options de sécurité](#1-options-de-sécurité)
2. [Variables](#2-variables)
3. [Fonctions](#3-fonctions)
4. [Gestion des erreurs](#4-gestion-des-erreurs)
5. [Lecture de fichiers](#5-lecture-de-fichiers)
6. [Validation](#6-validation)
7. [Lisibilité](#7-lisibilité)
8. [Récapitulatif rapide](#8-récapitulatif-rapide)
9. [Template complet](#9-template-complet)

---

## 1. Options de sécurité

Toujours mettre en début de script :

```bash
set -euo pipefail
IFS=$'\n\t'
```

| Option | Effet |
|---|---|
| `-e` | Stoppe le script si une commande échoue |
| `-u` | Stoppe si une variable non définie est utilisée |
| `-o pipefail` | Stoppe si une commande dans un pipe échoue |
| `IFS=$'\n\t'` | Évite les problèmes de découpage sur les espaces |

---

## 2. Variables

```bash
# ✅ Toujours quoter
echo "$ma_variable"

# ✅ Constantes en MAJUSCULES avec readonly
readonly LOG_FILE="/var/log/script.log"

# ✅ Variables locales dans les fonctions
ma_fonction() {
    local nom="$1"
}

# ❌ Ne jamais faire
echo $ma_variable       # risque de word splitting
VAR=$(commande)         # sans local dans une fonction
```

---

## 3. Fonctions

```bash
# ✅ Retourner une valeur via echo + capture
get_valeur() {
    local input="$1"
    echo "résultat_de_$input"
}

result=$(get_valeur "test")

# ❌ Ne pas utiliser de variables globales implicites
ma_fonction() {
    global_var="quelque chose"  # fragile, éviter
}
```

**Règles :**
- Une fonction = une responsabilité
- Toujours déclarer les variables avec `local`
- Valider les arguments en entrée
- Retourner les valeurs via `echo`, pas via des globales

---

## 4. Gestion des erreurs

```bash
# Fonctions utilitaires de logging
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}" | tee -a "$LOG_FILE"; }
info()    { log "INFO " "$*"; }
warn()    { log "WARN " "$*" >&2; }
die()     { log "ERROR" "$*" >&2; exit 1; }
success() { log "OK   " "$*"; }

# Nettoyage automatique à la sortie
cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT
trap 'die "Interruption reçue (SIGINT)"'  INT
trap 'die "Terminaison reçue (SIGTERM)"' TERM
```

---

## 5. Lecture de fichiers

```bash
# ✅ while read — robuste, gère les espaces et lignes vides
while IFS= read -r line; do
    [[ -z "$line" ]] && continue   # ignorer lignes vides
    echo "$line"
done < "$fichier"

# ❌ for + cat — problèmes si espaces dans les lignes
for line in $(cat $fichier); do
    echo $line
done
```

---

## 6. Validation

```bash
# Vérifier les dépendances
check_dependencies() {
    local deps=("grep" "awk" "cut")
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || die "Dépendance manquante : $dep"
    done
}

# Vérifier les arguments — toujours vérifier le nombre AVANT le contenu
validate_args() {
    [[ $# -ne 2 ]]   && die "Usage : $0 <input_file> <output_file>"
    [[ ! -f "$1" ]]  && die "Fichier introuvable : $1"
    [[ ! -r "$1" ]]  && die "Fichier non lisible : $1"
}
```

---

## 7. Lisibilité

- **Header** : description, usage, auteur, version en haut de chaque script
- **Commenter le "pourquoi"**, pas le "quoi"
- **Sections séparées** par des blocs de commentaires
- **Nommage** : verbe + nom pour les fonctions (`get_template`, `check_deps`)

```bash
# ❌ Commentaire inutile (décrit le "quoi")
i=$((i+1))  # incrémente i

# ✅ Commentaire utile (décrit le "pourquoi")
i=$((i+1))  # passe à l'hôte suivant dans la rotation round-robin
```

---

## 8. Récapitulatif rapide

| Pratique | À faire | À éviter |
|---|---|---|
| Sécurité | `set -euo pipefail` | Rien en début de script |
| Variables | `"$var"` | `$var` |
| Fonctions | `local var` | Variables globales implicites |
| Lecture fichier | `while IFS= read -r` | `for x in $(cat file)` |
| Erreurs | `die()` centralisé | `echo` + `exit` dispersés |
| Validation args | Nombre d'abord, contenu ensuite | Ordre inversé |
| Nettoyage | `trap cleanup EXIT` | Pas de trap |
| Logging | Horodaté avec niveau | `echo` brut |

---

## 9. Template complet

```bash
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
```
