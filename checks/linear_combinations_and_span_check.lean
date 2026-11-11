-- Linear combinations and span: two vectors in the plane reach every point exactly when their cross-number is not zero, the mixes of any list of vectors form the smallest subspace holding them, and the lawn target (14, 21) is reached by bags A and B but not by bags A and C.
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Module.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.Finsupp.LinearCombination
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-! A vector with two slots is a function `Fin 2 → ℝ`: `a 0` is its first slot and `a 1` its
second, and `![10, 5]` is the pair (10, 5). Amounts are real numbers, so fractions and negatives
are allowed. Mathlib's `Submodule.span ℝ s` is the span of the set `s`, and `⊤` is the whole
space. A list of `k` vectors is a function `v : Fin k → V`, and a mix of them with amounts
`c : Fin k → ℝ` is `∑ i, c i • v i`. -/

/-- The cross-number test. Two vectors `a` and `b` with two slots each, mixed with any real
amounts, reach every point of the plane exactly when their cross-number, the first slot of `a`
times the second slot of `b` minus the first slot of `b` times the second slot of `a`, is not
zero. -/
theorem two_vectors_span_plane_iff_cross_number_ne_zero (a b : Fin 2 → ℝ) :
    Submodule.span ℝ ({a, b} : Set (Fin 2 → ℝ)) = ⊤ ↔ a 0 * b 1 - b 0 * a 1 ≠ 0 := by
  constructor
  · intro h
    have h0 : (Pi.single 0 1 : Fin 2 → ℝ) ∈ Submodule.span ℝ ({a, b} : Set (Fin 2 → ℝ)) := by
      rw [h]; exact Submodule.mem_top
    have h1 : (Pi.single 1 1 : Fin 2 → ℝ) ∈ Submodule.span ℝ ({a, b} : Set (Fin 2 → ℝ)) := by
      rw [h]; exact Submodule.mem_top
    rw [Submodule.mem_span_pair] at h0 h1
    obtain ⟨x, y, hxy⟩ := h0
    obtain ⟨z, w, hzw⟩ := h1
    have e1 := congrFun hxy 0
    have e2 := congrFun hxy 1
    have e3 := congrFun hzw 0
    have e4 := congrFun hzw 1
    simp at e1 e2 e3 e4
    intro hd
    have : (a 0 * b 1 - b 0 * a 1) * (x * w - y * z) = 1 := by
      linear_combination (z * a 1 + w * b 1) * e1 + e4 - (x * a 1 + y * b 1) * e3
    rw [hd] at this
    norm_num at this
  · intro hd
    rw [eq_top_iff]
    intro v _
    rw [Submodule.mem_span_pair]
    refine ⟨(v 0 * b 1 - b 0 * v 1) / (a 0 * b 1 - b 0 * a 1),
      (a 0 * v 1 - v 0 * a 1) / (a 0 * b 1 - b 0 * a 1), ?_⟩
    refine funext (Fin.forall_fin_two.mpr ⟨?_, ?_⟩)
    · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, div_eq_iff hd]
      ring
    · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, div_eq_iff hd]
      ring

/-- A span always closes up. For any list of vectors in any real vector space, the set of all
their mixes (every choice of real amounts, scaled and added up) is a subspace, it is the span
of the list, and it is the smallest subspace holding the vectors: any subspace holding every
vector of the list holds every mix of them. -/
theorem mixes_form_smallest_subspace {V : Type*} [AddCommGroup V] [Module ℝ V] {k : ℕ}
    (v : Fin k → V) :
    ((Submodule.span ℝ (Set.range v) : Set V) = {t | ∃ c : Fin k → ℝ, ∑ i, c i • v i = t}) ∧
      ∀ W : Submodule ℝ V, (∀ i, v i ∈ W) → ∀ c : Fin k → ℝ, ∑ i, c i • v i ∈ W := by
  refine ⟨?_, ?_⟩
  · ext t
    rw [SetLike.mem_coe, Submodule.mem_span_range_iff_exists_fun]
    rfl
  · intro W hW c
    exact Submodule.sum_mem _ fun i _ => W.smul_mem _ (hW i)

