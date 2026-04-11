# test_files/

Archivos plantados para demostrar cada feature de Roast My Files.

| Archivo | Para qué |
|---|---|
| `apuntes.md` | Tiene muchos TODOs/FIXMEs/XXX/HACK y palabras repetidas ("básicamente", "importante") — dispara `roast_todos` y `roast_repetido` |
| `tp_final.md` | Archivo más largo, con muchas palabras repetidas — dispara `roast_ego` y `roast_repetido` |
| `notas_random.txt` | 3 líneas, una dice "asdasd" — dispara `roast_patetico` |
| `charla_grupo.txt` | Lleno de puteadas — dispara `roast_puteadas` |
| `diario.txt` | Diario abandonado — útil para mostrar `find -mtime` y `roast_abandonados` (correr `touch -t` para hacerlo viejo) |
| `codigo_demo.sh` | Script con varios comandos — útil para demos del modo serio (búsqueda con regex, contexto, etc.) |
| `lista_compras.txt` | Archivo neutro de control |

## Hacer "viejo" el diario para el roast de abandonados

```bash
touch -d "2024-01-15" diario.txt
```

Después correr el script y elegir "Archivos abandonados".
