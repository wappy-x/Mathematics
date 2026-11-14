-- CVA risk numbers: with a flat exposure and a flat hazard set by the spread, CVA's slope in the spread is exposure times life times survival, CVA is that exposure times the loss fraction times the default chance, and a par CDS's slope in the spread is its risky annuity.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.Calculus.Deriv.Slope

open Real intervalIntegral

/-- CS01, the card's main formula. Write CVA as a function of the counterparty's
credit spread `s`, with the hazard read off the credit triangle, `λ = s / (1 - R)`:
`CVA(s) = (1 - R) · C · (1 - e^{-λ T})`. Then its slope in the spread is
`C · T · e^{-λ T}`: exposure times years times the survival chance. The recovery
`R` cancels. The only condition is that the loss fraction `1 - R` is not zero,
so that the hazard `s / (1 - R)` makes sense. -/
theorem cva_cs01_eq_exposure_times_life_times_survival
    (C R T s : ℝ) (hR : R ≠ 1) :
    HasDerivAt (fun x : ℝ => (1 - R) * C * (1 - exp (-(x / (1 - R)) * T)))
      (C * T * exp (-(s / (1 - R)) * T)) s := by
  have hk : (1 - R) ≠ 0 := sub_ne_zero.mpr (Ne.symm hR)
  have h1 : HasDerivAt (fun x : ℝ => -(x / (1 - R)) * T) (-(1 / (1 - R)) * T) s := by
    have := ((hasDerivAt_id s).div_const (1 - R)).neg.mul_const T
    simpa using this
  have h2 := ((h1.exp).const_sub 1).const_mul ((1 - R) * C)
  convert h2 using 1
  field_simp

/-- The CVA formula with a flat discounted exposure. If the discounted expected
exposure equals `C` at every date and default comes at rate `λ` (density
`λ e^{-λ t}`), then `(1 - R) ∫₀ᵀ C · λ e^{-λ t} dt = (1 - R) · C · (1 - e^{-λ T})`:
loss fraction times exposure times the chance of default before expiry. -/
theorem cva_flat_exposure_integral (C R lam T : ℝ) :
    (1 - R) * ∫ t in (0 : ℝ)..T, C * (lam * exp (-lam * t)) =
      (1 - R) * C * (1 - exp (-lam * T)) := by
  have hint : ∫ t in (0 : ℝ)..T, C * (lam * exp (-lam * t)) = C * (1 - exp (-lam * T)) := by
    have hd : ∀ x ∈ Set.uIcc (0 : ℝ) T,
        HasDerivAt (fun t : ℝ => -C * exp (-lam * t)) (C * (lam * exp (-lam * x))) x := by
      intro x _
      have h : HasDerivAt (fun t : ℝ => -lam * t) (-lam) x := by
        simpa using (hasDerivAt_id x).const_mul (-lam)
      have h2 := (h.exp).const_mul (-C)
      convert h2 using 1
      ring
    rw [integral_eq_sub_of_hasDerivAt hd]
    · simp; ring
    · apply Continuous.intervalIntegrable; fun_prop
  rw [hint]; ring

/-- The CDS hedge instrument. A CDS with premium `s₀` paid continuously, flat hazard
`λ = s / (1 - R)` and riskless rate `r` is worth, per dollar of notional, its
protection leg `(1 - R) ∫₀ᵀ e^{-r t} λ e^{-λ t} dt` minus its premium leg
`s₀ ∫₀ᵀ e^{-(r + λ) t} dt`. At par (`s = s₀`) its slope in the spread is the risky
annuity `A = ∫₀ᵀ e^{-(r + λ) t} dt`. This is the CDS's CS01 per basis point that the
CVA's CS01 is matched against to size the hedge. -/
theorem cds_cs01_at_par_eq_risky_annuity (R r T s₀ : ℝ) (hR : R ≠ 1) :
    HasDerivAt
      (fun s : ℝ =>
        (1 - R) * (∫ t in (0 : ℝ)..T, exp (-r * t) * ((s / (1 - R)) * exp (-(s / (1 - R)) * t)))
          - s₀ * ∫ t in (0 : ℝ)..T, exp (-(r + s / (1 - R)) * t))
      (∫ t in (0 : ℝ)..T, exp (-(r + s₀ / (1 - R)) * t)) s₀ := by
  have hk : (1 - R) ≠ 0 := sub_ne_zero.mpr (Ne.symm hR)
  have hfun : (fun s : ℝ =>
        (1 - R) * (∫ t in (0 : ℝ)..T, exp (-r * t) * ((s / (1 - R)) * exp (-(s / (1 - R)) * t)))
          - s₀ * ∫ t in (0 : ℝ)..T, exp (-(r + s / (1 - R)) * t))
      = fun s : ℝ => (s - s₀) * ∫ t in (0 : ℝ)..T, exp (-(r + s / (1 - R)) * t) := by
    funext s
    have e : ∀ t : ℝ, exp (-r * t) * ((s / (1 - R)) * exp (-(s / (1 - R)) * t))
        = (s / (1 - R)) * exp (-(r + s / (1 - R)) * t) := by
      intro t
      rw [mul_left_comm, ← exp_add]
      ring_nf
    simp_rw [e, intervalIntegral.integral_const_mul]
    field_simp
  rw [hfun]
  have hc : Continuous fun s : ℝ => ∫ t in (0 : ℝ)..T, exp (-(r + s / (1 - R)) * t) :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
      (f := fun s t => exp (-(r + s / (1 - R)) * t)) (by fun_prop) 0 T
  rw [hasDerivAt_iff_tendsto_slope]
  refine ((hc.tendsto s₀).mono_left nhdsWithin_le_nhds).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with y hy
  have hy' : y - s₀ ≠ 0 := sub_ne_zero.mpr hy
  rw [slope_def_field]
  field_simp
  ring

-- The card's worked example: hazard 2% and recovery 40% give a spread of
-- 0.02 × 0.6 = 0.012, that is 120 basis points.
example : (2 / 100 : ℚ) * (1 - 40 / 100) = 120 / 10000 := by norm_num

-- Back the other way: a 120 bp spread with recovery 40% gives hazard λ = s / (1 - R) = 2%.
example : (120 / 10000 : ℚ) / (1 - 40 / 100) = 2 / 100 := by norm_num

#print axioms cva_cs01_eq_exposure_times_life_times_survival
#print axioms cva_flat_exposure_integral
#print axioms cds_cs01_at_par_eq_risky_annuity
