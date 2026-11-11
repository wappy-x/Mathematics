-- Uniform continuity: a function continuous on a closed, bounded interval is uniformly continuous there, a Lipschitz bound K gives the tolerance ε / K directly, and neither step reverses (the square root, squaring on the whole line).
import Mathlib.Topology.UniformSpace.HeineCantor
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

/-- Heine–Cantor: a function continuous at every point of a closed, bounded interval `[a, b]`
is uniformly continuous on it. For every output tolerance there is one input tolerance that
works for every pair of inputs in the interval, wherever they sit. -/
theorem continuous_on_closed_interval_is_uniformly_continuous (f : ℝ → ℝ) (a b : ℝ)
    (hf : ContinuousOn f (Set.Icc a b)) :
    UniformContinuousOn f (Set.Icc a b) := by
  exact isCompact_Icc.uniformContinuousOn_of_continuous hf

/-- The Lipschitz shortcut: if no two inputs in a set have outputs further apart than `K` times
their own distance, the function is uniformly continuous on the set, and the input tolerance
`ε / K` works for the output tolerance `ε`: inputs closer than `ε / K` have outputs closer
than `ε`, wherever they sit. -/
theorem lipschitz_tolerance_is_output_tolerance_over_K (f : ℝ → ℝ) (s : Set ℝ) (K : ℝ)
    (hK : ∀ x ∈ s, ∀ y ∈ s, |f x - f y| ≤ K * |x - y|) :
    UniformContinuousOn f s ∧
      ∀ ε > 0, ∀ x ∈ s, ∀ y ∈ s, |x - y| < ε / K → |f x - f y| < ε := by
  refine ⟨?_, ?_⟩
  · rw [Metric.uniformContinuousOn_iff]
    intro ε hε
    refine ⟨ε / (|K| + 1), by positivity, ?_⟩
    intro x hx y hy hxy
    rw [Real.dist_eq] at hxy ⊢
    have h1 := hK x hx y hy
    have hpos : (0 : ℝ) < |K| + 1 := by positivity
    have h2 : K * |x - y| ≤ |K| * |x - y| :=
      mul_le_mul_of_nonneg_right (le_abs_self K) (abs_nonneg _)
    have h3 : |x - y| * (|K| + 1) < ε := (lt_div_iff₀ hpos).mp hxy
    have h4 : 0 ≤ |K| := abs_nonneg K
    have h5 : 0 ≤ |x - y| := abs_nonneg _
    nlinarith
  · intro ε hε x hx y hy hxy
    have h1 := hK x hx y hy
    rcases lt_trichotomy K 0 with hKn | hK0 | hKp
    · have : ε / K < 0 := div_neg_of_pos_of_neg hε hKn
      linarith [abs_nonneg (x - y)]
    · subst hK0
      simp at hxy
      linarith [abs_nonneg (x - y)]
    · have h3 : |x - y| * K < ε := (lt_div_iff₀ hKp).mp hxy
      linarith

