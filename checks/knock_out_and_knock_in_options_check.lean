-- Knock-out and knock-in options: in any model a down-and-in call plus a down-and-out call costs one plain call, and in the Black-Scholes model the down-and-out call is the plain call minus the reflection weight times the call started from the image spot H^2/S.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Real Set

/-- Completing the square: `e^y` times a bell-curve density is a constant times the bell-curve
density shifted right by the variance. -/
lemma exp_mul_gaussianPDFReal (m : ℝ) (v : NNReal) (hv : v ≠ 0) (y : ℝ) :
    exp y * gaussianPDFReal m v y = exp (m + v / 2) * gaussianPDFReal (m + v) v y := by
  have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
  simp only [gaussianPDFReal]
  rw [mul_left_comm, ← exp_add, mul_left_comm (exp (m + v / 2)), ← exp_add]
  congr 2
  field_simp
  ring

/-- The call payoff times a bell-curve density is integrable. -/
lemma integrable_call_payoff_mul_gaussianPDFReal (x K m : ℝ) (v : NNReal) (hv : v ≠ 0) :
    Integrable (fun y => max (x * exp y - K) 0 * gaussianPDFReal m v y) := by
  have h1 : Integrable (fun y => exp y * gaussianPDFReal m v y) := by
    have : (fun y => exp y * gaussianPDFReal m v y)
        = fun y => exp (m + v / 2) * gaussianPDFReal (m + v) v y := by
      funext y; exact exp_mul_gaussianPDFReal m v hv y
    rw [this]
    exact (integrable_gaussianPDFReal _ _).const_mul _
  refine Integrable.mono' ((h1.const_mul |x|).add ((integrable_gaussianPDFReal m v).const_mul |K|))
    ?_ ?_
  · exact (by fun_prop : Measurable
      (fun y => max (x * exp y - K) 0 * gaussianPDFReal m v y)).aestronglyMeasurable
  · refine Filter.Eventually.of_forall (fun y => ?_)
    have hp := gaussianPDFReal_nonneg m v y
    have he := (exp_pos y).le
    rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg hp, abs_of_nonneg (le_max_right _ _)]
    have hm : max (x * exp y - K) 0 ≤ |x| * exp y + |K| := by
      refine max_le ?_ (by positivity)
      have := mul_le_mul_of_nonneg_right (le_abs_self x) he
      have := neg_le_abs K
      linarith
    calc max (x * exp y - K) 0 * gaussianPDFReal m v y
        ≤ (|x| * exp y + |K|) * gaussianPDFReal m v y := mul_le_mul_of_nonneg_right hm hp
      _ = |x| * (exp y * gaussianPDFReal m v y) + |K| * gaussianPDFReal m v y := by ring

#print axioms exp_mul_gaussianPDFReal
#print axioms integrable_call_payoff_mul_gaussianPDFReal

/-- In-out parity, in any model. Take any pricing world: a space of paths `Ω` with a
pricing measure `Q`, a share price `S t ω` at each time `t` on each path `ω`, a strike `K`,
a barrier `H`, an expiry `T` and a riskless rate `r`. A path "touches" the barrier when
`S t ω ≤ H` at some time `t` in `[0, T]`. The down-and-in call pays the call payoff
`max (S T - K) 0` on touched paths and zero otherwise (the indicator of the touched set);
the down-and-out call pays it on untouched paths (the complement) and zero otherwise.
Pricing each contract as its discounted average payoff, the knock-in plus the knock-out costs exactly one plain call. The only requirement is that
"touched" is an event of the model (a measurable set). -/
theorem knock_in_add_knock_out_eq_plain_call
    {Ω : Type*} [MeasurableSpace Ω] (Q : Measure Ω) (S : ℝ → Ω → ℝ) (K H T r : ℝ)
    (h_event : MeasurableSet {ω | ∃ t ∈ Icc (0 : ℝ) T, S t ω ≤ H}) :
    let touched : Set Ω := {ω | ∃ t ∈ Icc (0 : ℝ) T, S t ω ≤ H}
    let call_payoff : Ω → ENNReal := fun ω => ENNReal.ofReal (max (S T ω - K) 0)
    let disc : ENNReal := ENNReal.ofReal (exp (-(r * T)))
    disc * ∫⁻ ω, touched.indicator call_payoff ω ∂Q
      + disc * ∫⁻ ω, touchedᶜ.indicator call_payoff ω ∂Q
      = disc * ∫⁻ ω, call_payoff ω ∂Q := by
  intro touched call_payoff disc
  have ht : MeasurableSet touched := h_event
  rw [← mul_add, lintegral_indicator ht, lintegral_indicator ht.compl, lintegral_add_compl _ ht]

