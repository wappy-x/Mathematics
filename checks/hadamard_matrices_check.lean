-- Hadamard matrices: a square table of plus and minus ones with perpendicular rows has size 1, 2 or a multiple of 4, the Kronecker product with H2 doubles such a table, and no real square table with entries between -1 and 1 has determinant larger than n^(n/2).
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Matrix.PosDef
import Mathlib.Analysis.MeanInequalities
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.Order.Star.Real
import Mathlib.Tactic

namespace HadamardMatrices

open Matrix
open scoped Kronecker

/-- The card's main result, the size rule. Take an `n` by `n` table `H` whose entries are all
`+1` or `-1` and whose rows are perpendicular, so that `H * Hᵀ = n I` (each row dotted with itself
gives `n`, with any other row gives `0`). Then the size `n` is 1, 2 or a multiple of 4. -/
theorem hadamard_size_one_two_or_four_dvd {n : ℕ} (H : Matrix (Fin n) (Fin n) ℤ)
    (hpm : ∀ i j, H i j = 1 ∨ H i j = -1)
    (hH : H * Hᵀ = (n : ℤ) • (1 : Matrix (Fin n) (Fin n) ℤ)) :
    n = 1 ∨ n = 2 ∨ 4 ∣ n := by
  rcases Nat.lt_or_ge n 3 with h | h
  · interval_cases n <;> simp
  right; right
  have e : ∀ i k : Fin n, ∑ j, H i j * H k j = if i = k then (n : ℤ) else 0 := by
    intro i k
    have : ∑ j, H i j * H k j = (H * Hᵀ) i k := by rw [Matrix.mul_apply]; rfl
    rw [this, hH]; split_ifs with hik <;> simp [hik]
  let a : Fin n := ⟨0, by omega⟩
  let b : Fin n := ⟨1, by omega⟩
  let c : Fin n := ⟨2, by omega⟩
  have hab : a ≠ b := by simp [a, b, Fin.ext_iff]
  have hac : a ≠ c := by simp [a, c, Fin.ext_iff]
  have hbc : b ≠ c := by simp [b, c, Fin.ext_iff]
  have key : (n : ℤ) = ∑ j, (H a j + H b j) * (H a j + H c j) := by
    have h1 := e a a
    have h2 := e a c
    have h3 := e b a
    have h4 := e b c
    simp only [↓reduceIte, hac, hab.symm, hbc] at h1 h2 h3 h4
    have : ∑ j, (H a j + H b j) * (H a j + H c j)
        = ∑ j, H a j * H a j + ∑ j, H a j * H c j + ∑ j, H b j * H a j + ∑ j, H b j * H c j := by
      simp only [← Finset.sum_add_distrib]; congr 1; ext j; ring
    rw [this, h1, h2, h3, h4]; ring
  have : (4 : ℤ) ∣ (n : ℤ) := by
    rw [key]
    apply Finset.dvd_sum
    intro j _
    rcases hpm a j with h1 | h1 <;> rcases hpm b j with h2 | h2 <;> rcases hpm c j with h3 | h3 <;>
      simp [h1, h2, h3]
  exact_mod_cast this

/-- Sylvester's doubling. If `H` is an `n` by `n` table of `±1` with `H * Hᵀ = n I`, then the
Kronecker product `H₂ ⊗ H` with `H₂ = [[1, 1], [1, -1]]` (the block table `[[H, H], [H, -H]]`)
is a `2n` by `2n` table of `±1` with perpendicular rows: its product with its transpose is
`2n I`. -/
theorem sylvester_doubling_is_hadamard {n : ℕ} (H : Matrix (Fin n) (Fin n) ℤ)
    (hpm : ∀ i j, H i j = 1 ∨ H i j = -1)
    (hH : H * Hᵀ = (n : ℤ) • (1 : Matrix (Fin n) (Fin n) ℤ)) :
    (∀ i j, (!![1, 1; 1, -1] ⊗ₖ H) i j = 1 ∨ (!![1, 1; 1, -1] ⊗ₖ H) i j = -1) ∧
      (!![1, 1; 1, -1] ⊗ₖ H) * (!![1, 1; 1, -1] ⊗ₖ H)ᵀ =
        ((2 * n : ℕ) : ℤ) • (1 : Matrix (Fin 2 × Fin n) (Fin 2 × Fin n) ℤ) := by
  constructor
  · rintro ⟨a, i⟩ ⟨b, j⟩
    simp only [kroneckerMap_apply]
    rcases hpm i j with h | h <;> fin_cases a <;> fin_cases b <;> simp [h]
  · have h2 : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℤ) * (!![1, 1; 1, -1])ᵀ
        = (2 : ℤ) • (1 : Matrix (Fin 2) (Fin 2) ℤ) := by decide
    rw [← kroneckerMap_transpose, ← mul_kronecker_mul, h2, hH,
      smul_kronecker, kronecker_smul, one_kronecker_one, smul_smul]
    push_cast; ring_nf

