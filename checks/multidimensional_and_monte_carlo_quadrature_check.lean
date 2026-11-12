-- Many dimensions: the product midpoint grid on the d-cube misses by at most d·M·h²/24 at a cost of m^d points, while the average of N independent uniform random points has mean-square error σ²/N in every dimension.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory ProbabilityTheory Set

lemma second_diff_bound (g : ℝ → ℝ) (hg : ContDiff ℝ 2 g) (M : ℝ)
    (hM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M) (c t : ℝ) (ht : 0 ≤ t)
    (h1 : 0 ≤ c - t) (h2 : c + t ≤ 1) :
    |g (c + t) + g (c - t) - 2 * g c| ≤ M * t ^ 2 := by
  obtain ⟨hd1, -, hcd⟩ := contDiff_succ_iff_deriv.1 (show ContDiff ℝ (1 + 1) g from hg)
  have hd2 : Differentiable ℝ (deriv g) := hcd.differentiable one_ne_zero
  have hcont : Continuous (deriv g) := hcd.continuous
  have lip : ∀ y ∈ Icc (0 : ℝ) 1, ∀ z ∈ Icc (0 : ℝ) 1, |deriv g y - deriv g z| ≤ M * |y - z| := by
    intro y hy z hz
    have := (convex_Icc (0 : ℝ) 1).norm_image_sub_le_of_norm_deriv_le
      (fun x _ => hd2 x) (fun x hx => by simpa using hM x hx) hz hy
    simpa [Real.norm_eq_abs] using this
  have hftc : ∫ s in (0 : ℝ)..t, (deriv g (c + s) * 1 + deriv g (c - s) * (-1)) =
      (g (c + t) + g (c - t)) - (g (c + 0) + g (c - 0)) := by
    apply intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun s => g (c + s) + g (c - s))
    · intro s _
      exact ((hd1 (c + s)).hasDerivAt.comp s ((hasDerivAt_id s).const_add c)).add
        ((hd1 (c - s)).hasDerivAt.comp s ((hasDerivAt_id s).const_sub c))
    · apply Continuous.intervalIntegrable
      fun_prop
  simp only [add_zero, sub_zero, mul_one, mul_neg_one] at hftc
  rw [show g (c + t) + g (c - t) - 2 * g c = g (c + t) + g (c - t) - (g c + g c) by ring,
    ← hftc]
  have hb : ‖∫ s in (0 : ℝ)..t, (deriv g (c + s) + -deriv g (c - s))‖ ≤
      ∫ s in (0 : ℝ)..t, 2 * M * s := by
    apply intervalIntegral.norm_integral_le_of_norm_le ht
    · refine Filter.Eventually.of_forall (fun s hs => ?_)
      have := lip (c + s) ⟨by linarith [hs.1], by linarith [hs.2]⟩ (c - s)
        ⟨by linarith [hs.2], by linarith [hs.1]⟩
      rw [Real.norm_eq_abs, ← sub_eq_add_neg]
      calc |deriv g (c + s) - deriv g (c - s)| ≤ M * |c + s - (c - s)| := this
        _ = 2 * M * s := by
          rw [show c + s - (c - s) = 2 * s by ring, abs_of_nonneg (by linarith [hs.1])]; ring
    · apply Continuous.intervalIntegrable; fun_prop
  rw [Real.norm_eq_abs] at hb
  refine hb.trans (le_of_eq ?_)
  rw [intervalIntegral.integral_const_mul, integral_id]
  ring

#print axioms second_diff_bound

