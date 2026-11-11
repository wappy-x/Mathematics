-- Circles: in the flat plane a disc of radius r has area pi times r squared, one full turn round a circle of diameter d is pi times d long, and pi lies between Archimedes' 3 10/71 and 3 1/7.
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Tactic.NormNum

open Real MeasureTheory Metric

lemma circle_chord_sq (s t : ℝ) :
    (cos s - cos t) ^ 2 + (sin s - sin t) ^ 2 = (2 * sin ((s - t) / 2)) ^ 2 := by
  have hs : s = (s + t) / 2 + (s - t) / 2 := by ring
  have ht : t = (s + t) / 2 - (s - t) / 2 := by ring
  set a := (s + t) / 2
  set b := (s - t) / 2
  rw [hs, ht]
  simp only [cos_add, cos_sub, sin_add, sin_sub]
  linear_combination (4 * sin b ^ 2) * sin_sq_add_cos_sq a

lemma circle_dist (x : EuclideanSpace ℝ (Fin 2)) (r s t : ℝ) (hr : 0 ≤ r) :
    dist (x + r • !₂[cos s, sin s]) (x + r • !₂[cos t, sin t]) = 2 * r * |sin ((s - t) / 2)| := by
  rw [EuclideanSpace.dist_eq]
  simp [Fin.sum_univ_two, Real.dist_eq, sq_abs]
  rw [show (r * cos s - r * cos t) ^ 2 + (r * sin s - r * sin t) ^ 2
      = (2 * r * sin ((s - t) / 2)) ^ 2 by linear_combination r ^ 2 * circle_chord_sq s t,
    sqrt_sq_eq_abs, abs_mul, abs_mul, abs_of_nonneg hr, abs_two]

