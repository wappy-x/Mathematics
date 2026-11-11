-- Integrals round a full turn: for real A, B, C with A > √(B² + C²), the integral of 1/(A + B cos t + C sin t) over t from 0 to 2π is 2π/√(A² − B² − C²), setting z = e^(it) turns any full-turn integral in cos t and sin t into the loop integral round the unit circle with cos t = (z + 1/z)/2, sin t = (z − 1/z)/(2i), dt = dz/(iz), and for the Ferris wheel's 1/(2 + cos t) that loop integral is 2πi times the residue 1/(i√3) at the one pole −2 + √3 inside the circle.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

/-! `∫ t in (0 : ℝ)..2 * π, f t` is the integral of `f` over one full turn, `t` from `0` to `2π`.
`∮ z in C(0, 1), g z` is the loop integral of `g` once anticlockwise round the unit circle
`|z| = 1`; Mathlib defines it by the parametrization `z = e^(it)`, `0 ≤ t ≤ 2π`. `I` is i and
`Real.sqrt` is the square root. Real numbers such as `Real.cos t` are read as complex numbers where
a complex number is needed. -/

open Complex Real

namespace TrigonometricIntegralsOnTheUnitCircle

/-- Helper: the substitution `z = e^(it)` turns a full-turn integral into a unit-circle integral. -/
theorem full_turn_swap_aux (F : ℂ → ℂ → ℂ) :
    ∫ t in (0 : ℝ)..2 * π, F (Real.cos t) (Real.sin t) =
      ∮ z in C(0, 1), F ((z + z⁻¹) / 2) ((z - z⁻¹) / (2 * I)) / (I * z) := by
  rw [circleIntegral]
  refine intervalIntegral.integral_congr (fun θ _ => ?_)
  simp only [deriv_circleMap, circleMap_zero, ofReal_one, one_mul, smul_eq_mul]
  have he : Complex.exp (θ * I) ≠ 0 := Complex.exp_ne_zero _
  have hinv : (Complex.exp (θ * I))⁻¹ = Complex.exp (-θ * I) := by
    rw [neg_mul, Complex.exp_neg]
  have hc : (Complex.exp (θ * I) + (Complex.exp (θ * I))⁻¹) / 2 = (Real.cos θ : ℂ) := by
    rw [hinv, ofReal_cos, ← two_cos]; ring
  have hs : (Complex.exp (θ * I) - (Complex.exp (θ * I))⁻¹) / (2 * I) = (Real.sin θ : ℂ) := by
    rw [hinv, ofReal_sin]
    have h2 := two_sin (θ : ℂ)
    have hI : I ≠ 0 := I_ne_zero
    rw [div_eq_iff (mul_ne_zero two_ne_zero hI)]
    linear_combination (-I) * h2 + (Complex.exp (↑θ * I) - Complex.exp (-↑θ * I)) * I_sq
  rw [hc, hs]
  field_simp

#print axioms full_turn_swap_aux

/-- Helper: `∮ (z - r)⁻¹` round the unit circle is zero when `r` lies outside the closed disk. -/
theorem circleIntegral_sub_inv_of_one_lt_norm (r : ℂ) (hr : 1 < ‖r‖) : (∮ z in C(0, 1), (z - r)⁻¹) = 0 := by
  have hne : ∀ z ∈ Metric.closedBall (0 : ℂ) 1, z - r ≠ 0 := by
    intro z hz h
    rw [sub_eq_zero] at h
    subst h
    simp at hz
    linarith
  refine circleIntegral_eq_zero_of_differentiable_on_off_countable zero_le_one
    (s := ∅) Set.countable_empty ?_ ?_
  · exact (continuousOn_id.sub continuousOn_const).inv₀ hne
  · intro z hz
    exact ((differentiableAt_id.sub_const r).inv (hne z (Metric.ball_subset_closedBall hz.1)))

#print axioms circleIntegral_sub_inv_of_one_lt_norm

