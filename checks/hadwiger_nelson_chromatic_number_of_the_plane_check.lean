-- Colouring the plane: the plane's unit-distance graph needs at least 4 and at most 7 colours, the Moser spindle needs exactly 4 and sits in the plane with exactly its 11 lines at distance 1, and the card's hand counts hold.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Tactic.NormNum

open SimpleGraph

/-- The unit-distance graph of the plane: its dots are all the points of ℝ², and two points
are joined exactly when the ruler distance between them is 1. Every other distance is allowed. -/
def unitDistancePlane : SimpleGraph (EuclideanSpace ℝ (Fin 2)) where
  Adj p q := dist p q = 1
  symm := ⟨fun p q h => by rw [dist_comm]; exact h⟩
  loopless := ⟨fun p h => by simp at h⟩

lemma hn_dist_sq (p q : EuclideanSpace ℝ (Fin 2)) :
    dist p q ^ 2 = (p 0 - q 0) ^ 2 + (p 1 - q 1) ^ 2 := by
  rw [EuclideanSpace.dist_sq_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]
#print axioms hn_dist_sq

lemma hn_dist_eq_one_iff (p q : EuclideanSpace ℝ (Fin 2)) :
    dist p q = 1 ↔ (p 0 - q 0) ^ 2 + (p 1 - q 1) ^ 2 = 1 := by
  rw [← hn_dist_sq]
  constructor
  · intro h; rw [h]; norm_num
  · intro h; nlinarith [dist_nonneg (x := p) (y := q)]
#print axioms hn_dist_eq_one_iff

noncomputable def hnPt : Fin 7 → EuclideanSpace ℝ (Fin 2) :=
  ![!₂[0, 0],
    !₂[-1/4 + √3 * √11 / 12, √11 / 4 + √3 / 12],
    !₂[-1/4 - √3 * √11 / 12, √11 / 4 - √3 / 12],
    !₂[-1/2, √11 / 2],
    !₂[1/4 - √3 * √11 / 12, √11 / 4 + √3 / 12],
    !₂[1/4 + √3 * √11 / 12, √11 / 4 - √3 / 12],
    !₂[1/2, √11 / 2]]

def hnEdges : List (Fin 7 × Fin 7) :=
  [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3),
   (0, 4), (0, 5), (4, 5), (4, 6), (5, 6),
   (3, 6)]

lemma hnPt_dist (u v : Fin 7) :
    dist (hnPt u) (hnPt v) = 1 ↔ ((u, v) ∈ hnEdges ∨ (v, u) ∈ hnEdges) := by
  have ha : (√3) ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hb : (√11) ^ 2 = 11 := Real.sq_sqrt (by norm_num)
  have ha0 : 0 ≤ √3 := Real.sqrt_nonneg _
  have hb0 : 0 ≤ √11 := Real.sqrt_nonneg _
  have hc : (√3 * √11) ^ 2 = 33 := by rw [mul_pow, ha, hb]; norm_num
  have hc0 : 0 ≤ √3 * √11 := mul_nonneg ha0 hb0
  have hc1 : 5.7 < √3 * √11 := by nlinarith
  have hc2 : √3 * √11 < 5.8 := by nlinarith
  rw [hn_dist_eq_one_iff]
  fin_cases u <;> fin_cases v <;>
    simp only [hnPt, Fin.zero_eta, Fin.mk_one, Fin.reduceFinMk, Fin.isValue, Matrix.cons_val, PiLp.toLp_apply,
      Matrix.cons_val_zero, Matrix.cons_val_one] <;>
    constructor <;> intro h <;>
    first
    | decide
    | exact absurd h (by decide)
    | linarith
#print axioms hnPt_dist

/-- Distinct spindle points have distinct neighbourhoods. -/
lemma hnEdges_nbhd_inj (u v : Fin 7)
    (h : ∀ w, ((u, w) ∈ hnEdges ∨ (w, u) ∈ hnEdges) ↔ ((v, w) ∈ hnEdges ∨ (w, v) ∈ hnEdges)) :
    u = v := by
  have key : ∀ u v : Fin 7, (∀ w : Fin 7,
      decide ((u, w) ∈ hnEdges ∨ (w, u) ∈ hnEdges) = decide ((v, w) ∈ hnEdges ∨ (w, v) ∈ hnEdges)) →
      u = v := by decide
  exact key u v (fun w => decide_eq_decide.2 (h w))
#print axioms hnEdges_nbhd_inj

lemma hnPt_injective : Function.Injective hnPt := by
  intro u v h
  apply hnEdges_nbhd_inj
  intro w
  rw [← hnPt_dist, ← hnPt_dist, h]
