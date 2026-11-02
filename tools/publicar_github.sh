#!/usr/bin/env bash
# Publica todas las ramas y etiquetas de los laboratorios 7-10 y crea la Release Beta.
# Uso: tools/publicar_github.sh https://github.com/USUARIO/REPOSITORIO.git
set -e
REMOTO="$1"
if [ -n "$REMOTO" ] && ! git remote get-url origin >/dev/null 2>&1; then git remote add origin "$REMOTO"; fi
for rama in main lab-7 lab-8 lab-9 lab-10; do git push -u origin "$rama"; done
git push origin lab-8-final lab-9-final lab-10-final v0.9.0-beta
# Release de GitHub (requiere gh autenticado). Adjunta el ZIP Web si existe.
ASSET=""; [ -f build/DetectorFatigaCognitiva-web.zip ] && ASSET="build/DetectorFatigaCognitiva-web.zip"
gh release create v0.9.0-beta $ASSET --prerelease --title "v0.9.0-beta — Versión Beta" --notes-file doc/RELEASE_v0.9.0-beta.md
