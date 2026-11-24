-- Operator topologies: on bounded operators norm convergence implies strong implies weak, the shift on l2 shows neither arrow reverses, and Goldstine's theorem says a real Banach space's unit ball is weak-star dense in the unit ball of its second dual.
import Mathlib.Analysis.InnerProductSpace.WeakOperatorTopology
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Topology.Algebra.Module.Spaces.PointwiseConvergenceCLM
import Mathlib.Analysis.Normed.Module.DoubleDual
import Mathlib.Analysis.Normed.Module.WeakDual
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Analysis.LocallyConvex.WeakDual

open Filter
open scoped Topology InnerProductSpace lp

lemma two_toReal_pos : 0 < (2 : ENNReal).toReal := by norm_num

lemma exists_delay :
    ∃ S : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ), ∀ u : ℓ²(ℕ, ℝ), S u 0 = 0 ∧ ∀ k, S u (k + 1) = u k := by
  have hp := two_toReal_pos
  have hmem : ∀ u : ℓ²(ℕ, ℝ),
      Memℓp (fun k : ℕ => if k = 0 then (0 : ℝ) else u (k - 1)) 2 := by
    intro u
    rw [memℓp_gen_iff hp, ← summable_nat_add_iff 1]
    simpa using (lp.memℓp u).summable hp
  let L : ℓ²(ℕ, ℝ) →ₗ[ℝ] ℓ²(ℕ, ℝ) :=
    { toFun := fun u => ⟨fun k => if k = 0 then (0 : ℝ) else u (k - 1), hmem u⟩
      map_add' := fun u v => by
        ext k
        show (if k = 0 then (0 : ℝ) else (u + v) (k - 1)) =
          (if k = 0 then (0 : ℝ) else u (k - 1)) + (if k = 0 then (0 : ℝ) else v (k - 1))
        split_ifs <;> simp
      map_smul' := fun c u => by
        ext k
        show (if k = 0 then (0 : ℝ) else (c • u) (k - 1)) =
          c • (if k = 0 then (0 : ℝ) else u (k - 1))
        split_ifs <;> simp }
  have hL0 : ∀ u, L u 0 = 0 := fun u => by simp [L]
  have hL1 : ∀ u k, L u (k + 1) = u k := fun u k => by simp [L]
  refine ⟨L.mkContinuous 1 fun u => ?_, fun u => ⟨hL0 u, hL1 u⟩⟩
  rw [one_mul]
  apply lp.norm_le_of_tsum_le hp (norm_nonneg _)
  rw [lp.norm_rpow_eq_tsum hp u, ((lp.memℓp (L u)).summable hp).tsum_eq_zero_add]
  simp only [hL0, hL1, norm_zero]
  rw [Real.zero_rpow hp.ne', zero_add]

lemma exists_advance :
    ∃ A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ), ∀ u : ℓ²(ℕ, ℝ), ∀ k, A u k = u (k + 1) := by
  have hp := two_toReal_pos
  have hmem : ∀ u : ℓ²(ℕ, ℝ), Memℓp (fun k : ℕ => u (k + 1)) 2 := by
    intro u
    rw [memℓp_gen_iff hp]
    exact (summable_nat_add_iff 1).mpr ((lp.memℓp u).summable hp)
  let L : ℓ²(ℕ, ℝ) →ₗ[ℝ] ℓ²(ℕ, ℝ) :=
    { toFun := fun u => ⟨fun k => u (k + 1), hmem u⟩
      map_add' := fun u v => by
        ext k
        show (u + v) (k + 1) = u (k + 1) + v (k + 1)
        simp
      map_smul' := fun c u => by
        ext k
        show (c • u) (k + 1) = c • u (k + 1)
        simp }
  have hL : ∀ u k, L u k = u (k + 1) := fun u k => rfl
  refine ⟨L.mkContinuous 1 fun u => ?_, fun u k => hL u k⟩
  rw [one_mul]
  apply lp.norm_le_of_tsum_le hp (norm_nonneg _)
  rw [lp.norm_rpow_eq_tsum hp u, ((lp.memℓp u).summable hp).tsum_eq_zero_add]
  simp only [hL]
  have : 0 ≤ ‖u 0‖ ^ (2 : ENNReal).toReal := by positivity
  linarith
