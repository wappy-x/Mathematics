-- The maximal function: every smoothing by an even, falling kernel of area 1 returns an Lp function at almost every point, because the maximal function caps it and obeys the strong bound.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib

open MeasureTheory Filter Topology Set

/-- The Hardy-Littlewood maximal function on the line:
`Mf(x) = sup over h > 0 of (1 / 2h) * ∫ over (x - h, x + h) of |f|`, as an extended
non-negative number (it may be infinite). -/
noncomputable def maximalFunction (f : ℝ → ℝ) (x : ℝ) : ENNReal :=
  ⨆ (h : ℝ) (_ : 0 < h), (ENNReal.ofReal (2 * h))⁻¹ * ∫⁻ s in Ioo (x - h) (x + h), ‖f s‖ₑ

/-- One window is bounded by the maximal function. -/

lemma hlmf_window_le (f : ℝ → ℝ) (x r : ℝ) :
    ∫⁻ s in Ioo (x - r) (x + r), ‖f s‖ₑ ≤ volume (Ioo (x - r) (x + r)) * maximalFunction f x := by
  rcases le_or_gt r 0 with hr | hr
  · have : Ioo (x - r) (x + r) = ∅ := Ioo_eq_empty (by linarith)
    simp [this]
  rw [Real.volume_Ioo, show x + r - (x - r) = 2 * r by ring]
  have h1 : (ENNReal.ofReal (2 * r))⁻¹ * ∫⁻ s in Ioo (x - r) (x + r), ‖f s‖ₑ
      ≤ maximalFunction f x :=
    le_iSup₂ (f := fun (h : ℝ) (_ : 0 < h) =>
      (ENNReal.ofReal (2 * h))⁻¹ * ∫⁻ s in Ioo (x - h) (x + h), ‖f s‖ₑ) r hr
  have h0 : ENNReal.ofReal (2 * r) ≠ 0 := by simp; linarith
  have ht : ENNReal.ofReal (2 * r) ≠ ⊤ := ENNReal.ofReal_ne_top
  calc ∫⁻ s in Ioo (x - r) (x + r), ‖f s‖ₑ
      = ENNReal.ofReal (2 * r) * ((ENNReal.ofReal (2 * r))⁻¹ * ∫⁻ s in Ioo (x - r) (x + r), ‖f s‖ₑ) := by
        rw [← mul_assoc, ENNReal.mul_inv_cancel h0 ht, one_mul]
    _ ≤ _ := by gcongr

#print axioms hlmf_window_le

/-- A set closed under moving closer to `x` is bounded by the maximal function. -/

