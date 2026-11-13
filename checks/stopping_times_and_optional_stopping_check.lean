-- Stopping times: a fair game stopped at a stopping time that never passes a fixed round keeps its starting average, the frozen game is itself a fair game, and for fair one-dollar tosses the average squared fortune at the stop equals the average number of rounds played.
import Mathlib.Probability.Martingale.OptionalStopping

open MeasureTheory

theorem martingale_integral_stoppedValue_eq {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0)
    (M : ℕ → Ω → ℝ) (hM : Martingale M ℱ P)
    (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) (N : ℕ) (hbdd : ∀ ω, τ ω ≤ N) :
    ∫ ω, stoppedValue M τ ω ∂P = ∫ ω, M 0 ω ∂P := by
  have h0 : IsStoppingTime ℱ (fun _ : Ω => ((0 : ℕ) : WithTop ℕ)) := isStoppingTime_const ℱ 0
  have hle : (fun _ : Ω => ((0 : ℕ) : WithTop ℕ)) ≤ τ := fun ω => by simp
  have h1 := hM.submartingale.expected_stoppedValue_mono h0 hτ hle hbdd
  have h2 := hM.neg.submartingale.expected_stoppedValue_mono h0 hτ hle hbdd
  have e0 : ∀ ω, stoppedValue M (fun _ => ((0 : ℕ) : WithTop ℕ)) ω = M 0 ω := fun _ => rfl
  have e0' : ∀ ω, stoppedValue (-M) (fun _ => ((0 : ℕ) : WithTop ℕ)) ω = -M 0 ω := fun _ => rfl
  have e1 : ∀ ω, stoppedValue (-M) τ ω = -stoppedValue M τ ω := fun _ => rfl
  simp only [e0] at h1
  simp only [e0', e1, integral_neg, neg_le_neg_iff] at h2
  exact le_antisymm h2 h1

#print axioms martingale_integral_stoppedValue_eq

theorem sq_sub_index_martingale {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0)
    (S : ℕ → Ω → ℝ) (hS : Martingale S ℱ P) (hS0 : ∀ ω, S 0 ω = 0)
    (hstep : ∀ n ω, |S (n + 1) ω - S n ω| = 1) :
    (∀ n ω, |S n ω| ≤ n) ∧ (∀ n, Integrable (fun ω => S n ω ^ 2) P) ∧
      Martingale (fun n ω => S n ω ^ 2 - (n : ℝ)) ℱ P := by
  have hb : ∀ n ω, |S n ω| ≤ n := by
    intro n ω
    induction n with
    | zero => simp [hS0]
    | succ k ih =>
      have h1 : |S (k + 1) ω| ≤ |S (k + 1) ω - S k ω| + |S k ω| := by
        have := abs_add_le (S (k + 1) ω - S k ω) (S k ω)
        simpa using this
      rw [hstep] at h1
      push_cast
      linarith
  have hsm : ∀ n, StronglyMeasurable[m0] (S n) := fun n => (hS.stronglyMeasurable n).mono (ℱ.le n)
  have hsq : ∀ n, Integrable (fun ω => S n ω ^ 2) P := by
    intro n
    refine Integrable.of_bound ((hsm n).pow 2).aestronglyMeasurable ((n : ℝ) ^ 2)
      (Filter.Eventually.of_forall fun ω => ?_)
    rw [Real.norm_eq_abs, abs_pow]
    exact pow_le_pow_left₀ (abs_nonneg _) (hb n ω) 2
  refine ⟨hb, hsq, ?_⟩
  refine martingale_of_condExp_sub_eq_zero_nat
    (fun n => ((hS.stronglyMeasurable n).pow 2).sub stronglyMeasurable_const)
    (fun n => (hsq n).sub (integrable_const _)) (fun n => ?_)
  have heq : (fun ω => S (n + 1) ω ^ 2 - ((n + 1 : ℕ) : ℝ)) - (fun ω => S n ω ^ 2 - (n : ℝ))
      = (fun ω => 2 * S n ω) * (S (n + 1) - S n) := by
    ext ω
    have h := hstep n ω
    have h2 : (S (n + 1) ω - S n ω) ^ 2 = 1 := by rw [← sq_abs, h]; norm_num
    simp only [Pi.sub_apply, Pi.mul_apply]
    push_cast
    nlinarith [h2]
  rw [heq]
  have hDint : Integrable (S (n + 1) - S n) P := (hS.integrable _).sub (hS.integrable _)
  have hprod : Integrable ((fun ω => 2 * S n ω) * (S (n + 1) - S n)) P := by
    refine Integrable.of_bound (((hsm n).const_mul 2).mul ((hsm _).sub (hsm n))).aestronglyMeasurable
      (2 * n) (Filter.Eventually.of_forall fun ω => ?_)
    simp only [Pi.mul_apply, Pi.sub_apply, Real.norm_eq_abs, abs_mul, hstep, mul_one]
    have := hb n ω
    rw [abs_two]
    linarith
  have hD0 : P[S (n + 1) - S n | ℱ n] =ᵐ[P] 0 := by
    refine (condExp_sub (hS.integrable _) (hS.integrable _) _).trans ?_
    rw [condExp_of_stronglyMeasurable (ℱ.le n) (hS.stronglyMeasurable n) (hS.integrable n)]
    filter_upwards [hS.condExp_ae_eq (Nat.le_succ n)] with ω hω
    simp [hω]
  refine (condExp_mul_of_stronglyMeasurable_left
    ((hS.stronglyMeasurable n).const_mul 2) hprod hDint).trans ?_
  filter_upwards [hD0] with ω hω
  simp [hω]

#print axioms sq_sub_index_martingale

/-- **Optional stopping, bounded case.** On a probability space with a filtration (what is known
after each round), let `M` be a martingale (a fair game: adapted, each `M n` integrable, and the
forecast of the next value given the past is the current value). Let `τ` be a stopping time
(`{τ ≤ n}` is known after round `n`) that never passes a fixed round `N`. Then the average value
at the stop equals the average value at the start: `E[M_τ] = E[M_0]`. -/
theorem optional_stopping_bounded {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0)
    (M : ℕ → Ω → ℝ) (hM : Martingale M ℱ P)
    (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) (N : ℕ) (hbdd : ∀ ω, τ ω ≤ N) :
    ∫ ω, stoppedValue M τ ω ∂P = ∫ ω, M 0 ω ∂P := by
  exact martingale_integral_stoppedValue_eq P ℱ M hM τ hτ N hbdd

/-- **The frozen game is fair, with or without a deadline.** For a martingale `M` and any stopping
time `τ` (possibly unbounded, possibly infinite on some paths), the stopped process
`M_{n ∧ τ}` is again a martingale, and its average equals the starting average at every round:
`E[M_{n ∧ τ}] = E[M_0]` for every `n`. -/
theorem stopped_process_is_martingale {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0)
    (M : ℕ → Ω → ℝ) (hM : Martingale M ℱ P)
    (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) :
    Martingale (stoppedProcess M τ) ℱ P ∧
      ∀ n, ∫ ω, stoppedProcess M τ n ω ∂P = ∫ ω, M 0 ω ∂P := by
  have hmart : Martingale (stoppedProcess M τ) ℱ P := by
    rw [martingale_iff]
    refine ⟨?_, hM.submartingale.stoppedProcess hτ⟩
    have h := (hM.neg.submartingale.stoppedProcess hτ).neg
    simpa using h
  refine ⟨hmart, fun n => ?_⟩
  have := hmart.setIntegral_eq (Nat.zero_le n) (s := Set.univ) MeasurableSet.univ
  simp only [Measure.restrict_univ] at this
  rw [← this]
  congr 1
  ext ω
  simp [stoppedProcess]

/-- **The wait equals the average squared fortune.** Let `S` be a fair game that starts at 0 and
moves exactly one dollar up or down each round (a martingale with `S 0 = 0` and
`|S (n+1) - S n| = 1`). Then `S n ^ 2 - n` is also a fair game, and optional stopping applied to
it gives, for every stopping time `τ` that never passes a fixed round `N`,
`E[S_τ ^ 2] = E[τ]`. -/
theorem expected_square_at_stop_eq_expected_wait {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0)
    (S : ℕ → Ω → ℝ) (hS : Martingale S ℱ P) (hS0 : ∀ ω, S 0 ω = 0)
    (hstep : ∀ n ω, |S (n + 1) ω - S n ω| = 1)
    (τ : Ω → WithTop ℕ) (hτ : IsStoppingTime ℱ τ) (N : ℕ) (hbdd : ∀ ω, τ ω ≤ N) :
    ∫ ω, (stoppedValue S τ ω) ^ 2 ∂P = ∫ ω, ((τ ω).untopA : ℝ) ∂P := by
  obtain ⟨-, hsq, hX⟩ := sq_sub_index_martingale P ℱ S hS hS0 hstep
  have hXint := hX.submartingale.integrable_stoppedValue hτ hbdd
  have hSqint : Integrable (fun ω => stoppedValue S τ ω ^ 2) P :=
    integrable_stoppedValue ℕ hτ hsq hbdd
  have h0 := martingale_integral_stoppedValue_eq P ℱ _ hX τ hτ N hbdd
  simp only [hS0] at h0
  have e : ∀ ω, ((τ ω).untopA : ℝ) = (stoppedValue S τ ω) ^ 2
      - stoppedValue (fun n ω => S n ω ^ 2 - (n : ℝ)) τ ω := by
    intro ω
    simp [stoppedValue]
  simp_rw [e]
  rw [integral_sub hSqint hXint]
  simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, CharP.cast_eq_zero, sub_self,
    integral_zero] at h0
  rw [h0, sub_zero]

