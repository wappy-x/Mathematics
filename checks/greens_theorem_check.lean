-- Green's theorem: the work a smooth field P dx + Q dy does once anticlockwise round a rectangle equals its curl Q_x − P_y added over the rectangle, the P part of that holds on any region between two graphs, and each straight fence adds one shoelace term to the area integral ½(x dy − y dx).
import Mathlib.MeasureTheory.Integral.CurveIntegral.Basic
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Tactic.NormNum

open Set MeasureTheory

/-- The 1-form `P dx + Q dy` on the plane: at the point `z`, a small step `v` collects
`P z · v.1 + Q z · v.2`. -/
noncomputable def workForm (P Q : ℝ × ℝ → ℝ) (z : ℝ × ℝ) : ℝ × ℝ →L[ℝ] ℝ :=
  P z • ContinuousLinearMap.fst ℝ ℝ ℝ + Q z • ContinuousLinearMap.snd ℝ ℝ ℝ

/-- The fence of the rectangle `[a, b] × [c, d]`, walked once anticlockwise (region on the
left): bottom east, right side north, top west, left side south, back to the start. -/
noncomputable def rectangleLoop (a b c d : ℝ) : Path ((a, c) : ℝ × ℝ) (a, c) :=
  (Path.segment (a, c) (b, c)).trans
    ((Path.segment (b, c) (b, d)).trans
      ((Path.segment (b, d) (a, d)).trans (Path.segment (a, d) (a, c))))

