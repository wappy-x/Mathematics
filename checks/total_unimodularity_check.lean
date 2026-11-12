-- Total unimodularity: if every square submatrix of a whole-number table has determinant -1, 0 or 1 and the limits are whole, every corner of {x : Ax ≤ b, x ≥ 0} is whole; the two-group test proves a table qualifies, and prices certify the best assignment.
import Mathlib.LinearAlgebra.Matrix.Determinant.TotallyUnimodular
import Mathlib.Analysis.Convex.Extreme
import Mathlib.Basic.Real.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib

open Matrix

/-- Helper: if a totally unimodular whole-number system has exactly one real solution, that
solution is whole. -/
theorem tu_unique_solution_whole {T n : Type*} [Fintype T] [Fintype n]
    (M : Matrix T n ℤ) (hM : M.IsTotallyUnimodular)
    (hinj : Function.Injective (M.map (Int.cast : ℤ → ℝ)).mulVec)
    (c : T → ℤ) (y : n → ℝ) (hy : (M.map (Int.cast : ℤ → ℝ)) *ᵥ y = fun t => (c t : ℝ)) :
    ∃ z : n → ℤ, y = fun j => (z j : ℝ) := by
  classical
  set M' := M.map (Int.cast : ℤ → ℝ) with hM'
  have hrank : M'.rank = Fintype.card n := by
    rw [Matrix.rank, LinearMap.finrank_range_of_inj (by exact hinj),
      Module.finrank_fintype_fun_eq_card]
  rw [M'.rank_eq_finrank_span_row] at hrank
  obtain ⟨κ, a, ha, hsp, hli⟩ := exists_linearIndependent'.{_, _, 0} ℝ M'.row
  have : Fintype κ := Fintype.ofInjective a ha
  have hcard : Fintype.card κ = Fintype.card n := by
    rw [← hrank, ← hsp, linearIndependent_iff_card_eq_finrank_span.mp hli, Set.finrank]
  let e : n ≃ κ := Fintype.equivOfCardEq hcard.symm
  let f : n → T := a ∘ e
  let B : Matrix n n ℤ := M.submatrix f id
  have hB' : B.map (Int.cast : ℤ → ℝ) = M'.submatrix f id := rfl
  have hli' : LinearIndependent ℝ (B.map (Int.cast : ℤ → ℝ)).row := by
    have := hli.comp e e.injective
    exact this
  have hunit : IsUnit (B.map (Int.cast : ℤ → ℝ)) := linearIndependent_row_iff_isUnit.mp hli'
  have hdet0 : (B.map (Int.cast : ℤ → ℝ)).det ≠ 0 := by
    rw [← isUnit_iff_ne_zero, ← Matrix.isUnit_iff_isUnit_det]; exact hunit
  have hdetcast : ((B.det : ℤ) : ℝ) = (B.map (Int.cast : ℤ → ℝ)).det :=
    (Int.castRingHom ℝ).map_det B
  have htu := (isTotallyUnimodular_iff_fintype M).mp hM n f id
  obtain ⟨s, hs⟩ := htu
  have hsq : B.det * B.det = 1 := by
    change (M.submatrix f id).det * (M.submatrix f id).det = 1
    rw [← hs]
    rcases s with _ | _ | _
    · exfalso; apply hdet0; rw [← hdetcast]; change (((M.submatrix f id).det : ℤ) : ℝ) = 0
      rw [← hs]; simp
    · simp
    · simp
  -- adjugate argument
  have hBy : (B.map (Int.cast : ℤ → ℝ)) *ᵥ y = fun j => (c (f j) : ℝ) := by
    funext j
    rw [hB']
    have := congrFun hy (f j)
    simpa [Matrix.mulVec, dotProduct, Matrix.submatrix] using this
  have hadj := congrArg (fun v => (B.map (Int.cast : ℤ → ℝ)).adjugate *ᵥ v) hBy
  simp only [Matrix.mulVec_mulVec, Matrix.adjugate_mul, Matrix.smul_mulVec, Matrix.one_mulVec] at hadj
  refine ⟨fun j => B.det * (B.adjugate *ᵥ (c ∘ f)) j, ?_⟩
  funext j
  have hj := congrFun hadj j
  have hmap : ((B.adjugate *ᵥ (c ∘ f)) j : ℝ) =
      ((B.map (Int.cast : ℤ → ℝ)).adjugate *ᵥ fun j => (c (f j) : ℝ)) j := by
    rw [show ((B.adjugate *ᵥ (c ∘ f)) j : ℝ) = Int.castRingHom ℝ ((B.adjugate *ᵥ (c ∘ f)) j) from rfl,
      RingHom.map_mulVec]
    congr 1
    have := (Int.castRingHom ℝ).map_adjugate B
    simpa using this
  rw [← hdetcast] at hj
  simp only [Pi.smul_apply, smul_eq_mul] at hj
  have : ((B.det : ℝ) * (B.det : ℝ)) = 1 := by exact_mod_cast hsq
  rw [Int.cast_mul, hmap, ← hj, ← mul_assoc, this, one_mul]

#print axioms tu_unique_solution_whole

/-- Hoffman and Kruskal, the direction the card proves: if every square submatrix of the
whole-number table `A` has determinant -1, 0 or +1, and the right-hand side `b` is whole,
then every corner (extreme point) of the region `{x : A x ≤ b, x ≥ 0}` has whole coordinates. -/
theorem totally_unimodular_corners_are_whole {m n : Type*} [Fintype m] [Fintype n]
    (A : Matrix m n ℤ) (hA : A.IsTotallyUnimodular) (b : m → ℤ) (x : n → ℝ)
    (hx : x ∈ Set.extremePoints ℝ
      {y : n → ℝ | (∀ i, (A.map (Int.cast : ℤ → ℝ) *ᵥ y) i ≤ (b i : ℝ)) ∧ ∀ j, 0 ≤ y j}) :
    ∃ z : n → ℤ, x = fun j => (z j : ℝ) := by
  classical
  set S := {y : n → ℝ | (∀ i, (A.map (Int.cast : ℤ → ℝ) *ᵥ y) i ≤ (b i : ℝ)) ∧ ∀ j, 0 ≤ y j}
    with hS
  let N : Matrix (m ⊕ n) n ℤ := fromRows A (-1)
  have hN : N.IsTotallyUnimodular := by
    refine hA.fromRows_unitlike (fun _ j => ⟨j, -1, ?_⟩)
    ext k
    by_cases hjk : j = k
    · subst hjk; simp
    · simp [hjk, Ne.symm hjk]
  let b' : m ⊕ n → ℤ := Sum.elim b 0
  let Nr := N.map (Int.cast : ℤ → ℝ)
  have hNr : ∀ (y : n → ℝ), (Nr *ᵥ y) = Sum.elim (A.map Int.cast *ᵥ y) (-y) := by
    intro y
    funext r
    cases r with
    | inl i => simp [Nr, N, Matrix.mulVec, dotProduct]
    | inr j => simp [Nr, N, Matrix.mulVec, dotProduct, Matrix.one_apply]
  have hSiff : ∀ y, y ∈ S ↔ ∀ r, (Nr *ᵥ y) r ≤ (b' r : ℝ) := by
    intro y
    simp only [hS, Set.mem_ofPred_eq, hNr, Sum.forall, Sum.elim_inl, Sum.elim_inr, b',
      Pi.neg_apply, Pi.zero_apply, Int.cast_zero, neg_nonpos]
  have hxS : x ∈ S := hx.1
  have key : ∀ d : n → ℝ, (∀ r, (Nr *ᵥ x) r = (b' r : ℝ) → (Nr *ᵥ d) r = 0) → d = 0 := by
    intro d hd
    have hev : ∀ᶠ s in nhds (0 : ℝ), x + s • d ∈ S := by
      simp only [hSiff]
      refine Filter.eventually_all.2 fun r => ?_
      have hlin : ∀ s : ℝ, (Nr *ᵥ (x + s • d)) r = (Nr *ᵥ x) r + s * (Nr *ᵥ d) r := by
        intro s; simp [Matrix.mulVec_add, Matrix.mulVec_smul]
      simp only [hlin]
      by_cases ht : (Nr *ᵥ x) r = (b' r : ℝ)
      · refine Filter.Eventually.of_forall fun s => ?_
        rw [hd r ht, ht]; simp
      · have hlt : (Nr *ᵥ x) r < (b' r : ℝ) := lt_of_le_of_ne ((hSiff x).1 hxS r) ht
        have htend : Filter.Tendsto (fun s : ℝ => (Nr *ᵥ x) r + s * (Nr *ᵥ d) r) (nhds 0)
            (nhds ((Nr *ᵥ x) r)) := by
          have hc : Continuous (fun s : ℝ => (Nr *ᵥ x) r + s * (Nr *ᵥ d) r) :=
            continuous_const.add (continuous_id.mul continuous_const)
          exact hc.tendsto' 0 _ (by simp)
        exact (htend.eventually_lt_const hlt).mono fun s hs => le_of_lt hs
    obtain ⟨ε, hε, hball⟩ := Metric.eventually_nhds_iff.1 hev
    have h1 : x + (ε / 2) • d ∈ S := hball (by
      rw [Real.dist_eq, sub_zero, abs_of_pos (by linarith)]; linarith)
    have h2 : x + (-(ε / 2)) • d ∈ S := hball (by
      rw [Real.dist_eq, sub_zero, abs_neg, abs_of_pos (by linarith)]; linarith)
    have hseg : x ∈ openSegment ℝ (x + (ε / 2) • d) (x + (-(ε / 2)) • d) := by
      refine ⟨1 / 2, 1 / 2, by norm_num, by norm_num, by norm_num, ?_⟩
      ext j; simp; ring
    have := ((mem_extremePoints.1 hx).2 _ h1 _ h2 hseg).1
    have h3 : (ε / 2) • d = 0 := by
      have := congrArg (fun v => v - x) this
      simpa using this
    rcases smul_eq_zero.1 h3 with h | h
    · linarith
    · exact h
  let T := {r : m ⊕ n // (Nr *ᵥ x) r = (b' r : ℝ)}
  let M : Matrix T n ℤ := N.submatrix Subtype.val id
  have hMv : ∀ y, (M.map (Int.cast : ℤ → ℝ)) *ᵥ y = fun t => (Nr *ᵥ y) t.1 := fun y => rfl
  refine tu_unique_solution_whole M (hN.submatrix _ _) ?_ (fun t => b' t.1) x ?_
  · intro d1 d2 h12
    have hz := key (d1 - d2) (fun r hr => by
      have := congrFun h12 ⟨r, hr⟩
      rw [hMv, hMv] at this
      simp only at this
      rw [Matrix.mulVec_sub, Pi.sub_apply, this, sub_self])
    exact sub_eq_zero.1 hz
  · rw [hMv]
    funext t
    exact t.2

/-- The two-group test (Heller and Tompkins): a table with entries -1, 0, 1, at most two
nonzeros in each column, and its rows split into two groups so that a column's two nonzeros
sit in different groups when they have the same sign and in the same group when they have
opposite signs, is totally unimodular. -/
theorem two_group_test_gives_totally_unimodular {m n : Type*} [Fintype m]
    (A : Matrix m n ℤ) (hentry : ∀ i j, A i j = -1 ∨ A i j = 0 ∨ A i j = 1)
    (hcol : ∀ j, (Finset.univ.filter fun i => A i j ≠ 0).card ≤ 2)
    (group : m → Bool)
    (hsplit : ∀ j i₁ i₂, i₁ ≠ i₂ → A i₁ j ≠ 0 → A i₂ j ≠ 0 →
      (A i₁ j = A i₂ j ↔ group i₁ ≠ group i₂)) :
    A.IsTotallyUnimodular := by
  intro k
  induction k with
  | zero => intro f g _ _; exact ⟨1, by simp⟩
  | succ k ih =>
    intro f g hf hg
    by_cases hcase : ∃ c : Fin (k + 1), ∃ r : Fin (k + 1), ∀ i, i ≠ r → A (f i) (g c) = 0
    · obtain ⟨c, r, hr⟩ := hcase
      rw [det_succ_column (A.submatrix f g) c,
        Fintype.sum_eq_single r (fun i hi => by simp [hr i hi])]
      change _ ∈ MonoidHom.mrange SignType.castHom.toMonoidHom
      refine mul_mem (mul_mem (pow_mem ?_ _) ?_) ?_
      · exact ⟨-1, by simp⟩
      · rcases hentry (f r) (g c) with h | h | h
        · exact ⟨-1, by simp [h]⟩
        · exact ⟨0, by simp [h]⟩
        · exact ⟨1, by simp [h]⟩
      · rw [submatrix_submatrix]
        exact ih _ _ (hf.comp Fin.succAbove_right_injective)
          (hg.comp Fin.succAbove_right_injective)
    · push Not at hcase
      refine ⟨0, ?_⟩
      rw [SignType.coe_zero, eq_comm]
      classical
      let w : Fin (k + 1) → ℤ := fun i => if group (f i) then 1 else -1
      apply (Matrix.exists_vecMul_eq_zero_iff).1
      refine ⟨w, ?_, ?_⟩
      · intro h
        have := congrFun h 0
        simp only [w, Pi.zero_apply] at this
        split_ifs at this; omega
      · funext c
        obtain ⟨r1, h1⟩ : ∃ r1, A (f r1) (g c) ≠ 0 := by
          obtain ⟨i, _, hi⟩ := hcase c 0; exact ⟨i, hi⟩
        obtain ⟨r2, h21, h2⟩ := hcase c r1
        have hother : ∀ i, i ≠ r1 → i ≠ r2 → A (f i) (g c) = 0 := by
          intro i hi1 hi2
          by_contra hi
          have h3 : 2 < (Finset.univ.filter fun i => A i (g c) ≠ 0).card := by
            rw [Finset.two_lt_card_iff]
            refine ⟨f r1, f r2, f i, by simpa using h1, by simpa using h2, by simpa using hi,
              hf.ne (Ne.symm h21), hf.ne (Ne.symm hi1), hf.ne (Ne.symm hi2)⟩
          have := hcol (g c)
          omega
        simp only [vecMul, dotProduct, Pi.zero_apply, submatrix_apply]
        rw [Fintype.sum_eq_add r2 r1 h21 (fun i hi => by simp [hother i hi.2 hi.1])]
        have hs := hsplit (g c) (f r2) (f r1) (hf.ne h21) h2 h1
        simp only [w]
        rcases hentry (f r1) (g c) with e1 | e1 | e1 <;>
          rcases hentry (f r2) (g c) with e2 | e2 | e2 <;>
          simp only [e1, e2] at h1 h2 hs ⊢ <;>
          first
          | exact absurd rfl h1
          | exact absurd rfl h2
          | (cases hg1 : group (f r1) <;> cases hg2 : group (f r2) <;> simp [hg1, hg2] at hs ⊢)

/-- The price certificate for an assignment: if act prices `u` and slot prices `v` satisfy
`u i + v j ≥ c i j` for every pair, then every plan that books each act into its own slot
is worth at most the sum of all prices. -/
theorem assignment_value_le_sum_of_prices {n : ℕ} (c : Fin n → Fin n → ℝ) (u v : Fin n → ℝ)
    (hprice : ∀ i j, c i j ≤ u i + v j) (σ : Equiv.Perm (Fin n)) :
    ∑ i, c i (σ i) ≤ ∑ i, u i + ∑ j, v j := by
  calc ∑ i, c i (σ i) ≤ ∑ i, (u i + v (σ i)) := Finset.sum_le_sum fun i _ => hprice i (σ i)
    _ = ∑ i, u i + ∑ j, v j := by rw [Finset.sum_add_distrib, Equiv.sum_comp σ v]

/-- The festival's values, in £ thousand: rows Headliner, Rock band, DJ, Folk trio, Brass band,
Singer; columns Fri main, Sat main, Sun main, Fri late tent, Sat tent, Sun tent. -/
def festivalValue : Fin 6 → Fin 6 → ℤ :=
  !![48, 60, 30, 20, 25, 22;
     40, 45, 28, 22, 30, 26;
     30, 35, 15, 38, 24, 18;
     18, 20, 26, 12, 22, 24;
     15, 18, 25, 10, 20, 21;
     20, 22, 24, 14, 21, 25]

/-- The dual prices: acts and slots. -/
def actPrice : Fin 6 → ℤ := ![55, 40, 38, 22, 21, 21]
def slotPrice : Fin 6 → ℤ := ![0, 5, 4, 0, 0, 4]

/-- The relaxation's plan: Headliner to Sat main, Rock band to Fri main, DJ to Fri late tent,
Folk trio to Sat tent, Brass band to Sun main, Singer to Sun tent. -/
def festivalPlan : Fin 6 → Fin 6 := ![1, 0, 3, 4, 2, 5]

-- The plan uses each slot once.
example : Function.Injective festivalPlan := by decide

-- Its value: 60 + 40 + 38 + 22 + 25 + 25 = 210.
example : ∑ i, festivalValue i (festivalPlan i) = 210 := by decide

-- The prices add up to 210.
example : ∑ i, actPrice i + ∑ j, slotPrice j = 210 := by decide

-- All 36 price checks: act price plus slot price is at least the pair's value.
example : ∀ i j, festivalValue i j ≤ actPrice i + slotPrice j := by decide

-- Headliner + Sat main: 55 + 5 = 60, and Rock band + Sat main: 40 + 5 = 45.
example : actPrice 0 + slotPrice 1 = festivalValue 0 1 ∧
    actPrice 1 + slotPrice 1 = festivalValue 1 1 := by decide

-- The duet triangle has determinant 2.
example : (!![1, 0, 1; 1, 1, 0; 0, 1, 1] : Matrix (Fin 3) (Fin 3) ℤ).det = 2 := by
  simp [Matrix.det_fin_three]

-- So the duet triangle is not totally unimodular.
example : ¬ (!![1, 0, 1; 1, 1, 0; 0, 1, 1] : Matrix (Fin 3) (Fin 3) ℤ).IsTotallyUnimodular := by
  intro h
  obtain ⟨s, hs⟩ := h 3 id id Function.injective_id Function.injective_id
  simp [Matrix.det_fin_three] at hs
  cases s <;> simp at hs

#print axioms totally_unimodular_corners_are_whole
#print axioms two_group_test_gives_totally_unimodular
#print axioms assignment_value_le_sum_of_prices
