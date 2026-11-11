-- Divergence and curl: for a flat wind with continuous rates, the outflow and the anticlockwise circulation round a small square, divided by its area, tend to dP/dx + dQ/dy and dQ/dx - dP/dy as the square shrinks, and the card's wind gives exactly the card's numbers at S and E.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Order.Filter.Basic
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Filter Topology

/-! A flat wind is two functions on the plane `ℝ × ℝ`: its east part `P` and its north part `Q`,
at the point `(x, y)`, x east and y north. A partial derivative is the rate along one axis with the
other coordinate held still: `∂P/∂x` at `p` is `deriv (fun x => P (x, p.2)) p.1`.

The square of side `ℓ` is centred on the spot `p = (a, b)`, with edges parallel to the axes. -/

/-- Outflow across the edges of the square of side `ℓ` centred on `p`: the east part through the
east edge minus the west edge, plus the north part through the north edge minus the south edge. -/
noncomputable def squareOutflow (P Q : ℝ × ℝ → ℝ) (p : ℝ × ℝ) (ℓ : ℝ) : ℝ :=
  (∫ v in -(ℓ / 2)..ℓ / 2, (P (p.1 + ℓ / 2, p.2 + v) - P (p.1 - ℓ / 2, p.2 + v))) +
  (∫ u in -(ℓ / 2)..ℓ / 2, (Q (p.1 + u, p.2 + ℓ / 2) - Q (p.1 + u, p.2 - ℓ / 2)))

/-- Circulation round the square of side `ℓ` centred on `p`, walked anticlockwise: the south edge
walked east collects `P`, the east edge walked north collects `Q`, the north edge walked west gives
`P` back, and the west edge walked south gives `Q` back. -/
noncomputable def squareCirculation (P Q : ℝ × ℝ → ℝ) (p : ℝ × ℝ) (ℓ : ℝ) : ℝ :=
  (∫ u in -(ℓ / 2)..ℓ / 2, (P (p.1 + u, p.2 - ℓ / 2) - P (p.1 + u, p.2 + ℓ / 2))) +
  (∫ v in -(ℓ / 2)..ℓ / 2, (Q (p.1 + ℓ / 2, p.2 + v) - Q (p.1 - ℓ / 2, p.2 + v)))

