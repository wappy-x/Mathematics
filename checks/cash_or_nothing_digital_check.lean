-- Cash-or-nothing digital: if the finishing price is S e^((r - q - σ²/2)T + σ√T Z) with Z a standard bell-curve draw under the pricing measure, the discounted average of the one-dollar payoff above the strike is e^(-rT) N(d₂), the payoff at or below the strike is worth e^(-rT) N(-d₂), and in any model at all the two together are worth exactly e^(-rT).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Acme's price on expiry day under the pricing measure (Step 1): today's price `S`, bank rate
`r`, dividend yield `q`, volatility `σ`, time to expiry `T`, and a standard bell-curve draw `z`:
`S_T = S e^((r - q - σ²/2) T + σ√T z)`. -/
noncomputable def priceAtExpiry (S r q σ T z : ℝ) : ℝ :=
  S * exp ((r - q - σ ^ 2 / 2) * T + σ * √T * z)

/-- `d₂ = (ln(S/K) + (r - q - σ²/2) T) / (σ√T)`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * √T)

lemma priceAtExpiry_le_iff (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) (z : ℝ) :
    priceAtExpiry S r q σ T z ≤ K ↔ z ≤ -bsD2 S K r q σ T := by
  have ha : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  unfold priceAtExpiry bsD2
  rw [← le_div_iff₀' hS, ← Real.le_log_iff_exp_le (div_pos hK hS), ← neg_div,
    le_div_iff₀ ha]
  have hl : log (K / S) = -log (S / K) := by rw [← Real.log_inv, inv_div]
  rw [hl]
  constructor <;> intro h <;> linarith [mul_comm z (σ * √T)]

lemma stdNormalCDF_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  unfold stdNormalCDF
  rw [cdf_eq_real, cdf_eq_real]
  have hmap : (gaussianReal 0 1).map (fun x : ℝ ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  conv_lhs => rw [← hmap]
  rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
  have h1 : (fun x : ℝ ↦ -x) ⁻¹' Set.Iic (-x) = (Set.Iio x)ᶜ := by
    ext y; simp
  rw [h1, measureReal_compl measurableSet_Iio, probReal_univ,
    measureReal_congr Iio_ae_eq_Iic]

#print axioms priceAtExpiry_le_iff
#print axioms stdNormalCDF_neg

/-- **Cash-or-nothing call digital** (The formula; Why it works, Steps 0 to 3). Under the pricing
measure `Q`, let Acme's price follow the Black-Scholes model with one fixed volatility `σ > 0`,
no jumps, and one bank rate `r` and dividend yield `q`, so that on expiry day, after `T > 0`
years, it is `S_T = S e^((r - q - σ²/2) T + σ√T Z)` with `Z` a standard bell-curve draw; today's
price is `S > 0` and the strike is `K > 0`; the contract pays $1 on expiry day if the closing
price is above the strike and nothing otherwise. Then its price, the average payoff under `Q`
shrunk back to today by `e^(-rT)`, is `e^(-rT) N(d₂)`: the discount factor times the priced-in
chance of finishing above the strike. -/
theorem cash_or_nothing_call_is_discounted_chance_above_strike
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * ∫ ω, (if K < priceAtExpiry S r q σ T (Z ω) then (1 : ℝ) else 0) ∂Q =
      exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T) := by
  congr 1
  have hmeas : MeasurableSet {z : ℝ | K < priceAtExpiry S r q σ T z} :=
    measurableSet_lt measurable_const (by unfold priceAtExpiry; fun_prop)
  have hfun : (fun z : ℝ ↦ if K < priceAtExpiry S r q σ T z then (1 : ℝ) else 0) =
      Set.indicator {z : ℝ | K < priceAtExpiry S r q σ T z} 1 := by
    ext z; simp [Set.indicator_apply]
  have hint := hZ.integral_comp
    (f := fun z : ℝ ↦ if K < priceAtExpiry S r q σ T z then (1 : ℝ) else 0)
    (by rw [hfun]; exact (measurable_one.indicator hmeas).aestronglyMeasurable)
  simp only [Function.comp_def] at hint
  rw [hint, hfun, integral_indicator_one hmeas]
  have hset : {z : ℝ | K < priceAtExpiry S r q σ T z} = (Set.Iic (-bsD2 S K r q σ T))ᶜ := by
    ext z
    rw [Set.mem_ofPred_eq, Set.mem_compl_iff, Set.mem_Iic,
      ← priceAtExpiry_le_iff S K r q σ T hS hK hσ hT z, not_le]
  rw [hset, measureReal_compl measurableSet_Iic, probReal_univ, ← cdf_eq_real,
    ← stdNormalCDF, stdNormalCDF_neg]
  ring

