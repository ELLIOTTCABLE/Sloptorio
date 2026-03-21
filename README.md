Sloptorio
---------
An experimental Factorio mod that attempts to rebalance the gameplay of the optional ['quality'](https://wiki.factorio.com/Quality) system by introducing a new "Slop" tier of items, and causing them to be produced from game-start.

Heavily inspired by [Inverted Quality](https://mods.factorio.com/mod/Inverted-Quality); but takes a slightly different approach, in hopes of retaining vanilla's positive "quality" tiers, as well.

Yes, the name is a joke (I'm trying to maintain my skills by ensuring I know how the fuck to use AI models to write not-shitty code. It's a struggle.); but it's also a legitimate balance concern I have with the game, and is intended to become an actually-playable game mode.

Game-design & goals
===================
At the moment, gameplay in Factorio 2.0 with 'quality' enabled gets a lot of flack (and IMO, rightly so).

The dream of quality is, effectively, "Factorio, hard mode." Instead of byproduct-balancing, overproduction-handling, and slack-uptake being limited to issues you need to deal with in a few niche cases (for instance, Advanced Oil Production, where underconsuming heavy oil would traditonally "back up" and stop you producing the petroleum gas you were depending on), with quality turned on, *every single subfactory* in your game has an entirely new dimension and mechanic that you need to balance.

There's two primary problems:

1. In the vanilla balance, *actually building factories that use quality* is objectively inefficient. The default way players reach for those desirable "legendary-quality" pieces of equipment and buildings is to build a "recycler loop" at the end of a complex production chain. This is so *so* very much easier than actually dealing with "quality byproducts" in all of your factories (tons of diverting mechanisms, splitters, complexadditional belts/bots) that it feels wasteful, and borderline masochistic, to try to actually account for quality anywhere else in the production-chain. Losing out on the productivity from productivity-modules, wasting your input resources on a random smattering of quality-outputs that you don't even know how you're going to use yet ... it just can't compete.

2. By the time you unlock quality (or more importantly, the *desirable* qualities, like epic/legendary), most of your factories are built - and even *if* you don't use a recycler loop, the opportunity-cost is just too high, to redesign all of the factories in your entire game around attempting to obtain, collate, and consume enough quality-byproducts to work your way up to legendaries.

No. 1 is well-handled by other mods, like [No Quality Recycling](https://mods.factorio.com/mod/No-Qualitycycling) or [Recyclers Erase Quality](https://mods.factorio.com/mod/RecyclersEraseQuality).) But that actually exacerbates No. 2 - because you're not really left with any realistic way to obtain high-quality equipment or buildings. The best case is to start from scratch. Again, it's ... unfun.

This mod is intended to be used in conjunction with one of those mods, and is focused on No. 2. I'm trying to balance the game such that the player is not rewarded for playing in un-fun ways. I can't make "paying attention to quality" *easier* (and I wouldn't want to? this is Factorio, fun is hard, hard is fun. That's the fucking point of the game, lol.) - so the correct rebalance is to make playing not-that-way *harder*.

(Obviously, this is a mod; and it's not for everyone. I'm not suggesting the base game should be this way. The whole point is to make this style of play supported and encouraged by the mechanics, and make it feel less like you're making wasteful/stupid decisions *while* you're playing that way, for those of us who want to - I'm not saying you're a bad Factorio player if you don't want to deal with balancing byproducts!)

Hence, my approach:

1. **Produce quality-byproducts from game-start.** There's no longer an easy-way-out that it "feels wasteful" to avoid; every factory *has* to deal with them.
2. **Nerf high-quality output chances.** Now that you're going to both A. be producing quality byproducts *constantly*, for hundreds of hours, while you're building everything and progressing through the game, instead of for a little while at the end of progression; and B. have an *entire megafactory* contributing to quality-production ... well, it could definitely go the opposite direction and make it too easy in a *different* way to get quality equipment.
3. **Free up the module slot for more strategic choice.** There's still Quality Modules; but they're no longer necessary to get *some* quality outputs; they're more of a strategic choice vs. productivity (or speed) modules. They're still useful in chains where you want to ensure reasonable chances of rolling a legendary item; and they also contribute to reducing wastage on Slop-quality outputs; but they're no longer a boolean "definitely not" (for most of your factory) and "definitely" (for that one recycling-corner custom-built to chase legendary rolls.)


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
