-- Local volatility in implied-vol terms: Dupire's local variance, computed from Black-Scholes call prices built on a total-variance surface, equals the expiry slope of total variance divided by the butterfly function g; at short expiry local volatility tends to implied volatility over 1 - k σ'/σ, implied volatility is the harmonic mean of it from the forward to the strike, and at the forward the local skew is twice the implied skew.
import Mathlib
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum

open Real ProbabilityTheory Filter Topology

namespace LocalVolFromImpliedVol

/-! Notation, as on the card. `S > 0` is Acme's share price today, `r` the rate and `q` the
dividend yield, both known constants. `w k T` is the total implied variance surface
`σ_imp² T` at log-moneyness `k = ln(K / F_T)` and expiry `T`. -/

/-- `N`, the bell-curve area to the left of `x` (the standard normal distribution function). -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The forward `F_T = S e^{(r - q) T}`. -/
noncomputable def forward (S r q T : ℝ) : ℝ := S * exp ((r - q) * T)

/-- The Black-Scholes call per discounted forward dollar, in log-moneyness `k` and total
variance `w`: `c(k, w) = N(d₁) - e^k N(d₂)`, `d₁ = -k/√w + √w/2`, `d₂ = d₁ - √w`. -/
noncomputable def forwardScaledCall (k w : ℝ) : ℝ :=
  stdNormalCDF (-k / √w + √w / 2) - exp k * stdNormalCDF (-k / √w - √w / 2)

/-- The dollar call price at strike `K` and expiry `T` on the surface `w`:
`C(K, T) = e^{-rT} F_T c(k, w(k, T))` with `k = ln(K / F_T)`. -/
noncomputable def callPrice (S r q : ℝ) (w : ℝ → ℝ → ℝ) (K T : ℝ) : ℝ :=
  exp (-r * T) * forward S r q T *
    forwardScaledCall (log (K / forward S r q T)) (w (log (K / forward S r q T)) T)

/-- The butterfly function of one smile `w` (total variance as a function of `k`, with slope
`w'` and bend `w''`): `g(k) = (1 - k w'/(2w))² - (w')²/4 (1/w + 1/4) + w''/2`. -/
noncomputable def butterflyG (w : ℝ → ℝ) (k : ℝ) : ℝ :=
  (1 - k * deriv w k / (2 * w k)) ^ 2 - deriv w k ^ 2 / 4 * (1 / w k + 1 / 4)
    + deriv (deriv w) k / 2

/-- The short-expiry local volatility read off an implied-volatility smile `σ` (in `k`):
`σ_loc(k) = σ(k) / (1 - k σ'(k)/σ(k))`. -/
noncomputable def shortLocalVol (σ : ℝ → ℝ) (y : ℝ) : ℝ :=
  σ y / (1 - y * deriv σ y / σ y)

lemma npdf_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

#print axioms npdf_eq

lemma npdf_cont : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext npdf_eq
  rw [this]; fun_prop

#print axioms npdf_cont

open MeasureTheory in
lemma cdf_eq_int (x : ℝ) : stdNormalCDF x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold stdNormalCDF
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact integral_nonneg (fun t => gaussianPDFReal_nonneg _ _ t)

#print axioms cdf_eq_int

open MeasureTheory in
lemma cdf_eq_int' (x : ℝ) : stdNormalCDF x = stdNormalCDF 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
  rw [← intervalIntegral.integral_Iic_sub_Iic, cdf_eq_int, cdf_eq_int]
  · ring
  · exact (integrable_gaussianPDFReal _ _).integrableOn
  · exact (integrable_gaussianPDFReal _ _).integrableOn

