-- Hypergeometric: when every set of n items from a pool of N, K of them marked, is equally likely, the chance of exactly k marked items is C(K, k) C(N - K, n - k) / C(N, n), the average count is n K / N, the variance is n p (1 - p) (N - n)/(N - 1) with p = K/N, and the card's 6-from-49 lottery numbers check out.
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination
import Mathlib.Data.Nat.Choose.Cast

namespace Hypergeometric

open Finset

/-- Counting samples by how many marked items they hold. -/
theorem card_filter_inter_eq {α : Type*} [Fintype α] [DecidableEq α]
    (M : Finset α) (n k : ℕ) (hk : k ≤ n) :
    ((powersetCard n (univ : Finset α)).filter (fun s => (s ∩ M).card = k)).card
      = M.card.choose k * (Fintype.card α - M.card).choose (n - k) := by
  rw [← card_powersetCard, ← card_univ, ← card_sdiff_of_subset (subset_univ M),
    ← card_powersetCard, ← card_product]
  refine card_bij' (fun s _ => (s ∩ M, s \ M)) (fun p _ => p.1 ∪ p.2) ?_ ?_ ?_ ?_
  · intro s hs
    simp only [mem_filter, mem_powersetCard, subset_univ, true_and] at hs
    have h := card_sdiff_add_card_inter s M
    simp only [mem_product, mem_powersetCard]
    refine ⟨⟨inter_subset_right, hs.2⟩, ⟨sdiff_subset_sdiff (subset_univ _) le_rfl, ?_⟩⟩
    omega
  · rintro ⟨a, b⟩ hp
    simp only [mem_product, mem_powersetCard] at hp
    obtain ⟨⟨haM, ha⟩, ⟨hbM, hb⟩⟩ := hp
    have hdisj : Disjoint a b := by
      rw [disjoint_left]
      intro x hxa hxb
      have := hbM hxb
      simp only [mem_sdiff] at this
      exact this.2 (haM hxa)
    have hinter : (a ∪ b) ∩ M = a := by
      ext x
      have h1 := @haM x
      have h2 := @hbM x
      simp only [mem_sdiff, mem_univ, true_and] at h2
      simp only [mem_inter, mem_union]
      tauto
    simp only [mem_filter, mem_powersetCard, subset_univ, true_and]
    refine ⟨?_, ?_⟩
    · rw [card_union_of_disjoint hdisj]; omega
    · rw [hinter, ha]
  · intro s _
    ext x
    simp only [mem_union, mem_inter, mem_sdiff]
    tauto
  · rintro ⟨a, b⟩ hp
    simp only [mem_product, mem_powersetCard] at hp
    obtain ⟨⟨haM, _⟩, ⟨hbM, _⟩⟩ := hp
    have h1 := @haM
    have h2 := @hbM
    simp only [Prod.mk.injEq]
    constructor
    · ext x
      have := @h1 x
      have := @h2 x
      simp only [mem_sdiff, mem_univ, true_and] at *
      simp only [mem_inter, mem_union]
      tauto
    · ext x
      have := @h1 x
      have := @h2 x
      simp only [mem_sdiff, mem_univ, true_and] at *
      simp only [mem_union]
      tauto

/-- Samples that contain a given set `t` of `j` items. -/
theorem card_filter_superset {α : Type*} [Fintype α] [DecidableEq α]
    (t : Finset α) (n : ℕ) (hj : t.card ≤ n) :
    ((powersetCard n (univ : Finset α)).filter (fun s => t ⊆ s)).card
      = (Fintype.card α - t.card).choose (n - t.card) := by
  have := card_filter_inter_eq t n t.card hj
  rw [Nat.choose_self, one_mul] at this
  rw [← this]
  congr 1
  apply filter_congr
  intro s _
  constructor
  · intro h; rw [inter_eq_right.mpr h]
  · intro h
    have := eq_of_subset_of_card_le (inter_subset_right (s₁ := s) (s₂ := t)) (le_of_eq h.symm)
    exact inter_eq_right.mp this

