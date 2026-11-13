-- Dupire local volatility: Dupire's forward equation fixes the local variance as calendar slope plus carry terms over half the strike squared times the bend, a surface with positive bend and non-negative numerator has exactly one local volatility, and the flat Black-Scholes surface hands back its own volatility.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF

open Real ProbabilityTheory

/-- Shifting the argument of the standard normal density multiplies it by an exponential. -/
lemma gaussianPDFReal_std_shift (x y : ℝ) :
    gaussianPDFReal 0 1 y = gaussianPDFReal 0 1 x * Real.exp ((x ^ 2 - y ^ 2) / 2) := by
  simp only [gaussianPDFReal, mul_assoc, ← Real.exp_add]
  congr 2
  push_cast
  ring

#print axioms gaussianPDFReal_std_shift

/-- Dupire's formula. Write `C K T` for the call price at strike `K` and expiry `T`,
`C_T` for its slope in expiry, `C_K` for its slope in strike and `C_KK` for its bend in strike.
If the call prices obey Dupire's forward equation
`C_T = ½ σ_loc² K² C_KK − (r − q) K C_K − q C` at a positive strike where the bend is
positive, then the local variance there is read straight off the prices:
`σ_loc² = (C_T + (r − q) K C_K + q C) / (½ K² C_KK)`. -/
theorem dupire_local_variance_formula (C σloc : ℝ → ℝ → ℝ) (r q K T : ℝ) (hK : 0 < K)
    (hbend : 0 < deriv (deriv fun k => C k T) K)
    (hforward : deriv (fun t => C K t) T =
      (1 / 2) * σloc K T ^ 2 * K ^ 2 * deriv (deriv fun k => C k T) K
        - (r - q) * K * deriv (fun k => C k T) K - q * C K T) :
    σloc K T ^ 2 =
      (deriv (fun t => C K t) T + (r - q) * K * deriv (fun k => C k T) K + q * C K T) /
        ((1 / 2) * K ^ 2 * deriv (deriv fun k => C k T) K) := by
  rw [eq_div_iff (by positivity), hforward]
  ring

