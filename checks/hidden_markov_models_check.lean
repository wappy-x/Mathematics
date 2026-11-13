-- Hidden Markov models: when hidden weather follows a Markov chain and each day's signal depends on that day's weather alone, the chance of the signals is the total of the forward recursion, which equals the brute-force sum over all hidden paths, and the Viterbi and forward-backward recursions give the brute-force best path and per-day sums.
import Mathlib.Probability.ConditionalProbability
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Pi
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Real

open MeasureTheory ProbabilityTheory

namespace HMM

variable {R S O : Type*}

/-- The joint chance, by the card's product formula, of the hidden path `x 0, …, x n` together
with the signals `y 0, …, y n`: `ν_{x₀} b_{x₀}(y₀) ∏ p_{x_{k} x_{k+1}} b_{x_{k+1}}(y_{k+1})`.
Days are numbered from 0 here (the card's Monday is day 0). -/
def pathChance [CommSemiring R] (ν : S → R) (p : S → S → R) (b : S → O → R) (y : ℕ → O)
    (n : ℕ) (x : Fin (n + 1) → S) : R :=
  ν (x 0) * b (x 0) (y 0) *
    ∏ k : Fin n, p (x k.castSucc) (x k.succ) * b (x k.succ) (y ((k : ℕ) + 1))

/-- The forward recursion `α`: `α₀(i) = ν_i b_i(y₀)`, `α_{n+1}(i) = (∑_j α_n(j) p_{ji}) b_i(y_{n+1})`. -/
def forward [CommSemiring R] [Fintype S] (ν : S → R) (p : S → S → R) (b : S → O → R)
    (y : ℕ → O) : ℕ → S → R
  | 0, i => ν i * b i (y 0)
  | n + 1, i => (∑ j, forward ν p b y n j * p j i) * b i (y (n + 1))

/-- The backward recursion `β`: `backward m n i` is built from the `m` signals after day `n`,
given weather `i` on day `n`. It is `1` when `m = 0`, and otherwise
`∑_j p_{ij} b_j(y_{n+1})` times `backward (m - 1) (n + 1) j`. -/
def backward [CommSemiring R] [Fintype S] (p : S → S → R) (b : S → O → R) (y : ℕ → O) :
    ℕ → ℕ → S → R
  | 0, _, _ => 1
  | m + 1, n, i => ∑ j, p i j * b j (y (n + 1)) * backward p b y m (n + 1) j

/-- The Viterbi recursion `δ`: as the forward one, with "take the largest" in place of "add":
`δ₀(i) = ν_i b_i(y₀)`, `δ_{n+1}(i) = (max_j δ_n(j) p_{ji}) b_i(y_{n+1})`. -/
def viterbi [CommSemiring R] [SemilatticeSup R] [Fintype S] [Nonempty S] (ν : S → R)
    (p : S → S → R) (b : S → O → R) (y : ℕ → O) : ℕ → S → R
  | 0, i => ν i * b i (y 0)
  | n + 1, i =>
      (Finset.univ.sup' Finset.univ_nonempty fun j => viterbi ν p b y n j * p j i) *
        b i (y (n + 1))


theorem pathChance_succ [CommSemiring R] (ν : S → R) (p : S → S → R) (b : S → O → R)
    (y : ℕ → O) (n : ℕ) (x : Fin (n + 2) → S) :
    pathChance ν p b y (n + 1) x = pathChance ν p b y n (Fin.init x) *
      (p (x (Fin.last n).castSucc) (x (Fin.last (n + 1))) * b (x (Fin.last (n + 1))) (y (n + 1))) := by
  unfold pathChance
  rw [Fin.prod_univ_castSucc]
  simp [Fin.init, mul_assoc]

theorem pathChance_snoc [CommSemiring R] (ν : S → R) (p : S → S → R) (b : S → O → R)
    (y : ℕ → O) (n : ℕ) (x : Fin (n + 1) → S) (z : S) :
    pathChance ν p b y (n + 1) (Fin.snoc x z : Fin (n + 2) → S) = pathChance ν p b y n x *
      (p (x (Fin.last n)) z * b z (y (n + 1))) := by
  rw [pathChance_succ]
  simp

theorem forward_eq_sum [CommSemiring R] [Fintype S] [DecidableEq S] (ν : S → R) (p : S → S → R)
    (b : S → O → R) (y : ℕ → O) (n : ℕ) (i : S) :
    forward ν p b y n i =
      ∑ x : Fin (n + 1) → S, if x (Fin.last n) = i then pathChance ν p b y n x else 0 := by
  induction n generalizing i with
  | zero =>
    rw [← (Equiv.funUnique (Fin 1) S).symm.sum_comp]
    simp [forward, pathChance]
  | succ n ih =>
    rw [← (Fin.snocEquiv (fun _ => S)).sum_comp, Fintype.sum_prod_type]
    simp only [Fin.snocEquiv_apply, Fin.snoc_last, pathChance_snoc]
    simp only [forward, ih, Finset.sum_mul]
    rw [Finset.sum_comm]
    simp [Finset.sum_ite_eq', mul_assoc]

#print axioms pathChance_succ
#print axioms pathChance_snoc
#print axioms forward_eq_sum


theorem viterbi_isGreatest [Fintype S] [Nonempty S]
    (ν : S → ℝ) (p : S → S → ℝ) (b : S → O → ℝ)
    (hp : ∀ i j, 0 ≤ p i j) (hb : ∀ i o, 0 ≤ b i o) (y : ℕ → O) (n : ℕ) (i : S) :
    IsGreatest (pathChance ν p b y n '' {x | x (Fin.last n) = i}) (viterbi ν p b y n i) := by
  induction n generalizing i with
  | zero =>
    refine ⟨⟨fun _ => i, rfl, by simp [pathChance, viterbi]⟩, ?_⟩
    rintro _ ⟨x, hx, rfl⟩
    simp only [Set.mem_ofPred_eq] at hx
    have : x 0 = i := hx
    simp [pathChance, viterbi, this]
  | succ n ih =>
    obtain ⟨j, -, hj⟩ := Finset.exists_mem_eq_sup' (Finset.univ_nonempty (α := S))
      (fun j => viterbi ν p b y n j * p j i)
    refine ⟨?_, ?_⟩
    · obtain ⟨x, hx, hxv⟩ := (ih j).1
      refine ⟨Fin.snoc x i, by simp, ?_⟩
      simp only [Set.mem_ofPred_eq] at hx
      rw [pathChance_snoc, hxv, hx, viterbi, hj]
      ring
    · rintro _ ⟨x, hx, rfl⟩
      simp only [Set.mem_ofPred_eq] at hx
      rw [← Fin.snoc_init_self x, pathChance_snoc, hx, viterbi, ← mul_assoc]
      apply mul_le_mul_of_nonneg_right _ (hb _ _)
      refine le_trans ?_ (Finset.le_sup' (fun j => viterbi ν p b y n j * p j i)
        (Finset.mem_univ (Fin.init x (Fin.last n))))
      exact mul_le_mul_of_nonneg_right ((ih _).2 ⟨_, rfl, rfl⟩) (hp _ _)

#print axioms viterbi_isGreatest


/-- Backward recursion with terminal weights `w` in place of `1`. -/
def backwardW [CommSemiring R] [Fintype S] (p : S → S → R) (b : S → O → R) (y : ℕ → O) :
    ℕ → ℕ → (S → R) → S → R
  | 0, _, w, i => w i
  | m + 1, n, w, i => ∑ j, p i j * b j (y (n + 1)) * backwardW p b y m (n + 1) w j

theorem backwardW_one [CommSemiring R] [Fintype S] (p : S → S → R) (b : S → O → R)
    (y : ℕ → O) (m n : ℕ) (i : S) :
    backwardW p b y m n (fun _ => 1) i = backward p b y m n i := by
  induction m generalizing n i with
  | zero => rfl
  | succ m ih => simp [backwardW, backward, ih]

theorem backwardW_succ [CommSemiring R] [Fintype S] (p : S → S → R) (b : S → O → R)
    (y : ℕ → O) (m n : ℕ) (w : S → R) (i : S) :
    backwardW p b y (m + 1) n w i =
      backwardW p b y m n (fun k => ∑ z, p k z * b z (y (n + m + 1)) * w z) i := by
  induction m generalizing n i with
  | zero => simp [backwardW]
  | succ m ih =>
    rw [backwardW, backwardW]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [ih]
    have : n + 1 + m + 1 = n + (m + 1) + 1 := by omega
    rw [this]

theorem sum_paths_through_weighted [CommSemiring R] [Fintype S] [DecidableEq S]
    (ν : S → R) (p : S → S → R) (b : S → O → R) (y : ℕ → O) (n : ℕ) (i : S) (m : ℕ) :
    ∀ w : S → R,
    ∑ x : Fin (n + m + 1) → S,
      (if x ⟨n, by omega⟩ = i then pathChance ν p b y (n + m) x * w (x (Fin.last (n + m)))
        else 0) = forward ν p b y n i * backwardW p b y m n w i := by
  induction m with
  | zero =>
    intro w
    show (∑ x : Fin (n + 1) → S,
      (if x (Fin.last n) = i then pathChance ν p b y n x * w (x (Fin.last n)) else 0)) = _
    rw [forward_eq_sum, Finset.sum_mul]
    refine Finset.sum_congr rfl fun x _ => ?_
    split_ifs with h
    · simp [backwardW, h]
    · simp
  | succ m ih =>
    intro w
    show (∑ x : Fin (n + m + 1 + 1) → S,
      (if x ⟨n, by omega⟩ = i then
        pathChance ν p b y (n + m + 1) x * w (x (Fin.last (n + m + 1))) else 0)) = _
    rw [← (Fin.snocEquiv (fun _ => S)).sum_comp, Fintype.sum_prod_type, Finset.sum_comm,
      backwardW_succ, ← ih]
    refine Finset.sum_congr rfl fun x _ => ?_
    have hn : (⟨n, by omega⟩ : Fin (n + m + 1 + 1)) = Fin.castSucc ⟨n, by omega⟩ := rfl
    simp only [Fin.snocEquiv_apply, hn, Fin.snoc_castSucc, Fin.snoc_last, pathChance_snoc]
    split_ifs with h
    · rw [Finset.mul_sum]
      refine Finset.sum_congr rfl fun z _ => ?_
      ring
    · simp

#print axioms backwardW_one
#print axioms backwardW_succ
#print axioms sum_paths_through_weighted


theorem real_inter_of_cond {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (s t : Set Ω) (ht : MeasurableSet t) (c : ℝ)
    (hc : μ t ≠ 0 → (μ[s | t]).toReal = c) : μ.real (t ∩ s) = μ.real t * c := by
  by_cases h0 : μ t = 0
  · have h1 : μ (t ∩ s) = 0 := measure_mono_null Set.inter_subset_left h0
    simp [measureReal_def, h0, h1]
  · rw [← hc h0, cond_apply ht, ENNReal.toReal_mul, ENNReal.toReal_inv, ← measureReal_def,
      ← measureReal_def, ← mul_assoc, mul_inv_cancel₀, one_mul]
    rw [measureReal_def]
    exact ENNReal.toReal_ne_zero.mpr ⟨h0, measure_ne_top μ t⟩

theorem measurableSet_event {Ω : Type*} [MeasurableSpace Ω]
    [MeasurableSpace S] [MeasurableSingletonClass S] [MeasurableSpace O] [MeasurableSingletonClass O]
    (X : ℕ → Ω → S) (Y : ℕ → Ω → O) (hX : ∀ n, Measurable (X n)) (hY : ∀ n, Measurable (Y n))
    (a c : ℕ) (h : Fin a → S) (g : Fin c → O) :
    MeasurableSet {ω | (∀ m : Fin a, X m ω = h m) ∧ ∀ m : Fin c, Y m ω = g m} := by
  have : {ω | (∀ m : Fin a, X m ω = h m) ∧ ∀ m : Fin c, Y m ω = g m} =
      (⋂ m : Fin a, X m ⁻¹' {h m}) ∩ ⋂ m : Fin c, Y m ⁻¹' {g m} := by
    ext ω; simp
  rw [this]
  exact (MeasurableSet.iInter fun m : Fin a => hX (m : ℕ) (measurableSet_singleton (h m))).inter
    (MeasurableSet.iInter fun m : Fin c => hY (m : ℕ) (measurableSet_singleton (g m)))

#print axioms real_inter_of_cond
#print axioms measurableSet_event

theorem joint_chance {Ω : Type*} [MeasurableSpace Ω]
    [Fintype S] [MeasurableSpace S] [MeasurableSingletonClass S]
    [Fintype O] [MeasurableSpace O] [MeasurableSingletonClass O]
    (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → S) (Y : ℕ → Ω → O) (hX : ∀ n, Measurable (X n)) (hY : ∀ n, Measurable (Y n))
    (ν : S → ℝ) (p : S → S → ℝ) (b : S → O → ℝ)
    (hstart : ∀ i, μ.real {ω | X 0 ω = i} = ν i)
    (hmarkov : ∀ (n : ℕ) (h : Fin (n + 1) → S) (g : Fin (n + 1) → O) (j : S),
      μ {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin (n + 1), Y m ω = g m} ≠ 0 →
        (μ[{ω | X (n + 1) ω = j} |
            {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin (n + 1), Y m ω = g m}]).toReal =
          p (h (Fin.last n)) j)
    (hemit : ∀ (n : ℕ) (h : Fin (n + 1) → S) (g : Fin n → O) (o : O),
      μ {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin n, Y m ω = g m} ≠ 0 →
        (μ[{ω | Y n ω = o} |
            {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin n, Y m ω = g m}]).toReal =
          b (h (Fin.last n)) o)
    (y : ℕ → O) (n : ℕ) (x : Fin (n + 1) → S) :
    μ.real {ω | (∀ m : Fin (n + 1), X m ω = x m) ∧ ∀ m : Fin (n + 1), Y m ω = y m} =
      pathChance ν p b y n x := by
  -- emission step: the chance with today's signal is the chance without it times `b`
  have emit : ∀ (k : ℕ) (z : Fin (k + 1) → S),
      μ.real {ω | (∀ m : Fin (k + 1), X m ω = z m) ∧ ∀ m : Fin (k + 1), Y m ω = y m} =
        μ.real {ω | (∀ m : Fin (k + 1), X m ω = z m) ∧ ∀ m : Fin k, Y m ω = y m} *
          b (z (Fin.last k)) (y k) := by
    intro k z
    have hset : {ω | (∀ m : Fin (k + 1), X m ω = z m) ∧ ∀ m : Fin (k + 1), Y m ω = y m} =
        {ω | (∀ m : Fin (k + 1), X m ω = z m) ∧ ∀ m : Fin k, Y m ω = y m} ∩
          {ω | Y k ω = y k} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_inter_iff]
      rw [Fin.forall_fin_succ' (P := fun m : Fin (k + 1) => Y m ω = y m)]
      simp only [Fin.val_castSucc, Fin.val_last]
      tauto
    rw [hset]
    exact real_inter_of_cond μ _ _ (measurableSet_event X Y hX hY _ _ _ _) _
      (hemit k z (fun m => y m) (y k))
  induction n with
  | zero =>
    rw [emit]
    have hset : {ω | (∀ m : Fin (0 + 1), X m ω = x m) ∧ ∀ m : Fin 0, Y m ω = y m} =
        {ω | X 0 ω = x 0} := by
      ext ω
      simp
    rw [hset, hstart]
    simp [pathChance]
  | succ n ih =>
    rw [emit]
    have hset : {ω | (∀ m : Fin (n + 1 + 1), X m ω = x m) ∧ ∀ m : Fin (n + 1), Y m ω = y m} =
        {ω | (∀ m : Fin (n + 1), X m ω = Fin.init x m) ∧ ∀ m : Fin (n + 1), Y m ω = y m} ∩
          {ω | X (n + 1) ω = x (Fin.last (n + 1))} := by
      ext ω
      simp only [Set.mem_ofPred_eq, Set.mem_inter_iff]
      rw [Fin.forall_fin_succ' (P := fun m : Fin (n + 2) => X m ω = x m)]
      simp only [Fin.val_castSucc, Fin.val_last, Fin.init]
      tauto
    rw [hset, real_inter_of_cond μ _ _ (measurableSet_event X Y hX hY _ _ _ _) _
      (hmarkov n (Fin.init x) (fun m => y m) (x (Fin.last (n + 1)))), ih, pathChance_succ]
    simp only [Fin.init]
    ring

#print axioms joint_chance

/-- **The forward algorithm is exact.** A hidden chain `X 0, X 1, …` on finitely many weathers
`S` is seen only through signals `Y 0, Y 1, …` with finitely many values `O`. Assume
(start law) day 0 is weather `i` with chance `ν i`;
(Markov) given the whole past of weather and signals, tomorrow is `j` with chance `p i j`
when today is `i`;
(emission) given all weather to date and all earlier signals, today's signal is `o` with
chance `b i o` when today is `i`;
with the same numbers `ν`, `p`, `b` every day. Then for every number of days and every
signal record `y`, the chance of seeing `y 0, …, y n` is the total `∑_i α_n(i)` of the forward
recursion, and that total equals the brute-force sum of the product over all hidden paths. -/
theorem forward_eq_chance_of_signals {Ω : Type*} [MeasurableSpace Ω]
    [Fintype S] [MeasurableSpace S] [MeasurableSingletonClass S]
    [Fintype O] [MeasurableSpace O] [MeasurableSingletonClass O]
    (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → S) (Y : ℕ → Ω → O) (hX : ∀ n, Measurable (X n)) (hY : ∀ n, Measurable (Y n))
    (ν : S → ℝ) (p : S → S → ℝ) (b : S → O → ℝ)
    (hstart : ∀ i, μ.real {ω | X 0 ω = i} = ν i)
    (hmarkov : ∀ (n : ℕ) (h : Fin (n + 1) → S) (g : Fin (n + 1) → O) (j : S),
      μ {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin (n + 1), Y m ω = g m} ≠ 0 →
        (μ[{ω | X (n + 1) ω = j} |
            {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin (n + 1), Y m ω = g m}]).toReal =
          p (h (Fin.last n)) j)
    (hemit : ∀ (n : ℕ) (h : Fin (n + 1) → S) (g : Fin n → O) (o : O),
      μ {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin n, Y m ω = g m} ≠ 0 →
        (μ[{ω | Y n ω = o} |
            {ω | (∀ m : Fin (n + 1), X m ω = h m) ∧ ∀ m : Fin n, Y m ω = g m}]).toReal =
          b (h (Fin.last n)) o)
    (n : ℕ) (y : ℕ → O) :
    μ.real {ω | ∀ m : Fin (n + 1), Y m ω = y m} = ∑ i, forward ν p b y n i ∧
      ∑ i, forward ν p b y n i = ∑ x : Fin (n + 1) → S, pathChance ν p b y n x := by
  classical
  have h2 : ∑ i, forward ν p b y n i = ∑ x : Fin (n + 1) → S, pathChance ν p b y n x := by
    simp only [forward_eq_sum]
    rw [Finset.sum_comm]
    simp
  refine ⟨?_, h2⟩
  have hset : {ω | ∀ m : Fin (n + 1), Y m ω = y m} =
      ⋃ x ∈ (Finset.univ : Finset (Fin (n + 1) → S)),
        {ω | (∀ m : Fin (n + 1), X m ω = x m) ∧ ∀ m : Fin (n + 1), Y m ω = y m} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Finset.mem_univ, Set.iUnion_true, Set.mem_iUnion]
    exact ⟨fun h => ⟨fun m => X m ω, fun _ => rfl, h⟩, fun ⟨_, _, h⟩ => h⟩
  rw [h2, hset, measureReal_biUnion_finset]
  · exact Finset.sum_congr rfl fun x _ =>
      joint_chance μ X Y hX hY ν p b hstart hmarkov hemit y n x
  · intro x _ x' _ hxx'
    refine Set.disjoint_left.2 fun ω h1 h2 => hxx' (funext fun m => ?_)
    exact (h1.1 m).symm.trans (h2.1 m)
  · intro x _
    exact measurableSet_event X Y hX hY _ _ _ _

/-- **Viterbi decoding is exact.** For transition and signal chances `p`, `b` with no negative
values (the start law `ν` may be anything), the
Viterbi value `δ_n(i)` is the largest product over all hidden paths ending in weather `i` on
day `n`, attained by some such path; and the largest `δ_n(i)` over `i` is the largest product
over all hidden paths, the chance of the best single week together with the signals. -/
theorem viterbi_eq_best_path_chance [Fintype S] [Nonempty S]
    (ν : S → ℝ) (p : S → S → ℝ) (b : S → O → ℝ)
    (hp : ∀ i j, 0 ≤ p i j) (hb : ∀ i o, 0 ≤ b i o)
    (y : ℕ → O) (n : ℕ) :
    (∀ i, IsGreatest (pathChance ν p b y n '' {x | x (Fin.last n) = i}) (viterbi ν p b y n i)) ∧
      IsGreatest (Set.range (pathChance ν p b y n))
        (Finset.univ.sup' Finset.univ_nonempty (viterbi ν p b y n)) := by
  refine ⟨viterbi_isGreatest ν p b hp hb y n, ?_, ?_⟩
  · obtain ⟨j, -, hj⟩ := Finset.exists_mem_eq_sup' (Finset.univ_nonempty (α := S))
      (viterbi ν p b y n)
    obtain ⟨x, -, hx⟩ := (viterbi_isGreatest ν p b hp hb y n j).1
    exact ⟨x, hx.trans hj.symm⟩
  · rintro _ ⟨x, rfl⟩
    exact le_trans ((viterbi_isGreatest ν p b hp hb y n (x (Fin.last n))).2 ⟨x, rfl, rfl⟩)
      (Finset.le_sup' _ (Finset.mem_univ _))

/-- **Forward times backward is the sum over paths through a given day.** For any record of
`n + m + 1` days, `α_n(i) β_n(i)` (forward to day `n`, backward over the `m` days after it) is
the sum of the products of all hidden paths that have weather `i` on day `n`: the past half
times the future half. Divided by the forward total, it is the smoothed chance of `i` on day `n`. -/
theorem forward_mul_backward_eq_sum_paths_through [Fintype S] [DecidableEq S]
    (ν : S → ℝ) (p : S → S → ℝ) (b : S → O → ℝ) (y : ℕ → O) (n m : ℕ) (i : S) :
    forward ν p b y n i * backward p b y m n i =
      ∑ x ∈ Finset.univ.filter (fun x : Fin (n + m + 1) → S => x ⟨n, by omega⟩ = i),
        pathChance ν p b y (n + m) x := by
  rw [← backwardW_one, ← sum_paths_through_weighted, Finset.sum_filter]
  simp

/-! The card's worked numbers, exactly, in whole tenths (weathers 0 sunny, 1 cloudy, 2 rainy;
signal 1 umbrella, 0 none). The forward and Viterbi values on day `n` (from 0) are in units
of `10^-(2n+2)`, so Friday's (day 4) are in units of `10^-10`. -/

/-- The weather chain in tenths: sunny never turns straight to rain. -/
def pT : Fin 3 → Fin 3 → ℕ := ![![7, 3, 0], ![3, 3, 4], ![2, 2, 6]]
/-- Monday's weather, in tenths. -/
def νT : Fin 3 → ℕ := ![5, 3, 2]
/-- Umbrella chance in tenths: 1, 4, 8; no umbrella is the rest of 10. -/
def bT (i : Fin 3) (o : Fin 2) : ℕ := if o = 1 then ![1, 4, 8] i else 10 - ![1, 4, 8] i
/-- The umbrella week: umbrella, umbrella, none, none, umbrella. -/
def week (n : ℕ) : Fin 2 := if h : n < 5 then ![1, 1, 0, 0, 1] ⟨n, h⟩ else 0

-- Monday forward: 0.05, 0.12, 0.16; Tuesday rainy 0.1152.
example : forward νT pT bT week 0 = ![5, 12, 16] := by decide
example : forward νT pT bT week 1 2 = 1152 := by decide

-- Friday forward 0.0026587221, 0.0055769604, 0.0057453504; their sum L = 0.0139810329.
example : forward νT pT bT week 4 = ![26587221, 55769604, 57453504] := by decide
example : ∑ i, forward νT pT bT week 4 i = 139810329 := by decide

-- Monday filtered chance of rain: 0.16 / 0.33 = 16/33, about 0.4848.
example : 48475 * 33 ≤ 16 * 100000 ∧ 16 * 100000 < 48485 * 33 := by decide

-- Tuesday Viterbi, rain: max(0, 0.048, 0.096) × 0.8 = 0.0768.
example : viterbi νT pT bT week 1 2 = 768 := by decide

-- Friday Viterbi 0.0006096384, 0.0010450944, 0.0007962624; the largest is cloudy.
example : viterbi νT pT bT week 4 = ![6096384, 10450944, 7962624] := by decide

-- The best week R R S S C has product 0.0010450944; the day-by-day week R R S S R has chance 0.
example : pathChance νT pT bT week 4 ![2, 2, 0, 0, 1] = 10450944 := by decide
example : pathChance νT pT bT week 4 ![2, 2, 0, 0, 2] = 0 := by decide

-- Given the umbrellas, the best week has chance 0.0010450944 / 0.0139810329, about 0.0748.
example : 7475 * 139810329 ≤ 10450944 * 100000 ∧ 10450944 * 100000 < 7485 * 139810329 := by
  decide

-- Friday smoothed rain: forward × backward / L = 0.0057453504 / 0.0139810329, about 0.4109.
example : forward νT pT bT week 4 2 * backward pT bT week 0 4 2 = 57453504 := by decide
example : 41085 * 139810329 ≤ 57453504 * 100000 ∧ 57453504 * 100000 < 41095 * 139810329 := by
  decide

-- Brute force over all 3^5 = 243 weather weeks: the products add to L, and 144 are possible.
example : Fintype.card (Fin 5 → Fin 3) = 243 := by simp
example : ∑ x : Fin 5 → Fin 3, pathChance νT pT bT week 4 x = 139810329 := by
  decide +kernel
example : (Finset.univ.filter fun x : Fin 5 → Fin 3 => pathChance νT pT bT week 4 x ≠ 0).card =
    144 := by decide +kernel

#print axioms forward_eq_chance_of_signals
#print axioms viterbi_eq_best_path_chance
#print axioms forward_mul_backward_eq_sum_paths_through

end HMM
