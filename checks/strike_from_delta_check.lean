-- Strike from delta: in the Black-Scholes model the call and put deltas fall strictly as the strike rises, so a delta names exactly one positive strike precisely when it lies strictly inside its range, and the normal-quantile formula gives that strike.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Monotone.Basic

open Real MeasureTheory ProbabilityTheory Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The helper `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The call's spot delta as a function of the strike: `e^(-qT) N(d₁)`. -/
noncomputable def callDelta (S r q σ T K : ℝ) : ℝ :=
  exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)

/-- The put's spot delta as a function of the strike: `-e^(-qT) N(-d₁)`. -/
noncomputable def putDelta (S r q σ T K : ℝ) : ℝ :=
  -(exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T))


lemma sfd_cdf_strictMono : StrictMono stdNormalCDF := by
  intro x y hxy
  have h1 : (cdf (gaussianReal 0 1)).measure (Ioc x y)
      = ENNReal.ofReal (stdNormalCDF y - stdNormalCDF x) :=
    StieltjesFunction.measure_Ioc _ x y
  rw [measure_cdf] at h1
  have h2 : gaussianReal 0 1 (Ioc x y) ≠ 0 := by
    intro h
    have h3 := gaussianReal_absolutelyContinuous' 0 (v := 1) one_ne_zero h
    rw [Real.volume_Ioc, ENNReal.ofReal_eq_zero] at h3
    linarith
  rw [h1] at h2
  have h4 : ¬ (stdNormalCDF y - stdNormalCDF x ≤ 0) := fun h => h2 (ENNReal.ofReal_eq_zero.mpr h)
  linarith [not_le.mp h4]

lemma sfd_cdf_continuous : Continuous stdNormalCDF := by
  have hfun : stdNormalCDF = fun x => cdf (gaussianReal 0 1) x := rfl
  have hmono : Monotone (cdf (gaussianReal 0 1)) := monotone_cdf _
  rw [hfun, continuous_iff_continuousAt]
  intro a
  have h1 : (cdf (gaussianReal 0 1)).measure {a}
      = ENNReal.ofReal (cdf (gaussianReal 0 1) a - Function.leftLim (cdf (gaussianReal 0 1)) a) :=
    StieltjesFunction.measure_singleton _ a
  rw [measure_cdf] at h1
  have h0 : gaussianReal 0 1 {a} = 0 :=
    gaussianReal_absolutelyContinuous 0 one_ne_zero (Real.volume_singleton)
  rw [h0, eq_comm, ENNReal.ofReal_eq_zero] at h1
  have h2 := hmono.leftLim_le (le_refl a)
  have h5 : ContinuousAt (cdf (gaussianReal 0 1)) a := by
    rw [hmono.continuousAt_iff_leftLim_eq_rightLim, StieltjesFunction.rightLim_eq]
    linarith
  exact h5

lemma sfd_cdf_pos (x : ℝ) : 0 < stdNormalCDF x :=
  lt_of_le_of_lt (cdf_nonneg _ (x - 1)) (sfd_cdf_strictMono (by linarith : x - 1 < x))

lemma sfd_cdf_lt_one (x : ℝ) : stdNormalCDF x < 1 :=
  lt_of_lt_of_le (sfd_cdf_strictMono (by linarith : x < x + 1)) (cdf_le_one _ (x + 1))

lemma sfd_cdf_surj (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) : ∃ z, stdNormalCDF z = p := by
  have hbot : Filter.Tendsto stdNormalCDF Filter.atBot (nhds 0) := tendsto_cdf_atBot _
  have htop : Filter.Tendsto stdNormalCDF Filter.atTop (nhds 1) := tendsto_cdf_atTop _
  have ha : ∃ a, stdNormalCDF a ≤ p := by
    obtain ⟨a, ha⟩ := ((tendsto_order.1 hbot).2 p hp0).exists
    exact ⟨a, ha.le⟩
  have hb : ∃ b, p ≤ stdNormalCDF b := by
    obtain ⟨b, hb⟩ := ((tendsto_order.1 htop).1 p hp1).exists
    exact ⟨b, hb.le⟩
  exact mem_range_of_exists_le_of_exists_ge sfd_cdf_continuous ha hb

lemma sfd_d1_strictAntiOn (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    StrictAntiOn (fun K => bsD1 S K r q σ T) (Ioi 0) := by
  intro K1 hK1 K2 hK2 hlt
  have hK1' : 0 < K1 := hK1
  have hK2' : 0 < K2 := hK2
  simp only [bsD1]
  have hpos : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  apply div_lt_div_of_pos_right _ hpos
  rw [log_div hS.ne' hK1'.ne', log_div hS.ne' hK2'.ne']
  have := Real.log_lt_log hK1' hlt
  linarith

lemma sfd_d1_closed (S r q σ T z : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) (sgn : ℝ) :
    bsD1 S (S * exp (sgn * (σ * √T) * z + (r - q + σ ^ 2 / 2) * T)) r q σ T = -sgn * z := by
  have hpos : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hlog : log (S / (S * exp (sgn * (σ * √T) * z + (r - q + σ ^ 2 / 2) * T)))
      = -(sgn * (σ * √T) * z + (r - q + σ ^ 2 / 2) * T) := by
    rw [div_mul_eq_div_div S S, div_self hS.ne', one_div, log_inv, log_exp]
  simp only [bsD1]
  rw [hlog, div_eq_iff hpos.ne']
  ring

lemma sfd_exp_cancel (q T : ℝ) : exp (-q * T) * exp (q * T) = 1 := by
  rw [← exp_add, show -q * T + q * T = 0 by ring, exp_zero]

lemma sfd_call_bounds (S r q σ T K : ℝ) :
    0 < callDelta S r q σ T K ∧ callDelta S r q σ T K < exp (-q * T) := by
  have he := exp_pos (-q * T)
  have h0 := sfd_cdf_pos (bsD1 S K r q σ T)
  have h1 := sfd_cdf_lt_one (bsD1 S K r q σ T)
  simp only [callDelta]
  constructor
  · positivity
  · nlinarith

lemma sfd_put_bounds (S r q σ T K : ℝ) :
    -exp (-q * T) < putDelta S r q σ T K ∧ putDelta S r q σ T K < 0 := by
  have he := exp_pos (-q * T)
  have h0 := sfd_cdf_pos (-bsD1 S K r q σ T)
  have h1 := sfd_cdf_lt_one (-bsD1 S K r q σ T)
  simp only [putDelta]
  constructor
  · nlinarith
  · nlinarith

lemma sfd_anti (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    StrictAntiOn (callDelta S r q σ T) (Ioi 0) ∧
      StrictAntiOn (putDelta S r q σ T) (Ioi 0) := by
  have hd := sfd_d1_strictAntiOn S r q σ T hS hσ hT
  have he := exp_pos (-q * T)
  constructor
  · intro K1 hK1 K2 hK2 hlt
    have := sfd_cdf_strictMono (hd hK1 hK2 hlt)
    simp only [callDelta]
    exact mul_lt_mul_of_pos_left this he
  · intro K1 hK1 K2 hK2 hlt
    have h := hd hK1 hK2 hlt
    have := sfd_cdf_strictMono (neg_lt_neg h)
    simp only [putDelta]
    have := mul_lt_mul_of_pos_left this he
    linarith

lemma sfd_closed (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ Δ z : ℝ, 0 < Δ → Δ < exp (-q * T) → stdNormalCDF z = Δ * exp (q * T) →
      callDelta S r q σ T (S * exp (-(σ * √T) * z + (r - q + σ ^ 2 / 2) * T)) = Δ) ∧
    (∀ Δ z : ℝ, -exp (-q * T) < Δ → Δ < 0 → stdNormalCDF z = |Δ| * exp (q * T) →
      putDelta S r q σ T (S * exp ((σ * √T) * z + (r - q + σ ^ 2 / 2) * T)) = Δ) := by
  constructor
  · intro Δ z _ _ hz
    have h := sfd_d1_closed S r q σ T z hS hσ hT (-1)
    rw [show -1 * (σ * √T) * z = -(σ * √T) * z by ring, show -(-1 : ℝ) * z = z by ring] at h
    simp only [callDelta]
    rw [h, hz, ← mul_assoc, mul_comm (exp (-q * T)) Δ, mul_assoc, sfd_exp_cancel, mul_one]
  · intro Δ z _ hΔ hz
    have h := sfd_d1_closed S r q σ T z hS hσ hT 1
    rw [show 1 * (σ * √T) * z = (σ * √T) * z by ring, show -(1 : ℝ) * z = -z by ring] at h
    simp only [putDelta]
    rw [h, neg_neg, hz, abs_of_neg hΔ]
    have := sfd_exp_cancel q T
    linear_combination Δ * this

lemma sfd_exists_unique (S r q σ T Δ : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    ((∃! K : ℝ, 0 < K ∧ callDelta S r q σ T K = Δ) ↔ (0 < Δ ∧ Δ < exp (-q * T))) ∧
      ((∃! K : ℝ, 0 < K ∧ putDelta S r q σ T K = Δ) ↔ (-exp (-q * T) < Δ ∧ Δ < 0)) := by
  have hanti := sfd_anti S r q σ T hS hσ hT
  have hcl := sfd_closed S r q σ T hS hσ hT
  have hE := exp_pos (q * T)
  have hc := sfd_exp_cancel q T
  constructor
  · constructor
    · rintro ⟨K, ⟨_, hK⟩, _⟩
      rw [← hK]
      exact sfd_call_bounds S r q σ T K
    · rintro ⟨h0, h1⟩
      obtain ⟨z, hz⟩ := sfd_cdf_surj (Δ * exp (q * T)) (by positivity) (by nlinarith)
      refine ⟨S * exp (-(σ * √T) * z + (r - q + σ ^ 2 / 2) * T),
        ⟨by positivity, hcl.1 Δ z h0 h1 hz⟩, ?_⟩
      rintro K' ⟨hK', hK'e⟩
      exact hanti.1.injOn hK' (show (0:ℝ) < _ by positivity)
        (hK'e.trans (hcl.1 Δ z h0 h1 hz).symm)
  · constructor
    · rintro ⟨K, ⟨_, hK⟩, _⟩
      rw [← hK]
      exact sfd_put_bounds S r q σ T K
    · rintro ⟨h0, h1⟩
      have habs : |Δ| = -Δ := abs_of_neg h1
      obtain ⟨z, hz⟩ := sfd_cdf_surj (|Δ| * exp (q * T)) (by rw [habs]; nlinarith)
        (by rw [habs]; nlinarith)
      refine ⟨S * exp ((σ * √T) * z + (r - q + σ ^ 2 / 2) * T),
        ⟨by positivity, hcl.2 Δ z h0 h1 hz⟩, ?_⟩
      rintro K' ⟨hK', hK'e⟩
      exact hanti.2.injOn hK' (show (0:ℝ) < _ by positivity)
        (hK'e.trans (hcl.2 Δ z h0 h1 hz).symm)

/-- **A delta names exactly one strike, exactly inside its range** (Why it works, Steps 1 and 2).
Fix a spot `S > 0`, volatility `σ > 0`, time `T > 0`, and any rates `r`, `q`. A call delta `Δ`
is the delta of exactly one positive strike if and only if `0 < Δ < e^(-qT)`; outside that range
no strike has it. A put delta `Δ` is the delta of exactly one positive strike if and only if
`-e^(-qT) < Δ < 0`. -/
theorem strike_from_delta_exists_unique_iff
    (S r q σ T Δ : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    ((∃! K : ℝ, 0 < K ∧ callDelta S r q σ T K = Δ) ↔ (0 < Δ ∧ Δ < exp (-q * T))) ∧
      ((∃! K : ℝ, 0 < K ∧ putDelta S r q σ T K = Δ) ↔ (-exp (-q * T) < Δ ∧ Δ < 0)) := by
  exact sfd_exists_unique S r q σ T Δ hS hσ hT

/-- **Delta falls as the strike rises** (Why it works, Step 1). Under the same terms, the call
delta and the put delta are both strictly decreasing in the strike over all positive strikes. -/
theorem delta_strictly_decreasing_in_strike
    (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    StrictAntiOn (callDelta S r q σ T) (Ioi 0) ∧
      StrictAntiOn (putDelta S r q σ T) (Ioi 0) := by
  exact sfd_anti S r q σ T hS hσ hT

/-- **The one-line formula** (The formula; Why it works, Step 3). Under the same terms, for a call
delta `0 < Δ < e^(-qT)`, if `z` is the normal quantile of `Δ e^(qT)` (that is, `N(z) = Δ e^(qT)`),
then the strike `K = S exp(-σ√T z + (r - q + σ²/2) T)` has call delta `Δ`. For a put delta
`-e^(-qT) < Δ < 0`, if `N(z) = |Δ| e^(qT)`, then `K = S exp(+σ√T z + (r - q + σ²/2) T)` has put
delta `Δ`. -/
theorem strike_from_delta_closed_form
    (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ Δ z : ℝ, 0 < Δ → Δ < exp (-q * T) → stdNormalCDF z = Δ * exp (q * T) →
      callDelta S r q σ T (S * exp (-(σ * √T) * z + (r - q + σ ^ 2 / 2) * T)) = Δ) ∧
    (∀ Δ z : ℝ, -exp (-q * T) < Δ → Δ < 0 → stdNormalCDF z = |Δ| * exp (q * T) →
      putDelta S r q σ T (S * exp ((σ * √T) * z + (r - q + σ ^ 2 / 2) * T)) = Δ) := by
  exact sfd_closed S r q σ T hS hσ hT

-- Acme: S = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- The drift inside d₁: (0.05 - 0.02 + 0.20²/2) · 1 = 0.05.
example : ((5 : ℚ) / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1 = 1 / 20 := by norm_num
-- No strike has call delta 0.99: it sits above the ceiling e^(-0.02) = 0.9802.
example : ¬ ∃ K : ℝ, 0 < K ∧ callDelta 100 (5 / 100) (2 / 100) (1 / 5) 1 K = 99 / 100 := by
  rintro ⟨K, _, hK⟩
  have hb := (sfd_call_bounds 100 (5 / 100) (2 / 100) (1 / 5) 1 K).2
  rw [hK] at hb
  have h1 := Real.add_one_le_exp (2 / 100 : ℝ)
  have h2 := sfd_exp_cancel (2 / 100 : ℝ) 1
  have h3 := exp_pos (-(2 / 100 : ℝ) * 1)
  rw [mul_one] at h2
  nlinarith
-- The delta-neutral strike K = S e^(0.05) = 105.13 has d₁ = 0.
example : bsD1 100 (100 * exp (1 / 20)) (5 / 100) (2 / 100) (1 / 5) 1 = 0 := by
  have h := sfd_d1_closed 100 (5 / 100) (2 / 100) (1 / 5) 1 0 (by norm_num) (by norm_num) (by norm_num) 0
  norm_num at h ⊢
  convert h using 3
-- The 25-delta put is the 73.02-delta call, not the 75: 0.730199 + 0.25 = 0.980199.
example : (730199 : ℕ) + 250000 = 980199 := by norm_num

#print axioms sfd_cdf_strictMono
#print axioms sfd_cdf_continuous
#print axioms sfd_cdf_pos
#print axioms sfd_cdf_lt_one
#print axioms sfd_cdf_surj
#print axioms sfd_d1_strictAntiOn
#print axioms sfd_d1_closed
#print axioms sfd_exp_cancel
#print axioms sfd_call_bounds
#print axioms sfd_put_bounds
#print axioms sfd_anti
#print axioms sfd_closed
#print axioms sfd_exists_unique
#print axioms strike_from_delta_exists_unique_iff
#print axioms delta_strictly_decreasing_in_strike
#print axioms strike_from_delta_closed_form
