-- Random numbers from a computer: a linear congruential generator x ↦ (a x + c) mod 2^k (with 2^k at least 4) runs through all 2^k states before repeating exactly when c is odd and a leaves remainder 1 on division by 4; with no increment, n steps multiply the seed by a^n; and RANDU's every output is fixed by the two before it.
import Mathlib.Data.ZMod.Basic
import Mathlib.Dynamics.PeriodicPts.Defs
import Mathlib.Data.Int.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Ring.GeomSum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Positivity

open Finset in
lemma prn_sum_double (a n : ℕ) :
    ∑ i ∈ range (2 * n), a ^ i = (∑ i ∈ range n, a ^ i) * (1 + a ^ n) := by
  rw [two_mul, Finset.sum_range_add]
  simp only [pow_add, ← Finset.mul_sum]
  ring

open Finset in
lemma prn_sum_one_mod_four (a : ℕ) (ha : a % 4 = 1) (m : ℕ) :
    ∃ t, ∑ i ∈ range (2 ^ m), a ^ i = 2 ^ m * (2 * t + 1) := by
  induction m with
  | zero => exact ⟨0, by simp⟩
  | succ m ih =>
    obtain ⟨t, ht⟩ := ih
    have h4 : a ^ (2 ^ m) % 4 = 1 := by rw [Nat.pow_mod, ha]; simp
    obtain ⟨q, hq⟩ : ∃ q, a ^ (2 ^ m) = 4 * q + 1 := ⟨a ^ (2 ^ m) / 4, by omega⟩
    refine ⟨2 * t * q + t + q, ?_⟩
    rw [pow_succ, mul_comm (2 ^ m) 2, prn_sum_double, ht, hq]
    ring

open Finset in
lemma prn_sum_odd (a : ℕ) (ha : a % 2 = 1) (m : ℕ) :
    2 ^ m ∣ ∑ i ∈ range (2 ^ m), a ^ i := by
  induction m with
  | zero => simp
  | succ m ih =>
    have h2 : 2 ∣ 1 + a ^ (2 ^ m) := by
      have : a ^ (2 ^ m) % 2 = 1 := by rw [Nat.pow_mod, ha]; simp
      omega
    rw [show 2 ^ (m + 1) = 2 * 2 ^ m by ring, prn_sum_double, Nat.mul_comm 2 (2 ^ m)]
    exact mul_dvd_mul ih h2

open Finset in
lemma prn_sum_three_mod_four (a : ℕ) (ha : a % 4 = 3) (m : ℕ) :
    2 ^ (m + 2) ∣ ∑ i ∈ range (2 ^ (m + 1)), a ^ i := by
  induction m with
  | zero =>
    norm_num [Finset.sum_range_succ]
    omega
  | succ m ih =>
    have h2 : 2 ∣ 1 + a ^ (2 ^ (m + 1)) := by
      have ha2 : a % 2 = 1 := by omega
      have : a ^ (2 ^ (m + 1)) % 2 = 1 := by rw [Nat.pow_mod, ha2]; simp
      omega
    rw [show 2 ^ (m + 1 + 1) = 2 * 2 ^ (m + 1) by ring, prn_sum_double,
      show 2 ^ (m + 1 + 2) = 2 ^ (m + 2) * 2 by ring]
    exact mul_dvd_mul ih h2

open Finset in
lemma prn_iter (N a c : ℕ) (f : ZMod N → ZMod N) (hf : ∀ y, f y = (a : ZMod N) * y + c)
    (n : ℕ) (x : ZMod N) :
    f^[n] x = (a : ZMod N) ^ n * x + c * ∑ i ∈ range n, (a : ZMod N) ^ i := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih, hf, geom_sum_succ]
    ring

open Finset in
lemma prn_iter_sub (N a c : ℕ) (f : ZMod N → ZMod N) (hf : ∀ y, f y = (a : ZMod N) * y + c)
    (n : ℕ) (x : ZMod N) :
    f^[n] x - x = (∑ i ∈ range n, (a : ZMod N) ^ i) * (((a : ZMod N) - 1) * x + c) := by
  rw [prn_iter N a c f hf]
  have := geom_sum_mul (a : ZMod N) n
  linear_combination (-x) * this

lemma prn_two_pow_ne_zero (j : ℕ) : (2 : ZMod (2 ^ (j + 2))) ^ (j + 1) ≠ 0 := by
  intro h
  have h' : ((2 ^ (j + 1) : ℕ) : ZMod (2 ^ (j + 2))) = 0 := by exact_mod_cast h
  rw [ZMod.natCast_eq_zero_iff] at h'
  have h1 := Nat.le_of_dvd (by positivity) h'
  have h2 : 2 ^ (j + 1) < 2 ^ (j + 2) := Nat.pow_lt_pow_right (by norm_num) (by omega)
  omega