#print axioms hnPt_injective

/-- The plane has no proper 3-colouring: the seven spindle points already force a fourth colour. -/
lemma hn_plane_not_three (c : EuclideanSpace ℝ (Fin 2) → Fin 3)
    (hc : ∀ p q, dist p q = 1 → c p ≠ c q) : False := by
  have e : ∀ u v, ((u, v) ∈ hnEdges ∨ (v, u) ∈ hnEdges) → (c (hnPt u)).val ≠ (c (hnPt v)).val :=
    fun u v h => Fin.val_ne_of_ne (hc _ _ ((hnPt_dist u v).2 h))
  have h01 := e 0 1 (by decide)
  have h02 := e 0 2 (by decide)
  have h12 := e 1 2 (by decide)
  have h13 := e 1 3 (by decide)
  have h23 := e 2 3 (by decide)
  have h04 := e 0 4 (by decide)
  have h05 := e 0 5 (by decide)
  have h45 := e 4 5 (by decide)
  have h46 := e 4 6 (by decide)
  have h56 := e 5 6 (by decide)
  have h36 := e 3 6 (by decide)
  have b0 := (c (hnPt 0)).isLt
  have b1 := (c (hnPt 1)).isLt
  have b2 := (c (hnPt 2)).isLt
  have b3 := (c (hnPt 3)).isLt
  have b4 := (c (hnPt 4)).isLt
  have b5 := (c (hnPt 5)).isLt
  have b6 := (c (hnPt 6)).isLt
  omega
#print axioms hn_plane_not_three

lemma hn_Q_cover (u v : ℝ) (hu0 : 0 ≤ u) (hu1 : u < 1) (hv0 : 0 ≤ v) (hv1 : v < 1) :
    ∃ α β : ℤ, (u - α) ^ 2 + (u - α) * (v - β) + (v - β) ^ 2 ≤ 1 / 3 := by
  rcases le_total (u + v) 1 with h | h
  · rcases le_total (2 * u + v) 1 with h2 | h2
    · rcases le_total (u + 2 * v) 1 with h3 | h3
      · exact ⟨0, 0, by push_cast; nlinarith⟩
      · exact ⟨0, 1, by push_cast; nlinarith⟩
    · rcases le_total v u with h4 | h4
      · exact ⟨1, 0, by push_cast; nlinarith⟩
      · exact ⟨0, 1, by push_cast; nlinarith⟩
  · rcases le_total (u + 2 * v) 2 with h2 | h2
    · rcases le_total v u with h4 | h4
      · exact ⟨1, 0, by push_cast; nlinarith⟩
      · rcases le_total (2 * u + v) 2 with h3 | h3
        · exact ⟨0, 1, by push_cast; nlinarith⟩
        · exact ⟨1, 0, by push_cast; nlinarith⟩
    · rcases le_total (2 * u + v) 2 with h3 | h3
      · exact ⟨0, 1, by push_cast; nlinarith⟩
      · exact ⟨1, 1, by push_cast; nlinarith⟩
#print axioms hn_Q_cover

lemma hn_Q_cover_all (x y : ℝ) :
    ∃ a b : ℤ, (x - a) ^ 2 + (x - a) * (y - b) + (y - b) ^ 2 ≤ 1 / 3 := by
  obtain ⟨α, β, h⟩ := hn_Q_cover (x - ⌊x⌋) (y - ⌊y⌋) (by linarith [Int.floor_le x])
    (by linarith [Int.lt_floor_add_one x]) (by linarith [Int.floor_le y])
    (by linarith [Int.lt_floor_add_one y])
  refine ⟨⌊x⌋ + α, ⌊y⌋ + β, ?_⟩
  push_cast
  convert h using 2 <;> ring
#print axioms hn_Q_cover_all

/-- Lattice point `(a, b)` of the hexagonal lattice whose hexagons have side 2/5. -/
noncomputable def hnLat (a b : ℤ) : EuclideanSpace ℝ (Fin 2) :=
  !₂[((a : ℝ) + b / 2) * (2 * √3 / 5), (b : ℝ) * (3 / 5)]

lemma hnLat_apply_zero (a b : ℤ) : hnLat a b 0 = ((a : ℝ) + b / 2) * (2 * √3 / 5) := rfl
#print axioms hnLat_apply_zero

lemma hnLat_apply_one (a b : ℤ) : hnLat a b 1 = (b : ℝ) * (3 / 5) := rfl
#print axioms hnLat_apply_one

