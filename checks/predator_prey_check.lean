-- Predator and prey: every positive solution of the Lotka-Volterra equations keeps d·x − c·ln x + b·y − a·ln y fixed, stays positive, repeats in a closed cycle, and over each lap averages exactly to the balance point (c/d, a/b).
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Real


theorem lv_linear_sol {W k : ℝ → ℝ} (hk : Continuous k)
    (hW : ∀ t, HasDerivAt W (k t * W t) t) (t : ℝ) :
    W t = Real.exp (∫ s in (0:ℝ)..t, k s) * W 0 := by
  set P : ℝ → ℝ := fun t => ∫ s in (0:ℝ)..t, k s with hP
  have hPd : ∀ t, HasDerivAt P (k t) t := fun t => (hk.integral_hasStrictDerivAt 0 t).hasDerivAt
  have hg : ∀ t, HasDerivAt (fun t => W t * Real.exp (-P t)) 0 t := by
    intro t
    have h1 := ((hPd t).neg).exp
    have h2 := (hW t).mul h1
    convert h2 using 1
    ring
  have hconst := is_const_of_deriv_eq_zero (fun t => (hg t).differentiableAt)
    (fun t => (hg t).deriv) t 0
  have hP0 : P 0 = 0 := by simp [hP]
  simp only [hP0, neg_zero, Real.exp_zero, mul_one] at hconst
  have he : Real.exp (P t) * Real.exp (-P t) = 1 := by
    rw [← Real.exp_add]; simp
  calc W t = Real.exp (P t) * (W t * Real.exp (-P t)) := by
        linear_combination (-(W t)) * he
    _ = Real.exp (P t) * W 0 := by rw [hconst]

theorem lv_g_min {c d s : ℝ} (hc : 0 < c) (hd : 0 < d) (hs : 0 < s) :
    c - c * Real.log (c / d) ≤ d * s - c * Real.log s ∧
    (s ≠ c / d → c - c * Real.log (c / d) < d * s - c * Real.log s) := by
  have hz : 0 < s * d / c := by positivity
  have hlog : Real.log (s * d / c) = Real.log s - Real.log (c / d) := by
    rw [Real.log_div (by positivity) hc.ne', Real.log_mul hs.ne' hd.ne',
      Real.log_div hc.ne' hd.ne']; ring
  have key : c * (s * d / c) = d * s := by field_simp
  constructor
  · have h := Real.log_le_sub_one_of_pos hz
    rw [hlog] at h
    have := mul_le_mul_of_nonneg_left h hc.le
    nlinarith
  · intro hne
    have hz1 : s * d / c ≠ 1 := by
      intro h1; apply hne; field_simp at h1 ⊢; linarith
    have h := Real.log_lt_sub_one_of_pos hz hz1
    rw [hlog] at h
    have := mul_lt_mul_of_pos_left h hc
    nlinarith

