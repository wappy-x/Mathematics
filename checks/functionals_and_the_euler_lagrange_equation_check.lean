-- The Euler-Lagrange equation: a smooth route that is cheapest among all smooth routes with the same two ends satisfies F_y - d/dx F_p = 0 at every point strictly between the ends, a continuous function that integrates to zero against every nudge is zero, and on the flat field this forces the cable from (0, 0) to (400, 300) to be the straight line y = 0.75x.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Set Real

/-! Helper lemmas. -/

theorem fl_aux {G : ℝ → ℝ} {a b : ℝ} (hab : a < b)
    (hG : ContinuousOn G (Icc a b))
    (hzero : ∀ η : ℝ → ℝ, ContDiff ℝ 2 η → η a = 0 → η b = 0 →
      ∫ x in a..b, G x * η x = 0) :
    ∀ x ∈ Icc a b, G x = 0 := by
  have hint : ∀ x ∈ Ioo a b, G x = 0 := by
    intro x0 hx0
    by_contra hne
    obtain ⟨s, hsG⟩ : ∃ s : ℝ, 0 < s * G x0 := by
      rcases lt_or_gt_of_ne hne with h | h
      · exact ⟨-1, by linarith⟩
      · exact ⟨1, by linarith⟩
    have hcont : ContinuousAt G x0 := hG.continuousAt (Icc_mem_nhds hx0.1 hx0.2)
    have hev : ∀ᶠ x in nhds x0, 0 < s * G x :=
      (continuousAt_const.mul hcont).eventually (lt_mem_nhds hsG)
    obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff_ball.mp hev
    set r := min δ (min (x0 - a) (b - x0)) with hr_def
    have hr : 0 < r := lt_min hδ (lt_min (by linarith [hx0.1]) (by linarith [hx0.2]))
    have hrδ : r ≤ δ := min_le_left _ _
    have hra : r ≤ x0 - a := le_trans (min_le_right _ _) (min_le_left _ _)
    have hrb : r ≤ b - x0 := le_trans (min_le_right _ _) (min_le_right _ _)
    let φ : ContDiffBump x0 := ⟨r / 2, r, half_pos hr, half_lt_self hr⟩
    have hφ0 : ∀ x, x ∉ Metric.ball x0 r → φ x = 0 := by
      intro x hx
      by_contra h
      exact hx (φ.support_eq ▸ Function.mem_support.mpr h)
    have hφpos : ∀ x ∈ Metric.ball x0 r, 0 < φ x := fun x hx => φ.pos_of_mem_ball hx
    have hout : ∀ x, (x ≤ x0 - r ∨ x0 + r ≤ x) → φ x = 0 := by
      intro x hx
      apply hφ0
      rw [Metric.mem_ball, Real.dist_eq, not_lt]
      rcases hx with hx | hx
      · rw [abs_of_nonpos (by linarith)]; linarith
      · rw [abs_of_nonneg (by linarith)]; linarith
    set f : ℝ → ℝ := fun x => G x * (s * φ x) with hf_def
    have hηcd : ContDiff ℝ 2 (fun x => s * φ x) := contDiff_const.mul φ.contDiff
    have hI := hzero (fun x => s * φ x) hηcd
      (by rw [hout a (Or.inl (by linarith))]; ring)
      (by rw [hout b (Or.inr (by linarith))]; ring)
    have hfc : ContinuousOn f (Icc a b) :=
      hG.mul (continuousOn_const.mul φ.continuous.continuousOn)
    have hfi : ∀ c d, a ≤ c → c ≤ d → d ≤ b → IntervalIntegrable f MeasureTheory.volume c d := by
      intro c d hc hcd hd
      apply ContinuousOn.intervalIntegrable
      apply hfc.mono
      rw [uIcc_of_le hcd]
      exact Icc_subset_Icc hc hd
    have h1 : ∫ x in a..(x0 - r), f x = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0:ℝ))]
      · simp
      intro x hx
      rw [uIcc_of_le (by linarith)] at hx
      simp only [hf_def]
      rw [hout x (Or.inl hx.2)]; ring
    have h3 : ∫ x in (x0 + r)..b, f x = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0:ℝ))]
      · simp
      intro x hx
      rw [uIcc_of_le (by linarith)] at hx
      simp only [hf_def]
      rw [hout x (Or.inr hx.1)]; ring
    have h2 : 0 < ∫ x in (x0 - r)..(x0 + r), f x := by
      apply intervalIntegral.intervalIntegral_pos_of_pos_on (hfi _ _ (by linarith) (by linarith) (by linarith))
      · intro x hx
        have hxb : x ∈ Metric.ball x0 r := by
          rw [Metric.mem_ball, Real.dist_eq, abs_lt]; constructor <;> linarith [hx.1, hx.2]
        have hxδ : x ∈ Metric.ball x0 δ := Metric.ball_subset_ball hrδ hxb
        have := hball x hxδ
        have := hφpos x hxb
        simp only [hf_def]
        nlinarith
      · linarith
    have hsplit : ∫ x in a..b, f x = (∫ x in a..(x0 - r), f x) + (∫ x in (x0 - r)..(x0 + r), f x)
        + ∫ x in (x0 + r)..b, f x := by
      rw [intervalIntegral.integral_add_adjacent_intervals
          (hfi _ _ le_rfl (by linarith) (by linarith))
          (hfi _ _ (by linarith) (by linarith) (by linarith)),
        intervalIntegral.integral_add_adjacent_intervals
          (hfi _ _ le_rfl (by linarith) (by linarith))
          (hfi _ _ (by linarith) (by linarith) le_rfl)]
    have : ∫ x in a..b, f x = 0 := hI
    linarith
  have := Set.EqOn.of_subset_closure (f := G) (g := fun _ => (0:ℝ)) hint hG continuousOn_const
    Ioo_subset_Icc_self (by rw [closure_Ioo hab.ne])
  exact fun x hx => this hx