lemma hnLat_near (p : EuclideanSpace ℝ (Fin 2)) : ∃ a b : ℤ, dist p (hnLat a b) ≤ 2 / 5 := by
  have ht : (√3) ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have ht0 : 0 < √3 := by positivity
  set y : ℝ := p 1 * (5 / 3) with hy
  set x : ℝ := p 0 / (2 * √3 / 5) - y / 2 with hx
  have hp0 : p 0 = (x + y / 2) * (2 * √3 / 5) := by rw [hx]; field_simp; ring
  have hp1 : p 1 = y * (3 / 5) := by rw [hy]; ring
  obtain ⟨a, b, h⟩ := hn_Q_cover_all x y
  refine ⟨a, b, ?_⟩
  have hd := hn_dist_sq p (hnLat a b)
  rw [hnLat_apply_zero, hnLat_apply_one, hp0, hp1] at hd
  have : dist p (hnLat a b) ^ 2 ≤ (2 / 5) ^ 2 := by
    rw [hd]; nlinarith
  nlinarith [dist_nonneg (x := p) (y := hnLat a b)]
#print axioms hnLat_near

lemma hnLat_dist_sq (a b c d : ℤ) :
    dist (hnLat a b) (hnLat c d) ^ 2 =
      12 / 25 * (((a - c : ℤ) : ℝ) ^ 2 + ((a - c : ℤ) : ℝ) * ((b - d : ℤ) : ℝ) + ((b - d : ℤ) : ℝ) ^ 2) := by
  have ht : (√3) ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  rw [hn_dist_sq]
  rw [hnLat_apply_zero, hnLat_apply_one, hnLat_apply_zero, hnLat_apply_one]
  push_cast
  linear_combination (4 / 25 * ((a:ℝ) - c + (b - d) / 2) ^ 2) * ht
#print axioms hnLat_dist_sq

lemma hn_Q_ge_seven (m n : ℤ) (h7 : 7 ∣ m + 3 * n) (hne : m ≠ 0 ∨ n ≠ 0) :
    7 ≤ m ^ 2 + m * n + n ^ 2 := by
  obtain ⟨k, hk⟩ := h7
  have hm : m = 7 * k - 3 * n := by omega
  have hQ : m ^ 2 + m * n + n ^ 2 = 7 * (7 * k ^ 2 - 5 * k * n + n ^ 2) := by subst hm; ring
  have hpos : 0 < m ^ 2 + m * n + n ^ 2 := by
    rcases hne with h | h
    · have : 0 < m ^ 2 := by positivity
      nlinarith [sq_nonneg (m + 2 * n), sq_nonneg n]
    · have : 0 < n ^ 2 := by positivity
      nlinarith [sq_nonneg (2 * m + n)]
  rw [hQ] at hpos ⊢
  omega
#print axioms hn_Q_ge_seven

/-- The lattice point chosen near `p`: its two coordinates. -/
noncomputable def hnA (p : EuclideanSpace ℝ (Fin 2)) : ℤ := Classical.choose (hnLat_near p)

noncomputable def hnB (p : EuclideanSpace ℝ (Fin 2)) : ℤ :=
  Classical.choose (Classical.choose_spec (hnLat_near p))

lemma hnAB_near (p : EuclideanSpace ℝ (Fin 2)) : dist p (hnLat (hnA p) (hnB p)) ≤ 2 / 5 :=
  Classical.choose_spec (Classical.choose_spec (hnLat_near p))
#print axioms hnAB_near

/-- The colour of a point: the hexagon-lattice point chosen near it, coloured `(a + 3b) mod 7`. -/
noncomputable def hnColour (p : EuclideanSpace ℝ (Fin 2)) : Fin 7 :=
  ⟨((hnA p + 3 * hnB p) % 7).toNat, by omega⟩

lemma hnColour_valid (p q : EuclideanSpace ℝ (Fin 2)) (hpq : dist p q = 1) :
    hnColour p ≠ hnColour q := by
  intro hc
  have h7 : 7 ∣ (hnA p - hnA q) + 3 * (hnB p - hnB q) := by
    have := congrArg Fin.val hc
    simp only [hnColour] at this
    omega
  have hp := hnAB_near p
  have hq := hnAB_near q
  by_cases he : hnA p - hnA q = 0 ∧ hnB p - hnB q = 0
  · have ha : hnA p = hnA q := by omega
    have hb : hnB p = hnB q := by omega
    rw [ha, hb] at hp
    have := dist_triangle_right p q (hnLat (hnA q) (hnB q))
    linarith
  · have hQ := hn_Q_ge_seven _ _ h7 (by tauto)
    have hQr : (7 : ℝ) ≤ (((hnA p - hnA q : ℤ) : ℝ) ^ 2 + ((hnA p - hnA q : ℤ) : ℝ) *
        ((hnB p - hnB q : ℤ) : ℝ) + ((hnB p - hnB q : ℤ) : ℝ) ^ 2) := by exact_mod_cast hQ
    have hL := hnLat_dist_sq (hnA p) (hnB p) (hnA q) (hnB q)
    have htri : dist (hnLat (hnA p) (hnB p)) (hnLat (hnA q) (hnB q)) ≤ 9 / 5 := by
      have h1 := dist_triangle (hnLat (hnA p) (hnB p)) p (hnLat (hnA q) (hnB q))
      have h2 := dist_triangle p q (hnLat (hnA q) (hnB q))
      rw [dist_comm] at hp
      linarith
    nlinarith [dist_nonneg (x := hnLat (hnA p) (hnB p)) (y := hnLat (hnA q) (hnB q))]
