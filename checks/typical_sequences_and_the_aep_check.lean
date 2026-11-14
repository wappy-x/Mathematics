-- Typical sequences: for independent readings with the same chances every day, the typical records hold at least 1 - σ²/(nε²) of the chance and number between P(A)·2^(n(H-ε)) and 2^(n(H+ε)), the chance of the typical set tends to 1 as the record grows, any set of at most 2^(n(H-2ε)) records holds at most 2^(-nε) plus the chance outside the typical set, and the card's weather numbers are exact.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic

open Finset Filter Topology

namespace TypicalSetCard

variable {α : Type*} [Fintype α]

/-- The surprise of one reading of chance `p x`, in bits: `s(x) = -log₂ p(x)`. -/
noncomputable def surprise (p : α → ℝ) (x : α) : ℝ := -Real.logb 2 (p x)

/-- The entropy in bits: the average surprise of one reading, `H = Σ p(x) s(x)`.
(Mathlib's `Real.logb 2 0 = 0`, so a reading of chance 0 adds nothing.) -/
noncomputable def entropy (p : α → ℝ) : ℝ := ∑ x, p x * surprise p x

/-- The variance of one reading's surprise: `σ² = Σ p(x) (s(x) - H)²`. -/
noncomputable def surpriseVar (p : α → ℝ) : ℝ := ∑ x, p x * (surprise p x - entropy p) ^ 2

/-- The chance of a record `xⁿ = (x₁, …, xₙ)` of independent readings with the same chances
every day: the product `p(x₁) p(x₂) ⋯ p(xₙ)`. -/
def recordProb (p : α → ℝ) {n : ℕ} (r : Fin n → α) : ℝ := ∏ i, p (r i)

/-- The typical set `A`: every record of `n` days whose chance lies between
`2^(-n(H+ε))` and `2^(-n(H-ε))`. -/
noncomputable def typicalSet (p : α → ℝ) (n : ℕ) (ε : ℝ) : Finset (Fin n → α) :=
  univ.filter fun r => (2 : ℝ) ^ (-((n : ℝ) * (entropy p + ε))) ≤ recordProb p r ∧
    recordProb p r ≤ (2 : ℝ) ^ (-((n : ℝ) * (entropy p - ε)))

/-- The chance `P(A)` that a record of `n` days lands in the typical set. -/
noncomputable def typicalProb (p : α → ℝ) (n : ℕ) (ε : ℝ) : ℝ :=
  ∑ r ∈ typicalSet p n ε, recordProb p r


/-! ### Helper lemmas -/

lemma sum_record_prod {n : ℕ} (q : Fin n → α → ℝ) :
    ∑ r : Fin n → α, ∏ i, q i (r i) = ∏ i, ∑ x, q i x := by
  classical
  exact (Fintype.prod_sum q).symm

lemma sum_recordProb (p : α → ℝ) (hsum : ∑ x, p x = 1) (n : ℕ) :
    ∑ r : Fin n → α, recordProb p r = 1 := by
  unfold recordProb
  rw [sum_record_prod (fun _ x => p x)]
  simp [hsum]

lemma recordProb_nonneg (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) {n : ℕ} (r : Fin n → α) :
    0 ≤ recordProb p r :=
  Finset.prod_nonneg fun i _ => hp _

lemma recordProb_eq_rpow (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) {n : ℕ} (r : Fin n → α)
    (h : 0 < recordProb p r) :
    recordProb p r = (2 : ℝ) ^ (-∑ i, surprise p (r i)) := by
  have hpos : ∀ i, 0 < p (r i) := by
    intro i
    rcases (hp (r i)).lt_or_eq with h1 | h1
    · exact h1
    · exfalso
      have : recordProb p r = 0 := Finset.prod_eq_zero (Finset.mem_univ i) h1.symm
      linarith
  unfold surprise
  rw [show -∑ i, -Real.logb 2 (p (r i)) = ∑ i, Real.logb 2 (p (r i)) by
    simp [Finset.sum_neg_distrib]]
  rw [Real.rpow_sum_of_pos (by norm_num)]
  unfold recordProb
  refine Finset.prod_congr rfl fun i _ => ?_
  rw [Real.rpow_logb (by norm_num) (by norm_num) (hpos i)]

lemma mem_typicalSet_of (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) (n : ℕ) (ε : ℝ) (r : Fin n → α)
    (h : 0 < recordProb p r)
    (hS : |∑ i, surprise p (r i) - n * entropy p| ≤ n * ε) : r ∈ typicalSet p n ε := by
  simp only [typicalSet, Finset.mem_filter, Finset.mem_univ, true_and]
  rw [recordProb_eq_rpow p hp r h]
  rw [abs_le] at hS
  constructor
  · apply Real.rpow_le_rpow_of_exponent_le (by norm_num)
    nlinarith [hS.2]
  · apply Real.rpow_le_rpow_of_exponent_le (by norm_num)
    nlinarith [hS.1]

lemma sum_recordProb_mul_sq (p : α → ℝ) (hsum : ∑ x, p x = 1) (n : ℕ) :
    ∑ r : Fin n → α, recordProb p r * (∑ i, surprise p (r i) - n * entropy p) ^ 2 =
      n * surpriseVar p := by
  classical
  set f : α → ℝ := fun x => surprise p x - entropy p with hfdef
  have hf0 : ∑ x, p x * f x = 0 := by
    simp only [f, mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, hsum]
    unfold entropy
    ring
  have key : ∀ r : Fin n → α, ∑ i, surprise p (r i) - n * entropy p = ∑ i, f (r i) := by
    intro r
    simp [f, Finset.sum_sub_distrib]
  have hij : ∀ i j : Fin n, ∑ r : Fin n → α, recordProb p r * (f (r i) * f (r j)) =
      if i = j then surpriseVar p else 0 := by
    intro i j
    have hr : ∀ r : Fin n → α, recordProb p r * (f (r i) * f (r j)) =
        ∏ k, (p (r k) * ((if k = i then f (r k) else 1) * (if k = j then f (r k) else 1))) := by
      intro r
      rw [Finset.prod_mul_distrib, Finset.prod_mul_distrib, Finset.prod_ite_eq',
        Finset.prod_ite_eq']
      simp [recordProb]
    rw [Finset.sum_congr rfl (fun r _ => hr r),
      sum_record_prod (fun k x => p x * ((if k = i then f x else 1) * (if k = j then f x else 1)))]
    by_cases hij : i = j
    · subst hij
      simp only [if_true]
      rw [Finset.prod_eq_single i]
      · simp [surpriseVar, f, sq]
      · intro k _ hk
        simp [hk, hsum]
      · intro h; exact absurd (Finset.mem_univ i) h
    · simp only [hij, if_false]
      apply Finset.prod_eq_zero (Finset.mem_univ i)
      simp [hij, hf0]
  calc ∑ r : Fin n → α, recordProb p r * (∑ i, surprise p (r i) - n * entropy p) ^ 2
      = ∑ r : Fin n → α, ∑ i, ∑ j, recordProb p r * (f (r i) * f (r j)) := by
        refine Finset.sum_congr rfl fun r _ => ?_
        rw [key, sq, Finset.sum_mul_sum, Finset.mul_sum]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [Finset.mul_sum]
    _ = ∑ i, ∑ j, ∑ r : Fin n → α, recordProb p r * (f (r i) * f (r j)) := by
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [Finset.sum_comm]
    _ = ∑ i : Fin n, ∑ j : Fin n, (if i = j then surpriseVar p else 0) := by
        simp only [hij]
    _ = n * surpriseVar p := by
        simp

lemma typicalProb_le_one (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) (hsum : ∑ x, p x = 1)
    (n : ℕ) (ε : ℝ) : typicalProb p n ε ≤ 1 := by
  rw [← sum_recordProb p hsum n]
  exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _)
    (fun r _ _ => recordProb_nonneg p hp r)

lemma one_sub_typicalProb [DecidableEq α] (p : α → ℝ) (hsum : ∑ x, p x = 1) (n : ℕ) (ε : ℝ) :
    1 - typicalProb p n ε = ∑ r ∈ univ \ typicalSet p n ε, recordProb p r := by
  classical
  rw [← sum_recordProb p hsum n, typicalProb,
    ← Finset.sum_sdiff (Finset.subset_univ (typicalSet p n ε))]
  ring

lemma chebyshev_bound (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) (hsum : ∑ x, p x = 1)
    (n : ℕ) (ε : ℝ) (hε : 0 < ε) :
    1 - surpriseVar p / ((n : ℝ) * ε ^ 2) ≤ typicalProb p n ε := by
  classical
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    have h1 : typicalProb p 0 ε = 1 := by
      have hA : typicalSet p 0 ε = univ := by
        ext r
        simp [typicalSet, recordProb]
      unfold typicalProb
      rw [hA]
      exact sum_recordProb p hsum 0
    rw [h1]
    simp
  have hnε : (0 : ℝ) < (n : ℝ) * ε := by positivity
  have hpt : ∀ r ∈ univ \ typicalSet p n ε, recordProb p r ≤
      recordProb p r * (∑ i, surprise p (r i) - n * entropy p) ^ 2 / ((n : ℝ) * ε) ^ 2 := by
    intro r hr
    rcases (recordProb_nonneg p hp r).lt_or_eq with h | h
    · have hnot : r ∉ typicalSet p n ε := (Finset.mem_sdiff.mp hr).2
      have hD : (n : ℝ) * ε < |∑ i, surprise p (r i) - n * entropy p| := by
        by_contra hc
        exact hnot (mem_typicalSet_of p hp n ε r h (not_lt.mp hc))
      have hD2 : ((n : ℝ) * ε) ^ 2 ≤ (∑ i, surprise p (r i) - n * entropy p) ^ 2 := by
        rw [← sq_abs (∑ i, surprise p (r i) - n * entropy p)]
        exact pow_le_pow_left₀ hnε.le hD.le 2
      rw [le_div_iff₀ (by positivity)]
      exact mul_le_mul_of_nonneg_left hD2 h.le
    · rw [← h]; simp
  have hle : 1 - typicalProb p n ε ≤ surpriseVar p / ((n : ℝ) * ε ^ 2) := by
    rw [one_sub_typicalProb p hsum n ε]
    calc ∑ r ∈ univ \ typicalSet p n ε, recordProb p r
        ≤ ∑ r ∈ univ \ typicalSet p n ε,
            recordProb p r * (∑ i, surprise p (r i) - n * entropy p) ^ 2 / ((n : ℝ) * ε) ^ 2 :=
          Finset.sum_le_sum hpt
      _ ≤ ∑ r : Fin n → α,
            recordProb p r * (∑ i, surprise p (r i) - n * entropy p) ^ 2 / ((n : ℝ) * ε) ^ 2 :=
          Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _)
            (fun r _ _ => by
              have := recordProb_nonneg p hp r
              positivity)
      _ = (n * surpriseVar p) / ((n : ℝ) * ε) ^ 2 := by
          rw [← Finset.sum_div, sum_recordProb_mul_sq p hsum n]
      _ = surpriseVar p / ((n : ℝ) * ε ^ 2) := by
          have : (n : ℝ) ≠ 0 := by positivity
          field_simp
  linarith

