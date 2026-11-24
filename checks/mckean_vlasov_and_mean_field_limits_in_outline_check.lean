-- McKean-Vlasov equations in outline: the exact Gaussian bank example, its 1/N gap integral, the limit variance equation and the Picard rounds toward the self-consistent mean.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Nat.Factorial.Basic

open Real Filter Topology

lemma hasDerivAt_exp_const_mul (c x : ℝ) :
    HasDerivAt (fun u => Real.exp (c * u)) (Real.exp (c * x) * c) x := by
  have := ((hasDerivAt_id x).const_mul c).exp
  simpa using this

#print axioms hasDerivAt_exp_const_mul

/-- Propagation of chaos in numbers: for banks pulled toward the crowd's average at rate
`κ > 0` with noise size `σ`, the mean square gap between bank `i` and its limit copy after
time `t`, `(σ² / N) ∫₀ᵗ (1 - e^{-κu})² du`, equals
`(σ² / N) (t - 2(1 - e^{-κt})/κ + (1 - e^{-2κt})/(2κ))`. -/
theorem gap_mean_square_eq (κ σ t : ℝ) (N : ℕ) (hκ : 0 < κ) (ht : 0 ≤ t) (hN : 1 ≤ N) :
    σ ^ 2 / N * ∫ u in (0 : ℝ)..t, (1 - Real.exp (-κ * u)) ^ 2
      = σ ^ 2 / N * (t - 2 * (1 - Real.exp (-κ * t)) / κ
          + (1 - Real.exp (-2 * κ * t)) / (2 * κ)) := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  congr 1
  have hF : ∀ x ∈ Set.uIcc (0:ℝ) t, HasDerivAt
      (fun u => u + 2 * Real.exp (-κ * u) / κ - Real.exp (-2 * κ * u) / (2 * κ))
      ((1 - Real.exp (-κ * x)) ^ 2) x := by
    intro x _
    have h1 := hasDerivAt_exp_const_mul (-κ) x
    have h2 := hasDerivAt_exp_const_mul (-2 * κ) x
    have := (((hasDerivAt_id x).add ((h1.const_mul 2).div_const κ)).sub (h2.div_const (2 * κ)))
    refine this.congr_deriv ?_
    have e : Real.exp (-2 * κ * x) = Real.exp (-κ * x) ^ 2 := by
      rw [← Real.exp_nat_mul]; ring_nf
    rw [e]; field_simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF
    (by apply Continuous.intervalIntegrable; fun_prop)]
  simp; field_simp; ring

/-- The limit variance `v(t) = σ²/(2κ) (1 - e^{-2κt})` of the McKean-Vlasov bank starts at 0,
solves the Ornstein-Uhlenbeck variance equation `v' = σ² - 2κ v`, and settles to `σ²/(2κ)`. -/
theorem limit_variance_solves_ou_equation (κ σ : ℝ) (hκ : 0 < κ) :
    let v : ℝ → ℝ := fun t => σ ^ 2 / (2 * κ) * (1 - Real.exp (-2 * κ * t))
    v 0 = 0 ∧ (∀ t, HasDerivAt v (σ ^ 2 - 2 * κ * v t) t) ∧
      Tendsto v atTop (𝓝 (σ ^ 2 / (2 * κ))) := by
  intro v
  have hκ0 : κ ≠ 0 := hκ.ne'
  refine ⟨by simp [v], ?_, ?_⟩
  · intro t
    have h := ((hasDerivAt_exp_const_mul (-2 * κ) t).const_sub 1).const_mul (σ ^ 2 / (2 * κ))
    refine h.congr_deriv ?_
    simp only [v]
    field_simp; ring
  · have hlim : Tendsto (fun t : ℝ => Real.exp (-2 * κ * t)) atTop (𝓝 0) := by
      have : Tendsto (fun t : ℝ => -2 * κ * t) atTop atBot :=
        tendsto_id.const_mul_atTop_of_neg (by linarith)
      exact Real.tendsto_exp_atBot.comp this
    have := (hlim.const_sub 1).const_mul (σ ^ 2 / (2 * κ))
    simpa [v] using this

