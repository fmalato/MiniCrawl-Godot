import json
import random
import os, signal
from flask import Flask, request
import mss
import numpy as np

from minicrawl.dungeon_master import DungeonMaster

import logging
#log = logging.getLogger('werkzeug')
#log.setLevel(logging.ERROR)

HOSTNAME = "127.0.0.1"
PORT = 5555

ORIENTATIONS = {
    1: {
        "south": 0,
        "west": 1,
        "north": 2,
        "east": 3
    },
    2: {
        "south,west": 0,
        "south,north": 0,
        "west,north": 1,
        "west,east": 1,
        "north,east": 2,
        "east,south": 3
    },
    3: {
        "east,south,west": 0,
        "south,west,north": 1,
        "west,north,east": 2,
        "north,east,south": 3
    }
}


class GymFlaskServer:

    def __init__(self):
        self.app = Flask(__name__)
        self.pid = os.getpid()
        self.window_pos_x = None
        self.window_pos_y = None
        self.window_width = None
        self.window_height = None
        self.monitor = None
        self.image = None
        self.dungeon_master = DungeonMaster(starting_grid_size=3, max_grid_size=8, increment_freq=5, connection_density=0.5)

        @self.app.route("/")
        def index():
            return "NO DATA"

        @self.app.route("/init", methods=['POST'])
        def initialize_attrs():
            data = request.get_json()
            if data:
                self.window_pos_x = data["pos_x"]
                self.window_pos_y = data["pos_y"]
                self.window_width = data["width"]
                self.window_height = data["height"]
            else:
                self.window_pos_x = 400
                self.window_pos_y = 400
                self.window_width = 800
                self.window_height = 600

            self.monitor = {"top": self.window_pos_y, "left": self.window_pos_x, "width": self.window_width,
                            "height": self.window_height}

            return str(200)

        @self.app.route("/get_action", methods=['GET'])
        def get_action():
            assert self.monitor, "Initialize server first!"
            with mss.mss() as sct:
                obs = np.array(sct.grab(self.monitor))

            return {"action": str(random.randint(1, 4))}

        @self.app.route("/get_maze_map", methods=['GET'])
        def get_maze_map():
            self.dungeon_master.increment_level()
            maze_graph, maze_grid = self.dungeon_master.get_current_floor()
            connections = self.dungeon_master.get_connections()
            connects = np.empty(shape=maze_grid.shape, dtype=object)
            orients = np.zeros(shape=maze_grid.shape)
            for i, j in np.ndindex(maze_grid.shape):
                if maze_grid[i, j] == 0:
                    connects[i, j] = "empty"
                # TODO: something wrong here?
                elif maze_grid[i, j] == 1:
                    keys = list(connections[(i, j)].keys())
                    if len(keys) == 2:
                        if keys == ["north", "south"] or keys == ["west", "east"]:
                            connects[i, j] = f"room_2I"
                        else:
                            connects[i, j] = f"room_2L"
                    elif len(keys) == 0:
                        connects[i, j] = "boss_room"
                    else:
                        connects[i, j] = f"room_{len(list(connections[(i, j)].keys()))}"
                else:
                    corridor_name = self.find_corridor_type(list(connections[(i, j)]))
                    connects[i, j] = corridor_name
                orients[i, j] = self.find_orientations(connections, i, j)

            connections_string = ""
            for i in range(connects.shape[0]):
                for j in range(connects.shape[1]):
                    connections_string += f"{connects[i, j]},"
                connections_string = connections_string[:-1]
                connections_string += "\n"

            orientations_string = ""
            for i in range(orients.shape[0]):
                for j in range(orients.shape[1]):
                    orientations_string += f"{int(orients[i, j])},"
                orientations_string = orientations_string[:-1]
                orientations_string += "\n"

            data = {
                "connections": connections_string,
                "orientations": orientations_string,
                "level": self.dungeon_master.get_current_level(),
                "level_type": "dungeon_floor" if "boss_room" not in connections_string else "boss_stage"
            }
            """data = {
                "connections": "junction_T,junction_L,dead_end,corridor\njunction_T,junction_L,dead_end,corridor\njunction_T,junction_L,dead_end,corridor\njunction_T,junction_L,dead_end,corridor\n",
                "orientations": "0,0,0,0\n1,1,1,1\n2,2,2,2\n3,3,3,3\n"
            }"""

            return json.dumps(data).encode('utf-8')

        @self.app.route("/shutdown", methods=['POST'])
        def shutdown():
            data = request.get_json()
            if data["message"] == "SHUTDOWN_REQUEST":
                self.shutdown_server()
                return {"response_code": str(200), "message": "SHUTDOWN_COMPLETE"}
            else:
                return {"response_code": str(403), "message": "FORBIDDEN"}

    def run(self):
        self.app.run(host=HOSTNAME, port=PORT)

    def find_orientations(self, connections, x, y):
        keys = list(connections[(x, y)].keys())
        if len(keys) == 1:
            return ORIENTATIONS[1][keys[0]]
        elif len(keys) == 2:
            for orient in ORIENTATIONS[2].keys():
                if all([k in orient for k in keys]):
                    return ORIENTATIONS[2][orient]
        elif len(keys) == 3:
            for orient in ORIENTATIONS[3].keys():
                if all([k in orient for k in keys]):
                    return ORIENTATIONS[3][orient]
        else:
            return 0

    def find_corridor_type(self, keys):
        if len(keys) == 1:
            return "dead_end"
        elif len(keys) == 2:
            if set(keys) == {"north", "south"} or set(keys) == {"east", "west"}:
                return "corridor"
            else:
                return "junction_L"
        elif len(keys) == 3:
            return "junction_T"
        else:
            return "junction_X"

    def shutdown_server(self):
        os.kill(self.pid, signal.SIGTERM)


if __name__ == '__main__':
    flask_server = GymFlaskServer()

    flask_server.run()
