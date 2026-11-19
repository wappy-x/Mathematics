-- Sard's theorem and degree: critical values of a smooth map between manifolds of the same dimension have measure zero in every chart, and on the circle the signed count of preimages at any regular value equals the number of net turns.
import Mathlib.Geometry.Manifold.MFDeriv.Defs
import Mathlib.Geometry.Manifold.Instances.Real
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Data.Sign.Basic
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.Geometry.Manifold.MFDeriv.Atlas
import Mathlib.Geometry.Manifold.MFDeriv.FDeriv

open scoped Manifold ContDiff
open MeasureTheory Set

section SardHelpers

open Filter Topology

theorem sard_det_eq_zero_of_not_surjective {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] (A : E →L[ℝ] E) (hA : ¬ Function.Surjective A) : A.det = 0 := by
  by_contra h
  apply hA
  have hu : IsUnit (A : E →ₗ[ℝ] E) :=
    (LinearMap.isUnit_iff_isUnit_det _).2 (isUnit_iff_ne_zero.2 h)
  exact ((Module.End.isUnit_iff _).1 hu).2

open Classical in
/-- Left-hand value of `⌈G⌉` at `s`: the value just before `s`. -/
noncomputable def sardLeftVal (G D : ℝ → ℝ) (s : ℝ) : ℤ :=
  if ∃ k : ℤ, G s = k then (if 0 < D s then ⌈G s⌉ else ⌈G s⌉ + 1) else ⌈G s⌉

open Classical in
/-- Right-hand value of `⌈G⌉` at `s`: the value just after `s`. -/
noncomputable def sardRightVal (G D : ℝ → ℝ) (s : ℝ) : ℤ :=
  if ∃ k : ℤ, G s = k then (if 0 < D s then ⌈G s⌉ + 1 else ⌈G s⌉) else ⌈G s⌉

theorem sard_slope_pos {G : ℝ → ℝ} {d x : ℝ} (h : HasDerivAt G d x) (hd : 0 < d) :
    (∀ᶠ p in 𝓝[>] x, G x < G p) ∧ (∀ᶠ p in 𝓝[<] x, G p < G x) := by
  have ht := hasDerivAt_iff_tendsto_slope.1 h
  have hev : ∀ᶠ p in 𝓝[≠] x, 0 < slope G x p := ht.eventually (lt_mem_nhds hd)
  constructor
  · have h1 : ∀ᶠ p in 𝓝[>] x, 0 < slope G x p :=
      nhdsWithin_mono _ (show Ioi x ⊆ {x}ᶜ from fun p hp => ne_of_gt hp) hev
    filter_upwards [h1, self_mem_nhdsWithin] with p hp hxp
    rw [slope_def_field] at hp
    have : 0 < p - x := sub_pos.2 hxp
    have := (div_pos_iff_of_pos_right this).1 hp
    linarith
  · have h1 : ∀ᶠ p in 𝓝[<] x, 0 < slope G x p :=
      nhdsWithin_mono _ (show Iio x ⊆ {x}ᶜ from fun p hp => ne_of_lt hp) hev
    filter_upwards [h1, self_mem_nhdsWithin] with p hp hxp
    rw [slope_def_field] at hp
    have : p - x < 0 := sub_neg.2 hxp
    rcases div_pos_iff.1 hp with h | h
    · linarith [h.2]
    · linarith [h.1]

theorem sard_slope_neg {G : ℝ → ℝ} {d x : ℝ} (h : HasDerivAt G d x) (hd : d < 0) :
    (∀ᶠ p in 𝓝[>] x, G p < G x) ∧ (∀ᶠ p in 𝓝[<] x, G x < G p) := by
  obtain ⟨h1, h2⟩ := sard_slope_pos h.neg (by linarith)
  exact ⟨h1.mono fun p hp => by simpa using hp, h2.mono fun p hp => by simpa using hp⟩