lemma cell_bound (g : ℝ → ℝ) (hg : ContDiff ℝ 2 g) (M : ℝ)
    (hM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M) (c r : ℝ) (hr : 0 ≤ r)
    (h1 : 0 ≤ c - r) (h2 : c + r ≤ 1) :
    |(∫ x in (c - r)..(c + r), g x) - 2 * r * g c| ≤ M * r ^ 3 / 3 := by
  have hgc : Continuous g := hg.continuous
  have e : (∫ x in (c - r)..(c + r), g x) - 2 * r * g c =
      ∫ t in (0 : ℝ)..r, (g (c + t) + g (c - t) - 2 * g c) := by
    have i1 : IntervalIntegrable (fun t => g (c + t)) volume 0 r :=
      (hgc.comp (continuous_const.add continuous_id)).intervalIntegrable _ _
    have i2 : IntervalIntegrable (fun t => g (c - t)) volume 0 r :=
      (hgc.comp (continuous_const.sub continuous_id)).intervalIntegrable _ _
    rw [intervalIntegral.integral_sub (i1.add i2) intervalIntegrable_const,
      intervalIntegral.integral_add i1 i2, intervalIntegral.integral_comp_add_left,
      intervalIntegral.integral_comp_sub_left, intervalIntegral.integral_const,
      ← intervalIntegral.integral_add_adjacent_intervals (b := c)
        (hgc.intervalIntegrable _ _) (hgc.intervalIntegrable _ _)]
    simp only [add_zero, sub_zero, smul_eq_mul]
    ring
  rw [e]
  have hb : ‖∫ t in (0 : ℝ)..r, (g (c + t) + g (c - t) - 2 * g c)‖ ≤
      ∫ t in (0 : ℝ)..r, M * t ^ 2 := by
    apply intervalIntegral.norm_integral_le_of_norm_le hr
    · refine Filter.Eventually.of_forall (fun s hs => ?_)
      rw [Real.norm_eq_abs]
      exact second_diff_bound g hg M hM c s hs.1.le (by linarith [hs.2]) (by linarith [hs.2])
    · apply Continuous.intervalIntegrable; fun_prop
  rw [Real.norm_eq_abs] at hb
  refine hb.trans (le_of_eq ?_)
  simp
  ring

#print axioms cell_bound