lemma prn_two_pow_eq_zero (j : ℕ) : (2 : ZMod (2 ^ (j + 2))) ^ (j + 2) = 0 := by
  exact_mod_cast ZMod.natCast_self (2 ^ (j + 2))

#print axioms prn_sum_double
#print axioms prn_sum_one_mod_four
#print axioms prn_sum_odd
#print axioms prn_sum_three_mod_four
#print axioms prn_iter
#print axioms prn_iter_sub
#print axioms prn_two_pow_ne_zero
#print axioms prn_two_pow_eq_zero

/-- The full-cycle rule (Hull and Dobell, 1962), for m a power of 2 and at least 4. The linear
congruential generator x ↦ (a × x + c) mod m visits all m states before repeating, from every
seed, exactly when the increment c is odd and the multiplier a leaves remainder 1 on division
by 4. Here the states are the m remainders, and the loop length of a seed is the first number of
steps that brings it back. -/
theorem lcg_full_cycle_iff_c_odd_and_a_one_mod_four (k : ℕ) (hk : 2 ≤ k) (a c : ℕ) :
    (∀ x : ZMod (2 ^ k),
        Function.minimalPeriod (fun y : ZMod (2 ^ k) => (a : ZMod (2 ^ k)) * y + c) x = 2 ^ k) ↔
      (Odd c ∧ a % 4 = 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 2 := ⟨k - 2, by omega⟩
  set f := fun y : ZMod (2 ^ (j + 2)) => (a : ZMod (2 ^ (j + 2))) * y + c with hfdef
  have hf : ∀ y, f y = (a : ZMod (2 ^ (j + 2))) * y + c := fun y => rfl
  have hlt : 2 ^ (j + 1) < 2 ^ (j + 2) := Nat.pow_lt_pow_right (by norm_num) (by omega)
  constructor
  · intro h
    have hfix : ∀ x, f^[2 ^ (j + 2)] x = x := fun x => by
      have := Function.iterate_minimalPeriod (f := f) (x := x)
      rwa [h x] at this
    have hhalf : ¬ (f^[2 ^ (j + 1)] (0 : ZMod (2 ^ (j + 2))) = 0) := by
      intro h0
      have hd := (show Function.IsPeriodicPt f (2 ^ (j + 1)) 0 from h0).minimalPeriod_dvd
      rw [h 0] at hd
      have := Nat.le_of_dvd (by positivity) hd
      omega
    have ha : a % 2 = 1 := by
      by_contra hae
      have hinj : Function.Injective f := by
        have hid : f^[2 ^ (j + 2)] = id := funext hfix
        have h2 : f^[2 ^ (j + 2)] = f^[2 ^ (j + 2) - 1] ∘ f := by
          rw [← Function.iterate_succ]
          congr 1
          have := Nat.one_le_two_pow (n := j + 2)
          omega
        apply Function.Injective.of_comp (f := f^[2 ^ (j + 2) - 1])
        rw [← h2, hid]
        exact Function.injective_id
      have hfe : f 0 = f ((2 : ZMod (2 ^ (j + 2))) ^ (j + 1)) := by
        obtain ⟨b, rfl⟩ : ∃ b, a = 2 * b := ⟨a / 2, by omega⟩
        rw [hf, hf]
        push_cast
        linear_combination (-(b : ZMod (2 ^ (j + 2)))) * prn_two_pow_eq_zero j
      exact prn_two_pow_ne_zero j (hinj hfe).symm
    have hit : f^[2 ^ (j + 1)] 0 =
        ((c * ∑ i ∈ Finset.range (2 ^ (j + 1)), a ^ i : ℕ) : ZMod (2 ^ (j + 2))) := by
      rw [prn_iter _ a c f hf]
      push_cast
      ring
    have hc : c % 2 = 1 := by
      by_contra hce
      apply hhalf
      rw [hit, ZMod.natCast_eq_zero_iff]
      have hd := prn_sum_odd a ha (j + 1)
      obtain ⟨d, rfl⟩ : ∃ d, c = 2 * d := ⟨c / 2, by omega⟩
      have h2 : 2 ^ (j + 2) ∣ 2 * ∑ i ∈ Finset.range (2 ^ (j + 1)), a ^ i := by
        rw [show 2 ^ (j + 2) = 2 * 2 ^ (j + 1) by ring]
        exact mul_dvd_mul_left 2 hd
      exact h2.trans (Dvd.intro d (by ring))
    refine ⟨Nat.odd_iff.mpr hc, ?_⟩
    by_contra h4
    have h43 : a % 4 = 3 := by omega
    apply hhalf
    rw [hit, ZMod.natCast_eq_zero_iff]
    exact Dvd.dvd.mul_left (prn_sum_three_mod_four a h43 j) c
  · rintro ⟨hc, ha⟩ x
    have hS2 := prn_sum_odd a (by omega) (j + 2)
    have hper : Function.IsPeriodicPt f (2 ^ (j + 2)) x := by
      show f^[_] x = x
      rw [← sub_eq_zero, prn_iter_sub _ a c f hf]
      have h0 : (∑ i ∈ Finset.range (2 ^ (j + 2)), (a : ZMod (2 ^ (j + 2))) ^ i) = 0 := by
        have := (ZMod.natCast_eq_zero_iff _ _).mpr hS2
        push_cast at this
        exact this
      rw [h0, zero_mul]
    have hdvd := hper.minimalPeriod_dvd
    rw [Nat.dvd_prime_pow Nat.prime_two] at hdvd
    obtain ⟨i, hi, hieq⟩ := hdvd
    rw [hieq]
    by_contra hne
    have hi' : i ≤ j + 1 := by
      rcases lt_or_eq_of_le hi with h | h
      · omega
      · exact absurd (by rw [h]) hne
    have hp : Function.IsPeriodicPt f (2 ^ (j + 1)) x := by
      have : Function.minimalPeriod f x ∣ 2 ^ (j + 1) := by
        rw [hieq]; exact Nat.pow_dvd_pow 2 hi'
      exact (Function.isPeriodicPt_minimalPeriod f x).trans_dvd this
    have h1 : f^[2 ^ (j + 1)] x - x = 0 := sub_eq_zero.mpr hp
    rw [prn_iter_sub _ a c f hf] at h1
    obtain ⟨t, ht⟩ := prn_sum_one_mod_four a ha (j + 1)
    have hS : (∑ i ∈ Finset.range (2 ^ (j + 1)), (a : ZMod (2 ^ (j + 2))) ^ i) =
        2 ^ (j + 1) * (2 * t + 1) := by
      have := congrArg (Nat.cast : ℕ → ZMod (2 ^ (j + 2))) ht
      push_cast at this
      exact this
    rw [hS] at h1
    obtain ⟨r, hr⟩ : ∃ r, a = 4 * r + 1 := ⟨a / 4, by omega⟩
    obtain ⟨s, hs⟩ := hc
    rw [hr, hs] at h1
    push_cast at h1
    apply prn_two_pow_ne_zero j
    linear_combination h1 - ((t : ZMod (2 ^ (j + 2))) + (2 * t + 1) * (2 * r * x + s)) *
      prn_two_pow_eq_zero j

/-- Jumping ahead. With no increment (c = 0), n steps of x ↦ (a × x) mod m multiply the seed by
a exactly n times: from any seed x₀ (a state, so below m), the state after n steps is
aⁿ × x₀ mod m. -/
theorem lcg_no_increment_jump_ahead (m a x₀ n : ℕ) (hx : x₀ < m) :
    (fun x : ℕ => a * x % m)^[n] x₀ = a ^ n * x₀ % m := by
  induction n with
  | zero => simp [Nat.mod_eq_of_lt hx]
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih, Nat.mul_mod, Nat.mod_mod, ← Nat.mul_mod, pow_succ]
    ring_nf

