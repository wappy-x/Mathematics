-- One option, two currencies: the Garman-Kohlhagen price of a call on the foreign currency equals spot times strike times the price of a put on the domestic currency with spot and strike inverted and the two interest rates swapped, the mirror line holds for puts, and the two payoffs agree on every path.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Garman-Kohlhagen `d₁ = (ln(S/K) + (r_d - r_f + σ²/2) T) / (σ√T)`, with `S` the spot and `K`
the strike, both in domestic currency per unit of foreign, `r_d` the domestic rate, `r_f` the
foreign rate, `σ` the volatility and `T` the time to expiry; `d₂ = d₁ - σ√T`. -/
noncomputable def gkD1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)

/-- Garman-Kohlhagen call: the price, in domestic currency, of the right to buy one unit of the
foreign currency for `K` units of domestic on expiry day,
`C = S e^(-r_f T) N(d₁) - K e^(-r_d T) N(d₂)`. -/
noncomputable def gkCall (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
    - K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T)

/-- Garman-Kohlhagen put: the price, in domestic currency, of the right to sell one unit of the
foreign currency for `K` units of domestic on expiry day,
`P = K e^(-r_d T) N(-d₂) - S e^(-r_f T) N(-d₁)`. -/
noncomputable def gkPut (S K rd rf σ T : ℝ) : ℝ :=
  K * exp (-rd * T) * stdNormalCDF (-(gkD1 S K rd rf σ T - σ * √T))
    - S * exp (-rf * T) * stdNormalCDF (-gkD1 S K rd rf σ T)

