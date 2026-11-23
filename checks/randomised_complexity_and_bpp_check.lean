-- BPP: a majority vote of k independent runs, each right with chance at least 1/2 + ε, is wrong with chance at most exp(−2kε²), and the random-list check of a matrix product misses a wrong table with chance at most 1/|S|.
import Mathlib.Probability.Moments.SubGaussian
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Basic

open MeasureTheory ProbabilityTheory Real Matrix

/-- Amplification by majority vote (the card's Detailed proof). Run a test k times with fresh
coins: X i ω = 1 when run i is right and 0 when it is wrong. The runs are independent, and
each one is right with chance at least 1/2 + ε, for a fixed margin ε > 0. Then the majority
vote is wrong (at most half the runs are right) with chance at most exp(−2kε²). -/
theorem majority_vote_error_le_exp
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {X : ℕ → Ω → ℝ} (hmeas : ∀ i, Measurable (X i)) (hindep : iIndepFun X μ)
    (h01 : ∀ i ω, X i ω = 0 ∨ X i ω = 1)
    {ε : ℝ} (hε : 0 < ε) (hright : ∀ i, 1 / 2 + ε ≤ μ.real {ω | X i ω = 1}) (k : ℕ) :
    μ.real {ω | ∑ i ∈ Finset.range k, X i ω ≤ (k : ℝ) / 2} ≤ exp (-2 * k * ε ^ 2) := by
  -- the mean of each run is its chance of being right
  have hmean : ∀ i, 1 / 2 + ε ≤ μ[X i] := by
    intro i
    have hX : X i = Set.indicator {ω | X i ω = 1} (fun _ => (1 : ℝ)) := by
      funext ω
      rcases h01 i ω with h | h
      · have : ω ∉ {ω | X i ω = 1} := by simp [h]
        rw [Set.indicator_of_notMem this, h]
      · have : ω ∈ {ω | X i ω = 1} := by simp [h]
        rw [Set.indicator_of_mem this, h]
    have hms : MeasurableSet {ω | X i ω = 1} := hmeas i (measurableSet_singleton 1)
    have hE : μ[X i] = μ.real {ω | X i ω = 1} := by
      conv_lhs => rw [hX]
      rw [integral_indicator_const _ hms, smul_eq_mul, mul_one]
    rw [hE]
    exact hright i
  set Y : ℕ → Ω → ℝ := fun i ω => μ[X i] - X i ω with hYdef
  have hYind : iIndepFun Y μ := by
    have := hindep.comp (fun (i : ℕ) (x : ℝ) => μ[X i] - x) (fun i => by fun_prop)
    exact this
  have hsub : ∀ i < k, HasSubgaussianMGF (Y i) ((‖(1 : ℝ) - 0‖₊ / 2) ^ 2) μ := by
    intro i _
    have hb : ∀ᵐ ω ∂μ, X i ω ∈ Set.Icc (0 : ℝ) 1 := ae_of_all _ fun ω => by
      rcases h01 i ω with h | h <;> simp [h]
    have := (hasSubgaussianMGF_of_mem_Icc (hmeas i).aemeasurable hb).neg
    convert this using 1
    funext ω
    simp [Y]
  have hkε : (0 : ℝ) ≤ k * ε := by positivity
  have hH := HasSubgaussianMGF.measure_sum_range_ge_le_of_iIndepFun hYind hsub hkε
  have hsubset : {ω | ∑ i ∈ Finset.range k, X i ω ≤ (k : ℝ) / 2} ⊆
      {ω | (k : ℝ) * ε ≤ ∑ i ∈ Finset.range k, Y i ω} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq] at hω ⊢
    have h1 : ∑ i ∈ Finset.range k, Y i ω =
        ∑ i ∈ Finset.range k, μ[X i] - ∑ i ∈ Finset.range k, X i ω := by
      simp [Y, Finset.sum_sub_distrib]
    have h2 : ∑ i ∈ Finset.range k, (1 / 2 + ε) ≤ ∑ i ∈ Finset.range k, μ[X i] :=
      Finset.sum_le_sum fun i _ => hmean i
    simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul] at h2
    rw [h1]
    nlinarith
  calc μ.real {ω | ∑ i ∈ Finset.range k, X i ω ≤ (k : ℝ) / 2}
      ≤ μ.real {ω | (k : ℝ) * ε ≤ ∑ i ∈ Finset.range k, Y i ω} :=
        measureReal_mono hsubset (measure_ne_top _ _)
    _ ≤ _ := hH
    _ = exp (-2 * k * ε ^ 2) := by
        congr 1
        have hc : (((‖(1 : ℝ) - 0‖₊ / 2) ^ 2 : NNReal) : ℝ) = 1 / 4 := by
          simp; norm_num
        rw [hc]
        rcases Nat.eq_zero_or_pos k with hk | hk
        · subst hk; simp
        · have : (k : ℝ) ≠ 0 := by positivity
          field_simp
          ring

