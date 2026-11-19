-- Erdos problems: a Collatz search that sees every start from 2 to N drop below itself proves every start up to N reaches 1, a clean range forces any other cycle to satisfy the cycle inequality, and every sign sequence of length 12 or more has discrepancy at least 2.
import Mathlib.Logic.Function.Iterate
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.Order.Ring.Abs
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.Ring.Parity
import Mathlib.Algebra.Order.BigOperators.GroupWithZero.Finset
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Dynamics.PeriodicPts.Defs
import Mathlib.Data.Nat.Bits
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-- One Collatz step C(n): halve an even number; triple an odd number and add one. -/
def collatz (n : ℕ) : ℕ := if n % 2 = 0 then n / 2 else 3 * n + 1

/-- The same rule with 5n + 1 in place of 3n + 1, used on the card to show the step matters. -/
def collatz5 (n : ℕ) : ℕ := if n % 2 = 0 then n / 2 else 5 * n + 1

/-- The i-th sign of the sign sequence coded by the whole number c, as in the card's code:
x_i is -1 when bit i - 1 of c is 1, and +1 otherwise. -/
def sign (c i : ℕ) : ℤ := if c.testBit (i - 1) then -1 else 1

/-- The sign sequence coded by c, of length n, keeps every sum x_d + x_2d + ... + x_jd
(with jd at most n) at -1, 0 or +1. -/
def discWithinOne (n c : ℕ) : Bool :=
  (List.range' 1 n).all fun d => (List.range' 1 (n / d)).all fun j =>
    decide (|((List.range' 1 j).map fun i => sign c (i * d)).sum| ≤ 1)

theorem collatz_pos {n : ℕ} (hn : 1 ≤ n) : 1 ≤ collatz n := by
  unfold collatz; split_ifs <;> omega
#print axioms collatz_pos

theorem collatz_iterate_pos {n : ℕ} (hn : 1 ≤ n) (i : ℕ) : 1 ≤ collatz^[i] n := by
  induction i with
  | zero => simpa using hn
  | succ i ih => rw [Function.iterate_succ_apply']; exact collatz_pos ih
#print axioms collatz_iterate_pos

theorem collatz_step (m : ℕ) :
    (if m % 2 = 1 then 1 else 2) * collatz m = (if m % 2 = 1 then 3 * m + 1 else m) := by
  unfold collatz; split_ifs <;> omega
#print axioms collatz_step

theorem foldr_bit_lt (l : List Bool) : l.foldr Nat.bit 0 < 2 ^ l.length := by
  induction l with
  | nil => simp
  | cons b l ih =>
    simp only [List.foldr_cons, List.length_cons, Nat.bit_val, pow_succ]
    cases b <;> simp <;> omega
#print axioms foldr_bit_lt

theorem foldr_bit_testBit (l : List Bool) (k : ℕ) :
    (l.foldr Nat.bit 0).testBit k = l.getD k false := by
  induction l generalizing k with
  | nil => simp
  | cons b l ih =>
    cases k with
    | zero => simp
    | succ k => simp [Nat.testBit_bit_succ, ih]
#print axioms foldr_bit_testBit

theorem sum_range'_eq_sum_Icc (f : ℕ → ℤ) (j : ℕ) :
    ((List.range' 1 j).map f).sum = ∑ i ∈ Finset.Icc 1 j, f i := by
  induction j with
  | zero => simp
  | succ j ih =>
    rw [List.range'_concat, List.map_append, List.sum_append, ih,
      Finset.sum_Icc_succ_top (by omega)]
    simp [add_comm]
#print axioms sum_range'_eq_sum_Icc

theorem no_code_within_one_all :
    ((List.range 4096).all fun c => !discWithinOne 12 c) = true := by
  decide +kernel
#print axioms no_code_within_one_all

theorem no_code_within_one (c : ℕ) (hc : c < 4096) : discWithinOne 12 c = false := by
  have h := List.all_eq_true.1 no_code_within_one_all c (List.mem_range.2 hc)
  simpa using h
#print axioms no_code_within_one

/-- A clean range forces any other cycle to be long (the cycle inequality). Suppose every
whole number from 1 to N reaches 1 under the Collatz step. Take a cycle: a start n ≥ 1 that
returns to itself after p ≥ 1 steps, never passing through 1 (so it is not 1, 4, 2, 1). Let
k be its number of odd steps and L = p - k its number of halvings. Then
1 < 2^L / 3^k < (1 + 1/(3N))^k, written here in whole numbers as
3^k < 2^L and 2^L · (3N)^k < 3^k · (3N + 1)^k. -/
theorem clean_range_forces_cycle_inequality (N n p : ℕ)
    (hrange : ∀ m, 1 ≤ m → m ≤ N → ∃ i, collatz^[i] m = 1)
    (hn : 1 ≤ n) (hp : 1 ≤ p) (hcycle : collatz^[p] n = n)
    (havoid : ∀ i < p, collatz^[i] n ≠ 1) :
    let k := ((Finset.range p).filter fun i => collatz^[i] n % 2 = 1).card
    let L := p - k
    3 ^ k < 2 ^ L ∧ 2 ^ L * (3 * N) ^ k < 3 ^ k * (3 * N + 1) ^ k := by
  intro k L
  set a : ℕ → ℕ := fun i => collatz^[i] n with ha
  have hpos : ∀ i, 0 < a i := fun i => collatz_iterate_pos hn i
  -- every point of the cycle lies above N
  have hbig : ∀ i, N < a i := by
    intro i
    by_contra h
    obtain ⟨j, hj⟩ := hrange (a i) (hpos i) (by omega)
    have hper : Function.IsPeriodicPt collatz p n := hcycle
    have : collatz^[(j + i) % p] n = 1 := by
      rw [hper.iterate_mod_apply, Function.iterate_add_apply]; exact hj
    exact havoid _ (Nat.mod_lt _ (by omega)) this
  set S := Finset.range p
  set O := S.filter fun i => a i % 2 = 1 with hO
  set E := S.filter fun i => ¬ a i % 2 = 1 with hE
  have hk : O.card = k := rfl
  have hEcard : E.card = L := by
    have h : O.card + E.card = S.card := Finset.card_filter_add_card_filter_not _
    rw [Finset.card_range] at h
    show E.card = p - k
    rw [← hk]; omega
  -- the cycle identity 2^L * ∏_O a = ∏_O (3a+1)
  have hshift : ∏ i ∈ S, a (i + 1) = ∏ i ∈ S, a i := by
    have h1 := Finset.prod_range_succ' a p
    have h2 := Finset.prod_range_succ a p
    have hap : a p = a 0 := by simp [ha, hcycle]
    rw [h2, hap] at h1
    exact (Nat.eq_of_mul_eq_mul_right (hpos 0) h1).symm
  have hsucc : ∀ i, a (i + 1) = collatz (a i) := fun i => by
    simp [ha, Function.iterate_succ_apply']
  have hprod : ∏ i ∈ S, ((if a i % 2 = 1 then 1 else 2) * a (i + 1)) =
      ∏ i ∈ S, (if a i % 2 = 1 then 3 * a i + 1 else a i) :=
    Finset.prod_congr rfl fun i _ => by rw [hsucc]; exact collatz_step (a i)
  rw [Finset.prod_mul_distrib, Finset.prod_ite, Finset.prod_ite, hshift,
    ← Finset.prod_filter_mul_prod_filter_not S (fun i => a i % 2 = 1)] at hprod
  simp only [Finset.prod_const_one, one_mul, Finset.prod_const] at hprod
  rw [← hO, ← hE, hEcard] at hprod
  have hEpos : 0 < ∏ i ∈ E, a i := Finset.prod_pos fun i _ => hpos i
  have hid : 2 ^ L * ∏ i ∈ O, a i = ∏ i ∈ O, (3 * a i + 1) := by
    apply Nat.eq_of_mul_eq_mul_right hEpos
    rw [mul_assoc]; exact hprod
  -- there is at least one odd step
  have hOne : O.Nonempty := by
    rw [Finset.nonempty_iff_ne_empty]
    intro hO0
    rw [hO0, Finset.prod_empty, Finset.prod_empty, mul_one] at hid
    have hk0 : k = 0 := by rw [← hk, hO0, Finset.card_empty]
    have : L = p := by show p - k = p; omega
    rw [this] at hid
    have : 2 ≤ 2 ^ p := by
      calc 2 = 2 ^ 1 := by norm_num
        _ ≤ 2 ^ p := Nat.pow_le_pow_right (by norm_num) hp
    omega
  have hQpos : 0 < ∏ i ∈ O, a i := Finset.prod_pos fun i _ => hpos i
  constructor
  · have hlt : ∏ i ∈ O, (3 * a i) < ∏ i ∈ O, (3 * a i + 1) :=
      Finset.prod_lt_prod_of_nonempty₀ (fun i _ => by have := hpos i; omega)
        (fun i _ => by omega) hOne
    rw [Finset.prod_mul_distrib, Finset.prod_const, hk, ← hid] at hlt
    exact Nat.lt_of_mul_lt_mul_right hlt
  · rcases Nat.eq_zero_or_pos N with hN | hN
    · have hkpos : 0 < k := by rw [← hk]; exact hOne.card_pos
      subst hN
      simp only [mul_zero, zero_pow hkpos.ne', mul_zero, zero_add, one_pow, mul_one]
      positivity
    have hlt : ∏ i ∈ O, ((3 * a i + 1) * (3 * N)) < ∏ i ∈ O, ((3 * a i) * (3 * N + 1)) :=
      Finset.prod_lt_prod_of_nonempty₀ (fun i _ => by have := hpos i; positivity)
        (fun i _ => by have := hbig i; nlinarith) hOne
    have e1 : ∏ i ∈ O, ((3 * a i + 1) * (3 * N)) = (∏ i ∈ O, (3 * a i + 1)) * (3 * N) ^ k := by
      rw [Finset.prod_mul_distrib, Finset.prod_const, hk]
    have e2 : ∏ i ∈ O, ((3 * a i) * (3 * N + 1)) =
        3 ^ k * (∏ i ∈ O, a i) * (3 * N + 1) ^ k := by
      rw [Finset.prod_mul_distrib, Finset.prod_mul_distrib, Finset.prod_const, Finset.prod_const, hk]
    rw [e1, e2, ← hid] at hlt
    apply Nat.lt_of_mul_lt_mul_right (a := ∏ i ∈ O, a i)
    calc 2 ^ L * (3 * N) ^ k * (∏ i ∈ O, a i) = 2 ^ L * (∏ i ∈ O, a i) * (3 * N) ^ k := by ring
      _ < 3 ^ k * (∏ i ∈ O, a i) * (3 * N + 1) ^ k := hlt
      _ = 3 ^ k * (3 * N + 1) ^ k * (∏ i ∈ O, a i) := by ring

/-- Falling below the start is enough. If an exhaustive search finds that every start n from
2 to N eventually drops below n under the Collatz step, then every start from 1 to N
reaches 1. -/
theorem every_start_reaches_one_of_every_start_drops (N : ℕ)
    (hsearch : ∀ n, 2 ≤ n → n ≤ N → ∃ i, collatz^[i] n < n) :
    ∀ n, 1 ≤ n → n ≤ N → ∃ i, collatz^[i] n = 1 := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro hn hnN
    rcases Nat.eq_or_lt_of_le hn with h | h
    · exact ⟨0, by simp [← h]⟩
    obtain ⟨i, hi⟩ := hsearch n h hnN
    obtain ⟨j, hj⟩ := ih _ hi (collatz_iterate_pos (by omega) i) (by omega)
    exact ⟨j + i, by rw [Function.iterate_add_apply]; exact hj⟩

/-- Discrepancy 1 is settled by search: for every sign sequence x_1, x_2, ..., each +1 or -1,
of length n ≥ 12, some step d and count j with jd ≤ n give a sum
x_d + x_2d + ... + x_jd of size at least 2. -/
theorem sign_sequence_of_length_twelve_has_discrepancy_two (n : ℕ) (hn : 12 ≤ n)
    (x : ℕ → ℤ) (hx : ∀ i, x i = 1 ∨ x i = -1) :
    ∃ d j, 1 ≤ d ∧ 1 ≤ j ∧ j * d ≤ n ∧ 2 ≤ |∑ i ∈ Finset.Icc 1 j, x (i * d)| := by
  set b : List Bool := (List.range 12).map (fun k => decide (x (k + 1) = -1)) with hb
  set c := b.foldr Nat.bit 0 with hcdef
  have hc : c < 4096 := by
    have := foldr_bit_lt b
    simpa [hb] using this
  have hsign : ∀ m, 1 ≤ m → m ≤ 12 → sign c m = x m := by
    intro m hm1 hm2
    unfold sign
    rw [hcdef, foldr_bit_testBit, hb, List.getD_eq_getElem?_getD,
      List.getElem?_eq_getElem (by simp; omega)]
    simp only [List.getElem_map, List.getElem_range, Option.getD_some]
    rw [show m - 1 + 1 = m by omega]
    rcases hx m with h | h <;> simp [h]
  have hk := no_code_within_one c hc
  simp only [discWithinOne, List.all_eq_false, List.mem_range'_1, Bool.not_eq_true,
    decide_eq_false_iff_not] at hk
  obtain ⟨d, ⟨hd1, hd2⟩, j, ⟨hj1, hj2⟩, hlt⟩ := hk
  have hjd : j * d ≤ 12 := (Nat.le_div_iff_mul_le (by omega)).1 (by omega)
  refine ⟨d, j, hd1, hj1, by omega, ?_⟩
  rw [sum_range'_eq_sum_Icc] at hlt
  have : ∑ i ∈ Finset.Icc 1 j, sign c (i * d) = ∑ i ∈ Finset.Icc 1 j, x (i * d) := by
    apply Finset.sum_congr rfl
    intro i hi
    rw [Finset.mem_Icc] at hi
    apply hsign
    · exact Nat.mul_le_mul hi.1 hd1
    · exact le_trans (Nat.mul_le_mul_right d hi.2) hjd
  rw [this] at hlt
  simp at hlt
  omega

-- 27 reaches 1 after 111 steps, not before, and its walk peaks at 9,232.
example : collatz^[111] 27 = 1 ∧ (∀ i < 111, collatz^[i] 27 ≠ 1) ∧
    (∀ i ≤ 111, collatz^[i] 27 ≤ 9232) ∧ collatz^[77] 27 = 9232 := by
  decide +kernel
-- The record below a million: 837,799 reaches 1 after 524 steps, not before.
example : collatz^[524] 837799 = 1 ∧ ∀ i < 524, collatz^[i] 837799 ≠ 1 := by
  decide +kernel
-- Class 1 mod 4: 4a + 1 → 12a + 4 → 6a + 2 → 3a + 1, below 4a + 1 for a ≥ 1.
example (a : ℕ) (ha : 1 ≤ a) : collatz^[3] (4 * a + 1) = 3 * a + 1 ∧ 3 * a + 1 < 4 * a + 1 := by
  have h1 : collatz (4 * a + 1) = 12 * a + 4 := by unfold collatz; split_ifs <;> omega
  have h2 : collatz (12 * a + 4) = 6 * a + 2 := by unfold collatz; split_ifs <;> omega
  have h3 : collatz (6 * a + 2) = 3 * a + 1 := by unfold collatz; split_ifs <;> omega
  refine ⟨?_, by omega⟩
  simp only [Function.iterate_succ, Function.iterate_zero, Function.comp_apply, id_eq, h1, h2, h3]
-- The base case: 1 → 4 → 2 → 1 never drops below 1.
example : collatz 1 = 4 ∧ collatz 4 = 2 ∧ collatz 2 = 1 := by decide
-- With 5n + 1 the walk from 13 returns to 13 after 10 steps:
-- 13, 66, 33, 166, 83, 416, 208, 104, 52, 26, 13.
example : collatz5^[10] 13 = 13 ∧ ∀ i, 1 ≤ i → i < 10 → collatz5^[i] 13 ≠ 13 := by
  decide +kernel
-- The cycle bound at N = 1,000,000: k = 2,966 odd steps and L = 4,701 halvings fit,
-- in exact whole numbers.
example : 3 ^ 2966 < 2 ^ 4701 ∧
    2 ^ 4701 * (3 * 1000000) ^ 2966 < 3 ^ 2966 * (3 * 1000000 + 1) ^ 2966 := by
  decide +kernel
-- The published range: 2^68 = 295,147,905,179,352,825,856, and 2^71 is 8 times 2^68.
example : 2 ^ 68 = 295147905179352825856 ∧ 2 ^ 71 = 8 * 2 ^ 68 := by decide
-- Sign sequences within discrepancy 1, lengths 1 to 12: 2, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 0.
example : ((List.range 12).map fun n =>
    ((List.range (2 ^ (n + 1))).filter (discWithinOne (n + 1))).length) =
    [2, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 0] := by
  decide +kernel

#print axioms clean_range_forces_cycle_inequality
#print axioms every_start_reaches_one_of_every_start_drops
#print axioms sign_sequence_of_length_twelve_has_discrepancy_two
