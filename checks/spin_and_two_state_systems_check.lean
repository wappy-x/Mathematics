-- Spin one-half: an atom prepared up along z lands up along a magnet tilted by α with chance cos²(α/2) and down with chance sin²(α/2), every axis matrix n·σ squares to I so its only readings are +1 and −1, and a steady field turns the state by U = cos(ωt/2) I − i sin(ωt/2) n·σ.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Series
import Mathlib.Tactic

open Matrix Real

/-! A spin state is a column of two complex numbers, `Fin 2 → ℂ`. The overlap `⟨u|v⟩` is
`star u ⬝ᵥ v`: conjugate the first column's entries, multiply entry by entry, add. A chance is
the squared size of an overlap, `Complex.normSq`. The three Pauli matrices are written out below,
and the matrix of the magnet along the axis `n = (n_x, n_y, n_z)` is `n_x σ_x + n_y σ_y + n_z σ_z`.
The turning matrix `U(t) = e^(−i ω t σ_n / 2)` is Mathlib's matrix exponential `NormedSpace.exp`. -/

/-- The Pauli matrix `σ_x = [[0, 1], [1, 0]]`. -/
def σx : Matrix (Fin 2) (Fin 2) ℂ := !![0, 1; 1, 0]
/-- The Pauli matrix `σ_y = [[0, −i], [i, 0]]`. -/
def σy : Matrix (Fin 2) (Fin 2) ℂ := !![0, -Complex.I; Complex.I, 0]
/-- The Pauli matrix `σ_z = [[1, 0], [0, −1]]`. -/
def σz : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, -1]

/-- The magnet's matrix for the axis `n = (n_x, n_y, n_z)`: `σ_n = n_x σ_x + n_y σ_y + n_z σ_z`. -/
def σn (nx ny nz : ℝ) : Matrix (Fin 2) (Fin 2) ℂ :=
  (nx : ℂ) • σx + (ny : ℂ) • σy + (nz : ℂ) • σz

