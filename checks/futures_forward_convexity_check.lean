-- Futures against forwards: in the Hull-White model the futures rate beats the FRA rate by exactly G₀(e^C - 1)/α, this gap is strictly positive, and with no pull-back it becomes the Ho-Lee rule ½σ²TU.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory ProbabilityTheory Real Filter Topology
open scoped NNReal

noncomputable section

/-- The Hull-White loading `b(v) = (1 - e^{-κ v}) / κ`. -/
def hwLoading (κ v : ℝ) : ℝ := (1 - exp (-κ * v)) / κ

/-- `q_T = σ² (1 - e^{-2κT}) / (2κ)`: the variance of the random part `X_T` of the short rate. -/
def hwVar (κ σ T : ℝ) : ℝ := σ ^ 2 * (1 - exp (-2 * κ * T)) / (2 * κ)

/-- `c_T = σ² b(T)² / 2`: the covariance of `X_T` with the bank account's log growth. -/
def hwCov (κ σ T : ℝ) : ℝ := σ ^ 2 / 2 * hwLoading κ T ^ 2

/-- The total exponent `C = b(h)² q_T + b(h) c_T`, with `h = U - T`. -/
def convexityExponent (κ σ T U : ℝ) : ℝ :=
  hwLoading κ (U - T) ^ 2 * hwVar κ σ T + hwLoading κ (U - T) * hwCov κ σ T

/-- The growth factor `Z_T = 1 / P(T,U) = G₀ exp(½ b(h)² q_T + b(h) c_T + b(h) X_T)` from the
Hull-White bond formula, as a function of the value `x` of `X_T`. -/
def hwGrowthFactor (G₀ κ σ T U x : ℝ) : ℝ :=
  G₀ * exp (hwLoading κ (U - T) ^ 2 * hwVar κ σ T / 2
    + hwLoading κ (U - T) * hwCov κ σ T + hwLoading κ (U - T) * x)

/-- The FRA rate `K = (G₀ - 1)/α` with `G₀ = D(T)/D(U)`: it needs only today's curve. -/
def fraRate (D : ℝ → ℝ) (T U α : ℝ) : ℝ := (D T / D U - 1) / α

/-- Gaussian mean of the exponential payoff. -/
lemma hw_exp_mean {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : Ω → ℝ) (v : ℝ≥0) (hX : HasLaw X (gaussianReal 0 v) P) (G a b α : ℝ) :
    ∫ ω, (G * exp (a + b * X ω) - 1) / α ∂P = (G * exp (a + (v : ℝ) * b ^ 2 / 2) - 1) / α := by
  have hint : Integrable (fun ω => exp (b * X ω)) P :=
    hX.integrable_comp (f := fun x => exp (b * x)) (integrable_exp_mul_gaussianReal b)
  have hm : ∫ ω, exp (b * X ω) ∂P = exp ((v : ℝ) * b ^ 2 / 2) := by
    have := mgf_gaussianReal hX b
    simpa [mgf] using this
  have h1 : (fun ω => (G * exp (a + b * X ω) - 1) / α)
      = fun ω => ((G * exp a) * exp (b * X ω) - 1) / α := by
    funext ω; rw [exp_add]; ring
  rw [h1, integral_div, integral_sub (hint.const_mul _) (integrable_const _), integral_const_mul,
    hm]
  simp [exp_add]
  ring

/-- `(1 - e^{-κ v}) / κ → v` as `κ → 0`, `κ ≠ 0`. -/
lemma hw_loading_tendsto (v : ℝ) :
    Tendsto (fun κ : ℝ => (1 - exp (-κ * v)) / κ) (𝓝[≠] 0) (𝓝 v) := by
  have hd : HasDerivAt (fun κ : ℝ => -exp (-κ * v)) v 0 := by
    have h := (((hasDerivAt_id (0:ℝ)).neg.mul_const v).exp).neg
    convert h using 1
    · funext x; simp
    · simp
  have := hd.tendsto_slope
  refine this.congr (fun κ => ?_)
  rw [slope_def_field]
  simp
  ring

