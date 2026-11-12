-- Network flows: every corner of a shipping problem with whole supplies and demands ships whole tonnes, a whole cheapest plan always exists, and prices with no route below its two end prices certify a plan as cheapest.
import Mathlib.Analysis.Convex.Extreme
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic
import Mathlib.Analysis.Convex.KreinMilman

open Finset

/-- The shipping plans (the transportation problem's region): a tonnage `x i j` on every route from
mill `i` to column `j`, never negative, with each mill shipping exactly its supply `a i` and each
column receiving exactly its demand `b j`. Every limit is a "total in or out" row. -/
def shippingPlans {ι κ : Type*} [Fintype ι] [Fintype κ] (a : ι → ℝ) (b : κ → ℝ) :
    Set (ι → κ → ℝ) :=
  {x | (∀ i, ∑ j, x i j = a i) ∧ (∀ j, ∑ i, x i j = b j) ∧ ∀ i j, 0 ≤ x i j}

/-- The haulage bill of a plan: cost per tonne times tonnes, added over every route. -/
def haulageCost {ι κ : Type*} [Fintype ι] [Fintype κ] (c : ι → κ → ℝ) (x : ι → κ → ℝ) : ℝ :=
  ∑ i, ∑ j, c i j * x i j

lemma nf_int_sum {α : Type*} (s : Finset α) (g : α → ℝ) (h : ∀ k ∈ s, ∃ n : ℤ, g k = n) :
    ∃ n : ℤ, ∑ k ∈ s, g k = n := by
  classical
  induction s using Finset.induction_on with
  | empty => exact ⟨0, by simp⟩
  | insert a s ha ih =>
    obtain ⟨m, hm⟩ := h a (Finset.mem_insert_self a s)
    obtain ⟨n, hn⟩ := ih (fun k hk => h k (Finset.mem_insert_of_mem hk))
    exact ⟨m + n, by rw [Finset.sum_insert ha, hm, hn]; push_cast; ring⟩

lemma nf_second_fraction {α : Type*} [Fintype α] [DecidableEq α] (g : α → ℝ)
    (hsum : ∃ n : ℤ, ∑ k, g k = n) (j : α) (hj : ¬ ∃ n : ℤ, g j = n) :
    ∃ j', j' ≠ j ∧ ¬ ∃ n : ℤ, g j' = n := by
  by_contra hcon
  push Not at hcon
  apply hj
  obtain ⟨n, hn⟩ := hsum
  obtain ⟨m, hm⟩ := nf_int_sum (Finset.univ.erase j) g
    (fun k hk => hcon k (Finset.ne_of_mem_erase hk))
  have := Finset.add_sum_erase Finset.univ g (Finset.mem_univ j)
  exact ⟨n - m, by push_cast; linarith⟩

lemma nf_exists_cycle {ι κ : Type*} [Fintype ι] [Fintype κ] [DecidableEq ι] [DecidableEq κ]
    (x : ι → κ → ℝ) (F : Finset (ι × κ))
    (hF : ∀ e, e ∈ F ↔ ¬ ∃ n : ℤ, x e.1 e.2 = n)
    (hrow : ∀ i, ∃ n : ℤ, ∑ j, x i j = n) (hcol : ∀ j, ∃ n : ℤ, ∑ i, x i j = n)
    (hne : F.Nonempty) :
    ∃ D : ι → κ → ℝ, D ≠ 0 ∧ (∀ i j, (i, j) ∉ F → D i j = 0) ∧
      (∀ i, ∑ j, D i j = 0) ∧ (∀ j, ∑ i, D i j = 0) := by
  set R : Finset ι := F.image Prod.fst with hR
  set C : Finset κ := F.image Prod.snd with hC
  have hRcard : 2 * R.card ≤ F.card := by
    rw [Finset.card_eq_sum_card_image Prod.fst F]
    have := Finset.card_nsmul_le_sum R (fun i => (F.filter (fun e => e.1 = i)).card) 2 (by
      intro i hi
      obtain ⟨e, he, rfl⟩ := Finset.mem_image.mp hi
      have hfrac := (hF e).mp he
      obtain ⟨j', hj'ne, hj'⟩ := nf_second_fraction (x e.1) (hrow e.1) e.2 hfrac
      have h1 : 1 < (F.filter (fun e' => e'.1 = e.1)).card := by
        apply Finset.one_lt_card.mpr
        refine ⟨e, ?_, (e.1, j'), ?_, ?_⟩
        · simp [he]
        · exact Finset.mem_filter.mpr ⟨(hF _).mpr hj', rfl⟩
        · intro h; apply hj'ne; exact (congrArg Prod.snd h).symm
      omega)
    simpa [smul_eq_mul, mul_comm] using this
  have hCcard : 2 * C.card ≤ F.card := by
    rw [Finset.card_eq_sum_card_image Prod.snd F]
    have := Finset.card_nsmul_le_sum C (fun j => (F.filter (fun e => e.2 = j)).card) 2 (by
      intro j hj
      obtain ⟨e, he, rfl⟩ := Finset.mem_image.mp hj
      have hfrac := (hF e).mp he
      obtain ⟨i', hi'ne, hi'⟩ := nf_second_fraction (fun i => x i e.2) (hcol e.2) e.1 hfrac
      have h1 : 1 < (F.filter (fun e' => e'.2 = e.2)).card := by
        apply Finset.one_lt_card.mpr
        refine ⟨e, ?_, (i', e.2), ?_, ?_⟩
        · simp [he]
        · exact Finset.mem_filter.mpr ⟨(hF _).mpr hi', rfl⟩
        · intro h; apply hi'ne; exact (congrArg Prod.fst h).symm
      omega)
    simpa [smul_eq_mul, mul_comm] using this
  obtain ⟨e0, he0⟩ := hne
  have hj0 : e0.2 ∈ C := Finset.mem_image_of_mem _ he0
  set j0 := e0.2 with hj0def
  let ext : (F → ℝ) →ₗ[ℝ] (ι → κ → ℝ) :=
    { toFun := fun d i j => if h : (i, j) ∈ F then d ⟨(i, j), h⟩ else 0
      map_add' := by
        intro d1 d2; funext i j; simp only [Pi.add_apply]; split_ifs <;> simp
      map_smul' := by
        intro c d; funext i j
        simp only [Pi.smul_apply, smul_eq_mul, RingHom.id_apply]; split_ifs <;> simp }
  have ext_apply : ∀ d i j, ext d i j = if h : (i, j) ∈ F then d ⟨(i, j), h⟩ else 0 :=
    fun _ _ _ => rfl
  let f : (F → ℝ) →ₗ[ℝ] (R → ℝ) × (C.erase j0 → ℝ) :=
    { toFun := fun d => (fun r => ∑ j, ext d r j, fun c => ∑ i, ext d i c)
      map_add' := by
        intro d1 d2
        refine Prod.ext (funext fun r => ?_) (funext fun c => ?_) <;>
          simp [Finset.sum_add_distrib]
      map_smul' := by
        intro c d
        refine Prod.ext (funext fun r => ?_) (funext fun c => ?_) <;>
          simp [Finset.mul_sum] }
  have hlt : Module.finrank ℝ ((R → ℝ) × (C.erase j0 → ℝ)) < Module.finrank ℝ (F → ℝ) := by
    rw [Module.finrank_prod, Module.finrank_fintype_fun_eq_card,
      Module.finrank_fintype_fun_eq_card, Module.finrank_fintype_fun_eq_card]
    simp only [Fintype.card_coe]
    rw [Finset.card_erase_of_mem hj0]
    have : 1 ≤ C.card := Finset.card_pos.mpr ⟨_, hj0⟩
    omega
  obtain ⟨d, hdker, hd0⟩ := (Submodule.ne_bot_iff _).mp (LinearMap.ker_ne_bot_of_finrank_lt hlt)
  have hfd : f d = 0 := hdker
  have hrow0 : ∀ i, ∑ j, ext d i j = 0 := by
    intro i
    by_cases hi : i ∈ R
    · have := congrFun (congrArg Prod.fst hfd) ⟨i, hi⟩
      simpa [f] using this
    · apply Finset.sum_eq_zero
      intro j _
      have hij : (i, j) ∉ F := fun hij => hi (Finset.mem_image.mpr ⟨(i, j), hij, rfl⟩)
      simp [ext_apply, hij]
  have hcol' : ∀ j, j ≠ j0 → ∑ i, ext d i j = 0 := by
    intro j hj
    by_cases hjC : j ∈ C
    · have := congrFun (congrArg Prod.snd hfd) ⟨j, Finset.mem_erase.mpr ⟨hj, hjC⟩⟩
      simpa [f] using this
    · apply Finset.sum_eq_zero
      intro i _
      have hij : (i, j) ∉ F := fun hij => hjC (Finset.mem_image.mpr ⟨(i, j), hij, rfl⟩)
      simp [ext_apply, hij]
  refine ⟨ext d, ?_, ?_, hrow0, ?_⟩
  · intro h
    apply hd0
    funext e
    have := congrFun (congrFun h e.1.1) e.1.2
    simpa [ext_apply, e.2] using this
  · intro i j hij
    simp [ext_apply, hij]
  intro j
  by_cases hj : j = j0
  · subst hj
    have htot : ∑ j, ∑ i, ext d i j = 0 := by
      rw [Finset.sum_comm]; exact Finset.sum_eq_zero (fun i _ => hrow0 i)
    rw [← Finset.add_sum_erase Finset.univ _ (Finset.mem_univ j0)] at htot
    rw [Finset.sum_eq_zero (fun j hj => hcol' j (Finset.ne_of_mem_erase hj))] at htot
    simpa using htot
  · exact hcol' j hj

lemma nf_cost_combo {ι κ : Type*} [Fintype ι] [Fintype κ] (c : ι → κ → ℝ)
    (y1 y2 : ι → κ → ℝ) (s t : ℝ) :
    haulageCost c (s • y1 + t • y2) = s * haulageCost c y1 + t * haulageCost c y2 := by
  unfold haulageCost
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, mul_add, Finset.sum_add_distrib,
    Finset.mul_sum]
  congr 1 <;> (apply Finset.sum_congr rfl; intro _ _; apply Finset.sum_congr rfl; intro _ _; ring)

#print axioms nf_int_sum
#print axioms nf_second_fraction
#print axioms nf_exists_cycle
#print axioms nf_cost_combo

/-- The integrality theorem. In a shipping problem whose supplies and demands are whole numbers and
whose totals balance, every corner (extreme point) of the region of plans ships a whole number of
tonnes on every route. -/
theorem shipping_corner_is_whole {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → ℕ) (b : κ → ℕ) (hbal : ∑ i, a i = ∑ j, b j)
    (x : ι → κ → ℝ)
    (hx : x ∈ Set.extremePoints ℝ (shippingPlans (fun i => (a i : ℝ)) (fun j => (b j : ℝ)))) :
    ∀ i j, ∃ n : ℕ, x i j = n := by
  classical
  obtain ⟨hxP, hext⟩ := mem_extremePoints.mp hx
  have hxP' := hxP
  simp only [shippingPlans, Set.mem_ofPred_eq] at hxP'
  obtain ⟨hrowx, hcolx, hnn⟩ := hxP'
  set F : Finset (ι × κ) := Finset.univ.filter (fun e => ¬ ∃ n : ℤ, x e.1 e.2 = n) with hFdef
  have hF : ∀ e, e ∈ F ↔ ¬ ∃ n : ℤ, x e.1 e.2 = n := fun e => by simp [hFdef]
  have hFempty : F = ∅ := by
    by_contra hne
    have hne' : F.Nonempty := Finset.nonempty_iff_ne_empty.mpr hne
    obtain ⟨D, hD0, hDsupp, hDrow, hDcol⟩ := nf_exists_cycle x F hF
      (fun i => ⟨a i, by rw [hrowx i]; simp⟩) (fun j => ⟨b j, by rw [hcolx j]; simp⟩) hne'
    obtain ⟨e0, he0F, hmin⟩ := F.exists_min_image (fun e => x e.1 e.2) hne'
    have hpos : ∀ e ∈ F, 0 < x e.1 e.2 := by
      intro e he
      rcases (hnn e.1 e.2).lt_or_eq with h | h
      · exact h
      · exact absurd ⟨0, by rw [← h]; simp⟩ ((hF e).mp he)
    set m := x e0.1 e0.2 with hmdef
    have hm : 0 < m := hpos e0 he0F
    set M := ∑ i, ∑ j, |D i j| + 1 with hM
    have hMpos : 0 < M := by positivity
    set ε := m / M with hε
    have hεpos : 0 < ε := div_pos hm hMpos
    have hbound : ∀ i j, ε * |D i j| ≤ x i j := by
      intro i j
      by_cases hij : (i, j) ∈ F
      · have h1 : |D i j| ≤ M := by
          have : |D i j| ≤ ∑ j, |D i j| :=
            Finset.single_le_sum (f := fun j => |D i j|) (fun _ _ => abs_nonneg _)
              (Finset.mem_univ j)
          have : ∑ j, |D i j| ≤ ∑ i, ∑ j, |D i j| :=
            Finset.single_le_sum (f := fun i => ∑ j, |D i j|)
              (fun _ _ => Finset.sum_nonneg (fun _ _ => abs_nonneg _)) (Finset.mem_univ i)
          linarith
        have h2 : ε * |D i j| ≤ ε * M := mul_le_mul_of_nonneg_left h1 hεpos.le
        have h3 : ε * M = m := by rw [hε]; field_simp
        have h4 : m ≤ x i j := hmin (i, j) hij
        linarith
      · rw [hDsupp i j hij]; simp [hnn i j]
    have hmem : ∀ s : ℝ, |s| = ε →
        (x + s • D) ∈ shippingPlans (fun i => (a i : ℝ)) (fun j => (b j : ℝ)) := by
      intro s hs
      simp only [shippingPlans, Set.mem_ofPred_eq]
      refine ⟨fun i => ?_, fun j => ?_, fun i j => ?_⟩
      · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Finset.sum_add_distrib,
          ← Finset.mul_sum, hDrow i, hrowx i]
        ring
      · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Finset.sum_add_distrib,
          ← Finset.mul_sum, hDcol j, hcolx j]
        ring
      · simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
        have := hbound i j
        have : |s * D i j| = ε * |D i j| := by rw [abs_mul, hs]
        have := neg_abs_le (s * D i j)
        linarith
    have h1 := hmem ε (abs_of_pos hεpos)
    have h2 := hmem (-ε) (by rw [abs_neg, abs_of_pos hεpos])
    have hseg : x ∈ openSegment ℝ (x + ε • D) (x + (-ε) • D) := by
      refine ⟨1/2, 1/2, by norm_num, by norm_num, by norm_num, ?_⟩
      funext i j
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      ring
    have hx1 := (hext _ h1 _ h2 hseg).1
    apply hD0
    have h' : ε • D = 0 := by
      have := congrArg (fun z => z - x) hx1
      simpa using this
    exact (smul_eq_zero.mp h').resolve_left hεpos.ne'
  intro i j
  have hij : (i, j) ∉ F := by rw [hFempty]; exact Finset.notMem_empty _
  rw [hF] at hij
  push Not at hij
  obtain ⟨n, hn⟩ := hij
  have hn0 : 0 ≤ n := by have := hnn i j; rw [hn] at this; exact_mod_cast this
  exact ⟨n.toNat, by rw [hn]; exact_mod_cast (Int.toNat_of_nonneg hn0).symm⟩

/-- A shipping problem whose supplies and demands are whole numbers and whose totals balance has a
cheapest plan in whole numbers: some plan ships whole tonnes on every route and no plan, whole or
fractional, has a smaller haulage bill. -/
theorem shipping_has_whole_cheapest_plan {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → ℕ) (b : κ → ℕ) (hbal : ∑ i, a i = ∑ j, b j) (c : ι → κ → ℝ) :
    ∃ x ∈ shippingPlans (fun i => (a i : ℝ)) (fun j => (b j : ℝ)),
      (∀ i j, ∃ n : ℕ, x i j = n) ∧
      ∀ y ∈ shippingPlans (fun i => (a i : ℝ)) (fun j => (b j : ℝ)),
        haulageCost c x ≤ haulageCost c y := by
  set P := shippingPlans (fun i => (a i : ℝ)) (fun j => (b j : ℝ)) with hP
  have hmemP : ∀ x, x ∈ P ↔ (∀ i, ∑ j, x i j = a i) ∧ (∀ j, ∑ i, x i j = b j) ∧
      ∀ i j, 0 ≤ x i j := fun x => Iff.rfl
  have hbalR : ∑ j, (b j : ℝ) = ∑ i, (a i : ℝ) := by exact_mod_cast hbal.symm
  -- a plan exists
  have hne : P.Nonempty := by
    by_cases hT : ∑ i, (a i : ℝ) = 0
    · have ha0 : ∀ i, (a i : ℝ) = 0 := fun i =>
        (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => Nat.cast_nonneg (a i))).mp hT i
          (Finset.mem_univ i)
      have hb0 : ∀ j, (b j : ℝ) = 0 := fun j =>
        (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => Nat.cast_nonneg (b j))).mp
          (hbalR.trans hT) j (Finset.mem_univ j)
      refine ⟨0, (hmemP 0).mpr ⟨fun i => ?_, fun j => ?_, fun i j => le_rfl⟩⟩
      · simp [ha0 i]
      · simp [hb0 j]
    · refine ⟨fun i j => (a i : ℝ) * b j / ∑ i, (a i : ℝ), (hmemP _).mpr
        ⟨fun i => ?_, fun j => ?_, fun i j => by positivity⟩⟩
      · rw [← Finset.sum_div, ← Finset.mul_sum, hbalR]; field_simp
      · rw [← Finset.sum_div, ← Finset.sum_mul]; field_simp
  have hclosed : IsClosed P := by
    have : P = (⋂ i, {x : ι → κ → ℝ | ∑ j, x i j = a i}) ∩
        (⋂ j, {x : ι → κ → ℝ | ∑ i, x i j = b j}) ∩
        ⋂ i, ⋂ j, {x : ι → κ → ℝ | 0 ≤ x i j} := by
      ext x
      rw [hmemP]
      simp only [Set.mem_inter_iff, Set.mem_iInter, Set.mem_ofPred_eq, and_assoc]
    rw [this]
    refine ((isClosed_iInter fun i => isClosed_eq (by fun_prop) (by fun_prop)).inter
      (isClosed_iInter fun j => isClosed_eq (by fun_prop) (by fun_prop))).inter
      (isClosed_iInter fun i => isClosed_iInter fun j => isClosed_le (by fun_prop) (by fun_prop))
  have hsub : P ⊆ Set.Icc 0 (fun i _ => (a i : ℝ)) := by
    intro x hx
    obtain ⟨hr, _, hnn⟩ := (hmemP x).mp hx
    refine ⟨fun i j => hnn i j, fun i j => ?_⟩
    show x i j ≤ (a i : ℝ)
    rw [← hr i]
    exact Finset.single_le_sum (f := fun j => x i j) (fun j _ => hnn i j) (Finset.mem_univ j)
  have hcomp : IsCompact P := isCompact_Icc.of_isClosed_subset hclosed hsub
  have hcont : Continuous (haulageCost c) := by unfold haulageCost; fun_prop
  obtain ⟨x0, hx0P, hx0min⟩ := hcomp.exists_isMinOn hne hcont.continuousOn
  have hx0min' : ∀ y ∈ P, haulageCost c x0 ≤ haulageCost c y := fun y hy => hx0min hy
  set Mset := P ∩ {x | haulageCost c x ≤ haulageCost c x0} with hMset
  have hMcomp : IsCompact Mset := hcomp.inter_right (isClosed_le hcont continuous_const)
  obtain ⟨z, hz⟩ := hMcomp.extremePoints_nonempty ⟨x0, hx0P, show haulageCost c x0 ≤ haulageCost c x0 from le_rfl⟩
  obtain ⟨⟨hzP, hzle⟩, hzext⟩ := mem_extremePoints.mp hz
  have hzext' : z ∈ Set.extremePoints ℝ P := by
    refine mem_extremePoints.mpr ⟨hzP, fun y1 hy1 y2 hy2 hseg => ?_⟩
    obtain ⟨s, t, hs, ht, hst, hzeq⟩ := hseg
    have hcz : haulageCost c z = s * haulageCost c y1 + t * haulageCost c y2 := by
      rw [← hzeq, nf_cost_combo]
    have hz' : haulageCost c z ≤ haulageCost c x0 := hzle
    have hy1le : haulageCost c y1 ≤ haulageCost c x0 := by
      by_contra h
      push Not at h
      have := mul_pos hs (sub_pos.mpr h)
      have := mul_nonneg ht.le (sub_nonneg.mpr (hx0min' y2 hy2))
      have : s * haulageCost c x0 + t * haulageCost c x0 = haulageCost c x0 := by
        rw [← add_mul, hst, one_mul]
      linarith
    have hy2le : haulageCost c y2 ≤ haulageCost c x0 := by
      by_contra h
      push Not at h
      have := mul_pos ht (sub_pos.mpr h)
      have := mul_nonneg hs.le (sub_nonneg.mpr (hx0min' y1 hy1))
      have : s * haulageCost c x0 + t * haulageCost c x0 = haulageCost c x0 := by
        rw [← add_mul, hst, one_mul]
      linarith
    exact hzext y1 ⟨hy1, hy1le⟩ y2 ⟨hy2, hy2le⟩ ⟨s, t, hs, ht, hst, hzeq⟩
  exact ⟨z, hzP, shipping_corner_is_whole a b hbal z hzext',
    fun y hy => hzle.trans (hx0min' y hy)⟩

/-- The price certificate. If prices `u i` at the mills and `v j` at the columns leave no route
costing less than the prices at its two ends add up to (`c i j - u i - v j ≥ 0`), and every route
the plan uses costs exactly that (`c i j - u i - v j = 0` wherever `x i j > 0`), then the plan is a
cheapest plan, and its bill equals the price floor `∑ a i * u i + ∑ b j * v j`. -/
theorem shipping_prices_certify_cheapest {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → ℝ) (b : κ → ℝ) (c : ι → κ → ℝ) (u : ι → ℝ) (v : κ → ℝ)
    (x : ι → κ → ℝ) (hx : x ∈ shippingPlans a b)
    (hred : ∀ i j, 0 ≤ c i j - u i - v j)
    (hslack : ∀ i j, 0 < x i j → c i j - u i - v j = 0) :
    haulageCost c x = ∑ i, a i * u i + ∑ j, b j * v j ∧
      ∀ y ∈ shippingPlans a b, haulageCost c x ≤ haulageCost c y := by
  have key : ∀ y ∈ shippingPlans a b, haulageCost c y =
      ∑ i, a i * u i + ∑ j, b j * v j + ∑ i, ∑ j, (c i j - u i - v j) * y i j := by
    intro y hy
    obtain ⟨hr, hc, _⟩ := hy
    unfold haulageCost
    have e1 : ∑ i, a i * u i = ∑ i, ∑ j, u i * y i j := by
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [← hr i, Finset.sum_mul]; exact Finset.sum_congr rfl fun j _ => by ring
    have e2 : ∑ j, b j * v j = ∑ i, ∑ j, v j * y i j := by
      rw [Finset.sum_comm]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [← hc j, Finset.sum_mul]; exact Finset.sum_congr rfl fun i _ => by ring
    rw [e1, e2, ← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun j _ => by ring
  have hx0 : ∑ i, ∑ j, (c i j - u i - v j) * x i j = 0 := by
    refine Finset.sum_eq_zero fun i _ => Finset.sum_eq_zero fun j _ => ?_
    rcases (hx.2.2 i j).lt_or_eq with h | h
    · rw [hslack i j h, zero_mul]
    · rw [← h, mul_zero]
  refine ⟨by rw [key x hx, hx0, add_zero], fun y hy => ?_⟩
  rw [key x hx, key y hy, hx0]
  have : 0 ≤ ∑ i, ∑ j, (c i j - u i - v j) * y i j :=
    Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ => mul_nonneg (hred i j) (hy.2.2 i j)
  linarith

/-! The card's worked numbers. Rows: North, South. Columns: W1, W2, W3, spare. -/

/-- Cost per tonne, in pounds. -/
def cardCost : Fin 2 → Fin 4 → ℤ := ![![6, 7, 10, 0], ![7, 6, 7, 0]]
/-- The cheapest plan: North sends 25 to W1, 5 to W2, keeps 10; South sends 15 to W2, 15 to W3. -/
def cardBest : Fin 2 → Fin 4 → ℤ := ![![25, 5, 0, 10], ![0, 15, 15, 0]]
/-- The northwest-corner starting plan. -/
def cardNorthwest : Fin 2 → Fin 4 → ℤ := ![![25, 15, 0, 0], ![0, 5, 15, 10]]
/-- Prices at the mills and at the columns. -/
def cardU : Fin 2 → ℤ := ![0, -1]
def cardV : Fin 4 → ℤ := ![6, 7, 8, 0]
def cardSupply : Fin 2 → ℤ := ![40, 30]
def cardDemand : Fin 4 → ℤ := ![25, 20, 15, 10]

-- Supply 70 t, demand 60 t; the spare column takes the 10 t difference, so totals balance.
example : ∑ i, cardSupply i = 70 ∧ cardDemand 0 + cardDemand 1 + cardDemand 2 = 60 ∧
    ∑ i, cardSupply i = ∑ j, cardDemand j := by decide

-- The cheapest plan meets every row and column, in whole tonnes.
example : (∀ i, ∑ j, cardBest i j = cardSupply i) ∧ (∀ j, ∑ i, cardBest i j = cardDemand j) ∧
    ∀ i j, 0 ≤ cardBest i j := by decide

-- The northwest-corner plan meets every row and column too.
example : (∀ i, ∑ j, cardNorthwest i j = cardSupply i) ∧
    (∀ j, ∑ i, cardNorthwest i j = cardDemand j) ∧ ∀ i j, 0 ≤ cardNorthwest i j := by decide

-- Northwest-corner cost 390; after shifting 10 t round the loop at 1 pound a tonne: 380.
example : ∑ i, ∑ j, cardCost i j * cardNorthwest i j = 390 := by decide
example : ∑ i, ∑ j, cardCost i j * cardBest i j = 380 := by decide
example : (0 : ℤ) - 0 + 6 - 7 = -1 ∧ min 10 15 = 10 ∧ 390 - 10 * 1 = 380 := by decide

-- Leaf by leaf: South has 30 - 15 = 15 left for W2; W2 needs 20 - 15 = 5 from North;
-- North's total 25 + 5 + 10 checks.
example : (30 : ℤ) - 15 = 15 ∧ (20 : ℤ) - 15 = 5 ∧ (25 : ℤ) + 5 + 10 = 40 := by decide

-- Prices: no reduced cost below 0, and every used route has reduced cost 0.
example : (∀ i j, 0 ≤ cardCost i j - cardU i - cardV j) ∧
    ∀ i j, 0 < cardBest i j → cardCost i j - cardU i - cardV j = 0 := by decide

-- Reduced costs of the unused routes North-W3, South-W1, South-spare: 2, 2, 1.
example : cardCost 0 2 - cardU 0 - cardV 2 = 2 ∧ cardCost 1 0 - cardU 1 - cardV 0 = 2 ∧
    cardCost 1 3 - cardU 1 - cardV 3 = 1 := by decide

-- The price floor is 380, the same as the plan's bill.
example : ∑ i, cardSupply i * cardU i + ∑ j, cardDemand j * cardV j = 380 := by decide

-- With a 55-hour limit on South's lorry (3, 2, 2 hours a tonne to W1, W2, W3): sending South
-- 12 t to W2 uses 54 hours and costs 383; sending 13 t uses 56 hours, over the limit.
example : 2 * 12 + 2 * 15 = 54 ∧ 2 * 13 + 2 * 15 = 56 ∧ 56 > 55 := by decide
example : ∑ i, ∑ j, cardCost i j * (![![25, 8, 0, 7], ![0, 12, 15, 3]] : Fin 2 → Fin 4 → ℤ) i j
    = 383 := by decide

#print axioms shipping_corner_is_whole
#print axioms shipping_has_whole_cheapest_plan
#print axioms shipping_prices_certify_cheapest
