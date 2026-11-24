-- Cheyette: the sensitivity G splits across a date, the curve integrates to the bond reconstitution formula, y's closed form solves its equation, and with that y the bond formula is Hull-White's.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

/-- The bond's sensitivity to the rate gap: `G(t, T) = (1 - e^{-κ(T - t)}) / κ`. -/
noncomputable def chG (κ t T : ℝ) : ℝ := (1 - Real.exp (-κ * (T - t))) / κ

/-- The variance piled up by time `t` when the volatility is a fixed `σ`:
`ȳ(t) = σ² (1 - e^{-2κt}) / (2κ)`. -/
noncomputable def chY (σ κ t : ℝ) : ℝ := σ ^ 2 * (1 - Real.exp (-2 * κ * t)) / (2 * κ)

lemma hasDerivAt_chG (κ t u : ℝ) (hκ : κ ≠ 0) :
    HasDerivAt (fun v => chG κ t v) (Real.exp (-κ * (u - t))) u := by
  have h1 : HasDerivAt (fun v : ℝ => -κ * (v - t)) (-κ) u := by
    simpa using ((hasDerivAt_id u).sub_const t).const_mul (-κ)
  have h2 := (h1.exp.const_sub 1).div_const κ
  unfold chG
  convert h2 using 1
  field_simp

lemma chG_self (κ t : ℝ) : chG κ t t = 0 := by simp [chG]

#print axioms hasDerivAt_chG
#print axioms chG_self

/-- **The sensitivity splits across a date.** For `κ ≠ 0`,
`G(s, T) = G(s, t) + e^{-κ(t - s)} G(t, T)`: the area from `s` to `T` is the area to `t` plus the
faded area beyond. This is what lets Step 2 pull `e^{-κ(T - t)}` out of every term. -/
theorem G_splits (κ s t T : ℝ) (hκ : κ ≠ 0) :
    chG κ s T = chG κ s t + Real.exp (-κ * (t - s)) * chG κ t T := by
  have h : Real.exp (-κ * (t - s)) * Real.exp (-κ * (T - t)) = Real.exp (-κ * (T - s)) := by
    rw [← Real.exp_add]; ring_nf
  unfold chG
  rw [← h]
  field_simp
  ring

/-- **The forced drift's area.** For `κ ≠ 0`, the volatility shape `e^{-κ(u - t)}` adds up, from
`t` to `T`, to `G(t, T)` (Step 1). -/
theorem drift_area (κ t T : ℝ) (hκ : κ ≠ 0) :
    ∫ u in t..T, Real.exp (-κ * (u - t)) = chG κ t T := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun u _ => hasDerivAt_chG κ t u hκ)
      ((by fun_prop : Continuous fun u : ℝ => Real.exp (-κ * (u - t))).intervalIntegrable _ _),
    chG_self, sub_zero]

/-- **The curve integrates to the two-number bond terms.** For `κ ≠ 0`,
`∫_t^T e^{-κ(u - t)} (x + G(t, u) y) du = G(t, T) x + G(t, T)² y / 2`, because `e^{-κ(u - t)}` is
the slope of `G(t, u)` in `u` (Step 3). -/
theorem reconstitution_integral (κ t T x y : ℝ) (hκ : κ ≠ 0) :
    ∫ u in t..T, Real.exp (-κ * (u - t)) * (x + chG κ t u * y)
      = chG κ t T * x + chG κ t T ^ 2 / 2 * y := by
  have hd : ∀ u ∈ Set.uIcc t T, HasDerivAt (fun v => chG κ t v * x + chG κ t v * chG κ t v / 2 * y)
      (Real.exp (-κ * (u - t)) * (x + chG κ t u * y)) u := by
    intro u _
    have hG := hasDerivAt_chG κ t u hκ
    convert (hG.mul_const x).add (((hG.mul hG).div_const 2).mul_const y) using 1
    ring
  have hc : Continuous fun u : ℝ => Real.exp (-κ * (u - t)) * (x + chG κ t u * y) := by
    unfold chG; fun_prop
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd (hc.intervalIntegrable _ _), chG_self]
  ring

