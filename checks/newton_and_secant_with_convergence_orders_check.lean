-- Newton and secant: near a simple root the secant method's error ratio |e_(k+1)|/|e_k|^φ tends to C^(φ-1), Newton's e_(k+1)/e_k^2 tends to f''/(2f'), and the secant gains more digits per evaluation exactly when a slope costs more than log 2/log φ - 1 function values.
import Mathlib.NumberTheory.Real.GoldenRatio
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Inv

open Filter Topology Real
open scoped goldenRatio

/-- From a `C^2` hypothesis at `r`: first and second derivatives exist near `r`, and the
second derivative is continuous at `r`. -/
lemma aux_c2 {f : ℝ → ℝ} {r : ℝ} (hf : ContDiffAt ℝ 2 f r) :
    (∃ δ > 0, ∀ y, |y - r| < δ →
      HasDerivAt f (deriv f y) y ∧ HasDerivAt (deriv f) (deriv (deriv f) y) y) ∧
    ContinuousAt (deriv (deriv f)) r := by
  refine ⟨?_, ?_⟩
  · have h := hf.eventually (by decide)
    rcases Metric.eventually_nhds_iff.1 h with ⟨δ, hδ, hball⟩
    refine ⟨δ, hδ, fun y hy => ?_⟩
    have hy' : ContDiffAt ℝ 2 f y := hball (by rwa [Real.dist_eq])
    refine ⟨(hy'.differentiableAt (by norm_num)).hasDerivAt, ?_⟩
    have h1 : ContDiffAt ℝ 1 (deriv f) y := hy'.derivWithin (by norm_num)
    exact (h1.differentiableAt (by norm_num)).hasDerivAt
  · have h1 : ContDiffAt ℝ 1 (deriv f) r := hf.derivWithin (by norm_num)
    have h0 : ContDiffAt ℝ 0 (deriv (deriv f)) r := h1.derivWithin (by norm_num)
    exact h0.continuousAt

/-- Chord slopes near `r` are close to `f'(r)`. -/
lemma aux_slope {f : ℝ → ℝ} {r : ℝ} (hf : ContDiffAt ℝ 2 f r) {ε : ℝ} (hε : 0 < ε) :
    ∃ η > 0, ∀ a b, |a - r| < η → |b - r| < η →
      |f b - f a - deriv f r * (b - a)| ≤ ε * |b - a| := by
  obtain ⟨⟨δ, hδ, hder⟩, -⟩ := aux_c2 hf
  have hcont : ContinuousAt (deriv f) r := (hder r (by simpa using hδ)).2.continuousAt
  rcases Metric.continuousAt_iff.1 hcont ε hε with ⟨δ', hδ', hc⟩
  refine ⟨min δ δ', lt_min hδ hδ', fun a b ha hb => ?_⟩
  have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
    (f := fun y => f y - deriv f r * y) (f' := fun y => deriv f y - deriv f r)
    (s := Metric.ball r (min δ δ')) (C := ε) (x := a) (y := b)
    (fun y hy => ?_) (fun y hy => ?_) (convex_ball _ _)
    (by rwa [Metric.mem_ball, Real.dist_eq]) (by rwa [Metric.mem_ball, Real.dist_eq])
  · simp only [Real.norm_eq_abs] at key
    have e : f b - deriv f r * b - (f a - deriv f r * a) = f b - f a - deriv f r * (b - a) := by
      ring
    rwa [e] at key
  · have hy' : |y - r| < min δ δ' := by rwa [Metric.mem_ball, Real.dist_eq] at hy
    have h := ((hder y (lt_of_lt_of_le hy' (min_le_left _ _))).1).sub
      ((hasDerivAt_id' y).const_mul (deriv f r))
    exact (h.congr_deriv (by ring)).hasDerivWithinAt
  · have hy' : dist y r < δ' :=
      lt_of_lt_of_le (Metric.mem_ball.1 hy) (min_le_right _ _)
    rw [Real.norm_eq_abs, ← Real.dist_eq]
    exact (hc hy').le

/-- Second-order Taylor bounds (Peano form) near `r`, for `f` and for `f'`. -/
lemma aux_peano {f : ℝ → ℝ} {r : ℝ} (hf : ContDiffAt ℝ 2 f r) {ε : ℝ} (hε : 0 < ε) :
    ∃ η > 0, ∀ y, |y - r| < η →
      |deriv f y - deriv f r - deriv (deriv f) r * (y - r)| ≤ ε * |y - r| ∧
      |f y - f r - deriv f r * (y - r) - deriv (deriv f) r / 2 * (y - r) ^ 2|
        ≤ ε * (y - r) ^ 2 := by
  obtain ⟨⟨δ, hδ, hder⟩, -⟩ := aux_c2 hf
  have h2 : HasDerivAt (deriv f) (deriv (deriv f) r) r := (hder r (by simpa using hδ)).2
  have hlo := (hasDerivAt_iff_isLittleO.1 h2).def hε
  rcases Metric.eventually_nhds_iff.1 hlo with ⟨δ', hδ', hb⟩
  have hb' : ∀ y, |y - r| < δ' →
      |deriv f y - deriv f r - deriv (deriv f) r * (y - r)| ≤ ε * |y - r| := by
    intro y hy
    have h := hb (y := y) (by rwa [Real.dist_eq])
    rw [Real.norm_eq_abs, Real.norm_eq_abs, smul_eq_mul, mul_comm (y - r)] at h
    exact h
  refine ⟨min δ δ', lt_min hδ hδ', fun y hy => ⟨hb' y (lt_of_lt_of_le hy (min_le_right _ _)), ?_⟩⟩
  set ρ := |y - r| with hρ
  have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
    (f := fun z => f z - deriv f r * (z - r) - deriv (deriv f) r / 2 * (z - r) ^ 2)
    (f' := fun z => deriv f z - deriv f r - deriv (deriv f) r * (z - r))
    (s := Metric.closedBall r ρ) (C := ε * ρ) (x := r) (y := y)
    (fun z hz => ?_) (fun z hz => ?_) (convex_closedBall _ _)
    (Metric.mem_closedBall_self (abs_nonneg _))
    (by rw [Metric.mem_closedBall, Real.dist_eq])
  · have e : f y - f r - deriv f r * (y - r) - deriv (deriv f) r / 2 * (y - r) ^ 2 =
        (f y - deriv f r * (y - r) - deriv (deriv f) r / 2 * (y - r) ^ 2) -
          (f r - deriv f r * (r - r) - deriv (deriv f) r / 2 * (r - r) ^ 2) := by ring
    rw [e]
    calc _ ≤ ε * ρ * |y - r| := by simpa only [Real.norm_eq_abs] using key
      _ = ε * (y - r) ^ 2 := by rw [hρ, mul_assoc, abs_mul_abs_self]; ring
  · have hz' : |z - r| < min δ δ' := by
      rw [Metric.mem_closedBall, Real.dist_eq] at hz
      exact lt_of_le_of_lt hz hy
    have h := (((hder z (lt_of_lt_of_le hz' (min_le_left _ _))).1).sub
      (((hasDerivAt_id' z).sub_const r).const_mul (deriv f r))).sub
      ((((hasDerivAt_id' z).sub_const r).pow 2).const_mul (deriv (deriv f) r / 2))
    refine (h.congr_deriv ?_).hasDerivWithinAt
    simp only [Nat.cast_ofNat]
    ring
  · have hz' : |z - r| ≤ ρ := by rwa [Metric.mem_closedBall, Real.dist_eq] at hz
    rw [Real.norm_eq_abs]
    calc _ ≤ ε * |z - r| := hb' z (lt_of_le_of_lt hz' (lt_of_lt_of_le hy (min_le_right _ _)))
      _ ≤ ε * ρ := by gcongr

/-- The Newton quotient `(f'(y)(y-r) - f(y)) / (y-r)^2` tends to `f''(r)/2`. -/
lemma aux_key {f : ℝ → ℝ} {r : ℝ} (hf : ContDiffAt ℝ 2 f r) (hroot : f r = 0) {ε : ℝ}
    (hε : 0 < ε) :
    ∃ η > 0, ∀ y, |y - r| < η → y ≠ r →
      |(deriv f y * (y - r) - f y) / (y - r) ^ 2 - deriv (deriv f) r / 2| ≤ ε := by
  obtain ⟨η, hη, hP⟩ := aux_peano hf (half_pos hε)
  refine ⟨η, hη, fun y hy hyr => ?_⟩
  obtain ⟨hA, hB⟩ := hP y hy
  have he : y - r ≠ 0 := sub_ne_zero.2 hyr
  have hpos : 0 < (y - r) ^ 2 := lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 he))
  have eq : (deriv f y * (y - r) - f y) / (y - r) ^ 2 - deriv (deriv f) r / 2 =
      ((deriv f y - deriv f r - deriv (deriv f) r * (y - r)) * (y - r) -
        (f y - f r - deriv f r * (y - r) - deriv (deriv f) r / 2 * (y - r) ^ 2)) / (y - r) ^ 2 := by
    rw [hroot]; field_simp; ring
  rw [eq, abs_div, abs_of_pos hpos, div_le_iff₀ hpos]
  calc _ ≤ |(deriv f y - deriv f r - deriv (deriv f) r * (y - r)) * (y - r)| +
        |f y - f r - deriv f r * (y - r) - deriv (deriv f) r / 2 * (y - r) ^ 2| := abs_sub _ _
    _ ≤ ε / 2 * |y - r| * |y - r| + ε / 2 * (y - r) ^ 2 := by
        rw [abs_mul]; exact add_le_add (mul_le_mul_of_nonneg_right hA (abs_nonneg _)) hB
    _ = ε * (y - r) ^ 2 := by rw [mul_assoc, abs_mul_abs_self]; ring

/-- The secant numerator `(a-r) f(b) - (b-r) f(a)` is `f''(r)/2 (a-r)(b-r)(b-a)` up to a
small relative error, for `a`, `b` near `r` and different from `r`. -/
lemma aux_num {f : ℝ → ℝ} {r : ℝ} (hf : ContDiffAt ℝ 2 f r) (hroot : f r = 0) {ε : ℝ}
    (hε : 0 < ε) :
    ∃ η > 0, ∀ a b, |a - r| < η → |b - r| < η → a ≠ r → b ≠ r →
      |(a - r) * f b - (b - r) * f a - deriv (deriv f) r / 2 * (a - r) * (b - r) * (b - a)|
        ≤ ε * (|a - r| * |b - r| * |b - a|) := by
  obtain ⟨⟨δ, hδ, hder⟩, -⟩ := aux_c2 hf
  obtain ⟨η1, hη1, hK⟩ := aux_key hf hroot hε
  obtain ⟨η2, hη2, hP⟩ := aux_peano hf (half_pos hε)
  refine ⟨min δ (min η1 η2), lt_min hδ (lt_min hη1 hη2), fun a b ha hb har hbr => ?_⟩
  have hea : a - r ≠ 0 := sub_ne_zero.2 har
  have heb : b - r ≠ 0 := sub_ne_zero.2 hbr
  have ha' := ha
  have hb' := hb
  rw [lt_min_iff, lt_min_iff] at ha' hb'
  rcases lt_or_ge 0 ((a - r) * (b - r)) with hsame | hopp
  · have hsub : ∀ z ∈ Set.uIcc a b, |z - r| < min δ (min η1 η2) ∧ z ≠ r := by
      intro z hz
      rw [Set.mem_uIcc] at hz
      have ha2 := abs_lt.1 ha
      have hb2 := abs_lt.1 hb
      refine ⟨abs_lt.2 ⟨by rcases hz with h | h <;> linarith [h.1, h.2],
        by rcases hz with h | h <;> linarith [h.1, h.2]⟩, ?_⟩
      rintro rfl
      rcases hz with h | h
      · nlinarith [h.1, h.2]
      · nlinarith [h.1, h.2]
    have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
      (f := fun z => f z / (z - r) - deriv (deriv f) r / 2 * z)
      (f' := fun z => (deriv f z * (z - r) - f z) / (z - r) ^ 2 - deriv (deriv f) r / 2)
      (s := Set.uIcc a b) (C := ε) (x := a) (y := b)
      (fun z hz => ?_) (fun z hz => ?_) (convex_uIcc a b) Set.left_mem_uIcc Set.right_mem_uIcc
    · simp only [Real.norm_eq_abs] at key
      have e1 : (a - r) * f b - (b - r) * f a - deriv (deriv f) r / 2 * (a - r) * (b - r) * (b - a)
          = ((a - r) * (b - r)) * (f b / (b - r) - deriv (deriv f) r / 2 * b -
            (f a / (a - r) - deriv (deriv f) r / 2 * a)) := by
        field_simp; ring
      rw [e1, abs_mul, abs_mul (a - r)]
      calc _ ≤ |a - r| * |b - r| * (ε * |b - a|) :=
            mul_le_mul_of_nonneg_left key (by positivity)
        _ = _ := by ring
    · obtain ⟨hz1, hz2⟩ := hsub z hz
      have hzr : z - r ≠ 0 := sub_ne_zero.2 hz2
      have h := (((hder z (lt_of_lt_of_le hz1 (min_le_left _ _))).1).div
        ((hasDerivAt_id' z).sub_const r) hzr).sub
        ((hasDerivAt_id' z).const_mul (deriv (deriv f) r / 2))
      refine (h.congr_deriv ?_).hasDerivWithinAt
      ring
    · obtain ⟨hz1, hz2⟩ := hsub z hz
      rw [Real.norm_eq_abs]
      exact hK z (lt_of_lt_of_le hz1 (le_trans (min_le_right _ _) (min_le_left _ _))) hz2
  · have hbr2 : |b - r| ≤ |b - a| := sq_le_sq.1 (by nlinarith)
    have har2 : |a - r| ≤ |b - a| := sq_le_sq.1 (by nlinarith)
    have hBa := (hP a ha'.2.2).2
    have hBb := (hP b hb'.2.2).2
    rw [hroot] at hBa hBb
    calc _ = |(a - r) * (f b - 0 - deriv f r * (b - r) - deriv (deriv f) r / 2 * (b - r) ^ 2) -
          (b - r) * (f a - 0 - deriv f r * (a - r) - deriv (deriv f) r / 2 * (a - r) ^ 2)| := by
          congr 1; ring
      _ ≤ |(a - r) * (f b - 0 - deriv f r * (b - r) - deriv (deriv f) r / 2 * (b - r) ^ 2)| +
          |(b - r) * (f a - 0 - deriv f r * (a - r) - deriv (deriv f) r / 2 * (a - r) ^ 2)| :=
          abs_sub _ _
      _ ≤ |a - r| * (ε / 2 * (b - r) ^ 2) + |b - r| * (ε / 2 * (a - r) ^ 2) := by
          rw [abs_mul, abs_mul]
          exact add_le_add (mul_le_mul_of_nonneg_left hBb (abs_nonneg _))
            (mul_le_mul_of_nonneg_left hBa (abs_nonneg _))
      _ = ε / 2 * (|a - r| * |b - r| * |b - r|) + ε / 2 * (|a - r| * |b - r| * |a - r|) := by
          rw [← sq_abs (b - r), ← sq_abs (a - r)]; ring
      _ ≤ ε / 2 * (|a - r| * |b - r| * |b - a|) + ε / 2 * (|a - r| * |b - r| * |b - a|) := by
          gcongr
      _ = ε * (|a - r| * |b - r| * |b - a|) := by ring

/-- A sequence with `v (k+1) = q v k + δ k`, `|q| < 1` and `δ → 0` tends to 0. -/
lemma aux_contract {v δ : ℕ → ℝ} {q : ℝ} (hq : |q| < 1)
    (hrec : ∀ k, v (k + 1) = q * v k + δ k) (hδ : Tendsto δ atTop (𝓝 0)) :
    Tendsto v atTop (𝓝 0) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  have h1 : 0 < 1 - |q| := by linarith
  obtain ⟨N, hN⟩ := Metric.tendsto_atTop.1 hδ (ε * (1 - |q|) / 2) (by positivity)
  have hbound : ∀ j, |v (N + j)| ≤ |q| ^ j * |v N| + ε / 2 := by
    intro j
    induction j with
    | zero => simp; linarith
    | succ j ih =>
      have hdj : |δ (N + j)| < ε * (1 - |q|) / 2 := by
        simpa [Real.dist_eq] using hN (N + j) (by omega)
      rw [← add_assoc, hrec]
      calc |q * v (N + j) + δ (N + j)| ≤ |q * v (N + j)| + |δ (N + j)| := abs_add_le _ _
        _ = |q| * |v (N + j)| + |δ (N + j)| := by rw [abs_mul]
        _ ≤ |q| * (|q| ^ j * |v N| + ε / 2) + ε * (1 - |q|) / 2 :=
            add_le_add (mul_le_mul_of_nonneg_left ih (abs_nonneg q)) hdj.le
        _ = |q| ^ (j + 1) * |v N| + ε / 2 := by ring
  have hpow : Tendsto (fun j => |q| ^ j * |v N|) atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one (abs_nonneg q) hq).mul_const (|v N|)
  obtain ⟨J, hJ⟩ := Metric.tendsto_atTop.1 hpow (ε / 2) (half_pos hε)
  refine ⟨N + J, fun n hn => ?_⟩
  obtain ⟨j, rfl⟩ : ∃ j, n = N + j := ⟨n - N, by omega⟩
  have := hJ j (by omega)
  rw [Real.dist_eq, sub_zero] at this ⊢
  have h0 : 0 ≤ |q| ^ j * |v N| := by positivity
  rw [abs_of_nonneg h0] at this
  linarith [hbound j]

#print axioms aux_c2
#print axioms aux_slope
#print axioms aux_peano
#print axioms aux_key
#print axioms aux_num
#print axioms aux_contract

/-- The secant method has order the golden ratio. Let `f` have a continuous second
derivative near a root `r` (`f r = 0`), with `f'(r) ≠ 0` (a simple root) and
`f''(r) ≠ 0`. Let the guesses `x k` follow the secant step through the two newest
points, be distinct, never land on `r`, and tend to `r` (a close enough start).
Then `|e_(k+1)| / |e_k|^φ` tends to `C^(φ-1)`, where `e_k = x_k - r` and
`C = |f''(r)| / (2 |f'(r)|)`. -/
theorem secant_order_golden_ratio {f : ℝ → ℝ} {r : ℝ} {x : ℕ → ℝ}
    (hf : ContDiffAt ℝ 2 f r) (hroot : f r = 0)
    (hsimple : deriv f r ≠ 0) (hbend : deriv (deriv f) r ≠ 0)
    (hstep : ∀ k, x (k + 2) =
      x (k + 1) - f (x (k + 1)) * (x (k + 1) - x k) / (f (x (k + 1)) - f (x k)))
    (hdistinct : ∀ k, x (k + 1) ≠ x k) (hne : ∀ k, x k ≠ r)
    (hlim : Tendsto x atTop (𝓝 r)) :
    Tendsto (fun k => |x (k + 1) - r| / |x k - r| ^ φ) atTop
      (𝓝 ((|deriv (deriv f) r| / (2 * |deriv f r|)) ^ (φ - 1))) := by
  have he : ∀ k, x k - r ≠ 0 := fun k => sub_ne_zero.2 (hne k)
  have hba : ∀ k, x (k + 1) - x k ≠ 0 := fun k => sub_ne_zero.2 (hdistinct k)
  have hD0 : ∀ k, f (x (k + 1)) - f (x k) ≠ 0 := by
    intro k h
    apply hdistinct (k + 1)
    show x (k + 2) = x (k + 1)
    rw [hstep k, h, div_zero, sub_zero]
  obtain ⟨P, hPdef⟩ : ∃ P : ℕ → ℝ, ∀ k, P k =
      ((x k - r) * f (x (k + 1)) - (x (k + 1) - r) * f (x k)) /
        ((x k - r) * (x (k + 1) - r) * (x (k + 1) - x k)) := ⟨_, fun k => rfl⟩
  obtain ⟨Q, hQdef⟩ : ∃ Q : ℕ → ℝ, ∀ k, Q k =
      (f (x (k + 1)) - f (x k)) / (x (k + 1) - x k) := ⟨_, fun k => rfl⟩
  have hPt : Tendsto P atTop (𝓝 (deriv (deriv f) r / 2)) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨η, hη, hN⟩ := aux_num hf hroot (half_pos hε)
    obtain ⟨K, hK⟩ := Metric.tendsto_atTop.1 hlim η hη
    refine ⟨K, fun k hk => ?_⟩
    have ha : |x k - r| < η := by simpa [Real.dist_eq] using hK k hk
    have hb : |x (k + 1) - r| < η := by simpa [Real.dist_eq] using hK (k + 1) (by omega)
    have hden : (x k - r) * (x (k + 1) - r) * (x (k + 1) - x k) ≠ 0 :=
      mul_ne_zero (mul_ne_zero (he k) (he (k + 1))) (hba k)
    have hpos : 0 < |x k - r| * |x (k + 1) - r| * |x (k + 1) - x k| := by
      have := abs_pos.2 hden
      rwa [abs_mul, abs_mul] at this
    have eq : P k - deriv (deriv f) r / 2 =
        ((x k - r) * f (x (k + 1)) - (x (k + 1) - r) * f (x k) -
          deriv (deriv f) r / 2 * (x k - r) * (x (k + 1) - r) * (x (k + 1) - x k)) /
        ((x k - r) * (x (k + 1) - r) * (x (k + 1) - x k)) := by
      rw [hPdef k, eq_div_iff hden, sub_mul, div_mul_cancel₀ _ hden]
      ring
    rw [Real.dist_eq, eq, abs_div, abs_mul, abs_mul, div_lt_iff₀ hpos]
    calc _ ≤ ε / 2 * (|x k - r| * |x (k + 1) - r| * |x (k + 1) - x k|) :=
          hN (x k) (x (k + 1)) ha hb (hne k) (hne (k + 1))
      _ < ε * (|x k - r| * |x (k + 1) - r| * |x (k + 1) - x k|) := by nlinarith
  have hQt : Tendsto Q atTop (𝓝 (deriv f r)) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨η, hη, hN⟩ := aux_slope hf (half_pos hε)
    obtain ⟨K, hK⟩ := Metric.tendsto_atTop.1 hlim η hη
    refine ⟨K, fun k hk => ?_⟩
    have ha : |x k - r| < η := by simpa [Real.dist_eq] using hK k hk
    have hb : |x (k + 1) - r| < η := by simpa [Real.dist_eq] using hK (k + 1) (by omega)
    have hpos : 0 < |x (k + 1) - x k| := abs_pos.2 (hba k)
    have eq : Q k - deriv f r =
        (f (x (k + 1)) - f (x k) - deriv f r * (x (k + 1) - x k)) / (x (k + 1) - x k) := by
      rw [hQdef k, eq_div_iff (hba k), sub_mul, div_mul_cancel₀ _ (hba k)]
    rw [Real.dist_eq, eq, abs_div, div_lt_iff₀ hpos]
    calc _ ≤ ε / 2 * |x (k + 1) - x k| := hN (x k) (x (k + 1)) ha hb
      _ < ε * |x (k + 1) - x k| := by nlinarith
  have hratio : ∀ k, P k / Q k = (x (k + 2) - r) / ((x k - r) * (x (k + 1) - r)) := by
    intro k
    have h1 := he k
    have h2 := he (k + 1)
    have h3 := hba k
    have h4 := hD0 k
    rw [hPdef k, hQdef k, hstep k]
    field_simp
    ring
  obtain ⟨C, hC⟩ : ∃ C : ℝ, C = |deriv (deriv f) r| / (2 * |deriv f r|) := ⟨_, rfl⟩
  have hCpos : 0 < C := by
    rw [hC]
    exact div_pos (abs_pos.2 hbend) (by have := abs_pos.2 hsimple; linarith)
  have hδ : Tendsto (fun k => Real.log |P k / Q k| - Real.log C) atTop (𝓝 0) := by
    have hCeq : |deriv (deriv f) r / 2 / deriv f r| = C := by
      rw [hC, abs_div, abs_div, abs_two, div_div]
    have h1 := ((hPt.div hQt hsimple).abs).log (by rw [hCeq]; exact hCpos.ne')
    rw [hCeq] at h1
    simpa using h1.sub_const (Real.log C)
  have hlogrec : ∀ k, Real.log |P k / Q k| =
      Real.log |x (k + 2) - r| - Real.log |x k - r| - Real.log |x (k + 1) - r| := by
    intro k
    rw [hratio k, abs_div, abs_mul,
      Real.log_div (abs_ne_zero.2 (he _)) (mul_ne_zero (abs_ne_zero.2 (he _)) (abs_ne_zero.2 (he _))),
      Real.log_mul (abs_ne_zero.2 (he _)) (abs_ne_zero.2 (he _))]
    ring
  obtain ⟨v, hv⟩ : ∃ v : ℕ → ℝ, ∀ k, v k = Real.log |x (k + 1) - r| - φ * Real.log |x k - r|
      - (φ - 1) * Real.log C := ⟨_, fun k => rfl⟩
  have hvrec : ∀ k, v (k + 1) = (1 - φ) * v k + (Real.log |P k / Q k| - Real.log C) := by
    intro k
    rw [hv (k + 1), hv k, hlogrec k, show k + 1 + 1 = k + 2 from rfl]
    linear_combination (-(Real.log |x k - r|) - Real.log C) * Real.goldenRatio_sq
  have hq : |1 - φ| < 1 := by
    rw [abs_lt]
    constructor
    · linarith [Real.goldenRatio_lt_two]
    · linarith [Real.one_lt_goldenRatio]
  have hvlim := aux_contract hq hvrec hδ
  have hfin : Tendsto (fun k => Real.exp (v k + (φ - 1) * Real.log C)) atTop
      (𝓝 (Real.exp (0 + (φ - 1) * Real.log C))) :=
    (Real.continuous_exp.tendsto _).comp (hvlim.add_const _)
  have hlimval : Real.exp (0 + (φ - 1) * Real.log C) = C ^ (φ - 1) := by
    rw [Real.rpow_def_of_pos hCpos]
    congr 1
    ring
  rw [hlimval] at hfin
  rw [← hC]
  refine hfin.congr (fun k => ?_)
  rw [Real.rpow_def_of_pos (abs_pos.2 (he k)), hv k, eq_div_iff (Real.exp_pos _).ne',
    ← Real.exp_add]
  conv_rhs => rw [← Real.exp_log (abs_pos.2 (he (k + 1)))]
  congr 1
  ring

/-- Newton's method has order 2. Let `f` have a continuous second derivative near a
root `r` with `f'(r) ≠ 0` (a simple root). Let the guesses `x k` follow Newton's
step, never land on `r`, and tend to `r`. Then `e_(k+1) / e_k^2` tends to
`f''(r) / (2 f'(r))`, where `e_k = x_k - r`. -/
theorem newton_order_two {f : ℝ → ℝ} {r : ℝ} {x : ℕ → ℝ}
    (hf : ContDiffAt ℝ 2 f r) (hroot : f r = 0) (hsimple : deriv f r ≠ 0)
    (hstep : ∀ k, x (k + 1) = x k - f (x k) / deriv f (x k))
    (hne : ∀ k, x k ≠ r) (hlim : Tendsto x atTop (𝓝 r)) :
    Tendsto (fun k => (x (k + 1) - r) / (x k - r) ^ 2) atTop
      (𝓝 (deriv (deriv f) r / (2 * deriv f r))) := by
  obtain ⟨⟨δ, hδ, hder⟩, -⟩ := aux_c2 hf
  have hcont : ContinuousAt (deriv f) r := (hder r (by simpa using hδ)).2.continuousAt
  have hD : Tendsto (fun k => deriv f (x k)) atTop (𝓝 (deriv f r)) := hcont.tendsto.comp hlim
  have hN : Tendsto (fun k => (deriv f (x k) * (x k - r) - f (x k)) / (x k - r) ^ 2) atTop
      (𝓝 (deriv (deriv f) r / 2)) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨η, hη, hK⟩ := aux_key hf hroot (half_pos hε)
    obtain ⟨N, hN⟩ := Metric.tendsto_atTop.1 hlim η hη
    refine ⟨N, fun k hk => ?_⟩
    rw [Real.dist_eq]
    exact lt_of_le_of_lt (hK (x k) (by simpa [Real.dist_eq] using hN k hk) (hne k))
      (half_lt_self hε)
  have hev : ∀ᶠ k in atTop,
      (deriv f (x k) * (x k - r) - f (x k)) / (x k - r) ^ 2 / deriv f (x k)
        = (x (k + 1) - r) / (x k - r) ^ 2 := by
    filter_upwards [hD.eventually_ne hsimple] with k hk
    have he : x k - r ≠ 0 := sub_ne_zero.2 (hne k)
    rw [hstep k]
    field_simp
    ring
  have h := (hN.div hD hsimple).congr' hev
  rwa [div_div] at h

/-- The cost per digit. If one slope costs `t ≥ 0` function values, Newton multiplies
the correct digits by `2^(1/(1+t))` per evaluation and the secant by `φ`. The secant
gains more per evaluation exactly when `t > log 2 / log φ - 1` (about 0.4404). -/
theorem secant_beats_newton_iff {t : ℝ} (ht : 0 ≤ t) :
    (2 : ℝ) ^ (1 / (1 + t)) < φ ↔ log 2 / log φ - 1 < t := by
  have hlφ : 0 < Real.log φ := Real.log_pos Real.one_lt_goldenRatio
  have ht1 : 0 < 1 + t := by linarith
  rw [← Real.log_lt_log_iff (Real.rpow_pos_of_pos two_pos _) Real.goldenRatio_pos,
    Real.log_rpow two_pos, sub_lt_iff_lt_add, div_lt_iff₀ hlφ, one_div, inv_mul_eq_div,
    div_lt_iff₀ ht1]
  constructor <;> intro h <;> linarith

-- Newton on x^3 - 2 from 1: steps 1 and 2 are 4/3 and 91/72 (1.3333..., 1.26388...).
example : (1 : ℚ) - (1 ^ 3 - 2) / (3 * 1 ^ 2) = 4 / 3 := by norm_num
example : (4 / 3 : ℚ) - ((4 / 3) ^ 3 - 2) / (3 * (4 / 3) ^ 2) = 91 / 72 := by norm_num
-- Secant on x^3 - 2 from 1 and 2: x_2 = 8/7 and x_3 = 75/62 (1.142857..., 1.2096774...).
example : (2 : ℚ) - (2 ^ 3 - 2) * (2 - 1) / ((2 ^ 3 - 2) - (1 ^ 3 - 2)) = 8 / 7 := by norm_num
example : (8 / 7 : ℚ) - ((8 / 7) ^ 3 - 2) * (8 / 7 - 2) / (((8 / 7) ^ 3 - 2) - (2 ^ 3 - 2))
    = 75 / 62 := by norm_num
-- Bisection from width 1 to a half-width under 1e-9 takes 29 halvings: 2^30 ≥ 10^9 > 2^29.
example : 10 ^ 9 ≤ 2 ^ 30 ∧ 2 ^ 29 < 10 ^ 9 := by decide
-- Evaluations: Newton 4 + 4 = 8, secant 2 + 5 = 7, bisection 2 + 29 = 31.
example : 4 + 4 = 8 ∧ 2 + 5 = 7 ∧ 2 + 29 = 31 := by decide

#print axioms secant_order_golden_ratio
#print axioms newton_order_two
#print axioms secant_beats_newton_iff
