-- Greeks under jumps: a delta hedge loses exactly the squared move times an average of gamma at a gap, that loss is positive whenever gamma is, and the jump model's delta lies between 0 and the dividend discount factor.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Analysis.SpecialFunctions.Exponential

open Real

/-- Every point of the move from `S` to `S J` is a positive share price. -/
theorem gap_point_pos (S J t : ℝ) (hS : 0 < S) (hJ : 0 < J) (ht : t ∈ Set.Icc (0 : ℝ) 1) :
    0 < S + t * (S * (J - 1)) := by
  obtain ⟨h0, h1⟩ := ht
  have h : S + t * (S * (J - 1)) = S * ((1 - t) + t * J) := by ring
  rw [h]
  apply mul_pos hS
  rcases eq_or_lt_of_le h1 with rfl | h
  · simp [hJ]
  · have := mul_nonneg h0 hJ.le
    linarith

/-- The curvature integrand is continuous on `[0, 1]`. -/
theorem gap_integrand_continuousOn (C : ℝ → ℝ) (hC : ContDiffOn ℝ 2 C (Set.Ioi 0))
    (S J : ℝ) (hS : 0 < S) (hJ : 0 < J) :
    ContinuousOn (fun t => (1 - t) * deriv (deriv C) (S + t * (S * (J - 1))))
      (Set.Icc (0 : ℝ) 1) := by
  have hC1 : ContDiffOn ℝ 1 (deriv C) (Set.Ioi 0) := hC.deriv_of_isOpen isOpen_Ioi (by norm_num)
  have hc2 : ContinuousOn (deriv (deriv C)) (Set.Ioi 0) :=
    hC1.continuousOn_deriv_of_isOpen isOpen_Ioi (by norm_num)
  refine (continuousOn_const.sub continuousOn_id).mul (hc2.comp ?_ ?_)
  · exact (continuous_const.add (continuous_id.mul continuous_const)).continuousOn
  · intro t ht
    exact gap_point_pos S J t hS hJ ht


/-- The loss at a gap is curvature across the gap. Let `C` be a call price that is twice
continuously differentiable in the share price on the positive share prices, with delta
`deriv C` and gamma `deriv (deriv C)`. The hedger holds `deriv C S` shares, and a gap
multiplies the share price `S > 0` by `J > 0`, a dollar move `z = S (J - 1)`. Then the
hedger's loss `R = C (S J) - C S - S (J - 1) Δ` equals `z² ∫₀¹ (1 - t) Γ(S + t z) dt`. -/
theorem gap_loss_eq_curvature_integral (C : ℝ → ℝ) (hC : ContDiffOn ℝ 2 C (Set.Ioi 0))
    (S J : ℝ) (hS : 0 < S) (hJ : 0 < J) :
    C (S * J) - C S - S * (J - 1) * deriv C S
      = (S * (J - 1)) ^ 2 *
          ∫ t in (0 : ℝ)..1, (1 - t) * deriv (deriv C) (S + t * (S * (J - 1))) := by
  have hopen : IsOpen (Set.Ioi (0 : ℝ)) := isOpen_Ioi
  have hd1 : DifferentiableOn ℝ C (Set.Ioi 0) := hC.differentiableOn (by norm_num)
  have hC1 : ContDiffOn ℝ 1 (deriv C) (Set.Ioi 0) := hC.deriv_of_isOpen hopen (by norm_num)
  have hd2 : DifferentiableOn ℝ (deriv C) (Set.Ioi 0) := hC1.differentiableOn (by norm_num)
  have hcont := gap_integrand_continuousOn C hC S J hS hJ
  have hpt := gap_point_pos S J
  set z := S * (J - 1) with hz
  have hFTC : ∫ t in (0 : ℝ)..1, z ^ 2 * ((1 - t) * deriv (deriv C) (S + t * z))
      = ((1 - 1) * z * deriv C (S + 1 * z) + C (S + 1 * z))
        - ((1 - 0) * z * deriv C (S + 0 * z) + C (S + 0 * z)) := by
    apply intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun t => (1 - t) * z * deriv C (S + t * z) + C (S + t * z))
    · intro t ht
      rw [Set.uIcc_of_le zero_le_one] at ht
      have hp : S + t * z ∈ Set.Ioi (0 : ℝ) := hpt t hS hJ ht
      have hin : HasDerivAt (fun t => S + t * z) z t := by
        simpa using ((hasDerivAt_id t).mul_const z).const_add S
      have h1 : HasDerivAt (fun t => C (S + t * z)) (deriv C (S + t * z) * z) t :=
        (hd1.differentiableAt (hopen.mem_nhds hp)).hasDerivAt.comp t hin
      have h2 : HasDerivAt (fun t => deriv C (S + t * z))
          (deriv (deriv C) (S + t * z) * z) t :=
        HasDerivAt.comp (h₂ := deriv C) t
          (hd2.differentiableAt (hopen.mem_nhds hp)).hasDerivAt hin
      have h3 : HasDerivAt (fun t => (1 - t) * z) (-z) t := by
        simpa using ((hasDerivAt_id t).const_sub 1).mul_const z
      convert (h3.mul h2).add h1 using 1
      ring
    · apply ContinuousOn.intervalIntegrable
      rw [Set.uIcc_of_le zero_le_one]
      exact continuousOn_const.mul hcont
  rw [← intervalIntegral.integral_const_mul, hFTC]
  have hSJ : S + 1 * z = S * J := by rw [hz]; ring
  rw [hSJ, zero_mul, add_zero]
  ring

