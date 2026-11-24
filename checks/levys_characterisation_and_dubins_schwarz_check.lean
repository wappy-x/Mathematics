-- Levy's characterisation and Dubins-Schwarz: a continuous process starting at 0 whose exponential exp(i θ M_t + θ² t / 2) is a fair game for every θ is a Brownian motion with moves independent of the past, a known sign times a fair coin walk has the plain walk's law, and the doubler's gain 2 W read on the clock 4t is a Brownian motion.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Data.Nat.Factorial.DoubleFactorial

open MeasureTheory ProbabilityTheory
open scoped NNReal ENNReal

lemma levy_aux_integral
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hadapt : StronglyAdapted ℱ M)
    (hexp : ∀ θ : ℝ, Martingale
      (fun t ω ↦ Complex.exp (Complex.I * θ * M t ω + (θ ^ 2 * t / 2 : ℝ))) ℱ P)
    {s t : ℝ≥0} (hst : s ≤ t) {A : Set Ω} (hA : MeasurableSet[ℱ s] A) (θ : ℝ) :
    ∫ ω in A, Complex.exp (θ * ((M t ω - M s ω : ℝ) : ℂ) * Complex.I) ∂P
      = (P.real A) * Complex.exp (- (((t : ℝ) - s) * θ ^ 2 / 2)) := by
  have hmart := hexp θ
  set Z : ℝ≥0 → Ω → ℂ :=
    fun t ω ↦ Complex.exp (Complex.I * θ * M t ω + (θ ^ 2 * t / 2 : ℝ)) with hZ
  set g : Ω → ℂ := A.indicator
    (fun ω ↦ Complex.exp (-(Complex.I * θ * M s ω) - (θ ^ 2 * t / 2 : ℝ))) with hg
  have hg_meas : StronglyMeasurable[ℱ s] g := by
    refine StronglyMeasurable.indicator ?_ hA
    exact (by fun_prop : Continuous fun x : ℝ ↦
      Complex.exp (-(Complex.I * θ * x) - (θ ^ 2 * t / 2 : ℝ))).comp_stronglyMeasurable (hadapt s)
  have hg_bound : ∀ ω, ‖g ω‖ ≤ 1 := by
    intro ω
    by_cases h : ω ∈ A
    · simp only [hg, Set.indicator_of_mem h, Complex.norm_exp]
      rw [Real.exp_le_one_iff]
      simp
      rw [← Complex.ofReal_pow, Complex.ofReal_re]
      positivity
    · simp [hg, Set.indicator_of_notMem h]
  have hint_t : Integrable (fun ω ↦ g ω * Z t ω) P :=
    (hmart.integrable t).bdd_mul ((hg_meas.mono (ℱ.le s)).aestronglyMeasurable)
      (ae_of_all _ hg_bound)
  have key : ∫ ω, g ω * Z t ω ∂P = ∫ ω, g ω * Z s ω ∂P := by
    rw [← integral_condExp (ℱ.le s) (f := fun ω ↦ g ω * Z t ω)]
    have h1 := condExp_bilin_of_stronglyMeasurable_left (m := ℱ s) (μ := P)
      (ContinuousLinearMap.mul ℝ ℂ) hg_meas (g := Z t) (by simpa using hint_t)
      (hmart.integrable t)
    simp only [ContinuousLinearMap.mul_apply'] at h1
    rw [integral_congr_ae h1]
    apply integral_congr_ae
    filter_upwards [hmart.condExp_ae_eq hst] with ω hω
    rw [hω]
  have hAm : MeasurableSet A := ℱ.le s A hA
  have e1 : (fun ω ↦ g ω * Z t ω) =
      A.indicator (fun ω ↦ Complex.exp (θ * ((M t ω - M s ω : ℝ) : ℂ) * Complex.I)) := by
    funext ω
    by_cases h : ω ∈ A
    · simp only [hg, hZ, Set.indicator_of_mem h, ← Complex.exp_add]
      congr 1
      push_cast
      ring
    · simp [hg, Set.indicator_of_notMem h]
  have e2 : (fun ω ↦ g ω * Z s ω) =
      A.indicator (fun _ ↦ Complex.exp (- (((t : ℝ) - s) * θ ^ 2 / 2))) := by
    funext ω
    by_cases h : ω ∈ A
    · simp only [hg, hZ, Set.indicator_of_mem h, ← Complex.exp_add]
      congr 1
      push_cast
      ring
    · simp [hg, Set.indicator_of_notMem h]
  rw [e1, e2, integral_indicator hAm, integral_indicator hAm, setIntegral_const] at key
  rw [key, Complex.real_smul]

#print axioms levy_aux_integral

lemma levy_aux_cond
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hadapt : StronglyAdapted ℱ M)
    (hexp : ∀ θ : ℝ, Martingale
      (fun t ω ↦ Complex.exp (Complex.I * θ * M t ω + (θ ^ 2 * t / 2 : ℝ))) ℱ P)
    {s t : ℝ≥0} (hst : s ≤ t) {A : Set Ω} (hA : MeasurableSet[ℱ s] A) (hA0 : P A ≠ 0) :
    (ProbabilityTheory.cond P A).map (fun ω ↦ M t ω - M s ω) = gaussianReal 0 (t - s) := by
  have hmeas : ∀ u, Measurable (M u) := fun u ↦ (hadapt u).measurable.mono (ℱ.le u) le_rfl
  have hX : Measurable (fun ω ↦ M t ω - M s ω) := (hmeas t).sub (hmeas s)
  apply Measure.ext_of_charFun
  funext θ
  rw [charFun_apply_real, charFun_gaussianReal,
    integral_map hX.aemeasurable (by fun_prop), ProbabilityTheory.cond, integral_smul_measure,
    levy_aux_integral hadapt hexp hst hA θ]
  have hreal : P.real A ≠ 0 := by
    rw [measureReal_def, ENNReal.toReal_ne_zero]
    exact ⟨hA0, measure_ne_top _ _⟩
  rw [Complex.real_smul, ENNReal.toReal_inv, ← mul_assoc, ← measureReal_def, ← Complex.ofReal_mul,
    inv_mul_cancel₀ hreal, Complex.ofReal_one, one_mul]
  congr 1
  push_cast [NNReal.coe_sub hst]
  ring