/-! ### The card's worked numbers, by exact path counts

The quit-at-5 rule with deadline 100. After round `n`, `alive` lists, for each fortune
`f = i - 100` with `i = 0, …, 104`, how many of the `2 ^ n` toss sequences are still playing at
fortune `f`; `quit` counts the sequences that have already reached 5 dollars. -/

/-- One round: every path still playing moves one dollar up or down; paths reaching 5 quit, and
each quitter's count doubles because the later tosses no longer matter. -/
def quitAtFiveStep (s : ℕ × List ℕ) : ℕ × List ℕ :=
  (2 * s.1 + s.2.getD 104 0,
    (List.range 105).map fun i => (if i = 0 then 0 else s.2.getD (i - 1) 0) + s.2.getD (i + 1) 0)

/-- The counts after rounds 0, 1, …, 100. -/
def quitAtFiveCounts : List (ℕ × List ℕ) :=
  (List.range 100).scanl (fun s _ => quitAtFiveStep s)
    (0, (List.range 105).map fun i => if i = 100 then 1 else 0)

-- The frozen fortune averages exactly 0 at all 101 rounds: 5 × (quitters) + Σ f × (players at f)
-- = 0, written with `f = i - 100` as 5·quit + Σ i·alive_i = 100·Σ alive_i.
example : quitAtFiveCounts.length = 101 ∧
    quitAtFiveCounts.all (fun s =>
      5 * s.1 + ((List.range 105).map fun i => i * s.2.getD i 0).sum
        = 100 * s.2.sum) = true := by
  decide +kernel

