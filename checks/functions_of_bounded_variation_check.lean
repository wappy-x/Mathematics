-- Bounded variation: a real function on a closed interval has finite total variation exactly when it is one increasing function minus another, such a function has a limit from each side at every point and only countably many jumps, and x sin(1/x) is continuous on [0, 2/π] with infinite variation.
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Topology.EMetricSpace.VariationOnFromTo
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.PSeries
import Mathlib.Tactic.NormNum

open Set Filter Topology

lemma eVariationOn_sub_le_add (g h : ℝ → ℝ) (s : Set ℝ) :
    eVariationOn (fun x => g x - h x) s ≤ eVariationOn g s + eVariationOn h s := by
  apply iSup_le
  rintro ⟨n, u, hu, us⟩
  calc ∑ i ∈ Finset.range n, edist (g (u (i+1)) - h (u (i+1))) (g (u i) - h (u i))
      ≤ ∑ i ∈ Finset.range n,
          (edist (g (u (i+1))) (g (u i)) + edist (h (u (i+1))) (h (u i))) := by
        gcongr with i hi
        rw [edist_dist, edist_dist, edist_dist, ← ENNReal.ofReal_add dist_nonneg dist_nonneg]
        apply ENNReal.ofReal_le_ofReal
        rw [Real.dist_eq, Real.dist_eq, Real.dist_eq]
        calc |g (u (i+1)) - h (u (i+1)) - (g (u i) - h (u i))|
            = |(g (u (i+1)) - g (u i)) - (h (u (i+1)) - h (u i))| := by ring_nf
          _ ≤ |g (u (i+1)) - g (u i)| + |h (u (i+1)) - h (u i)| := abs_sub _ _
    _ = ∑ i ∈ Finset.range n, edist (g (u (i+1))) (g (u i)) +
          ∑ i ∈ Finset.range n, edist (h (u (i+1))) (h (u i)) := Finset.sum_add_distrib
    _ ≤ eVariationOn g s + eVariationOn h s :=
        add_le_add (eVariationOn.sum_le hu us) (eVariationOn.sum_le hu us)

#print axioms eVariationOn_sub_le_add

lemma boundedVariationOn_Icc_of_monotoneOn (g : ℝ → ℝ) (a b : ℝ) (hg : MonotoneOn g (Icc a b)) :
    BoundedVariationOn g (Icc a b) := by
  rcases le_or_gt a b with hab | hab
  · have := hg.locallyBoundedVariationOn a b ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩
    simpa using this
  · rw [Icc_eq_empty (not_le.mpr hab)]
    exact BoundedVariationOn.of_subsingleton subsingleton_empty

#print axioms boundedVariationOn_Icc_of_monotoneOn

lemma x_sin_inv_at_peak (k : ℕ) :
    (fun x : ℝ => x * Real.sin (1 / x)) (1 / (k * Real.pi + Real.pi / 2)) =
      1 / (k * Real.pi + Real.pi / 2) * (-1) ^ k := by
  simp only [one_div_one_div, Real.sin_add_pi_div_two, Real.cos_nat_mul_pi]

#print axioms x_sin_inv_at_peak

/-- Jordan decomposition and its converse. On a closed, bounded interval [a, b], a real function
f has bounded variation (the most any partition can collect by adding the sizes of the changes
of f is finite) exactly when f is the difference g - h of two functions g and h that are
increasing (never going down) on [a, b]. -/
theorem bounded_variation_iff_difference_of_increasing (f : ℝ → ℝ) (a b : ℝ) :
    BoundedVariationOn f (Icc a b) ↔
      ∃ g h : ℝ → ℝ, MonotoneOn g (Icc a b) ∧ MonotoneOn h (Icc a b) ∧
        ∀ x ∈ Icc a b, f x = g x - h x := by
  constructor
  · intro hf
    obtain ⟨p, q, hp, hq, hpq⟩ := hf.locallyBoundedVariationOn.exists_monotoneOn_sub_monotoneOn
    exact ⟨p, q, hp, hq, fun x _ => by rw [hpq]; rfl⟩
  · rintro ⟨g, h, hg, hh, hfgh⟩
    have hcongr : eVariationOn f (Icc a b) = eVariationOn (fun x => g x - h x) (Icc a b) :=
      eVariationOn.eq_of_eqOn hfgh
    unfold BoundedVariationOn
    rw [hcongr]
    refine ne_top_of_le_ne_top ?_ (eVariationOn_sub_le_add g h _)
    exact ENNReal.add_ne_top.mpr ⟨boundedVariationOn_Icc_of_monotoneOn g a b hg,
      boundedVariationOn_Icc_of_monotoneOn h a b hh⟩

