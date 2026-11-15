-- Plancherel: the Fourier transform divided by √(2π) extends from nice signals to a unitary operator on finite-energy signals, keeping energy.
import Mathlib.Analysis.Fourier.LpSpace

open MeasureTheory Complex

noncomputable section

/-- The card's transform, wing 07's form: `f̂(ω) = ∫ f(t) e^(−iωt) dt`. -/
def hat (f : ℝ → ℂ) (ω : ℝ) : ℂ :=
  ∫ t : ℝ, Complex.exp (-(Complex.I * (ω : ℂ) * (t : ℂ))) * f t

lemma dil_mp {a : ℝ} (ha : a ≠ 0) :
    MeasurePreserving (fun x : ℝ => a * x) volume (ENNReal.ofReal |a⁻¹| • volume) :=
  ⟨measurable_const_mul a, Real.map_volume_mul_left ha⟩

lemma dil_qmp {a : ℝ} (ha : a ≠ 0) :
    QuasiMeasurePreserving (fun x : ℝ => a * x) volume volume :=
  ⟨measurable_const_mul a, by rw [Real.map_volume_mul_left ha]; exact Measure.smul_absolutelyContinuous⟩

def dilFun (a : ℝ) (h : ℝ → ℂ) : ℝ → ℂ := fun x => ((Real.sqrt |a| : ℝ) : ℂ) * h (a * x)

lemma dilFun_memLp {a : ℝ} (ha : a ≠ 0) {h : ℝ → ℂ} (hh : MemLp h 2 volume) :
    MemLp (dilFun a h) 2 volume :=
  ((hh.smul_measure ENNReal.ofReal_ne_top).comp_measurePreserving (dil_mp ha)).const_mul _

lemma dilFun_eLpNorm {a : ℝ} (ha : a ≠ 0) {h : ℝ → ℂ} (hh : MemLp h 2 volume) :
    eLpNorm (dilFun a h) 2 volume = eLpNorm h 2 volume := by
  have h1 : eLpNorm (dilFun a h) 2 volume
      = ‖((Real.sqrt |a| : ℝ) : ℂ)‖ₑ * eLpNorm (h ∘ fun x : ℝ => a * x) 2 volume :=
    eLpNorm_const_smul (((Real.sqrt |a| : ℝ) : ℂ)) (h ∘ fun x : ℝ => a * x) 2 volume
  rw [h1, eLpNorm_comp_measurePreserving (hh.smul_measure ENNReal.ofReal_ne_top).aestronglyMeasurable (dil_mp ha),
    eLpNorm_smul_measure_of_ne_top (by norm_num) h _ hh.aestronglyMeasurable]
  rw [smul_eq_mul, ← mul_assoc]
  convert one_mul _
  rw [← ofReal_norm, Complex.norm_real, Real.norm_of_nonneg (Real.sqrt_nonneg _),
    ENNReal.ofReal_rpow_of_nonneg (by positivity) (by norm_num), ← ENNReal.ofReal_mul (by positivity)]
  rw [show (1 / (2 : ENNReal)).toReal = 1/2 by norm_num, ← Real.sqrt_eq_rpow, ← Real.sqrt_mul (abs_nonneg _), abs_inv,
    mul_inv_cancel₀ (abs_ne_zero.2 ha)]
  simp

lemma dilFun_congr {a : ℝ} (ha : a ≠ 0) {g h : ℝ → ℂ} (hgh : g =ᵐ[volume] h) :
    dilFun a g =ᵐ[volume] dilFun a h := by
  filter_upwards [(dil_qmp ha).ae_eq_comp hgh] with x hx
  simp only [dilFun, Function.comp_apply] at hx ⊢
  rw [hx]

