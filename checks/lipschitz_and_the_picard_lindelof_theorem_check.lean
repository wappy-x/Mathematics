-- The Picard-Lindelof theorem: a rate law y' = f(t, y) that is continuous on a box around the start and changes with the value at most L times as fast as the value has exactly one solution from the start for every window T with T ≤ a and M * T ≤ b, while the leaking bucket's rule -0.2 √h, which has no such bound at empty, lets several different pasts reach the same empty bucket.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Topology.ContinuousOn
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.Calculus.MeanValue

open Set

/-- Fencing step: a curve that starts at `y₀` and moves at most `M` per unit time while it is
within `b` of `y₀` stays within `b` of `y₀` up to a time `x` with `M * (x - t₀) < b`. -/
theorem pl_stay_right (z g : ℝ → ℝ) (t₀ y₀ b M x : ℝ) (hx : t₀ ≤ x) (hM0 : 0 ≤ M)
    (hMx : M * (x - t₀) < b) (hz0 : z t₀ = y₀) (hcont : ContinuousOn z (Icc t₀ x))
    (hd : ∀ t ∈ Ico t₀ x, HasDerivWithinAt z (g t) (Ici t) t)
    (hg : ∀ t ∈ Ico t₀ x, |z t - y₀| ≤ b → |g t| ≤ M) : |z x - y₀| ≤ b := by
  set d := b - M * (x - t₀) with hd_def
  have hdpos : 0 < d := by linarith
  have hx0 : 0 ≤ x - t₀ := by linarith
  set ε := d / (2 * (1 + (x - t₀))) with hε
  have hεpos : 0 < ε := by positivity
  have hεd : ε * (1 + (x - t₀)) ≤ d := by
    rw [hε, div_mul_eq_mul_div, div_le_iff₀ (by positivity)]; nlinarith
  have key := image_norm_le_of_norm_deriv_right_lt_deriv_boundary (f := fun t => z t - y₀)
    (f' := g) (a := t₀) (b := x) (B := fun t => ε + (M + ε) * (t - t₀)) (B' := fun _ => M + ε)
    (hcont.sub continuousOn_const) (fun t ht => (hd t ht).sub_const y₀) ?_ ?_ ?_
    (right_mem_Icc.2 hx)
  · have : ε + (M + ε) * (x - t₀) ≤ b := by nlinarith
    simp only [Real.norm_eq_abs] at key; linarith
  · simp [hz0, hεpos.le]
  · intro t
    have := (((hasDerivAt_id t).sub_const t₀).const_mul (M + ε)).const_add ε
    simpa using this
  · intro t ht heq
    simp only [Real.norm_eq_abs] at heq ⊢
    have hle : |z t - y₀| ≤ b := by
      have : ε + (M + ε) * (x - t₀) ≤ b := by nlinarith
      rw [heq]; nlinarith [ht.1, ht.2, mul_nonneg (add_nonneg hM0 hεpos.le) (sub_nonneg.2 ht.2.le)]
    have := hg t ht hle; linarith

