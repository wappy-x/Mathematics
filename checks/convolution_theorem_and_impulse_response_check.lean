-- The convolution theorem: the transform of a convolution is the product of the transforms, and the transform of a product is the convolution of the transforms, for integrable signals with an integrable spectrum or for finite-energy signals.
import Mathlib.Analysis.Fourier.Convolution
import Mathlib.Analysis.Fourier.LpSpace
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.MeasureTheory.Function.Holder
import Mathlib.Tactic.NormNum

/-! Signals are complex-valued functions of time `t : ℝ` in seconds. `𝓕 f ξ` is Mathlib's Fourier
transform in hertz, `∫ e^(−2πiξt) f(t) dt`, the card's `f̂(ξ)`. The card's convolution
`(f * g)(t) = ∫ f(s) g(t − s) ds` is Mathlib's `f ⋆[ContinuousLinearMap.mul ℂ ℂ] g`.
"In `L¹`" is `Integrable` and "in `L²`" (finite energy) is `MemLp · 2`. For a finite-energy
signal the transform is Plancherel's transform on `L²`, `𝓕 (hf.toLp f)`, read as a function
defined almost everywhere. -/

open MeasureTheory FourierTransform
open scoped Convolution

/-- The inverse transform can be moved across an integral: `∫ 𝓕⁻ H · K = ∫ H · 𝓕⁻ K`. -/
theorem conv_aux_flip_inv {H K : ℝ → ℂ} (hH : Integrable H) (hK : Integrable K) :
    ∫ η, 𝓕⁻ H η * K η = ∫ t, H t * 𝓕⁻ K t := by
  have hfl : (-innerₗ ℝ : ℝ →ₗ[ℝ] ℝ →ₗ[ℝ] ℝ).flip = -innerₗ ℝ := by
    ext; simp
  have := VectorFourier.integral_fourierIntegral_smul_eq_flip (L := (-innerₗ ℝ : ℝ →ₗ[ℝ] ℝ →ₗ[ℝ] ℝ))
    (μ := volume) (ν := volume) Real.continuous_fourierChar
    (by simp; fun_prop) hH hK
  rw [hfl] at this
  simp only [smul_eq_mul] at this
  exact this

#print axioms conv_aux_flip_inv

/-- The transform can be moved across an integral: `∫ 𝓕 H · K = ∫ H · 𝓕 K`. -/
theorem conv_aux_flip {H K : ℝ → ℂ} (hH : Integrable H) (hK : Integrable K) :
    ∫ η, 𝓕 H η * K η = ∫ t, H t * 𝓕 K t := by
  have hfl : (innerₗ ℝ : ℝ →ₗ[ℝ] ℝ →ₗ[ℝ] ℝ).flip = innerₗ ℝ := by
    ext; simp
  have := VectorFourier.integral_fourierIntegral_smul_eq_flip (L := (innerₗ ℝ : ℝ →ₗ[ℝ] ℝ →ₗ[ℝ] ℝ))
    (μ := volume) (ν := volume) Real.continuous_fourierChar
    (by simp; fun_prop) hH hK
  rw [hfl] at this
  simp only [smul_eq_mul] at this
  exact this

#print axioms conv_aux_flip

