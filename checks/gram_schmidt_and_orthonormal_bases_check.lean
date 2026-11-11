-- Gram-Schmidt: the card's loop turns any independent list of real vectors into perpendicular unit directions that reach the same points, every point they reach is the sum of its dot products with them, a leftover is zero exactly when the line was already a mix of the finished directions, a square matrix with such columns has Qᵀ Q = I, and the card's survey numbers come out as it says.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Orthonormal
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.InnerProductSpace.GramSchmidtOrtho

open RealInnerProductSpace

/-! A point with `m` real entries is `EuclideanSpace ℝ (Fin m)`, where `⟪x, y⟫` is the ordinary
dot product (multiply matching entries, add) and `‖x‖` is the square root of `⟪x, x⟫`. A list of
`n` survey lines, in a fixed order, is a function `a : Fin n → EuclideanSpace ℝ (Fin m)`: `a 0`
is the first line, `a 1` the second. `Finset.Iio k` is the set of positions before `k`.
"Perpendicular and one unit long" is Mathlib's `Orthonormal ℝ q`, and "the points a list
reaches" is `Submodule.span ℝ (Set.range a)`. -/

/-- Helper: for orthonormal `q`, the leftover vanishes exactly on the span. -/
theorem gs_helper_leftover_iff {m k : ℕ}
    (q : Fin k → EuclideanSpace ℝ (Fin m)) (hq : Orthonormal ℝ q)
    (v : EuclideanSpace ℝ (Fin m)) :
    v - ∑ j, ⟪v, q j⟫ • q j = 0 ↔ v ∈ Submodule.span ℝ (Set.range q) := by
  constructor
  · intro h
    rw [sub_eq_zero.mp h]
    exact Submodule.sum_mem _ fun j _ =>
      Submodule.smul_mem _ _ (Submodule.subset_span ⟨j, rfl⟩)
  · intro h
    obtain ⟨c, rfl⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp h
    rw [sub_eq_zero]
    congr 1
    funext j
    rw [hq.inner_left_fintype]
    simp

/-- Helper: the card's loop produces exactly Mathlib's normalized Gram-Schmidt vectors. -/
theorem gs_helper_loop_eq {m n : ℕ}
    (a q : Fin n → EuclideanSpace ℝ (Fin m))
    (h_loop : ∀ k, q k =
      ‖a k - ∑ j ∈ Finset.Iio k, ⟪a k, q j⟫ • q j‖⁻¹ •
        (a k - ∑ j ∈ Finset.Iio k, ⟪a k, q j⟫ • q j)) :
    ∀ k, q k = InnerProductSpace.gramSchmidtNormed ℝ a k := by
  intro k
  induction k using WellFoundedLT.induction with
  | _ k ih =>
    have hsum : ∑ j ∈ Finset.Iio k, ⟪a k, q j⟫ • q j =
        a k - InnerProductSpace.gramSchmidt ℝ a k := by
      conv_rhs => rw [InnerProductSpace.gramSchmidt_def'' ℝ a k]
      rw [add_sub_cancel_left]
      refine Finset.sum_congr rfl fun j hj => ?_
      rw [ih j (Finset.mem_Iio.mp hj), InnerProductSpace.gramSchmidtNormed]
      set g := InnerProductSpace.gramSchmidt ℝ a j
      simp only [RCLike.ofReal_real_eq_id, id, inner_smul_right, smul_smul, real_inner_comm]
      congr 1
      field_simp
    rw [h_loop k, hsum, sub_sub_cancel, InnerProductSpace.gramSchmidtNormed]
    simp

#print axioms gs_helper_leftover_iff
#print axioms gs_helper_loop_eq