/-- The card's bags. With bag A = (10, 5) and bag B = (2, 8), both the lawn target (14, 21)
and the target (14, 22) are in the span. Paired with bag C = (20, 10), two bags of A, the span
shrinks to a line and (14, 21) is out of reach. -/
theorem lawn_target_in_span_of_A_and_B_not_of_A_and_C :
    (![14, 21] : Fin 2 → ℝ) ∈ Submodule.span ℝ ({![10, 5], ![2, 8]} : Set (Fin 2 → ℝ)) ∧
    (![14, 22] : Fin 2 → ℝ) ∈ Submodule.span ℝ ({![10, 5], ![2, 8]} : Set (Fin 2 → ℝ)) ∧
    (![14, 21] : Fin 2 → ℝ) ∉ Submodule.span ℝ ({![10, 5], ![20, 10]} : Set (Fin 2 → ℝ)) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [Submodule.mem_span_pair]
    refine ⟨1, 2, ?_⟩
    funext i
    fin_cases i <;> norm_num
  · rw [Submodule.mem_span_pair]
    refine ⟨34 / 35, 15 / 7, ?_⟩
    funext i
    fin_cases i <;> norm_num
  · rw [Submodule.mem_span_pair]
    rintro ⟨x, y, hxy⟩
    have e1 := congrFun hxy 0
    have e2 := congrFun hxy 1
    simp at e1 e2
    linarith

-- One bag of A = (10, 5) and two bags of B = (2, 8) land exactly on the lawn target (14, 21).
example : (1 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (2 : ℤ) • ![2, 8] = ![14, 21] := by decide
-- The slot equations: nitrogen 10 × 1 + 2 × 2 = 14, phosphorus 5 × 1 + 8 × 2 = 21.
example : (10 : ℤ) * 1 + 2 * 2 = 14 ∧ (5 : ℤ) * 1 + 8 * 2 = 21 := by norm_num
-- The cross-number of A and B: 10 × 8 − 2 × 5 = 70.
example : (10 : ℤ) * 8 - 2 * 5 = 70 := by norm_num
-- Step 3: 5 × 14 = 70 and 10 × 21 = 210, then 70y = 210 − 70 = 140, so y = 2.
example : (5 : ℤ) * 14 = 70 ∧ (10 : ℤ) * 21 = 210 ∧ (80 : ℤ) - 10 = 70 ∧ (70 : ℤ) * 2 = 210 - 70 := by
  norm_num
-- The worked table: 7y = 21 − 7 = 14 gives y = 2, then x = (14 − 2 × 2) ÷ 10 = 1.
example : (7 : ℤ) * 2 = 21 - 7 ∧ ((14 : ℤ) - 2 * 2) / 10 = 1 := by norm_num
-- The cross-number rule numerators for (14, 21): 14 × 8 − 2 × 21 = 70 and 10 × 21 − 14 × 5 = 140.
example : (14 : ℤ) * 8 - 2 * 21 = 70 ∧ (10 : ℤ) * 21 - 14 * 5 = 140 := by norm_num
-- (14, 22): numerators 68 and 150 over 70, which is 34/35 of a bag of A and 15/7 bags of B.
example : (14 : ℤ) * 8 - 2 * 22 = 68 ∧ (10 : ℤ) * 22 - 14 * 5 = 150 := by norm_num
example : (68 / 70 : ℚ) = 34 / 35 ∧ (150 / 70 : ℚ) = 15 / 7 := by norm_num
example : (34 / 35 : ℚ) • (![10, 5] : Fin 2 → ℚ) + (15 / 7 : ℚ) • ![2, 8] = ![14, 22] := by
  ext i; fin_cases i <;> norm_num
-- With whole bags only, (14, 22) is not on the shelf: no whole amounts x and y reach it.
example : ¬ ∃ x y : ℤ, 10 * x + 2 * y = 14 ∧ 5 * x + 8 * y = 22 := by omega
-- One bag of A with 0, 1, 2 and 3 bags of B: nitrogen 10, 12, 14, 16 and phosphorus 5, 13, 21, 29.
example : (List.range 4).map (fun y : ℕ => (10 + 2 * y, 5 + 8 * y)) =
    [(10, 5), (12, 13), (14, 21), (16, 29)] := by decide
-- Bag C = (20, 10) is two bags of A, and the cross-number of A and C is 10 × 10 − 20 × 5 = 0.
example : (2 : ℤ) • (![10, 5] : Fin 2 → ℤ) = ![20, 10] := by decide
example : (10 : ℤ) * 10 - 20 * 5 = 0 := by norm_num
-- The mistakes: 7/5 of a bag of A alone gives (14, 7); one of each gives (12, 13);
-- two of A and one of B gives (22, 18).
example : (7 / 5 : ℚ) • (![10, 5] : Fin 2 → ℚ) = ![14, 7] := by
  ext i; fin_cases i <;> norm_num
example : (1 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (1 : ℤ) • ![2, 8] = ![12, 13] := by decide
example : (2 : ℤ) • (![10, 5] : Fin 2 → ℤ) + (1 : ℤ) • ![2, 8] = ![22, 18] := by decide

#print axioms two_vectors_span_plane_iff_cross_number_ne_zero
#print axioms mixes_form_smallest_subspace
#print axioms lawn_target_in_span_of_A_and_B_not_of_A_and_C
