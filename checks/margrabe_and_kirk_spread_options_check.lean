-- Spread options: if two futures prices are lognormal with fixed volatilities and a fixed correlation ρ, the discounted average of max(F₁(T) - F₂(T), 0) is Margrabe's formula D [F₁ N(d₁) - F₂ N(d₂)] with the one ratio volatility √(σ₁² + σ₂² - 2ρσ₁σ₂), that volatility is exactly the spread of the log ratio, and the price falls strictly as the correlation rises.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- A futures quote on expiry day in the card's model (detailed proof): today's quote `F`, its
volatility `σ`, years to expiry `T`, and a standard bell-curve shock `z`:
`F(T) = F e^(-σ²T/2 + σ√T z)`, a fair bet on its own number. -/
noncomputable def futuresAtExpiry (F σ T z : ℝ) : ℝ :=
  F * exp (-(σ ^ 2 * T) / 2 + σ * √T * z)

/-- The ratio volatility `σ = √(σ₁² + σ₂² - 2ρσ₁σ₂)`, the volatility of gasoline counted in
barrels of crude. -/
noncomputable def ratioVol (σ₁ σ₂ ρ : ℝ) : ℝ :=
  √(σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)

/-- `d₁ = (ln(F₁/F₂) + σ²T/2) / (σ√T)` with the ratio volatility `σ`; then `d₂ = d₁ - σ√T`. -/
noncomputable def margrabeD1 (F₁ F₂ σ₁ σ₂ ρ T : ℝ) : ℝ :=
  (log (F₁ / F₂) + ratioVol σ₁ σ₂ ρ ^ 2 * T / 2) / (ratioVol σ₁ σ₂ ρ * √T)

/-- Margrabe's formula on futures, `V = D [F₁ N(d₁) - F₂ N(d₂)]` with `D = e^(-rT)`. When the
ratio cannot move (`σ√T = 0`), the card's code rule applies: the gap cannot move either and the
option is worth `D max(F₁ - F₂, 0)`. -/
noncomputable def margrabePrice (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) : ℝ :=
  if ratioVol σ₁ σ₂ ρ * √T = 0 then exp (-r * T) * max (F₁ - F₂) 0
  else exp (-r * T) * (F₁ * stdNormalCDF (margrabeD1 F₁ F₂ σ₁ σ₂ ρ T)
    - F₂ * stdNormalCDF (margrabeD1 F₁ F₂ σ₁ σ₂ ρ T - ratioVol σ₁ σ₂ ρ * √T))

lemma tilt_gauss (s : ℝ) :
    (gaussianReal 0 1).withDensity (fun x => ENNReal.ofReal (exp (s * x - s ^ 2 / 2)))
      = gaussianReal s 1 := by
  rw [gaussianReal_of_var_ne_zero 0 one_ne_zero, gaussianReal_of_var_ne_zero s one_ne_zero,
    ← withDensity_mul _ (measurable_gaussianPDF _ _) (by fun_prop)]
  congr 1
  funext x
  simp only [Pi.mul_apply, gaussianPDF, gaussianPDFReal]
  rw [← ENNReal.ofReal_mul (by positivity), mul_assoc, ← exp_add]
  congr 2
  push_cast
  congr 1
  ring

#print axioms tilt_gauss

lemma stdNormalCDF_eq (x : ℝ) : stdNormalCDF x = (gaussianReal 0 1).real (Iic x) := by
  rw [stdNormalCDF, cdf_eq_real]

#print axioms stdNormalCDF_eq

lemma stdNormalCDF_neg (a : ℝ) : stdNormalCDF (-a) = (gaussianReal 0 1).real (Ioi a) := by
  have := nullSingletonClass_gaussianReal (μ := (0:ℝ)) (v := 1) one_ne_zero
  rw [stdNormalCDF_eq, ← measureReal_congr (Iio_ae_eq_Iic (μ := gaussianReal 0 1))]
  conv_rhs => rw [← neg_zero, ← gaussianReal_map_neg]
  rw [map_measureReal_apply (by fun_prop) measurableSet_Ioi]
  congr 1
  ext x; simp

#print axioms stdNormalCDF_neg

