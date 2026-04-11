#!/usr/bin/env bash
#
# Script de demostración para el modo búsqueda.
# Contiene varios comandos de Linux para que los podamos buscar.

# Buscar archivos por extensión
find . -name "*.txt" -type f

# Contar líneas con grep
grep -c "TODO" *.md

# Buscar recursivamente
grep -rn "función" lib/

# Reemplazar con sed
sed -i 's/viejo/nuevo/g' archivo.txt

# Tokenizar palabras con tr
cat archivo.txt | tr ' ' '\n' | sort | uniq -c | sort -rn

# Listar archivos por fecha de modificación
find . -type f -printf '%T@ %p\n' | sort -n

# TODO: agregar más ejemplos
# FIXME: revisar que todo funcione
