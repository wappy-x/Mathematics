-- Lebesgue measure: outer length kept on the sets that split every set cleanly measures every Borel set, squeezes every set it measures between an open set outside and a closed set inside with as little slack as wished, adds only pieces of null sets to the Borel sets, and is the only measure on Borel sets giving each interval (a, b] the length b - a.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory Set
open scoped ENNReal

/-- The card's outer measure `λ*`, from the Outer measure card: over every list `(c k, d k)` of
open intervals whose union contains `A`, take the total length `∑ (d k - c k)`, and take the
infimum of those totals. An interval with `d k ≤ c k` is empty and has length 0. -/
noncomputable def lambdaStar (A : Set ℝ) : ℝ≥0∞ :=
  ⨅ (c : ℕ → ℝ) (d : ℕ → ℝ) (_ : A ⊆ ⋃ k, Ioo (c k) (d k)), ∑' k, ENNReal.ofReal (d k - c k)

/-- The card's Lebesgue sets `𝓛`: the sets `E` that split every test set `A` cleanly,
`λ*(A) = λ*(A ∩ E) + λ*(A \ E)`. Lebesgue measure `λ` is `λ*` kept on these sets. -/
def IsLebesgueSet (E : Set ℝ) : Prop :=
  ∀ A : Set ℝ, lambdaStar A = lambdaStar (A ∩ E) + lambdaStar (A \ E)

