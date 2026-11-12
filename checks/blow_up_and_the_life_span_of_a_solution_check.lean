-- Blow-up: the equation y' = k y^2 with k > 0 and y(0) = y0 > 0 has the unique forward solution y0/(1 - k y0 t), which goes to infinity at T = 1/(k y0) so no solution reaches T, the doubling times add up to exactly T, and a linear equation y' = a(t) y + b(t) with continuous a and b has a solution for all time.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Tactic.NormNum

open Filter Topology Set

/-- Blow-up of the square rate law. Take k > 0 and a start y0 > 0, and let T = 1/(k y0).
The function y0/(1 - k y0 t) solves y' = k y^2 at every time before T and starts at y0;
it grows without bound as t rises to T; every solution of y' = k y^2 with y(0) = y0 on
0 ≤ t < T equals it there (uniqueness); and so no solution with y(0) = y0 lasts on the
closed interval 0 ≤ t ≤ T: the life span ends at the finite time T. -/
theorem square_rate_blows_up_in_finite_time {k y₀ : ℝ} (hk : 0 < k) (hy₀ : 0 < y₀) :
    (∀ t < 1 / (k * y₀),
        HasDerivAt (fun s => y₀ / (1 - k * y₀ * s)) (k * (y₀ / (1 - k * y₀ * t)) ^ 2) t) ∧
    y₀ / (1 - k * y₀ * 0) = y₀ ∧
    Tendsto (fun t => y₀ / (1 - k * y₀ * t)) (𝓝[<] (1 / (k * y₀))) atTop ∧
    (∀ y : ℝ → ℝ, y 0 = y₀ →
        (∀ t ∈ Ico 0 (1 / (k * y₀)), HasDerivAt y (k * y t ^ 2) t) →
        ∀ t ∈ Ico 0 (1 / (k * y₀)), y t = y₀ / (1 - k * y₀ * t)) ∧
    ¬ ∃ y : ℝ → ℝ, y 0 = y₀ ∧ ∀ t ∈ Icc 0 (1 / (k * y₀)), HasDerivAt y (k * y t ^ 2) t := by
  have hky : 0 < k * y₀ := mul_pos hk hy₀
  have hden : ∀ t < 1 / (k * y₀), 0 < 1 - k * y₀ * t := by
    intro t ht
    rw [lt_div_iff₀ hky] at ht
    linarith
  have hD : ∀ t < 1 / (k * y₀),
      HasDerivAt (fun s => y₀ / (1 - k * y₀ * s)) (k * (y₀ / (1 - k * y₀ * t)) ^ 2) t := by
    intro t ht
    have h0 := (hden t ht).ne'
    have h1 : HasDerivAt (fun s => 1 - k * y₀ * s) (-(k * y₀)) t := by
      simpa using ((hasDerivAt_id t).const_mul (k * y₀)).const_sub 1
    convert (hasDerivAt_const t y₀).div h1 h0 using 1
    field_simp
    ring
  have hT : Tendsto (fun t => y₀ / (1 - k * y₀ * t)) (𝓝[<] (1 / (k * y₀))) atTop := by
    have h1 : Tendsto (fun t => 1 - k * y₀ * t) (𝓝[<] (1 / (k * y₀))) (𝓝[>] 0) := by
      apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
      · have : Tendsto (fun t => 1 - k * y₀ * t) (𝓝 (1 / (k * y₀))) (𝓝 (1 - k * y₀ * (1 / (k * y₀)))) :=
          ((continuous_const.sub (continuous_const.mul continuous_id)).tendsto _)
        rw [mul_one_div_cancel hky.ne', sub_self] at this
        exact this.mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with t ht
        exact hden t ht
    have h2 := (tendsto_inv_nhdsGT_zero.comp h1).const_mul_atTop hy₀
    refine h2.congr' (Eventually.of_forall fun t => ?_)
    simp [div_eq_mul_inv]
  have hU : ∀ y : ℝ → ℝ, y 0 = y₀ →
      (∀ t ∈ Ico 0 (1 / (k * y₀)), HasDerivAt y (k * y t ^ 2) t) →
      ∀ t ∈ Ico 0 (1 / (k * y₀)), y t = y₀ / (1 - k * y₀ * t) := by
    intro y hy0 hy t ht
    have hcont : ContinuousOn y (Ico 0 (1 / (k * y₀))) :=
      fun s hs => (hy s hs).continuousAt.continuousWithinAt
    have hmono : MonotoneOn y (Ico 0 (1 / (k * y₀))) := by
      apply monotoneOn_of_hasDerivWithinAt_nonneg (convex_Ico _ _) hcont
        (f' := fun s => k * y s ^ 2)
      · intro s hs
        exact (hy s (interior_subset hs)).hasDerivWithinAt
      · intro s _
        positivity
    have hpos : ∀ s ∈ Ico 0 (1 / (k * y₀)), y₀ ≤ y s := by
      intro s hs
      rw [← hy0]
      exact hmono ⟨le_refl 0, lt_of_le_of_lt hs.1 hs.2⟩ hs hs.1
    have hgd : ∀ s ∈ Icc 0 t, HasDerivAt (fun s => 1 / y s + k * s) 0 s := by
      intro s hs
      have hs' : s ∈ Ico 0 (1 / (k * y₀)) := ⟨hs.1, lt_of_le_of_lt hs.2 ht.2⟩
      have hne : y s ≠ 0 := (lt_of_lt_of_le hy₀ (hpos s hs')).ne'
      have h1 := ((hy s hs').inv hne).add ((hasDerivAt_id' s).const_mul k)
      convert h1 using 1
      · ext x; simp [one_div]
      · field_simp; ring
    have hg : ∀ s ∈ Icc 0 t, (fun s => 1 / y s + k * s) s = (fun s => 1 / y s + k * s) 0 := by
      apply constant_of_has_deriv_right_zero
      · intro s hs
        exact (hgd s hs).continuousAt.continuousWithinAt
      · intro s hs
        exact (hgd s (Ico_subset_Icc_self hs)).hasDerivWithinAt
    have := hg t ⟨ht.1, le_refl t⟩
    simp only [hy0, mul_zero, add_zero] at this
    have hne : y t ≠ 0 := (lt_of_lt_of_le hy₀ (hpos t ht)).ne'
    have hd := (hden t ht.2).ne'
    rw [eq_div_iff hd]
    field_simp at this
    linear_combination (-1 : ℝ) * this
  refine ⟨hD, by simp, hT, hU, ?_⟩
  rintro ⟨y, hy0, hy⟩
  have hU' := hU y hy0 (fun t ht => hy t (Ico_subset_Icc_self ht))
  have hc : Tendsto y (𝓝[<] (1 / (k * y₀))) (𝓝 (y (1 / (k * y₀)))) :=
    (hy _ ⟨(by positivity), le_refl _⟩).continuousAt.tendsto.mono_left nhdsWithin_le_nhds
  have hT' : Tendsto y (𝓝[<] (1 / (k * y₀))) atTop := by
    refine hT.congr' ?_
    filter_upwards [Ioo_mem_nhdsLT (show (0:ℝ) < 1 / (k * y₀) by positivity)] with t ht
    exact (hU' t ⟨ht.1.le, ht.2⟩).symm
  exact not_tendsto_atTop_of_tendsto_nhds hc hT'

/-- The doubling times add to the blow-up time. For y' = k y^2 with k > 0 and y0 > 0,
growing from Y to 2Y takes the time ∫ from Y to 2Y of du/(k u^2); the doublings
y0 → 2y0 → 4y0 → … take these times in turn, and their infinite sum is exactly 1/(k y0). -/
theorem square_rate_doubling_times_sum {k y₀ : ℝ} (hk : 0 < k) (hy₀ : 0 < y₀) :
    HasSum (fun j : ℕ => ∫ u in y₀ * 2 ^ j..y₀ * 2 ^ (j + 1), 1 / (k * u ^ 2)) (1 / (k * y₀)) := by
  have hterm : ∀ j : ℕ, ∫ u in y₀ * 2 ^ j..y₀ * 2 ^ (j + 1), 1 / (k * u ^ 2)
      = 1 / (2 * k * y₀) * (1 / 2) ^ j := by
    intro j
    have hY : 0 < y₀ * 2 ^ j := by positivity
    have hle : y₀ * 2 ^ j ≤ y₀ * 2 ^ (j + 1) := by
      rw [pow_succ]; nlinarith
    have hpos : ∀ x ∈ uIcc (y₀ * 2 ^ j) (y₀ * 2 ^ (j + 1)), 0 < x := by
      intro x hx
      rw [uIcc_of_le hle] at hx
      exact lt_of_lt_of_le hY hx.1
    have hderiv : ∀ x ∈ uIcc (y₀ * 2 ^ j) (y₀ * 2 ^ (j + 1)),
        HasDerivAt (fun u => -(1 / (k * u))) (1 / (k * x ^ 2)) x := by
      intro x hx
      have hx0 := (hpos x hx).ne'
      have h1 : HasDerivAt (fun u => k * u) k x := by
        simpa using (hasDerivAt_id x).const_mul k
      convert ((hasDerivAt_const x (1:ℝ)).div h1 (mul_ne_zero hk.ne' hx0)).neg using 1
      field_simp
      ring
    have hint : IntervalIntegrable (fun u => 1 / (k * u ^ 2)) MeasureTheory.volume
        (y₀ * 2 ^ j) (y₀ * 2 ^ (j + 1)) := by
      apply ContinuousOn.intervalIntegrable
      intro x hx
      have hx0 := (hpos x hx).ne'
      apply ContinuousAt.continuousWithinAt
      apply ContinuousAt.div continuousAt_const (by fun_prop)
      positivity
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
    rw [pow_succ]
    field_simp
    rw [← mul_pow]
    norm_num
  have h := hasSum_geometric_two.mul_left (1 / (2 * k * y₀))
  convert h using 1
  · ext j; exact hterm j
  · field_simp

/-- Linear equations never blow up. If a and b are continuous for all time, then for every
start y0 the linear equation y' = a(t) y + b(t) has a solution with y(0) = y0 that exists
for every real time t. -/
theorem linear_equation_solution_exists_for_all_time (a b : ℝ → ℝ)
    (ha : Continuous a) (hb : Continuous b) (y₀ : ℝ) :
    ∃ y : ℝ → ℝ, y 0 = y₀ ∧ ∀ t : ℝ, HasDerivAt y (a t * y t + b t) t := by
  set A : ℝ → ℝ := fun t => ∫ s in (0:ℝ)..t, a s with hA
  have hAd : ∀ t, HasDerivAt A (a t) t := fun t => (ha.integral_hasStrictDerivAt 0 t).hasDerivAt
  have hAc : Continuous A := continuous_iff_continuousAt.2 fun t => (hAd t).continuousAt
  set g : ℝ → ℝ := fun s => Real.exp (-A s) * b s with hg
  have hgc : Continuous g := (Real.continuous_exp.comp hAc.neg).mul hb
  set B : ℝ → ℝ := fun t => ∫ s in (0:ℝ)..t, g s with hB
  have hBd : ∀ t, HasDerivAt B (g t) t := fun t => (hgc.integral_hasStrictDerivAt 0 t).hasDerivAt
  refine ⟨fun t => Real.exp (A t) * (y₀ + B t), ?_, ?_⟩
  · simp [hA, hB]
  · intro t
    have h1 := ((hAd t).exp).mul ((hasDerivAt_const t y₀).add (hBd t))
    convert h1 using 1
    simp only [hg, Real.exp_neg, Pi.add_apply]
    field_simp
    ring

-- The card's worked numbers for the scheme y' = (1/100) y^2, y(0) = 10.
-- Starting rate: 0.01 × 10^2 = 1 member a month.
example : (1 / 100 : ℝ) * 10 ^ 2 = 1 := by norm_num
-- Blow-up time 1/(k y0) = 10 months.
example : (1 : ℝ) / ((1 / 100) * 10) = 10 := by norm_num
-- y = 10/(1 - (1/100)·10·t): 20 members at month 5, 100 at month 9, 200 at month 9.5.
example : (10 : ℝ) / (1 - (1 / 100) * 10 * 5) = 20 := by norm_num
example : (10 : ℝ) / (1 - (1 / 100) * 10 * 9) = 100 := by norm_num
example : (10 : ℝ) / (1 - (1 / 100) * 10 * (19 / 2)) = 200 := by norm_num
-- The formula read past blow-up, at month 12, gives -50.
example : (10 : ℝ) / (1 - (1 / 100) * 10 * 12) = -50 := by norm_num
-- First doubling time 1/(2 k Y) = 5 months, and 5 × 2 = 10 months in all.
example : (1 : ℝ) / (2 * (1 / 100) * 10) = 5 := by norm_num
example : (5 : ℝ) * 2 = 10 := by norm_num
-- Life spans 1/(k y0) for y0 = 5, 20, 100: 20, 5 and 1 months.
example : (1 : ℝ) / ((1 / 100) * 5) = 20 := by norm_num
example : (1 : ℝ) / ((1 / 100) * 20) = 5 := by norm_num
example : (1 : ℝ) / ((1 / 100) * 100) = 1 := by norm_num
-- Leaking bucket h = (5 - t/10)^2 starts at 25 and is empty at t = 50.
example : ((5 : ℝ) - 0 / 10) ^ 2 = 25 := by norm_num
example : ((5 : ℝ) - 50 / 10) ^ 2 = 0 := by norm_num

#print axioms square_rate_blows_up_in_finite_time
#print axioms square_rate_doubling_times_sum
#print axioms linear_equation_solution_exists_for_all_time
