-- Approximate identities: averaging a signal against a family of kernels with total weight 1, capped total size and weight that gathers at the centre returns the signal at every point where a bounded signal is continuous and in the mean for every signal in L^p with p finite, and smooth signals that vanish outside a bounded interval come within any tolerance of every such signal.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Normed.Lp.SmoothApprox
import Mathlib.MeasureTheory.Function.LpSpace.ContinuousCompMeasurePreserving
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.MeanInequalities
import Mathlib.MeasureTheory.Group.Measure
import Mathlib.MeasureTheory.Group.LIntegral
import Mathlib.MeasureTheory.Order.Group.Lattice

open MeasureTheory Filter Topology
open scoped ENNReal ContDiff

/-- The card's definition. A family `K ε`, one kernel for each width `ε > 0`, is an
approximate identity with size cap `M` when, for every width, the kernel can be integrated,
its total weight `∫ K_ε` is 1 and its total size `∫ |K_ε|` is at most `M`; and, for every
distance `δ > 0`, the size beyond `δ`, `∫_{|s| > δ} |K_ε|`, tends to 0 as `ε` shrinks to 0. -/
structure IsApproxIdentity (K : ℝ → ℝ → ℝ) (M : ℝ) : Prop where
  integrable : ∀ ε > 0, Integrable (K ε)
  total_weight_one : ∀ ε > 0, ∫ s, K ε s = 1
  total_size_le : ∀ ε > 0, ∫ s, |K ε s| ≤ M
  tail_to_zero : ∀ δ > 0,
    Tendsto (fun ε => ∫ s in {s : ℝ | δ < |s|}, |K ε s|) (𝓝[>] 0) (𝓝 0)

/-- The smoothed signal: `(K_ε * f)(x) = ∫ K_ε(s) f(x − s) ds`, the weighted average of `f`
around the time `x`. -/
noncomputable def smoothed (K : ℝ → ℝ → ℝ) (ε : ℝ) (f : ℝ → ℝ) (x : ℝ) : ℝ :=
  ∫ s, K ε s * f (x - s)

