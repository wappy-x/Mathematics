-- Einstein equations: in empty space the Einstein equations reduce to Ric = 0, the Schwarzschild metric's Ricci components are all zero, and the first-order light-ray correction behind the bending 2 r_s / r_0 solves its equation.
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Matrix Real

/-- At one point of a four-dimensional spacetime, with metric components `g` (an invertible
matrix), Ricci components `Ric`, scalar curvature `S = g^{μν} Ric_{μν} = trace (g⁻¹ Ric)` and
energy-momentum components `T`: outside matter (`T = 0`), Einstein's equations
`Ric - (1/2) S g = κ T` hold exactly when `Ric = 0`. Here `κ` stands for `8πG/c⁴`. -/
theorem vacuum_einstein_iff_ricci_flat (g Ric T : Matrix (Fin 4) (Fin 4) ℝ) (κ : ℝ)
    (hg : IsUnit g.det) (hT : T = 0) :
    Ric - ((1 / 2 : ℝ) * trace (g⁻¹ * Ric)) • g = κ • T ↔ Ric = 0 := by
  subst hT
  rw [smul_zero]
  constructor
  · intro h
    set c : ℝ := (1 / 2 : ℝ) * trace (g⁻¹ * Ric) with hc
    have hR : Ric = c • g := sub_eq_zero.mp h
    have hgg : g⁻¹ * g = 1 := Matrix.nonsing_inv_mul g hg
    have htr : trace (g⁻¹ * Ric) = c * 4 := by
      rw [hR, Matrix.mul_smul, hgg, Matrix.trace_smul]
      simp [Matrix.trace]
    have hc0 : c = 0 := by
      have : c = (1 / 2 : ℝ) * (c * 4) := by rw [← htr]
      linarith
    rw [hR, hc0, zero_smul]
  · intro h
    subst h
    simp

/-- The clock exponent `a` of the Schwarzschild metric, `A = e^{2a} = 1 - r_s / r`. -/
noncomputable def schwarzschildA (rs : ℝ) (x : ℝ) : ℝ := (1 / 2) * Real.log (1 - rs / x)

/-- The radial exponent `b = -a` of the Schwarzschild metric, `B = e^{2b} = 1 / A`. -/
noncomputable def schwarzschildB (rs : ℝ) (x : ℝ) : ℝ := -schwarzschildA rs x