lemma advance_mul_delay (S A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ))
    (hS : ∀ u : ℓ²(ℕ, ℝ), S u 0 = 0 ∧ ∀ k, S u (k + 1) = u k)
    (hA : ∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), A u k = u (k + 1)) : A * S = 1 := by
  ext u k
  simp [hA, (hS u).2]

lemma adjoint_delay (S A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ))
    (hS : ∀ u : ℓ²(ℕ, ℝ), S u 0 = 0 ∧ ∀ k, S u (k + 1) = u k)
    (hA : ∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), A u k = u (k + 1)) :
    ContinuousLinearMap.adjoint S = A := by
  symm
  rw [ContinuousLinearMap.eq_adjoint_iff]
  intro x y
  have h1 := lp.hasSum_inner (𝕜 := ℝ) (A x) y
  have h2 := lp.hasSum_inner (𝕜 := ℝ) x (S y)
  rw [← hasSum_nat_add_iff' 1] at h2
  simp only [Finset.range_one, Finset.sum_singleton, (hS y).1, (hS y).2, inner_zero_right,
    sub_zero] at h2
  simp only [hA] at h1
  exact h1.unique h2

lemma advance_pow_apply (A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ))
    (hA : ∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), A u k = u (k + 1)) (n : ℕ) (u : ℓ²(ℕ, ℝ)) (k : ℕ) :
    (A ^ n) u k = u (k + n) := by
  induction n generalizing u with
  | zero => simp
  | succ n ih => rw [pow_succ, mul_apply_eq_comp, ih, hA, add_assoc]

lemma norm_advance_pow_apply_le (A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ))
    (hA : ∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), A u k = u (k + 1)) (n : ℕ) (u : ℓ²(ℕ, ℝ)) :
    ‖(A ^ n) u‖ ≤ ‖u‖ := by
  have hp := two_toReal_pos
  induction n generalizing u with
  | zero => simp
  | succ n ih =>
    rw [pow_succ, mul_apply_eq_comp]
    refine (ih (A u)).trans ?_
    apply lp.norm_le_of_tsum_le hp (norm_nonneg _)
    rw [lp.norm_rpow_eq_tsum hp u, ((lp.memℓp u).summable hp).tsum_eq_zero_add]
    simp only [hA]
    have : 0 ≤ ‖u 0‖ ^ (2 : ENNReal).toReal := by positivity
    linarith

lemma advance_pow_tendsto (A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ))
    (hA : ∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), A u k = u (k + 1)) (u : ℓ²(ℕ, ℝ)) :
    Tendsto (fun n : ℕ => (A ^ n) u) atTop (𝓝 0) := by
  have hp := two_toReal_pos
  rw [tendsto_zero_iff_norm_tendsto_zero]
  have h : ∀ n : ℕ, ‖(A ^ n) u‖ = (∑' k, ‖u (k + n)‖ ^ (2 : ENNReal).toReal) ^ (1 / (2 : ENNReal).toReal) := by
    intro n
    rw [lp.norm_eq_tsum_rpow hp]
    simp only [advance_pow_apply A hA]
  simp only [h]
  have := (tendsto_sum_nat_add fun k => ‖u k‖ ^ (2 : ENNReal).toReal).rpow_const
    (p := 1 / (2 : ENNReal).toReal) (Or.inr (by positivity))
  rwa [Real.zero_rpow (by positivity)] at this

lemma norm_advance_pow (A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ))
    (hA : ∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), A u k = u (k + 1)) (n : ℕ) : ‖A ^ n‖ = 1 := by
  apply le_antisymm
  · exact ContinuousLinearMap.opNorm_le_bound _ zero_le_one fun u => by
      rw [one_mul]; exact norm_advance_pow_apply_le A hA n u
  · let e : ℕ → ℓ²(ℕ, ℝ) := fun m => lp.single 2 m 1
    have he : ∀ m, ‖e m‖ = 1 := fun m => by simp [e, lp.norm_single]
    have h1 : (A ^ n) (e n) = e 0 := by
      ext k
      rw [advance_pow_apply A hA]
      simp only [e, lp.single_apply]
      by_cases hk : k = 0 <;> simp [hk]
    have := (A ^ n).le_opNorm (e n)
    rw [h1, he, he, mul_one] at this
    exact this

theorem weakDual_locallyConvexSpace (X : Type*) [NormedAddCommGroup X] [NormedSpace ℝ X] :
    LocallyConvexSpace ℝ (WeakDual ℝ X) := by
  unfold WeakDual
  exact WeakBilin.locallyConvexSpace
