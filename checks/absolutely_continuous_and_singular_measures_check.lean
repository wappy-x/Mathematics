-- Absolutely continuous and singular measures: a measure given by a nonnegative density is absolutely continuous, for a finite measure absolute continuity is the epsilon-delta condition, and a measure both absolutely continuous and singular with respect to another is zero.
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.MutuallySingular
import Mathlib.MeasureTheory.OuterMeasure.BorelCantelli
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Intervals

open MeasureTheory

/-- A density always gives absolute continuity. Let f be a nonnegative measurable function.
Weighing every set A by the integral of f over A against mu gives a measure, and every measure
nu built this way (nu(A) is the integral of f over A, for every measurable A) is absolutely
continuous with respect to mu: whatever mu calls size zero, nu calls size zero too. -/
theorem density_gives_absolute_continuity {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : Ω → ℝ) (hf : Measurable f) (hf0 : ∀ x, 0 ≤ f x) :
    (∃ ν : Measure Ω, ∀ A, MeasurableSet A → ν A = ∫⁻ x in A, ENNReal.ofReal (f x) ∂μ) ∧
    ∀ ν : Measure Ω, (∀ A, MeasurableSet A → ν A = ∫⁻ x in A, ENNReal.ofReal (f x) ∂μ) →
      ν ≪ μ := by
  refine ⟨⟨μ.withDensity (fun x => ENNReal.ofReal (f x)), fun A hA => withDensity_apply _ hA⟩, ?_⟩
  intro ν hν
  have : ν = μ.withDensity (fun x => ENNReal.ofReal (f x)) :=
    Measure.ext fun A hA => by rw [hν A hA, withDensity_apply _ hA]
  rw [this]
  exact withDensity_absolutelyContinuous _ _

