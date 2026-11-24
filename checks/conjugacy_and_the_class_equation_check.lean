-- Conjugacy and the class equation: a finite group's size is its centre's size plus the index of a centraliser for each bigger conjugacy class, and a group of prime-power size has a centre with more than one member.
import Mathlib.GroupTheory.ClassEquation
import Mathlib.GroupTheory.PGroup
import Mathlib.GroupTheory.Index
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.GroupTheory.Perm.Fin

open ConjClasses

/-- The class of `x` has as many members as the centraliser of `x` has cosets. -/
theorem card_carrier_mk_eq_index (G : Type*) [Group G] (x : G) :
    Nat.card (ConjClasses.mk x).carrier = (Subgroup.centralizer {x}).index := by
  rw [Subgroup.index_centralizer_eq_ncard, Nat.card_coe_set_eq]
  rfl

/-- **The class equation.** In a finite group, pick one member from each conjugacy class. Then
the group's size is the size of its centre plus, for each class with more than one member, the
index of the centraliser of the chosen member:
`|G| = |Z(G)| + ∑ [G : C(xᵢ)]`. -/
theorem class_equation (G : Type*) [Group G] [Finite G]
    (rep : ConjClasses G → G) (hrep : ∀ c, ConjClasses.mk (rep c) = c) :
    Nat.card G = Nat.card (Subgroup.center G)
      + ∑ᶠ c ∈ ConjClasses.noncenter G, (Subgroup.centralizer {rep c}).index := by
  rw [← Group.nat_card_center_add_sum_card_noncenter_eq_card G]
  congr 1
  refine finsum_mem_congr rfl fun c _ => ?_
  conv_lhs => rw [← hrep c]
  exact card_carrier_mk_eq_index G (rep c)

/-- **Each class size is a count of cosets.** In a finite group, the class of `x` times the
centraliser of `x` has the group's size, so the class size is the index `[G : C(x)]` and divides
the group's size; and the class has exactly one member when `x` is in the centre. -/
theorem class_size_eq_index_centralizer (G : Type*) [Group G] [Finite G] (x : G) :
    Nat.card (ConjClasses.mk x).carrier * Nat.card (Subgroup.centralizer {x}) = Nat.card G ∧
    Nat.card (ConjClasses.mk x).carrier = (Subgroup.centralizer {x}).index ∧
    Nat.card (ConjClasses.mk x).carrier ∣ Nat.card G ∧
    (Nat.card (ConjClasses.mk x).carrier = 1 ↔ x ∈ Subgroup.center G) := by
  have h := card_carrier_mk_eq_index G x
  refine ⟨?_, h, ?_, ?_⟩
  · rw [h, mul_comm]
    exact Subgroup.card_mul_index _
  · rw [h]
    exact Subgroup.index_dvd_card _
  · rw [h, Subgroup.index_eq_one, Subgroup.centralizer_eq_top_iff_subset,
      Set.singleton_subset_iff, SetLike.mem_coe]

/-- **A prime-power group has a centre bigger than one.** If a finite group has size `p ^ k`
for a prime `p` and `k` at least 1, its centre's size is a multiple of `p` and more than 1. -/
theorem prime_power_group_has_big_centre {G : Type*} [Group G] [Finite G] {p k : ℕ}
    (hp : p.Prime) (hk : 1 ≤ k) (hG : Nat.card G = p ^ k) :
    p ∣ Nat.card (Subgroup.center G) ∧ 1 < Nat.card (Subgroup.center G) := by
  have : Fact p.Prime := ⟨hp⟩
  obtain ⟨j, hj, hc⟩ := IsPGroup.card_center_eq_prime_pow hG hk
  rw [hc]
  exact ⟨dvd_pow_self p hj.ne', Nat.one_lt_pow hj.ne' hp.one_lt⟩

/-! ### The card's worked numbers

The tile group is `DihedralGroup 4`. The card's turn `r_k` is `r k`, and the card's flip `r_kf`
(position `i` goes to `k - i`) is `sr (-k)`: so r0f = `sr 0`, r1f = `sr 3`, r2f = `sr 2`,
r3f = `sr 1`. Products are read as on the card: `g * x` means do `x` first, then `g`. -/

open DihedralGroup

