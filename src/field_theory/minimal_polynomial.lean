/-
Copyright (c) 2019 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Johan Commelin
-/

import ring_theory.integral_closure ring_theory.localization

/-!
# Minimal polynomials

This file defines the minimal polynomial of an element x of an A-algebra B,
under the assumption that x is integral over A.

After stating the defining property we specialize to the setting of field extensions
and derive some well-known properties, amongst which the fact that minimal polynomials
are irreducible, and uniquely determined by their defining property.

-/

universes u v w

open_locale classical
open polynomial set function

variables {α : Type u} {β : Type v}

section min_poly_def
variables [comm_ring α] [comm_ring β] [algebra α β]

/-- Let B be an A-algebra, and x an element of B that is integral over A.
The minimal polynomial of x is a monic polynomial of smallest degree that has x as its root. -/
noncomputable def minimal_polynomial {x : β} (hx : is_integral α x) : polynomial α :=
well_founded.min polynomial.degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx)

end min_poly_def

namespace minimal_polynomial

section ring
variables [comm_ring α] [comm_ring β] [algebra α β]
variables {x : β} (hx : is_integral α x)

/--A minimal polynomial is monic.-/
lemma monic : monic (minimal_polynomial hx) :=
(well_founded.min_mem degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx)).1

/--An element is a root of its minimal polynomial.-/
@[simp] lemma aeval : aeval α β x (minimal_polynomial hx) = 0 :=
(well_founded.min_mem degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx)).2

/--The defining property of the minimal polynomial of an element x:
it is the monic polynomial with smallest degree that has x as its root.-/
lemma min {p : polynomial α} (pmonic : p.monic) (hp : polynomial.aeval α β x p = 0) :
  degree (minimal_polynomial hx) ≤ degree p :=
le_of_not_lt $ well_founded.not_lt_min degree_lt_wf _ (ne_empty_iff_exists_mem.mpr hx) ⟨pmonic, hp⟩

end ring

section field
variables [discrete_field α] [discrete_field β] [algebra α β]
variables {x : β} (hx : is_integral α x)

/--A minimal polynomial is nonzero.-/
lemma ne_zero : (minimal_polynomial hx) ≠ 0 :=
ne_zero_of_monic (monic hx)

/--If an element x is a root of a nonzero polynomial p,
then the degree of p is at least the degree of the minimal polynomial of x.-/
lemma degree_le_of_ne_zero
  {p : polynomial α} (pnz : p ≠ 0) (hp : polynomial.aeval α β x p = 0) :
  degree (minimal_polynomial hx) ≤ degree p :=
calc degree (minimal_polynomial hx) ≤ degree (p * C (leading_coeff p)⁻¹) :
    min _ (monic_mul_leading_coeff_inv pnz) (by simp [hp])
  ... = degree p : degree_mul_leading_coeff_inv p pnz

/--The minimal polynomial of an element x is uniquely characterized by its defining property:
if there is another monic polynomial of minimal degree that has x as a root,
then this polynomial is equal to the minimal polynomial of x.-/
lemma unique {p : polynomial α} (pmonic : p.monic) (hp : polynomial.aeval α β x p = 0)
  (pmin : ∀ q : polynomial α, q.monic → polynomial.aeval α β x q = 0 → degree p ≤ degree q) :
  p = minimal_polynomial hx :=
begin
  symmetry, apply eq_of_sub_eq_zero,
  by_contra hnz,
  have := degree_le_of_ne_zero hx hnz (by simp [hp]),
  contrapose! this,
  apply degree_sub_lt _ (ne_zero hx),
  { rw [(monic hx).leading_coeff, pmonic.leading_coeff] },
  { exact le_antisymm (min hx pmonic hp)
      (pmin (minimal_polynomial hx) (monic hx) (aeval hx)) },
end

/--If an element x is a root of a polynomial p, then the minimal polynomial of x divides p.-/
lemma dvd {p : polynomial α} (hp : polynomial.aeval α β x p = 0) :
  minimal_polynomial hx ∣ p :=
begin
  rw ← dvd_iff_mod_by_monic_eq_zero (monic hx),
  by_contra hnz,
  have := degree_le_of_ne_zero hx hnz _,
  { contrapose! this,
    exact degree_mod_by_monic_lt _ (monic hx) (ne_zero hx) },
  { rw ← mod_by_monic_add_div p (monic hx) at hp,
    simpa using hp }
end

