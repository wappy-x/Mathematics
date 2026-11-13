-- Knock-out and knock-in: in any model a knock-in plus a knock-out with the same strike, barrier and monitoring rule costs the plain call, and the two-bell-curve no-touch density prices the down-and-out call as the plain call minus its weighted mirror image.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

namespace BarrierOptionsByReflection

open MeasureTheory ProbabilityTheory Real

/-! Setting.

Part 1 (in-out parity, any model). `Ω` is the set of possible histories and `μ` the pricing
measure: any measure at all, so any volatility smile, jumps or anything else. `X ω t` is EURUSD
at time `t` on history `ω`. `M` is the set of times at which the contract looks at the rate:
all of `[0, T]` for continuous monitoring, 252 daily closes, or any other rule. The option
"touches" when `X ω t ≤ H` for some looked-at time `t`. Both legs pay the plain call payoff
`max (X ω T - K) 0` at the same date `T`, no rebate, discounted by `exp (-r_d T)`.

Part 2 (Garman–Kohlhagen). `ν = r_d - r_f - σ²/2` is the drift of log EURUSD, `λ = ν / σ²`,
`v = σ² T` the variance of the log move over the year, `b = log (H / S)` the wall on the log
scale. `C x` is the Garman–Kohlhagen price of the plain call at spot `x`: the discounted payoff
`max (x eʸ - K) 0` against the bell curve of log moves with mean `ν T` and variance `v`.
Step 4 of the card gives the density of ending at log move `x > b` without touching as
`φ(x - νT) - e^{2νb/σ²} φ(x - 2b - νT)`; the theorem integrates the payoff against it. -/

lemma exp_mul_gaussianPDFReal (m : ℝ) (v : NNReal) (hv : v ≠ 0) (x : ℝ) :
    exp x * gaussianPDFReal m v x = exp (m + (v : ℝ) / 2) * gaussianPDFReal (m + v) v x := by
  have hv' : (0 : ℝ) < v := by positivity
  simp only [gaussianPDFReal]
  have h : x + -(x - m) ^ 2 / (2 * (v : ℝ)) = m + (v : ℝ) / 2 + -(x - (m + v)) ^ 2 / (2 * v) := by
    field_simp; ring
  calc exp x * ((√(2 * π * v))⁻¹ * exp (-(x - m) ^ 2 / (2 * v)))
      = (√(2 * π * v))⁻¹ * exp (x + -(x - m) ^ 2 / (2 * v)) := by rw [exp_add]; ring
    _ = (√(2 * π * v))⁻¹ * exp (m + (v : ℝ) / 2 + -(x - (m + v)) ^ 2 / (2 * v)) := by rw [h]
    _ = _ := by rw [exp_add]; ring

lemma integrable_call_payoff (S K m : ℝ) (v : NNReal) (hv : v ≠ 0) (hS : 0 ≤ S) (hK : 0 ≤ K) :
    Integrable (fun x => max (S * exp x - K) 0 * gaussianPDFReal m v x) := by
  refine Integrable.mono' (((integrable_gaussianPDFReal (m + v) v).const_mul
    (S * exp (m + (v : ℝ) / 2)))) ?_ ?_
  · exact ((by fun_prop : Measurable fun x => max (S * exp x - K) 0).mul
      (measurable_gaussianPDFReal m v)).aestronglyMeasurable
  · refine Filter.Eventually.of_forall (fun x => ?_)
    have hp := gaussianPDFReal_nonneg m v x
    have h1 : 0 ≤ max (S * exp x - K) 0 := le_max_right _ _
    have h2 : max (S * exp x - K) 0 ≤ S * exp x := by
      apply max_le <;> nlinarith [exp_pos x]
    rw [Real.norm_eq_abs, abs_of_nonneg (mul_nonneg h1 hp)]
    calc max (S * exp x - K) 0 * gaussianPDFReal m v x ≤ S * exp x * gaussianPDFReal m v x :=
          mul_le_mul_of_nonneg_right h2 hp
      _ = S * (exp x * gaussianPDFReal m v x) := by ring
      _ = _ := by rw [exp_mul_gaussianPDFReal m v hv x]; ring