/-- For a finite measure nu, absolute continuity is a quantitative promise: nu is absolutely
continuous with respect to mu exactly when for every epsilon > 0 there is a delta > 0 such that
every measurable set of mu-size under delta has nu-size under epsilon. -/
theorem absolutely_continuous_iff_epsilon_delta {Ω : Type*} [MeasurableSpace Ω]
    (μ ν : Measure Ω) [IsFiniteMeasure ν] :
    ν ≪ μ ↔ ∀ ε : ℝ, 0 < ε → ∃ δ : ℝ, 0 < δ ∧
      ∀ A, MeasurableSet A → μ A < ENNReal.ofReal δ → ν A < ENNReal.ofReal ε := by
  constructor
  · intro hac
    by_contra hcon
    push Not at hcon
    obtain ⟨ε, hε, h⟩ := hcon
    have hex : ∀ n : ℕ, ∃ A, MeasurableSet A ∧ μ A < ENNReal.ofReal ((1 / 2 : ℝ) ^ n) ∧
        ENNReal.ofReal ε ≤ ν A := fun n => h _ (by positivity)
    choose A hAm hAμ hAν using hex
    have hsum : ∑' i, μ (A i) ≠ ⊤ := by
      refine ne_top_of_le_ne_top (b := ∑' i : ℕ, (2⁻¹ : ENNReal) ^ i) ?_ ?_
      · rw [ENNReal.tsum_geometric]
        simp [ENNReal.one_sub_inv_two]
      · refine tsum_le_tsum fun i => (hAμ i).le.trans_eq ?_
        rw [ENNReal.ofReal_pow (by norm_num)]
        congr 1
        rw [one_div, ENNReal.ofReal_inv_of_pos (by norm_num)]
        simp
    have h0 : μ (Filter.limsup A Filter.atTop) = 0 := measure_limsup_atTop_eq_zero hsum
    have h1 : ν (Filter.limsup A Filter.atTop) = 0 := hac h0
    rw [Filter.limsup_eq_iInf_iSup_of_nat] at h1
    simp only [Set.iSup_eq_iUnion, Set.iInf_eq_iInter] at h1
    have hanti : Antitone (fun n : ℕ => ⋃ i ≥ n, A i) := by
      intro m n hmn x hx
      simp only [Set.mem_iUnion] at hx ⊢
      obtain ⟨i, hi, hx⟩ := hx
      exact ⟨i, le_trans hmn hi, hx⟩
    rw [hanti.measure_iInter (fun n => (MeasurableSet.biUnion (Set.to_countable _)
      fun i _ => hAm i).nullMeasurableSet) ⟨0, measure_ne_top _ _⟩] at h1
    have : ENNReal.ofReal ε ≤ ⨅ n, ν (⋃ i ≥ n, A i) :=
      le_iInf fun n => (hAν n).trans (measure_mono fun x hx => by
        simp only [Set.mem_iUnion]; exact ⟨n, le_refl n, hx⟩)
    rw [h1] at this
    exact (ENNReal.ofReal_pos.mpr hε).ne' (le_antisymm this (zero_le))
  · intro h
    refine Measure.AbsolutelyContinuous.mk fun A hA hμA => ?_
    by_contra hne
    have hpos : 0 < (ν A).toReal := ENNReal.toReal_pos hne (measure_ne_top _ _)
    obtain ⟨δ, hδ, hδA⟩ := h _ hpos
    have := hδA A hA (by rw [hμA]; exact ENNReal.ofReal_pos.mpr hδ)
    rw [ENNReal.ofReal_toReal (measure_ne_top _ _)] at this
    exact lt_irrefl _ this

/-- Both at once means zero: if nu is absolutely continuous with respect to mu and the two are
mutually singular, then nu gives every set size zero. -/
theorem absolutely_continuous_and_singular_is_zero {Ω : Type*} [MeasurableSpace Ω]
    (μ ν : Measure Ω) (hac : ν ≪ μ) (hsing : ν ⟂ₘ μ) : ν = 0 := by
  exact Measure.eq_zero_of_absolutelyContinuous_of_mutuallySingular hac hsing

-- The dice. Faces 1 to 6 are 0 to 5 here; weights in tenths: P is 1/6 per face (not whole
-- tenths, so it charges every face), Q = 1,1,1,1,2,4; R = 2,2,2,2,2,0; D = 0,0,0,0,0,10.
-- Null sets out of the 64 sets of faces: R has 2 (the empty set and {6}), D has 32.
example : (Finset.univ.powerset.filter
    (fun s : Finset (Fin 6) => ∑ k ∈ s, ![2, 2, 2, 2, 2, 0] k = (0 : ℕ))).card = 2 := by decide
example : (Finset.univ.powerset.filter
    (fun s : Finset (Fin 6) => ∑ k ∈ s, ![0, 0, 0, 0, 0, 10] k = (0 : ℕ))).card = 32 := by decide
example : (Finset.univ.powerset.filter
    (fun s : Finset (Fin 6) => ∑ k ∈ s, ![1, 1, 1, 1, 2, 4] k = (0 : ℕ))).card = 1 := by decide
example : (Finset.univ : Finset (Finset (Fin 6))).card = 64 := by decide
-- R and D are mutually singular, S = faces 1 to 5: R gives face 6 nothing, D gives faces 1 to 5 nothing.
example : ![2, 2, 2, 2, 2, (0 : ℕ)] 5 = 0 ∧
    ∑ k ∈ ({0, 1, 2, 3, 4} : Finset (Fin 6)), ![0, 0, 0, 0, 0, (10 : ℕ)] k = 0 := by decide
-- Density of Q against P: 0.1 / (1/6) = 3/5, 0.2 / (1/6) = 6/5, 0.4 / (1/6) = 12/5.
example : (1 / 10 : ℚ) / (1 / 6) = 3 / 5 ∧ (2 / 10 : ℚ) / (1 / 6) = 6 / 5 ∧
    (4 / 10 : ℚ) / (1 / 6) = 12 / 5 := by norm_num
-- Q(5 or 6) through the density: (6/5 + 12/5) times 1/6 = 3/5 = 2/10 + 4/10.
example : ((6 / 5 : ℚ) + 12 / 5) * (1 / 6) = 2 / 10 + 4 / 10 := by norm_num
-- R is P reweighted by 6/5 on faces 1 to 5 and 0 on face 6.
example : (6 / 5 : ℚ) * (1 / 6) = 2 / 10 ∧ (0 : ℚ) * (1 / 6) = 0 := by norm_num
-- Epsilon-delta example: mu(n) = 2^-n, nu(n) = 1/(n(n+1)). The numbers 1 to 10 have mu-weight
-- 1 - 1/1024, so a set of mu-size under 1/1024 misses them all; the weights 11 to 16 plus the
-- weight beyond 16 (1/17) telescope to 1/11, which is below epsilon = 1/10.
example : ∑ n ∈ Finset.Icc (1 : ℕ) 10, (1 / 2 : ℚ) ^ n = 1 - 1 / 1024 := by
  simp [Finset.sum_Icc_succ_top]; norm_num
example : ∑ n ∈ Finset.Icc (11 : ℕ) 16, (1 : ℚ) / ((n : ℚ) * (n + 1)) + 1 / 17 = 1 / 11 := by
  simp [Finset.sum_Icc_succ_top]; norm_num
example : (1 : ℚ) / 11 < 1 / 10 := by norm_num
-- Counting measure against 2^-n: the point 20 has weight 1/1048576 and count 1.
example : (2 : ℕ) ^ 10 = 1024 ∧ (2 : ℕ) ^ 20 = 1048576 := by norm_num
-- Cantor stages: stage 10 keeps 2^10 = 1024 intervals, each of kappa-weight 1/1024,
-- with total length (2/3)^10 = 1024/59049.
example : (2 / 3 : ℚ) ^ 10 = 1024 / 59049 ∧ (1024 : ℚ) * (1 / 1024) = 1 := by norm_num

#print axioms density_gives_absolute_continuity
#print axioms absolutely_continuous_iff_epsilon_delta
#print axioms absolutely_continuous_and_singular_is_zero
