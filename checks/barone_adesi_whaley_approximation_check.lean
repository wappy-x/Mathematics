-- Barone-Adesi-Whaley: the premium's reduced equation is solved by powers of the share price, only the negative root vanishes for a put, the lump sized by the card's A makes the American curve meet the exercise line with slope −1 at a critical price that solves the matching equation, and such a critical price exists between 0 and the strike.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open MeasureTheory ProbabilityTheory Real Filter Topology

namespace BaroneAdesiWhaley

/-! The model, as on the card. Riskless rate `r`, dividend yield `q`, volatility `σ`, years to
expiry `T`, strike `K`. `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x`. -/

/-- `m = 2r/σ²`. -/
noncomputable def bawM (r σ : ℝ) : ℝ := 2 * r / σ ^ 2

/-- `n = 2(r − q)/σ²`. -/
noncomputable def bawN (r q σ : ℝ) : ℝ := 2 * (r - q) / σ ^ 2

/-- The life factor `h = 1 − e^(−rT)`. -/
noncomputable def bawH (r T : ℝ) : ℝ := 1 - exp (-(r * T))

/-- The negative root `β₁ = (−(n−1) − √((n−1)² + 4m/h)) / 2`. -/
noncomputable def bawBeta1 (r q σ T : ℝ) : ℝ :=
  (-(bawN r q σ - 1) - √((bawN r q σ - 1) ^ 2 + 4 * bawM r σ / bawH r T)) / 2

/-- The positive root `β₂ = (−(n−1) + √((n−1)² + 4m/h)) / 2`. -/
noncomputable def bawBeta2 (r q σ T : ℝ) : ℝ :=
  (-(bawN r q σ - 1) + √((bawN r q σ - 1) ^ 2 + 4 * bawM r σ / bawH r T)) / 2

/-- `d₁(X) = (ln(X/K) + (r − q + σ²/2) T) / (σ √T)`; `d₂ = d₁ − σ √T`. -/
noncomputable def bsD1 (X K r q σ T : ℝ) : ℝ :=
  (log (X / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The European put `p(X) = K e^(−rT) N(−d₂) − X e^(−qT) N(−d₁)`. -/
noncomputable def bsPut (X K r q σ T : ℝ) : ℝ :=
  K * exp (-(r * T)) * cdf (gaussianReal 0 1) (-(bsD1 X K r q σ T - σ * √T)) -
    X * exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 X K r q σ T)

/-- The lump's height at a trial critical price `X`:
`A = −(X/β₁)(1 − e^(−qT) N(−d₁(X)))`. -/
noncomputable def bawA (X K r q σ T : ℝ) : ℝ :=
  -(X / bawBeta1 r q σ T) * (1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 X K r q σ T))

/-- The Barone-Adesi-Whaley put with critical price `Sstar`: `K − S` at or below `Sstar`, and
`p(S) + A (S/S*)^β₁` above it. -/
noncomputable def bawPut (Sstar K r q σ T S : ℝ) : ℝ :=
  if S ≤ Sstar then K - S
  else bsPut S K r q σ T + bawA Sstar K r q σ T * (S / Sstar) ^ bawBeta1 r q σ T

theorem bawPhi_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

#print axioms bawPhi_eq_integral

theorem bawPhi_hasDerivAt (x : ℝ) :
    HasDerivAt (fun y => cdf (gaussianReal 0 1) y) (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ y, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic y) volume :=
    fun y => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : (fun y => cdf (gaussianReal 0 1) y) =
      fun y => (∫ t in Set.Iic 0, gaussianPDFReal 0 1 t) + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [bawPhi_eq_integral, ← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI y)]
    ring
  rw [heq]
  have hc : Continuous (gaussianPDFReal 0 1) := by
    rw [gaussianPDFReal_def]; fun_prop
  refine HasDerivAt.const_add _ ?_
  exact intervalIntegral.integral_hasDerivAt_right (hc.intervalIntegrable _ _)
    (hc.stronglyMeasurableAtFilter _ _) hc.continuousAt

#print axioms bawPhi_hasDerivAt

