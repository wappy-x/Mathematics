-- Ergodicity and mixing: in an ergodic map on a probability space the mean return time to a set A of positive measure is 1/μ(A), every mixing map is ergodic, and a turn of the circle is ergodic exactly when its size is irrational but is never mixing.
import Mathlib.Dynamics.Ergodic.AddCircleAdd
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Data.Rat.Floor
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.NumberTheory.DiophantineApproximation.Basic

open MeasureTheory Filter Topology
open scoped ENNReal

variable {X : Type*} [MeasurableSpace X]

/-- The return time to `A`: the first step `n ≥ 1` at which the start `x` is back in `A`,
`r_A(x) = min {n ≥ 1 : Tⁿ x ∈ A}`. It is `∞` for a start that never comes back. -/
noncomputable def returnTime (T : X → X) (A : Set X) (x : X) : ℝ≥0∞ :=
  ⨅ (n : ℕ) (_ : 1 ≤ n ∧ T^[n] x ∈ A), (n : ℝ≥0∞)

/-- `T` is mixing for `μ`: it keeps `μ`, and for all measurable sets `A` and `B` the overlap
`μ(T⁻ⁿA ∩ B)` of the starts in `B` that land in `A` after `n` steps tends to `μ(A) μ(B)`. -/
def IsMixing (T : X → X) (μ : Measure X) : Prop :=
  MeasurePreserving T μ μ ∧
    ∀ A B : Set X, MeasurableSet A → MeasurableSet B →
      Tendsto (fun n : ℕ => μ (T^[n] ⁻¹' A ∩ B)) atTop (𝓝 (μ A * μ B))

/-- Kac's lemma. Let `T` keep the probability measure `μ` (total measure 1) and be ergodic,
and let `A` be a measurable set with `μ(A) > 0`. Then the mean return time to `A`, averaged
over the starts in `A`, is one over the measure of `A`:
`(1/μ(A)) ∫_A r_A dμ = 1/μ(A)`. -/
theorem kac_mean_return_time_eq_inv_measure {μ : Measure X} [IsProbabilityMeasure μ]
    {T : X → X} (hT : Ergodic T μ) {A : Set X} (hA : MeasurableSet A) (hA0 : 0 < μ A) :
    (μ A)⁻¹ * ∫⁻ x in A, returnTime T A x ∂μ = (μ A)⁻¹ := by
  -- `S n`: the starts that stay out of `A` at steps `1, …, n`.
  obtain ⟨S, hSmem, hSmeas⟩ : ∃ S : ℕ → Set X,
      (∀ n x, x ∈ S n ↔ ∀ k : Fin n, T^[(k : ℕ) + 1] x ∉ A) ∧ ∀ n, MeasurableSet (S n) :=
    ⟨fun n => ⋂ k : Fin n, T^[(k : ℕ) + 1] ⁻¹' Aᶜ, fun n x => by simp,
      fun n => MeasurableSet.iInter fun k => (hT.measurable.iterate _) hA.compl⟩
  -- pointwise: the return time is the number of `n` with `x ∈ S n`
  have hpt : ∀ x, returnTime T A x = ∑' n, (S n).indicator 1 x := by
    intro x
    by_cases h : ∃ m, 1 ≤ m ∧ T^[m] x ∈ A
    · classical
      set m := Nat.find h with hm
      have hr : returnTime T A x = m := by
        apply le_antisymm
        · exact iInf₂_le m (Nat.find_spec h)
        · exact le_iInf₂ fun n hn => Nat.cast_le.mpr (Nat.find_min' h hn)
      have hmem : ∀ n, x ∈ S n ↔ n < m := by
        intro n
        rw [hSmem]
        constructor
        · intro hx
          by_contra hle
          push Not at hle
          have hm1 : 1 ≤ m := (Nat.find_spec h).1
          have := hx ⟨m - 1, by omega⟩
          simp only at this
          rw [Nat.sub_add_cancel hm1] at this
          exact this (Nat.find_spec h).2
        · intro hn k hk
          have hlt : (k : ℕ) + 1 < m := by have := k.2; omega
          exact Nat.find_min h hlt ⟨by omega, hk⟩
      rw [hr, tsum_eq_sum (s := Finset.range m)]
      · rw [Finset.sum_congr rfl (g := fun _ => (1 : ℝ≥0∞))]
        · simp
        · intro n hn
          rw [Finset.mem_range] at hn
          simp [(hmem n).2 hn]
      · intro n hn
        rw [Finset.mem_range] at hn
        simp [show x ∉ S n from fun hx => hn ((hmem n).1 hx)]
    · push Not at h
      have hr : returnTime T A x = ⊤ := by
        simp only [returnTime, iInf_eq_top]
        intro n hn
        exact absurd hn.2 (h n hn.1)
      have hmem : ∀ n, x ∈ S n := fun n => (hSmem n x).2 fun k => h _ (by omega)
      rw [hr]
      simp only [hmem, Set.indicator_of_mem, Pi.one_apply]
      exact (ENNReal.tsum_const_eq_top_of_ne_zero one_ne_zero).symm
  -- the integral as a sum
  have hint : ∫⁻ x in A, returnTime T A x ∂μ = ∑' n, μ (S n ∩ A) := by
    simp_rw [hpt]
    rw [lintegral_tsum fun n => (measurable_one.indicator (hSmeas n)).aemeasurable]
    congr 1
    funext n
    rw [lintegral_indicator_one (hSmeas n), Measure.restrict_apply (hSmeas n)]
  -- one step of the telescoping sum
  have hstep : ∀ n, μ (S n) = μ (S n ∩ A) + μ (S (n + 1)) := by
    intro n
    have hset : S (n + 1) = T ⁻¹' (S n \ A) := by
      ext x
      rw [hSmem, Set.mem_preimage, Set.mem_sdiff, hSmem, Fin.forall_fin_succ]
      simp only [Fin.val_zero, zero_add, Fin.val_succ,
        Function.iterate_succ_apply]
      tauto
    rw [hset, hT.measure_preimage ((hSmeas n).diff hA).nullMeasurableSet,
      measure_inter_add_sdiff _ hA]
  have hsum : ∀ N, ∑ n ∈ Finset.range N, μ (S n ∩ A) + μ (S N) = 1 := by
    intro N
    induction N with
    | zero =>
      have : S 0 = Set.univ := by
        ext x; simp [hSmem]
      simp [this]
    | succ N ih =>
      rw [Finset.sum_range_succ, add_assoc, ← hstep, ih]
  -- the starts that never come back to `A` form a null set
  have hanti : Antitone S := by
    intro m n hmn x hx
    rw [hSmem] at hx ⊢
    intro k
    exact hx ⟨k, by omega⟩
  have hnull : μ (⋂ n, S n) = 0 := by
    set C : Set X := {x | ∀ k : ℕ, T^[k + 1] x ∉ A} with hC
    have hCeq : C = ⋂ n, S n := by
      ext x
      simp only [hC, Set.mem_ofPred_eq, Set.mem_iInter, hSmem]
      constructor
      · intro hx n k; exact hx k
      · intro hx k; exact hx (k + 1) ⟨k, by omega⟩
    have hCmeas : MeasurableSet C := by rw [hCeq]; exact MeasurableSet.iInter hSmeas
    have hCsub : C ⊆ T ⁻¹' C := by
      intro x hx k
      have := hx (k + 1)
      rwa [Function.iterate_succ_apply] at this
    rw [← hCeq]
    rcases hT.ae_empty_or_univ_of_ae_le_preimage hCmeas.nullMeasurableSet
        hCsub.eventuallyLE with h | h
    · exact ae_eq_empty.1 h
    · exfalso
      rw [ae_eq_univ] at h
      have hsub : T ⁻¹' A ⊆ Cᶜ := by
        intro x hx hxC
        exact hxC 0 (by simpa using hx)
      have := measure_mono (μ := μ) hsub
      rw [h, hT.measure_preimage hA.nullMeasurableSet] at this
      exact absurd (le_zero_iff.1 this) hA0.ne'
  have htend : Tendsto (fun N => μ (S N)) atTop (𝓝 0) := by
    rw [← hnull]
    exact tendsto_measure_iInter_atTop (fun n => (hSmeas n).nullMeasurableSet) hanti
      ⟨0, measure_ne_top μ _⟩
  have hone : ∑' n, μ (S n ∩ A) = 1 := by
    apply le_antisymm
    · refine ENNReal.tsum_le_of_sum_range_le fun N => ?_
      rw [← hsum N]
      exact le_self_add
    · have h2 : Tendsto (fun N => (∑' n, μ (S n ∩ A)) + μ (S N)) atTop
          (𝓝 ((∑' n, μ (S n ∩ A)) + 0)) := tendsto_const_nhds.add htend
      rw [add_zero] at h2
      refine ge_of_tendsto' h2 fun N => ?_
      rw [← hsum N]
      gcongr
      exact sum_le_tsum _
  rw [hint, hone, mul_one]

/-- Mixing implies ergodic. If `T` keeps the probability measure `μ` and is mixing, then
every set that `T` keeps to itself has measure 0 or 1: `T` is ergodic. -/
theorem ergodic_of_mixing {μ : Measure X} [IsProbabilityMeasure μ] {T : X → X}
    (hT : IsMixing T μ) : Ergodic T μ := by
  refine Ergodic.of_preimage_eq hT.1 fun s hs hinv => ?_
  have hit : ∀ n : ℕ, T^[n] ⁻¹' s = s := by
    intro n
    induction n with
    | zero => rfl
    | succ n ih => rw [Function.iterate_succ, Set.preimage_comp, ih, hinv]
  have h := hT.2 s s hs hs
  simp only [hit, Set.inter_self] at h
  have heq : μ s = μ s * μ s := tendsto_nhds_unique tendsto_const_nhds h
  rw [eventuallyEmptyOrUniv_iff', ae_eq_empty, ae_eq_univ]
  by_cases h0 : μ s = 0
  · exact Or.inl h0
  · right
    have h1 : μ s = 1 := by
      have := (ENNReal.mul_right_inj h0 (measure_ne_top μ s) (b := 1) (c := μ s)).1
        (by rw [mul_one]; exact heq)
      exact this.symm
    rwa [prob_compl_eq_zero_iff hs]


/-- Turns of the strip. On the circle `ℝ/ℤ` (the strip `[0, 1)` with its ends joined) with
length, the turn `x ↦ x + α` is ergodic exactly when `α` is irrational (so a rational turn,
such as by 1/2, is not ergodic), and no turn, rational or not, is mixing. -/
theorem rotation_ergodic_iff_irrational_and_never_mixing (α : ℝ) :
    (Ergodic (fun x : UnitAddCircle => x + (α : UnitAddCircle)) volume ↔ Irrational α) ∧
      ¬ IsMixing (fun x : UnitAddCircle => x + (α : UnitAddCircle)) volume := by
  constructor
  · rw [AddCircle.ergodic_add_right, ← AddCircle.denseRange_zsmul_iff,
      AddCircle.denseRange_zsmul_coe_iff, div_one]
  · rintro ⟨-, hmix⟩
    set A : Set UnitAddCircle := Metric.closedBall 0 (1 / 4) with hAdef
    have hA : MeasurableSet A := measurableSet_closedBall
    have hvol : ∀ r : ℝ, volume (Metric.closedBall (0 : UnitAddCircle) r) =
        ENNReal.ofReal (min 1 (2 * r)) := fun r => AddCircle.volume_closedBall (T := 1) r
    have h := hmix A A hA hA
    rw [hAdef, hvol] at h
    have hlt : ENNReal.ofReal (min 1 (2 * (1 / 4))) * ENNReal.ofReal (min 1 (2 * (1 / 4)))
        < ENNReal.ofReal (3 / 8) := by
      rw [← ENNReal.ofReal_mul (by norm_num)]
      exact (ENNReal.ofReal_lt_ofReal_iff (by norm_num)).2 (by norm_num)
    obtain ⟨N, hN⟩ := eventually_atTop.1 (h.eventually (gt_mem_nhds hlt))
    obtain ⟨k, hk0, -, hk⟩ :=
      Real.exists_nat_abs_mul_sub_round_le α (n := 16 * (N + 1)) (by positivity)
    have hy : ‖((k * α : ℝ) : UnitAddCircle)‖ ≤ 1 / (16 * (N + 1) + 1) := by
      rw [UnitAddCircle.norm_eq]; push_cast at hk; exact hk
    set n := (N + 1) * k with hn
    have hnN : N ≤ n := by
      rw [hn]; nlinarith
    have hsmall : ‖n • (α : UnitAddCircle)‖ ≤ 1 / 16 := by
      have : n • (α : UnitAddCircle) = (N + 1) • ((k * α : ℝ) : UnitAddCircle) := by
        rw [hn, mul_nsmul', ← AddCircle.coe_nsmul (n := k), nsmul_eq_mul]
      rw [this]
      refine norm_nsmul_le.trans ?_
      have hpos : (0 : ℝ) < 16 * (N + 1) + 1 := by positivity
      calc ((N + 1 : ℕ) : ℝ) * ‖((k * α : ℝ) : UnitAddCircle)‖
          ≤ ((N + 1 : ℕ) : ℝ) * (1 / (16 * (N + 1) + 1)) := by gcongr
        _ ≤ 1 / 16 := by
          push_cast
          rw [mul_one_div, div_le_div_iff₀ hpos (by norm_num)]
          nlinarith
    have hsub : Metric.closedBall (0 : UnitAddCircle) (3 / 16) ⊆
        (fun x : UnitAddCircle => x + (α : UnitAddCircle))^[n] ⁻¹'
          Metric.closedBall 0 (1 / 4) ∩ Metric.closedBall 0 (1 / 4) := by
      intro x hx
      rw [mem_closedBall_zero_iff] at hx
      refine ⟨?_, ?_⟩
      · rw [Set.mem_preimage, add_right_iterate_apply, mem_closedBall_zero_iff]
        calc ‖x + n • (α : UnitAddCircle)‖ ≤ ‖x‖ + ‖n • (α : UnitAddCircle)‖ := norm_add_le _ _
          _ ≤ 1 / 4 := by linarith
      · rw [mem_closedBall_zero_iff]; linarith
    have h1 := measure_mono (μ := volume) hsub
    rw [hvol] at h1
    have h2 := hN n hnN
    have h3 : ENNReal.ofReal (min 1 (2 * (3 / 16))) = ENNReal.ofReal (3 / 8) := by
      norm_num
    rw [h3] at h1
    exact absurd (h1.trans_lt h2) (lt_irrefl _)

/-! The card's whole-number worked examples, checked exactly. -/

-- The half-metre turn on quarter cells: the starts that land in quarters {0, 2} after one
-- turn are quarters {0, 2} again, so A = [0, 1/4) ∪ [1/2, 3/4) is invariant, m(A) = 2/4.
example : (List.range 4).filter (fun c => (c + 2) % 4 = 0 ∨ (c + 2) % 4 = 2) = [0, 2] := by
  decide

-- The doubler swaps 1/3 and 2/3: D(1/3) = 2/3 and D(2/3) = 1/3.
example : Int.fract (2 * (1 / 3 : ℚ)) = 2 / 3 ∧ Int.fract (2 * (2 / 3 : ℚ)) = 1 / 3 := by
  norm_num [Int.fract]

-- Doubling with A = B = [0, 1/2), counted on the grid j/256: for every n from 1 to 7,
-- exactly 64 of the 256 grid points start in B and land in A after n steps, so the
-- overlap is 64/256 = 1/4 = m(A) m(B).
example : ∀ n ∈ Finset.Icc 1 7,
    ((Finset.range 256).filter (fun j => (j * 2 ^ n) % 256 < 128 ∧ j < 128)).card = 64 := by
  decide

-- The continued-fraction denominators of √2 − 1 follow q_{n+1} = 2 q_n + q_{n-1}.
example : [1, 2, 5, 12, 29, 70, 169, 408, 985] =
    [1, 2, 2 * 2 + 1, 2 * 5 + 2, 2 * 12 + 5, 2 * 29 + 12, 2 * 70 + 29, 2 * 169 + 70,
      2 * 408 + 169] := by
  decide

-- Kac for the doubler on [0, 1/2): return at step n has chance 1/2ⁿ, and the partial
-- sums of n/2ⁿ head to the mean 2 = 1/m(A); up to n = 10 the sum is 2 − 12/2¹⁰.
example : ∑ n ∈ Finset.Icc (1 : ℕ) 10, (n : ℚ) / 2 ^ n = 2 - 12 / 2 ^ 10 := by
  norm_num [Finset.sum_Icc_succ_top]

-- Kac for the turner on [0, 1/2): return times 1, 2, 3 on lengths 1/2 − α, 2α − 1/2,
-- 1/2 − α give mean 2 for any α (the card uses α = √2 − 1).
example (α : ℝ) :
    (1 * (1 / 2 - α) + 2 * (2 * α - 1 / 2) + 3 * (1 / 2 - α)) / (1 / 2) = 2 := by
  ring

-- Mistake 3: for the doubler and A = [0, 1/4), the wait from a random start is
-- (1 + 1/2)/(1 − 3/4) − 1 = 5, not 1/m(A) = 4.
example : ((1 : ℚ) + 1 / 2) / (1 - 3 / 4) - 1 = 5 ∧ (1 : ℚ) / (1 / 4) = 4 := by
  norm_num

#print axioms kac_mean_return_time_eq_inv_measure
#print axioms ergodic_of_mixing
#print axioms rotation_ergodic_iff_irrational_and_never_mixing
