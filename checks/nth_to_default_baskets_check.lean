-- First-to-default and nth-to-default baskets: unconnected names with one flat hazard give a first default at the summed hazard, the chances of at least k defaults add up over k to the names' own default chances whatever the dependence, and the chance of at least one default lies between the riskiest name's chance and the sum of all of them.
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open MeasureTheory ProbabilityTheory Real Finset

/-! Setting, as on the card. The basket has `n` names; name `i` defaults at the random date
`τ i`, a measurable function on a probability space `(Ω, μ)`. "Name `i` has defaulted by `t`" is
the event `τ i ≤ t`, so `C_t`, the count of names defaulted by `t`, is the number of `i` with
`τ i ω ≤ t`, and the k-th default has happened by `t` exactly when `k ≤ C_t`.
`μ.real` is the chance of an event, as a real number. The one-factor Gaussian copula prices
(490.42 bp, 133.22 bp and the correlation sweep) come from a numerical integral and a simulation,
so they are not stated here; the exact parts are the unconnected limit (Step 1), the fixed total
(the detailed proof under Step 4) and the bounds on at least one default (Step 2). -/

/-- **Unconnected names: the first default comes at the summed hazard** (Step 1). Every name has
the same flat hazard `λ`, so its chance of surviving past any date `s ≥ 0` is `e^{-λ s}`. If the
`n` default dates are independent (correlation 0), the chance that no name has defaulted by `t`,
which is the first-to-default survival curve `Q_1(t)`, is `(e^{-λ t})^n = e^{-n λ t}`: the basket's
first default has a flat hazard `n λ` (10% for five names at 2%). -/
theorem first_to_default_survival_independent {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (n : ℕ) (τ : Fin n → Ω → ℝ) (lam : ℝ)
    (hmeas : ∀ i, Measurable (τ i)) (hind : iIndepFun τ μ)
    (hflat : ∀ i, ∀ s : ℝ, 0 ≤ s → μ.real {ω | s < τ i ω} = exp (-(lam * s))) :
    ∀ t : ℝ, 0 ≤ t → μ.real {ω | ∀ i, t < τ i ω} = exp (-((n * lam) * t)) := by
  intro t ht
  have hset : {ω | ∀ i, t < τ i ω} = ⋂ i ∈ (univ : Finset (Fin n)), τ i ⁻¹' Set.Ioi t := by
    ext ω; simp
  have key := hind.measure_inter_preimage_eq_mul (univ : Finset (Fin n))
    (sets := fun _ => Set.Ioi t) (fun i _ => measurableSet_Ioi)
  rw [hset, measureReal_def, key, ENNReal.toReal_prod]
  have hi : ∀ i, (μ (τ i ⁻¹' Set.Ioi t)).toReal = exp (-(lam * t)) := by
    intro i
    have := hflat i t ht
    rw [measureReal_def] at this
    exact this
  simp only [hi, prod_const, card_univ, Fintype.card_fin]
  rw [← Real.exp_nat_mul]
  ring_nf

/-- **The total is fixed** (Step 4, detailed proof). Whatever ties the names together, the
chances of at least `k` defaults by `t`, added over `k = 1, …, n`, equal the sum of the names' own
default chances by `t`: `∑_k (1 - Q_k(t)) = E[C_t] = ∑_i Pr(τ_i ≤ t)`, which is `n p(t)` for equal
names. Since each protection leg is linear in `1 - Q_k`, the `n` nth-to-default protection legs add
up to the `n` single-name protection legs at every correlation. -/
theorem nth_to_default_chances_sum_to_single_names {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (n : ℕ) (τ : Fin n → Ω → ℝ)
    (hmeas : ∀ i, Measurable (τ i)) (t : ℝ) :
    ∑ k ∈ Icc 1 n, μ.real {ω | k ≤ (univ.filter (fun i => τ i ω ≤ t)).card}
      = ∑ i, μ.real {ω | τ i ω ≤ t} := by
  set C : Ω → ℕ := fun ω => (univ.filter (fun i => τ i ω ≤ t)).card with hC
  have hB : ∀ i, MeasurableSet {ω | τ i ω ≤ t} := fun i => measurableSet_le (hmeas i) measurable_const
  have hCmeas : Measurable C := by
    have : C = fun ω => ∑ i, ({ω | τ i ω ≤ t} : Set Ω).indicator (fun _ => (1 : ℕ)) ω := by
      funext ω
      simp only [hC, Set.indicator_apply, Set.mem_ofPred_eq, sum_boole, Nat.cast_id]
    rw [this]
    exact Finset.measurable_sum _ (fun i _ => (measurable_const.indicator (hB i)))
  have hA : ∀ k : ℕ, MeasurableSet {ω | k ≤ C ω} := fun k => measurableSet_le measurable_const hCmeas
  have hCle : ∀ ω, C ω ≤ n := fun ω => by
    simpa using card_filter_le (univ : Finset (Fin n)) (fun i => τ i ω ≤ t)
  have lhs : ∀ k, μ.real {ω | k ≤ C ω} = ∫ ω, ({ω | k ≤ C ω} : Set Ω).indicator 1 ω ∂μ :=
    fun k => (integral_indicator_one (hA k)).symm
  have rhs : ∀ i, μ.real {ω | τ i ω ≤ t} = ∫ ω, ({ω | τ i ω ≤ t} : Set Ω).indicator 1 ω ∂μ :=
    fun i => (integral_indicator_one (hB i)).symm
  show ∑ k ∈ Icc 1 n, μ.real {ω | k ≤ C ω} = _
  rw [Finset.sum_congr rfl (fun k _ => lhs k), Finset.sum_congr rfl (fun i _ => rhs i)]
  rw [← integral_finsetSum _ (fun k _ => show Integrable (({ω | k ≤ C ω} : Set Ω).indicator (1 : Ω → ℝ)) μ from
      (integrable_const (1:ℝ)).indicator (hA k)),
    ← integral_finsetSum _ (fun i _ => show Integrable (({ω | τ i ω ≤ t} : Set Ω).indicator (1 : Ω → ℝ)) μ from
      (integrable_const (1:ℝ)).indicator (hB i))]
  congr 1
  funext ω
  simp only [Set.indicator_apply, Set.mem_ofPred_eq, Pi.one_apply, sum_boole]
  congr 1
  rw [show (Icc 1 n).filter (fun k => k ≤ C ω) = Icc 1 (C ω) by
    ext k; simp only [mem_filter, mem_Icc]; constructor
    · rintro ⟨⟨h1, _⟩, h2⟩; exact ⟨h1, h2⟩
    · rintro ⟨h1, h2⟩; exact ⟨⟨h1, h2.trans (hCle ω)⟩, h2⟩]
  simp [hC]

/-- **At least one default, under any dependence** (Step 2). The chance that at least one name
has defaulted by `t` is at least each single name's own chance, because that name's default alone
counts, and at most the sum of the names' chances, because adding counts a joint default more than
once. -/
theorem first_default_chance_between_max_and_sum {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (n : ℕ) (τ : Fin n → Ω → ℝ) (t : ℝ) :
    (∀ i, μ.real {ω | τ i ω ≤ t} ≤ μ.real {ω | ∃ i, τ i ω ≤ t}) ∧
      μ.real {ω | ∃ i, τ i ω ≤ t} ≤ ∑ i, μ.real {ω | τ i ω ≤ t} := by
  refine ⟨fun i => measureReal_mono (fun ω hω => ⟨i, hω⟩), ?_⟩
  have : {ω | ∃ i, τ i ω ≤ t} = ⋃ i, {ω | τ i ω ≤ t} := by ext ω; simp
  rw [this]
  exact measureReal_iUnion_fintype_le _

-- Card, Step 1: five names at a 2% hazard give a first-default hazard of 5 × 2% = 10%.
example : (5 : ℚ) * (2 / 100) = 10 / 100 := by norm_num
-- Card, detailed proof: for any count c of defaults among five names, the number of k from 1 to 5
-- with c ≥ k is c itself.
example : ∀ c ∈ Finset.range 6, ((Finset.Icc 1 5).filter (fun k => k ≤ c)).card = c := by decide
-- Card, Step 4: "at least two of five" given the economy is 1 - (1-q)^5 - 5q(1-q)^4
-- = 10q² - 20q³ + 15q⁴ - 4q⁵, whose second derivative 20 - 120q + 180q² - 80q³ is 20(1-q)²(1-4q).
example (q : ℚ) : 1 - (1 - q) ^ 5 - 5 * q * (1 - q) ^ 4 = 10 * q ^ 2 - 20 * q ^ 3 + 15 * q ^ 4 - 4 * q ^ 5 := by
  ring
example (q : ℚ) : 20 - 120 * q + 180 * q ^ 2 - 80 * q ^ 3 = 20 * (1 - q) ^ 2 * (1 - 4 * q) := by
  ring
-- Card, Step 4: the bend changes sign where 1 - 4q = 0, at q = 25%.
example : (1 : ℚ) - 4 * (25 / 100) = 0 := by norm_num

#print axioms first_to_default_survival_independent
#print axioms nth_to_default_chances_sum_to_single_names
#print axioms first_default_chance_between_max_and_sum