#print axioms levy_aux_cond

lemma levy_aux_incr
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hmeasF : ∀ u, Measurable[ℱ u] (M u))
    (hind : ∀ s t : ℝ≥0, s ≤ t →
        Indep (MeasurableSpace.comap (fun ω ↦ M t ω - M s ω) inferInstance) (ℱ s) P) :
    HasIndepIncrements M P := by
  intro n τ hτ
  rw [iIndepFun_iff_measure_inter_preimage_eq_mul]
  intro S
  induction S using Finset.induction_on_max with
  | empty => intro sets _; simp
  | insert a S hlt ih =>
    intro sets H
    have haS : a ∉ S := fun h ↦ lt_irrefl a (hlt a h)
    have hS : MeasurableSet[ℱ (τ a.castSucc)]
        (⋂ i ∈ S, (fun ω ↦ M (τ i.succ) ω - M (τ i.castSucc) ω) ⁻¹' sets i) := by
      refine Finset.measurableSet_biInter S (fun i hi ↦ ?_)
      have hle : τ i.succ ≤ τ a.castSucc := hτ (Fin.succ_le_castSucc_iff.2 (hlt i hi))
      have hm : Measurable[ℱ (τ i.succ)] (fun ω ↦ M (τ i.succ) ω - M (τ i.castSucc) ω) :=
        (hmeasF _).sub ((hmeasF _).mono (ℱ.mono (hτ (Fin.castSucc_le_succ i))) le_rfl)
      exact (hm.mono (ℱ.mono hle) le_rfl) (H i (Finset.mem_insert_of_mem hi))
    rw [Finset.set_biInter_insert, Finset.prod_insert haS,
      (Indep_iff _ _ P).1 (hind _ _ (hτ (Fin.castSucc_le_succ a))) _ _
        ⟨sets a, H a (Finset.mem_insert_self a S), rfl⟩ hS,
      ih (fun i hi ↦ H i (Finset.mem_insert_of_mem hi))]

#print axioms levy_aux_incr

/-- **Levy's characterisation, from the exponential martingale (Steps 1 to 4).** Let `M` be a
process adapted to the information `ℱ`, with continuous paths and `M_0 = 0`, such that for every
real frequency `θ` the tilted exponential `Z_t = exp(i θ M_t + θ² t / 2)` is a fair game
(a martingale) for that same information. This is what a clock reading exactly `t` gives
(Steps 1 and 2). Then `M` is a Brownian motion, and each move `M_t - M_s` is independent of
everything known at time `s`, not just of the game's own past. -/
theorem levy_characterisation_of_exponential_martingale
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} [IsProbabilityMeasure P]
    {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hadapt : StronglyAdapted ℱ M) (hcont : ∀ ω, Continuous (fun t ↦ M t ω))
    (hzero : ∀ ω, M 0 ω = 0)
    (hexp : ∀ θ : ℝ, Martingale
      (fun t ω ↦ Complex.exp (Complex.I * θ * M t ω + (θ ^ 2 * t / 2 : ℝ))) ℱ P) :
    IsBrownianReal M P ∧
      ∀ s t : ℝ≥0, s ≤ t →
        Indep (MeasurableSpace.comap (fun ω ↦ M t ω - M s ω) inferInstance) (ℱ s) P := by
  have hmeasF : ∀ u, Measurable[ℱ u] (M u) := fun u ↦ (hadapt u).measurable
  have hmeas : ∀ u, Measurable (M u) := fun u ↦ (hmeasF u).mono (ℱ.le u) le_rfl
  have hX : ∀ s t, Measurable (fun ω ↦ M t ω - M s ω) := fun s t ↦ (hmeas t).sub (hmeas s)
  have key : ∀ s t, s ≤ t → ∀ A, MeasurableSet[ℱ s] A → ∀ B, MeasurableSet B →
      P (A ∩ (fun ω ↦ M t ω - M s ω) ⁻¹' B) = P A * gaussianReal 0 (t - s) B := by
    intro s t hst A hA B hB
    by_cases hA0 : P A = 0
    · rw [hA0, zero_mul]
      exact measure_mono_null Set.inter_subset_left hA0
    · have h2 := congrArg (fun μ : Measure ℝ ↦ μ B) (levy_aux_cond hadapt hexp hst hA hA0)
      rw [Measure.map_apply (hX s t) hB, ProbabilityTheory.cond_apply (ℱ.le s A hA)] at h2
      rw [← h2, ← mul_assoc, ENNReal.mul_inv_cancel hA0 (measure_ne_top _ _), one_mul]
  have law : ∀ s t, s ≤ t → P.map (fun ω ↦ M t ω - M s ω) = gaussianReal 0 (t - s) := by
    intro s t hst
    refine Measure.ext fun B hB ↦ ?_
    rw [Measure.map_apply (hX s t) hB]
    simpa using key s t hst Set.univ MeasurableSet.univ B hB
  have indep : ∀ s t : ℝ≥0, s ≤ t →
      Indep (MeasurableSpace.comap (fun ω ↦ M t ω - M s ω) inferInstance) (ℱ s) P := by
    intro s t hst
    rw [Indep_iff]
    rintro _ A ⟨B, hB, rfl⟩ hA
    rw [Set.inter_comm, key s t hst A hA B hB, mul_comm, ← Measure.map_apply (hX s t) hB,
      law s t hst]
  refine ⟨⟨?_, ae_of_all _ hcont⟩, indep⟩
  apply HasIndepIncrements.isPreBrownianReal_of_hasLaw
  · intro t
    refine ⟨(hmeas t).aemeasurable, ?_⟩
    have h0 := law 0 t zero_le
    simpa [hzero] using h0
  · exact levy_aux_incr hmeasF indep

/-- One coin flip as a move of `+1` (heads) or `-1` (tails). -/
def coinMove (b : Bool) : ℤ := if b then 1 else -1

/-- The plain coin-flip walk after the first `k` flips: `S_k = ξ_1 + ... + ξ_k`. -/
def coinWalk {n : ℕ} (ξ : Fin n → Bool) (k : ℕ) : ℤ :=
  ∑ j : Fin n, if (j : ℕ) < k then coinMove (ξ j) else 0

/-- The switcher's total: each flip times the sign of the walk just before it,
`+1` when `S_{k-1} ≥ 0` and `-1` below. -/
def switcherTotal {n : ℕ} (ξ : Fin n → Bool) : ℤ :=
  ∑ j : Fin n, (if 0 ≤ coinWalk ξ j then 1 else -1) * coinMove (ξ j)

/-- The switching map: flip coin `j` exactly when the walk before it is below zero. -/
def switchFlip {n : ℕ} (ξ : Fin n → Bool) (j : Fin n) : Bool :=
  if 0 ≤ coinWalk ξ j then ξ j else !(ξ j)

lemma coinWalk_switchFlip {n : ℕ} (ξ : Fin n → Bool) :
    coinWalk (switchFlip ξ) n = switcherTotal ξ := by
  unfold coinWalk switcherTotal
  refine Finset.sum_congr rfl (fun j _ ↦ ?_)
  simp only [j.isLt, ite_true, switchFlip]
  split_ifs <;> cases ξ j <;> simp [coinMove]

#print axioms coinWalk_switchFlip

lemma switchFlip_injective (n : ℕ) : Function.Injective (switchFlip (n := n)) := by
  intro ξ ξ' h
  have hk : ∀ k : ℕ, ∀ j : Fin n, (j : ℕ) < k → ξ j = ξ' j := by
    intro k
    induction k with
    | zero => intro j hj; omega
    | succ k ih =>
      intro j hj
      rcases Nat.lt_succ_iff_lt_or_eq.1 hj with hj | hj
      · exact ih j hj
      · have hw : coinWalk ξ j = coinWalk ξ' j := by
          unfold coinWalk
          refine Finset.sum_congr rfl (fun i _ ↦ ?_)
          split_ifs with hi
          · rw [ih i (hj ▸ hi)]
          · rfl
        have := congrFun h j
        simp only [switchFlip, hw] at this
        split_ifs at this
        · exact this
        · simpa using this
  funext j
  exact hk (j + 1) j (Nat.lt_succ_self _)

#print axioms switchFlip_injective

/-- **A fair coin times a known sign is a fair coin (Step 0).** For every number of flips `n`
and every total `m`, the number of the `2^n` flip sequences on which the switcher's total
equals `m` is the same as the number on which the plain walk's total equals `m`: the two
totals have exactly the same law. -/
theorem switcher_total_has_walk_law (n : ℕ) (m : ℤ) :
    (Finset.univ.filter (fun ξ : Fin n → Bool ↦ switcherTotal ξ = m)).card =
      (Finset.univ.filter (fun ξ : Fin n → Bool ↦ coinWalk ξ n = m)).card := by
  have hinj := switchFlip_injective n
  have hsurj : Function.Surjective (switchFlip (n := n)) := Finite.surjective_of_injective hinj
  refine Finset.card_nbij (switchFlip (n := n)) ?_ hinj.injOn ?_
  · intro ξ hξ
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hξ ⊢
    rw [coinWalk_switchFlip, hξ]
  · intro η hη
    obtain ⟨ξ, rfl⟩ := hsurj η
    refine ⟨ξ, ?_, rfl⟩
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hη ⊢
    rw [← coinWalk_switchFlip, hη]

/-- **The doubler on his own clock (Step 5).** If `W` is a Brownian motion, the doubler's gain
is `Y_t = 2 W_t`, whose clock reads `4t`. Read at the first moment its clock passes `s`,
that is at time `s / 4`, it gives `β_s = Y_{s/4} = 2 W_{s/4}`, and `β` is a Brownian motion. -/
theorem doubler_on_its_clock_is_brownian
    {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) :
    IsBrownianReal (fun s ω ↦ 2 * W (s / 4) ω) P := by
  have h := hW.smul (c := 1 / 4) (by norm_num)
  have hsq : (√((1 / 4 : ℝ≥0) : ℝ))⁻¹ = 2 := by
    have : ((1 / 4 : ℝ≥0) : ℝ) = (1 / 2) ^ 2 := by norm_num
    rw [this, Real.sqrt_sq (by norm_num)]
    norm_num
  have hfun : (fun s ω ↦ 2 * W (s / 4) ω) =
      (fun t ω ↦ (√((1 / 4 : ℝ≥0) : ℝ))⁻¹ * W (1 / 4 * t) ω) := by
    funext s ω
    rw [hsq, one_div_mul_eq_div]
  rw [hfun]
  exact h

/-! The card's whole-number worked examples, checked exactly. -/

-- Twelve flips: 4096 paths, and the walk's counts at totals -12, -10, ..., 12.
example : 2 ^ 12 = 4096 := by norm_num
example : (List.range 13).map (Nat.choose 12) =
    [1, 12, 66, 220, 495, 792, 924, 792, 495, 220, 66, 12, 1] := by decide
-- Total at least 4: (495 + 220 + 66 + 12 + 1) / 4096 = 794 / 4096.
example : 495 + 220 + 66 + 12 + 1 = 794 := by norm_num
example : (Finset.range 5).sum (Nat.choose 12) = 794 := by decide
-- The doubler's clock at one year: the holding 2, squared, over one year.
example : (2 : ℚ) ^ 2 * 1 = 4 := by norm_num
-- Normal moments E[Z^8], E[Z^6], E[Z^4], E[Z^2] are 7!!, 5!!, 3!!, 1!!.
example : Nat.doubleFactorial 7 = 105 ∧ Nat.doubleFactorial 5 = 15 ∧
    Nat.doubleFactorial 3 = 3 ∧ Nat.doubleFactorial 1 = 1 := by decide
-- E[(W_1^2 - 1)^4] = 105 - 60 + 18 - 4 + 1 = 60; over 16 it is E[X_1^4] = 3.75;
-- over E[X_1^2]^2 = 0.5^2 the fourth-moment ratio is 15.
example : (105 : ℚ) - 4 * 15 + 6 * 3 - 4 * 1 + 1 = 60 := by norm_num
example : (60 : ℚ) / 16 = 15 / 4 := by norm_num
example : ((15 : ℚ) / 4) / (1 / 2) ^ 2 = 15 := by norm_num

#print axioms levy_characterisation_of_exponential_martingale
#print axioms switcher_total_has_walk_law
#print axioms doubler_on_its_clock_is_brownian
