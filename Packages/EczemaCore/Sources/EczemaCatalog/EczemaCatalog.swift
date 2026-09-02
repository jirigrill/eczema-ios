// EczemaCatalog — the bundled static food catalog.
//
// Deliberately empty. The catalog is a fresh derivation with primary sources cited at
// authoring time, never a review pass over the PWA's mappings, so no entry lands here
// until it is sourced.
//
// The decided shape, for whoever fills this in: bundled static data *outside* the
// SwiftData store — no `@Model` for foods, no seeding, no reconcile-on-launch. Only
// `MealItem.foodId` crosses into the schema, which is why this target does not depend
// on EczemaDomain and must not come to.
