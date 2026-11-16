-- Continuous wavelet transform: for a zero-average mother wavelet with a finite admissibility constant C_ψ, the scalogram summed over all times and scales (weight da/a²) equals C_ψ times the signal's energy when the signal or the wavelet is real; a finite C_ψ forces zero average, and zero average with a fast-fading wavelet gives a finite C_ψ.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Fourier.LpSpace
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds

open MeasureTheory Set
open scoped FourierTransform ENNReal

noncomputable section

namespace CWT

/-- The wiggle stretched by the scale `a` and slid to the time `b`:
`ψ_{a,b}(t) = (1/√a) ψ((t - b)/a)`. -/
def wiggle (ψ : ℝ → ℂ) (a b t : ℝ) : ℂ :=
  ((Real.sqrt a)⁻¹ : ℂ) * ψ ((t - b) / a)

/-- The wavelet coefficient `W_ψ f(a, b) = ∫ f(t) conj(ψ_{a,b}(t)) dt`. -/
def transform (ψ f : ℝ → ℂ) (a b : ℝ) : ℂ :=
  ∫ t, f t * starRingEnd ℂ (wiggle ψ a b t)

/-- The admissibility constant `C_ψ = ½ ∫ |ψ̂(ξ)|² / |ξ| dξ`, with Mathlib's hertz-form
transform `ψ̂(ξ) = ∫ ψ(t) e^(-2πiξt) dt`; a value in `[0, ∞]`, infinite when the integral is. -/
def admissibility (ψ : ℝ → ℂ) : ℝ≥0∞ :=
  2⁻¹ * ∫⁻ ξ, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ

lemma fourier_continuous' {g : ℝ → ℂ} (h1 : Integrable g) : Continuous (𝓕 g) :=
  VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar continuous_inner h1

#print axioms fourier_continuous'

lemma mult_formula {φ g : ℝ → ℂ} (hφ : Integrable φ) (hg : Integrable g) :
    ∫ x, 𝓕 φ x • g x = ∫ x, φ x • 𝓕 g x := by
  simpa using! VectorFourier.integral_fourierIntegral_smul_eq_flip (L := innerₗ ℝ)
    Real.continuous_fourierChar continuous_inner hφ hg

#print axioms mult_formula