def dilₗ {a : ℝ} (ha : a ≠ 0) : Lp ℂ 2 (volume : Measure ℝ) →ₗ[ℂ] Lp ℂ 2 (volume : Measure ℝ) where
  toFun h := (dilFun_memLp ha (Lp.memLp h)).toLp _
  map_add' g h := by
    rw [← MemLp.toLp_add]
    apply MemLp.toLp_congr
    filter_upwards [dilFun_congr ha (Lp.coeFn_add g h)] with x hx
    rw [hx]; simp only [dilFun, Pi.add_apply]; ring
  map_smul' c h := by
    rw [RingHom.id_apply, ← MemLp.toLp_const_smul]
    apply MemLp.toLp_congr
    filter_upwards [dilFun_congr ha (Lp.coeFn_smul c h)] with x hx
    rw [hx]; simp only [dilFun, Pi.smul_apply, smul_eq_mul]; ring

lemma dilₗ_coe {a : ℝ} (ha : a ≠ 0) (h : Lp ℂ 2 (volume : Measure ℝ)) :
    (dilₗ ha h : ℝ → ℂ) =ᵐ[volume] dilFun a h :=
  MemLp.coeFn_toLp (dilFun_memLp ha (Lp.memLp h))

def dilᵢ {a : ℝ} (ha : a ≠ 0) : Lp ℂ 2 (volume : Measure ℝ) →ₗᵢ[ℂ] Lp ℂ 2 (volume : Measure ℝ) where
  toLinearMap := dilₗ ha
  norm_map' h := by
    change ‖(dilFun_memLp ha (Lp.memLp h)).toLp _‖ = ‖h‖
    rw [Lp.norm_toLp (dilFun a h) (dilFun_memLp ha (Lp.memLp h)), dilFun_eLpNorm ha (Lp.memLp h), Lp.norm_def]

lemma dilᵢ_coe {a : ℝ} (ha : a ≠ 0) (h : Lp ℂ 2 (volume : Measure ℝ)) :
    (dilᵢ ha h : ℝ → ℂ) =ᵐ[volume] dilFun a h :=
  dilₗ_coe ha h

lemma dilᵢ_surj {a : ℝ} (ha : a ≠ 0) : Function.Surjective (dilᵢ ha) := by
  intro h
  refine ⟨dilᵢ (inv_ne_zero ha) h, ?_⟩
  apply Lp.ext
  filter_upwards [dilᵢ_coe ha (dilᵢ (inv_ne_zero ha) h),
    (dil_qmp ha).ae_eq_comp (dilᵢ_coe (inv_ne_zero ha) h)] with x h1 h2
  rw [h1]
  simp only [dilFun, Function.comp_apply] at h2 ⊢
  rw [h2, ← mul_assoc, ← Complex.ofReal_mul, ← Real.sqrt_mul (abs_nonneg _), abs_inv,
    mul_inv_cancel₀ (abs_ne_zero.2 ha), inv_mul_cancel_left₀ ha]
  simp

def dilE {a : ℝ} (ha : a ≠ 0) : Lp ℂ 2 (volume : Measure ℝ) ≃ₗᵢ[ℂ] Lp ℂ 2 (volume : Measure ℝ) :=
  LinearIsometryEquiv.ofSurjective (dilᵢ ha) (dilᵢ_surj ha)

lemma dilE_coe {a : ℝ} (ha : a ≠ 0) (h : Lp ℂ 2 (volume : Measure ℝ)) :
    (dilE ha h : ℝ → ℂ) =ᵐ[volume] dilFun a h :=
  dilₗ_coe ha h

