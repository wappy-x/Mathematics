-- Inflation swaps: in any finite world of states with positive state prices, a zero-coupon inflation swap is worth the notional times the real-zero price less the fixed factor times the nominal-zero price, so exactly one fixed rate above minus 100 percent makes it worth zero, the T-th root of the bond price ratio less one, which in yields is Fisher's ratio.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Finset

/-! The states of the world at maturity `T` (in years) are the finite set `s`. State `i` has a
state price `ψ i > 0`, today's cost of one dollar paid only in that state, and an index ratio
`J i > 0`, the index at maturity over the index at the start. The nominal zero pays one dollar in
every state, so its price is `D(T) = ∑ ψ i`; the real zero pays `J i` dollars, so its price is
`R(T) = ∑ ψ i * J i`. The swap on notional `N` with fixed rate `K` pays the inflation receiver
`N * (J i - (1 + K)^T)` in state `i`, and its price is the sum of state price times payment. -/

/-- The card's main claim. In any arbitrage-free world (finitely many states, positive state
prices, positive index ratios), a zero-coupon inflation swap is worth
`V = N * (R(T) - (1 + K)^T * D(T))` for every fixed rate `K`, whatever the state prices and index
ratios are otherwise: only the two bond prices enter. For a positive notional and term, exactly
one fixed rate above minus 100 percent makes a new swap worth zero, the par rate
`k_T = (R(T) / D(T))^(1/T) - 1`. -/
theorem swap_rate_from_bond_prices {ι : Type*} (s : Finset ι) (hs : s.Nonempty)
    (ψ J : ι → ℝ) (hψ : ∀ i ∈ s, 0 < ψ i) (hJ : ∀ i ∈ s, 0 < J i)
    (N T : ℝ) (hN : 0 < N) (hT : 0 < T) :
    (∀ K : ℝ, ∑ i ∈ s, ψ i * (N * (J i - (1 + K) ^ T))
        = N * (∑ i ∈ s, ψ i * J i - (1 + K) ^ T * ∑ i ∈ s, ψ i)) ∧
    (∀ K : ℝ, -1 < K →
      (∑ i ∈ s, ψ i * (N * (J i - (1 + K) ^ T)) = 0 ↔
        K = ((∑ i ∈ s, ψ i * J i) / ∑ i ∈ s, ψ i) ^ (1 / T) - 1)) ∧
    -1 < ((∑ i ∈ s, ψ i * J i) / ∑ i ∈ s, ψ i) ^ (1 / T) - 1 := by
  have hD : 0 < ∑ i ∈ s, ψ i := Finset.sum_pos hψ hs
  have hR : 0 < ∑ i ∈ s, ψ i * J i :=
    Finset.sum_pos (fun i hi => mul_pos (hψ i hi) (hJ i hi)) hs
  have hval : ∀ K : ℝ, ∑ i ∈ s, ψ i * (N * (J i - (1 + K) ^ T))
      = N * (∑ i ∈ s, ψ i * J i - (1 + K) ^ T * ∑ i ∈ s, ψ i) := by
    intro K
    rw [mul_sub, Finset.mul_sum, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    ring
  have hA : 0 < (∑ i ∈ s, ψ i * J i) / ∑ i ∈ s, ψ i := div_pos hR hD
  refine ⟨hval, ?_, ?_⟩
  · intro K hK
    have hK1 : 0 < 1 + K := by linarith
    have hTne : T ≠ 0 := ne_of_gt hT
    rw [hval K]
    constructor
    · intro h
      have h1 : (1 + K) ^ T = (∑ i ∈ s, ψ i * J i) / ∑ i ∈ s, ψ i := by
        have h2 : ∑ i ∈ s, ψ i * J i - (1 + K) ^ T * ∑ i ∈ s, ψ i = 0 := by
          rcases mul_eq_zero.mp h with h3 | h3
          · exact absurd h3 (ne_of_gt hN)
          · exact h3
        field_simp
        linarith
      rw [← h1, one_div, Real.rpow_rpow_inv hK1.le hTne]
      ring
    · intro h
      have h1 : 1 + K = ((∑ i ∈ s, ψ i * J i) / ∑ i ∈ s, ψ i) ^ (1 / T) := by linarith
      have h2 : (1 + K) ^ T = (∑ i ∈ s, ψ i * J i) / ∑ i ∈ s, ψ i := by
        rw [h1, one_div, Real.rpow_inv_rpow hA.le hTne]
      rw [h2, div_mul_cancel₀ _ (ne_of_gt hD)]
      ring
  · have := Real.rpow_pos_of_pos hA (1 / T)
    linarith

/-- A running (seasoned) swap keeps its old base and its old term. If the index has already
risen by the ratio `J_t` and the swap was struck at `K` for an original term of `M` years, then in
state `i` it pays `N * (J_t * J i - (1 + K)^M)`, where `J i` is the index's rise from today. Its
value today is `N * (J_t * R(T) - (1 + K)^M * D(T))`, again using only the two bond prices. -/
theorem seasoned_swap_value {ι : Type*} (s : Finset ι) (ψ J : ι → ℝ) (N K M Jt : ℝ) :
    ∑ i ∈ s, ψ i * (N * (Jt * J i - (1 + K) ^ M))
      = N * (Jt * ∑ i ∈ s, ψ i * J i - (1 + K) ^ M * ∑ i ∈ s, ψ i) := by
  rw [Finset.mul_sum, Finset.mul_sum, mul_sub, Finset.mul_sum, Finset.mul_sum,
    ← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  ring

/-- In yields the par rate is Fisher's ratio. If the nominal zero is priced at the nominal
yield, `D(T) = (1 + n)^(-T)`, and the real zero at the real yield, `R(T) = (1 + y)^(-T)`, with
both yields above minus 100 percent and `T > 0`, then the par rate satisfies
`1 + k_T = (1 + n) / (1 + y)`. -/
theorem par_rate_eq_fisher_ratio (n y T : ℝ) (hn : -1 < n) (hy : -1 < y) (hT : 0 < T) :
    1 + (((1 + y) ^ (-T) / (1 + n) ^ (-T)) ^ (1 / T) - 1) = (1 + n) / (1 + y) := by
  have hn1 : 0 < 1 + n := by linarith
  have hy1 : 0 < 1 + y := by linarith
  have hTne : T ≠ 0 := ne_of_gt hT
  rw [← Real.div_rpow hy1.le hn1.le, ← Real.rpow_mul (div_pos hy1 hn1).le]
  have : -T * (1 / T) = -1 := by field_simp
  rw [this, Real.rpow_neg_one, inv_div]
  ring

/-! The card's worked numbers, as exact fractions. -/

-- Fisher's ratio at 5 years: a nominal yield of 3.626 percent over a real yield of 1.00 percent
-- gives a par rate of exactly 2.6 percent.
example : (103626 / 100000 : ℚ) / (101 / 100) - 1 = 26 / 1000 := by norm_num

-- The index forward A(5) = R(5) / D(5) = 1.03626^5 / 1.01^5 equals 1.026^5.
example : ((101 / 100 : ℚ) ^ 5)⁻¹ / ((103626 / 100000 : ℚ) ^ 5)⁻¹ = (1026 / 1000 : ℚ) ^ 5 := by
  norm_num

-- At an index ratio of 1.15 the receiver gets 1,000,000 (1.15 - 1.026^5): 13,061.94 dollars.
example : (1306194 / 100 : ℚ) < 1000000 * (115 / 100 - (1026 / 1000) ^ 5) ∧
    1000000 * (115 / 100 - (1026 / 1000 : ℚ) ^ 5) < 1306195 / 100 := by
  norm_num

-- The mistake: a simple-interest fixed leg, 1 + 5 * 0.026, turns the payout into 20,000 dollars.
example : (1000000 : ℚ) * (115 / 100 - (1 + 5 * (26 / 1000))) = 20000 := by norm_num

-- The older swap: struck at 2.3 percent for 7 years, index up 6 percent, 5 years left, is worth
-- 1,000,000 (1.06 R(5) - 1.023^7 D(5)) = 27,289.86 dollars to the receiver.
example :
    let D5 : ℚ := ((103626 / 100000) ^ 5)⁻¹
    let R5 : ℚ := ((101 / 100) ^ 5)⁻¹
    (2728986 / 100 : ℚ) < 1000000 * (106 / 100 * R5 - (1023 / 1000) ^ 7 * D5) ∧
      1000000 * (106 / 100 * R5 - (1023 / 1000) ^ 7 * D5) < 2728987 / 100 := by
  norm_num

-- The hedged linker, year 1: notional 10,000 times the index forward 1.0302 / 1.01 locks in
-- exactly 10,200 dollars.
example : (10000 : ℚ) * ((10302 / 10000) / (101 / 100)) = 10200 := by norm_num

#print axioms swap_rate_from_bond_prices
#print axioms seasoned_swap_value
#print axioms par_rate_eq_fisher_ratio
