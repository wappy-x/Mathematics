-- The Kuramoto model: for a Lorentzian spread of speeds the critical coupling is twice the half-width and above it r = √(1 - K_c/K) solves the self-consistency equation exactly, and below the threshold no bunched crowd solves it for any one-peaked symmetric spread.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.Tactic

open Real

/-- The Lorentzian spread of natural frequencies with half-width `γ`:
`g(ω) = γ / (π (ω² + γ²))`. -/
noncomputable def lorentzian (γ ω : ℝ) : ℝ := γ / (π * (ω ^ 2 + γ ^ 2))

/-- The critical coupling of a spread `g` of natural frequencies: `K_c = 2 / (π g(0))`. -/
noncomputable def criticalCoupling (g : ℝ → ℝ) : ℝ := 2 / (π * g 0)

/-- Algebra behind the derivative of the antiderivative used for the Lorentzian integral. -/
theorem kuramoto_arctan_deriv_alg (x y s γ a : ℝ) (hxy : x ^ 2 + y ^ 2 = 1)
    (hs2 : s ^ 2 = a ^ 2 + γ ^ 2) (hγ : 0 < γ) (hs : γ < s) :
    (s - γ) + s * (1 / (1 + ((s - γ) * x * y / (γ * y ^ 2 + s * x ^ 2)) ^ 2) *
      (((s - γ) * (y ^ 2 - x ^ 2) * (γ * y ^ 2 + s * x ^ 2) -
        (s - γ) * x * y * (2 * (s - γ) * x * y)) / (γ * y ^ 2 + s * x ^ 2) ^ 2))
      = γ * a ^ 2 * y ^ 2 / (γ ^ 2 * y ^ 2 + s ^ 2 * x ^ 2) := by
  have hs0 : 0 < s := by linarith
  have hD : 0 < γ * y ^ 2 + s * x ^ 2 := by
    rcases eq_or_ne y 0 with h | h
    · have : x ^ 2 = 1 := by rw [h] at hxy; linarith
      rw [h, this]; linarith
    · have : 0 < y ^ 2 := by positivity
      nlinarith [sq_nonneg x]
  have hE : 0 < γ ^ 2 * y ^ 2 + s ^ 2 * x ^ 2 := by
    rcases eq_or_ne y 0 with h | h
    · have : x ^ 2 = 1 := by rw [h] at hxy; linarith
      rw [h, this]; nlinarith
    · have : 0 < y ^ 2 := by positivity
      nlinarith [sq_nonneg x, sq_nonneg s]
  set D := γ * y ^ 2 + s * x ^ 2 with hD_def
  set N := (s - γ) * x * y with hN_def
  have h1 : 1 / (1 + (N / D) ^ 2) *
      (((s - γ) * (y ^ 2 - x ^ 2) * D - N * (2 * (s - γ) * x * y)) / D ^ 2)
      = ((s - γ) * (y ^ 2 - x ^ 2) * D - N * (2 * (s - γ) * x * y)) / (D ^ 2 + N ^ 2) := by
    have : 0 < D ^ 2 + N ^ 2 := by positivity
    field_simp
  have h2 : (s - γ) * (y ^ 2 - x ^ 2) * D - N * (2 * (s - γ) * x * y)
      = (s - γ) * (γ * y ^ 2 - s * x ^ 2) := by
    simp only [hD_def, hN_def]
    linear_combination ((s - γ) * (γ * y ^ 2 - s * x ^ 2)) * hxy
  have h3 : D ^ 2 + N ^ 2 = γ ^ 2 * y ^ 2 + s ^ 2 * x ^ 2 := by
    simp only [hD_def, hN_def]
    linear_combination (γ ^ 2 * y ^ 2 + s ^ 2 * x ^ 2) * hxy
  rw [h1, h2, h3]
  field_simp
  linear_combination (γ * y ^ 2) * hs2

#print axioms kuramoto_arctan_deriv_alg

