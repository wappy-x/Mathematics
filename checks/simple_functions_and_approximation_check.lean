-- Simple functions: the dyadic staircases of a non-negative measurable function are simple, rise, stay below it, come within 1/2^n wherever it is at most n, and converge to it at every point.
import Mathlib.MeasureTheory.Function.SimpleFunc
import Mathlib.Topology.Instances.ENNReal.Lemmas
import Mathlib.MeasureTheory.Function.Floor
import Mathlib.MeasureTheory.Constructions.BorelSpace.Metrizable

open MeasureTheory Filter Topology
open scoped ENNReal NNReal

/-- The card's stage-`n` staircase of a value `x` in `[0, ∞]`: multiply by `2^n`, round down to a
whole number, divide back, and never go above `n`; at `x = ∞` it is `n`. -/
noncomputable def staircase (n : ℕ) (x : ℝ≥0∞) : ℝ≥0∞ :=
  if x = ∞ then (n : ℝ≥0∞)
  else ((min (n : ℝ≥0) ((⌊(2 : ℝ≥0) ^ n * x.toNNReal⌋₊ : ℝ≥0) / 2 ^ n) : ℝ≥0) : ℝ≥0∞)

lemma staircase_measurable (n : ℕ) : Measurable (staircase n) := by
  unfold staircase
  refine Measurable.ite (measurableSet_singleton _) measurable_const ?_
  refine measurable_coe_nnreal_ennreal.comp ?_
  refine measurable_const.min ?_
  refine Measurable.div_const ?_ _
  refine Measurable.comp (measurable_from_nat (f := (Nat.cast : ℕ → ℝ≥0))) ?_
  exact (measurable_const.mul ENNReal.measurable_toNNReal).nat_floor

lemma staircase_finite_range (n : ℕ) : (Set.range (staircase n)).Finite := by
  let g : ℕ → ℝ≥0∞ := fun k => ((min (n : ℝ≥0) ((k : ℝ≥0) / 2 ^ n) : ℝ≥0) : ℝ≥0∞)
  have hsub : Set.range (staircase n) ⊆ insert (n : ℝ≥0∞) (g '' Set.Iic (n * 2 ^ n)) := by
    rintro _ ⟨x, rfl⟩
    unfold staircase
    split_ifs with hx
    · exact Set.mem_insert _ _
    · right
      set k := ⌊(2 : ℝ≥0) ^ n * x.toNNReal⌋₊
      by_cases hk : k ≤ n * 2 ^ n
      · exact ⟨k, hk, rfl⟩
      · refine ⟨n * 2 ^ n, Set.mem_Iic.mpr le_rfl, ?_⟩
        simp only [g]
        have h1 : (n : ℝ≥0) ≤ (k : ℝ≥0) / 2 ^ n := by
          rw [le_div_iff₀ (by positivity)]
          exact_mod_cast (le_of_lt (not_le.mp hk))
        have h2 : ((n * 2 ^ n : ℕ) : ℝ≥0) / 2 ^ n = n := by
          push_cast
          field_simp
        rw [h2, min_eq_left h1, min_self]
  exact ((Set.finite_Iic _).image g |>.insert _).subset hsub

lemma staircase_mono (n : ℕ) (x : ℝ≥0∞) : staircase n x ≤ staircase (n + 1) x := by
  unfold staircase
  split_ifs with hx
  · exact_mod_cast Nat.le_succ n
  · refine ENNReal.coe_le_coe.mpr (min_le_min (by exact_mod_cast Nat.le_succ n) ?_)
    set y := x.toNNReal
    rw [div_le_div_iff₀ (by positivity) (by positivity)]
    have : 2 * ⌊(2 : ℝ≥0) ^ n * y⌋₊ ≤ ⌊(2 : ℝ≥0) ^ (n + 1) * y⌋₊ := by
      apply Nat.le_floor
      push_cast
      rw [pow_succ]
      have := Nat.floor_le (a := (2 : ℝ≥0) ^ n * y) (by positivity)
      calc 2 * (⌊(2 : ℝ≥0) ^ n * y⌋₊ : ℝ≥0) ≤ 2 * (2 ^ n * y) := by gcongr
        _ = 2 ^ n * 2 * y := by ring
    calc (⌊(2 : ℝ≥0) ^ n * y⌋₊ : ℝ≥0) * 2 ^ (n + 1)
        = ((2 * ⌊(2 : ℝ≥0) ^ n * y⌋₊ : ℕ) : ℝ≥0) * 2 ^ n := by push_cast; ring
      _ ≤ (⌊(2 : ℝ≥0) ^ (n + 1) * y⌋₊ : ℝ≥0) * 2 ^ n := by gcongr

lemma staircase_le (n : ℕ) (x : ℝ≥0∞) : staircase n x ≤ x := by
  unfold staircase
  split_ifs with hx
  · rw [hx]; exact le_top
  · rw [← ENNReal.coe_toNNReal hx]
    refine ENNReal.coe_le_coe.mpr ((min_le_right _ _).trans ?_)
    rw [div_le_iff₀ (by positivity), mul_comm]
    exact Nat.floor_le (by positivity)

