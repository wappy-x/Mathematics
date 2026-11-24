-- Block designs: in every 2-(v, k, λ) design each point lies in the same number r of blocks with b k = v r and r (k − 1) = λ (v − 1), the incidence matrix satisfies N Nᵀ = (r − λ) I + λ J, the blocks never number fewer than the points (Fisher's inequality), and the card's Fano plane numbers check out.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse

namespace BlockDesignsAndFishersInequality

open Finset

variable {α ι : Type*} [Fintype α] [DecidableEq α] [Fintype ι]

/-- The incidence matrix `N` of a list of blocks `B` on the points `α`: one row per point, one
column per block, `1` where the point is in the block and `0` elsewhere. -/
def incidence (B : ι → Finset α) : Matrix α ι ℚ :=
  Matrix.of fun x i => if x ∈ B i then 1 else 0

/-- For each point `x`, (blocks through `x`) × (k − 1) = λ (v − 1), by counting pairs. -/
theorem deg_mul_eq (B : ι → Finset α) (k lam : ℕ)
    (hk : ∀ i, (B i).card = k)
    (hpair : ∀ x y : α, x ≠ y → (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card = lam) (x : α) :
    (univ.filter fun i => x ∈ B i).card * (k - 1) = lam * (Fintype.card α - 1) := by
  classical
  have h1 : ∑ y ∈ univ.erase x, (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card
      = lam * (Fintype.card α - 1) := by
    rw [Finset.sum_congr rfl (fun y hy => hpair x y (Finset.ne_of_mem_erase hy).symm)]
    rw [sum_const, card_erase_of_mem (mem_univ x), card_univ, smul_eq_mul, mul_comm]
  rw [← h1, ← smul_eq_mul, ← sum_const, Finset.sum_filter]
  simp_rw [card_filter]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  by_cases hi : x ∈ B i
  swap
  · simp [hi]
  simp only [hi, true_and, ite_true]
  rw [← card_filter, ← hk i, ← card_erase_of_mem hi]
  congr 1
  ext y
  simp [and_comm]

#print axioms deg_mul_eq

/-- Helper copy of `block_design_counts`, placed early so `fisher_inequality` can use it. -/
theorem counts_aux (B : ι → Finset α) (k lam : ℕ)
    (hk : ∀ i, (B i).card = k)
    (hpair : ∀ x y : α, x ≠ y → (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card = lam)
    (hlam : 1 ≤ lam) (hv : 2 ≤ Fintype.card α) :
    ∃ r : ℕ, (∀ x : α, (univ.filter fun i => x ∈ B i).card = r) ∧
      Fintype.card ι * k = Fintype.card α * r ∧
      r * (k - 1) = lam * (Fintype.card α - 1) := by
  have hne : Nonempty α := Fintype.card_pos_iff.mp (by omega)
  obtain ⟨x0⟩ := hne
  have hpos : 0 < lam * (Fintype.card α - 1) := Nat.mul_pos (by omega) (by omega)
  have hk1 : 0 < k - 1 := by
    rcases Nat.eq_zero_or_pos (k - 1) with h | h
    · have := deg_mul_eq B k lam hk hpair x0
      rw [h, mul_zero] at this; omega
    · exact h
  have hr : ∀ x : α, (univ.filter fun i => x ∈ B i).card
      = (univ.filter fun i => x0 ∈ B i).card := fun x =>
    Nat.eq_of_mul_eq_mul_right hk1
      ((deg_mul_eq B k lam hk hpair x).trans (deg_mul_eq B k lam hk hpair x0).symm)
  refine ⟨_, hr, ?_, deg_mul_eq B k lam hk hpair x0⟩
  have : ∑ i : ι, (B i).card = ∑ x : α, (univ.filter fun i => x ∈ B i).card := by
    simp_rw [card_filter]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    rw [← card_filter]
    congr 1; ext; simp
  rw [Finset.sum_congr rfl (fun i _ => hk i), Finset.sum_congr rfl (fun x _ => hr x)] at this
  simpa [sum_const, card_univ, smul_eq_mul] using this

#print axioms counts_aux

/-- Helper copy of `incidence_mul_transpose`, placed early so `fisher_inequality` can use it. -/
theorem incidence_mul_transpose_aux (B : ι → Finset α) (r lam : ℕ)
    (hr : ∀ x : α, (univ.filter fun i => x ∈ B i).card = r)
    (hpair : ∀ x y : α, x ≠ y → (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card = lam) :
    incidence B * (incidence B).transpose =
      ((r : ℚ) - lam) • (1 : Matrix α α ℚ) + (lam : ℚ) • Matrix.of fun _ _ => 1 := by
  ext x y
  have : (incidence B * (incidence B).transpose) x y
      = ((univ.filter fun i => x ∈ B i ∧ y ∈ B i).card : ℚ) := by
    simp only [Matrix.mul_apply, incidence, Matrix.transpose_apply, Matrix.of_apply]
    rw [card_filter]; push_cast
    refine Finset.sum_congr rfl (fun i _ => ?_)
    split_ifs <;> simp_all
  rw [this]
  by_cases hxy : x = y
  · subst hxy
    simp only [and_self, hr]
    simp
  · rw [hpair x y hxy]
    simp [Matrix.one_apply_ne hxy]

#print axioms incidence_mul_transpose_aux

/-- Fisher's inequality. Take `v` points and a list of `b` blocks `B`, every block holding `k`
points, every pair of distinct points together in exactly `λ` blocks, with `k < v` and `λ ≥ 1`
(so the design has at least one pair of points, `v ≥ 2`). Then the blocks never number fewer
than the points: `v ≤ b`. -/
theorem fisher_inequality (B : ι → Finset α) (k lam : ℕ)
    (hk : ∀ i, (B i).card = k)
    (hpair : ∀ x y : α, x ≠ y → (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card = lam)
    (hkv : k < Fintype.card α) (hlam : 1 ≤ lam) (hv : 2 ≤ Fintype.card α) :
    Fintype.card α ≤ Fintype.card ι := by
  obtain ⟨r, hr, -, hrk⟩ := counts_aux B k lam hk hpair hlam hv
  have hpos : 0 < lam * (Fintype.card α - 1) := Nat.mul_pos (by omega) (by omega)
  have hk1 : 0 < k - 1 := by
    rcases Nat.eq_zero_or_pos (k - 1) with h | h
    · rw [h, mul_zero] at hrk; omega
    · exact h
  have hrl : lam < r := by
    by_contra h
    replace h := not_lt.mp h
    have h1 : r * (k - 1) ≤ lam * (k - 1) := Nat.mul_le_mul_right _ h
    have h2 : lam * (k - 1) < lam * (Fintype.card α - 1) :=
      Nat.mul_lt_mul_of_pos_left (by omega) (by omega)
    omega
  have hM := incidence_mul_transpose_aux B r lam hr hpair
  set c : ℚ := (r : ℚ) - lam with hc
  have hcpos : 0 < c := by
    rw [hc, sub_pos]; exact_mod_cast hrl
  have hunit : IsUnit (incidence B * (incidence B).transpose) := by
    rw [← Matrix.mulVec_injective_iff_isUnit, hM]
    intro u w huw
    have key : ∀ d : α → ℚ,
        (c • (1 : Matrix α α ℚ) + (lam : ℚ) • Matrix.of fun _ _ => (1 : ℚ)).mulVec d = 0 →
        d = 0 := by
      intro d hd
      have hx : ∀ x, c * d x + lam * ∑ y, d y = 0 := by
        intro x
        have := congrFun hd x
        simp only [Matrix.add_mulVec, Matrix.smul_mulVec, Matrix.one_mulVec, Pi.add_apply,
          Pi.smul_apply, smul_eq_mul, Pi.zero_apply] at this
        simpa [Matrix.mulVec, dotProduct] using this
      have hs : ∑ y, d y = 0 := by
        have := Finset.sum_congr rfl (fun x (_ : x ∈ (univ : Finset α)) => hx x)
        rw [Finset.sum_add_distrib, ← Finset.mul_sum, sum_const, card_univ, nsmul_eq_mul] at this
        simp only [sum_const_zero] at this
        have hfac : (c + Fintype.card α * lam) * ∑ y, d y = 0 := by linarith
        have hne : c + Fintype.card α * lam ≠ 0 := by positivity
        exact (mul_eq_zero.mp hfac).resolve_left hne
      funext x
      have := hx x
      rw [hs, mul_zero, add_zero] at this
      exact (mul_eq_zero.mp this).resolve_left hcpos.ne'
    have := key (u - w) (by rw [Matrix.mulVec_sub, huw, sub_self])
    exact sub_eq_zero.mp this
  have h1 := Matrix.rank_of_isUnit _ hunit
  have h2 := Matrix.rank_mul_le_left (incidence B) (incidence B).transpose
  have h3 := Matrix.rank_le_card_width (incidence B)
  omega

/-- The two counts. In a 2-(v, k, λ) design with `λ ≥ 1` (and so `v ≥ 2`), every point lies
in the same number `r` of blocks, and `b k = v r` and `r (k − 1) = λ (v − 1)`. -/
theorem block_design_counts (B : ι → Finset α) (k lam : ℕ)
    (hk : ∀ i, (B i).card = k)
    (hpair : ∀ x y : α, x ≠ y → (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card = lam)
    (hlam : 1 ≤ lam) (hv : 2 ≤ Fintype.card α) :
    ∃ r : ℕ, (∀ x : α, (univ.filter fun i => x ∈ B i).card = r) ∧
      Fintype.card ι * k = Fintype.card α * r ∧
      r * (k - 1) = lam * (Fintype.card α - 1) := by
  exact counts_aux B k lam hk hpair hlam hv

/-- The incidence matrix. If every point lies in `r` blocks and every pair of distinct points
lies together in `λ` blocks, then `N Nᵀ = (r − λ) I + λ J`: `r` down the diagonal and `λ`
everywhere else, where `J` is the all-ones matrix. -/
theorem incidence_mul_transpose (B : ι → Finset α) (r lam : ℕ)
    (hr : ∀ x : α, (univ.filter fun i => x ∈ B i).card = r)
    (hpair : ∀ x y : α, x ≠ y → (univ.filter fun i => x ∈ B i ∧ y ∈ B i).card = lam) :
    incidence B * (incidence B).transpose =
      ((r : ℚ) - lam) • (1 : Matrix α α ℚ) + (lam : ℚ) • Matrix.of fun _ _ => 1 := by
  exact incidence_mul_transpose_aux B r lam hr hpair

/-- The Fano plane, the card's coffee schedule with blends 1 to 7 renamed 0 to 6 and tasters
A to G as blocks 0 to 6. -/
def fano : Fin 7 → Finset (Fin 7) :=
  ![{0, 1, 3}, {1, 2, 4}, {2, 3, 5}, {3, 4, 6}, {4, 5, 0}, {5, 6, 1}, {6, 0, 2}]

-- Every taster has 3 blends, every blend is tasted 3 times, every pair of blends meets once.
example : ∀ i, (fano i).card = 3 := by decide
example : ∀ x : Fin 7, (univ.filter fun i => x ∈ fano i).card = 3 := by decide
example : ∀ x y : Fin 7, x ≠ y → (univ.filter fun i => x ∈ fano i ∧ y ∈ fano i).card = 1 := by
  decide

-- The two counts: b k = 7 × 3 = 21 = 7 × 3 = v r, and r (k − 1) = 3 × 2 = 6 = 1 × 6 = λ (v − 1).
example : 7 * 3 = 7 * 3 ∧ 7 * 3 = 21 ∧ 3 * (3 - 1) = 1 * (7 - 1) ∧ 3 * (3 - 1) = 6 := by decide

-- 3 pairs per taster times 7 tasters is all 21 pairs of 7 blends.
example : Nat.choose 3 2 * 7 = Nat.choose 7 2 ∧ Nat.choose 7 2 = 21 := by decide

-- For the Fano plane, N Nᵀ = 2 I + J: 3 down the diagonal and 1 elsewhere.
example : incidence fano * (incidence fano).transpose =
    (2 : ℚ) • (1 : Matrix (Fin 7) (Fin 7) ℚ) + Matrix.of fun _ _ => 1 := by
  rw [incidence_mul_transpose fano 3 1 (by decide) (by decide)]
  norm_num

-- det N = 24 for the Fano incidence matrix, and det N Nᵀ = 24 × 24 = 576 = 2^6 × 9.
example : (incidence fano).det = 24 := by
  have h : incidence fano = !![1,0,0,0,1,0,1; 1,1,0,0,0,1,0; 0,1,1,0,0,0,1;
      1,0,1,1,0,0,0; 0,1,0,1,1,0,0; 0,0,1,0,1,1,0; 0,0,0,1,0,1,1] := by
    ext i j
    fin_cases i <;> fin_cases j <;> decide
  rw [h]
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ]
  norm_num [Fin.succAbove, Fin.lt_def]
example : 24 * 24 = 576 ∧ 2 ^ 6 * 9 = 576 := by norm_num

-- Parameters (8, 3, 1) are impossible: r (3 − 1) = 1 × (8 − 1) has no whole-number solution r.
example : ¬ ∃ r : ℕ, r * (3 - 1) = 1 * (8 - 1) := by
  rintro ⟨r, hr⟩; omega

-- Parameters (16, 6, 1) pass both counts with r = 3 and b = 8, yet 8 < 16 breaks Fisher.
example : 3 * (6 - 1) = 1 * (16 - 1) ∧ 8 * 6 = 16 * 3 ∧ 8 < 16 := by norm_num

#print axioms fisher_inequality
#print axioms block_design_counts
#print axioms incidence_mul_transpose

end BlockDesignsAndFishersInequality
