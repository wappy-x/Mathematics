-- Rating transition matrices: for a grade process where next year's grade depends only on this year's grade through one fixed table P, the chance of moving from grade i to grade j in T years is the (i, j) entry of P^T, its Default column is the cumulative default chance when Default is absorbing, and each cumulative default chance below 1 gives exactly one flat hazard.
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.Probability.Notation
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic

open MeasureTheory

theorem rtm_hist_measurable {ι Ω : Type*} [MeasurableSpace ι] [MeasurableSingletonClass ι]
    [MeasurableSpace Ω] (X : ℕ → Ω → ι) (hX : ∀ t, Measurable (X t)) (n : ℕ) (x : ℕ → ι) :
    MeasurableSet {ω | ∀ k ≤ n, X k ω = x k} := by
  simp only [Set.ofPred_forall]
  exact MeasurableSet.iInter fun k => MeasurableSet.iInter fun _ =>
    hX k (measurableSet_singleton (x k))

theorem rtm_hist_update {ι Ω : Type*} (X : ℕ → Ω → ι) (n : ℕ) (x : ℕ → ι) (m : ι) :
    {ω | ∀ k ≤ n, X k ω = Function.update x (n + 1) m k} = {ω | ∀ k ≤ n, X k ω = x k} := by
  ext ω
  simp only [Set.mem_ofPred_eq]
  refine forall_congr' fun k => imp_congr_right fun hk => ?_
  rw [Function.update_of_ne (by omega)]

theorem rtm_split {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace ι]
    [MeasurableSingletonClass ι] [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ t, Measurable (X t)) (S : Set Ω) (hS : MeasurableSet S)
    (n : ℕ) (x : ℕ → ι) :
    μ.real (S ∩ {ω | ∀ k ≤ n, X k ω = x k}) =
      ∑ m, μ.real (S ∩ {ω | ∀ k ≤ n + 1, X k ω = Function.update x (n + 1) m k}) := by
  rw [← measureReal_iUnion_fintype]
  · congr 1
    ext ω
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_iUnion]
    constructor
    · rintro ⟨hS, hh⟩
      refine ⟨X (n + 1) ω, hS, fun k hk => ?_⟩
      rcases Nat.lt_or_ge k (n + 1) with h | h
      · rw [Function.update_of_ne (by omega)]; exact hh k (by omega)
      · obtain rfl : k = n + 1 := by omega
        simp
    · rintro ⟨m, hS, hh⟩
      refine ⟨hS, fun k hk => ?_⟩
      have := hh k (by omega)
      rwa [Function.update_of_ne (by omega)] at this
  · intro a b hab
    refine Set.disjoint_left.mpr fun ω ha hb => hab ?_
    have h1 := ha.2 (n + 1) le_rfl
    have h2 := hb.2 (n + 1) le_rfl
    simp only [Function.update_self] at h1 h2
    rw [← h1, ← h2]
  · intro m
    exact hS.inter (rtm_hist_measurable X hX _ _)

