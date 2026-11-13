-- Representing a martingale: on a coin-toss tree where every day has exactly two outcomes, every martingale is its starting value plus the gain of exactly one predictable stake in a share that moves on every branch, so every payoff is copied by a trading strategy that costs its average.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp

open Finset

/-! A node of the tree is the list of tosses seen so far (`true` = heads, `false` = tails).
A process is a function of the node, so it only uses the tosses already seen; a stake
`H w` is indexed by the node *before* the next toss, so it is predictable.
`q w` is the chance that the toss after node `w` is heads. -/

/-- **Martingale representation on a binary tree.** Over `N` days, each day has exactly two
outcomes, each with positive chance. If the share `S` is a martingale under these chances,
the share moves on every branch (`S⁺ ≠ S⁻`), and `M` is any martingale under the same chances,
then there is a stake `H`, fixed by the tosses already seen, with
`M_n = M_0 + ∑_{k<n} H_k (S_k - S_{k-1})` on every path and every day `n ≤ N`;
and this stake is unique at every node before the last day. -/
theorem martingale_representation_binary_tree (N : ℕ) (q S M : List Bool → ℝ)
    (hq : ∀ w : List Bool, w.length < N → 0 < q w ∧ q w < 1)
    (hS : ∀ w : List Bool, w.length < N →
      S w = q w * S (w ++ [true]) + (1 - q w) * S (w ++ [false]))
    (hmove : ∀ w : List Bool, w.length < N → S (w ++ [true]) ≠ S (w ++ [false]))
    (hM : ∀ w : List Bool, w.length < N →
      M w = q w * M (w ++ [true]) + (1 - q w) * M (w ++ [false])) :
    ∃ H : List Bool → ℝ,
      (∀ ω : List Bool, ω.length = N → ∀ n ≤ N,
        M (ω.take n) = M [] + ∑ k ∈ range n, H (ω.take k) * (S (ω.take (k + 1)) - S (ω.take k))) ∧
      ∀ H' : List Bool → ℝ,
        (∀ ω : List Bool, ω.length = N → ∀ n ≤ N,
          M (ω.take n) = M [] + ∑ k ∈ range n, H' (ω.take k) * (S (ω.take (k + 1)) - S (ω.take k))) →
        ∀ w : List Bool, w.length < N → H' w = H w := by
  set H : List Bool → ℝ := fun w =>
    (M (w ++ [true]) - M (w ++ [false])) / (S (w ++ [true]) - S (w ++ [false])) with hHdef
  have key : ∀ w : List Bool, w.length < N → ∀ b : Bool,
      M (w ++ [b]) - M w = H w * (S (w ++ [b]) - S w) := by
    intro w hw b
    have hne : S (w ++ [true]) - S (w ++ [false]) ≠ 0 := sub_ne_zero.mpr (hmove w hw)
    simp only [hHdef]
    cases b
    · rw [hM w hw, hS w hw]; field_simp; ring
    · rw [hM w hw, hS w hw]; field_simp; ring
  refine ⟨H, ?_, ?_⟩
  · intro ω hω n hn
    induction n with
    | zero => simp
    | succ n ih =>
      have hlt : n < ω.length := by omega
      rw [sum_range_succ, ← add_assoc, ← ih (by omega)]
      have htake : ω.take (n + 1) = ω.take n ++ [ω[n]] := by
        rw [List.take_add_one, List.getElem?_eq_getElem hlt]; rfl
      have hlen : (ω.take n).length < N := by simp; omega
      have := key (ω.take n) hlen ω[n]
      rw [htake]
      linarith
  · intro H' hH' w hw
    set ω := w ++ true :: List.replicate (N - w.length - 1) true with hω
    have hωlen : ω.length = N := by simp [hω]; omega
    have e1 := hH' ω hωlen (w.length + 1) (by omega)
    have e0 := hH' ω hωlen w.length (by omega)
    have t0 : ω.take w.length = w := by simp [hω]
    have t1 : ω.take (w.length + 1) = w ++ [true] := by simp [hω, List.take_append]
    rw [sum_range_succ, t0, t1] at e1
    rw [t0] at e0
    have hk := key w hw true
    have hne : S (w ++ [true]) - S w ≠ 0 := by
      rw [hS w hw]
      have h1 : S (w ++ [true]) - (q w * S (w ++ [true]) + (1 - q w) * S (w ++ [false])) =
          (1 - q w) * (S (w ++ [true]) - S (w ++ [false])) := by ring
      rw [h1]
      exact mul_ne_zero (by linarith [(hq w hw).2]) (sub_ne_zero.mpr (hmove w hw))
    apply mul_right_cancel₀ hne
    linarith

/-- **Every payoff is a trading strategy, and its cost is its fair price.** A share moves by
`+d` on heads and `-d` on tails each day, `d ≠ 0`, with a fair coin. Any payoff `V` on the
`2^N` coin sequences equals its average `E[V]` plus the gain of a stake fixed by the tosses
already seen: `V = E[V] + ∑_k H_k (S_k - S_{k-1})` on every sequence. -/
theorem every_payoff_is_a_strategy (N : ℕ) (d : ℝ) (hd : d ≠ 0) (V : (Fin N → Bool) → ℝ) :
    ∃ H : List Bool → ℝ, ∀ ω : Fin N → Bool,
      V ω = (∑ ω' : Fin N → Bool, V ω') / 2 ^ N +
        ∑ k : Fin N, H ((List.ofFn ω).take k) * (d * (if ω k then 1 else -1)) := by
  induction N with
  | zero =>
    refine ⟨fun _ => 0, fun ω => ?_⟩
    have : ∀ ω' : Fin 0 → Bool, ω' = ω := fun ω' => funext (fun i => i.elim0)
    simp
    exact congrArg V (Subsingleton.elim _ _)
  | succ N ih =>
    obtain ⟨H0, h0⟩ := ih (fun ω => V (Fin.cons true ω))
    obtain ⟨H1, h1⟩ := ih (fun ω => V (Fin.cons false ω))
    set s0 := ∑ ω' : Fin N → Bool, V (Fin.cons true ω')
    set s1 := ∑ ω' : Fin N → Bool, V (Fin.cons false ω')
    have hsum : ∑ ω' : Fin (N+1) → Bool, V ω' = s0 + s1 := by
      rw [← (Fin.consEquiv (fun _ : Fin (N+1) => Bool)).sum_comp, Fintype.sum_prod_type,
        Fintype.sum_bool]
      rfl
    refine ⟨fun w => match w with
      | [] => (s0 / 2 ^ N - s1 / 2 ^ N) / (2 * d)
      | b :: w => if b then H0 w else H1 w, fun ω => ?_⟩
    rw [hsum, Fin.sum_univ_succ]
    obtain ⟨b, ω', rfl⟩ : ∃ b ω', ω = Fin.cons b ω' := ⟨ω 0, Fin.tail ω, (Fin.cons_self_tail ω).symm⟩
    simp only [List.ofFn_succ, Fin.cons_zero, Fin.cons_succ, Fin.val_zero, Fin.val_succ,
      List.take_zero, List.take_succ_cons]
    have hp : (2:ℝ) ^ (N+1) = 2 * 2 ^ N := by ring
    have h2N : (2:ℝ) ^ N ≠ 0 := by positivity
    cases b
    · simp only [Bool.false_eq_true, ite_false]
      rw [h1 ω', hp]
      have : (s0 / 2 ^ N - s1 / 2 ^ N) / (2 * d) * (d * -1) = (s1 - s0) / (2 * 2 ^ N) := by
        field_simp; ring
      rw [this, ← add_assoc]; congr 1; field_simp; ring
    · simp only [ite_true]
      rw [h0 ω', hp]
      have : (s0 / 2 ^ N - s1 / 2 ^ N) / (2 * d) * (d * 1) = (s0 - s1) / (2 * 2 ^ N) := by
        field_simp
      rw [this, ← add_assoc]; congr 1; field_simp; ring

/-- **Three outcomes a day breaks it.** If the $100 share can move up $10, stay flat, or move
down $10 on each of 3 days, no starting value and no stake fixed by the moves already seen
copies the call with strike $100 on all 27 sequences. Move `i : Fin 3` is `i - 1`. -/
theorem call_not_copied_with_three_outcomes :
    ¬ ∃ (x : ℝ) (H : List (Fin 3) → ℝ), ∀ ω : Fin 3 → Fin 3,
      max (10 * ∑ k : Fin 3, ((ω k : ℝ) - 1)) 0 =
        x + ∑ k : Fin 3, H ((List.ofFn ω).take k) * (10 * ((ω k : ℝ) - 1)) := by
  rintro ⟨x, H, h⟩
  have h1 := h ![1, 1, 0]
  have h2 := h ![1, 1, 1]
  have h3 := h ![1, 1, 2]
  simp [Fin.sum_univ_three, List.ofFn_succ] at h1 h2 h3
  norm_num at h1 h2 h3
  linarith

/-! The card's worked numbers for the call with strike $100 (share $100, ±$10 a day, 3 days). -/

-- Fair price: the average of the eight payments 30, 10, 10, 0, 10, 0, 0, 0 is $7.50.
example : ((30 + 10 + 10 + 0 + 10 + 0 + 0 + 0) / 8 : ℚ) = 15 / 2 := by norm_num

-- Values backward: HH (30+10)/2 = 20, HT (10+0)/2 = 5, H (20+5)/2 = 12.50, T (5+0)/2 = 2.50.
example : ((30 + 10) / 2 : ℚ) = 20 ∧ ((10 + 0) / 2 : ℚ) = 5 ∧ ((20 + 5) / 2 : ℚ) = 25 / 2 ∧
    ((5 + 0) / 2 : ℚ) = 5 / 2 ∧ ((25 / 2 + 5 / 2) / 2 : ℚ) = 15 / 2 := by norm_num

-- Stakes: HH (30-10)/(130-110) = 1, HT 10/20 = 1/2, TT 0/20 = 0, H (20-5)/20 = 3/4,
-- T (5-0)/20 = 1/4, start (12.50-2.50)/20 = 1/2.
example : ((30 - 10) / (130 - 110) : ℚ) = 1 ∧ ((10 - 0) / 20 : ℚ) = 1 / 2 ∧ ((0 : ℚ) / 20) = 0 ∧
    ((20 - 5) / 20 : ℚ) = 3 / 4 ∧ ((5 - 0) / 20 : ℚ) = 1 / 4 ∧
    ((25 / 2 - 5 / 2) / 20 : ℚ) = 1 / 2 := by norm_num

-- Cash at the start: 7.50 - 0.50 × 100 = -42.50, borrowed.
example : (15 / 2 - 1 / 2 * 100 : ℚ) = -85 / 2 := by norm_num

-- Replay HTH: 7.50 + 0.50 × 10 - 0.75 × 10 + 0.50 × 10 = 10 = the payment.
example : (15 / 2 + 1 / 2 * 10 - 3 / 4 * 10 + 1 / 2 * 10 : ℚ) = 10 := by norm_num

-- The whole strategy, replayed on all 8 sequences, ends at the call's payment.
-- Stakes: 1/2 on day 1; 3/4 after H, 1/4 after T; 1 after HH, 1/2 after HT or TH, 0 after TT.
example : ∀ a b c : Bool,
    let e : Bool → ℚ := fun t => if t then 1 else -1
    let h2 : Bool → ℚ := fun t => if t then 3 / 4 else 1 / 4
    let h3 : Bool → Bool → ℚ := fun s t => if s && t then 1 else if s || t then 1 / 2 else 0
    max (10 * (e a + e b + e c)) 0 =
      15 / 2 + 1 / 2 * (10 * e a) + h2 a * (10 * e b) + h3 a b * (10 * e c) := by
  intro a b c
  cases a <;> cases b <;> cases c <;> norm_num

-- Lookback ticket: payments 30, 20, 10, 10, 10, 0, 0, 0 average to $10.
example : ((30 + 20 + 10 + 10 + 10 + 0 + 0 + 0) / 8 : ℚ) = 10 := by norm_num

-- The count: 8 payments against 1 + 1 + 2 + 4 = 8 strategy numbers on two outcomes a day;
-- 27 payments against 1 + 1 + 3 + 9 = 14 on three.
example : 2 ^ 3 = 1 + 1 + 2 + 4 ∧ 3 ^ 3 = 27 ∧ 1 + 1 + 3 + 9 = 14 := by norm_num

#print axioms martingale_representation_binary_tree
#print axioms every_payoff_is_a_strategy
#print axioms call_not_copied_with_three_outcomes
