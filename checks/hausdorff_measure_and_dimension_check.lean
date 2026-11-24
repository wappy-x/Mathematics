-- Hausdorff measure and dimension: the Cantor set has Hausdorff dimension log 2 / log 3 with size between 1/2 and 1 there, Hausdorff measure scales by r^s and equals length on the line, and it jumps from infinity to 0 at one power.
import Mathlib.Topology.MetricSpace.HausdorffDimension
import Mathlib.Topology.Instances.CantorSet
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Lp.MeasurableSpace
import Mathlib.Probability.ProductMeasure

open MeasureTheory Measure Set
open scoped ENNReal Pointwise

lemma cantorAux_ofDigits_three (a : ℕ → Fin 3) :
    Real.ofDigits a = ((a 0 : ℕ) : ℝ) / 3 + 3⁻¹ * Real.ofDigits (fun i => a (i + 1)) := by
  rw [Real.ofDigits_eq_sum_add_ofDigits a 1]
  simp [Real.ofDigitsTerm]
  ring

lemma cantorAux_sep (f g : ℕ → Bool) (m : ℕ) (h : ∀ i < m, f i = g i) (hm : f m ≠ g m) :
    (3⁻¹ : ℝ) ^ (m + 1) ≤ |Real.ofDigits (fun i => cond (f i) (2 : Fin 3) 0) -
      Real.ofDigits (fun i => cond (g i) (2 : Fin 3) 0)| := by
  rw [Real.ofDigits_eq_sum_add_ofDigits _ m, Real.ofDigits_eq_sum_add_ofDigits (fun i => cond (g i) (2 : Fin 3) 0) m]
  have hsum : ∑ i ∈ Finset.range m, Real.ofDigitsTerm (fun i => cond (f i) (2 : Fin 3) 0) i =
      ∑ i ∈ Finset.range m, Real.ofDigitsTerm (fun i => cond (g i) (2 : Fin 3) 0) i :=
    Finset.sum_congr rfl fun i hi ↦ by simp [Real.ofDigitsTerm, h i (Finset.mem_range.mp hi)]
  rw [hsum, add_sub_add_left_eq_sub, ← mul_sub, abs_mul, abs_of_nonneg (by positivity),
    cantorAux_ofDigits_three (fun i => cond (f (i + m)) (2 : Fin 3) 0),
    cantorAux_ofDigits_three (fun i => cond (g (i + m)) (2 : Fin 3) 0)]
  have a1 := Real.ofDigits_nonneg (fun i => cond (f (i + 1 + m)) (2 : Fin 3) 0)
  have a2 := Real.ofDigits_le_one (fun i => cond (f (i + 1 + m)) (2 : Fin 3) 0)
  have b1 := Real.ofDigits_nonneg (fun i => cond (g (i + 1 + m)) (2 : Fin 3) 0)
  have b2 := Real.ofDigits_le_one (fun i => cond (g (i + 1 + m)) (2 : Fin 3) 0)
  simp only [zero_add]
  generalize Real.ofDigits (fun i => cond (f (i + 1 + m)) (2 : Fin 3) 0) = X at *
  generalize Real.ofDigits (fun i => cond (g (i + 1 + m)) (2 : Fin 3) 0) = Y at *
  have key : (3⁻¹ : ℝ) ≤ |(((cond (f m) (2 : Fin 3) 0 : Fin 3) : ℕ) : ℝ) / 3 + 3⁻¹ * X -
      ((((cond (g m) (2 : Fin 3) 0 : Fin 3) : ℕ) : ℝ) / 3 + 3⁻¹ * Y)| := by
    cases hf : f m <;> cases hg : g m <;> rw [hf, hg] at hm
    · exact absurd rfl hm
    · norm_num; rw [abs_of_neg (by linarith)]; linarith
    · norm_num; rw [abs_of_pos (by linarith)]; linarith
    · exact absurd rfl hm
  rw [pow_succ, inv_pow]
  calc ((3:ℝ) ^ m)⁻¹ * 3⁻¹ ≤ ((3:ℝ) ^ m)⁻¹ * _ := by gcongr
    _ = _ := rfl

lemma cantorAux_s0_pos : 0 < Real.log 2 / Real.log 3 :=
  div_pos (Real.log_pos (by norm_num)) (Real.log_pos (by norm_num))

