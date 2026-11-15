-- Orientability: a connected surface built from panels has a consistent turning sense exactly when the twists round every closed path of panels multiply to +1, and then it has exactly two.
import Mathlib.Combinatorics.Quiver.ConnectedComponent
import Mathlib.Algebra.GroupWithZero.Units.Fintype
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Tactic.NormNum
import Mathlib.Data.Int.Order.Units

/-- A surface built from panels, as the card sets it up. `P` is the set of panels and `E`
the set of shared edges. Each shared edge `e`, with one arrow fixed on it, lies on the side
of panel `T₁ e` and on the side of panel `T₂ e` (the same panel twice when a panel is glued
to itself). `c₁ e` is `+1` when `T₁ e`'s anticlockwise walk runs along `e` with the arrow and
`-1` when against: the card's `c(T, e)`. `c₂ e` is the same for `T₂ e`. A rim edge, on one
panel only, joins nothing and is left out. Giving each shared edge exactly two sides is the
card's condition that every edge is on at most two panels. -/
structure Panelling (P E : Type*) where
  /-- The first panel on the shared edge. -/
  T₁ : E → P
  /-- The second panel on the shared edge. -/
  T₂ : E → P
  /-- `c(T₁ e, e)`: `+1` if the first panel's walk follows the edge's arrow, `-1` if against. -/
  c₁ : E → ℤˣ
  /-- `c(T₂ e, e)`: the same for the second panel. -/
  c₂ : E → ℤˣ

namespace Panelling

variable {P E : Type*} (S : Panelling P E)

/-- A choice of senses `s`, `+1` keeping each panel's anticlockwise walk and `-1` reversing it,
is consistent when on every shared edge the two walks run in opposite directions:
`s_{T'} c(T', e) = -(s_T c(T, e))`. -/
def Consistent (s : P → ℤˣ) : Prop :=
  ∀ e, s (S.T₂ e) * S.c₂ e = -(s (S.T₁ e) * S.c₁ e)

/-- The surface is orientable when some choice of senses is consistent. -/
def Orientable : Prop :=
  ∃ s : P → ℤˣ, S.Consistent s

/-- The twist of a shared edge: `t(e) = -c(T, e) c(T', e)`. -/
def twist (e : E) : ℤˣ :=
  -(S.c₁ e * S.c₂ e)

/-- The panels, as the stops of paths. -/
def Panel (_ : Panelling P E) : Type _ := P