/-- Gram-Schmidt straightens a skewed basis, and coordinates become dot products. Take an
independent list of lines `a` with real entries, all the same size, in a fixed order. Run the
card's loop: the next direction `q k` is the leftover `a k − (a k · q j) q j − …`, one shadow
taken off for every direction `q j` already finished, divided by its length. Then the directions
are perpendicular and one unit long, they reach exactly the points the original lines reach,
and every such point `b` is `(b · q 0) q 0 + (b · q 1) q 1 + …`. -/
theorem gram_schmidt_straightens_and_coordinates_are_dot_products {m n : ℕ}
    (a q : Fin n → EuclideanSpace ℝ (Fin m))
    (h_indep : LinearIndependent ℝ a)
    (h_loop : ∀ k, q k =
      ‖a k - ∑ j ∈ Finset.Iio k, ⟪a k, q j⟫ • q j‖⁻¹ •
        (a k - ∑ j ∈ Finset.Iio k, ⟪a k, q j⟫ • q j)) :
    Orthonormal ℝ q ∧
      Submodule.span ℝ (Set.range q) = Submodule.span ℝ (Set.range a) ∧
      ∀ b ∈ Submodule.span ℝ (Set.range a), b = ∑ i, ⟪b, q i⟫ • q i := by
  have hq : q = InnerProductSpace.gramSchmidtNormed ℝ a := funext (gs_helper_loop_eq a q h_loop)
  have hon : Orthonormal ℝ q := hq ▸ InnerProductSpace.gramSchmidtNormed_orthonormal h_indep
  have hspan : Submodule.span ℝ (Set.range q) = Submodule.span ℝ (Set.range a) := by
    rw [hq, InnerProductSpace.span_gramSchmidtNormed_range, InnerProductSpace.span_gramSchmidt]
  refine ⟨hon, hspan, fun b hb => ?_⟩
  rw [← hspan] at hb
  exact (sub_eq_zero.mp ((gs_helper_leftover_iff q hon b).mpr hb))

/-- A zero leftover means a mix. Take finished directions `q`, perpendicular and one unit long,
and a further line `v` of the same size. The leftover `v − (v · q 0) q 0 − (v · q 1) q 1 − …`
is the zero vector exactly when `v` is already a mix of those directions. -/
theorem leftover_is_zero_iff_line_is_a_mix {m k : ℕ}
    (q : Fin k → EuclideanSpace ℝ (Fin m)) (hq : Orthonormal ℝ q)
    (v : EuclideanSpace ℝ (Fin m)) :
    v - ∑ j, ⟪v, q j⟫ • q j = 0 ↔ v ∈ Submodule.span ℝ (Set.range q) := by
  exact gs_helper_leftover_iff q hq v

/-- The orthogonal matrix. Put `n` directions with `n` real entries each, perpendicular and one
unit long, side by side as the columns of a square matrix `Q`. Then `Q` with rows and columns
swapped, times `Q`, is the identity: 1s on the diagonal, 0s elsewhere. -/
theorem orthonormal_columns_give_transpose_times_Q_identity {n : ℕ}
    (q : Fin n → EuclideanSpace ℝ (Fin n)) (hq : Orthonormal ℝ q) :
    (Matrix.of fun i j => q j i).transpose * Matrix.of (fun i j => q j i) = 1 := by
  ext i j
  rw [Matrix.mul_apply, Matrix.one_apply]
  have h := (orthonormal_iff_ite.mp hq) i j
  rw [PiLp.inner_apply] at h
  simpa [mul_comm] using h

-- The survey lines a1 = (3, 1), a2 = (2, 2): a1 · a1 = 10, a2 · a1 = 8, lengths squared 10 and 8.
example : (3 : ℤ) * 3 + 1 * 1 = 10 ∧ (2 : ℤ) * 3 + 2 * 1 = 8 ∧ (2 : ℤ) * 2 + 2 * 2 = 8 := by
  norm_num
-- The shadow of a2 on a1 is (8/10)(3, 1) = (12/5, 4/5); the leftover is (2, 2) minus it,
-- (-2/5, 6/5), which is 2/5 of (-1, 3); its length squared is 8/5.
example : (8 / 10 : ℚ) * 3 = 12 / 5 ∧ (8 / 10 : ℚ) * 1 = 4 / 5 ∧
    (2 : ℚ) - 12 / 5 = -2 / 5 ∧ (2 : ℚ) - 4 / 5 = 6 / 5 ∧
    (-2 / 5 : ℚ) = 2 / 5 * (-1) ∧ (6 / 5 : ℚ) = 2 / 5 * 3 ∧
    (-2 / 5 : ℚ) ^ 2 + (6 / 5) ^ 2 = 8 / 5 := by
  norm_num
-- q1 = (3, 1)/√10 and q2 = (-1, 3)/√10: (3, 1) · (-1, 3) = 0, and both have length squared 10,
-- so dividing each by √10 gives length 1.
example : (3 : ℤ) * (-1) + 1 * 3 = 0 ∧ (-1 : ℤ) * (-1) + 3 * 3 = 10 := by norm_num
-- Q^T Q = I, scaled by 10: the columns (3, 1) and (-1, 3) give 10 times the identity.
example : (!![3, 1; -1, 3] : Matrix (Fin 2) (Fin 2) ℤ) * !![3, -1; 1, 3] = !![10, 0; 0, 10] := by
  decide
