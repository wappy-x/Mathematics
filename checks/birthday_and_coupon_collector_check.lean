-- Two classics: with d equally likely days drawn independently, the chance that n people all have different days is the product of (1 - i/d) for i < n, and the average number of people needed until every day is taken is d times the harmonic number H_d.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.MeasureTheory.MeasurableSpace.Instances
import Mathlib.NumberTheory.Harmonic.Defs
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.ENat.Lattice
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory
open scoped ENNReal

lemma bc_prob_vec_mem
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    {ι : Type*} [Fintype ι] [DecidableEq ι]
    (d : ℕ) (X : ι → Ω → Fin d) (hmeas : ∀ i, Measurable (X i))
    (hind : iIndepFun X μ)
    (hunif : ∀ i (k : Fin d), μ.real {ω | X i ω = k} = 1 / d)
    (s : Finset (ι → Fin d)) :
    μ.real {ω | (fun i => X i ω) ∈ s} = s.card / (d : ℝ) ^ (Fintype.card ι) := by
  have hpt : ∀ f : ι → Fin d, μ.real {ω | (fun i => X i ω) = f} = (1 / (d : ℝ)) ^ Fintype.card ι := by
    intro f
    have h1 : {ω | (fun i => X i ω) = f} = ⋂ i ∈ (Finset.univ : Finset ι), X i ⁻¹' {f i} := by
      ext ω; simp [funext_iff]
    rw [h1, measureReal_def, hind.measure_inter_preimage_eq_mul _ (fun i _ => measurableSet_singleton _),
      ENNReal.toReal_prod]
    have h2 : ∀ i, (μ (X i ⁻¹' {f i})).toReal = 1 / (d : ℝ) := fun i => hunif i (f i)
    simp only [h2, Finset.prod_const, Finset.card_univ]
  have h1 : {ω | (fun i => X i ω) ∈ s} = ⋃ f ∈ s, {ω | (fun i => X i ω) = f} := by
    ext ω; simp
  rw [h1, measureReal_biUnion_finset]
  · simp only [hpt, Finset.sum_const, nsmul_eq_mul, one_div, inv_pow]
    rw [div_eq_mul_inv]
  · intro f _ g _ hfg
    refine Set.disjoint_left.mpr ?_
    intro ω h1 h2
    exact hfg (h1.symm.trans h2)
  · intro f _
    have : {ω | (fun i => X i ω) = f} = ⋂ i, X i ⁻¹' {f i} := by ext ω; simp [funext_iff]
    rw [this]
    exact MeasurableSet.iInter (fun i => hmeas i (measurableSet_singleton _))

#print axioms bc_prob_vec_mem

lemma bc_descFactorial_div (d n : ℕ) (hd : 0 < d) :
    (d.descFactorial n : ℝ) / (d : ℝ) ^ n = ∏ i ∈ Finset.range n, (1 - (i : ℝ) / d) := by
  have hd' : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.prod_range_succ, ← ih, Nat.descFactorial_succ]
    rcases le_or_gt n d with h | h
    · push_cast [Nat.cast_sub h]
      field_simp
      ring
    · have : d.descFactorial n = 0 := Nat.descFactorial_eq_zero_iff_lt.mpr h
      simp [this]

#print axioms bc_descFactorial_div

/-- Potential: expected remaining wait from `j` covered days out of `d`. -/
noncomputable def bcH (d j : ℕ) : ℝ := ∑ i ∈ Finset.Ico j d, (d : ℝ) / (d - i)

#print axioms bcH

lemma bcH_nonneg_term (d i : ℕ) (hi : i ∈ Finset.Ico 0 d) : 0 ≤ (d : ℝ) / (d - i) := by
  have : i < d := (Finset.mem_Ico.mp hi).2
  have : (i : ℝ) < d := by exact_mod_cast this
  positivity

#print axioms bcH_nonneg_term

lemma bcH_le (d j : ℕ) : bcH d j ≤ bcH d 0 := by
  unfold bcH
  apply Finset.sum_le_sum_of_subset_of_nonneg
  · intro i hi; simp only [Finset.mem_Ico] at hi ⊢; omega
  · intro i hi _; exact bcH_nonneg_term d i hi

#print axioms bcH_le

lemma bcH_nonneg (d j : ℕ) : 0 ≤ bcH d j := by
  unfold bcH
  apply Finset.sum_nonneg
  intro i hi
  have : i < d := (Finset.mem_Ico.mp hi).2
  have : (i : ℝ) < d := by exact_mod_cast this
  positivity

#print axioms bcH_nonneg

lemma bcH_self (d : ℕ) : bcH d d = 0 := by simp [bcH]

#print axioms bcH_self

lemma bcH_step (d j : ℕ) (hj : j ≤ d) :
    (j : ℝ) * bcH d j + ((d : ℝ) - j) * bcH d (j + 1)
      = d * bcH d j - if j < d then (d : ℝ) else 0 := by
  rcases hj.lt_or_eq with h | h
  · have hs : bcH d j = d / (d - j) + bcH d (j + 1) := by
      unfold bcH; rw [Finset.sum_eq_sum_Ico_succ_bot h]
    have hpos : (0 : ℝ) < d - j := by
      have : (j : ℝ) < d := by exact_mod_cast h
      linarith
    rw [ite_eq_left_iff.mpr (fun h' => absurd h h'), hs]
    field_simp
    ring
  · subst h; simp [bcH_self]

#print axioms bcH_step

lemma bcH_zero (d : ℕ) : bcH d 0 = d * (harmonic d : ℝ) := by
  unfold bcH
  rw [← Finset.range_eq_Ico, harmonic]
  push_cast
  rw [Finset.mul_sum]
  rw [← Finset.sum_range_reflect]
  apply Finset.sum_congr rfl
  intro i hi
  have hi : i < d := Finset.mem_range.mp hi
  rw [Nat.cast_sub (by omega), Nat.cast_sub (by omega)]
  push_cast
  rw [div_eq_mul_inv]
  congr 2
  ring

#print axioms bcH_zero

lemma bc_image_cons {d m : ℕ} (k : Fin d) (f : Fin m → Fin d) :
    Finset.univ.image (Fin.cons k f : Fin (m + 1) → Fin d) = insert k (Finset.univ.image f) := by
  ext x
  simp [Fin.exists_fin_succ, eq_comm]

#print axioms bc_image_cons

lemma bc_sum_insert {d : ℕ} (S : Finset (Fin d)) (g : ℕ → ℝ) :
    ∑ k : Fin d, g (insert k S).card = S.card * g S.card + ((d : ℝ) - S.card) * g (S.card + 1) := by
  rw [← Finset.sum_add_sum_compl S]
  have h1 : ∑ k ∈ S, g (insert k S).card = S.card * g S.card := by
    rw [Finset.sum_congr rfl (fun k hk => by rw [Finset.insert_eq_of_mem hk])]
    simp
  have h2 : ∑ k ∈ Sᶜ, g (insert k S).card = ((d : ℝ) - S.card) * g (S.card + 1) := by
    rw [Finset.sum_congr rfl (fun k hk => by
      rw [Finset.card_insert_of_notMem (Finset.mem_compl.mp hk)])]
    simp only [Finset.sum_const, nsmul_eq_mul, Finset.card_compl, Fintype.card_fin]
    rw [Nat.cast_sub (by simpa using S.card_le_univ)]
  rw [h1, h2]

#print axioms bc_sum_insert

/-- Probability, after `m` draws, that some day is still missing. -/
noncomputable def bcR (d m : ℕ) : ℝ :=
  ((Finset.univ.filter (fun f : Fin m → Fin d => ¬ Function.Surjective f)).card : ℝ) / (d : ℝ) ^ m

#print axioms bcR

noncomputable def bcG (d m : ℕ) : ℝ :=
  (∑ f : Fin m → Fin d, bcH d (Finset.univ.image f).card) / (d : ℝ) ^ m

#print axioms bcG

lemma bc_card_lt_iff {d m : ℕ} (f : Fin m → Fin d) :
    (Finset.univ.image f).card < d ↔ ¬ Function.Surjective f := by
  have := Finset.card_lt_iff_ne_univ (Finset.univ.image f)
  rw [Fintype.card_fin] at this
  rw [this, Ne, Finset.eq_univ_iff_forall]
  simp [Function.Surjective]

#print axioms bc_card_lt_iff

lemma bcG_succ (d m : ℕ) (hd : 0 < d) : bcG d (m + 1) = bcG d m - bcR d m := by
  have hd' : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
  have key : ∑ f : Fin (m + 1) → Fin d, bcH d (Finset.univ.image f).card
      = ∑ f : Fin m → Fin d, (d * bcH d (Finset.univ.image f).card
          - if ¬ Function.Surjective f then (d : ℝ) else 0) := by
    rw [← (Fin.consEquiv (fun _ : Fin (m + 1) => Fin d)).sum_comp, Fintype.sum_prod_type_right]
    apply Finset.sum_congr rfl
    intro f _
    simp only [Fin.consEquiv_apply, bc_image_cons]
    rw [bc_sum_insert, bcH_step d _ (by simpa using (Finset.univ.image f).card_le_univ)]
    simp only [bc_card_lt_iff]
  unfold bcG bcR
  rw [key, Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_ite, Finset.sum_const_zero,
    add_zero, Finset.sum_const, nsmul_eq_mul]
  field_simp
  ring

#print axioms bcG_succ

lemma bcG_le (d m : ℕ) : bcG d m ≤ bcH d 0 * bcR d m := by
  unfold bcG bcR
  rw [mul_div_assoc']
  apply div_le_div_of_nonneg_right _ (by positivity)
  rw [Finset.card_filter, Nat.cast_sum, Finset.mul_sum]
  apply Finset.sum_le_sum
  intro f _
  by_cases hf : Function.Surjective f
  · have : (Finset.univ.image f).card = d := by
      have := (bc_card_lt_iff f).not.mpr (not_not.mpr hf)
      have h2 := (Finset.univ.image f).card_le_univ
      simp at h2; omega
    simp [hf, this, bcH_self]
  · simp [hf, bcH_le]

#print axioms bcG_le

lemma bcG_nonneg (d m : ℕ) : 0 ≤ bcG d m := by
  unfold bcG
  apply div_nonneg (Finset.sum_nonneg (fun f _ => bcH_nonneg _ _)) (by positivity)

#print axioms bcG_nonneg

lemma bcR_nonneg (d m : ℕ) : 0 ≤ bcR d m := by unfold bcR; positivity

#print axioms bcR_nonneg

lemma bcG_zero (d : ℕ) : bcG d 0 = bcH d 0 := by
  simp [bcG]

#print axioms bcG_zero

lemma bc_hasSum (d : ℕ) (hd : 0 < d) : HasSum (bcR d) (d * (harmonic d : ℝ)) := by
  rw [← bcH_zero]
  have hpart : ∀ M, ∑ m ∈ Finset.range M, bcR d m = bcH d 0 - bcG d M := by
    intro M
    induction M with
    | zero => simp [bcG_zero]
    | succ M ih => rw [Finset.sum_range_succ, ih, bcG_succ d M hd]; ring
  have hsum : Summable (bcR d) :=
    summable_of_sum_range_le (bcR_nonneg d) (fun M => by
      rw [hpart]; linarith [bcG_nonneg d M])
  have hR : Filter.Tendsto (bcR d) Filter.atTop (nhds 0) := hsum.tendsto_atTop_zero
  have hG : Filter.Tendsto (bcG d) Filter.atTop (nhds 0) := by
    have h2 : Filter.Tendsto (fun M => bcH d 0 * bcR d M) Filter.atTop (nhds 0) := by
      simpa using hR.const_mul (bcH d 0)
    exact squeeze_zero (bcG_nonneg d) (bcG_le d) h2
  rw [hasSum_iff_tendsto_nat_of_nonneg (bcR_nonneg d)]
  simp_rw [hpart]
  simpa using (tendsto_const_nhds (x := bcH d 0)).sub hG

#print axioms bc_hasSum

lemma bc_enat_tsum (n : ℕ∞) :
    ((n : ℕ∞) : ℝ≥0∞) = ∑' m : ℕ, if (m : ℕ∞) < n then (1 : ℝ≥0∞) else 0 := by
  induction n using ENat.recTopCoe with
  | top => simp
  | coe k =>
    rw [tsum_eq_sum (s := Finset.range k)]
    · simp only [Nat.cast_lt]
      rw [Finset.sum_ite_of_true (fun m hm => Finset.mem_range.mp hm)]
      simp
    · intro m hm
      simp only [Finset.mem_range, not_lt] at hm
      simp [Nat.cast_lt, not_lt.mpr hm]

#print axioms bc_enat_tsum

lemma bc_lt_iInf {d : ℕ} {Ω : Type*} (X : ℕ → Ω → Fin d) (ω : Ω) (m : ℕ) :
    (m : ℕ∞) < ⨅ (m' : ℕ) (_ : ∀ k : Fin d, ∃ i < m', X i ω = k), (m' : ℕ∞)
      ↔ ¬ ∀ k : Fin d, ∃ i < m, X i ω = k := by
  constructor
  · intro hlt hcov
    exact absurd hlt (not_lt.mpr (iInf₂_le m hcov))
  · intro hnc
    have h : ((m + 1 : ℕ) : ℕ∞) ≤ ⨅ (m' : ℕ) (_ : ∀ k : Fin d, ∃ i < m', X i ω = k), (m' : ℕ∞) := by
      refine le_iInf₂ (fun m' hm' => ?_)
      rw [Nat.cast_le]
      by_contra hle
      apply hnc
      intro k
      obtain ⟨i, hi, hk⟩ := hm' k
      exact ⟨i, by omega, hk⟩
    exact lt_of_lt_of_le (Nat.cast_lt.mpr (Nat.lt_succ_self m)) h

#print axioms bc_lt_iInf

/-- The birthday problem. n people each get one of d days. Every day is equally likely for
every person (chance 1/d), and the people are independent; days are drawn with replacement.
Then the chance that no two people share a day is the product of shrinking fractions
(d/d)((d-1)/d)⋯((d-n+1)/d), that is, the product of (1 - i/d) for i = 0, …, n-1. The chance of
a shared day is one minus this. -/
theorem birthday_no_shared_day_prob
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (n d : ℕ) (X : Fin n → Ω → Fin d) (hmeas : ∀ i, Measurable (X i))
    (hind : iIndepFun X μ)
    (hunif : ∀ i (k : Fin d), μ.real {ω | X i ω = k} = 1 / d) :
    μ.real {ω | Function.Injective (fun i => X i ω)}
      = ∏ i ∈ Finset.range n, (1 - (i : ℝ) / d) := by
  rcases Nat.eq_zero_or_pos d with hd | hd
  · subst hd
    rcases Nat.eq_zero_or_pos n with hn | hn
    · subst hn
      have : {ω | Function.Injective (fun i : Fin 0 => X i ω)} = Set.univ := by
        ext ω; simp [Function.Injective]
      simp [this]
    · obtain ⟨ω⟩ : Nonempty Ω := nonempty_of_isProbabilityMeasure μ
      exact (X ⟨0, hn⟩ ω).elim0
  have h1 : {ω | Function.Injective (fun i => X i ω)}
      = {ω | (fun i => X i ω) ∈ (Finset.univ.filter (fun f : Fin n → Fin d => Function.Injective f))} := by
    ext ω; simp
  rw [h1, bc_prob_vec_mem μ d X hmeas hind hunif, Fintype.card_fin, ← bc_descFactorial_div d n hd]
  congr 2
  rw [← Fintype.card_subtype, Fintype.card_congr (Equiv.subtypeInjectiveEquivEmbedding _ _),
    Fintype.card_embedding_eq]
  simp

/-- The coupon collector's problem. People arrive one by one; each gets one of d days, every day
equally likely (chance 1/d), independently of everyone else, drawn with replacement. Let T be the
number of people who arrive until every one of the d days has been taken. Then the average of T
is d/d + d/(d-1) + ⋯ + d/1 = d H_d, where H_d = 1 + 1/2 + ⋯ + 1/d is the d-th harmonic number.
(T is counted in ℕ∞, with value ∞ if the set is never completed.) -/
theorem coupon_collector_expected_wait
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (d : ℕ) (X : ℕ → Ω → Fin d) (hmeas : ∀ i, Measurable (X i))
    (hind : iIndepFun X μ)
    (hunif : ∀ i (k : Fin d), μ.real {ω | X i ω = k} = 1 / d) :
    let T : Ω → ℕ∞ := fun ω => ⨅ (m : ℕ) (_ : ∀ k : Fin d, ∃ i < m, X i ω = k), (m : ℕ∞)
    ∫⁻ ω, ((T ω : ℕ∞) : ℝ≥0∞) ∂μ = ENNReal.ofReal ((d : ℝ) * (harmonic d : ℝ)) := by
  intro T
  rcases Nat.eq_zero_or_pos d with hd | hd
  · subst hd
    obtain ⟨ω⟩ : Nonempty Ω := nonempty_of_isProbabilityMeasure μ
    exact (X 0 ω).elim0
  let C : ℕ → Set Ω := fun m => {ω | ¬ ∀ k : Fin d, ∃ i < m, X i ω = k}
  have hC : ∀ m, C m = {ω | (fun i : Fin m => X i ω) ∈
      Finset.univ.filter (fun f : Fin m → Fin d => ¬ Function.Surjective f)} := by
    intro m
    ext ω
    simp only [C, Set.mem_ofPred_eq, Finset.mem_filter, Finset.mem_univ, true_and]
    unfold Function.Surjective
    refine not_congr (forall_congr' (fun k => ?_))
    exact ⟨fun ⟨i, hi, h⟩ => ⟨⟨i, hi⟩, h⟩, fun ⟨a, h⟩ => ⟨a, a.2, h⟩⟩
  have hCmeas : ∀ m, MeasurableSet (C m) := by
    intro m
    rw [hC]
    exact (measurable_pi_iff.mpr (fun i : Fin m => hmeas (i : ℕ))) (Finset.measurableSet _)
  have hprob : ∀ m, μ.real (C m) = bcR d m := by
    intro m
    rw [hC, bc_prob_vec_mem μ d (fun i : Fin m => X i) (fun i => hmeas i)
      (hind.precomp Fin.val_injective) (fun i k => hunif i k)]
    simp [bcR]
  have hTsum : ∀ ω, ((T ω : ℕ∞) : ℝ≥0∞) = ∑' m, (C m).indicator 1 ω := by
    intro ω
    rw [bc_enat_tsum]
    congr 1
    ext m
    by_cases h : ¬ ∀ k : Fin d, ∃ i < m, X i ω = k
    · have h' : (m : ℕ∞) < T ω := (bc_lt_iInf X ω m).mpr h
      simp only [h', ↓reduceIte]
      rw [Set.indicator_of_mem (show ω ∈ C m from h)]
      rfl
    · have h' : ¬ (m : ℕ∞) < T ω := fun hh => h ((bc_lt_iInf X ω m).mp hh)
      simp only [h', ↓reduceIte]
      rw [Set.indicator_of_notMem (show ω ∉ C m from h)]
  calc ∫⁻ ω, ((T ω : ℕ∞) : ℝ≥0∞) ∂μ = ∫⁻ ω, ∑' m, (C m).indicator 1 ω ∂μ :=
        lintegral_congr (fun ω => hTsum ω)
    _ = ∑' m, ∫⁻ ω, (C m).indicator 1 ω ∂μ :=
        lintegral_tsum (fun m => (measurable_const.indicator (hCmeas m)).aemeasurable)
    _ = ∑' m, ENNReal.ofReal (bcR d m) := by
        congr 1
        ext m
        rw [lintegral_indicator_one (hCmeas m), ← hprob, ofReal_measureReal]
    _ = ENNReal.ofReal (∑' m, bcR d m) :=
        (ENNReal.ofReal_tsum_of_nonneg (bcR_nonneg d) (bc_hasSum d hd).summable).symm
    _ = _ := by rw [(bc_hasSum d hd).tsum_eq]

/-- Why 23: each factor 1 - i/d is at most e^(-i/d), so the no-match chance is at most
e^(-n(n-1)/(2d)), where n(n-1)/2 is the number of pairs. So the approximation
1 - e^(-n(n-1)/(2d)) never overstates the chance of a shared day. -/
theorem birthday_approx_understates_match
    (n d : ℕ) :
    1 - Real.exp (-((n : ℝ) * (n - 1)) / (2 * d))
      ≤ 1 - ∏ i ∈ Finset.range n, (1 - (i : ℝ) / d) := by
  rcases Nat.eq_zero_or_pos d with hd0 | hd0
  · subst hd0; simp
  rcases le_or_gt n d with h | h
  · have hsum : ∑ i ∈ Finset.range n, (-(i : ℝ) / d) = -((n : ℝ) * (n - 1)) / (2 * d) := by
      rw [← Finset.sum_div, Finset.sum_neg_distrib]
      have := Finset.sum_range_id_mul_two n
      have h2 : (∑ i ∈ Finset.range n, (i : ℝ)) * 2 = (n : ℝ) * (n - 1) := by
        rcases Nat.eq_zero_or_pos n with hn | hn
        · subst hn; simp
        · have := congrArg (fun x : ℕ => (x : ℝ)) this
          push_cast [Nat.cast_sub (show 1 ≤ n from hn)] at this
          linarith
      rcases Nat.eq_zero_or_pos d with hd | hd
      · subst hd; simp
      · field_simp
        linarith
    have : ∏ i ∈ Finset.range n, (1 - (i : ℝ) / d) ≤ Real.exp (-((n : ℝ) * (n - 1)) / (2 * d)) := by
      rw [← hsum, Real.exp_sum]
      apply Finset.prod_le_prod₀
      · intro i hi
        have hi' : i < n := Finset.mem_range.mp hi
        rcases Nat.eq_zero_or_pos d with hd | hd
        · subst hd; simp
        · rw [sub_nonneg, div_le_one (by exact_mod_cast hd)]
          exact_mod_cast (hi'.trans_le h).le
      · intro i _
        have := Real.add_one_le_exp (-(i : ℝ) / d)
        linarith [show -(i : ℝ) / d + 1 = 1 - (i : ℝ) / d by ring]
    linarith
  · have hd : 0 < d := hd0
    have h0 : ∏ i ∈ Finset.range n, (1 - (i : ℝ) / d) = 0 := by
      apply Finset.prod_eq_zero (Finset.mem_range.mpr h)
      have : (d : ℝ) ≠ 0 := by exact_mod_cast hd.ne'
      rw [div_self this, sub_self]
    rw [h0]
    linarith [Real.exp_pos (-((n : ℝ) * (n - 1)) / (2 * d))]

-- Twenty-three people make 23 × 22 / 2 = 253 pairs.
example : 23 * 22 / 2 = 253 := by norm_num
-- With 365 days, 22 people fall just short of a one-half match chance and 23 people pass it.
example : (1 / 2 : ℚ) < ∏ i ∈ Finset.range 22, (1 - (i : ℚ) / 365) := by
  norm_num [Finset.prod_range_succ]
example : ∏ i ∈ Finset.range 23, (1 - (i : ℚ) / 365) < 1 / 2 := by
  norm_num [Finset.prod_range_succ]
-- Birth months: 12 equally likely months and 4 people give 12^4 = 20736 lists,
-- of which 12 × 11 × 10 × 9 = 11880 have no repeat.
example : 12 ^ 4 = 20736 ∧ 12 * 11 * 10 * 9 = 11880 := by norm_num
-- So the match chance for 4 people is 1 - 11880/20736 = 41/96.
example : 1 - ∏ i ∈ Finset.range 4, (1 - (i : ℚ) / 12) = 41 / 96 := by
  norm_num [Finset.prod_range_succ]
-- With 12 months, 5 is the first number of people whose match chance passes one half.
example : (1 / 2 : ℚ) < ∏ i ∈ Finset.range 4, (1 - (i : ℚ) / 12) ∧
    ∏ i ∈ Finset.range 5, (1 - (i : ℚ) / 12) < 1 / 2 := by
  norm_num [Finset.prod_range_succ]
-- Naive mistake: waiting 365 for each of the 365 days gives 365 × 365 = 133225.
example : 365 * 365 = 133225 := by norm_num
-- A die, all six faces: E[T] = 6 H_6 = 147/10.
example : (6 : ℚ) * harmonic 6 = 147 / 10 := by
  norm_num [harmonic, Finset.sum_range_succ]

#print axioms birthday_no_shared_day_prob
#print axioms coupon_collector_expected_wait
#print axioms birthday_approx_understates_match
