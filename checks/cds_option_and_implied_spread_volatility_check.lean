-- Options on a CDS: Black's payer premium on the forward spread, in units of the forward risky annuity, has exactly one implied spread volatility when the premium lies strictly between A(F - K)⁺ and A F, payer minus receiver is A(F - K), and the survival-measure change of unit removes the random annuity.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib

open Real ProbabilityTheory MeasureTheory

/-- The standard normal distribution function `N(x)`: the area under the bell curve left of `x`. -/
local notation "Φ" => cdf (gaussianReal 0 1)

/-- Black's first cut-off on a forward spread: `d₁ = (ln(F/K) + σ² T / 2) / (σ √T)`;
the second is `d₂ = d₁ - σ √T`. -/
noncomputable def blackD1 (F K T σ : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 / 2 * T) / (σ * √T)

/-- The knock-out payer CDS option: the forward risky annuity `A` times Black's call on the
forward spread `F` struck at `K`, `V_pay = A [F N(d₁) - K N(d₂)]`. -/
noncomputable def cdsPayer (A F K T σ : ℝ) : ℝ :=
  A * (F * Φ (blackD1 F K T σ) - K * Φ (blackD1 F K T σ - σ * √T))

/-- The knock-out receiver CDS option: `V_rec = A [K N(-d₂) - F N(-d₁)]`. -/
noncomputable def cdsReceiver (A F K T σ : ℝ) : ℝ :=
  A * (K * Φ (σ * √T - blackD1 F K T σ) - F * Φ (-blackD1 F K T σ))

open Filter Topology Set

lemma stdPDF_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma stdCDF_eq_integral (x : ℝ) : Φ x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma stdCDF_eq_add (x : ℝ) : Φ x = Φ 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
  rw [← intervalIntegral.integral_Iic_sub_Iic, stdCDF_eq_integral, stdCDF_eq_integral]
  · ring
  · exact (integrable_gaussianPDFReal _ _).integrableOn
  · exact (integrable_gaussianPDFReal _ _).integrableOn

lemma stdCDF_hasDerivAt (x : ℝ) : HasDerivAt Φ (gaussianPDFReal 0 1 x) x := by
  have h := (stdPDF_continuous.integral_hasStrictDerivAt 0 x).hasDerivAt.const_add (Φ 0)
  have he : Φ = fun y => Φ 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := funext stdCDF_eq_add
  rw [he]; exact h

lemma stdCDF_continuous : Continuous Φ :=
  continuous_iff_continuousAt.2 fun x => (stdCDF_hasDerivAt x).continuousAt

lemma stdCDF_neg (x : ℝ) : Φ (-x) = 1 - Φ x := by
  have hns := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [cdf_eq_real, cdf_eq_real]
  have h1 : (gaussianReal 0 1).real (Iic (-x)) = (gaussianReal 0 1).real (Ici x) := by
    conv_lhs => rw [← neg_zero, ← gaussianReal_map_neg]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1; ext t; simp
  have h2 : (gaussianReal 0 1).real (Ici x) = 1 - (gaussianReal 0 1).real (Iio x) := by
    rw [← compl_Iio, probReal_compl_eq_one_sub measurableSet_Iio]
  rw [h1, h2, measureReal_congr Iio_ae_eq_Iic]

