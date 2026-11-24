-- Computing e^A: squaring s times turns the exponential of A/2^s plus a backward error into the exponential of A plus 2^s times that error, so the relative backward error is unchanged; the degree-6 Pade ratio misses e^x first at x^13 with constant (6!)^2/(12! 13!); and a 2 by 2 matrix with distinct eigenvalues has e^A on the Lagrange line through its eigenvalues.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.RingTheory.PowerSeries.Exp
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Nat.Factorial.Basic

open scoped Matrix Matrix.Norms.Operator Nat

theorem iterate_sq_exp {n : Type*} [Fintype n] [DecidableEq n] (Y : Matrix n n ℝ) (s : ℕ) :
    (fun M : Matrix n n ℝ => M * M)^[s] (NormedSpace.exp Y) =
      NormedSpace.exp ((2 : ℝ) ^ s • Y) := by
  induction s with
  | zero => simp
  | succ k ih =>
    rw [Function.iterate_succ_apply', ih, ← Matrix.exp_add_of_commute _ _ (Commute.refl _),
      ← add_smul, pow_succ]
    congr 2; ring

#print axioms iterate_sq_exp

/-- Scaling and squaring keeps the relative backward error.
Let `X = A / 2^s`. If the Padé step returns the exact exponential of a slightly wrong
matrix, `R = e^(X + ΔX)`, then squaring `R` `s` times returns the exact exponential
`e^(A + ΔA)` with `ΔA = 2^s ΔX`, and the relative size of the wrong part is the same at `A`
as at `X`: `‖ΔA‖₁ / ‖A‖₁ = ‖ΔX‖₁ / ‖X‖₁`. Here `‖M‖₁`, the largest column total of the
entries' sizes, is written `‖Mᵀ‖` in Mathlib's L∞ operator norm (largest row total). -/
theorem squaring_keeps_relative_backward_error {n : Type*} [Fintype n] [DecidableEq n]
    (A ΔX R : Matrix n n ℝ) (s : ℕ)
    (hR : R = NormedSpace.exp (((2 : ℝ) ^ s)⁻¹ • A + ΔX)) :
    (fun M : Matrix n n ℝ => M * M)^[s] R = NormedSpace.exp (A + (2 : ℝ) ^ s • ΔX) ∧
      ‖((2 : ℝ) ^ s • ΔX)ᵀ‖ / ‖Aᵀ‖ = ‖ΔXᵀ‖ / ‖(((2 : ℝ) ^ s)⁻¹ • A)ᵀ‖ := by
  have hc : (2 : ℝ) ^ s ≠ 0 := pow_ne_zero _ two_ne_zero
  refine ⟨?_, ?_⟩
  · rw [hR, iterate_sq_exp, smul_add, smul_smul, mul_inv_cancel₀ hc, one_smul]
  · rw [Matrix.transpose_smul, Matrix.transpose_smul, norm_smul, norm_smul, norm_inv,
      Real.norm_eq_abs, abs_of_pos (by positivity : (0 : ℝ) < 2 ^ s)]
    rcases eq_or_ne ‖Aᵀ‖ 0 with h | h
    · simp [h]
    · field_simp

/-- The degree-6 Padé coefficients of the exponential,
`c_k = (12 - k)! 6! / (12! k! (6 - k)!)` for `k = 0, …, 6`, and `0` beyond. -/
def padeCoeff (k : ℕ) : ℚ :=
  if k ≤ 6 then ((12 - k)! * 6! : ℚ) / (12! * k ! * (6 - k)!) else 0

