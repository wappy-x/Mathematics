-- Cauchy condensation: for terms that are never negative and never rise, the series and its condensed series of 2^k times the term at 2^k converge or diverge together, the running total to 2^K sits between half and all of the condensed total, and the sum of 1/(n (ln n)^p) converges exactly when p > 1.
import Mathlib.Analysis.PSeries
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Analysis.Complex.ExponentialBounds

open Finset

/-- Lower half of the sandwich, on the blocks `(2^(k-1), 2^k]`. -/
lemma condensed_lower_aux (a : ℕ → ℝ) (h_mono : Antitone a) (K : ℕ) (hK : 1 ≤ K) :
    (1 / 2 : ℝ) * ∑ k ∈ Icc 1 K, (2 : ℝ) ^ k * a (2 ^ k) ≤ ∑ n ∈ Ioc 1 (2 ^ K), a n := by
  induction K, hK using Nat.le_induction with
  | base => simp
  | succ K hK ih =>
    rw [sum_Icc_succ_top (by omega), ← sum_Ioc_consecutive _ (m := 1) (n := 2 ^ K)
      (Nat.one_le_two_pow) (Nat.pow_le_pow_right (by norm_num) (by omega))]
    have hblock : (2 : ℝ) ^ K * a (2 ^ (K + 1)) ≤ ∑ n ∈ Ioc (2 ^ K) (2 ^ (K + 1)), a n := by
      have := card_nsmul_le_sum (Ioc (2 ^ K) (2 ^ (K + 1))) a (a (2 ^ (K + 1)))
        (fun x hx => h_mono (mem_Ioc.mp hx).2)
      rw [Nat.card_Ioc, nsmul_eq_mul] at this
      have h2 : (2 : ℕ) ^ (K + 1) - 2 ^ K = 2 ^ K := by rw [pow_succ]; omega
      rw [h2] at this
      push_cast at this
      exact this
    have : (1 / 2 : ℝ) * ((2 : ℝ) ^ (K + 1) * a (2 ^ (K + 1))) = (2 : ℝ) ^ K * a (2 ^ (K + 1)) := by
      rw [pow_succ]; ring
    rw [mul_add, this]
    exact add_le_add ih hblock

#print axioms condensed_lower_aux

/-- Upper half of the sandwich, on the blocks `[2^(k-1), 2^k)`, with the end term kept apart. -/
lemma condensed_upper_aux (a : ℕ → ℝ) (h_mono : Antitone a) (K : ℕ) (hK : 1 ≤ K) :
    ∑ n ∈ Ico 2 (2 ^ K), a n + (2 : ℝ) ^ K * a (2 ^ K) ≤ ∑ k ∈ Icc 1 K, (2 : ℝ) ^ k * a (2 ^ k) := by
  induction K, hK using Nat.le_induction with
  | base => simp
  | succ K hK ih =>
    rw [sum_Icc_succ_top (by omega), ← sum_Ico_consecutive _ (m := 2) (n := 2 ^ K)
      (by calc 2 = 2 ^ 1 := by norm_num
               _ ≤ 2 ^ K := Nat.pow_le_pow_right (by norm_num) hK)
      (Nat.pow_le_pow_right (by norm_num) (by omega))]
    have hblock : ∑ n ∈ Ico (2 ^ K) (2 ^ (K + 1)), a n ≤ (2 : ℝ) ^ K * a (2 ^ K) := by
      have := sum_le_card_nsmul (Ico (2 ^ K) (2 ^ (K + 1))) a (a (2 ^ K))
        (fun x hx => h_mono (mem_Ico.mp hx).1)
      rw [Nat.card_Ico, nsmul_eq_mul] at this
      have h2 : (2 : ℕ) ^ (K + 1) - 2 ^ K = 2 ^ K := by rw [pow_succ]; omega
      rw [h2] at this
      push_cast at this
      exact this
    linarith

#print axioms condensed_upper_aux

/-- Cauchy condensation test: when the terms `a n` are never negative and never rise,
the series `∑ a n` converges exactly when the condensed series `∑ 2^k a (2^k)` converges. -/
theorem summable_iff_summable_condensed (a : ℕ → ℝ)
    (h_nonneg : ∀ n, 0 ≤ a n) (h_mono : Antitone a) :
    Summable a ↔ Summable (fun k : ℕ => (2 : ℝ) ^ k * a (2 ^ k)) := by
  exact (summable_condensed_iff_of_nonneg h_nonneg (fun _ _ _ h => h_mono h)).symm

/-- The sandwich: for terms that are never negative and never rise, and every whole number
`K ≥ 1`, the running total from `n = 2` to `2^K` lies between half the condensed total
`∑_{k=1}^{K} 2^k a (2^k)` and the whole condensed total. -/
theorem condensed_sandwich (a : ℕ → ℝ)
    (h_nonneg : ∀ n, 0 ≤ a n) (h_mono : Antitone a) (K : ℕ) (hK : 1 ≤ K) :
    (1 / 2 : ℝ) * ∑ k ∈ Icc 1 K, (2 : ℝ) ^ k * a (2 ^ k) ≤ ∑ n ∈ Icc 2 (2 ^ K), a n ∧
      ∑ n ∈ Icc 2 (2 ^ K), a n ≤ ∑ k ∈ Icc 1 K, (2 : ℝ) ^ k * a (2 ^ k) := by
  have hpow : 2 ≤ 2 ^ K := by
    calc 2 = 2 ^ 1 := by norm_num
         _ ≤ 2 ^ K := Nat.pow_le_pow_right (by norm_num) hK
  have e1 : Icc 2 (2 ^ K) = Ioc 1 (2 ^ K) := by ext x; simp only [mem_Icc, mem_Ioc]; omega
  have e2 : Icc 2 (2 ^ K) = Ico 2 (2 ^ K + 1) := by ext x; simp only [mem_Icc, mem_Ico]; omega
  refine ⟨e1 ▸ condensed_lower_aux a h_mono K hK, ?_⟩
  rw [e2, sum_Ico_succ_top hpow]
  have hu := condensed_upper_aux a h_mono K hK
  have h1 : a (2 ^ K) ≤ (2 : ℝ) ^ K * a (2 ^ K) := by
    have : (1 : ℝ) ≤ 2 ^ K := one_le_pow₀ (by norm_num)
    nlinarith [h_nonneg (2 ^ K)]
  linarith

