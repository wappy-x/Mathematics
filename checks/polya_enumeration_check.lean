-- Polya counting: for a finite group of moves rearranging a finite set of positions, putting k in every slot of the cycle index counts the k-colourings up to the moves, and putting y_1^i + ... + y_k^i in slot x_i counts them by how many positions get each colour.
import Mathlib.GroupTheory.GroupAction.Quotient
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.Algebra.MvPolynomial.Eval
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open MulAction

-- A move `g` acts on colourings `f : α → Fin k` by `(g • f) x = f (g⁻¹ • x)`: the paint rides
-- with the positions.
attribute [local instance] arrowAction

open Finset in
/-- Which cycle of `σ` a point lies on: a fixed point names itself, a moved point names its cycle. -/
def cycleTag {α : Type*} [Fintype α] [DecidableEq α] (σ : Equiv.Perm α) (x : α) :
    α ⊕ Equiv.Perm α :=
  if x ∈ σ.support then .inr (σ.cycleOf x) else .inl x

theorem cycleTag_eq_iff {α : Type*} [Fintype α] [DecidableEq α] (σ : Equiv.Perm α) (x y : α) :
    cycleTag σ x = cycleTag σ y ↔ σ.SameCycle x y := by
  unfold cycleTag
  by_cases hx : x ∈ σ.support <;> by_cases hy : y ∈ σ.support <;>
    simp only [hx, hy, ite_true, ite_false]
  · rw [Equiv.Perm.sameCycle_iff_cycleOf_eq_of_mem_support hx hy, Sum.inr.injEq]
  · simp only [reduceCtorEq, false_iff]
    intro h; exact hy (h.mem_support_iff.1 hx)
  · simp only [reduceCtorEq, false_iff]
    intro h; exact hx (h.mem_support_iff.2 hy)
  · rw [Sum.inl.injEq]
    constructor
    · rintro rfl; exact Equiv.Perm.SameCycle.refl _ _
    · intro h; exact h.eq_of_left (Equiv.Perm.notMem_support.1 hx)

theorem fixed_iff_const {α C : Type*} [Fintype α] [DecidableEq α] (σ : Equiv.Perm α)
    (f : α → C) :
    (∀ x, f (σ⁻¹ x) = f x) ↔ ∀ x y, cycleTag σ x = cycleTag σ y → f x = f y := by
  simp only [cycleTag_eq_iff]
  constructor
  · rintro h x y ⟨i, rfl⟩
    have key : ∀ n : ℤ, f ((σ ^ n) x) = f x := by
      intro n
      induction n using Int.induction_on with
      | zero => simp
      | succ n ih =>
        rw [← ih, add_comm, zpow_add, zpow_one, Equiv.Perm.mul_apply]
        simpa using (h (σ ((σ ^ (n : ℤ)) x))).symm
      | pred n ih =>
        rw [← ih, sub_eq_add_neg, add_comm, zpow_add, zpow_neg_one, Equiv.Perm.mul_apply, h]
    exact (key i).symm
  · intro h x
    exact h _ _ ⟨1, by simp⟩

