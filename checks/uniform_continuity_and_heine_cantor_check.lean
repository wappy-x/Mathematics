-- Uniform continuity: on a compact metric space every continuous real function has one input tolerance that works at every point, resting on the Lebesgue number lemma, and a Lipschitz constant K hands over that tolerance as the output tolerance divided by K.
import Mathlib.Topology.MetricSpace.Pseudo.Lemmas
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum

/-- Heine–Cantor. If the metric space X is compact and f, from X to the real numbers, is
continuous at every point, then f is uniformly continuous: for every output tolerance ε above
zero, one input tolerance δ above zero works at every point, so any two points closer than δ
have values closer than ε. -/
theorem heine_cantor_compact_continuous_is_uniformly_continuous
    {X : Type*} [MetricSpace X] [CompactSpace X] (f : X → ℝ)
    (hf : ∀ p, ContinuousAt f p) :
    ∀ ε > 0, ∃ δ > 0, ∀ p q : X, dist p q < δ → |f p - f q| < ε := by
  have hu := CompactSpace.uniformContinuous_of_continuous (continuous_iff_continuousAt.mpr hf)
  intro ε hε
  obtain ⟨δ, hδ, h⟩ := Metric.uniformContinuous_iff.mp hu ε hε
  exact ⟨δ, hδ, fun p q hpq => by simpa [Real.dist_eq] using h hpq⟩

/-- The Lebesgue number lemma. In a compact metric space, every cover by open sets has a
Lebesgue number: one radius above zero such that every ball of that radius lies inside a single
set of the cover. -/
theorem lebesgue_number_lemma_compact_metric
    {X : Type*} [MetricSpace X] [CompactSpace X] {ι : Type*} (U : ι → Set X)
    (hU : ∀ i, IsOpen (U i)) (hcover : ⋃ i, U i = Set.univ) :
    ∃ lam > 0, ∀ p : X, ∃ i, Metric.ball p lam ⊆ U i := by
  obtain ⟨δ, hδ, h⟩ := lebesgue_number_lemma_of_metric (s := Set.univ) isCompact_univ hU
    (by rw [hcover])
  exact ⟨δ, hδ, fun p => h p (Set.mem_univ p)⟩

/-- A Lipschitz constant gives the tolerance outright. If |f(p) − f(q)| ≤ K d(p, q) for all
p and q, with K above zero, then δ = ε / K works for every output tolerance ε above zero. -/
theorem lipschitz_constant_gives_tolerance
    {X : Type*} [MetricSpace X] (f : X → ℝ) (K : ℝ) (hK : 0 < K)
    (hf : ∀ p q : X, |f p - f q| ≤ K * dist p q) :
    ∀ ε > 0, ∀ p q : X, dist p q < ε / K → |f p - f q| < ε := by
  intro ε hε p q hpq
  calc |f p - f q| ≤ K * dist p q := hf p q
    _ < K * (ε / K) := by gcongr
    _ = ε := by field_simp

-- The floor's Lipschitz constant: 6 × 2 / 36 = 1/3 degree C per metre walked.
example : (6 : ℚ) * 2 / 36 = 1 / 3 := by norm_num
-- Lipschitz tolerance: 0.5 / (1/3) = 1.5 m.
example : (1 / 2 : ℚ) / (1 / 3) = 3 / 2 := by norm_num
-- Radiator against a desk 1.5 m away: 6 × (1 − (34.5/36)²) = 47/96 degree C, inside 0.5.
example : (6 : ℚ) * (1 - (69 / 72) ^ 2) = 47 / 96 ∧ (47 / 96 : ℚ) < 1 / 2 := by norm_num
-- The best tolerance 36(1 − √(11/12)) is above 1.5 m, since √(11/12) < 23/24: 11/12 < (23/24)².
example : (11 / 12 : ℚ) < (23 / 24) ^ 2 := by norm_num
-- Three heating zones in centimetres, [0, 900), (700, 1700), (1500, 2400]: overlaps of 200 cm,
-- so the Lebesgue number is half an overlap, 100 cm.
example : min (900 - 700) (1700 - 1500) / 2 = (100 : ℕ) := by decide
-- The torn test field: 22 degrees C east of the gap against 18 west, a 4 degree C jump.
example : (22 : ℤ) - 18 = 4 := by decide

#print axioms heine_cantor_compact_continuous_is_uniformly_continuous
#print axioms lebesgue_number_lemma_compact_metric
#print axioms lipschitz_constant_gives_tolerance
