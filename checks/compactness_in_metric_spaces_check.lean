-- Compactness three ways: in a metric space the cover test, the sequence test, and "complete and totally bounded" agree, and in ℝⁿ they mean closed and bounded.
import Mathlib.Topology.Compactness.Compact
import Mathlib.Topology.Sequences
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Topology.MetricSpace.ProperSpace
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum

open Filter Topology Metric

universe u

/-- In any metric space, a set `K` passes the cover test (every open cover, by a family of
any size, has a finite subcover) exactly when it passes the sequence test (every list in `K`
has a subsequence converging to a point of `K`), and the sequence test holds exactly when `K`
is complete (every Cauchy list in `K` converges to a point of `K`) and totally bounded (for
every radius `ε > 0`, finitely many balls of radius `ε` cover `K`). -/
theorem compact_cover_iff_seq_iff_complete_totally_bounded
    {X : Type u} [MetricSpace X] (K : Set X) :
    ((∀ (ι : Type u) (U : ι → Set X), (∀ i, IsOpen (U i)) → K ⊆ ⋃ i, U i →
        ∃ t : Finset ι, K ⊆ ⋃ i ∈ t, U i) ↔
      (∀ x : ℕ → X, (∀ k, x k ∈ K) →
        ∃ p ∈ K, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 p))) ∧
    ((∀ x : ℕ → X, (∀ k, x k ∈ K) →
        ∃ p ∈ K, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 p)) ↔
      ((∀ x : ℕ → X, (∀ k, x k ∈ K) → CauchySeq x → ∃ p ∈ K, Tendsto x atTop (𝓝 p)) ∧
        (∀ ε > 0, ∃ c : Finset X, K ⊆ ⋃ y ∈ c, ball y ε))) := by
  have hcov : IsCompact K ↔ (∀ (ι : Type u) (U : ι → Set X), (∀ i, IsOpen (U i)) →
      K ⊆ ⋃ i, U i → ∃ t : Finset ι, K ⊆ ⋃ i ∈ t, U i) := by
    rw [isCompact_iff_finite_subcover]
  have hsc : IsSeqCompact K ↔ (∀ x : ℕ → X, (∀ k, x k ∈ K) →
      ∃ p ∈ K, ∃ φ : ℕ → ℕ, StrictMono φ ∧ Tendsto (x ∘ φ) atTop (𝓝 p)) :=
    ⟨fun h x hx => h hx, fun h x hx => h x hx⟩
  have htb : TotallyBounded K ↔ (∀ ε > 0, ∃ c : Finset X, K ⊆ ⋃ y ∈ c, ball y ε) := by
    rw [Metric.totallyBounded_iff]
    constructor
    · intro h ε hε
      obtain ⟨t, ht, hK⟩ := h ε hε
      refine ⟨ht.toFinset, ?_⟩
      simpa using hK
    · intro h ε hε
      obtain ⟨c, hc⟩ := h ε hε
      exact ⟨c, c.finite_toSet, by simpa using hc⟩
  have hcomp : IsComplete K ↔
      (∀ x : ℕ → X, (∀ k, x k ∈ K) → CauchySeq x → ∃ p ∈ K, Tendsto x atTop (𝓝 p)) := by
    constructor
    · intro h x hx hc
      have hle : map x atTop ≤ 𝓟 K := by
        rw [le_principal_iff]
        exact Filter.mem_map.2 (Filter.Eventually.of_forall (f := atTop) hx)
      obtain ⟨p, hp, hlim⟩ := h _ hc hle
      exact ⟨p, hp, hlim⟩
    · intro h
      rw [← completeSpace_coe_iff_isComplete]
      apply UniformSpace.complete_of_cauchySeq_tendsto
      intro u hu
      have hu' : CauchySeq (fun n => (u n : X)) :=
        uniformContinuous_subtype_val.comp_cauchySeq hu
      obtain ⟨p, hp, hlim⟩ := h _ (fun k => (u k).2) hu'
      refine ⟨⟨p, hp⟩, ?_⟩
      rw [tendsto_subtype_rng]
      exact hlim
  rw [← hcov, ← hsc, ← hcomp, ← htb, ← isCompact_iff_isSeqCompact,
    isCompact_iff_totallyBounded_isComplete]
  exact ⟨Iff.rfl, and_comm⟩

