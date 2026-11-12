-- Exact equations: on an open rectangle where M and N have continuous first partials, M dx + N dy is the change of one hidden function F exactly when M's rate in y equals N's rate in x, such an F forces that test, and the solutions are the level curves of F.
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.FDeriv.Partial
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set

/-- Fundamental theorem of calculus on an open interval: the running integral of a function
continuous on (u, v) has that function as its derivative at every point of (u, v). -/
theorem exact_ftc_Ioo {u v x₀ x₁ : ℝ} {g : ℝ → ℝ} (hg : ContinuousOn g (Ioo u v))
    (h₀ : x₀ ∈ Ioo u v) (h₁ : x₁ ∈ Ioo u v) :
    HasDerivAt (fun x => ∫ s in x₀..x, g s) (g x₁) x₁ :=
  intervalIntegral.integral_hasDerivAt_right
    ((hg.mono (ordConnected_Ioo.uIcc_subset h₀ h₁)).intervalIntegrable)
    (hg.stronglyMeasurableAtFilter isOpen_Ioo x₁ h₁)
    (hg.continuousAt (isOpen_Ioo.mem_nhds h₁))

#print axioms exact_ftc_Ioo

/-- A function continuous on an open rectangle is continuous along each vertical slice. -/
theorem exact_slice_snd {a b c d x : ℝ} {G : ℝ × ℝ → ℝ}
    (hG : ContinuousOn G (Ioo a b ×ˢ Ioo c d)) (hx : x ∈ Ioo a b) :
    ContinuousOn (fun t => G (x, t)) (Ioo c d) :=
  hG.comp (continuousOn_const.prodMk continuousOn_id) (fun _ ht => ⟨hx, ht⟩)

#print axioms exact_slice_snd

/-- A function continuous on an open rectangle is continuous along each horizontal slice. -/
theorem exact_slice_fst {a b c d t : ℝ} {G : ℝ × ℝ → ℝ}
    (hG : ContinuousOn G (Ioo a b ×ˢ Ioo c d)) (ht : t ∈ Ioo c d) :
    ContinuousOn (fun s => G (s, t)) (Ioo a b) :=
  hG.comp (continuousOn_id.prodMk continuousOn_const) (fun _ hs => ⟨hs, ht⟩)

#print axioms exact_slice_fst

/-- The x-slope of a function with continuous first partials on an open rectangle, read off its
full derivative. -/
theorem exact_partial_fst {a b c d x t : ℝ} {N : ℝ × ℝ → ℝ}
    (hN : ContDiffOn ℝ 1 N (Ioo a b ×ˢ Ioo c d)) (hxt : (x, t) ∈ Ioo a b ×ˢ Ioo c d) :
    HasDerivAt (fun s => N (s, t)) (fderiv ℝ N (x, t) (1, 0)) x := by
  have hd : DifferentiableAt ℝ N (x, t) :=
    (hN.differentiableOn one_ne_zero (x, t) hxt).differentiableAt
      ((isOpen_Ioo.prod isOpen_Ioo).mem_nhds hxt)
  have := hd.hasFDerivAt.comp_hasDerivAt x
    (HasDerivAt.prodMk (hasDerivAt_id x) (hasDerivAt_const x t))
  simp at this
  exact this

#print axioms exact_partial_fst

