-- Randomised SVD: for a basis Q with orthonormal columns, the error of Q times any small matrix C splits by Pythagoras into the projection error plus the error of C against Q-transpose A, so the projection is the best fit inside the span of Q, and a vector of independent standard normal draws has average squared image the squared Frobenius norm.
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum

open Matrix MeasureTheory ProbabilityTheory
open scoped Matrix.Norms.Frobenius

/-! ### How the card's objects are written here

The table `A` is an `m × n` real matrix, `A : Matrix (Fin m) (Fin n) ℝ`. The sketch basis `Q` is
`m × ℓ` with perpendicular unit columns, which is `Qᵀ * Q = 1`. The small matrix is
`B = Qᵀ * A`, and `Q * (Qᵀ * A)` is the projection `QQᵀA`. `‖·‖` on matrices is Mathlib's
Frobenius norm (root-sum-square of the entries), opened by `Matrix.Norms.Frobenius`.

A Gaussian test vector `ω : Fin n → ℝ` has independent standard normal entries: its law is
`Measure.pi (fun _ => gaussianReal 0 1)`. The squared length of `M ω` is written out as
`∑ i, (M *ᵥ ω) i ^ 2`. -/

/-! ### Helper lemmas -/

theorem frob_sq_eq_sum {m n : ℕ} (X : Matrix (Fin m) (Fin n) ℝ) :
    ‖X‖ ^ 2 = ∑ i, ∑ j, X i j ^ 2 := by
  rw [frobenius_norm_def, ← Real.sqrt_eq_rpow, Real.sq_sqrt (by positivity)]
  simp [Real.norm_eq_abs, sq_abs]

theorem frob_sq_eq_trace {m n : ℕ} (X : Matrix (Fin m) (Fin n) ℝ) :
    ‖X‖ ^ 2 = trace (Xᵀ * X) := by
  rw [frob_sq_eq_sum, Finset.sum_comm]
  simp only [trace, diag]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [Matrix.mul_apply]
  simp [sq]

