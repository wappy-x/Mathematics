-- Online convex optimisation: online gradient descent with steps D/(G√t) on a convex set of diameter D, against convex losses with gradients no longer than G, has regret at most (3/2) D G √T against every fixed point of the set, and steps 1/(μ t) bring this down to G²/(2μ) (1 + ln T) when every loss is μ-strongly convex.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Convex.Strong
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Sym.Card
import Mathlib.Analysis.InnerProductSpace.Projection.Minimal
import Mathlib.Analysis.Calculus.LineDeriv.Basic

open scoped RealInnerProductSpace

/-! The card's notation.
* `E` is the space of mixes, with inner product `⟪u, v⟫` (the card's `u^T v`) and length `‖u‖`.
* `K` is the set of valid mixes (the card's simplex `Δ`); it is convex, and any two of its
  points are at most `D` apart.
* `P` is the projection `Π_Δ`: `P v` is a point of `K` nearest to `v`.
* Days are counted `t = 1, …, T`. `w t` is the mix held on day `t`, chosen before day `t`'s
  loss `f t` is seen; `g t` is the gradient of `f t` at `w t`, at most `G` long.
* Day `t`'s step is `D / (G √t)` (or `1 / (μ t)` under strong convexity), and
  `w (t + 1) = P (w t - α_t • g t)`.
* The regret against a fixed mix `u` is `∑_{t=1}^{T} (f t (w t) - f t u)`. The card's regret is
  this against the best fixed mix in hindsight; a bound for every `u ∈ K` covers that mix. -/

/-- A nearest point of a convex set is no farther from any point of the set. -/
theorem ogd_proj_sq_le
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (K : Set E) (hK : Convex ℝ K)
    (P : E → E) (hPK : ∀ v, P v ∈ K) (hPnear : ∀ v, ∀ u ∈ K, ‖v - P v‖ ≤ ‖v - u‖)
    (v u : E) (hu : u ∈ K) : ‖P v - u‖ ^ 2 ≤ ‖v - u‖ ^ 2 := by
  have hinf : ‖v - P v‖ = ⨅ w : K, ‖v - w‖ := by
    have : Nonempty K := ⟨⟨P v, hPK v⟩⟩
    apply le_antisymm
    · exact le_ciInf fun w => hPnear v w w.2
    · have hb : BddBelow (Set.range fun w : K => ‖v - (w : E)‖) :=
        ⟨0, by rintro _ ⟨w, rfl⟩; exact norm_nonneg _⟩
      exact ciInf_le hb ⟨P v, hPK v⟩
  have hvi := (norm_eq_iInf_iff_real_inner_le_zero hK (hPK v)).1 hinf u hu
  have h1 : v - u = (v - P v) + (P v - u) := by abel
  rw [h1, norm_add_sq_real]
  have h2 : ⟪v - P v, P v - u⟫ = -⟪v - P v, u - P v⟫ := by
    rw [← inner_neg_right, neg_sub]
  nlinarith [sq_nonneg ‖v - P v‖]

#print axioms ogd_proj_sq_le

open Filter Topology in
/-- A gradient lower-bounds a function along a segment, given a quadratic upper bound
on its increments. -/
theorem ogd_inner_le_of_increment
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (f : E → ℝ) (g w v : E) (hgrad : HasGradientAt f g w) (A B : ℝ)
    (h : ∀ t : ℝ, 0 < t → t ≤ 1 → f (w + t • v) - f w ≤ t * A + t ^ 2 * B) :
    ⟪g, v⟫ ≤ A := by
  have hF := (hasGradientAt_iff_hasFDerivAt.1 hgrad).hasLineDerivAt v
  have hT := hF.tendsto_slope_zero_right
  simp only [InnerProductSpace.toDual_apply_apply, smul_eq_mul] at hT
  have hlim : Tendsto (fun t : ℝ => A + t * B) (𝓝[>] 0) (𝓝 (A + 0 * B)) :=
    (tendsto_const_nhds.add (tendsto_id.mul tendsto_const_nhds)).mono_left
      nhdsWithin_le_nhds
  rw [zero_mul, add_zero] at hlim
  refine le_of_tendsto_of_tendsto hT hlim ?_
  filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < 1 by norm_num)] with t ht
  have := h t ht.1 ht.2.le
  rw [inv_mul_le_iff₀ ht.1]
  nlinarith

