-- CW complexes: the torus recipe of one point, two edges a and b and one square glued on abAB gives the loop group ⟨a, b | abAB⟩, which is the pairs of whole numbers under addition, while without the square abAB never shrinks and with one arrow flipped the commuting group has rank 1 and torsion 2.
import Mathlib.GroupTheory.PresentedGroup
import Mathlib.GroupTheory.Abelianization.Defs
import Mathlib.GroupTheory.FreeGroup.Reduce
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.Group
import Mathlib.Tactic.FinCases
import Mathlib.Data.ZMod.Basic

/-! The edges `a` and `b` are the generators `FreeGroup.of 0` and `FreeGroup.of 1` of the free
group on two letters, `FreeGroup (Fin 2)`: the loop group of the figure eight, the 1-skeleton.
A capital letter is an inverse: `A` is `a⁻¹`, `B` is `b⁻¹`.
A presentation `⟨a, b | r⟩` is Mathlib's `PresentedGroup {r}`: words in `a`, `b` and their
inverses, with the rim word `r` of each 2-cell set equal to 1.
The pairs of whole numbers `ℤ²` under addition are `Multiplicative (ℤ × ℤ)` as a group;
`ofAdd (m, n)` is the pair `(m, n)`: `m` net shoulder turns, `n` net elbow turns.
The lift of a word to the square grid, one step right for `a` and one step up for `b`, is
`gridEnd`, the group map from the free group sending `a` to `(1, 0)` and `b` to `(0, 1)`. -/

/-- The rim word `abAB` of the torus's square. -/
def torusRim : FreeGroup (Fin 2) :=
  FreeGroup.of 0 * FreeGroup.of 1 * (FreeGroup.of 0)⁻¹ * (FreeGroup.of 1)⁻¹

/-- The rim word `abAb` of the Klein bottle's square: the torus's square with one `b` flipped. -/
def kleinRim : FreeGroup (Fin 2) :=
  FreeGroup.of 0 * FreeGroup.of 1 * (FreeGroup.of 0)⁻¹ * FreeGroup.of 1

/-- Where a word's lift to the square grid ends: one step right per `a`, one step up per `b`. -/
def gridEnd : FreeGroup (Fin 2) →* Multiplicative (ℤ × ℤ) :=
  FreeGroup.lift fun i => Multiplicative.ofAdd (if i = 0 then ((1 : ℤ), (0 : ℤ)) else (0, 1))

abbrev TG := PresentedGroup ({torusRim} : Set (FreeGroup (Fin 2)))
#print axioms TG

theorem torus_of_commute : Commute (PresentedGroup.of 0 : TG) (PresentedGroup.of 1) := by
  have h : PresentedGroup.mk ({torusRim} : Set (FreeGroup (Fin 2))) torusRim = 1 :=
    PresentedGroup.one_of_mem rfl
  simp only [torusRim] at h
  change (PresentedGroup.of 0 : TG) * PresentedGroup.of 1 * (PresentedGroup.of 0)⁻¹ *
    (PresentedGroup.of 1)⁻¹ = 1 at h
  rw [mul_inv_eq_one, mul_inv_eq_iff_eq_mul] at h
  exact h
#print axioms torus_of_commute

theorem gridEnd_torusRim : gridEnd torusRim = 1 := by decide
#print axioms gridEnd_torusRim

def torusInv : Multiplicative (ℤ × ℤ) →* TG :=
  MonoidHom.mk' (fun x => (PresentedGroup.of 0 : TG) ^ (Multiplicative.toAdd x).1 *
      (PresentedGroup.of 1 : TG) ^ (Multiplicative.toAdd x).2) (by
    intro x y
    simp only [toAdd_mul, Prod.fst_add, Prod.snd_add, zpow_add]
    have := (torus_of_commute.zpow_zpow (Multiplicative.toAdd y).1
      (Multiplicative.toAdd x).2)
    simp only [mul_assoc]
    rw [← mul_assoc (_ ^ (Multiplicative.toAdd y).1), this.eq]
    simp only [mul_assoc])
#print axioms torusInv

def torusFwd : TG →* Multiplicative (ℤ × ℤ) :=
  PresentedGroup.toGroup (f := fun i => Multiplicative.ofAdd (if i = 0 then ((1 : ℤ), (0 : ℤ)) else (0, 1)))
    (by rintro r rfl; exact gridEnd_torusRim)
#print axioms torusFwd

abbrev KG := PresentedGroup ({kleinRim} : Set (FreeGroup (Fin 2)))
#print axioms KG

theorem klein_lift_rim :
    FreeGroup.lift (fun i : Fin 2 => Multiplicative.ofAdd
      (if i = 0 then ((1 : ℤ), (0 : ZMod 2)) else (0, 1))) kleinRim = 1 := by decide
