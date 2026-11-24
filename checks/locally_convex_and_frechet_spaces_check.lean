-- Locally convex and Frechet spaces: the metric sum of 2^-k min(1, p_k) gives the same limits as its seminorms, the smooth functions on [0, 1] are complete in it, and no norm on them gives the right limits.
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.Normed.Module.Seminorm.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Analysis.Normed.Group.Tannery
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set Filter Topology
open scoped ContDiff

/-- The Frechet metric of a countable family of checks `p 0, p 1, ...`:
`d(x, y) = ∑ 2^-k min(1, p_k(x - y))`. -/
noncomputable def frechetDist {E : Type*} [Sub E] (p : ℕ → E → ℝ) (x y : E) : ℝ :=
  ∑' k : ℕ, (1 / 2 : ℝ) ^ k * min 1 (p k (x - y))

/-- The smooth functions on `[0, 1]` (derivatives of every order, one-sided at the ends).
Each one is set to `0` outside `[0, 1]`, so an element is exactly one function on `[0, 1]`. -/
def SmoothOn01 : Submodule ℝ (ℝ → ℝ) where
  carrier := {f | ContDiffOn ℝ ∞ f (Icc 0 1) ∧ ∀ t ∉ Icc (0 : ℝ) 1, f t = 0}
  zero_mem' := ⟨contDiffOn_const, fun _ _ => rfl⟩
  add_mem' := fun hf hg =>
    ⟨hf.1.add hg.1, fun t ht => by simp [hf.2 t ht, hg.2 t ht]⟩
  smul_mem' := fun c _ hf =>
    ⟨hf.1.const_smul c, fun t ht => by simp [hf.2 t ht]⟩

/-- The `k`-th check on `[0, 1]`: `p_k(f) = max over t in [0, 1] of |f^(k)(t)|`,
with one-sided derivatives at the ends. -/
noncomputable def pk (k : ℕ) (f : ℝ → ℝ) : ℝ :=
  ⨆ t : Icc (0 : ℝ) 1, |iteratedDerivWithin k f (Icc 0 1) t|

lemma halfMin_summable (q : ℕ → ℝ) (hq : ∀ k, 0 ≤ q k) :
    Summable (fun k : ℕ => (1 / 2 : ℝ) ^ k * min 1 (q k)) := by
  refine Summable.of_nonneg_of_le (fun k => mul_nonneg (by positivity) (le_min zero_le_one (hq k)))
    (fun k => ?_) (summable_geometric_of_lt_one (r := (1 / 2 : ℝ)) (by norm_num) (by norm_num))
  calc (1 / 2 : ℝ) ^ k * min 1 (q k) ≤ (1 / 2 : ℝ) ^ k * 1 :=
        mul_le_mul_of_nonneg_left (min_le_left _ _) (by positivity)
    _ = _ := mul_one _