#print axioms ogd_inner_le_of_increment

/-- The card's Step 1 inequality (used by the regret bounds below). -/
theorem ogd_one_step_helper
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (K : Set E) (hK : Convex ℝ K)
    (P : E → E) (hPK : ∀ v, P v ∈ K) (hPnear : ∀ v, ∀ u ∈ K, ‖v - P v‖ ≤ ‖v - u‖)
    (w g u : E) (_hw : w ∈ K) (hu : u ∈ K) (α : ℝ) (hα : 0 < α) :
    ⟪g, w - u⟫ ≤ (‖w - u‖ ^ 2 - ‖P (w - α • g) - u‖ ^ 2) / (2 * α) + α / 2 * ‖g‖ ^ 2 := by
  have h := ogd_proj_sq_le K hK P hPK hPnear (w - α • g) u hu
  have e : w - α • g - u = (w - u) - α • g := by abel
  rw [e, norm_sub_sq_real (w - u) (α • g), inner_smul_right, norm_smul, Real.norm_eq_abs, abs_of_pos hα,
    real_inner_comm] at h
  rw [← sub_nonneg]
  have key : (‖w - u‖ ^ 2 - ‖P (w - α • g) - u‖ ^ 2) / (2 * α) + α / 2 * ‖g‖ ^ 2 - ⟪g, w - u⟫
      = (‖w - u‖ ^ 2 - 2 * (α * ⟪g, w - u⟫) + (α * ‖g‖) ^ 2 - ‖P (w - α • g) - u‖ ^ 2)
        / (2 * α) := by
    field_simp
    ring
  rw [key]
  apply div_nonneg _ (by positivity)
  linarith

/-- First-order bound for a strongly convex function with a gradient. -/
theorem ogd_strong_first_order
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (K : Set E) (μ : ℝ) (f : E → ℝ) (hconv : StrongConvexOn K μ f)
    (g w : E) (hw : w ∈ K) (hgrad : HasGradientAt f g w) (u : E) (hu : u ∈ K) :
    f w - f u ≤ ⟪g, w - u⟫ - μ / 2 * ‖w - u‖ ^ 2 := by
  have h := ogd_inner_le_of_increment f g w (u - w) hgrad
    (f u - f w - μ / 2 * ‖w - u‖ ^ 2) (μ / 2 * ‖w - u‖ ^ 2) (by
      intro t ht0 ht1
      have hc := hconv.2 hw hu (show (0:ℝ) ≤ 1 - t by linarith) ht0.le (show (1 - t) + t = 1 by ring)
      have e : w + t • (u - w) = (1 - t) • w + t • u := by
        rw [smul_sub, sub_smul, one_smul]; abel
      rw [e]
      simp only [smul_eq_mul] at hc
      nlinarith)
  have e2 : ⟪g, w - u⟫ = -⟪g, u - w⟫ := by rw [← inner_neg_right, neg_sub]
  linarith

/-- First-order bound for a convex function with a gradient. -/
theorem ogd_convex_first_order
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (K : Set E) (f : E → ℝ) (hconv : ConvexOn ℝ K f)
    (g w : E) (hw : w ∈ K) (hgrad : HasGradientAt f g w) (u : E) (hu : u ∈ K) :
    f w - f u ≤ ⟪g, w - u⟫ := by
  have h := ogd_inner_le_of_increment f g w (u - w) hgrad (f u - f w) 0 (by
      intro t ht0 ht1
      have hc := hconv.2 hw hu (show (0:ℝ) ≤ 1 - t by linarith) ht0.le (show (1 - t) + t = 1 by ring)
      have e : w + t • (u - w) = (1 - t) • w + t • u := by
        rw [smul_sub, sub_smul, one_smul]; abel
      rw [e]
      simp only [smul_eq_mul] at hc
      nlinarith)
  have e2 : ⟪g, w - u⟫ = -⟪g, u - w⟫ := by rw [← inner_neg_right, neg_sub]
  linarith

