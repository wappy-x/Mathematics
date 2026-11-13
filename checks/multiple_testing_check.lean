-- Many tests: Bonferroni's cutoff α/m keeps the chance of any false discovery at most (m₀/m) α under any dependence, Benjamini–Hochberg keeps the average false share of the flagged list at most (m₀/m) q for independent tests, and uncorrected independent tests give at least one false alarm with chance 1 - (1 - α)^m₀.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Algebra.Order.Ring.Rat
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.Bochner.Set

open MeasureTheory ProbabilityTheory

namespace MultipleTesting

variable {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K]

/-- `countBelow p t` is N(t): how many of the m p-values are at or below the cutoff t. -/
def countBelow {m : ℕ} (p : Fin m → K) (t : K) : ℕ :=
  (Finset.univ.filter fun i => p i ≤ t).card

/-- Uncorrected testing at level α: reject test i when p i ≤ α. -/
def uncorrected {m : ℕ} (α : K) (p : Fin m → K) : Finset (Fin m) :=
  Finset.univ.filter fun i => p i ≤ α

/-- Bonferroni at level α: reject test i when p i ≤ α / m. -/
def bonferroni {m : ℕ} (α : K) (p : Fin m → K) : Finset (Fin m) :=
  Finset.univ.filter fun i => p i ≤ α / m

/-- The Benjamini–Hochberg number R: the largest rank k with p₍ₖ₎ ≤ k q / m, or 0 if none.
The k-th smallest p-value is at most t exactly when N(t) ≥ k, so this is the card's counting
form R = max {r : N(r q / m) ≥ r}; r = 0 always qualifies, which gives R = 0 when no rank does. -/
def bhCount {m : ℕ} (q : K) (p : Fin m → K) : ℕ :=
  ((Finset.range (m + 1)).filter fun r : ℕ => r ≤ countBelow p ((r : K) * q / m)).sup id

/-- Benjamini–Hochberg at level q: reject every test with p i ≤ R q / m. -/
def bh {m : ℕ} (q : K) (p : Fin m → K) : Finset (Fin m) :=
  Finset.univ.filter fun i => p i ≤ bhCount q p * q / m

/-! ### Helper lemmas -/

lemma countBelow_mono' {m : ℕ} (x : Fin m → ℝ) {t t' : ℝ} (h : t ≤ t') :
    countBelow x t ≤ countBelow x t' := by
  unfold countBelow
  apply Finset.card_le_card
  intro j
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  intro hj
  linarith

lemma le_bhCount' {m : ℕ} (q : ℝ) (x : Fin m → ℝ) {r : ℕ} (hr : r ≤ m)
    (h : r ≤ countBelow x ((r : ℝ) * q / m)) : r ≤ bhCount q x := by
  unfold bhCount
  exact Finset.le_sup (f := id) (Finset.mem_filter.2 ⟨Finset.mem_range.2 (by omega), h⟩)

lemma bhCount_spec' {m : ℕ} (q : ℝ) (x : Fin m → ℝ) :
    bhCount q x ≤ m ∧ bhCount q x ≤ countBelow x ((bhCount q x : ℝ) * q / m) := by
  have hne : ((Finset.range (m + 1)).filter
      fun r : ℕ => r ≤ countBelow x ((r : ℝ) * q / m)).Nonempty := ⟨0, by simp⟩
  obtain ⟨r, hr, hreq⟩ := Finset.exists_mem_eq_sup _ hne id
  have hR : bhCount q x = r := hreq
  rw [hR]
  simp only [Finset.mem_filter, Finset.mem_range] at hr
  exact ⟨by omega, hr.2⟩

lemma countBelow_update_ge' {m : ℕ} (x : Fin m → ℝ) (i : Fin m) {t : ℝ} (ht : 0 ≤ t) :
    countBelow x t ≤ countBelow (Function.update x i 0) t := by
  unfold countBelow
  apply Finset.card_le_card
  intro j
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  intro hj
  by_cases hji : j = i
  · subst hji; simpa using ht
  · simpa [Function.update_of_ne hji] using hj

lemma countBelow_update_le' {m : ℕ} (x : Fin m → ℝ) (i : Fin m) {t : ℝ} (hi : x i ≤ t) :
    countBelow (Function.update x i 0) t ≤ countBelow x t := by
  unfold countBelow
  apply Finset.card_le_card
  intro j
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  intro hj
  by_cases hji : j = i
  · subst hji; exact hi
  · simpa [Function.update_of_ne hji] using hj

lemma bhCount_le_update' {m : ℕ} (q : ℝ) (hq : 0 ≤ q) (x : Fin m → ℝ) (i : Fin m) :
    bhCount q x ≤ bhCount q (Function.update x i 0) := by
  obtain ⟨h1, h2⟩ := bhCount_spec' q x
  exact le_bhCount' q _ h1 (h2.trans (countBelow_update_ge' x i (by positivity)))

