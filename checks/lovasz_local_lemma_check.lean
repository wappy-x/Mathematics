-- The Lovasz local lemma: if each of m bad events has chance at most p, each is independent of all the events outside its at most d neighbours together, and e p (d + 1) <= 1, then all of them are avoided at once with chance at least (1 - 1/(d + 1))^m, so some outcome avoids them all.
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.Complex.ExponentialBounds
import Mathlib.MeasureTheory.Measure.Real

open MeasureTheory ProbabilityTheory

/-- Helper: `(1 + 1/d)^d ≤ e`, in the form `exp (-1) ≤ (d/(d+1))^d`. -/
theorem lll_aux_exp_bound (d : ℕ) :
    Real.exp (-1) ≤ ((d : ℝ) / (d + 1)) ^ d := by
  rcases Nat.eq_zero_or_pos d with rfl | hd
  · simp only [pow_zero]
    rw [Real.exp_le_one_iff]; norm_num
  have hdpos : (0 : ℝ) < d := by exact_mod_cast hd
  have h1 : 1 / (d : ℝ) + 1 ≤ Real.exp (1 / d) := by
    have := Real.add_one_le_exp (1 / (d : ℝ)); linarith
  have h2 : (1 / (d : ℝ) + 1) ^ d ≤ Real.exp 1 := by
    calc (1 / (d : ℝ) + 1) ^ d ≤ Real.exp (1 / d) ^ d :=
          pow_le_pow_left₀ (by positivity) h1 d
      _ = Real.exp 1 := by
          rw [← Real.exp_nat_mul]; congr 1; field_simp
  have h3 : ((d : ℝ) / (d + 1)) ^ d = 1 / (1 / (d : ℝ) + 1) ^ d := by
    rw [one_div, ← inv_pow]; congr 1; field_simp; ring
  rw [h3, Real.exp_neg, ← one_div]
  apply one_div_le_one_div_of_le (by positivity) h2

