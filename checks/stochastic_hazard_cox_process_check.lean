-- A random hazard: survival is the average of e to the minus the area under the hazard, that average is never below the flat-hazard survival, and the CIR closed form solves the card's two Riccati equations.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.Convex.Integral
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory

/-- The helper `γ = √(κ² + 2σ²)` of the CIR survival formula. -/
noncomputable def cirGamma (κ σ : ℝ) : ℝ := Real.sqrt (κ ^ 2 + 2 * σ ^ 2)

/-- The shared denominator `(γ + κ)(e^{γt} − 1) + 2γ`. -/
noncomputable def cirDen (κ σ t : ℝ) : ℝ :=
  (cirGamma κ σ + κ) * (Real.exp (cirGamma κ σ * t) - 1) + 2 * cirGamma κ σ

/-- The sensitivity to today's hazard, `B(t) = 2(e^{γt} − 1) / denominator`. -/
noncomputable def cirB (κ σ t : ℝ) : ℝ :=
  2 * (Real.exp (cirGamma κ σ * t) - 1) / cirDen κ σ t

/-- The level factor, `A(t) = [2γ e^{(γ+κ)t/2} / denominator] ^ ν` with `ν = 2κθ/σ²`. -/
noncomputable def cirA (κ θ σ t : ℝ) : ℝ :=
  (2 * cirGamma κ σ * Real.exp ((cirGamma κ σ + κ) * t / 2) / cirDen κ σ t) ^ (2 * κ * θ / σ ^ 2)