lemma cantorAux_rpow (k : ℕ) :
    ((3⁻¹ : ℝ) ^ k) ^ (Real.log 2 / Real.log 3) = (2⁻¹ : ℝ) ^ k := by
  have h3 : (3 : ℝ) ^ (Real.log 2 / Real.log 3) = 2 := by
    rw [Real.rpow_def_of_pos (by norm_num),
      mul_div_cancel₀ _ (Real.log_pos (by norm_num : (1:ℝ) < 3)).ne', Real.exp_log (by norm_num)]
  rw [← Real.rpow_natCast, ← Real.rpow_mul (by norm_num), mul_comm, Real.rpow_mul (by norm_num),
    Real.inv_rpow (by norm_num), h3, Real.rpow_natCast]

lemma cantorAux_ennreal (k : ℕ) :
    ENNReal.ofReal ((3⁻¹ : ℝ) ^ k) ^ (Real.log 2 / Real.log 3) = (2⁻¹ : ℝ≥0∞) ^ k := by
  rw [ENNReal.ofReal_rpow_of_nonneg (by positivity) cantorAux_s0_pos.le, cantorAux_rpow,
    ENNReal.ofReal_pow (by norm_num), ENNReal.ofReal_inv_of_pos (by norm_num)]
  simp

lemma cantorAux_upper : μH[Real.log 2 / Real.log 3] cantorSet ≤ 1 := by
  set φ : (ℕ → Bool) → ℝ := fun f => Real.ofDigits (fun i => cond (f i) (2 : Fin 3) 0) with hφ
  have hcov : ∀ n : ℕ, cantorSet ⊆ ⋃ b : Fin n → Bool, φ '' {f | ∀ i : Fin n, f i = b i} := by
    intro n x hx
    obtain ⟨y, rfl⟩ : ∃ y, φ y = x := ⟨cantorSetEquivNatToBool ⟨x, hx⟩,
      congrArg Subtype.val (cantorSetEquivNatToBool.symm_apply_apply ⟨x, hx⟩)⟩
    exact mem_iUnion.2 ⟨fun i => y i, y, fun i => rfl, rfl⟩
  have hdiam : ∀ n (b : Fin n → Bool), Metric.ediam (φ '' {f | ∀ i : Fin n, f i = b i}) ≤
      ENNReal.ofReal ((3⁻¹ : ℝ) ^ n) := by
    intro n b
    apply Metric.ediam_le
    rintro _ ⟨f, hf, rfl⟩ _ ⟨g, hg, rfl⟩
    rw [edist_dist, Real.dist_eq]
    apply ENNReal.ofReal_le_ofReal
    have := Real.abs_ofDigits_sub_ofDigits_le (b := 3) (n := n)
      (x := fun i => cond (f i) (2 : Fin 3) 0) (y := fun i => cond (g i) (2 : Fin 3) 0)
      (fun i hi => by simp only [hf ⟨i, hi⟩, hg ⟨i, hi⟩])
    refine this.trans_eq ?_
    push_cast
    rw [inv_pow]
  have hr : Filter.Tendsto (fun n : ℕ => ENNReal.ofReal ((3⁻¹ : ℝ) ^ n)) Filter.atTop (nhds 0) := by
    rw [← ENNReal.ofReal_zero]
    exact ENNReal.tendsto_ofReal
      (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num))
  refine (hausdorffMeasure_le_liminf_sum (ι := fun n => Fin n → Bool) (l := Filter.atTop) _ cantorSet _ hr
    (fun n b => φ '' {f | ∀ i : Fin n, f i = b i}) (Filter.Eventually.of_forall hdiam)
    (Filter.Eventually.of_forall hcov)).trans ?_
  have hsum : ∀ n : ℕ, ∑ b : Fin n → Bool, Metric.ediam (φ '' {f | ∀ i : Fin n, f i = b i}) ^
      (Real.log 2 / Real.log 3) ≤ 1 := by
    intro n
    calc ∑ b : Fin n → Bool, Metric.ediam (φ '' {f | ∀ i : Fin n, f i = b i}) ^ (Real.log 2 / Real.log 3)
        ≤ ∑ _b : Fin n → Bool, (2⁻¹ : ℝ≥0∞) ^ n := Finset.sum_le_sum fun b _ =>
          (ENNReal.rpow_le_rpow (hdiam n b) cantorAux_s0_pos.le).trans_eq (cantorAux_ennreal n)
      _ = 1 := by
        rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
        simp only [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin, Nat.cast_pow,
          Nat.cast_ofNat]
        rw [← mul_pow, ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top, one_pow]
  exact (Filter.liminf_le_liminf (Filter.Eventually.of_forall hsum)).trans
    (le_of_eq (Filter.liminf_const (f := (Filter.atTop : Filter ℕ)) (1 : ℝ≥0∞)))

