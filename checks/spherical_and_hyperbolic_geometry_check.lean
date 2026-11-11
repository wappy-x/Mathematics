-- Three geometries: circles of the same true radius have less rim on a sphere and more in the Poincaré disc than on flat ground (the disc rim is exactly 2π sinh ρ), a disc triangle's angles add to less than π, two great circles always meet, and through a point off a disc line pass infinitely many disc lines that never meet it.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith

open InnerProductGeometry
open scoped Real RealInnerProductSpace

lemma angle_lt_pi_div_four_of {x y : EuclideanSpace ℝ (Fin 2)}
    (h : √2 / 2 < ⟪x, y⟫ / (‖x‖ * ‖y‖)) : angle x y < π / 4 := by
  by_contra hc
  push Not at hc
  have := Real.cos_le_cos_of_nonneg_of_le_pi (by positivity) (angle_le_pi x y) hc
  rw [cos_angle, Real.cos_pi_div_four] at this
  linarith

lemma sqrt_two_div_two_lt (h S : ℝ) (hh : 0 < h) (hS : 0 < S) (h2 : S < 2 * h ^ 2) :
    √2 / 2 < h / √S := by
  have hq : 0 < h / √S := by positivity
  have hq2 : (h / √S) ^ 2 = h ^ 2 / S := by
    rw [div_pow, Real.sq_sqrt hS.le]
  have hgt : 1 / 2 < (h / √S) ^ 2 := by
    rw [hq2, lt_div_iff₀ hS]; linarith
  have h22 := Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num)
  nlinarith [Real.sqrt_nonneg 2]

#print axioms angle_lt_pi_div_four_of
#print axioms sqrt_two_div_two_lt

