-- Bochner spaces and the weak heat equation: every Galerkin path of the heat equation obeys the energy identity and the decay bound E(t) ≤ E(0) e^(−2π²κt/L²), weak heat paths with the same start are equal, and the hot spot's sine coefficients have the card's closed form.
import Mathlib.Analysis.InnerProductSpace.Projection.FiniteDimensional
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.BilinearForm.Basic

open Real

/-- The energy estimate of Step 5, the same for every number of modes.
`E` is the space of profiles with the inner product `(f, g)`, `V` the finite-dimensional
Galerkin space of the chosen modes, and `a v w` the slope form `(v_x, w_x)`.
The ends are held at 0 °C, which gives the Poincaré inequality `(π/L)² ‖v‖² ≤ (v_x, v_x)`
on `V`; time runs forward with `κ > 0`; the start `u₀` only needs a finite norm.
If the Galerkin path `u_N` stays in `V`, has time derivative `u_N'`, obeys
`(u_N', v) + κ (∂ₓu_N, v_x) = 0` for every `v` in `V`, and starts at the projection of `u₀`,
then for every `t ≥ 0` the energy identity
`½‖u_N(t)‖² + κ ∫₀ᵗ ‖∂ₓu_N‖² ds = ½‖u_N(0)‖² ≤ ½‖u₀‖²` holds, and the energy obeys the
decay bound `½‖u_N(t)‖² ≤ ½‖u₀‖² e^(−2π²κt/L²)`. -/
theorem galerkin_energy_identity_and_decay_bound
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (V : Submodule ℝ E) [FiniteDimensional ℝ V]
    (a : LinearMap.BilinForm ℝ E) (κ L : ℝ) (hκ : 0 < κ) (hL : 0 < L)
    (hpoincare : ∀ v ∈ V, (π / L) ^ 2 * ‖v‖ ^ 2 ≤ a v v)
    (u₀ : E) (u u' : ℝ → E)
    (hV : ∀ t, u t ∈ V)
    (hderiv : ∀ t, HasDerivAt u (u' t) t)
    (hgalerkin : ∀ t, ∀ v ∈ V, inner ℝ (u' t) v + κ * a (u t) v = 0)
    (hstart : u 0 = V.starProjection u₀) :
    ∀ t, 0 ≤ t →
      (1 / 2) * ‖u t‖ ^ 2 + κ * ∫ s in (0 : ℝ)..t, a (u s) (u s) = (1 / 2) * ‖u 0‖ ^ 2 ∧
      (1 / 2) * ‖u 0‖ ^ 2 ≤ (1 / 2) * ‖u₀‖ ^ 2 ∧
      (1 / 2) * ‖u t‖ ^ 2 ≤ (1 / 2) * ‖u₀‖ ^ 2 * Real.exp (-2 * π ^ 2 * κ * t / L ^ 2) := by
  have hnn : ∀ s, 0 ≤ a (u s) (u s) := fun s =>
    le_trans (by positivity) (hpoincare (u s) (hV s))
  have hN : ∀ t, HasDerivAt (fun s => ‖u s‖ ^ 2) (-(2 * κ) * a (u t) (u t)) t := by
    intro t
    have h1 := (hderiv t).norm_sq
    have h2 := hgalerkin t (u t) (hV t)
    have h3 := real_inner_comm (u t) (u' t)
    convert h1 using 1
    linarith
  have hu0 : ‖u 0‖ ^ 2 ≤ ‖u₀‖ ^ 2 := by
    rw [hstart]
    exact pow_le_pow_left₀ (norm_nonneg _) (V.norm_starProjection_apply_le u₀) 2
  intro t ht
  refine ⟨?_, by linarith, ?_⟩
  · have hg : ∀ s, HasDerivAt (fun s => -(1 / 2) * ‖u s‖ ^ 2) (κ * a (u s) (u s)) s := by
      intro s
      convert (hN s).const_mul (-(1 / 2) : ℝ) using 1
      ring
    have hint : IntervalIntegrable (fun s => κ * a (u s) (u s)) MeasureTheory.volume 0 t :=
      intervalIntegral.intervalIntegrable_deriv_of_nonneg
        (fun s _ => (hg s).continuousAt.continuousWithinAt)
        (fun s _ => hg s) (fun s _ => mul_nonneg hκ.le (hnn s))
    have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (fun s _ => hg s) hint
    rw [intervalIntegral.integral_const_mul] at hftc
    linarith
  · set c : ℝ := (π / L) ^ 2 with hc
    have hh : ∀ s, HasDerivAt (fun s => Real.exp (2 * κ * c * s) * ‖u s‖ ^ 2)
        (2 * κ * Real.exp (2 * κ * c * s) * (c * ‖u s‖ ^ 2 - a (u s) (u s))) s := by
      intro s
      have he : HasDerivAt (fun s => Real.exp (2 * κ * c * s)) (Real.exp (2 * κ * c * s) * (2 * κ * c)) s := by
        have := ((hasDerivAt_id s).const_mul (2 * κ * c)).exp
        simpa using this
      convert he.mul (hN s) using 1
      ring
    have hanti : Antitone (fun s => Real.exp (2 * κ * c * s) * ‖u s‖ ^ 2) := by
      apply antitone_of_hasDerivAt_nonpos hh
      intro s
      have hp := hpoincare (u s) (hV s)
      have : c * ‖u s‖ ^ 2 - a (u s) (u s) ≤ 0 := by rw [hc]; linarith
      exact mul_nonpos_of_nonneg_of_nonpos (by positivity) this
    have hle := hanti ht
    simp only [mul_zero, Real.exp_zero, one_mul] at hle
    have hx : -2 * π ^ 2 * κ * t / L ^ 2 = -(2 * κ * c * t) := by
      rw [hc, div_pow]; field_simp
    rw [hx]
    have hE : ‖u t‖ ^ 2 = Real.exp (-(2 * κ * c * t)) * (Real.exp (2 * κ * c * t) * ‖u t‖ ^ 2) := by
      rw [← mul_assoc, ← Real.exp_add]; simp
    have hpos : 0 < Real.exp (-(2 * κ * c * t)) := Real.exp_pos _
    have : ‖u t‖ ^ 2 ≤ ‖u₀‖ ^ 2 * Real.exp (-(2 * κ * c * t)) := by
      rw [hE, mul_comm (‖u₀‖ ^ 2)]
      exact mul_le_mul_of_nonneg_left (hle.trans hu0) hpos.le
    linarith

/-- Uniqueness, Step 7: two paths `u` and `ũ` that solve the same weak heat equation
`(u', v) + κ (u_x, v_x) = 0` for every test profile `v` in `V`, with `κ > 0` and slope energy
`(v_x, v_x) ≥ 0`, and that have the same start, are equal at every later time. -/
theorem weak_heat_solution_unique
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (V : Submodule ℝ E) (a : LinearMap.BilinForm ℝ E) (κ : ℝ) (hκ : 0 < κ)
    (hnonneg : ∀ v ∈ V, 0 ≤ a v v)
    (u u' w w' : ℝ → E)
    (huV : ∀ t, u t ∈ V) (hwV : ∀ t, w t ∈ V)
    (hu : ∀ t, HasDerivAt u (u' t) t) (hw : ∀ t, HasDerivAt w (w' t) t)
    (hequ : ∀ t, ∀ v ∈ V, inner ℝ (u' t) v + κ * a (u t) v = 0)
    (heqw : ∀ t, ∀ v ∈ V, inner ℝ (w' t) v + κ * a (w t) v = 0)
    (h0 : u 0 = w 0) :
    ∀ t, 0 ≤ t → u t = w t := by
  have hd : ∀ t, HasDerivAt (fun s => u s - w s) (u' t - w' t) t := fun t => (hu t).sub (hw t)
  have hdV : ∀ t, u t - w t ∈ V := fun t => V.sub_mem (huV t) (hwV t)
  have heq : ∀ t, ∀ v ∈ V, inner ℝ (u' t - w' t) v + κ * a (u t - w t) v = 0 := by
    intro t v hv
    rw [inner_sub_left, map_sub, LinearMap.sub_apply]
    have h1 := hequ t v hv
    have h2 := heqw t v hv
    linarith
  have hN : ∀ t, HasDerivAt (fun s => ‖u s - w s‖ ^ 2)
      (-(2 * κ) * a (u t - w t) (u t - w t)) t := by
    intro t
    have h1 := (hd t).norm_sq
    have h2 := heq t (u t - w t) (hdV t)
    have h3 := real_inner_comm (u t - w t) (u' t - w' t)
    convert h1 using 1
    linarith
  have hanti : Antitone (fun s => ‖u s - w s‖ ^ 2) := by
    apply antitone_of_hasDerivAt_nonpos hN
    intro s
    have := hnonneg _ (hdV s)
    show -(2 * κ) * a (u s - w s) (u s - w s) ≤ 0
    nlinarith
  intro t ht
  have hle := hanti ht
  simp only [h0, sub_self, norm_zero] at hle
  have : ‖u t - w t‖ = 0 := by
    have := sq_nonneg ‖u t - w t‖
    nlinarith [norm_nonneg (u t - w t)]
  exact sub_eq_zero.mp (norm_eq_zero.mp this)

/-- The hot spot's sine coefficients on the 1 m rod: for every mode `k ≥ 1`,
`b_k = (2/L) ∫_{0.4}^{0.6} 100 sin(kπx) dx = (400/(kπ)) sin(kπ/2) sin(kπ/10)` with `L = 1`. -/
theorem hot_spot_sine_coefficient (k : ℕ) (hk : 1 ≤ k) :
    (2 / 1 : ℝ) * ∫ x in (2 / 5 : ℝ)..(3 / 5), 100 * Real.sin (k * π * x)
      = 400 / (k * π) * Real.sin (k * π / 2) * Real.sin (k * π / 10) := by
  have hk0 : (k : ℝ) ≠ 0 := by
    have : (1 : ℝ) ≤ k := by exact_mod_cast hk
    linarith
  have hkπ : (k : ℝ) * π ≠ 0 := mul_ne_zero hk0 Real.pi_ne_zero
  rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_comp_mul_left Real.sin hkπ,
    integral_sin, smul_eq_mul]
  have e1 : (k : ℝ) * π * (2 / 5) = k * π / 2 - k * π / 10 := by ring
  have e2 : (k : ℝ) * π * (3 / 5) = k * π / 2 + k * π / 10 := by ring
  rw [e1, e2, Real.cos_sub, Real.cos_add]
  field_simp
  ring

-- The start energy: ½ × 100² × 0.2 = 1000 °C² m.
example : (1 / 2 : ℚ) * 100 ^ 2 * (1 / 5) = 1000 := by norm_num

-- Insulated ends keep the mean: 100 °C × 0.2 m over a 1 m rod is 20 °C.
example : (100 : ℚ) * (1 / 5) / 1 = 20 := by norm_num

-- ... and its energy ½ × 20² × 1 = 200 °C² m never decays.
example : (1 / 2 : ℚ) * 20 ^ 2 * 1 = 200 := by norm_num

#print axioms galerkin_energy_identity_and_decay_bound
#print axioms weak_heat_solution_unique
#print axioms hot_spot_sine_coefficient
