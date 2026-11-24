-- Describing functions: a relay of output ±d fed A sin θ has first Fourier sine coefficient 4d/π and so describing function 4d/(πA), a saturation of slope K clipped at ±1 has the card's arcsin formula, and the conveyor plant 1/(s(s+1)(s+2)) has phase −180° only at ω = √2, where G(j√2) = −1/6.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Real.Sign
import Mathlib.Analysis.Complex.Basic

open Real intervalIntegral Complex

set_option autoImplicit false

theorem df_integral_two_pi_of_add_pi (f : ℝ → ℝ) (hf : Continuous f)
    (hp : ∀ x, f (x + π) = f x) :
    ∫ x in (0 : ℝ)..2 * π, f x = 2 * ∫ x in (0 : ℝ)..π, f x := by
  rw [← integral_add_adjacent_intervals (hf.intervalIntegrable 0 π)
    (hf.intervalIntegrable π (2 * π))]
  have h := intervalIntegral.integral_comp_add_right f π (a := 0) (b := π)
  simp only [hp, zero_add] at h
  rw [show π + π = 2 * π by ring] at h
  rw [← h]; ring

#print axioms df_integral_two_pi_of_add_pi

theorem df_integral_pi_of_pi_sub (f : ℝ → ℝ) (hf : Continuous f)
    (hp : ∀ x, f (π - x) = f x) :
    ∫ x in (0 : ℝ)..π, f x = 2 * ∫ x in (0 : ℝ)..π / 2, f x := by
  rw [← integral_add_adjacent_intervals (hf.intervalIntegrable 0 (π / 2))
    (hf.intervalIntegrable (π / 2) π)]
  have h := intervalIntegral.integral_comp_sub_left f π (a := 0) (b := π / 2)
  simp only [hp, sub_zero] at h
  rw [show π - π / 2 = π / 2 by ring] at h
  rw [← h]; ring

#print axioms df_integral_pi_of_pi_sub

theorem df_sat_neg (y : ℝ) : max (-1) (min 1 (-y)) = -max (-1) (min 1 y) := by
  rcases le_total y 1 with h1 | h1 <;> rcases le_total y (-1) with h2 | h2 <;>
    simp [min_def, max_def] <;> split_ifs <;> linarith

#print axioms df_sat_neg

/-- **The relay's describing function.** A relay of output level `d` turns the sine
`A sin θ` (amplitude `A > 0`) into `d · sign(A sin θ)`, a square wave. Its first Fourier sine
coefficient `b₁ = (1/π) ∫₀^{2π} d · sign(A sin θ) · sin θ dθ` equals `4d/π`, whatever `A` is,
and so the describing function `N(A) = b₁/A` is `4d/(πA)`. -/
theorem relay_describing_function (d A : ℝ) (hA : 0 < A) :
    (1 / π) * ∫ θ in (0 : ℝ)..2 * π, d * Real.sign (A * Real.sin θ) * Real.sin θ = 4 * d / π ∧
      ((1 / π) * ∫ θ in (0 : ℝ)..2 * π, d * Real.sign (A * Real.sin θ) * Real.sin θ) / A =
        4 * d / (π * A) := by
  have hpt : ∀ θ : ℝ, d * Real.sign (A * Real.sin θ) * Real.sin θ = d * |Real.sin θ| := by
    intro θ
    rcases lt_trichotomy (Real.sin θ) 0 with h | h | h
    · rw [Real.sign_of_neg (mul_neg_of_pos_of_neg hA h), abs_of_neg h]; ring
    · rw [h]; simp
    · rw [Real.sign_of_pos (mul_pos hA h), abs_of_pos h]; ring
  have habs : ∫ θ in (0 : ℝ)..2 * π, |Real.sin θ| = 4 := by
    rw [df_integral_two_pi_of_add_pi _ (by fun_prop) (fun x => by rw [Real.sin_add_pi, abs_neg])]
    have : ∫ θ in (0 : ℝ)..π, |Real.sin θ| = ∫ θ in (0 : ℝ)..π, Real.sin θ := by
      refine integral_congr (fun x hx => ?_)
      rw [Set.uIcc_of_le Real.pi_pos.le] at hx
      exact abs_of_nonneg (Real.sin_nonneg_of_nonneg_of_le_pi hx.1 hx.2)
    rw [this, integral_sin]; simp; norm_num
  have hI : ∫ θ in (0 : ℝ)..2 * π, d * Real.sign (A * Real.sin θ) * Real.sin θ = 4 * d := by
    simp_rw [hpt]; rw [integral_const_mul, habs]; ring
  rw [hI]
  have hpi := Real.pi_pos.ne'
  constructor
  · field_simp
  · field_simp

