-- The Greeks together: for a price that is three times smoothly differentiable near today's inputs, the change after a move is the sum of each slope times its input's move, plus half of each pure bend times its move squared, plus each cross bend once times its two moves, with a leftover error that, divided by the cube of the move's scale, tends to one sixth of the third slope along the move.
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Tactic.NormNum

open Filter Topology Set

/-- The slope of `f` in its `i`-th input with the other inputs held still, read at each point:
`∂ᵢf(y) = Df(y) eᵢ`. Applied twice or three times it gives the bends and third slopes. With the
four inputs (share price, volatility, time, rate), `partialSlope 0 V` is delta,
`partialSlope 0 (partialSlope 0 V)` is gamma, `partialSlope 1 V` is vega,
`partialSlope 0 (partialSlope 1 V)` is vanna and `partialSlope 1 (partialSlope 1 V)` is volga. -/
noncomputable def partialSlope {n : ℕ} (i : Fin n) (f : (Fin n → ℝ) → ℝ) : (Fin n → ℝ) → ℝ :=
  fun y => fderiv ℝ f y (Pi.single i 1)

lemma partialSlope_contDiffAt {n : ℕ} {k m : WithTop ℕ∞} {W : (Fin n → ℝ) → ℝ}
    {y : Fin n → ℝ} (i : Fin n) (hW : ContDiffAt ℝ k W y) (hmk : m + 1 ≤ k) :
    ContDiffAt ℝ m (partialSlope i W) y :=
  (hW.fderiv_right hmk).clm_apply contDiffAt_const

