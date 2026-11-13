-- Compound options: the share's readings at the two dates have correlation √(T₁/T₂), a call on a call less a put on the call equals today's call less the discounted fee, and every positive fee has exactly one critical share price.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory ProbabilityTheory Real

namespace CompoundOptions

/-! The model, as on the card. Rate `r`, dividend yield `q`, volatility `σ`, time left `τ`,
strike `K`. `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`. -/

/-- `d₁ = (ln(S/K) + (r − q + σ²/2) τ) / (σ √τ)`; `d₂ = d₁ − σ √τ`. -/
noncomputable def bsD1 (S K r q σ τ : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * τ) / (σ * √τ)

/-- The Black-Scholes call `C(S) = S e^(−qτ) N(d₁) − K e^(−rτ) N(d₂)`. -/
noncomputable def bsCall (S K r q σ τ : ℝ) : ℝ :=
  S * exp (-(q * τ)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ τ) -
    K * exp (-(r * τ)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ τ - σ * √τ)

lemma stdNormal_cdf_sub_of_le {a b : ℝ} (hab : a ≤ b) :
    cdf (gaussianReal 0 1) b - cdf (gaussianReal 0 1) a =
      ∫ x in a..b, gaussianPDFReal 0 1 x := by
  have h := StieltjesFunction.measure_Ioc (cdf (gaussianReal 0 1)) a b
  rw [measure_cdf, gaussianReal_apply_eq_integral _ one_ne_zero] at h
  rw [intervalIntegral.integral_of_le hab]
  refine ((ENNReal.ofReal_eq_ofReal_iff ?_ ?_).1 h).symm
  · exact setIntegral_nonneg measurableSet_Ioc (fun x _ => gaussianPDFReal_nonneg _ _ _)
  · exact sub_nonneg.2 ((cdf (gaussianReal 0 1)).mono hab)

lemma stdNormal_cdf_sub (a b : ℝ) :
    cdf (gaussianReal 0 1) b - cdf (gaussianReal 0 1) a =
      ∫ x in a..b, gaussianPDFReal 0 1 x := by
  rcases le_total a b with h | h
  · exact stdNormal_cdf_sub_of_le h
  · rw [intervalIntegral.integral_symm, ← stdNormal_cdf_sub_of_le h]; ring

lemma continuous_stdNormalPDF : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

