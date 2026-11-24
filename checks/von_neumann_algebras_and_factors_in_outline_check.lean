-- Factors in outline: in the 2^n × 2^n complex matrices with the normalised trace, a projection's size is its rank over 2^n, every k/2^n occurs, two projections are linked by a partial isometry exactly when their sizes agree, and adding a qubit keeps every size.
import Mathlib.Algebra.Star.StarProjection
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Basic.Complex.Basic
import Mathlib.Analysis.Matrix.Spectrum

open Matrix
open scoped Kronecker

theorem vn_eig01 {ι : Type*} [Fintype ι] [DecidableEq ι] {P : Matrix ι ι ℂ}
    (hP : IsStarProjection P) (i : ι) :
    (hP.isSelfAdjoint.isHermitian).eigenvalues i = 0 ∨
      (hP.isSelfAdjoint.isHermitian).eigenvalues i = 1 := by
  set hA := hP.isSelfAdjoint.isHermitian
  set v : ι → ℂ := ⇑(hA.eigenvectorBasis i)
  set t := hA.eigenvalues i
  have hv : v ≠ 0 := (WithLp.ofLp_eq_zero 2).ne.2 <| hA.eigenvectorBasis.orthonormal.ne_zero i
  have h1 : P *ᵥ v = (t : ℂ) • v := by
    rw [hA.mulVec_eigenvectorBasis i, RCLike.real_smul_eq_coe_smul (K := ℂ)]; rfl
  have h2 : P *ᵥ (P *ᵥ v) = P *ᵥ v := by
    rw [mulVec_mulVec, hP.isIdempotentElem.eq]
  rw [h1, mulVec_smul, h1, smul_smul] at h2
  have h3 : ((t : ℂ) * t - t) • v = 0 := by rw [sub_smul, h2, sub_self]
  rcases smul_eq_zero.mp h3 with h | h
  · have : (t : ℂ) * (t - 1) = 0 := by rw [mul_sub, mul_one]; exact h
    rcases mul_eq_zero.mp this with h | h
    · left; exact_mod_cast h
    · right; have : (t : ℂ) = 1 := sub_eq_zero.mp h
      exact_mod_cast this
  · exact absurd h hv

#print axioms vn_eig01