theorem rtm_step {ι Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (X : ℕ → Ω → ι) (P : Matrix ι ι ℝ)
    (hMarkov : ∀ (t : ℕ) (x : ℕ → ι),
      μ.real {ω | ∀ k ≤ t + 1, X k ω = x k} =
        μ.real {ω | ∀ k ≤ t, X k ω = x k} * P (x t) (x (t + 1)))
    (n : ℕ) (x : ℕ → ι) (m : ι) :
    μ.real {ω | ∀ k ≤ n + 1, X k ω = Function.update x (n + 1) m k} =
      μ.real {ω | ∀ k ≤ n, X k ω = x k} * P (x n) m := by
  rw [hMarkov, rtm_hist_update, Function.update_self, Function.update_of_ne (by omega)]

theorem rtm_absorbing_row {ι : Type*} [Fintype ι] [DecidableEq ι] (P : Matrix ι ι ℝ) (d : ι)
    (hd : ∀ k, P d k = if k = d then 1 else 0) (T : ℕ) (j : ι) :
    (P ^ T) d j = if j = d then 1 else 0 := by
  induction T with
  | zero => simp [Matrix.one_apply, eq_comm]
  | succ T ih =>
    rw [pow_succ', Matrix.mul_apply]
    simp [hd, ih]

theorem rtm_general {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace ι]
    [MeasurableSingletonClass ι] [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ t, Measurable (X t)) (P : Matrix ι ι ℝ)
    (hMarkov : ∀ (t : ℕ) (x : ℕ → ι),
      μ.real {ω | ∀ k ≤ t + 1, X k ω = x k} =
        μ.real {ω | ∀ k ≤ t, X k ω = x k} * P (x t) (x (t + 1)))
    (T : ℕ) : ∀ (n : ℕ) (x : ℕ → ι) (j : ι),
    μ.real ({ω | X (n + T) ω = j} ∩ {ω | ∀ k ≤ n, X k ω = x k}) =
      μ.real {ω | ∀ k ≤ n, X k ω = x k} * (P ^ T) (x n) j := by
  induction T with
  | zero =>
    intro n x j
    by_cases h : x n = j
    · have : {ω | X (n + 0) ω = j} ∩ {ω | ∀ k ≤ n, X k ω = x k} = {ω | ∀ k ≤ n, X k ω = x k} := by
        ext ω
        simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, add_zero]
        exact ⟨fun h' => h'.2, fun h' => ⟨(h' n le_rfl).trans h, h'⟩⟩
      rw [this, pow_zero, h, Matrix.one_apply_eq, mul_one]
    · have : {ω | X (n + 0) ω = j} ∩ {ω | ∀ k ≤ n, X k ω = x k} = ∅ := by
        ext ω
        simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, add_zero, Set.mem_empty_iff_false,
          iff_false, not_and]
        intro h1 h2
        exact h ((h2 n le_rfl).symm.trans h1)
      rw [this, pow_zero, Matrix.one_apply_ne h, mul_zero, measureReal_empty]
  | succ T ih =>
    intro n x j
    rw [rtm_split μ X hX {ω | X (n + (T + 1)) ω = j} ((hX _) (measurableSet_singleton j))]
    have key : ∀ m, μ.real ({ω | X (n + (T + 1)) ω = j} ∩
        {ω | ∀ k ≤ n + 1, X k ω = Function.update x (n + 1) m k}) =
        μ.real {ω | ∀ k ≤ n, X k ω = x k} * (P (x n) m * (P ^ T) m j) := by
      intro m
      have e : n + (T + 1) = (n + 1) + T := by omega
      rw [e, ih, rtm_step μ X P hMarkov, Function.update_self, mul_assoc]
    simp_rw [key]
    rw [← Finset.mul_sum, pow_succ', Matrix.mul_apply]

theorem rtm_general_cum {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace ι]
    [MeasurableSingletonClass ι] [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ t, Measurable (X t)) (P : Matrix ι ι ℝ)
    (hMarkov : ∀ (t : ℕ) (x : ℕ → ι),
      μ.real {ω | ∀ k ≤ t + 1, X k ω = x k} =
        μ.real {ω | ∀ k ≤ t, X k ω = x k} * P (x t) (x (t + 1)))
    (d : ι) (hd : ∀ k, P d k = if k = d then 1 else 0)
    (T : ℕ) : ∀ (n : ℕ) (x : ℕ → ι),
    μ.real ({ω | ∃ t ≤ T, X (n + t) ω = d} ∩ {ω | ∀ k ≤ n, X k ω = x k}) =
      μ.real {ω | ∀ k ≤ n, X k ω = x k} * (P ^ T) (x n) d := by
  induction T with
  | zero =>
    intro n x
    have e : {ω | ∃ t ≤ 0, X (n + t) ω = d} = {ω | X (n + 0) ω = d} := by
      ext ω; simp
    rw [e, rtm_general μ X hX P hMarkov]
  | succ T ih =>
    intro n x
    by_cases h : x n = d
    · have : {ω | ∃ t ≤ T + 1, X (n + t) ω = d} ∩ {ω | ∀ k ≤ n, X k ω = x k} =
          {ω | ∀ k ≤ n, X k ω = x k} := by
        ext ω
        simp only [Set.mem_inter_iff, Set.mem_ofPred_eq]
        exact ⟨fun h' => h'.2, fun h' => ⟨⟨0, by omega, by simpa [h] using h' n le_rfl⟩, h'⟩⟩
      rw [this, h, rtm_absorbing_row P d hd]
      simp
    · have hS : MeasurableSet {ω | ∃ t ≤ T + 1, X (n + t) ω = d} := by
        have e : {ω | ∃ t ≤ T + 1, X (n + t) ω = d} =
            ⋃ t, ⋃ (_ : t ≤ T + 1), X (n + t) ⁻¹' {d} := by
          ext ω; simp
        rw [e]
        exact MeasurableSet.iUnion fun t => MeasurableSet.iUnion fun _ =>
          (hX _) (measurableSet_singleton d)
      rw [rtm_split μ X hX {ω | ∃ t ≤ T + 1, X (n + t) ω = d} hS]
      have key : ∀ m, μ.real ({ω | ∃ t ≤ T + 1, X (n + t) ω = d} ∩
          {ω | ∀ k ≤ n + 1, X k ω = Function.update x (n + 1) m k}) =
          μ.real {ω | ∀ k ≤ n, X k ω = x k} * (P (x n) m * (P ^ T) m d) := by
        intro m
        have e : {ω | ∃ t ≤ T + 1, X (n + t) ω = d} ∩
            {ω | ∀ k ≤ n + 1, X k ω = Function.update x (n + 1) m k} =
            {ω | ∃ t ≤ T, X ((n + 1) + t) ω = d} ∩
            {ω | ∀ k ≤ n + 1, X k ω = Function.update x (n + 1) m k} := by
          ext ω
          simp only [Set.mem_inter_iff, Set.mem_ofPred_eq]
          constructor
          · rintro ⟨⟨t, ht, hXt⟩, hh⟩
            refine ⟨?_, hh⟩
            rcases t with _ | s
            · exfalso
              have := hh n (by omega)
              rw [Function.update_of_ne (by omega)] at this
              exact h (this.symm.trans (by simpa using hXt))
            · exact ⟨s, by omega, by rwa [show n + 1 + s = n + (s + 1) by omega]⟩
          · rintro ⟨⟨s, hs, hXs⟩, hh⟩
            exact ⟨⟨s + 1, by omega, by rwa [show n + (s + 1) = n + 1 + s by omega]⟩, hh⟩
        rw [e, ih, rtm_step μ X P hMarkov, Function.update_self, mul_assoc]
      simp_rw [key]
      rw [← Finset.mul_sum, pow_succ', Matrix.mul_apply]

#print axioms rtm_hist_measurable
#print axioms rtm_hist_update
#print axioms rtm_split
#print axioms rtm_step
#print axioms rtm_absorbing_row
#print axioms rtm_general
#print axioms rtm_general_cum

/-- The theorem of the card. Grades form a finite set `ι`; `X t ω` is a borrower's grade in
year `t`. "Only today's grade matters" and "the same table every year": for every year `t` and
every grade history `x`, the chance of following `x` up to year `t + 1` is the chance of
following it up to year `t`, times the one-year table entry `P (x t) (x (t + 1))`.
Then for every horizon `T` and grades `i`, `j`, the chance of starting in `i` and being in `j`
at year `T` is the chance of starting in `i` times the `(i, j)` entry of `P ^ T`:
T years of moves are T copies of the one-year table multiplied together. -/
theorem transition_probability_eq_matrix_power
    {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace ι] [MeasurableSingletonClass ι]
    [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ t, Measurable (X t)) (P : Matrix ι ι ℝ)
    (hMarkov : ∀ (t : ℕ) (x : ℕ → ι),
      μ.real {ω | ∀ k ≤ t + 1, X k ω = x k} =
        μ.real {ω | ∀ k ≤ t, X k ω = x k} * P (x t) (x (t + 1)))
    (T : ℕ) (i j : ι) :
    μ.real {ω | X 0 ω = i ∧ X T ω = j} = μ.real {ω | X 0 ω = i} * (P ^ T) i j := by
  have hg := rtm_general μ X hX P hMarkov T 0 (fun _ => i) j
  have e1 : {ω | X 0 ω = i ∧ X T ω = j} =
      {ω | X (0 + T) ω = j} ∩ {ω | ∀ k ≤ 0, X k ω = (fun _ => i) k} := by
    ext ω; simp [and_comm]
  have e2 : {ω | ∀ k ≤ 0, X k ω = (fun _ : ℕ => i) k} = {ω | X 0 ω = i} := by
    ext ω; simp
  rw [e1, hg, e2]

/-- The Default column is cumulative. Same Markov table as above, and Default `d` is absorbing:
the Default row of the table is `1` on Default and `0` elsewhere ("once there, always there").
Then the chance of starting in grade `i` and having defaulted at some year up to `T` equals the
chance of starting in `i` times the Default entry `(P ^ T) i d`: the Default column of `P ^ T`
is the cumulative default chance `PD_i(T)`. -/
theorem cumulative_default_eq_matrix_power_default_column
    {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace ι] [MeasurableSingletonClass ι]
    [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ t, Measurable (X t)) (P : Matrix ι ι ℝ)
    (hMarkov : ∀ (t : ℕ) (x : ℕ → ι),
      μ.real {ω | ∀ k ≤ t + 1, X k ω = x k} =
        μ.real {ω | ∀ k ≤ t, X k ω = x k} * P (x t) (x (t + 1)))
    (d : ι) (hd : ∀ k, P d k = if k = d then 1 else 0)
    (T : ℕ) (i : ι) :
    μ.real {ω | X 0 ω = i ∧ ∃ t ≤ T, X t ω = d} = μ.real {ω | X 0 ω = i} * (P ^ T) i d := by
  have hg := rtm_general_cum μ X hX P hMarkov d hd T 0 (fun _ => i)
  have e1 : {ω | X 0 ω = i ∧ ∃ t ≤ T, X t ω = d} =
      {ω | ∃ t ≤ T, X (0 + t) ω = d} ∩ {ω | ∀ k ≤ 0, X k ω = (fun _ => i) k} := by
    ext ω; simp [and_comm]
  have e2 : {ω | ∀ k ≤ 0, X k ω = (fun _ : ℕ => i) k} = {ω | X 0 ω = i} := by
    ext ω; simp
  rw [e1, hg, e2]

/-- The average hazard exists and is unique. For a horizon `T` above 0 and a cumulative default
chance `pd` with `0 ≤ pd < 1`, a flat hazard `h` reproduces it, `1 - e^(-h T) = pd`, exactly
when `h = -ln(1 - pd) / T`. -/
theorem average_hazard_unique (T pd : ℝ) (hT : 0 < T) (hpd0 : 0 ≤ pd) (hpd1 : pd < 1) (h : ℝ) :
    1 - Real.exp (-(h * T)) = pd ↔ h = -Real.log (1 - pd) / T := by
  have h1 : 0 < 1 - pd := by linarith
  constructor
  · intro H
    have e : Real.exp (-(h * T)) = 1 - pd := by linarith
    have e2 := congrArg Real.log e
    rw [Real.log_exp] at e2
    field_simp
    linarith
  · intro H
    rw [H, show -(-Real.log (1 - pd) / T * T) = Real.log (1 - pd) by field_simp, Real.exp_log h1]
    ring

/-- The card's three-grade league: 0 Solid, 1 Shaky, 2 Default. -/
def league : Matrix (Fin 3) (Fin 3) ℚ :=
  !![9/10, 9/100, 1/100; 1/10, 8/10, 1/10; 0, 0, 1]

-- Two-year default from Solid, one term per road: 0.90 × 0.01 + 0.09 × 0.10 + 0.01 = 0.028.
example : (9/10 : ℚ) * (1/100) + (9/100) * (1/10) + (1/100) * 1 = 28/1000 := by norm_num
-- Two-year table: Solid row 0.819, 0.153, 0.028; Shaky row 0.170, 0.649, 0.181.
example : (league ^ 2) 0 0 = 819/1000 ∧ (league ^ 2) 0 1 = 153/1000 ∧ (league ^ 2) 0 2 = 28/1000 := by
  norm_num [league, pow_succ, Matrix.mul_fin_three]
example : (league ^ 2) 1 0 = 170/1000 ∧ (league ^ 2) 1 1 = 649/1000 ∧ (league ^ 2) 1 2 = 181/1000 := by
  norm_num [league, pow_succ, Matrix.mul_fin_three]
-- Hand table: PD Solid at years 3 and 4 are 0.051490 and 0.078625 exactly; Shaky year 3 is 0.247600.
example : (league ^ 3) 0 2 = 51490/1000000 ∧ (league ^ 3) 1 2 = 247600/1000000 := by
  norm_num [league, pow_succ, Matrix.mul_fin_three]
example : (league ^ 4) 0 2 = 78625/1000000 ∧ (league ^ 4) 1 2 = 303229/1000000 := by
  norm_num [league, pow_succ, Matrix.mul_fin_three]
-- Five-year default from Solid, exactly 0.10805311 (the card's 0.108053 / 10.81%).
example : (league ^ 5) 0 2 = 10805311/100000000 := by
  norm_num [league, pow_succ, Matrix.mul_fin_three]
-- First-step split for year 5: 0.01 + 0.90 × PD_S(4) + 0.09 × PD_H(4).
example : (1/100 : ℚ) + 9/10 * (78625/1000000) + 9/100 * (303229/1000000) = 10805311/100000000 := by
  norm_num
-- Of 1,000 Solid borrowers: 10 default in year one; then 900 Solid and 90 Shaky give 9 + 9 = 18.
example : (1000 : ℚ) * (1/100) = 10 ∧ (900 : ℚ) * (1/100) + 90 * (1/10) = 18 := by norm_num
-- Cohort estimate: 90 of 1,000 Solid borrowers slip to Shaky, so the estimate is 0.09.
example : (90 : ℚ) / 1000 = 9/100 := by norm_num

#print axioms transition_probability_eq_matrix_power
#print axioms cumulative_default_eq_matrix_power_default_column
#print axioms average_hazard_unique