/-- **The half-angle rule.** Take the magnet tilted by any angle `α` from z towards x, axis
`n = (sin α, 0, cos α)`. Let `u` be a unit column that the magnet's matrix keeps as itself (an
"up along n" eigenvector, reading +1) and `w` a unit column that it flips (a "down along n"
eigenvector, reading −1). Then an atom prepared up along z, the column `(1, 0)`, lands up with
chance `|⟨n₊|ψ⟩|² = cos²(α/2)` and down with chance `|⟨n₋|ψ⟩|² = sin²(α/2)`, whichever unit
eigenvectors are chosen. -/
theorem up_chance_is_cos_sq_half_angle (α : ℝ) (u w : Fin 2 → ℂ)
    (hu : σn (Real.sin α) 0 (Real.cos α) *ᵥ u = u) (hu1 : star u ⬝ᵥ u = 1)
    (hw : σn (Real.sin α) 0 (Real.cos α) *ᵥ w = -w) (hw1 : star w ⬝ᵥ w = 1) :
    Complex.normSq (star u ⬝ᵥ ![1, 0]) = Real.cos (α / 2) ^ 2 ∧
      Complex.normSq (star w ⬝ᵥ ![1, 0]) = Real.sin (α / 2) ^ 2 := by
  have hcr : Real.cos α = 2 * Real.cos (α / 2) ^ 2 - 1 := by
    rw [← Real.cos_two_mul]; ring_nf
  have hsr : Real.sin α = 2 * Real.sin (α / 2) * Real.cos (α / 2) := by
    rw [← Real.sin_two_mul]; ring_nf
  have hc : Complex.cos (α : ℂ) = 2 * ((Real.cos (α / 2) : ℝ) : ℂ) ^ 2 - 1 := by
    rw [← Complex.ofReal_cos, hcr]; push_cast; ring
  have hs : Complex.sin (α : ℂ) =
      2 * ((Real.sin (α / 2) : ℝ) : ℂ) * ((Real.cos (α / 2) : ℝ) : ℂ) := by
    rw [← Complex.ofReal_sin, hsr]; push_cast; ring
  have hscr : Real.sin (α / 2) ^ 2 + Real.cos (α / 2) ^ 2 = 1 := Real.sin_sq_add_cos_sq _
  have hsc : ((Real.sin (α / 2) : ℝ) : ℂ) ^ 2 + ((Real.cos (α / 2) : ℝ) : ℂ) ^ 2 = 1 := by
    exact_mod_cast hscr
  have hu0 := congrFun hu 0
  have hu1' := congrFun hu 1
  have hw0 := congrFun hw 0
  have hw1' := congrFun hw 1
  simp [σn, σx, σy, σz, mulVec, dotProduct, Fin.sum_univ_two] at hu0 hu1' hw0 hw1' hu1 hw1
  simp only [dotProduct, Fin.sum_univ_two, Pi.star_apply, Matrix.cons_val_zero,
    Matrix.cons_val_one, mul_one, mul_zero, add_zero, Complex.star_def, Complex.normSq_conj]
  rw [hc, hs] at hu0 hu1' hw0 hw1'
  set C : ℝ := Real.cos (α / 2) with hC
  set S : ℝ := Real.sin (α / 2) with hS
  -- norm-squared form of the unit conditions
  have nu : Complex.normSq (u 0) + Complex.normSq (u 1) = 1 := by
    have : ((Complex.normSq (u 0) + Complex.normSq (u 1) : ℝ) : ℂ) = 1 := by
      push_cast
      rw [← Complex.mul_conj, ← Complex.mul_conj, mul_comm (u 0), mul_comm (u 1)]
      exact hu1
    exact_mod_cast this
  have nw : Complex.normSq (w 0) + Complex.normSq (w 1) = 1 := by
    have : ((Complex.normSq (w 0) + Complex.normSq (w 1) : ℝ) : ℂ) = 1 := by
      push_cast
      rw [← Complex.mul_conj, ← Complex.mul_conj, mul_comm (w 0), mul_comm (w 1)]
      exact hw1
    exact_mod_cast this
  constructor
  · set k : ℂ := (C : ℂ) * u 0 + (S : ℂ) * u 1 with hk
    have ha : u 0 = (C : ℂ) * k := by rw [hk]; linear_combination (-1/2 : ℂ) * hu0
    have hb : u 1 = (S : ℂ) * k := by rw [hk]; linear_combination (-1/2 : ℂ) * hu1' - u 1 * hsc
    rw [ha, hb, Complex.normSq_mul, Complex.normSq_mul, Complex.normSq_ofReal,
      Complex.normSq_ofReal] at nu
    rw [ha, Complex.normSq_mul, Complex.normSq_ofReal]
    have hk1 : Complex.normSq k = 1 := by nlinarith
    rw [hk1]; ring
  · set k : ℂ := (S : ℂ) * w 0 - (C : ℂ) * w 1 with hk
    have ha : w 0 = (S : ℂ) * k := by rw [hk]; linear_combination (1/2 : ℂ) * hw0 - w 0 * hsc
    have hb : w 1 = -(C : ℂ) * k := by rw [hk]; linear_combination (1/2 : ℂ) * hw1'
    rw [ha, hb, Complex.normSq_mul, Complex.normSq_mul, Complex.normSq_ofReal,
      Complex.normSq_neg, Complex.normSq_ofReal] at nw
    rw [ha, Complex.normSq_mul, Complex.normSq_ofReal]
    have hk1 : Complex.normSq k = 1 := by nlinarith
    rw [hk1]; ring

