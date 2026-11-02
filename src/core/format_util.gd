# res://src/core/format_util.gd
# ---------------------------------------------------------------------------
# FORMAT UTIL — Utilidades de formato compartidas por las pantallas
# ---------------------------------------------------------------------------
class_name FormatUtil
extends RefCounted

## Formatea un valor en pesos con separador de miles: 15000 -> "15.000".
static func pesos(valor: int) -> String:
	var negativo: bool = valor < 0
	var s: String = str(absi(valor))
	var out: String = ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if negativo else "") + s + out
