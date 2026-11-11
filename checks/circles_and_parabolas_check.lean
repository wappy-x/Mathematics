-- Circles and parabolas: in the flat plane, the points at distance r > 0 from a centre are exactly the solutions of (x-h)^2 + (y-k)^2 = r^2, the points equally far from a focus and a horizontal directrix are exactly the solutions of (x-h)^2 = 4p(y-k), and the line of points equally far from the focus and a curve point's foot on the directrix touches the parabola only there and makes equal angles with the two.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Affine

open EuclideanGeometry

theorem dist_vec2 (a b c d : ℝ) :
    dist !₂[a, b] !₂[c, d] = Real.sqrt ((a - c) ^ 2 + (b - d) ^ 2) := by
  rw [EuclideanSpace.dist_eq]
  simp [Fin.sum_univ_two, Real.dist_eq, sq_abs]

theorem dist_pt_eq (Q : EuclideanSpace ℝ (Fin 2)) (c d : ℝ) :
    dist Q !₂[c, d] = Real.sqrt ((Q 0 - c) ^ 2 + (Q 1 - d) ^ 2) := by
  rw [EuclideanSpace.dist_eq]
  simp [Fin.sum_univ_two, Real.dist_eq, sq_abs]

theorem infDist_line (x y c : ℝ) :
    Metric.infDist !₂[x, y] {q : EuclideanSpace ℝ (Fin 2) | q 1 = c} = |y - c| := by
  have hmem : !₂[x, c] ∈ {q : EuclideanSpace ℝ (Fin 2) | q 1 = c} := by simp
  apply le_antisymm
  · calc _ ≤ dist !₂[x, y] !₂[x, c] := Metric.infDist_le_dist_of_mem hmem
      _ = |y - c| := by rw [dist_vec2]; simp [Real.sqrt_sq_eq_abs]
  · rw [Metric.le_infDist ⟨_, hmem⟩]
    intro q hq
    simp only [Set.mem_ofPred_eq] at hq
    rw [dist_comm, dist_pt_eq, ← hq, ← Real.sqrt_sq_eq_abs]
    apply Real.sqrt_le_sqrt
    simp
    nlinarith [sq_nonneg (q 0 - x)]

#print axioms dist_vec2
#print axioms dist_pt_eq
#print axioms infDist_line

/-- The parabola as a distance rule. In the flat plane with a square grid, take a nonzero focal
length p, a focus at (h, k + p) and a directrix, the grid line y = k - p. A point (x, y) is
exactly as far from the focus as from the directrix if and only if (x - h)^2 = 4p(y - k).
With the vertex at the origin (h = k = 0) this is x^2 = 4py. -/
theorem parabola_equidistant_iff_equation {p : ℝ} (hp : p ≠ 0) (h k x y : ℝ) :
    dist !₂[x, y] !₂[h, k + p] =
        Metric.infDist !₂[x, y] {q : EuclideanSpace ℝ (Fin 2) | q 1 = k - p} ↔
      (x - h) ^ 2 = 4 * p * (y - k) := by
  rw [dist_vec2, infDist_line, ← Real.sqrt_sq_eq_abs,
    Real.sqrt_inj (by positivity) (by positivity)]
  constructor <;> intro H <;> linarith

/-- The circle as a distance rule. In the flat plane with a square grid, for a positive radius r,
a point (x, y) lies at distance r from the centre (h, k) if and only if
(x - h)^2 + (y - k)^2 = r^2. -/
theorem circle_iff_equation {r : ℝ} (hr : 0 < r) (h k x y : ℝ) :
    !₂[x, y] ∈ Metric.sphere !₂[h, k] r ↔ (x - h) ^ 2 + (y - k) ^ 2 = r ^ 2 := by
  rw [Metric.mem_sphere, dist_vec2]
  constructor
  · intro H
    rw [← H, Real.sq_sqrt (by positivity)]
  · intro H
    rw [H, Real.sqrt_sq hr.le]