/-- Fourier inversion almost everywhere: if `f` and `𝓕 f` are in `L¹`, then `𝓕⁻ (𝓕 f) = f` a.e. -/
theorem conv_aux_inv_ae {f : ℝ → ℂ} (hf : Integrable f) (hf' : Integrable (𝓕 f)) :
    𝓕⁻ (𝓕 f) =ᵐ[volume] f := by
  have hc : Continuous (𝓕⁻ (𝓕 f)) := by
    rw [← Real.Lp.fourierTransformInv_toLp (memLp_one_iff_integrable.2 hf')]
    exact BoundedContinuousFunction.continuous _
  refine ae_eq_of_integral_contDiff_smul_eq hc.locallyIntegrable hf.locallyIntegrable ?_
  intro g hg hgs
  have hGs : HasCompactSupport (fun x => (g x : ℂ)) := hgs.comp_left Complex.ofReal_zero
  have hGd := Complex.ofRealCLM.contDiff.comp hg
  let φ : SchwartzMap ℝ ℂ := hGs.toSchwartzMap hGd
  have hφ : ∀ x, φ x = (g x : ℂ) := fun x => rfl
  have h1 : Integrable (𝓕⁻ (φ : ℝ → ℂ)) := by
    rw [← SchwartzMap.fourierInv_coe]; exact (𝓕⁻ φ).integrable
  have h2 : 𝓕 (𝓕⁻ (φ : ℝ → ℂ)) = φ := by
    rw [← SchwartzMap.fourierInv_coe, ← SchwartzMap.fourier_coe, fourier_fourierInv_eq]
  calc ∫ x, g x • 𝓕⁻ (𝓕 f) x = ∫ x, 𝓕⁻ (𝓕 f) x * φ x := by
        congr 1; ext x; rw [hφ, Complex.real_smul, mul_comm]
    _ = ∫ x, 𝓕 f x * 𝓕⁻ (φ : ℝ → ℂ) x := conv_aux_flip_inv hf' φ.integrable
    _ = ∫ x, f x * 𝓕 (𝓕⁻ (φ : ℝ → ℂ)) x := conv_aux_flip hf h1
    _ = ∫ x, g x • f x := by
        rw [h2]; congr 1; ext x; rw [hφ, Complex.real_smul, mul_comm]

#print axioms conv_aux_inv_ae

/-- Schwartz functions are dense in `L²`. -/
theorem conv_aux_dense :
    DenseRange (SchwartzMap.toLpCLM ℝ ℂ 2 (volume : Measure ℝ)) :=
  SchwartzMap.denseRange_toLpCLM ENNReal.ofNat_ne_top

#print axioms conv_aux_dense

/-- The `L²` pairing by multiplication is the integral of the product. -/
theorem conv_aux_pairing_eq_integral (u v : Lp ℂ 2 (volume : Measure ℝ)) :
    (ContinuousLinearMap.mul ℂ ℂ).lpPairing volume 2 2 u v = ∫ t, u t * v t := by
  rw [ContinuousLinearMap.lpPairing_eq_integral]
  rfl

#print axioms conv_aux_pairing_eq_integral

/-- The convolution theorem, forward direction, read as a system. If the input `x` and the impulse
response `h` both have finite area (`L¹`), the output `y = x * h` has transform
`ŷ(ξ) = ĥ(ξ) x̂(ξ)` at every frequency `ξ`: the system multiplies each frequency of the input by
one number, its frequency response `ĥ(ξ)`. -/
theorem convolution_multiplies_each_frequency {x h : ℝ → ℂ} (hx : Integrable x)
    (hh : Integrable h) (ξ : ℝ) :
    𝓕 (x ⋆[ContinuousLinearMap.mul ℂ ℂ] h) ξ = 𝓕 h ξ * 𝓕 x ξ := by
  rw [Real.fourier_mul_convolution_eq hx hh, mul_comm]

/-- The reverse direction, integrable form. If `f` and `g` are in `L¹` and `f̂` is in `L¹`, then
multiplying in time is blending in frequency: the transform of the product `f g` is the
convolution of the transforms, `(f g)^(ξ) = ∫ f̂(η) ĝ(ξ − η) dη`, at every frequency `ξ`. -/
theorem product_transforms_to_convolution {f g : ℝ → ℂ} (hf : Integrable f)
    (hg : Integrable g) (hf' : Integrable (𝓕 f)) (ξ : ℝ) :
    𝓕 (fun t => f t * g t) ξ = (𝓕 f ⋆[ContinuousLinearMap.mul ℂ ℂ] 𝓕 g) ξ := by
  set h : ℝ → ℂ := fun t => (𝐞 (-(t * ξ)) : ℂ) * g t with hh
  have hhi : Integrable h := by
    have := (Real.fourierIntegral_convergent_iff (V := ℝ) (μ := volume) ξ).2 hg
    refine this.congr (Filter.Eventually.of_forall fun t => ?_)
    simp [hh, Circle.smul_def, mul_comm]
  have key : ∀ η, 𝓕 g (ξ - η) = 𝓕⁻ h η := by
    intro η
    rw [Real.fourier_real_eq, Real.fourierInv_eq]
    congr 1; ext t
    simp only [hh, Circle.smul_def, smul_eq_mul, ← mul_assoc]
    congr 1
    rw [← Circle.coe_mul, ← AddChar.map_add_eq_mul]
    congr 2
    simp; ring
  rw [MeasureTheory.convolution_def]
  simp only [ContinuousLinearMap.mul_apply', key]
  calc 𝓕 (fun t => f t * g t) ξ = ∫ t, h t * f t := by
        rw [Real.fourier_real_eq]; congr 1; ext t
        simp [hh, Circle.smul_def]; ring
    _ = ∫ t, h t * 𝓕⁻ (𝓕 f) t := by
        apply integral_congr_ae
        filter_upwards [conv_aux_inv_ae hf hf'] with t ht
        rw [ht]
    _ = ∫ η, 𝓕⁻ h η * 𝓕 f η := (conv_aux_flip_inv hhi hf').symm
    _ = ∫ η, 𝓕 f η * 𝓕⁻ h η := by congr 1; ext η; ring

/-- The reverse direction, energy form. If `f` and `g` only have finite energy (`L²`), the product
`f g` still has finite area, and its transform is the convolution of the two `L²` transforms,
`(f g)^(ξ) = ∫ f̂(η) ĝ(ξ − η) dη`, at every frequency `ξ`, although `f̂` and `ĝ` need not have
finite area. -/
theorem product_transforms_to_convolution_of_finite_energy {f g : ℝ → ℂ} (hf : MemLp f 2)
    (hg : MemLp g 2) (ξ : ℝ) :
    𝓕 (fun t => f t * g t) ξ =
      (⇑(𝓕 (hf.toLp f) : Lp ℂ 2 (volume : Measure ℝ)) ⋆[ContinuousLinearMap.mul ℂ ℂ]
        ⇑(𝓕 (hg.toLp g) : Lp ℂ 2 (volume : Measure ℝ))) ξ := by
  set e : ℝ → ℂ := fun t => (𝐞 (-(t * ξ)) : ℂ) with he_def
  have he : MemLp e ⊤ volume := by
    refine memLp_top_of_bound ?_ 1 (Filter.Eventually.of_forall fun t => ?_)
    · exact (Continuous.comp continuous_subtype_val
        (Real.continuous_fourierChar.comp (by fun_prop))).aestronglyMeasurable
    · simp [he_def]
  set Λ := (ContinuousLinearMap.mul ℂ ℂ).lpPairing (volume : Measure ℝ) 2 2 with hΛ
  set K := (ContinuousLinearMap.mul ℂ ℂ).holderL (volume : Measure ℝ) ⊤ 2 2 (he.toLp e) with hK
  have hmp : MeasurePreserving (fun η : ℝ => ξ - η) volume volume :=
    Measure.measurePreserving_sub_left volume ξ
  set R : Lp ℂ 2 (volume : Measure ℝ) →L[ℂ] Lp ℂ 2 (volume : Measure ℝ) :=
    (Lp.compMeasurePreservingₗᵢ ℂ (fun η : ℝ => ξ - η) hmp).toContinuousLinearMap with hR
  -- the two sides as functions on `L² × L²`
  have hP : ∀ (u v : Lp ℂ 2 (volume : Measure ℝ)) (f₀ g₀ : ℝ → ℂ), u =ᵐ[volume] f₀ →
      v =ᵐ[volume] g₀ → Λ (K u) v = 𝓕 (fun t => f₀ t * g₀ t) ξ := by
    intro u v f₀ g₀ hu hv
    rw [hΛ, conv_aux_pairing_eq_integral, Real.fourier_real_eq]
    apply integral_congr_ae
    filter_upwards [hu, hv, ContinuousLinearMap.coeFn_holder (ContinuousLinearMap.mul ℂ ℂ)
      (r := 2) (he.toLp e) u, he.coeFn_toLp] with t h1 h2 h3 h4
    rw [hK, ContinuousLinearMap.holderL_apply_apply, h3, h4, h1, h2]
    simp [he_def, Circle.smul_def]; ring
  have hQ : ∀ (U V : Lp ℂ 2 (volume : Measure ℝ)) (F₀ G₀ : ℝ → ℂ), U =ᵐ[volume] F₀ →
      V =ᵐ[volume] G₀ → Λ U (R V) = (F₀ ⋆[ContinuousLinearMap.mul ℂ ℂ] G₀) ξ := by
    intro U V F₀ G₀ hU hV
    rw [hΛ, conv_aux_pairing_eq_integral, MeasureTheory.convolution_def]
    apply integral_congr_ae
    have hV' : (fun η => V (ξ - η)) =ᵐ[volume] fun η => G₀ (ξ - η) :=
      hmp.quasiMeasurePreserving.ae_eq_comp hV
    filter_upwards [hU, hV', Lp.coeFn_compMeasurePreserving V hmp] with t h1 h2 h3
    show U t * (Lp.compMeasurePreserving (fun η : ℝ => ξ - η) hmp V) t = _
    rw [h3, Function.comp_apply, h1, h2, ContinuousLinearMap.mul_apply']
  have hmain : ∀ u v : Lp ℂ 2 (volume : Measure ℝ), Λ (K u) v = Λ (𝓕 u) (R (𝓕 v)) := by
    intro u v
    refine DenseRange.induction_on₂ (p := fun u v => Λ (K u) v = Λ (𝓕 u) (R (𝓕 v)))
      conv_aux_dense ?_ ?_ u v
    · have hFc : Continuous (𝓕 : Lp ℂ 2 (volume : Measure ℝ) → Lp ℂ 2 (volume : Measure ℝ)) :=
        (Lp.fourierTransformₗᵢ ℝ ℂ).continuous
      have h1 : Continuous (fun q : Lp ℂ 2 (volume : Measure ℝ) × Lp ℂ 2 (volume : Measure ℝ) =>
          Λ (K q.1) q.2) :=
        (Λ.continuous.comp (K.continuous.comp continuous_fst)).clm_apply continuous_snd
      have h2 : Continuous (fun q : Lp ℂ 2 (volume : Measure ℝ) × Lp ℂ 2 (volume : Measure ℝ) =>
          Λ (𝓕 q.1) (R (𝓕 q.2))) :=
        (Λ.continuous.comp (hFc.comp continuous_fst)).clm_apply
          (R.continuous.comp (hFc.comp continuous_snd))
      exact isClosed_eq h1 h2
    · intro φ ψ
      simp only [SchwartzMap.toLpCLM_apply, SchwartzMap.toLp_fourier_eq]
      rw [hP _ _ φ ψ (φ.coeFn_toLp 2 volume) (ψ.coeFn_toLp 2 volume),
        hQ _ _ (𝓕 (φ : ℝ → ℂ)) (𝓕 (ψ : ℝ → ℂ)) ((𝓕 φ).coeFn_toLp 2 volume)
          ((𝓕 ψ).coeFn_toLp 2 volume)]
      exact product_transforms_to_convolution φ.integrable ψ.integrable (𝓕 φ).integrable ξ
  rw [← hP _ _ f g hf.coeFn_toLp hg.coeFn_toLp, hmain,
    hQ _ _ _ _ (Filter.EventuallyEq.refl _ _) (Filter.EventuallyEq.refl _ _)]

-- The hall: echo strength a = 1/2, echo delay T = 0.05 s = 1/20 s.
-- Walls 343 × 0.05 / 2 = 8.575 m = 343/40 m apart; peaks every 1/T = 20 Hz.
example : (343 : ℚ) * (1 / 20) / 2 = 343 / 40 ∧ 1 / ((1 : ℚ) / 20) = 20 := by norm_num
-- Cycles per echo delay: 440 × 0.05 = 22, 430 × 0.05 = 21.5, 435 × 0.05 = 21.75.
example : (440 : ℚ) * (1 / 20) = 22 ∧ (430 : ℚ) * (1 / 20) = 43 / 2 ∧
    (435 : ℚ) * (1 / 20) = 87 / 4 := by norm_num
-- ĥ(440) = 1/(1 − 0.5) = 2 and ĥ(430) = 1/(1 + 0.5) = 2/3 (0.666667).
example : 1 / (1 - (1 : ℚ) / 2) = 2 ∧ 1 / (1 + (1 : ℚ) / 2) = 2 / 3 := by norm_num
-- ĥ(435) = 1/(1 − 0.5i) = 0.8 + 0.4i, and its size squared is 0.8 = 4/5 (size 0.894427).
example : (1 : ℂ) / (1 - Complex.I / 2) = 4 / 5 + 2 / 5 * Complex.I := by
  rw [div_eq_iff (by simp [Complex.ext_iff])]
  ring_nf
  simp [Complex.I_sq]
  norm_num
example : ((4 : ℚ) / 5) ^ 2 + (2 / 5) ^ 2 = 4 / 5 := by norm_num
-- Echo build-up at 440 Hz, arrivals 0..5: 1, 1.5, 1.75, 1.875, 1.9375, 1.96875.
example : (List.range 6).map (fun n => ∑ k ∈ Finset.range (n + 1), ((1 : ℚ) / 2) ^ k) =
    [1, 3 / 2, 7 / 4, 15 / 8, 31 / 16, 63 / 32] := by
  simp [List.range_succ, Finset.sum_range_succ]; norm_num
-- Echo build-up at 430 Hz, each echo upside down: 1, 0.5, 0.75, 0.625, 0.6875, 0.65625.
example : (List.range 6).map (fun n => ∑ k ∈ Finset.range (n + 1), ((-1 : ℚ) / 2) ^ k) =
    [1, 1 / 2, 3 / 4, 5 / 8, 11 / 16, 21 / 32] := by
  simp [List.range_succ, Finset.sum_range_succ]; norm_num
-- The cut recording keeps four arrivals: 1 + 0.5 + 0.25 + 0.125 = 1.875 at the peak.
example : ∑ k ∈ Finset.range 4, ((1 : ℚ) / 2) ^ k = 15 / 8 := by
  norm_num [Finset.sum_range_succ]
-- The recording window runs from −0.025 s to 0.175 s: 0.2 s long, first zero of its spectrum 5 Hz.
example : (7 : ℚ) / 40 - (-1 / 40) = 1 / 5 ∧ 1 / ((1 : ℚ) / 5) = 5 := by norm_num
-- Walls that keep all the sound, a = 1: after 1 s (20 echoes) the 440 Hz tone is 21 times its size.
example : ∑ k ∈ Finset.range 21, (1 : ℚ) ^ k = 21 := by norm_num
-- Try changing: a = 0.8 gives 1/(1 − 0.8) = 5 at 440 Hz and 1/(1 + 0.8) = 5/9 (0.555556) at 430 Hz.
example : 1 / (1 - (4 : ℚ) / 5) = 5 ∧ 1 / (1 + (4 : ℚ) / 5) = 5 / 9 := by norm_num
-- Try changing: eight arrivals give 255/128 = 1.9921875 at 440 Hz; T = 0.1 s puts the walls 17.15 m apart.
example : ∑ k ∈ Finset.range 8, ((1 : ℚ) / 2) ^ k = 255 / 128 := by
  norm_num [Finset.sum_range_succ]
example : (343 : ℚ) * (1 / 10) / 2 = 343 / 20 := by norm_num

#print axioms convolution_multiplies_each_frequency
#print axioms product_transforms_to_convolution
#print axioms product_transforms_to_convolution_of_finite_energy