#print axioms exp_mul_gaussianPDFReal
#print axioms integrable_call_payoff

/-- In-out parity, in every model. Hold a knock-in and a knock-out on the same path, with the same
strike `K`, barrier `H`, expiry `T` and monitoring rule `M`, both paying the plain call payoff
at expiry and no rebate. On every path exactly one of them is alive, so their prices add up to
the price of the plain call. Nothing about the model is used, apart from the touch being an event
the model can price and the plain call having a price. -/
theorem knock_in_plus_knock_out_eq_plain {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (X : Ω → ℝ → ℝ) (M : Set ℝ) (H K T rd : ℝ)
    (hTouch : MeasurableSet {ω | ∃ t ∈ M, X ω t ≤ H})
    (hPlain : Integrable (fun ω => max (X ω T - K) 0) μ) :
    exp (-rd * T) * ∫ ω, Set.indicator {ω | ∃ t ∈ M, X ω t ≤ H}
        (fun ω => max (X ω T - K) 0) ω ∂μ
      + exp (-rd * T) * ∫ ω, Set.indicator {ω | ∀ t ∈ M, H < X ω t}
        (fun ω => max (X ω T - K) 0) ω ∂μ
      = exp (-rd * T) * ∫ ω, max (X ω T - K) 0 ∂μ := by
  have hc : {ω | ∀ t ∈ M, H < X ω t} = {ω | ∃ t ∈ M, X ω t ≤ H}ᶜ := by
    ext ω; simp only [Set.mem_ofPred_eq, Set.mem_compl_iff, not_exists, not_and, not_le]
  rw [hc, integral_indicator hTouch, integral_indicator hTouch.compl, ← mul_add,
    integral_add_compl hTouch hPlain]

/-- The down-and-out call by reflection (Steps 4 and 5). With the barrier `H` at or below the
strike `K` and spot `S` above the barrier, integrating the plain call payoff against the
two-bell-curve no-touch density (the bell curve from today's rate minus the bell curve from the
mirror start `2b`, shrunk by `e^{2νb/σ²}`) gives the plain call minus the plain call priced from
the mirror spot `H²/S`, scaled by the mirror weight `(H/S)^{2λ}`:
`C_do = C(S) - (H/S)^{2λ} C(H²/S)`. -/
theorem down_and_out_call_eq_plain_minus_weighted_mirror
    (S K H rd rf σ T : ℝ) (hH : 0 < H) (hHK : H ≤ K) (hHS : H < S) (hσ : 0 < σ) (hT : 0 < T) :
    let ν := rd - rf - σ ^ 2 / 2
    let lam := ν / σ ^ 2
    let v : NNReal := (σ ^ 2 * T).toNNReal
    let b := log (H / S)
    let C : ℝ → ℝ := fun x =>
      exp (-rd * T) * ∫ y, max (x * exp y - K) 0 * gaussianPDFReal (ν * T) v y
    exp (-rd * T) * ∫ x in Set.Ioi b, max (S * exp x - K) 0 *
        (gaussianPDFReal (ν * T) v x - exp (2 * ν * b / σ ^ 2) * gaussianPDFReal (2 * b + ν * T) v x)
      = C S - (H / S) ^ (2 * lam) * C (H ^ 2 / S) := by
  intro ν lam v b C
  have hS : 0 < S := hH.trans hHS
  have hK : 0 < K := hH.trans_le hHK
  have hv : v ≠ 0 := by
    simp only [v, ne_eq, Real.toNNReal_eq_zero, not_le]; positivity
  have hHS' : 0 < H / S := div_pos hH hS
  -- payoff vanishes off (b, ∞)
  have hzero : ∀ x, x ∉ Set.Ioi b → max (S * exp x - K) 0 = 0 := by
    intro x hx
    simp only [Set.mem_Ioi, not_lt] at hx
    have : exp x ≤ H / S := by
      calc exp x ≤ exp b := exp_le_exp.mpr hx
        _ = H / S := exp_log hHS'
    have : S * exp x ≤ H := by rw [le_div_iff₀ hS] at this; linarith
    exact max_eq_right (by linarith)
  have hI1 := integrable_call_payoff S K (ν * T) v hv hS.le hK.le
  have hI2 := integrable_call_payoff S K (2 * b + ν * T) v hv hS.le hK.le
  have hsplit : (∫ x in Set.Ioi b, max (S * exp x - K) 0 *
        (gaussianPDFReal (ν * T) v x - exp (2 * ν * b / σ ^ 2) * gaussianPDFReal (2 * b + ν * T) v x))
      = (∫ x, max (S * exp x - K) 0 * gaussianPDFReal (ν * T) v x)
        - exp (2 * ν * b / σ ^ 2) *
          ∫ x, max (S * exp x - K) 0 * gaussianPDFReal (2 * b + ν * T) v x := by
    rw [setIntegral_eq_integral_of_forall_compl_eq_zero (fun x hx => by rw [hzero x hx, zero_mul])]
    rw [← integral_const_mul, ← integral_sub hI1 (hI2.const_mul _)]
    congr 1; ext x; ring
  -- shift the mirror integral
  have hshift : (∫ x, max (S * exp x - K) 0 * gaussianPDFReal (2 * b + ν * T) v x)
      = ∫ y, max (H ^ 2 / S * exp y - K) 0 * gaussianPDFReal (ν * T) v y := by
    rw [← integral_add_right_eq_self _ (2 * b)]
    congr 1; ext y
    rw [gaussianPDFReal_add, show 2 * b + ν * T - 2 * b = ν * T by ring]
    congr 2
    rw [exp_add, show 2 * b = b + b by ring, exp_add, exp_log hHS']
    field_simp
  have hweight : (H / S) ^ (2 * lam) = exp (2 * ν * b / σ ^ 2) := by
    rw [rpow_def_of_pos hHS']
    congr 1
    simp only [lam, b]
    field_simp
  rw [hsplit, hshift, hweight]
  simp only [C]
  ring

/-- On the wall the knock-out formula is zero, whatever the plain-call pricing function `C` and
whatever `λ`: with spot equal to the barrier the mirror spot `H²/H` is the spot itself and the
weight is 1, so the two terms cancel and the knock-in is the whole plain call. -/
theorem knock_out_formula_zero_on_wall (C : ℝ → ℝ) (H lam : ℝ) (hH : 0 < H) :
    C H - (H / H) ^ (2 * lam) * C (H ^ 2 / H) = 0 := by
  rw [div_self hH.ne', one_rpow, one_mul, pow_two, mul_div_assoc, div_self hH.ne', mul_one,
    sub_self]

/-! The card's worked numbers, exactly (EURUSD 1.10, wall 1.05, rates 5% and 3%, volatility 10%). -/

-- drift of log EURUSD: ν = 0.05 - 0.03 - ½ (0.10)² = 0.015
example : (5 / 100 - 3 / 100 - 1 / 2 * (10 / 100) ^ 2 : ℚ) = 3 / 200 := by norm_num
-- λ = 0.015 / 0.01 = 1.5
example : ((3 / 200) / (10 / 100) ^ 2 : ℚ) = 3 / 2 := by norm_num
-- mirror weight (H/S)^{2λ} = (1.05/1.10)³ = 9261/10648 ≈ 0.869741
example : ((105 / 100) / (110 / 100) : ℚ) ^ 3 = 9261 / 10648 := by norm_num
-- mirror spot H²/S = 1.1025 / 1.10 = 441/440 ≈ 1.002273
example : ((105 / 100) ^ 2 / (110 / 100) : ℚ) = 441 / 440 := by norm_num
-- the mirror spot sits below the wall: 441/440 < 1.05
example : (441 / 440 : ℚ) < 105 / 100 := by norm_num
-- in desk units (hundredths of a pip): knock-out 416.61 + knock-in 118.95 = plain 535.56
example : 41661 + 11895 = 53556 := by norm_num

#print axioms knock_in_plus_knock_out_eq_plain
#print axioms down_and_out_call_eq_plain_minus_weighted_mirror
#print axioms knock_out_formula_zero_on_wall

end BarrierOptionsByReflection