lemma clm_apply_eq_sum_single {n : ℕ} (L : (Fin n → ℝ) →L[ℝ] ℝ) (h : Fin n → ℝ) :
    L h = ∑ i, L (Pi.single i 1) * h i := by
  conv_lhs => rw [← Finset.univ_sum_single h]
  rw [map_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  have : (Pi.single i (h i) : Fin n → ℝ) = h i • (Pi.single i (1 : ℝ) : Fin n → ℝ) := by
    ext j
    by_cases hj : j = i
    · subst hj; simp
    · simp [hj]
  rw [this, map_smul, smul_eq_mul, mul_comm]

lemma hasDerivAt_along_line {n : ℕ} (W : (Fin n → ℝ) → ℝ) (x h : Fin n → ℝ) (t : ℝ)
    (hW : DifferentiableAt ℝ W (x + t • h)) :
    HasDerivAt (fun s : ℝ => W (x + s • h)) (∑ i, partialSlope i W (x + t • h) * h i) t := by
  have hl : HasDerivAt (fun s : ℝ => x + s • h) h t := by
    simpa using ((hasDerivAt_id t).smul_const h).const_add x
  have := hW.hasFDerivAt.comp_hasDerivAt t hl
  exact this.congr_deriv (clm_apply_eq_sum_single _ h)

lemma partialSlope_partialSlope_eq {n : ℕ} (W : (Fin n → ℝ) → ℝ) (y : Fin n → ℝ) (i j : Fin n)
    (hd : DifferentiableAt ℝ (fderiv ℝ W) y) :
    partialSlope i (partialSlope j W) y
      = fderiv ℝ (fderiv ℝ W) y (Pi.single i 1) (Pi.single j 1) := by
  show fderiv ℝ (fun y => fderiv ℝ W y (Pi.single j 1)) y (Pi.single i 1) = _
  rw [fderiv_clm_apply hd (differentiableAt_const _)]
  simp

lemma taylor3_lagrange_unit (g0 g1 g2 g3 : ℝ → ℝ)
    (d0 : ∀ s ∈ Icc (0 : ℝ) 1, HasDerivAt g0 (g1 s) s)
    (d1 : ∀ s ∈ Icc (0 : ℝ) 1, HasDerivAt g1 (g2 s) s)
    (d2 : ∀ s ∈ Icc (0 : ℝ) 1, HasDerivAt g2 (g3 s) s) :
    ∃ c ∈ Ioo (0 : ℝ) 1, g0 1 = g0 0 + g1 0 + g2 0 / 2 + g3 c / 6 := by
  have dφ : ∀ t ∈ Icc (0 : ℝ) 1, HasDerivAt
      (fun t => g0 1 - (g0 t + g1 t * (1 - t) + g2 t * (1 - t) ^ 2 / 2))
      (-(g3 t * (1 - t) ^ 2 / 2)) t := by
    intro t ht
    have e1 : HasDerivAt (fun t : ℝ => 1 - t) (-1) t := by
      simpa using (hasDerivAt_id t).const_sub 1
    have := (hasDerivAt_const t (g0 1)).sub
      (((d0 t ht).add ((d1 t ht).mul e1)).add (((d2 t ht).mul (e1.pow 2)).div_const 2))
    convert this using 1
    simp only [Pi.pow_apply, Nat.cast_ofNat]
    ring
  have dψ : ∀ t : ℝ, HasDerivAt (fun t : ℝ => (1 - t) ^ 3) (-(3 * (1 - t) ^ 2)) t := by
    intro t
    have e1 : HasDerivAt (fun t : ℝ => 1 - t) (-1) t := by
      simpa using (hasDerivAt_id t).const_sub 1
    convert e1.pow 3 using 1
    simp only [Nat.cast_ofNat]
    ring
  obtain ⟨c, hc, hcE⟩ := exists_ratio_hasDerivAt_eq_ratio_slope
    (fun t => g0 1 - (g0 t + g1 t * (1 - t) + g2 t * (1 - t) ^ 2 / 2))
    (fun t => -(g3 t * (1 - t) ^ 2 / 2)) zero_lt_one
    (fun t ht => (dφ t ht).continuousAt.continuousWithinAt)
    (fun t ht => dφ t (Ioo_subset_Icc_self ht))
    (fun t : ℝ => (1 - t) ^ 3) (fun t => -(3 * (1 - t) ^ 2))
    (fun t _ => (dψ t).continuousAt.continuousWithinAt)
    (fun t _ => dψ t)
  refine ⟨c, hc, ?_⟩
  have hne : (1 - c) ^ 2 ≠ 0 := pow_ne_zero 2 (sub_ne_zero.mpr (ne_of_gt hc.2))
  have key : (g0 1 - (g0 0 + g1 0 + g2 0 / 2 + g3 c / 6)) * (1 - c) ^ 2 = 0 := by
    linear_combination (-1 / 3 : ℝ) * hcE
  have := (mul_eq_zero.mp key).resolve_right hne
  linarith

lemma sum_half_pure_add_cross {n : ℕ} (a : Fin n → Fin n → ℝ) (ha : ∀ i j, a i j = a j i)
    (u : Fin n → ℝ) :
    ∑ i, (1 / 2) * a i i * u i ^ 2
      + ∑ i, ∑ j ∈ Finset.univ.filter (fun j => i < j), a i j * u i * u j
      = (1 / 2) * ∑ i, ∑ j, a i j * u i * u j := by
  set f : Fin n → Fin n → ℝ := fun i j => a i j * u i * u j with hf
  have hfs : ∀ i j, f i j = f j i := by intro i j; simp only [hf]; rw [ha]; ring
  have split : ∀ i j, f i j = (if i < j then f i j else 0) + (if i = j then f i j else 0)
      + (if j < i then f i j else 0) := by
    intro i j
    rcases lt_trichotomy i j with hij | hij | hij
    · simp [hij, hij.ne, not_lt_of_gt hij]
    · subst hij; simp
    · simp [hij, hij.ne', not_lt_of_gt hij]
  have hsum : ∑ i, ∑ j, f i j = ∑ i, ∑ j, (if i < j then f i j else 0) + ∑ i, f i i
      + ∑ i, ∑ j, (if j < i then f i j else 0) := by
    simp_rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    conv_lhs => rw [Finset.sum_congr rfl (fun j _ => split i j)]
    rw [Finset.sum_add_distrib, Finset.sum_add_distrib]
    congr 2
    simp
  have hswap : ∑ i, ∑ j, (if j < i then f i j else 0)
      = ∑ i, ∑ j, (if i < j then f i j else 0) := by
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    rw [hfs]
  have hfilt : ∀ i, ∑ j ∈ Finset.univ.filter (fun j => i < j), f i j
      = ∑ j, (if i < j then f i j else 0) := fun i => Finset.sum_filter _ _
  have hfilt' : ∀ i, ∑ j ∈ Finset.univ.filter (fun j => i < j), a i j * u i * u j
      = ∑ j, (if i < j then f i j else 0) := hfilt
  have hpure : ∀ i, (1 / 2) * a i i * u i ^ 2 = (1 / 2) * f i i := by
    intro i; simp only [hf]; ring
  rw [Finset.sum_congr rfl (fun i _ => hpure i), Finset.sum_congr rfl (fun i _ => hfilt' i)]
  change _ = (1 / 2) * ∑ i, ∑ j, f i j
  rw [hsum, hswap, ← Finset.mul_sum]
  ring

lemma sum3_scale {n : ℕ} (a : Fin n → Fin n → Fin n → ℝ) (u : Fin n → ℝ) (k : ℝ) :
    ∑ i, ∑ j, ∑ l, a i j l * (k * u i) * (k * u j) * (k * u l)
      = k ^ 3 * ∑ i, ∑ j, ∑ l, a i j l * u i * u j * u l := by
  simp only [Finset.mul_sum]
  exact Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ =>
    Finset.sum_congr rfl fun l _ => by ring

lemma cross_bend_aux {n : ℕ} (V : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ)
    (hV : ContDiffAt ℝ 2 V x) (i j : Fin n) :
    partialSlope i (partialSlope j V) x = partialSlope j (partialSlope i V) x := by
  have hd : DifferentiableAt ℝ (fderiv ℝ V) x :=
    (hV.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  rw [partialSlope_partialSlope_eq V x i j hd, partialSlope_partialSlope_eq V x j i hd]
  exact hV.isSymmSndFDerivAt (by simp) _ _

lemma lagrange_remainder_aux {n : ℕ} (V : (Fin n → ℝ) → ℝ) (x h : Fin n → ℝ)
    (hV : ∀ k ∈ Icc (0 : ℝ) 1, ContDiffAt ℝ 3 V (x + k • h)) :
    ∃ c ∈ Ioo (0 : ℝ) 1,
      V (x + h) = V x + ∑ i, partialSlope i V x * h i
        + (1 / 2) * ∑ i, ∑ j, partialSlope i (partialSlope j V) x * h i * h j
        + (1 / 6) * ∑ i, ∑ j, ∑ l,
            partialSlope i (partialSlope j (partialSlope l V)) (x + c • h) * h i * h j * h l := by
  have hd : ∀ s ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ V (x + s • h)
      ∧ (∀ l, DifferentiableAt ℝ (partialSlope l V) (x + s • h))
      ∧ ∀ j l, DifferentiableAt ℝ (partialSlope j (partialSlope l V)) (x + s • h) := by
    intro s hs
    have h3 := hV s hs
    have h2 : ∀ l, ContDiffAt ℝ 2 (partialSlope l V) (x + s • h) :=
      fun l => partialSlope_contDiffAt l h3 (by norm_num)
    exact ⟨h3.differentiableAt (by norm_num), fun l => (h2 l).differentiableAt (by norm_num),
      fun j l => (partialSlope_contDiffAt (m := 1) j (h2 l) (by norm_num)).differentiableAt (by norm_num)⟩
  obtain ⟨c, hc, hT⟩ := taylor3_lagrange_unit
    (fun s => V (x + s • h))
    (fun s => ∑ l, partialSlope l V (x + s • h) * h l)
    (fun s => ∑ j, ∑ l, partialSlope j (partialSlope l V) (x + s • h) * h j * h l)
    (fun s => ∑ i, ∑ j, ∑ l,
      partialSlope i (partialSlope j (partialSlope l V)) (x + s • h) * h i * h j * h l)
    (fun s hs => hasDerivAt_along_line V x h s (hd s hs).1)
    (fun s hs => by
      have := HasDerivAt.sum (u := Finset.univ) (fun l _ =>
        (hasDerivAt_along_line (partialSlope l V) x h s ((hd s hs).2.1 l)).mul_const (h l))
      convert this using 1
      · ext y; simp
      · simp only [Finset.sum_mul]; rw [Finset.sum_comm])
    (fun s hs => by
      have := HasDerivAt.sum (u := Finset.univ) (fun j _ => HasDerivAt.sum (u := Finset.univ)
        (fun l _ => ((hasDerivAt_along_line (partialSlope j (partialSlope l V)) x h s
          ((hd s hs).2.2 j l)).mul_const (h j)).mul_const (h l)))
      convert this using 1
      · ext y; simp
      · simp only [Finset.sum_mul]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun j _ => ?_
        rw [Finset.sum_comm])
  refine ⟨c, hc, ?_⟩
  simp only [one_smul, zero_smul, add_zero] at hT
  rw [hT]
  ring

#print axioms partialSlope_contDiffAt
#print axioms clm_apply_eq_sum_single
#print axioms hasDerivAt_along_line
#print axioms partialSlope_partialSlope_eq
#print axioms taylor3_lagrange_unit
#print axioms sum_half_pure_add_cross
#print axioms sum3_scale
#print axioms cross_bend_aux
#print axioms lagrange_remainder_aux

/-- **A move's profit and loss as a second-order Taylor expansion, with an error that shrinks
like the cube of the move** (The formula; Why it works, Steps 1, 2 and 4; Detailed proof).
Let the price `V` depend on `n` inputs and be smooth near today's inputs `x`: three rounds of
slopes exist and are continuous near `x`. Scale a move `h` by `k`. Then the change
`V(x + k h) - V(x)` equals the sum of each slope times its input's move `k hᵢ`, plus half of
each pure bend times its move squared, plus each cross bend (such as vanna) once times the two
moves, plus a leftover `R₃(k)`; and `R₃(k) / k³` tends to `(1/6) g'''(0)` as `k → 0`, where
`g'''(0) = Σᵢⱼₗ ∂ᵢ∂ⱼ∂ₗV(x) hᵢ hⱼ hₗ` is the third slope of the price along the move. -/
theorem greeks_taylor_pnl_error_is_cubic {n : ℕ} (V : (Fin n → ℝ) → ℝ) (x h : Fin n → ℝ)
    (hV : ContDiffAt ℝ 3 V x) :
    Tendsto
      (fun k : ℝ =>
        (V (x + k • h) -
            (V x + ∑ i, partialSlope i V x * (k * h i)
              + ∑ i, (1 / 2) * partialSlope i (partialSlope i V) x * (k * h i) ^ 2
              + ∑ i, ∑ j ∈ Finset.univ.filter (fun j => i < j),
                  partialSlope i (partialSlope j V) x * (k * h i) * (k * h j))) / k ^ 3)
      (𝓝[≠] 0)
      (𝓝 ((1 / 6) * ∑ i, ∑ j, ∑ l,
        partialSlope i (partialSlope j (partialSlope l V)) x * h i * h j * h l)) := by
  obtain ⟨δ2, hδ2, hball⟩ := Metric.eventually_nhds_iff.mp (hV.eventually (by simp))
  set F : (Fin n → ℝ) → ℝ := fun y => (1 / 6) * ∑ i, ∑ j, ∑ l,
    partialSlope i (partialSlope j (partialSlope l V)) y * h i * h j * h l with hF
  have h0 : ∀ i j l, ContinuousAt (partialSlope i (partialSlope j (partialSlope l V))) x :=
    fun i j l => (partialSlope_contDiffAt (m := 0) i (partialSlope_contDiffAt (m := 1) j
      (partialSlope_contDiffAt (m := 2) l hV (by norm_num)) (by norm_num))
      (by norm_num)).continuousAt
  have hFc : ContinuousAt F x := by
    simp only [hF]
    fun_prop
  have hsym : ∀ i j, partialSlope i (partialSlope j V) x = partialSlope j (partialSlope i V) x :=
    fun i j => cross_bend_aux V x (hV.of_le (by norm_num)) i j
  rw [Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  obtain ⟨δ1, hδ1, hF1⟩ := Metric.continuousAt_iff.mp hFc ε hε
  refine ⟨min δ1 δ2 / (‖h‖ + 1), by positivity, fun {k} hk hkd => ?_⟩
  have hk0 : k ≠ 0 := by simpa using hk
  rw [Real.dist_eq, sub_zero] at hkd
  have hkh : |k| * ‖h‖ < min δ1 δ2 := by
    have := (lt_div_iff₀ (by positivity)).mp hkd
    nlinarith [abs_nonneg k, norm_nonneg h]
  have hnear : ∀ t ∈ Icc (0 : ℝ) 1, dist (x + t • (k • h)) x ≤ |k| * ‖h‖ := by
    intro t ht
    rw [dist_eq_norm, add_sub_cancel_left, norm_smul, norm_smul, Real.norm_eq_abs,
      Real.norm_eq_abs, abs_of_nonneg ht.1]
    nlinarith [ht.2, abs_nonneg k, norm_nonneg h, mul_nonneg (abs_nonneg k) (norm_nonneg h)]
  obtain ⟨c, hc, hT⟩ := lagrange_remainder_aux V x (k • h)
    (fun t ht => hball (lt_of_le_of_lt (hnear t ht) (lt_of_lt_of_le hkh (min_le_right _ _))))
  have hcomb := sum_half_pure_add_cross (fun i j => partialSlope i (partialSlope j V) x) hsym
    (fun i => k * h i)
  have hcube := sum3_scale
    (fun i j l => partialSlope i (partialSlope j (partialSlope l V)) (x + c • (k • h))) h k
  beta_reduce at hcomb hcube
  simp only [Pi.smul_apply, smul_eq_mul] at hT
  have hlt := hF1 (lt_of_le_of_lt (hnear c ⟨hc.1.le, hc.2.le⟩) (lt_of_lt_of_le hkh (min_le_left _ _)))
  convert hlt using 2
  rw [div_eq_iff (pow_ne_zero 3 hk0)]
  simp only [hF]
  linear_combination hT - hcomb + (1 / 6 : ℝ) * hcube

/-- **The exact form of the leftover** (Detailed proof, Lagrange remainder). If the price has
continuous third slopes near every point of the straight path from today's inputs `x` to next
evening's `x + h`, then for some point `x + c h` strictly inside the path (`0 < c < 1`),
`V(x + h) = V(x) + Σᵢ ∂ᵢV(x) hᵢ + (1/2) Σᵢⱼ ∂ᵢ∂ⱼV(x) hᵢ hⱼ + (1/6) Σᵢⱼₗ ∂ᵢ∂ⱼ∂ₗV(x + c h) hᵢ hⱼ hₗ`. -/
theorem greeks_taylor_pnl_lagrange_remainder {n : ℕ} (V : (Fin n → ℝ) → ℝ) (x h : Fin n → ℝ)
    (hV : ∀ k ∈ Icc (0 : ℝ) 1, ContDiffAt ℝ 3 V (x + k • h)) :
    ∃ c ∈ Ioo (0 : ℝ) 1,
      V (x + h) = V x + ∑ i, partialSlope i V x * h i
        + (1 / 2) * ∑ i, ∑ j, partialSlope i (partialSlope j V) x * h i * h j
        + (1 / 6) * ∑ i, ∑ j, ∑ l,
            partialSlope i (partialSlope j (partialSlope l V)) (x + c • h) * h i * h j * h l := by
  exact lagrange_remainder_aux V x h hV

/-- **A cross bend is the same in either order** (Why it works, Step 2). For a price with two
rounds of continuous slopes near `x`, moving input `i` then input `j` gives the same second slope
as moving `j` then `i`: for example, vanna is the change of delta with volatility and also the
change of vega with the share price. This is why each cross term appears twice in the bend and
once, without a half, in the card's formula. -/
theorem cross_bend_same_in_either_order {n : ℕ} (V : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ)
    (hV : ContDiffAt ℝ 2 V x) (i j : Fin n) :
    partialSlope i (partialSlope j V) x = partialSlope j (partialSlope i V) x := by
  exact cross_bend_aux V x hV i j

-- The card's exact numbers.
-- Four slopes and ten bends (4 pure, 6 cross pairs): fourteen terms in all.
example : 4 + Nat.choose 4 2 + 4 = 14 ∧ Nat.choose 5 2 = 10 := by decide
-- The cross term's half cancels: (1/2) × 2 = 1.
example : (1 / 2 : ℚ) * 2 = 1 := by norm_num
-- The share move squared: 5^2 = 25.
example : (5 : ℕ) ^ 2 = 25 := by decide
-- One vol point is 1/100 of volatility; 20% + 1 point = 21%.
example : (20 / 100 : ℚ) + 1 / 100 = 21 / 100 := by norm_num
-- One day is 1/365 of a year; after it, 364 days are left.
example : (1 : ℚ) - 1 / 365 = 364 / 365 := by norm_num
-- The cube law: double the move and the error grows eightfold; four times the move, 64-fold.
example : (2 : ℕ) ^ 3 = 8 ∧ (4 : ℕ) ^ 3 = 64 := by decide
-- The scaled moves k = 1/2, 1, 2, 4: spot +5k = 5/2, 5, 10, 20 dollars.
example : (5 : ℚ) * (1 / 2) = 5 / 2 ∧ (5 : ℚ) * 2 = 10 ∧ (5 : ℚ) * 4 = 20 := by norm_num
-- A typical day's move squared, σ² S² (before × dt): (0.20 × 100)^2 = 400.
example : ((20 / 100 : ℚ) * 100) ^ 2 = 400 := by norm_num

#print axioms greeks_taylor_pnl_error_is_cubic
#print axioms greeks_taylor_pnl_lagrange_remainder
#print axioms cross_bend_same_in_either_order
