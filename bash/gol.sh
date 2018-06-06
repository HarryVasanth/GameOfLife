#!/usr/bin/env bash
#
# Conway's Game of Life in the terminal.
#
# The script stays compatible with Bash 3.2 because macOS ships that
# version by default. It uses no associative arrays and no Bash 4 syntax.

VERSION="2.0.0"

# Text setup. The script replaces these values in setup_chars().
ALIVE=""
DEAD=""

# Default settings.
WIDTH=32
HEIGHT=16
SEED=$RANDOM
DELAY=0.5
GENERATIONS=0
PATTERN="random"
WRAP=0
ASCII=0

# Limits. A larger grid is slow and does not fit a normal terminal.
MAX_WIDTH=200
MAX_HEIGHT=100
MAX_CELLS=20000

# Cycle memory limit. See detect_cycle().
# shortcut: the script keeps at most 2000 states in memory. A pattern
# with a longer period is not detected. Raise the limit if needed.
CYCLE_LIMIT=2000

# Runtime state.
grid=()
history=()
generation=0
alive_cells_count=0
cycle_length=0
first_render=1
is_tty=0
exit_reason=""

script_name=${0##*/}

usage() {
    cat <<EOF
$script_name $VERSION - Conway's Game of Life

Usage: $script_name [options]

Options:
  -w N    Grid width, 1-$MAX_WIDTH (default 32)
  -h N    Grid height, 1-$MAX_HEIGHT (default 16)
  -s N    Random seed, 0-32767 (default: random)
  -p P    Start pattern: random, blinker, glider, pentomino, acorn
          (default: random)
  -d S    Delay between frames in seconds (default 0.5, 0 = fast)
  -n N    Stop after N generations (default 0 = no limit)
  -t      Wrap the grid at the edges (torus)
  -a      Use ASCII characters instead of blocks
  --help     Show this help and exit
  --version  Show the version and exit

Examples:
  $script_name
  $script_name -w 60 -h 30 -s 42
  $script_name -p glider -d 0.1
  $script_name -p acorn -t -n 500
EOF
}

die() {
    printf '%s: %s\n' "$script_name" "$*" >&2
    exit 1
}

is_uint() {
    [[ $1 =~ ^[0-9]+$ ]]
}

# Use base 10 so a value such as 08 does not fail as an octal number.
to_decimal() {
    printf '%d' "$((10#$1))"
}

validate() {
    is_uint "$WIDTH" || die "-w needs a number, not '$WIDTH'"
    is_uint "$HEIGHT" || die "-h needs a number, not '$HEIGHT'"
    is_uint "$GENERATIONS" || die "-n needs a number, not '$GENERATIONS'"
    is_uint "$SEED" || die "-s needs a number, not '$SEED'"

    WIDTH=$(to_decimal "$WIDTH")
    HEIGHT=$(to_decimal "$HEIGHT")
    GENERATIONS=$(to_decimal "$GENERATIONS")
    SEED=$(to_decimal "$SEED")

    ((WIDTH >= 1 && WIDTH <= MAX_WIDTH)) ||
        die "-w must be between 1 and $MAX_WIDTH"
    ((HEIGHT >= 1 && HEIGHT <= MAX_HEIGHT)) ||
        die "-h must be between 1 and $MAX_HEIGHT"
    ((WIDTH * HEIGHT <= MAX_CELLS)) ||
        die "the grid is too large (limit $MAX_CELLS cells)"

    # Bash RANDOM is 15 bits. Larger seeds wrap, so show the real value.
    SEED=$((SEED % 32768))

    [[ $DELAY =~ ^[0-9]+([.][0-9]+)?$ ]] ||
        die "-d needs seconds such as 0.5, not '$DELAY'"

    # A zero delay means full speed. Do not start sleep for each frame.
    if [[ $DELAY =~ ^0+([.]0+)?$ ]]; then
        DELAY=""
    fi

    case $PATTERN in
    random | blinker | glider | pentomino | acorn) ;;
    *) die "-p must be random, blinker, glider, pentomino or acorn" ;;
    esac
}

