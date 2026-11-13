-- Martingales: a gambler's fortune under fair ±1 coin-toss bets is a martingale for the gambler's own record, so is its square minus the rounds played, and at unfair odds the fortune minus its drift is a martingale while odds at or below even make the fortune a supermartingale.
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.ConditionalExpectation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FunProp

open MeasureTheory ProbabilityTheory Finset

/-- A `±1` variable with chances `p` and `1 - p` is `±1` almost surely and has mean `2p - 1`. -/
lemma pm_one_ae_and_integral
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (η : Ω → ℝ) (hη : Measurable η) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hwin : P {ω | η ω = 1} = ENNReal.ofReal p)
    (hlose : P {ω | η ω = -1} = ENNReal.ofReal (1 - p)) :
    (∀ᵐ ω ∂P, η ω = 1 ∨ η ω = -1) ∧ ∫ ω, η ω ∂P = 2 * p - 1 := by
  have hA : MeasurableSet {ω | η ω = 1} := hη (measurableSet_singleton 1)
  have hB : MeasurableSet {ω | η ω = -1} := hη (measurableSet_singleton (-1))
  have hdisj : Disjoint {ω | η ω = 1} {ω | η ω = -1} := by
    rw [Set.disjoint_left]
    intro ω h1 h2
    change η ω = 1 at h1
    change η ω = -1 at h2
    rw [h1] at h2
    norm_num at h2
  have hU : P ({ω | η ω = 1} ∪ {ω | η ω = -1}) = 1 := by
    rw [measure_union hdisj hB, hwin, hlose, ← ENNReal.ofReal_add hp0 (by linarith)]
    simp
  have hae : ∀ᵐ ω ∂P, η ω = 1 ∨ η ω = -1 := by
    have h0 : P ({ω | η ω = 1} ∪ {ω | η ω = -1})ᶜ = 0 :=
      (prob_compl_eq_zero_iff (hA.union hB)).2 hU
    filter_upwards [mem_ae_iff.2 h0] with ω hω
    simpa using hω
  refine ⟨hae, ?_⟩
  have heq : (fun ω => η ω) =ᵐ[P] fun ω =>
      {ω | η ω = 1}.indicator (fun _ => (1 : ℝ)) ω -
        {ω | η ω = -1}.indicator (fun _ => (1 : ℝ)) ω := by
    filter_upwards [hae] with ω hω
    rcases hω with h | h <;> simp [Set.indicator, h] <;> norm_num
  rw [integral_congr_ae heq,
    integral_sub ((integrable_const (1 : ℝ)).indicator hA) ((integrable_const (1 : ℝ)).indicator hB),
    integral_indicator hA, integral_indicator hB]
  simp only [integral_const, smul_eq_mul, mul_one, measureReal_def, Measure.restrict_apply_univ,
    hwin, hlose, ENNReal.toReal_ofReal hp0, ENNReal.toReal_ofReal (by linarith : (0:ℝ) ≤ 1 - p)]
  ring

