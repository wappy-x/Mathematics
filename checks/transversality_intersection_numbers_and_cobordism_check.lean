-- Transversality and cobordism: on the glued map sheet (flat torus), the straight loops (a, b) and (c, d) cross at |ad - bc| points, each with sign that of ad - bc, so their oriented intersection number is ad - bc; and a finite union of arcs and circles has an even number of ends.
import Mathlib.Data.Set.Card
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Data.Real.Basic
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.LinearAlgebra.FreeModule.Finite.CardQuotient
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.Order.Archimedean.Real.Basic

theorem torus_crossing_natCard_aux (a b c d : ℤ) (y0 : ℝ) (h : a * d - b * c ≠ 0) :
    Nat.card {p : ℝ × ℝ | p.1 ∈ Set.Ico (0 : ℝ) 1 ∧ p.2 ∈ Set.Ico (0 : ℝ) 1 ∧
        ∃ m n : ℤ, p.1 * a - p.2 * c = m ∧ y0 + p.1 * b - p.2 * d = n} =
      (a * d - b * c).natAbs := by
  have hDr : ((a : ℝ) * d - b * c) ≠ 0 := by exact_mod_cast h
  let A : Matrix (Fin 2) (Fin 2) ℤ := !![a, -c; b, -d]
  let N : Submodule ℤ (Fin 2 → ℤ) := LinearMap.range (Matrix.toLin' A)
  have hinj : Function.Injective (Matrix.toLin' A) := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro x hx
    have h0 := congrFun hx 0
    have h1 := congrFun hx 1
    simp [A, Matrix.mulVec, dotProduct, Fin.sum_univ_two] at h0 h1
    have e0 : (a * d - b * c) * x 0 = 0 := by linear_combination d * h0 - c * h1
    have e1 : (a * d - b * c) * x 1 = 0 := by linear_combination b * h0 - a * h1
    ext i; fin_cases i
    · simpa [h] using e0
    · simpa [h] using e1
  have hcard : Nat.card ((Fin 2 → ℤ) ⧸ N) = (a * d - b * c).natAbs := by
    rw [← Submodule.natAbs_det_equiv N (LinearEquiv.ofInjective _ hinj)]
    have : N.subtype ∘ₗ AddMonoidHom.toIntLinearMap
        ((LinearEquiv.ofInjective _ hinj : (Fin 2 → ℤ) ≃ₗ[ℤ] N) : (Fin 2 → ℤ) →+ N) =
        Matrix.toLin' A := by
      ext x : 1
      rfl
    rw [this, LinearMap.det_toLin', Matrix.det_fin_two_of, ← Int.natAbs_neg]
    congr 1
    ring
  -- membership in N, in coordinates
  have L1 : ∀ x : Fin 2 → ℤ, x ∈ N → ∃ k0 k1 : ℤ,
      ((x 0 : ℝ) * d - c * x 1) / (a * d - b * c) = k0 ∧
      ((b : ℝ) * x 0 - a * x 1) / (a * d - b * c) = k1 := by
    rintro x ⟨k, rfl⟩
    refine ⟨k 0, k 1, ?_, ?_⟩
    · rw [div_eq_iff hDr]
      simp [A, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
      ring
    · rw [div_eq_iff hDr]
      simp [A, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
      ring
  have L2 : ∀ (x : Fin 2 → ℤ) (k0 k1 : ℤ),
      ((x 0 : ℝ) * d - c * x 1) / (a * d - b * c) = k0 →
      ((b : ℝ) * x 0 - a * x 1) / (a * d - b * c) = k1 → x ∈ N := by
    intro x k0 k1 h0 h1
    rw [div_eq_iff hDr] at h0 h1
    refine ⟨![k0, k1], ?_⟩
    ext i; fin_cases i
    · simp [A, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
      have : ((a * k0 + -(c * k1) : ℤ) : ℝ) = x 0 := by
        apply mul_left_cancel₀ hDr
        push_cast
        linear_combination (-a) * h0 + c * h1
      exact_mod_cast this
    · simp [A, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
      have : ((b * k0 + -(d * k1) : ℤ) : ℝ) = x 1 := by
        apply mul_left_cancel₀ hDr
        push_cast
        linear_combination (-b) * h0 + d * h1
      exact_mod_cast this
  set S := {p : ℝ × ℝ | p.1 ∈ Set.Ico (0 : ℝ) 1 ∧ p.2 ∈ Set.Ico (0 : ℝ) 1 ∧
        ∃ m n : ℤ, p.1 * a - p.2 * c = m ∧ y0 + p.1 * b - p.2 * d = n} with hSdef
  obtain ⟨T, hT⟩ : ∃ T : (Fin 2 → ℤ) → ℝ,
      ∀ v, T v = ((v 0 : ℝ) * d - c * ((v 1 : ℝ) - y0)) / (a * d - b * c) := ⟨_, fun _ => rfl⟩
  obtain ⟨U, hU⟩ : ∃ U : (Fin 2 → ℤ) → ℝ,
      ∀ v, U v = ((b : ℝ) * v 0 - a * ((v 1 : ℝ) - y0)) / (a * d - b * c) := ⟨_, fun _ => rfl⟩
  have hTd : ∀ v w : Fin 2 → ℤ, T v - T w =
      (((v - w) 0 : ℤ) * (d : ℝ) - c * ((v - w) 1 : ℤ)) / (a * d - b * c) := by
    intro v w; rw [hT, hT]; simp only [Pi.sub_apply, Int.cast_sub]; field_simp; ring
  have hUd : ∀ v w : Fin 2 → ℤ, U v - U w =
      ((b : ℝ) * ((v - w) 0 : ℤ) - a * ((v - w) 1 : ℤ)) / (a * d - b * c) := by
    intro v w; rw [hU, hU]; simp only [Pi.sub_apply, Int.cast_sub]; field_simp; ring
  have hpre : ∀ p ∈ S, ∃ v : Fin 2 → ℤ, T v = p.1 ∧ U v = p.2 := by
    rintro p ⟨-, -, m, n, hm, hn⟩
    refine ⟨![m, n], ?_, ?_⟩
    · rw [hT, div_eq_iff hDr]
      simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
      rw [← hm, ← hn]; ring
    · rw [hU, div_eq_iff hDr]
      simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
      rw [← hm, ← hn]; ring
  have hmem : ∀ v : Fin 2 → ℤ, (Int.fract (T v), Int.fract (U v)) ∈ S := by
    intro v
    have hTD : T v * (a * d - b * c) = (v 0 : ℝ) * d - c * ((v 1 : ℝ) - y0) := by
      rw [hT, div_mul_cancel₀ _ hDr]
    have hUD : U v * (a * d - b * c) = (b : ℝ) * v 0 - a * ((v 1 : ℝ) - y0) := by
      rw [hU, div_mul_cancel₀ _ hDr]
    have eA : T v * a - U v * c = v 0 := by
      apply mul_right_cancel₀ hDr
      linear_combination (a : ℝ) * hTD - (c : ℝ) * hUD
    have eB : y0 + T v * b - U v * d = v 1 := by
      apply mul_right_cancel₀ hDr
      linear_combination (b : ℝ) * hTD - (d : ℝ) * hUD
    refine ⟨⟨Int.fract_nonneg _, Int.fract_lt_one _⟩, ⟨Int.fract_nonneg _, Int.fract_lt_one _⟩,
      v 0 - ⌊T v⌋ * a + ⌊U v⌋ * c, v 1 - ⌊T v⌋ * b + ⌊U v⌋ * d, ?_, ?_⟩
    · rw [Int.fract, Int.fract]; push_cast; linear_combination eA
    · rw [Int.fract, Int.fract]; push_cast; linear_combination eB
  let g : S → (Fin 2 → ℤ) ⧸ N := fun p => Submodule.Quotient.mk (hpre p.1 p.2).choose
  rw [← hcard]
  refine Nat.card_eq_of_bijective g ⟨?_, ?_⟩
  · rintro ⟨p, hp⟩ ⟨q, hq⟩ hpq
    have hx := (Submodule.Quotient.eq N).1 hpq
    obtain ⟨k0, k1, h0, h1⟩ := L1 _ hx
    obtain ⟨hp1, hp2⟩ := (hpre p hp).choose_spec
    obtain ⟨hq1, hq2⟩ := (hpre q hq).choose_spec
    rw [← hTd, hp1, hq1] at h0
    rw [← hUd, hp2, hq2] at h1
    have e1 : Int.fract p.1 = Int.fract q.1 := Int.fract_eq_fract.2 ⟨k0, h0⟩
    have e2 : Int.fract p.2 = Int.fract q.2 := Int.fract_eq_fract.2 ⟨k1, h1⟩
    rw [Int.fract_eq_self.2 hp.1, Int.fract_eq_self.2 hq.1] at e1
    rw [Int.fract_eq_self.2 hp.2.1, Int.fract_eq_self.2 hq.2.1] at e2
    exact Subtype.ext (Prod.ext e1 e2)
  · intro y
    obtain ⟨w, rfl⟩ := Submodule.Quotient.mk_surjective N y
    refine ⟨⟨_, hmem w⟩, ?_⟩
    show Submodule.Quotient.mk _ = Submodule.Quotient.mk w
    rw [Submodule.Quotient.eq]
    obtain ⟨h1, h2⟩ := (hpre _ (hmem w)).choose_spec
    refine L2 _ (-⌊T w⌋) (-⌊U w⌋) ?_ ?_
    · rw [← hTd, h1]; dsimp only; rw [Int.fract]; push_cast; ring
    · rw [← hUd, h2]; dsimp only; rw [Int.fract]; push_cast; ring
#print axioms torus_crossing_natCard_aux


/-- On the map sheet with opposite edges glued, loop A starts at (0, y0) and makes a trips across
and b trips up; loop B starts at the corner and makes c trips across and d trips up. A crossing is a
pair of times t, u in [0, 1) at which the two points differ by whole numbers in both coordinates.
When the loops cross transversally (ad - bc is not 0), every crossing has sign the sign of
ad - bc, and the sum of the signs over all crossings, the oriented intersection number, is ad - bc. -/
theorem torus_loop_intersection_number_eq_det (a b c d : ℤ) (y0 : ℝ) (h : a * d - b * c ≠ 0) :
    (∑ᶠ p ∈ {p : ℝ × ℝ | p.1 ∈ Set.Ico (0 : ℝ) 1 ∧ p.2 ∈ Set.Ico (0 : ℝ) 1 ∧
        ∃ m n : ℤ, p.1 * a - p.2 * c = m ∧ y0 + p.1 * b - p.2 * d = n},
      Int.sign (a * d - b * c)) = a * d - b * c := by
  have hc := torus_crossing_natCard_aux a b c d y0 h
  have hfin : Set.Finite {p : ℝ × ℝ | p.1 ∈ Set.Ico (0 : ℝ) 1 ∧ p.2 ∈ Set.Ico (0 : ℝ) 1 ∧
        ∃ m n : ℤ, p.1 * a - p.2 * c = m ∧ y0 + p.1 * b - p.2 * d = n} := by
    apply Nat.finite_of_card_ne_zero
    rw [hc]
    exact Int.natAbs_ne_zero.2 h
  rw [finsum_mem_eq_finite_toFinset_sum _ hfin, Finset.sum_const, ← Set.ncard_eq_toFinset_card _ hfin,
    ← Nat.card_coe_set_eq, hc, nsmul_eq_mul, Int.natCast_natAbs, mul_comm]
  exact Int.sign_mul_abs _

/-- The raw count: two transversal straight loops (a, b) and (c, d) on the glued map sheet cross at
exactly |ad - bc| points (the lattice points in the parallelogram they span). Its parity is the
mod-2 intersection number. -/
theorem torus_loop_crossing_count_eq_abs_det (a b c d : ℤ) (y0 : ℝ) (h : a * d - b * c ≠ 0) :
    Set.ncard {p : ℝ × ℝ | p.1 ∈ Set.Ico (0 : ℝ) 1 ∧ p.2 ∈ Set.Ico (0 : ℝ) 1 ∧
        ∃ m n : ℤ, p.1 * a - p.2 * c = m ∧ y0 + p.1 * b - p.2 * d = n} = (a * d - b * c).natAbs := by
  rw [← Nat.card_coe_set_eq]
  exact torus_crossing_natCard_aux a b c d y0 h

/-- Step 3's counting fact: a finite union of arcs and circles, drawn as a finite graph in which
every point has at most two neighbours, has an even number of ends (points with one neighbour). -/
theorem even_card_arc_ends {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (h : ∀ v, G.degree v ≤ 2) :
    Even (Finset.univ.filter (fun v => G.degree v = 1)).card := by
  have key := G.even_card_odd_degree_vertices
  convert key using 3 with v
  constructor
  · intro hv; rw [hv]; exact odd_one
  · intro hv
    have h2 := h v
    rcases Nat.lt_or_ge (G.degree v) 2 with hlt | hge
    · interval_cases hd : G.degree v
      · exact absurd hv (by decide)
      · rfl
    · have : G.degree v = 2 := le_antisymm h2 hge
      rw [this] at hv
      exact absurd hv (by decide)

-- The card's pairs: ad - bc for (1,0),(1,2); (1,0),(0,1); (2,1),(1,3); (1,1),(1,-1); (1,2),(1,0); (3,1),(1,2).
example : (1 : ℤ) * 2 - 0 * 1 = 2 := by norm_num
example : (1 : ℤ) * 1 - 0 * 0 = 1 := by norm_num
example : (2 : ℤ) * 3 - 1 * 1 = 5 := by norm_num
example : (1 : ℤ) * (-1) - 1 * 1 = -2 := by norm_num
example : (1 : ℤ) * 0 - 2 * 1 = -2 := by norm_num
example : (3 : ℤ) * 2 - 1 * 1 = 5 := by norm_num
-- Mod-2 count for (1, 0) and (1, 2): 2 crossings, even.
example : (2 : ℕ) % 2 = 0 := by decide

-- The projective plane from 10 triangles on 6 vertices: 15 edges, chi = 6 - 15 + 10 = 1, odd.
example :
    let tris : Finset (Finset ℕ) := {{1, 2, 3}, {1, 3, 4}, {1, 4, 5}, {1, 5, 6}, {1, 6, 2},
      {2, 3, 5}, {3, 4, 6}, {4, 5, 2}, {5, 6, 3}, {6, 2, 4}}
    let edges := tris.biUnion (fun t => t.powersetCard 2)
    let verts := tris.biUnion id
    (verts.card : ℤ) - edges.card + tris.card = 1 := by decide
-- Sphere 2, torus 0, projective plane 1 (vertices - edges + faces).
example : (4 : ℤ) - 6 + 4 = 2 := by norm_num
example : (16 : ℤ) - 48 + 32 = 0 := by norm_num

#print axioms torus_loop_intersection_number_eq_det
#print axioms torus_loop_crossing_count_eq_abs_det
#print axioms even_card_arc_ends
