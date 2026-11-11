-- Solving A x = b: for a square matrix of real numbers, independent columns give exactly one answer for every b, dependent columns give a whole infinite set of answers when b is a mix of the columns and no answer when it is not, two different answers always force a line of answers, and for 2 by 2 the columns test ad - bc says which case you are in.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.LinearIndependent.Basic
import Mathlib.LinearAlgebra.Span.Basic
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.LinearAlgebra.Finsupp.LinearCombination

open Matrix

/-- Helper: A x is the mix of the columns of A with weights x. -/
theorem mulVec_eq_sum_columns_helper {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (x : Fin n → ℝ) :
    A *ᵥ x = ∑ j, x j • (fun i => A i j) := by
  ext i
  simp [Matrix.mulVec, dotProduct, Finset.sum_apply, mul_comm]

#print axioms mulVec_eq_sum_columns_helper

/-- The columns settle the case before b is read. Take any square matrix A of real numbers, of
any size n, and write column j of A as the list (A 0 j, A 1 j, ...). If the columns are
independent, then for every list of totals b there is exactly one x with A x = b. If the columns
are dependent, then for every b: when b is a mix of the columns (in their span) the answers to
A x = b are infinitely many, and when b is not a mix of the columns there is no answer at all. -/
theorem columns_decide_one_none_or_infinitely_many_answers {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) :
    (LinearIndependent ℝ (fun j : Fin n => fun i => A i j) →
        ∀ b : Fin n → ℝ, ∃! x : Fin n → ℝ, A *ᵥ x = b) ∧
      (¬ LinearIndependent ℝ (fun j : Fin n => fun i => A i j) →
        ∀ b : Fin n → ℝ,
          (b ∈ Submodule.span ℝ (Set.range (fun j : Fin n => fun i => A i j)) →
              {x : Fin n → ℝ | A *ᵥ x = b}.Infinite) ∧
            (b ∉ Submodule.span ℝ (Set.range (fun j : Fin n => fun i => A i j)) →
              {x : Fin n → ℝ | A *ᵥ x = b} = ∅)) := by
  constructor
  · intro hli b
    have hinj : Function.Injective A.mulVec := by
      intro x y hxy
      have h0 : A *ᵥ (x - y) = 0 := by rw [mulVec_sub, hxy, sub_self]
      rw [Fintype.linearIndependent_iff] at hli
      funext j
      exact sub_eq_zero.mp
        (hli (x - y) (by rw [← mulVec_eq_sum_columns_helper]; exact h0) j)
    have hsurj : Function.Surjective A.mulVec :=
      mulVec_surjective_iff_isUnit.2 (mulVec_injective_iff_isUnit.1 hinj)
    obtain ⟨x, hx⟩ := hsurj b
    exact ⟨x, hx, fun y hy => hinj (hy.trans hx.symm)⟩
  · intro hli b
    rw [Fintype.not_linearIndependent_iff] at hli
    obtain ⟨g, hg, j0, hj0⟩ := hli
    have hker : A *ᵥ g = 0 := by rw [mulVec_eq_sum_columns_helper]; exact hg
    constructor
    · intro hb
      obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp hb
      have hc' : A *ᵥ c = b := by rw [mulVec_eq_sum_columns_helper]; exact hc
      apply Set.infinite_of_injective_forall_mem (f := fun t : ℝ => c + t • g)
      · intro s t hst
        have h := congrFun hst j0
        simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, add_right_inj] at h
        exact mul_right_cancel₀ hj0 h
      · intro t
        simp only [Set.mem_ofPred_eq]
        rw [mulVec_add, mulVec_smul, hker, smul_zero, add_zero, hc']
    · intro hb
      ext x
      simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
      intro hx
      apply hb
      rw [← hx, mulVec_eq_sum_columns_helper]
      exact Submodule.sum_mem _
        (fun j _ => Submodule.smul_mem _ _ (Submodule.subset_span ⟨j, rfl⟩))

/-- No fourth outcome. For any matrix A of real numbers (m rows, n columns) and any totals b,
if two different lists x and x' both satisfy A x = b, then the columns of A are dependent, and
adding any multiple t of the difference x' - x to x gives another answer: a whole line of
answers. -/
theorem two_answers_force_a_line_of_answers {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (b : Fin m → ℝ) (x x' : Fin n → ℝ) (hx : A *ᵥ x = b) (hx' : A *ᵥ x' = b) (hne : x ≠ x') :
    ¬ LinearIndependent ℝ (fun j : Fin n => fun i => A i j) ∧
      ∀ t : ℝ, A *ᵥ (x + t • (x' - x)) = b := by
  have hne' : x' - x ≠ 0 := sub_ne_zero.mpr hne.symm
  have hker : A *ᵥ (x' - x) = 0 := by rw [mulVec_sub, hx, hx', sub_self]
  constructor
  · intro hli
    rw [Fintype.linearIndependent_iff] at hli
    apply hne'
    funext j
    exact hli (x' - x) (by rw [← mulVec_eq_sum_columns_helper]; exact hker) j
  · intro t
    rw [mulVec_add, mulVec_smul, hker, smul_zero, add_zero, hx]

/-- The columns test for 2 by 2. The two columns of a 2 by 2 real matrix are independent exactly
when top-left times bottom-right, minus top-right times bottom-left, is not zero. -/
theorem columns_test_two_by_two (A : Matrix (Fin 2) (Fin 2) ℝ) :
    LinearIndependent ℝ (fun j : Fin 2 => fun i => A i j) ↔
      A 0 0 * A 1 1 - A 0 1 * A 1 0 ≠ 0 := by
  rw [Fintype.linearIndependent_iff]
  constructor
  · intro h hdet
    have key : ∀ g : Fin 2 → ℝ, g 0 * A 0 0 + g 1 * A 0 1 = 0 →
        g 0 * A 1 0 + g 1 * A 1 1 = 0 → g 0 = 0 ∧ g 1 = 0 := by
      intro g h0 h1
      have hz := h g (by
        funext i
        fin_cases i <;> simp [Fin.sum_univ_two] <;> linarith)
      exact ⟨hz 0, hz 1⟩
    by_cases hc : A 1 0 = 0 ∧ A 1 1 = 0
    · by_cases ha : A 0 0 = 0 ∧ A 0 1 = 0
      · have := key ![1, 0] (by simp [ha.1, ha.2]) (by simp [hc.1, hc.2])
        simp at this
      · have := key ![A 0 1, -A 0 0] (by simp; ring) (by simp; linarith)
        exact ha ⟨by simpa using this.2, by simpa using this.1⟩
    · have := key ![A 1 1, -A 1 0] (by simp; linarith) (by simp; ring)
      exact hc ⟨by simpa using this.2, by simpa using this.1⟩
  · intro hdet g hg i
    have h0 := congrFun hg 0
    have h1 := congrFun hg 1
    simp [Fin.sum_univ_two] at h0 h1
    have e0 : g 0 * (A 0 0 * A 1 1 - A 0 1 * A 1 0) = 0 := by
      linear_combination A 1 1 * h0 - A 0 1 * h1
    have e1 : g 1 * (A 0 0 * A 1 1 - A 0 1 * A 1 0) = 0 := by
      linear_combination (-A 1 0) * h0 + A 0 0 * h1
    fin_cases i
    · exact (mul_eq_zero.1 e0).resolve_right hdet
    · exact (mul_eq_zero.1 e1).resolve_right hdet

-- The cafe: [[2, 1], [1, 1]] times (4, 3) is (11, 7), a $4 coffee and a $3 pastry.
example : !![(2 : ℝ), 1; 1, 1] *ᵥ ![4, 3] = ![11, 7] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- And it is the only pair that fits: 2x + y = 11 and x + y = 7 force x = 4 and y = 3.
example (x y : ℝ) (h1 : 2 * x + y = 11) (h2 : x + y = 7) : x = 4 ∧ y = 3 := by
  constructor <;> linarith
-- The columns test: 2 x 1 - 1 x 1 = 1 for the cafe, 2 x 2 - 1 x 4 = 0 for the doubled Tuesday.
example : (2 : ℝ) * 1 - 1 * 1 = 1 ∧ (2 : ℝ) * 2 - 1 * 4 = 0 := by norm_num
-- The doubled Tuesday [[2, 1], [4, 2]] with takings (11, 22): (0, 11), (2, 7), (4, 3) and (5, 1)
-- all fit.
example : !![(2 : ℝ), 1; 4, 2] *ᵥ ![0, 11] = ![11, 22] ∧
    !![(2 : ℝ), 1; 4, 2] *ᵥ ![2, 7] = ![11, 22] ∧
    !![(2 : ℝ), 1; 4, 2] *ᵥ ![4, 3] = ![11, 22] ∧
    !![(2 : ℝ), 1; 4, 2] *ᵥ ![5, 1] = ![11, 22] := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
    (ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two])
-- The free direction (1, -2), one more coffee and two fewer pastries, changes no total.
example : !![(2 : ℝ), 1; 4, 2] *ᵥ ![1, -2] = ![0, 0] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- With takings (11, 23) no prices fit: twice Monday's row is 22, not 23.
example : ∀ v : Fin 2 → ℝ, !![(2 : ℝ), 1; 4, 2] *ᵥ v ≠ ![11, 23] := by
  intro v h
  have h0 := congrFun h 0
  have h1 := congrFun h 1
  norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two] at h0 h1
  linarith
-- The mistake of feeding the totals in the wrong order, b = (7, 11), gives (-4, 15).
example : !![(2 : ℝ), 1; 1, 1] *ᵥ ![-4, 15] = ![7, 11] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]

#print axioms columns_decide_one_none_or_infinitely_many_answers
#print axioms two_answers_force_a_line_of_answers
#print axioms columns_test_two_by_two
