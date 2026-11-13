-- Cox-Ingersoll-Ross: the closed-form CIR bond price solves the term-structure equation, its long yield is 2κθ/(γ+κ), and the Feller scale integral diverges at zero exactly when 2κθ ≥ σ².
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrability.Basic
import Mathlib.MeasureTheory.Integral.IntegrableOn
import Mathlib.Order.Filter.AtTopBot.Basic

open Real Filter Topology MeasureTheory Set

/-- The helper number γ = √(κ² + 2σ²). -/
noncomputable def cirGamma (κ σ : ℝ) : ℝ := Real.sqrt (κ ^ 2 + 2 * σ ^ 2)

/-- The shared denominator D(τ) = (γ + κ)(e^{γτ} − 1) + 2γ. -/
noncomputable def cirDen (κ σ τ : ℝ) : ℝ :=
  (cirGamma κ σ + κ) * (Real.exp (cirGamma κ σ * τ) - 1) + 2 * cirGamma κ σ

/-- The sensitivity B(τ) = 2(e^{γτ} − 1) / D(τ). -/
noncomputable def cirB (κ σ τ : ℝ) : ℝ :=
  2 * (Real.exp (cirGamma κ σ * τ) - 1) / cirDen κ σ τ

/-- The level factor A(τ) = [2γ e^{(γ+κ)τ/2} / D(τ)]^ν with ν = 2κθ/σ². -/
noncomputable def cirA (κ θ σ τ : ℝ) : ℝ :=
  (2 * cirGamma κ σ * Real.exp ((cirGamma κ σ + κ) * τ / 2) / cirDen κ σ τ) ^ (2 * κ * θ / σ ^ 2)

/-- The CIR price of a zero paying 1, with τ years left and today's rate r: P = A(τ) e^{−B(τ) r}. -/
noncomputable def cirPrice (κ θ σ τ r : ℝ) : ℝ :=
  cirA κ θ σ τ * Real.exp (-(cirB κ σ τ) * r)

lemma cirGamma_pos (κ σ : ℝ) (hσ : 0 < σ) : 0 < cirGamma κ σ :=
  Real.sqrt_pos.2 (by positivity)

lemma cirGamma_sq (κ σ : ℝ) : cirGamma κ σ ^ 2 = κ ^ 2 + 2 * σ ^ 2 :=
  Real.sq_sqrt (by positivity)

lemma cirDen_pos (κ σ τ : ℝ) (hκ : 0 < κ) (hσ : 0 < σ) (hτ : 0 ≤ τ) : 0 < cirDen κ σ τ := by
  have hγ := cirGamma_pos κ σ hσ
  have hE : 1 ≤ Real.exp (cirGamma κ σ * τ) := Real.one_le_exp (mul_nonneg hγ.le hτ)
  unfold cirDen
  have : 0 ≤ (cirGamma κ σ + κ) * (Real.exp (cirGamma κ σ * τ) - 1) :=
    mul_nonneg (by linarith) (by linarith)
  linarith

lemma hasDerivAt_cirDen (κ σ τ : ℝ) :
    HasDerivAt (fun t => cirDen κ σ t)
      ((cirGamma κ σ + κ) * (Real.exp (cirGamma κ σ * τ) * cirGamma κ σ)) τ := by
  have h1 : HasDerivAt (fun t => Real.exp (cirGamma κ σ * t))
      (Real.exp (cirGamma κ σ * τ) * cirGamma κ σ) τ := by
    simpa using ((hasDerivAt_id τ).const_mul (cirGamma κ σ)).exp
  unfold cirDen
  simpa using ((h1.sub_const 1).const_mul (cirGamma κ σ + κ)).add_const (2 * cirGamma κ σ)

