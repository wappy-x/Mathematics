-- Hedging three Greeks at once: when the gamma-vega determinant D is not zero, the hedge equations have exactly one solution, given by Cramer's rule with the shares solved last; D is zero for two Black-Scholes options with the same expiry.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic

open Real

/-- Cramer's rule for the three-Greek hedge. The book has Greeks `ΔP, ΓP, VP`; one option A
has `ΔA, ΓA, VA`; one option B has `ΔB, ΓB, VB`; a share has delta 1, gamma 0, vega 0.
If `D = ΓA·VB − ΓB·VA` is not zero, then buying `nS` shares, `nA` of A and `nB` of B makes
the book's delta, gamma and vega all zero exactly when
`nA = (ΓB·VP − ΓP·VB)/D`, `nB = (ΓP·VA − ΓA·VP)/D` and `nS = −(ΔP + nA·ΔA + nB·ΔB)`. -/
theorem delta_gamma_vega_hedge_cramer
    (ΔP ΓP VP ΔA ΓA VA ΔB ΓB VB nS nA nB : ℝ)
    (hD : ΓA * VB - ΓB * VA ≠ 0) :
    (nS * 1 + nA * ΔA + nB * ΔB = -ΔP ∧
      nS * 0 + nA * ΓA + nB * ΓB = -ΓP ∧
      nS * 0 + nA * VA + nB * VB = -VP) ↔
    (nA = (ΓB * VP - ΓP * VB) / (ΓA * VB - ΓB * VA) ∧
      nB = (ΓP * VA - ΓA * VP) / (ΓA * VB - ΓB * VA) ∧
      nS = -(ΔP + nA * ΔA + nB * ΔB)) := by
  constructor
  · rintro ⟨h1, h2, h3⟩
    refine ⟨?_, ?_, ?_⟩
    · rw [eq_div_iff hD]
      linear_combination VB * h2 - ΓB * h3
    · rw [eq_div_iff hD]
      linear_combination ΓA * h3 - VA * h2
    · linarith
  · rintro ⟨h1, h2, h3⟩
    refine ⟨?_, ?_, ?_⟩
    · rw [h3]; ring
    · rw [h1, h2, mul_zero, zero_add, div_mul_eq_mul_div, div_mul_eq_mul_div,
        ← add_div, div_eq_iff hD]
      ring
    · rw [h1, h2, mul_zero, zero_add, div_mul_eq_mul_div, div_mul_eq_mul_div,
        ← add_div, div_eq_iff hD]
      ring

/-- Existence and uniqueness: the three hedge equations have exactly one solution
`(nS, nA, nB)` if and only if the determinant `D = ΓA·VB − ΓB·VA` is not zero.
When `D = 0` there is either no answer or a whole line of them. -/
theorem hedge_unique_iff_det_ne_zero
    (ΔP ΓP VP ΔA ΓA VA ΔB ΓB VB : ℝ) :
    (∃! n : ℝ × ℝ × ℝ,
      n.1 * 1 + n.2.1 * ΔA + n.2.2 * ΔB = -ΔP ∧
      n.1 * 0 + n.2.1 * ΓA + n.2.2 * ΓB = -ΓP ∧
      n.1 * 0 + n.2.1 * VA + n.2.2 * VB = -VP) ↔
    ΓA * VB - ΓB * VA ≠ 0 := by
  constructor
  · rintro ⟨n, hn, huniq⟩ hD
    have key : ∀ ka kb : ℝ, ka * ΓA + kb * ΓB = 0 → ka * VA + kb * VB = 0 →
        ka = 0 ∧ kb = 0 := by
      intro ka kb hk1 hk2
      have e := huniq (n.1 - ka * ΔA - kb * ΔB, n.2.1 + ka, n.2.2 + kb)
        ⟨by simp only; linarith [hn.1], by simp only; linarith [hn.2.1],
          by simp only; linarith [hn.2.2]⟩
      have e2 := congrArg (fun m : ℝ × ℝ × ℝ => m.2.1) e
      have e3 := congrArg (fun m : ℝ × ℝ × ℝ => m.2.2) e
      simp only at e2 e3
      constructor <;> linarith
    obtain ⟨hg1, hg2⟩ := key ΓB (-ΓA) (by ring) (by linarith)
    obtain ⟨hv1, hv2⟩ := key VB (-VA) (by linarith) (by ring)
    have := key 1 0 (by rw [neg_eq_zero.mp hg2]; ring) (by rw [neg_eq_zero.mp hv2]; ring)
    norm_num at this
  · intro hD
    refine ⟨(-(ΔP + (ΓB * VP - ΓP * VB) / (ΓA * VB - ΓB * VA) * ΔA
        + (ΓP * VA - ΓA * VP) / (ΓA * VB - ΓB * VA) * ΔB),
        (ΓB * VP - ΓP * VB) / (ΓA * VB - ΓB * VA),
        (ΓP * VA - ΓA * VP) / (ΓA * VB - ΓB * VA)), ?_, ?_⟩
    · exact (delta_gamma_vega_hedge_cramer ΔP ΓP VP ΔA ΓA VA ΔB ΓB VB _ _ _ hD).mpr
        ⟨rfl, rfl, rfl⟩
    · rintro ⟨s, a, b⟩ h
      obtain ⟨h1, h2, h3⟩ :=
        (delta_gamma_vega_hedge_cramer ΔP ΓP VP ΔA ΓA VA ΔB ΓB VB s a b hD).mp h
      subst h1 h2
      rw [h3]

