-- Binomial: for n independent tries that each succeed with the same chance p, the chance of exactly k successes is C(n, k) p^k (1 - p)^(n - k), the average count is n p, and its variance is n p (1 - p).
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

theorem bb_integral_switch
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (f : Ω → Bool) (hf : Measurable f) :
    ∫ ω, (if f ω = true then (1 : ℝ) else 0) ∂μ = μ.real {ω | f ω = true} := by
  have hs : MeasurableSet {ω | f ω = true} := hf (measurableSet_singleton true)
  rw [← integral_indicator_one hs]
  congr 1
  ext ω
  by_cases h : f ω = true <;> simp [Set.indicator, h]

#print axioms bb_integral_switch

theorem bb_memLp_switch
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (f : Ω → Bool) (hf : Measurable f) :
    MemLp (fun ω => if f ω = true then (1 : ℝ) else 0) 2 μ := by
  have hm : Measurable (fun ω => if f ω = true then (1 : ℝ) else 0) :=
    Measurable.ite (hf (measurableSet_singleton true)) measurable_const measurable_const
  refine MemLp.of_bound hm.aestronglyMeasurable 1 (Filter.Eventually.of_forall fun ω => ?_)
  by_cases h : f ω = true <;> simp [h]

#print axioms bb_memLp_switch

