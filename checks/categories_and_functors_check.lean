-- Categories and functors: every functor carries isomorphisms to isomorphisms, and the flip-pattern rule (a lamp changes when an odd number of its switches are flipped) turns functions into group maps and keeps chains and do-nothing arrows.
import Mathlib.CategoryTheory.Functor.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.ZMod.Defs
import Mathlib.Algebra.Ring.Parity
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum.Basic
import Mathlib.Order.SymmDiff
import Mathlib.Algebra.BigOperators.Ring.Nat
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open CategoryTheory
open scoped symmDiff

/-- The card's flip-pattern rule F(f). A flip pattern P is a set of flipped switches; the wire
map f sends each switch to the lamp it feeds. F(f)(P) is the set of lamps t fed by an odd
number of switches in P. -/
def flipMap {α β : Type*} [Fintype β] [DecidableEq β] (f : α → β) (P : Finset α) : Finset β :=
  Finset.univ.filter (fun t => Odd (P.filter (fun s => f s = t)).card)


/-- Parity of a symmetric difference: |A ∆ B| + 2|A ∩ B| = |A| + |B|. -/
theorem card_symmDiff_add_two_inter {α : Type*} [DecidableEq α] (A B : Finset α) :
    (A ∆ B).card + 2 * (A ∩ B).card = A.card + B.card := by
  rw [symmDiff_eq_sup_sdiff_inf, ← Finset.card_union_add_card_inter A B]
  have hsub : A ⊓ B ⊆ A ⊔ B := fun x hx => Finset.mem_union_left _ (Finset.mem_inter.1 hx).1
  have hle := Finset.card_le_card hsub
  rw [Finset.card_sdiff_of_subset hsub]
  change (A ∪ B).card - (A ∩ B).card + 2 * (A ∩ B).card = (A ∪ B).card + (A ∩ B).card
  change (A ∩ B).card ≤ (A ∪ B).card at hle
  omega

/-- Membership in a flip map: lamp t is on exactly when an odd number of switches in P feed it. -/
theorem mem_flipMap {α β : Type*} [Fintype β] [DecidableEq β] (f : α → β) (P : Finset α)
    (t : β) : t ∈ flipMap f P ↔ Odd (P.filter (fun s => f s = t)).card := by
  simp [flipMap]

/-- Functors carry isomorphisms to isomorphisms. Let F be a functor from a category C to a
category D. If the arrow f : X → Y is undone on both sides by g : Y → X (g after f is the
do-nothing arrow on X, and f after g is the do-nothing arrow on Y), then F(f) is undone on both
sides by F(g). Lean writes `f ≫ g` for "f first, then g", the card's g ∘ f. -/
theorem functor_maps_iso_to_iso {C D : Type*} [Category C] [Category D] (F : C ⥤ D)
    {X Y : C} (f : X ⟶ Y) (g : Y ⟶ X) (hgf : f ≫ g = 𝟙 X) (hfg : g ≫ f = 𝟙 Y) :
    F.map f ≫ F.map g = 𝟙 (F.obj X) ∧ F.map g ≫ F.map f = 𝟙 (F.obj Y) := by
  exact ⟨by rw [← F.map_comp, hgf, F.map_id], by rw [← F.map_comp, hfg, F.map_id]⟩

/-- The switch rule gives a group map: for any function f from a set of switches to a finite
set of lamps, and any two flip patterns P and Q, F(f) sends P ∆ Q (the switches flipped in
exactly one of P and Q) to F(f)(P) ∆ F(f)(Q). -/
theorem flipMap_symmDiff {α β : Type*} [DecidableEq α] [Fintype β] [DecidableEq β]
    (f : α → β) (P Q : Finset α) :
    flipMap f (P ∆ Q) = flipMap f P ∆ flipMap f Q := by
  ext t
  have hfil : (P ∆ Q).filter (fun s => f s = t) =
      P.filter (fun s => f s = t) ∆ Q.filter (fun s => f s = t) := by
    ext s; simp only [Finset.mem_filter, Finset.mem_symmDiff]; tauto
  have key := card_symmDiff_add_two_inter (P.filter (fun s => f s = t)) (Q.filter (fun s => f s = t))
  simp only [mem_flipMap, Finset.mem_symmDiff, hfil]
  simp only [Nat.odd_iff]
  omega

