-- Cellular homology: the signed letter count of closed rims gives boundary matrices with d₁ d₂ = 0, cells and Betti numbers over a field give the same Euler characteristic, and the Klein bottle's recipe abAb gives H₁ = ℤ ⊕ ℤ/2 and H₂ = 0.
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.Data.ZMod.Defs
import Mathlib.Data.List.Count
import Mathlib.Tactic.NormNum
import Mathlib.Data.List.Rotate
import Mathlib.LinearAlgebra.Isomorphisms
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Data.ZMod.Basic

namespace CellularHomology

variable {V E ι : Type*}

/-- One step of a rim: an edge and its direction, `true` for a small letter (run forwards)
and `false` for a capital letter (run backwards). -/
abbrev Step (E : Type*) := E × Bool

/-- The point where a step starts: the edge's start if run forwards, its end if run backwards. -/
def stepStart (src tgt : E → V) (s : Step E) : V := if s.2 then src s.1 else tgt s.1

/-- The point where a step ends: the edge's end if run forwards, its start if run backwards. -/
def stepEnd (src tgt : E → V) (s : Step E) : V := if s.2 then tgt s.1 else src s.1

/-- A rim lands in the cells below it: its edge word is a closed walk, each step starting
where the one before it ended, and the last step ending where the first one started. -/
def IsClosedRim (src tgt : E → V) (w : List (Step E)) : Prop :=
  ∀ i (hi : i < w.length),
    stepEnd src tgt w[i] =
      stepStart src tgt (w[(i + 1) % w.length]'(Nat.mod_lt _ (Nat.zero_lt_of_lt hi)))

/-- The incidence number `[e : f]` read off the rim word `w` of a 2-cell `e`: the number of
times the letter `f` appears minus the number of times its capital appears. -/
def incidence [DecidableEq E] (w : List (Step E)) (f : E) : ℤ :=
  (w.count (f, true) : ℤ) - (w.count (f, false) : ℤ)

/-- The cellular boundary `d₁`: an edge's boundary is its end point minus its start point.
Rows are the points, columns the edges. -/
def d1 [DecidableEq V] (src tgt : E → V) : Matrix V E ℤ :=
  fun v e => (if tgt e = v then 1 else 0) - (if src e = v then 1 else 0)

/-- The cellular boundary `d₂`: the entry in row `f`, column `c` is the incidence number of
the 2-cell `c` along the edge `f`, by the signed letter count. -/
def d2 [DecidableEq E] (rim : ι → List (Step E)) : Matrix E ι ℤ :=
  fun f c => incidence (rim c) f

theorem sum_mul_incidence [DecidableEq E] [Fintype E] (f : E → ℤ) (w : List (Step E)) :
    ∑ e, f e * incidence w e = (w.map fun s => if s.2 then f s.1 else -f s.1).sum := by
  induction w with
  | nil => simp [incidence]
  | cons s w ih =>
    obtain ⟨a, b⟩ := s
    have h : ∀ e, incidence ((a, b) :: w) e = incidence w e +
        (if b then (if a = e then 1 else 0) else -(if a = e then 1 else 0)) := by
      intro e
      cases b <;> by_cases hae : a = e <;> simp [incidence, hae] <;> ring
    simp only [h, mul_add, Finset.sum_add_distrib, ih, List.map_cons, List.sum_cons]
    cases b <;> simp [Finset.sum_ite_eq] <;> ring

theorem closedRim_map [DecidableEq V] (src tgt : E → V) (w : List (Step E))
    (hw : IsClosedRim src tgt w) :
    w.map (stepEnd src tgt) = (w.rotate 1).map (stepStart src tgt) := by
  apply List.ext_getElem (by simp)
  intro i h1 h2
  simp only [List.getElem_map, List.getElem_rotate]
  exact hw i (by simpa using h1)

/-- The boundary of a boundary is zero: for discs glued along edge words, with each rim a
closed walk on the edges below it and each capital letter counted −1, the cellular boundary
matrices satisfy `d₁ d₂ = 0`. -/
theorem cellular_d1_mul_d2_eq_zero [DecidableEq V] [DecidableEq E] [Fintype E]
    (src tgt : E → V) (rim : ι → List (Step E)) (hrim : ∀ c, IsClosedRim src tgt (rim c)) :
    d1 src tgt * d2 rim = 0 := by
  ext v c
  rw [Matrix.mul_apply]
  simp only [d1, d2]
  rw [sum_mul_incidence]
  set g : V → ℤ := fun u => if u = v then 1 else 0 with hg
  have hpt : ∀ s : Step E,
      (if s.2 then ((if tgt s.1 = v then (1 : ℤ) else 0) - (if src s.1 = v then 1 else 0))
        else -((if tgt s.1 = v then (1 : ℤ) else 0) - (if src s.1 = v then 1 else 0))) =
      g (stepEnd src tgt s) - g (stepStart src tgt s) := by
    rintro ⟨e, b⟩
    cases b <;> simp [stepEnd, stepStart, hg]
  simp only [hpt]
  have hsub : ∀ l : List (Step E),
      (l.map fun s => g (stepEnd src tgt s) - g (stepStart src tgt s)).sum =
        (l.map fun s => g (stepEnd src tgt s)).sum - (l.map fun s => g (stepStart src tgt s)).sum := by
    intro l
    induction l with
    | nil => simp
    | cons a l ih => simp only [List.map_cons, List.sum_cons, ih]; ring
  rw [hsub, Matrix.zero_apply, sub_eq_zero]
  have h1 : ((rim c).map fun s => g (stepEnd src tgt s)) =
      ((rim c).map (stepEnd src tgt)).map g := by simp [List.map_map, Function.comp_def]
  have h2 : ((rim c).map fun s => g (stepStart src tgt s)) =
      ((rim c).map (stepStart src tgt)).map g := by simp [List.map_map, Function.comp_def]
  rw [h1, h2, closedRim_map src tgt _ (hrim c)]
  have hp : List.Perm (((rim c).rotate 1).map (stepStart src tgt)) ((rim c).map (stepStart src tgt)) :=
    ((rim c).rotate_perm 1).map _
  exact (hp.map g).sum_eq

/-- The Euler characteristic two ways: over any field `K`, for chains
`C₂ → C₁ → C₀` of finite dimensions `c₂, c₁, c₀` with `d₁ d₂ = 0`, the alternating cell
count `c₀ − c₁ + c₂` equals the alternating Betti sum `β₀ − β₁ + β₂`, where
`β₀ = dim (C₀ / im d₁)`, `β₁ = dim (ker d₁ / im d₂)` and `β₂ = dim (ker d₂)`. -/
theorem euler_characteristic_cells_eq_betti {K C₀ C₁ C₂ : Type*} [Field K]
    [AddCommGroup C₀] [Module K C₀] [FiniteDimensional K C₀]
    [AddCommGroup C₁] [Module K C₁] [FiniteDimensional K C₁]
    [AddCommGroup C₂] [Module K C₂] [FiniteDimensional K C₂]
    (d₁ : C₁ →ₗ[K] C₀) (d₂ : C₂ →ₗ[K] C₁) (h : d₁ ∘ₗ d₂ = 0) :
    (Module.finrank K C₀ : ℤ) - Module.finrank K C₁ + Module.finrank K C₂ =
      (Module.finrank K (C₀ ⧸ LinearMap.range d₁) : ℤ)
        - Module.finrank K (LinearMap.ker d₁ ⧸
            (LinearMap.range d₂).comap (LinearMap.ker d₁).subtype)
        + Module.finrank K (LinearMap.ker d₂) := by
  have hle : LinearMap.range d₂ ≤ LinearMap.ker d₁ := by
    rintro _ ⟨x, rfl⟩
    simpa using LinearMap.congr_fun h x
  have a1 := Submodule.finrank_quotient_add_finrank (LinearMap.range d₁)
  have a2 := Submodule.finrank_quotient_add_finrank
    ((LinearMap.range d₂).comap (LinearMap.ker d₁).subtype)
  have a3 := (Submodule.comapSubtypeEquivOfLe hle).finrank_eq
  have a4 := LinearMap.finrank_range_add_finrank_ker d₁
  have a5 := LinearMap.finrank_range_add_finrank_ker d₂
  omega

/-- The torus rim `abAB`, with `a = 0` and `b = 1`. -/
def torusRim : List (Step (Fin 2)) := [(0, true), (1, true), (0, false), (1, false)]

/-- The Klein bottle rim `abAb`, with `a = 0` and `b = 1`. -/
def kleinRim : List (Step (Fin 2)) := [(0, true), (1, true), (0, false), (1, true)]

/-- The projective plane rim `aa`, with `a = 0`. -/
def rp2Rim : List (Step (Fin 1)) := [(0, true), (0, true)]

/-- The Klein bottle from one point, two edges `a`, `b` and one square with rim `abAb`:
its cellular `H₁`, the cycles (kernel of `d₁`) modulo the boundaries (image of `d₂`), is
`ℤ ⊕ ℤ/2`, and its `H₂`, the kernel of `d₂`, is zero. -/
theorem klein_bottle_cellular_homology :
    Nonempty ((LinearMap.ker (d1 (fun _ : Fin 2 => ()) (fun _ => ())).mulVecLin ⧸
        (LinearMap.range (d2 (fun _ : Unit => kleinRim)).mulVecLin).comap
          (LinearMap.ker (d1 (fun _ : Fin 2 => ()) (fun _ => ())).mulVecLin).subtype) ≃+
      (ℤ × ZMod 2)) ∧
    LinearMap.ker (d2 (fun _ : Unit => kleinRim)).mulVecLin = ⊥ := by
  have hd2 : ∀ y : Unit → ℤ, (d2 (fun _ : Unit => kleinRim)).mulVec y = ![0, 2 * y ()] := by
    intro y
    have i0 : incidence kleinRim 0 = 0 := by decide
    have i1 : incidence kleinRim 1 = 2 := by decide
    ext f
    fin_cases f <;> simp [Matrix.mulVec, dotProduct, d2, i0, i1]
  set N := LinearMap.ker (d1 (fun _ : Fin 2 => ()) (fun _ => ())).mulVecLin
  let φ : N →ₗ[ℤ] ℤ × ZMod 2 :=
    LinearMap.prod ((LinearMap.proj (0 : Fin 2)).comp N.subtype)
      ((Int.castAddHom (ZMod 2)).toIntLinearMap.comp ((LinearMap.proj (1 : Fin 2)).comp N.subtype))
  have hd1 : ∀ x : Fin 2 → ℤ, x ∈ N := by
    intro x
    have : d1 (fun _ : Fin 2 => ()) (fun _ => ()) = 0 := by decide
    simp [N, this]
  have hsurj : Function.Surjective φ := by
    rintro ⟨a, b⟩
    refine ⟨⟨![a, (b.val : ℤ)], hd1 _⟩, ?_⟩
    simp [φ]
  have hker : LinearMap.ker φ = (LinearMap.range (d2 (fun _ : Unit => kleinRim)).mulVecLin).comap
      N.subtype := by
    ext ⟨x, hx⟩
    simp only [LinearMap.mem_ker, Submodule.mem_comap, LinearMap.mem_range,
      Matrix.mulVecLin_apply, hd2, Submodule.subtype_apply]
    constructor
    · intro h0
      simp [φ, Prod.ext_iff, ZMod.intCast_zmod_eq_zero_iff_dvd] at h0
      obtain ⟨h0, k, hk⟩ := h0
      refine ⟨fun _ => k, ?_⟩
      ext f; fin_cases f <;> simp [h0, hk]
    · rintro ⟨y, hy⟩
      have e0 := congr_fun hy 0
      have e1 := congr_fun hy 1
      simp at e0 e1
      simp [φ, Prod.ext_iff, ← e0, ← e1, show (2 : ZMod 2) = 0 from rfl]
  refine ⟨⟨((Submodule.quotEquivOfEq _ _ hker).symm.trans
    (φ.quotKerEquivOfSurjective hsurj)).toAddEquiv⟩, ?_⟩
  rw [eq_bot_iff]
  intro y hy
  rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, hd2] at hy
  have := congr_fun hy 1
  simp at this
  rw [Submodule.mem_bot]
  ext u; cases u; simpa using this

