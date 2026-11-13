-- Four deltas for one option: in the Garman-Kohlhagen model the premium-adjusted delta (spot delta less the premium in euros) equals the cash leg (K/S) e^(-r_d T) N(d₂), its forward version is (K/F) N(d₂), the forward delta is N(d₁), a call's and a put's forward deltas add to one in size, and the premium-adjusted delta is S times the slope of the option's euro value C/S.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Inv

open Real MeasureTheory ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The card's `d₁ = (ln(S/K) + (r_d - r_f + σ²/2) T) / (σ√T)`; then `d₂ = d₁ - σ√T`. -/
noncomputable def gkD1 (S K rd rf σ T : ℝ) : ℝ :=
  (log (S / K) + (rd - rf + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Garman-Kohlhagen call premium in dollars per euro of notional:
`C = S e^(-r_f T) N(d₁) - K e^(-r_d T) N(d₂)`. -/
noncomputable def gkCall (S K rd rf σ T : ℝ) : ℝ :=
  S * exp (-rf * T) * stdNormalCDF (gkD1 S K rd rf σ T)
    - K * exp (-rd * T) * stdNormalCDF (gkD1 S K rd rf σ T - σ * √T)

/-- The Garman-Kohlhagen put premium in dollars per euro of notional:
`P = K e^(-r_d T) N(-d₂) - S e^(-r_f T) N(-d₁)`. -/
noncomputable def gkPut (S K rd rf σ T : ℝ) : ℝ :=
  K * exp (-rd * T) * stdNormalCDF (-(gkD1 S K rd rf σ T - σ * √T))
    - S * exp (-rf * T) * stdNormalCDF (-(gkD1 S K rd rf σ T))

lemma stdNormalCDF_add_neg (d : ℝ) : stdNormalCDF d + stdNormalCDF (-d) = 1 := by
  unfold stdNormalCDF
  rw [cdf_eq_real, cdf_eq_real]
  have hmap : (gaussianReal 0 1).map (fun x : ℝ ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  have h1 : (gaussianReal 0 1).real (Set.Iic (-d)) = (gaussianReal 0 1).real (Set.Ici d) := by
    conv_lhs => rw [← hmap]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  have hpt : (gaussianReal 0 1) {d} = 0 :=
    gaussianReal_absolutelyContinuous 0 one_ne_zero (Real.volume_singleton)
  have h2 : (gaussianReal 0 1).real (Set.Ici d) = (gaussianReal 0 1).real (Set.Ioi d) := by
    rw [← Set.Ioi_insert, Set.insert_eq,
      measureReal_union (by simp) measurableSet_Ioi]
    simp [Measure.real, hpt]
  rw [h1, h2, ← Set.compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ]
  ring

#print axioms stdNormalCDF_add_neg

/-- **Four deltas for one option** (The formula; Why it works, Steps 1 to 4). In the
Garman-Kohlhagen model with spot `S > 0`, strike `K > 0`, volatility `σ > 0`, time `T > 0` and
constant rates `r_d`, `r_f`, write `F = S e^((r_d - r_f) T)` for the forward rate and
`Δ_S = e^(-r_f T) N(d₁)` for the call's spot delta. Then:
the forward delta, the spot delta counted in forward contracts (each worth `e^(-r_f T)` euros
today), is `Δ_F = Δ_S / e^(-r_f T) = N(d₁)`;
the premium-adjusted spot delta, the spot delta less the premium in euros, is
`Δ_S^pa = Δ_S - C/S = (K/S) e^(-r_d T) N(d₂)`, the cash leg in euros;
the premium-adjusted forward delta is `Δ_F^pa = Δ_S^pa / e^(-r_f T) = (K/F) N(d₂)`;
and for a put, with `-N(-d₁)` and `-N(-d₂)` in place of `N(d₁)` and `N(d₂)`, the same
subtraction gives `-e^(-r_f T) N(-d₁) - P/S = -(K/S) e^(-r_d T) N(-d₂)`. -/
theorem four_fx_deltas_premium_adjusted_is_cash_leg
    (S K rd rf σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let d₁ := gkD1 S K rd rf σ T
    let d₂ := d₁ - σ * √T
    let F := S * exp ((rd - rf) * T)
    let ΔS := exp (-rf * T) * stdNormalCDF d₁
    ΔS / exp (-rf * T) = stdNormalCDF d₁ ∧
      ΔS - gkCall S K rd rf σ T / S = K / S * exp (-rd * T) * stdNormalCDF d₂ ∧
      (ΔS - gkCall S K rd rf σ T / S) / exp (-rf * T) = K / F * stdNormalCDF d₂ ∧
      -(exp (-rf * T) * stdNormalCDF (-d₁)) - gkPut S K rd rf σ T / S
        = -(K / S * exp (-rd * T) * stdNormalCDF (-d₂)) := by
  intro d₁ d₂ F ΔS
  have hf : exp (-rf * T) ≠ 0 := (exp_pos _).ne'
  have hS' : S ≠ 0 := hS.ne'
  have hsplit : exp (-rf * T) = exp ((rd - rf) * T) * exp (-rd * T) := by
    rw [← exp_add]; ring_nf
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp only [ΔS]; field_simp
  · simp only [ΔS, gkCall, d₂, d₁]; field_simp; ring
  · simp only [ΔS, gkCall, d₂, d₁, F]
    rw [hsplit]
    have he : exp ((rd - rf) * T) ≠ 0 := (exp_pos _).ne'
    have he' : exp (-rd * T) ≠ 0 := (exp_pos _).ne'
    field_simp; ring
  · simp only [gkPut, d₂, d₁]; field_simp; ring

/-- **Call and put forward deltas add to one in size** (Step 2). For every `d₁`, the call's
forward delta `N(d₁)` minus the put's forward delta `-N(-d₁)` is exactly `1`; so a 25-delta call
and a 75-delta put in forward delta share one strike. -/
theorem forward_delta_call_minus_put_eq_one (d₁ : ℝ) :
    stdNormalCDF d₁ - (-stdNormalCDF (-d₁)) = 1 := by
  rw [sub_neg_eq_add]
  exact stdNormalCDF_add_neg d₁

/-- **The premium-adjusted delta keeps the euro account flat** (Step 3). For any premium
function `C` of the spot that has a slope at `S ≠ 0`, `S` times the slope of the option's euro
value `C/S` equals the dollar slope less the premium in euros:
`S · d/dS (C(S)/S) = C'(S) - C(S)/S`. -/
theorem premium_adjusted_delta_is_slope_of_euro_value
    (C : ℝ → ℝ) (S : ℝ) (hS : S ≠ 0) (hC : DifferentiableAt ℝ C S) :
    S * deriv (fun s => C s / s) S = deriv C S - C S / S := by
  rw [deriv_fun_div (d := fun s : ℝ => s) hC differentiableAt_id hS, deriv_id'']
  field_simp

-- House market: S = K = 1.1, r_d = 5/100, r_f = 3/100, σ = 1/10, T = 1.
-- d₁ = (ln(1.1/1.1) + (0.05 - 0.03 + 0.005) · 1) / (0.10 · √1) = 0.25.
example : (log ((11 / 10) / (11 / 10)) + ((5 / 100 : ℝ) - 3 / 100 + (1 / 10) ^ 2 / 2) * 1)
    / (1 / 10 * √1) = 1 / 4 := by norm_num
-- d₂ = d₁ - σ√T = 0.25 - 0.10 = 0.15.
example : (1 / 4 : ℚ) - 1 / 10 * 1 = 3 / 20 := by norm_num
-- Step 3: Δ_S^pa = 0.581012 - 0.048687 = 0.532325.
example : (581012 : ℚ) / 1000000 - 48687 / 1000000 = 532325 / 1000000 := by norm_num
-- On EUR 10,000,000: the spot hedge shrinks by the premium in euros, 5,810,119 - 5,323,248 = 486,871.
example : (5810119 : ℤ) - 5323248 = 486871 := by decide
-- What breaks: the forward delta used as a spot hedge buys 5,987,063 - 5,810,119 = 176,944 too many.
example : (5987063 : ℤ) - 5810119 = 176944 := by decide
-- 25-delta call strikes, in units of 0.00001 (tenths of a pip), measured from the spot-delta strike
-- 1.20368: forward 1.20654 is 28.6 pips higher, pa spot 1.19782 is 58.6 lower, pa forward 1.20082
-- is 28.6 lower.
example : (120654 : ℤ) - 120368 = 286 ∧ (119782 : ℤ) - 120368 = -586 ∧
    (120082 : ℤ) - 120368 = -286 := by decide
-- 25-delta put strikes from the spot-delta strike 1.05679: forward 1.05428 is 25.1 pips lower,
-- pa spot 1.05179 is 50.0 lower.
example : (105428 : ℤ) - 105679 = -251 ∧ (105179 : ℤ) - 105679 = -500 := by decide

#print axioms four_fx_deltas_premium_adjusted_is_cash_leg
#print axioms forward_delta_call_minus_put_eq_one
#print axioms premium_adjusted_delta_is_slope_of_euro_value
