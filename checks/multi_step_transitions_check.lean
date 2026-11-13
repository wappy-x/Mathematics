-- n-step transitions: for a Markov chain on finitely many states, the chance of going from state i to state j in n steps is the (i, j) entry of the n-th power of the transition matrix, the law on day n is the start law times that power, and the powers obey Chapman-Kolmogorov, P^(m+n) = P^m P^n entry by entry.
import Mathlib.Probability.ConditionalProbability
import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Matrix

/-! Setting, as in the card's Detailed proof. `S` is a finite set of states, `X 0, X 1, …` is
the process on a probability space `(Ω, μ)`, `α` is the start law (chances that add to 1) and
`P` is the transition matrix (no negative entry, each row adds to 1). The process is a
time-homogeneous Markov chain with start law `α` and matrix `P`: for every `n`, every path
`i₀, …, iₙ` has chance `α_{i₀} p_{i₀ i₁} ⋯ p_{iₙ₋₁ iₙ}`, the same `P` on every day.
`P ^ 0 = 1`, the identity matrix. -/

theorem path_sum_eq_dotProduct_pow_mulVec {S : Type*} [Fintype S] [DecidableEq S]
    (P : Matrix S S ℝ) : ∀ (n : ℕ) (u g : S → ℝ),
    ∑ h : Fin (n + 1) → S, u (h 0) * (∏ m : Fin n, P (h m.castSucc) (h m.succ)) *
      g (h (Fin.last n)) = u ⬝ᵥ ((P ^ n) *ᵥ g)
  | 0, u, g => by
    rw [← (Equiv.funUnique (Fin 1) S).symm.sum_comp]
    simp [dotProduct]
  | n + 1, u, g => by
    rw [← (Fin.consEquiv fun _ => S).sum_comp, Fintype.sum_prod_type]
    have key : ∀ a : S, ∑ t : Fin (n + 1) → S,
        u ((Fin.consEquiv fun _ => S) (a, t) 0) *
          (∏ m : Fin (n + 1), P ((Fin.consEquiv fun _ => S) (a, t) m.castSucc)
            ((Fin.consEquiv fun _ => S) (a, t) m.succ)) *
          g ((Fin.consEquiv fun _ => S) (a, t) (Fin.last (n + 1))) =
        ∑ b, (u a * P a b) * ((P ^ n) *ᵥ g) b := by
      intro a
      have ih := path_sum_eq_dotProduct_pow_mulVec P n (fun b => u a * P a b) g
      rw [dotProduct] at ih
      rw [← ih]
      refine Finset.sum_congr rfl fun t _ => ?_
      rw [← Fin.succ_last]
      simp only [Fin.consEquiv_apply, Fin.prod_univ_succ, Fin.cons_zero, Fin.castSucc_zero,
        Fin.cons_succ, ← Fin.succ_castSucc]
      ring
    simp_rw [key]
    rw [pow_succ', ← mulVec_mulVec]
    simp only [dotProduct, mulVec, Finset.mul_sum]
    refine Finset.sum_congr rfl fun a _ => Finset.sum_congr rfl fun b _ => ?_
    ring_nf

#print axioms path_sum_eq_dotProduct_pow_mulVec

theorem measureReal_path_event {Ω S : Type*} [MeasurableSpace Ω]
    [Fintype S] [DecidableEq S] [MeasurableSpace S] [MeasurableSingletonClass S]
    (μ : Measure Ω) [IsFiniteMeasure μ] (X : ℕ → Ω → S) (hX : ∀ n, Measurable (X n))
    (n : ℕ) (Φ : (Fin (n + 1) → S) → Prop) [DecidablePred Φ] :
    μ.real {ω | Φ (fun m : Fin (n + 1) => X m ω)} =
      ∑ h : Fin (n + 1) → S, if Φ h then μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} else 0 := by
  rw [← Finset.sum_filter]
  have hset : {ω | Φ (fun m : Fin (n + 1) => X m ω)} =
      ⋃ h ∈ Finset.univ.filter Φ, {ω | ∀ m : Fin (n + 1), X m ω = h m} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_filter, Finset.mem_univ, true_and,
      exists_prop]
    constructor
    · intro hω
      exact ⟨_, hω, fun m => rfl⟩
    · rintro ⟨h, hh, hω⟩
      have : (fun m : Fin (n + 1) => X m ω) = h := funext hω
      rw [this]
      exact hh
  rw [hset]
  refine measureReal_biUnion_finset ?_ ?_ (fun _ _ => measure_ne_top _ _)
  · intro h _ h' _ hne
    refine Set.disjoint_left.mpr fun ω hω hω' => hne ?_
    funext m
    have e1 : X m ω = h m := hω m
    have e2 : X m ω = h' m := hω' m
    rw [← e1, e2]
  · intro h _
    simp only [Set.ofPred_forall]
    exact MeasurableSet.iInter fun m => hX m (measurableSet_singleton _)

