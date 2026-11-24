-- Godunov's method: for Burgers' equation the update keeps the grid total except for the two end fluxes, Godunov's one-line edge flux is the flux of the exact Riemann solution on the edge, and conservation fixes a jump's speed at the Rankine-Hugoniot value.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-! ### How the card's objects are written here

* `burgersFlux u = u^2/2` is Burgers' flux `f(u)`.
* `godunovFlux uL uR = max (f (max uL 0)) (f (min uR 0))` is the card's one-line edge flux `g`.
* `riemannEdgeValue uL uR` is `u*`, the exact solution of the Riemann problem with `uL` left of
  the edge and `uR` right of it, read on the edge (`x/t = 0`), as in Step 3:
  a shock (`uL > uR`) gives `uL` if its speed `(uL + uR)/2` is positive and `uR` otherwise;
  a fan (`uL ≤ uR`) gives `uL` if `uL ≥ 0`, `uR` if `uR ≤ 0`, and `0` in the transonic case.
* Cell values are `u : ℤ → ℝ`. The cells are `0, …, N - 1`; `u (-1)` and `u N` are the ghost
  cells at the two ends, holding any values.
* `godunovStep Δt h u j` is Godunov's update of cell `j`:
  `u_j - (Δt/h) (F_{j+1/2} - F_{j-1/2})` with `F_{j+1/2} = g (u_j) (u_{j+1})`. -/

/-- Burgers' flux `f(u) = u^2/2`. -/
noncomputable def burgersFlux (u : ℝ) : ℝ := u ^ 2 / 2

/-- Godunov's edge flux for Burgers' equation in one line: `max (f (max uL 0)) (f (min uR 0))`. -/
noncomputable def godunovFlux (uL uR : ℝ) : ℝ :=
  max (burgersFlux (max uL 0)) (burgersFlux (min uR 0))

/-- The exact solution of Burgers' Riemann problem on the edge, `x/t = 0` (Step 3). -/
noncomputable def riemannEdgeValue (uL uR : ℝ) : ℝ :=
  if uR < uL then (if 0 < (uL + uR) / 2 then uL else uR)
  else if 0 ≤ uL then uL else if uR ≤ 0 then uR else 0

/-- One step of Godunov's method for Burgers' equation, at cell `j`. -/
noncomputable def godunovStep (Δt h : ℝ) (u : ℤ → ℝ) (j : ℤ) : ℝ :=
  u j - Δt / h * (godunovFlux (u j) (u (j + 1)) - godunovFlux (u (j - 1)) (u j))

/-- Godunov's method keeps the books: one step changes the total of the `N` cell averages only
by what crosses the two ends of the line. Every inner edge's flux leaves one cell and enters the
next, so it cancels, whatever the cells hold. -/
theorem godunov_step_total_changes_only_through_ends (Δt h : ℝ) (u : ℤ → ℝ) (N : ℕ) :
    ∑ j ∈ range N, godunovStep Δt h u j =
      ∑ j ∈ range N, u j
        - Δt / h * (godunovFlux (u ((N : ℤ) - 1)) (u N) - godunovFlux (u (-1)) (u 0)) := by
  unfold godunovStep
  rw [Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_sub_distrib]
  have h := Finset.sum_range_sub (fun k : ℕ => godunovFlux (u ((k : ℤ) - 1)) (u k)) N
  have h2 : ∑ j ∈ range N, godunovFlux (u (j : ℤ)) (u ((j : ℤ) + 1))
      - ∑ j ∈ range N, godunovFlux (u ((j : ℤ) - 1)) (u j)
      = ∑ k ∈ range N, (godunovFlux (u (((k + 1 : ℕ) : ℤ) - 1)) (u ((k + 1 : ℕ) : ℤ))
          - godunovFlux (u ((k : ℤ) - 1)) (u k)) := by
    rw [← Finset.sum_sub_distrib]
    apply Finset.sum_congr rfl
    intro k _
    push_cast
    ring_nf
  rw [h2, h]
  simp

/-- Godunov's flux for Burgers' equation: the one-line formula
`max (f (max uL 0)) (f (min uR 0))` equals `f(u*)`, the flux of the exact Riemann solution on
the edge, for every pair of states `uL`, `uR`, shocks, fans and transonic fans alike. -/
theorem godunov_flux_eq_exact_riemann_flux (uL uR : ℝ) :
    godunovFlux uL uR = burgersFlux (riemannEdgeValue uL uR) := by
  unfold godunovFlux riemannEdgeValue burgersFlux
  split_ifs with h1 h2 h3 h4
  · rw [max_eq_left (by linarith : (0:ℝ) ≤ uL)]
    rcases le_total uR 0 with h5 | h5
    · rw [min_eq_left h5]
      apply max_eq_left
      nlinarith
    · rw [min_eq_right h5]
      apply max_eq_left
      nlinarith
  · rw [min_eq_left (by linarith : uR ≤ 0)]
    rcases le_total uL 0 with h5 | h5
    · rw [max_eq_right h5]
      apply max_eq_right
      nlinarith
    · rw [max_eq_left h5]
      apply max_eq_right
      nlinarith
  · rw [max_eq_left h3, min_eq_right (by linarith : (0:ℝ) ≤ uR)]
    apply max_eq_left
    nlinarith
  · rw [max_eq_right (by linarith : uL ≤ 0), min_eq_left h4]
    apply max_eq_right
    nlinarith
  · rw [max_eq_right (by linarith : uL ≤ 0), min_eq_right (by linarith : (0:ℝ) ≤ uR)]
    norm_num

