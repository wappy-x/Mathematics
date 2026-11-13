-- Intervals for a proportion: the exact (Clopper–Pearson) interval catches the true rate with chance at least 1 − α for every rate, and the Wilson keep rule picks out exactly the rates between the two Wilson ends, which lie in 0 to 1 on either side of the observed rate.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals

open Finset

/-- The binomial chance, at true rate `p`, of exactly `j` recoveries out of `n`:
`C(n, j) p^j (1 - p)^(n - j)`. -/
noncomputable def binomChance (n j : ℕ) (p : ℝ) : ℝ :=
  (n.choose j : ℝ) * p ^ j * (1 - p) ^ (n - j)

/-- `A_k(p)`: the chance, at rate `p`, of `k` or more recoveries out of `n`. -/
noncomputable def upperTail (n k : ℕ) (p : ℝ) : ℝ :=
  ∑ j ∈ Icc k n, binomChance n j p

/-- `B_k(p)`: the chance, at rate `p`, of `k` or fewer recoveries out of `n`. -/
noncomputable def lowerTail (n k : ℕ) (p : ℝ) : ℝ :=
  ∑ j ∈ range (k + 1), binomChance n j p

/-- The exact interval for a count `k` keeps the candidate rate `p` unless the count is too high
for it (`A_k(p) < α/2`) or too low for it (`B_k(p) < α/2`). -/
abbrev exactKeeps (n k : ℕ) (α p : ℝ) : Prop :=
  α / 2 ≤ upperTail n k p ∧ α / 2 ≤ lowerTail n k p

/-- The Wilson interval's lower end `W₋` for `k` successes out of `n`, with `p̂ = k / n`. -/
noncomputable def wilsonLower (n k : ℕ) (z : ℝ) : ℝ :=
  ((k / n : ℝ) + z ^ 2 / (2 * n)
      - z * Real.sqrt ((k / n : ℝ) * (1 - k / n) / n + z ^ 2 / (4 * n ^ 2)))
    / (1 + z ^ 2 / n)

/-- The Wilson interval's upper end `W₊` for `k` successes out of `n`, with `p̂ = k / n`. -/
noncomputable def wilsonUpper (n k : ℕ) (z : ℝ) : ℝ :=
  ((k / n : ℝ) + z ^ 2 / (2 * n)
      + z * Real.sqrt ((k / n : ℝ) * (1 - k / n) / n + z ^ 2 / (4 * n ^ 2)))
    / (1 + z ^ 2 / n)

lemma binomChance_nonneg (n j : ℕ) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    0 ≤ binomChance n j p := by
  unfold binomChance
  have : 0 ≤ 1 - p := by linarith
  positivity

lemma binomChance_sum_eq_one (n : ℕ) (p : ℝ) :
    ∑ k ∈ range (n + 1), binomChance n k p = 1 := by
  have h := add_pow p (1 - p) n
  rw [show p + (1 - p) = 1 by ring, one_pow] at h
  rw [h]
  refine Finset.sum_congr rfl fun k _ => ?_
  unfold binomChance
  ring

lemma wilson_key_aux (q m z p S : ℝ) (hm : 0 < m)
    (hS : S ^ 2 = q * (1 - q) / m + z ^ 2 / (4 * m ^ 2)) :
    (q - p) ^ 2 - z ^ 2 * (p * (1 - p) / m) =
      (1 + z ^ 2 / m) * (p - (q + z ^ 2 / (2 * m) - z * S) / (1 + z ^ 2 / m)) *
        (p - (q + z ^ 2 / (2 * m) + z * S) / (1 + z ^ 2 / m)) := by
  have ha : 0 < 1 + z ^ 2 / m := by positivity
  have e : (1 + z ^ 2 / m) * (p - (q + z ^ 2 / (2 * m) - z * S) / (1 + z ^ 2 / m)) *
        (p - (q + z ^ 2 / (2 * m) + z * S) / (1 + z ^ 2 / m)) =
      (((1 + z ^ 2 / m) * p - (q + z ^ 2 / (2 * m))) ^ 2 - z ^ 2 * S ^ 2) / (1 + z ^ 2 / m) := by
    field_simp
    ring
  rw [e, hS]
  field_simp
  ring