lemma ai_holder_weight {w h : ℝ → ℝ≥0∞} (hw : AEMeasurable w volume) (hh : AEMeasurable h volume)
    {q : ℝ} (hq : 1 ≤ q) :
    (∫⁻ s, w s * h s) ^ q ≤ (∫⁻ s, w s) ^ (q - 1) * ∫⁻ s, w s * h s ^ q := by
  have hq0 : 0 < q := by linarith
  have ha : 0 ≤ 1 - 1 / q := by
    rw [sub_nonneg, div_le_one hq0]; exact hq
  have hb : 0 ≤ 1 / q := by positivity
  have key := ENNReal.lintegral_mul_norm_pow_le hw (hw.mul (hh.pow_const q)) ha hb (by ring)
  have hpt : ∀ s, w s * h s = w s ^ (1 - 1 / q) * (w s * h s ^ q) ^ (1 / q) := by
    intro s
    rw [ENNReal.mul_rpow_of_nonneg _ _ hb, ← ENNReal.rpow_mul, mul_one_div_cancel hq0.ne',
      ENNReal.rpow_one, ← mul_assoc, ← ENNReal.rpow_add_of_nonneg _ _ ha hb, sub_add_cancel,
      ENNReal.rpow_one]
  calc (∫⁻ s, w s * h s) ^ q
      = (∫⁻ s, w s ^ (1 - 1 / q) * (w s * h s ^ q) ^ (1 / q)) ^ q := by
        rw [lintegral_congr fun s => hpt s]
    _ ≤ ((∫⁻ s, w s) ^ (1 - 1 / q) * (∫⁻ s, w s * h s ^ q) ^ (1 / q)) ^ q :=
        ENNReal.rpow_le_rpow key hq0.le
    _ = (∫⁻ s, w s) ^ (q - 1) * ∫⁻ s, w s * h s ^ q := by
        rw [ENNReal.mul_rpow_of_nonneg _ _ hq0.le, ← ENNReal.rpow_mul, ← ENNReal.rpow_mul,
          one_div_mul_cancel hq0.ne', ENNReal.rpow_one]
        congr 2
        field_simp

lemma ai_young {w : ℝ → ℝ≥0∞} {H : ℝ → ℝ → ℝ≥0∞} (hw : AEMeasurable w volume)
    (hH : Measurable (Function.uncurry H)) {q : ℝ} (hq : 1 ≤ q) :
    ∫⁻ x, (∫⁻ s, w s * H x s) ^ q ≤ (∫⁻ s, w s) ^ (q - 1) * ∫⁻ s, w s * ∫⁻ x, H x s ^ q := by
  have hprod : AEMeasurable (Function.uncurry fun x s => w s * H x s ^ q)
      (volume.prod volume) :=
    (hw.comp_quasiMeasurePreserving Measure.quasiMeasurePreserving_snd).mul
      (hH.pow_const q).aemeasurable
  calc ∫⁻ x, (∫⁻ s, w s * H x s) ^ q
      ≤ ∫⁻ x, (∫⁻ s, w s) ^ (q - 1) * ∫⁻ s, w s * H x s ^ q :=
        lintegral_mono fun x =>
          ai_holder_weight hw (hH.comp measurable_prodMk_left).aemeasurable hq
    _ = (∫⁻ s, w s) ^ (q - 1) * ∫⁻ x, ∫⁻ s, w s * H x s ^ q :=
        lintegral_const_mul'' _ hprod.lintegral_prod_right'
    _ = (∫⁻ s, w s) ^ (q - 1) * ∫⁻ s, ∫⁻ x, w s * H x s ^ q := by
        rw [lintegral_lintegral_swap hprod]
    _ = (∫⁻ s, w s) ^ (q - 1) * ∫⁻ s, w s * ∫⁻ x, H x s ^ q := by
        congr 1
        refine lintegral_congr fun s => ?_
        exact lintegral_const_mul _ ((hH.comp measurable_prodMk_right).pow_const q)

lemma ai_main_bound {k f : ℝ → ℝ} (hk : Integrable k) (hk1 : ∫ s, k s = 1) (hf : Measurable f)
    {q : ℝ} (hq : 1 ≤ q) :
    ∫⁻ x, ‖(∫ s, k s * f (x - s)) - f x‖ₑ ^ q ≤
      (∫⁻ s, ‖k s‖ₑ) ^ (q - 1) * ∫⁻ s, ‖k s‖ₑ * ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q := by
  have hpt : ∀ x, ‖(∫ s, k s * f (x - s)) - f x‖ₑ ≤ ∫⁻ s, ‖k s‖ₑ * ‖f (x - s) - f x‖ₑ := by
    intro x
    have hmeas : AEStronglyMeasurable (fun s => k s * f (x - s)) volume :=
      hk.aestronglyMeasurable.mul (hf.comp (measurable_const.sub measurable_id)).aestronglyMeasurable
    by_cases hI : Integrable (fun s => k s * f (x - s))
    · have : (∫ s, k s * f (x - s)) - f x = ∫ s, k s * (f (x - s) - f x) := by
        have e1 : ∫ s, k s * f x = f x := by rw [integral_mul_const, hk1, one_mul]
        calc (∫ s, k s * f (x - s)) - f x = (∫ s, k s * f (x - s)) - ∫ s, k s * f x := by
              rw [e1]
          _ = ∫ s, (k s * f (x - s) - k s * f x) := (integral_sub hI (hk.mul_const _)).symm
          _ = _ := by simp_rw [mul_sub]
      rw [this]
      refine (enorm_integral_le_lintegral_enorm _).trans (le_of_eq ?_)
      simp_rw [enorm_mul]
    · have hinf : ∫⁻ s, ‖k s * f (x - s)‖ₑ = ⊤ := by
        by_contra h
        exact hI ⟨hmeas, hasFiniteIntegral_iff_enorm.2 (lt_top_iff_ne_top.2 h)⟩
      have hkfin : ∫⁻ s, ‖k s‖ₑ ≠ ⊤ := (hasFiniteIntegral_iff_enorm.1 hk.2).ne
      have hle : ∫⁻ s, ‖k s * f (x - s)‖ₑ ≤
          (∫⁻ s, ‖k s‖ₑ * ‖f (x - s) - f x‖ₑ) + (∫⁻ s, ‖k s‖ₑ) * ‖f x‖ₑ := by
        rw [← lintegral_mul_const' _ _ enorm_ne_top,
          ← lintegral_add_right' _ (hk.aestronglyMeasurable.enorm.mul_const _)]
        refine lintegral_mono fun s => ?_
        rw [enorm_mul, ← mul_add]
        gcongr
        calc ‖f (x - s)‖ₑ = ‖(f (x - s) - f x) + f x‖ₑ := by rw [sub_add_cancel]
          _ ≤ _ := enorm_add_le _ _
      rw [hinf, top_le_iff] at hle
      have : ∫⁻ s, ‖k s‖ₑ * ‖f (x - s) - f x‖ₑ = ⊤ := by
        by_contra hne
        exact ENNReal.add_ne_top.2 ⟨hne, ENNReal.mul_ne_top hkfin enorm_ne_top⟩ hle
      rw [this]; exact le_top
  calc ∫⁻ x, ‖(∫ s, k s * f (x - s)) - f x‖ₑ ^ q
      ≤ ∫⁻ x, (∫⁻ s, ‖k s‖ₑ * ‖f (x - s) - f x‖ₑ) ^ q :=
        lintegral_mono fun x => ENNReal.rpow_le_rpow (hpt x) (by linarith)
    _ ≤ _ := ai_young (H := fun x s => ‖f (x - s) - f x‖ₑ) hk.aestronglyMeasurable.enorm
        (by fun_prop) hq

lemma ai_translate_tendsto {p : ℝ≥0∞} (hp1 : 1 ≤ p) (hp_fin : p ≠ ⊤) {f : ℝ → ℝ}
    (hf : MemLp f p volume) :
    Tendsto (fun s => eLpNorm (fun x => f (x - s) - f x) p volume) (𝓝 0) (𝓝 0) := by
  have : Fact (1 ≤ p) := ⟨hp1⟩
  let F := hf.toLp f
  let g : ℝ → C(ℝ, ℝ) := (ContinuousMap.mk (fun z : ℝ × ℝ => z.2 - z.1) (by fun_prop)).curry
  have hgc : Continuous g := ContinuousMap.continuous _
  have hgm : ∀ s, MeasurePreserving (g s) volume volume := fun s =>
    measurePreserving_sub_right volume s
  have hT := Filter.Tendsto.compMeasurePreservingLp (μ := volume) (f := fun _ : ℝ => F)
    tendsto_const_nhds (hgc.tendsto 0) hgm (hgm 0) hp_fin
  rw [tendsto_iff_edist_tendsto_0] at hT
  refine hT.congr' (Eventually.of_forall fun s => ?_)
  simp only
  rw [Lp.edist_def]
  apply eLpNorm_congr_ae
  have h1 := Lp.coeFn_compMeasurePreserving F (hgm s)
  have h2 := Lp.coeFn_compMeasurePreserving F (hgm 0)
  have h3 : (F : ℝ → ℝ) =ᵐ[volume] f := hf.coeFn_toLp
  have h4 := (hgm s).quasiMeasurePreserving.ae_eq_comp h3
  have h5 := (hgm 0).quasiMeasurePreserving.ae_eq_comp h3
  filter_upwards [h1, h2, h4, h5] with x e1 e2 e4 e5
  simp only [Pi.sub_apply, e1, e2, Function.comp_apply] at e4 e5 ⊢
  rw [e4, e5]
  simp [g]

lemma ai_tendsto_Lp_of_measurable (K : ℝ → ℝ → ℝ) (M : ℝ) (hK : IsApproxIdentity K M)
    (p : ℝ≥0∞) (hp1 : 1 ≤ p) (hp_fin : p ≠ ⊤) (f : ℝ → ℝ) (hf : MemLp f p volume)
    (hfm : Measurable f) :
    Tendsto (fun ε => eLpNorm (fun x => smoothed K ε f x - f x) p volume) (𝓝[>] 0) (𝓝 0) := by
  have hp0 : p ≠ 0 := (zero_lt_one.trans_le hp1).ne'
  set q := p.toReal with hq_def
  have hq1 : 1 ≤ q := by
    have := ENNReal.toReal_mono hp_fin hp1
    simpa using this
  have hq0 : 0 < q := by linarith
  have hM0 : 0 ≤ M :=
    (integral_nonneg fun s => abs_nonneg (K 1 s)).trans (hK.total_size_le 1 one_pos)
  have haesm : ∀ ε > 0, AEStronglyMeasurable (fun x => smoothed K ε f x - f x) volume := by
    intro ε hε
    refine AEStronglyMeasurable.sub ?_ hfm.aestronglyMeasurable
    unfold smoothed
    exact AEStronglyMeasurable.integral_prod_right'
      (f := fun z : ℝ × ℝ => K ε z.2 * f (z.1 - z.2))
      (((hK.integrable ε hε).aestronglyMeasurable.comp_quasiMeasurePreserving
        Measure.quasiMeasurePreserving_snd).mul
        (hfm.comp (measurable_fst.sub measurable_snd)).aestronglyMeasurable)
  have heq : ∀ ε > 0, eLpNorm (fun x => smoothed K ε f x - f x) p volume =
      (∫⁻ x, ‖smoothed K ε f x - f x‖ₑ ^ q) ^ (1 / q) := by
    intro ε hε
    rw [eLpNorm_eq_eLpNorm' hp0 hp_fin (haesm ε hε), eLpNorm'_eq_lintegral_enorm]
  suffices hI : Tendsto (fun ε => ∫⁻ x, ‖smoothed K ε f x - f x‖ₑ ^ q) (𝓝[>] 0) (𝓝 0) by
    have h2 : Tendsto (fun ε => (∫⁻ x, ‖smoothed K ε f x - f x‖ₑ ^ q) ^ (1 / q))
        (𝓝[>] 0) (𝓝 0) := by
      have := (ENNReal.continuous_rpow_const (y := 1 / q)).tendsto 0
      rw [ENNReal.zero_rpow_of_pos (by positivity)] at this
      exact this.comp hI
    refine h2.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with ε hε
    exact (heq ε hε).symm
  have hshift : ∀ s, AEStronglyMeasurable (fun x => f (x - s) - f x) volume := fun s =>
    ((hfm.comp (measurable_id.sub measurable_const)).sub hfm).aestronglyMeasurable
  have hJeq : ∀ s, ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q =
      eLpNorm (fun x => f (x - s) - f x) p volume ^ q := by
    intro s
    rw [eLpNorm_eq_eLpNorm' hp0 hp_fin (hshift s), eLpNorm'_eq_lintegral_enorm,
      ← ENNReal.rpow_mul, one_div_mul_cancel hq0.ne', ENNReal.rpow_one]
  have hJlim : Tendsto (fun s => ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q) (𝓝 0) (𝓝 0) := by
    have h := ai_translate_tendsto hp1 hp_fin hf
    have hc := (ENNReal.continuous_rpow_const (y := q)).tendsto 0
    rw [ENNReal.zero_rpow_of_pos hq0] at hc
    simp_rw [hJeq]
    exact hc.comp h
  set C : ℝ≥0∞ := (2 * eLpNorm f p volume) ^ q with hC_def
  have hCfin : C ≠ ⊤ :=
    ENNReal.rpow_ne_top_of_nonneg hq0.le (ENNReal.mul_ne_top (by simp) hf.eLpNorm_ne_top)
  have hJC : ∀ s, ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q ≤ C := by
    intro s
    rw [hJeq]
    refine ENNReal.rpow_le_rpow ?_ hq0.le
    calc eLpNorm (fun x => f (x - s) - f x) p volume
        ≤ eLpNorm (fun x => f (x - s)) p volume + eLpNorm f p volume :=
          eLpNorm_sub_le (f := fun x => f (x - s)) (g := f) hp1
      _ = 2 * eLpNorm f p volume := by
          rw [show (fun x => f (x - s)) = f ∘ (fun x => x - s) from rfl,
            eLpNorm_comp_measurePreserving hf.aestronglyMeasurable (measurePreserving_sub_right volume s), two_mul]
  rw [ENNReal.tendsto_nhds_zero]
  intro e he
  obtain ⟨r, -, hr0, hre⟩ := ENNReal.lt_iff_exists_real_btwn.1 he
  have hr : 0 < r := ENNReal.ofReal_pos.1 hr0
  set A : ℝ := M ^ (q - 1) with hA_def
  have hA : 0 ≤ A := Real.rpow_nonneg hM0 _
  set Cr := C.toReal with hCr_def
  have hCr : 0 ≤ Cr := ENNReal.toReal_nonneg
  set η : ℝ := r / (2 * (A * M + 1)) with hη_def
  have hη : 0 < η := by positivity
  obtain ⟨δ, hδ, hJδ⟩ : ∃ δ > 0, ∀ s, |s| < δ →
      ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q ≤ ENNReal.ofReal η := by
    have := (ENNReal.tendsto_nhds_zero.1 hJlim) (ENNReal.ofReal η) (ENNReal.ofReal_pos.2 hη)
    obtain ⟨δ, hδ, h⟩ := Metric.eventually_nhds_iff.1 this
    exact ⟨δ, hδ, fun s hs => h (by simpa [Real.dist_eq] using hs)⟩
  set S : Set ℝ := {s : ℝ | δ / 2 < |s|} with hS_def
  have hS : MeasurableSet S := measurableSet_lt measurable_const measurable_abs
  set c : ℝ := r / (2 * (A * Cr + 1)) with hc_def
  have hc : 0 < c := by positivity
  filter_upwards [self_mem_nhdsWithin,
    (hK.tail_to_zero (δ / 2) (half_pos hδ)) (Iio_mem_nhds hc)] with ε (hε : 0 < ε) ht
  have ht' : ∫ s in S, |K ε s| < c := ht
  have hk := hK.integrable ε hε
  have hw : AEMeasurable (fun s => ‖K ε s‖ₑ) volume := hk.aestronglyMeasurable.enorm
  have hW : ∫⁻ s, ‖K ε s‖ₑ = ENNReal.ofReal (∫ s, |K ε s|) := by
    rw [← ofReal_integral_norm_eq_lintegral_enorm hk]
    simp [Real.norm_eq_abs]
  have hWS : ∫⁻ s in S, ‖K ε s‖ₑ = ENNReal.ofReal (∫ s in S, |K ε s|) := by
    rw [← ofReal_integral_norm_eq_lintegral_enorm hk.integrableOn]
    simp [Real.norm_eq_abs]
  have hmain := ai_main_bound hk (hK.total_weight_one ε hε) hfm hq1
  have hsplit : ∫⁻ s, ‖K ε s‖ₑ * ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q ≤
      ENNReal.ofReal η * (∫⁻ s, ‖K ε s‖ₑ) + C * ∫⁻ s in S, ‖K ε s‖ₑ := by
    calc ∫⁻ s, ‖K ε s‖ₑ * ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q
        ≤ ∫⁻ s, (ENNReal.ofReal η * ‖K ε s‖ₑ + C * S.indicator (fun s => ‖K ε s‖ₑ) s) := by
          refine lintegral_mono fun s => ?_
          by_cases hs : s ∈ S
          · rw [Set.indicator_of_mem hs, mul_comm (‖K ε s‖ₑ)]
            calc (∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q) * ‖K ε s‖ₑ ≤ C * ‖K ε s‖ₑ := by
                  gcongr; exact hJC s
              _ ≤ _ := le_add_self
          · rw [Set.indicator_of_notMem hs, mul_zero, add_zero, mul_comm]
            have : |s| < δ := by
              have : ¬ δ / 2 < |s| := hs
              linarith
            gcongr
            exact hJδ s this
      _ = _ := by
          rw [lintegral_add_left' (hw.const_mul _), lintegral_const_mul'' _ hw,
            lintegral_const_mul'' _ (hw.indicator hS), lintegral_indicator hS]
  have hW1 : (∫⁻ s, ‖K ε s‖ₑ) ^ (q - 1) ≤ ENNReal.ofReal A := by
    have h0 : 0 ≤ ∫ s, |K ε s| := integral_nonneg fun s => abs_nonneg _
    rw [hW, ENNReal.ofReal_rpow_of_nonneg h0 (by linarith)]
    exact ENNReal.ofReal_le_ofReal
      (Real.rpow_le_rpow h0 (hK.total_size_le ε hε) (by linarith))
  have hC' : C = ENNReal.ofReal Cr := (ENNReal.ofReal_toReal hCfin).symm
  have hAMη : A * M * η ≤ r / 2 := by
    rw [hη_def, mul_div_assoc', div_le_div_iff₀ (by positivity) (by norm_num)]
    nlinarith [mul_nonneg hA hM0]
  have hACc : A * Cr * c ≤ r / 2 := by
    rw [hc_def, mul_div_assoc', div_le_div_iff₀ (by positivity) (by norm_num)]
    nlinarith [mul_nonneg hA hCr]
  calc ∫⁻ x, ‖smoothed K ε f x - f x‖ₑ ^ q
      ≤ (∫⁻ s, ‖K ε s‖ₑ) ^ (q - 1) * ∫⁻ s, ‖K ε s‖ₑ * ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ q := hmain
    _ ≤ ENNReal.ofReal A * (ENNReal.ofReal η * (∫⁻ s, ‖K ε s‖ₑ) + C * ∫⁻ s in S, ‖K ε s‖ₑ) := by
        gcongr
    _ ≤ ENNReal.ofReal A * (ENNReal.ofReal η * ENNReal.ofReal M +
          ENNReal.ofReal Cr * ENNReal.ofReal c) := by
        rw [hW, hWS, ← hC']
        gcongr
        · exact hK.total_size_le ε hε
    _ = ENNReal.ofReal (A * (η * M + Cr * c)) := by
        rw [ENNReal.ofReal_mul hA, ENNReal.ofReal_add (by positivity) (by positivity),
          ENNReal.ofReal_mul hη.le, ENNReal.ofReal_mul hCr]
    _ ≤ ENNReal.ofReal r := ENNReal.ofReal_le_ofReal (by nlinarith)
    _ ≤ e := hre.le

#print axioms ai_holder_weight
#print axioms ai_young
#print axioms ai_main_bound
#print axioms ai_translate_tendsto
#print axioms ai_tendsto_Lp_of_measurable

/-- Convergence at a point of continuity: if `K_ε` is an approximate identity and the signal
`f` is bounded and continuous at the time `x`, then the smoothed value `(K_ε * f)(x)` tends to
the true value `f(x)` as the width `ε` shrinks to 0. -/
theorem approx_identity_tendsto_at_continuity_point
    (K : ℝ → ℝ → ℝ) (M : ℝ) (hK : IsApproxIdentity K M)
    (f : ℝ → ℝ) (hf_meas : AEStronglyMeasurable f volume)
    (hf_bdd : ∃ B : ℝ, ∀ t, |f t| ≤ B)
    (x : ℝ) (hx : ContinuousAt f x) :
    Tendsto (fun ε => smoothed K ε f x) (𝓝[>] 0) (𝓝 (f x)) := by
  obtain ⟨B, hB⟩ := hf_bdd
  have hB0 : 0 ≤ B := (abs_nonneg _).trans (hB 0)
  have hM0 : 0 ≤ M :=
    (integral_nonneg fun s => abs_nonneg (K 1 s)).trans (hK.total_size_le 1 one_pos)
  rw [Metric.tendsto_nhds]
  intro e he
  set η := e / (2 * (M + 1)) with hη
  have hηpos : 0 < η := by positivity
  obtain ⟨δ, hδ, hcont⟩ := Metric.continuousAt_iff.1 hx η hηpos
  set S : Set ℝ := {s : ℝ | δ / 2 < |s|} with hS_def
  have hS : MeasurableSet S := measurableSet_lt measurable_const measurable_abs
  set c := e / (2 * (2 * B + 1)) with hc_def
  have hc : 0 < c := by positivity
  filter_upwards [self_mem_nhdsWithin,
    (hK.tail_to_zero (δ / 2) (half_pos hδ)) (Iio_mem_nhds hc)] with ε (hε : 0 < ε) ht
  have ht' : ∫ s in S, |K ε s| < c := ht
  have hKi := hK.integrable ε hε
  have hfx : AEStronglyMeasurable (fun s => f (x - s)) volume :=
    hf_meas.comp_quasiMeasurePreserving
      (Measure.measurePreserving_sub_left volume x).quasiMeasurePreserving
  have hI1 : Integrable (fun s => K ε s * f (x - s)) := by
    refine (hKi.norm.const_mul B).mono' (hKi.aestronglyMeasurable.mul hfx) (ae_of_all _ ?_)
    intro s
    rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, mul_comm]
    exact mul_le_mul_of_nonneg_right (hB _) (abs_nonneg _)
  have hI2 : Integrable (fun s => K ε s * f x) := hKi.mul_const _
  have hdiff : smoothed K ε f x - f x = ∫ s, K ε s * (f (x - s) - f x) := by
    have e1 : ∫ s, K ε s * f x = f x := by
      rw [integral_mul_const, hK.total_weight_one ε hε, one_mul]
    calc smoothed K ε f x - f x = (∫ s, K ε s * f (x - s)) - ∫ s, K ε s * f x := by
          rw [e1]; rfl
      _ = ∫ s, (K ε s * f (x - s) - K ε s * f x) := (integral_sub hI1 hI2).symm
      _ = _ := by simp_rw [mul_sub]
  have hbound : ∀ s, |K ε s * (f (x - s) - f x)| ≤
      η * |K ε s| + 2 * B * S.indicator (fun s => |K ε s|) s := by
    intro s
    rw [abs_mul]
    by_cases hs : s ∈ S
    · rw [Set.indicator_of_mem hs]
      have : |f (x - s) - f x| ≤ 2 * B := by
        calc _ ≤ |f (x - s)| + |f x| := abs_sub _ _
          _ ≤ 2 * B := by linarith [hB (x - s), hB x]
      nlinarith [abs_nonneg (K ε s)]
    · rw [Set.indicator_of_notMem hs]
      have hs' : |s| ≤ δ / 2 := not_lt.1 hs
      have hd : dist (x - s) x < δ := by
        rw [Real.dist_eq, show x - s - x = -s by ring, abs_neg]; linarith
      have := hcont hd
      rw [Real.dist_eq] at this
      nlinarith [abs_nonneg (K ε s)]
  have hA := hKi.abs.const_mul η
  have hB' := (hKi.abs.indicator hS).const_mul (2 * B)
  rw [Real.dist_eq, hdiff]
  have h1 := hK.total_size_le ε hε
  have h2 : 0 ≤ ∫ s in S, |K ε s| := setIntegral_nonneg hS (fun _ _ => abs_nonneg _)
  have hηM : η * M < e / 2 := by
    rw [hη, div_mul_eq_mul_div, div_lt_div_iff₀ (by positivity) (by norm_num)]
    nlinarith
  have hBc : 2 * B * c < e / 2 := by
    rw [hc_def, mul_div_assoc', div_lt_div_iff₀ (by positivity) (by norm_num)]
    nlinarith
  calc |∫ s, K ε s * (f (x - s) - f x)| ≤ ∫ s, |K ε s * (f (x - s) - f x)| :=
        abs_integral_le_integral_abs
    _ ≤ ∫ s, (η * |K ε s| + 2 * B * S.indicator (fun s => |K ε s|) s) :=
        integral_mono_of_nonneg (ae_of_all _ fun _ => abs_nonneg _) (hA.add hB')
          (ae_of_all _ hbound)
    _ = η * (∫ s, |K ε s|) + 2 * B * ∫ s in S, |K ε s| := by
        rw [integral_add hA hB', integral_const_mul, integral_const_mul, integral_indicator hS]
    _ < e := by
        have h3 : η * (∫ s, |K ε s|) ≤ η * M := mul_le_mul_of_nonneg_left h1 hηpos.le
        have h4 : 2 * B * ∫ s in S, |K ε s| ≤ 2 * B * c :=
          mul_le_mul_of_nonneg_left ht'.le (by positivity)
        exact lt_of_le_of_lt (add_le_add h3 h4) (by linarith)

/-- Convergence in the mean: if `K_ε` is an approximate identity and `f` is in `L^p` with
`1 ≤ p < ∞`, then the size of the gap, `‖K_ε * f − f‖_p`, tends to 0 as the width `ε`
shrinks to 0. -/
theorem approx_identity_tendsto_in_Lp
    (K : ℝ → ℝ → ℝ) (M : ℝ) (hK : IsApproxIdentity K M)
    (p : ℝ≥0∞) (hp1 : 1 ≤ p) (hp_fin : p ≠ ⊤)
    (f : ℝ → ℝ) (hf : MemLp f p volume) :
    Tendsto (fun ε => eLpNorm (fun x => smoothed K ε f x - f x) p volume)
      (𝓝[>] 0) (𝓝 0) := by
  set f' := hf.aestronglyMeasurable.mk f with hf'_def
  have hf'm : StronglyMeasurable f' := hf.aestronglyMeasurable.stronglyMeasurable_mk
  have hff' : f =ᵐ[volume] f' := hf.aestronglyMeasurable.ae_eq_mk
  have hf'L : MemLp f' p volume := hf.ae_eq hff'
  have hsm : ∀ ε x, smoothed K ε f x = smoothed K ε f' x := by
    intro ε x
    unfold smoothed
    apply integral_congr_ae
    have : (fun s => f (x - s)) =ᵐ[volume] (fun s => f' (x - s)) :=
      (Measure.measurePreserving_sub_left volume x).quasiMeasurePreserving.ae_eq_comp hff'
    filter_upwards [this] with s hs
    rw [hs]
  have hcongr : ∀ ε, eLpNorm (fun x => smoothed K ε f x - f x) p volume =
      eLpNorm (fun x => smoothed K ε f' x - f' x) p volume := by
    intro ε
    apply eLpNorm_congr_ae
    filter_upwards [hff'] with x hx
    rw [hsm, hx]
  refine (ai_tendsto_Lp_of_measurable K M hK p hp1 hp_fin f' hf'L hf'm.measurable).congr' ?_
  exact Eventually.of_forall fun ε => (hcongr ε).symm

/-- Smooth signals are dense: for every `f` in `L^p`, `1 ≤ p < ∞`, and every tolerance
`τ > 0`, some signal `g` with derivatives of every order that is zero outside a bounded
interval (a signal in `C_c^∞`) lies within `τ` of `f` in the size `‖·‖_p`. -/
theorem smooth_compact_support_dense_in_Lp
    (p : ℝ≥0∞) (hp1 : 1 ≤ p) (hp_fin : p ≠ ⊤)
    (f : ℝ → ℝ) (hf : MemLp f p volume) (τ : ℝ) (hτ : 0 < τ) :
    ∃ g : ℝ → ℝ, ContDiff ℝ ∞ g ∧ HasCompactSupport g ∧
      eLpNorm (f - g) p volume < ENNReal.ofReal τ := by
  obtain ⟨g, hg1, hg2, hg3⟩ := hf.exist_eLpNorm_sub_le hp_fin hp1 (half_pos hτ)
  exact ⟨g, hg2, hg1, hg3.trans_lt ((ENNReal.ofReal_lt_ofReal_iff hτ).2 (half_lt_self hτ))⟩

-- The logger reads 1,000 times a second, so a 0.1 s window holds 100 readings,
-- and the box kernel on that window stands 10 per second high, for a total weight of 1.
example : (1000 : ℚ) * (1 / 10) = 100 ∧ (1 : ℚ) / (1 / 10) = 10 ∧ (10 : ℚ) * (1 / 10) = 1 := by
  norm_num

-- At the dip from 20 °C to 60 °C a symmetric kernel lands on the midpoint, 40 °C,
-- and the worst gap stays at half the jump, 20 °C.
example : ((20 : ℚ) + 60) / 2 = 40 ∧ ((60 : ℚ) - 20) / 2 = 20 := by
  norm_num

-- The box's mean distance from its centre, in widths: 2 × ∫_0^{1/2} u du = 1/4;
-- so the jump's share of the mean gap at width 0.1 s is 40 × 1/4 × 1/10 = 1 °C·s.
example : 2 * ((1 / 2 : ℚ) ^ 2 / 2) = 1 / 4 ∧ (40 : ℚ) * (1 / 4) * (1 / 10) = 1 := by
  norm_num

-- The box's mean of s² is ε²/12; half of it gives the bend estimate f''(x) ε²/24.
example : 2 * ((1 / 2 : ℚ) ^ 3 / 3) = 1 / 12 ∧ (1 / 2 : ℚ) * (1 / 12) = 1 / 24 := by
  norm_num

-- Weights adding to 0.9 shrink the 62 °C peak to 55.8 °C in the limit.
example : (9 / 10 : ℚ) * 62 = 279 / 5 := by
  norm_num

-- Noise: 100 readings with spread 0.5 °C average to spread 0.5/10 = 0.05 °C; 25 readings give 0.1 °C.
example : (10 : ℚ) ^ 2 = 100 ∧ (1 / 2 : ℚ) / 10 = 1 / 20 ∧ (5 : ℚ) ^ 2 = 25 ∧ (1 / 2 : ℚ) / 5 = 1 / 10 := by
  norm_num

#print axioms approx_identity_tendsto_at_continuity_point
#print axioms approx_identity_tendsto_in_Lp
#print axioms smooth_compact_support_dense_in_Lp
