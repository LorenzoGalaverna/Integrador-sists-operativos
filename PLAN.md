# 🔥 ROAST MY FILES — Plan de Proyecto

> **Materia:** Sistemas Operativos — Proyecto Integrador
> **Tema raíz:** Gestor de búsqueda de contenidos en archivos de texto
> **Giro:** Script que *además* de ser un gestor de búsqueda completo, analiza la carpeta del usuario y la "roastea" con datos reales.
> **Plataforma:** Linux (bash)

---

## 1. Visión general

`roast.sh` es un script Bash interactivo con interfaz TUI (terminal UI) que:

1. **Cumple la consigna al 100%**: tiene un **Modo Serio** que es un gestor completo de búsqueda de contenidos (grep, regex, recursivo, contexto, fzf, exportar). Esta sola opción ya satisface el enunciado.
2. **Va más allá**: encima del mismo motor de búsqueda, monta un modo "Roast" que usa los mismos comandos (`grep`, `awk`, `sed`, `wc`, `find`, `sort`, `uniq`, `tr`, `stat`) para extraer datos reales de los archivos del usuario y burlarse de ellos con frases graciosas.
3. **Se ve como una app de verdad**: usa `dialog` para menús TUI, `figlet` + `lolcat` + `boxes` para banners y cutscenes, `pv` para barras de carga dramáticas, y `fzf` para búsqueda fuzzy interactiva con preview.

El resultado es un proyecto que demuestra dominio profundo del ecosistema Linux (no solo comandos sueltos, sino cómo componerlos en una herramienta real) y que va a hacer reír al tribunal en la exposición.

---

## 2. Alcance y no-alcance

### ✅ Dentro
- Script bash 100% POSIX-friendly (usa features de bash, no sh puro, pero corre en cualquier distro moderna).
- Menú interactivo con submenús.
- Gestor de búsqueda completo (la consigna).
- Sistema de "roasts" modulares sobre el mismo motor.
- Interfaz TUI con `dialog` + adornos con `figlet`/`lolcat`/`boxes`/`pv`.
- Búsqueda interactiva con `fzf` y preview.
- Exportación de reportes a archivo.
- Manejo exhaustivo de errores (carpeta inválida, permisos, deps faltantes, Ctrl+C, archivos binarios, carpeta vacía).
- Chequeo automático de dependencias con instrucciones de instalación.
- Código comentado sección por sección.
- Variables en `MAYÚSCULAS_DESCRIPTIVAS`.

### ❌ Fuera
- GUI gráfica (zenity/GTK): difuminaría que es un proyecto de shell.
- Dependencias que no estén en los repos estándar de Debian/Ubuntu/Fedora.
- Features que requieran compilar algo.
- Soporte para macOS/Windows (el consigna lo prohíbe explícitamente).

---

## 3. Decisiones arquitectónicas

### 3.1 Estructura del proyecto

```
roast-my-files/
├── roast.sh                 # Entry point — solo parsea args y llama al main
├── lib/
│   ├── deps.sh              # Chequeo e instrucciones de dependencias
│   ├── ui.sh                # Wrappers de figlet/lolcat/boxes/dialog/pv
│   ├── menu.sh              # Menú principal y submenús (dialog)
│   ├── search.sh            # Modo Serio — gestor de búsqueda (consigna pura)
│   ├── roasts.sh            # Todas las funciones de roast
│   ├── stats.sh             # Helpers de análisis (word_count, top_words, etc.)
│   ├── report.sh            # Exportación de reportes a .txt
│   └── utils.sh             # Helpers genéricos (error, log, trap, cleanup)
├── data/
│   ├── stopwords_es.txt     # Palabras a ignorar en "palabras repetidas"
│   ├── puteadas.txt         # Lista de palabrotas para el ranking
│   ├── frases_roast.txt     # Pool de frases graciosas por categoría
│   └── frases_elogio.txt    # (opcional) Frases para el modo profesor
├── reportes/                # Directorio donde se exportan los .txt de reportes
├── test_files/              # Carpeta con archivos de prueba plantados
├── README.md                # Qué es, cómo instalarlo, cómo usarlo
├── INSTALL.md               # Instrucciones detalladas de instalación
└── PLAN.md                  # Este archivo
```

