-- Basket options: in the two-share lognormal model the basket's average and average square are exactly M₁ and M₂ for every correlation from -1 to 1, the moment-matched lognormal share reproduces both, and at correlation -1 the basket is not lognormal at all.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.Probability.Moments.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum

open Real MeasureTheory ProbabilityTheory

/-- One share's price on expiry day under the pricing measure (Step 2, the algebra):
`S(T) = F e^(-σ²T/2 + σ√T x)`, with `F = S e^((r - q)T)` its forward price, `σ` its volatility,
`T` the years to expiry and `x` its bell-curve draw. -/
noncomputable def shareAtExpiry (F σ T x : ℝ) : ℝ :=
  F * exp (-(σ ^ 2 * T) / 2 + σ * √T * x)

/-- Birch's draw (Step 4): a share `ρ` of Acme's draw `z₁` plus a fresh piece of the independent
draw `z₂`, `ρ z₁ + √(1 - ρ²) z₂`. -/
noncomputable def birchDraw (ρ z₁ z₂ : ℝ) : ℝ :=
  ρ * z₁ + √(1 - ρ ^ 2) * z₂

/-- The basket on expiry day: `B_T = w₁ S₁(T) + w₂ S₂(T)`, Acme driven by `z₁`, Birch by
`ρ z₁ + √(1 - ρ²) z₂`. -/
noncomputable def basketAtExpiry (w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T z₁ z₂ : ℝ) : ℝ :=
  w₁ * shareAtExpiry F₁ σ₁ T z₁ + w₂ * shareAtExpiry F₂ σ₂ T (birchDraw ρ z₁ z₂)

/-- The card's `M₁ = w₁F₁ + w₂F₂`. -/
def basketM1 (w₁ w₂ F₁ F₂ : ℝ) : ℝ :=
  w₁ * F₁ + w₂ * F₂

/-- The card's `M₂ = w₁²F₁²e^(σ₁²T) + w₂²F₂²e^(σ₂²T) + 2 w₁w₂F₁F₂ e^(ρσ₁σ₂T)`. -/
noncomputable def basketM2 (w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T : ℝ) : ℝ :=
  w₁ ^ 2 * F₁ ^ 2 * exp (σ₁ ^ 2 * T) + w₂ ^ 2 * F₂ ^ 2 * exp (σ₂ ^ 2 * T) +
    2 * w₁ * w₂ * F₁ * F₂ * exp (ρ * σ₁ * σ₂ * T)

lemma basket_exp_one_draw
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z : Ω → ℝ}
    (hZ : HasLaw Z (gaussianReal 0 1) Q) (c a : ℝ) :
    Integrable (fun ω ↦ exp (c + a * Z ω)) Q ∧
      ∫ ω, exp (c + a * Z ω) ∂Q = exp (c + a ^ 2 / 2) := by
  have hi : Integrable (fun ω ↦ exp (a * Z ω)) Q :=
    hZ.integrable_comp (f := fun x ↦ exp (a * x)) (integrable_exp_mul_gaussianReal a)
  have hm := mgf_gaussianReal hZ a
  simp only [mgf] at hm
  have hfun : (fun ω ↦ exp (c + a * Z ω)) = fun ω ↦ exp c * exp (a * Z ω) := by
    funext ω; rw [exp_add]
  rw [hfun]
  refine ⟨hi.const_mul _, ?_⟩
  rw [integral_const_mul, hm, ← exp_add]
  congr 1
  push_cast
  ring