theorem bawPhi_lt_one (x : ℝ) : cdf (gaussianReal 0 1) x < 1 := by
  have h1 : (gaussianReal 0 1) (Set.Ioi x) ≠ 0 := by
    intro h
    have := gaussianReal_absolutelyContinuous' (0:ℝ) one_ne_zero h
    simp at this
  have h2 : (gaussianReal 0 1) (Set.Iic x) + (gaussianReal 0 1) (Set.Ioi x) = 1 := by
    rw [← measure_union (Set.disjoint_left.2 fun a ha hb => not_lt.2 ha hb) measurableSet_Ioi,
      Set.Iic_union_Ioi, measure_univ]
  rw [cdf_eq_real, measureReal_def]
  have h3 : (gaussianReal 0 1) (Set.Iic x) < 1 := by
    rw [← h2]; exact ENNReal.lt_add_right (measure_ne_top _ _) h1
  have := ENNReal.toReal_strict_mono ENNReal.one_ne_top h3
  simpa using this

#print axioms bawPhi_lt_one

theorem bawPdf_neg (x : ℝ) : gaussianPDFReal 0 1 (-x) = gaussianPDFReal 0 1 x := by
  simp [gaussianPDFReal]

#print axioms bawPdf_neg

theorem bawPdf_identity (X K r q σ T : ℝ) (hX : 0 < X) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    K * exp (-(r * T)) * gaussianPDFReal 0 1 (bsD1 X K r q σ T - σ * √T) =
      X * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 X K r q σ T) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  set d := bsD1 X K r q σ T with hd
  have hds : d * (σ * √T) = log (X / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [hd, bsD1]; field_simp
  have hs2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, sq_sqrt hT.le]
  have hX' : X = K * exp (log (X / K)) := by
    rw [exp_log (div_pos hX hK)]; field_simp
  simp only [gaussianPDFReal]
  conv_rhs => rw [hX']
  have : exp (-(r * T)) * exp (-(d - σ * √T - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) =
      exp (log (X / K)) * exp (-(q * T)) * exp (-(d - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ))) := by
    rw [← exp_add, ← exp_add, ← exp_add]
    congr 1
    simp only [NNReal.coe_one, sub_zero]
    linear_combination hds - hs2 / 2
  linear_combination K * (√(2 * π * ((1 : NNReal) : ℝ)))⁻¹ * this

#print axioms bawPdf_identity

theorem bsD1_hasDerivAt_X (X K r q σ T : ℝ) (hX : 0 < X) (hK : 0 < K) :
    HasDerivAt (fun y => bsD1 y K r q σ T) ((1 / K) / (X / K) / (σ * √T)) X := by
  have h := (((hasDerivAt_id X).div_const K).log (div_pos hX hK).ne').add_const
    ((r - q + σ ^ 2 / 2) * T) |>.div_const (σ * √T)
  simpa [bsD1] using h

#print axioms bsD1_hasDerivAt_X

theorem bsPut_hasDerivAt_X (X K r q σ T : ℝ) (hX : 0 < X) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun y => bsPut y K r q σ T)
      (-(exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 X K r q σ T))) X := by
  have hd := bsD1_hasDerivAt_X X K r q σ T hX hK
  have h1 := ((bawPhi_hasDerivAt _).comp X ((hd.sub_const (σ * √T)).neg)).const_mul
    (K * exp (-(r * T)))
  have h2 := (hasDerivAt_id X).mul_const (exp (-(q * T))) |>.mul
    ((bawPhi_hasDerivAt _).comp X hd.neg)
  have h := h1.sub h2
  convert h using 1
  · funext y; simp [bsPut, Function.comp]
  · have hid := bawPdf_identity X K r q σ T hX hK hσ hT
    simp only [Pi.neg_apply, Function.comp_apply, id, bawPdf_neg]
    linear_combination ((1 / K) / (X / K) / (σ * √T)) * hid

#print axioms bsPut_hasDerivAt_X