theorem weakDual_dual_eq_eval (X : Type*) [NormedAddCommGroup X] [NormedSpace ℝ X]
    (f : StrongDual ℝ (WeakDual ℝ X)) :
    ∃ φ : X, ∀ Ψ : WeakDual ℝ X, f Ψ = WeakDual.toStrongDual Ψ φ := by
  obtain ⟨φ, hφ⟩ := LinearMap.dualEmbedding_surjective
    (topDualPairing ℝ X : (X →L[ℝ] ℝ) →ₗ[ℝ] X →ₗ[ℝ] ℝ) f
  exact ⟨φ, fun Ψ => by rw [← hφ]; rfl⟩

/-- **The shift separates the three senses.** On the endless lists `ℓ²` there is the delay
`S (u₀, u₁, …) = (0, u₀, u₁, …)`; its adjoint is the advance `S* (u₀, u₁, …) = (u₁, u₂, …)`.
The powers of the advance tend to `0` strongly (at each input) but each has gain `1`, so they
converge in norm to nothing; the powers of the delay tend to `0` weakly (every reading
`⟪w, Sⁿ u⟫` fades) but converge strongly to nothing; and advancing after delaying gives the
identity, `S*ⁿ Sⁿ = I`, at every `n`. -/
theorem shift_separates_norm_strong_weak :
    ∃ S : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ),
      (∀ u : ℓ²(ℕ, ℝ), S u 0 = 0 ∧ ∀ k, S u (k + 1) = u k) ∧
      (∀ (u : ℓ²(ℕ, ℝ)) (k : ℕ), (ContinuousLinearMap.adjoint S) u k = u (k + 1)) ∧
      Tendsto (fun n : ℕ => ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ)
        ℓ²(ℕ, ℝ) ℓ²(ℕ, ℝ) (ContinuousLinearMap.adjoint S ^ n)) atTop (𝓝 0) ∧
      (∀ n : ℕ, ‖ContinuousLinearMap.adjoint S ^ n‖ = 1) ∧
      (¬ ∃ A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ),
        Tendsto (fun n : ℕ => ContinuousLinearMap.adjoint S ^ n) atTop (𝓝 A)) ∧
      Tendsto (fun n : ℕ => ContinuousLinearMapWOT.ofCLM (σ := RingHom.id ℝ) (S ^ n))
        atTop (𝓝 0) ∧
      (¬ ∃ A : ℓ²(ℕ, ℝ) →L[ℝ] ℓ²(ℕ, ℝ),
        Tendsto (fun n : ℕ => ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ)
          ℓ²(ℕ, ℝ) ℓ²(ℕ, ℝ) (S ^ n)) atTop
          (𝓝 (ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ)
            ℓ²(ℕ, ℝ) ℓ²(ℕ, ℝ) A))) ∧
      (∀ n : ℕ, ContinuousLinearMap.adjoint S ^ n * S ^ n = 1) := by
  obtain ⟨S, hS⟩ := exists_delay
  obtain ⟨A, hA⟩ := exists_advance
  have hadj := adjoint_delay S A hS hA
  have hinner : ∀ (n : ℕ) (x y : ℓ²(ℕ, ℝ)), ⟪y, (S ^ n) x⟫_ℝ = ⟪(A ^ n) y, x⟫_ℝ := by
    intro n
    induction n with
    | zero => intro x y; simp
    | succ n ih =>
      intro x y
      rw [pow_succ', mul_apply_eq_comp, ← ContinuousLinearMap.adjoint_inner_left, hadj, ih,
        pow_succ, mul_apply_eq_comp]
  refine ⟨S, hS, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro u k
    rw [hadj, hA]
  · rw [hadj, PointwiseConvergenceCLM.tendsto_iff_forall_tendsto]
    intro u
    exact advance_pow_tendsto A hA u
  · intro n
    rw [hadj]
    exact norm_advance_pow A hA n
  · rintro ⟨B, hB⟩
    rw [hadj] at hB
    have hB0 : B = 0 := by
      ext1 u
      have h1 : Tendsto (fun n : ℕ => (A ^ n) u) atTop (𝓝 (B u)) :=
        ((ContinuousLinearMap.apply ℝ _ u).continuous.tendsto B).comp hB
      exact tendsto_nhds_unique h1 (advance_pow_tendsto A hA u)
    subst hB0
    have h := hB.norm
    simp only [norm_zero, norm_advance_pow A hA] at h
    exact one_ne_zero (tendsto_nhds_unique tendsto_const_nhds h)
  · rw [ContinuousLinearMapWOT.tendsto_iff_forall_inner_apply_tendsto]
    intro x y
    simp only [ContinuousLinearMapWOT.ofCLM_apply, ContinuousLinearMapWOT.zero_apply,
      inner_zero_right, hinner]
    simpa using (advance_pow_tendsto A hA y).inner (tendsto_const_nhds (x := x))
  · rintro ⟨B, hB⟩
    rw [PointwiseConvergenceCLM.tendsto_iff_forall_tendsto] at hB
    let e : ℓ²(ℕ, ℝ) := lp.single 2 0 1
    have he : ‖e‖ = 1 := by simp [e, lp.norm_single]
    have h : Tendsto (fun n : ℕ => (S ^ n) e) atTop (𝓝 (B e)) := hB e
    have hBe : B e = 0 := by
      have h1 : Tendsto (fun n : ℕ => ⟪B e, (S ^ n) e⟫_ℝ) atTop (𝓝 ⟪B e, B e⟫_ℝ) :=
        tendsto_const_nhds.inner h
      have h2 : Tendsto (fun n : ℕ => ⟪B e, (S ^ n) e⟫_ℝ) atTop (𝓝 0) := by
        simp only [hinner]
        simpa using (advance_pow_tendsto A hA (B e)).inner (tendsto_const_nhds (x := e))
      exact inner_self_eq_zero.mp (tendsto_nhds_unique h1 h2)
    have h3 := h.norm
    rw [hBe, norm_zero] at h3
    have h4 : ∀ n : ℕ, 1 ≤ ‖(S ^ n) e‖ := by
      intro n
      have := norm_advance_pow_apply_le A hA n ((S ^ n) e)
      rwa [← mul_apply_eq_comp, pow_mul_pow_eq_one n (advance_mul_delay S A hS hA),
        one_apply_eq_self, he] at this
    have := ge_of_tendsto' h3 h4
    norm_num at this
  · intro n
    rw [hadj]
    exact pow_mul_pow_eq_one n (advance_mul_delay S A hS hA)