/-- Jensen gap: for a nonnegative random hazard whose area up to the horizon `T ≥ 0` has a
finite average, survival `E[e^{-Λ_T}]` is never below the flat-hazard answer `e^{-E[Λ_T]}`,
where `Λ_T` is the area under the hazard path from `0` to `T`. -/
theorem cox_survival_ge_flat_survival {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (hazard : Ω → ℝ → ℝ) (T : ℝ) (hT : 0 ≤ T)
    (h_nonneg : ∀ ω t, 0 ≤ hazard ω t)
    (h_int : Integrable (fun ω => ∫ t in (0 : ℝ)..T, hazard ω t) μ) :
    Real.exp (-∫ ω, (∫ t in (0 : ℝ)..T, hazard ω t) ∂μ)
      ≤ ∫ ω, Real.exp (-∫ t in (0 : ℝ)..T, hazard ω t) ∂μ := by
  have hL : ∀ ω, 0 ≤ ∫ t in (0 : ℝ)..T, hazard ω t := fun ω =>
    intervalIntegral.integral_nonneg hT (fun t _ => h_nonneg ω t)
  have hgi : Integrable (Real.exp ∘ fun ω => -∫ t in (0 : ℝ)..T, hazard ω t) μ := by
    refine Integrable.mono' (integrable_const (1 : ℝ)) ?_ ?_
    · exact Real.continuous_exp.comp_aestronglyMeasurable h_int.neg.aestronglyMeasurable
    · refine Filter.Eventually.of_forall fun ω => ?_
      simp only [Function.comp, Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
      exact Real.exp_le_one_iff.mpr (neg_nonpos.mpr (hL ω))
  have := convexOn_exp.map_integral_le Real.continuous_exp.continuousOn isClosed_univ
    (Filter.Eventually.of_forall fun _ => Set.mem_univ _) h_int.neg hgi
  simpa only [Pi.neg_apply, integral_neg] using this

/-- The Cox construction: let `ξ` be an exponential clock with average 1, independent of the
area `Λ_T` under a nonnegative hazard path. The firm is alive at `T` exactly when `Λ_T < ξ`,
and the chance of that is the average of `e^{-Λ_T}`. -/
theorem cox_survival_eq_average_exp_neg_area {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (hazard : Ω → ℝ → ℝ) (T : ℝ) (hT : 0 ≤ T)
    (h_nonneg : ∀ ω t, 0 ≤ hazard ω t)
    (h_meas : Measurable (fun ω => ∫ t in (0 : ℝ)..T, hazard ω t))
    (ξ : Ω → ℝ) (hξ_law : μ.map ξ = expMeasure 1)
    (h_indep : IndepFun (fun ω => ∫ t in (0 : ℝ)..T, hazard ω t) ξ μ) :
    μ.real {ω | (∫ t in (0 : ℝ)..T, hazard ω t) < ξ ω}
      = ∫ ω, Real.exp (-∫ t in (0 : ℝ)..T, hazard ω t) ∂μ := by
  set L : Ω → ℝ := fun ω => ∫ t in (0 : ℝ)..T, hazard ω t with hLdef
  have hL : ∀ ω, 0 ≤ L ω := fun ω =>
    intervalIntegral.integral_nonneg hT (fun t _ => h_nonneg ω t)
  have : IsProbabilityMeasure (expMeasure 1) := isProbabilityMeasure_expMeasure one_pos
  -- ξ is a.e. measurable, since the exponential law has no atoms
  have hξ : AEMeasurable ξ μ := by
    by_contra h
    have h1 := Measure.map_of_not_aemeasurable_of_ne_zero h (IsProbabilityMeasure.ne_zero μ)
    rw [hξ_law] at h1
    have h2 : expMeasure 1 {Classical.ofNonempty} = 0 := by
      unfold expMeasure gammaMeasure
      exact withDensity_absolutelyContinuous _ _ (Real.volume_singleton)
    rw [h1] at h2
    simp at h2
  -- tail of the exponential law
  have htail : ∀ x : ℝ, 0 ≤ x → expMeasure 1 (Set.Ioi x) = ENNReal.ofReal (Real.exp (-x)) := by
    intro x hx
    have hc := cdf_expMeasure_eq one_pos x
    rw [cdf_eq_real] at hc
    simp only [hx, ↓reduceIte, one_mul] at hc
    rw [← Set.compl_Iic, ← ofReal_measureReal, measureReal_compl measurableSet_Iic, hc]
    simp
  have hS : MeasurableSet {p : ℝ × ℝ | p.1 < p.2} := measurableSet_lt measurable_fst measurable_snd
  have hprod := (indepFun_iff_map_prod_eq_prod_map_map h_meas.aemeasurable hξ).mp h_indep
  have key : μ {ω | L ω < ξ ω} = ∫⁻ ω, ENNReal.ofReal (Real.exp (-L ω)) ∂μ := by
    have e1 : {ω | L ω < ξ ω} = (fun ω => (L ω, ξ ω)) ⁻¹' {p : ℝ × ℝ | p.1 < p.2} := rfl
    rw [e1, ← Measure.map_apply_of_aemeasurable (h_meas.aemeasurable.prodMk hξ) hS, hprod,
      Measure.prod_apply hS, hξ_law]
    have e2 : ∀ x : ℝ, Prod.mk x ⁻¹' {p : ℝ × ℝ | p.1 < p.2} = Set.Ioi x := fun x => rfl
    simp_rw [e2]
    have hae : ∀ᵐ x ∂(μ.map L), expMeasure 1 (Set.Ioi x) = ENNReal.ofReal (Real.exp (-x)) := by
      have h0 : ∀ᵐ x ∂(μ.map L), 0 ≤ x :=
        (ae_map_iff h_meas.aemeasurable (measurableSet_le measurable_const measurable_id)).mpr
          (Filter.Eventually.of_forall hL)
      exact h0.mono fun x hx => htail x hx
    rw [lintegral_congr_ae hae, lintegral_map (by fun_prop) h_meas]
  have hnn : 0 ≤ᵐ[μ] fun ω => Real.exp (-L ω) := Filter.Eventually.of_forall fun _ => (Real.exp_pos _).le
  rw [integral_eq_lintegral_of_nonneg_ae hnn (by fun_prop), ← key]
  rfl

/-- The CIR closed form solves the card's Riccati equations: `B(0) = 0`, `A(0) = 1`,
`B' = 1 − κB − σ²B²/2` and `(ln A)' = −κθB`, for any pull speed `κ`, long-run level `θ`
and nonzero volatility `σ`, at every horizon `t`. -/
theorem cir_survival_solves_riccati (κ θ σ : ℝ) (hσ : σ ≠ 0) (t : ℝ) :
    cirB κ σ 0 = 0 ∧ cirA κ θ σ 0 = 1 ∧
    HasDerivAt (cirB κ σ) (1 - κ * cirB κ σ t - σ ^ 2 / 2 * cirB κ σ t ^ 2) t ∧
    HasDerivAt (fun s => Real.log (cirA κ θ σ s)) (-(κ * θ) * cirB κ σ t) t := by
  set γ := cirGamma κ σ with hγdef
  have hσ2pos : 0 < σ ^ 2 := by positivity
  have hγ2 : γ ^ 2 = κ ^ 2 + 2 * σ ^ 2 := Real.sq_sqrt (by positivity)
  have hγ0 : 0 ≤ γ := Real.sqrt_nonneg _
  have hγpos : 0 < γ := by
    rcases hγ0.lt_or_eq with h | h
    · exact h
    · rw [← h] at hγ2; nlinarith
  have hγmk : 0 < γ - κ := by nlinarith
  have hγpk : 0 < γ + κ := by nlinarith
  have hDeq : ∀ s, cirDen κ σ s = (γ + κ) * (Real.exp (γ * s) - 1) + 2 * γ := fun s => rfl
  have hDpos : ∀ s, 0 < cirDen κ σ s := by
    intro s
    rw [hDeq]
    have := Real.exp_pos (γ * s)
    nlinarith
  have hE : HasDerivAt (fun s => Real.exp (γ * s)) (Real.exp (γ * t) * (γ * 1)) t :=
    ((hasDerivAt_id' t).const_mul γ).exp
  have hDd : HasDerivAt (cirDen κ σ) ((γ + κ) * (Real.exp (γ * t) * (γ * 1))) t := by
    have := ((hE.sub_const 1).const_mul (γ + κ)).add_const (2 * γ)
    exact this
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp [cirB]
  · have h0 : cirDen κ σ 0 = 2 * γ := by simp [hDeq]
    simp only [cirA, h0, mul_zero, zero_div, Real.exp_zero, mul_one]
    rw [div_self (by positivity), Real.one_rpow]
  · have hB : cirB κ σ = fun s => 2 * (Real.exp (γ * s) - 1) / cirDen κ σ s := rfl
    have := ((hE.sub_const 1).const_mul 2).div hDd (hDpos t).ne'
    rw [hB]
    convert this using 1
    have hσ2 : σ ^ 2 = (γ ^ 2 - κ ^ 2) / 2 := by linarith
    beta_reduce
    rw [hσ2]
    have hne := (hDpos t).ne'
    have hDv := hDeq t
    generalize cirDen κ σ t = Dv at hne hDv ⊢
    generalize Real.exp (γ * t) = e at hDv ⊢
    field_simp
    subst hDv
    ring
  · have hbase : ∀ s, 0 < 2 * γ * Real.exp ((γ + κ) * s / 2) / cirDen κ σ s := fun s => by
      have := hDpos s
      positivity
    have hlogA : (fun s => Real.log (cirA κ θ σ s)) = fun s => (2 * κ * θ / σ ^ 2) *
        (Real.log (2 * γ) + (γ + κ) * s / 2 - Real.log (cirDen κ σ s)) := by
      funext s
      have hD := (hDpos s).ne'
      simp only [cirA]
      rw [Real.log_rpow (hbase s), Real.log_div (by positivity) hD,
        Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_exp]
    rw [hlogA]
    have := (((((hasDerivAt_id' t).const_mul (γ + κ)).div_const 2).const_add
      (Real.log (2 * γ))).sub (hDd.log (hDpos t).ne')).const_mul (2 * κ * θ / σ ^ 2)
    convert this using 1
    have hσ2 : σ ^ 2 = (γ ^ 2 - κ ^ 2) / 2 := by linarith
    have hgk : γ ^ 2 - κ ^ 2 ≠ 0 := by nlinarith
    simp only [cirB]
    rw [hσ2]
    have hne := (hDpos t).ne'
    have hDv := hDeq t
    generalize cirDen κ σ t = Dv at hne hDv ⊢
    generalize Real.exp (γ * t) = e at hDv ⊢
    field_simp
    subst hDv
    ring

-- Feller ratio ν = 2κθ/σ² for Northwind (κ = 1/2, θ = 2/100) at volatilities 10%, 5%, 15%, 20%.
example : (2 : ℚ) * (1 / 2) * (2 / 100) / (10 / 100) ^ 2 = 2 := by norm_num
example : (2 : ℚ) * (1 / 2) * (2 / 100) / (5 / 100) ^ 2 = 8 := by norm_num
example : (2 : ℚ) * (1 / 2) * (2 / 100) / (15 / 100) ^ 2 = 8 / 9 := by norm_num
example : (2 : ℚ) * (1 / 2) * (2 / 100) / (20 / 100) ^ 2 = 1 / 2 := by norm_num
-- The expected area over five years at an average hazard of 2% is exactly 1/10.
example : (5 : ℚ) * (2 / 100) = 1 / 10 := by norm_num
-- γ² = κ² + 2σ² = 1/4 + 2/100 = 27/100.
example : (1 / 2 : ℚ) ^ 2 + 2 * (10 / 100) ^ 2 = 27 / 100 := by norm_num

#print axioms cox_survival_ge_flat_survival
#print axioms cox_survival_eq_average_exp_neg_area
#print axioms cir_survival_solves_riccati