lemma basket_exp_two_draws
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q) (c a b : ℝ) :
    Integrable (fun ω ↦ exp (c + a * Z₁ ω + b * Z₂ ω)) Q ∧
      ∫ ω, exp (c + a * Z₁ ω + b * Z₂ ω) ∂Q = exp (c + a ^ 2 / 2 + b ^ 2 / 2) := by
  obtain ⟨hi₁, he₁⟩ := basket_exp_one_draw hZ₁ 0 a
  obtain ⟨hi₂, he₂⟩ := basket_exp_one_draw hZ₂ 0 b
  simp only [zero_add] at hi₁ he₁ hi₂ he₂
  have hfun : (fun ω ↦ exp (c + a * Z₁ ω + b * Z₂ ω)) =
      fun ω ↦ exp c * (exp (a * Z₁ ω) * exp (b * Z₂ ω)) := by
    funext ω; rw [exp_add, exp_add, mul_assoc]
  have hind' := hind.exp_mul a b
  rw [hfun]
  refine ⟨(hind'.integrable_mul hi₁ hi₂).const_mul _, ?_⟩
  rw [integral_const_mul, hind'.integral_fun_mul_eq_mul_integral hi₁.aestronglyMeasurable
    hi₂.aestronglyMeasurable, he₁, he₂, ← exp_add, ← exp_add]
  congr 1
  ring

lemma basket_moments_aux
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q)
    (w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T : ℝ) (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) (hT : 0 ≤ T) :
    Integrable (fun ω ↦ basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) Q ∧
      Integrable (fun ω ↦ (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2) Q ∧
      ∫ ω, basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω) ∂Q = basketM1 w₁ w₂ F₁ F₂ ∧
      ∫ ω, (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2 ∂Q =
        basketM2 w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T := by
  set s₁ := σ₁ * √T with hs₁
  set s₂ := σ₂ * √T with hs₂
  set r := √(1 - ρ ^ 2) with hr
  set c₁ := -(σ₁ ^ 2 * T) / 2 with hc₁
  set c₂ := -(σ₂ ^ 2 * T) / 2 with hc₂
  have hT2 : √T ^ 2 = T := Real.sq_sqrt hT
  have hr2 : r ^ 2 = 1 - ρ ^ 2 := Real.sq_sqrt (by nlinarith)
  obtain ⟨i₁, e₁⟩ := basket_exp_two_draws hZ₁ hZ₂ hind c₁ s₁ 0
  obtain ⟨i₂, e₂⟩ := basket_exp_two_draws hZ₁ hZ₂ hind c₂ (s₂ * ρ) (s₂ * r)
  obtain ⟨i₃, e₃⟩ := basket_exp_two_draws hZ₁ hZ₂ hind (2 * c₁) (2 * s₁) 0
  obtain ⟨i₄, e₄⟩ := basket_exp_two_draws hZ₁ hZ₂ hind (2 * c₂) (2 * (s₂ * ρ)) (2 * (s₂ * r))
  obtain ⟨i₅, e₅⟩ := basket_exp_two_draws hZ₁ hZ₂ hind (c₁ + c₂) (s₁ + s₂ * ρ) (s₂ * r)
  have hB : (fun ω ↦ basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) = fun ω ↦
      w₁ * F₁ * exp (c₁ + s₁ * Z₁ ω + 0 * Z₂ ω) +
        w₂ * F₂ * exp (c₂ + s₂ * ρ * Z₁ ω + s₂ * r * Z₂ ω) := by
    funext ω
    simp only [basketAtExpiry, shareAtExpiry, birchDraw]
    rw [show c₁ + s₁ * Z₁ ω + 0 * Z₂ ω = -(σ₁ ^ 2 * T) / 2 + σ₁ * √T * Z₁ ω by
          rw [hc₁, hs₁]; ring,
        show c₂ + s₂ * ρ * Z₁ ω + s₂ * r * Z₂ ω =
          -(σ₂ ^ 2 * T) / 2 + σ₂ * √T * (ρ * Z₁ ω + √(1 - ρ ^ 2) * Z₂ ω) by
          rw [hc₂, hs₂, hr]; ring]
    ring
  have hB2 : (fun ω ↦ (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2) = fun ω ↦
      (w₁ * F₁) ^ 2 * exp (2 * c₁ + 2 * s₁ * Z₁ ω + 0 * Z₂ ω) +
        (w₂ * F₂) ^ 2 * exp (2 * c₂ + 2 * (s₂ * ρ) * Z₁ ω + 2 * (s₂ * r) * Z₂ ω) +
        2 * (w₁ * F₁) * (w₂ * F₂) *
          exp (c₁ + c₂ + (s₁ + s₂ * ρ) * Z₁ ω + s₂ * r * Z₂ ω) := by
    funext ω
    have k3 : exp (2 * c₁ + 2 * s₁ * Z₁ ω + 0 * Z₂ ω) =
        exp (c₁ + s₁ * Z₁ ω + 0 * Z₂ ω) ^ 2 := by
      rw [sq, ← exp_add]; ring_nf
    have k4 : exp (2 * c₂ + 2 * (s₂ * ρ) * Z₁ ω + 2 * (s₂ * r) * Z₂ ω) =
        exp (c₂ + s₂ * ρ * Z₁ ω + s₂ * r * Z₂ ω) ^ 2 := by
      rw [sq, ← exp_add]; ring_nf
    have k5 : exp (c₁ + c₂ + (s₁ + s₂ * ρ) * Z₁ ω + s₂ * r * Z₂ ω) =
        exp (c₁ + s₁ * Z₁ ω + 0 * Z₂ ω) * exp (c₂ + s₂ * ρ * Z₁ ω + s₂ * r * Z₂ ω) := by
      rw [← exp_add]; ring_nf
    rw [congrFun hB ω, k3, k4, k5]
    ring
  have iB := (i₁.const_mul (w₁ * F₁)).add (i₂.const_mul (w₂ * F₂))
  have iB2 := ((i₃.const_mul ((w₁ * F₁) ^ 2)).add (i₄.const_mul ((w₂ * F₂) ^ 2))).add
    (i₅.const_mul (2 * (w₁ * F₁) * (w₂ * F₂)))
  refine ⟨hB ▸ iB, hB2 ▸ iB2, ?_, ?_⟩
  · rw [hB, integral_add (i₁.const_mul _) (i₂.const_mul _), integral_const_mul,
      integral_const_mul, e₁, e₂]
    have h1 : c₁ + s₁ ^ 2 / 2 + 0 ^ 2 / 2 = 0 := by
      rw [hc₁, hs₁]; linear_combination (σ₁ ^ 2 / 2) * hT2
    have h2 : c₂ + (s₂ * ρ) ^ 2 / 2 + (s₂ * r) ^ 2 / 2 = 0 := by
      rw [hc₂, hs₂]
      linear_combination (σ₂ ^ 2 / 2) * hT2 + (σ₂ ^ 2 * √T ^ 2 / 2) * hr2
    rw [h1, h2, basketM1]
    simp
  · have i34 : Integrable (fun ω ↦
        (w₁ * F₁) ^ 2 * exp (2 * c₁ + 2 * s₁ * Z₁ ω + 0 * Z₂ ω) +
          (w₂ * F₂) ^ 2 * exp (2 * c₂ + 2 * (s₂ * ρ) * Z₁ ω + 2 * (s₂ * r) * Z₂ ω)) Q :=
      (i₃.const_mul _).add (i₄.const_mul _)
    rw [hB2, integral_add i34 (i₅.const_mul _),
      integral_add (i₃.const_mul _) (i₄.const_mul _), integral_const_mul,
      integral_const_mul, integral_const_mul, e₃, e₄, e₅]
    have h3 : 2 * c₁ + (2 * s₁) ^ 2 / 2 + 0 ^ 2 / 2 = σ₁ ^ 2 * T := by
      rw [hc₁, hs₁]; linear_combination (2 * σ₁ ^ 2) * hT2
    have h4 : 2 * c₂ + (2 * (s₂ * ρ)) ^ 2 / 2 + (2 * (s₂ * r)) ^ 2 / 2 = σ₂ ^ 2 * T := by
      rw [hc₂, hs₂]
      linear_combination (2 * σ₂ ^ 2) * hT2 + (2 * σ₂ ^ 2 * √T ^ 2) * hr2
    have h5 : c₁ + c₂ + (s₁ + s₂ * ρ) ^ 2 / 2 + (s₂ * r) ^ 2 / 2 = ρ * σ₁ * σ₂ * T := by
      rw [hc₁, hc₂, hs₁, hs₂]
      linear_combination (σ₁ ^ 2 / 2 + σ₁ * σ₂ * ρ + σ₂ ^ 2 * ρ ^ 2 / 2 +
        σ₂ ^ 2 * (1 - ρ ^ 2) / 2) * hT2 + (σ₂ ^ 2 * √T ^ 2 / 2) * hr2
    rw [h3, h4, h5, basketM2]
    ring

#print axioms basket_exp_one_draw
#print axioms basket_exp_two_draws
#print axioms basket_moments_aux

/-- **The basket's first two moments are exact** (The formula; Why it works, Step 2). Let Acme
and Birch each be lognormal with constant volatilities `σ₁`, `σ₂` and forwards `F₁`, `F₂`, driven
by two independent standard bell-curve draws `Z₁`, `Z₂` under the pricing measure `Q`, Birch's
draw being `ρ Z₁ + √(1 - ρ²) Z₂` for a constant correlation `ρ` that can happen (`-1 ≤ ρ ≤ 1`),
with fixed weights `w₁`, `w₂` and one expiry `T ≥ 0` years away. Then the basket
`B_T = w₁S₁(T) + w₂S₂(T)` has average exactly `M₁ = w₁F₁ + w₂F₂` and average square exactly
`M₂ = w₁²F₁²e^(σ₁²T) + w₂²F₂²e^(σ₂²T) + 2w₁w₂F₁F₂e^(ρσ₁σ₂T)`; the correlation enters only through
the last exponent. -/
theorem basket_mean_and_mean_square_are_exact
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q)
    (w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T : ℝ) (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) (hT : 0 ≤ T) :
    ∫ ω, basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω) ∂Q = basketM1 w₁ w₂ F₁ F₂ ∧
      ∫ ω, (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2 ∂Q =
        basketM2 w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T := by
  obtain ⟨-, -, h1, h2⟩ := basket_moments_aux hZ₁ hZ₂ hind w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T hρ₁ hρ₂ hT
  exact ⟨h1, h2⟩

/-- **The fitted share matches the basket's average and spread** (Why it works, Step 3). In the
same model, with positive weights and forwards, set `v = ln(M₂/M₁²)` and let the pretend share be
`M₁ e^(-v/2 + √v Z)` for a standard bell-curve draw `Z`. That single lognormal share has exactly
the basket's average and exactly the basket's average square. -/
theorem moment_matched_share_has_basket_mean_and_mean_square
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z Z₁ Z₂ : Ω → ℝ}
    (hZ : HasLaw Z (gaussianReal 0 1) Q)
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q)
    (w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T : ℝ) (hw₁ : 0 < w₁) (hw₂ : 0 < w₂) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hρ₁ : -1 ≤ ρ) (hρ₂ : ρ ≤ 1) (hT : 0 ≤ T) :
    let M₁ := basketM1 w₁ w₂ F₁ F₂
    let v := log (basketM2 w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T / M₁ ^ 2)
    ∫ ω, M₁ * exp (-v / 2 + √v * Z ω) ∂Q =
        ∫ ω, basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω) ∂Q ∧
      ∫ ω, (M₁ * exp (-v / 2 + √v * Z ω)) ^ 2 ∂Q =
        ∫ ω, (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2 ∂Q := by
  intro M₁ v
  have := hZ₁.isProbabilityMeasure
  obtain ⟨iB, iB2, h1, h2⟩ :=
    basket_moments_aux hZ₁ hZ₂ hind w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T hρ₁ hρ₂ hT
  set M₂ := basketM2 w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T with hM₂
  have hM₁ : 0 < M₁ := by simp only [M₁, basketM1]; positivity
  have hM₂pos : 0 < M₂ := by simp only [hM₂, basketM2]; positivity
  -- the variance is nonnegative, so M₂ ≥ M₁²
  have hvar : M₁ ^ 2 ≤ M₂ := by
    have hnn : 0 ≤ ∫ ω, (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω) - M₁) ^ 2 ∂Q :=
      integral_nonneg (fun ω ↦ sq_nonneg _)
    have hexp : (fun ω ↦ (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω) - M₁) ^ 2) =
        fun ω ↦ ((basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2 -
          (2 * M₁) * basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) + M₁ ^ 2 := by
      funext ω; ring
    have iS : Integrable (fun ω ↦
        (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) ^ 2 -
          (2 * M₁) * basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ ρ T (Z₁ ω) (Z₂ ω)) Q :=
      iB2.sub (iB.const_mul _)
    rw [hexp, integral_add iS (integrable_const _),
      integral_sub iB2 (iB.const_mul _), integral_const_mul, h1, h2] at hnn
    simp only [integral_const, probReal_univ, one_smul] at hnn
    have hM1 : basketM1 w₁ w₂ F₁ F₂ = M₁ := rfl
    rw [hM1] at hnn
    nlinarith
  have hratio : 1 ≤ M₂ / M₁ ^ 2 := by rw [le_div_iff₀ (by positivity)]; linarith
  have hv : 0 ≤ v := Real.log_nonneg hratio
  have hv2 : √v ^ 2 = v := Real.sq_sqrt hv
  have hexpv : exp v = M₂ / M₁ ^ 2 := Real.exp_log (by positivity)
  obtain ⟨-, e1⟩ := basket_exp_one_draw hZ (-v / 2) (√v)
  obtain ⟨-, e2⟩ := basket_exp_one_draw hZ (-v) (2 * √v)
  refine ⟨?_, ?_⟩
  · rw [h1, integral_const_mul, e1, hv2]
    rw [show -v / 2 + v / 2 = 0 by ring, exp_zero, mul_one]
  · rw [h2]
    have hsq : (fun ω ↦ (M₁ * exp (-v / 2 + √v * Z ω)) ^ 2) =
        fun ω ↦ M₁ ^ 2 * exp (-v + 2 * √v * Z ω) := by
      funext ω
      rw [mul_pow, sq (exp _), ← exp_add]
      ring_nf
    rw [hsq, integral_const_mul, e2]
    rw [show -v + (2 * √v) ^ 2 / 2 = v by rw [mul_pow, hv2]; ring, hexpv]
    field_simp

/-- **A sum of lognormals is not lognormal** (Why it works, Step 1). In the same model with
positive weights and forwards, positive volatilities, `T > 0`, and Birch always moving opposite
Acme (`ρ = -1`), the basket has a floor above zero, so its logarithm is not a bell curve: for no
centre `μ` and no variance `v` does `ln B_T` have the law `N(μ, v)`. -/
theorem basket_at_correlation_minus_one_is_not_lognormal
    {Ω : Type*} [MeasurableSpace Ω] {Q : Measure Ω} {Z₁ Z₂ : Ω → ℝ}
    (hZ₁ : HasLaw Z₁ (gaussianReal 0 1) Q) (hZ₂ : HasLaw Z₂ (gaussianReal 0 1) Q)
    (hind : IndepFun Z₁ Z₂ Q)
    (w₁ w₂ F₁ F₂ σ₁ σ₂ T : ℝ) (hw₁ : 0 < w₁) (hw₂ : 0 < w₂) (hF₁ : 0 < F₁) (hF₂ : 0 < F₂)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂) (hT : 0 < T) :
    ∀ (μ : ℝ) (v : NNReal),
      ¬ HasLaw (fun ω ↦ log (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T (Z₁ ω) (Z₂ ω)))
        (gaussianReal μ v) Q := by
  intro μ v hlaw
  set a₁ := w₁ * F₁ * exp (-(σ₁ ^ 2 * T) / 2) with ha₁
  set a₂ := w₂ * F₂ * exp (-(σ₂ ^ 2 * T) / 2) with ha₂
  have ha₁pos : 0 < a₁ := by positivity
  have ha₂pos : 0 < a₂ := by positivity
  have hsT : 0 < √T := Real.sqrt_pos.mpr hT
  have hs₁ : 0 < σ₁ * √T := mul_pos hσ₁ hsT
  have hs₂ : 0 < σ₂ * √T := mul_pos hσ₂ hsT
  -- at ρ = -1 the basket is a function of z₁ alone
  have hform : ∀ z₁ z₂ : ℝ, basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T z₁ z₂ =
      a₁ * exp (σ₁ * √T * z₁) + a₂ * exp (-(σ₂ * √T * z₁)) := by
    intro z₁ z₂
    simp only [basketAtExpiry, shareAtExpiry, birchDraw, ha₁, ha₂]
    norm_num
    rw [exp_add, exp_add]
    ring_nf
  -- the floor m > 0
  set m := min a₁ a₂ with hm
  have hmpos : 0 < m := lt_min ha₁pos ha₂pos
  have hfloor : ∀ z₁ z₂ : ℝ, m ≤ basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T z₁ z₂ := by
    intro z₁ z₂
    rw [hform]
    have p1 : 0 < a₁ * exp (σ₁ * √T * z₁) := by positivity
    have p2 : 0 < a₂ * exp (-(σ₂ * √T * z₁)) := by positivity
    rcases le_total 0 z₁ with hz | hz
    · have : 1 ≤ exp (σ₁ * √T * z₁) := Real.one_le_exp (by positivity)
      have : a₁ ≤ a₁ * exp (σ₁ * √T * z₁) := by nlinarith
      have : m ≤ a₁ := min_le_left _ _
      linarith
    · have : 1 ≤ exp (-(σ₂ * √T * z₁)) := Real.one_le_exp (by nlinarith)
      have : a₂ ≤ a₂ * exp (-(σ₂ * √T * z₁)) := by nlinarith
      have : m ≤ a₂ := min_le_right _ _
      linarith
  by_cases hv : v = 0
  · -- the law would be a point mass at μ, but ln B exceeds μ with positive probability
    subst hv
    rw [gaussianReal_zero_var] at hlaw
    have h0 := hlaw.measure_eq (p := fun x ↦ μ < x) (measurableSet_lt measurable_const measurable_id)
    have hd : Measure.dirac μ {x : ℝ | μ < x} = 0 := by
      change Measure.dirac μ (Set.Ioi μ) = 0
      rw [Measure.dirac_apply' _ measurableSet_Ioi]
      simp
    rw [hd] at h0
    set K := (μ - log a₁) / (σ₁ * √T) with hK
    have hsub : {ω | K < Z₁ ω} ⊆
        {ω | μ < log (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T (Z₁ ω) (Z₂ ω))} := by
      intro ω hω
      change K < Z₁ ω at hω
      change μ < log (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T (Z₁ ω) (Z₂ ω))
      have hBpos : 0 < basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T (Z₁ ω) (Z₂ ω) :=
        lt_of_lt_of_le hmpos (hfloor _ _)
      rw [Real.lt_log_iff_exp_lt hBpos, hform]
      have hK' : μ - log a₁ < σ₁ * √T * Z₁ ω := by
        rw [hK, div_lt_iff₀ hs₁] at hω; linarith
      have : exp μ < a₁ * exp (σ₁ * √T * Z₁ ω) := by
        rw [show a₁ = exp (log a₁) from (Real.exp_log ha₁pos).symm, ← exp_add]
        exact Real.exp_lt_exp.mpr (by linarith)
      have : 0 < a₂ * exp (-(σ₂ * √T * Z₁ ω)) := by positivity
      linarith
    have hpos : Q {ω | K < Z₁ ω} ≠ 0 := by
      rw [hZ₁.measure_eq (p := fun x ↦ K < x) (measurableSet_lt measurable_const measurable_id)]
      intro h
      have := gaussianReal_absolutelyContinuous' (0 : ℝ) (v := 1) one_ne_zero h
      simp [show {x : ℝ | K < x} = Set.Ioi K from rfl] at this
    apply hpos
    exact nonpos_iff_eq_zero.mp ((measure_mono hsub).trans h0.le)
  · -- a true bell curve puts weight below ln m, but ln B never goes there
    have h0 := hlaw.measure_eq (p := fun x ↦ x < log m)
      (measurableSet_lt measurable_id measurable_const)
    have hempty : {ω | log (basketAtExpiry w₁ w₂ F₁ F₂ σ₁ σ₂ (-1) T (Z₁ ω) (Z₂ ω)) < log m} =
        ∅ := by
      refine Set.eq_empty_iff_forall_notMem.mpr fun ω hω ↦ ?_
      exact (not_lt.mpr (Real.log_le_log hmpos (hfloor _ _))) hω
    rw [hempty, measure_empty] at h0
    have := gaussianReal_absolutelyContinuous' μ hv h0.symm
    simp [show {x : ℝ | x < log m} = Set.Iio (log m) from rfl] at this

-- The story: Acme ends at $130 and Birch at $80, half of each.
-- The basket is $105.
example : (1 / 2 : ℚ) * 130 + 1 / 2 * 80 = 105 := by norm_num
-- The basket call with strike $100 pays $5.
example : max ((1 / 2 : ℚ) * 130 + 1 / 2 * 80 - 100) 0 = 5 := by norm_num
-- Two separate half-calls would have paid $15 on Acme and nothing on Birch.
example : (1 / 2 : ℚ) * max (130 - 100) 0 + 1 / 2 * max (80 - 100) 0 = 15 := by norm_num
-- The payoff picture: basket at 80, 85, ..., 130 pays 0 0 0 0 0 5 10 15 20 25 30.
example : (List.range 11).map (fun i : ℕ => max ((80 + 5 * (i : ℤ)) - 100) 0)
    = [0, 0, 0, 0, 0, 5, 10, 15, 20, 25, 30] := by decide
-- Step 4: Birch's draw has variance ρ² + (1 - ρ²) = 1; at the house correlation ρ = 1/2.
example : (1 / 2 : ℚ) ^ 2 + (1 - (1 / 2) ^ 2) = 1 := by norm_num

#print axioms basket_mean_and_mean_square_are_exact
#print axioms moment_matched_share_has_basket_mean_and_mean_square
#print axioms basket_at_correlation_minus_one_is_not_lognormal
