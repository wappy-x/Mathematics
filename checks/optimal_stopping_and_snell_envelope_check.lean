-- Optimal stopping: the Snell envelope, built backwards from a fixed deadline, is the smallest supermartingale above the reward, and stopping the first time the reward meets it earns the best average reward of any stopping rule.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Process.Stopping

open MeasureTheory

variable {Ω : Type*} {m0 : MeasurableSpace Ω}

/-- The backward recursion, indexed by the number `k` of months left before the deadline `N`:
`k = 0` is the deadline itself, where the worth is the reward `Z N`; with `k + 1` months left,
the worth is the better of the reward now and the conditional average of next month's worth. -/
noncomputable def snellAux (μ : Measure Ω) (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (N : ℕ) :
    ℕ → Ω → ℝ
  | 0 => Z N
  | k + 1 => fun ω => max (Z (N - (k + 1)) ω) (μ[snellAux μ ℱ Z N k | ℱ (N - (k + 1))] ω)

/-- The Snell envelope `U n` for months `1 ≤ n ≤ N`: `U N = Z N` and
`U n = max (Z n) (E[U (n+1) | ℱ n])` for `n < N`. -/
noncomputable def snellEnvelope (μ : Measure Ω) (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (N : ℕ)
    (n : ℕ) : Ω → ℝ :=
  snellAux μ ℱ Z N (N - n)

/-- The rule "sell the first month `n ≥ 1` at which the reward equals the envelope". -/
noncomputable def snellStop (μ : Measure Ω) (ℱ : Filtration ℕ m0) (Z : ℕ → Ω → ℝ) (N : ℕ) :
    Ω → WithTop ℕ :=
  fun ω => ((sInf {n : ℕ | 1 ≤ n ∧ snellEnvelope μ ℱ Z N n ω = Z n ω} : ℕ) : WithTop ℕ)

/-! Helper lemmas. -/

lemma snellEnvelope_of_ge {μ : Measure Ω} {ℱ : Filtration ℕ m0} {Z : ℕ → Ω → ℝ} {N n : ℕ}
    (h : N ≤ n) : snellEnvelope μ ℱ Z N n = Z N := by
  unfold snellEnvelope
  rw [Nat.sub_eq_zero_of_le h]
  rfl

lemma snellEnvelope_apply_of_lt {μ : Measure Ω} {ℱ : Filtration ℕ m0} {Z : ℕ → Ω → ℝ}
    {N n : ℕ} (h : n < N) (ω : Ω) :
    snellEnvelope μ ℱ Z N n ω =
      max (Z n ω) (μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n] ω) := by
  unfold snellEnvelope
  have hk : N - n = (N - (n + 1)) + 1 := by omega
  rw [hk, snellAux]
  have h2 : N - (N - (n + 1) + 1) = n := by omega
  rw [h2]

lemma snell_props {μ : Measure Ω} {ℱ : Filtration ℕ m0} {Z : ℕ → Ω → ℝ} {N : ℕ}
    (hZmeas : ∀ n, 1 ≤ n → n ≤ N → StronglyMeasurable[ℱ n] (Z n))
    (hZint : ∀ n, 1 ≤ n → n ≤ N → Integrable (Z n) μ) :
    ∀ n, 1 ≤ n → n ≤ N →
      StronglyMeasurable[ℱ n] (snellEnvelope μ ℱ Z N n) ∧
        Integrable (snellEnvelope μ ℱ Z N n) μ ∧ ∀ ω, Z n ω ≤ snellEnvelope μ ℱ Z N n ω := by
  have key : ∀ k n, n + k = N → 1 ≤ n →
      StronglyMeasurable[ℱ n] (snellEnvelope μ ℱ Z N n) ∧
        Integrable (snellEnvelope μ ℱ Z N n) μ ∧ ∀ ω, Z n ω ≤ snellEnvelope μ ℱ Z N n ω := by
    intro k
    induction k with
    | zero =>
      intro n hn h1
      have hnN : n = N := by omega
      subst hnN
      rw [snellEnvelope_of_ge le_rfl]
      exact ⟨hZmeas _ h1 le_rfl, hZint _ h1 le_rfl, fun ω => le_rfl⟩
    | succ k ih =>
      intro n hn h1
      have hfun : snellEnvelope μ ℱ Z N n =
          fun ω => max (Z n ω) (μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n] ω) :=
        funext (snellEnvelope_apply_of_lt (by omega))
      rw [hfun]
      have hc1 : StronglyMeasurable[ℱ n] (μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n]) :=
        stronglyMeasurable_condExp
      have hc2 : Integrable (μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n]) μ := integrable_condExp
      have hc3 : StronglyMeasurable[ℱ n]
          (fun ω => max (Z n ω) (μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n] ω)) := by
        let _ : MeasurableSpace Ω := ℱ n
        exact (hZmeas n h1 (by omega)).sup hc1
      exact ⟨hc3, (hZint n h1 (by omega)).sup hc2, fun ω => le_max_left _ _⟩
  intro n h1 h2
  exact key (N - n) n (by omega) h1