**Por qué modular en vez de un solo archivo:**
- Facilita repartir el trabajo entre los integrantes del grupo.
- Cada archivo tiene una responsabilidad clara y es más fácil de revisar/corregir.
- Los profes ven que entendemos `source` y cómo estructurar código bash como un proyecto real, no un script de 800 líneas.

### 3.2 Convenciones de código

- **Shebang:** `#!/usr/bin/env bash` (portable entre distros).
- **Modo estricto:** `set -euo pipefail` + `IFS=$'\n\t'` al inicio de cada archivo.
- **Variables globales:** `MAYÚSCULAS_CON_GUIONES`, declaradas con `readonly` cuando son constantes.
- **Variables locales de función:** `local minúsculas`.
- **Funciones:** nombres en `snake_case`, prefijo por módulo (ej: `ui_banner`, `search_recursive`, `roast_patetico`).
- **Comentarios:** cada función arranca con un bloque `# -----` explicando qué hace, qué recibe y qué devuelve. Cada sección lógica dentro tiene su comentario.
- **Salidas de error:** van a `stderr` con prefijo `[ERROR]`.
- **Códigos de salida:** 0 éxito, 1 error general, 2 dependencia faltante, 3 input inválido, 130 Ctrl+C.

### 3.3 Dependencias y cómo las manejamos

| Paquete | Para qué | Obligatorio | Fallback si falta |
|---|---|---|---|
| `bash` ≥ 4 | El intérprete | ✅ | — (abortar) |
| `grep` | Búsqueda | ✅ | — (abortar, viene en coreutils) |
| `awk` | Análisis | ✅ | — |
| `sed` | Transformaciones | ✅ | — |
| `find` | Búsqueda de archivos | ✅ | — |
| `dialog` | Menús TUI | ✅ | Modo texto plano (menú `read` numerado) |
| `figlet` | Banners ASCII | ⚠️ | Banner con echo normal |
| `lolcat` | Texto arcoíris | ⚠️ | Texto sin color |
| `boxes` | Cajas decorativas | ⚠️ | Líneas con `-` y `|` |
| `pv` | Barras de carga | ⚠️ | `sleep` con echo de puntos |
| `fzf` | Búsqueda fuzzy interactiva | ⚠️ | Menú `dialog` con lista estática |

**Estrategia:** al arrancar, `deps.sh` chequea qué hay instalado. Si falta algo obligatorio, aborta con instrucciones claras (`apt install ...`). Si falta algo decorativo, loguea un warning y activa el fallback. Así el script corre en cualquier Linux — con más o menos flash según lo que haya.

---

## 4. Flujo de usuario

```
$ ./roast.sh

  [ figlet "ROAST MY FILES" | lolcat ]

  ┌─ Seleccioná la carpeta víctima ────────┐
  │ > /home/user/apuntes                   │
  │   [ Examinar... ]  [ Usar actual ]     │
  └────────────────────────────────────────┘

  → Chequeando dependencias... OK
  → Escaneando 23 archivos... ████████ 100%

  ┌─ 🔥 ROAST MY FILES ────────────────────┐
  │ ¿Qué querés hacer?                     │
  │                                        │
  │  1) 🔥 Roast completo                  │
  │  2) 🗑️  El archivo más patético        │
  │  3) 📏 Ego en líneas                   │
  │  4) 🔁 Palabras repetidas              │
  │  5) 📌 Cementerio de TODOs             │
  │  6) 🤬 Ranking de puteadas             │
  │  7) 😴 Archivos abandonados            │
  │  8) 🔍 Modo serio (búsqueda)           │
  │  9) 💾 Exportar reporte                │
  │  0) Salir                              │
  └────────────────────────────────────────┘
```

Cada opción abre un submenú o ejecuta la acción con cutscene (figlet → barra de carga pv → resultado en dialog --textbox).

---

## 5. Módulos — especificación detallada

### 5.1 `roast.sh` (entry point)

- Carga todos los módulos con `source lib/*.sh`.
- Setea `set -euo pipefail` y el `trap` de limpieza.
- Parsea argumentos opcionales: `-d DIR` (carpeta víctima), `-h` (ayuda), `-v` (versión), `--no-color` (desactiva lolcat).
- Llama a `deps_check`, luego `ui_splash`, luego `menu_main`.
- Maneja el exit code final.

