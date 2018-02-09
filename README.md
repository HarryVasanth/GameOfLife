# 🧫 John Conway's Game of Life

John Conway's Game of Life is a cellular automaton devised by the British mathematician John Horton Conway in 1970.
It consists of a grid of cells that can be in one of two states: alive or dead.
The state of the grid evolves over time according to a set of simple rules, which lead to complex and often unpredictable behavior.

## How does this work?

1. Initializes a grid of specified width and height with random alive and dead cells.
2. Print the grid to the terminal output.
3. Updates the grid according to Conway's rules:
   - Any live cell with fewer than two live neighbors dies (underpopulation).
   - Any live cell with two or three live neighbors lives on to the next generation.
   - Any live cell with more than three live neighbors dies (overpopulation).
   - Any dead cell with exactly three live neighbors becomes a live cell (reproduction).
4. Repeats the process, updating the grid and printing it, to simulate the passage of time in the game.