/-- The seller loses on every gap, up or down. Under the same smoothness, if gamma is
positive at every point of the move from `S` to `S J`, and the gap is a real move
(`J ≠ 1`), then the hedger's loss `C (S J) - C S - S (J - 1) Δ` is strictly positive. -/
theorem gap_loss_pos (C : ℝ → ℝ) (hC : ContDiffOn ℝ 2 C (Set.Ioi 0))
    (S J : ℝ) (hS : 0 < S) (hJ : 0 < J) (hJ1 : J ≠ 1)
    (hΓ : ∀ t ∈ Set.Icc (0 : ℝ) 1, 0 < deriv (deriv C) (S + t * (S * (J - 1)))) :
    0 < C (S * J) - C S - S * (J - 1) * deriv C S := by
  rw [gap_loss_eq_curvature_integral C hC S J hS hJ]
  have hz : S * (J - 1) ≠ 0 := mul_ne_zero hS.ne' (sub_ne_zero.mpr hJ1)
  apply mul_pos
  · exact lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hz))
  · apply intervalIntegral.intervalIntegral_pos_of_pos_on
    · apply ContinuousOn.intervalIntegrable
      rw [Set.uIcc_of_le zero_le_one]
      exact gap_integrand_continuousOn C hC S J hS hJ
    · intro t ht
      exact mul_pos (by linarith [ht.2]) (hΓ t (Set.Ioo_subset_Icc_self ht))
    · exact zero_lt_one