/-- Each shared edge `e` is a step from panel `T₁ e` to panel `T₂ e`. Paths in
`Quiver.Symmetrify S.Panel` may cross each edge either way. -/
instance : Quiver S.Panel where
  Hom a b := {e : E // S.T₁ e = a ∧ S.T₂ e = b}

/-- The twist of one crossing, whichever way the edge is crossed. -/
def crossingTwist {a b : Quiver.Symmetrify S.Panel} : (a ⟶ b) → ℤˣ
  | Sum.inl e => S.twist e.1
  | Sum.inr e => S.twist e.1

/-- The product of the twists of every edge a path of panels crosses. -/
def twistProd (S : Panelling P E) {a : Quiver.Symmetrify S.Panel} :
    ∀ {b : Quiver.Symmetrify S.Panel}, Quiver.Path a b → ℤˣ
  | _, .nil => 1
  | _, .cons p e => twistProd S p * S.crossingTwist e

/-- The surface is connected: there is at least one panel, and any two panels are joined by a
path of panels, each step crossing a shared edge. -/
def Connected : Prop :=
  Nonempty P ∧ Quiver.IsStronglyConnected (Quiver.Symmetrify S.Panel)

end Panelling

open Panelling

theorem Panelling.twistProd_comp {P E : Type*} (S : Panelling P E)
    {a b : Quiver.Symmetrify S.Panel} (p : Quiver.Path a b) :
    ∀ {c : Quiver.Symmetrify S.Panel} (q : Quiver.Path b c),
      S.twistProd (p.comp q) = S.twistProd p * S.twistProd q
  | _, .nil => by simp [Panelling.twistProd]
  | _, .cons q e => by
    rw [Quiver.Path.comp_cons, Panelling.twistProd, Panelling.twistProd,
      Panelling.twistProd_comp S p q, mul_assoc]

theorem Panelling.crossingTwist_reverse {P E : Type*} (S : Panelling P E)
    {a b : Quiver.Symmetrify S.Panel} (e : a ⟶ b) :
    S.crossingTwist (Quiver.reverse e) = S.crossingTwist e := by
  cases e <;> rfl

theorem Panelling.twistProd_reverse {P E : Type*} (S : Panelling P E)
    {a : Quiver.Symmetrify S.Panel} :
    ∀ {b : Quiver.Symmetrify S.Panel} (p : Quiver.Path a b),
      S.twistProd p.reverse = S.twistProd p
  | _, .nil => rfl
  | _, .cons p e => by
    rw [Quiver.Path.reverse, Panelling.twistProd_comp, Panelling.twistProd_reverse S p]
    simp only [Quiver.Hom.toPath, Panelling.twistProd, Panelling.crossingTwist_reverse, one_mul]
    rw [mul_comm]

theorem Panelling.sense_eq_twistProd_mul {P E : Type*} (S : Panelling P E) (s : P → ℤˣ)
    (hs : ∀ e, s (S.T₂ e) = S.twist e * s (S.T₁ e)) {a : Quiver.Symmetrify S.Panel} :
    ∀ {b : Quiver.Symmetrify S.Panel} (γ : Quiver.Path a b), s b = S.twistProd γ * s a
  | _, .nil => by simp [Panelling.twistProd]
  | _, .cons γ e => by
    have ih := Panelling.sense_eq_twistProd_mul S s hs γ
    rcases e with ⟨e, h1, h2⟩ | ⟨e, h1, h2⟩
    · subst h1 h2
      simp only [Panelling.twistProd, Panelling.crossingTwist]
      rw [hs e, ih, ← mul_assoc, mul_comm (S.twist e)]
    · subst h1 h2
      have h := hs e
      simp only [Panelling.twistProd, Panelling.crossingTwist]
      rw [mul_comm (S.twistProd γ), mul_assoc, ← ih, h, ← mul_assoc, Int.units_mul_self, one_mul]

/-- The edge rule (Step 1). A choice of senses is consistent exactly when, across every shared
edge `e`, the second panel's sense is the first panel's sense times the twist:
`s_{T'} = t(e) s_T`. -/
theorem consistent_iff_sense_eq_twist_mul {P E : Type*} (S : Panelling P E) (s : P → ℤˣ) :
    S.Consistent s ↔ ∀ e, s (S.T₂ e) = S.twist e * s (S.T₁ e) := by
  unfold Panelling.Consistent Panelling.twist
  refine forall_congr' fun e => ?_
  constructor
  · intro h
    have h' := congrArg (· * S.c₂ e) h
    simp only [mul_assoc, Int.units_mul_self, mul_one] at h'
    rw [h', neg_mul, neg_mul]
    congr 1
    ac_rfl
  · intro h
    rw [h, neg_mul, neg_mul, mul_comm (S.c₁ e * S.c₂ e), mul_assoc, mul_assoc,
      Int.units_mul_self, mul_one]

/-- The loop test. A connected surface built from panels, every edge on at most two panels, is
orientable exactly when, round every closed path of panels, the twists of the edges crossed
multiply to `+1`. -/
theorem orientable_iff_twist_prod_eq_one_of_closed_path {P E : Type*} (S : Panelling P E)
    (hS : S.Connected) :
    S.Orientable ↔
      ∀ (a : Quiver.Symmetrify S.Panel) (γ : Quiver.Path a a), S.twistProd γ = 1 := by
  rw [Panelling.Orientable]
  constructor
  · rintro ⟨s, hs⟩ a γ
    rw [consistent_iff_sense_eq_twist_mul] at hs
    have h := S.sense_eq_twistProd_mul s hs γ
    exact (mul_eq_right.mp h.symm)
  · intro h
    obtain ⟨p0⟩ : Nonempty (Quiver.Symmetrify S.Panel) := hS.1
    have hc := hS.2
    have indep : ∀ (b : Quiver.Symmetrify S.Panel) (p q : Quiver.Path p0 b),
        S.twistProd p = S.twistProd q := by
      intro b p q
      have := h _ (p.comp q.reverse)
      rw [S.twistProd_comp, S.twistProd_reverse] at this
      rw [← mul_one (S.twistProd p), ← Int.units_mul_self (S.twistProd q), ← mul_assoc, this,
        one_mul]
    refine ⟨fun b => S.twistProd (Classical.choice (hc p0 b)), ?_⟩
    rw [consistent_iff_sense_eq_twist_mul]
    intro e
    have := indep (S.T₂ e) (Classical.choice (hc p0 (S.T₂ e)))
      ((Classical.choice (hc p0 (S.T₁ e))).cons (Sum.inl ⟨e, rfl, rfl⟩))
    refine this.trans ?_
    exact mul_comm _ _

/-- The count. On a connected surface built from panels, there are exactly 2 consistent
choices of senses or none: 2 when it is orientable, 0 when it is not. -/
theorem card_consistent_eq_two_or_zero {P E : Type*} (S : Panelling P E) (hS : S.Connected) :
    (S.Orientable → Nat.card {s : P → ℤˣ // S.Consistent s} = 2) ∧
      (¬ S.Orientable → Nat.card {s : P → ℤˣ // S.Consistent s} = 0) := by
  obtain ⟨p0⟩ : Nonempty (Quiver.Symmetrify S.Panel) := hS.1
  have hc := hS.2
  have dich : ∀ s s' : P → ℤˣ, S.Consistent s → S.Consistent s' → s' = s ∨ s' = -s := by
    intro s s' hs hs'
    rw [consistent_iff_sense_eq_twist_mul] at hs hs'
    have key : ∀ b : P, s' b = (s' p0 * s p0) * s b := by
      intro b
      obtain ⟨γ⟩ := hc p0 b
      rw [S.sense_eq_twistProd_mul s hs γ, S.sense_eq_twistProd_mul s' hs' γ]
      rcases Int.units_eq_one_or (s p0) with h1 | h1 <;>
        rcases Int.units_eq_one_or (s' p0) with h2 | h2 <;> rw [h1, h2] <;> simp
    rcases Int.units_eq_one_or (s' p0 * s p0) with h | h
    · left; funext b; rw [key b, h, one_mul]
    · right; funext b; rw [key b, h, Pi.neg_apply, neg_mul, one_mul]
  have negc : ∀ s : P → ℤˣ, S.Consistent s → S.Consistent (-s) := by
    intro s hs e
    simp only [Pi.neg_apply, neg_mul, hs e]
  refine ⟨?_, ?_⟩
  · rintro ⟨s, hs⟩
    rw [Nat.card_eq_two_iff' (⟨s, hs⟩ : {s : P → ℤˣ // S.Consistent s})]
    refine ⟨⟨-s, negc s hs⟩, ?_, ?_⟩
    · intro heq
      have := congrFun (congrArg Subtype.val heq) p0
      change -(s p0) = s p0 at this
      rcases Int.units_eq_one_or (s p0) with h | h <;> rw [h] at this <;> exact absurd this (by decide)
    · rintro ⟨y, hy⟩ hne
      rcases dich s y hs hy with h | h
      · exact absurd (Subtype.ext h) hne
      · exact Subtype.ext h
  · intro h
    have : IsEmpty {s : P → ℤˣ // S.Consistent s} := ⟨fun ⟨s, hs⟩ => h ⟨s, hs⟩⟩
    exact Nat.card_of_isEmpty

/-- The card's paper strips: 10 square panels in a row, edge `i` joining panel `i` to panel
`i + 1`, edge 9 the taped seam back to panel 0. Panel `i`'s walk follows each join's arrow and
panel `i + 1`'s walk runs against it, so inside joins have twist `+1`. With `flip`, the seam is
taped with a half twist: both walks run against its arrow, and its twist is `-1`. -/
def strip (flip : Bool) : Panelling (Fin 10) (Fin 10) where
  T₁ i := i
  T₂ i := i + 1
  c₁ i := if flip && i = 9 then -1 else 1
  c₂ _ := -1

-- One lap of the Möbius strip: 9 joins of twist +1 and the seam of twist -1 multiply to -1.
example : ∏ i : Fin 10, (strip true).twist i = -1 := by
  decide

-- One lap of the plain band multiplies to +1.
example : ∏ i : Fin 10, (strip false).twist i = 1 := by
  decide

-- Two laps of the Möbius strip: (-1)^2 = +1, so the pen line closes after 60 cm.
example : (∏ i : Fin 10, (strip true).twist i) ^ 2 = 1 := by
  decide

-- The card's hand arithmetic: (+1)^9 × (-1) = -1 and (-1)^2 = +1.
example : (1 : ℤ) ^ 9 * (-1) = -1 ∧ (-1 : ℤ) ^ 2 = 1 := by
  norm_num

-- 10 panels give 2^10 = 1024 choices of sense to try.
example : Fintype.card (Fin 10 → ℤˣ) = 1024 := by
  rw [Fintype.card_fun, Fintype.card_units_int, Fintype.card_fin]; norm_num

-- Euler characteristics V − E + F from the card's table: band and Möbius strip 20 − 30 + 10,
-- torus and Klein bottle 9 − 18 + 9, projective plane 10 − 18 + 9, geodesic dome 42 − 120 + 80.
example : (20 : ℤ) - 30 + 10 = 0 ∧ (9 : ℤ) - 18 + 9 = 0 ∧ (10 : ℤ) - 18 + 9 = 1 ∧
    (42 : ℤ) - 120 + 80 = 2 := by
  norm_num

#print axioms consistent_iff_sense_eq_twist_mul
#print axioms orientable_iff_twist_prod_eq_one_of_closed_path
#print axioms card_consistent_eq_two_or_zero
#print axioms Panelling.twistProd_comp
#print axioms Panelling.crossingTwist_reverse
#print axioms Panelling.twistProd_reverse
#print axioms Panelling.sense_eq_twistProd_mul