lemma hasDerivAt_stdNormal_cdf (x : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 x) x := by
  have h : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun y => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; rw [← stdNormal_cdf_sub 0 y]; ring
  rw [h]
  exact ((continuous_stdNormalPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma stdNormal_cdf_pos (x : ℝ) : 0 < cdf (gaussianReal 0 1) x := by
  have h := stdNormal_cdf_sub (x - 1) x
  have hpos : 0 < ∫ t in (x - 1)..x, gaussianPDFReal 0 1 t :=
    intervalIntegral.intervalIntegral_pos_of_pos_on
      (continuous_stdNormalPDF.intervalIntegrable _ _)
      (fun t _ => gaussianPDFReal_pos _ _ _ one_ne_zero) (by linarith)
  have := cdf_nonneg (gaussianReal 0 1) (x - 1)
  linarith

/-- The density identity behind the Black-Scholes delta. -/
lemma stdNormalPDF_identity {S K r q σ τ d L : ℝ} (hτ : 0 ≤ τ) (hS : S = K * exp L)
    (hd : d * (σ * √τ) = L + (r - q + σ ^ 2 / 2) * τ) :
    S * exp (-(q * τ)) * gaussianPDFReal 0 1 d =
      K * exp (-(r * τ)) * gaussianPDFReal 0 1 (d - σ * √τ) := by
  have hs : (σ * √τ) ^ 2 = σ ^ 2 * τ := by rw [mul_pow, sq_sqrt hτ]
  have he : L + -(q * τ) + -(d - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(r * τ) + -(d - σ * √τ - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) := by
    push_cast
    linear_combination -hd + hs / 2
  simp only [gaussianPDFReal]
  rw [hS]
  calc K * exp L * exp (-(q * τ)) * ((√(2 * π * ((1 : NNReal) : ℝ)))⁻¹ *
        exp (-(d - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))))
      = K * (√(2 * π * ((1 : NNReal) : ℝ)))⁻¹ *
          exp (L + -(q * τ) + -(d - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) := by
        rw [exp_add, exp_add]; ring
    _ = _ := by rw [he, exp_add]; ring

lemma hasDerivAt_bsCall {S K r q σ τ : ℝ} (hσ : 0 < σ) (hτ : 0 < τ) (hK : 0 < K) (hS : 0 < S) :
    HasDerivAt (fun S => bsCall S K r q σ τ)
      (exp (-(q * τ)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ τ)) S := by
  have hs : σ * √τ ≠ 0 := (mul_pos hσ (sqrt_pos.2 hτ)).ne'
  have hd : HasDerivAt (fun S => bsD1 S K r q σ τ)
      ((1 / K) / (S / K) / (σ * √τ)) S := by
    unfold bsD1
    exact ((((hasDerivAt_id' S).div_const K).log (div_pos hS hK).ne').add_const _).div_const _
  have h1 := ((hasDerivAt_id' S).mul_const (exp (-(q * τ)))).mul
    ((hasDerivAt_stdNormal_cdf (bsD1 S K r q σ τ)).comp S hd)
  have h2 := ((hasDerivAt_stdNormal_cdf (bsD1 S K r q σ τ - σ * √τ)).comp S
    (hd.sub_const (σ * √τ))).const_mul (K * exp (-(r * τ)))
  have hid := stdNormalPDF_identity (S := S) (K := K) (r := r) (q := q) (σ := σ) (τ := τ)
    (d := bsD1 S K r q σ τ) (L := log (S / K)) hτ.le
    (by rw [exp_log (div_pos hS hK)]; field_simp)
    (by unfold bsD1; field_simp)
  convert h1.sub h2 using 1
  · funext x; rfl
  · simp only [Function.comp_apply]
    linear_combination (-(1 / K / (S / K) / (σ * √τ))) * hid

#print axioms stdNormal_cdf_sub_of_le
#print axioms stdNormal_cdf_sub
#print axioms continuous_stdNormalPDF
#print axioms hasDerivAt_stdNormal_cdf
#print axioms stdNormal_cdf_pos
#print axioms stdNormalPDF_identity
#print axioms hasDerivAt_bsCall

/-- **The correlation of the two dates is the square root of their ratio.** The path value at the
second date is the value at the first date, `X` (spread `T₁`), plus an independent piece `Z`
(spread `T₂ − T₁`). Then the two readings have covariance `T₁`, and their correlation,
covariance over the product of the two spreads, is `√(T₁/T₂)`. -/
theorem correlation_of_two_dates_eq_sqrt_ratio {Ω : Type*} [MeasurableSpace Ω]
    {μ : Measure Ω} [IsProbabilityMeasure μ] {X Z : Ω → ℝ} {T₁ T₂ : ℝ}
    (hT₁ : 0 < T₁) (hT : T₁ ≤ T₂)
    (hX : MemLp X 2 μ) (hZ : MemLp Z 2 μ) (hind : IndepFun X Z μ)
    (hVX : Var[X; μ] = T₁) (hVZ : Var[Z; μ] = T₂ - T₁) :
    cov[X, X + Z; μ] = T₁ ∧
      cov[X, X + Z; μ] / (√(Var[X; μ]) * √(Var[X + Z; μ])) = √(T₁ / T₂) := by
  have hC : cov[X, X + Z; μ] = T₁ := by
    rw [covariance_add_right hX hX hZ, covariance_self hX.aemeasurable,
      hind.covariance_eq_zero hX hZ, hVX, add_zero]
  have hV : Var[X + Z; μ] = T₂ := by
    rw [hind.variance_add hX hZ, hVX, hVZ]; ring
  refine ⟨hC, ?_⟩
  have hT₂ : 0 < T₂ := lt_of_lt_of_le hT₁ hT
  have h1 : 0 < √T₁ := sqrt_pos.2 hT₁
  have h2 : 0 < √T₂ := sqrt_pos.2 hT₂
  rw [hC, hV, hVX, sqrt_div hT₁.le, div_eq_div_iff (by positivity) h2.ne']
  rw [← mul_assoc, mul_self_sqrt hT₁.le]

/-- **Compound parity.** On the first date the call on the call pays `max(C₁ − K₁, 0)` and the
put on the call pays `max(K₁ − C₁, 0)`, where `C₁` is the call's value then. Averaging and
discounting from the first date, the call on the call less the put on the call equals the house
call today, `e^(−rT₁) E[C₁]`, less the fee discounted from the first date. -/
theorem compound_parity {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {C₁ : Ω → ℝ} (hC : Integrable C₁ μ) (K₁ r T₁ : ℝ) :
    exp (-(r * T₁)) * ∫ ω, max (C₁ ω - K₁) 0 ∂μ - exp (-(r * T₁)) * ∫ ω, max (K₁ - C₁ ω) 0 ∂μ =
      exp (-(r * T₁)) * ∫ ω, C₁ ω ∂μ - K₁ * exp (-(r * T₁)) := by
  have i1 : Integrable (fun ω => max (C₁ ω - K₁) 0) μ :=
    (hC.sub (integrable_const K₁)).pos_part
  have i2 : Integrable (fun ω => max (K₁ - C₁ ω) 0) μ :=
    ((integrable_const K₁).sub hC).pos_part
  have h : ∀ ω, max (C₁ ω - K₁) 0 - max (K₁ - C₁ ω) 0 = C₁ ω - K₁ := by
    intro ω
    rcases le_total (C₁ ω) K₁ with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  rw [← mul_sub, ← integral_sub i1 i2]
  simp_rw [h]
  rw [integral_sub hC (integrable_const _)]
  simp
  ring

/-- **Exactly one critical share price.** With volatility above zero, time left above zero and a
strike above zero, the Black-Scholes call rises steadily from 0 with no ceiling as the share
price grows. So every fee above zero equals the call's value at exactly one share price. -/
theorem exists_unique_critical_price {K₂ K₁ r q σ τ : ℝ}
    (hσ : 0 < σ) (hτ : 0 < τ) (hK₂ : 0 < K₂) (hK₁ : 0 < K₁) :
    ∃! S : ℝ, 0 < S ∧ bsCall S K₂ r q σ τ = K₁ := by
  set f : ℝ → ℝ := fun S => bsCall S K₂ r q σ τ with hf
  set N := cdf (gaussianReal 0 1) with hN
  set a := exp (-(q * τ)) with ha
  set b := exp (-(r * τ)) with hb
  have ha0 : 0 < a := exp_pos _
  have hb0 : 0 < b := exp_pos _
  have hderiv : ∀ S, 0 < S → HasDerivAt f (a * N (bsD1 S K₂ r q σ τ)) S :=
    fun S hS => hasDerivAt_bsCall hσ hτ hK₂ hS
  have hcont : ContinuousOn f (Set.Ioi 0) :=
    fun S hS => (hderiv S hS).continuousAt.continuousWithinAt
  have hmono : StrictMonoOn f (Set.Ioi 0) := by
    refine strictMonoOn_of_hasDerivWithinAt_pos (convex_Ioi 0) hcont
      (f' := fun S => a * N (bsD1 S K₂ r q σ τ)) ?_ ?_
    · intro S hS
      rw [interior_Ioi] at hS ⊢
      exact (hderiv S hS).hasDerivWithinAt
    · intro S hS
      exact mul_pos ha0 (stdNormal_cdf_pos _)
  -- a small share price where the call is below the fee
  set S₀ := K₁ / (2 * a) with hS₀
  have hS₀0 : 0 < S₀ := by positivity
  have hf₀ : f S₀ < K₁ := by
    have h1 := cdf_le_one (gaussianReal 0 1) (bsD1 S₀ K₂ r q σ τ)
    have h2 := cdf_nonneg (gaussianReal 0 1) (bsD1 S₀ K₂ r q σ τ - σ * √τ)
    have h3 : S₀ * a = K₁ / 2 := by rw [hS₀]; field_simp
    have : f S₀ ≤ S₀ * a := by
      simp only [hf, bsCall]
      nlinarith [mul_pos hS₀0 ha0, mul_pos hK₂ hb0]
    linarith
  -- a large share price where the call is above the fee
  set m := (r - q + σ ^ 2 / 2) * τ with hm
  set c := N 0 with hc
  have hc0 : 0 < c := stdNormal_cdf_pos 0
  set S₁ := max (max (K₂ * exp (-m)) ((K₁ + K₂ * b + 1) / (a * c))) S₀ with hS₁
  have hS₀₁ : S₀ ≤ S₁ := le_max_right _ _
  have hS₁0 : 0 < S₁ := lt_of_lt_of_le hS₀0 hS₀₁
  have hA : K₂ * exp (-m) ≤ S₁ := le_trans (le_max_left _ _) (le_max_left _ _)
  have hB : (K₁ + K₂ * b + 1) / (a * c) ≤ S₁ := le_trans (le_max_right _ _) (le_max_left _ _)
  have hf₁ : K₁ < f S₁ := by
    have hlog : -m ≤ log (S₁ / K₂) := by
      rw [le_log_iff_exp_le (div_pos hS₁0 hK₂), le_div_iff₀ hK₂]
      linarith
    have hd : 0 ≤ bsD1 S₁ K₂ r q σ τ := by
      unfold bsD1
      apply div_nonneg _ (mul_pos hσ (sqrt_pos.2 hτ)).le
      linarith
    have h1 : c ≤ N (bsD1 S₁ K₂ r q σ τ) := (cdf (gaussianReal 0 1)).mono hd
    have h2 := cdf_le_one (gaussianReal 0 1) (bsD1 S₁ K₂ r q σ τ - σ * √τ)
    have h3 : K₁ + K₂ * b + 1 ≤ S₁ * (a * c) := by
      rwa [div_le_iff₀ (mul_pos ha0 hc0)] at hB
    have h4 : S₁ * a * c ≤ S₁ * a * N (bsD1 S₁ K₂ r q σ τ) :=
      mul_le_mul_of_nonneg_left h1 (mul_pos hS₁0 ha0).le
    have h5 : K₂ * b * N (bsD1 S₁ K₂ r q σ τ - σ * √τ) ≤ K₂ * b :=
      mul_le_of_le_one_right (mul_pos hK₂ hb0).le h2
    have : f S₁ = S₁ * a * N (bsD1 S₁ K₂ r q σ τ) -
        K₂ * b * N (bsD1 S₁ K₂ r q σ τ - σ * √τ) := rfl
    nlinarith
  obtain ⟨S, hSI, hfS⟩ : K₁ ∈ f '' Set.Icc S₀ S₁ :=
    intermediate_value_Icc hS₀₁ (hcont.mono fun x hx => lt_of_lt_of_le hS₀0 hx.1)
      ⟨hf₀.le, hf₁.le⟩
  have hS0 : 0 < S := lt_of_lt_of_le hS₀0 hSI.1
  refine ⟨S, ⟨hS0, hfS⟩, ?_⟩
  rintro y ⟨hy0, hy⟩
  exact hmono.injOn hy0 hS0 (hy.trans hfS.symm)

#print axioms correlation_of_two_dates_eq_sqrt_ratio
#print axioms compound_parity
#print axioms exists_unique_critical_price

end CompoundOptions