#print axioms klein_lift_rim

def kleinFwd : Abelianization KG →* Multiplicative (ℤ × ZMod 2) :=
  Abelianization.lift (PresentedGroup.toGroup (by rintro r rfl; exact klein_lift_rim))
#print axioms kleinFwd

theorem klein_sq_eq_one :
    (Abelianization.of (PresentedGroup.of 1 : KG)) ^ 2 = 1 := by
  have h : Abelianization.of (PresentedGroup.mk ({kleinRim} : Set (FreeGroup (Fin 2))) kleinRim) = 1 := by
    rw [PresentedGroup.one_of_mem rfl, map_one]
  simp only [kleinRim] at h
  change Abelianization.of (PresentedGroup.of 0 : KG) * Abelianization.of (PresentedGroup.of 1 : KG) *
    (Abelianization.of (PresentedGroup.of 0 : KG))⁻¹ * Abelianization.of (PresentedGroup.of 1 : KG) = 1 at h
  rw [mul_right_comm (Abelianization.of (PresentedGroup.of 0 : KG)), mul_inv_cancel, one_mul] at h
  rw [pow_two]; exact h
#print axioms klein_sq_eq_one

theorem klein_b_two :
    zmultiplesHom _ (Additive.ofMul (Abelianization.of (PresentedGroup.of 1 : KG))) (2 : ℤ) = 0 := by
  simp only [zmultiplesHom_apply]
  rw [← ofMul_zpow]
  simp [klein_sq_eq_one]
#print axioms klein_b_two

def kleinBackAdd : ℤ × ZMod 2 →+ Additive (Abelianization KG) :=
  (zmultiplesHom _ (Additive.ofMul (Abelianization.of (PresentedGroup.of 0 : KG)))).coprod
    (ZMod.lift 2 ⟨zmultiplesHom _ (Additive.ofMul (Abelianization.of (PresentedGroup.of 1 : KG))),
      klein_b_two⟩)
#print axioms kleinBackAdd

def kleinBack : Multiplicative (ℤ × ZMod 2) →* Abelianization KG :=
  AddMonoidHom.toMultiplicativeLeft kleinBackAdd
#print axioms kleinBack

theorem kleinBack_b :
    kleinBack (Multiplicative.ofAdd (0, 1)) = Abelianization.of (PresentedGroup.of 1 : KG) := by
  have h := ZMod.lift_coe 2 ⟨zmultiplesHom _ (Additive.ofMul (Abelianization.of (PresentedGroup.of 1 : KG))),
    klein_b_two⟩ (1 : ℤ)
  rw [Int.cast_one] at h
  simp [kleinBack, kleinBackAdd, h]
#print axioms kleinBack_b

theorem mult_int_zmod_two_hom_ext {M : Type*} [Group M] {F G : Multiplicative (ℤ × ZMod 2) →* M}
    (h1 : F (Multiplicative.ofAdd (1, 0)) = G (Multiplicative.ofAdd (1, 0)))
    (h2 : F (Multiplicative.ofAdd (0, 1)) = G (Multiplicative.ofAdd (0, 1))) : F = G := by
  refine MonoidHom.ext fun x => ?_
  obtain ⟨j, hj⟩ := ZMod.intCast_surjective (Multiplicative.toAdd x).2
  have hx : x = Multiplicative.ofAdd ((1 : ℤ), (0 : ZMod 2)) ^ (Multiplicative.toAdd x).1 *
      Multiplicative.ofAdd ((0 : ℤ), (1 : ZMod 2)) ^ j := by
    rw [← ofAdd_zsmul, ← ofAdd_zsmul, ← ofAdd_add, ← ofAdd_toAdd x]
    congr 1
    ext <;> simp [hj]
  rw [hx, map_mul, map_mul, map_zpow, map_zpow, map_zpow, map_zpow, h1, h2]
#print axioms mult_int_zmod_two_hom_ext

/-- **The torus's loop group is ℤ².** The group `⟨a, b | abAB⟩` read off the torus's cells
(one point, two edges `a` and `b`, one square glued along `abAB`) is isomorphic to the pairs
of whole numbers under addition, by the map that sends `a` to `(1, 0)` and `b` to `(0, 1)`:
every word is sent to its net shoulder and elbow turns, so a plan shrinks to nothing exactly
when its lift to the grid closes up. -/
theorem torus_presentation_iso_int_prod_int :
    ∃ e : PresentedGroup ({torusRim} : Set (FreeGroup (Fin 2))) ≃* Multiplicative (ℤ × ℤ),
      e (PresentedGroup.of 0) = Multiplicative.ofAdd (1, 0) ∧
        e (PresentedGroup.of 1) = Multiplicative.ofAdd (0, 1) := by
  refine ⟨MonoidHom.toMulEquiv torusFwd torusInv ?_ ?_, ?_, ?_⟩
  · apply PresentedGroup.ext
    intro i
    fin_cases i <;> simp [torusFwd, torusInv, PresentedGroup.toGroup.of]
  · refine MonoidHom.ext fun x => ?_
    simp [torusFwd, torusInv, PresentedGroup.toGroup.of, ← ofAdd_zsmul]
    rw [← ofAdd_add, Prod.mk_add_mk, add_zero, zero_add, ofAdd_toAdd]
  · simp [torusFwd, PresentedGroup.toGroup.of]
  · simp [torusFwd, PresentedGroup.toGroup.of]

