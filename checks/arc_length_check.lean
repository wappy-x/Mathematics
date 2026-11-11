-- Arc length: for a point moving in the plane with rates that have no jumps, the least upper bound of its chord totals equals the integral of its speed, a graph's length is the integral of √(1 + f'(x)^2), and the card's cable y = x^2/1000 from −200 to 200 m is exactly 500(0.4·√1.16 + asinh 0.4) metres long.
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Analysis.BoundedVariation
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Arsinh
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus

open Set Real

lemma arcLen_sqrt_le (X Y p q : ℝ) :
    √(X ^ 2 + Y ^ 2) ≤ √(p ^ 2 + q ^ 2) + |X - p| + |Y - q| := by
  set N := √(p ^ 2 + q ^ 2) with hNdef
  have hN : N ^ 2 = p ^ 2 + q ^ 2 := Real.sq_sqrt (by positivity)
  have hN0 : 0 ≤ N := Real.sqrt_nonneg _
  have hp : |p| ≤ N := Real.abs_le_sqrt (by nlinarith [sq_nonneg q])
  have hq : |q| ≤ N := Real.abs_le_sqrt (by nlinarith [sq_nonneg p])
  have h1 : p * (X - p) ≤ N * |X - p| :=
    (le_abs_self _).trans (by rw [abs_mul]; exact mul_le_mul_of_nonneg_right hp (abs_nonneg _))
  have h2 : q * (Y - q) ≤ N * |Y - q| :=
    (le_abs_self _).trans (by rw [abs_mul]; exact mul_le_mul_of_nonneg_right hq (abs_nonneg _))
  have h3 : |X - p| ^ 2 = (X - p) ^ 2 := sq_abs _
  have h4 : |Y - q| ^ 2 = (Y - q) ^ 2 := sq_abs _
  have h5 : 0 ≤ |X - p| * |Y - q| := mul_nonneg (abs_nonneg _) (abs_nonneg _)
  calc √(X ^ 2 + Y ^ 2) ≤ √((N + |X - p| + |Y - q|) ^ 2) :=
        Real.sqrt_le_sqrt (by nlinarith)
    _ = N + |X - p| + |Y - q| := Real.sqrt_sq (by positivity)

lemma arcLen_dot_le (c s X Y : ℝ) (h : c ^ 2 + s ^ 2 = 1) : c * X + s * Y ≤ √(X ^ 2 + Y ^ 2) :=
  (le_abs_self _).trans (Real.abs_le_sqrt (by nlinarith [sq_nonneg (c * Y - s * X)]))

lemma arcLen_dist_eq (a b c d : ℝ) :
    dist (!₂[a, b]) (!₂[c, d]) = √((a - c) ^ 2 + (b - d) ^ 2) := by
  rw [EuclideanSpace.dist_eq]; simp [Fin.sum_univ_two, Real.dist_eq, sq_abs]