parse_args() {
    local opt

    # getopts has no long options. Check the two long options first.
    for opt in "$@"; do
        case $opt in
        --help) usage; exit 0 ;;
        --version) printf '%s %s\n' "$script_name" "$VERSION"; exit 0 ;;
        esac
    done

    while getopts ":w:h:s:d:p:n:ta" opt; do
        case $opt in
        w) WIDTH=$OPTARG ;;
        h) HEIGHT=$OPTARG ;;
        s) SEED=$OPTARG ;;
        d) DELAY=$OPTARG ;;
        p) PATTERN=$OPTARG ;;
        n) GENERATIONS=$OPTARG ;;
        t) WRAP=1 ;;
        a) ASCII=1 ;;
        \?) die "invalid option -$OPTARG (try --help)" ;;
        :) die "option -$OPTARG needs a value" ;;
        esac
    done

    shift $((OPTIND - 1))
    (($# == 0)) || die "unexpected argument '$1' (try --help)"

    validate
}

setup_chars() {
    local locale_name=${LC_ALL:-${LC_CTYPE:-$LANG}}

    if ((ASCII)); then
        ALIVE="#"
        DEAD="."
        return
    fi

    case $locale_name in
    *UTF-8* | *utf-8* | *UTF8* | *utf8*)
        ALIVE="█"
        DEAD="░"
        ;;
    *)
        # A non UTF-8 terminal shows blocks as broken bytes.
        ALIVE="#"
        DEAD="."
        ;;
    esac
}

# The grid holds only "0" and "1" characters. Rendering replaces them
# with the display characters. This keeps the rules independent of the
# terminal encoding.
initialize_grid() {
    local i j row

    grid=()
    alive_cells_count=0

    for ((i = 0; i < HEIGHT; i++)); do
        row=""
        for ((j = 0; j < WIDTH; j++)); do
            if ((RANDOM % 2)); then
                row+="1"
            else
                row+="0"
            fi
        done
        grid[i]=$row
    done
    count_alive
}