lemma cantorAux_bool_prob :
    IsProbabilityMeasure ((2⁻¹ : ℝ≥0∞) • (Measure.dirac true + Measure.dirac false)) := by
  constructor
  simp only [Measure.smul_apply, Measure.add_apply, measure_univ, smul_eq_mul]
  rw [one_add_one_eq_two, ENNReal.inv_mul_cancel two_ne_zero ENNReal.ofNat_ne_top]

lemma cantorAux_bool_singleton (b : Bool) :
    ((2⁻¹ : ℝ≥0∞) • (Measure.dirac true + Measure.dirac false)) {b} = 2⁻¹ := by
  cases b <;> simp

lemma cantorAux_lower : (1 / 2 : ℝ≥0∞) ≤ μH[Real.log 2 / Real.log 3] cantorSet := by
  set φ : (ℕ → Bool) → ℝ := fun f => Real.ofDigits (fun i => cond (f i) (2 : Fin 3) 0) with hφ
  have hφm : Measurable φ := (Real.continuous_ofDigits.comp (by fun_prop)).measurable
  have := cantorAux_bool_prob
  set μ : Measure ℝ := (Measure.infinitePi
    (fun _ : ℕ => (2⁻¹ : ℝ≥0∞) • (Measure.dirac true + Measure.dirac false))).map φ with hμ
  have hC : μ cantorSet = 1 := by
    rw [hμ, Measure.map_apply hφm isClosed_cantorSet.measurableSet]
    have : φ ⁻¹' cantorSet = univ :=
      eq_univ_of_forall fun f => ofDigits_bool_to_fin_three_mem_cantorSet f
    rw [this, measure_univ]
  have hcyl : ∀ (k : ℕ) (s : Set ℝ), Metric.ediam s < ENNReal.ofReal ((3⁻¹ : ℝ) ^ k) →
      μ s ≤ (2⁻¹ : ℝ≥0∞) ^ k := by
    intro k s hs
    refine (measure_mono subset_closure).trans ?_
    rw [hμ, Measure.map_apply hφm isClosed_closure.measurableSet]
    rcases (φ ⁻¹' closure s).eq_empty_or_nonempty with h | ⟨f₀, hf₀⟩
    · simp [h]
    have hsub : φ ⁻¹' closure s ⊆ Set.pi (↑(Finset.range k)) (fun i => {f₀ i}) := by
      intro g hg
      simp only [Set.mem_pi, Finset.coe_range, mem_Iio, mem_singleton_iff]
      by_contra hne
      push Not at hne
      have hex : ∃ i, g i ≠ f₀ i := let ⟨i, _, hi⟩ := hne; ⟨i, hi⟩
      classical
      have hm : g (Nat.find hex) ≠ f₀ (Nat.find hex) := Nat.find_spec hex
      have hlt : ∀ i < Nat.find hex, g i = f₀ i := fun i hi => of_not_not (Nat.find_min hex hi)
      have hmk : Nat.find hex < k := by
        obtain ⟨i, hik, hi⟩ := hne
        exact lt_of_le_of_lt (Nat.find_min' hex hi) hik
      have hsep := cantorAux_sep g f₀ (Nat.find hex) hlt hm
      have hd : edist (φ g) (φ f₀) < ENNReal.ofReal ((3⁻¹ : ℝ) ^ k) :=
        (Metric.edist_le_ediam_of_mem (show φ g ∈ closure s from hg) (show φ f₀ ∈ closure s from hf₀)).trans_lt (by rwa [Metric.ediam_closure])
      rw [edist_dist, Real.dist_eq, ENNReal.ofReal_lt_ofReal_iff (by positivity)] at hd
      have : (3⁻¹ : ℝ) ^ k ≤ (3⁻¹ : ℝ) ^ (Nat.find hex + 1) :=
        pow_le_pow_of_le_one (by norm_num) (by norm_num) hmk
      simp only [hφ] at hd
      linarith
    refine (measure_mono hsub).trans_eq ?_
    rw [Measure.infinitePi_pi _ (fun i _ => measurableSet_singleton _)]
    simp only [cantorAux_bool_singleton, Finset.prod_const, Finset.card_range]
  have hle : (2⁻¹ : ℝ≥0∞) • μ ≤ μH[Real.log 2 / Real.log 3] := by
    refine le_mkMetric _ _ (ENNReal.ofReal (1 / 2)) (by simp) fun s hs => ?_
    rw [Measure.smul_apply, smul_eq_mul]
    rcases eq_or_ne (Metric.ediam s) 0 with h0 | h0
    · have : μ s = 0 := by
        refine le_antisymm (ge_of_tendsto' (ENNReal.tendsto_pow_atTop_nhds_zero_of_lt_one
          (by norm_num : (2⁻¹ : ℝ≥0∞) < 1)) fun k => hcyl k s ?_) (by positivity)
        rw [h0]
        exact ENNReal.ofReal_pos.2 (by positivity)
      simp [this]
    · have htop : Metric.ediam s ≠ ∞ := ne_top_of_le_ne_top ENNReal.ofReal_ne_top hs
      have hdpos : 0 < (Metric.ediam s).toReal := ENNReal.toReal_pos h0 htop
      have hD : Metric.ediam s = ENNReal.ofReal (Metric.ediam s).toReal :=
        (ENNReal.ofReal_toReal htop).symm
      generalize (Metric.ediam s).toReal = d at hdpos hD
      have hd2 : d ≤ 1 / 2 := by
        rw [hD] at hs
        exact (ENNReal.ofReal_le_ofReal_iff (by norm_num)).1 hs
      have hex : ∃ k : ℕ, (3⁻¹ : ℝ) ^ (k + 1) ≤ d := by
        obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one hdpos (by norm_num : (3⁻¹ : ℝ) < 1)
        exact ⟨n, (pow_le_pow_of_le_one (by norm_num) (by norm_num) n.le_succ).trans hn.le⟩
      classical
      have hk1 : (3⁻¹ : ℝ) ^ (Nat.find hex + 1) ≤ d := Nat.find_spec hex
      have hk2 : d < (3⁻¹ : ℝ) ^ Nat.find hex := by
        rcases Nat.eq_zero_or_pos (Nat.find hex) with hk | hk
        · rw [hk]; norm_num; linarith
        · have := Nat.find_min hex (show Nat.find hex - 1 < Nat.find hex by omega)
          rw [Nat.sub_add_cancel hk] at this
          exact lt_of_not_ge this
      have hμs := hcyl (Nat.find hex) s
        (by rw [hD, ENNReal.ofReal_lt_ofReal_iff (by positivity)]; exact hk2)
      calc 2⁻¹ * μ s ≤ 2⁻¹ * 2⁻¹ ^ Nat.find hex := by gcongr
        _ = 2⁻¹ ^ (Nat.find hex + 1) := by rw [pow_succ, mul_comm]
        _ = ENNReal.ofReal ((3⁻¹ : ℝ) ^ (Nat.find hex + 1)) ^ (Real.log 2 / Real.log 3) :=
          (cantorAux_ennreal _).symm
        _ ≤ ENNReal.ofReal d ^ (Real.log 2 / Real.log 3) :=
          ENNReal.rpow_le_rpow (ENNReal.ofReal_le_ofReal hk1) cantorAux_s0_pos.le
        _ = _ := by rw [← hD]
  calc (1 / 2 : ℝ≥0∞) = ((2⁻¹ : ℝ≥0∞) • μ) cantorSet := by
        rw [Measure.smul_apply, hC, smul_eq_mul, mul_one, one_div]
    _ ≤ _ := hle _

#print axioms cantorAux_ofDigits_three
#print axioms cantorAux_sep
#print axioms cantorAux_s0_pos
#print axioms cantorAux_rpow
#print axioms cantorAux_ennreal
#print axioms cantorAux_upper
#print axioms cantorAux_bool_prob
#print axioms cantorAux_bool_singleton
#print axioms cantorAux_lower

/-- The Cantor set at the power `s₀ = log 2 / log 3`: its `s₀`-dimensional Hausdorff
measure is at least 1/2 and at most 1, so its Hausdorff dimension is exactly
`log 2 / log 3` (about 0.6309). -/
theorem cantorSet_hausdorff_bounds_and_dimH :
    (1 / 2 : ℝ≥0∞) ≤ μH[Real.log 2 / Real.log 3] cantorSet ∧
      μH[Real.log 2 / Real.log 3] cantorSet ≤ 1 ∧
      dimH cantorSet = ENNReal.ofReal (Real.log 2 / Real.log 3) := by
  have hl := cantorAux_lower
  have hu := cantorAux_upper
  refine ⟨hl, hu, ?_⟩
  have hs0 := cantorAux_s0_pos
  have := dimH_of_hausdorffMeasure_ne_zero_ne_top
    (d := (Real.log 2 / Real.log 3).toNNReal) (s := cantorSet) ?_ ?_
  · rw [this]; rfl
  · rw [Real.coe_toNNReal _ hs0.le]; exact (lt_of_lt_of_le (by norm_num) hl).ne'
  · rw [Real.coe_toNNReal _ hs0.le]; exact ne_top_of_le_ne_top ENNReal.one_ne_top hu

/-- The two rules: in `ℝⁿ`, magnifying a set by `r > 0` multiplies its `s`-dimensional
Hausdorff measure by `r ^ s`; and on the line the 1-dimensional Hausdorff measure of every
set equals its Lebesgue outer measure (its length). -/
theorem hausdorffMeasure_scaling_and_length (n : ℕ) {s r : ℝ} (hs : 0 ≤ s) (hr : 0 < r)
    (A : Set (EuclideanSpace ℝ (Fin n))) :
    μH[s] (r • A) = ENNReal.ofReal r ^ s * μH[s] A ∧
      ∀ B : Set ℝ, μH[1] B = volume B := by
  refine ⟨?_, fun B => by rw [hausdorffMeasure_real]⟩
  rw [hausdorffMeasure_smul₀ hs hr.ne', ENNReal.smul_def, smul_eq_mul,
    ENNReal.coe_rpow_of_nonneg _ hs]
  congr 2
  rw [← enorm_eq_nnnorm, Real.enorm_eq_ofReal hr.le]

/-- The size jumps once: in `ℝⁿ`, if a set has finite `s`-dimensional Hausdorff measure,
then its `t`-dimensional Hausdorff measure is 0 for every higher power `t > s`. -/
theorem hausdorffMeasure_eq_zero_of_lt_of_ne_top (n : ℕ) {s t : ℝ} (hst : s < t)
    (A : Set (EuclideanSpace ℝ (Fin n))) (hA : μH[s] A ≠ ∞) :
    μH[t] A = 0 := by
  exact (hausdorffMeasure_zero_or_top hst A).resolve_right hA

-- Stage 5 of the Cantor set: 32 pieces, each 1/243 km long (4.12 m).
example : 2 ^ 5 = 32 ∧ 3 ^ 5 = 243 := by decide
-- Stage 10 has 1024 pieces; stage 20 has 1048576.
example : 2 ^ 10 = 1024 ∧ 2 ^ 20 = 1048576 := by decide
-- At s₀ each stage-k piece weighs 1/2^k, so 2^k pieces weigh 1 in total (stage 10).
example : (2 : ℚ) ^ 10 * (1 / 2 ^ 10) = 1 := by norm_num
-- Length of stage 10: (2/3)^10 km.
example : ((2 : ℚ) / 3) ^ 10 = 1024 / 59049 := by norm_num
-- The picture's U from 200 m to 300 m: Cantor mass F(3/10) - F(1/5) = 2/5 - 1/4 = 3/20.
example : (2 : ℚ) / 5 - 1 / 4 = 3 / 20 := by norm_num
-- U has width 1/10 km, between the stage-3 and stage-2 piece lengths 1/27 and 1/9 km.
example : (1 : ℚ) / 27 ≤ 1 / 10 ∧ (1 : ℚ) / 10 < 1 / 9 := by norm_num
-- The mass test: intervals with ends on multiples of 1/729 number 729 · 730 / 2 = 266085.
example : 729 * 730 / 2 = 266085 := by decide
-- Box counting on the fractions: 3, 9, 27, 81 boxes at widths 1/3, 1/9, 1/27, 1/81.
example : (3 ^ 1, 3 ^ 2, 3 ^ 3, 3 ^ 4) = (3, 9, 27, 81) := by decide
-- The Koch curve: stage k has 4^k pieces (stage 2: 16 pieces of length 1/9).
example : 4 ^ 2 = 16 := by decide

#print axioms cantorSet_hausdorff_bounds_and_dimH
#print axioms hausdorffMeasure_scaling_and_length
#print axioms hausdorffMeasure_eq_zero_of_lt_of_ne_top