### 5.2 `lib/utils.sh`

- `err "mensaje"` — imprime a stderr con prefijo.
- `die "mensaje" [code]` — err + exit.
- `log_info`, `log_warn`.
- `cleanup` — borra tempfiles, restaura cursor, limpia pantalla.
- `trap cleanup EXIT INT TERM` — instalado al inicio.
- `confirm "pregunta"` — sí/no con dialog o fallback a `read`.
- `require_dir "path"` — valida que una ruta sea dir legible.

### 5.3 `lib/deps.sh`

- `deps_check` — recorre una tabla de dependencias y setea flags `HAS_DIALOG`, `HAS_FIGLET`, etc. Aborta si falta algo obligatorio con mensaje tipo:
  ```
  [ERROR] Falta 'dialog'. Instalalo con:
    Debian/Ubuntu: sudo apt install dialog
    Fedora:        sudo dnf install dialog
    Arch:          sudo pacman -S dialog
  ```
- `deps_summary` — devuelve un string con qué se detectó (para mostrar en el splash).

### 5.4 `lib/ui.sh`

Wrappers que usan la versión "fancy" si la dep está, o fallback:

- `ui_banner "texto"` — figlet + lolcat, o echo con bordes.
- `ui_box "texto"` — boxes, o líneas con guiones.
- `ui_cutscene "mensaje"` — pv falso ("ANALIZANDO... ████"), o sleep con puntos.
- `ui_menu TITULO OPCIONES...` — dialog --menu, o read numerado.
- `ui_textbox TITULO ARCHIVO` — dialog --textbox, o `less`.
- `ui_inputbox TITULO PROMPT` — dialog --inputbox, o `read -p`.
- `ui_yesno TITULO PREGUNTA` — dialog --yesno, o read y/n.
- `ui_msgbox TITULO MENSAJE` — dialog --msgbox, o echo + pausa.
- `ui_dselect` — dialog --dselect para elegir directorio.

### 5.5 `lib/menu.sh`

- `menu_main` — loop principal con el menú de 10 opciones.
- `menu_search` — submenú del modo serio (ver `search.sh`).
- `menu_config` — cambiar carpeta víctima, toggle color, etc.

### 5.6 `lib/search.sh` — **MODO SERIO (la consigna pura)**

Submenú:

1. **Búsqueda simple** — `grep -n PATRÓN ARCHIVO`. Pide patrón + archivo. Muestra resultados con line numbers.
2. **Búsqueda recursiva** — `grep -rn PATRÓN DIR/`. Pide patrón + directorio.
3. **Búsqueda con regex** — `grep -En REGEX ARCHIVO/DIR`. Valida que el regex sea válido.
4. **Búsqueda case-insensitive** — agrega `-i` a cualquiera de las anteriores.
5. **Búsqueda con contexto** — `grep -n -A N -B N PATRÓN`. Pregunta cuántas líneas antes y después.
6. **Contar ocurrencias** — `grep -c PATRÓN`. Muestra conteo por archivo.
7. **Búsqueda fuzzy interactiva** — abre `fzf` con preview de archivo (`fzf --preview 'cat {}'`). El usuario va filtrando en vivo.
8. **Buscar archivos por nombre** — `find DIR -name PATRÓN`.
9. **Reemplazar texto (preview)** — `sed -n 's/X/Y/gp'` muestra qué cambiaría sin aplicar. Luego pregunta confirmación y aplica con `-i` si acepta.
10. **Exportar último resultado** — guarda el último resultado en `reportes/busqueda_TIMESTAMP.txt`.

Cada función de búsqueda:
- Valida que el archivo/dir exista.
- Captura el stderr de grep para mostrar errores bonitos.
- Guarda el resultado en un tempfile que se muestra con `ui_textbox`.
- Ofrece al final "¿Exportar este resultado?".

### 5.7 `lib/stats.sh`

Funciones puras que toman un archivo o dir y devuelven datos:

