-- Cylindrical and spherical coordinates: every point off the axis has exactly one spherical address (ρ, θ, φ), the atan2 recipe finds it, and ρ² = x² + y² + z².
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real

/-- The length of the complex number u + v i is √(u² + v²). -/
lemma norm_mk_eq_sqrt (u v : ℝ) : ‖(⟨u, v⟩ : ℂ)‖ = √(u ^ 2 + v ^ 2) := by
  rw [Complex.norm_def, Complex.normSq_apply]
  congr 1
  simp only
  ring

/-- The atan2 recipe gives an address in the ranges that lands back on the point. -/
lemma back_from_grid_aux (x y z : ℝ) (h : 0 < x ^ 2 + y ^ 2) :
    0 < √(x ^ 2 + y ^ 2 + z ^ 2) ∧ Complex.arg ⟨x, y⟩ ∈ Set.Ioc (-π) π ∧
      Complex.arg ⟨z, √(x ^ 2 + y ^ 2)⟩ ∈ Set.Icc 0 π ∧
      x = √(x ^ 2 + y ^ 2 + z ^ 2) * sin (Complex.arg ⟨z, √(x ^ 2 + y ^ 2)⟩) *
        cos (Complex.arg ⟨x, y⟩) ∧
      y = √(x ^ 2 + y ^ 2 + z ^ 2) * sin (Complex.arg ⟨z, √(x ^ 2 + y ^ 2)⟩) *
        sin (Complex.arg ⟨x, y⟩) ∧
      z = √(x ^ 2 + y ^ 2 + z ^ 2) * cos (Complex.arg ⟨z, √(x ^ 2 + y ^ 2)⟩) := by
  have hr : 0 ≤ √(x ^ 2 + y ^ 2) := Real.sqrt_nonneg _
  have hn : ‖(⟨z, √(x ^ 2 + y ^ 2)⟩ : ℂ)‖ = √(x ^ 2 + y ^ 2 + z ^ 2) := by
    rw [norm_mk_eq_sqrt, Real.sq_sqrt h.le]
    congr 1
    ring
  have hs := Complex.norm_mul_sin_arg (⟨z, √(x ^ 2 + y ^ 2)⟩ : ℂ)
  have hc := Complex.norm_mul_cos_arg (⟨z, √(x ^ 2 + y ^ 2)⟩ : ℂ)
  have hs' := Complex.norm_mul_sin_arg (⟨x, y⟩ : ℂ)
  have hc' := Complex.norm_mul_cos_arg (⟨x, y⟩ : ℂ)
  rw [hn] at hs hc
  rw [norm_mk_eq_sqrt] at hs' hc'
  simp only at hs hc hs' hc'
  refine ⟨Real.sqrt_pos.mpr (by positivity), Complex.arg_mem_Ioc _,
    ⟨Complex.arg_nonneg_iff.mpr hr, Complex.arg_le_pi _⟩, ?_, ?_, hc.symm⟩
  · rw [hs, hc']
  · rw [hs, hs']

#print axioms norm_mk_eq_sqrt
#print axioms back_from_grid_aux

/-- A point written as r cos θ + r sin θ i with r > 0 and θ in (−π, π] has angle θ. -/
lemma arg_mk_mul_cos_sin {r θ : ℝ} (hr : 0 < r) (hθ : θ ∈ Set.Ioc (-π) π) :
    Complex.arg ⟨r * cos θ, r * sin θ⟩ = θ := by
  have e : (⟨r * cos θ, r * sin θ⟩ : ℂ) =
      (r : ℂ) * (Complex.cos θ + Complex.sin θ * Complex.I) := by
    apply Complex.ext <;>
      simp [← Complex.ofReal_cos, ← Complex.ofReal_sin, Complex.mul_re, Complex.mul_im]
  rw [e, Complex.arg_mul_cos_add_sin_mul_I hr hθ]

#print axioms arg_mk_mul_cos_sin

/-- Every point off the axis has exactly one address: for a point (x, y, z) with
r = √(x² + y²) > 0 there is exactly one triple (ρ, θ, φ) with ρ > 0, θ above −π and up to π,
φ from 0 to π, such that x = ρ sin φ cos θ, y = ρ sin φ sin θ and z = ρ cos φ.
The triple is written p = (ρ, θ, φ), so p.1 = ρ, p.2.1 = θ, p.2.2 = φ. -/
theorem off_axis_point_has_unique_spherical_address (x y z : ℝ) (h : 0 < x ^ 2 + y ^ 2) :
    ∃! p : ℝ × ℝ × ℝ,
      0 < p.1 ∧ p.2.1 ∈ Set.Ioc (-π) π ∧ p.2.2 ∈ Set.Icc 0 π ∧
      x = p.1 * sin p.2.2 * cos p.2.1 ∧
      y = p.1 * sin p.2.2 * sin p.2.1 ∧
      z = p.1 * cos p.2.2 := by
  obtain ⟨h0, h1, h2, h3, h4, h5⟩ := back_from_grid_aux x y z h
  refine ⟨(√(x ^ 2 + y ^ 2 + z ^ 2), Complex.arg ⟨x, y⟩,
    Complex.arg ⟨z, √(x ^ 2 + y ^ 2)⟩), ⟨h0, h1, h2, h3, h4, h5⟩, ?_⟩
  rintro ⟨ρ, θ, φ⟩ ⟨hρ, hθ, hφ, hx, hy, hz⟩
  simp only at hρ hθ hφ hx hy hz
  have sθ := sin_sq_add_cos_sq θ
  have sφ := sin_sq_add_cos_sq φ
  have hsinφ : 0 ≤ sin φ := Real.sin_nonneg_of_nonneg_of_le_pi hφ.1 hφ.2
  have hxy : x ^ 2 + y ^ 2 = (ρ * sin φ) ^ 2 := by
    rw [hx, hy]; linear_combination (ρ * sin φ) ^ 2 * sθ
  have hxyz : x ^ 2 + y ^ 2 + z ^ 2 = ρ ^ 2 := by
    rw [hxy, hz]; linear_combination ρ ^ 2 * sφ
  have hr : √(x ^ 2 + y ^ 2) = ρ * sin φ := by
    rw [hxy, Real.sqrt_sq (mul_nonneg hρ.le hsinφ)]
  have hrpos : 0 < ρ * sin φ := by
    rw [← hr]; exact Real.sqrt_pos.mpr h
  have eρ : √(x ^ 2 + y ^ 2 + z ^ 2) = ρ := by
    rw [hxyz, Real.sqrt_sq hρ.le]
  have eθ : Complex.arg ⟨x, y⟩ = θ := by
    rw [hx, hy]; exact arg_mk_mul_cos_sin hrpos hθ
  have eφ : Complex.arg ⟨z, √(x ^ 2 + y ^ 2)⟩ = φ := by
    rw [hr, hz, mul_comm ρ (sin φ), mul_comm ρ (cos φ), ← mul_comm ρ, ← mul_comm ρ]
    exact arg_mk_mul_cos_sin hρ ⟨by linarith [hφ.1, Real.pi_pos], hφ.2⟩
  rw [eρ, eθ, eφ]

/-- Back from the grid: for a point off the axis, with r = √(x² + y²),
ρ = √(x² + y² + z²), θ = atan2(y, x) and φ = atan2(r, z) give an address in the ranges
(ρ > 0, θ above −π and up to π, φ from 0 to π) that lands back on the same point.
Here atan2(v, u) is the angle of the direction u across, v up, which Mathlib calls
`Complex.arg` of u + v i. -/
theorem back_from_grid_recovers_point (x y z : ℝ) (h : 0 < x ^ 2 + y ^ 2) :
    let r := √(x ^ 2 + y ^ 2)
    let ρ := √(x ^ 2 + y ^ 2 + z ^ 2)
    let θ := Complex.arg ⟨x, y⟩
    let φ := Complex.arg ⟨z, r⟩
    0 < ρ ∧ θ ∈ Set.Ioc (-π) π ∧ φ ∈ Set.Icc 0 π ∧
      x = ρ * sin φ * cos θ ∧ y = ρ * sin φ * sin θ ∧ z = ρ * cos φ := by
  exact back_from_grid_aux x y z h

/-- The spherical formulas keep the distance from the centre: for every radius and both
angles, x² + y² + z² = ρ², using sin² + cos² = 1 twice. -/
theorem spherical_sum_of_squares (ρ θ φ : ℝ) :
    (ρ * sin φ * cos θ) ^ 2 + (ρ * sin φ * sin θ) ^ 2 + (ρ * cos φ) ^ 2 = ρ ^ 2 := by
  linear_combination (ρ ^ 2 * sin φ ^ 2) * sin_sq_add_cos_sq θ + ρ ^ 2 * sin_sq_add_cos_sq φ

#print axioms off_axis_point_has_unique_spherical_address
#print axioms back_from_grid_recovers_point
#print axioms spherical_sum_of_squares
