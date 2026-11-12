-- When cycles meet again: two cycles of lengths a and b, both read off one count n, first come home together after a × b ÷ gcd(a, b) steps, a pair of positions ever happens exactly when the two positions leave the same remainder on division by gcd(a, b), and so exactly a × b ÷ gcd(a, b) of the a × b pairs ever happen.
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Set.Card
import Mathlib.Data.Finset.Image
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum

/-- Two cycles, one a steps long and one b steps long, are both read off one count n: the first
list stands at n % a, the second at n % b, and both start at 0 when n = 0. They are back at the
start together for the first time after their lengths multiplied, then divided by the biggest
number that goes into both: a × b ÷ gcd(a, b) steps. -/
theorem cycles_first_meet_again_at_product_div_gcd (a b : ℕ) (ha : 0 < a) (hb : 0 < b) :
    IsLeast {n : ℕ | 0 < n ∧ n % a = 0 ∧ n % b = 0} (a * b / Nat.gcd a b) := by
  have hl : a * b / Nat.gcd a b = Nat.lcm a b := rfl
  rw [hl]
  refine ⟨⟨Nat.lcm_pos ha hb, ?_, ?_⟩, ?_⟩
  · exact Nat.mod_eq_zero_of_dvd (Nat.dvd_lcm_left a b)
  · exact Nat.mod_eq_zero_of_dvd (Nat.dvd_lcm_right a b)
  · rintro n ⟨hn, h1, h2⟩
    exact Nat.le_of_dvd hn (Nat.lcm_dvd (Nat.dvd_of_mod_eq_zero h1) (Nat.dvd_of_mod_eq_zero h2))

/-- The shared factor rules pairs out. Position s on the a-list together with position t on the
b-list is ever read off one count exactly when s and t leave the same remainder on division by
gcd(a, b). Lengths that share nothing (gcd 1) rule nothing out: every pair happens. -/
theorem remainder_pair_happens_iff_agree_mod_gcd (a b s t : ℕ) (ha : 0 < a) (hb : 0 < b)
    (hs : s < a) (ht : t < b) :
    (∃ n : ℕ, n % a = s ∧ n % b = t) ↔ s ≡ t [MOD Nat.gcd a b] := by
  constructor
  · rintro ⟨n, h1, h2⟩
    have e1 : n ≡ s [MOD a] := by rw [Nat.ModEq, h1, Nat.mod_eq_of_lt hs]
    have e2 : n ≡ t [MOD b] := by rw [Nat.ModEq, h2, Nat.mod_eq_of_lt ht]
    exact (e1.of_dvd (Nat.gcd_dvd_left a b)).symm.trans (e2.of_dvd (Nat.gcd_dvd_right a b))
  · intro h
    obtain ⟨k, hk1, hk2⟩ := Nat.chineseRemainder' h
    refine ⟨k, ?_, ?_⟩
    · rw [hk1, Nat.mod_eq_of_lt hs]
    · rw [hk2, Nat.mod_eq_of_lt ht]

/-- Of the a × b pairs of positions on paper, the number that are ever read off one count is
a × b ÷ gcd(a, b). -/
theorem pairs_that_happen_count (a b : ℕ) (ha : 0 < a) (hb : 0 < b) :
    {p : ℕ × ℕ | ∃ n : ℕ, (n % a, n % b) = p}.ncard = a * b / Nat.gcd a b := by
  have hl : a * b / Nat.gcd a b = Nat.lcm a b := rfl
  rw [hl]
  have hlpos : 0 < Nat.lcm a b := Nat.lcm_pos ha hb
  have hset : {p : ℕ × ℕ | ∃ n : ℕ, (n % a, n % b) = p}
      = (fun n : ℕ => (n % a, n % b)) '' (Set.Iio (Nat.lcm a b)) := by
    ext p
    constructor
    · rintro ⟨n, rfl⟩
      refine ⟨n % Nat.lcm a b, Nat.mod_lt _ hlpos, ?_⟩
      have h1 : n % Nat.lcm a b % a = n % a := Nat.mod_mod_of_dvd _ (Nat.dvd_lcm_left a b)
      have h2 : n % Nat.lcm a b % b = n % b := Nat.mod_mod_of_dvd _ (Nat.dvd_lcm_right a b)
      simp only [h1, h2]
    · rintro ⟨n, _, rfl⟩
      exact ⟨n, rfl⟩
  rw [hset, Set.InjOn.ncard_image]
  · rw [← Set.Iio_def, Set.ncard_eq_toFinset_card']
    simp
  · intro m hm n hn h
    simp only [Set.mem_Iio] at hm hn
    simp only [Prod.mk.injEq] at h
    have : m ≡ n [MOD Nat.lcm a b] := Nat.modEq_and_modEq_iff_modEq_lcm.mp h
    unfold Nat.ModEq at this
    rwa [Nat.mod_eq_of_lt hm, Nat.mod_eq_of_lt hn] at this

-- 2026 is 42 years after the Wood Rat of 1984: stem 2, branch 6, the Fire Horse.
example : 2026 - 1984 = 42 ∧ 42 % 10 = 2 ∧ 42 % 12 = 6 := by decide
-- The stems and branches share 2, and come home together after 10 × 12 ÷ 2 = 60 years.
example : Nat.gcd 10 12 = 2 ∧ 10 * 12 = 120 ∧ 10 * 12 / Nat.gcd 10 12 = 60 ∧ Nat.lcm 10 12 = 60 := by
  norm_num [Nat.lcm]
-- Only 60 of the 120 pairs on paper ever happen; stem 3 with branch 4 never does.
example : ((Finset.range 120).image (fun n => (n % 10, n % 12))).card = 60 := by decide +kernel
example : ∀ n < 120, ¬ (n % 10 = 3 ∧ n % 12 = 4) := by decide +kernel
-- The Maya counts share 5 and realign after 260 × 365 ÷ 5 = 18980 days: 52 years of 365 days, 73 rounds of 260.
example : Nat.gcd 260 365 = 5 ∧ 260 * 365 = 94900 ∧ 94900 / 5 = 18980 ∧ Nat.lcm 260 365 = 18980 := by
  norm_num [Nat.lcm]
example : 18980 / 365 = 52 ∧ 52 * 365 = 18980 ∧ 73 * 260 = 18980 := by decide
-- The mistakes: 120 years, 94900 days (five times the round), and 94900 ÷ 365 = 260 years.
example : 94900 = 5 * 18980 ∧ 94900 / 365 = 260 := by decide

#print axioms cycles_first_meet_again_at_product_div_gcd
#print axioms remainder_pair_happens_iff_agree_mod_gcd
#print axioms pairs_that_happen_count