/-- Under Black-Scholes, with share price `S > 0`, volatility `σ > 0`, expiry `T > 0` and
dividend yield `q`, an option whose first distance is `d` has gamma
`e^(−qT) φ(d) / (S σ √T)` and vega per point `S e^(−qT) φ(d) √T / 100`, where `φ` is the
bell-curve height. Then vega over gamma is `S² σ T / 100` whatever the strike (whatever `d`),
so two options with the same expiry have determinant `D = 0`. -/
theorem same_expiry_vega_gamma_ratio_and_det_zero
    (S σ T q dA dB : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    let φ : ℝ → ℝ := fun x => Real.exp (-(x ^ 2) / 2) / Real.sqrt (2 * π)
    let Γ : ℝ → ℝ := fun d => Real.exp (-q * T) * φ d / (S * σ * Real.sqrt T)
    let V : ℝ → ℝ := fun d => S * Real.exp (-q * T) * φ d * Real.sqrt T / 100
    (V dA / Γ dA = S ^ 2 * σ * T / 100) ∧ (Γ dA * V dB - Γ dB * V dA = 0) := by
  intro φ Γ V
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hsq : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
  have hφ : ∀ x, 0 < φ x := fun x => by
    simp only [φ]; positivity
  have he : 0 < Real.exp (-q * T) := Real.exp_pos _
  have hφA := hφ dA
  have hφB := hφ dB
  constructor
  · simp only [V, Γ]
    field_simp
    exact hsq
  · simp only [V, Γ]
    field_simp
    ring

-- Vega-to-gamma ratio 20·T at S = 100, σ = 0.20: option A (T = 1/4), the book (T = 1), option B (T = 2).
example : (100 : ℚ) ^ 2 * (1 / 5) * (1 / 4) / 100 = 5 := by norm_num
example : (100 : ℚ) ^ 2 * (1 / 5) * 1 / 100 = 20 := by norm_num
example : (100 : ℚ) ^ 2 * (1 / 5) * 2 / 100 = 40 := by norm_num

-- The hedge as a blend: gamma shares wA = (40 − 20)/(40 − 5) = 4/7 and wB = 3/7
-- satisfy wA + wB = 1 and 5·wA + 40·wB = 20.
example : ((40 : ℚ) - 20) / (40 - 5) = 4 / 7 ∧ ((20 : ℚ) - 5) / (40 - 5) = 3 / 7 := by norm_num
example : (4 / 7 : ℚ) + 3 / 7 = 1 ∧ 5 * (4 / 7 : ℚ) + 40 * (3 / 7) = 20 := by norm_num

#print axioms delta_gamma_vega_hedge_cramer
#print axioms hedge_unique_iff_det_ne_zero
#print axioms same_expiry_vega_gamma_ratio_and_det_zero
