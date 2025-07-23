Adaptopolis Godot Integration Instructions
========================================

1. Copy Files:
   - Copy all files from this 'output' folder into your Godot project directory (e.g., D:\adaptopolis\adaptopolis\output).

2. Add Scripts and Scene:
   - In Godot, right-click your project folder and select 'Add Existing...' to add:
	 - scripts/Card.gd
	 - scripts/City.gd
	 - scripts/Rain.gd
	 - scripts/Game.gd
	 - scenes/Main.tscn

3. Set Main Scene:
   - In Godot, go to Project > Project Settings > Application > Run > Main Scene.
   - Set the main scene to 'scenes/Main.tscn'.

4. Run the Game:
   - Click the Play button (F5) to run the game.

5. How it works:
   - The game displays city status, rain events, and lets you buy cards each round.
   - Use the 'Next Round' button to advance.
   - The game ends when city health reaches zero.

6. Customization:
   - You can move the scripts/scenes to other folders, but update the preload paths in Game.gd if you do.

Enjoy managing your city! 