lemma hlmf_star_le (f : ℝ → ℝ) (x : ℝ) (S : Set ℝ)
    (hS : ∀ s ∈ S, ∀ s', |s' - x| ≤ |s - x| → s' ∈ S) :
    ∫⁻ s in S, ‖f s‖ₑ ≤ volume S * maximalFunction f x := by
  rcases S.eq_empty_or_nonempty with hE | hne
  · simp [hE]
  by_cases hb : BddAbove ((fun s => |s - x|) '' S)
  · set r := sSup ((fun s => |s - x|) '' S) with hr
    have hsub1 : Ioo (x - r) (x + r) ⊆ S := by
      intro s' hs'
      have hlt : |s' - x| < r := by
        rw [abs_lt]; constructor <;> linarith [hs'.1, hs'.2]
      obtain ⟨d, ⟨s, hs, rfl⟩, hd⟩ := exists_lt_of_lt_csSup (hne.image _) hlt
      exact hS s hs s' hd.le
    have hsub2 : S ⊆ Icc (x - r) (x + r) := by
      intro s hs
      have : |s - x| ≤ r := le_csSup hb ⟨s, hs, rfl⟩
      rw [abs_le] at this
      constructor <;> linarith
    calc ∫⁻ s in S, ‖f s‖ₑ ≤ ∫⁻ s in Icc (x - r) (x + r), ‖f s‖ₑ := lintegral_mono_set hsub2
      _ = ∫⁻ s in Ioo (x - r) (x + r), ‖f s‖ₑ := setLIntegral_congr Ioo_ae_eq_Icc.symm
      _ ≤ volume (Ioo (x - r) (x + r)) * maximalFunction f x := hlmf_window_le f x r
      _ ≤ volume S * maximalFunction f x := by gcongr
  · have hall : ∀ n : ℕ, Ioo (x - n) (x + n) ⊆ S := by
      intro n s' hs'
      rw [not_bddAbove_iff] at hb
      obtain ⟨d, ⟨s, hs, rfl⟩, hd⟩ := hb n
      refine hS s hs s' ?_
      have : |s' - x| < n := by rw [abs_lt]; constructor <;> linarith [hs'.1, hs'.2]
      linarith
    have hU : S = univ := by
      refine eq_univ_of_forall fun s' => ?_
      obtain ⟨n, hn⟩ := exists_nat_gt |s' - x|
      apply hall n
      rw [abs_lt] at hn; constructor <;> linarith
    subst hU
    by_cases hM : maximalFunction f x = 0
    · have hw : ∀ n : ℕ, ∫⁻ s in Ioo (x - n) (x + n), ‖f s‖ₑ = 0 := fun n =>
        le_antisymm ((hlmf_window_le f x n).trans (by rw [hM, mul_zero])) (zero_le)
      have hU2 : (univ : Set ℝ) = ⋃ n : ℕ, Ioo (x - n) (x + n) := by
        refine (eq_univ_of_forall fun s' => ?_).symm
        obtain ⟨n, hn⟩ := exists_nat_gt |s' - x|
        rw [abs_lt] at hn
        exact mem_iUnion.2 ⟨n, by constructor <;> linarith⟩
      calc ∫⁻ s in univ, ‖f s‖ₑ ≤ ∑' n : ℕ, ∫⁻ s in Ioo (x - n) (x + n), ‖f s‖ₑ := by
            rw [hU2]; exact lintegral_iUnion_le _ _
        _ = 0 := by simp [hw]
        _ ≤ _ := zero_le
    · rw [Real.volume_univ, ENNReal.top_mul hM]; exact le_top

#print axioms hlmf_star_le

lemma hlmf_K_abs {K : ℝ → ℝ} (hKeven : ∀ u, K (-u) = K u) (u : ℝ) : K |u| = K u := by
  rcases le_or_gt 0 u with h | h
  · rw [abs_of_nonneg h]
  · rw [abs_of_neg h, hKeven]

#print axioms hlmf_K_abs

lemma hlmf_K_mono {K : ℝ → ℝ} (hKeven : ∀ u, K (-u) = K u) (hKanti : AntitoneOn K (Ici 0))
    {u v : ℝ} (h : |u| ≤ |v|) : K v ≤ K u := by
  rw [← hlmf_K_abs hKeven u, ← hlmf_K_abs hKeven v]
  exact hKanti (mem_Ici.2 (abs_nonneg u)) (mem_Ici.2 (abs_nonneg v)) h

#print axioms hlmf_K_mono

lemma hlmf_K_meas {K : ℝ → ℝ} (hKeven : ∀ u, K (-u) = K u) (hKanti : AntitoneOn K (Ici 0)) :
    Measurable K := by
  have hA : Antitone (fun v : ℝ => K (max v 0)) := by
    intro a b hab
    exact hKanti (mem_Ici.2 (le_max_right _ _)) (mem_Ici.2 (le_max_right _ _))
      (max_le_max hab le_rfl)
  have : K = (fun v : ℝ => K (max v 0)) ∘ (fun u => |u|) := by
    funext u; simp [hlmf_K_abs hKeven]
  rw [this]; exact hA.measurable.comp measurable_abs

#print axioms hlmf_K_meas

lemma hlmf_scale (F : ℝ → ENNReal) (x : ℝ) {ε : ℝ} (hε : 0 < ε) :
    ∫⁻ s, F ((x - s) / ε) = ENNReal.ofReal ε * ∫⁻ u, F u := by
  have h1 : ∫⁻ s, F ((x - s) / ε) = ∫⁻ s, F (s / ε) :=
    lintegral_sub_left_eq_self (fun s => F (s / ε)) x
  rw [h1]
  have h : ε⁻¹ ≠ 0 := inv_ne_zero hε.ne'
  have := lintegral_map_equiv F (Homeomorph.mulLeft₀ ε⁻¹ h).toMeasurableEquiv (μ := volume)
  simp only [Homeomorph.toMeasurableEquiv_coe, Homeomorph.coe_mulLeft₀] at this
  rw [Real.map_volume_mul_left h, lintegral_smul_measure, inv_inv, abs_of_pos hε] at this
  rw [← smul_eq_mul, this]
  simp [div_eq_inv_mul]

#print axioms hlmf_scale

lemma hlmf_kernel_mass {K : ℝ → ℝ} (x : ℝ) {ε : ℝ} (hε : 0 < ε) :
    ∫⁻ s, ENNReal.ofReal (K ((x - s) / ε) / ε) = ∫⁻ u, ENNReal.ofReal (K u) := by
  have h0 : ENNReal.ofReal ε ≠ 0 := by simpa using hε
  have e : ∀ s, ENNReal.ofReal (K ((x - s) / ε) / ε)
      = ENNReal.ofReal (K ((x - s) / ε)) * (ENNReal.ofReal ε)⁻¹ := fun s => by
    rw [ENNReal.ofReal_div_of_pos hε, div_eq_mul_inv]
  simp_rw [e]
  rw [lintegral_mul_const' _ _ (ENNReal.inv_ne_top.2 h0),
    hlmf_scale (fun u => ENNReal.ofReal (K u)) x hε, mul_comm, ← mul_assoc,
    ENNReal.inv_mul_cancel h0 ENNReal.ofReal_ne_top, one_mul]

#print axioms hlmf_kernel_mass

lemma hlmf_eLpNorm_K {K : ℝ → ℝ} (hK0 : ∀ u, 0 ≤ K u) (hKm : Measurable K) :
    eLpNorm K 1 volume = ∫⁻ u, ENNReal.ofReal (K u) := by
  rw [eLpNorm_one_eq_lintegral_enorm hKm.aestronglyMeasurable]
  congr 1; funext u; exact Real.enorm_eq_ofReal (hK0 u)

#print axioms hlmf_eLpNorm_K

lemma hlmf_kernel_le {K : ℝ → ℝ} (hK0 : ∀ u, 0 ≤ K u) (hKeven : ∀ u, K (-u) = K u)
    (hKanti : AntitoneOn K (Ici 0)) {f : ℝ → ℝ} (hf : AEMeasurable (fun s => ‖f s‖ₑ))
    (x : ℝ) {ε : ℝ} (hε : 0 < ε) :
    ∫⁻ s, ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s‖ₑ
      ≤ eLpNorm K 1 volume * maximalFunction f x := by
  have hKm := hlmf_K_meas hKeven hKanti
  set g : ℝ → ℝ := fun s => K ((x - s) / ε) / ε with hg
  have hgm : Measurable g :=
    (hKm.comp ((measurable_const.sub measurable_id).div_const ε)).div_const ε
  have hg0 : ∀ s, 0 ≤ g s := fun s => div_nonneg (hK0 _) hε.le
  have hlc : ∀ s, ENNReal.ofReal (g s) = ∫⁻ t in Ioi 0, (Iio (g s)).indicator 1 t := by
    intro s
    rw [lintegral_indicator_one measurableSet_Iio, Measure.restrict_apply measurableSet_Iio,
      Iio_inter_Ioi, Real.volume_Ioo, sub_zero]
  have hswap : ∫⁻ s, ENNReal.ofReal (g s) * ‖f s‖ₑ
      = ∫⁻ t in Ioi 0, ∫⁻ s, (Iio (g s)).indicator 1 t * ‖f s‖ₑ := by
    have : ∀ s, ENNReal.ofReal (g s) * ‖f s‖ₑ
        = ∫⁻ t in Ioi 0, (Iio (g s)).indicator 1 t * ‖f s‖ₑ := by
      intro s
      rw [hlc s, lintegral_mul_const' _ _ enorm_ne_top]
    simp_rw [this]
    apply lintegral_lintegral_swap
    have hset : MeasurableSet {p : ℝ × ℝ | p.2 < g p.1} :=
      measurableSet_lt measurable_snd (hgm.comp measurable_fst)
    have e : Function.uncurry (fun s t => (Iio (g s)).indicator (1 : ℝ → ENNReal) t * ‖f s‖ₑ)
        = fun p : ℝ × ℝ => {p : ℝ × ℝ | p.2 < g p.1}.indicator 1 p * ‖f p.1‖ₑ := by
      funext p; simp [indicator, Function.uncurry]
    rw [e]
    exact ((measurable_one.indicator hset).aemeasurable).mul
      (hf.comp_quasiMeasurePreserving (Measure.quasiMeasurePreserving_fst))
  have hinner : ∀ t, ∫⁻ s, (Iio (g s)).indicator 1 t * ‖f s‖ₑ
      ≤ volume {s | t < g s} * maximalFunction f x := by
    intro t
    have e : (fun s => (Iio (g s)).indicator (1 : ℝ → ENNReal) t * ‖f s‖ₑ)
        = {s | t < g s}.indicator (fun s => ‖f s‖ₑ) := by
      funext s; by_cases h : t < g s <;> simp [indicator, h]
    rw [e, lintegral_indicator (measurableSet_lt measurable_const hgm)]
    apply hlmf_star_le
    intro s hs s' hs'
    simp only [mem_ofPred_eq] at hs ⊢
    refine lt_of_lt_of_le hs ?_
    simp only [hg]
    gcongr
    apply hlmf_K_mono hKeven hKanti
    rw [abs_div, abs_div, abs_sub_comm x s', abs_sub_comm x s]
    gcongr
  have hanti : Antitone (fun t => volume {s | t < g s}) := by
    intro a b hab
    exact measure_mono fun s (hs : b < g s) => (lt_of_le_of_lt hab hs : a < g s)
  calc ∫⁻ s, ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s‖ₑ
      = ∫⁻ t in Ioi 0, ∫⁻ s, (Iio (g s)).indicator 1 t * ‖f s‖ₑ := hswap
    _ ≤ ∫⁻ t in Ioi 0, volume {s | t < g s} * maximalFunction f x := lintegral_mono hinner
    _ = (∫⁻ t in Ioi 0, volume {s | t < g s}) * maximalFunction f x :=
        lintegral_mul_const _ hanti.measurable
    _ = eLpNorm K 1 volume * maximalFunction f x := by
        rw [← lintegral_eq_lintegral_meas_lt volume (ae_of_all _ hg0) hgm.aemeasurable,
          hlmf_eLpNorm_K hK0 hKm]
        congr 1
        exact hlmf_kernel_mass x hε

#print axioms hlmf_kernel_le

lemma hlmf_notMem_Ioo {x r s : ℝ} : s ∉ Ioo (x - r) (x + r) ↔ r ≤ |x - s| := by
  rw [mem_Ioo, not_and_or, not_lt, not_lt, le_abs']
  constructor <;> rintro (h | h) <;> first | (left; linarith) | (right; linarith)

#print axioms hlmf_notMem_Ioo

lemma hlmf_tail {K : ℝ → ℝ} (hKm : Measurable K) (hKint : Integrable K) :
    Tendsto (fun R : ℝ => ∫⁻ u, {u | R ≤ |u|}.indicator (fun u => ENNReal.ofReal (K u)) u)
      atTop (𝓝 0) := by
  have h := tendsto_lintegral_filter_of_dominated_convergence (μ := volume) (l := atTop)
    (F := fun R : ℝ => {u | R ≤ |u|}.indicator (fun u => ENNReal.ofReal (K u))) (f := fun _ => 0)
    (fun u => ENNReal.ofReal (K u))
    (Eventually.of_forall fun R => (ENNReal.measurable_ofReal.comp hKm).indicator
      (measurableSet_le measurable_const measurable_abs))
    (Eventually.of_forall fun R => ae_of_all _ fun u => indicator_le_self _ _ u)
    hKint.lintegral_lt_top.ne
    (ae_of_all _ fun u => by
      refine tendsto_const_nhds.congr' ?_
      filter_upwards [eventually_gt_atTop |u|] with R hR
      rw [indicator_of_notMem (show u ∉ {u | R ≤ |u|} from fun h => absurd h (not_le.2 hR))])
  simpa using h

#print axioms hlmf_tail

lemma hlmf_Ka {K : ℝ → ℝ} (hKeven : ∀ u, K (-u) = K u)
    (hKanti : AntitoneOn K (Ici 0)) (hKint : Integrable K) :
    Tendsto (fun a : ℝ => ENNReal.ofReal (K a) * ENNReal.ofReal a) atTop (𝓝 0) := by
  have hKm := hlmf_K_meas hKeven hKanti
  have ht := (hlmf_tail hKm hKint).comp (tendsto_id.atTop_div_const (by norm_num : (0 : ℝ) < 2))
  have h2 := ENNReal.Tendsto.const_mul ht (a := 2) (Or.inr (by norm_num))
  rw [mul_zero] at h2
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds h2
    (Eventually.of_forall fun _ => zero_le) ?_
  filter_upwards [eventually_gt_atTop 0] with a ha
  simp only [Function.comp, id]
  have e : ENNReal.ofReal a = 2 * ENNReal.ofReal (a / 2) := by
    rw [show (2 : ENNReal) = ENNReal.ofReal 2 by simp, ← ENNReal.ofReal_mul (by norm_num)]
    congr 1; ring
  rw [e, mul_left_comm]
  gcongr
  calc ENNReal.ofReal (K a) * ENNReal.ofReal (a / 2)
      = ∫⁻ u in Ioc (a / 2) a, ENNReal.ofReal (K a) := by
        rw [setLIntegral_const, Real.volume_Ioc, show a - a / 2 = a / 2 by ring]
    _ ≤ ∫⁻ u in Ioc (a / 2) a, ENNReal.ofReal (K u) := by
        refine setLIntegral_mono' measurableSet_Ioc fun u hu => ?_
        exact ENNReal.ofReal_le_ofReal
          (hKanti (mem_Ici.2 (by linarith [hu.1])) (mem_Ici.2 ha.le) hu.2)
    _ = ∫⁻ u, (Ioc (a / 2) a).indicator (fun u => ENNReal.ofReal (K u)) u :=
        (lintegral_indicator measurableSet_Ioc _).symm
    _ ≤ ∫⁻ u, {u | a / 2 ≤ |u|}.indicator (fun u => ENNReal.ofReal (K u)) u := by
        refine lintegral_mono fun u => indicator_le_indicator_of_subset (fun v hv => ?_)
          (fun _ => zero_le) u
        simp only [mem_ofPred_eq]
        rw [abs_of_pos (by linarith [hv.1])]; exact hv.1.le

#print axioms hlmf_Ka

/-- The weak bound, with constant 3, from the Vitali covering lemma. -/

lemma hlmf_weak (g : ℝ → ℝ) {a : ℝ} (ha : 0 < a) :
    volume {x | ENNReal.ofReal a < maximalFunction g x}
      ≤ ENNReal.ofReal (3 / a) * ∫⁻ s, ‖g s‖ₑ := by
  set C := ∫⁻ s, ‖g s‖ₑ with hC
  by_cases hCt : C = ⊤
  · rw [hCt, ENNReal.mul_top (by simp; positivity)]; exact le_top
  set S := {x | ENNReal.ofReal a < maximalFunction g x} with hS
  have hex : ∀ x : S, ∃ h : ℝ, 0 < h ∧
      ENNReal.ofReal (2 * h * a) < ∫⁻ s in Ioo (x.1 - h) (x.1 + h), ‖g s‖ₑ := by
    rintro ⟨x, hx⟩
    simp only [hS, mem_ofPred_eq, maximalFunction, lt_iSup_iff] at hx
    obtain ⟨h, hh, hlt⟩ := hx
    refine ⟨h, hh, ?_⟩
    have h0 : ENNReal.ofReal (2 * h) ≠ 0 := by simp; linarith
    have := ENNReal.mul_lt_mul_left h0 ENNReal.ofReal_ne_top hlt
    rw [mul_comm ((ENNReal.ofReal (2 * h))⁻¹), mul_assoc,
      ENNReal.inv_mul_cancel h0 ENNReal.ofReal_ne_top, mul_one,
      ← ENNReal.ofReal_mul ha.le] at this
    convert this using 2; ring
  choose h hpos hI using hex
  have hR : ∀ i : S, h i ≤ C.toReal / (2 * a) := by
    intro i
    have h1 : ENNReal.ofReal (2 * h i * a) < C := (hI i).trans_le (setLIntegral_le_lintegral _ _)
    rw [ENNReal.ofReal_lt_iff_lt_toReal (by nlinarith [hpos i]) hCt] at h1
    rw [le_div_iff₀ (by positivity)]; linarith
  have hne : ∀ i : S, (Ioo (i.1 - h i) (i.1 + h i)).Nonempty := fun i =>
    ⟨i.1, by constructor <;> linarith [hpos i]⟩
  obtain ⟨u, -, hdisj, hcov⟩ := Vitali.exists_disjoint_subfamily_covering_enlargement
    (fun i : S => Ioo (i.1 - h i) (i.1 + h i)) univ h 2 one_lt_two (fun i _ => (hpos i).le)
    (C.toReal / (2 * a)) (fun i _ => hR i) (fun i _ => hne i)
  have hcount : u.Countable := hdisj.countable_of_isOpen (fun _ _ => isOpen_Ioo)
    (fun i _ => hne i)
  have hcover : S ⊆ ⋃ b ∈ u, Ioo (b.1 - 3 * h b) (b.1 + 3 * h b) := by
    intro x hx
    obtain ⟨b, hbu, ⟨y, hy1, hy2⟩, hle⟩ := hcov ⟨x, hx⟩ (mem_univ _)
    refine mem_biUnion hbu ?_
    simp only [mem_Ioo] at hy1 hy2 ⊢
    constructor <;> linarith [hy1.1, hy1.2, hy2.1, hy2.2]
  calc volume S ≤ volume (⋃ b ∈ u, Ioo (b.1 - 3 * h b) (b.1 + 3 * h b)) := measure_mono hcover
    _ ≤ ∑' b : u, volume (Ioo (b.1.1 - 3 * h b) (b.1.1 + 3 * h b)) :=
        measure_biUnion_le _ hcount _
    _ ≤ ∑' b : u, ENNReal.ofReal (3 / a) * ∫⁻ s in Ioo (b.1.1 - h b) (b.1.1 + h b), ‖g s‖ₑ := by
        refine tsum_le_tsum fun b => ?_
        rw [Real.volume_Ioo]
        calc ENNReal.ofReal (b.1.1 + 3 * h b - (b.1.1 - 3 * h b))
            = ENNReal.ofReal (3 / a) * ENNReal.ofReal (2 * h b * a) := by
              rw [← ENNReal.ofReal_mul (by positivity)]; congr 1; field_simp; ring
          _ ≤ _ := by gcongr; exact (hI b).le
    _ = ENNReal.ofReal (3 / a) * ∫⁻ s in ⋃ b ∈ u, Ioo (b.1 - h b) (b.1 + h b), ‖g s‖ₑ := by
        rw [ENNReal.tsum_mul_left, lintegral_biUnion hcount (fun _ _ => measurableSet_Ioo) hdisj]
    _ ≤ ENNReal.ofReal (3 / a) * C := by gcongr; exact setLIntegral_le_lintegral _ _

#print axioms hlmf_weak

/-- The weak bound applied to the part of `f` above half the level. -/

lemma hlmf_weak_trunc (f : ℝ → ℝ) {t : ℝ} (ht : 0 < t) :
    volume {x | ENNReal.ofReal t < maximalFunction f x}
      ≤ ENNReal.ofReal (6 / t) * ∫⁻ s, {s | t / 2 < ‖f s‖}.indicator (fun s => ‖f s‖ₑ) s := by
  set g := {s | t / 2 < ‖f s‖}.indicator f with hg
  have hpt : ∀ s, ‖f s‖ₑ ≤ ‖g s‖ₑ + ENNReal.ofReal (t / 2) := by
    intro s
    by_cases hs : t / 2 < ‖f s‖
    · have : g s = f s := by rw [hg, indicator_of_mem (show s ∈ {s | t / 2 < ‖f s‖} from hs)]
      rw [this]; exact le_self_add
    · have : g s = 0 := by rw [hg, indicator_of_notMem (show s ∉ {s | t / 2 < ‖f s‖} from hs)]
      rw [this, enorm_zero, zero_add, ← ofReal_norm]
      exact ENNReal.ofReal_le_ofReal (not_lt.1 hs)
  have hM : ∀ x, maximalFunction f x ≤ maximalFunction g x + ENNReal.ofReal (t / 2) := by
    intro x
    apply iSup₂_le
    intro h hh
    have h0 : ENNReal.ofReal (2 * h) ≠ 0 := by simp; linarith
    calc (ENNReal.ofReal (2 * h))⁻¹ * ∫⁻ s in Ioo (x - h) (x + h), ‖f s‖ₑ
        ≤ (ENNReal.ofReal (2 * h))⁻¹
            * ∫⁻ s in Ioo (x - h) (x + h), (‖g s‖ₑ + ENNReal.ofReal (t / 2)) := by
          gcongr with s; exact hpt s
      _ = (ENNReal.ofReal (2 * h))⁻¹ * (∫⁻ s in Ioo (x - h) (x + h), ‖g s‖ₑ)
            + ENNReal.ofReal (t / 2) := by
          rw [lintegral_add_right _ measurable_const, setLIntegral_const, Real.volume_Ioo,
            show x + h - (x - h) = 2 * h by ring, mul_add,
            mul_comm (ENNReal.ofReal (t / 2)), ← mul_assoc,
            ENNReal.inv_mul_cancel h0 ENNReal.ofReal_ne_top, one_mul]
      _ ≤ maximalFunction g x + ENNReal.ofReal (t / 2) := by
          have hle : (ENNReal.ofReal (2 * h))⁻¹ * ∫⁻ s in Ioo (x - h) (x + h), ‖g s‖ₑ
              ≤ maximalFunction g x :=
            le_iSup₂ (f := fun (h : ℝ) (_ : 0 < h) =>
              (ENNReal.ofReal (2 * h))⁻¹ * ∫⁻ s in Ioo (x - h) (x + h), ‖g s‖ₑ) h hh
          exact add_le_add hle le_rfl
  have hsub : {x | ENNReal.ofReal t < maximalFunction f x}
      ⊆ {x | ENNReal.ofReal (t / 2) < maximalFunction g x} := by
    intro x hx
    simp only [mem_ofPred_eq] at hx ⊢
    by_contra hc
    replace hc := not_lt.1 hc
    have : maximalFunction f x ≤ ENNReal.ofReal t := by
      calc _ ≤ _ := hM x
        _ ≤ ENNReal.ofReal (t / 2) + ENNReal.ofReal (t / 2) := by gcongr
        _ = ENNReal.ofReal t := by
          rw [← ENNReal.ofReal_add (by positivity) (by positivity)]; ring_nf
    exact absurd hx (not_lt.2 this)
  calc _ ≤ _ := measure_mono hsub
    _ ≤ ENNReal.ofReal (3 / (t / 2)) * ∫⁻ s, ‖g s‖ₑ := hlmf_weak g (by positivity)
    _ = _ := by
        congr 1
        · congr 1; field_simp; norm_num
        · congr 1; funext s; rw [hg, enorm_indicator_eq_indicator_enorm]

#print axioms hlmf_weak_trunc

lemma hlmf_rpow_integral {p y : ℝ} (hp : 1 < p) (hy : 0 ≤ y) :
    ∫⁻ t in Ioo 0 y, ENNReal.ofReal (t ^ (p - 2)) = ENNReal.ofReal (y ^ (p - 1) / (p - 1)) := by
  have hint : IntegrableOn (fun t : ℝ => t ^ (p - 2)) (Ioo 0 y) := by
    have := intervalIntegral.intervalIntegrable_rpow' (a := 0) (b := y) (r := p - 2) (by linarith)
    exact (intervalIntegrable_iff_integrableOn_Ioo_of_le hy).1 this
  rw [← ofReal_integral_eq_lintegral_ofReal hint
    (ae_restrict_of_forall_mem measurableSet_Ioo fun t ht => Real.rpow_nonneg ht.1.le _)]
  congr 1
  rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hy,
    integral_rpow (Or.inl (by linarith)), show p - 2 + 1 = p - 1 by ring,
    Real.zero_rpow (by linarith), sub_zero]

#print axioms hlmf_rpow_integral

lemma hlmf_const_identity {p y : ℝ} (hp : 1 < p) (hy : 0 ≤ y) :
    p * (6 * ((2 * y) ^ (p - 1) / (p - 1)) * y) = 2 ^ p * (3 * p / (p - 1)) * y ^ p := by
  have hp1 : p - 1 ≠ 0 := by linarith
  rcases hy.eq_or_lt with h0 | hpos
  · subst h0; simp [Real.zero_rpow (show p ≠ 0 by linarith)]
  rw [Real.mul_rpow (by norm_num) hy, Real.rpow_sub_one (by norm_num : (2 : ℝ) ≠ 0),
    Real.rpow_sub_one hpos.ne']
  field_simp
  ring

#print axioms hlmf_const_identity

lemma hlmf_strong_lintegral {p : ℝ} (hp : 1 < p) {f : ℝ → ℝ}
    (hf : AEStronglyMeasurable f volume) :
    ∫⁻ x, maximalFunction f x ^ p
      ≤ ENNReal.ofReal (2 ^ p * (3 * p / (p - 1))) * ∫⁻ s, ‖f s‖ₑ ^ p := by
  have hp0 : 0 < p := by linarith
  obtain ⟨g, hgm, hgle, hgeq⟩ :=
    exists_measurable_le_lintegral_eq (μ := volume) (fun x => maximalFunction f x ^ p)
  rw [hgeq]
  have hsup : ∀ x, g x = ⨆ n : ℕ, g x ⊓ (n : ENNReal) := by
    intro x; rw [← inf_iSup_eq, ENNReal.iSup_natCast, inf_top_eq]
  rw [show ∫⁻ x, g x = ∫⁻ x, ⨆ n : ℕ, g x ⊓ (n : ENNReal) from lintegral_congr hsup]
  rw [lintegral_iSup (f := fun (n : ℕ) x => g x ⊓ (n : ENNReal))
    (fun n => hgm.inf measurable_const)
    (fun n m hnm x => inf_le_inf_left _ (Nat.cast_le.2 hnm))]
  apply iSup_le
  intro n
  set m := fun x => g x ⊓ (n : ENNReal) with hm
  set H : ℝ → ℝ := fun x => (m x).toReal ^ (1 / p) with hH
  have hm_ne : ∀ x, m x ≠ ⊤ := fun x =>
    ne_top_of_le_ne_top (ENNReal.natCast_ne_top n) inf_le_right
  have hHp : ∀ x, ENNReal.ofReal (H x ^ p) = m x := by
    intro x
    simp only [hH]
    rw [← Real.rpow_mul ENNReal.toReal_nonneg, one_div_mul_cancel hp0.ne', Real.rpow_one,
      ENNReal.ofReal_toReal (hm_ne x)]
  have hHm : Measurable H := ((hgm.inf measurable_const).ennreal_toReal).pow_const _
  have hH0 : ∀ x, 0 ≤ H x := fun x => Real.rpow_nonneg ENNReal.toReal_nonneg _
  set J : ℝ → ENNReal := fun t =>
    ∫⁻ s, {s | t / 2 < ‖f s‖}.indicator (fun s => ‖f s‖ₑ) s with hJ
  set Φ : ℝ → ℝ → ENNReal := fun t s =>
    (if t < 2 * ‖f s‖ then ENNReal.ofReal (6 * t ^ (p - 2)) else 0) * ENNReal.ofReal ‖f s‖
    with hΦ
  have hstep : ∀ t ∈ Ioi (0 : ℝ), volume {x | t < H x} * ENNReal.ofReal (t ^ (p - 1))
      ≤ ∫⁻ s, Φ t s := by
    intro t ht
    have ht : 0 < t := ht
    have h1 : volume {x | t < H x} ≤ ENNReal.ofReal (6 / t) * J t := by
      refine (measure_mono ?_).trans (hlmf_weak_trunc f ht)
      intro x hx
      simp only [mem_ofPred_eq] at hx ⊢
      by_contra hc
      replace hc := not_lt.1 hc
      have a1 : t ^ p < H x ^ p := Real.rpow_lt_rpow ht.le hx hp0
      have a2 : ENNReal.ofReal (t ^ p) < m x := by
        rw [← hHp x]
        exact (ENNReal.ofReal_lt_ofReal_iff (lt_of_le_of_lt (by positivity) a1)).2 a1
      have a3 : m x ≤ maximalFunction f x ^ p := (inf_le_left).trans (hgle x)
      have a4 : maximalFunction f x ^ p ≤ ENNReal.ofReal (t ^ p) := by
        rw [← ENNReal.ofReal_rpow_of_nonneg ht.le hp0.le]
        exact ENNReal.rpow_le_rpow hc hp0.le
      exact absurd (a2.trans_le (a3.trans a4)) (lt_irrefl _)
    calc volume {x | t < H x} * ENNReal.ofReal (t ^ (p - 1))
        ≤ ENNReal.ofReal (6 / t) * J t * ENNReal.ofReal (t ^ (p - 1)) := by gcongr
      _ = ∫⁻ s, Φ t s := by
        simp only [hJ]
        rw [← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top,
          ← lintegral_mul_const' _ _ ENNReal.ofReal_ne_top]
        congr 1; funext s
        have e1 : (t / 2 < ‖f s‖) ↔ (t < 2 * ‖f s‖) := by constructor <;> intro h <;> linarith
        have e2 : 6 / t * t ^ (p - 1) = 6 * t ^ (p - 2) := by
          rw [show p - 2 = (p - 1) - 1 by ring, Real.rpow_sub_one ht.ne' (p - 1)]; ring
        simp only [hΦ]
        by_cases hs : t < 2 * ‖f s‖
        · have hs' : t / 2 < ‖f s‖ := e1.2 hs
          rw [indicator_of_mem (show s ∈ {s | t / 2 < ‖f s‖} from hs'), if_pos hs, ← e2,
            ENNReal.ofReal_mul (by positivity), ofReal_norm]
          ring
        · have hs' : ¬ t / 2 < ‖f s‖ := fun h => hs (e1.1 h)
          rw [indicator_of_notMem (show s ∉ {s | t / 2 < ‖f s‖} from hs'), if_neg hs]
          simp
  have hΦm : AEMeasurable (Function.uncurry Φ) ((volume.restrict (Ioi (0 : ℝ))).prod volume) := by
    have hF : Measurable (fun q : ℝ × ℝ =>
        (if q.1 < 2 * q.2 then ENNReal.ofReal (6 * q.1 ^ (p - 2)) else 0) * ENNReal.ofReal q.2) := by
      refine Measurable.mul ?_ (ENNReal.measurable_ofReal.comp measurable_snd)
      refine Measurable.ite (measurableSet_lt measurable_fst (measurable_const.mul measurable_snd))
        ?_ measurable_const
      exact ENNReal.measurable_ofReal.comp (measurable_const.mul (measurable_fst.pow_const _))
    have hpair : AEMeasurable (fun q : ℝ × ℝ => (q.1, ‖f q.2‖))
        ((volume.restrict (Ioi (0 : ℝ))).prod volume) :=
      measurable_fst.aemeasurable.prodMk
        (hf.norm.aemeasurable.comp_quasiMeasurePreserving Measure.quasiMeasurePreserving_snd)
    exact hF.comp_aemeasurable hpair
  have hinner : ∀ s, ∫⁻ t in Ioi 0, Φ t s
      = ENNReal.ofReal (6 * ((2 * ‖f s‖) ^ (p - 1) / (p - 1)) * ‖f s‖) := by
    intro s
    have e : (fun t => Φ t s) = fun t =>
        (Iio (2 * ‖f s‖)).indicator (fun t => ENNReal.ofReal (6 * t ^ (p - 2))) t
          * ENNReal.ofReal ‖f s‖ := by
      funext t; simp [hΦ, indicator]
    rw [e, lintegral_mul_const' _ _ ENNReal.ofReal_ne_top, setLIntegral_indicator measurableSet_Iio,
      Iio_inter_Ioi]
    simp_rw [ENNReal.ofReal_mul (show (0 : ℝ) ≤ 6 by norm_num)]
    rw [lintegral_const_mul' _ _ ENNReal.ofReal_ne_top, hlmf_rpow_integral hp (by positivity),
      ← ENNReal.ofReal_mul (by norm_num), ← ENNReal.ofReal_mul (by positivity)]
  calc ∫⁻ x, m x = ∫⁻ x, ENNReal.ofReal (H x ^ p) := by simp_rw [hHp]
    _ = ENNReal.ofReal p * ∫⁻ t in Ioi 0, volume {x | t < H x} * ENNReal.ofReal (t ^ (p - 1)) :=
        lintegral_rpow_eq_lintegral_meas_lt_mul volume (ae_of_all _ hH0) hHm.aemeasurable hp0
    _ ≤ ENNReal.ofReal p * ∫⁻ t in Ioi 0, ∫⁻ s, Φ t s := by
        gcongr ENNReal.ofReal p * ?_
        exact setLIntegral_mono' measurableSet_Ioi hstep
    _ = ENNReal.ofReal p * ∫⁻ s, ∫⁻ t in Ioi 0, Φ t s := by
        rw [lintegral_lintegral_swap hΦm]
    _ = ∫⁻ s, ENNReal.ofReal (2 ^ p * (3 * p / (p - 1))) * ‖f s‖ₑ ^ p := by
        rw [← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
        congr 1; funext s
        rw [hinner s, ← ENNReal.ofReal_mul hp0.le, hlmf_const_identity hp (norm_nonneg _),
          ENNReal.ofReal_mul (by positivity), ← ofReal_norm,
          ENNReal.ofReal_rpow_of_nonneg (norm_nonneg _) hp0.le]
    _ = ENNReal.ofReal (2 ^ p * (3 * p / (p - 1))) * ∫⁻ s, ‖f s‖ₑ ^ p :=
        lintegral_const_mul' _ _ ENNReal.ofReal_ne_top

#print axioms hlmf_strong_lintegral

/-- Smoothings converge almost everywhere: let `K` be a kernel that is never negative, even,
never rising as `|u|` grows, integrable, with area 1, and let `K_ε(u) = K(u/ε)/ε`. For `f` of
finite p-norm with `1 ≤ p < ∞`, the smoothings `(K_ε * f)(x)` converge to `f(x)` as `ε`
shrinks to 0, at every point outside a set of length zero. -/
theorem falling_kernel_smoothing_tendsto_ae {K : ℝ → ℝ} (hK0 : ∀ u, 0 ≤ K u)
    (hKeven : ∀ u, K (-u) = K u) (hKanti : AntitoneOn K (Ici 0)) (hKint : Integrable K)
    (hK1 : ∫ u, K u = 1) {p : ENNReal} (hp1 : 1 ≤ p) (hptop : p ≠ ⊤) {f : ℝ → ℝ}
    (hf : MemLp f p) :
    ∀ᵐ x, Tendsto (fun ε : ℝ => ∫ s, K ((x - s) / ε) / ε * f s) (𝓝[>] 0) (𝓝 (f x)) := by
  have hKm := hlmf_K_meas hKeven hKanti
  have hloc : LocallyIntegrable f volume := hf.locallyIntegrable hp1
  have hfm : AEStronglyMeasurable f volume := hf.aestronglyMeasurable
  have hp0 : p ≠ 0 := (lt_of_lt_of_le one_pos hp1).ne'
  have hP : 1 ≤ p.toReal := by
    have := ENNReal.toReal_mono hptop hp1; simpa using this
  have hNp : ∫⁻ s, ‖f s‖ₑ ^ p.toReal ≠ ⊤ := by
    have := hf.eLpNorm_lt_top
    rw [eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hptop hfm] at this
    exact ((ENNReal.rpow_lt_top_iff_of_pos (by positivity)).1 this).ne
  have hKmass : eLpNorm K 1 volume = 1 := by
    rw [hlmf_eLpNorm_K hK0 hKm, ← ofReal_integral_eq_lintegral_ofReal hKint (ae_of_all _ hK0),
      hK1, ENNReal.ofReal_one]
  have hLeb := (IsUnifLocDoublingMeasure.vitaliFamily (volume : Measure ℝ) 1)
    |>.ae_tendsto_lintegral_enorm_sub_div hloc
  filter_upwards [hLeb] with x hx
  have hx2 : Tendsto (fun h : ℝ => (∫⁻ y in Metric.closedBall x h, ‖f y - f x‖ₑ)
      / volume (Metric.closedBall x h)) (𝓝[>] 0) (𝓝 0) := by
    refine hx.comp (IsUnifLocDoublingMeasure.tendsto_closedBall_filterAt volume
      (fun _ => x) id tendsto_id ?_)
    filter_upwards [self_mem_nhdsWithin] with h (hh : 0 < h)
    simp [hh.le]
  set D : ℝ → ENNReal := fun ε =>
    ∫⁻ s, ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s - f x‖ₑ with hD
  have hDlim : Tendsto D (𝓝[>] 0) (𝓝 0) := by
    rw [ENNReal.tendsto_nhds_zero]
    intro η hη
    have hη2 : 0 < η / 2 := ENNReal.half_pos hη.ne'
    obtain ⟨u, hu, hu'⟩ := mem_nhdsGT_iff_exists_Ioo_subset.1
      ((ENNReal.tendsto_nhds_zero.1 hx2) (η / 2) hη2)
    have hu0 : (0 : ℝ) < u := hu
    set r0 := u / 2 with hr0
    have hr0pos : 0 < r0 := by positivity
    have hball : ∀ h, 0 < h → h ≤ r0 →
        ∫⁻ y in Ioo (x - h) (x + h), ‖f y - f x‖ₑ ≤ η / 2 * ENNReal.ofReal (2 * h) := by
      intro h hh hhr
      have h1 : (∫⁻ y in Metric.closedBall x h, ‖f y - f x‖ₑ)
          / volume (Metric.closedBall x h) ≤ η / 2 := hu' ⟨hh, by linarith⟩
      rw [Real.volume_closedBall, ENNReal.div_le_iff (by simp; linarith) ENNReal.ofReal_ne_top,
        Real.closedBall_eq_Icc] at h1
      exact (lintegral_mono_set Ioo_subset_Icc_self).trans h1
    set φ : ℝ → ℝ := (Ioo (x - r0) (x + r0)).indicator (fun s => f s - f x) with hφ
    have hφm : AEStronglyMeasurable φ volume :=
      (hfm.sub aestronglyMeasurable_const).indicator measurableSet_Ioo
    have hMφ : maximalFunction φ x ≤ η / 2 := by
      apply iSup₂_le
      intro h hh
      have h0 : ENNReal.ofReal (2 * h) ≠ 0 := by simp; linarith
      have hI : ∫⁻ s in Ioo (x - h) (x + h), ‖φ s‖ₑ ≤ η / 2 * ENNReal.ofReal (2 * h) := by
        simp_rw [hφ, enorm_indicator_eq_indicator_enorm]
        rcases le_or_gt h r0 with hle | hgt
        · calc _ ≤ ∫⁻ s in Ioo (x - h) (x + h), ‖f s - f x‖ₑ :=
                lintegral_mono (fun s => indicator_le_self _ _ s)
            _ ≤ _ := hball h hh hle
        · calc _ ≤ ∫⁻ s, (Ioo (x - r0) (x + r0)).indicator (fun s => ‖f s - f x‖ₑ) s :=
                setLIntegral_le_lintegral _ _
            _ = ∫⁻ s in Ioo (x - r0) (x + r0), ‖f s - f x‖ₑ := lintegral_indicator measurableSet_Ioo _
            _ ≤ η / 2 * ENNReal.ofReal (2 * r0) := hball r0 hr0pos le_rfl
            _ ≤ η / 2 * ENNReal.ofReal (2 * h) := by
                gcongr
      calc (ENNReal.ofReal (2 * h))⁻¹ * ∫⁻ s in Ioo (x - h) (x + h), ‖φ s‖ₑ
          ≤ (ENNReal.ofReal (2 * h))⁻¹ * (η / 2 * ENNReal.ofReal (2 * h)) := by gcongr
        _ = η / 2 := by
          rw [mul_comm, mul_assoc, ENNReal.mul_inv_cancel h0 ENNReal.ofReal_ne_top, mul_one]
    set far := (Ioo (x - r0) (x + r0))ᶜ with hfar
    set T : ℝ → ENNReal := fun ε =>
      ∫⁻ s, far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s with hT
    set B : ℝ → ENNReal := fun ε => ENNReal.ofReal (K (r0 / ε) / ε) with hB
    set Np := ∫⁻ s, ‖f s‖ₑ ^ p.toReal with hNpdef
    have hdiv : Tendsto (fun ε : ℝ => r0 / ε) (𝓝[>] 0) atTop := by
      simpa [div_eq_mul_inv] using Tendsto.const_mul_atTop hr0pos tendsto_inv_nhdsGT_zero
    have hTlim : Tendsto T (𝓝[>] 0) (𝓝 0) := by
      refine ((hlmf_tail hKm hKint).comp hdiv).congr' ?_
      filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
      have h0 : ENNReal.ofReal ε ≠ 0 := by simpa using hε
      have e : ∀ s, far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s
          = {u | r0 / ε ≤ |u|}.indicator (fun u => ENNReal.ofReal (K u)) ((x - s) / ε)
            * (ENNReal.ofReal ε)⁻¹ := by
        intro s
        have hiff : s ∈ far ↔ (x - s) / ε ∈ {u | r0 / ε ≤ |u|} := by
          simp only [hfar, mem_compl_iff, hlmf_notMem_Ioo, mem_ofPred_eq, abs_div,
            abs_of_pos hε]
          exact (div_le_div_iff_of_pos_right hε).symm
        by_cases hs : s ∈ far
        · rw [indicator_of_mem hs, indicator_of_mem (hiff.1 hs), ENNReal.ofReal_div_of_pos hε,
            div_eq_mul_inv]
        · rw [indicator_of_notMem hs, indicator_of_notMem (fun h => hs (hiff.2 h)), zero_mul]
      simp only [Function.comp, hT]
      simp_rw [e]
      rw [lintegral_mul_const' _ _ (ENNReal.inv_ne_top.2 h0),
        hlmf_scale (fun u => {u | r0 / ε ≤ |u|}.indicator (fun u => ENNReal.ofReal (K u)) u) x hε,
        mul_comm, ← mul_assoc, ENNReal.inv_mul_cancel h0 ENNReal.ofReal_ne_top, one_mul]
    have hBlim : Tendsto B (𝓝[>] 0) (𝓝 0) := by
      have h1 := ENNReal.Tendsto.mul_const ((hlmf_Ka hKeven hKanti hKint).comp hdiv)
        (b := ENNReal.ofReal r0⁻¹) (Or.inr ENNReal.ofReal_ne_top)
      rw [zero_mul] at h1
      refine h1.congr' ?_
      filter_upwards [self_mem_nhdsWithin] with ε (hε : 0 < ε)
      simp only [Function.comp, hB]
      rw [← ENNReal.ofReal_mul (hK0 _), ← ENNReal.ofReal_mul
        (mul_nonneg (hK0 _) (div_pos hr0pos hε).le)]
      congr 1
      field_simp
    have hrest : Tendsto (fun ε => T ε * (1 + ‖f x‖ₑ) + B ε * Np) (𝓝[>] 0) (𝓝 0) := by
      have h1 := ENNReal.Tendsto.mul_const hTlim (b := 1 + ‖f x‖ₑ)
        (Or.inr (ENNReal.add_ne_top.2 ⟨ENNReal.one_ne_top, enorm_ne_top⟩))
      have h2 := ENNReal.Tendsto.mul_const hBlim (b := Np) (Or.inr hNp)
      simpa using h1.add h2
    filter_upwards [(ENNReal.tendsto_nhds_zero.1 hrest) (η / 2) hη2, self_mem_nhdsWithin]
      with ε hε1 (hε : 0 < ε)
    have hkm : Measurable (fun s => K ((x - s) / ε) / ε) :=
      (hKm.comp ((measurable_const.sub measurable_id).div_const ε)).div_const ε
    have hpt : ∀ s, ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s - f x‖ₑ ≤
        ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖φ s‖ₑ
        + far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s * (1 + ‖f x‖ₑ)
        + B ε * ‖f s‖ₑ ^ p.toReal := by
      intro s
      by_cases hs : s ∈ Ioo (x - r0) (x + r0)
      · have : φ s = f s - f x := by rw [hφ, indicator_of_mem hs]
        rw [this, add_assoc]; exact le_self_add
      · have h1 : φ s = 0 := by rw [hφ, indicator_of_notMem hs]
        have h2 : far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s
            = ENNReal.ofReal (K ((x - s) / ε) / ε) := indicator_of_mem hs _
        rw [h1, h2, enorm_zero, mul_zero, zero_add]
        have hkB : ENNReal.ofReal (K ((x - s) / ε) / ε) ≤ B ε := by
          apply ENNReal.ofReal_le_ofReal
          apply div_le_div_of_nonneg_right _ hε.le
          apply hlmf_K_mono hKeven hKanti
          rw [abs_of_pos (div_pos hr0pos hε), abs_div, abs_of_pos hε]
          exact div_le_div_of_nonneg_right (hlmf_notMem_Ioo.1 hs) hε.le
        have hfs : ‖f s‖ₑ ≤ 1 + ‖f s‖ₑ ^ p.toReal := by
          rcases le_total ‖f s‖ₑ 1 with h | h
          · exact h.trans le_self_add
          · calc ‖f s‖ₑ = ‖f s‖ₑ ^ (1 : ℝ) := (ENNReal.rpow_one _).symm
              _ ≤ ‖f s‖ₑ ^ p.toReal := ENNReal.rpow_le_rpow_of_exponent_le h hP
              _ ≤ _ := le_add_self
        calc ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s - f x‖ₑ
            ≤ ENNReal.ofReal (K ((x - s) / ε) / ε) * (‖f s‖ₑ + ‖f x‖ₑ) := by
              gcongr; exact enorm_sub_le
          _ ≤ ENNReal.ofReal (K ((x - s) / ε) / ε) * ((1 + ‖f s‖ₑ ^ p.toReal) + ‖f x‖ₑ) := by
              gcongr
          _ = ENNReal.ofReal (K ((x - s) / ε) / ε) * (1 + ‖f x‖ₑ)
              + ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s‖ₑ ^ p.toReal := by ring
          _ ≤ _ := by gcongr
    have hA : AEMeasurable (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖φ s‖ₑ) :=
      (ENNReal.measurable_ofReal.comp hkm).aemeasurable.mul hφm.enorm
    have hC : AEMeasurable (fun s =>
        far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s * (1 + ‖f x‖ₑ)) :=
      (((ENNReal.measurable_ofReal.comp hkm).indicator
        measurableSet_Ioo.compl).aemeasurable).mul_const _
    calc D ε ≤ ∫⁻ s, (ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖φ s‖ₑ
          + far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s * (1 + ‖f x‖ₑ)
          + B ε * ‖f s‖ₑ ^ p.toReal) := lintegral_mono hpt
      _ = (∫⁻ s, ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖φ s‖ₑ)
          + T ε * (1 + ‖f x‖ₑ) + B ε * Np := by
          have hAC : AEMeasurable (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖φ s‖ₑ
              + far.indicator (fun s => ENNReal.ofReal (K ((x - s) / ε) / ε)) s
                * (1 + ‖f x‖ₑ)) := hA.add hC
          rw [lintegral_add_left' hAC, lintegral_add_left' hA,
            lintegral_mul_const' _ _ (ENNReal.add_ne_top.2 ⟨ENNReal.one_ne_top, enorm_ne_top⟩),
            lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
      _ ≤ η / 2 + η / 2 := by
          rw [add_assoc]
          gcongr
          calc _ ≤ eLpNorm K 1 volume * maximalFunction φ x :=
                hlmf_kernel_le hK0 hKeven hKanti hφm.enorm x hε
            _ ≤ 1 * (η / 2) := by rw [hKmass]; gcongr
            _ = η / 2 := one_mul _
      _ = η := ENNReal.add_halves η
  rw [tendsto_iff_edist_tendsto_0]
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hDlim
    (Eventually.of_forall fun _ => zero_le) ?_
  filter_upwards [(ENNReal.tendsto_nhds_zero.1 hDlim) 1 one_pos, self_mem_nhdsWithin]
    with ε hDε (hε : 0 < ε)
  set k : ℝ → ℝ := fun s => K ((x - s) / ε) / ε with hk
  have hkm : Measurable k :=
    (hKm.comp ((measurable_const.sub measurable_id).div_const ε)).div_const ε
  have hk0 : ∀ s, 0 ≤ k s := fun s => div_nonneg (hK0 _) hε.le
  have hkint : Integrable k := by
    refine ⟨hkm.aestronglyMeasurable, ?_⟩
    show ∫⁻ s, ‖k s‖ₑ < ⊤
    simp_rw [Real.enorm_eq_ofReal (hk0 _)]
    rw [hlmf_kernel_mass x hε]; exact hKint.lintegral_lt_top
  have hk1 : ∫ s, k s = 1 := by
    simp only [hk]
    rw [integral_div, integral_sub_left_eq_self (fun s => K (s / ε)) volume x,
      Measure.integral_comp_div, abs_of_pos hε, hK1, smul_eq_mul, mul_one, div_self hε.ne']
  have hen : ∀ s, ‖k s * (f s - f x)‖ₑ = ENNReal.ofReal (k s) * ‖f s - f x‖ₑ := fun s => by
    rw [enorm_mul, Real.enorm_eq_ofReal (hk0 s)]
  have hint2 : Integrable (fun s => k s * (f s - f x)) := by
    refine ⟨hkm.aestronglyMeasurable.mul (hfm.sub aestronglyMeasurable_const), ?_⟩
    show ∫⁻ s, ‖k s * (f s - f x)‖ₑ < ⊤
    simp_rw [hen]; exact lt_of_le_of_lt hDε ENNReal.one_lt_top
  have heq : ∫ s, k s * f s = (∫ s, k s * (f s - f x)) + f x := by
    have : (fun s => k s * f s) = fun s => k s * (f s - f x) + k s * f x := by funext s; ring
    rw [this, integral_add hint2 (hkint.mul_const _), integral_mul_const, hk1, one_mul]
  rw [edist_eq_enorm_sub, heq, add_sub_cancel_right]
  calc ‖∫ s, k s * (f s - f x)‖ₑ ≤ ∫⁻ s, ‖k s * (f s - f x)‖ₑ :=
        enorm_integral_le_lintegral_enorm _
    _ = D ε := by simp_rw [hen]; rfl

/-- The cap on smoothers: if `K` is never negative, even, never rising as `|u|` grows and
integrable, then at every point `x` where `Mf(x)` is finite, and for every width `ε > 0`, the
smoothing integral converges absolutely and `|(K_ε * f)(x)| ≤ ‖K‖₁ · Mf(x)`. -/
theorem smoothing_le_kernel_area_mul_maximalFunction {K : ℝ → ℝ} (hK0 : ∀ u, 0 ≤ K u)
    (hKeven : ∀ u, K (-u) = K u) (hKanti : AntitoneOn K (Ici 0)) (hKint : Integrable K)
    {f : ℝ → ℝ} (hf : LocallyIntegrable f) {x : ℝ} (hMx : maximalFunction f x < ⊤)
    {ε : ℝ} (hε : 0 < ε) :
    Integrable (fun s => K ((x - s) / ε) / ε * f s) ∧
      ENNReal.ofReal |∫ s, K ((x - s) / ε) / ε * f s|
        ≤ eLpNorm K 1 volume * maximalFunction f x := by
  have hKm := hlmf_K_meas hKeven hKanti
  have hfm : AEStronglyMeasurable f volume := hf.aestronglyMeasurable
  have hbound := hlmf_kernel_le hK0 hKeven hKanti hfm.enorm x hε
  have hKfin : eLpNorm K 1 volume < ⊤ := (memLp_one_iff_integrable.2 hKint).eLpNorm_lt_top
  have hmeas : AEStronglyMeasurable (fun s => K ((x - s) / ε) / ε * f s) volume :=
    ((hKm.comp ((measurable_const.sub measurable_id).div_const ε)).div_const
      ε).aestronglyMeasurable.mul hfm
  have hen : ∀ s, ‖K ((x - s) / ε) / ε * f s‖ₑ
      = ENNReal.ofReal (K ((x - s) / ε) / ε) * ‖f s‖ₑ := by
    intro s; rw [enorm_mul, Real.enorm_eq_ofReal (div_nonneg (hK0 _) hε.le)]
  have hfin : ∫⁻ s, ‖K ((x - s) / ε) / ε * f s‖ₑ
      ≤ eLpNorm K 1 volume * maximalFunction f x := by
    simp_rw [hen]; exact hbound
  refine ⟨⟨hmeas, ?_⟩, ?_⟩
  · exact lt_of_le_of_lt hfin (ENNReal.mul_lt_top hKfin hMx)
  · rw [← Real.enorm_eq_ofReal_abs]
    exact (enorm_integral_le_lintegral_enorm _).trans hfin

/-- The strong bound: for `1 < p < ∞` and `f` of finite p-norm,
`‖Mf‖_p ≤ C_p ‖f‖_p` with `C_p = 2 (3p / (p - 1))^(1/p)`. -/
theorem maximalFunction_strong_bound {p : ℝ} (hp : 1 < p) {f : ℝ → ℝ}
    (hf : MemLp f (ENNReal.ofReal p)) :
    (∫⁻ x, maximalFunction f x ^ p) ^ (1 / p)
      ≤ ENNReal.ofReal (2 * (3 * p / (p - 1)) ^ (1 / p)) * eLpNorm f (ENNReal.ofReal p) volume := by
  have hp0 : 0 < p := by linarith
  have hfm : AEStronglyMeasurable f volume := hf.aestronglyMeasurable
  have hmain := hlmf_strong_lintegral hp hfm
  rw [eLpNorm_eq_lintegral_rpow_enorm_toReal (by simp; linarith) ENNReal.ofReal_ne_top hfm,
    ENNReal.toReal_ofReal hp0.le]
  calc (∫⁻ x, maximalFunction f x ^ p) ^ (1 / p)
      ≤ (ENNReal.ofReal (2 ^ p * (3 * p / (p - 1))) * ∫⁻ s, ‖f s‖ₑ ^ p) ^ (1 / p) :=
        ENNReal.rpow_le_rpow hmain (by positivity)
    _ = _ := by
      have h3 : 0 ≤ 3 * p / (p - 1) := div_nonneg (by linarith) (by linarith)
      rw [ENNReal.mul_rpow_of_nonneg _ _ (by positivity),
        ENNReal.ofReal_rpow_of_nonneg (by positivity) (by positivity)]
      congr 2
      rw [Real.mul_rpow (by positivity) h3, ← Real.rpow_mul (by norm_num),
        mul_one_div_cancel hp0.ne', Real.rpow_one]

-- The day's rain: drizzle 1 mm/h for 6 h, two bursts of 60 mm/h for 1/10 h, shower 10 mm/h for 1 h.
example : (1 : ℚ) * 6 + 60 * (1 / 10) + 60 * (1 / 10) + 10 * 1 = 28 := by norm_num
-- Mf(14.5) = 10: the window of half-width 3/5 h holds both bursts, 12 mm over 6/5 h.
example : (12 : ℚ) / (2 * (3 / 5)) = 10 := by norm_num
-- At noon the window from 6:00 to 18:00 holds 24 mm in 12 h: 2 mm/h.
example : ((8 - 6) * 1 + 12 + 10 : ℚ) / 12 = 2 := by norm_num
-- Weak bound on the whole day at level 8: 3 × 28 / 8 = 21/2 hours allowed.
example : (3 : ℚ) * 28 / 8 = 21 / 2 := by norm_num
-- One burst: Mf beats 8 mm/h out to z = 11/40 h, since 6 / (2 (11/40 + 1/10)) = 8.
example : (6 : ℚ) / (2 * (11 / 40 + 1 / 10)) = 8 := by norm_num
-- The storm's level set at 8 mm/h runs from 14 − 11/40 to 151/10 + 11/40: length 33/20 h,
-- above the 12/8 = 3/2 h a constant of 1 would allow, inside the 3 × 12/8 = 9/2 h allowed.
example : ((151 : ℚ) / 10 + 11 / 40) - (14 - 11 / 40) = 33 / 20 ∧ (12 : ℚ) / 8 < 33 / 20 ∧
    (33 : ℚ) / 20 ≤ 3 * 12 / 8 := by norm_num
-- At p = 2 the constant is C_2^2 = 3 × 2^2 × 2 / (2 − 1) = 24.
example : (3 : ℚ) * 2 ^ 2 * 2 / (2 - 1) = 24 := by norm_num
-- The record's jumps add up to 262 mm/h: 1 + 1 + 4 × 60 + 2 × 10.
example : 1 + 1 + 4 * 60 + 2 * 10 = 262 := by decide

#print axioms falling_kernel_smoothing_tendsto_ae
#print axioms smoothing_le_kernel_area_mul_maximalFunction
#print axioms maximalFunction_strong_bound