/-- The harmonic sum is at most `1 + ln T`. -/
theorem ogd_harmonic_le (T : ℕ) :
    ∑ t ∈ Finset.Icc 1 T, (1 / (t : ℝ)) ≤ 1 + Real.log T := by
  induction T with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega)]
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · have hn' : (0 : ℝ) < n := by exact_mod_cast hn
      have hlog : 1 / ((n + 1 : ℕ) : ℝ) ≤ Real.log ((n + 1 : ℕ) : ℝ) - Real.log n := by
        push_cast
        rw [← Real.log_div (by positivity) hn'.ne']
        have := Real.one_sub_inv_le_log_of_pos (x := ((n : ℝ) + 1) / n) (by positivity)
        rw [inv_div] at this
        have e : 1 - (n : ℝ) / (n + 1) = 1 / (n + 1) := by field_simp; ring
        linarith
      linarith

#print axioms ogd_one_step_helper
#print axioms ogd_strong_first_order
#print axioms ogd_convex_first_order
#print axioms ogd_harmonic_le

/-- The `(3/2) D G √T` regret bound for online gradient descent. Let every day's loss be
convex on the set of valid mixes, which is convex and has diameter at most `D`; let each day's
mix be chosen before that day's loss is seen, by stepping against the previous day's gradient
with step `D / (G √t)` and projecting back to the nearest valid mix; and let every gradient be
at most `G` long. Then, however the losses are chosen, the total loss over `T` days exceeds the
total loss of any fixed valid mix by at most `(3/2) D G √T`. -/
theorem ogd_regret_le_three_halves_D_G_sqrt_T
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (K : Set E) (hK : Convex ℝ K)
    (D G : ℝ) (hD : ∀ x ∈ K, ∀ y ∈ K, ‖x - y‖ ≤ D)
    (P : E → E) (hPK : ∀ v, P v ∈ K) (hPnear : ∀ v, ∀ u ∈ K, ‖v - P v‖ ≤ ‖v - u‖)
    (f : ℕ → E → ℝ) (hconv : ∀ t, ConvexOn ℝ K (f t))
    (w g : ℕ → E) (hw1 : w 1 ∈ K)
    (hgrad : ∀ t, 1 ≤ t → HasGradientAt (f t) (g t) (w t))
    (hG : ∀ t, 1 ≤ t → ‖g t‖ ≤ G)
    (hstep : ∀ t, 1 ≤ t → w (t + 1) = P (w t - (D / (G * Real.sqrt t)) • g t))
    (T : ℕ) :
    ∀ u ∈ K, ∑ t ∈ Finset.Icc 1 T, (f t (w t) - f t u) ≤ 3 / 2 * D * G * Real.sqrt T := by
  intro u hu
  have hwK : ∀ t, 1 ≤ t → w t ∈ K := by
    intro t ht
    obtain ⟨n, rfl⟩ : ∃ n, t = n + 1 := ⟨t - 1, by omega⟩
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · exact hw1
    · obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
      rw [hstep (m + 1) (by omega)]
      exact hPK _
  have hterm : ∀ t, 1 ≤ t → f t (w t) - f t u ≤ ⟪g t, w t - u⟫ := fun t ht =>
    ogd_convex_first_order K (f t) (hconv t) (g t) (w t) (hwK t ht) (hgrad t ht) u hu
  rcases Nat.eq_zero_or_pos T with rfl | hT
  · simp
  have hG0 : 0 ≤ G := le_trans (norm_nonneg _) (hG 1 le_rfl)
  have hD0 : 0 ≤ D := by have := hD u hu u hu; simp at this; linarith
  by_cases hDG : 0 < D ∧ 0 < G
  swap
  · have hz : D * G = 0 := by
      rcases not_and_or.1 hDG with h | h
      · rw [le_antisymm (not_lt.1 h) hD0, zero_mul]
      · rw [le_antisymm (not_lt.1 h) hG0, mul_zero]
    have : 3 / 2 * D * G * Real.sqrt T = 0 := by
      rw [mul_assoc (3 / 2 : ℝ), hz]; simp
    rw [this]
    apply Finset.sum_nonpos
    intro t ht
    have ht1 : 1 ≤ t := (Finset.mem_Icc.1 ht).1
    calc f t (w t) - f t u ≤ ⟪g t, w t - u⟫ := hterm t ht1
      _ ≤ ‖g t‖ * ‖w t - u‖ := real_inner_le_norm _ _
      _ ≤ G * D := mul_le_mul (hG t ht1) (hD _ (hwK t ht1) u hu) (norm_nonneg _) hG0
      _ = 0 := by rw [mul_comm, hz]
  obtain ⟨hDp, hGp⟩ := hDG
  have claim : ∀ n : ℕ, ∑ t ∈ Finset.Icc 1 n, (f t (w t) - f t u)
      + G * Real.sqrt n / (2 * D) * ‖w (n + 1) - u‖ ^ 2 ≤ 3 / 2 * D * G * Real.sqrt n := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Finset.sum_Icc_succ_top (by omega)]
      set s := Real.sqrt ((n + 1 : ℕ) : ℝ) with hs
      set r := Real.sqrt (n : ℝ) with hr
      have hs2 : s ^ 2 = (n : ℝ) + 1 := by
        rw [hs, Real.sq_sqrt (Nat.cast_nonneg _)]; push_cast; ring
      have hr2 : r ^ 2 = (n : ℝ) := Real.sq_sqrt (Nat.cast_nonneg _)
      have hr0 : 0 ≤ r := Real.sqrt_nonneg _
      have hs0 : 0 < s := Real.sqrt_pos.2 (by positivity)
      have hrs : r ≤ s := Real.sqrt_le_sqrt (by push_cast; linarith)
      set α := D / (G * s) with hα
      have hαp : 0 < α := by positivity
      set d1 := ‖w (n + 1) - u‖ with hd1
      set d2 := ‖w (n + 1 + 1) - u‖ with hd2
      have hone := ogd_one_step_helper K hK P hPK hPnear (w (n + 1)) (g (n + 1)) u
        (hwK _ (by omega)) hu α hαp
      rw [← hstep (n + 1) (by omega)] at hone
      have hdd : d1 ≤ D := hD _ (hwK _ (by omega)) u hu
      have hd10 : 0 ≤ d1 := norm_nonneg _
      have hgn : ‖g (n + 1)‖ ≤ G := hG _ (by omega)
      have h1 : (d1 ^ 2 - d2 ^ 2) / (2 * α) = G * s / (2 * D) * (d1 ^ 2 - d2 ^ 2) := by
        rw [hα]; field_simp
      have h2 : α / 2 * ‖g (n + 1)‖ ^ 2 ≤ D * G / (2 * s) := by
        calc α / 2 * ‖g (n + 1)‖ ^ 2 ≤ α / 2 * G ^ 2 := by
              apply mul_le_mul_of_nonneg_left _ (by positivity)
              exact pow_le_pow_left₀ (norm_nonneg _) hgn 2
          _ = D * G / (2 * s) := by rw [hα]; field_simp
      have h3 : G * (s - r) / (2 * D) * d1 ^ 2 ≤ G * (s - r) / (2 * D) * D ^ 2 := by
        apply mul_le_mul_of_nonneg_left _ (by
          apply div_nonneg (mul_nonneg hGp.le (by linarith)) (by positivity))
        exact pow_le_pow_left₀ hd10 hdd 2
      have h3' : G * (s - r) / (2 * D) * D ^ 2 = D * G * (s - r) / 2 := by
        field_simp
      have h4 : D * G / (2 * s) ≤ D * G * (s - r) := by
        have hrs2 : 2 * (r * s) ≤ 2 * n + 1 := by nlinarith [sq_nonneg (s - r)]
        rw [div_le_iff₀ (by positivity)]
        have : 1 ≤ 2 * s * (s - r) := by nlinarith
        have hDG : 0 < D * G := mul_pos hDp hGp
        nlinarith
      have hsplit1 : G * s / (2 * D) * (d1 ^ 2 - d2 ^ 2)
          = G * r / (2 * D) * d1 ^ 2 + G * (s - r) / (2 * D) * d1 ^ 2
            - G * s / (2 * D) * d2 ^ 2 := by ring
      have hterm' := hterm (n + 1) (by omega)
      have hlast : 3 / 2 * D * G * r + D * G * (s - r) / 2 + D * G * (s - r)
          = 3 / 2 * D * G * s := by ring
      linarith
  have := claim T
  have hnn : 0 ≤ G * Real.sqrt T / (2 * D) * ‖w (T + 1) - u‖ ^ 2 := by positivity
  linarith

