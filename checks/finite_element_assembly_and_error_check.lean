-- Assembly and error: for a cable obeying -T u'' = f, bolted at x = 0 and pulled by P at x = L, the hat-function answer of the assembled system has exact nodes, its stiffness matrix is the sum of the element matrices, and its slope and sag errors are at most h/π and (h/π)² times the RMS curvature.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Tactic

open MeasureTheory Set

/-- The hat function of node `i` on a mesh of spacing `h`: 1 at the node `x_i = i h`,
0 at every other node, straight in between. -/
noncomputable def hat (h : ℝ) (i : ℕ) (x : ℝ) : ℝ := max 0 (1 - |x - i * h| / h)

/-- The stiffness matrix of the cable `[0, L]` cut into `n` elements of length `h = L / n`,
by exact integrals: `K_ij = ∫₀ᴸ T φ_i' φ_j' dx`. -/
noncomputable def stiffness (T L : ℝ) (n i j : ℕ) : ℝ :=
  ∫ x in (0 : ℝ)..L, T * deriv (hat (L / n) i) x * deriv (hat (L / n) j) x

/-- The load list, by exact integrals, with the ring's pull `P` as one extra load at the last
node (the natural condition): `F_i = ∫₀ᴸ f φ_i dx + (P if i = n, else 0)`. -/
noncomputable def load (f : ℝ → ℝ) (P L : ℝ) (n i : ℕ) : ℝ :=
  (∫ x in (0 : ℝ)..L, f x * hat (L / n) i x) + if i = n then P else 0

/-- The computed sag `u_h = Σ U_i φ_i`, a sum of hat functions with node values `U_i`. -/
noncomputable def feSag (L : ℝ) (n : ℕ) (U : ℕ → ℝ) (x : ℝ) : ℝ :=
  ∑ j ∈ Finset.range (n + 1), U j * hat (L / n) j x

/-- Root-mean-square over the cable: `RMS(g) = sqrt((1/L) ∫₀ᴸ g² dx)`. -/
noncomputable def rms (L : ℝ) (g : ℝ → ℝ) : ℝ :=
  Real.sqrt ((1 / L) * ∫ x in (0 : ℝ)..L, g x ^ 2)

/-- Assembly: add each element's 2 by 2 matrix into the rows and columns of its own two nodes.
Element `e` joins nodes `e` and `e + 1`. -/
def assemble (n : ℕ) (k : Matrix (Fin 2) (Fin 2) ℝ) (i j : ℕ) : ℝ :=
  ∑ e ∈ Finset.range n, ∑ a : Fin 2, ∑ b : Fin 2,
    if e + (a : ℕ) = i ∧ e + (b : ℕ) = j then k a b else 0