/-- The binomial law. Make a fixed number n of tries, each with two outcomes (success = `true`),
each succeeding with the same chance p, all independent of each other. Then the chance of exactly
k successes is the number of ways to pick which k tries succeed, C(n, k), times the chance of any
one such pattern, p^k (1 - p)^(n - k). -/
theorem binomial_chance_of_k_successes
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (n : ℕ) (B : Fin n → Ω → Bool) (hmeas : ∀ i, Measurable (B i))
    (hind : iIndepFun B μ)
    (p : ℝ) (hp : ∀ i, μ.real {ω | B i ω = true} = p) (k : ℕ) :
    μ.real {ω | (Finset.univ.filter (fun i => B i ω = true)).card = k}
      = (n.choose k : ℝ) * p ^ k * (1 - p) ^ (n - k) := by
  classical
  set F : Ω → Finset (Fin n) := fun ω => Finset.univ.filter (fun i => B i ω = true) with hF
  have hset : {ω | (Finset.univ.filter (fun i => B i ω = true)).card = k}
      = ⋃ s ∈ Finset.powersetCard k (Finset.univ : Finset (Fin n)), {ω | F ω = s} := by
    ext ω; simp [hF, Finset.mem_powersetCard]
  have hE : ∀ s : Finset (Fin n), {ω | F ω = s} = ⋂ i, B i ⁻¹' {decide (i ∈ s)} := by
    intro s
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iInter, Set.mem_preimage, Set.mem_singleton_iff, hF]
    constructor
    · rintro rfl i; simp
    · intro h; ext i; have := h i; cases hb : B i ω <;> simp_all
  have hEm : ∀ s : Finset (Fin n), MeasurableSet {ω | F ω = s} := by
    intro s; rw [hE s]
    exact MeasurableSet.iInter fun i => hmeas i (measurableSet_singleton _)
  have hEval : ∀ s : Finset (Fin n), μ.real {ω | F ω = s} = p ^ s.card * (1 - p) ^ (n - s.card) := by
    intro s
    have h1 : ∀ i, μ.real (B i ⁻¹' {decide (i ∈ s)}) = if i ∈ s then p else 1 - p := by
      intro i
      by_cases hi : i ∈ s
      · simp only [hi, decide_true, ite_true]; exact hp i
      · simp only [hi, decide_false, ite_false]
        have : B i ⁻¹' {false} = {ω | B i ω = true}ᶜ := by
          ext ω; simp
        have hm : MeasurableSet {ω | B i ω = true} := hmeas i (measurableSet_singleton true)
        rw [this, probReal_compl_eq_one_sub hm, hp i]
    rw [hE s, measureReal_def,
      hind.meas_iInter (fun i => ⟨{decide (i ∈ s)}, measurableSet_singleton _, rfl⟩),
      ENNReal.toReal_prod]
    simp only [← measureReal_def, h1]
    rw [Finset.prod_ite, Finset.prod_const, Finset.prod_const]
    congr 2
    · simp
    · rw [Finset.filter_not, Finset.card_sdiff]; simp
  rw [hset, measureReal_biUnion_finset _ (fun s _ => hEm s)]
  · rw [Finset.sum_congr rfl (fun s hs => by
      rw [hEval s, (Finset.mem_powersetCard.1 hs).2])]
    simp [Finset.card_powersetCard]
    ring
  · intro s _ t _ hst
    exact Set.disjoint_left.2 fun ω h1 h2 => hst (h1.symm.trans h2)

/-- The average count of successes is tries times chance, n p. Write the count as a sum of
switches, one per try, each 1 on a success and 0 on a failure. This needs no independence. -/
theorem binomial_mean
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (n : ℕ) (B : Fin n → Ω → Bool) (hmeas : ∀ i, Measurable (B i))
    (p : ℝ) (hp : ∀ i, μ.real {ω | B i ω = true} = p) :
    ∫ ω, (∑ i, if B i ω = true then (1 : ℝ) else 0) ∂μ = n * p := by
  rw [integral_finsetSum _ (fun i _ => (bb_memLp_switch μ (B i) (hmeas i)).integrable one_le_two)]
  simp [bb_integral_switch μ _ (hmeas _), hp]

/-- For independent tries, the variance of the count of successes is the average times the chance
of failure, n p (1 - p). -/
theorem binomial_variance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (n : ℕ) (B : Fin n → Ω → Bool) (hmeas : ∀ i, Measurable (B i))
    (hind : iIndepFun B μ)
    (p : ℝ) (hp : ∀ i, μ.real {ω | B i ω = true} = p) :
    variance (fun ω => ∑ i, if B i ω = true then (1 : ℝ) else 0) μ = n * p * (1 - p) := by
  set X : Fin n → Ω → ℝ := fun i ω => if B i ω = true then (1 : ℝ) else 0 with hX
  have hfun : (fun ω => ∑ i, if B i ω = true then (1 : ℝ) else 0) = ∑ i, X i := by
    ext ω; simp [hX, Finset.sum_apply]
  have hind' : iIndepFun X μ :=
    hind.comp (fun (_ : Fin n) (b : Bool) => if b = true then (1 : ℝ) else 0)
      (fun _ => measurable_of_countable _)
  rw [hfun, IndepFun.variance_sum (fun i _ => bb_memLp_switch μ (B i) (hmeas i))
    (fun i _ j _ hij => hind'.indepFun hij)]
  have hvar : ∀ i, variance (X i) μ = p * (1 - p) := by
    intro i
    rw [variance_eq_sub (bb_memLp_switch μ (B i) (hmeas i))]
    have hsq : X i ^ 2 = X i := by
      ext ω; by_cases h : B i ω = true <;> simp [hX, h]
    rw [hsq]
    have := bb_integral_switch μ (B i) (hmeas i)
    simp only [hX] at this ⊢
    rw [this, hp]
    ring
  rw [Finset.sum_congr rfl (fun i _ => hvar i)]
  simp
  ring

-- Ten flips: 1,024 head-tail strings.
example : 2 ^ 10 = 1024 := by norm_num
-- Strings with k = 0, ..., 10 heads: 1 10 45 120 210 252 210 120 45 10 1.
example : (List.range 11).map (Nat.choose 10) = [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1] := by
  decide
-- Exactly 7 heads: C(10, 7) = (10 × 9 × 8)/(3 × 2 × 1) = 120.
example : Nat.choose 10 7 = 120 := by decide
example : Nat.choose 10 7 = (10 * 9 * 8) / (3 * 2 * 1) := by decide
-- 7 or more heads: 120 + 45 + 10 + 1 = 176 strings.
example : Nat.choose 10 7 + Nat.choose 10 8 + Nat.choose 10 9 + Nat.choose 10 10 = 176 := by decide
-- Fair coin: one string has chance 1/1,024; exactly 7 heads, 120/1,024; 7 or more, 176/1,024.
example : ((1 : ℚ) / 2) ^ 10 = 1 / 1024 := by norm_num
example : (Nat.choose 10 7 : ℚ) * (1 / 2) ^ 7 * (1 - 1 / 2) ^ (10 - 7) = 120 / 1024 := by
  norm_num [Nat.choose]
example : ((120 + 45 + 10 + 1 : ℕ) : ℚ) / 1024 = 176 / 1024 := by norm_num
-- Fair coin: average 10 × 1/2 = 5, variance 10 × 1/2 × 1/2 = 5/2.
example : (10 : ℚ) * (1 / 2) = 5 ∧ (10 : ℚ) * (1 / 2) * (1 - 1 / 2) = 5 / 2 := by norm_num
-- Bent coin, p = 3/5: one 7-head string has chance (3/5)^7 (2/5)^3 = 17496/9765625
-- (that is 0.0017915904 exactly), and exactly 7 heads has chance 120 times that.
example : ((3 : ℚ) / 5) ^ 7 * (1 - 3 / 5) ^ 3 = 17496 / 9765625 := by norm_num
example : (Nat.choose 10 7 : ℚ) * (3 / 5) ^ 7 * (1 - 3 / 5) ^ (10 - 7) = 120 * (17496 / 9765625) := by
  norm_num [Nat.choose]
-- Bent coin: average 10 × 3/5 = 6, variance 10 × 3/5 × 2/5 = 12/5.
example : (10 : ℚ) * (3 / 5) = 6 ∧ (10 : ℚ) * (3 / 5) * (1 - 3 / 5) = 12 / 5 := by norm_num
-- One fair flip copied onto all ten: variance n^2 p (1 - p) = 100 × 1/4 = 25.
example : ((10 : ℚ) ^ 2) * (1 / 2) * (1 - 1 / 2) = 25 := by norm_num

#print axioms binomial_chance_of_k_successes
#print axioms binomial_mean
#print axioms binomial_variance
