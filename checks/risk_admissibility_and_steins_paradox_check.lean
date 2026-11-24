-- Decision theory: a Bayes rule with constant squared-loss risk is minimax, the coin rule that adds √n/2 heads and √n/2 tails has the flat risk 1/(4(√n + 1)²), and the James-Stein shrink x/S has divergence (k − 2)/S.
import Mathlib.Probability.Decision.BayesEstimator
import Mathlib.Probability.Decision.Risk.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.RingTheory.Polynomial.Bernstein
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Pow

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-- Squared loss: the loss of the guess `y` when the quantity of interest is `q θ` is the
squared miss `(y − q θ)²`. -/
noncomputable def sqLoss {Θ : Type*} (q : Θ → ℝ) : Θ → ℝ → ℝ≥0∞ :=
  fun θ y => ENNReal.ofReal ((y - q θ) ^ 2)

/-- Evaluating a Bernstein polynomial gives the binomial weight. -/
lemma bern_eval (n ν : ℕ) (θ : ℝ) :
    (bernsteinPolynomial ℝ n ν).eval θ = (n.choose ν : ℝ) * θ ^ ν * (1 - θ) ^ (n - ν) := by
  simp [bernsteinPolynomial]

#print axioms bern_eval

/-- Changing one coordinate changes the sum of squares by the difference of squares. -/
lemma sum_update_sq {k : ℕ} (x : Fin k → ℝ) (i : Fin k) (t : ℝ) :
    ∑ j, (Function.update x i t j) ^ 2 = t ^ 2 + (∑ j, x j ^ 2 - x i ^ 2) := by
  rw [← Finset.add_sum_erase _ _ (Finset.mem_univ i),
    ← Finset.add_sum_erase _ _ (Finset.mem_univ i)]
  simp only [Function.update_self]
  have : ∑ j ∈ Finset.univ.erase i, (Function.update x i t j) ^ 2 =
      ∑ j ∈ Finset.univ.erase i, x j ^ 2 :=
    Finset.sum_congr rfl fun j hj => by
      rw [Function.update_of_ne (Finset.ne_of_mem_erase hj)]
  rw [this]; ring

#print axioms sum_update_sq

/-- **A Bayes rule with constant risk is minimax (Step 3).** Under squared loss, let the rule
`κ` be a Bayes rule for a prior `π` (its risk averaged over `π` is the smallest any rule can
have) and let its risk be the same number `C` at every truth `θ`. Then `κ` is minimax: its
worst risk equals the minimax risk (the smallest worst risk over all rules), and that minimax
risk is `C`. -/
theorem bayes_rule_with_constant_risk_is_minimax {Θ 𝓧 : Type*} [MeasurableSpace Θ]
    [MeasurableSpace 𝓧] (q : Θ → ℝ) (P : Kernel Θ 𝓧) (κ : Kernel 𝓧 ℝ) [IsMarkovKernel κ]
    (π : Measure Θ) [IsProbabilityMeasure π] (C : ℝ≥0∞)
    (hBayes : IsBayesEstimator (sqLoss q) P κ π)
    (hconst : ∀ θ, ∫⁻ y, sqLoss q θ y ∂((κ ∘ₖ P) θ) = C) :
    (⨆ θ, ∫⁻ y, sqLoss q θ y ∂((κ ∘ₖ P) θ)) = minimaxRisk (sqLoss q) P ∧
      minimaxRisk (sqLoss q) P = C := by
  have havg : avgRisk (sqLoss q) P κ π = C := by
    simp only [avgRisk, hconst, lintegral_const, measure_univ, mul_one]
  have h1 : C ≤ minimaxRisk (sqLoss q) P := by
    rw [← havg, hBayes]; exact bayesRisk_le_minimaxRisk _ _ _
  have h2 : minimaxRisk (sqLoss q) P ≤ ⨆ θ, ∫⁻ y, sqLoss q θ y ∂((κ ∘ₖ P) θ) :=
    by unfold minimaxRisk; exact iInf₂_le κ ‹IsMarkovKernel κ›
  have h3 : (⨆ θ, ∫⁻ y, sqLoss q θ y ∂((κ ∘ₖ P) θ)) ≤ C := iSup_le fun θ => (hconst θ).le
  exact ⟨le_antisymm (h3.trans h1) h2, le_antisymm (h2.trans h3) h1⟩