- `stats_word_count FILE` → total de palabras (`wc -w`).
- `stats_line_count FILE` → total de líneas (`wc -l`).
- `stats_top_words FILE N` → top N palabras más frecuentes, excluyendo stopwords. Pipeline:
  ```
  tr '[:upper:]' '[:lower:]' < FILE \
    | tr -cs '[:alpha:]' '\n' \
    | grep -vFf data/stopwords_es.txt \
    | sort | uniq -c | sort -rn | head -n N
  ```
- `stats_todos DIR` → busca TODO/FIXME/XXX recursivo con `grep -rn -E`.
- `stats_puteadas DIR` → `grep -rciE -f data/puteadas.txt`.
- `stats_oldest_file DIR` → `find DIR -type f -printf '%T@ %p\n' | sort -n | head -1`.
- `stats_shortest_file DIR` → `find` + `wc -l` + `sort -n | head -1`.
- `stats_longest_file DIR` → idem con `tail -1`.
- `stats_total_words DIR` → suma de todas las palabras.
- `stats_file_count DIR` → cantidad de archivos de texto.

### 5.8 `lib/roasts.sh`

Cada roast usa `stats_*` y compone el insulto eligiendo una frase random del pool:

- `roast_patetico` — llama `stats_shortest_file`, muestra su contenido, elige frase random de la sección "patético" de `frases_roast.txt`.
- `roast_ego` — `stats_longest_file`, frase de "egocéntrico".
- `roast_repetido` — `stats_top_words N=5`, frase por palabra top.
- `roast_todos` — `stats_todos`, muestra el más viejo con fecha, frase de "procrastinación".
- `roast_puteadas` — `stats_puteadas`, ranking con frase de "boca sucia".
- `roast_abandonados` — `stats_oldest_file`, calcula días desde mod, frase de "negligencia".
- `roast_completo` — ejecuta los 6 anteriores en cascada con cutscenes entre cada uno.

Las frases se eligen con `shuf -n 1` de la sección correspondiente del archivo de frases. Cada sección está marcada con `[categoria]` tipo INI.

### 5.9 `lib/report.sh`

- `report_generate` — corre todos los `stats_*` y arma un `.txt` con timestamp:
  ```
  reportes/roast_2026-04-11_15-30-22.txt
  ```
- Secciones del reporte:
  1. Metadata (carpeta analizada, fecha, hostname, usuario).
  2. Estadísticas generales.
  3. Top palabras.
  4. TODOs encontrados.
  5. Puteadas.
  6. Archivos por antigüedad.
  7. Roasts completos.
- `report_open` — abre el último reporte con `less` o el pager del sistema.

---

## 6. Archivos de datos

### 6.1 `data/stopwords_es.txt`
~150 palabras vacías del español (de, la, que, el, en, y, a, los, se...). Usada por `stats_top_words` para filtrar resultados relevantes.

### 6.2 `data/puteadas.txt`
Lista de palabrotas del español rioplatense, una por línea. Usada con `grep -f`.

### 6.3 `data/frases_roast.txt`
Archivo tipo INI con secciones por categoría. Cada línea es una frase con placeholders tipo `%FILE%`, `%COUNT%`, `%WORD%`:

```
[patetico]
Tu archivo %FILE% tiene %COUNT% líneas. Mi lista de compras tiene más.
%FILE% está más vacío que mi cuenta bancaria.
...

[egocentrico]
%FILE% tiene %COUNT% líneas. ¿Novela o ego?
...

[repetido]
Usás "%WORD%" %COUNT% veces. Básicamente no sabés decir otra cosa.
...
```

El motor reemplaza los placeholders en runtime.

### 6.4 `data/frases_elogio.txt` (opcional — modo profesor)
Mismas categorías pero con elogios exagerados. Se activa con `--modo-profesor`.

---

## 7. Manejo de errores

### 7.1 Casos a cubrir explícitamente

