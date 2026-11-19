-- Gauss-Bonnet: on a closed surface cut into polygon patches, the local theorem on each patch adds up to a total curvature of 2π times V - E + F, and the angle defects of a mesh of flat panels total the same 2π times V - E + F.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.Card

open Finset Real

/-- Global Gauss-Bonnet from the local theorem (the card's Step 3, "add the panels, and the
edges cancel"). A closed surface, with no rim, is cut into `F` polygon patches with `V` corners
and `E` edges. Each patch's edge is walked with the patch on the left and split into sides
(the type `H`); side `h` lies on patch `face h`, starts at corner `start h`, runs along edge
`edge h`, and `α h` is the patch's inside angle at that starting corner. Every edge borders
exactly two sides, walked in opposite directions (`twin`), so reversing the walk flips the
sign of the edge's bending `kg` (its integral of geodesic curvature). If every patch obeys the
local theorem, curvature inside plus edge bending plus corner turns `π - α` equals `2π`, and
the angles round every corner make a full turn `2π`, then the total curvature of the surface
is `2π (V - E + F)`. -/
theorem total_curvature_eq_two_pi_mul_euler_char
    {V E F H : Type*} [Fintype V] [Fintype E] [Fintype F] [Fintype H]
    [DecidableEq V] [DecidableEq E] [DecidableEq F]
    (face : H → F) (start : H → V) (edge : H → E) (twin : H → H)
    (htwin : ∀ h, twin (twin h) = h) (htwin_ne : ∀ h, twin h ≠ h)
    (htwin_edge : ∀ h, edge (twin h) = edge h)
    (htwo : ∀ e, #{h | edge h = e} = 2)
    (curv : F → ℝ) (kg : H → ℝ) (α : H → ℝ)
    (hkg : ∀ h, kg (twin h) = -kg h)
    (hlocal : ∀ f, curv f + ∑ h with face h = f, kg h + ∑ h with face h = f, (π - α h) = 2 * π)
    (hvertex : ∀ v, ∑ h with start h = v, α h = 2 * π) :
    ∑ f, curv f =
      2 * π * ((Fintype.card V : ℝ) - Fintype.card E + Fintype.card F) := by
  have hH : (Fintype.card H : ℝ) = 2 * Fintype.card E := by
    have := Finset.card_eq_sum_card_fiberwise (f := edge) (s := (univ : Finset H))
      (t := (univ : Finset E)) (fun _ _ => mem_univ _)
    simp only [htwo, sum_const, card_univ, smul_eq_mul] at this
    rw [this]
    push_cast; ring
  have hkg0 : ∑ h, kg h = 0 := by
    have e : ∑ h, kg (twin h) = ∑ h, kg h :=
      Equiv.sum_comp (Function.Involutive.toPerm twin htwin) kg
    simp only [hkg, sum_neg_distrib] at e
    linarith
  have hα : ∑ h, α h = 2 * π * Fintype.card V := by
    rw [← Finset.sum_fiberwise univ start α]
    simp only [hvertex, sum_const, card_univ, nsmul_eq_mul]
    ring
  have hsum := Finset.sum_congr rfl (fun f (_ : f ∈ (univ : Finset F)) => hlocal f)
  rw [sum_add_distrib, sum_add_distrib, Finset.sum_fiberwise univ face kg,
    Finset.sum_fiberwise univ face (fun h => π - α h), sum_sub_distrib, hkg0, hα] at hsum
  simp only [sum_const, card_univ, nsmul_eq_mul] at hsum
  rw [hH] at hsum
  linarith

/-- A corner gap is curvature packed into a point (the card's Step 4). A closed surface, with
no rim, is built from `F` flat polygon panels with `V` corners and `E` edges; corner `h` of
panel `face h` sits at the surface corner `start h` with inside angle `α h`, and every edge
borders exactly two panel sides. A flat panel with `n` corners has angles adding to
`(n - 2) π`. Then the angle defects, `2π` minus the angles meeting at each corner, add up to
`2π (V - E + F)`, whatever the mesh. -/
theorem sum_angle_defects_eq_two_pi_mul_euler_char
    {V E F H : Type*} [Fintype V] [Fintype E] [Fintype F] [Fintype H]
    [DecidableEq V] [DecidableEq E] [DecidableEq F]
    (face : H → F) (start : H → V) (edge : H → E)
    (htwo : ∀ e, #{h | edge h = e} = 2)
    (α : H → ℝ)
    (hflat : ∀ f, ∑ h with face h = f, α h = ((#{h | face h = f} : ℝ) - 2) * π) :
    ∑ v, (2 * π - ∑ h with start h = v, α h) =
      2 * π * ((Fintype.card V : ℝ) - Fintype.card E + Fintype.card F) := by
  have hH : (Fintype.card H : ℝ) = 2 * Fintype.card E := by
    have := Finset.card_eq_sum_card_fiberwise (f := edge) (s := (univ : Finset H))
      (t := (univ : Finset E)) (fun _ _ => mem_univ _)
    simp only [htwo, sum_const, card_univ, smul_eq_mul] at this
    rw [this]
    push_cast; ring
  have hF : ∑ f, ((#{h | face h = f} : ℝ)) = Fintype.card H := by
    have := Finset.card_eq_sum_card_fiberwise (f := face) (s := (univ : Finset H))
      (t := (univ : Finset F)) (fun _ _ => mem_univ _)
    simp only [card_univ] at this
    rw [this]
    push_cast; rfl
  have hα : ∑ h, α h = π * Fintype.card H - 2 * π * Fintype.card F := by
    rw [← Finset.sum_fiberwise univ face α]
    simp only [hflat, ← sum_mul, sum_sub_distrib, hF, sum_const, card_univ, nsmul_eq_mul]
    ring
  rw [sum_sub_distrib, Finset.sum_fiberwise univ start α, hα, hH]
  simp only [sum_const, card_univ, nsmul_eq_mul]
  ring

-- The football: 60 corners, 90 seams, 32 panels, so V - E + F = 2.
example : (60 : ℤ) - 90 + 32 = 2 := by norm_num
-- Its panels have 5 x 12 + 6 x 20 = 180 sides, each seam counted twice: 180 = 2 x 90.
example : 5 * 12 + 6 * 20 = 180 ∧ 180 = 2 * 90 := by decide
-- Panels summed: 2π x 32 - π x 180 + 2π x 60 = 4π = 2π x 2.
example : 2 * π * 32 - π * 180 + 2 * π * 60 = 2 * π * 2 := by ring
-- Flat-panel ball: a 12-degree gap at each corner (360 - 108 - 2 x 120), 60 corners, 720 degrees = 360 x 2.
example : 360 - 108 - 2 * 120 = 12 ∧ 60 * 12 = 720 ∧ 720 = 360 * 2 := by decide
-- Half dome, in degrees: 36 inside + 144 on the rim + 0 on the cut + 90 + 90 at the corners = 360.
example : 36 + 144 + 0 + 90 + 90 = 360 := by decide
-- Without the rim's bending: 36 + 90 + 90 = 216, not 360.
example : 36 + 90 + 90 = 216 := by decide
-- Inner tube, in degrees: outer half +720, inner half -720, total 0 = 360 x chi with chi = 2 - 2 x 1;
-- adding |K| instead gives 1440 degrees, which is 8π.
example : (720 : ℤ) + (-720) = 0 ∧ (0 : ℤ) = 360 * (2 - 2 * 1) ∧ (720 : ℤ) + 720 = 1440 := by norm_num
-- Two holes: chi = 2 - 2 x 2 = -2, total -720 degrees.
example : (2 : ℤ) - 2 * 2 = -2 ∧ (360 : ℤ) * (-2) = -720 := by norm_num
-- 2π chi = 4π (1 - g) for every genus g.
example (g : ℝ) : 2 * π * (2 - 2 * g) = 4 * π * (1 - g) := by ring

#print axioms total_curvature_eq_two_pi_mul_euler_char
#print axioms sum_angle_defects_eq_two_pi_mul_euler_char
