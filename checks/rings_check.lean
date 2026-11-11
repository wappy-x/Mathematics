-- Rings: on a clock dial of any size every nonzero reading is a unit or a zero divisor and never both, in every ring a unit is never a zero divisor, a reading is a unit exactly when it shares no factor with the dial size, and the card's 12-hour dial, whole-number and matrix numbers come out as it says.
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.ZMod.Units
import Mathlib.Data.Int.Interval
import Mathlib.LinearAlgebra.Matrix.Notation

/-- On a clock dial of any size `n` (the readings `0` to `n − 1`, wrapping at `n`), every nonzero
reading is either a unit (some reading multiplies it up to `1`) or a zero divisor (some nonzero
reading multiplies it to `0`), and never both. On the 12-hour dial the units are 1, 5, 7, 11 and
the zero divisors 2, 3, 4, 6, 8, 9, 10. -/
theorem dial_reading_unit_or_zero_divisor (n : ℕ) [NeZero n] (a : ZMod n) (ha : a ≠ 0) :
    Xor (IsUnit a) (∃ b : ZMod n, b ≠ 0 ∧ a * b = 0) := by
  classical
  by_cases hu : IsUnit a
  · left
    refine ⟨hu, ?_⟩
    rintro ⟨b, hb, hab⟩
    obtain ⟨u, rfl⟩ := hu
    apply hb
    calc b = (↑u⁻¹ : ZMod n) * ((u : ZMod n) * b) := by rw [← mul_assoc, Units.inv_mul, one_mul]
      _ = 0 := by rw [hab, mul_zero]
  · right
    refine ⟨?_, hu⟩
    have hni : ¬ Function.Injective (fun x : ZMod n => a * x) := by
      intro hinj
      have hsurj : Function.Surjective (fun x : ZMod n => a * x) := Finite.injective_iff_surjective.mp hinj
      obtain ⟨c, hc⟩ := hsurj 1
      exact hu (IsUnit.of_mul_eq_one c hc)
    rw [Function.Injective] at hni
    push_neg at hni
    obtain ⟨x, y, hxy, hne⟩ := hni
    exact ⟨x - y, sub_ne_zero.mpr hne, by rw [mul_sub, hxy]; exact sub_self _⟩

/-- In every ring, a unit is never a zero divisor: if `a` has a multiplicative undo and
`a * b = 0`, then `b = 0`. No commuting is assumed. -/
theorem unit_is_not_zero_divisor {R : Type*} [Ring R] (a b : R) (ha : IsUnit a)
    (h : a * b = 0) : b = 0 := by
  obtain ⟨u, rfl⟩ := ha
  calc b = (↑u⁻¹ : R) * ((u : R) * b) := by rw [← mul_assoc, Units.inv_mul, one_mul]
    _ = 0 := by rw [h, mul_zero]

/-- The greatest-common-divisor test: on a dial of size `n`, the reading `a` has a
multiplicative undo exactly when `a` and `n` share no factor above 1. -/
theorem dial_unit_iff_coprime (n : ℕ) (a : ℕ) :
    IsUnit (a : ZMod n) ↔ Nat.Coprime a n := by
  exact ZMod.isUnit_iff_coprime a n

-- Three jumps of four hours make one whole turn; five fives make two turns and an hour.
example : (3 : ZMod 12) * 4 = 0 := by decide
example : (5 : ZMod 12) * 5 = 1 := by decide
-- The units of the 12-hour dial: exactly 1, 5, 7 and 11, each its own undo.
example : (Finset.univ.filter fun a : ZMod 12 => ∃ b, a * b = 1) = {1, 5, 7, 11} := by decide
example : (1 : ZMod 12) * 1 = 1 ∧ (5 : ZMod 12) * 5 = 1 ∧ (7 : ZMod 12) * 7 = 1 ∧
    (11 : ZMod 12) * 11 = 1 := by decide
-- The nonzero zero divisors: 2, 3, 4, 6, 8, 9, 10, with partners 6, 4, 3, 2, 3, 4, 6.
example : (Finset.univ.filter fun a : ZMod 12 => a ≠ 0 ∧ ∃ b, b ≠ 0 ∧ a * b = 0) =
    {2, 3, 4, 6, 8, 9, 10} := by decide
example : (2 : ZMod 12) * 6 = 0 ∧ (3 : ZMod 12) * 4 = 0 ∧ (4 : ZMod 12) * 3 = 0 ∧
    (6 : ZMod 12) * 2 = 0 ∧ (8 : ZMod 12) * 3 = 0 ∧ (9 : ZMod 12) * 4 = 0 ∧
    (10 : ZMod 12) * 6 = 0 := by decide
-- How many readings each multiplier reaches: 1 12 6 4 3 12 2 12 3 4 6 12.
example : (List.finRange 12).map (fun a => (Finset.univ.image fun x : ZMod 12 => (a : ZMod 12) * x).card)
    = [1, 12, 6, 4, 3, 12, 2, 12, 3, 4, 6, 12] := by decide
-- Twice a reading is always even, so 2 has no undo; and 2x = 2 has two answers, 1 and 7.
example : ∀ x : ZMod 12, 2 * x ≠ 1 := by decide
example : (Finset.univ.filter fun x : ZMod 12 => 2 * x = 2) = {1, 7} := by decide
-- The distributive rule holds on all 1728 triples of readings.
example : ∀ a b c : ZMod 12, a * (b + c) = a * b + a * c := by decide
-- The whole numbers from −20 to 20: 2k = 1 has no answer, and the only units are −1 and 1.
example : ∀ k ∈ Finset.Icc (-20 : ℤ) 20, 2 * k ≠ 1 := by decide
example : ((Finset.Icc (-20 : ℤ) 20).filter fun k =>
      ((Finset.Icc (-20 : ℤ) 20).filter fun m => k * m = 1).Nonempty)
    = {-1, 1} := by decide
-- The 2 by 2 whole-number matrices: AB is not BA, and two nonzero matrices multiply to zero.
example : !![(1 : ℤ), 1; 0, 1] * !![1, 0; 1, 1] = !![2, 1; 1, 1] := by decide
example : !![(1 : ℤ), 0; 1, 1] * !![1, 1; 0, 1] = !![1, 1; 1, 2] := by decide
example : !![(1 : ℤ), 0; 0, 0] * !![0, 0; 0, 1] = 0 := by decide

#print axioms dial_reading_unit_or_zero_divisor
#print axioms unit_is_not_zero_divisor
#print axioms dial_unit_iff_coprime