/-- One-sided limits and countably many jumps. If f has bounded variation on [a, b], then at
every point x of [a, b] f has a limit from the left (when a < x) and a limit from the right
(when x < b), and the points of [a, b] where f is not continuous (on [a, b]) form a countable
set. -/
theorem bounded_variation_one_sided_limits_and_countable_jumps (f : ℝ → ℝ) (a b : ℝ)
    (hf : BoundedVariationOn f (Icc a b)) :
    (∀ x ∈ Icc a b,
      (a < x → ∃ L : ℝ, Tendsto f (𝓝[<] x) (𝓝 L)) ∧
      (x < b → ∃ L : ℝ, Tendsto f (𝓝[>] x) (𝓝 L))) ∧
    {x | x ∈ Icc a b ∧ ¬ ContinuousWithinAt f (Icc a b) x}.Countable := by
  refine ⟨fun x hx => ⟨fun hax => ?_, fun hxb => ?_⟩, ?_⟩
  · obtain ⟨L, hL⟩ := hf.exists_tendsto_left x
    refine ⟨L, hL.mono_left ?_⟩
    rw [nhdsWithin_le_iff]
    exact mem_of_superset (Ioo_mem_nhdsLT hax)
      (fun y hy => ⟨⟨hy.1.le, hy.2.le.trans hx.2⟩, hy.2⟩)
  · obtain ⟨L, hL⟩ := hf.exists_tendsto_right x
    refine ⟨L, hL.mono_left ?_⟩
    rw [nhdsWithin_le_iff]
    exact mem_of_superset (Ioo_mem_nhdsGT hxb)
      (fun y hy => ⟨⟨hx.1.trans hy.1.le, hy.2.le⟩, hy.1⟩)
  · obtain ⟨p, q, hp, hq, hpq⟩ := hf.locallyBoundedVariationOn.exists_monotoneOn_sub_monotoneOn
    refine (hp.countable_not_continuousWithinAt.union hq.countable_not_continuousWithinAt).mono ?_
    rintro x ⟨hx, hfx⟩
    by_contra hcon
    simp only [mem_union, mem_ofPred_eq, not_or, not_and, not_not] at hcon
    apply hfx
    rw [hpq]
    exact (hcon.1 hx).sub (hcon.2 hx)

