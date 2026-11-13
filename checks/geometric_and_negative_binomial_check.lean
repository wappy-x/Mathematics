-- Waiting for a success: with independent tries that each succeed with the same chance p > 0, the wait for the first success ends for sure, lands on try k with chance (1 - p)^(k-1) p, averages 1/p tries with variance (1 - p)/p², forgets its past, and the wait for the r-th success lands on try k with chance C(k-1, r-1) p^r (1 - p)^(k-r), averaging r/p with variance r(1 - p)/p².
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.Moments.Variance
import Mathlib.Basic.Real.ENatENNReal
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.MeasureTheory.Integral.Lebesgue.Countable
import Mathlib.MeasureTheory.Function.L2Space

open MeasureTheory ProbabilityTheory
open scoped ENNReal

open Classical in
/-- The try on which the `r`-th success lands, counting tries from 1. Try `i + 1` is a success
exactly when the outcome `ω` lies in the event `A i`. The wait is the least `k` such that the
first `k` tries hold at least `r` successes, and `⊤` (it never ends) if there is no such `k`.
For `r = 1` this is the wait for the first success. -/
noncomputable def waitFor {Ω : Type*} (r : ℕ) (A : ℕ → Set Ω) (ω : Ω) : ℕ∞ :=
  ⨅ (k : ℕ) (_ : r ≤ ((Finset.range k).filter (fun i => ω ∈ A i)).card), (k : ℕ∞)