/-- The log family: the sum of `1 / (n (ln n)^p)` converges exactly when `p > 1`.
At `p = 1` (the terms `1/(n ln n)`) it diverges; at `p = 2` it converges. -/
theorem summable_one_div_nat_mul_log_rpow_iff (p : ℝ) :
    Summable (fun n : ℕ => 1 / ((n : ℝ) * Real.log n ^ p)) ↔ 1 < p := by
  set f : ℕ → ℝ := fun n => 1 / ((n : ℝ) * Real.log n ^ p) with hf
  rcases le_or_gt p 0 with hp | hp
  · -- p ≤ 0: from n = 3 on, (ln n)^p ≤ 1, so each term is at least 1/n.
    refine iff_of_false ?_ (by linarith)
    intro hs
    rw [← summable_nat_add_iff 3] at hs
    apply Real.not_summable_one_div_natCast
    rw [← summable_nat_add_iff 3]
    refine hs.of_nonneg_of_le (fun n => by positivity) (fun n => ?_)
    have hn : (0 : ℝ) < (n + 3 : ℕ) := by positivity
    have hlog : 1 ≤ Real.log ((n + 3 : ℕ) : ℝ) := by
      rw [Real.le_log_iff_exp_le (by positivity)]
      have := Real.exp_one_lt_d9
      push_cast
      have : (0 : ℝ) ≤ n := n.cast_nonneg
      linarith
    have hr : Real.log ((n + 3 : ℕ) : ℝ) ^ p ≤ 1 := Real.rpow_le_one_of_one_le_of_nonpos hlog hp
    have hr0 : 0 < Real.log ((n + 3 : ℕ) : ℝ) ^ p := Real.rpow_pos_of_pos (by linarith) p
    simp only [hf]
    apply one_div_le_one_div_of_le (by positivity)
    nlinarith
  · -- p > 0: condense.
    have hnn : 0 ≤ᶠ[Filter.atTop] f := Filter.Eventually.of_forall fun n => by
      simp only [hf, Pi.zero_apply]
      have := Real.log_natCast_nonneg n
      positivity
    have hmono : ∀ᶠ k in Filter.atTop, f (k + 1) ≤ f k := by
      filter_upwards [Filter.eventually_ge_atTop 2] with k hk
      have hk' : (2 : ℝ) ≤ k := by exact_mod_cast hk
      have hlog : 0 < Real.log k := Real.log_pos (by linarith)
      have hlog' : Real.log k ≤ Real.log ((k + 1 : ℕ) : ℝ) :=
        Real.log_le_log (by linarith) (by push_cast; linarith)
      simp only [hf]
      apply one_div_le_one_div_of_le (mul_pos (by linarith) (Real.rpow_pos_of_pos hlog p))
      apply mul_le_mul (by push_cast; linarith) (Real.rpow_le_rpow hlog.le hlog' hp.le)
        (Real.rpow_pos_of_pos hlog p).le (by positivity)
    rw [← summable_condensed_iff_of_eventually_nonneg hnn hmono]
    have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
    have heq : (fun k : ℕ => (2 : ℝ) ^ k * f (2 ^ k)) =
        fun k : ℕ => (1 / Real.log 2 ^ p) * (1 / (k : ℝ) ^ p) := by
      funext k
      simp only [hf]
      push_cast
      rw [Real.log_pow, Real.mul_rpow (Nat.cast_nonneg k) hl2.le]
      have h2k : (0 : ℝ) < 2 ^ k := by positivity
      field_simp
    rw [heq, summable_mul_left_iff (by have := Real.rpow_pos_of_pos hl2 p; positivity),
      Real.summable_one_div_nat_rpow]

-- k = 20 is position 1,048,576.
example : 2 ^ 20 = 1048576 := by norm_num

-- The doubling block from 4 to 7 holds 4 = 2^2 terms; so does the shifted block 5 to 8.
example : (Ico 4 8).card = 2 ^ 2 := by decide
example : (Ioc 4 8).card = 2 ^ 2 := by decide

-- p = 2: the condensed terms 2^k / (2^k)^2 are 1/2 + 1/4 + ... ; to k = 20 they add to 1 - 1/2^20.
example : ∑ k ∈ Icc 1 20, (2 : ℚ) ^ k * (1 / ((2 : ℚ) ^ k) ^ 2) = 1 - 1 / 2 ^ 20 := by
  norm_num [Finset.sum_Icc_succ_top]

-- 999983, the largest prime below a million on the card, is prime.
example : Nat.Prime 999983 := by norm_num

#print axioms summable_iff_summable_condensed
#print axioms condensed_sandwich
#print axioms summable_one_div_nat_mul_log_rpow_iff
