-- Order statistics: for n independent draws from one law with cumulative chance F, the k-th smallest is at most x with chance equal to the binomial tail, so the largest has law F(x)^n and the smallest 1 - (1 - F(x))^n.
import Mathlib.Data.Fin.Tuple.Sort
import Mathlib.Probability.CDF
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open MeasureTheory ProbabilityTheory

/-- The k-th smallest of the n values `x 0, ..., x (n-1)`, for a rank `k` from 1 to n:
sort the values from smallest to largest (Mathlib's `Tuple.sort`, ties allowed) and take
place `k` of the sorted list. Rank 1 is the smallest and rank n the largest. -/
noncomputable def kthSmallest {n : ℕ} (x : Fin n → ℝ) (k : ℕ) (hk1 : 1 ≤ k) (hkn : k ≤ n) : ℝ :=
  x (Tuple.sort x ⟨k - 1, by omega⟩)

/-- Helper: the counting form of a rank question (used by the main theorem). -/
theorem os_helper_count {n : ℕ} (x : Fin n → ℝ) (k : ℕ) (hk1 : 1 ≤ k) (hkn : k ≤ n)
    (t : ℝ) :
    kthSmallest x k hk1 hkn ≤ t ↔ k ≤ (Finset.univ.filter (fun i => x i ≤ t)).card := by
  classical
  unfold kthSmallest
  set σ := Tuple.sort x
  have hmono : Monotone (x ∘ σ) := Tuple.monotone_sort x
  have hcard : (Finset.univ.filter (fun i => x i ≤ t)).card
      = (Finset.univ.filter (fun j => x (σ j) ≤ t)).card := by
    refine Finset.card_bij' (fun i _ => σ.symm i) (fun j _ => σ j) ?_ ?_ ?_ ?_ <;> simp
  rw [hcard]
  set m : Fin n := ⟨k - 1, by omega⟩
  constructor
  · intro h
    have hsub : Finset.Iic m ⊆ Finset.univ.filter (fun j => x (σ j) ≤ t) := by
      intro j hj
      simp only [Finset.mem_Iic] at hj
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      exact le_trans (hmono hj) h
    have := Finset.card_le_card hsub
    rw [Fin.card_Iic] at this
    simp only [m] at this
    omega
  · intro h
    by_contra hlt
    push Not at hlt
    have hsub : Finset.univ.filter (fun j => x (σ j) ≤ t) ⊆ Finset.Iio m := by
      intro j hj
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hj
      simp only [Finset.mem_Iio]
      by_contra hge
      push Not at hge
      have := hmono hge
      simp only [Function.comp] at this
      linarith
    have := Finset.card_le_card hsub
    rw [Fin.card_Iio] at this
    simp only [m] at this
    omega

/-- Helper: the event "exactly the draws in S are at most x" as an intersection. -/
theorem os_helper_set {Ω : Type*} {n : ℕ} (X : Fin n → Ω → ℝ) (x : ℝ) (S : Finset (Fin n)) :
    {ω | Finset.univ.filter (fun i => X i ω ≤ x) = S} =
      ⋂ i ∈ (Finset.univ : Finset (Fin n)),
        X i ⁻¹' (if i ∈ S then Set.Iic x else Set.Ioi x) := by
  classical
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_iInter, Finset.mem_univ, Set.mem_preimage, forall_const]
  rw [Finset.ext_iff]
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  apply forall_congr'
  intro i
  split_ifs with h <;> simp [h]

/-- Helper: that event is measurable. -/
theorem os_helper_meas {Ω : Type*} [MeasurableSpace Ω] {n : ℕ} (X : Fin n → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i)) (x : ℝ) (S : Finset (Fin n)) :
    MeasurableSet {ω | Finset.univ.filter (fun i => X i ω ≤ x) = S} := by
  rw [os_helper_set]
  refine Finset.measurableSet_biInter _ (fun i _ => hmeas i ?_)
  split_ifs
  · exact measurableSet_Iic
  · exact measurableSet_Ioi

