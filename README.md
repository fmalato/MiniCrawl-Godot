Please refer to [MiniCrawl](https://github.com/fmalato/MiniCrawl) for more information about the environment. Both projects are required to correctly run the environment. This project is a re-implementation of MiniCrawl using Godot for better performance.

# Some visuals
Exploration level: https://github.com/user-attachments/assets/35fa33e6-7fb6-48a1-9cff-5018cf908ad8

Boss stage: https://github.com/user-attachments/assets/c1e6cd91-f24a-456f-8f85-97e04726b5cb

# Installation
To correctly install the environment, please make sure that you have correctly installed [Godot 4](https://godotengine.org/) and [MiniCrawl](https://github.com/fmalato/MiniCrawl) first.

To play the environment:
- Clone this repo;
- Compile the project using Godot;
- Run the [python socket](https://github.com/fmalato/MiniCrawl/blob/main/godot_integration_test_socket.py);
- Run the compiled .exe of the game.

# Features
- The environment can be controlled by either a human player and an AI via a python integration (uses Gym).
- Fully customizable: you can choose depth, frequency and type of bosses, duration of an episode, reward shape.
- Maps are sequentially geerated using Pyhton and numpy for fast generation and efficient storage. The generation algorithm can easily be extended by editing the [DungeonMaster](https://github.com/fmalato/MiniCrawl/blob/main/minicrawl/dungeon_master.py). You can also implement your own algorithm by replacing the DungeonMaster with your own.
- Fast: can run at up to 2500FPS on a consumer laptop (Intel i7 13650HX, RTX 4080).
- You can record your own gameplay for Imitation Learning training, or use the implemented reward function for Reinforcement Learning.

# Limitations
- Due to Godot not making the rendered image easily accessible, recording the gameplay is limited to Windows and makes use of Python and low-level libraries to take screenshots of the game window as fast as possible. While this can be extended to UNIX-based systems, I haven't tested it yet. As a workaround, the asynchronous frames captured from Python are automatically matched with the key presses. According to my test, the resulting pairs are consistent.
- Capturing gameplay requires [ffmpeg](https://www.ffmpeg.org/). You can install your own version by following the instructions at the website. I am testing a .bat/.sh script to automatically install the library at the beginning of data collection and remove it at the end of the process. I will make it available as soon as I have extensively tested it.