/-- **The three promises about the typical set.** Take a reading with finitely many values and
chances `p(x)`, each at least 0 and adding to 1, independent from day to day with the same
chances every day. For every record length `n` and every tolerance `ε > 0`:
the typical set holds at least `1 - σ²/(nε²)` of the chance, it has at most `2^(n(H+ε))`
members, and it has at least `P(A) · 2^(n(H-ε))` members. -/
theorem typical_set_three_promises (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) (hsum : ∑ x, p x = 1)
    (n : ℕ) (ε : ℝ) (hε : 0 < ε) :
    1 - surpriseVar p / ((n : ℝ) * ε ^ 2) ≤ typicalProb p n ε ∧
      ((typicalSet p n ε).card : ℝ) ≤ (2 : ℝ) ^ ((n : ℝ) * (entropy p + ε)) ∧
      typicalProb p n ε * (2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)) ≤ (typicalSet p n ε).card := by
  classical
  refine ⟨chebyshev_bound p hp hsum n ε hε, ?_, ?_⟩
  · have hpos : (0 : ℝ) < (2 : ℝ) ^ ((n : ℝ) * (entropy p + ε)) := by positivity
    have h1 : ((typicalSet p n ε).card : ℝ) * ((2 : ℝ) ^ ((n : ℝ) * (entropy p + ε)))⁻¹ ≤ 1 := by
      calc ((typicalSet p n ε).card : ℝ) * ((2 : ℝ) ^ ((n : ℝ) * (entropy p + ε)))⁻¹
          = ∑ r ∈ typicalSet p n ε, (2 : ℝ) ^ (-((n : ℝ) * (entropy p + ε))) := by
            rw [Finset.sum_const, nsmul_eq_mul, Real.rpow_neg (by norm_num)]
        _ ≤ typicalProb p n ε := by
            apply Finset.sum_le_sum
            intro r hr
            exact ((Finset.mem_filter.mp hr).2).1
        _ ≤ 1 := typicalProb_le_one p hp hsum n ε
    rw [← div_eq_mul_inv, div_le_one hpos] at h1
    exact h1
  · have hpos : (0 : ℝ) < (2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)) := by positivity
    have h1 : typicalProb p n ε ≤
        ((typicalSet p n ε).card : ℝ) * ((2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)))⁻¹ := by
      calc typicalProb p n ε
          ≤ ∑ r ∈ typicalSet p n ε, (2 : ℝ) ^ (-((n : ℝ) * (entropy p - ε))) := by
            apply Finset.sum_le_sum
            intro r hr
            exact ((Finset.mem_filter.mp hr).2).2
        _ = ((typicalSet p n ε).card : ℝ) * ((2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)))⁻¹ := by
            rw [Finset.sum_const, nsmul_eq_mul, Real.rpow_neg (by norm_num)]
    rw [← div_eq_mul_inv, le_div_iff₀ hpos] at h1
    exact h1

