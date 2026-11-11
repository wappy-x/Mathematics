-- Symmetry: a turn that maps a flat lattice to itself is a full, half, third, quarter or sixth of a revolution and every one of those occurs, two flips make a turn by twice the angle between their mirrors, the six-armed snowflake's symmetries form a group of 12 moves, and the card's whole-number counts (7 strip kinds, the costs of 2 for all 17 walls) come out as it says.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Topology.MetricSpace.Isometry
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Analysis.Complex.Isometry
import Mathlib.Analysis.Normed.Affine.MazurUlam
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas

/-! The flat plane is the complex numbers `ℂ`: the point `(x, y)` is `x + y i`. The turn
by `360°/n` about the centre is multiplication by `exp (2π i / n)`. A wallpaper's lattice is
the set of whole-number combinations `p a + q b` of two slides `a`, `b` that point in
different directions (`LinearIndependent ℝ ![a, b]`): `Submodule.span ℤ {a, b}`.
A distance-keeping move of the plane is Mathlib's `ℂ ≃ᵢ ℂ` (an isometry onto the plane);
these form a group under composition. The snowflake's six tips are the six points
`z` with `z ^ 6 = 1`, arms 1 unit long, the centre at `0`. Angles are in radians:
`π / 3` is 60°. -/

open Real

theorem sym_exp_eq (n : ℕ) : Complex.exp (2 * π * Complex.I / n) =
    ((cos (2 * π / n) : ℝ) : ℂ) + ((sin (2 * π / n) : ℝ) : ℂ) * Complex.I := by
  have : 2 * π * Complex.I / n = ((2 * π / n : ℝ) : ℂ) * Complex.I := by push_cast; ring
  rw [this, Complex.exp_mul_I, ← Complex.ofReal_cos, ← Complex.ofReal_sin]

#print axioms sym_exp_eq

theorem sym_span_mul_mem (ζ a b : ℂ) (ha : ζ * a ∈ Submodule.span ℤ ({a, b} : Set ℂ))
    (hb : ζ * b ∈ Submodule.span ℤ ({a, b} : Set ℂ)) :
    ∀ z ∈ Submodule.span ℤ ({a, b} : Set ℂ), ζ * z ∈ Submodule.span ℤ ({a, b} : Set ℂ) := by
  intro z hz
  induction hz using Submodule.span_induction with
  | mem x hx =>
    rcases hx with rfl | hx
    · exact ha
    · rw [Set.mem_singleton_iff] at hx
      subst hx
      exact hb
  | zero => simp
  | add x y _ _ hx hy => rw [mul_add]; exact add_mem hx hy
  | smul c x _ hx => rw [mul_smul_comm]; exact Submodule.smul_mem _ c hx

#print axioms sym_span_mul_mem

theorem sym_image_eq_of_pow_iff (f : ℂ ≃ᵢ ℂ) (h : ∀ z : ℂ, (f z) ^ 6 = 1 ↔ z ^ 6 = 1) :
    f '' {z : ℂ | z ^ 6 = 1} = {z : ℂ | z ^ 6 = 1} := by
  ext w
  constructor
  · rintro ⟨z, hz, rfl⟩
    exact (h z).2 hz
  · intro hw
    refine ⟨f.symm w, (h _).1 ?_, by simp⟩
    simpa using hw

#print axioms sym_image_eq_of_pow_iff

