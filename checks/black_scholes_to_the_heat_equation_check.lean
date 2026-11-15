-- Black-Scholes is the heat equation after a change of variables: with log price x = ln(S/K), heat clock τ = σ²(T - t)/2 and V = K e^(αx + βτ) u, the Black-Scholes equation holds exactly where u_τ = u_xx, the call's payoff becomes the start max(e^(c₁x) - e^(c₂x), 0), and the heat kernel's answer, rescaled, is the Black-Scholes formula.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.ContDiff.Basic

open Real MeasureTheory ProbabilityTheory

namespace BlackScholesHeat

/-- `N(z)`: the normal curve's area to the left of `z`. -/
noncomputable def stdNormalCDF (z : ℝ) : ℝ := cdf (gaussianReal 0 1) z

/-- The heat clock: `τ = ½ σ² (T - t)`, time to expiry in units of half the variance. -/
noncomputable def heatClock (σ T t : ℝ) : ℝ := σ ^ 2 / 2 * (T - t)

/-- The drift in heat-clock units, `k' = 2(r - q)/σ²`. -/
noncomputable def kDrift (r q σ : ℝ) : ℝ := 2 * (r - q) / σ ^ 2

/-- The bank rate in heat-clock units, `k = 2r/σ²`. -/
noncomputable def kRate (r σ : ℝ) : ℝ := 2 * r / σ ^ 2

