-- Multigrid: weighted Jacobi with weight 2/3 shrinks every jagged wave on the bar to at most a third, the two-grid cycle has factor exactly 1/9 on every pair of waves, and a V-cycle costs at most 4/3 of its finest level.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Real

/-! The bar: `-u'' = f` on `(0, 1)` with `u = 0` at both ends, on a grid of `n` inside points
with spacing `h = 1 / (n + 1)`. An error is a function `e : ℤ → ℝ` on the grid points; the bar's
inside points are `j = 1, ..., n` and its two ends are `j = 0` and `j = n + 1`.

* `barA h e j` is the grid matrix `A_h = tridiag(-1, 2, -1) / h ^ 2` applied to `e` at point `j`.
* `jacobiSweep h ω e j` is one sweep of weighted Jacobi on the error, `e ← e - ω D⁻¹ A_h e`,
  with `D = 2 / h ^ 2` the diagonal of `A_h`.
* `wave n k j = sin (j θ)` is the `k`-th error wave `sin (k π x)` sampled at the grid points,
  with angle `θ = k π h`. -/

/-- The bar's grid matrix `A_h = tridiag(-1, 2, -1) / h ^ 2`, applied to `e` at point `j`. -/
noncomputable def barA (h : ℝ) (e : ℤ → ℝ) (j : ℤ) : ℝ :=
  (2 * e j - e (j - 1) - e (j + 1)) / h ^ 2

/-- One weighted-Jacobi sweep on the error: `e ← e - ω D⁻¹ A_h e`, with `D = 2 / h ^ 2`. -/
noncomputable def jacobiSweep (h ω : ℝ) (e : ℤ → ℝ) (j : ℤ) : ℝ :=
  e j - ω * (h ^ 2 / 2) * barA h e j

/-- The angle `θ = k π h` of the `k`-th wave on the grid with `n` inside points, `h = 1 / (n + 1)`. -/
noncomputable def waveAngle (n k : ℕ) : ℝ := k * π * (1 / ((n : ℝ) + 1))

/-- The `k`-th error wave on the bar, `sin (k π x)` at the grid point `x = j h`. -/
noncomputable def wave (n k : ℕ) (j : ℤ) : ℝ := Real.sin (j * waveAngle n k)