lemma halfMin_tendsto_iff (q : ℕ → ℕ → ℝ) (hq : ∀ k j, 0 ≤ q k j) :
    Tendsto (fun j => ∑' k : ℕ, (1 / 2 : ℝ) ^ k * min 1 (q k j)) atTop (𝓝 0) ↔
      ∀ k, Tendsto (fun j => q k j) atTop (𝓝 0) := by
  constructor
  · intro h k
    have h1 : Tendsto (fun j => (1 / 2 : ℝ) ^ k * min 1 (q k j)) atTop (𝓝 0) := by
      refine squeeze_zero (fun j => mul_nonneg (by positivity) (le_min zero_le_one (hq k j)))
        (fun j => ?_) h
      exact (halfMin_summable (fun k => q k j) (fun k => hq k j)).le_tsum k
        (fun i _ => mul_nonneg (by positivity) (le_min zero_le_one (hq i j)))
    have h2 : Tendsto (fun j => min 1 (q k j)) atTop (𝓝 0) := by
      have := h1.const_mul ((2 : ℝ) ^ k)
      simp only [mul_zero] at this
      refine this.congr (fun j => ?_)
      rw [← mul_assoc, ← mul_pow]; norm_num
    have h3 : ∀ᶠ j in atTop, min 1 (q k j) = q k j := by
      filter_upwards [h2.eventually (gt_mem_nhds (show (0 : ℝ) < 1 by norm_num))] with j hj
      rcases le_total 1 (q k j) with h | h
      · rw [min_eq_left h] at hj; exact absurd hj (lt_irrefl _)
      · exact min_eq_right h
    exact h2.congr' h3
  · intro h
    have := tendsto_tsum_of_dominated_convergence (f := fun j k => (1 / 2 : ℝ) ^ k * min 1 (q k j))
      (𝓕 := atTop) (g := fun _ => 0) (bound := fun k => (1 / 2 : ℝ) ^ k)
      (summable_geometric_of_lt_one (r := (1 / 2 : ℝ)) (by norm_num) (by norm_num)) (fun k => ?_)
      (Eventually.of_forall fun j k => ?_)
    · simpa using this
    · have : Tendsto (fun j => min 1 (q k j)) atTop (𝓝 (min 1 0)) :=
        tendsto_const_nhds.min (h k)
      rw [min_eq_right zero_le_one] at this
      simpa using this.const_mul ((1 / 2 : ℝ) ^ k)
    · rw [Real.norm_eq_abs, abs_of_nonneg (mul_nonneg (by positivity) (le_min zero_le_one (hq k j)))]
      calc (1 / 2 : ℝ) ^ k * min 1 (q k j) ≤ (1 / 2 : ℝ) ^ k * 1 :=
            mul_le_mul_of_nonneg_left (min_le_left _ _) (by positivity)
        _ = _ := mul_one _

lemma uI01 : UniqueDiffOn ℝ (Icc (0 : ℝ) 1) := uniqueDiffOn_Icc zero_lt_one

lemma pk_nonneg (k : ℕ) (f : ℝ → ℝ) : 0 ≤ pk k f :=
  Real.iSup_nonneg (fun _ => abs_nonneg _)

lemma pk_le {k : ℕ} {f : ℝ → ℝ} {C : ℝ}
    (h : ∀ t ∈ Icc (0 : ℝ) 1, |iteratedDerivWithin k f (Icc 0 1) t| ≤ C) : pk k f ≤ C := by
  have : Nonempty (Icc (0 : ℝ) 1) := ⟨⟨0, by simp⟩⟩
  exact ciSup_le fun t => h t t.2

lemma le_pk {k : ℕ} {f : ℝ → ℝ}
    (hb : ∃ C, ∀ t ∈ Icc (0 : ℝ) 1, |iteratedDerivWithin k f (Icc 0 1) t| ≤ C)
    {t : ℝ} (ht : t ∈ Icc (0 : ℝ) 1) : |iteratedDerivWithin k f (Icc 0 1) t| ≤ pk k f := by
  obtain ⟨C, hC⟩ := hb
  exact le_ciSup (f := fun t : Icc (0 : ℝ) 1 => |iteratedDerivWithin k f (Icc 0 1) t|)
    ⟨C, by rintro _ ⟨s, rfl⟩; exact hC s s.2⟩ ⟨t, ht⟩

lemma bound_of_contDiffOn {f : ℝ → ℝ} (hf : ContDiffOn ℝ ∞ f (Icc 0 1)) (k : ℕ) :
    ∃ C, ∀ t ∈ Icc (0 : ℝ) 1, |iteratedDerivWithin k f (Icc 0 1) t| ≤ C :=
  isCompact_Icc.exists_bound_of_continuousOn
    (hf.continuousOn_iteratedDerivWithin (by exact_mod_cast le_top) uI01)

lemma pk_smul (k : ℕ) {c : ℝ} (hc : 0 ≤ c) (f : ℝ → ℝ) : pk k (c • f) = c * pk k f := by
  unfold pk
  rw [Real.mul_iSup_of_nonneg hc]
  congr 1; ext t
  rw [iteratedDerivWithin_const_smul_field, smul_eq_mul, abs_mul, abs_of_nonneg hc]

lemma hasDerivWithinAt_iteratedDerivWithin {f : ℝ → ℝ} (hf : ContDiffOn ℝ ∞ f (Icc 0 1))
    (k : ℕ) {t : ℝ} (ht : t ∈ Icc (0 : ℝ) 1) :
    HasDerivWithinAt (iteratedDerivWithin k f (Icc 0 1))
      (iteratedDerivWithin (k + 1) f (Icc 0 1) t) (Icc 0 1) t := by
  rw [iteratedDerivWithin_succ]
  exact ((hf.differentiableOn_iteratedDerivWithin (by exact_mod_cast WithTop.coe_lt_top _) uI01)
    t ht).hasDerivWithinAt

lemma hasDerivWithinAt_of_uniform (F F' : ℕ → ℝ → ℝ) (G G' : ℝ → ℝ)
    (hF : ∀ j, ∀ t ∈ Icc (0 : ℝ) 1, HasDerivWithinAt (F j) (F' j t) (Icc 0 1) t)
    (hF'c : ∀ j, ContinuousOn (F' j) (Icc 0 1))
    (hG : ∀ t ∈ Icc (0 : ℝ) 1, Tendsto (fun j => F j t) atTop (𝓝 (G t)))
    (hG' : TendstoUniformlyOn F' G' atTop (Icc 0 1)) :
    ∀ t ∈ Icc (0 : ℝ) 1, HasDerivWithinAt G (G' t) (Icc 0 1) t := by
  have hG'c : ContinuousOn G' (Icc 0 1) := hG'.continuousOn (Frequently.of_forall hF'c)
  have hsub : ∀ t ∈ Icc (0 : ℝ) 1, uIcc 0 t ⊆ Icc 0 1 := fun t ht => by
    rw [uIcc_of_le ht.1]; exact Icc_subset_Icc le_rfl ht.2
  have ftc : ∀ j, ∀ t ∈ Icc (0 : ℝ) 1, F j t - F j 0 = ∫ x in (0 : ℝ)..t, F' j x := by
    intro j t ht
    refine (intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le ht.1 ?_ ?_ ?_).symm
    · intro x hx
      exact (hF j x ⟨hx.1, hx.2.trans ht.2⟩).continuousWithinAt.mono
        (Icc_subset_Icc le_rfl ht.2)
    · intro x hx
      exact (hF j x ⟨hx.1.le, hx.2.le.trans ht.2⟩).hasDerivAt
        (Icc_mem_nhds hx.1 (hx.2.trans_le ht.2))
    · exact ((hF'c j).mono (hsub t ht)).intervalIntegrable
  have lim_int : ∀ t ∈ Icc (0 : ℝ) 1, Tendsto (fun j => ∫ x in (0 : ℝ)..t, F' j x) atTop
      (𝓝 (∫ x in (0 : ℝ)..t, G' x)) := by
    intro t ht
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨M, hM⟩ := eventually_atTop.1 (Metric.tendstoUniformlyOn_iff.1 hG' (ε / 2) (by linarith))
    refine ⟨M, fun j hj => ?_⟩
    rw [dist_eq_norm, ← intervalIntegral.integral_sub
      ((hF'c j).mono (hsub t ht)).intervalIntegrable (hG'c.mono (hsub t ht)).intervalIntegrable]
    calc ‖∫ x in (0 : ℝ)..t, (F' j x - G' x)‖ ≤ ε / 2 * |t - 0| := by
          refine intervalIntegral.norm_integral_le_of_norm_le_const (fun x hx => ?_)
          rw [uIoc_of_le ht.1] at hx
          have := hM j hj x ⟨hx.1.le, hx.2.trans ht.2⟩
          rw [dist_comm, dist_eq_norm] at this
          exact this.le
      _ ≤ ε / 2 * 1 := by
          gcongr; rw [sub_zero, abs_of_nonneg ht.1]; exact ht.2
      _ < ε := by linarith
  have hGint : ∀ t ∈ Icc (0 : ℝ) 1, G t = G 0 + ∫ x in (0 : ℝ)..t, G' x := by
    intro t ht
    have h1 : Tendsto (fun j => F j t - F j 0) atTop (𝓝 (G t - G 0)) :=
      (hG t ht).sub (hG 0 ⟨le_rfl, zero_le_one⟩)
    have h2 : Tendsto (fun j => F j t - F j 0) atTop (𝓝 (∫ x in (0 : ℝ)..t, G' x)) :=
      (lim_int t ht).congr (fun j => (ftc j t ht).symm)
    have := tendsto_nhds_unique h1 h2
    linarith
  set E : ℝ → ℝ := IccExtend zero_le_one (domRestrict (Icc (0 : ℝ) 1) G') with hEdef
  have hE : Continuous E := continuous_IccExtend_iff.2 hG'c.domRestrict
  have hEG : EqOn E G' (Icc 0 1) := fun x hx => by
    rw [hEdef, IccExtend_of_mem _ _ hx]; rfl
  intro t ht
  have hH : HasDerivAt (fun u => G 0 + ∫ x in (0 : ℝ)..u, E x) (E t) t :=
    (hE.integral_hasStrictDerivAt 0 t).hasDerivAt.const_add (G 0)
  rw [← hEG ht]
  refine hH.hasDerivWithinAt.congr (fun u hu => ?_) ?_
  · rw [hGint u hu]
    congr 1
    exact intervalIntegral.integral_congr (fun x hx => (hEG (hsub u hu hx)).symm)
  · rw [hGint t ht]
    congr 1
    exact intervalIntegral.integral_congr (fun x hx => (hEG (hsub t ht hx)).symm)

lemma expFam_contDiff (a c : ℝ) : ContDiff ℝ ∞ (fun t => a * Real.exp (c * t)) :=
  contDiff_const.mul (Real.contDiff_exp.comp (contDiff_const.mul contDiff_id))

lemma expFam_mem (a c : ℝ) :
    (Icc (0 : ℝ) 1).indicator (fun t => a * Real.exp (c * t)) ∈ SmoothOn01 :=
  ⟨(expFam_contDiff a c).contDiffOn.congr (fun _ ht => indicator_of_mem ht _),
    fun _ ht => indicator_of_notMem ht _⟩

lemma expFam_iDW (a c : ℝ) (k : ℕ) {t : ℝ} (ht : t ∈ Icc (0 : ℝ) 1) :
    iteratedDerivWithin k ((Icc (0 : ℝ) 1).indicator (fun t => a * Real.exp (c * t)))
      (Icc 0 1) t = a * (c ^ k * Real.exp (c * t)) := by
  rw [iteratedDerivWithin_congr (fun s hs => indicator_of_mem hs _) ht,
    iteratedDerivWithin_eq_iteratedDeriv uI01
      ((expFam_contDiff a c).contDiffAt.of_le (by exact_mod_cast le_top)) ht,
    iteratedDeriv_const_mul_field, iteratedDeriv_exp_const_mul]

#print axioms halfMin_summable
#print axioms halfMin_tendsto_iff
#print axioms uI01
#print axioms pk_nonneg
#print axioms pk_le
#print axioms le_pk
#print axioms bound_of_contDiffOn
#print axioms pk_smul
#print axioms hasDerivWithinAt_iteratedDerivWithin
#print axioms hasDerivWithinAt_of_uniform
#print axioms expFam_contDiff
#print axioms expFam_mem
#print axioms expFam_iDW

/-- The smooth functions on `[0, 1]` carry no norm with the right limits: there is no norm `N`
for which `N(f_j - g) → 0` holds exactly when `p_k(f_j - g) → 0` for every `k` separately. -/
theorem smooth_functions_carry_no_norm :
    ¬ ∃ N : Seminorm ℝ SmoothOn01, (∀ f, N f = 0 → f = 0) ∧
      ∀ (f : ℕ → SmoothOn01) (g : SmoothOn01),
        Tendsto (fun j => N (f j - g)) atTop (𝓝 0) ↔
          ∀ k, Tendsto (fun j => pk k ((f j : ℝ → ℝ) - g)) atTop (𝓝 0) := by
  rintro ⟨N, -, H⟩
  have H0 : ∀ u : ℕ → SmoothOn01, Tendsto (fun j => N (u j)) atTop (𝓝 0) ↔
      ∀ k, Tendsto (fun j => pk k (u j : ℝ → ℝ)) atTop (𝓝 0) := by
    intro u; simpa using H u 0
  have Snn : ∀ (m : ℕ) (g : ℝ → ℝ), 0 ≤ ∑ k ∈ Finset.range (m + 1), pk k g :=
    fun m g => Finset.sum_nonneg (fun k _ => pk_nonneg k g)
  obtain ⟨m, C, hC⟩ : ∃ m : ℕ, ∃ C : ℝ, ∀ g : SmoothOn01,
      N g ≤ C * ∑ k ∈ Finset.range (m + 1), pk k (g : ℝ → ℝ) := by
    by_contra hne
    push Not at hne
    choose F hF using fun m : ℕ => hne m ((m : ℝ) + 1)
    have hNpos : ∀ m, 0 < N (F m) := fun m =>
      lt_of_le_of_lt (mul_nonneg (by positivity) (Snn m _)) (hF m)
    let u : ℕ → SmoothOn01 := fun m => (N (F m))⁻¹ • F m
    have hNu : ∀ m, N (u m) = 1 := by
      intro m
      change N ((N (F m))⁻¹ • F m) = 1
      rw [map_smul_eq_mul, Real.norm_eq_abs, abs_of_pos (inv_pos.2 (hNpos m)),
        inv_mul_cancel₀ (hNpos m).ne']
    have hpku : ∀ k m, pk k (u m : ℝ → ℝ) = (N (F m))⁻¹ * pk k (F m : ℝ → ℝ) := by
      intro k m
      change pk k (((N (F m))⁻¹ • F m : SmoothOn01) : ℝ → ℝ) = _
      rw [Submodule.coe_smul]
      exact pk_smul k (inv_pos.2 (hNpos m)).le _
    have hsmall : ∀ k m, k ≤ m → pk k (u m : ℝ → ℝ) ≤ 1 / ((m : ℝ) + 1) := by
      intro k m hkm
      rw [hpku]
      have h1 : pk k (F m : ℝ → ℝ) ≤ ∑ i ∈ Finset.range (m + 1), pk i (F m : ℝ → ℝ) :=
        Finset.single_le_sum (fun i _ => pk_nonneg i _)
          (Finset.mem_range.2 (Nat.lt_succ_of_le hkm))
      rw [inv_mul_eq_div, div_le_div_iff₀ (hNpos m) (by positivity)]
      have h2 := mul_le_mul_of_nonneg_right h1 (show (0 : ℝ) ≤ (m : ℝ) + 1 by positivity)
      have h3 := hF m
      nlinarith
    have hconv : ∀ k, Tendsto (fun m => pk k (u m : ℝ → ℝ)) atTop (𝓝 0) := by
      intro k
      refine squeeze_zero' (Eventually.of_forall fun m => pk_nonneg _ _) ?_
        tendsto_one_div_add_atTop_nhds_zero_nat
      filter_upwards [eventually_ge_atTop k] with m hm using hsmall k m hm
    have hlim := (H0 u).2 hconv
    simp only [hNu] at hlim
    exact one_ne_zero (tendsto_nhds_unique tendsto_const_nhds hlim)
  let h : ℕ → SmoothOn01 := fun j =>
    ⟨(Icc (0 : ℝ) 1).indicator (fun t => (((j : ℝ) + 1) ^ (m + 1) * Real.exp ((j : ℝ) + 1))⁻¹ *
      Real.exp (((j : ℝ) + 1) * t)), expFam_mem _ _⟩
  have hval : ∀ k j, ∀ t ∈ Icc (0 : ℝ) 1, iteratedDerivWithin k (h j : ℝ → ℝ) (Icc 0 1) t =
      (((j : ℝ) + 1) ^ (m + 1) * Real.exp ((j : ℝ) + 1))⁻¹ *
        (((j : ℝ) + 1) ^ k * Real.exp (((j : ℝ) + 1) * t)) :=
    fun k j t ht => expFam_iDW _ _ k ht
  have hbound : ∀ k j, ∀ t ∈ Icc (0 : ℝ) 1, |iteratedDerivWithin k (h j : ℝ → ℝ) (Icc 0 1) t| ≤
      ((j : ℝ) + 1) ^ k / ((j : ℝ) + 1) ^ (m + 1) := by
    intro k j t ht
    rw [hval k j t ht]
    have hn : 0 < (j : ℝ) + 1 := by positivity
    have hexp : Real.exp (((j : ℝ) + 1) * t) ≤ Real.exp ((j : ℝ) + 1) :=
      Real.exp_le_exp.2 (mul_le_of_le_one_right hn.le ht.2)
    rw [abs_of_nonneg (by positivity)]
    rw [show (((j : ℝ) + 1) ^ (m + 1) * Real.exp ((j : ℝ) + 1))⁻¹ *
        (((j : ℝ) + 1) ^ k * Real.exp (((j : ℝ) + 1) * t)) =
        ((j : ℝ) + 1) ^ k / ((j : ℝ) + 1) ^ (m + 1) *
          (Real.exp (((j : ℝ) + 1) * t) / Real.exp ((j : ℝ) + 1)) by
      field_simp]
    exact mul_le_of_le_one_right (by positivity) ((div_le_one (Real.exp_pos _)).2 hexp)
  have hlow : ∀ k ≤ m, ∀ j, pk k (h j : ℝ → ℝ) ≤ 1 / ((j : ℝ) + 1) := by
    intro k hk j
    refine pk_le (fun t ht => (hbound k j t ht).trans ?_)
    have hn : 1 ≤ (j : ℝ) + 1 := by
      have : (0 : ℝ) ≤ j := Nat.cast_nonneg j
      linarith
    rw [div_le_div_iff₀ (by positivity) (by positivity), one_mul, ← pow_succ]
    exact pow_le_pow_right₀ hn (by omega)
  have htop : ∀ j, 1 ≤ pk (m + 1) (h j : ℝ → ℝ) := by
    intro j
    have h1 : (1 : ℝ) ∈ Icc (0 : ℝ) 1 := ⟨zero_le_one, le_rfl⟩
    have := le_pk ⟨_, hbound (m + 1) j⟩ h1
    rw [hval (m + 1) j 1 h1, mul_one, inv_mul_cancel₀ (by positivity), abs_one] at this
    exact this
  have hS0 : Tendsto (fun j => ∑ k ∈ Finset.range (m + 1), pk k (h j : ℝ → ℝ)) atTop (𝓝 0) := by
    rw [show (0 : ℝ) = ∑ k ∈ Finset.range (m + 1), (0 : ℝ) by simp]
    refine tendsto_finsetSum _ (fun k hk => ?_)
    exact squeeze_zero (fun j => pk_nonneg _ _)
      (fun j => hlow k (Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)) j)
      tendsto_one_div_add_atTop_nhds_zero_nat
  have hN0 : Tendsto (fun j => N (h j)) atTop (𝓝 0) := by
    refine squeeze_zero (fun j => apply_nonneg N _) (fun j => hC (h j)) ?_
    simpa using hS0.const_mul C
  have hev := ((H0 h).1 hN0 (m + 1)).eventually (gt_mem_nhds (show (0 : ℝ) < 1 by norm_num))
  obtain ⟨j, hj⟩ := hev.exists
  linarith [htop j]

/-- The metric gives the same limits as the family: for any countable family of seminorms,
`d(x_j, y) → 0` exactly when `p_k(x_j - y) → 0` for every `k` separately. -/
theorem frechet_metric_same_limits {E : Type*} [AddCommGroup E] [Module ℝ E]
    (p : ℕ → Seminorm ℝ E) (x : ℕ → E) (y : E) :
    Tendsto (fun j => frechetDist (fun k => p k) (x j) y) atTop (𝓝 0) ↔
      ∀ k, Tendsto (fun j => p k (x j - y)) atTop (𝓝 0) := by
  unfold frechetDist
  exact halfMin_tendsto_iff (fun k j => p k (x j - y)) (fun k j => apply_nonneg _ _)

/-- The smooth functions on `[0, 1]` are complete: every sequence that is Cauchy in the
Frechet metric `d` converges in `d` to a smooth function on `[0, 1]`. -/
theorem smooth_functions_complete (f : ℕ → SmoothOn01)
    (hf : ∀ ε > 0, ∃ M : ℕ, ∀ i ≥ M, ∀ j ≥ M,
      frechetDist pk (f i : ℝ → ℝ) (f j) < ε) :
    ∃ g : SmoothOn01, Tendsto (fun j => frechetDist pk (f j : ℝ → ℝ) g) atTop (𝓝 0) := by
  have hS : ∀ j, ContDiffOn ℝ ∞ (f j : ℝ → ℝ) (Icc 0 1) := fun j => (f j).2.1
  have hZ : ∀ j, ∀ t ∉ Icc (0 : ℝ) 1, (f j : ℝ → ℝ) t = 0 := fun j => (f j).2.2
  have hdiff : ∀ k i j, ∀ t ∈ Icc (0 : ℝ) 1,
      iteratedDerivWithin k ((f i : ℝ → ℝ) - (f j : ℝ → ℝ)) (Icc 0 1) t =
        iteratedDerivWithin k (f i) (Icc 0 1) t - iteratedDerivWithin k (f j) (Icc 0 1) t :=
    fun k i j t ht => iteratedDerivWithin_sub ht uI01
      ((hS i t ht).of_le (by exact_mod_cast le_top)) ((hS j t ht).of_le (by exact_mod_cast le_top))
  have hcauchy : ∀ k, UniformCauchySeqOn
      (fun j => iteratedDerivWithin k (f j : ℝ → ℝ) (Icc 0 1)) atTop (Icc 0 1) := by
    intro k
    rw [Metric.uniformCauchySeqOn_iff]
    intro ε hε
    obtain ⟨M, hM⟩ := hf ((1 / 2 : ℝ) ^ k * min ε 1) (by positivity)
    refine ⟨M, fun i hi j hj t ht => ?_⟩
    have hd := hM i hi j hj
    unfold frechetDist at hd
    have hterm : (1 / 2 : ℝ) ^ k * min 1 (pk k ((f i : ℝ → ℝ) - (f j : ℝ → ℝ))) <
        (1 / 2 : ℝ) ^ k * min ε 1 :=
      lt_of_le_of_lt ((halfMin_summable (fun n => pk n ((f i : ℝ → ℝ) - (f j : ℝ → ℝ)))
        (fun n => pk_nonneg _ _)).le_tsum k
        (fun _ _ => mul_nonneg (by positivity) (le_min zero_le_one (pk_nonneg _ _)))) hd
    have hmin := lt_of_mul_lt_mul_left hterm (by positivity)
    have hpk : pk k ((f i : ℝ → ℝ) - (f j : ℝ → ℝ)) < ε := by
      rcases le_total 1 (pk k ((f i : ℝ → ℝ) - (f j : ℝ → ℝ))) with h | h
      · rw [min_eq_left h] at hmin
        exact absurd (hmin.trans_le (min_le_right _ _)) (lt_irrefl _)
      · rw [min_eq_right h] at hmin
        exact hmin.trans_le (min_le_left _ _)
    rw [Real.dist_eq, ← hdiff k i j t ht]
    exact (le_pk (bound_of_contDiffOn ((hS i).sub (hS j)) k) ht).trans_lt hpk
  let G : ℕ → ℝ → ℝ := fun k t =>
    limUnder atTop (fun j => iteratedDerivWithin k (f j : ℝ → ℝ) (Icc 0 1) t)
  have hGlim : ∀ k, ∀ t ∈ Icc (0 : ℝ) 1, Tendsto
      (fun j => iteratedDerivWithin k (f j : ℝ → ℝ) (Icc 0 1) t) atTop (𝓝 (G k t)) :=
    fun k t ht => tendsto_nhds_limUnder (cauchySeq_tendsto_of_complete ((hcauchy k).cauchySeq ht))
  have hGunif : ∀ k, TendstoUniformlyOn
      (fun j => iteratedDerivWithin k (f j : ℝ → ℝ) (Icc 0 1)) (G k) atTop (Icc 0 1) :=
    fun k => (hcauchy k).tendstoUniformlyOn_of_tendsto (hGlim k)
  have hGderiv : ∀ k, ∀ t ∈ Icc (0 : ℝ) 1, HasDerivWithinAt (G k) (G (k + 1) t) (Icc 0 1) t :=
    fun k => hasDerivWithinAt_of_uniform _ _ (G k) (G (k + 1))
      (fun j t ht => hasDerivWithinAt_iteratedDerivWithin (hS j) k ht)
      (fun j => (hS j).continuousOn_iteratedDerivWithin (by exact_mod_cast le_top) uI01)
      (hGlim k) (hGunif (k + 1))
  have hGeq : ∀ k, EqOn (iteratedDerivWithin k (G 0) (Icc 0 1)) (G k) (Icc 0 1) := by
    intro k
    induction k with
    | zero => intro t ht; simp [iteratedDerivWithin_zero]
    | succ k ih =>
      intro t ht
      rw [iteratedDerivWithin_succ, derivWithin_congr ih (ih ht)]
      exact (hGderiv k t ht).derivWithin (uI01 t ht)
  have hGcd : ContDiffOn ℝ ∞ (G 0) (Icc 0 1) := by
    apply contDiffOn_of_differentiableOn_deriv
    intro m _
    have hd : DifferentiableOn ℝ (G m) (Icc 0 1) := fun t ht =>
      (hGderiv m t ht).differentiableWithinAt
    exact hd.congr (fun t ht => hGeq m ht)
  have hGz : ∀ t ∉ Icc (0 : ℝ) 1, G 0 t = 0 := by
    intro t ht
    simp only [G, iteratedDerivWithin_zero, hZ _ t ht]
    exact tendsto_const_nhds.limUnder_eq
  refine ⟨⟨G 0, hGcd, hGz⟩, ?_⟩
  unfold frechetDist
  refine (halfMin_tendsto_iff (fun k j => pk k ((f j : ℝ → ℝ) - G 0))
    (fun k j => pk_nonneg _ _)).2 ?_
  intro k
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨M, hM⟩ := eventually_atTop.1
    (Metric.tendstoUniformlyOn_iff.1 (hGunif k) (ε / 2) (by linarith))
  refine ⟨M, fun j hj => ?_⟩
  rw [Real.dist_eq, sub_zero, abs_of_nonneg (pk_nonneg _ _)]
  refine lt_of_le_of_lt (pk_le (fun t ht => ?_)) (by linarith : ε / 2 < ε)
  rw [iteratedDerivWithin_sub ht uI01 ((hS j t ht).of_le (by exact_mod_cast le_top))
    ((hGcd t ht).of_le (by exact_mod_cast le_top)), hGeq k ht, abs_sub_comm]
  have := hM j hj t ht
  rw [Real.dist_eq] at this
  exact this.le

-- The move t^3: checks p_0 to p_3 are 1, 3, 6, 6 (p_k = 0 from k = 4),
-- each capped at 1 and weighted by 2^-k: d(t^3, 0) = 1 + 1/2 + 1/4 + 1/8 = 15/8 = 1.875.
example : ∑ k : Fin 4, (1 / 2 : ℚ) ^ (k : ℕ) * min 1 (![1, 3, 6, 6] k) = 15 / 8 := by
  simp [Fin.sum_univ_four]
  norm_num

-- The vibration at n = 10: d(g_10, 0) = 1/2 + 1/(2n) + 1/n^2 = 0.56 = 14/25.
example : (1 / 2 : ℚ) + 1 / (2 * 10) + 1 / 10 ^ 2 = 14 / 25 := by norm_num

-- Chebyshev slopes 2N^2 at N = 1, 3, 10: 2, 18 and 200.
example : (2 * 1 ^ 2, 2 * 3 ^ 2, 2 * 10 ^ 2) = (2, 18, 200) := by decide

#print axioms smooth_functions_carry_no_norm
#print axioms frechet_metric_same_limits
#print axioms smooth_functions_complete