/-- **Norm implies strong implies weak.** For bounded operators on a real Hilbert space `H`,
along any sequence or net: if `Tₐ → T` in the operator norm then `Tₐ → T` strongly (in the
topology of convergence at each input), and if `Tₐ → T` strongly then `Tₐ → T` weakly (in the
weak operator topology, where every reading `⟪w, Tₐ u⟫` settles). -/
theorem norm_imp_strong_imp_weak {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H]
    [CompleteSpace H] {α : Type*} {l : Filter α} (T : α → H →L[ℝ] H) (A : H →L[ℝ] H) :
    (Tendsto T l (𝓝 A) →
      Tendsto (fun a => ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ) H H (T a))
        l (𝓝 (ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ) H H A))) ∧
    (Tendsto (fun a => ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ) H H (T a))
        l (𝓝 (ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ) H H A)) →
      Tendsto (fun a => ContinuousLinearMapWOT.ofCLM (σ := RingHom.id ℝ) (T a)) l
        (𝓝 (ContinuousLinearMapWOT.ofCLM (σ := RingHom.id ℝ) A))) := by
  refine ⟨fun h => ((ContinuousLinearMap.toPointwiseConvergenceCLM ℝ (RingHom.id ℝ) H H).continuous.tendsto A).comp h, fun h => ?_⟩
  rw [PointwiseConvergenceCLM.tendsto_iff_forall_tendsto] at h
  rw [ContinuousLinearMapWOT.tendsto_iff_forall_inner_apply_tendsto]
  intro x y
  exact ((continuous_const.inner continuous_id).tendsto _).comp (h x)


