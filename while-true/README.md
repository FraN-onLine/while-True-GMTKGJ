# While True - Loop Breaking Puzzle Game

## Game Concept

"While True" is a puzzle game where everything in the world runs on a loop. Your goal is to understand the sequence of events happening around you and "break" the loop by submitting the correct sequence.

## How to Play

1. **Watch the Loop**: Observe the repeating sequence of events in the room
2. **Open Code Editor**: Press ESC to open the code editor
3. **Write Code**: Drag and drop code blocks to create your solution
4. **Test Code**: Click "Test Code" to verify your solution
5. **Break the Loop**: If correct, click "Break Loop" to complete the level

## Controls

- **WASD** or **Arrow Keys**: Move character
- **Space**: Jump
- **ESC**: Open/close code editor

## Level 1

The first level features a simple 3-event loop:
1. Anvil falls from the ceiling
2. Hole appears in the floor
3. Hole closes

Your task is to write code that matches this sequence:
```python
while true:
    drop(anvil)
    hole_open()
    hole_close()
```

## Level 2

The second level introduces conditional logic:
1. Card drops
2. Card drops  
3. Card drops (conditional: if level/2 == 0)

Your task is to write code with conditional blocks:
```python
while true:
    drop(card)
    drop(card)
    if level / 2 == 0:
        drop(card)
```

## Configuration

The game is easily configurable:

### Input Controls (project.godot):
- `move_left`: A key or Left Arrow
- `move_right`: D key or Right Arrow  
- `jump`: Space key
- `ui_cancel`: ESC key

### Level Configuration (global.gd):
- `loop_duration`: How long each loop cycle takes
- `current_sequence`: The expected sequence for each level
- Add new levels by adding cases to the `load_level()` function

### Droppable Resources (resources/):
- Each droppable type has its own `.tres` resource file
- Configure name, color, size, and label properties
- Add new droppable types by creating new resource files

### Code Blocks (code_editor.gd):
- Add new function blocks in `available_blocks`
- Add new conditional logic in `convert_code_to_sequence()`

## Running the Game

1. Open the project in Godot 4.4
2. Press F5 or click the "Play" button
3. The game will start with Level 1

## Game Structure

### Core Scripts:
- `global.gd`: Manages game state, sequences, and level progression
- `scripts/main_game.gd`: Main game scene controller
- `scripts/player.gd`: Player movement and interaction
- `scripts/loop_manager.gd`: Controls the repeating loop events
- `scripts/ui.gd`: UI management and display
- `scripts/code_editor.gd`: Code editor interface
- `scripts/droppable.gd`: Droppable resource system

### Scenes:
- `scenes/main_game.tscn`: Main game scene (combines all components)
- `scenes/player.tscn`: Player character with camera
- `scenes/room.tscn`: Game environment and loop manager
- `scenes/ui.tscn`: Game UI elements
- `scenes/code_editor.tscn`: Code editor interface
- `scenes/droppable.tscn`: Reusable droppable resource

### Resources:
- `resources/droppable_resource.gd`: Base class for droppable resources
- `resources/anvil.tres`: Anvil droppable configuration
- `resources/card.tres`: Card droppable configuration
- `resources/snake.tres`: Snake droppable configuration
- `resources/ball.tres`: Ball droppable configuration
- `resources/rock.tres`: Rock droppable configuration

## Developer Guide - Extending the Game

### Adding New Levels

1. **Update `global.gd`:**
   ```gdscript
   # In load_level() function, add new case:
   3:
       loop_duration = 7.0
       current_sequence = ["light_on", "door_open", "ball_roll"]
   ```

2. **Update `loop_manager.gd`:**
   ```gdscript
   # In play_next_event() function:
   "light_on":
       play_light_on()
   "door_open":
       play_door_open()
   
   # Add corresponding functions:
   func play_light_on():
       # Your animation logic here
   ```

3. **Update `code_editor.gd`:**
   ```gdscript
   # In available_blocks dictionary:
   "light_on()": {"type": "function", "params": []}
   
   # In convert_code_to_sequence():
   elif code == "light_on()":
       converted.append("light_on")
   ```