/-- Hadamard's bound. Every `n` by `n` table `A` of real numbers whose entries all lie between
`-1` and `1` has determinant at most `n` to the power `n/2` in size: `|det A| ≤ n ^ (n/2)`. -/
theorem abs_det_le_hadamard_bound {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : ∀ i j, |A i j| ≤ 1) :
    |A.det| ≤ (n : ℝ) ^ ((n : ℝ) / 2) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hP : (A * Aᵀ).PosSemidef := by
    simpa [conjTranspose_eq_transpose_of_trivial] using posSemidef_self_mul_conjTranspose A
  have hev : ∀ i, 0 ≤ hP.1.eigenvalues i := hP.eigenvalues_nonneg
  have hdet : A.det ^ 2 = ∏ i, hP.1.eigenvalues i := by
    have := hP.1.det_eq_prod_eigenvalues
    rw [det_mul, det_transpose] at this
    simpa [sq] using this
  have htr : ∑ i, hP.1.eigenvalues i ≤ (n : ℝ) ^ 2 := by
    have := hP.1.trace_eq_sum_eigenvalues
    simp only [RCLike.ofReal_real_eq_id, id] at this
    rw [← this]
    simp only [trace, diag, Matrix.mul_apply, transpose_apply]
    calc ∑ i, ∑ j, A i j * A i j ≤ ∑ i : Fin n, ∑ j : Fin n, (1 : ℝ) := by
          gcongr with i _ j _
          have := hA i j
          nlinarith [abs_mul_abs_self (A i j), abs_nonneg (A i j)]
      _ = (n : ℝ) ^ 2 := by simp; ring
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hamgm : ∏ i, hP.1.eigenvalues i ^ ((1 : ℝ) / n) ≤ ∑ i, ((1 : ℝ) / n) * hP.1.eigenvalues i :=
    Real.geom_mean_le_arith_mean_weighted Finset.univ (fun _ => (1 : ℝ) / n) _
      (fun _ _ => by positivity) (by simp; field_simp) (fun i _ => hev i)
  rw [Real.finsetProd_rpow _ _ (fun i _ => hev i), ← Finset.mul_sum] at hamgm
  have h1 : (A.det ^ 2) ^ ((1 : ℝ) / n) ≤ n := by
    rw [hdet]
    calc _ ≤ _ := hamgm
      _ ≤ 1 / n * (n : ℝ) ^ 2 := by gcongr
      _ = n := by field_simp
  have h2 : |A.det| = ((A.det ^ 2) ^ ((1 : ℝ) / n)) ^ ((n : ℝ) / 2) := by
    rw [← Real.rpow_mul (by positivity)]
    have : (1 : ℝ) / n * (n / 2) = 1 / 2 := by field_simp
    rw [this, ← Real.sqrt_eq_rpow, Real.sqrt_sq_eq_abs]
  rw [h2]
  exact Real.rpow_le_rpow (by positivity) h1 (by positivity)

/-! ### The card's worked examples -/

/-- `H₂ = [[1, 1], [1, -1]]`. -/
def H2 : Matrix (Fin 2) (Fin 2) ℤ := !![1, 1; 1, -1]

/-- `H₄ = H₂ ⊗ H₂`, written out as on the card. -/
def H4 : Matrix (Fin 4) (Fin 4) ℤ :=
  !![1, 1, 1, 1; 1, -1, 1, -1; 1, 1, -1, -1; 1, -1, -1, 1]

-- H4 is the Kronecker product H2 ⊗ H2 (pairs (a, b) listed as row 2a + b).
example : H2 ⊗ₖ H2 = H4.submatrix finProdFinEquiv finProdFinEquiv := by decide

-- H4 H4ᵀ = 4 I.
example : H4 * H4ᵀ = (4 : ℤ) • (1 : Matrix (Fin 4) (Fin 4) ℤ) := by decide

