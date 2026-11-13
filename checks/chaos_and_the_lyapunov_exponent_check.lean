-- The Lyapunov exponent: at growth factor 4 the logistic map's exponent is exactly ln 2 for almost every start in [0, 1], because the one-step stretches telescope to 2^n, while at growth factor 2.8 the orbit from 0.2 settles and its exponent is ln 0.8.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.MeasureTheory.OuterMeasure.BorelCantelli
import Mathlib.Analysis.Asymptotics.SpecificAsymptotics
import Mathlib.Analysis.SpecificLimits.Basic

open Real Filter Topology MeasureTheory

/-- The logistic map `x ↦ r x (1 - x)`. -/
def logistic (r x : ℝ) : ℝ := r * x * (1 - x)

/-- The orbit average of the logarithm of one step's stretch `|f'(x_k)| = |r (1 - 2 x_k)|`
over the first `n` steps from the start `x₀`: `(1/n) Σ_{k<n} ln |f'(x_k)|`.
The Lyapunov exponent is its limit as `n → ∞`. -/
noncomputable def lyapunovAvg (r x₀ : ℝ) (n : ℕ) : ℝ :=
  (1 / (n : ℝ)) * ∑ k ∈ Finset.range n, Real.log |r * (1 - 2 * (logistic r)^[k] x₀)|