lemma wilson_key (n k : ℕ) (hn : 0 < n) (hk : k ≤ n) (z p : ℝ) :
    ((k / n : ℝ) - p) ^ 2 - z ^ 2 * (p * (1 - p) / n) =
      (1 + z ^ 2 / n) * (p - wilsonLower n k z) * (p - wilsonUpper n k z) := by
  have hm : (0 : ℝ) < n := by exact_mod_cast hn
  have hq0 : (0 : ℝ) ≤ (k / n : ℝ) := by positivity
  have hq1 : (k / n : ℝ) ≤ 1 := by
    rw [div_le_one hm]; exact_mod_cast hk
  have hD : 0 ≤ (k / n : ℝ) * (1 - k / n) / n + z ^ 2 / (4 * n ^ 2) := by
    have : 0 ≤ 1 - (k / n : ℝ) := by linarith
    positivity
  exact wilson_key_aux _ _ _ _ _ hm (Real.sq_sqrt hD)

lemma wilsonUpper_pos (n k : ℕ) (hn : 0 < n) (z : ℝ) (hz : 0 < z) :
    0 < wilsonUpper n k z := by
  have hm : (0 : ℝ) < n := by exact_mod_cast hn
  unfold wilsonUpper
  have : 0 ≤ Real.sqrt ((k / n : ℝ) * (1 - k / n) / n + z ^ 2 / (4 * n ^ 2)) := Real.sqrt_nonneg _
  have : (0 : ℝ) ≤ (k / n : ℝ) := by positivity
  apply div_pos _ (by positivity)
  have : 0 < z ^ 2 / (2 * n) := by positivity
  nlinarith

lemma wilsonLower_lt_one (n k : ℕ) (hn : 0 < n) (hk : k ≤ n) (z : ℝ) (hz : 0 < z) :
    wilsonLower n k z < 1 := by
  have hm : (0 : ℝ) < n := by exact_mod_cast hn
  have hq1 : (k / n : ℝ) ≤ 1 := by
    rw [div_le_one hm]; exact_mod_cast hk
  unfold wilsonLower
  have : 0 ≤ Real.sqrt ((k / n : ℝ) * (1 - k / n) / n + z ^ 2 / (4 * n ^ 2)) := Real.sqrt_nonneg _
  have ha : 0 < 1 + z ^ 2 / n := by positivity
  rw [div_lt_one ha]
  have : 0 < z ^ 2 / (2 * n) := by positivity
  have : z ^ 2 / (2 * n) < z ^ 2 / n := by
    rw [div_lt_div_iff₀ (by positivity) hm]; nlinarith [sq_pos_of_pos hz]
  nlinarith

lemma wilsonLower_le_upper (n k : ℕ) (hn : 0 < n) (z : ℝ) (hz : 0 < z) :
    wilsonLower n k z ≤ wilsonUpper n k z := by
  have hm : (0 : ℝ) < n := by exact_mod_cast hn
  unfold wilsonLower wilsonUpper
  have : 0 ≤ Real.sqrt ((k / n : ℝ) * (1 - k / n) / n + z ^ 2 / (4 * n ^ 2)) := Real.sqrt_nonneg _
  have ha : 0 < 1 + z ^ 2 / n := by positivity
  apply div_le_div_of_nonneg_right _ ha.le
  nlinarith

