-- The test spaces: the Cantor set is compact, totally disconnected and has no isolated point, its address distance is an ultrametric squeezed between the ordinary distance and a third of it, and the indiscrete and cofinite spaces break the usual Hausdorff claims.
import Mathlib.Topology.Instances.CantorSet
import Mathlib.Topology.Perfect
import Mathlib.Topology.Connected.TotallyDisconnected
import Mathlib.Topology.MetricSpace.PiNat
import Mathlib.Topology.Separation.Basic

open Filter Topology

/-- The card's address distance between two points of the Cantor set: if their base-3 addresses
(digits 0 and 2 only, from `cantorToTernary`) first differ at digit place `n` (counting from 1),
the distance is `3 ^ (-n)`; a point is at distance 0 from itself. Mathlib numbers the digits from 0,
so the card's place `n` is `PiNat.firstDiff + 1`. -/
noncomputable def addrDist (x y : ℝ) : ℝ :=
  if x = y then 0
  else (3 : ℝ) ^ (-((PiNat.firstDiff (cantorToTernary x).get (cantorToTernary y).get : ℤ) + 1))

open Real in
/-- Two different points of the Cantor set have different digit strings. -/
theorem cantor_digits_ne {x y : ℝ} (hx : x ∈ cantorSet) (hy : y ∈ cantorSet) (h : x ≠ y) :
    (cantorToTernary x).get ≠ (cantorToTernary y).get := by
  intro e
  apply h
  rw [← ofDigits_cantorToTernary hx, ← ofDigits_cantorToTernary hy, e]

/-- For different points, the address distance is `(3 ^ (firstDiff + 1))⁻¹`. -/
theorem addrDist_of_ne {x y : ℝ} (h : x ≠ y) :
    addrDist x y =
      ((3 : ℝ) ^ (PiNat.firstDiff (cantorToTernary x).get (cantorToTernary y).get + 1))⁻¹ := by
  simp only [addrDist, h, ite_false]
  rw [show (-((PiNat.firstDiff (cantorToTernary x).get (cantorToTernary y).get : ℤ) + 1)) =
      -(((PiNat.firstDiff (cantorToTernary x).get (cantorToTernary y).get + 1 : ℕ) : ℤ)) by
    push_cast; ring, zpow_neg, zpow_natCast]

theorem addrDist_nonneg (x y : ℝ) : 0 ≤ addrDist x y := by
  unfold addrDist
  split_ifs
  · exact le_rfl
  · positivity

open Real in
/-- Two 0–2 digit strings that agree before place `n` and differ at place `n` give numbers at
least `(3 ^ (n + 1))⁻¹` apart. -/
theorem cantor_lower_bound {a b : ℕ → Fin 3} (ha : ∀ i, a i ≠ 1) (hb : ∀ i, b i ≠ 1) (n : ℕ)
    (heq : ∀ i < n, a i = b i) (hn : a n ≠ b n) :
    ((3 : ℝ) ^ (n + 1))⁻¹ ≤ |ofDigits a - ofDigits b| := by
  rw [ofDigits_eq_sum_add_ofDigits a (n + 1), ofDigits_eq_sum_add_ofDigits b (n + 1),
    Finset.sum_range_succ, Finset.sum_range_succ]
  have hs : ∑ i ∈ Finset.range n, ofDigitsTerm a i = ∑ i ∈ Finset.range n, ofDigitsTerm b i :=
    Finset.sum_congr rfl fun i hi ↦ by simp [ofDigitsTerm, heq i (Finset.mem_range.mp hi)]
  rw [hs]
  have hA0 := ofDigits_nonneg (fun i ↦ a (i + (n + 1)))
  have hA1 := ofDigits_le_one (fun i ↦ a (i + (n + 1)))
  have hB0 := ofDigits_nonneg (fun i ↦ b (i + (n + 1)))
  have hB1 := ofDigits_le_one (fun i ↦ b (i + (n + 1)))
  generalize ofDigits (fun i ↦ a (i + (n + 1))) = A at *
  generalize ofDigits (fun i ↦ b (i + (n + 1))) = B at *
  generalize ∑ i ∈ Finset.range n, ofDigitsTerm b i = S
  simp only [ofDigitsTerm, Nat.cast_ofNat]
  have hcpos : 0 < ((3 : ℝ) ^ (n + 1))⁻¹ := by positivity
  generalize ((3 : ℝ) ^ (n + 1))⁻¹ = c at *
  have ha' := ha n
  have hb' := hb n
  generalize a n = p at *
  generalize b n = q at *
  fin_cases p <;> fin_cases q <;> simp_all
  · rw [le_abs]
    right
    nlinarith [mul_nonneg hcpos.le (by linarith : (0 : ℝ) ≤ 1 + B - A)]
  · rw [le_abs]
    left
    nlinarith [mul_nonneg hcpos.le (by linarith : (0 : ℝ) ≤ 1 + A - B)]

