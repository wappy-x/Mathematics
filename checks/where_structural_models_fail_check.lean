-- Where structural models break: in Merton's model with assets above the debt the credit spread is capped by the default chance per year and falls to zero as the maturity shrinks, while a flat-hazard model keeps a short spread of hazard times loss.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Filter Topology ProbabilityTheory

noncomputable section

namespace WhereStructuralModelsFail

/-- `N x`: the standard normal chance of landing below `x`. -/
def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- Merton's `d₁`: assets `V`, debt face `D`, riskless rate `r`, volatility `σ`, maturity `T`. -/
def d1 (V D r σ T : ℝ) : ℝ :=
  (Real.log (V / D) + (r + σ ^ 2 / 2) * T) / (σ * Real.sqrt T)

/-- Merton's `d₂ = d₁ - σ √T`, the standardised distance of assets above debt. -/
def d2 (V D r σ T : ℝ) : ℝ := d1 V D r σ T - σ * Real.sqrt T

/-- The default put `P(T) = D e^{-rT} N(-d₂) - V N(-d₁)`. -/
def mertonPut (V D r σ T : ℝ) : ℝ :=
  D * Real.exp (-r * T) * N (-d2 V D r σ T) - V * N (-d1 V D r σ T)

/-- Merton's credit spread `s(T) = -(1/T) ln(1 - P(T) / (D e^{-rT}))`. -/
def mertonSpread (V D r σ T : ℝ) : ℝ :=
  -(1 / T) * Real.log (1 - mertonPut V D r σ T / (D * Real.exp (-r * T)))

/-- Flat-hazard zero-bond spread `s(T) = -(1/T) ln(1 - (1-R)(1 - e^{-λT}))`
with hazard `λ` and recovery `R` of face paid at maturity. -/
def hazardSpread (lam R T : ℝ) : ℝ :=
  -(1 / T) * Real.log (1 - (1 - R) * (1 - Real.exp (-lam * T)))

lemma N_nonneg (x : ℝ) : 0 ≤ N x := cdf_nonneg _ x

lemma N_lt_one (x : ℝ) : N x < 1 := by
  unfold N
  rw [cdf_eq_real, ← Set.compl_Ioi, MeasureTheory.probReal_compl_eq_one_sub measurableSet_Ioi]
  have hne : gaussianReal 0 1 (Set.Ioi x) ≠ 0 := by
    intro h
    have := gaussianReal_absolutelyContinuous' (0 : ℝ) (v := 1) one_ne_zero h
    simp at this
  have : 0 < (gaussianReal 0 1).real (Set.Ioi x) :=
    ENNReal.toReal_pos hne (MeasureTheory.measure_ne_top _ _)
  linarith

lemma N_neg_le_exp (x : ℝ) (hx : 0 ≤ x) : N (-x) ≤ Real.exp (-x ^ 2 / 2) := by
  unfold N
  rw [cdf_eq_real]
  have h := measure_le_le_exp_mul_mgf (X := id) (μ := gaussianReal 0 1) (-x) (t := -x)
    (by linarith) (integrable_exp_mul_gaussianReal _)
  rw [mgf_id_gaussianReal] at h
  have hs : {ω : ℝ | id ω ≤ -x} = Set.Iic (-x) := by ext; simp
  rw [hs, ← Real.exp_add] at h
  convert h using 2
  push_cast
  ring

lemma N_neg_le (x : ℝ) (hx : 0 < x) : N (-x) ≤ 16 / x ^ 4 := by
  refine (N_neg_le_exp x hx.le).trans ?_
  have h1 : 1 + x ^ 2 / 4 ≤ Real.exp (x ^ 2 / 4) := by
    have := Real.add_one_le_exp (x ^ 2 / 4); linarith
  have h2 : Real.exp (x ^ 2 / 2) = Real.exp (x ^ 2 / 4) ^ 2 := by
    rw [← Real.exp_nat_mul]; ring_nf
  have h3 : x ^ 4 / 16 ≤ Real.exp (x ^ 2 / 2) := by
    rw [h2]; nlinarith [sq_nonneg x]
  rw [show -x ^ 2 / 2 = -(x ^ 2 / 2) by ring, Real.exp_neg, le_div_iff₀ (by positivity)]
  have hpos := Real.exp_pos (x ^ 2 / 2)
  rw [inv_mul_eq_div, div_le_iff₀ hpos]
  linarith