/-- The switch rule keeps chains and do-nothing arrows, so F is a functor: for wire maps
f : A → B and g : B → C between finite sets and every flip pattern P,
F(g ∘ f)(P) = F(g)(F(f)(P)), and F(id_A)(P) = P. -/
theorem flipMap_comp_and_id {α β γ : Type*} [Fintype α] [DecidableEq α] [Fintype β]
    [DecidableEq β] [Fintype γ] [DecidableEq γ] (f : α → β) (g : β → γ) :
    (∀ P : Finset α, flipMap (g ∘ f) P = flipMap g (flipMap f P)) ∧
      (∀ P : Finset α, flipMap id P = P) := by
  refine ⟨fun P => ?_, fun P => ?_⟩
  · ext t
    have hmaps : ((P.filter (fun s => (g ∘ f) s = t) : Finset α) : Set α).MapsTo f
        (Finset.univ.filter (fun u => g u = t) : Finset β) := by
      intro s hs
      simp only [Finset.coe_filter, Set.mem_ofPred_eq, Function.comp_apply] at hs
      simp [hs.2]
    have hsum := Finset.card_eq_sum_card_fiberwise hmaps
    rw [mem_flipMap, mem_flipMap, hsum, Finset.odd_sum_iff_odd_card_odd]
    congr! 2
    ext u
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, mem_flipMap]
    constructor
    · rintro ⟨hu, hodd⟩
      refine ⟨?_, hu⟩
      convert hodd using 2
      ext s
      simp only [Finset.mem_filter, Function.comp_apply]
      constructor
      · rintro ⟨hs, rfl⟩; exact ⟨⟨hs, hu⟩, rfl⟩
      · rintro ⟨⟨hs, _⟩, h⟩; exact ⟨hs, h⟩
    · rintro ⟨hodd, hu⟩
      refine ⟨hu, ?_⟩
      convert hodd using 2
      ext s
      simp only [Finset.mem_filter, Function.comp_apply]
      constructor
      · rintro ⟨⟨hs, _⟩, h⟩; exact ⟨hs, h⟩
      · rintro ⟨hs, rfl⟩; exact ⟨⟨hs, hu⟩, rfl⟩
  · ext t
    rw [mem_flipMap]
    simp only [id]
    rw [Finset.filter_eq']
    split_ifs with h <;> simp [h]

-- Hom-set sizes: 3^3 = 27 functions from three switches to three, and 56 arrows in all
-- among {0}, {0,1}, {0,1,2}.
example : Fintype.card (Fin 3 → Fin 3) = 27 := by decide
example : 1 + 2 + 3 + 1 + 4 + 9 + 1 + 8 + 27 = 56 := by norm_num
-- Homomorphisms from the 4-hour clock to the 2-hour clock: 2. Arrows among C2, C3, C4, V: 51.
example : (Finset.univ.filter
    (fun h : ZMod 4 → ZMod 2 => ∀ a b, h (a + b) = h a + h b)).card = 2 := by decide
example : 9 + 6 + 11 + 25 = 51 := by norm_num
-- Bijections: 1 + 2 + 6 = 9 set isomorphisms; 24 bijections from C4 to V.
example : Fintype.card (Fin 3 ≃ Fin 3) = 6 ∧ Fintype.card (Fin 4 ≃ Fin 4) = 24 := by decide
-- Stair wiring w: both switches feed lamp 0; its four flip patterns.
example : flipMap (fun _ : Fin 2 => (0 : Fin 1)) ∅ = ∅ ∧
    flipMap (fun _ : Fin 2 => (0 : Fin 1)) {0} = {0} ∧
    flipMap (fun _ : Fin 2 => (0 : Fin 1)) {1} = {0} ∧
    flipMap (fun _ : Fin 2 => (0 : Fin 1)) {0, 1} = ∅ := by decide
-- The tempting wrong rule, "lamps touched at all", says the lamp changes when both flip.
example : ({0, 1} : Finset (Fin 2)).image (fun _ => (0 : Fin 1)) = {0} := by decide
-- Landing: f = [0, 1, 0], g = [0, 0]; flip all three switches.
example : flipMap (![0, 1, 0] : Fin 3 → Fin 2) {0, 1, 2} = {1} ∧
    flipMap (![0, 0] : Fin 2 → Fin 1) {1} = {0} ∧
    flipMap ((![0, 0] : Fin 2 → Fin 1) ∘ (![0, 1, 0] : Fin 3 → Fin 2)) {0, 1, 2} = {0} := by
  decide

#print axioms card_symmDiff_add_two_inter
#print axioms mem_flipMap
#print axioms functor_maps_iso_to_iso
#print axioms flipMap_symmDiff
#print axioms flipMap_comp_and_id