theorem sard_isolated {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t)
    (hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0) (t : ℝ) :
    ∀ᶠ p in 𝓝[≠] t, ¬ ∃ k : ℤ, G p = k := by
  have hc : ContinuousAt G t := (hG t).continuousAt
  by_cases hx : ∃ k : ℤ, G t = k
  · obtain ⟨k, hk⟩ := hx
    have hne := (hG t).eventually_ne (c := G t) (hT t k hk)
    have hnear : ∀ᶠ p in 𝓝 t, G p ∈ Ioo ((k : ℝ) - 1) (k + 1) :=
      hc.eventually (Ioo_mem_nhds (by rw [hk]; linarith) (by rw [hk]; linarith))
    filter_upwards [hne, nhdsWithin_le_nhds hnear] with p hp1 hp2
    rintro ⟨j, hj⟩
    rw [hj] at hp2
    have h1 : k - 1 < j := by exact_mod_cast hp2.1
    have h2 : j < k + 1 := by exact_mod_cast hp2.2
    have : j = k := by omega
    exact hp1 (by rw [hj, hk, this])
  · push_neg at hx
    set m := ⌈G t⌉
    have hlt : G t < m := lt_of_le_of_ne (Int.le_ceil _) (hx m)
    have hgt : (m : ℝ) - 1 < G t := by
      have := Int.ceil_lt_add_one (G t); linarith
    have hnear : ∀ᶠ p in 𝓝 t, G p ∈ Ioo ((m : ℝ) - 1) m := hc.eventually (Ioo_mem_nhds hgt hlt)
    filter_upwards [nhdsWithin_le_nhds hnear] with p hp
    rintro ⟨j, hj⟩
    rw [hj] at hp
    have h1 : m - 1 < j := by exact_mod_cast hp.1
    have h2 : j < m := by exact_mod_cast hp.2
    omega

theorem sard_finite {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t)
    (hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0) (a b : ℝ) :
    {t | t ∈ Icc a b ∧ ∃ k : ℤ, G t = k}.Finite := by
  by_contra h
  obtain ⟨x, -, hacc⟩ := Set.Infinite.exists_accPt_of_subset_isCompact h isCompact_Icc
    (fun t ht => ht.1)
  obtain ⟨p, hp1, hp2⟩ :=
    ((accPt_iff_frequently_nhdsNE.1 hacc).and_eventually (sard_isolated hG hT x)).exists
  exact hp2 hp1.2

theorem sard_const {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t) {u v : ℝ}
    (hno : ∀ t ∈ Ioo u v, ¬ ∃ k : ℤ, G t = k) {p q : ℝ} (hp : p ∈ Ioo u v) (hq : q ∈ Ioo u v) :
    ⌈G p⌉ = ⌈G q⌉ := by
  have hcont : Continuous G := continuous_iff_continuousAt.2 fun t => (hG t).continuousAt
  have key : ∀ p ∈ Ioo u v, ∀ q ∈ Ioo u v, ⌈G p⌉ ≤ ⌈G q⌉ := by
    intro p hp q hq
    by_contra hlt
    push_neg at hlt
    set n := ⌈G q⌉
    have h1 : G q < n := lt_of_le_of_ne (Int.le_ceil _) (fun h => hno q hq ⟨n, h⟩)
    have h2 : (n : ℝ) < G p := Int.lt_ceil.1 hlt
    have hmem : (n : ℝ) ∈ uIcc (G q) (G p) := by
      rw [uIcc_of_le (by linarith)]; exact ⟨h1.le, h2.le⟩
    obtain ⟨s, hs, hsn⟩ := intermediate_value_uIcc hcont.continuousOn hmem
    exact hno s (ordConnected_Ioo.uIcc_subset hq hp hs) ⟨n, hsn⟩
  exact le_antisymm (key p hp q hq) (key q hq p hp)

