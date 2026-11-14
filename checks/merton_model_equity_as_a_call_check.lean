-- Merton's model: on the payment date the shareholders' share of the assets is a call struck at the debt and the lenders' share is the assets minus that call, which is also a riskless payment minus a put; in the lognormal pricing model the same split holds for today's prices, and the pricing chance of default is N(-d2).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- The shareholders' payoff on the payment date (Why it works, Step 0). The firm owes one
payment `F`. If its assets `V_T` are worth more than `F`, the lenders are paid in full and the
shareholders keep the rest, `V_T - F`; otherwise the firm defaults and, by limited liability,
the shareholders get nothing. -/
noncomputable def equityPayoff (VT F : ℝ) : ℝ := if F < VT then VT - F else 0

/-- The lenders' payoff on the payment date (Why it works, Step 0): the full `F` if the assets
cover it, otherwise all of the assets `V_T`. -/
noncomputable def debtPayoff (VT F : ℝ) : ℝ := if F < VT then F else VT

/-- **Equity is a call; debt is the assets minus the call, which is a safe payment minus a put**
(the card's main claim; Why it works, Steps 1 and 2, and the detailed proof). For any value `V_T`
of the assets on the payment date and any face value `F`: the shareholders get `(V_T - F)⁺`, the
payoff of a call on the assets struck at `F`; shareholders and lenders together get exactly
`V_T`; and the lenders get `min(V_T, F) = V_T - (V_T - F)⁺ = F - (F - V_T)⁺`, the assets minus
the call, or the riskless `F` minus the payoff of a put struck at `F`. -/
theorem equity_is_call_and_debt_is_safe_bond_minus_put (VT F : ℝ) :
    equityPayoff VT F = max (VT - F) 0 ∧
    equityPayoff VT F + debtPayoff VT F = VT ∧
    debtPayoff VT F = min VT F ∧
    debtPayoff VT F = VT - max (VT - F) 0 ∧
    debtPayoff VT F = F - max (F - VT) 0 := by
  unfold equityPayoff debtPayoff
  split_ifs with h
  · refine ⟨?_, ?_, ?_, ?_, ?_⟩
    · rw [max_eq_left (by linarith)]
    · ring
    · rw [min_eq_right h.le]
    · rw [max_eq_left (by linarith)]; ring
    · rw [max_eq_right (by linarith)]; ring
  · push Not at h
    refine ⟨?_, ?_, ?_, ?_, ?_⟩
    · rw [max_eq_right (by linarith)]
    · ring
    · rw [min_eq_left h]
    · rw [max_eq_right (by linarith)]; ring
    · rw [max_eq_left (by linarith)]; ring

/-- **Today's prices split the same way** (Why it works, Step 3). In Merton's model the assets
wander like a Black-Scholes share: under the pricing (risk-neutral) measure, the assets on the
payment date are `V_T = V e^((r - σ²/2)T + σ√T Z)` with `Z` a standard bell-curve draw, `V > 0`
today's assets, `σ > 0` the volatility, `T > 0` the years to payment, `r` the riskless rate and
`F > 0` the face value. Price each claim as its discounted average payoff: equity
`E = e^(-rT) 𝔼[(V_T - F)⁺]`, the put `P = e^(-rT) 𝔼[(F - V_T)⁺]`, the bond
`B = e^(-rT) 𝔼[min(V_T, F)]`. Then `B = V - E` and `B = F e^(-rT) - P`. -/
theorem merton_bond_price_eq_assets_minus_call_eq_safe_bond_minus_put
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {Z : Ω → ℝ} (hZ : HasLaw Z (gaussianReal 0 1) μ)
    (V F r σ T : ℝ) (hV : 0 < V) (hF : 0 < F) (hσ : 0 < σ) (hT : 0 < T)
    (VT : Ω → ℝ) (hVT : ∀ ω, VT ω = V * exp ((r - σ ^ 2 / 2) * T + σ * √T * Z ω)) :
    exp (-(r * T)) * ∫ ω, min (VT ω) F ∂μ =
        V - exp (-(r * T)) * ∫ ω, max (VT ω - F) 0 ∂μ ∧
    exp (-(r * T)) * ∫ ω, min (VT ω) F ∂μ =
        F * exp (-(r * T)) - exp (-(r * T)) * ∫ ω, max (F - VT ω) 0 ∂μ := by
  have hmgf := mgf_gaussianReal hZ (σ * √T)
  have hint : Integrable (fun ω => exp ((σ * √T) * Z ω)) μ := by
    rw [← mgf_pos_iff, hmgf]; exact exp_pos _
  have hVTeq : VT = fun ω => (V * exp ((r - σ ^ 2 / 2) * T)) * exp ((σ * √T) * Z ω) := by
    funext ω; rw [hVT ω, exp_add]; ring
  have hVTi : Integrable VT μ := by rw [hVTeq]; exact hint.const_mul _
  have hEV : ∫ ω, VT ω ∂μ = V * exp (r * T) := by
    rw [hVTeq, integral_const_mul]
    have : ∫ ω, exp ((σ * √T) * Z ω) ∂μ = exp (0 * (σ * √T) + (1 : NNReal) * (σ * √T) ^ 2 / 2) :=
      hmgf
    rw [this, mul_assoc, ← exp_add]
    congr 2
    rw [mul_pow, sq_sqrt hT.le]; push_cast; ring
  have hC : Integrable (fun ω => max (VT ω - F) 0) μ :=
    (hVTi.sub (integrable_const F)).sup (integrable_zero _ _ _)
  have hP : Integrable (fun ω => max (F - VT ω) 0) μ :=
    ((integrable_const F).sub hVTi).sup (integrable_zero _ _ _)
  have e1 : (fun ω => min (VT ω) F) = fun ω => VT ω - max (VT ω - F) 0 := by
    funext ω
    rcases le_total (VT ω) F with h | h
    · rw [min_eq_left h, max_eq_right (by linarith)]; ring
    · rw [min_eq_right h, max_eq_left (by linarith)]; ring
  have e2 : (fun ω => min (VT ω) F) = fun ω => F - max (F - VT ω) 0 := by
    funext ω
    rcases le_total (VT ω) F with h | h
    · rw [min_eq_left h, max_eq_left (by linarith)]; ring
    · rw [min_eq_right h, max_eq_right (by linarith)]; ring
  constructor
  · rw [e1, integral_sub hVTi hC, hEV, mul_sub, ← mul_assoc, mul_comm (exp _) V, mul_assoc,
      ← exp_add]
    simp
  · rw [e2, integral_sub (integrable_const F) hP, integral_const]
    simp only [probReal_univ, one_smul]
    ring

/-- **`N(-d₂)` is the pricing chance of default** (Why it works, Step 4). In the same model,
the chance that the assets end below the debt, `V_T < F`, equals `N(-d₂)`, where `N` is the
standard bell-curve area to the left and `d₂ = (ln(V/F) + (r - σ²/2)T) / (σ√T)`. -/
theorem merton_default_probability_eq_normal_cdf_neg_d2
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {Z : Ω → ℝ} (hZ : HasLaw Z (gaussianReal 0 1) μ)
    (V F r σ T : ℝ) (hV : 0 < V) (hF : 0 < F) (hσ : 0 < σ) (hT : 0 < T)
    (VT : Ω → ℝ) (hVT : ∀ ω, VT ω = V * exp ((r - σ ^ 2 / 2) * T + σ * √T * Z ω)) :
    μ.real {ω | VT ω < F} =
      cdf (gaussianReal 0 1) (-((log (V / F) + (r - σ ^ 2 / 2) * T) / (σ * √T))) := by
  set c := -((log (V / F) + (r - σ ^ 2 / 2) * T) / (σ * √T)) with hc
  have hb : 0 < σ * √T := mul_pos hσ (sqrt_pos.mpr hT)
  have hset : {ω | VT ω < F} = {ω | Z ω < c} := by
    ext ω
    simp only [Set.mem_ofPred_eq, hVT ω]
    rw [hc, lt_neg, div_lt_iff₀ hb, ← lt_div_iff₀' hV, ← lt_log_iff_exp_lt (div_pos hF hV),
      log_div hF.ne' hV.ne', log_div hV.ne' hF.ne']
    constructor <;> intro h <;> linarith
  rw [hset, hZ.measureReal_eq (p := fun x => x < c) measurableSet_Iio, cdf_eq_real]
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  exact measureReal_congr Iio_ae_eq_Iic

-- Step 1: assets at $140m with $80m owed leave the shareholders $60m.
example : equityPayoff 140 80 = 60 := by norm_num [equityPayoff]
-- Step 2: assets at $60m: the shareholders get 0, the lenders $60m, the put pays the $20m shortfall.
example : equityPayoff 60 80 = 0 ∧ debtPayoff 60 80 = 60 ∧ max ((80 : ℝ) - 60) 0 = 20 := by
  norm_num [equityPayoff, debtPayoff]
-- The payoff chart: at assets 0, 20, ..., 160, the equity row is 0, 0, 0, 0, 0, 20, 40, 60, 80.
example : [equityPayoff 0 80, equityPayoff 20 80, equityPayoff 40 80, equityPayoff 60 80,
    equityPayoff 80 80, equityPayoff 100 80, equityPayoff 120 80, equityPayoff 140 80,
    equityPayoff 160 80] = [0, 0, 0, 0, 0, 20, 40, 60, 80] := by
  norm_num [equityPayoff]
-- ... and the debt row is 0, 20, 40, 60, 80, 80, 80, 80, 80.
example : [debtPayoff 0 80, debtPayoff 20 80, debtPayoff 40 80, debtPayoff 60 80,
    debtPayoff 80 80, debtPayoff 100 80, debtPayoff 120 80, debtPayoff 140 80,
    debtPayoff 160 80] = [0, 20, 40, 60, 80, 80, 80, 80, 80] := by
  norm_num [debtPayoff]

#print axioms equity_is_call_and_debt_is_safe_bond_minus_put
#print axioms merton_bond_price_eq_assets_minus_call_eq_safe_bond_minus_put
#print axioms merton_default_probability_eq_normal_cdf_neg_d2
