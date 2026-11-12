-- Finite elements: the Galerkin broken line built from hat functions is the closest broken line to the exact cable in the energy pairing, its matrix is tridiagonal with the card's entries, and with no load every broken line through the posts stores more energy than the cable.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Tactic

open intervalIntegral

/-- The hat function on node `i` of the mesh of `[0, 1]` with `n` elements, `h = 1 / n`:
1 at the node `x_i = i / n`, 0 at every other node, straight in between. -/
noncomputable def hat (n i : ℕ) (x : ℝ) : ℝ := max 0 (1 - |(n : ℝ) * x - i|)

/-- The energy pairing `a(u, v) = ∫₀¹ (u' v' + u v) dx`. -/
noncomputable def energyPairing (u v : ℝ → ℝ) : ℝ :=
  ∫ x in (0 : ℝ)..1, (deriv u x * deriv v x + u x * v x)

/-- The broken line through the posts `α` at `x = 0` and `β` at `x = 1`, with inside node
heights `U 1, ..., U (n - 1)`: `α φ_0 + Σ U_i φ_i + β φ_n`. -/
noncomputable def brokenLine (n : ℕ) (α β : ℝ) (U : ℕ → ℝ) (x : ℝ) : ℝ :=
  α * hat n 0 x + (∑ i ∈ Finset.Ioo 0 n, U i * hat n i x) + β * hat n n x

/-- The mesh nodes `k / n`, where hats may have corners. -/
noncomputable def meshNodes (n : ℕ) : Set ℝ := Set.range (fun k : ℤ => (k : ℝ) / n)

lemma ae_not_meshNode (n : ℕ) : ∀ᵐ x ∂MeasureTheory.volume, x ∉ meshNodes n :=
  (Set.countable_range _).ae_notMem _