/-- **The equipartition property, in probability.** For every tolerance `ε > 0`, the chance
that a random record's surprise per reading lands within `ε` of the entropy `H` (that is, the
chance of the typical set) tends to 1 as the record grows. -/
theorem typical_prob_tendsto_one (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) (hsum : ∑ x, p x = 1)
    (ε : ℝ) (hε : 0 < ε) :
    Tendsto (fun n : ℕ => typicalProb p n ε) atTop (𝓝 1) := by
  have hlow : Tendsto (fun n : ℕ => 1 - surpriseVar p / ((n : ℝ) * ε ^ 2)) atTop (𝓝 1) := by
    have h0 : Tendsto (fun n : ℕ => (surpriseVar p / ε ^ 2) / (n : ℝ)) atTop (𝓝 0) :=
      tendsto_const_div_atTop_nhds_zero_nat _
    have h0' : Tendsto (fun n : ℕ => surpriseVar p / ((n : ℝ) * ε ^ 2)) atTop (𝓝 0) := by
      refine h0.congr fun n => ?_
      rw [div_div, mul_comm]
    simpa using (tendsto_const_nhds (x := (1 : ℝ))).sub h0'
  exact tendsto_of_tendsto_of_tendsto_of_le_of_le hlow tendsto_const_nhds
    (fun n => chebyshev_bound p hp hsum n ε hε) (fun n => typicalProb_le_one p hp hsum n ε)

