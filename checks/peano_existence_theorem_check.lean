-- Peano's theorem: a continuous rate law y' = f(t, y) in R^n has a solution on the window min(a, b/M), a maximal solution with a finite end grows past every bound, and y' = sqrt|y| from 0 has the two solutions 0 and t^2/4.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.FDeriv.Extend
import Mathlib.Analysis.SpecificLimits.Basic

open Filter Topology Set Metric

/-- The share of Euler step `k` (from time `t₀ + k h` to `t₀ + (k+1) h`) used up by time `t`. -/
noncomputable def eulerWeight (t₀ h : ℝ) (k : ℕ) (t : ℝ) : ℝ := max 0 (min h (t - t₀ - k * h))

theorem eulerWeight_sum (t₀ h t : ℝ) (hh : 0 ≤ h) (ht : t₀ ≤ t) (N : ℕ) :
    ∑ k ∈ Finset.range N, eulerWeight t₀ h k t = min (t - t₀) (N * h) := by
  induction N with
  | zero => simp; linarith
  | succ N ih =>
    rw [Finset.sum_range_succ, ih]
    simp only [eulerWeight]
    push_cast
    rcases le_total (t - t₀) (N * h) with h1 | h1
    · have h2 : min h (t - t₀ - N * h) ≤ 0 := min_le_of_right_le (by linarith)
      rw [min_eq_left h1, max_eq_left h2, min_eq_left (by nlinarith)]
      ring
    · rw [min_eq_right h1]
      rcases le_total h (t - t₀ - N * h) with h3 | h3
      · rw [min_eq_left h3, max_eq_right hh, min_eq_right (by linarith)]
        ring
      · rw [min_eq_right h3, max_eq_right (by linarith), min_eq_left (by linarith)]
        ring

theorem eulerWeight_mono (t₀ h : ℝ) (k : ℕ) {s t : ℝ} (hst : s ≤ t) :
    eulerWeight t₀ h k s ≤ eulerWeight t₀ h k t := by
  unfold eulerWeight
  exact max_le_max le_rfl (min_le_min le_rfl (by linarith))

theorem eulerWeight_eq_of (t₀ h : ℝ) (k : ℕ) {s t : ℝ} (hst : s ≤ t)
    (hne : eulerWeight t₀ h k t ≠ eulerWeight t₀ h k s) :
    t₀ + k * h < t ∧ s < t₀ + k * h + h := by
  by_contra hc
  apply hne
  unfold eulerWeight
  rcases not_and_or.1 hc with h1 | h1
  · push Not at h1
    rw [max_eq_left (min_le_of_right_le (by linarith)),
      max_eq_left (min_le_of_right_le (by linarith))]
  · push Not at h1
    rw [min_eq_left (by linarith), min_eq_left (by linarith)]