lemma tail_div_tendsto (c b σ : ℝ) (hc : 0 < c) (hσ : 0 < σ) :
    Tendsto (fun T => N (-((c + b * T) / (σ * Real.sqrt T))) / T) (𝓝[>] 0) (𝓝 0) := by
  have hup : Tendsto (fun T : ℝ => (256 * σ ^ 4 / c ^ 4) * T) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun T : ℝ => (256 * σ ^ 4 / c ^ 4) * T) (𝓝 0) (𝓝 ((256 * σ ^ 4 / c ^ 4) * 0)) :=
      (continuous_const.mul continuous_id).tendsto 0
    simpa using this.mono_left nhdsWithin_le_nhds
  have hT0 : 0 < c / (2 * (|b| + 1)) := by positivity
  have hev : ∀ᶠ T in 𝓝[>] (0:ℝ), T ∈ Set.Ioo 0 (c / (2 * (|b| + 1))) :=
    Ioo_mem_nhdsGT hT0
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hup ?_ ?_
  · filter_upwards [hev] with T hT
    exact div_nonneg (N_nonneg _) hT.1.le
  · filter_upwards [hev] with T hT
    obtain ⟨hT, hTlt⟩ := hT
    have hsq : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
    have hsq2 : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
    have hbT : |b| * T ≤ c / 2 := by
      have h1 : T * (2 * (|b| + 1)) < c := (lt_div_iff₀ (by positivity)).mp hTlt
      nlinarith [abs_nonneg b]
    have hcb : c / 2 ≤ c + b * T := by
      have := neg_abs_le b
      nlinarith
    set d := (c + b * T) / (σ * Real.sqrt T) with hd
    have hden : 0 < σ * Real.sqrt T := by positivity
    have hdpos : 0 < d := div_pos (by linarith) hden
    have hdmul : d * (σ * Real.sqrt T) = c + b * T := by rw [hd]; field_simp
    have hd4 : (c / 2) ^ 4 ≤ d ^ 4 * σ ^ 4 * T ^ 2 := by
      have : (c / 2) ^ 4 ≤ (d * (σ * Real.sqrt T)) ^ 4 := by
        rw [hdmul]; exact pow_le_pow_left₀ (by positivity) hcb 4
      calc (c / 2) ^ 4 ≤ (d * (σ * Real.sqrt T)) ^ 4 := this
        _ = d ^ 4 * σ ^ 4 * (Real.sqrt T ^ 2) ^ 2 := by ring
        _ = d ^ 4 * σ ^ 4 * T ^ 2 := by rw [hsq2]
    calc N (-d) / T ≤ (16 / d ^ 4) / T := by
          gcongr; exact N_neg_le d hdpos
      _ ≤ (256 * σ ^ 4 / c ^ 4) * T := by
          rw [div_div, div_le_iff₀ (by positivity)]
          have : 16 * c ^ 4 ≤ 256 * σ ^ 4 * T ^ 2 * d ^ 4 := by nlinarith
          calc (16:ℝ) = 16 * c ^ 4 / c ^ 4 := by field_simp
            _ ≤ 256 * σ ^ 4 * T ^ 2 * d ^ 4 / c ^ 4 := by gcongr
            _ = 256 * σ ^ 4 / c ^ 4 * T * (d ^ 4 * T) := by ring

/-- The put scaled by the discounted face is `N(-d₂)` minus a nonnegative term. -/
lemma put_ratio_eq (V D r σ T : ℝ) (hD : 0 < D) :
    mertonPut V D r σ T / (D * Real.exp (-r * T)) =
      N (-d2 V D r σ T) - V / D * Real.exp (r * T) * N (-d1 V D r σ T) := by
  have hK : 0 < D * Real.exp (-r * T) := by positivity
  have he : Real.exp (-r * T) * Real.exp (r * T) = 1 := by
    rw [← Real.exp_add]; simp
  unfold mertonPut
  simp only [neg_mul, Real.exp_neg]
  field_simp

