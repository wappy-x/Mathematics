-- Streaming: an exact one-pass distinct counter with s bits needs 2^s ≥ C(U, D), and the median of k independent sketches fails with chance at most e^(-k/8).
import Mathlib.Probability.Moments.SubGaussian
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Sqrt

open MeasureTheory ProbabilityTheory

/-- **The exact floor.** A deterministic one-pass program reads a stream of visitors from a
set `α` of `U` possible addresses. Its memory is `s` bits (`Fin s → Bool`); it starts at
`init`, updates with `step` on each request, and answers `out` of its final memory. If it
reports the exact number of different visitors on every stream, then for every `D` the memory
has at least as many settings as there are sets of `D` visitors: `C(U, D) ≤ 2^s`, that is,
`s ≥ log₂ C(U, D)`. -/
theorem exact_distinct_count_needs_log_choose_bits
    {α : Type*} [Fintype α] [DecidableEq α] (s : ℕ)
    (init : Fin s → Bool) (step : (Fin s → Bool) → α → (Fin s → Bool))
    (out : (Fin s → Bool) → ℕ)
    (hexact : ∀ w : List α, out (w.foldl step init) = w.toFinset.card)
    (D : ℕ) :
    (Fintype.card α).choose D ≤ 2 ^ s ∧
      Real.logb 2 ((Fintype.card α).choose D) ≤ s := by
  have hle : (Fintype.card α).choose D ≤ 2 ^ s := by
    rw [← Finset.card_univ, ← Finset.card_powersetCard]
    have hinj : Set.InjOn (fun S : Finset α => S.toList.foldl step init)
        (Finset.powersetCard D (Finset.univ : Finset α) : Set (Finset α)) := by
      intro S hS T hT hST
      simp only [Finset.mem_coe, Finset.mem_powersetCard] at hS hT
      by_contra hne
      have h1 := hexact (S.toList ++ T.toList)
      have h2 := hexact (T.toList ++ T.toList)
      rw [List.foldl_append] at h1 h2
      simp only at hST
      rw [hST, h2] at h1
      simp only [List.toFinset_append, Finset.toList_toFinset, Finset.union_idempotent] at h1
      have hsub : T ⊆ S ∪ T := Finset.subset_union_right
      have hss : T ⊂ S ∪ T := by
        refine Finset.ssubset_iff_subset_ne.2 ⟨hsub, ?_⟩
        intro heq
        have : S ⊆ T := heq ▸ Finset.subset_union_left
        exact hne (Finset.eq_of_subset_of_card_le this (by rw [hS.2, hT.2]))
      have := Finset.card_lt_card hss
      omega
    have := Finset.card_le_card_of_injOn _ (fun _ _ => Finset.mem_coe.2 (Finset.mem_univ _)) hinj
    simpa [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] using this
  refine ⟨hle, ?_⟩
  rcases Nat.eq_zero_or_pos ((Fintype.card α).choose D) with h0 | hpos
  · rw [h0]; simp
  · have : ((Fintype.card α).choose D : ℝ) ≤ (2 : ℝ) ^ (s : ℝ) := by
      rw [Real.rpow_natCast]; exact_mod_cast hle
    calc Real.logb 2 ((Fintype.card α).choose D) ≤ Real.logb 2 ((2 : ℝ) ^ (s : ℝ)) :=
          Real.logb_le_logb_of_le (by norm_num) (by exact_mod_cast hpos) this
      _ = s := by rw [Real.logb_rpow (by norm_num) (by norm_num)]