/-- **Cash-or-nothing put digital, and the pair in the model** (Step 2's detailed proof, Step 4).
In the same model, with `S > 0`, `K > 0`, `σ > 0`, `T > 0` and `Z` a standard bell-curve draw
under `Q`: the contract paying $1 when Acme closes at or below the strike is worth
`e^(-rT) Q(S_T ≤ K) = e^(-rT) N(-d₂)`, and call plus put is
`e^(-rT) N(d₂) + e^(-rT) N(-d₂) = e^(-rT)`, since the two chances add to one. -/
theorem cash_or_nothing_put_is_discounted_chance_below_strike
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T)
    (hZ : HasLaw Z (gaussianReal 0 1) Q) :
    exp (-r * T) * Q.real {ω | priceAtExpiry S r q σ T (Z ω) ≤ K} =
        exp (-r * T) * stdNormalCDF (-bsD2 S K r q σ T) ∧
      exp (-r * T) * stdNormalCDF (bsD2 S K r q σ T) +
        exp (-r * T) * stdNormalCDF (-bsD2 S K r q σ T) = exp (-r * T) := by
  constructor
  · have hset : {ω | priceAtExpiry S r q σ T (Z ω) ≤ K} = {ω | Z ω ≤ -bsD2 S K r q σ T} :=
      Set.ext fun ω ↦ priceAtExpiry_le_iff S K r q σ T hS hK hσ hT (Z ω)
    rw [hset, hZ.measureReal_eq (p := fun z ↦ z ≤ -bsD2 S K r q σ T) measurableSet_Iic,
      stdNormalCDF, cdf_eq_real]
    rfl
  · rw [stdNormalCDF_neg]; ring

/-- **Call plus put is one discounted dollar, with no model at all** (Step 4). Whatever the
finishing price `S_T` does, as long as it is a random quantity under a pricing measure `Q`
(a probability measure), and whatever rate `r` and time `T`: exactly one of the two digitals pays
on expiry day, so the discounted average payoff of the call (pays $1 when `S_T > K`) plus that of
the put (pays $1 when `S_T ≤ K`) is `e^(-rT)`, the price of a certain dollar. -/
theorem cash_or_nothing_call_plus_put_is_discount_factor
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} [IsProbabilityMeasure Q] {ST : Ω → ℝ}
    (hST : Measurable ST) (K r T : ℝ) :
    exp (-r * T) * ∫ ω, (if K < ST ω then (1 : ℝ) else 0) ∂Q +
        exp (-r * T) * ∫ ω, (if ST ω ≤ K then (1 : ℝ) else 0) ∂Q = exp (-r * T) := by
  have hs : MeasurableSet {ω | K < ST ω} := measurableSet_lt measurable_const hST
  have h1 : (fun ω ↦ if K < ST ω then (1 : ℝ) else 0) = Set.indicator {ω | K < ST ω} 1 := by
    ext ω; simp [Set.indicator_apply]
  have h2 : (fun ω ↦ if ST ω ≤ K then (1 : ℝ) else 0) = Set.indicator {ω | K < ST ω}ᶜ 1 := by
    ext ω; simp [Set.indicator_apply, not_lt]
  rw [h1, h2, integral_indicator_one hs, integral_indicator_one hs.compl, ← mul_add,
    measureReal_add_measureReal_compl hs, probReal_univ, mul_one]

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- Step 1, the drift under Q: r - q - σ²/2 = 0.05 - 0.02 - 0.02 = 0.01.
example : (5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2 = 1 / 100 := by norm_num
-- Step 2: d₂ = (ln(100/100) + 0.01 · 1) / (0.20 · √1) = 0.05.
example : (log (100 / 100) + ((5 / 100 : ℝ) - 2 / 100 - (1 / 5) ^ 2 / 2) * 1) / (1 / 5 * √1)
    = 1 / 20 := by norm_num
-- d₁ = d₂ + σ√T = 0.05 + 0.20 = 0.25.
example : (1 / 20 : ℚ) + 1 / 5 = 1 / 4 := by norm_num
-- Step 4, the house prices to six places: 0.494581 + 0.456648 = 0.951229.
example : (494581 / 1000000 : ℚ) + 456648 / 1000000 = 951229 / 1000000 := by norm_num
-- Step 2's detailed proof: N(-d₂) = 1 - 0.519939 = 0.480061.
example : (1 : ℚ) - 519939 / 1000000 = 480061 / 1000000 := by norm_num

#print axioms cash_or_nothing_call_is_discounted_chance_above_strike
#print axioms cash_or_nothing_put_is_discounted_chance_below_strike
#print axioms cash_or_nothing_call_plus_put_is_discount_factor
