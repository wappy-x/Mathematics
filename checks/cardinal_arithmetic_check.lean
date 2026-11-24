-- Cardinal arithmetic: an infinite size added to or multiplied by itself stays the same, sums and products go to the bigger size, and two to the aleph-null is strictly bigger and equals the size of the line.
import Mathlib.SetTheory.Cardinal.Arithmetic
import Mathlib.SetTheory.Cardinal.Continuum
import Mathlib.Analysis.Real.Cardinality

open Cardinal

/-- An infinite size added to itself or multiplied by itself stays the same size:
for every infinite cardinal `κ`, `κ + κ = κ` and `κ × κ = κ`. -/
theorem infinite_add_self_and_mul_self {κ : Cardinal} (hκ : ℵ₀ ≤ κ) :
    κ + κ = κ ∧ κ * κ = κ := by
  exact ⟨add_eq_self hκ, mul_eq_self hκ⟩

/-- The quick rule: if `κ` is infinite and `λ` is no bigger, then `κ + λ = κ`;
if also `λ` is not zero, then `κ × λ = κ`. Sums and products go to the bigger size. -/
theorem sum_and_product_go_to_bigger {κ μ : Cardinal} (hκ : ℵ₀ ≤ κ) (hμ : μ ≤ κ) :
    κ + μ = κ ∧ (μ ≠ 0 → κ * μ = κ) := by
  exact ⟨add_eq_left hκ hμ, fun h => mul_eq_left hκ hμ h⟩

/-- The card's formula: aleph-null plus aleph-null is aleph-null, aleph-null times
aleph-null is aleph-null, but two to the aleph-null is strictly bigger and is the
size of the real line. -/
theorem aleph0_add_mul_and_two_pow_is_the_line :
    ℵ₀ + ℵ₀ = ℵ₀ ∧ ℵ₀ * ℵ₀ = ℵ₀ ∧ ℵ₀ < (2 : Cardinal) ^ ℵ₀ ∧ (2 : Cardinal) ^ ℵ₀ = #ℝ := by
  exact ⟨aleph0_add_aleph0, aleph0_mul_aleph0, cantor ℵ₀, by rw [two_power_aleph0, mk_real]⟩

-- Merging hotels: own guest in room 7 moves to 14, the newcomer from room 7 takes 13.
example : 2 * 7 = 14 ∧ 2 * 7 - 1 = 13 := by decide
-- The coach rule, room 2^m (2n + 1): (0,0) → 1, (2,1) → 12, (3,4) → 72.
example : 2 ^ 0 * (2 * 0 + 1) = 1 ∧ 2 ^ 2 * (2 * 1 + 1) = 12 ∧ 2 ^ 3 * (2 * 4 + 1) = 72 := by
  decide
-- Room 12 back: halve 2 times to the odd part 3, then (3 - 1) / 2 = 1: coach 2, seat 1.
example : 12 / 2 = 6 ∧ 6 / 2 = 3 ∧ 3 % 2 = 1 ∧ (3 - 1) / 2 = 1 := by decide
-- The coach rule sends the 100 guests of coaches 0-9, seats 0-9 to 100 different rooms.
set_option maxRecDepth 100000 in
example : ((Finset.range 10 ×ˢ Finset.range 10).image
    (fun p : ℕ × ℕ => 2 ^ p.1 * (2 * p.2 + 1))).card = 100 := by decide
-- Shells by the larger number: pair (2,1) sits at place 8.
example : (fun m n : ℕ => max m n * max m n + (if m < max m n then m else max m n + n) + 1) 2 1 = 8 := by
  decide
-- Mistakes: room m + n + 1 puts 100 guests in 19 rooms; room 2^m (n + 1) in 55.
set_option maxRecDepth 100000 in
example : ((Finset.range 10 ×ˢ Finset.range 10).image (fun p : ℕ × ℕ => p.1 + p.2 + 1)).card = 19 := by
  decide
set_option maxRecDepth 100000 in
example : ((Finset.range 10 ×ˢ Finset.range 10).image
    (fun p : ℕ × ℕ => 2 ^ p.1 * (p.2 + 1))).card = 55 := by decide
-- Emptying the even rooms leaves 50 of rooms 1-100 full.
set_option maxRecDepth 100000 in
example : ((Finset.Icc 1 100).filter (fun r => r % 2 = 1)).card = 50 := by decide
-- Finite sizes do not collapse: 3 + 4 = 7, 3 × 4 = 12, and 8 lists of 0s and 1s of length 3.
example : 3 + 4 = 7 ∧ 3 * 4 = 12 ∧ Fintype.card (Fin 3 → Bool) = 8 := by decide

#print axioms infinite_add_self_and_mul_self
#print axioms sum_and_product_go_to_bigger
#print axioms aleph0_add_mul_and_two_pow_is_the_line
