-- Local time and Tanaka's formula: for a ±1 coin walk, the distance from 0 equals the bet on moves away from 0 plus the visits to 0, on every path, so average distance equals average visits; and a call payoff is half a line plus half a kink.
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

open Finset

/-- The coin counter after `k` tosses, `S_k = X_0 + X_1 + ... + X_{k-1}`, started at 0.
(The card numbers the tosses from 1; here toss `k + 1` is `X k`.) -/
def walk (X : ℕ → ℤ) (k : ℕ) : ℤ := ∑ j ∈ range k, X j

/-- The betting result after `n` tosses: before each toss, bet `sgn(S_k)` units on the toss,
with the sign read before the move and `sgn 0 = 0` (`Int.sign`). -/
def bet (X : ℕ → ℤ) (n : ℕ) : ℤ := ∑ k ∈ range n, Int.sign (walk X k) * X k

/-- The walk's local time `N_n`: the number of `k` from `0` to `n - 1` with `S_k = 0`. -/
def visits (X : ℕ → ℤ) (n : ℕ) : ℕ := #{k ∈ range n | walk X k = 0}

/-- The tosses of one path `ω` of `n` fair coin tosses: `+1` for heads (`true`), `-1` for tails;
no tosses after the `n`-th. -/
def coinStep {n : ℕ} (ω : Fin n → Bool) (k : ℕ) : ℤ :=
  if h : k < n then (if ω ⟨k, h⟩ then 1 else -1) else 0

/-- One step of the discrete Tanaka formula: for an integer `s` and a step `x = ±1`,
`|s + x| = |s| + sgn(s) x + [s = 0]`. -/
theorem abs_add_step (s x : ℤ) (hx : x = 1 ∨ x = -1) :
    |s + x| = |s| + Int.sign s * x + (if s = 0 then 1 else 0) := by
  rcases lt_trichotomy s 0 with hs | hs | hs
  · have h1 : Int.sign s = -1 := Int.sign_eq_neg_one_of_neg hs
    have h0 : s ≠ 0 := hs.ne
    rw [h1, abs_of_neg hs]
    simp only [h0, ite_false]
    rcases hx with rfl | rfl
    · rw [abs_of_nonpos (by omega)]; ring
    · rw [abs_of_neg (by omega)]; ring
  · subst hs
    rcases hx with rfl | rfl <;> simp
  · have h1 : Int.sign s = 1 := Int.sign_eq_one_of_pos hs
    have h0 : s ≠ 0 := hs.ne'
    rw [h1, abs_of_pos hs]
    simp only [h0, ite_false]
    rcases hx with rfl | rfl
    · rw [abs_of_pos (by omega)]; ring
    · rw [abs_of_nonneg (by omega)]; ring

/-- Flipping toss `k` of a path leaves the counter before toss `k` unchanged and flips the
sign of toss `k`, so each bet term sums to zero over all paths. -/
theorem sum_sign_walk_mul_coinStep (n k : ℕ) :
    ∑ ω : Fin n → Bool, Int.sign (walk (coinStep ω) k) * coinStep ω k = 0 := by
  by_cases hk : k < n
  · set i : Fin n := ⟨k, hk⟩
    let f : (Fin n → Bool) → (Fin n → Bool) := fun ω => Function.update ω i (!ω i)
    have hinv : Function.Involutive f := by
      intro ω
      funext j
      by_cases hj : j = i
      · subst hj; simp [f]
      · simp [f, Function.update_of_ne hj]
    have hwalk : ∀ ω, walk (coinStep (f ω)) k = walk (coinStep ω) k := by
      intro ω
      unfold walk
      refine Finset.sum_congr rfl fun j hj => ?_
      have hjk : j < k := Finset.mem_range.mp hj
      have hjn : j < n := lt_trans hjk hk
      unfold coinStep
      rw [dif_pos hjn, dif_pos hjn]
      have hne : (⟨j, hjn⟩ : Fin n) ≠ i := by
        intro h; have := congrArg Fin.val h; simp [i] at this; omega
      simp [f, Function.update_of_ne hne]
    have hstep : ∀ ω, coinStep (f ω) k = - coinStep ω k := by
      intro ω
      unfold coinStep
      rw [dif_pos hk, dif_pos hk]
      have : (⟨k, hk⟩ : Fin n) = i := rfl
      rw [this]
      cases h : ω i <;> simp [f, h]
    have hsum := Equiv.sum_comp hinv.toPerm
      (fun ω => Int.sign (walk (coinStep ω) k) * coinStep ω k)
    simp only [Function.Involutive.coe_toPerm, hwalk, hstep] at hsum
    simp only [mul_neg, Finset.sum_neg_distrib] at hsum
    linarith
  · refine Finset.sum_eq_zero fun ω _ => ?_
    simp [coinStep, hk]

/-- Discrete Tanaka formula. For a walk whose every step is `+1` or `-1`, on every path and
after every number of tosses `n`, the distance from 0 is the bet on moves away from 0 plus
the number of visits to 0 before toss `n`: `|S_n| = Σ sgn(S_{k-1}) X_k + N_n`. -/
theorem abs_walk_eq_bet_add_visits (X : ℕ → ℤ) (hX : ∀ k, X k = 1 ∨ X k = -1) (n : ℕ) :
    |walk X n| = bet X n + visits X n := by
  induction n with
  | zero => simp [walk, bet, visits]; rfl
  | succ n ih =>
    have hw : walk X (n + 1) = walk X n + X n := by simp [walk, Finset.sum_range_succ]
    have hb : bet X (n + 1) = bet X n + Int.sign (walk X n) * X n := by
      simp [bet, Finset.sum_range_succ]
    have hv : (visits X (n + 1) : ℤ) = visits X n + (if walk X n = 0 then 1 else 0) := by
      unfold visits
      rw [Finset.range_add_one, Finset.filter_insert]
      split_ifs with h
      · rw [Finset.card_insert_of_notMem (by simp)]; push_cast; ring
      · simp
    rw [hw, hb, hv, abs_add_step _ _ (hX n), ih]
    ring