/-- **Weighted Jacobi damps jagged waves.** On the bar with `n` inside points and
`h = 1 / (n + 1)`, the `k`-th wave `sin (k π x)` is zero at both ends, it is an eigenvector of
`A_h` with eigenvalue `4 sin² (θ / 2) / h ²`, and one weighted-Jacobi sweep with weight `ω`
multiplies it by `g(θ) = 1 - 2 ω sin² (θ / 2)`. With `ω = 2 / 3`, every jagged wave
(angle `θ` from `π / 2` to `π`, that is `n + 1 ≤ 2 k`) keeps at most a third of itself:
`|g(θ)| ≤ 1 / 3`. -/
theorem weighted_jacobi_damps_jagged_waves (n k : ℕ) (ω : ℝ) :
    wave n k 0 = 0 ∧ wave n k ((n : ℤ) + 1) = 0 ∧
    (∀ j : ℤ, barA (1 / ((n : ℝ) + 1)) (wave n k) j =
        4 * Real.sin (waveAngle n k / 2) ^ 2 / (1 / ((n : ℝ) + 1)) ^ 2 * wave n k j) ∧
    (∀ j : ℤ, jacobiSweep (1 / ((n : ℝ) + 1)) ω (wave n k) j =
        (1 - 2 * ω * Real.sin (waveAngle n k / 2) ^ 2) * wave n k j) ∧
    (ω = 2 / 3 → n + 1 ≤ 2 * k → k ≤ n →
        |1 - 2 * ω * Real.sin (waveAngle n k / 2) ^ 2| ≤ 1 / 3) := by
  set θ := waveAngle n k with hθ
  have hn : ((n : ℝ) + 1) ≠ 0 := by positivity
  have hh : (1 / ((n : ℝ) + 1)) ≠ 0 := by positivity
  have hcos : Real.cos θ = 1 - 2 * Real.sin (θ / 2) ^ 2 := by
    have h1 := Real.cos_two_mul (θ / 2)
    have h2 := Real.sin_sq_add_cos_sq (θ / 2)
    rw [show 2 * (θ / 2) = θ by ring] at h1
    linarith
  have heig : ∀ j : ℤ, barA (1 / ((n : ℝ) + 1)) (wave n k) j =
      4 * Real.sin (θ / 2) ^ 2 / (1 / ((n : ℝ) + 1)) ^ 2 * wave n k j := by
    intro j
    simp only [barA, wave]
    rw [← hθ]
    have e1 : ((j - 1 : ℤ) : ℝ) * θ = (j : ℝ) * θ - θ := by push_cast; ring
    have e2 : ((j + 1 : ℤ) : ℝ) * θ = (j : ℝ) * θ + θ := by push_cast; ring
    rw [e1, e2, Real.sin_sub, Real.sin_add, hcos]
    field_simp
    ring
  refine ⟨?_, ?_, heig, ?_, ?_⟩
  · simp [wave]
  · simp only [wave, waveAngle]
    have : (((n : ℤ) + 1 : ℤ) : ℝ) * ((k : ℝ) * π * (1 / ((n : ℝ) + 1))) = (k : ℝ) * π := by
      push_cast
      field_simp
    rw [this, Real.sin_nat_mul_pi]
  · intro j
    simp only [jacobiSweep]
    rw [heig j]
    field_simp
    ring
  · intro hω h1 h2
    subst hω
    have hn' : (0 : ℝ) < (n : ℝ) + 1 := by positivity
    have hk1 : ((n : ℝ) + 1) ≤ 2 * (k : ℝ) := by exact_mod_cast h1
    have hk2 : (k : ℝ) ≤ (n : ℝ) := by exact_mod_cast h2
    have hθe : θ = (k : ℝ) * π / ((n : ℝ) + 1) := by
      rw [hθ, waveAngle]; field_simp
    have hlo : π / 2 ≤ θ := by
      rw [hθe, le_div_iff₀ hn']
      nlinarith [Real.pi_pos]
    have hhi : θ ≤ π + π / 2 := by
      rw [hθe, div_le_iff₀ hn']
      nlinarith [Real.pi_pos]
    have hc := Real.cos_nonpos_of_pi_div_two_le_of_le hlo hhi
    have hs1 : Real.sin (θ / 2) ^ 2 ≤ 1 := Real.sin_sq_le_one _
    rw [abs_le]
    constructor <;> nlinarith

/-- **The two-grid factor on the bar is exactly 1/9.** For a pair of waves with
`s = sin² (θ / 2)` and `c = cos² (θ / 2)`, the coarse-grid correction is the matrix
`K` with both rows `(s, c)`, and one weighted-Jacobi sweep with `ω = 2 / 3` is
`S = diag (1 - 2 ω s, 1 - 2 ω c)`. The two-grid cycle `S K S` has trace
`λ = s (1 - 2 ω s) ² + c (1 - 2 ω c) ² = 1 / 9` and determinant `0`, so its eigenvalues are
`0` and `1 / 9`, whatever the angle `θ`, and so whatever the grid. -/
theorem two_grid_factor_eq_one_ninth (θ : ℝ) :
    let s := Real.sin (θ / 2) ^ 2
    let c := Real.cos (θ / 2) ^ 2
    let ω : ℝ := 2 / 3
    let S : Matrix (Fin 2) (Fin 2) ℝ := !![1 - 2 * ω * s, 0; 0, 1 - 2 * ω * c]
    let K : Matrix (Fin 2) (Fin 2) ℝ := !![s, c; s, c]
    (S * K * S).trace = 1 / 9 ∧ (S * K * S).det = 0 := by
  intro s c ω S K
  have hsc : s + c = 1 := Real.sin_sq_add_cos_sq (θ / 2)
  have hc : c = 1 - s := by linarith
  constructor
  · simp only [S, K, ω, Matrix.trace, Matrix.diag, Matrix.mul_apply, Fin.sum_univ_two,
      Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.empty_val', Matrix.cons_val_fin_one]
    rw [hc]
    ring
  · simp only [S, K, Matrix.det_fin_two, Matrix.mul_apply, Fin.sum_univ_two,
      Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.empty_val', Matrix.cons_val_fin_one]
    ring

/-- **A V-cycle costs at most 4/3 of its finest level.** On the plate each coarser level has a
quarter of the points of the one above, so if the finest level costs `W₀ ≥ 0`, a V-cycle over
any number `L` of levels costs `W₀ (1 + 1/4 + 1/16 + ⋯) ≤ (4 / 3) W₀`. -/
theorem v_cycle_work_le_four_thirds (W₀ : ℝ) (hW : 0 ≤ W₀) (L : ℕ) :
    ∑ ℓ ∈ Finset.range L, W₀ * (1 / 4 : ℝ) ^ ℓ ≤ 4 / 3 * W₀ := by
  rw [← Finset.mul_sum, geom_sum_eq (by norm_num : (1 / 4 : ℝ) ≠ 1)]
  have hp : 0 ≤ (1 / 4 : ℝ) ^ L := by positivity
  have : ((1 / 4 : ℝ) ^ L - 1) / (1 / 4 - 1) = 4 / 3 * (1 - (1 / 4 : ℝ) ^ L) := by
    field_simp; ring
  rw [this]
  nlinarith [mul_nonneg hW hp]

/-! The card's exact worked numbers. -/

-- Best weight on the bar: 1 - ω = -(1 - 2 ω) at ω = 2/3.
example : (1 : ℚ) - 2 / 3 = -(1 - 2 * (2 / 3)) := by norm_num
-- Most jagged wave, θ = π, sin² (θ/2) = 1: g = 1 - (4/3) = -1/3, size 1/3.
example : (1 : ℚ) - 2 * (2 / 3) * 1 = -1 / 3 ∧ |(1 : ℚ) - 4 / 3| = 1 / 3 := by norm_num
-- Middle wave, θ = π/2, sin² (θ/2) = 1/2: g = 1 - (4/3)(1/2) = 1/3.
example : |(1 : ℚ) - 4 / 3 * (1 / 2)| = 1 / 3 := by norm_num
-- Two-grid factor at the middle pair, s = c = 1/2: (1/2)(1/3)² + (1/2)(1/3)² = 1/9.
example : (1 / 2 : ℚ) * (1 / 3) ^ 2 + 1 / 2 * (1 / 3) ^ 2 = 1 / 9 := by norm_num
-- Plate, ω = 4/5: both ends of the jagged range have size 3/5.
example : (1 : ℚ) - 4 / 5 * (1 / 2) = 3 / 5 ∧ |(1 : ℚ) - 2 * (4 / 5)| = 3 / 5 := by norm_num
-- Plate, ω = 2/3: the ends are 2/3 and 1/3, so the smoothing factor is 2/3.
example : (1 : ℚ) - 2 / 3 * (1 / 2) = 2 / 3 ∧ |(1 : ℚ) - 2 * (2 / 3)| = 1 / 3 := by norm_num
-- Plate, finest-level flops per unknown: 2(9) + 7 + 11/4 + 8/4 + 1 = 123/4 (30.75).
example : (2 * 9 + 7 + 11 / 4 + 8 / 4 + 1 : ℚ) = 123 / 4 := by norm_num
-- Plate, V-cycle flops per unknown: (4/3)(123/4) = 41.
example : (4 / 3 : ℚ) * (123 / 4) = 41 := by norm_num
-- Plate, FMG with two V-cycles per level: (4/3)(2 × 41 + 3) = 340/3 (113.33).
example : (4 / 3 : ℚ) * (2 * 41 + 3) = 340 / 3 := by norm_num
-- A W-cycle on the plate: 1 + 2/4 + 4/16 + ⋯ = 2, as 1 / (1 - 1/2).
example : (1 : ℚ) / (1 - 1 / 2) = 2 := by norm_num
-- The plate's unknowns: 1,023 by 1,023 = 1,046,529.
example : 1023 * 1023 = 1046529 := by norm_num
-- On the 1,023-point bar the spacing is 1/1024.
example : (1 : ℚ) / (1023 + 1) = 1 / 1024 := by norm_num

#print axioms weighted_jacobi_damps_jagged_waves
#print axioms two_grid_factor_eq_one_ninth
#print axioms v_cycle_work_le_four_thirds
