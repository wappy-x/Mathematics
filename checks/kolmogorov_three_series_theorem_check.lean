-- Kolmogorov's three-series theorem: a sum of independent random terms converges almost surely exactly when, after each term is cut off at a level A > 0, the chances of a cut, the means of the cut terms and their variances form three convergent series, and otherwise it diverges almost surely.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Independence.Integration
import Mathlib.Probability.BorelCantelli
import Mathlib.Probability.Moments.Variance
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Order.Filter.AtTopBot.Basic

open MeasureTheory ProbabilityTheory Filter Topology
open scoped ENNReal

lemma tsr_indep_split {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n)) (hind : iIndepFun X P)
    (k : ℕ) {f g : Ω → ℝ}
    (hf : Measurable[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (X i) inferInstance] f)
    (hg : Measurable[⨆ i ∈ {i | k ≤ i}, MeasurableSpace.comap (X i) inferInstance] g) :
    IndepFun f g P := by
  rw [IndepFun_iff_Indep]
  have h := indep_iSup_of_disjoint (m := fun i => MeasurableSpace.comap (X i) inferInstance)
    (fun i => (hX i).comap_le) hind.iIndep (S := {i | i < k}) (T := {i | k ≤ i})
    (Set.disjoint_left.2 fun i h1 h2 => (not_le.2 (show i < k from h1)) (show k ≤ i from h2))
  exact indep_of_indep_of_le_right (indep_of_indep_of_le_left h hf.comap_le) hg.comap_le

lemma tsr_meas_past {Ω : Type*} [MeasurableSpace Ω] (X : ℕ → Ω → ℝ) {k j : ℕ} (hj : j ≤ k) :
    Measurable[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (X i) inferInstance]
      (fun ω => ∑ i ∈ Finset.range j, X i ω) :=
  Finset.measurable_sum _ fun i hi => Measurable.of_comap_le
    (le_iSup₂ (f := fun i (_ : i ∈ {i | i < k}) => MeasurableSpace.comap (X i) inferInstance) i
      (show i < k from lt_of_lt_of_le (Finset.mem_range.1 hi) hj))

lemma tsr_meas_fut {Ω : Type*} [MeasurableSpace Ω] (X : ℕ → Ω → ℝ) {k : ℕ} (s : Finset ℕ)
    (hs : ∀ i ∈ s, k ≤ i) :
    Measurable[⨆ i ∈ {i | k ≤ i}, MeasurableSpace.comap (X i) inferInstance]
      (fun ω => ∑ i ∈ s, X i ω) :=
  Finset.measurable_sum _ fun i hi => Measurable.of_comap_le
    (le_iSup₂ (f := fun i (_ : i ∈ {i | k ≤ i}) => MeasurableSpace.comap (X i) inferInstance) i
      (hs i hi))

lemma tsr_past_le {Ω : Type*} [mΩ : MeasurableSpace Ω] (X : ℕ → Ω → ℝ)
    (hX : ∀ n, Measurable (X n)) (k : ℕ) :
    (⨆ i ∈ {i | i < k}, MeasurableSpace.comap (X i) inferInstance) ≤ mΩ :=
  iSup₂_le fun i _ => (hX i).comap_le

