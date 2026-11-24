-- Mittag-Leffler: poles that run off to infinity, each with any chosen principal part, are the poles of one function built by subtracting from each principal part its Taylor polynomial at 0, that function is unique up to adding an entire function, and the integer poles give the series for pi cot(pi z) and pi^2/sin^2(pi z).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Cotangent
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Analytic.Basic
import Mathlib.Tactic.NormNum

open Complex Filter Topology Real

/-- The principal part at the pole `a k`: a finite sum of constants `c k j` over the powers
`(z - a k) ^ (j + 1)`, for `j` below the order `m k`. -/
noncomputable def principalPart {ι : Type*} (a : ι → ℂ) (m : ι → ℕ) (c : ι → ℕ → ℂ)
    (k : ι) (z : ℂ) : ℂ :=
  ∑ j ∈ Finset.range (m k), c k j / (z - a k) ^ (j + 1)

/-- The correction `q k`: the Taylor polynomial at 0 of the principal part at `a k`, up to the
power `d k`. A pole at 0 gets no correction. -/
noncomputable def taylorCorrection {ι : Type*} (a : ι → ℂ) (m : ι → ℕ) (c : ι → ℕ → ℂ)
    (d : ι → ℕ) (k : ι) (z : ℂ) : ℂ :=
  if a k = 0 then 0 else
    ∑ i ∈ Finset.range (d k + 1),
      iteratedDeriv i (principalPart a m c k) 0 / (i.factorial : ℂ) * z ^ i

/-- Helper: the Taylor polynomials at 0 of a function differentiable on the disc of radius `r`
approach it uniformly on the disc of radius `r / 2`. -/
theorem ml_taylor_unif (P : ℂ → ℂ) (r : ℝ) (hr : 0 < r)
    (hP : DifferentiableOn ℂ P (Metric.ball 0 r)) (ε : ℝ) (hε : 0 < ε) :
    ∃ D : ℕ, ∀ z : ℂ, ‖z‖ < r / 2 →
      ‖P z - ∑ i ∈ Finset.range (D + 1), iteratedDeriv i P 0 / (i.factorial : ℂ) * z ^ i‖ < ε := by
  have hR0 : (0 : ℝ) ≤ 3 * r / 4 := by positivity
  have hR2 : (0 : ℝ) ≤ r / 2 := by positivity
  set R : NNReal := (3 * r / 4).toNNReal with hRdef
  have hRc : (R : ℝ) = 3 * r / 4 := Real.coe_toNNReal _ hR0
  have hR : (0 : NNReal) < R := by
    rw [← NNReal.coe_lt_coe, hRc]; simp; positivity
  have hcl : DifferentiableOn ℂ P (Metric.closedBall 0 R) :=
    hP.mono (Metric.closedBall_subset_ball (by rw [hRc]; linarith))
  have hb := hcl.hasFPowerSeriesOnBall hR
  have han : AnalyticAt ℂ P 0 := hb.analyticAt
  have heq := hb.hasFPowerSeriesAt.eq_formalMultilinearSeries han.hasFPowerSeriesAt
  rw [heq] at hb
  have hu := hb.tendstoUniformlyOn (r' := (r / 2).toNNReal) (by
    rw [ENNReal.coe_lt_coe, ← NNReal.coe_lt_coe, hRc, Real.coe_toNNReal _ hR2]; linarith)
  rw [Metric.tendstoUniformlyOn_iff] at hu
  obtain ⟨N, hN⟩ := eventually_atTop.1 (hu ε hε)
  refine ⟨N, fun z hz => ?_⟩
  have := hN (N + 1) (by omega) z (by simpa [Real.coe_toNNReal _ hR2] using hz)
  rw [dist_eq_norm] at this
  simpa [FormalMultilinearSeries.partialSum, FormalMultilinearSeries.ofScalars_apply_eq,
    mul_comm] using this

#print axioms ml_taylor_unif

/-- Helper: a principal part is complex-differentiable away from its pole. -/
theorem ml_principalPart_differentiableAt {ι : Type*} (a : ι → ℂ) (m : ι → ℕ)
    (c : ι → ℕ → ℂ) (k : ι) (w : ℂ) (hw : w ≠ a k) :
    DifferentiableAt ℂ (principalPart a m c k) w := by
  have hne : w - a k ≠ 0 := sub_ne_zero.2 hw
  show DifferentiableAt ℂ (fun z => ∑ j ∈ Finset.range (m k), c k j / (z - a k) ^ (j + 1)) w
  apply DifferentiableAt.fun_sum
  intro j _
  exact (differentiableAt_const _).div ((differentiableAt_id.sub_const _).pow _)
    (pow_ne_zero _ hne)

#print axioms ml_principalPart_differentiableAt