-- det Q = (3 × 3 − (-1) × 1)/10 = 1; the quarter turn 0 × 0 − (-1) × 1 = 1; the flip
-- 1 × (-1) − 0 × 0 = -1; doubling one axis and halving the other, 2 × 1/2 − 0 × 0 = 1.
example : ((3 : ℚ) * 3 - (-1) * 1) / 10 = 1 ∧ (0 : ℤ) * 0 - (-1) * 1 = 1 ∧
    (1 : ℤ) * (-1) - 0 * 0 = -1 ∧ (2 : ℚ) * (1 / 2) - 0 * 0 = 1 := by
  norm_num
-- The stake b = (4, 2): b · (3, 1) = 14 and b · (-1, 3) = 2, so c1 = 14/√10 and c2 = 2/√10;
-- rebuilt, (14/10)(3, 1) + (2/10)(-1, 3) = (4, 2), and c1² + c2² = 196/10 + 4/10 = 20 = b · b.
example : (4 : ℤ) * 3 + 2 * 1 = 14 ∧ (4 : ℤ) * (-1) + 2 * 3 = 2 ∧
    (14 / 10 : ℚ) * 3 + 2 / 10 * (-1) = 4 ∧ (14 / 10 : ℚ) * 1 + 2 / 10 * 3 = 2 ∧
    (196 / 10 : ℚ) + 4 / 10 = 20 ∧ (4 : ℤ) * 4 + 2 * 2 = 20 := by
  norm_num
-- The raw lines, solved: 3x + 2y = 4 and x + 2y = 2 give x = 1, y = 1/2.
example : (3 : ℚ) * 1 + 2 * (1 / 2) = 4 ∧ (1 : ℚ) + 2 * (1 / 2) = 2 := by norm_num
-- Mistake, no divide by a1 · a1: (2, 2) − 8 × (3, 1) = (-22, -6).
example : (![2, 2] : Fin 2 → ℤ) - (8 : ℤ) • ![3, 1] = ![-22, -6] := by decide
-- Mistake, never scaled: (b · a1) a1 + (b · leftover) leftover, with b · leftover = 4/5,
-- is (42, 14) + (4/5)(-2/5, 6/5) = (1042/25, 374/25), not (4, 2).
example : (4 : ℚ) * (-2 / 5) + 2 * (6 / 5) = 4 / 5 ∧
    (14 : ℚ) * 3 + 4 / 5 * (-2 / 5) = 1042 / 25 ∧ (14 : ℚ) * 1 + 4 / 5 * (6 / 5) = 374 / 25 := by
  norm_num
-- Mistake, (6, 2) second: (6, 2) · (3, 1) = 20, so the shadow takes 20/10 = 2 of (3, 1), and (6, 2) − 2 × (3, 1) = (0, 0).
example : (6 : ℤ) * 3 + 2 * 1 = 20 ∧ (![6, 2] : Fin 2 → ℤ) - (2 : ℤ) • ![3, 1] = ![0, 0] := by
  decide
-- Swap the order: start from (2, 2), direction (1, 1)/√2; (3, 1) · (1, 1) = 4 and 4/2 = 2,
-- so the leftover is (3, 1) − 2 × (1, 1) = (1, -1), and the pair is (1, 1)/√2 and (1, -1)/√2.
example : (3 : ℤ) * 1 + 1 * 1 = 4 ∧ (![3, 1] : Fin 2 → ℤ) - (2 : ℤ) • ![1, 1] = ![1, -1] := by
  decide
-- The stake moved to (6, 2): (6, 2) · (-1, 3) = 0, so its second coordinate is 0.
example : (6 : ℤ) * (-1) + 2 * 3 = 0 := by norm_num
-- The mast (1, 1, 1): (1, 1, 1) − (4/10)(3, 1, 0) − (2/10)(-1, 3, 0) = (0, 0, 1), already length 1.
example : (1 : ℚ) - 4 / 10 * 3 - 2 / 10 * (-1) = 0 ∧ (1 : ℚ) - 4 / 10 * 1 - 2 / 10 * 3 = 0 ∧
    (1 : ℚ) - 4 / 10 * 0 - 2 / 10 * 0 = 1 := by
  norm_num

#print axioms gram_schmidt_straightens_and_coordinates_are_dot_products
#print axioms leftover_is_zero_iff_line_is_a_mix
#print axioms orthonormal_columns_give_transpose_times_Q_identity
