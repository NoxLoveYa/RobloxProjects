# Drawing API Documentation for Roblox Exploits

A comprehensive guide to using the Drawing API in Roblox exploits like Synapse X, Protosmasher, and others.

## Table of Contents

- [Overview](#overview)
- [Object Types](#object-types)
- [Common Properties](#common-properties)
- [Usage Examples](#usage-examples)
- [Utility Functions](#utility-functions)
- [Important Notes](#important-notes)

## Overview

The Drawing API allows you to create and manipulate 2D rendering objects directly on your screen. These objects persist across games and can be used for ESP, UI elements, crosshairs, and more.

## Object Types

### Line

Creates a line between two points.

```lua
local line = Drawing.new("Line")
```

### Text

Creates text that can be displayed on screen.

```lua
local text = Drawing.new("Text")
```

### Square (Rectangle)

Creates a rectangle or square.

```lua
local square = Drawing.new("Square")
```

### Circle

Creates a circle with customizable smoothness.

```lua
local circle = Drawing.new("Circle")
```

### Quad

Creates a quadrilateral shape (if supported by exploit).

```lua
local quad = Drawing.new("Quad")
```

### Image

Creates an image from data or URL (support varies by exploit).

```lua
local image = Drawing.new("Image")
```

## Common Properties

### Visibility & Basic Properties

| Property | Type | Description |
|---|---|---|
| Visible | boolean | Shows/hides the object |
| Transparency | number | 1 = fully visible, 0 = invisible |
| Color | Color3 | The color of the object |
| Thickness | number | Line thickness in pixels |
| Filled | boolean | Whether to fill the shape |

### Line-Specific Properties

| Property | Type | Description |
|---|---|---|
| From | Vector2 | Starting position |
| To | Vector2 | Ending position |

### Text-Specific Properties

| Property | Type | Description |
|---|---|---|
| Text | string | The text to display |
| Size | number | Font size |
| Center | boolean | Center alignment |
| Outline | boolean | Enable text outline |
| OutlineColor | Color3 | Outline color |
| Position | Vector2 | Text position |
| Font | Enum | Font style (Synapse only) |

### Square/Rectangle Properties

| Property | Type | Description |
|---|---|---|
| Position | Vector2 | Top-left position |
| Size | Vector2 | Width and height |

### Circle Properties

| Property | Type | Description |
|---|---|---|
| Position | Vector2 | Center position |
| Radius | number | Circle radius |
| NumSides | number | Smoothness (more sides = smoother) |

### Quad Properties

| Property | Type | Description |
|---|---|---|
| PointA | Vector2 | First point |
| PointB | Vector2 | Second point |
| PointC | Vector2 | Third point |
| PointD | Vector2 | Fourth point |

### Image Properties

| Property | Type | Description |
|---|---|---|
| Data | string | Base64 or image data (Synapse) |
| Uri | string | Image URL (other exploits) |
| Position | Vector2 | Image position |
| Size | Vector2 | Display size |

## Usage Examples

### Basic Line

```lua
local line = Drawing.new("Line")
line.Visible = true
line.Color = Color3.new(1, 0, 0)  -- Red
line.Thickness = 2
line.From = Vector2.new(0, 0)
line.To = Vector2.new(100, 100)
```

### Text with Outline

```lua
local text = Drawing.new("Text")
text.Visible = true
text.Text = "Hello World"
text.Size = 18
text.Center = true
text.Outline = true
text.Color = Color3.new(1, 1, 1)  -- White
text.Position = Vector2.new(100, 100)
```

### Filled Circle

```lua
local circle = Drawing.new("Circle")
circle.Visible = true
circle.Color = Color3.new(0, 1, 0)  -- Green
circle.Filled = true
circle.Radius = 25
circle.Position = Vector2.new(200, 200)
circle.NumSides = 30
```

### Rectangle Border

```lua
local square = Drawing.new("Square")
square.Visible = true
square.Color = Color3.new(0, 0, 1)  -- Blue
square.Thickness = 3
square.Filled = false
square.Position = Vector2.new(50, 50)
square.Size = Vector2.new(100, 75)
```

## Utility Functions

### NewDrawing Wrapper

The script includes a convenient wrapper function for safe drawing creation:

```lua
function NewDrawing(InstanceName)
    local Instance = Drawing.new(InstanceName)
    return function(Properties)
        for property, value in pairs(Properties) do
            pcall(function()
                Instance[property] = value
            end)
        end
        return Instance
    end
end
```

#### Usage:

```lua
-- Create a line with multiple properties at once
local line = NewDrawing("Line"){
    Color = Color3.new(1, 0, 0),
    Thickness = 2,
    From = Vector2.new(0, 0),
    To = Vector2.new(100, 100),
    Visible = true
}

-- Create text with formatting
local text = NewDrawing("Text"){
    Text = "ESP Text",
    Size = 16,
    Color = Color3.new(1, 1, 1),
    Position = Vector2.new(50, 50),
    Center = true,
    Outline = true,
    Visible = true
}
```


## Important Notes

- **Exploit Compatibility:**
  - Font properties may only work in Synapse
  - Image handling differs between exploits
  - Quad objects may not be supported in all exploits

- **Coordinate System:**
  - Uses screen coordinates with (0,0) at top-left corner
  - `Vector2.new(X, Y)` where X increases right, Y increases down

- **Performance:**
  - Drawing objects persist until manually removed
  - Always clean up objects when done using `object:Remove()`
  - Use `object.Visible = false` to temporarily hide

- **Error Handling:**
  - Use `pcall` when setting properties for cross-exploit compatibility
  - Some properties may throw errors on unsupported exploits

- **Persistence:**
  - Drawing objects remain across game teleports
  - Must be manually cleaned up when script stops

## Checking Exploit Support

```lua
-- Check if Quad is supported
local QUAD_SUPPORTED = pcall(function() 
    Drawing.new('Quad'):Remove() 
end)

-- Check if using Synapse
local IsSynapse = syn and not PROTOSMASHER_LOADED
```