/-- How many runs reach a target error δ: under the same hypotheses, any number of runs
k ≥ ln(1/δ)/(2ε²) makes the majority vote wrong with chance at most δ. So the runs needed
grow only with the log of the target and with one over the margin squared. -/
theorem majority_vote_runs_for_error
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {X : ℕ → Ω → ℝ} (hmeas : ∀ i, Measurable (X i)) (hindep : iIndepFun X μ)
    (h01 : ∀ i ω, X i ω = 0 ∨ X i ω = 1)
    {ε : ℝ} (hε : 0 < ε) (hright : ∀ i, 1 / 2 + ε ≤ μ.real {ω | X i ω = 1})
    {δ : ℝ} (hδ : 0 < δ) {k : ℕ} (hk : log (1 / δ) / (2 * ε ^ 2) ≤ k) :
    μ.real {ω | ∑ i ∈ Finset.range k, X i ω ≤ (k : ℝ) / 2} ≤ δ := by
  refine (majority_vote_error_le_exp hmeas hindep h01 hε hright k).trans ?_
  have hpos : 0 < 2 * ε ^ 2 := by positivity
  rw [div_le_iff₀ hpos, one_div, Real.log_inv] at hk
  calc exp (-2 * k * ε ^ 2) ≤ exp (log δ) := by
        apply exp_le_exp.mpr; nlinarith
    _ = δ := exp_log hδ

