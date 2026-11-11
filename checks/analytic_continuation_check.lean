-- Analytic continuation: two holomorphic functions on a connected open region that agree on a set piling up at a point of the region agree on all of it, so 1/(1 - z) is the only continuation of the geometric series and 1/r the only continuation of the perpetuity price to negative rates.
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Analytic.IsolatedZeros
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Normed.Module.Connected
import Mathlib.LinearAlgebra.Complex.FiniteDimensional

open Set Filter Topology

/-- The plane without the point 1 is connected. -/
theorem ac_compl_one_isConnected : IsConnected ({1}ᶜ : Set ℂ) :=
  isConnected_compl_singleton_of_one_lt_rank (Complex.rank_real_complex ▸ Nat.one_lt_ofNat) _

/-- The points of the real interval (0, 1) pile up at 1/2 in the complex plane. -/
theorem ac_accPt_half :
    AccPt ((1 / 2 : ℝ) : ℂ) (𝓟 ((fun x : ℝ => (x : ℂ)) '' Ioo (0 : ℝ) 1)) := by
  rw [accPt_iff_frequently_nhdsNE]
  have hT : Tendsto (fun x : ℝ => (x : ℂ)) (𝓝[≠] (1 / 2 : ℝ)) (𝓝[≠] ((1 / 2 : ℝ) : ℂ)) := by
    apply Complex.continuous_ofReal.continuousWithinAt.tendsto_nhdsWithin
    intro x hx h
    exact hx (Complex.ofReal_injective h)
  have hev : ∀ᶠ x in 𝓝[≠] (1 / 2 : ℝ), x ∈ Ioo (0 : ℝ) 1 :=
    nhdsWithin_le_nhds (Ioo_mem_nhds (by norm_num) (by norm_num))
  exact hT.frequently (hev.frequently.mono fun x hx => mem_image_of_mem _ hx)

#print axioms ac_compl_one_isConnected
#print axioms ac_accPt_half

/-- The identity theorem, the card's main claim. Let f and g be holomorphic (complex
differentiable at every point) on a connected open region U. If f = g on a set S that piles up
at a point z₀ of U (every disc round z₀ holds a point of S other than z₀), then f = g on all of
U. So a function given on a small patch has at most one holomorphic extension to a larger
connected region. -/
theorem analytic_continuation_unique {U S : Set ℂ} {f g : ℂ → ℂ} {z₀ : ℂ}
    (hU : IsOpen U) (hconn : IsConnected U)
    (hf : DifferentiableOn ℂ f U) (hg : DifferentiableOn ℂ g U)
    (hfg : EqOn f g S) (hz₀ : z₀ ∈ U) (hacc : AccPt z₀ (𝓟 S)) :
    EqOn f g U := by
  have hfa := hf.analyticOnNhd hU
  have hga := hg.analyticOnNhd hU
  refine hfa.eqOn_of_preconnected_of_frequently_eq hga hconn.isPreconnected hz₀ ?_
  exact (accPt_iff_frequently_nhdsNE.mp hacc).mono fun z hz => hfg hz