lemma arcLen_dist_le_integral {x y x' y' : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hxc : ContinuousOn x (Icc a b)) (hyc : ContinuousOn y (Icc a b))
    (hxd : ∀ t ∈ Ioo a b, HasDerivAt x (x' t) t) (hyd : ∀ t ∈ Ioo a b, HasDerivAt y (y' t) t)
    (hx'c : ContinuousOn x' (Icc a b)) (hy'c : ContinuousOn y' (Icc a b)) :
    dist (!₂[x b, y b]) (!₂[x a, y a]) ≤ ∫ t in a..b, √(x' t ^ 2 + y' t ^ 2) := by
  have hA : ∫ t in a..b, x' t = x b - x a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hxc hxd
      (hx'c.intervalIntegrable_of_Icc hab)
  have hB : ∫ t in a..b, y' t = y b - y a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hyc hyd
      (hy'c.intervalIntegrable_of_Icc hab)
  have hvc : ContinuousOn (fun t => √(x' t ^ 2 + y' t ^ 2)) (Icc a b) :=
    ((hx'c.pow 2).add (hy'c.pow 2)).sqrt
  rw [arcLen_dist_eq]
  set A := x b - x a
  set B := y b - y a
  rcases eq_or_lt_of_le (Real.sqrt_nonneg (A ^ 2 + B ^ 2)) with h0 | hpos
  · rw [← h0]; exact intervalIntegral.integral_nonneg hab (fun t _ => Real.sqrt_nonneg _)
  · set N := √(A ^ 2 + B ^ 2) with hNdef
    have hN2 : N ^ 2 = A ^ 2 + B ^ 2 := Real.sq_sqrt (by positivity)
    have key : N = ∫ t in a..b, ((A / N) * x' t + (B / N) * y' t) := by
      rw [intervalIntegral.integral_add, intervalIntegral.integral_const_mul,
        intervalIntegral.integral_const_mul, hA, hB]
      · field_simp; linarith [hN2]
      · exact ((continuousOn_const.mul hx'c).intervalIntegrable_of_Icc hab)
      · exact ((continuousOn_const.mul hy'c).intervalIntegrable_of_Icc hab)
    rw [key]
    apply intervalIntegral.integral_mono_on hab
    · exact (((continuousOn_const.mul hx'c).add (continuousOn_const.mul hy'c)).intervalIntegrable_of_Icc hab)
    · exact hvc.intervalIntegrable_of_Icc hab
    · intro t _
      apply arcLen_dot_le
      field_simp; linarith [hN2]

lemma arcLen_integral_le_dist {x y x' y' : ℝ → ℝ} {a b ε : ℝ} (hab : a ≤ b)
    (hxc : ContinuousOn x (Icc a b)) (hyc : ContinuousOn y (Icc a b))
    (hxd : ∀ t ∈ Ioo a b, HasDerivAt x (x' t) t) (hyd : ∀ t ∈ Ioo a b, HasDerivAt y (y' t) t)
    (hx'c : ContinuousOn x' (Icc a b)) (hy'c : ContinuousOn y' (Icc a b))
    (hεx : ∀ t ∈ Icc a b, |x' t - x' a| ≤ ε) (hεy : ∀ t ∈ Icc a b, |y' t - y' a| ≤ ε) :
    ∫ t in a..b, √(x' t ^ 2 + y' t ^ 2) ≤ dist (!₂[x b, y b]) (!₂[x a, y a]) + 4 * ε * (b - a) := by
  have hA : ∫ t in a..b, x' t = x b - x a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hxc hxd
      (hx'c.intervalIntegrable_of_Icc hab)
  have hB : ∫ t in a..b, y' t = y b - y a :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab hyc hyd
      (hy'c.intervalIntegrable_of_Icc hab)
  have hvc : ContinuousOn (fun t => √(x' t ^ 2 + y' t ^ 2)) (Icc a b) :=
    ((hx'c.pow 2).add (hy'c.pow 2)).sqrt
  rw [arcLen_dist_eq]
  set p := x' a
  set q := y' a
  have h1 : ∫ t in a..b, √(x' t ^ 2 + y' t ^ 2) ≤ ∫ t in a..b, (√(p ^ 2 + q ^ 2) + 2 * ε) :=
    intervalIntegral.integral_mono_on hab (hvc.intervalIntegrable_of_Icc hab)
      intervalIntegrable_const
      (fun t ht => (arcLen_sqrt_le _ _ p q).trans (by linarith [hεx t ht, hεy t ht]))
  rw [intervalIntegral.integral_const, smul_eq_mul] at h1
  have hba : |b - a| = b - a := abs_of_nonneg (sub_nonneg.2 hab)
  have hxA : |(b - a) * p - (x b - x a)| ≤ ε * (b - a) := by
    have : (x b - x a) - (b - a) * p = ∫ t in a..b, (x' t - p) := by
      rw [intervalIntegral.integral_sub (hx'c.intervalIntegrable_of_Icc hab)
        intervalIntegrable_const, hA, intervalIntegral.integral_const, smul_eq_mul]
    rw [abs_sub_comm, this]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := b) (C := ε)
      (f := fun t => x' t - p)
      (fun t ht => hεx t (Ioc_subset_Icc_self (by simpa [uIoc_of_le hab] using ht)))
    simpa [hba] using this
  have hyB : |(b - a) * q - (y b - y a)| ≤ ε * (b - a) := by
    have : (y b - y a) - (b - a) * q = ∫ t in a..b, (y' t - q) := by
      rw [intervalIntegral.integral_sub (hy'c.intervalIntegrable_of_Icc hab)
        intervalIntegrable_const, hB, intervalIntegral.integral_const, smul_eq_mul]
    rw [abs_sub_comm, this]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := a) (b := b) (C := ε)
      (f := fun t => y' t - q)
      (fun t ht => hεy t (Ioc_subset_Icc_self (by simpa [uIoc_of_le hab] using ht)))
    simpa [hba] using this
  have h2 := arcLen_sqrt_le ((b - a) * p) ((b - a) * q) (x b - x a) (y b - y a)
  have h3 : √(((b - a) * p) ^ 2 + ((b - a) * q) ^ 2) = (b - a) * √(p ^ 2 + q ^ 2) := by
    rw [show ((b - a) * p) ^ 2 + ((b - a) * q) ^ 2 = (b - a) ^ 2 * (p ^ 2 + q ^ 2) by ring,
      Real.sqrt_mul (by positivity), Real.sqrt_sq (by linarith)]
  rw [h3] at h2
  nlinarith

#print axioms arcLen_sqrt_le
#print axioms arcLen_dot_le
#print axioms arcLen_dist_eq
#print axioms arcLen_dist_le_integral
#print axioms arcLen_integral_le_dist

/-- **Length is the integral of speed.** A point moves in the plane, at position (x(t), y(t))
at clock time t, from t₀ to t₁. Its rates x'(t) and y'(t) have no jumps: x and y are
continuously differentiable on the closed stretch [t₀, t₁]. The length of its path is defined
by chords: the least upper bound, over every way of picking clock times
t₀ ≤ s₀ ≤ s₁ ≤ … ≤ sₙ ≤ t₁, of the total of the straight (Euclidean) distances between
successive positions; Mathlib calls this `eVariationOn`. Each pass is counted. That length equals
the integral of the speed √(x'(t)^2 + y'(t)^2) from t₀ to t₁ (and so it is finite). -/
theorem arc_length_eq_integral_of_speed {x y : ℝ → ℝ} {t₀ t₁ : ℝ}
    (hx : ContDiffOn ℝ 1 x (Icc t₀ t₁)) (hy : ContDiffOn ℝ 1 y (Icc t₀ t₁)) :
    eVariationOn (fun t => !₂[x t, y t]) (Icc t₀ t₁) =
      ENNReal.ofReal (∫ t in t₀..t₁, √(deriv x t ^ 2 + deriv y t ^ 2)) := by
  rcases le_or_gt t₁ t₀ with h | hlt
  · have hsub : (Icc t₀ t₁).Subsingleton := fun a ha b hb => by
      simp only [mem_Icc] at ha hb; linarith
    rw [eVariationOn.constant_on (hsub.image _), eq_comm, ENNReal.ofReal_eq_zero,
      intervalIntegral.integral_symm, neg_nonpos]
    exact intervalIntegral.integral_nonneg h fun _ _ => Real.sqrt_nonneg _
  set x' := derivWithin x (Icc t₀ t₁) with hx'def
  set y' := derivWithin y (Icc t₀ t₁) with hy'def
  have hU : UniqueDiffOn ℝ (Icc t₀ t₁) := uniqueDiffOn_Icc hlt
  have hx'c : ContinuousOn x' (Icc t₀ t₁) := hx.continuousOn_derivWithin hU le_rfl
  have hy'c : ContinuousOn y' (Icc t₀ t₁) := hy.continuousOn_derivWithin hU le_rfl
  have hxd : ∀ t ∈ Ioo t₀ t₁, HasDerivAt x (x' t) t := fun t ht => by
    have hmem : Icc t₀ t₁ ∈ nhds t := Icc_mem_nhds ht.1 ht.2
    have hd := ((hx.differentiableOn one_ne_zero) t (Ioo_subset_Icc_self ht)).differentiableAt hmem
    rw [hx'def, derivWithin_of_mem_nhds hmem]; exact hd.hasDerivAt
  have hyd : ∀ t ∈ Ioo t₀ t₁, HasDerivAt y (y' t) t := fun t ht => by
    have hmem : Icc t₀ t₁ ∈ nhds t := Icc_mem_nhds ht.1 ht.2
    have hd := ((hy.differentiableOn one_ne_zero) t (Ioo_subset_Icc_self ht)).differentiableAt hmem
    rw [hy'def, derivWithin_of_mem_nhds hmem]; exact hd.hasDerivAt
  have hint_eq : ∫ t in t₀..t₁, √(deriv x t ^ 2 + deriv y t ^ 2) =
      ∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2) := by
    apply intervalIntegral.integral_congr_Ioo_of_le hlt.le
    intro t ht
    simp only [(hxd t ht).deriv, (hyd t ht).deriv]
  have hvc : ContinuousOn (fun t => √(x' t ^ 2 + y' t ^ 2)) (Icc t₀ t₁) :=
    ((hx'c.pow 2).add (hy'c.pow 2)).sqrt
  have hsubI : ∀ {a b}, a ∈ Icc t₀ t₁ → b ∈ Icc t₀ t₁ → Icc a b ⊆ Icc t₀ t₁ :=
    fun ha hb => Icc_subset_Icc ha.1 hb.2
  have hsubO : ∀ {a b}, a ∈ Icc t₀ t₁ → b ∈ Icc t₀ t₁ → Ioo a b ⊆ Ioo t₀ t₁ :=
    fun ha hb => Ioo_subset_Ioo ha.1 hb.2
  have hII : ∀ {a b}, a ∈ Icc t₀ t₁ → b ∈ Icc t₀ t₁ →
      IntervalIntegrable (fun t => √(x' t ^ 2 + y' t ^ 2)) MeasureTheory.volume a b :=
    fun ha hb => (hvc.mono (uIcc_subset_Icc ha hb)).intervalIntegrable
  rw [hint_eq]
  apply le_antisymm
  · refine iSup_le fun P => ?_
    obtain ⟨n, u, hu, us⟩ := P
    dsimp only
    calc ∑ i ∈ Finset.range n, edist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])
        = ENNReal.ofReal (∑ i ∈ Finset.range n,
            dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])) := by
          rw [ENNReal.ofReal_sum_of_nonneg (fun _ _ => dist_nonneg)]
          simp only [edist_dist]
      _ ≤ ENNReal.ofReal (∑ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2)) := by
          apply ENNReal.ofReal_le_ofReal
          apply Finset.sum_le_sum
          intro i _
          have hle : u i ≤ u (i + 1) := hu (Nat.le_succ i)
          have hI := hsubI (us i) (us (i + 1))
          have hO := hsubO (us i) (us (i + 1))
          exact arcLen_dist_le_integral hle (hx.continuousOn.mono hI) (hy.continuousOn.mono hI)
            (fun t ht => hxd t (hO ht)) (fun t ht => hyd t (hO ht)) (hx'c.mono hI) (hy'c.mono hI)
      _ = ENNReal.ofReal (∫ t in u 0..u n, √(x' t ^ 2 + y' t ^ 2)) := by
          rw [intervalIntegral.sum_integral_adjacent_intervals]
          intro k _
          exact hII (us k) (us (k + 1))
      _ ≤ ENNReal.ofReal (∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2)) := by
          apply ENNReal.ofReal_le_ofReal
          have h0 : t₀ ∈ Icc t₀ t₁ := ⟨le_rfl, hlt.le⟩
          have h1 : t₁ ∈ Icc t₀ t₁ := ⟨hlt.le, le_rfl⟩
          rw [← intervalIntegral.integral_add_adjacent_intervals (hII h0 (us 0)) (hII (us 0) h1),
            ← intervalIntegral.integral_add_adjacent_intervals (hII (us 0) (us n)) (hII (us n) h1)]
          have e1 : 0 ≤ ∫ t in t₀..u 0, √(x' t ^ 2 + y' t ^ 2) :=
            intervalIntegral.integral_nonneg (us 0).1 fun _ _ => Real.sqrt_nonneg _
          have e2 : 0 ≤ ∫ t in u n..t₁, √(x' t ^ 2 + y' t ^ 2) :=
            intervalIntegral.integral_nonneg (us n).2 fun _ _ => Real.sqrt_nonneg _
          linarith
  · apply ENNReal.le_of_forall_pos_le_add
    intro η hη _
    have hL : 0 < t₁ - t₀ := sub_pos.2 hlt
    set ε : ℝ := (η : ℝ) / (4 * (t₁ - t₀)) with hεdef
    have hε : 0 < ε := by positivity
    have hεL : 4 * ε * (t₁ - t₀) = η := by rw [hεdef]; field_simp
    obtain ⟨δx, hδx, hx'u⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hx'c) ε hε
    obtain ⟨δy, hδy, hy'u⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hy'c) ε hε
    set δ := min δx δy
    have hδ : 0 < δ := lt_min hδx hδy
    obtain ⟨n, hn⟩ := exists_nat_gt ((t₁ - t₀) / δ)
    have hnpos : (0 : ℝ) < n := lt_trans (by positivity) hn
    set h := (t₁ - t₀) / n with hhdef
    have hh : 0 < h := by positivity
    have hhδ : h < δ := by
      rw [hhdef, div_lt_iff₀ hnpos]; rw [div_lt_iff₀ hδ] at hn; linarith
    have hnh : (n : ℝ) * h = t₁ - t₀ := by rw [hhdef]; field_simp
    set u : ℕ → ℝ := fun i => t₀ + i * h with hudef
    have hmono : MonotoneOn u (Iic n) := fun i _ j _ hij => by
      simp only [hudef]; gcongr
    have hus : ∀ i ≤ n, u i ∈ Icc t₀ t₁ := fun i hi => by
      have : (i : ℝ) ≤ n := by exact_mod_cast hi
      constructor
      · simp only [hudef]; nlinarith
      · simp only [hudef]; nlinarith
    have hsum := eVariationOn.sum_le_of_monotoneOn_Iic
      (f := fun t => !₂[x t, y t]) hmono hus
    have hkey : ∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2) ≤
        (∑ i ∈ Finset.range n, dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)]))
          + η := by
      have hu0 : u 0 = t₀ := by simp [hudef]
      have hun : u n = t₁ := by simp only [hudef]; linarith
      have hsplit : ∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2) =
          ∑ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2) := by
        rw [intervalIntegral.sum_integral_adjacent_intervals, hu0, hun]
        intro k hk
        exact hII (hus k hk.le) (hus (k + 1) hk)
      rw [hsplit, ← hεL, ← hnh]
      have : ∀ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2) ≤
          dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)]) + 4 * ε * h := by
        intro i hi
        rw [Finset.mem_range] at hi
        have hai := hus i hi.le
        have hbi := hus (i + 1) hi
        have hle : u i ≤ u (i + 1) := hmono (mem_Iic.2 hi.le) (mem_Iic.2 hi) (Nat.le_succ i)
        have hdiff : u (i + 1) - u i = h := by simp only [hudef]; push_cast; ring
        have hI := hsubI hai hbi
        have hO := hsubO hai hbi
        have := arcLen_integral_le_dist (ε := ε) hle (hx.continuousOn.mono hI)
          (hy.continuousOn.mono hI)
          (fun t ht => hxd t (hO ht)) (fun t ht => hyd t (hO ht)) (hx'c.mono hI) (hy'c.mono hI)
          (fun t ht => by
            have hd : dist t (u i) < δx := by
              rw [Real.dist_eq, abs_of_nonneg (by linarith [ht.1])]
              linarith [ht.2, min_le_left δx δy]
            have := hx'u t (hI ht) (u i) hai hd
            rw [Real.dist_eq] at this; exact this.le)
          (fun t ht => by
            have hd : dist t (u i) < δy := by
              rw [Real.dist_eq, abs_of_nonneg (by linarith [ht.1])]
              linarith [ht.2, min_le_right δx δy]
            have := hy'u t (hI ht) (u i) hai hd
            rw [Real.dist_eq] at this; exact this.le)
        rw [hdiff] at this; exact this
      calc ∑ i ∈ Finset.range n, ∫ t in u i..u (i + 1), √(x' t ^ 2 + y' t ^ 2)
          ≤ ∑ i ∈ Finset.range n,
            (dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)]) + 4 * ε * h) :=
            Finset.sum_le_sum this
        _ = _ := by rw [Finset.sum_add_distrib, Finset.sum_const, Finset.card_range, nsmul_eq_mul]; ring
    calc ENNReal.ofReal (∫ t in t₀..t₁, √(x' t ^ 2 + y' t ^ 2))
        ≤ ENNReal.ofReal ((∑ i ∈ Finset.range n,
            dist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])) + η) :=
          ENNReal.ofReal_le_ofReal hkey
      _ = (∑ i ∈ Finset.range n,
            edist (!₂[x (u (i + 1)), y (u (i + 1))]) (!₂[x (u i), y (u i)])) + η := by
          rw [ENNReal.ofReal_add (Finset.sum_nonneg fun _ _ => dist_nonneg) (NNReal.coe_nonneg η),
            ENNReal.ofReal_sum_of_nonneg (fun _ _ => dist_nonneg), ENNReal.ofReal_coe_nnreal]
          simp only [edist_dist]
      _ ≤ _ := by gcongr