theorem vn_trace_eq_card {ι : Type*} [Fintype ι] [DecidableEq ι] {P : Matrix ι ι ℂ}
    (hP : IsStarProjection P) :
    trace P = (Finset.univ.filter
      (fun i => (hP.isSelfAdjoint.isHermitian).eigenvalues i = 1)).card := by
  rw [(hP.isSelfAdjoint.isHermitian).trace_eq_sum_eigenvalues, Finset.card_filter,
    Nat.cast_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rcases vn_eig01 hP i with h | h <;> simp [h]

#print axioms vn_trace_eq_card

theorem vn_rank_eq_card {ι : Type*} [Fintype ι] [DecidableEq ι] {P : Matrix ι ι ℂ}
    (hP : IsStarProjection P) :
    P.rank = (Finset.univ.filter
      (fun i => (hP.isSelfAdjoint.isHermitian).eigenvalues i = 1)).card := by
  rw [(hP.isSelfAdjoint.isHermitian).rank_eq_card_non_zero_eigs, Fintype.card_subtype]
  congr 1
  apply Finset.filter_congr
  intro i _
  rcases vn_eig01 hP i with h | h <;> simp [h]

#print axioms vn_rank_eq_card

theorem vn_trace_eq_rank {ι : Type*} [Fintype ι] [DecidableEq ι] {P : Matrix ι ι ℂ}
    (hP : IsStarProjection P) : trace P = (P.rank : ℂ) := by
  rw [vn_trace_eq_card hP, vn_rank_eq_card hP]

#print axioms vn_trace_eq_rank

open Polynomial in
theorem vn_charpoly {ι : Type*} [Fintype ι] [DecidableEq ι] {P : Matrix ι ι ℂ}
    (hP : IsStarProjection P) :
    P.charpoly = (X - 1) ^ (Finset.univ.filter
      (fun i => (hP.isSelfAdjoint.isHermitian).eigenvalues i = 1)).card *
      X ^ (Finset.univ.filter
      (fun i => ¬ (hP.isSelfAdjoint.isHermitian).eigenvalues i = 1)).card := by
  rw [(hP.isSelfAdjoint.isHermitian).charpoly_eq]
  rw [← Finset.prod_const, ← Finset.prod_const]
  rw [Finset.prod_filter, Finset.prod_filter, ← Finset.prod_mul_distrib]
  refine Finset.prod_congr rfl fun i _ => ?_
  rcases vn_eig01 hP i with h | h <;> simp [h]

#print axioms vn_charpoly

/-- Sizes of projections in n qubits. In the 2^n × 2^n complex matrices, give a projection P
(P² = P and P* = P) the size τ(P) = tr P / 2^n. Then every size equals rank P / 2^n, and the set
of sizes is exactly 0, 1/2^n, 2/2^n, …, 1: the numbers k/2^n with k a whole number from 0 to 2^n. -/
theorem projection_sizes_eq_rank_div_two_pow (n : ℕ) :
    (∀ P : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ, IsStarProjection P →
        trace P / 2 ^ n = (P.rank : ℂ) / 2 ^ n) ∧
      {x : ℂ | ∃ P : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ, IsStarProjection P ∧
          x = trace P / 2 ^ n} =
        {x : ℂ | ∃ k : ℕ, k ≤ 2 ^ n ∧ x = (k : ℂ) / 2 ^ n} := by
  refine ⟨fun P hP => by rw [vn_trace_eq_rank hP], ?_⟩
  ext x
  constructor
  · rintro ⟨P, hP, rfl⟩
    exact ⟨P.rank, P.rank_le_width, by rw [vn_trace_eq_rank hP]⟩
  · rintro ⟨k, hk, rfl⟩
    refine ⟨diagonal (fun i : Fin (2 ^ n) => if (i : ℕ) < k then (1 : ℂ) else 0), ⟨?_, ?_⟩, ?_⟩
    · show _ * _ = _
      rw [diagonal_mul_diagonal]
      congr 1; funext i; split_ifs <;> simp_all
    · show star _ = _
      rw [star_eq_conjTranspose, diagonal_conjTranspose]
      congr 1; funext i; by_cases h : (i : ℕ) < k <;> simp [h]
    · congr 1
      rw [trace_diagonal, Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const,
        nsmul_eq_mul, mul_one, Fin.card_filter_val_lt, min_eq_right hk]

/-- Equivalent projections are exactly the ones of equal size. In the 2^n × 2^n complex matrices,
two projections P and Q are linked by a partial isometry V (V*V = P and VV* = Q) exactly when
their normalised traces agree: τ(P) = τ(Q). The forward direction is the trace rule
τ(V*V) = τ(VV*); the converse sends an orthonormal basis of one range onto one of the other. -/
theorem equivalent_iff_same_size (n : ℕ) {P Q : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ}
    (hP : IsStarProjection P) (hQ : IsStarProjection Q) :
    (∃ V : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ, Vᴴ * V = P ∧ V * Vᴴ = Q) ↔
      trace P / 2 ^ n = trace Q / 2 ^ n := by
  constructor
  · rintro ⟨V, rfl, rfl⟩
    rw [trace_mul_comm]
  · intro h
    have h2 : (2 : ℂ) ^ n ≠ 0 := pow_ne_zero _ two_ne_zero
    rw [div_left_inj' h2, vn_trace_eq_card hP, vn_trace_eq_card hQ, Nat.cast_inj] at h
    set hA := hP.isSelfAdjoint.isHermitian
    set hB := hQ.isSelfAdjoint.isHermitian
    have hc : (Finset.univ.filter (fun i => ¬ hA.eigenvalues i = 1)).card =
        (Finset.univ.filter (fun i => ¬ hB.eigenvalues i = 1)).card := by
      rw [Finset.filter_not, Finset.filter_not, Finset.card_sdiff_of_subset (Finset.filter_subset _ _),
        Finset.card_sdiff_of_subset (Finset.filter_subset _ _), h]
    have he : hA.eigenvalues = hB.eigenvalues := by
      rw [hA.eigenvalues_eq_eigenvalues_iff hB, vn_charpoly hP, vn_charpoly hQ, h, hc]
    have sP := hA.spectral_theorem
    have sQ := hB.spectral_theorem
    rw [Unitary.conjStarAlgAut_apply] at sP sQ
    rw [← he] at sQ
    set U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ := ((hA.eigenvectorUnitary : unitaryGroup (Fin (2 ^ n)) ℂ) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
    set W : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ := ((hB.eigenvectorUnitary : unitaryGroup (Fin (2 ^ n)) ℂ) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
    set D : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ := diagonal (RCLike.ofReal ∘ hA.eigenvalues)
    have hU : star U * U = 1 := Unitary.coe_star_mul_self _
    have hW : star W * W = 1 := Unitary.coe_star_mul_self _
    have hU' : U * star U = 1 := Unitary.coe_mul_star_self _
    have hW' : W * star W = 1 := Unitary.coe_mul_star_self _
    refine ⟨W * star U * P, ?_, ?_⟩
    · rw [← star_eq_conjTranspose, star_mul, star_mul, star_star, hP.isSelfAdjoint.star_eq]
      calc P * (U * star W) * (W * star U * P) = P * (U * (star W * W) * star U) * P := by
            simp only [mul_assoc]
        _ = P := by rw [hW, mul_one, hU', mul_one, hP.isIdempotentElem.eq]
    · rw [← star_eq_conjTranspose, star_mul, star_mul, star_star, hP.isSelfAdjoint.star_eq]
      calc W * star U * P * (P * (U * star W)) = W * star U * (P * P) * U * star W := by
            simp only [mul_assoc]
        _ = Q := by
          rw [hP.isIdempotentElem.eq, sQ]
          conv_lhs => rw [sP]
          calc W * star U * (U * D * star U) * U * star W
              = W * (star U * U) * D * (star U * U) * star W := by simp only [mul_assoc]
            _ = W * D * star W := by rw [hU, mul_one, mul_one]

/-- Adding a qubit keeps sizes. The embedding A ↦ A ⊗ 1 of the 2^n × 2^n matrices into the
2^(n+1) × 2^(n+1) matrices (the new qubit left alone) keeps the normalised trace:
tr(A ⊗ 1) / 2^(n+1) = tr A / 2^n. -/
theorem normalised_trace_kronecker_one (n : ℕ) (A : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) :
    trace (A ⊗ₖ (1 : Matrix (Fin 2) (Fin 2) ℂ)) / 2 ^ (n + 1) = trace A / 2 ^ n := by
  rw [trace_kronecker, trace_one, Fintype.card_fin, pow_succ]
  have h2 : (2 : ℂ) ^ n ≠ 0 := pow_ne_zero _ two_ne_zero
  push_cast
  field_simp

-- The card's projection onto the line through u = (3/5, 4/5): P = [[9/25, 12/25], [12/25, 16/25]].
-- It is a projection, its size is (9/25 + 16/25) / 2 = 1/2, and V = [[3/5, 0], [4/5, 0]]
-- links it to E11: V*V = E11 and VV* = P.
example : !![(9 : ℚ) / 25, 12 / 25; 12 / 25, 16 / 25] * !![(9 : ℚ) / 25, 12 / 25; 12 / 25, 16 / 25]
    = !![(9 : ℚ) / 25, 12 / 25; 12 / 25, 16 / 25] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : trace !![(9 : ℚ) / 25, 12 / 25; 12 / 25, 16 / 25] / 2 = 1 / 2 := by
  simp [trace, Fin.sum_univ_two]; norm_num
example : (!![(3 : ℚ) / 5, 0; 4 / 5, 0])ᵀ * !![(3 : ℚ) / 5, 0; 4 / 5, 0] = !![1, 0; 0, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : !![(3 : ℚ) / 5, 0; 4 / 5, 0] * (!![(3 : ℚ) / 5, 0; 4 / 5, 0])ᵀ
    = !![(9 : ℚ) / 25, 12 / 25; 12 / 25, 16 / 25] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]

-- The halving step: W = E11 ⊗ E12 has W*W = E11 ⊗ E22 and WW* = E11 ⊗ E11.
example : (!![(1 : ℤ), 0; 0, 0] ⊗ₖ !![(0 : ℤ), 1; 0, 0])ᵀ * (!![(1 : ℤ), 0; 0, 0] ⊗ₖ !![(0 : ℤ), 1; 0, 0])
    = !![(1 : ℤ), 0; 0, 0] ⊗ₖ !![(0 : ℤ), 0; 0, 1] := by decide
example : (!![(1 : ℤ), 0; 0, 0] ⊗ₖ !![(0 : ℤ), 1; 0, 0]) * (!![(1 : ℤ), 0; 0, 0] ⊗ₖ !![(0 : ℤ), 1; 0, 0])ᵀ
    = !![(1 : ℤ), 0; 0, 0] ⊗ₖ !![(1 : ℤ), 0; 0, 0] := by decide

-- The smallest non-zero size at ten qubits is 1/2^10 = 1/1024.
example : (1 : ℚ) / 2 ^ 10 = 1 / 1024 := by norm_num

-- One third is no size at levels 1 to 4: 2^n is never a multiple of 3, so 3k ≠ 2^n.
example : ∀ n ∈ Finset.Icc 1 4, ∀ k ∈ Finset.range (2 ^ 4 + 1), 3 * k ≠ 2 ^ n := by decide

-- The one-third test on N digits passes (2^N + 2)/3 of the 2^N patterns: 6 for N = 4, 86 for N = 8.
example : ((Finset.range (2 ^ 4)).filter (fun k => 3 * k < 2 ^ 4)).card = (2 ^ 4 + 2) / 3 := by
  decide
example : ((Finset.range (2 ^ 8)).filter (fun k => 3 * k < 2 ^ 8)).card = (2 ^ 8 + 2) / 3 := by
  decide +kernel

-- The plain trace of E11 ⊗ 1 at level 10 is 512, not 1: it doubles with each qubit.
example : trace ((!![(1 : ℤ), 0; 0, 0]) ⊗ₖ (1 : Matrix (Fin (2 ^ 9)) (Fin (2 ^ 9)) ℤ)) = 512 := by
  rw [trace_kronecker]; simp [trace, Fin.sum_univ_two]

-- The truncated shift at N = 4: S*S and SS* both have trace 3, against 4 for the identity.
example : trace ((Matrix.of fun r c : Fin 4 => if (r : ℕ) = c + 1 then (1 : ℤ) else 0)ᵀ *
    Matrix.of fun r c : Fin 4 => if (r : ℕ) = c + 1 then (1 : ℤ) else 0) = 3 := by decide
example : trace ((Matrix.of fun r c : Fin 4 => if (r : ℕ) = c + 1 then (1 : ℤ) else 0) *
    (Matrix.of fun r c : Fin 4 => if (r : ℕ) = c + 1 then (1 : ℤ) else 0)ᵀ) = 3 := by decide

#print axioms projection_sizes_eq_rank_div_two_pow
#print axioms equivalent_iff_same_size
#print axioms normalised_trace_kronecker_one