lemma workForm_seg_horiz (P Q : ℝ × ℝ → ℝ) (x0 x1 y t : ℝ) :
    workForm P Q (AffineMap.lineMap ((x0, y) : ℝ × ℝ) (x1, y) t) ((x1, y) - (x0, y)) =
      (x1 - x0) • P (x0 + (x1 - x0) * t, y) := by
  simp [workForm, AffineMap.lineMap_apply_module']
  have e : t * (x1 - x0) + x0 = x0 + (x1 - x0) * t := by ring
  rw [e, mul_comm]

lemma workForm_seg_vert (P Q : ℝ × ℝ → ℝ) (x y0 y1 t : ℝ) :
    workForm P Q (AffineMap.lineMap ((x, y0) : ℝ × ℝ) (x, y1) t) ((x, y1) - (x, y0)) =
      (y1 - y0) • Q (x, y0 + (y1 - y0) * t) := by
  simp [workForm, AffineMap.lineMap_apply_module']
  have e : t * (y1 - y0) + y0 = y0 + (y1 - y0) * t := by ring
  rw [e, mul_comm]

lemma curveIntegral_seg_horiz (P Q : ℝ × ℝ → ℝ) (x0 x1 y : ℝ) :
    (∫ᶜ z in Path.segment ((x0, y) : ℝ × ℝ) (x1, y), workForm P Q z) = ∫ x in x0..x1, P (x, y) := by
  rw [curveIntegral_segment]
  simp_rw [workForm_seg_horiz, intervalIntegral.integral_smul]
  rw [intervalIntegral.smul_integral_comp_add_mul (f := fun x => P (x, y))]
  simp

lemma curveIntegral_seg_vert (P Q : ℝ × ℝ → ℝ) (x y0 y1 : ℝ) :
    (∫ᶜ z in Path.segment ((x, y0) : ℝ × ℝ) (x, y1), workForm P Q z) = ∫ y in y0..y1, Q (x, y) := by
  rw [curveIntegral_segment]
  simp_rw [workForm_seg_vert, intervalIntegral.integral_smul]
  rw [intervalIntegral.smul_integral_comp_add_mul (f := fun y => Q (x, y))]
  simp

lemma mem_uIcc_affine (x0 x1 t : ℝ) (ht : t ∈ uIcc (0:ℝ) 1) : x0 + (x1 - x0) * t ∈ uIcc x0 x1 := by
  rw [uIcc_of_le zero_le_one] at ht
  obtain ⟨h0, h1⟩ := ht
  rcases le_total x0 x1 with h | h
  · rw [uIcc_of_le h]; constructor <;> nlinarith
  · rw [uIcc_of_ge h]; constructor <;> nlinarith

lemma curveIntegrable_seg_horiz {P Q : ℝ × ℝ → ℝ} {x0 x1 y : ℝ}
    (h : ContinuousOn (fun x => P (x, y)) (uIcc x0 x1)) :
    CurveIntegrable (workForm P Q) (Path.segment ((x0, y) : ℝ × ℝ) (x1, y)) := by
  rw [curveIntegrable_segment]
  simp_rw [workForm_seg_horiz]
  apply ContinuousOn.intervalIntegrable
  simp only [smul_eq_mul]
  exact continuousOn_const.mul (h.comp (by fun_prop : Continuous fun t : ℝ => x0 + (x1 - x0) * t).continuousOn
    (fun t ht => mem_uIcc_affine x0 x1 t ht))

lemma curveIntegrable_seg_vert {P Q : ℝ × ℝ → ℝ} {x y0 y1 : ℝ}
    (h : ContinuousOn (fun y => Q (x, y)) (uIcc y0 y1)) :
    CurveIntegrable (workForm P Q) (Path.segment ((x, y0) : ℝ × ℝ) (x, y1)) := by
  rw [curveIntegrable_segment]
  simp_rw [workForm_seg_vert]
  apply ContinuousOn.intervalIntegrable
  simp only [smul_eq_mul]
  exact continuousOn_const.mul (h.comp (by fun_prop : Continuous fun t : ℝ => y0 + (y1 - y0) * t).continuousOn
    (fun t ht => mem_uIcc_affine y0 y1 t ht))

#print axioms workForm_seg_horiz
#print axioms workForm_seg_vert
#print axioms curveIntegral_seg_horiz
#print axioms curveIntegral_seg_vert
#print axioms mem_uIcc_affine
#print axioms curveIntegrable_seg_horiz
#print axioms curveIntegrable_seg_vert

/-- **Green's theorem on a rectangle.** Take a field with east part `P` and north part `Q` on the
rectangle `R = [a, b] × [c, d]`, and suppose both have continuous rates of change everywhere in
the rectangle, fence included (`P'` and `Q'` are their derivatives, continuous on `R`). Walk the
fence once with the region on the left. The work the field does on the walk, `∮ P dx + Q dy`,
equals the curl `Q_x − P_y` added over the rectangle. Here `Q_x = Q' z (1, 0)` is Q's rate per
step east and `P_y = P' z (0, 1)` is P's rate per step north. -/
theorem circulation_round_rectangle_eq_curl_summed_inside
    {P Q : ℝ × ℝ → ℝ} {P' Q' : ℝ × ℝ → ℝ × ℝ →L[ℝ] ℝ} {a b c d : ℝ}
    (hab : a < b) (hcd : c < d)
    (hP : ∀ z ∈ Icc a b ×ˢ Icc c d, HasFDerivWithinAt P (P' z) (Icc a b ×ˢ Icc c d) z)
    (hQ : ∀ z ∈ Icc a b ×ˢ Icc c d, HasFDerivWithinAt Q (Q' z) (Icc a b ×ˢ Icc c d) z)
    (hP' : ContinuousOn P' (Icc a b ×ˢ Icc c d))
    (hQ' : ContinuousOn Q' (Icc a b ×ˢ Icc c d)) :
    (∫ᶜ z in rectangleLoop a b c d, workForm P Q z) =
      ∫ z in Icc a b ×ˢ Icc c d, (Q' z (1, 0) - P' z (0, 1)) := by
  set R := Icc a b ×ˢ Icc c d with hR
  have hPc : ContinuousOn P R := fun z hz => (hP z hz).continuousWithinAt
  have hQc : ContinuousOn Q R := fun z hz => (hQ z hz).continuousWithinAt
  have hrow : ∀ y ∈ Icc c d, ContinuousOn (fun x => P (x, y)) (uIcc a b) ∧
      ContinuousOn (fun x => P (x, y)) (uIcc b a) := by
    intro y hy
    have : ContinuousOn (fun x => P (x, y)) (Icc a b) :=
      hPc.comp (by fun_prop : Continuous fun x : ℝ => (x, y)).continuousOn
        (fun x hx => ⟨hx, hy⟩)
    exact ⟨by rwa [uIcc_of_le hab.le], by rwa [uIcc_of_ge hab.le]⟩
  have hcol : ∀ x ∈ Icc a b, ContinuousOn (fun y => Q (x, y)) (uIcc c d) ∧
      ContinuousOn (fun y => Q (x, y)) (uIcc d c) := by
    intro x hx
    have : ContinuousOn (fun y => Q (x, y)) (Icc c d) :=
      hQc.comp (by fun_prop : Continuous fun y : ℝ => (x, y)).continuousOn
        (fun y hy => ⟨hx, hy⟩)
    exact ⟨by rwa [uIcc_of_le hcd.le], by rwa [uIcc_of_ge hcd.le]⟩
  have ha : a ∈ Icc a b := left_mem_Icc.2 hab.le
  have hb : b ∈ Icc a b := right_mem_Icc.2 hab.le
  have hc : c ∈ Icc c d := left_mem_Icc.2 hcd.le
  have hd : d ∈ Icc c d := right_mem_Icc.2 hcd.le
  have i1 := curveIntegrable_seg_horiz (Q := Q) (hrow c hc).1
  have i2 := curveIntegrable_seg_vert (P := P) (hcol b hb).1
  have i3 := curveIntegrable_seg_horiz (Q := Q) (hrow d hd).2
  have i4 := curveIntegrable_seg_vert (P := P) (hcol a ha).2
  unfold rectangleLoop
  rw [curveIntegral_trans i1 (i2.trans (i3.trans i4)), curveIntegral_trans i2 (i3.trans i4),
    curveIntegral_trans i3 i4, curveIntegral_seg_horiz, curveIntegral_seg_vert,
    curveIntegral_seg_horiz, curveIntegral_seg_vert]
  have hle : ((a, c) : ℝ × ℝ) ≤ (b, d) := ⟨hab.le, hcd.le⟩
  have hIcc : Icc ((a, c) : ℝ × ℝ) (b, d) = R := by rw [Icc_prod_eq]
  have hnhds : ∀ x ∈ Ioo a b ×ˢ Ioo c d, R ∈ nhds x := fun x hx =>
    prod_mem_nhds (Icc_mem_nhds hx.1.1 hx.1.2) (Icc_mem_nhds hx.2.1 hx.2.2)
  have key := integral_divergence_prod_Icc_of_hasFDerivAt_of_le Q (fun z => -P z) Q'
    (fun z => -P' z) (a, c) (b, d) hle (by rwa [hIcc]) (by rw [hIcc]; exact hPc.neg)
    (fun x hx => (hQ x ⟨Ioo_subset_Icc_self hx.1, Ioo_subset_Icc_self hx.2⟩).hasFDerivAt
      (hnhds x hx))
    (fun x hx => ((hP x ⟨Ioo_subset_Icc_self hx.1, Ioo_subset_Icc_self hx.2⟩).hasFDerivAt
      (hnhds x hx)).neg)
    (by
      rw [hIcc]
      refine ContinuousOn.integrableOn_compact (isCompact_Icc.prod isCompact_Icc) ?_
      exact (hQ'.clm_apply continuousOn_const).add (hP'.neg.clm_apply continuousOn_const))
  simp only [hIcc, neg_apply, ← sub_eq_add_neg,
    intervalIntegral.integral_neg] at key
  rw [key, intervalIntegral.integral_symm a b, intervalIntegral.integral_symm c d]
  ring

/-- **The P part on a region between two graphs.** Let the region be the points `(x, y)` with
`a ≤ x ≤ b` and `g(x) ≤ y ≤ h(x)`, where the floor `g` and the roof `h` are continuous and the
floor is never above the roof. Suppose `P` is continuous on the region and has a continuous
northward rate `P_y` there, fence included. Walking the fence with the region on the left, the
vertical sides add nothing to `∮ P dx`; the floor, walked east, and the roof, walked west, give
`∫ P(x, g x) dx − ∫ P(x, h x) dx`. That equals minus `P_y` added over the region. -/
theorem p_part_between_two_graphs_eq_minus_py_summed
    {P Py : ℝ × ℝ → ℝ} {g h : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hg : ContinuousOn g (Icc a b)) (hh : ContinuousOn h (Icc a b))
    (hgh : ∀ x ∈ Icc a b, g x ≤ h x)
    (hP : ContinuousOn P {z | z.1 ∈ Icc a b ∧ z.2 ∈ Icc (g z.1) (h z.1)})
    (hPy : ∀ x ∈ Icc a b, ∀ y ∈ Icc (g x) (h x),
      HasDerivWithinAt (fun t => P (x, t)) (Py (x, y)) (Icc (g x) (h x)) y)
    (hPyc : ContinuousOn Py {z | z.1 ∈ Icc a b ∧ z.2 ∈ Icc (g z.1) (h z.1)}) :
    (∫ x in a..b, P (x, g x)) - (∫ x in a..b, P (x, h x)) =
      -∫ x in a..b, ∫ y in g x..h x, Py (x, y) := by
  have hin : ∀ x ∈ Icc a b, ∫ y in g x..h x, Py (x, y) = P (x, h x) - P (x, g x) := by
    intro x hx
    apply intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le (f := fun t => P (x, t))
      (f' := fun t => Py (x, t)) (hgh x hx)
    · exact hP.comp (by fun_prop : Continuous fun t : ℝ => (x, t)).continuousOn
        (fun t ht => ⟨hx, ht⟩)
    · intro y hy
      exact ((hPy x hx y (Ioo_subset_Icc_self hy)).hasDerivAt
        (Icc_mem_nhds hy.1 hy.2)).hasDerivWithinAt
    · apply ContinuousOn.intervalIntegrable
      rw [uIcc_of_le (hgh x hx)]
      exact hPyc.comp (by fun_prop : Continuous fun t : ℝ => (x, t)).continuousOn
        (fun t ht => ⟨hx, ht⟩)
  have hcg : ContinuousOn (fun x => P (x, g x)) (Icc a b) :=
    hP.comp ((continuousOn_id).prodMk hg) (fun x hx => ⟨hx, le_rfl, hgh x hx⟩)
  have hch : ContinuousOn (fun x => P (x, h x)) (Icc a b) :=
    hP.comp ((continuousOn_id).prodMk hh) (fun x hx => ⟨hx, hgh x hx, le_rfl⟩)
  have e : (∫ x in a..b, ∫ y in g x..h x, Py (x, y)) = ∫ x in a..b, (P (x, h x) - P (x, g x)) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [uIcc_of_le hab] at hx
    exact hin x hx
  rw [e, intervalIntegral.integral_sub (hch.intervalIntegrable_of_Icc hab)
    (hcg.intervalIntegrable_of_Icc hab)]
  ring

/-- **One fence, one shoelace term.** The field `(−y/2, x/2)` has curl 1, so its work round a
loop measures area. Along one straight fence from post `p` to post `q`, its work
`½ ∫ x dy − y dx` is exactly `½ (x_p y_q − x_q y_p)`: the terms that carry the clock cancel. -/
theorem area_form_along_fence_eq_shoelace_term (p q : ℝ × ℝ) :
    (∫ᶜ z in Path.segment p q, workForm (fun w => -w.2 / 2) (fun w => w.1 / 2) z) =
      (p.1 * q.2 - q.1 * p.2) / 2 := by
  rw [curveIntegral_segment]
  have : ∀ t : ℝ, workForm (fun w => -w.2 / 2) (fun w => w.1 / 2) (AffineMap.lineMap p q t) (q - p)
      = (p.1 * q.2 - q.1 * p.2) / 2 := by
    intro t
    simp [workForm, AffineMap.lineMap_apply_module']
    ring
  simp_rw [this]
  simp

/-! ### The card's worked numbers -/

-- The house's posts (0,0), (6,0), (6,4), (3,6), (0,4): shoelace terms 0, 24, 24, 12, 0.
example : ((0:ℚ) * 0 - 6 * 0, (6:ℚ) * 4 - 6 * 0, (6:ℚ) * 6 - 3 * 4, (3:ℚ) * 4 - 0 * 6,
    (0:ℚ) * 0 - 0 * 4) = (0, 24, 24, 12, 0) := by norm_num

-- Half of 0 + 24 + 24 + 12 + 0 is 30 square metres.
example : ((0:ℚ) + 24 + 24 + 12 + 0) / 2 = 30 := by norm_num

-- The rectangle 24 square metres plus the roof triangle 6 square metres (base 6, height 2).
example : (6:ℚ) * 4 + 6 * 2 / 2 = 30 := by norm_num

-- Walked clockwise, every term flips: −30. With the half dropped: 60.
example : -(((0:ℚ) + 24 + 24 + 12 + 0) / 2) = -30 ∧ (0:ℚ) + 24 + 24 + 12 + 0 = 60 := by norm_num

-- Wind (−y²/20, x²/20) on the 6 m by 4 m rectangle: right fence 36/20 N over 4 m is 7.2 J,
-- top fence −0.8 N walked 6 m west is 4.8 J, total 12 J.
example : (36:ℚ) / 20 * 4 = 36 / 5 ∧ -(-(16:ℚ) / 20) * 6 = 24 / 5 ∧
    (36:ℚ) / 5 + 24 / 5 = 12 := by norm_num

-- Wind round the house: 7.2 + 5.9 + 3.5 = 16.6 J, with the roof terms (76 + 42)/20 and (76 − 6)/20.
example : (76 + 42 : ℚ) / 20 = 59 / 10 ∧ (76 - 6 : ℚ) / 20 = 7 / 2 ∧
    (36:ℚ) / 5 + 59 / 10 + 7 / 2 = 83 / 5 := by norm_num

-- Inside the house: x summed 30 × 3 = 90, y summed 24 × 2 + 6 × 14/3 = 76,
-- curl (x + y)/10 summed (90 + 76)/10 = 16.6 J, the same as the walk.
example : (30:ℚ) * 3 = 90 ∧ (24:ℚ) * 2 + 6 * (14 / 3) = 76 ∧ ((90:ℚ) + 76) / 10 = 83 / 5 := by
  norm_num

-- The shared fence y = 4 cancels: rectangle 12 J plus triangle 4.6 J is 16.6 J.
example : (12:ℚ) + 23 / 5 = 83 / 5 ∧ (24:ℚ) / 5 + -(24 / 5) = 0 := by norm_num

#print axioms circulation_round_rectangle_eq_curl_summed_inside
#print axioms p_part_between_two_graphs_eq_minus_py_summed
#print axioms area_form_along_fence_eq_shoelace_term