/-- Any solution of the problem stays in the box at every time strictly inside the window. -/
theorem pl_stays (f : ℝ → ℝ → ℝ) (t₀ y₀ a b M T : ℝ)
    (hM : ∀ t ∈ Icc (t₀ - a) (t₀ + a), ∀ y ∈ Icc (y₀ - b) (y₀ + b), |f t y| ≤ M)
    (hM0 : 0 ≤ M) (hb : 0 < b) (hTa : T ≤ a) (hTb : M * T ≤ b) (z : ℝ → ℝ) (hz0 : z t₀ = y₀)
    (hz : ∀ t ∈ Icc (t₀ - T) (t₀ + T),
      HasDerivWithinAt z (f t (z t)) (Icc (t₀ - T) (t₀ + T)) t) :
    ∀ t ∈ Ioo (t₀ - T) (t₀ + T), z t ∈ Icc (y₀ - b) (y₀ + b) := by
  intro t ht
  have hT0 : 0 < T := by linarith [ht.1, ht.2]
  have hzc : ContinuousOn z (Icc (t₀ - T) (t₀ + T)) := fun s hs => (hz s hs).continuousWithinAt
  have hmul : ∀ u, 0 ≤ u → u < T → M * u < b := by
    intro u hu huT
    rcases hM0.eq_or_lt with h | h
    · rw [← h]; simpa using hb
    · calc M * u < M * T := mul_lt_mul_of_pos_left huT h
        _ ≤ b := hTb
  suffices habs : |z t - y₀| ≤ b by
    rw [abs_le] at habs; constructor <;> linarith [habs.1, habs.2]
  rcases le_total t₀ t with h | h
  · apply pl_stay_right z (fun s => f s (z s)) t₀ y₀ b M t h hM0
      (hmul _ (by linarith) (by linarith [ht.2])) hz0
      (hzc.mono (Icc_subset_Icc (by linarith [ht.1]) ht.2.le))
    · intro s hs
      exact (hz s ⟨by linarith [hs.1, ht.1], by linarith [hs.2, ht.2]⟩).mono_of_mem_nhdsWithin
        (Filter.mem_of_superset (Icc_mem_nhdsGE (by linarith [hs.2, ht.2]))
          (Icc_subset_Icc_left (by linarith [hs.1, ht.1])))
    · intro s hs hzs
      rw [abs_le] at hzs
      exact hM s ⟨by linarith [hs.1, ht.1], by linarith [hs.2, ht.2]⟩ (z s)
        ⟨by linarith [hzs.1], by linarith [hzs.2]⟩
  · have := pl_stay_right (fun s => z (-s)) (fun s => -f (-s) (z (-s))) (-t₀) y₀ b M (-t)
      (by linarith) hM0 (hmul _ (by linarith) (by linarith [ht.1])) (by simpa using hz0)
      ((hzc.mono (Icc_subset_Icc ht.1.le (by linarith [ht.2]))).comp continuousOn_neg
        (fun s hs => ⟨by linarith [hs.2], by linarith [hs.1]⟩)) ?_ ?_
    · simpa using this
    · intro s hs
      have h1 : HasDerivWithinAt z (f (-s) (z (-s))) (Iic (-s)) (-s) :=
        (hz (-s) ⟨by linarith [hs.2, ht.1], by linarith [hs.1, ht.2]⟩).mono_of_mem_nhdsWithin
          (Filter.mem_of_superset (Icc_mem_nhdsLE (by linarith [hs.2, ht.1]))
            (Icc_subset_Icc_right (by linarith [hs.1, ht.2])))
      have h2 := h1.comp s (hasDerivAt_neg s).hasDerivWithinAt
        (s := Ici s) (fun u hu => by simp only [mem_Iic, mem_Ici] at hu ⊢; linarith)
      have h3 : -f (-s) (z (-s)) = f (-s) (z (-s)) * -1 := by ring
      rw [h3]; exact h2
    · intro s hs hzs
      rw [abs_neg]
      rw [abs_le] at hzs
      exact hM (-s) ⟨by linarith [hs.2, ht.1], by linarith [hs.1, ht.2]⟩ (z (-s))
        ⟨by linarith [hzs.1], by linarith [hzs.2]⟩

