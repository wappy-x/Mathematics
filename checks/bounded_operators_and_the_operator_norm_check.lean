-- Bounded operators: a linear map between real normed spaces is continuous exactly when it has a finite gain, the bounded maps into a complete space form a complete space, and the sampled blur on N samples has peak gain 1 - a^N.
import Mathlib.Analysis.Normed.Operator.Completeness
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Tactic.NormNum

open Matrix

/-- For a linear map `T` between real normed spaces, four properties are the same:
`T` is continuous; `T` is continuous at one point; `T` has a finite gain `C`, so that
`‖T x‖ ≤ C ‖x‖` for every input `x`; and `T` is Lipschitz, so two inputs close together
give outputs at most a fixed constant times as far apart. -/
theorem linear_map_continuous_iff_finite_gain
    {X Y : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    [NormedAddCommGroup Y] [NormedSpace ℝ Y] (T : X →ₗ[ℝ] Y) :
    List.TFAE
      [ Continuous T,
        ∃ x₀ : X, ContinuousAt T x₀,
        ∃ C : ℝ, ∀ x : X, ‖T x‖ ≤ C * ‖x‖,
        ∃ K : NNReal, LipschitzWith K T ] := by
  tfae_have 1 → 2 := fun h => ⟨0, h.continuousAt⟩
  tfae_have 2 → 1 := by
    rintro ⟨x₀, h⟩
    apply continuous_of_continuousAt_zero T
    have h2 : ContinuousAt (fun y : X => T (y + x₀) - T x₀) 0 :=
      (h.comp_of_eq (continuousAt_id.add continuousAt_const) (by simp)).sub continuousAt_const
    have heq : (fun y : X => T (y + x₀) - T x₀) = T := by
      funext y; simp
    rwa [heq] at h2
  tfae_have 1 → 3 := fun h => ⟨‖(⟨T, h⟩ : X →L[ℝ] Y)‖, fun x => (⟨T, h⟩ : X →L[ℝ] Y).le_opNorm x⟩
  tfae_have 3 → 1 := fun ⟨C, hC⟩ => AddMonoidHomClass.continuous_of_bound T C hC
  tfae_have 1 → 4 := fun h => ⟨‖(⟨T, h⟩ : X →L[ℝ] Y)‖₊, (⟨T, h⟩ : X →L[ℝ] Y).lipschitzWith⟩
  tfae_have 4 → 1 := fun ⟨K, hK⟩ => hK.continuous
  tfae_finish

/-- If the output space `Y` is a Banach space (complete), then the space `B(X, Y)` of
bounded linear maps from `X` to `Y`, with the operator norm, is complete: every sequence
of bounded maps that is Cauchy in operator norm converges in operator norm to a bounded map. -/
theorem bounded_operators_complete_of_complete_codomain
    {X Y : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    [NormedAddCommGroup Y] [NormedSpace ℝ Y] [CompleteSpace Y]
    (T : ℕ → X →L[ℝ] Y) (hT : CauchySeq T) :
    ∃ S : X →L[ℝ] Y, Filter.Tendsto T Filter.atTop (nhds S) := by
  exact cauchySeq_tendsto_of_complete hT

/-- The blur on a clip of `N` samples, unrolled: output sample `i` is the weighted sum of the
inputs so far, with weight `(1 - a) a^k` on the input `k` samples back. This is the
recursion `(Rx)_n = (1 - a) x_n + a (Rx)_{n-1}` started from silence. -/
noncomputable def blurMatrix (a : ℝ) (N : ℕ) : Matrix (Fin N) (Fin N) ℝ :=
  fun i j => if j ≤ i then (1 - a) * a ^ (i.val - j.val) else 0

theorem blurMatrix_nonneg (a : ℝ) (ha0 : 0 < a) (ha1 : a < 1) (N : ℕ) (i j : Fin N) :
    0 ≤ blurMatrix a N i j := by
  unfold blurMatrix
  split_ifs
  · exact mul_nonneg (by linarith) (pow_nonneg ha0.le _)
  · exact le_refl 0

#print axioms blurMatrix_nonneg

theorem blurMatrix_row_sum (a : ℝ) (N : ℕ) (i : Fin N) :
    ∑ j, blurMatrix a N i j = 1 - a ^ (i.val + 1) := by
  unfold blurMatrix
  simp only [Fin.le_def]
  rw [Fin.sum_univ_eq_sum_range (fun j => if j ≤ i.val then (1 - a) * a ^ (i.val - j) else 0) N]
  rw [← Finset.sum_filter]
  have hf : (Finset.range N).filter (fun j => j ≤ i.val) = Finset.range (i.val + 1) := by
    ext j; simp only [Finset.mem_filter, Finset.mem_range]; omega
  have hr := Finset.sum_range_reflect (fun k => a ^ k) (i.val + 1)
  simp only [Nat.add_sub_cancel] at hr
  rw [hf, ← Finset.mul_sum, hr]
  have := geom_sum_mul a (i.val + 1)
  linear_combination (-1 : ℝ) * this

#print axioms blurMatrix_row_sum

/-- The blur's gain formula: with smoothing factor `a` between 0 and 1, the blur on clips of
`N` samples, measured by their peak (the sup norm) on both sides, has operator norm
`1 - a^N`. -/
theorem blur_operator_norm (a : ℝ) (ha0 : 0 < a) (ha1 : a < 1) (N : ℕ) :
    ‖LinearMap.toContinuousLinearMap (Matrix.mulVecLin (blurMatrix a N))‖ = 1 - a ^ N := by
  set φ := LinearMap.toContinuousLinearMap (Matrix.mulVecLin (blurMatrix a N)) with hφdef
  have hφ : ∀ x, φ x = blurMatrix a N *ᵥ x := fun x => rfl
  have hpN : a ^ N ≤ 1 := pow_le_one₀ ha0.le ha1.le
  apply ContinuousLinearMap.opNorm_eq_of_bounds
  · linarith
  · intro x
    rw [hφ]
    apply (pi_norm_le_iff_of_nonneg (mul_nonneg (by linarith) (norm_nonneg x))).2
    intro i
    rw [Real.norm_eq_abs]
    calc |(blurMatrix a N *ᵥ x) i| = |∑ j, blurMatrix a N i j * x j| := rfl
      _ ≤ ∑ j, |blurMatrix a N i j * x j| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ j, blurMatrix a N i j * ‖x‖ := by
          apply Finset.sum_le_sum
          intro j _
          rw [abs_mul, abs_of_nonneg (blurMatrix_nonneg a ha0 ha1 N i j)]
          apply mul_le_mul_of_nonneg_left _ (blurMatrix_nonneg a ha0 ha1 N i j)
          rw [← Real.norm_eq_abs]
          exact norm_le_pi_norm x j
      _ = (1 - a ^ (i.val + 1)) * ‖x‖ := by rw [← Finset.sum_mul, blurMatrix_row_sum]
      _ ≤ (1 - a ^ N) * ‖x‖ := by
          apply mul_le_mul_of_nonneg_right _ (norm_nonneg x)
          have : a ^ N ≤ a ^ (i.val + 1) :=
            pow_le_pow_of_le_one ha0.le ha1.le (by omega)
          linarith
  · intro M hM h
    rcases Nat.eq_zero_or_pos N with rfl | hN
    · simpa using hM
    · let x : Fin N → ℝ := fun _ => 1
      have hx : ‖x‖ ≤ 1 := (pi_norm_le_iff_of_nonneg zero_le_one).2 fun i => by simp [x]
      have h1 := h x
      have h2 := norm_le_pi_norm (φ x) ⟨N - 1, by omega⟩
      have h3 : (φ x) ⟨N - 1, by omega⟩ = 1 - a ^ N := by
        rw [hφ]
        change ∑ j, blurMatrix a N ⟨N - 1, by omega⟩ j * x j = _
        simp only [x, mul_one]
        rw [blurMatrix_row_sum]
        congr 2
        simp only
        omega
      rw [h3, Real.norm_eq_abs, abs_of_nonneg (by linarith)] at h2
      nlinarith

-- The card's worked numbers, as exact fractions.
-- Blur gain on 4 samples with a = 1/2: 1/2 + 1/4 + 1/8 + 1/16 = 1 - 2^-4 = 15/16 (0.9375).
example : (1 : ℚ) / 2 + 1 / 4 + 1 / 8 + 1 / 16 = 1 - (1 / 2) ^ 4 := by norm_num
example : (1 : ℚ) - (1 / 2) ^ 4 = 15 / 16 := by norm_num
-- Bound on the clip (4/5, -1/2, 3/10, 3/5): 15/16 times its peak 4/5 is 3/4 (0.7500).
example : (15 : ℚ) / 16 * (4 / 5) = 3 / 4 := by norm_num
-- Blurring that clip by hand: 2/5, -1/20, 1/8, 29/80 (0.4000, -0.0500, 0.1250, 0.3625).
example : (1 : ℚ) / 2 * (4 / 5) + 1 / 2 * 0 = 2 / 5 := by norm_num
example : (1 : ℚ) / 2 * (-1 / 2) + 1 / 2 * (2 / 5) = -1 / 20 := by norm_num
example : (1 : ℚ) / 2 * (3 / 10) + 1 / 2 * (-1 / 20) = 1 / 8 := by norm_num
example : (1 : ℚ) / 2 * (3 / 5) + 1 / 2 * (1 / 8) = 29 / 80 := by norm_num
-- The held clip at 4/5 reaches the bound: its fourth blurred sample is 3/4.
example : (1 : ℚ) / 2 * (4 / 5) + 1 / 2 * (7 / 10) = 3 / 4 := by norm_num
-- Unblur gain at a = 1/2: (1 + a)/(1 - a) = 3.
example : ((1 : ℚ) + 1 / 2) / (1 - 1 / 2) = 3 := by norm_num
-- Unblur of (2/5, -2/5, ...), sample 2: 2 * (-2/5) - 2/5 = -6/5, past full scale.
example : (2 : ℚ) * (-2 / 5) - 2 / 5 = -6 / 5 := by norm_num
-- Gains multiply along a chain: blur then unblur is the identity, gain 1 <= 15/16 * 3.
example : (1 : ℚ) ≤ 15 / 16 * 3 := by norm_num
-- Truncated blurs: ||R_5 - R_10|| = 2^-5 - 2^-10 = 31/1024.
example : (1 / 2 : ℚ) ^ 5 - (1 / 2) ^ 10 = 31 / 1024 := by norm_num

#print axioms linear_map_continuous_iff_finite_gain
#print axioms bounded_operators_complete_of_complete_codomain
#print axioms blur_operator_norm