open Finset in
theorem sum_const_on_fibres {α β C R : Type*} [Fintype α] [DecidableEq α] [DecidableEq β] [Fintype C]
    [DecidableEq C] [CommSemiring R] (φ : α → β) (w : C → R)
    [DecidablePred fun f : α → C => ∀ x y, φ x = φ y → f x = f y] :
    ∑ f ∈ univ.filter (fun f : α → C => ∀ x y, φ x = φ y → f x = f y), ∏ x, w (f x) =
      ∏ b ∈ univ.image φ, ∑ c, w c ^ #{x | φ x = b} := by
  classical
  have hmem : ∀ x, φ x ∈ univ.image φ := fun x => mem_image_of_mem φ (mem_univ x)
  let e : (univ.image φ → C) ≃ {f : α → C // ∀ x y, φ x = φ y → f x = f y} :=
    { toFun := fun F => ⟨fun x => F ⟨φ x, hmem x⟩, fun x y h => by simp only [h]⟩
      invFun := fun f q => f.1 (Classical.choose (mem_image.1 q.2))
      left_inv := fun F => by
        funext q
        have := (Classical.choose_spec (mem_image.1 q.2)).2
        exact congrArg F (Subtype.ext this)
      right_inv := fun f => by
        apply Subtype.ext; funext x
        exact f.2 _ _ (Classical.choose_spec (mem_image.1 (hmem x))).2 }
  rw [Finset.sum_subtype (univ.filter _) (p := fun f : α → C => ∀ x y, φ x = φ y → f x = f y)
    (by intro f; simp only [mem_filter, mem_univ, true_and])]
  rw [← Finset.prod_coe_sort (univ.image φ), Fintype.prod_sum]
  symm
  refine Fintype.sum_equiv e _ _ (fun F => ?_)
  let G : β → R := fun b => if hb : b ∈ univ.image φ then w (F ⟨b, hb⟩) else 1
  have h1 : ∏ x, w ((e F).1 x) = ∏ x, G (φ x) := by
    refine prod_congr rfl (fun x _ => ?_)
    simp only [G, hmem x, ↓reduceDIte]
    rfl
  rw [h1, prod_comp, ← Finset.prod_coe_sort (univ.image φ)]
  refine prod_congr rfl (fun q _ => ?_)
  simp only [G, q.2, ↓reduceDIte]

open Finset in
theorem prod_fibres_cycleTag {α M : Type*} [Fintype α] [DecidableEq α] [CommMonoid M]
    (σ : Equiv.Perm α) (h : ℕ → M) :
    ∏ b ∈ univ.image (cycleTag σ), h #{x | cycleTag σ x = b} =
      (σ.partition.parts.map h).prod := by
  have himg : univ.image (cycleTag σ) = σ.supportᶜ.disjSum σ.cycleFactorsFinset := by
    ext b
    rcases b with x | c
    · simp only [mem_image, mem_univ, true_and, inl_mem_disjSum, mem_compl]
      constructor
      · rintro ⟨y, hy⟩
        unfold cycleTag at hy
        split_ifs at hy with hs
        rw [Sum.inl.injEq] at hy; rw [← hy]; exact hs
      · intro hx; exact ⟨x, by simp [cycleTag, hx]⟩
    · simp only [mem_image, mem_univ, true_and, inr_mem_disjSum]
      constructor
      · rintro ⟨y, hy⟩
        unfold cycleTag at hy
        split_ifs at hy with hs
        rw [Sum.inr.injEq] at hy
        exact hy ▸ Equiv.Perm.cycleOf_mem_cycleFactorsFinset_iff.2 hs
      · intro hc
        obtain ⟨a, ha⟩ := (Equiv.Perm.mem_cycleFactorsFinset_iff.1 hc).1.nonempty_support
        have ha' : a ∈ σ.support := Equiv.Perm.mem_cycleFactorsFinset_support_le hc ha
        exact ⟨a, by simp [cycleTag, ha', ← Equiv.Perm.cycle_is_cycleOf ha hc]⟩
  have h1 : ∀ x ∈ σ.supportᶜ, #{y | cycleTag σ y = .inl x} = 1 := by
    intro x hx
    rw [card_eq_one]
    refine ⟨x, ?_⟩
    ext y
    simp only [mem_filter, mem_univ, true_and, mem_singleton]
    unfold cycleTag
    split_ifs with hy
    · simp only [false_iff]
      rintro rfl; exact (mem_compl.1 hx) hy
    · rw [Sum.inl.injEq]
  have h2 : ∀ c ∈ σ.cycleFactorsFinset, #{y | cycleTag σ y = .inr c} = #c.support := by
    intro c hc
    congr 1
    ext y
    simp only [mem_filter, mem_univ, true_and]
    unfold cycleTag
    split_ifs with hy
    · rw [Sum.inr.injEq]
      constructor
      · rintro rfl
        exact Equiv.Perm.mem_support_cycleOf_iff.2 ⟨Equiv.Perm.SameCycle.refl _ _, hy⟩
      · intro hy'
        exact (Equiv.Perm.cycle_is_cycleOf hy' hc).symm
    · simp only [false_iff]
      intro hy'
      exact hy (Equiv.Perm.mem_cycleFactorsFinset_support_le hc hy')
  have h1' : ∀ x ∈ σ.supportᶜ, h #{y | cycleTag σ y = .inl x} = h 1 :=
    fun x hx => by rw [h1 x hx]
  have h2' : ∀ c ∈ σ.cycleFactorsFinset, h #{y | cycleTag σ y = .inr c} = h #c.support :=
    fun c hc => by rw [h2 c hc]
  rw [himg, prod_disjSum, prod_congr rfl h1', prod_congr rfl h2', prod_const, card_compl,
    Equiv.Perm.parts_partition, Multiset.map_add, Multiset.prod_add, Equiv.Perm.cycleType_def,
    Multiset.map_replicate, Multiset.prod_replicate, Multiset.map_map, mul_comm]
  rfl

open Finset in
theorem sum_fixed_prod_eq {α C R : Type*} [Fintype α] [DecidableEq α] [Fintype C]
    [DecidableEq C] [CommSemiring R] (σ : Equiv.Perm α) (w : C → R) :
    ∑ f ∈ univ.filter (fun f : α → C => ∀ x, f (σ⁻¹ x) = f x), ∏ x, w (f x) =
      (σ.partition.parts.map fun i => ∑ c, w c ^ i).prod := by
  classical
  rw [← prod_fibres_cycleTag σ (fun i => ∑ c, w c ^ i), ← sum_const_on_fibres]
  refine sum_congr ?_ (fun _ _ => rfl)
  ext f
  simp only [mem_filter, mem_univ, true_and]
  exact fixed_iff_const σ f


open Finset in
theorem coeff_sum_prod_X {α : Type*} [Fintype α] [DecidableEq α] {k : ℕ}
    (S : Finset (α → Fin k)) (e : Fin k → ℕ) :
    (∑ f ∈ S, ∏ x, (MvPolynomial.X (f x) : MvPolynomial (Fin k) ℚ)).coeff
        (Finsupp.equivFunOnFinite.symm e) =
      ((S.filter fun f => ∀ j, (univ.filter fun x => f x = j).card = e j).card : ℚ) := by
  rw [MvPolynomial.coeff_sum, Finset.card_filter, Nat.cast_sum]
  refine sum_congr rfl (fun f _ => ?_)
  have hX : ∏ x, (MvPolynomial.X (f x) : MvPolynomial (Fin k) ℚ) =
      MvPolynomial.monomial (∑ x, Finsupp.single (f x) 1) 1 := by
    rw [MvPolynomial.monomial_sum_one]; rfl
  have hiff : (∑ x, Finsupp.single (f x) 1 = Finsupp.equivFunOnFinite.symm e) ↔
      ∀ j, (univ.filter fun x => f x = j).card = e j := by
    rw [Finsupp.ext_iff]
    refine forall_congr' (fun j => ?_)
    rw [Finsupp.finsetSum_apply, Finsupp.coe_equivFunOnFinite_symm]
    simp only [Finsupp.single_apply, sum_boole, Nat.cast_id]
  rw [hX, MvPolynomial.coeff_monomial]
  by_cases h : ∀ j, (univ.filter fun x => f x = j).card = e j
  · simp [hiff.2 h, h]
  · simp [mt hiff.1 h, h]

#print axioms cycleTag_eq_iff
#print axioms fixed_iff_const
#print axioms sum_const_on_fibres
#print axioms prod_fibres_cycleTag
#print axioms sum_fixed_prod_eq
#print axioms coeff_sum_prod_X

section Polya

variable (G α : Type*) [Group G] [Fintype G] [MulAction G α] [Fintype α] [DecidableEq α]

/-- The lengths of the cycles into which move `g` splits the positions, one entry per cycle,
the fixed positions (cycles of length 1) included. -/
def cycleLengths (g : G) : Multiset ℕ :=
  (MulAction.toPerm g : Equiv.Perm α).partition.parts

/-- The cycle index `Z`: for each move, multiply one slot `x_i` per cycle of length `i`; add over
all moves; divide by the number of moves. The slot `x_i` is the variable `MvPolynomial.X i`. -/
noncomputable def cycleIndex : MvPolynomial ℕ ℚ :=
  (Fintype.card G : ℚ)⁻¹ •
    ∑ g : G, ((cycleLengths G α g).map fun i => (MvPolynomial.X i : MvPolynomial ℕ ℚ)).prod


omit [Fintype G] [Fintype α] [DecidableEq α] in
theorem mem_fixedBy_iff_perm {k : ℕ} (g : G) (f : α → Fin k) :
    f ∈ fixedBy (α → Fin k) g ↔ ∀ x, f ((MulAction.toPerm g : Equiv.Perm α)⁻¹ x) = f x := by
  rw [mem_fixedBy, funext_iff]; rfl

omit [Fintype G] in
open Finset in
theorem natCard_fixedBy_eq (k : ℕ) (g : G) :
    Nat.card (fixedBy (α → Fin k) g) = k ^ (cycleLengths G α g).card := by
  have hset : fixedBy (α → Fin k) g = ↑(univ.filter fun f : α → Fin k =>
      ∀ x, f ((MulAction.toPerm g : Equiv.Perm α)⁻¹ x) = f x) := by
    ext f
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq]
    exact mem_fixedBy_iff_perm G α g f
  rw [hset, Finset.coe_sort_coe, Nat.card_eq_finsetCard]
  have h := sum_fixed_prod_eq (MulAction.toPerm g : Equiv.Perm α) (fun _ : Fin k => (1 : ℕ))
  simp only [prod_const_one, one_pow, sum_const, card_univ, Fintype.card_fin, smul_eq_mul,
    mul_one, Multiset.map_const', Multiset.prod_replicate] at h
  rw [h]; rfl

/-- The colourings with colour count `e`; the moves keep them together. -/
def colourClass (k : ℕ) (e : Fin k → ℕ) : SubMulAction G (α → Fin k) where
  carrier := {f | ∀ j, (Finset.univ.filter fun x => f x = j).card = e j}
  smul_mem' g f hf j := by
    rw [← hf j]
    refine Finset.card_nbij' (fun x => g⁻¹ • x) (fun x => g • x) ?_ ?_ ?_ ?_
    · intro x hx
      simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
      exact hx
    · intro x hx
      simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
      show f (g⁻¹ • g • x) = j
      rw [inv_smul_smul]; exact hx
    · intro x _; simp
    · intro x _; simp

omit [Fintype G] [DecidableEq α] in
theorem natCard_orbits_colourClass (k : ℕ) (e : Fin k → ℕ) :
    Nat.card {o : orbitRel.Quotient G (α → Fin k) //
        ∃ f : α → Fin k, (Quotient.mk'' f : orbitRel.Quotient G (α → Fin k)) = o ∧
          ∀ j, (Finset.univ.filter fun x => f x = j).card = e j} =
      Nat.card (orbitRel.Quotient G (colourClass G α k e)) := by
  symm
  apply Nat.card_congr
  let ψ0 : orbitRel.Quotient G (colourClass G α k e) → orbitRel.Quotient G (α → Fin k) :=
    Quotient.map' Subtype.val (fun a b h => by
      obtain ⟨g, hg⟩ := h
      exact ⟨g, by rw [← hg]; rfl⟩)
  have hψ : ∀ q, ∃ f : α → Fin k, (Quotient.mk'' f : orbitRel.Quotient G (α → Fin k)) = ψ0 q ∧
      ∀ j, (Finset.univ.filter fun x => f x = j).card = e j := by
    intro q
    induction q using Quotient.inductionOn' with
    | h y => exact ⟨y.1, rfl, y.2⟩
  refine Equiv.ofBijective (fun q => ⟨ψ0 q, hψ q⟩) ⟨?_, ?_⟩
  · intro q1 q2 h
    induction q1 using Quotient.inductionOn'
    induction q2 using Quotient.inductionOn'
    rename_i a b
    have h' := congrArg Subtype.val h
    simp only [ψ0, Quotient.map'_mk''] at h'
    obtain ⟨g, hg⟩ := Quotient.exact' h'
    apply Quotient.sound'
    exact ⟨g, Subtype.ext hg⟩
  · rintro ⟨o, f, rfl, hf⟩
    exact ⟨Quotient.mk'' ⟨f, hf⟩, rfl⟩

omit [Fintype G] in
open Finset in
theorem natCard_fixedBy_colourClass (k : ℕ) (e : Fin k → ℕ) (g : G) :
    Nat.card (fixedBy (colourClass G α k e) g) =
      (univ.filter fun f : α → Fin k => (∀ x, f ((MulAction.toPerm g : Equiv.Perm α)⁻¹ x) = f x) ∧
        ∀ j, (univ.filter fun x => f x = j).card = e j).card := by
  rw [← Nat.card_eq_finsetCard]
  exact Nat.card_congr
    { toFun := fun y => ⟨y.1.1, mem_filter.2 ⟨mem_univ _,
        (mem_fixedBy_iff_perm G α g _).1 (congrArg Subtype.val y.2), y.1.2⟩⟩
      invFun := fun f => ⟨⟨f.1, (mem_filter.1 f.2).2.2⟩,
        Subtype.ext ((mem_fixedBy_iff_perm G α g f.1).2 (mem_filter.1 f.2).2.1)⟩
      left_inv := fun _ => rfl
      right_inv := fun _ => rfl }

#print axioms mem_fixedBy_iff_perm
#print axioms natCard_fixedBy_eq
#print axioms natCard_orbits_colourClass
#print axioms natCard_fixedBy_colourClass

/-- Pólya's theorem, the count: for a finite group of moves rearranging a finite set of
positions, with `k` colours free to go on any position and riding with the positions, the number
of different patterns (each orbit of colourings counted once) is the cycle index with `k` put in
every slot, `Z(k, k, k, …)`. -/
theorem card_patterns_eq_cycle_index_at_k (k : ℕ) :
    (Nat.card (orbitRel.Quotient G (α → Fin k)) : ℚ) =
      MvPolynomial.eval (fun _ => (k : ℚ)) (cycleIndex G α) := by
  classical
  have hB := MulAction.sum_card_fixedBy_eq_card_orbits_mul_card_group G (α → Fin k)
  simp only [← Nat.card_eq_fintype_card, natCard_fixedBy_eq] at hB
  have hG : (Nat.card G : ℚ) ≠ 0 := Nat.cast_ne_zero.2 Nat.card_pos.ne'
  simp only [cycleIndex, MvPolynomial.smul_eval, map_sum, map_multiset_prod, Multiset.map_map,
    Function.comp_def, MvPolynomial.eval_X, Multiset.map_const', Multiset.prod_replicate,
    ← Nat.card_eq_fintype_card]
  rw [eq_inv_mul_iff_mul_eq₀ hG, mul_comm]
  exact_mod_cast hB.symm

/-- Step 0: a colouring that a move leaves unchanged is one colour on each of its cycles, so with
`k` colours the move fixes exactly `k` to the power of its number of cycles. -/
theorem card_fixed_colourings_eq_pow_cycles (k : ℕ) (g : G) :
    Nat.card (fixedBy (α → Fin k) g) = k ^ (cycleLengths G α g).card := by
  exact natCard_fixedBy_eq G α k g

/-- Pólya's theorem, colour by colour: put `x_i = y_1^i + ⋯ + y_k^i` in every slot of the cycle
index. Then for every colour count `e` (colour `j` used on `e j` positions), the coefficient of
`y_1^(e 1) ⋯ y_k^(e k)` is the number of different patterns with exactly that colour count. -/
theorem card_patterns_of_colour_count_eq_coeff (k : ℕ) (e : Fin k → ℕ) :
    (Nat.card {o : orbitRel.Quotient G (α → Fin k) //
        ∃ f : α → Fin k, (Quotient.mk'' f : orbitRel.Quotient G (α → Fin k)) = o ∧
          ∀ j, (Finset.univ.filter fun x => f x = j).card = e j} : ℚ) =
      (MvPolynomial.aeval
          (fun i : ℕ => ∑ j : Fin k, (MvPolynomial.X j : MvPolynomial (Fin k) ℚ) ^ i)
          (cycleIndex G α)).coeff (Finsupp.equivFunOnFinite.symm e) := by
  classical
  rw [natCard_orbits_colourClass]
  have hB := MulAction.sum_card_fixedBy_eq_card_orbits_mul_card_group G (colourClass G α k e)
  simp only [← Nat.card_eq_fintype_card, natCard_fixedBy_colourClass] at hB
  have hg : ∀ g : G, (MvPolynomial.aeval
          (fun i : ℕ => ∑ j : Fin k, (MvPolynomial.X j : MvPolynomial (Fin k) ℚ) ^ i)
          ((cycleLengths G α g).map fun i => (MvPolynomial.X i : MvPolynomial ℕ ℚ)).prod).coeff
        (Finsupp.equivFunOnFinite.symm e) =
      ((Finset.univ.filter fun f : α → Fin k =>
        (∀ x, f ((MulAction.toPerm g : Equiv.Perm α)⁻¹ x) = f x) ∧
          ∀ j, (Finset.univ.filter fun x => f x = j).card = e j).card : ℚ) := by
    intro g
    rw [map_multiset_prod, Multiset.map_map]
    simp only [Function.comp_def, MvPolynomial.aeval_X]
    rw [cycleLengths, ← sum_fixed_prod_eq (MulAction.toPerm g : Equiv.Perm α)
      (fun j : Fin k => (MvPolynomial.X j : MvPolynomial (Fin k) ℚ)), coeff_sum_prod_X,
      Finset.filter_filter]
  have hG : (Nat.card G : ℚ) ≠ 0 := Nat.cast_ne_zero.2 Nat.card_pos.ne'
  rw [cycleIndex, map_smul, map_sum, MvPolynomial.coeff_smul, MvPolynomial.coeff_sum,
    Finset.sum_congr rfl (fun g _ => hg g), smul_eq_mul, Fintype.card_eq_nat_card,
    eq_inv_mul_iff_mul_eq₀ hG, mul_comm]
  exact_mod_cast hB.symm

end Polya

/-! ### The card's square tile, checked exactly

The tile's eight moves are Mathlib's `DihedralGroup 4`: `r k` turns by `k` quarters, sending
corner `i` to position `i + k`, and `sr k` flips, sending corner `i` to `-i - k`. A pattern paints
corners `0, 1, 2, 3`; a move carries every corner's colour to the position that corner lands on. -/

/-- Pattern `p` after move `a`: position `j` receives the colour of the corner `a` sends to `j`. -/
def tileMove {C : Type} : DihedralGroup 4 → (ZMod 4 → C) → (ZMod 4 → C)
  | .r k, p => fun j => p (j - k)
  | .sr k, p => fun j => p (-j - k)

-- Two colours: the eight moves fix 16 + 2 + 4 + 2 + 8 + 4 + 8 + 4 = 48 patterns, 48 / 8 = 6.
example : (∑ a : DihedralGroup 4,
    (Finset.univ.filter fun p : ZMod 4 → Fin 2 => tileMove a p = p).card) = 48 := by decide
example : ((16 + 4 + 12 + 16) / 8 : ℚ) = 6 := by norm_num

-- Listing the orbits of the 16 two-colour patterns gives the same 6 tiles.
example : (Finset.univ.image fun p : ZMod 4 → Fin 2 =>
    Finset.univ.image fun a : DihedralGroup 4 => tileMove a p).card = 6 := by decide

-- Three colours: (81 + 6 + 27 + 54) / 8 = 21, and four colours give 55.
example : ((81 + 6 + 27 + 54) / 8 : ℚ) = 21 := by norm_num
example : ((256 + 8 + 48 + 128) / 8 : ℚ) = 55 := by norm_num
set_option maxRecDepth 100000 in
example : (Finset.univ.image fun p : ZMod 4 → Fin 3 =>
    Finset.univ.image fun a : DihedralGroup 4 => tileMove a p).card = 21 := by decide

-- The colour substitution x_i = b^i + w^i in the tile's cycle index gives the inventory
-- b^4 + b^3 w + 2 b^2 w^2 + b w^3 + w^4.
example (b w : ℚ) :
    ((b + w) ^ 4 + 2 * (b ^ 4 + w ^ 4) + 3 * (b ^ 2 + w ^ 2) ^ 2
        + 2 * (b + w) ^ 2 * (b ^ 2 + w ^ 2)) / 8 =
      b ^ 4 + b ^ 3 * w + 2 * b ^ 2 * w ^ 2 + b * w ^ 3 + w ^ 4 := by ring

-- Two black corners: (6 + 0 + 6 + 4) / 8 = 2, and listing finds the same 2 tiles.
example : ((6 + 0 + 6 + 4) / 8 : ℚ) = 2 := by norm_num
example : ((Finset.univ.filter fun p : ZMod 4 → Fin 2 =>
    (Finset.univ.filter fun x => p x = 0).card = 2).image fun p =>
      Finset.univ.image fun a : DihedralGroup 4 => tileMove a p).card = 2 := by decide

-- The R R B B G Y bracelet: (180 + 4 + 4 + 4) / 12 = 16.
example : ((180 + 4 + 4 + 4) / 12 : ℚ) = 16 := by norm_num

#print axioms card_patterns_eq_cycle_index_at_k
#print axioms card_fixed_colourings_eq_pow_cycles
#print axioms card_patterns_of_colour_count_eq_coeff
