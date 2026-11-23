-- Universal properties: any two products of the same two objects match by exactly one isomorphism that keeps the projections, and the same holds for every limit and colimit.
import Mathlib.CategoryTheory.Limits.Shapes.BinaryProducts.BinaryFan
import Mathlib.CategoryTheory.Limits.IsLimit
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum
import Mathlib.Data.Nat.Factorial.Basic

open CategoryTheory CategoryTheory.Limits

universe v u w w'

/-- Products are unique up to unique isomorphism: if `P` (with projections `P.fst`, `P.snd`)
and `P'` (with projections `P'.fst`, `P'.snd`) are both products of `A` and `B` in any
category, then exactly one isomorphism `u : P ≅ P'` keeps both projections,
that is `π'_A ∘ u = π_A` and `π'_B ∘ u = π_B`. -/
theorem product_unique_up_to_unique_iso {C : Type u} [Category.{v} C] {A B : C}
    (P P' : BinaryFan A B) (hP : IsLimit P) (hP' : IsLimit P') :
    ∃! u : P.pt ≅ P'.pt, u.hom ≫ P'.fst = P.fst ∧ u.hom ≫ P'.snd = P.snd := by
  refine ⟨hP.conePointUniqueUpToIso hP', ⟨?_, ?_⟩, ?_⟩
  · exact IsLimit.conePointUniqueUpToIso_hom_comp hP hP' ⟨WalkingPair.left⟩
  · exact IsLimit.conePointUniqueUpToIso_hom_comp hP hP' ⟨WalkingPair.right⟩
  · rintro v ⟨h1, h2⟩
    ext
    refine BinaryFan.IsLimit.hom_ext hP' ?_ ?_
    · rw [h1]; exact (IsLimit.conePointUniqueUpToIso_hom_comp hP hP' ⟨WalkingPair.left⟩).symm
    · rw [h2]; exact (IsLimit.conePointUniqueUpToIso_hom_comp hP hP' ⟨WalkingPair.right⟩).symm

/-- Limits and colimits gather every case: for any diagram `F`, any two limit cones match by
exactly one isomorphism that keeps every arrow of the cone, and any two colimit cocones match by
exactly one isomorphism that keeps every arrow of the cocone. -/
theorem limits_and_colimits_unique_up_to_unique_iso {J : Type w} [Category.{w'} J]
    {C : Type u} [Category.{v} C] (F : J ⥤ C) :
    (∀ (s t : Cone F), IsLimit s → IsLimit t →
      ∃! u : s.pt ≅ t.pt, ∀ j : J, u.hom ≫ t.π.app j = s.π.app j) ∧
    (∀ (s t : Cocone F), IsColimit s → IsColimit t →
      ∃! u : s.pt ≅ t.pt, ∀ j : J, s.ι.app j ≫ u.hom = t.ι.app j) := by
  refine ⟨fun s t hs ht => ?_, fun s t hs ht => ?_⟩
  · refine ⟨hs.conePointUniqueUpToIso ht, fun j => IsLimit.conePointUniqueUpToIso_hom_comp hs ht j, ?_⟩
    intro v hv
    ext
    refine ht.hom_ext fun j => ?_
    rw [hv j]; exact (IsLimit.conePointUniqueUpToIso_hom_comp hs ht j).symm
  · refine ⟨hs.coconePointUniqueUpToIso ht, fun j => IsColimit.comp_coconePointUniqueUpToIso_hom hs ht j, ?_⟩
    intro v hv
    ext
    refine hs.hom_ext fun j => ?_
    rw [hv j]; exact (IsColimit.comp_coconePointUniqueUpToIso_hom hs ht j).symm

/-- The set of pairs has the property: for sets `A`, `B` and any `f : X → A`, `g : X → B`,
exactly one function `h : X → A × B` satisfies `fst ∘ h = f` and `snd ∘ h = g`
(namely `h x = (f x, g x)`). -/
theorem pairs_have_product_property {X A B : Type u} (f : X → A) (g : X → B) :
    ∃! h : X → A × B, Prod.fst ∘ h = f ∧ Prod.snd ∘ h = g := by
  refine ⟨fun x => (f x, g x), ⟨rfl, rfl⟩, ?_⟩
  rintro h ⟨rfl, rfl⟩
  rfl

-- 2 colours × 3 sizes give 6 stock lines.
example : 2 * 3 = 6 := by norm_num
-- Arrows from 4 orders to colours, to sizes: 2^4 = 16 and 3^4 = 81; pairs (f, g): 16 × 81 = 1,296.
example : (2 : ℕ) ^ 4 = 16 ∧ (3 : ℕ) ^ 4 = 81 ∧ 16 * 81 = 1296 := by norm_num
-- |Hom(X, A × B)| = |Hom(X, A)| × |Hom(X, B)|: 6^4 = 1296 = 16 × 81.
example : (6 : ℕ) ^ 4 = 1296 ∧ (6 : ℕ) ^ 4 = 2 ^ 4 * 3 ^ 4 := by norm_num
-- The same count on the actual finite sets: 4 orders, 2 colours, 3 sizes.
example : Fintype.card (Fin 4 → Fin 2 × Fin 3) =
    Fintype.card (Fin 4 → Fin 2) * Fintype.card (Fin 4 → Fin 3) := by
  norm_num
-- Functions from lines to codes: 6^6 = 46,656; bijections: 6! = 720.
example : (6 : ℕ) ^ 6 = 46656 := by norm_num
example : Nat.factorial 6 = 720 := by decide
-- The matching (c, s) ↦ 3c + s sends (blue, M) = (1, 1) to code 4, and code 4 reads back as (1, 1).
example : 3 * 1 + 1 = 4 ∧ 4 / 3 = 1 ∧ 4 % 3 = 1 := by decide
-- Missing blue L: 1,296 − 5^4 = 671 pairs met by no arrow.
example : 1296 - 5 ^ 4 = 671 := by norm_num
-- Coproduct: 2 + 3 = 5 tagged points; 2^5 = 32 arrows to yes/no against 2^2 × 2^3 = 4 × 8 = 32 pairs.
example : 2 + 3 = 5 ∧ (2 : ℕ) ^ 5 = 2 ^ 2 * 2 ^ 3 ∧ 2 ^ 2 * 2 ^ 3 = 32 := by norm_num
-- The 6 lines used as the coproduct: 2^6 = 64 arrows to yes/no, not 32.
example : (2 : ℕ) ^ 6 = 64 := by norm_num
-- Free product words of length 0 to 4: 1, 3, 4, 6, 8, running totals 1, 4, 8, 14, 22.
example : 1 + 3 = 4 ∧ 4 + 4 = 8 ∧ 8 + 6 = 14 ∧ 14 + 8 = 22 := by norm_num

#print axioms product_unique_up_to_unique_iso
#print axioms limits_and_colimits_unique_up_to_unique_iso
#print axioms pairs_have_product_property
