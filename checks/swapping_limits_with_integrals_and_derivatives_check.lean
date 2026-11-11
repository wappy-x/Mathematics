-- Swapping limits: on a closed, bounded interval a uniform limit of integrable functions is integrable with integral equal to the limit of the integrals (the areas missing by at most width times worst gap), and when the slopes converge uniformly and one height settles, the functions converge uniformly to a limit whose slope is the limit of the slopes.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Topology.UniformSpace.UniformApproximation

open Filter Topology MeasureTheory Finset


/-- Helper: integral gap bound (same as the bound theorem, placed first for reuse). -/
theorem swl_gap_aux {a b E : ℝ} (hab : a ≤ b) (g h : ℝ → ℝ)
    (hg : IntervalIntegrable g volume a b) (hh : IntervalIntegrable h volume a b)
    (h_gap : ∀ x ∈ Set.Icc a b, |g x - h x| ≤ E) :
    |(∫ x in a..b, g x) - ∫ x in a..b, h x| ≤ (b - a) * E := by
  rw [← intervalIntegral.integral_sub hg hh]
  have := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := b) (C := E)
    (f := fun x => g x - h x) (by
      intro x hx
      rw [Set.uIoc_of_le hab] at hx
      exact h_gap x ⟨hx.1.le, hx.2⟩)
  rw [Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.mpr hab)] at this
  linarith