/-- Helper: a Taylor correction is a polynomial, so it is differentiable everywhere. -/
theorem ml_taylorCorrection_differentiable {ι : Type*} (a : ι → ℂ) (m : ι → ℕ)
    (c : ι → ℕ → ℂ) (d : ι → ℕ) (k : ι) : Differentiable ℂ (taylorCorrection a m c d k) := by
  by_cases h : a k = 0
  · have : taylorCorrection a m c d k = fun _ => 0 := by
      funext z; rw [taylorCorrection, if_pos h]
    rw [this]; exact differentiable_const _
  · have : taylorCorrection a m c d k = fun z => ∑ i ∈ Finset.range (d k + 1),
        iteratedDeriv i (principalPart a m c k) 0 / (i.factorial : ℂ) * z ^ i := by
      funext z; rw [taylorCorrection, if_neg h]
    rw [this]; fun_prop

#print axioms ml_taylorCorrection_differentiable

/-- Helper: poles that run off to infinity are isolated, so near any point there are no
poles except possibly the point itself. -/
theorem ml_eventually_not_mem_range {ι : Type*} (a : ι → ℂ)
    (hfin : ∀ R : ℝ, {k | ‖a k‖ ≤ R}.Finite) (z : ℂ) :
    ∀ᶠ w in 𝓝[≠] z, w ∉ Set.range a := by
  set S := {k | ‖a k‖ ≤ ‖z‖ + 1}
  have hF : ((a '' S) \ {z}).Finite := ((hfin _).image a).subset Set.sdiff_subset
  have h1 : ((a '' S) \ {z})ᶜ ∈ 𝓝 z := hF.isClosed.isOpen_compl.mem_nhds (fun h => h.2 rfl)
  have h2 : Metric.ball z 1 ∈ 𝓝 z := Metric.ball_mem_nhds z one_pos
  filter_upwards [nhdsWithin_le_nhds h1, nhdsWithin_le_nhds h2, self_mem_nhdsWithin]
    with w hw1 hw2 hw3
  rintro ⟨k, rfl⟩
  apply hw1
  refine ⟨⟨k, ?_, rfl⟩, hw3⟩
  rw [Metric.mem_ball, dist_eq_norm] at hw2
  show ‖a k‖ ≤ ‖z‖ + 1
  have := norm_sub_norm_le (a k) z
  linarith

#print axioms ml_eventually_not_mem_range

/-- Helper: the set of poles is closed, so its complement is a neighbourhood of each of its
points. -/
theorem ml_compl_range_mem_nhds {ι : Type*} (a : ι → ℂ)
    (hfin : ∀ R : ℝ, {k | ‖a k‖ ≤ R}.Finite) (z : ℂ) (hz : z ∉ Set.range a) :
    (Set.range a)ᶜ ∈ 𝓝 z := by
  have := eventually_nhdsWithin_iff.1 (ml_eventually_not_mem_range a hfin z)
  filter_upwards [this] with w hw
  by_cases hwz : w = z
  · rw [hwz]; exact hz
  · exact hw hwz

#print axioms ml_compl_range_mem_nhds

