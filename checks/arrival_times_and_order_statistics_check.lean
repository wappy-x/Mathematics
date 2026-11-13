-- Given n arrivals, when did they happen: for a Poisson process built from independent exponential waits, given exactly n arrivals by time t the arrival times have the law of n independent uniform draws on (0, t) sorted into order, so the k-th averages k t / (n + 1) and the count before a is binomial with chance a / t.
import Mathlib.Probability.Distributions.Exponential
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Data.Fin.Tuple.Sort
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory

theorem lintegral_pi_fin_prod_aux : ∀ (n : ℕ) (μ : Fin n → Measure ℝ) [∀ i, SigmaFinite (μ i)]
    (g : Fin n → ℝ → ENNReal), (∀ i, Measurable (g i)) →
    ∫⁻ x, ∏ i, g i (x i) ∂(Measure.pi μ) = ∏ i, ∫⁻ y, g i y ∂(μ i)
  | 0, μ, _, g, _ => by
    simp
  | n + 1, μ, _, g, hg => by
    have mp := measurePreserving_piFinSuccAbove μ 0
    set e := MeasurableEquiv.piFinSuccAbove (fun _ : Fin (n+1) => ℝ) 0
    set F' : ℝ × (Fin n → ℝ) → ENNReal := fun p => g 0 p.1 * ∏ j, g j.succ (p.2 j)
    have hF : ∀ x : Fin (n+1) → ℝ, ∏ i, g i (x i) = F' (e x) := by
      intro x; simp [F', e, Fin.prod_univ_succ, MeasurableEquiv.piFinSuccAbove_apply,
        Fin.insertNthEquiv, Fin.tail]
    simp_rw [hF]
    rw [← lintegral_map_equiv, mp.map_eq]
    simp only [F', Fin.succAbove_zero]
    rw [lintegral_prod_mul (f := g 0) (g := fun x : Fin n → ℝ => ∏ j, g j.succ (x j))
      (hg 0).aemeasurable,
      lintegral_pi_fin_prod_aux n _ _ (fun j => hg j.succ), Fin.prod_univ_succ]
    · exact (Finset.measurable_prod _ fun j _ => (hg j.succ).comp (measurable_pi_apply j)).aemeasurable

#print axioms lintegral_pi_fin_prod_aux

theorem pi_expMeasure_eq_withDensity (n : ℕ) {r : ℝ} (hr : 0 < r) :
    Measure.pi (fun _ : Fin n => expMeasure r)
      = (volume : Measure (Fin n → ℝ)).withDensity (fun x => ∏ i, exponentialPDF r (x i)) := by
  have hexp : expMeasure r = volume.withDensity (exponentialPDF r) := rfl
  have hm : Measurable (exponentialPDF r) := by
    unfold exponentialPDF; exact (measurable_exponentialPDFReal r).ennreal_ofReal
  have := isProbabilityMeasure_expMeasure hr
  refine Measure.pi_eq fun s hs => ?_
  rw [withDensity_apply _ (MeasurableSet.univ_pi hs), volume_pi, Measure.restrict_pi_pi,
    lintegral_pi_fin_prod_aux n _ _ (fun _ => hm)]
  refine Finset.prod_congr rfl fun i _ => ?_
  rw [hexp, withDensity_apply _ (hs i)]

#print axioms pi_expMeasure_eq_withDensity

theorem expMeasure_Ioi_of_nonneg {r c : ℝ} (hr : 0 < r) (hc : 0 ≤ c) :
    expMeasure r (Set.Ioi c) = ENNReal.ofReal (Real.exp (-(r * c))) := by
  have := isProbabilityMeasure_expMeasure hr
  rw [← Set.compl_Iic, prob_compl_eq_one_sub measurableSet_Iic, ← ofReal_cdf,
    cdf_expMeasure_eq hr, ite_eq_left hc]
  have h1 : Real.exp (-(r * c)) ≤ 1 := Real.exp_le_one_iff.2 (by nlinarith)
  symm
  apply ENNReal.eq_sub_of_add_eq ENNReal.ofReal_ne_top
  rw [← ENNReal.ofReal_add (Real.exp_pos _).le (by linarith)]
  simp

#print axioms expMeasure_Ioi_of_nonneg

theorem map_first_n_and_next {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {r : ℝ} (hr : 0 < r) (E : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (E i)) (hind : iIndepFun E μ)
    (hexp : ∀ i, μ.map (E i) = expMeasure r) (n : ℕ) :
    μ.map (fun ω => (E n ω, fun i : Fin n => E i ω))
      = (expMeasure r).prod (Measure.pi fun _ : Fin n => expMeasure r) := by
  have := isProbabilityMeasure_expMeasure hr
  have hi : iIndepFun (fun i : Fin (n + 1) => E i) μ := hind.precomp Fin.val_injective
  have hZ := (iIndepFun_iff_map_fun_eq_pi_map (fun i : Fin (n+1) => (hmeas i).aemeasurable)).1 hi
  simp only [hexp] at hZ
  have mp := measurePreserving_piFinSuccAbove (fun _ : Fin (n+1) => expMeasure r) (Fin.last n)
  have hcomp : (fun ω => (E n ω, fun i : Fin n => E i ω)) =
      (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (n+1) => ℝ) (Fin.last n)) ∘
        (fun ω (i : Fin (n+1)) => E i ω) := by
    funext ω; simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv]
    rfl
  have hZm : Measurable (fun ω (i : Fin (n+1)) => E i ω) := measurable_pi_iff.2 fun (i : Fin (n+1)) => hmeas i
  rw [hcomp, ← Measure.map_map (MeasurableEquiv.measurable _) hZm, hZ, mp.map_eq]

#print axioms map_first_n_and_next