/-- Helper: the fundamental theorem of calculus between two points of the interval. -/
theorem swl_ftc_aux {a b u v : ℝ} (hu : u ∈ Set.Icc a b) (hv : v ∈ Set.Icc a b)
    (F F' : ℝ → ℝ)
    (h_deriv : ∀ x ∈ Set.Icc a b, HasDerivWithinAt F (F' x) (Set.Icc a b) x)
    (h_cont : ContinuousOn F' (Set.Icc a b)) :
    ∫ x in u..v, F' x = F v - F u := by
  have hsub : Set.uIcc u v ⊆ Set.Icc a b := Set.uIcc_subset_Icc hu hv
  apply intervalIntegral.integral_eq_sub_of_hasDeriv_right
  · intro x hx
    exact (h_deriv x (hsub hx)).continuousWithinAt.mono hsub
  · intro x hx
    have hxI : x ∈ Set.Ioo a b := by
      constructor
      · exact lt_of_le_of_lt (le_min hu.1 hv.1) hx.1
      · exact lt_of_lt_of_le hx.2 (max_le hu.2 hv.2)
    exact ((h_deriv x (Set.Ioo_subset_Icc_self hxI)).hasDerivAt
      (Icc_mem_nhds hxI.1 hxI.2)).hasDerivWithinAt
  · exact (h_cont.mono hsub).intervalIntegrable

/-- The integration theorem. On a closed, bounded interval from a to b, let every stage F n be
integrable, and let F n close in on f uniformly: the worst gap sup |F n x − f x| over the
interval shrinks to 0. Then the limit f is integrable too, and the integral of the limit is the
limit of the integrals: ∫ F n over [a, b] heads for ∫ f over [a, b]. -/
theorem integral_of_uniform_limit_eq_limit_of_integrals {a b : ℝ} (hab : a ≤ b)
    (F : ℕ → ℝ → ℝ) (f : ℝ → ℝ)
    (h_int : ∀ n, IntervalIntegrable (F n) volume a b)
    (h_unif : TendstoUniformlyOn F f atTop (Set.Icc a b)) :
    IntervalIntegrable f volume a b ∧
      Tendsto (fun n => ∫ x in a..b, F n x) atTop (𝓝 (∫ x in a..b, f x)) := by
  have hIoc : ∀ n, IntegrableOn (F n) (Set.Ioc a b) volume := fun n =>
    (intervalIntegrable_iff_integrableOn_Ioc_of_le hab).1 (h_int n)
  have hmeas : AEStronglyMeasurable f (volume.restrict (Set.Ioc a b)) := by
    refine aestronglyMeasurable_of_tendsto_ae atTop (fun n => (hIoc n).aestronglyMeasurable) ?_
    refine ae_restrict_of_forall_mem measurableSet_Ioc ?_
    intro x hx
    exact h_unif.tendsto_at ⟨hx.1.le, hx.2⟩
  obtain ⟨N, hN⟩ := (Metric.tendstoUniformlyOn_iff.1 h_unif 1 one_pos).exists_forall_of_atTop
  have hfint : IntervalIntegrable f volume a b := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hab]
    have hbound : IntegrableOn (fun x => ‖F N x‖ + 1) (Set.Ioc a b) volume :=
      (hIoc N).norm.add (integrableOn_const (by simp))
    refine Integrable.mono' hbound hmeas ?_
    refine ae_restrict_of_forall_mem measurableSet_Ioc ?_
    intro x hx
    have h1 := hN N le_rfl x ⟨hx.1.le, hx.2⟩
    rw [Real.dist_eq] at h1
    rw [Real.norm_eq_abs, Real.norm_eq_abs]
    have := abs_sub_abs_le_abs_sub (f x) (F N x)
    linarith
  refine ⟨hfint, ?_⟩
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hw : 0 < b - a + 1 := by linarith
  obtain ⟨M, hM⟩ := (Metric.tendstoUniformlyOn_iff.1 h_unif (ε / (b - a + 1))
    (div_pos hε hw)).exists_forall_of_atTop
  refine ⟨M, fun n hn => ?_⟩
  rw [Real.dist_eq]
  have := swl_gap_aux hab (F n) f (h_int n) hfint (E := ε / (b - a + 1)) (by
    intro x hx
    have := hM n hn x hx
    rw [Real.dist_eq, abs_sub_comm] at this
    exact this.le)
  have hlt : (b - a) * (ε / (b - a + 1)) < ε := by
    rw [mul_div_assoc', div_lt_iff₀ hw]
    nlinarith
  linarith

/-- The bound on the areas. If two integrable functions g and h on the closed interval from a
to b never differ by more than E, then their integrals differ by at most width times that gap:
|∫ g − ∫ h| ≤ (b − a) E. (With g = F n, h = f and E the worst gap E_n, this is the card's
bound |∫ F n − ∫ f| ≤ (b − a) E_n.) -/
theorem integral_gap_le_width_mul_worst_gap {a b E : ℝ} (hab : a ≤ b) (g h : ℝ → ℝ)
    (hg : IntervalIntegrable g volume a b) (hh : IntervalIntegrable h volume a b)
    (h_gap : ∀ x ∈ Set.Icc a b, |g x - h x| ≤ E) :
    |(∫ x in a..b, g x) - ∫ x in a..b, h x| ≤ (b - a) * E := by
  exact swl_gap_aux hab g h hg hh h_gap

/-- The differentiation theorem. On a closed, bounded interval from a to b, let every stage F n
have a continuous derivative F' n (one-sided at the ends), let the derivatives close in
uniformly on a function g, and at one point x₀ of the interval let the heights F n x₀ head for a
number c. Then the F n close in uniformly on f(x) = c + ∫ g from x₀ to x, and f has slope
f'(x) = g(x) = lim F' n x at every point of the interval. -/
theorem uniform_limit_of_slopes_is_slope_of_limit {a b x₀ c : ℝ} (hab : a ≤ b)
    (F F' : ℕ → ℝ → ℝ) (g : ℝ → ℝ)
    (h_deriv : ∀ n, ∀ x ∈ Set.Icc a b, HasDerivWithinAt (F n) (F' n x) (Set.Icc a b) x)
    (h_cont : ∀ n, ContinuousOn (F' n) (Set.Icc a b))
    (h_unif : TendstoUniformlyOn F' g atTop (Set.Icc a b))
    (hx₀ : x₀ ∈ Set.Icc a b)
    (h_anchor : Tendsto (fun n => F n x₀) atTop (𝓝 c)) :
    TendstoUniformlyOn F (fun x => c + ∫ s in x₀..x, g s) atTop (Set.Icc a b) ∧
      ∀ x ∈ Set.Icc a b,
        HasDerivWithinAt (fun y => c + ∫ s in x₀..y, g s) (g x) (Set.Icc a b) x := by
  have hgc : ContinuousOn g (Set.Icc a b) :=
    h_unif.continuousOn (Frequently.of_forall h_cont)
  have hFeq : ∀ n, ∀ x ∈ Set.Icc a b, F n x = F n x₀ + ∫ s in x₀..x, F' n s := by
    intro n x hx
    rw [swl_ftc_aux hx₀ hx (F n) (F' n) (h_deriv n) (h_cont n)]
    ring
  have hgint : ∀ x ∈ Set.Icc a b, IntervalIntegrable g volume x₀ x := fun x hx =>
    (hgc.mono (Set.uIcc_subset_Icc hx₀ hx)).intervalIntegrable
  refine ⟨?_, ?_⟩
  · rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    have hw : 0 < b - a + 1 := by linarith
    have h1 := (Metric.tendstoUniformlyOn_iff.1 h_unif (ε / 2 / (b - a + 1))
      (div_pos (half_pos hε) hw))
    have h2 := (Metric.tendsto_nhds.1 h_anchor) (ε / 2) (half_pos hε)
    filter_upwards [h1, h2] with n hn1 hn2
    intro x hx
    rw [Real.dist_eq, hFeq n x hx]
    rw [Real.dist_eq] at hn2
    have hsub : Set.uIcc x₀ x ⊆ Set.Icc a b := Set.uIcc_subset_Icc hx₀ hx
    have hFint : IntervalIntegrable (F' n) volume x₀ x :=
      ((h_cont n).mono hsub).intervalIntegrable
    have hgap : |(∫ s in x₀..x, g s) - ∫ s in x₀..x, F' n s| ≤ (b - a) * (ε / 2 / (b - a + 1)) := by
      rw [← intervalIntegral.integral_sub (hgint x hx) hFint]
      have := intervalIntegral.norm_integral_le_of_norm_le_const (a := x₀) (b := x)
        (C := ε / 2 / (b - a + 1)) (f := fun s => g s - F' n s) (by
          intro s hs
          have := hn1 s (hsub (Set.uIoc_subset_uIcc hs))
          rw [Real.dist_eq] at this
          rw [Real.norm_eq_abs]
          exact this.le)
      rw [Real.norm_eq_abs] at this
      have hxx : |x - x₀| ≤ b - a := by
        rw [abs_le]; constructor <;> linarith [hx.1, hx.2, hx₀.1, hx₀.2]
      have hC : 0 ≤ ε / 2 / (b - a + 1) := by positivity
      calc _ ≤ ε / 2 / (b - a + 1) * |x - x₀| := this
        _ ≤ ε / 2 / (b - a + 1) * (b - a) := mul_le_mul_of_nonneg_left hxx hC
        _ = _ := by ring
    have hlt : (b - a) * (ε / 2 / (b - a + 1)) < ε / 2 := by
      rw [mul_div_assoc', div_lt_iff₀ hw]
      nlinarith
    have e : c + (∫ s in x₀..x, g s) - (F n x₀ + ∫ s in x₀..x, F' n s)
        = (c - F n x₀) + ((∫ s in x₀..x, g s) - ∫ s in x₀..x, F' n s) := by ring
    rw [e]
    calc _ ≤ |c - F n x₀| + |(∫ s in x₀..x, g s) - ∫ s in x₀..x, F' n s| := abs_add_le _ _
      _ < ε := by rw [abs_sub_comm]; linarith
  · intro x hx
    set G : ℝ → ℝ := fun y => g (Set.projIcc a b hab y) with hGdef
    have hGc : Continuous G :=
      hgc.comp_continuous (continuous_subtype_val.comp continuous_projIcc)
        (fun y => (Set.projIcc a b hab y).2)
    have hGeq : ∀ y ∈ Set.Icc a b, G y = g y := by
      intro y hy
      simp [hGdef, Set.projIcc_of_mem hab hy]
    have hD : HasDerivAt (fun y => c + ∫ s in x₀..y, G s) (G x) x :=
      (intervalIntegral.integral_hasDerivAt_right (hGc.intervalIntegrable _ _)
        (hGc.stronglyMeasurableAtFilter _ _) hGc.continuousAt).const_add c
    rw [← hGeq x hx]
    have hcongr : ∀ y ∈ Set.Icc a b, (fun y => c + ∫ s in x₀..y, g s) y
        = (fun y => c + ∫ s in x₀..y, G s) y := by
      intro y hy
      simp only
      congr 1
      refine intervalIntegral.integral_congr ?_
      intro s hs
      exact (hGeq s (Set.uIcc_subset_Icc hx₀ hy hs)).symm
    exact hD.hasDerivWithinAt.congr hcongr (hcongr x hx)

/-! The card's exact worked numbers. -/

-- The tent at stage n is max 0 (2n − |4n²x − 2n|): base from 0 to 1/n, peak 2n at 1/(2n).
-- Its area at stage 1000 is ½ × (1/1000) × 2000 = 1.
example : (1 / 2 : ℚ) * (1 / 1000) * 2000 = 1 := by
  norm_num

-- The chart: peak 2 at 1/2 (stage 1), peak 4 at 1/4 (stage 2), peak 8 at 1/8 (stage 4).
example : (List.map (fun p : ℚ × ℚ => max 0 (2 * p.1 - |4 * p.1 ^ 2 * p.2 - 2 * p.1|))
    [(1, 1 / 2), (2, 1 / 4), (4, 1 / 8)]) = [2, 4, 8] := by
  norm_num [abs_of_nonneg, abs_of_nonpos]

-- Height at the point 1/100 at stages 1, 10, 50, 1000: 1/25 (the card's 0.04), 4, 100, 0.
example : (List.map (fun n : ℚ => max 0 (2 * n - |4 * n ^ 2 * (1 / 100) - 2 * n|))
    [1, 10, 50, 1000]) = [1 / 25, 4, 100, 0] := by
  norm_num [abs_of_nonneg, abs_of_nonpos]

-- The series' worst gap at x = 1 after ten terms: 1/(2 − 1) − (1/2 + ⋯ + 1/2^10) = 1/2^10
-- (the card's 0.000976562).
example : (1 : ℚ) / (2 - 1) - ∑ k ∈ Icc (1 : ℕ) 10, (1 / 2 : ℚ) ^ k = 1 / 2 ^ 10 := by
  norm_num [Finset.sum_Icc_succ_top]

-- The first ten terms integrated, 1/4 + 1/12 + 1/32 + ⋯ + 1/(11 × 2^10), is exactly
-- 274073/709632 (the card's 0.386218491).
example : ∑ k ∈ Icc (1 : ℕ) 10, (1 : ℚ) / ((k + 1) * 2 ^ k) = 274073 / 709632 := by
  norm_num [Finset.sum_Icc_succ_top]

-- The caps on the slope terms, k/2^k added to k = 60: 2 − 62/2^60 (the card's 2.000000).
example : ∑ k ∈ Icc (1 : ℕ) 60, (k : ℚ) / 2 ^ k = 2 - 62 / 2 ^ 60 := by
  norm_num [Finset.sum_Icc_succ_top]

-- The slope of S at 1/2 from the formula 2/(2 − x)²: 8/9 (the card's 0.888889).
example : (2 : ℚ) / (2 - 1 / 2) ^ 2 = 8 / 9 := by
  norm_num

-- Blocks 1/n high on 0 to n: width times worst gap is 1 at stages 10 and 1000.
example : (10 : ℚ) * (1 / 10) = 1 ∧ (1000 : ℚ) * (1 / 1000) = 1 := by
  norm_num

#print axioms swl_gap_aux
#print axioms swl_ftc_aux
#print axioms integral_of_uniform_limit_eq_limit_of_integrals
#print axioms integral_gap_le_width_mul_worst_gap
#print axioms uniform_limit_of_slopes_is_slope_of_limit