/-- Sum over samples of C(count, j): pick the `j` marked items first. -/
theorem sum_choose_card_inter {α : Type*} [Fintype α] [DecidableEq α]
    (M : Finset α) (n j : ℕ) (hj : j ≤ n) :
    ∑ s ∈ powersetCard n (univ : Finset α), (s ∩ M).card.choose j
      = M.card.choose j * (Fintype.card α - j).choose (n - j) := by
  have h1 : ∀ s : Finset α, (s ∩ M).card.choose j
      = ∑ t ∈ powersetCard j M, if t ⊆ s then 1 else 0 := by
    intro s
    rw [← card_powersetCard, sum_boole, Nat.cast_id]
    congr 1
    ext t
    simp only [mem_powersetCard, mem_filter, subset_inter_iff]
    tauto
  simp_rw [h1]
  rw [sum_comm]
  have h2 : ∀ t ∈ powersetCard j M,
      (∑ s ∈ powersetCard n (univ : Finset α), if t ⊆ s then 1 else 0)
        = (Fintype.card α - j).choose (n - j) := by
    intro t ht
    rw [mem_powersetCard] at ht
    rw [sum_boole, Nat.cast_id, card_filter_superset t n (ht.2 ▸ hj), ht.2]
  rw [sum_congr rfl h2, sum_const, card_powersetCard]
  simp

#print axioms card_filter_inter_eq
#print axioms card_filter_superset
#print axioms sum_choose_card_inter

/-- The card's main result. A pool `α` holds `N` items, and a set `M` of `K` of them is marked.
A sample is a set of `n` items taken without putting anything back, and every such set is equally
likely, so the chance of an event is the number of samples in it divided by the number of all
samples. Then the chance that the sample holds exactly `k` marked items is the number of ways to
choose `k` marked items and `n - k` unmarked ones, divided by the number of ways to choose the
sample: C(K, k) C(N - K, n - k) / C(N, n). Here `k` is one of the values the count can take,
from 0 up to the sample size `n`. -/
theorem hypergeometric_chance_of_k_marked {α : Type*} [Fintype α] [DecidableEq α]
    (M : Finset α) (N K n k : ℕ) (hN : Fintype.card α = N) (hK : M.card = K) (hk : k ≤ n) :
    (((powersetCard n (univ : Finset α)).filter (fun s => (s ∩ M).card = k)).card : ℚ)
        / (powersetCard n (univ : Finset α)).card
      = (K.choose k * (N - K).choose (n - k) : ℚ) / N.choose n := by
  have hS : (powersetCard n (univ : Finset α)).card = N.choose n := by
    rw [card_powersetCard, card_univ, hN]
  rw [hS, card_filter_inter_eq M n k hk, hK, hN]
  push_cast
  rfl