lemma circle_lower (n : ℕ) (hn : 1 ≤ n) (r : ℝ) (hr : 0 ≤ r) :
    π * (2 * r) - (r * π ^ 3 / 3) / n ≤ 2 * r * sin (π / n) * n := by
  have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hn0 : (0 : ℝ) < n := by linarith
  have hy := sin_gt_sub_cube (div_pos pi_pos hn0)
  have hA : π - π ^ 3 / (6 * n ^ 2) ≤ n * sin (π / n) := by
    have := mul_le_mul_of_nonneg_left hy.le hn0.le
    have e : (n : ℝ) * (π / n - (π / n) ^ 3 / 6) = π - π ^ 3 / (6 * n ^ 2) := by
      field_simp
    linarith
  have hB : π ^ 3 / (6 * n ^ 2) ≤ π ^ 3 / (6 * n) := by
    apply div_le_div_of_nonneg_left (by positivity) (by positivity)
    nlinarith
  have e : (r * π ^ 3 / 3) / n = 2 * r * (π ^ 3 / (6 * n)) := by field_simp; ring
  have := mul_le_mul_of_nonneg_left (hB.trans' (le_refl _)) (by positivity : 0 ≤ 2 * r)
  have := mul_le_mul_of_nonneg_left hA (by positivity : 0 ≤ 2 * r)
  nlinarith

/-- Area is pi r squared. In the flat plane, the disc of every radius r round every centre x
(all points at distance r or less from x) has area pi times r times r. -/
theorem disc_area_eq_pi_mul_radius_sq (x : EuclideanSpace ℝ (Fin 2)) (r : ℝ) (hr : 0 ≤ r) :
    volume (closedBall x r) = ENNReal.ofReal (π * r ^ 2) := by
  rw [EuclideanSpace.volume_closedBall_fin_two, ENNReal.ofReal_mul pi_pos.le, ENNReal.ofReal_pow hr, mul_comm]

/-- Circumference is pi times the diameter. Walk once round the circle of radius r about x in the
flat plane, and measure the walk the card's way: the most that any path of straight hops between
points met in order can add up to. That length is pi times the diameter 2r, for every circle. -/
theorem circumference_eq_pi_mul_diameter (x : EuclideanSpace ℝ (Fin 2)) (r : ℝ) (hr : 0 ≤ r) :
    eVariationOn (fun t : ℝ => x + r • !₂[Real.cos t, Real.sin t]) (Set.Icc 0 (2 * π)) =
      ENNReal.ofReal (π * (2 * r)) := by
  set γ := fun t : ℝ => x + r • !₂[Real.cos t, Real.sin t] with hγ
  apply le_antisymm
  · have hL : LipschitzWith r.toNNReal γ := LipschitzWith.of_dist_le_mul fun s t => by
      rw [hγ, circle_dist x r s t hr, Real.dist_eq, Real.coe_toNNReal r hr]
      have h1 := abs_sin_le_abs (x := (s - t) / 2)
      rw [abs_div, abs_two] at h1
      nlinarith
    have h := (hL.lipschitzOnWith (s := Set.univ)).comp_eVariationOn_le (g := id)
      (s := Set.Icc 0 (2 * π)) (Set.mapsTo_univ _ _)
    rw [Function.comp_id, eVariationOn_id_Icc] at h
    refine h.trans (le_of_eq ?_)
    rw [sub_zero]
    show ENNReal.ofReal r * _ = _
    rw [← ENNReal.ofReal_mul hr]
    ring_nf
  · have key : ∀ n : ℕ, 1 ≤ n →
        ENNReal.ofReal (2 * r * sin (π / n) * n) ≤ eVariationOn γ (Set.Icc 0 (2 * π)) := by
      intro n hn
      have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
      let u : ℕ → ℝ := fun i => 2 * π * (min i n : ℕ) / n
      have hu : Monotone u := by
        intro i j hij
        have : ((min i n : ℕ) : ℝ) ≤ (min j n : ℕ) := by exact_mod_cast min_le_min_right n hij
        have := pi_pos
        simp only [u]
        gcongr
      have us : ∀ i, u i ∈ Set.Icc 0 (2 * π) := by
        intro i
        have h1 : ((min i n : ℕ) : ℝ) ≤ n := by exact_mod_cast min_le_right i n
        have := pi_pos
        constructor
        · simp only [u]; positivity
        · simp only [u]
          rw [div_le_iff₀ hn0]
          nlinarith
      have hs := eVariationOn.sum_le (f := γ) (n := n) hu us
      refine le_trans (le_of_eq ?_) hs
      have hterm : ∀ i ∈ Finset.range n,
          edist (γ (u (i + 1))) (γ (u i)) = ENNReal.ofReal (2 * r * sin (π / n)) := by
        intro i hi
        have hi' : i < n := Finset.mem_range.mp hi
        rw [edist_dist, hγ, circle_dist x r _ _ hr]
        congr 1
        have hd : (u (i + 1) - u i) / 2 = π / n := by
          simp only [u]
          rw [min_eq_left hi', min_eq_left hi'.le]
          push_cast
          field_simp
          ring
        rw [hd, abs_of_nonneg]
        apply sin_nonneg_of_nonneg_of_le_pi (by positivity)
        rw [div_le_iff₀ hn0]
        have : (1 : ℝ) ≤ n := by exact_mod_cast hn
        nlinarith [pi_pos]
      rw [Finset.sum_congr rfl hterm, Finset.sum_const, Finset.card_range, nsmul_eq_mul,
        mul_comm, ENNReal.ofReal_mul (by
          have : 0 ≤ sin (π / n) := by
            apply sin_nonneg_of_nonneg_of_le_pi (by positivity)
            rw [div_le_iff₀ hn0]
            have : (1 : ℝ) ≤ n := by exact_mod_cast hn
            nlinarith [pi_pos]
          positivity), ENNReal.ofReal_natCast]
    have ht : Filter.Tendsto (fun n : ℕ => ENNReal.ofReal (π * (2 * r) - (r * π ^ 3 / 3) / n))
        Filter.atTop (nhds (ENNReal.ofReal (π * (2 * r)))) := by
      apply ENNReal.tendsto_ofReal
      simpa using (tendsto_const_nhds (x := π * (2 * r))).sub (tendsto_const_div_atTop_nhds_zero_nat (r * π ^ 3 / 3))
    refine le_of_tendsto ht ?_
    rw [Filter.eventually_atTop]
    exact ⟨1, fun n hn => (ENNReal.ofReal_le_ofReal (circle_lower n hn r hr)).trans (key n hn)⟩

/-- Archimedes' bounds from the 96-sided polygons: pi is more than 3 10/71 and less than 3 1/7,
the familiar 22/7. -/
theorem archimedes_bounds_on_pi : (3 + 10 / 71 : ℝ) < π ∧ π < 3 + 1 / 7 := by
  constructor
  · have := pi_gt_d4; norm_num at *; linarith
  · have := pi_lt_d4; norm_num at *; linarith

-- The wheel: 70 cm across, so the radius is 35 cm.
example : (70 : ℕ) / 2 = 35 := by norm_num
-- The inside hexagon: six sides, each one radius (35 cm) long, make 210 cm, 3 diameters.
example : 6 * 35 = 210 ∧ 210 = 3 * 70 := by norm_num
-- Doubling the sides from the hexagon: 4 doublings give Archimedes' 96, 20 give 6,291,456.
example : 6 * 2 ^ 4 = 96 ∧ 6 * 2 ^ 20 = 6291456 := by norm_num
-- Archimedes' fractions: 3 10/71 is 223/71 and 3 1/7 is 22/7.
example : (3 + 10 / 71 : ℚ) = 223 / 71 ∧ (3 + 1 / 7 : ℚ) = 22 / 7 := by norm_num
-- A wheel twice as wide, 140 cm: twice the diameter, but the radius squared grows four times.
example : 140 = 2 * 70 ∧ (70 : ℕ) ^ 2 = 4 * 35 ^ 2 := by norm_num
-- Centimetre squares on the 35 cm disc, one quarter at a time, times 4: 3712 wholly inside, 3980 touching.
example : 4 * ((Finset.range 35 ×ˢ Finset.range 35).filter
    (fun p : ℕ × ℕ => (p.1 + 1) ^ 2 + (p.2 + 1) ^ 2 ≤ 35 * 35)).card = 3712 := by decide +kernel
example : 4 * ((Finset.range 35 ×ˢ Finset.range 35).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + p.2 ^ 2 < 35 * 35)).card = 3980 := by decide +kernel

#print axioms circle_chord_sq
#print axioms circle_dist
#print axioms circle_lower
#print axioms disc_area_eq_pi_mul_radius_sq
#print axioms circumference_eq_pi_mul_diameter
#print axioms archimedes_bounds_on_pi
