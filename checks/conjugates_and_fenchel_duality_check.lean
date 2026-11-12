-- Convex conjugates: for convex real-valued costs the cheapest plan equals the best price bound (Fenchel duality), cost plus conjugate never falls below price times amount with a tie exactly at a slope (Fenchel-Young), the card's quadratic and kinked-fine conjugates are exact, and the roaster's numbers check out.
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.Convex.Function
import Mathlib.Data.EReal.Operations
import Mathlib.Data.EReal.Inv
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Convex.Continuous
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Analysis.InnerProductSpace.Dual

open ContinuousLinearMap

/-- The convex conjugate of a cost `f`: at the price list `y`, the largest value of revenue
`⟪y, x⟫` minus cost `f x` over every amount `x`. It may be `+∞` (`⊤`) when profit has no
ceiling, so it takes values in the extended reals. -/
noncomputable def conj {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (y : E) : EReal :=
  ⨆ x : E, ((inner ℝ y x - f x : ℝ) : EReal)

lemma conj_le_coe_iff {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (y : E) (r : ℝ) :
    conj f y ≤ (r : EReal) ↔ ∀ x, inner ℝ y x - f x ≤ r := by
  unfold conj
  simp only [iSup_le_iff, EReal.coe_le_coe_iff]

lemma coe_le_conj {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (y x : E) : ((inner ℝ y x - f x : ℝ) : EReal) ≤ conj f y :=
  le_iSup (fun x : E => ((inner ℝ y x - f x : ℝ) : EReal)) x

lemma ereal_neg_sub_le {a b : EReal} {r s t : ℝ} (ha : (r : EReal) ≤ a) (hb : (s : EReal) ≤ b)
    (h : -r - s = t) : -a - b ≤ (t : EReal) := by
  have h1 : -a ≤ ((-r : ℝ) : EReal) := by
    rw [EReal.coe_neg, EReal.neg_le_neg_iff]; exact ha
  calc -a - b ≤ ((-r : ℝ) : EReal) - (s : EReal) := EReal.sub_le_sub h1 hb
    _ = (t : EReal) := by rw [← EReal.coe_sub, h]

lemma exists_dual_certificate {E F : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [NormedAddCommGroup F] [InnerProductSpace ℝ F] [FiniteDimensional ℝ F]
    (f : E → ℝ) (g : F → ℝ) (hf : ConvexOn ℝ Set.univ f) (hg : ConvexOn ℝ Set.univ g)
    (A : E →L[ℝ] F) (p : ℝ) (hp : ∀ x, p ≤ f x + g (A x)) :
    ∃ y : F, ∀ x z, p + inner ℝ y (A x) - inner ℝ y z ≤ f x + g z := by
  have : CompleteSpace F := FiniteDimensional.complete ℝ F
  have hgc : Continuous g := hg.locallyLipschitz.continuous
  let C : Set (F × ℝ) := ⋃ x : E, {q | f x + g (A x + q.1) < q.2}
  have hmem : ∀ (x : E) (q : F × ℝ), f x + g (A x + q.1) < q.2 → q ∈ C := by
    intro x q h
    exact Set.mem_iUnion.2 ⟨x, h⟩
  have hCopen : IsOpen C := by
    refine isOpen_iUnion fun x => isOpen_lt ?_ continuous_snd
    exact continuous_const.add (hgc.comp (continuous_const.add continuous_fst))
  have hCconv : Convex ℝ C := by
    intro a ha b hb s t hs ht hst
    obtain ⟨x1, h1⟩ := Set.mem_iUnion.1 ha
    obtain ⟨x2, h2⟩ := Set.mem_iUnion.1 hb
    simp only [Set.mem_ofPred_eq] at h1 h2
    refine hmem (s • x1 + t • x2) _ ?_
    have hfx := hf.2 (Set.mem_univ x1) (Set.mem_univ x2) hs ht hst
    have hgx := hg.2 (Set.mem_univ (A x1 + a.1)) (Set.mem_univ (A x2 + b.1)) hs ht hst
    have key : A (s • x1 + t • x2) + (s • a + t • b).1 = s • (A x1 + a.1) + t • (A x2 + b.1) := by
      simp only [map_add, map_smul, Prod.fst_add, Prod.smul_fst, smul_add]
      abel
    rw [key]
    simp only [Prod.snd_add, Prod.smul_snd, smul_eq_mul] at hfx hgx ⊢
    have hst' : 0 < s ∨ 0 < t := by
      by_contra hc
      push_neg at hc
      linarith
    rcases hst' with hs0 | ht0
    · nlinarith [mul_pos hs0 (sub_pos.2 h1), mul_nonneg ht (sub_pos.2 h2).le]
    · nlinarith [mul_pos ht0 (sub_pos.2 h2), mul_nonneg hs (sub_pos.2 h1).le]
  have hnot : ((0 : F), p) ∉ C := by
    intro h
    obtain ⟨x, hx⟩ := Set.mem_iUnion.1 h
    simp only [Set.mem_ofPred_eq, add_zero] at hx
    linarith [hp x]
  obtain ⟨φ, hφ⟩ := geometric_hahn_banach_open_point hCconv hCopen hnot
  have hsplit : ∀ (u : F) (t : ℝ), φ (u, t) = φ (u, 0) + t * φ (0, 1) := by
    intro u t
    rw [← smul_eq_mul, ← map_smul, ← map_add]
    congr 1
    ext <;> simp
  have hφ00 : φ ((0 : F), (0 : ℝ)) = 0 := by rw [Prod.mk_zero_zero, map_zero]
  set c := φ (0, 1) with hc
  have hφ0 : φ ((0 : F), p) = p * c := by
    rw [hsplit, hφ00, zero_add]
  have hlt : ∀ (x : E) (u : F) (t : ℝ), f x + g (A x + u) < t → φ (u, 0) + t * c < p * c := by
    intro x u t h
    have := hφ (u, t) (hmem x (u, t) h)
    rw [hsplit, hφ0] at this
    exact this
  have hcneg : c < 0 := by
    by_contra hc0
    push_neg at hc0
    have h := hlt 0 0 (max p (f 0 + g (A 0 + 0)) + 1) (by linarith [le_max_right p (f 0 + g (A 0 + 0))])
    have h2 : p * c ≤ (max p (f 0 + g (A 0 + 0)) + 1) * c :=
      mul_le_mul_of_nonneg_right (by linarith [le_max_left p (f 0 + g (A 0 + 0))]) hc0
    rw [hφ00] at h
    linarith
  have hle : ∀ (x : E) (u : F), φ (u, 0) + (f x + g (A x + u)) * c ≤ p * c := by
    intro x u
    by_contra hcon
    push_neg at hcon
    set X := φ (u, 0) + (f x + g (A x + u)) * c - p * c with hX
    have hXpos : 0 < X := by linarith
    have h := hlt x u (f x + g (A x + u) + X / (2 * -c)) (by
      have : 0 < X / (2 * -c) := div_pos hXpos (by linarith)
      linarith)
    have hcne : c ≠ 0 := hcneg.ne
    have hd : X / (2 * -c) * c = -(X / 2) := by
      field_simp
    have : φ (u, 0) + (f x + g (A x + u) + X / (2 * -c)) * c = p * c + X / 2 := by
      rw [add_mul, hd]; linarith
    linarith
  set y0 : F := (InnerProductSpace.toDual ℝ F).symm (φ.comp (ContinuousLinearMap.inl ℝ F ℝ))
    with hy0
  have hin : ∀ w : F, inner ℝ y0 w = φ (w, 0) := by
    intro w
    rw [hy0, InnerProductSpace.toDual_symm_apply]
    simp
  refine ⟨(1 / c) • y0, fun x z => ?_⟩
  rw [real_inner_smul_left, real_inner_smul_left, hin, hin]
  have h := hle x (z - A x)
  rw [add_sub_cancel] at h
  have hsub : φ (z - A x, 0) = φ (z, 0) - φ (A x, 0) := by
    rw [← map_sub]; congr 1; ext <;> simp
  rw [hsub] at h
  have hcne : c ≠ 0 := hcneg.ne
  rw [show p + 1 / c * φ (A x, 0) - 1 / c * φ (z, 0) = (p * c + φ (A x, 0) - φ (z, 0)) / c by
    field_simp]
  rw [div_le_iff_of_neg hcneg]
  linarith

#print axioms conj_le_coe_iff
#print axioms coe_le_conj
#print axioms ereal_neg_sub_le
#print axioms exists_dual_certificate

/-- **Fenchel duality.** Let `f` and `g` be convex costs that are finite everywhere, on spaces
of amounts with finitely many coordinates, and let `A` be a linear map (a matrix) from plans to
deliveries. Then the cheapest plan `p* = inf_x (f x + g (A x))` equals the best price bound
`d* = sup_y (-f*(Aᵀ y) - g*(-y))`, and some price `y` reaches that best bound. Since both costs
are finite everywhere, every plan lies inside where both are finite, and a convex function that is
finite everywhere on such a space is automatically closed. -/
theorem fenchel_duality_no_gap
    {E F : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
    [NormedAddCommGroup F] [InnerProductSpace ℝ F] [FiniteDimensional ℝ F]
    (f : E → ℝ) (g : F → ℝ) (hf : ConvexOn ℝ Set.univ f) (hg : ConvexOn ℝ Set.univ g)
    (A : E →L[ℝ] F) :
    (⨅ x : E, ((f x + g (A x) : ℝ) : EReal)) = ⨆ y : F, (-(conj f (adjoint A y)) - conj g (-y)) ∧
      ∃ y : F, (⨆ y' : F, (-(conj f (adjoint A y')) - conj g (-y'))) =
        -(conj f (adjoint A y)) - conj g (-y) := by
  have weak : ∀ (y : F) (x : E),
      -(conj f (adjoint A y)) - conj g (-y) ≤ ((f x + g (A x) : ℝ) : EReal) := by
    intro y x
    have h1 := coe_le_conj f (adjoint A y) x
    have h2 := coe_le_conj g (-y) (A x)
    rw [adjoint_inner_left] at h1
    rw [inner_neg_left] at h2
    exact ereal_neg_sub_le h1 h2 (by ring)
  have hsup : (⨆ y : F, (-(conj f (adjoint A y)) - conj g (-y))) ≤
      ⨅ x : E, ((f x + g (A x) : ℝ) : EReal) :=
    iSup_le fun y => le_iInf fun x => weak y x
  by_cases hP : (⨅ x : E, ((f x + g (A x) : ℝ) : EReal)) = ⊥
  · rw [hP] at hsup ⊢
    have hall : ∀ y : F, -(conj f (adjoint A y)) - conj g (-y) = ⊥ := fun y =>
      le_bot_iff.1 ((le_iSup (fun y : F => -(conj f (adjoint A y)) - conj g (-y)) y).trans hsup)
    refine ⟨(le_bot_iff.1 hsup).symm, 0, ?_⟩
    rw [le_bot_iff.1 hsup, hall 0]
  · have hPtop : (⨅ x : E, ((f x + g (A x) : ℝ) : EReal)) ≠ ⊤ :=
      ne_top_of_le_ne_top (EReal.coe_ne_top _) (iInf_le _ 0)
    set p := (⨅ x : E, ((f x + g (A x) : ℝ) : EReal)).toReal with hpdef
    have hp : (⨅ x : E, ((f x + g (A x) : ℝ) : EReal)) = (p : EReal) :=
      (EReal.coe_toReal hPtop hP).symm
    have hpx : ∀ x, p ≤ f x + g (A x) := by
      intro x
      have := iInf_le (fun x : E => ((f x + g (A x) : ℝ) : EReal)) x
      rw [hp] at this
      exact EReal.coe_le_coe_iff.1 this
    obtain ⟨y, hy⟩ := exists_dual_certificate f g hf hg A p hpx
    -- bound the first conjugate
    have hb1 : ∀ z : F, conj f (adjoint A y) ≤ ((g z + inner ℝ y z - p : ℝ) : EReal) := by
      intro z
      rw [conj_le_coe_iff]
      intro x
      rw [adjoint_inner_left]
      linarith [hy x z]
    have hf1 : conj f (adjoint A y) ≠ ⊤ := ne_top_of_le_ne_top (EReal.coe_ne_top _) (hb1 0)
    have hf2 : conj f (adjoint A y) ≠ ⊥ :=
      ne_bot_of_le_ne_bot (EReal.coe_ne_bot _) (coe_le_conj f (adjoint A y) 0)
    set a := (conj f (adjoint A y)).toReal with hadef
    have ha : conj f (adjoint A y) = (a : EReal) := (EReal.coe_toReal hf1 hf2).symm
    have ha' : ∀ z : F, a ≤ g z + inner ℝ y z - p := by
      intro z
      have := hb1 z
      rw [ha] at this
      exact EReal.coe_le_coe_iff.1 this
    have hb2 : conj g (-y) ≤ ((-p - a : ℝ) : EReal) := by
      rw [conj_le_coe_iff]
      intro z
      rw [inner_neg_left]
      linarith [ha' z]
    have hg1 : conj g (-y) ≠ ⊤ := ne_top_of_le_ne_top (EReal.coe_ne_top _) hb2
    have hg2 : conj g (-y) ≠ ⊥ :=
      ne_bot_of_le_ne_bot (EReal.coe_ne_bot _) (coe_le_conj g (-y) 0)
    set b := (conj g (-y)).toReal with hbdef
    have hb : conj g (-y) = (b : EReal) := (EReal.coe_toReal hg1 hg2).symm
    have hb' : b ≤ -p - a := by
      rw [hb] at hb2
      exact EReal.coe_le_coe_iff.1 hb2
    have hDy : (p : EReal) ≤ -(conj f (adjoint A y)) - conj g (-y) := by
      rw [ha, hb, ← EReal.coe_neg, ← EReal.coe_sub, EReal.coe_le_coe_iff]
      linarith
    have hDle := le_iSup (fun y' : F => -(conj f (adjoint A y')) - conj g (-y')) y
    refine ⟨le_antisymm (hp ▸ hDy.trans hDle) hsup, y, ?_⟩
    exact le_antisymm (hsup.trans (hp ▸ hDy)) hDle

/-- **Fenchel-Young.** For any cost `f` (convex or not), any amount `x` and any price `y`, cost
plus conjugate is never below revenue: `f x + f*(y) ≥ ⟪y, x⟫`. The two are equal exactly when
`y` is a slope of a line touching `f` from below at `x` (a subgradient):
`f x' ≥ f x + ⟪y, x' - x⟫` for every other amount `x'`. -/
theorem fenchel_young_with_tie {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (x y : E) :
    ((inner ℝ y x : ℝ) : EReal) ≤ (f x : EReal) + conj f y ∧
      ((f x : EReal) + conj f y = ((inner ℝ y x : ℝ) : EReal) ↔
        ∀ x' : E, f x + inner ℝ y (x' - x) ≤ f x') := by
  have hlow := coe_le_conj f y x
  refine ⟨?_, ?_⟩
  · calc ((inner ℝ y x : ℝ) : EReal) = (f x : EReal) + ((inner ℝ y x - f x : ℝ) : EReal) := by
          rw [← EReal.coe_add]; congr 1; ring
      _ ≤ (f x : EReal) + conj f y := add_le_add_right hlow _
  · constructor
    · intro h x'
      have hle : conj f y ≤ ((inner ℝ y x - f x : ℝ) : EReal) := by
        cases hc : conj f y using EReal.rec with
        | bot => exact bot_le
        | top =>
          rw [hc] at h
          simp at h
        | coe r =>
          rw [hc, ← EReal.coe_add, EReal.coe_eq_coe_iff] at h
          rw [EReal.coe_le_coe_iff]
          linarith
      have := (conj_le_coe_iff f y _).1 hle x'
      rw [inner_sub_right]
      linarith
    · intro h
      have hle : conj f y ≤ ((inner ℝ y x - f x : ℝ) : EReal) := by
        rw [conj_le_coe_iff]
        intro x'
        have := h x'
        rw [inner_sub_right] at this
        linarith
      rw [le_antisymm hle hlow, ← EReal.coe_add]
      congr 1
      ring

/-- **The two conjugates the card computes.** A quadratic cost with base price `c` and climb
`q > 0`, `f x = c x + (q/2) x²`, has conjugate `(y - c)² / (2q)` at every price `y`. A fine of
`k` per unit off a target `D`, `g z = k |z - D|`, has conjugate `D w` on the band `|w| ≤ k` and
`+∞` outside it. -/
theorem conj_quadratic_and_kinked_fine (c q k D : ℝ) (hq : 0 < q) :
    (∀ y : ℝ, conj (fun x : ℝ => c * x + q / 2 * x ^ 2) y = (((y - c) ^ 2 / (2 * q) : ℝ) : EReal)) ∧
      (∀ w : ℝ, conj (fun z : ℝ => k * |z - D|) w = if |w| ≤ k then ((D * w : ℝ) : EReal) else ⊤) := by
  refine ⟨fun y => ?_, fun w => ?_⟩
  · apply le_antisymm
    · rw [conj_le_coe_iff]
      intro x
      rw [Real.inner_apply, le_div_iff₀ (by positivity)]
      nlinarith [sq_nonneg (q * x - (y - c))]
    · refine le_trans (le_of_eq ?_) (coe_le_conj _ y ((y - c) / q))
      rw [EReal.coe_eq_coe_iff, Real.inner_apply]
      field_simp
      ring
  · split_ifs with hw
    · apply le_antisymm
      · rw [conj_le_coe_iff]
        intro z
        rw [Real.inner_apply]
        have h1 : w * (z - D) ≤ |w| * |z - D| := by rw [← abs_mul]; exact le_abs_self _
        have h2 : |w| * |z - D| ≤ k * |z - D| := mul_le_mul_of_nonneg_right hw (abs_nonneg _)
        nlinarith
      · refine le_trans (le_of_eq ?_) (coe_le_conj _ w D)
        rw [EReal.coe_eq_coe_iff, Real.inner_apply]
        simp
        ring
    · rw [EReal.eq_top_iff_forall_lt]
      intro M
      push_neg at hw
      have hpos : 0 < |w| - k := by linarith
      set t := (|M - D * w| + 1) / (|w| - k) with htdef
      have ht : t * (|w| - k) = |M - D * w| + 1 := div_mul_cancel₀ _ hpos.ne'
      have ht0 : 0 ≤ t := by positivity
      have hM := le_abs_self (M - D * w)
      rcases le_or_gt 0 w with h0 | h0
      · refine lt_of_lt_of_le ?_ (coe_le_conj _ w (D + t))
        rw [EReal.coe_lt_coe_iff, Real.inner_apply]
        rw [abs_of_nonneg h0] at ht
        have habs : |D + t - D| = t := by rw [add_sub_cancel_left]; exact abs_of_nonneg ht0
        simp only [habs]
        nlinarith
      · refine lt_of_lt_of_le ?_ (coe_le_conj _ w (D - t))
        rw [EReal.coe_lt_coe_iff, Real.inner_apply]
        rw [abs_of_neg h0] at ht
        have habs : |D - t - D| = t := by
          rw [sub_sub_cancel_left, abs_neg]; exact abs_of_nonneg ht0
        simp only [habs]
        nlinarith

/-! Worked numbers from the card, as exact fractions: climbs 0.1, 0.05, 0.2 are 1/10, 1/20, 1/5. -/

-- The price that clears 100 kg: 35 y - 285 = 100 at y = 11, offers 30, 40, 30 kg.
example : (11 - 8) / (1/10 : ℚ) = 30 ∧ (11 - 9) / (1/20 : ℚ) = 40 ∧ (11 - 5) / (1/5 : ℚ) = 30 ∧
    35 * (11 : ℚ) - 285 = 100 ∧ (30 : ℚ) + 40 + 30 = 100 := by norm_num
-- Costs 285, 400, 240 pounds; cheapest bill 925 with fine 0; average 9.25 pounds a kilo.
example : 8 * 30 + (1/10 : ℚ) / 2 * 30 ^ 2 = 285 ∧ 9 * 40 + (1/20 : ℚ) / 2 * 40 ^ 2 = 400 ∧
    5 * 30 + (1/5 : ℚ) / 2 * 30 ^ 2 = 240 ∧ (285 : ℚ) + 400 + 240 + 12 * |100 - 100| = 925 ∧
    (925 : ℚ) / 100 = 37/4 := by norm_num
-- Conjugates at 11: 45, 40, 90; dual value 100 x 11 - 175 = 925; Brazil sells 330 - 285 = 45.
example : (11 - 8) ^ 2 / (2 * (1/10 : ℚ)) = 45 ∧ (11 - 9) ^ 2 / (2 * (1/20 : ℚ)) = 40 ∧
    (11 - 5) ^ 2 / (2 * (1/5 : ℚ)) = 90 ∧ 100 * (11 : ℚ) - (45 + 40 + 90) = 925 ∧
    11 * (30 : ℚ) - 285 = 45 := by norm_num
-- The dual is the downward bowl 925 - 17.5 (y - 11)^2 at every price y.
example (y : ℚ) : 100 * y - ((y - 8) ^ 2 / (2 * (1/10)) + (y - 9) ^ 2 / (2 * (1/20)) +
    (y - 5) ^ 2 / (2 * (1/5))) = 925 - 35/2 * (y - 11) ^ 2 := by ring
-- Chart values at y = 9, 9.5, 10, 10.5: 855, 885.625, 907.5, 920.625.
example : (925 : ℚ) - 35/2 * (9 - 11) ^ 2 = 855 ∧ (925 : ℚ) - 35/2 * (19/2 - 11) ^ 2 = 7085/8 ∧
    (925 : ℚ) - 35/2 * (10 - 11) ^ 2 = 1815/2 ∧ (925 : ℚ) - 35/2 * (21/2 - 11) ^ 2 = 7365/8 := by
  norm_num
-- Certificate: marginal costs 8 + 3 = 9 + 2 = 5 + 6 = 11, and -11 lies in [-12, 12].
example : 8 + (1/10 : ℚ) * 30 = 11 ∧ 9 + (1/20 : ℚ) * 40 = 11 ∧ 5 + (1/5 : ℚ) * 30 = 11 ∧
    (-12 : ℚ) ≤ -11 ∧ (-11 : ℚ) ≤ 12 := by norm_num
-- Fenchel-Young for Brazil at 30 kg: tie at price 11 (285 + 45 = 330); at price 12, 285 + 80 = 365, 5 above 360.
example : (285 : ℚ) + 45 = 30 * 11 ∧ (12 - 8) ^ 2 / (2 * (1/10 : ℚ)) = 80 ∧ (285 : ℚ) + 80 - 30 * 12 = 5 := by
  norm_num
-- The kinked fine: g*(-11) = 100 x (-11) = -1100.
example : (100 : ℚ) * (-11) = -1100 := by norm_num
-- Fine of 10: orders 20, 20, 25 kg, 35 kg short, bill 907.50; the uncapped "bound" stays 925.
example : 8 * 20 + (1/10 : ℚ) / 2 * 20 ^ 2 + (9 * 20 + (1/20 : ℚ) / 2 * 20 ^ 2) +
    (5 * 25 + (1/5 : ℚ) / 2 * 25 ^ 2) + 10 * |(20 + 20 + 25 : ℚ) - 100| = 1815/2 := by norm_num
-- Wrong answers: no 1/2 gives Brazil 90 and a dual of 750; kilos fed to f* give f1*(30) = 2420.
example : (11 - 8) ^ 2 / (1/10 : ℚ) = 90 ∧
    1100 - ((11 - 8) ^ 2 / (1/10 : ℚ) + (11 - 9) ^ 2 / (1/20) + (11 - 5) ^ 2 / (1/5)) = 750 ∧
    (30 - 8) ^ 2 / (2 * (1/10 : ℚ)) = 2420 := by norm_num
-- 60 kg sacks: both plans cost 1030; the dual at 11 is 1100 - 45 - 40 - 0 = 1015; f3**(30) = 330.
example : 8 * 20 + (1/10 : ℚ) / 2 * 20 ^ 2 + (9 * 20 + (1/20 : ℚ) / 2 * 20 ^ 2) +
    (5 * 60 + (1/5 : ℚ) / 2 * 60 ^ 2) = 1030 ∧
    8 * 40 + (1/10 : ℚ) / 2 * 40 ^ 2 + (9 * 60 + (1/20 : ℚ) / 2 * 60 ^ 2) = 1030 ∧
    max 0 (60 * 11 - (5 * 60 + (1/5 : ℚ) / 2 * 60 ^ 2)) = 0 ∧ (1100 : ℚ) - 45 - 40 - 0 = 1015 ∧
    (5 * 60 + (1/5 : ℚ) / 2 * 60 ^ 2) / 2 = 330 := by norm_num
-- Brute force searched 101^3 whole-kilo orders.
example : 101 ^ 3 = 1030301 := by norm_num

#print axioms fenchel_duality_no_gap
#print axioms fenchel_young_with_tie
#print axioms conj_quadratic_and_kinked_fine