lemma shift_real (s a : ℝ) : (gaussianReal s 1).real (Ioi a) = stdNormalCDF (s - a) := by
  rw [show s - a = -(a - s) by ring, stdNormalCDF_neg]
  conv_lhs => rw [← zero_add s, ← gaussianReal_map_add_const]
  rw [map_measureReal_apply (by fun_prop) measurableSet_Ioi]
  congr 1
  ext x; simp [sub_lt_iff_lt_add]

#print axioms shift_real

lemma integrable_exp_tilt (S : ℝ) :
    Integrable (fun z => exp (S * z - S ^ 2 / 2)) (gaussianReal 0 1) := by
  have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) S).const_mul (exp (-(S ^ 2 / 2)))
  refine this.congr (ae_of_all _ fun z => ?_)
  simp only
  rw [← exp_add]; ring_nf

#print axioms integrable_exp_tilt

lemma setIntegral_tilt (S k : ℝ) :
    ∫ z in Ioi k, exp (S * z - S ^ 2 / 2) ∂(gaussianReal 0 1) = stdNormalCDF (S - k) := by
  rw [← shift_real, ← tilt_gauss S, measureReal_def, withDensity_apply _ measurableSet_Ioi,
    ← ofReal_integral_eq_lintegral_ofReal (integrable_exp_tilt S).integrableOn
      (ae_of_all _ fun _ => (exp_pos _).le),
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Ioi fun _ _ => (exp_pos _).le)]

#print axioms setIntegral_tilt

lemma black1d (A B S : ℝ) (hA : 0 < A) (hB : 0 < B) (hS : 0 < S) :
    ∫ z, max (A * exp (S * z - S ^ 2 / 2) - B) 0 ∂(gaussianReal 0 1) =
      A * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S)
        - B * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S - S) := by
  set k := (log (B / A) + S ^ 2 / 2) / S with hk
  have hiff : ∀ z, k < z ↔ B < A * exp (S * z - S ^ 2 / 2) := by
    intro z
    rw [hk, div_lt_iff₀ hS, ← div_lt_iff₀' hA, ← Real.log_lt_iff_lt_exp (div_pos hB hA)]
    constructor <;> intro h <;> linarith
  have hpt : ∀ z, max (A * exp (S * z - S ^ 2 / 2) - B) 0
      = (Ioi k).indicator (fun z => A * exp (S * z - S ^ 2 / 2) - B) z := by
    intro z
    by_cases hz : k < z
    · rw [indicator_of_mem (show z ∈ Ioi k from hz)]
      exact max_eq_left (by linarith [(hiff z).1 hz])
    · rw [indicator_of_notMem (show z ∉ Ioi k from hz)]
      exact max_eq_right (by linarith [not_lt.1 (mt (hiff z).2 hz)])
  simp_rw [hpt]
  rw [integral_indicator measurableSet_Ioi,
    integral_sub ((integrable_exp_tilt S).const_mul A).integrableOn (integrableOn_const ..),
    integral_const_mul, setIntegral_const, setIntegral_tilt, ← stdNormalCDF_neg, smul_eq_mul,
    mul_comm _ B]
  have hl : log (B / A) = - log (A / B) := by
    rw [Real.log_div hB.ne' hA.ne', Real.log_div hA.ne' hB.ne']; ring
  congr 3
  · rw [hk, hl]; field_simp; ring
  · rw [hk, hl]; field_simp; ring

#print axioms black1d

/-- The Black value of `max(A e^{Sz - S²/2} - B, 0)` as a function of the total volatility `S`. -/
noncomputable def blackVal (A B S : ℝ) : ℝ :=
  if S = 0 then max (A - B) 0
  else A * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S)
    - B * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S - S)

#print axioms blackVal