#print axioms measureReal_path_event

theorem joint_law {Ω S : Type*} [MeasurableSpace Ω]
    [Fintype S] [DecidableEq S] [MeasurableSpace S] [MeasurableSingletonClass S]
    (μ : Measure Ω) (X : ℕ → Ω → S) (α : S → ℝ) (P : Matrix S S ℝ)
    (hpath : ∀ (n : ℕ) (h : Fin (n + 1) → S),
      μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} =
        α (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ))
    (n : ℕ) (u g : S → ℝ) :
    ∑ h : Fin (n + 1) → S, μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} * u (h 0) *
      g (h (Fin.last n)) = (fun k => α k * u k) ⬝ᵥ ((P ^ n) *ᵥ g) := by
  rw [← path_sum_eq_dotProduct_pow_mulVec]
  refine Finset.sum_congr rfl fun h _ => ?_
  rw [hpath]
  ring

#print axioms joint_law

/-- **n-step chances are matrix powers.** For a Markov chain on finitely many states with start
law `α` and the same transition matrix `P` every day, and for every number of days `n` and
states `i`, `j` with `i` having positive chance on day 0: the chance of state `j` on day `n`,
given state `i` on day 0, is the `(i, j)` entry of `P ^ n`. -/
theorem n_step_chance_eq_matrix_pow {Ω S : Type*} [MeasurableSpace Ω]
    [Fintype S] [DecidableEq S] [MeasurableSpace S] [MeasurableSingletonClass S]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (X : ℕ → Ω → S) (hX : ∀ n, Measurable (X n))
    (α : S → ℝ) (hα0 : ∀ i, 0 ≤ α i) (hα1 : ∑ i, α i = 1) (P : Matrix S S ℝ)
    (hP : P ∈ Matrix.rowStochastic ℝ S)
    (hpath : ∀ (n : ℕ) (h : Fin (n + 1) → S),
      μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} =
        α (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ))
    (n : ℕ) (i j : S) (hi : μ {ω | X 0 ω = i} ≠ 0) :
    (μ[{ω | X n ω = j} | {ω | X 0 ω = i}]).toReal = (P ^ n) i j := by
  have hmeas : MeasurableSet {ω | X 0 ω = i} := hX 0 (measurableSet_singleton i)
  have h0 : μ.real {ω | X 0 ω = i} = α i := by
    have := hpath 0 (fun _ => i)
    simp only [Finset.univ_eq_empty, Finset.prod_empty, mul_one] at this
    rw [← this]
    congr 1
    ext ω
    simp
  have hα : α i ≠ 0 := by
    rw [← h0, measureReal_def]
    exact ENNReal.toReal_ne_zero.mpr ⟨hi, measure_ne_top _ _⟩
  have hjoint : μ.real ({ω | X 0 ω = i} ∩ {ω | X n ω = j}) = α i * (P ^ n) i j := by
    have h1 := measureReal_path_event μ X hX n (fun h => h 0 = i ∧ h (Fin.last n) = j)
    simp only [Fin.val_last, Fin.val_zero] at h1
    have hs : {ω | X 0 ω = i} ∩ {ω | X n ω = j} = {ω | X 0 ω = i ∧ X n ω = j} := rfl
    rw [hs, h1]
    have h2 := joint_law μ X α P hpath n (Pi.single i 1) (Pi.single j 1)
    have h3 : (fun k => α k * (Pi.single i (1 : ℝ) : S → ℝ) k) ⬝ᵥ ((P ^ n) *ᵥ Pi.single j 1) =
        α i * (P ^ n) i j := by
      have : (fun k => α k * (Pi.single i (1 : ℝ) : S → ℝ) k) = Pi.single i (α i) := by
        funext k
        by_cases hk : k = i
        · subst hk; simp
        · simp [hk]
      rw [this, single_dotProduct, mulVec_single_one]
      rfl
    rw [← h3, ← h2]
    refine Finset.sum_congr rfl fun h _ => ?_
    by_cases ha : h 0 = i <;> by_cases hb : h (Fin.last n) = j <;> simp [ha, hb]
  rw [cond_apply hmeas, ENNReal.toReal_mul, ENNReal.toReal_inv, ← measureReal_def,
    ← measureReal_def, hjoint, h0]
  field_simp

