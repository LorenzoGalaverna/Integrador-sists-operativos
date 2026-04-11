# Instalación

## Requisitos

- **Sistema operativo:** Linux (Ubuntu, Debian, Fedora, Arch, openSUSE, etc.)
- **Bash:** versión 4 o superior (viene por defecto en todas las distros modernas)
- **Terminal:** tamaño mínimo 80x24 (recomendado 100x30 para el modo fancy)

❌ **No soporta macOS ni Windows.** El consigna del proyecto lo prohíbe explícitamente y varios comandos usados (`find -printf`, `stat -c`, etc.) son GNU-only.

---

## Dependencias obligatorias

Estas vienen preinstaladas en prácticamente cualquier Linux, pero por las dudas:

```bash
# Debian/Ubuntu
sudo apt install coreutils grep gawk sed findutils ncurses-bin

# Fedora
sudo dnf install coreutils grep gawk sed findutils ncurses

# Arch/Manjaro
sudo pacman -S coreutils grep gawk sed findutils ncurses
```

Si alguna falta, el script aborta al arrancar con instrucciones específicas.

---

## Dependencias decorativas (recomendadas)

Estas no son obligatorias — el script detecta cuáles faltan y usa fallbacks en texto plano. Pero con todas instaladas la experiencia es mucho mejor.

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install dialog figlet lolcat boxes pv fzf
```

### Fedora

```bash
sudo dnf install dialog figlet boxes pv fzf
# lolcat suele venir como gema de Ruby:
sudo dnf install rubygem-lolcat
```

### Arch / Manjaro

```bash
sudo pacman -S dialog figlet lolcat boxes pv fzf
```

### openSUSE

```bash
sudo zypper install dialog figlet boxes pv fzf
sudo zypper install rubygem-lolcat   # si está disponible
```

---

## Qué hace cada dependencia decorativa

| Paquete | Para qué se usa | Si falta... |
|---------|-----------------|-------------|
| `dialog` | Menús y ventanas TUI | Cae a menú de texto plano con `read` |
| `figlet` | Banners ASCII grandes | Banner con `echo` y bordes |
| `lolcat` | Texto con colores arcoíris | Texto monocromo |
| `boxes` | Cajas decorativas alrededor del texto | Líneas simples con `-` y `\|` |
| `pv` | Barras de progreso animadas | `sleep` con puntos |
| `fzf` | Búsqueda fuzzy interactiva con preview | Lista estática en dialog |
| `shuf` | Frases de roast aleatorias | Siempre la primera frase de cada categoría |

---

## Instalación del script

```bash
# 1. Clonar o copiar el proyecto
cd roast-my-files

# 2. Dar permisos de ejecución al script principal
chmod +x roast.sh

# 3. Ejecutar
./roast.sh
```

**Opcional:** para tenerlo en el PATH, copiar a `~/.local/bin`:

```bash
cp -r roast-my-files ~/.local/share/
ln -s ~/.local/share/roast-my-files/roast.sh ~/.local/bin/roast
```

---

## Verificar la instalación

```bash
./roast.sh -v        # muestra la versión
./roast.sh -h        # muestra la ayuda
./roast.sh           # arranca el menú interactivo
```

Si alguna dependencia decorativa falta, al arrancar vas a ver `[WARN]` avisando. Eso es normal — el script sigue funcionando.

Si una dependencia **obligatoria** falta, el script aborta con `[ERROR]` y te dice cómo instalarla.

---

## Problemas comunes

### "dialog: command not found"
Dialog no es obligatorio, pero sin él la UX es mucho peor. Instalalo con los comandos de arriba.

### "lolcat" instalado pero no coloreado
En Fedora/openSUSE a veces hay que agregar el bin de Ruby al PATH:
```bash
export PATH="$PATH:$(ruby -e 'print Gem.user_dir')/bin"
```

### "fzf" no encuentra nada en la búsqueda fuzzy
Verificar que la carpeta víctima tenga archivos de texto legibles. El script excluye binarios automáticamente.

### La terminal se queda rara después de un Ctrl+C
El trap del script intenta restaurar el estado con `tput cnorm`, pero si igual queda mal:
```bash
reset
```