/-- Why every ray reaches the focus. Take the parabola x^2 = 4py with p nonzero, focus F = (0, p),
a point P = (x₀, x₀^2/(4p)) on it, and D = (x₀, -p), P's foot on the directrix. The line of points
equally far from F and D (the tangent at P) meets the parabola at P alone, and from P it makes
the same angle with PF as with PD, so a ray falling along DP bounces off along PF. -/
theorem parabola_tangent_touches_once_and_halves_angle {p : ℝ} (hp : p ≠ 0) (x₀ : ℝ) :
    {Q : EuclideanSpace ℝ (Fin 2) |
        dist Q !₂[0, p] = dist Q !₂[x₀, -p] ∧ Q 0 ^ 2 = 4 * p * Q 1} =
        {!₂[x₀, x₀ ^ 2 / (4 * p)]} ∧
      ∀ Q : EuclideanSpace ℝ (Fin 2), dist Q !₂[0, p] = dist Q !₂[x₀, -p] →
        ∠ !₂[0, p] !₂[x₀, x₀ ^ 2 / (4 * p)] Q = ∠ !₂[x₀, -p] !₂[x₀, x₀ ^ 2 / (4 * p)] Q := by
  have hc : 4 * p * (x₀ ^ 2 / (4 * p)) = x₀ ^ 2 := by field_simp
  have key : ∀ Q : EuclideanSpace ℝ (Fin 2), dist Q !₂[0, p] = dist Q !₂[x₀, -p] →
      (Q 0 - 0) ^ 2 + (Q 1 - p) ^ 2 = (Q 0 - x₀) ^ 2 + (Q 1 - -p) ^ 2 := by
    intro Q hQ
    rw [dist_pt_eq, dist_pt_eq, Real.sqrt_inj (by positivity) (by positivity)] at hQ
    exact hQ
  refine ⟨?_, ?_⟩
  · ext Q
    simp only [Set.mem_ofPred_eq, Set.mem_singleton_iff]
    constructor
    · rintro ⟨h1, h2⟩
      have h1 := key Q h1
      have ha : (Q 0 - x₀) ^ 2 = 0 := by linear_combination h2 - h1
      have ha' : Q 0 = x₀ := by
        have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp ha
        linarith
      have hb : Q 1 = x₀ ^ 2 / (4 * p) := by
        field_simp
        rw [← ha']
        linarith
      ext i
      fin_cases i
      · simpa using ha'
      · simpa using hb
    · rintro rfl
      refine ⟨?_, ?_⟩
      · rw [dist_pt_eq, dist_pt_eq]
        congr 1
        simp
        linear_combination (-1) * hc
      · simp
        linear_combination (-1) * hc
  · intro Q hQ
    have hQ' := key Q hQ
    have h1 : inner ℝ (!₂[0, p] -ᵥ !₂[x₀, x₀ ^ 2 / (4 * p)]) (Q -ᵥ !₂[x₀, x₀ ^ 2 / (4 * p)]) =
        inner ℝ (!₂[x₀, -p] -ᵥ !₂[x₀, x₀ ^ 2 / (4 * p)]) (Q -ᵥ !₂[x₀, x₀ ^ 2 / (4 * p)]) := by
      simp [PiLp.inner_apply, Fin.sum_univ_two]
      linear_combination (-1/2) * hQ' + (-1/2) * hc
    have h2 : ‖!₂[0, p] -ᵥ !₂[x₀, x₀ ^ 2 / (4 * p)]‖ =
        ‖!₂[x₀, -p] -ᵥ !₂[x₀, x₀ ^ 2 / (4 * p)]‖ := by
      simp [EuclideanSpace.norm_eq, Fin.sum_univ_two]
      congr 1
      linear_combination (-1) * hc
    simp only [EuclideanGeometry.angle, InnerProductGeometry.angle, h1, h2]

-- The dish: rim point (40, 10) on x^2 = 4py gives 4p = 160, so p = 40.
example : (40 : ℤ) ^ 2 = 160 * 10 := by norm_num
example : (4 : ℤ) * 40 = 160 := by norm_num
-- Rim to receiver: 40^2 + 30^2 = 50^2; rim to directrix: 10 + 40 = 50.
example : (40 : ℤ) ^ 2 + (40 - 10) ^ 2 = 50 ^ 2 := by norm_num
example : (10 : ℤ) + 40 = 50 := by norm_num
-- The circle x^2 + y^2 - 80y = 900 becomes x^2 + (y - 40)^2 = 2500 = 50^2 after adding 1600.
example : (900 : ℤ) + 1600 = 2500 ∧ (2500 : ℤ) = 50 ^ 2 := by norm_num
-- Both rim points and (30, 80) lie on it.
example : (40 : ℤ) ^ 2 + 10 ^ 2 - 80 * 10 - 900 = 0 := by norm_num
example : (-40 : ℤ) ^ 2 + 10 ^ 2 - 80 * 10 - 900 = 0 := by norm_num
example : (30 : ℤ) ^ 2 + 80 ^ 2 - 80 * 80 - 900 = 0 := by norm_num
-- The tangent at P meets x^2 = 160y in x^2 - 80x + 1600 = 0, whose discriminant is 0.
example : (-80 : ℤ) ^ 2 - 4 * 1600 = 0 := by norm_num

#print axioms parabola_equidistant_iff_equation
#print axioms circle_iff_equation
#print axioms parabola_tangent_touches_once_and_halves_angle