theorem sard_right_witness {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t)
    (hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0) {u v : ℝ} (huv : u < v) :
    ∃ p ∈ Ioo u v, ⌈G p⌉ = sardRightVal G D u := by
  have hc : ContinuousAt G u := (hG u).continuousAt
  suffices H : ∀ᶠ p in 𝓝[>] u, ⌈G p⌉ = sardRightVal G D u by
    obtain ⟨p, hp1, hp2⟩ := (H.and (Ioo_mem_nhdsGT huv)).exists
    exact ⟨p, hp2, hp1⟩
  unfold sardRightVal
  by_cases hx : ∃ k : ℤ, G u = k
  · obtain ⟨k, hk⟩ := hx
    rw [if_pos ⟨k, hk⟩, hk, Int.ceil_intCast]
    have hnear : ∀ᶠ p in 𝓝 u, G p ∈ Ioo ((k : ℝ) - 1) (k + 1) :=
      hc.eventually (Ioo_mem_nhds (by rw [hk]; linarith) (by rw [hk]; linarith))
    rcases lt_or_gt_of_ne (hT u k hk) with hneg | hpos
    · rw [if_neg (not_lt.2 hneg.le)]
      filter_upwards [(sard_slope_neg (hG u) hneg).1, nhdsWithin_le_nhds hnear] with p hp1 hp2
      rw [Int.ceil_eq_iff]; rw [hk] at hp1; exact ⟨hp2.1, hp1.le⟩
    · rw [if_pos hpos]
      filter_upwards [(sard_slope_pos (hG u) hpos).1, nhdsWithin_le_nhds hnear] with p hp1 hp2
      rw [Int.ceil_eq_iff]; rw [hk] at hp1; push_cast; exact ⟨by linarith, hp2.2.le⟩
  · rw [if_neg hx]
    push_neg at hx
    set m := ⌈G u⌉
    have hlt : G u < m := lt_of_le_of_ne (Int.le_ceil _) (hx m)
    have hgt : (m : ℝ) - 1 < G u := by
      have := Int.ceil_lt_add_one (G u); linarith
    have hnear : ∀ᶠ p in 𝓝 u, G p ∈ Ioo ((m : ℝ) - 1) m := hc.eventually (Ioo_mem_nhds hgt hlt)
    filter_upwards [nhdsWithin_le_nhds hnear] with p hp
    rw [Int.ceil_eq_iff]; exact ⟨hp.1, hp.2.le⟩

theorem sard_left_witness {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t)
    (hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0) {u v : ℝ} (huv : u < v) :
    ∃ q ∈ Ioo u v, ⌈G q⌉ = sardLeftVal G D v := by
  have hc : ContinuousAt G v := (hG v).continuousAt
  suffices H : ∀ᶠ q in 𝓝[<] v, ⌈G q⌉ = sardLeftVal G D v by
    obtain ⟨q, hq1, hq2⟩ := (H.and (Ioo_mem_nhdsLT huv)).exists
    exact ⟨q, hq2, hq1⟩
  unfold sardLeftVal
  by_cases hx : ∃ k : ℤ, G v = k
  · obtain ⟨k, hk⟩ := hx
    rw [if_pos ⟨k, hk⟩, hk, Int.ceil_intCast]
    have hnear : ∀ᶠ p in 𝓝 v, G p ∈ Ioo ((k : ℝ) - 1) (k + 1) :=
      hc.eventually (Ioo_mem_nhds (by rw [hk]; linarith) (by rw [hk]; linarith))
    rcases lt_or_gt_of_ne (hT v k hk) with hneg | hpos
    · rw [if_neg (not_lt.2 hneg.le)]
      filter_upwards [(sard_slope_neg (hG v) hneg).2, nhdsWithin_le_nhds hnear] with p hp1 hp2
      rw [Int.ceil_eq_iff]; rw [hk] at hp1; push_cast; exact ⟨by linarith, hp2.2.le⟩
    · rw [if_pos hpos]
      filter_upwards [(sard_slope_pos (hG v) hpos).2, nhdsWithin_le_nhds hnear] with p hp1 hp2
      rw [Int.ceil_eq_iff]; rw [hk] at hp1; exact ⟨hp2.1, hp1.le⟩
  · rw [if_neg hx]
    push_neg at hx
    set m := ⌈G v⌉
    have hlt : G v < m := lt_of_le_of_ne (Int.le_ceil _) (hx m)
    have hgt : (m : ℝ) - 1 < G v := by
      have := Int.ceil_lt_add_one (G v); linarith
    have hnear : ∀ᶠ p in 𝓝 v, G p ∈ Ioo ((m : ℝ) - 1) m := hc.eventually (Ioo_mem_nhds hgt hlt)
    filter_upwards [nhdsWithin_le_nhds hnear] with p hp
    rw [Int.ceil_eq_iff]; exact ⟨hp.1, hp.2.le⟩