/-- **No smaller set will do.** Any set `B` of at most `2^(n(H-2ε))` records holds at most
`2^(-nε)` of the chance plus the chance outside the typical set, `1 - P(A)`. -/
theorem small_set_misses_chance (p : α → ℝ) (hp : ∀ x, 0 ≤ p x) (hsum : ∑ x, p x = 1)
    (n : ℕ) (ε : ℝ) (B : Finset (Fin n → α))
    (hB : (B.card : ℝ) ≤ (2 : ℝ) ^ ((n : ℝ) * (entropy p - 2 * ε))) :
    ∑ r ∈ B, recordProb p r ≤ (2 : ℝ) ^ (-((n : ℝ) * ε)) + (1 - typicalProb p n ε) := by
  classical
  have hy : (0 : ℝ) < (2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)) := by positivity
  rw [← Finset.sum_inter_add_sum_sdiff B (typicalSet p n ε)]
  gcongr ?_ + ?_
  · calc ∑ r ∈ B ∩ typicalSet p n ε, recordProb p r
        ≤ ∑ r ∈ B ∩ typicalSet p n ε, (2 : ℝ) ^ (-((n : ℝ) * (entropy p - ε))) := by
          apply Finset.sum_le_sum
          intro r hr
          exact ((Finset.mem_filter.mp (Finset.mem_inter.mp hr).2).2).2
      _ = ((B ∩ typicalSet p n ε).card : ℝ) * ((2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)))⁻¹ := by
          rw [Finset.sum_const, nsmul_eq_mul, Real.rpow_neg (by norm_num)]
      _ ≤ (B.card : ℝ) * ((2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)))⁻¹ := by
          gcongr
          exact Finset.inter_subset_left
      _ ≤ (2 : ℝ) ^ ((n : ℝ) * (entropy p - 2 * ε)) *
            ((2 : ℝ) ^ ((n : ℝ) * (entropy p - ε)))⁻¹ := by
          gcongr
      _ = (2 : ℝ) ^ (-((n : ℝ) * ε)) := by
          rw [← div_eq_mul_inv, ← Real.rpow_sub (by norm_num)]
          congr 1
          ring
  · rw [one_sub_typicalProb p hsum n ε]
    apply Finset.sum_le_sum_of_subset_of_nonneg
    · intro r hr
      simp only [Finset.mem_sdiff, Finset.mem_univ, true_and] at hr ⊢
      exact hr.2
    · intro r _ _
      exact recordProb_nonneg p hp r