| Error | Dónde | Cómo lo manejamos |
|---|---|---|
| Dependencia obligatoria falta | `deps_check` | `die` con instrucciones de instalación |
| Dependencia decorativa falta | `deps_check` | Warning + activar fallback |
| Carpeta víctima no existe | `menu_main` al recibir input | `ui_msgbox` de error + volver a pedir |
| Carpeta sin permisos de lectura | `require_dir` | Error + volver a pedir |
| Carpeta vacía (sin archivos de texto) | Al escanear | Warning amigable + ofrecer cambiar |
| Archivo binario en la búsqueda | `search_*` | Agregar `--binary-files=without-match` a grep |
| Archivo enorme (>10MB) | `stats_*` | Warning "esto puede tardar" + confirmar |
| Regex inválida | `search_regex` | Capturar stderr de grep, mostrar error |
| Patrón vacío | Cualquier búsqueda | Validar antes de ejecutar |
| Ctrl+C en medio de operación | `trap INT` | Cleanup + mensaje "cancelado" + volver al menú |
| Fallo al escribir reporte | `report_generate` | Error con ruta + permiso sugerido |
| `fzf` no encuentra nada | `search_fuzzy` | Mensaje "sin resultados" + volver |
| `dialog` falla (terminal muy chica) | `ui_*` | Fallback a modo texto |
| Archivo con encoding raro | `stats_*` | `iconv` o `--binary-files=text` |
| Stopwords no encontradas | `stats_top_words` | Warning + continuar sin filtrar |

### 7.2 Estrategia global

- `set -euo pipefail` en todos los archivos.
- `trap cleanup EXIT` — garantiza limpieza incluso si algo revienta.
- `trap 'handle_interrupt' INT` — Ctrl+C amigable.
- Función `safe_run` que envuelve comandos y captura exit code para decidir si abortar o continuar.
- Todos los tempfiles via `mktemp` y trackeados en una variable global que `cleanup` borra.

---

## 8. Testing manual

### 8.1 Carpeta de prueba — `test_files/`

Armamos una carpeta con archivos plantados específicamente para disparar cada roast:

- `apuntes_random.md` — con varios TODOs, FIXMEs sin cerrar.
- `diario_2024.txt` — con fecha de modificación vieja (touch `-t`).
- `tp_final.md` — largo, con muchas palabras repetidas tipo "básicamente", "importante", "urgente".
- `notas_basura.txt` — 2 líneas, una que diga "asdasd".
- `charla_amigos.txt` — con varias puteadas.
- `codigo.sh` — archivo con `grep`, `awk`, etc. para testear búsquedas.
- `vacio.txt` — archivo vacío (edge case).
- `binario.dat` — archivo binario (edge case).

### 8.2 Checklist de testing

Cada feature se prueba manualmente con:

- [ ] Input válido — happy path.
- [ ] Input inválido — error esperado.
- [ ] Input vacío — validación.
- [ ] Carpeta vacía — manejo.
- [ ] Archivo binario — filtrado.
- [ ] Ctrl+C en medio — cleanup.
- [ ] Sin la dep decorativa — fallback.
- [ ] Terminal chica (80x24) — dialog se adapta.

---

## 9. Plan de trabajo por fases

> **Filosofía:** empezamos por la consigna pura (modo serio) para tener algo que cumpla el enunciado desde el día 1. Después sumamos los roasts como capa encima. Así si el tiempo se come, igual entregamos algo válido.

### 🏗️ Fase 0 — Setup del proyecto
- [ ] Crear estructura de directorios (`lib/`, `data/`, `reportes/`, `test_files/`).
- [ ] Inicializar `roast.sh` con shebang, licencia/header de comentario, `set -euo pipefail`.
- [ ] Crear skeleton vacío de cada archivo en `lib/`.
- [ ] `README.md` inicial con descripción, screenshot placeholder, cómo correr.
- [ ] `INSTALL.md` con pasos de instalación de deps por distro.
- [ ] Probar que `./roast.sh` corre sin errores (aunque no haga nada útil todavía).

### 🧰 Fase 1 — Núcleo y utils
- [ ] `lib/utils.sh`: `err`, `die`, `log_info`, `log_warn`, `cleanup`, `trap`, `confirm`, `require_dir`.
- [ ] `lib/deps.sh`: tabla de deps, `deps_check`, instrucciones de instalación por distro, flags globales `HAS_*`.
- [ ] Integrar en `roast.sh`: carga módulos, llama a `deps_check`, sale limpio.
- [ ] **Test manual:** desinstalar `dialog` momentáneamente y ver que avisa bien.

