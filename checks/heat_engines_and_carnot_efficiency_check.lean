-- Heat engines: from the energy balance and the entropy balance over one cycle, an engine's efficiency is at most one minus cold over hot, with equality exactly when no entropy is created, and a heat pump's score is at most hot over the gap.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- Carnot's engine limit. Two reservoirs at fixed absolute temperatures
`Th` and `Tc` (kelvin, so both positive). A machine running in a cycle takes
heat `Qh > 0` from the hot side, hands heat `Qc` to the cold side and gives out
work `W`. Over one lap the first law gives `W = Qh - Qc`, and the second law
says the total entropy change `-Qh/Th + Qc/Tc` is not negative. Then the
efficiency `W / Qh` is at most `1 - Tc/Th`. -/
theorem carnot_efficiency_le (Th Tc Qh Qc W : ℝ)
    (hTh : 0 < Th) (hTc : 0 < Tc) (hQh : 0 < Qh)
    (energy : W = Qh - Qc)
    (entropy : 0 ≤ -Qh / Th + Qc / Tc) :
    W / Qh ≤ 1 - Tc / Th := by
  have key : Qh * Tc ≤ Qc * Th := by
    have h := mul_nonneg (mul_pos hTh hTc).le entropy
    have e : Th * Tc * (-Qh / Th + Qc / Tc) = Qc * Th - Qh * Tc := by
      field_simp; ring
    linarith
  subst energy
  rw [div_le_iff₀ hQh]
  have e2 : (1 - Tc / Th) * Qh = Qh - Qh * Tc / Th := by field_simp
  rw [e2]
  have : Qh * Tc / Th ≤ Qc := by rw [div_le_iff₀ hTh]; linarith
  linarith

/-- The engine reaches the limit exactly when it is reversible: under the same
cycle and energy balance, the efficiency equals `1 - Tc/Th` if and only if the
total entropy change `-Qh/Th + Qc/Tc` is zero. -/
theorem carnot_efficiency_eq_iff_reversible (Th Tc Qh Qc W : ℝ)
    (hTh : 0 < Th) (hTc : 0 < Tc) (hQh : 0 < Qh)
    (energy : W = Qh - Qc) :
    W / Qh = 1 - Tc / Th ↔ -Qh / Th + Qc / Tc = 0 := by
  subst energy
  have e : -Qh / Th + Qc / Tc = (Qc * Th - Qh * Tc) / (Th * Tc) := by
    field_simp; ring
  have e2 : (Qh - Qc) / Qh - (1 - Tc / Th) = (Qh * Tc - Qc * Th) / (Qh * Th) := by
    field_simp; ring
  rw [e, ← sub_eq_zero, e2, div_eq_zero_iff, div_eq_zero_iff]
  constructor
  · rintro (h | h)
    · left; linarith
    · exfalso; exact (mul_pos hQh hTh).ne' h
  · rintro (h | h)
    · left; linarith
    · exfalso; exact (mul_pos hTh hTc).ne' h

/-- Carnot's heat-pump limit. The engine run backwards between a cold
reservoir at `Tc` and a hotter one at `Th` (kelvin, `0 < Tc < Th`): work `W`
goes in, heat `Qc` is pulled from the cold side and heat `Qh > 0` is delivered
to the hot side. Energy: `Qh = W + Qc`. Entropy: the cold side loses `Qc/Tc`,
the hot side gains `Qh/Th`, and the total cannot fall. Then the score
`COP = Qh / W` is at most `Th / (Th - Tc)`. -/
theorem heat_pump_cop_le (Th Tc Qh Qc W : ℝ)
    (hTc : 0 < Tc) (hcold : Tc < Th) (hQh : 0 < Qh)
    (energy : Qh = W + Qc)
    (entropy : 0 ≤ -Qc / Tc + Qh / Th) :
    Qh / W ≤ Th / (Th - Tc) := by
  have hTh : 0 < Th := by linarith
  have hd : 0 < Th - Tc := by linarith
  have key : Qc * Th ≤ Qh * Tc := by
    have h := mul_nonneg (mul_pos hTh hTc).le entropy
    have e : Th * Tc * (-Qc / Tc + Qh / Th) = Qh * Tc - Qc * Th := by
      field_simp; ring
    linarith
  have hW : Qh * (Th - Tc) ≤ W * Th := by
    have : W = Qh - Qc := by linarith
    subst this; nlinarith
  have hWpos : 0 < W := by
    have := mul_pos hQh hd
    by_contra hneg
    have hneg' := not_lt.mp hneg
    nlinarith
  rw [div_le_div_iff₀ hWpos hd]
  linarith

-- The card's boiler: 90 °C = 36315/100 K and room 20 °C = 29315/100 K.
-- Engine limit 1 - 293.15/363.15 = 70/363.15, written as exact fractions.
example : (1 : ℝ) - (29315 / 100) / (36315 / 100) = 7000 / 36315 := by norm_num

-- Heat-pump limit 363.15/70, and the pump scoring 4 sits below it.
example : (36315 / 100 : ℝ) / (36315 / 100 - 29315 / 100) = 36315 / 7000 := by norm_num
example : (4 : ℝ) < (36315 / 100) / (36315 / 100 - 29315 / 100) := by norm_num

-- With 5 K gaps at each heat exchanger, the limit 368.15/80 is still above 4.
example : (4 : ℝ) < (36815 / 100) / (36815 / 100 - 28815 / 100) := by norm_num

-- A score of 4 drawing from 293.15 K allows delivery up to Th = 4 * 293.15 / 3,
-- where the limit Th/(Th - Tc) is exactly 4.
example : (4 * (29315 / 100) / 3 : ℝ) / (4 * (29315 / 100) / 3 - 29315 / 100) = 4 := by
  norm_num

-- The fridge limit Tc/(Th - Tc) is one less than the heating limit.
example : (36315 / 100 : ℝ) / 70 - (29315 / 100) / 70 = 1 := by norm_num

-- The Celsius mistake: 1 - 20/90 = 7/9 and 90/70 = 9/7.
example : (1 : ℝ) - 20 / 90 = 7 / 9 := by norm_num
example : (90 : ℝ) / 70 = 9 / 7 := by norm_num

#print axioms carnot_efficiency_le
#print axioms carnot_efficiency_eq_iff_reversible
#print axioms heat_pump_cop_le
