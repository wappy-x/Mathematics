-- Frechet mean: on the unit sphere, at a Frechet mean of data inside an open hemisphere the log-map arrows to the data add to zero, the squared distance has slope minus twice the log arrow, and bearings 0° and 180° have exactly two means.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.InverseDeriv
import Mathlib.Analysis.Normed.Group.AddCircle
import Mathlib.Analysis.Calculus.LocalExtr.Basic

open Real
open scoped RealInnerProductSpace

/-- Directions are unit arrows in ordinary three-dimensional space. -/
abbrev E3 := EuclideanSpace ℝ (Fin 3)

/-- The distance between two directions on the unit sphere: the angle `arccos (a · b)`. -/
noncomputable def sphDist (a b : E3) : ℝ := arccos ⟪a, b⟫

/-- The logarithm map at `m`: the arrow along the sphere at `m` aiming at `x`, as long as the
distance to `x`, namely `d (x - cos d m) / sin d` with `d = d(m, x)` (it is `0` when `x = m`). -/
noncomputable def sphLog (m x : E3) : E3 :=
  (sphDist m x / sin (sphDist m x)) • (x - cos (sphDist m x) • m)

/-- The Frechet function: the average squared distance from `m` to the data `x 0, ..., x (n-1)`. -/
noncomputable def frechetFn {n : ℕ} (x : Fin n → E3) (m : E3) : ℝ :=
  (1 / (n : ℝ)) * ∑ i, sphDist m (x i) ^ 2

/-- On the compass (bearings in degrees, `AddCircle 360`, distance the short way round),
the average squared distance from a bearing `θ` to the bearings `b i`. -/
noncomputable def compassScore {k : ℕ} (b : Fin k → AddCircle (360 : ℝ)) (θ : AddCircle (360 : ℝ)) : ℝ :=
  (1 / (k : ℝ)) * ∑ i, dist θ (b i) ^ 2

/-- Helper: the slope lemma, proved here so the main claim can use it. -/
lemma sq_dist_slope_aux (m x w : E3) (hmw : ⟪m, w⟫ = 0) (hd0 : 0 < sphDist m x) (hdπ : sphDist m x < π) :
    HasDerivAt (fun s : ℝ => sphDist (cos s • m + sin s • w) x ^ 2)
      (-2 * ⟪sphLog m x, w⟫) 0 := by
  have hd : sphDist m x = arccos ⟪m, x⟫ := rfl
  have ha1 : ⟪m, x⟫ ≠ 1 := by
    intro h; rw [hd, h, arccos_one] at hd0; exact lt_irrefl _ hd0
  have ham1 : ⟪m, x⟫ ≠ -1 := by
    intro h; rw [hd, h, arccos_neg_one] at hdπ; exact lt_irrefl _ hdπ
  have hfun : (fun s : ℝ => ⟪cos s • m + sin s • w, x⟫) =
      fun s => cos s * ⟪m, x⟫ + sin s * ⟪w, x⟫ := by
    funext s; rw [inner_add_left, real_inner_smul_left, real_inner_smul_left]
  have hg : HasDerivAt (fun s : ℝ => ⟪cos s • m + sin s • w, x⟫) ⟪w, x⟫ 0 := by
    rw [hfun]
    have := ((hasDerivAt_cos 0).mul_const ⟪m, x⟫).add ((hasDerivAt_sin 0).mul_const ⟪w, x⟫)
    convert this using 1; simp
  have hg0 : ⟪cos 0 • m + sin 0 • w, x⟫ = ⟪m, x⟫ := by simp
  have h1 : HasDerivAt arccos (-(1 / √(1 - ⟪m, x⟫ ^ 2))) ⟪cos 0 • m + sin 0 • w, x⟫ := by
    rw [hg0]; exact hasDerivAt_arccos ham1 ha1
  have h2 := (h1.comp 0 hg).pow 2
  have hsin : sin (sphDist m x) = √(1 - ⟪m, x⟫ ^ 2) := by rw [hd, sin_arccos]
  have hpos : 0 < √(1 - ⟪m, x⟫ ^ 2) := by
    rw [← hsin]; exact sin_pos_of_pos_of_lt_pi hd0 hdπ
  have hval : -2 * ⟪sphLog m x, w⟫ =
      ↑2 * (arccos ∘ fun s : ℝ => ⟪cos s • m + sin s • w, x⟫) 0 ^ (2 - 1) *
        (-(1 / √(1 - ⟪m, x⟫ ^ 2)) * ⟪w, x⟫) := by
    simp only [Function.comp, hg0]
    rw [sphLog, real_inner_smul_left, inner_sub_left, real_inner_smul_left, hmw, hsin,
      real_inner_comm w x, ← hd]
    field_simp
    ring
  rw [hval]
  exact h2