theorem logistic_four_iterate_sin_sq (θ : ℝ) (k : ℕ) :
    (logistic 4)^[k] (Real.sin θ ^ 2) = Real.sin (2 ^ k * θ) ^ 2 := by
  induction k with
  | zero => simp
  | succ k ih =>
    have e : (2 : ℝ) ^ (k + 1) * θ = 2 * (2 ^ k * θ) := by rw [pow_succ]; ring
    rw [Function.iterate_succ_apply', ih, logistic, e, Real.sin_two_mul]
    have := Real.sin_sq_add_cos_sq (2 ^ k * θ)
    nlinarith [this]

#print axioms logistic_four_iterate_sin_sq

theorem logistic_four_iterate_mem (x : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) (m : ℕ) :
    (logistic 4)^[m] x ∈ Set.Icc (0 : ℝ) 1 := by
  induction m with
  | zero => simpa using hx
  | succ m ih =>
    rw [Function.iterate_succ_apply']
    generalize (logistic 4)^[m] x = y at ih ⊢
    obtain ⟨h0, h1⟩ := ih
    constructor
    · unfold logistic; nlinarith
    · unfold logistic; nlinarith [sq_nonneg (2 * y - 1)]

#print axioms logistic_four_iterate_mem

theorem logistic_four_near_root (x : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) (n : ℕ) (η : ℝ)
    (hη : 0 < η) (h : (logistic 4)^[n] x < η ^ 2) :
    ∃ k ∈ Finset.range (2 ^ n + 1),
      x ∈ Set.Icc (Real.sin (k * π / 2 ^ n) ^ 2 - π * η / 2 ^ n)
        (Real.sin (k * π / 2 ^ n) ^ 2 + π * η / 2 ^ n) := by
  obtain ⟨hx0, hx1⟩ := hx
  set θ := Real.arcsin (Real.sqrt x) with hθ
  have hs : Real.sin θ = Real.sqrt x :=
    Real.sin_arcsin (by linarith [Real.sqrt_nonneg x]) (Real.sqrt_le_one.mpr hx1)
  have hθx : Real.sin θ ^ 2 = x := by rw [hs, Real.sq_sqrt hx0]
  have hθ0 : 0 ≤ θ := Real.arcsin_nonneg.mpr (Real.sqrt_nonneg x)
  have hθ1 : θ ≤ π / 2 := Real.arcsin_le_pi_div_two _
  rw [← hθx, logistic_four_iterate_sin_sq] at h
  set y := 2 ^ n * θ with hy
  have hP : (0 : ℝ) < 2 ^ n := by positivity
  have hy0 : 0 ≤ y := by positivity
  have hyle : y ≤ 2 ^ n * π / 2 := by rw [hy]; nlinarith
  set k := ⌊y / π + 1 / 2⌋₊ with hk
  have hk1 : (k : ℝ) ≤ y / π + 1 / 2 := Nat.floor_le (by positivity)
  have hk2 : y / π + 1 / 2 < k + 1 := Nat.lt_floor_add_one _
  have hk1' : (k : ℝ) * π ≤ y + π / 2 := by
    have := mul_le_mul_of_nonneg_right hk1 pi_pos.le
    rw [add_mul, div_mul_cancel₀ _ pi_ne_zero] at this; linarith
  have hk2' : y + π / 2 < (k : ℝ) * π + π := by
    have := mul_lt_mul_of_pos_right hk2 pi_pos
    rw [add_mul, add_mul, div_mul_cancel₀ _ pi_ne_zero] at this; linarith
  set z := y - k * π with hz
  have hsz : |Real.sin y| = |Real.sin z| := by
    have : y = z + k * π := by rw [hz]; ring
    rw [this, Real.sin_add_nat_mul_pi, abs_mul, abs_pow, abs_neg, abs_one, one_pow, one_mul]
  have hlow : 2 / π * |z| ≤ |Real.sin z| := by
    rcases le_total 0 z with hz0 | hz0
    · rw [abs_of_nonneg hz0]
      exact (Real.mul_le_sin hz0 (by linarith)).trans (le_abs_self _)
    · rw [abs_of_nonpos hz0]
      have := Real.mul_le_sin (neg_nonneg.mpr hz0) (by linarith)
      rw [Real.sin_neg] at this
      exact this.trans (neg_le_abs _)
  have hsy : |Real.sin y| < η := abs_lt_of_sq_lt_sq h hη.le
  have hzlt : 2 * |z| < π * η := by
    have h3 : 2 / π * |z| < η := by linarith
    rw [div_mul_eq_mul_div, div_lt_iff₀ pi_pos] at h3; linarith
  have hkle : k ≤ 2 ^ n := by
    have : (k : ℝ) < 2 ^ n + 1 := by
      have : (k : ℝ) * π < 2 ^ n * π + π := by nlinarith
      nlinarith [pi_pos]
    exact_mod_cast Nat.lt_succ_iff.mp (by exact_mod_cast this)
  refine ⟨k, Finset.mem_range.mpr (Nat.lt_succ_of_le hkle), ?_⟩
  set b := (k : ℝ) * π / 2 ^ n with hb
  have hθb : θ - b = z / 2 ^ n := by rw [hz, hy, hb]; field_simp
  have hdiff : |Real.sin θ ^ 2 - Real.sin b ^ 2| ≤ π * η / 2 ^ n := by
    have e : Real.sin θ ^ 2 - Real.sin b ^ 2 =
        (Real.sin θ - Real.sin b) * (Real.sin θ + Real.sin b) := by ring
    have hsum : |Real.sin θ + Real.sin b| ≤ 2 := by
      have := abs_add_le (Real.sin θ) (Real.sin b)
      linarith [Real.abs_sin_le_one θ, Real.abs_sin_le_one b]
    have h1 := Real.abs_sin_sub_sin_le θ b
    rw [hθb, abs_div, abs_of_pos hP] at h1
    rw [e, abs_mul]
    calc |Real.sin θ - Real.sin b| * |Real.sin θ + Real.sin b|
        ≤ |z| / 2 ^ n * 2 := mul_le_mul h1 hsum (abs_nonneg _) (by positivity)
      _ = 2 * |z| / 2 ^ n := by ring
      _ ≤ π * η / 2 ^ n := by gcongr
  rw [abs_le] at hdiff
  constructor <;> linarith [hdiff.1, hdiff.2]

#print axioms logistic_four_near_root

theorem logistic_four_small_measure (n : ℕ) (η : ℝ) (hη : 0 < η) :
    volume ({x | (logistic 4)^[n] x < η ^ 2} ∩ Set.Icc (0 : ℝ) 1) ≤
      ENNReal.ofReal (4 * π * η) := by
  set a := π * η / 2 ^ n with ha
  set c : ℕ → ℝ := fun k => Real.sin (k * π / 2 ^ n) ^ 2 with hc
  have hsub : {x | (logistic 4)^[n] x < η ^ 2} ∩ Set.Icc (0 : ℝ) 1 ⊆
      ⋃ k ∈ Finset.range (2 ^ n + 1), Set.Icc (c k - a) (c k + a) := by
    intro x ⟨hx1, hx2⟩
    obtain ⟨k, hk, hmem⟩ := logistic_four_near_root x hx2 n η hη hx1
    exact Set.mem_biUnion hk hmem
  have hvol : ∀ k, volume (Set.Icc (c k - a) (c k + a)) = ENNReal.ofReal (2 * a) := by
    intro k; rw [Real.volume_Icc]; ring_nf
  have hP : (1 : ℝ) ≤ 2 ^ n := one_le_pow₀ (by norm_num)
  have ha0 : 0 ≤ a := by positivity
  calc volume ({x | (logistic 4)^[n] x < η ^ 2} ∩ Set.Icc (0 : ℝ) 1)
      ≤ volume (⋃ k ∈ Finset.range (2 ^ n + 1), Set.Icc (c k - a) (c k + a)) :=
        measure_mono hsub
    _ ≤ ∑ k ∈ Finset.range (2 ^ n + 1), volume (Set.Icc (c k - a) (c k + a)) :=
        measure_biUnion_finset_le _ _
    _ = ((2 ^ n + 1 : ℕ) : ENNReal) * ENNReal.ofReal (2 * a) := by
        simp only [hvol, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    _ = ENNReal.ofReal ((2 ^ n + 1 : ℕ) * (2 * a)) := by
        rw [ENNReal.ofReal_mul (p := ((2 ^ n + 1 : ℕ) : ℝ)) (by positivity), ENNReal.ofReal_natCast]
    _ ≤ ENNReal.ofReal (4 * π * η) := by
        apply ENNReal.ofReal_le_ofReal
        have h2 : (2 : ℝ) ^ n * a = π * η := by rw [ha]; field_simp
        have h3 : a ≤ π * η := by rw [ha]; exact div_le_self (by positivity) hP
        push_cast
        nlinarith

#print axioms logistic_four_small_measure

theorem logistic_four_ae_eventually_ge (r : ℝ) (hr0 : 0 < r) (hr1 : r < 1) :
    ∀ᵐ x ∂(volume.restrict (Set.Icc (0 : ℝ) 1)),
      ∀ᶠ n in atTop, (r ^ n) ^ 2 ≤ (logistic 4)^[n] x := by
  have hs : (∑' n, volume.restrict (Set.Icc (0 : ℝ) 1)
      {x | (logistic 4)^[n] x < (r ^ n) ^ 2}) ≠ ⊤ := by
    have hsum : Summable (fun n : ℕ => 4 * π * r ^ n) :=
      (summable_geometric_of_lt_one hr0.le hr1).mul_left _
    refine ne_top_of_le_ne_top (b := ∑' n : ℕ, ENNReal.ofReal (4 * π * r ^ n)) ?_ ?_
    · rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => by positivity) hsum]
      exact ENNReal.ofReal_ne_top
    · refine tsum_le_tsum (fun n => ?_)
      rw [Measure.restrict_apply' measurableSet_Icc]
      exact logistic_four_small_measure n (r ^ n) (by positivity)
  filter_upwards [ae_eventually_notMem hs] with x hx
  filter_upwards [hx] with n hn
  exact not_lt.mp hn

#print axioms logistic_four_ae_eventually_ge

theorem logistic_four_log_step (x : ℝ) (k : ℕ) (h : (logistic 4)^[k + 2] x ≠ 0) :
    2 * Real.log |4 * (1 - 2 * (logistic 4)^[k] x)| + Real.log ((logistic 4)^[k + 1] x) =
      2 * Real.log 2 + Real.log ((logistic 4)^[k + 2] x) := by
  rw [Function.iterate_succ_apply'] at h ⊢
  rw [Function.iterate_succ_apply', Function.iterate_succ_apply'] at *
  set y := (logistic 4)^[k] x
  have key : (4 * (1 - 2 * y)) ^ 2 * logistic 4 y = 4 * logistic 4 (logistic 4 y) := by
    unfold logistic; ring
  have h4 : (4 * (1 - 2 * y)) ^ 2 * logistic 4 y ≠ 0 := by
    rw [key]; exact mul_ne_zero (by norm_num) h
  have ha : (4 * (1 - 2 * y)) ^ 2 ≠ 0 := left_ne_zero_of_mul h4
  have hb : logistic 4 y ≠ 0 := right_ne_zero_of_mul h4
  have e := congrArg Real.log key
  have h42 : Real.log 4 = 2 * Real.log 2 := by
    rw [show (4 : ℝ) = 2 ^ 2 by norm_num, Real.log_pow]; norm_num
  rw [Real.log_mul ha hb, Real.log_mul (by norm_num) h, Real.log_pow, h42,
    ← Real.log_abs (4 * (1 - 2 * y))] at e
  push_cast at e
  linarith

#print axioms logistic_four_log_step

theorem logistic_four_log_sum (x : ℝ) (h : ∀ m, (logistic 4)^[m] x ≠ 0) (n : ℕ) :
    ∑ k ∈ Finset.range n, Real.log |4 * (1 - 2 * (logistic 4)^[k] x)| =
      n * Real.log 2 + (Real.log ((logistic 4)^[n + 1] x) - Real.log ((logistic 4)^[1] x)) / 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, ih]
    have := logistic_four_log_step x n (h (n + 2))
    push_cast
    rw [show n + 1 + 1 = n + 2 by ring]
    linarith

#print axioms logistic_four_log_sum

theorem logistic_four_iterate_zero (m : ℕ) : (logistic 4)^[m] 0 = 0 :=
  Function.iterate_fixed (by norm_num [logistic]) m

#print axioms logistic_four_iterate_zero

theorem settled_contract (y : ℝ) (hy : |y - 9 / 14| ≤ 1 / 20) :
    |logistic (14 / 5) y - 9 / 14| ≤ 47 / 50 * |y - 9 / 14| := by
  have h : logistic (14 / 5) y - 9 / 14 = (1 - 14 / 5 * y) * (y - 9 / 14) := by
    unfold logistic; ring
  rw [h, abs_mul]
  apply mul_le_mul_of_nonneg_right _ (abs_nonneg _)
  rw [abs_le] at hy ⊢
  constructor <;> linarith [hy.1, hy.2]

#print axioms settled_contract

theorem settled_orbit_bound (k : ℕ) :
    |(logistic (14 / 5))^[k + 3] (1 / 5) - 9 / 14| ≤ 1 / 20 * (47 / 50) ^ k := by
  induction k with
  | zero => norm_num [logistic, abs_le]
  | succ k ih =>
    rw [show k + 1 + 3 = (k + 3) + 1 by ring, Function.iterate_succ_apply']
    have hy : |(logistic (14 / 5))^[k + 3] (1 / 5) - 9 / 14| ≤ 1 / 20 :=
      ih.trans (mul_le_of_le_one_right (by norm_num) (pow_le_one₀ (by norm_num) (by norm_num)))
    calc _ ≤ 47 / 50 * |(logistic (14 / 5))^[k + 3] (1 / 5) - 9 / 14| := settled_contract _ hy
      _ ≤ 47 / 50 * (1 / 20 * (47 / 50) ^ k) := by gcongr
      _ = _ := by ring

#print axioms settled_orbit_bound

theorem settled_orbit_tendsto :
    Tendsto (fun k => (logistic (14 / 5))^[k] (1 / 5)) atTop (𝓝 (9 / 14)) := by
  rw [← Filter.tendsto_add_atTop_iff_nat 3]
  have hg : Tendsto (fun k : ℕ => 1 / 20 * (47 / 50 : ℝ) ^ k) atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 47 / 50)
      (by norm_num)).const_mul (1 / 20 : ℝ)
  have := squeeze_zero (fun k => abs_nonneg _) settled_orbit_bound hg
  rw [tendsto_iff_norm_sub_tendsto_zero]
  simpa [Real.norm_eq_abs] using this

#print axioms settled_orbit_tendsto

/-- The card's main theorem: at growth factor 4, for a typical start (every start in [0, 1]
outside a set of length zero), the long-run average of ln of one step's stretch tends to
ln 2, so the Lyapunov exponent is exactly ln 2: one binary digit of the start lost per step. -/
theorem lyapunov_exponent_logistic_four_eq_log_two :
    ∀ᵐ x₀ ∂(volume.restrict (Set.Icc (0 : ℝ) 1)),
      Tendsto (lyapunovAvg 4 x₀) atTop (𝓝 (Real.log 2)) := by
  set r : ℕ → ℝ := fun j => Real.exp (-(1 / ((j : ℝ) + 1)) / 2) with hr
  have hr0 : ∀ j, 0 < r j := fun j => Real.exp_pos _
  have hr1 : ∀ j, r j < 1 := fun j => by
    rw [hr]; apply Real.exp_lt_one_iff.mpr
    have : 0 < 1 / ((j : ℝ) + 1) := by positivity
    linarith
  have hlogr : ∀ (j m : ℕ), Real.log ((r j ^ m) ^ 2) = -((m : ℝ) * (1 / ((j : ℝ) + 1))) := by
    intro j m
    rw [Real.log_pow, Real.log_pow, hr, Real.log_exp]
    push_cast; ring
  have h1 : ∀ᵐ x ∂(volume.restrict (Set.Icc (0 : ℝ) 1)), x ∈ Set.Icc (0 : ℝ) 1 :=
    ae_restrict_mem measurableSet_Icc
  have h2 : ∀ᵐ x ∂(volume.restrict (Set.Icc (0 : ℝ) 1)),
      ∀ j : ℕ, ∀ᶠ n in atTop, (r j ^ n) ^ 2 ≤ (logistic 4)^[n] x :=
    ae_all_iff.mpr (fun j => logistic_four_ae_eventually_ge (r j) (hr0 j) (hr1 j))
  filter_upwards [h1, h2] with x hx hj
  have hmem := logistic_four_iterate_mem x hx
  have hne : ∀ m, (logistic 4)^[m] x ≠ 0 := by
    intro m hm
    obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (hj 0)
    have h3 := hN (N + m) (by omega)
    rw [Function.iterate_add_apply, hm, logistic_four_iterate_zero] at h3
    have : 0 < (r 0 ^ (N + m)) ^ 2 := by have := hr0 0; positivity
    linarith
  -- the tail term `log x_{n+1} / n` tends to zero
  have htail : Tendsto (fun n : ℕ => Real.log ((logistic 4)^[n + 1] x) / n) atTop (𝓝 0) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨j, hjε⟩ := exists_nat_one_div_lt (half_pos hε)
    obtain ⟨M, hM⟩ := Filter.eventually_atTop.mp (hj j)
    refine ⟨M + 1, fun n hn => ?_⟩
    have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast (show 1 ≤ n by omega)
    have hb := hM (n + 1) (by omega)
    have hpos : 0 < (logistic 4)^[n + 1] x :=
      lt_of_le_of_ne (hmem (n + 1)).1 (Ne.symm (hne (n + 1)))
    have hL0 : Real.log ((logistic 4)^[n + 1] x) ≤ 0 :=
      Real.log_nonpos (hmem (n + 1)).1 (hmem (n + 1)).2
    have hL1 : -(((n + 1 : ℕ) : ℝ) * (1 / ((j : ℝ) + 1))) ≤
        Real.log ((logistic 4)^[n + 1] x) := by
      rw [← hlogr j (n + 1)]
      exact Real.log_le_log (by have := hr0 j; positivity) hb
    push_cast at hL1
    set L := Real.log ((logistic 4)^[n + 1] x)
    set a := 1 / ((j : ℝ) + 1)
    have ha0 : 0 < a := by positivity
    rw [Real.dist_eq, sub_zero, abs_div, abs_of_nonpos hL0, Nat.abs_cast,
      div_lt_iff₀ (by linarith)]
    have h5 : ((n : ℝ) + 1) * a < ((n : ℝ) + 1) * (ε / 2) :=
      mul_lt_mul_of_pos_left hjε (by linarith)
    nlinarith
  have hlim : Tendsto (fun n : ℕ => Real.log 2 + 1 / 2 * (Real.log ((logistic 4)^[n + 1] x) / n)
      - 1 / 2 * (Real.log ((logistic 4)^[1] x) / n)) atTop (𝓝 (Real.log 2)) := by
    have := ((tendsto_const_nhds (x := Real.log 2)).add (htail.const_mul (1 / 2))).sub
      ((tendsto_const_div_atTop_nhds_zero_nat (Real.log ((logistic 4)^[1] x))).const_mul (1 / 2))
    simpa using this
  refine hlim.congr' ?_
  filter_upwards [Filter.eventually_ge_atTop 1] with n hn
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
  unfold lyapunovAvg
  rw [logistic_four_log_sum x hne n]
  field_simp
  ring

/-- Steps 3 and 4: write the start as `x₀ = sin² θ₀`. At growth factor 4 the angle doubles
each step, and the stretches telescope: `∏_{k<n} |f'(x_k)| = 2^n |sin 2θ_n| / |sin 2θ₀|`
with `θ_n = 2^n θ₀`. Stated with the denominator cleared, so it holds for every angle. -/
theorem stretches_telescope_to_two_pow (θ₀ : ℝ) (n : ℕ) :
    |Real.sin (2 * θ₀)| *
        ∏ k ∈ Finset.range n, |4 * (1 - 2 * (logistic 4)^[k] (Real.sin θ₀ ^ 2))| =
      2 ^ n * |Real.sin (2 * (2 ^ n * θ₀))| := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.prod_range_succ, ← mul_assoc, ih, logistic_four_iterate_sin_sq]
    set φ := 2 ^ n * θ₀
    have h1 : 2 * (2 ^ (n + 1) * θ₀) = 2 * (2 * φ) := by rw [pow_succ]; ring
    have h2 : 1 - 2 * Real.sin φ ^ 2 = Real.cos (2 * φ) := by
      rw [Real.cos_two_mul, Real.cos_sq']; ring
    rw [h1, h2, Real.sin_two_mul (2 * φ), pow_succ]
    simp only [abs_mul]
    norm_num
    ring

/-- Negative means settled: at growth factor 2.8, the orbit from 0.2 settles on the fixed
point 9/14, where the stretch is 0.8, and the Lyapunov exponent is ln 0.8 < 0. -/
theorem lyapunov_exponent_settled_at_two_point_eight :
    Tendsto (lyapunovAvg (14 / 5) (1 / 5)) atTop (𝓝 (Real.log (4 / 5))) := by
  have hu : Tendsto (fun k => Real.log |14 / 5 * (1 - 2 * (logistic (14 / 5))^[k] (1 / 5))|)
      atTop (𝓝 (Real.log (4 / 5))) := by
    have hc : ContinuousAt (fun y : ℝ => Real.log |14 / 5 * (1 - 2 * y)|) (9 / 14) := by
      apply ContinuousAt.log
      · fun_prop
      · norm_num [abs_of_neg]
    have := hc.tendsto.comp settled_orbit_tendsto
    have e : Real.log |14 / 5 * (1 - 2 * (9 / 14 : ℝ))| = Real.log (4 / 5) := by
      norm_num [abs_of_neg]
    rw [e] at this
    exact this
  have := hu.cesaro
  unfold lyapunovAvg
  simpa [one_div] using this

-- At growth factor 2.8 the fixed point is 9/14, and the stretch there is 0.8.
example : logistic (14 / 5) (9 / 14) = 9 / 14 := by norm_num [logistic]
example : |(14 / 5 : ℝ) * (1 - 2 * (9 / 14))| = 4 / 5 := by norm_num [abs_of_neg]

-- At growth factor 4 the start 0 is a fixed point, with stretch 4 (so ln 4 there).
example : logistic 4 0 = 0 := by norm_num [logistic]
example : |(4 : ℝ) * (1 - 2 * 0)| = 4 := by norm_num

-- At growth factor 4 the start 0.5 lands on 0: 0.5 goes to 1, and 1 goes to 0.
example : (logistic 4)^[2] (1 / 2) = 0 := by norm_num [logistic]

-- One step's stretch at 0.2 with growth factor 3.9 is 2.34.
example : |(39 / 10 : ℝ) * (1 - 2 * (1 / 5))| = 117 / 50 := by norm_num [abs_of_pos]

#print axioms lyapunov_exponent_logistic_four_eq_log_two
#print axioms stretches_telescope_to_two_pow
#print axioms lyapunov_exponent_settled_at_two_point_eight