open Classical in
lemma gnb_waitFor_le_iff {Ω : Type*} (r : ℕ) (A : ℕ → Set Ω) (ω : Ω) (n : ℕ) :
    waitFor r A ω ≤ n ↔ r ≤ ((Finset.range n).filter (fun i => ω ∈ A i)).card := by
  constructor
  · intro h
    have h' : waitFor r A ω < ((n + 1 : ℕ) : ℕ∞) :=
      lt_of_le_of_lt h (by exact_mod_cast Nat.lt_succ_self n)
    unfold waitFor at h'
    rw [iInf_lt_iff] at h'
    obtain ⟨j, hj⟩ := h'
    rw [iInf_lt_iff] at hj
    obtain ⟨hrj, hjn⟩ := hj
    have hjn' : j ≤ n := by
      have : j < n + 1 := by exact_mod_cast hjn
      omega
    exact hrj.trans (Finset.card_le_card
      (Finset.filter_subset_filter _ (Finset.range_subset_range.2 hjn')))
  · intro h
    unfold waitFor
    exact iInf₂_le n h

open Classical in
lemma gnb_measurable_card {Ω : Type*} [MeasurableSpace Ω] (A : ℕ → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) (n : ℕ) :
    Measurable (fun ω => ((Finset.range n).filter (fun i => ω ∈ A i)).card) := by
  simp_rw [Finset.card_filter]
  exact Finset.measurable_sum _ (fun i _ => Measurable.ite (hA i) measurable_const measurable_const)

lemma gnb_enat_eq_succ_iff (x : ℕ∞) (k : ℕ) :
    x = ((k + 1 : ℕ) : ℕ∞) ↔ x ≤ ((k + 1 : ℕ) : ℕ∞) ∧ ¬ x ≤ (k : ℕ∞) := by
  induction x using ENat.recTopCoe with
  | top =>
    exact ⟨fun h => absurd h.symm (ENat.natCast_ne_top _),
      fun h => absurd (top_le_iff.1 h.1) (ENat.natCast_ne_top _)⟩
  | coe n => norm_cast; omega

lemma gnb_enat_eq_top_iff (x : ℕ∞) : x = ⊤ ↔ ∀ n : ℕ, ¬ x ≤ (n : ℕ∞) := by
  induction x using ENat.recTopCoe with
  | top => simp
  | coe n => simp only [ENat.natCast_ne_top, false_iff, not_forall, not_not]; exact ⟨n, le_rfl⟩

open Classical in
lemma gnb_measurable_waitFor {Ω : Type*} [MeasurableSpace Ω] (r : ℕ) (A : ℕ → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) : Measurable (waitFor r A) := by
  have hle : ∀ n : ℕ, MeasurableSet {ω | waitFor r A ω ≤ (n : ℕ∞)} := by
    intro n
    simp_rw [gnb_waitFor_le_iff]
    exact gnb_measurable_card A hA n (MeasurableSet.of_discrete (s := {k | r ≤ k}))
  refine measurable_to_countable' (fun x => ?_)
  induction x using ENat.recTopCoe with
  | top =>
    have : waitFor r A ⁻¹' {⊤} = ⋂ n : ℕ, {ω | waitFor r A ω ≤ (n : ℕ∞)}ᶜ := by
      ext ω; simp [gnb_enat_eq_top_iff (waitFor r A ω)]
    rw [this]; exact MeasurableSet.iInter fun n => (hle n).compl
  | coe n =>
    cases n with
    | zero =>
      have : waitFor r A ⁻¹' {((0 : ℕ) : ℕ∞)} = {ω | waitFor r A ω ≤ ((0 : ℕ) : ℕ∞)} := by
        ext ω; simp
      rw [this]; exact hle 0
    | succ k =>
      have : waitFor r A ⁻¹' {((k + 1 : ℕ) : ℕ∞)} =
          {ω | waitFor r A ω ≤ ((k + 1 : ℕ) : ℕ∞)} ∩ {ω | waitFor r A ω ≤ (k : ℕ∞)}ᶜ := by
        ext ω; simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_inter_iff,
          Set.mem_ofPred_eq, Set.mem_compl_iff]
        exact gnb_enat_eq_succ_iff _ k
      rw [this]; exact (hle (k + 1)).inter (hle k).compl

open Classical in
lemma gnb_pattern_set_eq {Ω : Type*} (A : ℕ → Set Ω) (n : ℕ) (T : Finset ℕ)
    (hT : T ⊆ Finset.range n) :
    {ω | (Finset.range n).filter (fun i => ω ∈ A i) = T} =
      ⋂ i ∈ Finset.range n, (if i ∈ T then A i else (A i)ᶜ) := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_iInter]
  constructor
  · rintro rfl i hi
    by_cases h : ω ∈ A i
    · have : i ∈ (Finset.range n).filter (fun i => ω ∈ A i) := Finset.mem_filter.2 ⟨hi, h⟩
      simp only [this, ite_true]; exact h
    · have : i ∉ (Finset.range n).filter (fun i => ω ∈ A i) := fun h' =>
        h (Finset.mem_filter.1 h').2
      simp only [this, ite_false]; exact h
  · intro h
    ext i
    simp only [Finset.mem_filter]
    constructor
    · rintro ⟨hi, hiA⟩
      by_contra hiT
      have := h i hi
      simp only [hiT, ite_false] at this
      exact this hiA
    · intro hiT
      have hi := hT hiT
      have := h i hi
      simp only [hiT, ite_true] at this
      exact ⟨hi, this⟩

open Classical in
lemma gnb_pattern_meas {Ω : Type*} [MeasurableSpace Ω] (A : ℕ → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) (n : ℕ) (T : Finset ℕ) (hT : T ⊆ Finset.range n) :
    MeasurableSet {ω | (Finset.range n).filter (fun i => ω ∈ A i) = T} := by
  rw [gnb_pattern_set_eq A n T hT]
  refine Finset.measurableSet_biInter _ (fun i _ => ?_)
  split_ifs
  · exact hA i
  · exact (hA i).compl

open Classical in
lemma gnb_pattern_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (n : ℕ) (T : Finset ℕ) (hT : T ⊆ Finset.range n) :
    P.real {ω | (Finset.range n).filter (fun i => ω ∈ A i) = T} =
      p ^ T.card * (1 - p) ^ (n - T.card) := by
  have hind' := (iIndepSet_iff_iIndep A P).1 hind
  rw [gnb_pattern_set_eq A n T hT, measureReal_def, hind'.meas_biInter (fun i _ => ?_),
    ENNReal.toReal_prod]
  · rw [← Finset.prod_sdiff hT]
    have h1 : ∀ i ∈ Finset.range n \ T,
        (P (if i ∈ T then A i else (A i)ᶜ)).toReal = 1 - p := by
      intro i hi
      rw [Finset.mem_sdiff] at hi
      simp only [hi.2, ite_false]
      rw [← measureReal_def, probReal_compl_eq_one_sub (hA i), hp i]
    have h2 : ∀ i ∈ T, (P (if i ∈ T then A i else (A i)ᶜ)).toReal = p := by
      intro i hi
      simp only [hi, ite_true]
      rw [← measureReal_def, hp i]
    rw [Finset.prod_congr rfl h1, Finset.prod_congr rfl h2, Finset.prod_const, Finset.prod_const,
      Finset.card_sdiff_of_subset hT, Finset.card_range, mul_comm]
  · split_ifs
    · exact MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)
    · exact (MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)).compl

open Classical in
lemma gnb_filter_succ {Ω : Type*} (A : ℕ → Set Ω) (ω : Ω) (k : ℕ) :
    (Finset.range (k + 1)).filter (fun i => ω ∈ A i) =
      if ω ∈ A k then insert k ((Finset.range k).filter (fun i => ω ∈ A i))
      else (Finset.range k).filter (fun i => ω ∈ A i) := by
  rw [Finset.range_add_one, Finset.filter_insert]