theorem lambdaStar_eq_volume (A : Set ℝ) : lambdaStar A = volume A := by
  apply le_antisymm
  · rw [Real.volume_val, StieltjesFunction.measure]
    show _ ≤ StieltjesFunction.id.outer A
    rw [StieltjesFunction.outer, OuterMeasure.ofFunction_apply]
    refine le_iInf₂ fun t ht => ?_
    refine ENNReal.le_of_forall_pos_le_add fun ε hε hfin => ?_
    obtain ⟨δ, hδpos, hδ⟩ := ENNReal.exists_pos_sum_of_countable
      (ε := ((ε / 2 : NNReal) : ℝ≥0∞)) (by simpa using hε.ne') ℕ
    have key : ∀ n, ∃ a b : ℝ, t n ⊆ Ioc a b ∧
        ENNReal.ofReal (b - a) < StieltjesFunction.id.length (t n) + δ n := by
      intro n
      have hl : StieltjesFunction.id.length (t n) < StieltjesFunction.id.length (t n) + δ n :=
        ENNReal.lt_add_right (ne_top_of_le_ne_top hfin.ne (le_tsum (fun n => StieltjesFunction.id.length (t n)) n))
          (by simpa using (hδpos n).ne')
      conv at hl => lhs; rw [StieltjesFunction.length_eq]
      simp only [iInf_lt_iff] at hl
      obtain ⟨a, b, h1, h2⟩ := hl
      exact ⟨a, b, fun x hx => h1 ⟨hx, fun h => not_isBot x h⟩, by simpa using h2⟩
    choose a b hab hlen using key
    calc lambdaStar A ≤ ∑' n, ENNReal.ofReal (b n + δ n - a n) := by
          refine iInf_le_of_le a (iInf_le_of_le (fun n => b n + δ n) (iInf_le_of_le ?_ le_rfl))
          intro x hx
          obtain ⟨n, hn⟩ := mem_iUnion.1 (ht hx)
          have := hab n hn
          have hpos : (0:ℝ) < δ n := hδpos n
          exact mem_iUnion.2 ⟨n, this.1, by linarith [this.2]⟩
      _ ≤ ∑' n, (StieltjesFunction.id.length (t n) + δ n + δ n) := by
          refine tsum_le_tsum fun n => ?_
          calc ENNReal.ofReal (b n + δ n - a n) = ENNReal.ofReal ((b n - a n) + δ n) := by ring_nf
            _ ≤ ENNReal.ofReal (b n - a n) + ENNReal.ofReal (δ n) := ENNReal.ofReal_add_le
            _ ≤ _ := by rw [ENNReal.ofReal_coe_nnreal]; gcongr; exact (hlen n).le
      _ = ∑' n, StieltjesFunction.id.length (t n) + (∑' n, (δ n : ℝ≥0∞) + ∑' n, (δ n : ℝ≥0∞)) := by
          rw [tsum_add, tsum_add, add_assoc]
      _ ≤ ∑' n, StieltjesFunction.id.length (t n) + ε := by
          gcongr
          calc ∑' n, (δ n : ℝ≥0∞) + ∑' n, (δ n : ℝ≥0∞)
              ≤ ((ε / 2 : NNReal) : ℝ≥0∞) + ((ε / 2 : NNReal) : ℝ≥0∞) := by gcongr
            _ = ε := by rw [← ENNReal.coe_add, add_halves]
  · refine le_iInf fun c => le_iInf fun d => le_iInf fun h => ?_
    calc volume A ≤ volume (⋃ k, Ioo (c k) (d k)) := measure_mono h
      _ ≤ ∑' k, volume (Ioo (c k) (d k)) := measure_iUnion_le _
      _ = _ := by simp [Real.volume_Ioo]

#print axioms lambdaStar_eq_volume

theorem exists_isOpen_superset_sdiff_lt (S : Set ℝ) (hS : MeasurableSet S) (ε : ℝ≥0∞)
    (hε : ε ≠ 0) : ∃ G : Set ℝ, IsOpen G ∧ S ⊆ G ∧ volume (G \ S) < ε := by
  obtain ⟨δ, hδpos, hδ⟩ := ENNReal.exists_pos_sum_of_countable hε ℕ
  have : ∀ n : ℕ, ∃ U, U ⊇ S ∩ Ioo (-(n : ℝ)) n ∧ IsOpen U ∧ volume U < ∞ ∧
      volume (U \ (S ∩ Ioo (-(n : ℝ)) n)) < δ n := fun n =>
    (hS.inter measurableSet_Ioo).exists_isOpen_sdiff_lt
      (ne_top_of_le_ne_top (by simp [Real.volume_Ioo]) (measure_mono inter_subset_right))
      (by simpa using (hδpos n).ne')
  choose U hU hUo _ hUd using this
  refine ⟨⋃ n, U n, isOpen_iUnion hUo, fun x hx => ?_, ?_⟩
  · obtain ⟨n, hn⟩ := exists_nat_gt |x|
    exact mem_iUnion.2 ⟨n, hU n ⟨hx, abs_lt.1 hn⟩⟩
  · calc volume ((⋃ n, U n) \ S) ≤ volume (⋃ n, U n \ (S ∩ Ioo (-(n : ℝ)) n)) := by
          refine measure_mono ?_
          rintro x ⟨hx, hxS⟩
          obtain ⟨n, hn⟩ := mem_iUnion.1 hx
          exact mem_iUnion.2 ⟨n, hn, fun h => hxS h.1⟩
      _ ≤ ∑' n, volume (U n \ (S ∩ Ioo (-(n : ℝ)) n)) := measure_iUnion_le _
      _ ≤ ∑' n, (δ n : ℝ≥0∞) := tsum_le_tsum fun n => (hUd n).le
      _ < ε := hδ

#print axioms exists_isOpen_superset_sdiff_lt

theorem isLebesgueSet_sandwich (E : Set ℝ) (hE : IsLebesgueSet E) :
    ∃ M H : Set ℝ, MeasurableSet M ∧ MeasurableSet H ∧ M ⊆ E ∧ E ⊆ H ∧
      volume (H \ M) = 0 := by
  set H := toMeasurable volume E with hHdef
  set H' := toMeasurable volume Eᶜ with hH'def
  refine ⟨H'ᶜ, H, (measurableSet_toMeasurable _ _).compl, measurableSet_toMeasurable _ _,
    ?_, subset_toMeasurable _ _, ?_⟩
  · intro x hx
    by_contra h
    exact hx (subset_toMeasurable _ _ h)
  · rw [sdiff_compl]
    have hn : ∀ n : ℕ, volume (H ∩ H' ∩ Ioo (-(n : ℝ)) n) = 0 := by
      intro n
      set D := H ∩ H' ∩ Ioo (-(n : ℝ)) n with hDdef
      have hDm : MeasurableSet D :=
        ((measurableSet_toMeasurable _ _).inter (measurableSet_toMeasurable _ _)).inter
          measurableSet_Ioo
      have hfin : volume D ≠ ∞ :=
        ne_top_of_le_ne_top (by simp [Real.volume_Ioo]) (measure_mono inter_subset_right)
      have h1 : volume (D ∩ E) = volume D := by
        rw [inter_comm, ← Measure.measure_toMeasurable_inter_of_sfinite hDm E]
        congr 1
        exact inter_eq_right.2 (fun x hx => hx.1.1)
      have h2 : volume (D \ E) = volume D := by
        rw [sdiff_eq, inter_comm, ← Measure.measure_toMeasurable_inter_of_sfinite hDm Eᶜ]
        congr 1
        exact inter_eq_right.2 (fun x hx => hx.1.2)
      have h3 := hE D
      rw [lambdaStar_eq_volume, lambdaStar_eq_volume, lambdaStar_eq_volume, h1, h2] at h3
      have h4 : volume D + volume D = volume D + 0 := by rw [add_zero]; exact h3.symm
      exact (ENNReal.add_right_inj hfin).1 h4
    refine measure_mono_null (fun x hx => ?_) (measure_iUnion_null hn)
    obtain ⟨n, hn⟩ := exists_nat_gt |x|
    exact mem_iUnion.2 ⟨n, hx, abs_lt.1 hn⟩

#print axioms isLebesgueSet_sandwich

theorem isLebesgueSet_of_sandwich (E M H : Set ℝ) (hM : MeasurableSet M) (hME : M ⊆ E)
    (hEH : E ⊆ H) (hnull : volume (H \ M) = 0) : IsLebesgueSet E := by
  intro A
  rw [lambdaStar_eq_volume, lambdaStar_eq_volume, lambdaStar_eq_volume]
  refine le_antisymm (measure_le_inter_add_sdiff _ _ _) ?_
  calc volume (A ∩ E) + volume (A \ E) ≤ volume (A ∩ M) + volume (A \ M) := by
        gcongr ?_ + ?_
        · calc volume (A ∩ E) ≤ volume (A ∩ M ∪ H \ M) := by
                refine measure_mono fun x hx => ?_
                by_cases hxM : x ∈ M
                · exact Or.inl ⟨hx.1, hxM⟩
                · exact Or.inr ⟨hEH hx.2, hxM⟩
            _ ≤ volume (A ∩ M) + volume (H \ M) := measure_union_le _ _
            _ = volume (A ∩ M) := by rw [hnull, add_zero]
        · exact measure_mono (sdiff_subset_sdiff_right hME)
    _ = volume A := measure_inter_add_sdiff A hM

#print axioms isLebesgueSet_of_sandwich

/-- Regularity, the squeeze (theorem (ii)): for every Lebesgue set `E` and every `ε > 0` there is
an open set `G` holding `E` whose part outside `E` has length below `ε`, and a closed set `K`
inside `E` leaving a part of `E` of length below `ε`. -/
theorem lebesgue_set_squeezed_between_open_and_closed (E : Set ℝ) (hE : IsLebesgueSet E)
    (ε : ℝ) (hε : 0 < ε) :
    (∃ G : Set ℝ, IsOpen G ∧ E ⊆ G ∧ lambdaStar (G \ E) < ENNReal.ofReal ε) ∧
    (∃ K : Set ℝ, IsClosed K ∧ K ⊆ E ∧ lambdaStar (E \ K) < ENNReal.ofReal ε) := by
  obtain ⟨M, H, hM, hH, hME, hEH, hnull⟩ := isLebesgueSet_sandwich E hE
  have hε' : ENNReal.ofReal ε ≠ 0 := (ENNReal.ofReal_pos.2 hε).ne'
  constructor
  · obtain ⟨G, hGo, hHG, hG⟩ := exists_isOpen_superset_sdiff_lt H hH _ hε'
    refine ⟨G, hGo, hEH.trans hHG, ?_⟩
    rw [lambdaStar_eq_volume]
    calc volume (G \ E) ≤ volume (G \ H ∪ H \ M) := by
          refine measure_mono fun x hx => ?_
          by_cases hxH : x ∈ H
          · exact Or.inr ⟨hxH, fun h => hx.2 (hME h)⟩
          · exact Or.inl ⟨hx.1, hxH⟩
      _ ≤ volume (G \ H) + volume (H \ M) := measure_union_le _ _
      _ = volume (G \ H) := by rw [hnull, add_zero]
      _ < _ := hG
  · obtain ⟨G, hGo, hMG, hG⟩ := exists_isOpen_superset_sdiff_lt Mᶜ hM.compl _ hε'
    refine ⟨Gᶜ, hGo.isClosed_compl, fun x hx => hME ?_, ?_⟩
    · by_contra h
      exact hx (hMG h)
    rw [lambdaStar_eq_volume]
    calc volume (E \ Gᶜ) ≤ volume (G \ Mᶜ ∪ H \ M) := by
          refine measure_mono fun x hx => ?_
          have hxG : x ∈ G := not_not.1 hx.2
          by_cases hxM : x ∈ M
          · exact Or.inl ⟨hxG, fun h => h hxM⟩
          · exact Or.inr ⟨hEH hx.1, hxM⟩
      _ ≤ volume (G \ Mᶜ) + volume (H \ M) := measure_union_le _ _
      _ = volume (G \ Mᶜ) := by rw [hnull, add_zero]
      _ < _ := hG

/-- Theorems (i) and (iii): every Borel set is a Lebesgue set, and a set is a Lebesgue set exactly
when it is trapped between Borel sets `M ⊆ E ⊆ H` whose difference `H \ M` has length 0. (On the
real line `MeasurableSet` means Borel.) -/
theorem lebesgue_sets_are_borel_sets_up_to_null_sets :
    (∀ B : Set ℝ, MeasurableSet B → IsLebesgueSet B) ∧
    ∀ E : Set ℝ, IsLebesgueSet E ↔
      ∃ M H : Set ℝ, MeasurableSet M ∧ MeasurableSet H ∧ M ⊆ E ∧ E ⊆ H ∧
        lambdaStar (H \ M) = 0 := by
  refine ⟨fun B hB => isLebesgueSet_of_sandwich B B B hB subset_rfl subset_rfl (by simp),
    fun E => ⟨fun hE => ?_, ?_⟩⟩
  · obtain ⟨M, H, hM, hH, hME, hEH, hnull⟩ := isLebesgueSet_sandwich E hE
    exact ⟨M, H, hM, hH, hME, hEH, by rw [lambdaStar_eq_volume, hnull]⟩
  · rintro ⟨M, H, hM, -, hME, hEH, hnull⟩
    rw [lambdaStar_eq_volume] at hnull
    exact isLebesgueSet_of_sandwich E M H hM hME hEH hnull

/-- Theorems (i) and (iv): Lebesgue measure gives every interval `(a, b]` with `a < b` its length
`b - a`, and every measure `μ` on the Borel sets that does the same equals Lebesgue measure on
every Borel set. -/
theorem lebesgue_measure_unique_with_interval_lengths :
    (∀ a b : ℝ, a < b → lambdaStar (Ioc a b) = ENNReal.ofReal (b - a)) ∧
    ∀ μ : Measure ℝ, (∀ a b : ℝ, a < b → μ (Ioc a b) = ENNReal.ofReal (b - a)) →
      ∀ B : Set ℝ, MeasurableSet B → μ B = lambdaStar B := by
  refine ⟨fun a b _ => by rw [lambdaStar_eq_volume, Real.volume_Ioc], fun μ hμ B _ => ?_⟩
  have h : μ = volume := Measure.ext_of_Ioc' μ volume
    (fun a b h => by rw [hμ a b h]; exact ENNReal.ofReal_ne_top)
    (fun a b h => by rw [hμ a b h, Real.volume_Ioc])
  rw [h, lambdaStar_eq_volume]

/- The card's worked numbers. Lengths on the 1 km path are in whole millimetres or micrometres. -/

-- The open set G = (-0.0005, 1.0005) km is 1.001 km: in mm, 1000500 - (-500) = 1001000.
example : (1000500 : ℤ) - (-500) = 1001000 := by norm_num

-- G beyond the path: the two overhangs, 0.0005 + 0.0005 = 0.001 km, in mm.
example : (500 : ℕ) + 500 = 1000 := by norm_num

-- Ends trimmed: [0.00025, 0.99975] km is 0.9995 km; in mm, 999750 - 250 = 999500.
example : (999750 : ℕ) - 250 = 999500 := by norm_num

-- The closed set K is at least 0.9995 - 0.0005 = 0.999 km, in mm.
example : (999500 : ℕ) - 500 = 999000 := by norm_num

-- Gap round pothole k is 0.0005 km × 2^(-k): 25, 12.5, 6.25, 3.125 cm, in micrometres.
example : 500000 / 2 ^ 1 = 250000 ∧ 500000 / 2 ^ 2 = 125000 ∧
    500000 / 2 ^ 3 = 62500 ∧ 500000 / 2 ^ 4 = 31250 := by norm_num

-- The first four gaps together stay below the 0.0005 km budget: 468750 < 500000 micrometres.
example : (250000 : ℕ) + 125000 + 62500 + 31250 = 468750 ∧ 468750 < 500000 := by norm_num

-- Potholes with denominator up to 8: 21 fractions p/q in lowest terms with 0 < p < q ≤ 8.
example : ((Finset.Icc 1 8 ×ˢ Finset.Icc 1 8).filter
    (fun pq : ℕ × ℕ => pq.1 < pq.2 ∧ Nat.Coprime pq.1 pq.2)).card = 21 := by decide

-- The pothole 301/1003 sits strictly inside (0.3, 0.3001): 3/10 < 301/1003 < 3001/10000.
example : 3 * 1003 < 10 * 301 ∧ 10000 * 301 < 3001 * 1003 := by norm_num

-- Four points (here 0, 1, 2, 3 for the card's 1, 2, 3, 4), sizes in quarters: μ gives 1 to each
-- point, ν gives 2 to the first and last. They agree on {1, 2} and {1, 3} (2 quarters each),
-- differ on {1} (1 quarter against 2), and disagree on 10 of the 16 subsets.
example : (∑ i ∈ ({0, 1} : Finset (Fin 4)), (![1, 1, 1, 1] : Fin 4 → ℕ) i) = 2 ∧
    (∑ i ∈ ({0, 1} : Finset (Fin 4)), (![2, 0, 0, 2] : Fin 4 → ℕ) i) = 2 ∧
    (∑ i ∈ ({0, 2} : Finset (Fin 4)), (![1, 1, 1, 1] : Fin 4 → ℕ) i) = 2 ∧
    (∑ i ∈ ({0, 2} : Finset (Fin 4)), (![2, 0, 0, 2] : Fin 4 → ℕ) i) = 2 ∧
    (![1, 1, 1, 1] : Fin 4 → ℕ) 0 = 1 ∧ (![2, 0, 0, 2] : Fin 4 → ℕ) 0 = 2 := by decide

example : (Finset.univ.filter (fun s : Finset (Fin 4) =>
    ∑ i ∈ s, (![1, 1, 1, 1] : Fin 4 → ℕ) i ≠ ∑ i ∈ s, (![2, 0, 0, 2] : Fin 4 → ℕ) i)).card = 10 := by
  decide

-- Completion on four points: blocks {1, 2} of size 0 and {3, 4} of size 2. The completed sets are
-- those meeting {3, 4} in nothing or all of it: 8 of them, and {3} is not one.
example : (Finset.univ.filter (fun e : Finset (Fin 4) =>
    e ∩ {2, 3} = ∅ ∨ e ∩ {2, 3} = {2, 3})).card = 8 ∧
    ¬ (({2} : Finset (Fin 4)) ∩ {2, 3} = ∅ ∨ ({2} : Finset (Fin 4)) ∩ {2, 3} = {2, 3}) := by
  decide

#print axioms lebesgue_set_squeezed_between_open_and_closed
#print axioms lebesgue_sets_are_borel_sets_up_to_null_sets
#print axioms lebesgue_measure_unique_with_interval_lengths
