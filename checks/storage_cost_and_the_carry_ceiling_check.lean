-- Storage and the carry ceiling: if the cash-and-carry trade offers no sure profit then a forward on a stored commodity is at most spot plus every storage bill, each financed at r until delivery; any positive forward up to that ceiling leaves no sure trade to the seller or to a buyer without grain, and storage charged in kind at rate u gives the same ceiling S e^((r+u)T).
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds

open Real Filter Topology

/-- The carry ceiling. Spot is `S` per unit today, money is borrowed at the continuously
compounded rate `r`, delivery is in `T` years, and the warehouse bills `U i` at the known times
`t i`, each between 0 and `T`. `ST` is the commodity's unknown price on delivery day.

Cash-and-carry: sell one forward at `F`, borrow `S` and buy one unit, and at each `t i` borrow
`U i` and pay the warehouse, so net cash is zero at every date before `T`. At `T` sell the stored
unit for `ST`, pay the forward's buyer `ST - F`, and repay the loans `S e^(rT)` and
`U i e^(r (T - t i))`.

If this position does not pay a positive amount whatever the delivery-day price turns out to be
(no riskless profit), then `F ≤ S e^(rT) + ∑ U i e^(r (T - t i))`. With one bill `U` paid today
this is `F ≤ (S + U) e^(rT)`. -/
theorem forward_le_carry_ceiling {k : ℕ} (S r T F : ℝ) (U t : Fin k → ℝ)
    (ht : ∀ i, 0 ≤ t i ∧ t i ≤ T)
    (no_carry_arb : ¬ ∀ ST : ℝ, 0 < ST →
      0 < ST - (ST - F) - (S * exp (r * T) + ∑ i, U i * exp (r * (T - t i)))) :
    F ≤ S * exp (r * T) + ∑ i, U i * exp (r * (T - t i)) := by
  by_contra h
  have h := not_le.mp h
  apply no_carry_arb
  intro ST _
  linarith

/-- Storage sets no floor. Take one storage bill `U ≥ 0` paid today, spot `S > 0`, rate `r` and
`T` years, and any forward price `F` with `0 < F ≤ (S + U) e^(rT)`. Then neither trade open to
someone without grain is a sure profit when the delivery-day price `ST` can be any positive
number: the cash-and-carry seller's result `ST - (ST - F) - (S + U) e^(rT)` is not positive for
every `ST`, and the buyer of the forward, who ends with `ST - F`, is not positive for every
`ST` either. -/
theorem no_floor_below_carry_ceiling (S U r T F : ℝ) (hS : 0 < S) (hU : 0 ≤ U)
    (hF : 0 < F) (hFle : F ≤ (S + U) * exp (r * T)) :
    (¬ ∀ ST : ℝ, 0 < ST → 0 < ST - (ST - F) - (S + U) * exp (r * T)) ∧
    (¬ ∀ ST : ℝ, 0 < ST → 0 < ST - F) := by
  refine ⟨fun h => ?_, fun h => ?_⟩
  · have := h 1 one_pos
    linarith
  · have := h (F / 2) (by positivity)
    linarith

/-- Storage as a rate gives the same ceiling. A warehouse that keeps the fraction `u T / n` of
the pile in each of `n` equal spells leaves `(1 - u T / n)^n` of it, which tends to `e^(-uT)` as
`n` grows; so `e^(uT)` units must be bought, and financing them costs `S e^(uT) e^(rT)`, which is
`S e^((r + u) T)`. When the rate matches a bill `U` paid today on spot `S > 0`, that is
`u = ln((S + U) / S)`, the one-year ceilings agree: `S e^(r + u) = (S + U) e^r`. -/
theorem storage_rate_gives_same_ceiling (S U r u T : ℝ) :
    Tendsto (fun n : ℕ => (1 - u * T / n) ^ n) atTop (𝓝 (exp (-(u * T)))) ∧
    S * exp (u * T) * exp (r * T) = S * exp ((r + u) * T) ∧
    (0 < S → 0 < S + U → u = log ((S + U) / S) →
      S * exp ((r + u) * 1) = (S + U) * exp (r * 1)) := by
  refine ⟨?_, ?_, ?_⟩
  · have := Real.tendsto_one_add_div_pow_exp (-(u * T))
    refine this.congr (fun n => ?_)
    congr 1
    ring
  · rw [mul_assoc, ← Real.exp_add]
    congr 2
    ring
  · intro hS hSU hu
    rw [hu, mul_one, mul_one, Real.exp_add, Real.exp_log (div_pos hSU hS)]
    field_simp

-- Cash needed today: 6.00 for the bushel plus 0.30 for the warehouse is 6.30.
example : (6 : ℚ) + 3 / 10 = 63 / 10 := by norm_num

-- One bill paid today: S e^(rT) + U e^(r (T - 0)) is (S + U) e^(rT) for the wheat numbers.
example : (6 : ℝ) * exp (5 / 100 * 1) + 3 / 10 * exp (5 / 100 * (1 - 0)) =
    (6 + 3 / 10) * exp (5 / 100 * 1) := by
  norm_num; ring

-- The carry profit at a 6.80 forward is the same whatever wheat costs on delivery day.
example (ST : ℝ) : ST - (ST - 68 / 10) - (6 + 3 / 10) * exp (5 / 100 * 1) =
    68 / 10 - 63 / 10 * exp (5 / 100) := by
  norm_num

-- Wrong answer "simple interest": 6.30 x 1.05 = 6.615.
example : (63 / 10 : ℚ) * (1 + 5 / 100 * 1) = 6615 / 1000 := by norm_num

-- Pro rata storage on the chart: three months of a 0.30 yearly bill is 0.075.
example : (3 / 10 : ℚ) * 3 / 12 = 75 / 1000 := by norm_num

#print axioms forward_le_carry_ceiling
#print axioms no_floor_below_carry_ceiling
#print axioms storage_rate_gives_same_ceiling
