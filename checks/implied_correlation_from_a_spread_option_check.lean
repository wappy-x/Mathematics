-- Correlation from a spread option: Margrabe's spread-option price falls strictly as the correlation rises from -1 to 1, so a quote is matched by exactly one correlation in [-1, 1] when it lies between the prices at +1 and -1 and by none otherwise, and the two-step route through the gap's volatility gives that correlation as (σ₁² + σ₂² - σ_imp²) / (2 σ₁ σ₂).
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open ProbabilityTheory

namespace SpreadImpliedCorrelation

/-- The standard normal distribution function `N(x)`: the bell-curve area left of `x`. -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The gap's volatility `σ(ρ) = √(σ₁² + σ₂² - 2 ρ σ₁ σ₂)`: the volatility of the ratio
gasoline over crude when the legs have volatilities `σ₁`, `σ₂` and correlation `ρ`. -/
noncomputable def gapVol (σ₁ σ₂ ρ : ℝ) : ℝ :=
  Real.sqrt (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)

/-- Black's futures-option formula on the ratio, as a function of the total swing `w = σ √T`:
`B(w) = D [F₁ N(d₁) - F₂ N(d₂)]` with `d₁ = ln(F₁/F₂)/w + w/2` and `d₂ = d₁ - w`.
At `w = 0` it is the limit `D (F₁ - F₂)⁺`, as the card defines it. -/
noncomputable def blackOnRatio (D F₁ F₂ w : ℝ) : ℝ :=
  if w = 0 then D * max (F₁ - F₂) 0
  else D * (F₁ * N (Real.log (F₁ / F₂) / w + w / 2) - F₂ * N (Real.log (F₁ / F₂) / w - w / 2))

/-- Margrabe's zero-strike spread-option price `C(ρ) = D [F₁ N(d₁) - F₂ N(d₂)]` with discount
factor `D = e^{-rT}` and the gap's volatility `σ(ρ)`. -/
noncomputable def margrabe (F₁ F₂ σ₁ σ₂ r T ρ : ℝ) : ℝ :=
  blackOnRatio (Real.exp (-r * T)) F₁ F₂ (gapVol σ₁ σ₂ ρ * Real.sqrt T)


/-! ### Helper lemmas -/

lemma pdf_eq (x : ℝ) :
    gaussianPDFReal 0 1 x = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma pdf_continuous : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun x => (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-x ^ 2 / 2) :=
    funext pdf_eq
  rw [this]; fun_prop

