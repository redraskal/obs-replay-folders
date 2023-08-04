# obs-replay-folders

Saves replay buffer files to game-specific folders (like ShadowPlay).

## Important:

1. The script requires `detect_game.exe` to be added to PATH.
2. To update the replay folder, restart the Replay Buffer.

There is no way to run an executable in Lua without breaking fullscreen application focus. So, the current running game will not automatically update.
