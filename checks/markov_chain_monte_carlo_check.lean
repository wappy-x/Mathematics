-- MCMC: on a finite set of states, a transition rule in detailed balance with a law keeps that law at rest, the Metropolis-Hastings rule with any proposal is in detailed balance with the target whatever its unknown constant, and a Gibbs sweep keeps the joint law at rest.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Real.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum

namespace MarkovChainMonteCarlo

open Finset Matrix

/-! Setting. The states are a finite type `S` (the card's grid of candidate pairs `(a, b)`).
`P x y` is the chance of moving from `x` to `y` in one step; from every state the chain must go
somewhere, so each row of `P` adds to 1. A law on the states is `π : S → ℝ`; one step sends it
to `y ↦ ∑ x, π x * P x y`. -/

/-- Helper: for `a, b ≥ 0`, `b * min 1 (a / b) = min a b`. -/
theorem mul_min_one_div_eq_min (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) :
    b * min 1 (a / b) = min a b := by
  rcases hb.eq_or_lt with h | h
  · subst h; simp [ha]
  · rw [mul_min_of_nonneg _ _ h.le, mul_one, mul_div_cancel₀ _ h.ne', min_comm]

#print axioms mul_min_one_div_eq_min

/-- Helper: if `0 ≤ p ≤ s` then `s * (p / s) = p` (also when `s = 0`). -/
theorem mul_div_self_of_le (s p : ℝ) (hp : 0 ≤ p) (hps : p ≤ s) : s * (p / s) = p := by
  rcases (hp.trans hps).eq_or_lt with h | h
  · subst h; rw [le_antisymm hps hp]; simp
  · exact mul_div_cancel₀ p h.ne'

#print axioms mul_div_self_of_le

/-- **Detailed balance forces the equilibrium.** Let `P` be a transition rule on a finite set of
states whose rows add to 1. If, for every pair of states `x ≠ y`, the flow from `x` to `y` equals
the flow back, `π x * P x y = π y * P y x`, then one step leaves `π` unchanged: for every state
`y`, `∑ x, π x * P x y = π y`, so `π` is stationary. -/
theorem detailed_balance_implies_stationary {S : Type*} [Fintype S] [DecidableEq S]
    (π : S → ℝ) (P : S → S → ℝ) (hrow : ∀ x, ∑ y, P x y = 1)
    (hbal : ∀ x y, x ≠ y → π x * P x y = π y * P y x) :
    ∀ y, ∑ x, π x * P x y = π y := by
  intro y
  calc ∑ x, π x * P x y = ∑ x, π y * P y x := by
        refine Finset.sum_congr rfl fun x _ => ?_
        by_cases h : x = y
        · subst h; rfl
        · exact hbal x y h
    _ = π y := by rw [← Finset.mul_sum, hrow, mul_one]

/-- The Metropolis-Hastings acceptance chance: from `x`, a proposed `y` is accepted with chance
`min 1 r`, where `r = f y * q y x / (f x * q x y)` is the Hastings ratio, `f` is the target up to
an unknown constant and `q x y` is the chance of proposing `y` from `x`. -/
noncomputable def mhAccept {S : Type*} (f : S → ℝ) (q : S → S → ℝ) (x y : S) : ℝ :=
  min 1 (f y * q y x / (f x * q x y))

/-- The Metropolis-Hastings transition rule: a move to `y ≠ x` needs a proposal and an
acceptance, chance `q x y * α x y`; the chain stays at `x` with whatever chance is left. -/
noncomputable def mhKernel {S : Type*} [Fintype S] [DecidableEq S]
    (f : S → ℝ) (q : S → S → ℝ) (x y : S) : ℝ :=
  if y = x then 1 - ∑ z ∈ univ.erase x, q x z * mhAccept f q x z
  else q x y * mhAccept f q x y

/-- **Metropolis-Hastings is in detailed balance with the target, from any proposal rule.** Let
`f ≥ 0` be the target known only up to its constant, `π = f / Z` for any `Z > 0`, and `q ≥ 0` any
proposal rule, symmetric or not. With acceptance `min 1 r`, `r = f y q(y, x) / (f x q(x, y))`, the
flow from `x` to `y` equals the flow back for every pair `x ≠ y`. The constant `Z` is never used
to run the chain. -/
theorem metropolis_hastings_detailed_balance {S : Type*} [Fintype S] [DecidableEq S]
    (f : S → ℝ) (hf : ∀ x, 0 ≤ f x) (q : S → S → ℝ) (hq : ∀ x y, 0 ≤ q x y)
    (Z : ℝ) (hZ : 0 < Z) (x y : S) (hxy : x ≠ y) :
    (f x / Z) * mhKernel f q x y = (f y / Z) * mhKernel f q y x := by
  have h1 := mul_min_one_div_eq_min (f y * q y x) (f x * q x y)
    (mul_nonneg (hf _) (hq _ _)) (mul_nonneg (hf _) (hq _ _))
  have h2 := mul_min_one_div_eq_min (f x * q x y) (f y * q y x)
    (mul_nonneg (hf _) (hq _ _)) (mul_nonneg (hf _) (hq _ _))
  simp only [mhKernel, mhAccept, if_neg (Ne.symm hxy), if_neg hxy]
  calc f x / Z * (q x y * min 1 (f y * q y x / (f x * q x y)))
      = (f x * q x y * min 1 (f y * q y x / (f x * q x y))) / Z := by ring
    _ = (f y * q y x * min 1 (f x * q x y / (f y * q y x))) / Z := by rw [h1, h2, min_comm]
    _ = _ := by ring

/-- Gibbs half-step "redraw a with b held": from `(a, b)` move to `(a', b)` with chance
`π (a', b) / ∑ a'', π (a'', b)`, the law of `a` given `b`. -/
noncomputable def redrawFirst {A B : Type*} [Fintype A] [DecidableEq B]
    (π : A × B → ℝ) : Matrix (A × B) (A × B) ℝ :=
  fun x y => if y.2 = x.2 then π y / ∑ a, π (a, x.2) else 0

/-- Gibbs half-step "redraw b with a held": from `(a, b)` move to `(a, b')` with chance
`π (a, b') / ∑ b'', π (a, b'')`, the law of `b` given `a`. -/
noncomputable def redrawSecond {A B : Type*} [Fintype B] [DecidableEq A]
    (π : A × B → ℝ) : Matrix (A × B) (A × B) ℝ :=
  fun x y => if y.1 = x.1 then π y / ∑ b, π (x.1, b) else 0

/-- **Gibbs sampling keeps the joint law.** For any law `π ≥ 0` on a finite grid of pairs
`(a, b)`, redrawing `a` from its law given `b` leaves `π` unchanged, so does redrawing `b` from its
law given `a`, and so does a whole sweep (one, then the other). -/
theorem gibbs_sweep_keeps_law {A B : Type*} [Fintype A] [Fintype B]
    [DecidableEq A] [DecidableEq B] (π : A × B → ℝ) (hπ : ∀ x, 0 ≤ π x) :
    π ᵥ* redrawFirst π = π ∧ π ᵥ* redrawSecond π = π ∧
      π ᵥ* (redrawFirst π * redrawSecond π) = π := by
  have hF : π ᵥ* redrawFirst π = π := by
    funext ⟨a0, b0⟩
    simp only [vecMul, dotProduct, redrawFirst, Fintype.sum_prod_type, mul_ite, mul_zero,
      Finset.sum_ite_eq, Finset.mem_univ, if_true]
    rw [← Finset.sum_mul]
    exact mul_div_self_of_le _ _ (hπ _)
      (Finset.single_le_sum (f := fun a => π (a, b0)) (fun a _ => hπ _) (Finset.mem_univ a0))
  have hS : π ᵥ* redrawSecond π = π := by
    funext ⟨a0, b0⟩
    simp only [vecMul, dotProduct, redrawSecond, Fintype.sum_prod_type_right, mul_ite, mul_zero,
      Finset.sum_ite_eq, Finset.mem_univ, if_true]
    rw [← Finset.sum_mul]
    exact mul_div_self_of_le _ _ (hπ _)
      (Finset.single_le_sum (f := fun b => π (a0, b)) (fun b _ => hπ _) (Finset.mem_univ b0))
  refine ⟨hF, hS, ?_⟩
  rw [← Matrix.vecMul_vecMul, hF, hS]

/-! The card's worked numbers, as exact fractions. Weeks 1 to 5; heights 2.1, 2.9, 4.2, 4.8,
6.0 cm (21/10, 29/10, 42/10, 48/10, 6); ruler spread σ = 1/2, so σ² = 1/4. -/

-- Sums of weeks and squared weeks: 15 and 55; the spread of the weeks D = 5 × 55 − 15² = 50.
example : (∑ w ∈ Icc (1 : ℕ) 5, w) = 15 ∧ (∑ w ∈ Icc 1 5, w ^ 2) = 55 ∧ 5 * 55 - 15 * 15 = 50 := by
  decide
-- Sum of heights 20.0 and of week times height 69.7.
example : (21 : ℚ) / 10 + 29 / 10 + 42 / 10 + 48 / 10 + 6 = 20 ∧
    (1 : ℚ) * (21 / 10) + 2 * (29 / 10) + 3 * (42 / 10) + 4 * (48 / 10) + 5 * 6 = 697 / 10 := by
  norm_num
-- Posterior means: growth b = (5 × 69.7 − 15 × 20.0) / 50 = 0.97, start a = (20.0 − 15 × 0.97)/5
-- = 1.09.
example : ((5 : ℚ) * (697 / 10) - 15 * 20) / 50 = 97 / 100 ∧
    ((20 : ℚ) - 15 * (97 / 100)) / 5 = 109 / 100 := by norm_num
-- Variances of a and b and their covariance: 0.2750, 0.0250, −0.0750.
example : (1 : ℚ) / 4 * 55 / 50 = 11 / 40 ∧ (1 : ℚ) / 4 * 5 / 50 = 1 / 40 ∧
    -((1 : ℚ) / 4 * 15 / 50) = -3 / 40 := by norm_num
-- The squared correlation is 9/11, the same as the forgetting rate 15 × 15 / (5 × 55).
example : (-(3 : ℚ) / 40) ^ 2 / (11 / 40 * (1 / 40)) = 9 / 11 ∧
    (15 : ℚ) * 15 / (5 * 55) = 9 / 11 := by norm_num
-- The inflation factor τ = (1 + 9/11) / (1 − 9/11) = 10, so 100,000 sweeps are worth 10,000
-- independent draws of b.
example : (1 + (9 : ℚ) / 11) / (1 - 9 / 11) = 10 ∧ (100000 : ℚ) / 10 = 10000 := by norm_num
-- First sweep from b = 0: a averages (20 − 15 × 0)/5 = 4, then b averages (69.7 − 15 × 4)/55,
-- which is 0.97 × (1 − 9/11).
example : ((20 : ℚ) - 15 * 0) / 5 = 4 ∧ ((697 : ℚ) / 10 - 15 * 4) / 55 = 97 / 550 ∧
    (97 : ℚ) / 100 * (1 - 9 / 11) = 97 / 550 := by norm_num
-- 0.97 is the fixed point of the b-chain's average: (69.7 − 15 × 20.0/5)/55 + (9/11) × 0.97 = 0.97.
example : ((697 : ℚ) / 10 - 15 * 20 / 5) / 55 + 9 / 11 * (97 / 100) = 97 / 100 := by norm_num
-- The b-chain's equilibrium variance σ² / (S_ww (1 − φ)) equals the posterior variance 1/40.
example : (1 : ℚ) / 4 / (55 * (1 - 9 / 11)) = 1 / 40 := by norm_num

#print axioms detailed_balance_implies_stationary
#print axioms metropolis_hastings_detailed_balance
#print axioms gibbs_sweep_keeps_law

end MarkovChainMonteCarlo