lemma N_eq_integral (x : ℝ) : N x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [N, cdf_eq_real, MeasureTheory.measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact MeasureTheory.setIntegral_nonneg measurableSet_Iic
    (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma N_eq_add (x : ℝ) : N x = N 0 + ∫ t in (0 : ℝ)..x, gaussianPDFReal 0 1 t := by
  rw [N_eq_integral, N_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic
    (integrable_gaussianPDFReal 0 1).integrableOn (integrable_gaussianPDFReal 0 1).integrableOn]
  ring

lemma hasDerivAt_N (x : ℝ) : HasDerivAt N (gaussianPDFReal 0 1 x) x := by
  have h := (pdf_continuous.integral_hasStrictDerivAt 0 x).hasDerivAt.const_add (N 0)
  exact h.congr_of_eventuallyEq (Filter.Eventually.of_forall N_eq_add)

lemma N_continuous : Continuous N :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_N x).continuousAt

lemma key_identity (a F₁ F₂ w : ℝ) (hF₂ : 0 < F₂) (ha : Real.exp a = F₁ / F₂) (hw : w ≠ 0) :
    F₂ * gaussianPDFReal 0 1 (a / w - w / 2) = F₁ * gaussianPDFReal 0 1 (a / w + w / 2) := by
  have hc : a / w * w = a := div_mul_cancel₀ a hw
  have h2 : -(a / w - w / 2) ^ 2 / 2 = -(a / w + w / 2) ^ 2 / 2 + a := by
    linear_combination hc
  rw [pdf_eq, pdf_eq, h2, Real.exp_add, ha]
  field_simp

lemma hasDerivAt_black (D F₁ F₂ w : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hw : 0 < w) :
    HasDerivAt (blackOnRatio D F₁ F₂)
      (D * F₁ * gaussianPDFReal 0 1 (Real.log (F₁ / F₂) / w + w / 2)) w := by
  have hexp : Real.exp (Real.log (F₁ / F₂)) = F₁ / F₂ := Real.exp_log (div_pos hF₁ hF₂)
  have heq : blackOnRatio D F₁ F₂ =ᶠ[nhds w] fun y =>
      D * (F₁ * N (Real.log (F₁ / F₂) / y + y / 2) - F₂ * N (Real.log (F₁ / F₂) / y - y / 2)) :=
    (lt_mem_nhds hw).mono fun y hy => by rw [blackOnRatio, if_neg hy.ne']
  refine HasDerivAt.congr_of_eventuallyEq ?_ heq
  generalize Real.log (F₁ / F₂) = a at hexp ⊢
  have hw0 : w ≠ 0 := hw.ne'
  have hinv : HasDerivAt (fun y : ℝ => a / y) ((-a / w ^ 2 : ℝ)) w := by
    have := (hasDerivAt_inv hw0).const_mul a
    convert this using 1
    · funext y; ring
    · ring
  have hd1 : HasDerivAt (fun y : ℝ => a / y + y / 2) ((-a / w ^ 2 + 1 / 2 : ℝ)) w :=
    hinv.add ((hasDerivAt_id' w).div_const 2)
  have hd2 : HasDerivAt (fun y : ℝ => a / y - y / 2) ((-a / w ^ 2 - 1 / 2 : ℝ)) w :=
    hinv.sub ((hasDerivAt_id' w).div_const 2)
  have hN1 := (hasDerivAt_N (a / w + w / 2)).comp w hd1
  have hN2 := (hasDerivAt_N (a / w - w / 2)).comp w hd2
  have hg := ((hN1.const_mul F₁).sub (hN2.const_mul F₂)).const_mul D
  have k := key_identity a F₁ F₂ w hF₂ hexp hw0
  convert hg using 1
  · rfl
  · linear_combination (D * (-a / w ^ 2 - 1 / 2)) * k

lemma black_continuousOn (D F₁ F₂ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) :
    ContinuousOn (blackOnRatio D F₁ F₂) (Set.Ici 0) := by
  intro x hx
  rcases (Set.mem_Ici.1 hx).eq_or_lt with h | h
  · subst h
    rw [← continuousWithinAt_Ioi_iff_Ici, ContinuousWithinAt]
    have heq : (fun y =>
        D * (F₁ * N (Real.log (F₁ / F₂) / y + y / 2) - F₂ * N (Real.log (F₁ / F₂) / y - y / 2)))
          =ᶠ[nhdsWithin 0 (Set.Ioi 0)] blackOnRatio D F₁ F₂ :=
      eventually_nhdsWithin_of_forall fun y hy => by rw [blackOnRatio, if_neg (ne_of_gt hy)]
    refine Filter.Tendsto.congr' heq ?_
    have h0 : blackOnRatio D F₁ F₂ 0 = D * max (F₁ - F₂) 0 := by simp [blackOnRatio]
    rw [h0]
    have hexp : Real.exp (Real.log (F₁ / F₂)) = F₁ / F₂ := Real.exp_log (div_pos hF₁ hF₂)
    generalize Real.log (F₁ / F₂) = a at hexp ⊢
    have hx2 : Filter.Tendsto (fun x : ℝ => x / 2) (nhdsWithin 0 (Set.Ioi 0)) (nhds 0) := by
      have : Filter.Tendsto (fun x : ℝ => x / 2) (nhds 0) (nhds (0 / 2)) :=
        (continuous_id.div_const 2).tendsto 0
      simpa using this.mono_left nhdsWithin_le_nhds
    rcases lt_trichotomy a 0 with ha | ha | ha
    · have hlt : F₁ < F₂ := by
        have : F₁ / F₂ < 1 := by rw [← hexp]; exact Real.exp_lt_one_iff.2 ha
        rwa [div_lt_one hF₂] at this
      have hinf : Filter.Tendsto (fun x : ℝ => a / x) (nhdsWithin 0 (Set.Ioi 0)) Filter.atBot := by
        have := tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg ha
        simpa [div_eq_mul_inv] using this
      have h1 : Filter.Tendsto (fun x : ℝ => a / x + x / 2) (nhdsWithin 0 (Set.Ioi 0))
          Filter.atBot := hinf.atBot_add hx2
      have h2 : Filter.Tendsto (fun x : ℝ => a / x - x / 2) (nhdsWithin 0 (Set.Ioi 0))
          Filter.atBot := by
        simpa only [sub_eq_add_neg] using
          hinf.atBot_add (hx2.neg (f := fun x : ℝ => x / 2))
      have hN : Filter.Tendsto N Filter.atBot (nhds 0) := tendsto_cdf_atBot (gaussianReal 0 1)
      have := (((hN.comp h1).const_mul F₁).sub ((hN.comp h2).const_mul F₂)).const_mul D
      rw [show D * max (F₁ - F₂) 0 = D * (F₁ * 0 - F₂ * 0) by
        rw [max_eq_right (by linarith)]; ring]
      exact this
    · subst ha
      have hF : F₁ = F₂ := by
        rw [Real.exp_zero, eq_div_iff hF₂.ne'] at hexp; linarith
      have hc : Continuous (fun x : ℝ => D * (F₁ * N (x / 2) - F₂ * N (-(x / 2)))) := by
        have := N_continuous
        fun_prop
      have := (hc.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
      rw [show D * max (F₁ - F₂) 0 = D * (F₁ * N (0 / 2) - F₂ * N (-(0 / 2))) by
        rw [hF]; simp]
      simpa [zero_div, neg_div] using this
    · have hlt : F₂ < F₁ := by
        have : 1 < F₁ / F₂ := by rw [← hexp]; exact Real.one_lt_exp_iff.2 ha
        rwa [one_lt_div hF₂] at this
      have hinf : Filter.Tendsto (fun x : ℝ => a / x) (nhdsWithin 0 (Set.Ioi 0)) Filter.atTop := by
        have := tendsto_inv_nhdsGT_zero.const_mul_atTop ha
        simpa [div_eq_mul_inv] using this
      have h1 : Filter.Tendsto (fun x : ℝ => a / x + x / 2) (nhdsWithin 0 (Set.Ioi 0))
          Filter.atTop := hinf.atTop_add hx2
      have h2 : Filter.Tendsto (fun x : ℝ => a / x - x / 2) (nhdsWithin 0 (Set.Ioi 0))
          Filter.atTop := by
        simpa only [sub_eq_add_neg] using
          hinf.atTop_add (hx2.neg (f := fun x : ℝ => x / 2))
      have hN : Filter.Tendsto N Filter.atTop (nhds 1) := tendsto_cdf_atTop (gaussianReal 0 1)
      have := (((hN.comp h1).const_mul F₁).sub ((hN.comp h2).const_mul F₂)).const_mul D
      rw [show D * max (F₁ - F₂) 0 = D * (F₁ * 1 - F₂ * 1) by
        rw [max_eq_left (by linarith)]; ring]
      exact this
  · exact (hasDerivAt_black D F₁ F₂ x hF₁ hF₂ h).continuousAt.continuousWithinAt

lemma black_strictMonoOn (D F₁ F₂ : ℝ) (hD : 0 < D) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) :
    StrictMonoOn (blackOnRatio D F₁ F₂) (Set.Ici 0) := by
  apply strictMonoOn_of_deriv_pos (convex_Ici 0) (black_continuousOn D F₁ F₂ hF₁ hF₂)
  intro x hx
  rw [interior_Ici] at hx
  rw [(hasDerivAt_black D F₁ F₂ x hF₁ hF₂ hx).deriv]
  exact mul_pos (mul_pos hD hF₁) (gaussianPDFReal_pos _ _ _ one_ne_zero)

lemma swing_strictAntiOn (σ₁ σ₂ T : ℝ) (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) (hT : 0 < T) :
    StrictAntiOn (fun ρ => gapVol σ₁ σ₂ ρ * Real.sqrt T) (Set.Icc (-1 : ℝ) 1) := by
  intro a _ b hb hab
  have hp := mul_pos hσ₁ hσ₂
  apply mul_lt_mul_of_pos_right _ (Real.sqrt_pos.2 hT)
  apply Real.sqrt_lt_sqrt
  · nlinarith [sq_nonneg (σ₁ - σ₂), hb.2]
  · nlinarith [mul_pos (sub_pos.2 hab) hp]

lemma margrabe_anti_aux (F₁ F₂ σ₁ σ₂ r T : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) (hT : 0 < T) :
    StrictAntiOn (fun ρ => margrabe F₁ F₂ σ₁ σ₂ r T ρ) (Set.Icc (-1 : ℝ) 1) := by
  intro a ha b hb hab
  exact black_strictMonoOn _ F₁ F₂ (Real.exp_pos _) hF₁ hF₂
    (Set.mem_Ici.2 (mul_nonneg (Real.sqrt_nonneg _) (Real.sqrt_nonneg _)))
    (Set.mem_Ici.2 (mul_nonneg (Real.sqrt_nonneg _) (Real.sqrt_nonneg _)))
    (swing_strictAntiOn σ₁ σ₂ T hσ₁ hσ₂ hT ha hb hab)

lemma margrabe_cont_aux (F₁ F₂ σ₁ σ₂ r T : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) :
    ContinuousOn (fun ρ => margrabe F₁ F₂ σ₁ σ₂ r T ρ) (Set.Icc (-1 : ℝ) 1) := by
  have hw : Continuous (fun ρ => gapVol σ₁ σ₂ ρ * Real.sqrt T) := by
    unfold gapVol; fun_prop
  exact (black_continuousOn _ F₁ F₂ hF₁ hF₂).comp hw.continuousOn
    (fun ρ _ => Set.mem_Ici.2 (mul_nonneg (Real.sqrt_nonneg _) (Real.sqrt_nonneg _)))

#print axioms pdf_eq
#print axioms pdf_continuous
#print axioms N_eq_integral
#print axioms N_eq_add
#print axioms hasDerivAt_N
#print axioms N_continuous
#print axioms key_identity
#print axioms hasDerivAt_black
#print axioms black_continuousOn
#print axioms black_strictMonoOn
#print axioms swing_strictAntiOn
#print axioms margrabe_anti_aux
#print axioms margrabe_cont_aux

/-- **Implied correlation exists and is unique exactly inside the range.**
Two lognormal futures legs (prices `F₁, F₂ > 0`) with fixed, agreed volatilities `σ₁, σ₂ > 0`,
one constant correlation, a zero-strike European spread option expiring at `T > 0`, and any bank
rate `r`. A quoted price `Cm` is matched by Margrabe's formula at exactly one correlation
`ρ ∈ [-1, 1]` if and only if `C(+1) ≤ Cm ≤ C(-1)`. A quote outside that range has no
implied correlation at all. -/
theorem implied_correlation_exists_unique_iff_in_range
    (F₁ F₂ σ₁ σ₂ r T : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) (hT : 0 < T) (Cm : ℝ) :
    (∃! ρ : ℝ, ρ ∈ Set.Icc (-1 : ℝ) 1 ∧ margrabe F₁ F₂ σ₁ σ₂ r T ρ = Cm) ↔
      (margrabe F₁ F₂ σ₁ σ₂ r T 1 ≤ Cm ∧ Cm ≤ margrabe F₁ F₂ σ₁ σ₂ r T (-1)) := by
  have hanti := margrabe_anti_aux F₁ F₂ σ₁ σ₂ r T hF₁ hF₂ hσ₁ hσ₂ hT
  have hcont := margrabe_cont_aux F₁ F₂ σ₁ σ₂ r T hF₁ hF₂
  have h1 : (1 : ℝ) ∈ Set.Icc (-1 : ℝ) 1 := ⟨by norm_num, le_rfl⟩
  have hm1 : (-1 : ℝ) ∈ Set.Icc (-1 : ℝ) 1 := ⟨le_rfl, by norm_num⟩
  constructor
  · rintro ⟨ρ, ⟨hρ, hρeq⟩, -⟩
    subst hρeq
    exact ⟨hanti.antitoneOn hρ h1 hρ.2, hanti.antitoneOn hm1 hρ hρ.1⟩
  · rintro ⟨hlo, hhi⟩
    obtain ⟨ρ, hρ, hρeq⟩ := intermediate_value_Icc' (by norm_num : (-1 : ℝ) ≤ 1) hcont ⟨hlo, hhi⟩
    exact ⟨ρ, ⟨hρ, hρeq⟩, fun ρ' h' => hanti.injOn h'.1 hρ (h'.2.trans hρeq.symm)⟩

/-- **The price always falls as the correlation rises.**
In the same model, as the correlation turns from `-1` to `+1` the spread option's price falls
strictly: a larger correlation in `[-1, 1]` always gives a strictly smaller Margrabe price. -/
theorem margrabe_strictAntiOn_correlation
    (F₁ F₂ σ₁ σ₂ r T : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) (hT : 0 < T) :
    StrictAntiOn (fun ρ => margrabe F₁ F₂ σ₁ σ₂ r T ρ) (Set.Icc (-1 : ℝ) 1) := by
  exact margrabe_anti_aux F₁ F₂ σ₁ σ₂ r T hF₁ hF₂ hσ₁ hσ₂ hT

/-- **The two-step route: undo the variance formula.**
With leg volatilities `σ₁, σ₂ > 0` and a gap volatility `s ≥ 0` read off the quote, a correlation
`ρ` in `[-1, 1]` gives the gap volatility `s` exactly when
`ρ = (σ₁² + σ₂² - s²) / (2 σ₁ σ₂)`, and that number lies in `[-1, 1]` exactly when
`|σ₁ - σ₂| ≤ s ≤ σ₁ + σ₂`. -/
theorem two_step_correlation_iff
    (σ₁ σ₂ s ρ : ℝ) (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) (hs : 0 ≤ s) :
    (ρ ∈ Set.Icc (-1 : ℝ) 1 ∧ gapVol σ₁ σ₂ ρ = s) ↔
      (ρ = (σ₁ ^ 2 + σ₂ ^ 2 - s ^ 2) / (2 * σ₁ * σ₂) ∧ |σ₁ - σ₂| ≤ s ∧ s ≤ σ₁ + σ₂) := by
  have hp := mul_pos hσ₁ hσ₂
  constructor
  · rintro ⟨⟨h1, h2⟩, hg⟩
    have hrad : 0 ≤ σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by nlinarith [sq_nonneg (σ₁ - σ₂)]
    have hs2 : s ^ 2 = σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by
      rw [← hg, gapVol, Real.sq_sqrt hrad]
    refine ⟨?_, ?_, ?_⟩
    · rw [eq_div_iff (by positivity)]
      linear_combination hs2
    · have hle : (σ₁ - σ₂) ^ 2 ≤ s ^ 2 := by nlinarith
      have := sq_le_sq.1 hle
      rwa [abs_of_nonneg hs] at this
    · have hle : s ^ 2 ≤ (σ₁ + σ₂) ^ 2 := by nlinarith
      have := sq_le_sq.1 hle
      rwa [abs_of_nonneg hs, abs_of_pos (by linarith)] at this
  · rintro ⟨hρ, hlo, hhi⟩
    have hlo2 : (σ₁ - σ₂) ^ 2 ≤ s ^ 2 := sq_le_sq.2 (by rwa [abs_of_nonneg hs])
    have hhi2 : s ^ 2 ≤ (σ₁ + σ₂) ^ 2 := pow_le_pow_left₀ hs hhi 2
    rw [eq_div_iff (by positivity)] at hρ
    refine ⟨⟨?_, ?_⟩, ?_⟩
    · nlinarith
    · nlinarith
    · have hr : σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ = s ^ 2 := by linear_combination -hρ
      rw [gapVol, hr, Real.sqrt_sq hs]

-- Worked numbers from the card, as exact fractions (σ₁ = 0.30, σ₂ = 0.25).
-- The gap's variance at ρ = 0.5: 0.09 + 0.0625 - 2 × 0.5 × 0.30 × 0.25 = 0.0775.
example : ((3 : ℚ) / 10) ^ 2 + (1 / 4) ^ 2 - 2 * (1 / 2) * (3 / 10) * (1 / 4) = 31 / 400 := by
  norm_num
-- Floor and ceiling of the gap's variance: (0.30 - 0.25)² = 0.05² at ρ = +1, (0.55)² at ρ = -1.
example : ((3 : ℚ) / 10) ^ 2 + (1 / 4) ^ 2 - 2 * 1 * (3 / 10) * (1 / 4) = (1 / 20) ^ 2 := by
  norm_num
example : ((3 : ℚ) / 10) ^ 2 + (1 / 4) ^ 2 - 2 * (-1) * (3 / 10) * (1 / 4) = (11 / 20) ^ 2 := by
  norm_num
-- The quote is in range: 0.05² ≤ 0.0775 ≤ 0.55².
example : ((1 : ℚ) / 20) ^ 2 ≤ 31 / 400 ∧ (31 : ℚ) / 400 ≤ (11 / 20) ^ 2 := by norm_num
-- Two-step route: (0.1525 - 0.0775) / 0.15 = 0.5.
example : ((61 : ℚ) / 400 - 31 / 400) / (2 * (3 / 10) * (1 / 4)) = 1 / 2 := by norm_num
-- What breaks: drop the 2 and it reads 1; flip the sign and it reads -0.5.
example : ((61 : ℚ) / 400 - 31 / 400) / ((3 / 10) * (1 / 4)) = 1 := by norm_num
example : ((31 : ℚ) / 400 - 61 / 400) / (2 * (3 / 10) * (1 / 4)) = -1 / 2 := by norm_num
-- Same quote, other gasoline vols (crude 25%): 26% → 0.4046, 28% → 0.4529, 32% → 0.5462, 34% → 0.5918.
example : (((13 : ℚ) / 50) ^ 2 + (1 / 4) ^ 2 - 31 / 400) / (2 * (13 / 50) * (1 / 4)) = 263 / 650 := by
  norm_num
example : (((7 : ℚ) / 25) ^ 2 + (1 / 4) ^ 2 - 31 / 400) / (2 * (7 / 25) * (1 / 4)) = 317 / 700 := by
  norm_num
example : (((8 : ℚ) / 25) ^ 2 + (1 / 4) ^ 2 - 31 / 400) / (2 * (8 / 25) * (1 / 4)) = 437 / 800 := by
  norm_num
example : (((17 : ℚ) / 50) ^ 2 + (1 / 4) ^ 2 - 31 / 400) / (2 * (17 / 50) * (1 / 4)) = 503 / 850 := by
  norm_num
-- Gasoline at 55%: the formula asks for 23/22 ≈ 1.0455, above 1, because 0.0775 < (0.55 - 0.25)².
example : (((11 : ℚ) / 20) ^ 2 + (1 / 4) ^ 2 - 31 / 400) / (2 * (11 / 20) * (1 / 4)) = 23 / 22 ∧
    (1 : ℚ) < 23 / 22 ∧ (31 : ℚ) / 400 < (11 / 20 - 1 / 4) ^ 2 := by norm_num

#print axioms implied_correlation_exists_unique_iff_in_range
#print axioms margrabe_strictAntiOn_correlation
#print axioms two_step_correlation_iff

end SpreadImpliedCorrelation