/-- **The coin's minimax rule has flat risk (Steps 1 and 3).** With `n ≥ 1` flips of a coin
whose chance of heads is `θ`, the heads count `x` has the binomial law
`C(n, x) θ^x (1 − θ)^(n − x)`. The rule that adds `√n/2` heads and `√n/2` tails,
`(x + √n/2)/(n + √n)`, has average squared miss `1/(4(√n + 1)²)` whatever `θ` is.
For `n = 16` this is the rule `(x + 2)/20` with risk `1/100`. -/
theorem binomial_minimax_rule_has_constant_risk (n : ℕ) (hn : 0 < n) (θ : ℝ) :
    ∑ x ∈ Finset.range (n + 1),
        (n.choose x : ℝ) * θ ^ x * (1 - θ) ^ (n - x) *
          ((x + Real.sqrt n / 2) / (n + Real.sqrt n) - θ) ^ 2 =
      1 / (4 * (Real.sqrt n + 1) ^ 2) := by
  set b : ℕ → ℝ := fun x => (n.choose x : ℝ) * θ ^ x * (1 - θ) ^ (n - x) with hb
  have h0 : ∑ x ∈ Finset.range (n + 1), b x = 1 := by
    have := congrArg (Polynomial.eval θ) (bernsteinPolynomial.sum ℝ n)
    simpa [Polynomial.eval_finsetSum, bern_eval, hb] using this
  have h1 : ∑ x ∈ Finset.range (n + 1), (x : ℝ) * b x = n * θ := by
    have := congrArg (Polynomial.eval θ) (bernsteinPolynomial.sum_smul ℝ n)
    simpa [Polynomial.eval_finsetSum, bern_eval, hb, nsmul_eq_mul] using this
  have h2 : ∑ x ∈ Finset.range (n + 1), ((n : ℝ) * θ - x) ^ 2 * b x = n * θ * (1 - θ) := by
    have := congrArg (Polynomial.eval θ) (bernsteinPolynomial.variance ℝ n)
    simpa [Polynomial.eval_finsetSum, bern_eval, hb, nsmul_eq_mul, mul_assoc] using this
  set s := Real.sqrt n with hs
  have hs2 : s ^ 2 = n := Real.sq_sqrt (Nat.cast_nonneg n)
  have hspos : 0 < s := Real.sqrt_pos.mpr (by exact_mod_cast hn)
  have hD : (n : ℝ) + s ≠ 0 := by positivity
  have key : ∀ x ∈ Finset.range (n + 1),
      b x * ((x + s / 2) / (n + s) - θ) ^ 2 =
        (1 / (n + s) ^ 2) * (((n : ℝ) * θ - x) ^ 2 * b x) +
        (2 * s * (1 / 2 - θ) / (n + s) ^ 2) * ((x : ℝ) * b x) +
        ((s ^ 2 * (1 / 2 - θ) ^ 2 - 2 * s * (1 / 2 - θ) * n * θ) / (n + s) ^ 2) * b x := by
    intro x _
    field_simp
    ring
  rw [Finset.sum_congr rfl key, Finset.sum_add_distrib, Finset.sum_add_distrib,
    ← Finset.mul_sum, ← Finset.mul_sum, ← Finset.mul_sum, h0, h1, h2]
  have hn' : (n : ℝ) = s ^ 2 := hs2.symm
  rw [hn']
  have : s + 1 ≠ 0 := by positivity
  field_simp
  ring

/-- **The divergence of the James-Stein shrink (Step 6).** For a list `x` of `k` readings, not
all zero, with sum of squares `S = x₁² + ⋯ + x_k²`, the slope of `x_i / S` in `x_i`, summed
over the `k` coordinates, equals `(k − 2)/S`. -/
theorem james_stein_divergence (k : ℕ) (x : Fin k → ℝ) (hx : x ≠ 0) :
    ∑ i, deriv (fun t : ℝ => t / ∑ j, (Function.update x i t j) ^ 2) (x i) =
      ((k : ℝ) - 2) / ∑ j, x j ^ 2 := by
  set S := ∑ j, x j ^ 2 with hS
  have hSne : S ≠ 0 := by
    intro h0
    apply hx
    funext j
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sq_nonneg (x j))).mp h0 j
      (Finset.mem_univ j)
    simpa using this
  have hderiv : ∀ i, deriv (fun t : ℝ => t / ∑ j, (Function.update x i t j) ^ 2) (x i) =
      (S - 2 * x i ^ 2) / S ^ 2 := by
    intro i
    have hf : (fun t : ℝ => t / ∑ j, (Function.update x i t j) ^ 2) =
        fun t => t / (t ^ 2 + (S - x i ^ 2)) := by
      funext t; rw [sum_update_sq]
    rw [hf]
    have hden : x i ^ 2 + (S - x i ^ 2) ≠ 0 := by simpa using hSne
    have hd : HasDerivAt (fun t : ℝ => t ^ 2 + (S - x i ^ 2)) (2 * x i) (x i) := by
      have h2 : HasDerivAt (fun t : ℝ => t ^ 2 + (S - x i ^ 2))
          ((2 : ℕ) * x i ^ (2 - 1) + 0) (x i) :=
        HasDerivAt.add (hasDerivAt_pow 2 (x i)) (hasDerivAt_const (x i) (S - x i ^ 2))
      exact HasDerivAt.congr_deriv h2 (by norm_num)
    have := HasDerivAt.fun_div (hasDerivAt_id' (x := x i)) hd hden
    rw [this.deriv]
    have : x i ^ 2 + (S - x i ^ 2) = S := by ring
    rw [this]; ring
  rw [Finset.sum_congr rfl fun i _ => hderiv i, ← Finset.sum_div, Finset.sum_sub_distrib,
    ← Finset.mul_sum, ← hS]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  field_simp

-- Step 1: for (X + 2)/20 with 16 flips, variance part plus squared bias part is 4/400.
example (θ : ℚ) : 16 * θ * (1 - θ) + (2 - 4 * θ) ^ 2 = 4 := by ring
-- The plain fraction's worst risk, at a fair coin: 0.5 × 0.5 / 16 = 0.015625.
example : (1 / 2 : ℚ) * (1 / 2) / 16 = 15625 / 1000000 := by norm_num
-- The minimax rule for 16 flips adds √16/2 = 2 heads and 2 tails; its risk 1/(4(4 + 1)²) = 0.01.
example : (4 : ℚ) / 2 = 2 ∧ (1 : ℚ) / (4 * (4 + 1) ^ 2) = 1 / 100 := by norm_num
-- Summing over all 17 head counts at a fair coin: (X + 2)/20 has risk 1/100, X/16 has 1/64.
example : ∑ x ∈ Finset.range 17, ((Nat.choose 16 x : ℚ) * (1 / 2) ^ 16 *
    ((x + 2) / 20 - 1 / 2) ^ 2) = 1 / 100 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num [Nat.choose]
example : ∑ x ∈ Finset.range 17, ((Nat.choose 16 x : ℚ) * (1 / 2) ^ 16 *
    ((x : ℚ) / 16 - 1 / 2) ^ 2) = 1 / 64 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num [Nat.choose]
-- The risks cross where θ(1 − θ) = 0.16: at θ = 0.2, θ(1 − θ)/16 = 0.01.
example : (1 / 5 : ℚ) * (1 - 1 / 5) = 16 / 100 ∧ (16 / 100 : ℚ) / 16 = 1 / 100 := by norm_num
-- Bayes risk of the plain fraction under Beta(2, 2): (1/5)/16 = 0.0125.
example : (1 / 5 : ℚ) / 16 = 125 / 10000 := by norm_num
-- 11 heads of 16: plain 11/16 = 0.6875, minimax (11 + 2)/20 = 0.65.
example : (11 : ℚ) / 16 = 6875 / 10000 ∧ ((11 : ℚ) + 2) / 20 = 65 / 100 := by norm_num
-- Stores, in hundredths: 1.44 + 0.16 + 4.00 + 0.09 + 1.21 = 6.90.
example : 144 + 16 + 400 + 9 + 121 = 690 := by decide
-- Share kept: 1 − 3/6.90 = 13/23 (0.5652...).
example : (1 : ℚ) - 3 / (690 / 100) = 13 / 23 := by norm_num
-- Total risk at θ = 0 for five means: 5 − 3² × (1/3) = 2.
example : (5 : ℚ) - 3 ^ 2 * (1 / 3) = 2 := by norm_num
-- With constant c in place of k − 2 = 3, at θ = 0 the risk is 5 − c(6 − c)/3: c = 5 gives 10/3, c = 7 gives 22/3.
example : (5 : ℚ) - 5 * (6 - 5) * (1 / 3) = 10 / 3 ∧ (5 : ℚ) - 7 * (6 - 7) * (1 / 3) = 22 / 3 := by
  norm_num

#print axioms bayes_rule_with_constant_risk_is_minimax
#print axioms binomial_minimax_rule_has_constant_risk
#print axioms james_stein_divergence
