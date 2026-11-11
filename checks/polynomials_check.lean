-- Polynomials: multiplying two real polynomials adds their degrees, adding two never raises the degree above the bigger one, the two product patterns hold for all real numbers, and the football's height 20t - 5t^2 gives the card's numbers.
import Mathlib.Algebra.Polynomial.Degree.Operations
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.ComputeDegree
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Polynomial

/-- Degrees add: multiply two polynomials with ordinary (real) numbers as coefficients, and the
degree of the product is the degree of one plus the degree of the other, because the two top
coefficients are not zero and so never multiply to zero. Mathlib's `degree` is the biggest power
whose coefficient is not zero; the zero polynomial gets the degree `⊥` (below every number), so
the rule needs no exception. -/
theorem degree_of_product_is_sum_of_degrees (p q : ℝ[X]) :
    (p * q).degree = p.degree + q.degree := by
  exact Polynomial.degree_mul

/-- Adding never pushes the degree above the bigger of the two degrees. It can pull it down,
when the top terms cancel, as the gap between the two balls shows. -/
theorem degree_of_sum_at_most_bigger_degree (p q : ℝ[X]) :
    (p + q).degree ≤ max p.degree q.degree := by
  exact Polynomial.degree_add_le p q

/-- The two product patterns, for every two numbers `a` and `b`: squaring a two-term bracket
gives the two squares and twice the product between them, `(a + b)^2 = a^2 + 2ab + b^2`; and a
difference times a sum leaves the two squares, `(a - b)(a + b) = a^2 - b^2`. -/
theorem square_of_sum_and_difference_of_squares (a b : ℝ) :
    (a + b) ^ 2 = a ^ 2 + 2 * a * b + b ^ 2 ∧ (a - b) * (a + b) = a ^ 2 - b ^ 2 := by
  constructor <;> ring

-- The football's height after t seconds, 20t - 5t^2 metres: 15, 20, 15, 0 at 1, 2, 3, 4 seconds.
example : (20 * X - 5 * X ^ 2 : ℝ[X]).eval 1 = 15 := by norm_num
example : (20 * X - 5 * X ^ 2 : ℝ[X]).eval 2 = 20 := by norm_num
example : (20 * X - 5 * X ^ 2 : ℝ[X]).eval 3 = 15 := by norm_num
example : (20 * X - 5 * X ^ 2 : ℝ[X]).eval 4 = 0 := by norm_num
-- The two pieces racing: 20t is 20, 40, 60, 80 and 5t^2 is 5, 20, 45, 80.
example : (20 * 1, 20 * 2, 20 * 3, 20 * 4) = (20, 40, 60, 80) := by decide
example : (5 * 1 ^ 2, 5 * 2 ^ 2, 5 * 3 ^ 2, 5 * 4 ^ 2) = (5, 20, 45, 80) := by decide
-- The degree of the height rule is 2; its coefficients are -5 for t^2, 20 for t, 0 plain.
example : (20 * X - 5 * X ^ 2 : ℝ[X]).natDegree = 2 := by compute_degree!
example : (20 * X - 5 * X ^ 2 : ℝ[X]).coeff 2 = -5 ∧ (20 * X - 5 * X ^ 2 : ℝ[X]).coeff 1 = 20 ∧
    (20 * X - 5 * X ^ 2 : ℝ[X]).coeff 0 = 0 := by
  simp [coeff_X, coeff_X_pow]
-- The roots: t = 0 and t = 4 give height zero, and no other time does.
example : (20 * X - 5 * X ^ 2 : ℝ[X]).eval 0 = 0 := by norm_num
example (t : ℝ) : 20 * t - 5 * t ^ 2 = 0 ↔ t = 0 ∨ t = 4 := by
  constructor
  · intro h
    have h' : 5 * t * (4 - t) = 0 := by linear_combination h
    rcases mul_eq_zero.mp h' with h1 | h1
    · left; linarith
    · right; linarith
  · rintro (rfl | rfl) <;> norm_num
-- The far end at 10 seconds: 200 - 500 = -300.
example : (20 * X - 5 * X ^ 2 : ℝ[X]).eval 10 = -300 := by norm_num
-- Every term against every term: 5t times (4 - t) is the ball's height again, degree 1 + 1 = 2.
example : (5 * X * (4 - X) : ℝ[X]) = 20 * X - 5 * X ^ 2 := by ring
example : (5 * X : ℝ[X]).natDegree = 1 ∧ (4 - X : ℝ[X]).natDegree = 1 := by
  constructor <;> compute_degree!
-- The second ball, 3 + 12t - 5t^2, is degree 2; the gap to the first is 3 - 8t, degree 1.
example : (3 + 12 * X - 5 * X ^ 2 : ℝ[X]).natDegree = 2 := by compute_degree!
example : ((3 + 12 * X - 5 * X ^ 2) - (20 * X - 5 * X ^ 2) : ℝ[X]) = 3 - 8 * X := by ring
example : (3 - 8 * X : ℝ[X]).natDegree = 1 := by compute_degree!
-- Symmetry about the top: h(2 + s) = 20 - 5s^2, so s = 0, 1, 2 give 20, 15, 0.
example (s : ℝ) : 20 * (2 + s) - 5 * (2 + s) ^ 2 = 20 - 5 * s ^ 2 := by ring
example : ((20 : ℤ) - 5 * 0 ^ 2, (20 : ℤ) - 5 * 1 ^ 2, (20 : ℤ) - 5 * 2 ^ 2) = (20, 15, 0) := by
  decide
-- The three mistakes at 3 seconds: -165, 11 and 35, instead of 15.
example : (20 : ℤ) * 3 - (5 * 3) ^ 2 = -165 := by decide
example : (20 : ℤ) - 3 * 3 = 11 := by decide
example : (20 : ℤ) * (2 + 1) - 5 * (4 + 1 * 1) = 35 := by decide
example : (20 : ℤ) * 3 - 5 * 3 ^ 2 = 15 := by decide

#print axioms degree_of_product_is_sum_of_degrees
#print axioms degree_of_sum_at_most_bigger_degree
#print axioms square_of_sum_and_difference_of_squares