lemma tsr_maximal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n))
    (hind : iIndepFun X P) (hL2 : ∀ n, MemLp (X n) 2 P) (hmean : ∀ n, ∫ ω, X n ω ∂P = 0)
    {t : ℝ} (ht : 0 < t) (n : ℕ) :
    P {ω | ∃ k ≤ n, t ≤ |∑ i ∈ Finset.range k, X i ω|} ≤
      ENNReal.ofReal ((∑ i ∈ Finset.range n, Var[X i; P]) / t ^ 2) := by
  classical
  set S : ℕ → Ω → ℝ := fun j ω => ∑ i ∈ Finset.range j, X i ω with hS
  set A : ℕ → Set Ω := fun k => {ω | t ≤ |S k ω| ∧ ∀ j < k, |S j ω| < t} with hA
  have hSL : ∀ j, MemLp (S j) 2 P := fun j => by
    have := memLp_finsetSum' (Finset.range j) (fun i _ => hL2 i)
    convert this using 1; ext ω; simp [S]
  have hSm : ∀ j, Measurable (S j) := fun j => Finset.measurable_sum _ fun i _ => hX i
  have hApast : ∀ k, MeasurableSet[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (X i) inferInstance]
      (A k) := by
    intro k
    have h1 : MeasurableSet[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (X i) inferInstance]
        {ω | t ≤ |S k ω|} :=
      measurableSet_le measurable_const (continuous_abs.measurable.comp (tsr_meas_past X le_rfl))
    have h2 : MeasurableSet[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (X i) inferInstance]
        {ω | ∀ j < k, |S j ω| < t} := by
      simp only [Set.ofPred_forall]
      refine MeasurableSet.iInter fun j => MeasurableSet.iInter fun hj => ?_
      exact measurableSet_lt (continuous_abs.measurable.comp (tsr_meas_past X (le_of_lt hj)))
        measurable_const
    exact h1.inter h2
  have hAm : ∀ k, MeasurableSet (A k) := fun k => tsr_past_le X hX k _ (hApast k)
  have hunion : {ω | ∃ k ≤ n, t ≤ |S k ω|} = ⋃ k ∈ Finset.range (n+1), A k := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_range, A]
    constructor
    · rintro ⟨k, hk, hkt⟩
      have hex : ∃ k, t ≤ |S k ω| := ⟨k, hkt⟩
      refine ⟨Nat.find hex, by have := Nat.find_min' hex hkt; omega, Nat.find_spec hex,
        fun j hj => lt_of_not_ge (Nat.find_min hex hj)⟩
    · rintro ⟨k, hk, hkt, _⟩
      exact ⟨k, by omega, hkt⟩
  have hdisj : Set.Pairwise (↑(Finset.range (n+1))) (Function.onFun Disjoint A) := by
    intro k _ l _ hkl
    refine Set.disjoint_left.2 fun ω h1 h2 => ?_
    rcases lt_or_gt_of_ne hkl with h | h
    · exact absurd h1.1 (not_le.2 (h2.2 k h))
    · exact absurd h2.1 (not_le.2 (h1.2 l h))
  have hkey : ∀ k ≤ n, t ^ 2 * P.real (A k) ≤ ∫ ω in A k, S n ω ^ 2 ∂P := by
    intro k hk
    set R : Ω → ℝ := fun ω => ∑ i ∈ Finset.Ico k n, X i ω with hR
    have hSR : ∀ ω, S n ω = S k ω + R ω := fun ω => by
      simp only [S, R]; rw [Finset.sum_range_add_sum_Ico _ hk]
    set U : Ω → ℝ := (A k).indicator (S k) with hU
    have hUL : MemLp U 2 P := (hSL k).indicator (hAm k).nullMeasurableSet
    have hRL : MemLp R 2 P := by
      have := memLp_finsetSum' (Finset.Ico k n) (fun i _ => hL2 i)
      convert this using 1; ext ω; simp [R]
    have hind' : IndepFun U R P := tsr_indep_split X hX hind k
      ((tsr_meas_past X le_rfl).indicator (hApast k))
      (tsr_meas_fut X _ fun i hi => (Finset.mem_Ico.1 hi).1)
    have hR0 : ∫ ω, R ω ∂P = 0 := by
      simp only [R]
      rw [integral_finsetSum _ fun i _ => (hL2 i).integrable (by norm_num)]
      exact Finset.sum_eq_zero fun i _ => hmean i
    have hcross : ∫ ω, U ω * R ω ∂P = 0 := by
      rw [hind'.integral_fun_mul_eq_mul_integral hUL.aestronglyMeasurable
        hRL.aestronglyMeasurable, hR0, mul_zero]
    have iUR : Integrable (fun ω => U ω * R ω) P :=
      hind'.integrable_mul (hUL.integrable (by norm_num)) (hRL.integrable (by norm_num))
    have i1 : Integrable (fun ω => U ω ^ 2 + 2 * (U ω * R ω)) P :=
      hUL.integrable_sq.add (iUR.const_mul 2)
    have i2 : Integrable ((A k).indicator fun ω => S n ω ^ 2) P :=
      (hSL n).integrable_sq.indicator (hAm k)
    calc t ^ 2 * P.real (A k) = ∫ ω, (A k).indicator (fun _ => t ^ 2) ω ∂P := by
          rw [integral_indicator (hAm k), setIntegral_const, smul_eq_mul, mul_comm]
      _ ≤ ∫ ω, U ω ^ 2 ∂P := by
          refine integral_mono ((integrable_const _).indicator (hAm k)) hUL.integrable_sq
            fun ω => ?_
          by_cases h : ω ∈ A k
          · simp only [Set.indicator_of_mem h, U]
            have h1 := h.1
            nlinarith [sq_abs (S k ω), abs_nonneg (S k ω)]
          · simp [Set.indicator_of_notMem h, U]
      _ = ∫ ω, (U ω ^ 2 + 2 * (U ω * R ω)) ∂P := by
          rw [integral_add hUL.integrable_sq (iUR.const_mul 2), integral_const_mul, hcross]
          ring
      _ ≤ ∫ ω, (A k).indicator (fun ω => S n ω ^ 2) ω ∂P := by
          refine integral_mono i1 i2 fun ω => ?_
          by_cases h : ω ∈ A k
          · simp only [Set.indicator_of_mem h, U, hSR]
            nlinarith [sq_nonneg (R ω)]
          · simp [Set.indicator_of_notMem h, U]
      _ = ∫ ω in A k, S n ω ^ 2 ∂P := integral_indicator (hAm k)
  have hmeanS : ∫ ω, S n ω ∂P = 0 := by
    simp only [S]
    rw [integral_finsetSum _ fun i _ => (hL2 i).integrable (by norm_num)]
    exact Finset.sum_eq_zero fun i _ => hmean i
  have hE : P.real {ω | ∃ k ≤ n, t ≤ |S k ω|} * t ^ 2 ≤ ∑ i ∈ Finset.range n, Var[X i; P] := by
    rw [hunion, measureReal_biUnion_finset hdisj (fun k _ => hAm k), Finset.sum_mul]
    calc ∑ k ∈ Finset.range (n+1), P.real (A k) * t ^ 2
          ≤ ∑ k ∈ Finset.range (n+1), ∫ ω in A k, S n ω ^ 2 ∂P :=
          Finset.sum_le_sum fun k hk => by
            rw [mul_comm]; exact hkey k (Nat.lt_succ_iff.1 (Finset.mem_range.1 hk))
      _ = ∫ ω in ⋃ k ∈ Finset.range (n+1), A k, S n ω ^ 2 ∂P :=
          (integral_biUnion_finset _ (fun k _ => hAm k) hdisj
            fun k _ => (hSL n).integrable_sq.integrableOn).symm
      _ ≤ ∫ ω, S n ω ^ 2 ∂P := setIntegral_le_integral (hSL n).integrable_sq
            (Eventually.of_forall fun ω => sq_nonneg _)
      _ = Var[S n; P] := (variance_of_integral_eq_zero (hSm n).aemeasurable hmeanS).symm
      _ = ∑ i ∈ Finset.range n, Var[X i; P] := by
          rw [show S n = ∑ i ∈ Finset.range n, X i from by ext ω; simp [S]]
          exact IndepFun.variance_sum (fun i _ => hL2 i) (fun i _ j _ hij => hind.indepFun hij)
  show P {ω | ∃ k ≤ n, t ≤ |S k ω|} ≤ _
  rw [← ofReal_measureReal]
  refine ENNReal.ofReal_le_ofReal ?_
  rw [le_div_iff₀ (by positivity)]
  exact hE

