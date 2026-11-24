-- Impedance matching: a quarter-wave section of impedance sqrt(Z0 ZL) shows a line of impedance Z0 its own impedance, a lossless line only turns the reflection coefficient, and the Smith map sends passive loads into the unit disc.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Complex

/-- The impedance seen looking into a lossless line of characteristic impedance `Zc`, electrical
length `θ = βℓ`, ending in a load `ZL`: the card's formula
`Zc (ZL + j Zc tan βℓ) / (Zc + j ZL tan βℓ)` with top and bottom multiplied by `cos βℓ`,
so that it stays finite at a quarter wave. Mathlib writes `I` for the card's `j`. -/
noncomputable def zin (Zc ZL : ℂ) (θ : ℝ) : ℂ :=
  Zc * (ZL * Real.cos θ + I * Zc * Real.sin θ) / (Zc * Real.cos θ + I * ZL * Real.sin θ)

/-- The reflection coefficient of an impedance `Z` on a line of characteristic impedance `Z0`. -/
noncomputable def gamma (Z0 Z : ℂ) : ℂ := (Z - Z0) / (Z + Z0)

/-- Helper: `e^(-j 2θ) = (cos θ - j sin θ)²`. -/
theorem exp_neg_two_mul (θ : ℝ) :
    exp (-(2 * θ : ℝ) * I) = ((Real.cos θ : ℂ) - I * Real.sin θ) ^ 2 := by
  have : -(2 * θ : ℝ) * I = ((-θ : ℝ) * I) + ((-θ : ℝ) * I) := by push_cast; ring
  rw [this, Complex.exp_add, Complex.exp_mul_I]
  rw [← Complex.ofReal_cos, ← Complex.ofReal_sin, Real.cos_neg, Real.sin_neg]
  push_cast; ring

#print axioms exp_neg_two_mul

