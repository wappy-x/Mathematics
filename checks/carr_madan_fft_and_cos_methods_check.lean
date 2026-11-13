-- Transform pricing: the damped call curve's Fourier transform is one line of the log price's characteristic function, the locked grids turn the inversion sum into one discrete Fourier transform, and the COS put coefficients have the stated closed forms.
import Mathlib.Probability.Moments.ComplexMGF
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Nat.Log
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals

open MeasureTheory ProbabilityTheory Complex

lemma cm_inner_real (α : ℝ) (hα : 0 < α) (y : ℝ) :
    Integrable (fun k : ℝ => Real.exp (α * k) * max (Real.exp y - Real.exp k) 0) ∧
    ∫ k : ℝ, Real.exp (α * k) * max (Real.exp y - Real.exp k) 0 =
      Real.exp ((α + 1) * y) / (α * (α + 1)) := by
  have hfun : (fun k : ℝ => Real.exp (α * k) * max (Real.exp y - Real.exp k) 0) =
      Set.indicator (Set.Iic y)
        (fun k : ℝ => Real.exp y * Real.exp (α * k) - Real.exp ((α + 1) * k)) := by
    funext k
    by_cases hk : k ≤ y
    · rw [Set.indicator_of_mem (by simpa using hk),
        max_eq_left (by simpa using Real.exp_le_exp.mpr hk)]
      rw [add_mul, one_mul, Real.exp_add]; ring
    · rw [Set.indicator_of_notMem (by simpa using hk),
        max_eq_right (by simpa using (not_le.mp hk).le), mul_zero]
  have h1 := integrableOn_exp_mul_Iic hα y
  have h2 := integrableOn_exp_mul_Iic (by linarith : 0 < α + 1) y
  refine ⟨?_, ?_⟩
  · rw [hfun, integrable_indicator_iff measurableSet_Iic]
    exact (h1.const_mul _).sub h2
  · rw [hfun, integral_indicator measurableSet_Iic, integral_sub (h1.const_mul _) h2,
      integral_const_mul, integral_exp_mul_Iic hα, integral_exp_mul_Iic (by linarith)]
    have : Real.exp ((α + 1) * y) = Real.exp y * Real.exp (α * y) := by
      rw [add_mul, one_mul, Real.exp_add]; ring
    rw [this]
    field_simp
    ring

lemma cm_inner_complex (α : ℝ) (hα : 0 < α) (u y : ℝ) :
    Integrable (fun k : ℝ =>
      cexp (I * u * k) * ((Real.exp (α * k) * max (Real.exp y - Real.exp k) 0 : ℝ) : ℂ)) ∧
    ∫ k : ℝ, cexp (I * u * k) * ((Real.exp (α * k) * max (Real.exp y - Real.exp k) 0 : ℝ) : ℂ) =
      cexp (((α + 1 : ℝ) + I * u) * y) / (((α : ℂ) + I * u) * (((α + 1 : ℝ) : ℂ) + I * u)) := by
  have hc1 : 0 < ((α : ℂ) + I * u).re := by simp [hα]
  have hc2 : 0 < (((α + 1 : ℝ) : ℂ) + I * u).re := by simp; linarith
  have hfun : (fun k : ℝ =>
      cexp (I * u * k) * ((Real.exp (α * k) * max (Real.exp y - Real.exp k) 0 : ℝ) : ℂ)) =
      Set.indicator (Set.Iic y)
        (fun k : ℝ => (Real.exp y : ℂ) * cexp (((α : ℂ) + I * u) * k) -
          cexp ((((α + 1 : ℝ) : ℂ) + I * u) * k)) := by
    funext k
    by_cases hk : k ≤ y
    · rw [Set.indicator_of_mem (by simpa using hk),
        max_eq_left (by simpa using Real.exp_le_exp.mpr hk)]
      push_cast
      simp only [add_mul, exp_add, one_mul]
      ring
    · rw [Set.indicator_of_notMem (by simpa using hk),
        max_eq_right (by simpa using (not_le.mp hk).le), mul_zero]
      simp
  have h1 := integrableOn_exp_mul_complex_Iic hc1 y
  have h2 := integrableOn_exp_mul_complex_Iic hc2 y
  refine ⟨?_, ?_⟩
  · rw [hfun, integrable_indicator_iff measurableSet_Iic]
    exact (h1.const_mul _).sub h2
  · rw [hfun, integral_indicator measurableSet_Iic, integral_sub (h1.const_mul _) h2,
      integral_const_mul, integral_exp_mul_complex_Iic hc1, integral_exp_mul_complex_Iic hc2]
    have hne1 : ((α : ℂ) + I * u) ≠ 0 := fun h => by simp [h] at hc1
    have hne2 : (((α + 1 : ℝ) : ℂ) + I * u) ≠ 0 := fun h => by rw [h] at hc2; simp at hc2
    have hsplit : cexp ((((α + 1 : ℝ) : ℂ) + I * u) * y) =
        (Real.exp y : ℂ) * cexp (((α : ℂ) + I * u) * y) := by
      push_cast
      simp only [add_mul, exp_add, one_mul]
      ring
    have hdiff : (((α + 1 : ℝ) : ℂ) + I * u) = ((α : ℂ) + I * u) + 1 := by push_cast; ring
    rw [hsplit]
    field_simp
    rw [hdiff]
    ring