lemma fe_friedrichs_k {a b k : ℝ} (hab : a < b) (hk : 0 < k) (hkπ : k * (b - a) < Real.pi)
    {g g' : ℝ → ℝ} (hg : ContinuousOn g (Icc a b))
    (hd : ∀ x ∈ Ioo a b, HasDerivAt g (g' x) x) (hga : g a = 0) (hgb : g b = 0)
    (hint : IntegrableOn (fun x => g' x ^ 2) (Icc a b)) :
    k ^ 2 * ∫ x in a..b, g x ^ 2 ≤ ∫ x in a..b, g' x ^ 2 := by
  set c := (Real.pi - k * (b - a)) / 2 with hc
  have hsin : ∀ x ∈ Icc a b, 0 < Real.sin (k * (x - a) + c) := by
    intro x hx
    apply Real.sin_pos_of_pos_of_lt_pi
    · nlinarith [hx.1]
    · nlinarith [hx.2]
  set G : ℝ → ℝ := fun x => g x ^ 2 * (k * Real.cos (k * (x - a) + c) / Real.sin (k * (x - a) + c))
  have hθ : ∀ x, HasDerivAt (fun x => k * (x - a) + c) k x := by
    intro x
    simpa using (((hasDerivAt_id x).sub_const a).const_mul k).add_const c
  have hGd : ∀ x ∈ Ioo a b, HasDerivAt G
      (2 * g x * g' x * (k * Real.cos (k * (x - a) + c) / Real.sin (k * (x - a) + c))
        - k ^ 2 * g x ^ 2 / Real.sin (k * (x - a) + c) ^ 2) x := by
    intro x hx
    have hs := hsin x (Ioo_subset_Icc_self hx)
    have h1 := ((hd x hx).pow 2).mul ((((hθ x).cos).const_mul k).div (hθ x).sin hs.ne')
    convert h1 using 1
    have hsc := Real.sin_sq_add_cos_sq (k * (x - a) + c)
    simp only [Pi.div_apply, Pi.pow_apply]
    push_cast
    field_simp
    linear_combination (g x ^ 2 * k) * hsc
  have hGc : ContinuousOn G (Icc a b) := by
    apply (hg.pow 2).mul
    apply ContinuousOn.div
    · exact (continuous_const.mul (Real.continuous_cos.comp
        ((continuous_const.mul (continuous_id.sub continuous_const)).add continuous_const))).continuousOn
    · exact (Real.continuous_sin.comp
        ((continuous_const.mul (continuous_id.sub continuous_const)).add continuous_const)).continuousOn
    · intro x hx; exact (hsin x hx).ne'
  have hg2 : IntegrableOn (fun x => g x ^ 2) (Icc a b) :=
    (hg.pow 2).integrableOn_compact isCompact_Icc
  have key := intervalIntegral.sub_le_integral_of_hasDeriv_right_of_le hab.le hGc
    (fun x hx => (hGd x hx).hasDerivWithinAt) (hint.sub (hg2.const_mul (k ^ 2)))
    (fun x hx => by
      have hs := hsin x (Ioo_subset_Icc_self hx)
      have hsc := Real.sin_sq_add_cos_sq (k * (x - a) + c)
      set S := Real.sin (k * (x - a) + c)
      set C := Real.cos (k * (x - a) + c)
      have : g' x ^ 2 - k ^ 2 * g x ^ 2 - (2 * g x * g' x * (k * C / S) - k ^ 2 * g x ^ 2 / S ^ 2)
          = (g' x - g x * k * C / S) ^ 2 := by
        field_simp
        linear_combination (-(k ^ 2 * g x ^ 2)) * hsc
      simp only [Pi.sub_apply]
      nlinarith [sq_nonneg (g' x - g x * k * C / S)])
  simp only [G, hga, hgb, Pi.sub_apply] at key
  rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul] at key
  · simpa using key
  · exact (intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2 hint
  · exact ((intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2 hg2).const_mul _

#print axioms fe_friedrichs_k

lemma fe_friedrichs {a b : ℝ} (hab : a < b)
    {g g' : ℝ → ℝ} (hg : ContinuousOn g (Icc a b))
    (hd : ∀ x ∈ Ioo a b, HasDerivAt g (g' x) x) (hga : g a = 0) (hgb : g b = 0)
    (hint : IntegrableOn (fun x => g' x ^ 2) (Icc a b)) :
    ∫ x in a..b, g x ^ 2 ≤ ((b - a) / Real.pi) ^ 2 * ∫ x in a..b, g' x ^ 2 := by
  set X := ∫ x in a..b, g x ^ 2
  set Y := ∫ x in a..b, g' x ^ 2
  have hba : 0 < b - a := sub_pos.2 hab
  have hK : 0 < Real.pi / (b - a) := div_pos Real.pi_pos hba
  have main : (Real.pi / (b - a)) ^ 2 * X ≤ Y := by
    by_contra hcon
    push Not at hcon
    have h1 : ∀ᶠ k in nhdsWithin (Real.pi / (b - a)) (Iio (Real.pi / (b - a))), Y < k ^ 2 * X := by
      have ht : Filter.Tendsto (fun k : ℝ => k ^ 2 * X) (nhds (Real.pi / (b - a)))
          (nhds ((Real.pi / (b - a)) ^ 2 * X)) :=
        ((continuous_pow 2).mul continuous_const).continuousAt.tendsto
      exact (ht.mono_left nhdsWithin_le_nhds).eventually (lt_mem_nhds hcon)
    have h2 : ∀ᶠ k in nhdsWithin (Real.pi / (b - a)) (Iio (Real.pi / (b - a))),
        k ∈ Ioo 0 (Real.pi / (b - a)) := Ioo_mem_nhdsLT hK
    obtain ⟨k, hk1, hk2⟩ := (h1.and h2).exists
    have hkπ : k * (b - a) < Real.pi := by
      have := hk2.2
      rwa [lt_div_iff₀ hba] at this
    have := fe_friedrichs_k hab hk2.1 hkπ hg hd hga hgb hint
    linarith
  have hc : ((b - a) / Real.pi) ^ 2 * (Real.pi / (b - a)) ^ 2 = 1 := by
    rw [← mul_pow, div_mul_div_comm, mul_comm (b - a), div_self (by positivity)]
    simp
  calc X = ((b - a) / Real.pi) ^ 2 * ((Real.pi / (b - a)) ^ 2 * X) := by
        rw [← mul_assoc, hc, one_mul]
    _ ≤ ((b - a) / Real.pi) ^ 2 * Y := mul_le_mul_of_nonneg_left main (by positivity)

#print axioms fe_friedrichs

lemma fe_element_bounds {a b : ℝ} (hab : a < b)
    {e e' w : ℝ → ℝ} (he : ContinuousOn e (Icc a b)) (he' : ContinuousOn e' (Icc a b))
    (hd : ∀ x ∈ Ioo a b, HasDerivAt e (e' x) x) (hd' : ∀ x ∈ Ioo a b, HasDerivAt e' (w x) x)
    (hea : e a = 0) (heb : e b = 0)
    (hw : IntegrableOn w (Icc a b)) (hw2 : IntegrableOn (fun x => w x ^ 2) (Icc a b)) :
    ∫ x in a..b, e' x ^ 2 ≤ ((b - a) / Real.pi) ^ 2 * ∫ x in a..b, w x ^ 2 ∧
    ∫ x in a..b, e x ^ 2 ≤ (((b - a) / Real.pi) ^ 2) ^ 2 * ∫ x in a..b, w x ^ 2 := by
  set c := ((b - a) / Real.pi) ^ 2 with hcdef
  have hba : 0 < b - a := sub_pos.2 hab
  have hc : 0 < c := by positivity
  have he'2 : IntegrableOn (fun x => e' x ^ 2) (Icc a b) :=
    (he'.pow 2).integrableOn_compact isCompact_Icc
  have he2 : IntegrableOn (fun x => e x ^ 2) (Icc a b) :=
    (he.pow 2).integrableOn_compact isCompact_Icc
  have hew : IntegrableOn (fun x => e x * w x) (Icc a b) :=
    hw.continuousOn_mul he isCompact_Icc
  have F1 := fe_friedrichs hab he hd hea heb he'2
  have ii : ∀ {f : ℝ → ℝ}, IntegrableOn f (Icc a b) → IntervalIntegrable f volume a b :=
    fun h => (intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2 h
  -- integration by parts: ∫ e'^2 + e w = 0
  have ibp : ∫ x in a..b, (e' x ^ 2 + e x * w x) = 0 := by
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le (f := fun x => e x * e' x) (f' := fun x => e' x ^ 2 + e x * w x) hab.le
      (he.mul he') (fun x hx => by
        have := (hd x hx).mul (hd' x hx)
        convert this using 1; ring) (ii (he'2.add hew))]
    simp [hea, heb]
  rw [intervalIntegral.integral_add (ii he'2) (ii hew)] at ibp
  have amgm : ∫ x in a..b, -(e x * w x) ≤
      ∫ x in a..b, (1 / (2 * c) * e x ^ 2 + c / 2 * w x ^ 2) := by
    apply intervalIntegral.integral_mono_on hab.le (ii hew).neg
      ((ii he2).const_mul _ |>.add ((ii hw2).const_mul _))
    intro x _
    show -(e x * w x) ≤ _
    have : 0 ≤ (e x + c * w x) ^ 2 / (2 * c) := by positivity
    have h2 : (e x + c * w x) ^ 2 / (2 * c) = 1 / (2 * c) * e x ^ 2 + e x * w x + c / 2 * w x ^ 2 := by
      field_simp; ring
    linarith
  rw [intervalIntegral.integral_neg, intervalIntegral.integral_add ((ii he2).const_mul _)
    ((ii hw2).const_mul _), intervalIntegral.integral_const_mul,
    intervalIntegral.integral_const_mul] at amgm
  set X := ∫ x in a..b, e x ^ 2
  set Y := ∫ x in a..b, e' x ^ 2
  set W := ∫ x in a..b, w x ^ 2
  have hY : Y ≤ c * W := by
    have h3 : 1 / (2 * c) * X ≤ 1 / (2 * c) * (c * Y) :=
      mul_le_mul_of_nonneg_left F1 (by positivity)
    have h4 : 1 / (2 * c) * (c * Y) = Y / 2 := by field_simp
    linarith
  refine ⟨hY, ?_⟩
  calc X ≤ c * Y := F1
    _ ≤ c * (c * W) := mul_le_mul_of_nonneg_left hY hc.le
    _ = c ^ 2 * W := by ring

#print axioms fe_element_bounds

/-- Slope of hat function `j` on element `k`. -/

noncomputable def feSlope (h : ℝ) (j k : ℕ) : ℝ :=
  (if j = k then -1 / h else 0) + (if j = k + 1 then 1 / h else 0)

/-- Value of hat function `j` on element `k`. -/

noncomputable def feHatLin (h : ℝ) (j k : ℕ) (x : ℝ) : ℝ :=
  (if j = k then (((k : ℝ) + 1) * h - x) / h else 0) +
    (if j = k + 1 then (x - (k : ℝ) * h) / h else 0)

lemma fe_hat_on_elem {h : ℝ} (hh : 0 < h) (j k : ℕ) {x : ℝ}
    (hx : x ∈ Icc ((k : ℝ) * h) (((k : ℝ) + 1) * h)) : hat h j x = feHatLin h j k x := by
  obtain ⟨hx1, hx2⟩ := hx
  unfold hat feHatLin
  by_cases h1 : j = k
  · subst h1
    have h2 : j ≠ j + 1 := by omega
    rw [if_pos rfl, if_neg h2, abs_of_nonneg (by linarith), max_eq_right]
    · field_simp; ring
    · rw [sub_nonneg, div_le_one hh]; linarith
  by_cases h2 : j = k + 1
  · subst h2
    rw [if_neg h1, if_pos rfl, abs_of_nonpos (by push_cast; linarith), max_eq_right]
    · push_cast; field_simp; ring
    · rw [sub_nonneg, div_le_one hh]; push_cast; linarith
  rw [if_neg h1, if_neg h2, max_eq_left]
  · simp
  rw [sub_nonpos, le_div_iff₀ hh, one_mul]
  rcases Nat.lt_or_gt_of_ne h1 with h3 | h3
  · have : (j : ℝ) + 1 ≤ k := by exact_mod_cast h3
    rw [abs_of_nonneg (by nlinarith)]; nlinarith
  · have : (k : ℝ) + 2 ≤ j := by
      have : k + 2 ≤ j := by omega
      exact_mod_cast this
    rw [abs_of_nonpos (by nlinarith)]; nlinarith

#print axioms fe_hat_on_elem

lemma fe_hatLin_hasDerivAt (h : ℝ) (j k : ℕ) (x : ℝ) :
    HasDerivAt (feHatLin h j k) (feSlope h j k) x := by
  unfold feHatLin feSlope
  apply HasDerivAt.add
  · split_ifs
    · simpa using ((hasDerivAt_id x).const_sub (((k : ℝ) + 1) * h)).div_const h
    · exact hasDerivAt_const _ _
  · split_ifs
    · simpa using ((hasDerivAt_id x).sub_const ((k : ℝ) * h)).div_const h
    · exact hasDerivAt_const _ _

#print axioms fe_hatLin_hasDerivAt

lemma fe_hat_hasDerivAt {h : ℝ} (hh : 0 < h) (j k : ℕ) {x : ℝ}
    (hx : x ∈ Ioo ((k : ℝ) * h) (((k : ℝ) + 1) * h)) :
    HasDerivAt (hat h j) (feSlope h j k) x := by
  apply (fe_hatLin_hasDerivAt h j k x).congr_of_eventuallyEq
  filter_upwards [Ioo_mem_nhds hx.1 hx.2] with y hy
  exact fe_hat_on_elem hh j k (Ioo_subset_Icc_self hy)

#print axioms fe_hat_hasDerivAt

lemma fe_deriv_hat {h : ℝ} (hh : 0 < h) (j k : ℕ) {x : ℝ}
    (hx : x ∈ Ioo ((k : ℝ) * h) (((k : ℝ) + 1) * h)) :
    deriv (hat h j) x = feSlope h j k :=
  (fe_hat_hasDerivAt hh j k hx).deriv

#print axioms fe_deriv_hat

lemma fe_sum_hatLin (n k : ℕ) (hk : k < n) (h : ℝ) (U : ℕ → ℝ) (x : ℝ) :
    ∑ j ∈ Finset.range (n + 1), U j * feHatLin h j k x =
      U k * ((((k : ℝ) + 1) * h - x) / h) + U (k + 1) * ((x - (k : ℝ) * h) / h) := by
  unfold feHatLin
  simp only [mul_add, mul_ite, mul_zero, Finset.sum_add_distrib, Finset.sum_ite_eq',
    Finset.mem_range]
  rw [if_pos (by omega), if_pos (by omega)]

#print axioms fe_sum_hatLin

lemma fe_sum_slope (n k : ℕ) (hk : k < n) (h : ℝ) (U : ℕ → ℝ) :
    ∑ j ∈ Finset.range (n + 1), U j * feSlope h j k = (U (k + 1) - U k) / h := by
  unfold feSlope
  simp only [mul_add, mul_ite, mul_zero, Finset.sum_add_distrib, Finset.sum_ite_eq',
    Finset.mem_range]
  rw [if_pos (by omega), if_pos (by omega)]
  ring

#print axioms fe_sum_slope

lemma fe_feSag_on_elem {L : ℝ} {n : ℕ} (hh : 0 < L / n) (k : ℕ) (hk : k < n) (U : ℕ → ℝ) {x : ℝ}
    (hx : x ∈ Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) :
    feSag L n U x = U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
      U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n)) := by
  unfold feSag
  rw [← fe_sum_hatLin n k hk]
  exact Finset.sum_congr rfl fun j _ => by rw [fe_hat_on_elem hh j k hx]

#print axioms fe_feSag_on_elem

lemma fe_feSag_hasDerivAt {L : ℝ} {n : ℕ} (hh : 0 < L / n) (k : ℕ) (hk : k < n) (U : ℕ → ℝ)
    {x : ℝ} (hx : x ∈ Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) :
    HasDerivAt (feSag L n U) ((U (k + 1) - U k) / (L / n)) x := by
  have hlin : HasDerivAt (fun y => U k * ((((k : ℝ) + 1) * (L / n) - y) / (L / n)) +
      U (k + 1) * ((y - (k : ℝ) * (L / n)) / (L / n))) ((U (k + 1) - U k) / (L / n)) x := by
    have := ((((hasDerivAt_id x).const_sub (((k : ℝ) + 1) * (L / n))).div_const (L / n)).const_mul
      (U k)).add ((((hasDerivAt_id x).sub_const ((k : ℝ) * (L / n))).div_const (L / n)).const_mul
      (U (k + 1)))
    exact this.congr_deriv (by ring)
  apply hlin.congr_of_eventuallyEq
  filter_upwards [Ioo_mem_nhds hx.1 hx.2] with y hy
  exact fe_feSag_on_elem hh k hk U (Ioo_subset_Icc_self hy)

#print axioms fe_feSag_hasDerivAt

lemma fe_split {L : ℝ} (hL : 0 < L) {n : ℕ} (hn : 0 < n) {f : ℝ → ℝ}
    (hint : ∀ k < n, IntervalIntegrable f volume ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) :
    ∫ x in (0 : ℝ)..L, f x =
      ∑ k ∈ Finset.range n, ∫ x in ((k : ℝ) * (L / n))..(((k : ℝ) + 1) * (L / n)), f x := by
  have e1 : ((n : ℕ) : ℝ) * (L / n) = L := by
    have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
    field_simp
  have := intervalIntegral.sum_integral_adjacent_intervals (μ := volume) (f := f)
    (a := fun k : ℕ => (k : ℝ) * (L / n)) (n := n) (fun k hk => by push_cast; exact hint k hk)
  push_cast at this
  rw [e1, zero_mul] at this
  exact this.symm

#print axioms fe_split

lemma fe_congr {a b : ℝ} (hab : a ≤ b) {f g : ℝ → ℝ} (hfg : EqOn f g (Ioo a b))
    (hg : IntervalIntegrable g volume a b) :
    IntervalIntegrable f volume a b ∧ ∫ x in a..b, f x = ∫ x in a..b, g x :=
  ⟨hg.congr_uIoo (by rw [uIoo_of_le hab]; exact hfg.symm),
    intervalIntegral.integral_congr_Ioo_of_le hab hfg⟩

#print axioms fe_congr

lemma fe_elem_le {L : ℝ} {n : ℕ} (hh : 0 < L / n) (k : ℕ) :
    (k : ℝ) * (L / n) ≤ ((k : ℝ) + 1) * (L / n) := by nlinarith

#print axioms fe_elem_le

lemma fe_stiffness_sum (T L : ℝ) (hL : 0 < L) (n : ℕ) (hn : 0 < n) (i j : ℕ) :
    stiffness T L n i j =
      ∑ k ∈ Finset.range n, (L / n) * (T * feSlope (L / n) i k * feSlope (L / n) j k) := by
  have hh : 0 < L / n := by positivity
  have hc : ∀ k : ℕ, EqOn (fun x => T * deriv (hat (L / n) i) x * deriv (hat (L / n) j) x)
      (fun _ => T * feSlope (L / n) i k * feSlope (L / n) j k)
      (Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) := by
    intro k x hx
    simp only [fe_deriv_hat hh i k hx, fe_deriv_hat hh j k hx]
  unfold stiffness
  rw [fe_split hL hn (fun k _ => (fe_congr (fe_elem_le hh k) (hc k) intervalIntegrable_const).1)]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [(fe_congr (fe_elem_le hh k) (hc k) intervalIntegrable_const).2, intervalIntegral.integral_const]
  simp only [smul_eq_mul]
  ring

#print axioms fe_stiffness_sum

theorem fe_stiffness_assembled (T L : ℝ) (hL : 0 < L) (n : ℕ) (hn : 0 < n) (i j : ℕ) :
    stiffness T L n i j = assemble n ((T / (L / n)) • !![1, -1; -1, 1]) i j := by
  have hh : 0 < L / n := by positivity
  rw [fe_stiffness_sum T L hL n hn]
  unfold assemble
  refine Finset.sum_congr rfl fun k _ => ?_
  simp only [Fin.sum_univ_two, Matrix.smul_apply, smul_eq_mul, Fin.val_zero, Fin.val_one,
    add_zero, Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
    Matrix.empty_val', Matrix.cons_val_fin_one]
  unfold feSlope
  set h := L / (n : ℝ)
  have hh' : h ≠ 0 := hh.ne'
  split_ifs <;> first | omega | (field_simp; ring)

#print axioms fe_stiffness_assembled

lemma fe_weight_left {a b h : ℝ} (hab : a < b) (hh : b - a = h) {u u' u'' : ℝ → ℝ}
    (hcu : ContinuousOn u (Icc a b)) (hcu' : ContinuousOn u' (Icc a b))
    (hdu : ∀ x ∈ Ioo a b, HasDerivAt u (u' x) x) (hdu' : ∀ x ∈ Ioo a b, HasDerivAt u' (u'' x) x)
    (hi : IntegrableOn u'' (Icc a b)) :
    ∫ x in a..b, u'' x * ((b - x) / h) = (u b - u a) / h - u' a := by
  subst hh
  have hne : b - a ≠ 0 := (sub_pos.2 hab).ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le (f := fun x => (u' x * (b - x) + u x) / (b - a))
    (f' := fun x => u'' x * ((b - x) / (b - a)))
    hab.le ((hcu'.mul (continuous_const.sub continuous_id).continuousOn).add hcu |>.div_const _)
    (fun x hx => by
      have := (((hdu' x hx).mul ((hasDerivAt_id x).const_sub b)).add (hdu x hx)).div_const (b - a)
      exact this.congr_deriv (by simp; ring))
    ((intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2
      (hi.mul_continuousOn ((continuous_const.sub continuous_id).div_const _).continuousOn
        isCompact_Icc))]
  field_simp
  ring

#print axioms fe_weight_left

lemma fe_weight_right {a b h : ℝ} (hab : a < b) (hh : b - a = h) {u u' u'' : ℝ → ℝ}
    (hcu : ContinuousOn u (Icc a b)) (hcu' : ContinuousOn u' (Icc a b))
    (hdu : ∀ x ∈ Ioo a b, HasDerivAt u (u' x) x) (hdu' : ∀ x ∈ Ioo a b, HasDerivAt u' (u'' x) x)
    (hi : IntegrableOn u'' (Icc a b)) :
    ∫ x in a..b, u'' x * ((x - a) / h) = u' b - (u b - u a) / h := by
  subst hh
  have hne : b - a ≠ 0 := (sub_pos.2 hab).ne'
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le (f := fun x => (u' x * (x - a) - u x) / (b - a))
    (f' := fun x => u'' x * ((x - a) / (b - a)))
    hab.le ((hcu'.mul (continuous_id.sub continuous_const).continuousOn).sub hcu |>.div_const _)
    (fun x hx => by
      have := (((hdu' x hx).mul ((hasDerivAt_id x).sub_const a)).sub (hdu x hx)).div_const (b - a)
      exact this.congr_deriv (by simp; ring))
    ((intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2
      (hi.mul_continuousOn ((continuous_id.sub continuous_const).div_const _).continuousOn
        isCompact_Icc))]
  field_simp
  ring

#print axioms fe_weight_right

lemma fe_elem_facts {L : ℝ} (hL : 0 < L) {n : ℕ} (hn : 0 < n) {u u' u'' : ℝ → ℝ}
    (hu : ∀ x ∈ Icc 0 L, HasDerivWithinAt u (u' x) (Icc 0 L) x)
    (hu' : ∀ x ∈ Icc 0 L, HasDerivWithinAt u' (u'' x) (Icc 0 L) x) (k : ℕ) (hk : k < n) :
    Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)) ⊆ Icc 0 L ∧
    ContinuousOn u (Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) ∧
    ContinuousOn u' (Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) ∧
    (∀ x ∈ Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)), HasDerivAt u (u' x) x) ∧
    (∀ x ∈ Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)), HasDerivAt u' (u'' x) x) := by
  have hh : 0 < L / n := by positivity
  have hsub : Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)) ⊆ Icc 0 L := by
    have hk' : (k : ℝ) + 1 ≤ n := by exact_mod_cast hk
    have hnL : (n : ℝ) * (L / n) = L := by
      have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
      field_simp
    apply Icc_subset_Icc
    · positivity
    · nlinarith
  have hcu : ContinuousOn u (Icc 0 L) := fun x hx => (hu x hx).continuousWithinAt
  have hcu' : ContinuousOn u' (Icc 0 L) := fun x hx => (hu' x hx).continuousWithinAt
  have hnhds : ∀ x ∈ Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)), Icc 0 L ∈ nhds x := by
    intro x hx
    exact Filter.mem_of_superset (Ioo_mem_nhds hx.1 hx.2)
      (Ioo_subset_Icc_self.trans hsub)
  refine ⟨hsub, hcu.mono hsub, hcu'.mono hsub, fun x hx => ?_, fun x hx => ?_⟩
  · exact (hu x (hsub (Ioo_subset_Icc_self hx))).hasDerivAt (hnhds x hx)
  · exact (hu' x (hsub (Ioo_subset_Icc_self hx))).hasDerivAt (hnhds x hx)

#print axioms fe_elem_facts

lemma fe_feHatLin_continuous (h : ℝ) (j k : ℕ) : Continuous (feHatLin h j k) :=
  continuous_iff_continuousAt.2 fun x => (fe_hatLin_hasDerivAt h j k x).continuousAt

#print axioms fe_feHatLin_continuous

lemma fe_integrableOn_u'' {L : ℝ} (_hL : 0 < L) {u'' : ℝ → ℝ}
    (hsq : MemLp u'' 2 (volume.restrict (Icc 0 L))) :
    IntegrableOn u'' (Icc 0 L) ∧ IntegrableOn (fun x => u'' x ^ 2) (Icc 0 L) := by
  have : IsFiniteMeasure (volume.restrict (Icc 0 L)) :=
    isFiniteMeasure_restrict.2 (by simp [Real.volume_Icc])
  exact ⟨hsq.integrable (by norm_num), hsq.integrable_sq⟩

#print axioms fe_integrableOn_u''

lemma fe_row_sum (T L : ℝ) (hL : 0 < L) (n : ℕ) (hn : 0 < n) (U : ℕ → ℝ) (i : ℕ) :
    ∑ j ∈ Finset.range (n + 1), stiffness T L n i j * U j =
      ∑ k ∈ Finset.range n, T * feSlope (L / n) i k * (U (k + 1) - U k) := by
  have hh : 0 < L / n := by positivity
  simp_rw [fe_stiffness_sum T L hL n hn, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun k hk => ?_
  have := fe_sum_slope n k (Finset.mem_range.1 hk) (L / n) U
  calc ∑ j ∈ Finset.range (n + 1), L / n * (T * feSlope (L / n) i k * feSlope (L / n) j k) * U j
      = (L / n * T * feSlope (L / n) i k) *
          ∑ j ∈ Finset.range (n + 1), U j * feSlope (L / n) j k := by
        rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun j _ => by ring
    _ = _ := by rw [this]; field_simp

#print axioms fe_row_sum

lemma fe_sum_two (n m : ℕ) (hm : m + 1 ≤ n) (F G S : ℕ → ℝ)
    (hS : ∀ k, S k = (if m + 1 = k then F k else 0) + (if m + 1 = k + 1 then G k else 0)) :
    ∑ k ∈ Finset.range n, S k = (if m + 1 < n then F (m + 1) else 0) + G m := by
  simp only [hS, Finset.sum_add_distrib, Finset.sum_ite_eq, Finset.mem_range,
    Nat.add_right_cancel_iff]
  simp [show m < n by omega]

#print axioms fe_sum_two

lemma fe_nodes_aux (T L P : ℝ) (hT : 0 < T) (hL : 0 < L) (n : ℕ) (hn : 0 < n)
    (u u' u'' f : ℝ → ℝ)
    (hu : ∀ x ∈ Icc 0 L, HasDerivWithinAt u (u' x) (Icc 0 L) x)
    (hu' : ∀ x ∈ Icc 0 L, HasDerivWithinAt u' (u'' x) (Icc 0 L) x)
    (hsq : MemLp u'' 2 (volume.restrict (Icc 0 L)))
    (heq : ∀ x ∈ Icc 0 L, -T * u'' x = f x)
    (hbolt : u 0 = 0) (hring : T * u' L = P)
    (U : ℕ → ℝ) (hU0 : U 0 = 0)
    (hKUF : ∀ i, 1 ≤ i → i ≤ n →
      ∑ j ∈ Finset.range (n + 1), stiffness T L n i j * U j = load f P L n i) :
    ∀ i ≤ n, U i = u (i * (L / n)) := by
  have hh : 0 < L / n := by positivity
  have hnR : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  obtain ⟨hint1, -⟩ := fe_integrableOn_u'' hL hsq
  have hload : ∀ i, ∀ k < n,
      IntervalIntegrable (fun x => f x * hat (L / n) i x) volume
        ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)) ∧
      ∫ x in ((k : ℝ) * (L / n))..(((k : ℝ) + 1) * (L / n)), f x * hat (L / n) i x =
        -T * ((if i = k then (u (((k : ℝ) + 1) * (L / n)) - u ((k : ℝ) * (L / n))) / (L / n)
                - u' ((k : ℝ) * (L / n)) else 0) +
              (if i = k + 1 then u' (((k : ℝ) + 1) * (L / n)) -
                (u (((k : ℝ) + 1) * (L / n)) - u ((k : ℝ) * (L / n))) / (L / n) else 0)) := by
    intro i k hk
    obtain ⟨hsub, hcu, hcu', hdu, hdu'⟩ := fe_elem_facts hL hn hu hu' k hk
    have hab : (k : ℝ) * (L / n) < ((k : ℝ) + 1) * (L / n) := by nlinarith
    have hlen : ((k : ℝ) + 1) * (L / n) - (k : ℝ) * (L / n) = L / n := by ring
    have hi : IntegrableOn u'' (Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) :=
      hint1.mono_set hsub
    have hc := fe_congr hab.le (f := fun x => f x * hat (L / n) i x)
      (g := fun x => -T * (u'' x * feHatLin (L / n) i k x))
      (fun x hx => by
        simp only
        rw [← heq x (hsub (Ioo_subset_Icc_self hx)), fe_hat_on_elem hh i k (Ioo_subset_Icc_self hx)]
        ring)
      ((intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2
        ((hi.mul_continuousOn (fe_feHatLin_continuous _ _ _).continuousOn isCompact_Icc).const_mul
          (-T)))
    refine ⟨hc.1, ?_⟩
    rw [hc.2, intervalIntegral.integral_const_mul]
    congr 1
    by_cases h1 : i = k
    · have : (fun x => u'' x * feHatLin (L / n) i k x) =
          fun x => u'' x * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) := by
        funext x; unfold feHatLin; rw [if_pos h1, if_neg (by omega)]; ring
      rw [this, fe_weight_left hab hlen hcu hcu' hdu hdu' hi, if_pos h1, if_neg (by omega)]
      ring
    by_cases h2 : i = k + 1
    · have : (fun x => u'' x * feHatLin (L / n) i k x) =
          fun x => u'' x * ((x - (k : ℝ) * (L / n)) / (L / n)) := by
        funext x; unfold feHatLin; rw [if_neg h1, if_pos h2]; ring
      rw [this, fe_weight_right hab hlen hcu hcu' hdu hdu' hi, if_neg h1, if_pos h2]
      ring
    · have : (fun x => u'' x * feHatLin (L / n) i k x) = fun _ => 0 := by
        funext x; unfold feHatLin; rw [if_neg h1, if_neg h2]; ring
      rw [this, if_neg h1, if_neg h2]
      simp
  obtain ⟨E, hE⟩ : ∃ E : ℕ → ℝ, ∀ k, E k =
      (U (k + 1) - U k) - (u (((k : ℝ) + 1) * (L / n)) - u ((k : ℝ) * (L / n))) := ⟨_, fun _ => rfl⟩
  have hrow : ∀ m, m + 1 ≤ n →
      (if m + 1 < n then -T / (L / n) * (U (m + 1 + 1) - U (m + 1)) else 0) +
        T / (L / n) * (U (m + 1) - U m) =
      (if m + 1 < n then -T * ((u (((((m + 1 : ℕ) : ℝ)) + 1) * (L / n)) -
          u (((m + 1 : ℕ) : ℝ) * (L / n))) / (L / n) - u' (((m + 1 : ℕ) : ℝ) * (L / n))) else 0) +
        -T * (u' (((m : ℝ) + 1) * (L / n)) -
          (u (((m : ℝ) + 1) * (L / n)) - u ((m : ℝ) * (L / n))) / (L / n)) +
        (if m + 1 = n then P else 0) := by
    intro m hm
    have row := hKUF (m + 1) (by omega) hm
    rw [fe_row_sum T L hL n hn U] at row
    unfold load at row
    rw [fe_split hL hn (fun k hk => (hload (m + 1) k hk).1),
      Finset.sum_congr rfl (fun k hk => (hload (m + 1) k (Finset.mem_range.1 hk)).2)] at row
    rw [fe_sum_two n m hm (fun k => -T / (L / n) * (U (k + 1) - U k))
      (fun k => T / (L / n) * (U (k + 1) - U k)) _ (fun k => by
        unfold feSlope; split_ifs <;> ring)] at row
    rw [fe_sum_two n m hm
      (fun k => -T * ((u (((k : ℝ) + 1) * (L / n)) - u ((k : ℝ) * (L / n))) / (L / n)
                - u' ((k : ℝ) * (L / n))))
      (fun k => -T * (u' (((k : ℝ) + 1) * (L / n)) -
                (u (((k : ℝ) + 1) * (L / n)) - u ((k : ℝ) * (L / n))) / (L / n))) _ (fun k => by
        split_ifs <;> ring)] at row
    exact row
  have hTh : T / (L / n) ≠ 0 := (div_pos hT hh).ne'
  have hstep : ∀ m, m + 1 < n → E m = E (m + 1) := by
    intro m hm
    have row := hrow m hm.le
    rw [if_pos hm, if_pos hm, if_neg hm.ne] at row
    have key : T / (L / n) * (E m - E (m + 1)) = 0 := by
      rw [hE, hE]
      push_cast at row ⊢
      linear_combination row
    rcases mul_eq_zero.1 key with h | h
    · exact absurd h hTh
    · linarith
  have hlast : ∀ m, m + 1 = n → E m = 0 := by
    intro m hm
    have row := hrow m hm.le
    rw [if_neg (by omega), if_neg (by omega), if_pos hm] at row
    have hxn : ((m : ℝ) + 1) * (L / n) = L := by
      have : (m : ℝ) + 1 = n := by exact_mod_cast hm
      rw [this]; field_simp
    rw [hxn] at row
    have key : T / (L / n) * E m = 0 := by
      rw [hE, hxn]
      linear_combination row - hring
    rcases mul_eq_zero.1 key with h | h
    · exact absurd h hTh
    · exact h
  have hzero : ∀ d m, m + 1 + d = n → E m = 0 := by
    intro d
    induction d with
    | zero => intro m hm; exact hlast m (by omega)
    | succ d ih => intro m hm; rw [hstep m (by omega)]; exact ih (m + 1) (by omega)
  intro i hi
  induction i with
  | zero => simp [hU0, hbolt]
  | succ k ih =>
    have h0 := hzero (n - (k + 1)) k (by omega)
    rw [hE] at h0
    have := ih (by omega)
    push_cast
    linarith

#print axioms fe_nodes_aux

lemma fe_rms_le {L c I J : ℝ} (hL : 0 < L) (hc : 0 ≤ c) (h : I ≤ c ^ 2 * J) :
    Real.sqrt ((1 / L) * I) ≤ c * Real.sqrt ((1 / L) * J) := by
  rw [← Real.sqrt_sq hc, ← Real.sqrt_mul (sq_nonneg c)]
  apply Real.sqrt_le_sqrt
  calc (1 / L) * I ≤ (1 / L) * (c ^ 2 * J) := mul_le_mul_of_nonneg_left h (by positivity)
    _ = c ^ 2 * ((1 / L) * J) := by ring

#print axioms fe_rms_le

lemma fe_error_aux (T L P : ℝ) (hT : 0 < T) (hL : 0 < L) (n : ℕ) (hn : 0 < n)
    (u u' u'' f : ℝ → ℝ)
    (hu : ∀ x ∈ Icc 0 L, HasDerivWithinAt u (u' x) (Icc 0 L) x)
    (hu' : ∀ x ∈ Icc 0 L, HasDerivWithinAt u' (u'' x) (Icc 0 L) x)
    (hsq : MemLp u'' 2 (volume.restrict (Icc 0 L)))
    (heq : ∀ x ∈ Icc 0 L, -T * u'' x = f x)
    (hbolt : u 0 = 0) (hring : T * u' L = P)
    (U : ℕ → ℝ) (hU0 : U 0 = 0)
    (hKUF : ∀ i, 1 ≤ i → i ≤ n →
      ∑ j ∈ Finset.range (n + 1), stiffness T L n i j * U j = load f P L n i) :
    rms L (fun x => u' x - deriv (feSag L n U) x) ≤ (L / n) / Real.pi * rms L u'' ∧
      rms L (fun x => u x - feSag L n U x) ≤ ((L / n) / Real.pi) ^ 2 * rms L u'' := by
  have hnodes := fe_nodes_aux T L P hT hL n hn u u' u'' f hu hu' hsq heq hbolt hring U hU0 hKUF
  have hh : 0 < L / n := by positivity
  obtain ⟨hint1, hint2⟩ := fe_integrableOn_u'' hL hsq
  have helem : ∀ k < n,
      IntervalIntegrable (fun x => (u' x - deriv (feSag L n U) x) ^ 2) volume
        ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)) ∧
      IntervalIntegrable (fun x => (u x - feSag L n U x) ^ 2) volume
        ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)) ∧
      IntervalIntegrable (fun x => u'' x ^ 2) volume
        ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)) ∧
      ∫ x in ((k : ℝ) * (L / n))..(((k : ℝ) + 1) * (L / n)), (u' x - deriv (feSag L n U) x) ^ 2
        ≤ ((L / n) / Real.pi) ^ 2 *
          ∫ x in ((k : ℝ) * (L / n))..(((k : ℝ) + 1) * (L / n)), u'' x ^ 2 ∧
      ∫ x in ((k : ℝ) * (L / n))..(((k : ℝ) + 1) * (L / n)), (u x - feSag L n U x) ^ 2
        ≤ (((L / n) / Real.pi) ^ 2) ^ 2 *
          ∫ x in ((k : ℝ) * (L / n))..(((k : ℝ) + 1) * (L / n)), u'' x ^ 2 := by
    intro k hk
    obtain ⟨hsub, hcu, hcu', hdu, hdu'⟩ := fe_elem_facts hL hn hu hu' k hk
    have hab : (k : ℝ) * (L / n) < ((k : ℝ) + 1) * (L / n) := by nlinarith
    have hlen : ((k : ℝ) + 1) * (L / n) - (k : ℝ) * (L / n) = L / n := by ring
    have hlin : Continuous (fun x => U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
        U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n))) := by fun_prop
    have he : ContinuousOn (fun x => u x - (U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
        U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n)))) (Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) :=
      hcu.sub hlin.continuousOn
    have he' : ContinuousOn (fun x => u' x - (U (k + 1) - U k) / (L / n))
        (Icc ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n))) := hcu'.sub continuousOn_const
    have hd : ∀ x ∈ Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)),
        HasDerivAt (fun x => u x - (U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
          U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n)))) (u' x - (U (k + 1) - U k) / (L / n)) x := by
      intro x hx
      have := (hdu x hx).sub
        (((((hasDerivAt_id x).const_sub (((k : ℝ) + 1) * (L / n))).div_const (L / n)).const_mul
          (U k)).add ((((hasDerivAt_id x).sub_const ((k : ℝ) * (L / n))).div_const (L / n)).const_mul
          (U (k + 1))))
      exact this.congr_deriv (by ring)
    have hd' : ∀ x ∈ Ioo ((k : ℝ) * (L / n)) (((k : ℝ) + 1) * (L / n)),
        HasDerivAt (fun x => u' x - (U (k + 1) - U k) / (L / n)) (u'' x) x := by
      intro x hx
      simpa using (hdu' x hx).sub_const ((U (k + 1) - U k) / (L / n))
    have hUk := hnodes k hk.le
    have hUk1 := hnodes (k + 1) hk
    push_cast at hUk1
    have hea : (fun x => u x - (U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
        U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n)))) ((k : ℝ) * (L / n)) = 0 := by
      simp only
      rw [hUk, hlen, div_self hh.ne']
      ring
    have heb : (fun x => u x - (U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
        U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n)))) (((k : ℝ) + 1) * (L / n)) = 0 := by
      simp only
      rw [hUk1, hlen, div_self hh.ne']
      ring
    have hw := hint1.mono_set hsub
    have hw2 := hint2.mono_set hsub
    have B := fe_element_bounds hab he he' hd hd' hea heb hw hw2
    rw [hlen] at B
    have c1 := fe_congr hab.le (f := fun x => (u' x - deriv (feSag L n U) x) ^ 2)
      (g := fun x => (u' x - (U (k + 1) - U k) / (L / n)) ^ 2)
      (fun x hx => by
        simp only
        rw [(fe_feSag_hasDerivAt hh k hk U hx).deriv])
      ((intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2
        ((he'.pow 2).integrableOn_compact isCompact_Icc))
    have c2 := fe_congr hab.le (f := fun x => (u x - feSag L n U x) ^ 2)
      (g := fun x => (u x - (U k * ((((k : ℝ) + 1) * (L / n) - x) / (L / n)) +
        U (k + 1) * ((x - (k : ℝ) * (L / n)) / (L / n)))) ^ 2)
      (fun x hx => by
        simp only
        rw [fe_feSag_on_elem hh k hk U (Ioo_subset_Icc_self hx)])
      ((intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2
        ((he.pow 2).integrableOn_compact isCompact_Icc))
    refine ⟨c1.1, c2.1, (intervalIntegrable_iff_integrableOn_Icc_of_le hab.le).2 hw2, ?_, ?_⟩
    · rw [c1.2]; exact B.1
    · rw [c2.2]; exact B.2
  have hI1 : ∫ x in (0 : ℝ)..L, (u' x - deriv (feSag L n U) x) ^ 2 ≤
      ((L / n) / Real.pi) ^ 2 * ∫ x in (0 : ℝ)..L, u'' x ^ 2 := by
    rw [fe_split hL hn (fun k hk => (helem k hk).1), fe_split hL hn (fun k hk => (helem k hk).2.2.1),
      Finset.mul_sum]
    exact Finset.sum_le_sum fun k hk => (helem k (Finset.mem_range.1 hk)).2.2.2.1
  have hI2 : ∫ x in (0 : ℝ)..L, (u x - feSag L n U x) ^ 2 ≤
      (((L / n) / Real.pi) ^ 2) ^ 2 * ∫ x in (0 : ℝ)..L, u'' x ^ 2 := by
    rw [fe_split hL hn (fun k hk => (helem k hk).2.1), fe_split hL hn (fun k hk => (helem k hk).2.2.1),
      Finset.mul_sum]
    exact Finset.sum_le_sum fun k hk => (helem k (Finset.mem_range.1 hk)).2.2.2.2
  unfold rms
  exact ⟨fe_rms_le hL (by positivity) hI1, fe_rms_le hL (by positivity) hI2⟩

#print axioms fe_error_aux

/-- The finite-element error bound on a cable. A cable of length `L > 0` at tension `T > 0`
obeys `-T u'' = f`, is bolted at the wall (`u(0) = 0`, essential) and pulled by `P` at the ring
(`T u'(L) = P`, natural), and its curvature `u''` is square-integrable. Cut it into `n`
elements of length `h = L / n`. Let `U` solve the assembled system with exact integrals: node 0
removed by the bolt (`U_0 = 0`) and `K U = F` in every other row. Then the computed sag
`u_h = Σ U_i φ_i` obeys `RMS(u' - u_h') ≤ (h/π) RMS(u'')` and
`RMS(u - u_h) ≤ (h/π)² RMS(u'')`: the slope error shrinks like `h`, the sag error like `h²`. -/
theorem finite_element_error_bound (T L P : ℝ) (hT : 0 < T) (hL : 0 < L) (n : ℕ) (hn : 0 < n)
    (u u' u'' f : ℝ → ℝ)
    (hu : ∀ x ∈ Icc 0 L, HasDerivWithinAt u (u' x) (Icc 0 L) x)
    (hu' : ∀ x ∈ Icc 0 L, HasDerivWithinAt u' (u'' x) (Icc 0 L) x)
    (hsq : MemLp u'' 2 (volume.restrict (Icc 0 L)))
    (heq : ∀ x ∈ Icc 0 L, -T * u'' x = f x)
    (hbolt : u 0 = 0) (hring : T * u' L = P)
    (U : ℕ → ℝ) (hU0 : U 0 = 0)
    (hKUF : ∀ i, 1 ≤ i → i ≤ n →
      ∑ j ∈ Finset.range (n + 1), stiffness T L n i j * U j = load f P L n i) :
    rms L (fun x => u' x - deriv (feSag L n U) x) ≤ (L / n) / Real.pi * rms L u'' ∧
      rms L (fun x => u x - feSag L n U x) ≤ ((L / n) / Real.pi) ^ 2 * rms L u'' := by
  exact fe_error_aux T L P hT hL n hn u u' u'' f hu hu' hsq heq hbolt hring U hU0 hKUF

/-- On a cable the computed sag is exact at every node: under the same hypotheses,
`U_i = u(x_i) = u(i h)` for every node `i = 0, ..., n`. -/
theorem finite_element_nodes_exact (T L P : ℝ) (hT : 0 < T) (hL : 0 < L) (n : ℕ) (hn : 0 < n)
    (u u' u'' f : ℝ → ℝ)
    (hu : ∀ x ∈ Icc 0 L, HasDerivWithinAt u (u' x) (Icc 0 L) x)
    (hu' : ∀ x ∈ Icc 0 L, HasDerivWithinAt u' (u'' x) (Icc 0 L) x)
    (hsq : MemLp u'' 2 (volume.restrict (Icc 0 L)))
    (heq : ∀ x ∈ Icc 0 L, -T * u'' x = f x)
    (hbolt : u 0 = 0) (hring : T * u' L = P)
    (U : ℕ → ℝ) (hU0 : U 0 = 0)
    (hKUF : ∀ i, 1 ≤ i → i ≤ n →
      ∑ j ∈ Finset.range (n + 1), stiffness T L n i j * U j = load f P L n i) :
    ∀ i ≤ n, U i = u (i * (L / n)) := by
  exact fe_nodes_aux T L P hT hL n hn u u' u'' f hu hu' hsq heq hbolt hring U hU0 hKUF

/-- Assembly is adding: the stiffness matrix `K_ij = ∫₀ᴸ T φ_i' φ_j' dx` equals the sum over
the elements of the element matrix `(T/h) [[1, -1], [-1, 1]]`, each added into the rows and
columns of its own two nodes. -/
theorem stiffness_eq_assembled_element_matrices (T L : ℝ) (hL : 0 < L) (n : ℕ) (hn : 0 < n) :
    ∀ i ≤ n, ∀ j ≤ n,
      stiffness T L n i j = assemble n ((T / (L / n)) • !![1, -1; -1, 1]) i j := by
  intro i _ j _
  exact fe_stiffness_assembled T L hL n hn i j

-- The cable: T = 2000 N, L = 4 m, n = 4, h = 1 m, planters 20 + 10x N/m, ring pull 40 N.
-- Element matrix T/h = 2000; node 1 diagonal 2000 + 2000 = 4000; 13 nonzeros of 25.
example : (2000 : ℚ) / 1 = 2000 ∧ (2000 : ℚ) + 2000 = 4000 ∧ 3 * 5 - 2 = 13 := by norm_num

-- Loads F = 35/3, 30, 40, 50, 205/3 N (11.667 ... 68.333): h (2 f_l + f_r)/6 and h (f_l + 2 f_r)/6.
example : ((2 * 20 + 30) / 6 : ℚ) = 35 / 3 ∧ ((20 + 2 * 30) / 6 + (2 * 30 + 40) / 6 : ℚ) = 30 ∧
    ((30 + 2 * 40) / 6 + (2 * 40 + 50) / 6 : ℚ) = 40 ∧
    ((40 + 2 * 50) / 6 + (2 * 50 + 60) / 6 : ℚ) = 50 ∧
    ((50 + 2 * 60) / 6 + 40 : ℚ) = 205 / 3 := by norm_num

-- The four node sags 565/6000, 1040/6000, 465/2000, 1600/6000 m (94.167, 173.333, 232.500,
-- 266.667 mm) solve rows 1 to 4 of K U = F, and equal the exact sag
-- u(x) = (200x - 10x² - 5x³/3)/2000 at x = 1, 2, 3, 4.
example :
    (4000 : ℚ) * (565 / 6000) - 2000 * (1040 / 6000) = 30 ∧
    -(2000 : ℚ) * (565 / 6000) + 4000 * (1040 / 6000) - 2000 * (465 / 2000) = 40 ∧
    -(2000 : ℚ) * (1040 / 6000) + 4000 * (465 / 2000) - 2000 * (1600 / 6000) = 50 ∧
    -(2000 : ℚ) * (465 / 2000) + 2000 * (1600 / 6000) = 205 / 3 := by norm_num

example :
    ((200 * 1 - 10 * 1 ^ 2 - 5 * 1 ^ 3 / 3) / 2000 : ℚ) = 565 / 6000 ∧
    ((200 * 2 - 10 * 2 ^ 2 - 5 * 2 ^ 3 / 3) / 2000 : ℚ) = 1040 / 6000 ∧
    ((200 * 3 - 10 * 3 ^ 2 - 5 * 3 ^ 3 / 3) / 2000 : ℚ) = 465 / 2000 ∧
    ((200 * 4 - 10 * 4 ^ 2 - 5 * 4 ^ 3 / 3) / 2000 : ℚ) = 1600 / 6000 := by norm_num

-- The ring: T u'(4) = 200 - 20·4 - 5·4² = 40 N, the natural condition.
example : (200 - 20 * 4 - 5 * 4 ^ 2 : ℚ) = 40 := by norm_num

-- Loads carried 565/3, 475/3, 355/3, 205/3 N; each element's drop is load × h / T.
example : (30 + 40 + 50 + 205 / 3 : ℚ) = 565 / 3 ∧ (565 / 3 : ℚ) * 1 / 2000 = 565 / 6000 ∧
    (565 / 6000 : ℚ) + (475 / 3) * 1 / 2000 = 1040 / 6000 ∧
    (465 / 2000 : ℚ) + (205 / 3) * 1 / 2000 = 1600 / 6000 := by norm_num

-- The bolt row returns its force: 2000·0 - 2000 · 565/6000 - 35/3 = -200 N, the whole load
-- (planters 20·4 + 5·4² = 160 N plus the ring's 40 N).
example : (2000 : ℚ) * 0 - 2000 * (565 / 6000) - 35 / 3 = -200 ∧
    (20 * 4 + 5 * 4 ^ 2 + 40 : ℚ) = 200 := by norm_num

-- What breaks: overwriting leaves node 1's diagonal 2000, so the first step gives
-- 2000 - 2000 = 0, a zero pivot; with the ring's 40 N dropped the tip is 560/3 mm (186.667).
example : (2000 : ℚ) - (-2000) / 2000 * (-2000) = 0 := by norm_num
example : (1600 / 6 : ℚ) - 40 * 4 / 2000 * 1000 = 560 / 3 := by norm_num

-- Thomas cost 8n - 7 flops: 25 at n = 4, 8185 at n = 1024.
example : 8 * 4 - 7 = 25 ∧ 8 * 1024 - 7 = 8185 := by decide

#print axioms finite_element_error_bound
#print axioms finite_element_nodes_exact
#print axioms stiffness_eq_assembled_element_matrices
