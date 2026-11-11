-- Fractals: the power D with s^D = N is exactly log N / log s, the Koch snowflake's perimeter passes every bound while its area stays under the hexagon and settles at 8/5 of the first triangle, and the Koch and Sierpinski dimensions lie strictly between 1 and 2.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Filter Topology

/-- The similarity dimension. Magnify a shape s times (s more than 1) and count N copies of the
original inside (at least one). Then there is exactly one power D with s^D = N, and it is
D = log N / log s. -/
theorem similarity_dimension_eq_log_div_log (s : ℝ) (N : ℕ) (hs : 1 < s) (hN : 0 < N) (D : ℝ) :
    s ^ D = (N : ℝ) ↔ D = Real.log N / Real.log s := by
  have hs0 : 0 < s := by linarith
  have hls : 0 < Real.log s := Real.log_pos hs
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  constructor
  · intro h
    rw [eq_div_iff hls.ne', ← h, Real.log_rpow hs0]
  · intro h
    rw [Real.rpow_def_of_pos hs0, h, mul_div_cancel₀ _ hls.ne', Real.exp_log hN']

/-- The Koch snowflake from a first triangle with side L. Stage n has 3 × 4^n sides, each
L / 3^n long, so its perimeter passes any length named in advance. Stage k + 1 adds 3 × 4^k
small triangles, each 1/9^(k+1) of the first triangle's area A₀ = (√3/4) L². So the area at
stage n is A₀ (8/5 − 3/5 (4/9)^n), it never reaches the hexagon's 2 A₀, and it settles at
8/5 A₀: endless perimeter, finite area. -/
theorem koch_snowflake_endless_perimeter_finite_area (L : ℝ) (hL : 0 < L) :
    let A₀ : ℝ := Real.sqrt 3 / 4 * L ^ 2
    let area : ℕ → ℝ := fun n => A₀ + ∑ k ∈ Finset.range n, 3 * 4 ^ k * (A₀ / 9 ^ (k + 1))
    (∀ M : ℝ, ∃ n : ℕ, M < (3 * 4 ^ n : ℝ) * (L / 3 ^ n)) ∧
    (∀ n : ℕ, area n = A₀ * (8 / 5 - 3 / 5 * (4 / 9) ^ n)) ∧
    (∀ n : ℕ, area n < 2 * A₀) ∧
    Tendsto area atTop (𝓝 (8 / 5 * A₀)) := by
  intro A₀ area
  have hA : 0 < A₀ := by
    show 0 < Real.sqrt 3 / 4 * L ^ 2
    have : 0 < Real.sqrt 3 := Real.sqrt_pos.mpr (by norm_num)
    positivity
  have hform : ∀ n : ℕ, area n = A₀ * (8 / 5 - 3 / 5 * (4 / 9) ^ n) := by
    intro n
    induction n with
    | zero => simp [area]; norm_num
    | succ n ih =>
      have : area (n + 1) = area n + 3 * 4 ^ n * (A₀ / 9 ^ (n + 1)) := by
        simp only [area, Finset.sum_range_succ]; ring
      rw [this, ih, div_pow, div_pow]
      field_simp
      ring
  refine ⟨?_, hform, ?_, ?_⟩
  · intro M
    obtain ⟨n, hn⟩ := pow_unbounded_of_one_lt (M / (3 * L)) (by norm_num : (1 : ℝ) < 4 / 3)
    refine ⟨n, ?_⟩
    have h3L : 0 < 3 * L := by positivity
    have heq : (3 * 4 ^ n : ℝ) * (L / 3 ^ n) = 3 * L * (4 / 3) ^ n := by
      rw [div_pow]; field_simp
    rw [heq]
    rw [div_lt_iff₀ h3L] at hn
    linarith
  · intro n
    rw [hform n]
    have : 0 ≤ (4 / 9 : ℝ) ^ n := by positivity
    nlinarith
  · have hfun : area = fun n => A₀ * (8 / 5 - 3 / 5 * (4 / 9 : ℝ) ^ n) := funext hform
    rw [hfun]
    have ht : Tendsto (fun n : ℕ => (4 / 9 : ℝ) ^ n) atTop (𝓝 0) :=
      tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num)
    have := ((ht.const_mul (3 / 5)).const_sub (8 / 5)).const_mul A₀
    convert this using 2
    ring

