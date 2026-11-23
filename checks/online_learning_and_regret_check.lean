-- Regret: the weighted-majority rule, with every loss between 0 and 1 and learning rate √(8 ln N / T), ends T rounds with expected loss at most √(T ln N / 2) above the best single expert, whatever the losses, while a rule with no coin can be forced to regret T(1 - 1/N).
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Dist
import Mathlib.Probability.Moments.SubGaussian
import Mathlib.Probability.ProbabilityMassFunction.Integrals

open Finset

namespace Regret

variable {N : ℕ}

/-- The total loss of expert `i` over the first `t` rounds (rounds counted from 0):
`ℓ 0 i + ℓ 1 i + ⋯ + ℓ (t - 1) i`. Here `ℓ s i` is expert `i`'s loss on round `s`. -/
def cumLoss (ℓ : ℕ → Fin N → ℝ) (t : ℕ) (i : Fin N) : ℝ :=
  ∑ s ∈ range t, ℓ s i

/-- The weighted-majority weight of expert `i` before round `t`. It starts at 1 and is
multiplied by `e^(-η × loss)` after every round, so it equals `e^(-η × total loss so far)`. -/
noncomputable def weight (η : ℝ) (ℓ : ℕ → Fin N → ℝ) (t : ℕ) (i : Fin N) : ℝ :=
  Real.exp (-η * cumLoss ℓ t i)

/-- The rule's chance of choosing expert `i` on round `t`: its weight over the total weight. -/
noncomputable def chance (η : ℝ) (ℓ : ℕ → Fin N → ℝ) (t : ℕ) (i : Fin N) : ℝ :=
  weight η ℓ t i / ∑ j, weight η ℓ t j

/-- The rule's total expected loss over `T` rounds: on each round, its chances times the
losses, added up. -/
noncomputable def ruleLoss (η : ℝ) (ℓ : ℕ → Fin N → ℝ) (T : ℕ) : ℝ :=
  ∑ t ∈ range T, ∑ i, chance η ℓ t i * ℓ t i

/-- The total loss of the best single expert in hindsight, `L* = min_i L_i`. -/
noncomputable def bestLoss (ℓ : ℕ → Fin N → ℝ) (T : ℕ) : ℝ :=
  ⨅ i, cumLoss ℓ T i

/-- The regret `R_T`: the rule's total expected loss minus the best single expert's total. -/
noncomputable def regret (η : ℝ) (ℓ : ℕ → Fin N → ℝ) (T : ℕ) : ℝ :=
  ruleLoss η ℓ T - bestLoss ℓ T

end Regret

open Regret

