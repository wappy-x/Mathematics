-- Expected shortfall: on any probability space, expected shortfall at a confidence level between 0 and 1 is subadditive, monotone, cash-translation invariant and positively homogeneous for losses with a finite average, while value at risk can fail subadditivity.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Probability.UniformOn

open MeasureTheory

/-- Value at risk of the loss `L` at confidence `α`: the smallest amount `x` that the loss stays
at or below with chance at least `α`, that is, the infimum of all `x` with `P(L ≤ x) ≥ α`. -/
noncomputable def valueAtRisk {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (α : ℝ)
    (L : Ω → ℝ) : ℝ :=
  sInf {x : ℝ | α ≤ μ.real {ω | L ω ≤ x}}

/-- Expected shortfall of the loss `L` at confidence `α`, by the card's formula:
`ES_α(L) = v + E[(L - v)_+] / (1 - α)` with `v = VaR_α(L)`. -/
noncomputable def expectedShortfall {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (α : ℝ)
    (L : Ω → ℝ) : ℝ :=
  valueAtRisk μ α L + (∫ ω, max (L ω - valueAtRisk μ α L) 0 ∂μ) / (1 - α)

open Filter Topology in
theorem es_tendsto_real_iInter {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {s : ℕ → Set Ω} (hs : ∀ n, MeasurableSet (s n)) (hm : Antitone s) :
    Tendsto (fun n => μ.real (s n)) atTop (𝓝 (μ.real (⋂ n, s n))) :=
  (ENNReal.tendsto_toReal (measure_ne_top _ _)).comp
    (tendsto_measure_iInter_atTop (fun n => (hs n).nullMeasurableSet) hm ⟨0, measure_ne_top _ _⟩)

#print axioms es_tendsto_real_iInter

open Filter Topology in
theorem es_tendsto_real_iUnion {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {s : ℕ → Set Ω} (hm : Monotone s) :
    Tendsto (fun n => μ.real (s n)) atTop (𝓝 (μ.real (⋃ n, s n))) :=
  (ENNReal.tendsto_toReal (measure_ne_top _ _)).comp (tendsto_measure_iUnion_atTop hm)

#print axioms es_tendsto_real_iUnion

open Filter Topology in
/-- Facts about the value-at-risk set for a measurable loss. -/
theorem es_var_facts {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (L : Ω → ℝ)
    (hL : Measurable L) :
    BddBelow {x : ℝ | α ≤ μ.real {ω | L ω ≤ x}} ∧
    ({x : ℝ | α ≤ μ.real {ω | L ω ≤ x}}).Nonempty ∧
    α ≤ μ.real {ω | L ω ≤ valueAtRisk μ α L} ∧
    μ.real {ω | L ω < valueAtRisk μ α L} ≤ α := by
  set S := {x : ℝ | α ≤ μ.real {ω | L ω ≤ x}} with hS
  have hmeas : ∀ x : ℝ, MeasurableSet {ω | L ω ≤ x} := fun x => measurableSet_le hL measurable_const
  have hmono : ∀ x y : ℝ, x ≤ y → μ.real {ω | L ω ≤ x} ≤ μ.real {ω | L ω ≤ y} := by
    intro x y hxy
    exact measureReal_mono (fun ω (h : L ω ≤ x) => show L ω ≤ y from h.trans hxy)
  -- bounded below
  have hbdd : BddBelow S := by
    have h1 : Tendsto (fun n : ℕ => μ.real {ω | L ω ≤ -(n : ℝ)}) atTop (𝓝 0) := by
      have := es_tendsto_real_iInter μ (s := fun n : ℕ => {ω | L ω ≤ -(n : ℝ)})
        (fun n => hmeas _) (by
          intro m n hmn ω (h : L ω ≤ -(n : ℝ))
          show L ω ≤ -(m : ℝ)
          have : (m : ℝ) ≤ n := by exact_mod_cast hmn
          linarith)
      have he : (⋂ n : ℕ, {ω | L ω ≤ -(n : ℝ)}) = ∅ := by
        ext ω
        simp only [Set.mem_iInter, Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false,
          not_forall, not_le]
        obtain ⟨n, hn⟩ := exists_nat_gt (-L ω)
        exact ⟨n, by linarith⟩
      rwa [he, measureReal_empty] at this
    obtain ⟨N, hN⟩ := (h1.eventually (gt_mem_nhds hα0)).exists
    refine ⟨-(N : ℝ), fun x hx => ?_⟩
    by_contra hlt
    push Not at hlt
    have := hmono x _ hlt.le
    have hx' : α ≤ μ.real {ω | L ω ≤ x} := hx
    linarith
  have hne : S.Nonempty := by
    have h1 : Tendsto (fun n : ℕ => μ.real {ω | L ω ≤ (n : ℝ)}) atTop (𝓝 1) := by
      have := es_tendsto_real_iUnion μ (s := fun n : ℕ => {ω | L ω ≤ (n : ℝ)}) (by
          intro m n hmn ω (h : L ω ≤ (m : ℝ))
          show L ω ≤ (n : ℝ)
          have : (m : ℝ) ≤ n := by exact_mod_cast hmn
          linarith)
      have he : (⋃ n : ℕ, {ω | L ω ≤ (n : ℝ)}) = Set.univ := by
        ext ω
        simp only [Set.mem_iUnion, Set.mem_ofPred_eq, Set.mem_univ, iff_true]
        obtain ⟨n, hn⟩ := exists_nat_ge (L ω)
        exact ⟨n, hn⟩
      rwa [he, probReal_univ] at this
    obtain ⟨N, hN⟩ := (h1.eventually (lt_mem_nhds hα1)).exists
    exact ⟨N, hN.le⟩
  refine ⟨hbdd, hne, ?_, ?_⟩
  · have hin : ∀ n : ℕ, α ≤ μ.real {ω | L ω ≤ sInf S + 1 / ((n : ℝ) + 1)} := by
      intro n
      have hpos : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
      obtain ⟨s, hs, hlt⟩ := exists_lt_of_csInf_lt hne (lt_add_of_pos_right (sInf S) hpos)
      exact le_trans hs (hmono _ _ hlt.le)
    have h1 := es_tendsto_real_iInter μ
      (s := fun n : ℕ => {ω | L ω ≤ sInf S + 1 / ((n : ℝ) + 1)}) (fun n => hmeas _) (by
        intro m n hmn ω (h : L ω ≤ sInf S + 1 / ((n : ℝ) + 1))
        show L ω ≤ sInf S + 1 / ((m : ℝ) + 1)
        have : (m : ℝ) ≤ n := by exact_mod_cast hmn
        have : 1 / ((n : ℝ) + 1) ≤ 1 / ((m : ℝ) + 1) :=
          one_div_le_one_div_of_le (by positivity) (by linarith)
        linarith)
    have he : (⋂ n : ℕ, {ω | L ω ≤ sInf S + 1 / ((n : ℝ) + 1)}) = {ω | L ω ≤ sInf S} := by
      ext ω
      simp only [Set.mem_iInter, Set.mem_ofPred_eq]
      constructor
      · intro h
        by_contra hlt
        push Not at hlt
        obtain ⟨n, hn⟩ := exists_nat_one_div_lt (sub_pos.mpr hlt)
        have := h n
        linarith
      · intro h n
        have : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
        linarith
    rw [he] at h1
    exact ge_of_tendsto' h1 hin
  · have hin : ∀ n : ℕ, μ.real {ω | L ω ≤ sInf S - 1 / ((n : ℝ) + 1)} ≤ α := by
      intro n
      have hpos : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
      have := notMem_of_lt_csInf (sub_lt_self (sInf S) hpos) hbdd
      simp only [hS, Set.mem_ofPred_eq, not_le] at this
      exact this.le
    have h1 := es_tendsto_real_iUnion μ
      (s := fun n : ℕ => {ω | L ω ≤ sInf S - 1 / ((n : ℝ) + 1)}) (by
        intro m n hmn ω (h : L ω ≤ sInf S - 1 / ((m : ℝ) + 1))
        show L ω ≤ sInf S - 1 / ((n : ℝ) + 1)
        have : (m : ℝ) ≤ n := by exact_mod_cast hmn
        have : 1 / ((n : ℝ) + 1) ≤ 1 / ((m : ℝ) + 1) :=
          one_div_le_one_div_of_le (by positivity) (by linarith)
        linarith)
    have he : (⋃ n : ℕ, {ω | L ω ≤ sInf S - 1 / ((n : ℝ) + 1)}) = {ω | L ω < sInf S} := by
      ext ω
      simp only [Set.mem_iUnion, Set.mem_ofPred_eq]
      constructor
      · rintro ⟨n, hn⟩
        have : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
        linarith
      · intro h
        obtain ⟨n, hn⟩ := exists_nat_one_div_lt (sub_pos.mpr h)
        exact ⟨n, by linarith⟩
    rw [he] at h1
    exact le_of_tendsto' h1 hin

#print axioms es_var_facts

open Filter Topology in
/-- For a measurable loss, the card's formula is at most `t + E[(L - t)_+]/(1 - α)` for every `t`. -/
theorem es_le_of_measurable {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (L : Ω → ℝ)
    (hLm : Measurable L) (hL : Integrable L μ) (t : ℝ) :
    expectedShortfall μ α L ≤ t + (∫ ω, max (L ω - t) 0 ∂μ) / (1 - α) := by
  obtain ⟨-, -, hA, hB⟩ := es_var_facts μ α hα0 hα1 L hLm
  set v := valueAtRisk μ α L with hv
  have hpos : 0 < 1 - α := by linarith
  have hgi : ∀ s : ℝ, Integrable (fun ω => max (L ω - s) 0) μ :=
    fun s => (hL.sub (integrable_const s)).pos_part
  have key : (∫ ω, max (L ω - v) 0 ∂μ) ≤ (∫ ω, max (L ω - t) 0 ∂μ) + (1 - α) * (t - v) := by
    rcases le_or_gt v t with hvt | htv
    · have hms : MeasurableSet {ω | v < L ω} := measurableSet_lt measurable_const hLm
      have hpt : ∀ ω, max (L ω - v) 0 ≤
          max (L ω - t) 0 + Set.indicator {ω | v < L ω} (fun _ => t - v) ω := by
        intro ω
        by_cases h : v < L ω
        · rw [Set.indicator_of_mem (show ω ∈ {ω | v < L ω} from h)]
          have := le_max_left (L ω - t) 0
          exact max_le (by linarith) (by linarith)
        · rw [Set.indicator_of_notMem (show ω ∉ {ω | v < L ω} from h)]
          push Not at h
          have := le_max_right (L ω - t) 0
          exact max_le (by linarith) (by linarith)
      have hint := integral_mono (hgi v) ((hgi t).add ((integrable_const _).indicator hms)) hpt
      simp only [Pi.add_apply] at hint
      rw [integral_add (hgi t) ((integrable_const _).indicator hms),
        integral_indicator_const _ hms, smul_eq_mul] at hint
      have hc : μ.real {ω | v < L ω} = 1 - μ.real {ω | L ω ≤ v} := by
        rw [← probReal_compl_eq_one_sub (measurableSet_le hLm measurable_const)]
        congr 1
        ext ω
        simp
      have : μ.real {ω | v < L ω} * (t - v) ≤ (1 - α) * (t - v) := by
        apply mul_le_mul_of_nonneg_right _ (by linarith)
        linarith
      linarith
    · have hms : MeasurableSet {ω | v ≤ L ω} := measurableSet_le measurable_const hLm
      have hpt : ∀ ω, max (L ω - v) 0 + Set.indicator {ω | v ≤ L ω} (fun _ => v - t) ω ≤
          max (L ω - t) 0 := by
        intro ω
        by_cases h : v ≤ L ω
        · rw [Set.indicator_of_mem (show ω ∈ {ω | v ≤ L ω} from h)]
          rw [max_eq_left (by linarith : (0 : ℝ) ≤ L ω - v),
            max_eq_left (by linarith : (0 : ℝ) ≤ L ω - t)]
          linarith
        · rw [Set.indicator_of_notMem (show ω ∉ {ω | v ≤ L ω} from h)]
          push Not at h
          rw [max_eq_right (by linarith : L ω - v ≤ 0)]
          simp
      have hint := integral_mono ((hgi v).add ((integrable_const _).indicator hms)) (hgi t) hpt
      simp only [Pi.add_apply] at hint
      rw [integral_add (hgi v) ((integrable_const _).indicator hms),
        integral_indicator_const _ hms, smul_eq_mul] at hint
      have hc : μ.real {ω | v ≤ L ω} = 1 - μ.real {ω | L ω < v} := by
        rw [← probReal_compl_eq_one_sub (measurableSet_lt hLm measurable_const)]
        congr 1
        ext ω
        simp
      have : (1 - α) * (v - t) ≤ μ.real {ω | v ≤ L ω} * (v - t) := by
        apply mul_le_mul_of_nonneg_right _ (by linarith)
        linarith
      linarith
  show v + (∫ ω, max (L ω - v) 0 ∂μ) / (1 - α) ≤ t + (∫ ω, max (L ω - t) 0 ∂μ) / (1 - α)
  have : (∫ ω, max (L ω - v) 0 ∂μ) / (1 - α) ≤
      ((∫ ω, max (L ω - t) 0 ∂μ) + (1 - α) * (t - v)) / (1 - α) :=
    div_le_div_of_nonneg_right key hpos.le
  rw [add_div, mul_div_cancel_left₀ _ hpos.ne'] at this
  linarith

#print axioms es_le_of_measurable

open Filter Topology in
theorem es_valueAtRisk_congr {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (α : ℝ)
    {L L' : Ω → ℝ} (h : L =ᵐ[μ] L') : valueAtRisk μ α L = valueAtRisk μ α L' := by
  unfold valueAtRisk
  congr 1
  ext x
  simp only [Set.mem_ofPred_eq]
  have : μ.real {ω | L ω ≤ x} = μ.real {ω | L' ω ≤ x} := by
    simp only [measureReal_def]
    congr 1
    apply measure_congr
    filter_upwards [h] with ω hω
    show (L ω ≤ x) = (L' ω ≤ x)
    rw [hω]
  rw [this]

#print axioms es_valueAtRisk_congr

open Filter Topology in
theorem es_expectedShortfall_congr {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (α : ℝ)
    {L L' : Ω → ℝ} (h : L =ᵐ[μ] L') :
    expectedShortfall μ α L = expectedShortfall μ α L' := by
  unfold expectedShortfall
  rw [es_valueAtRisk_congr μ α h]
  congr 2
  apply integral_congr_ae
  filter_upwards [h] with ω hω
  rw [hω]

#print axioms es_expectedShortfall_congr

open Filter Topology in
/-- Expected shortfall is at most `t + E[(L - t)_+]/(1 - α)` for every `t`. -/
theorem es_le {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (L : Ω → ℝ)
    (hL : Integrable L μ) (t : ℝ) :
    expectedShortfall μ α L ≤ t + (∫ ω, max (L ω - t) 0 ∂μ) / (1 - α) := by
  set L' := hL.1.mk L
  have hae : L =ᵐ[μ] L' := hL.1.ae_eq_mk
  rw [es_expectedShortfall_congr μ α hae]
  have h' := es_le_of_measurable μ α hα0 hα1 L' hL.1.stronglyMeasurable_mk.measurable
    (hL.congr hae) t
  have : (∫ ω, max (L ω - t) 0 ∂μ) = ∫ ω, max (L' ω - t) 0 ∂μ := by
    apply integral_congr_ae
    filter_upwards [hae] with ω hω
    rw [hω]
  rw [this]
  exact h'

#print axioms es_le

open Filter Topology in
/-- Expected shortfall is at least the average loss. -/
theorem es_ge_integral {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (L : Ω → ℝ)
    (hL : Integrable L μ) :
    (∫ ω, L ω ∂μ) ≤ expectedShortfall μ α L := by
  unfold expectedShortfall
  set v := valueAtRisk μ α L
  have hpos : 0 < 1 - α := by linarith
  have hX0 : 0 ≤ ∫ ω, max (L ω - v) 0 ∂μ := integral_nonneg fun ω => le_max_right _ _
  have hX : (∫ ω, L ω ∂μ) - v ≤ ∫ ω, max (L ω - v) 0 ∂μ := by
    have h1 : (∫ ω, (L ω - v) ∂μ) = (∫ ω, L ω ∂μ) - v := by
      rw [integral_sub hL (integrable_const v)]
      simp
    rw [← h1]
    exact integral_mono (hL.sub (integrable_const v)) (hL.sub (integrable_const v)).pos_part
      fun ω => le_max_left _ _
  have : (∫ ω, max (L ω - v) 0 ∂μ) ≤ (∫ ω, max (L ω - v) 0 ∂μ) / (1 - α) := by
    rw [le_div_iff₀ hpos]
    nlinarith [mul_nonneg hX0 hα0.le]
  linarith

#print axioms es_ge_integral

/-- Expected shortfall is subadditive. Take two losses `L` and `M` on the same probability space
(one loss law for everything), each with a finite average, and a confidence level `α` strictly
between 0 and 1. Then the expected shortfall of the merged book `L + M` is at most the expected
shortfall of `L` plus the expected shortfall of `M`: merging two books never needs more capital
than keeping them apart. -/
theorem expected_shortfall_subadditive {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (L M : Ω → ℝ)
    (hL : Integrable L μ) (hM : Integrable M μ) :
    expectedShortfall μ α (fun ω => L ω + M ω) ≤
      expectedShortfall μ α L + expectedShortfall μ α M := by
  set a := valueAtRisk μ α L
  set b := valueAtRisk μ α M
  have hpos : 0 < 1 - α := by linarith
  have h1 := es_le μ α hα0 hα1 (fun ω => L ω + M ω) (hL.add hM) (a + b)
  have hint : (∫ ω, max (L ω + M ω - (a + b)) 0 ∂μ) ≤
      (∫ ω, max (L ω - a) 0 ∂μ) + ∫ ω, max (M ω - b) 0 ∂μ := by
    have hadd : (∫ ω, (max (L ω - a) 0 + max (M ω - b) 0) ∂μ) =
        (∫ ω, max (L ω - a) 0 ∂μ) + ∫ ω, max (M ω - b) 0 ∂μ :=
      integral_add (hL.sub (integrable_const a)).pos_part (hM.sub (integrable_const b)).pos_part
    rw [← hadd]
    refine integral_mono ((hL.add hM).sub (integrable_const _)).pos_part
      ((hL.sub (integrable_const a)).pos_part.add (hM.sub (integrable_const b)).pos_part) ?_
    intro ω
    simp only
    have := le_max_left (L ω - a) 0
    have := le_max_right (L ω - a) 0
    have := le_max_left (M ω - b) 0
    have := le_max_right (M ω - b) 0
    exact max_le (by linarith) (by linarith)
  have h2 := div_le_div_of_nonneg_right hint hpos.le
  rw [add_div] at h2
  show _ ≤ (a + (∫ ω, max (L ω - a) 0 ∂μ) / (1 - α)) + (b + (∫ ω, max (M ω - b) 0 ∂μ) / (1 - α))
  linarith

/-- The other three rules of a coherent risk measure hold for expected shortfall. On a
probability space, at a confidence level `α` strictly between 0 and 1, for losses with a finite
average:
monotonicity, a book `L` that loses no more than `M` in every outcome has
`ES(L) ≤ ES(M)`;
cash translation, a certain extra loss of `c` dollars adds exactly `c`, `ES(L + c) = ES(L) + c`;
positive homogeneity, scaling the book by `λ ≥ 0` scales the shortfall, `ES(λL) = λ ES(L)`. -/
theorem expected_shortfall_monotone_cash_homogeneous {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) :
    (∀ L M : Ω → ℝ, Integrable L μ → Integrable M μ → (∀ ω, L ω ≤ M ω) →
        expectedShortfall μ α L ≤ expectedShortfall μ α M) ∧
    (∀ (L : Ω → ℝ) (c : ℝ), Integrable L μ →
        expectedShortfall μ α (fun ω => L ω + c) = expectedShortfall μ α L + c) ∧
    (∀ (L : Ω → ℝ) (lam : ℝ), Integrable L μ → 0 ≤ lam →
        expectedShortfall μ α (fun ω => lam * L ω) = lam * expectedShortfall μ α L) := by
  have hpos : 0 < 1 - α := by linarith
  refine ⟨?_, ?_, ?_⟩
  · intro L M hL hM hLM
    set b := valueAtRisk μ α M
    have h1 := es_le μ α hα0 hα1 L hL b
    have hint : (∫ ω, max (L ω - b) 0 ∂μ) ≤ ∫ ω, max (M ω - b) 0 ∂μ :=
      integral_mono (hL.sub (integrable_const b)).pos_part (hM.sub (integrable_const b)).pos_part
        fun ω => max_le_max (by linarith [hLM ω]) le_rfl
    have h2 := div_le_div_of_nonneg_right hint hpos.le
    show _ ≤ b + (∫ ω, max (M ω - b) 0 ∂μ) / (1 - α)
    linarith
  · intro L c hL
    apply le_antisymm
    · set a := valueAtRisk μ α L
      have h1 := es_le μ α hα0 hα1 (fun ω => L ω + c) (hL.add (integrable_const c)) (a + c)
      have he : (∫ ω, max (L ω + c - (a + c)) 0 ∂μ) = ∫ ω, max (L ω - a) 0 ∂μ := by
        congr 1
        funext ω
        ring_nf
      rw [he] at h1
      show _ ≤ (a + (∫ ω, max (L ω - a) 0 ∂μ) / (1 - α)) + c
      linarith
    · set v := valueAtRisk μ α (fun ω => L ω + c)
      have h1 := es_le μ α hα0 hα1 L hL (v - c)
      have he : (∫ ω, max (L ω - (v - c)) 0 ∂μ) = ∫ ω, max (L ω + c - v) 0 ∂μ := by
        congr 1
        funext ω
        ring_nf
      rw [he] at h1
      show _ ≤ v + (∫ ω, max (L ω + c - v) 0 ∂μ) / (1 - α)
      linarith
  · intro L lam hL hlam
    rcases hlam.lt_or_eq with hlam | hlam
    · apply le_antisymm
      · set a := valueAtRisk μ α L
        have h1 := es_le μ α hα0 hα1 (fun ω => lam * L ω) (hL.const_mul lam) (lam * a)
        have he : (∫ ω, max (lam * L ω - lam * a) 0 ∂μ) = lam * ∫ ω, max (L ω - a) 0 ∂μ := by
          rw [← integral_const_mul]
          congr 1
          funext ω
          rw [← mul_sub, mul_max_of_nonneg _ _ hlam.le, mul_zero]
        rw [he] at h1
        show _ ≤ lam * (a + (∫ ω, max (L ω - a) 0 ∂μ) / (1 - α))
        rw [mul_add, ← mul_div_assoc]
        exact h1
      · set v := valueAtRisk μ α (fun ω => lam * L ω)
        have h1 := es_le μ α hα0 hα1 L hL (v / lam)
        have he : lam * (∫ ω, max (L ω - v / lam) 0 ∂μ) = ∫ ω, max (lam * L ω - v) 0 ∂μ := by
          rw [← integral_const_mul]
          congr 1
          funext ω
          rw [mul_max_of_nonneg _ _ hlam.le, mul_zero, mul_sub, mul_div_cancel₀ _ hlam.ne']
        have h2 := mul_le_mul_of_nonneg_left h1 hlam.le
        rw [mul_add, mul_div_cancel₀ _ hlam.ne', ← mul_div_assoc, he] at h2
        exact h2
    · subst hlam
      simp only [zero_mul]
      apply le_antisymm
      · have h1 := es_le μ α hα0 hα1 (fun _ => (0 : ℝ)) (integrable_const 0) 0
        simpa using h1
      · have h1 := es_ge_integral μ α hα0 hα1 (fun _ => (0 : ℝ)) (integrable_const 0)
        simpa using h1

/-- Value at risk is not subadditive. There is a probability space with two losses `L` and `M`,
each with a finite average, whose merged value at risk at 99% is larger than the sum of their
own values at risk at 99% (the card's two bonds: $100 for the pair against $0 + $0). -/
theorem value_at_risk_not_subadditive :
    ∃ (Ω : Type) (_ : MeasurableSpace Ω) (μ : Measure Ω) (_ : IsProbabilityMeasure μ)
      (L M : Ω → ℝ), Integrable L μ ∧ Integrable M μ ∧
      valueAtRisk μ (99 / 100) L + valueAtRisk μ (99 / 100) M <
        valueAtRisk μ (99 / 100) (fun ω => L ω + M ω) := by
  let μ : Measure (Fin 100) := ProbabilityTheory.uniformOn Set.univ
  have hsing : ∀ i : Fin 100, μ.real {i} = 1 / 100 := by
    intro i
    simp only [μ, measureReal_def, ProbabilityTheory.uniformOn_univ, Measure.count_singleton,
      Fintype.card_fin]
    norm_num
  let L : Fin 100 → ℝ := fun ω => if ω = 0 then 100 else 0
  let M : Fin 100 → ℝ := fun ω => if ω = 1 then 100 else 0
  have hα0 : (0 : ℝ) < 99 / 100 := by norm_num
  have hα1 : (99 / 100 : ℝ) < 1 := by norm_num
  -- value at risk of a single bond is at most 0
  have hone : ∀ (i : Fin 100) (f : Fin 100 → ℝ), (∀ ω, ω ≠ i → f ω ≤ 0) →
      valueAtRisk μ (99 / 100) f ≤ 0 := by
    intro i f hf
    obtain ⟨hbdd, -, -, -⟩ := es_var_facts μ (99 / 100) hα0 hα1 f (measurable_of_finite f)
    apply csInf_le hbdd
    show (99 / 100 : ℝ) ≤ μ.real {ω | f ω ≤ 0}
    have hsub : ({i}ᶜ : Set (Fin 100)) ⊆ {ω | f ω ≤ 0} := fun ω hω => hf ω hω
    have := measureReal_mono (μ := μ) hsub
    rw [probReal_compl_eq_one_sub (measurableSet_singleton i), hsing] at this
    linarith
  have hL0 : valueAtRisk μ (99 / 100) L ≤ 0 :=
    hone 0 L (fun ω hω => by simp [L, hω])
  have hM0 : valueAtRisk μ (99 / 100) M ≤ 0 :=
    hone 1 M (fun ω hω => by simp [M, hω])
  have hLM : 100 ≤ valueAtRisk μ (99 / 100) (fun ω => L ω + M ω) := by
    obtain ⟨-, hne, -, -⟩ := es_var_facts μ (99 / 100) hα0 hα1 (fun ω => L ω + M ω)
      (measurable_of_finite _)
    apply le_csInf hne
    intro x hx
    have hx' : (99 / 100 : ℝ) ≤ μ.real {ω | L ω + M ω ≤ x} := hx
    by_contra hlt
    push Not at hlt
    have hsub : {ω | L ω + M ω ≤ x} ⊆ (({0} : Set (Fin 100)) ∪ {1})ᶜ := by
      intro ω hω
      have hω' : L ω + M ω ≤ x := hω
      simp only [Set.mem_compl_iff, Set.mem_union, Set.mem_singleton_iff, not_or]
      constructor
      · rintro rfl
        simp [L, M] at hω'
        linarith
      · rintro rfl
        simp [L, M] at hω'
        linarith
    have h1 := measureReal_mono (μ := μ) hsub
    rw [probReal_compl_eq_one_sub ((measurableSet_singleton 0).union (measurableSet_singleton 1)),
      measureReal_union (by simp) (measurableSet_singleton 1), hsing, hsing] at h1
    linarith
  exact ⟨Fin 100, inferInstance, μ, inferInstance, L, M, Integrable.of_finite, Integrable.of_finite,
    by linarith⟩

-- The four outcomes for two independent 1% defaults: 98.01%, 0.99%, 0.99% and 0.01%, total 1.
example : (99 / 100 : ℚ) * (99 / 100) = 9801 / 10000 ∧
    (1 / 100 : ℚ) * (99 / 100) = 99 / 10000 ∧ (1 / 100 : ℚ) * (1 / 100) = 1 / 10000 ∧
    (9801 : ℚ) / 10000 + 99 / 10000 + 99 / 10000 + 1 / 10000 = 1 := by norm_num
-- Exactly one default: 2 × 0.01 × 0.99 = 0.0198. The pair's chance of no loss, 98.01%, is short of 99%.
example : 2 * (1 / 100 : ℚ) * (99 / 100) = 198 / 10000 ∧ (9801 : ℚ) / 10000 < 99 / 100 := by
  norm_num
-- One bond: no loss with chance 99%, and its shortfall is 0 + (0.01 × 100) / 0.01 = 100.
example : (0 : ℚ) + (1 / 100 * 100) / (1 / 100) = 100 := by norm_num
-- The pair, filling the worst 1%: (0.0001 × 200 + 0.0099 × 100) / 0.01 = 101.
example : ((1 / 10000 : ℚ) * 200 + 99 / 10000 * 100) / (1 / 100) = 101 := by norm_num
-- The slice taken at $100 for the pair: 0.01 - 0.0001 = 0.0099.
example : (1 / 100 : ℚ) - 1 / 10000 = 99 / 10000 := by norm_num
-- The pair, by the formula: 100 + (0.0001 × 100) / 0.01 = 101, which is below 100 + 100.
example : (100 : ℚ) + (1 / 10000 * 100) / (1 / 100) = 101 ∧ (101 : ℚ) < 100 + 100 := by norm_num
-- The axioms on the pair: a certain $5 loss gives 106, doubling the book gives 202.
example : (101 : ℚ) + 5 = 106 ∧ 2 * (101 : ℚ) = 202 := by norm_num
-- Wrong slice, every loss at or above VaR: (0.0198 × 100 + 0.0001 × 200) / 0.0199 = 20000/199, about $100.50.
example : ((198 / 10000 : ℚ) * 100 + 1 / 10000 * 200) / (199 / 10000) = 20000 / 199 := by norm_num

#print axioms expected_shortfall_subadditive
#print axioms expected_shortfall_monotone_cash_homogeneous
#print axioms value_at_risk_not_subadditive