/-- Helper: for unit arrows, the inner product lies in `[-1, 1]`. -/
lemma inner_mem_Icc_of_unit {a b : E3} (ha : ‖a‖ = 1) (hb : ‖b‖ = 1) :
    -1 ≤ ⟪a, b⟫ ∧ ⟪a, b⟫ ≤ 1 := by
  have h := abs_le.mp (abs_real_inner_le_norm a b)
  rw [ha, hb, mul_one] at h
  exact h

/-- Helper: two unit arrows with inner product `1` are equal. -/
lemma eq_of_inner_eq_one {a b : E3} (ha : ‖a‖ = 1) (hb : ‖b‖ = 1) (h : ⟪a, b⟫ = 1) :
    a = b := by
  have h2 : ⟪a, b⟫ = ‖a‖ * ‖b‖ := by rw [ha, hb, h, mul_one]
  have := inner_eq_norm_mul_iff_real.mp h2
  rwa [ha, hb, one_smul, one_smul] at this

/-- Helper: the great circle through `m` in direction `w` stays on the unit sphere. -/
lemma norm_great_circle {m w : E3} (hm : ‖m‖ = 1) (hw : ‖w‖ = 1) (hmw : ⟪m, w⟫ = 0)
    (s : ℝ) : ‖cos s • m + sin s • w‖ = 1 := by
  have h : ‖cos s • m + sin s • w‖ ^ 2 = 1 := by
    rw [@norm_add_sq_real, norm_smul, norm_smul, real_inner_smul_left, real_inner_smul_right,
      hmw, hm, hw, Real.norm_eq_abs, Real.norm_eq_abs, mul_pow, mul_pow, sq_abs, sq_abs]
    nlinarith [sin_sq_add_cos_sq s]
  have h0 := norm_nonneg (cos s • m + sin s • w)
  nlinarith

/-- Helper: the log arrow at `m` is perpendicular to `m`. -/
lemma inner_sphLog_self {m x : E3} (hm : ‖m‖ = 1) (hx : ‖x‖ = 1) :
    ⟪sphLog m x, m⟫ = 0 := by
  obtain ⟨h1, h2⟩ := inner_mem_Icc_of_unit hm hx
  rw [sphLog, real_inner_smul_left, inner_sub_left, real_inner_smul_left,
    real_inner_self_eq_norm_sq, hm, sphDist, cos_arccos h1 h2, real_inner_comm]
  ring

/-- Helper: the slope of one squared distance, also when the data point is `m` itself. -/
lemma sq_dist_slope_term (m x w : E3) (hm : ‖m‖ = 1) (hx : ‖x‖ = 1)
    (hmw : ⟪m, w⟫ = 0) (hdπ : sphDist m x < π) :
    HasDerivAt (fun s : ℝ => sphDist (cos s • m + sin s • w) x ^ 2)
      (-2 * ⟪sphLog m x, w⟫) 0 := by
  rcases (arccos_nonneg ⟪m, x⟫).lt_or_eq with hd0 | hd0
  · exact sq_dist_slope_aux m x w hmw hd0 hdπ
  · have h1 : ⟪m, x⟫ = 1 := le_antisymm (inner_mem_Icc_of_unit hm hx).2
      (arccos_eq_zero.mp hd0.symm)
    have hxm : x = m := (eq_of_inner_eq_one hm hx h1).symm
    subst hxm
    have hlog : sphLog x x = 0 := by
      rw [sphLog, show sphDist x x = 0 from hd0.symm, zero_div, zero_smul]
    rw [hlog, inner_zero_left, mul_zero]
    have hsq : HasDerivAt (fun s : ℝ => s ^ 2) 0 0 := by
      simpa using (hasDerivAt_pow 2 (0 : ℝ))
    apply hsq.congr_of_eventuallyEq
    have hI : Set.Ioo (-π) π ∈ nhds (0 : ℝ) := Ioo_mem_nhds (by linarith [pi_pos]) pi_pos
    filter_upwards [hI] with s hs
    have hin : ⟪cos s • x + sin s • w, x⟫ = cos s := by
      rw [inner_add_left, real_inner_smul_left, real_inner_smul_left,
        real_inner_self_eq_norm_sq, hx, real_inner_comm, hmw]
      ring
    show arccos ⟪cos s • x + sin s • w, x⟫ ^ 2 = s ^ 2
    rw [hin]
    rcases le_total 0 s with h | h
    · rw [arccos_cos h hs.2.le]
    · rw [← cos_neg, arccos_cos (by linarith) (by linarith [hs.1]), neg_sq]

