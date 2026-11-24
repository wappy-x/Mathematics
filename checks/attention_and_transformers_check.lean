-- Attention: self-attention with no position code commutes with every reordering of the words, each row of its softmax weights is positive and adds to 1, one transformer block costs exactly 12nd² + 2n²d multiplications with any number of heads, and the card's whole-number examples check out.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Real.Sqrt
import Mathlib.LinearAlgebra.Matrix.Permutation
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Fintype.Perm

namespace AttentionAndTransformers

open Matrix

/-- The softmax along each row of a table of scores: raise e to each score and divide by the
row's total. -/
noncomputable def rowSoftmax {m k : Type*} [Fintype k] (S : Matrix m k ℝ) : Matrix m k ℝ :=
  fun i j => Real.exp (S i j) / ∑ l, Real.exp (S i l)

/-- The attention weights for `n` words of width `d`, stacked as the rows of `X`:
`A = softmax(Q Kᵀ / √d)` with `Q = X W_Q` and `K = X W_K`, the softmax taken along each row. -/
noncomputable def attentionWeights {n d : ℕ} (X : Matrix (Fin n) (Fin d) ℝ)
    (WQ WK : Matrix (Fin d) (Fin d) ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  rowSoftmax ((1 / Real.sqrt d) • ((X * WQ) * (X * WK)ᵀ))

/-- Scaled dot-product self-attention: `Z = softmax(Q Kᵀ / √d) V` with `V = X W_V`. Row `i` of
`Z` is word `i`'s new list, the weighted average of the values. -/
noncomputable def attention {n d : ℕ} (X : Matrix (Fin n) (Fin d) ℝ)
    (WQ WK WV : Matrix (Fin d) (Fin d) ℝ) : Matrix (Fin n) (Fin d) ℝ :=
  attentionWeights X WQ WK * (X * WV)

/-- Softmax along rows commutes with reordering rows and columns by the same permutation. -/
theorem rowSoftmax_submatrix {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (σ : Equiv.Perm (Fin n)) :
    rowSoftmax (S.submatrix σ σ) = (rowSoftmax S).submatrix σ σ := by
  ext i j
  simp only [rowSoftmax, submatrix_apply]
  congr 1
  exact Equiv.sum_comp σ (fun l => Real.exp (S (σ i) l))

#print axioms rowSoftmax_submatrix

/-- The card's main result (Step 3, permutation equivariance). Take any `n` words of width `d`
with no position code and no causal mask, and any query, key and value matrices. Reorder the
words by a permutation `σ`, written as the permutation matrix `P`. Then the outputs come out
reordered in the same way and nothing else changes: attention of `P X` is `P` times attention
of `X`. -/
theorem attention_perm_equivariant {n d : ℕ} (X : Matrix (Fin n) (Fin d) ℝ)
    (WQ WK WV : Matrix (Fin d) (Fin d) ℝ) (σ : Equiv.Perm (Fin n)) :
    attention (σ.permMatrix ℝ * X) WQ WK WV = σ.permMatrix ℝ * attention X WQ WK WV := by
  have hP : ∀ (M : Matrix (Fin n) (Fin d) ℝ), σ.permMatrix ℝ * M = M.submatrix σ id :=
    fun M => PEquiv.toMatrix_toPEquiv_mul σ M
  have hm : ∀ (M : Matrix (Fin n) (Fin d) ℝ) (W : Matrix (Fin d) (Fin d) ℝ),
      M.submatrix σ id * W = (M * W).submatrix σ id := by
    intro M W
    ext i j
    rfl
  rw [hP, hP]
  unfold attention attentionWeights
  rw [hm, hm, hm, transpose_submatrix]
  have hs : (X * WQ).submatrix σ id * ((X * WK)ᵀ).submatrix id σ
      = ((X * WQ) * (X * WK)ᵀ).submatrix σ σ := by
    ext i j
    rfl
  have hsm : (1 / Real.sqrt d) • ((X * WQ) * (X * WK)ᵀ).submatrix σ σ
      = ((1 / Real.sqrt d) • ((X * WQ) * (X * WK)ᵀ)).submatrix σ σ := rfl
  rw [hs, hsm, rowSoftmax_submatrix]
  exact submatrix_mul_equiv _ _ σ σ id

/-- Step 1: every attention weight is positive and the weights in each row add to 1, so each
output is a true weighted average of the values. -/
theorem attentionWeights_pos_and_row_sum_eq_one {n d : ℕ} (X : Matrix (Fin n) (Fin d) ℝ)
    (WQ WK : Matrix (Fin d) (Fin d) ℝ) (i : Fin n) :
    (∀ j, 0 < attentionWeights X WQ WK i j) ∧ ∑ j, attentionWeights X WQ WK i j = 1 := by
  have hden : 0 < ∑ l, Real.exp (((1 / Real.sqrt d) • ((X * WQ) * (X * WK)ᵀ)) i l) := by
    have hne : Nonempty (Fin n) := ⟨i⟩
    exact Finset.sum_pos (fun l _ => Real.exp_pos _) Finset.univ_nonempty
  refine ⟨fun j => div_pos (Real.exp_pos _) hden, ?_⟩
  simp only [attentionWeights, rowSoftmax]
  rw [← Finset.sum_div]
  exact div_self hden.ne'

/-- Step 6: the cost of one transformer block, counted as multiplications inside its matrix
products (an (a by b) times (b by c) product costs a·b·c), with `h` heads each of width `e`, so
the width is `d = h e`, and a feed-forward layer of width `4d`. Queries, keys and values cost
`3nd²`, the `h` score tables `h · n e n`, the `h` mixings `h · n n e`, the output matrix `nd²`
and the feed-forward layer `nd(4d) + n(4d)d`. The total is `12nd² + 2n²d` for every number of
heads. -/
theorem transformer_block_cost (n h e : ℕ) :
    3 * (n * (h * e) * (h * e)) + h * (n * e * n) + h * (n * n * e) + n * (h * e) * (h * e)
      + (n * (h * e) * (4 * (h * e)) + n * (4 * (h * e)) * (h * e))
      = 12 * n * (h * e) ^ 2 + 2 * n ^ 2 * (h * e) := by
  ring

/-! The card's house example: "the cat sat on the mat", width 2. -/

/-- The six embeddings as rows: the (1, 0), cat (0, 2), sat (1, 1), on (1, −1), the (1, 0),
mat (0, 1). -/
def houseX : Matrix (Fin 6) (Fin 2) ℤ := !![1, 0; 0, 2; 1, 1; 1, -1; 1, 0; 0, 1]

/-- The query matrix keeps the embedding. -/
def houseWQ : Matrix (Fin 2) (Fin 2) ℤ := !![1, 0; 0, 1]

/-- The key matrix swaps the two numbers. -/
def houseWK : Matrix (Fin 2) (Fin 2) ℤ := !![0, 1; 1, 0]

-- The unscaled score table Q Kᵀ: row "sat" is 1, 2, 2, 0, 1, 1, as in Worked numbers.
example : (houseX * houseWQ) * (houseX * houseWK)ᵀ =
    !![0, 2, 1, -1, 0, 1;
       2, 0, 2, 2, 2, 0;
       1, 2, 2, 0, 1, 1;
       -1, 2, 0, -2, -1, 1;
       0, 2, 1, -1, 0, 1;
       1, 0, 1, 1, 1, 0] := by
  decide

-- Swapping slots 2 and 6 turns the sentence into "the mat sat on the cat".
example : (Equiv.swap (1 : Fin 6) 5).permMatrix ℤ * houseX =
    !![1, 0; 0, 1; 1, 1; 1, -1; 1, 0; 0, 2] := by
  decide

-- The code checks all 720 orders of the six words.
example : Fintype.card (Equiv.Perm (Fin 6)) = 720 := by
  rw [Fintype.card_perm, Fintype.card_fin]; decide

-- Six words make 36 query-key pairs at 2 multiplications each: 72.
example : 6 * 6 * 2 = 72 := by norm_num

-- The house block, n = 6 and d = 2: 72 + 72 + 72 + 24 + 192 = 432 = 12·6·2² + 2·6²·2.
example : 3 * (6 * 2 * 2) + 6 * 2 * 6 + 6 * 6 * 2 + 6 * 2 * 2 + (6 * 2 * 8 + 6 * 8 * 2) = 432 ∧
    12 * 6 * 2 ^ 2 + 2 * 6 ^ 2 * 2 = 432 := by norm_num

-- The counted block sizes in the code's table.
example : 12 * 12 * 4 ^ 2 + 2 * 12 ^ 2 * 4 = 3456 ∧ 12 * 24 * 4 ^ 2 + 2 * 24 ^ 2 * 4 = 9216 ∧
    12 * 48 * 4 ^ 2 + 2 * 48 ^ 2 * 4 = 27648 ∧ 12 * 96 * 8 ^ 2 + 2 * 96 ^ 2 * 8 = 221184 := by
  norm_num

-- The two parts cross at n = 6d: 12 words at width 2, 4608 words at width 768.
example : 12 * 12 * 2 ^ 2 = 2 * 12 ^ 2 * 2 ∧ 12 * 4608 * 768 ^ 2 = 2 * 4608 ^ 2 * 768 := by
  norm_num

-- A causal mask keeps 1 + 2 + ... + 6 = 21 of the 36 scores.
example : ∑ i ∈ Finset.range 6, (i + 1) = 21 := by decide

#print axioms attention_perm_equivariant
#print axioms attentionWeights_pos_and_row_sum_eq_one
#print axioms transformer_block_cost

end AttentionAndTransformers