/-- Not a whole number: the Koch edge (4 copies at a third the size) and the Sierpinski
triangle (3 copies at half the size) both have dimension strictly between a line's 1 and a
surface's 2. -/
theorem koch_and_sierpinski_dimensions_between_one_and_two :
    (1 < Real.log 4 / Real.log 3 ∧ Real.log 4 / Real.log 3 < 2) ∧
    (1 < Real.log 3 / Real.log 2 ∧ Real.log 3 / Real.log 2 < 2) := by
  have h2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have h3 : 0 < Real.log 3 := Real.log_pos (by norm_num)
  have h23 : Real.log 2 < Real.log 3 := Real.log_lt_log (by norm_num) (by norm_num)
  have h34 : Real.log 3 < Real.log 4 := Real.log_lt_log (by norm_num) (by norm_num)
  have h49 : Real.log 4 < Real.log 9 := Real.log_lt_log (by norm_num) (by norm_num)
  have h9 : Real.log 9 = 2 * Real.log 3 := by
    rw [show (9 : ℝ) = 3 ^ 2 by norm_num, Real.log_pow]; norm_num
  have h4 : Real.log 4 = 2 * Real.log 2 := by
    rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; norm_num
  refine ⟨⟨?_, ?_⟩, ?_, ?_⟩
  · rw [lt_div_iff₀ h3]; linarith
  · rw [div_lt_iff₀ h3]; linarith
  · rw [lt_div_iff₀ h2]; linarith
  · rw [div_lt_iff₀ h2]; linarith

-- Magnified 3 times: a segment holds 3 copies, a square 9 = 3^2, a cube 27 = 3^3.
example : 3 ^ 1 = 3 ∧ 3 ^ 2 = 9 ∧ 3 ^ 3 = 27 := by decide
-- Two Koch stages as one: magnify 9 = 3^2 times and 16 = 4^2 copies fit.
example : 4 ^ 2 = 16 ∧ 3 ^ 2 = 9 := by decide
-- Sides: 3 at stage 0, 12 at stage 1, 48 at stage 2, 12288 at stage 6; stage 1 sides are 27 / 3 = 9 cm.
example : 3 * 4 ^ 0 = 3 ∧ 3 * 4 ^ 1 = 12 ∧ 3 * 4 ^ 2 = 48 ∧ 3 * 4 ^ 6 = 12288 ∧ 27 / 3 = 9 := by decide
-- Perimeter 3 × 27 × (4/3)^n: 81, 108, 144, 192, 256 cm.
example : (3 * 27 : ℚ) * (4 / 3) ^ 0 = 81 ∧ (3 * 27 : ℚ) * (4 / 3) ^ 1 = 108 ∧
    (3 * 27 : ℚ) * (4 / 3) ^ 2 = 144 ∧ (3 * 27 : ℚ) * (4 / 3) ^ 3 = 192 ∧
    (3 * 27 : ℚ) * (4 / 3) ^ 4 = 256 := by norm_num
-- The perimeter first passes 1 km = 100,000 cm at stage 25.
example : (81 : ℚ) * (4 / 3) ^ 24 ≤ 100000 ∧ 100000 < (81 : ℚ) * (4 / 3) ^ 25 := by norm_num
-- The perimeter first passes the equator, 40075 km = 4,007,500,000 cm, at stage 62.
example : (81 : ℚ) * (4 / 3) ^ 61 ≤ 4007500000 ∧ 4007500000 < (81 : ℚ) * (4 / 3) ^ 62 := by norm_num
-- Area formula, in units of the first triangle: 1 at stage 0, 4/3 at stage 1 (a third added).
example : (8 / 5 - 3 / 5 * (4 / 9) ^ 0 : ℚ) = 1 ∧ (8 / 5 - 3 / 5 * (4 / 9) ^ 1 : ℚ) = 1 + 1 / 3 := by norm_num
-- Stage 1 adds 3 triangles of 1/9 the area; stage 2 adds 12 of 1/81, four ninths of stage 1's gain.
example : (3 : ℚ) * (1 / 9) = 1 / 3 ∧ (12 : ℚ) * (1 / 81) = 4 / 9 * (1 / 3) := by norm_num
-- The hexagon: the triangle plus three caps, each a third of the triangle, is twice the triangle.
example : (1 : ℚ) + 3 * (1 / 3) = 2 := by norm_num
-- Sierpinski stage 6: 3^6 = 729 triangles, each 1/4^6 of the area, so (3/4)^6 of the area is left.
example : 3 ^ 6 = 729 ∧ (729 : ℚ) / 4 ^ 6 = (3 / 4) ^ 6 := by norm_num

#print axioms similarity_dimension_eq_log_div_log
#print axioms koch_snowflake_endless_perimeter_finite_area
#print axioms koch_and_sierpinski_dimensions_between_one_and_two
