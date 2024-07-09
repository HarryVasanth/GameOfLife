# 🧫 John Conway's Game of Life

John Conway's Game of Life is a cellular automaton devised by the British mathematician John Horton Conway in 1970.
It consists of a grid of cells that can be in one of two states: alive or dead.
The state of the grid evolves over time according to a set of simple rules, which lead to complex and often unpredictable behavior.

## How does this work?

1. Initializes a grid of specified width and height with random alive and dead cells based on an optional seed.
2. Prints the grid to the terminal output.
3. Updates the grid according to Conway's rules:
   - Any live cell with fewer than two live neighbors dies (underpopulation).
   - Any live cell with two or three live neighbors lives on to the next generation.
   - Any live cell with more than three live neighbors dies (overpopulation).
   - Any dead cell with exactly three live neighbors becomes a live cell (reproduction).
4. Repeats the process, updating the grid and printing it, to simulate the passage of time in the game.
5. The simulation stops if all cells are dead or if the pattern repeats twice in a row.

## Usage

Run the script with optional arguments for width, height, and seed:

```sh
./gol.sh [-w width] [-h height] [-s seed]
```

### Arguments

- `-w`: Width of the grid (default: 32)
- `-h`: Height of the grid (default: 16)
- `-s`: Seed for the random number generator (default: a random seed)

### Examples

Run with default settings:

```sh
./gol.sh
```

Run with a custom width, height, and seed:

```sh
./gol.sh -w 20 -h 10 -s 12345
```

- The simulation stops automatically if all cells are dead or if the pattern repeats.