/-- The Padé [6/6] ratio `r(x) = p(x) / p(-x)` matches `e^x` through `x^12`, and its first
miss is `c x^13` with `c = (6!)^2 / (12! 13!)`: the power series `p(-x) e^x - p(x)` has no
terms below `x^13`, and its `x^13` term is exactly `c`. -/
theorem pade_six_six_error_starts_at_x13 :
    let p : PowerSeries ℚ := PowerSeries.mk padeCoeff
    let q : PowerSeries ℚ := PowerSeries.mk fun k => (-1) ^ k * padeCoeff k
    (∀ k < 13, PowerSeries.coeff k (q * PowerSeries.exp ℚ - p) = 0) ∧
      PowerSeries.coeff 13 (q * PowerSeries.exp ℚ - p) = (6! ^ 2 : ℚ) / (12! * 13!) := by
  intro p q
  have key : ∀ k, PowerSeries.coeff k (q * PowerSeries.exp ℚ - p) =
      (∑ i ∈ Finset.range (k + 1), (-1) ^ i * padeCoeff i * (1 / ((k - i)! : ℚ))) - padeCoeff k := by
    intro k
    simp only [map_sub, PowerSeries.coeff_mul, q, p, PowerSeries.coeff_mk, PowerSeries.coeff_exp,
      Algebra.algebraMap_self, RingHom.id_apply]
    rw [Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk]
  refine ⟨?_, ?_⟩
  · intro k hk
    rw [key]
    interval_cases k <;> simp [Finset.sum_range_succ, padeCoeff, Nat.factorial] <;> norm_num
  · rw [key]
    simp [Finset.sum_range_succ, padeCoeff, Nat.factorial]
    norm_num

/-- For a 2 by 2 matrix with two distinct eigenvalues `λ₁ ≠ λ₂` (so its trace is `λ₁ + λ₂`
and its determinant `λ₁ λ₂`), `e^A` is the straight line through `(λ₁, e^λ₁)` and
`(λ₂, e^λ₂)` evaluated at `A`:
`e^A = (e^λ₁ (A - λ₂ I) - e^λ₂ (A - λ₁ I)) / (λ₁ - λ₂)`. -/
theorem exp_two_by_two_eq_lagrange_line (A : Matrix (Fin 2) (Fin 2) ℝ) (l₁ l₂ : ℝ)
    (hne : l₁ ≠ l₂) (htr : A.trace = l₁ + l₂) (hdet : A.det = l₁ * l₂) :
    NormedSpace.exp A =
      (l₁ - l₂)⁻¹ • (Real.exp l₁ • (A - l₂ • (1 : Matrix (Fin 2) (Fin 2) ℝ)) -
        Real.exp l₂ • (A - l₁ • (1 : Matrix (Fin 2) (Fin 2) ℝ))) := by
  set d := l₁ - l₂ with hd
  have hd0 : d ≠ 0 := sub_ne_zero.mpr hne
  have hsq : A * A = (l₁ + l₂) • A - (l₁ * l₂) • (1 : Matrix (Fin 2) (Fin 2) ℝ) := by
    rw [← htr, ← hdet]
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.trace_fin_two, Matrix.det_fin_two] <;> ring
  set P₁ := d⁻¹ • (A - l₂ • (1 : Matrix (Fin 2) (Fin 2) ℝ)) with hP₁
  set P₂ := -(d⁻¹ • (A - l₁ • (1 : Matrix (Fin 2) (Fin 2) ℝ))) with hP₂
  have h1 : A * P₁ = l₁ • P₁ := by
    rw [hP₁, Matrix.mul_smul, mul_sub, hsq, Matrix.mul_smul, mul_one]
    module
  have h2 : A * P₂ = l₂ • P₂ := by
    rw [hP₂, mul_neg, Matrix.mul_smul, mul_sub, hsq, Matrix.mul_smul, mul_one]
    module
  clear_value P₁ P₂
  have hpow : ∀ k : ℕ, A ^ k = l₁ ^ k • P₁ + l₂ ^ k • P₂ := by
    intro k
    induction k with
    | zero =>
      simp only [pow_zero, one_smul, hP₁, hP₂, ← sub_eq_add_neg, ← smul_sub]
      have : (A - l₂ • (1 : Matrix (Fin 2) (Fin 2) ℝ)) - (A - l₁ • 1) = d • 1 := by
        rw [hd]; module
      rw [this, smul_smul, inv_mul_cancel₀ hd0, one_smul]
    | succ k ih =>
      rw [pow_succ', ih, mul_add, Matrix.mul_smul, Matrix.mul_smul, h1, h2, smul_smul, smul_smul,
        pow_succ, pow_succ]
  have hs : ∀ x : ℝ, Summable (fun n : ℕ => ((n !)⁻¹ : ℝ) * x ^ n) := by
    intro x
    simpa [div_eq_inv_mul] using Real.summable_pow_div_factorial x
  have hR : ∀ x : ℝ, Real.exp x = ∑' n : ℕ, ((n !)⁻¹ : ℝ) * x ^ n := by
    intro x
    rw [Real.exp_eq_exp_ℝ, congrFun (NormedSpace.exp_eq_tsum ℝ) x]
    simp [smul_eq_mul]
  rw [congrFun (NormedSpace.exp_eq_tsum ℝ) A]
  simp only [hpow, smul_add, smul_smul]
  rw [Summable.tsum_add ((hs l₁).smul_const P₁) ((hs l₂).smul_const P₂),
    (hs l₁).tsum_smul_const, (hs l₂).tsum_smul_const, ← hR, ← hR, hP₁, hP₂]
  module