theorem gaussian_second_moment : ∫ x, x * x ∂(gaussianReal 0 1) = 1 := by
  have h := variance_fun_id_gaussianReal (μ := 0) (v := 1)
  rw [variance_eq_integral measurable_id'.aemeasurable] at h
  simpa [sq] using h

theorem gaussian_pair_moment {n : ℕ} (j k : Fin n) :
    Integrable (fun ω : Fin n → ℝ => ω j * ω k) (Measure.pi fun _ => gaussianReal 0 1) ∧
    ∫ ω, ω j * ω k ∂(Measure.pi fun _ : Fin n => gaussianReal 0 1) = if j = k then 1 else 0 := by
  let f : Fin n → ℝ → ℝ := fun i x => (if i = j then x else 1) * (if i = k then x else 1)
  have hprod : ∀ ω : Fin n → ℝ, ∏ i, f i (ω i) = ω j * ω k := by
    intro ω
    simp only [f, Finset.prod_mul_distrib, Finset.prod_ite_eq', Finset.mem_univ, ite_true]
  have hint1 : Integrable (fun x : ℝ => x) (gaussianReal 0 1) :=
    memLp_one_iff_integrable.mp (memLp_id_gaussianReal 1)
  have hint2 : Integrable (fun x : ℝ => x * x) (gaussianReal 0 1) := by
    simpa [sq] using (memLp_id_gaussianReal (μ := 0) (v := 1) 2).integrable_sq
  have hfi : ∀ i, Integrable (f i) (gaussianReal 0 1) := by
    intro i
    simp only [f]
    split_ifs <;> simp [hint1, hint2]
  refine ⟨?_, ?_⟩
  · have := Integrable.fintype_prod (μ := fun _ : Fin n => gaussianReal 0 1) hfi
    simpa [hprod] using this
  · have := integral_fintype_prod_eq_prod (μ := fun _ : Fin n => gaussianReal 0 1) f
    simp only [hprod] at this
    rw [this]
    split_ifs with hjk
    · subst hjk
      refine Finset.prod_eq_one fun i _ => ?_
      simp only [f]
      split_ifs <;> simp [gaussian_second_moment]
    · refine Finset.prod_eq_zero (Finset.mem_univ j) ?_
      simp [f, hjk]

#print axioms frob_sq_eq_sum
#print axioms frob_sq_eq_trace
#print axioms gaussian_second_moment
#print axioms gaussian_pair_moment

/-- The card's error split (Step 2). If `Q` has perpendicular unit columns (`QᵀQ = I`), then for
every small matrix `C` (in particular the rank-`k` truncation `B_k` of `B = QᵀA`) the error of the
lifted answer `QC` splits as the square of the part outside the span of `Q` plus the square of
the part inside it:
`‖A - QC‖_F² = ‖A - QQᵀA‖_F² + ‖QᵀA - C‖_F²`. -/
theorem range_finder_error_split {m n ℓ : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (Q : Matrix (Fin m) (Fin ℓ) ℝ) (hQ : Qᵀ * Q = 1)
    (C : Matrix (Fin ℓ) (Fin n) ℝ) :
    ‖A - Q * C‖ ^ 2 = ‖A - Q * (Qᵀ * A)‖ ^ 2 + ‖Qᵀ * A - C‖ ^ 2 := by
  set D := A - Q * (Qᵀ * A) with hD
  set E := Qᵀ * A - C with hE
  have hsplit : A - Q * C = D + Q * E := by
    simp only [hD, hE, Matrix.mul_sub]; abel
  have hQD : Qᵀ * D = 0 := by
    simp only [hD, Matrix.mul_sub, ← Matrix.mul_assoc, hQ, Matrix.one_mul, sub_self]
  have hDQ : Dᵀ * Q = 0 := by
    have := congrArg Matrix.transpose hQD
    simpa [Matrix.transpose_mul] using this
  rw [hsplit, frob_sq_eq_trace, frob_sq_eq_trace, frob_sq_eq_trace]
  rw [Matrix.transpose_add, Matrix.transpose_mul, Matrix.add_mul, Matrix.mul_add, Matrix.mul_add,
    trace_add, trace_add, trace_add]
  have h1 : Dᵀ * (Q * E) = 0 := by rw [← Matrix.mul_assoc, hDQ, Matrix.zero_mul]
  have h2 : Eᵀ * Qᵀ * D = 0 := by rw [Matrix.mul_assoc, hQD, Matrix.mul_zero]
  have h3 : Eᵀ * Qᵀ * (Q * E) = Eᵀ * E := by
    rw [Matrix.mul_assoc, ← Matrix.mul_assoc Qᵀ, hQ, Matrix.one_mul]
  rw [h1, h2, h3]
  simp

/-- The projection is the best fit inside the sketch's span (Step 2 and the deterministic proof of
Step 3). If `Q` has perpendicular unit columns, then `QQᵀA` is the closest matrix to `A` in the
Frobenius norm among all matrices `QC` whose columns lie in the span of `Q`. -/
theorem projection_is_best_in_span {m n ℓ : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (Q : Matrix (Fin m) (Fin ℓ) ℝ) (hQ : Qᵀ * Q = 1)
    (C : Matrix (Fin ℓ) (Fin n) ℝ) :
    ‖A - Q * (Qᵀ * A)‖ ≤ ‖A - Q * C‖ := by
  have h := range_finder_error_split A Q hQ C
  have h0 : ‖A - Q * (Qᵀ * A)‖ ^ 2 ≤ ‖A - Q * C‖ ^ 2 := by
    rw [h]; nlinarith [sq_nonneg ‖Qᵀ * A - C‖]
  exact (pow_le_pow_iff_left₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).mp h0

/-- The fact behind the a posteriori check (Step 5). For any matrix `M` and a test vector `ω` of
independent standard normal draws, the average of `‖Mω‖²` is exactly `‖M‖_F²`. -/
theorem gaussian_average_sq_norm_mulVec {m n : ℕ} (M : Matrix (Fin m) (Fin n) ℝ) :
    ∫ ω, ∑ i, (M *ᵥ ω) i ^ 2 ∂(Measure.pi fun _ : Fin n => gaussianReal 0 1) = ‖M‖ ^ 2 := by
  have hexp : ∀ ω : Fin n → ℝ, ∑ i, (M *ᵥ ω) i ^ 2 =
      ∑ i, ∑ j, ∑ k, (M i j * M i k) * (ω j * ω k) := by
    intro ω
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [mulVec, dotProduct, sq, Finset.sum_mul_sum]
    refine Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun k _ => ?_
    ring
  simp_rw [hexp]
  rw [integral_finsetSum _ fun i _ => integrable_finsetSum _ fun j _ =>
    integrable_finsetSum _ fun k _ => (gaussian_pair_moment j k).1.const_mul _]
  simp_rw [integral_finsetSum _ fun j _ =>
    integrable_finsetSum _ fun k _ => (gaussian_pair_moment j k).1.const_mul _]
  simp_rw [integral_finsetSum _ fun k _ => (gaussian_pair_moment _ k).1.const_mul _]
  simp_rw [integral_const_mul, (gaussian_pair_moment _ _).2]
  rw [frob_sq_eq_sum]
  simp [mul_ite, sq]

/-! ### The card's whole-number and exact worked numbers -/

-- One product with the 2,000 by 500 table and a sketch of width 15: 15,000,000 multiplications.
example : 2000 * 500 * 15 = 15000000 := by norm_num

-- Two products for q = 0, four for q = 1.
example : 2 * 15000000 = 30000000 ∧ 4 * 15000000 = 60000000 := by norm_num

-- The dense SVD's leading term m n²: 500,000,000 multiplications, 50/3 (about 16.7) times more.
example : 2000 * 500 ^ 2 = 500000000 := by norm_num
example : ((2000 * 500 ^ 2 : ℕ) : ℚ) / 30000000 = 50 / 3 := by norm_num

-- The squared bound factors at k = 10: 1 + k/(p-1) = 7/2 at p = 5 (so the factor is sqrt 3.5),
-- and 2 + k/(p-1) = 9/2 (so sqrt 4.5) for the rank-10 answer.
example : (1 : ℚ) + 10 / (5 - 1) = 7 / 2 ∧ (2 : ℚ) + 10 / (5 - 1) = 9 / 2 := by norm_num

-- The same squared factor at p = 2, 10, 20: 11, 19/9, 29/19.
example : (1 : ℚ) + 10 / (2 - 1) = 11 ∧ (1 : ℚ) + 10 / (10 - 1) = 19 / 9 ∧
    (1 : ℚ) + 10 / (20 - 1) = 29 / 19 := by norm_num

-- σ₁₁ = 0.8^10 exactly.
example : (4 / 5 : ℚ) ^ 10 = 1048576 / 9765625 := by norm_num

-- The size of the whole table as the card sums it: 1 + 0.64 + 0.64² + ... = 1/(1 - 0.64) = 25/9.
example : ∑' j : ℕ, (16 / 25 : ℝ) ^ j = 25 / 9 := by
  rw [tsum_geometric_of_lt_one (by norm_num) (by norm_num)]
  norm_num

#print axioms range_finder_error_split
#print axioms projection_is_best_in_span
#print axioms gaussian_average_sq_norm_mulVec