/-- **Every axis gives exactly two spots** (Step 3). For every unit arrow `n`
(`n_x² + n_y² + n_z² = 1`) the magnet's matrix squares to the identity, `σ_n² = I`, so the only
possible readings (eigenvalues with a nonzero eigenvector) are `+1` and `−1`. -/
theorem axis_matrix_squares_to_one (nx ny nz : ℝ) (hn : nx ^ 2 + ny ^ 2 + nz ^ 2 = 1) :
    σn nx ny nz * σn nx ny nz = 1 ∧
      ∀ (μ : ℂ) (v : Fin 2 → ℂ), v ≠ 0 → σn nx ny nz *ᵥ v = μ • v → μ = 1 ∨ μ = -1 := by
  have hn' : (nx : ℂ) ^ 2 + (ny : ℂ) ^ 2 + (nz : ℂ) ^ 2 = 1 := by exact_mod_cast hn
  have hsq : σn nx ny nz * σn nx ny nz = 1 := by
    ext i j; fin_cases i <;> fin_cases j <;>
      simp [σn, σx, σy, σz, Matrix.mul_apply, Fin.sum_univ_two] <;>
      first | ring1 | linear_combination hn' - (ny : ℂ) ^ 2 * Complex.I_sq
  refine ⟨hsq, fun μ v hv hμ => ?_⟩
  have h2 : v = μ ^ 2 • v := by
    have := congrArg (fun A => A *ᵥ v) hsq
    simp only [one_mulVec, ← mulVec_mulVec, hμ, mulVec_smul, smul_smul] at this
    rw [sq]; exact this.symm
  have h3 : (μ ^ 2 - 1) • v = 0 := by rw [sub_smul, ← h2, one_smul, sub_self]
  rcases smul_eq_zero.mp h3 with h | h
  · exact sq_eq_one_iff.mp (sub_eq_zero.mp h)
  · exact absurd h hv

/-- **The turning matrix collapses to two terms** (Step 4). For every unit arrow `n`, every rate
`ω` and every time `t`, the matrix exponential `U(t) = e^(−i ω t σ_n / 2)` equals
`cos(ωt/2) I − i sin(ωt/2) σ_n`. -/
theorem turning_matrix_closed_form (nx ny nz ω t : ℝ) (hn : nx ^ 2 + ny ^ 2 + nz ^ 2 = 1) :
    NormedSpace.exp ((-Complex.I * ((ω * t / 2 : ℝ) : ℂ)) • σn nx ny nz) =
      ((Real.cos (ω * t / 2) : ℝ) : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ) -
        (Complex.I * ((Real.sin (ω * t / 2) : ℝ) : ℂ)) • σn nx ny nz := by
  have hA2 : σn nx ny nz ^ 2 = 1 := by
    rw [sq]; exact (axis_matrix_squares_to_one nx ny nz hn).1
  set θ : ℝ := ω * t / 2
  set A := σn nx ny nz
  set z : ℂ := -Complex.I * (θ : ℂ) with hzdef
  have hz : z ^ 2 = -(θ : ℂ) ^ 2 := by
    rw [hzdef]; linear_combination (θ : ℂ) ^ 2 * Complex.I_sq
  rw [NormedSpace.exp_eq_tsum ℂ]
  refine HasSum.tsum_eq ?_
  have hcos := (Complex.hasSum_cos (θ : ℂ)).smul_const (1 : Matrix (Fin 2) (Fin 2) ℂ)
  have hsin := ((Complex.hasSum_sin (θ : ℂ)).mul_left (-Complex.I)).smul_const A
  rw [Complex.ofReal_cos, Complex.ofReal_sin, sub_eq_add_neg, ← neg_smul,
    show -(Complex.I * Complex.sin (θ : ℂ)) = -Complex.I * Complex.sin (θ : ℂ) by ring]
  refine HasSum.even_add_odd ?_ ?_
  · convert hcos using 1
    funext n
    rw [smul_pow, pow_mul A, hA2, one_pow, smul_smul]
    congr 1
    rw [pow_mul z, hz, neg_pow, pow_mul (θ : ℂ)]
    ring
  · convert hsin using 1
    funext n
    rw [smul_pow, pow_succ A, pow_mul A, hA2, one_pow, one_mul, smul_smul]
    congr 1
    rw [pow_succ z, pow_mul z, hz, neg_pow, ← pow_mul, hzdef]
    ring