open Classical in
lemma gnb_waitFor_eq_set {Ω : Type*} (A : ℕ → Set Ω) (s m : ℕ) :
    {ω | waitFor (s + 1) A ω = ((m + s + 1 : ℕ) : ℕ∞)} =
      ⋃ T ∈ (Finset.range (m + s)).powersetCard s,
        {ω | (Finset.range (m + s + 1)).filter (fun i => ω ∈ A i) = insert (m + s) T} := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_powersetCard, exists_prop]
  rw [gnb_enat_eq_succ_iff, gnb_waitFor_le_iff, gnb_waitFor_le_iff, gnb_filter_succ]
  have hnot : m + s ∉ (Finset.range (m + s)).filter (fun i => ω ∈ A i) := by
    simp
  constructor
  · rintro ⟨h1, h2⟩
    by_cases hk : ω ∈ A (m + s)
    · simp only [hk, ite_true] at h1 ⊢
      rw [Finset.card_insert_of_notMem hnot] at h1
      refine ⟨_, ⟨Finset.filter_subset _ _, by omega⟩, rfl⟩
    · simp only [hk, ite_false] at h1
      omega
  · rintro ⟨T, ⟨hTsub, hTcard⟩, hT⟩
    by_cases hk : ω ∈ A (m + s)
    · simp only [hk, ite_true] at hT
      have hTk : m + s ∉ T := fun h => by simpa using hTsub h
      have := congrArg (fun S => S.erase (m + s)) hT
      simp only [Finset.erase_insert hnot, Finset.erase_insert hTk] at this
      simp only [hk, ite_true]
      rw [Finset.card_insert_of_notMem hnot, this, hTcard]
      omega
    · simp only [hk, ite_false] at hT
      exfalso
      have : m + s ∈ (Finset.range (m + s)).filter (fun i => ω ∈ A i) := by
        rw [hT]; exact Finset.mem_insert_self _ _
      exact hnot this