lemma hasDerivAt_cirB (κ σ τ : ℝ) (hκ : 0 < κ) (hσ : 0 < σ) (hτ : 0 ≤ τ) :
    HasDerivAt (fun t => cirB κ σ t)
      (1 - κ * cirB κ σ τ - 1 / 2 * σ ^ 2 * cirB κ σ τ ^ 2) τ := by
  have hD := cirDen_pos κ σ τ hκ hσ hτ
  have h1 : HasDerivAt (fun t => Real.exp (cirGamma κ σ * t))
      (Real.exp (cirGamma κ σ * τ) * cirGamma κ σ) τ := by
    simpa using ((hasDerivAt_id τ).const_mul (cirGamma κ σ)).exp
  have h := ((h1.sub_const 1).const_mul 2).div (hasDerivAt_cirDen κ σ τ) hD.ne'
  unfold cirB
  convert h using 1
  have hs : σ ^ 2 = (cirGamma κ σ ^ 2 - κ ^ 2) / 2 := by rw [cirGamma_sq]; ring
  rw [hs]
  have hD' := hD
  unfold cirDen at hD' ⊢
  generalize Real.exp (cirGamma κ σ * τ) = E at *
  generalize cirGamma κ σ = γ at *
  have hD0 := hD'.ne'
  generalize hDdef : (γ + κ) * (E - 1) + 2 * γ = D at *
  field_simp
  rw [← hDdef]
  ring

