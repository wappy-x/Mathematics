-- Unit roots: a random walk of independent shocks has variance t σ² after t days and so spreads without limit, an autoregression with carry-over factor below 1 levels off at σ²/(1 − ρ²), and differencing white noise once too often gives a lag-one autocorrelation of exactly −1/2.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Basic

open MeasureTheory ProbabilityTheory Filter Topology

/-- Variance of a weighted sum of independent shocks `ε (i + 1)`. -/
theorem variance_weighted_sum_shift
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : ℕ → Ω → ℝ) (h_indep : iIndepFun ε P) (h_finite : ∀ t, MemLp (ε t) 2 P)
    (s : Finset ℕ) (c : ℕ → ℝ) :
    Var[fun ω => ∑ i ∈ s, c i * ε (i + 1) ω; P] = ∑ i ∈ s, c i ^ 2 * Var[ε (i + 1); P] := by
  rw [variance_fun_sum' (X := fun i ω => c i * ε (i + 1) ω)
    (fun i _ => (h_finite (i + 1)).const_mul (c i))]
  refine Finset.sum_congr rfl fun i hi => ?_
  rw [Finset.sum_eq_single i]
  · rw [covariance_const_mul_left, covariance_const_mul_right,
      covariance_self (h_finite (i + 1)).aemeasurable]
    ring
  · intro j _ hji
    rw [covariance_const_mul_left, covariance_const_mul_right,
      (h_indep.indepFun (by omega : i + 1 ≠ j + 1)).covariance_eq_zero (h_finite _) (h_finite _)]
    ring
  · intro h; exact absurd hi h

#print axioms variance_weighted_sum_shift

/-- A random walk's spread grows without limit. The shocks `ε 1, ε 2, …` are independent,
have finite variance, and each has the same variance `σ²`. The walk adds one shock a day:
`y (t + 1) = y t + ε (t + 1)`. Then for every day `t` the variance of the distance travelled
is `Var(y t − y 0) = t σ²`, and when `σ > 0` that variance grows without limit. -/
theorem random_walk_variance_eq_mul_and_unbounded
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : ℕ → Ω → ℝ) (σ : ℝ)
    (h_indep : iIndepFun ε P)
    (h_finite : ∀ t, MemLp (ε t) 2 P)
    (h_var : ∀ t, Var[ε t; P] = σ ^ 2)
    (y : ℕ → Ω → ℝ)
    (hy : ∀ t ω, y (t + 1) ω = y t ω + ε (t + 1) ω) :
    (∀ t : ℕ, Var[y t - y 0; P] = t * σ ^ 2) ∧
      (0 < σ → Tendsto (fun t : ℕ => Var[y t - y 0; P]) atTop atTop) := by
  have hrep : ∀ t : ℕ, y t - y 0 = fun ω => ∑ i ∈ Finset.range t, (1 : ℝ) * ε (i + 1) ω := by
    intro t
    induction t with
    | zero => funext ω; simp
    | succ n ih =>
      funext ω
      have := congrFun ih ω
      simp only [Pi.sub_apply] at this ⊢
      rw [Finset.sum_range_succ, ← this, hy]
      ring
  have hv : ∀ t : ℕ, Var[y t - y 0; P] = t * σ ^ 2 := by
    intro t
    rw [hrep t, variance_weighted_sum_shift ε h_indep h_finite]
    simp [h_var]
  refine ⟨hv, fun hσ => ?_⟩
  simp_rw [hv]
  exact tendsto_natCast_atTop_atTop.atTop_mul_const (by positivity)