/-- Each draining curve `(max (c - t/10) 0)^2` obeys the bucket's rule at every time. -/
theorem bucket_curve (c : ℝ) (t : ℝ) :
    HasDerivAt (fun t : ℝ => (max (c - t / 10) 0) ^ 2)
      (-(1 / 5) * Real.sqrt ((max (c - t / 10) 0) ^ 2)) t := by
  rw [Real.sqrt_sq (le_max_right _ _)]
  have hp : ∀ s : ℝ, HasDerivAt (fun t : ℝ => (c - t / 10) ^ 2) (-(1 / 5) * (c - s / 10)) s := by
    intro s
    have h0 : HasDerivAt (fun t : ℝ => c - t / 10) (-(1 / 10)) s := by
      simpa using ((hasDerivAt_id s).div_const 10).const_sub c
    have := h0.fun_pow 2
    convert this using 1
    norm_num; ring
  rcases lt_trichotomy t (10 * c) with h | h | h
  · have hm : max (c - t / 10) 0 = c - t / 10 := max_eq_left (by linarith)
    rw [hm]
    apply (hp t).congr_of_eventuallyEq
    filter_upwards [Iio_mem_nhds h] with s hs
    rw [max_eq_left (by simp only [mem_Iio] at hs; linarith)]
  · subst h
    have hm : max (c - 10 * c / 10) 0 = 0 := by
      rw [max_eq_right]; linarith
    rw [hm, mul_zero]
    have e : HasDerivWithinAt (fun t : ℝ => (max (c - t / 10) 0) ^ 2) 0
        (Iic (10 * c) ∪ Ici (10 * c)) (10 * c) := by
      apply HasDerivWithinAt.union
      · have := (hp (10 * c)).hasDerivWithinAt (s := Iic (10 * c))
        have hz : c - 10 * c / 10 = 0 := by ring
        rw [hz, mul_zero] at this
        apply this.congr
        · intro s hs
          simp only [mem_Iic] at hs
          rw [max_eq_left (by linarith)]
        · rw [hm, hz]
      · apply (hasDerivWithinAt_const (10 * c) (Ici (10 * c)) (0 : ℝ)).congr
        · intro s hs
          simp only [mem_Ici] at hs
          rw [max_eq_right (by linarith)]; norm_num
        · rw [hm]; norm_num
    rw [Iic_union_Ici] at e
    exact e.hasDerivAt Filter.univ_mem
  · have hm : max (c - t / 10) 0 = 0 := max_eq_right (by linarith)
    rw [hm, mul_zero]
    apply (hasDerivAt_const t (0 : ℝ)).congr_of_eventuallyEq
    filter_upwards [Ioi_mem_nhds h] with s hs
    simp only [mem_Ioi] at hs
    rw [max_eq_right (by linarith)]; norm_num