/-- **The law on day n is the start law times `P ^ n`.** For the same chain, for every `n` and
every state `j`, the chance of `j` on day `n` is entry `j` of the row `α P ⁿ`, that is
`∑ i, α i * (P ^ n) i j`. -/
theorem law_on_day_n_eq_start_law_mul_pow {Ω S : Type*} [MeasurableSpace Ω]
    [Fintype S] [DecidableEq S] [MeasurableSpace S] [MeasurableSingletonClass S]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (X : ℕ → Ω → S) (hX : ∀ n, Measurable (X n))
    (α : S → ℝ) (hα0 : ∀ i, 0 ≤ α i) (hα1 : ∑ i, α i = 1) (P : Matrix S S ℝ)
    (hP : P ∈ Matrix.rowStochastic ℝ S)
    (hpath : ∀ (n : ℕ) (h : Fin (n + 1) → S),
      μ.real {ω | ∀ m : Fin (n + 1), X m ω = h m} =
        α (h 0) * ∏ m : Fin n, P (h m.castSucc) (h m.succ))
    (n : ℕ) (j : S) :
    μ.real {ω | X n ω = j} = (α ᵥ* (P ^ n)) j := by
  have h1 := measureReal_path_event μ X hX n (fun h => h (Fin.last n) = j)
  simp only [Fin.val_last] at h1
  rw [h1]
  have h2 := joint_law μ X α P hpath n (fun _ => 1) (Pi.single j 1)
  simp only [mul_one, mulVec_single_one] at h2
  have h3 : (fun k => α k) ⬝ᵥ (P ^ n).col j = (α ᵥ* (P ^ n)) j := by
    simp [dotProduct, vecMul]
  rw [← h3, ← h2]
  refine Finset.sum_congr rfl fun h _ => ?_
  by_cases hh : h (Fin.last n) = j
  · simp [hh]
  · simp [hh]

/-- **Chapman-Kolmogorov.** For a matrix `P` on finitely many states and any numbers of days
`m` and `n`, the `(i, j)` entry of `P ^ (m + n)` is the sum, over every state `k` on day `m`,
of the first leg's entry `(P ^ m) i k` times the second leg's entry `(P ^ n) k j`. -/
theorem chapman_kolmogorov {S : Type*} [Fintype S] [DecidableEq S] (P : Matrix S S ℝ)
    (m n : ℕ) (i j : S) :
    (P ^ (m + n)) i j = ∑ k, (P ^ m) i k * (P ^ n) k j := by
  rw [pow_add, Matrix.mul_apply]

/-! The card's worked numbers, in whole numbers: `P` in tenths, so `P ^ n` is in units of
`10⁻ⁿ`. States: 0 sunny, 1 cloudy, 2 rainy. -/