theorem bsD1_hasDerivAt_K (X K r q σ T : ℝ) (hX : 0 < X) (hK : 0 < K) :
    HasDerivAt (fun k => bsD1 X k r q σ T) ((-(X / K ^ 2)) / (X / K) / (σ * √T)) K := by
  have h := (((hasDerivAt_id K).inv hK.ne').const_mul X |>.log (div_pos hX hK).ne').add_const
    ((r - q + σ ^ 2 / 2) * T) |>.div_const (σ * √T)
  convert h using 1
  · funext k; simp [bsD1, div_eq_mul_inv]
  · simp [div_eq_mul_inv]

#print axioms bsD1_hasDerivAt_K

theorem bsPut_hasDerivAt_K (X K r q σ T : ℝ) (hX : 0 < X) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun k => bsPut X k r q σ T)
      (exp (-(r * T)) * cdf (gaussianReal 0 1) (-(bsD1 X K r q σ T - σ * √T))) K := by
  have hd := bsD1_hasDerivAt_K X K r q σ T hX hK
  have h1 := ((hasDerivAt_id K).mul_const (exp (-(r * T)))).mul
    ((bawPhi_hasDerivAt _).comp K ((hd.sub_const (σ * √T)).neg))
  have h2 := ((bawPhi_hasDerivAt _).comp K hd.neg).const_mul (X * exp (-(q * T)))
  have h := h1.sub h2
  convert h using 1
  · funext y; simp [bsPut, Function.comp]
  · have hid := bawPdf_identity X K r q σ T hX hK hσ hT
    simp only [Pi.neg_apply, Function.comp_apply, id, bawPdf_neg]
    linear_combination ((-(X / K ^ 2)) / (X / K) / (σ * √T)) * hid

#print axioms bsPut_hasDerivAt_K

theorem bawMH_pos (r σ T : ℝ) (hr : 0 < r) (hσ : 0 < σ) (hT : 0 < T) :
    0 < bawM r σ / bawH r T := by
  unfold bawM bawH
  have : exp (-(r * T)) < 1 := by rw [exp_lt_one_iff]; nlinarith
  exact div_pos (by positivity) (by linarith)

#print axioms bawMH_pos

theorem bawBeta1_neg (r q σ T : ℝ) (hr : 0 < r) (hσ : 0 < σ) (hT : 0 < T) :
    bawBeta1 r q σ T < 0 := by
  have hc := bawMH_pos r σ T hr hσ hT
  have hD : 0 ≤ (bawN r q σ - 1) ^ 2 + 4 * (bawM r σ / bawH r T) := by positivity
  have hs := sq_sqrt hD
  have hs0 := sqrt_nonneg ((bawN r q σ - 1) ^ 2 + 4 * (bawM r σ / bawH r T))
  have e : 4 * bawM r σ / bawH r T = 4 * (bawM r σ / bawH r T) := mul_div_assoc _ _ _
  unfold bawBeta1
  rw [e]
  nlinarith

#print axioms bawBeta1_neg

theorem bawPhi_continuous : Continuous (fun y => cdf (gaussianReal 0 1) y) :=
  continuous_iff_continuousAt.2 fun x => (bawPhi_hasDerivAt x).continuousAt

#print axioms bawPhi_continuous