#print axioms hnColour_valid

lemma hn_plane_colorable_seven :
    ∃ c : EuclideanSpace ℝ (Fin 2) → Fin 7, ∀ p q, dist p q = 1 → c p ≠ c q :=
  ⟨hnColour, hnColour_valid⟩
#print axioms hn_plane_colorable_seven


/-- The two bounds proved on the card. Colour every point of the flat plane, with one
forbidden distance, 1, and no rule on the shape of the colour regions: three colours never
suffice (the Moser spindle) and seven always do (Isbell's hexagons), so 4 ≤ χ(ℝ²) ≤ 7. -/
theorem four_le_chromaticNumber_plane_le_seven :
    4 ≤ unitDistancePlane.chromaticNumber ∧ unitDistancePlane.chromaticNumber ≤ 7 := by
  constructor
  · rw [show (4 : ℕ∞) = ((4 : ℕ) : ℕ∞) from rfl, le_chromaticNumber_iff_colorable]
    intro m hm
    by_contra hlt
    have hm3 : m ≤ 3 := by
      by_contra h3
      exact hlt (by exact_mod_cast (show 4 ≤ m by omega))
    obtain ⟨C⟩ := hm.mono hm3
    exact hn_plane_not_three C (fun p q h => C.valid h)
  · have hcol : unitDistancePlane.Colorable 7 :=
      ⟨Coloring.mk hnColour (fun h => hnColour_valid _ _ h)⟩
    exact_mod_cast hcol.chromaticNumber_le

/-! The Moser spindle, points A to G as `0` to `6`: diamond ABCD (triangles ABC and BCD),
diamond AEFG (triangles AEF and EFG), and the line DG. -/

/-- The spindle's 11 lines. -/
def spindleEdges : List (Fin 7 × Fin 7) :=
  [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3),   -- AB AC BC BD CD
   (0, 4), (0, 5), (4, 5), (4, 6), (5, 6),   -- AE AF EF EG FG
   (3, 6)]                                    -- DG

/-- The Moser spindle as a graph: 7 dots, 11 lines. -/
def moserSpindle : SimpleGraph (Fin 7) where
  Adj u v := (u, v) ∈ spindleEdges ∨ (v, u) ∈ spindleEdges
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel moserSpindle.Adj := fun u v =>
  inferInstanceAs (Decidable ((u, v) ∈ spindleEdges ∨ (v, u) ∈ spindleEdges))

