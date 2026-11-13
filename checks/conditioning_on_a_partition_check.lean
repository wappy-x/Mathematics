-- Conditioning on a partition: for a countable partition into events and an integrable X, the cell-average forecast is integrable, has the same integral as X over every set of the partition's sigma-algebra, is the only cell-constant quantity that does so apart from null cells, and has the least mean squared error; that sigma-algebra is the unions of cells and its measurable functions are the cell-constant ones.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.MeasurableSpace.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.MeasureTheory.Function.L2Space

open MeasureTheory

lemma partition_cell_unique {Ω ι : Type*} (B : ι → Set Ω)
    (hdisj : Pairwise (Function.onFun Disjoint B))
    {i j : ι} {ω : Ω} (hi : ω ∈ B i) (hj : ω ∈ B j) : i = j := by
  by_contra h
  exact Set.disjoint_left.mp (hdisj h) hi hj

lemma partition_sigma_helper {Ω ι : Type*} [Countable ι]
    (B : ι → Set Ω) (hdisj : Pairwise (Function.onFun Disjoint B))
    (hcover : ⋃ i, B i = Set.univ) :
    (∀ A : Set Ω, MeasurableSet[MeasurableSpace.generateFrom (Set.range B)] A ↔
      ∃ I : Set ι, A = ⋃ i ∈ I, B i) ∧
    (∀ Z : Ω → ℝ, Measurable[MeasurableSpace.generateFrom (Set.range B)] Z ↔
      ∀ i, ∀ ω ∈ B i, ∀ ω' ∈ B i, Z ω = Z ω') := by
  have hex : ∀ ω, ∃ i, ω ∈ B i := fun ω => Set.mem_iUnion.mp (hcover ▸ Set.mem_univ ω)
  have hA : ∀ A : Set Ω, MeasurableSet[MeasurableSpace.generateFrom (Set.range B)] A ↔
      ∃ I : Set ι, A = ⋃ i ∈ I, B i := by
    intro A
    constructor
    · intro hA
      let M : MeasurableSpace Ω :=
        { MeasurableSet' := fun A => ∃ I : Set ι, A = ⋃ i ∈ I, B i
          measurableSet_empty := ⟨∅, by simp⟩
          measurableSet_compl := by
            rintro s ⟨I, rfl⟩
            refine ⟨Iᶜ, ?_⟩
            ext ω
            obtain ⟨j, hj⟩ := hex ω
            simp only [Set.mem_compl_iff, Set.mem_iUnion, exists_prop, not_exists, not_and]
            constructor
            · intro h
              exact ⟨j, fun hjI => h j hjI hj, hj⟩
            · rintro ⟨k, hkI, hk⟩ i hi hiω
              exact hkI (partition_cell_unique B hdisj hiω hk ▸ hi)
          measurableSet_iUnion := by
            intro s hs
            choose I hI using hs
            refine ⟨⋃ n, I n, ?_⟩
            ext ω
            simp only [hI, Set.mem_iUnion, exists_prop]
            constructor
            · rintro ⟨n, i, hi, hω⟩
              exact ⟨i, ⟨n, hi⟩, hω⟩
            · rintro ⟨i, ⟨n, hi⟩, hω⟩
              exact ⟨n, i, hi, hω⟩ }
      have hle : MeasurableSpace.generateFrom (Set.range B) ≤ M := by
        apply MeasurableSpace.generateFrom_le
        rintro _ ⟨i, rfl⟩
        exact ⟨{i}, by simp⟩
      exact hle A hA
    · rintro ⟨I, rfl⟩
      exact MeasurableSet.biUnion I.to_countable fun i _ =>
        MeasurableSpace.measurableSet_generateFrom ⟨i, rfl⟩
  refine ⟨hA, fun Z => ⟨?_, ?_⟩⟩
  · intro hZ i ω hω ω' hω'
    have hm : MeasurableSet[MeasurableSpace.generateFrom (Set.range B)] (Z ⁻¹' {Z ω}) :=
      hZ (measurableSet_singleton _)
    obtain ⟨I, hI⟩ := (hA _).mp hm
    have h1 : ω ∈ Z ⁻¹' {Z ω} := rfl
    rw [hI] at h1
    simp only [Set.mem_iUnion, exists_prop] at h1
    obtain ⟨j, hjI, hj⟩ := h1
    have hij := partition_cell_unique B hdisj hω hj
    have h2 : ω' ∈ ⋃ i ∈ I, B i := Set.mem_biUnion (hij ▸ hjI) hω'
    rw [← hI] at h2
    exact (h2 : Z ω' = Z ω).symm
  · intro hZ S _
    rw [hA]
    refine ⟨{i | ∀ ω ∈ B i, Z ω ∈ S}, ?_⟩
    ext ω
    simp only [Set.mem_preimage, Set.mem_iUnion, Set.mem_ofPred_eq, exists_prop]
    constructor
    · intro h
      obtain ⟨j, hj⟩ := hex ω
      exact ⟨j, fun ω' hω' => hZ j ω hj ω' hω' ▸ h, hj⟩
    · rintro ⟨j, hj, hω⟩
      exact hj ω hω

lemma partition_lintegral_eq_tsum {Ω ι : Type*} [MeasurableSpace Ω] [Countable ι]
    (P : Measure Ω) (B : ι → Set Ω) (hmeas : ∀ i, MeasurableSet (B i))
    (hdisj : Pairwise (Function.onFun Disjoint B)) (hcover : ⋃ i, B i = Set.univ)
    (f : Ω → ENNReal) : ∫⁻ ω, f ω ∂P = ∑' i, ∫⁻ ω in B i, f ω ∂P := by
  rw [← lintegral_iUnion hmeas hdisj, hcover, Measure.restrict_univ]

lemma partition_cell_integral_eq {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsFiniteMeasure P] (S : Set Ω) (hS : MeasurableSet S) (X Y : Ω → ℝ)
    (hY : P S ≠ 0 → ∀ ω ∈ S, Y ω = (∫ x in S, X x ∂P) / P.real S) :
    ∫ x in S, Y x ∂P = ∫ x in S, X x ∂P := by
  by_cases h : P S = 0
  · simp [Measure.restrict_eq_zero.mpr h]
  · rw [setIntegral_congr_fun hS (fun ω hω => hY h ω hω), setIntegral_const, smul_eq_mul]
    have : P.real S ≠ 0 := (measureReal_ne_zero_iff).mpr h
    field_simp

lemma partition_cell_mse {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsFiniteMeasure P] (S : Set Ω) (X : Ω → ℝ) (hX : MemLp X 2 P) (a c : ℝ)
    (ha : a * P.real S = ∫ x in S, X x ∂P) :
    ∫⁻ ω in S, ENNReal.ofReal ((X ω - a) ^ 2) ∂P ≤
      ∫⁻ ω in S, ENNReal.ofReal ((X ω - c) ^ 2) ∂P := by
  have hXi : Integrable X P := hX.integrable one_le_two
  have hsq : ∀ b : ℝ, Integrable (fun ω => (X ω - b) ^ 2) P := fun b =>
    (hX.sub (memLp_const b)).integrable_sq
  rw [← ofReal_integral_eq_lintegral_ofReal (hsq a).integrableOn
      (Filter.Eventually.of_forall fun _ => sq_nonneg _),
    ← ofReal_integral_eq_lintegral_ofReal (hsq c).integrableOn
      (Filter.Eventually.of_forall fun _ => sq_nonneg _)]
  apply ENNReal.ofReal_le_ofReal
  have e : ∀ ω, (X ω - c) ^ 2 = (X ω - a) ^ 2 + (2 * (a - c) * X ω + (c ^ 2 - a ^ 2)) := by
    intro ω; ring
  have hint : ∫ ω in S, (X ω - c) ^ 2 ∂P =
      ∫ ω in S, (X ω - a) ^ 2 ∂P + (2 * (a - c) * ∫ ω in S, X ω ∂P + P.real S * (c ^ 2 - a ^ 2)) := by
    simp_rw [e]
    have h1 : IntegrableOn (fun ω => 2 * (a - c) * X ω) S P := (hXi.const_mul _).integrableOn
    have h2 : IntegrableOn (fun _ : Ω => c ^ 2 - a ^ 2) S P := (integrable_const _).integrableOn
    have h3 : IntegrableOn (fun ω => 2 * (a - c) * X ω + (c ^ 2 - a ^ 2)) S P := h1.add h2
    rw [integral_add (hsq a).integrableOn h3, integral_add h1 h2,
      integral_const_mul, setIntegral_const, smul_eq_mul]
  rw [hint, ← ha]
  have hr : 0 ≤ P.real S := measureReal_nonneg
  nlinarith [mul_nonneg hr (sq_nonneg (a - c))]

/-- The cell average is the conditional expectation. Let the cells B i (at most countably many)
be events that do not overlap and together cover all outcomes, let P be a probability measure,
and let X be integrable. Let Y be any forecast that is constant on every cell and, on every cell
of positive probability, equals X's average over that cell, the integral of X over the cell
divided by the cell's probability (cells of probability 0 get a free value). Then Y is
integrable, Y has the same integral as X over every set of the sigma-algebra generated by the
cells, and any other integrable Z that is constant on cells and has the same integral as X over
every set of that sigma-algebra equals Y almost surely. -/
theorem cell_average_is_conditional_expectation {Ω ι : Type*} [MeasurableSpace Ω] [Countable ι]
    (P : Measure Ω) [IsProbabilityMeasure P]
    (B : ι → Set Ω) (hmeas : ∀ i, MeasurableSet (B i)) (hdisj : Pairwise (Function.onFun Disjoint B))
    (hcover : ⋃ i, B i = Set.univ)
    (X : Ω → ℝ) (hX : Integrable X P)
    (Y : Ω → ℝ) (hYconst : ∀ i, ∀ ω ∈ B i, ∀ ω' ∈ B i, Y ω = Y ω')
    (hYavg : ∀ i, P (B i) ≠ 0 → ∀ ω ∈ B i, Y ω = (∫ x in B i, X x ∂P) / P.real (B i)) :
    Integrable Y P ∧
    (∀ A, MeasurableSet[MeasurableSpace.generateFrom (Set.range B)] A →
      ∫ x in A, Y x ∂P = ∫ x in A, X x ∂P) ∧
    (∀ Z : Ω → ℝ, (∀ i, ∀ ω ∈ B i, ∀ ω' ∈ B i, Z ω = Z ω') → Integrable Z P →
      (∀ A, MeasurableSet[MeasurableSpace.generateFrom (Set.range B)] A →
        ∫ x in A, Z x ∂P = ∫ x in A, X x ∂P) →
      Z =ᵐ[P] Y) := by
  classical
  have hsig := partition_sigma_helper B hdisj hcover
  have hle : MeasurableSpace.generateFrom (Set.range B) ≤ ‹MeasurableSpace Ω› :=
    MeasurableSpace.generateFrom_le (by rintro _ ⟨i, rfl⟩; exact hmeas i)
  have hYm : Measurable Y := ((hsig.2 Y).mpr hYconst).mono hle le_rfl
  have hInt : Integrable Y P := by
    refine ⟨hYm.aestronglyMeasurable, ?_⟩
    refine lt_of_le_of_lt ?_ hX.2
    rw [partition_lintegral_eq_tsum P B hmeas hdisj hcover,
      partition_lintegral_eq_tsum P B hmeas hdisj hcover]
    refine tsum_le_tsum fun i => ?_
    by_cases h : P (B i) = 0
    · simp [Measure.restrict_eq_zero.mpr h]
    · have hr : P.real (B i) ≠ 0 := (measureReal_ne_zero_iff).mpr h
      rw [setLIntegral_congr_fun (hmeas i) (fun ω hω => by
          show ‖Y ω‖ₑ = ‖(∫ x in B i, X x ∂P) / P.real (B i)‖ₑ
          rw [hYavg i h ω hω]), setLIntegral_const]
      calc ‖(∫ x in B i, X x ∂P) / P.real (B i)‖ₑ * P (B i)
          = ‖(∫ x in B i, X x ∂P) / P.real (B i)‖ₑ * ‖P.real (B i)‖ₑ := by
            rw [Real.enorm_of_nonneg measureReal_nonneg, ofReal_measureReal]
        _ = ‖(∫ x in B i, X x ∂P) / P.real (B i) * P.real (B i)‖ₑ := (enorm_mul _ _).symm
        _ = ‖∫ x in B i, X x ∂P‖ₑ := by rw [div_mul_cancel₀ _ hr]
        _ ≤ ∫⁻ x in B i, ‖X x‖ₑ ∂P := enorm_integral_le_lintegral_enorm _
  refine ⟨hInt, ?_, ?_⟩
  · intro A hA
    obtain ⟨I, rfl⟩ := (hsig.1 A).mp hA
    have hAi : ∀ i, (⋃ j ∈ I, B j) ∩ B i = if i ∈ I then B i else ∅ := by
      intro i
      split_ifs with hi
      · exact Set.inter_eq_right.mpr (Set.subset_biUnion_of_mem hi)
      · ext ω
        simp only [Set.mem_inter_iff, Set.mem_iUnion, exists_prop, Set.mem_empty_iff_false,
          iff_false, not_and]
        rintro ⟨j, hj, hωj⟩ hωi
        exact hi (partition_cell_unique B hdisj hωj hωi ▸ hj)
    have hU : (⋃ j ∈ I, B j) = ⋃ i, ((⋃ j ∈ I, B j) ∩ B i) := by
      rw [← Set.inter_iUnion, hcover, Set.inter_univ]
    have hm : ∀ i, MeasurableSet ((⋃ j ∈ I, B j) ∩ B i) := fun i =>
      (MeasurableSet.biUnion I.to_countable fun j _ => hmeas j).inter (hmeas i)
    have hd : Pairwise (Function.onFun Disjoint fun i => (⋃ j ∈ I, B j) ∩ B i) :=
      fun i j hij => (hdisj hij).mono Set.inter_subset_right Set.inter_subset_right
    rw [hU, integral_iUnion hm hd hInt.integrableOn, integral_iUnion hm hd hX.integrableOn]
    congr 1
    ext i
    rw [hAi i]
    split_ifs with hi
    · exact partition_cell_integral_eq P (B i) (hmeas i) X Y (fun h ω hω => hYavg i h ω hω)
    · simp
  · intro Z hZconst hZ hZint
    have hcell : ∀ i, P (B i) ≠ 0 → ∀ ω ∈ B i, Z ω = Y ω := by
      intro i h ω hω
      have hr : P.real (B i) ≠ 0 := (measureReal_ne_zero_iff).mpr h
      have h1 := hZint (B i) (MeasurableSpace.measurableSet_generateFrom ⟨i, rfl⟩)
      rw [setIntegral_congr_fun (hmeas i) (fun ω' hω' => hZconst i ω' hω' ω hω),
        setIntegral_const, smul_eq_mul] at h1
      rw [hYavg i h ω hω, ← h1]
      field_simp
    rw [Filter.EventuallyEq, ae_iff]
    refine measure_mono_null (t := ⋃ i, {ω | ω ∈ B i ∧ P (B i) = 0}) ?_
      (measure_iUnion_null fun i => ?_)
    · intro ω hω
      obtain ⟨i, hi⟩ := Set.mem_iUnion.mp (hcover ▸ Set.mem_univ ω)
      refine Set.mem_iUnion.mpr ⟨i, hi, ?_⟩
      by_contra h
      exact hω (hcell i h ω hi)
    · by_cases h : P (B i) = 0
      · exact measure_mono_null (fun ω hω => hω.1) h
      · simp [h]

/-- The cells' sigma-algebra is the information. For at most countably many cells that do not
overlap and cover all outcomes, the sigma-algebra they generate consists exactly of the unions
of whole cells, and a real function is measurable with respect to it exactly when it is constant
on every cell. -/
theorem partition_sigma_algebra_is_unions_of_cells {Ω ι : Type*} [Countable ι]
    (B : ι → Set Ω) (hdisj : Pairwise (Function.onFun Disjoint B))
    (hcover : ⋃ i, B i = Set.univ) :
    (∀ A : Set Ω, MeasurableSet[MeasurableSpace.generateFrom (Set.range B)] A ↔
      ∃ I : Set ι, A = ⋃ i ∈ I, B i) ∧
    (∀ Z : Ω → ℝ, Measurable[MeasurableSpace.generateFrom (Set.range B)] Z ↔
      ∀ i, ∀ ω ∈ B i, ∀ ω' ∈ B i, Z ω = Z ω') := by
  exact partition_sigma_helper B hdisj hcover

/-- The cell average is the best cell-constant forecast. With the same partition and P, let X
have a finite second moment, and let Y be the cell-average forecast as above. Then every
forecast Z that is constant on cells has mean squared error E[(X - Z)^2] at least that of Y. -/
theorem cell_average_least_mean_squared_error {Ω ι : Type*} [MeasurableSpace Ω] [Countable ι]
    (P : Measure Ω) [IsProbabilityMeasure P]
    (B : ι → Set Ω) (hmeas : ∀ i, MeasurableSet (B i)) (hdisj : Pairwise (Function.onFun Disjoint B))
    (hcover : ⋃ i, B i = Set.univ)
    (X : Ω → ℝ) (hX : MemLp X 2 P)
    (Y : Ω → ℝ) (hYconst : ∀ i, ∀ ω ∈ B i, ∀ ω' ∈ B i, Y ω = Y ω')
    (hYavg : ∀ i, P (B i) ≠ 0 → ∀ ω ∈ B i, Y ω = (∫ x in B i, X x ∂P) / P.real (B i))
    (Z : Ω → ℝ) (hZconst : ∀ i, ∀ ω ∈ B i, ∀ ω' ∈ B i, Z ω = Z ω') :
    ∫⁻ ω, ENNReal.ofReal ((X ω - Y ω) ^ 2) ∂P ≤ ∫⁻ ω, ENNReal.ofReal ((X ω - Z ω) ^ 2) ∂P := by
  rw [partition_lintegral_eq_tsum P B hmeas hdisj hcover,
    partition_lintegral_eq_tsum P B hmeas hdisj hcover]
  refine tsum_le_tsum fun i => ?_
  by_cases h : P (B i) = 0
  · simp [Measure.restrict_eq_zero.mpr h]
  · obtain ⟨ω0, hω0⟩ := nonempty_of_measure_ne_zero h
    have eY : ∫⁻ ω in B i, ENNReal.ofReal ((X ω - Y ω) ^ 2) ∂P =
        ∫⁻ ω in B i, ENNReal.ofReal ((X ω - Y ω0) ^ 2) ∂P :=
      setLIntegral_congr_fun (hmeas i) (fun ω hω => by
        simp only [hYconst i ω hω ω0 hω0])
    have eZ : ∫⁻ ω in B i, ENNReal.ofReal ((X ω - Z ω) ^ 2) ∂P =
        ∫⁻ ω in B i, ENNReal.ofReal ((X ω - Z ω0) ^ 2) ∂P :=
      setLIntegral_congr_fun (hmeas i) (fun ω hω => by
        simp only [hZconst i ω hω ω0 hω0])
    rw [eY, eZ]
    apply partition_cell_mse P (B i) X hX
    rw [hYavg i h ω0 hω0]
    have : P.real (B i) ≠ 0 := (measureReal_ne_zero_iff).mpr h
    field_simp

-- The rain gauge. Months Dec, Jan, ..., Nov are 0 to 11; rainfall in mm.
-- Yearly average 55 mm.
example : ((20 + 30 + 40 + 45 + 60 + 75 + 80 + 100 + 90 + 55 + 40 + 25 : ℚ)) / 12 = 55 := by norm_num
-- Season averages: winter 30, spring 60, summer 90, autumn 40.
example : ((20 + 30 + 40 : ℚ)) / 3 = 30 := by norm_num
example : ((45 + 60 + 75 : ℚ)) / 3 = 60 := by norm_num
example : ((80 + 100 + 90 : ℚ)) / 3 = 90 := by norm_num
example : ((55 + 40 + 25 : ℚ)) / 3 = 40 := by norm_num
-- The season forecast averages back to the yearly average: 1/4 (30 + 60 + 90 + 40) = 55.
example : (1 / 4 : ℚ) * (30 + 60 + 90 + 40) = 55 := by norm_num
-- Summer: E[X 1_B] = (80 + 100 + 90)/12 = 45/2, P(B) = 1/4, forecast 90.
example : ((80 + 100 + 90 : ℚ)) * (1 / 12) = 45 / 2 := by norm_num
example : ((45 / 2 : ℚ)) / (1 / 4) = 90 := by norm_num
-- The constant 55 fails on summer: its total there is 55/4, not 45/2.
example : (55 : ℚ) * (1 / 4) = 55 / 4 ∧ (55 / 4 : ℚ) ≠ 45 / 2 := by norm_num
-- Spring or summer: 1/4 * 60 + 1/4 * 90 = 75/2, the rainfall's own total over those six months.
example : (1 / 4 : ℚ) * 60 + 1 / 4 * 90 = ((45 + 60 + 75 + 80 + 100 + 90 : ℚ)) / 12 := by norm_num
-- On July alone, outside the season sigma-algebra: 90/12 against 100/12, no match.
example : (90 : ℚ) / 12 ≠ 100 / 12 := by norm_num
-- Half-year: cool Sep to Feb averages 35, warm Mar to Aug averages 75.
example : ((55 + 40 + 25 + 20 + 30 + 40 : ℚ)) / 6 = 35 := by norm_num
example : ((45 + 60 + 75 + 80 + 100 + 90 : ℚ)) / 6 = 75 := by norm_num
-- Sets in the sigma-algebras of 1, 2, 4, 12 cells: 2, 4, 16, 4096; with the 13th null cell, 32.
example : (2 ^ 1, 2 ^ 2, 2 ^ 4, 2 ^ 12, 2 ^ 5) = ((2, 4, 16, 4096, 32) : ℕ × ℕ × ℕ × ℕ × ℕ) := by decide
-- Mean squared errors: nothing known 1900/3 (the variance of X), half-year 700/3, season 325/3.
example : (((-35) ^ 2 + (-25) ^ 2 + (-15) ^ 2 + (-10) ^ 2 + 5 ^ 2 + 20 ^ 2 + 25 ^ 2 + 45 ^ 2
    + 35 ^ 2 + 0 ^ 2 + (-15) ^ 2 + (-30) ^ 2 : ℚ)) / 12 = 1900 / 3 := by norm_num
example : (((20 - 35) ^ 2 + (30 - 35) ^ 2 + (40 - 35) ^ 2 + (45 - 75) ^ 2 + (60 - 75) ^ 2
    + (75 - 75) ^ 2 + (80 - 75) ^ 2 + (100 - 75) ^ 2 + (90 - 75) ^ 2 + (55 - 35) ^ 2
    + (40 - 35) ^ 2 + (25 - 35) ^ 2 : ℚ)) / 12 = 700 / 3 := by norm_num
example : (((20 - 30) ^ 2 + (30 - 30) ^ 2 + (40 - 30) ^ 2 + (45 - 60) ^ 2 + (60 - 60) ^ 2
    + (75 - 60) ^ 2 + (80 - 90) ^ 2 + (100 - 90) ^ 2 + (90 - 90) ^ 2 + (55 - 40) ^ 2
    + (40 - 40) ^ 2 + (25 - 40) ^ 2 : ℚ)) / 12 = 325 / 3 := by norm_num
-- Between plus within equals total: the season forecast's spread 525 plus its error 325/3 is 1900/3.
example : (3 * ((30 - 55) ^ 2 + (60 - 55) ^ 2 + (90 - 55) ^ 2 + (40 - 55) ^ 2) : ℚ) / 12 + 325 / 3
    = 1900 / 3 := by norm_num
-- Integrability fails: X = 2^n with chance 2^-n gives running totals 10, 20, 40.
example : ∑ j ∈ Finset.range 10, (1 / 2 ^ (j + 1) : ℚ) * 2 ^ (j + 1) = 10 := by
  norm_num [Finset.sum_range_succ]
example : ∑ j ∈ Finset.range 20, (1 / 2 ^ (j + 1) : ℚ) * 2 ^ (j + 1) = 20 := by
  norm_num [Finset.sum_range_succ]
example : ∑ j ∈ Finset.range 40, (1 / 2 ^ (j + 1) : ℚ) * 2 ^ (j + 1) = 40 := by
  norm_num [Finset.sum_range_succ]

#print axioms cell_average_is_conditional_expectation
#print axioms partition_sigma_algebra_is_unions_of_cells
#print axioms cell_average_least_mean_squared_error
#print axioms partition_cell_unique
#print axioms partition_sigma_helper
#print axioms partition_lintegral_eq_tsum
#print axioms partition_cell_integral_eq
#print axioms partition_cell_mse