/-- Helper: the east-minus-west edge difference of `F`, integrated along the edge and divided by
the area, tends to the x-rate of `F` as the square shrinks. -/
theorem edge_limit (F : ℝ × ℝ → ℝ) (p : ℝ × ℝ) (hF : ContDiffAt ℝ 1 F p) :
    Tendsto (fun ℓ => (∫ v in -(ℓ / 2)..ℓ / 2,
        (F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v))) / ℓ ^ 2) (𝓝[>] 0)
      (𝓝 (deriv (fun x => F (x, p.2)) p.1)) := by
  set L := fderiv ℝ F p with hL
  have hD : deriv (fun x => F (x, p.2)) p.1 = L ((1 : ℝ), (0 : ℝ)) := by
    have h1 : HasDerivAt (fun x : ℝ => (x, p.2)) ((1 : ℝ), (0 : ℝ)) p.1 :=
      (hasDerivAt_id p.1).prodMk (hasDerivAt_const p.1 p.2)
    have h2 : HasFDerivAt F L (p.1, p.2) := (hF.differentiableAt one_ne_zero).hasFDerivAt
    exact (h2.comp_hasDerivAt p.1 h1).deriv
  rw [hD]
  set D := L ((1 : ℝ), (0 : ℝ)) with hDdef
  have hS := (hF.hasStrictFDerivAt one_ne_zero).isLittleO
  have hC := hF.eventually (by simp)
  rw [Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  obtain ⟨δ1, hδ1, h1⟩ := Metric.eventually_nhds_iff.1 (hS.def (half_pos hε))
  obtain ⟨δ2, hδ2, h2⟩ := Metric.eventually_nhds_iff.1 hC
  refine ⟨min δ1 δ2, lt_min hδ1 hδ2, fun ℓ hℓ hℓd => ?_⟩
  have hl0 : 0 < ℓ := hℓ
  rw [Real.dist_eq, sub_zero, abs_of_pos hl0, lt_min_iff] at hℓd
  obtain ⟨hlt1, hlt2⟩ := hℓd
  have hnear : ∀ v : ℝ, |v| ≤ ℓ / 2 → ∀ s : ℝ, |s| ≤ ℓ / 2 →
      dist (p.1 + s, p.2 + v) p < ℓ := by
    intro v hv s hs
    rw [Prod.dist_eq, max_lt_iff, Real.dist_eq, Real.dist_eq]
    constructor
    · rw [show p.1 + s - p.1 = s by ring]; linarith
    · rw [show p.2 + v - p.2 = v by ring]; linarith
  have hpt : ∀ v : ℝ, |v| ≤ ℓ / 2 →
      ‖F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v) - ℓ * D‖ ≤ ε / 2 * ℓ := by
    intro v hv
    have hd : dist ((p.1 + ℓ / 2, p.2 + v), (p.1 - ℓ / 2, p.2 + v)) (p, p) < δ1 := by
      rw [Prod.dist_eq, max_lt_iff]
      have hh : |ℓ / 2| ≤ ℓ / 2 := by rw [abs_of_pos (by linarith)]
      have hh' : |-(ℓ / 2)| ≤ ℓ / 2 := by rw [abs_neg]; exact hh
      refine ⟨(hnear v hv _ hh).trans hlt1, ?_⟩
      have := hnear v hv _ hh'
      rw [← sub_eq_add_neg] at this
      exact this.trans hlt1
    have := h1 hd
    have hdiff : ((p.1 + ℓ / 2, p.2 + v) - (p.1 - ℓ / 2, p.2 + v) : ℝ × ℝ) = ℓ • ((1 : ℝ), (0 : ℝ)) := by
      ext <;> simp
    simp only at this
    rw [hdiff, map_smul, smul_eq_mul, norm_smul] at this
    have hn : ‖((1 : ℝ), (0 : ℝ))‖ = 1 := by simp
    rw [hn, mul_one, Real.norm_of_nonneg hl0.le] at this
    exact this
  have hcont : ∀ s : ℝ, |s| ≤ ℓ / 2 →
      ContinuousOn (fun v => F (p.1 + s, p.2 + v)) (Set.uIcc (-(ℓ / 2)) (ℓ / 2)) := by
    intro s hs v hv
    rw [Set.uIcc_of_le (by linarith)] at hv
    have hv' : |v| ≤ ℓ / 2 := abs_le.2 ⟨hv.1, hv.2⟩
    have hca : ContinuousAt F (p.1 + s, p.2 + v) :=
      (h2 ((hnear v hv' s hs).trans hlt2)).continuousAt
    exact (ContinuousAt.comp (g := F) (f := fun v => (p.1 + s, p.2 + v)) hca
      (by fun_prop)).continuousWithinAt
  have hh : |ℓ / 2| ≤ ℓ / 2 := by rw [abs_of_pos (by linarith)]
  have hh' : |-(ℓ / 2)| ≤ ℓ / 2 := by rw [abs_neg]; exact hh
  have hint : IntervalIntegrable (fun v => F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v))
      MeasureTheory.volume (-(ℓ / 2)) (ℓ / 2) := by
    have c1 := hcont _ hh
    have c2 := hcont _ hh'
    simp only [← sub_eq_add_neg] at c2
    exact (c1.sub c2).intervalIntegrable
  have hsplit : (∫ v in -(ℓ / 2)..ℓ / 2, (F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v))) =
      (∫ v in -(ℓ / 2)..ℓ / 2, (F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v) - ℓ * D))
        + ℓ ^ 2 * D := by
    rw [intervalIntegral.integral_sub hint intervalIntegrable_const, intervalIntegral.integral_const]
    simp only [smul_eq_mul]
    ring
  have hbound : ‖∫ v in -(ℓ / 2)..ℓ / 2,
      (F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v) - ℓ * D)‖ ≤
      ε / 2 * ℓ * |ℓ / 2 - -(ℓ / 2)| := by
    apply intervalIntegral.norm_integral_le_of_norm_le_const
    intro v hv
    rw [Set.uIoc_of_le (by linarith)] at hv
    exact hpt v (abs_le.2 ⟨hv.1.le, hv.2⟩)
  rw [show ℓ / 2 - -(ℓ / 2) = ℓ by ring, abs_of_pos hl0, Real.norm_eq_abs] at hbound
  rw [hsplit, Real.dist_eq]
  set I := ∫ v in -(ℓ / 2)..ℓ / 2,
      (F (p.1 + ℓ / 2, p.2 + v) - F (p.1 - ℓ / 2, p.2 + v) - ℓ * D)
  have hl2 : 0 < ℓ ^ 2 := by positivity
  rw [show (I + ℓ ^ 2 * D) / ℓ ^ 2 - D = I / ℓ ^ 2 by field_simp; ring, abs_div,
    abs_of_pos hl2, div_lt_iff₀ hl2]
  nlinarith