lemma mul_ne_int_of_not_meshNode (n : ℕ) (hn : 0 < n) (x : ℝ) (hx : x ∉ meshNodes n) (k : ℤ) :
    (n : ℝ) * x ≠ k := by
  intro h
  apply hx
  refine ⟨k, ?_⟩
  have : (0 : ℝ) < n := by exact_mod_cast hn
  rw [div_eq_iff this.ne', ← h, mul_comm]

lemma hat_val_lo (n i : ℕ) (x : ℝ) (hx : (n : ℝ) * x ≤ (i : ℝ) - 1) : hat n i x = 0 := by
  unfold hat
  rw [abs_of_neg (by linarith)]
  exact max_eq_left (by linarith)

lemma hat_val_hi (n i : ℕ) (x : ℝ) (hx : (i : ℝ) + 1 ≤ (n : ℝ) * x) : hat n i x = 0 := by
  unfold hat
  rw [abs_of_pos (by linarith)]
  exact max_eq_left (by linarith)

lemma hat_val_up (n i : ℕ) (x : ℝ) (h1 : (i : ℝ) - 1 ≤ (n : ℝ) * x) (h2 : (n : ℝ) * x ≤ i) :
    hat n i x = (n : ℝ) * x - i + 1 := by
  unfold hat
  rw [abs_of_nonpos (by linarith), max_eq_right (by linarith)]
  ring

lemma hat_val_down (n i : ℕ) (x : ℝ) (h1 : (i : ℝ) ≤ (n : ℝ) * x) (h2 : (n : ℝ) * x ≤ i + 1) :
    hat n i x = i + 1 - (n : ℝ) * x := by
  unfold hat
  rw [abs_of_nonneg (by linarith), max_eq_right (by linarith)]
  ring

lemma hat_hasDerivAt_lo (n i : ℕ) (x : ℝ) (hx : (n : ℝ) * x < (i : ℝ) - 1) :
    HasDerivAt (hat n i) 0 x := by
  have hopen : IsOpen {t : ℝ | (n : ℝ) * t < (i : ℝ) - 1} :=
    isOpen_lt (continuous_const.mul continuous_id) continuous_const
  apply (hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq
  filter_upwards [hopen.mem_nhds hx] with t ht
  exact hat_val_lo n i t (le_of_lt ht)

lemma hat_hasDerivAt_hi (n i : ℕ) (x : ℝ) (hx : (i : ℝ) + 1 < (n : ℝ) * x) :
    HasDerivAt (hat n i) 0 x := by
  have hopen : IsOpen {t : ℝ | (i : ℝ) + 1 < (n : ℝ) * t} :=
    isOpen_lt continuous_const (continuous_const.mul continuous_id)
  apply (hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq
  filter_upwards [hopen.mem_nhds hx] with t ht
  exact hat_val_hi n i t (le_of_lt ht)

lemma hat_hasDerivAt_up (n i : ℕ) (x : ℝ) (h1 : (i : ℝ) - 1 < (n : ℝ) * x) (h2 : (n : ℝ) * x < i) :
    HasDerivAt (hat n i) n x := by
  have hopen : IsOpen {t : ℝ | (i : ℝ) - 1 < (n : ℝ) * t ∧ (n : ℝ) * t < i} :=
    (isOpen_lt continuous_const (continuous_const.mul continuous_id)).inter (isOpen_lt (continuous_const.mul continuous_id) continuous_const)
  have hd : HasDerivAt (fun t : ℝ => (n : ℝ) * t - i + 1) n x := by
    simpa using (((hasDerivAt_id x).const_mul (n : ℝ)).sub_const (i : ℝ)).add_const (1 : ℝ)
  apply hd.congr_of_eventuallyEq
  filter_upwards [hopen.mem_nhds ⟨h1, h2⟩] with t ht
  exact hat_val_up n i t (le_of_lt ht.1) (le_of_lt ht.2)

lemma hat_hasDerivAt_down (n i : ℕ) (x : ℝ) (h1 : (i : ℝ) < (n : ℝ) * x)
    (h2 : (n : ℝ) * x < i + 1) : HasDerivAt (hat n i) (-n) x := by
  have hopen : IsOpen {t : ℝ | (i : ℝ) < (n : ℝ) * t ∧ (n : ℝ) * t < i + 1} :=
    (isOpen_lt continuous_const (continuous_const.mul continuous_id)).inter (isOpen_lt (continuous_const.mul continuous_id) continuous_const)
  have hd : HasDerivAt (fun t : ℝ => (i : ℝ) + 1 - (n : ℝ) * t) (-n) x := by
    simpa using ((hasDerivAt_id x).const_mul (n : ℝ)).const_sub ((i : ℝ) + 1)
  apply hd.congr_of_eventuallyEq
  filter_upwards [hopen.mem_nhds ⟨h1, h2⟩] with t ht
  exact hat_val_down n i t (le_of_lt ht.1) (le_of_lt ht.2)

lemma hat_hasDerivAt_off (n i : ℕ) (hn : 0 < n) (x : ℝ) (hx : x ∉ meshNodes n) :
    ∃ D : ℝ, |D| ≤ n ∧ HasDerivAt (hat n i) D x := by
  have hnR : (0 : ℝ) ≤ n := by positivity
  have e1 := mul_ne_int_of_not_meshNode n hn x hx ((i : ℤ) - 1)
  have e2 := mul_ne_int_of_not_meshNode n hn x hx (i : ℤ)
  have e3 := mul_ne_int_of_not_meshNode n hn x hx ((i : ℤ) + 1)
  push_cast at e1 e2 e3
  rcases lt_or_gt_of_ne e1 with h1 | h1
  · exact ⟨0, by simp, hat_hasDerivAt_lo n i x h1⟩
  rcases lt_or_gt_of_ne e2 with h2 | h2
  · exact ⟨n, by rw [abs_of_nonneg hnR], hat_hasDerivAt_up n i x h1 h2⟩
  rcases lt_or_gt_of_ne e3 with h3 | h3
  · exact ⟨-n, by rw [abs_neg, abs_of_nonneg hnR], hat_hasDerivAt_down n i x h2 h3⟩
  · exact ⟨0, by simp, hat_hasDerivAt_hi n i x h3⟩

lemma hat_continuous (n i : ℕ) : Continuous (hat n i) := by
  unfold hat
  fun_prop

/-- Continuous, differentiable off the mesh nodes, with a bounded derivative on `[0, 1]`. -/
def Good (n : ℕ) (v : ℝ → ℝ) : Prop :=
  Continuous v ∧ (∀ x, x ∉ meshNodes n → DifferentiableAt ℝ v x) ∧
    ∃ C, ∀ x, x ∉ meshNodes n → x ∈ Set.Icc (0 : ℝ) 1 → |deriv v x| ≤ C

lemma good_hat (n i : ℕ) (hn : 0 < n) : Good n (hat n i) := by
  refine ⟨hat_continuous n i, fun x hx => ?_, n, fun x hx _ => ?_⟩
  · obtain ⟨D, -, hD⟩ := hat_hasDerivAt_off n i hn x hx
    exact hD.differentiableAt
  · obtain ⟨D, hDn, hD⟩ := hat_hasDerivAt_off n i hn x hx
    rw [hD.deriv]
    exact hDn

lemma good_add {n : ℕ} {u v : ℝ → ℝ} (hu : Good n u) (hv : Good n v) :
    Good n (fun x => u x + v x) := by
  obtain ⟨hu1, hu2, Cu, hCu⟩ := hu
  obtain ⟨hv1, hv2, Cv, hCv⟩ := hv
  refine ⟨hu1.add hv1, fun x hx => (hu2 x hx).add (hv2 x hx), Cu + Cv, fun x hx hI => ?_⟩
  rw [deriv_fun_add (hu2 x hx) (hv2 x hx)]
  exact (abs_add_le _ _).trans (add_le_add (hCu x hx hI) (hCv x hx hI))

lemma good_sub {n : ℕ} {u v : ℝ → ℝ} (hu : Good n u) (hv : Good n v) :
    Good n (fun x => u x - v x) := by
  obtain ⟨hu1, hu2, Cu, hCu⟩ := hu
  obtain ⟨hv1, hv2, Cv, hCv⟩ := hv
  refine ⟨hu1.sub hv1, fun x hx => (hu2 x hx).sub (hv2 x hx), Cu + Cv, fun x hx hI => ?_⟩
  rw [deriv_fun_sub (hu2 x hx) (hv2 x hx)]
  exact (abs_sub _ _).trans (add_le_add (hCu x hx hI) (hCv x hx hI))

lemma good_const_mul {n : ℕ} {u : ℝ → ℝ} (c : ℝ) (hu : Good n u) :
    Good n (fun x => c * u x) := by
  obtain ⟨hu1, hu2, Cu, hCu⟩ := hu
  refine ⟨continuous_const.mul hu1, fun x hx => (hu2 x hx).const_mul c, |c| * Cu,
    fun x hx hI => ?_⟩
  rw [deriv_const_mul_field', abs_mul]
  exact mul_le_mul_of_nonneg_left (hCu x hx hI) (abs_nonneg c)

lemma good_zero (n : ℕ) : Good n (fun _ => 0) :=
  ⟨continuous_const, fun _ _ => differentiableAt_const _, 0, fun x _ _ => by simp⟩

lemma good_sum {n : ℕ} (T : Finset ℕ) (c : ℕ → ℝ) (g : ℕ → ℝ → ℝ)
    (hg : ∀ i ∈ T, Good n (g i)) : Good n (fun x => ∑ i ∈ T, c i * g i x) := by
  induction T using Finset.induction_on with
  | empty => simpa using good_zero n
  | insert a s ha ih =>
    simp only [Finset.sum_insert ha]
    exact good_add (good_const_mul _ (hg a (Finset.mem_insert_self a s)))
      (ih (fun i hi => hg i (Finset.mem_insert_of_mem hi)))

lemma good_brokenLine (n : ℕ) (hn : 0 < n) (α β : ℝ) (U : ℕ → ℝ) :
    Good n (brokenLine n α β U) := by
  unfold brokenLine
  exact good_add (good_add (good_const_mul _ (good_hat n 0 hn))
    (good_sum _ _ _ (fun i _ => good_hat n i hn))) (good_const_mul _ (good_hat n n hn))

lemma good_of_contDiff (n : ℕ) (y : ℝ → ℝ) (hy : ContDiff ℝ 2 y) : Good n y := by
  have hc : Continuous (deriv y) := hy.continuous_deriv (by norm_num)
  obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn
    (hc.continuousOn (s := Set.Icc (0 : ℝ) 1))
  exact ⟨hy.continuous, fun x _ => (hy.differentiable (by norm_num)) x, C,
    fun x _ hI => by simpa [Real.norm_eq_abs] using hC x hI⟩

lemma intervalIntegrable_of_bound (n : ℕ) (g : ℝ → ℝ)
    (hg : MeasureTheory.AEStronglyMeasurable g MeasureTheory.volume) (C : ℝ)
    (hC : ∀ x, x ∉ meshNodes n → x ∈ Set.Icc (0 : ℝ) 1 → |g x| ≤ C) :
    IntervalIntegrable g MeasureTheory.volume 0 1 := by
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le zero_le_one]
  refine MeasureTheory.Measure.integrableOn_of_bounded (M := C) measure_Ioc_lt_top.ne hg ?_
  rw [MeasureTheory.ae_restrict_iff' measurableSet_Ioc]
  filter_upwards [ae_not_meshNode n] with x hx hxI
  rw [Real.norm_eq_abs]
  exact hC x hx (Set.Ioc_subset_Icc_self hxI)

lemma pair_integrable {n : ℕ} {u v : ℝ → ℝ} (hu : Good n u) (hv : Good n v) :
    IntervalIntegrable (fun x => deriv u x * deriv v x + u x * v x) MeasureTheory.volume 0 1 := by
  obtain ⟨hu1, hu2, Cu, hCu⟩ := hu
  obtain ⟨hv1, hv2, Cv, hCv⟩ := hv
  obtain ⟨Mu, hMu⟩ := isCompact_Icc.exists_bound_of_continuousOn
    (hu1.continuousOn (s := Set.Icc (0 : ℝ) 1))
  obtain ⟨Mv, hMv⟩ := isCompact_Icc.exists_bound_of_continuousOn
    (hv1.continuousOn (s := Set.Icc (0 : ℝ) 1))
  refine intervalIntegrable_of_bound n _ ?_ (Cu * Cv + Mu * Mv) fun x hx hI => ?_
  · exact (((measurable_deriv u).mul (measurable_deriv v)).add
      (hu1.measurable.mul hv1.measurable)).aestronglyMeasurable
  · have a1 := hCu x hx hI
    have a2 := hCv x hx hI
    have a3 : |u x| ≤ Mu := by simpa [Real.norm_eq_abs] using hMu x hI
    have a4 : |v x| ≤ Mv := by simpa [Real.norm_eq_abs] using hMv x hI
    calc |deriv u x * deriv v x + u x * v x|
        ≤ |deriv u x| * |deriv v x| + |u x| * |v x| := by
          rw [← abs_mul, ← abs_mul]; exact abs_add_le _ _
      _ ≤ Cu * Cv + Mu * Mv := add_le_add
          (mul_le_mul a1 a2 (abs_nonneg _) ((abs_nonneg _).trans a1))
          (mul_le_mul a3 a4 (abs_nonneg _) ((abs_nonneg _).trans a3))

lemma pair_comm (u v : ℝ → ℝ) : energyPairing u v = energyPairing v u := by
  unfold energyPairing
  congr 1
  funext x
  ring

lemma pair_add_left {n : ℕ} {u v w : ℝ → ℝ} (hu : Good n u) (hv : Good n v) (hw : Good n w) :
    energyPairing (fun x => u x + v x) w = energyPairing u w + energyPairing v w := by
  unfold energyPairing
  rw [← integral_add (pair_integrable hu hw) (pair_integrable hv hw)]
  apply integral_congr_ae
  filter_upwards [ae_not_meshNode n] with x hx _
  rw [deriv_fun_add (hu.2.1 x hx) (hv.2.1 x hx)]
  ring

lemma pair_sub_left {n : ℕ} {u v w : ℝ → ℝ} (hu : Good n u) (hv : Good n v) (hw : Good n w) :
    energyPairing (fun x => u x - v x) w = energyPairing u w - energyPairing v w := by
  unfold energyPairing
  rw [← integral_sub (pair_integrable hu hw) (pair_integrable hv hw)]
  apply integral_congr_ae
  filter_upwards [ae_not_meshNode n] with x hx _
  rw [deriv_fun_sub (hu.2.1 x hx) (hv.2.1 x hx)]
  ring

lemma pair_const_mul_left (c : ℝ) (u w : ℝ → ℝ) :
    energyPairing (fun x => c * u x) w = c * energyPairing u w := by
  unfold energyPairing
  rw [deriv_const_mul_field', ← integral_const_mul]
  congr 1
  funext x
  ring

lemma pair_add_right {n : ℕ} {u v w : ℝ → ℝ} (hu : Good n u) (hv : Good n v) (hw : Good n w) :
    energyPairing w (fun x => u x + v x) = energyPairing w u + energyPairing w v := by
  rw [pair_comm, pair_add_left hu hv hw, pair_comm u, pair_comm v]

lemma pair_sub_right {n : ℕ} {u v w : ℝ → ℝ} (hu : Good n u) (hv : Good n v) (hw : Good n w) :
    energyPairing w (fun x => u x - v x) = energyPairing w u - energyPairing w v := by
  rw [pair_comm, pair_sub_left hu hv hw, pair_comm u, pair_comm v]

lemma pair_sum_right {n : ℕ} {u : ℝ → ℝ} (hu : Good n u) (T : Finset ℕ) (c : ℕ → ℝ)
    (g : ℕ → ℝ → ℝ) (hg : ∀ i ∈ T, Good n (g i)) :
    energyPairing u (fun x => ∑ i ∈ T, c i * g i x) = ∑ i ∈ T, c i * energyPairing u (g i) := by
  induction T using Finset.induction_on with
  | empty => simp [energyPairing]
  | insert a s ha ih =>
    have hga := hg a (Finset.mem_insert_self a s)
    have hgs : ∀ i ∈ s, Good n (g i) := fun i hi => hg i (Finset.mem_insert_of_mem hi)
    simp only [Finset.sum_insert ha]
    rw [pair_add_right (good_const_mul _ hga) (good_sum s c g hgs) hu, ih hgs, pair_comm u,
      pair_const_mul_left, pair_comm (g a)]

lemma pair_self_nonneg (u : ℝ → ℝ) : 0 ≤ energyPairing u u := by
  unfold energyPairing
  exact integral_nonneg zero_le_one fun x _ =>
    add_nonneg (mul_self_nonneg _) (mul_self_nonneg _)

lemma pair_ibp (n : ℕ) (y v : ℝ → ℝ) (hy : ContDiff ℝ 2 y) (hv : Good n v) (h0 : v 0 = 0)
    (h1 : v 1 = 0) :
    energyPairing y v = ∫ x in (0 : ℝ)..1, (-(deriv (deriv y) x) + y x) * v x := by
  have hy2 : ContDiff ℝ 1 (deriv y) := by
    exact ((contDiff_succ_iff_deriv (n := 1)).mp hy).2.2
  have hdy : Differentiable ℝ (deriv y) := hy2.differentiable one_ne_zero
  have hcy2 : Continuous (deriv (deriv y)) := hy2.continuous_deriv le_rfl
  have hgy := good_of_contDiff n y hy
  have I1 : IntervalIntegrable (fun x => deriv (deriv y) x * v x + deriv y x * deriv v x)
      MeasureTheory.volume 0 1 := by
    have := (pair_integrable hgy hv).add
      (((hcy2.sub hy.continuous).mul hv.1).intervalIntegrable (μ := MeasureTheory.volume) 0 1)
    convert this using 1
    funext x
    simp only [Pi.mul_apply, Pi.sub_apply]
    ring
  have I2 : IntervalIntegrable (fun x => (-(deriv (deriv y) x) + y x) * v x)
      MeasureTheory.volume 0 1 :=
    ((hcy2.neg.add hy.continuous).mul hv.1).intervalIntegrable 0 1
  have key : ∫ x in (0 : ℝ)..1, (deriv (deriv y) x * v x + deriv y x * deriv v x) = 0 := by
    rw [MeasureTheory.integral_eq_of_hasDerivAt_off_countable_of_le (fun x => deriv y x * v x)
      _ zero_le_one (Set.countable_range _) ((hdy.continuous.mul hv.1).continuousOn)
      (fun x hx => (hdy x).hasDerivAt.mul (hv.2.1 x hx.2).hasDerivAt) I1]
    simp [h0, h1]
  calc energyPairing y v
      = ∫ x in (0 : ℝ)..1, ((deriv (deriv y) x * v x + deriv y x * deriv v x) +
          (-(deriv (deriv y) x) + y x) * v x) := by
        unfold energyPairing
        congr 1
        funext x
        ring
    _ = _ := by rw [integral_add I1 I2, key, zero_add]

lemma quad_integral (a b c α β : ℝ) :
    ∫ x in α..β, (a + b * x + c * x ^ 2) =
      a * (β - α) + b * (β ^ 2 - α ^ 2) / 2 + c * (β ^ 3 - α ^ 3) / 3 := by
  have I : ∀ f : ℝ → ℝ, Continuous f → IntervalIntegrable f MeasureTheory.volume α β :=
    fun f hf => hf.intervalIntegrable _ _
  rw [integral_add (I _ (by fun_prop)) (I _ (by fun_prop)),
    integral_add (I _ (by fun_prop)) (I _ (by fun_prop)), integral_const,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul, integral_id,
    integral_pow]
  simp only [smul_eq_mul]
  ring

lemma piece_quad (F : ℝ → ℝ) (α β a b c : ℝ) (hαβ : α ≤ β)
    (h : ∀ x ∈ Set.Ioo α β, F x = a + b * x + c * x ^ 2) :
    ∫ x in α..β, F x = a * (β - α) + b * (β ^ 2 - α ^ 2) / 2 + c * (β ^ 3 - α ^ 3) / 3 := by
  rw [← quad_integral]
  apply integral_congr_ae
  have : ∀ᵐ x ∂MeasureTheory.volume, x ∉ ({β} : Set ℝ) :=
    (Set.countable_singleton β).ae_notMem _
  filter_upwards [this] with x hxβ hx
  rw [Set.uIoc_of_le hαβ] at hx
  exact h x ⟨hx.1, lt_of_le_of_ne hx.2 hxβ⟩

lemma intervalIntegrable_sub_of_unit {F : ℝ → ℝ}
    (hF : IntervalIntegrable F MeasureTheory.volume 0 1) {a b : ℝ} (ha : 0 ≤ a) (hab : a ≤ b)
    (hb : b ≤ 1) : IntervalIntegrable F MeasureTheory.volume a b :=
  hF.mono_set (by
    rw [Set.uIcc_of_le hab, Set.uIcc_of_le zero_le_one]
    exact Set.Icc_subset_Icc ha hb)

lemma integral_split3 {F : ℝ → ℝ} (hF : IntervalIntegrable F MeasureTheory.volume 0 1)
    {p q r : ℝ} (h0p : 0 ≤ p) (hpq : p ≤ q) (hqr : q ≤ r) (hr1 : r ≤ 1) :
    ∫ x in (0 : ℝ)..1, F x = (∫ x in (0 : ℝ)..p, F x) + (∫ x in p..q, F x) +
      (∫ x in q..r, F x) + ∫ x in r..1, F x := by
  have I := fun a b ha hab hb => intervalIntegrable_sub_of_unit hF (a := a) (b := b) ha hab hb
  rw [integral_add_adjacent_intervals (I 0 p le_rfl h0p (by linarith))
      (I p q h0p hpq (by linarith)),
    integral_add_adjacent_intervals (I 0 q le_rfl (by linarith) (by linarith))
      (I q r (by linarith) hqr hr1),
    integral_add_adjacent_intervals (I 0 r le_rfl (by linarith) hr1)
      (I r 1 (by linarith) hr1 le_rfl)]

lemma integral_split2 {F : ℝ → ℝ} (hF : IntervalIntegrable F MeasureTheory.volume 0 1)
    {p q : ℝ} (h0p : 0 ≤ p) (hpq : p ≤ q) (hq1 : q ≤ 1) :
    ∫ x in (0 : ℝ)..1, F x = (∫ x in (0 : ℝ)..p, F x) + (∫ x in p..q, F x) +
      ∫ x in q..1, F x := by
  have I := fun a b ha hab hb => intervalIntegrable_sub_of_unit hF (a := a) (b := b) ha hab hb
  rw [integral_add_adjacent_intervals (I 0 p le_rfl h0p (by linarith))
      (I p q h0p hpq hq1),
    integral_add_adjacent_intervals (I 0 q le_rfl (by linarith) hq1)
      (I q 1 (by linarith) hq1 le_rfl)]

lemma hat_at_zero (n j : ℕ) (hj : 1 ≤ j) : hat n j 0 = 0 := by
  have : (1 : ℝ) ≤ j := by exact_mod_cast hj
  exact hat_val_lo n j 0 (by rw [mul_zero]; linarith)

lemma hat_at_one (n j : ℕ) (hj : j < n) : hat n j 1 = 0 := by
  have : (j : ℝ) + 1 ≤ n := by exact_mod_cast hj
  exact hat_val_hi n j 1 (by rw [mul_one]; exact this)

lemma brokenLine_zero (n : ℕ) (hn : 0 < n) (α β : ℝ) (W : ℕ → ℝ) :
    brokenLine n α β W 0 = α := by
  unfold brokenLine
  rw [hat_at_zero n n hn, Finset.sum_eq_zero (fun i hi => by
    rw [hat_at_zero n i (Finset.mem_Ioo.mp hi).1, mul_zero])]
  simp [hat]

lemma brokenLine_one (n : ℕ) (hn : 0 < n) (α β : ℝ) (W : ℕ → ℝ) :
    brokenLine n α β W 1 = β := by
  unfold brokenLine
  rw [hat_at_one n 0 hn, Finset.sum_eq_zero (fun i hi => by
    rw [hat_at_one n i (Finset.mem_Ioo.mp hi).2, mul_zero])]
  simp [hat]

#print axioms ae_not_meshNode
#print axioms mul_ne_int_of_not_meshNode
#print axioms hat_val_lo
#print axioms hat_val_hi
#print axioms hat_val_up
#print axioms hat_val_down
#print axioms hat_hasDerivAt_lo
#print axioms hat_hasDerivAt_hi
#print axioms hat_hasDerivAt_up
#print axioms hat_hasDerivAt_down
#print axioms hat_hasDerivAt_off
#print axioms hat_continuous
#print axioms good_hat
#print axioms good_add
#print axioms good_sub
#print axioms good_const_mul
#print axioms good_zero
#print axioms good_sum
#print axioms good_brokenLine
#print axioms good_of_contDiff
#print axioms intervalIntegrable_of_bound
#print axioms pair_integrable
#print axioms pair_comm
#print axioms pair_add_left
#print axioms pair_sub_left
#print axioms pair_const_mul_left
#print axioms pair_add_right
#print axioms pair_sub_right
#print axioms pair_sum_right
#print axioms pair_self_nonneg
#print axioms pair_ibp
#print axioms quad_integral
#print axioms piece_quad
#print axioms intervalIntegrable_sub_of_unit
#print axioms integral_split3
#print axioms integral_split2
#print axioms hat_at_zero
#print axioms hat_at_one
#print axioms brokenLine_zero
#print axioms brokenLine_one

/-- Galerkin's answer is the best broken line in energy. Let the cable `y` (twice continuously
differentiable) obey `-y'' + y = f` on `[0, 1]`. Let the broken line `y_h` through the posts
`y(0)` and `y(1)` obey the weak form `a(y_h, φ_j) = (f, φ_j)` for every inside hat `φ_j`.
Then no broken line `w` through the same posts on the same mesh is closer to `y` in energy:
`a(y - y_h, y - y_h) ≤ a(y - w, y - w)`. -/
theorem galerkin_broken_line_is_closest_in_energy (n : ℕ) (hn : 0 < n) (f y : ℝ → ℝ)
    (hy : ContDiff ℝ 2 y)
    (heq : ∀ x ∈ Set.Icc (0 : ℝ) 1, -(deriv (deriv y) x) + y x = f x)
    (U : ℕ → ℝ)
    (hgal : ∀ j ∈ Finset.Ioo 0 n,
      energyPairing (brokenLine n (y 0) (y 1) U) (hat n j) = ∫ x in (0 : ℝ)..1, f x * hat n j x)
    (W : ℕ → ℝ) :
    energyPairing (y - brokenLine n (y 0) (y 1) U) (y - brokenLine n (y 0) (y 1) U) ≤
      energyPairing (y - brokenLine n (y 0) (y 1) W) (y - brokenLine n (y 0) (y 1) W) := by
  have hgy := good_of_contDiff n y hy
  have hgU := good_brokenLine n hn (y 0) (y 1) U
  have hgh : ∀ i ∈ Finset.Ioo 0 n, Good n (hat n i) := fun i _ => good_hat n i hn
  have hge := good_sub hgy hgU
  have hgd := good_sum (Finset.Ioo 0 n) (fun i => U i - W i) (hat n) hgh
  have hsplit : (y - brokenLine n (y 0) (y 1) W) = fun x =>
      (y x - brokenLine n (y 0) (y 1) U x) + ∑ i ∈ Finset.Ioo 0 n, (U i - W i) * hat n i x := by
    funext x
    simp only [Pi.sub_apply, brokenLine, sub_mul, Finset.sum_sub_distrib]
    ring
  have hed : energyPairing (fun x => y x - brokenLine n (y 0) (y 1) U x)
      (fun x => ∑ i ∈ Finset.Ioo 0 n, (U i - W i) * hat n i x) = 0 := by
    rw [pair_sum_right hge _ _ _ hgh]
    apply Finset.sum_eq_zero
    intro j hj
    have hj' := Finset.mem_Ioo.mp hj
    rw [pair_sub_left hgy hgU (good_hat n j hn), hgal j hj,
      pair_ibp n y _ hy (good_hat n j hn) (hat_at_zero n j hj'.1) (hat_at_one n j hj'.2)]
    have : ∫ x in (0 : ℝ)..1, (-(deriv (deriv y) x) + y x) * hat n j x =
        ∫ x in (0 : ℝ)..1, f x * hat n j x := by
      apply integral_congr
      intro x hx
      rw [Set.uIcc_of_le zero_le_one] at hx
      simp only [heq x hx]
    rw [this, sub_self, mul_zero]
  have hde : energyPairing (fun x => ∑ i ∈ Finset.Ioo 0 n, (U i - W i) * hat n i x)
      (fun x => y x - brokenLine n (y 0) (y 1) U x) = 0 := by
    rw [pair_comm]
    exact hed
  rw [hsplit]
  show energyPairing (fun x => y x - brokenLine n (y 0) (y 1) U x)
      (fun x => y x - brokenLine n (y 0) (y 1) U x) ≤ _
  rw [pair_add_left hge hgd (good_add hge hgd), pair_add_right hge hgd hge,
    pair_add_right hge hgd hgd, hed, hde]
  linarith [pair_self_nonneg (fun x => ∑ i ∈ Finset.Ioo 0 n, (U i - W i) * hat n i x)]

/-- Hats make the Galerkin matrix `K + M` tridiagonal. With `h = 1 / n`: an inside hat pairs with
itself to `d = 2/h + 4h/6`, neighbouring hats pair to `o = -1/h + h/6`, and hats two or more
nodes apart pair to 0. -/
theorem hat_pairing_is_tridiagonal (n : ℕ) (hn : 0 < n) :
    (∀ i, 0 < i → i < n →
      energyPairing (hat n i) (hat n i) = 2 / (1 / (n : ℝ)) + 4 * (1 / (n : ℝ)) / 6) ∧
    (∀ i, i + 1 ≤ n →
      energyPairing (hat n i) (hat n (i + 1)) = -1 / (1 / (n : ℝ)) + (1 / (n : ℝ)) / 6) ∧
    (∀ i j, i + 2 ≤ j → energyPairing (hat n i) (hat n j) = 0) := by
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  refine ⟨fun i hi0 hin => ?_, fun i hin => ?_, fun i j hij => ?_⟩
  · have hF := pair_integrable (good_hat n i hn) (good_hat n i hn)
    have hi1 : (1 : ℝ) ≤ i := by exact_mod_cast hi0
    have hin' : (i : ℝ) + 1 ≤ n := by exact_mod_cast hin
    unfold energyPairing
    set F : ℝ → ℝ := fun x => deriv (hat n i) x * deriv (hat n i) x + hat n i x * hat n i x
      with hFdef
    have h1 : (0 : ℝ) ≤ ((i : ℝ) - 1) / n := div_nonneg (by linarith) hnR.le
    have h2 : ((i : ℝ) - 1) / n ≤ (i : ℝ) / n := div_le_div_of_nonneg_right (by linarith) hnR.le
    have h3 : (i : ℝ) / n ≤ ((i : ℝ) + 1) / n := div_le_div_of_nonneg_right (by linarith) hnR.le
    have h4 : ((i : ℝ) + 1) / n ≤ 1 := (div_le_one hnR).mpr hin'
    have P1 := piece_quad F 0 (((i : ℝ) - 1) / n) 0 0 0 h1 (fun x hx => by
      have a2 := (lt_div_iff₀ hnR).mp hx.2
      rw [mul_comm] at a2
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_lo n i x a2).deriv, hat_val_lo n i x a2.le]
      ring)
    have P2 := piece_quad F (((i : ℝ) - 1) / n) ((i : ℝ) / n) ((n : ℝ) * n + ((i : ℝ) - 1) ^ 2)
        (-2 * n * ((i : ℝ) - 1)) ((n : ℝ) ^ 2) h2 (fun x hx => by
      have a1 := (div_lt_iff₀ hnR).mp hx.1
      have a2 := (lt_div_iff₀ hnR).mp hx.2
      rw [mul_comm] at a1 a2
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_up n i x a1 a2).deriv, hat_val_up n i x a1.le a2.le]
      ring)
    have P3 := piece_quad F ((i : ℝ) / n) (((i : ℝ) + 1) / n) ((n : ℝ) * n + ((i : ℝ) + 1) ^ 2)
        (-2 * n * ((i : ℝ) + 1)) ((n : ℝ) ^ 2) h3 (fun x hx => by
      have a1 := (div_lt_iff₀ hnR).mp hx.1
      have a2 := (lt_div_iff₀ hnR).mp hx.2
      rw [mul_comm] at a1 a2
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_down n i x a1 a2).deriv, hat_val_down n i x a1.le a2.le]
      ring)
    have P4 := piece_quad F (((i : ℝ) + 1) / n) 1 0 0 0 h4 (fun x hx => by
      have a1 := (div_lt_iff₀ hnR).mp hx.1
      rw [mul_comm] at a1
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_hi n i x a1).deriv, hat_val_hi n i x a1.le]
      ring)
    rw [integral_split3 hF h1 h2 h3 h4, P1, P2, P3, P4]
    field_simp
    ring
  · have hF := pair_integrable (good_hat n i hn) (good_hat n (i + 1) hn)
    have hin' : (i : ℝ) + 1 ≤ n := by exact_mod_cast hin
    unfold energyPairing
    set F : ℝ → ℝ := fun x => deriv (hat n i) x * deriv (hat n (i + 1)) x +
      hat n i x * hat n (i + 1) x with hFdef
    have h1 : (0 : ℝ) ≤ (i : ℝ) / n := div_nonneg (by positivity) hnR.le
    have h2 : (i : ℝ) / n ≤ ((i : ℝ) + 1) / n := div_le_div_of_nonneg_right (by linarith) hnR.le
    have h3 : ((i : ℝ) + 1) / n ≤ 1 := (div_le_one hnR).mpr hin'
    have P1 := piece_quad F 0 ((i : ℝ) / n) 0 0 0 h1 (fun x hx => by
      have a2 := (lt_div_iff₀ hnR).mp hx.2
      rw [mul_comm] at a2
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_lo n (i + 1) x (by push_cast; linarith)).deriv,
        hat_val_lo n (i + 1) x (by push_cast; linarith)]
      ring)
    have P2 := piece_quad F ((i : ℝ) / n) (((i : ℝ) + 1) / n)
        (-(n : ℝ) * n - (i : ℝ) * ((i : ℝ) + 1)) ((2 * (i : ℝ) + 1) * n) (-(n : ℝ) ^ 2) h2
        (fun x hx => by
      have a1 := (div_lt_iff₀ hnR).mp hx.1
      have a2 := (lt_div_iff₀ hnR).mp hx.2
      rw [mul_comm] at a1 a2
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_down n i x a1 a2).deriv, hat_val_down n i x a1.le a2.le,
        (hat_hasDerivAt_up n (i + 1) x (by push_cast; linarith) (by push_cast; linarith)).deriv,
        hat_val_up n (i + 1) x (by push_cast; linarith) (by push_cast; linarith)]
      push_cast
      ring)
    have P3 := piece_quad F (((i : ℝ) + 1) / n) 1 0 0 0 h3 (fun x hx => by
      have a1 := (div_lt_iff₀ hnR).mp hx.1
      rw [mul_comm] at a1
      rw [hFdef]
      dsimp only
      rw [(hat_hasDerivAt_hi n i x a1).deriv, hat_val_hi n i x a1.le]
      ring)
    rw [integral_split2 hF h1 h2 h3, P1, P2, P3]
    field_simp
    ring
  · have hj : (i : ℝ) + 2 ≤ j := by exact_mod_cast hij
    unfold energyPairing
    have : ∫ x in (0 : ℝ)..1, (deriv (hat n i) x * deriv (hat n j) x + hat n i x * hat n j x) =
        ∫ x in (0 : ℝ)..1, (0 : ℝ) := by
      apply integral_congr_ae
      filter_upwards [ae_not_meshNode n] with x hx _
      have e := mul_ne_int_of_not_meshNode n hn x hx ((i : ℤ) + 1)
      push_cast at e
      rcases lt_or_gt_of_ne e with h | h
      · rw [(hat_hasDerivAt_lo n j x (by linarith)).deriv, hat_val_lo n j x (by linarith)]
        ring
      · rw [(hat_hasDerivAt_hi n i x h).deriv, hat_val_hi n i x h.le]
        ring
    rw [this]
    simp