lemma snell_min_succ (V : ℕ → Ω → ℝ) (τ : Ω → ℕ) (j : ℕ) :
    (fun ω => V (min (τ ω) (j + 1)) ω) = fun ω => V (min (τ ω) j) ω +
      {ω | j < τ ω}.indicator (fun ω => V (j + 1) ω - V j ω) ω := by
  funext ω
  by_cases h : j < τ ω
  · have h1 : min (τ ω) (j + 1) = j + 1 := by omega
    have h2 : min (τ ω) j = j := by omega
    rw [h1, h2, Set.indicator_of_mem (show ω ∈ {ω | j < τ ω} from h)]
    ring
  · have h1 : min (τ ω) (j + 1) = τ ω := by omega
    have h2 : min (τ ω) j = τ ω := by omega
    rw [h1, h2, Set.indicator_of_notMem (show ω ∉ {ω | j < τ ω} from h)]
    ring

lemma snell_integrable_min {μ : Measure Ω} {ℱ : Filtration ℕ m0} (V : ℕ → Ω → ℝ)
    (hV : ∀ n, Integrable (V n) μ) (τ : Ω → ℕ)
    (hA : ∀ j, MeasurableSet[ℱ j] {ω | j < τ ω}) (j : ℕ) :
    Integrable (fun ω => V (min (τ ω) j) ω) μ := by
  induction j with
  | zero => simpa using hV 0
  | succ j ih =>
    rw [snell_min_succ]
    exact ih.add (((hV (j + 1)).sub (hV j)).indicator (ℱ.le j _ (hA j)))

lemma snell_integral_min_succ {μ : Measure Ω} [IsFiniteMeasure μ] {ℱ : Filtration ℕ m0}
    (V : ℕ → Ω → ℝ) (hV : ∀ n, Integrable (V n) μ) (τ : Ω → ℕ)
    (hA : ∀ j, MeasurableSet[ℱ j] {ω | j < τ ω}) (j : ℕ) :
    ∫ ω, V (min (τ ω) (j + 1)) ω ∂μ = ∫ ω, V (min (τ ω) j) ω ∂μ +
      ((∫ ω in {ω | j < τ ω}, (μ[V (j + 1) | ℱ j]) ω ∂μ) - ∫ ω in {ω | j < τ ω}, V j ω ∂μ) := by
  have hm : MeasurableSet {ω | j < τ ω} := ℱ.le j _ (hA j)
  have i1 : Integrable (fun ω => V (min (τ ω) j) ω) μ := snell_integrable_min V hV τ hA j
  have i2 : Integrable ({ω | j < τ ω}.indicator (fun ω => V (j + 1) ω - V j ω)) μ :=
    ((hV (j + 1)).sub (hV j)).indicator hm
  rw [snell_min_succ, integral_add i1 i2, integral_indicator hm,
    integral_sub (hV _).integrableOn (hV _).integrableOn,
    setIntegral_condExp (ℱ.le j) (hV _) (hA j)]

