-- The Hull-White tree: rolling a payoff back through any trinomial lattice gives the sum of state price times payoff, each layer's shift is fixed uniquely by the curve, and the branch weights match one step's mean and variance and stay positive at the turned edge.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Int.Interval

open Finset

namespace HullWhiteTree

/-- State prices, built forward one layer at a time. `S i` is the set of rungs on layer `i`,
`p i j k` the weight on the branch from rung `j` of layer `i` to rung `k` of layer `i+1`
(zero if there is no such branch), and the node rate is `α i + j * Δx`.
`Q 0` is `1` at the root rung `0`; `Q (i+1) k = ∑ j, Q i j * p(j → k) * exp(-(α i + j Δx) Δt)`. -/
noncomputable def stateQ (S : ℕ → Finset ℤ) (p : ℕ → ℤ → ℤ → ℝ) (α : ℕ → ℝ) (Δx Δt : ℝ) :
    ℕ → ℤ → ℝ
  | 0, j => if j = 0 then 1 else 0
  | i + 1, k => ∑ j ∈ S i, stateQ S p α Δx Δt i j * p i j k * Real.exp (-((α i + j * Δx) * Δt))

/-- One step of backward induction from layer `i+1` to layer `i`: the discounted average of the
children, discounted at the node's own rate `α i + j * Δx`. -/
noncomputable def backStep (S : ℕ → Finset ℤ) (p : ℕ → ℤ → ℤ → ℝ) (α : ℕ → ℝ) (Δx Δt : ℝ)
    (i : ℕ) (v : ℤ → ℝ) : ℤ → ℝ :=
  fun j => Real.exp (-((α i + j * Δx) * Δt)) * ∑ k ∈ S (i + 1), p i j k * v k

/-- Roll a payoff `H` paid at layer `m` all the way back to layer `0`. -/
noncomputable def rollback (S : ℕ → Finset ℤ) (p : ℕ → ℤ → ℤ → ℝ) (α : ℕ → ℝ) (Δx Δt : ℝ) :
    ℕ → (ℤ → ℝ) → ℤ → ℝ
  | 0, H => H
  | m + 1, H => rollback S p α Δx Δt m (backStep S p α Δx Δt m H)