/-- `d₂` written in the same shape as `d₁`, with drift `r - σ²/2`. -/
lemma d2_eq (V D r σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    d2 V D r σ T = (Real.log (V / D) + (r - σ ^ 2 / 2) * T) / (σ * Real.sqrt T) := by
  have hs : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hs2 : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
  unfold d2 d1
  field_simp
  rw [hs2]
  ring

/-- Helper: the bound of Step 1, proved before the main claim uses it. -/
lemma merton_spread_le_aux (V D r σ T : ℝ) (hV : 0 < V) (hD : 0 < D)
    (hσ : 0 < σ) (hT : 0 < T) :
    mertonSpread V D r σ T ≤ N (-d2 V D r σ T) / (T * (1 - N (-d2 V D r σ T))) := by
  unfold mertonSpread
  rw [put_ratio_eq V D r σ T hD]
  set p := N (-d2 V D r σ T)
  set q := p - V / D * Real.exp (r * T) * N (-d1 V D r σ T)
  have hp1 : p < 1 := N_lt_one _
  have hqp : q ≤ p := by
    have : 0 ≤ V / D * Real.exp (r * T) * N (-d1 V D r σ T) := by
      have := N_nonneg (-d1 V D r σ T); positivity
    linarith
  have h1q : 0 < 1 - q := by linarith
  have h1p : 0 < 1 - p := by linarith
  have hlog : -Real.log (1 - q) ≤ (1 - q)⁻¹ - 1 := by
    have := Real.log_le_sub_one_of_pos (inv_pos.mpr h1q)
    rwa [Real.log_inv] at this
  have hfrac : (1 - q)⁻¹ - 1 ≤ p / (1 - p) := by
    rw [show (1 - q)⁻¹ - 1 = q / (1 - q) by field_simp; ring, div_le_div_iff₀ h1q h1p]
    nlinarith
  calc -(1 / T) * Real.log (1 - q) = (1 / T) * (-Real.log (1 - q)) := by ring
    _ ≤ (1 / T) * (p / (1 - p)) := by gcongr; linarith
    _ = p / (T * (1 - p)) := by field_simp

#print axioms N_nonneg
#print axioms N_lt_one
#print axioms N_neg_le_exp
#print axioms N_neg_le
#print axioms tail_div_tendsto
#print axioms put_ratio_eq
#print axioms d2_eq
#print axioms merton_spread_le_aux

/-- The card's main claim: in Merton's model (assets move without jumps and are seen
exactly), if the assets are above the debt today (`V > D`), the credit spread falls to
zero as the maturity `T` shrinks to zero. -/
theorem merton_spread_tendsto_zero (V D r σ : ℝ) (hD : 0 < D) (hσ : 0 < σ) (hVD : D < V) :
    Tendsto (fun T => mertonSpread V D r σ T) (𝓝[>] 0) (𝓝 0) := by
  have hV : 0 < V := hD.trans hVD
  have hc : 0 < Real.log (V / D) := Real.log_pos ((one_lt_div hD).mpr hVD)
  -- `N(-d₂)/T → 0` and `N(-d₁)/T → 0`
  have h2 : Tendsto (fun T => N (-d2 V D r σ T) / T) (𝓝[>] 0) (𝓝 0) := by
    refine (tail_div_tendsto _ (r - σ ^ 2 / 2) σ hc hσ).congr' ?_
    filter_upwards [self_mem_nhdsWithin] with T hT
    rw [d2_eq V D r σ T hσ hT]
  have h1 : Tendsto (fun T => N (-d1 V D r σ T) / T) (𝓝[>] 0) (𝓝 0) :=
    tail_div_tendsto _ (r + σ ^ 2 / 2) σ hc hσ
  have hid : Tendsto (fun T : ℝ => T) (𝓝[>] 0) (𝓝 0) :=
    tendsto_nhdsWithin_of_tendsto_nhds tendsto_id
  -- `N(-d₂) → 0`
  have hp : Tendsto (fun T => N (-d2 V D r σ T)) (𝓝[>] 0) (𝓝 0) := by
    have := h2.mul hid
    rw [zero_mul] at this
    refine this.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with T hT
    field_simp [ne_of_gt (show (0:ℝ) < T from hT)]
  have hup : Tendsto (fun T => N (-d2 V D r σ T) / T / (1 - N (-d2 V D r σ T)))
      (𝓝[>] 0) (𝓝 0) := by
    have := h2.div (tendsto_const_nhds.sub hp) (by norm_num : (1:ℝ) - 0 ≠ 0)
    rw [sub_zero, zero_div] at this
    exact this
  have hexp : Tendsto (fun T : ℝ => Real.exp (r * T)) (𝓝[>] 0) (𝓝 1) := by
    have : Tendsto (fun T : ℝ => Real.exp (r * T)) (𝓝 0) (𝓝 (Real.exp (r * 0))) :=
      ((continuous_const.mul continuous_id).rexp).tendsto 0
    simpa using this.mono_left nhdsWithin_le_nhds
  have hlow : Tendsto (fun T => -(V / D) * Real.exp (r * T) * (N (-d1 V D r σ T) / T))
      (𝓝[>] 0) (𝓝 0) := by
    have := (tendsto_const_nhds (x := -(V / D))).mul hexp |>.mul h1
    simpa using this
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow hup ?_ ?_
  · filter_upwards [self_mem_nhdsWithin] with T hT
    have hT : (0:ℝ) < T := hT
    unfold mertonSpread
    rw [put_ratio_eq V D r σ T hD]
    set p := N (-d2 V D r σ T)
    set n1 := N (-d1 V D r σ T)
    have hp1 : p < 1 := N_lt_one _
    have hp0 : 0 ≤ p := N_nonneg _
    have hm : 0 ≤ V / D * Real.exp (r * T) * n1 := by
      have := N_nonneg (-d1 V D r σ T); positivity
    have h1q : 0 < 1 - (p - V / D * Real.exp (r * T) * n1) := by linarith
    have hlog := Real.log_le_sub_one_of_pos h1q
    calc -(V / D) * Real.exp (r * T) * (n1 / T)
        = (1 / T) * (-(V / D * Real.exp (r * T) * n1)) := by field_simp
      _ ≤ (1 / T) * (-Real.log (1 - (p - V / D * Real.exp (r * T) * n1))) := by
          gcongr; linarith
      _ = _ := by ring
  · filter_upwards [self_mem_nhdsWithin] with T hT
    have hT : (0:ℝ) < T := hT
    refine (merton_spread_le_aux V D r σ T hV hD hσ hT).trans_eq ?_
    rw [div_div, mul_comm T]

/-- Step 1: the Merton spread is at most the default chance per year of waiting,
`s(T) ≤ N(-d₂) / (T (1 - N(-d₂)))`. -/
theorem merton_spread_le_default_chance (V D r σ T : ℝ) (hV : 0 < V) (hD : 0 < D)
    (hσ : 0 < σ) (hT : 0 < T) :
    mertonSpread V D r σ T ≤ N (-d2 V D r σ T) / (T * (1 - N (-d2 V D r σ T))) := by
  exact merton_spread_le_aux V D r σ T hV hD hσ hT

/-- Step 4: with a flat hazard `λ` and recovery `R`, the short spread does not vanish:
it tends to `λ (1 - R)` as the maturity shrinks. -/
theorem hazard_spread_tendsto (lam R : ℝ) :
    Tendsto (fun T => hazardSpread lam R T) (𝓝[>] 0) (𝓝 (lam * (1 - R))) := by
  set f : ℝ → ℝ := fun T => Real.log (1 - (1 - R) * (1 - Real.exp (-lam * T))) with hf
  have hg : HasDerivAt (fun T : ℝ => 1 - (1 - R) * (1 - Real.exp (-lam * T)))
      (-((1 - R) * (-(Real.exp (-lam * 0) * (-lam * 1))))) 0 := by
    have h := ((hasDerivAt_id (0:ℝ)).const_mul (-lam)).exp
    exact ((h.const_sub 1).const_mul (1 - R)).const_sub 1
  have hd : HasDerivAt f (-(lam * (1 - R))) 0 := by
    have := hg.log (by simp)
    convert this using 1
    simp; ring
  have := hd.tendsto_slope_zero_right.neg
  rw [neg_neg] at this
  refine this.congr' ?_
  filter_upwards with T
  simp [hf, hazardSpread, smul_eq_mul]

/-- The card's flat-hazard example: a 2% hazard with 40% recovery gives a short-end
spread of 120 basis points. -/
example : (2 / 100 : ℝ) * (1 - 40 / 100) * 10000 = 120 := by norm_num

#print axioms merton_spread_tendsto_zero
#print axioms merton_spread_le_default_chance
#print axioms hazard_spread_tendsto
