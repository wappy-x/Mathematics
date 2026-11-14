-- MVA: when the discounted expected margin stays at its day-one level, the margin valuation adjustment integral closes to spread times day-one margin times the survival annuity (1 - e^(-λT))/λ, which grows with maturity more slowly than in proportion and beats CVA exactly when the hazard is below a crossover.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Real Set intervalIntegral

/-- MVA closed form. Let `s` be the margin funding spread, `r` the riskless rate, `λ > 0`
Northwind's hazard and `T ≥ 0` the trade's life. If the expected margin `EIM t` at every date
`t` in `[0, T]`, shrunk to today by `D(t) = e^{-rt}`, equals the day-one margin `IM₀`
(the green line: the dollar delta is a traded price), then
`MVA = s ∫₀ᵀ D(t) E[IM(t)] Q(t) dt` with `Q(t) = e^{-λt}` equals `s · IM₀ · (1 - e^{-λT}) / λ`. -/
theorem mva_closed_form (s r lam IM0 T : ℝ) (EIM : ℝ → ℝ) (hlam : 0 < lam) (hT : 0 ≤ T)
    (hflat : ∀ t ∈ Icc 0 T, Real.exp (-r * t) * EIM t = IM0) :
    s * ∫ t in (0)..T, Real.exp (-r * t) * EIM t * Real.exp (-lam * t)
      = s * IM0 * (1 - Real.exp (-lam * T)) / lam := by
  have h1 : (∫ t in (0)..T, Real.exp (-r * t) * EIM t * Real.exp (-lam * t))
      = ∫ t in (0)..T, IM0 * Real.exp (-lam * t) := by
    apply intervalIntegral.integral_congr
    intro t ht
    rw [uIcc_of_le hT] at ht
    simp only
    rw [hflat t ht]
  have h2 : (∫ t in (0)..T, IM0 * Real.exp (-lam * t))
      = IM0 * (1 - Real.exp (-lam * T)) / lam := by
    have hd : ∀ x ∈ uIcc 0 T, HasDerivAt (fun t => -IM0 * Real.exp (-lam * t) / lam)
        (IM0 * Real.exp (-lam * x)) x := by
      intro x _
      have h := ((((hasDerivAt_id x).const_mul (-lam)).exp).const_mul (-IM0)).div_const lam
      convert h using 1
      · funext t; simp
      · simp; field_simp
    have hi : IntervalIntegrable (fun t => IM0 * Real.exp (-lam * t)) MeasureTheory.volume 0 T :=
      (by fun_prop : Continuous (fun t => IM0 * Real.exp (-lam * t))).intervalIntegrable _ _
    rw [integral_eq_sub_of_hasDerivAt hd hi]
    simp
    field_simp
    ring
  rw [h1, h2]
  ring

/-- MVA grows with maturity, but more slowly than in proportion: with a positive spread,
positive day-one margin and positive hazard, the closed form `s · IM₀ · (1 - e^{-λT}) / λ`
is strictly increasing in `T`, its slope in `T` is `s · IM₀ · e^{-λT}`, and for every
`T > 0` it is strictly below the no-survival-weight charge `s · IM₀ · T`. -/
theorem mva_grows_with_maturity_less_than_proportionally (s IM0 lam : ℝ)
    (hs : 0 < s) (hIM : 0 < IM0) (hlam : 0 < lam) :
    StrictMono (fun T : ℝ => s * IM0 * (1 - Real.exp (-lam * T)) / lam) ∧
    (∀ T : ℝ, HasDerivAt (fun T : ℝ => s * IM0 * (1 - Real.exp (-lam * T)) / lam)
        (s * IM0 * Real.exp (-lam * T)) T) ∧
    (∀ T : ℝ, 0 < T → s * IM0 * (1 - Real.exp (-lam * T)) / lam < s * IM0 * T) := by
  have hsI : 0 < s * IM0 := mul_pos hs hIM
  refine ⟨?_, ?_, ?_⟩
  · intro a b hab
    simp only
    apply div_lt_div_of_pos_right _ hlam
    apply mul_lt_mul_of_pos_left _ hsI
    have : Real.exp (-lam * b) < Real.exp (-lam * a) := Real.exp_lt_exp.mpr (by nlinarith)
    linarith
  · intro T
    have h := (((((hasDerivAt_id' T).const_mul (-lam)).exp).const_sub 1).const_mul (s * IM0)).div_const lam
    convert h using 1
    field_simp
  · intro T hT
    rw [div_lt_iff₀ hlam]
    have hne : -lam * T ≠ 0 := by
      have : 0 < lam * T := mul_pos hlam hT
      intro h; linarith
    have := Real.add_one_lt_exp hne
    nlinarith

/-- MVA against CVA: with the same survival factor, MVA `s · IM₀ · (1 - e^{-λT}) / λ`
exceeds CVA `(1 - R) · C₀ · (1 - e^{-λT})` exactly when the hazard is below the crossover
`s · IM₀ / ((1 - R) · C₀)`. -/
theorem mva_exceeds_cva_iff_hazard_below_crossover (s IM0 C0 R lam T : ℝ)
    (hlam : 0 < lam) (hT : 0 < T) (hC : 0 < C0) (hR : R < 1) :
    (1 - R) * C0 * (1 - Real.exp (-lam * T)) < s * IM0 * (1 - Real.exp (-lam * T)) / lam ↔
      lam < s * IM0 / ((1 - R) * C0) := by
  have hA : 0 < 1 - Real.exp (-lam * T) := by
    have : Real.exp (-lam * T) < 1 := by
      have h := Real.exp_lt_exp.mpr (show -lam * T < 0 by nlinarith)
      rwa [Real.exp_zero] at h
    linarith
  have hD : 0 < (1 - R) * C0 := mul_pos (by linarith) hC
  rw [lt_div_iff₀ hlam, lt_div_iff₀ hD]
  rw [show (1 - R) * C0 * (1 - Real.exp (-lam * T)) * lam
      = lam * ((1 - R) * C0) * (1 - Real.exp (-lam * T)) by ring]
  exact mul_lt_mul_iff_of_pos_right hA

#print axioms mva_closed_form
#print axioms mva_grows_with_maturity_less_than_proportionally
#print axioms mva_exceeds_cva_iff_hazard_below_crossover