/-- The Cantor set is compact, totally disconnected (its only connected parts are single points),
and has no isolated point: every point of it has other points of the set as close as wished. -/
theorem cantorSet_compact_totallyDisconnected_no_isolated_point :
    IsCompact cantorSet ∧ IsTotallyDisconnected cantorSet ∧ Preperfect cantorSet := by
  refine ⟨isCompact_cantorSet, ?_, ?_⟩
  · have : TotallyDisconnectedSpace cantorSet :=
      cantorSetHomeomorphNatToBool.symm.totallyDisconnectedSpace
    exact totallyDisconnectedSpace_subtype_iff.1 this
  · rw [preperfect_iff_nhds]
    intro x hx U hU
    obtain ⟨ε, hε, hball⟩ := Metric.mem_nhds_iff.1 hU
    obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one hε (by norm_num : (1 / 3 : ℝ) < 1)
    set a := (cantorToTernary x).get with ha
    let b : ℕ → Fin 3 := Function.update a n (if a n = 0 then 2 else 0)
    have hb1 : ∀ i, b i ≠ 1 := by
      intro i
      by_cases hi : i = n
      · subst hi
        simp only [b, Function.update_self]
        split_ifs <;> decide
      · simp only [b, Function.update_of_ne hi]
        exact cantorToTernary_ne_one
    have hbn : b n ≠ a n := by
      simp only [b, Function.update_self]
      have := (cantorToTernary_ne_one : a n ≠ 1)
      split_ifs with h
      · rw [h]; decide
      · exact Ne.symm h
    have hab : ∀ i < n, b i = a i := fun i hi ↦ Function.update_of_ne hi.ne _ _
    have hyC : Real.ofDigits b ∈ cantorSet := ofDigits_zero_two_sequence_mem_cantorSet hb1
    have hxa : Real.ofDigits a = x := ofDigits_cantorToTernary hx
    refine ⟨Real.ofDigits b, ⟨hball ?_, hyC⟩, ?_⟩
    · rw [Metric.mem_ball, Real.dist_eq, ← hxa]
      refine lt_of_le_of_lt (Real.abs_ofDigits_sub_ofDigits_le hab) ?_
      calc ((3 : ℕ) ^ n : ℝ)⁻¹ = (1 / 3 : ℝ) ^ n := by push_cast; rw [one_div, inv_pow]
        _ < ε := hn
    · intro e
      rw [← hxa] at e
      exact hbn (congrFun (ofDigits_zero_two_sequence_unique hb1
        (fun _ ↦ cantorToTernary_ne_one) e) n)