/-- Inverting spot and strike and swapping the rates turns `d₁` into `-d₂`. -/
lemma gkD1_mirror (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    gkD1 (1 / S) (1 / K) rf rd σ T = -(gkD1 S K rd rf σ T - σ * √T) := by
  have hsq : 0 < √T := Real.sqrt_pos.mpr hT
  have hne : σ * √T ≠ 0 := (mul_pos hσ hsq).ne'
  have hlog : log (1 / S / (1 / K)) = -log (S / K) := by
    rw [show 1 / S / (1 / K) = (S / K)⁻¹ by field_simp, Real.log_inv]
  have hT' : σ ^ 2 * T = (σ * √T) * (σ * √T) := by
    rw [show (σ * √T) * (σ * √T) = σ ^ 2 * (√T * √T) by ring, Real.mul_self_sqrt hT.le]
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  unfold gkD1
  rw [hlog]
  field_simp
  linear_combination hT' - σ ^ 2 * hT2

#print axioms gkD1_mirror

/-- **Foreign-domestic symmetry** (The formula; Why it works, Steps 2 and 3). A call on the
foreign currency is a put on the domestic currency. With spot `S > 0` and strike `K > 0` (domestic
per unit of foreign), the same volatility `σ > 0` on both sides, fixed rates `r_d` and `r_f`, and
European exercise at `T > 0`: the domestic price of the right to buy one unit of foreign at `K`
equals `S · K` times the foreign-currency price of the right to sell one unit of domestic at
`1/K`, priced from the other side with spot `1/S` and the two interest rates trading places,
`C(S, K, r_d, r_f) = S K P(1/S, 1/K, r_f, r_d)`. -/
theorem foreign_call_is_domestic_put_times_spot_times_strike
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    gkCall S K rd rf σ T = S * K * gkPut (1 / S) (1 / K) rf rd σ T := by
  have h := gkD1_mirror S K rd rf σ T hS hK hσ hT
  unfold gkCall gkPut
  rw [h, neg_neg, show -(gkD1 S K rd rf σ T - σ * √T) - σ * √T = -gkD1 S K rd rf σ T by ring]
  field_simp

/-- **The mirror line: a foreign put is a domestic call** (The formula; Step 4). Under the same
conditions, the domestic price of the right to sell one unit of foreign at `K` equals `S · K`
times the foreign-currency price of the right to buy one unit of domestic at `1/K`, with spot
`1/S` and the rates swapped, `P(S, K, r_d, r_f) = S K C(1/S, 1/K, r_f, r_d)`. -/
theorem foreign_put_is_domestic_call_times_spot_times_strike
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    gkPut S K rd rf σ T = S * K * gkCall (1 / S) (1 / K) rf rd σ T := by
  have h := gkD1_mirror S K rd rf σ T hS hK hσ hT
  unfold gkCall gkPut
  rw [h, show -(gkD1 S K rd rf σ T - σ * √T) - σ * √T = -gkD1 S K rd rf σ T by ring]
  field_simp

/-- **The payoffs agree on every path, with no model** (Step 1). For any strike `K > 0` and any
expiry rate `S_T > 0`: a put on `K` units of domestic at `1/K` foreign each pays
`K (1/K - 1/S_T)^+ = (S_T - K)^+ / S_T` in foreign currency, and turned into domestic currency at
the expiry rate `S_T` that is exactly the call's payoff `(S_T - K)^+`. -/
theorem domestic_put_payoff_converted_equals_foreign_call_payoff
    (K ST : ℝ) (hK : 0 < K) (hST : 0 < ST) :
    K * max (1 / K - 1 / ST) 0 = max (ST - K) 0 / ST ∧
      K * max (1 / K - 1 / ST) 0 * ST = max (ST - K) 0 := by
  have hK' := hK.ne'
  have hST' := hST.ne'
  have h1 : K * max (1 / K - 1 / ST) 0 = max (ST - K) 0 / ST := by
    rcases le_total ST K with h | h
    · have a : 1 / K - 1 / ST ≤ 0 := by
        rw [sub_nonpos]; exact one_div_le_one_div_of_le hST h
      rw [max_eq_right a, max_eq_right (by linarith)]; simp
    · have a : 0 ≤ 1 / K - 1 / ST := by
        rw [sub_nonneg]; exact one_div_le_one_div_of_le hK h
      rw [max_eq_left a, max_eq_left (by linarith)]; field_simp
  refine ⟨h1, ?_⟩
  rw [h1]; field_simp

-- The house market: spot 1.10 = 11/10 USD per EUR, strike 1.20 = 6/5, USD 5%, EUR 3%, vol 10%.
-- Frankfurt's spot and strike: 1/1.10 = 10/11 and 1/1.20 = 5/6 EUR per USD.
example : (1 : ℚ) / (11 / 10) = 10 / 11 ∧ (1 : ℚ) / (6 / 5) = 5 / 6 := by norm_num
-- The 10 million EUR ticket at strike 1.20 is 12,000,000 USD of notional.
example : (6 / 5 : ℚ) * 10000000 = 12000000 := by norm_num
-- S · K = 1.10 × 1.20 = 1.32: USD pips per EUR pip, and the factor between the two prices.
example : (11 / 10 : ℚ) * (6 / 5) = 132 / 100 := by norm_num
-- Chicago's drift r_d - r_f + σ²/2 = 0.05 - 0.03 + 0.005 = 0.025; Frankfurt's, with the rates
-- swapped, r_f - r_d + σ²/2 = -0.015, which is minus Chicago's r_d - r_f - σ²/2 = 0.015.
example : (5 / 100 : ℚ) - 3 / 100 + (1 / 10) ^ 2 / 2 = 25 / 1000 ∧
    (3 / 100 : ℚ) - 5 / 100 + (1 / 10) ^ 2 / 2 = -(5 / 100 - 3 / 100 - (1 / 10) ^ 2 / 2) := by
  norm_num
-- Step 1 at expiry rate 1.40: Chicago's call pays 1.40 - 1.20 = 0.20 USD; Frankfurt's put pays
-- 1.20 (1/1.20 - 1/1.40) = 1/7 EUR, which is 0.20 USD at 1.40.
example : max ((7 / 5 : ℚ) - 6 / 5) 0 = 1 / 5 ∧ (6 / 5 : ℚ) * max (5 / 6 - 5 / 7) 0 = 1 / 7 ∧
    (1 / 7 : ℚ) * (7 / 5) = 1 / 5 := by norm_num
-- Step 1 at expiry rate 1.00: both payoffs are zero.
example : max ((1 : ℚ) - 6 / 5) 0 = 0 ∧ (6 / 5 : ℚ) * max (5 / 6 - 1) 0 = 0 := by norm_num

#print axioms foreign_call_is_domestic_put_times_spot_times_strike
#print axioms foreign_put_is_domestic_call_times_spot_times_strike
#print axioms domestic_put_payoff_converted_equals_foreign_call_payoff
