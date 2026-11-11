-- Conformal maps: where f'(a) is not zero a holomorphic f multiplies small arrows at a by f'(a), keeps crossing angles and has a holomorphic inverse near a (not always a global one), and Mercator's chart is -i Log of the stereographic globe.
import Mathlib.Analysis.Complex.Conformal
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.Deriv
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.ContDiff
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum

open Filter Topology Complex Asymptotics

/-- The card's main claim. Let f be holomorphic near a (complex differentiable at every point
near a) with f'(a) not zero. Then:
1. f(a + h) = f(a) + f'(a) h + ε(h) h with ε(h) → 0, that is, the error is small next to h;
2. as a map of the plane, f multiplies every small arrow u at a by f'(a);
3. so the angle from one arrow to another, direction included, is the same after the map:
   arg (f'(a) u / f'(a) v) = arg (u / v), and f is conformal at a in Mathlib's sense;
4. near a, f has a holomorphic inverse g: g undoes f near a, f undoes g near f(a), and
   g'(w) = 1 / f'(g(w)) at every w near f(a). -/
theorem holomorphic_nonzero_derivative_conformal {f : ℂ → ℂ} {a : ℂ}
    (hf : ∀ᶠ z in 𝓝 a, DifferentiableAt ℂ f z) (ha : deriv f a ≠ 0) :
    ((fun h : ℂ => f (a + h) - f a - deriv f a * h) =o[𝓝 0] fun h : ℂ => h) ∧
    (∀ u : ℂ, fderiv ℝ f a u = deriv f a * u) ∧
    (∀ u v : ℂ, u ≠ 0 → v ≠ 0 →
      Complex.arg (fderiv ℝ f a u / fderiv ℝ f a v) = Complex.arg (u / v)) ∧
    ConformalAt f a ∧
    ∃ g : ℂ → ℂ, (∀ᶠ z in 𝓝 a, g (f z) = z) ∧ (∀ᶠ w in 𝓝 (f a), f (g w) = w) ∧
      (∀ᶠ w in 𝓝 (f a), HasDerivAt g (1 / deriv f (g w)) w) := by
  have hd : DifferentiableAt ℂ f a := hf.self_of_nhds
  have hfd : ∀ u : ℂ, fderiv ℝ f a u = deriv f a * u := by
    intro u
    rw [hd.fderiv_restrictScalars ℝ]
    show fderiv ℂ f a u = deriv f a * u
    have : u = u • (1 : ℂ) := by simp
    rw [this, (fderiv ℂ f a).map_smul, fderiv_apply_one_eq_deriv, smul_eq_mul, mul_comm]
    simp
  have han : AnalyticAt ℂ f a := analyticAt_iff_eventually_differentiableAt.2 hf
  refine ⟨?_, hfd, ?_, hd.conformalAt ha, ?_⟩
  · have := hasDerivAt_iff_isLittleO_nhds_zero.1 hd.hasDerivAt
    simpa [smul_eq_mul, mul_comm] using this
  · intro u v hu hv
    rw [hfd, hfd, mul_div_mul_left _ _ ha]
  · have hs := (han.hasStrictDerivAt).hasStrictFDerivAt_equiv ha
    set e := hs.toOpenPartialHomeomorph f with he
    have hecoe : (e : ℂ → ℂ) = f := hs.toOpenPartialHomeomorph_coe
    have hsrc : a ∈ e.source := hs.mem_toOpenPartialHomeomorph_source
    have htgt : f a ∈ e.target := hs.image_mem_toOpenPartialHomeomorph_target
    have hga : e.symm (f a) = a := by
      have := e.left_inv hsrc
      rwa [hecoe] at this
    refine ⟨e.symm, ?_, ?_, ?_⟩
    · filter_upwards [e.open_source.mem_nhds hsrc] with z hz
      have := e.left_inv hz
      rwa [hecoe] at this
    · filter_upwards [e.open_target.mem_nhds htgt] with w hw
      have := e.right_inv hw
      rwa [hecoe] at this
    · have hderiv : ∀ᶠ z in 𝓝 a, deriv f z ≠ 0 :=
        han.deriv.continuousAt.eventually_ne ha
      have hS : ∀ᶠ z in 𝓝 a, DifferentiableAt ℂ f z ∧ deriv f z ≠ 0 := hf.and hderiv
      have hcont : Tendsto e.symm (𝓝 (f a)) (𝓝 a) := by
        have := e.continuousAt_symm htgt
        rwa [ContinuousAt, hga] at this
      filter_upwards [hcont.eventually hS, e.open_target.mem_nhds htgt] with w ⟨hw1, hw2⟩ hw
      have := HasDerivAt.of_local_left_inverse (e.continuousAt_symm hw) hw1.hasDerivAt hw2 ?_
      · simpa using this
      · filter_upwards [e.open_target.mem_nhds hw] with y hy
        have := e.right_inv hy
        rwa [hecoe] at this

/-- Local, not global: z^2 has a nonzero derivative 2z at every point other than 0, yet it is
not one-to-one there (1 + i and -1 - i both go to 2i). So a nonzero derivative does not make a
holomorphic function univalent. -/
theorem nonzero_derivative_not_univalent :
    (∀ z : ℂ, z ≠ 0 → HasDerivAt (fun w : ℂ => w ^ 2) (2 * z) z ∧ 2 * z ≠ 0) ∧
    ¬ Set.InjOn (fun w : ℂ => w ^ 2) {0}ᶜ := by
  refine ⟨fun z hz => ⟨?_, mul_ne_zero two_ne_zero hz⟩, ?_⟩
  · simpa using hasDerivAt_pow 2 z
  · intro h
    have h1 : (1 + I : ℂ) ≠ 0 := by
      intro h0; simpa using congrArg Complex.re h0
    have h2 : (-1 - I : ℂ) ≠ 0 := by
      intro h0; simpa using congrArg Complex.re h0
    have heq := h (Set.mem_compl_singleton_iff.2 h1) (Set.mem_compl_singleton_iff.2 h2)
      (by simp only; ring)
    have := congrArg Complex.re heq
    norm_num at this