/-- The tree's prices agree with its fit. On a trinomial lattice that starts from the single
root rung `0`, rolling any payoff `H` paid at layer `m` back to the root gives
`∑ k, Q m k * H k`: the sum over that layer's nodes of state price times payoff.
In particular, with `H = 1` the root value is the layer's state-price sum, so a tree fitted to the
curve reprices every zero-coupon bond on the grid by rollback as well. -/
theorem rollback_eq_state_price_sum (S : ℕ → Finset ℤ) (p : ℕ → ℤ → ℤ → ℝ) (α : ℕ → ℝ)
    (Δx Δt : ℝ) (hroot : S 0 = {0}) (m : ℕ) (H : ℤ → ℝ) :
    rollback S p α Δx Δt m H 0 = ∑ k ∈ S m, stateQ S p α Δx Δt m k * H k := by
  induction m generalizing H with
  | zero =>
    rw [hroot, Finset.sum_singleton]
    simp [rollback, stateQ]
  | succ n ih =>
    show rollback S p α Δx Δt n (backStep S p α Δx Δt n H) 0 = _
    rw [ih]
    simp only [backStep, stateQ, Finset.mul_sum, Finset.sum_mul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun j _ => ?_
    ring

/-- Fitting one layer. If the weights out of every parent add to one, the curve's next bond price
`D` is positive, `Δt > 0`, and the sum `∑ j, Q j * exp(-j Δx Δt)` is positive, then the next
layer's state prices add up to `D` exactly when the shift is
`α = (1/Δt) * ln((∑ j, Q j * exp(-j Δx Δt)) / D)`: the shift always exists and is unique. -/
theorem layer_shift_fits_curve_iff (Si Snext : Finset ℤ) (Q : ℤ → ℝ) (p : ℤ → ℤ → ℝ)
    (Δx Δt D : ℝ) (hΔt : 0 < Δt) (hD : 0 < D)
    (hp : ∀ j ∈ Si, ∑ k ∈ Snext, p j k = 1)
    (hsum : 0 < ∑ j ∈ Si, Q j * Real.exp (-((j : ℝ) * Δx * Δt))) (α : ℝ) :
    ∑ k ∈ Snext, ∑ j ∈ Si, Q j * p j k * Real.exp (-((α + j * Δx) * Δt)) = D ↔
      α = (1 / Δt) * Real.log ((∑ j ∈ Si, Q j * Real.exp (-((j : ℝ) * Δx * Δt))) / D) := by
  set A := ∑ j ∈ Si, Q j * Real.exp (-((j : ℝ) * Δx * Δt)) with hA
  have hL : ∑ k ∈ Snext, ∑ j ∈ Si, Q j * p j k * Real.exp (-((α + j * Δx) * Δt))
      = Real.exp (-(α * Δt)) * A := by
    rw [Finset.sum_comm, hA, Finset.mul_sum]
    refine Finset.sum_congr rfl fun j hj => ?_
    have h1 : ∀ k, Q j * p j k * Real.exp (-((α + j * Δx) * Δt))
        = (Real.exp (-(α * Δt)) * (Q j * Real.exp (-((j : ℝ) * Δx * Δt)))) * p j k := by
      intro k
      have : -((α + j * Δx) * Δt) = -(α * Δt) + -((j : ℝ) * Δx * Δt) := by ring
      rw [this, Real.exp_add]; ring
    simp only [h1]
    rw [← Finset.mul_sum, hp j hj, mul_one]
  rw [hL]
  have hE : 0 < Real.exp (-(α * Δt)) := Real.exp_pos _
  have hAD : 0 < A / D := div_pos hsum hD
  constructor
  · intro h
    have h2 : A / D = Real.exp (α * Δt) := by
      rw [← h, Real.exp_neg]; field_simp
    rw [h2, Real.log_exp]; field_simp
  · intro h
    have h2 : α * Δt = Real.log (A / D) := by rw [h]; field_simp
    rw [h2, Real.exp_neg, Real.exp_log hAD]; field_simp

/-- The branch weights. Write `m = j * M` for the average move from rung `j`, in rungs.
Middle rungs (moves +1, 0, -1) with `p_u = 1/6 + (m² + m)/2`, `p_m = 2/3 - m²`,
`p_d = 1/6 + (m² - m)/2`, and the top edge (moves 0, -1, -2) with weights
`7/6 + (m² + 3m)/2`, `-1/3 - m² - 2m`, `1/6 + (m² + m)/2`, both add to one, have average move `m`
and average squared move `1/3 + m²`. The middle rung's centre weight is positive exactly when
`|m| < √(2/3)`. At the top edge, with `y = -m`, the middle weight is positive exactly when
`1 - √(2/3) < y < 1 + √(2/3)`, and on that range all three edge weights are positive. -/
theorem branch_weights_match_step_and_edge_weights_positive (m : ℝ) :
    -- middle rung: sum, mean, second moment
    ((1/6 + (m^2 + m)/2) + (2/3 - m^2) + (1/6 + (m^2 - m)/2) = 1 ∧
      (1/6 + (m^2 + m)/2) * 1 + (2/3 - m^2) * 0 + (1/6 + (m^2 - m)/2) * (-1) = m ∧
      (1/6 + (m^2 + m)/2) * 1 + (2/3 - m^2) * 0 + (1/6 + (m^2 - m)/2) * 1 = 1/3 + m^2) ∧
    -- top edge: sum, mean, second moment
    ((7/6 + (m^2 + 3*m)/2) + (-1/3 - m^2 - 2*m) + (1/6 + (m^2 + m)/2) = 1 ∧
      (7/6 + (m^2 + 3*m)/2) * 0 + (-1/3 - m^2 - 2*m) * (-1) + (1/6 + (m^2 + m)/2) * (-2) = m ∧
      (7/6 + (m^2 + 3*m)/2) * 0 + (-1/3 - m^2 - 2*m) * 1 + (1/6 + (m^2 + m)/2) * 4
        = 1/3 + m^2) ∧
    -- the middle rung's centre weight turns negative past √(2/3)
    (0 < 2/3 - m^2 ↔ |m| < Real.sqrt (2/3)) ∧
    -- the top edge's middle weight is positive exactly on (1 - √(2/3), 1 + √(2/3))
    (0 < -1/3 - m^2 - 2*m ↔ 1 - Real.sqrt (2/3) < -m ∧ -m < 1 + Real.sqrt (2/3)) ∧
    -- and on that range all three edge weights are positive
    (1 - Real.sqrt (2/3) < -m → -m < 1 + Real.sqrt (2/3) →
      0 < 7/6 + (m^2 + 3*m)/2 ∧ 0 < -1/3 - m^2 - 2*m ∧ 0 < 1/6 + (m^2 + m)/2) := by
  have hs0 : 0 ≤ Real.sqrt (2/3) := Real.sqrt_nonneg _
  have hs2 : Real.sqrt (2/3) ^ 2 = 2/3 := Real.sq_sqrt (by norm_num)
  have hmid : 0 < -1/3 - m^2 - 2*m ↔ 1 - Real.sqrt (2/3) < -m ∧ -m < 1 + Real.sqrt (2/3) := by
    constructor
    · intro h
      have hlt : (m + 1) ^ 2 < Real.sqrt (2/3) ^ 2 := by nlinarith
      have := abs_lt_of_sq_lt_sq' hlt hs0
      constructor <;> linarith [this.1, this.2]
    · rintro ⟨h1, h2⟩
      nlinarith [mul_pos (by linarith : (0:ℝ) < Real.sqrt (2/3) - (m + 1))
        (by linarith : (0:ℝ) < Real.sqrt (2/3) + (m + 1))]
  refine ⟨⟨by ring, by ring, by ring⟩, ⟨by ring, by ring, by ring⟩, ?_, hmid, ?_⟩
  · rw [Real.lt_sqrt (abs_nonneg m), sq_abs]
    constructor <;> intro h <;> linarith
  · intro h1 h2
    refine ⟨by nlinarith [sq_nonneg (m + 3/2)], hmid.2 ⟨h1, h2⟩, by nlinarith [sq_nonneg (m + 1/2)]⟩

/-- Card: the step length is 6 years ÷ 60 steps = 0.1 year. -/
example : (6 : ℚ) / 60 = 1 / 10 := by norm_num

/-- Card: the weights at rung 0 are 1/6, 2/3, 1/6 (here `m = 0 * M = 0`). -/
example : ((1 : ℚ)/6 + (0^2 + 0)/2, (2 : ℚ)/3 - 0^2, (1 : ℚ)/6 + (0^2 - 0)/2) = (1/6, 2/3, 1/6) := by
  norm_num

/-- Card: rungs -7 to +7 give 15 nodes on each full layer. -/
example : (Finset.Icc (-7 : ℤ) 7).card = 15 := by decide

#print axioms rollback_eq_state_price_sum
#print axioms layer_shift_fits_curve_iff
#print axioms branch_weights_match_step_and_edge_weights_positive

end HullWhiteTree