open MeasureTheory ProbabilityTheory in
lemma hoeffding_fin {N : ℕ} (p x : Fin N → ℝ) (hp : ∀ i, 0 ≤ p i) (hs : ∑ i, p i = 1)
    (hx : ∀ i, 0 ≤ x i ∧ x i ≤ 1) (η : ℝ) :
    ∑ i, p i * Real.exp (-η * x i) ≤ Real.exp (-η * ∑ i, p i * x i + η ^ 2 / 8) := by
  have h1 : ∑ i, ENNReal.ofReal (p i) = 1 := by
    rw [← ENNReal.ofReal_sum_of_nonneg (fun i _ => hp i), hs, ENNReal.ofReal_one]
  set q := PMF.ofFintype (fun i => ENNReal.ofReal (p i)) h1
  set μ := q.toMeasure
  have hq : ∀ i, (q i).toReal = p i := fun i => by
    simp [q, PMF.ofFintype_apply, ENNReal.toReal_ofReal (hp i)]
  have hint : ∀ f : Fin N → ℝ, ∫ i, f i ∂μ = ∑ i, p i * f i := fun f => by
    rw [PMF.integral_eq_sum]; simp [hq]
  have h := hasSubgaussianMGF_of_mem_Icc (μ := μ) (X := x) (a := 0) (b := 1)
    (Measurable.aemeasurable (measurable_of_finite _)) (ae_of_all _ fun i => hx i)
  have h2 := h.mgf_le (-η)
  simp only [mgf, hint] at h2
  have e : ∀ i, p i * Real.exp (-η * (x i - ∑ j, p j * x j))
      = p i * Real.exp (-η * x i) * Real.exp (η * ∑ j, p j * x j) := fun i => by
    rw [mul_assoc, ← Real.exp_add]; ring_nf
  simp only [e, ← Finset.sum_mul] at h2
  have hc : ((‖(1:ℝ) - 0‖₊ / 2) ^ 2 : NNReal) = (1/4 : ℝ) := by
    norm_num
  rw [hc] at h2
  have hpos := Real.exp_pos (η * ∑ j, p j * x j)
  calc ∑ i, p i * Real.exp (-η * x i)
      = (∑ i, p i * Real.exp (-η * x i)) * Real.exp (η * ∑ j, p j * x j)
          * Real.exp (-η * ∑ i, p i * x i) := by
        rw [mul_assoc, ← Real.exp_add]; ring_nf; simp
    _ ≤ Real.exp (1/4 * (-η) ^ 2 / 2) * Real.exp (-η * ∑ i, p i * x i) := by gcongr
    _ = _ := by rw [← Real.exp_add]; ring_nf

#print axioms hoeffding_fin

variable {N : ℕ}