/-- Helper: split a series into finitely many chosen terms and a tail that is uniformly
bounded by a summable sequence on an open set; the tail is then differentiable there. -/
theorem ml_split_sum {ι : Type*} [DecidableEq ι] (T : ι → ℂ → ℂ) (ε : ι → ℝ) (hε : Summable ε)
    (Fs : Finset ι) (U : Set ℂ) (hU : IsOpen U)
    (hdiff : ∀ k ∉ Fs, DifferentiableOn ℂ (T k) U)
    (hbd : ∀ k ∉ Fs, ∀ w ∈ U, ‖T k w‖ ≤ ε k) (hε0 : ∀ k, 0 ≤ ε k) :
    DifferentiableOn ℂ (fun w => ∑' k, if k ∈ Fs then 0 else T k w) U ∧
    ∀ w ∈ U, Summable (fun k => T k w) ∧
      ∑' k, T k w = ∑ k ∈ Fs, T k w + ∑' k, (if k ∈ Fs then 0 else T k w) := by
  have hb : ∀ k, ∀ w ∈ U, ‖(if k ∈ Fs then 0 else T k w)‖ ≤ ε k := by
    intro k w hw
    by_cases hk : k ∈ Fs
    · simp [hk, hε0 k]
    · simp only [hk, if_false]; exact hbd k hk w hw
  refine ⟨?_, fun w hw => ?_⟩
  · apply differentiableOn_tsum_of_summable_norm hε _ hU hb
    intro k
    by_cases hk : k ∈ Fs
    · simp only [hk, if_true]; exact differentiableOn_const _
    · simp only [hk, if_false]; exact hdiff k hk
  · have hs2 : Summable (fun k => if k ∈ Fs then 0 else T k w) :=
      Summable.of_norm_bounded hε (fun k => hb k w hw)
    have hs1 : Summable (fun k => if k ∈ Fs then T k w else 0) := by
      apply summable_of_ne_finset_zero (s := Fs)
      intro k hk; simp [hk]
    have hsplit : (fun k => T k w) =
        fun k => (if k ∈ Fs then T k w else 0) + (if k ∈ Fs then 0 else T k w) := by
      funext k; by_cases hk : k ∈ Fs <;> simp [hk]
    have hsum1 : ∑' k, (if k ∈ Fs then T k w else 0) = ∑ k ∈ Fs, T k w := by
      rw [tsum_eq_sum (s := Fs) (fun k hk => by simp [hk])]
      exact Finset.sum_congr rfl (fun k hk => by simp [hk])
    refine ⟨by rw [hsplit]; exact hs1.add hs2, ?_⟩
    calc ∑' k, T k w = ∑' k, ((if k ∈ Fs then T k w else 0) + (if k ∈ Fs then 0 else T k w)) :=
          tsum_congr (fun k => by by_cases hk : k ∈ Fs <;> simp [hk])
      _ = _ := by rw [hs1.tsum_add hs2, hsum1]

#print axioms ml_split_sum

/-- Mittag-Leffler's theorem on the whole plane. Choose distinct poles `a k` that run off to
infinity (only finitely many in any disc) and a principal part at each. Then for some choice of
powers `d k`, the corrected terms `P k - q k` add up, in any order, at every point that is not a
pole; the sum `f` is complex-differentiable off the poles, and near each pole `a k` it is that
pole's principal part plus a function analytic there. Any other function `F` with the same poles
and principal parts differs from `f` by an entire function `h`. -/
theorem mittag_leffler_taylor_corrected_sum {ι : Type*} (a : ι → ℂ)
    (ha : Function.Injective a) (hfin : ∀ R : ℝ, {k | ‖a k‖ ≤ R}.Finite)
    (m : ι → ℕ) (c : ι → ℕ → ℂ) :
    ∃ d : ι → ℕ,
      (∀ z ∉ Set.range a,
        Summable fun k => principalPart a m c k z - taylorCorrection a m c d k z) ∧
      DifferentiableOn ℂ
        (fun z => ∑' k, (principalPart a m c k z - taylorCorrection a m c d k z))
        (Set.range a)ᶜ ∧
      (∀ k, ∃ g : ℂ → ℂ, AnalyticAt ℂ g (a k) ∧ ∀ᶠ z in 𝓝[≠] a k,
        ∑' i, (principalPart a m c i z - taylorCorrection a m c d i z) =
          principalPart a m c k z + g z) ∧
      (∀ F : ℂ → ℂ, DifferentiableOn ℂ F (Set.range a)ᶜ →
        (∀ k, ∃ g : ℂ → ℂ, AnalyticAt ℂ g (a k) ∧
          ∀ᶠ z in 𝓝[≠] a k, F z = principalPart a m c k z + g z) →
        ∃ h : ℂ → ℂ, Differentiable ℂ h ∧ ∀ z ∉ Set.range a,
          F z = ∑' i, (principalPart a m c i z - taylorCorrection a m c d i z) + h z) := by
  classical
  -- the poles are countable, so give them summable weights `ε k`
  have hcount : Countable ι := by
    have hU : (Set.univ : Set ι) = ⋃ n : ℕ, {k | ‖a k‖ ≤ n} := by
      ext k
      simp only [Set.mem_univ, Set.mem_iUnion, Set.mem_setOf_eq, true_iff]
      exact exists_nat_ge _
    exact Set.countable_univ_iff.1 (hU ▸ Set.countable_iUnion fun n => (hfin n).countable)
  obtain ⟨e, he⟩ := Countable.exists_injective_nat ι
  have hε0 : ∀ k, 0 < ((1 : ℝ) / 2) ^ (e k) := fun k => by positivity
  have hεs : Summable fun k => ((1 : ℝ) / 2) ^ (e k) := summable_geometric_two.comp_injective he
  -- choose the degrees `d k`
  have hex : ∀ k, ∃ D : ℕ, a k ≠ 0 → ∀ z : ℂ, ‖z‖ < ‖a k‖ / 2 →
      ‖principalPart a m c k z - ∑ i ∈ Finset.range (D + 1),
        iteratedDeriv i (principalPart a m c k) 0 / (i.factorial : ℂ) * z ^ i‖ <
          ((1 : ℝ) / 2) ^ (e k) := by
    intro k
    by_cases h : a k = 0
    · exact ⟨0, fun h' => absurd h h'⟩
    · have hr : 0 < ‖a k‖ := norm_pos_iff.2 h
      have hP : DifferentiableOn ℂ (principalPart a m c k) (Metric.ball 0 ‖a k‖) := by
        intro w hw
        apply DifferentiableAt.differentiableWithinAt
        apply ml_principalPart_differentiableAt
        rintro rfl
        simp at hw
      obtain ⟨D, hD⟩ := ml_taylor_unif _ _ hr hP _ (hε0 k)
      exact ⟨D, fun _ => hD⟩
  choose d hd using hex
  refine ⟨d, ?_⟩
  -- the corrected terms are small on the disc of half the pole's radius
  have hTb : ∀ k z, ‖z‖ < ‖a k‖ / 2 →
      ‖principalPart a m c k z - taylorCorrection a m c d k z‖ ≤ ((1 : ℝ) / 2) ^ (e k) := by
    intro k z hz
    have hak : a k ≠ 0 := by
      intro h; rw [h, norm_zero] at hz; linarith [norm_nonneg z]
    rw [taylorCorrection, if_neg hak]
    exact (hd k hak z hz).le
  have hTd : ∀ k w, w ≠ a k →
      DifferentiableAt ℂ (fun z => principalPart a m c k z - taylorCorrection a m c d k z) w :=
    fun k w hw => (ml_principalPart_differentiableAt a m c k w hw).sub
      (ml_taylorCorrection_differentiable a m c d k w)
  -- on the disc of radius `R`, split off the finitely many poles with `‖a k‖ ≤ 2 R`
  have hsplitR : ∀ R : ℝ, 0 < R → ∃ Fs : Finset ι, (∀ k, ‖a k‖ ≤ 2 * R → k ∈ Fs) ∧
      DifferentiableOn ℂ (fun w => ∑' k, if k ∈ Fs then 0 else
        (principalPart a m c k w - taylorCorrection a m c d k w)) (Metric.ball 0 R) ∧
      ∀ w ∈ Metric.ball (0 : ℂ) R,
        Summable (fun k => principalPart a m c k w - taylorCorrection a m c d k w) ∧
        ∑' k, (principalPart a m c k w - taylorCorrection a m c d k w) =
          ∑ k ∈ Fs, (principalPart a m c k w - taylorCorrection a m c d k w) +
          ∑' k, (if k ∈ Fs then 0 else
            (principalPart a m c k w - taylorCorrection a m c d k w)) := by
    intro R hR
    refine ⟨(hfin (2 * R)).toFinset, fun k hk => by simpa using hk, ?_⟩
    have hout : ∀ k ∉ (hfin (2 * R)).toFinset, 2 * R < ‖a k‖ := by
      intro k hk; simpa using hk
    exact ml_split_sum (fun k z => principalPart a m c k z - taylorCorrection a m c d k z)
      _ hεs _ _ Metric.isOpen_ball
      (fun k hk w hw => (hTd k w (by
          intro h; have := hout k hk; rw [mem_ball_zero_iff, h] at hw; linarith)
        ).differentiableWithinAt)
      (fun k hk w hw => hTb k w (by
        have := hout k hk; rw [mem_ball_zero_iff] at hw; linarith))
      (fun k => (hε0 k).le)
  -- local form of the sum near any point
  have hloc : ∀ z : ℂ, ∃ Fs : Finset ι, ∃ G : ℂ → ℂ, (∀ k, ‖a k‖ ≤ ‖z‖ + 1 → k ∈ Fs) ∧
      AnalyticAt ℂ G z ∧ ∀ᶠ w in 𝓝 z,
        ∑' k, (principalPart a m c k w - taylorCorrection a m c d k w) =
          ∑ k ∈ Fs, (principalPart a m c k w - taylorCorrection a m c d k w) + G w := by
    intro z
    obtain ⟨Fs, hFs, hG, hS⟩ := hsplitR (‖z‖ + 1) (by positivity)
    have hzb : z ∈ Metric.ball (0 : ℂ) (‖z‖ + 1) := by rw [mem_ball_zero_iff]; linarith
    refine ⟨Fs, _, fun k hk => hFs k (by linarith [norm_nonneg z]),
      hG.analyticAt (Metric.isOpen_ball.mem_nhds hzb), ?_⟩
    filter_upwards [Metric.isOpen_ball.mem_nhds hzb] with w hw
    exact (hS w hw).2
  have h1 : ∀ z ∉ Set.range a,
      Summable fun k => principalPart a m c k z - taylorCorrection a m c d k z := by
    intro z _
    obtain ⟨Fs, -, -, hS⟩ := hsplitR (‖z‖ + 1) (by positivity)
    exact (hS z (by rw [mem_ball_zero_iff]; linarith)).1
  have h2 : DifferentiableOn ℂ
      (fun z => ∑' k, (principalPart a m c k z - taylorCorrection a m c d k z))
      (Set.range a)ᶜ := by
    intro z hz
    obtain ⟨Fs, G, -, hG, hev⟩ := hloc z
    apply DifferentiableAt.differentiableWithinAt
    refine DifferentiableAt.congr_of_eventuallyEq ?_ hev
    apply DifferentiableAt.add _ hG.differentiableAt
    apply DifferentiableAt.fun_sum
    intro k _
    exact hTd k z (fun h => hz ⟨k, h.symm⟩)
  have h3 : ∀ k, ∃ g : ℂ → ℂ, AnalyticAt ℂ g (a k) ∧ ∀ᶠ z in 𝓝[≠] a k,
      ∑' i, (principalPart a m c i z - taylorCorrection a m c d i z) =
        principalPart a m c k z + g z := by
    intro k
    obtain ⟨Fs, G, hFs, hG, hev⟩ := hloc (a k)
    have hk : k ∈ Fs := hFs k (by linarith)
    refine ⟨fun w => ∑ i ∈ Fs.erase k,
      (principalPart a m c i w - taylorCorrection a m c d i w) -
        taylorCorrection a m c d k w + G w, ?_, ?_⟩
    · apply AnalyticAt.fun_add _ hG
      apply AnalyticAt.fun_sub _ ((ml_taylorCorrection_differentiable a m c d k).analyticAt (a k))
      apply Finset.analyticAt_fun_sum
      intro i hi
      have hne : a k ≠ a i := fun h => (Finset.ne_of_mem_erase hi) (ha h).symm
      have hdo : DifferentiableOn ℂ
          (fun w => principalPart a m c i w - taylorCorrection a m c d i w) {a i}ᶜ :=
        fun w hw => (hTd i w hw).differentiableWithinAt
      exact hdo.analyticAt (isOpen_compl_singleton.mem_nhds hne)
    · filter_upwards [nhdsWithin_le_nhds hev] with w hw
      rw [hw, ← Finset.add_sum_erase Fs
        (fun i => principalPart a m c i w - taylorCorrection a m c d i w) hk]
      ring
  have h4 : ∀ F : ℂ → ℂ, DifferentiableOn ℂ F (Set.range a)ᶜ →
      (∀ k, ∃ g : ℂ → ℂ, AnalyticAt ℂ g (a k) ∧
        ∀ᶠ z in 𝓝[≠] a k, F z = principalPart a m c k z + g z) →
      ∃ h : ℂ → ℂ, Differentiable ℂ h ∧ ∀ z ∉ Set.range a,
        F z = ∑' i, (principalPart a m c i z - taylorCorrection a m c d i z) + h z := by
    intro F hFd hF
    choose gF hgFa hgFe using hF
    choose gf hgfa hgfe using h3
    refine ⟨fun z => if hz : ∃ k, a k = z then gF hz.choose z - gf hz.choose z else
      F z - ∑' i, (principalPart a m c i z - taylorCorrection a m c d i z), ?_, ?_⟩
    · intro z
      by_cases hz : ∃ k, a k = z
      · obtain ⟨k, rfl⟩ := hz
        have hev : ∀ᶠ w in 𝓝[≠] a k, (if hz : ∃ k, a k = w then gF hz.choose w - gf hz.choose w
            else F w - ∑' i, (principalPart a m c i w - taylorCorrection a m c d i w)) =
            gF k w - gf k w := by
          filter_upwards [hgFe k, hgfe k, ml_eventually_not_mem_range a hfin (a k)]
            with w hw1 hw2 hw3
          have hw3' : ¬ ∃ j, a j = w := hw3
          rw [dif_neg hw3', hw1, hw2]
          ring
        have hev' : (fun w => if hz : ∃ k, a k = w then gF hz.choose w - gf hz.choose w
            else F w - ∑' i, (principalPart a m c i w - taylorCorrection a m c d i w)) =ᶠ[𝓝 (a k)]
            fun w => gF k w - gf k w := by
          filter_upwards [eventually_nhdsWithin_iff.1 hev] with w hw
          by_cases hwk : w = a k
          · subst hwk
            have hex : ∃ j, a j = a k := ⟨k, rfl⟩
            rw [dif_pos hex]
            have : hex.choose = k := ha hex.choose_spec
            rw [this]
          · exact hw hwk
        exact ((hgFa k).fun_sub (hgfa k)).differentiableAt.congr_of_eventuallyEq hev'
      · have hz' : z ∉ Set.range a := hz
        have hn := ml_compl_range_mem_nhds a hfin z hz'
        have hFz : DifferentiableAt ℂ F z := (hFd z hz').differentiableAt hn
        have hfz := (h2 z hz').differentiableAt hn
        refine (hFz.sub hfz).congr_of_eventuallyEq ?_
        filter_upwards [hn] with w hw
        exact dif_neg hw
    · intro z hz
      have hz' : ¬ ∃ k, a k = z := hz
      simp only [dif_neg hz']
      ring
  exact ⟨h1, h2, h3, h4⟩

/-- The row of wires: away from the integers, `π cot(π z)` is `1/z` plus, for each pair of
wires at `±n`, the term `2z / (z² − n²)`. -/
theorem pi_cot_pi_eq_one_div_add_series (z : ℂ) (hz : ∀ n : ℤ, z ≠ n) :
    HasSum (fun n : ℕ => 2 * z / (z ^ 2 - ((n : ℂ) + 1) ^ 2))
      (π * Complex.cot (π * z) - 1 / z) := by
  have hz' : z ∈ Complex.integerComplement := fun ⟨n, hn⟩ => hz n hn.symm
  have h := (summable_cotTerm hz').hasSum
  rw [← cot_series_rep' hz'] at h
  convert h using 1
  funext n
  rw [cotTerm_identity hz' n, mul_one_div]
  congr 1
  ring

/-- Helper: the derivative of `π cot (π w) - 1 / w` off the integers. -/
theorem ml_hasDerivAt_pi_cot_sub (z : ℂ) (hz : z ∈ Complex.integerComplement) :
    HasDerivAt (fun w : ℂ => π * Complex.cot (π * w) - 1 / w)
      (-(π ^ 2 / Complex.sin (π * z) ^ 2) + 1 / z ^ 2) z := by
  have hs : Complex.sin (π * z) ≠ 0 := sin_pi_mul_ne_zero hz
  have hz0 : z ≠ 0 := Complex.integerComplement.ne_zero hz
  have h1 : HasDerivAt (fun w : ℂ => π * w) π z := by
    simpa using (hasDerivAt_id z).const_mul (π : ℂ)
  have hc := (Complex.hasDerivAt_cos (π * z)).comp z h1
  have hsn := (Complex.hasDerivAt_sin (π * z)).comp z h1
  have hq := hc.div hsn hs
  have hinv := (hasDerivAt_id z).inv hz0
  have := (hq.const_mul (π : ℂ)).sub hinv
  convert this using 1
  · funext w; simp [Complex.cot_eq_cos_div_sin, one_div]
  · have hcs := Complex.sin_sq_add_cos_sq ((π : ℂ) * z)
    simp only [Function.comp_apply, id]
    rw [show -Complex.sin ((π : ℂ) * z) * π * Complex.sin (π * z) -
        Complex.cos (π * z) * (Complex.cos (π * z) * π) =
        -(π : ℂ) * (Complex.sin (π * z) ^ 2 + Complex.cos (π * z) ^ 2) by ring, hcs]
    ring

#print axioms ml_hasDerivAt_pi_cot_sub

/-- The squared series: away from the integers, `π² / sin²(π z)` is the plain sum over every
integer `n` of `1 / (z − n)²`. -/
theorem pi_sq_div_sin_sq_eq_series (z : ℂ) (hz : ∀ n : ℤ, z ≠ n) :
    HasSum (fun n : ℤ => 1 / (z - n) ^ 2) (π ^ 2 / Complex.sin (π * z) ^ 2) := by
  have hz' : z ∈ Complex.integerComplement := fun ⟨n, hn⟩ => hz n hn.symm
  have hU : IsOpen Complex.integerComplement := Complex.isOpen_compl_range_intCast
  obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.1 hU z hz'
  set A : ℝ := ‖z‖ + ε with hA
  have hA0 : 0 < A := by positivity
  set c : ℝ := min (1 / 2) (ε / (4 * A)) with hc
  have hc0 : 0 < c := by positivity
  -- distance from points of the small ball to the integers
  have hfar : ∀ w ∈ Metric.ball z (ε / 2), ∀ m : ℤ, ε / 2 ≤ ‖w - m‖ := by
    intro w hw m
    by_contra hlt
    push_neg at hlt
    have hm : (m : ℂ) ∈ Metric.ball z ε := by
      rw [Metric.mem_ball] at hw ⊢
      calc dist (m : ℂ) z ≤ dist (m : ℂ) w + dist w z := dist_triangle _ _ _
        _ < ε / 2 + ε / 2 := by
          rw [dist_comm, dist_eq_norm]; exact add_lt_add hlt hw
        _ = ε := by ring
    exact hball hm ⟨m, rfl⟩
  have hwA : ∀ w ∈ Metric.ball z (ε / 2), ‖w‖ < A := by
    intro w hw
    rw [Metric.mem_ball, dist_eq_norm] at hw
    calc ‖w‖ = ‖z + (w - z)‖ := by ring_nf
      _ ≤ ‖z‖ + ‖w - z‖ := norm_add_le _ _
      _ < A := by rw [hA]; linarith
  have hlow : ∀ w ∈ Metric.ball z (ε / 2), ∀ n : ℕ, ∀ s : ℂ, (s = 1 ∨ s = -1) →
      c * ((n : ℝ) + 1) ≤ ‖w - s * ((n : ℂ) + 1)‖ := by
    intro w hw n s hs
    have hsn : ‖s * ((n : ℂ) + 1)‖ = (n : ℝ) + 1 := by
      rcases hs with rfl | rfl
      · simp only [one_mul]; exact_mod_cast Complex.norm_natCast (n + 1)
      · rw [neg_one_mul, norm_neg]; exact_mod_cast Complex.norm_natCast (n + 1)
    by_cases hbig : 2 * A ≤ (n : ℝ) + 1
    · have h1 : (n : ℝ) + 1 - ‖w‖ ≤ ‖w - s * ((n : ℂ) + 1)‖ := by
        have := norm_sub_norm_le (s * ((n : ℂ) + 1)) w
        rw [hsn, norm_sub_rev] at this; exact this
      have := hwA w hw
      have : c ≤ 1 / 2 := min_le_left _ _
      nlinarith
    · push_neg at hbig
      have hm : ∃ m : ℤ, s * ((n : ℂ) + 1) = m := by
        rcases hs with rfl | rfl
        · exact ⟨n + 1, by push_cast; ring⟩
        · exact ⟨-(n + 1), by push_cast; ring⟩
      obtain ⟨m, hm⟩ := hm
      have h1 := hfar w hw m
      rw [← hm] at h1
      have h2 : c ≤ ε / (4 * A) := min_le_right _ _
      have h3 : c * ((n : ℝ) + 1) ≤ ε / (4 * A) * (2 * A) := by
        apply mul_le_mul h2 hbig.le (by positivity) (by positivity)
      have h4 : ε / (4 * A) * (2 * A) = ε / 2 := by field_simp; ring
      linarith
  -- the uniform bound on the terms
  have hbound : ∀ (n : ℕ) (w : ℂ), w ∈ Metric.ball z (ε / 2) →
      ‖cotTerm w n‖ ≤ 2 * A / c ^ 2 * (1 / ((n : ℝ) + 1) ^ 2) := by
    intro n w hw
    have hwc : w ∈ Complex.integerComplement := hball (Metric.ball_subset_ball (by linarith) hw)
    rw [cotTerm_identity hwc n]
    have hp := hlow w hw n 1 (Or.inl rfl)
    have hm := hlow w hw n (-1) (Or.inr rfl)
    simp only [one_mul, neg_one_mul, sub_neg_eq_add] at hp hm
    have hpos : 0 < c * ((n : ℝ) + 1) := by positivity
    rw [norm_mul, norm_mul, norm_div, norm_one, norm_mul]
    have h2 : ‖(2 : ℂ)‖ = 2 := by simp
    rw [h2]
    have hw' := (hwA w hw).le
    have hprod : (c * ((n : ℝ) + 1)) * (c * ((n : ℝ) + 1)) ≤
        ‖w + ((n : ℂ) + 1)‖ * ‖w - ((n : ℂ) + 1)‖ := mul_le_mul hm hp hpos.le (norm_nonneg _)
    calc 2 * ‖w‖ * (1 / (‖w + ((n : ℂ) + 1)‖ * ‖w - ((n : ℂ) + 1)‖))
        ≤ 2 * A * (1 / ((c * ((n : ℝ) + 1)) * (c * ((n : ℝ) + 1)))) := by
          apply mul_le_mul (by linarith) _ (by positivity) (by positivity)
          apply one_div_le_one_div_of_le (by positivity) hprod
      _ = 2 * A / c ^ 2 * (1 / ((n : ℝ) + 1) ^ 2) := by field_simp
  have hu : Summable fun n : ℕ => 2 * A / c ^ 2 * (1 / ((n : ℝ) + 1) ^ 2) := by
    apply Summable.mul_left
    have := (summable_nat_add_iff 1).2 (Real.summable_one_div_nat_pow.2 one_lt_two)
    simpa using this
  have hdiff : ∀ n : ℕ, DifferentiableOn ℂ (fun w => cotTerm w n) (Metric.ball z (ε / 2)) := by
    intro n w hw
    have hwc : w ∈ Complex.integerComplement := hball (Metric.ball_subset_ball (by linarith) hw)
    have h1 : w - ((n : ℂ) + 1) ≠ 0 := by
      have := hlow w hw n 1 (Or.inl rfl); simp only [one_mul] at this
      intro h0; rw [h0, norm_zero] at this; have : 0 < c * ((n : ℝ) + 1) := by positivity
      linarith
    have h2 : w + ((n : ℂ) + 1) ≠ 0 := by
      have := hlow w hw n (-1) (Or.inr rfl); simp only [neg_one_mul, sub_neg_eq_add] at this
      intro h0; rw [h0, norm_zero] at this; have : 0 < c * ((n : ℝ) + 1) := by positivity
      linarith
    apply DifferentiableAt.differentiableWithinAt
    simp only [cotTerm]
    fun_prop (disch := assumption)
  have hzb : z ∈ Metric.ball z (ε / 2) := Metric.mem_ball_self (by linarith)
  have hD := hasSum_deriv_of_summable_norm hu hdiff Metric.isOpen_ball hbound hzb
  -- derivative of the sum
  have heq : (fun w => ∑' n : ℕ, cotTerm w n) =ᶠ[𝓝 z]
      (fun w : ℂ => π * Complex.cot (π * w) - 1 / w) := by
    filter_upwards [hU.mem_nhds hz'] with w hw
    exact (cot_series_rep' hw).symm
  rw [heq.deriv_eq, (ml_hasDerivAt_pi_cot_sub z hz').deriv] at hD
  -- derivative of each term
  have hterm : ∀ n : ℕ, deriv (fun w => cotTerm w n) z =
      -(1 / (z - (((n : ℤ) + 1 : ℤ) : ℂ)) ^ 2 + 1 / (z - ((-((n : ℤ) + 1) : ℤ) : ℂ)) ^ 2) := by
    intro n
    have h1 : z - ((n : ℂ) + 1) ≠ 0 := fun h0 => hz (n + 1) (by
      push_cast; linear_combination h0)
    have h2 : z + ((n : ℂ) + 1) ≠ 0 := fun h0 => hz (-(n + 1)) (by
      push_cast; linear_combination h0)
    have hd1 := ((hasDerivAt_id z).sub_const ((n : ℂ) + 1)).inv h1
    have hd2 := ((hasDerivAt_id z).add_const ((n : ℂ) + 1)).inv h2
    have key : HasDerivAt (fun w => cotTerm w n)
        (-1 / (z - ((n : ℂ) + 1)) ^ 2 + -1 / (z + ((n : ℂ) + 1)) ^ 2) z := by
      convert hd1.add hd2 using 1
      · funext w; simp [cotTerm]
      · rfl
    rw [key.deriv]
    push_cast
    ring
  simp only [hterm] at hD
  -- assemble the sum over ℤ
  set f : ℤ → ℂ := fun n => 1 / (z - n) ^ 2 with hf
  have hfs : Summable f := by
    have := EisensteinSeries.linear_right_summable z (-1) (k := 2) le_rfl
    refine this.congr fun d => ?_
    simp only [hf, one_div]
    congr 1
    rw [zpow_two, Int.cast_neg, Int.cast_one]
    ring
  have hS1 : Summable fun n : ℕ => f (n + 1) :=
    hfs.comp_injective (fun x y hxy => by simpa using hxy)
  have hS2 : Summable fun n : ℕ => f (-(n + 1)) :=
    hfs.comp_injective (fun x y hxy => by simpa using hxy)
  have hall := hS1.hasSum.of_add_one_of_neg_add_one hS2.hasSum
  have hpair := (hS1.hasSum.add hS2.hasSum).neg
  have huniq := hD.unique hpair
  convert hall using 1
  have hf0 : f 0 = 1 / z ^ 2 := by simp [hf]
  rw [hf0]
  linear_combination -huniq

-- At z = 1/2 the wire pairs n = 1, 2, 3 give 1/(1/4 - n²) = -4/3, -4/15, -4/35.
example : (1 : ℚ) / (1 / 4 - 1 ^ 2) = -4 / 3 := by norm_num
example : (1 : ℚ) / (1 / 4 - 2 ^ 2) = -4 / 15 := by norm_num
example : (1 : ℚ) / (1 / 4 - 3 ^ 2) = -4 / 35 := by norm_num

-- Each pair splits as a telescoping difference: 1/(n² - 1/4) = 1/(n - 1/2) - 1/(n + 1/2).
example : ∀ n ∈ Finset.Icc (1 : ℕ) 20,
    (1 : ℚ) / ((n : ℚ) ^ 2 - 1 / 4) = 1 / ((n : ℚ) - 1 / 2) - 1 / ((n : ℚ) + 1 / 2) := by
  decide +kernel

-- The pairs to n = 1000 telescope to exactly 4000/2001 = 2 - 1/1000.5.
example : ∑ n ∈ Finset.Icc (1 : ℕ) 1000, (1 : ℚ) / ((n : ℚ) ^ 2 - 1 / 4) = 4000 / 2001 := by
  decide +kernel
example : (4000 : ℚ) / 2001 = 2 - 1 / (2001 / 2) := by norm_num

#print axioms mittag_leffler_taylor_corrected_sum
#print axioms pi_cot_pi_eq_one_div_add_series
#print axioms pi_sq_div_sin_sq_eq_series
