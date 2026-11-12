-- Semidefinite programs: this file proves the Schur complement test for a positive definite pivot, the bound that the max-cut relaxation puts on every cut, and that a semidefinite program's allowed matrices form a convex set.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.RowCol
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Analysis.Convex.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Algebra.Order.Star.Real

open Matrix

/-- A one-by-one real matrix is positive semidefinite exactly when its entry is zero or more. -/
theorem posSemidef_unit_iff (M : Matrix Unit Unit ℝ) : M.PosSemidef ↔ 0 ≤ M () () := by
  rw [posSemidef_iff_dotProduct_mulVec]
  constructor
  · rintro ⟨-, h⟩
    simpa [dotProduct, mulVec] using h (fun _ => 1)
  · intro h
    refine ⟨?_, fun x => ?_⟩
    · ext i j; cases i; cases j; simp
    · simp only [dotProduct, mulVec, Finset.univ_unique, Finset.sum_singleton, star_trivial,
        PUnit.default_eq_unit]
      nlinarith [mul_self_nonneg (x ())]

/-- The **Schur complement test**. Take a real number `a`, a column `b` and a positive definite
block `D`. The symmetric matrix with corner `a`, column `b` and block `D` is positive semidefinite
exactly when the Schur complement `a - bᵀ D⁻¹ b` is zero or more. -/
theorem schur_complement_psd_iff {n : Type*} [Fintype n] [DecidableEq n]
    (a : ℝ) (b : n → ℝ) (D : Matrix n n ℝ) (hD : D.PosDef) :
    (fromBlocks (of fun _ _ => a : Matrix Unit Unit ℝ) (replicateRow Unit b)
        (replicateCol Unit b) D).PosSemidef ↔
      0 ≤ a - b ⬝ᵥ (D⁻¹ *ᵥ b) := by
  have : Invertible D := hD.isUnit.invertible
  have hB : (replicateRow Unit b)ᴴ = replicateCol Unit b := by
    rw [conjTranspose_replicateRow]; simp
  rw [← hB, PosDef.fromBlocks₂₂ _ _ hD, posSemidef_unit_iff, hB]
  rw [Matrix.mul_assoc, ← replicateCol_mulVec, replicateRow_mul_replicateCol]
  rfl

/-- The objective of the max-cut relaxation for a network `G` on nodes `0, …, n-1`:
the sum over links `{i, j}` (counted once, with `i < j`) of `(1 - X i j) / 2`. -/
noncomputable def maxCutObjective {n : ℕ} (G : SimpleGraph (Fin n)) [DecidableRel G.Adj]
    (X : Matrix (Fin n) (Fin n) ℝ) : ℝ :=
  ∑ i, ∑ j, if i < j ∧ G.Adj i j then (1 - X i j) / 2 else 0

/-- The number of links of `G` cut by the split that puts the nodes of `S` on one side
and the rest on the other. -/
def cutSize {n : ℕ} (G : SimpleGraph (Fin n)) [DecidableRel G.Adj] (S : Finset (Fin n)) : ℕ :=
  (Finset.univ.filter fun p : Fin n × Fin n =>
    p.1 < p.2 ∧ G.Adj p.1 p.2 ∧ (p.1 ∈ S ↔ p.2 ∉ S)).card

/-- In a positive semidefinite matrix with ones on the diagonal, every entry is at least `-1`. -/
theorem posSemidef_entry_ge_neg_one {n : ℕ} (X : Matrix (Fin n) (Fin n) ℝ) (hX : X.PosSemidef)
    (hd : ∀ i, X i i = 1) (i j : Fin n) : -1 ≤ X i j := by
  have h := (hX.submatrix ![i, j]).dotProduct_mulVec_nonneg ![1, 1]
  simp [dotProduct, mulVec, Fin.sum_univ_two, hd] at h
  have hs : star (X j i) = X i j := hX.1.apply i j
  simp at hs
  linarith

/-- The max-cut objective of such a matrix is at most `n * n`. -/
theorem maxCutObjective_le {n : ℕ} (G : SimpleGraph (Fin n)) [DecidableRel G.Adj]
    (X : Matrix (Fin n) (Fin n) ℝ) (hX : X.PosSemidef) (hd : ∀ i, X i i = 1) :
    maxCutObjective G X ≤ (n : ℝ) * n := by
  have : ∑ _i : Fin n, ∑ _j : Fin n, (1 : ℝ) = (n : ℝ) * n := by simp
  rw [← this, maxCutObjective]
  refine Finset.sum_le_sum fun i _ => Finset.sum_le_sum fun j _ => ?_
  have := posSemidef_entry_ge_neg_one X hX hd i j
  split_ifs <;> linarith

