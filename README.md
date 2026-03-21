Sloptorio
---------

An unfinished, half-AI-written Factorio mod that attempts to rebalance the gameplay of the optional ['quality'](https://wiki.factorio.com/Quality) system by introducing a new "Slop" tier of items, and causing them to be produced from game-start.

Heavily inspired by [Inverted Quality](https://mods.factorio.com/mod/Inverted-Quality); but takes a slightly different approach, in hopes of retaining vanilla's positive "quality" tiers, as well.

Technical
=========
Factorio's quality system only goes "one way": items are produced at the bottom of the quality chain, and then 'promoted' by some chance 'upwards' to better qualities. To achieve what we're trying to do, we have to do something pretty hacky:

1.  We rename the vanilla `"normal"` quality to "Slop",
2.  and then introduce our own `"fine"` quality above it, which is intended to transparently appear equivalent to vanilla gameplay.

This has lots of consequences; and I've no idea how many of them I'll be able to work around, yet:

 - The actual *effect* of quality in the engine is primarily controlled by [`QualityPrototype.level`](https://lua-api.factorio.com/latest/prototypes/QualityPrototype.html#level), which is sadly a `uint32`. Unsigned. That means we can't have a partial ("75% effective"), nor negative, quality-value. We'll probably eventually have to write a lot of patches to make the 'base' effectiveness of many game features lower, then cancel those out with a bonus from the new "fine" quality, to achieve vanilla-like values for "fine" items, while having "slop" items be significantly worse.

 - There's two balancing/tuning limitations that make it really hard to *achieve* a fun experience around the actual quantity of slop produced, vs. the chances of obtaining high-quality items later on in the game, vs. the effectivness of [quality modules](https://wiki.factorio.com/Quality_module). There's only so much I can do; and even after much tweaking of numbers (see [`lib/tuning_defaults.lua`][] and [`quality-math-cli.lua`][]), the experience isn't quite where I want it to be, yet.

   Effectively, there's two axes of opposing limitations:

   1. Decreasing the quantity of "slop" produced at game-start, also decreases the "dynamic range" of improvement available from quality-modules later. Ideally, I would have liked something like ~10-15% slop - enough to force you to engage with byproducts in every single subfactory you design; but little enough to not significantly affect the ratios/resources/TPS/etc of the gameplay besides that. However, that equates to 85-90% of items being upgraded to "fine" from the perspective of the game-engine; and that leaves only that 10-10% range of *available improvement* that an inserted module, even a Legendary tier-3 module, can ever produce. That leaves you with either overproducing rares/epics/legendaries early-game with zero investment into quality-modules ... or significantly underproducing legendaries late-game no matter how hard you try.

   2. In a similar vein, using the quality system is a boolean thing: either a building produces quality-output, or it doesn't. If I enable "quality output" for all buildings, even without modules, to get this slop mechanic, then by definition, those buildings will *also* eventually be producing uncommon, and eventually even *legendary*, items. This means there's no longer the same significant tradeoff between productivity and "maybe I eventually want legendaries" (although in some ways, that's the point of this mod).

 - The game's graphics engine really doesn't like me trying to enable quality-overlay-icons for the default/null/"normal" quality:

   ![screenshot of buggy display of quality icons on belts in-game](https://github.com/user-attachments/assets/dd21a849-3f38-49db-9497-159b9bc27bde)

   See [my bug report](https://forums.factorio.com/viewtopic.php?p=690453); but, unfortunately, someone in Discord mentioned that this may be intended behaviour, which will probably make this mod DOA.