lemma staircase_close (n : ℕ) (x : ℝ≥0∞) (hx : x ≤ n) : x - staircase n x < (2 ^ n)⁻¹ := by
  have hxt : x ≠ ∞ := ne_top_of_le_ne_top (ENNReal.natCast_ne_top n) hx
  set y := x.toNNReal with hy
  have hxy : x = (y : ℝ≥0∞) := (ENNReal.coe_toNNReal hxt).symm
  have hyn : y ≤ n := by
    rw [hxy] at hx; exact_mod_cast hx
  have hfl : ((⌊(2 : ℝ≥0) ^ n * y⌋₊ : ℝ≥0) / 2 ^ n) ≤ y := by
    rw [div_le_iff₀ (by positivity), mul_comm]
    exact Nat.floor_le (by positivity)
  have hs : staircase n x = (((⌊(2 : ℝ≥0) ^ n * y⌋₊ : ℝ≥0) / 2 ^ n : ℝ≥0) : ℝ≥0∞) := by
    unfold staircase
    simp only [hxt, ↓reduceIte]
    rw [min_eq_right (hfl.trans hyn)]
  rw [hs, hxy, ENNReal.sub_lt_iff_lt_right ENNReal.coe_ne_top (ENNReal.coe_le_coe.mpr hfl)]
  have h2 : ((2 : ℝ≥0∞) ^ n)⁻¹ = (((2 : ℝ≥0) ^ n)⁻¹ : ℝ≥0) := by
    rw [ENNReal.coe_inv (by positivity)]; push_cast; rfl
  rw [h2, ← ENNReal.coe_add, ENNReal.coe_lt_coe]
  have hlt := Nat.lt_floor_add_one ((2 : ℝ≥0) ^ n * y)
  have hpos : (0 : ℝ≥0) < 2 ^ n := by positivity
  rw [add_comm, div_add' _ _ _ hpos.ne', lt_div_iff₀ hpos]
  calc y * 2 ^ n = 2 ^ n * y := mul_comm _ _
    _ < _ := by simpa using hlt

lemma staircase_tendsto (x : ℝ≥0∞) : Tendsto (fun n => staircase n x) atTop (𝓝 x) := by
  by_cases hx : x = ∞
  · subst hx
    simpa [staircase] using ENNReal.tendsto_nat_nhds_top
  · obtain ⟨N, hN⟩ := ENNReal.exists_nat_gt hx
    have hlow : Tendsto (fun n : ℕ => x - ((2 : ℝ≥0∞) ^ n)⁻¹) atTop (𝓝 x) := by
      have h0 : Tendsto (fun n : ℕ => ((2 : ℝ≥0∞) ^ n)⁻¹) atTop (𝓝 0) := by
        have : (fun n : ℕ => ((2 : ℝ≥0∞) ^ n)⁻¹) = fun n : ℕ => (2 : ℝ≥0∞)⁻¹ ^ n := by
          funext n; exact ENNReal.inv_pow
        rw [this]
        exact ENNReal.tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num)
      simpa using ENNReal.Tendsto.sub tendsto_const_nhds h0 (Or.inl hx)
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlow tendsto_const_nhds ?_
      (Eventually.of_forall fun n => staircase_le n x)
    filter_upwards [eventually_ge_atTop N] with n hn
    have hxn : x ≤ n := hN.le.trans (by exact_mod_cast hn)
    have := (staircase_close n x hxn).le
    rw [tsub_le_iff_right] at this ⊢
    rw [add_comm]; exact this

#print axioms staircase_measurable
#print axioms staircase_finite_range
#print axioms staircase_mono
#print axioms staircase_le
#print axioms staircase_close
#print axioms staircase_tendsto

/-- For every measurable `f` from a set with a sigma-algebra to `[0, ∞]`, the stage-`n`
staircases `s_n = min(n, 2^-n ⌊2^n f⌋)` are simple functions, never fall as `n` grows, never pass
`f`, are less than `2^-n` below `f` wherever `f ≤ n`, and converge to `f` at every point. -/
theorem staircase_approximation {Ω : Type*} [MeasurableSpace Ω] (f : Ω → ℝ≥0∞)
    (hf : Measurable f) :
    (∀ n : ℕ, ∃ s : SimpleFunc Ω ℝ≥0∞, ⇑s = fun ω => staircase n (f ω)) ∧
    (∀ n : ℕ, ∀ ω, staircase n (f ω) ≤ staircase (n + 1) (f ω)) ∧
    (∀ n : ℕ, ∀ ω, staircase n (f ω) ≤ f ω) ∧
    (∀ n : ℕ, ∀ ω, f ω ≤ n → f ω - staircase n (f ω) < (2 ^ n)⁻¹) ∧
    (∀ ω, Tendsto (fun n => staircase n (f ω)) atTop (𝓝 (f ω))) := by
  refine ⟨fun n => ?_, fun n ω => staircase_mono n (f ω), fun n ω => staircase_le n (f ω),
    fun n ω h => staircase_close n (f ω) h, fun ω => staircase_tendsto (f ω)⟩
  refine ⟨⟨fun ω => staircase n (f ω), fun b => ?_, ?_⟩, rfl⟩
  · exact ((staircase_measurable n).comp hf) (measurableSet_singleton b)
  · exact (staircase_finite_range n).subset (Set.range_comp_subset_range f (staircase n))