-- E[τ] = E[S_τ ^ 2] over all 2 ^ 100 paths: Σ_{n<100} (paths still playing after round n)
-- equals 25 × (quitters) + Σ f ^ 2 × (players at f) at round 100.
example :
    ((List.range 100).map fun n =>
        ((quitAtFiveCounts.getD n (0, [])).2.sum : ℤ) * 2 ^ (100 - n)).sum
      = 25 * ((quitAtFiveCounts.getD 100 (0, [])).1 : ℤ)
        + ((List.range 105).map fun (i : ℕ) =>
            ((i : ℤ) - 100) ^ 2 * ((quitAtFiveCounts.getD 100 (0, [])).2.getD i 0 : ℤ)).sum := by
  decide +kernel

-- The sample path in the picture first reaches 5 dollars at round 39, and the stopped path
-- is the played path frozen at 5 from then on.
example :
    let path : List ℤ := [0, 1, 0, -1, 0, 1, 0, 1, 0, -1, -2, -1, -2, -1, -2, -1, 0, 1, 0, -1, 0,
      1, 2, 1, 0, 1, 0, -1, -2, -3, -2, -1, 0, 1, 2, 3, 2, 3, 4, 5, 6, 5, 4, 5, 4, 3, 4, 3, 2, 1, 2]
    let stopped : List ℤ := [0, 1, 0, -1, 0, 1, 0, 1, 0, -1, -2, -1, -2, -1, -2, -1, 0, 1, 0, -1,
      0, 1, 2, 1, 0, 1, 0, -1, -2, -3, -2, -1, 0, 1, 2, 3, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
      5, 5]
    path.findIdx (· = 5) = 39 ∧
      stopped = (List.range 51).map fun n => path.getD (min n 39) 0 := by
  decide

-- Capped doubling, 10 rounds: stakes 1, 2, …, 512 lose 1023 in all, with chance 1 in 1024;
-- otherwise the player wins 1. The average is exactly 0.
example : ((List.range 10).map fun i => 2 ^ i).sum = 1023 := by decide
example : ((1023 / 1024) * 1 + (1 / 1024) * (-1023) : ℚ) = 0 := by norm_num

#print axioms optional_stopping_bounded
#print axioms stopped_process_is_martingale
#print axioms expected_square_at_stop_eq_expected_wait