/-! Worked numbers for Moler and Van Loan's `A = [[-49, 24], [-64, 31]]`. -/

-- trace −49 + 31 = −18 and determinant (−49)(31) − (24)(−64) = 17
example : Matrix.trace !![(-49 : ℤ), 24; -64, 31] = -18 ∧
    Matrix.det !![(-49 : ℤ), 24; -64, 31] = 17 := by
  constructor
  · simp [Matrix.trace_fin_two]
  · simp [Matrix.det_fin_two]

-- the eigenvalues are −1 and −17: (A + I)(A + 17 I) = 0
example : (!![(-49 : ℤ), 24; -64, 31] + 1) * (!![(-49 : ℤ), 24; -64, 31] + 17) = 0 := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.ofNat_apply]

-- size of A: column totals 49 + 64 = 113 and 24 + 31 = 55, so ‖A‖₁ = 113
example : ‖(!![(-49 : ℝ), 24; -64, 31])ᵀ‖ = 113 := by
  rw [Matrix.linfty_opNorm_def]
  have h : (Finset.univ : Finset (Fin 2)) = {0, 1} := by decide
  rw [h, Finset.sup_insert, Finset.sup_singleton]
  simp
  norm_num

-- the Padé coefficients c_0, …, c_6 = 1, 1/2, 5/44, 1/66, 1/792, 1/15840, 1/665280
example : padeCoeff 0 = 1 ∧ padeCoeff 1 = 1 / 2 ∧ padeCoeff 2 = 5 / 44 ∧
    padeCoeff 3 = 1 / 66 ∧ padeCoeff 4 = 1 / 792 ∧ padeCoeff 5 = 1 / 15840 ∧
    padeCoeff 6 = 1 / 665280 := by
  simp [padeCoeff, Nat.factorial]
  norm_num

-- top-left of e^A from the Lagrange line: −2 e^(−1) + 3 e^(−17)
example : NormedSpace.exp !![(-49 : ℝ), 24; -64, 31] 0 0 =
    -2 * Real.exp (-1) + 3 * Real.exp (-17) := by
  rw [exp_two_by_two_eq_lagrange_line _ (-1) (-17) (by norm_num)
    (by simp [Matrix.trace_fin_two]; norm_num) (by simp [Matrix.det_fin_two]; norm_num)]
  simp
  ring

#print axioms squaring_keeps_relative_backward_error
#print axioms pade_six_six_error_starts_at_x13
#print axioms exp_two_by_two_eq_lagrange_line
