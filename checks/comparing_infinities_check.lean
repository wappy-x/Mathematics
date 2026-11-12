-- Comparing infinities: every set fits one-to-one inside its power set but no handout of subsets covers them all (the set of members left off their own subset is always missed), two one-to-one fittings in opposite directions give a pairing, a segment of the line pairs with a whole square, and the card's four-room hotel numbers come out as it says.
import Mathlib.Logic.Function.Basic
import Mathlib.SetTheory.Cardinal.SchroederBernstein
import Mathlib.Analysis.Real.Cardinality
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum

/-- Every collection is strictly smaller than its power set. It fits inside: some one-to-one
rule sends each member to its own subset (each member to the list naming just it). And no
handout covers the power set: however each member `a` is handed a subset `g a`, the list of
the members left off their own list, `{x | x ∉ g x}`, is never one that was handed out. -/
theorem every_set_is_smaller_than_its_power_set (α : Type*) :
    (∃ f : α → Set α, Function.Injective f) ∧
      ∀ g : α → Set α, ∀ a : α, g a ≠ {x | x ∉ g x} := by
  refine ⟨⟨fun a => {a}, Set.singleton_injective⟩, ?_⟩
  intro g a h
  have h1 : a ∈ g a ↔ a ∈ {x | x ∉ g x} := by rw [← h]
  simp only [Set.mem_setOf_eq] at h1
  by_cases ha : a ∈ g a
  · exact (h1.mp ha) ha
  · exact ha (h1.mpr ha)

/-- Cantor–Bernstein: fitting both ways means the same size. If `α` fits one-to-one inside `β`
and `β` fits one-to-one inside `α`, then there is a single rule pairing `α` with `β` one for
one. -/
theorem fits_both_ways_means_same_size {α β : Type*} (f : α → β) (g : β → α)
    (hf : Function.Injective f) (hg : Function.Injective g) :
    ∃ h : α → β, Function.Bijective h := by
  exact Function.Embedding.schroeder_bernstein hf hg

/-- A segment holds as many points as a whole square: the points of `[0, 1]` pair one for one
with the points of the square `[0, 1] × [0, 1]`. -/
theorem segment_and_square_have_equally_many_points :
    Nonempty (Set.Icc (0 : ℝ) 1 ≃ Set.Icc (0 : ℝ) 1 × Set.Icc (0 : ℝ) 1) := by
  have h1 : Cardinal.mk (Set.Icc (0 : ℝ) 1) = Cardinal.continuum := Cardinal.mk_Icc_real (by norm_num)
  have h2 : Cardinal.mk (Set.Icc (0 : ℝ) 1 × Set.Icc (0 : ℝ) 1) = Cardinal.mk (Set.Icc (0 : ℝ) 1) := by
    rw [Cardinal.mk_prod, h1, Cardinal.lift_id, Cardinal.continuum_mul_self]
  exact Cardinal.eq.mp h2.symm

-- The four-room hotel has 16 guest lists, and 16 ^ 4 = 65536 ways to hand one list to each room.
example : Fintype.card (Finset (Fin 4)) = 16 := by decide
example : Fintype.card (Fin 4 → Finset (Fin 4)) = 65536 := by
  simp [Fintype.card_finset]

-- The handout from Step 2: room 1 gets {1,2}, room 2 gets {1,3,4}, room 3 gets {}, room 4 gets {2,4}.
-- Walking the corridor builds the missed list {2,3}, and no room was handed {2,3}.
example :
    let a : ℕ → Finset ℕ := fun r =>
      if r = 1 then {1, 2} else if r = 2 then {1, 3, 4} else if r = 3 then ∅ else {2, 4}
    ({1, 2, 3, 4} : Finset ℕ).filter (fun r => r ∉ a r) = {2, 3} ∧
      ∀ r ∈ ({1, 2, 3, 4} : Finset ℕ), a r ≠ {2, 3} := by
  decide

-- The square to four digits: shuffling the digits of each of the 100 × 100 points into one
-- four-digit number and unshuffling gives the point back, so all 10000 shuffles are different.
example : ∀ a < 100, ∀ b < 100,
    let t := a / 10 * 1000 + b / 10 * 100 + a % 10 * 10 + b % 10
    (t / 1000 * 10 + t / 10 % 10, t / 100 % 10 * 10 + t % 10) = (a, b) := by
  decide +kernel

#print axioms every_set_is_smaller_than_its_power_set
#print axioms fits_both_ways_means_same_size
#print axioms segment_and_square_have_equally_many_points