lemma existsUnique_iff_of_strictMonoOn (f : ℝ → ℝ) (a b y : ℝ)
    (hmono : StrictMonoOn f (Ioi 0)) (hcont : ContinuousOn f (Ioi 0))
    (h0 : Tendsto f (𝓝[>] 0) (𝓝 a)) (htop : Tendsto f atTop (𝓝 b)) :
    (∃! σ : ℝ, 0 < σ ∧ f σ = y) ↔ a < y ∧ y < b := by
  constructor
  · rintro ⟨σ, ⟨hσ, rfl⟩, -⟩
    have h2 : (0:ℝ) < σ / 2 := half_pos hσ
    constructor
    · have h1 : a ≤ f (σ / 2) := by
        apply le_of_tendsto h0
        filter_upwards [Ioo_mem_nhdsGT h2] with t ht
        exact (hmono ht.1 h2 ht.2).le
      exact h1.trans_lt (hmono h2 hσ (half_lt_self hσ))
    · have h3 : (0:ℝ) < 2 * σ := by positivity
      have h1 : f (2 * σ) ≤ b := by
        apply ge_of_tendsto htop
        filter_upwards [eventually_ge_atTop (2 * σ)] with t ht
        exact hmono.monotoneOn h3 (lt_of_lt_of_le h3 ht) ht
      exact (hmono hσ h3 (by linarith)).trans_le h1
  · rintro ⟨ha, hb⟩
    obtain ⟨t1, hft1, ht1⟩ :=
      ((h0.eventually (gt_mem_nhds ha)).and self_mem_nhdsWithin).exists
    obtain ⟨t2, hft2, ht12⟩ :=
      ((htop.eventually (lt_mem_nhds hb)).and (eventually_ge_atTop t1)).exists
    have ht1' : (0:ℝ) < t1 := ht1
    obtain ⟨σ, hσ, hfσ⟩ := intermediate_value_Icc ht12
      (hcont.mono fun x hx => lt_of_lt_of_le ht1' hx.1) ⟨hft1.le, hft2.le⟩
    have hσ0 : (0:ℝ) < σ := lt_of_lt_of_le ht1' hσ.1
    refine ⟨σ, ⟨hσ0, hfσ⟩, ?_⟩
    rintro τ ⟨hτ, hfτ⟩
    exact hmono.injOn hτ hσ0 (hfτ.trans hfσ.symm)

lemma blackD1_eq (F K T σ : ℝ) (hT : 0 < T) :
    blackD1 F K T σ = log (F / K) / √T * σ⁻¹ + √T / 2 * σ := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hsT : √T ^ 2 = T := sq_sqrt hT.le
  unfold blackD1
  generalize √T = s at *
  subst hsT
  rcases eq_or_ne σ 0 with rfl | hσ
  · simp
  · field_simp

lemma pdf_identity (F K T σ : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    F * gaussianPDFReal 0 1 (blackD1 F K T σ)
      = K * gaussianPDFReal 0 1 (blackD1 F K T σ - σ * √T) := by
  have hs : 0 < √T := sqrt_pos.2 hT
  have hsT : √T ^ 2 = T := sq_sqrt hT.le
  set d := blackD1 F K T σ with hd
  have hkey : σ * √T * d = log (F / K) + σ ^ 2 / 2 * T := by
    rw [hd, blackD1]; field_simp
  have hFK : F = K * exp (log (F / K)) := by
    rw [exp_log (div_pos hF hK)]; field_simp
  have he : -(d - σ * √T) ^ 2 / 2 = log (F / K) + -d ^ 2 / 2 := by
    linear_combination hkey - σ ^ 2 / 2 * hsT
  simp only [gaussianPDFReal, NNReal.coe_one, sub_zero, mul_one]
  rw [he, exp_add, exp_log (div_pos hF hK)]; field_simp

lemma payer_hasDerivAt (F K T σ : ℝ) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun σ => F * Φ (blackD1 F K T σ) - K * Φ (blackD1 F K T σ - σ * √T))
      (K * gaussianPDFReal 0 1 (blackD1 F K T σ - σ * √T) * √T) σ := by
  have hs : 0 < √T := sqrt_pos.2 hT
  set e : ℝ := log (F / K) / √T * (-(σ ^ 2)⁻¹) + √T / 2 with he
  have hd : HasDerivAt (fun σ => blackD1 F K T σ) e σ := by
    have := (((hasDerivAt_inv hσ.ne').const_mul (log (F / K) / √T)).add
      ((hasDerivAt_id σ).const_mul (√T / 2)))
    simp only [mul_one] at this
    convert this using 1
    funext x; simp [blackD1_eq F K T x hT]
  have h1 := (stdCDF_hasDerivAt (blackD1 F K T σ)).comp σ hd
  have h2 := (stdCDF_hasDerivAt (blackD1 F K T σ - σ * √T)).comp σ
    (hd.sub ((hasDerivAt_id σ).mul_const √T))
  convert (h1.const_mul F).sub (h2.const_mul K) using 1
  · funext x; rfl
  · have := pdf_identity F K T σ hF hK hT hσ
    linear_combination (-e) * this

#print axioms stdPDF_continuous
#print axioms stdCDF_eq_integral
#print axioms stdCDF_eq_add
#print axioms stdCDF_hasDerivAt
#print axioms stdCDF_continuous
#print axioms stdCDF_neg
#print axioms existsUnique_iff_of_strictMonoOn
#print axioms blackD1_eq
#print axioms pdf_identity
#print axioms payer_hasDerivAt

/-- **The implied spread volatility exists and is unique exactly inside Black's price range**
(Step 7). Fix a forward risky annuity `A > 0`, a forward spread `F > 0`, a strike spread `K > 0`
and an expiry `T > 0`, and take a quoted payer premium `V`. There is exactly one positive spread
volatility `σ` whose Black payer premium `A [F N(d₁) - K N(d₂)]` equals `V` if and only if
`A (F - K)⁺ < V < A F`. -/
theorem cds_implied_spread_volatility_exists_unique_iff (A F K T V : ℝ)
    (hA : 0 < A) (hF : 0 < F) (hK : 0 < K) (hT : 0 < T) :
    (∃! σ : ℝ, 0 < σ ∧ cdsPayer A F K T σ = V) ↔
      A * max (F - K) 0 < V ∧ V < A * F := by
  have hs : 0 < √T := sqrt_pos.2 hT
  set P : ℝ → ℝ := fun σ => F * Φ (blackD1 F K T σ) - K * Φ (blackD1 F K T σ - σ * √T) with hP
  have hpay : (fun σ => cdsPayer A F K T σ) = fun σ => A * P σ := rfl
  -- strict monotonicity and continuity
  have hcont : ContinuousOn P (Ioi 0) := fun x hx =>
    (payer_hasDerivAt F K T x hF hK hT hx).continuousAt.continuousWithinAt
  have hmono : StrictMonoOn P (Ioi 0) := by
    apply strictMonoOn_of_deriv_pos (convex_Ioi 0) hcont
    intro x hx
    rw [interior_Ioi] at hx
    rw [(payer_hasDerivAt F K T x hF hK hT hx).deriv]
    have := gaussianPDFReal_pos 0 1 (blackD1 F K T x - x * √T) one_ne_zero
    positivity
  -- the cut-offs as explicit functions
  set L := log (F / K) with hL
  set s := √T with hsdef
  have hd1f : (fun σ => blackD1 F K T σ) = fun σ => L / s * σ⁻¹ + s / 2 * σ :=
    funext fun σ => blackD1_eq F K T σ hT
  have hd2f : (fun σ => blackD1 F K T σ - σ * s) = fun σ => L / s * σ⁻¹ + (-(s / 2)) * σ :=
    funext fun σ => by rw [blackD1_eq F K T σ hT]; ring
  have hPeq : P = fun σ => F * Φ ((fun σ => blackD1 F K T σ) σ)
      - K * Φ ((fun σ => blackD1 F K T σ - σ * s) σ) := rfl
  -- limit at infinity
  have htop : Tendsto P atTop (𝓝 F) := by
    have hinv : Tendsto (fun σ : ℝ => L / s * σ⁻¹) atTop (𝓝 0) := by
      simpa using tendsto_inv_atTop_zero.const_mul (L / s)
    have h1 : Tendsto (fun σ => blackD1 F K T σ) atTop atTop := by
      rw [hd1f]; exact hinv.add_atTop (tendsto_id.const_mul_atTop (by positivity))
    have h2 : Tendsto (fun σ => blackD1 F K T σ - σ * s) atTop atBot := by
      rw [hd2f]
      exact hinv.add_atBot (tendsto_id.const_mul_atTop_of_neg (by linarith))
    have := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp h1).const_mul F).sub (((tendsto_cdf_atBot (gaussianReal 0 1)).comp h2).const_mul K)
    simpa using this
  -- limit at zero
  have hlin : ∀ c : ℝ, Tendsto (fun σ : ℝ => c * σ) (𝓝[>] 0) (𝓝 0) := fun c => by
    have : Tendsto (fun σ : ℝ => c * σ) (𝓝 0) (𝓝 (c * 0)) :=
      (continuous_const.mul continuous_id).tendsto 0
    rw [mul_zero] at this
    exact this.mono_left nhdsWithin_le_nhds
  have hzero : Tendsto P (𝓝[>] 0) (𝓝 (max (F - K) 0)) := by
    rcases lt_trichotomy F K with hlt | heq | hgt
    · have hLneg : L < 0 := log_neg (div_pos hF hK) ((div_lt_one hK).2 hlt)
      have hc : L / s < 0 := div_neg_of_neg_of_pos hLneg hs
      have hi := tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg hc
      have h1 : Tendsto (fun σ => blackD1 F K T σ) (𝓝[>] 0) atBot := by
        rw [hd1f]; exact hi.atBot_add (hlin _)
      have h2 : Tendsto (fun σ => blackD1 F K T σ - σ * s) (𝓝[>] 0) atBot := by
        rw [hd2f]; exact hi.atBot_add (hlin _)
      have := (((tendsto_cdf_atBot (gaussianReal 0 1)).comp h1).const_mul F).sub
        (((tendsto_cdf_atBot (gaussianReal 0 1)).comp h2).const_mul K)
      rw [max_eq_right (by linarith)]
      simpa using this
    · subst heq
      have hL0 : L = 0 := by rw [hL, div_self hF.ne', log_one]
      have h1 : Tendsto (fun σ => blackD1 F F T σ) (𝓝[>] 0) (𝓝 0) := by
        rw [hd1f, hL0]; simpa using hlin (s / 2)
      have h2 : Tendsto (fun σ => blackD1 F F T σ - σ * s) (𝓝[>] 0) (𝓝 0) := by
        rw [hd2f, hL0]; simpa using hlin (-(s / 2))
      have := (((stdCDF_continuous.tendsto 0).comp h1).const_mul F).sub
        (((stdCDF_continuous.tendsto 0).comp h2).const_mul F)
      simpa using this
    · have hLpos : 0 < L := log_pos ((one_lt_div hK).2 hgt)
      have hc : 0 < L / s := div_pos hLpos hs
      have hi := tendsto_inv_nhdsGT_zero.const_mul_atTop hc
      have h1 : Tendsto (fun σ => blackD1 F K T σ) (𝓝[>] 0) atTop := by
        rw [hd1f]; exact hi.atTop_add (hlin _)
      have h2 : Tendsto (fun σ => blackD1 F K T σ - σ * s) (𝓝[>] 0) atTop := by
        rw [hd2f]; exact hi.atTop_add (hlin _)
      have := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp h1).const_mul F).sub
        (((tendsto_cdf_atTop (gaussianReal 0 1)).comp h2).const_mul K)
      rw [max_eq_left (by linarith)]
      simpa using this
  exact existsUnique_iff_of_strictMonoOn (fun σ => A * P σ) _ _ V
    (fun x hx y hy hxy => mul_lt_mul_of_pos_left (hmono hx hy hxy) hA)
    (continuousOn_const.mul hcont) (hzero.const_mul A) (htop.const_mul A)