lemma black_all (A B S : ℝ) (hA : 0 < A) (hB : 0 < B) (hS : 0 ≤ S) :
    ∫ z, max (A * exp (S * z - S ^ 2 / 2) - B) 0 ∂(gaussianReal 0 1) = blackVal A B S := by
  rcases hS.eq_or_lt with h | h
  · subst h; simp [blackVal]
  · rw [black1d A B S hA hB h]; simp only [blackVal, h.ne', ↓reduceIte]

#print axioms black_all

lemma map_lin_prod (ν₁ ν₂ : Measure ℝ) [IsProbabilityMeasure ν₁] [IsProbabilityMeasure ν₂]
    (a b : ℝ) :
    (ν₁.prod ν₂).map (fun p => a * p.1 + b * p.2) = (ν₁.map (a * ·)) ∗ (ν₂.map (b * ·)) := by
  show _ = Measure.map (fun x : ℝ × ℝ => x.1 + x.2) ((ν₁.map (a * ·)).prod (ν₂.map (b * ·)))
  rw [Measure.map_prod_map _ _ (measurable_const_mul a) (measurable_const_mul b),
    Measure.map_map (by fun_prop) (by fun_prop)]
  rfl

#print axioms map_lin_prod

lemma core (F₁ F₂ s₁ s₂ ρ c : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hc : c ^ 2 = 1 - ρ ^ 2) :
    ∫ p, max (F₁ * exp (-(s₁ ^ 2) / 2 + s₁ * (ρ * p.1 + c * p.2))
        - F₂ * exp (-(s₂ ^ 2) / 2 + s₂ * p.1)) 0 ∂((gaussianReal 0 1).prod (gaussianReal 0 1))
      = blackVal F₁ F₂ √(s₁ ^ 2 + s₂ ^ 2 - 2 * ρ * s₁ * s₂) := by
  set K := (s₂ ^ 2 - s₁ ^ 2) / 2
  set a := s₁ * ρ - s₂
  set b := s₁ * c
  set H : ℝ → ℝ := fun w => max (F₁ * exp (K + w) - F₂) 0 with hH
  have hHc : Continuous H := by fun_prop
  have hpt : ∀ p : ℝ × ℝ, max (F₁ * exp (-(s₁ ^ 2) / 2 + s₁ * (ρ * p.1 + c * p.2))
        - F₂ * exp (-(s₂ ^ 2) / 2 + s₂ * p.1)) 0
      = exp (s₂ * p.1 - s₂ ^ 2 / 2) * H (a * p.1 + b * p.2) := by
    intro p
    have e1 : F₁ * exp (-(s₁ ^ 2) / 2 + s₁ * (ρ * p.1 + c * p.2))
        = exp (s₂ * p.1 - s₂ ^ 2 / 2) * (F₁ * exp (K + (a * p.1 + b * p.2))) := by
      rw [mul_left_comm, ← exp_add]; congr 2; ring
    have e2 : F₂ * exp (-(s₂ ^ 2) / 2 + s₂ * p.1) = exp (s₂ * p.1 - s₂ ^ 2 / 2) * F₂ := by
      rw [mul_comm]; congr 2; ring
    rw [e1, e2, ← mul_sub, hH]
    simp only
    rw [mul_max_of_nonneg _ _ (exp_pos _).le, mul_zero]
  simp_rw [hpt]
  have hmeas : Measurable fun p : ℝ × ℝ => ENNReal.ofReal (exp (s₂ * p.1 - s₂ ^ 2 / 2)) := by
    fun_prop
  have step2 : ∫ p, exp (s₂ * p.1 - s₂ ^ 2 / 2) * H (a * p.1 + b * p.2)
        ∂((gaussianReal 0 1).prod (gaussianReal 0 1))
      = ∫ p, H (a * p.1 + b * p.2) ∂((gaussianReal s₂ 1).prod (gaussianReal 0 1)) := by
    rw [← tilt_gauss s₂, prod_withDensity_left (by fun_prop),
      integral_withDensity_eq_integral_toReal_smul hmeas (ae_of_all _ fun _ => ENNReal.ofReal_lt_top)]
    congr 1; funext p
    rw [ENNReal.toReal_ofReal (exp_pos _).le, smul_eq_mul]
  rw [step2]
  set S := √(s₁ ^ 2 + s₂ ^ 2 - 2 * ρ * s₁ * s₂) with hS
  have hrad : s₁ ^ 2 + s₂ ^ 2 - 2 * ρ * s₁ * s₂ = a ^ 2 + b ^ 2 := by
    simp only [a, b]; rw [mul_pow s₁ c, hc]; ring
  have hS2 : S ^ 2 = a ^ 2 + b ^ 2 := by
    rw [hS, Real.sq_sqrt (by rw [hrad]; positivity), hrad]
  have step3 : ∫ p, H (a * p.1 + b * p.2) ∂((gaussianReal s₂ 1).prod (gaussianReal 0 1))
      = ∫ w, H w ∂((gaussianReal 0 1).map (fun z => S * z + a * s₂)) := by
    rw [show (∫ p, H (a * p.1 + b * p.2) ∂((gaussianReal s₂ 1).prod (gaussianReal 0 1)))
        = ∫ w, H w ∂(((gaussianReal s₂ 1).prod (gaussianReal 0 1)).map
          (fun p => a * p.1 + b * p.2)) from
        (integral_map (by fun_prop) hHc.aestronglyMeasurable).symm,
      map_lin_prod, gaussianReal_map_const_mul, gaussianReal_map_const_mul,
      gaussianReal_conv_gaussianReal,
      show (fun z => S * z + a * s₂) = (fun x => x + a * s₂) ∘ (fun x => S * x) from rfl,
      ← Measure.map_map (measurable_add_const _) (measurable_const_mul S),
      gaussianReal_map_const_mul, gaussianReal_map_add_const]
    congr 2
    · ring
    · ext; simp [hS2]
  rw [step3]
  rw [integral_map (by fun_prop) hHc.aestronglyMeasurable,
    ← black_all F₁ F₂ S hF₁ hF₂ (Real.sqrt_nonneg _)]
  congr 1; funext z
  have : K + a * s₂ = -(S ^ 2 / 2) := by
    rw [hS2]; simp only [K, a, b]; rw [mul_pow s₁ c, hc]; ring
  simp only [hH]
  rw [show K + (S * z + a * s₂) = S * z - S ^ 2 / 2 by linarith]

#print axioms core

lemma fut_eq (F σ T z : ℝ) (hT : 0 ≤ T) :
    futuresAtExpiry F σ T z = F * exp (-((σ * √T) ^ 2) / 2 + σ * √T * z) := by
  rw [futuresAtExpiry, mul_pow, Real.sq_sqrt hT]

#print axioms fut_eq

lemma ratio_eq (σ₁ σ₂ ρ T : ℝ) (hT : 0 ≤ T) :
    ratioVol σ₁ σ₂ ρ * √T
      = √((σ₁ * √T) ^ 2 + (σ₂ * √T) ^ 2 - 2 * ρ * (σ₁ * √T) * (σ₂ * √T)) := by
  rw [ratioVol, ← Real.sqrt_mul' _ hT]
  congr 1
  have h := Real.sq_sqrt hT
  linear_combination (-(σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)) * h

#print axioms ratio_eq

lemma price_eq (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hT : 0 ≤ T) :
    margrabePrice r T F₁ F₂ σ₁ σ₂ ρ
      = exp (-r * T) * blackVal F₁ F₂ (ratioVol σ₁ σ₂ ρ * √T) := by
  unfold margrabePrice blackVal margrabeD1
  split_ifs with h
  · rfl
  · rw [mul_pow, Real.sq_sqrt hT]

#print axioms price_eq

lemma stdNormalCDF_eq_integral (x : ℝ) :
    stdNormalCDF x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [stdNormalCDF_eq, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      fun _ _ => gaussianPDFReal_nonneg _ _ _)]

#print axioms stdNormalCDF_eq_integral

lemma continuous_stdPDF : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

#print axioms continuous_stdPDF

lemma hasDerivAt_stdNormalCDF (x : ℝ) :
    HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Iic a) volume :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun u => stdNormalCDF 0 + ∫ t in (0:ℝ)..u, gaussianPDFReal 0 1 t := by
    funext u
    rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
      ← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI u)]
    ring
  rw [heq]
  exact (intervalIntegral.integral_hasDerivAt_right
    ((integrable_gaussianPDFReal 0 1).intervalIntegrable)
    (continuous_stdPDF.stronglyMeasurableAtFilter _ _) continuous_stdPDF.continuousAt).const_add _

