-- Jordan content: a bounded region whose edge has content zero has a content equal to the limit of both grid-cube counts, a bounded function continuous off a set of content zero is Riemann integrable on a box, and on a Jordan region the Riemann integral equals the integral of the slice integrals, in any dimension.
import Mathlib.Analysis.BoxIntegral.Basic
import Mathlib.Analysis.BoxIntegral.Integrability
import Mathlib.Analysis.BoxIntegral.Partition.Measure
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Data.Pi.Interval
import Mathlib.Data.Int.Interval

open Set Filter Topology MeasureTheory BoxIntegral

/-- A set `Z` in `ℝ^ι` has **content zero**: for every tolerance `ε > 0`, finitely many closed
boxes `[a k, b k]` (each with `a k ≤ b k` in every coordinate) cover `Z` and have total volume
`∑ₖ ∏ᵢ (b k i - a k i)` below `ε`. -/
def ContentZero {ι : Type*} [Fintype ι] (Z : Set (ι → ℝ)) : Prop :=
  ∀ ε > 0, ∃ (n : ℕ) (a b : Fin n → ι → ℝ), (∀ k, a k ≤ b k) ∧
    Z ⊆ ⋃ k, Icc (a k) (b k) ∧ ∑ k, ∏ i, (b k i - a k i) < ε

/-- A **Jordan region**: a bounded set whose edge (its frontier) has content zero. -/
def IsJordanRegion {ι : Type*} [Fintype ι] (D : Set (ι → ℝ)) : Prop :=
  Bornology.IsBounded D ∧ ContentZero (frontier D)

/-- The closed grid cube of side `1/N` with lowest corner `z/N`, for `z` a point with
whole-number coordinates. -/
noncomputable def gridCube {ι : Type*} (N : ℕ) (z : ι → ℤ) : Set (ι → ℝ) :=
  Icc (fun i => (z i : ℝ) / N) (fun i => ((z i : ℝ) + 1) / N)

theorem volume_eq_zero_of_contentZero {ι : Type*} [Fintype ι] {Z : Set (ι → ℝ)}
    (hZ : ContentZero Z) : volume Z = 0 := by
  refine le_antisymm (ENNReal.le_of_forall_pos_le_add fun ε hε _ => ?_) bot_le
  obtain ⟨n, a, b, hab, hcov, hsum⟩ := hZ ε (by exact_mod_cast hε)
  calc volume Z ≤ volume (⋃ k, Icc (a k) (b k)) := measure_mono hcov
    _ ≤ ∑ k, volume (Icc (a k) (b k)) := measure_iUnion_fintype_le _ _
    _ = ∑ k, ∏ i, ENNReal.ofReal (b k i - a k i) := by simp [Real.volume_Icc_pi]
    _ = ENNReal.ofReal (∑ k, ∏ i, (b k i - a k i)) := by
        rw [ENNReal.ofReal_sum_of_nonneg]
        · refine Finset.sum_congr rfl fun k _ => ?_
          rw [ENNReal.ofReal_prod_of_nonneg]
          intro i _; exact sub_nonneg.2 (hab k i)
        · intro k _; exact Finset.prod_nonneg fun i _ => sub_nonneg.2 (hab k i)
    _ ≤ ENNReal.ofReal ε := ENNReal.ofReal_le_ofReal hsum.le
    _ = 0 + ε := by simp
#print axioms volume_eq_zero_of_contentZero

/-- The half-open grid cube, used to tile space without overlap. -/
noncomputable def halfCube {ι : Type*} (N : ℕ) (z : ι → ℤ) : Set (ι → ℝ) :=
  Set.pi univ fun i => Ico ((z i : ℝ) / N) (((z i : ℝ) + 1) / N)

