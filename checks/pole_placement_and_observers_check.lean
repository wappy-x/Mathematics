-- Pole placement: a one-motor plant that can be steered has exactly one state-feedback gain giving any chosen characteristic polynomial, a one-reading plant that can be seen has an observer gain giving any chosen error polynomial, and the joined controller-observer loop has the product of the two polynomials.
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Mathlib.LinearAlgebra.Matrix.Nondegenerate
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Ring

open Polynomial Matrix

/-! The plant is `x' = A x + B u` with `n` states and one motor: `A` is `n × n` and the push
enters through the column `B`. A full-state gain is a row `K`, and the push `u = -K x` gives the
closed loop `A - B K`, where `B K` is the column-times-row matrix `Matrix.vecMulVec B K`.
Its poles are the roots of its characteristic polynomial `det (s I - (A - B K))`, Mathlib's
`Matrix.charpoly`. Choosing the poles in mirror pairs is the same as choosing a monic polynomial
of degree `n` with real coefficients. -/

/-- The controllability matrix `(B, A B, A² B, …, A^(n-1) B)`: column `j` is `A^j B`. -/
def controllabilityMatrix {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j => (A ^ (j : ℕ) *ᵥ B) i

/-- The observability matrix for one reading `y = C x`: row `i` is `C A^i`. -/
def observabilityMatrix {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (C : Fin n → ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j => (C ᵥ* A ^ (i : ℕ)) j

theorem adjvec_coeff_rec {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) (k : ℕ) :
    (fun i => ((adjugate (charmatrix A) *ᵥ (fun i => C (B i))) i).coeff k)
      = A *ᵥ (fun i => ((adjugate (charmatrix A) *ᵥ (fun i => C (B i))) i).coeff (k + 1))
        + (A.charpoly.coeff (k + 1)) • B := by
  set v := adjugate (charmatrix A) *ᵥ (fun i => C (B i)) with hv
  have h : charmatrix A *ᵥ v = A.charpoly • (fun i => C (B i)) := by
    rw [hv, mulVec_mulVec, mul_adjugate, smul_mulVec, one_mulVec]
    rfl
  funext i
  have hi := congrArg (fun p : ℝ[X] => p.coeff (k + 1)) (congrFun h i)
  simp only [mulVec, dotProduct, charmatrix_apply, diagonal_apply, sub_mul, ite_mul, zero_mul,
    Finset.sum_sub_distrib, Finset.sum_ite_eq, Finset.mem_univ, ite_true, Pi.smul_apply,
    smul_eq_mul, coeff_sub, coeff_X_mul, finsetSum_coeff, coeff_C_mul, coeff_mul_C] at hi
  simp only [mulVec, dotProduct, Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  linarith

#print axioms adjvec_coeff_rec

theorem det_add_vecMulVec_adj {R : Type*} [CommRing R] [IsDomain R] {n : ℕ}
    (M : Matrix (Fin n) (Fin n) R) (hM : M.det ≠ 0) (u w : Fin n → R) :
    (M + vecMulVec u w).det = M.det + w ⬝ᵥ (adjugate M *ᵥ u) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [dotProduct]
  have key : (M + vecMulVec u w) * adjugate M
      = Matrix.scalar (Fin n) M.det - vecMulVec (-u) (w ᵥ* adjugate M) := by
    rw [Matrix.add_mul, mul_adjugate, vecMulVec_mul]
    ext i j
    simp [vecMulVec_apply, Matrix.scalar_apply, Matrix.smul_one_eq_diagonal]
  have h2 := congrArg Matrix.det key
  rw [det_mul, det_adjugate, ← eval_charpoly, charpoly_vecMulVec] at h2
  simp only [Fintype.card_fin, eval_sub, eval_pow, eval_X, eval_smul, smul_eq_mul] at h2
  have hpow : M.det ^ n = M.det * M.det ^ (n - 1) := by
    rw [← pow_succ']; congr 1; omega
  have hdot : (-u) ⬝ᵥ (w ᵥ* adjugate M) = -(w ⬝ᵥ (adjugate M *ᵥ u)) := by
    rw [neg_dotProduct, dotProduct_comm, ← dotProduct_mulVec]
  rw [hpow, hdot] at h2
  have hne : M.det ^ (n - 1) ≠ 0 := pow_ne_zero _ hM
  apply mul_right_cancel₀ hne
  rw [h2]; ring

#print axioms det_add_vecMulVec_adj

theorem charmatrix_sub_vecMulVec {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B K : Fin n → ℝ) :
    charmatrix (A - vecMulVec B K)
      = charmatrix A + vecMulVec (fun i => C (B i)) (fun i => C (K i)) := by
  ext i j
  simp [charmatrix_apply, vecMulVec_apply]
  ring

#print axioms charmatrix_sub_vecMulVec

theorem charpoly_sub_vecMulVec {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B K : Fin n → ℝ) :
    (A - vecMulVec B K).charpoly
      = A.charpoly + (fun i => C (K i)) ⬝ᵥ (adjugate (charmatrix A) *ᵥ (fun i => C (B i))) := by
  rw [charpoly, charmatrix_sub_vecMulVec, det_add_vecMulVec_adj]
  · rfl
  · exact (charpoly_monic A).ne_zero

#print axioms charpoly_sub_vecMulVec

theorem adjvec_coeff_eq_zero {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) (k : ℕ)
    (hk : n ≤ k) :
    (fun i => ((adjugate (charmatrix A) *ᵥ (fun i => C (B i))) i).coeff k) = 0 := by
  set v := adjugate (charmatrix A) *ᵥ (fun i => C (B i)) with hv
  set N := (Finset.univ.sup fun i => (v i).natDegree) + 1
  have hN : ∀ m, N ≤ m → (fun i => (v i).coeff m) = 0 := by
    intro m hm
    funext i
    apply coeff_eq_zero_of_natDegree_lt
    have : (v i).natDegree ≤ Finset.univ.sup fun i => (v i).natDegree :=
      Finset.le_sup (f := fun i => (v i).natDegree) (Finset.mem_univ i)
    omega
  have hstep : ∀ m, n ≤ m → (fun i => (v i).coeff m) = A *ᵥ (fun i => (v i).coeff (m + 1)) := by
    intro m hm
    rw [adjvec_coeff_rec A B m]
    have : A.charpoly.coeff (m + 1) = 0 := by
      apply coeff_eq_zero_of_natDegree_lt
      rw [charpoly_natDegree_eq_dim, Fintype.card_fin]
      omega
    rw [this, zero_smul, add_zero]
  have hiter : ∀ d m, n ≤ m →
      (fun i => (v i).coeff m) = (A ^ d) *ᵥ (fun i => (v i).coeff (m + d)) := by
    intro d
    induction d with
    | zero => intro m _; simp
    | succ d ih =>
      intro m hm
      rw [ih m hm, hstep (m + d) (by omega), mulVec_mulVec, ← pow_succ, Nat.add_assoc]
  rw [hiter N k hk, hN (k + N) (by omega), mulVec_zero]

#print axioms adjvec_coeff_eq_zero

theorem adjvec_coeff_top {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ) (hn : 0 < n) :
    (fun i => ((adjugate (charmatrix A) *ᵥ (fun i => C (B i))) i).coeff (n - 1)) = B := by
  rw [adjvec_coeff_rec A B (n - 1), Nat.sub_add_cancel hn, adjvec_coeff_eq_zero A B n le_rfl,
    mulVec_zero, zero_add]
  have : A.charpoly.coeff n = 1 := by
    have h := (charpoly_monic A).coeff_natDegree
    rwa [charpoly_natDegree_eq_dim, Fintype.card_fin] at h
  rw [this, one_smul]

#print axioms adjvec_coeff_top

theorem adjvec_coeff_injective {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ)
    (hctrb : IsUnit (controllabilityMatrix A B).det) (K : Fin n → ℝ)
    (h : ∀ k < n, K ⬝ᵥ (fun i => ((adjugate (charmatrix A) *ᵥ (fun i => C (B i))) i).coeff k)
      = 0) : K = 0 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · funext i; exact Fin.elim0 i
  set v := adjugate (charmatrix A) *ᵥ (fun i => C (B i)) with hv
  have claim : ∀ i k, i ≤ k → k < n →
      K ⬝ᵥ (A ^ i *ᵥ (fun j => (v j).coeff k)) = 0 := by
    intro i
    induction i with
    | zero => intro k _ hk; simpa using h k hk
    | succ i ih =>
      intro k hik hk
      obtain ⟨k', rfl⟩ : ∃ k', k = k' + 1 := ⟨k - 1, by omega⟩
      have e1 := ih k' (by omega) (by omega)
      have e2 := ih (n - 1) (by omega) (by omega)
      rw [adjvec_coeff_top A B hn] at e2
      rw [adjvec_coeff_rec A B k', mulVec_add, mulVec_mulVec, ← pow_succ, mulVec_smul,
        dotProduct_add, dotProduct_smul, e2, smul_zero, add_zero] at e1
      exact e1
  apply eq_zero_of_vecMul_eq_zero hctrb.ne_zero
  funext j
  have := claim j (n - 1) (by omega) (by omega)
  rw [adjvec_coeff_top A B hn] at this
  simpa [vecMul, controllabilityMatrix, dotProduct] using this

#print axioms adjvec_coeff_injective

/-- The pole placement theorem, for one motor (Steps 0, 2 and 3). If every state is steerable
(the controllability matrix is invertible), then for every chosen monic real polynomial of
degree `n` there is exactly one gain `K` that makes it the characteristic polynomial of the
closed loop `A - B K`: the closed-loop poles go anywhere you choose (complex ones in mirror
pairs), and the gain that puts them there is unique. -/
theorem pole_placement_unique_gain {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Fin n → ℝ)
    (hctrb : IsUnit (controllabilityMatrix A B).det)
    (p : ℝ[X]) (hmonic : p.Monic) (hdeg : p.natDegree = n) :
    ∃! K : Fin n → ℝ, (A - Matrix.vecMulVec B K).charpoly = p := by
  set v := adjugate (charmatrix A) *ᵥ (fun i => C (B i)) with hv
  have hcoeff : ∀ (K : Fin n → ℝ) k,
      ((A - vecMulVec B K).charpoly).coeff k
        = A.charpoly.coeff k + K ⬝ᵥ (fun i => (v i).coeff k) := by
    intro K k
    rw [charpoly_sub_vecMulVec, coeff_add]
    simp [dotProduct, finsetSum_coeff, coeff_C_mul, v]
  set V : Matrix (Fin n) (Fin n) ℝ := Matrix.of fun i k => (v i).coeff (k : ℕ) with hVdef
  have hV : ∀ (K : Fin n → ℝ) (k : Fin n), (K ᵥ* V) k = K ⬝ᵥ (fun i => (v i).coeff k) := by
    intro K k; rfl
  have hinj : Function.Injective (Matrix.vecMulLinear V) := by
    intro K₁ K₂ hK
    have h0 : K₁ - K₂ = 0 := by
      apply adjvec_coeff_injective A B hctrb
      intro k hk
      have := congrFun hK ⟨k, hk⟩
      simp only [vecMulLinear_apply, hV] at this
      rw [sub_dotProduct, this, sub_self]
    exact sub_eq_zero.mp h0
  obtain ⟨K, hK⟩ := LinearMap.injective_iff_surjective.mp hinj
    (fun k : Fin n => (p - A.charpoly).coeff k)
  have hdegA : A.charpoly.natDegree = n := by
    rw [charpoly_natDegree_eq_dim, Fintype.card_fin]
  have hKp : (A - Matrix.vecMulVec B K).charpoly = p := by
    ext k
    rw [hcoeff]
    by_cases hk : k < n
    · have := congrFun hK ⟨k, hk⟩
      simp only [vecMulLinear_apply, hV, coeff_sub] at this
      rw [this]; ring
    · rw [adjvec_coeff_eq_zero A B k (by omega), dotProduct_zero, add_zero]
      rcases Nat.lt_or_ge n k with hk' | hk'
      · rw [coeff_eq_zero_of_natDegree_lt (by omega), coeff_eq_zero_of_natDegree_lt (by omega)]
      · have hkn : k = n := by omega
        subst hkn
        have h1 := (charpoly_monic A).coeff_natDegree
        have h2 := hmonic.coeff_natDegree
        rw [hdegA] at h1
        rw [hdeg] at h2
        rw [h1, h2]
  refine ⟨K, hKp, ?_⟩
  intro K' hK'
  have h0 : K' - K = 0 := by
    apply adjvec_coeff_injective A B hctrb
    intro k _
    have e : ((A - vecMulVec B K').charpoly).coeff k = ((A - vecMulVec B K).charpoly).coeff k := by
      rw [hK', hKp]
    rw [hcoeff, hcoeff] at e
    rw [sub_dotProduct]
    linarith
  exact sub_eq_zero.mp h0

/-- Observer design by duality (Step 4), for one reading `y = C x`. If every state is seen
(the observability matrix is invertible), then for every chosen monic real polynomial of
degree `n` there is an observer gain `L` (a column) making it the characteristic polynomial of
the error dynamics `e' = (A - L C) e`: the observer's error poles go anywhere you choose. -/
theorem observer_poles_anywhere {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (C : Fin n → ℝ)
    (hobsv : IsUnit (observabilityMatrix A C).det)
    (p : ℝ[X]) (hmonic : p.Monic) (hdeg : p.natDegree = n) :
    ∃ L : Fin n → ℝ, (A - Matrix.vecMulVec L C).charpoly = p := by
  have hT : controllabilityMatrix Aᵀ C = (observabilityMatrix A C)ᵀ := by
    ext i j
    simp [controllabilityMatrix, observabilityMatrix, ← transpose_pow, mulVec_transpose]
  have hc : IsUnit (controllabilityMatrix Aᵀ C).det := by
    rwa [hT, det_transpose]
  obtain ⟨L, hL, -⟩ := pole_placement_unique_gain Aᵀ C hc p hmonic hdeg
  refine ⟨L, ?_⟩
  rw [← charpoly_transpose, transpose_sub, transpose_vecMulVec]
  exact hL

/-- Separation (Step 5). Any plant `x' = A x + B u` with readings `y = C x` (any number of
motors and readings), driven by `u = -K x̂` from the observer
`x̂' = A x̂ + B u + L (y - C x̂)`, is the joined loop
`(x, x̂)' = [[A, -B K], [L C, A - B K - L C]] (x, x̂)` in the original coordinates.
Its characteristic polynomial is exactly the controller's times the observer's, so its poles
are exactly both sets. -/
theorem separation_joined_loop_charpoly {n m q : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (B : Matrix (Fin n) (Fin m) ℝ) (C : Matrix (Fin q) (Fin n) ℝ)
    (K : Matrix (Fin m) (Fin n) ℝ) (L : Matrix (Fin n) (Fin q) ℝ) :
    (Matrix.fromBlocks A (-(B * K)) (L * C) (A - B * K - L * C)).charpoly
      = (A - B * K).charpoly * (A - L * C).charpoly := by
  set T : Matrix (Fin n ⊕ Fin n) (Fin n ⊕ Fin n) ℝ := fromBlocks 1 0 1 (-1) with hTdef
  set M := Matrix.fromBlocks A (-(B * K)) (L * C) (A - B * K - L * C)
  have hT : T * T = 1 := by
    rw [hTdef, fromBlocks_multiply, ← fromBlocks_one]
    congr 1 <;> simp
  have hN : T * M * T = fromBlocks (A - B * K) (B * K) 0 (A - L * C) := by
    simp only [M, hTdef, fromBlocks_multiply]
    congr 1 <;> simp <;> abel
  have : M.charpoly = (T * M * T).charpoly := by
    rw [Matrix.mul_assoc, charpoly_mul_comm, Matrix.mul_assoc, hT, Matrix.mul_one]
  rw [this, hN, charpoly_fromBlocks_zero₂₁]

/-! The card's whole-number worked numbers, exactly. -/

-- Open loop: the cart gives s² and the rod s² − 16, so the poles are 0, 0, +4 and −4.
example : ((X : ℤ[X]) ^ 2 * (X ^ 2 - 16)) = X ^ 2 * (X - 4) * (X + 4) := by ring
-- Slow pair −3 ± 3j: (s + 3)² + 9 = s² + 6s + 18.
example : ((X + 3 : ℤ[X]) ^ 2 + 9) = X ^ 2 + 6 * X + 18 := by ring
-- Fast pair −6 ± 6j: (s + 6)² + 36 = s² + 12s + 72.
example : ((X + 6 : ℤ[X]) ^ 2 + 36) = X ^ 2 + 12 * X + 72 := by ring
-- Δc, the product: coefficients 18, 162, 648, 1296.
example : ((X ^ 2 + 6 * X + 18 : ℤ[X]) * (X ^ 2 + 12 * X + 72))
    = X ^ 4 + 18 * X ^ 3 + 162 * X ^ 2 + 648 * X + 1296 := by ring
-- k₁ = −a₀/16 = −81 and k₂ = −a₁/16 = −40.5 = −81/2.
example : -(1296 : ℚ) / 16 = -81 := by norm_num
example : -(648 : ℚ) / 16 = -81 / 2 := by norm_num
-- k₃ and k₄ before dividing by c: k₁ − 16 − a₂ = −259 and k₂ − a₃ = −58.5 = −117/2.
example : (-81 : ℚ) - 16 - 162 = -259 := by norm_num
example : (-81 / 2 : ℚ) - 18 = -117 / 2 := by norm_num
-- The rod alone with k_θ = 32, k_ω = 8: θ'' = (16 − 32) θ − 8 ω has polynomial (s + 4)².
example : (!![0, 1; 16 - 32, -8] : Matrix (Fin 2) (Fin 2) ℤ).charpoly = (X + 4) ^ 2 := by
  rw [charpoly_fin_two]
  simp [Matrix.trace_fin_two, Matrix.det_fin_two]
  ring
-- Observer, cart: A − L C = [[−20, 1], [−100, 0]] with (ℓ₁, ℓ₂) = (20, 100) gives (s + 10)².
example : (!![0 - 20, 1; 0 - 100, 0] : Matrix (Fin 2) (Fin 2) ℤ).charpoly = (X + 10) ^ 2 := by
  rw [charpoly_fin_two]
  simp [Matrix.trace_fin_two, Matrix.det_fin_two]
  ring
-- Observer, rod: A − L C = [[−20, 1], [16 − 116, 0]] with (ℓ₁, ℓ₂) = (20, 116) gives (s + 10)².
example : (!![0 - 20, 1; 16 - 116, 0] : Matrix (Fin 2) (Fin 2) ℤ).charpoly = (X + 10) ^ 2 := by
  rw [charpoly_fin_two]
  simp [Matrix.trace_fin_two, Matrix.det_fin_two]
  ring
-- Joined loop: (s + 10)⁴ has s³ coefficient 40, so the s⁷ coefficient is 18 + 40 = 58.
example : ((X + 10 : ℤ[X]) ^ 4) = X ^ 4 + 40 * X ^ 3 + 600 * X ^ 2 + 4000 * X + 10000 := by ring
example : (18 : ℤ) + 40 = 58 := by norm_num

#print axioms pole_placement_unique_gain
#print axioms observer_poles_anywhere
#print axioms separation_joined_loop_charpoly
