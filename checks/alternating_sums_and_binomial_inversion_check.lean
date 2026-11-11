-- Alternating sums: every row of Pascal's triangle past row 0 adds to zero with alternating signs, a nonempty set has as many even-size as odd-size subsets, and so a binomial sum can be undone by the same row with signs.
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Algebra.Group.Int.Even
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Module.BigOperators

open Finset

theorem neg_one_pow_tsub_eq_mul (a b : ℕ) (h : b ≤ a) :
    (-1 : ℤ) ^ (a - b) = (-1) ^ a * (-1) ^ b := by
  obtain ⟨c, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [Nat.add_sub_cancel_left, pow_add, mul_comm ((-1 : ℤ) ^ b), mul_assoc, ← pow_add,
    ← two_mul, pow_mul]
  simp

#print axioms neg_one_pow_tsub_eq_mul

theorem choose_mul_alt_sum (n j : ℕ) (hj : j ≤ n) :
    ∑ k ∈ range (n + 1), (n.choose k : ℤ) * ((-1) ^ (k - j) * (k.choose j : ℤ)) =
      if j = n then 1 else 0 := by
  have hsplit : range (n + 1) = range j ∪ Ico j (n + 1) := by
    rw [range_eq_Ico, range_eq_Ico, Ico_union_Ico_eq_Ico (Nat.zero_le _) (by omega)]
  rw [hsplit, sum_union (by
      rw [range_eq_Ico]; exact Ico_disjoint_Ico_consecutive _ _ _)]
  have h0 : ∑ k ∈ range j, (n.choose k : ℤ) * ((-1) ^ (k - j) * (k.choose j : ℤ)) = 0 := by
    apply sum_eq_zero
    intro k hk
    rw [mem_range] at hk
    simp [Nat.choose_eq_zero_of_lt hk]
  rw [h0, zero_add, sum_Ico_eq_sum_range]
  have h1 : ∀ i ∈ range (n + 1 - j),
      (n.choose (j + i) : ℤ) * ((-1) ^ (j + i - j) * ((j + i).choose j : ℤ)) =
        (n.choose j : ℤ) * ((-1) ^ i * ((n - j).choose i : ℤ)) := by
    intro i _
    have := Nat.choose_mul (n := n) (k := j + i) (s := j) (Nat.le_add_right _ _)
    rw [Nat.add_sub_cancel_left] at this ⊢
    have hc : ((n.choose (j + i) : ℤ) * ((j + i).choose j : ℤ)) =
        (n.choose j : ℤ) * ((n - j).choose i : ℤ) := by exact_mod_cast this
    rw [mul_left_comm, hc, mul_left_comm]
  rw [sum_congr rfl h1, ← mul_sum, show n + 1 - j = (n - j) + 1 by omega,
    Int.alternating_sum_range_choose]
  by_cases h : j = n
  · subst h; simp
  · have : n - j ≠ 0 := by omega
    simp [h, this]

#print axioms choose_mul_alt_sum

theorem alt_choose_mul_sum (n j : ℕ) (hj : j ≤ n) :
    ∑ k ∈ range (n + 1), (-1 : ℤ) ^ (n - k) * (n.choose k : ℤ) * (k.choose j : ℤ) =
      if j = n then 1 else 0 := by
  have h : ∀ k ∈ range (n + 1), (-1 : ℤ) ^ (n - k) * (n.choose k : ℤ) * (k.choose j : ℤ) =
      (-1) ^ (n - j) * ((n.choose k : ℤ) * ((-1) ^ (k - j) * (k.choose j : ℤ))) := by
    intro k hk
    rw [mem_range] at hk
    by_cases hjk : j ≤ k
    · rw [neg_one_pow_tsub_eq_mul n k (by omega), neg_one_pow_tsub_eq_mul n j hj,
        neg_one_pow_tsub_eq_mul k j hjk]
      have hsq : (-1 : ℤ) ^ j * (-1) ^ j = 1 := by
        rw [← pow_add, ← two_mul, pow_mul]; simp
      generalize (-1 : ℤ) ^ j = s at hsq ⊢
      calc (-1 : ℤ) ^ n * (-1) ^ k * (n.choose k : ℤ) * (k.choose j : ℤ)
          = (-1) ^ n * (-1) ^ k * (n.choose k : ℤ) * (k.choose j : ℤ) * (s * s) := by
            rw [hsq, mul_one]
        _ = _ := by ring
    · simp [Nat.choose_eq_zero_of_lt (by omega : k < j)]
  rw [sum_congr rfl h, ← mul_sum, choose_mul_alt_sum n j hj]
  split_ifs with hjn
  · subst hjn; simp
  · simp

#print axioms alt_choose_mul_sum

theorem sum_choose_smul_extend {G : Type*} [AddCommGroup G] (n k : ℕ) (hk : k ≤ n)
    (c : ℕ → ℤ) (x : ℕ → G) :
    ∑ j ∈ range (k + 1), (c j * (k.choose j : ℤ)) • x j =
      ∑ j ∈ range (n + 1), (c j * (k.choose j : ℤ)) • x j := by
  apply sum_subset (range_subset_range.mpr (by omega))
  intro j _ hj
  rw [mem_range, not_lt] at hj
  simp [Nat.choose_eq_zero_of_lt (by omega : k < j)]

