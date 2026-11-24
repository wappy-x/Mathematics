-- Trace class: in finite dimensions the diagonal sum in any orthonormal basis equals the sum of the eigenvalues counted by algebraic multiplicity, the running total is Hilbert-Schmidt but not trace class, and the eigenvalues of K + V² add to its trace 1/2.
import Mathlib.Analysis.InnerProductSpace.Trace
import Mathlib.LinearAlgebra.Eigenspace.Charpoly
import Mathlib.LinearAlgebra.Matrix.Charpoly.Eigs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Analysis.PSeries
import Mathlib.NumberTheory.ZetaValues
import Mathlib.NumberTheory.ModularForms.EisensteinSeries.QExpansion

open scoped InnerProductSpace
open Complex Real

/-- Lidskii's theorem in finite dimensions (Steps 4 and 6 of the card): for an operator `T`
on a finite-dimensional complex inner product space, the sum of the diagonal entries
`⟨eᵢ, T eᵢ⟩` is the same in every orthonormal basis `e`, and it equals the sum of the
eigenvalues of `T`, each counted as often as its factor repeats in the characteristic
polynomial (its algebraic multiplicity). -/
theorem diagonal_sum_eq_sum_eigenvalues
    {E ι : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [FiniteDimensional ℂ E]
    [Fintype ι] (T : E →ₗ[ℂ] E) (e : OrthonormalBasis ι ℂ E) :
    ∑ i, ⟪e i, T (e i)⟫_ℂ = (LinearMap.charpoly T).roots.sum := by
  rw [← LinearMap.trace_eq_sum_inner T e]
  exact Module.End.trace_eq_sum_roots_charpoly_of_splits (IsAlgClosed.splits _)

/-- The running total `V` has singular values `2/((2n - 1)π)` for `n = 1, 2, …`
(indexed here from `n = 0` as `2/((2n + 1)π)`). Their squares add to `1/2`, so `V` is
Hilbert-Schmidt, but the singular values themselves do not add to a finite number,
so `V` is not trace class. -/
theorem running_total_hilbert_schmidt_not_trace_class :
    HasSum (fun n : ℕ => (2 / ((2 * (n : ℝ) + 1) * π)) ^ 2) (1 / 2) ∧
      ¬ Summable (fun n : ℕ => 2 / ((2 * (n : ℝ) + 1) * π)) := by
  constructor
  · set f : ℕ → ℝ := fun n => 1 / (n : ℝ) ^ 2 with hfdef
    have hf : HasSum f (π ^ 2 / 6) := hasSum_zeta_two
    have hs : Summable (fun n : ℕ => f (2 * n + 1)) :=
      hf.summable.comp_injective (f := f) (i := fun n : ℕ => 2 * n + 1)
        (fun a b h => by simpa using h)
    have he : HasSum (fun n : ℕ => f (2 * n)) (π ^ 2 / 6 / 4) := by
      have := hf.div_const 4
      refine this.congr_fun ?_
      intro n
      simp only [hfdef]
      push_cast
      ring
    have htot := HasSum.even_add_odd he hs.hasSum
    have hval : ∑' n : ℕ, f (2 * n + 1) = π ^ 2 / 8 := by
      have := htot.unique hf
      linarith
    have ho := hs.hasSum
    rw [hval] at ho
    have := ho.mul_left (4 / π ^ 2)
    convert this using 1
    · ext n
      have hp : π ≠ 0 := Real.pi_ne_zero
      have h1 : (2 * (n : ℝ) + 1) ≠ 0 := by positivity
      simp only [hfdef]
      push_cast
      field_simp
      ring
    · field_simp
      ring
  · intro h
    apply Real.not_summable_one_div_natCast
    rw [← summable_nat_add_iff 1]
    have h2 := h.mul_left π
    refine Summable.of_nonneg_of_le (fun n => by positivity) (fun n => ?_) h2
    have hp : 0 < π := Real.pi_pos
    push_cast
    rw [mul_div_assoc', div_le_div_iff₀ (by positivity) (by positivity)]
    nlinarith

/-- Lidskii's theorem checked on `T = K + V²`: its eigenvalues are `1/(L + 2πik)²` for every
integer `k`, with `L = ln(2 + √3)` (so `cosh L = 2`), and they add up to `1/2`, the trace of `T`
read off its kernel's diagonal. -/
theorem eigenvalues_of_k_plus_v_sq_sum_to_half :
    HasSum (fun k : ℤ =>
      1 / (((Real.log (2 + Real.sqrt 3) : ℝ) : ℂ) + 2 * (π : ℂ) * I * (k : ℂ)) ^ 2) (1 / 2) := by
  set L : ℝ := Real.log (2 + Real.sqrt 3) with hL
  have hs3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hs3pos : 0 < Real.sqrt 3 := by positivity
  have hs3gt : 1 < Real.sqrt 3 := by nlinarith
  have hLpos : 0 < L := Real.log_pos (by linarith)
  have hexp : Real.exp (-L) = 2 - Real.sqrt 3 := by
    rw [Real.exp_neg, hL, Real.exp_log (by positivity)]
    field_simp
    nlinarith
  have hpi : (0 : ℝ) < π := Real.pi_pos
  have hpiC : (π : ℂ) ≠ 0 := by exact_mod_cast hpi.ne'
  -- the point w = i L / (2π) in the upper half plane
  have hwim : 0 < (I * (L : ℂ) / (2 * π)).im := by
    have : (I * (L : ℂ) / (2 * π)) = ((L / (2 * π) : ℝ) : ℂ) * I := by
      push_cast; field_simp
    rw [this]
    simp only [mul_im, ofReal_re, I_im, ofReal_im, I_re, mul_zero, mul_one, add_zero]
    positivity
  let w : UpperHalfPlane := ⟨I * (L : ℂ) / (2 * π), hwim⟩
  have hw : (w : ℂ) = I * (L : ℂ) / (2 * π) := rfl
  have hq : cexp (2 * π * I * (w : ℂ)) = ((2 - Real.sqrt 3 : ℝ) : ℂ) := by
    rw [← hexp, ofReal_exp, hw]
    congr 1
    field_simp
    rw [I_sq]
    push_cast; ring
  have hqn : ‖((2 - Real.sqrt 3 : ℝ) : ℂ)‖ < 1 := by
    rw [Complex.norm_real, Real.norm_eq_abs, abs_lt]
    constructor <;> nlinarith
  have hid := EisensteinSeries.qExpansion_identity (k := 1) le_rfl w
  rw [hq] at hid
  simp only [pow_one, Nat.factorial_one, Nat.cast_one, div_one] at hid
  rw [tsum_coe_mul_geometric_of_norm_lt_one hqn] at hid
  -- summability of the Eisenstein-type series
  have hsum : Summable fun n : ℤ => 1 / ((w : ℂ) + n) ^ 2 := by
    have := EisensteinSeries.linear_right_summable (w : ℂ) 1 (k := 2) le_rfl
    refine this.congr fun n => ?_
    simp
  have hh := hsum.hasSum
  rw [hid] at hh
  have hneg := (Equiv.neg ℤ).hasSum_iff.mpr hh
  have hfin := hneg.mul_left (1 / (-4 * (π : ℂ) ^ 2))
  convert hfin using 1
  · ext k
    simp only [Function.comp_apply, Equiv.neg_apply, Int.cast_neg]
    rw [hw]
    have hk : ((L : ℂ) + 2 * π * I * k) = (-2 * π * I) * (I * L / (2 * π) + -(k : ℂ)) := by
      field_simp
      ring_nf
      rw [I_sq]
      ring
    rw [hk, mul_pow]
    have hI : (-2 * (π : ℂ) * I) ^ 2 = -4 * π ^ 2 := by
      ring_nf; rw [I_sq]; ring
    rw [hI]
    by_cases h0 : (I * L / (2 * π) + -(k : ℂ)) = 0
    · simp [h0]
    · field_simp
  · have h1 : (1 : ℂ) - ((2 - Real.sqrt 3 : ℝ) : ℂ) = ((Real.sqrt 3 - 1 : ℝ) : ℂ) := by
      push_cast; ring
    rw [h1]
    have hne : ((Real.sqrt 3 - 1 : ℝ) : ℂ) ≠ 0 := by
      exact_mod_cast (show Real.sqrt 3 - 1 ≠ 0 by linarith)
    have hI : (-2 * (π : ℂ) * I) ^ 2 = -4 * π ^ 2 := by
      ring_nf; rw [I_sq]; ring
    rw [hI]
    have hr : (2 - Real.sqrt 3) / (Real.sqrt 3 - 1) ^ 2 = (1 / 2 : ℝ) := by
      have : (Real.sqrt 3 - 1) ^ 2 ≠ 0 := by positivity
      field_simp
      nlinarith
    have hr' : ((2 - Real.sqrt 3 : ℝ) : ℂ) / ((Real.sqrt 3 - 1 : ℝ) : ℂ) ^ 2 = 1 / 2 := by
      rw [← ofReal_pow, ← ofReal_div, hr]; push_cast; ring
    rw [← hr']
    field_simp

-- The by-hand rehearsal: rows (1, -2) and (1, 3) have trace 4.
example : Matrix.trace !![(1 : ℚ), -2; 1, 3] = 4 := by
  norm_num [Matrix.trace_fin_two]

-- Its characteristic polynomial is z² - 4z + 5, whose roots 2 + i and 2 - i add to 4.
example : (2 + I) ^ 2 - 4 * (2 + I) + 5 = 0 ∧ (2 - I) ^ 2 - 4 * (2 - I) + 5 = 0 ∧
    (2 + I) + (2 - I) = 4 := by
  refine ⟨?_, ?_, ?_⟩ <;> ring_nf <;> norm_num [Complex.ext_iff, pow_two]

-- The Jordan block with rows (1, 1) and (0, 1) has trace 2 (eigenvalue 1, counted twice).
example : Matrix.trace !![(1 : ℚ), 1; 0, 1] = 2 := by
  norm_num [Matrix.trace_fin_two]

-- The meter's grid matrix V_N has N diagonal entries h/2 = 1/(2N), adding to 1/2.
example : (∑ _i : Fin 20, (1 : ℚ) / (2 * 20)) = 1 / 2 := by norm_num
example : (∑ _i : Fin 40, (1 : ℚ) / (2 * 40)) = 1 / 2 := by norm_num
example : (∑ _i : Fin 80, (1 : ℚ) / (2 * 80)) = 1 / 2 := by norm_num

-- The Fredholm-determinant closing step: sinh²(L/2) = (cosh L - 1)/2 = (2 - 1)/2 = 1/2,
-- so the eigenvalue sum 1/(4 sinh²(L/2)) is 1/2.
example : ((2 : ℚ) - 1) / 2 = 1 / 2 ∧ (1 : ℚ) / (4 * (1 / 2)) = 1 / 2 := by norm_num

#print axioms diagonal_sum_eq_sum_eigenvalues
#print axioms running_total_hilbert_schmidt_not_trace_class
#print axioms eigenvalues_of_k_plus_v_sq_sum_to_half