lemma midpoint_1d (g : ℝ → ℝ) (hg : ContDiff ℝ 2 g) (M : ℝ)
    (hM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M) (m : ℕ) (hm : 0 < m) :
    |(∑ j : Fin m, g (((j : ℝ) + 1 / 2) / m)) / m - ∫ t in Icc (0 : ℝ) 1, g t| ≤
      M * (1 / (m : ℝ)) ^ 2 / 24 := by
  have hgc : Continuous g := hg.continuous
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  have hI : ∫ t in Icc (0 : ℝ) 1, g t = ∑ k ∈ Finset.range m,
      ∫ x in ((k : ℝ) / m)..(((k + 1 : ℕ) : ℝ) / m), g x := by
    have := intervalIntegral.sum_integral_adjacent_intervals (μ := volume) (f := g)
      (a := fun k : ℕ => (k : ℝ) / m) (n := m) (fun k _ => hgc.intervalIntegrable _ _)
    rw [this, integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one]
    simp [hm'.ne']
  rw [hI, Fin.sum_univ_eq_sum_range (fun j : ℕ => g (((j : ℝ) + 1 / 2) / m)) m, Finset.sum_div,
    ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
  have hterm : ∀ k ∈ Finset.range m, |g (((k : ℝ) + 1 / 2) / m) / m -
      ∫ x in ((k : ℝ) / m)..(((k + 1 : ℕ) : ℝ) / m), g x| ≤ M * (1 / (2 * m)) ^ 3 / 3 := by
    intro k hk
    have hk' : (k : ℝ) + 1 ≤ m := by exact_mod_cast Finset.mem_range.1 hk
    set c := ((k : ℝ) + 1 / 2) / m
    set r := 1 / (2 * (m : ℝ))
    have ea : (k : ℝ) / m = c - r := by simp only [c, r]; field_simp; ring
    have eb : ((k + 1 : ℕ) : ℝ) / m = c + r := by simp only [c, r]; push_cast; field_simp; ring
    have ec : g c / m = 2 * r * g c := by simp only [r]; field_simp
    rw [ea, eb, ec, abs_sub_comm]
    apply cell_bound g hg M hM c r (by positivity)
    · rw [← ea]; positivity
    · rw [← eb, div_le_one hm']; push_cast; exact hk'
  refine (Finset.sum_le_sum hterm).trans (le_of_eq ?_)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
  field_simp
  ring

#print axioms midpoint_1d

lemma measurable_finCons (n : ℕ) :
    Measurable (fun p : ℝ × (Fin n → ℝ) => (Fin.cons p.1 p.2 : Fin (n + 1) → ℝ)) := by
  refine measurable_pi_iff.2 (fun i => ?_)
  refine Fin.cases ?_ (fun j => ?_) i
  · simp only [Fin.cons_zero]; exact measurable_fst
  · simp only [Fin.cons_succ]; exact (measurable_pi_apply j).comp measurable_snd

#print axioms measurable_finCons

lemma grid_telescope (m : ℕ) (hm : 0 < m) (node : Fin m → ℝ) (ν : Measure ℝ)
    [IsProbabilityMeasure ν] (ε : ℝ) :
    ∀ (d : ℕ) (F : (Fin d → ℝ) → ℝ), Measurable F → (∃ C, ∀ x, |F x| ≤ C) →
      (∀ x k, |(∑ j : Fin m, F (Function.update x k (node j))) / m -
        ∫ t, F (Function.update x k t) ∂ν| ≤ ε) →
      |(∑ j : Fin d → Fin m, F (fun i => node (j i))) / (m : ℝ) ^ d -
        ∫ x, F x ∂(Measure.pi fun _ : Fin d => ν)| ≤ d * ε := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  intro d
  induction d with
  | zero =>
    intro F _ _ _
    simp only [Fintype.sum_unique, pow_zero, div_one, integral_unique, CharP.cast_eq_zero,
      zero_mul, probReal_univ, one_smul]
    simp only [abs_nonpos_iff, sub_eq_zero]
    exact congrArg F (Subsingleton.elim _ _)
  | succ n ih =>
    intro F hF ⟨C, hC⟩ hloc
    set ν' := Measure.pi fun _ : Fin n => ν with hν'
    have hcm := measurable_finCons n
    -- the integral over the cube splits off the first coordinate
    have hmp := (measurePreserving_piFinSuccAbove (fun _ : Fin (n + 1) => ν) 0).symm
    have hsplit : ∫ x, F x ∂(Measure.pi fun _ : Fin (n + 1) => ν) =
        ∫ p, F (Fin.cons p.1 p.2) ∂(ν.prod ν') := by
      rw [← hmp.integral_comp' F]
      congr 1
      funext p
      simp [MeasurableEquiv.piFinSuccAbove_symm_apply]
    have hGm : Measurable (fun p : ℝ × (Fin n → ℝ) => F (Fin.cons p.1 p.2)) := hF.comp hcm
    have hGint : Integrable (fun p : ℝ × (Fin n → ℝ) => F (Fin.cons p.1 p.2)) (ν.prod ν') :=
      Integrable.of_bound hGm.aestronglyMeasurable C (Filter.Eventually.of_forall fun p => hC _)
    rw [hsplit, integral_prod _ hGint]
    -- the grid sum splits off the first coordinate
    have hsum : (∑ j : Fin (n + 1) → Fin m, F (fun i => node (j i))) =
        ∑ j' : Fin n → Fin m, ∑ j0 : Fin m,
          F (Fin.cons (node j0) (fun i => node (j' i))) := by
      rw [← (Fin.consEquiv fun _ => Fin m).sum_comp, Fintype.sum_prod_type, Finset.sum_comm]
      refine Finset.sum_congr rfl (fun j' _ => Finset.sum_congr rfl (fun j0 _ => ?_))
      congr 1
      funext i
      refine Fin.cases ?_ (fun k => ?_) i <;> simp
    rw [hsum]
    have hsec : ∀ y : Fin n → ℝ, Integrable (fun a => F (Fin.cons a y)) ν := fun y =>
      Integrable.of_bound (hGm.comp (measurable_id.prodMk measurable_const)).aestronglyMeasurable
        C (Filter.Eventually.of_forall fun a => hC _)
    -- first term: the last-coordinate rule against the integral, averaged over the grid
    have hA : ∀ j' : Fin n → Fin m,
        |(∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) / m -
          ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν| ≤ ε := by
      intro j'
      have := hloc (Fin.cons 0 (fun i => node (j' i))) 0
      simpa only [Fin.update_cons_zero] using this
    -- second term: the induction hypothesis on each slice
    have hB : ∀ a : ℝ,
        |(∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n -
          ∫ y, F (Fin.cons a y) ∂ν'| ≤ n * ε := by
      intro a
      apply ih (fun y => F (Fin.cons a y)) (hGm.comp (measurable_const.prodMk measurable_id))
        ⟨C, fun y => hC _⟩
      intro y k
      simpa only [Fin.cons_update] using hloc (Fin.cons a y) k.succ
    have hI1 : Integrable (fun a => (∑ j' : Fin n → Fin m,
        F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n) ν :=
      (integrable_finsetSum _ (fun j' _ => hsec _)).div_const _
    have hI2 : Integrable (fun a => ∫ y, F (Fin.cons a y) ∂ν') ν := hGint.integral_prod_left
    have hH : ∫ a, (∑ j' : Fin n → Fin m,
        F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n ∂ν =
        (∑ j' : Fin n → Fin m, ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν) / (m : ℝ) ^ n := by
      rw [integral_div, integral_finsetSum _ (fun j' _ => hsec _)]
    have hdecomp :
        (∑ j' : Fin n → Fin m, ∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) /
            (m : ℝ) ^ (n + 1) - ∫ a, ∫ y, F (Fin.cons a y) ∂ν' ∂ν =
          (∑ j' : Fin n → Fin m,
            ((∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) / m -
              ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν)) / (m : ℝ) ^ n +
          ∫ a, ((∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) / (m : ℝ) ^ n -
            ∫ y, F (Fin.cons a y) ∂ν') ∂ν := by
      rw [integral_sub hI1 hI2, hH, Finset.sum_sub_distrib, ← Finset.sum_div, pow_succ]
      field_simp
      ring
    rw [hdecomp]
    have hcard : (Finset.univ : Finset (Fin n → Fin m)).card = m ^ n := by simp
    have h1 : |(∑ j' : Fin n → Fin m,
            ((∑ j0 : Fin m, F (Fin.cons (node j0) (fun i => node (j' i)))) / m -
              ∫ a, F (Fin.cons a (fun i => node (j' i))) ∂ν)) / (m : ℝ) ^ n| ≤ ε := by
      rw [abs_div, abs_of_pos (pow_pos hm' n), div_le_iff₀ (pow_pos hm' n)]
      refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
      refine (Finset.sum_le_sum (fun j' _ => hA j')).trans (le_of_eq ?_)
      rw [Finset.sum_const, hcard, nsmul_eq_mul]
      push_cast
      ring
    have h2 : |∫ a, ((∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) /
        (m : ℝ) ^ n - ∫ y, F (Fin.cons a y) ∂ν') ∂ν| ≤ n * ε := by
      have := norm_integral_le_of_norm_le_const (μ := ν) (C := n * ε)
        (f := fun a => (∑ j' : Fin n → Fin m, F (Fin.cons a (fun i => node (j' i)))) /
          (m : ℝ) ^ n - ∫ y, F (Fin.cons a y) ∂ν')
        (Filter.Eventually.of_forall fun a => by rw [Real.norm_eq_abs]; exact hB a)
      rw [Real.norm_eq_abs, probReal_univ, mul_one] at this
      exact this
    push_cast
    calc _ ≤ _ := abs_add_le _ _
      _ ≤ ε + n * ε := add_le_add h1 h2
      _ = (n + 1) * ε := by ring

#print axioms grid_telescope

lemma unitCube_isProb (d : ℕ) :
    IsProbabilityMeasure (volume.restrict (Icc (0 : Fin d → ℝ) 1)) :=
  ⟨by simp [Real.volume_Icc_pi]⟩

#print axioms unitCube_isProb

lemma aemeasurable_of_map_eq_unitCube {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (d : ℕ) (V : Ω → (Fin d → ℝ))
    (h : P.map V = volume.restrict (Icc (0 : Fin d → ℝ) 1)) : AEMeasurable V P := by
  by_contra hV
  rcases Nat.eq_zero_or_pos d with hd | hd
  · subst hd
    exact hV (measurable_pi_iff.2 (fun i => i.elim0)).aemeasurable
  · obtain ⟨c, hc⟩ : ∃ c, P.map V = Measure.dirac c :=
      ⟨_, Measure.map_of_not_aemeasurable_of_ne_zero hV (IsProbabilityMeasure.ne_zero P)⟩
    rw [hc] at h
    have h2 := congrArg (fun ν : Measure (Fin d → ℝ) => ν {c}) h
    have h0 : volume ({c} : Set (Fin d → ℝ)) = 0 := by
      rw [← Icc_self, Real.volume_Icc_pi]
      exact Finset.prod_eq_zero (Finset.mem_univ ⟨0, hd⟩) (by simp)
    have h3 : (volume.restrict (Icc (0 : Fin d → ℝ) 1)) {c} = 0 :=
      le_antisymm ((Measure.restrict_apply_le _ _).trans h0.le) zero_le
    simp only [Measure.dirac_apply_of_mem (mem_singleton c)] at h2
    rw [h3] at h2
    exact one_ne_zero h2

#print axioms aemeasurable_of_map_eq_unitCube

/-- The product midpoint rule with `m` points per axis on the unit cube in `d` dimensions:
the plain average of `f` over all `m ^ d` points whose coordinates are midpoints
`(j + 1/2) / m`, `j = 0, …, m - 1` (the card's `(j - 1/2)/m`, `j = 1, …, m`). -/
noncomputable def productMidpoint (d m : ℕ) (f : (Fin d → ℝ) → ℝ) : ℝ :=
  (∑ j : Fin d → Fin m, f (fun i => ((j i : ℝ) + 1 / 2) / m)) / (m : ℝ) ^ d

/-- The product grid's error is at most `d` one-dimensional errors: if `f` has a second
derivative along each axis bounded by `M` on the unit cube, the product midpoint rule with
`m` points per axis (spacing `h = 1/m`) misses the integral over the cube by at most
`d · M · h² / 24`. -/
theorem product_midpoint_error_bound (d m : ℕ) (hm : 0 < m) (f : (Fin d → ℝ) → ℝ) (M : ℝ)
    (hf : ContDiff ℝ 2 f)
    (hM : ∀ x ∈ Icc (0 : Fin d → ℝ) 1, ∀ k : Fin d,
      |deriv (deriv fun t => f (Function.update x k t)) (x k)| ≤ M) :
    |productMidpoint d m f - ∫ u in Icc (0 : Fin d → ℝ) 1, f u| ≤
      d * M * (1 / (m : ℝ)) ^ 2 / 24 := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  -- clamp each coordinate into [0, 1]; this changes nothing on the cube
  set clamp : (Fin d → ℝ) → (Fin d → ℝ) := fun x i => max 0 (min (x i) 1) with hclamp
  have hcl_mem : ∀ x, clamp x ∈ Icc (0 : Fin d → ℝ) 1 := fun x =>
    ⟨fun i => le_max_left _ _, fun i => max_le zero_le_one (min_le_right _ _)⟩
  have hcl1 : ∀ t ∈ Icc (0 : ℝ) 1, max 0 (min t 1) = t := fun t ht => by
    rw [min_eq_left ht.2, max_eq_right ht.1]
  have hcl_id : ∀ x ∈ Icc (0 : Fin d → ℝ) 1, clamp x = x := fun x hx => funext fun i =>
    hcl1 (x i) ⟨hx.1 i, hx.2 i⟩
  have hcl_cont : Continuous clamp :=
    continuous_pi fun i => continuous_const.max ((continuous_apply i).min continuous_const)
  have hcl_upd : ∀ x k t, t ∈ Icc (0 : ℝ) 1 →
      clamp (Function.update x k t) = Function.update (clamp x) k t := by
    intro x k t ht
    funext i
    by_cases h : i = k
    · subst h; simp only [hclamp, Function.update_self]; exact hcl1 t ht
    · simp [hclamp, Function.update_of_ne h]
  set F : (Fin d → ℝ) → ℝ := fun x => f (clamp x) with hF
  have hFc : Continuous F := hf.continuous.comp hcl_cont
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := (0 : Fin d → ℝ)) (b := 1)).exists_bound_of_continuousOn
    hf.continuous.continuousOn
  have hFb : ∀ x, |F x| ≤ C := fun x => by
    simpa [Real.norm_eq_abs] using hC (clamp x) (hcl_mem x)
  set node : Fin m → ℝ := fun j => ((j : ℝ) + 1 / 2) / m with hnode_def
  have hnode : ∀ j, node j ∈ Icc (0 : ℝ) 1 := fun j => by
    have hj : (j : ℝ) + 1 ≤ m := by exact_mod_cast j.isLt
    refine ⟨by positivity, ?_⟩
    rw [hnode_def, div_le_one hm']
    linarith
  have : IsProbabilityMeasure (volume.restrict (Icc (0 : ℝ) 1)) := ⟨by simp⟩
  have hloc : ∀ x k, |(∑ j : Fin m, F (Function.update x k (node j))) / m -
      ∫ t, F (Function.update x k t) ∂(volume.restrict (Icc (0 : ℝ) 1))| ≤
        M * (1 / (m : ℝ)) ^ 2 / 24 := by
    intro x k
    set x' := clamp x
    set g : ℝ → ℝ := fun t => f (Function.update x' k t) with hg_def
    have hg : ContDiff ℝ 2 g := hf.comp (contDiff_update 2 x' k)
    have hgM : ∀ t ∈ Icc (0 : ℝ) 1, |deriv (deriv g) t| ≤ M := by
      intro t ht
      have hmem : Function.update x' k t ∈ Icc (0 : Fin d → ℝ) 1 := by
        refine ⟨fun i => ?_, fun i => ?_⟩ <;> by_cases h : i = k
        · subst h; simpa using ht.1
        · simpa [Function.update_of_ne h] using (hcl_mem x).1 i
        · subst h; simpa using ht.2
        · simpa [Function.update_of_ne h] using (hcl_mem x).2 i
      simpa [hg_def] using hM _ hmem k
    have e1 : ∀ j, F (Function.update x k (node j)) = g (node j) := fun j => by
      simp only [hF, hg_def]; rw [hcl_upd x k _ (hnode j)]
    have e2 : ∫ t, F (Function.update x k t) ∂(volume.restrict (Icc (0 : ℝ) 1)) =
        ∫ t in Icc (0 : ℝ) 1, g t :=
      setIntegral_congr_fun measurableSet_Icc (fun t ht => by
        simp only [hF, hg_def]; rw [hcl_upd x k t ht])
    rw [e2]
    simp only [e1]
    exact midpoint_1d g hg M hgM m hm
  have hT := grid_telescope m hm node (volume.restrict (Icc (0 : ℝ) 1))
    (M * (1 / (m : ℝ)) ^ 2 / 24) d F hFc.measurable ⟨C, hFb⟩ hloc
  have eS : productMidpoint d m f =
      (∑ j : Fin d → Fin m, F (fun i => node (j i))) / (m : ℝ) ^ d := by
    unfold productMidpoint
    congr 1
    refine Finset.sum_congr rfl (fun j _ => ?_)
    simp only [hF]
    rw [hcl_id _ ⟨fun i => (hnode (j i)).1, fun i => (hnode (j i)).2⟩]
  have hvol : volume.restrict (Icc (0 : Fin d → ℝ) 1) =
      Measure.pi fun _ : Fin d => volume.restrict (Icc (0 : ℝ) 1) := by
    rw [← Set.pi_univ_Icc, volume_pi, Measure.restrict_pi_pi]
    rfl
  have eI : ∫ u in Icc (0 : Fin d → ℝ) 1, f u =
      ∫ x, F x ∂(Measure.pi fun _ : Fin d => volume.restrict (Icc (0 : ℝ) 1)) := by
    rw [setIntegral_congr_fun measurableSet_Icc (g := F) (fun u hu => by
      simp only [hF]; rw [hcl_id u hu]), hvol]
  rw [eS, eI]
  refine hT.trans (le_of_eq ?_)
  ring

/-- The Monte Carlo error is σ/√N whatever the dimension: if `U₁, …, U_N` are independent
random points, each spread evenly over the unit cube in `d` dimensions, and the payoff `f`
has finite spread σ (finite mean square on the cube), then the average of `f(U_i)` has
mean-square miss from the true integral `I` equal to `σ² / N`, where `σ²` is the mean of
`(f - I)²` over the cube. No `d` appears in the answer. -/
theorem monte_carlo_mean_square_error {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (d N : ℕ) (hN : 0 < N) (f : (Fin d → ℝ) → ℝ)
    (U : Fin N → Ω → (Fin d → ℝ)) (hind : iIndepFun U P)
    (hunif : ∀ i, P.map (U i) = volume.restrict (Icc (0 : Fin d → ℝ) 1))
    (hσ : MemLp f 2 (volume.restrict (Icc (0 : Fin d → ℝ) 1))) :
    ∫ ω, ((∑ i, f (U i ω)) / N - ∫ u in Icc (0 : Fin d → ℝ) 1, f u) ^ 2 ∂P =
      (∫ u in Icc (0 : Fin d → ℝ) 1,
        (f u - ∫ v in Icc (0 : Fin d → ℝ) 1, f v) ^ 2) / N := by
  have hUm : ∀ i, AEMeasurable (U i) P := fun i =>
    aemeasurable_of_map_eq_unitCube d (U i) (hunif i)
  set μ := volume.restrict (Icc (0 : Fin d → ℝ) 1) with hμ
  have : IsProbabilityMeasure μ := unitCube_isProb d
  set I := ∫ u, f u ∂μ with hI
  have hfs := hσ.aestronglyMeasurable
  have hfm : ∀ i, AEMeasurable f (P.map (U i)) := fun i => by
    rw [hunif i]; exact hfs.aemeasurable
  set X : Fin N → Ω → ℝ := fun i ω => f (U i ω) with hX
  have hXind : iIndepFun X P := hind.comp₀ (fun _ => f) hUm hfm
  have hXL2 : ∀ i, MemLp (X i) 2 P := fun i =>
    (memLp_map_measure_iff (by rw [hunif i]; exact hfs) (hUm i)).1 (by rw [hunif i]; exact hσ)
  have hXint : ∀ i, ∫ ω, X i ω ∂P = I := fun i => by
    rw [hI, ← hunif i, integral_map (hUm i) (by rw [hunif i]; exact hfs)]
  have hXvar : ∀ i, variance (X i) P = ∫ u, (f u - I) ^ 2 ∂μ := fun i => by
    have := variance_map (hfm i) (hUm i)
    rw [hunif i] at this
    rw [show X i = f ∘ U i from rfl, ← this, variance_eq_integral hfs.aemeasurable]
  have hsum := IndepFun.variance_sum (s := Finset.univ) (fun i _ => hXL2 i)
    (fun i _ j _ hij => hXind.indepFun hij)
  have hSint : ∫ ω, (∑ i, X i) ω ∂P = N * I := by
    simp only [Finset.sum_apply]
    rw [integral_finsetSum _ (fun i _ => (hXL2 i).integrable one_le_two)]
    simp [hXint]
  have hSm : AEMeasurable (∑ i, X i) P :=
    Finset.aemeasurable_sum _ (fun i _ => (hXL2 i).aestronglyMeasurable.aemeasurable)
  rw [variance_eq_integral hSm, hSint] at hsum
  simp only [hXvar, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
    Finset.sum_apply] at hsum
  have hN' : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
  have key : ∀ ω, ((∑ i, f (U i ω)) / N - I) ^ 2 = (∑ i, X i ω - N * I) ^ 2 / (N : ℝ) ^ 2 := by
    intro ω
    simp only [hX]
    field_simp
  simp_rw [key]
  rw [integral_div, hsum]
  field_simp

/-- The grid's cost and rate in point count: a product grid with `m` points on each of `d`
axes has `N = m ^ d` points, and its spacing squared `h² = (1/m)²` equals `N ^ (-2/d)`,
so the error bound `d · M · h² / 24` falls only like `N ^ (-2/d)`. -/
theorem product_grid_cost_and_rate (d m : ℕ) (hd : 0 < d) (hm : 0 < m) :
    Fintype.card (Fin d → Fin m) = m ^ d ∧
      (1 / (m : ℝ)) ^ 2 = ((m : ℝ) ^ d) ^ (-(2 : ℝ) / d) := by
  refine ⟨by simp, ?_⟩
  have hm' : (0 : ℝ) ≤ m := Nat.cast_nonneg m
  have hd' : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
  rw [← Real.rpow_natCast (m : ℝ) d, ← Real.rpow_mul hm', mul_div_cancel₀ _ hd',
    Real.rpow_neg hm', one_div, inv_pow]
  norm_num

-- The card's grid sizes: 10 per axis in 5, 10 and 20 dimensions; 2, 3 and 4 per axis in 10.
example : Fintype.card (Fin 5 → Fin 10) = 100000 := by simp
example : (10 : ℕ) ^ 10 = 10000000000 := by norm_num
example : (10 : ℕ) ^ 20 = 100000000000000000000 := by norm_num
example : (2 : ℕ) ^ 10 = 1024 := by norm_num
example : (3 : ℕ) ^ 10 = 59049 := by norm_num
example : (4 : ℕ) ^ 10 = 1048576 := by norm_num

-- The hand computation of the basket's value: 2.5^6 - 5 × 1.5^6 + 10 × 0.5^6 = 187.34375,
-- then divided by 6! = 720 and times 8 gives I = 1199/576 (about 2.081597).
example : (5 / 2 : ℚ) ^ 6 - 5 * (3 / 2) ^ 6 + 10 * (1 / 2) ^ 6 = 5995 / 32 := by norm_num
example : (Nat.factorial 6 : ℚ) = 720 := by decide
example : 8 * (5995 / 32 : ℚ) / 720 = 1199 / 576 := by norm_num
-- The average squared payoff 64 × 5/24 = 40/3, and the variance σ² = 40/3 - I².
example : (64 : ℚ) * (5 / 24) = 40 / 3 := by norm_num
example : (40 / 3 : ℚ) - (1199 / 576) ^ 2 = 2986079 / 331776 := by norm_num
-- The reused-draw mistake aims at a one-dimensional triangle: 100 × 0.2 × 0.5 / 2 = 5.
example : (100 : ℚ) * (1 / 5) * (1 / 2) / 2 = 5 := by norm_num

#print axioms product_midpoint_error_bound
#print axioms monte_carlo_mean_square_error
#print axioms product_grid_cost_and_rate