#print axioms edge_limit

/-- Helper: the north-minus-south version, by swapping the two coordinates. -/
theorem edge_limit_y (F : ℝ × ℝ → ℝ) (p : ℝ × ℝ) (hF : ContDiffAt ℝ 1 F p) :
    Tendsto (fun ℓ => (∫ u in -(ℓ / 2)..ℓ / 2,
        (F (p.1 + u, p.2 + ℓ / 2) - F (p.1 + u, p.2 - ℓ / 2))) / ℓ ^ 2) (𝓝[>] 0)
      (𝓝 (deriv (fun y => F (p.1, y)) p.2)) := by
  have hG : ContDiffAt ℝ 1 (fun q : ℝ × ℝ => F (q.2, q.1)) (p.2, p.1) :=
    hF.comp (p.2, p.1) (by fun_prop : ContDiff ℝ 1 (fun q : ℝ × ℝ => (q.2, q.1))).contDiffAt
  exact edge_limit _ _ hG

#print axioms edge_limit_y

/-- Helper: an affine function integrated over a symmetric interval. -/
theorem integral_affine_sym (α β r : ℝ) : ∫ u in -r..r, (α + β * u) = 2 * r * α := by
  rw [intervalIntegral.integral_add intervalIntegrable_const
      ((by fun_prop : Continuous fun u : ℝ => β * u).intervalIntegrable _ _),
    intervalIntegral.integral_const, intervalIntegral.integral_const_mul, integral_id]
  simp only [smul_eq_mul]
  ring

#print axioms integral_affine_sym

/-- Divergence and curl as limits. Take a flat wind with east part P and north part Q whose rates
are continuous near the spot p (both parts continuously differentiable near p). Then, as the square
of side ℓ round p shrinks, the outflow across its edges divided by its area ℓ² tends to the
divergence ∂P/∂x + ∂Q/∂y, and the anticlockwise circulation round it divided by ℓ² tends to the
curl ∂Q/∂x − ∂P/∂y. -/
theorem square_outflow_and_circulation_per_area_tend_to_div_and_curl
    (P Q : ℝ × ℝ → ℝ) (p : ℝ × ℝ)
    (hP : ContDiffAt ℝ 1 P p) (hQ : ContDiffAt ℝ 1 Q p) :
    Tendsto (fun ℓ => squareOutflow P Q p ℓ / ℓ ^ 2) (𝓝[>] 0)
        (𝓝 (deriv (fun x => P (x, p.2)) p.1 + deriv (fun y => Q (p.1, y)) p.2)) ∧
      Tendsto (fun ℓ => squareCirculation P Q p ℓ / ℓ ^ 2) (𝓝[>] 0)
        (𝓝 (deriv (fun x => Q (x, p.2)) p.1 - deriv (fun y => P (p.1, y)) p.2)) := by
  constructor
  · refine (( edge_limit P p hP).add (edge_limit_y Q p hQ)).congr fun ℓ => ?_
    simp only [squareOutflow, add_div]
  · refine ((edge_limit Q p hQ).sub (edge_limit_y P p hP)).congr fun ℓ => ?_
    have hneg : (∫ u in -(ℓ / 2)..ℓ / 2, (P (p.1 + u, p.2 - ℓ / 2) - P (p.1 + u, p.2 + ℓ / 2))) =
        -∫ u in -(ℓ / 2)..ℓ / 2, (P (p.1 + u, p.2 + ℓ / 2) - P (p.1 + u, p.2 - ℓ / 2)) := by
      rw [← intervalIntegral.integral_neg]
      congr 1
      funext u
      ring
    simp only [squareCirculation, hneg]
    ring

