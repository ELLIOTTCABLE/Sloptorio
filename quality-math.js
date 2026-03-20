#!/usr/bin/env node

function clamp01(x) {
   return Math.max(0, Math.min(1, x));
}

function distribution({
   baseEffectQuality,
   normalNextProbability,
   fineNextProbability,
   uncommonNextProbability,
   rareNextProbability,
   epicNextProbability,
   maxLevel,
}) {
   const startChance = clamp01(baseEffectQuality * clamp01(normalNextProbability));
   const qFine = clamp01(fineNextProbability);
   const qUncommon = clamp01(uncommonNextProbability);
   const qRare = clamp01(rareNextProbability);
   const qEpic = clamp01(epicNextProbability);

   const out = {
      normal: 1 - startChance,
      fine: 0,
      uncommon: 0,
      rare: 0,
      epic: 0,
      legendary: 0,
   };

   if (maxLevel < 1) {
      return out;
   }

   const continueFromFine = maxLevel >= 2 ? qFine : 0;
   out.fine = startChance * (1 - continueFromFine);

   if (maxLevel >= 2) {
      const atUncommon = startChance * continueFromFine;
      const continueFromUncommon = maxLevel >= 3 ? qUncommon : 0;
      out.uncommon = atUncommon * (1 - continueFromUncommon);

      if (maxLevel >= 3) {
         const atRare = atUncommon * continueFromUncommon;
         const continueFromRare = maxLevel >= 4 ? qRare : 0;
         out.rare = atRare * (1 - continueFromRare);

         if (maxLevel >= 4) {
            const atEpic = atRare * continueFromRare;
            const continueFromEpic = maxLevel >= 5 ? qEpic : 0;
            out.epic = atEpic * (1 - continueFromEpic);
            out.legendary = atEpic * continueFromEpic;
         }
      }
   }

   return out;
}

function inferFromCounts(counts) {
   const total =
      counts.normal + counts.fine + counts.uncommon + counts.rare + counts.epic + counts.legendary;

   if (total <= 0) {
      throw new Error("Total count must be > 0");
   }

   const startChance = 1 - counts.normal / total;

   const tailFromFine = counts.fine + counts.uncommon + counts.rare + counts.epic + counts.legendary;
   const tailFromUncommon = counts.uncommon + counts.rare + counts.epic + counts.legendary;
   const tailFromRare = counts.rare + counts.epic + counts.legendary;
   const tailFromEpic = counts.epic + counts.legendary;

   const fineNextProbability = tailFromFine > 0 ? tailFromUncommon / tailFromFine : 0;
   const uncommonNextProbability = tailFromUncommon > 0 ? tailFromRare / tailFromUncommon : 0;
   const rareNextProbability = tailFromRare > 0 ? tailFromEpic / tailFromRare : 0;
   const epicNextProbability = tailFromEpic > 0 ? counts.legendary / tailFromEpic : 0;

   return {
      total,
      baseEffectQualityApprox: Math.round(startChance * 100),
      fineNextProbability,
      uncommonNextProbability,
      rareNextProbability,
      epicNextProbability,
   };
}

function parseArgs(argv) {
   const args = Object.fromEntries(
      argv
         .filter((s) => s.includes("="))
         .map((s) => {
            const [k, v] = s.split("=");
            return [k.replace(/^--/, ""), Number(v)];
         })
   );

   return {
      baseEffectQuality: Number.isFinite(args.baseEffectQuality) ? args.baseEffectQuality : 70,
      targetNormal: Number.isFinite(args.targetNormal) ? args.targetNormal : null,
      normalNextProbability: Number.isFinite(args.normalNextProbability) ? args.normalNextProbability : 0.02,
      fineNextProbability: Number.isFinite(args.fineNextProbability) ? args.fineNextProbability : 0.10,
      uncommonNextProbability: Number.isFinite(args.uncommonNextProbability)
         ? args.uncommonNextProbability
         : 0.10,
      rareNextProbability: Number.isFinite(args.rareNextProbability) ? args.rareNextProbability : 0.10,
      epicNextProbability: Number.isFinite(args.epicNextProbability) ? args.epicNextProbability : 0.10,
      maxLevel: Number.isFinite(args.maxLevel) ? Math.max(0, Math.floor(args.maxLevel)) : 5,
      normal: Number.isFinite(args.normal) ? args.normal : null,
      fine: Number.isFinite(args.fine) ? args.fine : null,
      uncommon: Number.isFinite(args.uncommon) ? args.uncommon : null,
      rare: Number.isFinite(args.rare) ? args.rare : null,
      epic: Number.isFinite(args.epic) ? args.epic : null,
      legendary: Number.isFinite(args.legendary) ? args.legendary : null,
   };
}

function main() {
   const cfg = parseArgs(process.argv.slice(2));

   if (cfg.targetNormal !== null) {
      const targetStartChance = clamp01(1 - cfg.targetNormal);
      const denom = clamp01(cfg.normalNextProbability);
      cfg.baseEffectQuality = denom > 0 ? targetStartChance / denom : 0;
      console.log("targetNormal=" + cfg.targetNormal);
      console.log("normalNextProbability=" + cfg.normalNextProbability);
      console.log("baseEffectQuality=" + cfg.baseEffectQuality.toFixed(6));
   }

   const hasCounts = [cfg.normal, cfg.fine, cfg.uncommon, cfg.rare, cfg.epic, cfg.legendary].every(
      (x) => x !== null
   );

   if (hasCounts) {
      const inferred = inferFromCounts({
         normal: cfg.normal,
         fine: cfg.fine,
         uncommon: cfg.uncommon,
         rare: cfg.rare,
         epic: cfg.epic,
         legendary: cfg.legendary,
      });
      console.log("inferred.total=" + inferred.total);
      console.log("inferred.startChance=" + (inferred.baseEffectQualityApprox / 100).toFixed(6));
      if (cfg.normalNextProbability > 0) {
         const inferredBaseEffect = (inferred.baseEffectQualityApprox / 100) / cfg.normalNextProbability;
         console.log("inferred.baseEffectQualityApprox=" + inferredBaseEffect.toFixed(6));
      }
      console.log("inferred.fineNextProbability=" + inferred.fineNextProbability.toFixed(6));
      console.log("inferred.uncommonNextProbability=" + inferred.uncommonNextProbability.toFixed(6));
      console.log("inferred.rareNextProbability=" + inferred.rareNextProbability.toFixed(6));
      console.log("inferred.epicNextProbability=" + inferred.epicNextProbability.toFixed(6));
   }

   const dist = distribution(cfg);
   console.log("baseEffectQuality=" + cfg.baseEffectQuality);
   console.log("normalNextProbability=" + cfg.normalNextProbability);
   console.log("fineNextProbability=" + cfg.fineNextProbability);
   console.log("uncommonNextProbability=" + cfg.uncommonNextProbability);
   console.log("rareNextProbability=" + cfg.rareNextProbability);
   console.log("epicNextProbability=" + cfg.epicNextProbability);
   console.log("maxLevel=" + cfg.maxLevel);

   console.log("normal=" + (dist.normal * 100).toFixed(2) + "%");
   console.log("fine=" + (dist.fine * 100).toFixed(2) + "%");
   console.log("uncommon=" + (dist.uncommon * 100).toFixed(2) + "%");
   console.log("rare=" + (dist.rare * 100).toFixed(2) + "%");
   console.log("epic=" + (dist.epic * 100).toFixed(2) + "%");
   console.log("legendary=" + (dist.legendary * 100).toFixed(2) + "%");
}

main();