theorem lv_conserved
    {a b c d : ℝ} {x y : ℝ → ℝ}
    (hx : ∀ t, HasDerivAt x (a * x t - b * x t * y t) t)
    (hy : ∀ t, HasDerivAt y (-c * y t + d * x t * y t) t)
    (hxpos : ∀ t, 0 < x t) (hypos : ∀ t, 0 < y t) (t : ℝ) :
    d * x t - c * Real.log (x t) + b * y t - a * Real.log (y t) =
      d * x 0 - c * Real.log (x 0) + b * y 0 - a * Real.log (y 0) := by
  have hG : ∀ t, HasDerivAt
      (fun t => d * x t - c * Real.log (x t) + b * y t - a * Real.log (y t)) 0 t := by
    intro t
    have h1 := (((hx t).const_mul d).sub (((hx t).log (hxpos t).ne').const_mul c)).add
      ((hy t).const_mul b) |>.sub (((hy t).log (hypos t).ne').const_mul a)
    convert h1 using 1
    have := (hxpos t).ne'
    have := (hypos t).ne'
    field_simp
    ring
  exact is_const_of_deriv_eq_zero (fun t => (hG t).differentiableAt) (fun t => (hG t).deriv) t 0

theorem lv_lap_average
    {a b c d : ℝ} (hb : b ≠ 0) (hd : d ≠ 0) {x y : ℝ → ℝ}
    (hx : ∀ t, HasDerivAt x (a * x t - b * x t * y t) t)
    (hy : ∀ t, HasDerivAt y (-c * y t + d * x t * y t) t)
    (hxpos : ∀ t, 0 < x t) (hypos : ∀ t, 0 < y t)
    {T : ℝ} (hT : 0 < T) (hxT : x T = x 0) (hyT : y T = y 0) :
    (∫ t in (0 : ℝ)..T, x t) / T = c / d ∧ (∫ t in (0 : ℝ)..T, y t) / T = a / b := by
  have hxc : Continuous x := continuous_iff_continuousAt.2 fun t => (hx t).continuousAt
  have hyc : Continuous y := continuous_iff_continuousAt.2 fun t => (hy t).continuousAt
  have hlx : ∀ t, HasDerivAt (fun t => Real.log (x t)) (a - b * y t) t := by
    intro t
    have := (hx t).log (hxpos t).ne'
    convert this using 1
    have := (hxpos t).ne'
    field_simp
  have hly : ∀ t, HasDerivAt (fun t => Real.log (y t)) (-c + d * x t) t := by
    intro t
    have := (hy t).log (hypos t).ne'
    convert this using 1
    have := (hypos t).ne'
    field_simp
  have i1 := intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hlx t)
    ((continuous_const.sub (continuous_const.mul hyc)).intervalIntegrable 0 T)
  have i2 := intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hly t)
    ((continuous_const.add (continuous_const.mul hxc)).intervalIntegrable 0 T)
  rw [hxT, sub_self] at i1
  rw [hyT, sub_self] at i2
  rw [intervalIntegral.integral_sub (f := fun _ => a) (g := fun t => b * y t)
    intervalIntegrable_const
    ((continuous_const.mul hyc).intervalIntegrable 0 T), intervalIntegral.integral_const,
    intervalIntegral.integral_const_mul] at i1
  rw [intervalIntegral.integral_add (f := fun _ => -c) (g := fun t => d * x t)
    intervalIntegrable_const
    ((continuous_const.mul hxc).intervalIntegrable 0 T), intervalIntegral.integral_const,
    intervalIntegral.integral_const_mul] at i2
  simp only [smul_eq_mul, sub_zero] at i1 i2
  constructor
  · rw [div_eq_div_iff hT.ne' hd]; linarith
  · rw [div_eq_div_iff hT.ne' hb]; linarith

theorem lv_ray {a b c d X Y μ : ℝ} (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) (hd : 0 < d)
    (hX : 0 < X) (hY : 0 < Y) (hne : ¬ (X = c / d ∧ Y = a / b)) (hμ0 : 0 < μ) (hμ1 : μ < 1) :
    d * (c / d + μ * (X - c / d)) - c * Real.log (c / d + μ * (X - c / d)) +
      b * (a / b + μ * (Y - a / b)) - a * Real.log (a / b + μ * (Y - a / b)) <
    d * X - c * Real.log X + b * Y - a * Real.log Y := by
  have hp : 0 < c / d := div_pos hc hd
  have hq : 0 < a / b := div_pos ha hb
  have e1 : c / d + μ * (X - c / d) = (1 - μ) • (c / d) + μ • X := by
    simp only [smul_eq_mul]; ring
  have e2 : a / b + μ * (Y - a / b) = (1 - μ) • (a / b) + μ • Y := by
    simp only [smul_eq_mul]; ring
  have l1 := strictConcaveOn_log_Ioi.concaveOn.2 (Set.mem_Ioi.2 hp) (Set.mem_Ioi.2 hX)
    (by linarith : (0:ℝ) ≤ 1 - μ) hμ0.le (by ring)
  have l2 := strictConcaveOn_log_Ioi.concaveOn.2 (Set.mem_Ioi.2 hq) (Set.mem_Ioi.2 hY)
    (by linarith : (0:ℝ) ≤ 1 - μ) hμ0.le (by ring)
  rw [← e1] at l1
  rw [← e2] at l2
  simp only [smul_eq_mul] at l1 l2
  have hpd : d * (c / d) = c := by field_simp
  have hqb : b * (a / b) = a := by field_simp
  have gx := lv_g_min hc hd hX
  have gy := lv_g_min ha hb hY
  have hstrict : c - c * Real.log (c / d) + (a - a * Real.log (a / b)) <
      d * X - c * Real.log X + (b * Y - a * Real.log Y) := by
    by_cases h : X = c / d
    · have : Y ≠ a / b := fun hy => hne ⟨h, hy⟩
      linarith [gy.2 this, gx.1]
    · linarith [gx.2 h, gy.1]
  have m1 := mul_le_mul_of_nonneg_left l1 hc.le
  have m2 := mul_le_mul_of_nonneg_left l2 ha.le
  have m3 := mul_lt_mul_of_pos_left hstrict (by linarith : (0:ℝ) < 1 - μ)
  nlinarith

theorem lv_bounds {a b c d K : ℝ} (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) (hd : 0 < d) :
    ∃ m M : ℝ, 0 < m ∧ ∀ X Y : ℝ, 0 < X → 0 < Y →
      d * X - c * Real.log X + b * Y - a * Real.log Y ≤ K →
      m ≤ X ∧ X ≤ M ∧ m ≤ Y ∧ Y ≤ M := by
  refine ⟨min (Real.exp (-(K - (a - a * Real.log (a / b))) / c))
      (Real.exp (-(K - (c - c * Real.log (c / d))) / a)),
    max (2 * (K - (a - a * Real.log (a / b)) - (c - c * Real.log (c / (d / 2)))) / d)
      (2 * (K - (c - c * Real.log (c / d)) - (a - a * Real.log (a / (b / 2)))) / b),
    by positivity, ?_⟩
  intro X Y hX hY hH
  have gx := (lv_g_min hc hd hX).1
  have gy := (lv_g_min ha hb hY).1
  have gx2 := (lv_g_min hc (half_pos hd) hX).1
  have gy2 := (lv_g_min ha (half_pos hb) hY).1
  have hdX := mul_pos hd hX
  have hbY := mul_pos hb hY
  have hlX : -(K - (a - a * Real.log (a / b))) / c ≤ Real.log X := by
    rw [div_le_iff₀ hc]; nlinarith
  have hlY : -(K - (c - c * Real.log (c / d))) / a ≤ Real.log Y := by
    rw [div_le_iff₀ ha]; nlinarith
  refine ⟨?_, ?_, ?_, ?_⟩
  · calc _ ≤ Real.exp (-(K - (a - a * Real.log (a / b))) / c) := min_le_left _ _
      _ ≤ Real.exp (Real.log X) := Real.exp_le_exp.2 hlX
      _ = X := Real.exp_log hX
  · refine le_max_of_le_left ?_
    rw [le_div_iff₀ hd]; linarith
  · calc _ ≤ Real.exp (-(K - (c - c * Real.log (c / d))) / a) := min_le_right _ _
      _ ≤ Real.exp (Real.log Y) := Real.exp_le_exp.2 hlY
      _ = Y := Real.exp_log hY
  · refine le_max_of_le_right ?_
    rw [le_div_iff₀ hb]; linarith

theorem lv_periodic {a b c d : ℝ} (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) (hd : 0 < d)
    {x y : ℝ → ℝ}
    (hx : ∀ t, HasDerivAt x (a * x t - b * x t * y t) t)
    (hy : ∀ t, HasDerivAt y (-c * y t + d * x t * y t) t)
    (hxpos : ∀ t, 0 < x t) (hypos : ∀ t, 0 < y t) :
    ∃ T > 0, ∀ t, x (t + T) = x t ∧ y (t + T) = y t := by
  have hxc : Continuous x := continuous_iff_continuousAt.2 fun t => (hx t).continuousAt
  have hyc : Continuous y := continuous_iff_continuousAt.2 fun t => (hy t).continuousAt
  have hcons := lv_conserved hx hy hxpos hypos
  obtain ⟨m, M, hm, hbd⟩ := lv_bounds
    (K := d * x 0 - c * Real.log (x 0) + b * y 0 - a * Real.log (y 0)) ha hb hc hd
  have hbox : ∀ t, m ≤ x t ∧ x t ≤ M ∧ m ≤ y t ∧ y t ≤ M :=
    fun t => hbd _ _ (hxpos t) (hypos t) (hcons t).le
  -- uniqueness: returning to the start gives a period
  have huniq : ∀ T, x T = x 0 → y T = y 0 → ∀ t, x (t + T) = x t ∧ y (t + T) = y t := by
    intro T hxT hyT
    let V : ℝ × ℝ → ℝ × ℝ := fun z => (a * z.1 - b * z.1 * z.2, -c * z.2 + d * z.1 * z.2)
    have hVd : ContDiff ℝ 1 V := by fun_prop
    obtain ⟨K, hK⟩ := (hVd.locallyLipschitz.locallyLipschitzOn
      (s := Set.Icc ((m, m) : ℝ × ℝ) (M, M))).exists_lipschitzOnWith_of_compact isCompact_Icc
    have key := ODE_solution_unique_univ (v := fun _ => V)
      (s := fun _ => Set.Icc ((m, m) : ℝ × ℝ) (M, M)) (K := K) (t₀ := 0)
      (f := fun t => (x (t + T), y (t + T))) (g := fun t => (x t, y t)) (fun _ => hK) ?_ ?_ ?_
    · intro t
      have := congrFun key t
      simp only [Prod.mk.injEq] at this
      exact this
    · intro t
      refine ⟨?_, ?_⟩
      · have h1 := (hx (t + T)).comp t ((hasDerivAt_id t).add_const T)
        have h2 := (hy (t + T)).comp t ((hasDerivAt_id t).add_const T)
        have h3 := h1.prodMk h2
        simp only [mul_one, id] at h3
        exact h3
      · obtain ⟨h1, h2, h3, h4⟩ := hbox (t + T)
        simp only [Set.mem_Icc, Prod.mk_le_mk]
        exact ⟨⟨h1, h3⟩, ⟨h2, h4⟩⟩
    · intro t
      refine ⟨(hx t).prodMk (hy t), ?_⟩
      obtain ⟨h1, h2, h3, h4⟩ := hbox t
      simp only [Set.mem_Icc, Prod.mk_le_mk]
      exact ⟨⟨h1, h3⟩, ⟨h2, h4⟩⟩
    · simp [hxT, hyT]
  have gmin : ∀ t, c - c * Real.log (c / d) + (a - a * Real.log (a / b)) ≤
      d * x t - c * Real.log (x t) + b * y t - a * Real.log (y t) := by
    intro t
    have := (lv_g_min hc hd (hxpos t)).1
    have := (lv_g_min ha hb (hypos t)).1
    linarith
  by_cases heq : x 0 = c / d ∧ y 0 = a / b
  · -- the balance point: the path never moves
    have hH0 : d * x 0 - c * Real.log (x 0) + b * y 0 - a * Real.log (y 0) =
        c - c * Real.log (c / d) + (a - a * Real.log (a / b)) := by
      rw [heq.1, heq.2]
      have : d * (c / d) = c := by field_simp
      have : b * (a / b) = a := by field_simp
      linarith
    have hall : ∀ t, x t = c / d ∧ y t = a / b := by
      intro t
      by_contra hne
      have h := hcons t
      by_cases h1 : x t = c / d
      · have h2 : y t ≠ a / b := fun h2 => hne ⟨h1, h2⟩
        have := (lv_g_min hc hd (hxpos t)).1
        have := (lv_g_min ha hb (hypos t)).2 h2
        linarith
      · have := (lv_g_min hc hd (hxpos t)).2 h1
        have := (lv_g_min ha hb (hypos t)).1
        linarith
    exact ⟨1, one_pos, huniq 1 (by rw [(hall 1).1, (hall 0).1]) (by rw [(hall 1).2, (hall 0).2])⟩
  · -- away from the balance point: the path turns around it at a steady minimum rate
    have hHgt : c - c * Real.log (c / d) + (a - a * Real.log (a / b)) <
        d * x 0 - c * Real.log (x 0) + b * y 0 - a * Real.log (y 0) := by
      by_cases h1 : x 0 = c / d
      · have h2 : y 0 ≠ a / b := fun h2 => heq ⟨h1, h2⟩
        have := (lv_g_min hc hd (hxpos 0)).1
        have := (lv_g_min ha hb (hypos 0)).2 h2
        linarith
      · have := (lv_g_min hc hd (hxpos 0)).2 h1
        have := (lv_g_min ha hb (hypos 0)).1
        linarith
    have hne : ∀ t, ¬ (x t = c / d ∧ y t = a / b) := by
      intro t ht
      have h := hcons t
      rw [ht.1, ht.2] at h
      have : d * (c / d) = c := by field_simp
      have : b * (a / b) = a := by field_simp
      linarith
    have hr : ∀ t, 0 < (x t - c / d) ^ 2 + (y t - a / b) ^ 2 := by
      intro t
      by_contra h
      push Not at h
      have hu : (x t - c / d) ^ 2 = 0 := by nlinarith [sq_nonneg (x t - c / d), sq_nonneg (y t - a / b)]
      have hv : (y t - a / b) ^ 2 = 0 := by nlinarith [sq_nonneg (x t - c / d), sq_nonneg (y t - a / b)]
      apply hne t
      constructor
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 hu; linarith
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 hv; linarith
    obtain ⟨ω, hω⟩ : ∃ ω : ℝ → ℝ, ∀ t, ω t = (d * y t * (x t - c / d) ^ 2 +
        b * x t * (y t - a / b) ^ 2) / ((x t - c / d) ^ 2 + (y t - a / b) ^ 2) :=
      ⟨_, fun t => rfl⟩
    obtain ⟨ρ, hρ⟩ : ∃ ρ : ℝ → ℝ, ∀ t, ρ t = ((d * y t - b * x t) * (x t - c / d) *
        (y t - a / b)) / ((x t - c / d) ^ 2 + (y t - a / b) ^ 2) :=
      ⟨_, fun t => rfl⟩
    have hωc : Continuous ω := by
      have : ω = fun t => (d * y t * (x t - c / d) ^ 2 +
        b * x t * (y t - a / b) ^ 2) / ((x t - c / d) ^ 2 + (y t - a / b) ^ 2) := funext hω
      rw [this]
      exact Continuous.div (by fun_prop) (by fun_prop) (fun t => (hr t).ne')
    have hρc : Continuous ρ := by
      have : ρ = fun t => ((d * y t - b * x t) * (x t - c / d) *
        (y t - a / b)) / ((x t - c / d) ^ 2 + (y t - a / b) ^ 2) := funext hρ
      rw [this]
      exact Continuous.div (by fun_prop) (by fun_prop) (fun t => (hr t).ne')
    set κ := min d b * m with hκ
    have hκpos : 0 < κ := mul_pos (lt_min hd hb) hm
    have hωκ : ∀ t, κ ≤ ω t := by
      intro t
      rw [hω t, le_div_iff₀ (hr t)]
      obtain ⟨h1, -, h3, -⟩ := hbox t
      have k1 : κ ≤ d * y t := by
        calc κ ≤ d * m := mul_le_mul_of_nonneg_right (min_le_left _ _) hm.le
          _ ≤ d * y t := mul_le_mul_of_nonneg_left h3 hd.le
      have k2 : κ ≤ b * x t := by
        calc κ ≤ b * m := mul_le_mul_of_nonneg_right (min_le_right _ _) hm.le
          _ ≤ b * x t := mul_le_mul_of_nonneg_left h1 hb.le
      nlinarith [mul_le_mul_of_nonneg_right k1 (sq_nonneg (x t - c / d)),
        mul_le_mul_of_nonneg_right k2 (sq_nonneg (y t - a / b))]
    obtain ⟨Θ, hΘdef⟩ : ∃ Θ : ℝ → ℝ, ∀ t, Θ t = ∫ s in (0:ℝ)..t, ω s := ⟨_, fun t => rfl⟩
    have hΘ : ∀ t, HasDerivAt Θ (ω t) t := by
      have : Θ = fun t => ∫ s in (0:ℝ)..t, ω s := funext hΘdef
      rw [this]
      exact fun t => (hωc.integral_hasStrictDerivAt 0 t).hasDerivAt
    have hΘc : Continuous Θ := continuous_iff_continuousAt.2 fun t => (hΘ t).continuousAt
    have hΘ0 : Θ 0 = 0 := by rw [hΘdef]; simp
    set τ := 2 * π / κ with hτ
    have hτpos : 0 < τ := div_pos two_pi_pos hκpos
    have hΘτ : 2 * π ≤ Θ τ := by
      rw [hΘdef]
      have := intervalIntegral.integral_mono_on (μ := MeasureTheory.volume) (f := fun _ => κ)
        hτpos.le intervalIntegrable_const
        (hωc.intervalIntegrable 0 τ) (fun t _ => hωκ t)
      rw [intervalIntegral.integral_const, smul_eq_mul, sub_zero, hτ,
        div_mul_cancel₀ _ hκpos.ne'] at this
      exact this
    obtain ⟨T, ⟨hT0, -⟩, hΘT⟩ := intermediate_value_Icc hτpos.le hΘc.continuousOn
      (show 2 * π ∈ Set.Icc (Θ 0) (Θ τ) from ⟨by rw [hΘ0]; exact two_pi_pos.le, hΘτ⟩)
    have hTpos : 0 < T := by
      rcases hT0.lt_or_eq with h | h
      · exact h
      · rw [← h, hΘ0] at hΘT; linarith [two_pi_pos]
    -- the path, seen from a frame turning with angle Θ, only stretches along its starting ray
    have hU : ∀ t, HasDerivAt
        (fun t => Real.cos (Θ t) * (x t - c / d) + Real.sin (Θ t) * (y t - a / b))
        (ρ t * (Real.cos (Θ t) * (x t - c / d) + Real.sin (Θ t) * (y t - a / b))) t := by
      intro t
      have h := (((hΘ t).cos).mul ((hx t).sub_const (c / d))).add
        (((hΘ t).sin).mul ((hy t).sub_const (a / b)))
      convert h using 1
      have hba : b * (a / b) = a := by field_simp
      have hdc : d * (c / d) = c := by field_simp
      have e1 : a * x t - b * x t * y t = -b * x t * (y t - a / b) := by
        linear_combination (-(x t)) * hba
      have e2 : -c * y t + d * x t * y t = d * y t * (x t - c / d) := by
        linear_combination (y t) * hdc
      rw [hω t, hρ t, e1, e2]
      have hr' := (hr t).ne'
      generalize x t - c / d = u at hr' ⊢
      generalize y t - a / b = v at hr' ⊢
      field_simp
      ring
    have hV : ∀ t, HasDerivAt
        (fun t => -Real.sin (Θ t) * (x t - c / d) + Real.cos (Θ t) * (y t - a / b))
        (ρ t * (-Real.sin (Θ t) * (x t - c / d) + Real.cos (Θ t) * (y t - a / b))) t := by
      intro t
      have h := ((((hΘ t).sin).neg).mul ((hx t).sub_const (c / d))).add
        (((hΘ t).cos).mul ((hy t).sub_const (a / b)))
      convert h using 1
      simp only [Pi.neg_apply]
      have hba : b * (a / b) = a := by field_simp
      have hdc : d * (c / d) = c := by field_simp
      have e1 : a * x t - b * x t * y t = -b * x t * (y t - a / b) := by
        linear_combination (-(x t)) * hba
      have e2 : -c * y t + d * x t * y t = d * y t * (x t - c / d) := by
        linear_combination (y t) * hdc
      rw [hω t, hρ t, e1, e2]
      have hr' := (hr t).ne'
      generalize x t - c / d = u at hr' ⊢
      generalize y t - a / b = v at hr' ⊢
      field_simp
      ring
    have hUs := lv_linear_sol hρc hU T
    have hVs := lv_linear_sol hρc hV T
    simp only [hΘT, hΘ0, Real.cos_two_pi, Real.sin_two_pi, Real.cos_zero, Real.sin_zero,
      one_mul, zero_mul, add_zero, zero_add, neg_zero] at hUs hVs
    set lam := Real.exp (∫ s in (0:ℝ)..T, ρ s) with hlam
    have hlampos : 0 < lam := Real.exp_pos _
    have hcT := hcons T
    have hlam1 : lam = 1 := by
      rcases lt_trichotomy lam 1 with h | h | h
      · exfalso
        have hr := lv_ray ha hb hc hd (hxpos 0) (hypos 0) heq hlampos h
        have ex : c / d + lam * (x 0 - c / d) = x T := by linarith
        have ey : a / b + lam * (y 0 - a / b) = y T := by linarith
        rw [ex, ey] at hr
        linarith
      · exact h
      · exfalso
        have hr := lv_ray ha hb hc hd (hxpos T) (hypos T) (hne T) (inv_pos.2 hlampos)
          (inv_lt_one_of_one_lt₀ h)
        have ex : c / d + lam⁻¹ * (x T - c / d) = x 0 := by
          rw [hUs]; field_simp; ring
        have ey : a / b + lam⁻¹ * (y T - a / b) = y 0 := by
          rw [hVs]; field_simp; ring
        rw [ex, ey] at hr
        linarith
    rw [hlam1] at hUs hVs
    exact ⟨T, hTpos, huniq T (by linarith) (by linarith)⟩

#print axioms lv_linear_sol
#print axioms lv_g_min
#print axioms lv_conserved
#print axioms lv_lap_average
#print axioms lv_ray
#print axioms lv_bounds
#print axioms lv_periodic

/-- **Cycles that never die out.** Take any positive rates a (prey births), b (prey lost per
meeting), c (predator deaths) and d (predators born per meeting), all fixed in time. Let the
prey count x(t) and the predator count y(t) be defined for every time t and follow the
Lotka-Volterra laws x' = a·x − b·x·y and y' = −c·y + d·x·y, starting from positive counts.
Then:
1. both counts stay positive forever (neither species dies out);
2. the hidden quantity d·x − c·ln x + b·y − a·ln y never changes along the path;
3. the path is a closed loop: there is a lap time T > 0 after which both counts repeat exactly,
   forever;
4. over that lap the prey average exactly c/d and the predators exactly a/b, the balance point. -/
theorem lotka_volterra_closed_cycles_average_to_balance
    {a b c d : ℝ} (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) (hd : 0 < d)
    {x y : ℝ → ℝ}
    (hx : ∀ t, HasDerivAt x (a * x t - b * x t * y t) t)
    (hy : ∀ t, HasDerivAt y (-c * y t + d * x t * y t) t)
    (hx0 : 0 < x 0) (hy0 : 0 < y 0) :
    (∀ t, 0 < x t ∧ 0 < y t) ∧
    (∀ t, d * x t - c * Real.log (x t) + b * y t - a * Real.log (y t) =
        d * x 0 - c * Real.log (x 0) + b * y 0 - a * Real.log (y 0)) ∧
    ∃ T > 0, (∀ t, x (t + T) = x t ∧ y (t + T) = y t) ∧
      (∫ t in (0 : ℝ)..T, x t) / T = c / d ∧ (∫ t in (0 : ℝ)..T, y t) / T = a / b := by
  have hxc : Continuous x := continuous_iff_continuousAt.2 fun t => (hx t).continuousAt
  have hyc : Continuous y := continuous_iff_continuousAt.2 fun t => (hy t).continuousAt
  have hxpos : ∀ t, 0 < x t := by
    intro t
    rw [lv_linear_sol (k := fun t => a - b * y t) (continuous_const.sub (continuous_const.mul hyc))
      (fun t => (hx t).congr_deriv (by ring)) t]
    positivity
  have hypos : ∀ t, 0 < y t := by
    intro t
    rw [lv_linear_sol (k := fun t => -c + d * x t) (continuous_const.add (continuous_const.mul hxc))
      (fun t => (hy t).congr_deriv (by ring)) t]
    positivity
  obtain ⟨T, hT, hTper⟩ := lv_periodic ha hb hc hd hx hy hxpos hypos
  refine ⟨fun t => ⟨hxpos t, hypos t⟩, lv_conserved hx hy hxpos hypos, T, hT, hTper, ?_⟩
  have h0 := hTper 0
  simp only [zero_add] at h0
  exact lv_lap_average hb.ne' hd.ne' hx hy hxpos hypos hT h0.1 h0.2

/-- **The fixed quantity (Step 3).** For any positive rates a, b, c, d and any prey and predator
counts x(t), y(t) that are positive at every time and follow x' = a·x − b·x·y and
y' = −c·y + d·x·y, the quantity d·x − c·ln x + b·y − a·ln y has rate zero, so it keeps its
starting value at every time. -/
theorem lotka_volterra_conserved_quantity
    {a b c d : ℝ} {x y : ℝ → ℝ}
    (hx : ∀ t, HasDerivAt x (a * x t - b * x t * y t) t)
    (hy : ∀ t, HasDerivAt y (-c * y t + d * x t * y t) t)
    (hxpos : ∀ t, 0 < x t) (hypos : ∀ t, 0 < y t) (t : ℝ) :
    d * x t - c * Real.log (x t) + b * y t - a * Real.log (y t) =
      d * x 0 - c * Real.log (x 0) + b * y 0 - a * Real.log (y 0) := by
  exact lv_conserved hx hy hxpos hypos t

/-- **Lap averages equal the balance point (Step 5).** For any rates a, b, c, d with b and d
nonzero, and any positive prey and predator counts following x' = a·x − b·x·y and
y' = −c·y + d·x·y, if after a time T > 0 both counts are back where they started (one full lap),
then over that lap the prey average exactly c/d and the predators exactly a/b, whatever the
loop's size. -/
theorem lotka_volterra_lap_average_eq_balance
    {a b c d : ℝ} (hb : b ≠ 0) (hd : d ≠ 0) {x y : ℝ → ℝ}
    (hx : ∀ t, HasDerivAt x (a * x t - b * x t * y t) t)
    (hy : ∀ t, HasDerivAt y (-c * y t + d * x t * y t) t)
    (hxpos : ∀ t, 0 < x t) (hypos : ∀ t, 0 < y t)
    {T : ℝ} (hT : 0 < T) (hxT : x T = x 0) (hyT : y T = y 0) :
    (∫ t in (0 : ℝ)..T, x t) / T = c / d ∧ (∫ t in (0 : ℝ)..T, y t) / T = a / b := by
  exact lv_lap_average hb hd hx hy hxpos hypos hT hxT hyT

-- The card's rates are all 1: x' = x − x·y, y' = −y + x·y.
-- Rates at the start (2, 1): 0 for the gazelles and +1 for the cheetahs.
example : ((2 : ℤ) - 2 * 1, (-1 : ℤ) + 2 * 1) = (0, 1) := by decide
-- Both rates vanish at the two rests, the empty reserve (0, 0) and the balance point (1, 1).
example : ((0 : ℤ) - 0 * 0, (-0 : ℤ) + 0 * 0) = (0, 0) := by decide
example : ((1 : ℤ) - 1 * 1, (-1 : ℤ) + 1 * 1) = (0, 0) := by decide
-- The balance point (c/d, a/b) with every rate 1 is (1, 1): 100 gazelles and 10 cheetahs.
example : ((1 : ℚ) / 1, (1 : ℚ) / 1) = (1, 1) := by norm_num
-- Jacobian at (0, 0) is [[1, 0], [0, −1]]: trace 0, determinant −1, eigenvalues +1 and −1 (a saddle).
example : (1 : ℤ) + (-1) = 0 ∧ (1 : ℤ) * (-1) - 0 * 0 = -1 := by decide
-- Jacobian at (1, 1) is [[0, −1], [1, 0]]: trace 0, determinant 1, eigenvalues ±i (a linear centre).
example : (0 : ℤ) + 0 = 0 ∧ (0 : ℤ) * 0 - (-1) * 1 = 1 := by decide
-- The lowest value of the fixed quantity, at the balance point: H(1, 1) = 1 − ln 1 + 1 − ln 1 = 2.
example : (1 : ℝ) - Real.log 1 + 1 - Real.log 1 = 2 := by norm_num

#print axioms lotka_volterra_closed_cycles_average_to_balance
#print axioms lotka_volterra_conserved_quantity
#print axioms lotka_volterra_lap_average_eq_balance