/-- The tile has 8 moves. -/
example : Fintype.card (DihedralGroup 4) = 8 := by decide

/-- Conjugating r0f by r1 gives r2f. -/
example : (r 1 : DihedralGroup 4) * sr 0 * (r 1)⁻¹ = sr 2 := by decide

/-- The eight moves fall into 5 classes. -/
example : (Finset.univ.image (fun x : DihedralGroup 4 =>
    Finset.univ.image (fun g : DihedralGroup 4 => g * x * g⁻¹))).card = 5 := by decide

/-- The class sizes: r0 and r2 alone; r1 with r3; r0f with r2f; r1f with r3f. -/
example : Finset.univ.image (fun g : DihedralGroup 4 => g * r 0 * g⁻¹) = {r 0} ∧
    Finset.univ.image (fun g : DihedralGroup 4 => g * r 2 * g⁻¹) = {r 2} ∧
    Finset.univ.image (fun g : DihedralGroup 4 => g * r 1 * g⁻¹) = {r 1, r 3} ∧
    Finset.univ.image (fun g : DihedralGroup 4 => g * sr 0 * g⁻¹) = {sr 0, sr 2} ∧
    Finset.univ.image (fun g : DihedralGroup 4 => g * sr 3 * g⁻¹) = {sr 3, sr 1} := by decide

/-- The centraliser of r1 is the four turns; those of r0f and r1f have 4 moves each. -/
example : Finset.univ.filter (fun g : DihedralGroup 4 => g * r 1 = r 1 * g)
      = {r 0, r 1, r 2, r 3} ∧
    Finset.univ.filter (fun g : DihedralGroup 4 => g * sr 0 = sr 0 * g)
      = {r 0, r 2, sr 0, sr 2} ∧
    (Finset.univ.filter (fun g : DihedralGroup 4 => g * sr 3 = sr 3 * g)).card = 4 := by decide

/-- The centre is do-nothing and the half turn. -/
example : Finset.univ.filter (fun z : DihedralGroup 4 => ∀ g, z * g = g * z) = {r 0, r 2} := by
  decide

/-- The class equation on the tile: 8 = 2 + 8/4 + 8/4 + 8/4 = 2 + 2 + 2 + 2. -/
example : (8 : ℕ) = 2 + 8 / 4 + 8 / 4 + 8 / 4 := by norm_num

/-- The subgroup {r0, r0f} has normaliser {r0, r2, r0f, r2f}, and 8 / 4 = 2 conjugate subgroups:
{r0, r0f} and {r0, r2f}. -/
example : Finset.univ.filter (fun g : DihedralGroup 4 =>
      ({r 0, sr 0} : Finset (DihedralGroup 4)).image (fun h => g * h * g⁻¹) = {r 0, sr 0})
      = {r 0, r 2, sr 0, sr 2} ∧
    Finset.univ.image (fun g : DihedralGroup 4 =>
      ({r 0, sr 0} : Finset (DihedralGroup 4)).image (fun h => g * h * g⁻¹))
      = {{r 0, sr 0}, {r 0, sr 2}} := by decide

/-- Conjugating by the four turns only splits the tile into 6 classes, not 5. -/
example : (Finset.univ.image (fun x : DihedralGroup 4 =>
    ({r 0, r 1, r 2, r 3} : Finset (DihedralGroup 4)).image (fun g => g * x * g⁻¹))).card = 6 := by
  decide

/-- The rearrangements of three things: 6 = 1 + 2 + 3, in 3 classes, with centre do-nothing
alone. -/
example : (Finset.univ.image (fun x : Equiv.Perm (Fin 3) =>
      Finset.univ.image (fun g : Equiv.Perm (Fin 3) => g * x * g⁻¹))).image Finset.card
      = {1, 2, 3} ∧
    (Finset.univ.image (fun x : Equiv.Perm (Fin 3) =>
      Finset.univ.image (fun g : Equiv.Perm (Fin 3) => g * x * g⁻¹))).card = 3 ∧
    (Finset.univ.filter (fun z : Equiv.Perm (Fin 3) => ∀ g, z * g = g * z)).card = 1 := by
  decide

#print axioms card_carrier_mk_eq_index
#print axioms class_equation
#print axioms class_size_eq_index_centralizer
#print axioms prime_power_group_has_big_centre
