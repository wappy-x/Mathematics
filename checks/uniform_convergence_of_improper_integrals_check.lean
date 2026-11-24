-- Improper integrals with a dial: a cap with finite area makes an improper integral with a parameter converge uniformly (the Weierstrass M-test), and then continuity and derivatives pass inside the infinite range.
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Interval.Set.OrdConnected
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set Filter Topology MeasureTheory

/-- Helper: the total from a to B depends continuously on the parameter. -/
theorem uc_continuousOn_intervalIntegral {f : ℝ → ℝ → ℝ} {a B : ℝ} {T : Set ℝ}
    (hf : ContinuousOn (Function.uncurry f) (T ×ˢ Ici a)) (hB : a ≤ B) :
    ContinuousOn (fun t => ∫ x in a..B, f t x) T := by
  rw [continuousOn_iff_continuous_domRestrict]
  have hg : Continuous (Function.uncurry (fun (t : T) (x : ℝ) => f t.1 (max a x))) := by
    have hc : Continuous (fun p : T × ℝ => ((p.1 : ℝ), max a p.2)) := by fun_prop
    exact hf.comp_continuous hc (fun p => ⟨p.1.2, show a ≤ max a p.2 from le_max_left _ _⟩)
  have h := intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
    (μ := volume) hg a B
  refine h.congr (fun t => ?_)
  simp only [Set.domRestrict_apply]
  refine intervalIntegral.integral_congr (fun x hx => ?_)
  rw [uIcc_of_le hB] at hx
  simp [max_eq_right hx.1]

