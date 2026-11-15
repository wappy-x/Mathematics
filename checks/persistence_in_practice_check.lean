-- Persistence in practice: the shuffle p-value never overstates the evidence, the Bonferroni correction keeps the total false-alarm chance within alpha, and moving each return by at most delta moves an m-day window by at most sqrt(m) times delta.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.GroupTheory.Perm.Fin
import Mathlib.Tactic

open MeasureTheory

/-- The sliding-window embedding: the window starting on day `t` lists the `m` returns
`x t, x (t + h), ..., x (t + (m - 1) h)`, as a point of `m`-dimensional space with the
ordinary straight-line distance. -/
noncomputable def slidingWindow (m h : ℕ) (x : ℕ → ℝ) (t : ℕ) : EuclideanSpace ℝ (Fin m) :=
  WithLp.toLp 2 (fun i : Fin m => x (t + (i : ℕ) * h))

/-- Among any real scores, at most `K` of them have at most `K` scores at or above them. -/
theorem card_low_rank_le {ι : Type*} [Fintype ι] [DecidableEq ι] (L : ι → ℝ) (K : ℝ) (hK : 0 ≤ K) :
    ((Finset.univ.filter fun i =>
        ((Finset.univ.filter fun j => L i ≤ L j).card : ℝ) ≤ K).card : ℝ) ≤ K := by
  set S := Finset.univ.filter fun i => ((Finset.univ.filter fun j => L i ≤ L j).card : ℝ) ≤ K
  rcases S.eq_empty_or_nonempty with hS | hS
  · simp [hS, hK]
  obtain ⟨i, hi, hmin⟩ := S.exists_min_image L hS
  have hsub : S ⊆ Finset.univ.filter fun j => L i ≤ L j := by
    intro s hs; simp [hmin s hs]
  have hi' := (Finset.mem_filter.1 hi).2
  exact le_trans (by exact_mod_cast Finset.card_le_card hsub) hi'

#print axioms card_low_rank_le