/-- **The bond reconstitution formula.** Suppose today's curve `f₀` is integrable on `[t, T]`
and adds up to `ln D(t) - ln D(T)`, with `D(t), D(T) > 0`. If the forward curve at time `t` is
`f(t, u) = f₀(u) + e^{-κ(u - t)} (x + G(t, u) y)`, then the bond
`P(t, T) = exp(-∫_t^T f(t, u) du)` equals `D(T)/D(t) · exp(-G x - ½ G² y)`. -/
theorem bond_reconstitution (κ t T x y Dt DT : ℝ) (f₀ : ℝ → ℝ) (hκ : κ ≠ 0)
    (hDt : 0 < Dt) (hDT : 0 < DT) (hf : IntervalIntegrable f₀ MeasureTheory.volume t T)
    (hcurve : ∫ u in t..T, f₀ u = Real.log Dt - Real.log DT) :
    Real.exp (-∫ u in t..T, (f₀ u + Real.exp (-κ * (u - t)) * (x + chG κ t u * y)))
      = DT / Dt * Real.exp (-chG κ t T * x - 1 / 2 * chG κ t T ^ 2 * y) := by
  have hc : Continuous fun u : ℝ => Real.exp (-κ * (u - t)) * (x + chG κ t u * y) := by
    unfold chG; fun_prop
  rw [intervalIntegral.integral_add hf (hc.intervalIntegrable _ _), hcurve,
    reconstitution_integral κ t T x y hκ]
  have e : -(Real.log Dt - Real.log DT + (chG κ t T * x + chG κ t T ^ 2 / 2 * y))
      = (Real.log DT - Real.log Dt) + (-chG κ t T * x - 1 / 2 * chG κ t T ^ 2 * y) := by ring
  rw [e, Real.exp_add, Real.exp_sub, Real.exp_log hDT, Real.exp_log hDt]

/-- **With a fixed volatility, `y` is known in advance.** For `κ ≠ 0`, `ȳ(0) = 0` and
`ȳ'(t) = σ² - 2κ ȳ(t)`: the closed form solves `y`'s equation (Step 5). -/
theorem y_closed_form_solves (σ κ t : ℝ) (hκ : κ ≠ 0) :
    chY σ κ 0 = 0 ∧ HasDerivAt (fun s => chY σ κ s) (σ ^ 2 - 2 * κ * chY σ κ t) t := by
  refine ⟨by simp [chY], ?_⟩
  have h1 : HasDerivAt (fun s : ℝ => -2 * κ * s) (-2 * κ) t := by
    simpa using (hasDerivAt_id t).const_mul (-2 * κ)
  have h2 := ((h1.exp.const_sub 1).const_mul (σ ^ 2)).div_const (2 * κ)
  unfold chY
  convert h2 using 1
  field_simp
  ring

/-- **Deterministic volatility gives Hull-White's bond.** For `κ ≠ 0`, put `x = r - f` (rate gap
= short rate minus today's forward `f` for date `t`) and `y = ȳ(t)` into the reconstitution
formula: the result is Hull-White's `A e^{-B r}` with `B = G`,
`D(T)/D(t) · exp(B f - σ²/(4κ) (1 - e^{-2κt}) B² - B r)`. -/
theorem cheyette_bond_is_hull_white (σ κ t T r f Dt DT : ℝ) (hκ : κ ≠ 0) :
    DT / Dt * Real.exp (-chG κ t T * (r - f) - 1 / 2 * chG κ t T ^ 2 * chY σ κ t)
      = DT / Dt * Real.exp (chG κ t T * f
          - σ ^ 2 / (4 * κ) * (1 - Real.exp (-2 * κ * t)) * chG κ t T ^ 2 - chG κ t T * r) := by
  congr 2
  unfold chY
  field_simp
  ring

/-- **The skew's local volatilities.** `σ_r = 0.01 + 0.2 x` is 0.6, 0.8, 1.0, 1.2 and 1.4 percent
at `x` = −2, −1, 0, +1 and +2 percent, and reaches zero at `x` = −5 percent. -/
theorem local_vol_values :
    ((1 : ℚ) / 100 + 2 / 10 * (-2 / 100) = 6 / 1000) ∧ ((1 : ℚ) / 100 + 2 / 10 * (-1 / 100) = 8 / 1000)
    ∧ ((1 : ℚ) / 100 + 2 / 10 * 0 = 10 / 1000) ∧ ((1 : ℚ) / 100 + 2 / 10 * (1 / 100) = 12 / 1000)
    ∧ ((1 : ℚ) / 100 + 2 / 10 * (2 / 100) = 14 / 1000) ∧ ((1 : ℚ) / 100 + 2 / 10 * (-5 / 100) = 0) := by
  norm_num

#print axioms G_splits
#print axioms drift_area
#print axioms reconstitution_integral
#print axioms bond_reconstitution
#print axioms y_closed_form_solves
#print axioms cheyette_bond_is_hull_white
#print axioms local_vol_values
