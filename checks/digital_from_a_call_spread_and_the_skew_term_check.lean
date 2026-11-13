-- A digital from a call spread: when the finishing price has no lump of probability at the strike, the tight centered call spread tends to the digital price e^(-rT) Q(S_T > K), which is minus the slope of the call price in the strike, and when each strike carries its own smooth Black-Scholes volatility σ(K) that slope gives the digital e^(-rT) N(d₂) - vega · σ'(K).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Real MeasureTheory ProbabilityTheory Filter Topology Set

/-! Notation. `μ` is the market's pricing distribution of Acme's finishing price `S_T`, `r` the
bank rate and `T` the years to expiry, so `e^(-rT)` is the discount factor. A European call
struck at `k` pays `max (S_T - k) 0` on expiry day; its price today is the discounted average
of that payoff. The digital call pays $1 when `S_T > K`; its price is `e^(-rT) Q(S_T > K)`.
`N(x)` is Mathlib's `cdf (gaussianReal 0 1) x` and `φ(x)` is `gaussianPDFReal 0 1 x`. -/

/-- The price today of a European call struck at `k`, when `S_T` has pricing distribution `μ`:
`C(k) = e^(-rT) ∫ max (x - k) 0 dμ(x)`. -/
noncomputable def callPrice (μ : Measure ℝ) (r T k : ℝ) : ℝ :=
  exp (-(r * T)) * ∫ x, max (x - k) 0 ∂μ

/-- Black-Scholes `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- Black-Scholes `d₂ = d₁ - σ√T`. -/
noncomputable def bsD2 (S K r q σ T : ℝ) : ℝ :=
  bsD1 S K r q σ T - σ * √T

/-- The Black-Scholes call `C_BS(K, σ) = S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q σ T) -
    K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 S K r q σ T)

/-- Vega, the call's price change per 1.00 of volatility: `𝒱 = S e^(-qT) φ(d₁) √T`. -/
noncomputable def bsVega (S K r q σ T : ℝ) : ℝ :=
  S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q σ T) * √T

/-- Half a call spread per unit of width: long the call struck at `K - h`, short the call
struck at `K + h`, divided by the width `2h`. Its payoff at a finishing price `x`. -/
noncomputable def rampPayoff (K h x : ℝ) : ℝ :=
  (max (x - (K - h)) 0 - max (x - (K + h)) 0) / (2 * h)

