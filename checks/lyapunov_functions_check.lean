-- Lyapunov functions: a continuously differentiable score that is zero at a rest, positive near it and never rising along motions makes the rest stable, and if it strictly falls away from the rest nearby motions settle there.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Topology.Order.IntermediateValue

open Filter Topology Set

lemma lyap_exists_pos_lower_bound {X : Type*} [TopologicalSpace X] {K : Set X}
    (hK : IsCompact K) {g : X → ℝ} (hg : ContinuousOn g K) (hpos : ∀ y ∈ K, 0 < g y) :
    ∃ m > 0, ∀ y ∈ K, m ≤ g y := by
  rcases K.eq_empty_or_nonempty with h | h
  · exact ⟨1, one_pos, by simp [h]⟩
  · obtain ⟨y0, hy0, hmin⟩ := hK.exists_isMinOn h hg
    exact ⟨g y0, hpos y0 hy0, fun y hy => hmin hy⟩

lemma lyap_le_of_hasDerivWithinAt_nonpos {h h' : ℝ → ℝ} {T : ℝ} (hT : 0 ≤ T)
    (hd : ∀ s ∈ Icc 0 T, HasDerivWithinAt h (h' s) (Ici 0) s)
    (hneg : ∀ s ∈ Icc 0 T, h' s ≤ 0) : h T ≤ h 0 := by
  have hanti : AntitoneOn h (Icc 0 T) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc 0 T)
      (fun s hs => (hd s hs).continuousWithinAt.mono Icc_subset_Ici_self) ?_
      (fun s hs => hneg s (interior_subset hs))
    intro s hs
    refine (hd s (interior_subset hs)).mono ?_
    exact interior_subset.trans Icc_subset_Ici_self
  exact hanti ⟨le_refl 0, hT⟩ ⟨hT, le_refl T⟩ hT

lemma lyap_hasDerivWithinAt_comp {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)}
    {V : EuclideanSpace ℝ (Fin n) → ℝ} {xstar : EuclideanSpace ℝ (Fin n)} {r : ℝ}
    (hV : ContDiffOn ℝ 1 V (Metric.ball xstar r)) {x : ℝ → EuclideanSpace ℝ (Fin n)} {t : ℝ}
    (hx : HasDerivWithinAt x (f (x t)) (Ici 0) t) (hxt : x t ∈ Metric.ball xstar r) :
    HasDerivWithinAt (fun s => V (x s)) (inner ℝ (gradient V (x t)) (f (x t))) (Ici 0) t := by
  have hd : DifferentiableAt ℝ V (x t) :=
    (hV.differentiableOn one_ne_zero (x t) hxt).differentiableAt (Metric.isOpen_ball.mem_nhds hxt)
  have := hd.hasFDerivAt.comp_hasDerivWithinAt t hx
  have hg : inner ℝ (gradient V (x t)) (f (x t)) = (fderiv ℝ V (x t)) (f (x t)) := by
    rw [gradient, InnerProductSpace.toDual_symm_apply]
  rw [hg]
  exact this

lemma lyap_shift {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)}
    {x : ℝ → EuclideanSpace ℝ (Fin n)}
    (hx : ∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Ici 0) t) {T : ℝ} (hT : 0 ≤ T) :
    ∀ s ≥ 0, HasDerivWithinAt (fun u => x (u + T)) (f (x (s + T))) (Ici 0) s := by
  intro s hs
  have h1 : HasDerivWithinAt (fun u : ℝ => u + T) 1 (Ici 0) s :=
    ((hasDerivAt_id s).add_const T).hasDerivWithinAt
  have h2 := (hx (s + T) (by linarith)).scomp s h1 (fun u (hu : u ∈ Ici 0) => by
    simp only [mem_Ici] at hu ⊢; linarith)
  rw [one_smul] at h2; exact h2

lemma lyap_inner_continuousOn {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)}
    {V : EuclideanSpace ℝ (Fin n) → ℝ} {xstar : EuclideanSpace ℝ (Fin n)} {r : ℝ}
    (hf : ContDiffOn ℝ 1 f (Metric.ball xstar r))
    (hV : ContDiffOn ℝ 1 V (Metric.ball xstar r)) :
    ContinuousOn (fun y => inner ℝ (gradient V y) (f y)) (Metric.ball xstar r) := by
  have hg : ContinuousOn (gradient V) (Metric.ball xstar r) := by
    have := hV.continuousOn_fderiv_of_isOpen Metric.isOpen_ball le_rfl
    exact (InnerProductSpace.toDual ℝ _).symm.continuous.comp_continuousOn this
  exact hg.inner hf.continuousOn