/-- **The saturation's describing function.** A saturation of slope `K > 0` clipped at `±1`
turns `A sin θ` (amplitude `A > 0`) into `max (−1) (min 1 (K A sin θ))`. Clipping starts at the
error `δ = 1/K`. Its describing function `N(A) = b₁/A`, with
`b₁ = (1/π) ∫₀^{2π} max (−1) (min 1 (K A sin θ)) · sin θ dθ`, is the full gain `K` when `A ≤ δ`,
and `(2K/π)(arcsin r + r √(1 − r²))` with `r = δ/A` when `A > δ`. -/
theorem saturation_describing_function (K A : ℝ) (hK : 0 < K) (hA : 0 < A) :
    (A ≤ 1 / K →
      ((1 / π) * ∫ θ in (0 : ℝ)..2 * π,
          max (-1) (min 1 (K * (A * Real.sin θ))) * Real.sin θ) / A = K) ∧
    (1 / K < A →
      ((1 / π) * ∫ θ in (0 : ℝ)..2 * π,
          max (-1) (min 1 (K * (A * Real.sin θ))) * Real.sin θ) / A =
        2 * K / π * (Real.arcsin ((1 / K) / A) +
          (1 / K) / A * Real.sqrt (1 - ((1 / K) / A) ^ 2))) := by
  have hpi := Real.pi_pos
  have hKA : 0 < K * A := mul_pos hK hA
  constructor
  · intro hle
    have hKA1 : K * A ≤ 1 := by
      rw [le_div_iff₀ hK] at hle; linarith
    have hpt : ∀ θ : ℝ, max (-1) (min 1 (K * (A * Real.sin θ))) * Real.sin θ =
        (K * A) * Real.sin θ ^ 2 := by
      intro θ
      have h1 := Real.neg_one_le_sin θ
      have h2 := Real.sin_le_one θ
      have hu : K * (A * Real.sin θ) ≤ 1 := by nlinarith
      have hl : -1 ≤ K * (A * Real.sin θ) := by nlinarith
      rw [min_eq_right hu, max_eq_right hl]; ring
    simp_rw [hpt]
    rw [integral_const_mul, integral_sin_sq]
    simp
    field_simp
  · intro hlt
    set r := (1 / K) / A with hr
    have hr0 : 0 < r := by positivity
    have hKAr : K * A * r = 1 := by rw [hr]; field_simp
    have hr1 : r < 1 := by
      rw [hr, div_lt_one hA]; exact hlt
    set α := Real.arcsin r with hα
    have hα0 : 0 ≤ α := Real.arcsin_nonneg.mpr hr0.le
    have hα2 : α ≤ π / 2 := Real.arcsin_le_pi_div_two r
    have hsα : Real.sin α = r := Real.sin_arcsin (by linarith) hr1.le
    have hcα : Real.cos α = Real.sqrt (1 - r ^ 2) := Real.cos_arcsin r
    set f : ℝ → ℝ := fun θ => max (-1) (min 1 (K * (A * Real.sin θ))) * Real.sin θ with hf
    have hfc : Continuous f := by rw [hf]; fun_prop
    have hI : ∫ θ in (0 : ℝ)..2 * π, f θ =
        4 * ((K * A) * ∫ θ in (0 : ℝ)..α, Real.sin θ ^ 2) + 4 * ∫ θ in α..π / 2, Real.sin θ := by
      rw [df_integral_two_pi_of_add_pi f hfc (fun x => by
            simp only [hf, Real.sin_add_pi, mul_neg, df_sat_neg]; ring),
        df_integral_pi_of_pi_sub f hfc (fun x => by simp only [hf, Real.sin_pi_sub]),
        ← integral_add_adjacent_intervals (hfc.intervalIntegrable 0 α)
          (hfc.intervalIntegrable α (π / 2))]
      have e1 : ∫ θ in (0 : ℝ)..α, f θ = ∫ θ in (0 : ℝ)..α, (K * A) * Real.sin θ ^ 2 := by
        refine integral_congr (fun x hx => ?_)
        rw [Set.uIcc_of_le hα0] at hx
        obtain ⟨hx1, hx2⟩ := hx
        have hs0 : 0 ≤ Real.sin x := Real.sin_nonneg_of_nonneg_of_le_pi hx1 (by linarith)
        have hs1 : Real.sin x ≤ r := by
          rw [← hsα]
          exact Real.sin_le_sin_of_le_of_le_pi_div_two (by linarith) hα2 hx2
        have hu : K * (A * Real.sin x) ≤ 1 := by
          have : K * A * Real.sin x ≤ K * A * r := mul_le_mul_of_nonneg_left hs1 hKA.le
          nlinarith
        have hl : -1 ≤ K * (A * Real.sin x) := by
          have : 0 ≤ K * A * Real.sin x := mul_nonneg hKA.le hs0
          nlinarith
        simp only [hf]
        rw [min_eq_right hu, max_eq_right hl]; ring
      have e2 : ∫ θ in α..π / 2, f θ = ∫ θ in α..π / 2, Real.sin θ := by
        refine integral_congr (fun x hx => ?_)
        rw [Set.uIcc_of_le hα2] at hx
        obtain ⟨hx1, hx2⟩ := hx
        have hs1 : r ≤ Real.sin x := by
          rw [← hsα]
          exact Real.sin_le_sin_of_le_of_le_pi_div_two (by linarith) hx2 hx1
        have hu : 1 ≤ K * (A * Real.sin x) := by
          have : K * A * r ≤ K * A * Real.sin x := mul_le_mul_of_nonneg_left hs1 hKA.le
          nlinarith
        simp only [hf]
        rw [min_eq_left hu, max_eq_right (by norm_num)]; ring
      rw [e1, e2, integral_const_mul]; ring
    rw [hI, integral_sin_sq, integral_sin, hsα, hcα]
    simp only [Real.sin_zero, Real.cos_zero, Real.cos_pi_div_two]
    have hpi' := hpi.ne'
    have hA' := hA.ne'
    have hK' := hK.ne'
    rw [show K * A = 1 / r by rw [eq_div_iff hr0.ne']; exact hKAr] 
    field_simp
    rw [hr]
    field_simp
    ring

/-- **Where the conveyor plant's phase reaches −180°.** For `G(s) = 1/(s(s+1)(s+2))` and an
angular frequency `ω > 0`, the frequency response `G(jω)` is real exactly when `ω = √2`, and
there `G(j√2) = −1/6`: a negative real number, so the phase is −180° and `|G| = 1/6`. -/
theorem conveyor_phase_crossover :
    (∀ ω : ℝ, 0 < ω →
      (((1 : ℂ) / ((ω * I) * ((ω * I) + 1) * ((ω * I) + 2))).im = 0 ↔ ω = Real.sqrt 2)) ∧
    (1 : ℂ) / (((Real.sqrt 2 : ℝ) * I) * (((Real.sqrt 2 : ℝ) * I) + 1) *
      (((Real.sqrt 2 : ℝ) * I) + 2)) = -1 / 6 := by
  have hden : ∀ ω : ℝ, ((ω : ℂ) * I) * (((ω : ℂ) * I) + 1) * (((ω : ℂ) * I) + 2) =
      ⟨-3 * ω ^ 2, ω * (2 - ω ^ 2)⟩ := by
    intro ω
    apply Complex.ext <;> simp <;> ring
  constructor
  · intro ω hω
    rw [hden, one_div, Complex.inv_im]
    simp only [Complex.normSq_mk]
    have hpos : 0 < -3 * ω ^ 2 * (-3 * ω ^ 2) + ω * (2 - ω ^ 2) * (ω * (2 - ω ^ 2)) := by
      have : 0 < ω ^ 2 := by positivity
      nlinarith [sq_nonneg (ω * (2 - ω ^ 2))]
    rw [div_eq_zero_iff, neg_eq_zero, mul_eq_zero]
    constructor
    · rintro ((h | h) | h)
      · exact absurd h hω.ne'
      · have h2 : ω ^ 2 = 2 := by linarith
        rw [← h2, Real.sqrt_sq hω.le]
      · exact absurd h hpos.ne'
    · intro h
      left; right
      rw [h, Real.sq_sqrt (by norm_num)]; ring
  · rw [hden]
    have h2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
    rw [h2]
    apply Complex.ext <;> norm_num

-- Worked numbers: the plant's denominator at ω = √2 is −3·2 = −6.
example : (((Real.sqrt 2 : ℝ) : ℂ) * I) * ((((Real.sqrt 2 : ℝ) : ℂ) * I) + 1) *
    ((((Real.sqrt 2 : ℝ) : ℂ) * I) + 2) = -6 := by
  have h : ((Real.sqrt 2 : ℝ) : ℂ) ^ 2 = 2 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
  linear_combination (((Real.sqrt 2 : ℝ) : ℂ) * I * (I ^ 2) + 3 * I ^ 2) * h +
    (3 * 2 + 2 * ((Real.sqrt 2 : ℝ) : ℂ) * I) * Complex.I_sq

-- Worked numbers: the balance 4/(πA) = 6 is met by A = 4/(6π).
example : 4 / (π * (4 / (6 * π))) = 6 := by
  have h := Real.pi_pos.ne'
  field_simp

#print axioms relay_describing_function
#print axioms saturation_describing_function
#print axioms conveyor_phase_crossover