/-- Continuity is not enough. The function x sin(1/x), with value 0 at x = 0, is continuous on
[0, 2/π] but does not have bounded variation there. (In Lean 1/0 = 0, so the formula already
gives the value 0 at 0.) -/
theorem x_sin_inv_continuous_without_bounded_variation :
    ContinuousOn (fun x : ℝ => x * Real.sin (1 / x)) (Icc 0 (2 / Real.pi)) ∧
      ¬ BoundedVariationOn (fun x : ℝ => x * Real.sin (1 / x)) (Icc 0 (2 / Real.pi)) := by
  set F : ℝ → ℝ := fun x : ℝ => x * Real.sin (1 / x) with hF
  have hpi := Real.pi_pos
  refine ⟨?_, ?_⟩
  · intro x _
    apply ContinuousAt.continuousWithinAt
    rcases eq_or_ne x 0 with rfl | hx
    · have h0 : F 0 = 0 := by simp [hF]
      show Tendsto F (𝓝 0) (𝓝 (F 0))
      rw [h0]
      apply squeeze_zero_norm (a := fun x : ℝ => ‖x‖)
      · intro y
        simp only [hF, norm_mul]
        exact mul_le_of_le_one_right (norm_nonneg _) (by
          rw [Real.norm_eq_abs]; exact Real.abs_sin_le_one _)
      · simpa using (continuous_norm.tendsto (0 : ℝ))
    · exact ContinuousAt.mul continuousAt_id
        (Real.continuous_sin.continuousAt.comp (continuousAt_const.div continuousAt_id hx))
  · intro hbv
    set φ : ℕ → ℝ := fun k => 1 / (k * Real.pi + Real.pi / 2) with hφ
    have hφpos : ∀ k : ℕ, 0 < φ k := fun k => by simp only [hφ]; positivity
    have hanti : AntitoneOn φ univ := by
      intro i _ j _ hij
      simp only [hφ]
      apply one_div_le_one_div_of_le (by positivity)
      have : (i : ℝ) ≤ j := by exact_mod_cast hij
      nlinarith
    have hmaps : MapsTo φ univ (Icc 0 (2 / Real.pi)) := by
      intro k _
      refine ⟨(hφpos k).le, ?_⟩
      simp only [hφ]
      rw [div_le_div_iff₀ (by positivity) hpi]
      have : (0 : ℝ) ≤ k := Nat.cast_nonneg k
      nlinarith
    have hle := eVariationOn.comp_le_of_antitoneOn F φ hanti hmaps
    have hterm : ∀ i : ℕ, 1 / Real.pi * (1 / ((i : ℝ) + 1)) ≤ dist (F (φ (i+1))) (F (φ i)) := by
      intro i
      have e1 : F (1 / (((i+1 : ℕ) : ℝ) * Real.pi + Real.pi / 2)) =
          1 / (((i+1 : ℕ) : ℝ) * Real.pi + Real.pi / 2) * (-1) ^ (i+1) := x_sin_inv_at_peak (i+1)
      have e0 : F (1 / ((i : ℝ) * Real.pi + Real.pi / 2)) =
          1 / ((i : ℝ) * Real.pi + Real.pi / 2) * (-1) ^ i := x_sin_inv_at_peak i
      rw [Real.dist_eq, show φ (i+1) = 1 / (((i+1 : ℕ) : ℝ) * Real.pi + Real.pi / 2) from rfl,
        show φ i = 1 / ((i : ℝ) * Real.pi + Real.pi / 2) from rfl, e1, e0]
      have hA : 0 < 1 / (((i+1 : ℕ) : ℝ) * Real.pi + Real.pi / 2) := hφpos (i+1)
      have hB : 0 < 1 / ((i : ℝ) * Real.pi + Real.pi / 2) := hφpos i
      rw [show 1 / (((i+1 : ℕ) : ℝ) * Real.pi + Real.pi / 2) * (-1) ^ (i+1) -
          1 / ((i : ℝ) * Real.pi + Real.pi / 2) * (-1) ^ i =
          (-1) ^ (i+1) * (1 / (((i+1 : ℕ) : ℝ) * Real.pi + Real.pi / 2) +
            1 / ((i : ℝ) * Real.pi + Real.pi / 2)) by ring]
      rw [abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul, abs_of_pos (by positivity)]
      have : 1 / Real.pi * (1 / ((i : ℝ) + 1)) ≤ 1 / ((i : ℝ) * Real.pi + Real.pi / 2) := by
        rw [div_mul_div_comm, one_mul]
        apply one_div_le_one_div_of_le (by positivity)
        nlinarith
      linarith
    have hfin : eVariationOn (F ∘ φ) univ ≠ ⊤ := ne_top_of_le_ne_top hbv hle
    have hbound : ∀ n : ℕ, 1 / Real.pi * ∑ i ∈ Finset.range n, (1 / ((i : ℝ) + 1)) ≤
        (eVariationOn (F ∘ φ) univ).toReal := by
      intro n
      have hs := eVariationOn.sum_le (f := F ∘ φ) (s := univ) (n := n) (u := id) monotone_id
        (fun _ => mem_univ _)
      simp only [Function.comp, id] at hs
      rw [Finset.mul_sum]
      refine le_trans (b := ∑ i ∈ Finset.range n, dist (F (φ (i+1))) (F (φ i))) ?_
        ((ENNReal.ofReal_le_iff_le_toReal hfin).mp ?_)
      · exact Finset.sum_le_sum (fun i _ => hterm i)
      · refine le_trans (le_of_eq ?_) hs
        rw [ENNReal.ofReal_sum_of_nonneg (fun i _ => dist_nonneg)]
        exact Finset.sum_congr rfl (fun i _ => (edist_dist _ _).symm)
    have htend := Real.tendsto_sum_range_one_div_nat_succ_atTop
    obtain ⟨n, hn⟩ := (htend.eventually_gt_atTop
      (Real.pi * (eVariationOn (F ∘ φ) univ).toReal)).exists
    have := hbound n
    rw [div_mul_eq_mul_div, one_mul, div_le_iff₀ hpi] at this
    linarith