/-- Step 4, the turns a wall allows. For every whole number `n ≥ 1`, a turn by `360°/n` can
map a flat lattice (the whole-number combinations of two slides in different directions) to
itself exactly when `n` is 1, 2, 3, 4 or 6: a wall turns only by a full, half, third,
quarter or sixth of a revolution, and each of those does occur. -/
theorem lattice_turn_is_half_third_quarter_or_sixth (n : ℕ) (hn : 0 < n) :
    (∃ a b : ℂ, LinearIndependent ℝ ![a, b] ∧
      ∀ z ∈ Submodule.span ℤ ({a, b} : Set ℂ),
        Complex.exp (2 * π * Complex.I / n) * z ∈ Submodule.span ℤ ({a, b} : Set ℂ)) ↔
    n ∈ ({1, 2, 3, 4, 6} : Finset ℕ) := by
  rw [sym_exp_eq]
  constructor
  · rintro ⟨a, b, hli, hinv⟩
    set c := cos (2 * π / n) with hc
    set d := sin (2 * π / n) with hd
    have ha0 : a ≠ 0 := by simpa using hli.ne_zero 0
    have hb0 : b ≠ 0 := by simpa using hli.ne_zero 1
    obtain ⟨p, q, hpq⟩ := Submodule.mem_span_pair.mp
      (hinv a (Submodule.subset_span (by simp)))
    obtain ⟨r, s, hrs⟩ := Submodule.mem_span_pair.mp
      (hinv b (Submodule.subset_span (by simp)))
    simp only [zsmul_eq_mul] at hpq hrs
    set ζ : ℂ := (c : ℂ) + (d : ℂ) * Complex.I with hζ
    have key : ((ζ - p) * (ζ - s) - q * r) * (a * b) = 0 := by
      linear_combination (-(ζ - s) * b) * hpq + (-(q * b)) * hrs
    have key2 : (ζ - p) * (ζ - s) - q * r = 0 :=
      (mul_eq_zero.mp key).resolve_right (mul_ne_zero ha0 hb0)
    have him := congrArg Complex.im key2
    simp [hζ] at him
    by_contra hmem
    have h57 : n = 5 ∨ 7 ≤ n := by simp at hmem; omega
    have hnr : (5:ℝ) ≤ n := by exact_mod_cast (by omega : 5 ≤ n)
    have hθ0 : 0 < 2 * π / n := by positivity
    have hθ1 : 2 * π / n < π := by
      rw [div_lt_iff₀ (by positivity)]; nlinarith [pi_pos]
    have hdpos : 0 < d := sin_pos_of_pos_of_lt_pi hθ0 hθ1
    have h2c : 2 * c = (p + s : ℤ) := by
      push_cast
      have : d * (2 * c - (p + s)) = 0 := by linear_combination him
      rcases mul_eq_zero.mp this with h | h
      · linarith
      · linarith
    rcases h57 with rfl | h7
    · have hlo : cos (π / 2) < c := by
        apply cos_lt_cos_of_nonneg_of_le_pi_div_two hθ0.le le_rfl
        rw [div_lt_div_iff₀ (by positivity) (by norm_num)]; push_cast; nlinarith [pi_pos]
      have hhi : c < cos (π / 3) := by
        apply cos_lt_cos_of_nonneg_of_le_pi (by positivity) hθ1.le
        rw [div_lt_div_iff₀ (by norm_num) (by positivity)]; push_cast; nlinarith [pi_pos]
      rw [cos_pi_div_two] at hlo
      rw [cos_pi_div_three] at hhi
      have h1 : (0:ℤ) < p + s := by exact_mod_cast (by linarith : (0:ℝ) < ((p + s : ℤ) : ℝ))
      have h2 : p + s < (1:ℤ) := by exact_mod_cast (by linarith : ((p + s : ℤ) : ℝ) < 1)
      omega
    · have h7r : (7:ℝ) ≤ n := by exact_mod_cast h7
      have hlo : cos (π / 3) < c := by
        apply cos_lt_cos_of_nonneg_of_le_pi hθ0.le (by linarith [pi_pos])
        rw [div_lt_div_iff₀ (by positivity) (by norm_num)]; nlinarith [pi_pos]
      have hhi : c < cos 0 := by
        apply cos_lt_cos_of_nonneg_of_le_pi le_rfl hθ1.le hθ0
      rw [cos_pi_div_three] at hlo
      rw [cos_zero] at hhi
      have h1 : (1:ℤ) < p + s := by exact_mod_cast (by linarith : (1:ℝ) < ((p + s : ℤ) : ℝ))
      have h2 : p + s < (2:ℤ) := by exact_mod_cast (by linarith : ((p + s : ℤ) : ℝ) < 2)
      omega
  · intro h
    simp only [Finset.mem_insert, Finset.mem_singleton] at h
    have h3 : √3 * √3 = 3 := Real.mul_self_sqrt (by norm_num)
    have sq_li : LinearIndependent ℝ ![(1:ℂ), Complex.I] := by
      rw [LinearIndependent.pair_iff]
      intro s t h
      have h1 := congrArg Complex.re h
      have h2 := congrArg Complex.im h
      simp at h1 h2
      exact ⟨h1, h2⟩
    have hex_li : LinearIndependent ℝ ![(1:ℂ), ((1/2 : ℝ) : ℂ) + ((√3/2 : ℝ) : ℂ) * Complex.I] := by
      rw [LinearIndependent.pair_iff]
      intro s t h
      have h1 := congrArg Complex.re h
      have h2 := congrArg Complex.im h
      simp at h1 h2
      constructor <;> linarith
    rcases h with rfl | rfl | rfl | rfl | rfl
    · have e : 2 * π / ((1:ℕ):ℝ) = 2 * π := by simp
      rw [e, cos_two_pi, sin_two_pi]
      refine ⟨1, Complex.I, sq_li, sym_span_mul_mem _ _ _ ?_ ?_⟩
      · rw [Submodule.mem_span_pair]; exact ⟨1, 0, by simp⟩
      · rw [Submodule.mem_span_pair]; exact ⟨0, 1, by simp⟩
    · have e : 2 * π / ((2:ℕ):ℝ) = π := by push_cast; ring
      rw [e, cos_pi, sin_pi]
      refine ⟨1, Complex.I, sq_li, sym_span_mul_mem _ _ _ ?_ ?_⟩
      · rw [Submodule.mem_span_pair]; exact ⟨-1, 0, by simp⟩
      · rw [Submodule.mem_span_pair]; exact ⟨0, -1, by simp⟩
    · have e : 2 * π / ((3:ℕ):ℝ) = π - π / 3 := by push_cast; ring
      rw [e, cos_pi_sub, sin_pi_sub, cos_pi_div_three, sin_pi_div_three]
      refine ⟨1, ((1/2 : ℝ) : ℂ) + ((√3/2 : ℝ) : ℂ) * Complex.I, hex_li,
        sym_span_mul_mem _ _ _ ?_ ?_⟩
      · rw [Submodule.mem_span_pair]; refine ⟨-1, 1, ?_⟩
        apply Complex.ext <;> simp; ring
      · rw [Submodule.mem_span_pair]; refine ⟨-1, 0, ?_⟩
        apply Complex.ext <;> simp <;> nlinarith
    · have e : 2 * π / ((4:ℕ):ℝ) = π / 2 := by push_cast; ring
      rw [e, cos_pi_div_two, sin_pi_div_two]
      refine ⟨1, Complex.I, sq_li, sym_span_mul_mem _ _ _ ?_ ?_⟩
      · rw [Submodule.mem_span_pair]; exact ⟨0, 1, by simp⟩
      · rw [Submodule.mem_span_pair]; exact ⟨-1, 0, by simp⟩
    · have e : 2 * π / ((6:ℕ):ℝ) = π / 3 := by push_cast; ring
      rw [e, cos_pi_div_three, sin_pi_div_three]
      refine ⟨1, ((1/2 : ℝ) : ℂ) + ((√3/2 : ℝ) : ℂ) * Complex.I, hex_li,
        sym_span_mul_mem _ _ _ ?_ ?_⟩
      · rw [Submodule.mem_span_pair]; refine ⟨0, 1, ?_⟩
        apply Complex.ext <;> simp
      · rw [Submodule.mem_span_pair]; refine ⟨-1, 1, ?_⟩
        apply Complex.ext <;> simp <;> nlinarith

