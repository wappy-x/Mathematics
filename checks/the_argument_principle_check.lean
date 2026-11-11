-- The argument principle: for a function holomorphic on and inside a circle except at poles, with no zero or pole on the circle and not identically zero, the loop integral of f′/f divided by 2πi, and the needle's total turn along the walk counted in whole turns, both equal the zeros inside minus the poles inside, each counted by its multiplicity or order.
import Mathlib.Analysis.Meromorphic.Divisor
import Mathlib.Analysis.Calculus.LogDeriv
import Mathlib.Analysis.SpecialFunctions.Complex.CircleMap
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Meromorphic.FactorizedRational
import Mathlib.Analysis.Normed.Module.Ball.Pointwise
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.MetricSpace.Thickening

/-! The plane is `ℂ`; `I` is i. The loop C is the circle `|z - c| = R`, walked once
anticlockwise: `circleMap c R t = c + R e^(it)` for `0 ≤ t ≤ 2π`, and `∮ z in C(c, R), F z` is the
loop integral of `F` round it. `logDeriv f z = deriv f z / f z` is the logarithmic derivative
f′/f. `MeromorphicOn f (closedBall c R)` says f is holomorphic on and inside the circle except at
isolated poles. `MeromorphicOn.divisor f (closedBall c R) a` is the whole number m at a zero of
multiplicity m, −p at a pole of order p, and 0 elsewhere; its positive part `⁺` counts zeros and
its negative part `⁻` counts poles. `ball c R` is the inside of the circle. -/

namespace TheArgumentPrinciple

open Complex Metric Set

theorem circleIntegral_logDeriv_eq_zero_aux {g : ℂ → ℂ} {c : ℂ} {r : ℝ} (hr : 0 ≤ r)
    (hg : ∀ z ∈ closedBall c r, AnalyticAt ℂ g z ∧ g z ≠ 0) :
    (∮ z in C(c, r), logDeriv g z) = 0 := by
  have hd : ∀ z ∈ closedBall c r, DifferentiableAt ℂ (logDeriv g) z := fun z hz => by
    obtain ⟨ha, hne⟩ := hg z hz
    exact ha.deriv.differentiableAt.div ha.differentiableAt hne
  exact circleIntegral_eq_zero_of_differentiable_on_off_countable hr Set.countable_empty
    (fun z hz => (hd z hz).continuousAt.continuousWithinAt)
    (fun z hz => hd z (ball_subset_closedBall hz.1))