open FourierTransform ContDiff in
lemma l2_fourier_ae_eq (f : ℝ → ℂ) (hf1 : Integrable f) (hf2 : MemLp f 2) :
    ((Lp.fourierTransformₗᵢ ℝ ℂ (hf2.toLp f) : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ)
      =ᵐ[volume] 𝓕 f := by
  set g := Lp.fourierTransformₗᵢ ℝ ℂ (hf2.toLp f) with hg_def
  have hT : Lp.toTemperedDistribution g =
      𝓕 (Lp.toTemperedDistribution (hf2.toLp f)) := by
    rw [Lp.fourier_toTemperedDistribution_eq]; rfl
  have hcont : Continuous (𝓕 f) :=
    VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
      (innerSL ℝ).continuous₂ hf1
  have hgl : LocallyIntegrable (g : ℝ → ℂ) volume :=
    (Lp.memLp g).locallyIntegrable (by norm_num)
  have hloc : LocallyIntegrable (fun x => (g : ℝ → ℂ) x - 𝓕 f x) volume :=
    hgl.sub hcont.locallyIntegrable
  have hz := ae_eq_zero_of_integral_contDiff_smul_eq_zero hloc ?_
  · filter_upwards [hz] with x hx
    exact sub_eq_zero.1 hx
  intro φ hφ hφc
  have hg₁ : HasCompactSupport (Complex.ofRealCLM ∘ φ) := hφc.comp_left rfl
  have hg₂ : ContDiff ℝ ∞ (Complex.ofRealCLM ∘ φ) := by fun_prop
  set ψ := hg₁.toSchwartzMap hg₂ with hψ
  have hψφ : ∀ x, ψ x = (φ x : ℂ) := fun x => rfl
  have e1 : ∫ x, ψ x • (g : ℝ → ℂ) x = ∫ x, 𝓕 ψ x • f x := by
    have := congrArg (fun T => T ψ) hT
    simp only [Lp.toTemperedDistribution_apply, TemperedDistribution.fourier_apply] at this
    rw [this]
    apply integral_congr_ae
    filter_upwards [hf2.coeFn_toLp] with x hx
    rw [hx]
  have e2 : ∫ x, ψ x • 𝓕 f x = ∫ x, 𝓕 ψ x • f x := by
    have := VectorFourier.integral_fourierIntegral_smul_eq_flip (L := innerₗ ℝ)
      Real.continuous_fourierChar continuous_inner (ψ.integrable (μ := volume)) hf1
    simpa using! this.symm
  have i1 : Integrable (fun x => φ x • (g : ℝ → ℂ) x) volume :=
    hgl.integrable_smul_left_of_hasCompactSupport hφ.continuous hφc
  have i2 : Integrable (fun x => φ x • 𝓕 f x) volume :=
    hcont.locallyIntegrable.integrable_smul_left_of_hasCompactSupport hφ.continuous hφc
  simp_rw [smul_sub]
  rw [integral_sub i1 i2]
  have r1 : ∫ x, φ x • (g : ℝ → ℂ) x = ∫ x, ψ x • (g : ℝ → ℂ) x := by
    simp [hψφ, Complex.real_smul]
  have r2 : ∫ x, φ x • 𝓕 f x = ∫ x, ψ x • 𝓕 f x := by
    simp [hψφ, Complex.real_smul]
  rw [r1, r2, e1, e2, sub_self]

open FourierTransform in
lemma hat_eq_fourier (f : ℝ → ℂ) (ω : ℝ) : hat f ω = 𝓕 f ((2 * Real.pi)⁻¹ * ω) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  unfold hat
  congr 1
  ext v
  rw [smul_eq_mul]
  congr 2
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  push_cast
  field_simp

open FourierTransform in
lemma continuous_hat (f : ℝ → ℂ) (hf1 : Integrable f) : Continuous (hat f) := by
  have hcont : Continuous (𝓕 f) :=
    VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
      (innerSL ℝ).continuous₂ hf1
  have : hat f = fun ω => 𝓕 f ((2 * Real.pi)⁻¹ * ω) := funext (hat_eq_fourier f)
  rw [this]
  exact hcont.comp (continuous_const_mul _)

/-- Plancherel's theorem, operator form: there is a unitary operator `𝓕` on the space `L²` of
finite-energy signals (a linear map onto `L²` that keeps every length, hence every angle, and can
be undone) which, on every nice signal (finite energy and finite area under `|f|`), is the
transform `f̂` divided by `√(2π)`. On the other signals it is defined by limits in energy. -/
theorem fourier_transform_is_unitary :
    ∃ 𝓕 : Lp ℂ 2 (volume : Measure ℝ) ≃ₗᵢ[ℂ] Lp ℂ 2 (volume : Measure ℝ),
      ∀ (f : ℝ → ℂ) (hf1 : Integrable f) (hf2 : MemLp f 2),
        (𝓕 (hf2.toLp f) : ℝ → ℂ) =ᵐ[volume]
          fun ω => ((Real.sqrt (2 * Real.pi) : ℝ) : ℂ)⁻¹ * hat f ω := by
  have ha : (2 * Real.pi)⁻¹ ≠ 0 := by positivity
  refine ⟨(Lp.fourierTransformₗᵢ ℝ ℂ).trans (dilE ha), ?_⟩
  intro f hf1 hf2
  rw [LinearIsometryEquiv.trans_apply]
  filter_upwards [dilE_coe ha (Lp.fourierTransformₗᵢ ℝ ℂ (hf2.toLp f)),
    (dil_qmp ha).ae_eq_comp (l2_fourier_ae_eq f hf1 hf2)] with ω h1 h2
  rw [h1]
  simp only [dilFun, Function.comp_apply] at h2 ⊢
  rw [h2, hat_eq_fourier, abs_of_pos (by positivity), Real.sqrt_inv, Complex.ofReal_inv]

/-- Plancherel's identity for a nice signal `f` (finite energy and finite area under `|f|`):
the energy counted over all frequencies is `2π` times the energy counted over all time,
`∫ |f̂(ω)|² dω = 2π ∫ |f(t)|² dt`. -/
theorem plancherel_identity_nice_signals (f : ℝ → ℂ) (hf1 : Integrable f) (hf2 : MemLp f 2) :
    ∫⁻ ω : ℝ, ‖hat f ω‖ₑ ^ 2 = ENNReal.ofReal (2 * Real.pi) * ∫⁻ t : ℝ, ‖f t‖ₑ ^ 2 := by
  obtain ⟨U, hU⟩ := fourier_transform_is_unitary
  have h := hU f hf1 hf2
  have hn : ‖U (hf2.toLp f)‖ = ‖hf2.toLp f‖ := U.norm_map _
  rw [Lp.norm_def, Lp.norm_def, ENNReal.toReal_eq_toReal_iff' (Lp.eLpNorm_ne_top _)
    (Lp.eLpNorm_ne_top _), eLpNorm_congr_ae h, eLpNorm_congr_ae hf2.coeFn_toLp] at hn
  set c : ℂ := ((Real.sqrt (2 * Real.pi) : ℝ) : ℂ)⁻¹ with hc
  have hsm : eLpNorm (fun ω => c * hat f ω) 2 volume = ‖c‖ₑ * eLpNorm (hat f) 2 volume :=
    eLpNorm_const_smul c (hat f) 2 volume
  rw [hsm, eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num)
      (continuous_hat f hf1).aestronglyMeasurable,
    eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num) hf2.aestronglyMeasurable]
    at hn
  have sq : ∀ y : ENNReal, (y ^ (1 / (2 : ENNReal).toReal)) ^ 2 = y := by
    intro y
    rw [← ENNReal.rpow_natCast, ← ENNReal.rpow_mul]
    norm_num
  have hn2 := congrArg (fun y : ENNReal => y ^ 2) hn
  simp only [mul_pow, sq] at hn2
  simp only [ENNReal.toReal_ofNat, ENNReal.rpow_two] at hn2
  have hc2 : ‖c‖ₑ ^ 2 = ENNReal.ofReal (2 * Real.pi)⁻¹ := by
    rw [hc, ← ofReal_norm, norm_inv, Complex.norm_real, Real.norm_of_nonneg (Real.sqrt_nonneg _),
      ← ENNReal.ofReal_pow (by positivity), inv_pow, Real.sq_sqrt (by positivity)]
  rw [← hn2, hc2, ← mul_assoc, ← ENNReal.ofReal_mul (by positivity),
    mul_inv_cancel₀ (by positivity), ENNReal.ofReal_one, one_mul]