/-- The average count of marked items in the sample is the sample size times the marked share of
the pool, n K / N: the same as when drawing with replacement. Here the average is the sum of the
count over all equally likely samples, divided by the number of samples. -/
theorem hypergeometric_mean {α : Type*} [Fintype α] [DecidableEq α]
    (M : Finset α) (N K n : ℕ) (hN : Fintype.card α = N) (hK : M.card = K) (hn : n ≤ N) :
    (∑ s ∈ powersetCard n (univ : Finset α), ((s ∩ M).card : ℚ))
        / (powersetCard n (univ : Finset α)).card
      = n * ((K : ℚ) / N) := by
  have hS : (powersetCard n (univ : Finset α)).card = N.choose n := by
    rw [card_powersetCard, card_univ, hN]
  rw [hS]
  rcases Nat.eq_zero_or_pos n with rfl | hn0
  · simp [powersetCard_zero]
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  obtain ⟨L, rfl⟩ : ∃ L, N = L + 1 := ⟨N - 1, by omega⟩
  have h1 := sum_choose_card_inter M (m + 1) 1 (by omega)
  simp only [Nat.choose_one_right, hK, hN, Nat.add_sub_cancel] at h1
  have hsum : (∑ s ∈ powersetCard (m + 1) (univ : Finset α), ((s ∩ M).card : ℚ))
      = K * L.choose m := by
    rw [← Nat.cast_sum, h1]; push_cast; ring
  rw [hsum]
  have hid : ((L + 1 : ℕ) : ℚ) * L.choose m = (L + 1).choose (m + 1) * (m + 1 : ℕ) := by
    exact_mod_cast Nat.add_one_mul_choose_eq L m
  have hpos : (0 : ℚ) < (L + 1).choose (m + 1) := by
    exact_mod_cast Nat.choose_pos (by omega)
  have hL : (0 : ℚ) < ((L + 1 : ℕ) : ℚ) := by positivity
  have e : (L.choose m : ℚ) = (L + 1).choose (m + 1) * (m + 1 : ℕ) / (L + 1 : ℕ) := by
    rw [eq_div_iff hL.ne']; linear_combination hid
  rw [e]
  push_cast
  field_simp

/-- The variance of the count (average of its square minus the square of its average, over all
equally likely samples) is the binomial variance n p (1 - p), with p = K / N, times the
finite-population correction (N - n) / (N - 1). The correction needs a pool of at least 2. -/
theorem hypergeometric_variance {α : Type*} [Fintype α] [DecidableEq α]
    (M : Finset α) (N K n : ℕ) (hN : Fintype.card α = N) (hK : M.card = K) (hn : n ≤ N)
    (hN2 : 2 ≤ N) :
    (∑ s ∈ powersetCard n (univ : Finset α), ((s ∩ M).card : ℚ) ^ 2)
        / (powersetCard n (univ : Finset α)).card
      - ((∑ s ∈ powersetCard n (univ : Finset α), ((s ∩ M).card : ℚ))
        / (powersetCard n (univ : Finset α)).card) ^ 2
      = n * ((K : ℚ) / N) * (1 - (K : ℚ) / N) * (((N : ℚ) - n) / ((N : ℚ) - 1)) := by
  have hS : (powersetCard n (univ : Finset α)).card = N.choose n := by
    rw [card_powersetCard, card_univ, hN]
  have hsq : ∀ s : Finset α, ((s ∩ M).card : ℚ) ^ 2
      = 2 * ((s ∩ M).card.choose 2 : ℚ) + (s ∩ M).card := by
    intro s; rw [Nat.cast_choose_two]; ring
  simp_rw [hsq]
  rw [sum_add_distrib, ← mul_sum, hS]
  rcases Nat.eq_zero_or_pos n with rfl | hn0
  · simp [powersetCard_zero]
  obtain ⟨L, rfl⟩ : ∃ L, N = L + 2 := ⟨N - 2, by omega⟩
  have h1 := sum_choose_card_inter M n 1 (by omega)
  simp only [Nat.choose_one_right, hK, hN] at h1
  have hsum1 : (∑ s ∈ powersetCard n (univ : Finset α), ((s ∩ M).card : ℚ))
      = K * (L + 1).choose (n - 1) := by
    rw [← Nat.cast_sum, h1, show L + 2 - 1 = L + 1 by omega]; push_cast; ring
  rw [hsum1]
  have hid1 : ((L + 2 : ℕ) : ℚ) * (L + 1).choose (n - 1) = (L + 2).choose n * (n : ℚ) := by
    have := Nat.add_one_mul_choose_eq (L + 1) (n - 1)
    rw [Nat.sub_add_cancel hn0] at this
    exact_mod_cast this
  have hpos : (0 : ℚ) < (L + 2).choose n := by
    exact_mod_cast Nat.choose_pos (by omega)
  have hL2 : (0 : ℚ) < ((L + 2 : ℕ) : ℚ) := by positivity
  have hL1 : ((L + 2 : ℕ) : ℚ) - 1 = (L + 1 : ℕ) := by push_cast; ring
  rcases Nat.lt_or_ge n 2 with hn2 | hn2
  · -- n = 1: no sample holds two marked items
    have hn1 : n = 1 := by omega
    subst hn1
    have h0 : (∑ s ∈ powersetCard 1 (univ : Finset α), ((s ∩ M).card.choose 2 : ℚ)) = 0 := by
      apply sum_eq_zero
      intro s hs
      rw [mem_powersetCard] at hs
      have : (s ∩ M).card ≤ 1 := hs.2 ▸ card_le_card inter_subset_left
      rw [Nat.choose_eq_zero_of_lt (by omega)]; simp
    rw [h0, hL1]
    simp only [Nat.sub_self, Nat.choose_zero_right, Nat.choose_one_right] at hid1 ⊢
    have hL1' : (0 : ℚ) < ((L + 1 : ℕ) : ℚ) := by positivity
    field_simp
    push_cast
    ring
  · obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
    have h2 := sum_choose_card_inter M (m + 2) 2 (by omega)
    simp only [hK, hN, Nat.add_sub_cancel] at h2
    have hsum2 : (∑ s ∈ powersetCard (m + 2) (univ : Finset α), ((s ∩ M).card.choose 2 : ℚ))
        = K * (K - 1) / 2 * L.choose m := by
      rw [← Nat.cast_sum, h2]; push_cast; rw [Nat.cast_choose_two]
    rw [hsum2]
    have hid2 : ((L + 1 : ℕ) : ℚ) * L.choose m = (L + 1).choose (m + 1) * (m + 1 : ℕ) := by
      exact_mod_cast Nat.add_one_mul_choose_eq L m
    simp only [show m + 2 - 1 = m + 1 by omega] at hid1 ⊢
    rw [hL1]
    have hL1' : (0 : ℚ) < ((L + 1 : ℕ) : ℚ) := by positivity
    set D : ℚ := ((L + 2).choose (m + 2) : ℚ) with hD
    set C1 : ℚ := ((L + 1).choose (m + 1) : ℚ) with hC1
    set C0 : ℚ := ((L).choose m : ℚ) with hC0
    have eC1 : C1 = D * (m + 2 : ℕ) / (L + 2 : ℕ) := by
      rw [eq_div_iff hL2.ne']; linear_combination hid1
    have eC0 : C0 = C1 * (m + 1 : ℕ) / (L + 1 : ℕ) := by
      rw [eq_div_iff hL1'.ne']; linear_combination hid2
    rw [eC0, eC1]
    push_cast
    field_simp
    ring

/-! The card's lottery: 6 balls drawn from 49, a ticket holds 6 numbers. -/

-- All possible draws: 49 × 48 × 47 × 46 × 45 × 44 = 10,068,347,520 ordered draws, / 720 = C(49, 6).
example : 49 * 48 * 47 * 46 * 45 * 44 = 10068347520 := by norm_num
example : Nat.factorial 6 = 720 := by decide
example : 10068347520 / 720 = 13983816 := by norm_num
example : Nat.choose 49 6 = 13983816 := by decide
-- Three matches: C(6, 3) = 20, C(43, 3) = 43 × 42 × 41 / 6 = 12,341, product 246,820.
example : Nat.choose 6 3 = 20 := by decide
example : Nat.choose 43 3 = 12341 ∧ 43 * 42 * 41 / 6 = 12341 := by decide
example : Nat.choose 6 3 * Nat.choose 43 3 = 246820 := by decide
-- The full table of favourable draws for k = 0, ..., 6 matches.
example : (List.range 7).map (fun k => Nat.choose 6 k * Nat.choose 43 (6 - k))
    = [6096454, 5775588, 1851150, 246820, 13545, 258, 1] := by decide
-- The seven counts add up to all 13,983,816 draws.
example : 6096454 + 5775588 + 1851150 + 246820 + 13545 + 258 + 1 = Nat.choose 49 6 := by decide
-- At least three matches: 246,820 + 13,545 + 258 + 1 = 260,624 draws.
example : 246820 + 13545 + 258 + 1 = 260624 := by norm_num
-- The overcounting mistake, "3 matches, then any 3 of the other 46": 20 × 15,180 = 303,600 draws.
example : Nat.choose 6 3 * Nat.choose 46 3 = 303600 := by decide
-- Average matches 6 × 6/49 = 36/49; correction (49 - 6)/(49 - 1) = 43/48.
example : (6 : ℚ) * (6 / 49) = 36 / 49 := by norm_num
example : ((49 : ℚ) - 6) / (49 - 1) = 43 / 48 := by norm_num
-- Variance from the full table equals 6 × 6/49 × 43/49 × 43/48, the formula with the correction.
example :
    ((0 ^ 2 * 6096454 + 1 ^ 2 * 5775588 + 2 ^ 2 * 1851150 + 3 ^ 2 * 246820 + 4 ^ 2 * 13545
        + 5 ^ 2 * 258 + 6 ^ 2 * 1 : ℚ) / 13983816)
      - ((0 * 6096454 + 1 * 5775588 + 2 * 1851150 + 3 * 246820 + 4 * 13545 + 5 * 258 + 6 * 1 : ℚ)
        / 13983816) ^ 2
      = 6 * (6 / 49) * (1 - 6 / 49) * ((49 - 6) / (49 - 1)) := by norm_num
-- Mean from the full table is 36/49.
example : (0 * 6096454 + 1 * 5775588 + 2 * 1851150 + 3 * 246820 + 4 * 13545 + 5 * 258 + 6 * 1 : ℚ)
    / 13983816 = 36 / 49 := by norm_num
-- Two named draws both match with chance 6/49 × 5/48; covariance with p^2 is -p(1 - p)/(N - 1).
example : (6 : ℚ) / 49 * (5 / 48) - (6 / 49) ^ 2 = -((6 / 49) * (1 - 6 / 49) / (49 - 1)) := by
  norm_num
-- A smaller game, 6 from 39: jackpot 1 in C(39, 6) = 3,262,623.
example : Nat.choose 39 6 = 3262623 := by decide

#print axioms hypergeometric_chance_of_k_marked
#print axioms hypergeometric_mean
#print axioms hypergeometric_variance

end Hypergeometric
