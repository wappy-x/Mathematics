-- Stochastic dominance: one fund beats another for every investor who likes more money exactly when its CDF is never higher, and for every risk-averse such investor exactly when its average shortfall below every cutoff is never higher.
import Mathlib.Probability.CDF
import Mathlib.Analysis.Convex.Function
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory ProbabilityTheory

theorem sd_shortfall_lintegral (μ : Measure ℝ) [IsProbabilityMeasure μ] (k : ℝ) :
    ∫⁻ x, ENNReal.ofReal (max (k - x) 0) ∂μ = ∫⁻ t in Set.Iic k, ENNReal.ofReal (cdf μ t) := by
  rw [lintegral_eq_lintegral_meas_le (f := fun x => max (k - x) 0) μ (Filter.Eventually.of_forall fun x => le_max_right _ _)
    (by fun_prop)]
  have h1 : ∀ s ∈ Set.Ioi (0:ℝ), μ {a | s ≤ max (k - a) 0} = ENNReal.ofReal (cdf μ (k - s)) := by
    intro s hs
    rw [ofReal_cdf]
    congr 1
    ext a
    simp only [Set.mem_ofPred_eq, Set.mem_Iic, le_max_iff]
    constructor
    · rintro (h | h)
      · linarith
      · exact absurd h (not_le.mpr hs)
    · intro h; left; linarith
  rw [setLIntegral_congr_fun measurableSet_Ioi h1]
  rw [← lintegral_indicator measurableSet_Ioi, ← lintegral_indicator measurableSet_Iic]
  rw [← lintegral_sub_left_eq_self _ k]
  apply lintegral_congr_ae
  have : ∀ᵐ t ∂(volume : Measure ℝ), t ≠ k := by
    simp [ae_iff, measure_singleton]
  filter_upwards [this] with t ht
  simp only [Set.indicator, Set.mem_Ioi, Set.mem_Iic, sub_pos, sub_sub_cancel]
  by_cases h : t < k
  · simp [h, h.le]
  · have : ¬ t ≤ k := fun h' => h (lt_of_le_of_ne h' ht)
    simp [h, this]

#print axioms sd_shortfall_lintegral

theorem sd_lowerSet_le (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hF : ∀ t : ℝ, cdf μ t ≤ cdf ν t) (L : Set ℝ) (hL : IsLowerSet L) : μ L ≤ ν L := by
  by_cases hmax : ∃ s ∈ L, ∀ x ∈ L, x ≤ s
  · obtain ⟨s, hs, hsm⟩ := hmax
    have hLs : L = Set.Iic s := by
      ext x
      exact ⟨fun hx => hsm x hx, fun hx => hL hx hs⟩
    rw [hLs, ← ofReal_cdf, ← ofReal_cdf]
    exact ENNReal.ofReal_le_ofReal (hF s)
  · push Not at hmax
    set A : ℚ → Set ℝ := fun q => {x | x ≤ (q : ℝ) ∧ (q : ℝ) ∈ L} with hA
    have hU : L = ⋃ q, A q := by
      ext x
      simp only [Set.mem_iUnion, hA, Set.mem_ofPred_eq]
      constructor
      · intro hx
        obtain ⟨y, hy, hxy⟩ := hmax x hx
        obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn hxy
        exact ⟨q, hq1.le, hL hq2.le hy⟩
      · rintro ⟨q, hxq, hq⟩
        exact hL hxq hq
    have hdir : Directed (· ⊆ ·) A := by
      intro q1 q2
      have key : ∀ a b : ℚ, a ≤ b → ∃ r, A a ⊆ A r ∧ A b ⊆ A r := by
        intro a b hab
        by_cases hb : (b : ℝ) ∈ L
        · refine ⟨b, fun x hx => ⟨hx.1.trans (by exact_mod_cast hab), hb⟩, le_rfl⟩
        · refine ⟨a, le_rfl, fun x hx => absurd hx.2 hb⟩
      rcases le_total q1 q2 with h | h
      · exact key q1 q2 h
      · obtain ⟨r, h1, h2⟩ := key q2 q1 h
        exact ⟨r, h2, h1⟩
    have hle : ∀ q, μ (A q) ≤ ν (A q) := by
      intro q
      by_cases hq : (q : ℝ) ∈ L
      · have : A q = Set.Iic (q : ℝ) := by
          ext x; simp [hA, hq]
        rw [this, ← ofReal_cdf, ← ofReal_cdf]
        exact ENNReal.ofReal_le_ofReal (hF q)
      · have : A q = ∅ := by
          ext x; simp [hA, hq]
        simp [this]
    rw [hU, hdir.measure_iUnion, hdir.measure_iUnion]
    exact iSup_mono hle

#print axioms sd_lowerSet_le

theorem sd_upperSet_le (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hF : ∀ t : ℝ, cdf μ t ≤ cdf ν t) (S : Set ℝ) (hS : IsUpperSet S) (hSm : MeasurableSet S) :
    ν S ≤ μ S := by
  have h1 : ν S = 1 - ν Sᶜ := by
    rw [prob_compl_eq_one_sub hSm, ENNReal.sub_sub_cancel ENNReal.one_ne_top prob_le_one]
  have h2 : μ S = 1 - μ Sᶜ := by
    rw [prob_compl_eq_one_sub hSm, ENNReal.sub_sub_cancel ENNReal.one_ne_top prob_le_one]
  rw [h1, h2]
  exact tsub_le_tsub_left (sd_lowerSet_le μ ν hF Sᶜ hS.compl) 1