theorem bsPut_nonneg (X K r q σ T : ℝ) (hX : 0 < X) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    0 ≤ bsPut X K r q σ T := by
  have hmono : MonotoneOn (fun k => bsPut X k r q σ T) (Set.Ioi 0) := by
    apply monotoneOn_of_deriv_nonneg (convex_Ioi 0)
    · exact fun k hk =>
        (bsPut_hasDerivAt_K X k r q σ T hX hk hσ hT).continuousAt.continuousWithinAt
    · rw [interior_Ioi]
      exact fun k hk =>
        (bsPut_hasDerivAt_K X k r q σ T hX hk hσ hT).differentiableAt.differentiableWithinAt
    · rw [interior_Ioi]
      intro k hk
      rw [(bsPut_hasDerivAt_K X k r q σ T hX hk hσ hT).deriv]
      exact mul_nonneg (exp_pos _).le (cdf_nonneg _ _)
  have hlim : Tendsto (fun k => bsPut X k r q σ T) (𝓝[>] 0) (𝓝 0) := by
    have hs : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
    have hd : Tendsto (fun k => -bsD1 X k r q σ T) (𝓝[>] 0) atBot := by
      have h1 : Tendsto (fun k => -log k) (𝓝[>] 0) atTop :=
        tendsto_neg_atBot_atTop.comp tendsto_log_nhdsGT_zero
      have h2 : Tendsto (fun k => (log X + -log k + (r - q + σ ^ 2 / 2) * T) / (σ * √T))
          (𝓝[>] 0) atTop :=
        (tendsto_atTop_add_const_right _ _ (tendsto_atTop_add_const_left _ _ h1)).atTop_div_const hs
      refine (tendsto_neg_atTop_atBot.comp h2).congr' ?_
      filter_upwards [self_mem_nhdsWithin] with k hk
      simp only [Function.comp, bsD1]
      rw [log_div hX.ne' (ne_of_gt hk)]
      ring
    have hA : Tendsto (fun k => k * exp (-(r * T)) *
        cdf (gaussianReal 0 1) (-(bsD1 X k r q σ T - σ * √T))) (𝓝[>] 0) (𝓝 0) := by
      have hup : Tendsto (fun k : ℝ => k * exp (-(r * T))) (𝓝[>] 0) (𝓝 0) := by
        have : Tendsto (fun k : ℝ => k * exp (-(r * T))) (𝓝 0) (𝓝 (0 * exp (-(r * T)))) :=
          tendsto_id.mul_const _
        rw [zero_mul] at this
        exact this.mono_left nhdsWithin_le_nhds
      apply tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hup
      · filter_upwards [self_mem_nhdsWithin] with k hk
        exact mul_nonneg (mul_nonneg (le_of_lt hk) (exp_pos _).le) (cdf_nonneg _ _)
      · filter_upwards [self_mem_nhdsWithin] with k hk
        exact mul_le_of_le_one_right (mul_nonneg (le_of_lt hk) (exp_pos _).le) (cdf_le_one _ _)
    have hB : Tendsto (fun k => X * exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 X k r q σ T))
        (𝓝[>] 0) (𝓝 0) := by
      simpa using Filter.Tendsto.const_mul (X * exp (-(q * T)))
        (Filter.Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) hd)
    simpa [bsPut] using hA.sub hB
  have hev : ∀ᶠ k in 𝓝[>] (0:ℝ), bsPut X k r q σ T ≤ bsPut X K r q σ T := by
    filter_upwards [Ioo_mem_nhdsGT hK] with k hk
    exact hmono hk.1 (Set.mem_Ioi.2 hK) hk.2.le
  exact le_of_tendsto hlim hev

#print axioms bsPut_nonneg