/-- Rayleigh-Ritz: with no load (`f = 0`), a cable `y` obeying `-y'' + y = 0` on `[0, 1]` stores
less energy than any broken line `w` through the same posts, by exactly the squared energy error:
`a(w, w) = a(y, y) + a(y - w, y - w)`. -/
theorem ritz_energy_identity (n : ℕ) (hn : 0 < n) (y : ℝ → ℝ) (hy : ContDiff ℝ 2 y)
    (heq : ∀ x ∈ Set.Icc (0 : ℝ) 1, -(deriv (deriv y) x) + y x = 0)
    (W : ℕ → ℝ) :
    energyPairing (brokenLine n (y 0) (y 1) W) (brokenLine n (y 0) (y 1) W) =
      energyPairing y y +
        energyPairing (y - brokenLine n (y 0) (y 1) W) (y - brokenLine n (y 0) (y 1) W) := by
  have hgy := good_of_contDiff n y hy
  have hgb := good_brokenLine n hn (y 0) (y 1) W
  have hv := good_sub hgb hgy
  have hyv : energyPairing y (fun x => brokenLine n (y 0) (y 1) W x - y x) = 0 := by
    rw [pair_ibp n y _ hy hv
      (by show brokenLine n (y 0) (y 1) W 0 - y 0 = 0; rw [brokenLine_zero n hn]; ring)
      (by show brokenLine n (y 0) (y 1) W 1 - y 1 = 0; rw [brokenLine_one n hn]; ring)]
    have : ∫ x in (0 : ℝ)..1, (-(deriv (deriv y) x) + y x) * (brokenLine n (y 0) (y 1) W x - y x)
        = ∫ x in (0 : ℝ)..1, (0 : ℝ) := by
      apply integral_congr
      intro x hx
      rw [Set.uIcc_of_le zero_le_one] at hx
      simp only [heq x hx, zero_mul]
    rw [this]
    simp
  rw [pair_sub_right hgb hgy hgy] at hyv
  show _ = energyPairing y y + energyPairing (fun x => y x - brokenLine n (y 0) (y 1) W x)
    (fun x => y x - brokenLine n (y 0) (y 1) W x)
  rw [pair_sub_left hgy hgb (good_sub hgy hgb), pair_sub_right hgy hgb hgy,
    pair_sub_right hgy hgb hgb, pair_comm (brokenLine n (y 0) (y 1) W) y]
  linarith