#print axioms sd_upperSet_le

theorem sd_min_integrable (ρ : Measure ℝ) [IsProbabilityMeasure ρ]
    (h : Integrable (fun x => x) ρ) (k : ℝ) : Integrable (fun x => min (x - k) 0) ρ := by
  refine ((integrable_const k).sub h).pos_part.neg.congr (ae_of_all _ fun x => ?_)
  simp only [Pi.neg_apply, Pi.sub_apply]
  rw [min_def, max_def]
  split_ifs <;> linarith

#print axioms sd_min_integrable

theorem sd_ramp_integral (ρ : Measure ℝ) [IsProbabilityMeasure ρ]
    (hρ : Integrable (fun x => x) ρ) (d h a b : ℝ) :
    Integrable (fun x => d * ((min (x - a) 0 - min (x - b) 0) / h + 1)) ρ ∧
    ∫ x, d * ((min (x - a) 0 - min (x - b) 0) / h + 1) ∂ρ =
      d * ((∫ x, min (x - a) 0 ∂ρ - ∫ x, min (x - b) 0 ∂ρ) / h + 1) := by
  have ha := sd_min_integrable ρ hρ a
  have hb := sd_min_integrable ρ hρ b
  constructor
  · exact (((ha.sub hb).div_const h).add (integrable_const 1)).const_mul d
  · have hs : Integrable (fun x => (min (x - a) 0 - min (x - b) 0) / h) ρ :=
      (ha.sub hb).div_const h
    rw [integral_const_mul, integral_add hs (integrable_const 1),
      integral_div, integral_sub ha hb]
    simp

#print axioms sd_ramp_integral

theorem sd_cone (μ ν : Measure ℝ) [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hμ : Integrable (fun x => x) μ) (hν : Integrable (fun x => x) ν)
    (H : ∀ k, ∫ x, min (x - k) 0 ∂ν ≤ ∫ x, min (x - k) 0 ∂μ)
    (c h : ℝ) (hh : 0 < h) (p D : ℕ → ℝ) (hDa : ∀ j, D (j + 1) ≤ D j)
    (m : ℕ) :
    Integrable (fun x => c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
      D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1)) μ ∧
    Integrable (fun x => c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
      D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1)) ν ∧
    D m * (∫ x, min (x - p m) 0 ∂μ - ∫ x, min (x - p m) 0 ∂ν) / h ≤
      (∫ x, c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
        D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1) ∂μ) -
      (∫ x, c + D 0 * min (x - p 0) 0 / h + ∑ j ∈ Finset.range m,
        D j * ((min (x - p (j + 1)) 0 - min (x - p j) 0) / h + 1) ∂ν) := by
  induction m with
  | zero =>
    have h0 : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] → Integrable (fun x => x) ρ →
        Integrable (fun x => c + D 0 * min (x - p 0) 0 / h) ρ ∧
        ∫ x, c + D 0 * min (x - p 0) 0 / h ∂ρ = c + D 0 * (∫ x, min (x - p 0) 0 ∂ρ) / h := by
      intro ρ _ hρ
      have hg := sd_min_integrable ρ hρ (p 0)
      refine ⟨(integrable_const c).add ((hg.const_mul (D 0)).div_const h), ?_⟩
      rw [integral_add (integrable_const c) ((hg.const_mul (D 0)).div_const h), integral_div,
        integral_const_mul]
      simp
    simp only [Finset.range_zero, Finset.sum_empty, add_zero]
    obtain ⟨i1, e1⟩ := h0 μ hμ
    obtain ⟨i2, e2⟩ := h0 ν hν
    refine ⟨i1, i2, ?_⟩
    rw [e1, e2]
    apply le_of_eq
    ring
  | succ m ih =>
    obtain ⟨i1, i2, hle⟩ := ih
    obtain ⟨r1, f1⟩ := sd_ramp_integral μ hμ (D m) h (p (m + 1)) (p m)
    obtain ⟨r2, f2⟩ := sd_ramp_integral ν hν (D m) h (p (m + 1)) (p m)
    simp only [Finset.sum_range_succ, ← add_assoc]
    refine ⟨i1.add r1, i2.add r2, ?_⟩
    rw [integral_add i1 r1, integral_add i2 r2, f1, f2]
    have hA : 0 ≤ ∫ x, min (x - p (m + 1)) 0 ∂μ - ∫ x, min (x - p (m + 1)) 0 ∂ν :=
      sub_nonneg.mpr (H _)
    have hA' : 0 ≤ ∫ x, min (x - p m) 0 ∂μ - ∫ x, min (x - p m) 0 ∂ν :=
      sub_nonneg.mpr (H _)
    have key : D (m + 1) * (∫ x, min (x - p (m + 1)) 0 ∂μ - ∫ x, min (x - p (m + 1)) 0 ∂ν) ≤
        D m * (∫ x, min (x - p (m + 1)) 0 ∂μ - ∫ x, min (x - p (m + 1)) 0 ∂ν) :=
      mul_le_mul_of_nonneg_right (hDa m) hA
    rw [div_le_iff₀ hh] at hle ⊢
    have alg : ∀ Iμ Iν a1 a2 b1 b2 : ℝ, (Iμ + D m * ((a1 - a2) / h + 1) -
        (Iν + D m * ((b1 - b2) / h + 1))) * h =
        (Iμ - Iν) * h + D m * ((a1 - b1) - (a2 - b2)) := by
      intros; field_simp; ring
    rw [alg]
    nlinarith