lemma tsr_conv {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n))
    (hind : iIndepFun X P) (hmean : ∀ n, ∫ ω, X n ω ∂P = 0)
    (hvar : (∑' n, eVar[X n; P]) ≠ ∞) :
    ∀ᵐ ω ∂P, ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s) := by
  have hL2 : ∀ n, MemLp (X n) 2 P := fun n =>
    (evariance_lt_top_iff_memLp (hX n).aestronglyMeasurable).1
      (lt_of_le_of_lt (le_tsum (fun n => eVar[X n; P]) n) hvar.lt_top)
  have htail : ∀ (ε : ℝ), 0 < ε → ∀ m : ℕ,
      P {ω | ∃ k, ε ≤ |∑ i ∈ Finset.range k, X (i + m) ω|} ≤
        (∑' i, eVar[X (i + m); P]) / ENNReal.ofReal (ε ^ 2) := by
    intro ε hε m
    have hindm : iIndepFun (fun i => X (i + m)) P :=
      hind.precomp (g := fun i => i + m) (add_left_injective m)
    have hU : {ω | ∃ k, ε ≤ |∑ i ∈ Finset.range k, X (i + m) ω|} =
        ⋃ N, {ω | ∃ k ≤ N, ε ≤ |∑ i ∈ Finset.range k, X (i + m) ω|} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_iUnion]
      constructor
      · rintro ⟨k, hk⟩; exact ⟨k, k, le_rfl, hk⟩
      · rintro ⟨N, k, _, hk⟩; exact ⟨k, hk⟩
    have hmono : Monotone fun N => {ω | ∃ k ≤ N, ε ≤ |∑ i ∈ Finset.range k, X (i + m) ω|} := by
      intro a b hab ω ⟨k, hk, h⟩
      exact ⟨k, hk.trans hab, h⟩
    rw [hU, hmono.measure_iUnion]
    refine iSup_le fun N => ?_
    refine (tsr_maximal (fun i => X (i + m)) (fun i => hX (i + m)) hindm (fun i => hL2 (i + m))
      (fun i => hmean (i + m)) hε N).trans ?_
    rw [ENNReal.ofReal_div_of_pos (by positivity)]
    gcongr
    rw [ENNReal.ofReal_sum_of_nonneg fun i _ => variance_nonneg _ _]
    refine le_trans (le_of_eq ?_) (sum_le_tsum (Finset.range N))
    exact Finset.sum_congr rfl fun i _ => (hL2 (i + m)).ofReal_variance_eq
  have hnull : ∀ j : ℕ, P {ω | ∀ m, ∃ k,
      1 / ((j : ℝ) + 1) ≤ |∑ i ∈ Finset.range k, X (i + m) ω|} = 0 := by
    intro j
    have hε : (0 : ℝ) < 1 / ((j : ℝ) + 1) := by positivity
    have hlim : Tendsto (fun m => (∑' i, eVar[X (i + m); P]) / ENNReal.ofReal ((1 / ((j : ℝ) + 1)) ^ 2))
        atTop (𝓝 0) := by
      have := ENNReal.Tendsto.div_const (ENNReal.tendsto_sum_nat_add (fun n => eVar[X n; P]) hvar)
        (b := ENNReal.ofReal ((1 / ((j : ℝ) + 1)) ^ 2)) (Or.inr (by
          rw [ne_eq, ENNReal.ofReal_eq_zero, not_le]; positivity))
      simpa using this
    refine le_antisymm (ge_of_tendsto' hlim fun m => ?_) (zero_le)
    refine (measure_mono fun ω hω => ?_).trans (htail _ hε m)
    exact hω m
  have hae : ∀ᵐ ω ∂P, ∀ j : ℕ, ω ∉ {ω | ∀ m, ∃ k,
      1 / ((j : ℝ) + 1) ≤ |∑ i ∈ Finset.range k, X (i + m) ω|} :=
    ae_all_iff.2 fun j => measure_eq_zero_iff_ae_notMem.1 (hnull j)
  filter_upwards [hae] with ω hω
  refine cauchySeq_tendsto_of_complete (Metric.cauchySeq_iff'.2 fun ε hε => ?_)
  obtain ⟨j, hj⟩ := exists_nat_one_div_lt hε
  have h := hω j
  simp only [not_forall, not_exists, not_le] at h
  obtain ⟨m, hm⟩ := h
  refine ⟨m, fun n hn => ?_⟩
  rw [Real.dist_eq, ← Finset.sum_range_add_sum_Ico _ hn, add_sub_cancel_left,
    Finset.sum_Ico_eq_sum_range]
  have := hm (n - m)
  simp only [add_comm _ m] at this
  exact this.trans hj

lemma tsr_int {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsFiniteMeasure P] {f : Ω → ℝ}
    (hf : MemLp f 2 P) : Integrable f P := hf.integrable one_le_two

lemma tsr_converse {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (Y : ℕ → Ω → ℝ) (hY : ∀ n, Measurable (Y n)) (hind : iIndepFun Y P)
    {A : ℝ} (hA : 0 ≤ A) (hb : ∀ n ω, |Y n ω| ≤ A) {ε : ℝ} (hε : 0 ≤ ε) (n : ℕ) :
    P.real {ω | ∀ j ≤ n, |∑ i ∈ Finset.range j, Y i ω| ≤ ε} *
      ∑ j ∈ Finset.range n, Var[Y j; P] ≤ 2 * (2 * A + 2 * ε) ^ 2 := by
  classical
  set S : ℕ → Ω → ℝ := fun j ω => ∑ i ∈ Finset.range j, Y i ω with hS
  set M : ℕ → Set Ω := fun k => {ω | ∀ j ≤ k, |S j ω| ≤ ε} with hM
  set B : ℝ := 2 * A + 2 * ε with hB
  have hB0 : 0 ≤ B := by positivity
  have hYL : ∀ i, MemLp (Y i) 2 P := fun i =>
    memLp_of_bounded (a := -A) (b := A) (Eventually.of_forall fun ω => abs_le.1 (hb i ω))
      (hY i).aestronglyMeasurable 2
  have hSL : ∀ j, MemLp (S j) 2 P := fun j => by
    have := memLp_finsetSum' (Finset.range j) (fun i _ => hYL i)
    convert this using 1; ext ω; simp [S]
  have hMpast : ∀ k, MeasurableSet[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (Y i) inferInstance]
      (M k) := by
    intro k
    simp only [M, Set.ofPred_forall]
    refine MeasurableSet.iInter fun j => MeasurableSet.iInter fun hj => ?_
    exact measurableSet_le (continuous_abs.measurable.comp (tsr_meas_past Y hj)) measurable_const
  have hMm : ∀ k, MeasurableSet (M k) := fun k => tsr_past_le Y hY k _ (hMpast k)
  have hMsub : ∀ k, M (k+1) ⊆ M k := fun k ω h j hj => h j (by omega)
  set m : ℕ → ℝ := fun k => P.real (M k) with hm
  set a : ℕ → ℝ := fun k => (∫ ω in M k, S k ω ∂P) / m k with ha
  set Q : ℕ → ℝ := fun k => ∫ ω in M k, (S k ω - a k) ^ 2 ∂P with hQ
  have hm0 : ∀ k, 0 ≤ m k := fun k => measureReal_nonneg
  have hint_le : ∀ k, |∫ ω in M k, S k ω ∂P| ≤ ε * m k := by
    intro k
    have := norm_setIntegral_le_of_norm_le_const (μ := P) (s := M k) (f := S k) (C := ε)
      (measure_lt_top _ _) (fun ω hω => by simpa [Real.norm_eq_abs] using hω k le_rfl)
    simpa [Real.norm_eq_abs] using this
  have hF0 : ∀ k, m k * a k = ∫ ω in M k, S k ω ∂P := by
    intro k
    by_cases h0 : m k = 0
    · have h := hint_le k
      rw [h0, mul_zero] at h
      rw [h0, zero_mul]; exact (abs_nonpos_iff.1 h).symm
    · simp only [a]; field_simp
  have hF1 : ∀ k, ∫ ω in M k, (S k ω - a k) ∂P = 0 := by
    intro k
    rw [integral_sub (tsr_int (hSL k)).integrableOn (integrable_const _).integrableOn,
      setIntegral_const, smul_eq_mul, hF0, sub_self]
  have hF2 : ∀ k, |a k| ≤ ε := by
    intro k
    simp only [a]
    rw [abs_div, abs_of_nonneg (hm0 k)]
    exact div_le_of_le_mul₀ (hm0 k) hε (hint_le k)
  have hstep : ∀ k, Q k + m k * Var[Y k; P] ≤ Q (k+1) + 2 * B ^ 2 * (m k - m (k+1)) := by
    intro k
    set μk : ℝ := ∫ ω, Y k ω ∂P with hμk
    set b : ℝ := a k + μk with hb'
    set c : ℝ := a (k+1) - b with hc
    set g : Ω → ℝ := fun ω => S (k+1) ω - b with hg
    have hSsucc : ∀ ω, S (k+1) ω = S k ω + Y k ω := fun ω => Finset.sum_range_succ _ _
    have hμ : |μk| ≤ A := by
      have := norm_integral_le_of_norm_le_const (μ := P) (f := Y k) (C := A)
        (Eventually.of_forall fun ω => by simpa [Real.norm_eq_abs] using hb k ω)
      simpa [Real.norm_eq_abs] using this
    have hgL : MemLp g 2 P := (hSL (k+1)).sub (memLp_const b)
    set U : Ω → ℝ := (M k).indicator (fun ω => S k ω - a k) with hU
    set D : Ω → ℝ := fun ω => Y k ω - μk with hD
    set I : Ω → ℝ := (M k).indicator (fun _ => (1:ℝ)) with hI
    have hUm : Measurable[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (Y i) inferInstance] U :=
      ((tsr_meas_past Y le_rfl).sub measurable_const).indicator (hMpast k)
    have hIm : Measurable[⨆ i ∈ {i | i < k}, MeasurableSpace.comap (Y i) inferInstance] I :=
      measurable_const.indicator (hMpast k)
    have hYkf : Measurable[⨆ i ∈ {i | k ≤ i}, MeasurableSpace.comap (Y i) inferInstance] (Y k) :=
      Measurable.of_comap_le (le_iSup₂ (f := fun i (_ : i ∈ {i | k ≤ i}) =>
        MeasurableSpace.comap (Y i) inferInstance) k (show k ≤ k from le_rfl))
    have hDm : Measurable[⨆ i ∈ {i | k ≤ i}, MeasurableSpace.comap (Y i) inferInstance] D :=
      hYkf.sub measurable_const
    have hD2m : Measurable[⨆ i ∈ {i | k ≤ i}, MeasurableSpace.comap (Y i) inferInstance]
        (fun ω => D ω ^ 2) := hDm.pow_const 2
    have hUD : IndepFun U D P := tsr_indep_split Y hY hind k hUm hDm
    have hID : IndepFun I D P := tsr_indep_split Y hY hind k hIm hDm
    have hID2 : IndepFun I (fun ω => D ω ^ 2) P := tsr_indep_split Y hY hind k hIm hD2m
    have hUL : MemLp U 2 P :=
      ((hSL k).sub (memLp_const (a k))).indicator (hMm k).nullMeasurableSet
    have hDL : MemLp D 2 P := (hYL k).sub (memLp_const _)
    have hIL : MemLp I 2 P := (memLp_const (1:ℝ)).indicator (hMm k).nullMeasurableSet
    have hD0 : ∫ ω, D ω ∂P = 0 := by
      simp only [D]
      rw [integral_sub (tsr_int (hYL k)) (integrable_const _), integral_const]
      simp [μk]
    have hU0 : ∫ ω, U ω ∂P = 0 := by rw [integral_indicator (hMm k)]; exact hF1 k
    have hI1 : ∫ ω, I ω ∂P = m k := by
      rw [integral_indicator (hMm k), setIntegral_const, smul_eq_mul, mul_one]
    have hUDi : Integrable (fun ω => U ω * D ω) P :=
      hUD.integrable_mul (tsr_int hUL) (tsr_int hDL)
    have hIDi : Integrable (fun ω => I ω * D ω) P :=
      hID.integrable_mul (tsr_int hIL) (tsr_int hDL)
    have hID2i : Integrable (fun ω => I ω * D ω ^ 2) P :=
      hID2.integrable_mul (tsr_int hIL) hDL.integrable_sq
    have hUD0 : ∫ ω, U ω * D ω ∂P = 0 := by
      rw [hUD.integral_fun_mul_eq_mul_integral hUL.aestronglyMeasurable hDL.aestronglyMeasurable,
        hU0, zero_mul]
    have hID0 : ∫ ω, I ω * D ω ∂P = 0 := by
      rw [hID.integral_fun_mul_eq_mul_integral hIL.aestronglyMeasurable hDL.aestronglyMeasurable,
        hD0, mul_zero]
    have hID2v : ∫ ω, I ω * D ω ^ 2 ∂P = m k * Var[Y k; P] := by
      rw [hID2.integral_fun_mul_eq_mul_integral hIL.aestronglyMeasurable
        hDL.integrable_sq.aestronglyMeasurable, hI1, variance_eq_integral (hY k).aemeasurable]
    have i1 : Integrable ((M k).indicator fun ω => (S k ω - a k) ^ 2) P :=
      ((hSL k).sub (memLp_const (a k))).integrable_sq.indicator (hMm k)
    have hE1 : ∫ ω in M k, g ω ^ 2 ∂P = Q k + m k * Var[Y k; P] := by
      have hpt : (M k).indicator (fun ω => g ω ^ 2) = fun ω =>
          (M k).indicator (fun ω => (S k ω - a k) ^ 2) ω + 2 * (U ω * D ω) + I ω * D ω ^ 2 := by
        funext ω
        by_cases h : ω ∈ M k
        · simp only [Set.indicator_of_mem h, U, I, D, g, b, hSsucc]; ring
        · simp [Set.indicator_of_notMem h, U, I]
      have i12 : Integrable (fun ω => (M k).indicator (fun ω => (S k ω - a k) ^ 2) ω
          + 2 * (U ω * D ω)) P := i1.add (hUDi.const_mul 2)
      rw [← integral_indicator (hMm k), hpt, integral_add i12 hID2i,
        integral_add i1 (hUDi.const_mul 2), integral_const_mul, hUD0, hID2v,
        integral_indicator (hMm k)]
      simp [Q]
    have hE2 : ∫ ω in M k, g ω ∂P = 0 := by
      have hpt : (M k).indicator g = fun ω => U ω + I ω * D ω := by
        funext ω
        by_cases h : ω ∈ M k
        · simp only [Set.indicator_of_mem h, U, I, D, g, b, hSsucc]; ring
        · simp [Set.indicator_of_notMem h, U, I]
      rw [← integral_indicator (hMm k), hpt, integral_add (tsr_int hUL) hIDi, hU0, hID0,
        add_zero]
    have hS'L : MemLp (fun ω => S (k+1) ω - a (k+1)) 2 P := (hSL (k+1)).sub (memLp_const _)
    have hG1 : ∫ ω in M (k+1), g ω ^ 2 ∂P = Q (k+1) + c ^ 2 * m (k+1) := by
      have : ∀ ω, g ω ^ 2 = ((S (k+1) ω - a (k+1)) ^ 2 + 2 * c * (S (k+1) ω - a (k+1))) + c ^ 2 :=
        fun ω => by simp only [g, c]; ring
      simp_rw [this]
      have i12 : IntegrableOn (fun ω => (S (k+1) ω - a (k+1)) ^ 2
          + 2 * c * (S (k+1) ω - a (k+1))) (M (k+1)) P :=
        hS'L.integrable_sq.integrableOn.add ((tsr_int hS'L).integrableOn.const_mul _)
      rw [integral_add i12 (integrable_const _).integrableOn,
        integral_add hS'L.integrable_sq.integrableOn
          ((tsr_int hS'L).integrableOn.const_mul _),
        integral_const_mul, hF1 (k+1), setIntegral_const, smul_eq_mul]
      simp [Q, m]; ring
    have hG2 : ∫ ω in M (k+1), g ω ∂P = c * m (k+1) := by
      have : ∀ ω, g ω = (S (k+1) ω - a (k+1)) + c := fun ω => by simp only [g, c]; ring
      simp_rw [this]
      rw [integral_add (tsr_int hS'L).integrableOn (integrable_const _).integrableOn,
        hF1 (k+1), setIntegral_const, smul_eq_mul]
      simp [m]; ring
    have hsplit1 := setIntegral_sdiff (μ := P) (f := g) (hMm (k+1))
      (tsr_int hgL).integrableOn (hMsub k)
    have hsplit2 := setIntegral_sdiff (μ := P) (f := fun ω => g ω ^ 2) (hMm (k+1))
      hgL.integrable_sq.integrableOn (hMsub k)
    have hΔ : P.real (M k \ M (k+1)) = m k - m (k+1) := measureReal_sdiff (hMsub k) (hMm (k+1))
    have hgb : ∀ ω ∈ M k \ M (k+1), |g ω| ≤ B := by
      intro ω hω
      have h1 := abs_le.1 (hω.1 k le_rfl)
      have h2 := abs_le.1 (hb k ω)
      have h3 := abs_le.1 (hF2 k)
      have h4 := abs_le.1 hμ
      have : g ω = S k ω + Y k ω - a k - μk := by simp only [g, b, hSsucc]; ring
      rw [this, abs_le]; constructor <;> linarith
    have hJ1 : |∫ ω in M k \ M (k+1), g ω ∂P| ≤ B * (m k - m (k+1)) := by
      have := norm_setIntegral_le_of_norm_le_const (μ := P) (s := M k \ M (k+1)) (f := g) (C := B)
        (measure_lt_top _ _) (fun ω hω => by simpa [Real.norm_eq_abs] using hgb ω hω)
      rw [hΔ] at this; simpa [Real.norm_eq_abs] using this
    have hJ2 : ∫ ω in M k \ M (k+1), g ω ^ 2 ∂P ≤ B ^ 2 * (m k - m (k+1)) := by
      have := norm_setIntegral_le_of_norm_le_const (μ := P) (s := M k \ M (k+1))
        (f := fun ω => g ω ^ 2) (C := B ^ 2) (measure_lt_top _ _) (fun ω hω => by
          rw [Real.norm_eq_abs, abs_pow, ← abs_of_nonneg hB0]
          exact pow_le_pow_left₀ (abs_nonneg _) ((hgb ω hω).trans (le_abs_self B)) 2)
      rw [hΔ] at this
      exact (le_abs_self _).trans (by simpa [Real.norm_eq_abs] using this)
    have hcB : |c| ≤ B := by
      have h3 := abs_le.1 (hF2 k)
      have h3' := abs_le.1 (hF2 (k+1))
      have h4 := abs_le.1 hμ
      rw [abs_le]; constructor <;> simp only [c, b] <;> linarith
    have hcm : |c * m (k+1)| ≤ B * (m k - m (k+1)) := by
      have : c * m (k+1) = - ∫ ω in M k \ M (k+1), g ω ∂P := by
        rw [hsplit1, hE2, hG2]; ring
      rw [this, abs_neg]; exact hJ1
    have hc2 : c ^ 2 * m (k+1) ≤ B * (B * (m k - m (k+1))) := by
      have : c ^ 2 * m (k+1) = |c| * |c * m (k+1)| := by
        rw [abs_mul, abs_of_nonneg (hm0 (k+1)), ← mul_assoc, ← sq, sq_abs]
      rw [this]
      exact mul_le_mul hcB hcm (abs_nonneg _) hB0
    have hE : Q k + m k * Var[Y k; P] = Q (k+1) + c ^ 2 * m (k+1) +
        ∫ ω in M k \ M (k+1), g ω ^ 2 ∂P := by
      rw [← hE1, hsplit2, hG1]; ring
    rw [hE]
    nlinarith
  have hind_sum : ∀ N, Q 0 + ∑ j ∈ Finset.range N, m j * Var[Y j; P] ≤
      Q N + 2 * B ^ 2 * (m 0 - m N) := by
    intro N
    induction N with
    | zero => simp
    | succ N ih =>
      rw [Finset.sum_range_succ]
      have := hstep N
      nlinarith
  have hQ0 : 0 ≤ Q 0 := integral_nonneg fun ω => sq_nonneg _
  have hQn : Q n ≤ B ^ 2 * m n := by
    have := norm_setIntegral_le_of_norm_le_const (μ := P) (s := M n)
      (f := fun ω => (S n ω - a n) ^ 2) (C := B ^ 2) (measure_lt_top _ _) (fun ω hω => by
        rw [Real.norm_eq_abs, abs_pow, ← abs_of_nonneg hB0]
        refine pow_le_pow_left₀ (abs_nonneg _) ?_ 2
        rw [abs_of_nonneg hB0]
        have h1 := abs_le.1 (hω n le_rfl)
        have h3 := abs_le.1 (hF2 n)
        rw [abs_le]; constructor <;> linarith)
    exact (le_abs_self _).trans (by simpa [Real.norm_eq_abs] using this)
  have hmono : ∀ j ≤ n, m n ≤ m j := by
    intro j hj
    exact measureReal_mono (fun ω h i hi => h i (hi.trans hj))
  have hlow : m n * ∑ j ∈ Finset.range n, Var[Y j; P] ≤
      ∑ j ∈ Finset.range n, m j * Var[Y j; P] := by
    rw [Finset.mul_sum]
    exact Finset.sum_le_sum fun j hj => mul_le_mul_of_nonneg_right
      (hmono j (Finset.mem_range.1 hj).le) (variance_nonneg _ _)
  have hm1 : m 0 ≤ 1 := measureReal_le_one
  have hmn := hm0 n
  have hsum := hind_sum n
  show m n * _ ≤ _
  nlinarith

lemma tsr_conv_congr (x y : ℕ → ℝ) (h : ∀ᶠ n in atTop, x n = y n)
    (hx : ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, x n) atTop (𝓝 s)) :
    ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, y n) atTop (𝓝 s) := by
  obtain ⟨s, hs⟩ := hx
  obtain ⟨N0, hN0⟩ := eventually_atTop.1 h
  refine ⟨s + ∑ n ∈ Finset.range N0, (y n - x n), ?_⟩
  refine (hs.add_const _).congr' (eventually_atTop.2 ⟨N0, fun N hN => ?_⟩)
  show _ = ∑ n ∈ Finset.range N, y n
  rw [← Finset.sum_range_add_sum_Ico _ hN, ← Finset.sum_range_add_sum_Ico (fun n => y n) hN,
    Finset.sum_sub_distrib]
  have : ∑ n ∈ Finset.Ico N0 N, x n = ∑ n ∈ Finset.Ico N0 N, y n :=
    Finset.sum_congr rfl fun n hn => hN0 n (Finset.mem_Ico.1 hn).1
  rw [this]; ring

lemma tsr_term_tendsto (x : ℕ → ℝ) {s : ℝ}
    (h : Tendsto (fun N => ∑ n ∈ Finset.range N, x n) atTop (𝓝 s)) :
    Tendsto x atTop (𝓝 0) := by
  have := (h.comp (tendsto_add_atTop_nat 1)).sub h
  rw [sub_self] at this
  refine this.congr fun n => ?_
  simp [Finset.sum_range_succ]

lemma tsr_main {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n))
    (hind : iIndepFun X P) {A : ℝ} (hA : 0 < A) :
    ((∀ᵐ ω ∂P, ∃ s : ℝ,
        Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s)) ↔
      ((∑' n, P {ω | A < |X n ω|}) ≠ ∞ ∧
        (∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N,
          ∫ ω, Set.indicator {ω | |X n ω| ≤ A} (X n) ω ∂P) atTop (𝓝 m)) ∧
        Summable (fun n => Var[Set.indicator {ω | |X n ω| ≤ A} (X n); P]))) ∧
    (¬ ((∑' n, P {ω | A < |X n ω|}) ≠ ∞ ∧
        (∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N,
          ∫ ω, Set.indicator {ω | |X n ω| ≤ A} (X n) ω ∂P) atTop (𝓝 m)) ∧
        Summable (fun n => Var[Set.indicator {ω | |X n ω| ≤ A} (X n); P])) →
      ∀ᵐ ω ∂P, ¬ ∃ s : ℝ,
        Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s)) := by
  classical
  set Y : ℕ → Ω → ℝ := fun n => Set.indicator {ω | |X n ω| ≤ A} (X n) with hYdef
  have hYm : ∀ n, Measurable (Y n) := fun n =>
    (hX n).indicator (measurableSet_le (continuous_abs.measurable.comp (hX n)) measurable_const)
  have hYb : ∀ n ω, |Y n ω| ≤ A := by
    intro n ω
    by_cases h : |X n ω| ≤ A
    · simp only [Y]; rw [Set.indicator_of_mem (show ω ∈ {ω | |X n ω| ≤ A} from h)]; exact h
    · simp only [Y]; rw [Set.indicator_of_notMem (show ω ∉ {ω | |X n ω| ≤ A} from h)]
      simpa using hA.le
  have hYind : iIndepFun Y P := by
    have e : Y = fun n => (fun x : ℝ => if |x| ≤ A then x else 0) ∘ X n := by
      funext n ω; simp [Y, Set.indicator]
    rw [e]
    exact hind.comp _ fun _ => Measurable.ite
      (measurableSet_le continuous_abs.measurable measurable_const) measurable_id measurable_const
  have hYL : ∀ n, MemLp (Y n) 2 P := fun n =>
    memLp_of_bounded (a := -A) (b := A) (Eventually.of_forall fun ω => abs_le.1 (hYb n ω))
      (hYm n).aestronglyMeasurable 2
  set c : ℕ → ℝ := fun n => ∫ ω, Y n ω ∂P with hc
  -- the centred truncated series converges when the variances are summable
  have hZconv : Summable (fun n => Var[Y n; P]) →
      ∀ᵐ ω ∂P, ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, (Y n ω - c n)) atTop (𝓝 s) := by
    intro hsum
    have hZind : iIndepFun (fun n => (fun x => x - c n) ∘ Y n) P :=
      hYind.comp _ fun n => measurable_id.sub_const _
    have hZL : ∀ n, MemLp ((fun x => x - c n) ∘ Y n) 2 P := fun n => (hYL n).sub (memLp_const _)
    have h := tsr_conv (fun n => (fun x => x - c n) ∘ Y n)
      (fun n => (hYm n).sub_const _) hZind (fun n => by
        show ∫ ω, (Y n ω - c n) ∂P = 0
        rw [integral_sub (tsr_int (hYL n)) (integrable_const _), integral_const]
        simp [c]) (by
        have : ∀ n, eVar[(fun x => x - c n) ∘ Y n; P] = ENNReal.ofReal (Var[Y n; P]) := fun n => by
          rw [← (hZL n).ofReal_variance_eq]
          congr 1
          exact variance_sub_const (hYm n).aestronglyMeasurable (c n)
        simp_rw [this]
        rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => variance_nonneg _ _) hsum]
        exact ENNReal.ofReal_ne_top)
    simpa using h
  -- the first Borel–Cantelli lemma: eventually no cut
  have hBC1 : (∑' n, P {ω | A < |X n ω|}) ≠ ∞ → ∀ᵐ ω ∂P, ∀ᶠ n in atTop, X n ω = Y n ω := by
    intro h
    filter_upwards [ae_eventually_notMem h] with ω hω
    refine hω.mono fun n hn => ?_
    have : |X n ω| ≤ A := not_lt.1 hn
    simp only [Y]; rw [Set.indicator_of_mem (show ω ∈ {ω | |X n ω| ≤ A} from this)]
  -- sufficiency
  have hsuff : ((∑' n, P {ω | A < |X n ω|}) ≠ ∞ ∧
        (∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, c n) atTop (𝓝 m)) ∧
        Summable (fun n => Var[Y n; P])) →
      ∀ᵐ ω ∂P, ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s) := by
    rintro ⟨h1, ⟨m, hm⟩, h3⟩
    filter_upwards [hBC1 h1, hZconv h3] with ω hω hZ
    obtain ⟨s, hs⟩ := hZ
    refine tsr_conv_congr (fun n => Y n ω) (fun n => X n ω)
      (hω.mono fun n hn => hn.symm) ⟨s + m, ?_⟩
    refine (hs.add hm).congr fun N => ?_
    rw [← Finset.sum_add_distrib]; simp
  -- divergence
  have hdiv : ¬ ((∑' n, P {ω | A < |X n ω|}) ≠ ∞ ∧
        (∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, c n) atTop (𝓝 m)) ∧
        Summable (fun n => Var[Y n; P])) →
      ∀ᵐ ω ∂P, ¬ ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s) := by
    intro hC
    by_cases h1 : (∑' n, P {ω | A < |X n ω|}) ≠ ∞
    · by_cases h3 : Summable (fun n => Var[Y n; P])
      · have h2 : ¬ ∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, c n) atTop (𝓝 m) :=
          fun h2 => hC ⟨h1, h2, h3⟩
        filter_upwards [hBC1 h1, hZconv h3] with ω hω hZ hconv
        obtain ⟨s1, hs1⟩ := hZ
        obtain ⟨s2, hs2⟩ := tsr_conv_congr (fun n => X n ω) (fun n => Y n ω) hω hconv
        refine h2 ⟨s2 - s1, (hs2.sub hs1).congr fun N => ?_⟩
        rw [← Finset.sum_sub_distrib]; simp
      · -- the variances diverge: the truncated partial sums are unbounded
        have hVt : Tendsto (fun N => ∑ n ∈ Finset.range N, Var[Y n; P]) atTop atTop :=
          (not_summable_iff_tendsto_nat_atTop_of_nonneg fun n => variance_nonneg _ _).1 h3
        have hnull : ∀ L : ℕ, P {ω | ∀ k, |∑ i ∈ Finset.range k, Y i ω| ≤ L} = 0 := by
          intro L
          set p := P.real {ω | ∀ k, |∑ i ∈ Finset.range k, Y i ω| ≤ L} with hp
          have hbound : ∀ N, p * ∑ n ∈ Finset.range N, Var[Y n; P] ≤
              2 * (2 * A + 2 * (L : ℝ)) ^ 2 := by
            intro N
            refine le_trans ?_ (tsr_converse Y hYm hYind hA.le hYb (Nat.cast_nonneg L) N)
            refine mul_le_mul_of_nonneg_right ?_
              (Finset.sum_nonneg fun n _ => variance_nonneg _ _)
            exact measureReal_mono fun ω h j _ => h j
          have hp0 : p = 0 := by
            by_contra hne
            have hpos : 0 < p := lt_of_le_of_ne measureReal_nonneg (Ne.symm hne)
            obtain ⟨N, hN⟩ := (hVt.eventually_gt_atTop
              (2 * (2 * A + 2 * (L : ℝ)) ^ 2 / p)).exists
            have := hbound N
            rw [div_lt_iff₀ hpos] at hN
            linarith
          exact (measureReal_eq_zero_iff).1 hp0
        have hae : ∀ᵐ ω ∂P, ∀ L : ℕ, ω ∉ {ω | ∀ k, |∑ i ∈ Finset.range k, Y i ω| ≤ L} :=
          ae_all_iff.2 fun L => measure_eq_zero_iff_ae_notMem.1 (hnull L)
        filter_upwards [hBC1 h1, hae] with ω hω hL hconv
        obtain ⟨s2, hs2⟩ := tsr_conv_congr (fun n => X n ω) (fun n => Y n ω) hω hconv
        obtain ⟨K, hK⟩ := hs2.abs.bddAbove_range
        refine hL ⌈K⌉₊ fun k => ?_
        exact (hK ⟨k, rfl⟩).trans (Nat.le_ceil K)
    · -- the second Borel–Cantelli lemma: infinitely many cuts
      push Not at h1
      set s : ℕ → Set Ω := fun n => {ω | A < |X n ω|} with hs
      have hsm : ∀ n, MeasurableSet (s n) := fun n =>
        measurableSet_lt measurable_const (continuous_abs.measurable.comp (hX n))
      have hsind : iIndepSet s P := by
        rw [iIndepSet_iff_meas_biInter hsm]
        intro S
        exact hind.meas_biInter fun i _ =>
          ⟨{x | A < |x|}, measurableSet_lt measurable_const continuous_abs.measurable, rfl⟩
      have hlim := measure_limsup_eq_one hsm hsind h1
      have hae : ∀ᵐ ω ∂P, ω ∈ limsup s atTop :=
        (ae_mem_iff_measure_eq (MeasurableSet.measurableSet_limsup hsm).nullMeasurableSet).2
          (by rw [hlim, measure_univ])
      filter_upwards [hae] with ω hω hconv
      obtain ⟨s0, hs0⟩ := hconv
      have ht := tsr_term_tendsto (fun n => X n ω) hs0
      have hev : ∀ᶠ n in atTop, |X n ω| < A := by
        have := (ht.abs).eventually (gt_mem_nhds (show |(0:ℝ)| < A by simpa using hA))
        exact this
      rw [Filter.mem_limsup_iff_frequently_mem] at hω
      obtain ⟨n, hn1, hn2⟩ := (hω.and_eventually hev).exists
      exact absurd hn1 (not_lt.2 hn2.le)
  refine ⟨⟨fun hconv => ?_, hsuff⟩, hdiv⟩
  by_contra hC
  obtain ⟨ω, h1, h2⟩ := (hconv.and (hdiv hC)).exists
  exact h2 h1