/-- RANDU's flaw. For RANDU, x ↦ 65539 × x mod 2³¹, take any output x and the next two, y and z.
Then 9 × x − 6 × y + z is always a multiple of 2³¹: every output is fixed by the two before it. -/
theorem randu_three_outputs_satisfy_nine_minus_six_plus_one (x : ℕ) :
    let y : ℕ := 65539 * x % 2 ^ 31
    let z : ℕ := 65539 * y % 2 ^ 31
    (2 ^ 31 : ℤ) ∣ 9 * (x : ℤ) - 6 * (y : ℤ) + (z : ℤ) := by
  intro y z
  have hy : (y : ℤ) = 65539 * x - 2 ^ 31 * ((65539 * x : ℕ) / 2 ^ 31 : ℕ) := by
    have := Nat.mod_add_div (65539 * x) (2 ^ 31)
    simp only [y]
    omega
  have hz : (z : ℤ) = 65539 * y - 2 ^ 31 * ((65539 * y : ℕ) / 2 ^ 31 : ℕ) := by
    have := Nat.mod_add_div (65539 * y) (2 ^ 31)
    simp only [z]
    omega
  rw [hz, hy]
  exact ⟨2 * x - 65533 * ((65539 * x : ℕ) / 2 ^ 31 : ℕ) - ((65539 * y : ℕ) / 2 ^ 31 : ℕ),
    by push_cast; ring⟩

