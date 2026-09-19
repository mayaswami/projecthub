-- Allow organization members to create projects and require them to set themselves as the creator.
create policy "Organization members can create projects"
on public.projects
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = projects.organization_id
      and organization_members.user_id = (select auth.uid())
  )
);

-- Allow organization owners/admins and project creators to update project details.
create policy "Owners admins and creators can update projects"
on public.projects
for update
to authenticated
using (
  exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = projects.organization_id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role in ('owner', 'admin')
  )
  or (
    created_by = (select auth.uid())
    and exists (
      select 1
      from public.organization_members
      where organization_members.organization_id = projects.organization_id
        and organization_members.user_id = (select auth.uid())
    )
  )
)
with check (
  exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = projects.organization_id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role in ('owner', 'admin')
  )
  or (
    created_by = (select auth.uid())
    and exists (
      select 1
      from public.organization_members
      where organization_members.organization_id = projects.organization_id
        and organization_members.user_id = (select auth.uid())
    )
  )
);

-- Allow organization owners/admins and project creators to delete projects.
create policy "Owners admins and creators can delete projects"
on public.projects
for delete
to authenticated
using (
  exists (
    select 1
    from public.organization_members
    where organization_members.organization_id = projects.organization_id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role in ('owner', 'admin')
  )
  or (
    created_by = (select auth.uid())
    and exists (
      select 1
      from public.organization_members
      where organization_members.organization_id = projects.organization_id
        and organization_members.user_id = (select auth.uid())
    )
  )
);
-- Allow organization owners/admins and project creators
-- to add organization members to a project.
create policy "Owners admins and creators can add project members"
on public.project_members
for insert
to authenticated
with check (
  (
    exists (
      select 1
      from public.projects
      join public.organization_members
        on organization_members.organization_id = projects.organization_id
      where projects.id = project_members.project_id
        and organization_members.user_id = (select auth.uid())
        and organization_members.role in ('owner', 'admin')
    )
    or
    exists (
      select 1
      from public.projects
      join public.organization_members
        on organization_members.organization_id = projects.organization_id
      where projects.id = project_members.project_id
        and projects.created_by = (select auth.uid())
        and organization_members.user_id = (select auth.uid())
    )
  )
  and exists (
    select 1
    from public.projects
    join public.organization_members
      on organization_members.organization_id = projects.organization_id
    where projects.id = project_members.project_id
      and organization_members.user_id = project_members.user_id
  )
);

-- Allow organization owners/admins and project creators
-- to remove members from a project.
create policy "Owners admins and creators can remove project members"
on public.project_members
for delete
to authenticated
using (
  (
    exists (
      select 1
      from public.projects
      join public.organization_members
        on organization_members.organization_id = projects.organization_id
      where projects.id = project_members.project_id
        and organization_members.user_id = (select auth.uid())
        and organization_members.role in ('owner', 'admin')
    )
    or
    exists (
      select 1
      from public.projects
      join public.organization_members
        on organization_members.organization_id = projects.organization_id
      where projects.id = project_members.project_id
        and projects.created_by = (select auth.uid())
        and organization_members.user_id = (select auth.uid())
    )
  )
);

-- TASKS: INSERT / UPDATE / DELETE

-- Allow organization members to create tasks.
-- The task creator must be the currently authenticated user.
create policy "Organization members can create tasks"
on public.tasks
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.projects
    join public.organization_members
      on organization_members.organization_id = projects.organization_id
    where projects.id = tasks.project_id
      and organization_members.user_id = (select auth.uid())
  )
);


-- Allow organization members to update tasks.
-- The updated task must still belong to an organization
-- that the current user is a member of.
create policy "Organization members can update tasks"
on public.tasks
for update
to authenticated
using (
  exists (
    select 1
    from public.projects
    join public.organization_members
      on organization_members.organization_id = projects.organization_id
    where projects.id = tasks.project_id
      and organization_members.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.projects
    join public.organization_members
      on organization_members.organization_id = projects.organization_id
    where projects.id = tasks.project_id
      and organization_members.user_id = (select auth.uid())
  )
);

-- Allow task creators and organization owners/admins
-- to delete tasks.
create policy "Creators owners and admins can delete tasks"
on public.tasks
for delete
to authenticated
using (
  (
    created_by = (select auth.uid())
    and exists (
      select 1
      from public.projects
      join public.organization_members
        on organization_members.organization_id = projects.organization_id
      where projects.id = tasks.project_id
        and organization_members.user_id = (select auth.uid())
    )
  )
  or
  exists (
    select 1
    from public.projects
    join public.organization_members
      on organization_members.organization_id = projects.organization_id
    where projects.id = tasks.project_id
      and organization_members.user_id = (select auth.uid())
      and organization_members.role in ('owner', 'admin')
  )
);