-- P² and the 0.19 of markov-chains: sunny to rainy in two days.
example : (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 2 =
    !![47, 34, 19; 36, 37, 27; 32, 38, 30] := by decide

-- The law day by day from a sunny start, (1, 0, 0) times P ^ n, in units of 10⁻ⁿ:
-- day 3 (0.422, 0.353, 0.225), day 4 (0.4041, 0.3578, 0.2381).
example : ![1, 0, 0] ᵥ* (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 3 =
    ![422, 353, 225] := by decide
example : ![1, 0, 0] ᵥ* (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 4 =
    ![4041, 3578, 2381] := by decide

-- P ^ 7, the week-ahead table: from sunny, rain a week out is 0.2454961, and the whole law on
-- day 7 is (0.3939966, 0.3605073, 0.2454961); the cloudy and rainy rows are the code's.
example : (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 7 =
    !![3939966, 3605073, 2454961; 3932013, 3607204, 2460783; 3929102, 3607984, 2462914] := by
  decide

-- Each row of P ^ 7 still adds to 1, that is to 10⁷ in these units.
example : (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 7 *ᵥ (fun _ => 1) =
    (fun _ => 10 ^ 7) := by decide

-- 3⁷ = 2187 seven-day paths from a sunny start.
example : Fintype.card (Fin 7 → Fin 3) = 2187 := by norm_num

-- Split at day 3: P³'s sunny row (0.422, 0.353, 0.225) against P⁴'s rainy column
-- (0.2381, 0.2493, 0.2534) gives 0.2454961, the same as seven one-day steps.
example : (fun k => ((!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 4) k 2) =
    ![2381, 2493, 2534] := by decide
example : 422 * 2381 + 353 * 2493 + 225 * 2534 = 2454961 := by decide

-- Uncertain start (0.5, 0.3, 0.2): rain on day 7 is
-- 0.5 × 0.2454961 + 0.3 × 0.2460783 + 0.2 × 0.2462914 = 0.24582982, printed 0.2458298.
example : ![5, 3, 2] ᵥ* (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 7 =
    ![39354073, 36062945, 24582982] := by decide
example : 5 * 2454961 + 3 * 2460783 + 2 * 2462914 = 24582982 := by decide

-- The long-run mix π = (24, 22, 15)/61 satisfies π P = π.
example : ![24, 22, 15] ᵥ* (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) =
    ![240, 220, 150] := by decide

-- The eigenvalues add to the diagonal sum 1.4 and multiply to the determinant 0.01
-- (in tenths: trace 14, determinant 10 thousandths).
example : Matrix.trace (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℤ) = 14 := by
  decide
example : Matrix.det (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℤ) = 10 := by
  norm_num [Matrix.det_fin_three]

-- What breaks: P ^ 7 times the start as a column gives the sunny column
-- (0.3939966, 0.3932013, 0.3929102), adding to 1.1801081, not a law.
example : (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 7 *ᵥ ![1, 0, 0] =
    ![3939966, 3932013, 3929102] := by decide
example : 3939966 + 3932013 + 3929102 = 11801081 := by decide

-- What breaks: three days of P then four of the wet table gives rain on day 7 at 0.4478788;
-- the seasons in the wrong order give 0.2538128. Matrices do not commute.
example : ((!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 3 *
    (!![4, 4, 2; 2, 4, 4; 1, 3, 6] : Matrix (Fin 3) (Fin 3) ℕ) ^ 4) 0 2 = 4478788 := by decide
example : ((!![4, 4, 2; 2, 4, 4; 1, 3, 6] : Matrix (Fin 3) (Fin 3) ℕ) ^ 4 *
    (!![6, 3, 1; 3, 4, 3; 2, 4, 4] : Matrix (Fin 3) (Fin 3) ℕ) ^ 3) 0 2 = 2538128 := by decide

#print axioms n_step_chance_eq_matrix_pow
#print axioms law_on_day_n_eq_start_law_mul_pow
#print axioms chapman_kolmogorov
