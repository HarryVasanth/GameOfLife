#!/bin/bash

# Constants for the game
ALIVE="◘"
DEAD="·"

# Initialize the grid with a given width and height
WIDTH=32
HEIGHT=16

# Create the initial grid
grid=()

# Function to print the grid
print_grid() {
    clear
    for ((i = 0; i < HEIGHT; i++)); do
        echo "${grid[i]}"
    done
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
                fi
            else
                if ((alive_neighbors == 3)); then
                    new_row+=$ALIVE
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

# Main function to run the game
run_gol() {
    initialize_grid
    while true; do
        print_grid
        update_grid
        sleep 0.5
        if all_dead; then
            echo "☠ All cells are dead..."
            break
        fi
    done
}

# Run the game
run_gol
