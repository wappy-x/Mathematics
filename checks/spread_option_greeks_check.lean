-- Greeks of a spread option: for Margrabe's zero-strike spread price D [F₁ N(d₁) - F₂ N(d₂)], the two deltas are D N(d₁) and -D N(d₂), the gamma table is D n(d₁)/(F₁v), -D n(d₁)/(F₂v), D n(d₁) F₁/(F₂²v) with a negative cross gamma, the two vegas and the correlation sensitivity are one vega times the slopes of the spread volatility, the correlation sensitivity equals σ₁σ₂T F₁F₂ times the cross gamma, and the deltas rebuild the price so a parallel percentage move leaves the hedged book unchanged.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def sprN (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `n(x)`: the standard bell curve's height at `x`. -/
noncomputable def sprPhi (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- The spread (ratio) volatility `σ = √(σ₁² + σ₂² - 2ρσ₁σ₂)`. -/
noncomputable def spreadVol (σ₁ σ₂ ρ : ℝ) : ℝ :=
  √(σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂)

/-- `d₁ = (ln(F₁/F₂) + v²/2) / v` with `v = σ√T`; then `d₂ = d₁ - v`. -/
noncomputable def spreadD1 (T F₁ F₂ σ₁ σ₂ ρ : ℝ) : ℝ :=
  (log (F₁ / F₂) + (spreadVol σ₁ σ₂ ρ * √T) ^ 2 / 2) / (spreadVol σ₁ σ₂ ρ * √T)

/-- Margrabe's zero-strike spread price on two futures, `V = D [F₁ N(d₁) - F₂ N(d₂)]`,
with `D = e^(-rT)`, `v = σ√T` and `d₂ = d₁ - v`. -/
noncomputable def spreadPrice (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) : ℝ :=
  exp (-r * T) * (F₁ * sprN (spreadD1 T F₁ F₂ σ₁ σ₂ ρ)
    - F₂ * sprN (spreadD1 T F₁ F₂ σ₁ σ₂ ρ - spreadVol σ₁ σ₂ ρ * √T))

lemma sprPhi_continuous : Continuous sprPhi := by
  unfold sprPhi gaussianPDFReal; fun_prop

lemma sprN_eq_integral (x : ℝ) : sprN x = ∫ t in Set.Iic x, sprPhi t := by
  unfold sprN sprPhi
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact integral_nonneg (fun _ => gaussianPDFReal_nonneg _ _ _)

lemma sprN_eq_interval (x : ℝ) : sprN x = sprN 0 + ∫ t in (0:ℝ)..x, sprPhi t := by
  rw [sprN_eq_integral, sprN_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic]
  · ring
  · exact (integrable_gaussianPDFReal 0 1).integrableOn
  · exact (integrable_gaussianPDFReal 0 1).integrableOn

lemma sprN_hasDerivAt (x : ℝ) : HasDerivAt sprN (sprPhi x) x := by
  have h := ((sprPhi_continuous.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add (sprN 0)
  exact h.congr_of_eventuallyEq (Filter.Eventually.of_forall sprN_eq_interval)

lemma sprPhi_pos (x : ℝ) : 0 < sprPhi x := gaussianPDFReal_pos _ _ _ one_ne_zero

lemma sprPhi_shift {F₁ F₂ w : ℝ} (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hw : w ≠ 0) :
    F₂ * sprPhi ((log (F₁ / F₂) + w ^ 2 / 2) / w - w)
      = F₁ * sprPhi ((log (F₁ / F₂) + w ^ 2 / 2) / w) := by
  unfold sprPhi gaussianPDFReal
  set d := (log (F₁ / F₂) + w ^ 2 / 2) / w with hd
  have hL : log (F₁ / F₂) = d * w - w ^ 2 / 2 := by rw [hd]; field_simp; ring
  have hexp : -(d - w - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))
      = -(d - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + log (F₁ / F₂) := by
    rw [hL]; push_cast; ring
  rw [hexp, exp_add, exp_log (div_pos hF₁ hF₂)]
  field_simp

lemma spreadVol_pos {σ₁ σ₂ ρ : ℝ} (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    0 < spreadVol σ₁ σ₂ ρ := Real.sqrt_pos.mpr hvar

lemma d1_hasDerivAt_left {F₁ F₂ w : ℝ} (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hw : w ≠ 0) :
    HasDerivAt (fun x => (log (x / F₂) + w ^ 2 / 2) / w) (1 / (F₁ * w)) F₁ := by
  have h := ((((hasDerivAt_id F₁).div_const F₂).log
    (div_pos hF₁ hF₂).ne').add_const (w ^ 2 / 2)).div_const w
  refine h.congr_deriv ?_
  simp only [id]
  field_simp

lemma d1_hasDerivAt_right {F₁ F₂ w : ℝ} (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hw : w ≠ 0) :
    HasDerivAt (fun y => (log (F₁ / y) + w ^ 2 / 2) / w) (-1 / (F₂ * w)) F₂ := by
  have h := ((((hasDerivAt_const F₂ F₁).div (hasDerivAt_id F₂) hF₂.ne').log
    (div_pos hF₁ hF₂).ne').add_const (w ^ 2 / 2)).div_const w
  refine h.congr_deriv ?_
  simp only [id, Pi.div_apply]
  field_simp
  ring

lemma d1_hasDerivAt_vol {L w : ℝ} (hw : w ≠ 0) :
    HasDerivAt (fun u => (L + u ^ 2 / 2) / u) ((w * w - (L + w ^ 2 / 2)) / w ^ 2) w := by
  have h := (((hasDerivAt_pow 2 w).div_const 2).const_add L).div (hasDerivAt_id w) hw
  refine h.congr_deriv ?_
  simp only [id]
  push_cast
  ring

lemma sprPhi_shift' {F₁ F₂ w : ℝ} (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hw : w ≠ 0) :
    sprPhi ((log (F₁ / F₂) + w ^ 2 / 2) / w - w)
      = F₁ * sprPhi ((log (F₁ / F₂) + w ^ 2 / 2) / w) / F₂ := by
  rw [eq_div_iff hF₂.ne', mul_comm]
  exact sprPhi_shift hF₁ hF₂ hw

lemma spread_delta1 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    HasDerivAt (fun x => spreadPrice r T x F₂ σ₁ σ₂ ρ)
      (exp (-r * T) * sprN (spreadD1 T F₁ F₂ σ₁ σ₂ ρ)) F₁ := by
  have hd := d1_hasDerivAt_left (w := spreadVol σ₁ σ₂ ρ * √T) hF₁ hF₂ hv
  have h := (((hasDerivAt_id F₁).mul ((sprN_hasDerivAt _).comp F₁ hd)).sub
    (((sprN_hasDerivAt _).comp F₁ (hd.sub_const (spreadVol σ₁ σ₂ ρ * √T))).const_mul F₂)).const_mul
    (exp (-r * T))
  refine h.congr_deriv ?_
  simp only [id, Function.comp_apply]
  rw [sprPhi_shift' hF₁ hF₂ hv]
  unfold spreadD1
  field_simp
  ring

lemma spread_delta2 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    HasDerivAt (fun y => spreadPrice r T F₁ y σ₁ σ₂ ρ)
      (-exp (-r * T) * sprN (spreadD1 T F₁ F₂ σ₁ σ₂ ρ - spreadVol σ₁ σ₂ ρ * √T)) F₂ := by
  have hd := d1_hasDerivAt_right (w := spreadVol σ₁ σ₂ ρ * √T) hF₁ hF₂ hv
  have h := ((((sprN_hasDerivAt _).comp F₂ hd).const_mul F₁).sub
    ((hasDerivAt_id F₂).mul ((sprN_hasDerivAt _).comp F₂
      (hd.sub_const (spreadVol σ₁ σ₂ ρ * √T))))).const_mul (exp (-r * T))
  refine h.congr_deriv ?_
  simp only [id, Function.comp_apply]
  rw [sprPhi_shift' hF₁ hF₂ hv]
  unfold spreadD1
  field_simp
  ring

lemma spread_gamma11 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    HasDerivAt (fun x => exp (-r * T) * sprN (spreadD1 T x F₂ σ₁ σ₂ ρ))
      (exp (-r * T) * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) / (F₁ * (spreadVol σ₁ σ₂ ρ * √T))) F₁ := by
  have hd := d1_hasDerivAt_left (w := spreadVol σ₁ σ₂ ρ * √T) hF₁ hF₂ hv
  have h := ((sprN_hasDerivAt _).comp F₁ hd).const_mul (exp (-r * T))
  refine h.congr_deriv ?_
  unfold spreadD1
  ring

lemma spread_gamma12 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    HasDerivAt (fun y => exp (-r * T) * sprN (spreadD1 T F₁ y σ₁ σ₂ ρ))
      (-(exp (-r * T) * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ)) / (F₂ * (spreadVol σ₁ σ₂ ρ * √T))) F₂ := by
  have hd := d1_hasDerivAt_right (w := spreadVol σ₁ σ₂ ρ * √T) hF₁ hF₂ hv
  have h := ((sprN_hasDerivAt _).comp F₂ hd).const_mul (exp (-r * T))
  refine h.congr_deriv ?_
  unfold spreadD1
  ring

lemma spread_gamma21 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    HasDerivAt (fun x => -exp (-r * T) * sprN (spreadD1 T x F₂ σ₁ σ₂ ρ - spreadVol σ₁ σ₂ ρ * √T))
      (-(exp (-r * T) * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ)) / (F₂ * (spreadVol σ₁ σ₂ ρ * √T))) F₁ := by
  have hd := d1_hasDerivAt_left (w := spreadVol σ₁ σ₂ ρ * √T) hF₁ hF₂ hv
  have h := ((sprN_hasDerivAt _).comp F₁ (hd.sub_const (spreadVol σ₁ σ₂ ρ * √T))).const_mul
    (-exp (-r * T))
  refine h.congr_deriv ?_
  rw [sprPhi_shift' hF₁ hF₂ hv]
  unfold spreadD1
  field_simp

lemma spread_gamma22 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    HasDerivAt (fun y => -exp (-r * T) * sprN (spreadD1 T F₁ y σ₁ σ₂ ρ - spreadVol σ₁ σ₂ ρ * √T))
      (exp (-r * T) * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) * F₁ / (F₂ ^ 2 * (spreadVol σ₁ σ₂ ρ * √T))) F₂ := by
  have hd := d1_hasDerivAt_right (w := spreadVol σ₁ σ₂ ρ * √T) hF₁ hF₂ hv
  have h := ((sprN_hasDerivAt _).comp F₂ (hd.sub_const (spreadVol σ₁ σ₂ ρ * √T))).const_mul
    (-exp (-r * T))
  refine h.congr_deriv ?_
  rw [sprPhi_shift' hF₁ hF₂ hv]
  unfold spreadD1
  field_simp

lemma spread_vol_slope {F₁ F₂ w : ℝ} (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hw : w ≠ 0) :
    HasDerivAt (fun u => F₁ * sprN ((log (F₁ / F₂) + u ^ 2 / 2) / u)
        - F₂ * sprN ((log (F₁ / F₂) + u ^ 2 / 2) / u - u))
      (F₁ * sprPhi ((log (F₁ / F₂) + w ^ 2 / 2) / w)) w := by
  have hd := d1_hasDerivAt_vol (L := log (F₁ / F₂)) hw
  have h := (((sprN_hasDerivAt _).comp w hd).const_mul F₁).sub
    (((sprN_hasDerivAt _).comp w (hd.sub (hasDerivAt_id w))).const_mul F₂)
  refine h.congr_deriv ?_
  simp only [id, Pi.sub_apply]
  rw [sprPhi_shift' hF₁ hF₂ hw]
  field_simp
  ring

lemma spread_vol_chain (r T F₁ F₂ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (vf : ℝ → ℝ) (v' s : ℝ)
    (hvf : HasDerivAt vf v' s) (hne : vf s ≠ 0) :
    HasDerivAt (fun s => exp (-r * T) * (F₁ * sprN ((log (F₁ / F₂) + vf s ^ 2 / 2) / vf s)
        - F₂ * sprN ((log (F₁ / F₂) + vf s ^ 2 / 2) / vf s - vf s)))
      (exp (-r * T) * (F₁ * sprPhi ((log (F₁ / F₂) + vf s ^ 2 / 2) / vf s) * v')) s := by
  have h := ((spread_vol_slope hF₁ hF₂ hne).comp s hvf).const_mul (exp (-r * T))
  exact h.congr_deriv (by ring)

lemma spread_vega1 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    HasDerivAt (fun s => spreadPrice r T F₁ F₂ s σ₂ ρ)
      (exp (-r * T) * F₁ * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) * √T *
        ((σ₁ - ρ * σ₂) / spreadVol σ₁ σ₂ ρ)) σ₁ := by
  have hinner : HasDerivAt (fun s => s ^ 2 + σ₂ ^ 2 - 2 * ρ * s * σ₂) (2 * σ₁ - 2 * ρ * σ₂) σ₁ :=
    (((hasDerivAt_pow 2 σ₁).add_const (σ₂ ^ 2)).sub
      (((hasDerivAt_id σ₁).const_mul (2 * ρ)).mul_const σ₂)).congr_deriv (by norm_num)
  have hs := spreadVol_pos hvar
  have hvf : HasDerivAt (fun s => spreadVol s σ₂ ρ * √T)
      ((σ₁ - ρ * σ₂) / spreadVol σ₁ σ₂ ρ * √T) σ₁ := by
    refine ((hinner.sqrt hvar.ne').mul_const (√T)).congr_deriv ?_
    unfold spreadVol at hs ⊢
    field_simp
  have hne : spreadVol σ₁ σ₂ ρ * √T ≠ 0 := (mul_pos hs (sqrt_pos.mpr hT)).ne'
  have h := spread_vol_chain r T F₁ F₂ hF₁ hF₂ _ _ σ₁ hvf hne
  refine h.congr_deriv ?_
  unfold spreadD1
  ring

lemma spread_vega2 (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    HasDerivAt (fun s => spreadPrice r T F₁ F₂ σ₁ s ρ)
      (exp (-r * T) * F₁ * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) * √T *
        ((σ₂ - ρ * σ₁) / spreadVol σ₁ σ₂ ρ)) σ₂ := by
  have hinner : HasDerivAt (fun s => σ₁ ^ 2 + s ^ 2 - 2 * ρ * σ₁ * s) (2 * σ₂ - 2 * ρ * σ₁) σ₂ :=
    (((hasDerivAt_pow 2 σ₂).const_add (σ₁ ^ 2)).sub
      ((hasDerivAt_id σ₂).const_mul (2 * ρ * σ₁))).congr_deriv (by norm_num)
  have hs := spreadVol_pos hvar
  have hvf : HasDerivAt (fun s => spreadVol σ₁ s ρ * √T)
      ((σ₂ - ρ * σ₁) / spreadVol σ₁ σ₂ ρ * √T) σ₂ := by
    refine ((hinner.sqrt hvar.ne').mul_const (√T)).congr_deriv ?_
    unfold spreadVol at hs ⊢
    field_simp
  have hne : spreadVol σ₁ σ₂ ρ * √T ≠ 0 := (mul_pos hs (sqrt_pos.mpr hT)).ne'
  have h := spread_vol_chain r T F₁ F₂ hF₁ hF₂ _ _ σ₂ hvf hne
  refine h.congr_deriv ?_
  unfold spreadD1
  ring

lemma spread_rho (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    HasDerivAt (fun p => spreadPrice r T F₁ F₂ σ₁ σ₂ p)
      (-(exp (-r * T) * F₁ * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) * √T) *
        (σ₁ * σ₂ / spreadVol σ₁ σ₂ ρ)) ρ := by
  have hinner : HasDerivAt (fun p => σ₁ ^ 2 + σ₂ ^ 2 - 2 * p * σ₁ * σ₂) (-(2 * σ₁ * σ₂)) ρ :=
    (((((hasDerivAt_id ρ).const_mul 2).mul_const σ₁).mul_const σ₂).const_sub
      (σ₁ ^ 2 + σ₂ ^ 2)).congr_deriv (by norm_num)
  have hs := spreadVol_pos hvar
  have hvf : HasDerivAt (fun p => spreadVol σ₁ σ₂ p * √T)
      (-(σ₁ * σ₂) / spreadVol σ₁ σ₂ ρ * √T) ρ := by
    refine ((hinner.sqrt hvar.ne').mul_const (√T)).congr_deriv ?_
    unfold spreadVol at hs ⊢
    field_simp
  have hne : spreadVol σ₁ σ₂ ρ * √T ≠ 0 := (mul_pos hs (sqrt_pos.mpr hT)).ne'
  have h := spread_vol_chain r T F₁ F₂ hF₁ hF₂ _ _ ρ hvf hne
  refine h.congr_deriv ?_
  unfold spreadD1
  ring

lemma spread_cross_gamma_deriv (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0) :
    deriv (fun y => deriv (fun x => spreadPrice r T x y σ₁ σ₂ ρ) F₁) F₂
      = -(exp (-r * T) * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ)) / (F₂ * (spreadVol σ₁ σ₂ ρ * √T)) := by
  have hev : (fun y => deriv (fun x => spreadPrice r T x y σ₁ σ₂ ρ) F₁)
      =ᶠ[nhds F₂] (fun y => exp (-r * T) * sprN (spreadD1 T F₁ y σ₁ σ₂ ρ)) := by
    filter_upwards [Ioi_mem_nhds hF₂] with y hy
    exact (spread_delta1 r T F₁ y σ₁ σ₂ ρ hF₁ hy hv).deriv
  exact ((spread_gamma12 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv).congr_of_eventuallyEq hev).deriv

#print axioms sprPhi_continuous
#print axioms sprN_eq_integral
#print axioms sprN_eq_interval
#print axioms sprN_hasDerivAt
#print axioms sprPhi_pos
#print axioms sprPhi_shift
#print axioms spreadVol_pos
#print axioms d1_hasDerivAt_left
#print axioms d1_hasDerivAt_right
#print axioms d1_hasDerivAt_vol
#print axioms sprPhi_shift'
#print axioms spread_delta1
#print axioms spread_delta2
#print axioms spread_gamma11
#print axioms spread_gamma12
#print axioms spread_gamma21
#print axioms spread_gamma22
#print axioms spread_vol_slope
#print axioms spread_vol_chain
#print axioms spread_vega1
#print axioms spread_vega2
#print axioms spread_rho
#print axioms spread_cross_gamma_deriv

/-- **The Greeks of a spread option** (The formula; Why it works, Steps 2, 4 and 5). Both futures
prices are lognormal with fixed volatilities `σ₁`, `σ₂` and one fixed correlation `ρ`, the strike
is zero, today's quotes are `F₁ > 0`, `F₂ > 0`, expiry is `T > 0` years away, the discount is
`D = e^(-rT)`, and the spread variance `σ₁² + σ₂² - 2ρσ₁σ₂` is positive, so `σ > 0` and
`v = σ√T > 0`. Then Margrabe's price has:
* one delta per leg, `Δ₁ = ∂V/∂F₁ = D N(d₁)` and `Δ₂ = ∂V/∂F₂ = -D N(d₂)`;
* a two-by-two gamma table: `Γ₁₁ = D n(d₁)/(F₁ v)`, the cross gamma
  `Γ₁₂ = ∂Δ₁/∂F₂ = ∂Δ₂/∂F₁ = -D n(d₁)/(F₂ v)`, which is negative, and `Γ₂₂ = D n(d₁) F₁/(F₂² v)`;
* a vega per leg, `ν₁ = D F₁ n(d₁) √T (σ₁ - ρσ₂)/σ` and `ν₂ = D F₁ n(d₁) √T (σ₂ - ρσ₁)/σ`;
* a correlation sensitivity `∂V/∂ρ = -D F₁ n(d₁) √T σ₁σ₂/σ`. -/
theorem spread_option_greeks
    (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    let D := exp (-r * T)
    let σ := spreadVol σ₁ σ₂ ρ
    let v := σ * √T
    let d₁ := spreadD1 T F₁ F₂ σ₁ σ₂ ρ
    -- deltas
    HasDerivAt (fun x => spreadPrice r T x F₂ σ₁ σ₂ ρ) (D * sprN d₁) F₁ ∧
    HasDerivAt (fun y => spreadPrice r T F₁ y σ₁ σ₂ ρ) (-D * sprN (d₁ - v)) F₂ ∧
    -- gamma table
    HasDerivAt (fun x => D * sprN (spreadD1 T x F₂ σ₁ σ₂ ρ)) (D * sprPhi d₁ / (F₁ * v)) F₁ ∧
    HasDerivAt (fun y => D * sprN (spreadD1 T F₁ y σ₁ σ₂ ρ)) (-(D * sprPhi d₁) / (F₂ * v)) F₂ ∧
    HasDerivAt (fun x => -D * sprN (spreadD1 T x F₂ σ₁ σ₂ ρ - v)) (-(D * sprPhi d₁) / (F₂ * v)) F₁ ∧
    HasDerivAt (fun y => -D * sprN (spreadD1 T F₁ y σ₁ σ₂ ρ - v))
      (D * sprPhi d₁ * F₁ / (F₂ ^ 2 * v)) F₂ ∧
    -(D * sprPhi d₁) / (F₂ * v) < 0 ∧
    -- vegas
    HasDerivAt (fun s => spreadPrice r T F₁ F₂ s σ₂ ρ)
      (D * F₁ * sprPhi d₁ * √T * ((σ₁ - ρ * σ₂) / σ)) σ₁ ∧
    HasDerivAt (fun s => spreadPrice r T F₁ F₂ σ₁ s ρ)
      (D * F₁ * sprPhi d₁ * √T * ((σ₂ - ρ * σ₁) / σ)) σ₂ ∧
    -- correlation sensitivity
    HasDerivAt (fun p => spreadPrice r T F₁ F₂ σ₁ σ₂ p)
      (-(D * F₁ * sprPhi d₁ * √T) * (σ₁ * σ₂ / σ)) ρ := by
  intro D σ v d₁
  have hvpos : 0 < spreadVol σ₁ σ₂ ρ * √T := mul_pos (spreadVol_pos hvar) (sqrt_pos.mpr hT)
  have hv := hvpos.ne'
  refine ⟨spread_delta1 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv,
    spread_delta2 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv,
    spread_gamma11 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv,
    spread_gamma12 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv,
    spread_gamma21 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv,
    spread_gamma22 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv, ?_,
    spread_vega1 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hT hvar,
    spread_vega2 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hT hvar,
    spread_rho r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hT hvar⟩
  have hφ := sprPhi_pos (spreadD1 T F₁ F₂ σ₁ σ₂ ρ)
  have hD := exp_pos (-r * T)
  have : 0 < exp (-r * T) * sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) / (F₂ * (spreadVol σ₁ σ₂ ρ * √T)) :=
    div_pos (mul_pos hD hφ) (mul_pos hF₂ hvpos)
  rw [neg_div]
  exact neg_neg_of_pos this

/-- **The bridge from correlation to cross gamma** (Why it works, Step 6). Under the same terms,
the price's slope in correlation is the cross gamma `∂²V/∂F₁∂F₂` scaled by both volatilities,
the time left and both prices: `∂V/∂ρ = σ₁σ₂ T F₁F₂ Γ₁₂`. -/
theorem correlation_sensitivity_eq_cross_gamma_scaled
    (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    HasDerivAt (fun p => spreadPrice r T F₁ F₂ σ₁ σ₂ p)
      (σ₁ * σ₂ * T * F₁ * F₂ *
        deriv (fun y => deriv (fun x => spreadPrice r T x y σ₁ σ₂ ρ) F₁) F₂) ρ := by
  have hs := spreadVol_pos hvar
  have hsT := sqrt_pos.mpr hT
  have hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0 := (mul_pos hs hsT).ne'
  rw [spread_cross_gamma_deriv r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv]
  refine (spread_rho r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hT hvar).congr_deriv ?_
  have hTT : √T * √T = T := mul_self_sqrt hT.le
  generalize exp (-r * T) = e
  generalize sprPhi (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) = P
  generalize spreadVol σ₁ σ₂ ρ = σ at hs ⊢
  generalize √T = q at hsT hTT ⊢
  rw [← hTT]
  field_simp

/-- **The deltas rebuild the price, and a parallel move costs the hedged book nothing**
(Why it works, Steps 3 and 4). Under the same terms, `V = F₁Δ₁ + F₂Δ₂`, and if both futures
prices are multiplied by the same `λ > 0`, the delta-hedged book's change
`V(λF₁, λF₂) - V(F₁, F₂) - Δ₁(λF₁ - F₁) - Δ₂(λF₂ - F₂)` is exactly zero. -/
theorem deltas_rebuild_price_and_parallel_move_is_free
    (r T F₁ F₂ σ₁ σ₂ ρ : ℝ) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂) (hT : 0 < T)
    (hvar : 0 < σ₁ ^ 2 + σ₂ ^ 2 - 2 * ρ * σ₁ * σ₂) :
    let Δ₁ := deriv (fun x => spreadPrice r T x F₂ σ₁ σ₂ ρ) F₁
    let Δ₂ := deriv (fun y => spreadPrice r T F₁ y σ₁ σ₂ ρ) F₂
    spreadPrice r T F₁ F₂ σ₁ σ₂ ρ = F₁ * Δ₁ + F₂ * Δ₂ ∧
      ∀ c : ℝ, 0 < c →
        spreadPrice r T (c * F₁) (c * F₂) σ₁ σ₂ ρ - spreadPrice r T F₁ F₂ σ₁ σ₂ ρ
          - Δ₁ * (c * F₁ - F₁) - Δ₂ * (c * F₂ - F₂) = 0 := by
  intro Δ₁ Δ₂
  have hv : spreadVol σ₁ σ₂ ρ * √T ≠ 0 :=
    (mul_pos (spreadVol_pos hvar) (sqrt_pos.mpr hT)).ne'
  have h1 : Δ₁ = exp (-r * T) * sprN (spreadD1 T F₁ F₂ σ₁ σ₂ ρ) :=
    (spread_delta1 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv).deriv
  have h2 : Δ₂ = -exp (-r * T) * sprN (spreadD1 T F₁ F₂ σ₁ σ₂ ρ - spreadVol σ₁ σ₂ ρ * √T) :=
    (spread_delta2 r T F₁ F₂ σ₁ σ₂ ρ hF₁ hF₂ hv).deriv
  have hscale : ∀ c : ℝ, 0 < c →
      spreadPrice r T (c * F₁) (c * F₂) σ₁ σ₂ ρ = c * spreadPrice r T F₁ F₂ σ₁ σ₂ ρ := by
    intro c hc
    unfold spreadPrice spreadD1
    rw [mul_div_mul_left _ _ hc.ne']
    ring
  refine ⟨?_, ?_⟩
  · rw [h1, h2]
    unfold spreadPrice
    ring
  · intro c hc
    rw [hscale c hc, h1, h2]
    unfold spreadPrice
    ring

/-! The card's exact worked numbers (fractions, no decimals). House crack:
F₁ = 100, F₂ = 90, σ₁ = 3/10, σ₂ = 1/4, ρ = 1/2, T = 1/2, r = 1/20. -/

-- Spread variance 0.09 + 0.0625 - 2(0.5)(0.30)(0.25) = 0.0775.
example : (3 / 10 : ℚ) ^ 2 + (1 / 4) ^ 2 - 2 * (1 / 2) * (3 / 10) * (1 / 4) = 31 / 400 := by
  norm_num
-- Chain-rule numerators: σ₁ - ρσ₂ = 0.175, σ₂ - ρσ₁ = 0.10, σ₁σ₂ = 0.075.
example : (3 / 10 : ℚ) - 1 / 2 * (1 / 4) = 7 / 40 := by norm_num
example : (1 / 4 : ℚ) - 1 / 2 * (3 / 10) = 1 / 10 := by norm_num
example : (3 / 10 : ℚ) * (1 / 4) = 3 / 40 := by norm_num
-- Crude's vega is positive here, since ρσ₁ = 0.15 is below σ₂ = 0.25.
example : (1 / 2 : ℚ) * (3 / 10) < 1 / 4 := by norm_num
-- Bridge factor σ₁σ₂ T F₁F₂ = 0.30 × 0.25 × 0.5 × 100 × 90 = 337.5.
example : (3 / 10 : ℚ) * (1 / 4) * (1 / 2) * 100 * 90 = 675 / 2 := by norm_num
-- Both legs up 5% (105 and 94.5) keep the ratio 100/90; both up 5 dollars (105 and 95) do not.
example : (105 : ℚ) / (189 / 2) = 100 / 90 := by norm_num
example : (105 : ℚ) / 95 ≠ 100 / 90 := by norm_num
-- Correlation re-marked from 0.5 to 0.3 is a change of -0.2.
example : (3 / 10 : ℚ) - 1 / 2 = -1 / 5 := by norm_num

#print axioms spread_option_greeks
#print axioms correlation_sensitivity_eq_cross_gamma_scaled
#print axioms deltas_rebuild_price_and_parallel_move_is_free
