-- Linear independence: a list of vectors has a mix with amounts not all zero landing on the zero vector exactly when one of its vectors is a mix of the others, independence means only the all-zero mix lands there, two vectors in the plane are independent exactly when their cross-number is not zero, and the card's fertiliser numbers come out as it says.
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Algebra.Module.Pi
import Mathlib.Algebra.Field.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FinCases

/-! A list of `n` vectors is a function `v : Fin n → V`: `v 0` is the first vector, `v 1` the
second, and so on. All of them live in the same space `V`, so they have the same slots in the
same order. A mix gives each vector an amount `c i` from a field `K` (so amounts may be negative
or fractions) and adds up `∑ i, c i • v i`. "One vector is a mix of the others" is Mathlib's
`v i ∈ Submodule.span K (v '' {j | j ≠ i})`: `v i` lies in the span of the rest of the list.
A point of the plane is a list of two numbers, `Fin 2 → K`, and `![10, 5]` is the pair (10, 5). -/

/-- Dependence means redundancy. For any list of vectors, with amounts that may be negative or
fractions: some mix with amounts not all zero lands on the zero vector exactly when one of the
vectors is already a mix of the others. -/
theorem dependent_iff_one_vector_is_a_mix_of_the_rest {K V : Type*} [Field K] [AddCommGroup V]
    [Module K V] {n : ℕ} (v : Fin n → V) :
    (∃ c : Fin n → K, ∑ i, c i • v i = 0 ∧ ∃ i, c i ≠ 0) ↔
      ∃ i, v i ∈ Submodule.span K (v '' {j | j ≠ i}) := by
  have hs : ∀ i : Fin n, ({j | j ≠ i} : Set (Fin n)) = Set.univ \ {i} := by
    intro i; ext j; simp
  rw [← Fintype.not_linearIndependent_iff, linearIndependent_iff_notMem_span]
  simp only [not_forall, not_not, hs]

/-- The card's definition is Mathlib's. A list of vectors is linearly independent exactly when
the only mix of them landing on the zero vector is the one that uses zero of everything. -/
theorem independent_iff_only_the_zero_mix_lands_on_zero {K V : Type*} [Field K] [AddCommGroup V]
    [Module K V] {n : ℕ} (v : Fin n → V) :
    LinearIndependent K v ↔ ∀ c : Fin n → K, ∑ i, c i • v i = 0 → ∀ i, c i = 0 := by
  exact Fintype.linearIndependent_iff

/-- The two-vector shortcut. Two vectors `u` and `w` of the plane are linearly independent
exactly when their cross-number, first slot times the other's second slot minus the other way
round, is not zero. -/
theorem two_vectors_independent_iff_cross_number_ne_zero {K : Type*} [Field K]
    (u w : Fin 2 → K) :
    LinearIndependent K ![u, w] ↔ u 0 * w 1 - w 0 * u 1 ≠ 0 := by
  rw [LinearIndependent.pair_iff]
  constructor
  · intro h hd
    by_cases h1 : w 1 = 0 ∧ u 1 = 0
    · by_cases h0 : w 0 = 0 ∧ u 0 = 0
      · have hu : u = 0 := by
          funext k; fin_cases k
          · simpa using h0.2
          · simpa using h1.2
        have := h 1 0 (by simp [hu])
        exact one_ne_zero this.1
      · have := h (w 0) (-u 0) (by
          funext k; fin_cases k
          · simp; ring
          · simp [h1.1, h1.2])
        apply h0
        exact ⟨this.1, neg_eq_zero.mp this.2⟩
    · have := h (w 1) (-u 1) (by
        funext k; fin_cases k
        · simp; linear_combination hd
        · simp; ring)
      exact h1 ⟨this.1, neg_eq_zero.mp this.2⟩
  · intro hd s t hst
    have e0 := congrFun hst 0
    have e1 := congrFun hst 1
    simp at e0 e1
    constructor
    · have : s * (u 0 * w 1 - w 0 * u 1) = 0 := by
        linear_combination w 1 * e0 - w 0 * e1
      exact (mul_eq_zero.mp this).resolve_right hd
    · have : t * (u 0 * w 1 - w 0 * u 1) = 0 := by
        linear_combination u 0 * e1 - u 1 * e0
      exact (mul_eq_zero.mp this).resolve_right hd

-- The relation: one bag of A = (10, 5), plus one of B = (2, 8), minus one of C = (12, 13) is (0, 0).
example : (1 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (1 : ℤ) • ![2, 8] + (-1 : ℤ) • ![12, 13] = ![0, 0] := by
  decide
-- C is one bag of A plus one bag of B.
example : (![10, 5] : Fin 2 → ℤ) + ![2, 8] = ![12, 13] := by decide
-- The cross-numbers: A with B is 70, A with C is 70, B with C is -70.
example : (10 : ℤ) * 8 - 2 * 5 = 70 ∧ (10 : ℤ) * 13 - 12 * 5 = 70 ∧ (2 : ℤ) * 13 - 12 * 8 = -70 := by
  norm_num
-- The solve with z = -1: 10x + 2y = 12 and 5x + 8y = 13; doubling and subtracting gives
-- (16 - 2)y = 26 - 12, so 14y = 14, y = 1, and x = (12 - 2 × 1) ÷ 10 = 1.
example : (16 : ℤ) - 2 = 14 ∧ (26 : ℤ) - 12 = 14 ∧ (12 - 2 * 1 : ℤ) = 10 * 1 ∧
    (10 : ℤ) * 1 + 2 * 1 = 12 ∧ (5 : ℤ) * 1 + 8 * 1 = 13 := by
  norm_num
-- The two slot equations hold at x = 1, y = 1, z = -1.
example : (10 : ℤ) * 1 + 2 * 1 + 12 * (-1) = 0 ∧ (5 : ℤ) * 1 + 8 * 1 + 13 * (-1) = 0 := by
  norm_num
-- The mistakes: the all-zero mix gives (0, 0); all three bags added give (24, 26).
example : (0 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (0 : ℤ) • ![2, 8] + (0 : ℤ) • ![12, 13] = ![0, 0] := by
  decide
example : (![10, 5] : Fin 2 → ℤ) + ![2, 8] + ![12, 13] = ![24, 26] := by decide
-- The picture: t bags each of A and B with t of C taken back out leaves (0, 0); without C the
-- barrow holds 12t kg of nitrogen and 13t kg of phosphorus, for t = 0, 1, 2, 3.
example : ∀ t : Fin 4, (t : ℤ) • (![10, 5] : Fin 2 → ℤ) + (t : ℤ) • ![2, 8] + (-(t : ℤ)) • ![12, 13]
    = ![0, 0] := by
  decide
example : ∀ t : Fin 4, (t : ℤ) • (![10, 5] : Fin 2 → ℤ) + (t : ℤ) • ![2, 8]
    = ![12 * (t : ℤ), 13 * (t : ℤ)] := by
  decide
-- Try changing: with C = (12, 14) the relation is 34 A + 40 B - 35 C = (0, 0); with C = (20, 10)
-- it is 2 A - C = (0, 0), and the cross-number of A and C falls to 0.
example : (34 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (40 : ℤ) • ![2, 8] + (-35 : ℤ) • ![12, 14] = ![0, 0] := by
  decide
example : (2 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (-1 : ℤ) • ![20, 10] = ![0, 0] ∧
    (10 : ℤ) * 10 - 20 * 5 = 0 := by
  decide

#print axioms dependent_iff_one_vector_is_a_mix_of_the_rest
#print axioms independent_iff_only_the_zero_mix_lands_on_zero
#print axioms two_vectors_independent_iff_cross_number_ne_zero