/-- The spindle needs four colours: no 3-colouring exists (each diamond forces its tip to take
A's colour, and the tips D and G are joined), and four colours do paint it. -/
theorem moserSpindle_chromaticNumber_eq_four : moserSpindle.chromaticNumber = 4 := by
  rw [show (4 : ℕ∞) = ((3 : ℕ) : ℕ∞) + 1 by norm_num, chromaticNumber_eq_iff_colorable_not_colorable]
  constructor
  · have key : ∀ v w, moserSpindle.Adj v w → (![0, 1, 2, 0, 1, 2, 3] : Fin 7 → Fin 4) v ≠
        (![0, 1, 2, 0, 1, 2, 3] : Fin 7 → Fin 4) w := by decide
    exact ⟨Coloring.mk _ (fun h => key _ _ h)⟩
  · rintro ⟨C⟩
    have e : ∀ u v, moserSpindle.Adj u v → (C u).val ≠ (C v).val :=
      fun u v h => Fin.val_ne_of_ne (C.valid h)
    have h01 := e 0 1 (by decide)
    have h02 := e 0 2 (by decide)
    have h12 := e 1 2 (by decide)
    have h13 := e 1 3 (by decide)
    have h23 := e 2 3 (by decide)
    have h04 := e 0 4 (by decide)
    have h05 := e 0 5 (by decide)
    have h45 := e 4 5 (by decide)
    have h46 := e 4 6 (by decide)
    have h56 := e 5 6 (by decide)
    have h36 := e 3 6 (by decide)
    have b0 := (C 0).isLt
    have b1 := (C 1).isLt
    have b2 := (C 2).isLt
    have b3 := (C 3).isLt
    have b4 := (C 4).isLt
    have b5 := (C 5).isLt
    have b6 := (C 6).isLt
    omega

/-- The spindle can be drawn in the plane: seven different points whose pairs at distance
exactly 1 are exactly the spindle's 11 lines, and no other pair. -/
theorem moserSpindle_unit_distance_drawing :
    ∃ f : Fin 7 → EuclideanSpace ℝ (Fin 2), Function.Injective f ∧
      ∀ u v, moserSpindle.Adj u v ↔ dist (f u) (f v) = 1 := by
  exact ⟨hnPt, hnPt_injective, fun u v => (hnPt_dist u v).symm⟩

-- 7 points, 11 lines, and 3^7 = 2,187 colourings to try with three colours.
example : moserSpindle.edgeFinset.card = 11 ∧ 3 ^ 7 = 2187 := by
  decide +kernel
-- Four colours paint the spindle in 384 ways.
example : (Finset.univ.filter (fun c : Fin 7 → Fin 4 =>
    ∀ u v, moserSpindle.Adj u v → c u ≠ c v)).card = 384 := by
  decide +kernel
-- Drop the line DG: 12 ways with three colours, matching k(k-1)^2(k-2)^4 at k = 3; 576 at k = 4.
example : (Finset.univ.filter (fun c : Fin 7 → Fin 3 =>
    ∀ u v, moserSpindle.Adj u v → (u, v) ≠ (3, 6) → (u, v) ≠ (6, 3) → c u ≠ c v)).card = 12 ∧
    3 * (3 - 1) ^ 2 * (3 - 2) ^ 4 = 12 ∧ 4 * (4 - 1) ^ 2 * (4 - 2) ^ 4 = 576 := by
  decide +kernel
-- The floor from the largest all-joined set is only 3: no four spindle points are all joined.
example : moserSpindle.CliqueFree 4 := by
  rw [cliqueFree_iff_isEmpty_copy_top_fin]
  refine ⟨fun f => ?_⟩
  have key : ∀ a b c d : Fin 7, moserSpindle.Adj a b → moserSpindle.Adj a c →
      moserSpindle.Adj a d → moserSpindle.Adj b c → moserSpindle.Adj b d →
      moserSpindle.Adj c d → False := by decide
  exact key (f 0) (f 1) (f 2) (f 3) (f.toHom.map_adj (by decide)) (f.toHom.map_adj (by decide))
    (f.toHom.map_adj (by decide)) (f.toHom.map_adj (by decide)) (f.toHom.map_adj (by decide))
    (f.toHom.map_adj (by decide))
-- Hexagon colour (a + 3b) mod 7: the six neighbours differ from the centre by 1, 6, 3, 4, 5, 2.
example : [((1 : ℤ), (0 : ℤ)), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1)].map
    (fun ab => (ab.1 + 3 * ab.2) % 7) = [1, 6, 3, 4, 5, 2] := by
  decide
-- The nearest other hexagon of colour 0 is (1, 2); its centre is sqrt(3 × 7) s = sqrt 21 s away.
example : ((1 : ℤ) + 3 * 2) % 7 = 0 ∧ 3 * (1 ^ 2 + 1 * 2 + 2 ^ 2) = 21 := by
  decide
-- Side s = 2/5: widest span 2s below 1, nearest same colour sqrt 7 × s above 1.
example : (2 : ℝ) * (2 / 5) < 1 ∧ 1 < Real.sqrt 7 * (2 / 5) := by
  have h := Real.sq_sqrt (show (0 : ℝ) ≤ 7 by norm_num)
  have h0 := Real.sqrt_nonneg 7
  constructor <;> nlinarith
-- What breaks: side 11/20 spans more than 1; side 7/20 puts same colours under 1 apart.
example : 1 < (2 : ℝ) * (11 / 20) ∧ Real.sqrt 7 * (7 / 20) < 1 := by
  have h := Real.sq_sqrt (show (0 : ℝ) ≤ 7 by norm_num)
  have h0 := Real.sqrt_nonneg 7
  constructor <;> nlinarith

#print axioms four_le_chromaticNumber_plane_le_seven
#print axioms moserSpindle_chromaticNumber_eq_four
#print axioms moserSpindle_unit_distance_drawing
