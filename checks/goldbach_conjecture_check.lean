-- Goldbach: the conjecture is stated exactly and left open; the file proves that an even check to B and a ladder of primes with steps shorter than B make every odd number from 7 to the top rung plus B a sum of three primes, that r(n) ≥ 1 says exactly that n is a sum of two primes, that an odd number is a sum of two primes exactly when it is 2 more than a prime, and the card's whole-number examples.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Finset.Prod
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum.Prime

/-- Goldbach's conjecture, strong (binary) form (open as of 2026-11-23; the card does not
prove it): every even number n from 4 up is p + q with p and q prime. -/
def GoldbachConjecture : Prop :=
  ∀ n : ℕ, Even n → 4 ≤ n → ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = n

/-- The Goldbach count r(n): the number of pairs (p, q) of primes with p ≤ q and p + q = n. -/
def goldbachCount (n : ℕ) : ℕ :=
  ((Finset.range (n + 1) ×ˢ Finset.range (n + 1)).filter
    (fun x : ℕ × ℕ => x.1 ≤ x.2 ∧ x.1 + x.2 = n ∧ x.1.Prime ∧ x.2.Prime)).card

/-- Every rung of a strictly rising ladder starting at 3 is at least 3. -/
theorem goldbach_rung_ge_three (k : ℕ) (rung : ℕ → ℕ) (hstart : rung 0 = 3)
    (hinc : ∀ i < k, rung i < rung (i + 1)) : ∀ i ≤ k, 3 ≤ rung i := by
  intro i
  induction i with
  | zero => intro _; omega
  | succ j ih =>
    intro hj
    have h1 := ih (by omega)
    have h2 := hinc j (by omega)
    omega

#print axioms goldbach_rung_ge_three

/-- The ladder: suppose every even n with 4 ≤ n ≤ B is a sum of two primes (the even check
to an even bound B), and the rungs 3 = q₀ < q₁ < ... < q_k are primes with each step from one
rung to the next shorter than B. Then every odd N from 7 up to the top rung plus B is a sum of
three primes: take the highest rung q ≤ N − 4, and N − q is even, at least 4 and at most B. -/
theorem even_check_and_prime_ladder_give_three_primes (B k : ℕ) (rung : ℕ → ℕ)
    (hB : Even B)
    (hcheck : ∀ n : ℕ, Even n → 4 ≤ n → n ≤ B → ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = n)
    (hstart : rung 0 = 3)
    (hprime : ∀ i ≤ k, (rung i).Prime)
    (hstep : ∀ i < k, rung i < rung (i + 1) ∧ rung (i + 1) - rung i < B) :
    ∀ N : ℕ, Odd N → 7 ≤ N → N ≤ rung k + B →
      ∃ p q s : ℕ, p.Prime ∧ q.Prime ∧ s.Prime ∧ p + q + s = N := by
  intro N hN h7 hNk
  have hge := goldbach_rung_ge_three k rung hstart (fun i hi => (hstep i hi).1)
  have hodd : ∀ i ≤ k, Odd (rung i) := by
    intro i hi
    exact (hprime i hi).odd_of_ne_two (by have := hge i hi; omega)
  set P : ℕ → Prop := fun i => rung i + 4 ≤ N with hPdef
  set i := Nat.findGreatest P k with hidef
  have hP0 : P 0 := by simp only [hPdef]; omega
  have hPi : P i := Nat.findGreatest_spec (P := P) (Nat.zero_le k) hP0
  have hik : i ≤ k := Nat.findGreatest_le k
  simp only [hPdef] at hPi
  obtain ⟨a, ha⟩ := hN
  obtain ⟨b, hb⟩ := hodd i hik
  obtain ⟨d, hd⟩ := hB
  have hle : N - rung i ≤ B := by
    rcases Nat.lt_or_ge i k with hlt | hge'
    · have hnot : ¬ P (i + 1) := Nat.findGreatest_is_greatest (Nat.lt_succ_self i) hlt
      simp only [hPdef] at hnot
      obtain ⟨c, hc⟩ := hodd (i + 1) hlt
      have hs := (hstep i hlt).2
      omega
    · have : i = k := le_antisymm hik hge'
      rw [this]; omega
  obtain ⟨p, q, hp, hq, hpq⟩ := hcheck (N - rung i) ⟨a - b, by omega⟩ (by omega) hle
  exact ⟨p, q, rung i, hp, hq, hprime i hik, by omega⟩

