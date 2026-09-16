-- Allow organization creators to view their own organization
-- (needed so a creator can add themselves as owner before becoming a member)
create policy "Creators can view their own organizations"
on public.organizations
for select
to authenticated
using (created_by = (select auth.uid()));

-- Allow authenticated users to create an organization
-- only when they set themselves as the creator.

create policy "Authenticated users can create organizations"
on public.organizations
for insert
to authenticated
with check (
  created_by = (select auth.uid())
);

-- Allow organization owners and admins to update their organization
create policy "Owners and admins can update organizations"
on public.organizations
for update
to authenticated
using (
  exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = organizations.id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role in ('owner', 'admin')
  )
)
with check (
  exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = organizations.id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role in ('owner', 'admin')
  )
);

-- Allow only organization owners to delete an organization
create policy "Owners can delete organizations"
on public.organizations
for delete
to authenticated
using (
  exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = organizations.id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role = 'owner'
  )
);

-- Allow organization creators to add themselves as the owner,
-- and existing owners/admins to add members.

create policy "Users can add organization members"
on public.organization_members
for insert
to authenticated
with check (
  (
    user_id = (select auth.uid())
    and role = 'owner'
    and exists (
      select 1
      from public.organizations
      where organizations.id = organization_members.organization_id
        and organizations.created_by = (select auth.uid())
    )
  )
  or
  (
    exists (
      select 1
      from public.organization_members as current_membership
      where current_membership.organization_id = organization_members.organization_id
        and current_membership.user_id = (select auth.uid())
        and current_membership.role in ('owner', 'admin')
    )
  )
);

-- Allow owners to update organization memberships
-- (with protection against the last remaining owner demoting themselves,
-- which would leave the organization permanently ownerless)

create policy "Owners can update organization members"
on public.organization_members
for update
to authenticated
using (
  exists (
    select 1
    from public.organization_members as current_membership
    where current_membership.organization_id = organization_members.organization_id
      and current_membership.user_id = (select auth.uid())
      and current_membership.role = 'owner'
  )
)
with check (
  exists (
    select 1
    from public.organization_members as current_membership
    where current_membership.organization_id = organization_members.organization_id
      and current_membership.user_id = (select auth.uid())
      and current_membership.role = 'owner'
  )
  and not (
    -- block only this specific case: the row being updated belongs to the
    -- current user, its new role is no longer 'owner', and they are
    -- currently the organization's only owner
    organization_members.user_id = (select auth.uid())
    and organization_members.role != 'owner'
    and (
      select count(*)
      from public.organization_members om2
      where om2.organization_id = organization_members.organization_id
        and om2.role = 'owner'
    ) = 1
  )
);

-- Allow owners to remove organization members
-- but prevent the last remaining owner from removing themselves.

create policy "Owners can delete organization members"
on public.organization_members
for delete
to authenticated
using (
  exists (
    select 1
    from public.organization_members as current_membership
    where current_membership.organization_id = organization_members.organization_id
      and current_membership.user_id = (select auth.uid())
      and current_membership.role = 'owner'
  )
  and not (
    organization_members.user_id = (select auth.uid())
    and organization_members.role = 'owner'
    and (
      select count(*)
      from public.organization_members as om2
      where om2.organization_id = organization_members.organization_id
        and om2.role = 'owner'
    ) = 1
  )
);