/-- Picard iteration on the mean path, `m⁽ᵏ⁺¹⁾(t) = x₀ e^{-κt} + ∫₀ᵗ κ e^{-κ(t-s)} m⁽ᵏ⁾(s) ds`:
starting from the guess 0, each round adds one term of the exponential series, so round `k` is
`x₀ e^{-κt} (1 + κt + ⋯ + (κt)^{k-1}/(k-1)!)`; and the constant mean path `x₀` reproduces itself. -/
theorem picard_round_adds_series_term (κ x₀ t : ℝ) (k : ℕ) (hκ : 0 < κ) :
    (x₀ * Real.exp (-κ * t) + ∫ s in (0 : ℝ)..t, κ * Real.exp (-κ * (t - s)) *
        (x₀ * Real.exp (-κ * s) * ∑ j ∈ Finset.range k, (κ * s) ^ j / (j.factorial : ℝ))
      = x₀ * Real.exp (-κ * t) * ∑ j ∈ Finset.range (k + 1), (κ * t) ^ j / (j.factorial : ℝ)) ∧
    (x₀ * Real.exp (-κ * t) + ∫ s in (0 : ℝ)..t, κ * Real.exp (-κ * (t - s)) * x₀ = x₀) := by
  have hκ0 : κ ≠ 0 := hκ.ne'
  constructor
  · have hG : ∀ x ∈ Set.uIcc (0:ℝ) t, HasDerivAt
        (fun s => x₀ * Real.exp (-κ * t) *
          ∑ j ∈ Finset.range k, (κ * s) ^ (j + 1) / ((j + 1).factorial : ℝ))
        (κ * Real.exp (-κ * (t - x)) *
          (x₀ * Real.exp (-κ * x) * ∑ j ∈ Finset.range k, (κ * x) ^ j / (j.factorial : ℝ))) x := by
      intro x _
      have hs : HasDerivAt
          (fun s => ∑ j ∈ Finset.range k, (κ * s) ^ (j + 1) / ((j + 1).factorial : ℝ))
          (∑ j ∈ Finset.range k, κ * ((κ * x) ^ j / (j.factorial : ℝ))) x := by
        have := HasDerivAt.sum (u := Finset.range k)
          (A := fun j s => (κ * s) ^ (j + 1) / ((j + 1).factorial : ℝ))
          (A' := fun j => κ * ((κ * x) ^ j / (j.factorial : ℝ))) (x := x) ?_
        · convert this using 1; funext s; simp [Finset.sum_apply]
        intro j _
        have h1 := (((hasDerivAt_id x).const_mul κ).pow (j + 1)).div_const ((j + 1).factorial : ℝ)
        refine h1.congr_deriv ?_
        simp only [id, Nat.factorial_succ, Nat.cast_mul, Nat.cast_succ, Nat.add_sub_cancel,
          mul_one]
        have : (j.factorial : ℝ) ≠ 0 := by positivity
        field_simp
      have := hs.const_mul (x₀ * Real.exp (-κ * t))
      convert this using 1
      rw [← Finset.mul_sum]
      have e : Real.exp (-κ * (t - x)) * Real.exp (-κ * x) = Real.exp (-κ * t) := by
        rw [← Real.exp_add]; ring_nf
      linear_combination (κ * x₀ * ∑ j ∈ Finset.range k, (κ * x) ^ j / (j.factorial : ℝ)) * e
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hG
      (by apply Continuous.intervalIntegrable; fun_prop)]
    rw [Finset.sum_range_succ']
    simp
    ring
  · have hH : ∀ x ∈ Set.uIcc (0:ℝ) t, HasDerivAt
        (fun s => x₀ * Real.exp (-κ * (t - s)))
        (κ * Real.exp (-κ * (t - x)) * x₀) x := by
      intro x _
      have := (((hasDerivAt_id x).const_sub t).const_mul (-κ)).exp.const_mul x₀
      refine this.congr_deriv ?_
      simp only [id]; ring
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hH
      (by apply Continuous.intervalIntegrable; fun_prop)]
    simp

-- The noise of a bank's gap from the average has variance 1 - 1/N, for N = 1,000.
example : ((1 : ℚ) - 1 / 1000) ^ 2 + (1000 - 1) / 1000 ^ 2 = 1 - 1 / 1000 := by norm_num
-- Long-run spread around the average: (1 - 1/1,000)/2 = 0.4995.
example : ((1 : ℚ) - 1 / 1000) / 2 = 4995 / 10000 := by norm_num
-- Ten banks: the average's variance after a year, 1/10, is 100 times the 1,000-bank value.
example : (1 : ℚ) / 10 = 100 * (1 / 1000) := by norm_num
-- After 1,000 years a crowd of 1,000 has an average with variance t/N = 1.
example : (1000 : ℚ) / 1000 = 1 := by norm_num

#print axioms gap_mean_square_eq
#print axioms limit_variance_solves_ou_equation
#print axioms picard_round_adds_series_term
