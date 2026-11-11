-- Taylor series in the plane: a function with a complex derivative on an open disc equals its Taylor series at every point of that disc, holomorphic and analytic are the same on open sets, and the series of 1/(1 + z^2) about 0 fails past the poles ±i.
import Mathlib.Analysis.Complex.TaylorSeries
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Nat

noncomputable def invOneAddSqCoeff (n : ℕ) : ℂ := if Even n then (-1) ^ (n / 2) else 0

theorem hasFPowerSeriesOnBall_inv_one_add_sq :
    HasFPowerSeriesOnBall (fun w : ℂ ↦ 1 / (1 + w ^ 2))
      (FormalMultilinearSeries.ofScalars ℂ invOneAddSqCoeff) 0 1 where
  r_le := by
    have := FormalMultilinearSeries.le_radius_of_bound
      (p := FormalMultilinearSeries.ofScalars ℂ invOneAddSqCoeff) 1 (r := 1) (fun n ↦ by
        rw [FormalMultilinearSeries.ofScalars_norm]
        simp only [NNReal.coe_one, one_pow, mul_one, invOneAddSqCoeff]
        split_ifs <;> simp)
    simpa using this
  r_pos := by simp
  hasSum := by
    intro y hy
    have hy0 : ‖y‖₊ < 1 := by simpa [enorm_eq_nnnorm] using hy
    have hy' : ‖y‖ < 1 := by exact_mod_cast hy0
    rw [FormalMultilinearSeries.ofScalars_apply_eq']
    have hg : ‖-y ^ 2‖ < 1 := by
      rw [norm_neg, norm_pow]; nlinarith [norm_nonneg y]
    have h := hasSum_geometric_of_norm_lt_one hg
    have hinj : Function.Injective (fun k : ℕ ↦ 2 * k) := fun a b h ↦ by simpa using h
    rw [← hinj.hasSum_iff]
    · convert h using 1
      · ext k
        have hc : invOneAddSqCoeff (2 * k) = (-1) ^ k := by
          simp [invOneAddSqCoeff]
        simp only [Function.comp_apply, smul_eq_mul]
        rw [hc, neg_pow (y ^ 2) k, pow_mul]
      · simp [one_div, sub_neg_eq_add]
    · intro n hn
      have : ¬ Even n := by
        rintro ⟨k, rfl⟩; exact hn ⟨k, by ring⟩
      simp [invOneAddSqCoeff, this]

theorem iteratedDeriv_inv_one_add_sq (n : ℕ) :
    (n ! : ℂ)⁻¹ * iteratedDeriv n (fun w : ℂ ↦ 1 / (1 + w ^ 2)) 0 = invOneAddSqCoeff n := by
  have h1 := hasFPowerSeriesOnBall_inv_one_add_sq.hasFPowerSeriesAt
  have h2 := h1.analyticAt.hasFPowerSeriesAt
  have := FormalMultilinearSeries.ofScalars_series_injective (𝕜 := ℂ) (E := ℂ) (h2.eq_formalMultilinearSeries h1)
  have := congrFun this n
  rw [← this, div_eq_inv_mul]

#print axioms invOneAddSqCoeff
#print axioms hasFPowerSeriesOnBall_inv_one_add_sq
#print axioms iteratedDeriv_inv_one_add_sq

/-- A function with a complex derivative throughout the open disc of radius `R` about `a`
equals its Taylor series about `a` at every point `z` of that disc: the sum over `n` of
`f⁽ⁿ⁾(a) / n! · (z - a)ⁿ` converges to `f z`. -/
theorem holomorphic_on_disc_eq_taylor_series {f : ℂ → ℂ} {a : ℂ} {R : ℝ}
    (hf : DifferentiableOn ℂ f (Metric.ball a R)) {z : ℂ} (hz : z ∈ Metric.ball a R) :
    HasSum (fun n : ℕ ↦ (n ! : ℂ)⁻¹ * iteratedDeriv n f a * (z - a) ^ n) (f z) := by
  convert Complex.hasSum_taylorSeries_on_ball hf hz using 2 with n
  rw [smul_eq_mul, smul_eq_mul]; ring

/-- Holomorphic and analytic are the same property: on an open set of the plane, a function
has a complex derivative at every point exactly when, near each point, it equals a convergent
power series. -/
theorem holomorphic_iff_analytic_on_open {f : ℂ → ℂ} {s : Set ℂ} (hs : IsOpen s) :
    DifferentiableOn ℂ f s ↔ AnalyticOnNhd ℂ f s := by
  exact (Complex.analyticOnNhd_iff_differentiableOn hs).symm

/-- The series cannot pass a pole: the Taylor series of `1/(1 + z^2)` about 0 diverges at
every `z` farther from 0 than the poles `±i`, that is, whenever `|z| > 1` (for example at
`z = 1.2`). -/
theorem taylor_series_of_inv_one_add_sq_diverges_past_poles {z : ℂ} (hz : 1 < ‖z‖) :
    ¬ Summable (fun n : ℕ ↦
      (n ! : ℂ)⁻¹ * iteratedDeriv n (fun w : ℂ ↦ 1 / (1 + w ^ 2)) 0 * z ^ n) := by
  intro hs
  simp_rw [iteratedDeriv_inv_one_add_sq] at hs
  have ht := hs.tendsto_atTop_zero
  have ht2 := (ht.comp (Filter.tendsto_id.const_mul_atTop' (by norm_num : (0:ℕ) < 2))).norm
  simp only [norm_zero] at ht2
  have hge : ∀ k : ℕ, (1 : ℝ) ≤ ‖((fun n ↦ invOneAddSqCoeff n * z ^ n) ∘ fun k ↦ 2 * id k) k‖ := by
    intro k
    simp [invOneAddSqCoeff]
    exact one_le_pow₀ hz.le
  have := ge_of_tendsto ht2 (Filter.Eventually.of_forall hge)
  norm_num at this

-- About a = 2: 1 + z^2 = 5 + 4(z - 2) + (z - 2)^2.
example : ∀ z : ℚ, 1 + z ^ 2 = 5 + 4 * (z - 2) + (z - 2) ^ 2 := by
  intro z; ring

-- The card's coefficients about 2, exactly: c0 = 1/5, c1 = -4/25, c2 = 11/125 (0.088),
-- c3 = -24/625 (-0.0384), c4 = 41/3125 (0.01312), from 5 c0 = 1 and 5 c_n + 4 c_(n-1) + c_(n-2) = 0.
example : (5 : ℚ) * (1 / 5) = 1 := by norm_num
example : (5 : ℚ) * (-4 / 25) + 4 * (1 / 5) = 0 := by norm_num
example : (5 : ℚ) * (11 / 125) + 4 * (-4 / 25) + 1 / 5 = 0 := by norm_num
example : (5 : ℚ) * (-24 / 625) + 4 * (11 / 125) + (-4 / 25) = 0 := by norm_num
example : (5 : ℚ) * (41 / 3125) + 4 * (-24 / 625) + 11 / 125 = 0 := by norm_num

-- Five terms at z = 1.2 (step -4/5 from 2): sum 799521/1953125 = 0.409355...
example : (1 / 5 : ℚ) + (-4 / 25) * (-4 / 5) + (11 / 125) * (-4 / 5) ^ 2
    + (-24 / 625) * (-4 / 5) ^ 3 + (41 / 3125) * (-4 / 5) ^ 4 = 799521 / 1953125 := by norm_num

-- True value 1/(1 + 1.2^2) = 25/61, and the five-term error 57344/119140625 = 0.0004813136...
example : (1 : ℚ) / (1 + (6 / 5) ^ 2) = 25 / 61 := by norm_num
example : (25 / 61 : ℚ) - 799521 / 1953125 = 57344 / 119140625 := by norm_num

-- About a = 0: the recursion c_n + c_(n-2) = 0, c0 = 1, c1 = 0 gives 1, 0, -1, 0, 1, 0, -1.
example : (1 : ℚ) + 0 * 0 = 1 ∧ (-1 : ℚ) + 1 = 0 ∧ (1 : ℚ) + (-1) = 0 ∧ (-1 : ℚ) + 1 = 0 := by
  norm_num

-- About 0 at z = 1/2: 1/(1 + 1/4) = 4/5 (the card's 0.800000).
example : (1 : ℚ) / (1 + (1 / 2) ^ 2) = 4 / 5 := by norm_num

-- Distance from 2 to the pole i, squared: 2^2 + 1^2 = 5, so the reach about 2 is √5.
example : (2 : ℕ) ^ 2 + 1 ^ 2 = 5 := by norm_num

#print axioms holomorphic_on_disc_eq_taylor_series
#print axioms holomorphic_iff_analytic_on_open
#print axioms taylor_series_of_inv_one_add_sq_diverges_past_poles
