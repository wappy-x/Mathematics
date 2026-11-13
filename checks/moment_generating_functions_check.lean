-- Moment generating functions: when M_X(t) = E[e^(tX)] is finite on an interval around t = 0 its k-th derivative at 0 is the k-th moment and its power series has coefficients E[X^k]/k!, and for independent X and Y the function of X + Y is the product of their functions.
import Mathlib.Probability.Moments.MGFAnalytic
import Mathlib.Probability.Moments.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Real Set Finset
open scoped Nat

/-! A random variable is a measurable function `X : Ω → ℝ` on a probability space `(Ω, μ)`.
Mathlib's `mgf X μ t` is the card's `M_X(t) = E[e^(tX)]`, the average `∫ e^(t X ω) dμ`.
"The function is finite at t" is `Integrable (fun ω => exp (t * X ω)) μ`.
`μ[X ^ k]` is the k-th moment `E[X^k]`, and `iteratedDeriv k f 0` is the k-th derivative
of `f` at 0. -/

/-- Moments by differentiation: if the moment generating function of `X` is finite on an
interval `(-a, a)` around the dial's zero, then for every `k` its k-th derivative at `t = 0`
is the k-th moment `E[X^k]`. -/
theorem iteratedDeriv_mgf_zero_eq_moment {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (a : ℝ) (ha : 0 < a)
    (hfin : ∀ t ∈ Ioo (-a) a, Integrable (fun ω => exp (t * X ω)) μ) (k : ℕ) :
    iteratedDeriv k (mgf X μ) 0 = μ[X ^ k] := by
  have h0 : (0:ℝ) ∈ interior (integrableExpSet X μ) := by
    rw [mem_interior]
    exact ⟨Ioo (-a) a, fun t ht => hfin t ht, isOpen_Ioo, ⟨by linarith, ha⟩⟩
  exact iteratedDeriv_mgf_zero h0 k

/-- The moment generating function is the exponential generating function of the moments:
if it is finite on an interval `(-a, a)` around zero, then at every dial setting `t` in that
interval `M_X(t) = Σ_k E[X^k] / k! · t^k`, the series converging to `M_X(t)`. -/
theorem mgf_eq_sum_moments_div_factorial {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X : Ω → ℝ) (a : ℝ) (ha : 0 < a)
    (hfin : ∀ t ∈ Ioo (-a) a, Integrable (fun ω => exp (t * X ω)) μ) :
    ∀ t ∈ Ioo (-a) a, HasSum (fun k : ℕ => μ[X ^ k] / (k ! : ℝ) * t ^ k) (mgf X μ t) := by
  intro t ht
  have h0 : (0:ℝ) ∈ interior (integrableExpSet X μ) := by
    rw [mem_interior]
    exact ⟨Ioo (-a) a, fun t ht => hfin t ht, isOpen_Ioo, ⟨by linarith, ha⟩⟩
  have hXm : AEMeasurable X μ := aemeasurable_of_mem_interior_integrableExpSet h0
  have hnt : -t ∈ Ioo (-a) a := ⟨by linarith [ht.2], by linarith [ht.1]⟩
  have hbig : Integrable (fun ω => exp (|t| * |X ω|)) μ :=
    integrable_exp_abs_mul_abs (hfin t ht) (hfin (-t) hnt)
  have key := hasSum_integral_of_dominated_convergence (μ := μ)
    (F := fun (k : ℕ) ω => X ω ^ k / (k ! : ℝ) * t ^ k) (f := fun ω => exp (t * X ω))
    (fun k ω => (|t| * |X ω|) ^ k / (k ! : ℝ))
    (fun k => by
      apply AEMeasurable.aestronglyMeasurable
      fun_prop)
    (fun k => Filter.Eventually.of_forall (fun ω => by
      rw [Real.norm_eq_abs, abs_mul, abs_div, abs_pow, abs_pow, mul_pow,
        abs_of_pos (by positivity : (0:ℝ) < (k ! : ℝ))]
      apply le_of_eq
      ring))
    (Filter.Eventually.of_forall (fun ω =>
      (NormedSpace.expSeries_div_hasSum_exp (|t| * |X ω|)).summable))
    (by
      refine hbig.congr (Filter.Eventually.of_forall (fun ω => ?_))
      simp only
      rw [(NormedSpace.expSeries_div_hasSum_exp (|t| * |X ω|)).tsum_eq, Real.exp_eq_exp_ℝ])
    (Filter.Eventually.of_forall (fun ω => by
      have := NormedSpace.expSeries_div_hasSum_exp (t * X ω)
      rw [← Real.exp_eq_exp_ℝ] at this
      convert this using 1
      funext k
      rw [mul_pow]
      ring))
  convert key using 1
  · funext k
    rw [integral_mul_const, integral_div]
    rfl
  · rfl

/-- The product rule: for independent random variables `X` and `Y`, the moment generating
function of the sum `X + Y` is the product of their two functions, at every dial setting `t`. -/
theorem mgf_add_eq_mul_of_indep {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω}
    [IsProbabilityMeasure μ] (X Y : Ω → ℝ) (hX : Measurable X) (hY : Measurable Y)
    (hindep : IndepFun X Y μ) (t : ℝ) :
    mgf (X + Y) μ t = mgf X μ t * mgf Y μ t := by
  exact hindep.mgf_add' hX.aestronglyMeasurable hY.aestronglyMeasurable

/-! The card's exact worked numbers, as fractions (0.5 = 1/2, 27.5 = 55/2, and so on). -/

-- One coin toss, X = 0 or 1 with chance 1/2 each: every moment E[X^k], k ≥ 1, is 1/2.
example : ∀ k : ℕ, k ≠ 0 →
    (0 : ℚ) ^ k * (1 / 2) + (1 : ℚ) ^ k * (1 / 2) = 1 / 2 := by
  intro k hk
  norm_num [zero_pow hk]
-- The coin's variance: 1/2 - (1/2)^2 = 1/4.
example : (1 / 2 : ℚ) - (1 / 2) ^ 2 = 1 / 4 := by norm_num
-- Ten tosses: 2^10 = 1,024 equally likely sequences; 252 of them have exactly five heads.
example : 2 ^ 10 = 1024 ∧ Nat.choose 10 5 = 252 := by decide
-- Ten tosses, S = number of heads: E[S] = 5, E[S^2] = 27.5, E[S^3] = 162.5, E[S^4] = 1,017.5.
example : (∑ j ∈ Finset.range 11, (Nat.choose 10 j : ℚ) * (j : ℚ) ^ 1) / 2 ^ 10 = 5 := by
  norm_num [Finset.sum_range_succ, Nat.choose]
example : (∑ j ∈ Finset.range 11, (Nat.choose 10 j : ℚ) * (j : ℚ) ^ 2) / 2 ^ 10 = 55 / 2 := by
  norm_num [Finset.sum_range_succ, Nat.choose]
example : (∑ j ∈ Finset.range 11, (Nat.choose 10 j : ℚ) * (j : ℚ) ^ 3) / 2 ^ 10 = 325 / 2 := by
  norm_num [Finset.sum_range_succ, Nat.choose]
example : (∑ j ∈ Finset.range 11, (Nat.choose 10 j : ℚ) * (j : ℚ) ^ 4) / 2 ^ 10 = 2035 / 2 := by
  norm_num [Finset.sum_range_succ, Nat.choose]
-- The derivatives of (1/2 + 1/2 e^t)^10 at zero, by hand: 10 × 1/2 = 5,
-- 90 × (1/2)^2 + 10 × 1/2 = 27.5, and 720 × (1/2)^3 + 270 × (1/2)^2 + 10 × 1/2 = 162.5.
example : (10 : ℚ) * (1 / 2) = 5 := by norm_num
example : (90 : ℚ) * (1 / 2) ^ 2 + 10 * (1 / 2) = 55 / 2 := by norm_num
example : (720 : ℚ) * (1 / 2) ^ 3 + 270 * (1 / 2) ^ 2 + 10 * (1 / 2) = 325 / 2 := by norm_num
-- Ten tosses' variance 27.5 - 25 = 2.5, ten times the coin's 1/4.
example : (55 / 2 : ℚ) - 5 ^ 2 = 5 / 2 ∧ (5 / 2 : ℚ) = 10 * (1 / 4) := by norm_num
-- Third moment about the mean: 162.5 - 3 × 5 × 27.5 + 2 × 5^3 = 0.
example : (325 / 2 : ℚ) - 3 * 5 * (55 / 2) + 2 * 5 ^ 3 = 0 := by norm_num
-- The t^2 coefficient of M_S is 13.75; it takes 2! × 13.75 = 27.5 to get the second moment.
example : (55 / 2 : ℚ) / 2 = 55 / 4 ∧ (2 : ℚ) * (55 / 4) = 55 / 2 := by norm_num
-- One toss copied ten times (0 or 10): average square 50 and variance 25, not 27.5 and 2.5.
example : (10 : ℚ) ^ 2 * (1 / 2) = 50 ∧ (50 : ℚ) - 5 ^ 2 = 25 := by norm_num
-- Cumulants add: 10 × 1/2 = 5 and 10 × 1/4 = 2.5.
example : (10 : ℚ) * (1 / 2) = 5 ∧ (10 : ℚ) * (1 / 4) = 5 / 2 := by norm_num

#print axioms iteratedDeriv_mgf_zero_eq_moment
#print axioms mgf_eq_sum_moments_div_factorial
#print axioms mgf_add_eq_mul_of_indep