/--The degree of a minimal polynomial is nonzero.-/
lemma degree_ne_zero : degree (minimal_polynomial hx) ≠ 0 :=
begin
  assume deg_eq_zero,
  have ndeg_eq_zero : nat_degree (minimal_polynomial hx) = 0,
  { simpa using congr_arg nat_degree (eq_C_of_degree_eq_zero deg_eq_zero) },
  have eq_one : minimal_polynomial hx = 1,
  { rw eq_C_of_degree_eq_zero deg_eq_zero, congr,
    simpa [ndeg_eq_zero.symm] using (monic hx).leading_coeff },
  simpa [eq_one, aeval_def] using aeval hx
end

/--A minimal polynomial is not a unit.-/
lemma not_is_unit : ¬ is_unit (minimal_polynomial hx) :=
assume H, degree_ne_zero hx $ degree_eq_zero_of_is_unit H

/--The degree of a minimal polynomial is positive.-/
lemma degree_pos : 0 < degree (minimal_polynomial hx) :=
degree_pos_of_ne_zero_of_nonunit (ne_zero hx) (not_is_unit hx)

/--A minimal polynomial is prime.-/
lemma prime : prime (minimal_polynomial hx) :=
begin
  refine ⟨ne_zero hx, not_is_unit hx, _⟩,
  rintros p q ⟨d, h⟩,
  have :    polynomial.aeval α β x (p*q) = 0 := by simp [h, aeval hx],
  replace : polynomial.aeval α β x p = 0 ∨ polynomial.aeval α β x q = 0 := by simpa,
  cases this; [left, right]; apply dvd; assumption
end

/--A minimal polynomial is irreducible.-/
lemma irreducible : irreducible (minimal_polynomial hx) :=
irreducible_of_prime (prime hx)

/--If L/K is a field extension, and x is an element of L in the image of K,
then the minimal polynomial of x is X - C x.-/
@[simp] protected lemma algebra_map (a : α) (ha : is_integral α (algebra_map β a)) :
  minimal_polynomial ha = X - C a :=
begin
  refine (unique ha (monic_X_sub_C a) (by simp [aeval_def]) _).symm,
  intros q hq H,
  rw degree_X_sub_C,
  suffices : 0 < degree q,
  { -- This part is annoying and shouldn't be there.
    have q_ne_zero : q ≠ 0,
    { apply polynomial.ne_zero_of_degree_gt this },
    rw degree_eq_nat_degree q_ne_zero at this ⊢,
    rw [← with_bot.coe_zero, with_bot.coe_lt_coe] at this,
    rwa [← with_bot.coe_one, with_bot.coe_le_coe], },
  apply degree_pos_of_root (ne_zero_of_monic hq),
  show is_root q a,
  apply is_field_hom.injective (algebra_map β : α → β),
  rw [is_ring_hom.map_zero (algebra_map β : α → β), ← H],
  convert polynomial.hom_eval₂ _ _ _ _,
  { exact is_semiring_hom.id },
  { apply_instance }
end

variable (β)
/--If L/K is a field extension, and x is an element of L in the image of K,
then the minimal polynomial of x is X - C x.-/
lemma algebra_map' (a : α) :
  minimal_polynomial (@is_integral_algebra_map α β _ _ _ a) =
  X - C a :=
minimal_polynomial.algebra_map _ _
variable {β}

/--The minimal polynomial of 0 is X.-/
@[simp] lemma zero {h₀ : is_integral α (0:β)} :
  minimal_polynomial h₀ = X :=
by simpa only [add_zero, polynomial.C_0, sub_eq_add_neg, neg_zero, algebra.map_zero]
  using algebra_map' β (0:α)

/--The minimal polynomial of 1 is X - 1.-/
@[simp] lemma one {h₁ : is_integral α (1:β)} :
  minimal_polynomial h₁ = X - 1 :=
by simpa only [algebra.map_one, polynomial.C_1, sub_eq_add_neg]
  using algebra_map' β (1:α)

/--If L/K is a field extension and an element y of K is a root of the minimal polynomial
of an element x ∈ L, then y maps to x under the field embedding.-/
lemma root {x : β} (hx : is_integral α x) {y : α}
  (h : is_root (minimal_polynomial hx) y) : algebra_map β y = x :=