/-- The Lorentzian locked-crowd integral, proved by the substitution `ω = a sin θ`. -/
theorem kuramoto_locked_integral_aux (γ a : ℝ) (hγ : 0 < γ) (ha : 0 < a) :
    ∫ ω in (-a)..a, √(1 - (ω / a) ^ 2) * lorentzian γ ω = (√(a ^ 2 + γ ^ 2) - γ) / a := by
  set s := √(a ^ 2 + γ ^ 2) with hs_def
  have hs2 : s ^ 2 = a ^ 2 + γ ^ 2 := Real.sq_sqrt (by positivity)
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs : γ < s := by nlinarith
  have hpi : 0 < π := Real.pi_pos
  have hgc : Continuous (fun ω => √(1 - (ω / a) ^ 2) * lorentzian γ ω) := by
    unfold lorentzian
    refine (Real.continuous_sqrt.comp (by fun_prop)).mul ?_
    refine continuous_const.div (by fun_prop) (fun ω => ?_)
    have : 0 < ω ^ 2 + γ ^ 2 := by positivity
    positivity
  have hsub := intervalIntegral.integral_comp_mul_deriv (a := -(π / 2)) (b := π / 2)
    (f := fun θ => a * sin θ) (f' := fun θ => a * cos θ)
    (fun x _ => (hasDerivAt_sin x).const_mul a)
    ((continuous_const.mul continuous_cos).continuousOn) hgc
  simp only [sin_neg, sin_pi_div_two, mul_neg, mul_one] at hsub
  rw [← hsub]
  set h : ℝ → ℝ := fun θ => γ * a * cos θ ^ 2 / (π * (γ ^ 2 * cos θ ^ 2 + s ^ 2 * sin θ ^ 2))
    with h_def
  have hE : ∀ θ, 0 < γ ^ 2 * cos θ ^ 2 + s ^ 2 * sin θ ^ 2 := by
    intro θ
    have hxy := sin_sq_add_cos_sq θ
    nlinarith [sq_nonneg (sin θ), sq_nonneg (cos θ)]
  have hcongr : Set.EqOn
      (fun θ => ((fun ω => √(1 - (ω / a) ^ 2) * lorentzian γ ω) ∘ (fun θ => a * sin θ)) θ
        * (a * cos θ)) h (Set.uIcc (-(π / 2)) (π / 2)) := by
    intro θ hθ
    rw [Set.uIcc_of_le (by linarith)] at hθ
    have hc := cos_nonneg_of_mem_Icc hθ
    have hsq : √(1 - (a * sin θ / a) ^ 2) = cos θ := by
      rw [mul_div_cancel_left₀ _ ha.ne', ← cos_sq', Real.sqrt_sq hc]
    simp only [Function.comp_apply, h_def, hsq, lorentzian]
    have h1 : (a * sin θ) ^ 2 + γ ^ 2 = γ ^ 2 * cos θ ^ 2 + s ^ 2 * sin θ ^ 2 := by
      linear_combination (-(γ ^ 2)) * sin_sq_add_cos_sq θ + (-(sin θ ^ 2)) * hs2
    rw [h1]
    have := hE θ
    field_simp
  rw [intervalIntegral.integral_congr hcongr]
  set k : ℝ → ℝ := fun θ => (s - γ) * sin θ * cos θ / (γ * cos θ ^ 2 + s * sin θ ^ 2) with hk_def
  set G : ℝ → ℝ := fun θ => ((s - γ) * θ + s * arctan (k θ)) / (π * a) with hG_def
  have hD : ∀ θ, 0 < γ * cos θ ^ 2 + s * sin θ ^ 2 := by
    intro θ
    have hxy := sin_sq_add_cos_sq θ
    nlinarith [sq_nonneg (sin θ), sq_nonneg (cos θ)]
  have hderiv : ∀ θ ∈ Set.uIcc (-(π / 2)) (π / 2), HasDerivAt G (h θ) θ := by
    intro θ _
    have hN : HasDerivAt (fun θ => (s - γ) * sin θ * cos θ)
        ((s - γ) * (cos θ ^ 2 - sin θ ^ 2)) θ := by
      convert ((hasDerivAt_sin θ).const_mul (s - γ)).mul (hasDerivAt_cos θ) using 1
      ring
    have hDd : HasDerivAt (fun θ => γ * cos θ ^ 2 + s * sin θ ^ 2)
        (2 * (s - γ) * sin θ * cos θ) θ := by
      convert (((hasDerivAt_cos θ).pow 2).const_mul γ).add
        (((hasDerivAt_sin θ).pow 2).const_mul s) using 1
      simp only [Nat.cast_ofNat]
      ring
    have hkd := (hN.div hDd (hD θ).ne').arctan
    have hGd := (((hasDerivAt_id θ).const_mul (s - γ)).add (hkd.const_mul s)).div_const (π * a)
    convert hGd using 1
    · funext x
      simp only [hG_def, hk_def, Pi.add_apply, Pi.div_apply, id]
    simp only [h_def, mul_one, Pi.div_apply]
    have halg := kuramoto_arctan_deriv_alg (sin θ) (cos θ) s γ a (sin_sq_add_cos_sq θ) hs2 hγ hs
    rw [halg]
    have := hE θ
    field_simp
  have hint : IntervalIntegrable h MeasureTheory.volume (-(π / 2)) (π / 2) := by
    apply Continuous.intervalIntegrable
    simp only [h_def]
    refine Continuous.div (by fun_prop) (by fun_prop) (fun θ => ?_)
    have := hE θ
    positivity
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
  simp only [hG_def, hk_def, sin_neg, cos_neg, sin_pi_div_two, cos_pi_div_two]
  simp
  field_simp
  ring

#print axioms kuramoto_locked_integral_aux

/-- The card's main claim. For Lorentzian frequencies of half-width `γ > 0`, the critical
coupling `2 / (π g(0))` is `2γ`; and for every coupling `K` above it, the bunching
`r = √(1 - K_c/K)` lies strictly between 0 and 1 and solves the self-consistency equation:
`r` equals the integral over the locked speeds `-K r ≤ ω ≤ K r` of
`√(1 - (ω/(K r))²) g(ω)`. -/
theorem lorentzian_order_parameter_sqrt_law (γ K r : ℝ) (hγ : 0 < γ)
    (hK : criticalCoupling (lorentzian γ) < K)
    (hr : r = √(1 - criticalCoupling (lorentzian γ) / K)) :
    criticalCoupling (lorentzian γ) = 2 * γ ∧ 0 < r ∧ r < 1 ∧
      r = ∫ ω in (-(K * r))..(K * r), √(1 - (ω / (K * r)) ^ 2) * lorentzian γ ω := by
  have hcc : criticalCoupling (lorentzian γ) = 2 * γ := by
    unfold criticalCoupling lorentzian
    have := Real.pi_pos
    field_simp
    ring
  rw [hcc] at hK hr
  have hK0 : 0 < K := by linarith
  have h1 : 0 < 1 - 2 * γ / K := by
    rw [sub_pos, div_lt_one hK0]
    exact hK
  have hr0 : 0 < r := by rw [hr]; exact Real.sqrt_pos.mpr h1
  have hr2 : r ^ 2 = 1 - 2 * γ / K := by rw [hr]; exact Real.sq_sqrt h1.le
  have hr1 : r < 1 := by
    have : 0 < 2 * γ / K := by positivity
    nlinarith
  refine ⟨hcc, hr0, hr1, ?_⟩
  rw [kuramoto_locked_integral_aux γ (K * r) hγ (by positivity)]
  have hKr2 : K * r ^ 2 = K - 2 * γ := by
    rw [hr2]
    field_simp
  have hsq : √((K * r) ^ 2 + γ ^ 2) = K - γ := by
    rw [Real.sqrt_eq_iff_mul_self_eq_of_pos (by linarith)]
    linear_combination (-K) * hKr2
  rw [hsq]
  field_simp
  linear_combination hKr2

/-- The Lorentzian integral from the card's fold: for a window half-width `a > 0` and
half-width `γ > 0`, the locked crowd's contribution
`∫_{-a}^{a} √(1 - ω²/a²) g(ω) dω` equals `(√(a² + γ²) - γ) / a`. -/
theorem lorentzian_locked_integral (γ a : ℝ) (hγ : 0 < γ) (ha : 0 < a) :
    ∫ ω in (-a)..a, √(1 - (ω / a) ^ 2) * lorentzian γ ω = (√(a ^ 2 + γ ^ 2) - γ) / a := by
  exact kuramoto_locked_integral_aux γ a hγ ha

/-- Below the threshold only the scattered crowd survives: for any spread `g` with its one
peak at the average and symmetric about it (even, and falling away from 0), and any
coupling `0 < K < 2 / (π g(0))`, every bunching `r > 0` gets back strictly less than itself
from the self-consistency integral, so no `r > 0` solves the equation. -/
theorem below_threshold_no_bunched_solution (g : ℝ → ℝ) (hg_even : ∀ ω, g (-ω) = g ω)
    (hg_peak : AntitoneOn g (Set.Ici 0)) (hg0 : 0 < g 0) (K r : ℝ) (hK0 : 0 < K)
    (hK : K < criticalCoupling g) (hr : 0 < r) :
    ∫ ω in (-(K * r))..(K * r), √(1 - (ω / (K * r)) ^ 2) * g ω < r := by
  have hpi : 0 < π := Real.pi_pos
  have ha : 0 < K * r := mul_pos hK0 hr
  have hgle : ∀ ω, g ω ≤ g 0 := by
    intro ω
    rcases le_total 0 ω with h | h
    · exact hg_peak (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr h) h
    · rw [← hg_even ω]
      exact hg_peak (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr (by linarith)) (by linarith)
  have hsub := intervalIntegral.integral_comp_div (f := fun x => √(1 - x ^ 2))
    (a := -(K * r)) (b := K * r) ha.ne'
  simp only [neg_div, div_self ha.ne'] at hsub
  have hbound : ∫ ω in (-(K * r))..(K * r), √(1 - (ω / (K * r)) ^ 2) * g 0
      = g 0 * (K * r * (π / 2)) := by
    rw [intervalIntegral.integral_mul_const, hsub, integral_sqrt_one_sub_sq, smul_eq_mul]
    ring
  have hKg : K * (π * g 0) < 2 := by
    unfold criticalCoupling at hK
    rwa [lt_div_iff₀ (by positivity)] at hK
  by_cases hint : IntervalIntegrable (fun ω => √(1 - (ω / (K * r)) ^ 2) * g ω)
      MeasureTheory.volume (-(K * r)) (K * r)
  · calc ∫ ω in (-(K * r))..(K * r), √(1 - (ω / (K * r)) ^ 2) * g ω
        ≤ ∫ ω in (-(K * r))..(K * r), √(1 - (ω / (K * r)) ^ 2) * g 0 := by
          apply intervalIntegral.integral_mono_on (by linarith) hint
          · exact (Continuous.intervalIntegrable (by fun_prop) _ _)
          · intro ω _
            exact mul_le_mul_of_nonneg_left (hgle ω) (Real.sqrt_nonneg _)
      _ = g 0 * (K * r * (π / 2)) := hbound
      _ < r := by nlinarith
  · rw [intervalIntegral.integral_undef hint]
    exact hr

-- Half-width 0.5: g(0) = 1/(π γ) and the critical coupling is 1.
example : criticalCoupling (lorentzian (1 / 2)) = 1 := by
  norm_num [criticalCoupling, lorentzian]
  field_simp
  norm_num
-- At K = 2: 1 - K_c/K = 1/2, so r² = 1/2 (r = 0.7071).
example : (1 : ℚ) - 1 / 2 = 1 / 2 := by norm_num
-- The card's check at K = 2: (K r)² + γ² = 2 + 1/4 = (3/2)², and 3/2 - 1/2 = 1 = (K r) · r = K r².
example : (2 : ℚ) ^ 2 * (1 / 2) + (1 / 2) ^ 2 = (3 / 2) ^ 2 := by norm_num
example : (3 / 2 : ℚ) - 1 / 2 = 2 * (1 / 2) := by norm_num
-- The chart's theory points: r² = 1/6 at K = 1.2, 1/3 at 1.5, 2/3 at 3, 3/4 at 4.
example : (1 : ℚ) - 1 / (6 / 5) = 1 / 6 ∧ (1 : ℚ) - 1 / (3 / 2) = 1 / 3 ∧
    (1 : ℚ) - 1 / 3 = 2 / 3 ∧ (1 : ℚ) - 1 / 4 = 3 / 4 := by norm_num
-- Mistake: the full width γ = 1 doubles the threshold to 2, so 1 - K_c/K = 0 at K = 2.
example : criticalCoupling (lorentzian 1) = 2 := by
  norm_num [criticalCoupling, lorentzian, Real.pi_ne_zero]
example : (1 : ℚ) - 2 / 2 = 0 := by norm_num
-- The house example: the phase gap obeys φ' = 0.5 - sin φ at K = 1, at rest at 30 degrees.
example : (1 / 2 : ℝ) - sin (π / 6) = 0 := by norm_num [Real.sin_pi_div_six]

#print axioms lorentzian_order_parameter_sqrt_law
#print axioms lorentzian_locked_integral
#print axioms below_threshold_no_bunched_solution