/-- The card's wind, in m/s: east part P = 3 + 0.0003 (x² − y²) + x³/400000, north part
Q = 0.0006 x y. -/
noncomputable def windP (q : ℝ × ℝ) : ℝ := 3 + 3 / 10000 * (q.1 ^ 2 - q.2 ^ 2) + q.1 ^ 3 / 400000
noncomputable def windQ (q : ℝ × ℝ) : ℝ := 6 / 10000 * q.1 * q.2

/-- The card's wind by its partial derivatives. At S = (40, 0) the rates are ∂P/∂x = 0.036 and
∂Q/∂y = 0.024, so the divergence is 0.06 per second, and the cross rates are both 0, so the curl is
0. At E = (0, 50) the own-direction rates are both 0, so the divergence is 0, and the cross rates
are ∂Q/∂x = 0.030 and ∂P/∂y = −0.030, so the curl is 0.06 per second. -/
theorem card_wind_div_and_curl_at_S_and_E :
    deriv (fun x => windP (x, 0)) 40 = 36 / 1000 ∧
      deriv (fun y => windQ (40, y)) 0 = 24 / 1000 ∧
      deriv (fun x => windQ (x, 0)) 40 = 0 ∧
      deriv (fun y => windP (40, y)) 0 = 0 ∧
      deriv (fun x => windP (x, 50)) 0 = 0 ∧
      deriv (fun y => windQ (0, y)) 50 = 0 ∧
      deriv (fun x => windQ (x, 50)) 0 = 30 / 1000 ∧
      deriv (fun y => windP (0, y)) 50 = -(30 / 1000) := by
  have ha : deriv (fun x => windP (x, 0)) 40 = 36 / 1000 := by
    have h := ((((hasDerivAt_pow 2 (40 : ℝ)).sub_const ((0 : ℝ) ^ 2)).const_mul
      (3 / 10000)).const_add 3).add ((hasDerivAt_pow 3 (40 : ℝ)).div_const 400000)
    refine h.deriv.trans ?_
    norm_num
  have hb : deriv (fun x => windP (x, 50)) 0 = 0 := by
    have h := ((((hasDerivAt_pow 2 (0 : ℝ)).sub_const ((50 : ℝ) ^ 2)).const_mul
      (3 / 10000)).const_add 3).add ((hasDerivAt_pow 3 (0 : ℝ)).div_const 400000)
    refine h.deriv.trans ?_
    norm_num
  rw [ha, hb]
  simp [windP, windQ]
  norm_num

/-- The card's squares, with no derivatives. For every side ℓ > 0, the outflow round S per unit
area is 0.06 + ℓ²/1600000 (the gap from the x³ term falls four-fold as the side halves), and the
circulation round E per unit area is exactly 0.06 at every side. -/
theorem card_wind_square_ratios (ℓ : ℝ) (hℓ : 0 < ℓ) :
    squareOutflow windP windQ (40, 0) ℓ / ℓ ^ 2 = 6 / 100 + ℓ ^ 2 / 1600000 ∧
      squareCirculation windP windQ (0, 50) ℓ / ℓ ^ 2 = 6 / 100 := by
  constructor
  · have e1 : (∫ v in -(ℓ / 2)..ℓ / 2,
        (windP ((40, 0).1 + ℓ / 2, (40, 0).2 + v) - windP ((40, 0).1 - ℓ / 2, (40, 0).2 + v))) =
        ∫ v in -(ℓ / 2)..ℓ / 2, ((3 / 10000 * ((40 + ℓ / 2) ^ 2 - (40 - ℓ / 2) ^ 2)
          + ((40 + ℓ / 2) ^ 3 - (40 - ℓ / 2) ^ 3) / 400000) + 0 * v) :=
      intervalIntegral.integral_congr (fun v _ => by simp only [windP]; ring)
    have e2 : (∫ u in -(ℓ / 2)..ℓ / 2,
        (windQ ((40, 0).1 + u, (40, 0).2 + ℓ / 2) - windQ ((40, 0).1 + u, (40, 0).2 - ℓ / 2))) =
        ∫ u in -(ℓ / 2)..ℓ / 2, (6 / 10000 * 40 * ℓ + 6 / 10000 * ℓ * u) :=
      intervalIntegral.integral_congr (fun u _ => by simp only [windQ]; ring)
    rw [squareOutflow, e1, e2, integral_affine_sym, integral_affine_sym]
    field_simp
    ring
  · have e1 : (∫ u in -(ℓ / 2)..ℓ / 2,
        (windP ((0, 50).1 + u, (0, 50).2 - ℓ / 2) - windP ((0, 50).1 + u, (0, 50).2 + ℓ / 2))) =
        ∫ u in -(ℓ / 2)..ℓ / 2, (3 / 10000 * ((50 + ℓ / 2) ^ 2 - (50 - ℓ / 2) ^ 2) + 0 * u) :=
      intervalIntegral.integral_congr (fun u _ => by simp only [windP]; ring)
    have e2 : (∫ v in -(ℓ / 2)..ℓ / 2,
        (windQ ((0, 50).1 + ℓ / 2, (0, 50).2 + v) - windQ ((0, 50).1 - ℓ / 2, (0, 50).2 + v))) =
        ∫ v in -(ℓ / 2)..ℓ / 2, (6 / 10000 * ℓ * 50 + 6 / 10000 * ℓ * v) :=
      intervalIntegral.integral_congr (fun v _ => by simp only [windQ]; ring)
    rw [squareCirculation, e1, e2, integral_affine_sym, integral_affine_sym]
    field_simp
    ring