/-- Step 2, two flips make a turn. For any two mirror angles `φ` and `ψ`, the flip in the
mirror at `φ` followed by the flip in the mirror at `ψ` is the turn by `2 (ψ − φ)`:
`F_ψ F_φ = R_{2(ψ − φ)}`, with `F_φ` the matrix `(cos 2φ, sin 2φ; sin 2φ, −cos 2φ)` and
`R_θ` the matrix `(cos θ, −sin θ; sin θ, cos θ)`. -/
theorem two_flips_make_a_turn (φ ψ : ℝ) :
    (!![cos (2 * ψ), sin (2 * ψ); sin (2 * ψ), -cos (2 * ψ)] : Matrix (Fin 2) (Fin 2) ℝ) *
      !![cos (2 * φ), sin (2 * φ); sin (2 * φ), -cos (2 * φ)] =
    !![cos (2 * (ψ - φ)), -sin (2 * (ψ - φ)); sin (2 * (ψ - φ)), cos (2 * (ψ - φ))] := by
  have h : 2 * (ψ - φ) = 2 * ψ - 2 * φ := by ring
  rw [h, cos_sub, sin_sub]
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two] <;> ring

/-- Steps 0 and 1, the snowflake. The distance-keeping moves of the plane that keep the
centre fixed and land the six tips (the points `z` with `z ^ 6 = 1`) on themselves form a
group, and that group has exactly 12 moves: 6 tips for the top tip to go to, times 2 sides
for its neighbour. -/
theorem snowflake_symmetries_form_group_of_twelve :
    ∃ G : Subgroup (ℂ ≃ᵢ ℂ),
      (∀ f : ℂ ≃ᵢ ℂ, f ∈ G ↔
        f 0 = 0 ∧ f '' {z : ℂ | z ^ 6 = 1} = {z : ℂ | z ^ 6 = 1}) ∧
      Nat.card G = 12 := by
  classical
  let G : Subgroup (ℂ ≃ᵢ ℂ) :=
    { carrier := {f | f 0 = 0 ∧ f '' {z : ℂ | z ^ 6 = 1} = {z : ℂ | z ^ 6 = 1}}
      mul_mem' := by
        rintro f g ⟨hf0, hf⟩ ⟨hg0, hg⟩
        refine ⟨by simp [IsometryEquiv.mul_apply, hg0, hf0], ?_⟩
        rw [IsometryEquiv.coe_mul, Set.image_comp, hg, hf]
      one_mem' := by simp
      inv_mem' := by
        rintro f ⟨hf0, hf⟩
        refine ⟨?_, ?_⟩
        · conv_lhs => rw [← hf0]
          simp
        · conv_lhs => rw [← hf]
          rw [Set.image_image]
          simp }
  refine ⟨G, fun f => Iff.rfl, ?_⟩
  let ω : Circle := Circle.exp (π / 3)
  have hprim : IsPrimitiveRoot (ω : ℂ) 6 := by
    have := Complex.isPrimitiveRoot_exp 6 (by norm_num)
    convert this using 2
    rw [Circle.coe_exp]
    push_cast
    ring_nf
  let g : Fin 6 × Bool → ℂ ≃ᵢ ℂ := fun p =>
    if p.2 then (Complex.conjLIE.trans (rotation (ω ^ (p.1 : ℕ)))).toIsometryEquiv
    else (rotation (ω ^ (p.1 : ℕ))).toIsometryEquiv
  have g_true : ∀ (k : Fin 6) (z : ℂ), g (k, true) z = (ω : ℂ) ^ (k : ℕ) * (starRingEnd ℂ) z := by
    intro k z; simp [g, -map_pow, rotation_apply]
  have g_false : ∀ (k : Fin 6) (z : ℂ), g (k, false) z = (ω : ℂ) ^ (k : ℕ) * z := by
    intro k z; simp [g, -map_pow, rotation_apply]
  have hω6 : ∀ k : ℕ, ((ω : ℂ) ^ k) ^ 6 = 1 := by
    intro k
    rw [← pow_mul, mul_comm, pow_mul, hprim.pow_eq_one, one_pow]
  have hω0 : (ω : ℂ) ≠ 0 := hprim.ne_zero (by norm_num)
  have hinj : Function.Injective g := by
    rintro ⟨k, b⟩ ⟨k', b'⟩ h
    have h1 := congrArg (fun f : ℂ ≃ᵢ ℂ => f 1) h
    have hI := congrArg (fun f : ℂ ≃ᵢ ℂ => f Complex.I) h
    have hk : k = k' := by
      apply Fin.ext
      apply hprim.pow_inj k.isLt k'.isLt
      cases b <;> cases b' <;> simpa [g_true, g_false] using h1
    subst hk
    cases b <;> cases b' <;> simp [g_true, g_false] at hI ⊢
    · have h0 : (ω : ℂ) ^ (k : ℕ) * Complex.I = 0 := by linear_combination (1/2 : ℂ) * hI
      simp [hω0] at h0
    · have h0 : (ω : ℂ) ^ (k : ℕ) * Complex.I = 0 := by linear_combination (-1/2 : ℂ) * hI
      simp [hω0] at h0
  have hrange : ∀ f : ℂ ≃ᵢ ℂ, f ∈ G ↔ f ∈ Set.range g := by
    intro f
    constructor
    · rintro ⟨hf0, hf⟩
      have hL : ∀ z, f.toRealLinearIsometryEquivOfMapZero hf0 z = f z := fun z => rfl
      have h1 : f 1 ∈ {z : ℂ | z ^ 6 = 1} := by rw [← hf]; exact ⟨1, by simp, rfl⟩
      obtain ⟨a, ha | ha⟩ := linear_isometry_complex (f.toRealLinearIsometryEquivOfMapZero hf0)
      · have hfz : ∀ z, f z = a * z := by intro z; rw [← hL, ha, rotation_apply]
        have ha6 : (a : ℂ) ^ 6 = 1 := by simpa [hfz] using h1
        obtain ⟨i, hi, hia⟩ := hprim.eq_pow_of_pow_eq_one ha6
        refine ⟨(⟨i, hi⟩, false), ?_⟩
        ext z
        rw [g_false, hfz, hia]
      · have hfz : ∀ z, f z = a * (starRingEnd ℂ) z := by
          intro z; rw [← hL, ha]; simp [-map_pow, rotation_apply]
        have ha6 : (a : ℂ) ^ 6 = 1 := by simpa [hfz] using h1
        obtain ⟨i, hi, hia⟩ := hprim.eq_pow_of_pow_eq_one ha6
        refine ⟨(⟨i, hi⟩, true), ?_⟩
        ext z
        rw [g_true, hfz, hia]
    · rintro ⟨⟨k, b⟩, rfl⟩
      refine ⟨by cases b <;> simp [g_true, g_false], sym_image_eq_of_pow_iff _ ?_⟩
      intro z
      cases b
      · rw [g_false, mul_pow, hω6, one_mul]
      · rw [g_true, mul_pow, hω6, one_mul, ← map_pow]
        exact map_eq_one_iff _ (RingHom.injective _)
  calc Nat.card G = Nat.card (Set.range g) := Nat.card_congr (Equiv.subtypeEquivRight hrange)
    _ = Nat.card (Fin 6 × Bool) := (Nat.card_congr (Equiv.ofInjective g hinj)).symm
    _ = 12 := by simp