lemma hasDerivAt_cirA (κ θ σ τ : ℝ) (hκ : 0 < κ) (hσ : 0 < σ) (hτ : 0 ≤ τ) :
    HasDerivAt (fun t => cirA κ θ σ t) (-(κ * θ * cirB κ σ τ) * cirA κ θ σ τ) τ := by
  have hD := cirDen_pos κ σ τ hκ hσ hτ
  have hγ := cirGamma_pos κ σ hσ
  have h1 : HasDerivAt (fun t => Real.exp ((cirGamma κ σ + κ) * t / 2))
      (Real.exp ((cirGamma κ σ + κ) * τ / 2) * ((cirGamma κ σ + κ) / 2)) τ := by
    simpa using (((hasDerivAt_id τ).const_mul (cirGamma κ σ + κ)).div_const 2).exp
  have hf := (h1.const_mul (2 * cirGamma κ σ)).div (hasDerivAt_cirDen κ σ τ) hD.ne'
  have hfpos : 0 < 2 * cirGamma κ σ * Real.exp ((cirGamma κ σ + κ) * τ / 2) / cirDen κ σ τ := by
    positivity
  have h := hf.rpow_const (p := 2 * κ * θ / σ ^ 2) (Or.inl hfpos.ne')
  unfold cirA
  convert h using 1
  simp only [Pi.div_apply]
  rw [Real.rpow_sub_one hfpos.ne']
  have hs : σ ^ 2 = (cirGamma κ σ ^ 2 - κ ^ 2) / 2 := by rw [cirGamma_sq]; ring
  have hs0 : cirGamma κ σ ^ 2 - κ ^ 2 ≠ 0 := by
    rw [cirGamma_sq]; have := sq_pos_of_pos hσ; apply ne_of_gt; linarith
  generalize (2 * cirGamma κ σ * Real.exp ((cirGamma κ σ + κ) * τ / 2) / cirDen κ σ τ) ^
    (2 * κ * θ / σ ^ 2) = Y
  rw [hs]
  have hD' := hD
  unfold cirB cirDen at hD' ⊢
  have hX := Real.exp_pos ((cirGamma κ σ + κ) * τ / 2)
  generalize Real.exp (cirGamma κ σ * τ) = E at *
  generalize Real.exp ((cirGamma κ σ + κ) * τ / 2) = X at *
  generalize cirGamma κ σ = γ at *
  have hD0 := hD'.ne'
  generalize hDdef : (γ + κ) * (E - 1) + 2 * γ = D at *
  field_simp
  rw [← hDdef]
  ring

#print axioms cirGamma_pos
#print axioms cirGamma_sq
#print axioms cirDen_pos
#print axioms hasDerivAt_cirDen
#print axioms hasDerivAt_cirB
#print axioms hasDerivAt_cirA

/-- CIR bond formula: for any positive pull speed κ, target θ and noise σ, the closed-form price
P(τ, r) = A(τ) e^{−B(τ) r} pays 1 at maturity and solves the term-structure equation
P_τ = κ(θ − r) P_r + ½ σ² r P_rr − r P at every rate r ≥ 0 and every time left τ ≥ 0. -/
theorem cir_bond_price_solves_term_structure_equation (κ θ σ : ℝ)
    (hκ : 0 < κ) (hθ : 0 < θ) (hσ : 0 < σ) :
    (∀ r : ℝ, 0 ≤ r → cirPrice κ θ σ 0 r = 1) ∧
    ∀ τ : ℝ, 0 ≤ τ → ∀ r : ℝ, 0 ≤ r →
      HasDerivAt (fun t => cirPrice κ θ σ t r)
        (κ * (θ - r) * deriv (fun x => cirPrice κ θ σ τ x) r
          + 1 / 2 * σ ^ 2 * r * deriv (deriv (fun x => cirPrice κ θ σ τ x)) r
          - r * cirPrice κ θ σ τ r) τ := by
  have hγ := cirGamma_pos κ σ hσ
  refine ⟨fun r _ => ?_, fun τ hτ r _ => ?_⟩
  · simp [cirPrice, cirA, cirB, cirDen, hγ.ne']
  · have hP : ∀ x, HasDerivAt (fun x => cirPrice κ θ σ τ x)
        (-(cirB κ σ τ) * cirPrice κ θ σ τ x) x := by
      intro x
      have h0 := (((hasDerivAt_id' x).const_mul (-(cirB κ σ τ))).exp).const_mul (cirA κ θ σ τ)
      unfold cirPrice
      convert h0 using 1
      ring
    have hderiv : deriv (fun x => cirPrice κ θ σ τ x) =
        fun x => -(cirB κ σ τ) * cirPrice κ θ σ τ x := by
      funext x
      exact (hP x).deriv
    rw [hderiv, ((hP r).const_mul (-(cirB κ σ τ))).deriv]
    have hA := hasDerivAt_cirA κ θ σ τ hκ hσ hτ
    have hB := hasDerivAt_cirB κ σ τ hκ hσ hτ
    have h : HasDerivAt (fun t => cirPrice κ θ σ t r)
        (-(κ * θ * cirB κ σ τ) * cirA κ θ σ τ * Real.exp (-(cirB κ σ τ) * r) +
          cirA κ θ σ τ * (Real.exp (-(cirB κ σ τ) * r) *
            (-(1 - κ * cirB κ σ τ - 1 / 2 * σ ^ 2 * cirB κ σ τ ^ 2) * r))) τ :=
      hA.mul ((hB.neg.mul_const r).exp)
    convert h using 1
    simp only [cirPrice]
    ring

/-- Long yield: for positive settings and any rate r ≥ 0 today, the yield −ln P(τ, r)/τ of a very
long zero settles at 2κθ/(γ + κ) as the maturity τ grows. -/
theorem cir_long_yield_tendsto (κ θ σ r : ℝ)
    (hκ : 0 < κ) (hθ : 0 < θ) (hσ : 0 < σ) (hr : 0 ≤ r) :
    Tendsto (fun τ => -Real.log (cirPrice κ θ σ τ r) / τ) atTop
      (𝓝 (2 * κ * θ / (cirGamma κ σ + κ))) := by
  have hγ := cirGamma_pos κ σ hσ
  have hγκ : 0 < cirGamma κ σ + κ := by linarith
  have he : Tendsto (fun τ => Real.exp (-(cirGamma κ σ * τ))) atTop (𝓝 0) :=
    tendsto_exp_neg_atTop_nhds_zero.comp (tendsto_id.const_mul_atTop hγ)
  have hg : Tendsto (fun τ => (cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
      + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ))) atTop (𝓝 (cirGamma κ σ + κ)) := by
    have := ((he.const_sub 1).const_mul (cirGamma κ σ + κ)).add (he.const_mul (2 * cirGamma κ σ))
    simpa using this
  have hlg := hg.log hγκ.ne'
  have hB : Tendsto (fun τ => 2 * (1 - Real.exp (-(cirGamma κ σ * τ))) /
      ((cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
        + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ)))) atTop
      (𝓝 (2 * (1 - 0) / (cirGamma κ σ + κ))) :=
    ((he.const_sub 1).const_mul 2).div hg hγκ.ne'
  have hsum := ((tendsto_const_nhds (x := -(2 * κ * θ / σ ^ 2 * Real.log (2 * cirGamma κ σ)))).add
      (hlg.const_mul (2 * κ * θ / σ ^ 2))).add (hB.mul_const r)
  have hlim := (tendsto_const_nhds (x := 2 * κ * θ / σ ^ 2 * (cirGamma κ σ - κ) / 2)).add
    (hsum.mul tendsto_inv_atTop_zero)
  have hval : 2 * κ * θ / σ ^ 2 * (cirGamma κ σ - κ) / 2 +
      (-(2 * κ * θ / σ ^ 2 * Real.log (2 * cirGamma κ σ)) +
        2 * κ * θ / σ ^ 2 * Real.log (cirGamma κ σ + κ) + 2 * (1 - 0) / (cirGamma κ σ + κ) * r) * 0
      = 2 * κ * θ / (cirGamma κ σ + κ) := by
    rw [mul_zero, add_zero]
    have hs : σ ^ 2 = (cirGamma κ σ ^ 2 - κ ^ 2) / 2 := by rw [cirGamma_sq]; ring
    have hs0 : cirGamma κ σ - κ ≠ 0 := by
      have h2 := cirGamma_sq κ σ
      have := sq_pos_of_pos hσ
      intro h0
      have : cirGamma κ σ = κ := by linarith
      rw [this] at h2
      linarith
    rw [hs]
    generalize cirGamma κ σ = γ at *
    have hfac : γ ^ 2 - κ ^ 2 = (γ - κ) * (γ + κ) := by ring
    rw [hfac]
    have h1 := mul_ne_zero hs0 hγκ.ne'
    field_simp
  rw [hval] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with τ hτ
  have hτ0 : 0 ≤ τ := hτ.le
  have hEe : Real.exp (cirGamma κ σ * τ) * Real.exp (-(cirGamma κ σ * τ)) = 1 := by
    rw [← Real.exp_add]; simp
  have he1 : Real.exp (-(cirGamma κ σ * τ)) ≤ 1 :=
    Real.exp_le_one_iff.2 (by have := mul_nonneg hγ.le hτ0; linarith)
  have hepos := Real.exp_pos (-(cirGamma κ σ * τ))
  have hEpos := Real.exp_pos (cirGamma κ σ * τ)
  have hgpos : 0 < (cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
      + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ)) := by
    have h1 : 0 ≤ (cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ))) :=
      mul_nonneg hγκ.le (by linarith)
    have h2 : 0 < 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ)) := by positivity
    linarith
  have hDeq : cirDen κ σ τ = Real.exp (cirGamma κ σ * τ) *
      ((cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
        + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ))) := by
    unfold cirDen
    linear_combination (κ - cirGamma κ σ) * hEe
  have hBeq : cirB κ σ τ = 2 * (1 - Real.exp (-(cirGamma κ σ * τ))) /
      ((cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
        + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ))) := by
    unfold cirB
    rw [hDeq, div_eq_div_iff (by positivity) hgpos.ne']
    linear_combination (2 * ((cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
        + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ)))) * hEe
  have hD := cirDen_pos κ σ τ hκ hσ hτ0
  have hf : 0 < 2 * cirGamma κ σ * Real.exp ((cirGamma κ σ + κ) * τ / 2) / cirDen κ σ τ := by
    positivity
  have hlogA : Real.log (cirA κ θ σ τ) = 2 * κ * θ / σ ^ 2 *
      (Real.log (2 * cirGamma κ σ) + (cirGamma κ σ + κ) * τ / 2 -
        (cirGamma κ σ * τ + Real.log ((cirGamma κ σ + κ) * (1 - Real.exp (-(cirGamma κ σ * τ)))
          + 2 * cirGamma κ σ * Real.exp (-(cirGamma κ σ * τ))))) := by
    unfold cirA
    rw [Real.log_rpow hf, Real.log_div (by positivity) hD.ne',
      Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_exp, hDeq,
      Real.log_mul hEpos.ne' hgpos.ne', Real.log_exp]
  have hApos : 0 < cirA κ θ σ τ := by
    unfold cirA; exact Real.rpow_pos_of_pos hf _
  unfold cirPrice
  rw [Real.log_mul hApos.ne' (Real.exp_pos _).ne', Real.log_exp, hlogA, hBeq]
  field_simp
  ring