/-- The gambler's record up to round `n` only depends on the tosses before round `n`. -/
lemma natural_le_past
    {Ω : Type*} [MeasurableSpace Ω] (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (x₀ : ℝ) (n : ℕ) :
    Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n
      ≤ ⨆ i ∈ {i : ℕ | i < n}, MeasurableSpace.comap (ξ i) inferInstance := by
  refine iSup₂_le fun j hj => ?_
  have hG : ∀ i < n,
      Measurable[⨆ i ∈ {i : ℕ | i < n}, MeasurableSpace.comap (ξ i) inferInstance] (ξ i) :=
    fun i hi => measurable_iff_comap_le.2
      (le_iSup₂ (f := fun i (_ : i ∈ {i : ℕ | i < n}) => MeasurableSpace.comap (ξ i) inferInstance)
        i hi)
  have hX : Measurable[⨆ i ∈ {i : ℕ | i < n}, MeasurableSpace.comap (ξ i) inferInstance]
      (fun ω => x₀ + ∑ i ∈ range j, ξ i ω) := by
    refine Measurable.const_add ?_ _
    exact Finset.measurable_sum _ fun i hi => hG i (lt_of_lt_of_le (mem_range.1 hi) hj)
  exact measurable_iff_comap_le.1 hX

/-- The next toss is independent of the record so far, so its conditional mean is its mean. -/
lemma condExp_next_toss
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P) (x₀ : ℝ) (n : ℕ) :
    P[ξ n | Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n]
      =ᵐ[P] fun _ => ∫ ω, ξ n ω ∂P := by
  have h := indep_iSup_of_disjoint (m := fun i => MeasurableSpace.comap (ξ i) inferInstance)
    (fun i => (hξm i).comap_le) hind.iIndep (S := {n}) (T := {i | i < n})
    (Set.disjoint_singleton_left.2 (lt_irrefl n))
  have h1 : Indep (MeasurableSpace.comap (ξ n) inferInstance)
      (⨆ i ∈ {i : ℕ | i < n}, MeasurableSpace.comap (ξ i) inferInstance) P :=
    indep_of_indep_of_le_left h
      (le_iSup₂ (f := fun i (_ : i ∈ ({n} : Set ℕ)) => MeasurableSpace.comap (ξ i) inferInstance)
        n rfl)
  have h2 := indep_of_indep_of_le_right h1 (natural_le_past ξ hξm x₀ n)
  exact condExp_indep_eq (hξm n).comap_le (Filtration.le _ n)
    (comap_measurable (ξ n)).stronglyMeasurable h2
/-- If every toss is `±1` almost surely, the fortune after `n` rounds is at most `|x₀| + n` in size. -/
lemma fortune_bound
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (ξ : ℕ → Ω → ℝ)
    (hae : ∀ i, ∀ᵐ ω ∂P, ξ i ω = 1 ∨ ξ i ω = -1) (x₀ : ℝ) (n : ℕ) :
    ∀ᵐ ω ∂P, |x₀ + ∑ i ∈ range n, ξ i ω| ≤ |x₀| + n := by
  filter_upwards [ae_all_iff.2 hae] with ω hω
  have h1 : ∀ i, |ξ i ω| = 1 := fun i => by rcases hω i with h | h <;> simp [h]
  calc |x₀ + ∑ i ∈ range n, ξ i ω| ≤ |x₀| + |∑ i ∈ range n, ξ i ω| := abs_add_le _ _
    _ ≤ |x₀| + ∑ i ∈ range n, |ξ i ω| := by gcongr; exact abs_sum_le_sum_abs _ _
    _ = |x₀| + n := by simp [h1]

/-- Each toss is integrable. -/
lemma toss_integrable
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i))
    (hae : ∀ i, ∀ᵐ ω ∂P, ξ i ω = 1 ∨ ξ i ω = -1) (i : ℕ) :
    Integrable (ξ i) P :=
  Integrable.of_bound (hξm i).aestronglyMeasurable 1
    (by filter_upwards [hae i] with ω hω; rcases hω with h | h <;> simp [h])

/-- The fortune after `n` rounds is integrable. -/
lemma fortune_integrable
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i))
    (hae : ∀ i, ∀ᵐ ω ∂P, ξ i ω = 1 ∨ ξ i ω = -1) (x₀ : ℝ) (n : ℕ) :
    Integrable (fun ω => x₀ + ∑ i ∈ range n, ξ i ω) P :=
  Integrable.of_bound (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).aestronglyMeasurable
    (|x₀| + n)
    (by filter_upwards [fortune_bound P ξ hae x₀ n] with ω hω; simpa [Real.norm_eq_abs] using hω)