/-- Differentiating under the integral sign: for N with continuous first partials on an open
rectangle, the x-derivative of ∫ N(x, t) dt over [y₀, y₁] is the integral of ∂N/∂x. -/
theorem exact_deriv_under_integral {a b c d x₁ y₀ y₁ : ℝ} {N : ℝ × ℝ → ℝ}
    (hN : ContDiffOn ℝ 1 N (Ioo a b ×ˢ Ioo c d)) (hx₁ : x₁ ∈ Ioo a b)
    (hy₀ : y₀ ∈ Ioo c d) (hy₁ : y₁ ∈ Ioo c d) :
    HasDerivAt (fun x => ∫ t in y₀..y₁, N (x, t))
      (∫ t in y₀..y₁, fderiv ℝ N (x₁, t) (1, 0)) x₁ := by
  set R := Ioo a b ×ˢ Ioo c d with hR
  have hRo : IsOpen R := isOpen_Ioo.prod isOpen_Ioo
  have hNc : ContinuousOn N R := hN.continuousOn
  have hN'c : ContinuousOn (fun q => fderiv ℝ N q (1, 0)) R :=
    (hN.continuousOn_fderiv_of_isOpen hRo le_rfl).clm_apply continuousOn_const
  have hpart : ∀ x t, (x, t) ∈ R →
      HasDerivAt (fun s => N (s, t)) (fderiv ℝ N (x, t) (1, 0)) x := by
    intro x t hxt
    have hd : DifferentiableAt ℝ N (x, t) :=
      (hN.differentiableOn one_ne_zero (x, t) hxt).differentiableAt (hRo.mem_nhds hxt)
    have := hd.hasFDerivAt.comp_hasDerivAt x
      (HasDerivAt.prodMk (hasDerivAt_id x) (hasDerivAt_const x t))
    simp at this
    exact this
  have hI : uIcc y₀ y₁ ⊆ Ioo c d := ordConnected_Ioo.uIcc_subset hy₀ hy₁
  set δ := min (x₁ - a) (b - x₁) / 2 with hδ
  have hδpos : 0 < δ := by
    have := hx₁.1; have := hx₁.2
    exact half_pos (lt_min (by linarith) (by linarith))
  have hδa : δ < x₁ - a := by
    have := min_le_left (x₁ - a) (b - x₁); have := hx₁.1; rw [hδ]; linarith
  have hδb : δ < b - x₁ := by
    have := min_le_right (x₁ - a) (b - x₁); have := hx₁.2; rw [hδ]; linarith
  have hJ : Icc (x₁ - δ) (x₁ + δ) ⊆ Ioo a b := fun x hx =>
    ⟨by linarith [hx.1], by linarith [hx.2]⟩
  have hK : Icc (x₁ - δ) (x₁ + δ) ×ˢ uIcc y₀ y₁ ⊆ R := prod_mono hJ hI
  obtain ⟨C, hC⟩ := (isCompact_Icc.prod isCompact_uIcc).exists_bound_of_continuousOn
    (hN'c.mono hK)
  have hs : Ioo (x₁ - δ) (x₁ + δ) ∈ nhds x₁ := Ioo_mem_nhds (by linarith) (by linarith)
  have hIoc : uIoc y₀ y₁ ⊆ Ioo c d := uIoc_subset_uIcc.trans hI
  have key := intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
    (μ := MeasureTheory.volume) (a := y₀) (b := y₁)
    (F := fun x t => N (x, t)) (F' := fun x t => fderiv ℝ N (x, t) (1, 0))
    (bound := fun _ => C) hs
    (by
      filter_upwards [isOpen_Ioo.mem_nhds hx₁] with x hx
      exact ((exact_slice_snd hNc hx).mono hIoc).aestronglyMeasurable measurableSet_uIoc)
    ((exact_slice_snd hNc hx₁).mono hI).intervalIntegrable
    (((exact_slice_snd hN'c hx₁).mono hIoc).aestronglyMeasurable measurableSet_uIoc)
    (Filter.Eventually.of_forall fun t ht x hx =>
      hC (x, t) ⟨Ioo_subset_Icc_self hx, uIoc_subset_uIcc ht⟩)
    intervalIntegrable_const
    (Filter.Eventually.of_forall fun t ht x hx =>
      hpart x t ⟨hJ (Ioo_subset_Icc_self hx), hIoc ht⟩)
  exact key.2

#print axioms exact_deriv_under_integral

/-- The exactness test is sufficient: let M and N have continuous first partials on an open
rectangle (a, b) × (c, d), and suppose M's rate in y equals N's rate in x at every point there,
∂M/∂y = ∂N/∂x. Then there is one hidden function F whose change is M dx + N dy on the whole
rectangle: F is differentiable there with ∂F/∂x = M and ∂F/∂y = N. -/
theorem exact_of_mixed_partials_eq {a b c d : ℝ} {M N : ℝ × ℝ → ℝ}
    (hM : ContDiffOn ℝ 1 M (Ioo a b ×ˢ Ioo c d))
    (hN : ContDiffOn ℝ 1 N (Ioo a b ×ˢ Ioo c d))
    (htest : ∀ p ∈ Ioo a b ×ˢ Ioo c d,
      deriv (fun t => M (p.1, t)) p.2 = deriv (fun s => N (s, p.2)) p.1) :
    ∃ F : ℝ × ℝ → ℝ, ∀ p ∈ Ioo a b ×ˢ Ioo c d,
      HasFDerivAt F (M p • ContinuousLinearMap.fst ℝ ℝ ℝ + N p • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
  set R := Ioo a b ×ˢ Ioo c d with hR
  rcases R.eq_empty_or_nonempty with hE | ⟨⟨x₀, y₀⟩, h₀⟩
  · exact ⟨0, fun p hp => by rw [hE] at hp; exact absurd hp (notMem_empty p)⟩
  have hRo : IsOpen R := isOpen_Ioo.prod isOpen_Ioo
  have hMc : ContinuousOn M R := hM.continuousOn
  have hNc : ContinuousOn N R := hN.continuousOn
  let f : ℝ → ℝ → ℝ := fun x y => (∫ s in x₀..x, M (s, y₀)) + ∫ t in y₀..y, N (x, t)
  -- the slope in x is M
  have dx : ∀ x y, (x, y) ∈ R → HasDerivAt (fun x => f x y) (M (x, y)) x := by
    intro x y hxy
    have h1 := exact_ftc_Ioo (exact_slice_fst hMc h₀.2) h₀.1 hxy.1
    have h2 := exact_deriv_under_integral hN hxy.1 h₀.2 hxy.2
    have hI : uIcc y₀ y ⊆ Ioo c d := ordConnected_Ioo.uIcc_subset h₀.2 hxy.2
    have hMs : ContDiffOn ℝ 1 (fun t => M (x, t)) (Ioo c d) :=
      hM.comp (contDiffOn_const.prodMk contDiffOn_id) (fun _ ht => ⟨hxy.1, ht⟩)
    have hint : (∫ t in y₀..y, fderiv ℝ N (x, t) (1, 0)) = M (x, y) - M (x, y₀) := by
      rw [← intervalIntegral.integral_deriv_eq_sub (f := fun t => M (x, t))
        (fun t ht => (hMs.differentiableOn one_ne_zero t (hI ht)).differentiableAt
          (isOpen_Ioo.mem_nhds (hI ht)))
        ((hMs.continuousOn_deriv_of_isOpen isOpen_Ioo le_rfl).mono hI).intervalIntegrable]
      refine intervalIntegral.integral_congr fun t ht => ?_
      have hxt : (x, t) ∈ R := ⟨hxy.1, hI ht⟩
      rw [(exact_partial_fst hN hxt).deriv.symm]
      exact (htest (x, t) hxt).symm
    have := h1.add h2
    rw [hint, add_sub_cancel] at this
    exact this
  -- the slope in y is N
  have dy : ∀ x y, (x, y) ∈ R → HasDerivAt (fun y => f x y) (N (x, y)) y := by
    intro x y hxy
    have := (hasDerivAt_const y (∫ s in x₀..x, M (s, y₀))).add
      (exact_ftc_Ioo (exact_slice_snd hNc hxy.1) h₀.2 hxy.2)
    rw [zero_add] at this
    exact this
  refine ⟨fun q => f q.1 q.2, fun p hp => ?_⟩
  have hev : ∀ᶠ v in nhds p, v ∈ R := hRo.mem_nhds hp
  have key := hasStrictFDerivAt_uncurry_coprod (𝕜 := ℝ) (u := p) (f := f)
    (f₁ := fun x y => M (x, y) • (1 : ℝ →L[ℝ] ℝ)) (f₂ := fun x y => N (x, y) • (1 : ℝ →L[ℝ] ℝ))
    (by
      filter_upwards [hev] with v hv
      have := (dx v.1 v.2 hv).hasFDerivAt
      convert this using 1
      ext
      show (M (v.1, v.2) • (1 : ℝ →L[ℝ] ℝ)) 1 = _
      simp)
    (by
      filter_upwards [hev] with v hv
      have := (dy v.1 v.2 hv).hasFDerivAt
      convert this using 1
      ext
      show (N (v.1, v.2) • (1 : ℝ →L[ℝ] ℝ)) 1 = _
      simp)
    ((hMc.continuousAt (hRo.mem_nhds hp)).smul continuousAt_const)
    ((hNc.continuousAt (hRo.mem_nhds hp)).smul continuousAt_const)
  convert key.hasFDerivAt using 1
  · funext q; rfl
  · refine ContinuousLinearMap.ext fun q => ?_
    show _ = ((M (p.1, p.2) • (1 : ℝ →L[ℝ] ℝ)).coprod (N (p.1, p.2) • (1 : ℝ →L[ℝ] ℝ))) q
    simp

/-- Step 1, the test is necessary: if F has continuous second partials on an open region U and
its two slopes are M and N (∂F/∂x = M, ∂F/∂y = N), then M's rate in y equals N's rate in x at
every point of U. -/
theorem mixed_partials_eq_of_exact {U : Set (ℝ × ℝ)} (hU : IsOpen U) {F M N : ℝ × ℝ → ℝ}
    (hF2 : ContDiffOn ℝ 2 F U)
    (hF : ∀ p ∈ U,
      HasFDerivAt F (M p • ContinuousLinearMap.fst ℝ ℝ ℝ + N p • ContinuousLinearMap.snd ℝ ℝ ℝ) p) :
    ∀ p ∈ U, deriv (fun t => M (p.1, t)) p.2 = deriv (fun s => N (s, p.2)) p.1 := by
  intro p hp
  have hFd : ∀ q ∈ U, fderiv ℝ F q = M q • ContinuousLinearMap.fst ℝ ℝ ℝ
      + N q • ContinuousLinearMap.snd ℝ ℝ ℝ := fun q hq => (hF q hq).fderiv
  have hMq : ∀ q ∈ U, M q = fderiv ℝ F q (1, 0) := by
    intro q hq; rw [hFd q hq]; simp
  have hNq : ∀ q ∈ U, N q = fderiv ℝ F q (0, 1) := by
    intro q hq; rw [hFd q hq]; simp
  have hcd : ContDiffAt ℝ 2 F p := hF2.contDiffAt (hU.mem_nhds hp)
  have hsymm : IsSymmSndFDerivAt ℝ F p := hcd.isSymmSndFDerivAt (by simp)
  have hdiff : DifferentiableAt ℝ (fderiv ℝ F) p :=
    (hcd.fderiv_right (m := 1) (by norm_num)).differentiableAt one_ne_zero
  have hD : HasFDerivAt (fderiv ℝ F) (fderiv ℝ (fderiv ℝ F) p) (p.1, p.2) := hdiff.hasFDerivAt
  -- slice in t
  have h1 : HasDerivAt (fun t => fderiv ℝ F (p.1, t) (1, 0))
      (fderiv ℝ (fderiv ℝ F) p (0, 1) (1, 0)) p.2 := by
    have := hD.comp_hasDerivAt p.2 (HasDerivAt.prodMk (hasDerivAt_const p.2 p.1) (hasDerivAt_id p.2))
    have := this.clm_apply (hasDerivAt_const p.2 ((1 : ℝ), (0 : ℝ)))
    simpa using this
  have h2 : HasDerivAt (fun s => fderiv ℝ F (s, p.2) (0, 1))
      (fderiv ℝ (fderiv ℝ F) p (1, 0) (0, 1)) p.1 := by
    have := hD.comp_hasDerivAt p.1 (HasDerivAt.prodMk (hasDerivAt_id p.1) (hasDerivAt_const p.1 p.2))
    have := this.clm_apply (hasDerivAt_const p.1 ((0 : ℝ), (1 : ℝ)))
    simpa using this
  have e1 : (fun t => M (p.1, t)) =ᶠ[nhds p.2] (fun t => fderiv ℝ F (p.1, t) (1, 0)) := by
    have : ∀ᶠ t in nhds p.2, (p.1, t) ∈ U :=
      (continuous_const.prodMk continuous_id).continuousAt.preimage_mem_nhds (hU.mem_nhds hp)
    filter_upwards [this] with t ht using hMq _ ht
  have e2 : (fun s => N (s, p.2)) =ᶠ[nhds p.1] (fun s => fderiv ℝ F (s, p.2) (0, 1)) := by
    have : ∀ᶠ s in nhds p.1, (s, p.2) ∈ U :=
      (continuous_id.prodMk continuous_const).continuousAt.preimage_mem_nhds (hU.mem_nhds hp)
    filter_upwards [this] with s hs using hNq _ hs
  rw [e1.deriv_eq, e2.deriv_eq, h1.deriv, h2.deriv]
  exact hsymm _ _

/-- Step 0, solutions are level curves: suppose F's change is M dx + N dy at every point of a
region U, and y is a differentiable path on an open interval (α, β) whose graph stays in U. Then
y solves M + N y' = 0 on the whole interval exactly when F is constant along the path,
F(x, y(x)) = C for one C. -/
theorem solution_iff_level_curve {U : Set (ℝ × ℝ)} {F M N : ℝ × ℝ → ℝ}
    (hF : ∀ p ∈ U,
      HasFDerivAt F (M p • ContinuousLinearMap.fst ℝ ℝ ℝ + N p • ContinuousLinearMap.snd ℝ ℝ ℝ) p)
    {α β : ℝ} {y : ℝ → ℝ} (hy : DifferentiableOn ℝ y (Ioo α β))
    (hyU : ∀ x ∈ Ioo α β, (x, y x) ∈ U) :
    (∀ x ∈ Ioo α β, M (x, y x) + N (x, y x) * deriv y x = 0) ↔
      ∃ C : ℝ, ∀ x ∈ Ioo α β, F (x, y x) = C := by
  have hg : ∀ x ∈ Ioo α β, HasDerivAt (fun x => F (x, y x))
      (M (x, y x) + N (x, y x) * deriv y x) x := by
    intro x hx
    have hyx : HasDerivAt y (deriv y x) x :=
      ((hy x hx).differentiableAt (isOpen_Ioo.mem_nhds hx)).hasDerivAt
    have := (hF _ (hyU x hx)).comp_hasDerivAt x (HasDerivAt.prodMk (hasDerivAt_id x) hyx)
    simp at this
    exact this
  constructor
  · intro h
    obtain ⟨C, hC⟩ := isOpen_Ioo.exists_is_const_of_deriv_eq_zero isPreconnected_Ioo
      (fun x hx => (hg x hx).differentiableAt.differentiableWithinAt)
      (fun x hx => by simp only [Pi.zero_apply]; rw [(hg x hx).deriv, h x hx])
    exact ⟨C, hC⟩
  · rintro ⟨C, hC⟩ x hx
    have hev : (fun x => F (x, y x)) =ᶠ[nhds x] fun _ => C := by
      filter_upwards [isOpen_Ioo.mem_nhds hx] with z hz using hC z hz
    exact (hg x hx).unique ((hasDerivAt_const x C).congr_of_eventuallyEq hev)

-- The valley: F = x^2 + xy + y^2 has slopes M = 2x + y east and N = x + 2y north.
example (p : ℝ × ℝ) :
    HasFDerivAt (fun q : ℝ × ℝ => q.1 ^ 2 + q.1 * q.2 + q.2 ^ 2)
      ((2 * p.1 + p.2) • ContinuousLinearMap.fst ℝ ℝ ℝ
        + (p.1 + 2 * p.2) • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
  have h := ((hasFDerivAt_fst (𝕜 := ℝ) (p := p)).pow 2 |>.add
    ((hasFDerivAt_fst (𝕜 := ℝ) (p := p)).mul (hasFDerivAt_snd (𝕜 := ℝ) (p := p)))).add
    ((hasFDerivAt_snd (𝕜 := ℝ) (p := p)).pow 2)
  convert h using 1
  ext <;> simp

-- The test on the valley: ∂(2x + y)/∂y = 1 and ∂(x + 2y)/∂x = 1 at every point.
example (x y : ℝ) :
    deriv (fun t => 2 * x + t) y = 1 ∧ deriv (fun s => s + 2 * y) x = 1 := by
  constructor
  · simp
  · simp

-- The height at (1, 2): F(1, 2) = 1 + 2 + 4 = 7.
example : (1 : ℤ) ^ 2 + 1 * 2 + 2 ^ 2 = 7 := by norm_num

-- Climbing to (1, 2): east along y = 0 with slope 2x climbs 1, then north at x = 1 with slope 1 + 2y climbs 6.
example : (∫ x in (0 : ℝ)..1, 2 * x) = 1 ∧ (∫ y in (0 : ℝ)..2, (1 + 2 * y)) = 6 := by
  constructor
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun x : ℝ => x ^ 2)
      (fun x _ => by simpa using hasDerivAt_pow 2 x)
      ((by fun_prop : Continuous fun x : ℝ => 2 * x).intervalIntegrable 0 1)]
    norm_num
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun y : ℝ => y + y ^ 2)
      (fun y _ => ((hasDerivAt_id' y).add (hasDerivAt_pow 2 y)).congr_deriv (by norm_num))
      ((by fun_prop : Continuous fun y : ℝ => 1 + 2 * y).intervalIntegrable 0 2)]
    norm_num

-- The start's level: F(0, 1) = 1, the 100 m ring.
example : (0 : ℤ) ^ 2 + 0 * 1 + 1 ^ 2 = 1 := by norm_num

-- The usual mistake: dropping g(y) leaves x^2 + xy, which gives 3 at (1, 2), not 7.
example : (1 : ℤ) ^ 2 + 1 * 2 = 3 := by norm_num

-- Skipping the test: on (2x + 2y)dx + (x + 2y)dy, g'(1) = N - 2x is 2 at x = 0 and 1 at x = 1.
example : ((0 : ℤ) + 2 * 1) - 2 * 0 = 2 ∧ ((1 : ℤ) + 2 * 1) - 2 * 1 = 1 := by norm_num

#print axioms exact_of_mixed_partials_eq
#print axioms mixed_partials_eq_of_exact
#print axioms solution_iff_level_curve