theorem eulerWeight_est {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (t₀ h : ℝ) (hh : 0 ≤ h) (N : ℕ) (v : ℕ → E) (w : E) (ε : ℝ) {s t : ℝ}
    (hs : t₀ ≤ s) (hst : s ≤ t) (htN : t ≤ t₀ + N * h)
    (hv : ∀ k < N, t₀ + k * h < t → s < t₀ + k * h + h → ‖v k - w‖ ≤ ε) :
    ‖(∑ k ∈ Finset.range N, eulerWeight t₀ h k t • v k)
      - (∑ k ∈ Finset.range N, eulerWeight t₀ h k s • v k) - (t - s) • w‖ ≤ ε * (t - s) := by
  have hsum : t - s = ∑ k ∈ Finset.range N, (eulerWeight t₀ h k t - eulerWeight t₀ h k s) := by
    rw [Finset.sum_sub_distrib, eulerWeight_sum t₀ h t hh (hs.trans hst),
      eulerWeight_sum t₀ h s hh hs, min_eq_left (by linarith), min_eq_left (by linarith)]
    ring
  have hrw : (∑ k ∈ Finset.range N, eulerWeight t₀ h k t • v k)
      - (∑ k ∈ Finset.range N, eulerWeight t₀ h k s • v k) - (t - s) • w
      = ∑ k ∈ Finset.range N, (eulerWeight t₀ h k t - eulerWeight t₀ h k s) • (v k - w) := by
    rw [hsum, Finset.sum_smul, ← Finset.sum_sub_distrib, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [sub_smul, sub_smul, smul_sub, smul_sub]
    abel
  rw [hrw, hsum, Finset.mul_sum]
  refine (norm_sum_le _ _).trans (Finset.sum_le_sum fun k hk => ?_)
  have hk' : k < N := Finset.mem_range.1 hk
  have hnn : 0 ≤ eulerWeight t₀ h k t - eulerWeight t₀ h k s :=
    sub_nonneg.2 (eulerWeight_mono t₀ h k hst)
  rw [norm_smul, Real.norm_of_nonneg hnn]
  by_cases he : eulerWeight t₀ h k t = eulerWeight t₀ h k s
  · rw [he]; simp
  · obtain ⟨h1, h2⟩ := eulerWeight_eq_of t₀ h k hst he
    rw [mul_comm ε]
    exact mul_le_mul_of_nonneg_left (hv k hk' h1 h2) hnn

/-- The Euler grid values: `Y 0 = y₀`, `Y (k+1) = Y k + h g(t₀ + k h, Y k)`. -/
noncomputable def eulerGrid {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ → E → E) (t₀ h : ℝ) (y₀ : E) : ℕ → E
  | 0 => y₀
  | k + 1 => eulerGrid g t₀ h y₀ k + h • g (t₀ + k * h) (eulerGrid g t₀ h y₀ k)

/-- The Euler polygon with `N` steps of size `h` from `(t₀, y₀)`. -/
noncomputable def eulerPoly {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ → E → E) (t₀ h : ℝ) (y₀ : E) (N : ℕ) (t : ℝ) : E :=
  y₀ + ∑ k ∈ Finset.range N, eulerWeight t₀ h k t • g (t₀ + k * h) (eulerGrid g t₀ h y₀ k)

theorem eulerGrid_eq_sum {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ → E → E) (t₀ h : ℝ) (y₀ : E) (j : ℕ) :
    eulerGrid g t₀ h y₀ j = y₀ + ∑ k ∈ Finset.range j, h • g (t₀ + k * h) (eulerGrid g t₀ h y₀ k) := by
  induction j with
  | zero => simp [eulerGrid]
  | succ j ih => rw [Finset.sum_range_succ, ← add_assoc, ← ih]; rfl

theorem eulerPoly_grid {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ → E → E) (t₀ h : ℝ) (hh : 0 ≤ h) (y₀ : E) (N j : ℕ) (hj : j ≤ N) :
    eulerPoly g t₀ h y₀ N (t₀ + j * h) = eulerGrid g t₀ h y₀ j := by
  rw [eulerGrid_eq_sum, eulerPoly]
  congr 1
  obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hj
  rw [Finset.sum_range_add]
  have h2 : ∑ k ∈ Finset.range m, eulerWeight t₀ h (j + k) (t₀ + j * h) •
      g (t₀ + ((j + k : ℕ) : ℝ) * h) (eulerGrid g t₀ h y₀ (j + k)) = 0 := by
    refine Finset.sum_eq_zero fun k _ => ?_
    have : eulerWeight t₀ h (j + k) (t₀ + j * h) = 0 := by
      unfold eulerWeight
      push_cast
      have : (0:ℝ) ≤ k * h := mul_nonneg (Nat.cast_nonneg k) hh
      exact max_eq_left (min_le_of_right_le (by nlinarith))
    rw [this, zero_smul]
  rw [h2, add_zero]
  refine Finset.sum_congr rfl fun k hk => ?_
  have hk' : (k : ℝ) + 1 ≤ j := by exact_mod_cast Finset.mem_range.1 hk
  have : eulerWeight t₀ h k (t₀ + j * h) = h := by
    unfold eulerWeight
    rw [min_eq_left (by nlinarith), max_eq_right hh]
  rw [this]

theorem eulerPoly_start {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ → E → E) (t₀ h : ℝ) (hh : 0 ≤ h) (y₀ : E) (N : ℕ) :
    eulerPoly g t₀ h y₀ N t₀ = y₀ := by
  have := eulerPoly_grid g t₀ h hh y₀ N 0 (Nat.zero_le _)
  simpa [eulerGrid] using this

/-- Peano for a rate law that is continuous and bounded everywhere: a limit of Euler polygons
(taken along an ultrafilter, so no subsequence is needed) solves the equation on `[t₀, t₀ + T]`. -/
theorem peano_core {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [ProperSpace E]
    (g : ℝ → E → E) (hg : Continuous (fun p : ℝ × E => g p.1 p.2))
    {M : ℝ} (hM : ∀ t x, ‖g t x‖ ≤ M) (t₀ T : ℝ) (hT : 0 ≤ T) (y₀ : E) :
    ∃ y : ℝ → E, y t₀ = y₀ ∧ (∀ t ∈ Icc t₀ (t₀ + T), ‖y t - y₀‖ ≤ M * (t - t₀)) ∧
      ∀ t ∈ Icc t₀ (t₀ + T), HasDerivWithinAt y (g t (y t)) (Icc t₀ (t₀ + T)) t := by
  classical
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0 0)
  obtain ⟨U, hU⟩ : ∃ U : Ultrafilter ℕ, (U : Filter ℕ) ≤ atTop :=
    ⟨Ultrafilter.of atTop, Ultrafilter.of_le _⟩
  set P : ℕ → ℝ → E := fun N => eulerPoly g t₀ (T / N) y₀ N with hP
  have hN1 : ∀ᶠ N in (U : Filter ℕ), 1 ≤ N := hU (eventually_ge_atTop 1)
  have hh : ∀ N : ℕ, 0 ≤ T / N := fun N => div_nonneg hT (Nat.cast_nonneg N)
  have hNh : ∀ N : ℕ, 1 ≤ N → t₀ + N * (T / N) = t₀ + T := by
    intro N hN
    have : (N : ℝ) ≠ 0 := by have : (1 : ℝ) ≤ N := by exact_mod_cast hN
                             linarith
    field_simp
  have hest : ∀ N : ℕ, 1 ≤ N → ∀ w : E, ∀ ε : ℝ, ∀ s t, t₀ ≤ s → s ≤ t → t ≤ t₀ + T →
      (∀ k < N, t₀ + k * (T / N) < t → s < t₀ + k * (T / N) + T / N →
        ‖g (t₀ + k * (T / N)) (eulerGrid g t₀ (T / N) y₀ k) - w‖ ≤ ε) →
      ‖P N t - P N s - (t - s) • w‖ ≤ ε * (t - s) := by
    intro N hN w ε s t hs hst ht hv
    have := eulerWeight_est t₀ (T / N) (hh N) N
      (fun k => g (t₀ + k * (T / N)) (eulerGrid g t₀ (T / N) y₀ k)) w ε hs hst
      (by rw [hNh N hN]; exact ht) hv
    simpa [hP, eulerPoly] using this
  have hP0 : ∀ N, P N t₀ = y₀ := fun N => eulerPoly_start g t₀ _ (hh N) y₀ N
  have hlip : ∀ N : ℕ, 1 ≤ N → ∀ s t, t₀ ≤ s → s ≤ t → t ≤ t₀ + T →
      ‖P N t - P N s‖ ≤ M * (t - s) := by
    intro N hN s t hs hst ht
    have := hest N hN 0 M s t hs hst ht (fun k _ _ _ => by simpa using hM _ _)
    simpa using this
  have hlip' : ∀ N : ℕ, 1 ≤ N → ∀ s ∈ Icc t₀ (t₀ + T), ∀ t ∈ Icc t₀ (t₀ + T),
      ‖P N t - P N s‖ ≤ M * |t - s| := by
    intro N hN s hs t ht
    rcases le_total s t with h | h
    · rw [abs_of_nonneg (by linarith)]; exact hlip N hN s t hs.1 h ht.2
    · rw [norm_sub_rev, abs_of_nonpos (by linarith), neg_sub]; exact hlip N hN t s ht.1 h hs.2
  have hball : ∀ N : ℕ, 1 ≤ N → ∀ t ∈ Icc t₀ (t₀ + T), ‖P N t - y₀‖ ≤ M * (t - t₀) := by
    intro N hN t ht
    have := hlip N hN t₀ t le_rfl ht.1 ht.2
    rwa [hP0] at this
  have hlim : ∀ t ∈ Icc t₀ (t₀ + T),
      Tendsto (fun N => P N t) U (𝓝 (limUnder (U : Filter ℕ) (fun N => P N t))) := by
    intro t ht
    apply tendsto_nhds_limUnder
    have hmem : closedBall y₀ (M * T) ∈ U.map (fun N => P N t) := by
      rw [Ultrafilter.mem_map]
      refine Ultrafilter.mem_coe.1 (hN1.mono fun N hN => ?_)
      show P N t ∈ closedBall y₀ (M * T)
      rw [mem_closedBall, dist_eq_norm]
      exact (hball N hN t ht).trans (mul_le_mul_of_nonneg_left (by linarith [ht.2]) hM0)
    obtain ⟨x, -, hx⟩ := (isCompact_closedBall y₀ (M * T)).ultrafilter_le_nhds' _ hmem
    rw [Ultrafilter.coe_map] at hx
    exact ⟨x, hx⟩
  set y : ℝ → E := fun t => limUnder (U : Filter ℕ) (fun N => P N t) with hy
  have hy0 : y t₀ = y₀ := by
    have h1 : Tendsto (fun N => P N t₀) U (𝓝 (y t₀)) := hlim t₀ ⟨le_rfl, by linarith⟩
    rw [show (fun N => P N t₀) = fun _ => y₀ from funext hP0] at h1
    exact tendsto_nhds_unique h1 tendsto_const_nhds
  have hyb : ∀ t ∈ Icc t₀ (t₀ + T), ‖y t - y₀‖ ≤ M * (t - t₀) := by
    intro t ht
    exact le_of_tendsto (((hlim t ht).sub_const y₀).norm) (hN1.mono fun N hN => hball N hN t ht)
  refine ⟨y, hy0, hyb, fun s hs => ?_⟩
  set w := g s (y s) with hw
  rw [hasDerivWithinAt_iff_isLittleO, Asymptotics.isLittleO_iff]
  intro ε hε
  obtain ⟨δ, hδ, hcont⟩ := Metric.continuous_iff.1 hg (s, y s) ε hε
  set η := δ / (4 * (M + 1)) with hη
  have hη0 : 0 < η := by positivity
  have hMη : M * η < δ / 4 := by
    rw [hη, mul_div_assoc', div_lt_div_iff₀ (by positivity) (by norm_num)]
    nlinarith
  have hηδ : η < δ / 2 := by
    rw [hη, div_lt_div_iff₀ (by positivity) (by norm_num)]
    nlinarith
  filter_upwards [self_mem_nhdsWithin, nhdsWithin_le_nhds (Metric.ball_mem_nhds s hη0)]
    with t ht htη
  rw [mem_ball, Real.dist_eq] at htη
  rw [Real.norm_eq_abs]
  have hsmall : ∀ᶠ N : ℕ in (U : Filter ℕ), T / (N : ℝ) < η :=
    hU ((tendsto_const_div_atTop_nhds_zero_nat T).eventually (Iio_mem_nhds hη0))
  have hclose : ∀ᶠ N in (U : Filter ℕ), dist (P N s) (y s) < δ / 2 :=
    (hlim s hs).eventually (Metric.ball_mem_nhds _ (half_pos hδ))
  refine le_of_tendsto ((((hlim t ht).sub (hlim s hs)).sub_const ((t - s) • w)).norm) ?_
  filter_upwards [hN1, hsmall, hclose] with N hN hNs hNc
  -- every grid point near `s` gives a slope within `ε` of `w`
  have key : ∀ k < N, |t₀ + k * (T / N) - s| < 2 * η →
      ‖g (t₀ + k * (T / N)) (eulerGrid g t₀ (T / N) y₀ k) - w‖ ≤ ε := by
    intro k hk hks
    have hkN : (k : ℝ) ≤ N := by exact_mod_cast hk.le
    have hkmem : t₀ + k * (T / N) ∈ Icc t₀ (t₀ + T) := by
      refine ⟨by linarith [mul_nonneg (Nat.cast_nonneg k) (hh N)], ?_⟩
      rw [← hNh N hN]
      nlinarith [hh N]
    have hgrid := eulerPoly_grid g t₀ (T / N) (hh N) y₀ N k hk.le
    have h1 : ‖eulerGrid g t₀ (T / N) y₀ k - P N s‖ ≤ M * |t₀ + k * (T / N) - s| := by
      rw [← hgrid]; exact hlip' N hN s hs _ hkmem
    have h2 : dist (eulerGrid g t₀ (T / N) y₀ k) (y s) < δ := by
      rw [dist_eq_norm]
      calc ‖eulerGrid g t₀ (T / N) y₀ k - y s‖
          ≤ ‖eulerGrid g t₀ (T / N) y₀ k - P N s‖ + ‖P N s - y s‖ := norm_sub_le_norm_sub_add_norm_sub _ _ _
        _ < δ / 2 + δ / 2 := by
          refine add_lt_add_of_le_of_lt ?_ (by rwa [← dist_eq_norm])
          exact h1.trans ((mul_le_mul_of_nonneg_left hks.le hM0).trans (by linarith))
        _ = δ := by ring
    have h3 := hcont (t₀ + k * (T / N), eulerGrid g t₀ (T / N) y₀ k) (by
      rw [Prod.dist_eq, max_lt_iff, Real.dist_eq]
      exact ⟨by linarith, h2⟩)
    rw [dist_eq_norm] at h3
    exact h3.le
  rcases le_total s t with hst | hst
  · rw [abs_of_nonneg (by linarith)]
    refine hest N hN w ε s t hs.1 hst ht.2 fun k hk h1 h2 => key k hk ?_
    rw [abs_lt]; constructor <;> linarith [abs_lt.1 htη, hh N]
  · rw [abs_of_nonpos (by linarith)]
    have := hest N hN w ε t s ht.1 hst hs.2 fun k hk h1 h2 => key k hk (by
      rw [abs_lt]; constructor <;> linarith [abs_lt.1 htη, hh N])
    rw [← norm_neg]
    convert this using 2
    · simp only [neg_sub, sub_smul]; abel
    · ring

/-- Peano on a box `[t₀, t₀ + a] × closedBall y₀ b`: clamp time into `[t₀, t₀ + a]` and pull
values radially back into the ball, solve the clamped law with `peano_core`, and note that the
solution never leaves the box, where the clamped law is the original one. -/
theorem peano_box {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [ProperSpace E]
    (f : ℝ → E → E) (t₀ : ℝ) (y₀ : E) {a b M : ℝ} (ha : 0 < a) (hb : 0 < b)
    (hf : ContinuousOn (fun p : ℝ × E => f p.1 p.2) (Icc t₀ (t₀ + a) ×ˢ closedBall y₀ b))
    (hM : ∀ t ∈ Icc t₀ (t₀ + a), ∀ x ∈ closedBall y₀ b, ‖f t x‖ ≤ M) :
    ∃ y : ℝ → E, y t₀ = y₀ ∧
      ∀ t ∈ Icc t₀ (t₀ + min a (b / M)),
        HasDerivWithinAt y (f t (y t)) (Icc t₀ (t₀ + min a (b / M))) t := by
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM t₀ ⟨le_rfl, by linarith⟩ y₀ (mem_closedBall_self hb.le))
  set τ : ℝ → ℝ := fun t => max t₀ (min (t₀ + a) t) with hτ
  set r : E → E := fun x => y₀ + (b / max b ‖x - y₀‖) • (x - y₀) with hr
  have hmax : ∀ x : E, 0 < max b ‖x - y₀‖ := fun x => lt_max_of_lt_left hb
  have hτmem : ∀ t, τ t ∈ Icc t₀ (t₀ + a) :=
    fun t => ⟨le_max_left _ _, max_le (by linarith) (min_le_left _ _)⟩
  have hrmem : ∀ x, r x ∈ closedBall y₀ b := by
    intro x
    rw [mem_closedBall, dist_eq_norm, hr]
    simp only [add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
      abs_of_pos (div_pos hb (hmax x))]
    rw [div_mul_eq_mul_div, div_le_iff₀ (hmax x)]
    exact mul_le_mul_of_nonneg_left (le_max_right _ _) hb.le
  have hτid : ∀ t ∈ Icc t₀ (t₀ + a), τ t = t := fun t ht => by
    simp only [hτ, min_eq_right ht.2, max_eq_right ht.1]
  have hrid : ∀ x ∈ closedBall y₀ b, r x = x := by
    intro x hx
    rw [mem_closedBall, dist_eq_norm] at hx
    simp only [hr, max_eq_left hx, div_self hb.ne', one_smul, add_sub_cancel]
  have hτc : Continuous τ := continuous_const.max (continuous_const.min continuous_id)
  have hrc : Continuous r := by
    refine continuous_const.add (Continuous.smul ?_ (continuous_id.sub continuous_const))
    exact continuous_const.div (continuous_const.max ((continuous_id.sub continuous_const).norm))
      fun x => (hmax x).ne'
  set g : ℝ → E → E := fun t x => f (τ t) (r x) with hg
  have hgc : Continuous (fun p : ℝ × E => g p.1 p.2) := by
    have : (fun p : ℝ × E => g p.1 p.2) =
        (fun q : ℝ × E => f q.1 q.2) ∘ (fun p : ℝ × E => (τ p.1, r p.2)) := rfl
    rw [this]
    exact hf.comp_continuous ((hτc.comp continuous_fst).prodMk (hrc.comp continuous_snd))
      fun p => ⟨hτmem p.1, hrmem p.2⟩
  have hgM : ∀ t x, ‖g t x‖ ≤ M := fun t x => hM _ (hτmem t) _ (hrmem x)
  set T := min a (b / M) with hT
  have hT0 : 0 ≤ T := le_min ha.le (div_nonneg hb.le hM0)
  have hTa : T ≤ a := min_le_left _ _
  have hMT : M * T ≤ b := by
    rcases hM0.eq_or_lt with h | h
    · rw [← h]; simp [hb.le]
    · calc M * T ≤ M * (b / M) := mul_le_mul_of_nonneg_left (min_le_right _ _) hM0
        _ = b := by field_simp
  obtain ⟨y, hy0, hyb, hyd⟩ := peano_core g hgc hgM t₀ T hT0 y₀
  refine ⟨y, hy0, fun t ht => ?_⟩
  have h1 : t ∈ Icc t₀ (t₀ + a) := ⟨ht.1, by linarith [ht.2]⟩
  have h2 : y t ∈ closedBall y₀ b := by
    rw [mem_closedBall, dist_eq_norm]
    refine (hyb t ht).trans ((mul_le_mul_of_nonneg_left (by linarith [ht.2]) hM0).trans hMT)
  have := hyd t ht
  simp only [hg, hτid t h1, hrid _ h2] at this
  exact this

/-- Peano's existence theorem. Let the rate law f(t, y), with y a point of R^n, be continuous
on the box of times 0 ≤ t ≤ a and values within b of the start y0, and let M bound its size
there. Then some y with y(0) = y0 solves y' = f(t, y) for 0 ≤ t ≤ T = min(a, b/M). -/
theorem peano_existence {n : ℕ} (f : ℝ → EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (y₀ : EuclideanSpace ℝ (Fin n)) {a b M : ℝ} (ha : 0 < a) (hb : 0 < b)
    (hf : ContinuousOn (fun p : ℝ × EuclideanSpace ℝ (Fin n) => f p.1 p.2)
      (Icc 0 a ×ˢ closedBall y₀ b))
    (hM : ∀ t ∈ Icc 0 a, ∀ x ∈ closedBall y₀ b, ‖f t x‖ ≤ M) :
    ∃ y : ℝ → EuclideanSpace ℝ (Fin n), y 0 = y₀ ∧
      ∀ t ∈ Icc 0 (min a (b / M)), HasDerivWithinAt y (f t (y t)) (Icc 0 (min a (b / M))) t := by
  have := peano_box f 0 y₀ ha hb (by simpa using hf) (by simpa using hM)
  simpa using this

/-- A maximal solution leaves every closed bounded set. Let f(t, y), with y in R^n, be
continuous for all times and values. If y solves y' = f(t, y) for 0 ≤ t < T₊ and no solution
on a longer interval 0 ≤ t < T' agrees with it before T₊ (y is maximal), then the length |y(t)|
grows past every bound as t rises to the finite end T₊. -/
theorem maximal_solution_escapes_every_bounded_set {n : ℕ}
    (f : ℝ → EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (hf : Continuous (fun p : ℝ × EuclideanSpace ℝ (Fin n) => f p.1 p.2))
    (y : ℝ → EuclideanSpace ℝ (Fin n)) {Tp : ℝ} (hTp : 0 < Tp)
    (hy : ∀ t ∈ Ico 0 Tp, HasDerivWithinAt y (f t (y t)) (Ici 0) t)
    (hmax : ∀ T' > Tp, ∀ z : ℝ → EuclideanSpace ℝ (Fin n),
      (∀ t ∈ Ico 0 T', HasDerivWithinAt z (f t (z t)) (Ici 0) t) →
      (∀ t ∈ Ico 0 Tp, z t = y t) → False) :
    Tendsto (fun t => ‖y t‖) (𝓝[<] Tp) atTop := by
  classical
  by_contra hcon
  obtain ⟨R, hR⟩ := not_forall.1 (mt Filter.tendsto_atTop.2 hcon)
  rw [Filter.not_eventually] at hR
  -- inside `(0, Tp)` the solution has a two-sided derivative
  have hyd : ∀ t ∈ Ioo 0 Tp, HasDerivAt y (f t (y t)) t :=
    fun t ht => (hy t ⟨ht.1.le, ht.2⟩).hasDerivAt (Ici_mem_nhds ht.1)
  -- a speed bound on the closed bounded set `[0, Tp] × closedBall 0 (R + 1)`
  obtain ⟨K, hK⟩ := (isCompact_Icc.prod (isCompact_closedBall
    (0 : EuclideanSpace ℝ (Fin n)) (R + 1))).exists_bound_of_continuousOn hf.continuousOn
  set K₀ := max K 0 with hK₀
  have hK₀0 : 0 ≤ K₀ := le_max_right _ _
  have hK₀b : ∀ t ∈ Icc 0 Tp, ∀ x ∈ closedBall (0 : EuclideanSpace ℝ (Fin n)) (R + 1),
      ‖f t x‖ ≤ K₀ := fun t ht x hx => (hK (t, x) ⟨ht, hx⟩).trans (le_max_left _ _)
  -- a time `t₁` close to `Tp` where the solution is inside the ball of radius `R`
  have hlo : max 0 (Tp - 1 / (K₀ + 1)) < Tp :=
    max_lt hTp (by have : 0 < 1 / (K₀ + 1) := by positivity
                   linarith)
  obtain ⟨t₁, ht₁R, ht₁⟩ := (hR.and_eventually (Ioo_mem_nhdsLT hlo)).exists
  rw [not_le] at ht₁R
  have ht₁0 : 0 < t₁ := lt_of_le_of_lt (le_max_left _ _) ht₁.1
  have hgap : (K₀ + 1) * (Tp - t₁) < 1 := by
    have h1 : Tp - 1 / (K₀ + 1) < t₁ := lt_of_le_of_lt (le_max_right _ _) ht₁.1
    have h2 : Tp - t₁ < 1 / (K₀ + 1) := by linarith
    rw [lt_div_iff₀ (by positivity)] at h2
    linarith
  -- after `t₁` the solution stays inside the ball of radius `R + 1`
  have hstay : ∀ x ∈ Ico t₁ Tp, ‖y x - y t₁‖ ≤ (K₀ + 1) * (x - t₁) := by
    intro x hx
    have := image_norm_le_of_norm_deriv_right_lt_deriv_boundary'
      (f := fun u => y u - y t₁) (f' := fun u => f u (y u)) (a := t₁) (b := x)
      (B := fun u => (K₀ + 1) * (u - t₁)) (B' := fun _ => K₀ + 1)
      (fun u hu => ((hyd u ⟨ht₁0.trans_le hu.1, hu.2.trans_lt hx.2⟩).continuousAt.sub
        continuousAt_const).continuousWithinAt)
      (fun u hu => ((hyd u ⟨ht₁0.trans_le hu.1, hu.2.trans hx.2⟩).sub_const (y t₁)).hasDerivWithinAt)
      (by simp)
      (by fun_prop)
      (fun u _ => by
        have := ((hasDerivAt_id u).sub_const t₁).const_mul (K₀ + 1)
        simpa using this.hasDerivWithinAt)
      (fun u hu heq => by
        have hu' : ‖y u‖ ≤ R + 1 := by
          have h3 : ‖y u - y t₁‖ < 1 := by
            rw [heq]
            have : (K₀ + 1) * (u - t₁) ≤ (K₀ + 1) * (Tp - t₁) :=
              mul_le_mul_of_nonneg_left (by linarith [hu.2, hx.2]) (by linarith)
            linarith
          have := norm_le_norm_add_norm_sub' (y u) (y t₁)
          rw [norm_sub_rev] at h3
          linarith [norm_sub_rev (y u) (y t₁)]
        have := hK₀b u ⟨ht₁0.le.trans hu.1, (hu.2.trans hx.2).le⟩ (y u)
          (mem_closedBall_zero_iff.2 hu')
        show ‖f u (y u)‖ < K₀ + 1
        linarith)
    exact this ⟨hx.1, le_rfl⟩
  have hbd : ∀ x ∈ Ico t₁ Tp, ‖f x (y x)‖ ≤ K₀ := by
    intro x hx
    have h3 : ‖y x - y t₁‖ < 1 := by
      have : (K₀ + 1) * (x - t₁) ≤ (K₀ + 1) * (Tp - t₁) :=
        mul_le_mul_of_nonneg_left (by linarith [hx.2]) (by linarith)
      linarith [hstay x hx]
    have hx' : ‖y x‖ ≤ R + 1 := by
      have := norm_le_norm_add_norm_sub' (y x) (y t₁)
      linarith [norm_sub_rev (y x) (y t₁)]
    exact hK₀b x ⟨ht₁0.le.trans hx.1, hx.2.le⟩ (y x) (mem_closedBall_zero_iff.2 hx')
  -- so `y` is `K₀`-Lipschitz on `[t₁, Tp)`
  have hlip : ∀ u v, t₁ ≤ u → u ≤ v → v < Tp → ‖y v - y u‖ ≤ K₀ * (v - u) := by
    intro u v hu huv hv
    refine norm_image_sub_le_of_norm_deriv_le_segment' (f' := fun x => f x (y x))
      (fun x hx => (hyd x ⟨ht₁0.trans_le (hu.trans hx.1), hx.2.trans_lt hv⟩).hasDerivWithinAt)
      (fun x hx => hbd x ⟨hu.trans hx.1, hx.2.trans hv⟩) v ⟨huv, le_rfl⟩
  -- hence `y` has a limit `p` as `t` rises to `Tp`
  obtain ⟨p, hp⟩ : ∃ p, Tendsto y (𝓝[<] Tp) (𝓝 p) := by
    refine cauchy_map_iff_exists_tendsto.1 (Metric.cauchy_iff.2 ⟨inferInstance, fun ε hε => ?_⟩)
    have hlo' : max t₁ (Tp - ε / (K₀ + 1)) < Tp :=
      max_lt ht₁.2 (by have : 0 < ε / (K₀ + 1) := by positivity
                       linarith)
    refine ⟨y '' Ioo (max t₁ (Tp - ε / (K₀ + 1))) Tp, image_mem_map (Ioo_mem_nhdsLT hlo'), ?_⟩
    rintro _ ⟨u, hu, rfl⟩ _ ⟨v, hv, rfl⟩
    have hu1 := lt_of_le_of_lt (le_max_left _ _) hu.1
    have hv1 := lt_of_le_of_lt (le_max_left _ _) hv.1
    have hu2 := lt_of_le_of_lt (le_max_right _ _) hu.1
    have hv2 := lt_of_le_of_lt (le_max_right _ _) hv.1
    have hd : |v - u| < ε / (K₀ + 1) := by
      rw [abs_lt]; constructor <;> linarith [hu.2, hv.2]
    rw [lt_div_iff₀ (by positivity)] at hd
    rw [dist_eq_norm]
    have hb : ‖y u - y v‖ ≤ K₀ * |v - u| := by
      rcases le_total u v with h | h
      · rw [norm_sub_rev, abs_of_nonneg (by linarith)]
        exact hlip u v hu1.le h hv.2
      · rw [abs_of_nonpos (by linarith), neg_sub]
        exact hlip v u hv1.le h hu.2
    have : K₀ * |v - u| ≤ |v - u| * (K₀ + 1) := by nlinarith [abs_nonneg (v - u)]
    linarith
  -- a Peano solution `w` from `(Tp, p)`
  obtain ⟨C, hC⟩ := (isCompact_Icc (a := Tp) (b := Tp + 1)).prod (isCompact_closedBall p 1)
    |>.exists_bound_of_continuousOn hf.continuousOn
  set M := max C 0 + 1 with hMdef
  have hM0 : 0 < M := by positivity
  obtain ⟨w, hw0, hwd⟩ := peano_box f Tp p one_pos one_pos hf.continuousOn
    (M := M) (fun t ht x hx => (hC (t, x) ⟨ht, hx⟩).trans (by linarith [le_max_left C 0]))
  set T := min 1 (1 / M) with hT
  have hT0 : 0 < T := lt_min one_pos (by positivity)
  -- glue: `y` before `Tp`, `w` from `Tp` on
  set z : ℝ → EuclideanSpace ℝ (Fin n) := fun t => if t < Tp then y t else w t with hz
  have hzy : ∀ t, t < Tp → z t = y t := fun t ht => by simp [hz, ht]
  have hzw : ∀ t, Tp ≤ t → z t = w t := fun t ht => by simp [hz, not_lt.2 ht]
  refine hmax (Tp + T) (by linarith) z (fun t ht => ?_) (fun t ht => hzy t ht.2)
  rcases lt_trichotomy t Tp with h | rfl | h
  · rw [hzy t h]
    refine (hy t ⟨ht.1, h⟩).congr_of_eventuallyEq ?_ (hzy t h)
    exact Filter.eventually_of_mem (nhdsWithin_le_nhds (Iio_mem_nhds h)) fun u hu => hzy u hu
  · rw [hzw t le_rfl, hw0]
    -- right side: from `w`
    have hright : HasDerivWithinAt z (f t p) (Ici t) t := by
      have := (hwd t ⟨le_rfl, by linarith⟩).mono_of_mem_nhdsWithin
        (Icc_mem_nhdsGE (show t < t + T by linarith))
      rw [hw0] at this
      exact this.congr_of_eventuallyEq
        (Filter.eventually_of_mem self_mem_nhdsWithin fun u hu => hzw u hu) (by rw [hzw t le_rfl, hw0])
    -- left side: the derivative `f u (y u)` tends to `f t p`
    have hleft : HasDerivWithinAt z (f t p) (Iic t) t := by
      have hs : Ioo t₁ t ∈ 𝓝[<] t := Ioo_mem_nhdsLT ht₁.2
      have hzy' : z =ᶠ[𝓝[<] t] y := Filter.eventually_of_mem self_mem_nhdsWithin fun u hu => hzy u hu
      refine hasDerivWithinAt_Iic_of_tendsto_deriv (s := Ioo t₁ t) ?_ ?_ hs ?_
      · intro u hu
        have hu' : u ∈ Ioo 0 t := ⟨ht₁0.trans hu.1, hu.2⟩
        exact ((hyd u hu').congr_of_eventuallyEq
          (Filter.eventually_of_mem (Iio_mem_nhds hu.2) fun v hv => hzy v hv)).differentiableAt.differentiableWithinAt
      · have : Tendsto z (𝓝[<] t) (𝓝 (z t)) := by
          rw [hzw t le_rfl, hw0]
          exact hp.congr' hzy'.symm
        exact this.mono_left (nhdsWithin_mono _ Ioo_subset_Iio_self)
      · have hlim : Tendsto (fun u => f u (y u)) (𝓝[<] t) (𝓝 (f t p)) :=
          (hf.tendsto (t, p)).comp ((tendsto_nhdsWithin_of_tendsto_nhds tendsto_id).prodMk_nhds hp)
        refine hlim.congr' ?_
        filter_upwards [hs] with u hu
        have hu' : u ∈ Ioo 0 t := ⟨ht₁0.trans hu.1, hu.2⟩
        exact ((hyd u hu').congr_of_eventuallyEq
          (Filter.eventually_of_mem (Iio_mem_nhds hu.2) fun v hv => hzy v hv)).deriv.symm
    have := hleft.union hright
    rw [Iic_union_Ici] at this
    exact (hasDerivWithinAt_univ.1 this).hasDerivWithinAt
  · have h2 : t < Tp + T := ht.2
    rw [hzw t h.le]
    have := (hwd t ⟨h.le, h2.le⟩).hasDerivAt (Icc_mem_nhds h h2)
    exact (this.congr_of_eventuallyEq (Filter.eventually_of_mem (Ioi_mem_nhds h) fun u hu => hzw u (le_of_lt hu))
      ).hasDerivWithinAt

/-- One start, two futures. The rate law y' = sqrt|y| is continuous, and from y(0) = 0 both
y = 0 and y = t^2/4 solve it for t ≥ 0; they differ at time 2, where t^2/4 equals 1. -/
theorem sqrt_abs_has_two_solutions :
    (∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt (fun _ : ℝ => (0 : ℝ)) (Real.sqrt |(0 : ℝ)|) (Ici 0) t) ∧
    (∀ t ∈ Ici (0 : ℝ),
      HasDerivWithinAt (fun s : ℝ => s ^ 2 / 4) (Real.sqrt |t ^ 2 / 4|) (Ici 0) t) ∧
    (0 : ℝ) ^ 2 / 4 = 0 ∧ (2 : ℝ) ^ 2 / 4 = 1 := by
  refine ⟨fun t _ => ?_, fun t ht => ?_, by norm_num, by norm_num⟩
  · simpa using hasDerivWithinAt_const t (Ici (0 : ℝ)) (0 : ℝ)
  · have ht' : (0 : ℝ) ≤ t := ht
    have hval : Real.sqrt |t ^ 2 / 4| = t / 2 := by
      rw [abs_of_nonneg (by positivity), show t ^ 2 / 4 = (t / 2) ^ 2 by ring,
        Real.sqrt_sq (by linarith)]
    rw [hval]
    have := ((hasDerivAt_pow 2 t).div_const 4).hasDerivWithinAt (s := Ici 0)
    convert this using 1
    push_cast
    ring

-- Worked numbers: the other solution at 2, the speed limit for 1 + y^2 in the box b = 1,
-- and the guaranteed window min(1, 1/2).
example : (2 : ℝ) ^ 2 / 4 = 1 := by norm_num
example : (1 : ℝ) + 1 ^ 2 = 2 := by norm_num
example : min (1 : ℝ) (1 / 2) = 1 / 2 := by norm_num

#print axioms eulerWeight_sum
#print axioms eulerWeight_mono
#print axioms eulerWeight_eq_of
#print axioms eulerWeight_est
#print axioms eulerGrid_eq_sum
#print axioms eulerPoly_grid
#print axioms eulerPoly_start
#print axioms peano_core
#print axioms peano_box
#print axioms peano_existence
#print axioms maximal_solution_escapes_every_bounded_set
#print axioms sqrt_abs_has_two_solutions
