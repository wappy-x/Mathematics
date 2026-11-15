-- Vietoris-Rips, Cech and alpha complexes: in the plane every Cech simplex at radius r is a Rips simplex at r, and every Rips simplex at r is a Cech simplex at 2r/√3.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Radon
import Mathlib.Analysis.Normed.Module.Convex

open Metric

/-- The plane, with ordinary straight-line distance. -/
abbrev Plane := EuclideanSpace ℝ (Fin 2)

/-- Rips test at ball radius `r`: every two sites of `σ` stand within `2r`. -/
def IsRipsSimplex {ι : Type*} (x : ι → Plane) (r : ℝ) (σ : Finset ι) : Prop :=
  ∀ i ∈ σ, ∀ j ∈ σ, dist (x i) (x j) ≤ 2 * r

/-- Čech test at ball radius `r`: the closed discs of radius `r` round the sites of `σ`
share a point. -/
def IsCechSimplex {ι : Type*} (x : ι → Plane) (r : ℝ) (σ : Finset ι) : Prop :=
  (⋂ i ∈ σ, closedBall (x i) r).Nonempty

lemma dist_sq_plane (p q : Plane) : dist p q ^ 2 = (p 0 - q 0) ^ 2 + (p 1 - q 1) ^ 2 := by
  rw [EuclideanSpace.dist_sq_eq, Fin.sum_univ_two, Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]

lemma le_of_sq_le_sq_nonneg {s t : ℝ} (_hs : 0 ≤ s) (ht : 0 ≤ t) (h : s ^ 2 ≤ t ^ 2) : s ≤ t := by
  nlinarith

lemma midpoint_close (a b c : Plane) (h : dist a b ^ 2 + dist b c ^ 2 ≤ dist a c ^ 2) :
    ∃ m : Plane, dist m a ≤ dist a c / 2 ∧ dist m b ≤ dist a c / 2 ∧ dist m c ≤ dist a c / 2 := by
  have hab := dist_sq_plane a b
  have hbc := dist_sq_plane b c
  have hac := dist_sq_plane a c
  refine ⟨!₂[(a 0 + c 0) / 2, (a 1 + c 1) / 2], ?_, ?_, ?_⟩ <;>
  · apply le_of_sq_le_sq_nonneg dist_nonneg (by positivity)
    rw [div_pow, dist_sq_plane, hac]
    simp
    nlinarith

lemma circ_real (u0 u1 v0 v1 x y z dd : ℝ) (hxd : x = u0 ^ 2 + u1 ^ 2)
    (hyd : y = v0 ^ 2 + v1 ^ 2) (hzd : z = (u0 - v0) ^ 2 + (u1 - v1) ^ 2)
    (hx : x ≤ dd) (hy : y ≤ x) (hz : z ≤ x) (hacute : x < y + z) :
    ∃ o0 o1 : ℝ, o0 ^ 2 + o1 ^ 2 ≤ dd / 3 ∧ (o0 - u0) ^ 2 + (o1 - u1) ^ 2 = o0 ^ 2 + o1 ^ 2 ∧
      (o0 - v0) ^ 2 + (o1 - v1) ^ 2 = o0 ^ 2 + o1 ^ 2 := by
  have hD2 : 4 * (u0 * v1 - u1 * v0) ^ 2 = 4 * y * z - (y + z - x) ^ 2 := by
    rw [hxd, hyd, hzd]; ring
  have hy0 : 0 < y := by linarith
  have hz0 : 0 < z := by linarith
  have ht : (y + z - x) ^ 2 ≤ y * z := by nlinarith
  have h3 : 3 * y * z ≤ 4 * (u0 * v1 - u1 * v0) ^ 2 := by linarith
  have hDpos : 0 < (u0 * v1 - u1 * v0) ^ 2 := by nlinarith
  have hD : u0 * v1 - u1 * v0 ≠ 0 := by
    intro h0; rw [h0] at hDpos; simp at hDpos
  have hx0 : 0 ≤ x := by rw [hxd]; positivity
  refine ⟨(x * v1 - y * u1) / (2 * (u0 * v1 - u1 * v0)),
    (y * u0 - x * v0) / (2 * (u0 * v1 - u1 * v0)), ?_, ?_, ?_⟩
  · have hnum : (x * v1 - y * u1) ^ 2 + (y * u0 - x * v0) ^ 2 = x * y * z := by
      rw [hxd, hyd, hzd]; ring
    rw [div_pow, div_pow, ← add_div, hnum, div_le_div_iff₀ (by positivity) (by norm_num)]
    nlinarith [mul_le_mul_of_nonneg_left h3 hx0,
      mul_le_mul_of_nonneg_right hx (le_of_lt hDpos)]
  · have hdot : (x * v1 - y * u1) / (2 * (u0 * v1 - u1 * v0)) * u0
        + (y * u0 - x * v0) / (2 * (u0 * v1 - u1 * v0)) * u1 = x / 2 := by
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div,
        div_eq_iff (mul_ne_zero two_ne_zero hD)]
      rw [hxd]; ring
    linear_combination (-2) * hdot - hxd
  · have hdot : (x * v1 - y * u1) / (2 * (u0 * v1 - u1 * v0)) * v0
        + (y * u0 - x * v0) / (2 * (u0 * v1 - u1 * v0)) * v1 = y / 2 := by
      rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div,
        div_eq_iff (mul_ne_zero two_ne_zero hD)]
      rw [hyd]; ring
    linear_combination (-2) * hdot - hyd

