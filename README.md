# 3D Trail addon for Godot

![trail](https://user-images.githubusercontent.com/52043844/59968224-af19ff80-9536-11e9-81b2-8d815403904b.png)

## Disclaimer

+ This addon is still a work in progress and far from a usable state
+ Initialy developped for my game (codenamed GlassMainframe, hence the "gm" prefix)
+ Feel free to fork it and reuse what you can.

## Overview

Add 3D trail custom node for Godot Engine
+ Dynamically created at runtime
+ Resolution can be changed (Lower value means higher vertex count)
+ It's just a mesh so you can apply your own materials on it

## How to use
+ Go to **Project settings > Plugins** and activate the **Trail** plugin
+ Add a **Trail** node to your scene
  - Add two Spatial nodes named **Top** and **Bottom** to your trail
  - These two points defined the width of the trail
  - The LifeTime parameter defines how long the trail is