/-- The address distance on the Cantor set obeys the strong triangle rule
`d(x, z) ≤ max (d(x, y)) (d(y, z))`, so it is an ultrametric, and it is sandwiched by the
ordinary distance: `d(x, y) ≤ |x - y| ≤ 3 d(x, y)`. -/
theorem cantor_addrDist_ultrametric_and_sandwich :
    (∀ x ∈ cantorSet, ∀ y ∈ cantorSet, ∀ z ∈ cantorSet,
      addrDist x z ≤ max (addrDist x y) (addrDist y z)) ∧
    (∀ x ∈ cantorSet, ∀ y ∈ cantorSet,
      addrDist x y ≤ |x - y| ∧ |x - y| ≤ 3 * addrDist x y) := by
  refine ⟨?_, ?_⟩
  · intro x hx y hy z hz
    by_cases hxz : x = z
    · simp only [addrDist, hxz, ite_true]
      exact le_max_of_le_left (addrDist_nonneg _ _)
    by_cases hxy : x = y
    · subst hxy; exact le_max_right _ _
    by_cases hyz : y = z
    · subst hyz; exact le_max_left _ _
    rw [addrDist_of_ne hxz, addrDist_of_ne hxy, addrDist_of_ne hyz]
    have hm := PiNat.min_firstDiff_le (cantorToTernary x).get (cantorToTernary y).get
      (cantorToTernary z).get (cantor_digits_ne hx hz hxz)
    rcases le_total (PiNat.firstDiff (cantorToTernary x).get (cantorToTernary y).get)
        (PiNat.firstDiff (cantorToTernary y).get (cantorToTernary z).get) with h | h
    · rw [min_eq_left h] at hm
      refine le_max_of_le_left ?_
      gcongr
      · norm_num
    · rw [min_eq_right h] at hm
      refine le_max_of_le_right ?_
      gcongr
      · norm_num
  · intro x hx y hy
    by_cases hxy : x = y
    · simp [addrDist, hxy]
    rw [addrDist_of_ne hxy]
    have hne := cantor_digits_ne hx hy hxy
    set n := PiNat.firstDiff (cantorToTernary x).get (cantorToTernary y).get
    have hxa := ofDigits_cantorToTernary hx
    have hya := ofDigits_cantorToTernary hy
    constructor
    · have := cantor_lower_bound (fun _ ↦ cantorToTernary_ne_one)
        (fun _ ↦ cantorToTernary_ne_one) n (fun i hi ↦ PiNat.apply_eq_of_lt_firstDiff hi)
        (PiNat.apply_firstDiff_ne hne)
      rwa [hxa, hya] at this
    · have := Real.abs_ofDigits_sub_ofDigits_le (b := 3) (n := n)
        (x := (cantorToTernary x).get) (y := (cantorToTernary y).get)
        (fun i hi ↦ PiNat.apply_eq_of_lt_firstDiff hi)
      rw [hxa, hya] at this
      refine this.trans (le_of_eq ?_)
      push_cast
      rw [pow_succ, mul_inv]
      field_simp