/-- **The closed form.** For real constants `A`, `B`, `C` with `A > √(B² + C²)`, so that the
denominator `A + B cos t + C sin t` is never zero, the integral of `1/(A + B cos t + C sin t)`
over one full turn, `t` from `0` to `2π`, equals `2π/√(A² − B² − C²)`. -/
theorem integral_inv_add_cos_add_sin_full_turn (A B C : ℝ) (h : Real.sqrt (B ^ 2 + C ^ 2) < A) :
    ∫ t in (0 : ℝ)..2 * π, 1 / (A + B * Real.cos t + C * Real.sin t) =
      2 * π / Real.sqrt (A ^ 2 - B ^ 2 - C ^ 2) := by
  have hs0 : 0 ≤ Real.sqrt (B ^ 2 + C ^ 2) := Real.sqrt_nonneg _
  have hA : 0 < A := lt_of_le_of_lt hs0 h
  have hsq : Real.sqrt (B ^ 2 + C ^ 2) ^ 2 = B ^ 2 + C ^ 2 := Real.sq_sqrt (by positivity)
  have hlt : B ^ 2 + C ^ 2 < A ^ 2 := by nlinarith
  by_cases hBC : B ^ 2 + C ^ 2 = 0
  · have hB : B = 0 := by nlinarith [sq_nonneg B, sq_nonneg C]
    have hC : C = 0 := by nlinarith [sq_nonneg B, sq_nonneg C]
    subst hB hC
    simp [Real.sqrt_sq hA.le]
    ring
  have hpos : 0 < B ^ 2 + C ^ 2 := lt_of_le_of_ne (by positivity) (Ne.symm hBC)
  set D := Real.sqrt (A ^ 2 - B ^ 2 - C ^ 2) with hDdef
  have hD2 : D ^ 2 = A ^ 2 - B ^ 2 - C ^ 2 := Real.sq_sqrt (by linarith)
  have hD : 0 < D := Real.sqrt_pos.2 (by linarith)
  have hDA : D < A := by nlinarith
  set w : ℂ := (B : ℂ) - C * I with hw
  have hwn : ‖w‖ ^ 2 = B ^ 2 + C ^ 2 := by
    rw [Complex.sq_norm, Complex.normSq_apply]; simp [hw]; ring
  have hwpos : 0 < ‖w‖ := by
    rcases (norm_nonneg w).lt_or_eq with h' | h'
    · exact h'
    · rw [← h'] at hwn; linarith
  have hw0 : w ≠ 0 := norm_pos_iff.1 hwpos
  set r₁ : ℂ := ((D - A : ℝ) : ℂ) / w with hr₁
  set r₂ : ℂ := ((-D - A : ℝ) : ℂ) / w with hr₂
  have hn₁ : ‖r₁‖ < 1 := by
    rw [hr₁, norm_div, Complex.norm_real, Real.norm_eq_abs, abs_of_neg (by linarith),
      div_lt_one hwpos]
    nlinarith
  have hn₂ : 1 < ‖r₂‖ := by
    rw [hr₂, norm_div, Complex.norm_real, Real.norm_eq_abs, abs_of_neg (by linarith),
      one_lt_div hwpos]
    nlinarith
  have hD2c : (D : ℂ) ^ 2 = (A : ℂ) ^ 2 - (B : ℂ) ^ 2 - (C : ℂ) ^ 2 := by exact_mod_cast hD2
  have hDc : (D : ℂ) ≠ 0 := by exact_mod_cast hD.ne'
  have hI : I ≠ 0 := I_ne_zero
  have hsum : (r₁ + r₂) * w = -2 * A := by
    rw [hr₁, hr₂]; push_cast; field_simp; ring
  have hprod : r₁ * r₂ * w = B + C * I := by
    rw [hr₁, hr₂]; push_cast; field_simp
    rw [hw]
    linear_combination (-1 : ℂ) * hD2c + (C : ℂ) ^ 2 * I_sq
  have key : ∀ z ∈ Metric.sphere (0 : ℂ) 1,
      1 / ((A : ℂ) + B * ((z + z⁻¹) / 2) + C * ((z - z⁻¹) / (2 * I))) / (I * z) =
        (1 / (I * D)) * ((z - r₁)⁻¹ - (z - r₂)⁻¹) := by
    intro z hz
    have hz1 : ‖z‖ = 1 := by simpa using hz
    have hz0 : z ≠ 0 := by rintro rfl; simp at hz1
    have hz₁ : z - r₁ ≠ 0 := by
      intro h'; rw [sub_eq_zero] at h'; rw [h'] at hz1; linarith
    have hz₂ : z - r₂ ≠ 0 := by
      intro h'; rw [sub_eq_zero] at h'; rw [h'] at hz1; linarith
    have hden : (A : ℂ) + B * ((z + z⁻¹) / 2) + C * ((z - z⁻¹) / (2 * I)) =
        w * (z - r₁) * (z - r₂) / (2 * z) := by
      have e : w * (z - r₁) * (z - r₂) = w * z ^ 2 - (r₁ + r₂) * w * z + r₁ * r₂ * w := by ring
      rw [e, hsum, hprod, hw]
      field_simp
      linear_combination (C : ℂ) * (z ^ 2 - 1) * I_sq
    rw [hden]
    have hr : r₁ - r₂ = 2 * D / w := by
      rw [hr₁, hr₂]; push_cast; field_simp; ring
    rw [inv_sub_inv hz₁ hz₂]
    have : z - r₂ - (z - r₁) = r₁ - r₂ := by ring
    rw [this, hr]
    field_simp
  have hcast : ((∫ t in (0 : ℝ)..2 * π, 1 / (A + B * Real.cos t + C * Real.sin t) : ℝ) : ℂ) =
      ∫ t in (0 : ℝ)..2 * π,
        (fun c s : ℂ => 1 / ((A : ℂ) + B * c + C * s)) (Real.cos t) (Real.sin t) := by
    rw [← intervalIntegral.integral_ofReal]
    push_cast
    rfl
  have hint₁ : CircleIntegrable (fun z => (z - r₁)⁻¹) 0 1 := by
    rw [circleIntegrable_sub_inv_iff]; right; intro h'; simp at h'; linarith
  have hint₂ : CircleIntegrable (fun z => (z - r₂)⁻¹) 0 1 := by
    rw [circleIntegrable_sub_inv_iff]; right; intro h'; simp at h'; linarith
  have hfin : ((∫ t in (0 : ℝ)..2 * π, 1 / (A + B * Real.cos t + C * Real.sin t) : ℝ) : ℂ) =
      ((2 * π / D : ℝ) : ℂ) := by
    rw [hcast, full_turn_swap_aux (fun c s : ℂ => 1 / ((A : ℂ) + B * c + C * s)), circleIntegral.integral_congr zero_le_one key,
      circleIntegral.integral_const_mul, circleIntegral.integral_sub hint₁ hint₂,
      circleIntegral.integral_sub_inv_of_mem_ball (by simpa using hn₁), circleIntegral_sub_inv_of_one_lt_norm r₂ hn₂]
    push_cast
    field_simp
    ring
  exact_mod_cast hfin

/-- **The swap: a full turn is a full loop.** Setting `z = e^(it)`, so that
`cos t = (z + 1/z)/2`, `sin t = (z − 1/z)/(2i)` and `dt = dz/(iz)`, turns the integral over one
full turn of any expression `F(cos t, sin t)` into the loop integral, once anticlockwise round the
unit circle, of `F((z + 1/z)/2, (z − 1/z)/(2i)) / (iz)`. -/
theorem full_turn_integral_eq_unit_circle_integral (F : ℂ → ℂ → ℂ) :
    ∫ t in (0 : ℝ)..2 * π, F (Real.cos t) (Real.sin t) =
      ∮ z in C(0, 1), F ((z + z⁻¹) / 2) ((z - z⁻¹) / (2 * I)) / (I * z) := by
  exact full_turn_swap_aux F

/-- **The Ferris wheel by residues.** After the swap, `1/(2 + cos t) dt` becomes
`2 dz / (i(z² + 4z + 1))`. Its poles are the roots `z₊ = −2 + √3` and `z₋ = −2 − √3` of
`z² + 4z + 1`; `z₊` lies inside the unit circle and `z₋` outside. The loop integral round the unit
circle is `2πi` times the residue `1/(i√3)` at `z₊` alone, and that equals the integral of
`1/(2 + cos t)` over one full turn, `2π/√3`. -/
theorem ferris_wheel_integral_by_residue :
    (∀ z : ℂ, z ^ 2 + 4 * z + 1 = (z - (-2 + Real.sqrt 3)) * (z - (-2 - Real.sqrt 3))) ∧
      ‖(-2 + Real.sqrt 3 : ℂ)‖ < 1 ∧ 1 < ‖(-2 - Real.sqrt 3 : ℂ)‖ ∧
      (∮ z in C(0, 1), 2 / (I * (z ^ 2 + 4 * z + 1))) = 2 * π * I * (1 / (I * Real.sqrt 3)) ∧
      ∫ t in (0 : ℝ)..2 * π, 1 / (2 + Real.cos t) = 2 * π / Real.sqrt 3 := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have h3c : ((Real.sqrt 3 : ℝ) : ℂ) ^ 2 = 3 := by exact_mod_cast h3
  have h3pos : 0 < Real.sqrt 3 := Real.sqrt_pos.2 (by norm_num)
  have h3gt : 1 < Real.sqrt 3 := by nlinarith
  have h3lt : Real.sqrt 3 < 2 := by nlinarith
  have hreal : ∫ t in (0 : ℝ)..2 * π, 1 / (2 + Real.cos t) = 2 * π / Real.sqrt 3 := by
    have hm := integral_inv_add_cos_add_sin_full_turn 2 1 0 (by norm_num)
    simp only [one_mul, zero_mul, add_zero] at hm
    rw [hm]
    norm_num
  refine ⟨fun z => by linear_combination h3c, ?_, ?_, ?_, hreal⟩
  · have : ((-2 + Real.sqrt 3 : ℝ) : ℂ) = (-2 + Real.sqrt 3 : ℂ) := by push_cast; ring
    rw [← this, Complex.norm_real, Real.norm_eq_abs, abs_lt]
    constructor <;> linarith
  · have : ((-2 - Real.sqrt 3 : ℝ) : ℂ) = (-2 - Real.sqrt 3 : ℂ) := by push_cast; ring
    rw [← this, Complex.norm_real, Real.norm_eq_abs, lt_abs]
    right; linarith
  · have hc : ∀ z ∈ Metric.sphere (0 : ℂ) 1,
        2 / (I * (z ^ 2 + 4 * z + 1)) =
          (fun c _ : ℂ => 1 / (2 + c)) ((z + z⁻¹) / 2) ((z - z⁻¹) / (2 * I)) / (I * z) := by
      intro z hz
      have hz1 : ‖z‖ = 1 := by simpa using hz
      have hz0 : z ≠ 0 := by rintro rfl; simp at hz1
      have hq : z ^ 2 + 4 * z + 1 ≠ 0 := by
        intro hq
        have e : z ^ 2 + 4 * z + 1 = (z - (-2 + Real.sqrt 3)) * (z - (-2 - Real.sqrt 3)) := by
          linear_combination h3c
        rw [e] at hq
        rcases mul_eq_zero.1 hq with h' | h'
        · rw [sub_eq_zero] at h'
          have : ((-2 + Real.sqrt 3 : ℝ) : ℂ) = z := by rw [h']; push_cast; ring
          rw [← this, Complex.norm_real, Real.norm_eq_abs, abs_eq (by norm_num)] at hz1
          rcases hz1 with h'' | h'' <;> linarith
        · rw [sub_eq_zero] at h'
          have : ((-2 - Real.sqrt 3 : ℝ) : ℂ) = z := by rw [h']; push_cast; ring
          rw [← this, Complex.norm_real, Real.norm_eq_abs, abs_eq (by norm_num)] at hz1
          rcases hz1 with h'' | h'' <;> linarith
      have hI : I ≠ 0 := I_ne_zero
      have hd : (2 : ℂ) + (z + z⁻¹) / 2 = (z ^ 2 + 4 * z + 1) / (2 * z) := by
        field_simp; ring
      simp only
      rw [hd]
      field_simp
    rw [circleIntegral.integral_congr zero_le_one hc, ← full_turn_integral_eq_unit_circle_integral (fun c _ : ℂ => 1 / (2 + c))]
    have hcast : ((∫ t in (0 : ℝ)..2 * π, 1 / (2 + Real.cos t) : ℝ) : ℂ) =
        ∫ t in (0 : ℝ)..2 * π,
          (fun c _ : ℂ => 1 / (2 + c)) (Real.cos t) (Real.sin t) := by
      rw [← intervalIntegral.integral_ofReal]
      push_cast
      rfl
    rw [← hcast, hreal]
    have hs : ((Real.sqrt 3 : ℝ) : ℂ) ≠ 0 := by exact_mod_cast h3pos.ne'
    push_cast
    field_simp

/-- The wheel's denominator in `z`: `2 + (z + 1/z)/2 = (z² + 4z + 1)/(2z)` for `z ≠ 0`. -/
example (z : ℂ) (hz : z ≠ 0) : 2 + (z + z⁻¹) / 2 = (z ^ 2 + 4 * z + 1) / (2 * z) := by
  field_simp
  ring

/-- The two poles multiply to the constant term, 1: each is the other's reciprocal. -/
example : (-2 + Real.sqrt 3) * (-2 - Real.sqrt 3) = 1 := by
  have h : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  nlinarith [h]

/-- The wheel, A = 2, B = 1, C = 0: A² − B² − C² = 3, and A > √(B² + C²) = 1. -/
example : (2 : ℝ) ^ 2 - 1 ^ 2 - 0 ^ 2 = 3 ∧ Real.sqrt (1 ^ 2 + 0 ^ 2) < 2 := by
  norm_num

/-- The second case 1/(5 + 4 sin t), A = 5, B = 0, C = 4: √(A² − B² − C²) = 3, so the integral
is 2π/3; and A > √(B² + C²) = 4. -/
example : Real.sqrt (5 ^ 2 - 0 ^ 2 - 4 ^ 2) = 3 ∧ Real.sqrt (0 ^ 2 + 4 ^ 2) < 5 := by
  have h3 : (5 : ℝ) ^ 2 - 0 ^ 2 - 4 ^ 2 = 3 ^ 2 := by norm_num
  have h4 : (0 : ℝ) ^ 2 + 4 ^ 2 = 4 ^ 2 := by norm_num
  rw [h3, h4, Real.sqrt_sq (by norm_num), Real.sqrt_sq (by norm_num)]
  norm_num

/-- The pole on the circle: for 1/(1 + cos t), A = 1, B = 1, C = 0 gives A = √(B² + C²), so the
card's condition A > √(B² + C²) fails. -/
example : ¬ (Real.sqrt (1 ^ 2 + 0 ^ 2) < (1 : ℝ)) := by
  norm_num

#print axioms integral_inv_add_cos_add_sin_full_turn
#print axioms full_turn_integral_eq_unit_circle_integral
#print axioms ferris_wheel_integral_by_residue

end TrigonometricIntegralsOnTheUnitCircle