/-- The shuffle p-value never overstates the evidence. Fix the returns `d` of a stretch of
`n` days and any statistic `T` of a series (such as the longest loop bar). Under the null
hypothesis every ordering of the days is equally likely: the real series is `d` read in a
uniformly random order `τ 0`, and the `N` shuffled copies are `d` read in further uniformly
random orders `τ 1, ..., τ N`. With `p = (1 + #{j ≥ 1 : L_j ≥ L}) / (N + 1)`, which is
`#{j : L_j ≥ L} / (N + 1)` counting the real one, the chance that `p ≤ α` is at most `α`. -/
theorem shuffle_p_value_le_alpha (n N : ℕ) (d : Fin n → ℝ) (T : (Fin n → ℝ) → ℝ) (α : ℝ)
    (hα : 0 ≤ α) :
    ((Finset.univ.filter fun τ : Fin (N + 1) → Equiv.Perm (Fin n) =>
        ((Finset.univ.filter fun j : Fin (N + 1) =>
            T (d ∘ τ 0) ≤ T (d ∘ τ j)).card : ℝ) / (N + 1) ≤ α).card : ℝ)
      / (Fintype.card (Fin (N + 1) → Equiv.Perm (Fin n)) : ℝ) ≤ α := by
  classical
  set Ω := Fin (N + 1) → Equiv.Perm (Fin n)
  have hM : (0 : ℝ) < N + 1 := by positivity
  -- event that index i looks extreme
  let A : Fin (N + 1) → Finset Ω := fun i => Finset.univ.filter fun τ =>
    ((Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ i) ≤ T (d ∘ τ j)).card : ℝ) / (N + 1) ≤ α
  -- each index is equally likely to look extreme
  have hswap : ∀ i, (A 0).card = (A i).card := by
    intro i
    let σ := Equiv.swap (0 : Fin (N + 1)) i
    refine Finset.card_bij' (fun τ _ => fun j => τ (σ j)) (fun τ _ => fun j => τ (σ j)) ?_ ?_ ?_ ?_
    · intro τ hτ
      simp only [A, Finset.mem_filter, Finset.mem_univ, true_and] at hτ ⊢
      have : (Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ (σ i)) ≤ T (d ∘ τ (σ j))).card
          = (Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ 0) ≤ T (d ∘ τ j)).card := by
        have hσi : σ i = 0 := Equiv.swap_apply_right _ _
        rw [hσi]
        exact Finset.card_bij' (fun j _ => σ j) (fun j _ => σ j)
          (by intro a ha; simpa [σ, Equiv.swap_apply_self] using ha)
          (by intro a ha; simpa [σ, Equiv.swap_apply_self] using ha)
          (by intro a _; simp [σ, Equiv.swap_apply_self])
          (by intro a _; simp [σ, Equiv.swap_apply_self])
      rw [this]; exact hτ
    · intro τ hτ
      simp only [A, Finset.mem_filter, Finset.mem_univ, true_and] at hτ ⊢
      have : (Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ (σ 0)) ≤ T (d ∘ τ (σ j))).card
          = (Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ i) ≤ T (d ∘ τ j)).card := by
        have hσ0 : σ 0 = i := Equiv.swap_apply_left _ _
        rw [hσ0]
        exact Finset.card_bij' (fun j _ => σ j) (fun j _ => σ j)
          (by intro a ha; simpa [σ, Equiv.swap_apply_self] using ha)
          (by intro a ha; simpa [σ, Equiv.swap_apply_self] using ha)
          (by intro a _; simp [σ, Equiv.swap_apply_self])
          (by intro a _; simp [σ, Equiv.swap_apply_self])
      rw [this]; exact hτ
    · intro τ _; funext j; simp [σ]
    · intro τ _; funext j; simp [σ]
  -- double counting
  have hdouble : ∑ i, ((A i).card : ℝ) = ∑ τ : Ω, ((Finset.univ.filter fun i =>
      ((Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ i) ≤ T (d ∘ τ j)).card : ℝ)
        ≤ α * (N + 1)).card : ℝ) := by
    simp only [A, Finset.card_filter, Nat.cast_sum]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun τ _ => Finset.sum_congr rfl fun i _ => ?_
    split_ifs with h1 h2 h2
    · rfl
    · exact absurd ((div_le_iff₀ hM).1 h1) h2
    · exact absurd ((div_le_iff₀ hM).2 h2) h1
    · rfl
  have hbound : ∀ τ : Ω, ((Finset.univ.filter fun i =>
      ((Finset.univ.filter fun j : Fin (N + 1) => T (d ∘ τ i) ≤ T (d ∘ τ j)).card : ℝ)
        ≤ α * (N + 1)).card : ℝ) ≤ α * (N + 1) := fun τ =>
    card_low_rank_le (fun j => T (d ∘ τ j)) _ (by positivity)
  have hsum : ((N : ℝ) + 1) * (A 0).card ≤ (Fintype.card Ω : ℝ) * (α * (N + 1)) := by
    have h1 : ∑ _i : Fin (N + 1), ((A 0).card : ℝ) = ((N : ℝ) + 1) * (A 0).card := by
      simp
    rw [← h1]
    calc ∑ _i : Fin (N + 1), ((A 0).card : ℝ) = ∑ i, ((A i).card : ℝ) := 
          Finset.sum_congr rfl fun i _ => by rw [hswap i]
      _ = _ := hdouble
      _ ≤ ∑ _τ : Ω, α * (N + 1) := Finset.sum_le_sum fun τ _ => hbound τ
      _ = _ := by simp
  have hΩ : (0 : ℝ) < Fintype.card Ω := by exact_mod_cast Fintype.card_pos
  rw [div_le_iff₀ hΩ]
  nlinarith