#print axioms cm_inner_real
#print axioms cm_inner_complex

/-- The call price at log strike `k`, in the card's coordinates:
`C(k) = S e^{-rT} E[(e^Y - e^k)^+]`, with `Y` the log share price at expiry against today's price. -/
noncomputable def callPrice {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (Y : Ω → ℝ)
    (S r T k : ℝ) : ℝ :=
  S * Real.exp (-r * T) * ∫ ω, max (Real.exp (Y ω) - Real.exp k) 0 ∂P

/-- Carr–Madan. Pick a damping exponent `α > 0` and set `p = α + 1`. If the share price has a
finite moment of order `p`, that is `E[e^{pY}] < ∞`, then the damped call curve
`c(k) = e^{αk} C(k)` is integrable over all log strikes, and its Fourier transform is one line of
the characteristic function `Φ(z) = E[e^{zY}]`:
`∫ e^{iuk} c(k) dk = S e^{-rT} Φ(p + iu) / ((α + iu)(p + iu))` for every real frequency `u`. -/
theorem carr_madan_damped_call_transform {Ω : Type*} [MeasurableSpace Ω]
    (P : Measure Ω) [IsProbabilityMeasure P] (Y : Ω → ℝ) (S r T α : ℝ) (hα : 0 < α)
    (hmoment : Integrable (fun ω => Real.exp ((α + 1) * Y ω)) P) (u : ℝ) :
    Integrable (fun k : ℝ => Real.exp (α * k) * callPrice P Y S r T k) ∧
    ∫ k : ℝ, cexp (I * u * k) * ((Real.exp (α * k) * callPrice P Y S r T k : ℝ) : ℂ) =
      (S : ℂ) * (Real.exp (-r * T) : ℂ) * complexMGF Y P ((α + 1 : ℝ) + I * u) /
        (((α : ℂ) + I * u) * (((α + 1 : ℝ) : ℂ) + I * u)) := by
  have hp : (α + 1) ≠ 0 := by linarith
  have hY : AEMeasurable Y P := by
    have h := (Real.measurable_log.comp_aemeasurable hmoment.aemeasurable).div_const (α + 1)
    convert h using 1
    funext ω
    simp [Function.comp, Real.log_exp]
    field_simp
  let F : Ω × ℝ → ℝ := fun z => Real.exp (α * z.2) * max (Real.exp (Y z.1) - Real.exp z.2) 0
  have hFnn : ∀ z, 0 ≤ F z := fun z => mul_nonneg (Real.exp_pos _).le (le_max_right _ _)
  have hpair : AEMeasurable (fun z : Ω × ℝ => (Y z.1, z.2)) (P.prod volume) :=
    hY.comp_fst.prodMk measurable_snd.aemeasurable
  have hFm : AEStronglyMeasurable F (P.prod volume) := by
    have hg : Continuous (fun q : ℝ × ℝ =>
        Real.exp (α * q.2) * max (Real.exp q.1 - Real.exp q.2) 0) := by fun_prop
    exact (hg.measurable.comp_aemeasurable hpair).aestronglyMeasurable
  have hF : Integrable F (P.prod volume) := by
    rw [integrable_prod_iff hFm]
    refine ⟨Filter.Eventually.of_forall fun ω => (cm_inner_real α hα (Y ω)).1, ?_⟩
    have : (fun ω => ∫ k, ‖F (ω, k)‖) =
        fun ω => Real.exp ((α + 1) * Y ω) / (α * (α + 1)) := by
      funext ω
      simp_rw [Real.norm_of_nonneg (hFnn _)]
      exact (cm_inner_real α hα (Y ω)).2
    rw [this]
    exact hmoment.div_const _
  let H : Ω × ℝ → ℂ := fun z => cexp (I * u * z.2) * (F z : ℂ)
  have hHm : AEStronglyMeasurable H (P.prod volume) := by
    have hg : Continuous (fun q : ℝ × ℝ => cexp (I * u * q.2) *
        ((Real.exp (α * q.2) * max (Real.exp q.1 - Real.exp q.2) 0 : ℝ) : ℂ)) := by fun_prop
    exact (hg.measurable.comp_aemeasurable hpair).aestronglyMeasurable
  have hH : Integrable H (P.prod volume) := by
    refine hF.mono' hHm (Filter.Eventually.of_forall fun z => ?_)
    have : ‖cexp (I * u * z.2)‖ = 1 := by
      rw [norm_exp]; simp
    simp only [H, norm_mul, this, one_mul, norm_real, Real.norm_of_nonneg (hFnn z)]
    rfl
  constructor
  · have := (hF.integral_prod_right).const_mul (S * Real.exp (-r * T))
    convert this using 1
    funext k
    simp only [callPrice, F]
    rw [integral_const_mul]
    ring
  · have h1 : ∀ k : ℝ, cexp (I * u * k) * ((Real.exp (α * k) * callPrice P Y S r T k : ℝ) : ℂ) =
        ((S : ℂ) * (Real.exp (-r * T) : ℂ)) * ∫ ω, H (ω, k) ∂P := by
      intro k
      simp only [H, F, callPrice]
      rw [integral_const_mul, integral_complex_ofReal, integral_const_mul]
      push_cast
      ring
    simp_rw [h1]
    rw [integral_const_mul,
      ← integral_integral_swap (f := fun ω k => H (ω, k)) hH]
    have h2 : ∀ ω, ∫ k, H (ω, k) = cexp (((α + 1 : ℝ) + I * u) * Y ω) /
        (((α : ℂ) + I * u) * (((α + 1 : ℝ) : ℂ) + I * u)) :=
      fun ω => (cm_inner_complex α hα u (Y ω)).2
    simp_rw [h2]
    rw [integral_div, complexMGF]
    ring

/-- The grid lock. With frequencies `u_j = (j + 1/2) η`, log strikes `k_ℓ = -π/η + ℓλ` and
`λη = 2π/N`, the midpoint sum for log strike `k_ℓ` is a discrete Fourier transform:
`Σ_j e^{-i u_j k_ℓ} ψ(u_j) = e^{-iπℓ/N} Σ_j i(-1)^j ψ(u_j) e^{-2πijℓ/N}`, for any transform `ψ`. -/
theorem carr_madan_grid_sum_is_dft (N : ℕ) (η lam : ℝ) (hη : η ≠ 0)
    (hlock : lam * η = 2 * Real.pi / N) (ψ : ℝ → ℂ) (ℓ : ℕ) :
    ∑ j ∈ Finset.range N,
        cexp (-I * (((j + 1 / 2) * η : ℝ) : ℂ) * ((-Real.pi / η + ℓ * lam : ℝ) : ℂ)) *
          ψ ((j + 1 / 2) * η) =
      cexp (-I * Real.pi * ℓ / N) *
        ∑ j ∈ Finset.range N,
          I * (-1) ^ j * ψ ((j + 1 / 2) * η) * cexp (-2 * Real.pi * I * j * ℓ / N) := by
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp
  have hN' : (N : ℝ) ≠ 0 := by positivity
  have hNc : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun j _ => ?_
  have key : ((j + 1 / 2) * η * (-Real.pi / η + ℓ * lam) : ℝ) =
      -((j + 1 / 2) * Real.pi) + (j + 1 / 2) * ℓ * (2 * Real.pi / N) := by
    rw [← hlock]; field_simp
  have hexp : -I * (((j + 1 / 2) * η : ℝ) : ℂ) * ((-Real.pi / η + ℓ * lam : ℝ) : ℂ) =
      (j : ℂ) * (Real.pi * I) + Real.pi / 2 * I + (-I * Real.pi * ℓ / N) +
        (-2 * Real.pi * I * j * ℓ / N) := by
    rw [mul_assoc, ← ofReal_mul, key]
    push_cast
    field_simp
    ring_nf
  rw [hexp, exp_add, exp_add, exp_add, exp_nat_mul, exp_pi_mul_I, exp_pi_div_two_mul_I]
  ring

/-- COS payoff coefficients. For a nonzero cosine frequency `ω`, integrating over `[a, d]`:
`∫ cos(ω(y - a)) dy = sin(ω(d - a))/ω` and
`∫ e^y cos(ω(y - a)) dy = (e^d [cos(ω(d - a)) + ω sin(ω(d - a))] - e^a) / (1 + ω²)`. -/
theorem cos_put_payoff_coefficients (a d ω : ℝ) (hω : ω ≠ 0) :
    (∫ y in a..d, Real.cos (ω * (y - a))) = Real.sin (ω * (d - a)) / ω ∧
    (∫ y in a..d, Real.exp y * Real.cos (ω * (y - a))) =
      (Real.exp d * (Real.cos (ω * (d - a)) + ω * Real.sin (ω * (d - a))) - Real.exp a) /
        (1 + ω ^ 2) := by
  have hpos : (1 + ω ^ 2) ≠ 0 := by positivity
  constructor
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun y => Real.sin (ω * (y - a)) / ω)]
    · simp
    · intro x _
      have h1 : HasDerivAt (fun y => ω * (y - a)) ω x := by
        simpa using ((hasDerivAt_id x).sub_const a).const_mul ω
      have := (h1.sin).div_const ω
      convert this using 1
      field_simp
    · exact (by fun_prop : Continuous fun y => Real.cos (ω * (y - a))).intervalIntegrable _ _
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun y => Real.exp y * (Real.cos (ω * (y - a)) + ω * Real.sin (ω * (y - a))) /
        (1 + ω ^ 2))]
    · simp; ring
    · intro x _
      have h1 : HasDerivAt (fun y => ω * (y - a)) ω x := by
        simpa using ((hasDerivAt_id x).sub_const a).const_mul ω
      have := (((Real.hasDerivAt_exp x).mul
        ((h1.cos).add ((h1.sin).const_mul ω)))).div_const (1 + ω ^ 2)
      convert this using 1
      simp only [Pi.add_apply]
      field_simp
      ring
    · exact (by fun_prop : Continuous fun y => Real.exp y * Real.cos (ω * (y - a))).intervalIntegrable _ _

-- The card's grid: N = 4096 points at frequency step η = 1/4 give a cutoff of 1024.
example : (4096 : ℚ) * (1 / 4) = 1024 := by norm_num
-- Damping α = 3/2 gives p = α + 1 = 5/2.
example : (3 / 2 : ℚ) + 1 = 5 / 2 := by norm_num
-- 4096 is a power of two, 2^12, so log₂ N = 12.
example : (4096 : ℕ) = 2 ^ 12 := by norm_num
example : Nat.log 2 4096 = 12 := by
  rw [show (4096 : ℕ) = 2 ^ 12 by norm_num, Nat.log_pow (by norm_num)]
-- N² against N log₂ N at 4,096 points: "some 340 times less work" (341 in whole numbers).
example : 4096 ^ 2 / (4096 * 12) = 341 := by norm_num
-- The middle grid cell, where K = 100, is cell N/2 = 2048; 16 and 32 cells either side.
example : 4096 / 2 = 2048 ∧ 2048 - 32 = 2016 ∧ 2048 + 32 = 2080 := by norm_num

#print axioms carr_madan_damped_call_transform
#print axioms carr_madan_grid_sum_is_dft
#print axioms cos_put_payoff_coefficients