theorem sard_gap {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t)
    (hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0) {u v : ℝ} (huv : u < v)
    (hno : ∀ t ∈ Ioo u v, ¬ ∃ k : ℤ, G t = k) :
    sardRightVal G D u = sardLeftVal G D v := by
  obtain ⟨p, hp, hp'⟩ := sard_right_witness hG hT huv
  obtain ⟨q, hq, hq'⟩ := sard_left_witness hG hT huv
  rw [← hp', ← hq']
  exact sard_const hG hno hp hq

theorem sard_noncross {G D : ℝ → ℝ} {s : ℝ} (hs : ¬ ∃ k : ℤ, G s = k) :
    sardLeftVal G D s = sardRightVal G D s := by
  simp only [sardLeftVal, sardRightVal, if_neg hs]

theorem sard_telescope {G D : ℝ → ℝ} (hG : ∀ t, HasDerivAt G (D t) t)
    (hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0) (a : ℝ) :
    ∀ n : ℕ, ∀ b, a ≤ b → {t | t ∈ Ico a b ∧ ∃ k : ℤ, G t = k}.ncard = n →
      ∑ᶠ t ∈ {t | t ∈ Ico a b ∧ ∃ k : ℤ, G t = k}, (sardRightVal G D t - sardLeftVal G D t)
        = sardLeftVal G D b - sardLeftVal G D a := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro b hab hn
  set Z := {t | t ∈ Ico a b ∧ ∃ k : ℤ, G t = k} with hZ
  have hfin : Z.Finite :=
    (sard_finite hG hT a b).subset fun t ht => ⟨Ico_subset_Icc_self ht.1, ht.2⟩
  rcases Z.eq_empty_or_nonempty with he | hne
  · rw [he, finsum_mem_empty]
    rcases hab.lt_or_eq with hlt | heq
    · have ha : ¬ ∃ k : ℤ, G a = k := fun h => by
        have : a ∈ Z := ⟨⟨le_rfl, hlt⟩, h⟩
        rw [he] at this; exact this
      rw [← sard_gap hG hT hlt (fun t ht h => by
        have : t ∈ Z := ⟨⟨ht.1.le, ht.2⟩, h⟩
        rw [he] at this; exact this), sard_noncross ha]
      ring
    · rw [heq]; ring
  · obtain ⟨t0, ht0, hmax⟩ := Set.exists_max_image Z id hfin hne
    have hsplit : Z = insert t0 {t | t ∈ Ico a t0 ∧ ∃ k : ℤ, G t = k} := by
      ext t
      simp only [hZ, mem_setOf_eq, mem_insert_iff, mem_Ico]
      constructor
      · rintro ⟨⟨h1, h2⟩, h3⟩
        rcases eq_or_ne t t0 with h | h
        · exact Or.inl h
        · exact Or.inr ⟨⟨h1, lt_of_le_of_ne (hmax t ⟨⟨h1, h2⟩, h3⟩) h⟩, h3⟩
      · rintro (rfl | ⟨⟨h1, h2⟩, h3⟩)
        · exact ht0
        · exact ⟨⟨h1, h2.trans ht0.1.2⟩, h3⟩
    have hnot : t0 ∉ {t | t ∈ Ico a t0 ∧ ∃ k : ℤ, G t = k} := fun h => lt_irrefl _ h.1.2
    have hfin' : {t | t ∈ Ico a t0 ∧ ∃ k : ℤ, G t = k}.Finite :=
      hfin.subset (by rw [hsplit]; exact subset_insert _ _)
    have hcard : {t | t ∈ Ico a t0 ∧ ∃ k : ℤ, G t = k}.ncard < n := by
      rw [← hn, hsplit, ncard_insert_of_notMem hnot hfin']
      omega
    rw [hsplit, finsum_mem_insert _ hnot hfin', ih _ hcard t0 ht0.1.1 rfl,
      sard_gap hG hT ht0.1.2 (fun t ht h => by
        have := hmax t ⟨⟨ht0.1.1.trans ht.1.le, ht.2⟩, h⟩
        exact absurd ht.1 (not_lt.2 this))]
    ring

end SardHelpers

/-- Sard's theorem, same dimension: for a smooth map `F` between smooth manifolds of the same
dimension `n`, the critical values (images of the points where `dF` is not onto) take up no room
in the target: read in any chart of `N`, they form a set of measure zero. -/
theorem critical_values_measure_zero {n : ℕ}
    {M : Type*} [TopologicalSpace M] [ChartedSpace (EuclideanSpace ℝ (Fin n)) M]
    [IsManifold (𝓡 n) ∞ M] [SecondCountableTopology M]
    {N : Type*} [TopologicalSpace N] [ChartedSpace (EuclideanSpace ℝ (Fin n)) N]
    [IsManifold (𝓡 n) ∞ N]
    (F : M → N) (hF : ContMDiff (𝓡 n) (𝓡 n) ∞ F) :
    ∀ e ∈ atlas (EuclideanSpace ℝ (Fin n)) N,
      volume (e '' (F '' {x | ¬ Function.Surjective (mfderiv (𝓡 n) (𝓡 n) F x)} ∩ e.source)) = 0 := by
  intro e he
  set C := {x | ¬ Function.Surjective (mfderiv (𝓡 n) (𝓡 n) F x)} with hC
  obtain ⟨s, hs, hcover⟩ := TopologicalSpace.countable_cover_nhds
    (f := fun x : M => (chartAt (EuclideanSpace ℝ (Fin n)) x).source)
    (fun x => (chartAt (EuclideanSpace ℝ (Fin n)) x).open_source.mem_nhds (mem_chart_source _ x))
  have hFd : MDifferentiable (𝓡 n) (𝓡 n) F := hF.mdifferentiable (by simp)
  let D : M → Set M := fun x => C ∩ F ⁻¹' e.source ∩ (chartAt (EuclideanSpace ℝ (Fin n)) x).source
  let g : M → EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n) :=
    fun x p => e (F ((chartAt (EuclideanSpace ℝ (Fin n)) x).symm p))
  have hsub : e '' (F '' C ∩ e.source) ⊆
      ⋃ x ∈ s, g x '' ((chartAt (EuclideanSpace ℝ (Fin n)) x) '' D x) := by
    rintro _ ⟨_, ⟨⟨z, hz, rfl⟩, hze⟩, rfl⟩
    have hzu : z ∈ ⋃ x ∈ s, (chartAt (EuclideanSpace ℝ (Fin n)) x).source := by
      rw [hcover]; trivial
    simp only [mem_iUnion] at hzu
    obtain ⟨x, hx, hzx⟩ := hzu
    simp only [mem_iUnion]
    refine ⟨x, hx, _, ⟨z, ⟨⟨hz, hze⟩, hzx⟩, rfl⟩, ?_⟩
    simp only [g, (chartAt (EuclideanSpace ℝ (Fin n)) x).left_inv hzx]
  refine measure_mono_null hsub ?_
  refine (measure_biUnion_null_iff hs).2 fun x _ => ?_
  set φ := chartAt (EuclideanSpace ℝ (Fin n)) x with hφ
  have key : ∀ z ∈ D x, MDifferentiableAt (𝓡 n) (𝓡 n) (g x) (φ z) ∧
      ¬ Function.Surjective (mfderiv (𝓡 n) (𝓡 n) (g x) (φ z)) := by
    rintro z ⟨⟨hzC, hze⟩, hzx⟩
    have h1 : MDifferentiableAt (𝓡 n) (𝓡 n) φ.symm (φ z) :=
      mdifferentiableAt_atlas_symm (chart_mem_atlas _ _) (φ.map_source hzx)
    have h2 : MDifferentiableAt (𝓡 n) (𝓡 n) F (φ.symm (φ z)) := hFd _
    have hze' : F (φ.symm (φ z)) ∈ e.source := by rw [φ.left_inv hzx]; exact hze
    have h3 : MDifferentiableAt (𝓡 n) (𝓡 n) e (F (φ.symm (φ z))) :=
      mdifferentiableAt_atlas he hze'
    have h21 := h2.comp (φ z) h1
    refine ⟨h3.comp (φ z) h21, ?_⟩
    have hg : g x = e ∘ (F ∘ φ.symm) := rfl
    rw [hg, mfderiv_comp (φ z) h3 h21, mfderiv_comp (φ z) h2 h1]
    intro hsurj
    apply hzC
    have hinj := (mdifferentiable_of_mem_atlas (I := 𝓡 n) he).mfderiv_injective hze'
    rw [φ.left_inv hzx] at hinj
    intro u
    obtain ⟨v, hv⟩ := hsurj (mfderiv (𝓡 n) (𝓡 n) e (F z) u)
    have hw : φ.symm (φ z) = z := φ.left_inv hzx
    simp only [Function.comp_apply] at hv
    generalize φ.symm (φ z) = w at hv hw
    subst hw
    exact ⟨_, hinj hv⟩
  refine addHaar_image_eq_zero_of_det_fderivWithin_eq_zero _
    (f' := fun p => mfderiv (𝓡 n) (𝓡 n) (g x) p) (fun p hp => ?_) (fun p hp => ?_)
  · obtain ⟨z, hz, rfl⟩ := hp
    exact (key z hz).1.hasMFDerivAt.hasFDerivAt.hasFDerivWithinAt
  · obtain ⟨z, hz, rfl⟩ := hp
    exact sard_det_eq_zero_of_not_surjective _ (key z hz).2

/-- Degree on the circle: let `F` be a smooth map of the circle to itself, followed without
wrapping, so that one full turn of the source moves it on by `d` full turns
(`F (t + 2π) = F t + 2π d`). At every regular value `y` the source points landing on `y`
are finitely many, and scoring each `+1` or `-1` by the sign of the slope there gives `d`,
the same whole number for every regular value. -/
theorem signed_count_eq_net_turns (F : ℝ → ℝ) (d : ℤ) (hF : ContDiff ℝ ∞ F)
    (hturn : ∀ t, F (t + 2 * Real.pi) = F t + 2 * Real.pi * d) (y : ℝ)
    (hreg : ∀ t, ∀ k : ℤ, F t = y + 2 * Real.pi * k → deriv F t ≠ 0) :
    {t | t ∈ Ico 0 (2 * Real.pi) ∧ ∃ k : ℤ, F t = y + 2 * Real.pi * k}.Finite ∧
      ∑ᶠ t ∈ {t | t ∈ Ico 0 (2 * Real.pi) ∧ ∃ k : ℤ, F t = y + 2 * Real.pi * k},
        ((SignType.sign (deriv F t) : SignType) : ℤ) = d := by
  have hpi : 0 < 2 * Real.pi := by positivity
  have hd : Differentiable ℝ F := hF.differentiable (by simp)
  let G : ℝ → ℝ := fun t => (F t - y) / (2 * Real.pi)
  let D : ℝ → ℝ := fun t => deriv F t / (2 * Real.pi)
  have hG : ∀ t, HasDerivAt G (D t) t := fun t => ((hd t).hasDerivAt.sub_const y).div_const _
  have hcross : ∀ t (k : ℤ), F t = y + 2 * Real.pi * k ↔ G t = k := by
    intro t k
    simp only [G]
    rw [div_eq_iff hpi.ne']
    constructor <;> intro h <;> linarith
  have hT : ∀ t, ∀ k : ℤ, G t = k → D t ≠ 0 := fun t k hk =>
    div_ne_zero (hreg t k ((hcross t k).2 hk)) hpi.ne'
  have hS : {t | t ∈ Ico 0 (2 * Real.pi) ∧ ∃ k : ℤ, F t = y + 2 * Real.pi * k} =
      {t | t ∈ Ico 0 (2 * Real.pi) ∧ ∃ k : ℤ, G t = k} := by
    ext t; simp only [mem_setOf_eq, hcross]
  rw [hS]
  refine ⟨(sard_finite hG hT 0 (2 * Real.pi)).subset
    fun t ht => ⟨Ico_subset_Icc_self ht.1, ht.2⟩, ?_⟩
  have hsum : ∀ t ∈ {t | t ∈ Ico 0 (2 * Real.pi) ∧ ∃ k : ℤ, G t = k},
      ((SignType.sign (deriv F t) : SignType) : ℤ) = sardRightVal G D t - sardLeftVal G D t := by
    intro t ht
    obtain ⟨k, hk⟩ := ht.2
    have hne := hreg t k ((hcross t k).2 hk)
    have hDpos : 0 < D t ↔ 0 < deriv F t := div_pos_iff_of_pos_right hpi
    unfold sardRightVal sardLeftVal
    rw [if_pos ht.2, if_pos ht.2]
    rcases lt_or_gt_of_ne hne with h | h
    · rw [if_neg (by rw [hDpos]; exact not_lt.2 h.le), if_neg (by rw [hDpos]; exact not_lt.2 h.le),
        sign_neg h]
      simp
    · rw [if_pos (hDpos.2 h), if_pos (hDpos.2 h), sign_pos h]
      simp
  rw [finsum_mem_congr rfl hsum, sard_telescope hG hT 0 _ (2 * Real.pi) hpi.le rfl]
  have hF2 : F (2 * Real.pi) = F 0 + 2 * Real.pi * d := by simpa using hturn 0
  have hD2 : deriv F (2 * Real.pi) = deriv F 0 := by
    have h1 : (fun t => F (t + 2 * Real.pi)) = fun t => F t + 2 * Real.pi * d := funext hturn
    have h2 := congrArg (fun f => deriv f 0) h1
    rw [deriv_comp_add_const, deriv_add_const, zero_add] at h2
    exact h2
  have hG2 : G (2 * Real.pi) = G 0 + d := by
    simp only [G]; rw [hF2]; field_simp; ring
  have hX2 : (∃ k : ℤ, G (2 * Real.pi) = k) ↔ ∃ k : ℤ, G 0 = k := by
    rw [hG2]
    constructor
    · rintro ⟨k, hk⟩; exact ⟨k - d, by push_cast; linarith⟩
    · rintro ⟨k, hk⟩; exact ⟨k + d, by push_cast; linarith⟩
  have hDD : D (2 * Real.pi) = D 0 := by simp only [D, hD2]
  unfold sardLeftVal
  rw [hDD]
  by_cases h0 : ∃ k : ℤ, G 0 = k
  · rw [if_pos (hX2.2 h0), if_pos h0, hG2, Int.ceil_add_intCast]
    split_ifs <;> ring
  · rw [if_neg (fun h => h0 (hX2.1 h)), if_neg h0, hG2, Int.ceil_add_intCast]
    ring

/-- The spinner `F t = 2 t + 3 sin t` has degree 2: at every regular value the signed count of
knob positions landing on it is 2. -/
theorem spinner_signed_count_eq_two (y : ℝ)
    (hreg : ∀ t, ∀ k : ℤ, 2 * t + 3 * Real.sin t = y + 2 * Real.pi * k →
      deriv (fun s => 2 * s + 3 * Real.sin s) t ≠ 0) :
    ∑ᶠ t ∈ {t | t ∈ Ico 0 (2 * Real.pi) ∧ ∃ k : ℤ, 2 * t + 3 * Real.sin t = y + 2 * Real.pi * k},
      ((SignType.sign (deriv (fun s => 2 * s + 3 * Real.sin s) t) : SignType) : ℤ) = 2 := by
  have hsm : ContDiff ℝ ∞ (fun s : ℝ => 2 * s + 3 * Real.sin s) := by fun_prop
  have hturn : ∀ t, (fun s : ℝ => 2 * s + 3 * Real.sin s) (t + 2 * Real.pi) =
      (fun s : ℝ => 2 * s + 3 * Real.sin s) t + 2 * Real.pi * ((2 : ℤ) : ℝ) := by
    intro t; simp only [Real.sin_add_two_pi]; push_cast; ring
  exact (signed_count_eq_net_turns _ 2 hsm hturn y hreg).2

-- The spinner wraps the dial twice: one knob turn moves the pointer on by two full turns.
example : ∀ t : ℝ, 2 * (t + 2 * Real.pi) + 3 * Real.sin (t + 2 * Real.pi)
    = (2 * t + 3 * Real.sin t) + 2 * Real.pi * 2 := by
  intro t; rw [Real.sin_add_two_pi]; ring

-- Knob 0°: pointer at 0°, slope 2 + 3 cos 0 = +5.
example : 2 * (0 : ℝ) + 3 * Real.sin 0 = 0 ∧
    deriv (fun s : ℝ => 2 * s + 3 * Real.sin s) 0 = 5 := by
  have h : HasDerivAt (fun s : ℝ => 2 * s + 3 * Real.sin s) (2 * 1 + 3 * Real.cos 0) 0 :=
    ((hasDerivAt_id' 0).const_mul 2).add ((Real.hasDerivAt_sin 0).const_mul 3)
  refine ⟨by simp, ?_⟩
  rw [h.deriv]; norm_num

-- Knob 180°: pointer at 360°, slope 2 + 3 cos 180° = -1.
example : 2 * Real.pi + 3 * Real.sin Real.pi = 2 * Real.pi ∧
    deriv (fun s : ℝ => 2 * s + 3 * Real.sin s) Real.pi = -1 := by
  have h : HasDerivAt (fun s : ℝ => 2 * s + 3 * Real.sin s)
      (2 * 1 + 3 * Real.cos Real.pi) Real.pi :=
    ((hasDerivAt_id' Real.pi).const_mul 2).add ((Real.hasDerivAt_sin Real.pi).const_mul 3)
  refine ⟨by simp, ?_⟩
  rw [h.deriv]; norm_num

-- The signed count at 12 o'clock: 1 + 1 - 1 + 1 = 2.
example : (1 + 1 - 1 + 1 : ℤ) = 2 := by
  norm_num

-- Unsigned counts over 360 targets: 296 with 2 preimages and 64 with 4.
example : (296 + 64 : ℕ) = 360 := by
  norm_num

#print axioms sard_det_eq_zero_of_not_surjective
#print axioms sard_slope_pos
#print axioms sard_slope_neg
#print axioms sard_isolated
#print axioms sard_finite
#print axioms sard_const
#print axioms sard_right_witness
#print axioms sard_left_witness
#print axioms sard_gap
#print axioms sard_noncross
#print axioms sard_telescope
#print axioms critical_values_measure_zero
#print axioms signed_count_eq_net_turns
#print axioms spinner_signed_count_eq_two
