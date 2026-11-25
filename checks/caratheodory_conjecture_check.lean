-- Caratheodory's conjecture: if the indices of finitely many round points add up to 2 and each index is below 2, there are at least two round points.
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Data.Rat.Floor
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.IntervalCases

/-! The geometry (Poincare-Hopf for line fields on a sphere-shaped surface) is not in Mathlib.
It enters here as a hypothesis: the round points form a finite set `U` (they are isolated on a
closed surface) and their indices `ind p` add up to 2, the Euler characteristic of the sphere.
What is proved is the card's Step 4: how an index bound turns that sum into a count. -/

open Finset

/-- An index bound proves the conjecture: if the round points of a closed sphere-shaped surface
are isolated (finitely many) with indices adding up to 2, and every index is at most some bound
`m` below 2, then the surface has at least two round points. -/
theorem two_umbilics_of_index_bound_below_two {ι : Type*} (U : Finset ι) (ind : ι → ℚ)
    (hsum : ∑ p ∈ U, ind p = 2) (m : ℚ) (hm : m < 2) (hbound : ∀ p ∈ U, ind p ≤ m) :
    2 ≤ U.card := by
  have h := Finset.sum_le_card_nsmul U ind m hbound
  rw [hsum, nsmul_eq_mul] at h
  by_contra hc
  have hc' : U.card ≤ 1 := by omega
  interval_cases hcard : U.card
  · norm_num at h
  · norm_num at h
    linarith

/-- The card's formula: if the indices add up to 2 and no index exceeds a positive bound `m`,
the number of round points `N` is at least `2 / m`. -/
theorem umbilic_count_ge_two_div_bound {ι : Type*} (U : Finset ι) (ind : ι → ℚ)
    (hsum : ∑ p ∈ U, ind p = 2) (m : ℚ) (hm : 0 < m) (hbound : ∀ p ∈ U, ind p ≤ m) :
    2 / m ≤ (U.card : ℚ) := by
  have h := Finset.sum_le_card_nsmul U ind m hbound
  rw [hsum, nsmul_eq_mul] at h
  rw [div_le_iff₀ hm]
  exact h

/-- A counterexample needs one round point of index exactly 2: if the indices add up to 2 and
there are fewer than two round points, there is exactly one, and its index is 2. -/
theorem single_umbilic_has_index_two {ι : Type*} (U : Finset ι) (ind : ι → ℚ)
    (hsum : ∑ p ∈ U, ind p = 2) (hfew : U.card < 2) :
    ∃ p, U = {p} ∧ ind p = 2 := by
  interval_cases hcard : U.card
  · rw [Finset.card_eq_zero.mp hcard] at hsum
    simp at hsum
  · obtain ⟨a, rfl⟩ := Finset.card_eq_one.mp hcard
    refine ⟨a, rfl, ?_⟩
    simpa using hsum

-- The pebble: 4 round points of index 1/2 each, sum 2.
example : ∑ _p : Fin 4, (1 / 2 : ℚ) = 2 := by norm_num
-- The egg: 2 tips of index 1 each, sum 2.
example : ∑ _p : Fin 2, (1 : ℚ) = 2 := by norm_num
-- 5 lemons (index 1/2) and 1 star (index -1/2): 6 points, sum still 2.
example : 5 * (1 / 2 : ℚ) + (-1 / 2) = 2 ∧ 5 + 1 = 6 := by norm_num
-- Fewest round points, ceil(2 / m), for m = 1 (Loewner), m = 3/2 (index below 2), m = 2.
example : ⌈(2 : ℚ) / 1⌉ = 2 := by norm_num
example : ⌈(2 : ℚ) / (3 / 2)⌉ = 2 := by norm_num [Int.ceil_eq_iff]
example : ⌈(2 : ℚ) / 2⌉ = 1 := by norm_num
-- The pebble's closed form with a, b, c = 3, 2, 1: x^2 = 9 * 5/8, z^2 = 3/8, both curvatures a c / b^3 = 3/8.
example : (3 : ℚ) ^ 2 * ((3 ^ 2 - 2 ^ 2) / (3 ^ 2 - 1 ^ 2)) = 45 / 8 := by norm_num
example : (1 : ℚ) ^ 2 * ((2 ^ 2 - 1 ^ 2) / (3 ^ 2 - 1 ^ 2)) = 3 / 8 := by norm_num
example : (3 : ℚ) * 1 / 2 ^ 3 = 3 / 8 := by norm_num

#print axioms two_umbilics_of_index_bound_below_two
#print axioms umbilic_count_ge_two_div_bound
#print axioms single_umbilic_has_index_two