#print axioms sum_choose_smul_extend

theorem sum_smul_sum_swap {G : Type*} [AddCommGroup G] (n : ℕ) (c : ℕ → ℤ)
    (d : ℕ → ℕ → ℤ) (x : ℕ → G) :
    ∑ k ∈ range (n + 1), c k • ∑ j ∈ range (n + 1), d k j • x j =
      ∑ j ∈ range (n + 1), (∑ k ∈ range (n + 1), c k * d k j) • x j := by
  simp_rw [smul_sum, ← mul_smul, sum_smul]
  exact sum_comm

#print axioms sum_smul_sum_swap

/-- Alternating row sum. For every row n of Pascal's triangle past the top (n ≥ 1), adding the
row with alternating signs gives zero: C(n,0) − C(n,1) + C(n,2) − ⋯ ± C(n,n) = 0. -/
theorem alternating_row_sum_eq_zero (n : ℕ) (hn : 1 ≤ n) :
    ∑ k ∈ range (n + 1), (-1 : ℤ) ^ k * (n.choose k : ℤ) = 0 := by
  exact Int.alternating_sum_range_choose_of_ne (by omega)

/-- Binomial inversion. Take two sequences a₀, a₁, … and b₀, b₁, … of quantities that can be
added and subtracted (whole numbers, dollars, remainders on a clock: any additive group), both
indexed from 0. Each loose count is the exact counts weighted by a row,
b_n = ∑_{k=0}^{n} C(n,k) a_k for every n, exactly when each exact count is the loose counts
weighted by that row with alternating signs, last term positive:
a_n = ∑_{k=0}^{n} (−1)^(n−k) C(n,k) b_k for every n. -/
theorem binomial_inversion {G : Type*} [AddCommGroup G] (a b : ℕ → G) :
    (∀ n, b n = ∑ k ∈ range (n + 1), n.choose k • a k) ↔
      (∀ n, a n = ∑ k ∈ range (n + 1), ((-1 : ℤ) ^ (n - k) * (n.choose k : ℤ)) • b k) := by
  constructor
  · intro hb n
    have step : ∀ k ∈ range (n + 1), ((-1 : ℤ) ^ (n - k) * (n.choose k : ℤ)) • b k =
        ((-1 : ℤ) ^ (n - k) * (n.choose k : ℤ)) •
          ∑ j ∈ range (n + 1), ((1 : ℤ) * (k.choose j : ℤ)) • a j := by
      intro k hk
      rw [mem_range] at hk
      rw [hb k, ← sum_choose_smul_extend n k (by omega)]
      congr 1
      apply sum_congr rfl
      intro j _
      rw [one_mul, natCast_zsmul]
    rw [sum_congr rfl step, sum_smul_sum_swap]
    have coeff : ∀ j ∈ range (n + 1),
        (∑ k ∈ range (n + 1), (-1 : ℤ) ^ (n - k) * (n.choose k : ℤ) *
          (1 * (k.choose j : ℤ))) • a j = (if j = n then (1 : ℤ) else 0) • a j := by
      intro j hj
      rw [mem_range] at hj
      simp_rw [one_mul]
      rw [alt_choose_mul_sum n j (by omega)]
    rw [sum_congr rfl coeff]
    simp [ite_smul]
  · intro ha n
    have step : ∀ k ∈ range (n + 1), n.choose k • a k =
        (n.choose k : ℤ) •
          ∑ j ∈ range (n + 1), ((-1 : ℤ) ^ (k - j) * (k.choose j : ℤ)) • b j := by
      intro k hk
      rw [mem_range] at hk
      rw [← natCast_zsmul, ha k, sum_choose_smul_extend n k (by omega)]
    rw [sum_congr rfl step, sum_smul_sum_swap]
    have coeff : ∀ j ∈ range (n + 1),
        (∑ k ∈ range (n + 1), (n.choose k : ℤ) * ((-1 : ℤ) ^ (k - j) * (k.choose j : ℤ))) • b j
          = (if j = n then (1 : ℤ) else 0) • b j := by
      intro j hj
      rw [mem_range] at hj
      rw [choose_mul_alt_sum n j (by omega)]
    rw [sum_congr rfl coeff]
    simp [ite_smul]

