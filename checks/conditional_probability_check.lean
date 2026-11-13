-- Conditional probability: the chance of A given B is P(A and B) / P(B), the chance of both is P(B) times P(A given B), and the chance of A is the sum over a partition of piece size times rate in the piece.
import Mathlib.Probability.ConditionalProbability
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- The definition, read as a formula: for any probability `P` and events `A`, `B`
with `P(B) > 0`, the chance of `A` given `B` is the chance that both happen,
divided by the chance of `B`. -/
theorem cond_eq_inter_div {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {A B : Set Ω} (hA : MeasurableSet A) (hB : MeasurableSet B)
    (hpos : 0 < P B) :
    P[A | B] = P (A ∩ B) / P B := by
  rw [cond_apply hB, div_eq_mul_inv, mul_comm, Set.inter_comm]

/-- The multiplication rule: when `P(B) > 0`, the chance that both `A` and `B` happen
is the chance of `B` times the chance of `A` given `B`. -/
theorem inter_eq_mul_cond {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {A B : Set Ω} (hA : MeasurableSet A) (hB : MeasurableSet B)
    (hpos : 0 < P B) :
    P (A ∩ B) = P B * P[A | B] := by
  rw [Set.inter_comm, ← cond_mul_eq_inter hB A P, mul_comm]

/-- The law of total probability: if the pieces `B 0, ..., B (n-1)` do not overlap,
together cover every outcome, and each has positive chance, then the chance of `A`
is the sum of `P(B i) * P(A given B i)` over the pieces. -/
theorem total_probability {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n : ℕ} {A : Set Ω} (B : Fin n → Set Ω)
    (hA : MeasurableSet A) (hB : ∀ i, MeasurableSet (B i))
    (hdisj : Pairwise fun i j => Disjoint (B i) (B j))
    (hcover : (⋃ i, B i) = Set.univ)
    (hpos : ∀ i, 0 < P (B i)) :
    P A = ∑ i, P (B i) * P[A | B i] := by
  have hdisj' : Pairwise (Function.onFun Disjoint fun i => A ∩ B i) := by
    intro i j hij
    exact (hdisj hij).mono Set.inter_subset_right Set.inter_subset_right
  have hU : A = ⋃ i, A ∩ B i := by
    rw [← Set.inter_iUnion, hcover, Set.inter_univ]
  calc P A = P (⋃ i, A ∩ B i) := by rw [← hU]
    _ = ∑' i, P (A ∩ B i) := measure_iUnion hdisj' (fun i => hA.inter (hB i))
    _ = ∑ i, P (A ∩ B i) := tsum_fintype _
    _ = ∑ i, P (B i) * P[A | B i] := by
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [Set.inter_comm, ← cond_mul_eq_inter (hB i) A P, mul_comm]

/-! The town of 10,000: 100 sick, 90 of them positive; 9,900 healthy, 495 of them positive. -/

-- The positives: 90 sick plus 495 healthy.
example : 90 + 495 = 585 := by norm_num

-- Counting: 90 sick out of 585 positives is 2 in 13.
example : (90 : ℚ) / 585 = 2 / 13 := by norm_num

-- Healthy given positive, by counting and by the complement rule.
example : (495 : ℚ) / 585 = 1 - 2 / 13 := by norm_num

-- Multiplication rule: P(D) P(T | D) = 1/100 * 9/10 = 90 out of 10,000.
example : (1 / 100 : ℚ) * (9 / 10) = 90 / 10000 := by norm_num

-- Total probability: P(T) = 1/100 * 9/10 + 99/100 * 1/20 = 585 out of 10,000.
example : (1 / 100 : ℚ) * (9 / 10) + (99 / 100) * (1 / 20) = 585 / 10000 := by norm_num

-- The definition: P(D | T) = (90 / 10000) / (585 / 10000) = 2 / 13.
example : ((90 : ℚ) / 10000) / (585 / 10000) = 2 / 13 := by norm_num

-- The same answer by counting the town one resident at a time.
example : ((Finset.range 10000).filter (fun i => i < 90 ∨ (100 ≤ i ∧ i < 595))).card = 585 := by
  decide +kernel

#print axioms cond_eq_inter_div
#print axioms inter_eq_mul_cond
#print axioms total_probability