/-- **The graph formula.** If the height f(x) and its slope f'(x) have no jumps on the stretch
from a to b (f is continuously differentiable on [a, b]), then the length of the graph
x ↦ (x, f(x)) over [a, b], the least upper bound of its chord totals, is
∫ from a to b of √(1 + f'(x)^2). -/
theorem graph_length_eq_integral_sqrt_one_add_deriv_sq {f : ℝ → ℝ} {a b : ℝ}
    (hf : ContDiffOn ℝ 1 f (Icc a b)) :
    eVariationOn (fun x => !₂[x, f x]) (Icc a b) =
      ENNReal.ofReal (∫ x in a..b, √(1 + deriv f x ^ 2)) := by
  simpa using arc_length_eq_integral_of_speed (x := fun t => t) (y := f) contDiffOn_id hf

/-- **The cable.** The suspension cable hangs as y = x^2/1000 between towers at x = −200 and
x = 200 m (span 400 m, sag 40 m). Its length, the least upper bound of its chord totals, is
exactly 500 · (0.4 · √1.16 + asinh 0.4) metres, about 410.424 m. Here 0.4 = 2/5 and
1.16 = 29/25. -/
theorem cable_length_closed_form :
    eVariationOn (fun x : ℝ => !₂[x, x ^ 2 / 1000]) (Icc (-200) 200) =
      ENNReal.ofReal (500 * (2 / 5 * √(29 / 25) + arsinh (2 / 5))) := by
  rw [graph_length_eq_integral_sqrt_one_add_deriv_sq (f := fun x : ℝ => x ^ 2 / 1000)
    ((contDiff_id.pow 2).div_const _).contDiffOn]
  congr 1
  have hd : ∀ x : ℝ, deriv (fun x : ℝ => x ^ 2 / 1000) x = x / 500 := fun x => by
    rw [((hasDerivAt_pow 2 x).div_const 1000).deriv]; ring
  simp only [hd]
  have hF : ∀ x ∈ uIcc (-200 : ℝ) 200, HasDerivAt
      (fun x : ℝ => 250 * (x / 500 * √(1 + (x / 500) ^ 2) + arsinh (x / 500)))
      (√(1 + (x / 500) ^ 2)) x := by
    intro x _
    have hu : HasDerivAt (fun x : ℝ => x / 500) (1 / 500) x := (hasDerivAt_id x).div_const 500
    have hpos : 0 < 1 + (x / 500) ^ 2 := by positivity
    have hs : HasDerivAt (fun x : ℝ => √(1 + (x / 500) ^ 2))
        ((2 * (x / 500) * (1 / 500)) / (2 * √(1 + (x / 500) ^ 2))) x := by
      have h1 : HasDerivAt (fun x : ℝ => 1 + (x / 500) ^ 2) (2 * (x / 500) * (1 / 500)) x := by
        have := (hu.pow 2).const_add 1
        convert this using 1; push_cast; ring
      exact h1.sqrt hpos.ne'
    have := ((hu.mul hs).add hu.arsinh).const_mul 250
    convert this using 1
    have hsq := Real.sq_sqrt hpos.le
    have hspos := Real.sqrt_pos.2 hpos
    rw [smul_eq_mul]
    generalize √(1 + (x / 500) ^ 2) = s at hsq hspos ⊢
    field_simp
    nlinarith [hsq]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF
    (by apply Continuous.intervalIntegrable; fun_prop)]
  have e1 : (200 : ℝ) / 500 = 2 / 5 := by norm_num
  have e2 : (-200 : ℝ) / 500 = -(2 / 5) := by norm_num
  have e3 : 1 + ((2 : ℝ) / 5) ^ 2 = 29 / 25 := by norm_num
  simp only [e1, e2, neg_sq, e3, Real.arsinh_neg]
  ring

