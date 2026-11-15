-- Subspace, product and quotient: a tape of length L with its two ends glued is homeomorphic to the circle in the plane, by the wrap map, and maps into a product and out of a glued space are tested one simple way.
import Mathlib.Topology.Constructions
import Mathlib.Topology.Homeomorph.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Data.Nat.Bitwise
import Mathlib

open Real

/-- The glued tape is the circle. Take a tape [0, L] of length L > 0 and glue its two ends,
0 and L, and nothing else; give the glued set the quotient topology (a set is open when its
full pre-image on the tape is open). Take the circle of radius R = L / (2π) in the plane, with
the open sets the plane's open sets cut out of it. Then the wrap map, which sends the mark t
to the point (R cos(2πt/L), R sin(2πt/L)), gives a homeomorphism from the glued tape onto the
circle: [0, L]/(0 ∼ L) ≅ S¹. -/
theorem glued_tape_homeomorphic_to_circle (L : ℝ) (hL : 0 < L) :
    ∃ e : Quot (fun s t : Set.Icc (0 : ℝ) L => (s : ℝ) = 0 ∧ (t : ℝ) = L) ≃ₜ
        {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = (L / (2 * π)) ^ 2},
      ∀ t : Set.Icc (0 : ℝ) L,
        (e (Quot.mk _ t) : ℝ × ℝ) =
          (L / (2 * π) * cos (2 * π * t / L), L / (2 * π) * sin (2 * π * t / L)) := by
  classical
  set R : ℝ := L / (2 * π) with hRdef
  have hπ : 0 < π := Real.pi_pos
  have hR : 0 < R := by positivity
  let C := {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 = R ^ 2}
  let wrap : Set.Icc (0 : ℝ) L → C := fun t =>
    ⟨(R * cos (2 * π * t / L), R * sin (2 * π * t / L)), by
      show (R * cos (2 * π * t / L)) ^ 2 + (R * sin (2 * π * t / L)) ^ 2 = R ^ 2
      linear_combination R ^ 2 * sin_sq_add_cos_sq (2 * π * (t : ℝ) / L)⟩
  have hwrap : Continuous wrap := by
    apply Continuous.subtype_mk
    fun_prop
  have hresp : ∀ s t : Set.Icc (0 : ℝ) L, ((s : ℝ) = 0 ∧ (t : ℝ) = L) → wrap s = wrap t := by
    rintro s t ⟨hs, ht⟩
    apply Subtype.ext
    simp only [wrap, hs, ht]
    have : 2 * π * L / L = 2 * π := by field_simp
    rw [this]
    simp
  let f : Quot (fun s t : Set.Icc (0 : ℝ) L => (s : ℝ) = 0 ∧ (t : ℝ) = L) → C :=
    Quot.lift wrap hresp
  have hf : Continuous f := continuous_quot_lift hresp hwrap
  have hinj : Function.Injective f := by
    intro x y hxy
    induction x using Quot.ind with
    | mk s =>
    induction y using Quot.ind with
    | mk t =>
    have h1 := congrArg (fun p : C => (p : ℝ × ℝ).1) hxy
    have h2 := congrArg (fun p : C => (p : ℝ × ℝ).2) hxy
    simp only [f, wrap] at h1 h2
    have hc : cos (2 * π * s / L) = cos (2 * π * t / L) :=
      mul_left_cancel₀ hR.ne' h1
    have hsn : sin (2 * π * s / L) = sin (2 * π * t / L) :=
      mul_left_cancel₀ hR.ne' h2
    have hcos1 : cos (2 * π * s / L - 2 * π * t / L) = 1 := by
      rw [cos_sub, hc, hsn]
      linear_combination sin_sq_add_cos_sq (2 * π * (t : ℝ) / L)
    obtain ⟨hs0, hsL⟩ := s.2
    obtain ⟨ht0, htL⟩ := t.2
    have hdiff : 2 * π * (s : ℝ) / L - 2 * π * t / L = (2 * π / L) * (s - t) := by ring
    have hk : 0 < 2 * π / L := by positivity
    by_cases hA : (s : ℝ) - t = L
    · have hsL' : (s : ℝ) = L := by linarith
      have ht0' : (t : ℝ) = 0 := by linarith
      exact (Quot.sound ⟨ht0', hsL'⟩).symm
    by_cases hB : (s : ℝ) - t = -L
    · have hs0' : (s : ℝ) = 0 := by linarith
      have htL' : (t : ℝ) = L := by linarith
      exact Quot.sound ⟨hs0', htL'⟩
    have hlt1 : (s : ℝ) - t < L := lt_of_le_of_ne (by linarith) hA
    have hlt2 : -L < (s : ℝ) - t := lt_of_le_of_ne (by linarith) (Ne.symm hB)
    have e1 : (2 * π / L) * L = 2 * π := by field_simp
    have hlo : -(2 * π) < 2 * π * (s : ℝ) / L - 2 * π * t / L := by
      rw [hdiff]
      have := mul_lt_mul_of_pos_left hlt2 hk
      linarith
    have hhi : 2 * π * (s : ℝ) / L - 2 * π * t / L < 2 * π := by
      rw [hdiff]
      have := mul_lt_mul_of_pos_left hlt1 hk
      linarith
    have h0 := (cos_eq_one_iff_of_lt_of_lt hlo hhi).mp hcos1
    rw [hdiff] at h0
    have : (s : ℝ) - t = 0 := by
      rcases mul_eq_zero.mp h0 with h | h
      · exact absurd h hk.ne'
      · exact h
    have hst : s = t := Subtype.ext (by linarith)
    rw [hst]
  have hsurj : Function.Surjective f := by
    rintro ⟨⟨x, y⟩, hp⟩
    have hp' : x ^ 2 + y ^ 2 = R ^ 2 := hp
    let z : ℂ := ⟨x, y⟩
    have hz : ‖z‖ = R := by
      rw [Complex.norm_def, Complex.normSq_apply]
      simp only [z]
      rw [show x * x + y * y = R ^ 2 by linarith [hp'], Real.sqrt_sq hR.le]
    have hcx : R * cos (Complex.arg z) = x := by
      rw [← hz]; exact Complex.norm_mul_cos_arg z
    have hsy : R * sin (Complex.arg z) = y := by
      rw [← hz]; exact Complex.norm_mul_sin_arg z
    have ha1 := Complex.neg_pi_lt_arg z
    have ha2 := Complex.arg_le_pi z
    obtain ⟨θ, hθ0, hθ1, hθc, hθs⟩ : ∃ θ : ℝ, 0 ≤ θ ∧ θ ≤ 2 * π ∧
        R * cos θ = x ∧ R * sin θ = y := by
      by_cases hneg : 0 ≤ Complex.arg z
      · exact ⟨Complex.arg z, hneg, by linarith, hcx, hsy⟩
      · refine ⟨Complex.arg z + 2 * π, by linarith, by linarith, ?_, ?_⟩
        · rw [cos_add_two_pi]; exact hcx
        · rw [sin_add_two_pi]; exact hsy
    refine ⟨Quot.mk _ ⟨θ * L / (2 * π), ?_, ?_⟩, ?_⟩
    · positivity
    · rw [div_le_iff₀ (by positivity)]
      nlinarith
    · apply Subtype.ext
      simp only [f, wrap]
      have : 2 * π * (θ * L / (2 * π)) / L = θ := by field_simp
      rw [this, hθc, hθs]
  refine ⟨hf.homeoOfEquivCompactToT2 (f := Equiv.ofBijective f ⟨hinj, hsurj⟩), ?_⟩
  intro t
  rfl

/-- Maps into a product are tested by coordinates. With the product topology (open sets are
unions of boxes U × V), a map g into X × Y is continuous exactly when its first entry and its
second entry are both continuous. -/
theorem continuous_into_product_iff_coordinates {Z X Y : Type*} [TopologicalSpace Z]
    [TopologicalSpace X] [TopologicalSpace Y] (g : Z → X × Y) :
    Continuous g ↔ Continuous (fun z => (g z).1) ∧ Continuous (fun z => (g z).2) := by
  exact ⟨fun h => ⟨continuous_fst.comp h, continuous_snd.comp h⟩,
    fun h => h.1.prodMk h.2⟩

/-- Maps out of a glued space are tested before gluing. Glue a space X by a sameness rule ∼
and give X/∼ the quotient topology, with q sending each point to its block. Then a map h out of
X/∼ is continuous exactly when h ∘ q is continuous on X. -/
theorem continuous_out_of_quotient_iff {X Y : Type*} [TopologicalSpace X] [TopologicalSpace Y]
    (s : Setoid X) (h : Quotient s → Y) :
    Continuous h ↔ Continuous (h ∘ Quotient.mk s) := by
  exact isQuotientMap_quotient_mk'.continuous_iff

/- Finite models, as in the card's code. A set of pieces is a bitmask; a space is the list of
each piece's smallest open set, and a set is open when it holds the smallest open set of each
piece in it. -/
def isOpenSet (u : List ℕ) (s : ℕ) : Bool :=
  (List.range u.length).all fun x => !s.testBit x || (u.getD x 0 &&& s == u.getD x 0)
def openSets (u : List ℕ) : List ℕ := (List.range (2 ^ u.length)).filter (isOpenSet u)
/-- The tape in 5 pieces: mark 0, (0, 1/2), mark 1/2, (1/2, 1), mark 1. -/
def tape : List ℕ := [0b00011, 0b00010, 0b01110, 0b01000, 0b11000]
/-- The four-point circle by small discs: east, top, west, bottom. -/
def circle4 : List ℕ := [0b1011, 0b0010, 0b1110, 0b1000]
/-- Pre-image on the tape of a set of glued points: marks 0 and 1 both go to east. -/
def preimage (v : ℕ) : ℕ :=
  ((List.range 5).filter fun i => v.testBit ([0, 1, 2, 3, 0].getD i 0)).foldl (· ||| 2 ^ ·) 0
/-- The glued tape's open sets, by the quotient rule. -/
def gluedOpens : List ℕ := (List.range 16).filter fun v => isOpenSet tape (preimage v)
/-- The box U × V in the four-point torus; the pair (x, y) is bit 4x + y. -/
def boxMask (a b : ℕ) : ℕ :=
  ((List.range 16).filter fun k => a.testBit (k / 4) && b.testBit (k % 4)).foldl (· ||| 2 ^ ·) 0
def torus16 : List ℕ :=
  (List.range 16).map fun k => boxMask (circle4.getD (k / 4) 0) (circle4.getD (k % 4) 0)

-- The five-piece tape has 13 open sets; 8 of them hold an end mark.
example : (openSets tape).length = 13 := by decide +kernel
example : ((openSets tape).filter fun s => s.testBit 0 || s.testBit 4).length = 8 := by
  decide +kernel
-- Glued by the quotient rule: 7 open sets, the same family as the circle by small discs.
example : gluedOpens.length = 7 ∧ gluedOpens = openSets circle4 := by decide +kernel
-- {east, top} is not open: its pre-image {0, (0,1/2), 1} is not open, though {0, (0,1/2)} is.
example : isOpenSet circle4 0b0011 = false ∧ preimage 0b0011 = 0b10011 ∧
    isOpenSet tape 0b10011 = false ∧ isOpenSet tape 0b00011 = true := by decide +kernel
-- The four-point torus: 37 distinct boxes, and 430 open sets as unions of boxes.
example : ((openSets circle4).flatMap fun a => (openSets circle4).map fun b => boxMask a b).dedup.length
    = 37 := by decide +kernel
example : (openSets torus16).length = 430 := by decide +kernel

#print axioms glued_tape_homeomorphic_to_circle
#print axioms continuous_into_product_iff_coordinates
#print axioms continuous_out_of_quotient_iff