#print axioms hasDerivAt_stdNormalCDF

lemma pdf_ratio (A B S d : ℝ) (hA : 0 < A) (hB : 0 < B)
    (hd : d * S = log (A / B) + S ^ 2 / 2) :
    A * gaussianPDFReal 0 1 d = B * gaussianPDFReal 0 1 (d - S) := by
  simp only [gaussianPDFReal]
  rw [mul_left_comm, mul_left_comm B]
  congr 1
  rw [← Real.exp_log hA, ← Real.exp_log hB, ← exp_add, ← exp_add]
  congr 1
  rw [Real.log_div hA.ne' hB.ne'] at hd
  push_cast
  field_simp
  linear_combination (-2) * hd

#print axioms pdf_ratio

lemma hasDerivAt_black (A B S : ℝ) (hA : 0 < A) (hB : 0 < B) (hS : 0 < S) :
    HasDerivAt (fun S => A * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S)
        - B * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S - S))
      (B * gaussianPDFReal 0 1 ((log (A / B) + S ^ 2 / 2) / S - S)) S := by
  set L := log (A / B)
  have hd : HasDerivAt (fun S => (L + S ^ 2 / 2) / S)
      (((↑2 * S ^ (2 - 1) / 2) * S - (L + S ^ 2 / 2) * 1) / S ^ 2) S :=
    (((hasDerivAt_pow 2 S).div_const 2).const_add L).div (hasDerivAt_id S) hS.ne'
  have h1 := ((hasDerivAt_stdNormalCDF _).comp S hd).const_mul A
  have h2 := ((hasDerivAt_stdNormalCDF _).comp S (hd.sub (hasDerivAt_id S))).const_mul B
  have hid := pdf_ratio A B S ((L + S ^ 2 / 2) / S) hA hB (by field_simp; simp only [L]; ring)
  convert h1.sub h2 using 1
  · rfl
  simp only [Pi.sub_apply, id]
  linear_combination (-((2 * S ^ (2 - 1) / 2 * S - (L + S ^ 2 / 2) * 1) / S ^ 2 : ℝ)) * hid

