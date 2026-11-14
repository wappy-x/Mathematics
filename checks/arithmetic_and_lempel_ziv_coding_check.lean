-- Arithmetic and Lempel-Ziv coding: for independent days with known chances, sending each n-day message as ⌈log2(1/W)⌉ bits, where W is the product of its days' chances, always lands a binary fraction inside its slice and costs less than the entropy plus 1/n bits a day on average.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Data.Nat.Log
import Mathlib.Tactic.NormNum

open Finset

/-- Helper: the expected value of one day's cost `g (x j)` under the product weights equals
the one-day average `∑ a, p a * g a`. -/
theorem weighted_day_sum
    {α : Type*} [Fintype α] (p : α → ℝ) (hp1 : ∑ a, p a = 1) (n : ℕ) (g : α → ℝ) (j : Fin n) :
    ∑ x : Fin n → α, (∏ i, p (x i)) * g (x j) = ∑ a, p a * g a := by
  classical
  have key := Fintype.prod_sum (fun (i : Fin n) a => p a * (if i = j then g a else 1))
  have hR : ∀ x : Fin n → α, ∏ i, p (x i) * (if i = j then g (x i) else 1)
      = (∏ i, p (x i)) * g (x j) := by
    intro x
    rw [Finset.prod_mul_distrib, Finset.prod_ite_eq' Finset.univ j (fun i => g (x i))]
    simp
  have hL : ∏ i : Fin n, ∑ a, p a * (if i = j then g a else 1) = ∑ a, p a * g a := by
    rw [Finset.prod_eq_single j]
    · simp
    · intro i _ hij; simp [hij, hp1]
    · intro h; exact absurd (Finset.mem_univ j) h
  rw [← hL, key]
  exact Finset.sum_congr rfl (fun x _ => (hR x).symm)

/-- Helper: the average total information over n-day messages is n times the entropy. -/
theorem weighted_info_sum
    {α : Type*} [Fintype α] (p : α → ℝ) (hp1 : ∑ a, p a = 1) (n : ℕ) :
    ∑ x : Fin n → α, (∏ j, p (x j)) * Real.logb 2 (1 / ∏ j, p (x j))
      = n * ∑ a, p a * Real.logb 2 (1 / p a) := by
  have hterm : ∀ x : Fin n → α, (∏ j, p (x j)) * Real.logb 2 (1 / ∏ j, p (x j))
      = ∑ j, (∏ i, p (x i)) * Real.logb 2 (1 / p (x j)) := by
    intro x
    rw [← Finset.mul_sum]
    by_cases h : ∏ j, p (x j) = 0
    · rw [h]; simp
    · congr 1
      have hne : ∀ j ∈ (Finset.univ : Finset (Fin n)), p (x j) ≠ 0 := by
        intro j _ hj; exact h (Finset.prod_eq_zero (Finset.mem_univ j) hj)
      simp only [one_div, Real.logb_inv]
      rw [Real.logb_prod _ _ hne, Finset.sum_neg_distrib]
  rw [Finset.sum_congr rfl (fun x _ => hterm x), Finset.sum_comm]
  simp only [weighted_day_sum p hp1 n (fun a => Real.logb 2 (1 / p a))]
  simp

/-- Arithmetic coding is within one bit of the entropy, per message. The days are independent,
each one a reading `a` with chance `p a` (the chances are at least 0 and add up to 1). An
n-day message `x` gets a slice of width `W = p(x 1) ⋯ p(x n)` and is sent in
`⌈log2(1/W)⌉` bits. Averaged over all n-day messages, weighted by their chances, the cost per
day is less than the entropy `H = Σ p a · log2(1/p a)` plus one bit shared over the n days. -/
theorem arithmetic_code_average_lt_entropy_add_inv_length
    {α : Type*} [Fintype α] (p : α → ℝ) (hp0 : ∀ a, 0 ≤ p a) (hp1 : ∑ a, p a = 1)
    (n : ℕ) (hn : 0 < n) :
    (∑ x : Fin n → α,
        (∏ j, p (x j)) * (⌈Real.logb 2 (1 / ∏ j, p (x j))⌉₊ : ℝ)) / n
      < (∑ a, p a * Real.logb 2 (1 / p a)) + 1 / n := by
  set w : (Fin n → α) → ℝ := fun x => ∏ j, p (x j) with hw
  have hw0 : ∀ x, 0 ≤ w x := fun x => Finset.prod_nonneg (fun j _ => hp0 _)
  have hw1 : ∑ x, w x = 1 := by
    rw [← Fintype.prod_sum (fun (_ : Fin n) a => p a)]; simp [hp1]
  have hwle : ∀ x, w x ≤ 1 := fun x => by
    rw [← hw1]; exact Finset.single_le_sum (fun y _ => hw0 y) (Finset.mem_univ x)
  have hle : ∀ x ∈ (Finset.univ : Finset (Fin n → α)),
      w x * (⌈Real.logb 2 (1 / w x)⌉₊ : ℝ) ≤ w x * (Real.logb 2 (1 / w x) + 1) := by
    intro x _
    rcases (hw0 x).eq_or_lt with h | h
    · rw [← h]; simp
    · apply mul_le_mul_of_nonneg_left _ (hw0 x)
      have : 0 ≤ Real.logb 2 (1 / w x) :=
        Real.logb_nonneg (by norm_num) (by rw [le_div_iff₀ h]; linarith [hwle x])
      exact (Nat.ceil_lt_add_one this).le
  have hex : ∃ x ∈ (Finset.univ : Finset (Fin n → α)),
      w x * (⌈Real.logb 2 (1 / w x)⌉₊ : ℝ) < w x * (Real.logb 2 (1 / w x) + 1) := by
    by_contra hcon
    push Not at hcon
    have hpos : ∃ x, 0 < w x := by
      by_contra h'
      push Not at h'
      have : ∑ x, w x ≤ 0 := Finset.sum_nonpos (fun x _ => h' x)
      linarith
    obtain ⟨x, hx⟩ := hpos
    have h0 : 0 ≤ Real.logb 2 (1 / w x) :=
      Real.logb_nonneg (by norm_num) (by rw [le_div_iff₀ hx]; linarith [hwle x])
    have := hcon x (Finset.mem_univ x)
    have := mul_lt_mul_of_pos_left (Nat.ceil_lt_add_one h0) hx
    linarith
  have hlt := Finset.sum_lt_sum hle hex
  have hsum : ∑ x, w x * (Real.logb 2 (1 / w x) + 1)
      = n * ∑ a, p a * Real.logb 2 (1 / p a) + 1 := by
    simp only [mul_add, mul_one, Finset.sum_add_distrib, hw1]
    rw [hw, weighted_info_sum p hp1 n]
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  rw [div_lt_iff₀ hnR, add_mul, div_mul_cancel₀ _ hnR.ne']
  have : ∑ x, w x * (⌈Real.logb 2 (1 / w x)⌉₊ : ℝ) < n * ∑ a, p a * Real.logb 2 (1 / p a) + 1 := by
    rw [← hsum]; exact hlt
  simpa [hw, mul_comm] using this

/-- The slices tile the ruler: the widths of all n-day slices, each the product of its days'
chances, add up to the whole ruler, 1. -/
theorem slice_widths_add_to_one
    {α : Type*} [Fintype α] (p : α → ℝ) (hp1 : ∑ a, p a = 1) (n : ℕ) :
    ∑ x : Fin n → α, ∏ j, p (x j) = 1 := by
  rw [← Fintype.prod_sum (fun (_ : Fin n) a => p a)]
  simp [hp1]

/-- Enough bits to land inside: for any slice from `L` to `L + W` with width `W > 0`, with
`ℓ = ⌈log2(1/W)⌉` there is an ℓ-digit binary fraction `m / 2^ℓ` inside it, at or above `L`
and below `L + W`. -/
theorem binary_fraction_lands_in_slice (L W : ℝ) (hW : 0 < W) :
    ∃ m : ℤ, L ≤ (m : ℝ) / 2 ^ ⌈Real.logb 2 (1 / W)⌉₊ ∧
      (m : ℝ) / 2 ^ ⌈Real.logb 2 (1 / W)⌉₊ < L + W := by
  set ℓ := ⌈Real.logb 2 (1 / W)⌉₊
  have hpos : (0 : ℝ) < 2 ^ ℓ := by positivity
  have hbig : 1 / W ≤ (2 : ℝ) ^ ℓ := by
    have h1 : Real.logb 2 (1 / W) ≤ (ℓ : ℝ) := Nat.le_ceil _
    calc 1 / W = (2 : ℝ) ^ (Real.logb 2 (1 / W)) := (Real.rpow_logb (by norm_num) (by norm_num) (by positivity)).symm
      _ ≤ (2 : ℝ) ^ (ℓ : ℝ) := Real.rpow_le_rpow_of_exponent_le (by norm_num) h1
      _ = (2 : ℝ) ^ ℓ := Real.rpow_natCast 2 ℓ
  have hstep : 1 / (2 : ℝ) ^ ℓ ≤ W := by
    rw [div_le_iff₀ hpos]
    rw [div_le_iff₀ hW] at hbig
    linarith
  refine ⟨⌈L * 2 ^ ℓ⌉, ?_, ?_⟩
  · rw [le_div_iff₀ hpos]; exact Int.le_ceil _
  · have := Int.ceil_lt_add_one (L * 2 ^ ℓ)
    have : ((⌈L * 2 ^ ℓ⌉ : ℤ) : ℝ) / 2 ^ ℓ < L + 1 / 2 ^ ℓ := by
      rw [div_lt_iff₀ hpos, add_mul, div_mul_cancel₀ _ hpos.ne']; exact this
    linarith

-- The month: 24 cloudy days at 8/10 and 6 sunny or rainy days at 1/10. Width = 8^24 / 10^30.
example : (8 : ℕ) ^ 24 * 1 ^ 6 = 4722366482869645213696 := by norm_num
-- ⌈log2(10^30 / 8^24)⌉ = 28: a step of 2^-28 fits in the slice, 2^-27 does not.
example : 2 ^ 27 * 8 ^ 24 < (10 : ℕ) ^ 30 ∧ (10 : ℕ) ^ 30 ≤ 2 ^ 28 * 8 ^ 24 := by norm_num
-- 10^30 is about 2^99.7.
example : (2 : ℕ) ^ 99 < 10 ^ 30 ∧ (10 : ℕ) ^ 30 < 2 ^ 100 := by norm_num
-- The 28-bit code 1000100000000101100100010101 lies in the month's slice, whose low end is
-- 531334953587380200023328292864 / 10^30.
example : (0b1000100000000101100100010101 : ℕ) = 142629141 := by norm_num
example : 531334953587380200023328292864 * 2 ^ 28 ≤ 142629141 * (10 : ℕ) ^ 30 ∧
    142629141 * (10 : ℕ) ^ 30 < (531334953587380200023328292864 + 8 ^ 24) * 2 ^ 28 := by norm_num
-- Huffman 36 bits; arithmetic coding one day at a time, ⌈log2(10/8)⌉ = 1 and ⌈log2 10⌉ = 4: 48 bits.
example : 24 * 1 + 3 * 2 + 3 * 2 = 36 := by norm_num
example : Nat.clog 2 1 = 0 ∧ Nat.clog 2 10 = 4 ∧ 24 * 1 + 6 * 4 = 48 := by decide
-- First five days C C S C C: width 8·8·1·8·8 / 10^5 = 4096 / 100000, so 5 bits.
example : 8 * 8 * 1 * 8 * 8 = 4096 ∧ 2 ^ 4 * 4096 < 100000 ∧ 100000 ≤ 2 ^ 5 * 4096 := by norm_num
-- The slices narrow: 0 to 8/10, 0 to 64/100, 512/1000 to 576/1000, 512/1000 to 5632/10^4, 512/1000 to 55296/10^5.
example : (512 : ℚ) / 1000 = 64 / 100 * 8 / 10 ∧ (576 : ℚ) / 1000 = 64 / 100 * 9 / 10 ∧
    (5632 : ℚ) / 10000 = 512 / 1000 + (576 / 1000 - 512 / 1000) * 8 / 10 ∧
    (55296 : ℚ) / 100000 = 512 / 1000 + (5632 / 10000 - 512 / 1000) * 8 / 10 := by norm_num
-- The code 0.10001 in binary = 17/32 sits in [512/1000, 55296/100000).
example : (512 : ℚ) / 1000 ≤ 17 / 32 ∧ (17 : ℚ) / 32 < 55296 / 100000 := by norm_num
-- One day at a time on average: 8/10 · 1 + 1/10 · 4 + 1/10 · 4 = 16/10 bits a day.
example : (8 : ℚ) / 10 * 1 + 1 / 10 * 4 + 1 / 10 * 4 = 16 / 10 := by norm_num
-- LZ78 on the month: 11 phrases, phrase i costs ⌈log2 i⌉ + 2 bits, the last needs no reading: 49 bits.
example : (∑ i ∈ Icc 1 11, (Nat.clog 2 i + 2)) - 2 = 49 := by decide
example : 2 + 3 + 4 + 4 + 5 + 5 + 5 + 5 + 6 + 6 + 4 = 49 := by norm_num

#print axioms weighted_day_sum
#print axioms weighted_info_sum
#print axioms arithmetic_code_average_lt_entropy_add_inv_length
#print axioms slice_widths_add_to_one
#print axioms binary_fraction_lands_in_slice
