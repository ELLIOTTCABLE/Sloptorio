- Keep this file very short; only add items that have been *repeatedly* forgotten (i.e. if I yell at you to)
- Notes must stay high-level: capture repeated mistakes and surprising Factorio/model behaviors, not noisy run-by-run details.
- Keep one visible source of truth in workspace notes; avoid hidden memory-only notes.

----

- factorio quality goes normal/unc/rare ... this project introduces "fine" between normal/uncommon
- NYI, but this project will *reduce* the effect of "normal" and rename it "slop", making "fine" effectively the new normal. when comparing vanilla values and modded values, do not forget this, as it means you need to shift up-by-one so "fine" compares to "normal", "uncommon" compares to "uncommon", and so on. Be very careful and precise with the *context* of a name, because they're ambiguous: when interfacing with the factorio API or reading documentation, "normal" means level=0; but we never otherwise use the word "normal" because it is ambiguous. stick to "slop" and "fine" where possible.
- the `level` multiplier in vanilla (and here) skips a step from epic (level=3) to legendary (level=5). there is no level 4.
- we are limited by blackbox quality implementation in the core game to only adjusting the "quality curve" via some indirect knobs - the default values are in `tuning_defaults.lua`; in particular, we can *mostly* only adjust the "entry point" and some properties of the curve, but not directly adjust the value of each level. this is unfortunate as it is desirable to have very different behaviour from "slop" to "fine" (we want ~75-85% of items to graduate to "fine"), but then vanilla-like behaviour thereafter. in particular lots of tunings produce legendary items in much more bulk than we want, or preclude legendaries even when the player invests lots into modules.
- another limitation is the 'dynamic range' of module quality; if we produce less slop (i.e. 15% instead of 25%), then, since the only thing a module-insertion can affect is increase that number (from 85% to 100%), giving very little ability for modules to feel valuable (and even *less* ability for a tier-3 module to feel significantly more valuable than a tier-1)
- there are no automated tests. only a CLI you can invoke to gauge tuning correctness.
- this is not in production, no need for migrations and changing of settings is free