#print axioms hasDerivAt_black

lemma integral_exp_tilt (S : ℝ) : ∫ z, exp (S * z - S ^ 2 / 2) ∂(gaussianReal 0 1) = 1 := by
  have h := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) S
  simp only [mgf, id] at h
  calc ∫ z, exp (S * z - S ^ 2 / 2) ∂(gaussianReal 0 1)
      = ∫ z, exp (-(S ^ 2 / 2)) * exp (S * z) ∂(gaussianReal 0 1) := by
        congr 1; funext z; rw [← exp_add]; ring_nf
    _ = 1 := by
        rw [integral_const_mul, h, ← exp_add]; simp

#print axioms integral_exp_tilt

lemma blackVal_ge (A B S : ℝ) (hA : 0 < A) (hB : 0 < B) (hS : 0 < S) :
    max (A - B) 0 ≤ blackVal A B S := by
  rw [← black_all A B S hA hB hS.le]
  have hint : Integrable (fun z => A * exp (S * z - S ^ 2 / 2) - B) (gaussianReal 0 1) :=
    ((integrable_exp_tilt S).const_mul A).sub (integrable_const B)
  apply max_le
  · calc A - B = ∫ z, (A * exp (S * z - S ^ 2 / 2) - B) ∂(gaussianReal 0 1) := by
          rw [integral_sub ((integrable_exp_tilt S).const_mul A) (integrable_const B),
            integral_const_mul, integral_exp_tilt, integral_const]
          simp
      _ ≤ _ := integral_mono hint hint.pos_part (fun z => le_max_left _ _)
  · exact integral_nonneg (fun z => le_max_right _ _)

#print axioms blackVal_ge

lemma blackVal_strictMonoOn (A B : ℝ) (hA : 0 < A) (hB : 0 < B) :
    StrictMonoOn (blackVal A B) (Ici 0) := by
  set f := fun S => A * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S)
        - B * stdNormalCDF ((log (A / B) + S ^ 2 / 2) / S - S) with hfdef
  have hf : StrictMonoOn f (Ioi 0) := by
    apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
    · exact fun x hx => (hasDerivAt_black A B x hA hB hx).continuousAt.continuousWithinAt
    · intro x hx
      rw [interior_Ioi] at hx
      rw [(hasDerivAt_black A B x hA hB hx).deriv]
      exact mul_pos hB (gaussianPDFReal_pos _ _ _ one_ne_zero)
  have heq : ∀ S, 0 < S → blackVal A B S = f S := by
    intro S hS; simp [blackVal, hS.ne', hfdef]
  intro x hx y hy hxy
  rw [mem_Ici] at hx
  rcases eq_or_lt_of_le hx with h0 | hx'
  · subst h0
    have hy' : 0 < y := hxy
    calc blackVal A B 0 = max (A - B) 0 := by simp [blackVal]
      _ ≤ blackVal A B (y / 2) := blackVal_ge _ _ _ hA hB (by positivity)
      _ < blackVal A B y := by
          rw [heq _ (by positivity), heq _ hy']
          exact hf (show (0:ℝ) < y / 2 by positivity) hy' (by linarith)
  · rw [heq x hx', heq y (hx'.trans hxy)]
    exact hf hx' (hx'.trans hxy) hxy

