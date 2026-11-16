-- The uncertainty principle: a nonzero signal's time spread times its frequency spread is at least 1/(4π), only a bell curve reaches it, and no nonzero signal is both time-limited and band-limited.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib

open MeasureTheory Real
open scoped FourierTransform

noncomputable section

/-- The energy `‖f‖² = ∫ |f(t)|² dt` of a signal `f : ℝ → ℂ`, with `t` in seconds. -/
def energy (f : ℝ → ℂ) : ℝ := ∫ t, ‖f t‖ ^ 2

/-- The mean time `t₀ = (1/‖f‖²) ∫ t |f(t)|² dt`, weighted by energy. -/
def meanTime (f : ℝ → ℂ) : ℝ := (∫ t, t * ‖f t‖ ^ 2) / energy f

/-- The time spread `Δt`: the standard deviation of the energy `|f(t)|²` over time,
`Δt² = (1/‖f‖²) ∫ (t - t₀)² |f(t)|² dt`. -/
def timeSpread (f : ℝ → ℂ) : ℝ :=
  Real.sqrt ((∫ t, (t - meanTime f) ^ 2 * ‖f t‖ ^ 2) / energy f)

/-- The mean frequency `ξ₀ = (1/‖f‖²) ∫ ξ |f̂(ξ)|² dξ`, with the hertz-form transform
`f̂(ξ) = ∫ f(t) e^(-2πiξt) dt` (Mathlib's `𝓕`). -/
def meanFreq (f : ℝ → ℂ) : ℝ := (∫ ξ, ξ * ‖𝓕 f ξ‖ ^ 2) / energy f

/-- The frequency spread `Δξ`: the standard deviation of the energy `|f̂(ξ)|²` over frequency,
`Δξ² = (1/‖f‖²) ∫ (ξ - ξ₀)² |f̂(ξ)|² dξ`. -/
def freqSpread (f : ℝ → ℂ) : ℝ :=
  Real.sqrt ((∫ ξ, (ξ - meanFreq f) ^ 2 * ‖𝓕 f ξ‖ ^ 2) / energy f)

lemma up_selfadj {f g : ℝ → ℂ} (hf : Integrable f) (hg : Integrable g) :
    ∫ ξ, 𝓕 f ξ * g ξ = ∫ x, f x * 𝓕 g x := by
  simpa using! VectorFourier.integral_bilin_fourierIntegral_eq_flip (ContinuousLinearMap.mul ℂ ℂ)
    (L := innerₗ ℝ) Real.continuous_fourierChar continuous_inner hf hg

lemma up_L2pair (h : Lp ℂ 2 (volume : Measure ℝ)) (g : SchwartzMap ℝ ℂ) :
    ∫ ξ, g ξ • (𝓕 h : Lp ℂ 2 (volume : Measure ℝ)) ξ = ∫ x, 𝓕 g x • h x := by
  have := congrArg (fun T : TemperedDistribution ℝ ℂ => T g) (Lp.fourier_toTemperedDistribution_eq h)
  simp only [TemperedDistribution.fourier_apply, Lp.toTemperedDistribution_apply] at this
  exact this.symm

open scoped ContDiff in
lemma up_unique (F : Lp ℂ 2 (volume : Measure ℝ)) {G : ℝ → ℂ} (hG : Continuous G)
    (h : ∀ g : SchwartzMap ℝ ℂ, HasCompactSupport (g : ℝ → ℂ) →
      ∫ ξ, g ξ * F ξ = ∫ ξ, g ξ * G ξ) : (F : ℝ → ℂ) =ᵐ[volume] G := by
  apply ae_eq_of_integral_contDiff_smul_eq
  · exact (Lp.memLp F).locallyIntegrable (by norm_num)
  · exact hG.locallyIntegrable
  · intro g g_smooth g_cpt
    have hg₁ : HasCompactSupport (Complex.ofRealCLM ∘ g) := g_cpt.comp_left rfl
    have hg₂ : ContDiff ℝ ∞ (Complex.ofRealCLM ∘ g) := by fun_prop
    have := h (hg₁.toSchwartzMap hg₂) hg₁
    simpa [Complex.real_smul] using this

/-- Plancherel on `L¹ ∩ L²`: the `L²` transform agrees with the integral. -/
lemma up_fourier_toLp {f : ℝ → ℂ} (hf1 : Integrable f) (hf2 : MemLp f 2) :
    ((𝓕 (hf2.toLp f) : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ) =ᵐ[volume] 𝓕 f := by
  apply up_unique _ (VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
    (by fun_prop) hf1)
  intro g _
  rw [show (∫ ξ, g ξ * (𝓕 (hf2.toLp f) : Lp ℂ 2 (volume : Measure ℝ)) ξ)
      = ∫ ξ, g ξ • (𝓕 (hf2.toLp f) : Lp ℂ 2 (volume : Measure ℝ)) ξ from rfl, up_L2pair]
  have e1 : ∫ x, 𝓕 (g : ℝ → ℂ) x • (hf2.toLp f) x = ∫ x, f x * 𝓕 (g : ℝ → ℂ) x := by
    apply integral_congr_ae
    filter_upwards [hf2.coeFn_toLp] with x hx
    rw [hx, smul_eq_mul, mul_comm]
  rw [SchwartzMap.fourier_coe, e1, ← up_selfadj hf1 g.integrable]
  congr 1; ext ξ; rw [mul_comm]; rfl

lemma up_fourier_cont {f : ℝ → ℂ} (hf1 : Integrable f) : Continuous (𝓕 f) :=
  VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar (by fun_prop) hf1

lemma up_fourier_deriv_toLp {f : ℝ → ℂ} (hf1 : Integrable f) (hdiff : Differentiable ℝ f)
    (hdf : MemLp (deriv f) 2) :
    ((𝓕 (hdf.toLp (deriv f)) : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ) =ᵐ[volume]
      fun ξ => (2 * π * Complex.I * ξ) * 𝓕 f ξ := by
  apply up_unique _ (by have := up_fourier_cont hf1; fun_prop)
  intro g _
  rw [show (∫ ξ, g ξ * (𝓕 (hdf.toLp (deriv f)) : Lp ℂ 2 (volume : Measure ℝ)) ξ)
      = ∫ ξ, g ξ • (𝓕 (hdf.toLp (deriv f)) : Lp ℂ 2 (volume : Measure ℝ)) ξ from rfl, up_L2pair]
  have e1 : ∫ x, 𝓕 g x • (hdf.toLp (deriv f)) x = ∫ x, 𝓕 (g : ℝ → ℂ) x * deriv f x := by
    apply integral_congr_ae
    filter_upwards [hdf.coeFn_toLp] with x hx
    rw [hx, smul_eq_mul, SchwartzMap.fourier_coe]
  have hxg : Integrable (fun x : ℝ => x • g x) := by
    refine (g.integrable_pow_mul volume 1).mono' (by fun_prop) (Filter.Eventually.of_forall ?_)
    intro x; simp
  have hg1 : Integrable (fun x : ℝ => (-2 * π * Complex.I * x) • g x) := by
    have := hxg.smul (-2 * π * Complex.I)
    refine this.congr (Filter.Eventually.of_forall fun x => ?_)
    simp only [Pi.smul_apply, smul_eq_mul, Complex.real_smul]; ring
  have hbd : ∀ (h : ℝ → ℂ) (ξ : ℝ), ‖𝓕 h ξ‖ ≤ ∫ v, ‖h v‖ := fun h ξ =>
    Real.norm_fourier_le_integral_norm h ξ
  have hibp := integral_mul_deriv_eq_deriv_mul_of_integrable (u := 𝓕 (g : ℝ → ℂ)) (v := f)
    (u' := 𝓕 (fun x : ℝ => (-2 * π * Complex.I * x) • g x)) (v' := deriv f)
    (fun x _ => Real.hasDerivAt_fourier g.integrable hxg x)
    (fun x _ => (hdiff x).hasDerivAt)
    (by
      have h2 : MemLp (𝓕 (g : ℝ → ℂ)) 2 := by
        rw [← SchwartzMap.fourier_coe]; exact (𝓕 g).memLp 2
      exact h2.integrable_mul hdf)
    (Integrable.bdd_mul hf1 (up_fourier_cont hg1).aestronglyMeasurable
      (Filter.Eventually.of_forall (hbd _)))
    (Integrable.bdd_mul hf1 (up_fourier_cont g.integrable).aestronglyMeasurable
      (Filter.Eventually.of_forall (hbd _)))
  rw [e1, hibp]
  have e2 : ∫ x, 𝓕 (fun x : ℝ => (-2 * π * Complex.I * x) • g x) x * f x
      = ∫ x, f x * 𝓕 (fun x : ℝ => (-2 * π * Complex.I * x) • g x) x := by
    congr 1; ext x; ring
  rw [e2, ← up_selfadj hf1 hg1, ← integral_neg]
  congr 1; ext ξ; simp only [smul_eq_mul]; ring

lemma up_norm_sq (F : Lp ℂ 2 (volume : Measure ℝ)) : ‖F‖ ^ 2 = ∫ x, ‖F x‖ ^ 2 := by
  have h1 := MeasureTheory.L2.inner_def (𝕜 := ℂ) F F
  simp only [inner_self_eq_norm_sq_to_K] at h1
  have h3 : ((‖F‖ ^ 2 : ℝ) : ℂ) = ((∫ a, ‖(F : ℝ → ℂ) a‖ ^ 2 : ℝ) : ℂ) := by
    rw [← integral_complex_ofReal]; push_cast; exact h1
  exact_mod_cast h3

lemma up_norm_sq_toLp {f : ℝ → ℂ} (hf : MemLp f 2) : ‖hf.toLp f‖ ^ 2 = ∫ x, ‖f x‖ ^ 2 := by
  rw [up_norm_sq]
  apply integral_congr_ae
  filter_upwards [hf.coeFn_toLp] with x hx
  rw [hx]

lemma up_plancherel {f : ℝ → ℂ} (hf1 : Integrable f) (hf2 : MemLp f 2) :
    MemLp (𝓕 f) 2 ∧ ∫ ξ, ‖𝓕 f ξ‖ ^ 2 = ∫ x, ‖f x‖ ^ 2 := by
  have hae := up_fourier_toLp hf1 hf2
  refine ⟨(Lp.memLp _).ae_eq hae, ?_⟩
  rw [← up_norm_sq_toLp hf2, ← Lp.norm_fourier_eq, up_norm_sq]
  apply integral_congr_ae
  filter_upwards [hae] with x hx
  rw [hx]

lemma up_freq_deriv {f : ℝ → ℂ} (hf1 : Integrable f) (hf2 : MemLp f 2)
    (hdiff : Differentiable ℝ f) (hdf : MemLp (deriv f) 2) (b : ℝ) :
    MemLp (fun ξ : ℝ => (2 * π * Complex.I * (ξ - b)) * 𝓕 f ξ) 2 ∧
    ∫ ξ, ‖(2 * π * Complex.I * (ξ - b)) * 𝓕 f ξ‖ ^ 2 =
      ∫ t, ‖deriv f t + (-(2 * π * Complex.I * b)) • f t‖ ^ 2 := by
  set c : ℂ := -(2 * π * Complex.I * b)
  have hh : MemLp (fun t => deriv f t + c • f t) 2 := hdf.add (hf2.const_smul c)
  set X : Lp ℂ 2 (volume : Measure ℝ) := hdf.toLp (deriv f) + c • hf2.toLp f
  have hX : X = hh.toLp _ := by
    simp only [X]; rw [← MemLp.toLp_const_smul, ← MemLp.toLp_add]; rfl
  have hFX : 𝓕 X = 𝓕 (hdf.toLp (deriv f)) + c • 𝓕 (hf2.toLp f) := by
    simp only [X, FourierTransform.fourier_add, FourierTransform.fourier_smul]
  have hae : ((𝓕 X : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ) =ᵐ[volume]
      fun ξ : ℝ => (2 * π * Complex.I * (ξ - b)) * 𝓕 f ξ := by
    rw [hFX]
    filter_upwards [Lp.coeFn_add (𝓕 (hdf.toLp (deriv f))) (c • 𝓕 (hf2.toLp f)),
      Lp.coeFn_smul c (𝓕 (hf2.toLp f)), up_fourier_toLp hf1 hf2,
      up_fourier_deriv_toLp hf1 hdiff hdf] with ξ h1 h2 h3 h4
    rw [h1, Pi.add_apply, h2, Pi.smul_apply, h3, h4, smul_eq_mul]
    simp only [c]; ring
  refine ⟨(Lp.memLp _).ae_eq hae, ?_⟩
  have := up_norm_sq_toLp hh
  rw [← hX, ← Lp.norm_fourier_eq, up_norm_sq] at this
  rw [← this]
  apply integral_congr_ae
  filter_upwards [hae] with x hx
  rw [hx]
lemma up_sq {g : ℝ → ℂ} (hg : MemLp g 2) : Integrable (fun x => ‖g x‖ ^ 2) :=
  (memLp_two_iff_integrable_sq_norm hg.aestronglyMeasurable).1 hg

lemma up_prod {u v : ℝ → ℂ} (hu : MemLp u 2) (hv : MemLp v 2) :
    Integrable (fun x => ‖u x‖ * ‖v x‖) := by
  refine ((up_sq hu).add (up_sq hv)).mono' (hu.aestronglyMeasurable.norm.mul hv.aestronglyMeasurable.norm) ?_
  refine Filter.Eventually.of_forall fun x => ?_
  have h1 := norm_nonneg (u x); have h2 := norm_nonneg (v x)
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity)]
  simp only [Pi.add_apply]; nlinarith [sq_nonneg (‖u x‖ - ‖v x‖)]

lemma up_shift {f : ℝ → ℂ} (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (a : ℝ) : MemLp (fun t : ℝ => ((t - a : ℝ) : ℂ) * f t) 2 := by
  have : (fun t : ℝ => ((t - a : ℝ) : ℂ) * f t) =
      (fun t : ℝ => (t : ℂ) * f t) - fun t => (a : ℂ) * f t := by
    ext t; simp only [Pi.sub_apply]; push_cast; ring
  rw [this]; exact htf.sub (hf.const_mul _)

lemma up_norm_shift (f : ℝ → ℂ) (a t : ℝ) :
    ‖((t - a : ℝ) : ℂ) * f t‖ = |t - a| * ‖f t‖ := by
  rw [norm_mul, Complex.norm_real, Real.norm_eq_abs]

lemma up_L1 {f : ℝ → ℂ} (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2) :
    Integrable f := by
  have h1 := up_sq hf
  have h2 := up_sq htf
  refine ((h1.add h2).add integrable_inv_one_add_sq).mono' hf.aestronglyMeasurable ?_
  refine Filter.Eventually.of_forall fun t => ?_
  simp only [Pi.add_apply, norm_mul, Complex.norm_real, Real.norm_eq_abs, mul_pow, sq_abs]
  set x := ‖f t‖
  have hx : 0 ≤ x := norm_nonneg _
  have hs : 0 < 1 + t ^ 2 := by positivity
  have key : (1 + t ^ 2) * x ≤ (1 + t ^ 2) * (x ^ 2 + t ^ 2 * x ^ 2 + (1 + t ^ 2)⁻¹) := by
    rw [mul_add, mul_inv_cancel₀ hs.ne']
    nlinarith [sq_nonneg ((1 + t ^ 2) * x - 1), sq_nonneg t, mul_nonneg (sq_nonneg t) hx]
  exact le_of_mul_le_mul_left key hs

lemma up_tw {f : ℝ → ℂ} (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (a : ℝ) : Integrable (fun t => (t - a) ^ 2 * ‖f t‖ ^ 2) := by
  refine (up_sq (up_shift hf htf a)).congr (Filter.Eventually.of_forall fun t => ?_)
  simp only [up_norm_shift, mul_pow, sq_abs]

lemma up_inner_imag (z : ℂ) (b : ℝ) : inner ℝ z ((-(2 * π * Complex.I * b)) • z) = 0 := by
  simp [Complex.inner, Complex.mul_re, Complex.mul_im]
  ring

lemma up_ident {f : ℝ → ℂ} (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (hdiff : Differentiable ℝ f) (hdf : MemLp (deriv f) 2) (a b : ℝ) :
    ∫ t, ‖f t‖ ^ 2 =
      -2 * ∫ t, (t - a) * inner ℝ (f t) (deriv f t + (-(2 * π * Complex.I * b)) • f t) := by
  have hderiv : ∀ t, HasDerivAt (fun t => (t - a) * ‖f t‖ ^ 2)
      (‖f t‖ ^ 2 + 2 * ((t - a) * inner ℝ (f t) (deriv f t))) t := by
    intro t
    have h1 := ((hasDerivAt_id t).sub_const a).mul (hdiff t).hasDerivAt.norm_sq
    refine h1.congr_deriv ?_
    simp only [id]; ring
  have hu := up_shift hf htf a
  have hint1 : Integrable (fun t => (t - a) * inner ℝ (f t) (deriv f t)) := by
    refine (up_prod hu hdf).mono'
      ((measurable_id.sub_const a).aestronglyMeasurable.mul
        (hf.aestronglyMeasurable.inner hdf.aestronglyMeasurable)) ?_
    refine Filter.Eventually.of_forall fun t => ?_
    rw [up_norm_shift, norm_mul, Real.norm_eq_abs, mul_assoc]
    gcongr
    exact abs_real_inner_le_norm _ _
  have hw : Integrable (fun t => (t - a) * ‖f t‖ ^ 2) := by
    refine (up_prod hu hf).mono'
      ((measurable_id.sub_const a).aestronglyMeasurable.mul (hf.aestronglyMeasurable.norm.pow 2)) ?_
    refine Filter.Eventually.of_forall fun t => ?_
    rw [up_norm_shift, norm_mul, Real.norm_eq_abs, norm_pow, Real.norm_eq_abs, abs_norm]
    ring_nf; rfl
  have h0 := integral_eq_zero_of_hasDerivAt_of_integrable hderiv
    ((up_sq hf).add (hint1.const_mul 2)) hw
  rw [integral_add (up_sq hf) (hint1.const_mul 2), integral_const_mul] at h0
  have e : ∀ t, (t - a) * inner ℝ (f t) (deriv f t + (-(2 * π * Complex.I * b)) • f t)
      = (t - a) * inner ℝ (f t) (deriv f t) := by
    intro t; rw [inner_add_right, up_inner_imag, add_zero]
  simp_rw [e]
  linarith

lemma up_ineq {f : ℝ → ℂ} (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (hdiff : Differentiable ℝ f) (hdf : MemLp (deriv f) 2) (a b l : ℝ) (hl : 0 < l) :
    ∫ t, ‖f t‖ ^ 2 ≤ l * (∫ t, (t - a) ^ 2 * ‖f t‖ ^ 2) +
      (∫ t, ‖deriv f t + (-(2 * π * Complex.I * b)) • f t‖ ^ 2) / l := by
  set c : ℂ := -(2 * π * Complex.I * b)
  have hv : MemLp (fun t => deriv f t + c • f t) 2 := hdf.add (hf.const_smul c)
  have hu := up_shift hf htf a
  have eq : l * (∫ t, (t - a) ^ 2 * ‖f t‖ ^ 2) + (∫ t, ‖deriv f t + c • f t‖ ^ 2) / l
      = ∫ t, (l * ((t - a) ^ 2 * ‖f t‖ ^ 2) + ‖deriv f t + c • f t‖ ^ 2 / l) := by
    rw [integral_add ((up_tw hf htf a).const_mul l) ((up_sq hv).div_const l),
      integral_const_mul, integral_div]
  rw [eq, up_ident hf htf hdiff hdf a b, ← integral_const_mul (-2 : ℝ)]
  have hint : Integrable (fun t => -2 * ((t - a) * inner ℝ (f t) (deriv f t + c • f t))) := by
    refine ((up_prod hu hv).const_mul 2).mono'
      (((measurable_id.sub_const a).aestronglyMeasurable.mul
        (hf.aestronglyMeasurable.inner hv.aestronglyMeasurable)).const_mul _) ?_
    refine Filter.Eventually.of_forall fun t => ?_
    have hi := abs_real_inner_le_norm (f t) (deriv f t + c • f t)
    rw [norm_mul, norm_mul, up_norm_shift, Real.norm_eq_abs, Real.norm_eq_abs, Real.norm_eq_abs]
    have h2 : |(-2 : ℝ)| = 2 := by norm_num
    rw [h2, mul_assoc |t - a|]
    gcongr
  refine integral_mono hint (((up_tw hf htf a).const_mul l).add ((up_sq hv).div_const l)) ?_
  intro t
  simp only
  set v := deriv f t + c • f t
  have hi := abs_real_inner_le_norm (f t) v
  set p := |t - a| * ‖f t‖
  have hp : 0 ≤ p := by positivity
  have hq := norm_nonneg v
  have h1 : -2 * ((t - a) * inner ℝ (f t) v) ≤ 2 * (p * ‖v‖) := by
    have : |(t - a) * inner ℝ (f t) v| ≤ p * ‖v‖ := by
      rw [abs_mul, mul_assoc]; gcongr
    nlinarith [neg_abs_le ((t - a) * inner ℝ (f t) v)]
  have h2 : 2 * (p * ‖v‖) ≤ l * ((t - a) ^ 2 * ‖f t‖ ^ 2) + ‖v‖ ^ 2 / l := by
    have hp2 : p ^ 2 = (t - a) ^ 2 * ‖f t‖ ^ 2 := by simp only [p, mul_pow, sq_abs]
    rw [← hp2, div_eq_mul_inv]
    have hl' : 0 < l⁻¹ := inv_pos.mpr hl
    have : l * l⁻¹ = 1 := mul_inv_cancel₀ hl.ne'
    nlinarith [sq_nonneg (l * p - ‖v‖), mul_nonneg hl'.le (sq_nonneg (l * p - ‖v‖))]
  linarith


lemma up_V {f : ℝ → ℂ} (hf1 : Integrable f) (hf2 : MemLp f 2)
    (hdiff : Differentiable ℝ f) (hdf : MemLp (deriv f) 2) (b : ℝ) :
    Integrable (fun ξ : ℝ => (ξ - b) ^ 2 * ‖𝓕 f ξ‖ ^ 2) ∧
    ∫ t, ‖deriv f t + (-(2 * π * Complex.I * b)) • f t‖ ^ 2 =
      4 * π ^ 2 * ∫ ξ, (ξ - b) ^ 2 * ‖𝓕 f ξ‖ ^ 2 := by
  obtain ⟨hm, he⟩ := up_freq_deriv hf1 hf2 hdiff hdf b
  have hn : ∀ ξ : ℝ, ‖(2 * π * Complex.I * (ξ - b)) * 𝓕 f ξ‖ ^ 2
      = 4 * π ^ 2 * ((ξ - b) ^ 2 * ‖𝓕 f ξ‖ ^ 2) := by
    intro ξ
    rw [norm_mul, norm_mul, norm_mul, norm_mul, Complex.norm_I]
    rw [show ((ξ : ℂ) - b) = ((ξ - b : ℝ) : ℂ) by push_cast; ring, Complex.norm_real,
      Complex.norm_real, Complex.norm_ofNat, Real.norm_eq_abs, Real.norm_eq_abs,
      abs_of_pos pi_pos]
    simp only [mul_pow, sq_abs, one_pow]; ring
  have hi := up_sq hm
  simp_rw [hn] at hi he
  refine ⟨(hi.const_mul (4 * π ^ 2)⁻¹).congr (Filter.Eventually.of_forall fun ξ => ?_), ?_⟩
  · simp only; field_simp
  · rw [← he, integral_const_mul]

lemma up_alg {E U W : ℝ} (hE : 0 < E) (hU : 0 ≤ U) (hW : 0 ≤ W)
    (h : ∀ l : ℝ, 0 < l → E ≤ l * U + 4 * π ^ 2 * W / l) :
    0 < U ∧ E ^ 2 ≤ 16 * π ^ 2 * U * W := by
  have hp := pi_pos
  have hU' : 0 < U := by
    rcases hU.lt_or_eq with h' | h'
    · exact h'
    exfalso
    have hl : 0 < (8 * π ^ 2 * W + 1) / E := by positivity
    have := h _ hl
    rw [← h', mul_zero, zero_add, div_div_eq_mul_div, le_div_iff₀ (by positivity)] at this
    have : 0 ≤ E * (π ^ 2 * W) := by positivity
    nlinarith
  refine ⟨hU', ?_⟩
  have := h (E / (2 * U)) (by positivity)
  rw [div_div_eq_mul_div] at this
  have e1 : E / (2 * U) * U = E / 2 := by field_simp
  rw [e1] at this
  have e2 : 4 * π ^ 2 * W * (2 * U) / E = 8 * π ^ 2 * U * W / E := by ring
  rw [e2] at this
  have : E / 2 ≤ 8 * π ^ 2 * U * W / E := by linarith
  rw [le_div_iff₀ hE] at this
  nlinarith

lemma up_spread {E U W : ℝ} (hE : 0 < E) (hU : 0 ≤ U)
    (h : E ^ 2 ≤ 16 * π ^ 2 * U * W) :
    1 / (4 * π) ≤ Real.sqrt (U / E) * Real.sqrt (W / E) := by
  rw [← Real.sqrt_mul (div_nonneg hU hE.le)]
  apply Real.le_sqrt_of_sq_le
  have hp := pi_pos
  rw [div_pow, div_mul_div_comm, div_le_div_iff₀ (by positivity) (by positivity)]
  nlinarith

lemma up_energy_pos {f : ℝ → ℂ} (hf : MemLp f 2) (hc : Continuous f) (hne : f ≠ 0) :
    0 < ∫ t, ‖f t‖ ^ 2 := by
  rw [integral_pos_iff_support_of_nonneg (fun t => by positivity) (up_sq hf)]
  obtain ⟨t, ht⟩ : ∃ t, f t ≠ 0 := by
    by_contra h; push Not at h; exact hne (funext h)
  apply IsOpen.measure_pos
  · exact isOpen_ne_fun (by fun_prop) continuous_const
  · exact ⟨t, by simpa using ht⟩

lemma up_int_inner {f : ℝ → ℂ} (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (hdf : MemLp (deriv f) 2) (a : ℝ) (c : ℂ) :
    Integrable (fun t => (t - a) * inner ℝ (f t) (deriv f t + c • f t)) := by
  have hv : MemLp (fun t => deriv f t + c • f t) 2 := hdf.add (hf.const_smul c)
  have hu := up_shift hf htf a
  refine (up_prod hu hv).mono'
    ((measurable_id.sub_const a).aestronglyMeasurable.mul
      (hf.aestronglyMeasurable.inner hv.aestronglyMeasurable)) ?_
  refine Filter.Eventually.of_forall fun t => ?_
  rw [up_norm_shift, norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, mul_assoc]
  gcongr
  exact abs_real_inner_le_norm _ _

lemma up_x_int {w : ℝ → ℝ} (hw0 : ∀ x, 0 ≤ w x) (hw : Integrable w)
    (hw2 : Integrable fun x => x ^ 2 * w x) : Integrable fun x => x * w x := by
  refine (hw.add hw2).mono' (measurable_id.aestronglyMeasurable.mul hw.aestronglyMeasurable) ?_
  refine Filter.Eventually.of_forall fun t => ?_
  simp only [Pi.add_apply, norm_mul, Real.norm_eq_abs, abs_of_nonneg (hw0 t)]
  have ht : |t| ≤ 1 + t ^ 2 := by nlinarith [abs_nonneg t, sq_abs t, sq_nonneg (|t| - 1)]
  nlinarith [mul_le_mul_of_nonneg_right ht (hw0 t)]

lemma up_var_expand {w : ℝ → ℝ} (hw : Integrable w) (hw1 : Integrable fun x => x * w x)
    (hw2 : Integrable fun x => x ^ 2 * w x) (m : ℝ) :
    ∫ x, (x - m) ^ 2 * w x =
      (∫ x, x ^ 2 * w x) - 2 * m * (∫ x, x * w x) + m ^ 2 * ∫ x, w x := by
  have e : ∀ x, (x - m) ^ 2 * w x = (x ^ 2 * w x - (2 * m) * (x * w x)) + m ^ 2 * w x := by
    intro x; ring
  simp_rw [e]
  have i1 : Integrable (fun x => x ^ 2 * w x - 2 * m * (x * w x)) := hw2.sub (hw1.const_mul _)
  rw [integral_add i1 (hw.const_mul _),
    integral_sub hw2 (hw1.const_mul _), integral_const_mul, integral_const_mul]

lemma up_var {w : ℝ → ℝ} (hw0 : ∀ x, 0 ≤ w x) (hw : Integrable w)
    (hw2 : Integrable fun x => x ^ 2 * w x) {E : ℝ} (hE : ∫ x, w x = E) (hEpos : 0 < E)
    (a : ℝ) : ∫ x, (x - (∫ x, x * w x) / E) ^ 2 * w x ≤ ∫ x, (x - a) ^ 2 * w x := by
  have hw1 := up_x_int hw0 hw hw2
  rw [up_var_expand hw hw1 hw2, up_var_expand hw hw1 hw2, hE]
  set X := ∫ x, x * w x
  have : 0 ≤ (a * E - X) ^ 2 / E := by positivity
  have e : (a * E - X) ^ 2 / E = a ^ 2 * E - 2 * a * X + X ^ 2 / E := by
    field_simp; ring
  have e2 : (X / E) ^ 2 * E = X ^ 2 / E := by field_simp
  have e3 : 2 * (X / E) * X = 2 * (X ^ 2 / E) := by ring
  rw [e2, e3]
  linarith

lemma up_spread_eq {E U W : ℝ} (hE : 0 < E) (hU : 0 ≤ U) (hW : 0 ≤ W)
    (h : Real.sqrt (U / E) * Real.sqrt (W / E) = 1 / (4 * π)) :
    E ^ 2 = 16 * π ^ 2 * U * W := by
  rw [← Real.sqrt_mul (div_nonneg hU hE.le)] at h
  have hp := pi_pos
  have h2 : (Real.sqrt (U / E * (W / E))) ^ 2 = (1 / (4 * π)) ^ 2 := by rw [h]
  rw [Real.sq_sqrt (by positivity), div_mul_div_comm, div_pow] at h2
  field_simp at h2
  linarith

lemma up_spread_le {E U W : ℝ} (hE : 0 < E) (hU : 0 ≤ U)
    (h : 16 * π ^ 2 * U * W ≤ E ^ 2) :
    Real.sqrt (U / E) * Real.sqrt (W / E) ≤ 1 / (4 * π) := by
  rw [← Real.sqrt_mul (div_nonneg hU hE.le)]
  have hp := pi_pos
  rw [Real.sqrt_le_left (by positivity), div_mul_div_comm, div_pow,
    div_le_div_iff₀ (by positivity) (by positivity)]
  nlinarith

lemma up_ode {f : ℝ → ℂ} (hdiff : Differentiable ℝ f) (a b c : ℝ)
    (hae : ∀ᵐ t ∂volume, deriv f t + (-(2 * π * Complex.I * b)) • f t + (c * (t - a)) • f t = 0) :
    ∃ A : ℂ, ∀ t : ℝ, f t = A * Complex.exp (2 * π * b * t * Complex.I) *
      Complex.exp (-(((c / 2 : ℝ) : ℂ) * (t - a) ^ 2)) := by
  set φ : ℝ → ℂ := fun t =>
    Complex.exp (((c / 2 * (t - a) ^ 2 : ℝ) : ℂ) - 2 * π * Complex.I * b * t)
  have hφ : ∀ t, HasDerivAt φ (φ t * (((c * (t - a) : ℝ) : ℂ) - 2 * π * Complex.I * b)) t := by
    intro t
    have ha : HasDerivAt (fun t : ℝ => c / 2 * (t - a) ^ 2) (c * (t - a)) t := by
      have := (((hasDerivAt_id t).sub_const a).pow 2).const_mul (c / 2)
      refine this.congr_deriv ?_
      simp only [id]; ring
    have hb : HasDerivAt (fun t : ℝ => (t : ℂ)) 1 t := (hasDerivAt_id t).ofReal_comp
    have h1 := ha.ofReal_comp.sub (hb.const_mul (2 * π * Complex.I * b))
    have h2 := h1.cexp
    refine h2.congr_deriv ?_
    simp only [φ, mul_one, Pi.sub_apply]
  have hderiv : ∀ t, HasDerivAt (fun t => φ t * f t)
      (φ t * (deriv f t + (-(2 * π * Complex.I * b)) • f t + (c * (t - a)) • f t)) t := by
    intro t
    refine ((hφ t).mul (hdiff t).hasDerivAt).congr_deriv ?_
    simp only [smul_eq_mul, Complex.real_smul]; push_cast; ring
  have hd0 : (fun t => φ t * (deriv f t + (-(2 * π * Complex.I * b)) • f t +
      (c * (t - a)) • f t)) =ᵐ[volume] fun _ => (0 : ℂ) := by
    filter_upwards [hae] with t ht
    rw [ht, mul_zero]
  have hint : Integrable (fun t => φ t * (deriv f t + (-(2 * π * Complex.I * b)) • f t +
      (c * (t - a)) • f t)) := (integrable_zero ℝ ℂ volume).congr hd0.symm
  have hconst : ∀ t, φ t * f t = φ 0 * f 0 := by
    intro t
    have h1 := intervalIntegral.integral_eq_sub_of_hasDerivAt (a := 0) (b := t)
      (fun x _ => hderiv x) hint.intervalIntegrable
    have h0 : ∫ x in (0 : ℝ)..t, φ x * (deriv f x + (-(2 * π * Complex.I * b)) • f x +
        (c * (x - a)) • f x) = 0 := by
      rw [intervalIntegral.integral_congr_ae (g := fun _ => (0 : ℂ))]
      · simp
      · filter_upwards [hd0] with x hx _
        exact hx
    rw [h0] at h1
    exact (sub_eq_zero.mp h1.symm)
  refine ⟨φ 0 * f 0, fun t => ?_⟩
  have hexp : Complex.exp (2 * π * b * t * Complex.I) *
      Complex.exp (-(((c / 2 : ℝ) : ℂ) * (t - a) ^ 2)) * φ t = 1 := by
    simp only [φ]
    rw [← Complex.exp_add, ← Complex.exp_add]
    convert Complex.exp_zero using 2
    push_cast; ring
  calc f t = (Complex.exp (2 * π * b * t * Complex.I) *
      Complex.exp (-(((c / 2 : ℝ) : ℂ) * (t - a) ^ 2)) * φ t) * f t := by rw [hexp, one_mul]
    _ = _ := by rw [mul_assoc _ (φ t), hconst t]; ring

lemma up_gauss_deriv {f : ℝ → ℂ} (A : ℂ) (c t₀ ξ₀ : ℝ)
    (hform : ∀ t : ℝ, f t = A * Complex.exp (2 * π * ξ₀ * t * Complex.I) *
      Complex.exp (-(c * (t - t₀) ^ 2))) (t : ℝ) :
    deriv f t + (-(2 * π * Complex.I * ξ₀)) • f t = (-(2 * c * (t - t₀))) • f t := by
  have hfeq : f = fun t : ℝ => A * Complex.exp (2 * π * ξ₀ * t * Complex.I) *
      Complex.exp (-(c * (t - t₀) ^ 2)) := funext hform
  have hb : HasDerivAt (fun t : ℝ => (t : ℂ)) 1 t := (hasDerivAt_id t).ofReal_comp
  have h1 : HasDerivAt (fun t : ℝ => 2 * π * ξ₀ * (t : ℂ) * Complex.I)
      (2 * π * ξ₀ * 1 * Complex.I) t := (hb.const_mul _).mul_const _
  have h2 : HasDerivAt (fun t : ℝ => -((c : ℂ) * ((t : ℂ) - t₀) ^ 2))
      (-((c : ℂ) * (2 * ((t : ℂ) - t₀) ^ 1 * 1))) t := by
    have := ((hb.sub_const (t₀ : ℂ)).pow 2).const_mul (c : ℂ)
    exact this.neg
  have h3 := (h1.cexp.const_mul A).mul h2.cexp
  have hd : deriv f t = A * Complex.exp (2 * π * ξ₀ * t * Complex.I) *
      Complex.exp (-(c * (t - t₀) ^ 2)) *
        (2 * π * ξ₀ * Complex.I - 2 * c * (t - t₀)) := by
    rw [hfeq]
    refine h3.deriv.trans ?_
    ring
  rw [hd, hform t]
  simp only [smul_eq_mul, Complex.real_smul]; push_cast; ring

lemma up_exp_bound {f : ℝ → ℂ} {T : ℝ} (htime : ∀ t : ℝ, T < |t| → f t = 0) (z : ℂ) (v : ℝ) :
    ‖Complex.exp (((-2 * π * v : ℝ) : ℂ) * z * Complex.I) * f v‖ ≤
      Real.exp (2 * π * |T| * ‖z‖) * ‖f v‖ := by
  by_cases hv : f v = 0
  · simp [hv]
  have hvT : |v| ≤ T := by
    by_contra h; exact hv (htime v (not_le.mp h))
  rw [norm_mul, Complex.norm_exp]
  gcongr
  have hre : (((-2 * π * v : ℝ) : ℂ) * z * Complex.I).re = 2 * π * v * z.im := by
    simp [Complex.mul_re, Complex.mul_im]
  rw [hre]
  have h1 := Complex.abs_im_le_norm z
  have h2 : |v| ≤ |T| := hvT.trans (le_abs_self T)
  have hp := pi_pos
  calc 2 * π * v * z.im ≤ |2 * π * v * z.im| := le_abs_self _
    _ = 2 * π * (|v| * |z.im|) := by rw [abs_mul, abs_mul, abs_of_pos (by positivity)]; ring
    _ ≤ 2 * π * (|T| * ‖z‖) := by gcongr
    _ = _ := by ring

/-- **The Heisenberg–Gabor inequality.** Take a nonzero signal `f` with finite energy, with
`t f(t)` of finite energy (so the time spread is a finite standard deviation), and with a slope
`f'` of finite energy. Measure both widths as standard deviations of energy, the frequency in
hertz. Then the time spread times the frequency spread is at least `1/(4π)`:
`Δt · Δξ ≥ 1/(4π)`. -/
theorem heisenberg_gabor_uncertainty (f : ℝ → ℂ)
    (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (hdiff : Differentiable ℝ f) (hdf : MemLp (deriv f) 2) (hne : f ≠ 0) :
    1 / (4 * π) ≤ timeSpread f * freqSpread f := by
  have hf1 := up_L1 hf htf
  have hE := up_energy_pos hf hdiff.continuous hne
  obtain ⟨hWi, hV⟩ := up_V hf1 hf hdiff hdf (meanFreq f)
  have hU0 : 0 ≤ ∫ t, (t - meanTime f) ^ 2 * ‖f t‖ ^ 2 :=
    integral_nonneg fun t => by positivity
  have hW0 : 0 ≤ ∫ ξ, (ξ - meanFreq f) ^ 2 * ‖𝓕 f ξ‖ ^ 2 :=
    integral_nonneg fun t => by positivity
  have key := up_alg hE hU0 hW0 (fun l hl => by
    have := up_ineq hf htf hdiff hdf (meanTime f) (meanFreq f) l hl
    rwa [hV] at this)
  exact up_spread hE hU0 key.2

/-- **Only the bell curve meets the floor.** Under the same conditions, `Δt · Δξ = 1/(4π)` exactly
when `f` is a bell curve slid to some time `t₀` and some frequency `ξ₀`:
`f(t) = A e^(2πiξ₀t) e^(-c(t - t₀)²)` with `c > 0`. -/
theorem uncertainty_equality_iff_gaussian (f : ℝ → ℂ)
    (hf : MemLp f 2) (htf : MemLp (fun t : ℝ => (t : ℂ) * f t) 2)
    (hdiff : Differentiable ℝ f) (hdf : MemLp (deriv f) 2) (hne : f ≠ 0) :
    timeSpread f * freqSpread f = 1 / (4 * π) ↔
      ∃ (A : ℂ) (c t₀ ξ₀ : ℝ), 0 < c ∧ ∀ t : ℝ,
        f t = A * Complex.exp (2 * π * ξ₀ * t * Complex.I) * Complex.exp (-(c * (t - t₀) ^ 2)) := by
  have hf1 := up_L1 hf htf
  have hE := up_energy_pos hf hdiff.continuous hne
  have hU0 : 0 ≤ ∫ t, (t - meanTime f) ^ 2 * ‖f t‖ ^ 2 :=
    integral_nonneg fun t => by positivity
  have hW0 : 0 ≤ ∫ ξ, (ξ - meanFreq f) ^ 2 * ‖𝓕 f ξ‖ ^ 2 :=
    integral_nonneg fun t => by positivity
  constructor
  · intro heq
    obtain ⟨hWi, hV⟩ := up_V hf1 hf hdiff hdf (meanFreq f)
    have h16 := up_spread_eq hE hU0 hW0 heq
    have key := up_alg hE hU0 hW0 (fun l hl => by
      have := up_ineq hf htf hdiff hdf (meanTime f) (meanFreq f) l hl
      rwa [hV] at this)
    set a := meanTime f
    set b := meanFreq f
    set E := ∫ t, ‖f t‖ ^ 2 with hEdef
    set U := ∫ t, (t - a) ^ 2 * ‖f t‖ ^ 2
    set W := ∫ ξ, (ξ - b) ^ 2 * ‖𝓕 f ξ‖ ^ 2
    have hUpos := key.1
    set c := E / (2 * U) with hc
    set c₀ : ℂ := -(2 * π * Complex.I * b)
    have hv : MemLp (fun t => deriv f t + c₀ • f t) 2 := hdf.add (hf.const_smul c₀)
    have hpt : ∀ t, ‖(deriv f t + c₀ • f t) + (c * (t - a)) • f t‖ ^ 2 =
        ‖deriv f t + c₀ • f t‖ ^ 2 + 2 * c * ((t - a) * inner ℝ (f t) (deriv f t + c₀ • f t)) +
          c ^ 2 * ((t - a) ^ 2 * ‖f t‖ ^ 2) := by
      intro t
      rw [norm_add_sq_real, real_inner_smul_right, real_inner_comm, norm_smul, Real.norm_eq_abs,
        mul_pow, sq_abs]
      ring
    have hI := up_int_inner hf htf hdf a c₀
    have hint : Integrable (fun t => ‖(deriv f t + c₀ • f t) + (c * (t - a)) • f t‖ ^ 2) := by
      simp_rw [hpt]
      exact ((up_sq hv).add (hI.const_mul (2 * c))).add ((up_tw hf htf a).const_mul (c ^ 2))
    have hsq : ∫ t, ‖(deriv f t + c₀ • f t) + (c * (t - a)) • f t‖ ^ 2 = 0 := by
      simp_rw [hpt]
      have i1 : Integrable (fun t => ‖deriv f t + c₀ • f t‖ ^ 2 +
          2 * c * ((t - a) * inner ℝ (f t) (deriv f t + c₀ • f t))) :=
        (up_sq hv).add (hI.const_mul (2 * c))
      rw [integral_add i1 ((up_tw hf htf a).const_mul (c ^ 2)),
        integral_add (up_sq hv) (hI.const_mul (2 * c)), integral_const_mul, integral_const_mul]
      have hid := up_ident hf htf hdiff hdf a b
      rw [hV]
      have hI' : ∫ t, (t - a) * inner ℝ (f t) (deriv f t + c₀ • f t) = -E / 2 := by
        rw [hEdef]; linarith
      rw [hI', hc]
      field_simp
      nlinarith
    have hzero := (integral_eq_zero_iff_of_nonneg (fun t => by positivity) hint).1 hsq
    have hae : ∀ᵐ t ∂volume, deriv f t + (-(2 * π * Complex.I * b)) • f t +
        (c * (t - a)) • f t = 0 := by
      filter_upwards [hzero] with t ht
      have h' : ‖deriv f t + c₀ • f t + (c * (t - a)) • f t‖ ^ 2 = 0 := ht
      exact norm_eq_zero.mp ((pow_eq_zero_iff two_ne_zero).mp h')
    obtain ⟨A, hA⟩ := up_ode hdiff a b c hae
    exact ⟨A, c / 2, a, b, by positivity, hA⟩
  · rintro ⟨A, c, t₀, ξ₀, hc, hform⟩
    have hv := up_gauss_deriv A c t₀ ξ₀ hform
    set E := ∫ t, ‖f t‖ ^ 2 with hEdef
    set U₁ := ∫ t, (t - t₀) ^ 2 * ‖f t‖ ^ 2
    set W₁ := ∫ ξ, (ξ - ξ₀) ^ 2 * ‖𝓕 f ξ‖ ^ 2
    have hid := up_ident hf htf hdiff hdf t₀ ξ₀
    simp_rw [hv, real_inner_smul_right, real_inner_self_eq_norm_sq] at hid
    have e1 : ∀ t : ℝ, (t - t₀) * (-(2 * c * (t - t₀)) * ‖f t‖ ^ 2)
        = (-(2 * c)) * ((t - t₀) ^ 2 * ‖f t‖ ^ 2) := fun t => by ring
    simp_rw [e1, integral_const_mul] at hid
    obtain ⟨hW1i, hV1⟩ := up_V hf1 hf hdiff hdf ξ₀
    simp_rw [hv, norm_smul, Real.norm_eq_abs, mul_pow, sq_abs] at hV1
    have e2 : ∀ t : ℝ, (2 * c * (t - t₀)) ^ 2 * ‖f t‖ ^ 2
        = (4 * c ^ 2) * ((t - t₀) ^ 2 * ‖f t‖ ^ 2) := fun t => by ring
    simp_rw [neg_sq, e2, integral_const_mul] at hV1
    obtain ⟨hFm, hFe⟩ := up_plancherel hf1 hf
    have hUle : ∫ t, (t - meanTime f) ^ 2 * ‖f t‖ ^ 2 ≤ U₁ :=
      up_var (w := fun t => ‖f t‖ ^ 2) (fun _ => by positivity) (up_sq hf)
        (by simpa using up_tw hf htf 0) rfl hE t₀
    have hWle : ∫ ξ, (ξ - meanFreq f) ^ 2 * ‖𝓕 f ξ‖ ^ 2 ≤ W₁ :=
      up_var (w := fun ξ => ‖𝓕 f ξ‖ ^ 2) (fun _ => by positivity) (up_sq hFm)
        (by simpa using (up_V hf1 hf hdiff hdf 0).1) hFe hE ξ₀
    have hU1 : 0 ≤ U₁ := integral_nonneg fun t => by positivity
    have hW1 : 0 ≤ W₁ := integral_nonneg fun t => by positivity
    apply le_antisymm
    · apply up_spread_le hE hU0
      have hp := pi_pos
      calc 16 * π ^ 2 * (∫ t, (t - meanTime f) ^ 2 * ‖f t‖ ^ 2) *
            (∫ ξ, (ξ - meanFreq f) ^ 2 * ‖𝓕 f ξ‖ ^ 2) ≤ 16 * π ^ 2 * U₁ * W₁ := by
            gcongr
        _ = E ^ 2 := by nlinarith
    · exact heisenberg_gabor_uncertainty f hf htf hdiff hdf hne

/-- **Paley–Wiener: nothing is both time-limited and band-limited.** A signal of finite energy
that is zero outside the time window `[-T, T]` and whose transform is zero outside the band
`[-B, B]` hertz is the zero signal (zero at almost every time). -/
theorem time_limited_and_band_limited_is_zero (f : ℝ → ℂ) (T B : ℝ) (hf : MemLp f 2)
    (htime : ∀ t : ℝ, T < |t| → f t = 0) (hband : ∀ ξ : ℝ, B < |ξ| → 𝓕 f ξ = 0) :
    f =ᵐ[volume] 0 := by
  have hf1 : Integrable f := by
    rw [← integrableOn_iff_integrable_of_support_subset (s := Set.Icc (-T) T)]
    · exact (hf.restrict _).integrable (by norm_num)
    · intro t ht
      by_contra h
      rw [Set.mem_Icc, ← abs_le] at h
      exact ht (htime t (not_le.mp h))
  set F : ℂ → ℂ := fun z => ∫ v, Complex.exp (((-2 * π * v : ℝ) : ℂ) * z * Complex.I) * f v
  have hcont : ∀ z : ℂ, Continuous fun v : ℝ =>
      Complex.exp (((-2 * π * v : ℝ) : ℂ) * z * Complex.I) := fun z => by fun_prop
  have hdiffF : Differentiable ℂ F := by
    intro z₀
    have hd := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
      (F := fun z v => Complex.exp (((-2 * π * v : ℝ) : ℂ) * z * Complex.I) * f v)
      (F' := fun z v => ((-2 * π * v : ℝ) : ℂ) * Complex.I *
        (Complex.exp (((-2 * π * v : ℝ) : ℂ) * z * Complex.I) * f v))
      (x₀ := z₀) (s := Metric.ball z₀ 1)
      (bound := fun v => 2 * π * |T| * Real.exp (2 * π * |T| * (‖z₀‖ + 1)) * ‖f v‖)
      (Metric.ball_mem_nhds z₀ one_pos)
      (Filter.Eventually.of_forall fun z =>
        (hcont z).aestronglyMeasurable.mul hf1.aestronglyMeasurable)
      (hf1.norm.const_mul (Real.exp (2 * π * |T| * ‖z₀‖)) |>.mono'
        ((hcont z₀).aestronglyMeasurable.mul hf1.aestronglyMeasurable)
        (Filter.Eventually.of_forall fun v => up_exp_bound htime z₀ v))
      ((by fun_prop : Continuous fun v : ℝ => ((-2 * π * v : ℝ) : ℂ) * Complex.I).aestronglyMeasurable.mul
        ((hcont z₀).aestronglyMeasurable.mul hf1.aestronglyMeasurable))
      (Filter.Eventually.of_forall fun v z hz => by
        by_cases hv : f v = 0
        · simp [hv]
        have hvT : |v| ≤ T := by
          by_contra h; exact hv (htime v (not_le.mp h))
        have hz' : ‖z‖ ≤ ‖z₀‖ + 1 := by
          have := norm_le_norm_add_norm_sub' z z₀
          rw [Metric.mem_ball, dist_eq_norm] at hz
          linarith
        rw [norm_mul, norm_mul, Complex.norm_I, Complex.norm_real, Real.norm_eq_abs]
        have hp := pi_pos
        have hb := up_exp_bound htime z v
        have h1 : |-2 * π * v| ≤ 2 * π * |T| := by
          have e : |-2 * π * v| = 2 * π * |v| := by
            rw [abs_mul, abs_mul]; simp [abs_of_pos hp]
          rw [e]
          exact mul_le_mul_of_nonneg_left (hvT.trans (le_abs_self T)) (by positivity)
        have h2 : Real.exp (2 * π * |T| * ‖z‖) * ‖f v‖ ≤
            Real.exp (2 * π * |T| * (‖z₀‖ + 1)) * ‖f v‖ := by gcongr
        calc |-2 * π * v| * 1 * ‖Complex.exp (((-2 * π * v : ℝ) : ℂ) * z * Complex.I) * f v‖
            ≤ (2 * π * |T|) * (Real.exp (2 * π * |T| * (‖z₀‖ + 1)) * ‖f v‖) := by
              rw [mul_one]; gcongr; exact hb.trans h2
          _ = _ := by ring)
      (hf1.norm.const_mul _)
      (Filter.Eventually.of_forall fun v z _ => by
        have := ((((hasDerivAt_id z).const_mul (((-2 * π * v : ℝ) : ℂ))).mul_const
          Complex.I).cexp).mul_const (f v)
        refine this.congr_deriv ?_
        simp only [id]; ring)
    exact hd.2.differentiableAt
  have hFreal : ∀ w : ℝ, F w = 𝓕 f w := by
    intro w
    rw [Real.fourier_real_eq_integral_exp_smul]
    simp only [F, smul_eq_mul]
    congr 1; ext v; congr 2; push_cast; ring
  have hzero : Set.EqOn F 0 Set.univ := by
    have han : AnalyticOnNhd ℂ F Set.univ := fun z _ => hdiffF.analyticAt z
    refine han.eqOn_zero_of_preconnected_of_frequently_eq_zero isPreconnected_univ
      (Set.mem_univ ((|B| + 1 : ℝ) : ℂ)) ?_
    have ht : Filter.Tendsto (fun x : ℝ => (x : ℂ)) (nhdsWithin (|B| + 1) {(|B| + 1 : ℝ)}ᶜ)
        (nhdsWithin ((|B| + 1 : ℝ) : ℂ) {((|B| + 1 : ℝ) : ℂ)}ᶜ) := by
      refine Complex.continuous_ofReal.continuousWithinAt.tendsto_nhdsWithin ?_
      intro x hx
      rw [Set.mem_compl_singleton_iff] at hx ⊢
      exact fun h => hx (Complex.ofReal_injective h)
    refine ht.frequently (Filter.Eventually.frequently ?_)
    have hev : ∀ᶠ x in nhds (|B| + 1 : ℝ), B < |x| := by
      have : ∀ᶠ x in nhds (|B| + 1 : ℝ), |B| + 1 / 2 < x :=
        eventually_gt_nhds (by linarith)
      filter_upwards [this] with x hx
      have := le_abs_self B
      have := le_abs_self x
      linarith
    filter_upwards [nhdsWithin_le_nhds hev] with x hx
    rw [hFreal]; exact hband x hx
  have hF0 : ∀ ξ : ℝ, 𝓕 f ξ = 0 := fun ξ => by
    rw [← hFreal]; exact hzero (Set.mem_univ _)
  have hpl := (up_plancherel hf1 hf).2
  simp only [hF0, norm_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
    integral_zero] at hpl
  have := (integral_eq_zero_iff_of_nonneg (fun t => by positivity) (up_sq hf)).1 hpl.symm
  filter_upwards [this] with t ht
  have h' : ‖f t‖ ^ 2 = 0 := ht
  simpa using h'

/-! The drum hit: `Δt` = 10 ms = 1/100 s. -/

-- The floor `1/(4π Δt)` is 7.96 Hz to two decimals: between 7.95 Hz and 7.96 Hz.
example : (795 / 100 : ℝ) < 1 / (4 * π * (1 / 100)) ∧ 1 / (4 * π * (1 / 100)) < 796 / 100 := by
  have h1 := Real.pi_gt_d4
  have h2 := Real.pi_lt_d4
  constructor
  · rw [lt_div_iff₀ (by positivity)]; norm_num at h2 ⊢; nlinarith
  · rw [div_lt_iff₀ (by positivity)]; norm_num at h1 ⊢; nlinarith

-- So a 10 ms hit cannot occupy 5 Hz: 5 Hz is below the floor.
example : (5 : ℝ) < 1 / (4 * π * (1 / 100)) := by
  have h := Real.pi_lt_d2
  rw [lt_div_iff₀ (by positivity)]; nlinarith

-- 5 Hz as a share of the floor is exactly π/5 (0.628).
example : (5 : ℝ) / (1 / (4 * π * (1 / 100))) = π / 5 := by
  field_simp; ring

-- A 5 Hz band needs a time spread of at least `1/(4π × 5)` s, between 15 ms and 16 ms.
example : (15 / 1000 : ℝ) < 1 / (4 * π * 5) ∧ 1 / (4 * π * 5) < 16 / 1000 := by
  have h1 := Real.pi_gt_d2
  have h2 := Real.pi_lt_d2
  constructor
  · rw [lt_div_iff₀ (by positivity)]; nlinarith
  · rw [div_lt_iff₀ (by positivity)]; norm_num at h1 ⊢; nlinarith

-- In radians per second the floor is `1/(2 Δt)` = 50 rad/s, not 50 Hz.
example : (1 : ℝ) / (2 * (1 / 100)) = 50 := by norm_num

#print axioms up_selfadj
#print axioms up_L2pair
#print axioms up_unique
#print axioms up_fourier_toLp
#print axioms up_fourier_cont
#print axioms up_fourier_deriv_toLp
#print axioms up_norm_sq
#print axioms up_norm_sq_toLp
#print axioms up_plancherel
#print axioms up_freq_deriv
#print axioms up_sq
#print axioms up_prod
#print axioms up_shift
#print axioms up_norm_shift
#print axioms up_L1
#print axioms up_tw
#print axioms up_inner_imag
#print axioms up_ident
#print axioms up_ineq
#print axioms up_V
#print axioms up_alg
#print axioms up_spread
#print axioms up_energy_pos
#print axioms up_int_inner
#print axioms up_x_int
#print axioms up_var_expand
#print axioms up_var
#print axioms up_spread_eq
#print axioms up_spread_le
#print axioms up_ode
#print axioms up_gauss_deriv
#print axioms up_exp_bound
#print axioms heisenberg_gabor_uncertainty
#print axioms uncertainty_equality_iff_gaussian
#print axioms time_limited_and_band_limited_is_zero