#print axioms tsr_indep_split
#print axioms tsr_meas_past
#print axioms tsr_meas_fut
#print axioms tsr_past_le
#print axioms tsr_maximal
#print axioms tsr_conv
#print axioms tsr_int
#print axioms tsr_converse
#print axioms tsr_conv_congr
#print axioms tsr_term_tendsto
#print axioms tsr_main

/-- **Kolmogorov's three-series theorem.** Let `X 0, X 1, X 2, …` be independent random terms
(the card's `X₁, X₂, …`, shifted by one) and fix a cut-off level `A > 0`. Cut each term off:
`Yₙ = Xₙ` where `|Xₙ| ≤ A` and `Yₙ = 0` elsewhere. Then the partial sums `X 0 + ⋯ + X (n-1)`
have a finite limit for almost every outcome exactly when all three series converge:
(i) the chances `P(|Xₙ| > A)` have a finite sum, (ii) the means `E[Yₙ]` form a convergent
series, and (iii) the variances `Var(Yₙ)` have a finite sum. If any one of the three fails,
the partial sums have no finite limit for almost every outcome. -/
theorem three_series_theorem {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n))
    (hind : iIndepFun X P) {A : ℝ} (hA : 0 < A) :
    ((∀ᵐ ω ∂P, ∃ s : ℝ,
        Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s)) ↔
      ((∑' n, P {ω | A < |X n ω|}) ≠ ∞ ∧
        (∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N,
          ∫ ω, Set.indicator {ω | |X n ω| ≤ A} (X n) ω ∂P) atTop (𝓝 m)) ∧
        Summable (fun n => Var[Set.indicator {ω | |X n ω| ≤ A} (X n); P]))) ∧
    (¬ ((∑' n, P {ω | A < |X n ω|}) ≠ ∞ ∧
        (∃ m : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N,
          ∫ ω, Set.indicator {ω | |X n ω| ≤ A} (X n) ω ∂P) atTop (𝓝 m)) ∧
        Summable (fun n => Var[Set.indicator {ω | |X n ω| ≤ A} (X n); P])) →
      ∀ᵐ ω ∂P, ¬ ∃ s : ℝ,
        Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s)) := by
  exact tsr_main X hX hind hA

