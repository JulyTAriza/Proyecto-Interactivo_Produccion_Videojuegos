#!/usr/bin/env bash
# Prueba de sistema SIS-01 con reinicios reales del proceso (persistencia).
# Uso: tools/run_system_test.sh [ruta_godot]
set -e
GODOT="${1:-godot}"
cd "$(dirname "$0")/.."
run() { "$GODOT" --headless --fixed-fps 60 --path . res://tools/system_flow_runner.tscn -- "$@" 2>&1 | grep "SIS>"; }
echo "== Ejecución 1: ganar un cupón y cerrar sin gastarlo"
run --fase=jugar --comprar=false | tee /tmp/sis1.log
N1=$(grep -o "RESULTADO_CUPONES=[0-9]*" /tmp/sis1.log | cut -d= -f2)
echo "== Ejecución 2: reabrir -> el cupón debe seguir ahí ($N1)"
run --fase=verificar --esperados=$N1
echo "== Ejecución 3: ganar otro cupón y gastar el mejor en la factura de planes"
run --fase=jugar | tee /tmp/sis3.log
N3=$(grep -o "RESULTADO_CUPONES=[0-9]*" /tmp/sis3.log | cut -d= -f2)
echo "== Ejecución 4: reabrir -> el cupón consumido NO debe reaparecer ($N3)"
run --fase=verificar --esperados=$N3
echo "== Ejecución 5: ganar cupón y comprar un Kit Anti-Fatiga (Lab 9)"
run --fase=jugar --tienda=kit | tee /tmp/sis5.log
N5=$(grep -o "RESULTADO_CUPONES=[0-9]*" /tmp/sis5.log | cut -d= -f2)
echo "== Ejecución 6: reabrir -> estado de cupones tras la compra del kit ($N5)"
run --fase=verificar --esperados=$N5 | tee /tmp/sis6.log
grep -q "FALLA (" /tmp/sis1.log /tmp/sis3.log /tmp/sis5.log /tmp/sis6.log && exit 1 || echo "SIS-01 completo: PASA"