#print axioms lyap_exists_pos_lower_bound
#print axioms lyap_le_of_hasDerivWithinAt_nonpos
#print axioms lyap_hasDerivWithinAt_comp
#print axioms lyap_shift
#print axioms lyap_inner_continuousOn


/-- Lyapunov's direct method, stability part. Take a rate law `x' = f x` on `ℝⁿ` with a rest
`xstar` (`f xstar = 0`). Suppose that on a ball of radius `r` about the rest, `V` and `f` have
continuous slopes, `V` is zero at the rest and positive at every other point, and the rate of `V`
along the motion, `∇V · f`, is never positive. Then the rest is stable: for any allowed distance
`ε`, every motion that starts within some `δ` of the rest stays within `ε` of it for all later
times. -/
theorem lyapunov_stable {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (V : EuclideanSpace ℝ (Fin n) → ℝ) (xstar : EuclideanSpace ℝ (Fin n)) (r : ℝ) (hr : 0 < r)
    (hrest : f xstar = 0)
    (hf : ContDiffOn ℝ 1 f (Metric.ball xstar r))
    (hV : ContDiffOn ℝ 1 V (Metric.ball xstar r))
    (hV0 : V xstar = 0)
    (hVpos : ∀ x ∈ Metric.ball xstar r, x ≠ xstar → 0 < V x)
    (hVdot : ∀ x ∈ Metric.ball xstar r, inner ℝ (gradient V x) (f x) ≤ 0) :
    ∀ ε > 0, ∃ δ > 0, ∀ x : ℝ → EuclideanSpace ℝ (Fin n),
      (∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Ici 0) t) →
      dist (x 0) xstar < δ → ∀ t ≥ 0, dist (x t) xstar < ε := by
  intro ε hε
  set ρ := min ε (r / 2) with hρdef
  have hρ : 0 < ρ := lt_min hε (by linarith)
  have hρr : ρ < r := lt_of_le_of_lt (min_le_right _ _) (by linarith)
  have hρε : ρ ≤ ε := min_le_left _ _
  have hsph : Metric.sphere xstar ρ ⊆ Metric.ball xstar r := fun y hy => by
    rw [Metric.mem_sphere] at hy; rw [Metric.mem_ball]; linarith
  obtain ⟨m, hm, hmV⟩ : ∃ m > 0, ∀ y ∈ Metric.sphere xstar ρ, m ≤ V y :=
    lyap_exists_pos_lower_bound (isCompact_sphere _ _) (hV.continuousOn.mono hsph)
      (fun y hy => hVpos y (hsph hy) (by
        rintro rfl; rw [Metric.mem_sphere, dist_self] at hy; linarith))
  have hVc : ContinuousAt V xstar :=
    hV.continuousOn.continuousAt (Metric.isOpen_ball.mem_nhds (Metric.mem_ball_self hr))
  obtain ⟨δ0, hδ0, hδ0V⟩ := Metric.continuousAt_iff.mp hVc m hm
  refine ⟨min δ0 ρ, lt_min hδ0 hρ, ?_⟩
  intro x hx h0
  have h0ρ : dist (x 0) xstar < ρ := lt_of_lt_of_le h0 (min_le_right _ _)
  have hV0m : V (x 0) < m := by
    have := hδ0V (lt_of_lt_of_le h0 (min_le_left _ _))
    rw [hV0, Real.dist_eq, sub_zero] at this
    exact lt_of_le_of_lt (le_abs_self _) this
  suffices hsuff : ∀ t ≥ 0, dist (x t) xstar < ρ from
    fun t ht => lt_of_lt_of_le (hsuff t ht) hρε
  intro t ht
  by_contra hcon
  rw [not_lt] at hcon
  have hxc : ContinuousOn x (Ici 0) := fun s hs => (hx s hs).continuousWithinAt
  have hgc : ContinuousOn (fun s => dist (x s) xstar) (Ici 0) :=
    (continuous_id.dist continuous_const).comp_continuousOn hxc
  set A := Icc 0 t ∩ (fun s => dist (x s) xstar) ⁻¹' Ici ρ with hAdef
  have hAc : IsClosed A :=
    (hgc.mono Icc_subset_Ici_self).preimage_isClosed_of_isClosed isClosed_Icc isClosed_Ici
  have htA : t ∈ A := ⟨⟨ht, le_refl t⟩, hcon⟩
  have hAne : A.Nonempty := ⟨t, htA⟩
  have hAbdd : BddBelow A := ⟨0, fun s hs => hs.1.1⟩
  set t1 := sInf A with ht1def
  have ht1A : t1 ∈ A := hAc.csInf_mem hAne hAbdd
  have ht1le : ∀ s ∈ A, t1 ≤ s := fun s hs => csInf_le hAbdd hs
  have ht10 : 0 ≤ t1 := ht1A.1.1
  have ht1t : t1 ≤ t := ht1A.1.2
  -- before t1 the motion is strictly inside the sphere
  have hbefore : ∀ s ∈ Icc 0 t1, s < t1 → dist (x s) xstar < ρ := by
    intro s hs hst
    by_contra hc
    rw [not_lt] at hc
    have : t1 ≤ s := ht1le s ⟨⟨hs.1, hs.2.trans ht1t⟩, hc⟩
    linarith
  -- at t1 the motion is exactly on the sphere
  have hat : dist (x t1) xstar = ρ := by
    have hivt := intermediate_value_Icc ht10 (hgc.mono Icc_subset_Ici_self)
    obtain ⟨s, hs, hsρ⟩ := hivt ⟨h0ρ.le, ht1A.2⟩
    have hsA : s ∈ A := ⟨⟨hs.1, hs.2.trans ht1t⟩, by
      exact le_of_eq hsρ.symm⟩
    have := ht1le s hsA
    have hst : s = t1 := le_antisymm hs.2 this
    rw [← hst]; exact hsρ
  have hinball : ∀ s ∈ Icc 0 t1, x s ∈ Metric.ball xstar r := by
    intro s hs
    rw [Metric.mem_ball]
    rcases lt_or_eq_of_le hs.2 with hlt | heq
    · linarith [hbefore s hs hlt]
    · rw [heq, hat]; exact hρr
  have hmono : V (x t1) ≤ V (x 0) :=
    lyap_le_of_hasDerivWithinAt_nonpos ht10
      (fun s hs => lyap_hasDerivWithinAt_comp hV (hx s hs.1) (hinball s hs))
      (fun s hs => hVdot (x s) (hinball s hs))
  have hmt1 : m ≤ V (x t1) := hmV (x t1) (by rw [Metric.mem_sphere]; exact hat)
  linarith

/-- Lyapunov's direct method, settling part. Under the same conditions, if moreover the rate
`∇V · f` is strictly negative at every point of the ball except the rest, then the rest is
asymptotically stable: it is stable, and every motion that starts close enough tends to the rest
as time goes to infinity. -/
theorem lyapunov_asymptotically_stable {n : ℕ}
    (f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (V : EuclideanSpace ℝ (Fin n) → ℝ) (xstar : EuclideanSpace ℝ (Fin n)) (r : ℝ) (hr : 0 < r)
    (hrest : f xstar = 0)
    (hf : ContDiffOn ℝ 1 f (Metric.ball xstar r))
    (hV : ContDiffOn ℝ 1 V (Metric.ball xstar r))
    (hV0 : V xstar = 0)
    (hVpos : ∀ x ∈ Metric.ball xstar r, x ≠ xstar → 0 < V x)
    (hVdot : ∀ x ∈ Metric.ball xstar r, x ≠ xstar → inner ℝ (gradient V x) (f x) < 0) :
    (∀ ε > 0, ∃ δ > 0, ∀ x : ℝ → EuclideanSpace ℝ (Fin n),
      (∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Ici 0) t) →
      dist (x 0) xstar < δ → ∀ t ≥ 0, dist (x t) xstar < ε) ∧
    ∃ δ > 0, ∀ x : ℝ → EuclideanSpace ℝ (Fin n),
      (∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Ici 0) t) →
      dist (x 0) xstar < δ → Tendsto x atTop (𝓝 xstar) := by
  have hVdot' : ∀ x ∈ Metric.ball xstar r, inner ℝ (gradient V x) (f x) ≤ 0 := by
    intro y hy
    by_cases hyx : y = xstar
    · rw [hyx, hrest, inner_zero_right]
    · exact (hVdot y hy hyx).le
  have stab := lyapunov_stable f V xstar r hr hrest hf hV hV0 hVpos hVdot'
  refine ⟨stab, ?_⟩
  obtain ⟨δ, hδ, hδx⟩ := stab (r / 2) (by linarith)
  refine ⟨δ, hδ, fun x hx h0 => ?_⟩
  have hin : ∀ t ≥ 0, dist (x t) xstar < r / 2 := hδx x hx h0
  have hinball : ∀ t ≥ 0, x t ∈ Metric.ball xstar r := fun t ht => by
    rw [Metric.mem_ball]; linarith [hin t ht]
  have hVnn : ∀ t ≥ 0, 0 ≤ V (x t) := by
    intro t ht
    by_cases hxt : x t = xstar
    · rw [hxt, hV0]
    · exact (hVpos _ (hinball t ht) hxt).le
  -- the motion comes arbitrarily close to the rest
  have key : ∀ η > 0, ∃ T ≥ 0, dist (x T) xstar < η := by
    intro η hη
    by_contra hcon
    have hfar : ∀ T ≥ 0, η ≤ dist (x T) xstar := by
      intro T hT
      by_contra h
      exact hcon ⟨T, hT, lt_of_not_ge h⟩
    set K := Metric.closedBall xstar (r / 2) \ Metric.ball xstar η with hKdef
    have hKc : IsCompact K := (isCompact_closedBall _ _).diff Metric.isOpen_ball
    have hKball : K ⊆ Metric.ball xstar r := fun y hy => by
      have := hy.1; rw [Metric.mem_closedBall] at this; rw [Metric.mem_ball]; linarith
    obtain ⟨c, hc, hcK⟩ : ∃ c > 0, ∀ y ∈ K, c ≤ -inner ℝ (gradient V y) (f y) :=
      lyap_exists_pos_lower_bound hKc
        ((lyap_inner_continuousOn hf hV).neg.mono hKball)
        (fun y hy => by
          have hne : y ≠ xstar := by
            rintro rfl
            exact hy.2 (Metric.mem_ball_self hη)
          linarith [hVdot y (hKball hy) hne])
    have hxK : ∀ t ≥ 0, x t ∈ K := fun t ht =>
      ⟨by rw [Metric.mem_closedBall]; linarith [hin t ht],
       by rw [Metric.mem_ball, not_lt]; exact hfar t ht⟩
    set T := V (x 0) / c + 1 with hTdef
    have hT0 : 0 ≤ T := by
      have := hVnn 0 le_rfl
      positivity
    have hdec : V (x T) + c * T ≤ V (x 0) + c * 0 := by
      refine lyap_le_of_hasDerivWithinAt_nonpos (h := fun s => V (x s) + c * s)
        (h' := fun s => inner ℝ (gradient V (x s)) (f (x s)) + c) hT0 ?_ ?_
      · intro s hs
        have h1 := lyap_hasDerivWithinAt_comp hV (hx s hs.1) (hinball s hs.1)
        have h2 : HasDerivWithinAt (fun u : ℝ => c * u) c (Ici 0) s := by
          simpa using ((hasDerivAt_id s).const_mul c).hasDerivWithinAt
        exact h1.add h2
      · intro s hs
        have := hcK (x s) (hxK s hs.1)
        show inner ℝ (gradient V (x s)) (f (x s)) + c ≤ 0
        linarith
    have hcT : c * T = V (x 0) + c := by
      rw [hTdef]; field_simp
    have := hVnn T hT0
    nlinarith
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨δ', hδ', hδ'x⟩ := stab ε hε
  obtain ⟨T, hT, hTd⟩ := key δ' hδ'
  refine ⟨T, fun t ht => ?_⟩
  have := hδ'x (fun u => x (u + T)) (lyap_shift hx hT) (by simpa using hTd) (t - T) (by linarith)
  simpa using this

/-- The honey bowl `x' = -x^3`, solved by separating variables: from any start `x0`, the motion
`x t = x0 / √(1 + 2 x0² t)` (that is, `1/x² = 1/x0² + 2t`) obeys the rate law at every time
`t ≥ 0`, the score `V = x²/2` obeys `1/V = 1/V0 + 4t` (for `x0 ≠ 0`), and the ball tends to the
bottom. -/
theorem honey_bowl_settles (x0 : ℝ) :
    (∀ t : ℝ, 0 ≤ t →
      HasDerivAt (fun s => x0 / Real.sqrt (1 + 2 * x0 ^ 2 * s))
        (-(x0 / Real.sqrt (1 + 2 * x0 ^ 2 * t)) ^ 3) t) ∧
    (x0 ≠ 0 → ∀ t : ℝ, 0 ≤ t →
      1 / ((x0 / Real.sqrt (1 + 2 * x0 ^ 2 * t)) ^ 2 / 2) = 1 / (x0 ^ 2 / 2) + 4 * t) ∧
    Tendsto (fun s => x0 / Real.sqrt (1 + 2 * x0 ^ 2 * s)) atTop (𝓝 0) := by
  have hu : ∀ t : ℝ, 0 ≤ t → 0 < 1 + 2 * x0 ^ 2 * t := fun t ht => by positivity
  refine ⟨?_, ?_, ?_⟩
  · intro t ht
    have hpos := hu t ht
    have h1 : HasDerivAt (fun s : ℝ => 1 + 2 * x0 ^ 2 * s) (2 * x0 ^ 2) t := by
      simpa using ((hasDerivAt_id t).const_mul (2 * x0 ^ 2)).const_add 1
    have h2 := h1.sqrt hpos.ne'
    have h3 := (hasDerivAt_const t x0).div h2 (Real.sqrt_pos.mpr hpos).ne'
    convert h3 using 1
    have hs : Real.sqrt (1 + 2 * x0 ^ 2 * t) ^ 2 = 1 + 2 * x0 ^ 2 * t := Real.sq_sqrt hpos.le
    have hsp : 0 < Real.sqrt (1 + 2 * x0 ^ 2 * t) := Real.sqrt_pos.mpr hpos
    field_simp
    ring
  · intro hx0 t ht
    have hpos := hu t ht
    rw [div_pow, Real.sq_sqrt hpos.le]
    field_simp
    ring
  · rcases eq_or_ne x0 0 with h | h
    · subst h
      simp
    · have hlin : Tendsto (fun s : ℝ => 1 + 2 * x0 ^ 2 * s) atTop atTop :=
        tendsto_atTop_add_const_left _ 1 (tendsto_id.const_mul_atTop (by positivity))
      exact Tendsto.div_atTop tendsto_const_nhds (Real.tendsto_sqrt_atTop.comp hlin)

