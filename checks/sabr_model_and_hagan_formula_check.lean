-- SABR and Hagan's formula: the exact pieces of Hagan's formula, namely chi as an integral of one over the route's volatility, the zero-correlation smile, and the unique alpha behind an at-the-money quote.
import Mathlib.Analysis.SpecialFunctions.Arsinh
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open Real

/-- Hagan's helper chi(z) = ln((sqrt(1 - 2 rho z + z^2) + z - rho) / (1 - rho)), written on the card. -/
noncomputable def sabrChi (ρ z : ℝ) : ℝ :=
  Real.log ((Real.sqrt (1 - 2 * ρ * z + z ^ 2) + z - ρ) / (1 - ρ))

lemma sabr_q_pos (ρ y : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) : 0 < 1 - 2 * ρ * y + y ^ 2 := by
  nlinarith [sq_nonneg (y - ρ)]

#print axioms sabr_q_pos

lemma sabr_arg_pos (ρ y : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    0 < Real.sqrt (1 - 2 * ρ * y + y ^ 2) + y - ρ := by
  have : ρ - y < Real.sqrt (1 - 2 * ρ * y + y ^ 2) := by
    apply Real.lt_sqrt_of_sq_lt
    nlinarith
  linarith

#print axioms sabr_arg_pos

lemma sabr_hasDerivAt (ρ y : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    HasDerivAt (fun y => Real.log (Real.sqrt (1 - 2 * ρ * y + y ^ 2) + y - ρ) - Real.log (1 - ρ))
      (1 / Real.sqrt (1 - 2 * ρ * y + y ^ 2)) y := by
  have hq := sabr_q_pos ρ y hρ₁ hρ₂
  have ha := sabr_arg_pos ρ y hρ₁ hρ₂
  have hs : 0 < Real.sqrt (1 - 2 * ρ * y + y ^ 2) := Real.sqrt_pos.mpr hq
  have h1 : HasDerivAt (fun y : ℝ => 1 - 2 * ρ * y + y ^ 2) (-(2 * ρ) + 2 * y) y := by
    have := ((hasDerivAt_id y).const_mul (2 * ρ)).const_sub 1 |>.add ((hasDerivAt_id y).pow 2)
    convert this using 1
    · ext t; simp
    · simp
  have h2 := ((h1.sqrt hq.ne').add (hasDerivAt_id y)).sub_const ρ
  have h3 := (h2.log (by simpa using ha.ne')).sub_const (Real.log (1 - ρ))
  convert h3 using 1
  have hsq : Real.sqrt (1 - 2 * ρ * y + y ^ 2) ^ 2 = 1 - 2 * ρ * y + y ^ 2 := Real.sq_sqrt hq.le
  show 1 / √(1 - 2 * ρ * y + y ^ 2) = ((-(2 * ρ) + 2 * y) / (2 * √(1 - 2 * ρ * y + y ^ 2)) + 1)
    / (√(1 - 2 * ρ * y + y ^ 2) + y - ρ)
  rw [eq_div_iff ha.ne']
  · field_simp
    ring
  · rfl

#print axioms sabr_hasDerivAt

lemma sabr_arsinh_lt_self (z : ℝ) (hz : 0 < z) : Real.arsinh z < z := by
  have h := Real.arsinh_lt_arsinh.mpr (Real.self_lt_sinh_iff.mpr hz)
  rwa [Real.arsinh_sinh] at h

#print axioms sabr_arsinh_lt_self

/-- For any correlation rho strictly between -1 and 1 and any scaled log-distance z, Hagan's chi
in closed form equals the integral from 0 to z of 1 / sqrt(1 - 2 rho y + y^2): the leading term is a
harmonic average of the volatility alpha * sqrt(1 - 2 rho y + y^2) met along the cheapest route. -/
theorem sabr_chi_eq_integral (ρ z : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) :
    sabrChi ρ z = ∫ y in (0 : ℝ)..z, 1 / Real.sqrt (1 - 2 * ρ * y + y ^ 2) := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun y _ => sabr_hasDerivAt ρ y hρ₁ hρ₂)]
  · have h1 : (1 : ℝ) - ρ ≠ 0 := by linarith
    simp only [sabrChi]
    rw [Real.log_div (sabr_arg_pos ρ z hρ₁ hρ₂).ne' h1]
    simp
  · apply Continuous.intervalIntegrable
    apply Continuous.div continuous_const
    · fun_prop
    · intro y; exact (Real.sqrt_pos.mpr (sabr_q_pos ρ y hρ₁ hρ₂)).ne'

/-- With zero correlation, chi(z) is arcsinh(z), and for every nonzero z the bend z / chi(z) is
above 1 and the same at z and -z: the volatility exceeds its level on both sides of the forward,
a smile symmetric in log-strike. -/
theorem sabr_zero_correlation_smile (z : ℝ) (hz : z ≠ 0) :
    sabrChi 0 z = Real.arsinh z ∧ 1 < z / sabrChi 0 z ∧
      (-z) / sabrChi 0 (-z) = z / sabrChi 0 z := by
  have hc : ∀ w : ℝ, sabrChi 0 w = Real.arsinh w := by
    intro w
    simp only [sabrChi, Real.arsinh]
    congr 1
    ring_nf
  refine ⟨hc z, ?_, ?_⟩
  · rw [hc z]
    rcases lt_or_gt_of_ne hz with h | h
    · have h1 := sabr_arsinh_lt_self (-z) (by linarith)
      rw [Real.arsinh_neg] at h1
      have h2 : Real.arsinh z < 0 := Real.arsinh_neg_iff.mpr h
      rw [lt_div_iff_of_neg h2]; linarith
    · have h1 := sabr_arsinh_lt_self z h
      have h2 : 0 < Real.arsinh z := Real.arsinh_pos_iff.mpr h
      rw [lt_div_iff₀ h2]; linarith
  · rw [hc, hc, Real.arsinh_neg, neg_div_neg_eq]

/-- At beta = 1 the at-the-money quote sigma is the quadratic A * alpha + B * alpha^2 in alpha, with
A = 1 + (2 - 3 rho^2) nu^2 T / 24 and B = rho nu T / 4. For a calm volatility (nu^2 T < 24) and a
quote sigma >= 0 not above the hill's peak (A^2 + rho nu T sigma >= 0), the alpha on the rising side
(A + 2 B alpha >= 0) that gives the quote exists, is unique, is nonnegative, and equals the small root
2 sigma / (A + sqrt(A^2 + rho nu T sigma)). -/
theorem sabr_atm_alpha_small_root (ρ ν T σ : ℝ) (hρ₁ : -1 < ρ) (hρ₂ : ρ < 1) (hT : 0 ≤ T)
    (hcalm : ν ^ 2 * T < 24) (hσ : 0 ≤ σ)
    (hpeak : 0 ≤ (1 + (2 - 3 * ρ ^ 2) / 24 * ν ^ 2 * T) ^ 2 + ρ * ν * T * σ) :
    let A := 1 + (2 - 3 * ρ ^ 2) / 24 * ν ^ 2 * T
    let B := ρ * ν * T / 4
    let α₀ := 2 * σ / (A + Real.sqrt (A ^ 2 + ρ * ν * T * σ))
    0 ≤ α₀ ∧ ∀ α : ℝ, (0 ≤ A + 2 * B * α ∧ A * α + B * α ^ 2 = σ) ↔ α = α₀ := by
  intro A B α₀
  have hνT : 0 ≤ ν ^ 2 * T := mul_nonneg (sq_nonneg ν) hT
  have hA : 0 < A := by
    simp only [A]
    have : 0 ≤ (1 - ρ ^ 2) * (ν ^ 2 * T) := mul_nonneg (by nlinarith) hνT
    nlinarith
  set s := Real.sqrt (A ^ 2 + ρ * ν * T * σ) with hs_def
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs2 : s ^ 2 = A ^ 2 + ρ * ν * T * σ := Real.sq_sqrt hpeak
  have hden : 0 < A + s := by linarith
  refine ⟨div_nonneg (by linarith) hden.le, fun α => ⟨?_, ?_⟩⟩
  · rintro ⟨h1, h2⟩
    have hsq : (A + 2 * B * α) ^ 2 = s ^ 2 := by
      rw [hs2]; simp only [B] at h2 ⊢; rw [← h2]; ring
    have he : A + 2 * B * α = s := by
      have := (sq_eq_sq₀ h1 hs0).mp hsq
      exact this
    simp only [α₀]
    rw [eq_div_iff hden.ne']
    rw [← he, ← h2]; ring
  · intro hα
    have hα' : α * (A + s) = 2 * σ := by
      rw [hα]; simp only [α₀]; rw [← hs_def]; field_simp
    have he : A + 2 * B * α = s := by
      have : (A + 2 * B * α) * (A + s) = s * (A + s) := by
        have : (A + 2 * B * α) * (A + s) = A * (A + s) + B * 2 * (α * (A + s)) := by ring
        rw [this, hα']; simp only [B]; nlinarith [hs2]
      exact mul_right_cancel₀ hden.ne' this
    refine ⟨by rw [he]; exact hs0, ?_⟩
    have : A * α + B * α ^ 2 = α * (A + 2 * B * α + A) / 2 := by ring
    rw [this, he]
    linarith [hα']

#print axioms sabr_chi_eq_integral
#print axioms sabr_zero_correlation_smile
#print axioms sabr_atm_alpha_small_root