/-- Average visits equal average distance. Over all `2^n` equally likely runs of `n` fair
coin tosses, the total distance from 0 at the end equals the total number of visits to 0
before toss `n`; dividing both by `2^n`, `E|S_n| = E N_n`. -/
theorem sum_abs_walk_eq_sum_visits (n : ℕ) :
    ∑ ω : Fin n → Bool, |walk (coinStep ω) n| = ∑ ω : Fin n → Bool, (visits (coinStep ω) n : ℤ) := by
  have hX : ∀ ω : Fin n → Bool, ∀ k < n, coinStep ω k = 1 ∨ coinStep ω k = -1 := by
    intro ω k hk
    unfold coinStep
    rw [dif_pos hk]
    split_ifs <;> simp
  -- Modify the tosses after `n` to be `+1`, which does not change anything up to `n`.
  let Y : (Fin n → Bool) → ℕ → ℤ := fun ω k => if k < n then coinStep ω k else 1
  have hYX : ∀ ω k, k ≤ n → walk (Y ω) k = walk (coinStep ω) k := by
    intro ω k hk
    unfold walk
    refine Finset.sum_congr rfl fun j hj => ?_
    have : j < n := lt_of_lt_of_le (Finset.mem_range.mp hj) hk
    simp [Y, this]
  have hY : ∀ ω k, Y ω k = 1 ∨ Y ω k = -1 := by
    intro ω k
    by_cases hk : k < n
    · simp only [Y, if_pos hk]; exact hX ω k hk
    · simp [Y, hk]
  have hbet : ∀ ω, bet (Y ω) n = bet (coinStep ω) n := by
    intro ω
    unfold bet
    refine Finset.sum_congr rfl fun k hk => ?_
    have hkn : k < n := Finset.mem_range.mp hk
    rw [hYX ω k hkn.le]
    simp [Y, hkn]
  have hvis : ∀ ω, visits (Y ω) n = visits (coinStep ω) n := by
    intro ω
    unfold visits
    congr 1
    refine Finset.filter_congr fun k hk => ?_
    rw [hYX ω k (Finset.mem_range.mp hk).le]
  have key : ∀ ω : Fin n → Bool,
      |walk (coinStep ω) n| = bet (coinStep ω) n + visits (coinStep ω) n := by
    intro ω
    rw [← hYX ω n le_rfl, ← hbet, ← hvis]
    exact abs_walk_eq_bet_add_visits (Y ω) (hY ω) n
  have hzero : ∑ ω : Fin n → Bool, bet (coinStep ω) n = 0 := by
    unfold bet
    rw [Finset.sum_comm]
    exact Finset.sum_eq_zero fun k _ => sum_sign_walk_mul_coinStep n k
  rw [Finset.sum_congr rfl fun ω _ => key ω, Finset.sum_add_distrib, hzero, zero_add]

/-- A call payoff is half a straight line plus half a kink at the strike:
`(x - K)^+ = ((x - K) + |x - K|) / 2`. This is why the call's local-time term arrives halved. -/
theorem call_payoff_eq_half_line_add_half_kink (x K : ℝ) :
    max (x - K) 0 = ((x - K) + |x - K|) / 2 := by
  rcases le_total 0 (x - K) with h | h
  · rw [max_eq_left h, abs_of_nonneg h]; ring
  · rw [max_eq_right h, abs_of_nonpos h]; ring

/-- The card's hand run: up, down, down, up, up, up, down, down, down, down. -/
def handStep (k : ℕ) : ℤ := [1, -1, -1, 1, 1, 1, -1, -1, -1, -1].getD k 0

-- The counter ends at -2, so the distance is 2.
example : walk handStep 10 = -2 := by decide
example : |walk handStep 10| = 2 := by decide
-- The betting result is -2.
example : bet handStep 10 = -2 := by decide
-- The counter stands at 0 before tosses 1, 3, 5 and 9: four visits.
example : visits handStep 10 = 4 := by decide
-- 2 = -2 + 4.
example : |walk handStep 10| = bet handStep 10 + visits handStep 10 := by decide

-- All 1,024 ten-toss runs: total distance 2520 and total visits 2520, so both averages are
-- 2520 / 1024 = 2.4609375.
example : ∑ ω : Fin 10 → Bool, |walk (coinStep ω) 10| = 2520 := by decide +kernel
example : ∑ ω : Fin 10 → Bool, (visits (coinStep ω) 10 : ℤ) = 2520 := by decide +kernel
-- The binomial count: the chances the counter is at 0 after 0, 2, 4, 6, 8 tosses add to
-- 1 + 1/2 + 3/8 + 5/16 + 35/128 = 315/128 = 2520/1024.
example : ∑ m ∈ range 5, ((Nat.choose (2 * m) m : ℚ) / 4 ^ m) = 315 / 128 := by
  norm_num [Finset.sum_range_succ, Nat.choose]

-- The call in the card at strike 100: a price of 120 pays 20, a price of 90 pays 0.
example : max ((120 : ℝ) - 100) 0 = 20 := by norm_num
example : max ((90 : ℝ) - 100) 0 = 0 := by norm_num

#print axioms abs_add_step
#print axioms sum_sign_walk_mul_coinStep
#print axioms abs_walk_eq_bet_add_visits
#print axioms sum_abs_walk_eq_sum_visits
#print axioms call_payoff_eq_half_line_add_half_kink