/-- The exact interval keeps its promise: with `n` patients fixed in advance, independent, each
recovering with the same chance `p`, and error allowance `α` between 0 and 1, the counts `k`
whose exact interval contains `p` have total binomial chance at least `1 − α`,
whatever the true rate `p` in 0 to 1 is. -/
theorem exact_interval_coverage_at_least_one_minus_alpha
    (n : ℕ) (α p : ℝ) (hα : 0 < α) (hα1 : α < 1) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    1 - α ≤ ∑ k ∈ (range (n + 1)).filter (fun k => exactKeeps n k α p), binomChance n k p := by
  set f : ℕ → ℝ := fun k => binomChance n k p with hf
  have hf0 : ∀ k, 0 ≤ f k := fun k => binomChance_nonneg n k p hp0 hp1
  set s := range (n + 1) with hs
  have htot : ∑ k ∈ s, f k = 1 := binomChance_sum_eq_one n p
  have hsplit := Finset.sum_filter_add_sum_filter_not s (fun k => exactKeeps n k α p) f
  set E := s.filter (fun k => ¬ exactKeeps n k α p) with hE
  set U := s.filter (fun k => upperTail n k p < α / 2) with hU
  set L := s.filter (fun k => lowerTail n k p < α / 2) with hL
  have hEsub : E ⊆ U ∪ L := by
    intro k hk
    rw [hE, Finset.mem_filter] at hk
    obtain ⟨hks, hkn⟩ := hk
    rw [Finset.mem_union, hU, hL, Finset.mem_filter, Finset.mem_filter]
    unfold exactKeeps at hkn
    by_cases h1 : α / 2 ≤ upperTail n k p
    · right
      refine ⟨hks, ?_⟩
      by_contra h2
      exact hkn ⟨h1, not_lt.mp h2⟩
    · left
      exact ⟨hks, not_le.mp h1⟩
  have hUb : ∑ k ∈ U, f k ≤ α / 2 := by
    rcases U.eq_empty_or_nonempty with h | h
    · rw [h, Finset.sum_empty]; linarith
    · have hmin := U.min'_mem h
      replace hmin := (Finset.mem_filter.mp hmin)
      have hsub : U ⊆ Icc (U.min' h) n := by
        intro k hk
        have hk' := hk
        rw [hU, Finset.mem_filter, hs, Finset.mem_range] at hk'
        rw [Finset.mem_Icc]
        exact ⟨U.min'_le k hk, by omega⟩
      have := Finset.sum_le_sum_of_subset_of_nonneg hsub (fun k _ _ => hf0 k)
      have h2 := hmin.2
      unfold upperTail at h2
      linarith
  have hLb : ∑ k ∈ L, f k ≤ α / 2 := by
    rcases L.eq_empty_or_nonempty with h | h
    · rw [h, Finset.sum_empty]; linarith
    · have hmax := L.max'_mem h
      replace hmax := (Finset.mem_filter.mp hmax)
      have hsub : L ⊆ range (L.max' h + 1) := by
        intro k hk
        rw [Finset.mem_range]
        have := L.le_max' k hk
        omega
      have := Finset.sum_le_sum_of_subset_of_nonneg hsub (fun k _ _ => hf0 k)
      have h2 := hmax.2
      unfold lowerTail at h2
      linarith
  have hEb : ∑ k ∈ E, f k ≤ α := by
    have h1 := Finset.sum_le_sum_of_subset_of_nonneg hEsub (fun k _ _ => hf0 k)
    have h2 := Finset.sum_union_inter (s₁ := U) (s₂ := L) (f := f)
    have h3 : 0 ≤ ∑ k ∈ U ∩ L, f k := Finset.sum_nonneg (fun k _ => hf0 k)
    linarith
  linarith

/-- Wilson's keep rule solves to an interval: for `k` of `n` (with `n ≥ 1`), `p̂ = k / n` and
`z > 0`, a candidate rate `p` has `|p̂ − p| ≤ z √(p(1 − p)/n)` exactly when `p` lies between
the Wilson ends `W₋` and `W₊`. -/
theorem wilson_keep_rule_iff_between_wilson_ends
    (n k : ℕ) (hn : 0 < n) (hk : k ≤ n) (z p : ℝ) (hz : 0 < z) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    |(k / n : ℝ) - p| ≤ z * Real.sqrt (p * (1 - p) / n) ↔
      wilsonLower n k z ≤ p ∧ p ≤ wilsonUpper n k z := by
  have hm : (0 : ℝ) < n := by exact_mod_cast hn
  have ha : 0 < 1 + z ^ 2 / n := by positivity
  have key := wilson_key n k hn hk z p
  have hle := wilsonLower_le_upper n k hn z hz
  have hX : 0 ≤ p * (1 - p) / n := by
    have : 0 ≤ 1 - p := by linarith
    positivity
  rw [show z * Real.sqrt (p * (1 - p) / n) = Real.sqrt (z ^ 2 * (p * (1 - p) / n)) by
    rw [Real.sqrt_mul (sq_nonneg z), Real.sqrt_sq hz.le]]
  rw [Real.le_sqrt (abs_nonneg _) (by positivity), sq_abs]
  set L := wilsonLower n k z
  set U := wilsonUpper n k z
  constructor
  · intro h
    have h1 : (p - L) * (p - U) ≤ 0 := by
      by_contra hc
      push Not at hc
      have := mul_pos ha hc
      nlinarith
    constructor
    · by_contra hc
      push Not at hc
      nlinarith
    · by_contra hc
      push Not at hc
      nlinarith
  · rintro ⟨h1, h2⟩
    have : (p - L) * (p - U) ≤ 0 := mul_nonpos_of_nonneg_of_nonpos (by linarith) (by linarith)
    have := mul_nonpos_of_nonneg_of_nonpos ha.le this
    nlinarith

/-- The Wilson ends stay inside 0 to 1, one on each side of the observed rate:
`0 ≤ W₋ ≤ p̂ ≤ W₊ ≤ 1`. -/
theorem wilson_ends_in_unit_interval_around_observed_rate
    (n k : ℕ) (hn : 0 < n) (hk : k ≤ n) (z : ℝ) (hz : 0 < z) :
    0 ≤ wilsonLower n k z ∧ wilsonLower n k z ≤ (k / n : ℝ) ∧
      (k / n : ℝ) ≤ wilsonUpper n k z ∧ wilsonUpper n k z ≤ 1 := by
  have hm : (0 : ℝ) < n := by exact_mod_cast hn
  have ha : 0 < 1 + z ^ 2 / n := by positivity
  have hq0 : (0 : ℝ) ≤ (k / n : ℝ) := by positivity
  have hq1 : (k / n : ℝ) ≤ 1 := by
    rw [div_le_one hm]; exact_mod_cast hk
  have hle := wilsonLower_le_upper n k hn z hz
  have hUpos := wilsonUpper_pos n k hn z hz
  have hLlt := wilsonLower_lt_one n k hn hk z hz
  have kq := wilson_key n k hn hk z (k / n : ℝ)
  have k0 := wilson_key n k hn hk z 0
  have k1 := wilson_key n k hn hk z 1
  set q : ℝ := (k / n : ℝ)
  set L := wilsonLower n k z
  set U := wilsonUpper n k z
  have hX : 0 ≤ z ^ 2 * (q * (1 - q) / n) := by
    have : 0 ≤ 1 - q := by linarith
    positivity
  have hprod : (q - L) * (q - U) ≤ 0 := by
    by_contra hc
    push Not at hc
    have := mul_pos ha hc
    nlinarith
  have hLq : L ≤ q := by
    by_contra hc
    push Not at hc
    nlinarith
  have hqU : q ≤ U := by
    by_contra hc
    push Not at hc
    nlinarith
  refine ⟨?_, hLq, hqU, ?_⟩
  · by_contra hc
    push Not at hc
    have : (1 + z ^ 2 / n) * ((0 - L) * (0 - U)) < 0 := by
      apply mul_neg_of_pos_of_neg ha
      apply mul_neg_of_pos_of_neg <;> linarith
    have : (1 + z ^ 2 / n) * (0 - L) * (0 - U) = q ^ 2 := by
      rw [← k0]; ring
    nlinarith [sq_nonneg q]
  · by_contra hc
    push Not at hc
    have : (1 + z ^ 2 / n) * ((1 - L) * (1 - U)) < 0 := by
      apply mul_neg_of_pos_of_neg ha
      apply mul_neg_of_pos_of_neg <;> linarith
    have : (1 + z ^ 2 / n) * (1 - L) * (1 - U) = (q - 1) ^ 2 := by
      rw [← k1]; ring
    nlinarith

/-! The card's worked numbers: 45 recoveries in 100 patients, 35 on placebo, 0 rashes. -/

-- The observed rate 45/100 is 9/20, and p̂(1 − p̂)/n = 0.45 × 0.55 / 100 = 0.002475 = 99/40000.
example : (45 : ℚ) / 100 = 9 / 20 ∧ (45 / 100 : ℚ) * (1 - 45 / 100) / 100 = 99 / 40000 := by
  norm_num

-- The placebo arm: 35/100 = 7/20, and p̂(1 − p̂)/n = 0.35 × 0.65 / 100 = 91/40000.
example : (35 : ℚ) / 100 = 7 / 20 ∧ (35 / 100 : ℚ) * (1 - 35 / 100) / 100 = 91 / 40000 := by
  norm_num

-- Wald on 0 rashes in 100: the estimated spread is 0, so the interval is 0 to 0, whatever z is.
example (z : ℝ) :
    (0 / 100 : ℝ) - z * Real.sqrt ((0 / 100) * (1 - 0 / 100) / 100) = 0 ∧
      (0 / 100 : ℝ) + z * Real.sqrt ((0 / 100) * (1 - 0 / 100) / 100) = 0 := by
  norm_num

-- For 0 rashes in 100, the chance of 0 or fewer is B₀(p) = (1 − p)^100.
example (p : ℝ) : lowerTail 100 0 p = (1 - p) ^ 100 := by
  norm_num [lowerTail, binomChance]

#print axioms binomChance_nonneg
#print axioms binomChance_sum_eq_one
#print axioms wilson_key_aux
#print axioms wilson_key
#print axioms wilsonUpper_pos
#print axioms wilsonLower_lt_one
#print axioms wilsonLower_le_upper
#print axioms exact_interval_coverage_at_least_one_minus_alpha
#print axioms wilson_keep_rule_iff_between_wilson_ends
#print axioms wilson_ends_in_unit_interval_around_observed_rate
