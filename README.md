# Canvas - In-game image displays
![Banner](https://i.imgur.com/3Olfx6S.png)

--------

### Display Images In-Game Easily!
Spawning the entity allows you to select the model and easily manipulate it like a prop, when you are not holding a phys/toolgun the model is invisible and only the image remains!

### BaseWars Support Out The Box
Automatically prevents making unraidable bases by making all canvases no-colliding when a raid is ongoing!

You can easily add them to the BaseWars Buy Menu in the config like so:
```lua
["Canvas"] = BaseWars.GSL{Model = "models/hunter/plates/plate1x1.mdl", Price = 5e5, ClassName = "canvas", UseSpawnFunc = true},
```

### More Coming Soon!
- [x] Duplicator / Perma Prop support.
- [ ] More configuration options.
- [ ] Admin controls for domain white/blacklist.
- [ ] Improved UI.

... along with performance gains, not that it's an issue now!

### LICENSE
Canvas is licensed under the [MIT License](license.md); do whatever you want with it, just include the original credits please!

### Credits
- Q2F2 - Current maintainer, reworking of Zeni's prototype, QOL improvements
- Zeni - Original code, reworking of user's version
- user4992 - Original original code