/-- Standard form: a real function with finitely many values is measurable exactly when each
level set `{s = a}` is measurable, and it equals the sum of each value times the indicator of
the piece where that value is taken. -/
theorem simple_function_standard_form {Ω : Type*} [MeasurableSpace Ω] (s : Ω → ℝ)
    (hfin : (Set.range s).Finite) :
    (Measurable s ↔ ∀ a ∈ Set.range s, MeasurableSet (s ⁻¹' {a})) ∧
    ∀ ω, s ω = ∑ a ∈ hfin.toFinset, a * (s ⁻¹' {a}).indicator 1 ω := by
  refine ⟨⟨fun h a _ => h (measurableSet_singleton a), fun h => ?_⟩, fun ω => ?_⟩
  · have hfib : ∀ a : ℝ, MeasurableSet (s ⁻¹' {a}) := by
      intro a
      by_cases ha : a ∈ Set.range s
      · exact h a ha
      · have : s ⁻¹' {a} = ∅ := by
          ext ω
          simp only [Set.mem_preimage, Set.mem_singleton_iff, Set.mem_empty_iff_false, iff_false]
          exact fun hω => ha ⟨ω, hω⟩
        rw [this]; exact MeasurableSet.empty
    exact (SimpleFunc.mk s hfib hfin).measurable
  · rw [Finset.sum_eq_single (s ω)]
    · simp [Set.indicator]
    · intro b _ hb
      have : ω ∉ s ⁻¹' {b} := fun h => hb (h.symm ▸ rfl)
      simp [Set.indicator_of_notMem this]
    · intro h
      exact absurd (hfin.mem_toFinset.mpr ⟨ω, rfl⟩) h

/-- The converse: a function from a set with a sigma-algebra to `[0, ∞]` is measurable exactly
when it is the pointwise limit of a rising sequence of simple functions. -/
theorem measurable_iff_rising_limit_of_simple {Ω : Type*} [MeasurableSpace Ω] (f : Ω → ℝ≥0∞) :
    Measurable f ↔ ∃ s : ℕ → SimpleFunc Ω ℝ≥0∞,
      Monotone s ∧ ∀ ω, Tendsto (fun n => s n ω) atTop (𝓝 (f ω)) := by
  constructor
  · intro hf
    exact ⟨SimpleFunc.eapprox f, SimpleFunc.monotone_eapprox f, SimpleFunc.tendsto_eapprox hf⟩
  · rintro ⟨s, -, hs⟩
    exact measurable_of_tendsto_metrizable (fun n => (s n).measurable) (tendsto_pi_nhds.mpr hs)

-- At 19:00 the draw is 3.1 kW = 31/10. Stage n reads ⌊2^n · 31/10⌋ steps of 2^-n, capped at n·2^n.
-- Stage 2: ⌊4 × 3.1⌋ = 12 steps of 1/4, i.e. 3 kW, above the ceiling, so it reads 2 kW = 8/4.
example : min (2 * 2 ^ 2) ((2 ^ 2 * 31) / 10) = 8 := by decide
-- Stage 4: ⌊16 × 3.1⌋ = 49, so it reads 49/16 = 3.0625 kW.
example : (2 ^ 4 * 31) / 10 = 49 ∧ 49 < 4 * 2 ^ 4 := by decide
-- Stage 8: ⌊256 × 3.1⌋ = 793, so it reads 793/256 = 3.09765625 kW.
example : (2 ^ 8 * 31) / 10 = 793 ∧ 793 < 8 * 2 ^ 8 := by decide
-- The gaps at 19:00 are below one step: 31/10 - 49/16 < 1/16 and 31/10 - 793/256 < 1/256.
example : (31 : ℚ) / 10 - 49 / 16 < 1 / 16 ∧ (31 : ℚ) / 10 - 793 / 256 < 1 / 256 := by norm_num
-- At most n·2^n + 1 values: 3 at stage 1, 9 at stage 2, 2049 at stage 8.
example : 1 * 2 ^ 1 + 1 = 3 ∧ 2 * 2 ^ 2 + 1 = 9 ∧ 8 * 2 ^ 8 + 1 = 2049 := by decide

#print axioms staircase_approximation
#print axioms simple_function_standard_form
#print axioms measurable_iff_rising_limit_of_simple