/-- **The convexity adjustment.** In the Hull-White model the random part `X_T` of the short rate
at the fixing date is normal with mean 0 and variance `q_T`, and the growth factor is
`Z_T = G₀ exp(½ b(h)² q_T + b(h) c_T + b(h) X_T)` with `G₀ = D(T)/D(U)`. The futures rate is the
plain average of the fixed rate `L_T = (Z_T - 1)/α`. Then the futures rate minus the FRA rate is
exactly `G₀ (e^C - 1)/α`, with `C = b(h)² q_T + b(h) c_T`. -/
theorem futures_rate_sub_fra_rate_eq
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (D : ℝ → ℝ) (κ σ T U α : ℝ) (X : Ω → ℝ) (v : ℝ≥0)
    (hv : (v : ℝ) = hwVar κ σ T) (hX : HasLaw X (gaussianReal 0 v) P) :
    (∫ ω, (hwGrowthFactor (D T / D U) κ σ T U (X ω) - 1) / α ∂P) - fraRate D T U α
      = D T / D U / α * (exp (convexityExponent κ σ T U) - 1) := by
  have hG : ∀ x, hwGrowthFactor (D T / D U) κ σ T U x
      = D T / D U * exp ((hwLoading κ (U - T) ^ 2 * hwVar κ σ T / 2
        + hwLoading κ (U - T) * hwCov κ σ T) + hwLoading κ (U - T) * x) := by
    intro x; rfl
  simp_rw [hG]
  rw [hw_exp_mean P X v hX, hv]
  unfold fraRate convexityExponent
  rw [show hwLoading κ (U - T) ^ 2 * hwVar κ σ T / 2 + hwLoading κ (U - T) * hwCov κ σ T
      + hwVar κ σ T * hwLoading κ (U - T) ^ 2 / 2
      = hwLoading κ (U - T) ^ 2 * hwVar κ σ T + hwLoading κ (U - T) * hwCov κ σ T by ring]
  ring

/-- **The sign.** With pull-back `κ > 0`, volatility `σ > 0`, fixing date `T > 0`, payment date
`U > T`, accrual `α > 0` and positive discount factors, the futures rate is strictly above the
FRA rate. -/
theorem fra_rate_lt_futures_rate
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (D : ℝ → ℝ) (κ σ T U α : ℝ) (X : Ω → ℝ) (v : ℝ≥0)
    (hv : (v : ℝ) = hwVar κ σ T) (hX : HasLaw X (gaussianReal 0 v) P)
    (hκ : 0 < κ) (hσ : 0 < σ) (hT : 0 < T) (hTU : T < U) (hα : 0 < α)
    (hDT : 0 < D T) (hDU : 0 < D U) :
    fraRate D T U α < ∫ ω, (hwGrowthFactor (D T / D U) κ σ T U (X ω) - 1) / α ∂P := by
  rw [← sub_pos, futures_rate_sub_fra_rate_eq P D κ σ T U α X v hv hX]
  have hb : ∀ w, 0 < w → 0 < hwLoading κ w := by
    intro w hw
    unfold hwLoading
    apply div_pos _ hκ
    have : exp (-κ * w) < 1 := by
      rw [Real.exp_lt_one_iff]; nlinarith
    linarith
  have hh := hb (U - T) (by linarith)
  have hq : 0 < hwVar κ σ T := by
    unfold hwVar
    have : exp (-2 * κ * T) < 1 := by
      rw [Real.exp_lt_one_iff]; nlinarith
    apply div_pos _ (by linarith)
    apply mul_pos (by positivity); linarith
  have hc : 0 < hwCov κ σ T := by
    unfold hwCov
    have := hb T hT
    positivity
  have hC : 0 < convexityExponent κ σ T U := by
    unfold convexityExponent; positivity
  have : 1 < exp (convexityExponent κ σ T U) := one_lt_exp_iff.mpr hC
  have : 0 < exp (convexityExponent κ σ T U) - 1 := by linarith
  positivity