/-- Helper: at a point inside T, the total from a to B can be differentiated under the
integral sign. -/
theorem uc_hasDerivAt_intervalIntegral {f f' : ℝ → ℝ → ℝ} {a B u : ℝ} {T : Set ℝ}
    (hf : ContinuousOn (Function.uncurry f) (T ×ˢ Ici a))
    (hf' : ContinuousOn (Function.uncurry f') (T ×ˢ Ici a))
    (hderiv : ∀ x, a ≤ x → ∀ t ∈ T, HasDerivWithinAt (fun s => f s x) (f' t x) T t)
    (hB : a ≤ B) (hu : T ∈ 𝓝 u) :
    HasDerivAt (fun t => ∫ x in a..B, f t x) (∫ x in a..B, f' u x) u := by
  obtain ⟨ε, hε, hball⟩ := Metric.mem_nhds_iff.1 hu
  have hcb : Metric.closedBall u (ε / 2) ⊆ T :=
    (Metric.closedBall_subset_ball (by linarith)).trans hball
  have hK : IsCompact (Metric.closedBall u (ε / 2) ×ˢ Icc a B) :=
    (isCompact_closedBall u _).prod isCompact_Icc
  obtain ⟨C, hC⟩ := hK.exists_bound_of_continuousOn
    (hf'.mono (prod_mono hcb Icc_subset_Ici_self))
  have hIoc : Set.uIoc a B = Ioc a B := uIoc_of_le hB
  have hcont : ∀ {g : ℝ → ℝ → ℝ}, ContinuousOn (Function.uncurry g) (T ×ˢ Ici a) →
      ∀ t ∈ T, ContinuousOn (g t) (Icc a B) := by
    intro g hg t ht
    exact hg.comp (by fun_prop : Continuous fun x : ℝ => (t, x)).continuousOn
      (fun x hx => ⟨ht, hx.1⟩)
  have hu' : u ∈ T := mem_of_mem_nhds hu
  have key := intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
    (μ := volume) (F := f) (F' := f') (x₀ := u) (bound := fun _ => C) (a := a) (b := B)
    (Metric.ball_mem_nhds u (half_pos hε)) ?_ ?_ ?_ ?_ intervalIntegrable_const ?_
  · exact key.2
  · filter_upwards [hu] with t ht
    rw [hIoc]
    exact ((hcont hf t ht).mono Ioc_subset_Icc_self).aestronglyMeasurable measurableSet_Ioc
  · exact (hcont hf u hu').intervalIntegrable_of_Icc hB
  · rw [hIoc]
    exact ((hcont hf' u hu').mono Ioc_subset_Icc_self).aestronglyMeasurable measurableSet_Ioc
  · refine Eventually.of_forall fun x hx t ht => ?_
    rw [hIoc] at hx
    exact hC (t, x) ⟨Metric.ball_subset_closedBall ht, Ioc_subset_Icc_self hx⟩
  · refine Eventually.of_forall fun x hx t ht => ?_
    rw [hIoc] at hx
    have ht' : t ∈ Metric.ball u ε := Metric.ball_subset_ball (by linarith) ht
    exact (hderiv x hx.1.le t (hball ht')).hasDerivAt
      (mem_of_superset (Metric.isOpen_ball.mem_nhds ht') hball)

/-- **The Weierstrass M-test for integrals.** Let f(t, x) depend on a parameter t in a set T
and a position x ≥ a, continuous in x on every finite piece for each allowed t. Suppose a cap
M(x), with no t in it, has finite area from a to infinity and sits above |f(t, x)| for every
t in T and every x ≥ a. Then every integral of f(t, ·) from a to infinity converges; the tail
beyond any cut-off B is at most the cap's tail beyond B; the worst tail over all t in T
shrinks to 0 as B grows (uniform convergence); and so the totals up to B close in on the
full totals uniformly in t. -/
theorem weierstrass_m_test_improper_integral
    {f : ℝ → ℝ → ℝ} {M : ℝ → ℝ} {a : ℝ} {T : Set ℝ}
    (hf : ∀ t ∈ T, ContinuousOn (f t) (Ici a))
    (hM : IntegrableOn M (Ioi a))
    (hcap : ∀ t ∈ T, ∀ x, a ≤ x → |f t x| ≤ M x) :
    (∀ t ∈ T, IntegrableOn (f t) (Ioi a)) ∧
    (∀ t ∈ T, ∀ B, a ≤ B → |∫ x in Ioi B, f t x| ≤ ∫ x in Ioi B, M x) ∧
    TendstoUniformlyOn (fun B t => ∫ x in Ioi B, f t x) (fun _ => 0) atTop T ∧
    TendstoUniformlyOn (fun B t => ∫ x in a..B, f t x) (fun t => ∫ x in Ioi a, f t x)
      atTop T := by
  have hint : ∀ t ∈ T, IntegrableOn (f t) (Ioi a) := fun t ht =>
    hM.mono' (((hf t ht).mono Ioi_subset_Ici_self).aestronglyMeasurable measurableSet_Ioi)
      (ae_restrict_of_forall_mem measurableSet_Ioi fun x hx => by
        rw [Real.norm_eq_abs]; exact hcap t ht x (le_of_lt hx))
  have htail : ∀ t ∈ T, ∀ B, a ≤ B → |∫ x in Ioi B, f t x| ≤ ∫ x in Ioi B, M x := by
    intro t ht B hB
    rw [← Real.norm_eq_abs]
    exact norm_integral_le_of_norm_le (hM.mono_set (Ioi_subset_Ioi hB))
      (ae_restrict_of_forall_mem measurableSet_Ioi fun x hx => by
        rw [Real.norm_eq_abs]; exact hcap t ht x (hB.trans (le_of_lt hx)))
  have hMtail : Tendsto (fun B => ∫ x in Ioi B, M x) atTop (𝓝 0) := by
    have h := tendsto_setIntegral_of_antitone (μ := volume) (f := M) (s := fun B : ℝ => Ioi B)
      (fun B => measurableSet_Ioi) (fun B C hBC => Ioi_subset_Ioi hBC) ⟨a, hM⟩
    have he : (⋂ n : ℝ, Ioi n) = ∅ := by
      ext x
      simp only [mem_iInter, mem_Ioi, mem_empty_iff_false, iff_false, not_forall, not_lt]
      exact ⟨x, le_rfl⟩
    rwa [he, Measure.restrict_empty, integral_zero_measure] at h
  have hsplit : ∀ t ∈ T, ∀ B, a ≤ B →
      ∫ x in Ioi a, f t x = (∫ x in a..B, f t x) + ∫ x in Ioi B, f t x := by
    intro t ht B hB
    rw [intervalIntegral.integral_of_le hB, ← setIntegral_union (Ioc_disjoint_Ioi le_rfl)
      measurableSet_Ioi ((hint t ht).mono_set Ioc_subset_Ioi_self)
      ((hint t ht).mono_set (Ioi_subset_Ioi hB)), Ioc_union_Ioi_eq_Ioi hB]
  refine ⟨hint, htail, ?_, ?_⟩
  · rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    filter_upwards [hMtail.eventually (gt_mem_nhds hε), eventually_ge_atTop a] with B hB hBa t ht
    rw [Real.dist_eq, zero_sub, abs_neg]
    exact (htail t ht B hBa).trans_lt hB
  · rw [Metric.tendstoUniformlyOn_iff]
    intro ε hε
    filter_upwards [hMtail.eventually (gt_mem_nhds hε), eventually_ge_atTop a] with B hB hBa t ht
    rw [Real.dist_eq, hsplit t ht B hBa, add_sub_cancel_left]
    exact (htail t ht B hBa).trans_lt hB

/-- **Continuity passes inside.** Let f(t, x) be continuous for t in T and x ≥ a. If the
totals from a to B converge, uniformly for t in T, to F(t) as B grows (the improper integral
converges uniformly), then F is continuous on T. -/
theorem continuousOn_of_uniform_improper_integral
    {f : ℝ → ℝ → ℝ} {F : ℝ → ℝ} {a : ℝ} {T : Set ℝ}
    (hf : ContinuousOn (Function.uncurry f) (T ×ˢ Ici a))
    (hunif : TendstoUniformlyOn (fun B t => ∫ x in a..B, f t x) F atTop T) :
    ContinuousOn F T := by
  have hcont : ∀ᶠ B in atTop, ContinuousOn (fun t => ∫ x in a..B, f t x) T :=
    eventually_atTop.2 ⟨a, fun B hB => uc_continuousOn_intervalIntegral hf hB⟩
  exact hunif.continuousOn hcont.frequently

/-- **Derivatives pass inside.** Let T be an interval, and let f(t, x) and its rate in t,
f'(t, x) (x held still), be continuous for t in T and x ≥ a. Suppose the improper integral of
the rate converges uniformly on T, to G(t), and the improper integral of f converges at one
point t₀ of T. Then the improper integral of f converges at every t in T, to a value F(t), and
F has derivative G(t) at every t in T (one-sided at an end of T): the rate of the total is the
total of the rates. -/
theorem hasDerivWithinAt_of_uniform_improper_integral_deriv
    {f f' : ℝ → ℝ → ℝ} {G : ℝ → ℝ} {a t₀ F₀ : ℝ} {T : Set ℝ}
    (hT : T.OrdConnected)
    (hf : ContinuousOn (Function.uncurry f) (T ×ˢ Ici a))
    (hf' : ContinuousOn (Function.uncurry f') (T ×ˢ Ici a))
    (hderiv : ∀ x, a ≤ x → ∀ t ∈ T, HasDerivWithinAt (fun s => f s x) (f' t x) T t)
    (hunif : TendstoUniformlyOn (fun B t => ∫ x in a..B, f' t x) G atTop T)
    (ht₀ : t₀ ∈ T)
    (hF₀ : Tendsto (fun B => ∫ x in a..B, f t₀ x) atTop (𝓝 F₀)) :
    ∃ F : ℝ → ℝ, (∀ t ∈ T, Tendsto (fun B => ∫ x in a..B, f t x) atTop (𝓝 (F t))) ∧
      ∀ t ∈ T, HasDerivWithinAt F (G t) T t := by
  have hG : ContinuousOn G T := continuousOn_of_uniform_improper_integral hf' hunif
  have hJ : ∀ B, a ≤ B → ContinuousOn (fun t => ∫ x in a..B, f' t x) T := fun B hB =>
    uc_continuousOn_intervalIntegral hf' hB
  have hI : ∀ B, a ≤ B → ContinuousOn (fun t => ∫ x in a..B, f t x) T := fun B hB =>
    uc_continuousOn_intervalIntegral hf hB
  have hFTC : ∀ B, a ≤ B → ∀ t ∈ T, (∫ x in a..B, f t x) =
      (∫ x in a..B, f t₀ x) + ∫ s in t₀..t, ∫ x in a..B, f' s x := by
    intro B hB t ht
    have hsub : uIcc t₀ t ⊆ T := hT.uIcc_subset ht₀ ht
    have hsub' : Icc (min t₀ t) (max t₀ t) ⊆ T := by rw [Icc_min_max]; exact hsub
    rw [intervalIntegral.integral_eq_sub_of_hasDeriv_right ((hI B hB).mono hsub) ?_
      (((hJ B hB).mono hsub).intervalIntegrable)]
    · ring
    · intro u hu
      refine (uc_hasDerivAt_intervalIntegral hf hf' hderiv hB ?_).hasDerivWithinAt
      exact mem_of_superset (Ioo_mem_nhds hu.1 hu.2) (Ioo_subset_Icc_self.trans hsub')
  refine ⟨fun t => F₀ + ∫ s in t₀..t, G s, ?_, ?_⟩
  · intro t ht
    have hsub : uIcc t₀ t ⊆ T := hT.uIcc_subset ht₀ ht
    have h1 : Tendsto (fun B => ∫ s in t₀..t, ∫ x in a..B, f' s x) atTop
        (𝓝 (∫ s in t₀..t, G s)) := by
      rw [Metric.tendsto_nhds]
      intro ε hε
      have hε' : 0 < ε / (|t - t₀| + 1) := by positivity
      filter_upwards [(Metric.tendstoUniformlyOn_iff.1 hunif) _ hε', eventually_ge_atTop a]
        with B hB hBa
      rw [dist_eq_norm, ← intervalIntegral.integral_sub
        ((hJ B hBa).mono hsub).intervalIntegrable (hG.mono hsub).intervalIntegrable]
      calc ‖∫ s in t₀..t, ((∫ x in a..B, f' s x) - G s)‖
          ≤ ε / (|t - t₀| + 1) * |t - t₀| :=
            intervalIntegral.norm_integral_le_of_norm_le_const (fun s hs => by
              rw [← dist_eq_norm, dist_comm]
              exact (hB s (hsub (uIoc_subset_uIcc hs))).le)
        _ < ε := by
            rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]
            nlinarith [abs_nonneg (t - t₀)]
    refine (hF₀.add h1).congr' ?_
    filter_upwards [eventually_ge_atTop a] with B hB
    exact (hFTC B hB t ht).symm
  · intro t ht
    rw [hasDerivWithinAt_iff_isLittleO, Asymptotics.isLittleO_iff]
    intro c hc
    obtain ⟨δ, hδ, hδG⟩ := Metric.continuousWithinAt_iff.1 (hG t ht) c hc
    filter_upwards [self_mem_nhdsWithin, nhdsWithin_le_nhds (Metric.ball_mem_nhds t hδ)]
      with s hs hsδ
    have hsub : uIcc t s ⊆ T := hT.uIcc_subset ht hs
    have hint1 : IntervalIntegrable G volume t₀ s := (hG.mono (hT.uIcc_subset ht₀ hs)).intervalIntegrable
    have hint2 : IntervalIntegrable G volume t₀ t := (hG.mono (hT.uIcc_subset ht₀ ht)).intervalIntegrable
    have heq : (F₀ + ∫ u in t₀..s, G u) - (F₀ + ∫ u in t₀..t, G u) - (s - t) • G t =
        ∫ u in t..s, (G u - G t) := by
      rw [intervalIntegral.integral_sub (hG.mono hsub).intervalIntegrable (intervalIntegrable_const (μ := volume)),
        intervalIntegral.integral_const, ← intervalIntegral.integral_interval_sub_left hint1 hint2]
      simp only [smul_eq_mul]
      ring
    rw [heq]
    refine (intervalIntegral.norm_integral_le_of_norm_le_const (C := c) fun u hu => ?_).trans
      (le_of_eq (by rw [Real.norm_eq_abs]))
    have hu' : u ∈ uIcc t s := uIoc_subset_uIcc hu
    rw [← dist_eq_norm]
    refine (hδG (hsub hu') (lt_of_le_of_lt ?_ hsδ)).le
    rw [Real.dist_eq, Metric.mem_ball, Real.dist_eq] at *
    exact abs_sub_left_of_mem_uIcc hu'

-- The worked numbers, by hand.
-- Caps for t ≥ 1: the areas under x e^(-x), x^2 e^(-x), x^3 e^(-x) are 1!, 2!, 3!.
example : (Nat.factorial 1, Nat.factorial 2, Nat.factorial 3) = (1, 2, 6) := by decide
-- Three swaps on 1/t: -1/t^2, then 2/t^3, then -6/t^4; the coefficients are 1·2·3 = 6.
example : (1 : ℤ) * (-1) * (-2) * (-3) = -6 := by norm_num
-- At t = 2: 6/t^4 = 6/16 = 0.375 = 3/8.
example : (6 : ℚ) / 2 ^ 4 = 3 / 8 := by norm_num
-- The cap's tail beyond B = 20 is e^(-20) × (B^3 + 3B^2 + 6B + 6) = e^(-20) × 9326.
example : (20 : ℤ) ^ 3 + 3 * 20 ^ 2 + 6 * 20 + 6 = 8000 + 1200 + 120 + 6 := by norm_num
example : (8000 : ℤ) + 1200 + 120 + 6 = 9326 := by norm_num
-- The infinite-area cap x^3 for t ≥ 0: 6/t^4 at t = 1/10 is 60000.
example : (6 : ℚ) / (1 / 10) ^ 4 = 60000 := by norm_num
-- Dirichlet's rate -1/(1 + t^2) at t = 1 is -1/2.
example : (-1 : ℚ) / (1 + 1 ^ 2) = -1 / 2 := by norm_num
-- The bound 2/B at B = 10, 100, 1000 is 1/5, 1/50, 1/500.
example : ((2 : ℚ) / 10, (2 : ℚ) / 100, (2 : ℚ) / 1000) = (1 / 5, 1 / 50, 1 / 500) := by norm_num

#print axioms uc_continuousOn_intervalIntegral
#print axioms uc_hasDerivAt_intervalIntegral
#print axioms weierstrass_m_test_improper_integral
#print axioms continuousOn_of_uniform_improper_integral
#print axioms hasDerivWithinAt_of_uniform_improper_integral_deriv