lemma fourier_toLp_ae {g : ℝ → ℂ} (h1 : Integrable g) (h2 : MemLp g 2) :
    (𝓕 (h2.toLp g : Lp ℂ 2 (volume : Measure ℝ)) : Lp ℂ 2 (volume : Measure ℝ)) =ᵐ[volume] 𝓕 g := by
  apply ae_eq_of_integral_contDiff_smul_eq
  · exact (Lp.memLp _).locallyIntegrable (by norm_num)
  · exact (fourier_continuous' h1).locallyIntegrable
  intro g' g_smooth g_cpt
  have hg₁ : HasCompactSupport (Complex.ofRealCLM ∘ g') := g_cpt.comp_left rfl
  have hg₂ : ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) (Complex.ofRealCLM ∘ g') := Complex.ofRealCLM.contDiff.comp g_smooth
  set φ : SchwartzMap ℝ ℂ := hg₁.toSchwartzMap hg₂
  have hφ : ∀ x, φ x = (g' x : ℂ) := fun x => rfl
  calc ∫ x, g' x • (𝓕 (h2.toLp g : Lp ℂ 2 (volume : Measure ℝ)) : Lp ℂ 2 (volume : Measure ℝ)) x
      = Lp.toTemperedDistribution (𝓕 (h2.toLp g : Lp ℂ 2 (volume : Measure ℝ)) : Lp ℂ 2 (volume : Measure ℝ)) φ := by
        rw [Lp.toTemperedDistribution_apply]; simp [hφ]
    _ = 𝓕 (Lp.toTemperedDistribution (h2.toLp g)) φ := by
        rw [Lp.fourier_toTemperedDistribution_eq]
    _ = ∫ x, 𝓕 φ x • g x := by
        rw [TemperedDistribution.fourier_apply, Lp.toTemperedDistribution_apply]
        apply integral_congr_ae
        filter_upwards [h2.coeFn_toLp] with x hx
        rw [hx]
    _ = ∫ x, φ x • 𝓕 g x := by
        rw [SchwartzMap.fourier_coe]
        exact mult_formula φ.integrable h1
    _ = ∫ x, g' x • 𝓕 g x := by simp [hφ]

#print axioms fourier_toLp_ae

abbrev L2R := Lp ℂ 2 (volume : Measure ℝ)

lemma lintegral_sq_eq {f : ℝ → ℂ} (hf : AEStronglyMeasurable f) :
    ∫⁻ x, ‖f x‖ₑ ^ 2 = eLpNorm f 2 volume ^ 2 := by
  rw [eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num) hf]
  rw [← ENNReal.rpow_natCast, ← ENNReal.rpow_mul]
  simp

#print axioms lintegral_sq_eq

lemma plancherel_Lp (u : L2R) :
    ∫⁻ x, ‖(𝓕 u : L2R) x‖ₑ ^ 2 = ∫⁻ x, ‖u x‖ₑ ^ 2 := by
  rw [lintegral_sq_eq (Lp.aestronglyMeasurable _), lintegral_sq_eq (Lp.aestronglyMeasurable _)]
  have h := Lp.norm_fourier_eq u
  rw [Lp.norm_def, Lp.norm_def] at h
  rw [(ENNReal.toReal_eq_toReal_iff' (Lp.eLpNorm_ne_top _) (Lp.eLpNorm_ne_top _)).1 h]

#print axioms plancherel_Lp

lemma wiggle_integrable {ψ : ℝ → ℂ} (hψ : Integrable ψ) {a : ℝ} (ha : 0 < a) (b : ℝ) :
    Integrable (wiggle ψ a b) := by
  unfold wiggle
  exact (((hψ.comp_div ha.ne').comp_sub_right b)).const_mul _

#print axioms wiggle_integrable

lemma wiggle_memLp {ψ : ℝ → ℂ} (hψ : Integrable ψ) (hψ2 : MemLp ψ 2) {a : ℝ} (ha : 0 < a)
    (b : ℝ) : MemLp (wiggle ψ a b) 2 := by
  rw [memLp_two_iff_integrable_sq_norm (wiggle_integrable hψ ha b).aestronglyMeasurable]
  have h := (memLp_two_iff_integrable_sq_norm hψ.aestronglyMeasurable).1 hψ2
  have h2 := ((h.comp_div ha.ne').comp_sub_right b).const_mul (‖((Real.sqrt a)⁻¹ : ℂ)‖ ^ 2)
  refine h2.congr (Filter.Eventually.of_forall fun t => ?_)
  simp only [wiggle, norm_mul, mul_pow]

#print axioms wiggle_memLp

lemma wiggle_fourier (ψ : ℝ → ℂ) {a : ℝ} (ha : 0 < a) (b ξ : ℝ) :
    𝓕 (wiggle ψ a b) ξ =
      (Real.sqrt a : ℂ) * ((Real.fourierChar (-(b * ξ)) : Circle) : ℂ) * 𝓕 ψ (a * ξ) := by
  rw [Real.fourier_real_eq, Real.fourier_real_eq]
  set c : ℂ := ((Real.fourierChar (-(b * ξ)) : Circle) : ℂ) with hc
  set g : ℝ → ℂ := fun s => Real.fourierChar (-((s + b) * ξ)) • wiggle ψ a b (s + b) with hg
  set h : ℝ → ℂ := fun u => ((Real.sqrt a)⁻¹ : ℂ) * c *
        (Real.fourierChar (-(u * (a * ξ))) • ψ u) with hh
  have hs : (a : ℂ) * (Real.sqrt a : ℂ)⁻¹ = Real.sqrt a := by
    have h1 : (0:ℝ) < Real.sqrt a := Real.sqrt_pos.2 ha
    have h2 : ((Real.sqrt a : ℂ)) ≠ 0 := by exact_mod_cast h1.ne'
    field_simp
    norm_cast
    exact (Real.sq_sqrt ha.le).symm
  calc ∫ v : ℝ, Real.fourierChar (-(v * ξ)) • wiggle ψ a b v
      = ∫ v : ℝ, g (v - b) := by
        congr 1; funext v; simp only [hg, sub_add_cancel]
    _ = ∫ s : ℝ, g s := integral_sub_right_eq_self g b
    _ = ∫ s : ℝ, h (s / a) := by
        congr 1; funext s
        simp only [hg, hh, hc, wiggle, add_sub_cancel_right, Circle.smul_def, smul_eq_mul]
        have : -((s + b) * ξ) = -(b * ξ) + -(s / a * (a * ξ)) := by field_simp; ring
        rw [this, Real.fourierChar.map_add_eq_mul]
        push_cast; ring
    _ = |a| • ∫ u : ℝ, h u := Measure.integral_comp_div h a
    _ = _ := by
        rw [hh, integral_const_mul, abs_of_pos ha, Complex.real_smul, ← mul_assoc, ← mul_assoc, hs]

#print axioms wiggle_fourier

lemma inner_repr {w f : ℝ → ℂ} (hw : MemLp w 2) (hf : MemLp f 2) :
    ∫ t, f t * starRingEnd ℂ (w t) =
      ∫ ξ, (𝓕 (hf.toLp f) : L2R) ξ * starRingEnd ℂ ((𝓕 (hw.toLp w) : L2R) ξ) := by
  have h := Lp.inner_fourier_eq (hw.toLp w) (hf.toLp f)
  rw [L2.inner_def, L2.inner_def] at h
  simp only [RCLike.inner_apply] at h
  rw [h]
  apply integral_congr_ae
  filter_upwards [hw.coeFn_toLp, hf.coeFn_toLp] with t h1 h2
  rw [h1, h2]

#print axioms inner_repr

lemma plancherel_fun {g : ℝ → ℂ} (h1 : Integrable g) (h2 : MemLp g 2) :
    ∫⁻ ξ, ‖𝓕 g ξ‖ₑ ^ 2 = ∫⁻ x, ‖g x‖ₑ ^ 2 := by
  calc ∫⁻ ξ, ‖𝓕 g ξ‖ₑ ^ 2 = ∫⁻ ξ, ‖(𝓕 (h2.toLp g) : L2R) ξ‖ₑ ^ 2 := by
        apply lintegral_congr_ae
        filter_upwards [fourier_toLp_ae h1 h2] with ξ h
        rw [h]
    _ = ∫⁻ x, ‖(h2.toLp g : L2R) x‖ₑ ^ 2 := plancherel_Lp _
    _ = _ := by
        apply lintegral_congr_ae
        filter_upwards [h2.coeFn_toLp] with x h
        rw [h]

#print axioms plancherel_fun

lemma memLp_fourier {g : ℝ → ℂ} (h1 : Integrable g) (h2 : MemLp g 2) : MemLp (𝓕 g) 2 :=
  (Lp.memLp (𝓕 (h2.toLp g : L2R) : L2R)).ae_eq (fourier_toLp_ae h1 h2)

#print axioms memLp_fourier

/-- The Fourier-side integrand for scale `a`. -/
def Gfun (ψ F : ℝ → ℂ) (a ξ : ℝ) : ℂ := starRingEnd ℂ (𝓕 ψ (a * ξ)) * F ξ

lemma memLp_fourier_scale {ψ : ℝ → ℂ} (hψ : Integrable ψ) (hψ2 : MemLp ψ 2) {a : ℝ}
    (ha : 0 < a) : MemLp (fun ξ => 𝓕 ψ (a * ξ)) 2 := by
  have hc : Continuous fun ξ => 𝓕 ψ (a * ξ) :=
    (fourier_continuous' hψ).comp (continuous_const.mul continuous_id)
  rw [memLp_two_iff_integrable_sq_norm hc.aestronglyMeasurable]
  have h := (memLp_two_iff_integrable_sq_norm (fourier_continuous' hψ).aestronglyMeasurable).1
    (memLp_fourier hψ hψ2)
  exact h.comp_mul_left' ha.ne'

#print axioms memLp_fourier_scale

lemma Gfun_integrable {ψ F : ℝ → ℂ} (hψ : Integrable ψ) (hψ2 : MemLp ψ 2) (hF : MemLp F 2)
    {a : ℝ} (ha : 0 < a) : Integrable (Gfun ψ F a) := by
  have h1 : MemLp (fun ξ => starRingEnd ℂ (𝓕 ψ (a * ξ))) 2 := by
    refine (memLp_fourier_scale hψ hψ2 ha).of_le ?_ (Filter.Eventually.of_forall fun ξ => ?_)
    · exact (Complex.continuous_conj.comp ((fourier_continuous' hψ).comp
        (continuous_const.mul continuous_id))).aestronglyMeasurable
    · simp
  exact h1.integrable_mul hF

#print axioms Gfun_integrable

lemma Gfun_memLp {ψ F : ℝ → ℂ} (hψ : Integrable ψ) (hF : MemLp F 2) (a : ℝ) :
    MemLp (Gfun ψ F a) 2 := by
  refine (hF.const_mul (((∫ t, ‖ψ t‖ : ℝ)) : ℂ)).of_le ?_ (Filter.Eventually.of_forall fun ξ => ?_)
  · exact (Complex.continuous_conj.comp ((fourier_continuous' hψ).comp
        (continuous_const.mul continuous_id))).aestronglyMeasurable.mul hF.aestronglyMeasurable
  · simp only [Gfun, norm_mul, RCLike.norm_conj, Complex.norm_real, Real.norm_eq_abs]
    rw [abs_of_nonneg (integral_nonneg fun t => norm_nonneg _)]
    exact mul_le_mul_of_nonneg_right (Real.norm_fourier_le_integral_norm _ _) (norm_nonneg _)

#print axioms Gfun_memLp

/-- The `L²` Fourier transform of `f`, as a function. -/
def FL {f : ℝ → ℂ} (hf : MemLp f 2) : ℝ → ℂ := (𝓕 (hf.toLp f : L2R) : L2R)

lemma transform_eq {ψ f : ℝ → ℂ} (hψ : Integrable ψ) (hψ2 : MemLp ψ 2) (hf : MemLp f 2)
    {a : ℝ} (ha : 0 < a) (b : ℝ) :
    transform ψ f a b =
      (Real.sqrt a : ℂ) * 𝓕 (Gfun ψ (FL hf) a) (-b) := by
  unfold transform
  rw [inner_repr (wiggle_memLp hψ hψ2 ha b) hf, Real.fourier_real_eq, ← integral_const_mul]
  apply integral_congr_ae
  filter_upwards [fourier_toLp_ae (wiggle_integrable hψ ha b) (wiggle_memLp hψ hψ2 ha b)]
    with ξ hξ
  rw [hξ, wiggle_fourier ψ ha b ξ]
  simp only [Gfun, FL, map_mul, Complex.conj_ofReal, Circle.smul_def, smul_eq_mul]
  have : -(ξ * -b) = -(-(b * ξ)) := by ring
  rw [this, Circle.starRingEnd_addChar]
  ring

#print axioms transform_eq

lemma FL_memLp {f : ℝ → ℂ} (hf : MemLp f 2) : MemLp (FL hf) 2 := Lp.memLp _

#print axioms FL_memLp

lemma FL_aemeas {f : ℝ → ℂ} (hf : MemLp f 2) : AEMeasurable (fun ξ => ‖FL hf ξ‖ₑ ^ 2) :=
  ((FL_memLp hf).aestronglyMeasurable.enorm).pow_const 2

#print axioms FL_aemeas

lemma lintegral_FL {f : ℝ → ℂ} (hf : MemLp f 2) :
    ∫⁻ ξ, ‖FL hf ξ‖ₑ ^ 2 = ∫⁻ t, ‖f t‖ₑ ^ 2 := by
  rw [FL, plancherel_Lp]
  apply lintegral_congr_ae
  filter_upwards [hf.coeFn_toLp] with x h
  rw [h]

#print axioms lintegral_FL

lemma lintegral_transform_sq {ψ f : ℝ → ℂ} (hψ : Integrable ψ) (hψ2 : MemLp ψ 2)
    (hf : MemLp f 2) {a : ℝ} (ha : 0 < a) :
    ∫⁻ b, ‖transform ψ f a b‖ₑ ^ 2 =
      ENNReal.ofReal a * ∫⁻ ξ, ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 * ‖FL hf ξ‖ₑ ^ 2 := by
  simp_rw [transform_eq hψ hψ2 hf ha, enorm_mul, mul_pow]
  rw [lintegral_const_mul' _ _ (by simp)]
  congr 1
  · rw [← ofReal_norm, Complex.norm_real, Real.norm_of_nonneg (Real.sqrt_nonneg a),
      ← ENNReal.ofReal_pow (Real.sqrt_nonneg a), Real.sq_sqrt ha.le]
  · rw [lintegral_neg_eq_self (fun b => ‖𝓕 (Gfun ψ (FL hf) a) b‖ₑ ^ 2)]
    rw [plancherel_fun (Gfun_integrable hψ hψ2 (FL_memLp hf) ha) (Gfun_memLp hψ (FL_memLp hf) a)]
    congr 1; funext ξ
    simp only [Gfun, enorm_mul, RCLike.enorm_conj, mul_pow]

#print axioms lintegral_transform_sq

lemma lintegral_Ioi_scale (g : ℝ → ℝ≥0∞) {c : ℝ} (hc : 0 < c) :
    ∫⁻ a in Ioi 0, g (a * c) / ENNReal.ofReal a = ∫⁻ u in Ioi 0, g u / ENNReal.ofReal u := by
  rw [← lintegral_indicator measurableSet_Ioi, ← lintegral_indicator measurableSet_Ioi]
  set h : ℝ → ℝ≥0∞ := fun u => (Ioi 0).indicator (fun u => g u / ENNReal.ofReal u) u *
    ENNReal.ofReal c with hh
  have key : (fun a => (Ioi 0).indicator (fun a => g (a * c) / ENNReal.ofReal a) a) =
      fun a => h (a * c) := by
    funext a
    by_cases ha : 0 < a
    · have hac : 0 < a * c := mul_pos ha hc
      rw [hh]
      simp only [indicator_of_mem (show a ∈ Ioi (0:ℝ) from ha),
        indicator_of_mem (show a * c ∈ Ioi (0:ℝ) from hac)]
      rw [ENNReal.ofReal_mul ha.le, ENNReal.div_eq_inv_mul, ENNReal.div_eq_inv_mul,
        ENNReal.mul_inv (Or.inl (by simpa using ha)) (Or.inl ENNReal.ofReal_ne_top)]
      have hc0 : ENNReal.ofReal c ≠ 0 := by simpa using hc
      calc (ENNReal.ofReal a)⁻¹ * g (a * c)
          = (ENNReal.ofReal a)⁻¹ * g (a * c) * ((ENNReal.ofReal c)⁻¹ * ENNReal.ofReal c) := by
            rw [ENNReal.inv_mul_cancel hc0 ENNReal.ofReal_ne_top, mul_one]
        _ = _ := by ring
    · have hac : ¬ 0 < a * c := fun h' => ha (pos_of_mul_pos_left h' hc.le)
      rw [hh]
      simp only [indicator_of_notMem (show a ∉ Ioi (0:ℝ) from ha),
        indicator_of_notMem (show a * c ∉ Ioi (0:ℝ) from hac), zero_mul]
  rw [key]
  have emb : MeasurableEmbedding (fun a : ℝ => a * c) :=
    (Homeomorph.mulRight₀ c hc.ne').measurableEmbedding
  rw [← emb.lintegral_map, Real.map_volume_mul_right hc.ne', lintegral_smul_measure, hh,
    lintegral_mul_const' _ _ ENNReal.ofReal_ne_top, abs_of_pos (inv_pos.2 hc)]
  rw [smul_eq_mul, mul_comm, mul_assoc, ← ENNReal.ofReal_mul hc.le, mul_inv_cancel₀ hc.ne', ENNReal.ofReal_one,
    mul_one]

#print axioms lintegral_Ioi_scale

lemma lintegral_Ioi_neg (k : ℝ → ℝ≥0∞) : ∫⁻ u in Ioi 0, k (-u) = ∫⁻ u in Iio 0, k u := by
  rw [← lintegral_indicator measurableSet_Ioi, ← lintegral_indicator measurableSet_Iio,
    ← lintegral_neg_eq_self ((Iio 0).indicator k)]
  congr 1; funext u
  by_cases hu : 0 < u
  · rw [indicator_of_mem (show u ∈ Ioi (0:ℝ) from hu),
      indicator_of_mem (show -u ∈ Iio (0:ℝ) by simpa using hu)]
  · rw [indicator_of_notMem (show u ∉ Ioi (0:ℝ) from hu),
      indicator_of_notMem (show -u ∉ Iio (0:ℝ) by simpa using hu)]

#print axioms lintegral_Ioi_neg

lemma lintegral_Iio_neg (k : ℝ → ℝ≥0∞) : ∫⁻ u in Iio 0, k (-u) = ∫⁻ u in Ioi 0, k u := by
  have := lintegral_Ioi_neg (fun u => k (-u))
  simp only [neg_neg] at this
  exact this.symm

#print axioms lintegral_Iio_neg

lemma lintegral_Ioi_scale_neg (g : ℝ → ℝ≥0∞) {c : ℝ} (hc : c < 0) :
    ∫⁻ a in Ioi 0, g (a * c) / ENNReal.ofReal a =
      ∫⁻ u in Iio 0, g u / ENNReal.ofReal (-u) := by
  have h1 := lintegral_Ioi_scale (fun u => g (-u)) (neg_pos.2 hc)
  simp only [mul_neg, neg_neg] at h1
  rw [h1, ← lintegral_Ioi_neg (fun u => g u / ENNReal.ofReal (-u))]
  simp only [neg_neg]

#print axioms lintegral_Ioi_scale_neg

lemma lintegral_split (k : ℝ → ℝ≥0∞) :
    ∫⁻ ξ, k ξ = (∫⁻ ξ in Ioi 0, k ξ) + ∫⁻ ξ in Iio 0, k ξ := by
  have h := lintegral_add_compl (μ := volume) k (measurableSet_Ioi (a := (0:ℝ)))
  rw [compl_Ioi] at h
  rw [← h, setLIntegral_congr (Iio_ae_eq_Iic (a := (0:ℝ))).symm]

#print axioms lintegral_split

/-- The positive-frequency half of the admissibility integral. -/
def Apos (ψ : ℝ → ℂ) : ℝ≥0∞ := ∫⁻ u in Ioi 0, ‖𝓕 ψ u‖ₑ ^ 2 / ENNReal.ofReal u

/-- The negative-frequency half of the admissibility integral. -/
def Aneg (ψ : ℝ → ℂ) : ℝ≥0∞ := ∫⁻ u in Iio 0, ‖𝓕 ψ u‖ₑ ^ 2 / ENNReal.ofReal (-u)

lemma admissibility_eq (ψ : ℝ → ℂ) : admissibility ψ = 2⁻¹ * (Apos ψ + Aneg ψ) := by
  have h1 : ∫⁻ ξ in Ioi 0, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ = Apos ψ := by
    refine setLIntegral_congr_fun (measurableSet_Ioi (a := (0:ℝ))) (fun ξ hξ => ?_)
    rw [Real.enorm_eq_ofReal (le_of_lt hξ)]
  have h2 : ∫⁻ ξ in Iio 0, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ = Aneg ψ := by
    refine setLIntegral_congr_fun (measurableSet_Iio (a := (0:ℝ))) (fun ξ hξ => ?_)
    rw [Real.enorm_eq_ofReal_abs, abs_of_neg hξ]
  rw [admissibility, lintegral_split, h1, h2]

#print axioms admissibility_eq

lemma scalogram_formula {ψ f : ℝ → ℂ} (hψ : Integrable ψ) (hψ2 : MemLp ψ 2) (hf : MemLp f 2) :
    ∫⁻ a in Ioi (0 : ℝ), (∫⁻ b, ‖transform ψ f a b‖ₑ ^ 2) / ENNReal.ofReal (a ^ 2) =
      Apos ψ * (∫⁻ ξ in Ioi 0, ‖FL hf ξ‖ₑ ^ 2) + Aneg ψ * ∫⁻ ξ in Iio 0, ‖FL hf ξ‖ₑ ^ 2 := by
  have step1 : ∀ a ∈ Ioi (0:ℝ), (∫⁻ b, ‖transform ψ f a b‖ₑ ^ 2) / ENNReal.ofReal (a ^ 2) =
      ∫⁻ ξ, ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 * ‖FL hf ξ‖ₑ ^ 2 / ENNReal.ofReal a := by
    intro a ha
    have ha' : (0:ℝ) < a := ha
    have h0 : ENNReal.ofReal a ≠ 0 := by simpa using ha'
    rw [lintegral_transform_sq hψ hψ2 hf ha',
      show ENNReal.ofReal (a ^ 2) = ENNReal.ofReal a * ENNReal.ofReal a by
        rw [sq, ENNReal.ofReal_mul ha'.le],
      ENNReal.mul_div_mul_left _ _ h0 ENNReal.ofReal_ne_top]
    simp_rw [div_eq_mul_inv]
    rw [lintegral_mul_const' _ _ (ENNReal.inv_ne_top.2 h0)]
  rw [setLIntegral_congr_fun (measurableSet_Ioi (a := (0:ℝ))) step1]
  have hmeas : AEMeasurable (Function.uncurry fun (a ξ : ℝ) =>
      ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 * ‖FL hf ξ‖ₑ ^ 2 / ENNReal.ofReal a)
      ((volume.restrict (Ioi (0:ℝ))).prod volume) := by
    have c1 : Measurable (fun p : ℝ × ℝ => ‖𝓕 ψ (p.1 * p.2)‖ₑ ^ 2) :=
      ((fourier_continuous' hψ).comp (continuous_fst.mul continuous_snd)).measurable.enorm.pow_const 2
    have c2 : AEMeasurable (fun p : ℝ × ℝ => ‖FL hf p.2‖ₑ ^ 2)
        ((volume.restrict (Ioi (0:ℝ))).prod volume) := (FL_aemeas hf).comp_snd
    have c3 : Measurable (fun p : ℝ × ℝ => ENNReal.ofReal p.1) :=
      ENNReal.measurable_ofReal.comp measurable_fst
    exact (c1.aemeasurable.mul c2).div c3.aemeasurable
  rw [lintegral_lintegral_swap hmeas]
  have step2 : ∀ ξ : ℝ, ∫⁻ a in Ioi (0:ℝ), ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 * ‖FL hf ξ‖ₑ ^ 2 / ENNReal.ofReal a =
      ‖FL hf ξ‖ₑ ^ 2 * ∫⁻ a in Ioi (0:ℝ), ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 / ENNReal.ofReal a := by
    intro ξ
    rw [← lintegral_const_mul' _ _ (by simp)]
    congr 1; funext a
    rw [mul_comm, mul_div_assoc]
  simp_rw [step2]
  rw [lintegral_split]
  have hpos : ∀ ξ ∈ Ioi (0:ℝ), ‖FL hf ξ‖ₑ ^ 2 * ∫⁻ a in Ioi (0:ℝ), ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 /
      ENNReal.ofReal a = Apos ψ * ‖FL hf ξ‖ₑ ^ 2 := by
    intro ξ hξ
    rw [mul_comm, Apos, lintegral_Ioi_scale (fun u => ‖𝓕 ψ u‖ₑ ^ 2) hξ]
  have hneg : ∀ ξ ∈ Iio (0:ℝ), ‖FL hf ξ‖ₑ ^ 2 * ∫⁻ a in Ioi (0:ℝ), ‖𝓕 ψ (a * ξ)‖ₑ ^ 2 /
      ENNReal.ofReal a = Aneg ψ * ‖FL hf ξ‖ₑ ^ 2 := by
    intro ξ hξ
    rw [mul_comm, Aneg, lintegral_Ioi_scale_neg (fun u => ‖𝓕 ψ u‖ₑ ^ 2) hξ]
  rw [setLIntegral_congr_fun (measurableSet_Ioi (a := (0:ℝ))) hpos,
    setLIntegral_congr_fun (measurableSet_Iio (a := (0:ℝ))) hneg,
    lintegral_const_mul'' _ (FL_aemeas hf).restrict, lintegral_const_mul'' _ (FL_aemeas hf).restrict]

#print axioms scalogram_formula

lemma fourier_conj (ψ : ℝ → ℂ) (u : ℝ) :
    𝓕 (fun t => starRingEnd ℂ (ψ t)) u = starRingEnd ℂ (𝓕 ψ (-u)) := by
  rw [Real.fourier_real_eq, Real.fourier_real_eq, ← integral_conj]
  congr 1; funext v
  simp only [Circle.smul_def, smul_eq_mul, map_mul, Circle.starRingEnd_addChar]
  congr 3; ring

#print axioms fourier_conj

lemma Apos_conj (ψ : ℝ → ℂ) : Apos (fun t => starRingEnd ℂ (ψ t)) = Aneg ψ := by
  rw [Apos, Aneg]
  simp_rw [fourier_conj, RCLike.enorm_conj]
  have := lintegral_Ioi_neg (fun u => ‖𝓕 ψ u‖ₑ ^ 2 / ENNReal.ofReal (-u))
  simp only [neg_neg] at this
  exact this

#print axioms Apos_conj

lemma Aneg_conj (ψ : ℝ → ℂ) : Aneg (fun t => starRingEnd ℂ (ψ t)) = Apos ψ := by
  rw [Apos, Aneg]
  simp_rw [fourier_conj, RCLike.enorm_conj]
  exact lintegral_Iio_neg (fun u => ‖𝓕 ψ u‖ₑ ^ 2 / ENNReal.ofReal u)

#print axioms Aneg_conj

lemma transform_conj_enorm {ψ f : ℝ → ℂ}
    (hreal : (∀ t, (f t).im = 0) ∨ (∀ t, (ψ t).im = 0)) (a b : ℝ) :
    ‖transform (fun t => starRingEnd ℂ (ψ t)) f a b‖ₑ = ‖transform ψ f a b‖ₑ := by
  rcases hreal with hf | hψ
  · have : transform (fun t => starRingEnd ℂ (ψ t)) f a b = starRingEnd ℂ (transform ψ f a b) := by
      unfold transform
      rw [← integral_conj]
      congr 1; funext t
      simp only [wiggle, map_mul, map_inv₀, Complex.conj_ofReal, Complex.conj_conj,
        Complex.conj_eq_iff_im.2 (hf t)]
    rw [this, RCLike.enorm_conj]
  · have : (fun t => starRingEnd ℂ (ψ t)) = ψ := funext fun t => Complex.conj_eq_iff_im.2 (hψ t)
    rw [this]

#print axioms transform_conj_enorm

lemma fourier_zero (ψ : ℝ → ℂ) : 𝓕 ψ 0 = ∫ t, ψ t := by
  rw [Real.fourier_real_eq]; simp

#print axioms fourier_zero

lemma lintegral_inv_Ioo_eq_top {δ : ℝ} (hδ : 0 < δ) :
    ∫⁻ ξ in Ioo 0 δ, (ENNReal.ofReal ξ)⁻¹ = ∞ := by
  by_contra h
  have hfin : ∫⁻ ξ in Ioo 0 δ, ENNReal.ofReal (ξ⁻¹) < ∞ := by
    rw [setLIntegral_congr_fun (measurableSet_Ioo (a := (0:ℝ)) (b := δ))
      (fun ξ hξ => ENNReal.ofReal_inv_of_pos hξ.1)]
    exact lt_top_iff_ne_top.2 h
  have hint : IntegrableOn (fun x : ℝ => x⁻¹) (Ioo 0 δ) := by
    refine ⟨measurable_inv.aestronglyMeasurable, ?_⟩
    rw [hasFiniteIntegral_iff_ofReal (ae_restrict_of_forall_mem measurableSet_Ioo
      (fun x hx => (inv_pos.2 hx.1).le))]
    exact hfin
  have := (intervalIntegrable_iff_integrableOn_Ioo_of_le hδ.le).2 hint
  rw [intervalIntegrable_inv_iff] at this
  rcases this with h | h
  · linarith
  · exact h Set.left_mem_uIcc

#print axioms lintegral_inv_Ioo_eq_top

lemma enorm_sq_eq (z : ℂ) : ‖z‖ₑ ^ 2 = ENNReal.ofReal (‖z‖ ^ 2) := by
  rw [← ofReal_norm, ENNReal.ofReal_pow (norm_nonneg _)]

#print axioms enorm_sq_eq

lemma fourier_bound {ψ : ℝ → ℂ} (hψ : Integrable ψ)
    (hmoment : Integrable (fun t : ℝ => |t| * ‖ψ t‖)) (hmean : ∫ t, ψ t = 0) (ξ : ℝ) :
    ‖𝓕 ψ ξ‖ ≤ 2 * Real.pi * |ξ| * ∫ t, |t| * ‖ψ t‖ := by
  have hint : Integrable (fun t : ℝ => Real.fourierChar (-(t * ξ)) • ψ t) := by
    refine hψ.mono ?_ (Filter.Eventually.of_forall fun t => ?_)
    · exact ((Real.continuous_fourierChar.comp (continuous_id.mul continuous_const).neg).aestronglyMeasurable).smul
        hψ.aestronglyMeasurable
    · simp [Circle.smul_def]
  have e : 𝓕 ψ ξ = ∫ t, (Real.fourierChar (-(t * ξ)) • ψ t - ψ t) := by
    rw [integral_sub hint hψ, hmean, sub_zero, Real.fourier_real_eq]
  rw [e, ← integral_const_mul]
  refine norm_integral_le_of_norm_le (hmoment.const_mul _) (Filter.Eventually.of_forall fun t => ?_)
  rw [Circle.smul_def, smul_eq_mul, ← sub_one_mul, norm_mul, Real.fourierChar_apply]
  have h1 : ‖Complex.exp (↑(2 * Real.pi * -(t * ξ)) * Complex.I) - 1‖ ≤
      2 * Real.pi * (|t| * |ξ|) := by
    have := Real.norm_exp_I_mul_ofReal_sub_one_le (x := 2 * Real.pi * -(t * ξ))
    rw [mul_comm Complex.I] at this
    refine this.trans (le_of_eq ?_)
    rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_neg, abs_mul, abs_of_pos Real.pi_pos, abs_two]
  calc ‖Complex.exp (↑(2 * Real.pi * -(t * ξ)) * Complex.I) - 1‖ * ‖ψ t‖
      ≤ 2 * Real.pi * (|t| * |ξ|) * ‖ψ t‖ := mul_le_mul_of_nonneg_right h1 (norm_nonneg _)
    _ = _ := by ring

#print axioms fourier_bound

/-- **The transform keeps the energy.** Let the mother wavelet `ψ` be an absolutely integrable,
finite-energy wiggle with zero average, `∫ ψ = 0`, whose admissibility constant `C_ψ` is finite.
Let `f` be a finite-energy signal, and let the signal or the wavelet be real. Then the scalogram
`|W_ψ f(a, b)|²`, added up over all times `b` and all scales `a > 0` with weight `da/a²`, equals
`C_ψ` times the signal's energy `∫ |f(t)|² dt`. -/
theorem scalogram_energy_eq_admissibility_mul_energy (ψ f : ℝ → ℂ)
    (hψ : Integrable ψ) (hψ2 : MemLp ψ 2) (hmean : ∫ t, ψ t = 0)
    (hC : admissibility ψ < ∞)
    (hreal : (∀ t, (f t).im = 0) ∨ (∀ t, (ψ t).im = 0))
    (hf : MemLp f 2) :
    ∫⁻ a in Ioi (0 : ℝ), (∫⁻ b, ‖transform ψ f a b‖ₑ ^ 2) / ENNReal.ofReal (a ^ 2) =
      admissibility ψ * ∫⁻ t, ‖f t‖ₑ ^ 2 := by
  have hψc : Integrable (fun t => starRingEnd ℂ (ψ t)) :=
    memLp_one_iff_integrable.1 (memLp_one_iff_integrable.2 hψ).star
  have hψc2 : MemLp (fun t => starRingEnd ℂ (ψ t)) 2 := hψ2.star
  have e1 := scalogram_formula hψ hψ2 hf
  have e2 := scalogram_formula hψc hψc2 hf
  simp_rw [transform_conj_enorm hreal] at e2
  rw [Apos_conj, Aneg_conj] at e2
  have hPN : (∫⁻ ξ in Ioi 0, ‖FL hf ξ‖ₑ ^ 2) + (∫⁻ ξ in Iio 0, ‖FL hf ξ‖ₑ ^ 2) =
      ∫⁻ t, ‖f t‖ₑ ^ 2 := by
    rw [← lintegral_FL hf, lintegral_split]
  rw [admissibility_eq, ← hPN]
  set L := ∫⁻ a in Ioi (0 : ℝ), (∫⁻ b, ‖transform ψ f a b‖ₑ ^ 2) / ENNReal.ofReal (a ^ 2)
  have hLL : L + L = (Apos ψ + Aneg ψ) *
      ((∫⁻ ξ in Ioi 0, ‖FL hf ξ‖ₑ ^ 2) + (∫⁻ ξ in Iio 0, ‖FL hf ξ‖ₑ ^ 2)) := by
    nth_rewrite 1 [e1]
    rw [e2]
    ring
  calc L = 2⁻¹ * (L + L) := by
        rw [← two_mul, ← mul_assoc, ENNReal.inv_mul_cancel two_ne_zero ENNReal.ofNat_ne_top,
          one_mul]
    _ = _ := by rw [hLL, mul_assoc]

/-- **A finite constant needs zero average.** If an absolutely integrable wavelet `ψ` has a
finite admissibility constant `C_ψ`, then its average is exactly zero: `∫ ψ = ψ̂(0) = 0`.
(So a plain bell-curve bump, whose average is not zero, has `C_ψ = ∞`.) -/
theorem integral_eq_zero_of_admissibility_lt_top (ψ : ℝ → ℂ)
    (hψ : Integrable ψ) (hC : admissibility ψ < ∞) :
    ∫ t, ψ t = 0 := by
  have hcont := fourier_continuous' hψ
  rw [← fourier_zero]
  by_contra hne
  have hc : 0 < ‖𝓕 ψ 0‖ := norm_pos_iff.2 hne
  have hev : ∀ᶠ ξ in nhds (0:ℝ), ‖𝓕 ψ 0‖ / 2 < ‖𝓕 ψ ξ‖ :=
    (hcont.norm.tendsto 0).eventually (lt_mem_nhds (half_lt_self hc))
  obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff.1 hev
  set m : ℝ≥0∞ := ENNReal.ofReal ((‖𝓕 ψ 0‖ / 2) ^ 2) with hm
  have hm0 : m ≠ 0 := by
    rw [hm]; simp only [ne_eq, ENNReal.ofReal_eq_zero, not_le]; positivity
  have htop : admissibility ψ = ∞ := by
    rw [admissibility, eq_top_iff]
    calc (∞ : ℝ≥0∞) = 2⁻¹ * (m * ∫⁻ ξ in Ioo 0 δ, (ENNReal.ofReal ξ)⁻¹) := by
          rw [lintegral_inv_Ioo_eq_top hδ, ENNReal.mul_top hm0, ENNReal.mul_top (by simp)]
      _ = 2⁻¹ * ∫⁻ ξ in Ioo 0 δ, m * (ENNReal.ofReal ξ)⁻¹ := by
          rw [lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
      _ ≤ 2⁻¹ * ∫⁻ ξ in Ioo 0 δ, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ := by
          gcongr 2⁻¹ * ?_
          refine lintegral_mono_ae ((ae_restrict_iff' measurableSet_Ioo).2
            (Filter.Eventually.of_forall fun ξ hξ => ?_))
          rw [Real.enorm_eq_ofReal hξ.1.le, div_eq_mul_inv]
          gcongr
          rw [hm, enorm_sq_eq]
          apply ENNReal.ofReal_le_ofReal
          have h1 : ‖𝓕 ψ 0‖ / 2 < ‖𝓕 ψ ξ‖ := by
            apply hball
            rw [Real.dist_eq, sub_zero, abs_of_pos hξ.1]
            exact hξ.2
          have h2 : 0 ≤ ‖𝓕 ψ 0‖ / 2 := by positivity
          nlinarith
      _ ≤ 2⁻¹ * ∫⁻ ξ, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ := by
          gcongr 2⁻¹ * ?_
          exact setLIntegral_le_lintegral _ _
  rw [htop] at hC
  exact lt_irrefl _ hC

/-- **Zero average is enough for a wiggle that fades fast.** If `ψ` is absolutely integrable,
has finite energy, has `∫ |t| |ψ(t)| dt` finite, and has zero average, then its admissibility
constant `C_ψ` is finite. -/
theorem admissibility_lt_top_of_integral_eq_zero (ψ : ℝ → ℂ)
    (hψ : Integrable ψ) (hψ2 : MemLp ψ 2)
    (hmoment : Integrable (fun t : ℝ => |t| * ‖ψ t‖))
    (hmean : ∫ t, ψ t = 0) :
    admissibility ψ < ∞ := by
  set M := ∫ t, |t| * ‖ψ t‖ with hM
  set K : ℝ := (2 * Real.pi * M) ^ 2 with hK
  have hbound : ∀ ξ : ℝ, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ ≤
      (Icc (-1:ℝ) 1).indicator (fun _ => ENNReal.ofReal K) ξ + ‖𝓕 ψ ξ‖ₑ ^ 2 := by
    intro ξ
    by_cases hξ : ξ ∈ Icc (-1:ℝ) 1
    · rw [indicator_of_mem hξ]
      refine le_trans ?_ le_self_add
      by_cases h0 : ξ = 0
      · rw [h0, fourier_zero, hmean]; simp
      · have hpos : 0 < |ξ| := abs_pos.2 h0
        have hle : |ξ| ≤ 1 := abs_le.2 hξ
        rw [enorm_sq_eq, Real.enorm_eq_ofReal_abs, ← ENNReal.ofReal_div_of_pos hpos]
        apply ENNReal.ofReal_le_ofReal
        rw [div_le_iff₀ hpos]
        have hb := fourier_bound hψ hmoment hmean ξ
        have hn : 0 ≤ ‖𝓕 ψ ξ‖ := norm_nonneg _
        have hM0 : 0 ≤ M := integral_nonneg fun t => mul_nonneg (abs_nonneg _) (norm_nonneg _)
        have h3 : ‖𝓕 ψ ξ‖ ^ 2 ≤ (2 * Real.pi * |ξ| * M) ^ 2 := pow_le_pow_left₀ hn hb 2
        have h4 : (2 * Real.pi * |ξ| * M) ^ 2 = K * |ξ| ^ 2 := by rw [hK]; ring
        have hK0 : 0 ≤ K := by rw [hK]; positivity
        have h5 : K * |ξ| ^ 2 ≤ K * |ξ| := by
          apply mul_le_mul_of_nonneg_left _ hK0
          nlinarith
        linarith
    · rw [indicator_of_notMem hξ, zero_add]
      apply ENNReal.div_le_of_le_mul
      apply le_mul_of_one_le_right' 
      rw [Real.enorm_eq_ofReal_abs, ENNReal.one_le_ofReal]
      by_contra hlt
      push Not at hlt
      exact hξ (abs_le.1 hlt.le)
  have hfin : ∫⁻ ξ, ‖𝓕 ψ ξ‖ₑ ^ 2 < ∞ := by
    rw [plancherel_fun hψ hψ2, lintegral_sq_eq hψ2.aestronglyMeasurable]
    exact ENNReal.pow_lt_top hψ2.eLpNorm_lt_top
  rw [admissibility]
  refine ENNReal.mul_lt_top (by simp) ?_
  calc ∫⁻ ξ, ‖𝓕 ψ ξ‖ₑ ^ 2 / ‖ξ‖ₑ
      ≤ ∫⁻ ξ, ((Icc (-1:ℝ) 1).indicator (fun _ => ENNReal.ofReal K) ξ + ‖𝓕 ψ ξ‖ₑ ^ 2) :=
        lintegral_mono hbound
    _ = ENNReal.ofReal K * volume (Icc (-1:ℝ) 1) + ∫⁻ ξ, ‖𝓕 ψ ξ‖ₑ ^ 2 := by
        rw [lintegral_add_left (measurable_const.indicator measurableSet_Icc),
          lintegral_indicator_const measurableSet_Icc]
    _ < ∞ := by
        refine ENNReal.add_lt_top.2 ⟨ENNReal.mul_lt_top ENNReal.ofReal_lt_top ?_, hfin⟩
        rw [Real.volume_Icc]; exact ENNReal.ofReal_lt_top

/-- The card's distance to the quake: S minus P time 6 s, P at 6 km/s, S at 7/2 km/s,
`6 × 6 × 3.5 / (6 − 3.5) = 50.4 = 252/5` km. -/
example : (6 : ℚ) * 6 * (7 / 2) / (6 - 7 / 2) = 252 / 5 := by norm_num

/-- The S minus P arrival: `10 − 4 = 6` seconds. -/
example : (10 : ℕ) - 4 = 6 := by decide

end CWT

open CWT

#print axioms scalogram_energy_eq_admissibility_mul_energy
#print axioms integral_eq_zero_of_admissibility_lt_top
#print axioms admissibility_lt_top_of_integral_eq_zero