/-- Neither arrow reverses. The square root on `[0, 1]` is uniformly continuous, yet no
Lipschitz constant `K` fits it; squaring on the whole line is continuous, yet not uniformly
continuous. -/
theorem neither_arrow_reverses :
    (UniformContinuousOn Real.sqrt (Set.Icc 0 1) ∧
      ¬ ∃ K : ℝ, ∀ x ∈ Set.Icc (0 : ℝ) 1, ∀ y ∈ Set.Icc (0 : ℝ) 1,
          |Real.sqrt x - Real.sqrt y| ≤ K * |x - y|) ∧
    (Continuous (fun x : ℝ => x ^ 2) ∧ ¬ UniformContinuous (fun x : ℝ => x ^ 2)) := by
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩⟩
  · exact isCompact_Icc.uniformContinuousOn_of_continuous Real.continuous_sqrt.continuousOn
  · rintro ⟨K, hK⟩
    set t : ℝ := 1 / (|K| + 2) with ht
    have hKa : 0 ≤ |K| := abs_nonneg K
    have htpos : 0 < t := by positivity
    have htle : t ≤ 1 := by
      rw [ht, div_le_one (by positivity)]
      linarith
    have hmem : t ^ 2 ∈ Set.Icc (0 : ℝ) 1 :=
      ⟨by positivity, by nlinarith⟩
    have h0 : (0 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := ⟨le_refl _, zero_le_one⟩
    have h := hK (t ^ 2) hmem 0 h0
    rw [Real.sqrt_sq htpos.le, Real.sqrt_zero, sub_zero, sub_zero,
      abs_of_pos htpos, abs_of_pos (by positivity)] at h
    have hKt : t * (|K| + 2) = 1 := by
      rw [ht]; field_simp
    have hK' : K ≤ |K| := le_abs_self K
    -- t ≤ K t², so 1 ≤ K t ≤ |K| t < (|K| + 2) t = 1
    have : 1 ≤ K * t := by
      have := (div_le_div_iff_of_pos_right htpos).mpr h
      rw [div_self htpos.ne'] at this
      calc (1 : ℝ) ≤ K * t ^ 2 / t := this
        _ = K * t := by field_simp
    nlinarith
  · exact continuous_pow 2
  · intro hU
    rw [Metric.uniformContinuous_iff] at hU
    obtain ⟨δ, hδ, hδU⟩ := hU 1 one_pos
    have h := @hδU (1 / δ + δ / 2) (1 / δ) (by
      rw [Real.dist_eq]
      have : 1 / δ + δ / 2 - 1 / δ = δ / 2 := by ring
      rw [this, abs_of_pos (by positivity)]
      linarith)
    rw [Real.dist_eq] at h
    have he : (1 / δ + δ / 2) ^ 2 - (1 / δ) ^ 2 = 1 + δ ^ 2 / 4 := by
      field_simp
      ring
    rw [he, abs_of_pos (by positivity)] at h
    have : 0 < δ ^ 2 / 4 := by positivity
    linarith

-- Worked numbers, by hand. Lengths in metres, areas in square metres.
-- Lipschitz tolerance for the tiles: 0.01 / 4 = 0.0025 m.
example : (1 / 100 : ℚ) / 4 = 1 / 400 := by norm_num
-- Factoring on sides up to 2 m: x + y is at most 2 + 2 = 4.
example : (2 : ℚ) + 2 = 4 := by norm_num
-- Worst pair, 1.9975 m and 2 m: area gap 2 × 2 − 1.9975 × 1.9975 = 0.00999375, inside 0.01.
example : (2 : ℚ) * 2 - (799 / 400) * (799 / 400) = 1599 / 160000 ∧
    (1599 / 160000 : ℚ) < 1 / 100 := by norm_num
-- Whole line, tolerance 0.0025: sides 400 and 400.00125, area gap 1 + 0.0025² / 4 = 1.00000156…
example : (400 + 1 / 800 : ℚ) ^ 2 - 400 ^ 2 = 1 + (1 / 400) ^ 2 / 4 := by norm_num
-- The algebra behind it: (1/h + h/2)² − (1/h)² = 1 + h²/4 for every nonzero h.
example (h : ℚ) (hh : h ≠ 0) : (1 / h + h / 2) ^ 2 - (1 / h) ^ 2 = 1 + h ^ 2 / 4 := by
  field_simp
  ring
-- Open end: 1/x at 1/100 and 1/101, inputs 1/10100 apart, outputs exactly 1 apart.
example : (1 / 100 : ℚ) - 1 / 101 = 1 / 10100 ∧ 1 / (1 / 101 : ℚ) - 1 / (1 / 100) = 1 := by
  norm_num
-- Square root against K = 4: inputs 0 and 1/25 = (1/5)², outputs 0 and 1/5, steepness 5.
example : ((1 : ℚ) / 5) ^ 2 = 1 / 25 ∧ (1 / 5 : ℚ) / (1 / 25) = 5 := by norm_num
-- Try: sides up to 3 m give K = 6 and tolerance 0.01 / 6; area tolerance 0.001 gives 0.00025 m.
example : (2 : ℚ) * 3 = 6 ∧ (1 / 1000 : ℚ) / 4 = 1 / 4000 := by norm_num

#print axioms continuous_on_closed_interval_is_uniformly_continuous
#print axioms lipschitz_tolerance_is_output_tolerance_over_K
#print axioms neither_arrow_reverses
