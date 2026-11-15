-- Semigroups: every strongly continuous semigroup of bounded operators on a complete normed space grows at most exponentially and moves each state continuously in time, a bounded generator makes e^(tA) return to I in norm, and the help desk's two-state numbers check exactly.
import Mathlib.Analysis.Normed.Operator.BanachSteinhaus
import Mathlib.Analysis.Normed.Algebra.Exponential
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Filter Topology

/-- Helper: a strongly continuous semigroup is uniformly bounded on some interval `[0, δ]`. -/
theorem scs_local_bound
    {𝕜 : Type*} [NontriviallyNormedField 𝕜]
    {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X] [CompleteSpace X]
    (T : ℝ → X →L[𝕜] X)
    (h_zero : T 0 = 1)
    (h_strong : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[>] 0) (𝓝 x)) :
    ∃ δ : ℝ, 0 < δ ∧ ∃ C : ℝ, 1 ≤ C ∧ ∀ t : ℝ, 0 ≤ t → t ≤ δ → ‖T t‖ ≤ C := by
  by_contra h
  push Not at h
  have hex : ∀ n : ℕ, ∃ t : ℝ, 0 ≤ t ∧ t ≤ 1 / ((n : ℝ) + 1) ∧ (n : ℝ) + 1 < ‖T t‖ := by
    intro n
    exact h _ (by positivity) _ (by linarith [(Nat.cast_nonneg n : (0 : ℝ) ≤ n)])
  choose t ht0 ht1 ht2 using hex
  have hpos : ∀ n, 0 < t n := by
    intro n
    rcases (ht0 n).eq_or_lt with h' | h'
    · exfalso
      have := ht2 n
      rw [← h', h_zero] at this
      have h1 : ‖(1 : X →L[𝕜] X)‖ ≤ 1 := ContinuousLinearMap.norm_id_le
      linarith [(Nat.cast_nonneg n : (0 : ℝ) ≤ n)]
    · exact h'
  have hlim : Tendsto t atTop (𝓝[>] 0) := by
    refine tendsto_nhdsWithin_iff.2 ⟨?_, Eventually.of_forall hpos⟩
    exact squeeze_zero ht0 ht1 tendsto_one_div_add_atTop_nhds_zero_nat
  have hpt : ∀ x : X, ∃ C, ∀ n, ‖T (t n) x‖ ≤ C := by
    intro x
    obtain ⟨C, hC⟩ := isBounded_iff_forall_norm_le.1
      (Metric.isBounded_range_of_tendsto _ ((h_strong x).comp hlim))
    exact ⟨C, fun n => hC _ ⟨n, rfl⟩⟩
  obtain ⟨C', hC'⟩ := banach_steinhaus (g := fun n => T (t n)) hpt
  obtain ⟨n, hn⟩ := exists_nat_gt C'
  have := hC' n
  have := ht2 n
  linarith

#print axioms scs_local_bound

/-- The growth bound. Let `X` be a complete normed space and `T(t)`, one for each wait `t ≥ 0`,
a family of bounded linear operators on it that is a semigroup (`T(0) = I` and
`T(s + t) = T(s) T(t)` for all `s, t ≥ 0`) and strongly continuous (for every state `x`,
`T(t) x → x` as `t` shrinks to 0). Then there are constants `M ≥ 1` and `ω` with
`‖T(t)‖ ≤ M e^(ω t)` for every `t ≥ 0`. -/
theorem strongly_continuous_semigroup_growth_bound
    {𝕜 : Type*} [NontriviallyNormedField 𝕜]
    {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X] [CompleteSpace X]
    (T : ℝ → X →L[𝕜] X)
    (h_zero : T 0 = 1)
    (h_law : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (h_strong : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[>] 0) (𝓝 x)) :
    ∃ M : ℝ, 1 ≤ M ∧ ∃ ω : ℝ, ∀ t : ℝ, 0 ≤ t → ‖T t‖ ≤ M * Real.exp (ω * t) := by
  obtain ⟨δ, hδ, C, hC1, hC⟩ := scs_local_bound T h_zero h_strong
  have key : ∀ n : ℕ, ∀ t : ℝ, 0 ≤ t → t ≤ ((n : ℝ) + 1) * δ → ‖T t‖ ≤ C ^ (n + 1) := by
    intro n
    induction n with
    | zero =>
      intro t h0 h1
      simpa using hC t h0 (by simpa using h1)
    | succ n ih =>
      intro t h0 h1
      push_cast at h1
      by_cases ht : t ≤ δ
      · calc ‖T t‖ ≤ C := hC t h0 ht
          _ ≤ C ^ (n + 1 + 1) := le_self_pow₀ hC1 (by omega)
      · push Not at ht
        have e : T t = T δ * T (t - δ) := by
          rw [← h_law δ (t - δ) hδ.le (by linarith)]
          congr 1
          ring
        rw [e]
        calc ‖T δ * T (t - δ)‖ ≤ ‖T δ‖ * ‖T (t - δ)‖ := norm_mul_le _ _
          _ ≤ C * C ^ (n + 1) :=
            mul_le_mul (hC δ hδ.le le_rfl) (ih (t - δ) (by linarith) (by linarith))
              (norm_nonneg _) (by linarith)
          _ = C ^ (n + 1 + 1) := by ring
  refine ⟨C, hC1, Real.log C / δ, fun t ht => ?_⟩
  set n := ⌊t / δ⌋₊ with hn
  have hn1 : t ≤ ((n : ℝ) + 1) * δ := by
    have := Nat.lt_floor_add_one (t / δ)
    rw [div_lt_iff₀ hδ] at this
    exact this.le
  have hn2 : (n : ℝ) ≤ t / δ := Nat.floor_le (div_nonneg ht hδ.le)
  calc ‖T t‖ ≤ C ^ (n + 1) := key n t ht hn1
    _ = C * C ^ ((n : ℕ) : ℝ) := by rw [Real.rpow_natCast]; ring
    _ ≤ C * C ^ (t / δ) := by
        gcongr
    _ = C * Real.exp (Real.log C / δ * t) := by
        rw [Real.rpow_def_of_pos (by linarith)]
        congr 2
        ring

/-- From time zero to every time. For a strongly continuous semigroup `T(t)` of bounded linear
operators on a complete normed space, each single state moves continuously at every time:
for every `x`, the path `t ↦ T(t) x` is continuous on `t ≥ 0`. -/
theorem strongly_continuous_semigroup_orbit_continuous
    {𝕜 : Type*} [NontriviallyNormedField 𝕜]
    {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X] [CompleteSpace X]
    (T : ℝ → X →L[𝕜] X)
    (h_zero : T 0 = 1)
    (h_law : ∀ s t : ℝ, 0 ≤ s → 0 ≤ t → T (s + t) = T s * T t)
    (h_strong : ∀ x : X, Tendsto (fun t : ℝ => T t x) (𝓝[>] 0) (𝓝 x)) (x : X) :
    ContinuousOn (fun t : ℝ => T t x) (Set.Ici 0) := by
  obtain ⟨M, hM, ω, hb⟩ := strongly_continuous_semigroup_growth_bound T h_zero h_law h_strong
  intro t0 ht0
  have ht0' : (0 : ℝ) ≤ t0 := ht0
  have hset : Set.Ici (0 : ℝ) = Set.Ico 0 t0 ∪ Set.Ici t0 := by
    ext s
    simp only [Set.mem_Ici, Set.mem_Ico, Set.mem_union]
    constructor
    · intro h
      by_cases hs : s < t0
      · exact Or.inl ⟨h, hs⟩
      · exact Or.inr (not_lt.1 hs)
    · rintro (h | h)
      · exact h.1
      · linarith
  rw [hset]
  apply ContinuousWithinAt.union
  · rcases ht0'.eq_or_lt with h | h
    · subst h
      rw [Set.Ico_self, ContinuousWithinAt, nhdsWithin_empty]
      exact tendsto_bot
    · set K := M * Real.exp (|ω| * t0) with hK
      have hT : ∀ t ∈ Set.Ico 0 t0, ‖T t x - T t0 x‖ ≤ K * ‖x - T (t0 - t) x‖ := by
        intro t ht
        have e : T t0 x = T t (T (t0 - t) x) := by
          have : T t0 = T t * T (t0 - t) := by
            rw [← h_law t (t0 - t) ht.1 (by linarith [ht.2])]
            congr 1
            ring
          rw [this]
          rfl
        rw [e, ← map_sub]
        calc ‖T t (x - T (t0 - t) x)‖ ≤ ‖T t‖ * ‖x - T (t0 - t) x‖ := (T t).le_opNorm _
          _ ≤ K * ‖x - T (t0 - t) x‖ := by
            gcongr
            calc ‖T t‖ ≤ M * Real.exp (ω * t) := hb t ht.1
              _ ≤ K := by
                rw [hK]
                have h0 : 0 ≤ t := ht.1
                have h1 : t < t0 := ht.2
                exact mul_le_mul_of_nonneg_left (Real.exp_le_exp.2
                  (by nlinarith [le_abs_self ω, abs_nonneg ω])) (by linarith)
      have hlim : Tendsto (fun t => t0 - t) (𝓝[Set.Ico 0 t0] t0) (𝓝[>] 0) := by
        refine tendsto_nhdsWithin_iff.2 ⟨?_, eventually_nhdsWithin_of_forall
          fun t ht => sub_pos.2 ht.2⟩
        have : Tendsto (fun t : ℝ => t0 - t) (𝓝 t0) (𝓝 (t0 - t0)) :=
          tendsto_const_nhds.sub tendsto_id
        rw [sub_self] at this
        exact this.mono_left nhdsWithin_le_nhds
      have h2 : Tendsto (fun t => K * ‖x - T (t0 - t) x‖) (𝓝[Set.Ico 0 t0] t0) (𝓝 0) := by
        have h3 : Tendsto (fun t => x - T (t0 - t) x) (𝓝[Set.Ico 0 t0] t0) (𝓝 (x - x)) :=
          tendsto_const_nhds.sub ((h_strong x).comp hlim)
        rw [sub_self] at h3
        simpa using (h3.norm).const_mul K
      rw [ContinuousWithinAt, tendsto_iff_norm_sub_tendsto_zero]
      exact squeeze_zero' (Eventually.of_forall fun _ => norm_nonneg _)
        (eventually_nhdsWithin_of_forall hT) h2
  · rw [← continuousWithinAt_Ioi_iff_Ici]
    have hlim : Tendsto (fun t => t - t0) (𝓝[>] t0) (𝓝[>] 0) := by
      refine tendsto_nhdsWithin_iff.2 ⟨?_, eventually_nhdsWithin_of_forall
        fun t ht => Set.mem_Ioi.2 (sub_pos.2 ht)⟩
      have : Tendsto (fun t : ℝ => t - t0) (𝓝 t0) (𝓝 (t0 - t0)) :=
        tendsto_id.sub tendsto_const_nhds
      rw [sub_self] at this
      exact this.mono_left nhdsWithin_le_nhds
    have h1 : Tendsto (fun t => T t0 (T (t - t0) x)) (𝓝[>] t0) (𝓝 (T t0 x)) :=
      ((T t0).continuous.tendsto x).comp ((h_strong x).comp hlim)
    refine h1.congr' (eventually_nhdsWithin_of_forall fun t ht => ?_)
    have ht' : t0 < t := ht
    have e : T t = T t0 * T (t - t0) := by
      rw [← h_law t0 (t - t0) ht0' (by linarith), add_sub_cancel]
    show T t0 (T (t - t0) x) = T t x
    rw [e]
    rfl

/-- A bounded generator forces norm continuity. For a bounded operator `A` on a complete normed
space, the semigroup `e^(tA)` satisfies `‖e^(tA) - I‖ ≤ e^(t‖A‖) - 1` for every `t ≥ 0`, so the
whole operator `e^(tA)` returns to `I` in norm as `t` shrinks to 0. -/
theorem bounded_generator_norm_continuous
    {𝕜 : Type*} [RCLike 𝕜]
    {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X] [CompleteSpace X]
    (A : X →L[𝕜] X) :
    (∀ t : ℝ, 0 ≤ t →
        ‖NormedSpace.exp ((t : 𝕜) • A) - 1‖ ≤ Real.exp (t * ‖A‖) - 1) ∧
      Tendsto (fun t : ℝ => NormedSpace.exp ((t : 𝕜) • A)) (𝓝[>] 0) (𝓝 1) := by
  have hbound : ∀ B : X →L[𝕜] X, ‖NormedSpace.exp B - 1‖ ≤ Real.exp ‖B‖ - 1 := by
    intro B
    have h1 := NormedSpace.exp_series_hasSum_exp' (𝕂 := 𝕜) B
    have h2 := (hasSum_nat_add_iff' 1).mpr h1
    rw [Finset.sum_range_one] at h2
    simp only [Nat.factorial_zero, Nat.cast_one, inv_one, pow_zero, one_smul] at h2
    have h3 : HasSum (fun n : ℕ => ‖B‖ ^ (n + 1) / ((n + 1).factorial : ℝ))
        (Real.exp ‖B‖ - 1) := by
      have h4 := NormedSpace.expSeries_div_hasSum_exp ‖B‖
      rw [← Real.exp_eq_exp_ℝ] at h4
      have h5 := (hasSum_nat_add_iff' 1).mpr h4
      rw [Finset.sum_range_one] at h5
      simpa using h5
    refine h2.norm_le_of_bounded h3 (fun n => ?_)
    rw [norm_smul, norm_inv, RCLike.norm_natCast, div_eq_inv_mul]
    gcongr
    exact norm_pow_le' B n.succ_pos
  constructor
  · intro t ht
    refine (hbound _).trans ?_
    rw [norm_smul, RCLike.norm_ofReal, abs_of_nonneg ht]
  · have hc : Continuous (fun t : ℝ => NormedSpace.exp ((t : 𝕜) • A)) := by
      rw [continuous_iff_continuousAt]
      intro t
      exact (NormedSpace.exp_analytic (𝕂 := 𝕜) _).continuousAt.comp
        (f := fun t : ℝ => (t : 𝕜) • A)
        ((by fun_prop : Continuous fun t : ℝ => (t : 𝕜) • A).continuousAt)
    have := hc.tendsto 0
    simp only [RCLike.ofReal_zero, zero_smul, NormedSpace.exp_zero] at this
    exact this.mono_left nhdsWithin_le_nhds

-- The desk with no hold line: rate matrix G = [[-4, 4], [5, -5]] and the long-run table Π
-- with both rows (5/9, 4/9). Then Π² = Π, Π(I - Π) = 0, and G = 9(Π - I), so the eigenvalues are 0 and -9.
example : (!![5/9, 4/9; 5/9, 4/9] : Matrix (Fin 2) (Fin 2) ℚ) * !![5/9, 4/9; 5/9, 4/9] =
    !![5/9, 4/9; 5/9, 4/9] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> norm_num
example : (!![5/9, 4/9; 5/9, 4/9] : Matrix (Fin 2) (Fin 2) ℚ) * (1 - !![5/9, 4/9; 5/9, 4/9]) = 0 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.one_apply] <;> norm_num
example : (!![-4, 4; 5, -5] : Matrix (Fin 2) (Fin 2) ℚ) = 9 • (!![5/9, 4/9; 5/9, 4/9] - 1) := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.one_apply] <;> norm_num

-- Waits of 15 and 30 minutes make one of 45: 1/4 h + 1/2 h = 3/4 h.
example : (1 / 4 : ℚ) + 1 / 2 = 3 / 4 := by norm_num

-- One agent: top leaving rate 4 + 5 = 9 an hour, generator size 2 × 9 = 18.
example : 2 * (4 + 5) = 18 := by norm_num

-- An agent for every caller cut at N states: top leaving rate 5(N - 1), generator size
-- 90, 990 and 9990 at N = 10, 100 and 1000; at N = 10 the top leaving rate is 45 an hour.
example : 5 * (10 - 1) = 45 := by norm_num
example : 2 * (5 * (10 - 1)) = 90 := by norm_num
example : 2 * (5 * (100 - 1)) = 990 := by norm_num
example : 2 * (5 * (1000 - 1)) = 9990 := by norm_num

#print axioms strongly_continuous_semigroup_growth_bound
#print axioms strongly_continuous_semigroup_orbit_continuous
#print axioms bounded_generator_norm_continuous