/-- The jump model's delta is a call's delta. In Merton's model with gap rate `λ ≥ 0`,
gap log-mean `μJ`, gap log-spread `δ`, average gap fraction `k = e^(μJ + δ²/2) - 1`,
and `τ > 0` years to expiry, the delta
`Δ = Σₙ pₙ e^(-qₙ τ) N(d₁,ₙ)` with Poisson weights `pₙ = e^(-λτ) (λτ)ⁿ / n!`,
branch yields `qₙ = q + λk - n (μJ + δ²/2)/τ`, branch volatilities
`σₙ = √(σ² + n δ²/τ)` and `N` the standard normal distribution function,
lies between `0` and `e^(-qτ)`. -/
theorem merton_delta_mem_Icc (S K r q σ lam μJ δ τ : ℝ) (hlam : 0 ≤ lam) (hτ : 0 < τ) :
    let k : ℝ := exp (μJ + δ ^ 2 / 2) - 1
    let p : ℕ → ℝ := fun n => exp (-lam * τ) * (lam * τ) ^ n / n.factorial
    let qn : ℕ → ℝ := fun n => q + lam * k - n * (μJ + δ ^ 2 / 2) / τ
    let σn : ℕ → ℝ := fun n => sqrt (σ ^ 2 + n * δ ^ 2 / τ)
    let d1 : ℕ → ℝ := fun n =>
      (log (S / K) + (r - qn n) * τ) / (σn n * sqrt τ) + σn n * sqrt τ / 2
    let N : ℝ → ℝ := ProbabilityTheory.cdf (ProbabilityTheory.gaussianReal 0 1)
    let Δ : ℝ := ∑' n : ℕ, p n * exp (-(qn n) * τ) * N (d1 n)
    0 ≤ Δ ∧ Δ ≤ exp (-q * τ) := by
  intro k p qn σn d1 N Δ
  have hN : ∀ y, 0 ≤ N y ∧ N y ≤ 1 := fun y =>
    ⟨ProbabilityTheory.cdf_nonneg _ y, ProbabilityTheory.cdf_le_one _ y⟩
  have hg : ∀ n : ℕ, p n * exp (-(qn n) * τ)
      = exp (-q * τ) * (exp (-(lam * τ * exp (μJ + δ ^ 2 / 2)))
          * (lam * τ * exp (μJ + δ ^ 2 / 2)) ^ n / n.factorial) := by
    intro n
    simp only [p, qn, k]
    rw [mul_pow (lam * τ) (exp (μJ + δ ^ 2 / 2)), ← Real.exp_nat_mul]
    have hc : (n : ℝ) * (μJ + δ ^ 2 / 2) / τ * τ = n * (μJ + δ ^ 2 / 2) :=
      div_mul_cancel₀ _ hτ.ne'
    have key : exp (-lam * τ)
          * exp (-(q + lam * (exp (μJ + δ ^ 2 / 2) - 1) - n * (μJ + δ ^ 2 / 2) / τ) * τ)
        = exp (-q * τ) * exp (-(lam * τ * exp (μJ + δ ^ 2 / 2)))
          * exp (n * (μJ + δ ^ 2 / 2)) := by
      rw [← exp_add, ← exp_add, ← exp_add]
      congr 1
      linear_combination hc
    linear_combination ((lam * τ) ^ n / (n.factorial : ℝ)) * key
  have hsum : HasSum (fun n : ℕ => p n * exp (-(qn n) * τ)) (exp (-q * τ)) := by
    simp_rw [hg]
    have := ((NormedSpace.expSeries_div_hasSum_exp (lam * τ * exp (μJ + δ ^ 2 / 2))).mul_left
      (exp (-(lam * τ * exp (μJ + δ ^ 2 / 2))))).mul_left (exp (-q * τ))
    convert this using 1
    · funext n
      ring
    · rw [← Real.exp_eq_exp_ℝ, ← exp_add]
      simp
  have hnn : ∀ n : ℕ, 0 ≤ p n * exp (-(qn n) * τ) := by
    intro n
    rw [hg]
    have : 0 ≤ lam * τ * exp (μJ + δ ^ 2 / 2) := by positivity
    positivity
  have hle : ∀ n : ℕ, p n * exp (-(qn n) * τ) * N (d1 n) ≤ p n * exp (-(qn n) * τ) :=
    fun n => mul_le_of_le_one_right (hnn n) (hN _).2
  have hnn' : ∀ n : ℕ, 0 ≤ p n * exp (-(qn n) * τ) * N (d1 n) := fun n =>
    mul_nonneg (hnn n) (hN _).1
  refine ⟨tsum_nonneg hnn', ?_⟩
  rw [← hsum.tsum_eq]
  exact Summable.tsum_le_tsum hle (Summable.of_nonneg_of_le hnn' hle hsum.summable)
    hsum.summable

-- The dollar moves in the card's gap table: S = 100 and J = 0.8, 0.9, 1.1, 1.2.
example : (100 : ℚ) * (8 / 10 - 1) = -20 := by norm_num
example : (100 : ℚ) * (9 / 10 - 1) = -10 := by norm_num
example : (100 : ℚ) * (11 / 10 - 1) = 10 := by norm_num
example : (100 : ℚ) * (12 / 10 - 1) = 20 := by norm_num

-- The vega factor S² σ τ for Acme: 100² × 0.20 × 1 = 2000.
example : (100 : ℚ) ^ 2 * (20 / 100) * 1 = 2000 := by norm_num

-- The chance of exactly one gap is λτ = 1/2 times the chance of none.
example : exp (-(1 / 2 : ℝ)) * (1 / 2) ^ 1 / (Nat.factorial 1) = (1 / 2) * exp (-(1 / 2 : ℝ)) := by
  norm_num [mul_comm]

#print axioms gap_point_pos
#print axioms gap_integrand_continuousOn
#print axioms gap_loss_eq_curvature_integral
#print axioms gap_loss_pos
#print axioms merton_delta_mem_Icc