/-- **Payer-receiver parity** (Step 5). For every annuity, forward, strike, expiry and
volatility, the payer premium minus the receiver premium is `A (F - K)`, the value today of a
forward CDS struck at `K`. -/
theorem cds_payer_sub_receiver_eq (A F K T σ : ℝ) :
    cdsPayer A F K T σ - cdsReceiver A F K T σ = A * (F - K) := by
  unfold cdsPayer cdsReceiver
  have h1 := stdCDF_neg (blackD1 F K T σ)
  have h2 := stdCDF_neg (blackD1 F K T σ - σ * √T)
  rw [neg_sub] at h2
  rw [h1, h2]; ring

/-- **The survival measure: the change of unit that removes the random annuity** (Step 2, Step 4
and the detailed proof). Under a risk-neutral probability `μ`, let `D` be the positive discount
factor to expiry, `S` the event that the name survives to expiry, and `A_T` the risky annuity at
expiry, positive on survival. Today's forward risky annuity is `A = 𝔼[D 1_S A_T]`, assumed
positive. Then the weight `w = D 1_S A_T / A` defines a probability measure (the survival
measure), and every payoff `X` at expiry that is zero on default before expiry is priced as
`𝔼[D X] = A 𝔼^A[X / A_T]`. -/
theorem survival_measure_change_of_unit {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (D AT X : Ω → ℝ) (S : Set Ω)
    (hS : MeasurableSet S) (hD : Measurable D) (hAT : Measurable AT)
    (hDpos : ∀ ω, 0 < D ω) (hATpos : ∀ ω ∈ S, 0 < AT ω)
    (hint : Integrable (fun ω => D ω * S.indicator AT ω) μ)
    (hApos : 0 < ∫ ω, D ω * S.indicator AT ω ∂μ)
    (hX : ∀ ω ∉ S, X ω = 0) :
    let A := ∫ ω, D ω * S.indicator AT ω ∂μ
    let ν := μ.withDensity (fun ω => ENNReal.ofReal (D ω * S.indicator AT ω / A))
    IsProbabilityMeasure ν ∧ ∫ ω, D ω * X ω ∂μ = A * ∫ ω, X ω / AT ω ∂ν := by
  intro A ν
  have hg0 : ∀ ω, 0 ≤ D ω * S.indicator AT ω := by
    intro ω
    by_cases h : ω ∈ S
    · rw [indicator_of_mem h]; exact mul_nonneg (hDpos ω).le (hATpos ω h).le
    · rw [indicator_of_notMem h, mul_zero]
  have hA : 0 < A := hApos
  have hmeas : Measurable (fun ω => ENNReal.ofReal (D ω * S.indicator AT ω / A)) := by
    apply ENNReal.measurable_ofReal.comp
    exact (hD.mul (hAT.indicator hS)).div_const _
  refine ⟨⟨?_⟩, ?_⟩
  · show μ.withDensity _ univ = 1
    rw [withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ,
      ← ofReal_integral_eq_lintegral_ofReal (hint.div_const A)
        (ae_of_all _ fun ω => div_nonneg (hg0 ω) hA.le), integral_div]
    simp [A, hA.ne']
  · show _ = A * ∫ ω, X ω / AT ω ∂(μ.withDensity _)
    rw [integral_withDensity_eq_integral_toReal_smul hmeas (ae_of_all _ fun _ => ENNReal.ofReal_lt_top)]
    have hpt : ∀ ω, (ENNReal.ofReal (D ω * S.indicator AT ω / A)).toReal • (X ω / AT ω)
        = D ω * X ω / A := by
      intro ω
      rw [ENNReal.toReal_ofReal (div_nonneg (hg0 ω) hA.le), smul_eq_mul]
      by_cases h : ω ∈ S
      · rw [indicator_of_mem h]
        have := (hATpos ω h).ne'
        field_simp
      · rw [indicator_of_notMem h, hX ω h]; simp
    simp_rw [hpt, integral_div]
    field_simp

/-! Worked numbers from the card, as exact fractions of the printed decimals. -/

-- Half variance: ½ × 0.5² × 1 = 0.125.
example : (1 / 2 : ℚ) * (1 / 2) ^ 2 * 1 = 1 / 8 := by norm_num
-- d₁ = (0.150308 + 0.125) / 0.5 = 0.550616.
example : ((150308 : ℚ) / 10 ^ 6 + 1 / 8) / (1 / 2) = 550616 / 10 ^ 6 := by norm_num
-- d₂ = d₁ - σ √T = 0.550616 - 0.5 = 0.050616.
example : (550616 : ℚ) / 10 ^ 6 - 1 / 2 = 50616 / 10 ^ 6 := by norm_num
-- Payer that keeps the front-end protection: 2.332014 + 1.120398 = 3.452412 percent.
example : (2332014 : ℚ) / 10 ^ 6 + 1120398 / 10 ^ 6 = 3452412 / 10 ^ 6 := by norm_num
-- The premium 2.332014 percent lies inside Black's range, 1.244724 to 8.919113 percent.
example : (1244724 : ℚ) / 10 ^ 6 < 2332014 / 10 ^ 6 ∧ (2332014 : ℚ) / 10 ^ 6 < 8919113 / 10 ^ 6 := by
  norm_num
-- A premium of 1.20 percent is below the floor 1.244724 percent, so it has no volatility.
example : (120 : ℚ) / 100 < 1244724 / 10 ^ 6 := by norm_num

#print axioms cds_implied_spread_volatility_exists_unique_iff
#print axioms cds_payer_sub_receiver_eq
#print axioms survival_measure_change_of_unit