#print axioms sd_cone

theorem sd_ramp (h : ℝ) (hh : 0 < h) (q1 q2 x : ℝ) (hq : q2 = q1 + h) :
    0 ≤ (min (x - q2) 0 - min (x - q1) 0) / h + 1 ∧
    (min (x - q2) 0 - min (x - q1) 0) / h + 1 ≤ 1 ∧
    (q2 ≤ x → (min (x - q2) 0 - min (x - q1) 0) / h + 1 = 1) ∧
    (x ≤ q1 → (min (x - q2) 0 - min (x - q1) 0) / h + 1 = 0) := by
  subst hq
  refine ⟨?_, ?_, fun hx => ?_, fun hx => ?_⟩
  · have : -h ≤ min (x - (q1 + h)) 0 - min (x - q1) 0 := by
      rw [min_def, min_def]; split_ifs <;> linarith
    have : -1 ≤ (min (x - (q1 + h)) 0 - min (x - q1) 0) / h := by
      rw [le_div_iff₀ hh]; linarith
    linarith
  · have : min (x - (q1 + h)) 0 - min (x - q1) 0 ≤ 0 := by
      rw [min_def, min_def]; split_ifs <;> linarith
    have : (min (x - (q1 + h)) 0 - min (x - q1) 0) / h ≤ 0 := div_nonpos_of_nonpos_of_nonneg this hh.le
    linarith
  · rw [min_eq_right (by linarith), min_eq_right (by linarith)]; simp
  · rw [min_eq_left (by linarith), min_eq_left (by linarith)]
    field_simp; ring

#print axioms sd_ramp

theorem sd_sum_bounds (h : ℝ) (hh : 0 < h) (b : ℝ) (D : ℕ → ℝ) (hD : ∀ j, 0 ≤ D j) (m : ℕ)
    (x : ℝ) :
    (x ≤ b → ∑ j ∈ Finset.range m,
      D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        = 0) ∧
    (b + (m : ℝ) * h ≤ x → ∑ j ∈ Finset.range m,
      D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        = ∑ j ∈ Finset.range m, D j) ∧
    (∀ i, i < m → b + (i : ℝ) * h ≤ x → x ≤ b + ((i + 1 : ℕ) : ℝ) * h →
      ∑ j ∈ Finset.range i, D j ≤ ∑ j ∈ Finset.range m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1) ∧
      ∑ j ∈ Finset.range m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        ≤ ∑ j ∈ Finset.range (i + 1), D j) := by
  have R := fun j : ℕ => sd_ramp h hh (b + (j : ℝ) * h) (b + ((j + 1 : ℕ) : ℝ) * h) x
    (by push_cast; ring)
  have hmono : ∀ i j : ℕ, i ≤ j → b + (i : ℝ) * h ≤ b + (j : ℝ) * h := by
    intro i j hij
    have : (i : ℝ) ≤ j := by exact_mod_cast hij
    nlinarith
  refine ⟨fun hx => ?_, fun hx => ?_, fun i hi hx1 hx2 => ⟨?_, ?_⟩⟩
  · refine Finset.sum_eq_zero fun j _ => ?_
    rw [(R j).2.2.2 (hx.trans (by simpa using hmono 0 j (Nat.zero_le j))), mul_zero]
  · refine Finset.sum_congr rfl fun j hj => ?_
    rw [(R j).2.2.1 ((hmono (j + 1) m (Finset.mem_range.mp hj)).trans hx), mul_one]
  · rw [← Finset.sum_range_add_sum_Ico _ hi.le]
    have h1 : ∑ j ∈ Finset.range i, D j = ∑ j ∈ Finset.range i,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1) := by
      refine Finset.sum_congr rfl fun j hj => ?_
      rw [(R j).2.2.1 ((hmono (j + 1) i (Finset.mem_range.mp hj)).trans hx1), mul_one]
    have h2 : 0 ≤ ∑ j ∈ Finset.Ico i m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1) :=
      Finset.sum_nonneg fun j _ => mul_nonneg (hD j) (R j).1
    linarith
  · rw [← Finset.sum_range_add_sum_Ico _ (Nat.succ_le_of_lt hi)]
    have h1 : ∑ j ∈ Finset.range (i + 1),
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        ≤ ∑ j ∈ Finset.range (i + 1), D j :=
      Finset.sum_le_sum fun j _ => mul_le_of_le_one_right (hD j) (R j).2.1
    have h2 : ∑ j ∈ Finset.Ico (i + 1) m,
        D j * ((min (x - (b + ((j + 1 : ℕ) : ℝ) * h)) 0 - min (x - (b + (j : ℝ) * h)) 0) / h + 1)
        = 0 := by
      refine Finset.sum_eq_zero fun j hj => ?_
      rw [(R j).2.2.2 (hx2.trans (hmono (i + 1) j (Finset.mem_Ico.mp hj).1)), mul_zero]
    linarith

#print axioms sd_sum_bounds