/-- **The Ho-Lee limit.** The continuously compounded adjustment `(C - ½ b(h)² q_T)/h` tends to the
Ho-Lee rule `½ σ² T U` as the pull-back `κ` falls to zero. -/
theorem cc_adjustment_tendsto_ho_lee (σ T U : ℝ) (hTU : T < U) :
    Tendsto (fun κ => (convexityExponent κ σ T U - hwLoading κ (U - T) ^ 2 * hwVar κ σ T / 2)
        / (U - T)) (𝓝[>] 0) (𝓝 (σ ^ 2 * T * U / 2)) := by
  have hh : U - T ≠ 0 := by linarith
  have hfun : (fun κ => (convexityExponent κ σ T U - hwLoading κ (U - T) ^ 2 * hwVar κ σ T / 2)
        / (U - T))
      = fun κ => (hwLoading κ (U - T) ^ 2 * (σ ^ 2 * (((1 - exp (-κ * (2 * T))) / κ) / 2)) / 2
          + hwLoading κ (U - T) * (σ ^ 2 / 2 * hwLoading κ T ^ 2)) / (U - T) := by
    funext κ
    unfold convexityExponent hwCov
    have : hwVar κ σ T = σ ^ 2 * (((1 - exp (-κ * (2 * T))) / κ) / 2) := by
      unfold hwVar
      rw [show -2 * κ * T = -κ * (2 * T) by ring]
      rw [mul_div_assoc, div_div, mul_comm κ 2]
    rw [this]; ring
  rw [hfun]
  have hL : ∀ w, Tendsto (fun κ => hwLoading κ w) (𝓝[>] 0) (𝓝 w) := fun w =>
    (hw_loading_tendsto w).mono_left (nhdsWithin_mono _ (fun x (hx : x ∈ Set.Ioi (0:ℝ)) => (ne_of_gt hx : x ≠ 0)))
  have hV : Tendsto (fun κ : ℝ => ((1 - exp (-κ * (2 * T))) / κ) / 2) (𝓝[>] 0) (𝓝 T) := by
    have := ((hw_loading_tendsto (2 * T)).mono_left
      (nhdsWithin_mono _ (fun x (hx : x ∈ Set.Ioi (0:ℝ)) => (ne_of_gt hx : x ≠ 0)))).div_const 2
    simpa using this
  have hlim := ((((hL (U - T)).pow 2).mul (hV.const_mul (σ ^ 2))).div_const 2 |>.add
    ((hL (U - T)).mul (((hL T).pow 2).const_mul (σ ^ 2 / 2)))).div_const (U - T)
  convert hlim using 2
  field_simp
  ring

end

-- One basis point on $1,000,000 for a quarter year is $25.
example : (1000000 : ℚ) * (1 / 10000) * (1 / 4) = 25 := by norm_num

-- The accrual gap h = U - T = 3.25 - 3 = 0.25.
example : (13 / 4 : ℚ) - 3 = 1 / 4 := by norm_num

-- The exponent of G₀ = D(3)/D(3.25) for D(s) = e^{-0.03 s - 0.002 s²}: 0.010625.
example : (-(3 / 100) * 3 - (2 / 1000) * 3 ^ 2) - (-(3 / 100) * (13 / 4) - (2 / 1000) * (13 / 4) ^ 2)
    = (10625 / 1000000 : ℚ) := by norm_num

-- The Ho-Lee rule ½σ²TU with σ = 0.0143, T = 3, U = 3.25 is 9.9688875 basis points.
example : (1 / 2 : ℚ) * (143 / 10000) ^ 2 * 3 * (13 / 4) * 10000 = 99688875 / 10000000 := by norm_num

#print axioms hw_exp_mean
#print axioms hw_loading_tendsto
#print axioms futures_rate_sub_fra_rate_eq
#print axioms fra_rate_lt_futures_rate
#print axioms cc_adjustment_tendsto_ho_lee