### 🎨 Fase 2 — UI wrappers
- [ ] `lib/ui.sh`: todas las funciones wrapper con fallback.
- [ ] `ui_banner` con figlet+lolcat y fallback.
- [ ] `ui_menu`, `ui_textbox`, `ui_inputbox`, `ui_yesno`, `ui_msgbox`, `ui_dselect`.
- [ ] `ui_cutscene` con pv.
- [ ] **Test manual:** cada wrapper en modo fancy y modo fallback.

### 🧭 Fase 3 — Menú principal
- [ ] `lib/menu.sh`: `menu_main` con las 10 opciones, stubs para cada una (que digan "TODO").
- [ ] Selección de carpeta víctima al arrancar (con `ui_dselect` o inputbox).
- [ ] Loop hasta que el usuario elija "Salir".
- [ ] Integrado con `ui.sh`.

### 🔍 Fase 4 — Modo serio (CONSIGNA PURA) ⭐
- [ ] `lib/search.sh`: submenú completo.
- [ ] Opción 1: búsqueda simple (`grep -n`).
- [ ] Opción 2: búsqueda recursiva (`grep -rn`).
- [ ] Opción 3: regex (`grep -En`).
- [ ] Opción 4: toggle case-insensitive.
- [ ] Opción 5: contexto (`-A/-B/-C`).
- [ ] Opción 6: contar (`grep -c`).
- [ ] Opción 7: fzf fuzzy con preview.
- [ ] Opción 8: find por nombre.
- [ ] Opción 9: reemplazo con sed (preview + confirm).
- [ ] Opción 10: exportar último resultado.
- [ ] Manejo de errores en cada una.
- [ ] **Test manual completo con `test_files/`.**
- [ ] ✅ **Checkpoint: en este punto, el proyecto ya cumple la consigna.** Todo lo que sigue es bonus.

### 📊 Fase 5 — Motor de stats
- [ ] `lib/stats.sh`: todas las funciones.
- [ ] `stats_word_count`, `stats_line_count`.
- [ ] `stats_top_words` con stopwords.
- [ ] `stats_todos`.
- [ ] `stats_puteadas`.
- [ ] `stats_oldest_file`, `stats_shortest_file`, `stats_longest_file`.
- [ ] **Test manual:** correr cada función contra `test_files/` y verificar.

### 📁 Fase 6 — Archivos de datos
- [ ] `data/stopwords_es.txt`.
- [ ] `data/puteadas.txt`.
- [ ] `data/frases_roast.txt` con 6 categorías × mínimo 5 frases cada una.

### 🔥 Fase 7 — Roasts individuales
- [ ] `lib/roasts.sh`.
- [ ] `roast_patetico`.
- [ ] `roast_ego`.
- [ ] `roast_repetido`.
- [ ] `roast_todos`.
- [ ] `roast_puteadas`.
- [ ] `roast_abandonados`.
- [ ] Sistema de placeholders `%FILE%` / `%COUNT%` / `%WORD%`.
- [ ] Selector random de frases con `shuf`.

### 🎬 Fase 8 — Roast completo y cutscenes
- [ ] `roast_completo` encadenando los 6.
- [ ] Cutscene entre cada roast con `ui_cutscene`.
- [ ] Banner final con stats resumidas.

### 💾 Fase 9 — Exportación de reportes
- [ ] `lib/report.sh`.
- [ ] `report_generate` con formato prolijo.
- [ ] Ver reporte con `less`.
- [ ] Chequear permisos de escritura en `reportes/`.

### 🩹 Fase 10 — Edge cases y hardening
- [ ] Carpeta vacía, archivos binarios, archivos enormes.
- [ ] Regex inválidas.
- [ ] Ctrl+C en cada punto del flujo.
- [ ] Sin ninguna dep decorativa (modo texto plano).
- [ ] Terminal 80x24.

### ✨ Fase 11 — Polish
- [ ] Revisar todos los comentarios, que cumplan la consigna.
- [ ] Verificar que las variables globales estén en MAYÚSCULAS.
- [ ] Banner de inicio con figlet grande.
- [ ] `--help` con uso + ejemplos.
- [ ] `--version`.
- [ ] `--no-color` funcional.
- [ ] `-d DIR` funcional.

