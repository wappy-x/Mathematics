-- Product and quotient rules: the derivative of a product of two differentiable real functions is f' g + f g', of a ratio is (f' g - f g') / g^2 where the bottom is not zero, and of x^n is n x^(n-1) for every nonzero whole number n.
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.ZPow
import Mathlib.Tactic.NormNum

/-- Product rule: if two real functions `f` and `g` both have a derivative at the point `x`,
with rates `f'` and `g'`, then their product has a derivative there, equal to the first's rate
times the second plus the first times the second's rate: `(f g)' = f' g + f g'`. -/
theorem product_rule (f g : ℝ → ℝ) (f' g' x : ℝ)
    (hf : HasDerivAt f f' x) (hg : HasDerivAt g g' x) :
    HasDerivAt (fun y => f y * g y) (f' * g x + f x * g') x := by
  exact hf.mul hg

/-- Quotient rule: if `f` and `g` both have a derivative at `x` and the bottom `g x` is not zero,
then `f / g` has a derivative there, equal to the top's rate times the bottom, minus the top
times the bottom's rate, all over the bottom squared: `(f / g)' = (f' g - f g') / g^2`. -/
theorem quotient_rule (f g : ℝ → ℝ) (f' g' x : ℝ)
    (hf : HasDerivAt f f' x) (hg : HasDerivAt g g' x) (hx : g x ≠ 0) :
    HasDerivAt (fun y => f y / g y) ((f' * g x - f x * g') / g x ^ 2) x := by
  exact hf.div hg hx

/-- Power rule: for every whole number `n ≠ 0`, possibly negative, the derivative of `x ^ n`
is `n * x ^ (n - 1)`, with `x ≠ 0` required when `n` is negative. -/
theorem power_rule_int (n : ℤ) (x : ℝ) (hn : n ≠ 0) (hx : n < 0 → x ≠ 0) :
    HasDerivAt (fun y : ℝ => y ^ n) ((n : ℝ) * x ^ (n - 1)) x := by
  apply hasDerivAt_zpow n x
  by_cases h : n < 0
  · exact Or.inl (hx h)
  · exact Or.inr (by omega)

-- Week 4: price 14, bags 184, revenue 14 × 184 = 2576.
example : (12 + (1 / 2 : ℚ) * 4) = 14 ∧ (200 - 4 * 4 : ℚ) = 184 ∧ (14 * 184 : ℚ) = 2576 := by norm_num
-- Product rule in week 4: 0.5 × 184 + 14 × (−4) = 92 − 56 = 36.
example : (1 / 2 : ℚ) * 184 + 14 * (-4) = 36 := by norm_num
-- The 4-week step: 2 × 184 + 14 × (−16) + 2 × (−16) = 112 = 16 × 168 − 2576.
example : (2 * 184 + 14 * (-16) + 2 * (-16) : ℚ) = 112 ∧ (16 * 168 - 2576 : ℚ) = 112 := by norm_num
-- Quotient rule recovers the price rate: (36 × 184 − 2576 × (−4)) / 184^2 = 16928 / 33856 = 0.5.
example : ((36 * 184 - 2576 * (-4)) / 184 ^ 2 : ℚ) = 16928 / 33856 ∧ (16928 / 33856 : ℚ) = 1 / 2 := by
  norm_num
-- Power rule at x = 2: the rate of x^3 is 3 × 2^2 = 12, and the rate of x^(−2) is −2 × 2^(−3) = −0.25.
example : (3 : ℚ) * 2 ^ 2 = 12 ∧ (-2 : ℚ) * (2 : ℚ) ^ (-3 : ℤ) = -1 / 4 := by norm_num
-- Revenue peaks in week 13: price 18.5 times 148 bags is 2738, and there 0.5 × 148 + 18.5 × (−4) = 0.
example : (12 + (1 / 2 : ℚ) * 13) * (200 - 4 * 13) = 2738 ∧
    (1 / 2 : ℚ) * (200 - 4 * 13) + (12 + (1 / 2 : ℚ) * 13) * (-4) = 0 := by norm_num
-- The usual mistakes: product of rates 0.5 × (−4) = −2; reversed quotient −0.5; unsquared bottom 92.
example : (1 / 2 : ℚ) * (-4) = -2 ∧ ((2576 * (-4) - 36 * 184) / 184 ^ 2 : ℚ) = -1 / 2 ∧
    ((36 * 184 - 2576 * (-4)) / 184 : ℚ) = 92 := by norm_num

#print axioms product_rule
#print axioms quotient_rule
#print axioms power_rule_int
