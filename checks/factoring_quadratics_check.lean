-- Factoring: when two whole numbers p and q add to b and multiply to c, x^2 + bx + c equals (x + p)(x + q) and is zero only at x = -p or x = -q, because a product of real numbers is zero exactly when one factor is, and a square minus a square splits as (x + k)(x - k) while a square plus a nonzero square does not.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Ring.Int.Defs
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- The two-number hunt. If two whole numbers p and q add to the middle number b and multiply
to the last number c, then the bare quadratic x^2 + bx + c is the product (x + p)(x + q) for
every x, and it is zero exactly where a bracket is: at x = -p or x = -q, and nowhere else. -/
theorem quadratic_factors_and_is_zero_only_at_brackets (b c p q : ℤ)
    (hsum : p + q = b) (hprod : p * q = c) :
    (∀ x : ℝ, x ^ 2 + (b : ℝ) * x + (c : ℝ) = (x + (p : ℝ)) * (x + (q : ℝ))) ∧
    (∀ x : ℝ, x ^ 2 + (b : ℝ) * x + (c : ℝ) = 0 ↔ x = -(p : ℝ) ∨ x = -(q : ℝ)) := by
  subst hsum hprod
  have h : ∀ x : ℝ, x ^ 2 + ((p + q : ℤ) : ℝ) * x + ((p * q : ℤ) : ℝ) = (x + (p : ℝ)) * (x + (q : ℝ)) := by
    intro x
    push_cast
    ring
  refine ⟨h, fun x => ?_⟩
  rw [h x, mul_eq_zero]
  constructor
  · rintro (h1 | h1)
    · left; linarith
    · right; linarith
  · rintro (h1 | h1)
    · left; linarith
    · right; linarith

/-- A product is zero only when one factor is: if two numbers multiply to zero, at least one of
them is zero, and a zero factor always makes the product zero. -/
theorem product_is_zero_iff_a_factor_is (A B : ℝ) : A * B = 0 ↔ A = 0 ∨ B = 0 := by
  constructor
  · intro h
    rcases eq_or_ne A 0 with hA | hA
    · exact Or.inl hA
    · exact Or.inr ((mul_eq_zero.mp h).resolve_left hA)
  · rintro (h | h)
    · rw [h, zero_mul]
    · rw [h, mul_zero]

/-- A square minus a square collapses: x^2 - k^2 = (x + k)(x - k) for every x and k. A square
plus a square does not split this way: when k is not zero, no two real numbers add to 0 and
multiply to +k^2, so the hunt for x^2 + k^2 finds nothing. -/
theorem square_minus_square_splits_square_plus_square_does_not (k : ℝ) :
    (∀ x : ℝ, x ^ 2 - k ^ 2 = (x + k) * (x - k)) ∧
    (k ≠ 0 → ¬ ∃ p q : ℝ, p + q = 0 ∧ p * q = k ^ 2) := by
  refine ⟨fun x => by ring, fun hk => ?_⟩
  rintro ⟨p, q, hsum, hprod⟩
  have hq : q = -p := by linarith
  subst hq
  have hk2 : 0 < k ^ 2 := by positivity
  nlinarith [sq_nonneg p]

-- The football, 20t - 5t^2 = 5t(4 - t): zero at the kick and at landing, 20 m at its highest.
example : 20 * 0 - 5 * 0 ^ 2 = (0 : ℤ) ∧ 20 * 4 - 5 * 4 ^ 2 = (0 : ℤ) ∧
    20 * 2 - 5 * 2 ^ 2 = (20 : ℤ) := by decide
example : ∀ t ∈ Finset.Icc (-10 : ℤ) 10, 20 * t - 5 * t ^ 2 = 5 * t * (4 - t) := by decide
-- The whole-number pairs d, 30 / d with d * d at most 30 are 1 and 30, 2 and 15, 3 and 10, 5 and 6.
example : (Finset.Icc (1 : ℤ) 30).filter (fun d => 30 % d = 0 ∧ d * d ≤ 30) = {1, 2, 3, 5} := by
  decide
-- The pair adding to -11 and multiplying to 30 is -5 and -6.
example : (-5 : ℤ) + -6 = -11 ∧ (-5 : ℤ) * -6 = 30 := by decide
-- The patio, x^2 - 11x + 30 = (x - 5)(x - 6), agrees at all 20 whole x from -4 to 15.
example : ∀ x ∈ Finset.Icc (-4 : ℤ) 15, x ^ 2 - 11 * x + 30 = (x - 5) * (x - 6) := by decide
-- The patio vanishes at x = 5 and x = 6, and leaves 30 square metres at x = 11 (6 m by 5 m).
example : (5 : ℤ) ^ 2 - 11 * 5 + 30 = 0 ∧ (6 : ℤ) ^ 2 - 11 * 6 + 30 = 0 ∧
    (11 : ℤ) ^ 2 - 11 * 11 + 30 = 30 ∧ (11 - 5 : ℤ) * (11 - 6) = 30 := by decide
-- The pond patio at x = 11, k = 3: 121 - 9 = 112 and 14 * 8 = 112.
example : (11 : ℤ) ^ 2 - 3 ^ 2 = 112 ∧ (11 + 3 : ℤ) * (11 - 3) = 112 := by decide
-- x^2 + 9: no whole-number pair adds to 0 and multiplies to 9.
example : ∀ p ∈ Finset.Icc (-9 : ℤ) 9, ∀ q ∈ Finset.Icc (-9 : ℤ) 9, ¬ (p + q = 0 ∧ p * q = 9) := by
  decide
-- The four mistakes: 870 not 30, 8 not 30, 112 not 130, 10 not 20.
example : (35 : ℤ) ^ 2 - 11 * 35 + 30 = 870 ∧ (11 - 3 : ℤ) * (11 - 10) = 8 ∧
    (11 + 3 : ℤ) * (11 - 3) = 112 ∧ (11 : ℤ) ^ 2 + 9 = 130 ∧ (5 : ℤ) * (4 - 2) = 10 := by decide
-- The true solutions of (x - 5)(x - 6) = 30 are x = 0 and x = 11.
example : (0 - 5 : ℤ) * (0 - 6) = 30 ∧ (11 - 5 : ℤ) * (11 - 6) = 30 := by decide

#print axioms quadratic_factors_and_is_zero_only_at_brackets
#print axioms product_is_zero_iff_a_factor_is
#print axioms square_minus_square_splits_square_plus_square_does_not
