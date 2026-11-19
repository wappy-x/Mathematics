-- Stokes on manifolds: integrating d of a compactly supported smooth form over the half-space equals integrating the form over its edge with the outward-first orientation, and the dome-tent check agrees.
import Mathlib.Analysis.Calculus.DifferentialForm.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open MeasureTheory Real

/-- The half-space `H` in dimension `n + 1`: points whose last coordinate is `0` or more.
Its edge is the hyperplane where the last coordinate is `0`. -/
def halfSpace (n : ℕ) : Set (Fin (n + 1) → ℝ) := {x | 0 ≤ x (Fin.last n)}

/-- Stokes' theorem on the half-space, the model chart at every edge point of a manifold with
boundary (the card's Step 2). Let `ω` be a smooth `n`-form on the half-space `H` of dimension
`n + 1`, zero outside a closed, bounded set. Then integrating its exterior derivative `dω` over `H`
(standard orientation) gives the same number as integrating `ω` over the edge `∂H`, oriented
outward first. Written in the edge coordinates `y`, outward first gives the edge the sign
`(-1)^(n+1)` times the standard orientation, which is the factor on the right. -/
theorem stokes_on_half_space {n : ℕ}
    (ω : (Fin (n + 1) → ℝ) → (Fin (n + 1) → ℝ) [⋀^Fin n]→L[ℝ] ℝ)
    (hsmooth : ContDiffOn ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) ω (halfSpace n))
    (hsupp : ∃ K : Set (Fin (n + 1) → ℝ), IsCompact K ∧ ∀ x ∈ halfSpace n, x ∉ K → ω x = 0) :
    ∫ x in halfSpace n, extDerivWithin ω (halfSpace n) x (fun i => Pi.single i 1) =
      (-1) ^ (n + 1) *
        ∫ y : Fin n → ℝ, ω (Fin.snoc y 0) (fun i => Pi.single (Fin.castSucc i) 1) := by
  classical
  obtain ⟨K, hK, hKz⟩ := hsupp
  obtain ⟨R, hR⟩ := hK.isBounded.subset_closedBall 0
  set H := halfSpace n with hH_def
  set e : Fin (n + 1) → Fin (n + 1) → ℝ := fun i => Pi.single i 1 with he_def
  set r : ℝ := max R 0 + 1 with hr_def
  have hr0 : 0 < r := by positivity
  have hRr : R < r := by have := le_max_left R 0; linarith
  -- basic facts about the half-space
  have hHconv : Convex ℝ H := by
    intro x hx y hy s t hs ht _
    simp only [hH_def, halfSpace, Set.mem_ofPred_eq, Pi.add_apply, Pi.smul_apply, smul_eq_mul] at *
    positivity
  have hHopen : IsOpen {x : Fin (n + 1) → ℝ | 0 < x (Fin.last n)} :=
    isOpen_lt continuous_const (continuous_apply _)
  have hsubH : {x : Fin (n + 1) → ℝ | 0 < x (Fin.last n)} ⊆ H := by
    intro y (hy : (0 : ℝ) < y (Fin.last n))
    exact hy.le
  have hHint : (interior H).Nonempty := by
    refine ⟨fun _ => 1, interior_maximal hsubH hHopen ?_⟩
    show (0 : ℝ) < 1
    exact one_pos
  have hU : UniqueDiffOn ℝ H := uniqueDiffOn_convex hHconv hHint
  have hHmeas : MeasurableSet H :=
    (isClosed_le continuous_const (continuous_apply (Fin.last n))).measurableSet
  have hωc : ContinuousOn ω H := hsmooth.continuousOn
  have hωd : DifferentiableOn ℝ ω H := hsmooth.differentiableOn (by simp)
  -- ω vanishes far out
  have hzero : ∀ x ∈ H, R < ‖x‖ → ω x = 0 := by
    intro x hx hxR
    refine hKz x hx (fun hxK => ?_)
    have := hR hxK
    rw [Metric.mem_closedBall, dist_zero_right] at this
    linarith
  have hcoord : ∀ (x : Fin (n + 1) → ℝ) (i : Fin (n + 1)), r ≤ |x i| → R < ‖x‖ := by
    intro x i hi
    have := norm_le_pi_norm x i
    rw [Real.norm_eq_abs] at this
    linarith
  have hdzero : ∀ x ∈ H, R < ‖x‖ → extDerivWithin ω H x = 0 := by
    intro x hx hxR
    have hev : ω =ᶠ[nhdsWithin x H] (fun _ => 0) := by
      have : {y : Fin (n + 1) → ℝ | R < ‖y‖} ∈ nhds x :=
        (isOpen_lt continuous_const continuous_norm).mem_nhds hxR
      filter_upwards [self_mem_nhdsWithin, nhdsWithin_le_nhds this] with y hyH hyR
        using hzero y hyH hyR
    rw [hev.extDerivWithin_eq_of_mem hx]
    ext v
    simp [extDerivWithin, ContinuousAlternatingMap.alternatizeUncurryFin_apply]
  -- the box
  set a : Fin (n + 1) → ℝ := fun i => if i = Fin.last n then 0 else -r with ha_def
  set b : Fin (n + 1) → ℝ := fun _ => r with hb_def
  have hab : a ≤ b := by
    intro i
    simp only [ha_def, hb_def]
    split_ifs <;> linarith
  have hboxH : Set.Icc a b ⊆ H := by
    intro x hx
    have := hx.1 (Fin.last n)
    simpa [ha_def, hH_def, halfSpace] using this
  -- Step A: shrink the domain to the box
  have hA : ∫ x in H, extDerivWithin ω H x e = ∫ x in Set.Icc a b, extDerivWithin ω H x e := by
    refine setIntegral_eq_of_subset_of_forall_sdiff_eq_zero hHmeas hboxH ?_
    rintro x ⟨hxH, hxI⟩
    have : ∃ i, r ≤ |x i| := by
      by_contra hcon
      push Not at hcon
      apply hxI
      constructor
      · intro i
        simp only [ha_def]
        split_ifs with h
        · subst h; exact hxH
        · have := hcon i; rw [abs_lt] at this; linarith
      · intro i
        have := hcon i; rw [abs_lt] at this; simp only [hb_def]; linarith
    obtain ⟨i, hi⟩ := this
    rw [hdzero x hxH (hcoord x i hi)]
    rfl
  -- the pieces
  let f : Fin (n + 1) → (Fin (n + 1) → ℝ) → ℝ := fun i x => ((-1 : ℤ) ^ (i : ℕ)) • ω x (i.removeNth e)
  let f' : Fin (n + 1) → (Fin (n + 1) → ℝ) → (Fin (n + 1) → ℝ) →L[ℝ] ℝ :=
    fun i x => ((-1 : ℤ) ^ (i : ℕ)) • fderivWithin ℝ (fun y => ω y (i.removeNth e)) H x
  have hB : Set.EqOn (fun x => extDerivWithin ω H x e) (fun x => ∑ i, f' i x (Pi.single i 1))
      (Set.Icc a b) := by
    intro x hx
    simp only [f', smul_apply]
    exact extDerivWithin_apply (hωd x (hboxH hx)) (hU x (hboxH hx)) e
  have hcont : ContinuousOn (fun x => extDerivWithin ω H x e) H := by
    have h1 : ContinuousOn (fderivWithin ℝ ω H) H :=
      hsmooth.continuousOn_fderivWithin hU (by simp)
    have h2 : ContinuousOn (fun x =>
        ContinuousAlternatingMap.alternatizeUncurryFinCLM ℝ _ ℝ (fderivWithin ℝ ω H x)) H :=
      (ContinuousLinearMap.continuous _).comp_continuousOn h1
    simp only [ContinuousAlternatingMap.alternatizeUncurryFinCLM_apply] at h2
    exact (continuous_eval_const e).comp_continuousOn h2
  have hInt : IntegrableOn (fun x => ∑ i, f' i x (Pi.single i 1)) (Set.Icc a b) :=
    ((hcont.mono hboxH).integrableOn_compact isCompact_Icc).congr_fun hB measurableSet_Icc
  have hfc : ∀ i, ContinuousOn (f i) (Set.Icc a b) := by
    intro i
    have h1 : ContinuousOn (fun x => ω x (i.removeNth e)) H :=
      (continuous_eval_const _).comp_continuousOn hωc
    exact (h1.const_smul ((-1 : ℤ) ^ (i : ℕ))).mono hboxH
  have hfd : ∀ x ∈ (Set.univ.pi fun i => Set.Ioo (a i) (b i)) \ ∅, ∀ i,
      HasFDerivAt (f i) (f' i x) x := by
    intro x hx i
    have hxl : 0 < x (Fin.last n) := by
      have := (hx.1 (Fin.last n) (Set.mem_univ _)).1
      simpa [ha_def] using this
    have hnhds : H ∈ nhds x :=
      Filter.mem_of_superset (hHopen.mem_nhds hxl) hsubH
    have hda : DifferentiableAt ℝ ω x := (hωd x (mem_of_mem_nhds hnhds)).differentiableAt hnhds
    have hg : DifferentiableAt ℝ (fun y => ω y (i.removeNth e)) x :=
      hda.continuousAlternatingMap_apply_const _
    simp only [f', fderivWithin_of_mem_nhds hnhds]
    exact hg.hasFDerivAt.const_smul ((-1 : ℤ) ^ (i : ℕ))
  have hC := integral_divergence_of_hasFDerivAt_off_countable' a b hab f f' ∅ Set.countable_empty
    hfc hfd hInt
  have hfront : ∀ i, ∫ y in Set.Icc (a ∘ i.succAbove) (b ∘ i.succAbove),
      f i (i.insertNth (b i) y) = 0 := by
    intro i
    refine setIntegral_eq_zero_of_forall_eq_zero (fun y hy => ?_)
    have hmem : i.insertNth (b i) y ∈ Set.Icc a b :=
      Fin.insertNth_mem_Icc.2 ⟨⟨hab i, le_rfl⟩, hy⟩
    have : ω (i.insertNth (b i) y) = 0 :=
      hzero _ (hboxH hmem) (hcoord _ i (by simp [hb_def, abs_of_pos hr0]))
    simp [f, this]
  have hback : ∀ i, i ≠ Fin.last n → ∫ y in Set.Icc (a ∘ i.succAbove) (b ∘ i.succAbove),
      f i (i.insertNth (a i) y) = 0 := by
    intro i hi
    refine setIntegral_eq_zero_of_forall_eq_zero (fun y hy => ?_)
    have hmem : i.insertNth (a i) y ∈ Set.Icc a b :=
      Fin.insertNth_mem_Icc.2 ⟨⟨le_rfl, hab i⟩, hy⟩
    have : ω (i.insertNth (a i) y) = 0 :=
      hzero _ (hboxH hmem) (hcoord _ i (by simp [ha_def, hi, abs_of_pos hr0]))
    simp [f, this]
  rw [hA, setIntegral_congr_fun measurableSet_Icc hB, hC, Finset.sum_eq_single (Fin.last n)
    (fun i _ hi => by rw [hfront i, hback i hi, sub_self]) (by simp), hfront]
  have hface : Set.Icc (a ∘ (Fin.last n).succAbove) (b ∘ (Fin.last n).succAbove) =
      Set.Icc (fun _ => -r) (fun _ => r) := by
    congr 1
    · ext j; simp [ha_def, Fin.succAbove_last, Fin.castSucc_ne_last]
  have hal : a (Fin.last n) = 0 := by simp [ha_def]
  rw [hface, hal]
  have hfl : ∀ y : Fin n → ℝ, f (Fin.last n) ((Fin.last n).insertNth 0 y) =
      (-1) ^ n * ω (Fin.snoc y 0) (fun i => Pi.single (Fin.castSucc i) 1) := by
    intro y
    simp only [f, Fin.insertNth_last', Fin.val_last, zsmul_eq_mul, Int.cast_pow, Int.cast_neg,
      Int.cast_one, Fin.removeNth_last]
    rfl
  simp_rw [hfl]
  rw [setIntegral_eq_integral_of_forall_compl_eq_zero, integral_const_mul]
  · ring
  · intro y hy
    have : ∃ j, r ≤ |y j| := by
      by_contra hcon
      push Not at hcon
      apply hy
      constructor
      · intro j; have := hcon j; rw [abs_lt] at this; linarith
      · intro j; have := hcon j; rw [abs_lt] at this; linarith
    obtain ⟨j, hj⟩ := this
    have hH0 : (Fin.snoc y 0 : Fin (n + 1) → ℝ) ∈ H := by
      simp [hH_def, halfSpace]
    have h0 : ω (Fin.snoc y 0) = 0 :=
      hzero _ hH0 (hcoord _ (Fin.castSucc j) (by simpa using hj))
    simp [h0]

/-- The eddy's part of the wind on the tent, in the globe chart: `ω = 3 dx + g(φ) dθ`, with
`g(φ) = 0.4 R² (1 + cos φ) sin² φ` and `R = 1.5 m`. -/
noncomputable def tentG (φ : ℝ) : ℝ := 2 / 5 * (3 / 2) ^ 2 * (1 + cos φ) * sin φ ^ 2

/-- `tentG` is smooth enough to differentiate once with a continuous derivative. -/
theorem tentG_contDiff : ContDiff ℝ 1 tentG := by
  unfold tentG
  fun_prop

/-- Since `tentG 0 = 0`, adding up `tentG'` from `0` to `a` gives `tentG a`. -/
theorem tentG_integral_deriv (a : ℝ) : ∫ φ in (0 : ℝ)..a, deriv tentG φ = tentG a := by
  rw [intervalIntegral.integral_deriv_eq_sub
    (fun x _ => (tentG_contDiff.differentiable one_ne_zero) x)
    ((tentG_contDiff.continuous_deriv le_rfl).intervalIntegrable _ _)]
  simp [tentG]

#print axioms tentG_contDiff
#print axioms tentG_integral_deriv

/-- Stokes on every cap of the tent: the spin `dω = g'(φ) dφ ∧ dθ` added over the cap from the
top down to angle `a` equals the wind `g(a) dθ` added once round the cap's edge circle. -/
theorem tent_cap_stokes (a : ℝ) :
    (∫ θ in (0 : ℝ)..2 * π, ∫ φ in (0 : ℝ)..a, deriv tentG φ) =
      ∫ θ in (0 : ℝ)..2 * π, tentG a := by
  simp only [tentG_integral_deriv]

/-- The whole tent panel: both sides of Stokes equal `2π × 0.9` m²/s. -/
theorem tent_panel_value :
    (∫ θ in (0 : ℝ)..2 * π, ∫ φ in (0 : ℝ)..π / 2, deriv tentG φ) = 2 * π * (9 / 10) := by
  simp only [tentG_integral_deriv, intervalIntegral.integral_const, smul_eq_mul]
  simp [tentG]
  norm_num

-- eddy speed at the hem: 0.4 per second × 1.5 m = 0.6 m/s
example : (2 / 5 : ℚ) * (3 / 2) = 3 / 5 := by norm_num
-- g at the hem: 0.4 × 2.25 × (1 + 0) × 1 = 0.9
example : (2 / 5 : ℚ) * (3 / 2) ^ 2 * (1 + 0) * 1 = 9 / 10 := by norm_num
-- cap down to 60°: 0.4 × 2.25 × 1.5 × 0.75 = 1.0125
example : (2 / 5 : ℚ) * (9 / 4) * (3 / 2) * (3 / 4) = 81 / 80 := by norm_num
-- n = 1, the breeze 3 dx along the half hem east to west: 3 × (-1.5) - 3 × 1.5 = -9
example : (3 : ℚ) * (-3 / 2) - 3 * (3 / 2) = -9 := by norm_num

#print axioms stokes_on_half_space
#print axioms tent_cap_stokes
#print axioms tent_panel_value