open Classical in
lemma gnb_prob_eq {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (s m : ℕ) :
    P.real {ω | waitFor (s + 1) A ω = ((m + s + 1 : ℕ) : ℕ∞)} =
      ((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m := by
  rw [gnb_waitFor_eq_set, measureReal_biUnion_finset]
  · have hsub : ∀ T ∈ (Finset.range (m + s)).powersetCard s,
        insert (m + s) T ⊆ Finset.range (m + s + 1) ∧ (insert (m + s) T).card = s + 1 := by
      intro T hT
      rw [Finset.mem_powersetCard] at hT
      have hTk : m + s ∉ T := fun h => by simpa using hT.1 h
      refine ⟨?_, by rw [Finset.card_insert_of_notMem hTk, hT.2]⟩
      rw [Finset.range_add_one]
      exact Finset.insert_subset_insert _ hT.1
    rw [Finset.sum_congr rfl (fun T hT => by
      rw [gnb_pattern_prob P A p hA hind hp _ _ (hsub T hT).1, (hsub T hT).2])]
    rw [Finset.sum_const, Finset.card_powersetCard, Finset.card_range, nsmul_eq_mul,
      show m + s + 1 - (s + 1) = m by omega]
    ring
  · intro T₁ hT₁ T₂ hT₂ hne
    rw [Function.onFun, Set.disjoint_left]
    intro ω h1 h2
    simp only [Set.mem_ofPred_eq] at h1 h2
    rw [h1] at h2
    have hT₁' := (Finset.mem_powersetCard.1 hT₁).1
    have hT₂' := (Finset.mem_powersetCard.1 hT₂).1
    have hk1 : m + s ∉ T₁ := fun h => by simpa using hT₁' h
    have hk2 : m + s ∉ T₂ := fun h => by simpa using hT₂' h
    have := congrArg (fun S => S.erase (m + s)) h2
    simp only [Finset.erase_insert hk1, Finset.erase_insert hk2] at this
    exact hne this
  · intro T hT
    have hT' := (Finset.mem_powersetCard.1 hT).1
    apply gnb_pattern_meas A hA
    rw [Finset.range_add_one]
    exact Finset.insert_subset_insert _ hT'

open Classical in
lemma gnb_waitFor_lt_empty {Ω : Type*} (A : ℕ → Set Ω) (s n : ℕ) (hn : n < s + 1) :
    {ω | waitFor (s + 1) A ω = (n : ℕ∞)} = ∅ := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
  intro h
  have h' := (gnb_waitFor_le_iff (s + 1) A ω n).1 h.le
  have : ((Finset.range n).filter (fun i => ω ∈ A i)).card ≤ n :=
    (Finset.card_filter_le _ _).trans (Finset.card_range n).le
  omega

open Classical in
lemma gnb_tail_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (n : ℕ) :
    P.real {ω | (n : ℕ∞) < waitFor 1 A ω} = (1 - p) ^ n := by
  have : {ω | (n : ℕ∞) < waitFor 1 A ω} =
      {ω | (Finset.range n).filter (fun i => ω ∈ A i) = ∅} := by
    ext ω
    simp only [Set.mem_ofPred_eq, ← not_le, gnb_waitFor_le_iff, Nat.one_le_iff_ne_zero, ne_eq,
      not_not, Finset.card_eq_zero]
  rw [this, gnb_pattern_prob P A p hA hind hp n ∅ (Finset.empty_subset _)]
  simp

lemma gnb_choose_one (m s : ℕ) :
    ((m + (s + 1) : ℕ) : ℝ) * ((m + s).choose s : ℝ) =
      ((s : ℝ) + 1) * ((m + (s + 1)).choose (s + 1) : ℝ) := by
  have h := Nat.add_one_mul_choose_eq (m + s) s
  have h' : (m + (s + 1)) * (m + s).choose s = (s + 1) * (m + (s + 1)).choose (s + 1) := by
    rw [show m + (s + 1) = m + s + 1 by omega, h, mul_comm]
  exact_mod_cast h'

lemma gnb_choose_two (m s : ℕ) :
    ((m + (s + 2) : ℕ) : ℝ) * ((m + (s + 1)).choose (s + 1) : ℝ) =
      ((s : ℝ) + 2) * ((m + (s + 2)).choose (s + 2) : ℝ) := by
  have h := Nat.add_one_mul_choose_eq (m + s + 1) (s + 1)
  have h' : (m + (s + 2)) * (m + (s + 1)).choose (s + 1) =
      (s + 2) * (m + (s + 2)).choose (s + 2) := by
    rw [show m + (s + 2) = m + s + 1 + 1 by omega, show m + (s + 1) = m + s + 1 by omega, h,
      mul_comm]
  exact_mod_cast h'

open Classical in
lemma gnb_main {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (A : ℕ → Set Ω) (p : ℝ) (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) (s : ℕ) :
    P {ω | waitFor (s + 1) A ω = ⊤} = 0 ∧
    ∫⁻ ω, (waitFor (s + 1) A ω : ℝ≥0∞) ∂P = ENNReal.ofReal ((s + 1) / p) ∧
    variance (fun ω => ((waitFor (s + 1) A ω).toNat : ℝ)) P = (s + 1) * (1 - p) / p ^ 2 := by
  have hWm : Measurable (waitFor (s + 1) A) := gnb_measurable_waitFor _ A hA
  have hp1 : p ≤ 1 := by rw [← hp 0]; exact measureReal_le_one
  have hq0 : 0 ≤ 1 - p := by linarith
  have hq1 : ‖1 - p‖ < 1 := by rw [Real.norm_eq_abs, abs_of_nonneg hq0]; linarith
  have hp' : 1 - (1 - p) = p := by ring
  set F : ℕ → ℝ := fun n => P.real {ω | waitFor (s + 1) A ω = n} with hF
  have hF0 : ∀ n, 0 ≤ F n := fun n => measureReal_nonneg
  have hFlt : ∀ n ∈ Finset.range (s + 1), F n = 0 := by
    intro n hn
    simp only [hF]
    rw [gnb_waitFor_lt_empty A s n (Finset.mem_range.1 hn)]
    simp
  have hFm : ∀ m, F (m + (s + 1)) = ((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m := by
    intro m
    simp only [hF]
    rw [show m + (s + 1) = m + s + 1 by omega]
    exact gnb_prob_eq P A p hA hind hp s m
  have shift : ∀ (w : ℕ → ℝ) (S : ℝ),
      HasSum (fun m => w (m + (s + 1)) * F (m + (s + 1))) S → HasSum (fun n => w n * F n) S := by
    intro w S h
    rw [← hasSum_nat_add_iff' (s + 1)]
    rw [Finset.sum_eq_zero (fun n hn => by rw [hFlt n hn, mul_zero]), sub_zero]
    exact h
  have hS0 : HasSum (fun n => (1 : ℝ) * F n) 1 := by
    apply shift
    have := (hasSum_choose_mul_geometric_of_norm_lt_one s hq1).mul_left (p ^ (s + 1))
    rw [hp'] at this
    convert this using 1
    · funext m; rw [hFm]; ring
    · field_simp
  have hS1 : HasSum (fun n : ℕ => (n : ℝ) * F n) ((s + 1) / p) := by
    apply shift
    have := (hasSum_choose_mul_geometric_of_norm_lt_one (s + 1) hq1).mul_left
      (((s : ℝ) + 1) * p ^ (s + 1))
    rw [hp'] at this
    convert this using 1
    · funext m
      rw [hFm]
      have := gnb_choose_one m s
      calc ((m + (s + 1) : ℕ) : ℝ) * (((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m)
          = (((m + (s + 1) : ℕ) : ℝ) * ((m + s).choose s : ℝ)) * p ^ (s + 1) * (1 - p) ^ m := by
            ring
        _ = _ := by rw [this]; ring
    · field_simp
      ring
  have hS2 : HasSum (fun n : ℕ => ((n : ℝ) * ((n : ℝ) + 1)) * F n) ((s + 1) * (s + 2) / p ^ 2) := by
    apply shift
    have := (hasSum_choose_mul_geometric_of_norm_lt_one (s + 2) hq1).mul_left
      (((s : ℝ) + 1) * ((s : ℝ) + 2) * p ^ (s + 1))
    rw [hp'] at this
    convert this using 1
    · funext m
      rw [hFm]
      have h1 := gnb_choose_one m s
      have h2 := gnb_choose_two m s
      have e : ((m + (s + 1) : ℕ) : ℝ) + 1 = ((m + (s + 2) : ℕ) : ℝ) := by push_cast; ring
      rw [e]
      calc ((m + (s + 1) : ℕ) : ℝ) * ((m + (s + 2) : ℕ) : ℝ) *
            (((m + s).choose s : ℝ) * p ^ (s + 1) * (1 - p) ^ m)
          = ((m + (s + 2) : ℕ) : ℝ) * (((m + (s + 1) : ℕ) : ℝ) * ((m + s).choose s : ℝ)) *
              p ^ (s + 1) * (1 - p) ^ m := by ring
        _ = ((s : ℝ) + 1) * (((m + (s + 2) : ℕ) : ℝ) * ((m + (s + 1)).choose (s + 1) : ℝ)) *
              p ^ (s + 1) * (1 - p) ^ m := by rw [h1]; ring
        _ = _ := by rw [h2]; ring
    · field_simp
      ring
  have hS2' : HasSum (fun n : ℕ => (n : ℝ) ^ 2 * F n) ((s + 1) * (s + 2) / p ^ 2 - (s + 1) / p) := by
    convert hS2.sub hS1 using 1
    funext n; ring
  have hPW : ∀ n : ℕ, P {ω | waitFor (s + 1) A ω = n} = ENNReal.ofReal (F n) :=
    fun n => (ofReal_measureReal).symm
  have hmeas : ∀ n : ℕ, MeasurableSet {ω | waitFor (s + 1) A ω = n} :=
    fun n => hWm (measurableSet_singleton _)
  have htop : P {ω | waitFor (s + 1) A ω = ⊤} = 0 := by
    have hU : {ω | waitFor (s + 1) A ω ≠ ⊤} = ⋃ n : ℕ, {ω | waitFor (s + 1) A ω = n} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_iUnion, ENat.ne_top_iff_exists]
      exact ⟨fun ⟨m, hm⟩ => ⟨m, hm.symm⟩, fun ⟨m, hm⟩ => ⟨m, hm.symm⟩⟩
    have h1 : P {ω | waitFor (s + 1) A ω ≠ ⊤} = 1 := by
      rw [hU, measure_iUnion (fun i j hij => ?_) hmeas]
      · simp_rw [hPW]
        rw [← ENNReal.ofReal_tsum_of_nonneg hF0 (by simpa using hS0.summable)]
        have : ∑' n, F n = 1 := by simpa using hS0.tsum_eq
        rw [this, ENNReal.ofReal_one]
      · rw [Function.onFun, Set.disjoint_left]
        intro ω h1 h2
        simp only [Set.mem_ofPred_eq] at h1 h2
        rw [h1] at h2
        exact hij (by exact_mod_cast h2)
    have hc : {ω | waitFor (s + 1) A ω = ⊤} = {ω | waitFor (s + 1) A ω ≠ ⊤}ᶜ := by
      ext ω; simp
    have hmc : MeasurableSet {ω | waitFor (s + 1) A ω ≠ ⊤} :=
      (hWm (measurableSet_singleton ⊤)).compl
    rw [hc, prob_compl_eq_one_sub hmc, h1, tsub_self]
  set N : Ω → ℕ := fun ω => (waitFor (s + 1) A ω).toNat with hN
  have hNm : Measurable N := (Measurable.of_discrete (f := ENat.toNat)).comp hWm
  have hae : ∀ᵐ ω ∂P, waitFor (s + 1) A ω = (N ω : ℕ∞) := by
    have : ∀ᵐ ω ∂P, waitFor (s + 1) A ω ≠ ⊤ := by
      rw [ae_iff]; simpa using htop
    filter_upwards [this] with ω hω
    exact (ENat.natCast_toNat hω).symm
  have hPN : ∀ n : ℕ, P (N ⁻¹' {n}) = P {ω | waitFor (s + 1) A ω = n} := by
    intro n
    apply measure_congr
    filter_upwards [hae] with ω hω
    show (ω ∈ N ⁻¹' {n}) = (ω ∈ {ω | waitFor (s + 1) A ω = n})
    simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_ofPred_eq, hω, Nat.cast_inj]
  have hlin : ∀ g : ℕ → ℝ≥0∞, ∫⁻ ω, g (N ω) ∂P = ∑' n, g n * ENNReal.ofReal (F n) := by
    intro g
    rw [← lintegral_map Measurable.of_discrete hNm, lintegral_countable']
    congr 1
    funext n
    rw [Measure.map_apply hNm (measurableSet_singleton _), hPN, hPW]
  have key : ∀ w : ℕ → ℝ, (∀ n, 0 ≤ w n) → ∀ S, HasSum (fun n => w n * F n) S →
      ∫⁻ ω, ENNReal.ofReal (w (N ω)) ∂P = ENNReal.ofReal S := by
    intro w hw S h
    rw [hlin (fun n => ENNReal.ofReal (w n))]
    simp_rw [← ENNReal.ofReal_mul (hw _)]
    rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => mul_nonneg (hw n) (hF0 n)) h.summable,
      h.tsum_eq]
  have hE1 := key (fun n => (n : ℝ)) (fun n => Nat.cast_nonneg n) _ hS1
  have hE2 := key (fun n => (n : ℝ) ^ 2) (fun n => by positivity) _ hS2'
  refine ⟨htop, ?_, ?_⟩
  · rw [← hE1]
    apply lintegral_congr_ae
    filter_upwards [hae] with ω hω
    rw [hω, ENat.toENNReal_coe, ENNReal.ofReal_natCast]
  · set X : Ω → ℝ := fun ω => (N ω : ℝ) with hX
    have hXm : Measurable X := (Measurable.of_discrete (f := fun n : ℕ => (n : ℝ))).comp hNm
    have hX0 : 0 ≤ᵐ[P] X := ae_of_all _ (fun ω => Nat.cast_nonneg _)
    have hX20 : 0 ≤ᵐ[P] (X ^ 2) := ae_of_all _ (fun ω => by
      simp only [Pi.zero_apply, Pi.pow_apply]; positivity)
    have hint2 : Integrable (X ^ 2) P :=
      (lintegral_ofReal_ne_top_iff_integrable (hXm.pow_const 2).aestronglyMeasurable hX20).1
        (by
          have : ∫⁻ ω, ENNReal.ofReal (X ω ^ 2) ∂P = ENNReal.ofReal
              ((s + 1) * (s + 2) / p ^ 2 - (s + 1) / p) := hE2
          rw [this]; exact ENNReal.ofReal_ne_top)
    have hmemLp : MemLp X 2 P := (memLp_two_iff_integrable_sq hXm.aestronglyMeasurable).2 hint2
    have hI1 : ∫ ω, X ω ∂P = (s + 1) / p := by
      rw [integral_eq_lintegral_of_nonneg_ae hX0 hXm.aestronglyMeasurable]
      rw [show ∫⁻ ω, ENNReal.ofReal (X ω) ∂P = ENNReal.ofReal ((s + 1) / p) from hE1]
      rw [ENNReal.toReal_ofReal (by positivity)]
    have hI2 : ∫ ω, (X ^ 2) ω ∂P = (s + 1) * (s + 2) / p ^ 2 - (s + 1) / p := by
      rw [integral_eq_lintegral_of_nonneg_ae hX20 (hXm.pow_const 2).aestronglyMeasurable]
      rw [show ∫⁻ ω, ENNReal.ofReal ((X ^ 2) ω) ∂P = ENNReal.ofReal
          ((s + 1) * (s + 2) / p ^ 2 - (s + 1) / p) from hE2]
      rw [ENNReal.toReal_ofReal (hS2'.nonneg (fun n => mul_nonneg (by positivity) (hF0 n)))]
    show variance X P = _
    rw [variance_eq_sub hmemLp, hI2, hI1]
    field_simp
    ring

#print axioms gnb_waitFor_le_iff
#print axioms gnb_measurable_card
#print axioms gnb_enat_eq_succ_iff
#print axioms gnb_enat_eq_top_iff
#print axioms gnb_measurable_waitFor
#print axioms gnb_pattern_set_eq
#print axioms gnb_pattern_meas
#print axioms gnb_pattern_prob
#print axioms gnb_filter_succ
#print axioms gnb_waitFor_eq_set
#print axioms gnb_prob_eq
#print axioms gnb_waitFor_lt_empty
#print axioms gnb_tail_prob
#print axioms gnb_choose_one
#print axioms gnb_choose_two
#print axioms gnb_main

/-- The geometric law. Make independent tries, each a success with the same chance `p`, where
`p > 0`, and count the tries up to and including the first success. Then the wait ends with
probability 1; the first success lands on try `k` (for `k = 1, 2, 3, …`) with chance
`(1 - p)^(k-1) p`; the chance of no success in the first `k` tries is `(1 - p)^k`; the average
wait is `1/p` tries; and its variance is `(1 - p)/p²`. -/
theorem first_success_wait_is_geometric {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (A : ℕ → Set Ω) (p : ℝ)
    (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) :
    P {ω | waitFor 1 A ω = ⊤} = 0 ∧
    (∀ k : ℕ, 1 ≤ k → P.real {ω | waitFor 1 A ω = k} = (1 - p) ^ (k - 1) * p) ∧
    (∀ k : ℕ, P.real {ω | (k : ℕ∞) < waitFor 1 A ω} = (1 - p) ^ k) ∧
    ∫⁻ ω, (waitFor 1 A ω : ℝ≥0∞) ∂P = ENNReal.ofReal (1 / p) ∧
    variance (fun ω => ((waitFor 1 A ω).toNat : ℝ)) P = (1 - p) / p ^ 2 := by
  obtain ⟨h1, h2, h3⟩ := gnb_main P A p hA hind hp hp0 0
  simp only [zero_add, Nat.cast_zero] at h1 h2 h3
  refine ⟨h1, ?_, gnb_tail_prob P A p hA hind hp, h2, ?_⟩
  · intro k hk
    have h := gnb_prob_eq P A p hA hind hp 0 (k - 1)
    simp only [zero_add, add_zero, Nat.choose_zero_right, Nat.cast_one, one_mul, pow_one] at h
    rw [show k - 1 + 1 = k by omega] at h
    rw [h, mul_comm]
  · rw [h3]; ring

/-- Memorylessness. With the same independent tries, each a success with chance `p`, where now
`0 < p < 1`: for any whole numbers `s, t ≥ 0`, given that the first `s` tries all missed, the
chance that the next `t` tries also all miss is the same as the chance that the first `t` tries
miss from a standing start: `P(X > s + t | X > s) = P(X > t)`. -/
theorem first_success_wait_memoryless {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (A : ℕ → Set Ω) (p : ℝ)
    (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) (hp1 : p < 1) (s t : ℕ) :
    P[{ω | ((s + t : ℕ) : ℕ∞) < waitFor 1 A ω} | {ω | (s : ℕ∞) < waitFor 1 A ω}] =
      P {ω | (t : ℕ∞) < waitFor 1 A ω} := by
  have hq : 0 < 1 - p := by linarith
  have hmB : MeasurableSet {ω | (s : ℕ∞) < waitFor 1 A ω} :=
    gnb_measurable_waitFor 1 A hA (MeasurableSet.of_discrete (s := {x : ℕ∞ | (s : ℕ∞) < x}))
  rw [cond_apply hmB]
  have hsub : {ω | (s : ℕ∞) < waitFor 1 A ω} ∩ {ω | ((s + t : ℕ) : ℕ∞) < waitFor 1 A ω} =
      {ω | ((s + t : ℕ) : ℕ∞) < waitFor 1 A ω} := by
    refine Set.inter_eq_right.2 (fun ω hω => ?_)
    simp only [Set.mem_ofPred_eq] at hω ⊢
    exact lt_of_le_of_lt (by exact_mod_cast Nat.le_add_right s t) hω
  rw [hsub, ← ofReal_measureReal, ← ofReal_measureReal, ← ofReal_measureReal,
    gnb_tail_prob P A p hA hind hp, gnb_tail_prob P A p hA hind hp,
    gnb_tail_prob P A p hA hind hp, ← ENNReal.ofReal_inv_of_pos (by positivity),
    ← ENNReal.ofReal_mul (by positivity)]
  congr 1
  rw [pow_add]
  field_simp

/-- The negative binomial law. With the same independent tries, each a success with chance
`p > 0`, count the tries up to and including the `r`-th success, for any `r ≥ 1`. Then this
wait ends with probability 1; the `r`-th success lands on try `k` (for `k = r, r + 1, …`) with
chance `C(k-1, r-1) p^r (1 - p)^(k-r)`; and, being `r` geometric waits laid end to end, it
averages `r/p` tries with variance `r(1 - p)/p²`. -/
theorem rth_success_wait_is_negative_binomial {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (A : ℕ → Set Ω) (p : ℝ)
    (hA : ∀ i, MeasurableSet (A i)) (hind : iIndepSet A P)
    (hp : ∀ i, P.real (A i) = p) (hp0 : 0 < p) (r : ℕ) (hr : 1 ≤ r) :
    P {ω | waitFor r A ω = ⊤} = 0 ∧
    (∀ k : ℕ, r ≤ k → P.real {ω | waitFor r A ω = k} =
      ((k - 1).choose (r - 1) : ℝ) * p ^ r * (1 - p) ^ (k - r)) ∧
    ∫⁻ ω, (waitFor r A ω : ℝ≥0∞) ∂P = ENNReal.ofReal (r / p) ∧
    variance (fun ω => ((waitFor r A ω).toNat : ℝ)) P = r * (1 - p) / p ^ 2 := by
  obtain ⟨s, rfl⟩ : ∃ s, r = s + 1 := ⟨r - 1, by omega⟩
  obtain ⟨h1, h2, h3⟩ := gnb_main P A p hA hind hp hp0 s
  refine ⟨h1, ?_, ?_, ?_⟩
  · intro k hk
    obtain ⟨m, rfl⟩ : ∃ m, k = m + s + 1 := ⟨k - (s + 1), by omega⟩
    rw [gnb_prob_eq P A p hA hind hp s m, show m + s + 1 - 1 = m + s by omega,
      show s + 1 - 1 = s by omega, show m + s + 1 - (s + 1) = m by omega]
  · rw [h2]; push_cast; rfl
  · rw [h3]; push_cast; ring

/-! Worked numbers for a fair die: p = 1/6, q = 5/6. -/

-- First six on roll 5: (5/6)^4 × 1/6 = 625/7776.
example : (5 / 6 : ℚ) ^ 4 * (1 / 6) = 625 / 7776 := by norm_num
-- No six in the first 3 rolls: (5/6)^3 = 125/216.
example : (5 / 6 : ℚ) ^ 3 = 125 / 216 := by norm_num
-- A six within 4 rolls: 1 - (5/6)^4 = 671/1296 (0.517747).
example : 1 - (5 / 6 : ℚ) ^ 4 = 671 / 1296 := by norm_num
-- A six within 6 rolls: 1 - (5/6)^6 = 31031/46656 (0.665102).
example : 1 - (5 / 6 : ℚ) ^ 6 = 31031 / 46656 := by norm_num
-- Mean wait for the first six: 1 / (1/6) = 6.
example : 1 / (1 / 6 : ℚ) = 6 := by norm_num
-- Its variance: (5/6) / (1/6)^2 = 30.
example : (5 / 6 : ℚ) / (1 / 6) ^ 2 = 30 := by norm_num
-- Third six on roll 5: C(4, 2) × (1/6)^3 × (5/6)^2 = 6 × 25/7776.
example : (Nat.choose 4 2 : ℚ) * (1 / 6) ^ 3 * (5 / 6) ^ 2 = 6 * 25 / 7776 := by
  norm_num [Nat.choose]
-- Mean and variance for the third six: 3 × 6 = 18 and 3 × 30 = 90.
example : 3 / (1 / 6 : ℚ) = 18 := by norm_num
example : 3 * (5 / 6 : ℚ) / (1 / 6) ^ 2 = 90 := by norm_num
-- Memorylessness after four misses: (5/6)^(4+3) / (5/6)^4 = (5/6)^3 = 125/216.
example : (5 / 6 : ℚ) ^ (4 + 3) / (5 / 6) ^ 4 = 125 / 216 := by norm_num
-- The third-six wait remembers: P(T3 > 3 | T3 > 2) = 1 - (1/6)^3 = 215/216.
example : 1 - (1 / 6 : ℚ) ^ 3 = 215 / 216 := by norm_num
-- Counting all 6^6 = 46656 sequences of six rolls: the first six on roll 5 in 5^4 × 6 = 3750
-- of them, and 3750/46656 = 625/7776.
example : (6 : ℕ) ^ 6 = 46656 ∧ 5 ^ 4 * 6 = 3750 := by norm_num
example : (3750 : ℚ) / 46656 = 625 / 7776 := by norm_num
-- The third six on roll 5 in C(4, 2) × 5^2 × 6 = 900 of them, and 900/46656 = 150/7776.
example : Nat.choose 4 2 * 5 ^ 2 * 6 = 900 := by decide
example : (900 : ℚ) / 46656 = 6 * 25 / 7776 := by norm_num
-- Step 7, the same event counted two ways for n = 12 and n = 18: fewer than three sixes in
-- n rolls has the same chance as the third six landing after roll n.
example : (∑ j ∈ Finset.range 3, (Nat.choose 12 j : ℚ) * (1 / 6) ^ j * (5 / 6) ^ (12 - j)) =
    1 - ∑ k ∈ Finset.Icc 3 12, (Nat.choose (k - 1) 2 : ℚ) * (1 / 6) ^ 3 * (5 / 6) ^ (k - 3) := by
  decide +kernel
example : (∑ j ∈ Finset.range 3, (Nat.choose 18 j : ℚ) * (1 / 6) ^ j * (5 / 6) ^ (18 - j)) =
    1 - ∑ k ∈ Finset.Icc 3 18, (Nat.choose (k - 1) 2 : ℚ) * (1 / 6) ^ 3 * (5 / 6) ^ (k - 3) := by
  decide +kernel
-- Counting misses only: mean q/p = (5/6) / (1/6) = 5, one less than 6.
example : (5 / 6 : ℚ) / (1 / 6) = 5 := by norm_num
-- Variance of three waits wrongly taken as 3^2 × 30 = 270, not 3 × 30 = 90.
example : (3 : ℚ) ^ 2 * 30 = 270 ∧ (3 : ℚ) * 30 = 90 := by norm_num
-- Dealing six cards without replacement until the 6: mean (1 + 2 + … + 6)/6 = 7/2.
example : (∑ i ∈ Finset.range 6, ((i : ℚ) + 1)) / 6 = 7 / 2 := by
  norm_num [Finset.sum_range_succ]
-- Help desk: 12 emails an hour, one try per second: mean wait 1 / (12/3600) = 300 seconds.
example : 1 / ((12 : ℚ) / 3600) = 300 := by norm_num
-- Try-it: ten sixes average 10 × 6 = 60 rolls; a 1-in-100 prize averages 100 tries.
example : 10 / (1 / 6 : ℚ) = 60 := by norm_num
example : 1 / (1 / 100 : ℚ) = 100 := by norm_num

#print axioms first_success_wait_is_geometric
#print axioms first_success_wait_memoryless
#print axioms rth_success_wait_is_negative_binomial
