-- Monotone operators: on a reflexive real normed space, a monotone, coercive, hemicontinuous operator into the dual hits every target, exactly once when it is strictly monotone, and the pipe's cube flux is strictly monotone.
import Mathlib.Analysis.Normed.Module.DoubleDual
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Filter NormedSpace

theorem mb_quad_nonneg {ι : Type*} [Fintype ι] (M : ι → ι → ℝ)
    (hM : ∀ i j, 0 ≤ M i j + M j i) (μ : ι → ℝ) (hμ : ∀ i, 0 ≤ μ i) :
    0 ≤ ∑ i, μ i * ∑ j, M i j * μ j := by
  have h1 : ∑ i, μ i * ∑ j, M i j * μ j = ∑ i, ∑ j, M i j * μ i * μ j := by
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [Finset.mul_sum]; refine Finset.sum_congr rfl fun j _ => ?_; ring
  have h2 : ∑ i, ∑ j, M i j * μ i * μ j = ∑ i, ∑ j, M j i * μ i * μ j := by
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_; ring
  have h3 : 0 ≤ ∑ i, ∑ j, (M i j + M j i) * μ i * μ j :=
    Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ =>
      mul_nonneg (mul_nonneg (hM i j) (hμ i)) (hμ j)
  have h4 : ∑ i, ∑ j, (M i j + M j i) * μ i * μ j
      = ∑ i, ∑ j, M i j * μ i * μ j + ∑ i, ∑ j, M j i * μ i * μ j := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun j _ => ?_; ring
  linarith