/-! The card's exact checks. -/

-- σ_x σ_y = i σ_z.
example : σx * σy = Complex.I • σz := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [σx, σy, σz, Matrix.mul_apply, Fin.sum_univ_two]
-- Each Pauli matrix squares to I.
example : σx * σx = 1 ∧ σy * σy = 1 ∧ σz * σz = 1 := by
  refine ⟨?_, ?_, ?_⟩ <;> ext i j <;> fin_cases i <;> fin_cases j <;>
    simp [σx, σy, σz, Matrix.mul_apply, Fin.sum_univ_two]
-- Two different Pauli matrices anticommute: σ_x σ_y = −σ_y σ_x.
example : σx * σy = -(σy * σx) := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [σx, σy, Matrix.mul_apply, Fin.sum_univ_two]
-- The tilted magnet's matrix is [[cos α, sin α], [sin α, −cos α]].
example (α : ℝ) : σn (Real.sin α) 0 (Real.cos α) =
    !![(Real.cos α : ℂ), Real.sin α; Real.sin α, -(Real.cos α : ℂ)] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [σn, σx, σy, σz]
-- Tilt 60°: cos² 30° = 3/4; of 10000 atoms, 7500 up and 2500 down.
example : Real.cos (π / 3 / 2) ^ 2 = 3 / 4 := by
  rw [show π / 3 / 2 = π / 6 by ring, Real.cos_pi_div_six, div_pow, Real.sq_sqrt (by norm_num)]
  norm_num
example : (10000 : ℚ) * (3 / 4) = 7500 ∧ (10000 : ℚ) * (1 - 3 / 4) = 2500 := by norm_num
-- Tilts of 90°, 120° and 180°: up chances 1/2, 1/4 and 0.
example : Real.cos (π / 2 / 2) ^ 2 = 1 / 2 := by
  rw [show π / 2 / 2 = π / 4 by ring, Real.cos_pi_div_four, div_pow, Real.sq_sqrt (by norm_num)]
  norm_num
example : Real.cos (2 * π / 3 / 2) ^ 2 = 1 / 4 := by
  rw [show 2 * π / 3 / 2 = π / 3 by ring, Real.cos_pi_div_three]; norm_num
example : Real.cos (π / 2) ^ 2 = 0 := by simp
-- The wrong full angle: cos² 60° = 1/4, not 3/4.
example : Real.cos (π / 3) ^ 2 = 1 / 4 := by rw [Real.cos_pi_div_three]; norm_num
-- z, then x (keep +x), then z again: 10000 → 5000 kept → 2500 up, 2500 down.
example : (10000 : ℚ) * (1 / 2) = 5000 ∧ (5000 : ℚ) * (1 / 2) = 2500 ∧
    (5000 : ℚ) * (1 - 1 / 2) = 2500 := by norm_num
-- After one full turn, ωt = 2π, the closed form gives −I; after two turns, +I.
example (nx ny nz : ℝ) :
    ((Real.cos (2 * π / 2) : ℝ) : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ) -
      (Complex.I * ((Real.sin (2 * π / 2) : ℝ) : ℂ)) • σn nx ny nz = -1 := by
  rw [show 2 * π / 2 = π by ring, Real.cos_pi, Real.sin_pi]; simp
example (nx ny nz : ℝ) :
    ((Real.cos (4 * π / 2) : ℝ) : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ) -
      (Complex.I * ((Real.sin (4 * π / 2) : ℝ) : ℂ)) • σn nx ny nz = 1 := by
  rw [show 4 * π / 2 = 2 * π by ring, Real.cos_two_pi, Real.sin_two_pi]; simp

#print axioms up_chance_is_cos_sq_half_angle
#print axioms axis_matrix_squares_to_one
#print axioms turning_matrix_closed_form
