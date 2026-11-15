-- Infinite dimensions: the closed unit ball of a real normed space is compact exactly when the space is finite-dimensional, by Riesz's lemma, and the spikes in l2 are a bounded list with no convergent sublist.
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Analysis.Normed.Module.RieszLemma
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.Data.Fintype.Pi

open Filter Topology

/-- Riesz's theorem: the closed unit ball of a real normed space is compact
exactly when the space has finitely many dimensions. -/
theorem isCompact_closedBall_one_iff_finiteDimensional
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] :
    IsCompact (Metric.closedBall (0 : X) 1) ↔ FiniteDimensional ℝ X := by
  constructor
  · intro h
    exact FiniteDimensional.of_isCompact_closedBall₀ ℝ one_pos h
  · intro h
    exact isCompact_closedBall 0 1

/-- Riesz's lemma: if a closed subspace `M` misses part of a real normed space,
then for every theta with `0 < θ < 1` some vector of size 1 sits at distance
at least theta from all of `M`. -/
theorem riesz_lemma_unit_vector_far_from_subspace
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    (M : Subspace ℝ X) (hM : IsClosed (M : Set X)) (hMX : M ≠ ⊤)
    (θ : ℝ) (hθ0 : 0 < θ) (hθ1 : θ < 1) :
    ∃ x : X, ‖x‖ = 1 ∧ θ ≤ Metric.infDist x (M : Set X) := by
  have hF : ∃ x : X, x ∉ M := by
    by_contra h
    push Not at h
    exact hMX (eq_top_iff.mpr fun x _ => h x)
  obtain ⟨x₀, _, hnorm, hfar⟩ := riesz_lemma_of_lt_one hM hF hθ1
  refine ⟨x₀, hnorm, ?_⟩
  rw [Metric.le_infDist ⟨0, M.zero_mem⟩]
  intro y hy
  rw [dist_eq_norm]
  exact hfar y hy

/-- The spikes `e_n` in `ℓ²` (1 at hour `n`, 0 elsewhere) all have size 1,
every two different ones are `√2` apart, and no sublist of them converges
in the `ℓ²` norm: a bounded list with no settling part. -/
theorem spikes_bounded_sqrt_two_apart_no_convergent_sublist :
    (∀ n : ℕ, ‖(lp.single 2 n (1 : ℝ) : lp (fun _ : ℕ => ℝ) 2)‖ = 1) ∧
    (∀ n m : ℕ, n ≠ m →
      ‖(lp.single 2 n (1 : ℝ) : lp (fun _ : ℕ => ℝ) 2) - lp.single 2 m 1‖ = Real.sqrt 2) ∧
    (∀ φ : ℕ → ℕ, StrictMono φ →
      ¬ ∃ L : lp (fun _ : ℕ => ℝ) 2,
        Tendsto (fun k => (lp.single 2 (φ k) (1 : ℝ) : lp (fun _ : ℕ => ℝ) 2)) atTop (𝓝 L)) := by
  have hdiff : ∀ n m : ℕ, n ≠ m →
      ‖(lp.single 2 n (1 : ℝ) : lp (fun _ : ℕ => ℝ) 2) - lp.single 2 m 1‖ = Real.sqrt 2 := by
    intro n m hnm
    have hp : (0 : ℝ) < (2 : ENNReal).toReal := by norm_num
    have key := lp.norm_sum_single (E := fun _ : ℕ => ℝ) hp
      (fun i => if i = n then (1 : ℝ) else -1) {n, m}
    have hsum : (∑ i ∈ ({n, m} : Finset ℕ),
        lp.single 2 i (if i = n then (1 : ℝ) else -1) : lp (fun _ : ℕ => ℝ) 2)
        = lp.single 2 n (1 : ℝ) - lp.single 2 m 1 := by
      rw [Finset.sum_pair hnm]
      simp [Ne.symm hnm, sub_eq_add_neg]
    rw [hsum, Finset.sum_pair hnm] at key
    simp [Ne.symm hnm] at key
    have h2 : ‖(lp.single 2 n (1 : ℝ) : lp (fun _ : ℕ => ℝ) 2) - lp.single 2 m 1‖ ^ 2 = 2 := by
      have := key
      norm_num at this ⊢
      linarith
    rw [← h2, Real.sqrt_sq (norm_nonneg _)]
  refine ⟨fun n => ?_, hdiff, ?_⟩
  · rw [lp.norm_single (by norm_num)]
    simp
  · rintro φ hφ ⟨L, hL⟩
    set f := fun k => (lp.single 2 (φ k) (1 : ℝ) : lp (fun _ : ℕ => ℝ) 2)
    have h1 : Tendsto (fun k => f (k + 1) - f k) atTop (𝓝 (L - L)) :=
      ((hL.comp (tendsto_add_atTop_nat 1)).sub hL)
    rw [sub_self] at h1
    have h2 : Tendsto (fun k => ‖f (k + 1) - f k‖) atTop (𝓝 ‖(0 : lp (fun _ : ℕ => ℝ) 2)‖) :=
      h1.norm
    rw [norm_zero] at h2
    have h3 : (fun k => ‖f (k + 1) - f k‖) = fun _ => Real.sqrt 2 := by
      funext k
      exact hdiff _ _ (hφ (Nat.lt_succ_self k)).ne'
    rw [h3] at h2
    have := tendsto_nhds_unique tendsto_const_nhds h2
    have : (0 : ℝ) < Real.sqrt 2 := by positivity
    linarith

-- Spike number 169, cycling through a 168-hour week, lands on hour 1 again.
example : (169 - 1) % 168 + 1 = 1 := by decide

-- Records of 0s and 1s over N hours: 2^N of them, 16, 256 and 1024 at N = 4, 8, 10.
example : Fintype.card (Fin 4 → Fin 2) = 16 := by simp
example : Fintype.card (Fin 8 → Fin 2) = 256 := by simp
example : Fintype.card (Fin 10 → Fin 2) = 1024 := by simp

#print axioms isCompact_closedBall_one_iff_finiteDimensional
#print axioms riesz_lemma_unit_vector_far_from_subspace
#print axioms spikes_bounded_sqrt_two_apart_no_convergent_sublist