/-- Mercator's chart is -i Log of the stereographic globe. A point at latitude φ strictly
between -π/2 and π/2 and longitude λ in (-π, π] projects to z = r e^(iλ) with
r = tan(π/4 - φ/2). Then r > 0, -i Log z = λ + i ln tan(π/4 + φ/2), and the chart's stretch
(1 + r^2)/(2r) equals 1/cos φ. -/
theorem mercator_is_log_of_stereographic (φ l : ℝ)
    (hφ₁ : -(Real.pi / 2) < φ) (hφ₂ : φ < Real.pi / 2)
    (hl₁ : -Real.pi < l) (hl₂ : l ≤ Real.pi) :
    0 < Real.tan (Real.pi / 4 - φ / 2) ∧
    -I * Complex.log ((Real.tan (Real.pi / 4 - φ / 2) : ℂ) * Complex.exp (l * I)) =
      l + I * Real.log (Real.tan (Real.pi / 4 + φ / 2)) ∧
    (1 + Real.tan (Real.pi / 4 - φ / 2) ^ 2) / (2 * Real.tan (Real.pi / 4 - φ / 2)) =
      1 / Real.cos φ := by
  set t := Real.pi / 4 - φ / 2 with ht
  have ht0 : 0 < t := by rw [ht]; linarith
  have ht1 : t < Real.pi / 2 := by rw [ht]; linarith
  have hpos : 0 < Real.tan t := Real.tan_pos_of_pos_of_lt_pi_div_two ht0 ht1
  have hc : 0 < Real.cos t := Real.cos_pos_of_mem_Ioo ⟨by linarith, ht1⟩
  have hs : 0 < Real.sin t := Real.sin_pos_of_pos_of_lt_pi ht0 (by linarith)
  refine ⟨hpos, ?_, ?_⟩
  · have hinv : Real.tan (Real.pi / 4 + φ / 2) = (Real.tan t)⁻¹ := by
      rw [← Real.tan_pi_div_two_sub]; congr 1; rw [ht]; ring
    rw [hinv, Real.log_inv]
    have hr : ((Real.tan t : ℝ) : ℂ) = Complex.exp (Real.log (Real.tan t)) := by
      rw [← Complex.ofReal_exp, Real.exp_log hpos]
    rw [hr, ← Complex.exp_add, Complex.log_exp]
    · push_cast
      ring_nf
      rw [I_sq]
      ring
    · simp [Complex.add_im, Complex.ofReal_im]
      linarith
    · simp [Complex.add_im, Complex.ofReal_im]
      linarith
  · have hcos : Real.cos φ = 2 * Real.sin t * Real.cos t := by
      rw [← Real.sin_two_mul, ← Real.cos_pi_div_two_sub]; congr 1; rw [ht]; ring
    rw [hcos, Real.tan_eq_sin_div_cos]
    have h1 := Real.sin_sq_add_cos_sq t
    field_simp
    nlinarith [h1]

-- f(z) = z^2 at 1 + i: f'(1 + i) = 2(1 + i) = 2 + 2i, and |f'|^2 = 2^2 + 2^2 = 8.
example : (2 : ℂ) * (1 + I) = 2 + 2 * I := by ring
example : Complex.normSq (2 + 2 * I) = 8 := by
  simp [Complex.normSq_apply]; norm_num
-- Arrows 1 (east) and 1 + i (north-east), times 2 + 2i, land on 2 + 2i and 4i: 45 and 90 degrees.
example : (2 + 2 * I) * 1 = 2 + 2 * I ∧ (2 + 2 * I) * (1 + I) = 4 * I := by
  constructor
  · ring
  · ring_nf; rw [I_sq]; ring
-- The quotient of the image arrows equals the quotient of the arrows: the multiplier cancels.
example : (2 + 2 * I) * (1 + I) / ((2 + 2 * I) * 1) = (1 + I) / 1 := by
  rw [mul_div_mul_left]; intro h; simpa using congrArg Complex.re h
-- Not one-to-one: (1 + i)^2 = (-1 - i)^2 = 2i.
example : (1 + I) ^ 2 = 2 * I ∧ (-1 - I) ^ 2 = 2 * I := by
  constructor <;> (ring_nf; rw [I_sq]; ring)
-- The local inverse's slope at 2i: 1/f'(1 + i) = 1/(2 + 2i) = 1/4 - (1/4) i.
example : 1 / (2 + 2 * I) = 1 / 4 - (1 / 4) * I := by
  rw [Complex.ext_iff]; simp [Complex.inv_re, Complex.inv_im, Complex.normSq]; norm_num
-- z-bar sends the north-east arrow 1 + i to 1 - i: 45 degrees becomes -45.
example : (starRingEnd ℂ) (1 + I) = 1 - I := by simp [sub_eq_add_neg]

#print axioms holomorphic_nonzero_derivative_conformal
#print axioms nonzero_derivative_not_univalent
#print axioms mercator_is_log_of_stereographic