/-- The geometric series 1 + z + z^2 + ... settles only on the unit disc, but 1/(1 - z) is
holomorphic on the plane without the point 1, agrees with the sum on the unit disc, and is the
only holomorphic function on the plane without 1 that does. -/
theorem geometric_series_unique_continuation :
    DifferentiableOn ℂ (fun z : ℂ => (1 - z)⁻¹) {1}ᶜ ∧
    (∀ z : ℂ, ‖z‖ < 1 → ∑' n : ℕ, z ^ n = (1 - z)⁻¹) ∧
    ∀ g : ℂ → ℂ, DifferentiableOn ℂ g {1}ᶜ →
      (∀ z : ℂ, ‖z‖ < 1 → g z = ∑' n : ℕ, z ^ n) →
      ∀ z : ℂ, z ≠ 1 → g z = (1 - z)⁻¹ := by
  have hd : DifferentiableOn ℂ (fun z : ℂ => (1 - z)⁻¹) {1}ᶜ := by
    intro z hz
    apply DifferentiableAt.differentiableWithinAt
    apply DifferentiableAt.inv ((differentiableAt_const _).sub differentiableAt_id)
    intro h
    exact hz (by simpa using (sub_eq_zero.mp h).symm)
  refine ⟨hd, fun z hz => tsum_geometric_of_norm_lt_one hz, ?_⟩
  intro g hg hgs z hz
  have hopen : IsOpen ({1}ᶜ : Set ℂ) := isOpen_compl_singleton
  have hacc : AccPt (0 : ℂ) (𝓟 (Metric.ball (0 : ℂ) 1)) := by
    rw [accPt_iff_frequently_nhdsNE]
    have hev : ∀ᶠ y in 𝓝[≠] (0 : ℂ), y ∈ Metric.ball (0 : ℂ) 1 :=
      nhdsWithin_le_nhds (Metric.ball_mem_nhds (0 : ℂ) one_pos)
    exact hev.frequently
  have hEq : EqOn g (fun z : ℂ => (1 - z)⁻¹) (Metric.ball (0 : ℂ) 1) := by
    intro w hw
    have hw' : ‖w‖ < 1 := by simpa using hw
    rw [hgs w hw', tsum_geometric_of_norm_lt_one hw']
  exact analytic_continuation_unique hopen ac_compl_one_isConnected hg hd hEq
    (by simp) hacc hz

/-- Positive rates alone fix the perpetuity price everywhere. If g is holomorphic in the discount
factor z on the plane without 1, and at every positive rate r it equals the perpetuity sum
z + z^2 + z^3 + ... at z = 1/(1 + r), then at every rate r other than 0 and -100% the
continued price g(1/(1 + r)) is 1/r. At -0.5% that is -200. -/
theorem perpetuity_continuation_eq_inv_rate (g : ℂ → ℂ) (hg : DifferentiableOn ℂ g {1}ᶜ)
    (hsum : ∀ r : ℝ, 0 < r → g (1 / (1 + (r : ℂ))) = ∑' n : ℕ, (1 / (1 + (r : ℂ))) ^ (n + 1))
    (r : ℝ) (hr : r ≠ 0) (hr1 : 1 + r ≠ 0) :
    g (1 / (1 + (r : ℂ))) = 1 / (r : ℂ) := by
  have hopen : IsOpen ({1}ᶜ : Set ℂ) := isOpen_compl_singleton
  have hd : DifferentiableOn ℂ (fun z : ℂ => z * (1 - z)⁻¹) {1}ᶜ := by
    intro z hz
    apply DifferentiableAt.differentiableWithinAt
    apply differentiableAt_id.mul
    apply DifferentiableAt.inv ((differentiableAt_const _).sub differentiableAt_id)
    intro h
    exact hz (by simpa using (sub_eq_zero.mp h).symm)
  have hEq : EqOn g (fun z : ℂ => z * (1 - z)⁻¹) ((fun x : ℝ => (x : ℂ)) '' Ioo (0 : ℝ) 1) := by
    rintro _ ⟨x, ⟨hx0, hx1⟩, rfl⟩
    have hr : 0 < 1 / x - 1 := by
      rw [sub_pos, lt_div_iff₀ hx0]; linarith
    have key : (1 / (1 + (((1 / x - 1 : ℝ)) : ℂ))) = (x : ℂ) := by
      have hx0' : (x : ℂ) ≠ 0 := by exact_mod_cast hx0.ne'
      push_cast
      field_simp
      ring
    have h := hsum (1 / x - 1) hr
    rw [key] at h
    rw [h]
    have hn : ‖(x : ℂ)‖ < 1 := by
      rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos hx0]; exact hx1
    simp only [pow_succ']
    rw [tsum_mul_left, tsum_geometric_of_norm_lt_one hn]
  have hacc := ac_accPt_half
  have hz : (1 / (1 + (r : ℂ))) ∈ ({1}ᶜ : Set ℂ) := by
    intro h
    simp only [mem_singleton_iff] at h
    have h1 : (1 + (r : ℂ)) ≠ 0 := by exact_mod_cast hr1
    rw [div_eq_one_iff_eq h1] at h
    apply hr
    have : (r : ℂ) = 0 := by linear_combination -h
    exact_mod_cast this
  rw [analytic_continuation_unique hopen ac_compl_one_isConnected hg hd hEq
    (by norm_num) hacc hz]
  have h1 : (1 + (r : ℂ)) ≠ 0 := by exact_mod_cast hr1
  have h2 : (r : ℂ) ≠ 0 := by exact_mod_cast hr
  field_simp
  simp [h2]

-- At 5%: z = 1/1.05 = 20/21, and the perpetuity price z/(1 - z) is 20, which is 1/r.
example : (1 : ℚ) / (1 + 5 / 100) = 20 / 21 := by norm_num
example : ((20 : ℚ) / 21) / (1 - 20 / 21) = 20 ∧ (1 : ℚ) / (5 / 100) = 20 := by norm_num
-- At -0.5%: the continued price 1/r is -200.
example : (1 : ℚ) / (-5 / 1000) = -200 := by norm_num
-- f at T: 0.995 / (0.995 - 1) = -199, and P = f(T) - 1 = -200.
example : ((995 : ℚ) / 1000) / (995 / 1000 - 1) = -199 ∧ (-199 : ℚ) - 1 = -200 := by norm_num
-- The chain of discs by hand, v = 1/(1 - c) at each centre c.
example : (1 - ((1 : ℂ) / 2 + (1 / 2) * Complex.I))⁻¹ = 1 + Complex.I := by
  rw [Complex.ext_iff]; simp [Complex.inv_re, Complex.inv_im, Complex.normSq]; norm_num
example : (1 - ((1 : ℂ) + (2 / 5) * Complex.I))⁻¹ = (5 / 2) * Complex.I := by
  rw [Complex.ext_iff]; simp
example : (1 - ((6 : ℂ) / 5 + (1 / 10) * Complex.I))⁻¹ = -4 + 2 * Complex.I := by
  rw [Complex.ext_iff]; simp [Complex.inv_re, Complex.inv_im, Complex.normSq]; norm_num
example : (1 - (102 : ℚ) / 100)⁻¹ = -50 := by norm_num
-- The mistake: counting a payment today, 1/(1 - z) at 5% is 21, not 20.
example : (1 - (20 : ℚ) / 21)⁻¹ = 21 := by norm_num
-- 1 + 2 + ... + 100 = 5050.
example : ∑ n ∈ Finset.range 101, n = 5050 := by decide

#print axioms analytic_continuation_unique
#print axioms geometric_series_unique_continuation
#print axioms perpetuity_continuation_eq_inv_rate