/-- With a carry-over factor below 1 the spread levels off. The shocks are as above, the
series starts at 0 and follows `y (t + 1) = ρ y t + ε (t + 1)` with `|ρ| < 1`. Then
`Var(y t) = σ² (1 − ρ^(2t)) / (1 − ρ²)` for every day `t`, and this variance settles at
`σ² / (1 − ρ²)` as `t` grows. -/
theorem stationary_ar_variance_levels_off
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : ℕ → Ω → ℝ) (σ ρ : ℝ) (hρ : |ρ| < 1)
    (h_indep : iIndepFun ε P)
    (h_finite : ∀ t, MemLp (ε t) 2 P)
    (h_var : ∀ t, Var[ε t; P] = σ ^ 2)
    (y : ℕ → Ω → ℝ)
    (hy0 : ∀ ω, y 0 ω = 0)
    (hy : ∀ t ω, y (t + 1) ω = ρ * y t ω + ε (t + 1) ω) :
    (∀ t : ℕ, Var[y t; P] = σ ^ 2 * (1 - ρ ^ (2 * t)) / (1 - ρ ^ 2)) ∧
      Tendsto (fun t : ℕ => Var[y t; P]) atTop (𝓝 (σ ^ 2 / (1 - ρ ^ 2))) := by
  have hρ2 : ρ ^ 2 < 1 := (sq_lt_one_iff_abs_lt_one ρ).2 hρ
  have hne : 1 - ρ ^ 2 ≠ 0 := by linarith
  have hrep : ∀ t : ℕ, y t = fun ω => ∑ i ∈ Finset.range t, ρ ^ (t - 1 - i) * ε (i + 1) ω := by
    intro t
    induction t with
    | zero => funext ω; simp [hy0]
    | succ n ih =>
      funext ω
      rw [hy, ih, Finset.sum_range_succ, Finset.mul_sum]
      simp only [Nat.add_sub_cancel, Nat.sub_self, pow_zero, one_mul]
      congr 1
      refine Finset.sum_congr rfl fun i hi => ?_
      have hi' := Finset.mem_range.1 hi
      have : n - i = (n - 1 - i) + 1 := by omega
      rw [this, pow_succ]
      ring
  have hgeo : ∀ t : ℕ,
      (∑ i ∈ Finset.range t, (ρ ^ (t - 1 - i)) ^ 2) * (1 - ρ ^ 2) = 1 - ρ ^ (2 * t) := by
    intro t
    induction t with
    | zero => simp
    | succ n ih =>
      rw [Finset.sum_range_succ]
      simp only [Nat.add_sub_cancel, Nat.sub_self, pow_zero, one_pow]
      have hs : ∑ i ∈ Finset.range n, (ρ ^ (n - i)) ^ 2
          = ρ ^ 2 * ∑ i ∈ Finset.range n, (ρ ^ (n - 1 - i)) ^ 2 := by
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun i hi => ?_
        have hi' := Finset.mem_range.1 hi
        have : n - i = (n - 1 - i) + 1 := by omega
        rw [this, pow_succ]
        ring
      rw [hs, add_mul, mul_assoc, ih]
      rw [show 2 * (n + 1) = 2 * n + 2 by ring, pow_add, pow_mul]
      ring
  have hv : ∀ t : ℕ, Var[y t; P] = σ ^ 2 * (1 - ρ ^ (2 * t)) / (1 - ρ ^ 2) := by
    intro t
    rw [hrep t, variance_weighted_sum_shift ε h_indep h_finite]
    simp only [h_var]
    rw [← Finset.sum_mul, ← hgeo t]
    field_simp
  refine ⟨hv, ?_⟩
  simp_rw [hv]
  have h0 : Tendsto (fun t : ℕ => ρ ^ (2 * t)) atTop (𝓝 0) := by
    simp_rw [pow_mul]
    exact tendsto_pow_atTop_nhds_zero_of_lt_one (sq_nonneg ρ) hρ2
  have := ((tendsto_const_nhds (x := (1 : ℝ))).sub h0).const_mul (σ ^ 2) |>.div_const (1 - ρ ^ 2)
  simpa using this

/-- Differencing once too often builds a pattern into pure noise. The shocks are independent,
have finite variance, and each has the same variance `σ² > 0`. The over-differenced series
`w t = ε (t + 1) − ε t` has variance `2σ²`, consecutive values have covariance `−σ²`, and so
its lag-one autocorrelation is exactly `−1/2`, whatever the shock size. -/
theorem over_differencing_lag_one_autocorrelation
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : ℕ → Ω → ℝ) (σ : ℝ) (hσ : 0 < σ)
    (h_indep : iIndepFun ε P)
    (h_finite : ∀ t, MemLp (ε t) 2 P)
    (h_var : ∀ t, Var[ε t; P] = σ ^ 2)
    (w : ℕ → Ω → ℝ)
    (hw : ∀ t ω, w t ω = ε (t + 1) ω - ε t ω) (t : ℕ) :
    Var[w t; P] = 2 * σ ^ 2 ∧ cov[w (t + 1), w t; P] = -σ ^ 2 ∧
      cov[w (t + 1), w t; P] / Var[w t; P] = -1 / 2 := by
  have hw' : ∀ s, w s = ε (s + 1) - ε s := fun s => funext fun ω => hw s ω
  have hc : ∀ i j, i ≠ j → cov[ε i, ε j; P] = 0 := fun i j hij =>
    (h_indep.indepFun hij).covariance_eq_zero (h_finite _) (h_finite _)
  have h1 : Var[w t; P] = 2 * σ ^ 2 := by
    rw [hw', variance_sub (h_finite _) (h_finite _), hc _ _ (by omega), h_var, h_var]
    ring
  have h2 : cov[w (t + 1), w t; P] = -σ ^ 2 := by
    rw [hw', hw', covariance_sub_sub (h_finite _) (h_finite _) (h_finite _) (h_finite _),
      hc (t + 1 + 1) (t + 1) (by omega), hc (t + 1 + 1) t (by omega),
      hc (t + 1) t (by omega), covariance_self (h_finite _).aemeasurable, h_var]
    ring
  refine ⟨h1, h2, ?_⟩
  rw [h1, h2]
  have : σ ^ 2 ≠ 0 := by positivity
  field_simp

-- The spread figure, 1% shocks (σ = 1 in percent): the variance after t days is t σ², so the
-- standard deviation is 5 at day 25, 10 at day 100, 15 at day 225 (5² = 25, 10² = 100, 15² = 225).
example : (25 : ℚ) * 1 ^ 2 = 5 ^ 2 := by norm_num
example : (100 : ℚ) * 1 ^ 2 = 10 ^ 2 := by norm_num
example : (225 : ℚ) * 1 ^ 2 = 15 ^ 2 := by norm_num
-- After 250 days the exact variance is 250 squared percent.
example : (250 : ℚ) * 1 ^ 2 = 250 := by norm_num

-- Over-differencing with σ = 1: variance 1 + 1 = 2, lag-one covariance −1, ratio −1/2.
example : (-(1 : ℚ) ^ 2) / (2 * 1 ^ 2) = -1 / 2 := by norm_num

#print axioms random_walk_variance_eq_mul_and_unbounded
#print axioms stationary_ar_variance_levels_off
#print axioms over_differencing_lag_one_autocorrelation