/-- Rankine–Hugoniot (Step 2): a jump at `X(t)` from `uL` to `uR` (`uL ≠ uR`) moving at speed
`s = X'(t)`, inside a stretch `[A, B]` whose total `(X - A) uL + (B - X) uR` changes at the rate
flux in minus flux out, `f(uL) - f(uR)`, must move at `s = (f(uL) - f(uR)) / (uL - uR)`;
for Burgers' flux that is `(uL + uR)/2`. -/
theorem rankine_hugoniot_shock_speed (f : ℝ → ℝ) (uL uR A B s t : ℝ) (X : ℝ → ℝ)
    (hjump : uL ≠ uR) (hX : HasDerivAt X s t)
    (hbooks : HasDerivAt (fun τ => (X τ - A) * uL + (B - X τ) * uR) (f uL - f uR) t) :
    s = (f uL - f uR) / (uL - uR) ∧
      (f = burgersFlux → s = (uL + uR) / 2) := by
  have hd : HasDerivAt (fun τ => (X τ - A) * uL + (B - X τ) * uR) (s * uL - s * uR) t := by
    have h1 := ((hX.sub_const A).mul_const uL).add ((hX.const_sub B).mul_const uR)
    convert h1 using 1
    ring
  have heq : f uL - f uR = s * uL - s * uR := hbooks.unique hd
  have hne : uL - uR ≠ 0 := sub_ne_zero.mpr hjump
  have hs : s = (f uL - f uR) / (uL - uR) := by
    rw [heq, eq_div_iff hne]
    ring
  refine ⟨hs, ?_⟩
  intro hf
  rw [hs, hf, div_eq_iff hne]
  unfold burgersFlux
  ring

-- The card's shock: speed (f(1) - f(0))/(1 - 0) = 1/2, so at t = 1/2 the jump sits at
-- 3/10 + 1/2 × 1/2 = 11/20.
example : (burgersFlux 1 - burgersFlux 0) / (1 - 0) = 1 / 2 := by norm_num [burgersFlux]
example : (3 / 10 : ℚ) + 1 / 2 * (1 / 2) = 11 / 20 := by norm_num

-- The grid total: 3/10 + 100 × (1/200) × (1/2) = 11/20.
example : (3 / 10 : ℚ) + 100 * (1 / 200) * (1 / 2) = 11 / 20 := by norm_num

-- By hand, step 1 in the cell from 0.30 to 0.31 (ν = 1/2): left edge 1 | 0, right edge 0 | 0.
example : godunovFlux 1 0 = 1 / 2 := by norm_num [godunovFlux, burgersFlux]
example : godunovFlux 0 0 = 0 := by norm_num [godunovFlux, burgersFlux]
example : (0 : ℝ) - 1 / 2 * (godunovFlux 0 0 - godunovFlux 1 0) = 1 / 4 := by
  norm_num [godunovFlux, burgersFlux]

-- Step 2: right edge 1/4 | 0 carries f(1/4) = 1/32, left edge 1 | 1/4 carries 1/2;
-- the cell becomes 1/4 - 1/2 × (1/32 - 1/2) = 31/64 (0.484375).
example : godunovFlux (1 / 4) 0 = 1 / 32 := by norm_num [godunovFlux, burgersFlux]
example : godunovFlux 1 (1 / 4) = 1 / 2 := by norm_num [godunovFlux, burgersFlux]
example : (1 / 4 : ℝ) - 1 / 2 * (godunovFlux (1 / 4) 0 - godunovFlux 1 (1 / 4)) = 31 / 64 := by
  norm_num [godunovFlux, burgersFlux]

-- The transonic fan from -1 to +1: the edge value is 0, so the edge carries no flux.
example : godunovFlux (-1) 1 = 0 := by norm_num [godunovFlux, burgersFlux]

-- The non-conservative step in the first empty cell: 0 - ν × 0 × (0 - 1) = 0, nothing moves.
example (ν : ℝ) : (0 : ℝ) - ν * 0 * (0 - 1) = 0 := by ring

-- Conserving u^2 with flux (2/3)u^3: a jump from 1 to 0 moves at (2/3 - 0)/(1 - 0) = 2/3,
-- landing at 3/10 + 2/3 × 1/2 = 19/30 (0.6333).
example : ((2 / 3 : ℚ) * 1 ^ 3 - 2 / 3 * 0 ^ 3) / (1 ^ 2 - 0 ^ 2) = 2 / 3 := by norm_num
example : (3 / 10 : ℚ) + 2 / 3 * (1 / 2) = 19 / 30 := by norm_num

-- Roe with no fix on the -1 / +1 jump at t = 1/4: two triangles of base 1/4 and height 1.
example : (2 : ℚ) * (1 / 2 * (1 / 4) * 1) = 1 / 4 := by norm_num

#print axioms godunov_step_total_changes_only_through_ends
#print axioms godunov_flux_eq_exact_riemann_flux
#print axioms rankine_hugoniot_shock_speed