lemma jung3_core (a b c : Plane) (d : ℝ) (hd : 0 ≤ d) (hac : dist a c ≤ d)
    (h1 : dist a b ≤ dist a c) (h2 : dist b c ≤ dist a c) :
    ∃ p : Plane, dist p a ≤ d / √3 ∧ dist p b ≤ d / √3 ∧ dist p c ≤ d / √3 := by
  have hs3 : 0 < √3 := by positivity
  have hs3' : √3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hR : 0 ≤ d / √3 := by positivity
  have hRsq : (d / √3) ^ 2 = d ^ 2 / 3 := by rw [div_pow, hs3']
  by_cases hob : dist a b ^ 2 + dist b c ^ 2 ≤ dist a c ^ 2
  · obtain ⟨m, hma, hmb, hmc⟩ := midpoint_close a b c hob
    have key : dist a c / 2 ≤ d / √3 := by
      rw [div_le_div_iff₀ (by norm_num) hs3]
      nlinarith [dist_nonneg (x := a) (y := c)]
    exact ⟨m, hma.trans key, hmb.trans key, hmc.trans key⟩
  · push Not at hob
    have e1 : dist a c ^ 2 = (c 0 - a 0) ^ 2 + (c 1 - a 1) ^ 2 := by rw [dist_sq_plane]; ring
    have e2 : dist a b ^ 2 = (b 0 - a 0) ^ 2 + (b 1 - a 1) ^ 2 := by rw [dist_sq_plane]; ring
    have e3 : dist b c ^ 2 = ((c 0 - a 0) - (b 0 - a 0)) ^ 2 + ((c 1 - a 1) - (b 1 - a 1)) ^ 2 := by
      rw [dist_sq_plane]; ring
    have hx : dist a c ^ 2 ≤ d ^ 2 := pow_le_pow_left₀ dist_nonneg hac 2
    have hy : dist a b ^ 2 ≤ dist a c ^ 2 := pow_le_pow_left₀ dist_nonneg h1 2
    have hz : dist b c ^ 2 ≤ dist a c ^ 2 := pow_le_pow_left₀ dist_nonneg h2 2
    obtain ⟨o0, o1, ho, hou, hov⟩ := circ_real (c 0 - a 0) (c 1 - a 1) (b 0 - a 0) (b 1 - a 1)
      _ _ _ (d ^ 2) e1 e2 e3 hx hy hz (by linarith)
    have ho' : o0 ^ 2 + o1 ^ 2 ≤ (d / √3) ^ 2 := by rw [hRsq]; exact ho
    refine ⟨!₂[a 0 + o0, a 1 + o1], ?_, ?_, ?_⟩ <;>
    · apply le_of_sq_le_sq_nonneg dist_nonneg hR
      rw [dist_sq_plane]
      simp only [Matrix.cons_val_zero, Matrix.cons_val_one]
      nlinarith [ho', hou, hov]

lemma jung3 (a b c : Plane) (d : ℝ) (hd : 0 ≤ d) (hab : dist a b ≤ d) (hbc : dist b c ≤ d)
    (hac : dist a c ≤ d) :
    ∃ p : Plane, dist p a ≤ d / √3 ∧ dist p b ≤ d / √3 ∧ dist p c ≤ d / √3 := by
  have cab := dist_comm a b
  have cbc := dist_comm b c
  have cac := dist_comm a c
  have hacb : ∀ p : Plane, dist p a ≤ d / √3 → dist p c ≤ d / √3 → dist p b ≤ d / √3 →
      ∃ p : Plane, dist p a ≤ d / √3 ∧ dist p b ≤ d / √3 ∧ dist p c ≤ d / √3 :=
    fun p h1 h2 h3 => ⟨p, h1, h3, h2⟩
  have hbac : ∀ p : Plane, dist p b ≤ d / √3 → dist p a ≤ d / √3 → dist p c ≤ d / √3 →
      ∃ p : Plane, dist p a ≤ d / √3 ∧ dist p b ≤ d / √3 ∧ dist p c ≤ d / √3 :=
    fun p h1 h2 h3 => ⟨p, h2, h1, h3⟩
  rcases le_total (dist a b) (dist a c) with h1 | h1
  · rcases le_total (dist b c) (dist a c) with h2 | h2
    · exact jung3_core a b c d hd hac h1 h2
    · obtain ⟨p, h1', h2', h3'⟩ := jung3_core b a c d hd hbc (by linarith) (by linarith)
      exact hbac p h1' h2' h3'
  · rcases le_total (dist b c) (dist a b) with h2 | h2
    · obtain ⟨p, h1', h2', h3'⟩ := jung3_core a c b d hd hab (by linarith) (by linarith)
      exact hacb p h1' h2' h3'
    · obtain ⟨p, h1', h2', h3'⟩ := jung3_core b a c d hd hbc (by linarith) (by linarith)
      exact hbac p h1' h2' h3'

lemma finset_le_three {ι : Type*} (τ : Finset ι) (h : τ.card ≤ 3) (hne : τ.Nonempty) :
    ∃ i ∈ τ, ∃ j ∈ τ, ∃ k ∈ τ, ∀ l ∈ τ, l = i ∨ l = j ∨ l = k := by
  classical
  have hpos := hne.card_pos
  rcases (show τ.card = 1 ∨ τ.card = 2 ∨ τ.card = 3 by omega) with hc | hc | hc
  · obtain ⟨i, rfl⟩ := Finset.card_eq_one.1 hc
    exact ⟨i, by simp, i, by simp, i, by simp, by simp⟩
  · obtain ⟨i, j, -, rfl⟩ := Finset.card_eq_two.1 hc
    exact ⟨i, by simp, j, by simp, j, by simp, by simp⟩
  · obtain ⟨i, j, k, -, -, -, rfl⟩ := Finset.card_eq_three.1 hc
    exact ⟨i, by simp, j, by simp, k, by simp, by simp⟩

lemma finrank_plane : Module.finrank ℝ Plane = 2 := finrank_euclideanSpace_fin

#print axioms dist_sq_plane
#print axioms le_of_sq_le_sq_nonneg
#print axioms midpoint_close
#print axioms circ_real
#print axioms jung3_core
#print axioms jung3
#print axioms finset_le_three
#print axioms finrank_plane

/-- **Rips–Čech sandwich in the plane.** Every Čech simplex at radius `r` is a Rips simplex at
radius `r`, and every Rips simplex at radius `r` is a Čech simplex at radius `2r/√3`:
`Č_r ⊆ VR_r ⊆ Č_{2r/√3}`. -/
theorem cech_subset_rips_subset_cech_two_div_sqrt_three {ι : Type*} (x : ι → Plane) (r : ℝ)
    (σ : Finset ι) :
    (IsCechSimplex x r σ → IsRipsSimplex x r σ) ∧
      (IsRipsSimplex x r σ → IsCechSimplex x (2 * r / Real.sqrt 3) σ) := by
  constructor
  · rintro ⟨p, hp⟩ i hi j hj
    rw [Set.mem_iInter₂] at hp
    have hi' : dist p (x i) ≤ r := hp i hi
    have hj' : dist p (x j) ≤ r := hp j hj
    calc dist (x i) (x j) ≤ dist (x i) p + dist p (x j) := dist_triangle _ _ _
      _ ≤ 2 * r := by rw [dist_comm] at hi'; linarith
  · intro hR
    classical
    rcases σ.eq_empty_or_nonempty with rfl | ⟨i0, hi0⟩
    · simp [IsCechSimplex]
    have hr : 0 ≤ r := by
      have := hR i0 hi0 i0 hi0
      simp at this; linarith
    unfold IsCechSimplex
    apply Convex.helly_theorem' (𝕜 := ℝ) (fun i _ => convex_closedBall _ _)
    intro τ hτσ hτc
    rw [finrank_plane] at hτc
    rcases τ.eq_empty_or_nonempty with rfl | hne
    · simp
    obtain ⟨i, hi, j, hj, k, hk, hall⟩ := finset_le_three τ (by omega) hne
    obtain ⟨p, hpi, hpj, hpk⟩ := jung3 (x i) (x j) (x k) (2 * r) (by linarith)
      (hR i (hτσ hi) j (hτσ hj)) (hR j (hτσ hj) k (hτσ hk)) (hR i (hτσ hi) k (hτσ hk))
    refine ⟨p, Set.mem_iInter₂.2 fun l hl => ?_⟩
    rw [mem_closedBall]
    rcases hall l hl with rfl | rfl | rfl
    · exact hpi
    · exact hpj
    · exact hpk

/-- **Helly in the plane: triples decide.** A set of sites is a Čech simplex exactly when every
part of it with at most three sites is one. -/
theorem cech_simplex_iff_every_triple {ι : Type*} (x : ι → Plane) (r : ℝ) (σ : Finset ι) :
    IsCechSimplex x r σ ↔ ∀ τ ⊆ σ, τ.card ≤ 3 → IsCechSimplex x r τ := by
  unfold IsCechSimplex
  constructor
  · rintro ⟨p, hp⟩ τ hτ -
    refine ⟨p, Set.mem_iInter₂.2 fun i hi => ?_⟩
    exact Set.mem_iInter₂.1 hp i (hτ hi)
  · intro h
    apply Convex.helly_theorem' (𝕜 := ℝ) (fun i _ => convex_closedBall _ _)
    intro τ hτ hc
    rw [finrank_plane] at hc
    exact h τ hτ hc

/-- **Right or obtuse triangle.** If the angle at `b` is 90° or more
(`|a - c|² ≥ |a - b|² + |b - c|²`), the discs of radius `r` round `a`, `b`, `c` share a point
exactly when the longest side `|a - c|` is at most `2r`: the longest side is a diameter. -/
theorem obtuse_triangle_cech_iff_longest_side {a b c : Plane} (r : ℝ)
    (hobtuse : dist a b ^ 2 + dist b c ^ 2 ≤ dist a c ^ 2) :
    (closedBall a r ∩ closedBall b r ∩ closedBall c r).Nonempty ↔ dist a c ≤ 2 * r := by
  constructor
  · rintro ⟨p, ⟨hpa, -⟩, hpc⟩
    rw [mem_closedBall] at hpa hpc
    calc dist a c ≤ dist a p + dist p c := dist_triangle _ _ _
      _ ≤ 2 * r := by rw [dist_comm] at hpa; linarith
  · intro h
    obtain ⟨m, hma, hmb, hmc⟩ := midpoint_close a b c hobtuse
    exact ⟨m, ⟨mem_closedBall.2 (by linarith), mem_closedBall.2 (by linarith)⟩,
      mem_closedBall.2 (by linarith)⟩

/-! The card's twelve sensor sites, in metres, and its whole-number worked examples. -/

/-- The twelve sites, numbered 0 to 11. -/
def site : Fin 12 → ℤ × ℤ :=
  ![(270, 200), (235, 285), (150, 320), (65, 285), (30, 200), (65, 115), (150, 80),
    (235, 115), (330, 278), (102, 315), (0, 120), (200, 10)]

/-- Squared distance between two sites, in square metres. -/
def d2 (i j : Fin 12) : ℤ :=
  ((site i).1 - (site j).1) ^ 2 + ((site i).2 - (site j).2) ^ 2

-- Squared sides of the gap triangle [0, 1, 8] and of the obtuse triangle [2, 3, 9].
example : d2 0 1 = 8450 ∧ d2 0 8 = 9684 ∧ d2 1 8 = 9074 := by decide
example : d2 2 3 = 8450 ∧ d2 2 9 = 2329 ∧ d2 3 9 = 2269 := by decide
example : d2 4 5 = 8450 ∧ d2 4 10 = 7300 ∧ d2 5 10 = 4250 := by decide

-- At r = 50 m an edge needs squared distance at most 100² = 10000: there are 15 edges.
example : ((Finset.univ : Finset (Fin 12 × Fin 12)).filter
    (fun p => p.1 < p.2 ∧ d2 p.1 p.2 ≤ 10000)).card = 15 := by decide

-- [2, 3, 9] is obtuse: 2329 + 2269 = 4598 falls short of 8450.
example : (2329 : ℤ) + 2269 = 4598 ∧ (4598 : ℤ) < 8450 := by norm_num

-- [0, 1, 8]: twice its area is 7830, and its circumradius squared is
-- 8450 · 9684 · 9074 / (4 · 7830²) = 206256557/68121, more than 50² = 2500 but at most
-- (2 · 50)² / 3 = 10000/3, the Rips–Čech bound.
example : (235 - 270) * (278 - 200) - (285 - 200) * (330 - 270) = (-7830 : ℤ) := by norm_num
example : ((8450 * 9684 * 9074 : ℚ) / (4 * 7830 ^ 2)) = 206256557 / 68121 := by norm_num
example : (2500 : ℚ) < 206256557 / 68121 ∧ (206256557 : ℚ) / 68121 ≤ 10000 / 3 := by norm_num

-- Sizes and Euler characteristics at 50 m: Rips 12 + 15 + 3 = 30, χ = 0; Čech 12 + 15 + 2 = 29,
-- χ = -1; loops β₁ = β₀ + β₂ - χ: Rips 1, Čech 2.
example : 12 + 15 + 3 = 30 ∧ 12 + 15 + 2 = 29 := by norm_num
example : (12 : ℤ) - 15 + 3 = 0 ∧ (12 : ℤ) - 15 + 2 = -1 := by norm_num
example : (1 : ℤ) + 0 - 0 = 1 ∧ (1 : ℤ) + 0 - (-1) = 2 := by norm_num

-- Delaunay ceiling for twelve sites: 3 · 12 - 6 = 30 edges and 2 · 12 - 5 = 19 triangles.
example : 3 * 12 - 6 = 30 ∧ 2 * 12 - 5 = 19 := by norm_num

#print axioms cech_subset_rips_subset_cech_two_div_sqrt_three
#print axioms cech_simplex_iff_every_triple
#print axioms obtuse_triangle_cech_iff_longest_side