/-- One step forward: given the record so far, the next fortune is forecast as today's fortune
plus the mean gain `μ` of a round. -/
lemma condExp_fortune_succ
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hae : ∀ i, ∀ᵐ ω ∂P, ξ i ω = 1 ∨ ξ i ω = -1) (μ : ℝ) (hmean : ∀ i, ∫ ω, ξ i ω ∂P = μ)
    (x₀ : ℝ) (n : ℕ) :
    P[(fun ω => x₀ + ∑ i ∈ range (n + 1), ξ i ω) |
        Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
          (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n]
      =ᵐ[P] fun ω => x₀ + ∑ i ∈ range n, ξ i ω + μ := by
  have hsplit : (fun ω => x₀ + ∑ i ∈ range (n + 1), ξ i ω)
      = (fun ω => x₀ + ∑ i ∈ range n, ξ i ω) + ξ n := by
    funext ω
    simp only [sum_range_succ, Pi.add_apply]
    ring
  have hadp := Filtration.stronglyAdapted_natural
    (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable)
  rw [hsplit]
  filter_upwards [condExp_add (fortune_integrable P ξ hξm hae x₀ n) (toss_integrable P ξ hξm hae n)
      (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n),
    condExp_next_toss P ξ hξm hind x₀ n] with ω h1 h2
  rw [h1, Pi.add_apply, h2, condExp_of_stronglyMeasurable (Filtration.le _ n) (hadp n)
    (fortune_integrable P ξ hξm hae x₀ n), hmean n]

/-- The tilted fortune, proved here so the fair case can use it. -/
lemma tilted_core
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hwin : ∀ i, P {ω | ξ i ω = 1} = ENNReal.ofReal p)
    (hlose : ∀ i, P {ω | ξ i ω = -1} = ENNReal.ofReal (1 - p))
    (x₀ : ℝ) :
    Martingale (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω - n * (2 * p - 1))
        (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
          (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable))
        P ∧
      (p ≤ 1 / 2 →
        Supermartingale (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
          (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
            (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable))
          P) := by
  have hae : ∀ i, ∀ᵐ ω ∂P, ξ i ω = 1 ∨ ξ i ω = -1 := fun i =>
    (pm_one_ae_and_integral P (ξ i) (hξm i) p hp0 hp1 (hwin i) (hlose i)).1
  have hmean : ∀ i, ∫ ω, ξ i ω ∂P = 2 * p - 1 := fun i =>
    (pm_one_ae_and_integral P (ξ i) (hξm i) p hp0 hp1 (hwin i) (hlose i)).2
  have hadp := Filtration.stronglyAdapted_natural
    (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable)
  have hstep := condExp_fortune_succ P ξ hξm hind hae (2 * p - 1) hmean x₀
  refine ⟨?_, fun _ => ?_⟩
  · refine martingale_nat (fun n => (hadp n).sub stronglyMeasurable_const)
      (fun n => (fortune_integrable P ξ hξm hae x₀ n).sub (integrable_const _)) (fun n => ?_)
    have e : (fun ω => x₀ + ∑ i ∈ range (n + 1), ξ i ω - ((n + 1 : ℕ) : ℝ) * (2 * p - 1))
        = (fun ω => x₀ + ∑ i ∈ range (n + 1), ξ i ω) - fun _ => ((n + 1 : ℕ) : ℝ) * (2 * p - 1) :=
      rfl
    show _ =ᵐ[P] P[fun ω => x₀ + ∑ i ∈ range (n + 1), ξ i ω - ((n + 1 : ℕ) : ℝ) * (2 * p - 1) | _]
    rw [e]
    filter_upwards [condExp_sub (fortune_integrable P ξ hξm hae x₀ (n + 1)) (integrable_const _)
      (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n),
      hstep n] with ω h1 h2
    rw [h1, Pi.sub_apply, h2, condExp_const (Filtration.le _ n)]
    push_cast
    ring
  · refine supermartingale_nat hadp (fortune_integrable P ξ hξm hae x₀) fun n => ?_
    filter_upwards [hstep n] with ω h
    show P[fun ω => x₀ + ∑ i ∈ range (n + 1), ξ i ω | _] ω ≤ x₀ + ∑ i ∈ range n, ξ i ω
    rw [h]
    linarith

/-- **The fair fortune is a martingale.** The rounds are independent tosses `ξ 0, ξ 1, ...`,
each `+1` (a win) with chance `1/2` and `-1` (a loss) with chance `1/2`. The fortune after
`n` rounds is `X n = x₀ + ξ 0 + ... + ξ (n-1)`. Relative to the gambler's own record (the
filtration generated by the fortunes so far, which is the record of the tosses so far), the
fortune is a martingale: adapted, integrable, and `E[X (n+1) | ℱ n] = X n`. -/
theorem fair_fortune_is_martingale
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hwin : ∀ i, P {ω | ξ i ω = 1} = 1 / 2) (hlose : ∀ i, P {ω | ξ i ω = -1} = 1 / 2)
    (x₀ : ℝ) :
    Martingale (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
      (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable))
      P := by
  have hwin' : ∀ i, P {ω | ξ i ω = 1} = ENNReal.ofReal (1 / 2) := fun i => by
    rw [hwin i, ENNReal.ofReal_div_of_pos two_pos]; simp
  have hlose' : ∀ i, P {ω | ξ i ω = -1} = ENNReal.ofReal (1 - 1 / 2) := fun i => by
    rw [hlose i, show (1 : ℝ) - 1 / 2 = 1 / 2 by norm_num, ENNReal.ofReal_div_of_pos two_pos]; simp
  have h := (tilted_core P ξ hξm hind (1 / 2) (by norm_num)
    (by norm_num) hwin' hlose' x₀).1
  have e : (fun (n : ℕ) ω => x₀ + ∑ i ∈ range n, ξ i ω - n * (2 * (1 / 2 : ℝ) - 1))
      = fun n ω => x₀ + ∑ i ∈ range n, ξ i ω := by
    funext n ω
    norm_num
  rw [e] at h
  exact h

