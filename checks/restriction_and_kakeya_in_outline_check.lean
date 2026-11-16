-- Restriction and Kakeya in outline: N needle tubes of length 1 and width 1/N, one in each direction kπ/N and placed anywhere in the plane, cover at least (Nδ)²/S_N of area, S_N has the card's closed form, and restricting a transform to the circle is the same problem as extending amplitudes from it.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory Real Complex FourierTransform
open scoped InnerProductSpace ComplexConjugate

namespace RestrictionKakeya

/-! Notation, as on the card. A point of the plane is `x = (x₁, x₂)`, in metres: Mathlib's
`EuclideanSpace ℝ (Fin 2)`, with `x 0 = x₁` and `x 1 = x₂`, its `volume` being area. -/

/-- The plane. -/
abbrev Plane : Type := EuclideanSpace ℝ (Fin 2)

/-- The tube `T` of length 1 and width `δ` centred at `c`, pointing along the direction at angle
`θ`: the points whose offset from `c` is at most `1/2` along `(cos θ, sin θ)` and at most `δ/2`
across it. -/
def tube (c : Plane) (θ δ : ℝ) : Set Plane :=
  {x | |(x 0 - c 0) * Real.cos θ + (x 1 - c 1) * Real.sin θ| ≤ 1 / 2 ∧
       |-(x 0 - c 0) * Real.sin θ + (x 1 - c 1) * Real.cos θ| ≤ δ / 2}

/-- The card's directions: tube number `k` points at angle `kπ/N`. -/
noncomputable def dir (N : ℕ) (k : Fin N) : ℝ := (k : ℝ) * π / N

/-- The overlap total `S_N = Nδ + ∑_{j ≠ k} δ² / sin θ_{jk}` for `N` tubes of width `δ = 1/N` in
the directions `kπ/N`; `θ_{jk}` is the angle between tubes `j` and `k`, whose sine is
`|sin(θ_j - θ_k)|`. -/
noncomputable def overlapTotal (N : ℕ) : ℝ :=
  let δ : ℝ := 1 / N
  N * δ + ∑ j : Fin N, ∑ k ∈ Finset.univ.filter (· ≠ j),
    δ ^ 2 / |Real.sin (dir N j - dir N k)|


/-- The sine at a direction gap `mπ/N`, `1 ≤ m < N`, is positive. -/
lemma sin_pos_of_lt (N m : ℕ) (h1 : 1 ≤ m) (h2 : m < N) : 0 < Real.sin (m * π / N) := by
  have hN : (0 : ℝ) < N := by exact_mod_cast (show 0 < N by omega)
  have hm : (1 : ℝ) ≤ m := by exact_mod_cast h1
  have hmN : (m : ℝ) < N := by exact_mod_cast h2
  apply Real.sin_pos_of_pos_of_lt_pi
  · positivity
  · rw [div_lt_iff₀ hN]; nlinarith [Real.pi_pos]

/-- The sine of the gap between directions `j` and `k` is, up to sign, `sin(mπ/N)` with
`m = j - k` taken mod `N`. -/
lemma abs_sin_dir (N : ℕ) [NeZero N] (j k : Fin N) (h : j ≠ k) :
    |Real.sin (dir N j - dir N k)| = Real.sin (((j - k : Fin N) : ℕ) * π / N) ∧
      0 < Real.sin (((j - k : Fin N) : ℕ) * π / N) := by
  have hpos : 0 < Real.sin (((j - k : Fin N) : ℕ) * π / N) := by
    apply sin_pos_of_lt
    · rcases Nat.eq_zero_or_pos ((j - k : Fin N) : ℕ) with h0 | h0
      · exact absurd (sub_eq_zero.mp (Fin.ext h0)) h
      · exact h0
    · exact (j - k).isLt
  refine ⟨?_, hpos⟩
  have hN : (N : ℝ) ≠ 0 := by exact_mod_cast (NeZero.ne N)
  rcases le_or_gt k j with hkj | hjk
  · have hv : ((j - k : Fin N) : ℕ) = (j : ℕ) - k := Fin.coe_sub_iff_le.mpr hkj
    have hle : (k : ℕ) ≤ j := hkj
    rw [hv, Nat.cast_sub hle, dir, dir, abs_of_pos]
    · congr 1; field_simp
    · convert hpos using 2; rw [hv, Nat.cast_sub hle]; field_simp
  · have hv : ((j - k : Fin N) : ℕ) = N + j - k := Fin.coe_sub_iff_lt.mpr hjk
    have hlt : (j : ℕ) < k := hjk
    have hk : (k : ℕ) < N := k.isLt
    have hc : (((N + j - k : ℕ)) : ℝ) = N + j - k := by
      rw [Nat.cast_sub (by omega)]; push_cast; ring
    have he : ((N + j - k : ℕ) : ℝ) * π / N = (dir N j - dir N k) + π := by
      rw [hc, dir, dir]; field_simp; ring
    rw [hv, he, Real.sin_add_pi]
    rw [hv, he, Real.sin_add_pi] at hpos
    rw [abs_of_neg (by linarith)]


