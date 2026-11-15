-- Minimax: this file states that when one side is compact and convex and the payoff is convex for the minimiser and concave for the maximiser, the best worst case equals the worst best case, and that the penalty kick's mixed value is 4775/60 percent either way round.
import Mathlib.Analysis.Convex.Function
import Mathlib.Topology.Semicontinuity.Defs
import Mathlib.Topology.Algebra.Module.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Data.EReal.Basic
import Mathlib.Order.CompleteLattice.Basic
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Analysis.Convex.Jensen
import Mathlib.Data.EReal.Operations
import Mathlib.Topology.Semicontinuity.Basic
import Mathlib.Algebra.BigOperators.Field

open Set

/-- Finite step: if every point of `X` has some `y` in the finite set `u` with payoff at least
`c`, then a single mixed `y'` in `Y` gives payoff at least `c` at every point of `X`. -/
theorem minimax_finite_step
    {E G : Type*} [AddCommGroup E] [Module ℝ E] [AddCommGroup G] [Module ℝ G]
    {X : Set E} {Y : Set G} {F : E → G → ℝ}
    (hXne : X.Nonempty) (hXcvx : Convex ℝ X) (hYcvx : Convex ℝ Y)
    (hconvex : ∀ y ∈ Y, ConvexOn ℝ X fun x => F x y)
    (hconcave : ∀ x ∈ X, ConcaveOn ℝ Y (F x))
    (u : Finset G) (hu : ∀ y ∈ u, y ∈ Y) (c : ℝ)
    (h : ∀ x ∈ X, ∃ y ∈ u, c ≤ F x y) :
    ∃ y' ∈ Y, ∀ x ∈ X, c ≤ F x y' := by
  classical
  obtain ⟨x0, hx0⟩ := hXne
  let ι := {y // y ∈ u}
  let A : Set (ι → ℝ) := {z | ∃ x ∈ X, ∀ i : ι, F x i ≤ z i}
  let B : Set (ι → ℝ) := Set.pi univ (fun _ => Iio c)
  have hAcvx : Convex ℝ A := by
    rintro z1 ⟨x1, hx1, h1⟩ z2 ⟨x2, hx2, h2⟩ a b ha hb hab
    refine ⟨a • x1 + b • x2, hXcvx hx1 hx2 ha hb hab, fun i => ?_⟩
    have := (hconvex i (hu i i.2)).2 hx1 hx2 ha hb hab
    simp only [smul_eq_mul] at this
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    nlinarith [h1 i, h2 i]
  have hBcvx : Convex ℝ B := convex_pi (fun _ _ => convex_Iio c)
  have hBopen : IsOpen B := isOpen_set_pi finite_univ (fun _ _ => isOpen_Iio)
  have hdisj : Disjoint B A := by
    rw [Set.disjoint_left]
    rintro z hzB ⟨x, hx, hz⟩
    obtain ⟨y, hy, hcy⟩ := h x hx
    have := hzB ⟨y, hy⟩ (mem_univ _)
    have := hz ⟨y, hy⟩
    simp only [mem_Iio] at *
    linarith
  obtain ⟨f, s0, hfB, hfA⟩ := geometric_hahn_banach_open hBcvx hBopen hAcvx hdisj
  let fl : (ι → ℝ) →ₗ[ℝ] ℝ := f.toLinearMap
  let w : ι → ℝ := fun i => f (fun j => if i = j then 1 else 0)
  have hf : ∀ z, f z = ∑ i, z i * w i := by
    intro z
    have := LinearMap.pi_apply_eq_sum_univ fl z
    simpa [fl, w, smul_eq_mul] using this
  have hb0 : (fun i : ι => F x0 i) ∈ A := ⟨x0, hx0, fun i => le_rfl⟩
  have hw0 : ∀ i, 0 ≤ w i := by
    intro i
    by_contra hneg
    push Not at hneg
    set b0 : ι → ℝ := fun i => F x0 i
    have hfb0 := hfA b0 hb0
    set t : ℝ := (f b0 - s0 + 1) / (-w i)
    have ht : 0 ≤ t := div_nonneg (by linarith) (by linarith)
    have hmem : b0 + t • (fun j => if i = j then (1:ℝ) else 0) ∈ A := by
      refine ⟨x0, hx0, fun j => ?_⟩
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, b0]
      have : 0 ≤ t * (if i = j then (1:ℝ) else 0) := mul_nonneg ht (by split_ifs <;> norm_num)
      linarith
    have h1 := hfA _ hmem
    rw [map_add, map_smul, smul_eq_mul] at h1
    have hne : -w i ≠ 0 := by linarith
    have h2 : t * w i = -(f b0 - s0 + 1) := by
      simp only [t]; rw [div_mul_eq_mul_div, div_eq_iff hne]; ring
    change s0 ≤ f b0 + t * w i at h1
    linarith
  set S := ∑ i, w i with hS
  have hSpos : 0 < S := by
    rcases (Finset.sum_nonneg (fun i _ => hw0 i) : 0 ≤ S).lt_or_eq with h' | h'
    · exact h'
    · exfalso
      have hwz : ∀ i, w i = 0 := by
        intro i
        exact (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => hw0 i)).1 h'.symm i (Finset.mem_univ _)
      have hc1 : (fun _ : ι => c - 1) ∈ B := fun _ _ => by simp
      have e1 := hfB _ hc1
      have e2 := hfA _ hb0
      rw [hf] at e1 e2
      simp only [hwz, mul_zero, Finset.sum_const_zero] at e1 e2
      linarith
  have hcS : c * S ≤ s0 := by
    by_contra hlt
    push Not at hlt
    set δ := (c * S - s0) / S
    have hδ : 0 < δ := div_pos (by linarith) hSpos
    have hmem : (fun _ : ι => c - δ) ∈ B := fun _ _ => by simp [hδ]
    have e1 := hfB _ hmem
    rw [hf, ← Finset.mul_sum] at e1
    have : (c - δ) * S = s0 := by simp only [δ]; field_simp; ring
    linarith
  let lam : ι → ℝ := fun i => w i / S
  have hlam0 : ∀ i ∈ (Finset.univ : Finset ι), 0 ≤ lam i := fun i _ => div_nonneg (hw0 i) hSpos.le
  have hlam1 : ∑ i ∈ (Finset.univ : Finset ι), lam i = 1 := by
    rw [← Finset.sum_div, ← hS]; field_simp
  have hmemY : ∀ i ∈ (Finset.univ : Finset ι), (i : G) ∈ Y := fun i _ => hu i i.2
  refine ⟨∑ i, lam i • (i : G), hYcvx.sum_mem hlam0 hlam1 hmemY, fun x hx => ?_⟩
  have hj := (hconcave x hx).le_map_sum hlam0 hlam1 hmemY
  have hA : (fun i : ι => F x i) ∈ A := ⟨x, hx, fun i => le_rfl⟩
  have e := hfA _ hA
  rw [hf] at e
  have : c ≤ ∑ i, lam i • F x i := by
    simp only [lam, smul_eq_mul]
    rw [show (∑ i, w i / S * F x i) = (∑ i : ι, F x (i : G) * w i) / S by
      rw [Finset.sum_div]; exact Finset.sum_congr rfl (fun i _ => by ring)]
    rw [le_div_iff₀ hSpos]
    linarith
  linarith

