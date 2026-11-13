-- Markov chains: for a process on finitely many states, the next-step rule (tomorrow's chances given any history are today's row of the matrix) holds exactly when every path's chance is the start law times one matrix entry per step, those path chances add to 1, and the two-step chances are the entries of the matrix squared.
import Mathlib.Probability.ConditionalProbability
import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Real

open MeasureTheory ProbabilityTheory Matrix

theorem path_sum_general {S : Type*} [Fintype S] [DecidableEq S] (P : Matrix S S ℝ)
    (hP : P ∈ Matrix.rowStochastic ℝ S) (n : ℕ) : ∀ v : S → ℝ,
    ∑ h : Fin (n + 1) → S, v (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ) = ∑ i, v i := by
  induction n with
  | zero =>
    intro v
    simp only [Finset.univ_eq_empty, Finset.prod_empty, mul_one]
    exact Fintype.sum_equiv (Equiv.funUnique (Fin 1) S) _ _ (fun _ => rfl)
  | succ n ih =>
    intro v
    rw [← (Fin.consEquiv fun _ : Fin (n + 2) => S).sum_comp, Fintype.sum_prod_type]
    refine Finset.sum_congr rfl fun i _ => ?_
    have := ih (fun k => v i * P i k)
    simp only [Fin.consEquiv_apply] at *
    simp only [Fin.prod_univ_succ, Fin.cons_zero, Fin.castSucc_zero,
      Fin.cons_succ, ← Fin.succ_castSucc] at *
    calc _ = ∑ g : Fin (n + 1) → S, v i * P i (g 0) * ∏ m : Fin n, P (g m.castSucc) (g m.succ) :=
          Finset.sum_congr rfl fun g _ => by ring
      _ = _ := by rw [this, ← Finset.mul_sum, Matrix.sum_row_of_mem_rowStochastic hP, mul_one]

#print axioms path_sum_general

theorem markov_pathSet_measurable {Ω S : Type*} [MeasurableSpace Ω] [MeasurableSpace S]
    [MeasurableSingletonClass S] (X : ℕ → Ω → S) (hX : ∀ n, Measurable (X n)) (n : ℕ)
    (h : Fin (n + 1) → S) : MeasurableSet {ω | ∀ m : Fin (n + 1), X m ω = h m} := by
  rw [Set.ofPred_forall]
  exact MeasurableSet.iInter fun m => hX m (measurableSet_singleton (h m))

#print axioms markov_pathSet_measurable

theorem markov_pathSet_succ {Ω S : Type*} (X : ℕ → Ω → S) (n : ℕ) (h : Fin (n + 2) → S) :
    {ω | ∀ m : Fin (n + 2), X m ω = h m} =
      {ω | ∀ m : Fin (n + 1), X m ω = h m.castSucc} ∩ {ω | X (n + 1) ω = h (Fin.last (n + 1))} := by
  ext ω
  simp only [Set.mem_ofPred_eq, Set.mem_inter_iff, Fin.forall_fin_succ' (P := fun m => X m ω = h m),
    Fin.val_castSucc, Fin.val_last]

#print axioms markov_pathSet_succ

theorem markov_pathSet_zero {Ω S : Type*} (X : ℕ → Ω → S) (i : S) :
    {ω | ∀ m : Fin 1, X m ω = (fun _ => i) m} = {ω | X 0 ω = i} := by
  ext ω
  simp

#print axioms markov_pathSet_zero

theorem markov_pathProd_succ {S : Type*} (α : S → ℝ) (P : Matrix S S ℝ) (n : ℕ)
    (h : Fin (n + 2) → S) :
    α (h 0) * ∏ m : Fin (n + 1), P (h m.castSucc) (h m.succ) =
      (α ((fun m : Fin (n + 1) => h m.castSucc) 0) *
        ∏ m : Fin n, P ((fun m : Fin (n + 1) => h m.castSucc) m.castSucc)
          ((fun m : Fin (n + 1) => h m.castSucc) m.succ)) *
        P ((fun m : Fin (n + 1) => h m.castSucc) (Fin.last n)) (h (Fin.last (n + 1))) := by
  rw [Fin.prod_univ_castSucc]
  simp only [Fin.castSucc_zero, Fin.succ_last, Fin.succ_castSucc]
  ring

#print axioms markov_pathProd_succ