/-- The random-list check of a claimed product (Freivalds' check), Step 1 of the card.
Let A, B, C be integer tables with A * B ≠ C. Draw a list x with every entry from a finite
set S. Of the |S|^(number of entries) possible lists, the ones that miss the error
(A(Bx) = Cx) are at most a fraction 1/|S|: count of missing lists × |S| ≤ |S|^(entries). -/
theorem random_list_check_misses_at_most_one_over_card
    {ι κ τ : Type*} [Fintype ι] [Fintype κ] [Fintype τ] [DecidableEq τ]
    (A : Matrix ι κ ℤ) (B : Matrix κ τ ℤ) (C : Matrix ι τ ℤ) (hwrong : A * B ≠ C)
    (S : Finset ℤ) :
    ((Fintype.piFinset fun _ : τ => S).filter
        (fun x => A *ᵥ (B *ᵥ x) = C *ᵥ x)).card * S.card ≤ S.card ^ Fintype.card τ := by
  classical
  set D := A * B - C with hD
  obtain ⟨i, j, hij⟩ : ∃ i j, D i j ≠ 0 := by
    by_contra h
    apply hwrong
    ext a b
    by_contra hab
    exact h ⟨a, b, by simp only [hD, Matrix.sub_apply, ne_eq, sub_eq_zero]; exact hab⟩
  set M := (Fintype.piFinset fun _ : τ => S).filter (fun x => A *ᵥ (B *ᵥ x) = C *ᵥ x)
  have hMD : ∀ x ∈ M, (D *ᵥ x) i = 0 := by
    intro x hx
    simp only [M, Finset.mem_filter] at hx
    rw [hD, Matrix.sub_mulVec, ← Matrix.mulVec_mulVec, hx.2, sub_self]
    rfl
  have key : ∀ x ∈ M, ∀ y ∈ M, (∀ l, l ≠ j → x l = y l) → x j = y j := by
    intro x hx y hy hxy
    have h0 : (D *ᵥ (x - y)) i = 0 := by
      rw [Matrix.mulVec_sub, Pi.sub_apply, hMD x hx, hMD y hy, sub_self]
    have hs : (D *ᵥ (x - y)) i = D i j * (x j - y j) := by
      simp only [Matrix.mulVec, dotProduct]
      rw [Finset.sum_eq_single j]
      · simp
      · intro l _ hl
        simp [hxy l hl]
      · simp
    rw [hs] at h0
    have := (mul_eq_zero.mp h0).resolve_left hij
    linarith
  have hinj : Set.InjOn (fun p : (τ → ℤ) × ℤ => Function.update p.1 j p.2)
      (M ×ˢ S : Finset _) := by
    rintro ⟨x, s⟩ hp ⟨y, t⟩ hq hxy
    simp only [Finset.coe_product, Set.mem_prod, Finset.mem_coe] at hp hq
    simp only at hxy
    have hst : s = t := by
      have := congrFun hxy j
      simpa using this
    have hoff : ∀ l, l ≠ j → x l = y l := by
      intro l hl
      have := congrFun hxy l
      simpa [Function.update_of_ne hl] using this
    have hj := key x hp.1 y hq.1 hoff
    refine Prod.ext ?_ hst
    funext l
    by_cases hl : l = j
    · subst hl; exact hj
    · exact hoff l hl
  have hmaps : ∀ p ∈ M ×ˢ S, Function.update p.1 j p.2 ∈ Fintype.piFinset fun _ : τ => S := by
    rintro ⟨x, s⟩ hp
    rw [Finset.mem_product] at hp
    have hx := (Finset.mem_filter.mp hp.1).1
    rw [Fintype.mem_piFinset] at hx ⊢
    intro l
    by_cases hl : l = j
    · subst hl; simpa using hp.2
    · rw [Function.update_of_ne hl]; exact hx l
  have := Finset.card_le_card_of_injOn _ hmaps hinj
  rw [Finset.card_product, Fintype.card_piFinset, Finset.prod_const, Finset.card_univ] at this
  exact this

-- The rota: staff per shift A (wards W1..W3 by early, late, night), hours per shift B
-- (by Monday, Saturday, Sunday), the true staff-hours C = AB, and the table with
-- W2 Saturday mistyped as 36.
def rotaA : Matrix (Fin 3) (Fin 3) ℤ := !![4, 3, 2; 2, 2, 1; 5, 4, 3]
def rotaB : Matrix (Fin 3) (Fin 3) ℤ := !![8, 6, 6; 8, 8, 6; 10, 10, 12]
def rotaC : Matrix (Fin 3) (Fin 3) ℤ := !![76, 68, 66; 42, 38, 36; 102, 92, 90]
def rotaWrong : Matrix (Fin 3) (Fin 3) ℤ := !![76, 68, 66; 42, 36, 36; 102, 92, 90]
-- W2 Monday 44 and Saturday 36: two errors that cancel in the weekly total.
def rotaSwap : Matrix (Fin 3) (Fin 3) ℤ := !![76, 68, 66; 44, 36, 36; 102, 92, 90]

def rotaPasses (T : Matrix (Fin 3) (Fin 3) ℤ) (x : Fin 3 → ℤ) : Prop :=
  rotaA *ᵥ (rotaB *ᵥ x) = T *ᵥ x

instance (T : Matrix (Fin 3) (Fin 3) ℤ) : DecidablePred (rotaPasses T) := fun x => by
  unfold rotaPasses; infer_instance

def lists01 : Finset (Fin 3 → ℤ) := Fintype.piFinset fun _ => ({0, 1} : Finset ℤ)
def lists09 : Finset (Fin 3 → ℤ) := Fintype.piFinset fun _ => Finset.Icc (0 : ℤ) 9

-- The true table: C = AB, row by row.
example : rotaA * rotaB = rotaC := by decide
-- The two hand runs: x = (1, 0, 1) misses the mistyped 36, x = (0, 1, 1) catches it (74 ≠ 72).
example : rotaB *ᵥ ![1, 0, 1] = ![14, 14, 22] ∧ rotaA *ᵥ ![14, 14, 22] = ![142, 78, 192] ∧
    rotaWrong *ᵥ ![1, 0, 1] = ![142, 78, 192] := by decide
example : rotaB *ᵥ ![0, 1, 1] = ![12, 14, 22] ∧ rotaA *ᵥ ![12, 14, 22] = ![134, 74, 182] ∧
    rotaWrong *ᵥ ![0, 1, 1] = ![134, 72, 182] := by decide
-- A right table passes all 8 lists; the wrong one is missed by 4 of 8 0/1 lists.
example : (lists01.filter (rotaPasses rotaC)).card = 8 := by decide
example : (lists01.filter (rotaPasses rotaWrong)).card = 4 := by decide
-- Two fresh runs: 16 of the 64 coin strings miss, 0.5 × 0.5 = 0.25.
example : ((lists01 ×ˢ lists01).filter
    (fun p => rotaPasses rotaWrong p.1 ∧ rotaPasses rotaWrong p.2)).card = 16 := by decide
-- Lists with entries 0 to 9: 100 of the 1,000 lists miss, one over |S| = 10.
example : (lists09.filter (rotaPasses rotaWrong)).card = 100 := by decide +kernel
-- The two cancelling errors: 4 of 8 0/1 lists miss them, and the fixed list (1, 1, 1) always does.
example : (lists01.filter (rotaPasses rotaSwap)).card = 4 := by decide
example : rotaPasses rotaSwap ![1, 1, 1] := by decide
-- A vote of runs each right with chance 2/3: 193 runs bring the exact error under one in a
-- million, 191 do not. Wrong means at most half the runs right; j right runs have weight
-- C(k, j) 2^j out of 3^k.
example : 10 ^ 6 * ∑ j ∈ Finset.range 97, Nat.choose 193 j * 2 ^ j ≤ 3 ^ 193 := by decide +kernel
example : ¬ (10 ^ 6 * ∑ j ∈ Finset.range 96, Nat.choose 191 j * 2 ^ j ≤ 3 ^ 191) := by decide +kernel
-- Cost at side m = 1,000: one check is 3m² = 3,000,000 multiplications against m³ for a redo,
-- and 20 checks cost 6% of a redo.
example : 20 * (3 * 1000 ^ 2) * 100 = 6 * 1000 ^ 3 := by norm_num

#print axioms majority_vote_error_le_exp
#print axioms majority_vote_runs_for_error
#print axioms random_list_check_misses_at_most_one_over_card