#print axioms blackVal_strictMonoOn

/-- **Margrabe's formula for the exchange option on two futures** (The formula; Why it works,
Steps 0 to 2 and the detailed proof). Under the pricing measure `Q`, crude's shock `Z₂` and a
second shock `Z⊥` are independent standard bell-curve draws, and gasoline's shock is
`Z₁ = ρZ₂ + √(1 - ρ²) Z⊥`, so the two shocks have the fixed correlation `ρ`, `-1 ≤ ρ ≤ 1`.
Both futures wander lognormally with fixed volatilities `σ₁`, `σ₂` and no drift:
`Fᵢ(T) = Fᵢ e^(-σᵢ²T/2 + σᵢ√T Zᵢ)`, with today's quotes `F₁ > 0`, `F₂ > 0` in the same unit.
Exercise is on expiry day only, `T > 0` years away, and the bank rate `r` is known, so one
discount `D = e^(-rT)` serves both legs. Then the option paying `max(F₁(T) - F₂(T), 0)` is worth
`D [F₁ N(d₁) - F₂ N(d₂)]`, whose only volatility is the ratio's, `√(σ₁² + σ₂² - 2ρσ₁σ₂)`, and
whose rate appears only in `D`. -/
theorem exchange_option_on_futures_is_margrabe
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₂ Zperp : Ω → ℝ}
    (F₁ F₂ r σ₁ σ₂ ρ T : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hρlo : -1 ≤ ρ) (hρhi : ρ ≤ 1)
    (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q) (hZperp : HasLaw Zperp (gaussianReal 0 1) Q)
    (hind : IndepFun Z₂ Zperp Q) :
    exp (-r * T) * ∫ ω, max (futuresAtExpiry F₁ σ₁ T (ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω)
        - futuresAtExpiry F₂ σ₂ T (Z₂ ω)) 0 ∂Q =
      margrabePrice r T F₁ F₂ σ₁ σ₂ ρ := by
  have hQ : IsProbabilityMeasure Q := hZ₂.isProbabilityMeasure
  have hP := hind.hasLaw_prod hZ₂ hZperp
  have hc : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt (by nlinarith)
  set c := √(1 - ρ ^ 2)
  set g : ℝ × ℝ → ℝ := fun p => max (futuresAtExpiry F₁ σ₁ T (ρ * p.1 + c * p.2)
    - futuresAtExpiry F₂ σ₂ T p.1) 0 with hg
  have hgc : Continuous g := by simp only [hg, futuresAtExpiry]; fun_prop
  have h1 : ∫ ω, max (futuresAtExpiry F₁ σ₁ T (ρ * Z₂ ω + c * Zperp ω)
        - futuresAtExpiry F₂ σ₂ T (Z₂ ω)) 0 ∂Q
      = ∫ p, g p ∂((gaussianReal 0 1).prod (gaussianReal 0 1)) :=
    hP.integral_comp hgc.aestronglyMeasurable
  rw [h1, price_eq _ _ _ _ _ _ _ hT.le, ratio_eq _ _ _ _ hT.le,
    ← core F₁ F₂ (σ₁ * √T) (σ₂ * √T) ρ c hF₁ hF₂ hc]
  congr 2
  funext p
  simp only [hg, fut_eq _ _ _ _ hT.le]