-- Step 1: the top tip goes to one of 6 tips, its neighbour to one of 2 sides: 12 moves.
example : 6 * 2 = 12 := by norm_num
-- Step 2: mirrors at 0° and 30° give a turn by 2 × (30° − 0°) = 60°; the other order, −60°.
example : 2 * (30 - 0 : ℤ) = 60 ∧ 2 * (0 - 30 : ℤ) = -60 ∧ (-60 : ℤ) % 360 = 300 := by
  norm_num
-- Step 4: the trace of R_60 is 2 cos 60° = 1, a whole number, so a six-fold turn fits a wall.
example : 2 * Real.cos (π / 3) = 1 := by
  rw [Real.cos_pi_div_three]; norm_num
-- Step 3: of the 16 on-off lists for V, H, R, G, exactly 7 obey the rules
-- (no H with G; V and H force R; H and R force V; V and R force H or G;
-- V and G force R; R and G force V).
example :
    ((Finset.univ : Finset (Bool × Bool × Bool × Bool)).filter fun x =>
      (!(x.2.1 && x.2.2.2) && (!(x.1 && x.2.1) || x.2.2.1) &&
        (!(x.2.1 && x.2.2.1) || x.1) && (!(x.1 && x.2.2.1) || (x.2.1 || x.2.2.2)) &&
        (!(x.1 && x.2.2.2) || x.2.2.1) && (!(x.2.2.1 && x.2.2.2) || x.1)) = true).card = 7 := by
  decide
