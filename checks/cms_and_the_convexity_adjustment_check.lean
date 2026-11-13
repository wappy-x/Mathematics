-- Constant-maturity swaps: any twice continuously differentiable payoff equals a straight line plus a strip of receiver and payer payoffs weighted by its second derivative, the CMS rate splits into the forward plus a replicable adjustment, and the strip weights have the stated formula.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.Calculus.ContDiff.Basic

open MeasureTheory

/-- The static replication (strip identity): for any payoff `f` with a continuous second
derivative, any forward `F > 0` and any rate `s > 0`,
`f(s) = f(F) + f'(F)(s - F) + ∫₀^F f''(k) (k - s)⁺ dk + ∫_F^∞ f''(k) (s - k)⁺ dk`.
A curved payoff is a straight line plus receivers below the forward and payers above it,
each sized by how sharply the payoff bends at its strike. -/
theorem static_replication_strip (f : ℝ → ℝ) (hf : ContDiff ℝ 2 f) (F s : ℝ)
    (hF : 0 < F) (hs : 0 < s) :
    f s = f F + deriv f F * (s - F)
      + (∫ k in (0 : ℝ)..F, deriv (deriv f) k * max (k - s) 0)
      + ∫ k in Set.Ioi F, deriv (deriv f) k * max (s - k) 0 := by
  have h1 : ContDiff ℝ (1 + 1) f := by rw [one_add_one_eq_two]; exact hf
  obtain ⟨hfd, -, hf1⟩ := contDiff_succ_iff_deriv.mp h1
  have hf'd : Differentiable ℝ (deriv f) := hf1.differentiable (by norm_num)
  have hf''c : Continuous (deriv (deriv f)) := hf1.continuous_deriv (by norm_num)
  rcases le_or_gt s F with hsF | hsF
  · have hint : ∀ a b : ℝ,
        IntervalIntegrable (fun k => deriv (deriv f) k * max (k - s) 0) volume a b :=
      fun a b => (hf''c.mul (by fun_prop)).intervalIntegrable a b
    have h2 : ∫ k in Set.Ioi F, deriv (deriv f) k * max (s - k) 0 = 0 := by
      apply setIntegral_eq_zero_of_forall_eq_zero
      intro k hk
      have hk' : F < k := hk
      rw [max_eq_right (by linarith)]
      simp
    have h3 : ∫ k in (0 : ℝ)..s, deriv (deriv f) k * max (k - s) 0 = 0 := by
      have : ∫ k in (0 : ℝ)..s, deriv (deriv f) k * max (k - s) 0
          = ∫ _ in (0 : ℝ)..s, (0 : ℝ) := by
        apply intervalIntegral.integral_congr
        intro k hk
        rw [Set.uIcc_of_le hs.le] at hk
        simp only
        rw [max_eq_right (by linarith [hk.2])]
        simp
      rw [this]
      simp
    have h4 : ∫ k in s..F, deriv (deriv f) k * max (k - s) 0
        = (deriv f F * (F - s) - f F) - (deriv f s * (s - s) - f s) := by
      have : ∫ k in s..F, deriv (deriv f) k * max (k - s) 0
          = ∫ k in s..F, deriv (deriv f) k * (k - s) := by
        apply intervalIntegral.integral_congr
        intro k hk
        rw [Set.uIcc_of_le hsF] at hk
        simp only
        rw [max_eq_left (by linarith [hk.1])]
      rw [this]
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt
        (f := fun k => deriv f k * (k - s) - f k)
      · intro k _
        have h : HasDerivAt (fun k => deriv f k * (k - s) - f k)
            (deriv (deriv f) k * (k - s) + deriv f k * 1 - deriv f k) k :=
          ((hf'd k).hasDerivAt.mul ((hasDerivAt_id k).sub_const s)).sub (hfd k).hasDerivAt
        convert h using 1
        ring
      · exact (hf''c.mul (by fun_prop)).intervalIntegrable _ _
    rw [h2, ← intervalIntegral.integral_add_adjacent_intervals (hint 0 s) (hint s F), h3, h4]
    ring
  · have h1' : ∫ k in (0 : ℝ)..F, deriv (deriv f) k * max (k - s) 0 = 0 := by
      have : ∫ k in (0 : ℝ)..F, deriv (deriv f) k * max (k - s) 0
          = ∫ _ in (0 : ℝ)..F, (0 : ℝ) := by
        apply intervalIntegral.integral_congr
        intro k hk
        rw [Set.uIcc_of_le hF.le] at hk
        simp only
        rw [max_eq_right (by linarith [hk.2])]
        simp
      rw [this]
      simp
    have h2 : ∫ k in Set.Ioi F, deriv (deriv f) k * max (s - k) 0
        = ∫ k in Set.Ioc F s, deriv (deriv f) k * max (s - k) 0 := by
      apply setIntegral_eq_of_subset_of_forall_sdiff_eq_zero measurableSet_Ioi
        Set.Ioc_subset_Ioi_self
      intro k hk
      have hks : s < k := by
        rcases hk with ⟨hk1, hk2⟩
        simp only [Set.mem_Ioc, not_and, not_le] at hk2
        exact hk2 hk1
      rw [max_eq_right (by linarith)]
      simp
    have h4 : ∫ k in F..s, deriv (deriv f) k * max (s - k) 0
        = (deriv f s * (s - s) + f s) - (deriv f F * (s - F) + f F) := by
      have : ∫ k in F..s, deriv (deriv f) k * max (s - k) 0
          = ∫ k in F..s, deriv (deriv f) k * (s - k) := by
        apply intervalIntegral.integral_congr
        intro k hk
        rw [Set.uIcc_of_le hsF.le] at hk
        simp only
        rw [max_eq_left (by linarith [hk.2])]
      rw [this]
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt
        (f := fun k => deriv f k * (s - k) + f k)
      · intro k _
        have h : HasDerivAt (fun k => deriv f k * (s - k) + f k)
            (deriv (deriv f) k * (s - k) + deriv f k * (-1) + deriv f k) k :=
          ((hf'd k).hasDerivAt.mul ((hasDerivAt_id k).const_sub s)).add (hfd k).hasDerivAt
        convert h using 1
        ring
      · exact (hf''c.mul (by fun_prop)).intervalIntegrable _ _
    rw [h2, ← intervalIntegral.integral_of_le hsF.le, h1', h4]
    ring

/-- The CMS rate is the forward plus a replicable adjustment: if the rate `S` has law `μ`
under the annuity measure with mean `F` (no drift), and `w` is the weight (payment bond over
annuity) with nonzero average, then
`E[S w(S)] / E[w(S)] = F + E[h(S)] / E[w(S)]` where `h(s) = (s - F)(w(s) - w(F))`. -/
theorem cms_rate_eq_forward_add_adjustment (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (w : ℝ → ℝ) (F : ℝ)
    (hS : Integrable (fun s : ℝ => s) μ) (hw : Integrable w μ)
    (hSw : Integrable (fun s => s * w s) μ)
    (hmean : ∫ s, s ∂μ = F) (hw0 : ∫ s, w s ∂μ ≠ 0) :
    (∫ s, s * w s ∂μ) / (∫ s, w s ∂μ)
      = F + (∫ s, (s - F) * (w s - w F) ∂μ) / (∫ s, w s ∂μ) := by
  have hexp : ∫ s, (s - F) * (w s - w F) ∂μ = ∫ s, s * w s ∂μ - F * ∫ s, w s ∂μ := by
    have e : (fun s => (s - F) * (w s - w F))
        = fun s => (s * w s - F * w s) - (w F * s - F * w F) := by
      funext s; ring
    rw [e, integral_sub (f := fun s => s * w s - F * w s) (g := fun s => w F * s - F * w F)
        (hSw.sub (hw.const_mul F)) ((hS.const_mul (w F)).sub (integrable_const _)),
      integral_sub (f := fun s => s * w s) (g := fun s => F * w s) hSw (hw.const_mul F),
      integral_sub (f := fun s => w F * s) (g := fun _ => F * w F)
        (hS.const_mul (w F)) (integrable_const _),
      integral_const_mul, integral_const_mul, hmean, integral_const]
    simp
    ring
  rw [hexp]
  field_simp
  ring

/-- The strip's weights: for `h(s) = (s - F)(w(s) - w(F))` with `w` twice continuously
differentiable, `h''(k) = 2 w'(k) + (k - F) w''(k)`. -/
theorem strip_weight_second_deriv (w : ℝ → ℝ) (hw : ContDiff ℝ 2 w) (F k : ℝ) :
    deriv (deriv (fun s => (s - F) * (w s - w F))) k
      = 2 * deriv w k + (k - F) * deriv (deriv w) k := by
  have h1 : ContDiff ℝ (1 + 1) w := by rw [one_add_one_eq_two]; exact hw
  obtain ⟨hwd, -, hw1⟩ := contDiff_succ_iff_deriv.mp h1
  have hw'd : Differentiable ℝ (deriv w) := hw1.differentiable (by norm_num)
  have hd : deriv (fun s => (s - F) * (w s - w F))
      = fun s => (w s - w F) + (s - F) * deriv w s := by
    funext s
    have : HasDerivAt (fun s => (s - F) * (w s - w F))
        (1 * (w s - w F) + (s - F) * deriv w s) s :=
      ((hasDerivAt_id s).sub_const F).mul ((hwd s).hasDerivAt.sub_const (w F))
    rw [this.deriv]
    ring
  rw [hd]
  have : HasDerivAt (fun s => w s - w F + (s - F) * deriv w s)
      (deriv w k + (1 * deriv w k + (k - F) * deriv (deriv w) k)) k :=
    ((hwd k).hasDerivAt.sub_const (w F)).add
      (((hasDerivAt_id k).sub_const F).mul (hw'd k).hasDerivAt)
  rw [this.deriv]
  ring

/- The card's check that the flat-curve weight agrees with today's curve: at a flat 4.5%
(= 9/200), `D(U)/A₀ = (1.045)^-6 / Σ_{i=6}^{15} (1.045)^-i` equals
`w(F) = (1.045)^-1 / Σ_{i=1}^{10} (1.045)^-i`. -/
example :
    ((1 + (9 / 200 : ℚ))⁻¹ ^ 6) / (∑ i ∈ Finset.range 10, (1 + (9 / 200 : ℚ))⁻¹ ^ (i + 6))
      = (1 + (9 / 200 : ℚ))⁻¹ / (∑ i ∈ Finset.range 10, (1 + (9 / 200 : ℚ))⁻¹ ^ (i + 1)) := by
  norm_num [Finset.sum_range_succ]

#print axioms static_replication_strip
#print axioms cms_rate_eq_forward_add_adjustment
#print axioms strip_weight_second_deriv
