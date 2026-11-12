-- Every root at once: the companion matrix of a polynomial has that polynomial divided by its leading coefficient as its characteristic polynomial, so its eigenvalues are exactly the roots; Horner's partial sums are the quotient after dividing by x - z; and the backward error of a computed root is exactly |p(x̂)| / Σ|a_k||x̂|^k.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Eigs
import Mathlib.LinearAlgebra.Matrix.Charpoly.Minpoly
import Mathlib.RingTheory.AdjoinRoot
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Polynomial

/-- The companion matrix of a polynomial p of degree n = natDegree p, with coefficients a_k:
the top row is -a_(n-1)/a_n, ..., -a_1/a_n, -a_0/a_n, there are ones just below the diagonal,
and every other entry is zero. -/
noncomputable def companion {K : Type*} [Field K] (p : K[X]) :
    Matrix (Fin p.natDegree) (Fin p.natDegree) K :=
  Matrix.of fun i j =>
    if (i : ℕ) = 0 then -p.coeff (p.natDegree - 1 - j) / p.leadingCoeff
    else if (i : ℕ) = j + 1 then 1 else 0

/-- Horner's partial sums of p at z, reading p as a polynomial of degree n with coefficients
a_k: b_0 = a_n and b_k = b_(k-1) z + a_(n-k). -/
def hornerSums {R : Type*} [CommRing R] (p : R[X]) (n : ℕ) (z : R) : ℕ → R
  | 0 => p.coeff n
  | k + 1 => hornerSums p n z k * z + p.coeff (n - (k + 1))

/-- The size Σ_k |a_k| |x|^k of p at x: every coefficient and every power taken in absolute
value. It is the bottom of the backward-error formula. -/
noncomputable def absSum (p : ℂ[X]) (x : ℂ) : ℝ :=
  ∑ k ∈ Finset.range (p.natDegree + 1), ‖p.coeff k‖ * ‖x‖ ^ k

/-- Helper: the first k + 1 Horner steps as a polynomial identity. -/
theorem hornerSums_partial {R : Type*} [CommRing R] (p : R[X]) (n : ℕ) (z : R) (k : ℕ) :
    ∑ i ∈ Finset.range (k + 1), C (p.coeff (n - i)) * X ^ (k - i) =
      (X - C z) * (∑ i ∈ Finset.range k, C (hornerSums p n z i) * X ^ (k - 1 - i)) +
        C (hornerSums p n z k) := by
  induction k with
  | zero => simp [hornerSums]
  | succ k ih =>
    have hsplit : ∑ i ∈ Finset.range (k + 1), C (hornerSums p n z i) * X ^ (k + 1 - 1 - i) =
        X * ∑ i ∈ Finset.range k, C (hornerSums p n z i) * X ^ (k - 1 - i) +
          C (hornerSums p n z k) := by
      rw [Finset.sum_range_succ, Finset.mul_sum]
      congr 1
      · refine Finset.sum_congr rfl fun i hi => ?_
        rw [Finset.mem_range] at hi
        rw [show k + 1 - 1 - i = (k - 1 - i) + 1 by omega, pow_succ]
        ring
      · simp
    have hlhs : ∑ i ∈ Finset.range (k + 1 + 1), C (p.coeff (n - i)) * X ^ (k + 1 - i) =
        X * ∑ i ∈ Finset.range (k + 1), C (p.coeff (n - i)) * X ^ (k - i) +
          C (p.coeff (n - (k + 1))) := by
      rw [Finset.sum_range_succ, Finset.mul_sum]
      congr 1
      · refine Finset.sum_congr rfl fun i hi => ?_
        rw [Finset.mem_range] at hi
        rw [show k + 1 - i = (k - i) + 1 by omega, pow_succ]
        ring
      · simp
    rw [hlhs, hsplit, ih, hornerSums]
    simp only [map_add, map_mul]
    ring

#print axioms hornerSums_partial