open Classical in
theorem circleIntegral_sub_inv_aux {c u : ℂ} {r : ℝ} (hr : 0 < r) (hu : u ∉ sphere c r) :
    (∮ z in C(c, r), (z - u)⁻¹) = if u ∈ ball c r then 2 * Real.pi * I else 0 := by
  split_ifs with h
  · exact circleIntegral.integral_sub_inv_of_mem_ball h
  · have hu' : u ∉ closedBall c r := by
      intro h'
      rcases (mem_closedBall.1 h').lt_or_eq with h1 | h1
      · exact h (mem_ball.2 h1)
      · exact hu (mem_sphere.2 h1)
    have hd : ∀ z ∈ closedBall c r, DifferentiableAt ℂ (fun z => (z - u)⁻¹) z := fun z hz =>
      (differentiableAt_id.sub_const u).inv (sub_ne_zero.2 fun h => hu' (h ▸ hz))
    exact circleIntegral_eq_zero_of_differentiable_on_off_countable hr.le Set.countable_empty
      (fun z hz => (hd z hz).continuousAt.continuousWithinAt)
      (fun z hz => hd z (ball_subset_closedBall hz.1))

open Classical in
theorem circleIntegral_formula_aux {F g : ℂ → ℂ} {c : ℂ} {r : ℝ} (hr : 0 < r) (s : Finset ℂ)
    (D : ℂ → ℤ) (hs : ∀ u ∈ s, u ∉ sphere c r)
    (hg : ∀ z ∈ closedBall c r, AnalyticAt ℂ g z ∧ g z ≠ 0)
    (hF : ∀ z ∈ sphere c r, F z = ∑ u ∈ s, (D u : ℂ) * (z - u)⁻¹ + logDeriv g z) :
    (2 * Real.pi * I)⁻¹ * (∮ z in C(c, r), F z)
      = ∑ u ∈ s, if u ∈ ball c r then (D u : ℂ) else 0 := by
  have hc : ∀ u ∈ s, ContinuousOn (fun z : ℂ => (D u : ℂ) * (z - u)⁻¹) (sphere c r) :=
    fun u hu => continuousOn_const.mul ((continuousOn_id.sub continuousOn_const).inv₀
      fun z hz h => hs u hu (by have : z = u := sub_eq_zero.1 h; exact this ▸ hz))
  have hgc : ContinuousOn (logDeriv g) (sphere c r) := fun z hz => by
    obtain ⟨ha, hne⟩ := hg z (sphere_subset_closedBall hz)
    exact (ha.deriv.continuousAt.div ha.continuousAt hne).continuousWithinAt
  rw [circleIntegral.integral_congr hr.le hF, circleIntegral.integral_add
    (ContinuousOn.circleIntegrable hr.le (continuousOn_finsetSum _ hc))
    (hgc.circleIntegrable hr.le),
    circleIntegral.integral_fun_sum (fun u hu => (hc u hu).circleIntegrable hr.le),
    circleIntegral_logDeriv_eq_zero_aux hr.le hg, add_zero, Finset.mul_sum]
  refine Finset.sum_congr rfl fun u hu => ?_
  rw [circleIntegral.integral_const_mul, circleIntegral_sub_inv_aux hr (hs u hu)]
  have h2 : (2 * (Real.pi : ℂ) * I) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  split_ifs
  · field_simp
  · simp


open Classical in
theorem finsum_divisor_aux {f : ℂ → ℂ} {c : ℂ} {R : ℝ} {K : Set ℂ} (s : Finset ℂ)
    (hmero : MeromorphicOn f (closedBall c R)) (hmK : MeromorphicOn f K)
    (hBK : ball c R ⊆ K) (hs : ∀ a, MeromorphicOn.divisor f K a ≠ 0 → a ∈ s) :
    ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) : ℂ)
        - ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) : ℂ)
      = ∑ u ∈ s, if u ∈ ball c R then (MeromorphicOn.divisor f K u : ℂ) else 0 := by
  have hDD : ∀ a ∈ ball c R,
      MeromorphicOn.divisor f (closedBall c R) a = MeromorphicOn.divisor f K a := fun a ha => by
    rw [hmero.divisor_apply (ball_subset_closedBall ha), hmK.divisor_apply (hBK ha)]
  have key : ∀ F : ℤ → ℤ, F 0 = 0 →
      (∑ᶠ a ∈ ball c R, F (MeromorphicOn.divisor f (closedBall c R) a))
        = ∑ u ∈ s, if u ∈ ball c R then F (MeromorphicOn.divisor f K u) else 0 := by
    intro F hF0
    rw [finsum_mem_def, finsum_eq_sum_of_support_subset _ (s := s)]
    · refine Finset.sum_congr rfl fun u _ => ?_
      rw [Set.indicator_apply]
      split_ifs with h
      · rw [hDD u h]
      · rfl
    · intro a ha
      rw [Function.mem_support, Set.indicator_apply] at ha
      split_ifs at ha with hb
      · apply hs
        intro h0
        rw [hDD a hb, h0, hF0] at ha
        exact ha rfl
      · exact absurd rfl ha
  rw [key (fun x => x⁺) (by simp), key (fun x => x⁻) (by simp)]
  push_cast
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun u _ => ?_
  split_ifs
  · rw [← Int.cast_sub, posPart_sub_negPart]
  · simp

#print axioms finsum_divisor_aux