/-- One pair is enough: r(n) ≥ 1 exactly when n is p + q for some primes p and q. -/
theorem one_le_goldbachCount_iff (n : ℕ) :
    1 ≤ goldbachCount n ↔ ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = n := by
  constructor
  · intro h
    have hpos : 0 < goldbachCount n := by omega
    unfold goldbachCount at hpos
    obtain ⟨x, hx⟩ := Finset.card_pos.mp hpos
    rw [Finset.mem_filter] at hx
    exact ⟨x.1, x.2, hx.2.2.2.1, hx.2.2.2.2, hx.2.2.1⟩
  · rintro ⟨p, q, hp, hq, hpq⟩
    unfold goldbachCount
    apply Finset.card_pos.mpr
    refine ⟨(min p q, max p q), ?_⟩
    rw [Finset.mem_filter, Finset.mem_product, Finset.mem_range, Finset.mem_range]
    refine ⟨⟨by omega, by omega⟩, by omega, by omega, ?_, ?_⟩
    · rcases le_total p q with h | h
      · rw [min_eq_left h]; exact hp
      · rw [min_eq_right h]; exact hq
    · rcases le_total p q with h | h
      · rw [max_eq_right h]; exact hq
      · rw [max_eq_left h]; exact hp

/-- Why n must be even: an odd n is a sum of two primes exactly when n − 2 is prime,
since one of the two primes must be 2. So 999,999 has no pair, as 999,997 is composite. -/
theorem odd_sum_of_two_primes_iff (n : ℕ) (hn : Odd n) :
    (∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = n) ↔ (n - 2).Prime := by
  constructor
  · rintro ⟨p, q, hp, hq, hpq⟩
    rcases hp.eq_two_or_odd' with h2 | hpo
    · subst h2
      have : n - 2 = q := by omega
      rw [this]; exact hq
    · rcases hq.eq_two_or_odd' with h2 | hqo
      · subst h2
        have : n - 2 = p := by omega
        rw [this]; exact hp
      · exfalso
        obtain ⟨a, ha⟩ := hpo
        obtain ⟨b, hb⟩ := hqo
        obtain ⟨c, hc⟩ := hn
        omega
  · intro h
    have h2 := h.two_le
    exact ⟨2, n - 2, Nat.prime_two, h, by omega⟩

/-! The card's whole-number examples. -/

-- One million: the smallest pair is 17 + 999,983.
example : (17 : ℕ).Prime ∧ (999983 : ℕ).Prime ∧ 17 + 999983 = 1000000 := by norm_num
-- The failures before p = 17: 1,000,000 − p is composite for p = 3, 5, 7, 11, 13.
example : 999997 = 757 * 1321 ∧ 999995 = 5 * 199999 ∧ 999993 = 3 * 333331 ∧
    999989 = 19 * 52631 ∧ 999987 = 3 * 333329 := by norm_num
example : ¬ (999997 : ℕ).Prime ∧ ¬ (999995 : ℕ).Prime ∧ ¬ (999993 : ℕ).Prime ∧
    ¬ (999989 : ℕ).Prime ∧ ¬ (999987 : ℕ).Prime := by norm_num
-- Counted as ordered pairs, the 5,402 pairs of one million become 10,804.
example : 2 * 5402 = 10804 := by norm_num
-- 999,999 has no pair: 999,999 − 2 = 999,997 = 757 × 1,321.
example : 999999 - 2 = 999997 ∧ 999997 = 757 * 1321 := by norm_num
-- The records at 503,222 (with 523) and 1,077,422 (with 601) leave a prime.
example : (523 : ℕ).Prime ∧ (503222 - 523 : ℕ).Prime := by norm_num
example : (601 : ℕ).Prime ∧ (1077422 - 601 : ℕ).Prime := by norm_num
-- Base 2 alone calls 2,047 prime: 2^1023 leaves remainder 1 mod 2,047, yet 2,047 = 23 × 89.
set_option exponentiation.threshold 1024 in
example : 2 ^ 1023 % 2047 = 1 ∧ 2047 = 23 * 89 ∧ ¬ (2047 : ℕ).Prime := by norm_num
-- The bounds of "When it holds": 2 + 2 = 4, 2 + 2 + 2 = 6, and 7 = 2 + 2 + 3.
example : 2 + 2 = 4 ∧ 2 + 2 + 2 = 6 ∧ 2 + 2 + 3 = 7 ∧ (3 : ℕ).Prime := by norm_num
-- The ladder's worked case: 9,999,999,999 = 9,999,881,909 + 29 + 118,061, all three prime.
set_option maxRecDepth 100000 in
example : (9999881909 : ℕ).Prime ∧ (29 : ℕ).Prime ∧ (118061 : ℕ).Prime ∧
    9999881909 + 29 + 118061 = 9999999999 := by norm_num
-- The ladder's top rung 10,001,881,889 plus B = 2,000,000 gives the end of its range.
set_option maxRecDepth 100000 in
example : (10001881889 : ℕ).Prime ∧ 10001881889 + 2000000 = 10003881889 := by norm_num

#print axioms even_check_and_prime_ladder_give_three_primes
#print axioms one_le_goldbachCount_iff
#print axioms odd_sum_of_two_primes_iff