/-- **Kolmogorov's maximal inequality.** Let the terms `X 0, X 1, …` be independent with mean 0
and finite variances. For every level `t > 0` (the card's `λ`) and every `n`, the chance that the running total
`Sₖ = X 0 + ⋯ + X (k-1)` reaches size `t` at some time `k ≤ n` is at most
`(Var(X 0) + ⋯ + Var(X (n-1))) / t²`, which is `Var(Sₙ) / t²`. -/
theorem kolmogorov_maximal_inequality {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n))
    (hind : iIndepFun X P) (hL2 : ∀ n, MemLp (X n) 2 P) (hmean : ∀ n, ∫ ω, X n ω ∂P = 0)
    {t : ℝ} (ht : 0 < t) (n : ℕ) :
    P {ω | ∃ k ≤ n, t ≤ |∑ i ∈ Finset.range k, X i ω|} ≤
      ENNReal.ofReal ((∑ i ∈ Finset.range n, Var[X i; P]) / t ^ 2) := by
  exact tsr_maximal X hX hind hL2 hmean ht n

/-- **Summable variances make the series converge.** If the terms `X 0, X 1, …` are independent
with mean 0 and their variances have a finite sum, then the partial sums `X 0 + ⋯ + X (n-1)`
have a finite limit for almost every outcome. -/
theorem summable_variances_converge_ae {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n))
    (hind : iIndepFun X P) (hmean : ∀ n, ∫ ω, X n ω ∂P = 0)
    (hvar : (∑' n, eVar[X n; P]) ≠ ∞) :
    ∀ᵐ ω ∂P, ∃ s : ℝ, Tendsto (fun N => ∑ n ∈ Finset.range N, X n ω) atTop (𝓝 s) := by
  exact tsr_conv X hX hind hmean hvar

-- The card's exact arithmetic.
-- Series A, a fair sign times 1/n: variance (1/n)² · 1/2 + (-1/n)² · 1/2 = 1/n².
example (n : ℚ) : (1 / n) ^ 2 * (1 / 2) + (-1 / n) ^ 2 * (1 / 2) = 1 / n ^ 2 := by
  ring
-- Series C, n² with chance 1/n²: mean 1 and variance n² - 1.
example (n : ℚ) (hn : n ≠ 0) :
    n ^ 2 * (1 / n ^ 2) = 1 ∧ (n ^ 2) ^ 2 * (1 / n ^ 2) - 1 ^ 2 = n ^ 2 - 1 := by
  constructor <;> field_simp
-- Series C, no jump from term 2 to term N: the product of 1 - 1/k² telescopes to (N+1)/(2N);
-- at N = 10 that is 11/20.
example : ∏ k ∈ Finset.Icc (2 : ℕ) 10, (1 - 1 / (k : ℚ) ^ 2) = 11 / 20 := by
  norm_num [Finset.prod_Icc_succ_top]
-- Series D, +1/n with chance 3/4: mean 1/(2n) and variance 3/(4n²).
example (n : ℚ) (hn : n ≠ 0) :
    (1 / n) * (3 / 4) + (-1 / n) * (1 / 4) = 1 / (2 * n) ∧
      (1 / n) ^ 2 - (1 / (2 * n)) ^ 2 = 3 / (4 * n ^ 2) := by
  constructor <;> field_simp <;> ring
-- The exact count uses L = lcm(1, …, 16) = 720720, so every partial sum of ±1/k is an integer over L.
example : (Finset.Icc 1 16).lcm id = 720720 := by
  decide
-- Bounds: δ = 1/20 gives δ² = 1/400; λ = 3/2, c = 1 gives (λ + c)² = 25/4; λ = 2 gives λ² = 4.
example : ((1 : ℚ) / 20) ^ 2 = 1 / 400 ∧ ((3 : ℚ) / 2 + 1) ^ 2 = 25 / 4 ∧ (2 : ℚ) ^ 2 = 4 := by
  norm_num
-- Kolmogorov's strong law: a fair die's face has mean 7/2 and variance 35/12.
example : (∑ k ∈ Finset.Icc (1 : ℕ) 6, (k : ℚ)) / 6 = 7 / 2 ∧
    (∑ k ∈ Finset.Icc (1 : ℕ) 6, ((k : ℚ) - 7 / 2) ^ 2) / 6 = 35 / 12 := by
  norm_num [Finset.sum_Icc_succ_top]

#print axioms three_series_theorem
#print axioms kolmogorov_maximal_inequality
#print axioms summable_variances_converge_ae
