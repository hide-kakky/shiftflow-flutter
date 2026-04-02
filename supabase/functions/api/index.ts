import { createServiceClient } from '../_shared/supabase.ts';
import { corsHeaders, decodeJwtPayload, jsonResponse, readBearerToken } from '../_shared/cors.ts';
import { dispatchQueuedNotifications } from '../_shared/notification_dispatch.ts';

type AccessContext = {
  userId: string;
  email: string;
  orgId: string;
  role: 'admin' | 'manager' | 'member' | 'guest';
  membershipId: string;
};

function isManagerRole(role: string): boolean {
  return role === 'admin' || role === 'manager';
}

function isMemberRole(role: string): boolean {
  return role === 'admin' || role === 'manager' || role === 'member';
}

function asString(value: unknown): string {
  if (typeof value !== 'string') return '';
  return value.trim();
}

function asMap(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

function asList(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function asBool(value: unknown): boolean {
  return value === true;
}

async function resolveAccessContext(request: Request): Promise<AccessContext> {
  const token = readBearerToken(request);
  const payload = decodeJwtPayload(token);
  const authUserId = asString(payload.sub);
  const email = asString(payload.email).toLowerCase();

  if (!authUserId && !email) {
    throw new Error('invalid_token');
  }

  const service = createServiceClient();

  let userQuery = service.from('users').select('*').limit(1);
  if (authUserId) {
    userQuery = userQuery.eq('auth_user_id', authUserId);
  } else {
    userQuery = userQuery.eq('email', email);
  }

  const { data: existingUser, error: userError } = await userQuery.maybeSingle();
  if (userError) throw userError;

  let user = existingUser;

  if (!user) {
    const { data: inserted, error: insertError } = await service
      .from('users')
      .insert({
        auth_user_id: authUserId || null,
        email,
        display_name: email.split('@')[0] || 'user',
        status: 'pending',
        is_active: false,
      })
      .select('*')
      .single();

    if (insertError) throw insertError;
    user = inserted;
  }

  if (authUserId && !user.auth_user_id) {
    await service.from('users').update({ auth_user_id: authUserId }).eq('id', user.id);
  }

  const { data: memberships, error: membershipError } = await service
    .from('memberships')
    .select('*')
    .eq('user_id', user.id)
    .order('created_at', { ascending: true });

  if (membershipError) throw membershipError;

  const activeMembership = (memberships ?? []).find((m) => m.status === 'active');

  if (!activeMembership) {
    return {
      userId: user.id,
      email: user.email,
      orgId: '',
      role: 'guest',
      membershipId: '',
    };
  }

  return {
    userId: user.id,
    email: user.email,
    orgId: activeMembership.organization_id,
    role: activeMembership.role,
    membershipId: activeMembership.id,
  };
}

function ensureSignedIn(ctx: AccessContext) {
  if (!ctx.userId || !ctx.orgId || !isMemberRole(ctx.role)) {
    throw new Error('access_denied');
  }
}

function ensureManager(ctx: AccessContext) {
  ensureSignedIn(ctx);
  if (!isManagerRole(ctx.role)) {
    throw new Error('forbidden');
  }
}

async function insertAuditLog(
  action: string,
  ctx: AccessContext,
  targetType: string,
  targetId: string,
  payload: Record<string, unknown> = {},
) {
  const service = createServiceClient();
  await service.from('audit_logs').insert({
    organization_id: ctx.orgId,
    actor_membership_id: ctx.membershipId || null,
    target_type: targetType,
    target_id: targetId,
    action,
    payload_json: payload,
  });
}

async function enqueueDispatch(
  eventType: 'new_message' | 'new_task_assigned' | 'task_due_tomorrow',
  orgId: string,
  sourceId: string,
  targetUserIds: string[],
) {
  const service = createServiceClient();
  for (const userId of targetUserIds) {
    const { data: existing } = await service
      .from('notification_dispatch_logs')
      .select('id')
      .eq('event_type', eventType)
      .eq('source_id', sourceId)
      .eq('target_user_id', userId)
      .limit(1)
      .maybeSingle();
    if (existing) continue;
    await service.from('notification_dispatch_logs').insert({
      event_type: eventType,
      organization_id: orgId,
      target_user_id: userId,
      source_id: sourceId,
      status: 'queued',
    });
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const ctx = await resolveAccessContext(request);
    const service = createServiceClient();

    const body = request.method === 'GET' ? {} : asMap(await request.json().catch(() => ({})));
    const route = asString(body.route);
    const method = asString(body.method).toUpperCase() || request.method.toUpperCase();
    const args = asList(body.args);
    const segments = route.split('/').filter((s) => s.length > 0);

    if (!route) {
      return jsonResponse(400, { ok: false, code: 'route_required', reason: 'Route is required' });
    }

    if (route === 'getUserSettings') {
      const { data: user } = await service
        .from('users')
        .select('*')
        .eq('id', ctx.userId)
        .maybeSingle();
      return jsonResponse(200, {
        ok: true,
        result: {
          userId: ctx.userId,
          name: user?.display_name ?? ctx.email,
          imageUrl: user?.profile_image_url ?? '',
          role: ctx.role,
          email: ctx.email,
          theme: user?.theme ?? 'system',
          language: user?.language ?? 'ja',
        },
      });
    }

    if (route === 'saveUserSettings') {
      ensureSignedIn(ctx);
      const payload = asMap(args[0]);
      const patch: Record<string, unknown> = {};
      const name = asString(payload.name);
      const theme = asString(payload.theme);
      const language = asString(payload.language);
      const imageUrl = asString(payload.imageUrl);
      if (name) patch.display_name = name;
      if (theme) patch.theme = theme;
      if (language) patch.language = language;
      if (imageUrl) patch.profile_image_url = imageUrl;

      if (Object.keys(patch).length > 0) {
        const { error } = await service.from('users').update(patch).eq('id', ctx.userId);
        if (error) throw error;
      }

      return jsonResponse(200, { ok: true, result: { success: true } });
    }

    ensureSignedIn(ctx);

    if (route === 'getBootstrapData' || route === 'getHomeContent') {
      const [tasks, messages, pendingUsers] = await Promise.all([
        service.from('tasks').select('id', { count: 'exact', head: true }).eq('organization_id', ctx.orgId).in('status', ['open', 'in_progress', 'on_hold']),
        service.from('messages').select('id', { count: 'exact', head: true }).eq('organization_id', ctx.orgId),
        service.from('memberships').select('id', { count: 'exact', head: true }).eq('organization_id', ctx.orgId).eq('status', 'pending'),
      ]);

      return jsonResponse(200, {
        ok: true,
        result: {
          overview: {
            openTaskCount: tasks.count ?? 0,
            unreadMessageCount: messages.count ?? 0,
            pendingUserCount: pendingUsers.count ?? 0,
          },
        },
      });
    }

    if (route === 'listMyTasks') {
      const { data } = await service
        .from('tasks')
        .select(
          'id,title,description,status,priority,due_at,created_at,updated_at,task_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes))',
        )
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (route === 'listCreatedTasks') {
      const { data } = await service
        .from('tasks')
        .select(
          'id,title,description,status,priority,due_at,created_at,updated_at,task_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes))',
        )
        .eq('organization_id', ctx.orgId)
        .eq('created_by_user_id', ctx.userId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (route === 'listAllTasks') {
      ensureManager(ctx);
      const { data } = await service
        .from('tasks')
        .select(
          'id,title,description,status,priority,due_at,created_at,updated_at,task_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes))',
        )
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (route === 'getTaskById') {
      const taskId = asString(args[0]);
      const { data } = await service.from('tasks').select('*').eq('id', taskId).eq('organization_id', ctx.orgId).maybeSingle();
      return jsonResponse(200, { ok: true, result: data ?? {} });
    }

    if (route === 'addNewTask') {
      const payload = asMap(args[0]);
      const title = asString(payload.title);
      if (!title) return jsonResponse(400, { ok: false, code: 'title_required', reason: 'title required' });
      const priority = asString(payload.priority);
      const safePriority = priority === 'low' || priority === 'high' ? priority : 'medium';

      const dueAtMs = Number(payload.dueAtMs ?? 0);
      const { data: inserted, error } = await service
        .from('tasks')
        .insert({
          organization_id: ctx.orgId,
          title,
          description: asString(payload.description),
          created_by_user_id: ctx.userId,
          priority: safePriority,
          due_at: Number.isFinite(dueAtMs) && dueAtMs > 0 ? new Date(dueAtMs).toISOString() : null,
        })
        .select('*')
        .single();
      if (error) throw error;

      const assignees = asList(payload.assigneeUserIds)
        .map((v) => asString(v))
        .filter((v) => v.length > 0);
      const targetUsers = assignees.length > 0 ? assignees : [ctx.userId];

      for (const userId of targetUsers) {
        await service.from('task_assignees').upsert({
          task_id: inserted.id,
          user_id: userId,
        });
      }

      await enqueueDispatch('new_task_assigned', ctx.orgId, inserted.id, targetUsers);
      await dispatchQueuedNotifications({
        sourceId: inserted.id,
        eventType: 'new_task_assigned',
      }).catch(() => undefined);
      await insertAuditLog('task.create', ctx, 'task', inserted.id, { title });
      return jsonResponse(200, { ok: true, result: inserted });
    }

    if (route === 'updateTask') {
      const payload = asMap(args[0]);
      const taskId = asString(payload.taskId);
      const patch: Record<string, unknown> = {};
      const title = asString(payload.title);
      const description = asString(payload.description);
      const status = asString(payload.status);
      if (title) patch.title = title;
      if (description) patch.description = description;
      if (status) patch.status = status;
      if (Object.keys(patch).length === 0) return jsonResponse(200, { ok: true, result: {} });

      const { data, error } = await service
        .from('tasks')
        .update(patch)
        .eq('id', taskId)
        .eq('organization_id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('task.update', ctx, 'task', taskId, patch);
      return jsonResponse(200, { ok: true, result: data });
    }

    if (route === 'completeTask') {
      const taskId = asString(args[0]);
      const { data, error } = await service
        .from('tasks')
        .update({ status: 'completed' })
        .eq('id', taskId)
        .eq('organization_id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('task.complete', ctx, 'task', taskId, {});
      return jsonResponse(200, { ok: true, result: data });
    }

    if (route === 'deleteTaskById') {
      const taskId = asString(args[0]);
      await service.from('tasks').delete().eq('id', taskId).eq('organization_id', ctx.orgId);
      await insertAuditLog('task.delete', ctx, 'task', taskId, {});
      return jsonResponse(200, { ok: true, result: { deleted: true } });
    }

    if (route === 'getMessages') {
      const payload = asMap(args[0]);
      const folderId = asString(payload.folderId);
      const unreadOnly = asBool(payload.unreadOnly);
      let query = service
        .from('messages')
        .select('id,title,body,priority,is_pinned,folder_id,created_at,updated_at')
        .eq('organization_id', ctx.orgId)
        .order('is_pinned', { ascending: false })
        .order('created_at', { ascending: false });
      if (folderId) query = query.eq('folder_id', folderId);
      const { data } = await query;
      const messages = data ?? [];

      if (messages.length === 0) {
        return jsonResponse(200, { ok: true, result: [] });
      }

      const messageIds = messages.map((row) => row.id).filter((id) => !!id);
      const { data: readRows } = await service
        .from('message_reads')
        .select('message_id')
        .eq('membership_id', ctx.membershipId)
        .in('message_id', messageIds);
      const readMessageIds = new Set((readRows ?? []).map((row) => row.message_id));

      const mapped = messages
        .map((row) => {
          const isRead = readMessageIds.has(row.id);
          return {
            ...row,
            isRead,
          };
        })
        .filter((row) => (unreadOnly ? !row.isRead : true));

      return jsonResponse(200, { ok: true, result: mapped });
    }

    if (route === 'getMessageById') {
      const messageId = asString(args[0]);
      const { data: message } = await service
        .from('messages')
        .select('*')
        .eq('organization_id', ctx.orgId)
        .eq('id', messageId)
        .maybeSingle();
      const { data: comments } = await service
        .from('message_comments')
        .select('*')
        .eq('organization_id', ctx.orgId)
        .eq('message_id', messageId)
        .order('created_at', { ascending: true });
      return jsonResponse(200, {
        ok: true,
        result: {
          ...(message ?? {}),
          comments: comments ?? [],
        },
      });
    }

    if (route === 'addNewMessage') {
      const payload = asMap(args[0]);
      const title = asString(payload.title);
      const bodyText = asString(payload.body);
      if (!title) return jsonResponse(400, { ok: false, code: 'title_required', reason: 'title required' });

      const { data: message, error } = await service
        .from('messages')
        .insert({
          organization_id: ctx.orgId,
          folder_id: asString(payload.folderId) || null,
          author_membership_id: ctx.membershipId,
          title,
          body: bodyText,
        })
        .select('*')
        .single();
      if (error) throw error;

      const { data: targetUsers } = await service
        .from('memberships')
        .select('user_id')
        .eq('organization_id', ctx.orgId)
        .eq('status', 'active');

      await enqueueDispatch(
        'new_message',
        ctx.orgId,
        message.id,
        (targetUsers ?? [])
          .map((x) => x.user_id)
          .filter((userId) => userId && userId !== ctx.userId),
      );
      await dispatchQueuedNotifications({
        sourceId: message.id,
        eventType: 'new_message',
      }).catch(() => undefined);

      await insertAuditLog('message.create', ctx, 'message', message.id, { title });
      return jsonResponse(200, { ok: true, result: message });
    }

    if (route === 'deleteMessageById') {
      const messageId = asString(args[0]);
      await service.from('messages').delete().eq('id', messageId).eq('organization_id', ctx.orgId);
      await insertAuditLog('message.delete', ctx, 'message', messageId, {});
      return jsonResponse(200, { ok: true, result: { deleted: true } });
    }

    if (route === 'addNewComment') {
      const payload = asMap(args[0]);
      const messageId = asString(payload.messageId);
      const commentBody = asString(payload.body);
      if (!messageId || !commentBody) {
        return jsonResponse(400, { ok: false, code: 'invalid_input', reason: 'messageId/body required' });
      }
      const { data: inserted, error } = await service
        .from('message_comments')
        .insert({
          message_id: messageId,
          organization_id: ctx.orgId,
          membership_id: ctx.membershipId,
          author_email: ctx.email,
          author_display_name: ctx.email,
          body: commentBody,
        })
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('message.comment', ctx, 'message', messageId, { commentId: inserted.id });
      return jsonResponse(200, { ok: true, result: inserted });
    }

    if (route === 'toggleMemoRead' || route === 'markMemoAsRead') {
      const messageId = asString(args[0]);
      const { data: existingMembership } = await service
        .from('memberships')
        .select('id')
        .eq('organization_id', ctx.orgId)
        .eq('user_id', ctx.userId)
        .eq('status', 'active')
        .maybeSingle();
      if (!existingMembership) {
        return jsonResponse(403, { ok: false, code: 'membership_missing', reason: 'membership missing' });
      }

      if (route === 'toggleMemoRead') {
        const { data: existingRead } = await service
          .from('message_reads')
          .select('id')
          .eq('message_id', messageId)
          .eq('membership_id', existingMembership.id)
          .maybeSingle();
        if (existingRead) {
          await service.from('message_reads').delete().eq('id', existingRead.id);
          return jsonResponse(200, { ok: true, result: { isRead: false } });
        }
      }

      await service.from('message_reads').upsert({
        message_id: messageId,
        membership_id: existingMembership.id,
        read_at: new Date().toISOString(),
      });
      return jsonResponse(200, { ok: true, result: { isRead: true } });
    }

    if (route === 'markMemosReadBulk') {
      const messageIds = asList(args[0]).map((x) => asString(x)).filter((x) => x);
      const { data: existingMembership } = await service
        .from('memberships')
        .select('id')
        .eq('organization_id', ctx.orgId)
        .eq('user_id', ctx.userId)
        .eq('status', 'active')
        .maybeSingle();
      if (!existingMembership) {
        return jsonResponse(403, { ok: false, code: 'membership_missing', reason: 'membership missing' });
      }
      for (const messageId of messageIds) {
        await service.from('message_reads').upsert({
          message_id: messageId,
          membership_id: existingMembership.id,
          read_at: new Date().toISOString(),
        });
      }
      return jsonResponse(200, { ok: true, result: { updated: messageIds.length } });
    }

    if (route === 'listActiveFolders' || (segments[0] === 'folders' && route === 'folders')) {
      const { data } = await service
        .from('folders')
        .select('*')
        .eq('organization_id', ctx.orgId)
        .eq('is_active', true)
        .order('sort_order', { ascending: true });
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (segments[0] === 'folders' && segments.length === 1 && method === 'POST') {
      ensureManager(ctx);
      const name = asString(body.name);
      if (!name) return jsonResponse(400, { ok: false, code: 'name_required', reason: 'folder name required' });
      const { data: inserted, error } = await service
        .from('folders')
        .insert({
          organization_id: ctx.orgId,
          name,
          color: asString(body.color) || null,
          is_public: Boolean(body.isPublic ?? true),
        })
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('folder.create', ctx, 'folder', inserted.id, { name });
      return jsonResponse(201, { ok: true, result: inserted });
    }

    if (segments[0] === 'folders' && segments.length === 2 && method === 'PATCH') {
      ensureManager(ctx);
      const folderId = segments[1];
      const patch: Record<string, unknown> = {};
      const name = asString(body.name);
      if (name) patch.name = name;
      if (body.color !== undefined) patch.color = asString(body.color) || null;
      if (body.isPublic !== undefined) patch.is_public = Boolean(body.isPublic);
      if (body.isActive !== undefined) patch.is_active = Boolean(body.isActive);
      const { data, error } = await service
        .from('folders')
        .update(patch)
        .eq('id', folderId)
        .eq('organization_id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('folder.update', ctx, 'folder', folderId, patch as Record<string, unknown>);
      return jsonResponse(200, { ok: true, result: data });
    }

    if (segments[0] === 'folders' && segments.length === 2 && method === 'DELETE') {
      ensureManager(ctx);
      const folderId = segments[1];
      const { data, error } = await service
        .from('folders')
        .update({ is_active: false, archived_at: new Date().toISOString() })
        .eq('id', folderId)
        .eq('organization_id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('folder.archive', ctx, 'folder', folderId, {});
      return jsonResponse(200, { ok: true, result: data });
    }

    if (segments[0] === 'templates' && segments.length === 1 && (route === 'templates')) {
      if (method === 'GET') {
        const folderId = asString(body.folderId ?? args[0]);
        let query = service
          .from('templates')
          .select('*')
          .eq('organization_id', ctx.orgId)
          .order('updated_at', { ascending: false });
        if (folderId) query = query.eq('folder_id', folderId);
        const { data } = await query;
        return jsonResponse(200, { ok: true, result: data ?? [] });
      }

      if (method === 'POST') {
        ensureManager(ctx);
        const folderId = asString(body.folderId);
        const name = asString(body.name);
        if (!folderId || !name) {
          return jsonResponse(400, { ok: false, code: 'invalid_input', reason: 'folderId/name required' });
        }
        const { data, error } = await service
          .from('templates')
          .insert({
            organization_id: ctx.orgId,
            folder_id: folderId,
            name,
            title_format: asString(body.titleFormat),
            body_format: asString(body.bodyFormat),
          })
          .select('*')
          .single();
        if (error) throw error;
        await insertAuditLog('template.create', ctx, 'template', data.id, { folderId, name });
        return jsonResponse(201, { ok: true, result: data });
      }
    }

    if (route === 'listActiveUsers') {
      ensureManager(ctx);
      const { data } = await service
        .from('memberships')
        .select('id,user_id,role,status,users(id,email,display_name)')
        .eq('organization_id', ctx.orgId)
        .eq('status', 'active');
      const mapped = (data ?? []).map((row) => ({
        membershipId: row.id,
        userId: row.user_id,
        role: row.role,
        status: row.status,
        email: row.users?.email ?? '',
        displayName: row.users?.display_name ?? row.users?.email ?? '',
      }));
      return jsonResponse(200, { ok: true, result: mapped });
    }

    if (route === 'adminListUsers') {
      ensureManager(ctx);
      const { data } = await service
        .from('memberships')
        .select('id,organization_id,user_id,role,status,users(id,email,display_name,created_at)')
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      const rows = (data ?? []).map((row) => ({
        membershipId: row.id,
        userId: row.user_id,
        email: row.users?.email ?? '',
        displayName: row.users?.display_name ?? row.users?.email ?? '',
        role: row.role,
        status: row.status,
        createdAt: row.users?.created_at ?? null,
      }));
      return jsonResponse(200, { ok: true, result: { rows } });
    }

    if (route === 'adminUpdateUser') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const email = asString(payload.email).toLowerCase();
      const targetRole = asString(payload.role);
      const targetStatus = asString(payload.status);

      const { data: targetUser } = await service.from('users').select('*').eq('email', email).maybeSingle();
      if (!targetUser) {
        return jsonResponse(404, { ok: false, code: 'user_not_found', reason: 'user not found' });
      }

      if (targetStatus) {
        await service
          .from('memberships')
          .update({ status: targetStatus })
          .eq('organization_id', ctx.orgId)
          .eq('user_id', targetUser.id);
        await service
          .from('users')
          .update({
            status: targetStatus,
            is_active: targetStatus === 'active',
            approved_by: ctx.email,
            approved_at: targetStatus === 'active' ? new Date().toISOString() : null,
          })
          .eq('id', targetUser.id);
      }

      if (targetRole) {
        await service
          .from('memberships')
          .update({ role: targetRole })
          .eq('organization_id', ctx.orgId)
          .eq('user_id', targetUser.id);
      }

      await insertAuditLog('admin.user.update', ctx, 'user', targetUser.id, {
        role: targetRole,
        status: targetStatus,
      });

      return jsonResponse(200, { ok: true, result: { success: true } });
    }

    if (route === 'adminListOrganizations') {
      ensureManager(ctx);
      const { data } = await service
        .from('organizations')
        .select('*')
        .eq('id', ctx.orgId);
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (route === 'adminGetOrganization') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const orgId = asString(payload.orgId) || ctx.orgId;
      const { data } = await service.from('organizations').select('*').eq('id', orgId).maybeSingle();
      return jsonResponse(200, { ok: true, result: data ?? {} });
    }

    if (route === 'adminUpdateOrganization') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const name = asString(payload.name);
      if (!name) {
        return jsonResponse(400, { ok: false, code: 'name_required', reason: 'name required' });
      }
      const patch = {
        name,
        short_name: asString(payload.shortName) || null,
        display_color: asString(payload.displayColor) || null,
        timezone: asString(payload.timezone) || 'Asia/Tokyo',
        notification_email: asString(payload.notificationEmail) || null,
      };
      const { data, error } = await service
        .from('organizations')
        .update(patch)
        .eq('id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('admin.organization.update', ctx, 'organization', ctx.orgId, patch);
      return jsonResponse(200, { ok: true, result: data });
    }

    if (route === 'getAuditLogs') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const limit = Number(payload.limit ?? 100);
      const { data } = await service
        .from('audit_logs')
        .select('*')
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false })
        .limit(Number.isFinite(limit) ? Math.min(limit, 500) : 100);
      return jsonResponse(200, { ok: true, result: { rows: data ?? [] } });
    }

    if (route === 'downloadAttachment') {
      const attachmentId = asString(args[0]);
      const { data: attachment } = await service
        .from('attachments')
        .select('*')
        .eq('id', attachmentId)
        .eq('organization_id', ctx.orgId)
        .maybeSingle();
      if (!attachment) {
        return jsonResponse(404, { ok: false, code: 'attachment_not_found', reason: 'not found' });
      }
      const storagePath = asString(attachment.storage_path);
      const [bucket, ...rest] = storagePath.split('/').filter((x) => x.length > 0);
      if (!bucket || rest.length === 0) {
        return jsonResponse(400, { ok: false, code: 'invalid_storage_path', reason: 'invalid path' });
      }
      const objectPath = rest.join('/');
      const { data: signed } = await service.storage.from(bucket).createSignedUrl(objectPath, 300);
      return jsonResponse(200, {
        ok: true,
        result: {
          url: signed?.signedUrl ?? '',
          path: storagePath,
        },
      });
    }

    if (segments[0] === 'messages' && segments.length === 3 && segments[2] === 'pin') {
      ensureManager(ctx);
      const messageId = segments[1];
      const { data: current } = await service
        .from('messages')
        .select('id,is_pinned')
        .eq('organization_id', ctx.orgId)
        .eq('id', messageId)
        .maybeSingle();
      if (!current) {
        return jsonResponse(404, { ok: false, code: 'message_not_found', reason: 'not found' });
      }
      const { data } = await service
        .from('messages')
        .update({ is_pinned: !current.is_pinned })
        .eq('id', messageId)
        .eq('organization_id', ctx.orgId)
        .select('id,is_pinned')
        .single();
      await insertAuditLog('message.pin.toggle', ctx, 'message', messageId, { isPinned: data.is_pinned });
      return jsonResponse(200, { ok: true, result: data });
    }

    if (segments[0] === 'messages' && segments.length === 3 && segments[2] === 'read_status') {
      ensureManager(ctx);
      const messageId = segments[1];
      const { data: message } = await service
        .from('messages')
        .select('id,organization_id')
        .eq('id', messageId)
        .eq('organization_id', ctx.orgId)
        .maybeSingle();
      if (!message) return jsonResponse(404, { ok: false, code: 'message_not_found', reason: 'not found' });

      const { data: reads } = await service
        .from('message_reads')
        .select('membership_id,memberships(user_id,users(email,display_name))')
        .eq('message_id', messageId);
      const { data: members } = await service
        .from('memberships')
        .select('id,user_id,users(email,display_name)')
        .eq('organization_id', ctx.orgId)
        .eq('status', 'active');

      const readUserIds = new Set((reads ?? []).map((r) => r.memberships?.user_id).filter(Boolean));
      const readUsers = (reads ?? []).map((r) => ({
        userId: r.memberships?.user_id,
        email: r.memberships?.users?.email ?? '',
        displayName: r.memberships?.users?.display_name ?? '',
      }));
      const unreadUsers = (members ?? [])
        .filter((m) => !readUserIds.has(m.user_id))
        .map((m) => ({
          userId: m.user_id,
          email: m.users?.email ?? '',
          displayName: m.users?.display_name ?? '',
        }));

      return jsonResponse(200, {
        ok: true,
        result: {
          messageId,
          readUsers,
          unreadUsers,
        },
      });
    }

    return jsonResponse(501, {
      ok: false,
      code: 'route_not_implemented',
      reason: `Route not implemented: ${route}`,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = message === 'forbidden' || message === 'access_denied' ? 403 : 500;
    return jsonResponse(status, {
      ok: false,
      code: message,
      reason: message,
    });
  }
});