#print axioms cdf_eq_int'

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (gaussianPDFReal 0 1 x) x := by
  have h := ((npdf_cont.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add (stdNormalCDF 0)
  have : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t :=
    funext cdf_eq_int'
  rw [this]; exact h

#print axioms hasDerivAt_stdNormalCDF

lemma hasDerivAt_npdf (x : ℝ) : HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have : gaussianPDFReal 0 1 = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext npdf_eq
  rw [this]
  have h := (((hasDerivAt_pow 2 x).neg.div_const 2).exp).const_mul (√(2 * π))⁻¹
  convert h using 1
  simp; ring

#print axioms hasDerivAt_npdf

lemma npdf_key (k s : ℝ) (hs : s ≠ 0) :
    exp k * gaussianPDFReal 0 1 (-k / s - s / 2) = gaussianPDFReal 0 1 (-k / s + s / 2) := by
  rw [npdf_eq, npdf_eq, mul_left_comm, ← exp_add]
  congr 2
  field_simp; ring

#print axioms npdf_key

lemma hasDerivAt_fsc {κ W : ℝ → ℝ} {κ' W' t : ℝ} (hκ : HasDerivAt κ κ' t)
    (hW : HasDerivAt W W' t) (hpos : 0 < W t) :
    HasDerivAt (fun t => forwardScaledCall (κ t) (W t))
      (gaussianPDFReal 0 1 (-κ t / √(W t) + √(W t) / 2) * W' / (2 * √(W t))
        - exp (κ t) * κ' * stdNormalCDF (-κ t / √(W t) - √(W t) / 2)) t := by
  have hs : HasDerivAt (fun t => √(W t)) (W' / (2 * √(W t))) t := hW.sqrt hpos.ne'
  have hsp : 0 < √(W t) := sqrt_pos.2 hpos
  have hq := hκ.neg.div hs hsp.ne'
  have h1 := (hasDerivAt_stdNormalCDF _).comp t (hq.add (hs.div_const 2))
  have h2 := (hasDerivAt_stdNormalCDF _).comp t (hq.sub (hs.div_const 2))
  have h := h1.sub (hκ.exp.mul h2)
  unfold forwardScaledCall
  refine h.congr_deriv ?_
  simp only [Pi.add_apply, Pi.div_apply, Pi.neg_apply, Function.comp, Pi.sub_apply]
  rw [← npdf_key (κ t) _ hsp.ne']
  field_simp
  ring

#print axioms hasDerivAt_fsc

lemma hasDerivAt_phi1 (ω : ℝ → ℝ) (x : ℝ) (h1 : DifferentiableAt ℝ ω x)
    (h2 : HasDerivAt (deriv ω) (deriv (deriv ω) x) x) (hpos : 0 < ω x) :
    HasDerivAt (fun y => gaussianPDFReal 0 1 (-y / √(ω y) + √(ω y) / 2) * deriv ω y / (2 * √(ω y))
        - exp y * 1 * stdNormalCDF (-y / √(ω y) - √(ω y) / 2))
      (gaussianPDFReal 0 1 (-x / √(ω x) + √(ω x) / 2) * deriv ω x / (2 * √(ω x))
        - exp x * 1 * stdNormalCDF (-x / √(ω x) - √(ω x) / 2)
        + gaussianPDFReal 0 1 (-x / √(ω x) + √(ω x) / 2) / √(ω x) * butterflyG ω x) x := by
  have hW := h1.hasDerivAt
  have hs := hW.sqrt hpos.ne'
  have hsp : 0 < √(ω x) := sqrt_pos.2 hpos
  have hq := (hasDerivAt_id' x).neg.div hs hsp.ne'
  have hd1 := hq.add (hs.div_const 2)
  have hd2 := hq.sub (hs.div_const 2)
  have hn := (hasDerivAt_npdf _).comp x hd1
  have hA := (hn.mul h2).div (hs.const_mul 2) (by positivity)
  have hB := ((hasDerivAt_exp x).mul_const 1).mul ((hasDerivAt_stdNormalCDF _).comp x hd2)
  have h := hA.sub hB
  refine h.congr_deriv ?_
  simp only [Pi.add_apply, Pi.div_apply, Pi.neg_apply, Function.comp, Pi.sub_apply, Pi.mul_apply]
  rw [← npdf_key x _ hsp.ne']
  unfold butterflyG
  have hωs : ω x = √(ω x) ^ 2 := (sq_sqrt hpos.le).symm
  generalize √(ω x) = s at hωs hsp ⊢
  rw [hωs]
  field_simp
  ring

#print axioms hasDerivAt_phi1

lemma hasDerivAt_mul_cont (h : ℝ → ℝ) (hc : ContinuousAt h 0) :
    HasDerivAt (fun y => y * h y) (h 0) 0 := by
  rw [hasDerivAt_iff_tendsto_slope]
  have : Tendsto h (𝓝[≠] 0) (𝓝 (h 0)) := hc.tendsto.mono_left nhdsWithin_le_nhds
  apply this.congr'
  filter_upwards [self_mem_nhdsWithin] with y hy
  have hy' : y ≠ 0 := hy
  simp [slope_def_field]
  exact (mul_div_cancel_left₀ (h y) hy').symm

#print axioms hasDerivAt_mul_cont

/-- **Local volatility in implied-vol terms.** Price every call by Black-Scholes from a total
implied variance surface `w(k, T)` that is smooth in strike and expiry and positive, with known
rate `r` and proportional dividend yield `q`. At any strike `K > 0` and expiry `T > 0` where the
calendar test `∂w/∂T ≥ 0` and the butterfly test `g > 0` pass, Dupire's local variance
`(C_T + (r - q) K C_K + q C) / (½ K² C_KK)` is exactly `(∂w/∂T) / g(k)` at `k = ln(K / F_T)`,
and it is not negative, so a local volatility exists there. -/
theorem dupire_local_variance_eq_total_variance_slope_div_butterfly
    (S r q : ℝ) (hS : 0 < S) (w : ℝ → ℝ → ℝ)
    (hsmooth : ContDiffOn ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2) {p | 0 < p.2})
    (hwpos : ∀ k T, 0 < T → 0 < w k T)
    (K T : ℝ) (hK : 0 < K) (hT : 0 < T)
    (hcalendar : 0 ≤ deriv (fun t => w (log (K / forward S r q T)) t) T)
    (hbutterfly : 0 < butterflyG (fun k => w k T) (log (K / forward S r q T))) :
    (deriv (fun t => callPrice S r q w K t) T
        + (r - q) * K * deriv (fun k => callPrice S r q w k T) K + q * callPrice S r q w K T) /
      ((1 / 2) * K ^ 2 * deriv (deriv fun k => callPrice S r q w k T) K)
      = deriv (fun t => w (log (K / forward S r q T)) t) T /
          butterflyG (fun k => w k T) (log (K / forward S r q T)) ∧
    0 ≤ (deriv (fun t => callPrice S r q w K t) T
        + (r - q) * K * deriv (fun k => callPrice S r q w k T) K + q * callPrice S r q w K T) /
      ((1 / 2) * K ^ 2 * deriv (deriv fun k => callPrice S r q w k T) K) := by
  have hFpos : ∀ t, 0 < forward S r q t := fun t => by unfold forward; positivity
  set F := forward S r q T with hF
  set κ0 := log (K / F) with hκ0
  -- the smile at expiry T
  have hsm2 : ContDiff ℝ 2 (fun k => w k T) :=
    hsmooth.comp_contDiff (f := fun k => (k, T)) (by fun_prop) (fun k => by simpa using hT)
  have hωd : Differentiable ℝ (fun k => w k T) := hsm2.differentiable (by norm_num)
  have hωdd : Differentiable ℝ (deriv (fun k => w k T)) := hsm2.differentiable_deriv_two
  have hωpos : ∀ k, 0 < w k T := fun k => hwpos k T hT
  have hφ : ∀ y, HasDerivAt (fun k => forwardScaledCall k (w k T))
      (gaussianPDFReal 0 1 (-y / √(w y T) + √(w y T) / 2) * deriv (fun k => w k T) y
          / (2 * √(w y T)) - exp y * 1 * stdNormalCDF (-y / √(w y T) - √(w y T) / 2)) y :=
    fun y => hasDerivAt_fsc (κ := fun k => k) (W := fun k => w k T) (hasDerivAt_id' y)
      (hωd y).hasDerivAt (hωpos y)
  have hφ2 := hasDerivAt_phi1 (fun k => w k T) κ0 (hωd κ0) (hωdd κ0).hasDerivAt (hωpos κ0)
  obtain ⟨P, hP⟩ : ∃ P : ℝ → ℝ, P = fun y => gaussianPDFReal 0 1 (-y / √(w y T) + √(w y T) / 2)
      * deriv (fun k => w k T) y / (2 * √(w y T))
      - exp y * 1 * stdNormalCDF (-y / √(w y T) - √(w y T) / 2) := ⟨_, rfl⟩
  have hφ' : ∀ y, HasDerivAt (fun k => forwardScaledCall k (w k T)) (P y) y := by
    intro y; rw [hP]; exact hφ y
  have hφ2' : HasDerivAt P (P κ0 + gaussianPDFReal 0 1 (-κ0 / √(w κ0 T) + √(w κ0 T) / 2)
      / √(w κ0 T) * butterflyG (fun k => w k T) κ0) κ0 := by
    rw [hP]; exact hφ2
  have hFT : 0 < F := hFpos T
  -- derivatives in the strike
  have hlog : ∀ k, 0 < k → HasDerivAt (fun k => log (k / F)) (1 / k) k := by
    intro k hk
    have := ((hasDerivAt_id' k).div_const F).log (div_pos hk hFT).ne'
    refine this.congr_deriv ?_
    field_simp
  have hC1 : ∀ k, 0 < k → HasDerivAt (fun k => callPrice S r q w k T)
      (exp (-r * T) * F * (P (log (k / F)) * (1 / k))) k := by
    intro k hk
    exact ((hφ' (log (k / F))).comp k (hlog k hk)).const_mul (exp (-r * T) * F)
  have hC1ev : deriv (fun k => callPrice S r q w k T) =ᶠ[𝓝 K]
      fun k => exp (-r * T) * F * (P (log (k / F)) * (1 / k)) := by
    filter_upwards [lt_mem_nhds hK] with k hk
    exact (hC1 k hk).deriv
  have hinv : HasDerivAt (fun k : ℝ => 1 / k) (-(1 / K ^ 2)) K := by
    have := (hasDerivAt_const K (1:ℝ)).div (hasDerivAt_id' K) hK.ne'
    refine this.congr_deriv ?_
    ring
  have hC2 := ((hφ2'.comp K (hlog K hK)).mul hinv).const_mul (exp (-r * T) * F)
  have hd3 := hC1ev.deriv_eq.trans hC2.deriv
  have hd2 := (hC1 K hK).deriv
  -- derivatives in the expiry
  have hFt : HasDerivAt (fun t => forward S r q t) (F * (r - q)) T := by
    have := ((hasDerivAt_id' T).const_mul (r - q)).exp.const_mul S
    refine this.congr_deriv ?_
    rw [hF]; unfold forward; ring
  have hκt : HasDerivAt (fun t => log (K / forward S r q t)) (-(r - q)) T := by
    have := ((hasDerivAt_const T K).div hFt (hFpos T).ne').log (div_pos hK (hFpos T)).ne'
    refine this.congr_deriv ?_
    simp only [Pi.div_apply, ← hF]
    field_simp
    ring
  have hg : HasFDerivAt (fun p : ℝ × ℝ => w p.1 p.2)
      (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (κ0, T)) (κ0, T) := by
    have hopen : IsOpen {p : ℝ × ℝ | 0 < p.2} := isOpen_lt continuous_const continuous_snd
    exact ((hsmooth.contDiffAt (hopen.mem_nhds hT)).differentiableAt (by norm_num)).hasFDerivAt
  set L := fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (κ0, T) with hL
  have hWt : HasDerivAt (fun t => w (log (K / forward S r q t)) t) (L (-(r - q), 1)) T :=
    hg.comp_hasDerivAt (x := T) (f := fun t => (log (K / forward S r q t), t))
      (hκt.prodMk (hasDerivAt_id' T))
  have hwt : HasDerivAt (fun t => w κ0 t) (L (0, 1)) T :=
    hg.comp_hasDerivAt (x := T) (f := fun t => (κ0, t))
      ((hasDerivAt_const T κ0).prodMk (hasDerivAt_id' T))
  have hwk : HasDerivAt (fun k => w k T) (L (1, 0)) κ0 :=
    hg.comp_hasDerivAt (x := κ0) (f := fun k => (k, T))
      ((hasDerivAt_id' κ0).prodMk (hasDerivAt_const κ0 T))
  have hLsplit : L (-(r - q), 1) = -(r - q) * L (1, 0) + L (0, 1) := by
    have : ((-(r - q)), (1:ℝ)) = (-(r - q)) • ((1:ℝ), (0:ℝ)) + ((0:ℝ), (1:ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]
  have hψ := hasDerivAt_fsc hκt hWt (hwpos _ _ hT)
  have hE : HasDerivAt (fun t => exp (-r * t)) (exp (-r * T) * (-r)) T := by
    have := ((hasDerivAt_id' T).const_mul (-r)).exp
    refine this.congr_deriv ?_
    ring
  have hCT : HasDerivAt (fun t => callPrice S r q w K t) _ T := (hE.mul hFt).mul hψ
  have hd1 := hCT.deriv
  have hcall : callPrice S r q w K T = exp (-r * T) * F * forwardScaledCall κ0 (w κ0 T) := rfl
  have key : ∀ N D c a b : ℝ, c ≠ 0 → N = c * a → D = c * b → N / D = a / b := by
    intro N D c a b hc h1 h2; rw [h1, h2, mul_div_mul_left _ _ hc]
  have main : (deriv (fun t => callPrice S r q w K t) T
        + (r - q) * K * deriv (fun k => callPrice S r q w k T) K + q * callPrice S r q w K T) /
      ((1 / 2) * K ^ 2 * deriv (deriv fun k => callPrice S r q w k T) K)
      = deriv (fun t => w κ0 t) T / butterflyG (fun k => w k T) κ0 := by
    rw [hd1, hd2, hd3, hcall, hLsplit, ← hwk.deriv, ← hwt.deriv]
    simp only [Function.comp, Pi.mul_apply, hP]
    rw [hκ0, hF]
    have hs : 0 < √(w (log (K / forward S r q T)) T) := sqrt_pos.2 (hωpos _)
    have hn : 0 < gaussianPDFReal 0 1 (-log (K / forward S r q T) / √(w (log (K / forward S r q T)) T)
        + √(w (log (K / forward S r q T)) T) / 2) := gaussianPDFReal_pos _ _ _ one_ne_zero
    have hFT' := hFpos T
    apply key _ _ (exp (-r * T) * forward S r q T * gaussianPDFReal 0 1
      (-log (K / forward S r q T) / √(w (log (K / forward S r q T)) T)
        + √(w (log (K / forward S r q T)) T) / 2) / (2 * √(w (log (K / forward S r q T)) T)))
    · positivity
    · field_simp
      ring
    · field_simp
      ring
  exact ⟨main, by rw [main]; exact div_nonneg hcalendar hbutterfly.le⟩

/-- **At short expiry, implied volatility is an average of local volatility** (Step 5). On the
surface that keeps each log-moneyness's implied volatility `σ(k)` at every expiry,
`w(k, T) = T σ(k)²`, with `σ` smooth and positive and the short-expiry butterfly test
`1 - k σ'/σ > 0` passing: as expiry shrinks to 0 the local volatility `√((∂w/∂T) / g)` tends to
`σ(k) / (1 - k σ'(k)/σ(k))`, and implied volatility is the harmonic mean of that limit along the
straight line from the forward to the strike: `1/σ(k) = ∫₀¹ du / σ_loc(u k)`. -/
theorem short_expiry_implied_vol_is_harmonic_mean_of_local_vol
    (σ : ℝ → ℝ) (hσ : ContDiff ℝ 2 σ) (hpos : ∀ y, 0 < σ y)
    (hbutterfly : ∀ y, 0 < 1 - y * deriv σ y / σ y) (k : ℝ) :
    Tendsto (fun T => √(deriv (fun t => t * σ k ^ 2) T / butterflyG (fun y => T * σ y ^ 2) k))
        (𝓝[>] 0) (𝓝 (shortLocalVol σ k)) ∧
      1 / σ k = ∫ u in (0 : ℝ)..1, 1 / shortLocalVol σ (u * k) := by
  have hd : Differentiable ℝ σ := hσ.differentiable (by norm_num)
  have hdd : Differentiable ℝ (deriv σ) := hσ.differentiable_deriv_two
  have hcd : Continuous (deriv σ) := hσ.continuous_deriv (by norm_num)
  constructor
  · have ha : σ k ≠ 0 := (hpos k).ne'
    have hG : ∀ T, T ≠ 0 → butterflyG (fun y => T * σ y ^ 2) k =
        (1 - k * deriv σ k / σ k) ^ 2 - T * deriv σ k ^ 2 - T ^ 2 * σ k ^ 2 * deriv σ k ^ 2 / 4
          + T * (deriv σ k ^ 2 + σ k * deriv (deriv σ) k) := by
      intro T hT
      have h1 : deriv (fun y => T * σ y ^ 2) = fun y => T * (2 * σ y * deriv σ y) := by
        funext y
        have := ((hd y).hasDerivAt.pow 2).const_mul T
        exact this.deriv.trans (by simp)
      have h2 : deriv (fun y => T * (2 * σ y * deriv σ y)) k =
          T * (2 * (deriv σ k * deriv σ k + σ k * deriv (deriv σ) k)) := by
        have := ((((hd k).hasDerivAt.const_mul 2).mul (hdd k).hasDerivAt)).const_mul T
        exact this.deriv.trans (by ring)
      unfold butterflyG
      rw [h1, h2]
      field_simp
      ring
    have hb0 : 0 < 1 - k * deriv σ k / σ k := hbutterfly k
    have hcont : Tendsto (fun T : ℝ => √(σ k ^ 2 /
        ((1 - k * deriv σ k / σ k) ^ 2 - T * deriv σ k ^ 2 - T ^ 2 * σ k ^ 2 * deriv σ k ^ 2 / 4
          + T * (deriv σ k ^ 2 + σ k * deriv (deriv σ) k))))
        (𝓝[>] 0) (𝓝 (√(σ k ^ 2 / ((1 - k * deriv σ k / σ k) ^ 2 - 0 * deriv σ k ^ 2
          - 0 ^ 2 * σ k ^ 2 * deriv σ k ^ 2 / 4
          + 0 * (deriv σ k ^ 2 + σ k * deriv (deriv σ) k))))) := by
      apply Tendsto.mono_left _ nhdsWithin_le_nhds
      apply Tendsto.sqrt
      apply Tendsto.div tendsto_const_nhds
      · exact (by fun_prop : Continuous (fun T : ℝ => (1 - k * deriv σ k / σ k) ^ 2 - T * deriv σ k ^ 2
          - T ^ 2 * σ k ^ 2 * deriv σ k ^ 2 / 4
          + T * (deriv σ k ^ 2 + σ k * deriv (deriv σ) k))).tendsto 0
      · simp; exact hb0.ne'
    have hlim : √(σ k ^ 2 / ((1 - k * deriv σ k / σ k) ^ 2 - 0 * deriv σ k ^ 2
          - 0 ^ 2 * σ k ^ 2 * deriv σ k ^ 2 / 4
          + 0 * (deriv σ k ^ 2 + σ k * deriv (deriv σ) k))) = shortLocalVol σ k := by
      unfold shortLocalVol
      simp only [zero_mul, sub_zero, add_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true,
        zero_pow, zero_div]
      rw [← div_pow, sqrt_sq (div_nonneg (hpos k).le hb0.le)]
    rw [← hlim]
    apply hcont.congr'
    filter_upwards [self_mem_nhdsWithin] with T hT
    rw [hG T (ne_of_gt hT)]
    congr 2
    simp
  · have hσc : Continuous σ := hd.continuous
    have hderiv : ∀ x ∈ Set.uIcc (0:ℝ) 1,
        HasDerivAt (fun u => u / σ (u * k)) (1 / shortLocalVol σ (x * k)) x := by
      intro x _
      have h1 : HasDerivAt (fun u => σ (u * k)) (deriv σ (x * k) * k) x := by
        have := (hd (x*k)).hasDerivAt.comp x ((hasDerivAt_id x).mul_const k)
        refine this.congr_deriv ?_
        simp
      have := (hasDerivAt_id x).div h1 (hpos _).ne'
      refine this.congr_deriv ?_
      unfold shortLocalVol
      have h2 := (hpos (x*k)).ne'
      have h3 := (hbutterfly (x*k)).ne'
      rw [one_div_div]
      field_simp
      simp [mul_comm]
    have hint : IntervalIntegrable (fun u => 1 / shortLocalVol σ (u * k)) MeasureTheory.volume 0 1 := by
      have : (fun u => 1 / shortLocalVol σ (u * k)) =
          fun u => (1 - u * k * deriv σ (u*k) / σ (u*k)) / σ (u*k) := by
        funext u; unfold shortLocalVol; rw [one_div_div]
      rw [this]
      apply Continuous.intervalIntegrable
      have := fun u => (hpos (u*k)).ne'
      fun_prop (disch := assumption)
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
    simp

/-- **The twice-the-skew rule** (Step 6). At short expiry and at the forward `k = 0`, the local
volatility `σ(k) / (1 - k σ'(k)/σ(k))` slopes exactly twice as steeply as the implied
volatility `σ`: `σ_loc'(0) = 2 σ_imp'(0)`. -/
theorem short_expiry_local_skew_is_twice_implied_skew
    (σ : ℝ → ℝ) (hσ : ContDiff ℝ 1 σ) (hpos : 0 < σ 0) :
    HasDerivAt (shortLocalVol σ) (2 * deriv σ 0) 0 := by
  have hd : Differentiable ℝ σ := hσ.differentiable (by norm_num)
  have hcd : Continuous (deriv σ) := hσ.continuous_deriv le_rfl
  have hD : HasDerivAt (fun y => 1 - y * (deriv σ y / σ y)) (-(deriv σ 0 / σ 0)) 0 := by
    have := hasDerivAt_mul_cont (fun y => deriv σ y / σ y)
      ((hcd.continuousAt).div (hd 0).continuousAt hpos.ne')
    simpa using this.const_sub 1
  have h := (hd 0).hasDerivAt.div hD (by simp)
  unfold shortLocalVol
  convert h using 1
  · funext y; simp only [Pi.div_apply, mul_div_assoc]
  · field_simp [hpos.ne']; ring

-- Step 4: a flat surface has w' = w'' = 0, so g = 1 and local equals implied.
example (k w : ℝ) : (1 - k * 0 / (2 * w)) ^ 2 - (0 : ℝ) ^ 2 / 4 * (1 / w + 1 / 4) + 0 / 2 = 1 := by
  norm_num

#print axioms dupire_local_variance_eq_total_variance_slope_div_butterfly
#print axioms short_expiry_implied_vol_is_harmonic_mean_of_local_vol
#print axioms short_expiry_local_skew_is_twice_implied_skew

end LocalVolFromImpliedVol