/-- The area of a parallelogram `{|p y₀ + q y₁ - a| ≤ r, |u y₀ + v y₁ - b| ≤ s}` in coordinates. -/
lemma volume_parallelogram (M : Matrix (Fin 2) (Fin 2) ℝ) (hM : M.det ≠ 0) (a b r s : ℝ) :
    volume {y : Fin 2 → ℝ | |M 0 0 * y 0 + M 0 1 * y 1 - a| ≤ r ∧
      |M 1 0 * y 0 + M 1 1 * y 1 - b| ≤ s} =
      ENNReal.ofReal |M.det⁻¹| * (ENNReal.ofReal (2 * r) * ENNReal.ofReal (2 * s)) := by
  have hset : {y : Fin 2 → ℝ | |M 0 0 * y 0 + M 0 1 * y 1 - a| ≤ r ∧
      |M 1 0 * y 0 + M 1 1 * y 1 - b| ≤ s} = Matrix.toLin' M ⁻¹'
        Set.pi Set.univ (fun i => Set.Icc (![a, b] i - ![r, s] i) (![a, b] i + ![r, s] i)) := by
    ext y
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, Set.mem_pi, Set.mem_univ, true_implies,
      Fin.forall_fin_two, Matrix.toLin'_apply, Matrix.mulVec, dotProduct, Fin.sum_univ_two,
      Set.mem_Icc, Matrix.cons_val_zero, Matrix.cons_val_one, abs_le]
    constructor <;> rintro ⟨⟨h1, h2⟩, h3, h4⟩ <;> refine ⟨⟨?_, ?_⟩, ?_, ?_⟩ <;> linarith
  rw [hset, Measure.addHaar_preimage_linearMap _ (by rwa [LinearMap.det_toLin']),
    LinearMap.det_toLin', volume_pi_pi, Fin.prod_univ_two]
  simp only [Real.volume_Icc, Matrix.cons_val_zero, Matrix.cons_val_one]
  ring_nf

/-- Area in the plane is area in coordinates. -/
lemma volume_plane_eq (P : ℝ → ℝ → Prop) :
    volume {x : Plane | P (x 0) (x 1)} = volume {y : Fin 2 → ℝ | P (y 0) (y 1)} := by
  rw [← (EuclideanSpace.volume_preserving_symm_measurableEquiv_toLp (Fin 2)).symm.measure_preimage_equiv]
  rfl

/-- The same parallelogram, in the plane. -/
lemma volume_plane_parallelogram (p q u v a b r s : ℝ) (hM : p * v - q * u ≠ 0) :
    volume {x : Plane | |p * x 0 + q * x 1 - a| ≤ r ∧ |u * x 0 + v * x 1 - b| ≤ s} =
      ENNReal.ofReal |(p * v - q * u)⁻¹| * (ENNReal.ofReal (2 * r) * ENNReal.ofReal (2 * s)) := by
  rw [volume_plane_eq (fun y0 y1 => |p * y0 + q * y1 - a| ≤ r ∧ |u * y0 + v * y1 - b| ≤ s)]
  have := volume_parallelogram !![p, q; u, v] (by rwa [Matrix.det_fin_two_of]) a b r s
  simpa [Matrix.det_fin_two_of] using this

/-- A tube is a closed, hence measurable, set. -/
lemma measurableSet_tube (c : Plane) (θ δ : ℝ) : MeasurableSet (tube c θ δ) := by
  have h0 : Continuous (fun x : Plane => x 0) := (EuclideanSpace.proj (0 : Fin 2)).continuous
  have h1 : Continuous (fun x : Plane => x 1) := (EuclideanSpace.proj (1 : Fin 2)).continuous
  apply IsClosed.measurableSet
  simp only [tube, Set.ofPred_and]
  exact (isClosed_le (by fun_prop) continuous_const).inter (isClosed_le (by fun_prop) continuous_const)

/-- A tube of length 1 and width `δ` has area `δ`. -/
lemma volume_tube (c : Plane) (θ δ : ℝ) :
    volume (tube c θ δ) = ENNReal.ofReal δ := by
  have hset : tube c θ δ = {x : Plane |
      |Real.cos θ * x 0 + Real.sin θ * x 1 - (c 0 * Real.cos θ + c 1 * Real.sin θ)| ≤ 1 / 2 ∧
      |(-Real.sin θ) * x 0 + Real.cos θ * x 1 - (-c 0 * Real.sin θ + c 1 * Real.cos θ)| ≤ δ / 2} := by
    ext x
    simp only [tube, Set.mem_ofPred_eq]
    constructor <;> rintro ⟨h1, h2⟩
    · exact ⟨by convert h1 using 2; ring, by convert h2 using 2; ring⟩
    · exact ⟨by convert h1 using 2; ring, by convert h2 using 2; ring⟩
  rw [hset, volume_plane_parallelogram _ _ _ _ _ _ _ _ (by nlinarith [Real.sin_sq_add_cos_sq θ])]
  have h1 : Real.cos θ * Real.cos θ - Real.sin θ * -Real.sin θ = 1 := by
    nlinarith [Real.sin_sq_add_cos_sq θ]
  rw [h1]
  simp only [inv_one, abs_one, ENNReal.ofReal_one, one_mul]
  rw [← ENNReal.ofReal_mul (by norm_num)]
  congr 1; ring

/-- Two tubes of width `δ` at angles `θ, θ'` with `sin(θ - θ') ≠ 0` meet in area at most
`δ² / |sin(θ - θ')|`: their meeting lies in the parallelogram where the two strips cross. -/
lemma volume_tube_inter_le (c c' : Plane) (θ θ' δ : ℝ) (hδ : 0 ≤ δ)
    (hs : Real.sin (θ - θ') ≠ 0) :
    volume (tube c θ δ ∩ tube c' θ' δ) ≤ ENNReal.ofReal (δ ^ 2 / |Real.sin (θ - θ')|) := by
  have hsub : tube c θ δ ∩ tube c' θ' δ ⊆ {x : Plane |
      |(-Real.sin θ) * x 0 + Real.cos θ * x 1 - (-c 0 * Real.sin θ + c 1 * Real.cos θ)| ≤ δ / 2 ∧
      |(-Real.sin θ') * x 0 + Real.cos θ' * x 1 - (-c' 0 * Real.sin θ' + c' 1 * Real.cos θ')|
        ≤ δ / 2} := by
    rintro x ⟨⟨_, h1⟩, ⟨_, h2⟩⟩
    refine ⟨?_, ?_⟩
    · convert h1 using 2; ring
    · convert h2 using 2; ring
  have hdet : -Real.sin θ * Real.cos θ' - Real.cos θ * -Real.sin θ' = -Real.sin (θ - θ') := by
    rw [Real.sin_sub]; ring
  refine (measure_mono hsub).trans (le_of_eq ?_)
  rw [volume_plane_parallelogram _ _ _ _ _ _ _ _ (by rw [hdet]; exact neg_ne_zero.mpr hs), hdet,
    ← ENNReal.ofReal_mul (by positivity), ← ENNReal.ofReal_mul (abs_nonneg _)]
  congr 1
  rw [abs_inv, abs_neg]
  field_simp

/-- `2aF ≤ F² + a²` for finite `a, F` in `[0, ∞]`. -/
lemma two_mul_mul_le_sq_add_sq {a F : ENNReal} (ha : a ≠ ⊤) (hF : F ≠ ⊤) :
    2 * a * F ≤ F ^ 2 + a ^ 2 := by
  lift F to NNReal using hF
  lift a to NNReal using ha
  rw [← ENNReal.coe_ofNat, ← ENNReal.coe_mul, ← ENNReal.coe_mul, ← ENNReal.coe_pow,
    ← ENNReal.coe_pow, ← ENNReal.coe_add, ENNReal.coe_le_coe, ← NNReal.coe_le_coe]
  push_cast
  nlinarith [sq_nonneg ((F : ℝ) - a)]

/-- **The needle bound in the plane** (The formula; Why it works, Step 5). Take `N` tubes of
length 1 and width `δ = 1/N`, tube `k` pointing in the direction `kπ/N`, and place them anywhere,
tube `k` centred at `c k`. Then their union covers at least `(Nδ)² / S_N` of area. -/
theorem tube_union_area_ge_sq_div_overlap_total (N : ℕ) (c : Fin N → Plane) :
    ENNReal.ofReal (((N : ℝ) * (1 / N)) ^ 2 / overlapTotal N) ≤
      volume (⋃ k : Fin N, tube (c k) (dir N k) (1 / N)) := by
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp
  have : NeZero N := ⟨hN.ne'⟩
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  set δ : ℝ := 1 / (N : ℝ) with hδdef
  have hδ : 0 < δ := by positivity
  have hNδ : (N : ℝ) * δ = 1 := by rw [hδdef]; field_simp
  set T : Fin N → Set Plane := fun k => tube (c k) (dir N k) δ with hTdef
  set U : Set Plane := ⋃ k, T k with hUdef
  have hTm : ∀ k, MeasurableSet (T k) := fun k => measurableSet_tube _ _ _
  have hUm : MeasurableSet U := MeasurableSet.iUnion hTm
  -- the overlap total, split into its diagonal and off-diagonal parts
  have hSdef : overlapTotal N = ∑ j : Fin N, (δ + ∑ k ∈ Finset.univ.filter (· ≠ j),
      δ ^ 2 / |Real.sin (dir N j - dir N k)|) := by
    simp only [overlapTotal]
    rw [Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have hoff : ∀ j k : Fin N, k ≠ j → 0 < |Real.sin (dir N j - dir N k)| :=
    fun j k h => (abs_sin_dir N j k h.symm).1 ▸ (abs_sin_dir N j k h.symm).2
  have hS_nonneg : ∀ j : Fin N, 0 ≤ δ + ∑ k ∈ Finset.univ.filter (· ≠ j),
      δ ^ 2 / |Real.sin (dir N j - dir N k)| := fun j =>
    add_nonneg hδ.le (Finset.sum_nonneg (fun k _ => by positivity))
  have hS1 : 1 ≤ overlapTotal N := by
    rw [hSdef, ← hNδ]
    have : (N : ℝ) * δ = ∑ _j : Fin N, δ := by simp
    rw [this]
    exact Finset.sum_le_sum (fun j _ =>
      le_add_of_nonneg_right (Finset.sum_nonneg (fun k _ => by positivity)))
  set S : ℝ := overlapTotal N with hS
  set s : ENNReal := ENNReal.ofReal S with hs
  have hs0 : s ≠ 0 := by rw [hs]; simp; linarith
  have hstop : s ≠ ⊤ := ENNReal.ofReal_ne_top
  -- the pair areas add up to at most `S`
  have hsum : ∑ j, ∑ k, volume (T j ∩ T k) ≤ s := by
    rw [hs, hSdef, ENNReal.ofReal_sum_of_nonneg (fun j _ => hS_nonneg j)]
    refine Finset.sum_le_sum (fun j _ => ?_)
    rw [← Finset.add_sum_erase _ _ (Finset.mem_univ j), Finset.filter_ne',
      ENNReal.ofReal_add hδ.le (Finset.sum_nonneg (fun k _ => by positivity)),
      ENNReal.ofReal_sum_of_nonneg (fun k _ => by positivity)]
    gcongr with k hk
    · rw [Set.inter_self, volume_tube]
    · have hkj : k ≠ j := Finset.ne_of_mem_erase hk
      exact volume_tube_inter_le _ _ _ _ _ hδ.le
        (by have := hoff j k hkj; intro h; rw [h, abs_zero] at this; exact lt_irrefl _ this)
  -- the tube areas add up to `Nδ = 1`
  have hone : ∑ k, volume (T k) = 1 := by
    simp only [hTdef, volume_tube, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul]
    rw [← ENNReal.ofReal_natCast, ← ENNReal.ofReal_mul (Nat.cast_nonneg _), hNδ,
      ENNReal.ofReal_one]
  -- pointwise: `2 s F ≤ F² + s² 1_U` with `F` the number of tubes through the point
  have hpt : ∀ x, 2 * s * ∑ k, (T k).indicator 1 x ≤
      ∑ j, ∑ k, (T j ∩ T k).indicator (1 : Plane → ENNReal) x + s ^ 2 * U.indicator 1 x := by
    intro x
    have hsq : ∑ j, ∑ k, (T j ∩ T k).indicator (1 : Plane → ENNReal) x =
        (∑ k, (T k).indicator (1 : Plane → ENNReal) x) ^ 2 := by
      rw [sq, Finset.sum_mul_sum]
      simp only [Set.inter_indicator_one, Pi.mul_apply]
    rw [hsq]
    by_cases hx : x ∈ U
    · rw [Set.indicator_of_mem hx, Pi.one_apply, mul_one]
      have hF : ∑ k, (T k).indicator (1 : Plane → ENNReal) x ≠ ⊤ :=
        ENNReal.sum_ne_top.mpr (fun k _ => by
          by_cases h : x ∈ T k <;> simp [Set.indicator, h])
      exact two_mul_mul_le_sq_add_sq hstop hF
    · have h0 : ∀ k, (T k).indicator (1 : Plane → ENNReal) x = 0 := fun k =>
        Set.indicator_of_notMem (fun h => hx (Set.mem_iUnion.mpr ⟨k, h⟩)) _
      simp [h0]
  have hmeasInd : ∀ (A : Set Plane), MeasurableSet A →
      Measurable (A.indicator (1 : Plane → ENNReal)) := fun A hA => measurable_one.indicator hA
  have hint := lintegral_mono (μ := volume) hpt
  rw [lintegral_const_mul _ (Finset.measurable_sum _ (fun k _ => hmeasInd _ (hTm k))),
    lintegral_finsetSum _ (fun k _ => hmeasInd _ (hTm k)),
    lintegral_add_right _ ((hmeasInd _ hUm).const_mul _),
    lintegral_const_mul _ (hmeasInd _ hUm), lintegral_indicator_one hUm,
    lintegral_finsetSum _ (fun j _ => Finset.measurable_sum _ (fun k _ =>
      hmeasInd _ ((hTm j).inter (hTm k))))] at hint
  simp only [lintegral_indicator_one (hTm _), lintegral_indicator_one ((hTm _).inter (hTm _)),
    lintegral_finsetSum _ (fun k _ => hmeasInd _ ((hTm _).inter (hTm k)))] at hint
  rw [hone, mul_one] at hint
  have key : s + s ≤ s + s ^ 2 * volume U := by
    rw [← two_mul]
    exact hint.trans (add_le_add_left hsum _)
  have key2 : s * 1 ≤ s * (s * volume U) := by
    rw [mul_one, ← mul_assoc, ← sq]
    exact (ENNReal.add_le_add_iff_left hstop).mp key
  have key3 : 1 ≤ s * volume U := (ENNReal.mul_le_mul_iff_right hs0 hstop).mp key2
  rw [hNδ, one_pow, one_div, ENNReal.ofReal_inv_of_pos (by linarith), ← hs,
    ENNReal.inv_le_iff_le_mul (fun _ => hs0) (fun h => absurd h hstop)]
  exact key3


/-- **The overlap total in closed form** (Detailed proof of Step 5). Each tube meets the others
at the angles `mπ/N`, `m = 1, …, N - 1`, so with `δ = 1/N`,
`S_N = Nδ + Nδ² ∑_{m=1}^{N-1} 1 / sin(mπ/N) = 1 + (1/N) ∑_{m=1}^{N-1} 1 / sin(mπ/N)`. -/
theorem overlap_total_eq (N : ℕ) (hN : 0 < N) :
    overlapTotal N = 1 + (1 / (N : ℝ)) * ∑ m ∈ Finset.Ico 1 N, 1 / Real.sin (m * π / N) := by
  have : NeZero N := ⟨hN.ne'⟩
  have hNr : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
  have inner : ∀ j : Fin N, ∑ k ∈ Finset.univ.filter (· ≠ j),
      (1 / (N : ℝ)) ^ 2 / |Real.sin (dir N j - dir N k)| =
      (1 / (N : ℝ)) ^ 2 * ∑ m ∈ Finset.Ico 1 N, 1 / Real.sin (m * π / N) := by
    intro j
    rw [Finset.mul_sum]
    refine Finset.sum_bij (fun k _ => ((j - k : Fin N) : ℕ)) ?_ ?_ ?_ ?_
    · intro k hk
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hk
      simp only [Finset.mem_Ico]
      refine ⟨?_, (j - k).isLt⟩
      rcases Nat.eq_zero_or_pos ((j - k : Fin N) : ℕ) with h0 | h0
      · exact absurd (sub_eq_zero.mp (Fin.ext h0)).symm hk
      · exact h0
    · intro a _ b _ hab
      have : j - a = j - b := Fin.ext hab
      exact sub_right_injective this
    · intro m hm
      simp only [Finset.mem_Ico] at hm
      refine ⟨j - ⟨m, hm.2⟩, ?_, ?_⟩
      · simp only [Finset.mem_filter, Finset.mem_univ, true_and, ne_eq, sub_eq_self]
        intro h0
        have := congrArg Fin.val h0
        simp at this
        omega
      · simp
    · intro k hk
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hk
      rw [(abs_sin_dir N j k hk.symm).1, div_eq_mul_one_div]
  simp only [overlapTotal]
  rw [Finset.sum_congr rfl (fun j _ => inner j), Finset.sum_const, Finset.card_univ,
    Fintype.card_fin, nsmul_eq_mul]
  generalize ∑ m ∈ Finset.Ico 1 N, 1 / Real.sin (m * π / N) = s
  field_simp


/-- The direction `ω = (cos φ, sin φ)` on the unit circle `S¹`, at angle `φ`. -/
noncomputable def onCircle (φ : ℝ) : Plane := !₂[Real.cos φ, Real.sin φ]

/-- The extension operator: the field `Eg(x) = ∫_{S¹} g(ω) e^{2πi x·ω} dσ(ω)` built from the
amplitude `g(φ)` of the wave from the direction at angle `φ`, arc length `dσ = dφ`. -/
noncomputable def extension (g : ℝ → ℂ) (x : Plane) : ℂ :=
  ∫ φ in (0 : ℝ)..2 * π, g φ * Complex.exp (2 * π * Complex.I * (⟪x, onCircle φ⟫_ℝ : ℝ))

/-- The pairing `x · ω` with the direction at angle `φ`, in coordinates. -/
lemma inner_onCircle (x : Plane) (φ : ℝ) :
    ⟪x, onCircle φ⟫_ℝ = x 0 * Real.cos φ + x 1 * Real.sin φ := by
  simp [onCircle, PiLp.inner_apply, Fin.sum_univ_two, mul_comm]

/-- **Restriction is extension turned round** (Why it works, Step 1). For an integrable `f` on
the plane, with transform `f̂(ξ) = ∫ f(x) e^{-2πi x·ξ} dx` (Mathlib's `𝓕 f`), and a bounded
amplitude `g` on the circle,
`∫_{S¹} f̂(ω) conj(g(ω)) dσ(ω) = ∫_{ℝ²} f(x) conj(Eg(x)) dx`. -/
theorem integral_circle_fourier_mul_conj_eq_integral_mul_conj_extension
    (f : Plane → ℂ) (hf : Integrable f) (g : ℝ → ℂ) (hg : AEStronglyMeasurable g)
    (hgb : ∃ M, ∀ φ, ‖g φ‖ ≤ M) :
    ∫ φ in (0 : ℝ)..2 * π, 𝓕 f (onCircle φ) * conj (g φ) =
      ∫ x, f x * conj (extension g x) := by
  have hpi : (0 : ℝ) ≤ 2 * π := by positivity
  obtain ⟨M, hM⟩ := hgb
  set μ : Measure ℝ := volume.restrict (Set.Ioc (0 : ℝ) (2 * π)) with hμ
  let F : Plane → ℝ → ℂ := fun x φ =>
    f x * conj (g φ) * Complex.exp (↑(-2 * π * ⟪x, onCircle φ⟫_ℝ) * Complex.I)
  have h0 : Continuous (fun x : Plane => x 0) := (EuclideanSpace.proj (0 : Fin 2)).continuous
  have h1 : Continuous (fun x : Plane => x 1) := (EuclideanSpace.proj (1 : Fin 2)).continuous
  have hcont : Continuous (fun p : Plane × ℝ =>
      Complex.exp (↑(-2 * π * ⟪p.1, onCircle p.2⟫_ℝ) * Complex.I)) := by
    simp only [inner_onCircle]
    fun_prop
  have hint : Integrable (Function.uncurry F) (volume.prod μ) := by
    refine Integrable.mono' ((hf.norm.mul_const M).comp_fst μ) ?_ ?_
    · have hg' : AEStronglyMeasurable (fun φ => conj (g φ)) μ :=
        (continuous_conj.comp_aestronglyMeasurable hg).restrict
      exact (hf.1.comp_fst.mul hg'.comp_snd).mul hcont.aestronglyMeasurable
    · refine Filter.Eventually.of_forall (fun p => ?_)
      simp only [Function.uncurry, F, norm_mul, Complex.norm_conj, Complex.norm_exp_ofReal_mul_I,
        mul_one]
      exact mul_le_mul_of_nonneg_left (hM p.2) (norm_nonneg _)
  have lhs : ∀ φ, 𝓕 f (onCircle φ) * conj (g φ) = ∫ x, F x φ := by
    intro φ
    rw [fourier_eq', ← integral_mul_const]
    congr 1; ext x
    simp only [F, smul_eq_mul]
    ring
  have rhs : ∀ x, f x * conj (extension g x) = ∫ φ, F x φ ∂μ := by
    intro x
    rw [extension, intervalIntegral.integral_of_le hpi, ← integral_conj, ← integral_const_mul]
    congr 1; ext φ
    simp only [F, map_mul, ← Complex.exp_conj, Complex.conj_ofReal, Complex.conj_I, map_ofNat]
    rw [← mul_assoc]
    congr 2
    push_cast
    ring
  rw [intervalIntegral.integral_of_le hpi]
  simp_rw [lhs, rhs]
  exact (integral_integral_swap hint).symm


-- The restriction thresholds 2d/(d-1): 4 in the plane, 3 in space.
example : (2 * 2 / (2 - 1) : ℚ) = 4 := by norm_num
example : (2 * 3 / (3 - 1) : ℚ) = 3 := by norm_num
-- The Stein-Tomas exponent 2(d+1)/(d-1) in the plane is 6.
example : (2 * (2 + 1) / (2 - 1) : ℚ) = 6 := by norm_num
-- At p = 4: 16 × 3/8 × 2π = 12π, the coefficient of 1/r; at p = 6: 64 × 5/16 × 2π = 40π.
example : (16 * (3 / 8) * 2 : ℚ) = 12 := by norm_num
example : (64 * (5 / 16) * 2 : ℚ) = 40 := by norm_num
-- Knapp at p = 6: (2δ)^(1/2) δ^(-3/p) has δ-exponent 1/2 - 3/6 = 0.
example : (1 / 2 - 3 / 6 : ℚ) = 0 := by norm_num
-- The bridge table: Kakeya dimension at least 2p/(p-2) - d.
example : (2 * 4 / (4 - 2) - 2 : ℚ) = 2 := by norm_num
example : (2 * 6 / (6 - 2) - 2 : ℚ) = 1 := by norm_num
example : (2 * 3 / (3 - 2) - 3 : ℚ) = 3 := by norm_num
example : (2 * 4 / (4 - 2) - 3 : ℚ) = 1 := by norm_num
-- Ten tubes of width 1/10: total area Nδ = 1.
example : ((10 : ℚ) * (1 / 10)) = 1 := by norm_num

#print axioms tube_union_area_ge_sq_div_overlap_total
#print axioms overlap_total_eq
#print axioms integral_circle_fourier_mul_conj_eq_integral_mul_conj_extension
#print axioms sin_pos_of_lt
#print axioms abs_sin_dir
#print axioms volume_parallelogram
#print axioms volume_plane_eq
#print axioms volume_plane_parallelogram
#print axioms measurableSet_tube
#print axioms volume_tube
#print axioms volume_tube_inter_le
#print axioms two_mul_mul_le_sq_add_sq
#print axioms inner_onCircle

end RestrictionKakeya
