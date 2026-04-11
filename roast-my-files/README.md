# 🔥 Roast My Files

**Proyecto Integrador — Sistemas Operativos**
Gestor de búsqueda de contenidos en archivos de texto (con actitud).

---

## ¿Qué es esto?

`roast.sh` es un script Bash interactivo con interfaz TUI que tiene **dos modos**:

1. **Modo Serio** 🔍 — Un gestor completo de búsqueda de contenidos en archivos de texto: búsqueda simple, recursiva, con regex, case-insensitive, con contexto, conteo, fuzzy (con `fzf`), reemplazo con preview, y exportación de resultados. Esta es la parte que cumple la consigna del proyecto.

2. **Modo Roast** 🔥 — El mismo motor de búsqueda, pero usado para analizar tu carpeta y burlarse de ella con datos reales. Te dice cuál es tu archivo más patético, qué palabras repetís como loro, cuántos TODOs abandonaste, qué archivos no tocás hace meses, y más.

Los dos modos usan exactamente los mismos comandos Linux (`grep`, `awk`, `sed`, `find`, `wc`, `sort`, `uniq`, `tr`, `stat`). La gracia es mostrar dominio profundo de esas herramientas usándolas para algo más que el típico "buscar una palabra en un archivo".

---

## Uso rápido

```bash
# Modo interactivo (te pregunta la carpeta)
./roast.sh

# Con carpeta pre-seleccionada
./roast.sh -d ~/apuntes

# Sin colores (para logs o terminales limitadas)
./roast.sh --no-color

# Ayuda
./roast.sh -h
```

---

## Instalación

Ver [`INSTALL.md`](INSTALL.md) para los comandos exactos según tu distro.

**TL;DR en Debian/Ubuntu:**
```bash
sudo apt install dialog figlet lolcat boxes pv fzf
chmod +x roast.sh
./roast.sh
```

El script funciona incluso si faltan las dependencias decorativas (`figlet`, `lolcat`, `boxes`, `pv`, `fzf`): detecta qué hay instalado y usa fallbacks de texto plano para lo que no.

---

## Estructura del proyecto

```
roast-my-files/
├── roast.sh              # Entry point
├── lib/
│   ├── utils.sh          # Logging, errores, traps, helpers
│   ├── deps.sh           # Chequeo de dependencias
│   ├── ui.sh             # Wrappers de dialog/figlet/lolcat/boxes/pv
│   ├── menu.sh           # Menú principal y submenús
│   ├── search.sh         # Modo serio (gestor de búsqueda)
│   ├── stats.sh          # Motor de análisis de archivos
│   ├── roasts.sh         # Funciones de roast
│   └── report.sh         # Exportación de reportes
├── data/
│   ├── stopwords_es.txt  # Palabras vacías del español
│   ├── puteadas.txt      # Lista para el ranking de palabrotas
│   └── frases_roast.txt  # Pool de frases por categoría
├── reportes/             # Salida de reportes exportados
├── test_files/           # Archivos de prueba para demo
├── README.md             # Este archivo
├── INSTALL.md            # Instrucciones de instalación
└── PLAN.md               # Plan de desarrollo por fases
```

---

## Comandos Linux demostrados

| Comando | Uso en el proyecto |
|---------|---------------------|
| `grep` | Búsqueda simple, recursiva, regex, contexto, conteo |
| `awk` | Parseo de estadísticas y reporte |
| `sed` | Reemplazo con preview + in-place |
| `find` | Búsqueda por nombre, archivos por fecha |
| `wc` | Conteo de líneas, palabras, caracteres |
| `sort`, `uniq` | Top palabras, rankings |
| `tr` | Normalización y tokenización |
| `cut`, `head`, `tail` | Pipeline de análisis |
| `stat` | Metadatos de archivos |
| `mktemp` | Archivos temporales seguros |
| `tput` | Control de terminal |
| `dialog` | Menús TUI |
| `figlet`, `lolcat`, `boxes` | Presentación visual |
| `pv` | Barras de progreso |
| `fzf` | Búsqueda fuzzy interactiva |
| `shuf` | Selección aleatoria de frases |

---

## Estado de desarrollo

Ver [`PLAN.md`](PLAN.md) para el plan completo por fases.

**Fase actual:** 1 — Núcleo y utils ✅

---

## Autores

Proyecto Integrador — Sistemas Operativos
UCC