/-- A Markov chain, two ways. Take a process `X 0, X 1, …` on a finite set of states `S`, a start
law `α` (chances that add to 1) and a transition matrix `P` (no negative entry, each row adds
to 1). Statement (A), the definition: day 0 follows `α`, and for every history `i₀, …, iₙ` with
positive chance, the chance of state `j` tomorrow given that history is `p_{iₙ j}`, the entry in
today's row. Statement (B), the factorisation: for every `n`, every path `i₀, …, iₙ` has chance
`α_{i₀} p_{i₀ i₁} ⋯ p_{iₙ₋₁ iₙ}`. The card proves (A) and (B) say the same thing. -/
theorem markov_property_iff_path_factorisation {Ω S : Type*} [MeasurableSpace Ω]
    [Fintype S] [DecidableEq S] [MeasurableSpace S] [MeasurableSingletonClass S]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (X : ℕ → Ω → S) (hX : ∀ n, Measurable (X n))
    (α : S → ℝ) (hα0 : ∀ i, 0 ≤ α i) (hα1 : ∑ i, α i = 1) (P : Matrix S S ℝ)
    (hP : P ∈ Matrix.rowStochastic ℝ S) :
    ((∀ i, μ.real {ω | X 0 ω = i} = α i) ∧
      ∀ (n : ℕ) (h : Fin (n + 1) → S) (j : S),
        μ {ω | ∀ m : Fin (n + 1), X m ω = h m} ≠ 0 →
          (μ[{ω | X (n + 1) ω = j} | {ω | ∀ m : Fin (n + 1), X m ω = h m}]).toReal =
            P (h (Fin.last n)) j) ↔
    ∀ (n : ℕ) (h : Fin (n + 1) → S),
      μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} =
        α (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ) := by
  constructor
  · rintro ⟨h0, hstep⟩ n
    induction n with
    | zero =>
      intro h
      have := markov_pathSet_zero X (h 0)
      have hh : h = fun _ => h 0 := funext fun m => by rw [Subsingleton.elim (α := Fin 1) m 0]
      rw [hh, this, h0]
      simp
    | succ n ih =>
      intro h
      set g : Fin (n + 1) → S := fun m => h m.castSucc with hg
      rw [markov_pathSet_succ, markov_pathProd_succ, ← ih g]
      by_cases hz : μ {ω | ∀ m : Fin (n + 1), X m ω = g m} = 0
      · have h1 : μ.real {ω | ∀ m : Fin (n + 1), X m ω = g m} = 0 := by
          simp [measureReal_def, hz]
        have h2 : μ.real ({ω | ∀ m : Fin (n + 1), X m ω = g m} ∩
            {ω | X (n + 1) ω = h (Fin.last (n + 1))}) = 0 := by
          rw [measureReal_def, measure_mono_null Set.inter_subset_left hz]; simp
        rw [h1, h2, zero_mul]
      · have := hstep n g (h (Fin.last (n + 1))) hz
        rw [cond_apply (markov_pathSet_measurable X hX n g), ENNReal.toReal_mul,
          ENNReal.toReal_inv] at this
        rw [← this, ← measureReal_def, ← measureReal_def]
        have hne : μ.real {ω | ∀ m : Fin (n + 1), X m ω = g m} ≠ 0 := by
          rw [measureReal_def]
          exact ENNReal.toReal_ne_zero.mpr ⟨hz, measure_ne_top _ _⟩
        field_simp
        rfl
  · intro hB
    refine ⟨fun i => ?_, fun n h j hz => ?_⟩
    · have := hB 0 (fun _ => i)
      rw [markov_pathSet_zero] at this
      simpa using this
    · rw [cond_apply (markov_pathSet_measurable X hX n h), ENNReal.toReal_mul,
        ENNReal.toReal_inv, ← measureReal_def, ← measureReal_def]
      have e1 := hB (n + 1) (Fin.snoc h j)
      rw [markov_pathSet_succ, markov_pathProd_succ] at e1
      simp only [Fin.snoc_castSucc, Fin.snoc_last] at e1
      have e2 := hB n h
      have hne : μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} ≠ 0 := by
        rw [measureReal_def]
        exact ENNReal.toReal_ne_zero.mpr ⟨hz, measure_ne_top _ _⟩
      rw [e1, ← e2]
      field_simp

/-- The products are a probability table. For a start law `α` and a transition matrix `P`
(no negative entry, rows adding to 1), the products `α_{i₀} p_{i₀ i₁} ⋯ p_{iₙ₋₁ iₙ}` over all
paths of `n` steps add to 1, for every `n`. -/
theorem path_products_sum_to_one {S : Type*} [Fintype S] [DecidableEq S]
    (α : S → ℝ) (hα0 : ∀ i, 0 ≤ α i) (hα1 : ∑ i, α i = 1) (P : Matrix S S ℝ)
    (hP : P ∈ Matrix.rowStochastic ℝ S) (n : ℕ) :
    ∑ h : Fin (n + 1) → S, α (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ) = 1 := by
  have := path_sum_general P hP n α
  rw [this, hα1]