/-- Helper: the general local lemma with a weight `x`, in multiplicative form. -/
theorem lll_aux_general {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {m : ℕ} (A : Fin m → Set Ω) (hA : ∀ i, MeasurableSet (A i))
    (Γ : Fin m → Finset (Fin m)) (p x : ℝ) (d : ℕ)
    (hp : ∀ i, μ.real (A i) ≤ p) (hd : ∀ i, (Γ i).card ≤ d)
    (hind : ∀ i, Indep (MeasurableSpace.generateFrom {A i})
      (⨆ (j : Fin m) (_ : j ≠ i ∧ j ∉ Γ i), MeasurableSpace.generateFrom {A j}) μ)
    (hx0 : 0 ≤ x) (hx1 : x ≤ 1) (hpx : p ≤ x * (1 - x) ^ d) :
    (1 - x) ^ m ≤ μ.real (⋂ i, (A i)ᶜ) := by
  classical
  set B : Finset (Fin m) → Set Ω := fun S => ⋂ j ∈ S, (A j)ᶜ with hBdef
  have hBmeas : ∀ S, MeasurableSet (B S) := fun S =>
    Finset.measurableSet_biInter S (fun j _ => (hA j).compl)
  have hx1' : 0 ≤ 1 - x := by linarith
  -- chain bound
  have chain : ∀ U V : Finset (Fin m), Disjoint U V →
      (∀ W : Finset (Fin m), W.card < U.card + V.card → ∀ i ∉ W,
        μ.real (A i ∩ B W) ≤ x * μ.real (B W)) →
      (1 - x) ^ V.card * μ.real (B U) ≤ μ.real (B (U ∪ V)) := by
    intro U V
    induction V using Finset.induction_on with
    | empty => intro _ _; simp
    | @insert j V hjV ih =>
      intro hdisj hcl
      have hdisj' : Disjoint U V := Finset.disjoint_of_subset_right (Finset.subset_insert _ _) hdisj
      have hjU : j ∉ U := fun h => Finset.disjoint_left.mp hdisj h (Finset.mem_insert_self _ _)
      have hcardUV : (U ∪ V).card = U.card + V.card := Finset.card_union_of_disjoint hdisj'
      have ih' := ih hdisj' (fun W hW i hi => hcl W (by rw [Finset.card_insert_of_notMem hjV]; omega) i hi)
      have hjUV : j ∉ U ∪ V := by simp [hjU, hjV]
      have hstep := hcl (U ∪ V) (by rw [Finset.card_insert_of_notMem hjV]; omega) j hjUV
      have hsplit := measureReal_inter_add_sdiff (μ := μ) (s := B (U ∪ V)) (hA j)
      have hBins : B (U ∪ insert j V) = B (U ∪ V) \ A j := by
        simp only [hBdef, Finset.union_insert, Finset.set_biInter_insert]
        rw [Set.sdiff_eq, Set.inter_comm]
      rw [hBins, Finset.card_insert_of_notMem hjV, pow_succ]
      rw [Set.inter_comm] at hstep
      have hB0 : 0 ≤ μ.real (B U) := measureReal_nonneg
      calc (1 - x) ^ V.card * (1 - x) * μ.real (B U)
          = (1 - x) * ((1 - x) ^ V.card * μ.real (B U)) := by ring
        _ ≤ (1 - x) * μ.real (B (U ∪ V)) := mul_le_mul_of_nonneg_left ih' hx1'
        _ ≤ μ.real (B (U ∪ V) \ A j) := by linarith
  -- main claim
  have key : ∀ n, ∀ S : Finset (Fin m), S.card = n → ∀ i ∉ S,
      μ.real (A i ∩ B S) ≤ x * μ.real (B S) := by
    intro n
    induction n using Nat.strong_induction_on with
    | _ n ihn =>
    intro S hS i hi
    set S2 := S.filter (fun j => j ∉ Γ i) with hS2
    set S1 := S.filter (fun j => j ∈ Γ i) with hS1
    have hdisj : Disjoint S2 S1 := by
      rw [hS2, hS1, Finset.disjoint_filter]; intro j _ h1 h2; exact h1 h2
    have hunion : S2 ∪ S1 = S := by
      ext j; simp only [hS2, hS1, Finset.mem_union, Finset.mem_filter]; tauto
    have hcard : S2.card + S1.card = S.card := by
      rw [← Finset.card_union_of_disjoint hdisj, hunion]
    have hch := chain S2 S1 hdisj (fun W hW k hk => ihn W.card (by omega) W rfl k hk)
    rw [hunion] at hch
    have hS1card : S1.card ≤ d := (Finset.card_le_card (by
      intro j hj; rw [hS1, Finset.mem_filter] at hj; exact hj.2)).trans (hd i)
    -- independence
    have hmeas2 : MeasurableSet[⨆ (j : Fin m) (_ : j ≠ i ∧ j ∉ Γ i),
        MeasurableSpace.generateFrom {A j}] (B S2) := by
      apply Finset.measurableSet_biInter
      intro j hj0
      have hj : j ∈ S ∧ j ∉ Γ i := by simpa [hS2] using hj0
      have hji : j ≠ i := fun h => hi (h ▸ hj.1)
      apply MeasurableSet.compl
      have h0 : MeasurableSet[MeasurableSpace.generateFrom {A j}] (A j) :=
        MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)
      exact (le_iSup₂ (f := fun (j : Fin m) (_ : j ≠ i ∧ j ∉ Γ i) =>
        MeasurableSpace.generateFrom {A j}) j ⟨hji, hj.2⟩) _ h0
    have hmeas1 : MeasurableSet[MeasurableSpace.generateFrom {A i}] (A i) :=
      MeasurableSpace.measurableSet_generateFrom (Set.mem_singleton _)
    have hindeq := (Indep_iff _ _ μ).mp (hind i) (A i) (B S2) hmeas1 hmeas2
    have hindr : μ.real (A i ∩ B S2) = μ.real (A i) * μ.real (B S2) := by
      simp only [Measure.real, hindeq, ENNReal.toReal_mul]
    have hsub : B S ⊆ B S2 := by
      simp only [hBdef]
      exact Set.biInter_subset_biInter_left (fun j hj => by
        exact (by simpa [hS2] using hj : j ∈ S ∧ j ∉ Γ i).1)
    have hB2 : 0 ≤ μ.real (B S2) := measureReal_nonneg
    have hpow : (1 - x) ^ d ≤ (1 - x) ^ S1.card := pow_le_pow_of_le_one hx1' (by linarith) hS1card
    calc μ.real (A i ∩ B S) ≤ μ.real (A i ∩ B S2) :=
          measureReal_mono (Set.inter_subset_inter_right _ hsub)
      _ = μ.real (A i) * μ.real (B S2) := hindr
      _ ≤ p * μ.real (B S2) := mul_le_mul_of_nonneg_right (hp i) hB2
      _ ≤ (x * (1 - x) ^ d) * μ.real (B S2) := mul_le_mul_of_nonneg_right hpx hB2
      _ ≤ (x * (1 - x) ^ S1.card) * μ.real (B S2) :=
          mul_le_mul_of_nonneg_right (mul_le_mul_of_nonneg_left hpow hx0) hB2
      _ = x * ((1 - x) ^ S1.card * μ.real (B S2)) := by ring
      _ ≤ x * μ.real (B S) := mul_le_mul_of_nonneg_left hch hx0
  have hfin := chain ∅ Finset.univ (Finset.disjoint_empty_left _)
    (fun W hW i hi => key W.card W rfl i hi)
  have hBe : B ∅ = Set.univ := by simp [hBdef]
  have hBu : B (∅ ∪ Finset.univ) = ⋂ i, (A i)ᶜ := by simp [hBdef]
  rw [hBe, hBu, probReal_univ, mul_one, Finset.card_univ, Fintype.card_fin] at hfin
  exact hfin