/-- Exists and unique: where the butterfly test passes strictly (positive bend) and the
calendar test passes (the numerator `C_T + (r − q) K C_K + q C` is not negative), there is
exactly one non-negative local volatility that makes the call prices obey Dupire's forward
equation at that strike and expiry. -/
theorem dupire_local_vol_exists_unique (C : ℝ → ℝ → ℝ) (r q K T : ℝ) (hK : 0 < K)
    (hbutterfly : 0 < deriv (deriv fun k => C k T) K)
    (hcalendar : 0 ≤ deriv (fun t => C K t) T + (r - q) * K * deriv (fun k => C k T) K
      + q * C K T) :
    ∃! s : ℝ, 0 ≤ s ∧ deriv (fun t => C K t) T =
      (1 / 2) * s ^ 2 * K ^ 2 * deriv (deriv fun k => C k T) K
        - (r - q) * K * deriv (fun k => C k T) K - q * C K T := by
  set D := deriv (deriv fun k => C k T) K with hD
  set A := deriv (fun t => C K t) T + (r - q) * K * deriv (fun k => C k T) K + q * C K T
    with hA
  have hden : 0 < (1 / 2) * K ^ 2 * D := by positivity
  refine ⟨Real.sqrt (A / ((1 / 2) * K ^ 2 * D)), ⟨Real.sqrt_nonneg _, ?_⟩, ?_⟩
  · have hsq : Real.sqrt (A / ((1 / 2) * K ^ 2 * D)) ^ 2 = A / ((1 / 2) * K ^ 2 * D) :=
      Real.sq_sqrt (div_nonneg hcalendar hden.le)
    have h1 : (1 / 2) * Real.sqrt (A / ((1 / 2) * K ^ 2 * D)) ^ 2 * K ^ 2 * D
        = Real.sqrt (A / ((1 / 2) * K ^ 2 * D)) ^ 2 * ((1 / 2) * K ^ 2 * D) := by ring
    rw [h1, hsq, div_mul_cancel₀ _ hden.ne', hA]
    ring
  · rintro s ⟨hs, heq⟩
    have hs2 : s ^ 2 = A / ((1 / 2) * K ^ 2 * D) := by
      rw [eq_div_iff hden.ne', hA, heq]
      ring
    rw [← hs2, Real.sqrt_sq hs]

/-- A flat surface hands back its own volatility. For the Black-Scholes call at volatility
`σ` (spot `S`, rate `r`, dividend yield `q`, strike `K`, expiry `T`), plug the house
formula's closed-form slopes `C_T`, `C_K`, `C_KK` into Dupire's formula: the carry terms
cancel and the ratio is exactly `σ²`. Here `N` is the standard normal distribution function
and `φ` the standard normal density. -/
theorem dupire_flat_surface_returns_sigma (S K r q σ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let N : ℝ → ℝ := fun x => cdf (gaussianReal 0 1) x
    let φ : ℝ → ℝ := gaussianPDFReal 0 1
    let d₁ := (Real.log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * Real.sqrt T)
    let d₂ := d₁ - σ * Real.sqrt T
    let C := S * Real.exp (-q * T) * N d₁ - K * Real.exp (-r * T) * N d₂
    let C_T := S * Real.exp (-q * T) * φ d₁ * σ / (2 * Real.sqrt T)
      - q * S * Real.exp (-q * T) * N d₁ + r * K * Real.exp (-r * T) * N d₂
    let C_K := -Real.exp (-r * T) * N d₂
    let C_KK := Real.exp (-r * T) * φ d₂ / (K * σ * Real.sqrt T)
    (C_T + (r - q) * K * C_K + q * C) / ((1 / 2) * K ^ 2 * C_KK) = σ ^ 2 := by
  intro N φ d₁ d₂ C C_T C_K C_KK
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hσsT : σ * Real.sqrt T ≠ 0 := (mul_pos hσ hsT).ne'
  have hsq : Real.sqrt T ^ 2 = T := Real.sq_sqrt hT.le
  have hd : d₁ * (σ * Real.sqrt T) = Real.log (S / K) + (r - q + σ ^ 2 / 2) * T :=
    div_mul_cancel₀ _ hσsT
  have hdiff : (d₁ ^ 2 - d₂ ^ 2) / 2 = Real.log (S / K) + (r - q) * T := by
    have : d₁ ^ 2 - d₂ ^ 2 = 2 * (d₁ * (σ * Real.sqrt T)) - σ ^ 2 * Real.sqrt T ^ 2 := by
      simp only [d₂]; ring
    rw [this, hd, hsq]; ring
  have key : φ d₂ = φ d₁ * (S / K * Real.exp ((r - q) * T)) := by
    simp only [φ]
    rw [gaussianPDFReal_std_shift d₁ d₂, hdiff, Real.exp_add, Real.exp_log (div_pos hS hK)]
  have hφ : 0 < φ d₁ := gaussianPDFReal_pos 0 1 d₁ one_ne_zero
  have hnum : C_T + (r - q) * K * C_K + q * C
      = S * Real.exp (-q * T) * φ d₁ * σ / (2 * Real.sqrt T) := by
    simp only [C_T, C_K, C]; ring
  have hq : Real.exp (-q * T) = Real.exp (-r * T) * Real.exp ((r - q) * T) := by
    rw [← Real.exp_add]; ring_nf
  rw [hnum]
  simp only [C_KK]
  rw [key, hq]
  have he1 : 0 < Real.exp (-r * T) := Real.exp_pos _
  have he2 : 0 < Real.exp ((r - q) * T) := Real.exp_pos _
  field_simp

#print axioms dupire_local_variance_formula
#print axioms dupire_local_vol_exists_unique
#print axioms dupire_flat_surface_returns_sigma