/-- **Goldstine's theorem.** For a real Banach space `X`, the image of its closed unit ball
under the reading map `J : X → X''`, `(J x)(φ) = φ x`, is weak-star dense in the closed unit
ball of the second dual: its closure in the weak-star topology is that whole ball. -/
theorem goldstine (X : Type*) [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X] :
    closure ((fun x => StrongDual.toWeakDual (NormedSpace.inclusionInDoubleDual ℝ X x)) ''
        Metric.closedBall (0 : X) 1) =
      WeakDual.toStrongDual ⁻¹' Metric.closedBall (0 : StrongDual ℝ (StrongDual ℝ X)) 1 := by
  apply Set.Subset.antisymm
  · apply closure_minimal _ (WeakDual.isClosed_closedBall 0 1)
    rintro _ ⟨x, hx, rfl⟩
    simp only [Set.mem_preimage, Metric.mem_closedBall, dist_zero_right] at hx ⊢
    exact (NormedSpace.double_dual_bound ℝ X x).trans hx
  · intro Φ hΦ
    by_contra hnot
    have hconv : Convex ℝ (closure ((fun x => StrongDual.toWeakDual
        (NormedSpace.inclusionInDoubleDual ℝ X x)) '' Metric.closedBall (0 : X) 1)) := by
      apply Convex.closure
      exact (convex_closedBall (0:X) 1).linear_image
        ((StrongDual.toWeakDual : _ ≃ₗ[ℝ] _).toLinearMap ∘ₗ
          (NormedSpace.inclusionInDoubleDual ℝ X).toLinearMap)
    have := weakDual_locallyConvexSpace (StrongDual ℝ X)
    obtain ⟨f, u, hfu, hux⟩ := geometric_hahn_banach_closed_point hconv isClosed_closure hnot
    obtain ⟨φ, hf⟩ := weakDual_dual_eq_eval (StrongDual ℝ X) f
    have h1 : ∀ x ∈ Metric.closedBall (0:X) 1, φ x < u := fun x hx => by
      have := hfu _ (subset_closure ⟨x, hx, rfl⟩)
      rw [hf] at this
      simpa using this
    have hu : 0 ≤ u := by simpa using (h1 0 (by simp)).le
    have hφ : ‖φ‖ ≤ u := by
      refine ContinuousLinearMap.opNorm_le_of_unit_norm hu fun x hx => ?_
      have a := h1 x (by simp [hx])
      have b := h1 (-x) (by simp [hx])
      rw [map_neg] at b
      rw [Real.norm_eq_abs, abs_le]; constructor <;> linarith
    have hΦ' : ‖WeakDual.toStrongDual Φ‖ ≤ 1 := by
      have h := hΦ
      simp only [Set.mem_preimage, Metric.mem_closedBall] at h
      exact (dist_zero_right (WeakDual.toStrongDual Φ)).symm.le.trans h
    rw [hf] at hux
    have := (le_abs_self _).trans ((WeakDual.toStrongDual Φ).le_opNorm φ)
    nlinarith [norm_nonneg φ, norm_nonneg (WeakDual.toStrongDual Φ)]

/-! The clip `(3, 1, 4, 1, 5)`: energy after advancing `n` times, and the lag readings
`⟪u, Sⁿ u⟫`, exactly as on the card. -/
example : (List.map (fun n => ((([3, 1, 4, 1, 5] : List ℤ).drop n).map (· ^ 2)).sum)
    (List.range 6)) = [52, 43, 42, 26, 25, 0] := by decide
example : (List.map (fun n => (List.zipWith (· * ·) ([3, 1, 4, 1, 5] : List ℤ)
    ((List.replicate n (0 : ℤ) ++ [3, 1, 4, 1, 5]).take 5)).sum) (List.range 6)) =
    [52, 16, 33, 8, 15, 0] := by decide

/-! The net of Step 5, `T_mn v = v₁ (e_m + m e_n)` probed by `(1, 1/2, 1/3, …)`: with `ε = 1/q`,
`m = 2q + 1` and `n = 2mq + 1`, the reading `1/m + m/n` is below `ε`, that is
`(n + m²) q < m n`, for `q = 10, 100, 1000`. -/
example : (421 + 21 ^ 2) * 10 < 21 * 421 := by norm_num
example : (40201 + 201 ^ 2) * 100 < 201 * 40201 := by norm_num
example : (4002001 + 2001 ^ 2) * 1000 < 2001 * 4002001 := by norm_num

#print axioms two_toReal_pos
#print axioms exists_delay
#print axioms exists_advance
#print axioms advance_mul_delay
#print axioms adjoint_delay
#print axioms advance_pow_apply
#print axioms norm_advance_pow_apply_le
#print axioms advance_pow_tendsto
#print axioms norm_advance_pow
#print axioms weakDual_locallyConvexSpace
#print axioms weakDual_dual_eq_eval
#print axioms shift_separates_norm_strong_weak
#print axioms norm_imp_strong_imp_weak
#print axioms goldstine
