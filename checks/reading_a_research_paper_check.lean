-- Reading a paper: Zhang's Theorem 1 applied to one admissible tuple gives the abstract's bound on a gap that recurs forever, a tuple of primes above its own size is admissible, and the card's whole-number checks are exact.
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.NormNum.DivMod
import Mathlib.Tactic.IntervalCases

open Filter

/-- A tuple of offsets H is admissible when, for every prime p, the offsets occupy fewer than p
remainder classes mod p: ν_p(H) < p, so at least one class mod p holds no offset. -/
def Admissible (H : Finset ℕ) : Prop :=
  ∀ p : ℕ, p.Prime → (H.image (· % p)).card < p

/-- Zhang's Theorem 1 for a size k₀ (the card quotes it; it is the paper's result, not proved
here): every admissible tuple of at least k₀ offsets has infinitely many shifts n for which at
least two of n + h₁, …, n + h_k₀ are prime. -/
def ZhangTheoremOne (k₀ : ℕ) : Prop :=
  ∀ H : Finset ℕ, Admissible H → k₀ ≤ H.card →
    {n : ℕ | 2 ≤ (H.filter (fun h => (n + h).Prime)).card}.Infinite

/-- The bridge from Theorem 1 to the abstract: if Theorem 1 holds for k₀, and H is an admissible
tuple of at least k₀ offsets whose entries all lie within w of each other, then the gap
p_(n+1) − p_n between neighbouring primes is at most w for infinitely many n. (With k₀ =
3,500,000 and H the primes from 3,500,017 to 63,374,611, w = 59,874,594 < 70,000,000.) -/
theorem gap_le_width_infinitely_often_of_theorem_one {k₀ w : ℕ} (hT1 : ZhangTheoremOne k₀)
    {H : Finset ℕ} (hH : Admissible H) (hk : k₀ ≤ H.card)
    (hw : ∀ a ∈ H, ∀ b ∈ H, b - a ≤ w) :
    ∃ᶠ n in atTop, Nat.nth Nat.Prime (n + 1) - Nat.nth Nat.Prime n ≤ w := by
  have hinf : (Set.ofPred Nat.Prime).Infinite := Nat.infinite_setOfPred_prime
  rw [Filter.frequently_atTop]
  intro N
  obtain ⟨n, hnS, hnN⟩ := (hT1 H hH hk).exists_gt (Nat.nth Nat.Prime N)
  have hS : 1 < (H.filter (fun h => (n + h).Prime)).card := hnS
  obtain ⟨a, ha, b, hb, hab⟩ := Finset.one_lt_card.mp hS
  rw [Finset.mem_filter] at ha hb
  -- order the two offsets
  obtain ⟨h1, h2, hh1, hh2, hlt, hp1, hp2⟩ :
      ∃ h1 h2, h1 ∈ H ∧ h2 ∈ H ∧ h1 < h2 ∧ (n + h1).Prime ∧ (n + h2).Prime := by
    rcases lt_or_gt_of_ne hab with h | h
    · exact ⟨a, b, ha.1, hb.1, h, ha.2, hb.2⟩
    · exact ⟨b, a, hb.1, ha.1, h, hb.2, ha.2⟩
  set m := Nat.count Nat.Prime (n + h1) with hm
  have hq1 : Nat.nth Nat.Prime m = n + h1 := Nat.nth_count hp1
  have hmN : N ≤ m := by
    by_contra hcon
    push Not at hcon
    have := Nat.nth_strictMono hinf hcon
    omega
  have hcount : m + 1 ≤ Nat.count Nat.Prime (n + h2) := by
    have h1' : Nat.count Nat.Prime (n + h1 + 1) = m + 1 := by
      rw [Nat.count_succ, ite_eq_left_of_eq_true _ _ (eq_true hp1)]
    rw [← h1']
    exact Nat.count_monotone _ (by omega)
  have hq2 : Nat.nth Nat.Prime (m + 1) ≤ n + h2 := by
    calc Nat.nth Nat.Prime (m + 1) ≤ Nat.nth Nat.Prime (Nat.count Nat.Prime (n + h2)) :=
          Nat.nth_monotone hinf hcount
      _ = n + h2 := Nat.nth_count hp2
  refine ⟨m, hmN, ?_⟩
  have := hw h1 hh1 h2 hh2
  omega

/-- The admissibility shortcut: a tuple whose entries are all primes larger than the number of
entries is admissible. For p no larger than the size, class 0 mod p is empty; for p larger
than the size, there are more classes than entries. -/
theorem admissible_of_primes_above_card {H : Finset ℕ}
    (hH : ∀ h ∈ H, h.Prime ∧ H.card < h) : Admissible H := by
  intro p hp
  by_cases hpc : p ≤ H.card
  · have hsub : H.image (· % p) ⊆ (Finset.range p).erase 0 := by
      intro r hr
      rw [Finset.mem_image] at hr
      obtain ⟨h, hh, rfl⟩ := hr
      rw [Finset.mem_erase, Finset.mem_range]
      refine ⟨?_, Nat.mod_lt _ hp.pos⟩
      intro h0
      have hdvd : p ∣ h := Nat.dvd_of_mod_eq_zero h0
      obtain ⟨hhp, hhc⟩ := hH h hh
      rcases (Nat.prime_dvd_prime_iff_eq hp hhp).mp hdvd with rfl
      omega
    calc (H.image (· % p)).card ≤ ((Finset.range p).erase 0).card := Finset.card_le_card hsub
      _ = p - 1 := by rw [Finset.card_erase_of_mem (by simp [hp.pos]), Finset.card_range]
      _ < p := by have := hp.two_le; omega
  · push Not at hpc
    exact lt_of_le_of_lt Finset.card_image_le hpc

/-- Gaps between primes are unbounded, so lim inf is not a bound on every gap: for every
j from 2 to n, the number n! + j is composite (n! + j is divisible by j and larger than j). -/
theorem factorial_add_not_prime {n j : ℕ} (h2 : 2 ≤ j) (hj : j ≤ n) :
    ¬ (Nat.factorial n + j).Prime := by
  intro hprime
  have hj0 : 0 < j := by omega
  have hdvd : j ∣ Nat.factorial n + j :=
    (Nat.dvd_add_right (Nat.dvd_factorial hj0 hj)).mpr dvd_rfl
  have hpos : 0 < Nat.factorial n := Nat.factorial_pos n
  rcases hprime.eq_one_or_self_of_dvd j hdvd with h | h <;> omega

-- The paper's inequality, from the card's prime counts: 4,118,064 − 250,150 = 3,867,914 > 3,500,000.
example : 4118064 - 250150 = 3867914 ∧ 3500000 < 3867914 := by norm_num
-- The tuple runs from 3,500,017 to 63,374,611: width 59,874,594, slack 10,125,406 under 70,000,000.
example : 63374611 - 3500017 = 59874594 ∧ 70000000 - 59874594 = 10125406 ∧
    59874594 < 70000000 := by norm_num
-- Its first entry is the first prime above k₀ = 3,500,000.
example : Nat.Prime 3500017 ∧ 3500000 < 3500017 := by norm_num
-- The first 10 primes are not admissible: they fill both classes mod 2.
example : (({2, 3, 5, 7, 11, 13, 17, 19, 23, 29} : Finset ℕ).image (· % 2)).card = 2 := by
  decide
-- The 10 primes above 10, from 11 to 43, leave class 0 empty mod 2, 3, 5 and 7.
example : ∀ p ∈ ({2, 3, 5, 7} : Finset ℕ),
    ∀ h ∈ ({11, 13, 17, 19, 23, 29, 31, 37, 41, 43} : Finset ℕ), h % p ≠ 0 := by decide
-- (0, 2, 4) meets all 3 classes mod 3, so it is not admissible.
example : (({0, 2, 4} : Finset ℕ).image (· % 3)).card = 3 := by decide
example : ¬ Admissible {0, 2, 4} := by
  intro h; have := h 3 Nat.prime_three; revert this; decide
-- 10! = 3,628,800, and 10! + 2 to 10! + 10 are all composite.
example : Nat.factorial 10 = 3628800 := by decide
example : ∀ j ∈ Finset.Icc 2 10, ¬ (3628800 + j).Prime := by
  intro j hj; rw [Finset.mem_Icc] at hj; obtain ⟨h1, h2⟩ := hj
  interval_cases j <;> norm_num
-- Theorem 2's level: ϖ = 1/1168, 1/2 + 2ϖ = 293/584, cut-off exponent 1/4 + ϖ = 293/1168, excess 2ϖ = 1/584.
example : (1 / 2 + 2 * (1 / 1168) : ℚ) = 293 / 584 ∧ (1 / 4 + 1 / 1168 : ℚ) = 293 / 1168 ∧
    (2 * (1 / 1168) : ℚ) = 1 / 584 := by norm_num
-- Polymath 2014's exponent, quoted: 1/2 + 7/300 = 157/300.
example : (1 / 2 + 7 / 300 : ℚ) = 157 / 300 := by norm_num

#print axioms gap_le_width_infinitely_often_of_theorem_one
#print axioms admissible_of_primes_above_card
#print axioms factorial_add_not_prime