/-- Helper: on the compass, the distance from `↑t` to `0` for `t` in `[0, 180]`. -/
lemma compass_norm_small {t : ℝ} (h0 : -180 ≤ t) (h1 : t ≤ 180) :
    ‖((t : ℝ) : AddCircle (360 : ℝ))‖ = |t| := by
  refine (AddCircle.norm_coe_eq_abs_iff (p := (360 : ℝ)) (by norm_num)).mpr ?_
  rw [abs_le]; constructor <;> norm_num [abs_of_pos] <;> linarith

/-- Helper: every bearing is some `t` in `[0, 360)`, with its two distances to `0` and `180`. -/
lemma compass_rep (θ : AddCircle (360 : ℝ)) :
    ∃ t : ℝ, 0 ≤ t ∧ t < 360 ∧ θ = (t : AddCircle (360 : ℝ)) ∧
      ((t ≤ 180 ∧ dist θ 0 = t) ∨ (180 ≤ t ∧ dist θ 0 = 360 - t)) ∧
      dist θ ((180 : ℝ) : AddCircle (360 : ℝ)) = |t - 180| := by
  have : Fact ((0 : ℝ) < 360) := ⟨by norm_num⟩
  set t : ℝ := (AddCircle.equivIco (360 : ℝ) 0 θ : ℝ) with ht
  have hmem : 0 ≤ t ∧ t < 360 := by
    have h2 := (AddCircle.equivIco (360 : ℝ) 0 θ).2
    rw [Set.mem_Ico] at h2
    exact ⟨h2.1, by linarith [h2.2]⟩
  have hθ : θ = (t : AddCircle (360 : ℝ)) := by rw [ht, AddCircle.coe_equivIco]
  refine ⟨t, hmem.1, hmem.2, hθ, ?_, ?_⟩
  · rw [dist_eq_norm, sub_zero, hθ]
    rcases le_total t 180 with h | h
    · left; refine ⟨h, ?_⟩
      rw [compass_norm_small (by linarith) h, abs_of_nonneg hmem.1]
    · right; refine ⟨h, ?_⟩
      have : (t : AddCircle (360 : ℝ)) = ((t - 360 : ℝ) : AddCircle (360 : ℝ)) := by
        rw [AddCircle.coe_sub, AddCircle.coe_period, sub_zero]
      rw [this, compass_norm_small (by linarith) (by linarith), abs_of_neg (by linarith)]
      ring
  · rw [dist_eq_norm, hθ, ← AddCircle.coe_sub,
      compass_norm_small (by linarith) (by linarith)]

lemma compass_score_eq (θ : AddCircle (360 : ℝ)) :
    compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] θ =
      (1 / 2) * (dist θ 0 ^ 2 + dist θ ((180 : ℝ) : AddCircle (360 : ℝ)) ^ 2) := by
  simp [compassScore, Fin.sum_univ_two]

lemma compass_score_ge (θ : AddCircle (360 : ℝ)) :
    8100 ≤ compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] θ := by
  obtain ⟨t, h0, h1, -, hA, hB⟩ := compass_rep θ
  rw [compass_score_eq, hB]
  rcases hA with ⟨h, hA⟩ | ⟨h, hA⟩
  · rw [hA, abs_of_nonpos (by linarith)]; nlinarith [sq_nonneg (t - 90)]
  · rw [hA, abs_of_nonneg (by linarith)]; nlinarith [sq_nonneg (t - 270)]