theorem mb_matrix {ι : Type*} [Fintype ι] [Nonempty ι] (M : ι → ι → ℝ)
    (hM : ∀ i j, 0 ≤ M i j + M j i) :
    ∃ w : ι → ℝ, (∀ j, 0 ≤ w j) ∧ ∑ j, w j = 1 ∧ ∀ i, 0 ≤ ∑ j, M i j * w j := by
  classical
  by_contra hne
  push Not at hne
  let S : Set (ι → ℝ) := {w | (∀ j, 0 ≤ w j) ∧ ∑ j, w j = 1}
  have hSconv : Convex ℝ S := by
    refine fun f hf g hg a b ha hb hab => ⟨fun x => ?_, ?_⟩
    · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      exact add_nonneg (mul_nonneg ha (hf.1 x)) (mul_nonneg hb (hg.1 x))
    · simp_rw [Pi.add_apply, Pi.smul_apply]
      rw [Finset.sum_add_distrib, ← Finset.smul_sum, ← Finset.smul_sum, hf.2, hg.2, smul_eq_mul,
        smul_eq_mul, mul_one, mul_one, hab]
  have hScl : IsClosed S := by
    have : S = (⋂ x, {f : ι → ℝ | 0 ≤ f x}) ∩ {f | ∑ x, f x = 1} := by
      ext f; simp [S]
    rw [this]
    apply IsClosed.inter
    · exact isClosed_iInter fun i ↦ isClosed_le continuous_const (continuous_apply i)
    · exact isClosed_eq (by fun_prop) continuous_const
  have hSsub : S ⊆ Set.Icc 0 1 := by
    intro f hf
    refine ⟨fun i => hf.1 i, fun i => ?_⟩
    have := Finset.single_le_sum (fun j _ => hf.1 j) (Finset.mem_univ i)
    simpa [hf.2] using this
  have hScpt : IsCompact S := IsCompact.of_isClosed_subset isCompact_Icc hScl hSsub
  let L : (ι → ℝ) →ₗ[ℝ] (ι → ℝ) :=
    { toFun := fun w i => ∑ j, M i j * w j
      map_add' := fun x y => by
        funext i; simp only [Pi.add_apply, mul_add, Finset.sum_add_distrib]
      map_smul' := fun c x => by
        funext i; simp only [Pi.smul_apply, smul_eq_mul, RingHom.id_apply, Finset.mul_sum]
        refine Finset.sum_congr rfl fun j _ => ?_; ring }
  have hL : ∀ w i, L w i = ∑ j, M i j * w j := fun w i => rfl
  have hLc : Continuous L := LinearMap.continuous_of_finiteDimensional L
  have hdisj : Disjoint (L '' S) (Set.Ici 0) := by
    rw [Set.disjoint_left]
    rintro _ ⟨w, hw, rfl⟩ hp
    obtain ⟨i, hi⟩ := hne w hw.1 hw.2
    have := hp i
    rw [Pi.zero_apply, hL] at this
    linarith
  obtain ⟨f, u, v, hfu, huv, hfv⟩ := geometric_hahn_banach_compact_closed
    (hSconv.linear_image L) (hScpt.image hLc) (convex_Ici 0) isClosed_Ici hdisj
  set μ : ι → ℝ := fun i => f fun j => if i = j then 1 else 0 with hμdef
  have hf : ∀ x, f x = ∑ i, x i * μ i := fun x => by
    have := LinearMap.pi_apply_eq_sum_univ f.toLinearMap x
    simpa [smul_eq_mul] using this
  have hv : v < 0 := by simpa using hfv 0 (Set.mem_Ici.mpr le_rfl)
  have hμ : ∀ i, 0 ≤ μ i := by
    intro i
    by_contra hneg
    push Not at hneg
    have hmem : (v / μ i) • (fun j => if i = j then (1:ℝ) else 0) ∈ Set.Ici (0 : ι → ℝ) := by
      intro j
      have : 0 ≤ v / μ i := div_nonneg_of_nonpos hv.le hneg.le
      rcases eq_or_ne i j with rfl | hij
      · simpa using this
      · simp [hij]
    have h := hfv _ hmem
    rw [map_smul, smul_eq_mul] at h
    have : v / μ i * μ i = v := div_mul_cancel₀ v hneg.ne
    change v < v / μ i * μ i at h
    linarith
  obtain ⟨i0⟩ := ‹Nonempty ι›
  set T := ∑ i, μ i with hT
  have hT0 : 0 ≤ T := Finset.sum_nonneg fun i _ => hμ i
  rcases hT0.lt_or_eq with hTpos | hTz
  · have hwS : T⁻¹ • μ ∈ S := by
      refine ⟨fun j => ?_, ?_⟩
      · simp only [Pi.smul_apply, smul_eq_mul]; exact mul_nonneg (inv_nonneg.mpr hT0) (hμ j)
      · simp only [Pi.smul_apply, smul_eq_mul]
        rw [← Finset.mul_sum, ← hT, inv_mul_cancel₀ hTpos.ne']
    have h1 := hfu _ ⟨_, hwS, rfl⟩
    rw [map_smul, map_smul, smul_eq_mul, hf] at h1
    have hq := mb_quad_nonneg M hM μ hμ
    have : ∑ i, L μ i * μ i = ∑ i, μ i * ∑ j, M i j * μ j := by
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [hL]; ring
    rw [this] at h1
    have : 0 ≤ T⁻¹ * ∑ i, μ i * ∑ j, M i j * μ j := mul_nonneg (inv_nonneg.mpr hT0) hq
    linarith
  · have hμ0 : ∀ i, μ i = 0 := fun i =>
      (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => hμ j)).mp hTz.symm i (Finset.mem_univ i)
    have hwS : (fun j => if i0 = j then (1:ℝ) else 0) ∈ S := by
      refine ⟨fun j => ?_, ?_⟩
      · by_cases h : i0 = j <;> simp [h]
      · simp
    have h1 := hfu _ ⟨_, hwS, rfl⟩
    rw [hf] at h1
    simp only [hμ0, mul_zero, Finset.sum_const_zero] at h1
    linarith