begin
  have ndeg_one : nat_degree (minimal_polynomial hx) = 1,
  { rw ← polynomial.degree_eq_iff_nat_degree_eq_of_pos (nat.zero_lt_one),
    exact degree_eq_one_of_irreducible_of_root (irreducible hx) h },
  have coeff_one : (minimal_polynomial hx).coeff 1 = 1,
  { simpa [ndeg_one, leading_coeff] using (monic hx).leading_coeff },
  have hy : y = - coeff (minimal_polynomial hx) 0,
  { rw (minimal_polynomial hx).as_sum at h,
    apply eq_neg_of_add_eq_zero,
    simpa [ndeg_one, finset.sum_range_succ, coeff_one] using h },
  subst y,
  rw [algebra.map_neg, neg_eq_iff_add_eq_zero],
  have H := aeval hx,
  rw (minimal_polynomial hx).as_sum at H,
  simpa [ndeg_one, finset.sum_range_succ, coeff_one, aeval_def] using H
end

/--The constant coefficient of the minimal polynomial of x is 0
if and only if x = 0.-/
@[simp] lemma coeff_zero_eq_zero : coeff (minimal_polynomial hx) 0 = 0 ↔ x = 0 :=
begin
  split,
  { intro h,
    have zero_root := polynomial.zero_is_root_of_coeff_zero_eq_zero h,
    rw ← root hx zero_root,
    exact is_ring_hom.map_zero _ },
  { rintro rfl, simp }
end

/--The minimal polynomial of a nonzero element has nonzero constant coefficient.-/
lemma coeff_zero_ne_zero (h : x ≠ 0) : coeff (minimal_polynomial hx) 0 ≠ 0 :=
by { contrapose! h, simpa using h }

end field

section integral_domain

/-variables [integral_domain α] [discrete_field β] [algebra α β]
variables {x : β} (hx : is_integral α x)

/--A minimal polynomial is nonzero.-/
--lemma ne_zero' : (minimal_polynomial hx) ≠ 0 :=
--ne_zero_of_monic (monic hx)

def fraction_field (α : Type*) [integral_domain α] : Type := sorry

instance : discrete_field (fraction_field α) := sorry

instance a1 : algebra α (fraction_field α) := sorry

instance a2 : algebra (fraction_field α) β := sorry

def im_fraction_field (α : Type*) [integral_domain α] : set (fraction_field α) :=
(set.image (algebra_map _ : α → fraction_field α) set.univ)

instance : is_subring (im_fraction_field α) := sorry

lemma map_map (y : α) : algebra_map β (algebra_map (fraction_field α) y) = algebra_map β y := sorry

lemma integral_fraction_field (hx : is_integral α x) : is_integral (fraction_field α) x := sorry

lemma minimal_polynomial_fraction_field :
  (minimal_polynomial hx).map (algebra_map _) = minimal_polynomial (integral_fraction_field hx) :=
begin
  --refine @unique (fraction_field α) β _ _ _ x _ _ _ _ _,
  refine unique _ _ _ _,
  { exact monic_map _ (monic hx) },
  { change eval₂ (algebra_map β) x _ = 0, rw [eval₂_map], conv_lhs { congr, funext, rw map_map },
    exact aeval hx },
  { intros q hqm hq0,
    rw [degree_map_eq_of_leading_coeff_ne_zero],
    { sorry },
    { rw [monic.def.mp (monic _), algebra.map_one], exact one_ne_zero } } --duplicate
end

lemma algebra_map_injective : injective (algebra_map _ : α → fraction_field α) := sorry

/--If an element x is a root of a nonzero polynomial p,
then the degree of p is at least the degree of the minimal polynomial of x.-/
lemma degree_le_of_ne_zero'
  {p : polynomial α} (pnz : p ≠ 0) (hp : polynomial.aeval α β x p = 0) :
  degree (minimal_polynomial hx) ≤ degree p :=
calc degree (minimal_polynomial hx)
    = degree ((minimal_polynomial hx).map (algebra_map _ : α → fraction_field α)) :
      eq.symm $ degree_map_eq_of_leading_coeff_ne_zero _
        (by { rw [monic.def.mp (monic _), algebra.map_one], exact one_ne_zero })
... = degree (minimal_polynomial $ integral_fraction_field hx) :
  congr_arg _ (minimal_polynomial_fraction_field _)
... ≤ degree (p.map (algebra_map _ : α → fraction_field α)) :
  begin
    refine degree_le_of_ne_zero _ _ _,
    { intro hn,
      rw [←map_zero (algebra_map _ : α → fraction_field α)] at hn,
      rw [function.injective.eq_iff (map_injective algebra_map_injective _)] at hn,
      contradiction,
      apply_instance,
      exact 0 },
    { change (eval₂ (algebra_map β) x) _ = 0,
      rw [eval₂_map], conv_lhs { congr, funext, rw map_map }, exact hp }
  end