lemma compass_score_90 :
    compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] ((90 : ℝ) : AddCircle (360 : ℝ)) = 8100 := by
  rw [compass_score_eq, dist_eq_norm, dist_eq_norm, sub_zero, ← AddCircle.coe_sub,
    compass_norm_small (by norm_num) (by norm_num),
    compass_norm_small (by norm_num) (by norm_num)]
  norm_num

lemma compass_score_270 :
    compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] ((270 : ℝ) : AddCircle (360 : ℝ)) = 8100 := by
  have e1 : dist ((270 : ℝ) : AddCircle (360 : ℝ)) 0 = 90 := by
    have : ((270 : ℝ) : AddCircle (360 : ℝ)) = ((-90 : ℝ) : AddCircle (360 : ℝ)) := by
      rw [show (270 : ℝ) = -90 + 360 by norm_num, AddCircle.coe_add_period]
    rw [this, dist_eq_norm, sub_zero, compass_norm_small (by norm_num) (by norm_num)]
    norm_num
  have e2 : dist ((270 : ℝ) : AddCircle (360 : ℝ)) ((180 : ℝ) : AddCircle (360 : ℝ)) = 90 := by
    rw [dist_eq_norm, ← AddCircle.coe_sub, compass_norm_small (by norm_num) (by norm_num)]
    norm_num
  rw [compass_score_eq, e1, e2]
  norm_num