/-- The indiscrete topology on two points (here `Bool`, with only the empty set and the whole set
open) has a compact set `{true}` that is not closed, a constant sequence `true, true, …` that also
converges to `false`, and it is connected. The cofinite topology on the counting numbers makes
every point a closed set (T1) but is not Hausdorff. -/
theorem indiscrete_and_cofinite_break_hausdorff_claims :
    (@IsCompact Bool ⊤ {true} ∧ ¬ @IsClosed Bool ⊤ {true}) ∧
    Tendsto (fun _ : ℕ => true) atTop (@nhds Bool ⊤ false) ∧
    @ConnectedSpace Bool ⊤ ∧
    (T1Space (CofiniteTopology ℕ) ∧ ¬ T2Space (CofiniteTopology ℕ)) := by
  refine ⟨⟨?_, ?_⟩, ?_, ?_, ⟨inferInstance, ?_⟩⟩
  · exact @Set.Finite.isCompact Bool ⊤ _ (Set.toFinite _)
  · intro h
    have h' := h.isOpen_compl
    rw [TopologicalSpace.isOpen_top_iff] at h'
    rcases h' with h | h
    · have : false ∈ ({true}ᶜ : Set Bool) := by simp
      rw [h] at this
      exact this
    · have : true ∈ ({true}ᶜ : Set Bool) := by rw [h]; trivial
      simp at this
  · rw [nhds_top]
    exact tendsto_top
  · refine @ConnectedSpace.mk Bool ⊤ (@PreconnectedSpace.mk Bool ⊤ ?_) ⟨true⟩
    intro u v hu hv _ hsu hsv
    rw [TopologicalSpace.isOpen_top_iff] at hu hv
    rcases hu with rfl | rfl
    · simp at hsu
    rcases hv with rfl | rfl
    · simp at hsv
    exact ⟨true, by simp⟩
  · intro hT2
    obtain ⟨u, v, hu, hv, h0, h1, huv⟩ :=
      t2_separation (show CofiniteTopology.of (0 : ℕ) ≠ CofiniteTopology.of 1 by
        simp [CofiniteTopology.of])
    rw [CofiniteTopology.isOpen_iff] at hu hv
    have hfin : (u ∩ v)ᶜ.Finite := by
      rw [Set.compl_inter]
      exact (hu ⟨_, h0⟩).union (hv ⟨_, h1⟩)
    have hinf : (u ∩ v).Infinite := by
      intro hf
      have : (Set.univ : Set (CofiniteTopology ℕ)).Finite := by
        rw [← Set.union_compl_self (u ∩ v)]
        exact hf.union hfin
      have : Infinite (CofiniteTopology ℕ) :=
        Infinite.of_injective CofiniteTopology.of CofiniteTopology.of.injective
      exact Set.infinite_univ (by assumption)
    obtain ⟨w, hw⟩ := hinf.nonempty
    exact Set.disjoint_left.1 huv hw.1 hw.2

-- After 3 rounds of deleting: 8 pieces, each 1/27 long.
example : (2 : ℕ) ^ 3 = 8 ∧ ((1 : ℚ) / 3) ^ 3 = 1 / 27 := by norm_num
-- Address distances for x = 0, y = 2/9, z = 8/27: first differences at digits 2, 3, 2.
example : (3 : ℚ) ^ (-2 : ℤ) = 1 / 9 ∧ (3 : ℚ) ^ (-3 : ℤ) = 1 / 27 := by norm_num
-- Strong triangle rule holds for the address distance: d(x, z) = 1/9 ≤ max (1/9) (1/27).
example : (1 / 9 : ℚ) ≤ max (1 / 9) (1 / 27) := by norm_num
-- Ordinary distances 2/9, 2/27, 8/27; the ordinary distance breaks the strong rule.
example : |(2 / 9 : ℚ) - 0| = 2 / 9 ∧ |(8 / 27 : ℚ) - 2 / 9| = 2 / 27 ∧ |(8 / 27 : ℚ) - 0| = 8 / 27 ∧
    (8 / 27 : ℚ) > max (2 / 9) (2 / 27) := by norm_num
-- Sandwich for x, z: 1/9 ≤ 8/27 ≤ 3 · 1/9.
example : (1 / 9 : ℚ) ≤ 8 / 27 ∧ (8 / 27 : ℚ) ≤ 3 * (1 / 9) := by norm_num
-- Gap point 0.0111… = (1/9) / (1 - 1/3) = 1/6, strictly between x = 0 and y = 2/9.
example : (1 / 9 : ℚ) / (1 - 1 / 3) = 1 / 6 ∧ (0 : ℚ) < 1 / 6 ∧ (1 / 6 : ℚ) < 2 / 9 := by norm_num
-- Two longest sides of the triangle x, y, z under the address distance are equal: 1/9 and 1/9.
example : max ((3 : ℚ) ^ (-2 : ℤ)) ((3 : ℚ) ^ (-3 : ℤ)) = (3 : ℚ) ^ (-2 : ℤ) := by norm_num

#print axioms cantor_digits_ne
#print axioms addrDist_of_ne
#print axioms addrDist_nonneg
#print axioms cantor_lower_bound
#print axioms cantorSet_compact_totallyDisconnected_no_isolated_point
#print axioms cantor_addrDist_ultrametric_and_sandwich
#print axioms indiscrete_and_cofinite_break_hausdorff_claims