theorem sd_cover (b h : ℝ) (hh : 0 < h) (m : ℕ) (x : ℝ) :
    x ≤ b ∨ b + (m : ℝ) * h ≤ x ∨
      ∃ i, i < m ∧ b + (i : ℝ) * h ≤ x ∧ x ≤ b + ((i + 1 : ℕ) : ℝ) * h := by
  by_cases h1 : x ≤ b
  · exact Or.inl h1
  by_cases h2 : b + (m : ℝ) * h ≤ x
  · exact Or.inr (Or.inl h2)
  right; right
  push Not at h1 h2
  have hpos : 0 ≤ (x - b) / h := div_nonneg (by linarith) hh.le
  refine ⟨⌊(x - b) / h⌋₊, ?_, ?_, ?_⟩
  · rw [Nat.floor_lt hpos, div_lt_iff₀ hh]; linarith
  · have := Nat.floor_le hpos
    rw [le_div_iff₀ hh] at this; linarith
  · have := Nat.lt_floor_add_one ((x - b) / h)
    rw [div_lt_iff₀ hh] at this; push_cast; linarith

#print axioms sd_cover

theorem sd_approx (u : ℝ → ℝ) (hu : Monotone u) (hc : ConcaveOn ℝ Set.univ u) (a h : ℝ)
    (hh : 0 < h) (D : ℕ → ℝ) (hD : ∀ j, D j = u (a + ((j + 1 : ℕ) : ℝ) * h) - u (a + (j : ℝ) * h))
    (m : ℕ) (x : ℝ) :
    (x ≤ a - h + ((0 : ℕ) : ℝ) * h → u x ≤ u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
      ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
        min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ∧
      u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
      ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
        min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ≤ u a) ∧
    (a - h + (m : ℝ) * h ≤ x → u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
      ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
        min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) = u (a + (m : ℝ) * h)) ∧
    (∀ i, i < m → a - h + (i : ℝ) * h ≤ x → x ≤ a - h + ((i + 1 : ℕ) : ℝ) * h →
      u (a + (i : ℝ) * h) ≤ u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
        ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
          min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ∧
      u a + D 0 * min (x - (a - h + ((0 : ℕ) : ℝ) * h)) 0 / h +
        ∑ j ∈ Finset.range m, D j * ((min (x - (a - h + ((j + 1 : ℕ) : ℝ) * h)) 0 -
          min (x - (a - h + (j : ℝ) * h)) 0) / h + 1) ≤ u (a + ((i + 1 : ℕ) : ℝ) * h)) := by
  have hDnn : ∀ j, 0 ≤ D j := by
    intro j; rw [hD j]; apply sub_nonneg.mpr; apply hu; push_cast; nlinarith
  have tele : ∀ i, ∑ j ∈ Finset.range i, D j = u (a + (i : ℝ) * h) - u a := by
    intro i
    have := Finset.sum_range_sub (fun j : ℕ => u (a + (j : ℝ) * h)) i
    simp only [Nat.cast_zero, zero_mul, add_zero] at this
    rw [← this]
    exact Finset.sum_congr rfl fun j _ => hD j
  obtain ⟨S1, S2, S3⟩ := sd_sum_bounds h hh (a - h) D hDnn m x
  simp only [Nat.cast_zero, zero_mul, add_zero] at S1 ⊢
  refine ⟨fun hx => ?_, fun hx => ?_, fun i hi hx1 hx2 => ?_⟩
  · rw [S1 hx, add_zero, min_eq_left (by linarith)]
    have hD0 : D 0 = u (a + h) - u a := by rw [hD 0]; simp
    have hslope := hc.slope_anti_adjacent (Set.mem_univ x) (Set.mem_univ (a + h))
      (show x < a by linarith) (show a < a + h by linarith)
    rw [add_sub_cancel_left, ← hD0, div_le_div_iff₀ hh (by linarith)] at hslope
    have hd0 := hDnn 0
    constructor
    · have e : D 0 * (x - (a - h)) / h = D 0 * (x - a) / h + D 0 := by field_simp; ring
      have e2 : D 0 * (x - a) / h ≥ -(u a - u x) := by
        rw [ge_iff_le, le_div_iff₀ hh]; nlinarith
      linarith
    · have : D 0 * (x - (a - h)) / h ≤ 0 :=
        div_nonpos_of_nonpos_of_nonneg (mul_nonpos_of_nonneg_of_nonpos hd0 (by linarith)) hh.le
      linarith
  · have hx0 : a - h ≤ x := by
      have : (0 : ℝ) ≤ (m : ℝ) * h := by positivity
      linarith
    rw [S2 hx, min_eq_right (by linarith), tele m]; simp
  · have hx0 : a - h ≤ x := by
      have : (0 : ℝ) ≤ (i : ℝ) * h := by positivity
      linarith
    obtain ⟨L, U⟩ := S3 i hi hx1 hx2
    rw [min_eq_right (by linarith), tele] at *
    simp only [mul_zero, zero_div, add_zero]
    constructor <;> linarith

#print axioms sd_approx