/-- Main claim. If the data directions lie inside an open hemisphere (around a unit arrow `p`),
then at any Frechet mean `m` (a point of the sphere with the smallest average squared distance to
the data) the arrows from `m` to the data balance: `∑ log_m (x i) = 0`. So every Frechet mean is a
point where the averaging iteration stands still. -/
theorem frechet_mean_arrows_balance {n : ℕ} (x : Fin n → E3) (hx : ∀ i, ‖x i‖ = 1)
    (hhemi : ∃ p : E3, ‖p‖ = 1 ∧ ∀ i, 0 < ⟪p, x i⟫)
    (m : E3) (hm : ‖m‖ = 1) (hmin : ∀ q : E3, ‖q‖ = 1 → frechetFn x m ≤ frechetFn x q) :
    ∑ i, sphLog m (x i) = 0 := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simp
  obtain ⟨p, hp, hpx⟩ := hhemi
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  -- Step 1: no data point is opposite to `m`.
  have hlt : ∀ i, sphDist m (x i) < π := by
    intro j
    by_contra hj
    replace hj := not_lt.mp hj
    have hj' : ⟪m, x j⟫ ≤ -1 := arccos_eq_pi.mp (le_antisymm (arccos_le_pi _) hj)
    have hj1 : ⟪-m, x j⟫ = 1 := by
      rw [inner_neg_left]; linarith [(inner_mem_Icc_of_unit hm (hx j)).1]
    have hxj : -m = x j := eq_of_inner_eq_one (by rw [norm_neg, hm]) (hx j) hj1
    have hpm : ⟪p, m⟫ < 0 := by
      have := hpx j; rw [← hxj, inner_neg_right] at this; linarith
    set c := ⟪p, m⟫ with hc
    set m' : E3 := m - (2 * c) • p with hm'
    have hnorm' : ‖m'‖ = 1 := by
      have h : ‖m'‖ ^ 2 = 1 := by
        rw [hm', @norm_sub_sq_real, norm_smul, real_inner_smul_right, real_inner_comm, ← hc,
          hm, hp, Real.norm_eq_abs, mul_pow, sq_abs]
        ring
      have h0 := norm_nonneg m'
      nlinarith
    have hlt' : frechetFn x m' < frechetFn x m := by
      unfold frechetFn
      apply mul_lt_mul_of_pos_left _ (by positivity)
      apply Finset.sum_lt_sum_of_nonempty ⟨j, Finset.mem_univ _⟩
      intro i _
      have hi1 := inner_mem_Icc_of_unit hm (hx i)
      have hi2 := inner_mem_Icc_of_unit hnorm' (hx i)
      have hinner : ⟪m, x i⟫ < ⟪m', x i⟫ := by
        rw [hm', inner_sub_left, real_inner_smul_left]
        have := hpx i
        nlinarith
      have hacc : sphDist m' (x i) < sphDist m (x i) :=
        arccos_lt_arccos hi1.1 hinner hi2.2
      exact pow_lt_pow_left₀ hacc (arccos_nonneg _) (by norm_num)
    linarith [hmin m' hnorm']
  -- Step 2: along every great circle through `m`, the slope of the Frechet function is zero.
  have hperp : ∀ w : E3, ‖w‖ = 1 → ⟪m, w⟫ = 0 → ⟪∑ i, sphLog m (x i), w⟫ = 0 := by
    intro w hw hmw
    have hD : HasDerivAt (fun s : ℝ => frechetFn x (cos s • m + sin s • w))
        ((1 / (n : ℝ)) * ∑ i, (-2 * ⟪sphLog m (x i), w⟫)) 0 := by
      unfold frechetFn
      apply HasDerivAt.const_mul
      apply HasDerivAt.fun_sum
      intro i _
      exact sq_dist_slope_term m (x i) w hm (hx i) hmw (hlt i)
    have hloc : IsLocalMin (fun s : ℝ => frechetFn x (cos s • m + sin s • w)) 0 := by
      apply Filter.Eventually.of_forall
      intro s
      have h0 : cos (0 : ℝ) • m + sin (0 : ℝ) • w = m := by simp
      simp only [h0]
      exact hmin _ (norm_great_circle hm hw hmw s)
    have h0 := IsLocalMin.hasDerivAt_eq_zero hloc hD
    rw [sum_inner]
    rw [← Finset.mul_sum] at h0
    have hne : (1 / (n : ℝ)) ≠ 0 := by positivity
    have := (mul_eq_zero.mp h0).resolve_left hne
    linarith
  -- Step 3: the sum is perpendicular to `m` and to every direction along the sphere at `m`.
  set v := ∑ i, sphLog m (x i) with hv
  have hvm : ⟪m, v⟫ = 0 := by
    rw [real_inner_comm, hv, sum_inner]
    exact Finset.sum_eq_zero (fun i _ => inner_sphLog_self hm (hx i))
  by_contra hne
  have hvpos : 0 < ‖v‖ := norm_pos_iff.mpr hne
  have hw : ‖‖v‖⁻¹ • v‖ = 1 := norm_smul_inv_norm hne
  have hmw : ⟪m, ‖v‖⁻¹ • v⟫ = 0 := by rw [real_inner_smul_right, hvm, mul_zero]
  have := hperp _ hw hmw
  rw [real_inner_smul_right, real_inner_self_eq_norm_sq] at this
  have : ‖v‖ = 0 := by field_simp at this; nlinarith
  linarith

/-- The detailed proof's lemma: walk from `m` at unit speed along the great circle in the
direction of a unit arrow `w` along the sphere at `m`. If the data point `x` is at distance `d`
with `0 < d < π`, the squared distance to `x` changes at the rate `-2 log_m(x) · w`; so the
gradient of `d(·, x)²` is `-2 log_m(x)`. -/
theorem sq_dist_slope_eq_neg_two_log (m x w : E3) (hm : ‖m‖ = 1) (hx : ‖x‖ = 1)
    (hw : ‖w‖ = 1) (hmw : ⟪m, w⟫ = 0) (hd0 : 0 < sphDist m x) (hdπ : sphDist m x < π) :
    HasDerivAt (fun s : ℝ => sphDist (cos s • m + sin s • w) x ^ 2)
      (-2 * ⟪sphLog m x, w⟫) 0 := by
  exact sq_dist_slope_aux m x w hmw hd0 hdπ

/-- What breaks: bearings 0° and 180° fit in no open half-circle, and they have two means.
The bearings with the lowest average squared distance are exactly 90° and 270°,
each scoring 8100 deg². -/
theorem antipodal_bearings_two_means :
    compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] ((90 : ℝ) : AddCircle (360 : ℝ)) = 8100 ∧
    compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] ((270 : ℝ) : AddCircle (360 : ℝ)) = 8100 ∧
    {θ : AddCircle (360 : ℝ) | ∀ φ, compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] θ ≤
        compassScore ![(0 : AddCircle (360 : ℝ)), (180 : ℝ)] φ} =
      {((90 : ℝ) : AddCircle (360 : ℝ)), ((270 : ℝ) : AddCircle (360 : ℝ))} ∧
    ((90 : ℝ) : AddCircle (360 : ℝ)) ≠ ((270 : ℝ) : AddCircle (360 : ℝ)) := by
  refine ⟨compass_score_90, compass_score_270, ?_, ?_⟩
  · ext θ
    simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
    constructor
    · intro hθ
      have hle := hθ ((90 : ℝ) : AddCircle (360 : ℝ))
      rw [compass_score_90] at hle
      obtain ⟨t, h0, h1, hθt, hA, hB⟩ := compass_rep θ
      rw [compass_score_eq, hB] at hle
      rcases hA with ⟨h, hA⟩ | ⟨h, hA⟩
      · rw [hA, abs_of_nonpos (by linarith)] at hle
        left; rw [hθt]
        have : (t - 90) ^ 2 ≤ 0 := by nlinarith
        have : t = 90 := by nlinarith [sq_nonneg (t - 90)]
        rw [this]
      · rw [hA, abs_of_nonneg (by linarith)] at hle
        right; rw [hθt]
        have : (t - 270) ^ 2 ≤ 0 := by nlinarith
        have : t = 270 := by nlinarith [sq_nonneg (t - 270)]
        rw [this]
    · rintro (rfl | rfl) φ
      · rw [compass_score_90]; exact compass_score_ge φ
      · rw [compass_score_270]; exact compass_score_ge φ
  · have : Fact ((0 : ℝ) < 360) := ⟨by norm_num⟩
    rw [Ne, AddCircle.coe_eq_coe_iff_of_mem_Ico (a := 0)] <;> norm_num