/-- Quarter-wave transformer: a real load `ZL` seen through a quarter wave (`βℓ = π/2`) of
lossless line whose impedance is the geometric mean `Z1 = √(Z0 ZL)` looks exactly like `Z0`,
so the main line sees no reflection. -/
theorem quarter_wave_transformer_matches (Z0 ZL : ℝ) (h0 : 0 < Z0) (hL : 0 < ZL) :
    zin (Real.sqrt (Z0 * ZL) : ℂ) (ZL : ℂ) (Real.pi / 2) = (Z0 : ℂ) := by
  unfold zin
  have hs : ((Real.sqrt (Z0 * ZL) : ℂ)) ^ 2 = (Z0 : ℂ) * ZL := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by positivity)]; push_cast; ring
  have hL' : (ZL : ℂ) ≠ 0 := by exact_mod_cast hL.ne'
  rw [Real.cos_pi_div_two, Real.sin_pi_div_two]
  push_cast
  simp only [mul_zero, zero_add, mul_one]
  rw [div_eq_iff (mul_ne_zero I_ne_zero hL')]
  linear_combination I * hs

/-- A lossless line only turns the reflection coefficient: moving an electrical length `θ = βd`
back from a passive load (resistance `≥ 0`) multiplies its reflection coefficient by
`e^(-j 2βd)`, so its size stays fixed and its angle turns clockwise. The hypothesis `hfin` says the
input impedance is finite at that point. -/
theorem lossless_line_turns_reflection (Z0 : ℝ) (h0 : 0 < Z0) (ZL : ℂ) (hL : 0 ≤ ZL.re) (θ : ℝ)
    (hfin : (Z0 : ℂ) * Real.cos θ + I * ZL * Real.sin θ ≠ 0) :
    gamma Z0 (zin Z0 ZL θ) = gamma Z0 ZL * exp (-(2 * θ : ℝ) * I) := by
  rw [exp_neg_two_mul]
  set c : ℂ := (Real.cos θ : ℂ) with hc
  set s : ℂ := (Real.sin θ : ℂ) with hs
  have hcs : c ^ 2 + s ^ 2 = 1 := by
    rw [hc, hs]; exact_mod_cast Real.cos_sq_add_sin_sq θ
  have hZ0 : (Z0 : ℂ) ≠ 0 := by exact_mod_cast h0.ne'
  have hsum : ZL + (Z0 : ℂ) ≠ 0 := by
    intro h
    have := congrArg Complex.re h
    simp at this
    linarith
  have hE : c + I * s ≠ 0 := by
    intro h
    have : (c - I * s) * (c + I * s) = 1 := by linear_combination hcs - s ^ 2 * I_sq
    rw [h, mul_zero] at this
    exact zero_ne_one this
  have e : (ZL - Z0) / (ZL + Z0) * (ZL + Z0) = ZL - Z0 := div_mul_cancel₀ _ hsum
  unfold gamma zin
  have h1 : (Z0 : ℂ) * (ZL * c + I * Z0 * s) / (Z0 * c + I * ZL * s) - Z0
      = Z0 * (ZL - Z0) * (c - I * s) / (Z0 * c + I * ZL * s) := by
    rw [eq_div_iff hfin, sub_mul, div_mul_cancel₀ _ hfin]; ring
  have h2 : (Z0 : ℂ) * (ZL * c + I * Z0 * s) / (Z0 * c + I * ZL * s) + Z0
      = Z0 * (ZL + Z0) * (c + I * s) / (Z0 * c + I * ZL * s) := by
    rw [eq_div_iff hfin, add_mul, div_mul_cancel₀ _ hfin]; ring
  rw [h1, h2, div_div_div_cancel_right₀ hfin]
  rw [div_eq_iff (mul_ne_zero (mul_ne_zero hZ0 hsum) hE)]
  linear_combination (Z0 : ℂ) * (c - I * s) *
    (-(ZL - Z0) * hcs + (ZL - Z0) * s ^ 2 * I_sq - (c - I * s) * (c + I * s) * e)

/-- The Smith chart: the map `Γ = (z - 1)/(z + 1)` sends a normalised impedance `z` into the
closed unit disc exactly when its resistance `r = Re z` is at least zero, so every passive load
lands inside the chart. -/
theorem smith_map_disc_iff_passive (z : ℂ) (hz : z ≠ -1) :
    ‖(z - 1) / (z + 1)‖ ≤ 1 ↔ 0 ≤ z.re := by
  have hz1 : z + 1 ≠ 0 := by
    intro h; exact hz (eq_neg_of_add_eq_zero_left h)
  have hpos : 0 < ‖z + 1‖ := norm_pos_iff.mpr hz1
  rw [norm_div, div_le_one hpos, ← sq_le_sq₀ (norm_nonneg _) (norm_nonneg _),
    Complex.sq_norm, Complex.sq_norm, Complex.normSq_apply, Complex.normSq_apply]
  simp
  constructor <;> intro h <;> nlinarith

/-! The card's exact worked numbers. -/

-- The 75 Ω antenna on bare 50 Ω coax: Γ = (75 - 50)/(75 + 50) = 1/5 and VSWR = 3/2.
example : ((75 : ℚ) - 50) / (75 + 50) = 1 / 5 := by norm_num
example : (1 + (1 / 5 : ℚ)) / (1 - 1 / 5) = 3 / 2 := by norm_num

-- The quarter-wave check: Z1² = 50 × 75 = 3750, and 3750 / 75 = 50 Ω.
example : ((50 : ℚ) * 75) / 75 = 50 := by norm_num

-- The 25 + j25 Ω whip: z = 1/2 + j/2, Γ = -1/5 + 2j/5, |Γ|² = 1/5 (20 % of the power), y = 1 - j.
example : ((25 + 25 * I) / 50 : ℂ) = 1 / 2 + 1 / 2 * I := by
  apply Complex.ext <;> norm_num
example : (((1 / 2 + 1 / 2 * I) - 1) / ((1 / 2 + 1 / 2 * I) + 1) : ℂ) = -1 / 5 + 2 / 5 * I := by
  apply Complex.ext <;> norm_num [Complex.div_re, Complex.div_im, Complex.normSq]
example : Complex.normSq (-1 / 5 + 2 / 5 * I) = 1 / 5 := by
  norm_num [Complex.normSq_apply]
example : (1 / (1 / 2 + 1 / 2 * I) : ℂ) = 1 - I := by
  apply Complex.ext <;> norm_num [Complex.div_re, Complex.div_im, Complex.normSq]

-- The whip's point lies on the r = 1/2 circle, centre 1/3, radius 2/3.
example : ((-1 / 5 : ℚ) - 1 / 3) ^ 2 + (2 / 5) ^ 2 = (2 / 3) ^ 2 := by norm_num

-- At point B the admittance is (1 + 1/5 + 2j/5)/(1 - 1/5 - 2j/5) = 1 + j.
example : ((1 + 1 / 5 + 2 / 5 * I) / (1 - 1 / 5 - 2 / 5 * I) : ℂ) = 1 + I := by
  apply Complex.ext <;> norm_num [Complex.div_re, Complex.div_im, Complex.normSq]

-- The wrong quarter wave on the whip: Z1² = 50 × 25 = 1250, and 1250 / (25 + j25) = 25 - j25.
example : ((1250 : ℂ) / (25 + 25 * I)) = 25 - 25 * I := by
  apply Complex.ext <;> norm_num [Complex.div_re, Complex.div_im, Complex.normSq]

#print axioms quarter_wave_transformer_matches
#print axioms lossless_line_turns_reflection
#print axioms smith_map_disc_iff_passive