/-- Strong convexity buys `log T`. Let every day's loss be `μ`-strongly convex on the convex
set of valid mixes, with `μ > 0` known; let each day's mix be chosen before that day's loss is
seen, by stepping against the previous day's gradient with step `1 / (μ t)` and projecting back
to the nearest valid mix; and let every gradient be at most `G` long. Then the total loss over
`T` days exceeds the total loss of any fixed valid mix by at most `G² / (2μ) · (1 + ln T)`. -/
theorem ogd_regret_le_log_T_of_strongConvex
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]
    (K : Set E) (μ G : ℝ) (hμ : 0 < μ)
    (P : E → E) (hPK : ∀ v, P v ∈ K) (hPnear : ∀ v, ∀ u ∈ K, ‖v - P v‖ ≤ ‖v - u‖)
    (f : ℕ → E → ℝ) (hconv : ∀ t, StrongConvexOn K μ (f t))
    (w g : ℕ → E) (hw1 : w 1 ∈ K)
    (hgrad : ∀ t, 1 ≤ t → HasGradientAt (f t) (g t) (w t))
    (hG : ∀ t, 1 ≤ t → ‖g t‖ ≤ G)
    (hstep : ∀ t, 1 ≤ t → w (t + 1) = P (w t - (1 / (μ * t)) • g t))
    (T : ℕ) :
    ∀ u ∈ K, ∑ t ∈ Finset.Icc 1 T, (f t (w t) - f t u)
      ≤ G ^ 2 / (2 * μ) * (1 + Real.log T) := by
  intro u hu
  have hK : Convex ℝ K := (hconv 0).1
  have hwK : ∀ t, 1 ≤ t → w t ∈ K := by
    intro t ht
    obtain ⟨n, rfl⟩ : ∃ n, t = n + 1 := ⟨t - 1, by omega⟩
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · exact hw1
    · obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
      rw [hstep (m + 1) (by omega)]
      exact hPK _
  have hterm : ∀ t, 1 ≤ t →
      f t (w t) - f t u ≤ ⟪g t, w t - u⟫ - μ / 2 * ‖w t - u‖ ^ 2 := fun t ht =>
    ogd_strong_first_order K μ (f t) (hconv t) (g t) (w t) (hwK t ht) (hgrad t ht) u hu
  have hc0 : 0 ≤ G ^ 2 / (2 * μ) := by positivity
  have claim : ∀ n : ℕ, ∑ t ∈ Finset.Icc 1 n, (f t (w t) - f t u)
      + μ * n / 2 * ‖w (n + 1) - u‖ ^ 2
      ≤ G ^ 2 / (2 * μ) * ∑ t ∈ Finset.Icc 1 n, (1 / (t : ℝ)) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_Icc_succ_top (by omega), mul_add]
      set m : ℝ := ((n + 1 : ℕ) : ℝ) with hm
      have hm' : m = (n : ℝ) + 1 := by rw [hm]; push_cast; ring
      have hm0 : 0 < m := by rw [hm']; positivity
      set α := 1 / (μ * m) with hα
      have hαp : 0 < α := by positivity
      set d1 := ‖w (n + 1) - u‖ with hd1
      set d2 := ‖w (n + 1 + 1) - u‖ with hd2
      have hone := ogd_one_step_helper K hK P hPK hPnear (w (n + 1)) (g (n + 1)) u
        (hwK _ (by omega)) hu α hαp
      rw [← hstep (n + 1) (by omega)] at hone
      have hgn : ‖g (n + 1)‖ ≤ G := hG _ (by omega)
      have h1 : (d1 ^ 2 - d2 ^ 2) / (2 * α) = μ * m / 2 * (d1 ^ 2 - d2 ^ 2) := by
        rw [hα]; field_simp
      have h2 : α / 2 * ‖g (n + 1)‖ ^ 2 ≤ G ^ 2 / (2 * μ) * (1 / m) := by
        calc α / 2 * ‖g (n + 1)‖ ^ 2 ≤ α / 2 * G ^ 2 := by
              apply mul_le_mul_of_nonneg_left _ (by positivity)
              exact pow_le_pow_left₀ (norm_nonneg _) hgn 2
          _ = G ^ 2 / (2 * μ) * (1 / m) := by rw [hα]; field_simp
      have hterm' := hterm (n + 1) (by omega)
      have hsplit : μ * m / 2 * (d1 ^ 2 - d2 ^ 2) - μ / 2 * d1 ^ 2
          = μ * n / 2 * d1 ^ 2 - μ * m / 2 * d2 ^ 2 := by rw [hm']; ring
      linarith
  have h := claim T
  have hnn : 0 ≤ μ * T / 2 * ‖w (T + 1) - u‖ ^ 2 := by positivity
  have hH := mul_le_mul_of_nonneg_left (ogd_harmonic_le T) hc0
  linarith

/-- One day, one inequality (the card's Step 1). If the set of valid mixes is convex, `w` and
`u` are valid mixes, `α > 0` is the step and `w⁺ = Π(w - α g)` is the nearest valid mix to the
stepped point, then the linearised regret `g^T (w - u)` is paid for by the drop in squared
distance to `u`, divided by `2α`, plus `α/2` times the squared slope:
`⟪g, w - u⟫ ≤ (‖w - u‖² - ‖w⁺ - u‖²) / (2α) + (α/2) ‖g‖²`. -/
theorem ogd_one_step_inequality
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (K : Set E) (hK : Convex ℝ K)
    (P : E → E) (hPK : ∀ v, P v ∈ K) (hPnear : ∀ v, ∀ u ∈ K, ‖v - P v‖ ≤ ‖v - u‖)
    (w g u : E) (hw : w ∈ K) (hu : u ∈ K) (α : ℝ) (hα : 0 < α) :
    ⟪g, w - u⟫ ≤ (‖w - u‖ ^ 2 - ‖P (w - α • g) - u‖ ^ 2) / (2 * α) + α / 2 * ‖g‖ ^ 2 := by
  exact ogd_one_step_helper K hK P hPK hPnear w g u hw hu α hα

/-! The card's whole-number check. The best fixed mix in hindsight is confirmed by enumerating
every mix of three sleeves whose weights are multiples of 1/600: a mix is 600 equal units
shared among 3 sleeves, a multiset of size 600 from 3 sleeves, and there are
`(600 + 1)(600 + 2)/2 = 180,901` of them. -/
example : (600 + 1) * (600 + 2) / 2 = 180901 := by norm_num
example : Nat.multichoose 3 600 = 180901 := by
  rw [Nat.multichoose_eq, Nat.choose_symm_of_eq_add (show 3 + 600 - 1 = 600 + 2 by norm_num),
    Nat.choose_two_right]
example : Fintype.card (Sym (Fin 3) 600) = 180901 := by
  rw [Sym.card_sym_eq_multichoose, Fintype.card_fin, Nat.multichoose_eq,
    Nat.choose_symm_of_eq_add (show 3 + 600 - 1 = 600 + 2 by norm_num), Nat.choose_two_right]

#print axioms ogd_regret_le_three_halves_D_G_sqrt_T
#print axioms ogd_regret_le_log_T_of_strongConvex
#print axioms ogd_one_step_inequality