-- Worked numbers, by hand (honey bowl from 1 cm).
-- The candidate V = x²/2 at 1 cm is 1/2.
example : ((1 : ℚ) ^ 2 / 2) = 1 / 2 := by norm_num
-- Rate of V, -x⁴, at 1, 0.5 and 0.2 cm: -1, -0.0625, -0.0016.
example : -((1 : ℚ) ^ 4) = -1 := by norm_num
example : -((1 / 2 : ℚ) ^ 4) = -625 / 10000 := by norm_num
example : -((1 / 5 : ℚ) ^ 4) = -16 / 10000 := by norm_num
-- At 4 s: 1/x² = 1 + 2 × 4 = 9, so x = 1/3 cm.
example : (1 : ℚ) + 2 * 4 = 9 ∧ (1 / 3 : ℚ) ^ 2 = 1 / 9 := by norm_num
-- At 12 s: 1/x² = 1 + 2 × 12 = 25, so x = 1/5 cm = 0.2 cm.
example : (1 : ℚ) + 2 * 12 = 25 ∧ (1 / 5 : ℚ) ^ 2 = 1 / 25 := by norm_num
-- V by its own law: 1/V = 2 + 4 × 12 = 50, so V = 0.02; it matches x²/2 at x = 1/5.
example : (2 : ℚ) + 4 * 12 = 50 ∧ (1 / 5 : ℚ) ^ 2 / 2 = 1 / 50 := by norm_num
-- Down to 0.1 cm: 100 = 1 + 2t gives t = 49.5 s.
example : (1 : ℚ) + 2 * (99 / 2) = 100 ∧ (99 / 2 : ℚ) = 495 / 10 := by norm_num
-- Frictionless energy E = x⁴/4 + y²/2 from rest at 1 cm is 0.25.
example : (1 : ℚ) ^ 4 / 4 + 0 ^ 2 / 2 = 25 / 100 := by norm_num

#print axioms lyapunov_stable
#print axioms lyapunov_asymptotically_stable
#print axioms honey_bowl_settles