-- One step of the toy generator: 5 × 7 + 3 = 38, and 38 mod 16 is 6.
example : 5 * 7 + 3 = 38 ∧ 38 % 16 = 6 ∧ 38 = 2 * 16 + 6 := by decide
-- The toy generator (5x + 3) mod 16 from seed 7: its 16 outputs, ending back at 7.
example : (List.range 16).map (fun n => (fun x : ℕ => (5 * x + 3) % 16)^[n + 1] 7) =
    [6, 1, 8, 11, 10, 5, 12, 15, 14, 9, 0, 3, 2, 13, 4, 7] := by decide
-- Its loop length is 16: 7 first comes back after 16 steps.
example : (fun x : ℕ => (5 * x + 3) % 16)^[16] 7 = 7 ∧
    ∀ n ∈ Finset.Ico 1 16, (fun x : ℕ => (5 * x + 3) % 16)^[n] 7 ≠ 7 := by decide
-- The rule for the toy generator: a = 5 leaves 1 on division by 4, and c = 3 is odd.
example : 5 % 4 = 1 ∧ 3 % 2 = 1 := by decide
-- Even increment: (5x + 2) mod 16 from 7 loops after 8. And a = 3 (remainder 3 on division
-- by 4): (3x + 3) mod 16 from 7 also loops after 8.
example : (fun x : ℕ => (5 * x + 2) % 16)^[8] 7 = 7 ∧
    ∀ n ∈ Finset.Ico 1 8, (fun x : ℕ => (5 * x + 2) % 16)^[n] 7 ≠ 7 := by decide
example : (fun x : ℕ => (3 * x + 3) % 16)^[8] 7 = 7 ∧
    ∀ n ∈ Finset.Ico 1 8, (fun x : ℕ => (3 * x + 3) % 16)^[n] 7 ≠ 7 := by decide
-- Brute force for m = 16: for every pair a, c from 0 to 15, 0 first comes back at step 16
-- exactly when the rule holds, and the rule picks out 32 of the 256 pairs.
example : ∀ a ∈ Finset.range 16, ∀ c ∈ Finset.range 16,
    (((fun x : ℕ => (a * x + c) % 16)^[16] 0 = 0 ∧
        ∀ n ∈ Finset.Ico 1 16, (fun x : ℕ => (a * x + c) % 16)^[n] 0 ≠ 0) ↔
      (c % 2 = 1 ∧ a % 4 = 1)) := by decide
example : ((Finset.range 16 ×ˢ Finset.range 16).filter
      (fun p : ℕ × ℕ => p.2 % 2 = 1 ∧ p.1 % 4 = 1)).card = 32 := by decide
-- A full loop is not randomness: a = 1, c = 1 counts 8, 9, 10, 11, 12, 13.
example : (List.range 6).map (fun n => (fun x : ℕ => (x + 1) % 16)^[n] 8) =
    [8, 9, 10, 11, 12, 13] := by decide
-- The toy's consecutive pairs (x, y) lie on four lines: x + 3y is 9, 25, 41 or 57.
example : ∀ x ∈ Finset.range 16, (x + 3 * ((5 * x + 3) % 16)) % 16 = 9 ∧
    x + 3 * ((5 * x + 3) % 16) ∈ ({9, 25, 41, 57} : Finset ℕ) := by decide
-- Its last bit alternates 0, 1, 0, 1 along the stream 6, 1, 8, 11, ...
example : (List.range 12).map (fun n => (fun x : ℕ => (5 * x + 3) % 16)^[n + 1] 7 % 2) =
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1] := by decide
-- RANDU: 65539 = 2^16 + 3, and a² leaves the same remainder as 6a − 9 on division by 2^31.
example : 65539 = 2 ^ 16 + 3 ∧ 65539 ^ 2 % 2 ^ 31 = (6 * 65539 - 9) % 2 ^ 31 := by norm_num
-- minstd, a = 16807, m = 2^31 − 1, seed 1: the 10,000th state is 1043618065, by stepping
-- 10,000 times and by jumping straight there with a^10000 × 1 mod m.
example : (fun x : ℕ => 16807 * x % (2 ^ 31 - 1))^[10000] 1 = 1043618065 := by decide +kernel
example : 16807 ^ 10000 * 1 % (2 ^ 31 - 1) = 1043618065 := by decide +kernel

#print axioms lcg_full_cycle_iff_c_odd_and_a_one_mod_four
#print axioms lcg_no_increment_jump_ahead
#print axioms randu_three_outputs_satisfy_nine_minus_six_plus_one