/-- Helper: a centered difference quotient tends to minus the derivative. -/
theorem centered_quotient_tendsto_neg_deriv {f : ℝ → ℝ} {f' x : ℝ} (hf : HasDerivAt f f' x) :
    Tendsto (fun h : ℝ => (f (x - h) - f (x + h)) / (2 * h)) (𝓝[≠] 0) (𝓝 (-f')) := by
  have h1 := hasDerivAt_iff_tendsto_slope_zero.1 hf
  have hneg : Tendsto (fun t : ℝ => -t) (𝓝[≠] 0) (𝓝[≠] 0) := by
    refine tendsto_nhdsWithin_iff.2 ⟨?_, eventually_nhdsWithin_of_forall fun t ht => ?_⟩
    · have : Tendsto (fun t : ℝ => -t) (𝓝 0) (𝓝 (-0)) := tendsto_id.neg
      simpa using this.mono_left nhdsWithin_le_nhds
    · simpa using ht
  have h3 := (h1.add (h1.comp hneg)).const_mul (-(1 / 2 : ℝ))
  rw [show -(1 / 2 : ℝ) * (f' + f') = -f' by ring] at h3
  refine h3.congr' (eventually_nhdsWithin_of_forall fun t ht => ?_)
  have ht' : t ≠ 0 := ht
  simp only [Function.comp, smul_eq_mul]
  field_simp
  ring_nf

/-- Helper: the standard normal distribution function has slope `φ(x)` at `x`. -/
theorem stdNormal_cdf_hasDerivAt (x : ℝ) :
    HasDerivAt (fun y => cdf (gaussianReal 0 1) y) (gaussianPDFReal 0 1 x) x := by
  have hφc : Continuous (gaussianPDFReal 0 1) := by
    rw [gaussianPDFReal_def]; fun_prop
  have hint : Integrable (gaussianPDFReal 0 1) := integrable_gaussianPDFReal 0 1
  have key : ∀ y, cdf (gaussianReal 0 1) y =
      (∫ t in Iic 0, gaussianPDFReal 0 1 t) + ∫ t in (0 : ℝ)..y, gaussianPDFReal 0 1 t := by
    intro y
    rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral 0 one_ne_zero,
      ENNReal.toReal_ofReal (integral_nonneg fun _ => gaussianPDFReal_nonneg _ _ _),
      ← intervalIntegral.integral_Iic_sub_Iic hint.integrableOn hint.integrableOn]
    ring
  have := ((hφc.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add
    (∫ t in Iic 0, gaussianPDFReal 0 1 t)
  simpa only [← key] using this

/-- Helper: `K e^(-rT) φ(d₂) = S e^(-qT) φ(d₁)`. -/
theorem bs_pdf_identity (S K r q s T : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hs : 0 < s) :
    K * exp (-(r * T)) * gaussianPDFReal 0 1 (bsD2 S K r q s T) =
      S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q s T) := by
  have hsT : 0 < s * √T := mul_pos hs (Real.sqrt_pos.2 hT)
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT.le
  set d := bsD1 S K r q s T with hd
  have hu : d * (s * √T) = log (S / K) + (r - q + s ^ 2 / 2) * T := by
    rw [hd, bsD1]; field_simp
  have hSK : 0 < S / K := div_pos hS hK
  simp only [bsD2, gaussianPDFReal, ← hd, NNReal.coe_one, sub_zero, mul_one]
  calc K * exp (-(r * T)) * ((√(2 * π))⁻¹ * exp (-(d - s * √T) ^ 2 / 2))
      = K * (√(2 * π))⁻¹ * exp (-(r * T) + -(d - s * √T) ^ 2 / 2) := by rw [exp_add]; ring
    _ = K * (√(2 * π))⁻¹ * exp (log (S / K) + (-(q * T) + -d ^ 2 / 2)) := by
        congr 2; linear_combination hu - (s ^ 2 / 2) * hT2
    _ = S * exp (-(q * T)) * ((√(2 * π))⁻¹ * exp (-d ^ 2 / 2)) := by
        rw [exp_add, exp_log hSK, exp_add]; field_simp

#print axioms centered_quotient_tendsto_neg_deriv
#print axioms stdNormal_cdf_hasDerivAt
#print axioms bs_pdf_identity

/-- **A digital is minus the strike slope of the call, and the tight spread measures it**
(The formula; Why it works, Steps 0 to 2, with no model). Let European calls on Acme be priced
as the discounted average payoff under a pricing distribution `μ` of the finishing price (a
probability distribution with a finite average, so every call has a price), and suppose there is
no lump of probability at the strike: `μ {K} = 0`. Then the centered call spread
`(C(K - h) - C(K + h)) / (2h)` tends, as `h → 0`, to the digital's price
`e^(-rT) Q(S_T > K)`, and the call price has slope exactly minus that number at `K`. -/
theorem digital_eq_limit_of_call_spread_eq_neg_strike_slope
    (μ : Measure ℝ) [IsProbabilityMeasure μ] (hμ : Integrable (fun x : ℝ => x) μ)
    (r T K : ℝ) (hK : μ {K} = 0) :
    Tendsto (fun h : ℝ => (callPrice μ r T (K - h) - callPrice μ r T (K + h)) / (2 * h))
        (𝓝[≠] 0) (𝓝 (exp (-(r * T)) * μ.real (Ioi K))) ∧
      HasDerivAt (fun k : ℝ => callPrice μ r T k) (-(exp (-(r * T)) * μ.real (Ioi K))) K := by
  have hint : Integrable (fun x : ℝ => max (x - K) 0) μ := (hμ.sub (integrable_const K)).pos_part
  have hae : ∀ᵐ x ∂μ, x ∉ ({K} : Set ℝ) := measure_eq_zero_iff_ae_notMem.1 hK
  obtain ⟨-, key⟩ := hasDerivAt_integral_of_dominated_loc_of_lip (μ := μ)
    (F := fun k x => max (x - k) 0) (F' := fun x => -((Ioi K).indicator 1 x))
    (bound := fun _ => (1 : ℝ)) (s := univ) univ_mem
    (Eventually.of_forall fun k => (by fun_prop : Continuous fun x : ℝ => max (x - k) 0).aestronglyMeasurable)
    hint
    ((measurable_const.indicator measurableSet_Ioi).neg.aestronglyMeasurable)
    (ae_of_all _ fun x => LipschitzOnWith.of_dist_le_mul fun a _ b _ => by
      simp only [Real.dist_eq]
      refine (abs_max_sub_max_le_abs _ _ _).trans ?_
      rw [show (x - a) - (x - b) = b - a by ring, abs_sub_comm]
      simp)
    (integrable_const _)
    (hae.mono fun x hx => by
      have hx' : x ≠ K := hx
      rcases lt_or_gt_of_ne hx' with hlt | hgt
      · have : (Ioi K).indicator (1 : ℝ → ℝ) x = 0 := indicator_of_notMem (by simpa using hlt.le) _
        rw [this, neg_zero]
        exact (hasDerivAt_const K (0 : ℝ)).congr_of_eventuallyEq
          ((eventually_gt_nhds hlt).mono fun k hk => max_eq_right (by linarith))
      · have : (Ioi K).indicator (1 : ℝ → ℝ) x = 1 := indicator_of_mem (by simpa using hgt) _
        rw [this]
        exact ((hasDerivAt_id K).const_sub x).congr_of_eventuallyEq
          ((eventually_lt_nhds hgt).mono fun k hk => max_eq_left (by linarith)))
  rw [integral_neg, integral_indicator_one measurableSet_Ioi] at key
  have hd : HasDerivAt (fun k : ℝ => callPrice μ r T k) (-(exp (-(r * T)) * μ.real (Ioi K))) K := by
    have := key.const_mul (exp (-(r * T)))
    unfold callPrice
    convert this using 1
    ring
  refine ⟨?_, hd⟩
  simpa using centered_quotient_tendsto_neg_deriv hd

/-- **The skew term** (The formula; Why it works, Steps 3 and 4). Suppose the market prices
each strike `k` at its own volatility `σ(k)` through Black-Scholes, so the market call is
`C(k) = C_BS(k, σ(k))`, with today's price `S > 0`, strike `K > 0`, time `T > 0`, a positive
volatility `σ(K)` at the strike, and a smooth smile at the strike: `σ` has slope `σ'` at `K`.
Then the market call has slope `-(e^(-rT) N(d₂) - 𝒱 σ'(K))` at `K`, so the market digital,
minus that slope, is `e^(-rT) N(d₂) - 𝒱 σ'(K)` (with `d₂` and vega `𝒱` taken at `σ(K)`), and
the tight centered market call spread tends to that same price. -/
theorem market_digital_eq_bs_digital_sub_vega_mul_smile_slope
    (S K r q T : ℝ) (σ : ℝ → ℝ) (σ' : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hσK : 0 < σ K) (hσ' : HasDerivAt σ σ' K) :
    HasDerivAt (fun k : ℝ => bsCall S k r q (σ k) T)
        (-(exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 S K r q (σ K) T) -
            bsVega S K r q (σ K) T * σ'))
        K ∧
      Tendsto
        (fun h : ℝ =>
          (bsCall S (K - h) r q (σ (K - h)) T - bsCall S (K + h) r q (σ (K + h)) T) / (2 * h))
        (𝓝[≠] 0)
        (𝓝 (exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 S K r q (σ K) T) -
            bsVega S K r q (σ K) T * σ')) := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hσT : σ K * √T ≠ 0 := (mul_pos hσK hsT).ne'
  have hdiv := (hasDerivAt_const K S).div (hasDerivAt_id' K) hK.ne'
  have hD1 := ((hdiv.log (by simpa using (div_pos hS hK).ne')).add
      ((((hσ'.pow 2).div_const 2).const_add (r - q)).mul_const T)).div
      (hσ'.mul_const √T) hσT
  obtain ⟨a, ha⟩ : ∃ a, HasDerivAt (fun k => bsD1 S k r q (σ k) T) a K := ⟨_, hD1⟩
  have ha2 : HasDerivAt (fun k => bsD2 S k r q (σ k) T) (a - σ' * √T) K := by
    unfold bsD2
    exact ha.sub (hσ'.mul_const √T)
  have hN1 := (stdNormal_cdf_hasDerivAt (bsD1 S K r q (σ K) T)).comp K ha
  have hN2 := (stdNormal_cdf_hasDerivAt (bsD2 S K r q (σ K) T)).comp K ha2
  have hd0 := (hN1.const_mul (S * exp (-(q * T)))).sub
      (((hasDerivAt_id' K).mul_const (exp (-(r * T)))).mul hN2)
  have hd : HasDerivAt (fun k => bsCall S k r q (σ k) T)
      (S * exp (-(q * T)) * (gaussianPDFReal 0 1 (bsD1 S K r q (σ K) T) * a) -
        (1 * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 S K r q (σ K) T) +
          K * exp (-(r * T)) * (gaussianPDFReal 0 1 (bsD2 S K r q (σ K) T) * (a - σ' * √T)))) K :=
    hd0
  have hid := bs_pdf_identity S K r q (σ K) T hS hK hT hσK
  have hd' : HasDerivAt (fun k : ℝ => bsCall S k r q (σ k) T)
      (-(exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD2 S K r q (σ K) T) -
          bsVega S K r q (σ K) T * σ')) K := by
    refine hd.congr_deriv ?_
    unfold bsVega
    linear_combination (-(a - σ' * √T)) * hid
  refine ⟨hd', ?_⟩
  simpa using centered_quotient_tendsto_neg_deriv hd'

/-- **The ramp squeezes into the step** (Why it works, Steps 0 and 1). For a spread of positive
half-width `h`, the payoff `(max (x - (K - h)) 0 - max (x - (K + h)) 0) / (2h)` is `0` at or below
`K - h`, exactly `1` at or above `K + h`, and between `0` and `1` in between; and at every
finishing price `x` other than the strike itself, it tends to the digital's step payoff
(`1` if `x > K`, `0` if not) as the half-width shrinks to `0`. -/
theorem ramp_payoff_tends_to_step_payoff (K : ℝ) :
    (∀ h x : ℝ, 0 < h →
      (x ≤ K - h → rampPayoff K h x = 0) ∧ (K + h ≤ x → rampPayoff K h x = 1) ∧
        0 ≤ rampPayoff K h x ∧ rampPayoff K h x ≤ 1) ∧
      ∀ x : ℝ, x ≠ K →
        Tendsto (fun h : ℝ => rampPayoff K h x) (𝓝[>] 0)
          (𝓝 (if K < x then (1 : ℝ) else 0)) := by
  have part1 : ∀ h x : ℝ, 0 < h →
      (x ≤ K - h → rampPayoff K h x = 0) ∧ (K + h ≤ x → rampPayoff K h x = 1) ∧
        0 ≤ rampPayoff K h x ∧ rampPayoff K h x ≤ 1 := by
    intro h x hh
    unfold rampPayoff
    refine ⟨fun hx => ?_, fun hx => ?_, ?_, ?_⟩
    · rw [max_eq_right (by linarith), max_eq_right (by linarith)]; simp
    · rw [max_eq_left (by linarith), max_eq_left (by linarith)]; field_simp; ring
    · apply div_nonneg _ (by linarith)
      simp only [max_def]; split_ifs <;> linarith
    · rw [div_le_one (by linarith)]
      simp only [max_def]; split_ifs <;> linarith
  refine ⟨part1, fun x hx => ?_⟩
  rcases lt_or_gt_of_ne hx with hlt | hgt
  · rw [ite_eq_right_iff.2 (fun h => absurd h (by linarith))]
    refine tendsto_const_nhds.congr' ?_
    filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < K - x by linarith)] with h hh
    exact ((part1 h x hh.1).1 (by linarith [hh.2])).symm
  · simp only [hgt, ite_true]
    refine tendsto_const_nhds.congr' ?_
    filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < x - K by linarith)] with h hh
    exact ((part1 h x hh.1).2.1 (by linarith [hh.2])).symm

/-! The card's exact worked numbers, for Acme: `S = K = 100`, `r = 5/100`, `q = 2/100`,
`σ = 1/5`, `T = 1`, smile slope `-4/10000` per dollar, spread `99/101` so `h = 1`. -/

-- The picture: the 99/101 ramp pays 0 at 97, 1/4 at 99.5, 1/2 at 100, 3/4 at 100.5, 1 at 103.
example : rampPayoff 100 1 97 = 0 := by norm_num [rampPayoff]
example : rampPayoff 100 1 (199 / 2) = 1 / 4 := by norm_num [rampPayoff]
example : rampPayoff 100 1 100 = 1 / 2 := by norm_num [rampPayoff]
example : rampPayoff 100 1 (201 / 2) = 3 / 4 := by norm_num [rampPayoff]
example : rampPayoff 100 1 103 = 1 := by norm_num [rampPayoff]

-- d₁ = (ln(100/100) + (0.05 - 0.02 + 0.02) · 1) / (0.20 · √1) = 0.25, and d₂ = 0.25 - 0.20 = 0.05.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by norm_num [bsD1]
example : bsD2 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 20 := by norm_num [bsD2, bsD1]

-- A volatility point is 0.01: a skew of -0.04 points per dollar is σ'(K) = -0.0004.
example : (-4 / 100 : ℚ) * (1 / 100) = -4 / 10000 := by norm_num

-- The smile σ(K) = 0.20 - 0.0004 (K - 100) gives 0.2004 at 99 and 0.1996 at 101.
example : (1 / 5 : ℚ) - 4 / 10000 * (99 - 100) = 2004 / 10000 := by norm_num
example : (1 / 5 : ℚ) - 4 / 10000 * (101 - 100) = 1996 / 10000 := by norm_num

-- The 99/101 spread from the printed calls: (9.731084 - 8.741874) / 2 = 0.494605.
example : ((9731084 : ℚ) / 1000000 - 8741874 / 1000000) / 2 = 494605 / 1000000 := by norm_num

-- The sandwich: 0.500463 < 0.509742 < 0.519031.
example : (500463 : ℚ) / 1000000 < 509742 / 1000000 ∧
    (509742 : ℚ) / 1000000 < 519031 / 1000000 := by norm_num

#print axioms digital_eq_limit_of_call_spread_eq_neg_strike_slope
#print axioms market_digital_eq_bs_digital_sub_vega_mul_smile_slope
#print axioms ramp_payoff_tends_to_step_payoff