/-- The companion matrix's eigenvalues are the roots. For any nonzero polynomial p with leading
coefficient a_n, the companion matrix C has characteristic polynomial det(xI - C) = p(x)/a_n, so
a number is an eigenvalue of C exactly when it is a root of p. -/
theorem companion_charpoly_and_eigenvalues {K : Type*} [Field K] (p : K[X]) (hp : p ≠ 0) :
    (companion p).charpoly = C p.leadingCoeff⁻¹ * p ∧
      ∀ μ : K, μ ∈ spectrum K (companion p) ↔ p.IsRoot μ := by
  have hlc : p.leadingCoeff ≠ 0 := leadingCoeff_ne_zero.mpr hp
  let b : Module.Basis (Fin p.natDegree) K (AdjoinRoot p) := AdjoinRoot.powerBasisAux hp
  have hb : ∀ i : Fin p.natDegree, b i = AdjoinRoot.root p ^ (i : ℕ) := by
    intro i; exact (AdjoinRoot.powerBasis hp).basis_eq_pow i
  have hroot : AdjoinRoot.root p ^ p.natDegree =
      ∑ i : Fin p.natDegree, (-p.coeff i / p.leadingCoeff) • b i := by
    have h0 : aeval (AdjoinRoot.root p) p = 0 := by
      rw [AdjoinRoot.aeval_eq, AdjoinRoot.mk_self]
    rw [aeval_eq_sum_range, Finset.sum_range_succ] at h0
    simp_rw [hb]
    rw [Fin.sum_univ_eq_sum_range (fun i => (-p.coeff i / p.leadingCoeff) • AdjoinRoot.root p ^ i)]
    have h1 : p.leadingCoeff • AdjoinRoot.root p ^ p.natDegree =
        -∑ i ∈ Finset.range p.natDegree, p.coeff i • AdjoinRoot.root p ^ i :=
      eq_neg_of_add_eq_zero_right h0
    calc AdjoinRoot.root p ^ p.natDegree
        = p.leadingCoeff⁻¹ • (p.leadingCoeff • AdjoinRoot.root p ^ p.natDegree) := by
          rw [smul_smul, inv_mul_cancel₀ hlc, one_smul]
      _ = _ := by
          rw [h1, smul_neg, Finset.smul_sum, ← Finset.sum_neg_distrib]
          refine Finset.sum_congr rfl fun i _ => ?_
          rw [smul_smul, ← neg_smul]
          congr 1
          field_simp
  have hmat : companion p = Matrix.transpose
      (Matrix.reindex Fin.revPerm Fin.revPerm (Algebra.leftMulMatrix b (AdjoinRoot.root p))) := by
    ext i j
    rw [Matrix.transpose_apply, Matrix.reindex_apply, Matrix.submatrix_apply,
      Algebra.leftMulMatrix_eq_repr_mul, Fin.revPerm_symm]
    simp only [companion, Matrix.of_apply, Fin.revPerm_apply, hb]
    rw [← pow_succ']
    have hi := i.isLt
    have hj := j.isLt
    rw [Fin.val_rev]
    by_cases h0 : (i : ℕ) = 0
    · simp only [h0, ↓reduceIte]
      rw [show p.natDegree - (0 + 1) + 1 = p.natDegree by omega, hroot,
        b.repr_sum_self, Fin.val_rev]
      congr 3
      omega
    · simp only [h0, ↓reduceIte]
      have hk : p.natDegree - ((i : ℕ) + 1) + 1 < p.natDegree := by omega
      rw [show AdjoinRoot.root p ^ (p.natDegree - ((i : ℕ) + 1) + 1) = b ⟨_, hk⟩ from
        (hb ⟨_, hk⟩).symm, b.repr_self, Finsupp.single_apply]
      simp only [Fin.ext_iff, Fin.val_rev]
      split_ifs <;> first | rfl | omega
  have hchar : (companion p).charpoly = C p.leadingCoeff⁻¹ * p := by
    rw [hmat, Matrix.charpoly_transpose, Matrix.charpoly_reindex]
    have := charpoly_leftMulMatrix (AdjoinRoot.powerBasis hp)
    rw [AdjoinRoot.powerBasis_gen, AdjoinRoot.minpoly_root hp] at this
    rw [mul_comm]
    exact this
  refine ⟨hchar, fun μ => ?_⟩
  rw [Matrix.mem_spectrum_iff_isRoot_charpoly, hchar, IsRoot, IsRoot, eval_mul, eval_C,
    mul_eq_zero, inv_eq_zero]
  simp [hlc]

/-- Horner's partial sums are synthetic division. For a polynomial p of degree at most n and any
point z, the partial sums b_0, ..., b_(n-1) are the coefficients of the quotient after dividing
by x - z, and the last one, b_n, is the remainder, which is p(z):
p(x) = (x - z)(b_0 x^(n-1) + ... + b_(n-1)) + b_n. -/
theorem horner_partial_sums_divide {R : Type*} [CommRing R] (p : R[X]) (n : ℕ)
    (hn : p.natDegree ≤ n) (z : R) :
    p = (X - C z) * (∑ k ∈ Finset.range n, C (hornerSums p n z k) * X ^ (n - 1 - k)) +
        C (hornerSums p n z n) ∧
      hornerSums p n z n = p.eval z := by
  have hp : p = ∑ i ∈ Finset.range (n + 1), C (p.coeff (n - i)) * X ^ (n - i) := by
    conv_lhs => rw [p.as_sum_range_C_mul_X_pow' (Nat.lt_succ_of_le hn)]
    rw [← Finset.sum_range_reflect]
    refine Finset.sum_congr rfl fun i _ => ?_
    have h : n.succ - 1 - i = n - i := by omega
    rw [h]
  have key := hp.trans (hornerSums_partial p n z n)
  refine ⟨key, ?_⟩
  have := congrArg (eval z) key
  simp only [eval_add, eval_mul, eval_sub, eval_X, eval_C, sub_self, zero_mul, zero_add] at this
  exact this.symm

/-- The backward error of a computed root is exactly |p(x̂)| / Σ|a_k||x̂|^k. No smaller relative
change works: if x̂ is a root of p + δp with every |δa_k| ≤ η|a_k|, then |p(x̂)| ≤ η Σ|a_k||x̂|^k.
And that value works: some change with |δa_k| = |a_k| |p(x̂)| / Σ|a_k||x̂|^k for every k makes x̂
an exact root of p + δp. -/
theorem backward_error_of_computed_root (p : ℂ[X]) (x : ℂ) :
    (∀ (η : ℝ) (δp : ℂ[X]), (∀ k, ‖δp.coeff k‖ ≤ η * ‖p.coeff k‖) → (p + δp).IsRoot x →
        ‖p.eval x‖ ≤ η * absSum p x) ∧
      ∃ δp : ℂ[X], (∀ k, ‖δp.coeff k‖ = ‖p.coeff k‖ * ‖p.eval x‖ / absSum p x) ∧
        (p + δp).IsRoot x := by
  have hS0 : 0 ≤ absSum p x := Finset.sum_nonneg fun k _ => by positivity
  have hle : ‖p.eval x‖ ≤ absSum p x := by
    rw [eval_eq_sum_range]
    refine (norm_sum_le _ _).trans (le_of_eq ?_)
    simp [absSum, norm_pow]
  constructor
  · intro η δp hδ hroot
    have hdeg : δp.natDegree < p.natDegree + 1 := by
      rw [Nat.lt_succ_iff, natDegree_le_iff_coeff_eq_zero]
      intro k hk
      have hk' : p.coeff k = 0 := coeff_eq_zero_of_natDegree_lt (by exact_mod_cast hk)
      have := hδ k
      rw [hk', norm_zero, mul_zero] at this
      exact norm_le_zero_iff.mp this
    have h1 : p.eval x = -δp.eval x := by
      rw [IsRoot, eval_add] at hroot
      exact eq_neg_of_add_eq_zero_left hroot
    rw [h1, norm_neg, eval_eq_sum_range' hdeg]
    calc ‖∑ k ∈ Finset.range (p.natDegree + 1), δp.coeff k * x ^ k‖
        ≤ ∑ k ∈ Finset.range (p.natDegree + 1), ‖δp.coeff k * x ^ k‖ := norm_sum_le _ _
      _ = ∑ k ∈ Finset.range (p.natDegree + 1), ‖δp.coeff k‖ * ‖x‖ ^ k := by
          simp [norm_pow]
      _ ≤ ∑ k ∈ Finset.range (p.natDegree + 1), η * ‖p.coeff k‖ * ‖x‖ ^ k :=
          Finset.sum_le_sum fun k _ => mul_le_mul_of_nonneg_right (hδ k) (by positivity)
      _ = η * absSum p x := by
          rw [absSum, Finset.mul_sum]
          simp only [mul_assoc]
  · set S := absSum p x with hSdef
    let u : ℂ := if x = 0 then 1 else (starRingEnd ℂ x) / (‖x‖ : ℂ)
    have hu : ‖u‖ = 1 := by
      by_cases hx : x = 0
      · simp [u, hx]
      · have : ‖x‖ ≠ 0 := norm_ne_zero_iff.mpr hx
        simp [u, hx, this]
    have hux : u * x = (‖x‖ : ℂ) := by
      by_cases hx : x = 0
      · simp [u, hx]
      · have : (‖x‖ : ℂ) ≠ 0 := by exact_mod_cast norm_ne_zero_iff.mpr hx
        simp only [u, hx, ↓reduceIte]
        rw [div_mul_eq_mul_div, Complex.conj_mul']
        field_simp
    let c : ℂ := -(p.eval x / (S : ℂ))
    refine ⟨∑ k ∈ Finset.range (p.natDegree + 1), C (c * (‖p.coeff k‖ : ℂ) * u ^ k) * X ^ k,
      fun k => ?_, ?_⟩
    · simp only [finsetSum_coeff, coeff_C_mul_X_pow]
      rw [Finset.sum_ite_eq]
      split_ifs with hk
      · rw [norm_mul, norm_mul, norm_pow, hu, one_pow, mul_one]
        simp only [c, norm_neg, norm_div, Complex.norm_real, Real.norm_of_nonneg hS0,
          Complex.norm_real, norm_norm]
        ring
      · rw [Finset.mem_range, not_lt] at hk
        rw [coeff_eq_zero_of_natDegree_lt (by omega)]
        simp
    · rw [IsRoot, eval_add, eval_finsetSum]
      simp only [eval_mul, eval_C, eval_pow, eval_X]
      have hsum : ∑ k ∈ Finset.range (p.natDegree + 1), c * (‖p.coeff k‖ : ℂ) * u ^ k * x ^ k =
          c * (S : ℂ) := by
        rw [hSdef, absSum, Complex.ofReal_sum, Finset.mul_sum]
        refine Finset.sum_congr rfl fun k _ => ?_
        rw [mul_assoc, mul_assoc, ← mul_pow, hux]
        push_cast
        ring
      rw [hsum]
      by_cases hS : S = 0
      · have he : p.eval x = 0 := norm_le_zero_iff.mp (hS ▸ hle)
        simp [c, he]
      · have : (S : ℂ) ≠ 0 := by exact_mod_cast hS
        simp only [c]
        field_simp
        ring

/-- The lease: $10,000 paid now, rents $1,500, $2,000, $2,000, $2,500, $2,500, $1,500 over six
years, all moved to year 6 with growth factor x. -/
noncomputable def leaseP : ℚ[X] :=
  10000 * X ^ 6 - 1500 * X ^ 5 - 2000 * X ^ 4 - 2000 * X ^ 3 - 2500 * X ^ 2 - 2500 * X - 1500

-- Horner by hand at x = 1.05 = 21/20: partial sums 10000, 9000, 7450, 5822.5, 3613.625,
-- 1294.30625, and p(1.05) = -140.9784375.
example : (10000 : ℚ) * (21 / 20) - 1500 = 9000 := by norm_num
example : (9000 : ℚ) * (21 / 20) - 2000 = 7450 := by norm_num
example : (7450 : ℚ) * (21 / 20) - 2000 = 11645 / 2 := by norm_num
example : (11645 / 2 : ℚ) * (21 / 20) - 2500 = 28909 / 8 := by norm_num
example : (28909 / 8 : ℚ) * (21 / 20) - 2500 = 207089 / 160 := by norm_num
example : (207089 / 160 : ℚ) * (21 / 20) - 1500 = -451131 / 3200 := by norm_num

-- The same value straight from the polynomial: p(1.05) = -140.9784375.
example : leaseP.eval (21 / 20) = -451131 / 3200 := by
  norm_num [leaseP]

-- The slope p'(1.05) = 43834.596875.
example : (derivative leaseP).eval (21 / 20) = 14027071 / 320 := by
  norm_num [leaseP]

-- At a 0% rate the rents beat the price by $2,000: p(1) = -2000.
example : leaseP.eval 1 = -2000 := by
  norm_num [leaseP]

-- The companion matrix's top row for the lease: 0.15, 0.20, 0.20, 0.25, 0.25, 0.15, and the sum
-- and product of the roots, -a_5/a_6 = 0.15 and a_0/a_6 = -0.15.
example : ((-(-1500 : ℚ) / 10000, -(-2000 : ℚ) / 10000, -(-2500 : ℚ) / 10000, -(-1500 : ℚ) / 10000)
    = (3 / 20, 1 / 5, 1 / 4, 3 / 20)) := by norm_num
example : (-1500 : ℚ) / 10000 = -3 / 20 := by norm_num

-- Wilkinson's polynomial (x - 1)(x - 2)...(x - 20): the x^19 coefficient is -(1 + 2 + ... + 20)
-- = -210 and the constant is 20! = 2432902008176640000.
example : ∑ k ∈ Finset.range 20, (k + 1) = 210 := by decide
example : (∏ k ∈ Finset.range 20, (X - C ((k : ℤ) + 1))).eval 0 = 2432902008176640000 := by
  norm_num [eval_prod, Finset.prod_range_succ]

#print axioms companion_charpoly_and_eigenvalues
#print axioms horner_partial_sums_divide
#print axioms backward_error_of_computed_root