#print axioms lll_aux_exp_bound
#print axioms lll_aux_general

/-- The symmetric Lovasz local lemma. Take bad events `A 0, ..., A (m - 1)` on a probability
space. Each has chance at most `p`. Event `i` has a set `Γ i` of at most `d` neighbours, and it is
independent of all its non-neighbours together. If `e * p * (d + 1) ≤ 1`, there is an outcome in
which none of the bad events happens. -/
theorem lovasz_local_lemma_symmetric {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {m : ℕ} (A : Fin m → Set Ω) (hA : ∀ i, MeasurableSet (A i))
    (Γ : Fin m → Finset (Fin m)) (p : ℝ) (d : ℕ)
    (hp : ∀ i, μ.real (A i) ≤ p) (hd : ∀ i, (Γ i).card ≤ d)
    (hind : ∀ i, Indep (MeasurableSpace.generateFrom {A i})
      (⨆ (j : Fin m) (_ : j ≠ i ∧ j ∉ Γ i), MeasurableSpace.generateFrom {A j}) μ)
    (he : Real.exp 1 * p * (d + 1) ≤ 1) :
    ∃ ω : Ω, ∀ i, ω ∉ A i := by
  classical
  have h3 := lll_aux_exp_bound (d + 1)
  push_cast at h3
  have hd1 : (0 : ℝ) < (d : ℝ) + 1 := by positivity
  have hd2 : (0 : ℝ) < (d : ℝ) + 1 + 1 := by positivity
  have hxp : p ≤ (1 / ((d : ℝ) + 2)) * (1 - 1 / ((d : ℝ) + 2)) ^ d := by
    have hval : (1 / ((d : ℝ) + 2)) * (1 - 1 / ((d : ℝ) + 2)) ^ d
        = (1 / ((d : ℝ) + 1)) * (((d : ℝ) + 1) / ((d : ℝ) + 1 + 1)) ^ (d + 1) := by
      rw [pow_succ]
      have : (1 - 1 / ((d : ℝ) + 2)) = ((d : ℝ) + 1) / ((d : ℝ) + 1 + 1) := by
        field_simp; ring
      rw [this]; field_simp; ring
    rw [hval]
    have he' : p ≤ Real.exp (-1) / ((d : ℝ) + 1) := by
      have he1 := Real.exp_pos 1
      rw [le_div_iff₀ hd1, Real.exp_neg, ← one_div, le_div_iff₀ he1]; nlinarith [he]
    calc p ≤ Real.exp (-1) / ((d : ℝ) + 1) := he'
      _ ≤ (((d : ℝ) + 1) / ((d : ℝ) + 1 + 1)) ^ (d + 1) / ((d : ℝ) + 1) :=
          div_le_div_of_nonneg_right h3 hd1.le
      _ = _ := by ring
  have hx0 : (0 : ℝ) ≤ 1 / ((d : ℝ) + 2) := by positivity
  have hx1 : 1 / ((d : ℝ) + 2) < 1 := by rw [div_lt_one (by positivity)]; linarith
  have hmain := lll_aux_general μ A hA Γ p _ d hp hd hind hx0 hx1.le hxp
  have hpos : 0 < μ.real (⋂ i, (A i)ᶜ) :=
    lt_of_lt_of_le (pow_pos (by linarith) m) hmain
  have hne : (⋂ i, (A i)ᶜ).Nonempty := by
    by_contra h
    rw [Set.not_nonempty_iff_eq_empty] at h
    rw [h, measureReal_empty] at hpos
    exact lt_irrefl _ hpos
  obtain ⟨ω, hω⟩ := hne
  exact ⟨ω, fun i => Set.mem_iInter.mp hω i⟩

/-- The card's formula: under the same conditions, the chance that every bad event is avoided is
at least `(1 - 1/(d + 1))^m`. -/
theorem lovasz_local_lemma_floor {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {m : ℕ} (A : Fin m → Set Ω) (hA : ∀ i, MeasurableSet (A i))
    (Γ : Fin m → Finset (Fin m)) (p : ℝ) (d : ℕ)
    (hp : ∀ i, μ.real (A i) ≤ p) (hd : ∀ i, (Γ i).card ≤ d)
    (hind : ∀ i, Indep (MeasurableSpace.generateFrom {A i})
      (⨆ (j : Fin m) (_ : j ≠ i ∧ j ∉ Γ i), MeasurableSpace.generateFrom {A j}) μ)
    (he : Real.exp 1 * p * (d + 1) ≤ 1) :
    (1 - 1 / ((d : ℝ) + 1)) ^ m ≤ μ.real (⋂ i, (A i)ᶜ) := by
  have h3 := lll_aux_exp_bound d
  have hd1 : (0 : ℝ) < (d : ℝ) + 1 := by positivity
  have hxp : p ≤ (1 / ((d : ℝ) + 1)) * (1 - 1 / ((d : ℝ) + 1)) ^ d := by
    have hval : (1 - 1 / ((d : ℝ) + 1)) = (d : ℝ) / ((d : ℝ) + 1) := by
      field_simp; ring
    rw [hval]
    have he1 := Real.exp_pos 1
    have he' : p ≤ Real.exp (-1) / ((d : ℝ) + 1) := by
      rw [le_div_iff₀ hd1, Real.exp_neg, ← one_div, le_div_iff₀ he1]; nlinarith [he]
    calc p ≤ Real.exp (-1) / ((d : ℝ) + 1) := he'
      _ ≤ ((d : ℝ) / ((d : ℝ) + 1)) ^ d / ((d : ℝ) + 1) :=
          div_le_div_of_nonneg_right h3 hd1.le
      _ = _ := by ring
  have hx0 : (0 : ℝ) ≤ 1 / ((d : ℝ) + 1) := by positivity
  have hx1 : 1 / ((d : ℝ) + 1) ≤ 1 := by
    rw [div_le_one hd1]; have : (0:ℝ) ≤ d := Nat.cast_nonneg d; linarith
  exact lll_aux_general μ A hA Γ p _ d hp hd hind hx0 hx1 hxp

/-- Step 3, where the e comes from: `(d / (d + 1))^d` is never below `1/e`. -/
theorem one_div_e_le_pow_d_div_succ (d : ℕ) :
    Real.exp (-1) ≤ ((d : ℝ) / (d + 1)) ^ d := by
  exact lll_aux_exp_bound d

-- 10-SAT: p = 1/1024. The rule holds at d = 375 (e × 376/1024 ≤ 1) and fails at d = 376.
example : Real.exp 1 * (1 / 1024) * (375 + 1) ≤ 1 := by
  have := Real.exp_one_lt_d9; norm_num at this ⊢; linarith
example : 1 < Real.exp 1 * (1 / 1024) * (376 + 1) := by
  have := Real.exp_one_gt_d9; norm_num at this ⊢; linarith

-- The union bound fails for the 3800-clause formula: 3800/1024 is over 1.
example : (1 : ℚ) < 3800 / 1024 := by norm_num

-- 2-colouring ten-sets: p = 2/1024. The rule holds at d = 187 and fails at d = 188.
example : Real.exp 1 * (2 / 1024) * (187 + 1) ≤ 1 := by
  have := Real.exp_one_lt_d9; norm_num at this ⊢; linarith
example : 1 < Real.exp 1 * (2 / 1024) * (188 + 1) := by
  have := Real.exp_one_gt_d9; norm_num at this ⊢; linarith

-- The ring of six 4-variable clauses: p = 1/16, d = 2, and e × 3/16 is under 1.
example : Real.exp 1 * (1 / 16) * (2 + 1) ≤ 1 := by
  have := Real.exp_one_lt_d9; norm_num at this ⊢; linarith

-- Erdos's counting bound for k = 10: n = 100 passes (2 C(n,10) < 2^C(10,2)) and n = 101 fails.
example : 2 * Nat.choose 100 10 < 2 ^ Nat.choose 10 2 := by decide
example : ¬ 2 * Nat.choose 101 10 < 2 ^ Nat.choose 10 2 := by decide

#print axioms lovasz_local_lemma_symmetric
#print axioms lovasz_local_lemma_floor
#print axioms one_div_e_le_pow_d_div_succ