/-- First-order stochastic dominance. Fund A (return distribution `μ`) gives every investor who
prefers more money to less (every increasing utility `u` whose averages exist) at least the
average utility of fund B (distribution `ν`) exactly when, at every threshold `t`, A is no more
likely than B to end at or below `t`: `F_A(t) ≤ F_B(t)`. -/
theorem first_order_dominance_iff_cdf_le (μ ν : Measure ℝ)
    [IsProbabilityMeasure μ] [IsProbabilityMeasure ν] :
    (∀ u : ℝ → ℝ, Monotone u → Integrable u μ → Integrable u ν →
        ∫ x, u x ∂ν ≤ ∫ x, u x ∂μ) ↔
      ∀ t : ℝ, cdf μ t ≤ cdf ν t := by
  constructor
  · intro H t
    have hmono : Monotone ((Set.Ioi t).indicator (1 : ℝ → ℝ)) := by
      intro a b hab
      simp only [Set.indicator, Set.mem_Ioi, Pi.one_apply]
      split_ifs with h1 h2 <;> first | exact le_rfl | exact absurd (h1.trans_le hab) h2 | norm_num
    have hint : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] →
        Integrable ((Set.Ioi t).indicator (1 : ℝ → ℝ)) ρ := fun ρ _ =>
      (integrable_const (1 : ℝ)).indicator measurableSet_Ioi
    have hval : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] →
        ∫ x, (Set.Ioi t).indicator (1 : ℝ → ℝ) x ∂ρ = 1 - cdf ρ t := by
      intro ρ _
      rw [integral_indicator_one measurableSet_Ioi, cdf_eq_real, ← Set.compl_Iic,
        probReal_compl_eq_one_sub measurableSet_Iic]
    have := H _ hmono (hint μ) (hint ν)
    rw [hval, hval] at this
    linarith
  · intro hF u hu hiμ hiν
    have hum : Measurable u := hu.measurable
    rw [integral_eq_lintegral_pos_part_sub_lintegral_neg_part hiμ,
      integral_eq_lintegral_pos_part_sub_lintegral_neg_part hiν]
    have hpos : ∀ ρ : Measure ℝ, ∫⁻ x, ENNReal.ofReal (u x) ∂ρ =
        ∫⁻ s in Set.Ioi 0, ρ {a | s < max (u a) 0} := by
      intro ρ
      rw [← lintegral_eq_lintegral_meas_lt (f := fun x => max (u x) 0) ρ
        (Filter.Eventually.of_forall fun x => le_max_right _ _) (by fun_prop)]
      congr 1; ext x; simp [ENNReal.ofReal_max]
    have hneg : ∀ ρ : Measure ℝ, ∫⁻ x, ENNReal.ofReal (-u x) ∂ρ =
        ∫⁻ s in Set.Ioi 0, ρ {a | s < max (-u a) 0} := by
      intro ρ
      rw [← lintegral_eq_lintegral_meas_lt (f := fun x => max (-u x) 0) ρ
        (Filter.Eventually.of_forall fun x => le_max_right _ _) (by fun_prop)]
      congr 1; ext x; simp [ENNReal.ofReal_max]
    have hP : ∫⁻ x, ENNReal.ofReal (u x) ∂ν ≤ ∫⁻ x, ENNReal.ofReal (u x) ∂μ := by
      rw [hpos, hpos]
      refine lintegral_mono fun s => ?_
      refine sd_upperSet_le μ ν hF _ ?_ (measurableSet_lt measurable_const (by fun_prop))
      intro a b hab ha
      simp only [Set.mem_ofPred_eq] at ha ⊢
      exact ha.trans_le (max_le_max (hu hab) le_rfl)
    have hN : ∫⁻ x, ENNReal.ofReal (-u x) ∂μ ≤ ∫⁻ x, ENNReal.ofReal (-u x) ∂ν := by
      rw [hneg, hneg]
      refine lintegral_mono fun s => ?_
      refine sd_lowerSet_le μ ν hF _ ?_
      intro a b hab ha
      simp only [Set.mem_ofPred_eq] at ha ⊢
      exact ha.trans_le (max_le_max (neg_le_neg (hu hab)) le_rfl)
    have h1 := ENNReal.toReal_mono hiμ.lintegral_lt_top.ne hP
    have hfin : ∫⁻ x, ENNReal.ofReal (-u x) ∂ν < ⊤ := hiν.neg.lintegral_lt_top
    have h2 := ENNReal.toReal_mono hfin.ne hN
    linarith