4. **Create new room scene:**
   - Copy `room.tscn` to `room_level3.tscn`
   - Add level-specific visual elements
   - Update `main_game.gd` load_level_room() function

### Adding New Droppable Types

1. **Create new resource file:**
   ```gdscript
   # Create resources/gem.tres:
   [gd_resource type="Resource" script_class="DroppableResource" load_steps=2 format=3]
   
   [ext_resource type="Script" path="res://resources/droppable_resource.gd" id="1_droppable"]
   
   [resource]
   script = ExtResource("1_droppable")
   name = "gem"
   color = Color(0.8, 0.2, 0.8, 1)
   size = Vector2(25, 25)
   label = "Gem"
   ```

2. **Update `code_editor.gd`:**
   ```gdscript
   # Add to drop() parameters:
   "drop()": {"type": "function", "params": ["anvil", "card", "gem"]}
   
   # Add conversion:
   elif param == "gem":
       converted.append("gem_drop")
   ```

### Adding New Code Blocks

1. **Update `code_editor.gd`:**
   ```gdscript
   # In available_blocks:
   "repeat()": {"type": "function", "params": ["3", "5", "10"]}
   
   # Add conversion logic:
   elif code.begins_with("repeat("):
       var count = code.split("(")[1].split(")")[0]
       for i in range(int(count)):
           converted.append("repeat_action")
   ```

2. **Update `code_editor.tscn`:**
   - Add new button in BlockList
   - Button text must match the key in available_blocks

### File Structure Overview

```
while-true/
├── global.gd                 # Game state, level management
├── scripts/
│   ├── main_game.gd         # Main scene controller
│   ├── player.gd            # Player movement and interaction
│   ├── loop_manager.gd      # Loop event system
│   ├── code_editor.gd       # Code editor interface
│   ├── ui.gd                # UI management
│   ├── droppable.gd         # Droppable resource system
│   └── title_screen.gd      # Title screen logic
├── scenes/
│   ├── main_game.tscn       # Main game scene
│   ├── player.tscn          # Player character
│   ├── room.tscn            # Level 1 environment
│   ├── room_level2.tscn     # Level 2 environment
│   ├── ui.tscn              # Game UI
│   ├── code_editor.tscn     # Code editor interface
│   ├── droppable.tscn       # Reusable droppable
│   └── title_screen.tscn    # Title screen
├── resources/
│   ├── droppable_resource.gd # Base droppable resource class
│   ├── anvil.tres           # Anvil configuration
│   ├── card.tres            # Card configuration
│   ├── snake.tres           # Snake configuration
│   ├── ball.tres            # Ball configuration
│   └── rock.tres            # Rock configuration
└── project.godot            # Project configuration
```

### Key Configuration Points

- **Input Controls**: `project.godot` → `[input]` section
- **Level Sequences**: `global.gd` → `load_level()` function
- **Code Blocks**: `code_editor.gd` → `available_blocks` dictionary
- **Droppable Resources**: `resources/` folder → individual `.tres` files
- **Room Scenes**: Create new `.tscn` files for each level

### Testing New Features

1. **Test Level Progression**: Ensure levels load correctly
2. **Test Code Editor**: Verify new blocks work and convert properly
3. **Test Visual Elements**: Check animations and UI updates
4. **Test Game Flow**: Complete full level cycle

## Recent Fixes

### Code Editor UI Issues Fixed:
- Added missing `ui_cancel` input action for ESC key
- Fixed button signal connections and input handling
- Added debug prints to track button interactions
- Improved dragging functionality for code blocks
- Enhanced resource system for droppable configuration

### Droppable Resource System:
- Created `DroppableResource` class for configurable droppables
- Added individual `.tres` files for each droppable type
- Updated `droppable.gd` to use resource system
- Made texture, name, color, size, and label easily editable

## Future Features

- More complex conditional logic (else, elif)
- Nested loops and functions
- Multiple rooms and environments
- Visual effects and better graphics
- Sound effects and music
- Save/load game progress
- Level editor for custom puzzles 