-- Four elements, h = 1/4: diagonal d = 49/6 (8.166667) and side entry o = -95/24 (-3.958333).
example : (2 : ℚ) / (1 / 4) + 4 * (1 / 4) / 6 = 49 / 6 := by norm_num
example : (-1 : ℚ) / (1 / 4) + (1 / 4) / 6 = -95 / 24 := by norm_num

-- The right side from the end hats: -o × 1, 0, -o × 2 = 95/24, 0, 95/12 (3.958333, 0, 7.916667).
example : -(-95 / 24 : ℚ) * 1 = 95 / 24 ∧ -(-95 / 24 : ℚ) * 2 = 95 / 12 := by norm_num

-- The four-element Galerkin nodes, exactly: 4506895/3991736, 27075/20366, 6441665/3991736
-- (1.129056, 1.329422, 1.613750) solve the three rows of (K + M) U = F.
example :
    (49 / 6 : ℚ) * (4506895 / 3991736) - 95 / 24 * (27075 / 20366) = 95 / 24 ∧
    -(95 / 24 : ℚ) * (4506895 / 3991736) + 49 / 6 * (27075 / 20366)
      - 95 / 24 * (6441665 / 3991736) = 0 ∧
    -(95 / 24 : ℚ) * (27075 / 20366) + 49 / 6 * (6441665 / 3991736) = 95 / 12 := by norm_num

-- Mistake 2, springs dropped: K alone (diagonal 8, side -4, right side 4, 0, 8) gives the
-- straight chord 5/4, 3/2, 7/4 (1.25, 1.5, 1.75 cm).
example :
    (8 : ℚ) * (5 / 4) - 4 * (3 / 2) = 4 ∧
    -(4 : ℚ) * (5 / 4) + 8 * (3 / 2) - 4 * (7 / 4) = 0 ∧
    -(4 : ℚ) * (3 / 2) + 8 * (7 / 4) = 8 := by norm_num

-- Cost of the Thomas sweep, 8(n - 1) - 7 flops: 17 at n = 4 and 8177 at n = 1024.
example : 8 * (4 - 1) - 7 = 17 := by decide
example : 8 * (1024 - 1) - 7 = 8177 := by decide

#print axioms galerkin_broken_line_is_closest_in_energy
#print axioms hat_pairing_is_tridiagonal
#print axioms ritz_energy_identity