/-- The factor's slope in log price, `α = -½ (k' - 1)`. -/
noncomputable def alpha (r q σ : ℝ) : ℝ := -(kDrift r q σ - 1) / 2

/-- The factor's rate on the heat clock, `β = -¼ (k' - 1)² - k`. -/
noncomputable def beta (r q σ : ℝ) : ℝ := -(kDrift r q σ - 1) ^ 2 / 4 - kRate r σ

/-- The value rebuilt from a rod temperature `u(x, τ)`:
`V(S, t) = K e^(αx + βτ) u(x, τ)` with `x = ln(S/K)` and `τ = ½ σ² (T - t)`. -/
noncomputable def valueFromRod (K r q σ T : ℝ) (u : ℝ → ℝ → ℝ) (S t : ℝ) : ℝ :=
  K * exp (alpha r q σ * log (S / K) + beta r q σ * heatClock σ T t)
    * u (log (S / K)) (heatClock σ T t)

/-- The Black-Scholes equation at share price `S` and date `t`:
`V_t + (r - q) S V_S + ½ σ² S² V_SS = r V`, each slope taken with the other variable held still. -/
def ObeysBlackScholes (V : ℝ → ℝ → ℝ) (r q σ S t : ℝ) : Prop :=
  deriv (fun t' => V S t') t
      + (r - q) * S * deriv (fun S' => V S' t) S
      + 1 / 2 * σ ^ 2 * S ^ 2 * deriv (fun S' => deriv (fun S'' => V S'' t) S') S
    = r * V S t

/-- The heat equation `u_τ = u_xx` at the point `(x, τ)`. -/
def ObeysHeat (u : ℝ → ℝ → ℝ) (x τ : ℝ) : Prop :=
  deriv (fun τ' => u x τ') τ = deriv (fun x' => deriv (fun x'' => u x'' τ) x') x

/-- The heat kernel on an endless rod, `G(x, τ) = e^(-x²/(4τ)) / √(4πτ)`. -/
noncomputable def heatKernel (x τ : ℝ) : ℝ := exp (-x ^ 2 / (4 * τ)) / √(4 * π * τ)

/-- The call's payoff as the rod's start: `max(e^(c₁x) - e^(c₂x), 0)`, with
`c₁ = ½ (k' + 1)` and `c₂ = ½ (k' - 1)`. -/
noncomputable def rodStart (r q σ x : ℝ) : ℝ :=
  max (exp ((kDrift r q σ + 1) / 2 * x) - exp ((kDrift r q σ - 1) / 2 * x)) 0

open Set in
lemma gaussian_tail (m : ℝ) (v : NNReal) (hv : v ≠ 0) :
    ∫ y, (Ioi (0:ℝ)).indicator (gaussianPDFReal m v) y = stdNormalCDF (m / √(v:ℝ)) := by
  have hsv : 0 < √(v:ℝ) := Real.sqrt_pos.2 (by positivity)
  have hmap : gaussianReal m v = (gaussianReal 0 1).map (fun z => m - √(v:ℝ) * z) := by
    have h1 : (gaussianReal 0 1).map (fun z => √(v:ℝ) * z) = gaussianReal 0 v := by
      rw [gaussianReal_map_const_mul]; congr 1
      · simp
      · ext; simp [Real.sq_sqrt (NNReal.coe_nonneg v)]
    have : (fun z => m - √(v:ℝ) * z) = (fun w => m - w) ∘ (fun z => √(v:ℝ) * z) := rfl
    rw [this, ← Measure.map_map (by fun_prop) (by fun_prop), h1, gaussianReal_map_const_sub]
    simp
  have hpre : (fun z => m - √(v:ℝ) * z) ⁻¹' Ioi 0 = Iio (m / √(v:ℝ)) := by
    ext z; simp only [mem_preimage, mem_Ioi, mem_Iio, sub_pos]
    rw [lt_div_iff₀ hsv, mul_comm]
  have hreal : (gaussianReal m v).real (Ioi 0) = stdNormalCDF (m / √(v:ℝ)) := by
    rw [hmap, map_measureReal_apply (by fun_prop) measurableSet_Ioi, hpre, stdNormalCDF,
      cdf_eq_real]
    have := nullSingletonClass_gaussianReal (μ := (0:ℝ)) (v := 1) one_ne_zero
    exact measureReal_congr Iio_ae_eq_Iic
  rw [← hreal, integral_indicator measurableSet_Ioi, measureReal_def,
    gaussianReal_apply_eq_integral _ hv, ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Ioi (fun y _ => gaussianPDFReal_nonneg _ _ _)

#print axioms gaussian_tail

lemma heat_tilt (c x y τ : ℝ) (hτ : 0 < τ) :
    exp (c * y) * heatKernel (x - y) τ
      = exp (c * x + c ^ 2 * τ) * gaussianPDFReal (x + 2 * c * τ) (2 * τ).toNNReal y := by
  unfold heatKernel gaussianPDFReal
  rw [Real.coe_toNNReal _ (by positivity)]
  have h4 : 2 * π * (2 * τ) = 4 * π * τ := by ring
  rw [h4]
  have hs : 0 < √(4 * π * τ) := Real.sqrt_pos.2 (by positivity)
  rw [div_eq_mul_inv, mul_comm (√(4 * π * τ))⁻¹, ← mul_assoc, ← mul_assoc, ← exp_add, ← exp_add]
  congr 2
  field_simp
  ring

#print axioms heat_tilt

/-- **Black-Scholes is the heat equation after a change of variables** (The formula; Why it
works, Steps 1 to 3). Take a constant bank rate `r`, dividend yield `q` and volatility `σ > 0`,
and a strike `K > 0`. Let `u(x, τ)` be any twice continuously differentiable function, and
rebuild the value `V(S, t) = K e^(αx + βτ) u(x, τ)` from it, with log price `x = ln(S/K)`, heat
clock `τ = ½ σ² (T - t)`, `α = -½ (k' - 1)`, `β = -¼ (k' - 1)² - k`, `k' = 2(r - q)/σ²` and
`k = 2r/σ²`. Then at every share price `S > 0` and date `t`, `V` obeys the Black-Scholes
equation `V_t + (r - q) S V_S + ½ σ² S² V_SS = r V` exactly when `u` obeys the heat equation
`u_τ = u_xx` at the matching point `(ln(S/K), ½ σ² (T - t))`. Every step is reversible. -/
theorem black_scholes_iff_heat_equation (K r q σ T : ℝ) (hσ : 0 < σ) (hK : 0 < K)
    (u : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (S t : ℝ) (hS : 0 < S) :
    ObeysBlackScholes (valueFromRod K r q σ T u) r q σ S t ↔
      ObeysHeat u (log (S / K)) (heatClock σ T t) := by
  -- one-variable smoothness of `u` in each slot
  have hcx : ∀ τ, ContDiff ℝ 2 (fun x => u x τ) := fun τ =>
    hu.comp (by fun_prop : ContDiff ℝ 2 fun x : ℝ => (x, τ))
  have hct : ∀ x, ContDiff ℝ 2 (fun τ => u x τ) := fun x =>
    hu.comp (by fun_prop : ContDiff ℝ 2 fun τ : ℝ => (x, τ))
  set ux : ℝ → ℝ → ℝ := fun x τ => deriv (fun x' => u x' τ) x with hux
  set uxx : ℝ → ℝ → ℝ := fun x τ => deriv (fun x' => ux x' τ) x with huxx
  set ut : ℝ → ℝ → ℝ := fun x τ => deriv (fun τ' => u x τ') τ with hut
  have hdx : ∀ x τ, HasDerivAt (fun x' => u x' τ) (ux x τ) x := fun x τ =>
    ((hcx τ).differentiable (by norm_num) x).hasDerivAt
  have hdxx : ∀ x τ, HasDerivAt (fun x' => ux x' τ) (uxx x τ) x := fun x τ =>
    ((hcx τ).differentiable_deriv_two x).hasDerivAt
  have hdt : ∀ x τ, HasDerivAt (fun τ' => u x τ') (ut x τ) τ := fun x τ =>
    ((hct x).differentiable (by norm_num) τ).hasDerivAt
  set a := alpha r q σ with ha
  set b := beta r q σ with hb
  set τ₀ := heatClock σ T t with hτ₀
  set x₀ := log (S / K) with hx₀
  -- the log price and its slope
  have hlog : ∀ S' : ℝ, 0 < S' → HasDerivAt (fun S'' => log (S'' / K)) S'⁻¹ S' := by
    intro S' hS'
    have := ((hasDerivAt_id' S').div_const K).log (div_pos hS' hK).ne'
    refine this.congr_deriv ?_
    field_simp
  -- time slope
  have hclock : HasDerivAt (fun t' => heatClock σ T t') (-(σ ^ 2 / 2)) t := by
    unfold heatClock
    simpa using ((hasDerivAt_id t).const_sub T).const_mul (σ ^ 2 / 2)
  have hVt : HasDerivAt (fun t' => valueFromRod K r q σ T u S t')
      (K * exp (a * x₀ + b * τ₀) * (-(σ ^ 2 / 2)) * (b * u x₀ τ₀ + ut x₀ τ₀)) t := by
    unfold valueFromRod
    have h1 := (((hasDerivAt_const t (a * x₀)).add (hclock.const_mul b)).exp).const_mul K
    have h2 := (hdt x₀ τ₀).comp t hclock
    have := h1.mul h2
    refine this.congr_deriv ?_
    simp only [Function.comp_apply, Pi.add_apply]
    ring
  -- first price slope, at every positive price
  set D : ℝ → ℝ := fun S' =>
    K * exp (a * log (S' / K) + b * τ₀) * (a * u (log (S' / K)) τ₀ + ux (log (S' / K)) τ₀) * S'⁻¹
    with hD
  have hVS : ∀ S' : ℝ, 0 < S' → HasDerivAt (fun S'' => valueFromRod K r q σ T u S'' t) (D S') S' := by
    intro S' hS'
    unfold valueFromRod
    have h1 := ((((hlog S' hS').const_mul a).add_const (b * τ₀)).exp).const_mul K
    have h2 := (hdx (log (S' / K)) τ₀).comp S' (hlog S' hS')
    have := h1.mul h2
    refine this.congr_deriv ?_
    simp only [D, Function.comp_apply]
    ring
  have hDS : HasDerivAt D
      (K * exp (a * x₀ + b * τ₀) * (a * S⁻¹ * (a * u x₀ τ₀ + ux x₀ τ₀) * S⁻¹
        + (a * (ux x₀ τ₀ * S⁻¹) + uxx x₀ τ₀ * S⁻¹) * S⁻¹
        + (a * u x₀ τ₀ + ux x₀ τ₀) * (-(S ^ 2)⁻¹))) S := by
    have h1 := ((((hlog S hS).const_mul a).add_const (b * τ₀)).exp).const_mul K
    have h2 := ((hdx x₀ τ₀).comp S (hlog S hS)).const_mul a
    have h3 := (hdxx x₀ τ₀).comp S (hlog S hS)
    have h4 := hasDerivAt_inv hS.ne'
    have := (h1.mul (h2.add h3)).mul h4
    refine this.congr_deriv ?_
    simp only [Function.comp_apply, Pi.add_apply, Pi.mul_apply]
    ring
  have hderiv2 : deriv (fun S' => deriv (fun S'' => valueFromRod K r q σ T u S'' t) S') S
      = deriv D S := by
    apply Filter.EventuallyEq.deriv_eq
    filter_upwards [Ioi_mem_nhds hS] with S' hS'
    exact (hVS S' hS').deriv
  have hVval : valueFromRod K r q σ T u S t = K * exp (a * x₀ + b * τ₀) * u x₀ τ₀ := rfl
  unfold ObeysBlackScholes ObeysHeat
  rw [hVt.deriv, (hVS S hS).deriv, hderiv2, hDS.deriv, hVval]
  change _ ↔ ut x₀ τ₀ = uxx x₀ τ₀
  simp only [D]
  rw [← hx₀]
  have hE : 0 < K * exp (a * x₀ + b * τ₀) := by positivity
  generalize K * exp (a * x₀ + b * τ₀) = E at hE ⊢
  generalize u x₀ τ₀ = U
  generalize ux x₀ τ₀ = U1
  generalize uxx x₀ τ₀ = U2
  generalize ut x₀ τ₀ = Ut
  have key : (E * -(σ ^ 2 / 2) * (b * U + Ut) + (r - q) * S * (E * (a * U + U1) * S⁻¹)
      + 1 / 2 * σ ^ 2 * S ^ 2 * (E * (a * S⁻¹ * (a * U + U1) * S⁻¹
        + (a * (U1 * S⁻¹) + U2 * S⁻¹) * S⁻¹ + (a * U + U1) * -(S ^ 2)⁻¹)))
      - r * (E * U) = σ ^ 2 / 2 * E * (U2 - Ut) := by
    simp only [ha, hb, alpha, beta, kDrift, kRate]
    field_simp
    ring
  have hc : σ ^ 2 / 2 * E ≠ 0 := by positivity
  constructor
  · intro h
    have : σ ^ 2 / 2 * E * (U2 - Ut) = 0 := by rw [← key, h, sub_self]
    have := (mul_eq_zero.1 this).resolve_left hc
    linarith
  · intro h
    have : σ ^ 2 / 2 * E * (U2 - Ut) = 0 := by rw [h, sub_self, mul_zero]
    rw [← key] at this
    linarith

/-- **The payoff becomes the rod's starting temperature** (Why it works, Step 4). With strike
`K > 0`, the rebuilt value at expiry is the call's payoff, `V(S, T) = max(S - K, 0)` for every
share price `S > 0`, exactly when the rod starts at
`u(x, 0) = max(e^(½(k'+1)x) - e^(½(k'-1)x), 0)` for every log price `x`. -/
theorem call_payoff_iff_rod_start (K r q σ T : ℝ) (hK : 0 < K) (u : ℝ → ℝ → ℝ) :
    (∀ S : ℝ, 0 < S → valueFromRod K r q σ T u S T = max (S - K) 0) ↔
      ∀ x : ℝ, u x 0 = rodStart r q σ x := by
  have key : ∀ x, K * exp (alpha r q σ * x) * rodStart r q σ x = max (K * exp x - K) 0 := by
    intro x
    unfold rodStart
    rw [mul_max_of_nonneg _ _ (by positivity), mul_zero]
    have e1 : exp (alpha r q σ * x) * exp ((kDrift r q σ + 1) / 2 * x) = exp x := by
      rw [← exp_add]; congr 1; unfold alpha; ring
    have e2 : exp (alpha r q σ * x) * exp ((kDrift r q σ - 1) / 2 * x) = 1 := by
      rw [← exp_add, Real.exp_eq_one_iff]; unfold alpha; ring
    congr 1
    linear_combination K * e1 - K * e2
  have hT : heatClock σ T T = 0 := by simp [heatClock]
  constructor
  · intro h x
    have h' := h (K * exp x) (by positivity)
    unfold valueFromRod at h'
    rw [hT, mul_zero, add_zero, mul_div_cancel_left₀ _ hK.ne', log_exp, ← key x] at h'
    exact mul_left_cancel₀ (by positivity) h'
  · intro h S hS
    unfold valueFromRod
    rw [hT, mul_zero, add_zero, h, key]
    have : K * exp (log (S / K)) = S := by rw [exp_log (div_pos hS hK)]; field_simp
    rw [this]

/-- **The heat kernel's answer is the Black-Scholes formula** (Why it works, Step 5). With
`σ > 0`, `K > 0`, share price `S > 0` and a date `t` strictly before expiry `T`, blend the heat
kernel against the rod's start, `u(x, τ) = ∫ u(y, 0) G(x - y, τ) dy`, at `x = ln(S/K)` and
`τ = ½ σ² (T - t)`, then undo the factor: `K e^(αx + βτ) u(x, τ)` equals the Black-Scholes call
`S e^(-q(T - t)) N(d₁) - K e^(-r(T - t)) N(d₂)`, with
`d₁ = (ln(S/K) + (r - q + ½ σ²)(T - t)) / (σ √(T - t))` and `d₂ = d₁ - σ √(T - t)`. -/
theorem heat_kernel_answer_is_black_scholes_call (K r q σ T S t : ℝ)
    (hσ : 0 < σ) (hK : 0 < K) (hS : 0 < S) (ht : t < T) :
    let x := log (S / K)
    let τ := heatClock σ T t
    let d₁ := (log (S / K) + (r - q + σ ^ 2 / 2) * (T - t)) / (σ * √(T - t))
    let d₂ := d₁ - σ * √(T - t)
    K * exp (alpha r q σ * x + beta r q σ * τ) * ∫ y : ℝ, rodStart r q σ y * heatKernel (x - y) τ
      = S * exp (-q * (T - t)) * stdNormalCDF d₁ - K * exp (-r * (T - t)) * stdNormalCDF d₂ := by
  intro x τ d₁ d₂
  have hTt : 0 < T - t := sub_pos.2 ht
  have hτ : 0 < τ := by simp only [τ, heatClock]; positivity
  set v : NNReal := (2 * τ).toNNReal with hv_def
  have hv : v ≠ 0 := (Real.toNNReal_pos.2 (by positivity)).ne'
  set c₁ := (kDrift r q σ + 1) / 2 with hc₁
  set c₂ := (kDrift r q σ - 1) / 2 with hc₂
  have hpt : ∀ y, rodStart r q σ y * heatKernel (x - y) τ
      = exp (c₁ * x + c₁ ^ 2 * τ) * (Set.Ioi 0).indicator (gaussianPDFReal (x + 2 * c₁ * τ) v) y
        - exp (c₂ * x + c₂ ^ 2 * τ) * (Set.Ioi 0).indicator (gaussianPDFReal (x + 2 * c₂ * τ) v) y := by
    intro y
    unfold rodStart
    rcases lt_or_ge 0 y with hy | hy
    · rw [Set.indicator_of_mem (Set.mem_Ioi.2 hy), Set.indicator_of_mem (Set.mem_Ioi.2 hy)]
      rw [max_eq_left (sub_nonneg.2 (exp_le_exp.2 (by nlinarith)))]
      rw [sub_mul, heat_tilt c₁ x y τ hτ, heat_tilt c₂ x y τ hτ]
    · rw [Set.indicator_of_notMem (by simpa using hy), Set.indicator_of_notMem (by simpa using hy)]
      rw [max_eq_right (sub_nonpos.2 (exp_le_exp.2 (by nlinarith)))]
      simp
  have hint : ∫ y : ℝ, rodStart r q σ y * heatKernel (x - y) τ
      = exp (c₁ * x + c₁ ^ 2 * τ) * stdNormalCDF ((x + 2 * c₁ * τ) / √(v:ℝ))
        - exp (c₂ * x + c₂ ^ 2 * τ) * stdNormalCDF ((x + 2 * c₂ * τ) / √(v:ℝ)) := by
    simp_rw [hpt]
    rw [integral_sub, integral_const_mul, integral_const_mul, gaussian_tail _ _ hv,
      gaussian_tail _ _ hv]
    · exact ((integrable_gaussianPDFReal _ _).indicator measurableSet_Ioi).const_mul _
    · exact ((integrable_gaussianPDFReal _ _).indicator measurableSet_Ioi).const_mul _
  have hsqrt : √(v:ℝ) = σ * √(T - t) := by
    have : (v:ℝ) = σ ^ 2 * (T - t) := by
      rw [hv_def, Real.coe_toNNReal _ (by positivity)]; simp only [τ, heatClock]; ring
    rw [this, Real.sqrt_mul (sq_nonneg σ), Real.sqrt_sq hσ.le]
  have hst : 0 < √(T - t) := Real.sqrt_pos.2 hTt
  have hst2 : √(T - t) ^ 2 = T - t := Real.sq_sqrt hTt.le
  have hd₁ : (x + 2 * c₁ * τ) / √(v:ℝ) = d₁ := by
    rw [hsqrt]; simp only [d₁, x, τ, c₁, heatClock, kDrift]
    congr 1; field_simp
  have hd₂ : (x + 2 * c₂ * τ) / √(v:ℝ) = d₂ := by
    rw [hsqrt]; simp only [d₂, d₁, x, τ, c₂, heatClock, kDrift]
    rw [eq_sub_iff_add_eq, div_add' _ _ _ (by positivity)]
    congr 1
    field_simp
    rw [hst2]; ring
  have hx : exp x = S / K := by simp only [x]; exact exp_log (div_pos hS hK)
  have he₁ : K * exp (alpha r q σ * x + beta r q σ * τ) * exp (c₁ * x + c₁ ^ 2 * τ)
      = S * exp (-q * (T - t)) := by
    rw [mul_assoc, ← exp_add]
    have : alpha r q σ * x + beta r q σ * τ + (c₁ * x + c₁ ^ 2 * τ) = x + -q * (T - t) := by
      simp only [alpha, beta, c₁, kDrift, kRate, τ, heatClock]; field_simp; ring
    rw [this, exp_add, hx]; field_simp
  have he₂ : K * exp (alpha r q σ * x + beta r q σ * τ) * exp (c₂ * x + c₂ ^ 2 * τ)
      = K * exp (-r * (T - t)) := by
    rw [mul_assoc, ← exp_add]
    congr 2
    simp only [alpha, beta, c₂, kDrift, kRate, τ, heatClock]; field_simp; ring
  rw [hint, hd₁, hd₂]
  linear_combination stdNormalCDF d₁ * he₁ - stdNormalCDF d₂ * he₂

-- The card's call, in exact fractions: r = 1/20, q = 1/50, σ = 1/5, three months T - t = 1/4.
-- Heat clock τ = (1/5)² · (1/4) / 2 = 1/200 (0.005).
example : heatClock (1 / 5) (1 / 4) 0 = 1 / 200 := by
  unfold heatClock; norm_num
-- Drift and rate in heat units: k' = 3/2 and k = 5/2.
example : kDrift (1 / 20) (1 / 50) (1 / 5) = 3 / 2 ∧ kRate (1 / 20) (1 / 5) = 5 / 2 := by
  unfold kDrift kRate; norm_num
-- The factor: α = -1/4 (−0.25) and β = -41/16 (−2.5625).
example : alpha (1 / 20) (1 / 50) (1 / 5) = -1 / 4 ∧ beta (1 / 20) (1 / 50) (1 / 5) = -41 / 16 := by
  unfold alpha beta kDrift kRate; norm_num
-- The start's exponents c₁ = 5/4 and c₂ = 1/4, and the distances d₁ = 2 c₁ τ / √(2τ) = 1/8 and
-- d₂ = 2 c₂ τ / √(2τ) = 1/40, using √(2τ) = 1/10 since (1/10)² = 2 · (1/200).
example : ((3 : ℚ) / 2 + 1) / 2 = 5 / 4 ∧ ((3 : ℚ) / 2 - 1) / 2 = 1 / 4 ∧
    ((1 : ℚ) / 10) ^ 2 = 2 * (1 / 200) ∧
    2 * ((5 : ℚ) / 4) * (1 / 200) / (1 / 10) = 1 / 8 ∧
    2 * ((1 : ℚ) / 4) * (1 / 200) / (1 / 10) = 1 / 40 := by norm_num
-- The exponents collapse: α + c₁ = 1, β + c₁² = k' - k = -2q/σ² = -1, α + c₂ = 0, β + c₂² = -k.
example : (-1 / 4 : ℚ) + 5 / 4 = 1 ∧ (-41 / 16 : ℚ) + (5 / 4) ^ 2 = 3 / 2 - 5 / 2 ∧
    (3 / 2 - 5 / 2 : ℚ) = -2 * (1 / 50) / (1 / 5) ^ 2 ∧
    (-1 / 4 : ℚ) + 1 / 4 = 0 ∧ (-41 / 16 : ℚ) + (1 / 4) ^ 2 = -5 / 2 := by norm_num
-- The growth terms' exponents: c₁² τ = 25/16 · 1/200 = 1/128 and c₂² τ = 1/16 · 1/200 = 1/3200.
example : ((5 : ℚ) / 4) ^ 2 * (1 / 200) = 1 / 128 ∧ ((1 : ℚ) / 4) ^ 2 * (1 / 200) = 1 / 3200 := by
  norm_num

#print axioms black_scholes_iff_heat_equation
#print axioms call_payoff_iff_rod_start
#print axioms heat_kernel_answer_is_black_scholes_call

end BlackScholesHeat
