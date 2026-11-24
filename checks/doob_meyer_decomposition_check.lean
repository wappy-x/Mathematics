-- Doob-Meyer: in discrete time every submartingale splits in exactly one way into a fair game starting at 0 plus a rising trend known one round early, the trend of a martingale's square is the sum of its forecast squared steps, and on the coin-toss tree that trend equals W squared times the time step.
import Mathlib.Probability.Martingale.Centering
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Tactic.NormNum.NatFactorial
import Mathlib.Tactic.NormNum.BigOperators

open MeasureTheory ProbabilityTheory
open scoped BigOperators

/-! Setting, as on the card. `Ω` carries a probability measure `μ`; `ℱ n` is what is known by
round `n`. `μ[X | ℱ n]` is the best forecast of `X` given `ℱ n`. A process is *predictable* when
its value at round `n + 1` is fixed by `ℱ n` (known one round early).

Only the discrete-time part of the card is stated here. The continuous-time Doob-Meyer theorem
(class D, right-continuous paths), the identification `⟨M⟩ = [M]` for continuous martingales and
the Poisson bracket `λ t` need continuous-time predictability, class D and the Poisson process,
which Mathlib does not have. -/

/-- The card's main claim, in discrete time (the Doob decomposition): a submartingale `Z` splits
as `Z n = Z 0 + M n + A n`, where `M` is a martingale starting at 0 and the trend `A` starts at 0,
is predictable (`A (n + 1)` is known at round `n`) and rises. The split is unique: any other
split `Z = Z 0 + M' + A'` with the same properties has `M' n = M n` and `A' n = A n` almost
surely, for every round `n`. -/
theorem submartingale_doob_decomposition_exists_unique {Ω : Type*} {m0 : MeasurableSpace Ω}
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {Z : ℕ → Ω → ℝ}
    (hZ : Submartingale Z ℱ μ) :
    ∃ M A : ℕ → Ω → ℝ,
      (∀ n, Z n = Z 0 + M n + A n) ∧ Martingale M ℱ μ ∧ M 0 = 0 ∧ A 0 = 0 ∧
      (∀ n, StronglyMeasurable[ℱ n] (A (n + 1))) ∧ (∀ᵐ ω ∂μ, Monotone fun n => A n ω) ∧
      ∀ M' A' : ℕ → Ω → ℝ, (∀ n, Z n = Z 0 + M' n + A' n) → Martingale M' ℱ μ →
        M' 0 = 0 → A' 0 = 0 → (∀ n, StronglyMeasurable[ℱ n] (A' (n + 1))) →
        ∀ n, M' n =ᵐ[μ] M n ∧ A' n =ᵐ[μ] A n := by
  have hZ0 : Martingale (fun _ => Z 0) ℱ μ :=
    martingale_const_fun ℱ μ (hZ.stronglyAdapted 0) (hZ.integrable 0)
  have hmP : Martingale (martingalePart Z ℱ μ) ℱ μ :=
    martingale_martingalePart hZ.stronglyAdapted hZ.integrable
  refine ⟨fun n => martingalePart Z ℱ μ n - Z 0, predictablePart Z ℱ μ, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro n
    have := congrFun (martingalePart_add_predictablePart ℱ μ Z) n
    rw [Pi.add_apply] at this
    rw [← this]; ext ω; simp only [Pi.add_apply, Pi.sub_apply]; ring
  · exact hmP.sub hZ0
  · simp
  · simp
  · exact stronglyAdapted_predictablePart
  · exact hZ.monotone_predictablePart
  · intro M' A' hsplit hM' hM'0 hA'0 hA'
    have hf : Martingale (fun n => Z 0 + M' n) ℱ μ := hZ0.add hM'
    have hfg : (fun n => Z 0 + M' n) + A' = Z := by
      funext n; rw [hsplit n]; rfl
    have hA'int : ∀ n, Integrable (A' n) μ := by
      intro n
      have : A' n = Z n - (Z 0 + M' n) := by rw [hsplit n]; abel
      rw [this]; exact (hZ.integrable n).sub ((hZ.integrable 0).add (hM'.integrable n))
    intro n
    have h1 := martingalePart_add_ae_eq hf hA' hA'0 hA'int n
    have h2 := predictablePart_add_ae_eq hf hA' hA'0 hA'int n
    rw [hfg] at h1 h2
    refine ⟨?_, h2.symm⟩
    filter_upwards [h1] with ω hω
    simp [hω]

/-- The bracket in discrete time: for a martingale `M` with finite variance at every round,
the Doob trend of `M ^ 2` (Mathlib's `predictablePart`) is the running sum of the forecast
squared steps, `⟨M⟩ n = ∑_{k < n} E[(M (k+1) - M k)^2 | ℱ k]`, and `M ^ 2 - ⟨M⟩` is a
martingale. -/
theorem bracket_eq_sum_forecast_squared_steps {Ω : Type*} {m0 : MeasurableSpace Ω}
    {μ : Measure Ω} [IsProbabilityMeasure μ] {ℱ : Filtration ℕ m0} {M : ℕ → Ω → ℝ}
    (hM : Martingale M ℱ μ) (hM2 : ∀ n, MemLp (M n) 2 μ) :
    (∀ n, predictablePart (fun k => M k ^ 2) ℱ μ n =ᵐ[μ]
        ∑ k ∈ Finset.range n, μ[(M (k + 1) - M k) ^ 2 | ℱ k]) ∧
      Martingale (fun n => M n ^ 2 - ∑ k ∈ Finset.range n, μ[(M (k + 1) - M k) ^ 2 | ℱ k])
        ℱ μ := by
  have hsq : ∀ n, Integrable (M n ^ 2) μ := fun n => (hM2 n).integrable_sq
  have hstep : ∀ k, μ[M (k + 1) ^ 2 - M k ^ 2 | ℱ k] =ᵐ[μ] μ[(M (k + 1) - M k) ^ 2 | ℱ k] := by
    intro k
    have hprod : Integrable (M k * (M (k + 1) - M k)) μ :=
      MemLp.integrable_mul (p := 2) (q := 2) (hM2 k) ((hM2 (k + 1)).sub (hM2 k))
    have hdiff : Integrable (M (k + 1) - M k) μ := (hM.integrable _).sub (hM.integrable _)
    have hid : (M (k + 1) - M k) ^ 2 =
        (M (k + 1) ^ 2 - M k ^ 2) - (2 : ℝ) • (M k * (M (k + 1) - M k)) := by
      ext ω; simp only [Pi.pow_apply, Pi.sub_apply, Pi.smul_apply, Pi.mul_apply, smul_eq_mul]
      ring
    have hzero : μ[M k * (M (k + 1) - M k) | ℱ k] =ᵐ[μ] 0 := by
      have h1 := condExp_mul_of_stronglyMeasurable_left (m := ℱ k) (hM.stronglyAdapted k) hprod
        hdiff
      have h2 : μ[M (k + 1) - M k | ℱ k] =ᵐ[μ] 0 := by
        have := condExp_sub (m := ℱ k) (hM.integrable (k + 1)) (hM.integrable k)
        filter_upwards [this, hM.condExp_ae_eq (Nat.le_succ k), hM.condExp_ae_eq (le_refl k)]
          with ω h h' h''
        simp [h, h', h'']
      filter_upwards [h1, h2] with ω h h'
      simp [h, h']
    rw [hid]
    have h3 := condExp_sub (m := ℱ k) ((hsq (k + 1)).sub (hsq k)) (hprod.const_mul 2 |>.congr
      (by filter_upwards with ω; simp [smul_eq_mul]) : Integrable ((2 : ℝ) • (M k * (M (k + 1) - M k))) μ)
    have h4 : μ[(2 : ℝ) • (M k * (M (k + 1) - M k)) | ℱ k] =ᵐ[μ] 0 := by
      filter_upwards [condExp_smul (m := ℱ k) (μ := μ) (2 : ℝ) (M k * (M (k + 1) - M k)), hzero]
        with ω h h'
      simp [h, h']
    filter_upwards [h3, h4] with ω h h'
    simp [h, h']
  have hpart : ∀ n, predictablePart (fun k => M k ^ 2) ℱ μ n =ᵐ[μ]
      ∑ k ∈ Finset.range n, μ[(M (k + 1) - M k) ^ 2 | ℱ k] := by
    intro n
    simp only [predictablePart]
    exact eventuallyEq_sum fun k _ => hstep k
  refine ⟨hpart, ?_⟩
  have hadapt : StronglyAdapted ℱ (fun k => M k ^ 2) := fun n => (hM.stronglyAdapted n).pow 2
  have hmP : Martingale (martingalePart (fun k => M k ^ 2) ℱ μ) ℱ μ :=
    martingale_martingalePart hadapt hsq
  have heq : ∀ n, (M n ^ 2 - ∑ k ∈ Finset.range n, μ[(M (k + 1) - M k) ^ 2 | ℱ k]) =ᵐ[μ]
      martingalePart (fun k => M k ^ 2) ℱ μ n := by
    intro n
    filter_upwards [hpart n] with ω h
    simp only [martingalePart, Pi.sub_apply, h]
  refine ⟨fun n => ?_, fun i j hij => ?_⟩
  · refine (hadapt n).sub ?_
    exact Finset.stronglyMeasurable_sum _ fun k hk =>
      stronglyMeasurable_condExp.mono (ℱ.mono (Finset.mem_range_le hk))
  · exact (condExp_congr_ae (heq j)).trans ((hmP.condExp_ae_eq hij).trans (heq i).symm)

/-- The house example on the coin-toss tree. The walk moves from `W` to `W + δ` or `W - δ`
with chance 1/2 each while time moves from `t` to `t + dt`, where `δ ^ 2 = dt`, and the gain is
`M(w, t) = (w ^ 2 - t) / 2`. Then Doob's recipe for `M ^ 2` at the node (average of the two
children minus the parent) is `W ^ 2 * dt`, and the squared step of `M` along either branch is
also `W ^ 2 * dt`. -/
theorem coin_tree_recipe_eq_squared_step (W t δ dt : ℝ) (hδ : δ ^ 2 = dt) :
    let M : ℝ → ℝ → ℝ := fun w s => (w ^ 2 - s) / 2
    ((M (W + δ) (t + dt)) ^ 2 + (M (W - δ) (t + dt)) ^ 2) / 2 - (M W t) ^ 2 = W ^ 2 * dt ∧
      (M (W + δ) (t + dt) - M W t) ^ 2 = W ^ 2 * dt ∧
      (M (W - δ) (t + dt) - M W t) ^ 2 = W ^ 2 * dt := by
  intro M
  simp only [M]
  subst hδ
  refine ⟨by ring, by ring, by ring⟩

/-! The card's exact worked numbers. -/

-- Coin tree, 10 steps: S is the number of up-steps k minus down-steps, M_10 = (S^2 - 10)/20,
-- and averaging M_10^2 over the 2^10 paths gives E[M^2] = 9/20 = (10 - 1)/(2 * 10).
example : (∑ k ∈ Finset.range 11, ((Nat.choose 10 k : ℚ) *
    ((((2 * k : ℚ) - 10) ^ 2 - 10) / 20) ^ 2)) / 2 ^ 10 = 9 / 20 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num [Nat.choose]

-- Coin tree, 100 steps: E[M^2] = 99/200 = (100 - 1)/(2 * 100).
set_option maxRecDepth 100000 in
example : (∑ k ∈ Finset.range 101, ((Nat.choose 100 k : ℚ) *
    ((((2 * k : ℚ) - 100) ^ 2 - 100) / 200) ^ 2)) / 2 ^ 100 = 99 / 200 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero,
    Nat.choose_eq_descFactorial_div_factorial]
  norm_num

-- The square, directly: E[M_1^2] = (E[W^4] - 2 E[W^2] + 1)/4 = (3 - 2 + 1)/4 = 1/2.
example : ((3 : ℚ) - 2 * 1 + 1) / 4 = 1 / 2 := by norm_num

-- The bracket: E<M>_1 = ∫_0^1 s ds = 1/2.
example : ∫ s in (0 : ℝ)..1, s = 1 / 2 := by
  rw [integral_id]; norm_num

-- Calls at 4 an hour: E[N_1^2] = λ + λ^2 = 20, not 4; an 8-hour shift has variance 4 * 8 = 32.
example : (4 : ℚ) + 4 ^ 2 = 20 ∧ (4 : ℚ) * 8 = 32 := by norm_num

-- One slot ahead, with call chance p and current fair part m: the recipe step for (N - 4t)^2 is
-- p (1 - p), whatever m is.
example (p m : ℚ) : p * (m + 1 - p) ^ 2 + (1 - p) * (m - p) ^ 2 - m ^ 2 = p * (1 - p) := by
  ring

-- Over the hour: 60 slots give 60 p (1 - p) = 56/15 = 3.7333..., 3600 slots give 899/225 = 3.99555...
example : (60 : ℚ) * ((4 / 60) * (1 - 4 / 60)) = 56 / 15 ∧
    (3600 : ℚ) * ((4 / 3600) * (1 - 4 / 3600)) = 899 / 225 := by norm_num

#print axioms submartingale_doob_decomposition_exists_unique
#print axioms bracket_eq_sum_forecast_squared_steps
#print axioms coin_tree_recipe_eq_squared_step