/-- **Without the square, `abAB` does not shrink.** On the figure eight, whose loop group is
the free group on `a` and `b`, the torus's rim word `abAB` is not the trivial loop. -/
theorem figure_eight_rim_ne_one : torusRim ≠ 1 := by
  decide

/-- **One arrow flipped gives the Klein bottle.** For the recipe with rim `abAb`, the
abelianised group (every pair of letters made to commute) is `ℤ × ℤ/2`: rank 1, torsion `[2]`. -/
theorem klein_abelianization_iso_int_prod_zmod_two :
    Nonempty (Abelianization (PresentedGroup ({kleinRim} : Set (FreeGroup (Fin 2)))) ≃*
      Multiplicative (ℤ × ZMod 2)) := by
  refine ⟨MonoidHom.toMulEquiv kleinFwd kleinBack ?_ ?_⟩
  · apply Abelianization.hom_ext
    apply PresentedGroup.ext
    intro i
    fin_cases i
    · simp [kleinFwd, kleinBack, kleinBackAdd, PresentedGroup.toGroup.of]
    · have h := kleinBack_b
      simp only [MonoidHom.comp_apply, MonoidHom.id_apply]
      simp [kleinFwd, PresentedGroup.toGroup.of]
      simpa using h
  · apply mult_int_zmod_two_hom_ext
    · simp [kleinFwd, kleinBack, kleinBackAdd, PresentedGroup.toGroup.of]
    · rw [MonoidHom.comp_apply, kleinBack_b]
      simp [kleinFwd, PresentedGroup.toGroup.of]

-- Euler characteristics from the cell counts c₀ - c₁ + c₂ - c₃.
example : (1 : ℤ) - 1 = 0 := by decide                    -- circle, 1 point and 1 edge
example : (1 : ℤ) - 2 + 1 = 0 := by decide                -- torus, 1 point, 2 edges, 1 square
example : (1 : ℤ) - 2 = -1 := by decide                   -- figure eight
example : (1 : ℤ) + 1 = 2 := by decide                    -- sphere, 1 point and 1 disc
example : (2 : ℤ) - 2 + 2 = 2 := by decide                -- sphere, 2 poles, 2 edges, 2 discs
example : (1 : ℤ) + 1 - 1 = 1 := by decide                -- solid ball
example : (1 : ℤ) - 3 + 3 - 1 = 0 := by decide            -- 3-torus box
example : (9 : ℤ) - 27 + 18 = 0 := by decide              -- torus by triangles
example : (4 : ℤ) - 6 + 4 = 2 := by decide                -- sphere by triangles

-- The arm plans lifted to the grid: abAB closes at (0, 0); aaaBB ends at (3, -2).
example : gridEnd torusRim = Multiplicative.ofAdd (0, 0) := by decide
example : gridEnd (FreeGroup.of 0 ^ 3 * (FreeGroup.of 1)⁻¹ ^ 2) =
    Multiplicative.ofAdd (3, -2) := by decide

-- Closed lifts on the grid against the formula C(L, L/2)²: 4, 36 and 400.
example : (Nat.choose 2 1) ^ 2 = 4 := by decide
example : (Nat.choose 4 2) ^ 2 = 36 := by decide
example : (Nat.choose 6 3) ^ 2 = 400 := by decide
example : (Nat.choose 8 4) ^ 2 = 4900 := by decide

-- Of the 256 words of length 4 in a, A, b, B, exactly 36 have net turns (0, 0).
example : (Finset.univ.filter fun w : Fin 4 → Fin 4 =>
    ((Finset.univ.filter fun i => w i = 0).card : ℤ) - (Finset.univ.filter fun i => w i = 1).card = 0 ∧
    ((Finset.univ.filter fun i => w i = 2).card : ℤ) - (Finset.univ.filter fun i => w i = 3).card = 0).card
    = 36 := by decide

#print axioms torus_presentation_iso_int_prod_int
#print axioms figure_eight_rim_ne_one
#print axioms klein_abelianization_iso_int_prod_zmod_two