clear_grid() {
    local i row

    printf -v row '%*s' "$WIDTH" ""
    row=${row// /0}
    grid=()
    for ((i = 0; i < HEIGHT; i++)); do
        grid[i]=$row
    done
    alive_cells_count=0
}

count_alive() {
    local i row

    alive_cells_count=0
    for ((i = 0; i < HEIGHT; i++)); do
        row=${grid[i]//0/}
        alive_cells_count=$((alive_cells_count + ${#row}))
    done
}

set_cell() {
    local x=$1 y=$2 row=${grid[$2]}

    grid[y]="${row:0:$x}1${row:$((x + 1))}"
}

place_pattern() {
    local pattern=$1 cells width height ox oy cell x y

    case $pattern in
    blinker)
        width=3 height=1
        cells="0,0 1,0 2,0"
        ;;
    glider)
        width=3 height=3
        cells="1,0 2,1 0,2 1,2 2,2"
        ;;
    pentomino)
        width=3 height=3
        cells="1,0 2,0 0,1 1,1 1,2"
        ;;
    acorn)
        width=7 height=3
        cells="1,0 3,1 0,2 1,2 4,2 5,2 6,2"
        ;;
    *) die "unknown pattern '$pattern'" ;;
    esac

    ((width <= WIDTH && height <= HEIGHT)) ||
        die "pattern '$pattern' needs a grid of at least ${width}x${height}"

    ox=$(((WIDTH - width) / 2))
    oy=$(((HEIGHT - height) / 2))

    for cell in $cells; do
        x=${cell%,*}
        y=${cell#*,}
        set_cell $((ox + x)) $((oy + y))
    done
    count_alive
}

print_grid() {
    local i row out=""

    if ((is_tty)); then
        if ((first_render)); then
            printf '\033[H\033[2J'
        else
            printf '\033[H'
        fi
    else
        printf -- '--- generation %d ---\n' "$generation"
    fi

    for ((i = 0; i < HEIGHT; i++)); do
        row=${grid[i]//0/$DEAD}
        out+=${row//1/$ALIVE}$'\n'
    done

    printf '%s' "$out"
    printf 'Generation: %d  Alive: %d  Elapsed: %ds  Seed: %d\n' \
        "$generation" "$alive_cells_count" "$SECONDS" "$SEED"

    first_render=0
}

update_grid() {
    local i j x y nx ny neighbors alive row new_grid

    new_grid=()
    alive_cells_count=0

    for ((i = 0; i < HEIGHT; i++)); do
        row=""
        for ((j = 0; j < WIDTH; j++)); do
            neighbors=0

            for ((y = -1; y <= 1; y++)); do
                for ((x = -1; x <= 1; x++)); do
                    if ((y == 0 && x == 0)); then
                        continue
                    fi

                    nx=$((j + x))
                    ny=$((i + y))

                    if ((WRAP)); then
                        nx=$(((nx + WIDTH) % WIDTH))
                        ny=$(((ny + HEIGHT) % HEIGHT))
                    elif ((nx < 0 || nx >= WIDTH || ny < 0 || ny >= HEIGHT)); then
                        continue
                    fi

                    if [[ ${grid[ny]:nx:1} == "1" ]]; then
                        neighbors=$((neighbors + 1))
                    fi
                done
            done

            alive=${grid[i]:j:1}
            if [[ $alive == "1" ]]; then
                if ((neighbors == 2 || neighbors == 3)); then
                    row+="1"
                    alive_cells_count=$((alive_cells_count + 1))
                else
                    row+="0"
                fi
            else
                if ((neighbors == 3)); then
                    row+="1"
                    alive_cells_count=$((alive_cells_count + 1))
                else
                    row+="0"
                fi
            fi
        done
        new_grid[i]=$row
    done

    grid=("${new_grid[@]}")
}

# Compare the current state with every earlier state in the history.
# A match means the simulation is in a loop.
detect_cycle() {
    local state k

    state="${grid[*]}"

    for ((k = 0; k < ${#history[@]}; k++)); do
        if [[ ${history[k]} == "$state" ]]; then
            cycle_length=$((${#history[@]} - k))
            return 0
        fi
    done

    if ((${#history[@]} >= CYCLE_LIMIT)); then
        history=("${history[@]:1}")
    fi
    history[${#history[@]}]=$state

    return 1
}

cleanup() {
    if ((is_tty)); then
        printf '\033[?25h'
        if [[ -n $exit_reason ]]; then
            printf '\n'
        fi
    fi

    if [[ -n $exit_reason ]]; then
        printf 'Simulation stopped: %s\n' "$exit_reason"
        printf 'Generations: %d  Alive: %d  Seed: %d\n' \
            "$generation" "$alive_cells_count" "$SEED"
    fi
}

run_gol() {
    parse_args "$@"
    setup_chars

    if [[ -t 1 ]]; then
        is_tty=1
        printf '\033[?25l'
    fi

    trap cleanup EXIT
    trap 'exit_reason="interrupted"; exit 130' INT TERM

    SECONDS=0
    RANDOM=$SEED

    if [[ $PATTERN == "random" ]]; then
        initialize_grid
    else
        clear_grid
        place_pattern "$PATTERN"
    fi

    while true; do
        print_grid

        if ((alive_cells_count == 0)); then
            exit_reason="all cells are dead"
            break
        fi

        if ((GENERATIONS > 0 && generation >= GENERATIONS)); then
            exit_reason="generation limit reached"
            break
        fi

        if detect_cycle; then
            exit_reason="the pattern repeats every $cycle_length generation(s)"
            break
        fi

        update_grid
        generation=$((generation + 1))

        if [[ -n $DELAY ]]; then
            sleep "$DELAY"
        fi
    done
}

run_gol "$@"
