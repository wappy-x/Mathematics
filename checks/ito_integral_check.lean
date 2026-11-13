-- The Ito integral: for a bounded simple strategy held against a Brownian motion, the sum of holding times price move has mean square equal to the average squared holding added over time (the isometry) and is a fair game (a martingale), and holding W itself gives half the final square less half the sum of squared moves.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Probability.ConditionalExpectation
import Mathlib.Probability.Independence.Integration
import Mathlib.Probability.Moments.Variance

open MeasureTheory ProbabilityTheory
open scoped NNReal

/-! Setting, as on the card. `B : ℝ≥0 → Ω → ℝ` is a Brownian motion (Mathlib's `IsBrownianReal`)
for the filtration `ℱ` (what is known by each time): `B t` is fixed by `ℱ t`, and every later move
`B u - B s` is independent of `ℱ s`. A simple strategy trades at the times
`0 = t 0 < t 1 < ... < t n = T` and holds `H k` shares on the stretch from `t k` to `t (k+1)`;
`H k` is fixed by `ℱ (t k)` and bounded by one constant `c`. -/

/-- The simple strategy as a function of time: `H k` shares on the stretch `[t k, t (k+1))`,
none outside `[0, T)`. -/
noncomputable def simpleHolding {Ω : Type*} {n : ℕ} (t : Fin (n + 1) → ℝ≥0) (H : Fin n → Ω → ℝ)
    (s : ℝ) (ω : Ω) : ℝ :=
  ∑ k : Fin n, Set.indicator (Set.Ico ((t k.castSucc : ℝ)) ((t k.succ : ℝ))) (fun _ => H k ω) s

/-- The Ito integral of a simple strategy, stopped at time `r`:
`I_r = ∑ H k (B (min (t (k+1)) r) - B (min (t k) r))`. At `r = T` it is the full sum
`∑ H k (B (t (k+1)) - B (t k))`. -/
noncomputable def simpleItoIntegral {Ω : Type*} {n : ℕ} (B : ℝ≥0 → Ω → ℝ)
    (t : Fin (n + 1) → ℝ≥0) (H : Fin n → Ω → ℝ) (r : ℝ≥0) (ω : Ω) : ℝ :=
  ∑ k : Fin n, H k ω * (B (min (t k.succ) r) ω - B (min (t k.castSucc) r) ω)

lemma ito_inc_hasLaw {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ}
    (hB : IsBrownianReal B P) (a b : ℝ≥0) :
    HasLaw (fun ω => B b ω - B a ω) (gaussianReal 0 (nndist (b : ℝ) (a : ℝ))) P :=
  hB.hasLaw_sub b a

#print axioms ito_inc_hasLaw

lemma ito_inc_memLp {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ}
    (hB : IsBrownianReal B P) (a b : ℝ≥0) :
    MemLp (fun ω => B b ω - B a ω) 2 P :=
  (ito_inc_hasLaw hB a b).memLp (memLp_id_gaussianReal' 2 (by simp))

#print axioms ito_inc_memLp

lemma ito_inc_integrable {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    [IsProbabilityMeasure P] {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (a b : ℝ≥0) :
    Integrable (fun ω => B b ω - B a ω) P :=
  (ito_inc_memLp hB a b).integrable (by norm_num)

#print axioms ito_inc_integrable

lemma ito_inc_integral {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) (a b : ℝ≥0) :
    ∫ ω, (B b ω - B a ω) ∂P = 0 := by
  rw [(ito_inc_hasLaw hB a b).integral_eq, integral_id_gaussianReal]

#print axioms ito_inc_integral

lemma ito_inc_sq_integral {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {B : ℝ≥0 → Ω → ℝ} (hB : IsBrownianReal B P) {a b : ℝ≥0} (hab : a ≤ b) :
    ∫ ω, (B b ω - B a ω) ^ 2 ∂P = (b : ℝ) - a := by
  have h := ito_inc_hasLaw hB a b
  rw [← variance_of_integral_eq_zero h.aemeasurable (ito_inc_integral hB a b), h.variance_eq,
    variance_id_gaussianReal, coe_nndist, Real.dist_eq, abs_of_nonneg (by simpa using hab)]

#print axioms ito_inc_sq_integral

lemma ito_indepFun {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    (ℱ : Filtration ℝ≥0 mΩ) (B : ℝ≥0 → Ω → ℝ)
    (hBindep : ∀ s u : ℝ≥0, s ≤ u →
      Indep (MeasurableSpace.comap (fun ω => B u ω - B s ω) (inferInstance : MeasurableSpace ℝ))
        (ℱ s) P)
    {s u : ℝ≥0} (hsu : s ≤ u) {X : Ω → ℝ} (hX : Measurable[ℱ s] X) :
    IndepFun X (fun ω => B u ω - B s ω) P := by
  rw [IndepFun_iff_Indep]
  exact indep_of_indep_of_le_left (hBindep s u hsu).symm hX.comap_le

#print axioms ito_indepFun

lemma ito_condExp_mul_inc_eq_zero {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (B : ℝ≥0 → Ω → ℝ)
    (hB : IsBrownianReal B P) (hBadapted : Adapted ℱ B)
    (hBindep : ∀ s u : ℝ≥0, s ≤ u →
      Indep (MeasurableSpace.comap (fun ω => B u ω - B s ω) (inferInstance : MeasurableSpace ℝ))
        (ℱ s) P)
    {s a b : ℝ≥0} (hsa : s ≤ a) (hab : a ≤ b) {X : Ω → ℝ}
    (hX : Measurable[ℱ a] X) (c : ℝ) (hc : ∀ ω, |X ω| ≤ c) :
    P[(fun ω => X ω * (B b ω - B a ω)) | ℱ s] =ᵐ[P] 0 := by
  have hBm : ∀ r, Measurable (B r) := fun r => (hBadapted r).mono (ℱ.le r) le_rfl
  have hD : Measurable (fun ω => B b ω - B a ω) := (hBm b).sub (hBm a)
  have h1 : P[(fun ω => X ω * (B b ω - B a ω)) | ℱ a] =ᵐ[P] 0 := by
    have h2 := condExp_stronglyMeasurable_mul_of_bound (ℱ.le a) hX.stronglyMeasurable
      (ito_inc_integrable hB a b) c
      (Filter.Eventually.of_forall fun ω => by simpa [Real.norm_eq_abs] using hc ω)
    have h3 : P[(fun ω => B b ω - B a ω) | ℱ a] =ᵐ[P] fun _ => P[(fun ω => B b ω - B a ω)] :=
      condExp_indep_eq hD.comap_le (ℱ.le a) (comap_measurable _).stronglyMeasurable
        (hBindep a b hab)
    rw [ito_inc_integral hB a b] at h3
    filter_upwards [h2, h3] with ω h2 h3
    rw [show (fun ω => X ω * (B b ω - B a ω)) = X * (fun ω => B b ω - B a ω) from rfl, h2]
    simp [h3]
  refine (condExp_condExp_of_le (ℱ.mono hsa) (ℱ.le a)).symm.trans ?_
  refine (condExp_congr_ae h1).trans ?_
  rw [condExp_zero]

#print axioms ito_condExp_mul_inc_eq_zero

lemma ito_condExp_sum_eq_zero {Ω : Type*} {m mΩ : MeasurableSpace Ω} {P : Measure Ω}
    {ι : Type*} (s : Finset ι) (f : ι → Ω → ℝ)
    (hint : ∀ i, Integrable (f i) P) (h0 : ∀ i, P[f i | m] =ᵐ[P] 0) :
    P[(fun ω => ∑ i ∈ s, f i ω) | m] =ᵐ[P] 0 := by
  classical
  induction s using Finset.induction_on with
  | empty => simp; rfl
  | insert a s ha ih =>
    simp only [Finset.sum_insert ha]
    have : (fun ω => f a ω + ∑ i ∈ s, f i ω) = f a + fun ω => ∑ i ∈ s, f i ω := rfl
    rw [this]
    refine (condExp_add (hint a) (integrable_finsetSum s fun i _ => hint i) m).trans ?_
    filter_upwards [h0 a, ih] with ω h1 h2
    simp [h1, h2]

#print axioms ito_condExp_sum_eq_zero

lemma ito_intervalIntegral_indicator_Ico {a b T v : ℝ} (h0 : 0 ≤ a) (hab : a ≤ b)
    (hbT : b ≤ T) :
    ∫ s in (0 : ℝ)..T, Set.indicator (Set.Ico a b) (fun _ => v) s = v * (b - a) := by
  rw [intervalIntegral.integral_of_le (h0.trans (hab.trans hbT)), ← integral_Icc_eq_integral_Ioc,
    setIntegral_indicator measurableSet_Ico,
    Set.inter_eq_right.mpr (Set.Ico_subset_Icc_self.trans (Set.Icc_subset_Icc h0 hbT)),
    setIntegral_const]
  simp [hab, mul_comm]

#print axioms ito_intervalIntegral_indicator_Ico

lemma ito_term_clamp {Ω : Type*} (B : ℝ≥0 → Ω → ℝ) (a b r : ℝ≥0) (hab : a ≤ b) (h : ℝ)
    (ω : Ω) :
    h * (B (min b r) ω - B (min a r) ω) = h * (B (min b (max r a)) ω - B a ω) := by
  rcases le_total r a with hra | hra
  · rw [min_eq_right (hra.trans hab), min_eq_right hra, max_eq_right hra, min_eq_right hab]
    simp
  · rw [min_eq_left hra, max_eq_left hra]

#print axioms ito_term_clamp

lemma ito_simpleHolding_sq {Ω : Type*} {n : ℕ} (t : Fin (n + 1) → ℝ≥0) (ht : StrictMono t)
    (H : Fin n → Ω → ℝ) (s : ℝ) (ω : Ω) :
    (simpleHolding t H s ω) ^ 2 = ∑ k : Fin n,
      Set.indicator (Set.Ico ((t k.castSucc : ℝ)) ((t k.succ : ℝ))) (fun _ => H k ω ^ 2) s := by
  unfold simpleHolding
  by_cases hs : ∃ k : Fin n, s ∈ Set.Ico ((t k.castSucc : ℝ)) ((t k.succ : ℝ))
  · obtain ⟨k, hk⟩ := hs
    have hother : ∀ j : Fin n, j ≠ k → s ∉ Set.Ico ((t j.castSucc : ℝ)) ((t j.succ : ℝ)) := by
      intro j hjk hj
      rcases lt_or_gt_of_ne hjk with h | h
      · have : t j.succ ≤ t k.castSucc := ht.monotone (Fin.succ_le_castSucc_iff.mpr h)
        have : (t j.succ : ℝ) ≤ t k.castSucc := by exact_mod_cast this
        linarith [hj.2, hk.1]
      · have : t k.succ ≤ t j.castSucc := ht.monotone (Fin.succ_le_castSucc_iff.mpr h)
        have : (t k.succ : ℝ) ≤ t j.castSucc := by exact_mod_cast this
        linarith [hj.1, hk.2]
    rw [Finset.sum_eq_single k (fun j _ hjk => Set.indicator_of_notMem (hother j hjk) _)
        (by simp),
      Finset.sum_eq_single k (fun j _ hjk => Set.indicator_of_notMem (hother j hjk) _)
        (by simp),
      Set.indicator_of_mem hk, Set.indicator_of_mem hk]
  · push Not at hs
    rw [Finset.sum_eq_zero (fun j _ => Set.indicator_of_notMem (hs j) _),
      Finset.sum_eq_zero (fun j _ => Set.indicator_of_notMem (hs j) _)]
    simp

#print axioms ito_simpleHolding_sq

/-- **The Ito isometry for simple strategies.** For a bounded simple strategy, each holding fixed
before the Brownian move it multiplies, the average of the squared Ito integral
`I_T = ∑ H k (W (t (k+1)) - W (t k))` equals the average of the squared holding added up over
time: `E[I_T^2] = E[∫_0^T H_t^2 dt]`. -/
theorem ito_isometry_simple_strategy {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (B : ℝ≥0 → Ω → ℝ)
    (hB : IsBrownianReal B P) (hBadapted : Adapted ℱ B)
    (hBindep : ∀ s u : ℝ≥0, s ≤ u →
      Indep (MeasurableSpace.comap (fun ω => B u ω - B s ω) (inferInstance : MeasurableSpace ℝ))
        (ℱ s) P)
    (n : ℕ) (t : Fin (n + 1) → ℝ≥0) (ht0 : t 0 = 0) (ht : StrictMono t)
    (H : Fin n → Ω → ℝ) (hH : ∀ k : Fin n, Measurable[ℱ (t k.castSucc)] (H k))
    (c : ℝ) (hc : ∀ k ω, |H k ω| ≤ c) :
    ∫ ω, (∑ k : Fin n, H k ω * (B (t k.succ) ω - B (t k.castSucc) ω)) ^ 2 ∂P
      = ∫ ω, (∫ s in (0 : ℝ)..((t (Fin.last n) : ℝ)), (simpleHolding t H s ω) ^ 2) ∂P := by
  have hlt : ∀ k : Fin n, t k.castSucc < t k.succ := fun k => ht Fin.castSucc_lt_succ
  have hHm : ∀ k, Measurable (H k) := fun k => (hH k).mono (ℱ.le _) le_rfl
  have hBm : ∀ r, Measurable (B r) := fun r => (hBadapted r).mono (ℱ.le r) le_rfl
  -- the right side, path by path
  have hR : ∀ ω, ∫ s in (0 : ℝ)..((t (Fin.last n) : ℝ)), (simpleHolding t H s ω) ^ 2
      = ∑ k : Fin n, H k ω ^ 2 * ((t k.succ : ℝ) - t k.castSucc) := by
    intro ω
    simp_rw [ito_simpleHolding_sq t ht H _ ω]
    rw [intervalIntegral.integral_finsetSum]
    · refine Finset.sum_congr rfl fun k _ => ?_
      exact ito_intervalIntegral_indicator_Ico (by positivity)
        (by exact_mod_cast (hlt k).le)
        (by exact_mod_cast ht.monotone (Fin.le_last _))
    · intro k _
      refine IntegrableOn.intervalIntegrable ?_
      exact (integrableOn_const (by simp)).indicator measurableSet_Ico
  have hHsq : ∀ k, Integrable (fun ω => H k ω ^ 2) P := fun k =>
    Integrable.of_bound ((hHm k).pow_const 2).aestronglyMeasurable (c ^ 2)
      (Filter.Eventually.of_forall fun ω => by
        rw [Real.norm_eq_abs, abs_pow]
        exact pow_le_pow_left₀ (abs_nonneg _) (hc k ω) 2)
  simp_rw [hR]
  rw [integral_finsetSum _ (fun k _ => (hHsq k).mul_const _)]
  simp_rw [integral_mul_const]
  -- the left side
  obtain ⟨a, ha⟩ : ∃ a : Fin n → Ω → ℝ,
      a = fun k ω => H k ω * (B (t k.succ) ω - B (t k.castSucc) ω) := ⟨_, rfl⟩
  have hL : ∀ ω, (∑ k : Fin n, H k ω * (B (t k.succ) ω - B (t k.castSucc) ω)) ^ 2
      = ∑ j : Fin n, ∑ k : Fin n, a j ω * a k ω := by
    intro ω; rw [sq, Finset.sum_mul_sum, ha]
  simp_rw [hL]
  have hint2 : ∀ j k, Integrable (fun ω => a j ω * a k ω) P := by
    intro j k
    have h1 : Integrable (fun ω => (B (t j.succ) ω - B (t j.castSucc) ω)
        * (B (t k.succ) ω - B (t k.castSucc) ω)) P :=
      (ito_inc_memLp hB _ _).integrable_mul (ito_inc_memLp hB _ _)
    have h2 := h1.bdd_mul (c := c * c) ((hHm j).mul (hHm k)).aestronglyMeasurable
      (Filter.Eventually.of_forall fun ω => by
        rw [Real.norm_eq_abs, Pi.mul_apply, abs_mul]
        exact mul_le_mul (hc j ω) (hc k ω) (abs_nonneg _) ((abs_nonneg _).trans (hc j ω)))
    refine h2.congr (Filter.Eventually.of_forall fun ω => ?_)
    simp only [ha, Pi.mul_apply]
    ring
  rw [integral_finsetSum _ (fun j _ => integrable_finsetSum _ fun k _ => hint2 j k)]
  simp_rw [integral_finsetSum _ (fun k _ => hint2 _ k)]
  -- cross terms vanish
  have hcross : ∀ j k : Fin n, j < k → ∫ ω, a j ω * a k ω ∂P = 0 := by
    intro j k hjk
    have hle : t j.succ ≤ t k.castSucc := ht.monotone (Fin.succ_le_castSucc_iff.mpr hjk)
    have hle' : t j.castSucc ≤ t k.castSucc := ht.monotone (Fin.castSucc_le_castSucc_iff.mpr hjk.le)
    have hX : Measurable[ℱ (t k.castSucc)] (fun ω => a j ω * H k ω) := by
      rw [ha]
      exact (((hH j).mono (ℱ.mono hle') le_rfl).mul
        (((hBadapted _).mono (ℱ.mono hle) le_rfl).sub
          ((hBadapted _).mono (ℱ.mono hle') le_rfl))).mul (hH k)
    have heq : (fun ω => a j ω * a k ω)
        = fun ω => (a j ω * H k ω) * (B (t k.succ) ω - B (t k.castSucc) ω) := by
      funext ω; rw [ha]; ring
    rw [heq, (ito_indepFun ℱ B hBindep (hlt k).le hX).integral_fun_mul_eq_mul_integral
      (hX.mono (ℱ.le _) le_rfl).aestronglyMeasurable
      (ito_inc_integrable hB _ _).aestronglyMeasurable, ito_inc_integral hB, mul_zero]
  have hdiag : ∀ k : Fin n, ∫ ω, a k ω * a k ω ∂P
      = (∫ ω, H k ω ^ 2 ∂P) * ((t k.succ : ℝ) - t k.castSucc) := by
    intro k
    have hX : Measurable[ℱ (t k.castSucc)] (fun ω => H k ω ^ 2) := (hH k).pow_const 2
    have hind := (ito_indepFun ℱ B hBindep (hlt k).le hX).comp measurable_id
      (measurable_id.pow_const 2 : Measurable fun x : ℝ => x ^ 2)
    have heq : (fun ω => a k ω * a k ω)
        = fun ω => (H k ω ^ 2) * (B (t k.succ) ω - B (t k.castSucc) ω) ^ 2 := by
      funext ω; rw [ha]; ring
    rw [heq]
    have := hind.integral_fun_mul_eq_mul_integral
      ((hX.mono (ℱ.le _) le_rfl).aestronglyMeasurable)
      (((hBm _).sub (hBm _)).pow_const 2).aestronglyMeasurable
    simp only [Function.comp_def, id] at this
    rw [this, ito_inc_sq_integral hB (hlt k).le]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [Finset.sum_eq_single j]
  · exact hdiag j
  · intro k _ hkj
    rcases lt_or_gt_of_ne hkj with h | h
    · rw [show (fun ω => a j ω * a k ω) = fun ω => a k ω * a j ω from funext fun ω => mul_comm _ _]
      exact hcross k j h
    · exact hcross j k h
  · simp

/-- **The martingale property for simple strategies.** For a bounded simple strategy against a
Brownian motion, the Ito integral stopped at each time is a martingale for the filtration: for any
earlier time `s`, `E[I_T | ℱ_s] = I_s`. In particular the average gain is zero, `E[I_T] = 0`. -/
theorem simple_ito_integral_is_martingale {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (B : ℝ≥0 → Ω → ℝ)
    (hB : IsBrownianReal B P) (hBadapted : Adapted ℱ B)
    (hBindep : ∀ s u : ℝ≥0, s ≤ u →
      Indep (MeasurableSpace.comap (fun ω => B u ω - B s ω) (inferInstance : MeasurableSpace ℝ))
        (ℱ s) P)
    (n : ℕ) (t : Fin (n + 1) → ℝ≥0) (ht0 : t 0 = 0) (ht : StrictMono t)
    (H : Fin n → Ω → ℝ) (hH : ∀ k : Fin n, Measurable[ℱ (t k.castSucc)] (H k))
    (c : ℝ) (hc : ∀ k ω, |H k ω| ≤ c) :
    Martingale (simpleItoIntegral B t H) ℱ P ∧
      ∫ ω, (∑ k : Fin n, H k ω * (B (t k.succ) ω - B (t k.castSucc) ω)) ∂P = 0 := by
  have hlt : ∀ k : Fin n, t k.castSucc < t k.succ := fun k => ht Fin.castSucc_lt_succ
  have hHm : ∀ k, Measurable (H k) := fun k => (hH k).mono (ℱ.le _) le_rfl
  have hterm : ∀ (k : Fin n) (x y : ℝ≥0),
      Integrable (fun ω => H k ω * (B x ω - B y ω)) P := fun k x y =>
    (ito_inc_integrable hB y x).bdd_mul (hHm k).aestronglyMeasurable
      (Filter.Eventually.of_forall fun ω => by simpa [Real.norm_eq_abs] using hc k ω)
  obtain ⟨g, hg⟩ : ∃ g : Fin n → ℝ≥0 → ℝ≥0, g = fun k r => min (t k.succ) (max r (t k.castSucc)) :=
    ⟨_, rfl⟩
  have hI : ∀ r ω, simpleItoIntegral B t H r ω
      = ∑ k, H k ω * (B (g k r) ω - B (t k.castSucc) ω) := by
    intro r ω
    unfold simpleItoIntegral
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [hg]
    exact ito_term_clamp B _ _ r (hlt k).le _ ω
  have hIfun : ∀ r, simpleItoIntegral B t H r
      = fun ω => ∑ k, H k ω * (B (g k r) ω - B (t k.castSucc) ω) := fun r => funext (hI r)
  have hint : ∀ r, Integrable (simpleItoIntegral B t H r) P := by
    intro r
    rw [hIfun r]
    exact integrable_finsetSum _ fun k _ => hterm k _ _
  have hadapt : StronglyAdapted ℱ (simpleItoIntegral B t H) := by
    intro r
    rw [hIfun r]
    refine Measurable.stronglyMeasurable ?_
    refine Finset.measurable_fun_sum _ fun k _ => ?_
    by_cases hk : t k.castSucc ≤ r
    · have h1 : Measurable[ℱ r] (H k) := (hH k).mono (ℱ.mono hk) le_rfl
      have hgr : g k r ≤ r := by
        rw [hg]; exact min_le_of_right_le (max_le le_rfl hk)
      have h2 : Measurable[ℱ r] (B (g k r)) := (hBadapted _).mono (ℱ.mono hgr) le_rfl
      have h3 : Measurable[ℱ r] (B (t k.castSucc)) := (hBadapted _).mono (ℱ.mono hk) le_rfl
      exact h1.mul (h2.sub h3)
    · have hgk : g k r = t k.castSucc := by
        rw [hg]
        simp only
        rw [max_eq_right (not_le.mp hk).le, min_eq_right (hlt k).le]
      simp only [hgk, sub_self, mul_zero]
      exact measurable_const
  refine ⟨⟨hadapt, fun i j hij => ?_⟩, ?_⟩
  · have hdiff : simpleItoIntegral B t H j = simpleItoIntegral B t H i
        + fun ω => ∑ k, H k ω * (B (g k j) ω - B (g k i) ω) := by
      funext ω
      simp only [Pi.add_apply, hI]
      rw [← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun k _ => ?_
      ring
    have hD0 : ∀ k, P[(fun ω => H k ω * (B (g k j) ω - B (g k i) ω)) | ℱ i] =ᵐ[P] 0 := by
      intro k
      by_cases hcase : i ≤ g k i
      · have hmono : g k i ≤ g k j := by
          rw [hg]; exact min_le_min le_rfl (max_le_max hij le_rfl)
        have hta : t k.castSucc ≤ g k i := by
          rw [hg]; exact le_min (hlt k).le (le_max_right _ _)
        exact ito_condExp_mul_inc_eq_zero ℱ B hB hBadapted hBindep hcase hmono
          ((hH k).mono (ℱ.mono hta) le_rfl) c (hc k)
      · have h1 : t k.succ < i := by
          by_contra hcon
          rw [not_lt] at hcon
          apply hcase
          rw [hg]
          exact le_min hcon (le_max_left _ _)
        have hgi : g k i = t k.succ := by
          rw [hg]; exact min_eq_left (h1.le.trans (le_max_left _ _))
        have hgj : g k j = t k.succ := by
          rw [hg]; exact min_eq_left ((h1.le.trans hij).trans (le_max_left _ _))
        have : (fun ω => H k ω * (B (g k j) ω - B (g k i) ω)) = 0 := by
          funext ω; simp [hgi, hgj]
        rw [this, condExp_zero]
    rw [hdiff]
    refine (condExp_add (hint i) (integrable_finsetSum _ fun k _ => hterm k _ _) _).trans ?_
    rw [condExp_of_stronglyMeasurable (ℱ.le i) (hadapt i) (hint i)]
    filter_upwards [ito_condExp_sum_eq_zero (m := ℱ i) Finset.univ _ (fun k => hterm k _ _) hD0]
      with ω hω
    simp [hω]
  · rw [integral_finsetSum _ (fun k _ => hterm k _ _)]
    refine Finset.sum_eq_zero fun k _ => ?_
    rw [(ito_indepFun ℱ B hBindep (hlt k).le (hH k)).integral_fun_mul_eq_mul_integral
      (hHm k).aestronglyMeasurable (ito_inc_integrable hB _ _).aestronglyMeasurable,
      ito_inc_integral hB, mul_zero]

/-- **Step 5's identity, with nothing random in it.** For any path values `w 0, ..., w n` starting
at `w 0 = 0`, holding `w k` over each stretch earns half the final square less half the sum of
squared moves: `∑ w_k (w_{k+1} - w_k) = w_n^2 / 2 - (1/2) ∑ (w_{k+1} - w_k)^2`. -/
theorem left_sum_eq_half_square_sub_half_quadratic_variation (n : ℕ) (w : ℕ → ℝ) (hw0 : w 0 = 0) :
    ∑ k ∈ Finset.range n, w k * (w (k + 1) - w k)
      = w n ^ 2 / 2 - (1 / 2) * ∑ k ∈ Finset.range n, (w (k + 1) - w k) ^ 2 := by
  induction n with
  | zero => simp [hw0]
  | succ n ih =>
    rw [Finset.sum_range_succ, Finset.sum_range_succ, ih]
    ring

/-! The card's exact worked numbers. -/

-- Half-year rule, first half: 2 shares squared times half a year is 2.
example : (2 : ℚ) ^ 2 * (1 / 2) = 2 := by norm_num

-- Second half: chance 1/2 of holding 1 share, squared, times half a year is 1/4.
example : (1 / 2 : ℚ) * 1 ^ 2 * (1 / 2) = 1 / 4 := by norm_num

-- E[∫_0^1 H_t^2 dt] = 2 + 1/4 = 9/4.
example : (2 : ℚ) + 1 / 4 = 9 / 4 := by norm_num

-- Variance of the dollar gain G_1 = 20 I_1: 20^2 * 9/4 = 900.
example : (20 : ℚ) ^ 2 * (9 / 4) = 900 := by norm_num

-- Typical size of the gain: sqrt 900 = 30 dollars.
example : √(900 : ℝ) = 30 := by norm_num

-- Hold-the-excess strategy H_t = W_t: E[∫_0^1 W_t^2 dt] = 1/2, so the dollar variance is 400 * 1/2 = 200.
example : (400 : ℚ) * (1 / 2) = 200 := by norm_num

-- Step 5's second road: (3T^2 - 2T^2 + T^2) / 4 = T^2 / 2, at T = 1 year.
example : ((3 : ℚ) * 1 ^ 2 - 2 * 1 ^ 2 + 1 ^ 2) / 4 = 1 ^ 2 / 2 := by norm_num

-- The coin-toss check of the half-year rule with 2 steps: over the 4 paths, with first move a
-- and second move b (each +1 or -1), the gain in steps is 2a + (b if a > 0, else 0).
-- The 4 gains add to 0 (mean gain 0) ...
example : ((List.product [1, -1] [1, -1] : List (ℤ × ℤ)).map
    (fun p => 2 * p.1 + (if 0 < p.1 then p.2 else 0))).sum = 0 := by decide

-- ... and their squares add to 18, so E[I^2] = (1/2) * 18 / 4 = 9/4, the isometry value.
example : ((List.product [1, -1] [1, -1] : List (ℤ × ℤ)).map
    (fun p => (2 * p.1 + (if 0 < p.1 then p.2 else 0)) ^ 2)).sum = 18 := by decide

example : (1 / 2 : ℚ) * 18 / 4 = 9 / 4 := by norm_num

#print axioms ito_isometry_simple_strategy
#print axioms simple_ito_integral_is_martingale
#print axioms left_sum_eq_half_square_sub_half_quadratic_variation
