-- Plancherel: on rapidly decreasing signals the transform keeps energy, and its extension to all square-integrable signals keeps every energy and distance, is the energy-limit of the transforms of rapidly decreasing approximations, and is one to one and onto.
import Mathlib.Analysis.Fourier.LpSpace

open MeasureTheory Filter Topology SchwartzMap
open scoped FourierTransform ComplexInnerProductSpace

noncomputable section


/-- The finite-energy signals on the time line: `L²(ℝ)`, complex valued, with Lebesgue measure. -/
abbrev L2Signal := Lp ℂ 2 (volume : Measure ℝ)

/-- **Plancherel.** For every rapidly decreasing signal `f` (a Schwartz function `ℝ → ℂ`), with the
hertz-form transform `f̂(ξ) = ∫ f(t) e^(-2πiξt) dt` (Mathlib's `𝓕`), the energy summed over
frequencies equals the energy summed over time: `∫ |f̂(ξ)|² dξ = ∫ |f(t)|² dt`.
And the transform `𝓕` on all finite-energy signals `L²(ℝ)` extends it by limits: whenever
rapidly decreasing `φₙ` approach `f` in energy, the transforms `φ̂ₙ` approach `𝓕 f` in energy;
and `𝓕` keeps every distance, `‖𝓕 f - 𝓕 g‖₂ = ‖f - g‖₂` (so, with `g = 0`, every energy). -/
theorem plancherel_energy_and_extension_to_L2 :
    (∀ f : 𝓢(ℝ, ℂ), ∫ ξ, ‖𝓕 (f : ℝ → ℂ) ξ‖ ^ 2 = ∫ t, ‖f t‖ ^ 2) ∧
    (∀ (f : L2Signal) (φ : ℕ → 𝓢(ℝ, ℂ)),
      Tendsto (fun n => (φ n).toLp 2) atTop (𝓝 f) →
      Tendsto (fun n => (𝓕 (φ n)).toLp 2) atTop (𝓝 (𝓕 f : L2Signal))) ∧
    (∀ f g : L2Signal, ‖(𝓕 f : L2Signal) - 𝓕 g‖ = ‖f - g‖) := by
  refine ⟨fun f => ?_, fun f φ hφ => ?_, fun f g => ?_⟩
  · simpa [SchwartzMap.fourier_coe] using SchwartzMap.integral_norm_sq_fourier f
  · have hc : Continuous (fun x : L2Signal => (𝓕 x : L2Signal)) :=
      (MeasureTheory.Lp.fourierTransformₗᵢ ℝ ℂ).continuous
    have := (hc.tendsto f).comp hφ
    simpa [Function.comp_def, SchwartzMap.toLp_fourier_eq] using this
  · have h := (MeasureTheory.Lp.fourierTransformₗᵢ ℝ ℂ).norm_map (f - g)
    rw [map_sub] at h
    exact h

/-- **Step 2: the transform keeps inner products.** For every two rapidly decreasing signals
`f` and `h`, `⟨f̂, ĥ⟩ = ∫ f̂(ξ) conj(ĥ(ξ)) dξ` equals `⟨f, h⟩ = ∫ f(t) conj(h(t)) dt`. -/
theorem fourier_keeps_inner_product_schwartz (f h : 𝓢(ℝ, ℂ)) :
    ∫ ξ, 𝓕 (f : ℝ → ℂ) ξ * starRingEnd ℂ (𝓕 (h : ℝ → ℂ) ξ) =
      ∫ t, f t * starRingEnd ℂ (h t) := by
  have := SchwartzMap.integral_inner_fourier_fourier h f
  simpa [SchwartzMap.fourier_coe, RCLike.inner_apply] using this

/-- **Step 6: the map is onto, so it can be undone.** The transform `𝓕` on `L²(ℝ)` is one to one
and onto: every finite-energy spectrum belongs to exactly one finite-energy signal. -/
theorem fourier_L2_bijective : Function.Bijective (fun f : L2Signal => (𝓕 f : L2Signal)) := by
  exact (MeasureTheory.Lp.fourierTransformₗᵢ ℝ ℂ).bijective


#print axioms plancherel_energy_and_extension_to_L2
#print axioms fourier_keeps_inner_product_schwartz
#print axioms fourier_L2_bijective
