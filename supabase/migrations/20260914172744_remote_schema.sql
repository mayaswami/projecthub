SET local check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

CREATE POLICY "Organization members can view activity logs" ON "public"."activity_log"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.organization_members
  WHERE ((organization_members.organization_id = activity_log.organization_id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "Organization members can view task attachments" ON "public"."attachments"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM ((public.tasks
     JOIN public.projects ON ((projects.id = tasks.project_id)))
     JOIN public.organization_members ON ((organization_members.organization_id = projects.organization_id)))
  WHERE ((tasks.id = attachments.task_id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "Organization members can view task comments" ON "public"."comments"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM ((public.tasks
     JOIN public.projects ON ((projects.id = tasks.project_id)))
     JOIN public.organization_members ON ((organization_members.organization_id = projects.organization_id)))
  WHERE ((tasks.id = comments.task_id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "Users can view their own notifications" ON "public"."notifications"
  FOR SELECT
  TO "authenticated"
  USING ((user_id = ( SELECT auth.uid() AS uid)));

CREATE POLICY "Users can view their own memberships" ON "public"."organization_members"
  FOR SELECT
  TO "authenticated"
  USING ((user_id = auth.uid()));

CREATE POLICY "Members can view their organizations" ON "public"."organizations"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.organization_members
  WHERE ((organization_members.organization_id = organizations.id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "Organization members can view project members" ON "public"."project_members"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM (public.projects
     JOIN public.organization_members ON ((organization_members.organization_id = projects.organization_id)))
  WHERE ((projects.id = project_members.project_id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "Members can view organization projects" ON "public"."projects"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.organization_members
  WHERE ((organization_members.organization_id = projects.organization_id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

CREATE POLICY "Organization members can view project tasks" ON "public"."tasks"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM (public.projects
     JOIN public.organization_members ON ((organization_members.organization_id = projects.organization_id)))
  WHERE ((projects.id = tasks.project_id) AND (organization_members.user_id = ( SELECT auth.uid() AS uid))))));