/-- **The median trick.** Run `k` independent sketches; copy `i` fails (misses by more than
the allowed error) on the event `F i`, each with chance at most `1/4`. The median can fail
only if at least half the copies fail (the number of failing copies at `ω` is the sum of the
indicators of the `F i`), and by Hoeffding's inequality the chance of that is at
most `e^(-k/8)`. -/
theorem median_trick_half_fail_le_exp
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (k : ℕ) (F : Fin k → Set Ω) (hmeas : ∀ i, MeasurableSet (F i))
    (hind : iIndepSet F μ) (hp : ∀ i, μ.real (F i) ≤ 1 / 4) :
    μ.real {ω | (k : ℝ) / 2 ≤ ∑ i, (F i).indicator (fun _ => (1 : ℝ)) ω}
      ≤ Real.exp (-(k : ℝ) / 8) := by
  set I : Fin k → Ω → ℝ := fun i => (F i).indicator (fun _ => (1 : ℝ)) with hI
  have hIind : iIndepFun I μ := hind.iIndepFun_indicator
  have hImeas : ∀ i, Measurable (I i) := fun i => measurable_const.indicator (hmeas i)
  have hint : ∀ i, μ[I i] = μ.real (F i) := fun i => by
    simp [hI, integral_indicator (hmeas i)]
  set X : Fin k → Ω → ℝ := fun i ω => I i ω - μ[I i] with hX
  have hXind : iIndepFun X μ := by
    have := hIind.comp (fun i (x : ℝ) => x - μ[I i]) (fun i => measurable_id.sub_const _)
    exact this
  have hsub : ∀ i ∈ (Finset.univ : Finset (Fin k)),
      HasSubgaussianMGF (X i) ((‖(1 : ℝ) - 0‖₊ / 2) ^ 2) μ := by
    intro i _
    refine hasSubgaussianMGF_of_mem_Icc (hImeas i).aemeasurable (ae_of_all _ fun ω => ?_)
    simp only [hI, Set.indicator, Set.mem_Icc]
    split_ifs <;> norm_num
  have hc : ((‖(1 : ℝ) - 0‖₊ / 2) ^ 2 : NNReal) = 1 / 4 := by
    simp; norm_num
  have hH := HasSubgaussianMGF.measure_sum_ge_le_of_iIndepFun hXind hsub (ε := (k : ℝ) / 4) (by positivity)
  have hsum : ∑ i, μ[I i] ≤ (k : ℝ) / 4 := by
    calc ∑ i, μ[I i] ≤ ∑ _i : Fin k, (1 / 4 : ℝ) := Finset.sum_le_sum fun i _ => (hint i) ▸ hp i
      _ = (k : ℝ) / 4 := by simp; ring
  calc μ.real {ω | (k : ℝ) / 2 ≤ ∑ i, (F i).indicator (fun _ => (1 : ℝ)) ω}
      ≤ μ.real {ω | (k : ℝ) / 4 ≤ ∑ i ∈ Finset.univ, X i ω} := by
        apply measureReal_mono _ (measure_ne_top _ _)
        intro ω hω
        simp only [Set.mem_ofPred_eq, hX, Finset.sum_sub_distrib] at hω ⊢
        change (k : ℝ) / 2 ≤ ∑ i, I i ω at hω
        linarith
    _ ≤ Real.exp (-((k : ℝ) / 4) ^ 2 / (2 * ∑ i ∈ Finset.univ, ((‖(1 : ℝ) - 0‖₊ / 2) ^ 2 : NNReal))) := hH
    _ = Real.exp (-(k : ℝ) / 8) := by
        congr 1
        rw [hc]
        simp
        rcases Nat.eq_zero_or_pos k with h | h
        · subst h; simp
        · have : (k : ℝ) ≠ 0 := by positivity
          field_simp
          ring

/-- **How many copies.** For any failure chance `δ > 0`, taking `k = ⌈8 ln(1/δ)⌉` copies makes
the median trick's bound `e^(-k/8)` at most `δ`. -/
theorem median_copies_for_failure_chance (δ : ℝ) (hδ : 0 < δ) :
    Real.exp (-((⌈8 * Real.log (1 / δ)⌉₊ : ℕ) : ℝ) / 8) ≤ δ := by
  have h := Nat.le_ceil (8 * Real.log (1 / δ))
  rw [one_div, Real.log_inv] at h
  calc Real.exp (-((⌈8 * Real.log (1 / δ)⌉₊ : ℕ) : ℝ) / 8) ≤ Real.exp (Real.log δ) := by
        apply Real.exp_le_exp.2
        rw [one_div, Real.log_inv]
        linarith
    _ = δ := Real.exp_log hδ

-- The card's whole-number worked examples.
-- 12 bits pick one of 4,096 registers; 4,096 registers of 6 bits are 3,072 bytes.
example : 2 ^ 12 = 4096 := by norm_num
example : 4096 * 6 / 8 = 3072 := by norm_num
-- The promised error 1.04 / sqrt 4,096 uses sqrt 4,096 = 64; four times the memory halves the error.
example : 64 ^ 2 = 4096 ∧ 32 ^ 2 = 1024 ∧ 4 * 1024 = 4096 := by norm_num
-- The plain list of 394,571 four-byte addresses.
example : 4 * 394571 = 1578284 := by norm_num
-- The exact floor over the sketch: 732,554 bytes against 3,072 bytes, 238 times.
example : 732554 / 3072 = 238 := by norm_num
-- The median-trick memory table: 24, 37 and 56 copies of the 3,072-byte sketch.
example : 24 * 3072 = 73728 := by norm_num
example : 37 * 3072 = 113664 := by norm_num
example : 56 * 3072 = 172032 := by norm_num
-- The toy: 10 possible visitors give 1,024 visitor sets; a 9-bit summary has only 512 settings.
example : 2 ^ 9 = 512 ∧ 2 ^ 10 = 1024 ∧ 2 ^ 9 < 2 ^ 10 := by norm_num
-- The 9-bit summary sets bit (v mod 9): the streams [0] and [9] leave the same memory,
-- and so do [0, 0] and [9, 0], whose true distinct counts are 1 and 2.
example : ([0] : List ℕ).foldl (fun st v => st ||| 1 <<< (v % 9)) 0
    = ([9] : List ℕ).foldl (fun st v => st ||| 1 <<< (v % 9)) 0 := by decide
example : ([0, 0] : List ℕ).foldl (fun st v => st ||| 1 <<< (v % 9)) 0
    = ([9, 0] : List ℕ).foldl (fun st v => st ||| 1 <<< (v % 9)) 0 := by decide
example : ([0, 0] : List ℕ).toFinset.card = 1 ∧ ([9, 0] : List ℕ).toFinset.card = 2 := by
  decide

#print axioms exact_distinct_count_needs_log_choose_bits
#print axioms median_trick_half_fail_le_exp
#print axioms median_copies_for_failure_chance