theorem core_A {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {r t : ℝ} (hr : 0 < r) (E : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (E i)) (hind : iIndepFun E μ)
    (hexp : ∀ i, μ.map (E i) = expMeasure r) (n : ℕ) {B : Set (Fin n → ℝ)} (hB : MeasurableSet B) :
    μ ({ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω} ∩
        (fun ω (i : Fin n) => E i ω) ⁻¹' B)
      = ENNReal.ofReal (r ^ n * Real.exp (-(r * t))) *
        volume (B ∩ {x | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t}) := by
  have := isProbabilityMeasure_expMeasure hr
  set W : Ω → ℝ × (Fin n → ℝ) := fun ω => (E n ω, fun i : Fin n => E i ω)
  have hWm : Measurable W := (hmeas n).prodMk (measurable_pi_iff.2 fun (i : Fin n) => hmeas i)
  set C : Set (ℝ × (Fin n → ℝ)) := {p | p.2 ∈ B ∧ ∑ i, p.2 i ≤ t ∧ t < ∑ i, p.2 i + p.1}
  have hsum : Measurable (fun x : Fin n → ℝ => ∑ i, x i) :=
    Finset.measurable_sum _ fun i _ => measurable_pi_apply i
  have hC : MeasurableSet C := by
    have h1 : MeasurableSet (Prod.snd ⁻¹' B : Set (ℝ × (Fin n → ℝ))) := measurable_snd hB
    have h2 : MeasurableSet {p : ℝ × (Fin n → ℝ) | ∑ i, p.2 i ≤ t} :=
      measurableSet_le (hsum.comp measurable_snd) measurable_const
    have h3 : MeasurableSet {p : ℝ × (Fin n → ℝ) | t < ∑ i, p.2 i + p.1} :=
      measurableSet_lt measurable_const ((hsum.comp measurable_snd).add measurable_fst)
    exact h1.inter (h2.inter h3)
  have hset : {ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω} ∩
        (fun ω (i : Fin n) => E i ω) ⁻¹' B = W ⁻¹' C := by
    ext ω
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_preimage, C, W, Finset.sum_range_succ,
      Fin.sum_univ_eq_sum_range (fun i => E i ω) n]
    tauto
  rw [hset, ← Measure.map_apply hWm hC, map_first_n_and_next μ hr E hmeas hind hexp n,
    Measure.prod_apply_symm hC, pi_expMeasure_eq_withDensity n hr]
  have hslice : ∀ x : Fin n → ℝ, expMeasure r ((fun y => (y, x)) ⁻¹' C) =
      (B ∩ {x | ∑ i, x i ≤ t}).indicator
        (fun x => ENNReal.ofReal (Real.exp (-(r * (t - ∑ i, x i))))) x := by
    intro x
    by_cases hx : x ∈ B ∩ {x | ∑ i, x i ≤ t}
    · have hx2 : ∑ i, x i ≤ t := hx.2
      rw [Set.indicator_of_mem hx, ← expMeasure_Ioi_of_nonneg hr (by linarith : 0 ≤ t - ∑ i, x i)]
      congr 1; ext y
      simp only [Set.mem_preimage, Set.mem_ofPred_eq, Set.mem_Ioi, C, hx.1, hx2, true_and]
      constructor <;> intro <;> linarith
    · rw [Set.indicator_of_notMem hx]
      have : (fun y => (y, x)) ⁻¹' C = ∅ := by
        ext y
        simp only [Set.mem_preimage, Set.mem_ofPred_eq, C, Set.mem_empty_iff_false, iff_false]
        rintro ⟨h1, h2, -⟩; exact hx ⟨h1, h2⟩
      rw [this, measure_empty]
  simp_rw [hslice]
  have hpdf : Measurable (exponentialPDF r) := by
    unfold exponentialPDF; exact (measurable_exponentialPDFReal r).ennreal_ofReal
  have hFm : Measurable (fun x : Fin n → ℝ => ∏ i, exponentialPDF r (x i)) :=
    Finset.measurable_prod _ fun i _ => hpdf.comp (measurable_pi_apply i)
  have hBt : MeasurableSet (B ∩ {x : Fin n → ℝ | ∑ i, x i ≤ t}) :=
    hB.inter (measurableSet_le hsum measurable_const)
  have hgm : Measurable ((B ∩ {x : Fin n → ℝ | ∑ i, x i ≤ t}).indicator
        (fun x => ENNReal.ofReal (Real.exp (-(r * (t - ∑ i, x i)))))) :=
    (ENNReal.measurable_ofReal.comp (Real.measurable_exp.comp
      ((measurable_const.sub hsum).const_mul r).neg)).indicator hBt
  rw [lintegral_withDensity_eq_lintegral_mul _ hFm hgm]
  have hΔ : MeasurableSet (B ∩ {x : Fin n → ℝ | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t}) := by
    have : {x : Fin n → ℝ | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t} =
        (⋂ i, {x : Fin n → ℝ | 0 ≤ x i}) ∩ {x | ∑ i, x i ≤ t} := by
      ext x; simp
    rw [this]
    exact hB.inter ((MeasurableSet.iInter fun i => measurableSet_le measurable_const
      (measurable_pi_apply i)).inter (measurableSet_le hsum measurable_const))
  rw [← lintegral_indicator_const hΔ]
  refine lintegral_congr fun x => ?_
  simp only [Pi.mul_apply]
  by_cases hx : x ∈ B ∩ {x | ∑ i, x i ≤ t}
  · rw [Set.indicator_of_mem hx]
    by_cases hpos : ∀ i, 0 ≤ x i
    · rw [Set.indicator_of_mem (show x ∈ B ∩ {x : Fin n → ℝ | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t} from
        ⟨hx.1, hpos, hx.2⟩)]
      simp_rw [exponentialPDF_of_nonneg (hpos _)]
      rw [← ENNReal.ofReal_prod_of_nonneg (fun i _ => by positivity), ← ENNReal.ofReal_mul
        (Finset.prod_nonneg fun i _ => by positivity)]
      congr 1
      rw [Finset.prod_mul_distrib, Finset.prod_const, Finset.card_univ, Fintype.card_fin,
        ← Real.exp_sum, mul_assoc, ← Real.exp_add]
      congr 2
      rw [Finset.sum_neg_distrib, ← Finset.mul_sum]; ring
    · rw [Set.indicator_of_notMem
        (fun (h : x ∈ B ∩ {x : Fin n → ℝ | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t}) => hpos h.2.1)]
      simp only [not_forall, not_le] at hpos
      obtain ⟨i, hi⟩ := hpos
      rw [Finset.prod_eq_zero (Finset.mem_univ i) (exponentialPDF_of_neg hi), zero_mul]
  · rw [Set.indicator_of_notMem hx, mul_zero, Set.indicator_of_notMem]
    exact fun (h : x ∈ B ∩ {x : Fin n → ℝ | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t}) => hx ⟨h.1, h.2.2⟩

#print axioms core_A

theorem cumsum_eq_toLin (n : ℕ) (f : ℕ → ℝ) (k : Fin n) :
    ∑ i ∈ Finset.range ((k : ℕ) + 1), f i
      = Matrix.toLin' (Matrix.of fun (k i : Fin n) => if i ≤ k then (1:ℝ) else 0)
          (fun i => f i) k := by
  rw [Matrix.toLin'_apply, Matrix.mulVec, dotProduct]
  simp only [Matrix.of_apply, ite_mul, one_mul, zero_mul]
  have : ∀ i : Fin n, (if i ≤ k then f i else 0) = (fun j : ℕ => if j ≤ (k : ℕ) then f j else 0) i :=
    fun i => if_congr Fin.le_def rfl rfl
  simp_rw [this]
  rw [Fin.sum_univ_eq_sum_range (fun j : ℕ => if j ≤ (k : ℕ) then f j else 0) n, ← Finset.sum_filter]
  congr 1
  ext j; simp only [Finset.mem_filter, Finset.mem_range]; omega

#print axioms cumsum_eq_toLin

theorem det_cumsum (n : ℕ) :
    LinearMap.det (Matrix.toLin' (Matrix.of fun (k i : Fin n) => if i ≤ k then (1:ℝ) else 0)) = 1 := by
  rw [LinearMap.det_toLin', Matrix.det_of_isLowerTriangular]
  · simp
  · intro i j hij
    simp only [Matrix.of_apply]
    exact ite_eq_right (not_le.2 (OrderDual.toDual_lt_toDual.1 hij))

#print axioms det_cumsum

theorem volume_preimage_cumsum (n : ℕ) (s : Set (Fin n → ℝ)) :
    volume (Matrix.toLin' (Matrix.of fun (k i : Fin n) => if i ≤ k then (1:ℝ) else 0) ⁻¹' s)
      = volume s := by
  rw [Measure.addHaar_preimage_linearMap _ (by rw [det_cumsum]; norm_num), det_cumsum]
  simp

#print axioms volume_preimage_cumsum

theorem preimage_cumsum_sorted (n : ℕ) {t : ℝ} (ht : 0 ≤ t) :
    Matrix.toLin' (Matrix.of fun (k i : Fin n) => if i ≤ k then (1:ℝ) else 0) ⁻¹'
        {s | Monotone s ∧ ∀ i, 0 ≤ s i ∧ s i ≤ t}
      = {x | (∀ i, 0 ≤ x i) ∧ ∑ i, x i ≤ t} := by
  ext x
  set f : ℕ → ℝ := fun j => if h : j < n then x ⟨j, h⟩ else 0 with hf
  have hx : x = fun i : Fin n => f i := by funext i; simp [f, i.isLt]
  have hL : ∀ k : Fin n, Matrix.toLin' (Matrix.of fun (k i : Fin n) => if i ≤ k then (1:ℝ) else 0) x k
      = ∑ i ∈ Finset.range ((k : ℕ) + 1), f i := by
    intro k; rw [cumsum_eq_toLin n f k, ← hx]
  have hsum : ∑ i, x i = ∑ i ∈ Finset.range n, f i := by
    conv_lhs => rw [hx]
    exact Fin.sum_univ_eq_sum_range f n
  simp only [Set.mem_preimage, Set.mem_ofPred_eq, hL, hsum]
  constructor
  · rintro ⟨hmono, hb⟩
    refine ⟨fun i => ?_, ?_⟩
    · obtain ⟨j, hj⟩ := i
      rcases j with _ | j
      · have := (hb ⟨0, hj⟩).1
        simpa [f, hj] using this
      · have h1 := hmono (show (⟨j, by omega⟩ : Fin n) ≤ ⟨j + 1, hj⟩ from by simp)
        rw [hL, hL] at h1
        simp only [Finset.sum_range_succ (n := j + 1)] at h1
        have : f (j + 1) = x ⟨j + 1, hj⟩ := by simp [f, hj]
        linarith
    · rcases Nat.eq_zero_or_pos n with h0 | hpos
      · subst h0; simpa using ht
      · have := (hb ⟨n - 1, by omega⟩).2
        rwa [show n - 1 + 1 = n by omega] at this
  · rintro ⟨hpos, hle⟩
    have hf0 : ∀ j, 0 ≤ f j := fun j => by
      simp only [f]; split_ifs
      · exact hpos _
      · exact le_rfl
    refine ⟨fun a b hab => ?_, fun i => ⟨Finset.sum_nonneg fun j _ => hf0 j, ?_⟩⟩
    · rw [hL, hL]
      exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_subset_range.2 (by have := Fin.le_def.1 hab; omega))
        fun j _ _ => hf0 j
    · exact le_trans (Finset.sum_le_sum_of_subset_of_nonneg
        (Finset.range_subset_range.2 (by omega)) fun j _ _ => hf0 j) hle

#print axioms preimage_cumsum_sorted

theorem sort_preimage_eq (n : ℕ) (A : Set (Fin n → ℝ)) :
    (fun u : Fin n → ℝ => u ∘ Tuple.sort u) ⁻¹' A
      = ⋃ σ : Equiv.Perm (Fin n), {u : Fin n → ℝ | Monotone (u ∘ σ)} ∩ (fun u => u ∘ σ) ⁻¹' A := by
  ext u
  simp only [Set.mem_preimage, Set.mem_iUnion, Set.mem_inter_iff, Set.mem_ofPred_eq]
  constructor
  · intro h; exact ⟨Tuple.sort u, Tuple.monotone_sort u, h⟩
  · rintro ⟨σ, hσ, hA⟩
    rwa [Tuple.unique_monotone (Tuple.monotone_sort u) hσ]

#print axioms sort_preimage_eq

theorem measurableSet_monotone_comp (n : ℕ) (σ : Equiv.Perm (Fin n)) :
    MeasurableSet {u : Fin n → ℝ | Monotone (u ∘ σ)} := by
  have : {u : Fin n → ℝ | Monotone (u ∘ σ)}
      = ⋂ i : Fin n, ⋂ j : Fin n, {u | i ≤ j → u (σ i) ≤ u (σ j)} := by
    ext u; simp [Monotone]
  rw [this]
  refine MeasurableSet.iInter fun i => MeasurableSet.iInter fun j => ?_
  by_cases hij : i ≤ j
  · simp only [hij, true_implies]
    exact measurableSet_le (measurable_pi_apply _) (measurable_pi_apply _)
  · simp [hij]

#print axioms measurableSet_monotone_comp

theorem measurable_sort_map (n : ℕ) : Measurable (fun u : Fin n → ℝ => u ∘ Tuple.sort u) := by
  intro A hA
  rw [sort_preimage_eq]
  refine MeasurableSet.iUnion fun σ => (measurableSet_monotone_comp n σ).inter ?_
  have hm : Measurable (fun u : Fin n → ℝ => u ∘ σ) :=
    measurable_pi_iff.2 fun i => measurable_pi_apply (σ i)
  exact hm hA

#print axioms measurable_sort_map

theorem volume_preimage_perm (n : ℕ) (σ : Equiv.Perm (Fin n)) (X : Set (Fin n → ℝ)) :
    volume ((fun u : Fin n → ℝ => u ∘ σ) ⁻¹' X) = volume X := by
  have h := volume_measurePreserving_piCongrLeft (fun _ : Fin n => ℝ) σ.symm
  have heq : ⇑(MeasurableEquiv.piCongrLeft (fun _ : Fin n => ℝ) σ.symm) = fun u => u ∘ σ := by
    funext u i; simp [MeasurableEquiv.coe_piCongrLeft, Equiv.piCongrLeft_apply]
  rw [← heq, h.measure_preimage_equiv]

#print axioms volume_preimage_perm

theorem volume_eq_coord_null (n : ℕ) (i j : Fin n) (hij : i ≠ j) :
    volume {u : Fin n → ℝ | u i = u j} = 0 := by
  have hs : {u : Fin n → ℝ | u i = u j}
      = (LinearMap.ker (LinearMap.proj (R := ℝ) (φ := fun _ : Fin n => ℝ) i - LinearMap.proj (R := ℝ) (φ := fun _ : Fin n => ℝ) j) : Set _) := by
    ext u; simp [sub_eq_zero]
  rw [hs]
  apply Measure.addHaar_submodule
  intro htop
  have : (Pi.single i (1:ℝ) : Fin n → ℝ) ∈ LinearMap.ker
      (LinearMap.proj (R := ℝ) (φ := fun _ : Fin n => ℝ) i - LinearMap.proj (R := ℝ) (φ := fun _ : Fin n => ℝ) j) := by rw [htop]; trivial
  simp [hij.symm] at this

#print axioms volume_eq_coord_null

theorem volume_coord_eq_const_null (n : ℕ) (i : Fin n) (c : ℝ) :
    volume {u : Fin n → ℝ | u i = c} = 0 := by
  have : {u : Fin n → ℝ | u i = c} = @Function.eval (Fin n) (fun _ => ℝ) i ⁻¹' ({c} : Set ℝ) := rfl
  rw [this, volume_pi]
  exact Measure.pi_eval_preimage_null _ (by simp)

#print axioms volume_coord_eq_const_null

theorem volume_sort_preimage (n : ℕ) (t : ℝ) {A : Set (Fin n → ℝ)} (hA : MeasurableSet A) :
    volume ((fun u : Fin n → ℝ => u ∘ Tuple.sort u) ⁻¹' A ∩ Set.univ.pi (fun _ => Set.Ioo 0 t))
      = n.factorial * volume (A ∩ {s | Monotone s ∧ ∀ i, 0 ≤ s i ∧ s i ≤ t}) := by
  set Q : Set (Fin n → ℝ) := Set.univ.pi (fun _ => Set.Ioo 0 t) with hQ
  set SM : Set (Fin n → ℝ) := {s | StrictMono s} with hSM
  set N : Set (Fin n → ℝ) := (⋃ i, ⋃ j, ⋃ (_ : i ≠ j), {u | u i = u j}) ∪
      ((⋃ i, {u | u i = 0}) ∪ (⋃ i, {u | u i = t})) with hNdef
  have hN : volume N = 0 := by
    refine measure_union_null (measure_iUnion_null fun i => measure_iUnion_null fun j =>
      measure_iUnion_null fun hij => volume_eq_coord_null n i j hij)
      (measure_union_null (measure_iUnion_null fun i => volume_coord_eq_const_null n i 0)
        (measure_iUnion_null fun i => volume_coord_eq_const_null n i t))
  have hNm : MeasurableSet N := by
    refine (MeasurableSet.iUnion fun i => MeasurableSet.iUnion fun j => MeasurableSet.iUnion
      fun _ => measurableSet_eq_fun (measurable_pi_apply i) (measurable_pi_apply j)).union
      ((MeasurableSet.iUnion fun i => measurableSet_eq_fun (measurable_pi_apply i)
        measurable_const).union (MeasurableSet.iUnion fun i =>
          measurableSet_eq_fun (measurable_pi_apply i) measurable_const))
  have hNc : ∀ u, u ∉ N → Function.Injective u ∧ ∀ i, u i ≠ 0 ∧ u i ≠ t := by
    intro u hu
    simp only [hNdef, Set.mem_union, Set.mem_iUnion, Set.mem_ofPred_eq, not_or, not_exists] at hu
    refine ⟨fun a b hab => ?_, fun i => ⟨hu.2.1 i, hu.2.2 i⟩⟩
    by_contra h
    exact hu.1 a b h hab
  have hSMm : MeasurableSet SM := by
    have : SM = ⋂ i : Fin n, ⋂ j : Fin n, {u | i < j → u i < u j} := by
      ext u; simp [hSM, StrictMono]
    rw [this]
    refine MeasurableSet.iInter fun i => MeasurableSet.iInter fun j => ?_
    by_cases hij : i < j
    · simp only [hij, true_implies]
      exact measurableSet_lt (measurable_pi_apply _) (measurable_pi_apply _)
    · simp [hij]
  have hQm : MeasurableSet Q := MeasurableSet.univ_pi fun _ => measurableSet_Ioo
  have hQperm : ∀ (σ : Equiv.Perm (Fin n)) (u : Fin n → ℝ), u ∘ σ ∈ Q ↔ u ∈ Q := by
    intro σ u
    simp only [hQ, Set.mem_univ_pi, Function.comp_apply]
    exact ⟨fun h i => by simpa using h (σ.symm i), fun h i => h (σ i)⟩
  have hperm_m : ∀ σ : Equiv.Perm (Fin n), Measurable (fun u : Fin n → ℝ => u ∘ σ) :=
    fun σ => measurable_pi_iff.2 fun i => measurable_pi_apply (σ i)
  have hinj : ∀ (σ : Equiv.Perm (Fin n)) (u : Fin n → ℝ), StrictMono (u ∘ σ) →
      Function.Injective u := by
    intro σ u h a b hab
    have : (u ∘ σ) (σ.symm a) = (u ∘ σ) (σ.symm b) := by simp [hab]
    simpa using h.injective this
  rw [← measure_sdiff_null hN]
  have hset : ((fun u : Fin n → ℝ => u ∘ Tuple.sort u) ⁻¹' A ∩ Q) \ N
      = ⋃ σ : Equiv.Perm (Fin n), ((fun u : Fin n → ℝ => u ∘ σ) ⁻¹' (A ∩ Q ∩ SM)) \ N := by
    ext u
    simp only [Set.mem_sdiff, Set.mem_inter_iff, Set.mem_preimage, Set.mem_iUnion]
    constructor
    · rintro ⟨⟨hA', hQ'⟩, hN'⟩
      refine ⟨Tuple.sort u, ⟨⟨hA', (hQperm _ u).2 hQ'⟩, ?_⟩, hN'⟩
      exact (Tuple.monotone_sort u).strictMono_of_injective
        ((hNc u hN').1.comp (Equiv.injective _))
    · rintro ⟨σ, ⟨⟨hA', hQ'⟩, hSM'⟩, hN'⟩
      have := Tuple.unique_monotone (Tuple.monotone_sort u) hSM'.monotone
      refine ⟨⟨?_, (hQperm σ u).1 hQ'⟩, hN'⟩
      rw [this]; exact hA'
  rw [hset, measure_iUnion]
  · rw [tsum_fintype]
    have hterm : ∀ σ : Equiv.Perm (Fin n),
        volume (((fun u : Fin n → ℝ => u ∘ σ) ⁻¹' (A ∩ Q ∩ SM)) \ N) = volume (A ∩ Q ∩ SM) := by
      intro σ
      rw [measure_sdiff_null hN, volume_preimage_perm]
    simp_rw [hterm]
    rw [Finset.sum_const, Finset.card_univ, Fintype.card_perm, Fintype.card_fin, nsmul_eq_mul]
    congr 1
    rw [← measure_sdiff_null hN, ← measure_sdiff_null (s := A ∩ {s | Monotone s ∧ ∀ i, 0 ≤ s i ∧ s i ≤ t}) hN]
    congr 1
    ext u
    simp only [Set.mem_sdiff, Set.mem_inter_iff, Set.mem_ofPred_eq, hQ, hSM, Set.mem_univ_pi,
      Set.mem_Ioo]
    constructor
    · rintro ⟨⟨⟨hA', hQ'⟩, hS'⟩, hN'⟩
      exact ⟨⟨hA', hS'.monotone, fun i => ⟨(hQ' i).1.le, (hQ' i).2.le⟩⟩, hN'⟩
    · rintro ⟨⟨hA', hM', hb⟩, hN'⟩
      obtain ⟨hi, hne⟩ := hNc u hN'
      refine ⟨⟨⟨hA', fun i => ⟨lt_of_le_of_ne (hb i).1 (hne i).1.symm,
        lt_of_le_of_ne (hb i).2 (hne i).2⟩⟩, hM'.strictMono_of_injective hi⟩, hN'⟩
  · intro σ τ hστ
    refine Set.disjoint_left.2 fun u hu hu' => hστ ?_
    have h1 : StrictMono (u ∘ σ) := hu.1.2
    have h2 : StrictMono (u ∘ τ) := hu'.1.2
    have := Tuple.unique_monotone h1.monotone h2.monotone
    ext i
    have hi := congrFun this i
    exact congrArg Fin.val (hinj σ u h1 hi)
  · intro σ
    exact (hperm_m σ ((hA.inter hQm).inter hSMm)).diff hNm

#print axioms volume_sort_preimage

theorem pi_uniform_eq (n : ℕ) (t : ℝ) :
    Measure.pi (fun _ : Fin n => (volume : Measure ℝ)[|Set.Ioo 0 t])
      = ((volume (Set.Ioo (0:ℝ) t))⁻¹) ^ n •
          (volume : Measure (Fin n → ℝ)).restrict (Set.univ.pi fun _ => Set.Ioo 0 t) := by
  refine Measure.pi_eq fun s hs => ?_
  rw [Measure.smul_apply, Measure.restrict_apply (MeasurableSet.univ_pi hs), ← Set.pi_inter_distrib,
    volume_pi, Measure.pi_pi, smul_eq_mul]
  simp_rw [cond_apply measurableSet_Ioo]
  rw [Finset.prod_mul_distrib, Finset.prod_const, Finset.card_univ, Fintype.card_fin]
  congr 1
  refine Finset.prod_congr rfl fun i _ => ?_
  rw [Set.inter_comm]

#print axioms pi_uniform_eq

theorem pi_count_binomial (n : ℕ) (P : Measure ℝ) [IsProbabilityMeasure P] (a : ℝ) (j : ℕ) :
    (Measure.pi fun _ : Fin n => P).real {u | (Finset.univ.filter (fun i => u i ≤ a)).card = j}
      = (n.choose j : ℝ) * (P.real (Set.Iic a)) ^ j * (1 - P.real (Set.Iic a)) ^ (n - j) := by
  classical
  set box : Finset (Fin n) → Set (Fin n → ℝ) :=
    fun s => Set.univ.pi (fun i => if i ∈ s then Set.Iic a else Set.Ioi a) with hbox
  have hset : {u : Fin n → ℝ | (Finset.univ.filter (fun i => u i ≤ a)).card = j}
      = ⋃ s ∈ Finset.powersetCard j (Finset.univ : Finset (Fin n)), box s := by
    ext u
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_powersetCard, Finset.subset_univ,
      true_and, hbox, Set.mem_univ_pi, exists_prop]
    constructor
    · intro h
      refine ⟨_, h, fun i => ?_⟩
      by_cases hi : u i ≤ a
      · simp [hi]
      · simp [hi, not_le.1 hi]
    · rintro ⟨s, hs, hu⟩
      rw [← hs]
      congr 1
      ext i
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      have := hu i
      by_cases hi : i ∈ s
      · simp only [hi, ite_true, Set.mem_Iic] at this; simp [hi, this]
      · simp only [hi, ite_false, Set.mem_Ioi] at this; simp [hi, not_le.2 this]
  have hboxm : ∀ s, MeasurableSet (box s) := fun s =>
    MeasurableSet.univ_pi fun i => by split_ifs; exacts [measurableSet_Iic, measurableSet_Ioi]
  rw [hset, measureReal_biUnion_finset]
  · have hterm : ∀ s ∈ Finset.powersetCard j (Finset.univ : Finset (Fin n)),
        (Measure.pi fun _ : Fin n => P).real (box s)
          = (P.real (Set.Iic a)) ^ j * (1 - P.real (Set.Iic a)) ^ (n - j) := by
      intro s hs
      rw [Finset.mem_powersetCard] at hs
      rw [measureReal_def, hbox, Measure.pi_pi, ENNReal.toReal_prod]
      have : ∀ i, (P (if i ∈ s then Set.Iic a else Set.Ioi a)).toReal
          = if i ∈ s then P.real (Set.Iic a) else 1 - P.real (Set.Iic a) := by
        intro i
        split_ifs
        · rfl
        · rw [← Set.compl_Iic, ← measureReal_def, probReal_compl_eq_one_sub measurableSet_Iic]
      simp_rw [this]
      rw [Finset.prod_ite, Finset.prod_const, Finset.prod_const]
      congr 2
      · rw [← hs.2]; congr 1; ext i; simp
      · rw [Finset.filter_not, Finset.card_sdiff_of_subset (Finset.filter_subset _ _)]
        simp only [Finset.card_univ, Fintype.card_fin]
        rw [← hs.2]; congr 2; ext i; simp
    rw [Finset.sum_congr rfl hterm, Finset.sum_const, Finset.card_powersetCard, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul, mul_assoc]
  · intro s _ s' _ hss'
    refine Set.disjoint_left.2 fun u hu hu' => hss' ?_
    simp only [hbox, Set.mem_univ_pi] at hu hu'
    ext i
    have h1 := hu i
    have h2 := hu' i
    by_cases hi : i ∈ s <;> by_cases hi' : i ∈ s' <;> simp_all
    · exact absurd h1 (not_le.2 h2)
    · exact absurd h2 (not_le.2 h1)
  · exact fun s _ => hboxm s

#print axioms pi_count_binomial

theorem uniform_real_Iic {t : ℝ} (ht : 0 < t) {a : ℝ} (ha : 0 ≤ a) :
    ((volume : Measure ℝ)[|Set.Ioo 0 t]).real (Set.Iic a) = min a t / t := by
  have hvol : volume (Set.Ioo 0 t ∩ Set.Iic a) = ENNReal.ofReal (min a t) := by
    apply le_antisymm
    · calc volume (Set.Ioo 0 t ∩ Set.Iic a) ≤ volume (Set.Icc 0 (min a t)) :=
            measure_mono fun x hx => ⟨hx.1.1.le, le_min hx.2 hx.1.2.le⟩
        _ = ENNReal.ofReal (min a t) := by simp
    · calc ENNReal.ofReal (min a t) = volume (Set.Ioo 0 (min a t)) := by simp
        _ ≤ volume (Set.Ioo 0 t ∩ Set.Iic a) :=
            measure_mono fun x hx => ⟨⟨hx.1, lt_of_lt_of_le hx.2 (min_le_right _ _)⟩,
              (lt_of_lt_of_le hx.2 (min_le_left _ _)).le⟩
  rw [measureReal_def, cond_apply measurableSet_Ioo, hvol, Real.volume_Ioo, ENNReal.toReal_mul,
    ENNReal.toReal_inv, ENNReal.toReal_ofReal (by linarith), ENNReal.toReal_ofReal (le_min ha ht.le),
    sub_zero, div_eq_inv_mul]

#print axioms uniform_real_Iic

theorem card_filter_perm_eq (n : ℕ) (σ : Equiv.Perm (Fin n)) (u : Fin n → ℝ) (a : ℝ) :
    (Finset.univ.filter (fun i => (u ∘ σ) i ≤ a)).card
      = (Finset.univ.filter (fun i => u i ≤ a)).card := by
  refine Finset.card_nbij' σ σ.symm ?_ ?_ ?_ ?_
  · intro i hi; simpa using hi
  · intro i hi; simpa using hi
  · intro i _; simp
  · intro i _; simp

#print axioms card_filter_perm_eq

theorem measurableSet_count_eq (n : ℕ) (a : ℝ) (j : ℕ) :
    MeasurableSet {u : Fin n → ℝ | (Finset.univ.filter (fun i => u i ≤ a)).card = j} := by
  have : (fun u : Fin n → ℝ => (Finset.univ.filter (fun i => u i ≤ a)).card)
      = fun u => ∑ i, if u i ≤ a then 1 else 0 := by
    funext u; rw [Finset.card_filter]
  have hm : Measurable (fun u : Fin n → ℝ => (Finset.univ.filter (fun i => u i ≤ a)).card) := by
    rw [this]
    exact Finset.measurable_sum _ fun i _ => Measurable.ite
      (measurableSet_le (measurable_pi_apply i) measurable_const) measurable_const measurable_const
  exact hm (measurableSet_singleton j)

#print axioms measurableSet_count_eq

theorem sort_preimage_count (n : ℕ) (a : ℝ) (j : ℕ) :
    (fun u : Fin n → ℝ => u ∘ Tuple.sort u) ⁻¹'
        {u : Fin n → ℝ | (Finset.univ.filter (fun i => u i ≤ a)).card = j}
      = {u : Fin n → ℝ | (Finset.univ.filter (fun i => u i ≤ a)).card = j} := by
  ext u
  simp only [Set.mem_preimage, Set.mem_ofPred_eq]
  rw [card_filter_perm_eq]

#print axioms sort_preimage_count

theorem beta_integral_nat : ∀ (j l : ℕ),
    ∫ x in (0:ℝ)..1, x ^ j * (1 - x) ^ l
      = (j.factorial * l.factorial : ℝ) / ((j + l + 1).factorial : ℝ)
  | 0, l => by
    simp only [pow_zero, one_mul, Nat.factorial_zero, Nat.cast_one, zero_add]
    rw [intervalIntegral.integral_comp_sub_left (fun x => x ^ l) 1]
    simp only [sub_self, sub_zero, integral_pow]
    rw [Nat.factorial_succ]
    push_cast
    have : (l.factorial : ℝ) ≠ 0 := by positivity
    field_simp
    simp
  | j + 1, l => by
    have hu : ∀ x ∈ Set.uIcc (0:ℝ) 1, HasDerivAt (fun x : ℝ => x ^ (j + 1))
        (((j + 1 : ℕ) : ℝ) * x ^ j) x := by
      intro x _
      simpa using hasDerivAt_pow (j + 1) x
    have hv : ∀ x ∈ Set.uIcc (0:ℝ) 1, HasDerivAt (fun x : ℝ => -(1 - x) ^ (l + 1) / ((l:ℝ) + 1))
        ((1 - x) ^ l) x := by
      intro x _
      have h := (((hasDerivAt_id x).const_sub 1).pow (l + 1)).neg.div_const ((l:ℝ) + 1)
      refine h.congr_deriv ?_
      have : ((l:ℝ) + 1) ≠ 0 := by positivity
      simp only [id]
      field_simp
      push_cast
      ring
    have key := intervalIntegral.integral_mul_deriv_eq_deriv_mul hu hv
      ((continuous_const.mul (continuous_pow j)).intervalIntegrable _ _)
      (((continuous_const.sub continuous_id).pow l).intervalIntegrable _ _)
    rw [key]
    have hrest : ∫ x in (0:ℝ)..1, ((j + 1 : ℕ) : ℝ) * x ^ j * (-(1 - x) ^ (l + 1) / ((l:ℝ) + 1))
        = -(((j + 1 : ℕ) : ℝ) / ((l:ℝ) + 1)) * ∫ x in (0:ℝ)..1, x ^ j * (1 - x) ^ (l + 1) := by
      rw [← intervalIntegral.integral_const_mul]
      congr 1; funext x; ring
    rw [hrest, beta_integral_nat j (l + 1)]
    simp only [one_pow, sub_self, ne_eq, Nat.add_eq_zero_iff, one_ne_zero, and_false,
      not_false_eq_true, zero_pow, neg_zero, zero_div, mul_zero, sub_zero]
    rw [show j + (l + 1) + 1 = j + 1 + l + 1 by ring, Nat.factorial_succ j, Nat.factorial_succ l]
    push_cast
    have h1 : ((l:ℝ) + 1) ≠ 0 := by positivity
    have h2 : (((j + 1 + l + 1).factorial : ℕ) : ℝ) ≠ 0 := by positivity
    field_simp
    ring

#print axioms beta_integral_nat

theorem choose_mul_beta (n j : ℕ) (hj : j ≤ n) :
    (n.choose j : ℝ) * ∫ x in (0:ℝ)..1, x ^ j * (1 - x) ^ (n - j) = 1 / ((n:ℝ) + 1) := by
  rw [beta_integral_nat, show j + (n - j) + 1 = n + 1 by omega, Nat.factorial_succ]
  have h := Nat.choose_mul_factorial_mul_factorial hj
  have h' : (n.choose j : ℝ) * j.factorial * (n - j).factorial = n.factorial := by
    exact_mod_cast h
  push_cast
  have : (n.factorial : ℝ) ≠ 0 := by positivity
  rw [mul_div_assoc', ← mul_assoc, h']
  field_simp

#print axioms choose_mul_beta

theorem monotone_lt_iff_card (n : ℕ) {w : Fin n → ℝ} (hw : Monotone w) (i0 : Fin n) (a : ℝ) :
    a < w i0 ↔ (Finset.univ.filter (fun i => w i ≤ a)).card ≤ (i0 : ℕ) := by
  constructor
  · intro h
    calc (Finset.univ.filter (fun i => w i ≤ a)).card ≤ (Finset.Iio i0).card := by
          apply Finset.card_le_card
          intro i hi
          simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hi
          simp only [Finset.mem_Iio]
          by_contra hc
          exact absurd (lt_of_lt_of_le h (hw (not_lt.1 hc))) (not_lt.2 hi)
      _ = i0 := Fin.card_Iio i0
  · intro h
    by_contra hc
    have : (Finset.Iic i0).card ≤ (Finset.univ.filter (fun i => w i ≤ a)).card := by
      apply Finset.card_le_card
      intro i hi
      simp only [Finset.mem_Iic] at hi
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      exact le_trans (hw hi) (not_lt.1 hc)
    rw [Fin.card_Iic] at this
    omega

#print axioms monotone_lt_iff_card

/-- Uniform order statistics. Build a Poisson process with a constant rate `rate > 0` from
independent waits `E 0, E 1, ...`, each exponential with that rate; the k-th arrival comes at
`T_k = E 0 + ... + E (k - 1)`. Fix a window `(0, t]` in advance. Given exactly n arrivals in it,
that is `T_n ≤ t < T_(n+1)`, the list `(T_1, ..., T_n)` has the same law as n independent uniform
draws on `(0, t)` sorted from smallest to largest. The rate does not appear on the right. -/
theorem arrival_times_given_count_are_sorted_uniforms
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (rate t : ℝ) (hrate : 0 < rate) (ht : 0 < t)
    (E : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (E i)) (hind : iIndepFun E μ)
    (hexp : ∀ i, μ.map (E i) = expMeasure rate) (n : ℕ) :
    (μ[|{ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω}]).map
        (fun ω (k : Fin n) => ∑ i ∈ Finset.range ((k : ℕ) + 1), E i ω)
      = (Measure.pi fun _ : Fin n => (volume : Measure ℝ)[|Set.Ioo 0 t]).map
        (fun u : Fin n → ℝ => u ∘ Tuple.sort u) := by
  set S := {ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω} with hSdef
  set T : Ω → Fin n → ℝ := fun ω (k : Fin n) => ∑ i ∈ Finset.range ((k : ℕ) + 1), E i ω with hTdef
  set L := Matrix.toLin' (Matrix.of fun (k i : Fin n) => if i ≤ k then (1:ℝ) else 0) with hLdef
  set D : Set (Fin n → ℝ) := {s | Monotone s ∧ ∀ i, 0 ≤ s i ∧ s i ≤ t} with hDdef
  set K : ENNReal := ENNReal.ofReal (rate ^ n * Real.exp (-(rate * t))) with hKdef
  set c : ENNReal := (volume (Set.Ioo (0:ℝ) t))⁻¹ with hcdef
  have hX : Measurable (fun ω (i : Fin n) => E i ω) := measurable_pi_iff.2 fun i => hmeas i
  have hTL : T = fun ω => L (fun i : Fin n => E i ω) := by
    funext ω k; exact cumsum_eq_toLin n (fun i => E i ω) k
  have hLm : Measurable L := L.continuous_of_finiteDimensional.measurable
  have hTm : Measurable T := by rw [hTL]; exact hLm.comp hX
  have hSm : MeasurableSet S := by
    have h1 : Measurable fun ω => ∑ i ∈ Finset.range n, E i ω :=
      Finset.measurable_sum _ fun i _ => hmeas i
    have h2 : Measurable fun ω => ∑ i ∈ Finset.range (n + 1), E i ω :=
      Finset.measurable_sum _ fun i _ => hmeas i
    exact (measurableSet_le h1 measurable_const).inter (measurableSet_lt measurable_const h2)
  have hLHS : ∀ A : Set (Fin n → ℝ), MeasurableSet A → μ (S ∩ T ⁻¹' A) = K * volume (A ∩ D) := by
    intro A hA
    have : T ⁻¹' A = (fun ω (i : Fin n) => E i ω) ⁻¹' (L ⁻¹' A) := by rw [hTL]; rfl
    rw [this, core_A μ hrate E hmeas hind hexp n (hLm hA), ← preimage_cumsum_sorted n ht.le,
      ← Set.preimage_inter, volume_preimage_cumsum]
  have hRHS : ∀ A : Set (Fin n → ℝ), MeasurableSet A →
      ((Measure.pi fun _ : Fin n => (volume : Measure ℝ)[|Set.Ioo 0 t]).map
        (fun u : Fin n → ℝ => u ∘ Tuple.sort u)) A = c ^ n * n.factorial * volume (A ∩ D) := by
    intro A hA
    rw [Measure.map_apply (measurable_sort_map n) hA, pi_uniform_eq, Measure.smul_apply,
      Measure.restrict_apply (measurable_sort_map n hA), volume_sort_preimage n t hA, smul_eq_mul,
      mul_assoc]
  have hIoo0 : volume (Set.Ioo (0:ℝ) t) ≠ 0 := by simp [ht]
  have hIooT : volume (Set.Ioo (0:ℝ) t) ≠ ⊤ := by simp
  have : IsProbabilityMeasure ((volume : Measure ℝ)[|Set.Ioo 0 t]) :=
    cond_isProbabilityMeasure_of_finite hIoo0 hIooT
  have hνprob : IsProbabilityMeasure ((Measure.pi fun _ : Fin n => (volume : Measure ℝ)[|Set.Ioo 0 t]).map
        (fun u : Fin n → ℝ => u ∘ Tuple.sort u)) :=
    inferInstance
  have hD1 : c ^ n * n.factorial * volume D = 1 := by
    have h := hRHS Set.univ MeasurableSet.univ
    rw [measure_univ, Set.univ_inter] at h
    exact h.symm
  have hD0 : volume D ≠ 0 := by
    intro h; rw [h, mul_zero] at hD1; exact zero_ne_one hD1
  have hDT : volume D ≠ ⊤ := by
    intro h; rw [h] at hD1
    by_cases hc : c ^ n * (n.factorial : ENNReal) = 0
    · rw [hc, zero_mul] at hD1; exact zero_ne_one hD1
    · rw [ENNReal.mul_top hc] at hD1; exact ENNReal.top_ne_one hD1
  have hK0 : K ≠ 0 := by
    rw [hKdef]; simp only [ne_eq, ENNReal.ofReal_eq_zero, not_le]; positivity
  have hKT : K ≠ ⊤ := ENNReal.ofReal_ne_top
  have hS : μ S = K * volume D := by
    have h := hLHS Set.univ MeasurableSet.univ
    rwa [Set.preimage_univ, Set.inter_univ, Set.univ_inter] at h
  have hcD : c ^ n * n.factorial = (volume D)⁻¹ := ENNReal.eq_inv_of_mul_eq_one_left hD1
  ext A hA
  rw [hRHS A hA, Measure.map_apply hTm hA, cond_apply hSm, hLHS A hA, hS, hcD,
    ENNReal.mul_inv (Or.inl hK0) (Or.inl hKT), ← mul_assoc, mul_comm K⁻¹, mul_assoc _ K⁻¹,
    ENNReal.inv_mul_cancel hK0 hKT, mul_one]

/-- The k-th arrival on average. Given exactly n arrivals by time t, the k-th of them
(1 ≤ k ≤ n) comes on average at `k t / (n + 1)`: the n arrivals cut the window into n + 1 gaps
of the same average size. -/
theorem mean_kth_arrival_given_count
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (rate t : ℝ) (hrate : 0 < rate) (ht : 0 < t)
    (E : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (E i)) (hind : iIndepFun E μ)
    (hexp : ∀ i, μ.map (E i) = expMeasure rate) (n k : ℕ) (hk1 : 1 ≤ k) (hkn : k ≤ n) :
    ∫ ω, (∑ i ∈ Finset.range k, E i ω)
        ∂(μ[|{ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω}])
      = k * t / (n + 1) := by
  obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
  have hm : m < n := by omega
  set i0 : Fin n := ⟨m, hm⟩ with hi0
  set T : Ω → Fin n → ℝ := fun ω (k : Fin n) => ∑ i ∈ Finset.range ((k : ℕ) + 1), E i ω with hTdef
  have hTm : Measurable T := measurable_pi_iff.2 fun k =>
    Finset.measurable_sum _ fun i _ => hmeas i
  have hIoo0 : volume (Set.Ioo (0:ℝ) t) ≠ 0 := by simp [ht]
  have hIooT : volume (Set.Ioo (0:ℝ) t) ≠ ⊤ := by simp
  have : IsProbabilityMeasure ((volume : Measure ℝ)[|Set.Ioo 0 t]) :=
    cond_isProbabilityMeasure_of_finite hIoo0 hIooT
  set ν := (Measure.pi fun _ : Fin n => (volume : Measure ℝ)[|Set.Ioo 0 t]).map
    (fun u : Fin n → ℝ => u ∘ Tuple.sort u) with hν
  have hint : ∫ ω, (∑ i ∈ Finset.range (m + 1), E i ω)
        ∂(μ[|{ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω}])
      = ∫ v, v i0 ∂ν := by
    rw [hν, ← arrival_times_given_count_are_sorted_uniforms μ rate t hrate ht E hmeas hind hexp n,
      integral_map hTm.aemeasurable (continuous_apply i0).aestronglyMeasurable]
  rw [hint]
  set Q : Set (Fin n → ℝ) := Set.univ.pi fun _ => Set.Ioo 0 t with hQ
  have hQm : MeasurableSet Q := MeasurableSet.univ_pi fun _ => measurableSet_Ioo
  have hQae : ∀ᵐ v ∂ν, v ∈ Q := by
    rw [ae_iff]
    have h1 : {v | ¬ v ∈ Q} = Qᶜ := rfl
    have hpre : (fun u : Fin n → ℝ => u ∘ Tuple.sort u) ⁻¹' Qᶜ = Qᶜ := by
      ext u
      simp only [Set.mem_preimage, Set.mem_compl_iff, hQ, Set.mem_univ_pi, Function.comp_apply]
      constructor
      · intro h h'; exact h fun i => h' _
      · intro h h'; exact h fun i => by simpa using h' ((Tuple.sort u).symm i)
    rw [h1, hν, Measure.map_apply (measurable_sort_map n) hQm.compl, hpre, pi_uniform_eq,
      Measure.smul_apply, Measure.restrict_apply hQm.compl, Set.compl_inter_self, measure_empty,
      smul_zero]
  have hnn : 0 ≤ᵐ[ν] fun v : Fin n → ℝ => v i0 :=
    hQae.mono fun v hv => ((Set.mem_univ_pi.1 hv) i0).1.le
  have hintg : Integrable (fun v : Fin n → ℝ => v i0) ν := by
    refine Integrable.of_bound (continuous_apply i0).aestronglyMeasurable t
      (hQae.mono fun v hv => ?_)
    have := (Set.mem_univ_pi.1 hv) i0
    rw [Real.norm_eq_abs, abs_le]
    exact ⟨by linarith [this.1], this.2.le⟩
  rw [hintg.integral_eq_integral_meas_lt hnn]
  set G : ℝ → ℝ := fun p => ∑ j ∈ Finset.range (m + 1), (n.choose j : ℝ) * p ^ j * (1 - p) ^ (n - j)
    with hG
  have htail : ∀ a ∈ Set.Ioi (0:ℝ), ν.real {v | a < v i0} = G (min a t / t) := by
    intro a ha
    have hmeasA : MeasurableSet {v : Fin n → ℝ | a < v i0} :=
      measurableSet_lt measurable_const (measurable_pi_apply i0)
    rw [hν, map_measureReal_apply (measurable_sort_map n) hmeasA]
    have hset : (fun u : Fin n → ℝ => u ∘ Tuple.sort u) ⁻¹' {v | a < v i0}
        = ⋃ j ∈ Finset.range (m + 1),
            {u : Fin n → ℝ | (Finset.univ.filter (fun i => u i ≤ a)).card = j} := by
      ext u
      simp only [Set.mem_preimage, Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_range,
        exists_prop]
      rw [monotone_lt_iff_card n (Tuple.monotone_sort u) i0 a, card_filter_perm_eq]
      constructor
      · intro h; exact ⟨_, by simp only [hi0] at h; omega, rfl⟩
      · rintro ⟨j, hj, rfl⟩; simp only [hi0]; omega
    rw [hset, measureReal_biUnion_finset]
    · rw [hG]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [pi_count_binomial, uniform_real_Iic ht (le_of_lt ha)]
    · intro j _ j' _ hjj'
      refine Set.disjoint_left.2 fun u hu hu' => hjj' ?_
      simp only [Set.mem_ofPred_eq] at hu hu'
      rw [← hu, ← hu']
    · exact fun j _ => measurableSet_count_eq n a j
  rw [setIntegral_congr_fun measurableSet_Ioi htail]
  rw [setIntegral_eq_of_subset_of_forall_sdiff_eq_zero measurableSet_Ioi Set.Ioc_subset_Ioi_self]
  swap
  · intro a ha
    have hat : t < a := by
      by_contra h
      exact ha.2 ⟨ha.1, not_lt.1 h⟩
    rw [min_eq_right hat.le, div_self ht.ne', hG]
    refine Finset.sum_eq_zero fun j hj => ?_
    rw [Finset.mem_range] at hj
    rw [sub_self, zero_pow (by omega), mul_zero]
  rw [setIntegral_congr_fun measurableSet_Ioc (g := fun a => G (a / t))
    (fun a ha => by simp only; rw [min_eq_left ha.2]),
    ← intervalIntegral.integral_of_le ht.le, intervalIntegral.integral_comp_div G ht.ne',
    zero_div, div_self ht.ne', smul_eq_mul]
  simp only [hG]
  rw [intervalIntegral.integral_finsetSum]
  · have hterm : ∀ j ∈ Finset.range (m + 1),
        ∫ x in (0:ℝ)..1, (n.choose j : ℝ) * x ^ j * (1 - x) ^ (n - j) = 1 / ((n:ℝ) + 1) := by
      intro j hj
      rw [Finset.mem_range] at hj
      simp_rw [mul_assoc]
      rw [intervalIntegral.integral_const_mul, choose_mul_beta n j (by omega)]
    rw [Finset.sum_congr rfl hterm, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    push_cast
    field_simp
  · intro j _
    exact (by fun_prop : Continuous fun x : ℝ => (n.choose j : ℝ) * x ^ j * (1 - x) ^ (n - j))
      |>.intervalIntegrable _ _

/-- The count in an early window is binomial. Given exactly n arrivals by time t, and a time a
with 0 ≤ a ≤ t, the chance that exactly j of the n arrivals come by time a is
`C(n, j) p^j (1 - p)^(n - j)` with `p = a / t`. -/
theorem count_before_a_given_count_is_binomial
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (rate t : ℝ) (hrate : 0 < rate) (ht : 0 < t)
    (E : ℕ → Ω → ℝ) (hmeas : ∀ i, Measurable (E i)) (hind : iIndepFun E μ)
    (hexp : ∀ i, μ.map (E i) = expMeasure rate) (n j : ℕ) (a : ℝ) (ha0 : 0 ≤ a) (hat : a ≤ t) :
    (μ[|{ω | ∑ i ∈ Finset.range n, E i ω ≤ t ∧ t < ∑ i ∈ Finset.range (n + 1), E i ω}]).real
        {ω | ((Finset.range n).filter
              (fun k => ∑ i ∈ Finset.range (k + 1), E i ω ≤ a)).card = j}
      = (n.choose j : ℝ) * (a / t) ^ j * (1 - a / t) ^ (n - j) := by
  set T : Ω → Fin n → ℝ := fun ω (k : Fin n) => ∑ i ∈ Finset.range ((k : ℕ) + 1), E i ω with hTdef
  have hTm : Measurable T := measurable_pi_iff.2 fun k =>
    Finset.measurable_sum _ fun i _ => hmeas i
  have hcard : ∀ (P : ℕ → Prop) [DecidablePred P],
      ((Finset.range n).filter P).card = (Finset.univ.filter (fun i : Fin n => P i)).card := by
    intro P _
    rw [← Nat.Iio_eq_range, ← Fin.map_valEmbedding_univ, Finset.filter_map, Finset.card_map]
    rfl
  have hset : {ω | ((Finset.range n).filter
              (fun k => ∑ i ∈ Finset.range (k + 1), E i ω ≤ a)).card = j}
      = T ⁻¹' {u : Fin n → ℝ | (Finset.univ.filter (fun i => u i ≤ a)).card = j} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, hTdef]
    rw [hcard]
  have := isProbabilityMeasure_expMeasure hrate
  have hIoo0 : volume (Set.Ioo (0:ℝ) t) ≠ 0 := by simp [ht]
  have hIooT : volume (Set.Ioo (0:ℝ) t) ≠ ⊤ := by simp
  have : IsProbabilityMeasure ((volume : Measure ℝ)[|Set.Ioo 0 t]) :=
    cond_isProbabilityMeasure_of_finite hIoo0 hIooT
  rw [hset, ← map_measureReal_apply hTm (measurableSet_count_eq n a j),
    arrival_times_given_count_are_sorted_uniforms μ rate t hrate ht E hmeas hind hexp n,
    map_measureReal_apply (measurable_sort_map n) (measurableSet_count_eq n a j),
    sort_preimage_count, pi_count_binomial, uniform_real_Iic ht ha0, min_eq_left hat]

-- Switchboard: 4 calls in one hour (t = 1 hour = 60 minutes).
-- Height of the joint density: 4! / 1^4 = 24 per hour^4.
example : (Nat.factorial 4 : ℚ) / 1 ^ 4 = 24 := by norm_num [Nat.factorial]
-- One call in each quarter-hour: 4! × (1/4)^4 = 24/256 = 0.093750.
example : (Nat.factorial 4 : ℚ) * (1 / 4) ^ 4 = 24 / 256 := by norm_num [Nat.factorial]
-- Mean call times k × 60 / (4 + 1): 12, 24, 36 and 48 minutes.
example : (1 : ℚ) * 60 / (4 + 1) = 12 ∧ (2 : ℚ) * 60 / (4 + 1) = 24 ∧
    (3 : ℚ) * 60 / (4 + 1) = 36 ∧ (4 : ℚ) * 60 / (4 + 1) = 48 := by norm_num
-- First quarter-hour empty: (1 - 15/60)^4 = (3/4)^4 = 81/256 = 0.316406...
example : (1 - (15 : ℚ) / 60) ^ 4 = 81 / 256 := by norm_num
-- Gap from call 2 to call 3 over 20 minutes: (1 - 20/60)^4 = (2/3)^4 = 16/81 = 0.197531...
example : (1 - (20 : ℚ) / 60) ^ 4 = 16 / 81 := by norm_num
-- Exactly 2 of the 4 in the first half-hour: C(4, 2) × (1/2)^4 = 6/16 = 0.375.
example : (Nat.choose 4 2 : ℚ) * (1 / 2) ^ 2 * (1 - 1 / 2) ^ (4 - 2) = 6 / 16 := by
  norm_num [Nat.choose]
-- The whole first-half law, 0 to 4 calls: 1/16, 4/16, 6/16, 4/16, 1/16.
example : (List.range 5).map (fun j => (Nat.choose 4 j : ℚ) * (1 / 2) ^ j * (1 / 2) ^ (4 - j))
    = [1 / 16, 4 / 16, 6 / 16, 4 / 16, 1 / 16] := by
  norm_num [List.range_succ, Nat.choose]
-- Mistake row: the first call read as one uniform draw, chance after 15 minutes 1 - 15/60 = 3/4.
example : 1 - (15 : ℚ) / 60 = 3 / 4 := by norm_num
-- Rising rate (2 an hour, then 6): 2 of 4 in the first half with chance C(4, 2) (1/4)^2 (3/4)^2
-- = 54/256 = 0.2109375, and the first call averages
-- 60 (0.4 (1 - (3/4)^5) + (3/4)^5 / 7.5) = 1293/64 = 20.203125 minutes.
example : (Nat.choose 4 2 : ℚ) * (1 / 4) ^ 2 * (3 / 4) ^ 2 = 54 / 256 := by norm_num [Nat.choose]
example : (60 : ℚ) * (2 / 5 * (1 - (3 / 4) ^ 5) + (3 / 4) ^ 5 / (15 / 2)) = 1293 / 64 := by
  norm_num
-- Forgetting n!: density 1 on the ordered times gives total chance 1/4! = 1/24.
example : (1 : ℚ) / Nat.factorial 4 = 1 / 24 := by norm_num [Nat.factorial]

#print axioms arrival_times_given_count_are_sorted_uniforms
#print axioms mean_kth_arrival_given_count
#print axioms count_before_a_given_count_is_binomial