/-! Worked numbers from the card. All three recipes have one point, so every edge starts and
ends at it. -/

-- All three rims are closed walks on the one point.
example : IsClosedRim (fun _ : Fin 2 => ()) (fun _ => ()) torusRim := by
  unfold IsClosedRim; decide
example : IsClosedRim (fun _ : Fin 2 => ()) (fun _ => ()) kleinRim := by
  unfold IsClosedRim; decide
example : IsClosedRim (fun _ : Fin 1 => ()) (fun _ => ()) rp2Rim := by
  unfold IsClosedRim; decide
-- d₁ = 0: each edge's boundary is v − v.
example : d1 (fun _ : Fin 2 => ()) (fun _ => ()) = 0 := by decide
-- Torus, rim abAB: [T:a] = 1 − 1 = 0 and [T:b] = 0.
example : incidence torusRim 0 = 0 ∧ incidence torusRim 1 = 0 := by decide
-- Klein bottle, rim abAb: [K:a] = 1 − 1 = 0 and [K:b] = 2 − 0 = 2.
example : incidence kleinRim 0 = 0 ∧ incidence kleinRim 1 = 2 := by decide
-- Projective plane, rim aa: [P:a] = 2 − 0 = 2.
example : incidence rp2Rim 0 = 2 := by decide
-- Euler characteristic from cells: torus and Klein bottle 1 − 2 + 1 = 0, projective plane
-- 1 − 1 + 1 = 1, torus with the square left out 1 − 2 = −1, 3-torus 1 − 3 + 3 − 1 = 0.
example : (1 : ℤ) - 2 + 1 = 0 ∧ (1 : ℤ) - 1 + 1 = 1 ∧ (1 : ℤ) - 2 = -1 ∧
    (1 : ℤ) - 3 + 3 - 1 = 0 := by norm_num
-- The same from Betti numbers: over ℚ 1 − 2 + 1, 1 − 1 + 0, 1 − 0 + 0; over ℤ/2 1 − 2 + 1,
-- 1 − 2 + 1, 1 − 1 + 1.
example : (1 : ℤ) - 2 + 1 = 0 ∧ (1 : ℤ) - 1 + 0 = 0 ∧ (1 : ℤ) - 0 + 0 = 1 ∧
    (1 : ℤ) - 1 + 1 = 1 := by norm_num
-- Matrix entries: cellular 1·2 + 2·1 = 4; torus triangles 9·27 + 27·18 = 729; projective
-- plane triangles 6·15 + 15·10 = 240.
example : 1 * 2 + 2 * 1 = 4 ∧ 9 * 27 + 27 * 18 = 729 ∧ 6 * 15 + 15 * 10 = 240 := by norm_num

#print axioms sum_mul_incidence
#print axioms closedRim_map
#print axioms cellular_d1_mul_d2_eq_zero
#print axioms euler_characteristic_cells_eq_betti
#print axioms klein_bottle_cellular_homology

end CellularHomology