-- Step 5: the snowflake wall *632 costs 1 + 5/12 + 1/3 + 1/4 = 2, and 632 costs
-- 5/6 + 2/3 + 1/2 = 2.
example : (1 : ℚ) + 5 / 12 + 1 / 3 + 1 / 4 = 2 ∧ (5 / 6 : ℚ) + 2 / 3 + 1 / 2 = 2 := by
  norm_num
-- Step 5, the hand count: each of the 17 listed walls costs exactly 2. A turn centre of
-- fold n off the mirrors costs (n − 1)/n, on a mirror (n − 1)/(2n); `*`, `×` cost 1, `∘` 2.
example :
    let off : ℚ → ℚ := fun n => (n - 1) / n
    let on : ℚ → ℚ := fun n => (n - 1) / (2 * n)
    (2 : ℚ) = 2 ∧                                                    -- ∘
    (1 : ℚ) + 1 = 2 ∧                                                -- ××
    (1 : ℚ) + 1 = 2 ∧                                                -- *×
    (1 : ℚ) + 1 = 2 ∧                                                -- **
    off 2 + off 2 + off 2 + off 2 = 2 ∧                              -- 2222
    off 3 + off 3 + off 3 = 2 ∧                                      -- 333
    off 4 + off 4 + off 2 = 2 ∧                                      -- 442
    off 6 + off 3 + off 2 = 2 ∧                                      -- 632
    off 2 + off 2 + 1 = 2 ∧                                          -- 22×
    1 + on 2 + on 2 + on 2 + on 2 = 2 ∧                              -- *2222
    1 + on 3 + on 3 + on 3 = 2 ∧                                     -- *333
    1 + on 4 + on 4 + on 2 = 2 ∧                                     -- *442
    1 + on 6 + on 3 + on 2 = 2 ∧                                     -- *632
    off 2 + 1 + on 2 + on 2 = 2 ∧                                    -- 2*22
    off 3 + 1 + on 3 = 2 ∧                                           -- 3*3
    off 4 + 1 + on 2 = 2 ∧                                           -- 4*2
    off 2 + off 2 + 1 = 2 := by                                      -- 22*
  norm_num

#print axioms lattice_turn_is_half_third_quarter_or_sixth
#print axioms two_flips_make_a_turn
#print axioms snowflake_symmetries_form_group_of_twelve