end TypicalSetCard

open TypicalSetCard

-- The card's whole-number checks.
-- Entropy of the station: 1/2·1 + 1/4·2 + 1/8·3 + 1/8·3 = 7/4 bits.
example : (1 / 2 : ℚ) * 1 + 1 / 4 * 2 + 1 / 8 * 3 + 1 / 8 * 3 = 7 / 4 := by norm_num
-- Variance of the surprise: mean square 1/2·1 + 1/4·4 + 1/4·9 = 15/4, minus (7/4)² is 11/16.
example : (1 / 2 : ℚ) * 1 + 1 / 4 * 4 + 1 / 4 * 9 = 15 / 4 ∧
    (15 / 4 : ℚ) - (7 / 4) ^ 2 = 11 / 16 := by norm_num
-- All records of 1,000 days: 4^1000 = 2^2000.
set_option exponentiation.threshold 2000 in
example : (4 : ℕ) ^ 1000 = 2 ^ 2000 := by norm_num
-- The window at 1,000 days: 1000 · (7/4 + 1/20) = 1800 and 1000 · (7/4 - 1/20) = 1700.
example : (1000 : ℚ) * (7 / 4 + 1 / 20) = 1800 ∧ (1000 : ℚ) * (7 / 4 - 1 / 20) = 1700 := by
  norm_num
-- The centre record: 500·1 + 250·2 + 250·3 = 1,750 bits.
example : 500 * 1 + 250 * 2 + 250 * 3 = 1750 := by norm_num
-- Chebyshev at 1,000 days: miss at most (11/16)/(1000 · (1/20)²) = 11/40, floor 29/40.
example : (11 / 16 : ℚ) / (1000 * (1 / 20) ^ 2) = 11 / 40 ∧ 1 - (11 / 40 : ℚ) = 29 / 40 := by
  norm_num
-- Step 5: 2^1650 records of chance at most 2^-1700 hold at most 2^-50.
set_option exponentiation.threshold 2000 in
example : (2 : ℚ) ^ 1650 * (2 ^ 1700)⁻¹ = (2 ^ 50)⁻¹ := by norm_num
-- 8 days: the window |L/8 - 7/4| ≤ 1/20 allows only a total surprise of exactly 14 bits.
example : ∀ L : Fin 25, ((20 * (L : ℤ) - 280).natAbs ≤ 8 ↔ (L : ℕ) = 14) := by decide
-- 8 days: 4^8 = 65,536 records in all.
example : (4 : ℕ) ^ 8 = 65536 := by norm_num
-- 8 days, total 14 bits: a sunny, b cloudy, c wet days with a + b + c = 8 and b + 2c = 6;
-- each mix gives 8!/(a! b! c!) orders and 2^c ways to make wet days rain or snow: 2,716 records.
example : Nat.factorial 8 / (Nat.factorial 2 * Nat.factorial 6 * Nat.factorial 0) * 2 ^ 0 +
    Nat.factorial 8 / (Nat.factorial 3 * Nat.factorial 4 * Nat.factorial 1) * 2 ^ 1 +
    Nat.factorial 8 / (Nat.factorial 4 * Nat.factorial 2 * Nat.factorial 2) * 2 ^ 2 +
    Nat.factorial 8 / (Nat.factorial 5 * Nat.factorial 0 * Nat.factorial 3) * 2 ^ 3 = 2716 := by
  decide
-- 8 days: each of those records has chance 2^-14, so together 2716/16384 of the chance.
example : (2716 : ℚ) * (2 ^ 14)⁻¹ = 2716 / 16384 := by norm_num

#print axioms sum_record_prod
#print axioms sum_recordProb
#print axioms recordProb_nonneg
#print axioms recordProb_eq_rpow
#print axioms mem_typicalSet_of
#print axioms sum_recordProb_mul_sq
#print axioms typicalProb_le_one
#print axioms one_sub_typicalProb
#print axioms chebyshev_bound
#print axioms typical_set_three_promises
#print axioms typical_prob_tendsto_one
#print axioms small_set_misses_chance