/-- **The max-cut relaxation bounds every cut.** The best value of the relaxation, the largest
`∑ (1 - X i j) / 2` over links among symmetric matrices `X` with ones on the diagonal that are
positive semidefinite, is at least the number of links cut by any split of the network. -/
theorem cutSize_le_maxCut_relaxation {n : ℕ} (G : SimpleGraph (Fin n)) [DecidableRel G.Adj]
    (S : Finset (Fin n)) :
    (cutSize G S : ℝ) ≤
      sSup {v : ℝ | ∃ X : Matrix (Fin n) (Fin n) ℝ,
        X.PosSemidef ∧ (∀ i, X i i = 1) ∧ maxCutObjective G X = v} := by
  apply le_csSup
  · refine ⟨(n : ℝ) * n, ?_⟩
    rintro v ⟨X, hX, hd, rfl⟩
    exact maxCutObjective_le G X hX hd
  · set s : Fin n → ℝ := fun i => if i ∈ S then 1 else -1 with hs
    refine ⟨vecMulVec s s, ?_, ?_, ?_⟩
    · simpa using posSemidef_vecMulVec_self_star s
    · intro i; simp only [vecMulVec_apply, hs]; split_ifs <;> norm_num
    · rw [maxCutObjective, cutSize, Finset.card_filter, Nat.cast_sum, ← Finset.univ_product_univ,
        Finset.sum_product]
      refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
      simp only [vecMulVec_apply, hs]
      by_cases hi : i ∈ S <;> by_cases hj : j ∈ S <;> simp [hi, hj]

/-- **The allowed matrices of a semidefinite program form a convex set.** The symmetric matrices
that obey any family of linear limits `A k X ≤ c k` and are positive semidefinite
(every mix has a variance of zero or more) form a convex set. -/
theorem sdp_feasible_set_convex {n κ : Type*} [Fintype n]
    (A : κ → Matrix n n ℝ →ₗ[ℝ] ℝ) (c : κ → ℝ) :
    Convex ℝ {X : Matrix n n ℝ | X.PosSemidef ∧ ∀ k, A k X ≤ c k} := by
  rintro X ⟨hX, hXc⟩ Y ⟨hY, hYc⟩ s t hs ht hst
  refine ⟨(hX.smul hs).add (hY.smul ht), fun k => ?_⟩
  rw [map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]
  have h1 := mul_le_mul_of_nonneg_left (hXc k) hs
  have h2 := mul_le_mul_of_nonneg_left (hYc k) ht
  calc s * A k X + t * A k Y ≤ s * c k + t * c k := add_le_add h1 h2
    _ = c k := by rw [← add_mul, hst, one_mul]

-- The desk's matrix C, with UK-Europe 9/10, UK-property 1/5, Europe-property 9/10.
-- The long UK, short Europe, long property mix w = (1, -1, 1) has variance -1/5.
example :
    (![1, -1, 1] : Fin 3 → ℝ) ⬝ᵥ
      ((!![1, 9/10, 1/5; 9/10, 1, 9/10; 1/5, 9/10, 1] : Matrix (Fin 3) (Fin 3) ℝ) *ᵥ ![1, -1, 1])
      = -1/5 := by
  simp [dotProduct, mulVec, Fin.sum_univ_three]; norm_num
-- In pounds squared, at 20,000 pounds of risk per asset: -80,000,000.
example : (20000 : ℝ) ^ 2 * (-1/5) = -80000000 := by norm_num
-- Schur complement on Europe: corner 1 - (9/10)^2 = 19/100, off-corner 1/5 - (9/10)^2 = -61/100,
-- determinant -42/125 (the card's -0.336).
example : (1 : ℝ) - (9/10) ^ 2 = 19/100 ∧ (1/5 : ℝ) - (9/10) ^ 2 = -61/100 ∧
    (19/100 : ℝ) * (19/100) - (-61/100) ^ 2 = -42/125 := by norm_num
-- The determinant of C by cofactors is the same -42/125.
example : (!![1, 9/10, 1/5; 9/10, 1, 9/10; 1/5, 9/10, 1] : Matrix (Fin 3) (Fin 3) ℝ).det
    = -42/125 := by
  simp [det_fin_three]; norm_num
-- Least UK-property correlation allowed: 2 (9/10)^2 - 1 = 31/50 (the card's 0.62).
example : 2 * (9/10 : ℝ) ^ 2 - 1 = 31/50 := by norm_num
-- The negative pivot [[-1, 1], [1, 0]]: the ratio test d - b^2/a gives 1.
example : (0 : ℝ) - 1 ^ 2 / (-1) = 1 := by norm_num
-- Max-cut on the ring of five: the best split cuts 4 links, and 10 of the 32 splits reach it.
example : (Finset.univ : Finset (Finset (Fin 5))).sup (cutSize (SimpleGraph.cycleGraph 5)) = 4 := by
  decide
example : ((Finset.univ : Finset (Finset (Fin 5))).filter
    fun S => cutSize (SimpleGraph.cycleGraph 5) S = 4).card = 10 := by
  decide

#print axioms posSemidef_unit_iff
#print axioms posSemidef_entry_ge_neg_one
#print axioms maxCutObjective_le
#print axioms schur_complement_psd_iff
#print axioms cutSize_le_maxCut_relaxation
#print axioms sdp_feasible_set_convex