theorem int_ne_add_half_aux (m n : ℤ) : (m : ℝ) ≠ n + 1 / 2 := by
  intro h
  have h' : ((2 * m : ℤ) : ℝ) = ((2 * n + 1 : ℤ) : ℝ) := by push_cast; linarith
  have := Int.cast_injective h'
  omega

#print axioms int_ne_add_half_aux

#print axioms circleIntegral_logDeriv_eq_zero_aux
#print axioms circleIntegral_sub_inv_aux
#print axioms circleIntegral_formula_aux

/-- **The argument principle, as a loop integral.** Let C be the circle `|z - c| = R`, walked once
anticlockwise. Let f be holomorphic (have a complex derivative) inside and on C except at poles,
with no zero or pole on C (f is holomorphic and nonzero at every point of C), and f not
identically zero. Let N be the number of zeros inside C, each counted by its multiplicity, and P
the number of poles inside C, each counted by its order. Then
`(1/2πi) ∮_C f′(z)/f(z) dz = N − P`. -/
theorem loop_integral_of_log_deriv_eq_zeros_sub_poles
    (f : ℂ → ℂ) (c : ℂ) (R : ℝ) (hR : 0 < R)
    (hmero : MeromorphicOn f (closedBall c R))
    (hC : ∀ z ∈ sphere c R, AnalyticAt ℂ f z ∧ f z ≠ 0)
    (hne : ∃ z ∈ closedBall c R, f z ≠ 0) :
    (2 * Real.pi * I)⁻¹ * (∮ z in C(c, R), logDeriv f z)
      = ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) : ℂ)
        - ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) : ℂ) := by
  -- enlarge the closed disc to a slightly bigger one on which f is still meromorphic
  set V := ball c R ∪ {z | AnalyticAt ℂ f z} with hV
  have hVo : IsOpen V := isOpen_ball.union (isOpen_analyticAt ℂ f)
  have hKV : closedBall c R ⊆ V := by
    intro z hz
    rcases (mem_closedBall.1 hz).lt_or_eq with h | h
    · exact Or.inl (mem_ball.2 h)
    · exact Or.inr (hC z (mem_sphere.2 h)).1
  obtain ⟨δ, hδ, hδV⟩ := (isCompact_closedBall c R).exists_thickening_subset_open hVo hKV
  rw [thickening_closedBall hδ hR.le] at hδV
  have hRR' : R < R + δ / 2 := by linarith
  have hK'V : closedBall c (R + δ / 2) ⊆ V :=
    (closedBall_subset_ball (by linarith : R + δ / 2 < δ + R)).trans hδV
  set K := closedBall c (R + δ / 2) with hK
  have hmK : MeromorphicOn f K := fun z hz => by
    rcases hK'V hz with h | h
    · exact hmero z (ball_subset_closedBall h)
    · exact (show AnalyticAt ℂ f z from h).meromorphicAt
  have hord0 : ∀ z ∈ sphere c R, meromorphicOrderAt f z = 0 := fun z hz =>
    (hC z hz).1.meromorphicNFAt.meromorphicOrderAt_eq_zero_iff.2 (hC z hz).2
  obtain ⟨z0, hz0⟩ : (sphere c R).Nonempty := NormedSpace.sphere_nonempty.2 hR.le
  have hsphK : sphere c R ⊆ K :=
    sphere_subset_closedBall.trans (closedBall_subset_closedBall hRR'.le)
  have hBK : ball c R ⊆ K := ball_subset_closedBall.trans (closedBall_subset_closedBall hRR'.le)
  have hntop : ∀ u : K, meromorphicOrderAt f u ≠ ⊤ := fun u =>
    hmK.meromorphicOrderAt_ne_top_of_isPreconnected (convex_closedBall c _).isPreconnected
      (hsphK hz0) u.2 (by rw [hord0 z0 hz0]; exact WithTop.zero_ne_top)
  have hfin : (MeromorphicOn.divisor f K).support.Finite :=
    (MeromorphicOn.divisor f K).finiteSupport (isCompact_closedBall c _)
  obtain ⟨g, hg_an, hg_ne, hfg⟩ := hmK.extract_zeros_poles hntop hfin
  set D := MeromorphicOn.divisor f K with hD
  have hD0 : ∀ z ∈ sphere c R, D z = 0 := fun z hz => by
    rw [hD, hmK.divisor_apply (hsphK hz), hord0 z hz]; rfl
  set s := hfin.toFinset with hs
  have hsph : ∀ u ∈ s, u ∉ sphere c R := fun u hu hu' => by
    rw [hs, Set.Finite.mem_toFinset] at hu; exact hu (hD0 u hu')
  have hP : (∏ᶠ u, (· - u) ^ D u) = fun z => ∏ u ∈ s, (z - u) ^ D u := by
    rw [finprod_eq_prod_of_mulSupport_subset _ (s := s)
      (by rw [Function.FactorizedRational.mulSupport]; simp [s])]
    ext z; simp [Finset.prod_apply]
  have hkey : ∀ z ∈ sphere c R,
      logDeriv f z = ∑ u ∈ s, (D u : ℂ) * (z - u)⁻¹ + logDeriv g z := by
    intro z hz
    have hzK := hsphK hz
    have hzs : ∀ u ∈ s, z - u ≠ 0 := fun u hu h => hsph u hu (by
      have : z = u := sub_eq_zero.1 h
      exact this ▸ hz)
    set P : ℂ → ℂ := fun w => ∏ u ∈ s, (w - u) ^ D u with hPdef
    have hPd : DifferentiableAt ℂ P z :=
      DifferentiableAt.fun_finsetProd (f := fun u w => (w - u) ^ D u) fun u hu =>
        (differentiableAt_id.sub_const u).zpow (Or.inl (hzs u hu))
    have hPne : P z ≠ 0 := Finset.prod_ne_zero_iff.2 fun u hu => zpow_ne_zero _ (hzs u hu)
    have hzint : K ∈ nhds z := closedBall_mem_nhds_of_mem (mem_ball.2 (by
      have := mem_sphere.1 hz; linarith))
    have h1 : Filter.EventuallyEq (nhdsWithin z {z}ᶜ) f (fun w => P w * g w) := by
      filter_upwards [mem_codiscreteWithin_iff_forall_mem_nhdsNE.1 hfg z hzK,
        nhdsWithin_le_nhds hzint] with w hw hwK
      have := hw.resolve_right (not_not_intro hwK)
      simpa [hP, P] using this
    have hfe : Filter.EventuallyEq (nhds z) f (fun w => P w * g w) :=
      (ContinuousAt.eventuallyEq_nhds_iff_eventuallyEq_nhdsNE (hC z hz).1.continuousAt
        (hPd.continuousAt.mul (hg_an z hzK).continuousAt)).1 h1
    rw [(logDeriv_congr_nhds hfe).eq_of_nhds, logDeriv_fun_mul z hPne (hg_ne ⟨z, hzK⟩) hPd
      (hg_an z hzK).differentiableAt]
    congr 1
    rw [show P = ∏ u ∈ s, (fun w => (w - u) ^ D u) by ext w; simp [P, Finset.prod_apply],
      logDeriv_prod (f := fun u w => (w - u) ^ D u) (fun u hu => zpow_ne_zero _ (hzs u hu))
        (fun u hu => (differentiableAt_id.sub_const u).zpow (Or.inl (hzs u hu)))]
    refine Finset.sum_congr rfl fun u _ => ?_
    rw [logDeriv_fun_zpow (f := fun w => w - u) (differentiableAt_id.sub_const u)]
    simp [logDeriv_apply, div_eq_mul_inv]
  have hgK : ∀ z ∈ closedBall c R, AnalyticAt ℂ g z ∧ g z ≠ 0 := fun z hz =>
    have hz' : z ∈ K := closedBall_subset_closedBall hRR'.le hz
    ⟨hg_an z hz', hg_ne ⟨z, hz'⟩⟩
  rw [circleIntegral_formula_aux hR s D hsph hgK hkey,
    finsum_divisor_aux s hmero hmK hBK (fun a ha => by simpa [s] using ha)]

/-- **Walk the boundary and watch the needle spin.** Same hypotheses as above. Follow the value
f(z) as an arrow from 0 while z walks the circle once anticlockwise, and keep its angle φ
continuous: f(c + R e^(it)) = |f(c + R e^(it))| e^(iφ(t)) for `0 ≤ t ≤ 2π`. Such a continuous angle
exists, and every such angle has total change `φ(2π) − φ(0) = 2π (N − P)`: the needle turns
exactly N − P times round 0. -/
theorem needle_turns_eq_zeros_sub_poles
    (f : ℂ → ℂ) (c : ℂ) (R : ℝ) (hR : 0 < R)
    (hmero : MeromorphicOn f (closedBall c R))
    (hC : ∀ z ∈ sphere c R, AnalyticAt ℂ f z ∧ f z ≠ 0)
    (hne : ∃ z ∈ closedBall c R, f z ≠ 0) :
    (∃ φ : ℝ → ℝ, ContinuousOn φ (Icc 0 (2 * Real.pi)) ∧
      ∀ t ∈ Icc 0 (2 * Real.pi),
        f (circleMap c R t) = ‖f (circleMap c R t)‖ * exp (φ t * I)) ∧
    ∀ φ : ℝ → ℝ, ContinuousOn φ (Icc 0 (2 * Real.pi)) →
      (∀ t ∈ Icc 0 (2 * Real.pi),
        f (circleMap c R t) = ‖f (circleMap c R t)‖ * exp (φ t * I)) →
      φ (2 * Real.pi) - φ 0
        = 2 * Real.pi *
          (((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) : ℝ)
            - ((∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) : ℝ)) := by
  have h1 := loop_integral_of_log_deriv_eq_zeros_sub_poles f c R hR hmero hC hne
  set N := (∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁺ : ℤ) with hN
  set Q := (∑ᶠ a ∈ ball c R, (MeromorphicOn.divisor f (closedBall c R) a)⁻ : ℤ) with hQ
  have h2π : (2 * (Real.pi : ℂ) * I) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  have hI : (∮ z in C(c, R), logDeriv f z) = 2 * Real.pi * I * ((N : ℂ) - (Q : ℂ)) := by
    rw [← h1, ← mul_assoc, mul_inv_cancel₀ h2π, one_mul]
  have hγs : ∀ t, circleMap c R t ∈ sphere c R := fun t => circleMap_mem_sphere c hR.le t
  have hcont_ld : ∀ w ∈ sphere c R, ContinuousAt (logDeriv f) w := fun w hw => by
    obtain ⟨ha, hne⟩ := hC w hw
    exact ha.deriv.continuousAt.div ha.continuousAt hne
  set F : ℝ → ℂ := fun t => (circleMap 0 R t * I) * logDeriv f (circleMap c R t) with hFdef
  have hFc : Continuous F :=
    ((continuous_circleMap 0 R).mul continuous_const).mul
      (continuous_iff_continuousAt.2 fun t =>
        ContinuousAt.comp (g := logDeriv f) (hcont_ld _ (hγs t))
          (continuous_circleMap c R).continuousAt)
  set L : ℝ → ℂ := fun t => ∫ s in (0 : ℝ)..t, F s with hLdef
  have hL : ∀ t, HasDerivAt L (F t) t := fun t => (hFc.integral_hasStrictDerivAt 0 t).hasDerivAt
  have hLc : Continuous L := continuous_iff_continuousAt.2 fun t => (hL t).continuousAt
  have hfγ : ∀ t, HasDerivAt (fun t => f (circleMap c R t))
      (deriv f (circleMap c R t) * (circleMap 0 R t * I)) t := fun t =>
    ((hC _ (hγs t)).1.differentiableAt.hasDerivAt).comp t (hasDerivAt_circleMap c R t)
  set H : ℝ → ℂ := fun t => f (circleMap c R t) * exp (-L t) with hHdef
  have hH : ∀ t, HasDerivAt H 0 t := by
    intro t
    have := (hfγ t).mul ((hL t).neg.cexp)
    convert this using 1
    have hf0 := (hC _ (hγs t)).2
    simp only [hFdef, logDeriv_apply]
    field_simp
    ring
  have hHc : ∀ t, H t = H 0 := fun t =>
    is_const_of_deriv_eq_zero (fun t => (hH t).differentiableAt) (fun t => (hH t).deriv) t 0
  have hL0 : L 0 = 0 := intervalIntegral.integral_same
  have hrep : ∀ t, f (circleMap c R t) = f (circleMap c R 0) * exp (L t) := by
    intro t
    have := hHc t
    simp only [hHdef, hL0, neg_zero, exp_zero, mul_one] at this
    rw [← this, mul_assoc, ← exp_add, neg_add_cancel, exp_zero, mul_one]
  have hL2π : L (2 * Real.pi) = 2 * Real.pi * I * ((N : ℂ) - (Q : ℂ)) := by
    rw [← hI]
    simp only [hLdef, hFdef, circleIntegral, deriv_circleMap, smul_eq_mul]
  set φ0 : ℝ → ℝ := fun t => arg (f (circleMap c R 0)) + (L t).im with hφ0def
  have hφ0c : Continuous φ0 := continuous_const.add (continuous_im.comp hLc)
  have hφ0 : ∀ t, f (circleMap c R t) = ‖f (circleMap c R t)‖ * exp (φ0 t * I) := by
    intro t
    rw [hrep t, norm_mul, Complex.norm_exp]
    conv_lhs => rw [← Complex.norm_mul_exp_arg_mul_I (f (circleMap c R 0)), ← Complex.re_add_im (L t)]
    simp only [hφ0def]
    push_cast
    simp only [add_mul, exp_add]
    ring
  refine ⟨⟨φ0, hφ0c.continuousOn, fun t _ => hφ0 t⟩, fun ψ hψc hψ => ?_⟩
  have key : ∀ t ∈ Icc 0 (2 * Real.pi), ∃ n : ℤ, ψ t - φ0 t = n * (2 * Real.pi) := by
    intro t ht
    have h := (hψ t ht).symm.trans (hφ0 t)
    have hn0 : ((‖f (circleMap c R t)‖ : ℝ) : ℂ) ≠ 0 := by
      simpa using (hC _ (hγs t)).2
    obtain ⟨n, hn⟩ := Complex.exp_eq_exp_iff_exists_int.1 (mul_left_cancel₀ hn0 h)
    refine ⟨n, ?_⟩
    have := congrArg Complex.im hn
    simp at this
    linarith
  have hpi : 0 < 2 * Real.pi := by positivity
  obtain ⟨n0, hn0⟩ := key 0 ⟨le_rfl, hpi.le⟩
  obtain ⟨n1, hn1⟩ := key (2 * Real.pi) ⟨hpi.le, le_rfl⟩
  have hcd : ContinuousOn (fun t => ψ t - φ0 t) (Icc 0 (2 * Real.pi)) :=
    hψc.sub hφ0c.continuousOn
  have hn01 : n0 = n1 := by
    by_contra hneq
    rcases lt_or_gt_of_ne hneq with hlt | hlt
    · have hle : ((n0 : ℝ) + 1 / 2) ≤ n1 := by
        have : (n0 : ℝ) + 1 ≤ n1 := by exact_mod_cast hlt
        linarith
      have hmem : ((n0 : ℝ) + 1 / 2) * (2 * Real.pi) ∈
          Icc (ψ 0 - φ0 0) (ψ (2 * Real.pi) - φ0 (2 * Real.pi)) := by
        rw [hn0, hn1]
        constructor <;> nlinarith
      obtain ⟨t, ht, hteq⟩ := intermediate_value_Icc hpi.le hcd hmem
      obtain ⟨m, hm⟩ := key t ht
      have : (m : ℝ) = n0 + 1 / 2 := by
        have := hm.symm.trans hteq
        exact mul_right_cancel₀ hpi.ne' this
      exact int_ne_add_half_aux m n0 this
    · have hle : ((n1 : ℝ) + 1 / 2) ≤ n0 := by
        have : (n1 : ℝ) + 1 ≤ n0 := by exact_mod_cast hlt
        linarith
      have hmem : ((n1 : ℝ) + 1 / 2) * (2 * Real.pi) ∈
          Icc (ψ (2 * Real.pi) - φ0 (2 * Real.pi)) (ψ 0 - φ0 0) := by
        rw [hn0, hn1]
        constructor <;> nlinarith
      obtain ⟨t, ht, hteq⟩ := intermediate_value_Icc' hpi.le hcd hmem
      obtain ⟨m, hm⟩ := key t ht
      have : (m : ℝ) = n1 + 1 / 2 := by
        have := hm.symm.trans hteq
        exact mul_right_cancel₀ hpi.ne' this
      exact int_ne_add_half_aux m n1 this
  have hdiff : ψ (2 * Real.pi) - ψ 0 = φ0 (2 * Real.pi) - φ0 0 := by
    rw [hn01] at hn0
    linarith
  rw [hdiff]
  simp only [hφ0def, hL2π, hL0]
  simp [Complex.mul_im]

/-- **Each zero of multiplicity m contributes m; each pole of order p contributes −p.** Near a,
let f(z) = (z − a)^n h(z) on the punctured disc `0 < |z − a| < R`, with h holomorphic and nonzero
on the whole disc `|z − a| < R`; n = m > 0 is a zero of multiplicity m, n = −p < 0 a pole of order
p. Then f′/f = n/(z − a) + h′/h on the punctured disc, so the residue of f′/f at a is n: every
small circle `|z − a| = r` with `0 < r < R` gives `(1/2πi) ∮ f′/f dz = n`. -/
theorem log_deriv_residue_eq_order
    (f h : ℂ → ℂ) (a : ℂ) (R : ℝ) (n : ℤ)
    (hh : DifferentiableOn ℂ h (ball a R)) (hh0 : ∀ z ∈ ball a R, h z ≠ 0)
    (hf : ∀ z ∈ ball a R \ {a}, f z = (z - a) ^ n * h z) :
    (∀ z ∈ ball a R \ {a}, logDeriv f z = n / (z - a) + logDeriv h z) ∧
    ∀ r : ℝ, 0 < r → r < R →
      (2 * Real.pi * I)⁻¹ * (∮ z in C(a, r), logDeriv f z) = n := by
  have h1 : ∀ z ∈ ball a R \ {a}, logDeriv f z = n / (z - a) + logDeriv h z := by
    intro z hz
    have hopen : IsOpen (ball a R \ {a}) := isOpen_ball.sdiff isClosed_singleton
    have heq : Filter.EventuallyEq (nhds z) f (fun w => (w - a) ^ n * h w) :=
      Filter.eventually_of_mem (hopen.mem_nhds hz) hf
    have hza : z - a ≠ 0 := sub_ne_zero.2 hz.2
    have hdh : DifferentiableAt ℂ h z := hh.differentiableAt (isOpen_ball.mem_nhds hz.1)
    rw [(logDeriv_congr_nhds heq).eq_of_nhds, logDeriv_fun_mul (f := fun w => (w - a) ^ n) z (zpow_ne_zero n hza) (hh0 z hz.1)
      ((differentiableAt_id.sub_const a).zpow (Or.inl hza)) hdh,
      logDeriv_fun_zpow (f := fun w => w - a) (differentiableAt_id.sub_const a) n]
    simp [logDeriv_apply, div_eq_mul_inv]
  refine ⟨h1, fun r hr0 hrR => ?_⟩
  have hsub : closedBall a r ⊆ ball a R := closedBall_subset_ball hrR
  have := circleIntegral_formula_aux (F := logDeriv f) (g := h) hr0 {a} (fun _ => n)
    (by simp [hr0.ne]) (fun z hz => ⟨hh.analyticAt (isOpen_ball.mem_nhds (hsub hz)),
      hh0 z (hsub hz)⟩)
    (fun z hz => by
      have hz' : z ∈ ball a R \ {a} := ⟨hsub (sphere_subset_closedBall hz), by
        rintro rfl; simp [hr0.ne] at hz⟩
      rw [h1 z hz']; simp [div_eq_mul_inv])
  rw [this]; simp [hr0]

/-! ### The card's worked numbers, checked exactly (0.4 is written 2/5, 0.5 is 1/2, 0.2 is 1/5) -/

-- f(z) = z(z − 2/5), f′(z) = 2z − 2/5: f′/f = 1/z + 1/(z − 2/5), residue 1 at each zero.
example (z : ℂ) (h0 : z ≠ 0) (h1 : z - 2 / 5 ≠ 0) :
    (2 * z - 2 / 5) / (z * (z - 2 / 5)) = 1 / z + 1 / (z - 2 / 5) := by
  rw [div_add_div _ _ h0 h1, div_eq_div_iff (mul_ne_zero h0 h1) (mul_ne_zero h0 h1)]
  ring

-- g(z) = (z − 1/2)/(z − 2)^3, g′(z) = ((z − 2) − 3(z − 1/2))/(z − 2)^4:
-- g′/g = 1/(z − 1/2) − 3/(z − 2), residue 1 at the zero and −3 at the pole.
example (z : ℂ) (h1 : z - 1 / 2 ≠ 0) (h2 : z - 2 ≠ 0) :
    (((z - 2) - 3 * (z - 1 / 2)) / (z - 2) ^ 4) / ((z - 1 / 2) / (z - 2) ^ 3)
      = 1 / (z - 1 / 2) - 3 / (z - 2) := by
  rw [div_sub_div _ _ h1 h2, div_div_div_eq,
    div_eq_div_iff (mul_ne_zero (pow_ne_zero 4 h2) h1) (mul_ne_zero h1 h2)]
  ring

-- Which points lie inside which circle: 0 and 2/5 inside |z| = 1; only 0 inside |z| = 1/5;
-- 1/2 inside |z| = 1 but 2 outside; both 1/2 and 2 inside |z| = 3.
example : ‖(0 : ℂ)‖ < 1 ∧ ‖(2 / 5 : ℂ)‖ < 1 ∧ ‖(0 : ℂ)‖ < 1 / 5 ∧ ¬ ‖(2 / 5 : ℂ)‖ < 1 / 5 := by
  norm_num [Complex.norm_real]
example : ‖(1 / 2 : ℂ)‖ < 1 ∧ ¬ ‖(2 : ℂ)‖ < 1 ∧ ‖(1 / 2 : ℂ)‖ < 3 ∧ ‖(2 : ℂ)‖ < 3 := by
  norm_num [Complex.norm_real]

-- The counts N − P: 1 + 1 = 2 on |z| = 1; 1 on |z| = 1/5; 1 − 0 = 1 and 1 − 3 = −2 for g.
example : (1 + 1 : ℤ) - 0 = 2 ∧ (1 : ℤ) - 0 = 1 ∧ (1 : ℤ) - 0 = 1 ∧ (1 : ℤ) - 3 = -2 := by decide

-- The mistake: counting the pole of order 3 once gives 1 − 1 = 0, not −2.
example : (1 : ℤ) - 1 = 0 ∧ (1 : ℤ) - 1 ≠ 1 - 3 := by decide

#print axioms loop_integral_of_log_deriv_eq_zeros_sub_poles
#print axioms needle_turns_eq_zeros_sub_poles
#print axioms log_deriv_residue_eq_order

end TheArgumentPrinciple