lemma bhCount_update_le' {m : ℕ} (q : ℝ) (x : Fin m → ℝ) (i : Fin m)
    (hi : x i ≤ (bhCount q (Function.update x i 0) : ℝ) * q / m) :
    bhCount q (Function.update x i 0) ≤ bhCount q x := by
  obtain ⟨h1, h2⟩ := bhCount_spec' q (Function.update x i 0)
  exact le_bhCount' q x h1 (h2.trans (countBelow_update_le' x i hi))

lemma one_le_bhCount_update' {m : ℕ} (q : ℝ) (hq : 0 ≤ q) (x : Fin m → ℝ) (i : Fin m) :
    1 ≤ bhCount q (Function.update x i 0) := by
  have hm : 1 ≤ m := by have := i.2; omega
  apply le_bhCount' q _ hm
  unfold countBelow
  exact Finset.one_le_card.2 ⟨i, by simp; positivity⟩

lemma bh_pointwise' {m : ℕ} (q : ℝ) (hq : 0 ≤ q) (x : Fin m → ℝ) (N : Finset (Fin m)) :
    ((N ∩ bh q x).card : ℝ) / max ((bh q x).card : ℝ) 1 ≤
      ∑ i ∈ N, ∑ k ∈ Finset.Icc 1 m,
        (if bhCount q (Function.update x i 0) = k ∧ x i ≤ (k : ℝ) * q / m
          then (1 / (k : ℝ)) else 0) := by
  rw [← Finset.filter_mem_eq_inter, Finset.card_filter, Nat.cast_sum, Finset.sum_div]
  apply Finset.sum_le_sum
  intro i _
  simp only [ite_and]
  rw [Finset.sum_ite_eq]
  have hR1 := one_le_bhCount_update' q hq x i
  have hRm := (bhCount_spec' q (Function.update x i 0)).1
  have hmem : bhCount q (Function.update x i 0) ∈ Finset.Icc 1 m := Finset.mem_Icc.2 ⟨hR1, hRm⟩
  simp only [hmem, ↓reduceIte]
  by_cases hi : i ∈ bh q x
  · have hxi0 : x i ≤ (bhCount q x : ℝ) * q / m := (Finset.mem_filter.1 hi).2
    have hle : (bhCount q x : ℝ) * q / m
        ≤ (bhCount q (Function.update x i 0) : ℝ) * q / m := by
      gcongr
      exact_mod_cast bhCount_le_update' q hq x i
    have hxi := hxi0.trans hle
    simp only [hi, hxi, ↓reduceIte, Nat.cast_one]
    have hge : bhCount q (Function.update x i 0) ≤ (bh q x).card :=
      (bhCount_update_le' q x i hxi).trans (bhCount_spec' q x).2
    have hpos : (0 : ℝ) < bhCount q (Function.update x i 0) := by exact_mod_cast hR1
    apply one_div_le_one_div_of_le hpos
    exact le_max_of_le_left (by exact_mod_cast hge)
  · simp only [hi, ↓reduceIte, Nat.cast_zero, zero_div]
    split_ifs <;> positivity

lemma measurable_bhCount' {m : ℕ} (q : ℝ) : Measurable (fun x : Fin m → ℝ => bhCount q x) := by
  let B : (Fin m → ℝ) → (Fin (m + 1) → Fin m → Bool) :=
    fun x r j => decide (x j ≤ (r.val : ℝ) * q / m)
  let G : (Fin (m + 1) → Fin m → Bool) → ℕ := fun b =>
    ((Finset.univ : Finset (Fin (m + 1))).filter
      fun r => r.val ≤ (Finset.univ.filter fun j => b r j = true).card).sup Fin.val
  have hB : Measurable B := by
    apply Measurable.of_eval; intro r
    apply Measurable.of_eval; intro j
    apply measurable_to_bool
    have : (fun x : Fin m → ℝ => B x r j) ⁻¹' {true} = {x | x j ≤ (r.val : ℝ) * q / m} := by
      ext x; simp [B]
    rw [this]
    exact measurableSet_le (measurable_pi_apply j) measurable_const
  have hGB : (fun x => bhCount q x) = G ∘ B := by
    funext x
    have hcb : ∀ r : Fin (m + 1),
        (Finset.univ.filter fun j => B x r j = true).card = countBelow x ((r.val : ℝ) * q / m) := by
      intro r; simp [B, countBelow]
    apply le_antisymm
    · obtain ⟨h1, h2⟩ := bhCount_spec' q x
      have hmemG : (⟨bhCount q x, by omega⟩ : Fin (m + 1)) ∈ (Finset.univ : Finset (Fin (m + 1))).filter
          fun r => r.val ≤ (Finset.univ.filter fun j => B x r j = true).card := by
        simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        rw [hcb]; exact h2
      exact Finset.le_sup (f := Fin.val) hmemG
    · show G (B x) ≤ bhCount q x
      apply Finset.sup_le
      intro r hr
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hr
      rw [hcb] at hr
      exact le_bhCount' q x (by omega) hr
  rw [hGB]
  exact (measurable_of_countable G).comp hB

lemma measurable_update_zero' {m : ℕ} (i : Fin m) :
    Measurable (fun x : Fin m → ℝ => Function.update x i 0) := by
  apply Measurable.of_eval
  intro j
  by_cases hji : j = i
  · subst hji; simp
  · simpa [Function.update_of_ne hji] using measurable_pi_apply j

/-- Bonferroni controls the family-wise error rate. Run m tests, fixed in advance, on one
probability space. Let N be the set of tests whose null is true, m₀ = #N of them, and suppose each
true null has a valid p-value: the chance that it is at most t is at most t, for every cutoff t.
Nothing else is assumed; in particular the tests may depend on each other in any way. Reject test i
when p i ≤ α / m. Then the chance of at least one false discovery is at most (m₀ / m) α, which is
at most α. -/
theorem bonferroni_fwer_le
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (m : ℕ) (p : Fin m → Ω → ℝ) (N : Finset (Fin m))
    (hvalid : ∀ i ∈ N, ∀ t : ℝ, μ {ω | p i ω ≤ t} ≤ ENNReal.ofReal t) (α : ℝ) :
    μ {ω | ∃ i ∈ N, i ∈ bonferroni α (fun j => p j ω)}
        ≤ ENNReal.ofReal ((N.card : ℝ) / m * α) ∧
      ENNReal.ofReal ((N.card : ℝ) / m * α) ≤ ENNReal.ofReal α := by
  have hNm : (N.card : ℝ) ≤ m := by
    exact_mod_cast (Finset.card_le_univ N).trans (by simp)
  constructor
  · have hset : {ω | ∃ i ∈ N, i ∈ bonferroni α (fun j => p j ω)}
        = ⋃ i ∈ N, {ω | p i ω ≤ α / m} := by
      ext ω; simp [bonferroni]
    rw [hset]
    calc μ (⋃ i ∈ N, {ω | p i ω ≤ α / m}) ≤ ∑ i ∈ N, μ {ω | p i ω ≤ α / m} :=
          measure_biUnion_finset_le _ _
      _ ≤ ∑ i ∈ N, ENNReal.ofReal (α / m) := Finset.sum_le_sum fun i hi => hvalid i hi _
      _ = ENNReal.ofReal ((N.card : ℝ) / m * α) := by
        rw [Finset.sum_const, nsmul_eq_mul]
        have heq : (N.card : ℝ) / m * α = N.card * (α / m) := by ring
        rw [heq]
        rcases le_or_gt 0 (α / m) with h | h
        · rw [← ENNReal.ofReal_natCast, ← ENNReal.ofReal_mul (by positivity)]
        · rw [ENNReal.ofReal_of_nonpos h.le, mul_zero]
          symm
          exact ENNReal.ofReal_of_nonpos (mul_nonpos_of_nonneg_of_nonpos (by positivity) h.le)
  · rcases le_or_gt 0 α with hα | hα
    · apply ENNReal.ofReal_le_ofReal
      exact mul_le_of_le_one_left hα (div_le_one_of_le₀ hNm (by positivity))
    · rw [ENNReal.ofReal_of_nonpos hα.le,
        ENNReal.ofReal_of_nonpos (mul_nonpos_of_nonneg_of_nonpos (by positivity) hα.le)]

/-- Benjamini–Hochberg controls the false discovery rate for independent tests. Run m independent
tests, fixed in advance, with p-values that are random variables. Let N be the set of tests whose
null is true, m₀ = #N, each with a valid p-value. Run BH at level q ≥ 0: R tests are rejected and
V of them are true nulls. Then the long-run average of the false share V / max(R, 1) is at most
(m₀ / m) q, which is at most q. -/
theorem bh_fdr_le
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (m : ℕ) (p : Fin m → Ω → ℝ) (hmeas : ∀ i, Measurable (p i)) (hind : iIndepFun p μ)
    (N : Finset (Fin m))
    (hvalid : ∀ i ∈ N, ∀ t : ℝ, μ {ω | p i ω ≤ t} ≤ ENNReal.ofReal t) (q : ℝ) (hq : 0 ≤ q) :
    ∫ ω, ((N ∩ bh q (fun j => p j ω)).card : ℝ) / max ((bh q (fun j => p j ω)).card : ℝ) 1 ∂μ
        ≤ (N.card : ℝ) / m * q ∧
      (N.card : ℝ) / m * q ≤ q := by
  have hNm : (N.card : ℝ) ≤ m := by
    exact_mod_cast (Finset.card_le_univ N).trans (by simp)
  refine ⟨?_, ?_⟩
  swap
  · rcases Nat.eq_zero_or_pos m with h | h
    · subst h; simp [hq]
    · exact mul_le_of_le_one_left hq (div_le_one_of_le₀ hNm (by positivity))
  -- The vector of p-values and, for each test i, the BH count with p i replaced by 0.
  set X : Ω → Fin m → ℝ := fun ω j => p j ω with hXdef
  have hX : Measurable X := Measurable.of_eval hmeas
  let Rp : Fin m → Ω → ℕ := fun i ω => bhCount q (Function.update (X ω) i 0)
  have hRp : ∀ i, Measurable (Rp i) := fun i =>
    (measurable_bhCount' q).comp ((measurable_update_zero' i).comp hX)
  -- Independence of p i from the replaced vector.
  have hfac : ∀ i : Fin m, ∀ (k : ℕ) (t : ℝ),
      μ.real ({ω | p i ω ≤ t} ∩ Rp i ⁻¹' {k})
        = μ.real {ω | p i ω ≤ t} * μ.real (Rp i ⁻¹' {k}) := by
    intro i k t
    have hST : Disjoint ({i} : Finset (Fin m)) (Finset.univ.erase i) :=
      Finset.disjoint_singleton_left.2 (Finset.notMem_erase i _)
    have hI := hind.indepFun_finset {i} (Finset.univ.erase i) hST hmeas
    let ext : (↥(Finset.univ.erase i) → ℝ) → Fin m → ℝ :=
      fun y j => if h : j ∈ Finset.univ.erase i then y ⟨j, h⟩ else 0
    have hext : Measurable ext := by
      apply Measurable.of_eval
      intro j
      by_cases h : j ∈ Finset.univ.erase i
      · simp only [ext, h, ↓reduceDIte]; exact measurable_pi_apply _
      · simp only [ext, h, ↓reduceDIte]; exact measurable_const
    let s : Set (↥({i} : Finset (Fin m)) → ℝ) := {v | v ⟨i, Finset.mem_singleton_self i⟩ ≤ t}
    let u : Set (↥(Finset.univ.erase i) → ℝ) :=
      ext ⁻¹' ((fun x : Fin m → ℝ => bhCount q x) ⁻¹' {k})
    have hs : MeasurableSet s := measurableSet_le (measurable_pi_apply _) measurable_const
    have hu : MeasurableSet u :=
      hext ((measurable_bhCount' q) (measurableSet_singleton k))
    have h1 : {ω | p i ω ≤ t} = (fun a (j : ↥({i} : Finset (Fin m))) => p j a) ⁻¹' s := rfl
    have h2 : Rp i ⁻¹' {k}
        = (fun a (j : ↥(Finset.univ.erase i)) => p j a) ⁻¹' u := by
      ext ω
      simp only [Set.mem_preimage, Set.mem_singleton_iff, u, Rp]
      have : ext (fun j : ↥(Finset.univ.erase i) => p j ω)
          = Function.update (X ω) i 0 := by
        funext j
        by_cases hji : j = i
        · subst hji; simp [ext]
        · simp [ext, hXdef, hji]
      rw [this]
    rw [h1, h2, measureReal_def, measureReal_def, measureReal_def,
      hI.measure_inter_preimage_eq_mul s u hs hu, ENNReal.toReal_mul]
  -- The dominating function.
  let E : Fin m → ℕ → Set Ω := fun i k => {ω | p i ω ≤ (k : ℝ) * q / m} ∩ Rp i ⁻¹' {k}
  have hE : ∀ i k, MeasurableSet (E i k) := fun i k =>
    (measurableSet_le (hmeas i) measurable_const).inter (hRp i (measurableSet_singleton k))
  let g : Ω → ℝ := fun ω =>
    ∑ i ∈ N, ∑ k ∈ Finset.Icc 1 m, (E i k).indicator (fun _ => 1 / (k : ℝ)) ω
  have hg : Integrable g μ := by
    refine integrable_finsetSum _ fun i _ => integrable_finsetSum _ fun k _ => ?_
    exact (integrable_const _).indicator (hE i k)
  have hfg : ∀ ω, ((N ∩ bh q (fun j => p j ω)).card : ℝ) / max ((bh q (fun j => p j ω)).card : ℝ) 1
      ≤ g ω := by
    intro ω
    refine (bh_pointwise' q hq (X ω) N).trans (le_of_eq ?_)
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun k _ => ?_
    simp only [E, Rp, hXdef]
    by_cases h1 : bhCount q (Function.update (fun j => p j ω) i 0) = k <;>
      by_cases h2 : p i ω ≤ (k : ℝ) * q / m <;> simp [h1, h2]
  calc ∫ ω, ((N ∩ bh q (fun j => p j ω)).card : ℝ) / max ((bh q (fun j => p j ω)).card : ℝ) 1 ∂μ
      ≤ ∫ ω, g ω ∂μ :=
        integral_mono_of_nonneg (Filter.Eventually.of_forall fun ω => by positivity) hg
          (Filter.Eventually.of_forall hfg)
    _ = ∑ i ∈ N, ∑ k ∈ Finset.Icc 1 m, μ.real (E i k) * (1 / (k : ℝ)) := by
        simp only [g]
        rw [integral_finsetSum _ fun i _ => integrable_finsetSum _ fun k _ =>
          (integrable_const _).indicator (hE i k)]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [integral_finsetSum _ fun k _ => (integrable_const _).indicator (hE i k)]
        refine Finset.sum_congr rfl fun k _ => ?_
        rw [integral_indicator_const _ (hE i k), smul_eq_mul]
    _ ≤ ∑ i ∈ N, ∑ k ∈ Finset.Icc 1 m, μ.real (Rp i ⁻¹' {k}) * (q / m) := by
        refine Finset.sum_le_sum fun i hi => Finset.sum_le_sum fun k hk => ?_
        have hk1 : 1 ≤ k := (Finset.mem_Icc.1 hk).1
        have hkpos : (0 : ℝ) < k := by exact_mod_cast hk1
        have hmpos : (0 : ℝ) < m := by have := i.2; exact_mod_cast (by omega : 0 < m)
        have hv : μ.real {ω | p i ω ≤ (k : ℝ) * q / m} ≤ (k : ℝ) * q / m :=
          ENNReal.toReal_le_of_le_ofReal (by positivity) (hvalid i hi _)
        have hP : 0 ≤ μ.real (Rp i ⁻¹' {k}) := measureReal_nonneg
        simp only [E]
        rw [hfac]
        calc μ.real {ω | p i ω ≤ (k : ℝ) * q / m} * μ.real (Rp i ⁻¹' {k}) * (1 / (k : ℝ))
            ≤ ((k : ℝ) * q / m) * μ.real (Rp i ⁻¹' {k}) * (1 / (k : ℝ)) := by gcongr
          _ = μ.real (Rp i ⁻¹' {k}) * (q / m) := by field_simp
    _ ≤ ∑ i ∈ N, (1 : ℝ) * (q / m) := by
        refine Finset.sum_le_sum fun i _ => ?_
        rw [← Finset.sum_mul]
        gcongr
        rw [sum_measureReal_preimage_singleton _ fun k _ => hRp i (measurableSet_singleton k)]
        exact measureReal_le_one
    _ = (N.card : ℝ) / m * q := by
        rw [Finset.sum_const, nsmul_eq_mul]; ring

/-- One in twenty lies. Run m independent tests uncorrected at level α, where each of the m₀ true
nulls in N is flagged with chance exactly α. Then the chance of at least one false alarm is
1 - (1 - α)^m₀; with m₀ = 100 and α = 0.05 that is 1 - 0.95^100, about 0.994. -/
theorem uncorrected_any_false_alarm
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (m : ℕ) (p : Fin m → Ω → ℝ) (hmeas : ∀ i, Measurable (p i)) (hind : iIndepFun p μ)
    (N : Finset (Fin m)) (α : ℝ) (hα : ∀ i ∈ N, μ.real {ω | p i ω ≤ α} = α) :
    μ.real {ω | ∃ i ∈ N, i ∈ uncorrected α (fun j => p j ω)} = 1 - (1 - α) ^ N.card := by
  have hset : {ω | ∃ i ∈ N, i ∈ uncorrected α (fun j => p j ω)}
      = (⋂ i ∈ N, p i ⁻¹' Set.Ioi α)ᶜ := by
    ext ω; simp [uncorrected]
  have hmeasI : MeasurableSet (⋂ i ∈ N, p i ⁻¹' Set.Ioi α) :=
    Finset.measurableSet_biInter N fun i _ => hmeas i measurableSet_Ioi
  rw [hset, probReal_compl_eq_one_sub hmeasI]
  congr 1
  have h := hind.measure_inter_preimage_eq_mul N (sets := fun _ => Set.Ioi α)
    (fun i _ => measurableSet_Ioi)
  rw [measureReal_def, h, ENNReal.toReal_prod]
  rw [Finset.prod_congr rfl (g := fun _ => 1 - α), Finset.prod_const]
  intro i hi
  have hc : p i ⁻¹' Set.Ioi α = {ω | p i ω ≤ α}ᶜ := by ext; simp
  rw [hc, ← measureReal_def,
    probReal_compl_eq_one_sub (measurableSet_le (hmeas i) measurable_const), hα i hi]

/-- The lab's twelve smallest p-values, in order. -/
def labSmall : List ℚ :=
  [2 / 100000, 11 / 100000, 4 / 10000, 9 / 10000, 15 / 10000, 21 / 10000, 36 / 10000,
    38 / 10000, 52 / 10000, 71 / 10000, 21 / 1000, 34 / 1000]

/-- The lab's 100 p-values: the twelve smallest, then 88 spread evenly, 0.06, 0.07, ..., 0.93. -/
def labP (i : Fin 100) : ℚ :=
  if i.val < 12 then labSmall.getD i.val 0 else ((i.val : ℚ) - 6) / 100

-- The last of the 88 even values is 0.93.
example : labP 99 = 93 / 100 := by decide +kernel
-- Expected false flags if all 100 genes are null: 100 × 0.05 = 5.
example : (100 : ℚ) * (5 / 100) = 5 := by norm_num
-- Uncorrected at 0.05: 12 flags.
example : (uncorrected (5 / 100 : ℚ) labP).card = 12 := by decide +kernel
-- Bonferroni cutoff 0.05 / 100 = 0.0005, and 3 flags.
example : (5 / 100 : ℚ) / 100 = 5 / 10000 := by norm_num
example : (bonferroni (5 / 100 : ℚ) labP).card = 3 := by decide +kernel
-- BH: rank 7 is above its line (0.0036 > 0.0035), rank 8 under (0.0038 ≤ 0.0040).
example : (36 / 10000 : ℚ) > 7 * (5 / 100) / 100 ∧ (38 / 10000 : ℚ) ≤ 8 * (5 / 100) / 100 := by
  norm_num
-- BH: R = 8, cutoff 8 × 0.05 / 100 = 0.004, and 8 flags.
example : bhCount (5 / 100 : ℚ) labP = 8 := by decide +kernel
example : (8 : ℚ) * (5 / 100) / 100 = 4 / 1000 := by norm_num
example : (bh (5 / 100 : ℚ) labP).card = 8 := by decide +kernel
-- Three tests at level 0.75, Bonferroni FWER 1 - 0.75^m₀ for m₀ = 0, 1, 2, 3:
-- 0, 0.25, 0.4375, 0.578125.
example : (1 - (3 / 4 : ℚ) ^ 0, 1 - (3 / 4 : ℚ) ^ 1, 1 - (3 / 4 : ℚ) ^ 2, 1 - (3 / 4 : ℚ) ^ 3)
    = (0, 1 / 4, 7 / 16, 37 / 64) := by norm_num

#print axioms countBelow_mono'
#print axioms le_bhCount'
#print axioms bhCount_spec'
#print axioms countBelow_update_ge'
#print axioms countBelow_update_le'
#print axioms bhCount_le_update'
#print axioms bhCount_update_le'
#print axioms one_le_bhCount_update'
#print axioms bh_pointwise'
#print axioms measurable_bhCount'
#print axioms measurable_update_zero'
#print axioms bonferroni_fwer_le
#print axioms bh_fdr_le
#print axioms uncorrected_any_false_alarm

end MultipleTesting