-- det H4 = 16 = 4 ^ (4/2): H4 reaches Hadamard's bound.
example : H4.det = 16 := by
  simp [H4, Matrix.det_succ_row_zero, Fin.sum_univ_succ]; decide

-- The weighing plan: parcels 120, 75, 210, 45 g give readings 450, 210, -60, -120 g,
-- and H4ᵀ y / 4 recovers the parcels.
example : H4 *ᵥ ![120, 75, 210, 45] = ![450, 210, -60, -120] := by decide
example : H4ᵀ *ᵥ ![450, 210, -60, -120] = (4 : ℤ) • ![120, 75, 210, 45] := by decide

-- Rows 2 and 3 of Sylvester's H8 = H2 ⊗ H4: the columns split 2, 2, 2, 2 by sign pattern.
example :
    (Finset.univ.filter fun c : Fin 2 × Fin 4 => (H2 ⊗ₖ H4) (0, 1) c = 1 ∧ (H2 ⊗ₖ H4) (0, 2) c = 1).card = 2 ∧
    (Finset.univ.filter fun c : Fin 2 × Fin 4 => (H2 ⊗ₖ H4) (0, 1) c = 1 ∧ (H2 ⊗ₖ H4) (0, 2) c = -1).card = 2 ∧
    (Finset.univ.filter fun c : Fin 2 × Fin 4 => (H2 ⊗ₖ H4) (0, 1) c = -1 ∧ (H2 ⊗ₖ H4) (0, 2) c = 1).card = 2 ∧
    (Finset.univ.filter fun c : Fin 2 × Fin 4 => (H2 ⊗ₖ H4) (0, 1) c = -1 ∧ (H2 ⊗ₖ H4) (0, 2) c = -1).card = 2 := by
  decide

/-- The 7 by 7 core of Sylvester's `H₈`: its first row and column deleted. -/
def core8 (i j : Fin 7) : ℤ :=
  (H2 ⊗ₖ H4) (finProdFinEquiv.symm (i.succ.cast rfl)) (finProdFinEquiv.symm (j.succ.cast rfl))

-- Each core row has three +1 places, and every two columns share a +1 in exactly one row:
-- the +1 places form a 2-(7, 3, 1) design, the Fano plane.
example : ∀ i : Fin 7, (Finset.univ.filter fun j => core8 i j = 1).card = 3 := by decide
example : ∀ x y : Fin 7, x ≠ y →
    (Finset.univ.filter fun i => core8 i x = 1 ∧ core8 i y = 1).card = 1 := by decide

-- The −1 places give the complement: blocks of 4, each pair together twice, a 2-(7, 4, 2) design.
example : ∀ x y : Fin 7, x ≠ y →
    (Finset.univ.filter fun i => core8 i x = -1 ∧ core8 i y = -1).card = 2 := by decide

/-- Back from the Fano plane: a border of `+1`s, then `+1` on each house line {1, 2, 4},
{2, 3, 5}, {3, 4, 6}, {4, 5, 7}, {5, 6, 1}, {6, 7, 2}, {7, 1, 3} and `-1` off it. -/
def fanoH8 : Matrix (Fin 8) (Fin 8) ℤ :=
  !![1, 1, 1, 1, 1, 1, 1, 1;
     1, 1, 1, -1, 1, -1, -1, -1;
     1, -1, 1, 1, -1, 1, -1, -1;
     1, -1, -1, 1, 1, -1, 1, -1;
     1, -1, -1, -1, 1, 1, -1, 1;
     1, 1, -1, -1, -1, 1, 1, -1;
     1, -1, 1, -1, -1, -1, 1, 1;
     1, 1, -1, 1, -1, -1, -1, 1]

example : fanoH8 * fanoH8ᵀ = (8 : ℤ) • (1 : Matrix (Fin 8) (Fin 8) ℤ) := by decide

-- Dropping the minus: [[H4, H4], [H4, H4]] has two equal rows, so H Hᵀ ≠ 8 I.
example : (!![1, 1; 1, 1] ⊗ₖ H4) * (!![1, 1; 1, 1] ⊗ₖ H4)ᵀ ≠
    (8 : ℤ) • (1 : Matrix (Fin 2 × Fin 4) (Fin 2 × Fin 4) ℤ) := by decide

#print axioms hadamard_size_one_two_or_four_dvd
#print axioms sylvester_doubling_is_hadamard
#print axioms abs_det_le_hadamard_bound

end HadamardMatrices