/-- Feller's scale-function test: the scale density x^{−ν} e^{2κx/σ²}, with ν = 2κθ/σ², has an
infinite integral down to zero (so the rate never reaches zero) exactly when the Feller
condition 2κθ ≥ σ² holds; when 2κθ < σ² the integral is finite. -/
theorem feller_scale_integral_diverges_iff (κ θ σ b : ℝ)
    (hκ : 0 < κ) (hθ : 0 < θ) (hσ : 0 < σ) (hb : 0 < b) :
    ¬ IntegrableOn (fun x : ℝ => x ^ (-(2 * κ * θ / σ ^ 2)) * Real.exp (2 * κ * x / σ ^ 2))
        (Set.Ioc 0 b) ↔ σ ^ 2 ≤ 2 * κ * θ := by
  have hc : 0 < 2 * κ / σ ^ 2 := by positivity
  rw [integrableOn_Ioc_iff_integrableOn_Ioo]
  have key : IntegrableOn (fun x : ℝ => x ^ (-(2 * κ * θ / σ ^ 2)) * Real.exp (2 * κ * x / σ ^ 2))
      (Ioo 0 b) ↔ IntegrableOn (fun x : ℝ => x ^ (-(2 * κ * θ / σ ^ 2))) (Ioo 0 b) := by
    have hm2 : AEStronglyMeasurable (fun x : ℝ => x ^ (-(2 * κ * θ / σ ^ 2)))
        (volume.restrict (Ioo 0 b)) :=
      ContinuousOn.aestronglyMeasurable
        (ContinuousOn.rpow_const continuousOn_id (fun x hx => Or.inl (ne_of_gt hx.1)))
        measurableSet_Ioo
    have hm1 : AEStronglyMeasurable
        (fun x : ℝ => x ^ (-(2 * κ * θ / σ ^ 2)) * Real.exp (2 * κ * x / σ ^ 2))
        (volume.restrict (Ioo 0 b)) :=
      ContinuousOn.aestronglyMeasurable
        (ContinuousOn.mul
          (ContinuousOn.rpow_const continuousOn_id (fun x hx => Or.inl (ne_of_gt hx.1)))
          (by fun_prop))
        measurableSet_Ioo
    constructor
    · intro h
      refine Integrable.mono' h hm2 ?_
      refine (ae_restrict_iff' measurableSet_Ioo).2 (Filter.Eventually.of_forall fun x hx => ?_)
      have hp : 0 < x ^ (-(2 * κ * θ / σ ^ 2)) := Real.rpow_pos_of_pos hx.1 _
      have he : 1 ≤ Real.exp (2 * κ * x / σ ^ 2) := Real.one_le_exp (by
        have := hx.1; positivity)
      rw [Real.norm_eq_abs, abs_of_pos hp]
      nlinarith
    · intro h
      refine Integrable.mono' (h.const_mul (Real.exp (2 * κ * b / σ ^ 2))) hm1 ?_
      refine (ae_restrict_iff' measurableSet_Ioo).2 (Filter.Eventually.of_forall fun x hx => ?_)
      have hp : 0 < x ^ (-(2 * κ * θ / σ ^ 2)) := Real.rpow_pos_of_pos hx.1 _
      have he : Real.exp (2 * κ * x / σ ^ 2) ≤ Real.exp (2 * κ * b / σ ^ 2) := by
        apply Real.exp_le_exp.2
        apply div_le_div_of_nonneg_right _ (by positivity)
        nlinarith [hx.2]
      rw [Real.norm_eq_abs, abs_of_pos (mul_pos hp (Real.exp_pos _))]
      nlinarith
  rw [key, intervalIntegral.integrableOn_Ioo_rpow_iff hb, not_lt, neg_le_neg_iff, le_div_iff₀ (by positivity),
    one_mul]

-- The card's market: κ = 3/10, θ = 1/20, σ = 1/20.
-- Feller ratio ν = 2κθ/σ² = 12.
example : 2 * (3 / 10 : ℚ) * (1 / 20) / (1 / 20) ^ 2 = 12 := by norm_num
-- Pull power 3/100 against noise power 1/400: Feller holds.
example : 2 * (3 / 10 : ℚ) * (1 / 20) = 3 / 100 ∧ (1 / 20 : ℚ) ^ 2 = 1 / 400 := by norm_num
example : (1 / 20 : ℚ) ^ 2 ≤ 2 * (3 / 10) * (1 / 20) := by norm_num
-- γ² = κ² + 2σ² = 19/200.
example : (3 / 10 : ℚ) ^ 2 + 2 * (1 / 20) ^ 2 = 19 / 200 := by norm_num
-- Noise 1/5 breaks Feller: 1/25 beats 3/100.
example : 2 * (3 / 10 : ℚ) * (1 / 20) < (1 / 5) ^ 2 := by norm_num

#print axioms cir_bond_price_solves_term_structure_equation
#print axioms cir_long_yield_tendsto
#print axioms feller_scale_integral_diverges_iff