/-- The bounded-extension theorem: a linear map `T` from a dense subspace `D` of a normed space
`X` into a complete normed space `Y`, with `‖T x‖ ≤ C ‖x‖`, has exactly one continuous linear
extension to all of `X`, and that extension keeps the same bound `C`. -/
theorem bounded_extension_theorem {𝕜 X Y : Type*} [RCLike 𝕜]
    [NormedAddCommGroup X] [NormedSpace 𝕜 X]
    [NormedAddCommGroup Y] [NormedSpace 𝕜 Y] [CompleteSpace Y]
    (D : Submodule 𝕜 X) (hD : Dense (D : Set X)) (T : D →ₗ[𝕜] Y) (C : ℝ)
    (hT : ∀ x : D, ‖T x‖ ≤ C * ‖(x : X)‖) :
    ∃! S : X →L[𝕜] Y, (∀ x : D, S x = T x) ∧ ∀ x : X, ‖S x‖ ≤ C * ‖x‖ := by
  classical
  let T' : D →L[𝕜] Y := T.mkContinuous C hT
  have hd : DenseRange (D.subtypeL) := by
    simpa [DenseRange] using hD
  have hu : IsUniformInducing (D.subtypeL) := isUniformInducing_val _
  set S := T'.extend D.subtypeL with hS_def
  have hS : ∀ x : D, S x = T x := fun x => ContinuousLinearMap.extend_eq T' hd hu x
  refine ⟨S, ⟨hS, ?_⟩, ?_⟩
  · intro x
    have hcl : IsClosed {x : X | ‖S x‖ ≤ C * ‖x‖} :=
      isClosed_le (by fun_prop) (by fun_prop)
    have hsub : (D : Set X) ⊆ {x : X | ‖S x‖ ≤ C * ‖x‖} := by
      intro y hy
      have := hS ⟨y, hy⟩
      show ‖S y‖ ≤ C * ‖y‖
      rw [show S y = S (⟨y, hy⟩ : D) from rfl, this]
      exact hT ⟨y, hy⟩
    exact hcl.closure_subset_iff.2 hsub (hD x)
  · rintro S' ⟨h1, -⟩
    refine (ContinuousLinearMap.extend_unique T' hd hu S' ?_).symm
    ext x
    simp only [ContinuousLinearMap.comp_apply, Submodule.subtypeL_apply, h1]
    rfl

/-- The sampled pulse 0 0 0 1 1 0 0 0 at spacing 1 µs carries energy 2 (µJ into 1 Ω). -/
example : (([0, 0, 0, 1, 1, 0, 0, 0] : List ℕ).map (· ^ 2)).sum = 2 := by decide

/-- The pulse, 1 V on −1 < t < 1 µs, carries 1 V² × 2 µs = 2 µJ into 1 Ω. -/
example : ∫ _t in (-1 : ℝ)..1, (1 : ℝ) ^ 2 = 2 := by norm_num

end

#print axioms dil_mp
#print axioms dil_qmp
#print axioms dilFun
#print axioms dilFun_memLp
#print axioms dilFun_eLpNorm
#print axioms dilFun_congr
#print axioms dilₗ
#print axioms dilₗ_coe
#print axioms dilᵢ
#print axioms dilᵢ_coe
#print axioms dilᵢ_surj
#print axioms dilE
#print axioms dilE_coe
#print axioms l2_fourier_ae_eq
#print axioms hat_eq_fourier
#print axioms continuous_hat
#print axioms fourier_transform_is_unitary
#print axioms plancherel_identity_nice_signals
#print axioms bounded_extension_theorem