-- The sag: the cable's height at a tower is 200^2/1000 = 40 m.
example : (200 : ℚ) ^ 2 / 1000 = 40 := by norm_num
-- The slope x/500 at a tower is 200/500 = 0.4 = 2/5.
example : (200 : ℚ) / 500 = 2 / 5 := by norm_num
-- The stretch factor squared at a tower: 1 + 0.4^2 = 1.16 = 29/25.
example : 1 + ((2 : ℚ) / 5) ^ 2 = 29 / 25 := by norm_num
-- The slope x/500 is the derivative of x^2/1000: 2x/1000 = x/500.
example : ∀ x : ℚ, 2 * x / 1000 = x / 500 := by intro x; ring
-- The moving point x = 200t, y = 40t^2 traces the same parabola: 40t^2 = (200t)^2/1000.
example : ∀ t : ℚ, 40 * t ^ 2 = (200 * t) ^ 2 / 1000 := by intro t; ring
-- It starts and ends at the towers: x = ∓200, y = 40 at t = ∓1.
example : (200 : ℚ) * (-1) = -200 ∧ (40 : ℚ) * (-1) ^ 2 = 40 ∧ (200 : ℚ) * 1 = 200 := by norm_num
-- Its speed squared at t = 1 is 200^2 + 80^2 = 46400 = 40000 · 1.16, the graph's stretch factor
-- squared times the clock's 200 m per unit of time, squared.
example : (200 : ℚ) ^ 2 + (2 * 40 * 1) ^ 2 = 200 ^ 2 * (29 / 25) := by norm_num
-- Integrating the slope's size, forgetting the 1: vertical travel 40 m down plus 40 m up = 80 m.
example : (40 : ℚ) + 40 = 80 := by norm_num
-- Dropping the square root: 400 + (200^3 + 200^3)/(3 · 500^2) = 1264/3 m, about 421.333 m.
example : (400 : ℚ) + (200 ^ 3 + 200 ^ 3) / (3 * 500 ^ 2) = 1264 / 3 := by norm_num
-- The shallow-sag rule of thumb: 400 + 8 · 40^2/(3 · 400) = 1232/3 m, about 410.667 m.
example : (400 : ℚ) + 8 * 40 ^ 2 / (3 * 400) = 1232 / 3 := by norm_num
-- Figure points at 0.8 units per metre: the towers (−200, 40) and (200, 40) sit
-- 0.8 · 400 = 320 units apart (x = 20 and x = 340).
example : (340 : ℚ) - 20 = 4 / 5 * 400 := by norm_num

#print axioms arc_length_eq_integral_of_speed
#print axioms graph_length_eq_integral_sqrt_one_add_deriv_sq
#print axioms cable_length_closed_form
