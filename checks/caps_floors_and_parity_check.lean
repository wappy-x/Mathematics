-- Caps and floors: in any linear pricing model where bonds trade at the discount factors and a one-quarter deposit earns the fixing rate, a cap minus a floor at the same strike equals the payer swap's value from discount factors alone.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Module.Pi
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Algebra.Order.Group.MinMax
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

/-- Cap-floor parity, in every model. A model is any set of states `Ω` and, for each
payment date `j`, a linear price `V j` for a payoff paid at date `j` (linearity is the
no-arbitrage sum rule: a bundle of separate payments costs the sum of their prices).
Quarter `i` (for `i = 1, …, n`) fixes at rate `L i` on its reset date `T_i` and pays at
`T_{i+1}`; the cap pays `τ · max(L_i − K, 0)` and the floor pays `τ · max(K − L_i, 0)`.
If a bond paying 1 at date `j` costs `D j`, and a dollar deposited for one quarter at
`T_i` returns `1 + τ · L_i` at `T_{i+1}`, then
Cap − Floor = D₁ − D_{n+1} − K · A, where A = Σ τ · D_{i+1} is the annuity:
the value of the payer swap that receives the floating rate and pays the strike. -/
theorem cap_minus_floor_eq_payer_swap {Ω : Type*} (n : ℕ) (τ K : ℝ)
    (L : ℕ → Ω → ℝ) (D : ℕ → ℝ) (V : ℕ → (Ω → ℝ) →ₗ[ℝ] ℝ)
    (hbond : ∀ j ∈ Icc 1 (n + 1), V j (fun _ => 1) = D j)
    (hdeposit : ∀ i ∈ Icc 1 n, V (i + 1) (fun ω => 1 + τ * L i ω) = D i) :
    (∑ i ∈ Icc 1 n, V (i + 1) (fun ω => τ * max (L i ω - K) 0))
      - (∑ i ∈ Icc 1 n, V (i + 1) (fun ω => τ * max (K - L i ω) 0))
      = D 1 - D (n + 1) - K * ∑ i ∈ Icc 1 n, τ * D (i + 1) := by
  have hpay : ∀ a b : ℝ, max (a - b) 0 - max (b - a) 0 = a - b := by
    intro a b
    rcases le_total a b with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  have key : ∀ i ∈ Icc 1 n, V (i + 1) (fun ω => τ * max (L i ω - K) 0)
      - V (i + 1) (fun ω => τ * max (K - L i ω) 0) = D i - D (i + 1) - K * (τ * D (i + 1)) := by
    intro i hi
    have hi' : i + 1 ∈ Icc 1 (n + 1) := by
      simp only [mem_Icc] at hi ⊢; omega
    rw [← map_sub]
    have hfun : ((fun ω => τ * max (L i ω - K) 0) - (fun ω => τ * max (K - L i ω) 0))
        = (fun ω => 1 + τ * L i ω) - (1 + τ * K) • (fun _ : Ω => (1 : ℝ)) := by
      funext ω
      simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
      rw [← mul_sub, hpay]; ring
    rw [hfun, map_sub, map_smul, hdeposit i hi, hbond (i + 1) hi', smul_eq_mul]
    ring
  have tele : ∀ m : ℕ, ∑ i ∈ Icc 1 m, (D i - D (i + 1)) = D 1 - D (m + 1) := by
    intro m
    induction m with
    | zero => simp
    | succ k ih =>
      rw [sum_Icc_succ_top (by omega), ih]; ring
  rw [← sum_sub_distrib, sum_congr rfl key, sum_sub_distrib, ← Finset.mul_sum, tele]

/-- Step 0: for any fixing `L` and strike `K`, one quarter's caplet payoff minus its
floorlet payoff is the swap payoff: max(L − K, 0) − max(K − L, 0) = L − K.
No probabilities enter. -/
theorem caplet_sub_floorlet_payoff (L K : ℝ) :
    max (L - K) 0 - max (K - L) 0 = L - K := by
  rcases le_total L K with h | h
  · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
  · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring

/-- Step 6, the cap as insurance: a borrower who pays the fixing `L` and receives the
caplet payoff max(L − K, 0) pays, net, the smaller of `L` and the strike `K`. -/
theorem capped_borrowing_rate (L K : ℝ) :
    L - max (L - K) 0 = min L K := by
  rcases le_total L K with h | h
  · rw [max_eq_right (by linarith), min_eq_left h]; ring
  · rw [max_eq_left (by linarith), min_eq_right h]; ring

-- The chart: one quarter on $10,000,000 at strike 5 percent, rates as fractions.
-- A fixing of 5.5 percent: the caplet pays $12,500, the floorlet pays nothing.
example : (10000000 : ℚ) * (1 / 4) * max (55 / 1000 - 5 / 100) 0 = 12500 := by norm_num
example : (10000000 : ℚ) * (1 / 4) * max (5 / 100 - 55 / 1000) 0 = 0 := by norm_num
-- A fixing of 6 percent: the caplet pays $25,000.
example : (10000000 : ℚ) * (1 / 4) * max (6 / 100 - 5 / 100) 0 = 25000 := by norm_num
-- A fixing of 4 percent: the floorlet pays $25,000, so caplet minus floorlet is −$25,000.
example : (10000000 : ℚ) * (1 / 4) * max (5 / 100 - 4 / 100) 0 = 25000 := by norm_num
example : (10000000 : ℚ) * (1 / 4) * (max (4 / 100 - 5 / 100) 0 - max (5 / 100 - 4 / 100) 0)
    = -25000 := by norm_num
-- A fixing of 7 percent: the caplet pays $50,000.
example : (10000000 : ℚ) * (1 / 4) * max (7 / 100 - 5 / 100) 0 = 50000 := by norm_num

#print axioms cap_minus_floor_eq_payer_swap
#print axioms caplet_sub_floorlet_payoff
#print axioms capped_borrowing_rate