/-- Two days is a sum over the middle day. If every path's chance is the start law times one
matrix entry per step, then for any state `i` with positive chance on day 0, the chance of state
`j` on day 2 given state `i` on day 0 is `∑ k, p_{ik} p_{kj}`, the `(i, j)` entry of `P²`. -/
theorem two_step_chance_eq_matrix_sq {Ω S : Type*} [MeasurableSpace Ω]
    [Fintype S] [DecidableEq S] [MeasurableSpace S] [MeasurableSingletonClass S]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (X : ℕ → Ω → S) (hX : ∀ n, Measurable (X n))
    (α : S → ℝ) (hα0 : ∀ i, 0 ≤ α i) (hα1 : ∑ i, α i = 1) (P : Matrix S S ℝ)
    (hP : P ∈ Matrix.rowStochastic ℝ S)
    (hpath : ∀ (n : ℕ) (h : Fin (n + 1) → S),
      μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} =
        α (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ))
    (i j : S) (hi : μ {ω | X 0 ω = i} ≠ 0) :
    (μ[{ω | X 2 ω = j} | {ω | X 0 ω = i}]).toReal = (P ^ 2) i j ∧
      (P ^ 2) i j = ∑ k, P i k * P k j := by
  have hsq : (P ^ 2) i j = ∑ k, P i k * P k j := by rw [sq, Matrix.mul_apply]
  refine ⟨?_, hsq⟩
  have h0 := hpath 0 (fun _ => i)
  rw [markov_pathSet_zero] at h0
  simp only [Finset.univ_eq_empty, Finset.prod_empty, mul_one] at h0
  have hmeas0 : MeasurableSet {ω | X 0 ω = i} := hX 0 (measurableSet_singleton i)
  have hset : {ω | X 0 ω = i} ∩ {ω | X 2 ω = j} =
      ⋃ k ∈ (Finset.univ : Finset S), {ω | ∀ m : Fin 3, X m ω = ![i, k, j] m} := by
    ext ω
    simp [Fin.forall_fin_succ]
  have hsum : μ.real ({ω | X 0 ω = i} ∩ {ω | X 2 ω = j}) = α i * ∑ k, P i k * P k j := by
    rw [hset, measureReal_biUnion_finset]
    · rw [Finset.mul_sum]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [hpath 2]
      simp [Fin.prod_univ_two]
    · intro k _ k' _ hkk'
      refine Set.disjoint_left.mpr fun ω h1 h2 => hkk' ?_
      have a := h1 1
      have b := h2 1
      simp at a b
      rw [← a, ← b]
    · intro k _
      exact markov_pathSet_measurable X hX 2 _
  have hne : μ.real {ω | X 0 ω = i} ≠ 0 := by
    rw [measureReal_def]
    exact ENNReal.toReal_ne_zero.mpr ⟨hi, measure_ne_top _ _⟩
  rw [cond_apply hmeas0, ENNReal.toReal_mul, ENNReal.toReal_inv, ← measureReal_def,
    ← measureReal_def, hsum, hsq, h0]
  rw [h0] at hne
  field_simp

/-! The card's worked numbers, in whole tenths (states 0 sunny, 1 cloudy, 2 rainy). -/

-- The weather matrix in tenths: each row adds to 10; the columns add to 11, 11 and 8.
example : (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) *ᵥ (fun _ => 1) =
    (fun _ => 10) := by decide

example : (fun _ => 1) ᵥ* (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) =
    ![11, 11, 8] := by decide

-- P² in hundredths: S 0.47, 0.34, 0.19; C 0.36, 0.37, 0.27; R 0.32, 0.38, 0.30.
example : (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 2 =
    !![47, 34, 19; 36, 37, 27; 32, 38, 30] := by decide

-- Sunny to rainy in two days, three routes: 0.06 + 0.09 + 0.04 = 0.19.
example : 6 * 1 + 3 * 3 + 1 * 4 = 19 := by decide

-- The week S S C C R R S from a sunny Monday: 0.6 × 0.3 × 0.4 × 0.3 × 0.4 × 0.2 = 0.001728,
-- about 1 in 579 (10⁶ / 1728 is nearer 579 than 578).
example : 6 * 3 * 4 * 3 * 4 * 2 = 1728 ∧ 579 * 1728 - 1000000 < 1000000 - 578 * 1728 := by
  decide

-- Taking the days as independent gives 0.6 × 0.47 = 0.282, not 0.6 × 0.6 = 0.36.
example : 6 * 47 = 282 ∧ 6 * 6 * 10 = 360 := by decide

-- All 81 four-day paths from the forecast start law 0.5, 0.3, 0.2: the weights add to 1.
example : ∑ a : Fin 3, ∑ b : Fin 3, ∑ c : Fin 3, ∑ d : Fin 3,
    ![5, 3, 2] a * (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) a b *
      (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) b c *
      (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) c d = 10000 := by decide

#print axioms markov_property_iff_path_factorisation
#print axioms path_products_sum_to_one
#print axioms two_step_chance_eq_matrix_sq