/-- **Drop the clock term and the premium is a power; the put keeps the negative root**
(Steps 3 and the detailed proof). Under Black-Scholes dynamics with constant rate `r > 0`,
yield `q` and volatility `σ > 0`, and a life `T > 0`: the two roots `β₁, β₂` of
`β² + (n−1)β − m/h = 0` multiply to `−m/h`, with `β₁ < 0 < β₂`; every combination
`f(S) = a₁ S^β₁ + a₂ S^β₂` solves the reduced equation `S² f'' + n S f' − (m/h) f = 0` at every
share price `S > 0`; and such an `f` falls to zero as the share price grows exactly when
`a₂ = 0`, so the premium is a power `A (S/S*)^β₁` of the share price. -/
theorem baw_reduced_equation_solved_by_negative_power
    (r q σ T : ℝ) (hr : 0 < r) (hσ : 0 < σ) (hT : 0 < T) :
    bawBeta1 r q σ T ^ 2 + (bawN r q σ - 1) * bawBeta1 r q σ T - bawM r σ / bawH r T = 0 ∧
      bawBeta2 r q σ T ^ 2 + (bawN r q σ - 1) * bawBeta2 r q σ T - bawM r σ / bawH r T = 0 ∧
      bawBeta1 r q σ T * bawBeta2 r q σ T = -(bawM r σ / bawH r T) ∧
      bawBeta1 r q σ T < 0 ∧ 0 < bawBeta2 r q σ T ∧
      ∀ a₁ a₂ : ℝ,
        (∀ S : ℝ, 0 < S →
          S ^ 2 * deriv (deriv (fun x : ℝ =>
              a₁ * x ^ bawBeta1 r q σ T + a₂ * x ^ bawBeta2 r q σ T)) S +
            bawN r q σ * S * deriv (fun x : ℝ =>
              a₁ * x ^ bawBeta1 r q σ T + a₂ * x ^ bawBeta2 r q σ T) S -
            bawM r σ / bawH r T * (a₁ * S ^ bawBeta1 r q σ T + a₂ * S ^ bawBeta2 r q σ T) = 0) ∧
        (Tendsto (fun x : ℝ => a₁ * x ^ bawBeta1 r q σ T + a₂ * x ^ bawBeta2 r q σ T)
            atTop (𝓝 0) ↔ a₂ = 0) := by
  have hc := bawMH_pos r σ T hr hσ hT
  have e : 4 * bawM r σ / bawH r T = 4 * (bawM r σ / bawH r T) := mul_div_assoc _ _ _
  have hD : 0 ≤ (bawN r q σ - 1) ^ 2 + 4 * (bawM r σ / bawH r T) := by positivity
  have hs := sq_sqrt hD
  have hs0 := sqrt_nonneg ((bawN r q σ - 1) ^ 2 + 4 * (bawM r σ / bawH r T))
  have hb1 : bawBeta1 r q σ T = (-(bawN r q σ - 1) -
      √((bawN r q σ - 1) ^ 2 + 4 * (bawM r σ / bawH r T))) / 2 := by
    rw [bawBeta1, e]
  have hb2 : bawBeta2 r q σ T = (-(bawN r q σ - 1) +
      √((bawN r q σ - 1) ^ 2 + 4 * (bawM r σ / bawH r T))) / 2 := by
    rw [bawBeta2, e]
  have h1 : bawBeta1 r q σ T ^ 2 + (bawN r q σ - 1) * bawBeta1 r q σ T -
      bawM r σ / bawH r T = 0 := by
    rw [hb1]; linear_combination hs / 4
  have h2 : bawBeta2 r q σ T ^ 2 + (bawN r q σ - 1) * bawBeta2 r q σ T -
      bawM r σ / bawH r T = 0 := by
    rw [hb2]; linear_combination hs / 4
  have h3 : bawBeta1 r q σ T * bawBeta2 r q σ T = -(bawM r σ / bawH r T) := by
    rw [hb1, hb2]; linear_combination (-1 / 4) * hs
  have h4 : bawBeta1 r q σ T < 0 := by rw [hb1]; nlinarith
  have h5 : 0 < bawBeta2 r q σ T := by rw [hb2]; nlinarith
  refine ⟨h1, h2, h3, h4, h5, ?_⟩
  intro a₁ a₂
  set p1 := bawBeta1 r q σ T with hp1
  set p2 := bawBeta2 r q σ T with hp2
  refine ⟨?_, ?_⟩
  · intro S hS
    have hd : ∀ x : ℝ, 0 < x → HasDerivAt (fun x : ℝ => a₁ * x ^ p1 + a₂ * x ^ p2)
        (a₁ * (p1 * x ^ (p1 - 1)) + a₂ * (p2 * x ^ (p2 - 1))) x := by
      intro x hx
      exact ((hasDerivAt_rpow_const (Or.inl hx.ne')).const_mul a₁).add
        ((hasDerivAt_rpow_const (Or.inl hx.ne')).const_mul a₂)
    have hev : deriv (fun x : ℝ => a₁ * x ^ p1 + a₂ * x ^ p2) =ᶠ[𝓝 S]
        fun x => a₁ * (p1 * x ^ (p1 - 1)) + a₂ * (p2 * x ^ (p2 - 1)) :=
      Filter.eventually_of_mem (Ioi_mem_nhds hS) fun x hx => (hd x hx).deriv
    have hd2 : HasDerivAt (fun x : ℝ => a₁ * (p1 * x ^ (p1 - 1)) + a₂ * (p2 * x ^ (p2 - 1)))
        (a₁ * (p1 * ((p1 - 1) * S ^ (p1 - 1 - 1))) + a₂ * (p2 * ((p2 - 1) * S ^ (p2 - 1 - 1)))) S :=
      (((hasDerivAt_rpow_const (Or.inl hS.ne')).const_mul p1).const_mul a₁).add
        (((hasDerivAt_rpow_const (Or.inl hS.ne')).const_mul p2).const_mul a₂)
    rw [hev.deriv_eq, hd2.deriv, (hd S hS).deriv]
    have hw : ∀ p : ℝ, S ^ p = S ^ (p - 1 - 1) * S ^ 2 := by
      intro p
      rw [← rpow_natCast, ← rpow_add hS]
      congr 1
      push_cast
      ring
    have hv : ∀ p : ℝ, S ^ (p - 1) = S ^ (p - 1 - 1) * S := by
      intro p
      rw [← rpow_add_one hS.ne']
      congr 1
      ring
    rw [hv p1, hv p2, hw p1, hw p2]
    linear_combination (a₁ * S ^ (p1 - 1 - 1) * S ^ 2) * h1 + (a₂ * S ^ (p2 - 1 - 1) * S ^ 2) * h2
  · have hp1t : Tendsto (fun x : ℝ => x ^ p1) atTop (𝓝 0) := by
      have := tendsto_rpow_neg_atTop (neg_pos.2 h4)
      simpa using this
    constructor
    · intro h
      by_contra ha
      have h' : Tendsto (fun x : ℝ => x ^ p2) atTop (𝓝 0) := by
        have := (h.sub (hp1t.const_mul a₁)).const_mul a₂⁻¹
        simp only [mul_zero, sub_zero] at this
        refine this.congr fun x => ?_
        rw [add_sub_cancel_left, ← mul_assoc, inv_mul_cancel₀ ha, one_mul]
      exact not_tendsto_nhds_of_tendsto_atTop (tendsto_rpow_atTop h5) 0 h'
    · rintro rfl
      simpa using hp1t.const_mul a₁

/-- **Smooth pasting at the critical price** (Step 4). With strike `K > 0`, rate `r > 0`,
volatility `σ > 0` and life `T > 0`, let `S* > 0` solve the critical-price equation
`K − S* = p(S*) + A`, with `A = −(S*/β₁)(1 − e^(−qT) N(−d₁(S*)))`. Then the Barone-Adesi-Whaley
price, `K − S` at or below `S*` and `p(S) + A (S/S*)^β₁` above it, has slope exactly `−1` at
`S*`: the price curve meets the exercise line tangentially, not at a corner. -/
theorem baw_put_smooth_pasting_at_critical_price
    (K r q σ T Sstar : ℝ) (hK : 0 < K) (hr : 0 < r) (hσ : 0 < σ) (hT : 0 < T) (hS : 0 < Sstar)
    (hmatch : K - Sstar = bsPut Sstar K r q σ T + bawA Sstar K r q σ T) :
    HasDerivAt (bawPut Sstar K r q σ T) (-1) Sstar := by
  have hb := bawBeta1_neg r q σ T hr hσ hT
  have hgd : HasDerivAt (fun S => bsPut S K r q σ T +
      bawA Sstar K r q σ T * (S / Sstar) ^ bawBeta1 r q σ T) (-1) Sstar := by
    have h := (bsPut_hasDerivAt_X Sstar K r q σ T hS hK hσ hT).add
      ((((hasDerivAt_id' Sstar).div_const Sstar).rpow_const
        (p := bawBeta1 r q σ T) (Or.inl (div_pos hS hS).ne')).const_mul (bawA Sstar K r q σ T))
    convert h using 1
    rw [div_self hS.ne', one_rpow, bawA]
    have h1 : bawBeta1 r q σ T ≠ 0 := hb.ne
    have h2 : Sstar ≠ 0 := hS.ne'
    field_simp
    ring
  have hleft : HasDerivWithinAt (bawPut Sstar K r q σ T) (-1) (Set.Iic Sstar) Sstar := by
    have h := ((hasDerivAt_id' Sstar).const_sub K).hasDerivWithinAt (s := Set.Iic Sstar)
    exact h.congr_of_mem (fun x hx => by simp [bawPut, Set.mem_Iic.1 hx]) (Set.mem_Iic.2 le_rfl)
  have hright : HasDerivWithinAt (bawPut Sstar K r q σ T) (-1) (Set.Ici Sstar) Sstar := by
    refine hgd.hasDerivWithinAt.congr_of_mem (fun x hx => ?_) (Set.mem_Ici.2 le_rfl)
    by_cases h : x ≤ Sstar
    · have hx' : x = Sstar := le_antisymm h hx
      subst hx'
      simp only [bawPut, le_refl, ite_true, div_self hS.ne', one_rpow, mul_one]
      exact hmatch
    · simp [bawPut, h]
  have := hleft.union hright
  rwa [Set.Iic_union_Ici, hasDerivWithinAt_univ] at this

/-- **A critical price exists below the strike** (detailed proof, "Matching"). With strike
`K > 0`, rate `r > 0`, dividend yield `q ≥ 0`, volatility `σ > 0` and life `T > 0`, the
critical-price equation `K − S* = p(S*) − (1 − e^(−qT) N(−d₁(S*))) S*/β₁` has a root strictly
between `0` and `K`. -/
theorem baw_critical_price_exists_below_strike
    (K r q σ T : ℝ) (hK : 0 < K) (hr : 0 < r) (hq : 0 ≤ q) (hσ : 0 < σ) (hT : 0 < T) :
    ∃ Sstar ∈ Set.Ioo 0 K,
      K - Sstar = bsPut Sstar K r q σ T -
        (1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 Sstar K r q σ T)) * Sstar /
          bawBeta1 r q σ T := by
  have hb := bawBeta1_neg r q σ T hr hσ hT
  set β := bawBeta1 r q σ T with hβ
  set F : ℝ → ℝ := fun S => bsPut S K r q σ T -
    (1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 S K r q σ T)) * S / β - (K - S) with hF
  have hd1c : ContinuousOn (fun S => bsD1 S K r q σ T) (Set.Ioi 0) := fun S hS =>
    (bsD1_hasDerivAt_X S K r q σ T hS hK).continuousAt.continuousWithinAt
  have hputc : ContinuousOn (fun S => bsPut S K r q σ T) (Set.Ioi 0) := fun S hS =>
    (bsPut_hasDerivAt_X S K r q σ T hS hK hσ hT).continuousAt.continuousWithinAt
  have hFc : ContinuousOn F (Set.Ioi 0) := by
    have h3 : ContinuousOn (fun S => cdf (gaussianReal 0 1) (-bsD1 S K r q σ T)) (Set.Ioi 0) :=
      bawPhi_continuous.comp_continuousOn hd1c.neg
    exact (hputc.sub (((continuousOn_const.sub (continuousOn_const.mul h3)).mul
      continuousOn_id).div_const β)).sub (continuousOn_const.sub continuousOn_id)
  have her : exp (-(r * T)) < 1 := by rw [exp_lt_one_iff]; nlinarith
  have her0 := exp_pos (-(r * T))
  have heq : exp (-(q * T)) ≤ 1 := by rw [exp_le_one_iff]; nlinarith
  have heq0 := exp_pos (-(q * T))
  set S0 := K * (1 - exp (-(r * T))) * (-β) / (2 * (1 - β)) with hS0
  have hS0pos : 0 < S0 :=
    div_pos (mul_pos (mul_pos hK (by linarith)) (neg_pos.2 hb)) (by linarith)
  have hS0K : S0 < K := by
    rw [hS0, div_lt_iff₀ (by linarith)]
    have : K * (1 - exp (-(r * T))) * (-β) < K * 1 * (-β) :=
      mul_lt_mul_of_pos_right (mul_lt_mul_of_pos_left (by linarith) hK) (neg_pos.2 hb)
    nlinarith
  have hFS0 : F S0 < 0 := by
    have hΦ1 := cdf_nonneg (gaussianReal 0 1) (-bsD1 S0 K r q σ T)
    have hΦ2 := cdf_le_one (gaussianReal 0 1) (-bsD1 S0 K r q σ T)
    have hΦ3 := cdf_nonneg (gaussianReal 0 1) (-(bsD1 S0 K r q σ T - σ * √T))
    have hΦ4 := cdf_le_one (gaussianReal 0 1) (-(bsD1 S0 K r q σ T - σ * √T))
    have hput : bsPut S0 K r q σ T ≤ K * exp (-(r * T)) := by
      unfold bsPut
      have : 0 ≤ S0 * exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 S0 K r q σ T) := by
        positivity
      have : K * exp (-(r * T)) * cdf (gaussianReal 0 1) (-(bsD1 S0 K r q σ T - σ * √T)) ≤
          K * exp (-(r * T)) := mul_le_of_le_one_right (by positivity) hΦ4
      linarith
    have ht : S0 / β ≤ 0 := div_nonpos_of_nonneg_of_nonpos hS0pos.le hb.le
    have hc1 : 1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 S0 K r q σ T) ≤ 1 := by
      nlinarith
    have hcS : (1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 S0 K r q σ T)) * S0 / β ≥
        S0 / β := by
      rw [mul_div_assoc]; nlinarith
    have hsum : S0 - S0 / β = K * (1 - exp (-(r * T))) / 2 := by
      rw [hS0]
      have : β ≠ 0 := hb.ne
      have : 1 - β ≠ 0 := by linarith
      field_simp
      ring
    simp only [hF]
    nlinarith
  have hFK : 0 < F K := by
    have hΦ1 := cdf_nonneg (gaussianReal 0 1) (-bsD1 K K r q σ T)
    have hΦ2 := bawPhi_lt_one (-bsD1 K K r q σ T)
    have hp := bsPut_nonneg K K r q σ T hK hK hσ hT
    have hc : 0 < 1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 K K r q σ T) := by
      nlinarith
    have : (1 - exp (-(q * T)) * cdf (gaussianReal 0 1) (-bsD1 K K r q σ T)) * K / β < 0 :=
      div_neg_of_pos_of_neg (mul_pos hc hK) hb
    simp only [hF]
    linarith
  obtain ⟨c, hc, hFc0⟩ := intermediate_value_Icc hS0K.le
    (hFc.mono fun x hx => lt_of_lt_of_le hS0pos hx.1) ⟨hFS0.le, hFK.le⟩
  have hcK : c ≠ K := by
    rintro rfl
    linarith
  refine ⟨c, ⟨lt_of_lt_of_le hS0pos hc.1, lt_of_le_of_ne hc.2 hcK⟩, ?_⟩
  simp only [hF] at hFc0
  linarith

/-! The card's exact numbers for Acme: `r = 5/100`, `q = 2/100`, `σ = 20/100`. -/

-- m = 2r/σ² = 0.10/0.04 = 2.5.
example : bawM (5 / 100) (20 / 100) = 5 / 2 := by norm_num [bawM]

-- n = 2(r − q)/σ² = 0.06/0.04 = 1.5.
example : bawN (5 / 100) (2 / 100) (20 / 100) = 3 / 2 := by norm_num [bawN]

-- The drift in d₁: r − q + σ²/2 = 0.05, as in the hand table's d₁(S*) line.
example : (5 / 100 : ℚ) - 2 / 100 + (20 / 100) ^ 2 / 2 = 5 / 100 := by norm_num

-- (n − 1)² = 0.25, the first term under the square root in β₁.
example : ((3 : ℚ) / 2 - 1) ^ 2 = 1 / 4 := by norm_num

-- A 2,000-step tree has 1 + 2 + … + 2000 = 2,001,000 nodes before expiry.
example : ∑ i ∈ Finset.range 2000, (i + 1) = 2001000 := by
  rw [Finset.sum_add_distrib, Finset.sum_range_id]; simp

#print axioms baw_reduced_equation_solved_by_negative_power
#print axioms baw_put_smooth_pasting_at_critical_price
#print axioms baw_critical_price_exists_below_strike

end BaroneAdesiWhaley