/-- The Schwarzschild metric solves Einstein's equations in empty space: for the round, still
metric with `A = e^{2a} = 1 - r_s / r` and `B = e^{2b} = 1 / A`, the card's three Ricci components
`Ric_tt = e^{2(a-b)} (a'' + a'^2 - a'b' + 2a'/r)`, `Ric_rr = -a'' - a'^2 + a'b' + 2b'/r` and
`Ric_φφ = e^{-2b} (r (b' - a') - 1) + 1` are all zero at every radius `r > 0` where `1 - r_s/r > 0`
(`Ric_θθ = sin²φ Ric_φφ` then vanishes too). -/
theorem schwarzschild_ricci_components_vanish (rs r : ℝ) (hr : 0 < r) (hrs : rs < r) :
    (let a := schwarzschildA rs
     let b := schwarzschildB rs
     Real.exp (2 * (a r - b r)) *
        (deriv (deriv a) r + deriv a r ^ 2 - deriv a r * deriv b r + 2 * deriv a r / r) = 0 ∧
      -deriv (deriv a) r - deriv a r ^ 2 + deriv a r * deriv b r + 2 * deriv b r / r = 0 ∧
      Real.exp (-2 * b r) * (r * (deriv b r - deriv a r) - 1) + 1 = 0) := by
  intro a b
  have hr' : 0 < r - rs := by linarith
  have hU : ∀ x : ℝ, max 0 rs < x →
      HasDerivAt (schwarzschildA rs) ((1 / 2) * (1 / (x - rs) - 1 / x)) x := by
    intro x hx
    have hx0 : 0 < x := lt_of_le_of_lt (le_max_left _ _) hx
    have hxr : rs < x := lt_of_le_of_lt (le_max_right _ _) hx
    have hpos : 0 < 1 - rs / x := by
      rw [sub_pos, div_lt_one hx0]; exact hxr
    have h1 : HasDerivAt (fun y : ℝ => 1 - rs / y) (rs / x ^ 2) x := by
      have := ((hasDerivAt_inv hx0.ne').const_mul rs).const_sub 1
      convert this using 1
      · funext y; simp [div_eq_mul_inv]
      · field_simp
    have h2 := (h1.log hpos.ne').const_mul (1 / 2 : ℝ)
    have hxr' : x - rs ≠ 0 := by linarith
    have hx0' : x ≠ 0 := hx0.ne'
    have hsub : 1 - rs / x = (x - rs) / x := by field_simp
    refine h2.congr_deriv ?_
    rw [hsub]
    field_simp
    ring
  have hrU : max 0 rs < r := max_lt hr hrs
  have hda : ∀ x : ℝ, max 0 rs < x →
      deriv a x = (1 / 2) * (1 / (x - rs) - 1 / x) := fun x hx => (hU x hx).deriv
  have hdb : ∀ x : ℝ, max 0 rs < x →
      deriv b x = -((1 / 2) * (1 / (x - rs) - 1 / x)) := by
    intro x hx
    have : b = fun y => -schwarzschildA rs y := rfl
    rw [this]
    exact (hU x hx).neg.deriv
  have hev : deriv a =ᶠ[nhds r] fun x => (1 / 2) * (1 / (x - rs) - 1 / x) := by
    filter_upwards [isOpen_Ioi.mem_nhds (show r ∈ Set.Ioi (max 0 rs) from hrU)] with x hx
    exact hda x hx
  have hg : HasDerivAt (fun x : ℝ => (1 / 2) * (1 / (x - rs) - 1 / x))
      ((1 / 2) * (-(1 / (r - rs) ^ 2) + 1 / r ^ 2)) r := by
    have e1 : HasDerivAt (fun x : ℝ => x - rs) 1 r := (hasDerivAt_id r).sub_const rs
    have e2 := e1.inv hr'.ne'
    have e3 := hasDerivAt_inv hr.ne'
    have e4 := (e2.sub e3).const_mul (1 / 2 : ℝ)
    convert e4 using 1
    · funext x; simp [one_div]
    · field_simp
      ring
  have hdda : deriv (deriv a) r = (1 / 2) * (-(1 / (r - rs) ^ 2) + 1 / r ^ 2) := by
    rw [hev.deriv_eq]; exact hg.deriv
  rw [hdda, hda r hrU, hdb r hrU]
  have hr0 : r ≠ 0 := hr.ne'
  have hrr : r - rs ≠ 0 := hr'.ne'
  refine ⟨?_, ?_, ?_⟩
  · apply mul_eq_zero_of_right
    field_simp
    ring
  · field_simp
    ring
  · have hpos : 0 < 1 - rs / r := by
      rw [sub_pos, div_lt_one hr]; exact hrs
    have hb : -2 * b r = Real.log (1 - rs / r) := by
      show -2 * -((1 / 2) * Real.log (1 - rs / r)) = _
      ring
    rw [hb, Real.exp_log hpos]
    field_simp
    ring

/-- The first-order correction to a light ray, `w = cos θ + ε w₁` with `w₁ = 3/4 - (1/4) cos 2θ - (1/2) cos θ`,
solves `w₁'' + w₁ = (3/4)(1 + cos 2θ)` with `w₁(0) = w₁'(0) = 0`, and `w₁(π/2) = 1`; this is why each
half of the ray sweeps `π/2 + ε` and the bending is `2ε = 2 r_s / r_0`. -/
theorem light_ray_first_order_correction :
    (let w₁ : ℝ → ℝ := fun θ => 3 / 4 - (1 / 4) * Real.cos (2 * θ) - (1 / 2) * Real.cos θ
     (∀ θ : ℝ, deriv (deriv w₁) θ + w₁ θ = (3 / 4) * (1 + Real.cos (2 * θ))) ∧
      w₁ 0 = 0 ∧ deriv w₁ 0 = 0 ∧ w₁ (π / 2) = 1) := by
  intro w₁
  have hd1 : ∀ θ : ℝ, HasDerivAt w₁ ((1 / 2) * Real.sin (2 * θ) + (1 / 2) * Real.sin θ) θ := by
    intro θ
    have c2 : HasDerivAt (fun t : ℝ => Real.cos (2 * t)) (-Real.sin (2 * θ) * 2) θ := by
      have := ((hasDerivAt_id θ).const_mul (2 : ℝ)).cos
      simpa using this
    have := ((c2.const_mul (1 / 4 : ℝ)).const_sub (3 / 4 : ℝ)).sub
      ((Real.hasDerivAt_cos θ).const_mul (1 / 2 : ℝ))
    convert this using 1
    ring
  have hD1 : deriv w₁ = fun θ => (1 / 2) * Real.sin (2 * θ) + (1 / 2) * Real.sin θ :=
    funext fun θ => (hd1 θ).deriv
  have hd2 : ∀ θ : ℝ, HasDerivAt (fun θ : ℝ => (1 / 2) * Real.sin (2 * θ) + (1 / 2) * Real.sin θ)
      (Real.cos (2 * θ) + (1 / 2) * Real.cos θ) θ := by
    intro θ
    have s2 : HasDerivAt (fun t : ℝ => Real.sin (2 * t)) (Real.cos (2 * θ) * 2) θ := by
      have := ((hasDerivAt_id θ).const_mul (2 : ℝ)).sin
      simpa using this
    have := (s2.const_mul (1 / 2 : ℝ)).add ((Real.hasDerivAt_sin θ).const_mul (1 / 2 : ℝ))
    convert this using 1
    ring
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro θ
    rw [hD1, (hd2 θ).deriv]
    simp only [w₁]
    ring
  · simp [w₁]; norm_num
  · rw [hD1]; simp
  · simp only [w₁]
    have h1 : 2 * (π / 2) = π := by ring
    rw [h1]
    simp
    norm_num

-- The trace step: in four dimensions g^{μν} g_{μν} = trace (g⁻¹ g) = 4.
example : trace (1 : Matrix (Fin 4) (Fin 4) ℚ) = 4 := by
  norm_num [Matrix.trace, Fin.sum_univ_four]

-- The clocks-only metric at r = 3 r_s: a' = 1/12, a'' = -5/72, so Ric_rr = -a'' - a'^2 = 1/16 = 0.0625.
example : -(-(5 : ℚ) / 72) - (1 / 12) ^ 2 = 1 / 16 := by norm_num

#print axioms vacuum_einstein_iff_ricci_flat
#print axioms schwarzschild_ricci_components_vanish
#print axioms light_ray_first_order_correction