/-- Heine–Borel in `n` dimensions: a set of points with `n` real coordinates, under
straight-line distance, is compact exactly when it is closed and bounded. -/
theorem heine_borel_closed_and_bounded (n : ℕ) (K : Set (EuclideanSpace ℝ (Fin n))) :
    IsCompact K ↔ IsClosed K ∧ Bornology.IsBounded K := by
  exact Metric.isCompact_iff_isClosed_bounded

/-- Outside coordinate space, closed and bounded is not enough: some metric space holds a
set that is closed and bounded but not compact. -/
theorem closed_bounded_not_compact_somewhere :
    ∃ (X : Type) (_ : MetricSpace X) (K : Set X),
      IsClosed K ∧ Bornology.IsBounded K ∧ ¬ IsCompact K := by
  refine ⟨{x : ℝ // x ∈ Set.Ioo (0 : ℝ) 1}, inferInstance, Set.univ, isClosed_univ, ?_, ?_⟩
  · refine Metric.isBounded_iff.2 ⟨1, fun x _ y _ => ?_⟩
    rw [Subtype.dist_eq, Real.dist_eq, abs_le]
    obtain ⟨hx0, hx1⟩ := x.2
    obtain ⟨hy0, hy1⟩ := y.2
    constructor <;> linarith
  · intro hK
    have h1 : IsCompact (Subtype.val '' (Set.univ : Set {x : ℝ // x ∈ Set.Ioo (0 : ℝ) 1})) :=
      hK.image continuous_subtype_val
    rw [Set.image_univ, Subtype.range_coe] at h1
    have h2 := h1.isClosed.closure_eq
    rw [closure_Ioo (zero_ne_one)] at h2
    have h3 : (1 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := ⟨zero_le_one, le_refl 1⟩
    rw [h2] at h3
    exact lt_irrefl _ h3.2

-- The plot: 40 m by 30 m, diagonal 50 m; 70 m to walk corner to corner.
example : (30 : ℕ) ^ 2 + 40 ^ 2 = 50 ^ 2 := by norm_num
example : (40 : ℕ) + 30 = 70 := by norm_num
-- Square nets of radius 10 m, 5 m and 1 m: 12, 48 and 1200 balls.
example : (40 / 10 : ℕ) * (30 / 10) = 12 := by norm_num
example : (40 / 5 : ℕ) * (30 / 5) = 48 := by norm_num
example : (40 : ℕ) * 30 = 1200 := by norm_num
-- Pigeonhole: 49 stakes in 48 squares, so two share one.
example : (48 : ℕ) < 49 := by norm_num
-- Test points every 0.25 m, fence included: 161 by 121.
example : (4000 / 25 + 1 : ℕ) * (3000 / 25 + 1) = 19481 := by norm_num
-- Quartering in the plane: 2^n = 4 pieces per cut; level-6 diagonal 50/2^6 = 25/32 m.
example : (2 : ℕ) ^ 2 = 4 := by norm_num
example : (50 : ℚ) / 2 ^ 6 = 25 / 32 := by norm_num
-- Open fence (0, 40): U_10 reaches down to 40/2^10 = 5/128 m; stake 11 sits at 5/256 m.
example : (40 : ℚ) / 2 ^ 10 = 5 / 128 := by norm_num
example : (40 : ℚ) / 2 ^ 11 = 5 / 256 := by norm_num
example : (5 : ℚ) / 256 < 5 / 128 := by norm_num
-- Nonempty subfamilies of U_1, ..., U_10: 2^10 - 1 = 1023.
example : (2 : ℕ) ^ 10 - 1 = 1023 := by norm_num
-- Hub: two street ends are 100 + 100 = 200 m apart.
example : (100 : ℕ) + 100 = 200 := by norm_num
-- One-point cover of the whole-centimetre points: 4001 by 3001.
example : (4000 + 1 : ℕ) * (3000 + 1) = 12007001 := by norm_num

#print axioms compact_cover_iff_seq_iff_complete_totally_bounded
#print axioms heine_borel_closed_and_bounded
#print axioms closed_bounded_not_compact_somewhere