/-- Circles grow slower on a sphere and faster in the hyperbolic plane. Take a circle of true
radius `ρ > 0`. On a ball of radius 1 its rim is `2π sin ρ`; on flat ground it is `2πρ`. In the
Poincaré disc the circle is drawn at drawn radius `r`, where `r` is the drawn distance whose true
distance from the centre is `ρ`: adding the disc's ruler `2/(1 - s^2)` over thin slices from 0 to
`r` gives `ρ`. Every point of the drawn circle has the same factor, so its true rim is
`2πr × 2/(1 - r^2)`. Then `2π sin ρ < 2πρ < 2πr × 2/(1 - r^2)`, and that last rim is exactly
`2π sinh ρ`. -/
theorem circle_rims_sphere_flat_hyperbolic (ρ r : ℝ) (hρ : 0 < ρ) (hr0 : 0 ≤ r) (hr1 : r < 1)
    (hdist : ∫ s in (0 : ℝ)..r, 2 / (1 - s ^ 2) = ρ) :
    2 * π * Real.sin ρ < 2 * π * ρ ∧
      2 * π * ρ < 2 * π * r * (2 / (1 - r ^ 2)) ∧
      2 * π * r * (2 / (1 - r ^ 2)) = 2 * π * Real.sinh ρ := by
  have hderiv : ∀ x ∈ Set.uIcc 0 r,
      HasDerivAt (fun s => Real.log (1 + s) - Real.log (1 - s)) (2 / (1 - x ^ 2)) x := by
    intro x hx
    rw [Set.uIcc_of_le hr0] at hx
    obtain ⟨hx0, hxr⟩ := hx
    have h1 : 0 < 1 + x := by linarith
    have h2 : 0 < 1 - x := by linarith
    have := (((hasDerivAt_id x).const_add 1).log h1.ne').sub
      (((hasDerivAt_id x).const_sub 1).log h2.ne')
    convert this using 1
    · rfl
    · have h3 : 1 - x ^ 2 ≠ 0 := by nlinarith
      simp only [id]
      field_simp
      ring
  have hcont : IntervalIntegrable (fun s : ℝ => 2 / (1 - s ^ 2)) MeasureTheory.volume 0 r := by
    apply ContinuousOn.intervalIntegrable
    apply ContinuousOn.div continuousOn_const (by fun_prop)
    intro x hx
    rw [Set.uIcc_of_le hr0] at hx
    obtain ⟨hx0, hxr⟩ := hx
    nlinarith
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hcont] at hdist
  simp only [add_zero, sub_zero, Real.log_one] at hdist
  have h1 : 0 < 1 + r := by linarith
  have h2 : 0 < 1 - r := by linarith
  have hexp : Real.exp ρ = (1 + r) / (1 - r) := by
    rw [← hdist, Real.exp_sub, Real.exp_log h1, Real.exp_log h2]
  have hsinh : Real.sinh ρ = r * (2 / (1 - r ^ 2)) := by
    rw [Real.sinh_eq, Real.exp_neg, hexp]
    have h3 : 1 - r ^ 2 ≠ 0 := by nlinarith
    field_simp
    ring
  have h3 : 2 * π * r * (2 / (1 - r ^ 2)) = 2 * π * Real.sinh ρ := by
    rw [hsinh]; ring
  refine ⟨?_, ?_, h3⟩
  · have := Real.sin_lt hρ
    have := Real.pi_pos
    nlinarith
  · rw [h3]
    have := Real.self_lt_sinh_iff.mpr hρ
    have := Real.pi_pos
    nlinarith

/-- A disc triangle falls short of 180°. In the Poincaré disc (rim radius 1, centre `O`), put
`A = (a, 0)` and `B = (0, a)` at drawn distance `a` along two square diameters, `0 < a < 1`.
Side `AB` is a disc line: an arc of the circle with centre `(c₁, c₂)` and radius `k` that passes
through `A` and `B` and meets the rim square, so `c₁^2 + c₂^2 = 1 + k^2`. Drawn angles are true
angles. At `O` the sides run along `(1, 0)` and `(0, 1)`. At `A` the way back to `O` is `(-1, 0)`
and the arc leaves along `(-c₂, c₁ - a)`, square to the radius `A - c`; at `B` the way back is
`(0, -1)` and the arc leaves along `(c₂ - a, -c₁)`, square to `B - c`. The three angles add to
less than π. -/
theorem disc_triangle_angle_sum_lt_pi (a c₁ c₂ k : ℝ) (ha0 : 0 < a) (ha1 : a < 1)
    (hA : (a - c₁) ^ 2 + c₂ ^ 2 = k ^ 2) (hB : c₁ ^ 2 + (a - c₂) ^ 2 = k ^ 2)
    (hrim : c₁ ^ 2 + c₂ ^ 2 = 1 + k ^ 2) :
    angle (!₂[1, 0] : EuclideanSpace ℝ (Fin 2)) !₂[0, 1] +
        angle (!₂[-1, 0] : EuclideanSpace ℝ (Fin 2)) !₂[-c₂, c₁ - a] +
        angle (!₂[0, -1] : EuclideanSpace ℝ (Fin 2)) !₂[c₂ - a, -c₁] < π := by
  have hc : c₂ = c₁ := by
    have : a * (c₂ - c₁) = 0 := by nlinarith
    rcases mul_eq_zero.mp this with h | h
    · linarith
    · linarith
  subst hc
  have hq : a ^ 2 - 2 * a * c₂ + 1 = 0 := by nlinarith
  have hpos : a < c₂ := by nlinarith
  have hO : angle (!₂[1, 0] : EuclideanSpace ℝ (Fin 2)) !₂[0, 1] = π / 2 := by
    rw [← inner_eq_zero_iff_angle_eq_pi_div_two]
    simp [EuclideanSpace.inner_eq_star_dotProduct, Fin.sum_univ_two, dotProduct]
  have hAng : angle (!₂[-1, 0] : EuclideanSpace ℝ (Fin 2)) !₂[-c₂, c₂ - a] < π / 4 := by
    apply angle_lt_pi_div_four_of
    simp [EuclideanSpace.inner_eq_star_dotProduct, Fin.sum_univ_two, dotProduct,
      EuclideanSpace.norm_eq]
    apply sqrt_two_div_two_lt <;> nlinarith
  have hBng : angle (!₂[0, -1] : EuclideanSpace ℝ (Fin 2)) !₂[c₂ - a, -c₂] < π / 4 := by
    apply angle_lt_pi_div_four_of
    simp [EuclideanSpace.inner_eq_star_dotProduct, Fin.sum_univ_two, dotProduct,
      EuclideanSpace.norm_eq]
    apply sqrt_two_div_two_lt <;> nlinarith
  rw [hO]
  linarith

/-- No parallels on a sphere, endless parallels in the disc.
Sphere: a great circle is where a plane through the ball's centre cuts the unit sphere; the plane
is given by a nonzero arrow `n` square to it. Any two great circles share a point.
Disc: the given line is the diameter `OA`, the points `(x, 0)` with `-1 < x < 1`, and the point
off it is `B = (0, 1/2)`. A disc line through `B` that is not a diameter is a circle with centre
`c` and radius `k > 0` through `B` that meets the rim square, `c₁^2 + c₂^2 = 1 + k^2`. The
centres of those disc lines through `B` that never meet the diameter form an infinite set. -/
theorem parallels_none_on_sphere_endless_in_disc :
    (∀ n₁ n₂ : EuclideanSpace ℝ (Fin 3), n₁ ≠ 0 → n₂ ≠ 0 →
      ∃ p ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1, ⟪p, n₁⟫ = 0 ∧ ⟪p, n₂⟫ = 0) ∧
    Set.Infinite {c : ℝ × ℝ | ∃ k : ℝ, 0 < k ∧ c.1 ^ 2 + c.2 ^ 2 = 1 + k ^ 2 ∧
      (0 - c.1) ^ 2 + (1 / 2 - c.2) ^ 2 = k ^ 2 ∧
      ∀ x : ℝ, -1 < x → x < 1 → (x - c.1) ^ 2 + (0 - c.2) ^ 2 ≠ k ^ 2} := by
  refine ⟨?_, ?_⟩
  · intro n₁ n₂ _ _
    set K : Submodule ℝ (EuclideanSpace ℝ (Fin 3)) := Submodule.span ℝ (Set.range ![n₁, n₂])
    have hK : Module.finrank ℝ K ≤ 2 := by
      exact (finrank_range_le_card (R := ℝ) ![n₁, n₂]).trans (by simp)
    have hsum := K.finrank_add_finrank_orthogonal
    rw [finrank_euclideanSpace_fin] at hsum
    have hpos : 0 < Module.finrank ℝ Kᗮ := by omega
    obtain ⟨v, hv⟩ := Module.finrank_pos_iff_exists_ne_zero.mp hpos
    have hv0 : (v : EuclideanSpace ℝ (Fin 3)) ≠ 0 := by simpa using hv
    have hn : ‖(v : EuclideanSpace ℝ (Fin 3))‖ ≠ 0 := norm_ne_zero_iff.mpr hv0
    refine ⟨‖(v : EuclideanSpace ℝ (Fin 3))‖⁻¹ • (v : EuclideanSpace ℝ (Fin 3)), ?_, ?_, ?_⟩
    · simp [norm_smul, hn]
    · have h1 : n₁ ∈ K := Submodule.subset_span ⟨0, rfl⟩
      have := (Submodule.mem_orthogonal' K _).mp v.2 n₁ h1
      rw [inner_smul_left, this]; simp
    · have h1 : n₂ ∈ K := Submodule.subset_span ⟨1, rfl⟩
      have := (Submodule.mem_orthogonal' K _).mp v.2 n₂ h1
      rw [inner_smul_left, this]; simp
  · have hinj : Set.InjOn (fun u : ℝ => ((u, 5 / 4) : ℝ × ℝ)) (Set.Ioo (-1) 1) := by
      intro u _ v _ h
      simpa using h
    refine ((Set.Ioo_infinite (by norm_num : (-1 : ℝ) < 1)).image hinj).mono ?_
    rintro _ ⟨u, ⟨hu1, hu2⟩, rfl⟩
    refine ⟨√(u ^ 2 + 9 / 16), by positivity, ?_, ?_, ?_⟩
    · rw [Real.sq_sqrt (by positivity)]; ring
    · rw [Real.sq_sqrt (by positivity)]; ring
    · intro x _ _
      rw [Real.sq_sqrt (by positivity)]
      intro h
      nlinarith [sq_nonneg (x - u)]


-- Flat triangle O, A, B: 90 + 45 + 45 = 180. Octant on a ball: three right angles, 270.
example : (90 + 45 + 45 : ℕ) = 180 ∧ (90 + 90 + 90 : ℕ) = 270 := by decide
-- Step 2: from e^d - r e^d = 1 + r, the drawn distance is r = (e^d - 1)/(e^d + 1).
example (r E : ℝ) (hE : 0 < E) (h : E - r * E = 1 + r) : r = (E - 1) / (E + 1) := by
  rw [eq_div_iff (by linarith)]
  linarith
-- Step 3: with r = (E - 1)/(E + 1), 1 - r^2 = 4E/(E + 1)^2 and 2r/(1 - r^2) = (E^2 - 1)/(2E).
example (E : ℝ) (hE : 0 < E) :
    1 - ((E - 1) / (E + 1)) ^ 2 = 4 * E / (E + 1) ^ 2 ∧
      2 * ((E - 1) / (E + 1)) / (1 - ((E - 1) / (E + 1)) ^ 2) = (E ^ 2 - 1) / (2 * E) := by
  have h1 : E + 1 ≠ 0 := by linarith
  have h2 : 1 - ((E - 1) / (E + 1)) ^ 2 = 4 * E / (E + 1) ^ 2 := by
    field_simp
    ring
  refine ⟨h2, ?_⟩
  rw [h2]
  have : E ≠ 0 := hE.ne'
  field_simp
  ring
-- Step 4 with a = 1/2: h = (1 + a^2)/(2a) = 5/4, k^2 = 2h^2 - 1 = 17/8, the circle passes
-- through A = (1/2, 0), and the angle at A has tangent (h - a)/h = 3/5.
example : (1 + (1 / 2 : ℚ) ^ 2) / (2 * (1 / 2)) = 5 / 4 ∧ 2 * (5 / 4 : ℚ) ^ 2 - 1 = 17 / 8 ∧
    (1 / 2 - 5 / 4 : ℚ) ^ 2 + (5 / 4) ^ 2 = 17 / 8 ∧ ((5 / 4 : ℚ) - 1 / 2) / (5 / 4) = 3 / 5 := by
  norm_num
-- Step 5: circles centred (u, 5/4) through B = (0, 1/2). At u = 0 the radius is 3/4, the rim
-- test gives 1 and the lowest point is 1/2; at u = 1/2 the squared radius is 13/16, rim test 1.
example : (0 : ℚ) ^ 2 + (5 / 4 - 1 / 2) ^ 2 = (3 / 4) ^ 2 ∧ (0 : ℚ) ^ 2 + (5 / 4) ^ 2 - (3 / 4) ^ 2 = 1 ∧
    (5 / 4 - 3 / 4 : ℚ) = 1 / 2 ∧ (1 / 2 : ℚ) ^ 2 + (5 / 4 - 1 / 2) ^ 2 = 13 / 16 ∧
    (1 / 2 : ℚ) ^ 2 + (5 / 4) ^ 2 - 13 / 16 = 1 := by
  norm_num

#print axioms circle_rims_sphere_flat_hyperbolic
#print axioms disc_triangle_angle_sum_lt_pi
#print axioms parallels_none_on_sphere_endless_in_disc