-- Worked numbers by hand, in exact fractions (0.0003 = 3/10000, 0.0006 = 6/10000).
-- Wind at S: 3 + 0.0003 × 40² + 40³/400000 = 3.640 m/s east.
example : (3 : ℚ) + 3 / 10000 * 40 ^ 2 + 40 ^ 3 / 400000 = 3640 / 1000 := by norm_num
-- Own-direction rates at S: 0.0006 × 40 + 3 × 40²/400000 = 0.036 and 0.0006 × 40 = 0.024; sum 0.06.
example : (6 : ℚ) / 10000 * 40 + 3 * 40 ^ 2 / 400000 = 36 / 1000 := by norm_num
example : (6 : ℚ) / 10000 * 40 = 24 / 1000 := by norm_num
example : (36 : ℚ) / 1000 + 24 / 1000 = 6 / 100 := by norm_num
-- Wind at E: 3 − 0.0003 × 50² = 2.250 m/s east.
example : (3 : ℚ) - 3 / 10000 * 50 ^ 2 = 2250 / 1000 := by norm_num
-- Cross rates at E: 0.0006 × 50 = 0.030 and −0.030; curl 0.030 − (−0.030) = 0.06; spin half that, 0.03.
example : (6 : ℚ) / 10000 * 50 = 30 / 1000 := by norm_num
example : (30 : ℚ) / 1000 - (-(30 / 1000)) = 6 / 100 := by norm_num
example : ((6 : ℚ) / 100) / 2 = 3 / 100 := by norm_num
-- Square ratios at S for sides 40, 20, 10, 5 m: 0.061, 0.06025, 0.0600625, 0.060015625.
example : (6 : ℚ) / 100 + 40 ^ 2 / 1600000 = 61 / 1000 := by norm_num
example : (6 : ℚ) / 100 + 20 ^ 2 / 1600000 = 6025 / 100000 := by norm_num
example : (6 : ℚ) / 100 + 10 ^ 2 / 1600000 = 600625 / 10000000 := by norm_num
example : (6 : ℚ) / 100 + 5 ^ 2 / 1600000 = 60015625 / 1000000000 := by norm_num
-- Mistakes: cross rates added at E give 0, not 0.06; order swapped gives −0.06.
example : (30 : ℚ) / 1000 + (-(30 / 1000)) = 0 := by norm_num
example : (-(30 : ℚ) / 1000) - 30 / 1000 = -(6 / 100) := by norm_num
-- Line-integrals cross-check: curl −0.1 N/m times the 40 m by 30 m field is −120 J.
example : (-(1 : ℚ) / 10) * 40 * 30 = -120 := by norm_num

#print axioms square_outflow_and_circulation_per_area_tend_to_div_and_curl
#print axioms card_wind_div_and_curl_at_S_and_E
#print axioms card_wind_square_ratios