/-- Helper: the chance that exactly the draws in S are at most x. -/
theorem os_helper_fiber {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n : ℕ} (X : Fin n → Ω → ℝ) (μ : Measure ℝ)
    [IsProbabilityMeasure μ] (hmeas : ∀ i, Measurable (X i)) (hindep : iIndepFun X P)
    (hlaw : ∀ i, P.map (X i) = μ) (x : ℝ) (S : Finset (Fin n)) :
    P.real {ω | Finset.univ.filter (fun i => X i ω ≤ x) = S} =
      cdf μ x ^ S.card * (1 - cdf μ x) ^ (n - S.card) := by
  classical
  have hms : ∀ i : Fin n, MeasurableSet (if i ∈ S then Set.Iic x else Set.Ioi x) := by
    intro i
    split_ifs
    · exact measurableSet_Iic
    · exact measurableSet_Ioi
  have hprob : ∀ i, P.real (X i ⁻¹' (if i ∈ S then Set.Iic x else Set.Ioi x)) =
      if i ∈ S then cdf μ x else 1 - cdf μ x := by
    intro i
    rw [← map_measureReal_apply (hmeas i) (hms i), hlaw i]
    split_ifs
    · rw [cdf_eq_real]
    · rw [← Set.compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic, cdf_eq_real]
  rw [os_helper_set, measureReal_def,
    hindep.measure_inter_preimage_eq_mul _ (fun i _ => hms i), ENNReal.toReal_prod]
  simp_rw [← measureReal_def, hprob]
  rw [Finset.prod_ite]
  simp only [Finset.prod_const]
  congr 2
  · congr 1
    ext i
    simp
  · rw [Finset.filter_not, Finset.card_sdiff]
    simp

#print axioms os_helper_count
#print axioms os_helper_set
#print axioms os_helper_meas
#print axioms os_helper_fiber

/-- The card's main claim. Take n independent draws `X 0, ..., X (n-1)` that all follow one
law `μ` on the real line, with cumulative chance `F = cdf μ`. For any rank k from 1 to n and any
threshold x, the chance that the k-th smallest draw is at most x is the binomial tail:
the sum over j from k to n of C(n, j) F(x)^j (1 - F(x))^(n - j). -/
theorem kth_smallest_cdf_eq_binomial_tail {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n : ℕ} (X : Fin n → Ω → ℝ) (μ : Measure ℝ)
    [IsProbabilityMeasure μ] (hmeas : ∀ i, Measurable (X i)) (hindep : iIndepFun X P)
    (hlaw : ∀ i, P.map (X i) = μ) (k : ℕ) (hk1 : 1 ≤ k) (hkn : k ≤ n) (x : ℝ) :
    P.real {ω | kthSmallest (fun i => X i ω) k hk1 hkn ≤ x} =
      ∑ j ∈ Finset.Icc k n, (n.choose j : ℝ) * cdf μ x ^ j * (1 - cdf μ x) ^ (n - j) := by
  classical
  have hevent : {ω | kthSmallest (fun i => X i ω) k hk1 hkn ≤ x} =
      (fun ω => Finset.univ.filter (fun i => X i ω ≤ x)) ⁻¹'
        ↑(Finset.univ.filter (fun S : Finset (Fin n) => k ≤ S.card)) := by
    ext ω
    simp [os_helper_count]
  rw [hevent, ← sum_measureReal_preimage_singleton _
    (fun S _ => os_helper_meas X hmeas x S)]
  have hfib : ∀ S : Finset (Fin n),
      P.real ((fun ω => Finset.univ.filter (fun i => X i ω ≤ x)) ⁻¹' {S}) =
        cdf μ x ^ S.card * (1 - cdf μ x) ^ (n - S.card) := fun S =>
    os_helper_fiber P X μ hmeas hindep hlaw x S
  simp_rw [hfib]
  rw [Finset.sum_filter, ← Finset.powerset_univ,
    Finset.sum_powerset_apply_card
      (fun m => if k ≤ m then cdf μ x ^ m * (1 - cdf μ x) ^ (n - m) else 0)]
  simp only [Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mul_ite, mul_zero]
  rw [← Finset.sum_filter]
  have hIcc : (Finset.range (n + 1)).filter (fun m => k ≤ m) = Finset.Icc k n := by
    ext m
    simp only [Finset.mem_filter, Finset.mem_range, Finset.mem_Icc]
    omega
  rw [hIcc]
  refine Finset.sum_congr rfl (fun j _ => by ring)

/-- Step 0 of the card: a rank question is a counting question. For any n real values, ties
allowed, the k-th smallest is at most t exactly when at least k of the values are at most t. -/
theorem kth_smallest_le_iff_count {n : ℕ} (x : Fin n → ℝ) (k : ℕ) (hk1 : 1 ≤ k) (hkn : k ≤ n)
    (t : ℝ) :
    kthSmallest x k hk1 hkn ≤ t ↔ k ≤ (Finset.univ.filter (fun i => x i ≤ t)).card := by
  exact os_helper_count x k hk1 hkn t

/-- The maximum's and the minimum's laws. For n ≥ 1 independent draws from one law with
cumulative chance `F = cdf μ`, the largest is at most x with chance F(x)^n, and the smallest is
at most x with chance 1 - (1 - F(x))^n. -/
theorem max_min_cdf {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] {n : ℕ} (hn : 0 < n) (X : Fin n → Ω → ℝ) (μ : Measure ℝ)
    [IsProbabilityMeasure μ] (hmeas : ∀ i, Measurable (X i)) (hindep : iIndepFun X P)
    (hlaw : ∀ i, P.map (X i) = μ) (x : ℝ) :
    P.real {ω | Finset.univ.sup' ⟨⟨0, hn⟩, Finset.mem_univ _⟩ (fun i => X i ω) ≤ x} =
        cdf μ x ^ n ∧
      P.real {ω | Finset.univ.inf' ⟨⟨0, hn⟩, Finset.mem_univ _⟩ (fun i => X i ω) ≤ x} =
        1 - (1 - cdf μ x) ^ n := by
  classical
  constructor
  · have hset : {ω | Finset.univ.sup' ⟨⟨0, hn⟩, Finset.mem_univ _⟩ (fun i => X i ω) ≤ x} =
        {ω | Finset.univ.filter (fun i => X i ω ≤ x) = Finset.univ} := by
      ext ω
      show (Finset.univ.sup' _ (fun i => X i ω) ≤ x) ↔
        Finset.univ.filter (fun i => X i ω ≤ x) = Finset.univ
      refine (Finset.sup'_le_iff _ _).trans ?_
      rw [Finset.eq_univ_iff_forall]
      simp
    rw [hset, os_helper_fiber P X μ hmeas hindep hlaw x]
    simp
  · have hset : {ω | Finset.univ.inf' ⟨⟨0, hn⟩, Finset.mem_univ _⟩ (fun i => X i ω) ≤ x} =
        {ω | Finset.univ.filter (fun i => X i ω ≤ x) = ∅}ᶜ := by
      ext ω
      show (Finset.univ.inf' _ (fun i => X i ω) ≤ x) ↔
        ¬ (Finset.univ.filter (fun i => X i ω ≤ x) = ∅)
      refine (Finset.inf'_le_iff _).trans ?_
      rw [Finset.filter_eq_empty_iff]
      simp
    rw [hset, probReal_compl_eq_one_sub (os_helper_meas X hmeas x ∅),
      os_helper_fiber P X μ hmeas hindep hlaw x]
    simp

/-! The card's whole-number worked examples, checked exactly. -/

-- Every day of 20 a loss: chance 0.5^20, which is 1 in 1,048,576.
example : (1 / 2 : ℚ) ^ 20 = 1 / 1048576 := by norm_num

-- C(20, 19) = 20 ways to pick which 19 days stay under the line.
example : Nat.choose 20 19 = 20 := by decide

-- The count in front of the second worst's density: 20 × C(19, 18) = 380 = 20! / (18! 1!).
example : 20 * Nat.choose 19 18 = 380 := by decide
example : 20 * Nat.choose 19 18 = Nat.factorial 20 / (Nat.factorial 18 * Nat.factorial 1) := by
  decide

-- The second worst of 20 at most the true 95% VaR: the binomial tail from 19 to 20 at F = 0.95
-- is 0.95^20 + 20 × 0.05 × 0.95^19.
example : ∑ j ∈ Finset.Icc 19 20, (Nat.choose 20 j : ℚ) * (19 / 20) ^ j * (1 / 20) ^ (20 - j) =
    (19 / 20) ^ 20 + 20 * (1 / 20) * (19 / 20) ^ 19 := by
  rw [show Finset.Icc 19 20 = {19, 20} from by decide]
  norm_num [Nat.choose]

-- The 6th and 15th values bracket the median when 6 to 14 of 20 fair days are at or below it:
-- 1,005,176 of the 1,048,576 equally likely patterns, about 0.9586.
example : ∑ j ∈ Finset.Icc 6 14, Nat.choose 20 j = 1005176 := by decide

-- Mistake 1: adding the daily chances, 20 × 0.01 = 0.2, overstates 1 - 0.99^20.
example : 1 - (99 / 100 : ℚ) ^ 20 < 20 * (1 / 100) := by norm_num

#print axioms kth_smallest_cdf_eq_binomial_tail
#print axioms kth_smallest_le_iff_count
#print axioms max_min_cdf