theorem floor_eq_of_mem_halfCube {ι : Type*} {N : ℕ} (hN : 0 < N) {z : ι → ℤ} {p : ι → ℝ}
    (hp : p ∈ halfCube N z) (i : ι) : ⌊(N : ℝ) * p i⌋ = z i := by
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  have h := hp i (mem_univ i)
  rw [Int.floor_eq_iff]
  constructor
  · have := h.1; rw [div_le_iff₀ hN'] at this; linarith
  · have := h.2; rw [lt_div_iff₀ hN'] at this; linarith
#print axioms floor_eq_of_mem_halfCube

theorem mem_halfCube_floor {ι : Type*} {N : ℕ} (hN : 0 < N) (p : ι → ℝ) :
    p ∈ halfCube N (fun i => ⌊(N : ℝ) * p i⌋) := by
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  intro i _
  constructor
  · rw [div_le_iff₀ hN']; have := Int.floor_le ((N : ℝ) * p i); linarith
  · rw [lt_div_iff₀ hN']; have := Int.lt_floor_add_one ((N : ℝ) * p i); linarith
#print axioms mem_halfCube_floor

theorem halfCube_subset_gridCube {ι : Type*} (N : ℕ) (z : ι → ℤ) :
    halfCube N z ⊆ gridCube N z := by
  intro p hp
  exact ⟨fun i => (hp i (mem_univ i)).1, fun i => le_of_lt (hp i (mem_univ i)).2⟩
#print axioms halfCube_subset_gridCube

theorem volume_biUnion_halfCube {ι : Type*} [Fintype ι] {N : ℕ} (hN : 0 < N)
    (F : Finset (ι → ℤ)) :
    volume (⋃ z ∈ F, halfCube N z) =
      ENNReal.ofReal ((F.card : ℝ) * (1 / (N : ℝ)) ^ Fintype.card ι) := by
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  rw [measure_biUnion_finset]
  · have hv : ∀ z : ι → ℤ, volume (halfCube N z) = ENNReal.ofReal ((1 / (N : ℝ)) ^ Fintype.card ι) := by
      intro z
      rw [halfCube, Real.volume_pi_Ico, ENNReal.ofReal_pow (by positivity), ← Finset.card_univ,
        ← Finset.prod_const]
      refine Finset.prod_congr rfl fun i _ => ?_
      congr 1; field_simp; ring
    simp only [hv, Finset.sum_const, nsmul_eq_mul]
    rw [ENNReal.ofReal_mul (by positivity), ENNReal.ofReal_natCast]
  · intro z _ z' _ hzz'
    refine Set.disjoint_left.2 fun p hp hp' => hzz' ?_
    funext i
    rw [← floor_eq_of_mem_halfCube hN hp i, ← floor_eq_of_mem_halfCube hN hp' i]
  · intro z _
    exact MeasurableSet.univ_pi fun i => measurableSet_Ico
#print axioms volume_biUnion_halfCube

/-- The integer points of the grid cubes meeting a box `[a, b]`. -/
theorem gridCube_meet_box_subset {ι : Type*} [Fintype ι] [DecidableEq ι] {N : ℕ} (hN : 0 < N)
    (a b : ι → ℝ) :
    {z : ι → ℤ | (gridCube N z ∩ Icc a b).Nonempty} ⊆
      ↑(Finset.Icc (fun i => ⌈(N : ℝ) * a i⌉ - 1) (fun i => ⌊(N : ℝ) * b i⌋)) := by
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN
  rintro z ⟨p, ⟨hp1, hp2⟩, hq1, hq2⟩
  rw [Finset.coe_Icc, mem_Icc]
  constructor
  · intro i
    have h1 := hp2 i; have h2 := hq1 i
    simp only at h1
    rw [le_div_iff₀ hN'] at h1
    have : ⌈(N : ℝ) * a i⌉ ≤ z i + 1 := by
      rw [Int.ceil_le]; push_cast; nlinarith
    simp only; omega
  · intro i
    have h1 := hp1 i; have h2 := hq2 i
    simp only at h1
    rw [div_le_iff₀ hN'] at h1
    simp only
    rw [Int.le_floor]; nlinarith
#print axioms gridCube_meet_box_subset

theorem card_box_le {ι : Type*} [Fintype ι] [DecidableEq ι] {N : ℕ} (a b : ι → ℝ) (hab : a ≤ b) :
    ((Finset.Icc (fun i => ⌈(N : ℝ) * a i⌉ - 1) (fun i => ⌊(N : ℝ) * b i⌋)).card : ℝ) ≤
      ∏ i, ((N : ℝ) * (b i - a i) + 2) := by
  rw [Pi.card_Icc]
  push_cast
  refine Finset.prod_le_prod₀ (fun i _ => by positivity) fun i _ => ?_
  rw [Int.card_Icc]
  have hN0 : (0 : ℝ) ≤ N := Nat.cast_nonneg N
  have hb := Int.floor_le ((N : ℝ) * b i)
  have ha := Int.le_ceil ((N : ℝ) * a i)
  have hab' : 0 ≤ (N : ℝ) * (b i - a i) := mul_nonneg hN0 (sub_nonneg.2 (hab i))
  have : (((⌊(N : ℝ) * b i⌋ + 1 - (⌈(N : ℝ) * a i⌉ - 1)).toNat : ℤ) : ℝ) ≤
      (N : ℝ) * (b i - a i) + 2 := by
    rw [Int.toNat_eq_max]
    push_cast
    refine max_le ?_ (by linarith)
    nlinarith
  exact_mod_cast this
#print axioms card_box_le

theorem finite_gridCube_meet {ι : Type*} [Fintype ι] {N : ℕ} (hN : 0 < N) {E : Set (ι → ℝ)}
    (hE : Bornology.IsBounded E) : {z : ι → ℤ | (gridCube N z ∩ E).Nonempty}.Finite := by
  classical
  obtain ⟨a, ha⟩ := hE.bddBelow
  obtain ⟨b, hb⟩ := hE.bddAbove
  refine (Finset.finite_toSet _).subset (subset_trans ?_ (gridCube_meet_box_subset hN a b))
  rintro z ⟨p, hp, hpE⟩
  exact ⟨p, hp, ha hpE, hb hpE⟩
#print axioms finite_gridCube_meet

theorem tendsto_count_contentZero {ι : Type*} [Fintype ι] {Z : Set (ι → ℝ)} (hZ : ContentZero Z) :
    Tendsto (fun N : ℕ => ({z : ι → ℤ | (gridCube N z ∩ Z).Nonempty}.ncard : ℝ) /
      (N : ℝ) ^ Fintype.card ι) atTop (𝓝 0) := by
  classical
  rw [tendsto_order]
  refine ⟨fun a ha => Eventually.of_forall fun N => lt_of_lt_of_le ha (by positivity), ?_⟩
  intro ε hε
  obtain ⟨m, a, b, hab, hcov, hsum⟩ := hZ ε hε
  have hlim : Tendsto (fun N : ℕ => ∑ k, ∏ i, (b k i - a k i + 2 / (N : ℝ))) atTop
      (𝓝 (∑ k, ∏ i, (b k i - a k i))) := by
    have h2 : Tendsto (fun N : ℕ => 2 / (N : ℝ)) atTop (𝓝 0) :=
      tendsto_const_div_atTop_nhds_zero_nat 2
    refine tendsto_finsetSum _ fun k _ => tendsto_finsetProd _ fun i _ => ?_
    simpa using (tendsto_const_nhds (x := b k i - a k i)).add h2
  filter_upwards [hlim.eventually (gt_mem_nhds hsum), eventually_gt_atTop 0] with N hN hN0
  refine lt_of_le_of_lt ?_ hN
  have hN' : (0 : ℝ) < N := by exact_mod_cast hN0
  have hsub : {z : ι → ℤ | (gridCube N z ∩ Z).Nonempty} ⊆
      ↑(Finset.univ.biUnion fun k => Finset.Icc (fun i => ⌈(N : ℝ) * a k i⌉ - 1)
        (fun i => ⌊(N : ℝ) * b k i⌋)) := by
    rintro z ⟨p, hp, hpZ⟩
    obtain ⟨k, hk⟩ := mem_iUnion.1 (hcov hpZ)
    rw [Finset.coe_biUnion]
    exact mem_iUnion₂.2 ⟨k, by simp, gridCube_meet_box_subset hN0 (a k) (b k) ⟨p, hp, hk⟩⟩
  have hcount : ({z : ι → ℤ | (gridCube N z ∩ Z).Nonempty}.ncard : ℝ) ≤
      ∑ k, ∏ i, ((N : ℝ) * (b k i - a k i) + 2) := by
    calc ({z : ι → ℤ | (gridCube N z ∩ Z).Nonempty}.ncard : ℝ)
        ≤ ((Finset.univ.biUnion fun k => Finset.Icc (fun i => ⌈(N : ℝ) * a k i⌉ - 1)
            (fun i => ⌊(N : ℝ) * b k i⌋)).card : ℝ) := by
          have := ncard_le_ncard hsub (Finset.finite_toSet _)
          rw [ncard_coe_finset] at this
          exact_mod_cast this
      _ ≤ ∑ k, ((Finset.Icc (fun i => ⌈(N : ℝ) * a k i⌉ - 1)
            (fun i => ⌊(N : ℝ) * b k i⌋)).card : ℝ) := by exact_mod_cast Finset.card_biUnion_le
      _ ≤ ∑ k, ∏ i, ((N : ℝ) * (b k i - a k i) + 2) :=
          Finset.sum_le_sum fun k _ => card_box_le (a k) (b k) (hab k)
  rw [div_le_iff₀ (by positivity)]
  refine hcount.trans (le_of_eq ?_)
  rw [Finset.sum_mul]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [← Finset.card_univ, ← Finset.prod_const, ← Finset.prod_mul_distrib]
  refine Finset.prod_congr rfl fun i _ => ?_
  field_simp
#print axioms tendsto_count_contentZero

/-- A closed grid cube that meets `D` without lying inside it meets the edge of `D`. -/
theorem gridCube_meet_frontier {ι : Type*} [Fintype ι] {N : ℕ} {z : ι → ℤ} {D : Set (ι → ℝ)}
    (h1 : (gridCube N z ∩ D).Nonempty) (h2 : ¬ gridCube N z ⊆ D) :
    (gridCube N z ∩ frontier D).Nonempty := by
  by_contra hne
  rw [not_nonempty_iff_eq_empty] at hne
  have hnf : ∀ q ∈ gridCube N z, q ∉ frontier D := fun q hq hqf =>
    (eq_empty_iff_forall_notMem.1 hne) q ⟨hq, hqf⟩
  have hQ : IsPreconnected (gridCube N z) := (convex_Icc _ _).isPreconnected
  obtain ⟨r, hr, hru, hrv⟩ := hQ (interior D) (closure D)ᶜ isOpen_interior
    isClosed_closure.isOpen_compl
    (by
      intro q hq
      by_cases hqi : q ∈ interior D
      · exact Or.inl hqi
      · exact Or.inr fun hqc => hnf q hq ⟨hqc, hqi⟩)
    (by
      obtain ⟨p, hp, hpD⟩ := h1
      refine ⟨p, hp, ?_⟩
      by_contra hpi
      exact hnf p hp ⟨subset_closure hpD, hpi⟩)
    (by
      obtain ⟨q, hq, hqD⟩ := not_subset.1 h2
      refine ⟨q, hq, fun hqc => hnf q hq ⟨hqc, fun hqi => hqD (interior_subset hqi)⟩⟩)
  exact hrv (subset_closure (interior_subset hru))
#print axioms gridCube_meet_frontier

/-- **Fubini on a Jordan region, in any dimension.** Split the coordinates of `ℝⁿ` into a group
`x` (indexed by `ι`) and the rest `y` (indexed by `κ`), and let the box `I = A × C` hold the region
`D`. Suppose `D` is a Jordan region (bounded, with edge of content zero), the depth `f` is bounded
on `D`, and `f` jumps only on a set `Z` of content zero (it is continuous on `D` at every point of
`D` off `Z`). Then `F`, equal to `f` on `D` and `0` outside, is Riemann integrable on the box, and
its integral is found one group of variables at a time: add `f` over each slice
`D_x = {y | (x, y) ∈ D}`, then add the slice totals over `x` in `A`. The slice totals are taken
as Lebesgue integrals, which agree with the Riemann slice integrals whenever those exist, so the
odd slices of the card's last condition need no extra hypothesis. -/
theorem fubini_on_jordan_region {ι κ : Type*} [Fintype ι] [Fintype κ]
    (A : Box ι) (C : Box κ) (I : Box (ι ⊕ κ))
    (hlo : I.lower = Sum.elim A.lower C.lower) (hup : I.upper = Sum.elim A.upper C.upper)
    (D : Set (ι ⊕ κ → ℝ)) (hDI : D ⊆ Box.Icc I) (hD : IsJordanRegion D)
    (f : (ι ⊕ κ → ℝ) → ℝ) (hfb : ∃ M : ℝ, ∀ p ∈ D, |f p| ≤ M)
    (Z : Set (ι ⊕ κ → ℝ)) (hZ : ContentZero Z)
    (hfc : ∀ p ∈ D, p ∉ Z → ContinuousWithinAt f D p) :
    HasIntegral I IntegrationParams.Riemann (D.indicator f) BoxAdditiveMap.volume
      (∫ x in Box.Icc A, ∫ y in {y | Sum.elim x y ∈ D}, f (Sum.elim x y)) := by
  obtain ⟨M, hM⟩ := hfb
  set g := D.indicator f with hg
  have hF0 : volume (frontier D) = 0 := volume_eq_zero_of_contentZero hD.2
  have hZ0 : volume Z = 0 := volume_eq_zero_of_contentZero hZ
  -- `g` is continuous off the edge of `D` and off `Z`
  have hcont : ∀ p, p ∉ frontier D → p ∉ Z → ContinuousAt g p := by
    intro p hpF hpZ
    by_cases hpi : p ∈ interior D
    · have hDn : D ∈ 𝓝 p := mem_interior_iff_mem_nhds.1 hpi
      have hfp : ContinuousAt f p :=
        (hfc p (interior_subset hpi) hpZ).continuousAt hDn
      refine hfp.congr ?_
      filter_upwards [hDn] with q hq
      exact (indicator_of_mem hq f).symm
    · have hpc : p ∉ closure D := fun h => hpF ⟨h, hpi⟩
      have hn : (closure D)ᶜ ∈ 𝓝 p := isClosed_closure.isOpen_compl.mem_nhds hpc
      refine (continuousAt_const (y := (0 : ℝ))).congr ?_
      filter_upwards [hn] with q hq
      exact (indicator_of_notMem (fun h => hq (subset_closure h)) f).symm
  have hae : ∀ᵐ p ∂(volume : Measure (ι ⊕ κ → ℝ)), ContinuousAt g p := by
    have h1 : ∀ᵐ p ∂(volume : Measure (ι ⊕ κ → ℝ)), p ∉ frontier D :=
      measure_eq_zero_iff_ae_notMem.1 hF0
    have h2 : ∀ᵐ p ∂(volume : Measure (ι ⊕ κ → ℝ)), p ∉ Z :=
      measure_eq_zero_iff_ae_notMem.1 hZ0
    filter_upwards [h1, h2] with p hp1 hp2
    exact hcont p hp1 hp2
  have hbound : ∀ p, ‖g p‖ ≤ max M 0 := by
    intro p
    by_cases hp : p ∈ D
    · rw [hg, indicator_of_mem hp, Real.norm_eq_abs]; exact (hM p hp).trans (le_max_left _ _)
    · rw [hg, indicator_of_notMem hp, norm_zero]; exact le_max_right _ _
  have hbox := AEContinuous.hasBoxIntegral (E := ℝ) (volume : Measure (ι ⊕ κ → ℝ)) (I := I)
    (f := g) ⟨max M 0, fun p _ => hbound p⟩ hae IntegrationParams.Riemann
  rw [BoxAdditiveMap.volume]
  convert hbox using 1
  -- now the value
  have hgout : ∀ p, p ∉ Box.Icc I → g p = 0 := fun p hp =>
    indicator_of_notMem (fun h => hp (hDI h)) f
  rw [setIntegral_congr_set (Box.coe_ae_eq_Icc I),
    setIntegral_eq_integral_of_forall_compl_eq_zero hgout]
  -- measurability and integrability of `g`
  have hgm : AEStronglyMeasurable g (volume : Measure (ι ⊕ κ → ℝ)) := by
    have hv := (continuousOn_of_forall_continuousAt (s := {p | ContinuousAt g p})
      fun _ h ↦ h).aestronglyMeasurable (μ := volume) (measurableSet_of_continuousAt g)
    rwa [Measure.restrict_eq_self_of_ae_mem hae] at hv
  have hgi : Integrable g (volume : Measure (ι ⊕ κ → ℝ)) := by
    refine IntegrableOn.integrable_of_forall_notMem_eq_zero (s := Box.Icc I) ?_ hgout
    exact IntegrableOn.of_bound I.isCompact_Icc.measure_lt_top hgm.restrict (max M 0)
      (ae_of_all _ hbound)
  set e := MeasurableEquiv.sumPiEquivProdPi (fun _ : ι ⊕ κ => ℝ) with he
  have hmp : MeasurePreserving e.symm (volume : Measure ((ι → ℝ) × (κ → ℝ)))
      (volume : Measure (ι ⊕ κ → ℝ)) :=
    measurePreserving_sumPiEquivProdPi_symm (fun _ => volume)
  have hes : ∀ x y, e.symm (x, y) = Sum.elim x y := fun x y => by ext (i | i) <;> rfl
  rw [← hmp.integral_comp' g]
  have hgi' : Integrable (g ∘ e.symm) (volume : Measure ((ι → ℝ) × (κ → ℝ))) :=
    (hmp.integrable_comp_emb e.symm.measurableEmbedding).2 hgi
  rw [Measure.volume_eq_prod] at hgi' ⊢
  rw [integral_prod (fun z => g (e.symm z)) hgi']
  simp only [hes]
  -- the outer integral may run over all `x`: slices off `A` are empty
  have hslice_out : ∀ x, x ∉ Box.Icc A →
      ∫ y in {y | Sum.elim x y ∈ D}, f (Sum.elim x y) = 0 := by
    intro x hx
    have : {y : κ → ℝ | Sum.elim x y ∈ D} = ∅ := by
      ext y
      simp only [mem_ofPred_eq, mem_empty_iff_false, iff_false]
      intro hy
      apply hx
      have h := hDI hy
      rw [Box.Icc_def, mem_Icc, hlo, hup] at h
      rw [Box.Icc_def, mem_Icc]
      exact ⟨fun i => h.1 (Sum.inl i), fun i => h.2 (Sum.inl i)⟩
    rw [this, Measure.restrict_empty, integral_zero_measure]
  rw [setIntegral_eq_integral_of_forall_compl_eq_zero hslice_out]
  -- almost every slice of the edge is null
  have hFm : MeasurableSet (e.symm ⁻¹' frontier D) :=
    e.symm.measurable isClosed_frontier.measurableSet
  have hFp : (volume.prod volume : Measure ((ι → ℝ) × (κ → ℝ))) (e.symm ⁻¹' frontier D) = 0 := by
    rw [← Measure.volume_eq_prod, hmp.measure_preimage isClosed_frontier.measurableSet.nullMeasurableSet, hF0]
  have hsl := (Measure.measure_prod_null hFm).1 hFp
  refine integral_congr_ae ?_
  filter_upwards [hsl] with x hx
  simp only [Pi.zero_apply] at hx
  have hxF : volume {y : κ → ℝ | Sum.elim x y ∈ frontier D} = 0 := by
    rw [← hx]; congr 1
  have hcontY : Continuous fun y : κ → ℝ => (Sum.elim x y : ι ⊕ κ → ℝ) := by
    refine continuous_pi fun j => ?_
    rcases j with i | i
    · exact continuous_const
    · exact continuous_apply i
  have hTm : MeasurableSet {y : κ → ℝ | Sum.elim x y ∈ interior D} :=
    (isOpen_interior.preimage hcontY).measurableSet
  have hST : {y : κ → ℝ | Sum.elim x y ∈ interior D} =ᵐ[volume] {y | Sum.elim x y ∈ D} := by
    refine ae_eq_set.2 ⟨?_, ?_⟩
    · have h0 : {y : κ → ℝ | Sum.elim x y ∈ interior D} \ {y | Sum.elim x y ∈ D} = ∅ :=
        sdiff_eq_empty.2 fun y (hy : Sum.elim x y ∈ interior D) => (interior_subset hy : Sum.elim x y ∈ D)
      rw [h0]; exact measure_empty
    · refine measure_mono_null ?_ hxF
      intro y hy
      exact ⟨subset_closure hy.1, hy.2⟩
  have hSm : NullMeasurableSet {y : κ → ℝ | Sum.elim x y ∈ D} volume :=
    hTm.nullMeasurableSet.congr hST
  rw [← integral_indicator₀ hSm]
  refine integral_congr_ae (ae_of_all _ fun y => ?_)
  by_cases hy : Sum.elim x y ∈ D
  · simp [hg, indicator_of_mem hy, indicator_of_mem (show y ∈ {y | Sum.elim x y ∈ D} from hy)]
  · simp [hg, indicator_of_notMem hy,
      indicator_of_notMem (show y ∉ {y | Sum.elim x y ∈ D} from hy)]

/-- **The integrability test.** A function `F` that is bounded on a closed box `I` and continuous
(on the box) at every point of the box off a set `Z` of content zero is Riemann integrable on `I`. -/
theorem riemann_integrable_of_continuous_off_content_zero {ι : Type*} [Fintype ι]
    (I : Box ι) (F : (ι → ℝ) → ℝ) (hFb : ∃ M : ℝ, ∀ x ∈ Box.Icc I, |F x| ≤ M)
    (Z : Set (ι → ℝ)) (hZ : ContentZero Z)
    (hFc : ∀ x ∈ Box.Icc I, x ∉ Z → ContinuousWithinAt F (Box.Icc I) x) :
    Integrable I IntegrationParams.Riemann F BoxAdditiveMap.volume := by
  have hZ0 := volume_eq_zero_of_contentZero hZ
  obtain ⟨M, hM⟩ := hFb
  rw [BoxAdditiveMap.volume]
  refine integrable_of_bounded_and_ae_continuousWithinAt (E := ℝ) IntegrationParams.Riemann
    (I := I) (f := F) ⟨M, fun x hx => by rw [Real.norm_eq_abs]; exact hM x hx⟩ volume ?_
  have h1 : ∀ᵐ x ∂(volume.restrict (Box.Icc I)), x ∈ Box.Icc I :=
    ae_restrict_mem measurableSet_Icc
  have h2 : ∀ᵐ x ∂(volume.restrict (Box.Icc I)), x ∉ Z :=
    ae_restrict_of_ae (measure_eq_zero_iff_ae_notMem.1 hZ0)
  filter_upwards [h1, h2] with x hx hxZ
  exact hFc x hx hxZ

/-- **Jordan content from grid counts.** For a Jordan region `D` in `ℝⁿ`, the volume of the grid
cubes of side `1/N` lying inside `D` and the volume of those meeting `D` both tend, as `N` grows,
to one number, the content of `D`, which is its volume. -/
theorem jordan_content_eq_lim_inner_eq_lim_outer {ι : Type*} [Fintype ι]
    (D : Set (ι → ℝ)) (hD : IsJordanRegion D) :
    Tendsto (fun N : ℕ => ({z : ι → ℤ | gridCube N z ⊆ D}.ncard : ℝ) / (N : ℝ) ^ Fintype.card ι)
        atTop (𝓝 (volume D).toReal) ∧
      Tendsto (fun N : ℕ => ({z : ι → ℤ | (gridCube N z ∩ D).Nonempty}.ncard : ℝ) /
        (N : ℝ) ^ Fintype.card ι) atTop (𝓝 (volume D).toReal) := by
  obtain ⟨hB, hF⟩ := hD
  have hfin : volume D ≠ ⊤ := hB.measure_lt_top.ne
  have hc := tendsto_count_contentZero hF
  set n := Fintype.card ι
  set V := (volume D).toReal
  -- the three bounds, for `N > 0`
  have hout_fin : ∀ N : ℕ, 0 < N → {z : ι → ℤ | (gridCube N z ∩ D).Nonempty}.Finite :=
    fun N hN => finite_gridCube_meet hN hB
  have hin_sub : ∀ N : ℕ, 0 < N →
      {z : ι → ℤ | gridCube N z ⊆ D} ⊆ {z : ι → ℤ | (gridCube N z ∩ D).Nonempty} := by
    intro N hN z hz
    have hN' : (0 : ℝ) < N := by exact_mod_cast hN
    refine ⟨fun i => (z i : ℝ) / N, ⟨le_rfl, fun i => ?_⟩, hz ⟨le_rfl, fun i => ?_⟩⟩ <;>
      exact div_le_div_of_nonneg_right (by linarith) hN'.le
  have hin_fin : ∀ N : ℕ, 0 < N → {z : ι → ℤ | gridCube N z ⊆ D}.Finite :=
    fun N hN => (hout_fin N hN).subset (hin_sub N hN)
  have hin_le : ∀ N : ℕ, 0 < N →
      ({z : ι → ℤ | gridCube N z ⊆ D}.ncard : ℝ) / (N : ℝ) ^ n ≤ V := by
    intro N hN
    set F := (hin_fin N hN).toFinset
    have hvol := volume_biUnion_halfCube hN F
    have hsub : (⋃ z ∈ F, halfCube N z) ⊆ D := by
      refine iUnion₂_subset fun z hz => ?_
      rw [Set.Finite.mem_toFinset] at hz
      exact (halfCube_subset_gridCube N z).trans hz
    have h : ENNReal.ofReal _ ≤ volume D := hvol ▸ measure_mono hsub
    rw [ENNReal.ofReal_le_iff_le_toReal hfin] at h
    rw [ncard_eq_toFinset_card _ (hin_fin N hN)]
    convert h using 1
    rw [div_eq_mul_one_div, one_div_pow]
  have hV_le : ∀ N : ℕ, 0 < N →
      V ≤ ({z : ι → ℤ | (gridCube N z ∩ D).Nonempty}.ncard : ℝ) / (N : ℝ) ^ n := by
    intro N hN
    set F := (hout_fin N hN).toFinset
    have hvol := volume_biUnion_halfCube hN F
    have hsub : D ⊆ ⋃ z ∈ F, halfCube N z := by
      intro p hp
      refine mem_iUnion₂.2 ⟨fun i => ⌊(N : ℝ) * p i⌋, ?_, mem_halfCube_floor hN p⟩
      rw [Set.Finite.mem_toFinset]
      exact ⟨p, halfCube_subset_gridCube N _ (mem_halfCube_floor hN p), hp⟩
    have h := (measure_mono hsub).trans_eq hvol
    have h' := ENNReal.toReal_le_of_le_ofReal (by positivity) h
    rw [ncard_eq_toFinset_card _ (hout_fin N hN)]
    convert h' using 1
    rw [div_eq_mul_one_div, one_div_pow]
  have hout_le : ∀ N : ℕ, 0 < N →
      ({z : ι → ℤ | (gridCube N z ∩ D).Nonempty}.ncard : ℝ) ≤
        ({z : ι → ℤ | gridCube N z ⊆ D}.ncard : ℝ) +
          ({z : ι → ℤ | (gridCube N z ∩ frontier D).Nonempty}.ncard : ℝ) := by
    intro N hN
    have hTfin : {z : ι → ℤ | (gridCube N z ∩ frontier D).Nonempty}.Finite :=
      finite_gridCube_meet hN (hB.closure.subset frontier_subset_closure)
    have hsub : {z : ι → ℤ | (gridCube N z ∩ D).Nonempty} ⊆
        {z : ι → ℤ | gridCube N z ⊆ D} ∪ {z : ι → ℤ | (gridCube N z ∩ frontier D).Nonempty} := by
      intro z hz
      by_cases hzD : gridCube N z ⊆ D
      · exact Or.inl hzD
      · exact Or.inr (gridCube_meet_frontier hz hzD)
    have := (ncard_le_ncard hsub ((hin_fin N hN).union hTfin)).trans (ncard_union_le _ _)
    exact_mod_cast this
  set c := fun N : ℕ => ({z : ι → ℤ | (gridCube N z ∩ frontier D).Nonempty}.ncard : ℝ) /
      (N : ℝ) ^ n with hcdef
  have hsplit : ∀ N : ℕ, 0 < N →
      ({z : ι → ℤ | (gridCube N z ∩ D).Nonempty}.ncard : ℝ) / (N : ℝ) ^ n ≤
        ({z : ι → ℤ | gridCube N z ⊆ D}.ncard : ℝ) / (N : ℝ) ^ n + c N := by
    intro N hN
    have hN' : (0 : ℝ) < (N : ℝ) ^ n := by positivity
    rw [hcdef, ← add_div]
    exact div_le_div_of_nonneg_right (hout_le N hN) hN'.le
  constructor
  · refine tendsto_of_tendsto_of_tendsto_of_le_of_le' (g := fun N => V - c N) (h := fun _ => V)
      ?_ tendsto_const_nhds ?_ ?_
    · simpa using (tendsto_const_nhds (x := V)).sub hc
    · filter_upwards [eventually_gt_atTop 0] with N hN
      have := hsplit N hN; have := hV_le N hN
      linarith
    · filter_upwards [eventually_gt_atTop 0] with N hN
      exact hin_le N hN
  · refine tendsto_of_tendsto_of_tendsto_of_le_of_le' (g := fun _ => V) (h := fun N => V + c N)
      tendsto_const_nhds ?_ ?_ ?_
    · simpa using (tendsto_const_nhds (x := V)).add hc
    · filter_upwards [eventually_gt_atTop 0] with N hN
      exact hV_le N hN
    · filter_upwards [eventually_gt_atTop 0] with N hN
      have := hsplit N hN; have := hin_le N hN
      linarith

-- The catchment triangle (0, 0), (4, 0), (0, 3) km on a grid of squares 1/N km wide: square
-- (i, j) lies inside when its far corner does, 3(i + 1) + 4(j + 1) ≤ 12N, and meets the
-- triangle when its near corner does, 3i + 4j ≤ 12N.
-- N = 4: 84 squares inside, 111 meeting the catchment, 27 on the edge.
example : ((Finset.range 16 ×ˢ Finset.range 12).filter
    (fun p : ℕ × ℕ => 3 * (p.1 + 1) + 4 * (p.2 + 1) ≤ 48)).card = 84 := by decide
example : ((Finset.range 16 ×ˢ Finset.range 12).filter
    (fun p : ℕ × ℕ => 3 * p.1 + 4 * p.2 ≤ 48)).card = 111 := by decide
-- N = 10: 570 squares inside, 639 meeting.
set_option maxRecDepth 100000 in
example : ((Finset.range 40 ×ˢ Finset.range 30).filter
    (fun p : ℕ × ℕ => 3 * (p.1 + 1) + 4 * (p.2 + 1) ≤ 120)).card = 570 := by decide
set_option maxRecDepth 100000 in
example : ((Finset.range 40 ×ˢ Finset.range 30).filter
    (fun p : ℕ × ℕ => 3 * p.1 + 4 * p.2 ≤ 120)).card = 639 := by decide
-- The count formulas 6N² − 3N and 6N² + 4N − 1 at N = 1000, and the 7N − 1 = 6999 edge squares.
example : (6 * 1000 ^ 2 + 4 * 1000 - 1) - (6 * 1000 ^ 2 - 3 * 1000) = 6999 := by norm_num
-- The rain total, 76 mm km², three ways: north strips, east strips, the centroid.
example : (30 : ℚ) * 4 - 3 / 2 * 4 ^ 2 / 2 - 3 / 2 * 4 ^ 3 / 3 = 76 := by norm_num
example : (10 : ℚ) * 6 + 4 ^ 2 * 3 / 3 = 76 := by norm_num
example : (10 : ℚ) * 6 + 2 * 6 * (4 / 3) = 76 := by norm_num
-- The strip at x = 2 holds (10 + 2·2)(3 − 3·2/4) = 21; the layers add to 6·10 + (3/4)·64/3 = 76.
example : ((10 : ℚ) + 2 * 2) * (3 - 3 * 2 / 4) = 21 := by norm_num
example : (6 : ℚ) * 10 + 3 / 4 * (64 / 3) = 76 := by norm_num

#print axioms fubini_on_jordan_region
#print axioms riemann_integrable_of_continuous_off_content_zero
#print axioms jordan_content_eq_lim_inner_eq_lim_outer
