-- Weak convergence: every bounded sequence in a real Hilbert space has a weakly convergent subsequence whose limit is no bigger than the sizes it keeps returning to, and the closed unit ball of any dual space is weak-star compact (sequentially so when the space is separable).
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Normed.Module.WeakDual
import Mathlib.Order.LiminfLimsup
import Mathlib.Analysis.InnerProductSpace.Dual
import Mathlib.Analysis.InnerProductSpace.Projection.Basic

open Filter Topology

/-- Sequential Banach–Alaoglu with radius `r`: a sequence in the dual of a separable normed
space with norms at most `r` has a pointwise convergent subsequence with limit of norm at most
`r`. -/
theorem helper_seq_weak_star_closedBall
    {𝕜 : Type*} [RCLike 𝕜] {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X]
    [TopologicalSpace.SeparableSpace X]
    (φ : ℕ → StrongDual 𝕜 X) (r : ℝ) (hφ : ∀ n, ‖φ n‖ ≤ r) :
    ∃ (ns : ℕ → ℕ) (ψ : StrongDual 𝕜 X), StrictMono ns ∧ ‖ψ‖ ≤ r ∧
      ∀ x : X, Tendsto (fun k => φ (ns k) x) atTop (𝓝 (ψ x)) := by
  have hK := WeakDual.isSeqCompact_closedBall 𝕜 X 0 r
  have hmem : ∀ n, StrongDual.toWeakDual (φ n) ∈
      WeakDual.toStrongDual ⁻¹' Metric.closedBall (0 : StrongDual 𝕜 X) r := by
    intro n
    simpa [Metric.mem_closedBall, dist_zero_right] using hφ n
  obtain ⟨ψ', hψ', ns, hns, hlim⟩ := hK hmem
  refine ⟨ns, WeakDual.toStrongDual ψ', hns, ?_, ?_⟩
  · simpa [Metric.mem_closedBall, dist_zero_right] using hψ'
  · intro x
    exact ((WeakDual.eval_continuous x).tendsto ψ').comp hlim

#print axioms helper_seq_weak_star_closedBall

/-- In a Hilbert space every bounded sequence has a subsequence on which every measurement
settles: if every `x n` has size at most `B`, there are races `ns 0 < ns 1 < ...` and a limit
`xlim` with `⟪y, x (ns k)⟫ → ⟪y, xlim⟫` for every weight `y`, and the limit keeps the
measurements but can only lose size: `‖xlim‖ ≤ liminf ‖x (ns k)‖ ≤ B`. -/
theorem bounded_seq_has_weakly_convergent_subseq
    {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
    (x : ℕ → H) (B : ℝ) (hB : ∀ n, ‖x n‖ ≤ B) :
    ∃ (ns : ℕ → ℕ) (xlim : H), StrictMono ns ∧
      (∀ y : H, Tendsto (fun k => inner ℝ y (x (ns k))) atTop (𝓝 (inner ℝ y xlim))) ∧
      ‖xlim‖ ≤ liminf (fun k => ‖x (ns k)‖) atTop ∧
      liminf (fun k => ‖x (ns k)‖) atTop ≤ B := by
  have hB0 : 0 ≤ B := le_trans (norm_nonneg _) (hB 0)
  set M : Submodule ℝ H := (Submodule.span ℝ (Set.range x)).topologicalClosure with hM
  have hsep : TopologicalSpace.IsSeparable (M : Set H) := by
    rw [hM, Submodule.topologicalClosure_coe]
    exact ((Set.countable_range x).isSeparable.span (R := ℝ)).closure
  have : TopologicalSpace.SeparableSpace M := hsep.separableSpace
  have : CompleteSpace M :=
    (Submodule.isClosed_topologicalClosure _).completeSpace_coe
  have hxM : ∀ n, x n ∈ M := fun n =>
    Submodule.le_topologicalClosure _ (Submodule.subset_span (Set.mem_range_self n))
  let φ : ℕ → StrongDual ℝ M := fun n => (innerSL ℝ (x n)).comp M.subtypeL
  have hφ : ∀ n, ‖φ n‖ ≤ B := by
    intro n
    refine ContinuousLinearMap.opNorm_le_bound _ hB0 fun m => ?_
    simp only [φ, ContinuousLinearMap.comp_apply, innerSL_apply_apply, Submodule.subtypeL_apply]
    calc ‖inner ℝ (x n) (m : H)‖ ≤ ‖x n‖ * ‖(m : H)‖ := norm_inner_le_norm _ _
      _ ≤ B * ‖m‖ := by
        rw [Submodule.norm_coe]
        exact mul_le_mul_of_nonneg_right (hB n) (norm_nonneg _)
  obtain ⟨ns, ψ, hns, -, hlim⟩ := helper_seq_weak_star_closedBall φ B hφ
  set z : M := (InnerProductSpace.toDual ℝ M).symm ψ
  have key : ∀ y : H, ∀ w ∈ M, inner ℝ y w = inner ℝ (M.starProjection y) w := by
    intro y w hw
    have h0 := Submodule.starProjection_inner_eq_zero (K := M) y w hw
    rw [inner_sub_left, sub_eq_zero] at h0
    exact h0
  have hweak : ∀ y : H, Tendsto (fun k => inner ℝ y (x (ns k))) atTop (𝓝 (inner ℝ y (z : H))) := by
    intro y
    have hPy : M.starProjection y ∈ M := M.starProjection_apply_mem y
    have h1 := hlim ⟨_, hPy⟩
    have e1 : (fun k => inner ℝ y (x (ns k))) = fun k => φ (ns k) ⟨_, hPy⟩ := by
      funext k
      simp only [φ, ContinuousLinearMap.comp_apply, innerSL_apply_apply, Submodule.subtypeL_apply]
      rw [key y _ (hxM _), real_inner_comm]
    have e2 : inner ℝ y (z : H) = ψ ⟨_, hPy⟩ := by
      rw [← InnerProductSpace.toDual_symm_apply, Submodule.coe_inner, key y _ z.2, real_inner_comm]
    rw [e1, e2]
    exact h1
  have hbdd : IsBoundedUnder (· ≥ ·) atTop (fun k => ‖x (ns k)‖) :=
    isBoundedUnder_of ⟨0, fun k => norm_nonneg _⟩
  refine ⟨ns, (z : H), hns, hweak, ?_, ?_⟩
  · by_contra hcon
    push Not at hcon
    obtain ⟨c, hc1, hc2⟩ := exists_between hcon
    set u : H := ‖(z : H)‖⁻¹ • (z : H)
    have hu : ‖u‖ ≤ 1 := by
      rcases eq_or_ne ‖(z : H)‖ 0 with h | h
      · simp [u, h]
      · rw [norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ h]
    have huz : inner ℝ u (z : H) = ‖(z : H)‖ := by
      rw [real_inner_smul_left, real_inner_self_eq_norm_sq]
      rcases eq_or_ne ‖(z : H)‖ 0 with h | h
      · simp [h]
      · field_simp
    have hev : ∀ᶠ k in atTop, c ≤ ‖x (ns k)‖ := by
      have := (hweak u).eventually (lt_mem_nhds (huz ▸ hc2))
      filter_upwards [this] with k hk
      calc c ≤ inner ℝ u (x (ns k)) := hk.le
        _ ≤ ‖u‖ * ‖x (ns k)‖ := real_inner_le_norm _ _
        _ ≤ 1 * ‖x (ns k)‖ := mul_le_mul_of_nonneg_right hu (norm_nonneg _)
        _ = ‖x (ns k)‖ := one_mul _
    have := le_liminf_of_le (isCoboundedUnder_ge_of_le atTop (fun k => hB (ns k))) hev
    linarith
  · exact liminf_le_of_frequently_le (Frequently.of_forall fun k => hB (ns k)) hbdd

/-- Banach–Alaoglu: for any normed space `X`, the unit ball `{φ ∈ X' : ‖φ‖ ≤ 1}` of its dual is
compact in the weak-star topology (convergence of the values `φ x` at every point `x`). -/
theorem dual_unit_ball_weak_star_compact
    {𝕜 : Type*} [RCLike 𝕜] {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X] :
    IsCompact {φ : WeakDual 𝕜 X | ‖WeakDual.toStrongDual φ‖ ≤ 1} := by
  simpa [Set.preimage, Metric.mem_closedBall, dist_zero_right] using
    WeakDual.isCompact_closedBall (𝕜 := 𝕜) (E := X) (0 : StrongDual 𝕜 X) 1

/-- Banach–Alaoglu, separable case: if `X` has a countable dense set, every sequence of
functionals `φ n` with `‖φ n‖ ≤ 1` has a subsequence converging weak-star, that is at every
point `x`, to a functional `ψ` that is still in the unit ball. -/
theorem separable_dual_unit_ball_weak_star_seq_compact
    {𝕜 : Type*} [RCLike 𝕜] {X : Type*} [NormedAddCommGroup X] [NormedSpace 𝕜 X]
    [TopologicalSpace.SeparableSpace X]
    (φ : ℕ → StrongDual 𝕜 X) (hφ : ∀ n, ‖φ n‖ ≤ 1) :
    ∃ (ns : ℕ → ℕ) (ψ : StrongDual 𝕜 X), StrictMono ns ∧ ‖ψ‖ ≤ 1 ∧
      ∀ x : X, Tendsto (fun k => φ (ns k) x) atTop (𝓝 (ψ x)) := by
  exact helper_seq_weak_star_closedBall φ 1 hφ

-- The card's bound: B² = 36 + 16 + 36 = 88 (start, middle and swap terms at their largest).
example : (36 : ℕ) + 16 + 36 = 88 := by norm_num
-- The swap profile 6 c_m has squared size 6² = 36 at every m.
example : (6 : ℕ) ^ 2 = 36 := by norm_num
-- Mazur's average of N swaps has squared size 36/N: size 6, 3, 1.5, 0.6 at N = 1, 4, 16, 100.
example : (36 : ℚ) / 1 = 6 ^ 2 := by norm_num
example : (36 : ℚ) / 4 = 3 ^ 2 := by norm_num
example : (36 : ℚ) / 16 = (3 / 2) ^ 2 := by norm_num
example : (36 : ℚ) / 100 = (3 / 5) ^ 2 := by norm_num

#print axioms bounded_seq_has_weakly_convergent_subseq
#print axioms dual_unit_ball_weak_star_compact
#print axioms separable_dual_unit_ball_weak_star_seq_compact
