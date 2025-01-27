#!/bin/bash

# Constants for the game
ALIVE="█"
DEAD="░"

# Default values for the grid size and seed
WIDTH=32
HEIGHT=16
SEED=$RANDOM

# Create the initial grid
grid=()
prev_grid=()

# Function to print the grid and score
print_grid() {
    clear
    for ((i = 0; i < HEIGHT; i++)); do
        echo "${grid[i]}"
    done
    echo ""
    echo "Time elapsed: ${SECONDS} seconds"
    echo "Alive cells: ${alive_cells_count}"
    echo "Seed: ${SEED}"
}

# Function to initialize the grid with a random state
initialize_grid() {
    for ((i = 0; i < HEIGHT; i++)); do
        row=""
        for ((j = 0; j < WIDTH; j++)); do
            if ((RANDOM % 2)); then
                row+=$ALIVE
            else
                row+=$DEAD
            fi
        done
        grid[i]=$row
    done
}

# Function to count the number of alive neighbors of a cell
count_alive_neighbors() {
    local x=$1
    local y=$2
    local count=0

    for ((i = -1; i <= 1; i++)); do
        for ((j = -1; j <= 1; j++)); do
            if ((i == 0 && j == 0)); then
                continue
            fi

            local nx=$((x + i))
            local ny=$((y + j))

            if ((nx >= 0 && nx < HEIGHT && ny >= 0 && ny < WIDTH)); then
                if [[ ${grid[nx]:ny:1} == "$ALIVE" ]]; then
                    ((count++))
                fi
            fi
        done
    done

    echo $count
}

# Function to update the grid to the next generation
update_grid() {
    new_grid=()
    alive_cells_count=0

    for ((i = 0; i < HEIGHT; i++)); do
        new_row=""
        for ((j = 0; j < WIDTH; j++)); do
            alive_neighbors=$(count_alive_neighbors $i $j)
            cell=${grid[i]:j:1}

            if [[ $cell == "$ALIVE" ]]; then
                if ((alive_neighbors < 2 || alive_neighbors > 3)); then
                    new_row+=$DEAD
                else
                    new_row+=$ALIVE
                    ((alive_cells_count++))
                fi
            else
                if ((alive_neighbors == 3)); then
                    new_row+=$ALIVE
                    ((alive_cells_count++))
                else
                    new_row+=$DEAD
                fi
            fi
        done
        new_grid[i]=$new_row
    done

    grid=("${new_grid[@]}")
}

# Function to check if all cells are dead
all_dead() {
    for ((i = 0; i < HEIGHT; i++)); do
        if [[ ${grid[i]} == *"$ALIVE"* ]]; then
            return 1
        fi
    done
    return 0
}

# Function to check if the current grid state is the same as the previous state
grid_repeats() {
    if [ "${grid[*]}" == "${prev_grid[*]}" ]; then
        return 0
    else
        return 1
    fi
}

# Function to parse command line arguments
parse_args() {
    while getopts ":w:h:s:" opt; do
        case $opt in
        w) WIDTH=$OPTARG ;;
        h) HEIGHT=$OPTARG ;;
        s) SEED=$OPTARG ;;
        \?)
            echo "Invalid option -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        esac
    done
}

# Main function to run the game of life
run_gol() {
    SECONDS=0
    parse_args "$@"
    RANDOM=$SEED
    initialize_grid
    while true; do
        print_grid
        if all_dead; then
            echo "☠ All cells are dead! Exiting..."
            break
        fi
        if grid_repeats; then
            echo "♻ The cell pattern is persistent! Exiting..."
            break
        fi
        prev_grid=("${grid[@]}")
        update_grid
        sleep 0.5
    done
}

# Run the game of life
run_gol "$@"