theorem regret_le_aux (hN : 0 < N) (T : ℕ) (ℓ : ℕ → Fin N → ℝ)
    (hℓ : ∀ t < T, ∀ i, 0 ≤ ℓ t i ∧ ℓ t i ≤ 1) (η : ℝ) (hη : 0 < η) :
    regret η ℓ T ≤ Real.log N / η + η * T / 8 := by
  have : Nonempty (Fin N) := ⟨⟨0, hN⟩⟩
  set W : ℕ → ℝ := fun t => ∑ j, weight η ℓ t j with hW
  have wpos : ∀ t j, 0 < weight η ℓ t j := fun t j => Real.exp_pos _
  have Wpos : ∀ t, 0 < W t := fun t => Finset.sum_pos (fun j _ => wpos t j) Finset.univ_nonempty
  have hstep : ∀ t < T, W (t + 1) ≤ W t *
      Real.exp (-η * ∑ i, chance η ℓ t i * ℓ t i + η ^ 2 / 8) := by
    intro t ht
    have e1 : W (t + 1) = W t * ∑ j, chance η ℓ t j * Real.exp (-η * ℓ t j) := by
      simp only [hW, Finset.mul_sum, chance]
      refine Finset.sum_congr rfl fun j _ => ?_
      have hWt : (∑ j, weight η ℓ t j) ≠ 0 := (Wpos t).ne'
      rw [div_mul_eq_mul_div, mul_div_assoc', mul_div_cancel_left₀ _ hWt]
      simp only [weight, cumLoss, Finset.sum_range_succ, ← Real.exp_add]
      ring_nf
    rw [e1]
    gcongr
    · exact (Wpos t).le
    · exact hoeffding_fin _ _ (fun j => div_nonneg (wpos t j).le (Wpos t).le)
        (by simp only [← Finset.sum_div]; exact div_self (Wpos t).ne')
        (fun i => hℓ t ht i) η
  have hind : ∀ t ≤ T, W t ≤ N * Real.exp (-η * ruleLoss η ℓ t + t * η ^ 2 / 8) := by
    intro t
    induction t with
    | zero => intro _; simp [hW, weight, cumLoss, ruleLoss]
    | succ t ih =>
      intro ht
      refine (hstep t (by omega)).trans ?_
      calc W t * Real.exp (-η * ∑ i, chance η ℓ t i * ℓ t i + η ^ 2 / 8)
          ≤ N * Real.exp (-η * ruleLoss η ℓ t + t * η ^ 2 / 8) *
              Real.exp (-η * ∑ i, chance η ℓ t i * ℓ t i + η ^ 2 / 8) := by
            gcongr; exact ih (by omega)
        _ = _ := by
            rw [mul_assoc, ← Real.exp_add]
            simp only [ruleLoss, Finset.sum_range_succ]
            push_cast; ring_nf
  obtain ⟨i, hi⟩ := exists_eq_ciInf_of_finite (f := fun i => cumLoss ℓ T i)
  have hle : weight η ℓ T i ≤ W T :=
    Finset.single_le_sum (f := fun j => weight η ℓ T j) (fun j _ => (wpos T j).le)
      (Finset.mem_univ i)
  have hmain := hle.trans (hind T le_rfl)
  have hNpos : (0:ℝ) < N := by exact_mod_cast hN
  have hlog := Real.log_le_log (wpos T i) hmain
  rw [Real.log_mul hNpos.ne' (Real.exp_pos _).ne', Real.log_exp, weight, Real.log_exp] at hlog
  have hb : bestLoss ℓ T = cumLoss ℓ T i := hi.symm
  simp only [regret, hb]
  rw [div_add' _ _ _ hη.ne', le_div_iff₀ hη]
  nlinarith [hlog]

#print axioms regret_le_aux

/-- The card's main claim. Take `N` experts and `T` rounds, with every loss between 0 and 1.
Run the weighted-majority rule (choose each expert with chance in proportion to its weight,
shrink each weight by `e^(-η × loss)` after every round) with the learning rate
`η = √(8 ln N / T)`. Then its expected loss is at most `√(T ln N / 2)` above the best single
expert in hindsight, whatever the losses were. The losses are an arbitrary sequence, so they
may be chosen by a planner who sees the past and the rule's chances, but not the coin. -/
theorem weighted_majority_regret_le_sqrt (hN : 0 < N) (T : ℕ) (ℓ : ℕ → Fin N → ℝ)
    (hℓ : ∀ t < T, ∀ i, 0 ≤ ℓ t i ∧ ℓ t i ≤ 1) :
    regret (Real.sqrt (8 * Real.log N / T)) ℓ T ≤ Real.sqrt (T * Real.log N / 2) := by
  have hη0 : 0 ≤ Real.sqrt (8 * Real.log N / T) := Real.sqrt_nonneg _
  rcases hη0.lt_or_eq with hη | hη
  · refine (regret_le_aux hN T ℓ hℓ _ hη).trans (le_of_eq ?_)
    have hT : (0:ℝ) < T := by
      rcases (Nat.cast_nonneg (α := ℝ) T).lt_or_eq with h | h
      · exact h
      · rw [← h] at hη; simp at hη
    have hL : 0 < Real.log N := by
      by_contra h
      replace h := not_lt.mp h
      have : 8 * Real.log N / T ≤ 0 := div_nonpos_of_nonpos_of_nonneg (by linarith) hT.le
      rw [Real.sqrt_eq_zero'.mpr this] at hη
      exact lt_irrefl _ hη
    set L := Real.log N
    have hs8 : Real.sqrt (8 * L / T) ^ 2 = 8 * L / T := Real.sq_sqrt (by positivity)
    have hs2 : Real.sqrt (T * L / 2) ^ 2 = T * L / 2 := Real.sq_sqrt (by positivity)
    have hpos2 : 0 < Real.sqrt (T * L / 2) := Real.sqrt_pos.mpr (by positivity)
    have hprod : Real.sqrt (8 * L / T) * Real.sqrt (T * L / 2) = 2 * L := by
      rw [← Real.sqrt_mul (by positivity)]
      have : 8 * L / T * (T * L / 2) = (2 * L) ^ 2 := by field_simp; ring
      rw [this, Real.sqrt_sq (by positivity)]
    rw [div_add' _ _ _ hη.ne', div_eq_iff hη.ne']
    nlinarith [hs8, hprod]
  · -- The learning rate is 0: then `T = 0` or `N = 1`.
    have hT : T = 0 ∨ Real.log N = 0 := by
      rcases Nat.eq_zero_or_pos T with h | h
      · exact Or.inl h
      · right
        have hTr : (0:ℝ) < T := by exact_mod_cast h
        have h0 : 8 * Real.log N / T ≤ 0 := Real.sqrt_eq_zero'.mp hη.symm
        have hL0 : Real.log N ≤ 0 := by
          have := (div_nonpos_iff.mp h0)
          rcases this with ⟨_, h2⟩ | ⟨h1, _⟩
          · exact absurd h2 (not_le.mpr hTr)
          · linarith
        exact le_antisymm hL0 (Real.log_nonneg (by exact_mod_cast hN))
    have hreg : regret (Real.sqrt (8 * Real.log N / T)) ℓ T ≤ 0 := by
      rcases hT with hT | hL
      · subst hT
        have : Nonempty (Fin N) := ⟨⟨0, hN⟩⟩
        simp [regret, ruleLoss, bestLoss, cumLoss]
      · have hN1 : N = 1 := by
          have := Real.eq_one_of_pos_of_log_eq_zero (by exact_mod_cast hN) hL
          exact_mod_cast this
        subst hN1
        simp [regret, ruleLoss, bestLoss, chance, cumLoss, weight]
    exact hreg.trans (Real.sqrt_nonneg _)

/-- The bound before the learning rate is tuned (the card's Step 3). For any learning rate
`η > 0` and losses between 0 and 1, the weighted-majority rule's regret after `T` rounds is
at most `ln N / η + η T / 8`. -/
theorem weighted_majority_regret_le (hN : 0 < N) (T : ℕ) (ℓ : ℕ → Fin N → ℝ)
    (hℓ : ∀ t < T, ∀ i, 0 ≤ ℓ t i ∧ ℓ t i ≤ 1) (η : ℝ) (hη : 0 < η) :
    regret η ℓ T ≤ Real.log N / η + η * T / 8 := by
  exact regret_le_aux hN T ℓ hℓ η hη

/-- Why the coin is essential (the card's Step 4). A rule with no coin picks an expert on
each round from the losses seen so far: `pick t past` is its choice on round `t` given the
losses `past s i` of rounds `s < t`. For every such rule there are losses between 0 and 1
(a full loss on its pick, none elsewhere) that leave its regret at least `T (1 - 1/N)`. -/
theorem deterministic_rule_regret_ge (hN : 0 < N) (T : ℕ)
    (pick : (t : ℕ) → (Fin t → Fin N → ℝ) → Fin N) :
    ∃ ℓ : ℕ → Fin N → ℝ, (∀ t i, 0 ≤ ℓ t i ∧ ℓ t i ≤ 1) ∧
      (T : ℝ) * (1 - 1 / N) ≤
        (∑ t ∈ range T, ℓ t (pick t (fun s => ℓ s))) - ⨅ i, cumLoss ℓ T i := by
  have : Nonempty (Fin N) := ⟨⟨0, hN⟩⟩
  let F : (n : ℕ) → ((m : ℕ) → m < n → Fin N → ℝ) → Fin N → ℝ :=
    fun t rec i => if i = pick t (fun s => rec s s.2) then 1 else 0
  let ℓ : ℕ → Fin N → ℝ := fun t => @Nat.strongRec (fun _ => Fin N → ℝ) F t
  have hℓ : ∀ t i, ℓ t i = if i = pick t (fun s => ℓ s) then 1 else 0 := by
    intro t i
    show @Nat.strongRec (fun _ => Fin N → ℝ) F t i = _
    rw [Nat.strongRec_eq]
  refine ⟨ℓ, fun t i => ?_, ?_⟩
  · rw [hℓ]; split_ifs <;> norm_num
  have hpick : ∀ t, ℓ t (pick t (fun s => ℓ s)) = 1 := fun t => by rw [hℓ]; simp
  have hrow : ∀ t, ∑ i, ℓ t i = 1 := fun t => by
    simp only [hℓ]; simp
  have hsum : ∑ i, cumLoss ℓ T i = T := by
    simp only [cumLoss]
    rw [Finset.sum_comm]
    simp [hrow]
  have hNpos : (0:ℝ) < N := by exact_mod_cast hN
  obtain ⟨i, -, hi⟩ := Finset.exists_le_of_sum_le (s := Finset.univ) Finset.univ_nonempty
    (f := fun i => cumLoss ℓ T i) (g := fun _ => (T:ℝ) / N)
    (by rw [hsum]; simp; field_simp; rfl)
  have hbdd : BddBelow (Set.range fun i => cumLoss ℓ T i) := (Set.finite_range _).bddBelow
  have hinf : (⨅ i, cumLoss ℓ T i) ≤ T / N := (ciInf_le hbdd i).trans hi
  simp only [hpick, Finset.sum_const, Finset.card_range, nsmul_eq_mul, mul_one]
  have : (T:ℝ) * (1 - 1 / N) = T - T / N := by ring
  linarith

-- The month's delays in minutes, 20 mornings: bus, train, bike, car.
-- Route totals 142, 108, 111, 204; the train is best in hindsight.
example :
    [6, 8, 5, 9, 7, 6, 10, 5, 8, 7, 6, 9, 5, 7, 8, 6, 7, 9, 6, 8].sum = 142 ∧
    [1, 2, 0, 1, 2, 18, 20, 16, 19, 17, 2, 1, 0, 2, 1, 1, 2, 0, 1, 2].sum = 108 ∧
    [4, 4, 5, 4, 12, 4, 5, 4, 4, 13, 4, 5, 4, 4, 14, 4, 5, 4, 4, 4].sum = 111 ∧
    [9, 11, 8, 12, 10, 9, 13, 10, 11, 9, 10, 12, 8, 9, 11, 10, 9, 12, 10, 11].sum = 204 := by
  decide

-- The train's signal failure, mornings 6 to 10, cost 90 of its 108 minutes.
example : [18, 20, 16, 19, 17].sum = 90 := by decide

-- The best route chosen afresh each morning loses only 42 minutes in total.
example :
    (List.zipWith min (List.zipWith min
      [6, 8, 5, 9, 7, 6, 10, 5, 8, 7, 6, 9, 5, 7, 8, 6, 7, 9, 6, 8]
      [1, 2, 0, 1, 2, 18, 20, 16, 19, 17, 2, 1, 0, 2, 1, 1, 2, 0, 1, 2])
      (List.zipWith min
      [4, 4, 5, 4, 12, 4, 5, 4, 4, 13, 4, 5, 4, 4, 14, 4, 5, 4, 4, 4]
      [9, 11, 8, 12, 10, 9, 13, 10, 11, 9, 10, 12, 8, 9, 11, 10, 9, 12, 10, 11])).sum = 42 := by
  decide

-- A rule with no coin against the planner, four routes, 20 mornings: T (1 - 1/N) = 15 hold-ups,
-- 300 minutes at 20 minutes each.
example : (20 : ℚ) * (1 - 1 / 4) = 15 ∧ 15 * 20 = 300 := by norm_num

-- Fair-coin mornings, two routes, T = 20: the sum behind every rule's expected regret,
-- Σ_k C(20, k) |k - 10|, equals the closed form (T/2) C(T, T/2) = 10 × 184,756.
example : ∑ k ∈ range 21, Nat.choose 20 k * Nat.dist k 10 = 10 * Nat.choose 20 10 ∧
    Nat.choose 20 10 = 184756 := by
  decide

#print axioms weighted_majority_regret_le_sqrt
#print axioms weighted_majority_regret_le
#print axioms deterministic_rule_regret_ge