/-- The pairing behind the zero. A finite set with at least one item in it has exactly as many
even-size subsets as odd-size subsets (toggling one chosen item matches them one for one). -/
theorem even_size_picks_eq_odd_size_picks {α : Type*} [DecidableEq α] (s : Finset α)
    (hs : s.Nonempty) :
    (s.powerset.filter (fun t => Even t.card)).card =
      (s.powerset.filter (fun t => Odd t.card)).card := by
  have h := sum_powerset_neg_one_pow_card_of_nonempty hs
  rw [← sum_filter_add_sum_filter_not _ (fun t => Even t.card)] at h
  have he : ∑ t ∈ s.powerset.filter (fun t => Even t.card), (-1 : ℤ) ^ t.card =
      ((s.powerset.filter (fun t => Even t.card)).card : ℤ) := by
    rw [Finset.card_eq_sum_ones, Nat.cast_sum]
    apply sum_congr rfl
    intro t ht
    rw [mem_filter] at ht
    simp [ht.2.neg_one_pow]
  have ho : ∑ t ∈ s.powerset.filter (fun t => ¬ Even t.card), (-1 : ℤ) ^ t.card =
      -((s.powerset.filter (fun t => Odd t.card)).card : ℤ) := by
    rw [Finset.card_eq_sum_ones, Nat.cast_sum, ← sum_neg_distrib]
    have : s.powerset.filter (fun t => ¬ Even t.card) =
        s.powerset.filter (fun t => Odd t.card) := by
      apply filter_congr
      intro t _
      exact Nat.not_even_iff_odd
    rw [this]
    apply sum_congr rfl
    intro t ht
    rw [mem_filter] at ht
    simp [ht.2.neg_one_pow]
  rw [he, ho] at h
  omega

-- Row 5 with signs: 1 − 5 + 10 − 10 + 5 − 1 = 0; without signs it is 32.
example : ∑ k ∈ range 6, (-1 : ℤ) ^ k * (Nat.choose 5 k : ℤ) = 0 := by decide
example : ∑ k ∈ range 6, Nat.choose 5 k = 32 := by decide
-- Row 10: 1,024 plain, 0 with signs.
example : ∑ k ∈ range 11, Nat.choose 10 k = 1024 := by decide
example : ∑ k ∈ range 11, (-1 : ℤ) ^ k * (Nat.choose 10 k : ℤ) = 0 := by decide
-- Row 0 is the exception: its alternating sum is 1.
example : ∑ k ∈ range 1, (-1 : ℤ) ^ k * (Nat.choose 0 k : ℤ) = 1 := by decide
-- The picks of the five tunes: 16 even-size, 16 odd-size, 32 in all.
example : ((range 5).powerset.filter (fun t => Even t.card)).card = 16 := by decide
example : ((range 5).powerset.filter (fun t => Odd t.card)).card = 16 := by decide
-- Setlists of exactly k tunes from five, C(5,k) × k!: 1, 5, 20, 60, 120, 120, adding to 326.
example : (List.range 6).map (fun k => Nat.choose 5 k * k.factorial) = [1, 5, 20, 60, 120, 120] :=
  by decide
example : ∑ k ∈ range 6, Nat.choose 5 k * k.factorial = 326 := by decide
-- The loose counts b(n) = ∑ C(n,k) k! for pools of 0 to 5 tunes: 1, 2, 5, 16, 65, 326.
example : (List.range 6).map (fun n => ∑ k ∈ range (n + 1), Nat.choose n k * k.factorial) =
    [1, 2, 5, 16, 65, 326] := by decide
-- The inverse at n = 5, term by term: −1 + 10 − 50 + 160 − 325 + 326 = 120.
example : (List.range 6).map (fun k => (-1 : ℤ) ^ (5 - k) * (Nat.choose 5 k : ℤ) *
    ([1, 2, 5, 16, 65, 326].getD k 0 : ℤ)) = [-1, 10, -50, 160, -325, 326] := by decide
example : (-1 : ℤ) + 10 - 50 + 160 - 325 + 326 = 120 := by decide
-- Inverting the loose counts gives back 1, 1, 2, 6, 24, 120, which is k! each time.
example : (List.range 6).map (fun n => ∑ k ∈ range (n + 1), (-1 : ℤ) ^ (n - k) *
    (Nat.choose n k : ℤ) * ([1, 2, 5, 16, 65, 326].getD k 0 : ℤ)) = [1, 1, 2, 6, 24, 120] := by
  decide
example : (List.range 6).map Nat.factorial = [1, 1, 2, 6, 24, 120] := by decide
-- The same count, straight: 5 × 4 × 3 × 2 × 1 = 120.
example : Nat.factorial 5 = 5 * 4 * 3 * 2 * 1 ∧ 5 * 4 * 3 * 2 * 1 = 120 := by decide
-- The three mistakes: no signs gives 872, row 5 one term short gives 1, dropping k = 0 gives 121.
example : ∑ k ∈ range 6, Nat.choose 5 k * [1, 2, 5, 16, 65, 326].getD k 0 = 872 := by decide
example : ∑ k ∈ range 5, (-1 : ℤ) ^ k * (Nat.choose 5 k : ℤ) = 1 := by decide
example : ∑ k ∈ Ico 1 6, (-1 : ℤ) ^ (5 - k) * (Nat.choose 5 k : ℤ) *
    ([1, 2, 5, 16, 65, 326].getD k 0 : ℤ) = 121 := by decide

#print axioms alternating_row_sum_eq_zero
#print axioms binomial_inversion
#print axioms even_size_picks_eq_odd_size_picks
