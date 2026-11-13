-- Pricing Heston exactly: the closed-form exponents B and A of Heston's characteristic function solve the model's two equations in time, and with the stable root the logarithm inside A never reaches its cut.
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Complex.RealDeriv

open Complex

namespace HestonCF

/-- The pull speed bent by the correlation: `β = κ - ρ ξ i u`. -/
noncomputable def beta (κ ξ ρ : ℝ) (u : ℂ) : ℂ := κ - ρ * ξ * I * u

/-- The ratio of the two roots of the Riccati quadratic: `g = (β - d) / (β + d)`. -/
noncomputable def g (β d : ℂ) : ℂ := (β - d) / (β + d)

/-- The card's `B` at `τ` years left:
`B(τ) = (β - d)/ξ² · (1 - e^{-dτ}) / (1 - g e^{-dτ})`. -/
noncomputable def B (ξ : ℝ) (β d : ℂ) (τ : ℝ) : ℂ :=
  (β - d) / (ξ : ℂ) ^ 2 * ((1 - exp (-d * τ)) / (1 - g β d * exp (-d * τ)))

/-- The card's `A` at `τ` years left:
`A(τ) = (r - q) i u τ + κθ/ξ² [(β - d) τ - 2 ln((1 - g e^{-dτ}) / (1 - g))]`,
with `ln` the computer's (principal) complex logarithm. -/
noncomputable def A (r q κ θ ξ : ℝ) (u β d : ℂ) (τ : ℝ) : ℂ :=
  (r - q) * I * u * τ + (κ : ℂ) * θ / (ξ : ℂ) ^ 2 *
    ((β - d) * τ - 2 * log ((1 - g β d * exp (-d * τ)) / (1 - g β d)))