lemma snell_integral_min_le {μ : Measure Ω} [IsFiniteMeasure μ] {ℱ : Filtration ℕ m0}
    (V : ℕ → Ω → ℝ) (hV : ∀ n, Integrable (V n) μ) (τ : Ω → ℕ)
    (hA : ∀ j, MeasurableSet[ℱ j] {ω | j < τ ω}) (a b : ℕ)
    (hstep : ∀ j, a ≤ j → j < b →
      ∫ ω in {ω | j < τ ω}, (μ[V (j + 1) | ℱ j]) ω ∂μ ≤ ∫ ω in {ω | j < τ ω}, V j ω ∂μ) :
    ∀ j, a ≤ j → j ≤ b → ∫ ω, V (min (τ ω) j) ω ∂μ ≤ ∫ ω, V (min (τ ω) a) ω ∂μ := by
  intro j haj
  induction j, haj using Nat.le_induction with
  | base => intro _; exact le_rfl
  | succ j haj ih =>
    intro hjb
    rw [snell_integral_min_succ V hV τ hA j]
    have h1 := hstep j haj (by omega)
    have h2 := ih (by omega)
    linarith

lemma snell_integral_min_eq {μ : Measure Ω} [IsFiniteMeasure μ] {ℱ : Filtration ℕ m0}
    (V : ℕ → Ω → ℝ) (hV : ∀ n, Integrable (V n) μ) (τ : Ω → ℕ)
    (hA : ∀ j, MeasurableSet[ℱ j] {ω | j < τ ω}) (a b : ℕ)
    (hstep : ∀ j, a ≤ j → j < b →
      ∫ ω in {ω | j < τ ω}, (μ[V (j + 1) | ℱ j]) ω ∂μ = ∫ ω in {ω | j < τ ω}, V j ω ∂μ) :
    ∀ j, a ≤ j → j ≤ b → ∫ ω, V (min (τ ω) j) ω ∂μ = ∫ ω, V (min (τ ω) a) ω ∂μ := by
  intro j haj
  induction j, haj using Nat.le_induction with
  | base => intro _; rfl
  | succ j haj ih =>
    intro hjb
    rw [snell_integral_min_succ V hV τ hA j]
    have h1 := hstep j haj (by omega)
    have h2 := ih (by omega)
    linarith

#print axioms snellEnvelope_of_ge
#print axioms snellEnvelope_apply_of_lt
#print axioms snell_props
#print axioms snell_min_succ
#print axioms snell_integrable_min
#print axioms snell_integral_min_succ
#print axioms snell_integral_min_le
#print axioms snell_integral_min_eq

