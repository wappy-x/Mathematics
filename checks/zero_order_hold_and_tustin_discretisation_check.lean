-- Discretising a design: the zero-order-hold model is exact at the samples, Tustin's map sends the stable half-plane onto the unit disc, and on the unit circle Tustin's s is j times the bent frequency (2/T) tan(ωT/2).
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.Calculus.Deriv.Mul

open scoped Matrix

set_option backward.isDefEq.respectTransparency false in
open scoped Matrix.Norms.Operator in
theorem zoh_helper {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (B : n → ℝ) (u T : ℝ) (hT : 0 ≤ T) (x : ℝ → n → ℝ)
    (hx : ∀ t ∈ Set.Icc 0 T, HasDerivWithinAt x (A *ᵥ x t + u • B) (Set.Icc 0 T) t) :
    x T = NormedSpace.exp (T • A) *ᵥ x 0
      + ∫ σ in (0 : ℝ)..T, NormedSpace.exp (σ • A) *ᵥ (u • B) := by
  let L : Matrix n n ℝ →L[ℝ] (n → ℝ) →L[ℝ] (n → ℝ) :=
    LinearMap.toContinuousLinearMap
      ((LinearMap.toContinuousLinearMap : ((n → ℝ) →ₗ[ℝ] (n → ℝ)) ≃ₗ[ℝ] _).toLinearMap ∘ₗ
        (Matrix.toLin' : Matrix n n ℝ ≃ₗ[ℝ] _).toLinearMap)
  have hL : ∀ M v, L M v = M *ᵥ v := fun M v => by simp [L]
  set E : ℝ → Matrix n n ℝ := fun t => NormedSpace.exp ((T - t) • A) with hE
  have hEd : ∀ t, HasDerivAt E ((-1 : ℝ) • (NormedSpace.exp ((T - t) • A) * A)) t := fun t =>
    (hasDerivAt_exp_smul_const A (T - t)).scomp t ((hasDerivAt_id t).const_sub T)
  set g : ℝ → n → ℝ := fun t => L (E t) (x t) with hg
  have hgd : ∀ t ∈ Set.Icc 0 T,
      HasDerivWithinAt g (E t *ᵥ (u • B)) (Set.Icc 0 T) t := by
    intro t ht
    have := L.hasDerivWithinAt_of_bilinear (hEd t).hasDerivWithinAt (hx t ht)
    convert this using 1
    rw [hL, hL]
    simp only [E, Matrix.mulVec_add, Matrix.mulVec_mulVec, neg_smul, one_smul, Matrix.neg_mulVec]
    abel
  have hcontE : Continuous fun t => E t *ᵥ (u • B) := by
    have : Continuous E := continuous_iff_continuousAt.2 fun t => (hEd t).continuousAt
    exact this.matrix_mulVec continuous_const
  have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT
    (fun t ht => (hgd t ht).continuousWithinAt)
    (fun t ht => (hgd t (Set.Ioo_subset_Icc_self ht)).hasDerivAt (Icc_mem_nhds ht.1 ht.2))
    (hcontE.intervalIntegrable _ _)
  have hsub : (∫ t in (0:ℝ)..T, E t *ᵥ (u • B))
      = ∫ σ in (0 : ℝ)..T, NormedSpace.exp (σ • A) *ᵥ (u • B) := by
    simp only [E]
    rw [intervalIntegral.integral_comp_sub_left (fun σ => NormedSpace.exp (σ • A) *ᵥ (u • B)) T]
    simp
  rw [← hsub, hftc]
  simp [g, hL, E]

#print axioms zoh_helper

/-- Zero-order hold is exact at the samples: if the state obeys dx/dt = A x + B u over one tick
of length T, with the input u held flat for the whole tick, then the state one tick later is
e^(AT) x(0) plus the integral over the tick of e^(Aσ) B u, i.e. x[k+1] = A_d x[k] + B_d u[k]. -/
theorem zoh_exact_at_samples {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) (B : n → ℝ) (u T : ℝ) (hT : 0 ≤ T) (x : ℝ → n → ℝ)
    (hx : ∀ t ∈ Set.Icc 0 T, HasDerivWithinAt x (A *ᵥ x t + u • B) (Set.Icc 0 T) t) :
    x T = NormedSpace.exp (T • A) *ᵥ x 0
      + ∫ σ in (0 : ℝ)..T, NormedSpace.exp (σ • A) *ᵥ (u • B) := by
  exact zoh_helper A B u T hT x hx

/-- Tustin keeps stable designs stable: with sampling interval T > 0, the point
z = (1 + sT/2)/(1 − sT/2) that Tustin assigns to s lies strictly inside the unit circle exactly
when s lies in the open left half-plane, and every point inside the unit circle comes from such
an s. -/
theorem tustin_left_half_plane_onto_unit_disc (T : ℝ) (hT : 0 < T) :
    (∀ s : ℂ, 1 - s * T / 2 ≠ 0 →
      (‖(1 + s * T / 2) / (1 - s * T / 2)‖ < 1 ↔ s.re < 0)) ∧
    (∀ z : ℂ, ‖z‖ < 1 →
      ∃ s : ℂ, s.re < 0 ∧ 1 - s * T / 2 ≠ 0 ∧ (1 + s * T / 2) / (1 - s * T / 2) = z) := by
  have key : ∀ s : ℂ, 1 - s * T / 2 ≠ 0 →
      (‖(1 + s * T / 2) / (1 - s * T / 2)‖ < 1 ↔ s.re < 0) := by
    intro s hs
    have hpos : 0 < ‖1 - s * T / 2‖ := norm_pos_iff.2 hs
    rw [norm_div, div_lt_one hpos]
    rw [← sq_lt_sq₀ (norm_nonneg _) (norm_nonneg _), Complex.sq_norm, Complex.sq_norm,
      Complex.normSq_apply, Complex.normSq_apply]
    simp only [Complex.add_re, Complex.sub_re, Complex.one_re, Complex.div_re, Complex.mul_re,
      Complex.ofReal_re, Complex.ofReal_im, Complex.add_im, Complex.sub_im, Complex.one_im,
      Complex.div_im, Complex.mul_im]
    norm_num
    constructor
    · intro h; nlinarith
    · intro h; nlinarith
  refine ⟨key, fun z hz => ?_⟩
  have hz1 : z + 1 ≠ 0 := by
    intro h
    have : z = -1 := by linear_combination h
    rw [this] at hz; simp at hz
  have hTc : (T : ℂ) ≠ 0 := by exact_mod_cast hT.ne'
  set s : ℂ := 2 / T * ((z - 1) / (z + 1)) with hsdef
  have h1 : 1 - s * T / 2 = 2 / (z + 1) := by
    rw [hsdef]; field_simp; ring
  have h2 : 1 + s * T / 2 = 2 * z / (z + 1) := by
    rw [hsdef]; field_simp; ring
  have hne : 1 - s * T / 2 ≠ 0 := by rw [h1]; exact div_ne_zero two_ne_zero hz1
  have heq : (1 + s * T / 2) / (1 - s * T / 2) = z := by
    rw [h1, h2]; field_simp
  refine ⟨s, ?_, hne, heq⟩
  rw [← key s hne, heq]; exact hz

/-- Tustin bends the frequency axis: on the unit circle z = e^(jωT), Tustin's substitute for s,
(2/T)(z − 1)/(z + 1), equals j ω_a with ω_a = (2/T) tan(ωT/2). -/
theorem tustin_frequency_warping (T ω : ℝ) :
    (2 / T : ℂ) * ((Complex.exp (ω * T * Complex.I) - 1) / (Complex.exp (ω * T * Complex.I) + 1))
      = Complex.I * ((2 / T * Real.tan (ω * T / 2) : ℝ) : ℂ) := by
  set φ : ℂ := (ω : ℂ) * T / 2 with hφ
  have hx : (ω : ℂ) * T * Complex.I = 2 * φ * Complex.I := by rw [hφ]; ring
  have htan : Complex.tan ((ω : ℂ) * T / 2) = Complex.sin φ / Complex.cos φ := by
    rw [Complex.tan, hφ]
  push_cast
  rw [htan, hx, Complex.exp_mul_I, Complex.cos_two_mul, Complex.sin_two_mul]
  have hsc : Complex.sin φ ^ 2 + Complex.cos φ ^ 2 = 1 := Complex.sin_sq_add_cos_sq φ
  by_cases hc : Complex.cos φ = 0
  · rw [hc]; simp
  · have hu : Complex.cos φ + Complex.sin φ * Complex.I ≠ 0 := by
      rw [← Complex.exp_mul_I]; exact Complex.exp_ne_zero _
    have hd : 2 * Complex.cos φ ^ 2 - 1 + 2 * Complex.sin φ * Complex.cos φ * Complex.I + 1
        = 2 * Complex.cos φ * (Complex.cos φ + Complex.sin φ * Complex.I) := by ring
    have hn : 2 * Complex.cos φ ^ 2 - 1 + 2 * Complex.sin φ * Complex.cos φ * Complex.I - 1
        = 2 * Complex.sin φ * Complex.I * (Complex.cos φ + Complex.sin φ * Complex.I) := by
      linear_combination 2 * hsc - 2 * Complex.sin φ ^ 2 * Complex.I_sq
    rw [hd, hn]
    field_simp

-- The cup's transfer function: R/((τ₁ s + 1)(τ₂ s + 1)) with R = 1/2, τ₁ = 1, τ₂ = 1/4 is 2/(s² + 5s + 4).
example (s : ℚ) : (1 / 2) / ((1 * s + 1) * ((1 / 4) * s + 1)) = 2 / (s ^ 2 + 5 * s + 4) := by
  rw [show (1 * s + 1) * ((1 / 4) * s + 1) = (s ^ 2 + 5 * s + 4) / 4 by ring, div_div_eq_mul_div]
  ring

-- Tustin with c = 2/T = 20: the denominator coefficients 504, −792, 304 and the numerator 2, 4, 2.
example : (20 : ℤ) ^ 2 + 5 * 20 + 4 = 504 ∧ 2 * 4 - 2 * 20 ^ 2 = -792 ∧ (20 : ℤ) ^ 2 - 5 * 20 + 4 = 304 := by
  norm_num
example (z : ℚ) :
    (20 * (z - 1)) ^ 2 + 5 * (20 * (z - 1)) * (z + 1) + 4 * (z + 1) ^ 2 = 504 * z ^ 2 - 792 * z + 304 := by
  ring

-- Tustin's step response to 10 W: 20/504 = 5/126 K at 0 s, then (792 · 5/126 + 60)/504 = 80/441 K at 0.1 s.
example : (2 * 10 : ℚ) / 504 = 5 / 126 := by norm_num
example : ((792 * (5 / 126) + 2 * 10 + 4 * 10) / 504 : ℚ) = 80 / 441 := by norm_num

-- Tustin's poles at T = 1/10: s = −1 goes to 19/21 and s = −4 goes to 2/3.
example : ((1 + (-1) * (1 / 10) / 2) / (1 - (-1) * (1 / 10) / 2) : ℚ) = 19 / 21 := by norm_num
example : ((1 + (-4) * (1 / 10) / 2) / (1 - (-4) * (1 / 10) / 2) : ℚ) = 2 / 3 := by norm_num

-- Forward Euler at T = 3/5: the sensor pole 1 − 4T = −7/5 lies outside the unit circle; Euler needs T < 2τ₂ = 1/2.
example : (1 - 4 * (3 / 5) : ℚ) = -7 / 5 ∧ 1 < |(-7 / 5 : ℚ)| ∧ (2 * (1 / 4) : ℚ) < 3 / 5 := by
  norm_num [abs_of_neg]

-- Holding the cup 2 K below room needs u = −2/R = −4 W; a 10 W step settles at 10 · R = 5 K.
example : (-2 : ℚ) / (1 / 2) = -4 ∧ (10 : ℚ) * (1 / 2) = 5 := by norm_num

#print axioms zoh_exact_at_samples
#print axioms tustin_left_half_plane_onto_unit_disc
#print axioms tustin_frequency_warping