/-- Second-order stochastic dominance. When both funds have finite averages, fund A (`μ`) gives
every investor who prefers more money to less and dislikes risk (every increasing concave
utility `u` whose averages exist) at least the average utility of fund B (`ν`) exactly when, at
every cutoff `k`, A's average shortfall `E[(k - A)⁺]` is no larger than B's. -/
theorem second_order_dominance_iff_shortfall_le (μ ν : Measure ℝ)
    [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    (hμ : Integrable (fun x => x) μ) (hν : Integrable (fun x => x) ν) :
    (∀ u : ℝ → ℝ, Monotone u → ConcaveOn ℝ Set.univ u → Integrable u μ → Integrable u ν →
        ∫ x, u x ∂ν ≤ ∫ x, u x ∂μ) ↔
      ∀ k : ℝ, ∫ x, max (k - x) 0 ∂μ ≤ ∫ x, max (k - x) 0 ∂ν := by
  have e : ∀ (ρ : Measure ℝ) (k : ℝ), ∫ x, min (x - k) 0 ∂ρ = -∫ x, max (k - x) 0 ∂ρ := by
    intro ρ k
    rw [← integral_neg]
    congr 1
    funext x
    rw [min_def, max_def]
    split_ifs <;> linarith
  constructor
  · intro H k
    have hmono : Monotone (fun x : ℝ => min (x - k) 0) :=
      fun a b hab => min_le_min (by linarith) le_rfl
    have hconc : ConcaveOn ℝ Set.univ (fun x : ℝ => min (x - k) 0) := by
      refine ⟨convex_univ, fun x _ y _ a b ha hb hab => ?_⟩
      simp only [smul_eq_mul]
      refine le_min ?_ ?_
      · have h1 := mul_le_mul_of_nonneg_left (min_le_left (x - k) 0) ha
        have h2 := mul_le_mul_of_nonneg_left (min_le_left (y - k) 0) hb
        have hk : a * (x - k) + b * (y - k) = a * x + b * y - k := by linear_combination (-k) * hab
        linarith
      · nlinarith [min_le_right (x - k) 0, min_le_right (y - k) 0]
    have := H _ hmono hconc (sd_min_integrable μ hμ k) (sd_min_integrable ν hν k)
    rw [e, e] at this
    linarith
  · intro hS u hu hc hiμ hiν
    have H : ∀ k, ∫ x, min (x - k) 0 ∂ν ≤ ∫ x, min (x - k) 0 ∂μ := by
      intro k; rw [e, e]; linarith [hS k]
    have hcont : Continuous u := by
      have := hc.continuousOn_interior
      rw [interior_univ] at this
      exact continuousOn_univ.mp this
    set a : ℕ → ℝ := fun n => -((n : ℝ) + 1) with ha
    set h : ℕ → ℝ := fun n => 1 / ((n : ℝ) + 1) with hh
    set m : ℕ → ℕ := fun n => 2 * (n + 1) ^ 2 with hm
    set Dn : ℕ → ℕ → ℝ := fun n j => u (a n + ((j + 1 : ℕ) : ℝ) * h n) - u (a n + (j : ℝ) * h n)
      with hDn
    set V : ℕ → ℝ → ℝ := fun n x => u (a n) +
      Dn n 0 * min (x - (a n - h n + ((0 : ℕ) : ℝ) * h n)) 0 / h n +
      ∑ j ∈ Finset.range (m n), Dn n j * ((min (x - (a n - h n + ((j + 1 : ℕ) : ℝ) * h n)) 0 -
        min (x - (a n - h n + (j : ℝ) * h n)) 0) / h n + 1) with hV
    have hpos : ∀ n, 0 < h n := fun n => by simp only [hh]; positivity
    have hle1 : ∀ n, h n ≤ 1 := fun n => by
      simp only [hh]
      rw [div_le_one (by positivity)]
      have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      linarith
    have hmh : ∀ n, ((m n : ℕ) : ℝ) * h n = 2 * ((n : ℝ) + 1) := fun n => by
      simp only [hm, hh]; push_cast; field_simp
    have hDnn : ∀ n j, 0 ≤ Dn n j := by
      intro n j; simp only [hDn]; apply sub_nonneg.mpr; apply hu
      have := hpos n; push_cast; nlinarith
    have hDa : ∀ n j, Dn n (j + 1) ≤ Dn n j := by
      intro n j
      have hp := hpos n
      have hs := hc.slope_anti_adjacent (Set.mem_univ (a n + (j : ℝ) * h n))
        (Set.mem_univ (a n + ((j + 1 + 1 : ℕ) : ℝ) * h n))
        (show a n + (j : ℝ) * h n < a n + ((j + 1 : ℕ) : ℝ) * h n by push_cast; linarith)
        (show a n + ((j + 1 : ℕ) : ℝ) * h n < a n + ((j + 1 + 1 : ℕ) : ℝ) * h n by
          push_cast; linarith)
      have e1 : a n + ((j + 1 + 1 : ℕ) : ℝ) * h n - (a n + ((j + 1 : ℕ) : ℝ) * h n) = h n := by
        push_cast; ring
      have e2 : a n + ((j + 1 : ℕ) : ℝ) * h n - (a n + (j : ℝ) * h n) = h n := by
        push_cast; ring
      rw [e1, e2, div_le_div_iff_of_pos_right hp] at hs
      simpa only [hDn] using hs
    -- comparison for each approximant
    have hcone := fun n => sd_cone μ ν hμ hν H (u (a n)) (h n) (hpos n)
      (fun j => a n - h n + (j : ℝ) * h n) (Dn n) (hDa n) (m n)
    have hcmp : ∀ n, ∫ x, V n x ∂ν ≤ ∫ x, V n x ∂μ := by
      intro n
      obtain ⟨_, _, hle⟩ := hcone n
      have h0 : 0 ≤ Dn n (m n) * (∫ x, min (x - (a n - h n + ((m n : ℕ) : ℝ) * h n)) 0 ∂μ -
          ∫ x, min (x - (a n - h n + ((m n : ℕ) : ℝ) * h n)) 0 ∂ν) / h n :=
        div_nonneg (mul_nonneg (hDnn n (m n)) (sub_nonneg.mpr (H _))) (hpos n).le
      exact sub_nonneg.mp (h0.trans hle)
    -- pointwise bounds
    have hbound : ∀ n x, (min (u x) (u 0) ≤ V n x ∧ V n x ≤ u (max x 0 + 2)) ∧
        (a n - h n < x → x < a n - h n + ((m n : ℕ) : ℝ) * h n →
          u x ≤ V n x ∧ V n x ≤ u (x + 2 * h n)) := by
      intro n x
      have hp := hpos n
      have h1 := hle1 n
      have hmhn := hmh n
      have han : a n = -((n : ℝ) + 1) := rfl
      have hn0 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      obtain ⟨A1, A2, A3⟩ := sd_approx u hu hc (a n) (h n) hp (Dn n) (fun j => rfl) (m n) x
      have hmax : x ≤ max x 0 := le_max_left _ _
      have hmax0 : 0 ≤ max x 0 := le_max_right _ _
      rcases sd_cover (a n - h n) (h n) hp (m n) x with hx | hx | ⟨i, hi, hx1, hx2⟩
      · obtain ⟨l, r⟩ := A1 (by simpa using hx)
        refine ⟨⟨(min_le_left _ _).trans l, r.trans (hu (by linarith))⟩, fun hx' _ => ?_⟩
        exact absurd hx (not_le.mpr hx')
      · have hv := A2 hx
        have hN : a n + ((m n : ℕ) : ℝ) * h n = (n : ℝ) + 1 := by rw [hmhn, han]; ring
        rw [hN] at hv
        refine ⟨⟨?_, ?_⟩, fun _ hx' => absurd hx (not_le.mpr hx')⟩
        · exact (min_le_right _ _).trans ((hu (by linarith : (0 : ℝ) ≤ (n : ℝ) + 1)).trans hv.ge)
        · exact hv.le.trans (hu (by linarith))
      · obtain ⟨l, r⟩ := A3 i hi hx1 hx2
        have hx2' : x ≤ a n + (i : ℝ) * h n := by push_cast at hx2; linarith
        have hup : a n + ((i + 1 : ℕ) : ℝ) * h n ≤ x + 2 * h n := by push_cast; linarith
        refine ⟨⟨(min_le_left _ _).trans ((hu hx2').trans l), r.trans (hu (by linarith))⟩,
          fun _ _ => ⟨(hu hx2').trans l, r.trans (hu hup)⟩⟩
    -- domination
    set c := u 0 - u (-1) with hcdef
    have hc0 : 0 ≤ c := sub_nonneg.mpr (hu (by norm_num))
    have hlin : ∀ y, 0 < y → u y ≤ u 0 + c * y := by
      intro y hy
      have hs := hc.slope_anti_adjacent (Set.mem_univ (-1 : ℝ)) (Set.mem_univ y)
        (show (-1 : ℝ) < 0 by norm_num) hy
      rw [sub_zero, show (0 : ℝ) - -1 = 1 by norm_num, div_one, div_le_iff₀ hy] at hs
      linarith
    have hG : ∀ n x, ‖V n x‖ ≤ |u x| + 2 * |u 0| + c * (|x| + 2) := by
      intro n x
      obtain ⟨⟨l, r⟩, _⟩ := hbound n x
      have r2 := hlin (max x 0 + 2) (by positivity)
      have hmx : max x 0 ≤ |x| := max_le (le_abs_self x) (abs_nonneg x)
      have hcm : c * (max x 0 + 2) ≤ c * (|x| + 2) := mul_le_mul_of_nonneg_left (by linarith) hc0
      have hcm0 : 0 ≤ c * (|x| + 2) := mul_nonneg hc0 (by positivity)
      have lo : -|u x| - |u 0| ≤ min (u x) (u 0) :=
        le_min (by linarith [neg_abs_le (u x), abs_nonneg (u 0)])
          (by linarith [neg_abs_le (u 0), abs_nonneg (u x)])
      rw [Real.norm_eq_abs, abs_le]
      constructor
      · linarith [abs_nonneg (u 0)]
      · linarith [le_abs_self (u 0), abs_nonneg (u x), abs_nonneg (u 0)]
    have hGint : ∀ ρ : Measure ℝ, [IsProbabilityMeasure ρ] → Integrable u ρ →
        Integrable (fun x => x) ρ → Integrable (fun x => |u x| + 2 * |u 0| + c * (|x| + 2)) ρ := by
      intro ρ _ hu' hx'
      exact (hu'.abs.add (integrable_const _)).add ((hx'.abs.add (integrable_const 2)).const_mul c)
    -- convergence
    have hlim : ∀ x, Filter.Tendsto (fun n => V n x) Filter.atTop (nhds (u x)) := by
      intro x
      have ht : Filter.Tendsto (fun n : ℕ => x + 2 * h n) Filter.atTop (nhds x) := by
        have := ((tendsto_one_div_add_atTop_nhds_zero_nat (𝕜 := ℝ)).const_mul 2).const_add x
        rw [mul_zero, add_zero] at this
        exact this
      have hev : ∀ᶠ n in Filter.atTop, u x ≤ V n x ∧ V n x ≤ u (x + 2 * h n) := by
        refine Filter.eventually_atTop.2 ⟨⌈|x|⌉₊ + 1, fun n hn => ?_⟩
        have hn' : (⌈|x|⌉₊ : ℝ) + 1 ≤ n := by exact_mod_cast hn
        have hc1 := Nat.le_ceil |x|
        have hax := neg_abs_le x
        have hxa := le_abs_self x
        have hp := hpos n
        have h1 := hle1 n
        refine (hbound n x).2 ?_ ?_
        · simp only [ha]; linarith
        · rw [hmh n]; simp only [ha]; linarith
      exact tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
        ((hcont.tendsto x).comp ht) (hev.mono fun n hn => hn.1) (hev.mono fun n hn => hn.2)
    have Tμ := tendsto_integral_of_dominated_convergence (μ := μ) (F := V) (f := u) _
      (fun n => (hcone n).1.aestronglyMeasurable) (hGint μ hiμ hμ)
      (fun n => ae_of_all _ (hG n)) (ae_of_all _ hlim)
    have Tν := tendsto_integral_of_dominated_convergence (μ := ν) (F := V) (f := u) _
      (fun n => (hcone n).2.1.aestronglyMeasurable) (hGint ν hiν hν)
      (fun n => ae_of_all _ (hG n)) (ae_of_all _ hlim)
    exact le_of_tendsto_of_tendsto' Tν Tμ hcmp

/-- The shortfall is the area under the CDF: the average amount `E[(k - A)⁺]` by which a fund
falls short of a cutoff `k` equals `∫_{-∞}^{k} F_A(t) dt`. -/
theorem shortfall_eq_integral_cdf (μ : Measure ℝ) [IsProbabilityMeasure μ] (k : ℝ) :
    ∫ x, max (k - x) 0 ∂μ = ∫ t in Set.Iic k, cdf μ t := by
  rw [integral_eq_lintegral_of_nonneg_ae (f := fun x => max (k - x) 0) (Filter.Eventually.of_forall fun x => le_max_right _ _)
    (by fun_prop),
    integral_eq_lintegral_of_nonneg_ae (f := fun t => cdf μ t) (Filter.Eventually.of_forall fun x => cdf_nonneg μ x)
    ((monotone_cdf μ).measurable.aestronglyMeasurable), sd_shortfall_lintegral]

/-! The card's three funds, as lists of (return in percent, probability). -/

/-- Chance that a finite fund ends at or below `t`. -/
def fundCdf (f : List (ℚ × ℚ)) (t : ℚ) : ℚ :=
  ((f.filter fun p => p.1 ≤ t).map Prod.snd).sum

/-- Average shortfall `E[(k - X)⁺]` of a finite fund below the cutoff `k`. -/
def fundShortfall (f : List (ℚ × ℚ)) (k : ℚ) : ℚ :=
  (f.map fun p => p.2 * max (k - p.1) 0).sum

/-- Average utility `E[u(X)]` of a finite fund. -/
def fundAvg (f : List (ℚ × ℚ)) (u : ℚ → ℚ) : ℚ :=
  (f.map fun p => p.2 * u p.1).sum

def steady : List (ℚ × ℚ) := [(2, 1)]
def swing : List (ℚ × ℚ) := [(-2, 1/2), (6, 1/2)]
def upside : List (ℚ × ℚ) := [(-2, 1/2), (8, 1/2)]

-- Means: Steady 2, Swing 2, Upside 3.
example : fundAvg steady id = 2 ∧ fundAvg swing id = 2 ∧ fundAvg upside id = 3 := by
  norm_num [fundAvg, steady, swing, upside]

-- Upside vs Swing, CDFs at -2, 2, 6, 8: Upside 1/2, 1/2, 1/2, 1 against Swing 1/2, 1/2, 1, 1.
example : [fundCdf upside (-2), fundCdf upside 2, fundCdf upside 6, fundCdf upside 8] = [1/2, 1/2, 1/2, 1] ∧
    [fundCdf swing (-2), fundCdf swing 2, fundCdf swing 6, fundCdf swing 8] = [1/2, 1/2, 1, 1] := by
  norm_num [fundCdf, upside, swing]

-- Steady vs Swing, CDF at 2: Steady 1 against Swing 1/2, so first order fails.
example : fundCdf steady 2 = 1 ∧ fundCdf swing 2 = 1/2 := by
  norm_num [fundCdf, steady, swing]

-- Steady vs Swing, shortfalls at -2, 2, 6, 8: Steady 0, 0, 4, 6 against Swing 0, 2, 4, 6.
example : [fundShortfall steady (-2), fundShortfall steady 2, fundShortfall steady 6, fundShortfall steady 8] = [0, 0, 4, 6] ∧
    [fundShortfall swing (-2), fundShortfall swing 2, fundShortfall swing 6, fundShortfall swing 8] = [0, 2, 4, 6] := by
  norm_num [fundShortfall, steady, swing]

-- Steady vs Upside: shortfall at 2 is 0 against 2, at 8 is 6 against 5, so neither dominates.
example : fundShortfall steady 2 = 0 ∧ fundShortfall upside 2 = 2 ∧
    fundShortfall steady 8 = 6 ∧ fundShortfall upside 8 = 5 := by
  norm_num [fundShortfall, steady, upside]

-- Swing's shortfall at 4 is 3, the same as the area under its CDF: 1/2 × 6.
example : fundShortfall swing 4 = 3 ∧ fundCdf swing 4 * (4 - (-2)) = 3 := by
  norm_num [fundShortfall, fundCdf, swing]

-- Two risk-averse witnesses disagree: capped at 2, Steady 2 against Upside 0; linear, Steady 2 against Upside 3.
example : fundAvg steady (fun r => min r 2) = 2 ∧ fundAvg upside (fun r => min r 2) = 0 ∧
    fundAvg steady id = 2 ∧ fundAvg upside id = 3 := by
  norm_num [fundAvg, steady, upside]

#print axioms first_order_dominance_iff_cdf_le
#print axioms second_order_dominance_iff_shortfall_le
#print axioms shortfall_eq_integral_cdf
