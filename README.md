# dungeon
Rogue like random dungeon generator
![alt text](https://github.com/terenctbrobots/dungeon/blob/main/dungeon.png?raw=true)

This is a random dungeon generator built around the LOVE2D framework. There are no other dependencies.

The current system generates a series of connected rooms given a width,height and target number of rooms. It does so by:
1) Doing a BSP inspired subdivision until the required number of container which translate in to rooms are reached
2) Create random sized rooms in the containers
3) Does a delauney triangulation to find all possible connection(edges)  to each room center
4) Does a Minimum Spanning Tree(MST) to determine which edges are needed to connect all rooms
5) Connects each room up using a simple L method so that corridors are angular (There is an alternate A*Star pathfinding routine but it is slow and generates curvy corridors)

The code uses the following LUA code:
1) a modified Delaunay library by Roland Yonaba (https://github.com/Yonaba/delaunay)
2) classic a lua CLASS library(https://github.com/rxi/classic)
3) inspect (https://github.com/kikito/inspect.lua)
4) json (https://github.com/rxi/json.lua)

I might do a more comprehensive writeup in the future