/-- **The ratio's volatility is the volatility of a difference** (Step 1). With the same shocks
(`Z₂`, `Z⊥` independent standard bell-curve draws, `Z₁ = ρZ₂ + √(1 - ρ²) Z⊥`, `-1 ≤ ρ ≤ 1`)
and `T > 0`, the two shocks have correlation `ρ`, and the random part of the log ratio
`ln F₁(T) - ln F₂(T)`, namely `σ₁√T Z₁ - σ₂√T Z₂`, has variance `(σ₁² + σ₂² - 2ρσ₁σ₂) T`. -/
theorem log_ratio_variance_is_ratio_vol_squared
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₂ Zperp : Ω → ℝ}
    (σ₁ σ₂ ρ T : ℝ) (hT : 0 < T) (hρlo : -1 ≤ ρ) (hρhi : ρ ≤ 1)
    (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q) (hZperp : HasLaw Zperp (gaussianReal 0 1) Q)
    (hind : IndepFun Z₂ Zperp Q) :
    covariance (fun ω => ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω) Z₂ Q = ρ ∧
      variance (fun ω => σ₁ * √T * (ρ * Z₂ ω + √(1 - ρ ^ 2) * Zperp ω) - σ₂ * √T * Z₂ ω) Q =
        (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) * T := by
  have hQ : IsProbabilityMeasure Q := hZ₂.isProbabilityMeasure
  have hc : √(1 - ρ ^ 2) ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt (by nlinarith)
  set c := √(1 - ρ ^ 2)
  have m2 : MemLp Z₂ 2 Q := hZ₂.memLp (memLp_id_gaussianReal' 2 (by simp))
  have mp : MemLp Zperp 2 Q := hZperp.memLp (memLp_id_gaussianReal' 2 (by simp))
  have v2 : variance Z₂ Q = 1 := by rw [hZ₂.variance_eq, variance_id_gaussianReal]; simp
  have vp : variance Zperp Q = 1 := by rw [hZperp.variance_eq, variance_id_gaussianReal]; simp
  constructor
  · show cov[(fun ω => ρ * Z₂ ω) + (fun ω => c * Zperp ω), Z₂; Q] = ρ
    rw [covariance_add_left (m2.const_mul ρ) (mp.const_mul c) m2, covariance_const_mul_left,
      covariance_const_mul_left, covariance_self m2.aestronglyMeasurable.aemeasurable,
      hind.symm.covariance_eq_zero mp m2, v2]
    ring
  · set a := σ₁ * √T * ρ - σ₂ * √T
    set b := σ₁ * √T * c
    have hfun : (fun ω => σ₁ * √T * (ρ * Z₂ ω + c * Zperp ω) - σ₂ * √T * Z₂ ω)
        = (fun ω => a * Z₂ ω) + (fun ω => b * Zperp ω) := by
      funext ω; simp only [Pi.add_apply, a, b]; ring
    rw [hfun, IndepFun.variance_add (m2.const_mul a) (mp.const_mul b)
      (hind.comp (measurable_const_mul a) (measurable_const_mul b)),
      variance_const_mul, variance_const_mul, v2, vp]
    have hT' := Real.sq_sqrt hT.le
    simp only [a, b]
    linear_combination (σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) * hT' + σ₁ ^ 2 * √T ^ 2 * hc

/-- **Correlation is the steering wheel** (Correlation is the steering wheel; the symbol table).
With both legs moving (`σ₁ > 0`, `σ₂ > 0`), today's quotes `F₁ > 0`, `F₂ > 0` and `T > 0`, and
everything else held fixed, Margrabe's price falls strictly as the correlation `ρ` rises across
`[-1, 1]`: the tighter the link, the cheaper the option. -/
theorem margrabe_price_strictly_falls_with_correlation
    (r T F₁ F₂ σ₁ σ₂ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) :
    StrictAntiOn (fun ρ => margrabePrice r T F₁ F₂ σ₁ σ₂ ρ) (Icc (-1) 1) := by
  intro ρ hρ ρ' hρ' hlt
  simp only
  rw [price_eq _ _ _ _ _ _ _ hT.le, price_eq _ _ _ _ _ _ _ hT.le]
  apply mul_lt_mul_of_pos_left _ (exp_pos _)
  have hσ := mul_pos hσ₁ hσ₂
  have h0 : 0 ≤ σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ' * σ₁ * σ₂ := by
    nlinarith [sq_nonneg (σ₁ - σ₂), hρ'.2]
  have hlt' : σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ' * σ₁ * σ₂ < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂ := by
    nlinarith
  apply blackVal_strictMonoOn F₁ F₂ hF₁ hF₂
  · exact mul_nonneg (Real.sqrt_nonneg _) (Real.sqrt_nonneg _)
  · exact mul_nonneg (Real.sqrt_nonneg _) (Real.sqrt_nonneg _)
  · exact mul_lt_mul_of_pos_right (Real.sqrt_lt_sqrt h0 hlt') (Real.sqrt_pos.2 hT)

/-! The card's exact worked numbers (fractions, no decimals). The refinery's crack:
F₁ = 100, F₂ = 90, σ₁ = 3/10, σ₂ = 1/4, ρ = 1/2, T = 1/2, r = 1/20. -/

-- Today's gap: 100 - 90 = 10 dollars a barrel.
example : (100 : ℤ) - 90 = 10 := by decide
-- Step 0: the payoff factors, max(100 - 90, 0) = 90 · max(100/90 - 1, 0).
example : max ((100 : ℚ) - 90) 0 = 90 * max (100 / 90 - 1) 0 := by norm_num
-- Step 1: ratio variance 0.09 + 0.0625 - 2(0.5)(0.30)(0.25) = 0.0775.
example : (3 / 10 : ℚ) ^ 2 + (1 / 4) ^ 2 - 2 * (1 / 2) * (3 / 10) * (1 / 4) = 31 / 400 := by
  norm_num
-- Step 3: Kirk's share a = 90/(90 + 10) = 0.9, so crude plus strike wiggles 0.9 × 25% = 22.5%.
example : (90 : ℚ) / (90 + 10) = 9 / 10 := by norm_num
example : (9 / 10 : ℚ) * (1 / 4) = 9 / 40 := by norm_num
-- Kirk's variance 0.09 - 2(0.5)(0.30)(0.225) + 0.225² = 0.073125.
example : (3 / 10 : ℚ) ^ 2 - 2 * (1 / 2) * (3 / 10) * (9 / 40) + (9 / 40) ^ 2 = 117 / 1600 := by
  norm_num
-- What breaks: the plus sign gives variance 0.2275; dropping correlation gives 0.1525.
example : (3 / 10 : ℚ) ^ 2 + (1 / 4) ^ 2 + 2 * (1 / 2) * (3 / 10) * (1 / 4) = 91 / 400 := by
  norm_num
example : (3 / 10 : ℚ) ^ 2 + (1 / 4) ^ 2 = 61 / 400 := by norm_num
-- Identical twins: both at 30 percent, correlation 1, the ratio variance is 0 ...
example : (3 / 10 : ℚ) ^ 2 + (3 / 10) ^ 2 - 2 * 1 * (3 / 10) * (3 / 10) = 0 := by norm_num
-- ... and the exchange option is worth today's gap of 10, discounted: 10 e^(-0.025).
example : margrabePrice (1 / 20) (1 / 2) 100 90 (3 / 10) (3 / 10) 1 = 10 * exp (-(1 / 40)) := by
  have h : ratioVol (3 / 10) (3 / 10) 1 = 0 := by norm_num [ratioVol]
  simp only [margrabePrice, h, zero_mul, ite_true]
  rw [mul_comm]
  norm_num
-- The payoff chart: gaps -10, 0, 5, 15, 30 pay 0, 0, 5, 15, 30 with no strike ...
example : max ((-10 : ℤ)) 0 = 0 ∧ max (0 : ℤ) 0 = 0 ∧ max (5 : ℤ) 0 = 5 ∧ max (15 : ℤ) 0 = 15 ∧
    max (30 : ℤ) 0 = 30 := by decide
-- ... and 0, 0, 0, 5, 20 with a strike of 10.
example : max ((-10 : ℤ) - 10) 0 = 0 ∧ max ((0 : ℤ) - 10) 0 = 0 ∧ max ((5 : ℤ) - 10) 0 = 0 ∧
    max ((15 : ℤ) - 10) 0 = 5 ∧ max ((30 : ℤ) - 10) 0 = 20 := by decide

#print axioms exchange_option_on_futures_is_margrabe
#print axioms log_ratio_variance_is_ratio_vol_squared
#print axioms margrabe_price_strictly_falls_with_correlation
