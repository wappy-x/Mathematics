-- Short-time Fourier transform: the spectrogram of a finite-energy signal holds exactly the signal's energy times the window's energy, a window that fits inside one frequency step turns a grid of window positions into a frame with an exact energy formula, and a pitch climbing at c hertz per second draws a ridge whose squared thickness is never below c/(2π), reached by the bell window of spread 1/√(4πc).
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.LpSpace.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Topology.Algebra.InfiniteSum.ENNReal
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Fourier.LpSpace
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff

open MeasureTheory Complex Real
open scoped ENNReal

noncomputable section

namespace ShortTimeFourier

/-- The short-time Fourier transform of a signal `f` (volts, at time `s` seconds) with a real
window `w`: `V_w f(t, ξ) = ∫ f(s) · conj(w(s - t)) · e^(-2πiξs) ds`, the window centred at time
`t` and the frequency `ξ` in hertz (the card's convention, no factor in front).
The spectrogram is `|V_w f(t, ξ)|²`. -/
def stft (w : ℝ → ℝ) (f : ℝ → ℂ) (t ξ : ℝ) : ℂ :=
  ∫ s : ℝ, f s * starRingEnd ℂ ((w (s - t) : ℝ) : ℂ) * Complex.exp (-2 * π * I * ξ * s)

/-- The overlap `G(s) = ∑ₘ w(s - m a)²`: the sum of all copies of `w²` moved by whole
multiples of the time step `a`. -/
def overlap (w : ℝ → ℝ) (a s : ℝ) : ℝ≥0∞ :=
  ∑' m : ℤ, ‖w (s - m * a)‖ₑ ^ 2

/-! Helper lemmas. -/

section Helpers

open FourierTransform SchwartzMap

lemma fourier_continuous_of_integrable (F : ℝ → ℂ) (h1 : Integrable F) : Continuous (𝓕 F) :=
  VectorFourier.fourierIntegral_continuous Real.continuous_fourierChar
    (innerSL ℝ).continuous₂ h1

lemma l2_fourier_ae_eq (F : ℝ → ℂ) (h1 : Integrable F) (h2 : MemLp F 2) :
    ((𝓕 (h2.toLp F) : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ) =ᵐ[volume] 𝓕 F := by
  set U := (𝓕 (h2.toLp F) : Lp ℂ 2 (volume : Measure ℝ))
  have key : ∀ g : 𝓢(ℝ, ℂ), ∫ x, g x • U x = ∫ x, g x • 𝓕 F x := by
    intro g
    have e1 : (U : 𝓢'(ℝ, ℂ)) g = ∫ x, g x • U x := Lp.toTemperedDistribution_apply _ _
    rw [← e1, ← Lp.fourier_toTemperedDistribution_eq, TemperedDistribution.fourier_apply,
      Lp.toTemperedDistribution_apply]
    rw [integral_congr_ae (h2.coeFn_toLp.mono fun x hx => by rw [hx])]
    have := VectorFourier.integral_fourierIntegral_smul_eq_flip (L := innerₗ ℝ) (μ := volume) (ν := volume)
      Real.continuous_fourierChar continuous_inner g.integrable h1
    rw [fourier_coe]
    have hflip : (innerₗ ℝ : ℝ →ₗ[ℝ] ℝ →ₗ[ℝ] ℝ).flip = innerₗ ℝ := by
      ext; simp
    rw [hflip] at this
    exact this
  have hUloc : LocallyIntegrable (U : ℝ → ℂ) volume :=
    (Lp.memLp U).locallyIntegrable (by norm_num)
  have hFc := fourier_continuous_of_integrable F h1
  have hloc : LocallyIntegrable (fun x => U x - 𝓕 F x) volume :=
    hUloc.sub hFc.locallyIntegrable
  have := ae_eq_zero_of_integral_contDiff_smul_eq_zero hloc ?_
  · filter_upwards [this] with x hx
    exact sub_eq_zero.mp hx
  intro g g_smooth g_cpt
  have hg₁ : HasCompactSupport (Complex.ofRealCLM ∘ g) := g_cpt.comp_left rfl
  have hg₂ := (Complex.ofRealCLM.contDiff).comp g_smooth
  have := key (hg₁.toSchwartzMap hg₂)
  simp at this
  simp_rw [smul_sub]
  rw [integral_sub (hUloc.integrable_smul_left_of_hasCompactSupport g_smooth.continuous g_cpt)
    (hFc.locallyIntegrable.integrable_smul_left_of_hasCompactSupport g_smooth.continuous g_cpt)]
  simp_rw [Complex.real_smul]
  rw [this, sub_self]

lemma lintegral_sq_eq_of_eLpNorm_eq {F G : ℝ → ℂ} (hF : AEStronglyMeasurable F volume)
    (hG : AEStronglyMeasurable G volume) (h : eLpNorm F 2 volume = eLpNorm G 2 volume) :
    ∫⁻ x, ‖F x‖ₑ ^ 2 = ∫⁻ x, ‖G x‖ₑ ^ 2 := by
  rw [eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num) hF,
    eLpNorm_eq_lintegral_rpow_enorm_toReal (by norm_num) (by norm_num) hG] at h
  have h' := ENNReal.rpow_left_injective (x := 1 / (2 : ℝ≥0∞).toReal) (by norm_num) h
  have e2 : (2 : ℝ≥0∞).toReal = ((2 : ℕ) : ℝ) := by norm_num
  simp only [e2, ENNReal.rpow_natCast] at h'
  exact h'

lemma plancherel_lintegral (F : ℝ → ℂ) (h1 : Integrable F) (h2 : MemLp F 2) :
    ∫⁻ ξ, ‖𝓕 F ξ‖ₑ ^ 2 = ∫⁻ x, ‖F x‖ₑ ^ 2 := by
  apply lintegral_sq_eq_of_eLpNorm_eq
    (fourier_continuous_of_integrable F h1).aestronglyMeasurable h2.aestronglyMeasurable
  have hn := Lp.norm_fourier_eq (h2.toLp F)
  rw [Lp.norm_def, Lp.norm_def] at hn
  rw [← eLpNorm_congr_ae (l2_fourier_ae_eq F h1 h2), ← eLpNorm_congr_ae h2.coeFn_toLp]
  exact (ENNReal.toReal_eq_toReal_iff' (Lp.eLpNorm_ne_top _) (Lp.eLpNorm_ne_top _)).mp hn

lemma memLp_two_iff_lintegral {E : Type*} [NormedAddCommGroup E] {F : ℝ → E}
    (hF : AEStronglyMeasurable F volume) :
    MemLp F 2 volume ↔ ∫⁻ x, ‖F x‖ₑ ^ 2 < ⊤ := by
  have e2 : (2 : ℝ≥0∞).toReal = ((2 : ℕ) : ℝ) := by norm_num
  have := eLpNorm_lt_top_iff_lintegral_rpow_enorm_lt_top (μ := volume) (p := 2) (by norm_num)
    (by norm_num) hF
  simp only [e2, ENNReal.rpow_natCast] at this
  constructor
  · intro h; exact this.mp h.eLpNorm_lt_top
  · intro h; exact this.mpr h

lemma enorm_ofReal_complex (r : ℝ) : ‖(r : ℂ)‖ₑ = ‖r‖ₑ := by
  rw [← ofReal_norm, ← ofReal_norm, Complex.norm_real]

lemma stft_eq_fourier (w : ℝ → ℝ) (f : ℝ → ℂ) (t ξ : ℝ) :
    stft w f t ξ = 𝓕 (fun s => f s * ((w (s - t) : ℝ) : ℂ)) ξ := by
  rw [fourier_real_eq_integral_exp_smul, stft]
  congr 1; ext s
  rw [Complex.conj_ofReal, smul_eq_mul, mul_comm]
  congr 1; push_cast; ring_nf

lemma stft_row_sum (w : ℝ → ℝ) (b α : ℝ) (hb : 0 < b)
    (hcont : Continuous w) (hsupp : ∀ s, s ∉ Set.Icc α (α + 1 / b) → w s = 0)
    (f : ℝ → ℂ) (hf : MemLp f 2 volume) (t : ℝ) :
    ∑' n : ℤ, ‖stft w f t (n * b)‖ₑ ^ 2
      = ENNReal.ofReal (1 / b) * ∫⁻ s : ℝ, ‖f s‖ₑ ^ 2 * ‖w (s - t)‖ₑ ^ 2 := by
  set T : ℝ := 1 / b with hT
  have hTpos : 0 < T := by positivity
  set c : ℝ := α + t with hc
  have hcT : c < c + T := by linarith
  set g : ℝ → ℂ := fun s => ((w (s - t) : ℝ) : ℂ) with hg
  set F : ℝ → ℂ := fun s => f s * g s with hF
  have hgz : ∀ s, s ∉ Set.Icc c (c + T) → g s = 0 := by
    intro s hs
    have : s - t ∉ Set.Icc α (α + 1 / b) := by
      intro h; apply hs; constructor <;> [linarith [h.1]; linarith [h.2]]
    simp [hg, hsupp _ this]
  have hFz : ∀ s, s ∉ Set.Icc c (c + T) → F s = 0 := by
    intro s hs; simp [hF, hgz s hs]
  have hgc : Continuous g := by fun_prop
  have hgcs : HasCompactSupport g :=
    HasCompactSupport.intro isCompact_Icc hgz
  have hgtop : MemLp g ⊤ volume := hgc.memLp_top_of_hasCompactSupport hgcs volume
  have hF2 : MemLp F 2 volume := hf.fun_mul hgtop
  -- each STFT value is T times a Fourier coefficient on [c, c + T]
  have hcoeff : ∀ n : ℤ, stft w f t (n * b) = (T : ℂ) * fourierCoeffOn hcT F n := by
    intro n
    rw [fourierCoeffOn_eq_integral, stft]
    simp_rw [fourier_coe_apply]
    have hcc : c + T - c = T := by ring
    rw [hcc, intervalIntegral.integral_of_le hcT.le]
    rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Set.Icc c (c + T)), 
      integral_Icc_eq_integral_Ioc, Complex.real_smul, ← mul_assoc, ← Complex.ofReal_mul,
      mul_one_div_cancel hTpos.ne', Complex.ofReal_one, one_mul]
    · refine setIntegral_congr_fun measurableSet_Ioc fun x _ => ?_
      simp only [hF, hg, Complex.conj_ofReal, smul_eq_mul]
      rw [mul_comm]
      congr 1
      rw [hT]; push_cast
      field_simp
    · intro x hx
      have h0 := hgz x hx
      simp only [hg, Complex.ofReal_eq_zero] at h0
      simp [h0]
  have hpar := hasSum_sq_fourierCoeffOn hcT (hF2.restrict (Set.Ioc c (c + T)))
  set J : ℝ := ∫ x, ‖F x‖ ^ 2 with hJ
  have hJ' : ∫ x in c..c + T, ‖F x‖ ^ 2 = J := by
    rw [intervalIntegral.integral_of_le hcT.le, ← integral_Icc_eq_integral_Ioc]
    apply setIntegral_eq_integral_of_forall_compl_eq_zero
    intro x hx; simp [hFz x hx]
  have hcc : c + T - c = T := by ring
  rw [hJ', hcc] at hpar
  have hsum : HasSum (fun n : ℤ => ‖stft w f t (n * b)‖ ^ 2) (T * J) := by
    have := hpar.mul_left (T ^ 2)
    convert this using 1
    · ext n; rw [hcoeff, norm_mul, Complex.norm_real, Real.norm_of_nonneg hTpos.le]; ring
    · rw [smul_eq_mul]; field_simp
  have henorm : ∀ z : ℂ, ‖z‖ₑ ^ 2 = ENNReal.ofReal (‖z‖ ^ 2) := fun z => by
    rw [ENNReal.ofReal_pow (norm_nonneg _), ofReal_norm]
  have hFint : Integrable (fun x => ‖F x‖ ^ 2) volume :=
    (memLp_two_iff_integrable_sq_norm hF2.aestronglyMeasurable).mp hF2
  simp_rw [henorm]
  rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => by positivity) hsum.summable, hsum.tsum_eq,
    ENNReal.ofReal_mul hTpos.le, hJ,
    ofReal_integral_eq_lintegral_ofReal hFint (Filter.Eventually.of_forall fun x => by positivity)]
  congr 1
  apply lintegral_congr
  intro x
  rw [← henorm, ← henorm]
  simp only [hF, hg, enorm_mul, mul_pow, enorm_ofReal_complex]

lemma ridge_eq_iff_aux (c Δt Δξ : ℝ) (hc : 0 < c)
    (hU : 1 / (4 * π) ≤ Δt * Δξ) :
    c / (2 * π) ≤ Δξ ^ 2 + c ^ 2 * Δt ^ 2 ∧
    (Δξ ^ 2 + c ^ 2 * Δt ^ 2 = c / (2 * π) ↔ Δt * Δξ = 1 / (4 * π) ∧ Δξ = c * Δt) := by
  set k := 1 / (4 * π) with hk
  have hπ : 0 < π := pi_pos
  have hck : c / (2 * π) = 2 * c * k := by rw [hk]; field_simp; ring
  rw [hck]
  have hsq : 0 ≤ (Δξ - c * Δt) ^ 2 := sq_nonneg _
  have h2 : 2 * c * k ≤ 2 * c * (Δt * Δξ) := by nlinarith
  refine ⟨by nlinarith, ⟨fun h => ?_, fun ⟨h1, h2⟩ => ?_⟩⟩
  · have hz : (Δξ - c * Δt) ^ 2 = 0 := by nlinarith
    have hz' : Δξ - c * Δt = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp hz
    refine ⟨?_, by linarith⟩
    have : c * (Δt * Δξ) = c * k := by nlinarith
    exact (mul_left_cancel₀ hc.ne' this)
  · rw [← h1, h2]; ring

end Helpers

#print axioms fourier_continuous_of_integrable
#print axioms l2_fourier_ae_eq
#print axioms lintegral_sq_eq_of_eLpNorm_eq
#print axioms plancherel_lintegral
#print axioms memLp_two_iff_lintegral
#print axioms enorm_ofReal_complex
#print axioms stft_eq_fourier
#print axioms stft_row_sum
#print axioms ridge_eq_iff_aux

/-- **Nothing is lost (the energy identity).** For every finite-energy signal `f` and every
real finite-energy window `w`, the spectrogram's total brightness, its integral over every time
`t` and every frequency `ξ`, equals the signal's energy times the window's energy:
`∫∫ |V_w f(t, ξ)|² dξ dt = ‖f‖² ‖w‖²`. -/
theorem stft_energy_identity (f : ℝ → ℂ) (w : ℝ → ℝ)
    (hf : MemLp f 2 volume) (hw : MemLp w 2 volume) :
    ∫⁻ t : ℝ, ∫⁻ ξ : ℝ, ‖stft w f t ξ‖ₑ ^ 2
      = (∫⁻ s : ℝ, ‖f s‖ₑ ^ 2) * ∫⁻ s : ℝ, ‖w s‖ₑ ^ 2 := by
  set Ft : ℝ → ℝ → ℂ := fun t s => f s * ((w (s - t) : ℝ) : ℂ) with hFt
  have hwt : ∀ t, MemLp (fun s => ((w (s - t) : ℝ) : ℂ)) 2 volume := fun t =>
    (hw.comp_measurePreserving (measurePreserving_sub_right volume t)).ofReal
  have hint : ∀ t, Integrable (Ft t) volume := fun t => hf.integrable_mul (hwt t)
  set g : ℝ → ℝ → ℝ≥0∞ := fun t s => ‖f s‖ₑ ^ 2 * ‖w (s - t)‖ₑ ^ 2 with hg
  have hq : QuasiMeasurePreserving (fun p : ℝ × ℝ => p.2 - p.1)
      (volume.prod volume) volume :=
    (quasiMeasurePreserving_sub volume volume).comp
      Measure.measurePreserving_swap.quasiMeasurePreserving
  have hgm : AEMeasurable (Function.uncurry g) (volume.prod volume) := by
    show AEMeasurable (fun p : ℝ × ℝ => ‖f p.2‖ₑ ^ 2 * ‖w (p.2 - p.1)‖ₑ ^ 2) _
    exact AEMeasurable.mul (f := fun p : ℝ × ℝ => ‖f p.2‖ₑ ^ 2)
      (g := fun p : ℝ × ℝ => ‖w (p.2 - p.1)‖ₑ ^ 2)
      ((hf.aestronglyMeasurable.enorm.pow_const 2).comp_snd)
      ((hw.aestronglyMeasurable.enorm.pow_const 2).comp_quasiMeasurePreserving hq)
  have hfF := (memLp_two_iff_lintegral hf.aestronglyMeasurable).mp hf
  have hwF := (memLp_two_iff_lintegral hw.aestronglyMeasurable).mp hw
  have htot : ∫⁻ t, ∫⁻ s, g t s = (∫⁻ s : ℝ, ‖f s‖ₑ ^ 2) * ∫⁻ s : ℝ, ‖w s‖ₑ ^ 2 := by
    rw [lintegral_lintegral_swap hgm, ← lintegral_mul_const' _ _ hwF.ne]
    congr 1; ext s
    simp only [hg]
    rw [lintegral_const_mul' _ _ (by simp)]
    congr 1
    exact lintegral_sub_left_eq_self (fun x => ‖w x‖ₑ ^ 2) s
  have hfin : (∫⁻ s : ℝ, ‖f s‖ₑ ^ 2) * ∫⁻ s : ℝ, ‖w s‖ₑ ^ 2 ≠ ⊤ :=
    ENNReal.mul_ne_top hfF.ne hwF.ne
  have hae : ∀ᵐ t, ∫⁻ s, g t s < ⊤ :=
    ae_lt_top' hgm.lintegral_prod_right' (htot ▸ hfin)
  rw [← htot]
  apply lintegral_congr_ae
  filter_upwards [hae] with t ht
  have hgt : ∀ s, ‖Ft t s‖ₑ ^ 2 = g t s := fun s => by
    simp only [hFt, hg, enorm_mul, mul_pow, enorm_ofReal_complex]
  have h2 : MemLp (Ft t) 2 volume := by
    rw [memLp_two_iff_lintegral (hint t).aestronglyMeasurable]
    simp_rw [hgt]; exact ht
  simp_rw [stft_eq_fourier]
  rw [plancherel_lintegral _ (hint t) h2]
  simp_rw [hgt]

/-- **A grid is enough when the window fits in one frequency step (the painless frame).**
Take time step `a > 0`, frequency step `b > 0`, and a real continuous window `w` that is zero
outside an interval `[α, α + 1/b]` of length `1/b`. The grid values
`⟨f, g_{m,n}⟩ = V_w f(m a, n b)`, with `g_{m,n}(s) = w(s - m a) e^(2πi n b s)`, pick up
exactly `∑_{m,n} |⟨f, g_{m,n}⟩|² = (1/b) ∫ |f(s)|² G(s) ds` from every finite-energy signal `f`.
So whenever `A ≤ G ≤ B` everywhere, the grid's energy lies between `A/b` and `B/b` times the
signal's energy: these are the frame bounds. -/
theorem painless_gabor_frame (w : ℝ → ℝ) (a b α : ℝ) (ha : 0 < a) (hb : 0 < b)
    (hcont : Continuous w) (hsupp : ∀ s, s ∉ Set.Icc α (α + 1 / b) → w s = 0)
    (f : ℝ → ℂ) (hf : MemLp f 2 volume) :
    (∑' p : ℤ × ℤ, ‖stft w f (p.1 * a) (p.2 * b)‖ₑ ^ 2
        = ENNReal.ofReal (1 / b) * ∫⁻ s : ℝ, ‖f s‖ₑ ^ 2 * overlap w a s) ∧
    (∀ A B : ℝ≥0∞, (∀ s, A ≤ overlap w a s ∧ overlap w a s ≤ B) →
        ENNReal.ofReal (1 / b) * A * ∫⁻ s : ℝ, ‖f s‖ₑ ^ 2
          ≤ ∑' p : ℤ × ℤ, ‖stft w f (p.1 * a) (p.2 * b)‖ₑ ^ 2 ∧
        ∑' p : ℤ × ℤ, ‖stft w f (p.1 * a) (p.2 * b)‖ₑ ^ 2
          ≤ ENNReal.ofReal (1 / b) * B * ∫⁻ s : ℝ, ‖f s‖ₑ ^ 2) := by
  have hrow : ∀ m : ℤ, ∑' n : ℤ, ‖stft w f (m * a) (n * b)‖ₑ ^ 2
      = ENNReal.ofReal (1 / b) * ∫⁻ s, ‖f s‖ₑ ^ 2 * ‖w (s - m * a)‖ₑ ^ 2 :=
    fun m => stft_row_sum w b α hb hcont hsupp f hf (m * a)
  have hfm : AEMeasurable (fun s => ‖f s‖ₑ ^ 2) volume :=
    hf.aestronglyMeasurable.enorm.pow_const 2
  have hmain : ∑' p : ℤ × ℤ, ‖stft w f (p.1 * a) (p.2 * b)‖ₑ ^ 2
      = ENNReal.ofReal (1 / b) * ∫⁻ s : ℝ, ‖f s‖ₑ ^ 2 * overlap w a s := by
    rw [tsum_prod (f := fun m n : ℤ => ‖stft w f (m * a) (n * b)‖ₑ ^ 2)]
    simp_rw [hrow]
    rw [ENNReal.tsum_mul_left, ← lintegral_tsum]
    · congr 1
      apply lintegral_congr
      intro s
      rw [overlap, ENNReal.tsum_mul_left]
    · intro m
      exact hfm.mul
        ((hcont.measurable.comp (measurable_sub_const _)).enorm.pow_const 2).aemeasurable
  refine ⟨hmain, fun A B hAB => ⟨?_, ?_⟩⟩
  · rw [hmain, mul_assoc]
    gcongr
    calc A * ∫⁻ s, ‖f s‖ₑ ^ 2 ≤ ∫⁻ s, A * ‖f s‖ₑ ^ 2 := lintegral_const_mul_le _ _
      _ ≤ ∫⁻ s, ‖f s‖ₑ ^ 2 * overlap w a s := by
        apply lintegral_mono
        intro s
        simp only
        rw [mul_comm]
        exact mul_le_mul_right (hAB s).1 _
  · rw [hmain, mul_assoc]
    gcongr
    calc ∫⁻ s, ‖f s‖ₑ ^ 2 * overlap w a s ≤ ∫⁻ s, ‖f s‖ₑ ^ 2 * B := by
          apply lintegral_mono
          intro s
          exact mul_le_mul_right (hAB s).2 _
      _ = B * ∫⁻ s, ‖f s‖ₑ ^ 2 := by rw [lintegral_mul_const'' _ hfm, mul_comm]

/-- **There is a sharpest picture (the ridge floor).** A pitch climbing at `c > 0` hertz per
second, seen through a window with time spread `Δt` and frequency spread `Δξ` obeying the
uncertainty principle `Δt · Δξ ≥ 1/(4π)`, draws a ridge of squared thickness
`R² = Δξ² + c² Δt²`, which is never below `c/(2π)`. Equality holds exactly when the product is
`1/(4π)` and the window's smear equals the climb across it, `Δξ = c Δt`. For the bell window of
spread `σ > 0`, where `Δt = σ` and `Δξ = 1/(4πσ)`, the floor is reached exactly at
`σ = 1/√(4πc)`. -/
theorem ridge_floor (c Δt Δξ : ℝ) (hc : 0 < c) (ht : 0 ≤ Δt) (hξ : 0 ≤ Δξ)
    (hU : 1 / (4 * π) ≤ Δt * Δξ) :
    c / (2 * π) ≤ Δξ ^ 2 + c ^ 2 * Δt ^ 2 ∧
    (Δξ ^ 2 + c ^ 2 * Δt ^ 2 = c / (2 * π) ↔ Δt * Δξ = 1 / (4 * π) ∧ Δξ = c * Δt) ∧
    (∀ σ : ℝ, 0 < σ →
      ((1 / (4 * π * σ)) ^ 2 + c ^ 2 * σ ^ 2 = c / (2 * π) ↔ σ = 1 / Real.sqrt (4 * π * c))) := by
  obtain ⟨h1, h2⟩ := ridge_eq_iff_aux c Δt Δξ hc hU
  refine ⟨h1, h2, fun σ hσ => ?_⟩
  have hπ : 0 < π := pi_pos
  have hprod : σ * (1 / (4 * π * σ)) = 1 / (4 * π) := by field_simp
  obtain ⟨-, h3⟩ := ridge_eq_iff_aux c σ (1 / (4 * π * σ)) hc hprod.ge
  rw [h3]
  have hpos : 0 < 4 * π * c := by positivity
  have hs : 0 < Real.sqrt (4 * π * c) := Real.sqrt_pos.mpr hpos
  have hss : Real.sqrt (4 * π * c) ^ 2 = 4 * π * c := Real.sq_sqrt hpos.le
  constructor
  · rintro ⟨-, h⟩
    -- 1 = 4 π c σ²
    have hE : 4 * π * c * σ ^ 2 = 1 := by
      field_simp at h; nlinarith
    have hE2 : (Real.sqrt (4 * π * c) * σ) ^ 2 = 1 := by rw [mul_pow, hss]; exact hE
    have hE3 : Real.sqrt (4 * π * c) * σ = 1 := by
      have hx : 0 ≤ Real.sqrt (4 * π * c) * σ := by positivity
      nlinarith
    field_simp; linarith
  · intro h
    refine ⟨hprod, ?_⟩
    rw [h]
    field_simp
    rw [hss]

/-! The card's whole-number and fraction checks. -/

/-- The climb rate: from 2000 Hz to 4000 Hz in 10 s is 200 Hz per second. -/
example : ((4000 : ℚ) - 2000) / 10 = 200 := by norm_num

/-- Ten seconds at 16,000 samples a second is 160,000 samples, which a hop of 320 samples
(20 ms) cuts into 500 columns. -/
example : 10 * 16000 = 160000 ∧ 500 * 320 = 160000 ∧ (320 : ℚ) / 16000 = 1 / 50 := by norm_num

/-- The frequency step `b = 16000/4096 = 125/32` Hz (3.906250 Hz), so `1/b = 4096/16000` s
is 256 ms, and the grid density is `ab = 320/4096 = 5/64` (0.078125). -/
example : (16000 : ℚ) / 4096 = 125 / 32 ∧ (4096 : ℚ) / 16000 * 1000 = 256 ∧
    ((320 : ℚ) / 16000) * (16000 / 4096) = 5 / 64 := by norm_num

/-- The cut bell spans 2 · 1915 + 1 = 3831 samples, which fits inside one 4096-point FFT
(the painless case); a hop of 4000 samples (250 ms) leaves 169 samples of every hop under
no window, although 4096/4000 = 128/125 (1.024) numbers per sample. -/
example : 2 * 1915 + 1 = 3831 ∧ 3831 ≤ 4096 ∧ 4000 - 3831 = 169 ∧
    (4096 : ℚ) / 4000 = 128 / 125 := by norm_num

/-- With the bell's energy `‖w‖² = 1/20` s and the hop `a = 1/50` s, the overlap is
`G = (1/20)/(1/50) = 5/2`, the frame bounds are `A = B = G/b = (5/2)/(125/32) = 16/25` s
(0.64 s), the grid picks up `16/25 · 5 = 16/5` V²·s² (3.2), and the total brightness is
`5 · 1/20 = 1/4` V²·s² (0.25). -/
example : ((1 : ℚ) / 20) / (1 / 50) = 5 / 2 ∧ ((5 : ℚ) / 2) / (125 / 32) = 16 / 25 ∧
    (16 : ℚ) / 25 * 5 = 16 / 5 ∧ (5 : ℚ) * (1 / 20) = 1 / 4 := by norm_num

/-- The density theorem's failing grid: 128 frequencies with a hop of 160 samples gives
128,000 numbers for 160,000 samples, and `ab = 160/128 = 5/4 > 1`. -/
example : 128 * (160000 / 160) = 128000 ∧ 128000 < 160000 ∧
    (160 : ℚ) / 128 = 5 / 4 ∧ (1 : ℚ) < 5 / 4 := by norm_num

#print axioms stft_energy_identity
#print axioms painless_gabor_frame
#print axioms ridge_floor

end ShortTimeFourier
