-- Finite word length: rounding to a step q misses by at most q/2, a uniform rounding error has mean 0 and variance q^2/12, and a polynomial's slope at a root is the product of that root's distances to the other roots.
import Mathlib.Algebra.Order.Round
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Data.Rat.Floor
import Mathlib.Tactic.NormNum

/-! A fixed-point number is an integer times a step `q > 0`. Rounding `x` to the nearest
step gives `q * round (x / q)`; Mathlib's `round` rounds halves up, `round y = ⌊y + 1/2⌋`,
exactly as the card's code `floor(v / q + 0.5) * q` does.
A filter's denominator is `A(z) = (z - p 1) ⋯ (z - p N)` with poles `p i`. -/

open Polynomial Finset

/-- A rounding error is at most half a step: rounding any real number `x` to the nearest
multiple of the step `q > 0` changes it by at most `q / 2`. -/
theorem rounding_error_le_half_step (q : ℝ) (hq : 0 < q) (x : ℝ) :
    |x - q * round (x / q)| ≤ q / 2 := by
  have h := abs_sub_round (x / q)
  have e : x - q * round (x / q) = q * (x / q - round (x / q)) := by
    field_simp
  rw [e, abs_mul, abs_of_pos hq]
  calc q * |x / q - round (x / q)| ≤ q * (1 / 2) := by gcongr
    _ = q / 2 := by ring

/-- One rounding error, modelled as uniform on `[-q/2, q/2]`, has mean `0` and
variance `q^2 / 12`: the average of `e` over the interval is `0` and the average
of `e^2` is `q^2 / 12`. -/
theorem uniform_rounding_error_mean_zero_variance (q : ℝ) (hq : 0 < q) :
    (1 / q) * ∫ e in (-q / 2)..(q / 2), e = 0 ∧
    (1 / q) * ∫ e in (-q / 2)..(q / 2), e ^ 2 = q ^ 2 / 12 := by
  rw [integral_id, integral_pow]
  constructor
  · ring
  · field_simp
    ring

/-- The slope of the denominator at a pole is the product of that pole's distances to all
the other poles: if `A(z) = ∏ m, (z - p m)` then `A'(p i) = ∏ (m ≠ i), (p i - p m)`.
This is the divisor in the card's pole-sensitivity formula. -/
theorem slope_at_pole_eq_prod_distances {N : ℕ} (p : Fin N → ℂ) (i : Fin N) :
    (derivative (∏ m, (X - C (p m)))).eval (p i) = ∏ m ∈ univ.erase i, (p i - p m) := by
  classical
  rw [derivative_prod_finset, eval_finsetSum]
  rw [Finset.sum_eq_single i]
  · simp [eval_prod]
  · intro b _ hb
    rw [eval_mul, eval_prod]
    apply mul_eq_zero_of_left
    apply Finset.prod_eq_zero (i := i)
    · exact Finset.mem_erase.mpr ⟨fun h => hb h.symm, Finset.mem_univ _⟩
    · simp
  · intro h; exact absurd (Finset.mem_univ i) h

/-! Worked numbers from the card, exact. -/

-- Rounding the direct form's coefficients to 10 fraction bits (step 2^-10): in units of
-- 2^-10 they become 1024, -4288, 7239, -6154, 2632, -453 (1.000000, -4.187500, 7.069336,
-- -6.009766, 2.570312, -0.442383), from the card's 1, -4.187300, 7.069723, -6.009958,
-- 2.570429, -0.442209.
example : round ((-4187300 : ℚ) / 1000000 * 1024) = -4288 := by norm_num [round_eq]
example : round ((7069723 : ℚ) / 1000000 * 1024) = 7239 := by norm_num [round_eq]
example : round ((-6009958 : ℚ) / 1000000 * 1024) = -6154 := by norm_num [round_eq]
example : round ((2570429 : ℚ) / 1000000 * 1024) = 2632 := by norm_num [round_eq]
example : round ((-442209 : ℚ) / 1000000 * 1024) = -453 := by norm_num [round_eq]

-- Their sum A(1) is exactly 0, so z = 1 is a pole: the filter no longer settles.
example : (1024 : ℤ) - 4288 + 7239 - 6154 + 2632 - 453 = 0 := by norm_num

-- The worst shift of A(1) from rounding five coefficients at F = 10 is 5 × 2^-11 = 5/2048,
-- more than the true A(1) = 0.000685.
example : (5 : ℚ) * ((1 / 2) * (1 / 2 ^ 10)) = 5 / 2048 ∧ (685 : ℚ) / 1000000 < 5 / 2048 := by
  norm_num

-- A 16-bit word holding a coefficient as large as 7.07 (between 2^2 and 2^3) spends a sign
-- bit and three whole-number bits, leaving 12 fraction bits.
example : (2 : ℕ) ^ 2 ≤ 7 ∧ 7 < 2 ^ 3 ∧ 1 + 3 + 12 = 16 := by norm_num

-- Direct form II's inner gain at 0 Hz, 1460.5, needs 11 extra bits: 2^10 < 1460.5 ≤ 2^11.
example : (2 : ℚ) ^ 10 < 2921 / 2 ∧ (2921 : ℚ) / 2 ≤ 2 ^ 11 := by norm_num

#print axioms rounding_error_le_half_step
#print axioms uniform_rounding_error_mean_zero_variance
#print axioms slope_at_pole_eq_prod_distances