... = degree p :
  begin
    refine degree_map_eq_of_leading_coeff_ne_zero _ _,
    intro hn,
    rw [←algebra.map_zero α (fraction_field α)] at hn,
    rw [function.injective.eq_iff algebra_map_injective, leading_coeff_eq_zero] at hn,
    contradiction
  end
-/

variables [integral_domain α] [integral_domain β] [algebra α β]
variables {x : β} (hx : is_integral α x)

open localization localization.fraction_ring

lemma algebra_map_injective {α β : Type*} [discrete_field α] [discrete_field β] [algebra α β] :
  injective (algebra_map _ : α → β) := sorry

--instance : algebra (fraction_ring α) (fraction_ring β) :=
--algebra.mk (map algebra_map algebra_map_injective) _ _
instance : algebra (fraction_ring α) (fraction_ring β) := sorry

lemma algebra_map_of {y : α} :
  (algebra_map _ : fraction_ring α → fraction_ring β) (of y) = of (algebra_map β y) := sorry

#check eval₂ (algebra_map (fraction_ring β)) (of x) (map of (minimal_polynomial hx)) = 0
#check eval₂ (algebra_map (fraction_ring β)) (of x) (map of (minimal_polynomial hx)) = 0

/--A minimal polynomial is nonzero.-/
lemma ne_zero' : (minimal_polynomial hx) ≠ 0 :=
ne_zero_of_monic (monic hx)

lemma is_integral_fraction_ring (hx : is_integral α x) :
  is_integral (fraction_ring α) (of x : fraction_ring β) := sorry

lemma test : (minimal_polynomial hx).map (of : α → fraction_ring α) =
  minimal_polynomial (is_integral_fraction_ring hx) :=
minimal_polynomial.unique (is_integral_fraction_ring hx) (monic_map _ (monic hx))
(calc (eval₂ (algebra_map _) (of x)) _
    = (eval₂ (λ y:α, (algebra_map _ : fraction_ring α → fraction_ring β)
          ((of : α → fraction_ring α) y)) (of x)) (minimal_polynomial hx) :
            eval₂_map (of : α → fraction_ring α) _ _
... = of (eval₂ (algebra_map _) x (minimal_polynomial hx)) : sorry
... = 0 : sorry)
sorry

/-(calc (eval₂ (algebra_map _) (of x)) _
      = (eval₂ (λ y:α, (algebra_map _ : fraction_ring α → fraction_ring β)
          ((of : α → fraction_ring α) y)) (of x)) _ :
          @eval₂_map α (fraction_ring α) _ (minimal_polynomial hx) _ (of : α → fraction_ring α) _
          (fraction_ring β) _ (algebra_map _) _ (of x)
  ---... = eval₂ (λ y:α, of (algebra_map _ y)) (of x) (minimal_polynomial hx) :
  ---  begin congr, ext, exact algebra_map_of end
  ---... = of (eval₂ (algebra_map _) x (minimal_polynomial hx)) : begin sorry end
  ... = 0 : sorry)-/

lemma degree_map_of {p : polynomial α} :
  degree (p.map (of : α → fraction_ring α)) = degree p :=
classical.by_cases (λ h : p = 0, by { rw [h, map_zero], refl })
  (λ hn, degree_map_eq_of_leading_coeff_ne_zero _
    (λ h, absurd (leading_coeff_eq_zero.mp $ eq_zero_of _ h) hn))

/--If an element x is a root of a nonzero polynomial p,
then the degree of p is at least the degree of the minimal polynomial of x.-/
lemma degree_le_of_ne_zero2'
  {p : polynomial α} (pnz : p ≠ 0) (hp : polynomial.aeval α β x p = 0) :
  degree (minimal_polynomial hx) ≤ degree p :=
have hi : is_integral (fraction_ring α) (of x : fraction_ring β), from is_integral_fraction_ring hx,
calc degree (minimal_polynomial hx)
    = degree ((minimal_polynomial hx).map (of : α → fraction_ring α)) : eq.symm $ degree_map_of
... = degree (minimal_polynomial hi) : congr_arg _ $ test hx
... ≤ degree (p.map (of : α → fraction_ring α)) :
  minimal_polynomial.degree_le_of_ne_zero hi sorry sorry
... = degree p : degree_map_of

end integral_domain

end minimal_polynomial
