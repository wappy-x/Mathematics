-- Swaption Greeks: in Black's model the swaption's slope in the forward swap rate, counted per unit of annuity, is N(d₁), its gamma, vega and time decay have the card's closed forms with decay equal to half σ²F² times gamma, and on a flat curve the dollar hedge ratio in forward swaps is N(d₁) + (A′/A)·B, strictly below N(d₁).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Real MeasureTheory ProbabilityTheory Set Finset

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x)`: the bell curve's height at `x`, the standard normal density. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- `d₁ = (ln(F/K) + σ²T/2) / (σ√T)`; the second distance is `d₂ = d₁ - σ√T`. -/
noncomputable def blackD1 (F K σ T : ℝ) : ℝ :=
  (log (F / K) + σ ^ 2 * T / 2) / (σ * √T)

/-- `B = F N(d₁) - K N(d₂)`: the swaption's value per unit of annuity, a Black call on the
forward swap rate `F` struck at `K`. -/
noncomputable def blackB (F K σ T : ℝ) : ℝ :=
  F * stdNormalCDF (blackD1 F K σ T) - K * stdNormalCDF (blackD1 F K σ T - σ * √T)

/-- The discount factor on a flat curve at yearly rate `y`: `D(t) = (1 + y)^(-t)`. -/
noncomputable def discount (y : ℝ) (t : ℕ) : ℝ := ((1 + y) ^ t)⁻¹

/-- The annuity of an `m`-into-`n` swap with yearly fixed payments: `1` paid on each of the dates
`m + 1, …, m + n`, discounted on the flat curve at `y`. -/
noncomputable def annuity (m n : ℕ) (y : ℝ) : ℝ :=
  ∑ i ∈ range n, discount y (m + i + 1)

/-- The forward swap rate: `F = (D(m) - D(m + n)) / A`, the fixed rate that makes the swap
starting at year `m` worth zero today. -/
noncomputable def forwardSwapRate (m n : ℕ) (y : ℝ) : ℝ :=
  (discount y m - discount y (m + n)) / annuity m n y

/-- The payer swaption's dollar value on the flat curve at `y`: notional `M`, times the annuity,
times Black's call on the forward swap rate, with expiry `T = m` years (the swap's start). -/
noncomputable def swaptionValue (M K σ : ℝ) (m n : ℕ) (y : ℝ) : ℝ :=
  M * annuity m n y * blackB (forwardSwapRate m n y) K σ m

/-- The dollar value of a forward swap paying fixed `F₀` from year `m` for `n` years on notional
`M`: `M A (F - F₀)`. -/
noncomputable def forwardSwapValue (M F₀ : ℝ) (m n : ℕ) (y : ℝ) : ℝ :=
  M * annuity m n y * (forwardSwapRate m n y - F₀)

lemma stdNormalPDF_eq (x : ℝ) : stdNormalPDF x = (√(2 * π))⁻¹ * rexp (-x ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

lemma stdNormalPDF_pos (x : ℝ) : 0 < stdNormalPDF x := by
  rw [stdNormalPDF_eq]; positivity

lemma continuous_stdNormalPDF : Continuous stdNormalPDF := by
  have : stdNormalPDF = fun x ↦ (√(2 * π))⁻¹ * rexp (-x ^ 2 / 2) := funext stdNormalPDF_eq
  rw [this]; fun_prop

lemma stdNormalCDF_eq (x : ℝ) : stdNormalCDF x = ∫ t in Iic x, stdNormalPDF t := by
  unfold stdNormalCDF stdNormalPDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact integral_nonneg (fun _ ↦ gaussianPDFReal_nonneg _ _ _)

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF x) x := by
  have hint : ∀ a, IntegrableOn stdNormalPDF (Iic a) := fun a ↦
    (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : stdNormalCDF = fun u ↦ stdNormalCDF 0 + ∫ t in (0:ℝ)..u, stdNormalPDF t := by
    funext u
    rw [stdNormalCDF_eq, stdNormalCDF_eq, ← intervalIntegral.integral_Iic_sub_Iic (hint 0) (hint u)]
    ring
  rw [heq]
  exact ((continuous_stdNormalPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma stdNormalCDF_strictMono : StrictMono stdNormalCDF :=
  strictMono_of_deriv_pos fun x ↦ (hasDerivAt_stdNormalCDF x).deriv ▸ stdNormalPDF_pos x

lemma stdNormalCDF_pos (x : ℝ) : 0 < stdNormalCDF x :=
  lt_of_le_of_lt (cdf_nonneg _ _) (stdNormalCDF_strictMono (show x - 1 < x by linarith))

/-- The height identity `F φ(d₁) = K φ(d₁ - σ√T)`. -/
lemma black_height_identity (F K σ T : ℝ)
    (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    F * stdNormalPDF (blackD1 F K σ T) = K * stdNormalPDF (blackD1 F K σ T - σ * √T) := by
  set d := blackD1 F K σ T with hd
  set s := σ * √T with hs
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hs0 : 0 < s := mul_pos hσ hsT
  have hs2 : s ^ 2 = σ ^ 2 * T := by rw [hs, mul_pow, sq_sqrt hT.le]
  have hds : d * s = log (F / K) + s ^ 2 / 2 := by
    rw [hd, blackD1, ← hs, hs2]; field_simp
  have hexp : -(d - s) ^ 2 / 2 = -d ^ 2 / 2 + log (F / K) := by linear_combination hds
  rw [stdNormalPDF_eq, stdNormalPDF_eq, hexp, exp_add, exp_log (div_pos hF hK)]
  field_simp

lemma hasDerivAt_blackD1_F (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun f ↦ blackD1 f K σ T) (1 / (F * σ * √T)) F := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have h1 : HasDerivAt (fun f ↦ f / K) (1 / K) F := (hasDerivAt_id F).div_const K
  have h2 := (h1.log (div_pos hF hK).ne').add_const (σ ^ 2 * T / 2)
  have h3 := h2.div_const (σ * √T)
  refine HasDerivAt.congr_deriv (f := fun f ↦ blackD1 f K σ T) h3 ?_
  field_simp

/-- Delta in `F` of the value per unit of annuity. -/
lemma hasDerivAt_blackB_F (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun f ↦ blackB f K σ T) (stdNormalCDF (blackD1 F K σ T)) F := by
  have hd := hasDerivAt_blackD1_F F K σ T hF hK hσ hT
  have hN1 := (hasDerivAt_stdNormalCDF (blackD1 F K σ T)).comp F hd
  have hN2 := (hasDerivAt_stdNormalCDF (blackD1 F K σ T - σ * √T)).comp F
    (hd.sub_const (σ * √T))
  have h := ((hasDerivAt_id F).mul hN1).sub (hN2.const_mul K)
  refine HasDerivAt.congr_deriv (f := fun f ↦ blackB f K σ T) h ?_
  have hid := black_height_identity F K σ T hF hK hσ hT
  simp only [id, Function.comp]
  linear_combination (1 / (F * σ * √T)) * hid

open Filter Topology in
lemma blackB_pos (F K σ T : ℝ) (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    0 < blackB F K σ T := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hmono : StrictMonoOn (fun f ↦ blackB f K σ T) (Ioi 0) := by
    apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
    · intro x hx
      exact (hasDerivAt_blackB_F x K σ T hx hK hσ hT).continuousAt.continuousWithinAt
    · intro x hx
      rw [interior_Ioi] at hx
      rw [(hasDerivAt_blackB_F x K σ T hx hK hσ hT).deriv]
      exact stdNormalCDF_pos _
  -- lower bound by `-K N(d₂)`, which tends to `0` as `f → 0⁺`
  have hlim : Tendsto (fun f ↦ -K * stdNormalCDF (blackD1 f K σ T - σ * √T)) (𝓝[>] 0)
      (𝓝 (-K * 0)) := by
    have h1 : Tendsto (fun f ↦ log f - log K + σ ^ 2 * T / 2) (𝓝[>] (0:ℝ)) atBot :=
      tendsto_atBot_add_const_right _ _ (tendsto_atBot_add_const_right _ _ tendsto_log_nhdsGT_zero)
    have h2 := tendsto_atBot_add_const_right _ (-(σ * √T)) (h1.atBot_div_const (mul_pos hσ hsT))
    have h3 : Tendsto (fun f ↦ blackD1 f K σ T - σ * √T) (𝓝[>] (0:ℝ)) atBot := by
      refine h2.congr' ?_
      filter_upwards [self_mem_nhdsWithin] with f hf
      rw [blackD1, log_div (ne_of_gt hf) hK.ne']
      ring
    exact (Filter.Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) h3).const_mul (-K)
  have hhalf : 0 ≤ blackB (F / 2) K σ T := by
    have := le_of_tendsto hlim (b := blackB (F / 2) K σ T) ?_
    · simpa using this
    have hF2 : (0:ℝ) < F / 2 := by positivity
    filter_upwards [Ioo_mem_nhdsGT hF2] with f hf
    have hlt := hmono hf.1 (show F / 2 ∈ Ioi (0:ℝ) from hF2) hf.2
    have : -K * stdNormalCDF (blackD1 f K σ T - σ * √T) ≤ blackB f K σ T := by
      have := mul_nonneg hf.1.le (cdf_nonneg (gaussianReal 0 1) (blackD1 f K σ T))
      simp only [blackB, stdNormalCDF] at *
      linarith
    exact this.trans hlt.le
  have := hmono (show F / 2 ∈ Ioi (0:ℝ) by simp; positivity) (show F ∈ Ioi (0:ℝ) from hF)
    (by linarith)
  linarith

lemma discount_sub_succ (y : ℝ) (hy : 1 + y ≠ 0) (k : ℕ) :
    discount y k - discount y (k + 1) = y * discount y (k + 1) := by
  unfold discount; rw [pow_succ]; field_simp; ring

lemma discount_telescope (y : ℝ) (hy : 1 + y ≠ 0) (m n : ℕ) :
    discount y m - discount y (m + n) = y * annuity m n y := by
  induction n with
  | zero => simp [annuity]
  | succ n ih =>
    simp only [annuity] at ih ⊢
    rw [sum_range_succ, ← add_assoc]
    linear_combination ih + discount_sub_succ y hy (m + n)

lemma annuity_pos (m n : ℕ) (y : ℝ) (hy : -1 < y) (hn : 0 < n) : 0 < annuity m n y := by
  have h1 : 0 < 1 + y := by linarith
  exact sum_pos (fun i _ ↦ by unfold discount; positivity) (nonempty_range_iff.mpr hn.ne')

lemma forwardSwapRate_eq (m n : ℕ) (y : ℝ) (hy : -1 < y) (hn : 0 < n) :
    forwardSwapRate m n y = y := by
  have h1 : 1 + y ≠ 0 := by linarith
  rw [forwardSwapRate, discount_telescope y h1, mul_div_assoc,
    div_self (annuity_pos m n y hy hn).ne', mul_one]

lemma hasDerivAt_discount (y : ℝ) (hy : -1 < y) (k : ℕ) (hk : 0 < k) :
    ∃ d, d < 0 ∧ HasDerivAt (fun z ↦ discount z k) d y := by
  have h1 : 0 < 1 + y := by linarith
  have hk' : (0:ℝ) < k := Nat.cast_pos.mpr hk
  refine ⟨_, ?_, (((hasDerivAt_id y).const_add 1).fun_pow k).inv (by simp only [id]; positivity)⟩
  simp only [id, mul_one]
  have : 0 < (k:ℝ) * (1 + y) ^ (k - 1) / ((1 + y) ^ k) ^ 2 := by positivity
  rw [neg_div]
  linarith

lemma hasDerivAt_annuity (m n : ℕ) (y : ℝ) (hy : -1 < y) (hn : 0 < n) :
    ∃ d, d < 0 ∧ HasDerivAt (annuity m n) d y := by
  have h := fun i : ℕ ↦ hasDerivAt_discount y hy (m + i + 1) (Nat.succ_pos _)
  choose d hd hD using h
  refine ⟨∑ i ∈ range n, d i, ?_, HasDerivAt.fun_sum (fun i _ ↦ hD i)⟩
  calc ∑ i ∈ range n, d i < ∑ i ∈ range n, (0:ℝ) :=
        sum_lt_sum_of_nonempty (nonempty_range_iff.mpr hn.ne') (fun i _ ↦ hd i)
    _ = 0 := by simp

#print axioms stdNormalPDF_eq
#print axioms stdNormalPDF_pos
#print axioms continuous_stdNormalPDF
#print axioms stdNormalCDF_eq
#print axioms hasDerivAt_stdNormalCDF
#print axioms stdNormalCDF_strictMono
#print axioms stdNormalCDF_pos
#print axioms black_height_identity
#print axioms hasDerivAt_blackD1_F
#print axioms hasDerivAt_blackB_F
#print axioms blackB_pos
#print axioms discount_sub_succ
#print axioms discount_telescope
#print axioms annuity_pos
#print axioms forwardSwapRate_eq
#print axioms hasDerivAt_discount
#print axioms hasDerivAt_annuity

/-- **The dollar hedge ratio sits below N(d₁)** (Step 2). In Black's lognormal model with one
constant volatility `σ > 0`, on one flat curve at a positive yearly rate `y` that both forecasts
and discounts and moves in parallel, take a payer swaption on notional `M > 0`, strike `K > 0`,
expiring in `m ≥ 1` years into an `n ≥ 1`-year swap with yearly fixed payments. Then the forward
swap rate equals `y`; the number of at-market forward swaps (fixed rate `F₀ = F` today) whose
dollar slope in `y` matches the swaption's is `h = N(d₁) + (A′/A) B`, with `A′` the annuity's
slope in `y` and `B = F N(d₁) - K N(d₂)` the value per unit of annuity; and `h` is strictly less
than the delta in swaps `N(d₁)`, because the annuity falls as rates rise. -/
theorem swaption_dollar_hedge_ratio_below_delta_in_swaps (M K σ y : ℝ) (m n : ℕ)
    (hM : 0 < M) (hK : 0 < K) (hσ : 0 < σ) (hy : 0 < y) (hm : 0 < m) (hn : 0 < n) :
    forwardSwapRate m n y = y ∧
      deriv (fun z ↦ swaptionValue M K σ m n z) y /
          deriv (fun z ↦ forwardSwapValue M (forwardSwapRate m n y) m n z) y =
        stdNormalCDF (blackD1 (forwardSwapRate m n y) K σ m) +
          deriv (annuity m n) y / annuity m n y * blackB (forwardSwapRate m n y) K σ m ∧
      stdNormalCDF (blackD1 (forwardSwapRate m n y) K σ m) +
          deriv (annuity m n) y / annuity m n y * blackB (forwardSwapRate m n y) K σ m <
        stdNormalCDF (blackD1 (forwardSwapRate m n y) K σ m) := by
  have hy1 : -1 < y := by linarith
  have hF : forwardSwapRate m n y = y := forwardSwapRate_eq m n y hy1 hn
  have hT : (0:ℝ) < m := Nat.cast_pos.mpr hm
  obtain ⟨A', hA'neg, hA⟩ := hasDerivAt_annuity m n y hy1 hn
  have hApos := annuity_pos m n y hy1 hn
  have hB := blackB_pos y K σ m hy hK hσ hT
  have hBd := hasDerivAt_blackB_F y K σ m hy hK hσ hT
  have hev : ∀ᶠ z in nhds y, forwardSwapRate m n z = z := by
    filter_upwards [Ioi_mem_nhds hy1] with z hz using forwardSwapRate_eq m n z hz hn
  have hS : HasDerivAt (fun z ↦ swaptionValue M K σ m n z)
      (M * (A' * blackB y K σ m + annuity m n y * stdNormalCDF (blackD1 y K σ m))) y := by
    have h := (hA.const_mul M).mul hBd
    refine (h.congr_of_eventuallyEq ?_).congr_deriv ?_
    · filter_upwards [hev] with z hz
      simp [swaptionValue, hz]
    · ring
  have hV : HasDerivAt (fun z ↦ forwardSwapValue M y m n z) (M * annuity m n y) y := by
    have h := (hA.const_mul M).mul ((hasDerivAt_id y).sub_const y)
    refine (h.congr_of_eventuallyEq ?_).congr_deriv ?_
    · filter_upwards [hev] with z hz
      simp [forwardSwapValue, hz]
    · simp
  rw [hF, hS.deriv, hV.deriv, hA.deriv]
  refine ⟨rfl, ?_, ?_⟩
  · field_simp
    ring
  · have : A' / annuity m n y * blackB y K σ m < 0 :=
      mul_neg_of_neg_of_pos (div_neg_of_neg_of_pos hA'neg hApos) hB
    linarith

/-- **Delta in swaps is N(d₁)** (Step 0 and Step 1). For a forward swap rate `F > 0`, strike
`K > 0`, volatility `σ > 0` and expiry `T > 0`, the two height terms cancel exactly,
`F φ(d₁) = K φ(d₂)`, and so the slope in `F` of the value per unit of annuity,
`F N(d₁) - K N(d₂)`, is exactly `N(d₁)`. -/
theorem delta_in_swaps_is_N_d1 (F K σ T : ℝ)
    (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    F * stdNormalPDF (blackD1 F K σ T) = K * stdNormalPDF (blackD1 F K σ T - σ * √T) ∧
      deriv (fun f ↦ blackB f K σ T) F = stdNormalCDF (blackD1 F K σ T) := by
  exact ⟨black_height_identity F K σ T hF hK hσ hT, (hasDerivAt_blackB_F F K σ T hF hK hσ hT).deriv⟩

/-- **Gamma, vega and theta in annuity units** (Steps 3 to 5). For `F > 0`, `K > 0`, `σ > 0`,
`T > 0`: gamma, the slope of `N(d₁)` in `F`, is `φ(d₁) / (F σ √T)`; vega, the slope of the value
per unit of annuity in `σ`, is `F φ(d₁) √T`; and the decay, its slope in the time left `T`, is
`F φ(d₁) σ / (2√T)`, which is exactly `½ σ² F²` times gamma: theta pays for gamma. -/
theorem gamma_vega_and_theta_pays_for_gamma (F K σ T : ℝ)
    (hF : 0 < F) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    deriv (fun f ↦ stdNormalCDF (blackD1 f K σ T)) F =
        stdNormalPDF (blackD1 F K σ T) / (F * σ * √T) ∧
      deriv (fun s ↦ blackB F K s T) σ = F * stdNormalPDF (blackD1 F K σ T) * √T ∧
      deriv (fun t ↦ blackB F K σ t) T = F * stdNormalPDF (blackD1 F K σ T) * σ / (2 * √T) ∧
      deriv (fun t ↦ blackB F K σ t) T =
        σ ^ 2 * F ^ 2 / 2 * (stdNormalPDF (blackD1 F K σ T) / (F * σ * √T)) := by
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hid := black_height_identity F K σ T hF hK hσ hT
  have hgamma : deriv (fun f ↦ stdNormalCDF (blackD1 f K σ T)) F =
      stdNormalPDF (blackD1 F K σ T) / (F * σ * √T) := by
    have h := (hasDerivAt_stdNormalCDF (blackD1 F K σ T)).comp F
      (hasDerivAt_blackD1_F F K σ T hF hK hσ hT)
    rw [show (fun f ↦ stdNormalCDF (blackD1 f K σ T)) =
      stdNormalCDF ∘ (fun f ↦ blackD1 f K σ T) from rfl, h.deriv]
    ring
  -- vega
  obtain ⟨Dv, hDv⟩ : ∃ D, HasDerivAt (fun s ↦ blackD1 F K s T) D σ := by
    have hnum := (((hasDerivAt_pow 2 σ).mul_const T).div_const 2).const_add (log (F / K))
    have hden := (hasDerivAt_id σ).mul_const √T
    exact ⟨_, hnum.div hden (by positivity)⟩
  have hvega : deriv (fun s ↦ blackB F K s T) σ = F * stdNormalPDF (blackD1 F K σ T) * √T := by
    have hN1 := (hasDerivAt_stdNormalCDF (blackD1 F K σ T)).comp σ hDv
    have hN2 := (hasDerivAt_stdNormalCDF (blackD1 F K σ T - σ * √T)).comp σ
      (hDv.sub ((hasDerivAt_id σ).mul_const √T))
    have h := (hN1.const_mul F).sub (hN2.const_mul K)
    have h' : HasDerivAt (fun s ↦ blackB F K s T)
        (F * (stdNormalPDF (blackD1 F K σ T) * Dv) -
          K * (stdNormalPDF (blackD1 F K σ T - σ * √T) * (Dv - 1 * √T))) σ := h
    rw [h'.deriv]
    simp only [id] at *
    linear_combination (Dv - √T) * hid
  -- theta
  obtain ⟨Dt, hDt⟩ : ∃ D, HasDerivAt (fun t ↦ blackD1 F K σ t) D T := by
    have hnum := ((hasDerivAt_id T).const_mul (σ ^ 2) |>.div_const 2).const_add (log (F / K))
    have hden := (Real.hasDerivAt_sqrt hT.ne').const_mul σ
    exact ⟨_, hnum.div hden (by positivity)⟩
  have htheta : deriv (fun t ↦ blackB F K σ t) T =
      F * stdNormalPDF (blackD1 F K σ T) * σ / (2 * √T) := by
    have hN1 := (hasDerivAt_stdNormalCDF (blackD1 F K σ T)).comp T hDt
    have hN2 := (hasDerivAt_stdNormalCDF (blackD1 F K σ T - σ * √T)).comp T
      (hDt.sub ((Real.hasDerivAt_sqrt hT.ne').const_mul σ))
    have h := (hN1.const_mul F).sub (hN2.const_mul K)
    have h' : HasDerivAt (fun t ↦ blackB F K σ t)
        (F * (stdNormalPDF (blackD1 F K σ T) * Dt) -
          K * (stdNormalPDF (blackD1 F K σ T - σ * √T) * (Dt - σ * (1 / (2 * √T))))) T := h
    rw [h'.deriv]
    field_simp
    linear_combination (2 * √T * Dt - σ) * hid
  refine ⟨hgamma, hvega, htheta, ?_⟩
  rw [htheta]
  field_simp

-- The card's curve: flat 4.40 percent, yearly payments, a 1-into-5 swap. The forward
-- (D(1) - D(6)) / (D(2) + … + D(6)) is exactly 4.40 percent.
example : ((1 : ℚ) / (1044 / 1000) - 1 / (1044 / 1000) ^ 6) /
    (∑ t ∈ Finset.range 5, 1 / ((1044 : ℚ) / 1000) ^ (t + 2)) = 44 / 1000 := by
  norm_num [Finset.sum_range_succ]
-- Half the variance: σ²T/2 = 0.30² × 1 / 2 = 0.045.
example : ((30 : ℚ) / 100) ^ 2 * 1 / 2 = 45 / 1000 := by norm_num
-- d₂ = d₁ - σ√T: 0.188096 - 0.30 = -0.111904.
example : (188096 : ℚ) / 1000000 - 30 / 100 = -111904 / 1000000 := by norm_num
-- The hedge ratio: 0.574599 - 0.020508 = 0.554091.
example : (574599 : ℚ) / 1000000 - 20508 / 1000000 = 554091 / 1000000 := by norm_num
-- The hedge at work: swaption P&L plus hedge P&L gives the net in each row of the table.
example : (-6500514 : ℚ) / 100 + 7088762 / 100 = 588248 / 100 ∧
    (-2281725 : ℚ) / 100 + 2345219 / 100 = 63494 / 100 ∧
    (2389184 : ℚ) / 100 - 2327700 / 100 = 61484 / 100 ∧
    (7465470 : ℚ) / 100 - 6931087 / 100 = 534383 / 100 := by norm_num
-- Theta: decay of 298.85 a day plus carry of 27.21 a day nets to -271.64 a day.
example : (-29885 : ℚ) / 100 + 2721 / 100 = -27164 / 100 := by norm_num

#print axioms swaption_dollar_hedge_ratio_below_delta_in_swaps
#print axioms delta_in_swaps_is_N_d1
#print axioms gamma_vega_and_theta_pays_for_gamma