/-- Weak duality, as a helper. -/
theorem minimax_weak {α β : Type*} (X : Set α) (Y : Set β) (F : α → β → ℝ) :
    (⨆ y ∈ Y, ⨅ x ∈ X, (F x y : EReal)) ≤ ⨅ x ∈ X, ⨆ y ∈ Y, (F x y : EReal) :=
  iSup₂_le fun y hy => le_iInf₂ fun x hx => (iInf₂_le x hx).trans (le_iSup₂ (f := fun y _ => (F x y : EReal)) y hy)


theorem minimax_key
    {E G : Type*} [TopologicalSpace E] [AddCommGroup E] [Module ℝ E]
    [AddCommGroup G] [Module ℝ G]
    {X : Set E} {Y : Set G} {F : E → G → ℝ}
    (hXne : X.Nonempty) (hXcpt : IsCompact X) (hXcvx : Convex ℝ X) (hYcvx : Convex ℝ Y)
    (hconvex : ∀ y ∈ Y, ConvexOn ℝ X fun x => F x y)
    (hlsc : ∀ y ∈ Y, LowerSemicontinuousOn (fun x => F x y) X)
    (hconcave : ∀ x ∈ X, ConcaveOn ℝ Y (F x)) :
    ∃ x₀ ∈ X, ∀ y ∈ Y, (F x₀ y : EReal) ≤ ⨆ y ∈ Y, ⨅ x ∈ X, (F x y : EReal) := by
  classical
  set v := ⨆ y ∈ Y, ⨅ x ∈ X, (F x y : EReal) with hv
  let ι := {p : G × ℝ // p.1 ∈ Y ∧ v < (p.2 : EReal)}
  have hC : ∀ i : ι, ∃ C : Set E, IsClosed C ∧
      X ∩ (fun x => F x i.1.1) ⁻¹' Iic i.1.2 = X ∩ C := fun i =>
    lowerSemicontinuousOn_iff_preimage_Iic.1 (hlsc i.1.1 i.2.1) i.1.2
  choose C hCc hXC using hC
  have hfin : ∀ u : Finset ι, (X ∩ ⋂ i ∈ u, C i).Nonempty := by
    intro u
    rcases u.eq_empty_or_nonempty with rfl | hu
    · simpa using hXne
    obtain ⟨p₀, hp₀, hmin⟩ := u.exists_min_image (fun p => p.1.2) hu
    set c := p₀.1.2
    have hvc : v < (c : EReal) := p₀.2.2
    have hex : ∃ x ∈ X, ∀ y ∈ u.image (fun p => p.1.1), F x y < c := by
      by_contra hno
      push Not at hno
      obtain ⟨y', hy'Y, hy'⟩ := minimax_finite_step hXne hXcvx hYcvx hconvex hconcave
        (u.image (fun p => p.1.1)) (by
          intro y hy
          obtain ⟨p, -, rfl⟩ := Finset.mem_image.1 hy
          exact p.2.1) c hno
      have h1 : (c : EReal) ≤ ⨅ x ∈ X, (F x y' : EReal) :=
        le_iInf₂ fun x hx => EReal.coe_le_coe_iff.2 (hy' x hx)
      have h2 : (⨅ x ∈ X, (F x y' : EReal)) ≤ v :=
        le_iSup₂ (f := fun y _ => ⨅ x ∈ X, (F x y : EReal)) y' hy'Y
      exact absurd (h1.trans h2) (not_le.2 hvc)
    obtain ⟨x, hx, hxu⟩ := hex
    refine ⟨x, hx, mem_iInter₂.2 fun i hi => ?_⟩
    have hle : F x i.1.1 ≤ i.1.2 :=
      ((hxu _ (Finset.mem_image_of_mem _ hi)).trans_le (hmin i hi)).le
    have : x ∈ X ∩ (fun x => F x i.1.1) ⁻¹' Iic i.1.2 := ⟨hx, hle⟩
    rw [hXC i] at this
    exact this.2
  obtain ⟨x₀, hx₀X, hx₀C⟩ := hXcpt.inter_iInter_nonempty C hCc hfin
  refine ⟨x₀, hx₀X, fun y hy => ?_⟩
  refine EReal.le_of_forall_lt_iff_le.1 fun c hc => ?_
  let i : ι := ⟨(y, c), hy, hc⟩
  have : x₀ ∈ X ∩ C i := ⟨hx₀X, mem_iInter.1 hx₀C i⟩
  rw [← hXC i] at this
  exact EReal.coe_le_coe_iff.2 this.2

#print axioms minimax_finite_step
#print axioms minimax_weak
#print axioms minimax_key

/-- **Minimax theorem (Fan).** Let `X` be a compact convex set in a real topological vector
space and `Y` any convex set in a real vector space. Let the payoff `F x y` be convex and lower
semicontinuous in `x` on `X` for each `y` in `Y`, and concave in `y` on `Y` for each `x` in `X`.
Then the best worst case equals the worst best case:
`min_{x ∈ X} sup_{y ∈ Y} F x y = sup_{y ∈ Y} inf_{x ∈ X} F x y`,
and the minimum on the left is reached by some `x₀` in `X`. ("min" needs `X` nonempty.)
Values are taken in the extended reals, since a supremum may be `+∞`. -/
theorem best_worst_case_eq_worst_best_case
    {E G : Type*} [TopologicalSpace E] [AddCommGroup E] [Module ℝ E]
    [IsTopologicalAddGroup E] [ContinuousSMul ℝ E] [AddCommGroup G] [Module ℝ G]
    {X : Set E} {Y : Set G} {F : E → G → ℝ}
    (hXne : X.Nonempty) (hXcpt : IsCompact X) (hXcvx : Convex ℝ X) (hYcvx : Convex ℝ Y)
    (hconvex : ∀ y ∈ Y, ConvexOn ℝ X fun x => F x y)
    (hlsc : ∀ y ∈ Y, LowerSemicontinuousOn (fun x => F x y) X)
    (hconcave : ∀ x ∈ X, ConcaveOn ℝ Y (F x)) :
    ∃ x₀ ∈ X,
      (⨆ y ∈ Y, (F x₀ y : EReal)) = ⨅ x ∈ X, ⨆ y ∈ Y, (F x y : EReal) ∧
      (⨅ x ∈ X, ⨆ y ∈ Y, (F x y : EReal)) = ⨆ y ∈ Y, ⨅ x ∈ X, (F x y : EReal) := by
  obtain ⟨x₀, hx₀, hkey⟩ :=
    minimax_key hXne hXcpt hXcvx hYcvx hconvex hlsc hconcave
  have h1 : (⨆ y ∈ Y, (F x₀ y : EReal)) ≤ ⨆ y ∈ Y, ⨅ x ∈ X, (F x y : EReal) := iSup₂_le hkey
  have h2 := minimax_weak X Y F
  have h3 : (⨅ x ∈ X, ⨆ y ∈ Y, (F x y : EReal)) ≤ ⨆ y ∈ Y, (F x₀ y : EReal) :=
    iInf₂_le (f := fun x _ => ⨆ y ∈ Y, (F x y : EReal)) x₀ hx₀
  exact ⟨x₀, hx₀, le_antisymm (h1.trans h2) h3, le_antisymm (h3.trans h1) h2⟩

/-- **Moving second never hurts** (Step 1, and weak duality). For any sets of choices and any
payoff, the maximiser's best guarantee when moving first is at most the minimiser's best
guarantee when moving first: `sup_y inf_x F x y ≤ inf_x sup_y F x y`. -/
theorem moving_second_never_hurts {α β : Type*} (X : Set α) (Y : Set β) (F : α → β → ℝ) :
    (⨆ y ∈ Y, ⨅ x ∈ X, (F x y : EReal)) ≤ ⨅ x ∈ X, ⨆ y ∈ Y, (F x y : EReal) := by
  exact minimax_weak X Y F

/-- The penalty kick's scoring chance, in percentage points, when the kicker shoots Left with
chance `p` and the keeper dives Left with chance `q` (table: 58, 95 / 93, 70). -/
def kick (p q : ℝ) : ℝ :=
  58 * p * q + 95 * p * (1 - q) + 93 * (1 - p) * q + 70 * (1 - p) * (1 - q)

/-- **The penalty kick's mixed value.** When both players mix, the order of play stops
mattering: keeper first and kicker first both give 4775/60 percent (79.5833%). The kicker's
mix `p = 23/60` scores exactly that against every keeper mix, and the keeper's mix
`q = 5/12` concedes exactly that against every kicker mix. -/
theorem penalty_kick_mixed_value :
    (⨅ q : Icc (0 : ℝ) 1, ⨆ p : Icc (0 : ℝ) 1, kick p q) = 4775 / 60 ∧
    (⨆ p : Icc (0 : ℝ) 1, ⨅ q : Icc (0 : ℝ) 1, kick p q) = 4775 / 60 ∧
    (∀ q ∈ Icc (0 : ℝ) 1, kick (23 / 60) q = 4775 / 60) ∧
    (∀ p ∈ Icc (0 : ℝ) 1, kick p (5 / 12) = 4775 / 60) := by
  have hP : ∀ q : ℝ, kick (23 / 60) q = 4775 / 60 := fun q => by unfold kick; ring
  have hQ : ∀ p : ℝ, kick p (5 / 12) = 4775 / 60 := fun p => by unfold kick; ring
  have : Nonempty (Icc (0 : ℝ) 1) := ⟨⟨0, by norm_num, by norm_num⟩⟩
  let p₀ : Icc (0 : ℝ) 1 := ⟨23 / 60, by norm_num, by norm_num⟩
  let q₀ : Icc (0 : ℝ) 1 := ⟨5 / 12, by norm_num, by norm_num⟩
  have hup : ∀ p q : Icc (0 : ℝ) 1, kick p q ≤ 188 := by
    rintro ⟨p, hp0, hp1⟩ ⟨q, hq0, hq1⟩
    unfold kick
    nlinarith [mul_nonneg hp0 hq0, mul_nonneg (sub_nonneg.2 hp1) hq0,
      mul_nonneg hp0 (sub_nonneg.2 hq1), mul_nonneg (sub_nonneg.2 hp1) (sub_nonneg.2 hq1)]
  have hlo : ∀ p q : Icc (0 : ℝ) 1, 0 ≤ kick p q := by
    rintro ⟨p, hp0, hp1⟩ ⟨q, hq0, hq1⟩
    unfold kick
    nlinarith [mul_nonneg hp0 hq0, mul_nonneg (sub_nonneg.2 hp1) hq0,
      mul_nonneg hp0 (sub_nonneg.2 hq1), mul_nonneg (sub_nonneg.2 hp1) (sub_nonneg.2 hq1)]
  have bA : ∀ q : Icc (0 : ℝ) 1, BddAbove (range fun p : Icc (0 : ℝ) 1 => kick p q) :=
    fun q => ⟨188, by rintro _ ⟨p, rfl⟩; exact hup p q⟩
  have bB : ∀ p : Icc (0 : ℝ) 1, BddBelow (range fun q : Icc (0 : ℝ) 1 => kick p q) :=
    fun p => ⟨0, by rintro _ ⟨q, rfl⟩; exact hlo p q⟩
  refine ⟨?_, ?_, fun q _ => hP q, fun p _ => hQ p⟩
  · apply le_antisymm
    · refine (ciInf_le ⟨4775 / 60, ?_⟩ q₀).trans (ciSup_le fun p => (hQ p).le)
      rintro _ ⟨q, rfl⟩
      exact (hP q).symm.le.trans (le_ciSup (bA q) p₀)
    · exact le_ciInf fun q => (hP q).symm.le.trans (le_ciSup (bA q) p₀)
  · apply le_antisymm
    · exact ciSup_le fun p => (ciInf_le (bB p) q₀).trans (hQ p).le
    · refine le_trans ?_ (le_ciSup ⟨4775 / 60, ?_⟩ p₀)
      · exact le_ciInf fun q => (hP q).symm.le
      · rintro _ ⟨p, rfl⟩
        exact (ciInf_le (bB p) q₀).trans (hQ p).le

-- Plain choices only: kicker first locks in 70, keeper first concedes 93.
example : max (min 58 95) (min 93 70) = (70 : ℕ) := by decide
example : min (max 58 93) (max 95 70) = (93 : ℕ) := by decide
-- The hand steps: 95 × 93 − 58 × 70 = 4775 and 95 + 93 − 58 − 70 = 60.
example : 95 * 93 - 58 * 70 = (4775 : ℤ) ∧ 95 + 93 - 58 - 70 = (60 : ℤ) := by norm_num
-- The closed-form mixes: p* = (93 − 70)/60 = 23/60 and q* = (95 − 70)/60 = 5/12.
example : ((93 - 70 : ℚ) / 60 = 23 / 60) ∧ ((95 - 70 : ℚ) / 60 = 5 / 12) := by norm_num
-- The wall at keeper Left and at keeper Right: both 4775/60.
example : 23 * 58 + 37 * 93 = (4775 : ℕ) ∧ 1334 + 3441 = (4775 : ℕ) := by decide
example : 23 * 95 + 37 * 70 = (4775 : ℕ) ∧ 2185 + 2590 = (4775 : ℕ) := by decide
-- The dual function at q = 3/10 and q = 1/2: 83.9 and 81.5 percent.
example : max (58 * (3 / 10) + 95 * (7 / 10)) (93 * (3 / 10) + 70 * (7 / 10)) = (839 / 10 : ℚ) := by
  norm_num
example : max (58 * (1 / 2) + 95 * (1 / 2)) (93 * (1 / 2) + 70 * (1 / 2)) = (163 / 2 : ℚ) := by
  norm_num
-- The keeper's LP: z = q/V with V = 191/240 (as a chance); its total is 1/V = 240/191,
-- and the prices 92/191, 148/191 rescaled by V give the kicker's mix 23/60, 37/60.
example : ((5 / 12 : ℚ) / (191 / 240) = 100 / 191) ∧ ((7 / 12 : ℚ) / (191 / 240) = 140 / 191) ∧
    ((100 : ℚ) / 191 + 140 / 191 = 240 / 191) ∧ ((4775 : ℚ) / 6000 = 191 / 240) := by norm_num
example : ((92 : ℚ) / 191 * (191 / 240) = 23 / 60) ∧ ((148 : ℚ) / 191 * (191 / 240) = 37 / 60) := by
  norm_num

#print axioms best_worst_case_eq_worst_best_case
#print axioms moving_second_never_hurts
#print axioms penalty_kick_mixed_value