-- The trail, elevations in metres at km 0, 4, 6, 10, 12: 1000, 1600, 1300, 1600, 1200.
-- Total variation through the turning points: 600 + 300 + 300 + 400 = 1600.
example : |(1600 : ℤ) - 1000| + |(1300 : ℤ) - 1600| + |(1600 : ℤ) - 1300| +
    |(1200 : ℤ) - 1600| = 1600 := by norm_num
-- Climb P(12) = 600 + 300 = 900, descent N(12) = 300 + 400 = 700.
-- P - N is the net change 1200 - 1000 = 200, and P + N is the variation 1600.
example : (600 : ℤ) + 300 = 900 ∧ (300 : ℤ) + 400 = 700 ∧
    (900 : ℤ) - 700 = 1200 - 1000 ∧ (900 : ℤ) + 700 = 1600 := by norm_num
-- At km 5 (1450 m): P = 600, N = 150, P - N = 450 = 1450 - 1000.
example : (600 : ℤ) - 150 = 1450 - 1000 := by norm_num
-- Refining the partition {0, 12}: it collects 200; adding km 6 gives 300 + 100 = 400.
example : |(1200 : ℤ) - 1000| = 200 ∧ |(1300 : ℤ) - 1000| + |(1200 : ℤ) - 1300| = 400 := by
  norm_num
-- Equal pieces. n = 3 (km 0, 4, 8, 12; elevations 1000, 1600, 1450, 1200) collects 1000.
example : |(1600 : ℤ) - 1000| + |(1450 : ℤ) - 1600| + |(1200 : ℤ) - 1450| = 1000 := by norm_num
-- n = 4 (km 0, 3, 6, 9, 12; elevations 1000, 1450, 1300, 1525, 1200) collects 1150.
example : |(1450 : ℤ) - 1000| + |(1300 : ℤ) - 1450| + |(1525 : ℤ) - 1300| +
    |(1200 : ℤ) - 1525| = 1150 := by norm_num
-- n = 5 (every 2.4 km; elevations 1000, 1360, 1480, 1390, 1570, 1200) collects 1120.
example : |(1360 : ℤ) - 1000| + |(1480 : ℤ) - 1360| + |(1390 : ℤ) - 1480| +
    |(1570 : ℤ) - 1390| + |(1200 : ℤ) - 1570| = 1120 := by norm_num
-- n = 6 (every 2 km; elevations 1000, 1300, 1600, 1450, 1300, 1600, 1200) collects 1600.
example : |(1300 : ℤ) - 1000| + |(1600 : ℤ) - 1300| + |(1450 : ℤ) - 1600| +
    |(1300 : ℤ) - 1450| + |(1600 : ℤ) - 1300| + |(1200 : ℤ) - 1600| = 1600 := by norm_num
-- The 50 m ladder at km 8 adds its height: variation 1650, climb 950.
example : (1600 : ℤ) + 50 = 1650 ∧ (900 : ℤ) + 50 = 950 := by norm_num
-- Lipschitz cap: 200 m per km over 12 km is 2400 m, above the true 1600 m.
example : (200 : ℤ) * 12 = 2400 ∧ (1600 : ℤ) ≤ 2400 := by norm_num

#print axioms bounded_variation_iff_difference_of_increasing
#print axioms bounded_variation_one_sided_limits_and_countable_jumps
#print axioms x_sin_inv_continuous_without_bounded_variation
