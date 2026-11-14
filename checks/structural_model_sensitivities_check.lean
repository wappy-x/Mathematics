-- How the balance-sheet claims move: in Merton's model more asset volatility raises the equity by exactly what it takes from the debt, a new dollar of assets splits as N(d1) to shareholders and N(-d1) to lenders, the equity's slopes against face, time and rate are the call's Greeks, and the credit spread depends on assets and debt only through leverage and rises with the face of the debt.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real

/-! The model (Merton): `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`, the area under the
standard bell curve to the left of `x`, and `φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, its height.
Assets `V`, face of the one zero-coupon debt `D`, asset volatility `σ`, riskless rate `r`,
years to the debt's due date `T`.
`d1 = (log (V / D) + (r + σ² / 2) T) / (σ √T)` and `d2 = d1 - σ √T`.
Equity `E = V N(d1) - D e^(-rT) N(d2)` (a call on the assets struck at the debt);
debt `B = V - E` (no cost of going bust, so the two claims are the whole firm);
credit spread `s = -log (B / D) / T - r`. -/

namespace StructuralSensitivities

/-- How far the assets sit above the debt, in units of `σ √T`, plus one. -/
noncomputable def d1 (V D σ r T : ℝ) : ℝ := (log (V / D) + (r + σ ^ 2 / 2) * T) / (σ * √T)

/-- `d2 = d1 - σ √T`. -/
noncomputable def d2 (V D σ r T : ℝ) : ℝ := d1 V D σ r T - σ * √T

/-- The equity: a Black–Scholes call on the assets struck at the face of the debt. -/
noncomputable def equity (V D σ r T : ℝ) : ℝ :=
  V * cdf (gaussianReal 0 1) (d1 V D σ r T) - D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T)

/-- The debt: the assets minus the equity. -/
noncomputable def debt (V D σ r T : ℝ) : ℝ := V - equity V D σ r T

/-- The credit spread: the debt's yield `-log (B / D) / T` minus the riskless rate. -/
noncomputable def spread (V D σ r T : ℝ) : ℝ := -log (debt V D σ r T / D) / T - r

/-! Helper facts about the standard normal curve and the model. -/

lemma gaussPDF_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma gaussCDF_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg 0 1 t))]

lemma gaussCDF_eq_add (x : ℝ) :
    cdf (gaussianReal 0 1) x =
      cdf (gaussianReal 0 1) 0 + ∫ t in (0 : ℝ)..x, gaussianPDFReal 0 1 t := by
  rw [gaussCDF_eq_integral, gaussCDF_eq_integral,
    ← intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
      (integrable_gaussianPDFReal 0 1).integrableOn]
  ring

lemma gaussCDF_hasDerivAt (x : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 x) x := by
  have h : (cdf (gaussianReal 0 1) : ℝ → ℝ) = fun y =>
      cdf (gaussianReal 0 1) 0 + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; exact gaussCDF_eq_add y
  rw [h]
  exact (gaussPDF_continuous.integral_hasStrictDerivAt 0 x).hasDerivAt.const_add _

lemma gaussCDF_pos (x : ℝ) : 0 < cdf (gaussianReal 0 1) x := by
  have h1 := gaussCDF_eq_add x
  have h2 := gaussCDF_eq_add (x - 1)
  have h3 : 0 < ∫ t in (x - 1)..x, gaussianPDFReal 0 1 t :=
    intervalIntegral.intervalIntegral_pos_of_pos
      (gaussPDF_continuous.intervalIntegrable _ _)
      (fun t => gaussianPDFReal_pos 0 1 t one_ne_zero) (by linarith)
  have h4 := intervalIntegral.integral_add_adjacent_intervals
    (gaussPDF_continuous.intervalIntegrable (μ := volume) 0 (x - 1))
    (gaussPDF_continuous.intervalIntegrable (x - 1) x)
  have h5 := cdf_nonneg (gaussianReal 0 1) (x - 1)
  linarith

lemma gaussCDF_neg (x : ℝ) :
    cdf (gaussianReal 0 1) (-x) = 1 - cdf (gaussianReal 0 1) x := by
  have hmap : (gaussianReal 0 1).map (fun y : ℝ => -y) = gaussianReal 0 1 := by
    simpa using gaussianReal_map_neg (μ := (0 : ℝ)) (v := 1)
  have := nullSingletonClass_gaussianReal (μ := (0 : ℝ)) (v := 1) one_ne_zero
  rw [cdf_eq_real, cdf_eq_real]
  conv_lhs => rw [← hmap]
  rw [map_measureReal_apply measurable_neg measurableSet_Iic]
  have : (fun y : ℝ => -y) ⁻¹' Set.Iic (-x) = (Set.Iio x)ᶜ := by
    ext y; simp
  rw [this, probReal_compl_eq_one_sub measurableSet_Iio, measureReal_congr Iio_ae_eq_Iic]

/-- The density identity `D e^(-rT) φ(d2) = V φ(d1)`. -/
lemma pdf_d2_eq (V D σ r T : ℝ) (hV : 0 < V) (hD : 0 < D) (hσ : 0 < σ) (hT : 0 < T) :
    D * exp (-(r * T)) * gaussianPDFReal 0 1 (d2 V D σ r T) =
      V * gaussianPDFReal 0 1 (d1 V D σ r T) := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  have hs : σ * √T ≠ 0 := by positivity
  have hs2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, sq_sqrt hT.le]
  have hd1s : d1 V D σ r T * (σ * √T) = log (V / D) + (r + σ ^ 2 / 2) * T := by
    unfold d1; field_simp
  have hexp : -(d2 V D σ r T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(d1 V D σ r T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log (V / D) + r * T := by
    unfold d2; push_cast
    linear_combination hd1s - hs2 / 2
  unfold gaussianPDFReal
  rw [hexp, exp_add, exp_add, exp_log (div_pos hV hD)]
  have he : exp (-(r * T)) * exp (r * T) = 1 := by rw [← exp_add]; simp
  field_simp
  exact he

lemma debt_eq (V D σ r T : ℝ) :
    debt V D σ r T = V * cdf (gaussianReal 0 1) (-d1 V D σ r T) +
      D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T) := by
  unfold debt equity; rw [gaussCDF_neg]; ring

lemma debt_pos (V D σ r T : ℝ) (hV : 0 < V) (hD : 0 < D) : 0 < debt V D σ r T := by
  rw [debt_eq]
  have h1 := gaussCDF_pos (-d1 V D σ r T)
  have h2 := cdf_nonneg (gaussianReal 0 1) (d2 V D σ r T)
  positivity

#print axioms gaussPDF_continuous
#print axioms gaussCDF_eq_integral
#print axioms gaussCDF_eq_add
#print axioms gaussCDF_hasDerivAt
#print axioms gaussCDF_pos
#print axioms gaussCDF_neg
#print axioms pdf_d2_eq
#print axioms debt_eq
#print axioms debt_pos

/-- Volatility helps shareholders and hurts lenders (the formula): with positive assets, face,
volatility and time, the equity's slope against volatility is `V φ(d1) √T`, the debt's slope is
exactly minus that, and it is positive; against the assets, the equity's slope is `N(d1)` and
the debt's is `N(-d1)`. -/
theorem volatility_moves_value_from_lenders_to_shareholders
    (V D σ r T : ℝ) (hV : 0 < V) (hD : 0 < D) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s : ℝ => equity V D s r T)
        (V * gaussianPDFReal 0 1 (d1 V D σ r T) * √T) σ ∧
      HasDerivAt (fun s : ℝ => debt V D s r T)
        (-(V * gaussianPDFReal 0 1 (d1 V D σ r T) * √T)) σ ∧
      0 < V * gaussianPDFReal 0 1 (d1 V D σ r T) * √T ∧
      HasDerivAt (fun v : ℝ => equity v D σ r T) (cdf (gaussianReal 0 1) (d1 V D σ r T)) V ∧
      HasDerivAt (fun v : ℝ => debt v D σ r T) (cdf (gaussianReal 0 1) (-d1 V D σ r T)) V := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  have hkey := pdf_d2_eq V D σ r T hV hD hσ hT
  -- volatility
  obtain ⟨a, ha⟩ : ∃ a, HasDerivAt (fun s : ℝ => d1 V D s r T) a σ := by
    refine ⟨_, DifferentiableAt.hasDerivAt ?_⟩
    unfold d1; fun_prop (disch := positivity)
  have hb : HasDerivAt (fun s : ℝ => d2 V D s r T) (a - 1 * √T) σ := by
    unfold d2; exact ha.sub ((hasDerivAt_id' σ).mul_const √T)
  have hEσ : HasDerivAt (fun s : ℝ => equity V D s r T)
      (V * gaussianPDFReal 0 1 (d1 V D σ r T) * √T) σ := by
    have h := (((gaussCDF_hasDerivAt _).comp σ ha).const_mul V).sub
      (((gaussCDF_hasDerivAt _).comp σ hb).const_mul (D * exp (-(r * T))))
    refine (show HasDerivAt (fun s : ℝ => equity V D s r T) _ σ from h).congr_deriv ?_
    linear_combination (-(a - 1 * √T)) * hkey
  -- assets
  obtain ⟨a', ha'⟩ : ∃ a, HasDerivAt (fun v : ℝ => d1 v D σ r T) a V := by
    refine ⟨_, DifferentiableAt.hasDerivAt ?_⟩
    unfold d1; fun_prop (disch := positivity)
  have hb' : HasDerivAt (fun v : ℝ => d2 v D σ r T) a' V := by
    unfold d2; exact ha'.sub_const _
  have hEV : HasDerivAt (fun v : ℝ => equity v D σ r T) (cdf (gaussianReal 0 1) (d1 V D σ r T)) V := by
    have h := ((hasDerivAt_id' V).mul ((gaussCDF_hasDerivAt _).comp V ha')).sub
      (((gaussCDF_hasDerivAt _).comp V hb').const_mul (D * exp (-(r * T))))
    refine (show HasDerivAt (fun v : ℝ => equity v D σ r T) _ V from h).congr_deriv ?_
    try simp only [Function.comp_apply]
    linear_combination (-a') * hkey
  refine ⟨hEσ, ?_, ?_, hEV, ?_⟩
  · exact (show HasDerivAt (fun s : ℝ => V - equity V D s r T) _ σ from hEσ.const_sub V)
  · have := gaussianPDFReal_pos 0 1 (d1 V D σ r T) one_ne_zero
    positivity
  · have h := (hasDerivAt_id' V).sub hEV
    refine (show HasDerivAt (fun v : ℝ => v - equity v D σ r T) _ V from h).congr_deriv ?_
    rw [gaussCDF_neg]

/-- The equity's other slopes (Step 1): with positive assets, face, volatility and time, the
equity's slope against the face is `-e^(-rT) N(d2)`, against time it is
`V φ(d1) σ / (2 √T) + r D e^(-rT) N(d2)`, and against the rate it is `T D e^(-rT) N(d2)`;
the debt's slope against each of these is exactly minus the equity's. -/
theorem equity_slopes_in_face_time_and_rate
    (V D σ r T : ℝ) (hV : 0 < V) (hD : 0 < D) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun k : ℝ => equity V k σ r T)
        (-(exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T))) D ∧
      HasDerivAt (fun k : ℝ => debt V k σ r T)
        (exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T)) D ∧
      HasDerivAt (fun t : ℝ => equity V D σ r t)
        (V * gaussianPDFReal 0 1 (d1 V D σ r T) * σ / (2 * √T) +
          r * D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T)) T ∧
      HasDerivAt (fun t : ℝ => debt V D σ r t)
        (-(V * gaussianPDFReal 0 1 (d1 V D σ r T) * σ / (2 * √T) +
          r * D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T))) T ∧
      HasDerivAt (fun ρ : ℝ => equity V D σ ρ T)
        (T * D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T)) r ∧
      HasDerivAt (fun ρ : ℝ => debt V D σ ρ T)
        (-(T * D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T))) r := by
  have hsT : 0 < √T := sqrt_pos.2 hT
  have hkey := pdf_d2_eq V D σ r T hV hD hσ hT
  -- face
  obtain ⟨a, ha⟩ : ∃ a, HasDerivAt (fun k : ℝ => d1 V k σ r T) a D := by
    refine ⟨_, DifferentiableAt.hasDerivAt ?_⟩
    unfold d1; fun_prop (disch := positivity)
  have hb : HasDerivAt (fun k : ℝ => d2 V k σ r T) a D := by
    unfold d2; exact ha.sub_const _
  have hED : HasDerivAt (fun k : ℝ => equity V k σ r T)
      (-(exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T))) D := by
    have h := (((gaussCDF_hasDerivAt _).comp D ha).const_mul V).sub
      (((hasDerivAt_id' D).mul_const (exp (-(r * T)))).mul ((gaussCDF_hasDerivAt _).comp D hb))
    refine (show HasDerivAt (fun k : ℝ => equity V k σ r T) _ D from h).congr_deriv ?_
    try simp only [Function.comp_apply]
    linear_combination (-a) * hkey
  -- time
  obtain ⟨c, hc⟩ : ∃ a, HasDerivAt (fun t : ℝ => d1 V D σ r t) a T := by
    refine ⟨_, DifferentiableAt.hasDerivAt ?_⟩
    unfold d1; fun_prop (disch := positivity)
  have hc2 : HasDerivAt (fun t : ℝ => d2 V D σ r t) (c - σ * (1 / (2 * √T))) T := by
    unfold d2; exact hc.sub ((hasDerivAt_sqrt hT.ne').const_mul σ)
  have hexpT : HasDerivAt (fun t : ℝ => exp (-(r * t))) (exp (-(r * T)) * -(r * 1)) T :=
    ((hasDerivAt_id' T).const_mul r).neg.exp
  have hET : HasDerivAt (fun t : ℝ => equity V D σ r t)
      (V * gaussianPDFReal 0 1 (d1 V D σ r T) * σ / (2 * √T) +
        r * D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T)) T := by
    have h := (((gaussCDF_hasDerivAt _).comp T hc).const_mul V).sub
      ((hexpT.const_mul D).mul ((gaussCDF_hasDerivAt _).comp T hc2))
    refine (show HasDerivAt (fun t : ℝ => equity V D σ r t) _ T from h).congr_deriv ?_
    try simp only [Function.comp_apply]
    linear_combination (-(c - σ * (1 / (2 * √T)))) * hkey
  -- rate
  obtain ⟨e, he⟩ : ∃ a, HasDerivAt (fun ρ : ℝ => d1 V D σ ρ T) a r := by
    refine ⟨_, DifferentiableAt.hasDerivAt ?_⟩
    unfold d1; fun_prop (disch := positivity)
  have he2 : HasDerivAt (fun ρ : ℝ => d2 V D σ ρ T) e r := by
    unfold d2; exact he.sub_const _
  have hexpr : HasDerivAt (fun ρ : ℝ => exp (-(ρ * T))) (exp (-(r * T)) * -(1 * T)) r :=
    ((hasDerivAt_id' r).mul_const T).neg.exp
  have hEr : HasDerivAt (fun ρ : ℝ => equity V D σ ρ T)
      (T * D * exp (-(r * T)) * cdf (gaussianReal 0 1) (d2 V D σ r T)) r := by
    have h := (((gaussCDF_hasDerivAt _).comp r he).const_mul V).sub
      ((hexpr.const_mul D).mul ((gaussCDF_hasDerivAt _).comp r he2))
    refine (show HasDerivAt (fun ρ : ℝ => equity V D σ ρ T) _ r from h).congr_deriv ?_
    try simp only [Function.comp_apply]
    linear_combination (-e) * hkey
  refine ⟨hED, ?_, hET, ?_, hEr, ?_⟩
  · refine (show HasDerivAt (fun k : ℝ => V - equity V k σ r T) _ D from
      hED.const_sub V).congr_deriv ?_
    ring
  · exact (show HasDerivAt (fun t : ℝ => V - equity V D σ r t) _ T from hET.const_sub V)
  · exact (show HasDerivAt (fun ρ : ℝ => V - equity V D σ ρ T) _ r from hEr.const_sub V)

/-- Leverage widens the spread (Step 4): with positive assets, face, volatility and time,
scaling the assets and the face by the same positive factor leaves the spread unchanged, so the
spread depends on them only through the leverage `D e^(-rT) / V`; and with the assets held
still, a larger face of debt gives a strictly wider spread. -/
theorem spread_depends_only_on_leverage_and_rises_with_face
    (V D σ r T : ℝ) (hV : 0 < V) (hD : 0 < D) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ c : ℝ, 0 < c → spread (c * V) (c * D) σ r T = spread V D σ r T) ∧
      StrictMonoOn (fun k : ℝ => spread V k σ r T) (Set.Ioi 0) := by
  refine ⟨fun c hc => ?_, ?_⟩
  · have h1 : d1 (c * V) (c * D) σ r T = d1 V D σ r T := by
      unfold d1; rw [mul_div_mul_left _ _ hc.ne']
    have h2 : d2 (c * V) (c * D) σ r T = d2 V D σ r T := by
      unfold d2; rw [h1]
    have h3 : debt (c * V) (c * D) σ r T / (c * D) = debt V D σ r T / D := by
      unfold debt equity; rw [h1, h2]; field_simp
    unfold spread; rw [h3]
  · -- the debt per dollar of face falls as the face rises
    have hg : ∀ k ∈ Set.Ioi (0 : ℝ), HasDerivAt (fun k : ℝ => debt V k σ r T / k)
        (-(V * cdf (gaussianReal 0 1) (-d1 V k σ r T)) / k ^ 2) k := by
      intro k hk
      have hk : (0 : ℝ) < k := hk
      have h := ((equity_slopes_in_face_time_and_rate V k σ r T hV hk hσ hT).2.1).div
        (hasDerivAt_id' k) hk.ne'
      refine h.congr_deriv ?_
      rw [debt_eq]; field_simp; ring
    have hanti : StrictAntiOn (fun k : ℝ => debt V k σ r T / k) (Set.Ioi 0) := by
      refine strictAntiOn_of_deriv_neg (convex_Ioi 0)
        (fun x hx => (hg x hx).continuousAt.continuousWithinAt) ?_
      intro x hx
      rw [interior_Ioi] at hx
      have hx' : (0 : ℝ) < x := hx
      rw [(hg x hx).deriv]
      have := gaussCDF_pos (-d1 V x σ r T)
      have : 0 < V * cdf (gaussianReal 0 1) (-d1 V x σ r T) := by positivity
      apply div_neg_of_neg_of_pos (by linarith) (by positivity)
    intro k₁ hk₁ k₂ hk₂ hlt
    have hk₁' : (0 : ℝ) < k₁ := hk₁
    have hk₂' : (0 : ℝ) < k₂ := hk₂
    have hpos : 0 < debt V k₂ σ r T / k₂ := div_pos (debt_pos V k₂ σ r T hV hk₂') hk₂'
    have hlog : log (debt V k₂ σ r T / k₂) < log (debt V k₁ σ r T / k₁) :=
      log_lt_log hpos (hanti hk₁ hk₂ hlt)
    show -log (debt V k₁ σ r T / k₁) / T - r < -log (debt V k₂ σ r T / k₂) / T - r
    have := div_lt_div_of_pos_right (show -log (debt V k₁ σ r T / k₁) < -log (debt V k₂ σ r T / k₂) by linarith) hT
    linarith

/-! The card's exact whole-number checks. -/

-- Assets $90m with face $80m and assets $100m with face $800/9m have the same leverage.
example : (80 : ℚ) / 90 = (800 / 9) / 100 := by norm_num

-- The base firm's d1 - d2 = σ √T is 0.20 when σ = 0.20 and T = 1.
example : (1 / 5 : ℝ) * √1 = 1 / 5 := by norm_num

#print axioms volatility_moves_value_from_lenders_to_shareholders
#print axioms equity_slopes_in_face_time_and_rate
#print axioms spread_depends_only_on_leverage_and_rises_with_face

end StructuralSensitivities