theorem riccati_alg (β d ξ E a : ℂ) (hξ : ξ ≠ 0) (hβd : β + d ≠ 0)
    (hden : (β + d) - (β - d) * E ≠ 0) (ha : ξ ^ 2 * a = d ^ 2 - β ^ 2) :
    (β - d) / ξ ^ 2 * ((-(E * (-d * 1)) * (1 - (β - d) / (β + d) * E)
        - (1 - E) * (-((β - d) / (β + d) * (E * (-d * 1))))) / (1 - (β - d) / (β + d) * E) ^ 2)
      = ξ ^ 2 / 2 * ((β - d) / ξ ^ 2 * ((1 - E) / (1 - (β - d) / (β + d) * E))) ^ 2
        - β * ((β - d) / ξ ^ 2 * ((1 - E) / (1 - (β - d) / (β + d) * E))) - a / 2 := by
  have h1 : 1 - (β - d) / (β + d) * E = ((β + d) - (β - d) * E) / (β + d) := by
    field_simp
  have ha' : a = (d ^ 2 - β ^ 2) / ξ ^ 2 := by
    rw [← ha]; field_simp
  rw [h1, ha']
  field_simp
  ring

#print axioms riccati_alg

theorem den_eq (β d E : ℂ) (hβd : β + d ≠ 0) :
    1 - (β - d) / (β + d) * E = ((β + d) - (β - d) * E) / (β + d) := by
  field_simp

#print axioms den_eq

theorem log_alg (β d E : ℂ) (hβd : β + d ≠ 0)
    (hden : (β + d) - (β - d) * E ≠ 0) (hd0 : d ≠ 0) :
    (β - d) - 2 * ((-((β - d) / (β + d) * (E * (-d * 1))) / (1 - (β - d) / (β + d))) /
        ((1 - (β - d) / (β + d) * E) / (1 - (β - d) / (β + d))))
      = (β - d) * ((1 - E) / (1 - (β - d) / (β + d) * E)) := by
  have h1 : 1 - (β - d) / (β + d) * E = ((β + d) - (β - d) * E) / (β + d) := by
    field_simp
  have h2 : 1 - (β - d) / (β + d) = 2 * d / (β + d) := by
    field_simp; ring
  rw [h1, h2]
  field_simp
  ring

#print axioms log_alg

theorem norm_g_exp_lt_one (g d : ℂ) (τ : ℝ) (hd : 0 ≤ d.re) (hg : ‖g‖ < 1) (hτ : 0 ≤ τ) :
    ‖g * exp (-d * τ)‖ < 1 := by
  rw [norm_mul, Complex.norm_exp]
  have h1 : (-d * (τ : ℂ)).re = -(d.re * τ) := by simp
  have h2 : Real.exp (-d * (τ : ℂ)).re ≤ 1 := by
    rw [h1, Real.exp_le_one_iff]; nlinarith
  calc ‖g‖ * Real.exp (-d * (τ : ℂ)).re ≤ ‖g‖ * 1 :=
        mul_le_mul_of_nonneg_left h2 (norm_nonneg _)
    _ < 1 := by simpa using hg

#print axioms norm_g_exp_lt_one

theorem one_sub_re_pos (w : ℂ) (hw : ‖w‖ < 1) : 0 < (1 - w).re := by
  have := Complex.re_le_norm w
  simp; linarith

#print axioms one_sub_re_pos

theorem one_sub_ne_zero_of_norm_lt (w : ℂ) (hw : ‖w‖ < 1) : 1 - w ≠ 0 := by
  intro h; have := one_sub_re_pos w hw; rw [h] at this; simp at this

#print axioms one_sub_ne_zero_of_norm_lt

theorem off_cut (g d : ℂ) (τ : ℝ) (hd : 0 ≤ d.re) (hg : ‖g‖ < 1) (hτ : 0 ≤ τ) :
    (1 - g * exp (-d * τ)) / (1 - g) ∈ slitPlane := by
  have h1 := one_sub_re_pos _ (norm_g_exp_lt_one g d τ hd hg hτ)
  have h2 := one_sub_re_pos g hg
  have h2' : 1 - g ≠ 0 := one_sub_ne_zero_of_norm_lt g hg
  rw [mem_slitPlane_iff]
  by_contra hcon
  simp only [not_or, not_lt, not_not] at hcon
  obtain ⟨hre, him⟩ := hcon
  set w := (1 - g * exp (-d * τ)) / (1 - g) with hw
  have hw' : 1 - g * exp (-d * τ) = w * (1 - g) := by rw [hw]; field_simp
  have hwr : w = (w.re : ℂ) := by apply Complex.ext <;> simp [him]
  have : (1 - g * exp (-d * τ)).re = w.re * (1 - g).re := by
    rw [hw', hwr]; simp
  rw [this] at h1
  nlinarith

#print axioms off_cut

/-- Heston's `B` is exact: with `d` a square root of `β² + ξ²(u² + iu)` whose real part is not
negative, the closed form `B` starts at 0 and solves the Riccati equation
`B' = ½ ξ² B² - β B - ½ (u² + iu)` at every `τ ≥ 0`. -/
theorem heston_B_solves_riccati (κ ξ ρ : ℝ) (u d : ℂ) (τ : ℝ)
    (hξ : 0 < ξ)
    (hdsq : d ^ 2 = beta κ ξ ρ u ^ 2 + (ξ : ℂ) ^ 2 * (u ^ 2 + I * u))
    (hd : 0 ≤ d.re)
    (hβd : beta κ ξ ρ u + d ≠ 0)
    (hg : ‖g (beta κ ξ ρ u) d‖ < 1)
    (hτ : 0 ≤ τ) :
    B ξ (beta κ ξ ρ u) d 0 = 0 ∧
    HasDerivAt (fun t : ℝ => B ξ (beta κ ξ ρ u) d t)
      ((ξ : ℂ) ^ 2 / 2 * B ξ (beta κ ξ ρ u) d τ ^ 2
        - beta κ ξ ρ u * B ξ (beta κ ξ ρ u) d τ - (u ^ 2 + I * u) / 2) τ := by
  constructor
  · simp [B]
  · set β := beta κ ξ ρ u with hβ
    have hξ0 : (ξ : ℂ) ≠ 0 := by exact_mod_cast hξ.ne'
    have hden : 1 - g β d * exp (-d * τ) ≠ 0 :=
      one_sub_ne_zero_of_norm_lt _ (norm_g_exp_lt_one _ d τ hd hg hτ)
    have hden' : (β + d) - (β - d) * exp (-d * τ) ≠ 0 := by
      intro h; apply hden; unfold g; rw [den_eq β d _ hβd, h, zero_div]
    have he : HasDerivAt (fun z : ℂ => exp (-d * z)) (exp (-d * τ) * (-d * 1)) (τ : ℂ) :=
      ((hasDerivAt_id (τ : ℂ)).const_mul (-d)).cexp
    have hF := (((he.const_sub 1).div ((he.const_mul (g β d)).const_sub 1) hden).const_mul
      ((β - d) / (ξ : ℂ) ^ 2)).comp_ofReal
    convert hF using 1
    · rfl
    · unfold B g
      exact (riccati_alg β d ξ (exp (-d * τ)) (u ^ 2 + I * u) hξ0 hβd hden'
        (by linear_combination -hdsq)).symm

/-- Heston's `A` is exact: under the same conditions, the closed form `A` (with the computer's
logarithm) starts at 0 and solves `A' = (r - q) i u + κ θ B` at every `τ ≥ 0`, so it is the
integral of `B` the card derives. -/
theorem heston_A_solves_its_equation (r q κ θ ξ ρ : ℝ) (u d : ℂ) (τ : ℝ)
    (hξ : 0 < ξ)
    (hdsq : d ^ 2 = beta κ ξ ρ u ^ 2 + (ξ : ℂ) ^ 2 * (u ^ 2 + I * u))
    (hd : 0 ≤ d.re)
    (hβd : beta κ ξ ρ u + d ≠ 0)
    (hg : ‖g (beta κ ξ ρ u) d‖ < 1)
    (hτ : 0 ≤ τ) :
    A r q κ θ ξ u (beta κ ξ ρ u) d 0 = 0 ∧
    HasDerivAt (fun t : ℝ => A r q κ θ ξ u (beta κ ξ ρ u) d t)
      ((r - q) * I * u + (κ : ℂ) * θ * B ξ (beta κ ξ ρ u) d τ) τ := by
  set β := beta κ ξ ρ u with hβ
  have h1g : 1 - g β d ≠ 0 := one_sub_ne_zero_of_norm_lt _ hg
  constructor
  · simp [A, div_self h1g]
  · have hden : 1 - g β d * exp (-d * τ) ≠ 0 :=
      one_sub_ne_zero_of_norm_lt _ (norm_g_exp_lt_one _ d τ hd hg hτ)
    have hden' : (β + d) - (β - d) * exp (-d * τ) ≠ 0 := by
      intro h; apply hden; unfold g; rw [den_eq β d _ hβd, h, zero_div]
    have hd0 : d ≠ 0 := by
      rintro rfl
      have hβ0 : β ≠ 0 := by simpa using hβd
      simp [g, div_self hβ0] at hg
    have he : HasDerivAt (fun z : ℂ => exp (-d * z)) (exp (-d * τ) * (-d * 1)) (τ : ℂ) :=
      ((hasDerivAt_id (τ : ℂ)).const_mul (-d)).cexp
    have hL := ((((he.const_mul (g β d)).const_sub 1).div_const (1 - g β d)).clog
      (off_cut (g β d) d τ hd hg hτ))
    have hT : HasDerivAt (fun z : ℂ => z) 1 (τ : ℂ) := hasDerivAt_id' _
    have hF := ((hT.const_mul ((r - q) * I * u)).add
      (((hT.const_mul (β - d)).sub (hL.const_mul 2)).const_mul
        ((κ : ℂ) * θ / (ξ : ℂ) ^ 2))).comp_ofReal
    convert hF using 1
    · rfl
    · unfold B g
      have hX := log_alg β d (exp (-d * τ)) hβd hden' hd0
      linear_combination -((κ : ℂ) * θ / (ξ : ℂ) ^ 2) * hX

/-- The stable layout keeps the logarithm off its cut: if the root `d` has a real part that is
not negative, `g` is shorter than 1 and `τ ≥ 0`, then the number inside the logarithm,
`(1 - g e^{-dτ}) / (1 - g)`, never lies on the cut (zero or the negative real axis). -/
theorem stable_layout_log_argument_off_cut (g d : ℂ) (τ : ℝ)
    (hd : 0 ≤ d.re) (hg : ‖g‖ < 1) (hτ : 0 ≤ τ) :
    (1 - g * exp (-d * τ)) / (1 - g) ∈ slitPlane := by
  exact off_cut g d τ hd hg hτ

/-- Worked numbers, frequency 1: `β = 2 - (-0.7)(0.3) i = 2 + 0.21 i`. -/
example : beta 2 (3 / 10) (-7 / 10) 1 = 2 + 21 / 100 * I := by
  unfold beta; apply Complex.ext <;> simp <;> norm_num

/-- Worked numbers, frequency 1: `β² + ξ²(u² + iu) = 4.0459 + 0.93 i`. -/
example : beta 2 (3 / 10) (-7 / 10) 1 ^ 2 + ((3 / 10 : ℝ) : ℂ) ^ 2 * (1 ^ 2 + I * 1)
    = 40459 / 10000 + 93 / 100 * I := by
  unfold beta; apply Complex.ext <;> simp [pow_two] <;> norm_num

#print axioms heston_B_solves_riccati
#print axioms heston_A_solves_its_equation
#print axioms stable_layout_log_argument_off_cut

end HestonCF