/-- The Picard-Lindelof theorem. The box is the times within `a` of `t₀` and the values within
`b` of `y₀`. The rule `f` is continuous in the box, it obeys the Lipschitz bound
`|f t y - f t z| ≤ L * |y - z|` there, and `M` bounds its size there. Then for any window
`T` with `T ≤ a` and `M * T ≤ b` (the card's `T = min(a, b/M)` is the largest such window),
the problem `y' = f(t, y)`, `y(t₀) = y₀` has a solution on the times `|t - t₀| ≤ T`, and every
other solution agrees with it at every one of those times: exactly one solution. -/
theorem picard_lindelof_exactly_one_solution (f : ℝ → ℝ → ℝ) (t₀ y₀ a b L M T : ℝ)
    (ha : 0 < a) (hb : 0 < b)
    (hcont : ContinuousOn (Function.uncurry f) (Icc (t₀ - a) (t₀ + a) ×ˢ Icc (y₀ - b) (y₀ + b)))
    (hlip : ∀ t ∈ Icc (t₀ - a) (t₀ + a), ∀ y ∈ Icc (y₀ - b) (y₀ + b),
      ∀ z ∈ Icc (y₀ - b) (y₀ + b), |f t y - f t z| ≤ L * |y - z|)
    (hM : ∀ t ∈ Icc (t₀ - a) (t₀ + a), ∀ y ∈ Icc (y₀ - b) (y₀ + b), |f t y| ≤ M)
    (hT : 0 ≤ T) (hTa : T ≤ a) (hTb : M * T ≤ b) :
    ∃ y : ℝ → ℝ, y t₀ = y₀ ∧
      (∀ t ∈ Icc (t₀ - T) (t₀ + T), HasDerivWithinAt y (f t (y t)) (Icc (t₀ - T) (t₀ + T)) t) ∧
      ∀ z : ℝ → ℝ, z t₀ = y₀ →
        (∀ t ∈ Icc (t₀ - T) (t₀ + T),
          HasDerivWithinAt z (f t (z t)) (Icc (t₀ - T) (t₀ + T)) t) →
        EqOn z y (Icc (t₀ - T) (t₀ + T)) := by
  have hy₀ : y₀ ∈ Icc (y₀ - b) (y₀ + b) := ⟨by linarith, by linarith⟩
  have ht₀ : t₀ ∈ Icc (t₀ - a) (t₀ + a) := ⟨by linarith, by linarith⟩
  have hM0 : 0 ≤ M := le_trans (abs_nonneg _) (hM t₀ ht₀ y₀ hy₀)
  have hL0 : 0 ≤ L := by
    have h := hlip t₀ ht₀ (y₀ + b) ⟨by linarith, by linarith⟩ y₀ hy₀
    rw [show y₀ + b - y₀ = b by ring, abs_of_pos hb] at h
    by_contra hneg
    push Not at hneg
    nlinarith [abs_nonneg (f t₀ (y₀ + b) - f t₀ y₀)]
  have htime : ∀ t ∈ Icc (t₀ - T) (t₀ + T), t ∈ Icc (t₀ - a) (t₀ + a) := fun t ht =>
    ⟨by linarith [ht.1], by linarith [ht.2]⟩
  have hlipW : ∀ t ∈ Icc (t₀ - a) (t₀ + a),
      LipschitzOnWith (Real.toNNReal L) (f t) (Icc (y₀ - b) (y₀ + b)) := by
    intro t ht
    apply LipschitzOnWith.of_dist_le_mul
    intro y hy z hz
    rw [Real.dist_eq, Real.dist_eq, Real.coe_toNNReal _ hL0]
    exact hlip t ht y hy z hz
  have hpl : IsPicardLindelof f (tmin := t₀ - T) (tmax := t₀ + T)
      ⟨t₀, ⟨by linarith, by linarith⟩⟩ y₀ ⟨b, hb.le⟩ 0 ⟨M, hM0⟩ (Real.toNNReal L) := by
    constructor
    · intro t ht
      simp only [Real.closedBall_eq_Icc]
      exact hlipW t (htime t ht)
    · intro x hx
      simp only [Real.closedBall_eq_Icc] at hx
      have hx' : x ∈ Icc (y₀ - b) (y₀ + b) := hx
      exact hcont.comp (f := fun t => (t, x)) (continuous_id.prodMk continuous_const).continuousOn
        (fun t ht => ⟨htime t ht, hx'⟩)
    · intro t ht x hx
      simp only [Real.closedBall_eq_Icc] at hx
      rw [Real.norm_eq_abs]
      exact hM t (htime t ht) x (hx : x ∈ Icc (y₀ - b) (y₀ + b))
    · simp only [NNReal.coe_zero, sub_zero]
      rw [show t₀ + T - t₀ = T by ring, show t₀ - (t₀ - T) = T by ring, max_self]
      exact hTb
  obtain ⟨α, hα0, hα⟩ := hpl.exists_eq_forall_mem_Icc_hasDerivWithinAt₀
  refine ⟨α, hα0, hα, ?_⟩
  intro z hz0 hz
  have hzs := pl_stays f t₀ y₀ a b M T hM hM0 hb hTa hTb z hz0 hz
  have hαs := pl_stays f t₀ y₀ a b M T hM hM0 hb hTa hTb α hα0 hα
  have hzc : ContinuousOn z (Icc (t₀ - T) (t₀ + T)) := fun s hs => (hz s hs).continuousWithinAt
  have hαc : ContinuousOn α (Icc (t₀ - T) (t₀ + T)) := fun s hs => (hα s hs).continuousWithinAt
  rw [← Icc_union_Icc_eq_Icc (show t₀ - T ≤ t₀ by linarith) (show t₀ ≤ t₀ + T by linarith)]
  apply EqOn.union
  · refine ODE_solution_unique_of_mem_Icc_left (v := f) (s := fun _ => Icc (y₀ - b) (y₀ + b))
      (K := Real.toNNReal L) (fun t ht => hlipW t ⟨by linarith [ht.1], by linarith [ht.2]⟩)
      (hzc.mono (Icc_subset_Icc_right (by linarith)))
      (fun t ht => (hz t ⟨ht.1.le, by linarith [ht.2]⟩).mono_of_mem_nhdsWithin
        (Filter.mem_of_superset (Icc_mem_nhdsLE ht.1) (Icc_subset_Icc_right (by linarith [ht.2]))))
      (fun t ht => hzs t ⟨ht.1, by linarith [ht.1, ht.2]⟩)
      (hαc.mono (Icc_subset_Icc_right (by linarith)))
      (fun t ht => (hα t ⟨ht.1.le, by linarith [ht.2]⟩).mono_of_mem_nhdsWithin
        (Filter.mem_of_superset (Icc_mem_nhdsLE ht.1) (Icc_subset_Icc_right (by linarith [ht.2]))))
      (fun t ht => hαs t ⟨ht.1, by linarith [ht.1, ht.2]⟩) (by rw [hz0, hα0])
  · refine ODE_solution_unique_of_mem_Icc_right (v := f) (s := fun _ => Icc (y₀ - b) (y₀ + b))
      (K := Real.toNNReal L) (fun t ht => hlipW t ⟨by linarith [ht.1], by linarith [ht.2]⟩)
      (hzc.mono (Icc_subset_Icc_left (by linarith)))
      (fun t ht => (hz t ⟨by linarith [ht.1], ht.2.le⟩).mono_of_mem_nhdsWithin
        (Filter.mem_of_superset (Icc_mem_nhdsGE ht.2) (Icc_subset_Icc_left (by linarith [ht.1]))))
      (fun t ht => hzs t ⟨by linarith [ht.1, ht.2], ht.2⟩)
      (hαc.mono (Icc_subset_Icc_left (by linarith)))
      (fun t ht => (hα t ⟨by linarith [ht.1], ht.2.le⟩).mono_of_mem_nhdsWithin
        (Filter.mem_of_superset (Icc_mem_nhdsGE ht.2) (Icc_subset_Icc_left (by linarith [ht.1]))))
      (fun t ht => hαs t ⟨by linarith [ht.1, ht.2], ht.2⟩) (by rw [hz0, hα0])

/-- The empty bucket has many pasts. The bucket's rule is `h' = -0.2 √h`. Three depth curves
obey it at every time: full (25 cm) at minute 0 and draining as `(5 - t/10)²` until empty at
minute 50; 9 cm at minute 0 and draining as `(3 - t/10)²` until empty at minute 30; and always
empty. All three read 0 cm at minute 50, yet they start at 25, 9 and 0 cm: the rule alone
cannot say how deep the bucket was. -/
theorem empty_bucket_has_many_pasts :
    let hA : ℝ → ℝ := fun t => (max (5 - t / 10) 0) ^ 2
    let hB : ℝ → ℝ := fun t => (max (3 - t / 10) 0) ^ 2
    let hZ : ℝ → ℝ := fun _ => 0
    (∀ t : ℝ, HasDerivAt hA (-(1 / 5) * Real.sqrt (hA t)) t) ∧
    (∀ t : ℝ, HasDerivAt hB (-(1 / 5) * Real.sqrt (hB t)) t) ∧
    (∀ t : ℝ, HasDerivAt hZ (-(1 / 5) * Real.sqrt (hZ t)) t) ∧
    hA 50 = 0 ∧ hB 50 = 0 ∧ hZ 50 = 0 ∧
    hA 0 = 25 ∧ hB 0 = 9 ∧ hZ 0 = 0 := by
  intro hA hB hZ
  refine ⟨bucket_curve 5, bucket_curve 3, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro t
    simpa [hZ] using hasDerivAt_const t (0 : ℝ)
  all_goals norm_num [hA, hB, hZ]

/-- The bucket's box: times within 10 minutes of the start, depths within 16 cm of 25 cm, so
depths from 9 to 41 cm. There the rule `-0.2 √h` has Lipschitz constant `0.1/√9 = 1/30` per
minute and size at most `0.2 √41` cm per minute; with `T = 10` the promised shrink per Picard
round is `L * T = 1/3`. -/
theorem bucket_box_constants :
    (∀ y ∈ Icc (9 : ℝ) 41, ∀ z ∈ Icc (9 : ℝ) 41,
      |-(1 / 5) * Real.sqrt y - -(1 / 5) * Real.sqrt z| ≤ 1 / 30 * |y - z|) ∧
    (∀ y ∈ Icc (9 : ℝ) 41, |-(1 / 5) * Real.sqrt y| ≤ 1 / 5 * Real.sqrt 41) ∧
    (1 / 5 * Real.sqrt 41) * 10 ≤ (16 : ℝ) := by
  refine ⟨?_, ?_, ?_⟩
  · intro y hy z hz
    have hy0 : (0 : ℝ) ≤ y := by linarith [hy.1]
    have hz0 : (0 : ℝ) ≤ z := by linarith [hz.1]
    have hu : 3 ≤ Real.sqrt y := by
      rw [show (3 : ℝ) = Real.sqrt 9 by rw [show (9 : ℝ) = 3 ^ 2 by norm_num,
        Real.sqrt_sq (by norm_num)]]
      exact Real.sqrt_le_sqrt hy.1
    have hv : 3 ≤ Real.sqrt z := by
      rw [show (3 : ℝ) = Real.sqrt 9 by rw [show (9 : ℝ) = 3 ^ 2 by norm_num,
        Real.sqrt_sq (by norm_num)]]
      exact Real.sqrt_le_sqrt hz.1
    have e1 := Real.sq_sqrt hy0
    have e2 := Real.sq_sqrt hz0
    set u := Real.sqrt y
    set v := Real.sqrt z
    rcases le_total u v with h | h
    · rw [abs_of_nonneg (by linarith : (0 : ℝ) ≤ -(1 / 5) * u - -(1 / 5) * v),
        abs_of_nonpos (by nlinarith : y - z ≤ 0)]
      nlinarith
    · rw [abs_of_nonpos (by linarith : -(1 / 5) * u - -(1 / 5) * v ≤ (0 : ℝ)),
        abs_of_nonneg (by nlinarith : (0 : ℝ) ≤ y - z)]
      nlinarith
  · intro y hy
    rw [abs_of_nonpos (by nlinarith [Real.sqrt_nonneg y])]
    have := Real.sqrt_le_sqrt hy.2
    linarith
  · nlinarith [Real.sq_sqrt (show (0 : ℝ) ≤ 41 by norm_num), Real.sqrt_nonneg 41]

-- The box: the floor sits at 25 - 16 = 9 cm, and the steepest slope there is 0.1/√9 = 1/30.
example : (25 : ℝ) - 16 = 9 ∧ Real.sqrt 9 = 3 ∧ (1 / 10 : ℝ) / Real.sqrt 9 = 1 / 30 := by norm_num
-- The rate at the start: 0.2 √25 = 1 cm a minute; the slope at 25 cm is 0.1/√25 = 0.02.
example : (1 / 5 : ℝ) * Real.sqrt 25 = 1 ∧ (1 / 10 : ℝ) / Real.sqrt 25 = 1 / 50 := by norm_num
-- Promised shrink per round: L * T = (1/30) * 10 = 1/3.
example : (1 / 30 : ℚ) * 10 = 1 / 3 := by norm_num
-- Round 1 at 10 minutes: 25 + 10 * (-0.2 * 5) = 15 cm.
example : (25 : ℚ) + 10 * (-(1 / 5) * 5) = 15 := by norm_num
-- Step 3: the moves total at most 10 + 10/3 + 10/9 + ... = 10 / (1 - 1/3) = 15 cm.
example : (10 : ℚ) / (1 - 1 / 3) = 15 := by norm_num
-- The separation formula: (5 - 0.1 * 10)^2 = 16 cm after 10 minutes.
example : ((5 : ℚ) - 10 / 10) ^ 2 = 16 := by norm_num
-- The three pasts: curve A is full at 0 and empty at 50; curve B holds 9 cm at 0 and is empty at 30.
example : ((5 : ℚ) - 0 / 10) ^ 2 = 25 ∧ ((5 : ℚ) - 50 / 10) ^ 2 = 0 ∧
    ((3 : ℚ) - 0 / 10) ^ 2 = 9 ∧ ((3 : ℚ) - 30 / 10) ^ 2 = 0 := by norm_num
-- Stretching the window to 40 minutes: L * T = 4/3, and the depth hits the box's floor, 9 cm, at 20 minutes.
example : (1 / 30 : ℚ) * 40 = 4 / 3 ∧ ((5 : ℚ) - 20 / 10) ^ 2 = 9 := by norm_num
-- Try changing: with A = 5 the promise is (1/30) * 5 = 1/6 and the rounds land on (5 - 0.5)^2 = 20.25 cm;
-- with rate -0.3 they land on (5 - 1.5)^2 = 12.25 cm.
example : (1 / 30 : ℚ) * 5 = 1 / 6 ∧ ((5 : ℚ) - 5 / 10) ^ 2 = 81 / 4 ∧
    ((5 : ℚ) - 3 / 10 * 5) ^ 2 = 49 / 4 := by norm_num

#print axioms pl_stay_right
#print axioms pl_stays
#print axioms bucket_curve
#print axioms picard_lindelof_exactly_one_solution
#print axioms empty_bucket_has_many_pasts
#print axioms bucket_box_constants
