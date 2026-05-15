# Note — Cascade Windsurf edit tools (Claude vs GPT-5.5)

Referencia rápida sobre qué herramientas de edición funcionan limpio en Cascade y por qué a GPT-5.5 le suelen fallar.

## Tools disponibles

### 1. `edit` — find & replace exacto
```
file_path:   absolute path
old_string:  texto exacto a reemplazar (incluye whitespace, indentación, line endings)
new_string:  reemplazo
replace_all: opcional, default false
```

### 2. `multi_edit` — múltiples edits atómicas en el mismo archivo
```
file_path: absolute
edits: [{old_string, new_string, replace_all?}, ...]
```
Si UNA falla, ninguna se aplica. Edits aplicados en secuencia (cada uno ve el resultado del anterior).

### 3. `write_to_file` — SOLO archivos nuevos
```
TargetFile: absolute
CodeContent: contenido completo
EmptyFile: bool
```
Nunca sobre archivo existente.

## Reglas que evitan fallos

| Regla | Por qué |
|---|---|
| Leer (`read_file`) antes de editar | La tool requiere ≥1 read previo en la conversación |
| `old_string` único en el archivo | Si aparece 2+ veces → error. Solución: ampliar contexto con líneas vecinas hasta unicidad, o `replace_all: true` |
| Indentación EXACTA (tabs/spaces) | Mismatch invisible = `not found` |
| `old_string` ≠ `new_string` | No-op → error |
| No incluir el prefijo `<spaces>+<linenum>+<tab>` que devuelve `read_file` cat -n | Solo contenido real |
| Respetar CRLF/LF del archivo | Windows + git autocrlf puede generar mismatch silencioso |
| `write_to_file` solo si archivo no existe | Sobrescribiría sin warning |
| En `multi_edit`, pensar el orden | Edit 2 puede fallar si edit 1 borró su `old_string` |

## Patrones de fallo típicos en GPT-5.5 y mitigación

| Falla | Causa común | Mitigación en prompt |
|---|---|---|
| `old_string not found` | Whitespace/CRLF mal copiado, archivo cambió desde el read | "Lee el archivo justo antes de editar; copia bytes verbatim" |
| `old_string not unique` | String ambiguo | "Incluye 3-5 líneas de contexto vecino para unicidad" |
| Sobrescribe trabajo | Usa `write_to_file` sobre archivo existente | "Solo `write_to_file` para archivos nuevos; `edit` para modificar" |
| Edits encadenados rompen | `multi_edit` con dependencias mal pensadas | "Aplica cambios uno a uno con `edit` si dudas" |

## Tips operativos para GPT-5.5

1. *"Lee primero el archivo X completo antes de proponer edits"*
2. *"Usa `edit` con `old_string` que incluya 3-5 líneas únicas de contexto"*
3. *"Después de cada edit, verifica con `read_file` el resultado"*
4. *"No uses `write_to_file` salvo para archivos nuevos"*
5. *"Si necesitas leer varios archivos, hazlo en paralelo en una sola respuesta"*

## Ventaja adicional Claude/Cascade

Capacidad nativa de invocar tools **en paralelo** cuando son independientes (`read_file` + `grep_search` + `find_by_name` a la vez). GPT-5.5 tiende a serializar, multiplicando turnos y puntos de fallo. Forzar paralelismo en el prompt acelera y reduce errores.

---

*Creado 2026-05-15 a petición Founder yaboula tras incidente CRLF migration 010 + savings column 037 (sesión PM Cascade).*