/-- **The squared fortune minus the rounds is a martingale.** In the same fair game, with the
same filtration (the gambler's own record), `Y n = (X n)^2 - n` is a martingale:
`E[(X (n+1))^2 - (n+1) | ℱ n] = (X n)^2 - n`. -/
theorem fair_fortune_sq_sub_rounds_is_martingale
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (hwin : ∀ i, P {ω | ξ i ω = 1} = 1 / 2) (hlose : ∀ i, P {ω | ξ i ω = -1} = 1 / 2)
    (x₀ : ℝ) :
    Martingale (fun n ω => (x₀ + ∑ i ∈ range n, ξ i ω) ^ 2 - n)
      (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable))
      P := by
  have hwin' : ∀ i, P {ω | ξ i ω = 1} = ENNReal.ofReal (1 / 2) := fun i => by
    rw [hwin i, ENNReal.ofReal_div_of_pos two_pos]; simp
  have hlose' : ∀ i, P {ω | ξ i ω = -1} = ENNReal.ofReal (1 - 1 / 2) := fun i => by
    rw [hlose i, show (1 : ℝ) - 1 / 2 = 1 / 2 by norm_num, ENNReal.ofReal_div_of_pos two_pos]; simp
  have hae : ∀ i, ∀ᵐ ω ∂P, ξ i ω = 1 ∨ ξ i ω = -1 := fun i =>
    (pm_one_ae_and_integral P (ξ i) (hξm i) (1 / 2) (by norm_num) (by norm_num)
      (hwin' i) (hlose' i)).1
  have hmean : ∀ i, ∫ ω, ξ i ω ∂P = 0 := fun i => by
    rw [(pm_one_ae_and_integral P (ξ i) (hξm i) (1 / 2) (by norm_num) (by norm_num)
      (hwin' i) (hlose' i)).2]
    norm_num
  have hadp := Filtration.stronglyAdapted_natural
    (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable)
  have hYadp : ∀ n : ℕ, StronglyMeasurable[Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
      (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n]
      (fun ω => (x₀ + ∑ i ∈ range n, ξ i ω) ^ 2 - (n : ℝ)) :=
    fun n => ((hadp n).pow 2).sub stronglyMeasurable_const
  have hYint : ∀ n : ℕ, Integrable (fun ω => (x₀ + ∑ i ∈ range n, ξ i ω) ^ 2 - (n : ℝ)) P := by
    intro n
    refine Integrable.of_bound
      (by fun_prop : Measurable fun ω => (x₀ + ∑ i ∈ range n, ξ i ω) ^ 2 - (n : ℝ)).aestronglyMeasurable
      ((|x₀| + n) ^ 2 + n) ?_
    filter_upwards [fortune_bound P ξ hae x₀ n] with ω hω
    rw [Real.norm_eq_abs]
    have h2 : (x₀ + ∑ i ∈ range n, ξ i ω) ^ 2 ≤ (|x₀| + n) ^ 2 := by
      rw [← sq_abs]
      exact pow_le_pow_left₀ (abs_nonneg _) hω 2
    have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    exact abs_le.2 ⟨by nlinarith [sq_nonneg (x₀ + ∑ i ∈ range n, ξ i ω), sq_nonneg (|x₀| + n)],
      by linarith⟩
  refine martingale_nat hYadp hYint (fun n => ?_)
  have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
  have hY : (fun ω => (x₀ + ∑ i ∈ range (n + 1), ξ i ω) ^ 2 - ((n + 1 : ℕ) : ℝ)) =ᵐ[P]
      (fun ω => (x₀ + ∑ i ∈ range n, ξ i ω) ^ 2 - (n : ℝ)) +
        (fun ω => 2 * (x₀ + ∑ i ∈ range n, ξ i ω)) * ξ n := by
    filter_upwards [hae n] with ω hω
    have hsq : ξ n ω ^ 2 = 1 := by rcases hω with h | h <;> simp [h]
    simp only [Pi.add_apply, Pi.mul_apply, sum_range_succ]
    push_cast
    linear_combination hsq
  have hbound : ∀ᵐ ω ∂P, ‖2 * (x₀ + ∑ i ∈ range n, ξ i ω)‖ ≤ 2 * (|x₀| + n) := by
    filter_upwards [fortune_bound P ξ hae x₀ n] with ω hω
    rw [Real.norm_eq_abs, abs_mul]
    norm_num
    exact hω
  have hint2 : Integrable ((fun ω => 2 * (x₀ + ∑ i ∈ range n, ξ i ω)) * ξ n) P := by
    refine Integrable.of_bound
      ((by fun_prop : Measurable fun ω => 2 * (x₀ + ∑ i ∈ range n, ξ i ω)).mul
        (hξm n)).aestronglyMeasurable (2 * (|x₀| + n)) ?_
    filter_upwards [hbound, hae n] with ω h1 h2
    rw [Pi.mul_apply, norm_mul]
    rcases h2 with h | h <;> simpa [h] using h1
  show _ =ᵐ[P] P[fun ω => (x₀ + ∑ i ∈ range (n + 1), ξ i ω) ^ 2 - ((n + 1 : ℕ) : ℝ) | _]
  filter_upwards [condExp_congr_ae (m := Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n)
      hY,
    condExp_add (hYint n) hint2 (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
        (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable) n),
    condExp_stronglyMeasurable_mul_of_bound (Filtration.le _ n) ((hadp n).const_mul 2)
      (toss_integrable P ξ hξm hae n) (2 * (|x₀| + n)) hbound,
    condExp_next_toss P ξ hξm hind x₀ n] with ω h1 h2 h3 h4
  rw [h1, h2, Pi.add_apply, h3, Pi.mul_apply, h4, hmean n,
    condExp_of_stronglyMeasurable (Filtration.le _ n) (hYadp n) (hYint n)]
  simp

/-- **The tilted fortune.** If each independent round is won (`+1`) with chance `p` and lost
(`-1`) with chance `1 - p`, the average gain per round is `μ = 2p - 1`. Relative to the
gambler's own record, the fortune minus its drift, `X n - n μ`, is a martingale; and when the
odds are at or below even (`p ≤ 1/2`, so `μ ≤ 0`, as on red at roulette with `p = 18/37`),
the fortune itself is a supermartingale. -/
theorem tilted_fortune_drift_and_supermartingale
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (ξ : ℕ → Ω → ℝ) (hξm : ∀ i, Measurable (ξ i)) (hind : iIndepFun ξ P)
    (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1)
    (hwin : ∀ i, P {ω | ξ i ω = 1} = ENNReal.ofReal p)
    (hlose : ∀ i, P {ω | ξ i ω = -1} = ENNReal.ofReal (1 - p))
    (x₀ : ℝ) :
    Martingale (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω - n * (2 * p - 1))
        (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
          (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable))
        P ∧
      (p ≤ 1 / 2 →
        Supermartingale (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
          (Filtration.natural (fun n ω => x₀ + ∑ i ∈ range n, ξ i ω)
            (fun n => (by fun_prop : Measurable fun ω => x₀ + ∑ i ∈ range n, ξ i ω).stronglyMeasurable))
          P) := by
  exact tilted_core P ξ hξm hind p hp0 hp1 hwin hlose x₀

-- From $12 the next fortune is $13 or $11, each with chance 1/2: the average is $12.
example : ((13 + 11 : ℚ) / 2) = 12 := by norm_num
-- Its square: 169 or 121, averaging 145 = 144 + 1.
example : (13 : ℕ) ^ 2 = 169 ∧ (11 : ℕ) ^ 2 = 121 := by decide
example : ((169 + 121 : ℚ) / 2) = 12 ^ 2 + 1 := by norm_num
-- Square minus rounds is unchanged from round n to n + 1: (144 - n) against (145 - (n + 1)).
example (n : ℤ) : (145 : ℤ) - (n + 1) = 144 - n := by ring
-- All 1024 records of 10 rounds: with k wins out of 10 the fortune is 10 + k - (10 - k) = 2k,
-- and the average of the squared fortune is 110.
example : (2 : ℕ) ^ 10 = 1024 := by decide
example : ∑ k ∈ range 11, Nat.choose 10 k * (2 * k) ^ 2 = 110 * 1024 := by decide
-- Spread after 10 rounds: 110 - 10 × 10 = 10.
example : (110 - 10 * 10 : ℤ) = 10 := by norm_num
-- Roulette: p = 18/37, so μ = 2p - 1 = -1/37; from $10, one round forecasts 10 - 1/37 and
-- 100 rounds forecast 10 - 100/37 = 270/37.
example : (2 * (18 / 37 : ℚ) - 1) = -1 / 37 := by norm_num
example : ((10 : ℚ) - 100 / 37) = 270 / 37 := by norm_num
-- The bent function (19/18)^X straightens roulette: its one-round factor is
-- (18/37)(19/18) + (19/37)(18/19) = 1.
example : (18 / 37 : ℚ) * (19 / 18) + (19 / 37) * (18 / 19) = 1 := by norm_num

#print axioms pm_one_ae_and_integral
#print axioms natural_le_past
#print axioms condExp_next_toss
#print axioms fortune_bound
#print axioms toss_integrable
#print axioms fortune_integrable
#print axioms condExp_fortune_succ
#print axioms tilted_core
#print axioms fair_fortune_is_martingale
#print axioms fair_fortune_sq_sub_rounds_is_martingale
#print axioms tilted_fortune_drift_and_supermartingale