/-- **Optimal stopping.** With a fixed deadline `N`, rewards `Z 1, …, Z N` that are known at their
month and have finite averages, the worth at listing `U 0 = E[U 1]` of the Snell envelope is the
largest average reward `E[Z τ]` over all stopping rules `τ` with `1 ≤ τ ≤ N`, and the rule
`τ* = min {n ≥ 1 : U n = Z n}` is a stopping rule that attains it. -/
theorem snell_envelope_is_optimal_stopping_value
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {Z : ℕ → Ω → ℝ} {N : ℕ}
    (hN : 1 ≤ N)
    (hZmeas : ∀ n, 1 ≤ n → n ≤ N → StronglyMeasurable[ℱ n] (Z n))
    (hZint : ∀ n, 1 ≤ n → n ≤ N → Integrable (Z n) μ) :
    IsGreatest
        {x : ℝ | ∃ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ ∧ (∀ ω, 1 ≤ τ ω ∧ τ ω ≤ N) ∧
          x = ∫ ω, stoppedValue Z τ ω ∂μ}
        (∫ ω, snellEnvelope μ ℱ Z N 1 ω ∂μ) ∧
      IsStoppingTime ℱ (snellStop μ ℱ Z N) ∧ (∀ ω, 1 ≤ snellStop μ ℱ Z N ω ∧ snellStop μ ℱ Z N ω ≤ N) ∧
      ∫ ω, stoppedValue Z (snellStop μ ℱ Z N) ω ∂μ = ∫ ω, snellEnvelope μ ℱ Z N 1 ω ∂μ := by
  have hU := snell_props (μ := μ) hZmeas hZint
  have hsup' : ∀ n, 1 ≤ n → n < N →
      μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n] ≤ᵐ[μ] snellEnvelope μ ℱ Z N n := by
    intro n _ hlt
    exact Filter.Eventually.of_forall fun ω => by
      rw [snellEnvelope_apply_of_lt hlt ω]
      exact le_max_right _ _
  let V : ℕ → Ω → ℝ := fun n => if 1 ≤ n ∧ n ≤ N then snellEnvelope μ ℱ Z N n else 0
  have hV : ∀ n, Integrable (V n) μ := by
    intro n
    simp only [V]
    split_ifs with h
    · exact (hU n h.1 h.2).2.1
    · exact integrable_zero _ _ _
  have hVeq : ∀ n, 1 ≤ n → n ≤ N → V n = snellEnvelope μ ℱ Z N n := by
    intro n h1 h2
    simp [V, h1, h2]
  let Z' : ℕ → Ω → ℝ := fun n => if 1 ≤ n ∧ n ≤ N then Z n else 0
  have hZ' : ∀ n, Integrable (Z' n) μ := by
    intro n
    simp only [Z']
    split_ifs with h
    · exact hZint n h.1 h.2
    · exact integrable_zero _ _ _
  have hZ'eq : ∀ n, 1 ≤ n → n ≤ N → Z' n = Z n := by
    intro n h1 h2
    simp [Z', h1, h2]
  -- Any stopping rule earns at most the envelope's average.
  have upper : ∀ τ : Ω → WithTop ℕ, IsStoppingTime ℱ τ → (∀ ω, 1 ≤ τ ω ∧ τ ω ≤ N) →
      ∫ ω, stoppedValue Z τ ω ∂μ ≤ ∫ ω, snellEnvelope μ ℱ Z N 1 ω ∂μ := by
    intro τ hτ hτb
    let τ' : Ω → ℕ := fun ω => (τ ω).untopA
    have hτeq : ∀ ω, τ ω = WithTop.some (τ' ω) := by
      intro ω
      have hne : τ ω ≠ ⊤ := ne_top_of_le_ne_top (WithTop.coe_ne_top (a := N)) (hτb ω).2
      cases h : τ ω with
      | top => exact absurd h hne
      | coe a =>
        show (a : WithTop ℕ) = WithTop.some ((τ ω).untopA)
        rw [h]
        rfl
    have hτ'b : ∀ ω, 1 ≤ τ' ω ∧ τ' ω ≤ N := by
      intro ω
      have h := hτb ω
      rw [hτeq ω] at h
      exact ⟨WithTop.coe_le_coe.mp h.1, WithTop.coe_le_coe.mp h.2⟩
    have hA : ∀ j, MeasurableSet[ℱ j] {ω | j < τ' ω} := by
      intro j
      have hs : {ω | j < τ' ω} = {ω | τ ω ≤ WithTop.some j}ᶜ := by
        ext ω
        simp only [Set.mem_ofPred_eq, Set.mem_compl_iff, hτeq ω, WithTop.coe_le_coe, not_le]
      rw [hs]
      exact (hτ j).compl
    have hstep : ∀ j, 1 ≤ j → j < N →
        ∫ ω in {ω | j < τ' ω}, (μ[V (j + 1) | ℱ j]) ω ∂μ ≤ ∫ ω in {ω | j < τ' ω}, V j ω ∂μ := by
      intro j h1 h2
      rw [hVeq (j + 1) (by omega) (by omega), hVeq j h1 h2.le]
      exact setIntegral_mono_ae integrable_condExp.integrableOn
        (hU j h1 h2.le).2.1.integrableOn (hsup' j h1 h2)
    have hmono := snell_integral_min_le V hV τ' hA 1 N hstep N hN le_rfl
    have e1 : ∀ ω, V (min (τ' ω) 1) ω = snellEnvelope μ ℱ Z N 1 ω := by
      intro ω
      have h := hτ'b ω
      rw [show min (τ' ω) 1 = 1 by omega, hVeq 1 le_rfl hN]
    have hint : Integrable (stoppedValue Z τ) μ := by
      have hs : stoppedValue Z τ = fun ω => Z' (min (τ' ω) N) ω := by
        funext ω
        have h := hτ'b ω
        rw [min_eq_left h.2, hZ'eq _ h.1 h.2]
        rfl
      rw [hs]
      exact snell_integrable_min Z' hZ' τ' hA N
    calc ∫ ω, stoppedValue Z τ ω ∂μ ≤ ∫ ω, V (min (τ' ω) N) ω ∂μ := by
          refine integral_mono hint (snell_integrable_min V hV τ' hA N) fun ω => ?_
          have h := hτ'b ω
          show Z (τ' ω) ω ≤ _
          rw [min_eq_left h.2, hVeq _ h.1 h.2]
          exact (hU _ h.1 h.2).2.2 ω
      _ ≤ ∫ ω, V (min (τ' ω) 1) ω ∂μ := hmono
      _ = ∫ ω, snellEnvelope μ ℱ Z N 1 ω ∂μ := integral_congr_ae (ae_of_all _ e1)
  -- The rule `snellStop`.
  let τ' : Ω → ℕ := fun ω => sInf {n : ℕ | 1 ≤ n ∧ snellEnvelope μ ℱ Z N n ω = Z n ω}
  have hNS : ∀ ω, N ∈ {n : ℕ | 1 ≤ n ∧ snellEnvelope μ ℱ Z N n ω = Z n ω} :=
    fun ω => ⟨hN, by rw [snellEnvelope_of_ge le_rfl]⟩
  have hmem : ∀ ω, 1 ≤ τ' ω ∧ snellEnvelope μ ℱ Z N (τ' ω) ω = Z (τ' ω) ω :=
    fun ω => Nat.sInf_mem ⟨N, hNS ω⟩
  have hle : ∀ ω, τ' ω ≤ N := fun ω => Nat.sInf_le (hNS ω)
  have hmeas : ∀ i, MeasurableSet[ℱ i] {ω | τ' ω ≤ i} := by
    intro i
    have hs : {ω | τ' ω ≤ i} =
        ⋃ n ∈ Finset.Icc 1 (min i N), {ω | snellEnvelope μ ℱ Z N n ω = Z n ω} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_Icc, exists_prop]
      constructor
      · intro h
        exact ⟨τ' ω, ⟨(hmem ω).1, le_min h (hle ω)⟩, (hmem ω).2⟩
      · rintro ⟨n, ⟨h1, h2⟩, h3⟩
        exact (Nat.sInf_le (show n ∈ {n : ℕ | 1 ≤ n ∧ snellEnvelope μ ℱ Z N n ω = Z n ω} from
          ⟨h1, h3⟩)).trans (h2.trans (min_le_left _ _))
    rw [hs]
    let _ : MeasurableSpace Ω := ℱ i
    refine Finset.measurableSet_biUnion _ fun n hn => ?_
    rw [Finset.mem_Icc] at hn
    have h1 : 1 ≤ n := hn.1
    have h2 : n ≤ i := hn.2.trans (min_le_left _ _)
    have h3 : n ≤ N := hn.2.trans (min_le_right _ _)
    exact ℱ.mono h2 _ ((hU n h1 h3).1.measurableSet_eq_fun (hZmeas n h1 h3))
  have hstop : IsStoppingTime ℱ (snellStop μ ℱ Z N) := by
    intro i
    convert hmeas i using 1
    ext ω
    exact WithTop.coe_le_coe
  have hbounds : ∀ ω, 1 ≤ snellStop μ ℱ Z N ω ∧ snellStop μ ℱ Z N ω ≤ N := by
    intro ω
    show (1 : WithTop ℕ) ≤ ((τ' ω : ℕ) : WithTop ℕ) ∧ ((τ' ω : ℕ) : WithTop ℕ) ≤ (N : WithTop ℕ)
    exact ⟨by exact_mod_cast (hmem ω).1, by exact_mod_cast hle ω⟩
  have hA : ∀ j, MeasurableSet[ℱ j] {ω | j < τ' ω} := by
    intro j
    have hs : {ω | j < τ' ω} = {ω | τ' ω ≤ j}ᶜ := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_compl_iff, not_le]
    rw [hs]
    exact (hmeas j).compl
  have hstep : ∀ j, 1 ≤ j → j < N →
      ∫ ω in {ω | j < τ' ω}, (μ[V (j + 1) | ℱ j]) ω ∂μ = ∫ ω in {ω | j < τ' ω}, V j ω ∂μ := by
    intro j h1 h2
    rw [hVeq (j + 1) (by omega) (by omega), hVeq j h1 h2.le]
    refine setIntegral_congr_fun (ℱ.le j _ (hA j)) fun ω hω => ?_
    have hω' : j < τ' ω := hω
    have hnot : j ∉ {n : ℕ | 1 ≤ n ∧ snellEnvelope μ ℱ Z N n ω = Z n ω} :=
      Nat.notMem_of_lt_sInf hω'
    have hne : snellEnvelope μ ℱ Z N j ω ≠ Z j ω := fun h => hnot ⟨h1, h⟩
    rw [snellEnvelope_apply_of_lt h2 ω] at hne ⊢
    rcases le_total (Z j ω) (μ[snellEnvelope μ ℱ Z N (j + 1) | ℱ j] ω) with h | h
    · rw [max_eq_right h]
    · exact absurd (max_eq_left h) hne
  have heqint := snell_integral_min_eq V hV τ' hA 1 N hstep N hN le_rfl
  have e1 : ∀ ω, V (min (τ' ω) 1) ω = snellEnvelope μ ℱ Z N 1 ω := by
    intro ω
    rw [show min (τ' ω) 1 = 1 by have := (hmem ω).1; omega, hVeq 1 le_rfl hN]
  have e2 : ∀ ω, stoppedValue Z (snellStop μ ℱ Z N) ω = V (min (τ' ω) N) ω := by
    intro ω
    rw [min_eq_left (hle ω), hVeq _ (hmem ω).1 (hle ω), (hmem ω).2]
    rfl
  have hval : ∫ ω, stoppedValue Z (snellStop μ ℱ Z N) ω ∂μ =
      ∫ ω, snellEnvelope μ ℱ Z N 1 ω ∂μ := by
    rw [integral_congr_ae (ae_of_all _ e2), heqint]
    exact integral_congr_ae (ae_of_all _ e1)
  refine ⟨⟨⟨snellStop μ ℱ Z N, hstop, hbounds, hval.symm⟩, ?_⟩, hstop, hbounds, hval⟩
  rintro x ⟨τ, hτ, hτb, rfl⟩
  exact upper τ hτ hτb

/-- **The envelope is a supermartingale at or above the reward.** For months `1 ≤ n ≤ N`, `U n` is
known at month `n`, has a finite average and is at least the reward `Z n`; and for `1 ≤ n < N`
the forecast of next month's envelope is never above this month's: `E[U (n+1) | ℱ n] ≤ U n`. -/
theorem snell_envelope_supermartingale_above_reward
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {Z : ℕ → Ω → ℝ} {N : ℕ}
    (hZmeas : ∀ n, 1 ≤ n → n ≤ N → StronglyMeasurable[ℱ n] (Z n))
    (hZint : ∀ n, 1 ≤ n → n ≤ N → Integrable (Z n) μ) :
    (∀ n, 1 ≤ n → n ≤ N →
      StronglyMeasurable[ℱ n] (snellEnvelope μ ℱ Z N n) ∧ Integrable (snellEnvelope μ ℱ Z N n) μ ∧
        ∀ ω, Z n ω ≤ snellEnvelope μ ℱ Z N n ω) ∧
      ∀ n, 1 ≤ n → n < N → μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n] ≤ᵐ[μ] snellEnvelope μ ℱ Z N n := by
  refine ⟨snell_props hZmeas hZint, fun n _ hlt => ?_⟩
  exact Filter.Eventually.of_forall fun ω => by
    rw [snellEnvelope_apply_of_lt hlt ω]
    exact le_max_right _ _

/-- **The envelope is the smallest such supermartingale.** Any adapted process `Y` with finite
averages that covers the reward (`Y n ≥ Z n` for `1 ≤ n ≤ N`) and is fair-or-falling
(`E[Y (n+1) | ℱ n] ≤ Y n` for `n < N`) lies above the envelope: `Y n ≥ U n` for `1 ≤ n ≤ N`,
and at listing `Y 0 ≥ U 0 = E[U 1 | ℱ 0]`. -/
theorem snell_envelope_smallest_supermartingale_above_reward
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {Z Y : ℕ → Ω → ℝ} {N : ℕ}
    (hN : 1 ≤ N)
    (hZmeas : ∀ n, 1 ≤ n → n ≤ N → StronglyMeasurable[ℱ n] (Z n))
    (hZint : ∀ n, 1 ≤ n → n ≤ N → Integrable (Z n) μ)
    (hYmeas : ∀ n, n ≤ N → StronglyMeasurable[ℱ n] (Y n))
    (hYint : ∀ n, n ≤ N → Integrable (Y n) μ)
    (hYZ : ∀ n, 1 ≤ n → n ≤ N → Z n ≤ᵐ[μ] Y n)
    (hYsup : ∀ n, n < N → μ[Y (n + 1) | ℱ n] ≤ᵐ[μ] Y n) :
    (∀ n, 1 ≤ n → n ≤ N → snellEnvelope μ ℱ Z N n ≤ᵐ[μ] Y n) ∧
      μ[snellEnvelope μ ℱ Z N 1 | ℱ 0] ≤ᵐ[μ] Y 0 := by
  have hU := snell_props (μ := μ) hZmeas hZint
  have key : ∀ k n, n + k = N → 1 ≤ n → snellEnvelope μ ℱ Z N n ≤ᵐ[μ] Y n := by
    intro k
    induction k with
    | zero =>
      intro n hn h1
      have hnN : n = N := by omega
      subst hnN
      rw [snellEnvelope_of_ge le_rfl]
      exact hYZ n h1 le_rfl
    | succ k ih =>
      intro n hn h1
      have hc : μ[snellEnvelope μ ℱ Z N (n + 1) | ℱ n] ≤ᵐ[μ] μ[Y (n + 1) | ℱ n] :=
        condExp_mono (hU (n + 1) (by omega) (by omega)).2.1 (hYint (n + 1) (by omega))
          (ih (n + 1) (by omega) (by omega))
      filter_upwards [hYZ n h1 (by omega), hc, hYsup n (by omega)] with ω ha hb hc'
      rw [snellEnvelope_apply_of_lt (by omega) ω]
      exact max_le ha (hb.trans hc')
  refine ⟨fun n h1 h2 => key (N - n) n (by omega) h1, ?_⟩
  exact (condExp_mono (hU 1 le_rfl hN).2.1 (hYint 1 hN) (key (N - 1) 1 (by omega) le_rfl)).trans
    (hYsup 0 (by omega))

/-! The card's house example, in whole dollars. Offers 380,000 / 400,000 / 430,000 with chances
3, 5, 2 tenths; cost 3,000 a month; deadline month 3. -/

-- Month-3 rewards and the month-2 wait value C₂ = 391,000.
example : (3 * 371000 + 5 * 391000 + 2 * 421000) / 10 = 391000 := by norm_num

-- Month-1 wait value C₁ = 399,100, from the month-2 envelope max(Z₂, C₂).
example :
    (3 * max 374000 391000 + 5 * max 394000 391000 + 2 * max 424000 391000) / 10 = 399100 := by
  norm_num

-- Worth at listing U₀ = 404,680, from the month-1 envelope max(Z₁, C₁).
example :
    (3 * max 377000 399100 + 5 * max 397000 399100 + 2 * max 427000 399100) / 10 = 404680 := by
  norm_num

-- The whole backward recursion from the month-3 rewards in one line: U₀ = 404,680.
example :
    let C₂ := (3 * 371000 + 5 * 391000 + 2 * 421000) / 10
    let C₁ := (3 * max 374000 C₂ + 5 * max 394000 C₂ + 2 * max 424000 C₂) / 10
    (3 * max 377000 C₁ + 5 * max 397000 C₁ + 2 * max 427000 C₁) / 10 = 404680 := by
  norm_num

-- The deadline shortcut V₁ = 397,000, V₂ = 402,100, V₃ = 404,680, with V_k = E[max(X, V_{k-1})] - c.
example : (3 * 380000 + 5 * 400000 + 2 * 430000) / 10 - 3000 = 397000 := by norm_num
example :
    (3 * max 380000 397000 + 5 * max 400000 397000 + 2 * max 430000 397000) / 10 - 3000
      = 402100 := by norm_num
example :
    (3 * max 380000 402100 + 5 * max 400000 402100 + 2 * max 430000 402100) / 10 - 3000
      = 404680 := by norm_num

-- The envelope's rule sells in month 1, 2, 3 with chances 20, 56, 24 hundredths (2/10, 8/10 × 7/10,
-- 8/10 × 3/10), so it waits 2.04 months on average and pays 2.04 × 3,000 = 6,120 in costs.
example : 2 * 10 = 20 ∧ 8 * 7 = 56 ∧ 8 * 3 = 24 ∧ 20 + 56 + 24 = 100 := by norm_num
example : (1 * 20 + 2 * 56 + 3 * 24) * 3000 / 100 = 6120 := by norm_num
-- Mean sale price 410,800, and 410,800 - 6,120 = 404,680.
example : (2 * 430000 * 10 + 8 * (5 * 400000 + 2 * 430000) + 8 * 3 * 400000) / 100 = 410800 := by
  norm_num
example : 410800 - 6120 = 404680 := by norm_num

-- Other rules: take the first offer 397,000; hold out for 430,000 gives 403,480;
-- myopic gives 403,630. (Chances in thousandths over the three months.)
example : (200 * 427000 + 160 * 424000 + 640 * 391000) / 1000 = 403480 := by norm_num
example : (500 * 397000 + 200 * 427000 + 300 * 399100) / 1000 = 403630 := by norm_num

-- With no deadline, the bar V = 415,000 solves V = 0.8 V + 0.2 × 430,000 - 3,000.
example : (8 * 415000 + 2 * 430000) / 10 - 3000 = 415000 := by norm_num

#print axioms snell_envelope_is_optimal_stopping_value
#print axioms snell_envelope_supermartingale_above_reward
#print axioms snell_envelope_smallest_supermartingale_above_reward