/-- The drifted reflection (Step 3). Let `p₀` be the bell-curve density with centre `0` and
variance `σ² T`, and `p_ν` the one with centre `ν T` and the same variance. For a barrier
`b` in log units and any end point `x`: the driftless density of touched paths ending at `x`,
`p₀ (2b - x)`, times the drift's likelihood ratio `exp (ν x / σ² - ν² T / (2 σ²))`, equals the
weight `exp (2 ν b / σ²)` times the drifted density at the reflected point `x - 2b`. -/
theorem drifted_reflection_density (ν σ T b x : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    gaussianPDFReal 0 (σ ^ 2 * T).toNNReal (2 * b - x)
        * exp (ν * x / σ ^ 2 - ν ^ 2 * T / (2 * σ ^ 2))
      = exp (2 * ν * b / σ ^ 2) * gaussianPDFReal (ν * T) (σ ^ 2 * T).toNNReal (x - 2 * b) := by
  have hv : ((σ ^ 2 * T).toNNReal : ℝ) = σ ^ 2 * T := Real.coe_toNNReal _ (by positivity)
  simp only [gaussianPDFReal, hv]
  rw [mul_assoc, ← exp_add, mul_left_comm (exp (2 * ν * b / σ ^ 2)), ← exp_add]
  congr 2
  field_simp
  ring

/-- The reflection price (Steps 4 and 5), in the Black-Scholes model. Let `ν = r - q - σ²/2`,
let `p` be the bell-curve density of the log growth `ln (S_T / S)` (centre `ν T`, variance
`σ² T`), and let `C x = e^{-rT} ∫ max (x e^y - K) 0 · p y dy` be the Black-Scholes call with
today's price `x`. With the barrier `b = ln (H / S)` in log units, the down-and-out call is the
discounted payoff over end points above the barrier, weighted by the density of untouched
paths `p x - e^{2νb/σ²} p (x - 2b)`. When the barrier sits at or below the strike and below
today's price, this equals the plain call minus the reflection weight `(H/S)^{2ν/σ²}` times the
call started from the image spot `H²/S`. -/
theorem down_and_out_call_eq_call_sub_reflected_call
    (S K H r q σ T : ℝ) (hH : 0 < H) (hHS : H < S) (hHK : H ≤ K) (hσ : 0 < σ) (hT : 0 < T) :
    let ν : ℝ := r - q - σ ^ 2 / 2
    let p : ℝ → ℝ := gaussianPDFReal (ν * T) (σ ^ 2 * T).toNNReal
    let C : ℝ → ℝ := fun x => exp (-(r * T)) * ∫ y, max (x * exp y - K) 0 * p y
    let b : ℝ := log (H / S)
    exp (-(r * T)) * ∫ x in Ioi b,
        max (S * exp x - K) 0 * (p x - exp (2 * ν * b / σ ^ 2) * p (x - 2 * b))
      = C S - (H / S) ^ (2 * ν / σ ^ 2) * C (H ^ 2 / S) := by
  intro ν p C b
  have hS : 0 < S := hH.trans hHS
  have hv : (σ ^ 2 * T).toNNReal ≠ 0 := by
    rw [Ne, Real.toNNReal_eq_zero, not_le]; positivity
  have key : ∀ x, Integrable (fun y => max (x * exp y - K) 0 * p y) := fun x =>
    integrable_call_payoff_mul_gaussianPDFReal x K (ν * T) _ hv
  have heb : exp b = H / S := exp_log (div_pos hH hS)
  set w : ℝ := exp (2 * ν * b / σ ^ 2) with hw
  set h : ℝ → ℝ := fun y => max (H ^ 2 / S * exp y - K) 0 * p y with hh
  have hg : ∀ x, max (S * exp x - K) 0 * p (x - 2 * b) = h (x - 2 * b) := by
    intro x
    simp only [hh]
    congr 3
    rw [exp_sub, show 2 * b = b + b by ring, exp_add, heb]
    field_simp
  have hgi : Integrable (fun x => max (S * exp x - K) 0 * p (x - 2 * b)) := by
    simp_rw [hg]
    exact (key (H ^ 2 / S)).comp_sub_right (2 * b)
  have hsplit : (fun x => max (S * exp x - K) 0 * (p x - w * p (x - 2 * b)))
      = fun x => max (S * exp x - K) 0 * p x - w * (max (S * exp x - K) 0 * p (x - 2 * b)) := by
    funext x; ring
  rw [hsplit, integral_sub (key S).integrableOn (hgi.const_mul w).integrableOn,
    integral_const_mul]
  have hzero : ∀ x, x ∉ Ioi b → max (S * exp x - K) 0 = 0 := by
    intro x hx
    rw [mem_Ioi, not_lt] at hx
    apply max_eq_right
    have : exp x ≤ H / S := heb ▸ exp_le_exp.mpr hx
    have : S * exp x ≤ H := by
      calc S * exp x ≤ S * (H / S) := mul_le_mul_of_nonneg_left this hS.le
        _ = H := by field_simp
    linarith
  rw [setIntegral_eq_integral_of_forall_compl_eq_zero (fun x hx => by simp [hzero x hx]),
    setIntegral_eq_integral_of_forall_compl_eq_zero (fun x hx => by simp [hzero x hx])]
  simp_rw [hg]
  rw [integral_sub_right_eq_self h (2 * b)]
  have hwr : w = (H / S) ^ (2 * ν / σ ^ 2) := by
    rw [hw, rpow_def_of_pos (div_pos hH hS)]
    congr 1
    ring
  rw [hwr]
  simp only [C, hh]
  ring

-- Worked example, house market: the image spot is 80 × 80 / 100 = 64,
-- so on a log scale ln 64 = 2 ln 80 - ln 100, that is 64 × 100 = 80².
example : (80 * 80 : ℚ) / 100 = 64 := by norm_num
example : (80 : ℕ) ^ 2 = 64 * 100 := by decide

-- Worked example: with r = 5%, q = 2%, σ = 20%, the drift ν is 1/100
-- and the exponent 2ν/σ² is 1/2.
example : ((5 : ℚ) / 100 - 2 / 100 - (20 / 100) ^ 2 / 2) = 1 / 100 := by norm_num
example : 2 * ((5 : ℚ) / 100 - 2 / 100 - (20 / 100) ^ 2 / 2) / (20 / 100) ^ 2 = 1 / 2 := by
  norm_num

-- The eight contracts: down or up, out or in, call or put.
example : 2 * 2 * 2 = 8 := by decide

#print axioms knock_in_add_knock_out_eq_plain_call
#print axioms drifted_reflection_density
#print axioms down_and_out_call_eq_call_sub_reflected_call