theorem mb_finite_vi {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (A : X → StrongDual ℝ X)
    (hmono : ∀ u v : X, 0 ≤ (A u - A v) (u - v))
    (R : ℝ) (hR : 0 ≤ R) (s : Finset X) (hs : ∀ v ∈ s, ‖v‖ ≤ R) :
    ∃ u : X, ‖u‖ ≤ R ∧ ∀ v ∈ s, A v u ≤ A v v := by
  classical
  rcases isEmpty_or_nonempty s with hE | hN
  · refine ⟨0, by simpa using hR, fun v hv => (hE.false ⟨v, hv⟩).elim⟩
  · let M : s → s → ℝ := fun i j => A i.1 (i.1 - j.1)
    have hM : ∀ i j, 0 ≤ M i j + M j i := fun i j => by
      have := hmono i.1 j.1
      simp only [M, sub_apply] at this ⊢
      have e : A j.1 (j.1 - i.1) = - A j.1 (i.1 - j.1) := by
        rw [← map_neg, neg_sub]
      rw [e]; linarith
    obtain ⟨w, hw0, hw1, hwM⟩ := mb_matrix M hM
    refine ⟨∑ j, w j • j.1, ?_, ?_⟩
    · have hconv := (convex_closedBall (0 : X) R).sum_mem (t := Finset.univ) (w := w) (z := fun j => j.1)
        (fun j _ => hw0 j) hw1 (fun j _ => by simpa using hs j.1 j.2)
      simpa using hconv
    · intro v hv
      have h := hwM ⟨v, hv⟩
      simp only [M, map_sub] at h
      have e : ∑ j : s, (A v v - A v j.1) * w j = A v v - A v (∑ j, w j • j.1) := by
        rw [map_sum]
        simp only [map_smul, smul_eq_mul, sub_mul, Finset.sum_sub_distrib, ← Finset.mul_sum, hw1]
        ring_nf
        refine congrArg _ (Finset.sum_congr rfl fun j _ => ?_); ring
      linarith

theorem mb_core {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (hrefl : Function.Surjective (inclusionInDoubleDual ℝ X))
    (A : X → StrongDual ℝ X)
    (hmono : ∀ u v : X, 0 ≤ (A u - A v) (u - v))
    (R : ℝ) (hR : ∀ u : X, R ≤ ‖u‖ → 0 < A u u)
    (hhemi : ∀ u v w : X, Continuous fun r : ℝ => A (u + r • v) w) :
    ∃ u : X, ∀ v : X, A u v = 0 := by
  have hR0 : 0 < R := by
    by_contra h
    have := hR 0 (by simpa using not_lt.mp h)
    simp at this
  -- Step 1: Minty's variational inequality on the ball, via weak-* compactness.
  obtain ⟨u, hu, hvi⟩ : ∃ u : X, ‖u‖ ≤ R ∧ ∀ v : X, ‖v‖ ≤ R → A v u ≤ A v v := by
    let K : Set (WeakDual ℝ (StrongDual ℝ X)) :=
      WeakDual.toStrongDual ⁻¹' Metric.closedBall 0 R
    have hK : IsCompact K := WeakDual.isCompact_closedBall 0 R
    let t : {v : X // ‖v‖ ≤ R} → Set (WeakDual ℝ (StrongDual ℝ X)) :=
      fun v => {Φ | Φ (A v.1) ≤ A v.1 v.1}
    have htc : ∀ v, IsClosed (t v) := fun v =>
      isClosed_le (WeakDual.eval_continuous (A v.1)) continuous_const
    have hfip : ∀ s : Finset {v : X // ‖v‖ ≤ R}, (K ∩ ⋂ i ∈ s, t i).Nonempty := by
      intro s
      classical
      obtain ⟨u, hu, hu'⟩ := mb_finite_vi A hmono R hR0.le (s.image Subtype.val)
        (by intro v hv; obtain ⟨w, _, rfl⟩ := Finset.mem_image.mp hv; exact w.2)
      refine ⟨StrongDual.toWeakDual (inclusionInDoubleDual ℝ X u), ?_, ?_⟩
      · show WeakDual.toStrongDual (StrongDual.toWeakDual (inclusionInDoubleDual ℝ X u)) ∈
          Metric.closedBall 0 R
        rw [StrongDual.toStrongDual_toWeakDual, Metric.mem_closedBall]
        exact (dist_zero_right (E := StrongDual ℝ (StrongDual ℝ X)) _).trans_le
          ((double_dual_bound ℝ X u).trans hu)
      · simp only [Set.mem_iInter]
        intro i hi
        exact hu' i.1 (Finset.mem_image_of_mem _ hi)
    obtain ⟨Φ, hΦK, hΦt⟩ := hK.inter_iInter_nonempty t htc hfip
    obtain ⟨u, hJu⟩ := hrefl (WeakDual.toStrongDual Φ)
    refine ⟨u, ?_, fun v hv => ?_⟩
    · rw [← (inclusionInDoubleDualLi ℝ).norm_map u]
      change ‖inclusionInDoubleDual ℝ X u‖ ≤ R
      rw [hJu]
      have : WeakDual.toStrongDual Φ ∈ Metric.closedBall (0 : StrongDual ℝ (StrongDual ℝ X)) R :=
        hΦK
      rw [Metric.mem_closedBall] at this
      exact (dist_zero_right (E := StrongDual ℝ (StrongDual ℝ X)) _).symm.trans_le this
    · have h := Set.mem_iInter.mp hΦt ⟨v, hv⟩
      calc A v u = inclusionInDoubleDual ℝ X u (A v) := rfl
        _ = Φ (A v) := by rw [hJu]; rfl
        _ ≤ A v v := h
  -- Step 2: Minty's trick along segments inside the ball.
  have hball : ∀ w : X, ‖w‖ ≤ R → 0 ≤ A u (w - u) := by
    intro w hw
    have hcont := hhemi u (w - u) (w - u)
    have hev : ∀ᶠ r in nhdsWithin (0:ℝ) (Set.Ioi 0), 0 ≤ A (u + r • (w - u)) (w - u) := by
      filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < 1 by norm_num)] with r hr
      have hmem : u + r • (w - u) ∈ Metric.closedBall (0:X) R :=
        (convex_closedBall (0:X) R).add_smul_sub_mem (by simpa using hu) (by simpa using hw)
          ⟨hr.1.le, hr.2.le⟩
      have h := hvi _ (by simpa using hmem)
      have e : A (u + r • (w - u)) (u + r • (w - u)) - A (u + r • (w - u)) u
          = r * A (u + r • (w - u)) (w - u) := by
        rw [← map_sub, add_sub_cancel_left, map_smul, smul_eq_mul]
      have : 0 ≤ r * A (u + r • (w - u)) (w - u) := by linarith
      exact (mul_nonneg_iff_of_pos_left hr.1).mp this
    have ht : Tendsto (fun r : ℝ => A (u + r • (w - u)) (w - u)) (nhdsWithin 0 (Set.Ioi 0))
        (nhds (A (u + (0:ℝ) • (w - u)) (w - u))) :=
      (hcont.tendsto 0).mono_left nhdsWithin_le_nhds
    have := ge_of_tendsto ht hev
    simpa using this
  have huu : A u u ≤ 0 := by
    have := hball 0 (by simpa using hR0.le)
    rw [zero_sub, map_neg] at this
    linarith
  have hlt : ‖u‖ < R := by
    by_contra h
    push Not at h
    have := hR u h
    linarith
  refine ⟨u, fun z => ?_⟩
  set δ := (R - ‖u‖) / (‖z‖ + 1) with hδ
  have hδpos : 0 < δ := div_pos (by linarith) (by positivity)
  have hδz : δ * ‖z‖ ≤ R - ‖u‖ := by
    have : δ * (‖z‖ + 1) = R - ‖u‖ := div_mul_cancel₀ _ (by positivity)
    nlinarith [norm_nonneg z]
  have hnz : ‖δ • z‖ = δ * ‖z‖ := by rw [norm_smul, Real.norm_of_nonneg hδpos.le]
  have h1 := hball (u + δ • z) (by
    calc ‖u + δ • z‖ ≤ ‖u‖ + ‖δ • z‖ := norm_add_le _ _
      _ ≤ R := by linarith)
  have h2 := hball (u - δ • z) (by
    calc ‖u - δ • z‖ ≤ ‖u‖ + ‖δ • z‖ := norm_sub_le _ _
      _ ≤ R := by linarith)
  rw [add_sub_cancel_left, map_smul, smul_eq_mul] at h1
  rw [sub_sub_cancel_left, map_neg, map_smul, smul_eq_mul] at h2
  have h3 : 0 ≤ A u z := (mul_nonneg_iff_of_pos_left hδpos).mp h1
  have h4 : A u z ≤ 0 := by nlinarith
  linarith

/-- The Minty-Browder theorem: let `X` be a reflexive real normed space (the reading map
`J : X → X''` is onto) and let `A : X → X*` be monotone (`⟨Au - Av, u - v⟩ ≥ 0`), coercive
(`⟨Au, u⟩ / ‖u‖ → ∞` as `‖u‖ → ∞`) and hemicontinuous (`r ↦ ⟨A(u + r v), w⟩` is continuous).
Then for every target `f` in the dual `X*` there is a `u` in `X` with `⟨Au, v⟩ = ⟨f, v⟩`
for all `v`. -/
theorem minty_browder_surjective
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (hrefl : Function.Surjective (inclusionInDoubleDual ℝ X))
    (A : X → StrongDual ℝ X)
    (hmono : ∀ u v : X, 0 ≤ (A u - A v) (u - v))
    (hcoer : Tendsto (fun u : X => A u u / ‖u‖) (Bornology.cobounded X) atTop)
    (hhemi : ∀ u v w : X, Continuous fun r : ℝ => A (u + r • v) w) :
    ∀ f : StrongDual ℝ X, ∃ u : X, ∀ v : X, A u v = f v := by
  intro f
  have hev := hcoer.eventually_gt_atTop ‖f‖
  rw [← comap_norm_atTop, Filter.eventually_comap, Filter.eventually_atTop] at hev
  obtain ⟨N, hN⟩ := hev
  have hR : ∀ u : X, max N 1 ≤ ‖u‖ → 0 < (A u - f) u := by
    intro u hu
    have hpos : 0 < ‖u‖ := lt_of_lt_of_le one_pos ((le_max_right _ _).trans hu)
    have h := hN ‖u‖ ((le_max_left _ _).trans hu) u rfl
    rw [lt_div_iff₀ hpos] at h
    have hf : f u ≤ ‖f‖ * ‖u‖ := (le_abs_self _).trans (f.le_opNorm u)
    rw [sub_apply]
    linarith
  obtain ⟨u, hu⟩ := mb_core hrefl (fun u => A u - f) (fun u v => by simpa using hmono u v)
    (max N 1) hR (fun u v w => by
      simp only [sub_apply]; exact (hhemi u v w).sub continuous_const)
  exact ⟨u, fun v => by have := hu v; rw [sub_apply] at this; linarith⟩

/-- Exactly once: if in addition `A` is strictly monotone (`⟨Au - Av, u - v⟩ > 0` whenever
`u ≠ v`), then for every target `f` there is exactly one `u` with `⟨Au, v⟩ = ⟨f, v⟩` for all `v`. -/
theorem minty_browder_unique_of_strict_mono
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (hrefl : Function.Surjective (inclusionInDoubleDual ℝ X))
    (A : X → StrongDual ℝ X)
    (hstrict : ∀ u v : X, u ≠ v → 0 < (A u - A v) (u - v))
    (hcoer : Tendsto (fun u : X => A u u / ‖u‖) (Bornology.cobounded X) atTop)
    (hhemi : ∀ u v w : X, Continuous fun r : ℝ => A (u + r • v) w) :
    ∀ f : StrongDual ℝ X, ∃! u : X, ∀ v : X, A u v = f v := by
  intro f
  have hmono : ∀ u v : X, 0 ≤ (A u - A v) (u - v) := fun u v => by
    rcases eq_or_ne u v with rfl | h
    · simp
    · exact (hstrict u v h).le
  obtain ⟨u, hu⟩ := minty_browder_surjective hrefl A hmono hcoer hhemi f
  refine ⟨u, hu, fun y hy => ?_⟩
  by_contra hne
  have h := hstrict y u hne
  rw [sub_apply, hy, hu] at h
  simp at h

/-- The pipe's mixing flux is strictly monotone: `(a³ - b³)(a - b) > 0` whenever `a ≠ b`,
so the cube of the slope always moves the same way as the slope. -/
theorem cube_flux_strict_mono (a b : ℝ) (h : a ≠ b) : 0 < (a ^ 3 - b ^ 3) * (a - b) := by
  have h1 : 0 < (a - b) ^ 2 := by
    have : a - b ≠ 0 := sub_ne_zero.mpr h
    positivity
  have h2 : 0 < a ^ 2 + a * b + b ^ 2 := by
    by_contra hle
    push Not at hle
    have ha : a = 0 := by nlinarith [sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]
    have hb : b = 0 := by nlinarith [sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]
    exact h (ha.trans hb.symm)
  have e : (a ^ 3 - b ^ 3) * (a - b) = (a - b) ^ 2 * (a ^ 2 + a * b + b ^ 2) := by ring
  rw [e]
  exact mul_pos h1 h2

-- Slopes 2 and 0: the monotone pairing (2³ - 0³)(2 - 0) = 16 is positive.
example : ((2 : ℤ) ^ 3 - 0 ^ 3) * (2 - 0) = 16 := by norm_num

-- Weak limit of slopes 2 and 0 is 1, with cube 1; the average of their cubes is 4, not 1.
example : ((2 : ℚ) ^ 3 + 0 ^ 3) / 2 = 4 ∧ ((2 + 0 : ℚ) / 2) ^ 3 = 1 := by norm_num

-- Slopes flipping 10 times: ∫ w x dx = Σ over the 10 periods of the steps of x², which is
-- 1/2 - 1/(4·10) = 19/40 = 0.475; the cubes give 4 times that, 19/10 = 1.9.
example : (∑ k ∈ Finset.range 10, (((k : ℚ) / 10 + 1 / 20) ^ 2 - ((k : ℚ) / 10) ^ 2)) = 19 / 40 := by
  norm_num [Finset.sum_range_succ]
example : (1 / 2 - 1 / (4 * 10) : ℚ) = 19 / 40 ∧ 4 * (19 / 40 : ℚ) = 19 / 10 := by norm_num

-- Slopes flipping 1000 times: 1/2 - 1/4000 = 0.49975, and 4 times that is 1.999.
example : (1 / 2 - 1 / (4 * 1000) : ℚ) = 1999 / 4000 ∧ 4 * (1999 / 4000 : ℚ) = 1999 / 1000 := by
  norm_num

-- In the limit, the cube of the weak limit tested against x gives 1/2; the limit of the cubes gives 4 · 1/2 = 2.
example : (1 : ℚ) ^ 3 * (1 / 2) = 1 / 2 ∧ (4 : ℚ) * (1 / 2) = 2 := by norm_num

-- Not hemicontinuous: x + [x ≥ 0] jumps from 0 to 1 at x = 0, skipping the target 1/2.
example : (0 : ℚ) + 1 = 1 ∧ (0 : ℚ) < 1 / 2 ∧ (1 / 2 : ℚ) < 1 := by norm_num

-- Not monotone: x³ - 3x vanishes at x = 0 (the other two roots are ±√3).
example : (0 : ℤ) ^ 3 - 3 * 0 = 0 := by norm_num

#print axioms mb_quad_nonneg
#print axioms mb_matrix
#print axioms mb_finite_vi
#print axioms mb_core
#print axioms minty_browder_surjective
#print axioms minty_browder_unique_of_strict_mono
#print axioms cube_flux_strict_mono
