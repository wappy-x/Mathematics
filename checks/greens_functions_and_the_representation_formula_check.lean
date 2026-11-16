-- Green's function: on a box in space, Green's two identities hold, the temperature at any inside point equals the sources weighted by the Green's function minus the wall data weighted by its outward slope, and the Green's function is symmetric.
import Mathlib
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Tactic.NormNum

open Real Set MeasureTheory InnerProductSpace Laplacian

/-! Space is `E = EuclideanSpace ℝ (Fin 3)`, with its ordinary volume. The region is a box with
lower corner `lo` and upper corner `hi` (the card's cube is `lo = 0`, `hi = 1`): `openBox` is its
inside Ω, `closedBox` is Ω̄, and the walls ∂Ω are `closedBox \ openBox`. The Laplacian `Δ` and the
gradient `gradient` are Mathlib's. Mathlib has no surface integral over a general wall, which is
why the region is a box: its wall is six flat faces, and a face integral is an ordinary area
integral. At the pole Lean's `1 / 0 = 0` gives `Φ` the value `0`; one point has volume zero. -/

/-- The inside Ω of the box with corners `lo` and `hi`. -/
def openBox (lo hi : Fin 3 → ℝ) : Set (EuclideanSpace ℝ (Fin 3)) :=
  {x | ∀ i, lo i < x i ∧ x i < hi i}

/-- The closed box Ω̄: the inside together with its six walls. -/
def closedBox (lo hi : Fin 3 → ℝ) : Set (EuclideanSpace ℝ (Fin 3)) :=
  {x | ∀ i, lo i ≤ x i ∧ x i ≤ hi i}

/-- The wall integral `∮_{∂Ω} F(p, n) dS` over the six faces of the box, where `p` is the wall
point and `n` the outward unit normal there. For each direction `i` the far face `x_i = hi_i` has
normal `e_i` and the near face `x_i = lo_i` has normal `−e_i`. A face point is
`Fin.insertNth i c y`: `i`-th coordinate `c`, the other two coordinates `y`, which run over a
rectangle; the face integral is the area integral over that rectangle. -/
noncomputable def wallIntegral (lo hi : Fin 3 → ℝ)
    (F : EuclideanSpace ℝ (Fin 3) → EuclideanSpace ℝ (Fin 3) → ℝ) : ℝ :=
  ∑ i : Fin 3,
    ((∫ y in Icc (lo ∘ i.succAbove) (hi ∘ i.succAbove),
        F (WithLp.toLp 2 (Fin.insertNth i (hi i) y)) (EuclideanSpace.single i 1)) +
      ∫ y in Icc (lo ∘ i.succAbove) (hi ∘ i.succAbove),
        F (WithLp.toLp 2 (Fin.insertNth i (lo i) y)) (-EuclideanSpace.single i 1))

/-- The fundamental solution `Φ(x) = 1 / (4π|x|)`: a unit poke in space with no walls. -/
noncomputable def fundSol3 (x : EuclideanSpace ℝ (Fin 3)) : ℝ := 1 / (4 * π * ‖x‖)

/-- `G` is the Green's function of the box (wall values held at zero). For every pole `y` inside,
`G(·, y) = Φ(· − y) − h_y` away from `y`, where the corrector `h_y` is smooth (two continuous
derivatives on an open set holding the closed box) and harmonic inside, and `G(x, y) = 0` for
every wall point `x`. This is the card's `−Δ_x G(x, y) = δ(x − y)` in Ω, `G = 0` on ∂Ω. -/
def IsGreenFunctionBox (lo hi : Fin 3 → ℝ)
    (G : EuclideanSpace ℝ (Fin 3) → EuclideanSpace ℝ (Fin 3) → ℝ) : Prop :=
  ∀ y ∈ openBox lo hi, ∃ h : EuclideanSpace ℝ (Fin 3) → ℝ,
    (∃ U : Set (EuclideanSpace ℝ (Fin 3)), IsOpen U ∧ closedBox lo hi ⊆ U ∧ ContDiffOn ℝ 2 h U) ∧
    HarmonicOnNhd h (openBox lo hi) ∧
    (∀ x, x ≠ y → G x y = fundSol3 (x - y) - h x) ∧
    (∀ x ∈ closedBox lo hi \ openBox lo hi, G x y = 0)

local notation "E3" => EuclideanSpace ℝ (Fin 3)

lemma closedBox_eq_preimage (lo hi : Fin 3 → ℝ) :
    closedBox lo hi = (WithLp.ofLp : E3 → (Fin 3 → ℝ)) ⁻¹' Icc lo hi := by
  ext x; simp [closedBox, Pi.le_def, forall_and]

#print axioms closedBox_eq_preimage

lemma openBox_eq_preimage (lo hi : Fin 3 → ℝ) :
    openBox lo hi = (WithLp.ofLp : E3 → (Fin 3 → ℝ)) ⁻¹' (Set.pi univ fun i => Ioo (lo i) (hi i)) := by
  ext x; simp [openBox]

#print axioms openBox_eq_preimage

lemma setIntegral_closedBox (lo hi : Fin 3 → ℝ) (H : E3 → ℝ) :
    ∫ x in closedBox lo hi, H x = ∫ y in Icc lo hi, H (WithLp.toLp 2 y) := by
  rw [closedBox_eq_preimage]
  have := (EuclideanSpace.volume_preserving_symm_measurableEquiv_toLp (Fin 3)).setIntegral_preimage_emb
    (MeasurableEquiv.measurableEmbedding _) (fun y => H (WithLp.toLp 2 y)) (Icc lo hi)
  exact this

#print axioms setIntegral_closedBox

lemma integrableOn_closedBox (lo hi : Fin 3 → ℝ) (H : E3 → ℝ) :
    IntegrableOn H (closedBox lo hi) ↔ IntegrableOn (fun y => H (WithLp.toLp 2 y)) (Icc lo hi) := by
  rw [closedBox_eq_preimage]
  have := (EuclideanSpace.volume_preserving_symm_measurableEquiv_toLp (Fin 3)).integrableOn_comp_preimage
    (MeasurableEquiv.measurableEmbedding _) (f := fun y => H (WithLp.toLp 2 y)) (s := Icc lo hi)
  exact this

#print axioms integrableOn_closedBox

lemma box_divergence {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i)
    (φ : Fin 3 → E3 → ℝ) (φ' : Fin 3 → E3 → (E3 →L[ℝ] ℝ))
    (Hc : ∀ i, ContinuousOn (φ i) (closedBox lo hi))
    (Hd : ∀ x ∈ openBox lo hi, ∀ i, HasFDerivAt (φ i) (φ' i x) x)
    (Hi : IntegrableOn (fun x => ∑ i, φ' i x (EuclideanSpace.single i 1)) (closedBox lo hi))
    (F : E3 → E3 → ℝ)
    (hF : ∀ i p, F p (EuclideanSpace.single i 1) = φ i p ∧ F p (-EuclideanSpace.single i 1) = -φ i p) :
    ∫ x in closedBox lo hi, ∑ i, φ' i x (EuclideanSpace.single i 1) = wallIntegral lo hi F := by
  let L : (Fin 3 → ℝ) →L[ℝ] E3 := (PiLp.continuousLinearEquiv 2 ℝ (fun _ : Fin 3 => ℝ)).symm.toContinuousLinearMap
  have hL : ∀ y, L y = WithLp.toLp 2 y := fun y => rfl
  have key := integral_divergence_of_hasFDerivAt_off_countable' (n := 2) lo hi hle
    (fun i y => φ i (WithLp.toLp 2 y)) (fun i y => (φ' i (WithLp.toLp 2 y)).comp L) ∅ countable_empty
    ?_ ?_ ?_
  · rw [setIntegral_closedBox]
    have e1 : ∀ i : Fin 3, L (Pi.single i 1) = EuclideanSpace.single i 1 := by
      intro i; rw [hL]; rfl
    simp only [ContinuousLinearMap.comp_apply, e1] at key
    rw [key, wallIntegral]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [sub_eq_add_neg, ← integral_neg]
    congr 1
    · exact integral_congr_ae (Filter.Eventually.of_forall fun y => ((hF i _).1).symm)
    · exact integral_congr_ae (Filter.Eventually.of_forall fun y => ((hF i _).2).symm)
  · intro i
    refine (Hc i).comp L.continuous.continuousOn ?_
    intro y hy; rw [closedBox_eq_preimage]; simpa using hy
  · intro y hy i
    have hx : WithLp.toLp 2 y ∈ openBox lo hi := by
      rw [openBox_eq_preimage]; simpa using hy.1
    exact (Hd _ hx i).comp y L.hasFDerivAt
  · rw [integrableOn_closedBox] at Hi
    have e1 : ∀ i : Fin 3, L (Pi.single i 1) = EuclideanSpace.single i 1 := by
      intro i; rw [hL]; rfl
    simpa [e1] using Hi

#print axioms box_divergence

lemma isCompact_closedBox (lo hi : Fin 3 → ℝ) : IsCompact (closedBox lo hi) := by
  have : closedBox lo hi = (WithLp.toLp 2 : (Fin 3 → ℝ) → E3) '' Icc lo hi := by
    rw [closedBox_eq_preimage]; ext x; constructor
    · intro hx; exact ⟨WithLp.ofLp x, hx, by simp⟩
    · rintro ⟨y, hy, rfl⟩; simpa using hy
  rw [this]
  exact isCompact_Icc.image (PiLp.continuousLinearEquiv 2 ℝ (fun _ : Fin 3 => ℝ)).symm.continuous

#print axioms isCompact_closedBox

lemma isOpen_openBox (lo hi : Fin 3 → ℝ) : IsOpen (openBox lo hi) := by
  rw [openBox_eq_preimage]
  exact (isOpen_set_pi finite_univ fun i _ => isOpen_Ioo).preimage
    (PiLp.continuousLinearEquiv 2 ℝ (fun _ : Fin 3 => ℝ)).continuous

#print axioms isOpen_openBox

lemma isClosed_closedBox (lo hi : Fin 3 → ℝ) : IsClosed (closedBox lo hi) :=
  (isCompact_closedBox lo hi).isClosed

#print axioms isClosed_closedBox

lemma openBox_subset_closedBox (lo hi : Fin 3 → ℝ) : openBox lo hi ⊆ closedBox lo hi :=
  fun _ hx i => ⟨(hx i).1.le, (hx i).2.le⟩

#print axioms openBox_subset_closedBox

lemma convex_closedBox (lo hi : Fin 3 → ℝ) : Convex ℝ (closedBox lo hi) := by
  intro x hx y hy a b ha hb hab i
  simp only [PiLp.add_apply, PiLp.smul_apply, smul_eq_mul]
  have h1 := hx i; have h2 := hy i
  have e : lo i = a * lo i + b * lo i := by rw [← add_mul, hab, one_mul]
  have e' : hi i = a * hi i + b * hi i := by rw [← add_mul, hab, one_mul]
  constructor
  · nlinarith [mul_le_mul_of_nonneg_left h1.1 ha, mul_le_mul_of_nonneg_left h2.1 hb]
  · nlinarith [mul_le_mul_of_nonneg_left h1.2 ha, mul_le_mul_of_nonneg_left h2.2 hb]

#print axioms convex_closedBox

lemma closedBox_ae_eq_openBox (lo hi : Fin 3 → ℝ) :
    (closedBox lo hi : Set E3) =ᵐ[volume] openBox lo hi := by
  rw [closedBox_eq_preimage, openBox_eq_preimage]
  have h := (Measure.univ_pi_Ioo_ae_eq_Icc (μ := fun _ : Fin 3 => (volume : Measure ℝ))
    (f := lo) (g := hi))
  have hq := (EuclideanSpace.volume_preserving_symm_measurableEquiv_toLp (Fin 3)).quasiMeasurePreserving
  exact (hq.preimage_ae_eq h).symm

#print axioms closedBox_ae_eq_openBox

lemma ae_mem_openBox (lo hi : Fin 3 → ℝ) :
    ∀ᵐ x ∂(volume.restrict (closedBox lo hi)), x ∈ openBox lo hi := by
  rw [Measure.restrict_congr_set (closedBox_ae_eq_openBox lo hi)]
  exact ae_restrict_mem (isOpen_openBox lo hi).measurableSet

#print axioms ae_mem_openBox

lemma laplacian_eq_sum_fderiv {f : E3 → ℝ} {x : E3} (hf : ContDiffAt ℝ 2 f x) :
    Δ f x = ∑ i, fderiv ℝ (fun y => fderiv ℝ f y (EuclideanSpace.single i 1)) x
      (EuclideanSpace.single i 1) := by
  rw [laplacian_eq_iteratedFDeriv_orthonormalBasis (v := EuclideanSpace.basisFun (Fin 3) ℝ)]
  refine Finset.sum_congr rfl fun i _ => ?_
  have hd : DifferentiableAt ℝ (fderiv ℝ f) x :=
    (hf.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  rw [iteratedFDeriv_two_apply, fderiv_clm_apply hd (differentiableAt_const _)]
  simp

#print axioms laplacian_eq_sum_fderiv

lemma gradient_apply_single (f : E3 → ℝ) (x : E3) (i : Fin 3) :
    gradient f x i = fderiv ℝ f x (EuclideanSpace.single i 1) := by
  have := EuclideanSpace.inner_single_left i (1 : ℝ) (gradient f x)
  simp only [map_one, one_mul] at this
  rw [← this, real_inner_comm, gradient, InnerProductSpace.toDual_symm_apply]

#print axioms gradient_apply_single

lemma inner_gradient_eq_sum (f g : E3 → ℝ) (x : E3) :
    ⟪gradient f x, gradient g x⟫_ℝ = ∑ i, fderiv ℝ f x (EuclideanSpace.single i 1) *
      fderiv ℝ g x (EuclideanSpace.single i 1) := by
  rw [PiLp.inner_apply]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [gradient_apply_single, gradient_apply_single]
  simp [mul_comm]

#print axioms inner_gradient_eq_sum

lemma contDiffOn_partial {u : E3 → ℝ} {U : Set E3} (hU : IsOpen U) (hu : ContDiffOn ℝ 2 u U)
    (w : E3) : ContDiffOn ℝ 1 (fun y => fderiv ℝ u y w) U :=
  (hu.fderiv_of_isOpen hU (m := 1) (by norm_num)).clm_apply contDiffOn_const

#print axioms contDiffOn_partial

lemma continuousOn_partial2 {u : E3 → ℝ} {U : Set E3} (hU : IsOpen U) (hu : ContDiffOn ℝ 2 u U)
    (w w' : E3) : ContinuousOn (fun y => fderiv ℝ (fun z => fderiv ℝ u z w) y w') U :=
  ((contDiffOn_partial hU hu w).continuousOn_fderiv_of_isOpen hU le_rfl).clm_apply continuousOn_const

#print axioms continuousOn_partial2

lemma hasFDerivAt_partial {u : E3 → ℝ} {x : E3} (hu : ContDiffAt ℝ 2 u x) (w : E3) :
    HasFDerivAt (fun y => fderiv ℝ u y w) (fderiv ℝ (fun y => fderiv ℝ u y w) x) x :=
  (((hu.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)).clm_apply
    (differentiableAt_const w)).hasFDerivAt

#print axioms hasFDerivAt_partial

lemma continuousOn_laplacian {u : E3 → ℝ} {U : Set E3} (hU : IsOpen U) (hu : ContDiffOn ℝ 2 u U) :
    ContinuousOn (Δ u) U := by
  have : ContinuousOn (fun x => ∑ i, fderiv ℝ (fun y => fderiv ℝ u y (EuclideanSpace.single i 1)) x
      (EuclideanSpace.single i 1)) U :=
    continuousOn_finsetSum _ fun i _ => continuousOn_partial2 hU hu _ _
  refine this.congr fun x hx => ?_
  exact laplacian_eq_sum_fderiv (hu.contDiffAt (hU.mem_nhds hx))

#print axioms continuousOn_laplacian

/-- Green's first identity on a box, for functions twice differentiable near the closed box. -/
lemma green_first_box {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i) {u v : E3 → ℝ} {U : Set E3}
    (hU : IsOpen U) (hsub : closedBox lo hi ⊆ U) (hu : ContDiffOn ℝ 2 u U)
    (hv : ContDiffOn ℝ 2 v U) :
    (∫ x in closedBox lo hi, v x * Δ u x + ⟪gradient v x, gradient u x⟫_ℝ) =
      wallIntegral lo hi (fun p n => v p * fderiv ℝ u p n) := by
  set e : Fin 3 → E3 := fun i => EuclideanSpace.single i 1 with he
  have hdiv : ∀ x ∈ U, (∑ i, (v x • fderiv ℝ (fun y => fderiv ℝ u y (e i)) x +
      fderiv ℝ u x (e i) • fderiv ℝ v x) (e i)) = v x * Δ u x + ⟪gradient v x, gradient u x⟫_ℝ := by
    intro x hx
    rw [laplacian_eq_sum_fderiv (hu.contDiffAt (hU.mem_nhds hx)), inner_gradient_eq_sum,
      Finset.mul_sum, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [add_apply, smul_apply, smul_eq_mul, he]
    ring
  have key := box_divergence hle (fun i p => v p * fderiv ℝ u p (e i))
    (fun i x => v x • fderiv ℝ (fun y => fderiv ℝ u y (e i)) x + fderiv ℝ u x (e i) • fderiv ℝ v x)
    ?_ ?_ ?_ (fun p n => v p * fderiv ℝ u p n) ?_
  · rw [← key]
    refine setIntegral_congr_fun (isClosed_closedBox lo hi).measurableSet fun x hx => ?_
    exact (hdiv x (hsub hx)).symm
  · intro i
    exact (hv.continuousOn.mul ((hu.continuousOn_fderiv_of_isOpen hU (by norm_num)).clm_apply
      continuousOn_const)).mono hsub
  · intro x hx i
    have hxU := hsub (openBox_subset_closedBox lo hi hx)
    have hu2 := hu.contDiffAt (hU.mem_nhds hxU)
    have hv2 := hv.contDiffAt (hU.mem_nhds hxU)
    exact (hv2.differentiableAt (by norm_num)).hasFDerivAt.mul (hasFDerivAt_partial hu2 (e i))
  · refine ContinuousOn.integrableOn_compact (isCompact_closedBox lo hi) ?_
    refine (continuousOn_finsetSum _ fun i _ => ?_).mono hsub
    refine ContinuousOn.add ?_ ?_
    · exact hv.continuousOn.mul (continuousOn_partial2 hU hu _ _)
    · exact ((hu.continuousOn_fderiv_of_isOpen hU (by norm_num)).clm_apply continuousOn_const).mul
        ((hv.continuousOn_fderiv_of_isOpen hU (by norm_num)).clm_apply continuousOn_const)
  · intro i p
    simp [he]

#print axioms green_first_box

/-- Green's second identity on a box, in a general form: `u` is twice differentiable inside and
continuous up to the walls, with a continuous extension `Du` of its derivative; `v` is twice
differentiable near the closed box. -/
lemma green_second_general {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i) {u v : E3 → ℝ}
    (Du : E3 → E3 →L[ℝ] ℝ) (hu2 : ContDiffOn ℝ 2 u (openBox lo hi))
    (huc : ContinuousOn u (closedBox lo hi)) (hDu : ContinuousOn Du (closedBox lo hi))
    (hDu' : ∀ x ∈ openBox lo hi, Du x = fderiv ℝ u x)
    (hΔu : IntegrableOn (Δ u) (closedBox lo hi)) {U : Set E3}
    (hU : IsOpen U) (hsub : closedBox lo hi ⊆ U) (hv : ContDiffOn ℝ 2 v U) :
    (∫ x in closedBox lo hi, u x * Δ v x - v x * Δ u x) =
      wallIntegral lo hi (fun p n => u p * fderiv ℝ v p n - v p * Du p n) := by
  set e : Fin 3 → E3 := fun i => EuclideanSpace.single i 1 with he
  set φ' : Fin 3 → E3 → (E3 →L[ℝ] ℝ) := fun i x =>
    (u x • fderiv ℝ (fun y => fderiv ℝ v y (e i)) x + fderiv ℝ v x (e i) • fderiv ℝ u x) -
      (v x • fderiv ℝ (fun y => fderiv ℝ u y (e i)) x + Du x (e i) • fderiv ℝ v x) with hφ'
  have hdiv : ∀ x ∈ openBox lo hi, (∑ i, φ' i x (e i)) = u x * Δ v x - v x * Δ u x := by
    intro x hx
    have hxU := hsub (openBox_subset_closedBox lo hi hx)
    rw [laplacian_eq_sum_fderiv (hu2.contDiffAt ((isOpen_openBox lo hi).mem_nhds hx)),
      laplacian_eq_sum_fderiv (hv.contDiffAt (hU.mem_nhds hxU)),
      Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [hφ', hDu' x hx, add_apply, sub_apply,
      smul_apply, smul_eq_mul, he]
    ring
  have hint : IntegrableOn (fun x => u x * Δ v x - v x * Δ u x) (closedBox lo hi) := by
    refine IntegrableOn.sub ?_ ?_
    · exact ContinuousOn.integrableOn_compact (isCompact_closedBox lo hi)
        (huc.mul ((continuousOn_laplacian hU hv).mono hsub))
    · exact hΔu.continuousOn_mul (hv.continuousOn.mono hsub) (isCompact_closedBox lo hi)
  have hae : (fun x => ∑ i, φ' i x (e i)) =ᵐ[volume.restrict (closedBox lo hi)]
      (fun x => u x * Δ v x - v x * Δ u x) := by
    filter_upwards [ae_mem_openBox lo hi] with x hx using hdiv x hx
  have key := box_divergence hle (fun i p => u p * fderiv ℝ v p (e i) - v p * Du p (e i)) φ'
    ?_ ?_ (hint.congr_fun_ae hae.symm) (fun p n => u p * fderiv ℝ v p n - v p * Du p n) ?_
  · rw [← key]
    exact integral_congr_ae hae.symm
  · intro i
    refine ContinuousOn.sub ?_ ?_
    · exact huc.mul (((hv.continuousOn_fderiv_of_isOpen hU (by norm_num)).clm_apply
        continuousOn_const).mono hsub)
    · exact (hv.continuousOn.mono hsub).mul (hDu.clm_apply continuousOn_const)
  · intro x hx i
    have hxU := hsub (openBox_subset_closedBox lo hi hx)
    have hu2x := hu2.contDiffAt ((isOpen_openBox lo hi).mem_nhds hx)
    have hv2 := hv.contDiffAt (hU.mem_nhds hxU)
    have hDux : HasFDerivAt (fun y => Du y (e i)) (fderiv ℝ (fun y => fderiv ℝ u y (e i)) x) x := by
      refine (hasFDerivAt_partial hu2x (e i)).congr_of_eventuallyEq ?_
      filter_upwards [(isOpen_openBox lo hi).mem_nhds hx] with y hy
      rw [hDu' y hy]
    exact ((hu2x.differentiableAt (by norm_num)).hasFDerivAt.mul
      (hasFDerivAt_partial hv2 (e i))).sub
      ((hv2.differentiableAt (by norm_num)).hasFDerivAt.mul hDux)
  · intro i p
    refine ⟨rfl, ?_⟩
    simp only [he, map_neg, mul_neg]
    ring

#print axioms green_second_general

/-- A smoothed fundamental solution centred at `x`; `s = 0` gives back `Φ(· − x)`. -/
noncomputable def Ψc (s : ℝ) (x y : E3) : ℝ := (4 * π)⁻¹ * (‖y - x‖ ^ 2 + s) ^ (-(1 / 2 : ℝ))

lemma Ψc_zero_eq {x y : E3} (hy : y ≠ x) : Ψc 0 x y = fundSol3 (y - x) := by
  have hn : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hy)
  rw [Ψc, fundSol3, add_zero, Real.rpow_neg (by positivity), ← Real.sqrt_eq_rpow,
    Real.sqrt_sq hn.le]
  field_simp

#print axioms Ψc_zero_eq

lemma hasFDerivAt_normsq_sub (x y : E3) (s : ℝ) :
    HasFDerivAt (fun z : E3 => ‖z - x‖ ^ 2 + s) (2 • innerSL ℝ (y - x)) y := by
  have := ((hasFDerivAt_id y).sub_const x).norm_sq.add_const s
  simpa using this

#print axioms hasFDerivAt_normsq_sub

lemma hasFDerivAt_Ψc {s : ℝ} {x y : E3} (h : 0 < ‖y - x‖ ^ 2 + s) :
    HasFDerivAt (Ψc s x)
      ((-((4 * π)⁻¹ * (‖y - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)))) • innerSL ℝ (y - x)) y := by
  have h1 := ((hasFDerivAt_normsq_sub x y s).rpow_const (p := -(1 / 2 : ℝ)) (Or.inl h.ne')).const_mul
    ((4 * π)⁻¹)
  refine h1.congr_fderiv ?_
  ext n
  simp
  ring_nf

#print axioms hasFDerivAt_Ψc

lemma fderiv_Ψc_apply {s : ℝ} {x y : E3} (h : 0 < ‖y - x‖ ^ 2 + s) (n : E3) :
    fderiv ℝ (Ψc s x) y n = -((4 * π)⁻¹ * (‖y - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)) * ⟪y - x, n⟫_ℝ) := by
  rw [(hasFDerivAt_Ψc h).fderiv]
  simp only [smul_apply, innerSL_apply_apply, smul_eq_mul]
  ring

#print axioms fderiv_Ψc_apply

lemma contDiff_Ψc {s : ℝ} (hs : 0 < s) (x : E3) : ContDiff ℝ 2 (Ψc s x) := by
  unfold Ψc
  refine contDiff_const.mul ?_
  refine ContDiff.rpow_const_of_ne ?_ fun y => by positivity
  exact ((contDiff_id.sub contDiff_const).norm_sq ℝ).add contDiff_const

#print axioms contDiff_Ψc

lemma laplacian_Ψc {s : ℝ} (hs : 0 < s) (x y : E3) :
    Δ (Ψc s x) y = -(3 * s * (4 * π)⁻¹ * (‖y - x‖ ^ 2 + s) ^ (-(5 / 2 : ℝ))) := by
  rw [laplacian_eq_sum_fderiv ((contDiff_Ψc hs x).contDiffAt)]
  have hpos : ∀ z : E3, 0 < ‖z - x‖ ^ 2 + s := fun z => by positivity
  have hfun : ∀ i : Fin 3, (fun z => fderiv ℝ (Ψc s x) z (EuclideanSpace.single i 1)) =
      fun z => -((4 * π)⁻¹ * (‖z - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)) *
        ⟪z - x, EuclideanSpace.single i 1⟫_ℝ) := by
    intro i; funext z; exact fderiv_Ψc_apply (hpos z) _
  have hder : ∀ i : Fin 3, fderiv ℝ (fun z => -((4 * π)⁻¹ * (‖z - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)) *
        ⟪z - x, EuclideanSpace.single i 1⟫_ℝ)) y (EuclideanSpace.single i 1) =
      -((4 * π)⁻¹ * ((-(3 / 2 : ℝ)) * (‖y - x‖ ^ 2 + s) ^ (-(5 / 2 : ℝ)) * (2 * (y - x) i)
        * (y - x) i + (‖y - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)))) := by
    intro i
    have hA := (hasFDerivAt_normsq_sub x y s).rpow_const (p := -(3 / 2 : ℝ)) (Or.inl (hpos y).ne')
    have hB : HasFDerivAt (fun z : E3 => ⟪z - x, EuclideanSpace.single i 1⟫_ℝ)
        (innerSL ℝ (EuclideanSpace.single i (1 : ℝ))) y := by
      have := (innerSL ℝ (EuclideanSpace.single i (1 : ℝ))).hasFDerivAt (x := y - x)
      have h2 := this.comp y ((hasFDerivAt_id y).sub_const x)
      refine (h2.congr_fderiv ?_).congr_of_eventuallyEq ?_
      · ext n; simp
      · filter_upwards with z
        simp [real_inner_comm]
    have : HasFDerivAt (fun z => -((4 * π)⁻¹ * (‖z - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)) *
        ⟪z - x, EuclideanSpace.single i 1⟫_ℝ)) _ y := ((hA.const_mul ((4 * π)⁻¹)).mul hB).neg
    rw [this.fderiv]
    have e1 : (-(3 / 2 : ℝ) - 1) = -(5 / 2) := by norm_num
    simp only [neg_apply, add_apply, smul_apply, innerSL_apply_apply, smul_eq_mul, e1,
      EuclideanSpace.inner_single_right]
    simp
    ring
  simp only [hfun, hder]
  have hsq : ∑ i : Fin 3, (y - x) i * (y - x) i = ‖y - x‖ ^ 2 := by
    rw [EuclideanSpace.norm_sq_eq]; simp [sq]
  have hrp : (‖y - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ)) =
      (‖y - x‖ ^ 2 + s) * (‖y - x‖ ^ 2 + s) ^ (-(5 / 2 : ℝ)) := by
    rw [← Real.rpow_one_add' (hpos y).le (by norm_num)]; norm_num
  rw [Fin.sum_univ_three] at hsq ⊢
  rw [hrp]
  linear_combination (3 * (4 * π)⁻¹ * (‖y - x‖ ^ 2 + s) ^ (-(5 / 2 : ℝ))) * hsq

#print axioms laplacian_Ψc

/-- The peak profile `η(w) = 3 / (4π (|w|² + 1)^{5/2})`. -/
noncomputable def ηpk (w : E3) : ℝ := 3 * (4 * π)⁻¹ * (‖w‖ ^ 2 + 1) ^ (-(5 / 2 : ℝ))

lemma ηpk_nonneg (w : E3) : 0 ≤ ηpk w := by unfold ηpk; positivity

#print axioms ηpk_nonneg

lemma radial_antideriv (r : ℝ) :
    HasDerivAt (fun t : ℝ => t ^ 3 / 3 * (t ^ 2 + 1) ^ (-(3 / 2 : ℝ)))
      (r ^ 2 * (r ^ 2 + 1) ^ (-(5 / 2 : ℝ))) r := by
  have hp : 0 < r ^ 2 + 1 := by positivity
  have h1 : HasDerivAt (fun t : ℝ => t ^ 3 / 3) (r ^ 2) r := by
    have := (hasDerivAt_pow 3 r).div_const 3
    convert this using 1; push_cast; ring
  have h2 : HasDerivAt (fun t : ℝ => t ^ 2 + 1) (2 * r) r := by
    have := (hasDerivAt_pow 2 r).add_const 1
    convert this using 1; push_cast; ring
  have h3 := h2.rpow_const (p := -(3 / 2 : ℝ)) (Or.inl hp.ne')
  have := h1.mul h3
  convert this using 1
  have e1 : (-(3 / 2 : ℝ) - 1) = -(5 / 2) := by norm_num
  have hrp : (r ^ 2 + 1) ^ (-(3 / 2 : ℝ)) = (r ^ 2 + 1) * (r ^ 2 + 1) ^ (-(5 / 2 : ℝ)) := by
    rw [← Real.rpow_one_add' hp.le (by norm_num)]; norm_num
  rw [e1, hrp]; ring

#print axioms radial_antideriv

lemma radial_limit :
    Filter.Tendsto (fun t : ℝ => t ^ 3 / 3 * (t ^ 2 + 1) ^ (-(3 / 2 : ℝ))) Filter.atTop (nhds (1 / 3)) := by
  have hq : Filter.Tendsto (fun t : ℝ => t ^ 2 / (t ^ 2 + 1)) Filter.atTop (nhds 1) := by
    have h0 : Filter.Tendsto (fun t : ℝ => 1 - (t ^ 2 + 1)⁻¹) Filter.atTop (nhds (1 - 0)) := by
      refine tendsto_const_nhds.sub (Filter.Tendsto.inv_tendsto_atTop ?_)
      exact Filter.tendsto_atTop_add_const_right _ _ (Filter.tendsto_pow_atTop two_ne_zero)
    rw [sub_zero] at h0
    refine h0.congr fun t => ?_
    have : 0 < t ^ 2 + 1 := by positivity
    field_simp; ring
  have hc : Filter.Tendsto (fun t : ℝ => (t ^ 2 / (t ^ 2 + 1)) ^ (3 / 2 : ℝ) / 3) Filter.atTop
      (nhds ((1 : ℝ) ^ (3 / 2 : ℝ) / 3)) :=
    ((hq.rpow_const (Or.inl one_ne_zero))).div_const 3
  rw [Real.one_rpow] at hc
  refine hc.congr' ?_
  filter_upwards [Filter.eventually_ge_atTop (0 : ℝ)] with t ht
  have hp : 0 < t ^ 2 + 1 := by positivity
  rw [Real.div_rpow (by positivity) hp.le, Real.rpow_neg hp.le]
  have : (t ^ 2) ^ (3 / 2 : ℝ) = t ^ 3 := by
    rw [← Real.rpow_natCast t 2, ← Real.rpow_mul ht]; norm_num
  rw [this]; ring

#print axioms radial_limit

lemma integral_ηpk : ∫ w : E3, ηpk w = 1 := by
  have h := integral_fun_norm_addHaar (volume : Measure E3)
    (fun r : ℝ => 3 * (4 * π)⁻¹ * (r ^ 2 + 1) ^ (-(5 / 2 : ℝ)))
  simp only [finrank_euclideanSpace_fin] at h
  unfold ηpk
  rw [h]
  have hI : ∫ y in Ioi (0 : ℝ), y ^ (3 - 1) • (3 * (4 * π)⁻¹ * (y ^ 2 + 1) ^ (-(5 / 2 : ℝ))) =
      3 * (4 * π)⁻¹ * (1 / 3) := by
    have := integral_Ioi_of_hasDerivAt_of_nonneg' (a := 0) (fun r _ => radial_antideriv r)
      (fun r _ => by positivity) radial_limit
    simp only [smul_eq_mul]
    rw [show (fun y : ℝ => y ^ (3 - 1) * (3 * (4 * π)⁻¹ * (y ^ 2 + 1) ^ (-(5 / 2 : ℝ)))) =
      fun y => 3 * (4 * π)⁻¹ * (y ^ 2 * (y ^ 2 + 1) ^ (-(5 / 2 : ℝ))) by funext y; ring]
    rw [integral_const_mul, this]
    norm_num
  rw [hI]
  simp only [Measure.real, EuclideanSpace.volume_ball_fin_three]
  rw [ENNReal.toReal_mul, ENNReal.toReal_pow, ENNReal.toReal_ofReal zero_le_one,
    ENNReal.toReal_ofReal (by positivity)]
  simp only [nsmul_eq_mul, smul_eq_mul]
  field_simp
  norm_num

#print axioms integral_ηpk

lemma ηpk_decay :
    Filter.Tendsto (fun w : E3 => ‖w‖ ^ Module.finrank ℝ E3 * ηpk w) (Bornology.cobounded E3)
      (nhds 0) := by
  simp only [finrank_euclideanSpace_fin]
  have hg : Filter.Tendsto (fun r : ℝ => r ^ 3 * (3 * (4 * π)⁻¹ * (r ^ 2 + 1) ^ (-(5 / 2 : ℝ))))
      Filter.atTop (nhds 0) := by
    have hb : Filter.Tendsto (fun r : ℝ => 3 * (4 * π)⁻¹ * r⁻¹) Filter.atTop (nhds 0) := by
      simpa using tendsto_inv_atTop_zero.const_mul (3 * (4 * π)⁻¹)
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hb ?_ ?_
    · filter_upwards [Filter.eventually_ge_atTop (0 : ℝ)] with r hr; positivity
    · filter_upwards [Filter.eventually_gt_atTop (0 : ℝ)] with r hr
      have hp : 1 ≤ r ^ 2 + 1 := by nlinarith
      have h1 : (r ^ 2 + 1) ^ (-(5 / 2 : ℝ)) ≤ (r ^ 2 + 1) ^ (-(2 : ℝ)) :=
        Real.rpow_le_rpow_of_exponent_le hp (by norm_num)
      have h2 : (r ^ 2 + 1) ^ (-(2 : ℝ)) = ((r ^ 2 + 1) ^ 2)⁻¹ := by
        rw [Real.rpow_neg (by positivity)]; norm_cast
      have h3 : r ^ 3 * ((r ^ 2 + 1) ^ 2)⁻¹ ≤ r⁻¹ := by
        rw [← div_eq_mul_inv, div_le_iff₀ (by positivity)]
        field_simp
        nlinarith [sq_nonneg r, pow_pos hr 4]
      have hk : 0 ≤ 3 * (4 * π)⁻¹ := by positivity
      calc r ^ 3 * (3 * (4 * π)⁻¹ * (r ^ 2 + 1) ^ (-(5 / 2 : ℝ)))
          = 3 * (4 * π)⁻¹ * (r ^ 3 * (r ^ 2 + 1) ^ (-(5 / 2 : ℝ))) := by ring
        _ ≤ 3 * (4 * π)⁻¹ * (r ^ 3 * ((r ^ 2 + 1) ^ 2)⁻¹) := by
          rw [← h2]; gcongr
        _ ≤ 3 * (4 * π)⁻¹ * r⁻¹ := by gcongr
  exact hg.comp tendsto_norm_cobounded_atTop

#print axioms ηpk_decay

lemma laplacian_Ψc_eq_peak {c : ℝ} (hc : 0 < c) (x y : E3) :
    Δ (Ψc (1 / c ^ 2) x) y = -(c ^ Module.finrank ℝ E3 * ηpk (c • (x - y))) := by
  rw [laplacian_Ψc (by positivity), finrank_euclideanSpace_fin, ηpk, norm_smul, norm_sub_rev x y,
    Real.norm_of_nonneg hc.le]
  have hA : 0 < ‖y - x‖ ^ 2 + 1 / c ^ 2 := by positivity
  have e : (c * ‖y - x‖) ^ 2 + 1 = c ^ 2 * (‖y - x‖ ^ 2 + 1 / c ^ 2) := by field_simp
  rw [e, Real.mul_rpow (by positivity) hA.le]
  have : (c ^ 2) ^ (-(5 / 2 : ℝ)) = (c ^ 5)⁻¹ := by
    rw [← Real.rpow_natCast c 2, ← Real.rpow_mul hc.le,
      show ((2 : ℕ) : ℝ) * -(5 / 2) = -((5 : ℕ) : ℝ) by norm_num, Real.rpow_neg hc.le,
      Real.rpow_natCast]
  rw [this]
  field_simp

#print axioms laplacian_Ψc_eq_peak

lemma integrableOn_fundSol3_ball (R : ℝ) : IntegrableOn fundSol3 (Metric.ball (0 : E3) R) := by
  have h := integrableOn_fun_norm_addHaar (volume : Measure E3) (f := fun r : ℝ => 1 / (4 * π * r))
    (r := R)
  simp only [finrank_euclideanSpace_fin] at h
  refine h.2 ?_
  have hc : IntegrableOn (fun r : ℝ => r / (4 * π)) (Ioo 0 R) :=
    ((continuous_id.div_const _).integrableOn_Icc (a := 0) (b := R)).mono_set Ioo_subset_Icc_self
  refine hc.congr_fun (fun r hr => ?_) measurableSet_Ioo
  have : r ≠ 0 := hr.1.ne'
  simp only [smul_eq_mul]
  field_simp

#print axioms integrableOn_fundSol3_ball

lemma integrableOn_fundSol3_sub_ball (x : E3) (R : ℝ) :
    IntegrableOn (fun y => fundSol3 (y - x)) (Metric.ball x R) := by
  have h := (measurePreserving_sub_right (volume : Measure E3) x).integrableOn_comp_preimage
    (MeasurableEquiv.subRight x).measurableEmbedding (f := fundSol3) (s := Metric.ball 0 R)
  have hpre : (fun y => y - x) ⁻¹' Metric.ball (0 : E3) R = Metric.ball x R := by
    ext y; simp [dist_eq_norm]
  rw [hpre] at h
  exact h.2 (integrableOn_fundSol3_ball R)

#print axioms integrableOn_fundSol3_sub_ball

lemma integrableOn_fundSol3_sub_closedBox (lo hi : Fin 3 → ℝ) (x : E3) :
    IntegrableOn (fun y => fundSol3 (y - x)) (closedBox lo hi) := by
  obtain ⟨R, hR⟩ := (isCompact_closedBox lo hi).isBounded.subset_ball x
  exact (integrableOn_fundSol3_sub_ball x R).mono_set hR

#print axioms integrableOn_fundSol3_sub_closedBox

lemma fundSol3_nonneg (z : E3) : 0 ≤ fundSol3 z := by unfold fundSol3; positivity

#print axioms fundSol3_nonneg

lemma exists_dist_wall {lo hi : Fin 3 → ℝ} {x : E3} (hx : x ∈ openBox lo hi) :
    ∃ d > 0, ∀ p, p ∉ openBox lo hi → d ≤ ‖p - x‖ := by
  obtain ⟨d, hd, hball⟩ := Metric.isOpen_iff.1 (isOpen_openBox lo hi) x hx
  refine ⟨d, hd, fun p hp => ?_⟩
  by_contra h
  rw [not_le] at h
  exact hp (hball (by rw [Metric.mem_ball, dist_eq_norm]; exact h))

#print axioms exists_dist_wall

lemma integrableOn_fund_mul {lo hi : Fin 3 → ℝ} {x : E3} (hx : x ∈ openBox lo hi) {k : E3 → ℝ}
    (hk : IntegrableOn k (closedBox lo hi)) (hkc : ContinuousOn k (openBox lo hi)) :
    IntegrableOn (fun y => fundSol3 (y - x) * k y) (closedBox lo hi) := by
  obtain ⟨d, hd, hball⟩ := Metric.isOpen_iff.1 (isOpen_openBox lo hi) x hx
  have hcb : Metric.closedBall x (d / 2) ⊆ openBox lo hi :=
    (Metric.closedBall_subset_ball (by linarith)).trans hball
  obtain ⟨M, hM⟩ := (isCompact_closedBall x (d / 2)).exists_bound_of_continuousOn (hkc.mono hcb)
  have hL := integrableOn_fundSol3_sub_closedBox lo hi x
  refine Integrable.mono' ((hL.const_mul M).add (hk.norm.const_mul (4 * π * (d / 2))⁻¹))
    (hL.aestronglyMeasurable.mul hk.aestronglyMeasurable) ?_
  refine Filter.Eventually.of_forall fun y => ?_
  have hΦ := fundSol3_nonneg (y - x)
  rw [norm_mul, Real.norm_of_nonneg hΦ]
  show _ ≤ M * fundSol3 (y - x) + (4 * π * (d / 2))⁻¹ * ‖k y‖
  by_cases hy : y ∈ Metric.closedBall x (d / 2)
  · have h1 := hM y hy
    have h2 : 0 ≤ (4 * π * (d / 2))⁻¹ * ‖k y‖ := by positivity
    calc fundSol3 (y - x) * ‖k y‖ ≤ fundSol3 (y - x) * M := by gcongr
      _ = M * fundSol3 (y - x) := by ring
      _ ≤ _ := by linarith
  · rw [Metric.mem_closedBall, dist_eq_norm, not_le] at hy
    have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM x (Metric.mem_closedBall_self (by linarith)))
    have h3 : fundSol3 (y - x) ≤ (4 * π * (d / 2))⁻¹ := by
      unfold fundSol3; rw [one_div]
      exact inv_anti₀ (by positivity) (by gcongr)
    have h4 : 0 ≤ M * fundSol3 (y - x) := mul_nonneg hM0 hΦ
    calc fundSol3 (y - x) * ‖k y‖ ≤ (4 * π * (d / 2))⁻¹ * ‖k y‖ := by gcongr
      _ ≤ _ := by linarith

#print axioms integrableOn_fund_mul

lemma face_mem_closedBox {lo hi : Fin 3 → ℝ} (i : Fin 3) {c : ℝ}
    (hc : lo i ≤ c ∧ c ≤ hi i) {y : Fin 2 → ℝ} (hy : y ∈ Icc (lo ∘ i.succAbove) (hi ∘ i.succAbove)) :
    (WithLp.toLp 2 (Fin.insertNth i c y) : E3) ∈ closedBox lo hi := by
  intro j
  by_cases hj : j = i
  · subst hj; simpa using hc
  · obtain ⟨k, rfl⟩ := Fin.exists_succAbove_eq hj
    rw [WithLp.ofLp_toLp, Fin.insertNth_apply_succAbove]
    exact ⟨hy.1 k, hy.2 k⟩

#print axioms face_mem_closedBox

lemma face_hi_mem_wall {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i) (i : Fin 3) {y : Fin 2 → ℝ}
    (hy : y ∈ Icc (lo ∘ i.succAbove) (hi ∘ i.succAbove)) :
    (WithLp.toLp 2 (Fin.insertNth i (hi i) y) : E3) ∈ closedBox lo hi \ openBox lo hi := by
  refine ⟨face_mem_closedBox i ⟨hle i, le_rfl⟩ hy, fun h => ?_⟩
  have := (h i).2
  simp at this

#print axioms face_hi_mem_wall

lemma face_lo_mem_wall {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i) (i : Fin 3) {y : Fin 2 → ℝ}
    (hy : y ∈ Icc (lo ∘ i.succAbove) (hi ∘ i.succAbove)) :
    (WithLp.toLp 2 (Fin.insertNth i (lo i) y) : E3) ∈ closedBox lo hi \ openBox lo hi := by
  refine ⟨face_mem_closedBox i ⟨le_rfl, hle i⟩ hy, fun h => ?_⟩
  have := (h i).1
  simp at this

#print axioms face_lo_mem_wall

lemma continuous_face (i : Fin 3) (c : ℝ) :
    Continuous fun y : Fin 2 → ℝ => (WithLp.toLp 2 (Fin.insertNth i c y) : E3) :=
  (PiLp.continuousLinearEquiv 2 ℝ (fun _ : Fin 3 => ℝ)).symm.continuous.comp
    (continuous_const.finInsertNth i continuous_id)

#print axioms continuous_face

lemma wallIntegral_congr {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i) {F₁ F₂ : E3 → E3 → ℝ}
    (h : ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n, F₁ p n = F₂ p n) :
    wallIntegral lo hi F₁ = wallIntegral lo hi F₂ := by
  unfold wallIntegral
  refine Finset.sum_congr rfl fun i _ => ?_
  congr 1
  · exact setIntegral_congr_fun measurableSet_Icc fun y hy => h _ (face_hi_mem_wall hle i hy) _
  · exact setIntegral_congr_fun measurableSet_Icc fun y hy => h _ (face_lo_mem_wall hle i hy) _

#print axioms wallIntegral_congr

lemma wallIntegral_tendsto {lo hi : Fin 3 → ℝ} (hle : ∀ i, lo i ≤ hi i)
    {F : ℕ → E3 → E3 → ℝ} {F₀ : E3 → E3 → ℝ} (C : ℝ)
    (hc : ∀ k (i : Fin 3), ContinuousOn (fun p => F k p (EuclideanSpace.single i 1))
      (closedBox lo hi \ openBox lo hi) ∧
      ContinuousOn (fun p => F k p (-EuclideanSpace.single i 1)) (closedBox lo hi \ openBox lo hi))
    (hb : ∀ k, ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ i : Fin 3,
      |F k p (EuclideanSpace.single i 1)| ≤ C ∧ |F k p (-EuclideanSpace.single i 1)| ≤ C)
    (hl : ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ i : Fin 3,
      Filter.Tendsto (fun k => F k p (EuclideanSpace.single i 1)) Filter.atTop
        (nhds (F₀ p (EuclideanSpace.single i 1))) ∧
      Filter.Tendsto (fun k => F k p (-EuclideanSpace.single i 1)) Filter.atTop
        (nhds (F₀ p (-EuclideanSpace.single i 1)))) :
    Filter.Tendsto (fun k => wallIntegral lo hi (F k)) Filter.atTop
      (nhds (wallIntegral lo hi F₀)) := by
  unfold wallIntegral
  refine tendsto_finsetSum _ fun i _ => ?_
  have hfin : IsFiniteMeasure (volume.restrict (Icc (lo ∘ i.succAbove) (hi ∘ i.succAbove))) := by
    rw [isFiniteMeasure_restrict]; exact (isCompact_Icc.measure_lt_top).ne
  refine Filter.Tendsto.add ?_ ?_
  · refine tendsto_integral_of_dominated_convergence (fun _ => C) (fun k => ?_)
      (integrable_const C) (fun k => ?_) ?_
    · exact ((hc k i).1.comp (continuous_face i (hi i)).continuousOn
        (fun y hy => face_hi_mem_wall hle i hy)).aestronglyMeasurable measurableSet_Icc
    · filter_upwards [ae_restrict_mem measurableSet_Icc] with y hy
      rw [Real.norm_eq_abs]; exact (hb k _ (face_hi_mem_wall hle i hy) i).1
    · filter_upwards [ae_restrict_mem measurableSet_Icc] with y hy
      exact (hl _ (face_hi_mem_wall hle i hy) i).1
  · refine tendsto_integral_of_dominated_convergence (fun _ => C) (fun k => ?_)
      (integrable_const C) (fun k => ?_) ?_
    · exact ((hc k i).2.comp (continuous_face i (lo i)).continuousOn
        (fun y hy => face_lo_mem_wall hle i hy)).aestronglyMeasurable measurableSet_Icc
    · filter_upwards [ae_restrict_mem measurableSet_Icc] with y hy
      rw [Real.norm_eq_abs]; exact (hb k _ (face_lo_mem_wall hle i hy) i).2
    · filter_upwards [ae_restrict_mem measurableSet_Icc] with y hy
      exact (hl _ (face_lo_mem_wall hle i hy) i).2

#print axioms wallIntegral_tendsto

lemma Ψc_nonneg {s : ℝ} (hs : 0 ≤ s) (x y : E3) : 0 ≤ Ψc s x y := by unfold Ψc; positivity

#print axioms Ψc_nonneg

lemma Ψc_le_fund {s : ℝ} (hs : 0 ≤ s) {x y : E3} (hy : y ≠ x) : Ψc s x y ≤ fundSol3 (y - x) := by
  rw [← Ψc_zero_eq hy]
  unfold Ψc
  have hn : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hy)
  gcongr (4 * π)⁻¹ * ?_
  exact Real.rpow_le_rpow_of_nonpos (by positivity) (by linarith) (by norm_num)

#print axioms Ψc_le_fund

lemma Ψc_tendsto {x y : E3} (hy : y ≠ x) {s : ℕ → ℝ} (hs : Filter.Tendsto s Filter.atTop (nhds 0)) :
    Filter.Tendsto (fun k => Ψc (s k) x y) Filter.atTop (nhds (fundSol3 (y - x))) := by
  rw [← Ψc_zero_eq hy]
  have hn : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hy)
  unfold Ψc
  refine Filter.Tendsto.const_mul _ ?_
  refine Filter.Tendsto.rpow_const ?_ (Or.inl (by rw [add_zero]; exact (pow_pos hn 2).ne'))
  simpa using (tendsto_const_nhds (x := ‖y - x‖ ^ 2)).add hs

#print axioms Ψc_tendsto

lemma fderiv_Ψc_tendsto {x p : E3} (hp : p ≠ x) {s : ℕ → ℝ} (hs0 : ∀ k, 0 ≤ s k)
    (hs : Filter.Tendsto s Filter.atTop (nhds 0)) (n : E3) :
    Filter.Tendsto (fun k => fderiv ℝ (Ψc (s k) x) p n) Filter.atTop
      (nhds (fderiv ℝ (Ψc 0 x) p n)) := by
  have hn : 0 < ‖p - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hp)
  have h0 : 0 < ‖p - x‖ ^ 2 + 0 := by rw [add_zero]; exact pow_pos hn 2
  rw [fderiv_Ψc_apply h0]
  have : (fun k => fderiv ℝ (Ψc (s k) x) p n) = fun k =>
      -((4 * π)⁻¹ * (‖p - x‖ ^ 2 + s k) ^ (-(3 / 2 : ℝ)) * ⟪p - x, n⟫_ℝ) := by
    funext k; exact fderiv_Ψc_apply (by have := hs0 k; positivity) n
  rw [this]
  refine Filter.Tendsto.neg (Filter.Tendsto.mul_const _ (Filter.Tendsto.const_mul _ ?_))
  refine Filter.Tendsto.rpow_const ?_ (Or.inl h0.ne')
  exact (tendsto_const_nhds (x := ‖p - x‖ ^ 2)).add hs

#print axioms fderiv_Ψc_tendsto

lemma abs_fderiv_Ψc_le {s : ℝ} (hs : 0 ≤ s) {x p : E3} {d R : ℝ} (hd : 0 < d) (hdp : d ≤ ‖p - x‖)
    (hR : ‖p - x‖ ≤ R) (n : E3) :
    |fderiv ℝ (Ψc s x) p n| ≤ (4 * π)⁻¹ * (d ^ 2) ^ (-(3 / 2 : ℝ)) * R * ‖n‖ := by
  have hpos : 0 < ‖p - x‖ ^ 2 + s := by
    have : 0 < ‖p - x‖ := hd.trans_le hdp
    have := pow_pos this 2
    linarith
  rw [fderiv_Ψc_apply hpos, abs_neg, abs_mul, abs_mul]
  have h1 : |(4 * π)⁻¹| = (4 * π)⁻¹ := abs_of_pos (by positivity)
  have h2 : |(‖p - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ))| ≤ (d ^ 2) ^ (-(3 / 2 : ℝ)) := by
    rw [abs_of_pos (by positivity)]
    exact Real.rpow_le_rpow_of_nonpos (by positivity) (by nlinarith) (by norm_num)
  have h3 : |⟪p - x, n⟫_ℝ| ≤ R * ‖n‖ :=
    (abs_real_inner_le_norm _ _).trans (by gcongr)
  rw [h1]
  calc (4 * π)⁻¹ * |(‖p - x‖ ^ 2 + s) ^ (-(3 / 2 : ℝ))| * |⟪p - x, n⟫_ℝ|
      ≤ (4 * π)⁻¹ * (d ^ 2) ^ (-(3 / 2 : ℝ)) * (R * ‖n‖) :=
        mul_le_mul (mul_le_mul_of_nonneg_left h2 (by positivity)) h3 (abs_nonneg _)
          (by positivity)
    _ = _ := by ring

#print axioms abs_fderiv_Ψc_le

lemma fundSol3_le_of_dist {z : E3} {d : ℝ} (hd : 0 < d) (hz : d ≤ ‖z‖) :
    fundSol3 z ≤ (4 * π * d)⁻¹ := by
  unfold fundSol3; rw [one_div]
  exact inv_anti₀ (by positivity) (by gcongr)

#print axioms fundSol3_le_of_dist

lemma ae_ne_point (x : E3) : ∀ᵐ y ∂(volume : Measure E3), y ≠ x := by
  rw [ae_iff]; simp

#print axioms ae_ne_point

lemma seq_tendsto_atTop : Filter.Tendsto (fun k : ℕ => (k : ℝ) + 1) Filter.atTop Filter.atTop :=
  Filter.tendsto_atTop_add_const_right _ _ tendsto_natCast_atTop_atTop

#print axioms seq_tendsto_atTop

lemma seq_s_tendsto : Filter.Tendsto (fun k : ℕ => 1 / ((k : ℝ) + 1) ^ 2) Filter.atTop (nhds 0) := by
  have := (Filter.tendsto_pow_atTop (two_ne_zero)).comp seq_tendsto_atTop
  refine this.inv_tendsto_atTop.congr fun k => ?_
  simp

#print axioms seq_s_tendsto

lemma peak_tendsto {lo hi : Fin 3 → ℝ} {x : E3} (hx : x ∈ openBox lo hi) {g : E3 → ℝ}
    (hg : IntegrableOn g (closedBox lo hi)) (hgc : ContinuousAt g x) :
    Filter.Tendsto (fun k : ℕ => ∫ y in closedBox lo hi, g y * Δ (Ψc (1 / ((k : ℝ) + 1) ^ 2) x) y)
      Filter.atTop (nhds (-g x)) := by
  have hmeas := (isClosed_closedBox lo hi).measurableSet
  have hgi : Integrable ((closedBox lo hi).indicator g) :=
    (integrable_indicator_iff hmeas).2 hg
  have hgx : ContinuousAt ((closedBox lo hi).indicator g) x := by
    refine hgc.congr ?_
    filter_upwards [(isOpen_openBox lo hi).mem_nhds hx] with y hy
    exact (indicator_of_mem (openBox_subset_closedBox lo hi hy) g).symm
  have key := (tendsto_integral_comp_smul_smul_of_integrable' ηpk_nonneg integral_ηpk ηpk_decay
    hgi hgx).comp seq_tendsto_atTop
  rw [indicator_of_mem (openBox_subset_closedBox lo hi hx)] at key
  have key' := key.neg
  refine key'.congr fun k => ?_
  simp only [Function.comp_apply]
  rw [← integral_neg, ← integral_indicator hmeas]
  congr 1
  funext y
  by_cases hy : y ∈ closedBox lo hi
  · rw [indicator_of_mem hy, indicator_of_mem hy, laplacian_Ψc_eq_peak (by positivity), smul_eq_mul]
    ring
  · rw [indicator_of_notMem hy, indicator_of_notMem hy, smul_zero, neg_zero]

#print axioms peak_tendsto

lemma norm_single_pm (i : Fin 3) :
    ‖(EuclideanSpace.single i (1 : ℝ) : E3)‖ = 1 ∧ ‖(-EuclideanSpace.single i (1 : ℝ) : E3)‖ = 1 := by
  simp [PiLp.norm_single]

#print axioms norm_single_pm

lemma core_identity {lo hi : Fin 3 → ℝ} (hlh : ∀ i, lo i < hi i) {G : E3 → E3 → ℝ}
    (hG : IsGreenFunctionBox lo hi G) {x : E3} (hx : x ∈ openBox lo hi) {w : E3 → ℝ}
    (hw2 : ContDiffOn ℝ 2 w (openBox lo hi)) (hw1 : ContDiffOn ℝ 1 w (closedBox lo hi))
    (hΔw : IntegrableOn (Δ w) (closedBox lo hi)) :
    w x = -(∫ y in closedBox lo hi, G y x * Δ w y) -
      wallIntegral lo hi (fun p n => w p * fderiv ℝ (fun z => G z x) p n) := by
  have hle : ∀ i, lo i ≤ hi i := fun i => (hlh i).le
  obtain ⟨h, ⟨U, hU, hsub, hh⟩, hharm, hGeq, hGwall⟩ := hG x hx
  have hmeas := (isClosed_closedBox lo hi).measurableSet
  have hcpt := isCompact_closedBox lo hi
  have hob := openBox_subset_closedBox lo hi
  have hud : UniqueDiffOn ℝ (closedBox lo hi) :=
    uniqueDiffOn_convex (convex_closedBox lo hi)
      ⟨x, interior_maximal hob (isOpen_openBox lo hi) hx⟩
  set Du := fderivWithin ℝ w (closedBox lo hi) with hDu_def
  have hDu : ContinuousOn Du (closedBox lo hi) := hw1.continuousOn_fderivWithin hud le_rfl
  have hDu' : ∀ y ∈ openBox lo hi, Du y = fderiv ℝ w y := fun y hy =>
    fderivWithin_of_mem_nhds (Filter.mem_of_superset ((isOpen_openBox lo hi).mem_nhds hy) hob)
  have hwc : ContinuousOn w (closedBox lo hi) := hw1.continuousOn
  set s : ℕ → ℝ := fun k => 1 / ((k : ℝ) + 1) ^ 2 with hs_def
  have hspos : ∀ k, 0 < s k := fun k => by positivity
  set v : ℕ → E3 → ℝ := fun k y => Ψc (s k) x y - h y with hv_def
  have hv : ∀ k, ContDiffOn ℝ 2 (v k) U := fun k => (contDiff_Ψc (hspos k) x).contDiffOn.sub hh
  -- Step 1: Green's identity for each `k`.
  have hΔv : ∀ k, ∀ y ∈ openBox lo hi, Δ (v k) y = Δ (Ψc (s k) x) y := by
    intro k y hy
    have hyU := hsub (hob hy)
    have e : v k = Ψc (s k) x - h := rfl
    rw [e, ContDiffAt.laplacian_sub (contDiff_Ψc (hspos k) x).contDiffAt
      (hh.contDiffAt (hU.mem_nhds hyU)), (hharm y hy).2.eq_of_nhds]
    simp
  have hsplit : ∀ k, (∫ y in closedBox lo hi, w y * Δ (v k) y - v k y * Δ w y) =
      (∫ y in closedBox lo hi, w y * Δ (Ψc (s k) x) y) - ∫ y in closedBox lo hi, v k y * Δ w y := by
    intro k
    have i1 : IntegrableOn (fun y => w y * Δ (v k) y) (closedBox lo hi) :=
      ContinuousOn.integrableOn_compact hcpt
        (hwc.mul ((continuousOn_laplacian hU (hv k)).mono hsub))
    have i2 : IntegrableOn (fun y => v k y * Δ w y) (closedBox lo hi) :=
      hΔw.continuousOn_mul ((hv k).continuousOn.mono hsub) hcpt
    rw [integral_sub i1 i2]
    congr 1
    refine integral_congr_ae ?_
    filter_upwards [ae_mem_openBox lo hi] with y hy
    rw [hΔv k y hy]
  have hGL : ∀ k, (∫ y in closedBox lo hi, w y * Δ (Ψc (s k) x) y) -
      (∫ y in closedBox lo hi, v k y * Δ w y) =
      wallIntegral lo hi (fun p n => w p * fderiv ℝ (v k) p n - v k p * Du p n) := by
    intro k; rw [← hsplit k]
    exact green_second_general hle Du hw2 hwc hDu hDu' hΔw hU hsub (hv k)
  -- Step 2: the volume terms.
  have hA : Filter.Tendsto (fun k => ∫ y in closedBox lo hi, w y * Δ (Ψc (s k) x) y)
      Filter.atTop (nhds (-w x)) :=
    peak_tendsto hx (hwc.integrableOn_compact hcpt)
      (hw2.continuousOn.continuousAt ((isOpen_openBox lo hi).mem_nhds hx))
  obtain ⟨Mh, hMh⟩ := hcpt.exists_bound_of_continuousOn (hh.continuousOn.mono hsub)
  have hΔwc : ContinuousOn (Δ w) (openBox lo hi) := continuousOn_laplacian (isOpen_openBox lo hi) hw2
  have hB : Filter.Tendsto (fun k => ∫ y in closedBox lo hi, v k y * Δ w y) Filter.atTop
      (nhds (∫ y in closedBox lo hi, G y x * Δ w y)) := by
    refine tendsto_integral_of_dominated_convergence
      (fun y => fundSol3 (y - x) * |Δ w y| + Mh * |Δ w y|) (fun k => ?_) ?_ (fun k => ?_) ?_
    · exact (((hv k).continuousOn.mono hsub).aestronglyMeasurable hmeas).mul
        hΔw.aestronglyMeasurable
    · exact (integrableOn_fund_mul hx hΔw.abs hΔwc.abs).add (hΔw.abs.const_mul Mh)
    · filter_upwards [ae_restrict_mem hmeas, ae_restrict_of_ae (ae_ne_point x)] with y hy hyx
      rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, ← add_mul]
      refine mul_le_mul_of_nonneg_right ?_ (abs_nonneg _)
      calc |v k y| ≤ |Ψc (s k) x y| + |h y| := abs_sub _ _
        _ ≤ fundSol3 (y - x) + Mh := by
          refine add_le_add ?_ ?_
          · rw [abs_of_nonneg (Ψc_nonneg (hspos k).le x y)]; exact Ψc_le_fund (hspos k).le hyx
          · have := hMh y hy; rwa [Real.norm_eq_abs] at this
    · filter_upwards [ae_restrict_of_ae (ae_ne_point x)] with y hyx
      rw [hGeq y hyx]
      exact ((Ψc_tendsto hyx seq_s_tendsto).sub tendsto_const_nhds).mul tendsto_const_nhds
  -- Step 3: the wall terms.
  obtain ⟨d, hd, hdist⟩ := exists_dist_wall hx
  obtain ⟨R, hR⟩ : ∃ R, ∀ p ∈ closedBox lo hi, ‖p - x‖ ≤ R := by
    obtain ⟨R, hR⟩ := hcpt.isBounded.subset_closedBall x
    exact ⟨R, fun p hp => by have := hR hp; rwa [Metric.mem_closedBall, dist_eq_norm] at this⟩
  obtain ⟨Mw, hMw⟩ := hcpt.exists_bound_of_continuousOn hwc
  obtain ⟨MD, hMD⟩ := hcpt.exists_bound_of_continuousOn hDu
  have hfh : ContinuousOn (fderiv ℝ h) U := hh.continuousOn_fderiv_of_isOpen hU (by norm_num)
  obtain ⟨Mh', hMh'⟩ := hcpt.exists_bound_of_continuousOn (hfh.mono hsub)
  have hpx : ∀ p ∈ closedBox lo hi \ openBox lo hi, p ≠ x := fun p hp hpx => hp.2 (hpx ▸ hx)
  have hhd : ∀ p ∈ U, DifferentiableAt ℝ h p := fun p hp =>
    (hh.contDiffAt (hU.mem_nhds hp)).differentiableAt (by norm_num)
  have hfd_v : ∀ k, ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n,
      fderiv ℝ (v k) p n = fderiv ℝ (Ψc (s k) x) p n - fderiv ℝ h p n := by
    intro k p hp n
    show fderiv ℝ (Ψc (s k) x - h) p n = _
    rw [fderiv_sub ((contDiff_Ψc (hspos k) x).differentiable (by norm_num) p) (hhd p (hsub hp.1))]
    rfl
  have hfd_G : ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n,
      fderiv ℝ (fun z => G z x) p n = fderiv ℝ (Ψc 0 x) p n - fderiv ℝ h p n := by
    intro p hp n
    have hp0 : 0 < ‖p - x‖ ^ 2 + 0 := by
      rw [add_zero]; exact pow_pos (norm_pos_iff.2 (sub_ne_zero.2 (hpx p hp))) 2
    have heq : (fun z => G z x) =ᶠ[nhds p] (Ψc 0 x - h) := by
      filter_upwards [isOpen_ne.mem_nhds (hpx p hp)] with z hz
      rw [hGeq z hz, Pi.sub_apply, Ψc_zero_eq hz]
    rw [heq.fderiv_eq, fderiv_sub (hasFDerivAt_Ψc hp0).differentiableAt (hhd p (hsub hp.1))]
    rfl
  set K1 : ℝ := (4 * π)⁻¹ * (d ^ 2) ^ (-(3 / 2 : ℝ)) * R with hK1
  set C : ℝ := Mw * (K1 + Mh') + ((4 * π * d)⁻¹ + Mh) * MD with hC
  have hMw0 : 0 ≤ Mw := (norm_nonneg _).trans (hMw x (hob hx))
  have hbound : ∀ k, ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n : E3, ‖n‖ = 1 →
      |w p * fderiv ℝ (v k) p n - v k p * Du p n| ≤ C := by
    intro k p hp n hn
    rw [hfd_v k p hp n]
    have h1 : |w p| ≤ Mw := by have := hMw p hp.1; rwa [Real.norm_eq_abs] at this
    have h2 : |fderiv ℝ (Ψc (s k) x) p n| ≤ K1 := by
      have := abs_fderiv_Ψc_le (hspos k).le hd (hdist p hp.2) (hR p hp.1) n
      rwa [hn, mul_one] at this
    have h3 : |fderiv ℝ h p n| ≤ Mh' := by
      have := (fderiv ℝ h p).le_opNorm n
      rw [hn, mul_one, Real.norm_eq_abs] at this
      exact this.trans (hMh' p hp.1)
    have h4 : |v k p| ≤ (4 * π * d)⁻¹ + Mh := by
      calc |v k p| ≤ |Ψc (s k) x p| + |h p| := abs_sub _ _
        _ ≤ (4 * π * d)⁻¹ + Mh := by
          refine add_le_add ?_ ?_
          · rw [abs_of_nonneg (Ψc_nonneg (hspos k).le x p)]
            exact (Ψc_le_fund (hspos k).le (hpx p hp)).trans
              (fundSol3_le_of_dist hd (hdist p hp.2))
          · have := hMh p hp.1; rwa [Real.norm_eq_abs] at this
    have h5 : |Du p n| ≤ MD := by
      have := (Du p).le_opNorm n
      rw [hn, mul_one, Real.norm_eq_abs] at this
      exact this.trans (hMD p hp.1)
    have h6 : |fderiv ℝ (Ψc (s k) x) p n - fderiv ℝ h p n| ≤ K1 + Mh' :=
      (abs_sub _ _).trans (add_le_add h2 h3)
    calc |w p * (fderiv ℝ (Ψc (s k) x) p n - fderiv ℝ h p n) - v k p * Du p n|
        ≤ |w p| * |fderiv ℝ (Ψc (s k) x) p n - fderiv ℝ h p n| + |v k p| * |Du p n| := by
          rw [← abs_mul, ← abs_mul]; exact abs_sub _ _
      _ ≤ Mw * (K1 + Mh') + ((4 * π * d)⁻¹ + Mh) * MD := by
          refine add_le_add (mul_le_mul h1 h6 (abs_nonneg _) hMw0)
            (mul_le_mul h4 h5 (abs_nonneg _) ((abs_nonneg _).trans h4))
  have hlim : ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n : E3,
      Filter.Tendsto (fun k => w p * fderiv ℝ (v k) p n - v k p * Du p n) Filter.atTop
        (nhds (w p * fderiv ℝ (fun z => G z x) p n)) := by
    intro p hp n
    have e1 : (fun k => w p * fderiv ℝ (v k) p n - v k p * Du p n) = fun k =>
        w p * (fderiv ℝ (Ψc (s k) x) p n - fderiv ℝ h p n) - (Ψc (s k) x p - h p) * Du p n := by
      funext k; rw [hfd_v k p hp n]
    rw [e1, hfd_G p hp n]
    have hv0 : fundSol3 (p - x) - h p = 0 := by rw [← hGeq p (hpx p hp)]; exact hGwall p hp
    have t1 := (fderiv_Ψc_tendsto (hpx p hp) (fun k => (hspos k).le) seq_s_tendsto n).sub
      (tendsto_const_nhds (x := fderiv ℝ h p n))
    have t2 := ((Ψc_tendsto (hpx p hp) seq_s_tendsto).sub (tendsto_const_nhds (x := h p))).mul
      (tendsto_const_nhds (x := Du p n))
    rw [hv0, zero_mul] at t2
    have := (t1.const_mul (w p)).sub t2
    rwa [sub_zero] at this
  have hcont : ∀ k (n : E3), ContinuousOn (fun p => w p * fderiv ℝ (v k) p n - v k p * Du p n)
      (closedBox lo hi \ openBox lo hi) := by
    intro k n
    have hs' : closedBox lo hi \ openBox lo hi ⊆ U := fun p hp => hsub hp.1
    refine ContinuousOn.sub ?_ ?_
    · exact (hwc.mono sdiff_subset).mul
        ((((hv k).continuousOn_fderiv_of_isOpen hU (by norm_num)).clm_apply
          continuousOn_const).mono hs')
    · exact ((hv k).continuousOn.mono hs').mul
        ((hDu.clm_apply continuousOn_const).mono sdiff_subset)
  have hW := wallIntegral_tendsto hle (F := fun k p n => w p * fderiv ℝ (v k) p n - v k p * Du p n)
    (F₀ := fun p n => w p * fderiv ℝ (fun z => G z x) p n) C
    (fun k i => ⟨hcont k _, hcont k _⟩)
    (fun k p hp i => ⟨hbound k p hp _ (norm_single_pm i).1, hbound k p hp _ (norm_single_pm i).2⟩)
    (fun p hp i => ⟨hlim p hp _, hlim p hp _⟩)
  have hL := (hA.sub hB).congr fun k => hGL k
  have := tendsto_nhds_unique hL hW
  linarith

#print axioms core_identity

lemma green_wall_deriv {lo hi : Fin 3 → ℝ} {G : E3 → E3 → ℝ} (hG : IsGreenFunctionBox lo hi G)
    {x : E3} (hx : x ∈ openBox lo hi) :
    ∃ C, (∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n : E3, ‖n‖ = 1 →
        |fderiv ℝ (fun z => G z x) p n| ≤ C) ∧
      ∀ n : E3, ContinuousOn (fun p => fderiv ℝ (fun z => G z x) p n)
        (closedBox lo hi \ openBox lo hi) := by
  obtain ⟨h, ⟨U, hU, hsub, hh⟩, -, hGeq, -⟩ := hG x hx
  have hcpt := isCompact_closedBox lo hi
  have hpx : ∀ p ∈ closedBox lo hi \ openBox lo hi, p ≠ x := fun p hp hpx => hp.2 (hpx ▸ hx)
  have hhd : ∀ p ∈ U, DifferentiableAt ℝ h p := fun p hp =>
    (hh.contDiffAt (hU.mem_nhds hp)).differentiableAt (by norm_num)
  have hp0 : ∀ p ∈ closedBox lo hi \ openBox lo hi, 0 < ‖p - x‖ ^ 2 + 0 := fun p hp => by
    rw [add_zero]; exact pow_pos (norm_pos_iff.2 (sub_ne_zero.2 (hpx p hp))) 2
  have hfd_G : ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n,
      fderiv ℝ (fun z => G z x) p n = fderiv ℝ (Ψc 0 x) p n - fderiv ℝ h p n := by
    intro p hp n
    have heq : (fun z => G z x) =ᶠ[nhds p] (Ψc 0 x - h) := by
      filter_upwards [isOpen_ne.mem_nhds (hpx p hp)] with z hz
      rw [hGeq z hz, Pi.sub_apply, Ψc_zero_eq hz]
    rw [heq.fderiv_eq, fderiv_sub (hasFDerivAt_Ψc (hp0 p hp)).differentiableAt (hhd p (hsub hp.1))]
    rfl
  obtain ⟨d, hd, hdist⟩ := exists_dist_wall hx
  obtain ⟨R, hR⟩ : ∃ R, ∀ p ∈ closedBox lo hi, ‖p - x‖ ≤ R := by
    obtain ⟨R, hR⟩ := hcpt.isBounded.subset_closedBall x
    exact ⟨R, fun p hp => by have := hR hp; rwa [Metric.mem_closedBall, dist_eq_norm] at this⟩
  have hfh : ContinuousOn (fderiv ℝ h) U := hh.continuousOn_fderiv_of_isOpen hU (by norm_num)
  obtain ⟨Mh', hMh'⟩ := hcpt.exists_bound_of_continuousOn (hfh.mono hsub)
  refine ⟨(4 * π)⁻¹ * (d ^ 2) ^ (-(3 / 2 : ℝ)) * R + Mh', fun p hp n hn => ?_, fun n => ?_⟩
  · rw [hfd_G p hp n]
    have h2 := abs_fderiv_Ψc_le le_rfl hd (hdist p hp.2) (hR p hp.1) n
    rw [hn, mul_one] at h2
    have h3 : |fderiv ℝ h p n| ≤ Mh' := by
      have := (fderiv ℝ h p).le_opNorm n
      rw [hn, mul_one, Real.norm_eq_abs] at this
      exact this.trans (hMh' p hp.1)
    exact (abs_sub _ _).trans (add_le_add h2 h3)
  · have hs' : closedBox lo hi \ openBox lo hi ⊆ U := fun p hp => hsub hp.1
    have hc : ContinuousOn (fun p : E3 => -((4 * π)⁻¹ * (‖p - x‖ ^ 2 + 0) ^ (-(3 / 2 : ℝ)) *
        ⟪p - x, n⟫_ℝ) - fderiv ℝ h p n) (closedBox lo hi \ openBox lo hi) := by
      refine ContinuousOn.sub (ContinuousOn.neg (ContinuousOn.mul (continuousOn_const.mul ?_) ?_))
        ((hfh.clm_apply continuousOn_const).mono hs')
      · exact ContinuousOn.rpow_const
          ((((continuous_id.sub continuous_const).norm.pow 2).add continuous_const).continuousOn)
          (fun p hp => Or.inl (hp0 p hp).ne')
      · exact ((continuous_id.sub continuous_const).inner continuous_const).continuousOn
    refine hc.congr fun p hp => ?_
    simp only
    rw [hfd_G p hp n, fderiv_Ψc_apply (hp0 p hp)]

#print axioms green_wall_deriv

lemma green_symm_aux {lo hi : Fin 3 → ℝ} (hlh : ∀ i, lo i < hi i) {G : E3 → E3 → ℝ}
    (hG : IsGreenFunctionBox lo hi G) {a b : E3} (ha : a ∈ openBox lo hi)
    (hb : b ∈ openBox lo hi) : G a b = G b a := by
  by_cases hab : a = b
  · rw [hab]
  have hle : ∀ i, lo i ≤ hi i := fun i => (hlh i).le
  have hmeas := (isClosed_closedBox lo hi).measurableSet
  have hcpt := isCompact_closedBox lo hi
  have hob := openBox_subset_closedBox lo hi
  obtain ⟨h, ⟨U, hU, hsub, hh⟩, hharm, hGeq, hGwall⟩ := hG b hb
  obtain ⟨ha', ⟨Ua, hUa, hsuba, hha⟩, -, hGeqa, -⟩ := hG a ha
  set s : ℕ → ℝ := fun k => 1 / ((k : ℝ) + 1) ^ 2 with hs_def
  have hspos : ∀ k, 0 < s k := fun k => by positivity
  set w : ℕ → E3 → ℝ := fun k y => Ψc (s k) b y - h y with hw_def
  have hw : ∀ k, ContDiffOn ℝ 2 (w k) U := fun k => (contDiff_Ψc (hspos k) b).contDiffOn.sub hh
  have hcore : ∀ k, w k a = -(∫ y in closedBox lo hi, G y a * Δ (w k) y) -
      wallIntegral lo hi (fun p n => w k p * fderiv ℝ (fun z => G z a) p n) := fun k =>
    core_identity hlh hG ha ((hw k).mono (hob.trans hsub))
      (((hw k).of_le (by norm_num)).mono hsub)
      (ContinuousOn.integrableOn_compact hcpt ((continuousOn_laplacian hU (hw k)).mono hsub))
  -- the value at `a`
  have hL : Filter.Tendsto (fun k => w k a) Filter.atTop (nhds (G a b)) := by
    rw [hGeq a hab]
    exact (Ψc_tendsto hab seq_s_tendsto).sub tendsto_const_nhds
  -- the volume term
  have hba : b ≠ a := Ne.symm hab
  have hGi : IntegrableOn (fun y => G y a) (closedBox lo hi) := by
    refine ((integrableOn_fundSol3_sub_closedBox lo hi a).sub
      ((hha.continuousOn.mono hsuba).integrableOn_compact hcpt)).congr_fun_ae ?_
    filter_upwards [ae_restrict_of_ae (ae_ne_point a)] with y hy
    rw [hGeqa y hy]; rfl
  have hGc : ContinuousAt (fun y => G y a) b := by
    have hb0 : 0 < ‖b - a‖ ^ 2 + 0 := by
      rw [add_zero]; exact pow_pos (norm_pos_iff.2 (sub_ne_zero.2 hba)) 2
    have h1 : ContinuousAt (fun y => Ψc 0 a y - ha' y) b :=
      (hasFDerivAt_Ψc hb0).continuousAt.sub
        (hha.continuousOn.continuousAt (hUa.mem_nhds (hsuba (hob hb))))
    refine h1.congr ?_
    filter_upwards [isOpen_ne.mem_nhds hba] with y hy
    rw [hGeqa y hy, Ψc_zero_eq hy]
  have hV : Filter.Tendsto (fun k => ∫ y in closedBox lo hi, G y a * Δ (w k) y) Filter.atTop
      (nhds (-G b a)) := by
    refine (peak_tendsto hb hGi hGc).congr fun k => ?_
    refine integral_congr_ae ?_
    filter_upwards [ae_mem_openBox lo hi] with y hy
    have hyU := hsub (hob hy)
    have e : w k = Ψc (s k) b - h := rfl
    rw [e, ContDiffAt.laplacian_sub (contDiff_Ψc (hspos k) b).contDiffAt
      (hh.contDiffAt (hU.mem_nhds hyU)), (hharm y hy).2.eq_of_nhds]
    simp only [Pi.zero_apply, sub_zero]
    rfl
  -- the wall term
  obtain ⟨C₁, hC₁, hcG⟩ := green_wall_deriv hG ha
  obtain ⟨d, hd, hdist⟩ := exists_dist_wall hb
  obtain ⟨Mh, hMh⟩ := hcpt.exists_bound_of_continuousOn (hh.continuousOn.mono hsub)
  have hpb : ∀ p ∈ closedBox lo hi \ openBox lo hi, p ≠ b := fun p hp hpx => hp.2 (hpx ▸ hb)
  have hwb : ∀ k, ∀ p ∈ closedBox lo hi \ openBox lo hi, |w k p| ≤ (4 * π * d)⁻¹ + Mh := by
    intro k p hp
    calc |w k p| ≤ |Ψc (s k) b p| + |h p| := abs_sub _ _
      _ ≤ (4 * π * d)⁻¹ + Mh := by
        refine add_le_add ?_ ?_
        · rw [abs_of_nonneg (Ψc_nonneg (hspos k).le b p)]
          exact (Ψc_le_fund (hspos k).le (hpb p hp)).trans (fundSol3_le_of_dist hd (hdist p hp.2))
        · have := hMh p hp.1; rwa [Real.norm_eq_abs] at this
  have hbound : ∀ k, ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n : E3, ‖n‖ = 1 →
      |w k p * fderiv ℝ (fun z => G z a) p n| ≤ ((4 * π * d)⁻¹ + Mh) * C₁ := by
    intro k p hp n hn
    rw [abs_mul]
    exact mul_le_mul (hwb k p hp) (hC₁ p hp n hn) (abs_nonneg _)
      ((abs_nonneg _).trans (hwb k p hp))
  have hlim : ∀ p ∈ closedBox lo hi \ openBox lo hi, ∀ n : E3,
      Filter.Tendsto (fun k => w k p * fderiv ℝ (fun z => G z a) p n) Filter.atTop
        (nhds ((fun _ _ => (0 : ℝ)) p n)) := by
    intro p hp n
    have hv0 : fundSol3 (p - b) - h p = 0 := by rw [← hGeq p (hpb p hp)]; exact hGwall p hp
    have t := ((Ψc_tendsto (hpb p hp) seq_s_tendsto).sub (tendsto_const_nhds (x := h p))).mul
      (tendsto_const_nhds (x := fderiv ℝ (fun z => G z a) p n))
    rw [hv0, zero_mul] at t
    exact t
  have hcont : ∀ k (n : E3), ContinuousOn (fun p => w k p * fderiv ℝ (fun z => G z a) p n)
      (closedBox lo hi \ openBox lo hi) := fun k n =>
    ((hw k).continuousOn.mono fun p (hp : p ∈ closedBox lo hi \ openBox lo hi) => hsub hp.1).mul
      (hcG n)
  have hW := wallIntegral_tendsto hle (F := fun k p n => w k p * fderiv ℝ (fun z => G z a) p n)
    (F₀ := fun _ _ => (0 : ℝ)) (((4 * π * d)⁻¹ + Mh) * C₁)
    (fun k i => ⟨hcont k _, hcont k _⟩)
    (fun k p hp i => ⟨hbound k p hp _ (norm_single_pm i).1, hbound k p hp _ (norm_single_pm i).2⟩)
    (fun p hp i => ⟨hlim p hp _, hlim p hp _⟩)
  have hW0 : wallIntegral lo hi (fun _ _ => (0 : ℝ)) = 0 := by simp [wallIntegral]
  rw [hW0] at hW
  have hR := (hV.neg.sub hW).congr fun k => (hcore k).symm
  have := tendsto_nhds_unique hL hR
  linarith

#print axioms green_symm_aux

/-- **The representation formula.** Let `u` be a classical solution of `−Δu = f` inside the box
with wall values `u = g`: two continuous derivatives inside, and continuous with continuous first
derivatives up to the walls; the source `f` is integrable over the box. Let `G` be the box's
Green's function. Then at every inside point `x`,
`u(x) = ∫_Ω G(x, y) f(y) dV_y − ∮_{∂Ω} g(y) ∂G/∂n_y dS_y`:
every source weighted by its poke response at `x`, plus every wall temperature weighted by how
steeply the poke response leaves the box there. The wall slope is the outward slope at the wall
point `y` of the poke response `z ↦ G(z, x)` with its pole at `x`, which by the symmetry theorem
is the response `G(x, ·)` read the other way round. -/
theorem representation_formula_box {lo hi : Fin 3 → ℝ} (hlh : ∀ i, lo i < hi i)
    {G : EuclideanSpace ℝ (Fin 3) → EuclideanSpace ℝ (Fin 3) → ℝ}
    (hG : IsGreenFunctionBox lo hi G)
    {u f g : EuclideanSpace ℝ (Fin 3) → ℝ}
    (hu2 : ContDiffOn ℝ 2 u (openBox lo hi)) (hu1 : ContDiffOn ℝ 1 u (closedBox lo hi))
    (hf : ∀ x ∈ openBox lo hi, -Δ u x = f x) (hfi : IntegrableOn f (closedBox lo hi))
    (hg : ∀ p ∈ closedBox lo hi \ openBox lo hi, u p = g p)
    {x : EuclideanSpace ℝ (Fin 3)} (hx : x ∈ openBox lo hi) :
    u x = (∫ y in closedBox lo hi, G x y * f y) -
      wallIntegral lo hi (fun p n => g p * fderiv ℝ (fun z => G z x) p n) := by
  have hle : ∀ i, lo i ≤ hi i := fun i => (hlh i).le
  have hΔu : IntegrableOn (Δ u) (closedBox lo hi) := by
    refine hfi.neg.congr_fun_ae ?_
    filter_upwards [ae_mem_openBox lo hi] with y hy
    rw [Pi.neg_apply, ← hf y hy, neg_neg]
  rw [core_identity hlh hG hx hu2 hu1 hΔu]
  congr 1
  · rw [← integral_neg]
    refine integral_congr_ae ?_
    filter_upwards [ae_mem_openBox lo hi] with y hy
    rw [green_symm_aux hlh hG hy hx, ← hf y hy]
    simp
  · exact wallIntegral_congr hle fun p hp n => by rw [hg p hp]

/-- **The Green's function is symmetric.** For any two inside points `a` and `b`,
`G(a, b) = G(b, a)`: a heater at `a` read at `b` gives the same rise as a heater at `b` read at
`a`. -/
theorem greens_function_symmetric {lo hi : Fin 3 → ℝ} (hlh : ∀ i, lo i < hi i)
    {G : EuclideanSpace ℝ (Fin 3) → EuclideanSpace ℝ (Fin 3) → ℝ}
    (hG : IsGreenFunctionBox lo hi G)
    {a b : EuclideanSpace ℝ (Fin 3)} (ha : a ∈ openBox lo hi) (hb : b ∈ openBox lo hi) :
    G a b = G b a := by
  exact green_symm_aux hlh hG ha hb

/-- **Green's first and second identities.** Let `u` and `v` have two continuous derivatives on
an open set holding the closed box. Then
`∫_Ω (v Δu + ∇v · ∇u) dV = ∮_{∂Ω} v ∂u/∂n dS` and
`∫_Ω (u Δv − v Δu) dV = ∮_{∂Ω} (u ∂v/∂n − v ∂u/∂n) dS`,
with `∂u/∂n` the slope of `u` along the outward normal. -/
theorem greens_first_and_second_identities {lo hi : Fin 3 → ℝ} (hlh : ∀ i, lo i ≤ hi i)
    {u v : EuclideanSpace ℝ (Fin 3) → ℝ}
    (hu : ∃ U : Set (EuclideanSpace ℝ (Fin 3)), IsOpen U ∧ closedBox lo hi ⊆ U ∧ ContDiffOn ℝ 2 u U)
    (hv : ∃ U : Set (EuclideanSpace ℝ (Fin 3)), IsOpen U ∧ closedBox lo hi ⊆ U ∧ ContDiffOn ℝ 2 v U) :
    (∫ x in closedBox lo hi, v x * Δ u x + ⟪gradient v x, gradient u x⟫_ℝ) =
        wallIntegral lo hi (fun p n => v p * fderiv ℝ u p n) ∧
      (∫ x in closedBox lo hi, u x * Δ v x - v x * Δ u x) =
        wallIntegral lo hi (fun p n => u p * fderiv ℝ v p n - v p * fderiv ℝ u p n) := by
  obtain ⟨U₁, hU₁, hs₁, hu₁⟩ := hu
  obtain ⟨U₂, hU₂, hs₂, hv₂⟩ := hv
  have hU := hU₁.inter hU₂
  have hs : closedBox lo hi ⊆ U₁ ∩ U₂ := subset_inter hs₁ hs₂
  have hu' := hu₁.mono (inter_subset_left : U₁ ∩ U₂ ⊆ U₁)
  have hv' := hv₂.mono (inter_subset_right : U₁ ∩ U₂ ⊆ U₂)
  refine ⟨green_first_box hlh hU hs hu' hv', ?_⟩
  refine green_second_general hlh (fderiv ℝ u) (hu'.mono ((openBox_subset_closedBox lo hi).trans hs))
    (hu'.continuousOn.mono hs) ((hu'.continuousOn_fderiv_of_isOpen hU (by norm_num)).mono hs)
    (fun _ _ => rfl) ?_ hU hs hv'
  exact ContinuousOn.integrableOn_compact (isCompact_closedBox lo hi)
    ((continuousOn_laplacian hU hu').mono hs)

/-! The card's exact numbers (unit cube, temperatures in °C, lengths in m). -/

-- At the centre the six faces weigh the same and add to 1, so each weighs 1/6; walls alone give
-- 80 × 1/6 + 20 × 5/6 = 20 + 60/6 = 30 °C.
example : (6 : ℚ) * (1 / 6) = 1 ∧ (80 : ℚ) * (1 / 6) + 20 * (5 / 6) = 30 ∧
    (20 : ℚ) + 60 / 6 = 30 := by norm_num

-- Heater at (0.2, 0.3, 0.4), sensor at (0.5, 0.5, 0.8): squared distance 0.29 m²;
-- Q/k = 20 W / 1.4 W/(m·K) = 100/7 K·m.
example : ((5 : ℚ) / 10 - 2 / 10) ^ 2 + (5 / 10 - 3 / 10) ^ 2 + (8 / 10 - 4 / 10) ^ 2 = 29 / 100 ∧
    (20 : ℚ) / (14 / 10) = 100 / 7 := by norm_num

-- First identity on u = x²y + z, v = xyz + y²: inside the integrand is
-- 4xy²z + 2y³ + x³z + 2x²y + xy, whose integral over the unit cube is 37/24 (1.541667).
example : (4 : ℚ) * (1 / 2 * (1 / 3) * (1 / 2)) + 2 * (1 / 4) + 1 / 4 * (1 / 2) +
    2 * (1 / 3 * (1 / 2)) + 1 / 2 * (1 / 2) = 37 / 24 := by norm_num

-- Second identity: u Δv − v Δu = 2x²y + 2z − 2xy²z − 2y³, integral 2/3 (0.666667).
example : (2 : ℚ) * (1 / 3 * (1 / 2)) + 2 * (1 / 2) - 2 * (1 / 2 * (1 / 3) * (1 / 2)) -
    2 * (1 / 4) = 2 / 3 := by norm_num

#print axioms representation_formula_box
#print axioms greens_function_symmetric
#print axioms greens_first_and_second_identities