-- The card's whole-number arithmetic on the compass, as exact fractions.
-- The number average of the six bearings: 1090 / 6 = 545/3 (181.67°).
example : ((340 + 350 + 355 + 5 + 10 + 30 : ℚ) / 6) = 545 / 3 := by norm_num
-- Turns from the guess 340°: 0, 10, 15, 25, 30, 50, summing to 130.
example : (0 + 10 + 15 + 25 + 30 + 50 : ℤ) = 130 := by norm_num
-- One step: 340 + 130/6, past 360, is 5/3 (1.67°).
example : (340 + 130 / 6 - 360 : ℚ) = 5 / 3 := by norm_num
-- Measured from 5/3, the turns -65/3, -35/3, -20/3, 10/3, 25/3, 85/3 add to zero.
example : ((340 - 360 - 5/3) + (350 - 360 - 5/3) + (355 - 360 - 5/3) + (5 - 5/3) + (10 - 5/3)
    + (30 - 5/3) : ℚ) = 0 := by norm_num
-- Spread at the mean: 2300/9 deg² (255.56).
example : (((-65/3)^2 + (-35/3)^2 + (-20/3)^2 + (10/3)^2 + (25/3)^2 + (85/3)^2) / 6 : ℚ)
    = 2300 / 9 := by norm_num
-- Spread at the number average 545/3: 250700/9 deg² (27,855.56).
example : (((340 - 545/3)^2 + (350 - 545/3)^2 + (355 - 545/3)^2 + (5 - 545/3)^2
    + (10 - 545/3)^2 + (30 - 545/3)^2) / 6 : ℚ) = 250700 / 9 := by norm_num
-- Bearings 0° and 180°: from 90°, both are 90° away, scoring 8100 deg².
example : ((90 ^ 2 + 90 ^ 2) / 2 : ℕ) = 8100 := by norm_num

#print axioms sq_dist_slope_aux
#print axioms inner_mem_Icc_of_unit
#print axioms eq_of_inner_eq_one
#print axioms norm_great_circle
#print axioms inner_sphLog_self
#print axioms sq_dist_slope_term
#print axioms compass_norm_small
#print axioms compass_rep
#print axioms compass_score_eq
#print axioms compass_score_ge
#print axioms compass_score_90
#print axioms compass_score_270
#print axioms frechet_mean_arrows_balance
#print axioms sq_dist_slope_eq_neg_two_log
#print axioms antipodal_bearings_two_means