### 🎁 Fase 12 — Extras (si hay tiempo)
- [ ] Modo profesor (felicitaciones exageradas).
- [ ] Easter egg: si detecta "Linus Torvalds" o "GPL" en un archivo, frase especial.
- [ ] Sonido con `beep` o `paplay` en momentos clave.
- [ ] Config file en `~/.roastrc`.
- [ ] Historial de roasts pasados.

### 📚 Fase 13 — Documentación y entrega
- [ ] `README.md` completo con screenshots.
- [ ] `INSTALL.md` con pasos verificados en Ubuntu, Debian, Fedora, Arch.
- [ ] Revisar que todos los archivos tengan header con autores y fecha.
- [ ] Armar guion de la exposición oral.
- [ ] Probar el script en una VM limpia de Ubuntu.

---

## 10. Guion de la exposición oral

1. **Hook (30s):** arrancar el script en vivo, banner con figlet, "hoy vamos a roastear los archivos del profesor" (broma).
2. **Contexto (1 min):** "la consigna pedía un gestor de búsqueda — nosotros lo hicimos, pero encima montamos un modo roast que usa los mismos comandos con otro propósito".
3. **Demo modo serio (2 min):**
   - Búsqueda recursiva con regex.
   - fzf con preview.
   - Contexto con `-A/-B`.
   - Reemplazo con sed (preview + confirm).
   - Exportar resultado.
4. **Demo modo roast (2 min):**
   - Correr `roast_completo` sobre `test_files/`.
   - Mostrar que cada roast está hecho con comandos reales (abrir el código al lado).
5. **Arquitectura (1 min):** mostrar la estructura modular, explicar por qué.
6. **Manejo de errores (1 min):** demostrar intencionalmente 2-3 errores (carpeta inválida, regex rota, Ctrl+C).
7. **Cierre (30s):** recap de comandos usados (grep, awk, sed, find, wc, sort, uniq, tr, stat, dialog, fzf, figlet, lolcat, boxes, pv).

**Total: ~8 minutos.**

---

## 11. Criterios de "listo"

El proyecto se considera completo cuando:

1. ✅ Corre en una VM limpia de Ubuntu 22.04 después de seguir `INSTALL.md`.
2. ✅ El modo serio cubre búsqueda simple, recursiva, regex, case-insensitive, contexto, contar, fzf, find, sed, exportar.
3. ✅ Los 6 roasts funcionan contra `test_files/`.
4. ✅ `roast_completo` corre de punta a punta sin errores.
5. ✅ Todos los errores del punto 7.1 están manejados.
6. ✅ Todos los archivos `.sh` pasan `shellcheck` sin warnings críticos.
7. ✅ `README.md` e `INSTALL.md` completos.
8. ✅ Código comentado sección por sección, variables en MAYÚSCULAS.
9. ✅ Guion de exposición probado en seco.

---

## 12. Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `dialog` queda feo en la terminal de la defensa | Media | Medio | Tener fallback texto plano probado + llevar terminal propia |
| Los profes piden correrlo en una distro sin deps | Media | Alto | INSTALL.md con one-liner por distro + fallback a modo mínimo |
| El tiempo no alcanza para los roasts | Media | Bajo | Fase 4 (modo serio) ya cumple la consigna — los roasts son bonus |
| Alguna dep no está en Fedora/Arch | Baja | Medio | Probar en las 3 distros antes de entregar |
| Chistes en las frases mal recibidos | Baja | Medio | Frases neutras/amables en `frases_roast.txt`, sin cruzar líneas |
| Bash 3 en alguna distro vieja | Baja | Alto | Declarar bash ≥ 4 como requisito en INSTALL.md |

---

## 13. Próximos pasos

1. **Vos:** revisás este plan, me decís qué sacar, qué agregar, qué cambiar.
2. **Juntos:** decidimos nombre final del proyecto (¿seguimos con "Roast My Files" o algo más?).
3. **Yo:** arranco por Fase 0 (setup) y Fase 1 (núcleo) en un solo empujón, te muestro el esqueleto corriendo.
4. **Iteramos:** fase por fase, mostrándote al final de cada una.

---
