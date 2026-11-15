-- Knots and links: every Gauss-code knot diagram with at most two crossings and even gaps is descending, the trefoil's diagram is not, and 6 of the 8 over-under markings of the trefoil's shadow are descending.
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fin.VecNotation
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Tactic.NormNum

/-! Mathlib has no knot theory, so the card's combinatorial objects are defined here.
A knot diagram with `n` crossings is read on one walk as a Gauss code: passage `k` of the
`2n` passages gives the crossing's name and `true` for over (O), `false` for under (U).
The topology (a descending diagram is the unknot; real diagrams have even gaps) is proved
on the card in words; this file checks the finite, exhaustive part of Step 4 and the
trefoil's numbers. -/

/-- A diagram with `n` crossings as a Gauss code: `2n` passages, each a crossing and O or U. -/
abbrev GaussDiagram (n : ℕ) := Fin (2 * n) → Fin n × Bool

namespace GaussDiagram

variable {n : ℕ}

/-- Each crossing is passed exactly twice: once over and once under. -/
def IsValid (d : GaussDiagram n) : Prop :=
  ∀ c : Fin n, ∀ b : Bool, (Finset.univ.filter fun k => d k = (c, b)).card = 1

/-- Even gaps: between the two visits to one crossing lie an even number of letters. -/
def HasEvenGaps (d : GaussDiagram n) : Prop :=
  ∀ i j : Fin (2 * n), i < j → (d i).1 = (d j).1 → Even (j.val - i.val - 1)

/-- The passage reached at step `j` of a walk from passage `start`, forwards or backwards. -/
def walkPos (start : Fin (2 * n)) (back : Bool) (j : Fin (2 * n)) : Fin (2 * n) :=
  if back then start - j else start + j

/-- Descending: from some start, in some direction, every crossing is first met on the over
strand. The empty diagram (no crossings) counts as descending. -/
def IsDescending (d : GaussDiagram n) : Prop :=
  n = 0 ∨ ∃ start : Fin (2 * n), ∃ back : Bool, ∀ j : Fin (2 * n),
    (∀ i : Fin (2 * n), i < j → (d (walkPos start back i)).1 ≠ (d (walkPos start back j)).1) →
      (d (walkPos start back j)).2 = true

/-- Alternating: over and under alternate all the way round the walk. -/
def IsAlternating (d : GaussDiagram n) : Prop :=
  ∀ k : Fin (2 * n), (d k).2 ≠ (d (finRotate (2 * n) k)).2

instance (d : GaussDiagram n) : Decidable d.IsValid := by unfold IsValid; infer_instance
instance (d : GaussDiagram n) : Decidable d.HasEvenGaps := by unfold HasEvenGaps; infer_instance
instance (d : GaussDiagram n) : Decidable d.IsDescending := by unfold IsDescending; infer_instance
instance (d : GaussDiagram n) : Decidable d.IsAlternating := by unfold IsAlternating; infer_instance

/-- Mark a shadow (the crossing names along the walk) with over and under:
`pick c = true` says the first visit to crossing `c` is over. -/
def ofShadow (w : Fin (2 * n) → Fin n) (pick : Fin n → Bool) : GaussDiagram n :=
  fun k => (w k, pick (w k) == decide (∀ i : Fin (2 * n), i < k → w i ≠ w k))

/-- Change one crossing: swap over and under at both visits to crossing `x`. -/
def flip (d : GaussDiagram n) (x : Fin n) : GaussDiagram n :=
  fun k => ((d k).1, if (d k).1 = x then !(d k).2 else (d k).2)

end GaussDiagram

open GaussDiagram

/-- The trefoil's shadow, read from the start dot: crossings 1 2 3 1 2 3 (named 0, 1, 2). -/
def trefoilShadow : Fin (2 * 3) → Fin 3 := ![0, 1, 2, 0, 1, 2]

/-- The trefoil as drawn on the card: O1 U2 O3 U1 O2 U3 (crossings named 0, 1, 2). -/
def trefoil : GaussDiagram 3 :=
  ![(0, true), (1, false), (2, true), (0, false), (1, true), (2, false)]

/-- Step 4, the exhaustive check: every Gauss-code diagram with at most 2 crossings, each
crossing passed once over and once under, with even gaps, is descending (so, by Step 3,
the unknot). -/
theorem diagram_with_at_most_two_crossings_is_descending (n : ℕ) (hn : n ≤ 2)
    (d : GaussDiagram n) (hd : d.IsValid) (he : d.HasEvenGaps) : d.IsDescending := by
  revert d
  rcases (by omega : n = 0 ∨ n = 1 ∨ n = 2) with rfl | rfl | rfl
  · intro d _ _; exact Or.inl rfl
  · set_option maxRecDepth 100000 in decide
  · set_option maxRecDepth 100000 in decide

/-- The trefoil as drawn is not descending: from every start, in either direction, some
crossing is met under first. -/
theorem trefoil_not_descending : ¬ trefoil.IsDescending := by
  decide

/-- Of the 8 ways to mark over and under on the trefoil's shadow, exactly 6 are descending. -/
theorem trefoil_shadow_six_of_eight_markings_descending :
    (Finset.univ.filter fun pick : Fin 3 → Bool =>
      (ofShadow trefoilShadow pick).IsDescending).card = 6 := by
  decide

-- The trefoil's diagram is a valid Gauss code, alternates, and has even gaps (2, 2, 2).
example : trefoil.IsValid ∧ trefoil.IsAlternating ∧ trefoil.HasEvenGaps := by decide

-- The card's trefoil is the shadow marked over first at crossings 1 and 3, under first at 2.
example : ofShadow trefoilShadow ![true, false, true] = trefoil := by decide

-- All markings of the trefoil's shadow: 2 × 2 × 2 = 8.
example : Fintype.card (Fin 3 → Bool) = 8 := by decide

-- Changing any one of the 3 crossings makes the trefoil's diagram descending.
example : ∀ x : Fin 3, (trefoil.flip x).IsDescending := by decide

-- Census, n = 1: 1 code, 1 with even gaps, 2 diagrams.
example : (Finset.univ.filter fun d : GaussDiagram 1 => d.IsValid ∧ d.HasEvenGaps).card = 2 := by
  decide

-- Census, n = 2: 6 codes, 4 with even gaps, 16 diagrams.
example : (Finset.univ.filter fun w : Fin (2 * 2) → Fin 2 =>
    ∀ c, (Finset.univ.filter fun k => w k = c).card = 2).card = 6 := by decide
example : (Finset.univ.filter fun d : GaussDiagram 2 => d.IsValid ∧ d.HasEvenGaps).card = 16 := by
  decide

-- Census, n = 3: 36 codes with even gaps, each with 2 ^ 3 markings, give 288 diagrams.
example : 36 * 2 ^ 3 = 288 := by norm_num

#print axioms diagram_with_at_most_two_crossings_is_descending
#print axioms trefoil_not_descending
#print axioms trefoil_shadow_six_of_eight_markings_descending
