-- Arzela-Ascoli: a sequence of functions on a closed interval that is bounded at each point and equicontinuous has a subsequence converging uniformly to a continuous limit, and for sets of continuous functions these two conditions are exactly what is needed.
import Mathlib.Topology.ContinuousMap.Bounded.ArzelaAscoli
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Topology.UniformSpace.UniformConvergence
import Mathlib.Topology.Sequences
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Topology.Order.Compact
import Mathlib.Tactic.NormNum
import Mathlib.Topology.UniformSpace.Ascoli

/-- Arzelà–Ascoli. Let f₁, f₂, … be functions on the closed interval [a, b]. Suppose they are
bounded at each point (for every t in [a, b], one number M bounds every |f_k(t)|) and
equicontinuous (every tolerance ε above zero has one window δ above zero such that times u and t
of [a, b] closer than δ give |f_k(u) − f_k(t)| < ε for every k at once). Then some subsequence
f_{k₁}, f_{k₂}, … with k₁ < k₂ < ⋯ converges uniformly on [a, b] to a function g that is
continuous on [a, b]. -/
theorem bounded_equicontinuous_has_uniformly_convergent_subsequence
    (a b : ℝ) (f : ℕ → ℝ → ℝ)
    (hbdd : ∀ t ∈ Set.Icc a b, ∃ M : ℝ, ∀ k, |f k t| ≤ M)
    (hequi : ∀ ε > 0, ∃ δ > 0, ∀ k, ∀ u ∈ Set.Icc a b, ∀ t ∈ Set.Icc a b,
      |u - t| < δ → |f k u - f k t| < ε) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ g : ℝ → ℝ, ContinuousOn g (Set.Icc a b) ∧
      TendstoUniformlyOn (fun j => f (φ j)) g Filter.atTop (Set.Icc a b) := by
  classical
  let K : Set ℝ := Set.Icc a b
  let 𝔖 : Set (Set ℝ) := {K}
  have : (uniformity (UniformOnFun ℝ ℝ 𝔖)).IsCountablyGenerated :=
    UniformOnFun.isCountablyGenerated_uniformity (𝔖 := 𝔖) (t := fun _ => K) (fun _ => rfl)
      (fun _ _ _ => le_rfl) (fun s hs => ⟨0, by rw [Set.mem_singleton_iff.mp hs]⟩)
  let F : UniformOnFun ℝ ℝ 𝔖 → ℝ → ℝ := UniformOnFun.toFun 𝔖
  let s : Set (UniformOnFun ℝ ℝ 𝔖) := Set.range (fun k => UniformOnFun.ofFun 𝔖 (f k))
  have hcpt : IsCompact (closure s) := by
    refine ArzelaAscoli.isCompact_closure_of_isClosedEmbedding (F := F) (𝔖 := 𝔖) ?_ ?_ ?_ ?_
    · intro K' hK'
      rw [Set.mem_singleton_iff.mp hK']
      exact isCompact_Icc
    · exact Topology.IsClosedEmbedding.id
    · intro K' hK' x₀ hx₀
      rw [Set.mem_singleton_iff.mp hK'] at hx₀ ⊢
      intro U hU
      obtain ⟨ε, hε, hεU⟩ := Metric.mem_uniformity_dist.mp hU
      obtain ⟨δ, hδ, hδ'⟩ := hequi ε hε
      filter_upwards [inter_mem_nhdsWithin K (Metric.ball_mem_nhds x₀ hδ)] with x hx
      rintro ⟨_, k, rfl⟩
      apply hεU
      have hx1 : |x - x₀| < δ := by
        have := hx.2
        rwa [Metric.mem_ball, Real.dist_eq] at this
      have := hδ' k x₀ hx₀ x hx.1 (by rw [abs_sub_comm]; exact hx1)
      rw [Real.dist_eq]
      exact this
    · intro K' hK' x hx
      rw [Set.mem_singleton_iff.mp hK'] at hx
      obtain ⟨M, hM⟩ := hbdd x hx
      refine ⟨Metric.closedBall 0 M, isCompact_closedBall 0 M, ?_⟩
      rintro _ ⟨k, rfl⟩
      rw [Metric.mem_closedBall, Real.dist_eq, sub_zero]
      exact hM k
  obtain ⟨G, -, φ, hφ, hG⟩ := hcpt.tendsto_subseq
    (x := fun k => UniformOnFun.ofFun 𝔖 (f k)) (fun k => subset_closure ⟨k, rfl⟩)
  have hU : TendstoUniformlyOn (fun j => f (φ j)) (UniformOnFun.toFun 𝔖 G) Filter.atTop K :=
    (UniformOnFun.tendsto_iff_tendstoUniformlyOn.mp hG) K rfl
  refine ⟨φ, hφ, UniformOnFun.toFun 𝔖 G, ?_, hU⟩
  have hc : ∀ k, ContinuousOn (f k) K := by
    intro k
    rw [Metric.continuousOn_iff]
    intro t ht ε hε
    obtain ⟨δ, hδ, hδ'⟩ := hequi ε hε
    refine ⟨δ, hδ, fun u hu hut => ?_⟩
    rw [Real.dist_eq] at hut ⊢
    exact hδ' k u hu t ht hut
  exact hU.continuousOn (Filter.Frequently.of_forall fun j => hc (φ j))

/-- The working tool: readings decide the whole day. Let φ and ψ be two functions on [a, b]
that share the slope bound K ≥ 0 (|φ(u) − φ(t)| ≤ K |u − t|, and the same for ψ). Let the
readings be a finite set of times in [a, b] spaced so that every time in [a, b] lies within
h/2 of some reading. If φ and ψ differ by at most D at every reading, then they differ by at
most D + K h at every time in [a, b]: the worst gap over the day is at most the worst gap at
the readings plus the slope bound times the spacing. -/
theorem sup_gap_le_reading_gap_add_slope_mul_spacing
    (a b K h D : ℝ) (hK : 0 ≤ K) (φ ψ : ℝ → ℝ)
    (hφ : ∀ u ∈ Set.Icc a b, ∀ t ∈ Set.Icc a b, |φ u - φ t| ≤ K * |u - t|)
    (hψ : ∀ u ∈ Set.Icc a b, ∀ t ∈ Set.Icc a b, |ψ u - ψ t| ≤ K * |u - t|)
    (R : Finset ℝ) (hR : ∀ s ∈ R, s ∈ Set.Icc a b)
    (hcover : ∀ t ∈ Set.Icc a b, ∃ s ∈ R, |t - s| ≤ h / 2)
    (hD : ∀ s ∈ R, |φ s - ψ s| ≤ D) :
    ∀ t ∈ Set.Icc a b, |φ t - ψ t| ≤ D + K * h := by
  intro t ht
  obtain ⟨s, hs, hts⟩ := hcover t ht
  have h1 := hφ t ht s (hR s hs)
  have h2 := hψ s (hR s hs) t ht
  have h3 := hD s hs
  have h4 : K * |t - s| ≤ K * (h / 2) := mul_le_mul_of_nonneg_left hts hK
  rw [abs_sub_comm s t] at h2
  calc |φ t - ψ t| = |(φ t - φ s) + (φ s - ψ s) + (ψ s - ψ t)| := by ring_nf
    _ ≤ |φ t - φ s| + |φ s - ψ s| + |ψ s - ψ t| := abs_add_three _ _ _
    _ ≤ D + K * h := by linarith

/-- The two hypotheses are exactly right. For a set A of functions continuous on [a, b],
every sequence drawn from A has a subsequence converging uniformly on [a, b] exactly when A is
bounded at each point of [a, b] and equicontinuous on [a, b]. -/
theorem every_sequence_has_uniform_subsequence_iff_bounded_equicontinuous
    (a b : ℝ) (A : Set (ℝ → ℝ)) (hcont : ∀ f ∈ A, ContinuousOn f (Set.Icc a b)) :
    (∀ u : ℕ → ℝ → ℝ, (∀ n, u n ∈ A) →
      ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ g : ℝ → ℝ,
        TendstoUniformlyOn (fun j => u (φ j)) g Filter.atTop (Set.Icc a b)) ↔
    ((∀ t ∈ Set.Icc a b, ∃ M : ℝ, ∀ f ∈ A, |f t| ≤ M) ∧
      ∀ ε > 0, ∃ δ > 0, ∀ f ∈ A, ∀ u ∈ Set.Icc a b, ∀ t ∈ Set.Icc a b,
        |u - t| < δ → |f u - f t| < ε) := by
  constructor
  · intro H
    constructor
    · intro t ht
      by_contra hne
      push Not at hne
      choose u huA hu using fun n : ℕ => hne n
      obtain ⟨φ, hφ, g, hg⟩ := H u huA
      rw [Metric.tendstoUniformlyOn_iff] at hg
      obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (hg 1 one_pos)
      let j := N + ⌈|g t|⌉₊ + 1
      have hj := hN j (by omega) t ht
      rw [Real.dist_eq] at hj
      have hφj : (j : ℝ) ≤ (φ j : ℝ) := by exact_mod_cast hφ.id_le j
      have hjg : |g t| + 1 ≤ (j : ℝ) := by
        have := Nat.le_ceil (|g t|)
        simp only [j]
        push_cast
        linarith [(Nat.cast_nonneg N : (0 : ℝ) ≤ N)]
      have h5 := hu (φ j)
      have h6 : |u (φ j) t| ≤ |g t| + |g t - u (φ j) t| := by
        have := abs_sub_abs_le_abs_sub (u (φ j) t) (g t)
        rw [abs_sub_comm (u (φ j) t) (g t)] at this
        linarith
      linarith
    · intro ε hε
      by_contra hne
      push Not at hne
      choose u huA x hx y hy hxy hfxy using
        fun n : ℕ => hne (1 / ((n : ℝ) + 1)) (by positivity)
      obtain ⟨φ, hφ, g, hg⟩ := H u huA
      have hgc : ContinuousOn g (Set.Icc a b) :=
        hg.continuousOn (Filter.Frequently.of_forall fun j => hcont _ (huA _))
      have hgu := isCompact_Icc.uniformContinuousOn_of_continuous hgc
      rw [Metric.uniformContinuousOn_iff] at hgu
      obtain ⟨δ, hδ, hgδ⟩ := hgu (ε / 3) (by positivity)
      rw [Metric.tendstoUniformlyOn_iff] at hg
      obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (hg (ε / 3) (by positivity))
      obtain ⟨m, hm⟩ := exists_nat_one_div_lt hδ
      let j := N + m
      have hj1 := hN j (Nat.le_add_right N m)
      have hφj : m ≤ φ j := le_trans (Nat.le_add_left m N) (hφ.id_le j)
      have hle : 1 / ((φ j : ℝ) + 1) ≤ 1 / ((m : ℝ) + 1) :=
        one_div_le_one_div_of_le (by positivity) (by exact_mod_cast Nat.add_le_add_right hφj 1)
      have hd : dist (x (φ j)) (y (φ j)) < δ := by
        rw [Real.dist_eq]
        linarith [hxy (φ j)]
      have h1 := hgδ _ (hx _) _ (hy _) hd
      have h2 := hj1 _ (hx (φ j))
      have h3 := hj1 _ (hy (φ j))
      rw [Real.dist_eq] at h1 h2 h3
      have h4 := hfxy (φ j)
      rw [abs_lt] at h1 h2 h3
      rcases abs_cases (u (φ j) (x (φ j)) - u (φ j) (y (φ j))) with ⟨h5, _⟩ | ⟨h5, _⟩ <;>
        linarith
  · rintro ⟨hb, he⟩ u hu
    obtain ⟨φ, hφ, g, -, hg⟩ := bounded_equicontinuous_has_uniformly_convergent_subsequence a b u
      (fun t ht => let ⟨M, hM⟩ := hb t ht; ⟨M, fun k => hM _ (hu k)⟩)
      (fun ε hε => let ⟨δ, hδ, h⟩ := he ε hε; ⟨δ, hδ, fun k => h _ (hu k)⟩)
    exact ⟨φ, hφ, g, hg⟩

-- The archive: 100 weather stations times 200 days is 20,000 curves.
example : 100 * 200 = 20000 := by decide
-- Stage 1 reads every 60 minutes over 24 hours: 25 readings; stage 6 reads every 60/32 minutes:
-- 24 × 32 + 1 = 769 readings.
example : 24 * 1 + 1 = 25 ∧ 24 * 2 ^ 5 + 1 = 769 := by decide
-- The diagonal picks #1, #6, #27, #61, #184, #650 increase, so they form a subsequence.
example : 1 < 6 ∧ 6 < 27 ∧ 27 < 61 ∧ 61 < 184 ∧ 184 < 650 := by decide
-- The ball centres #6, #95, #61, #1116, #3844, #2014 go back (95 to 61, 3844 to 2014): not a run.
example : ¬ (95 < 61) ∧ ¬ (3844 < 2014) := by decide
-- Curves kept at stages 1 to 6 shrink: 5,656, 1,414, 363, 94, 29, 15.
example : 15 < 29 ∧ 29 < 94 ∧ 94 < 363 ∧ 363 < 1414 ∧ 1414 < 5656 := by decide
-- The k = 144 sensor 15 + 5 sin(2π · 144 t / 24): every 10-minute reading is a whole number of
-- cycles (144 × 10 = 1,440 minutes per day), so it reads exactly 15 °C there; at 00:02:30
-- (150 seconds) it is a quarter cycle in (144 × 150 × 4 = 86,400 seconds per day), 5 °C off.
example : 144 * 10 = 24 * 60 ∧ 144 * 150 * 4 = 24 * 60 * 60 := by decide

#print axioms bounded_equicontinuous_has_uniformly_convergent_subsequence
#print axioms sup_gap_le_reading_gap_add_slope_mul_spacing
#print axioms every_sequence_has_uniform_subsequence_iff_bounded_equicontinuous