#print axioms fl_aux

theorem el_aux {F : ℝ → ℝ → ℝ → ℝ} {y : ℝ → ℝ} {a b : ℝ}
    (hab : a < b)
    (hF : ContDiff ℝ 2 (fun q : ℝ × ℝ × ℝ => F q.1 q.2.1 q.2.2))
    (hy : ContDiff ℝ 2 y)
    (hmin : ∀ η : ℝ → ℝ, ContDiff ℝ 2 η → η a = 0 → η b = 0 →
      (∫ x in a..b, F x (y x) (deriv y x)) ≤
        ∫ x in a..b, F x (y x + η x) (deriv (fun t => y t + η t) x)) :
    ∀ x ∈ Ioo a b,
      deriv (fun u => F x u (deriv y x)) (y x)
        - deriv (fun t => deriv (fun p => F t (y t) p) (deriv y t)) x = 0 := by
  set Fu : ℝ × ℝ × ℝ → ℝ := fun q => F q.1 q.2.1 q.2.2 with hFu
  have hFd : Differentiable ℝ Fu := hF.differentiable (by norm_num)
  set DF := fderiv ℝ Fu with hDF
  have hDF1 : ContDiff ℝ 1 DF := hF.fderiv_right (m := 1) (by norm_num)
  have hDFc : Continuous DF := hDF1.continuous
  have hFy : ∀ x u p, HasDerivAt (fun u' => F x u' p) (DF (x, u, p) (0, 1, 0)) u := by
    intro x u p
    have h1 : HasDerivAt (fun u' : ℝ => ((x, u', p) : ℝ × ℝ × ℝ)) ((0, 1, 0)) u :=
      (hasDerivAt_const u x).prodMk ((hasDerivAt_id u).prodMk (hasDerivAt_const u p))
    exact (hFd (x, u, p)).hasFDerivAt.comp_hasDerivAt u h1
  have hFp : ∀ x u p, HasDerivAt (fun p' => F x u p') (DF (x, u, p) (0, 0, 1)) p := by
    intro x u p
    have h1 : HasDerivAt (fun p' : ℝ => ((x, u, p') : ℝ × ℝ × ℝ)) ((0, 0, 1)) p :=
      (hasDerivAt_const p x).prodMk ((hasDerivAt_const p u).prodMk (hasDerivAt_id p))
    exact (hFd (x, u, p)).hasFDerivAt.comp_hasDerivAt p h1
  have hlin2 : ∀ q (s t : ℝ), DF q (0, s, t) = s * DF q (0, 1, 0) + t * DF q (0, 0, 1) := by
    intro q s t
    rw [← smul_eq_mul, ← smul_eq_mul, ← map_smul, ← map_smul, ← map_add]
    congr 1
    ext <;> simp
  have hy1 : ContDiff ℝ 1 (deriv y) := hy.iterate_deriv' 1 1
  have hyd : Differentiable ℝ y := hy.differentiable (by norm_num)
  have hyc : Continuous y := hyd.continuous
  have hdyc : Continuous (deriv y) := hy1.continuous
  have hγ : ContDiff ℝ 1 (fun t => ((t, y t, deriv y t) : ℝ × ℝ × ℝ)) :=
    contDiff_id.prodMk ((hy.of_le (by norm_num)).prodMk hy1)
  set g : ℝ → ℝ := fun t => DF (t, y t, deriv y t) (0, 0, 1) with hg
  have hgfun : (fun t => deriv (fun p => F t (y t) p) (deriv y t)) = g :=
    funext fun t => (hFp _ _ _).deriv
  have hFydef : ∀ t, deriv (fun u => F t u (deriv y t)) (y t) = DF (t, y t, deriv y t) (0, 1, 0) :=
    fun t => (hFy _ _ _).deriv
  have hg1 : ContDiff ℝ 1 g := (hDF1.comp hγ).clm_apply contDiff_const
  have hgd : Differentiable ℝ g := hg1.differentiable_one
  have hdgc : Continuous (deriv g) := hg1.continuous_deriv le_rfl
  have hFyc : Continuous (fun t => DF (t, y t, deriv y t) (0, 1, 0)) :=
    (hDFc.comp hγ.continuous).clm_apply continuous_const
  have key := fl_aux (G := fun t => DF (t, y t, deriv y t) (0, 1, 0) - deriv g t) hab
    (hFyc.sub hdgc).continuousOn ?_
  · intro x hx
    rw [hFydef, hgfun]
    exact key x (Ioo_subset_Icc_self hx)
  intro η hη ha hb
  have hη1 : ContDiff ℝ 1 (deriv η) := hη.iterate_deriv' 1 1
  have hηd : Differentiable ℝ η := hη.differentiable (by norm_num)
  have hηc : Continuous η := hηd.continuous
  have hdηc : Continuous (deriv η) := hη1.continuous
  -- the varied cost
  let P : ℝ → ℝ → ℝ := fun e x => F x (y x + e * η x) (deriv y x + e * deriv η x)
  let P' : ℝ → ℝ → ℝ := fun e x =>
    DF (x, y x + e * η x, deriv y x + e * deriv η x) (0, η x, deriv η x)
  have hPc : ∀ e, Continuous (P e) := by
    intro e
    have : Continuous (fun x => ((x, y x + e * η x, deriv y x + e * deriv η x) : ℝ × ℝ × ℝ)) := by
      fun_prop
    exact hFd.continuous.comp this
  have hQc : Continuous (fun z : ℝ × ℝ => P' z.1 z.2) := by
    have : Continuous (fun z : ℝ × ℝ =>
        ((z.2, y z.2 + z.1 * η z.2, deriv y z.2 + z.1 * deriv η z.2) : ℝ × ℝ × ℝ)) := by
      fun_prop
    exact (hDFc.comp this).clm_apply (by fun_prop)
  have hP'c : ∀ e, Continuous (P' e) := fun e =>
    hQc.comp (continuous_const.prodMk continuous_id)
  have hPd : ∀ e x, HasDerivAt (fun e => P e x) (P' e x) e := by
    intro e x
    have hl : ∀ c d : ℝ, HasDerivAt (fun e : ℝ => c + e * d) d e := by
      intro c d; simpa using ((hasDerivAt_id e).mul_const d).const_add c
    have h1 : HasDerivAt (fun e : ℝ =>
        ((x, y x + e * η x, deriv y x + e * deriv η x) : ℝ × ℝ × ℝ)) ((0, η x, deriv η x)) e :=
      (hasDerivAt_const e x).prodMk ((hl _ _).prodMk (hl _ _))
    exact (hFd _).hasFDerivAt.comp_hasDerivAt e h1
  obtain ⟨C, hC⟩ := ((isCompact_closedBall (0:ℝ) 1).prod (isCompact_Icc
    (a := a) (b := b))).exists_bound_of_continuousOn hQc.continuousOn
  have hderiv := intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
    (μ := MeasureTheory.volume) (a := a) (b := b) (F := P) (F' := P') (x₀ := 0)
    (bound := fun _ => C) (s := Metric.ball 0 1) (Metric.ball_mem_nhds 0 one_pos)
    (Filter.Eventually.of_forall fun e => (hPc e).aestronglyMeasurable)
    ((hPc 0).intervalIntegrable _ _) (hP'c 0).aestronglyMeasurable
    (Filter.Eventually.of_forall fun x hx e he => by
      have := hC (e, x) ⟨Metric.ball_subset_closedBall he, by
        rw [uIoc_of_le hab.le] at hx; exact Ioc_subset_Icc_self hx⟩
      simpa using this)
    intervalIntegrable_const
    (Filter.Eventually.of_forall fun x _ e _ => hPd e x)
  have hmin' : IsLocalMin (fun e => ∫ x in a..b, P e x) 0 := by
    refine Filter.Eventually.of_forall fun e => ?_
    have h := hmin (fun t => e * η t) (contDiff_const.mul hη) (by simp [ha]) (by simp [hb])
    have hd : ∀ x, deriv (fun t => y t + e * η t) x = deriv y x + e * deriv η x := by
      intro x
      exact ((hyd x).hasDerivAt.add ((hηd x).hasDerivAt.const_mul e)).deriv
    simp only [hd] at h
    simpa [P] using h
  have hzero := hmin'.hasDerivAt_eq_zero hderiv.2
  have hP'0 : ∀ x, P' 0 x = DF (x, y x, deriv y x) (0, 1, 0) * η x + g x * deriv η x := by
    intro x
    show DF (x, y x + 0 * η x, deriv y x + 0 * deriv η x) (0, η x, deriv η x) =
      DF (x, y x, deriv y x) (0, 1, 0) * η x + DF (x, y x, deriv y x) (0, 0, 1) * deriv η x
    rw [zero_mul, zero_mul, add_zero, add_zero, hlin2]
    ring
  simp only [hP'0] at hzero
  have hi1 : IntervalIntegrable (fun x => DF (x, y x, deriv y x) (0, 1, 0) * η x)
      MeasureTheory.volume a b := (hFyc.mul hηc).intervalIntegrable _ _
  have hi2 : IntervalIntegrable (fun x => g x * deriv η x) MeasureTheory.volume a b :=
    (hgd.continuous.mul hdηc).intervalIntegrable _ _
  have hi3 : IntervalIntegrable (fun x => deriv g x * η x) MeasureTheory.volume a b :=
    (hdgc.mul hηc).intervalIntegrable _ _
  rw [intervalIntegral.integral_add hi1 hi2] at hzero
  have hparts := intervalIntegral.integral_mul_deriv_eq_deriv_mul
    (u := g) (v := η) (u' := deriv g) (v' := deriv η) (a := a) (b := b)
    (fun x _ => (hgd x).hasDerivAt) (fun x _ => (hηd x).hasDerivAt)
    (hdgc.intervalIntegrable _ _) (hdηc.intervalIntegrable _ _)
  rw [ha, hb, mul_zero, mul_zero, sub_zero, zero_sub] at hparts
  simp only [sub_mul]
  rw [intervalIntegral.integral_sub hi1 hi3]
  linarith

#print axioms el_aux

theorem slope_ratio_injective {p q : ℝ} (h : p / √(1 + p ^ 2) = q / √(1 + q ^ 2)) : p = q := by
  have hp : 0 < √(1 + p ^ 2) := Real.sqrt_pos.mpr (by positivity)
  have hq : 0 < √(1 + q ^ 2) := Real.sqrt_pos.mpr (by positivity)
  have hp2 : √(1 + p ^ 2) ^ 2 = 1 + p ^ 2 := Real.sq_sqrt (by positivity)
  have hq2 : √(1 + q ^ 2) ^ 2 = 1 + q ^ 2 := Real.sq_sqrt (by positivity)
  rw [div_eq_div_iff hp.ne' hq.ne'] at h
  have hsq : p ^ 2 = q ^ 2 := by
    have := congrArg (· ^ 2) h
    simp only [mul_pow, hp2, hq2] at this
    nlinarith
  have hs : √(1 + p ^ 2) = √(1 + q ^ 2) := by rw [hsq]
  rw [hs] at h
  exact mul_right_cancel₀ hq.ne' h

theorem flat_aux {y : ℝ → ℝ}
    (hy : ContDiff ℝ 2 y) (hA : y 0 = 0) (hB : y 400 = 300)
    (hEL : ∀ x ∈ Ioo (0 : ℝ) 400,
      deriv (fun _u : ℝ => √(1 + deriv y x ^ 2)) (y x)
        - deriv (fun t => deriv (fun p : ℝ => √(1 + p ^ 2)) (deriv y t)) x = 0) :
    ∀ x ∈ Icc (0 : ℝ) 400, y x = 3 / 4 * x := by
  have hy1 : ContDiff ℝ 1 (deriv y) := hy.iterate_deriv' 1 1
  have hdy : Differentiable ℝ (deriv y) := hy1.differentiable_one
  have hyd : Differentiable ℝ y := hy.differentiable (by norm_num)
  have hk : ∀ q : ℝ, deriv (fun p : ℝ => √(1 + p ^ 2)) q = q / √(1 + q ^ 2) := by
    intro q
    have hpos : (0:ℝ) < 1 + q ^ 2 := by positivity
    have h := ((hasDerivAt_pow 2 q).const_add 1).sqrt hpos.ne'
    rw [h.deriv]
    simp
    field_simp
  simp only [hk, deriv_const, zero_sub, neg_eq_zero] at hEL
  set K : ℝ → ℝ := fun t => deriv y t / √(1 + deriv y t ^ 2) with hK
  have hKd : Differentiable ℝ K := by
    intro t
    have hpos : (0:ℝ) < 1 + deriv y t ^ 2 := by positivity
    exact (hdy t).div ((((hdy t).pow 2).const_add 1).sqrt hpos.ne')
      (Real.sqrt_pos.mpr hpos).ne'
  have hKc : ∀ x ∈ Icc (0:ℝ) 400, K x = K 0 := by
    intro x hx
    rcases eq_or_lt_of_le hx.1 with h0 | h0
    · rw [← h0]
    obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope K h0 hKd.continuous.continuousOn
      (fun t _ => (hKd t).differentiableWithinAt)
    have : deriv K c = 0 := hEL c ⟨hc.1, lt_of_lt_of_le hc.2 hx.2⟩
    rw [this, eq_comm, div_eq_zero_iff] at hcd
    rcases hcd with h | h
    · linarith
    · linarith
  have hm : ∀ x ∈ Icc (0:ℝ) 400, deriv y x = deriv y 0 := fun x hx =>
    slope_ratio_injective (hKc x hx)
  have hlin : ∀ x ∈ Icc (0:ℝ) 400, y x = deriv y 0 * x := by
    intro x hx
    rcases eq_or_lt_of_le hx.1 with h0 | h0
    · rw [← h0, hA]; ring
    obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope y h0 hyd.continuous.continuousOn
      (fun t _ => (hyd t).differentiableWithinAt)
    rw [hm c ⟨hc.1.le, (lt_of_lt_of_le hc.2 hx.2).le⟩, hA, sub_zero, sub_zero] at hcd
    rw [hcd]; field_simp
  have h400 := hlin 400 ⟨by norm_num, le_rfl⟩
  rw [hB] at h400
  intro x hx
  rw [hlin x hx]
  have : deriv y 0 = 3 / 4 := by linarith
  rw [this]

#print axioms slope_ratio_injective
#print axioms flat_aux


/-! A route is a function `y : ℝ → ℝ`; at distance `x` east it runs `y x` north, with slope
`deriv y x`. The cost per metre east is `F x u p`, where `u` is the height slot and `p` the
slope slot. The cost of a route from `a` to `b` is `J[y] = ∫ x in a..b, F x (y x) (deriv y x)`.
`F_y` is `deriv (fun u' => F x u' p) u`, the rate `F` changes with height, slope held still;
`F_p` is `deriv (fun p' => F x u p') p`, the rate with slope, height held still.
"Smooth" means twice continuously differentiable (`ContDiff ℝ 2`). A nudge is a smooth `η`
with `η a = 0` and `η b = 0`, so the nudged route `y + η` keeps both ends fixed. -/

/-- **The Euler-Lagrange equation.** Let the cost per metre `F(x, u, p)` be smooth in all three
slots and let the route `y` be smooth, with `a < b`. If `y` is the cheapest route with its ends
fixed — no smooth nudge `η` that is zero at `a` and at `b` makes the cost
`∫ₐᵇ F(x, y, y') dx` smaller — then at every point strictly between the ends
`F_y(x, y, y') - d/dx F_p(x, y, y') = 0`. -/
theorem euler_lagrange_equation_of_minimizer {F : ℝ → ℝ → ℝ → ℝ} {y : ℝ → ℝ} {a b : ℝ}
    (hab : a < b)
    (hF : ContDiff ℝ 2 (fun q : ℝ × ℝ × ℝ => F q.1 q.2.1 q.2.2))
    (hy : ContDiff ℝ 2 y)
    (hmin : ∀ η : ℝ → ℝ, ContDiff ℝ 2 η → η a = 0 → η b = 0 →
      (∫ x in a..b, F x (y x) (deriv y x)) ≤
        ∫ x in a..b, F x (y x + η x) (deriv (fun t => y t + η t) x)) :
    ∀ x ∈ Ioo a b,
      deriv (fun u => F x u (deriv y x)) (y x)
        - deriv (fun t => deriv (fun p => F t (y t) p) (deriv y t)) x = 0 := by
  exact el_aux hab hF hy hmin

/-- **The fundamental lemma of the calculus of variations.** Let `G` be continuous on `[a, b]`.
If `∫ₐᵇ G η dx = 0` for every nudge — every smooth `η` that is zero at `a` and at `b` — then
`G = 0` everywhere on `[a, b]`. -/
theorem fundamental_lemma_calculus_of_variations {G : ℝ → ℝ} {a b : ℝ} (hab : a < b)
    (hG : ContinuousOn G (Icc a b))
    (hzero : ∀ η : ℝ → ℝ, ContDiff ℝ 2 η → η a = 0 → η b = 0 →
      ∫ x in a..b, G x * η x = 0) :
    ∀ x ∈ Icc a b, G x = 0 := by
  exact fl_aux hab hG hzero

/-- **The flat field gives a straight line.** With one price, the cost per metre east is
`F = √(1 + p²)` metres of cable. If a smooth route `y` from pylon A = (0, 0) to pylon
B = (400, 300) satisfies the Euler-Lagrange equation `F_y - d/dx F_p = 0` for this `F` at every
point strictly between the pylons, then it is the straight line `y = 0.75x` on `[0, 400]`. -/
theorem flat_field_euler_lagrange_gives_straight_line {y : ℝ → ℝ}
    (hy : ContDiff ℝ 2 y) (hA : y 0 = 0) (hB : y 400 = 300)
    (hEL : ∀ x ∈ Ioo (0 : ℝ) 400,
      deriv (fun _u : ℝ => √(1 + deriv y x ^ 2)) (y x)
        - deriv (fun t => deriv (fun p : ℝ => √(1 + p ^ 2)) (deriv y t)) x = 0) :
    ∀ x ∈ Icc (0 : ℝ) 400, y x = 3 / 4 * x := by
  exact flat_aux hy hA hB hEL

/-! The card's exact worked numbers. -/

-- The straight route on the flat field: √(400² + 300²) = 500 m.
example : √((400 : ℝ) ^ 2 + 300 ^ 2) = 500 := by
  rw [show (400 : ℝ) ^ 2 + 300 ^ 2 = 500 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Its slope 300/400 = 3/4 = 0.75.
example : (300 : ℚ) / 400 = 3 / 4 := by norm_num
-- Its slope term: √(1 + (3/4)²) = 5/4, so F_p = (3/4)/(5/4) = 3/5 = 0.6.
example : √(1 + ((3 : ℝ) / 4) ^ 2) = 5 / 4 := by
  rw [show 1 + ((3 : ℝ) / 4) ^ 2 = (5 / 4) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : ((3 : ℚ) / 4) / (5 / 4) = 3 / 5 := by norm_num
-- Moving pylon B 10 m north: first variation 0.6 × 10 = 6 m, not 0.
example : (3 : ℚ) / 5 * 10 = 6 := by norm_num
-- The straight route crosses the border x = 200 at y = 0.75 × 200 = 150, each half 250 m long.
example : (3 : ℚ) / 4 * 200 = 150 := by norm_num
example : √((200 : ℝ) ^ 2 + 150 ^ 2) = 250 := by
  rw [show (200 : ℝ) ^ 2 + 150 ^ 2 = 250 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Keeping the straight route on the rocky field: 80 × 250 + 160 × 250 = £60,000.
example : (80 : ℚ) * 250 + 160 * 250 = 60000 := by norm_num

#print axioms euler_lagrange_equation_of_minimizer
#print axioms fundamental_lemma_calculus_of_variations
#print axioms flat_field_euler_lagrange_gives_straight_line