/-- The Bonferroni correction: run `k` tests, each with false-alarm chance at most `α / k`.
Whether or not the tests are independent, the chance that at least one fires falsely is at
most `α` (the union bound). -/
theorem bonferroni_union_bound {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (k : ℕ) (α : ℝ) (E : Fin k → Set Ω)
    (hE : ∀ i, P (E i) ≤ ENNReal.ofReal (α / k)) :
    P (⋃ i, E i) ≤ ENNReal.ofReal α := by
  have hsum : P (⋃ i, E i) ≤ ∑ i, P (E i) := measure_iUnion_fintype_le P E
  refine hsum.trans ?_
  refine (Finset.sum_le_sum fun i _ => hE i).trans ?_
  rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  rcases Nat.eq_zero_or_pos k with rfl | hk
  · simp
  · have hk' : (0 : ℝ) < k := by exact_mod_cast hk
    rw [show ((k : ℕ) : ENNReal) = ENNReal.ofReal (k : ℝ) by simp,
      ← ENNReal.ofReal_mul hk'.le, mul_div_cancel₀ _ hk'.ne']

/-- Noise moves a window only a little: if every return changes by at most `δ`, then every
`m`-day window moves by at most `√m · δ` in straight-line distance (for three-day windows and
`δ = 0.1` percent, at most `√3 × 0.1` percent). -/
theorem slidingWindow_dist_le (m h : ℕ) (x y : ℕ → ℝ) (δ : ℝ)
    (hxy : ∀ t, |x t - y t| ≤ δ) (t : ℕ) :
    dist (slidingWindow m h x t) (slidingWindow m h y t) ≤ √(m : ℝ) * δ := by
  have hδ : 0 ≤ δ := (abs_nonneg _).trans (hxy 0)
  rw [EuclideanSpace.dist_eq]
  have hle : ∑ i : Fin m, dist ((slidingWindow m h x t) i) ((slidingWindow m h y t) i) ^ 2
      ≤ ∑ _i : Fin m, δ ^ 2 := by
    refine Finset.sum_le_sum fun i _ => ?_
    simp only [slidingWindow, Real.dist_eq]
    exact pow_le_pow_left₀ (abs_nonneg _) (hxy _) 2
  calc √(∑ i : Fin m, dist ((slidingWindow m h x t) i) ((slidingWindow m h y t) i) ^ 2)
      ≤ √(∑ _i : Fin m, δ ^ 2) := Real.sqrt_le_sqrt hle
    _ = √(m : ℝ) * δ := by
      rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
        Real.sqrt_mul (Nat.cast_nonneg _), Real.sqrt_sq hδ]

/-- The card's pure six-day cycle of returns, in percent: 2, 1, -1, -2, -1, 1, repeating. -/
def hexCycle (t : ℕ) : ℤ := [2, 1, -1, -2, -1, 1].getD (t % 6) 0

/-- Squared distance between the three-day windows (delay 1) starting on days `s` and `t`. -/
def hexD2 (s t : ℕ) : ℤ := ∑ i : Fin 3, (hexCycle (s + i) - hexCycle (t + i)) ^ 2

-- The six windows: (2,1,-1) (1,-1,-2) (-1,-2,-1) (-2,-1,1) (-1,1,2) (1,2,1).
example : (List.range 6).map (fun t => (hexCycle t, hexCycle (t + 1), hexCycle (t + 2))) =
    [(2, 1, -1), (1, -1, -2), (-1, -2, -1), (-2, -1, 1), (-1, 1, 2), (1, 2, 1)] := by decide
-- Neighbours have squared distance 6, windows two days apart 18, opposite windows 24.
example : ∀ t : Fin 6, hexD2 t (t + 1) = 6 := by decide
example : ∀ t : Fin 6, hexD2 t (t + 2) = 18 := by decide
example : ∀ t : Fin 6, hexD2 t (t + 3) = 24 := by decide
-- Every window lies on one plane: the third entry is the second minus the first.
example : ∀ t : Fin 6, hexCycle (t + 2) = hexCycle (t + 1) - hexCycle t := by decide
-- The series repeats every six days, so the window at day t + 6 equals the window at day t.
example : ∀ t : Fin 6, ∀ i : Fin 3, hexCycle (t + 6 + i) = hexCycle (t + i) := by decide
-- 42 days give 40 three-day windows.
example : 42 - 3 + 1 = 40 := by norm_num
-- With 99 shuffles the smallest possible p is 1/100.
example : (1 + 0 : ℚ) / (99 + 1) = 1 / 100 := by norm_num

#print axioms shuffle_p_value_le_alpha
#print axioms bonferroni_union_bound
#print axioms slidingWindow_dist_le
