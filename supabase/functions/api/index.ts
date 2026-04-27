import { createServiceClient } from '../_shared/supabase.ts';
import { corsHeaders, decodeJwtPayload, jsonResponse, readBearerToken } from '../_shared/cors.ts';
import { dispatchQueuedNotifications } from '../_shared/notification_dispatch.ts';

type AccessContext = {
  userId: string;
  email: string;
  orgId: string;
  role: 'owner' | 'admin' | 'member' | 'guest';
  membershipId: string;
  membershipStatus: 'pending' | 'active' | 'suspended' | 'revoked' | 'unaffiliated';
  unitRole: 'manager' | 'member' | 'none';
  currentOrganizationId: string;
  currentUnitId: string;
};

function isManagerRole(role: string): boolean {
  return role === 'owner' || role === 'admin';
}

function isMemberRole(role: string): boolean {
  return role === 'owner' || role === 'admin' || role === 'member';
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

function firstRelation<T>(value: T | T[] | null | undefined): T | undefined {
  if (Array.isArray(value)) {
    return value[0];
  }
  return value ?? undefined;
}

function mapLegacyRole(role: string): 'owner' | 'admin' | 'member' | 'guest' {
  if (role === 'owner' || role === 'admin' || role === 'member') {
    return role;
  }
  if (role === 'manager') {
    return 'admin';
  }
  return 'guest';
}

function isActiveMembership(status: string): boolean {
  return status === 'active';
}

function canUseApplication(ctx: AccessContext): boolean {
  return !!ctx.userId && !!ctx.orgId && isMemberRole(ctx.role) && ctx.membershipStatus === 'active';
}

type UnitRow = {
  id: string;
  organization_id: string;
  parent_unit_id: string | null;
  name: string;
  path_text?: string | null;
  is_active?: boolean;
  sort_order?: number | null;
};

type UnitAccessContext = {
  units: UnitRow[];
  directUnitRoles: Map<string, 'manager' | 'member'>;
  accessibleUnitIds: Set<string>;
};

function getAncestorUnitIds(units: UnitRow[], startUnitId: string): string[] {
  const byId = new Map(units.map((unit) => [unit.id, unit]));
  const result: string[] = [];
  let cursor = byId.get(startUnitId) ?? null;
  while (cursor) {
    result.push(cursor.id);
    cursor = cursor.parent_unit_id ? byId.get(cursor.parent_unit_id) ?? null : null;
  }
  return result;
}

function getDescendantUnitIds(units: UnitRow[], startUnitId: string): string[] {
  const childrenByParent = new Map<string, string[]>();
  for (const unit of units) {
    if (!unit.parent_unit_id) continue;
    const list = childrenByParent.get(unit.parent_unit_id) ?? [];
    list.push(unit.id);
    childrenByParent.set(unit.parent_unit_id, list);
  }
  const visited = new Set<string>();
  const queue = [startUnitId];
  while (queue.length > 0) {
    const next = queue.shift()!;
    if (visited.has(next)) continue;
    visited.add(next);
    const children = childrenByParent.get(next) ?? [];
    queue.push(...children);
  }
  return Array.from(visited);
}

function buildDirectUnitRoleMap(
  unitMemberships: Array<Record<string, unknown>>,
): Map<string, 'manager' | 'member'> {
  const roles = new Map<string, 'manager' | 'member'>();
  for (const row of unitMemberships) {
    const unitId = asString(row.unit_id);
    if (!unitId) continue;
    roles.set(unitId, asString(row.role) === 'manager' ? 'manager' : 'member');
  }
  return roles;
}

function buildAccessibleUnitIds(
  units: UnitRow[],
  unitMemberships: Array<Record<string, unknown>>,
  role: AccessContext['role'],
): Set<string> {
  if (role === 'owner' || role === 'admin') {
    return new Set(units.map((unit) => unit.id));
  }

  const accessible = new Set<string>();
  for (const [unitId, unitRole] of buildDirectUnitRoleMap(unitMemberships).entries()) {
    if (unitRole === 'manager') {
      for (const descendantId of getDescendantUnitIds(units, unitId)) {
        accessible.add(descendantId);
      }
    } else {
      accessible.add(unitId);
    }
  }
  return accessible;
}

async function loadUnitAccessContext(
  service: ReturnType<typeof createServiceClient>,
  ctx: Pick<AccessContext, 'orgId' | 'role' | 'userId'>,
): Promise<UnitAccessContext> {
  if (!ctx.orgId) {
    return { units: [], directUnitRoles: new Map(), accessibleUnitIds: new Set() };
  }

  const { data: unitsData } = await service
    .from('units')
    .select('id,organization_id,parent_unit_id,name,path_text,is_active,sort_order')
    .eq('organization_id', ctx.orgId)
    .eq('is_active', true)
    .order('sort_order', { ascending: true });
  const units = (unitsData ?? []) as UnitRow[];

  if (ctx.role === 'owner' || ctx.role === 'admin') {
    return {
      units,
      directUnitRoles: new Map(),
      accessibleUnitIds: new Set(units.map((unit) => unit.id)),
    };
  }

  const { data: unitMembershipsData } = await service
    .from('unit_memberships')
    .select('unit_id,role,status')
    .eq('user_id', ctx.userId)
    .eq('status', 'active');
  const unitMemberships = (unitMembershipsData ?? []) as Array<Record<string, unknown>>;

  return {
    units,
    directUnitRoles: buildDirectUnitRoleMap(unitMemberships),
    accessibleUnitIds: buildAccessibleUnitIds(units, unitMemberships, ctx.role),
  };
}

function filterAccessibleUnits(units: UnitRow[], accessibleUnitIds: Set<string>): UnitRow[] {
  return units.filter((unit) => accessibleUnitIds.has(unit.id));
}

function ensureUnitAccessible(access: UnitAccessContext, unitId: string): string {
  if (!unitId || !access.accessibleUnitIds.has(unitId)) {
    throw new Error('unit_forbidden');
  }
  return unitId;
}

function isSharedResourceAccessible(access: UnitAccessContext, unitId: string): boolean {
  if (!unitId) return true;
  return access.accessibleUnitIds.has(unitId);
}

async function resolveCurrentUnitId(
  service: ReturnType<typeof createServiceClient>,
  userId: string,
  orgId: string,
  accessibleUnitIds: Set<string>,
  units: UnitRow[],
): Promise<string> {
  if (!userId || !orgId || accessibleUnitIds.size === 0) return '';

  const { data: userRow } = await service
    .from('users')
    .select('current_unit_id')
    .eq('id', userId)
    .maybeSingle();

  const preferredUnitId = asString(userRow?.current_unit_id);
  if (preferredUnitId && accessibleUnitIds.has(preferredUnitId)) {
    return preferredUnitId;
  }
  return filterAccessibleUnits(units, accessibleUnitIds)[0]?.id ?? '';
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

  const activeMemberships = (memberships ?? []).filter((membership) => membership.status === 'active');
  const pendingMemberships = (memberships ?? []).filter((membership) => membership.status === 'pending');

  const selectedMembership = activeMemberships[0] ?? pendingMemberships[0] ?? (memberships ?? [])[0] ?? null;

  if (!selectedMembership) {
    return {
      userId: user.id,
      email: user.email,
      orgId: '',
      role: 'guest',
      membershipId: '',
      membershipStatus: 'unaffiliated',
      unitRole: 'none',
      currentOrganizationId: '',
      currentUnitId: '',
    };
  }

  const resolvedRole = mapLegacyRole(asString(selectedMembership.organization_role) || asString(selectedMembership.role));
  const currentOrganizationId = asString(user.current_organization_id) || asString(selectedMembership.organization_id);
  const activeOrgId = activeMemberships.find((membership) => membership.organization_id === currentOrganizationId)?.organization_id
    ?? activeMemberships[0]?.organization_id
    ?? '';
  const effectiveOrgId = activeOrgId || (selectedMembership.status === 'active' ? asString(selectedMembership.organization_id) : '');
  let currentUnitId = '';
  let directUnitRoles = new Map<string, 'manager' | 'member'>();
  if (effectiveOrgId) {
    const access = await loadUnitAccessContext(service, {
      orgId: effectiveOrgId,
      role: resolvedRole,
      userId: user.id,
    });
    directUnitRoles = access.directUnitRoles;
    currentUnitId = await resolveCurrentUnitId(
      service,
      user.id,
      effectiveOrgId,
      access.accessibleUnitIds,
      access.units,
    );
  }

  let unitRole: 'manager' | 'member' | 'none' = 'none';
  if (currentUnitId) {
    unitRole = directUnitRoles.get(currentUnitId) ?? 'none';
  }

  return {
    userId: user.id,
    email: user.email,
    orgId: effectiveOrgId,
    role: resolvedRole,
    membershipId: asString(selectedMembership.id),
    membershipStatus: selectedMembership.status ?? 'unaffiliated',
    unitRole,
    currentOrganizationId: activeOrgId,
    currentUnitId,
  };
}

function ensureSignedIn(ctx: AccessContext) {
  if (!canUseApplication(ctx)) {
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
  eventType:
    | 'new_message'
    | 'new_direct_message'
    | 'new_task_assigned'
    | 'task_due_tomorrow'
    | 'join_request_approved'
    | 'organization_invite_accepted',
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

async function loadBootstrapPayload(
  service: ReturnType<typeof createServiceClient>,
  ctx: AccessContext,
) {
  const { data: currentUser } = await service
    .from('users')
    .select('id,email,display_name,profile_image_url,current_organization_id,current_unit_id')
    .eq('id', ctx.userId)
    .maybeSingle();

  const { data: memberships } = await service
    .from('memberships')
    .select('id,organization_id,status,role,organization_role,organizations(id,name,short_name,display_color,organization_code)')
    .eq('user_id', ctx.userId)
    .order('created_at', { ascending: true });

  const availableOrganizations = (memberships ?? []).map((membership) => {
    const organization = firstRelation(membership.organizations);
    return {
      membershipId: membership.id,
      organizationId: membership.organization_id,
      status: membership.status,
      role: mapLegacyRole(asString(membership.organization_role) || asString(membership.role)),
      isCurrent: membership.organization_id === ctx.currentOrganizationId,
      organization: {
        id: organization?.id ?? membership.organization_id,
        name: organization?.name ?? '',
        shortName: organization?.short_name ?? '',
        displayColor: organization?.display_color ?? '',
        organizationCode: organization?.organization_code ?? '',
      },
    };
  });

  const currentOrganization = availableOrganizations.find((item) => item.organizationId === ctx.currentOrganizationId)
    ?? availableOrganizations.find((item) => item.status === 'active')
    ?? null;

  let units: UnitRow[] = [];
  let directUnitRoles = new Map<string, 'manager' | 'member'>();
  let currentUnit: Record<string, unknown> | null = null;
  let badges = {
    allUnreadMessages: 0,
    currentUnitUnreadMessages: 0,
    openTasks: 0,
    pendingJoinRequests: 0,
  };

  if (ctx.orgId) {
    const access = await loadUnitAccessContext(service, ctx);
    const [taskRows, pendingRequestsCount] = await Promise.all([
      service
        .from('tasks')
        .select('id,unit_id,status')
        .eq('organization_id', ctx.orgId)
        .in('status', ['open', 'in_progress', 'on_hold']),
      isManagerRole(ctx.role)
        ? service
          .from('join_requests')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', ctx.orgId)
          .eq('status', 'pending')
        : Promise.resolve({ count: 0 }),
    ]);

    units = filterAccessibleUnits(access.units, access.accessibleUnitIds);
    directUnitRoles = access.directUnitRoles;
    const currentUnitId = (ctx.currentUnitId && access.accessibleUnitIds.has(ctx.currentUnitId))
      ? ctx.currentUnitId
      : (units[0]?.id ?? '');
    currentUnit = units.find((unit) => unit.id === currentUnitId) ?? null;

    const scopedUnitIds = currentUnitId
      ? getDescendantUnitIds(access.units, currentUnitId).filter((unitId) => access.accessibleUnitIds.has(unitId))
      : [];

    const unreadBaseQuery = service
      .from('messages')
      .select('id,unit_id,message_scope,author_user_id,recipient_user_id')
      .eq('organization_id', ctx.orgId);
    const { data: unreadCandidates } = await unreadBaseQuery;
    const rows = (unreadCandidates ?? []).filter((row) => {
      const scope = asString(row.message_scope) || 'shared';
      if (scope === 'direct') {
        return row.author_user_id === ctx.userId || row.recipient_user_id === ctx.userId;
      }
      return isSharedResourceAccessible(access, asString(row.unit_id))
        && (scopedUnitIds.length === 0 || scopedUnitIds.includes(asString(row.unit_id)));
    });
    const messageIds = rows.map((row) => row.id).filter(Boolean);

    const { data: readRows } = await service
      .from('message_reads')
      .select('message_id,membership_id,user_id')
      .in('message_id', messageIds.length > 0 ? messageIds : ['00000000-0000-0000-0000-000000000000']);

    const readSharedIds = new Set(
      (readRows ?? [])
        .filter((row) => row.membership_id === ctx.membershipId)
        .map((row) => row.message_id),
    );
    const readDirectIds = new Set(
      (readRows ?? [])
        .filter((row) => row.user_id === ctx.userId)
        .map((row) => row.message_id),
    );

    const unreadAll = rows.filter((row) => {
      const scope = asString(row.message_scope) || 'shared';
      return scope === 'direct' ? !readDirectIds.has(row.id) : !readSharedIds.has(row.id);
    });
    const unreadCurrentUnit = unreadAll.filter((row) => {
      const scope = asString(row.message_scope) || 'shared';
      if (scope === 'direct') return true;
      return currentUnitId ? row.unit_id === currentUnitId : true;
    });

    badges = {
      allUnreadMessages: unreadAll.length,
      currentUnitUnreadMessages: unreadCurrentUnit.length,
      openTasks: (taskRows.data ?? []).filter((row) => isSharedResourceAccessible(access, asString(row.unit_id))).length,
      pendingJoinRequests: pendingRequestsCount.count ?? 0,
    };
  }

  const availableUnits = units.map((unit) => {
    return {
      id: unit.id,
      name: unit.name,
      pathText: unit.path_text ?? unit.name,
      parentUnitId: unit.parent_unit_id,
      isCurrent: unit.id === asString(currentUnit?.id),
      role: ctx.role === 'owner' || ctx.role === 'admin'
        ? 'manager'
        : (directUnitRoles.get(unit.id) ?? 'none'),
    };
  });

  return {
    user: {
      userId: ctx.userId,
      email: ctx.email,
      displayName: currentUser?.display_name ?? ctx.email,
      profileImageUrl: currentUser?.profile_image_url ?? '',
    },
    participation: {
      status: ctx.membershipStatus,
      organizationRole: ctx.role,
      unitRole: ctx.unitRole,
      membershipId: ctx.membershipId,
      canUseApp: canUseApplication(ctx),
    },
    currentOrganization: currentOrganization?.organization ?? null,
    currentUnit,
    availableOrganizations,
    availableUnits,
    navigation: {
      home: canUseApplication(ctx),
      tasks: canUseApplication(ctx),
      messages: canUseApplication(ctx),
      admin: isManagerRole(ctx.role) || ctx.unitRole === 'manager',
      settings: true,
    },
    badges,
    overview: {
      openTaskCount: badges.openTasks,
      unreadMessageCount: badges.allUnreadMessages,
      pendingUserCount: badges.pendingJoinRequests,
    },
  };
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
          organizationRole: ctx.role,
          unitRole: ctx.unitRole,
          participationStatus: ctx.membershipStatus,
          currentOrganizationId: ctx.currentOrganizationId,
          currentUnitId: ctx.currentUnitId,
          email: ctx.email,
          theme: user?.theme ?? 'system',
          language: user?.language ?? 'ja',
        },
      });
    }

    if (route === 'saveUserSettings') {
      const payload = asMap(args[0]);
      const patch: Record<string, unknown> = {};
      const name = asString(payload.name);
      const theme = asString(payload.theme);
      const language = asString(payload.language);
      const imageUrl = asString(payload.imageUrl);
      const currentOrganizationId = asString(payload.currentOrganizationId);
      const currentUnitId = asString(payload.currentUnitId);
      if (name) patch.display_name = name;
      if (theme) patch.theme = theme;
      if (language) patch.language = language;
      if (imageUrl) patch.profile_image_url = imageUrl;
      if (currentOrganizationId) patch.current_organization_id = currentOrganizationId;
      if (currentUnitId) patch.current_unit_id = currentUnitId;
      if (currentOrganizationId || currentUnitId) patch.last_context_changed_at = new Date().toISOString();

      if (Object.keys(patch).length > 0) {
        const { error } = await service.from('users').update(patch).eq('id', ctx.userId);
        if (error) throw error;
      }

      return jsonResponse(200, { ok: true, result: { success: true } });
    }

    if (route === 'getBootstrapData' || route === 'getHomeContent') {
      const bootstrap = await loadBootstrapPayload(service, ctx);
      if (route === 'getBootstrapData') {
        return jsonResponse(200, { ok: true, result: bootstrap });
      }

      if (!canUseApplication(ctx)) {
        return jsonResponse(200, {
          ok: true,
          result: {
            ...bootstrap,
            blocks: [],
          },
        });
      }

      const currentUnitId = asString(bootstrap.currentUnit?.id);
      const [taskRows, messageRows, folderRows, unitRows] = await Promise.all([
        service
          .from('tasks')
          .select('id,title,status,priority,due_at,unit_id,created_at')
          .eq('organization_id', ctx.orgId)
          .order('created_at', { ascending: false })
          .limit(5),
        service
          .from('messages')
          .select('id,title,body,is_pinned,created_at,unit_id,message_scope,recipient_user_id,author_user_id')
          .eq('organization_id', ctx.orgId)
          .order('is_pinned', { ascending: false })
          .order('created_at', { ascending: false })
          .limit(8),
        service
          .from('folders')
          .select('id,name,unit_id,is_public,is_active')
          .eq('organization_id', ctx.orgId)
          .eq('is_active', true)
          .order('sort_order', { ascending: true })
          .limit(8),
        service
          .from('units')
          .select('id,name,parent_unit_id,path_text')
          .eq('organization_id', ctx.orgId)
          .eq('is_active', true)
          .order('sort_order', { ascending: true }),
      ]);

      const units = (unitRows.data ?? []) as UnitRow[];
      const homeMessages = (messageRows.data ?? []).filter((row) => {
        const scope = asString(row.message_scope) || 'shared';
        if (scope === 'direct') {
          return row.author_user_id === ctx.userId || row.recipient_user_id === ctx.userId;
        }
        return currentUnitId ? getDescendantUnitIds(units, currentUnitId).includes(asString(row.unit_id)) : true;
      });
      return jsonResponse(200, {
        ok: true,
        result: {
          ...bootstrap,
          blocks: {
            tasks: taskRows.data ?? [],
            messages: homeMessages,
            folders: folderRows.data ?? [],
            units: units,
            adminSummary: bootstrap.overview,
          },
        },
      });
    }

    if (route === 'searchOrganizationsByCode') {
      const payload = asMap(args[0]);
      const query = asString(payload.keyword);
      if (!query) {
        return jsonResponse(200, { ok: true, result: [] });
      }
      const { data } = await service
        .from('organizations')
        .select('id,name,short_name,display_color,organization_code')
        .or(`organization_code.ilike.%${query}%,name.ilike.%${query}%,short_name.ilike.%${query}%`)
        .limit(20);
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (route === 'requestOrganizationJoin') {
      const payload = asMap(args[0]);
      const organizationId = asString(payload.organizationId);
      const requestMessage = asString(payload.requestMessage);
      const requestedCode = asString(payload.organizationCode);
      if (!organizationId) {
        return jsonResponse(400, { ok: false, code: 'organization_required', reason: 'organization required' });
      }
      const { data, error } = await service
        .from('join_requests')
        .upsert({
          organization_id: organizationId,
          user_id: ctx.userId,
          requested_code: requestedCode || null,
          request_message: requestMessage || null,
          status: 'pending',
          reviewed_by_membership_id: null,
          reviewed_at: null,
        }, { onConflict: 'organization_id,user_id' })
        .select('*')
        .single();
      if (error) throw error;
      return jsonResponse(200, { ok: true, result: data });
    }

    if (route === 'acceptOrganizationInvite') {
      const payload = asMap(args[0]);
      const inviteToken = asString(payload.inviteToken);
      if (!inviteToken) {
        return jsonResponse(400, { ok: false, code: 'invite_token_required', reason: 'invite token required' });
      }
      const { data: invite } = await service
        .from('organization_invites')
        .select('*')
        .eq('invite_token', inviteToken)
        .is('revoked_at', null)
        .is('accepted_at', null)
        .maybeSingle();
      if (!invite) {
        return jsonResponse(404, { ok: false, code: 'invite_not_found', reason: 'invite not found' });
      }
      const inviteExpired = invite.expires_at ? new Date(invite.expires_at).getTime() < Date.now() : false;
      if (inviteExpired) {
        return jsonResponse(400, { ok: false, code: 'invite_expired', reason: 'invite expired' });
      }
      const { data: membership, error: membershipError } = await service
        .from('memberships')
        .upsert({
          organization_id: invite.organization_id,
          user_id: ctx.userId,
          status: 'active',
          organization_role: invite.role ?? 'member',
          role: invite.role === 'admin' || invite.role === 'owner' ? 'admin' : 'member',
        }, { onConflict: 'organization_id,user_id' })
        .select('*')
        .single();
      if (membershipError) throw membershipError;
      await service
        .from('organization_invites')
        .update({
          accepted_by_user_id: ctx.userId,
          accepted_at: new Date().toISOString(),
        })
        .eq('id', invite.id);
      await service
        .from('users')
        .update({
          current_organization_id: invite.organization_id,
          current_unit_id: invite.unit_id || null,
          last_context_changed_at: new Date().toISOString(),
        })
        .eq('id', ctx.userId);
      await enqueueDispatch('organization_invite_accepted', invite.organization_id, invite.id, [ctx.userId]);
      return jsonResponse(200, { ok: true, result: membership });
    }

    if (route === 'listJoinRequests') {
      ensureManager(ctx);
      const { data } = await service
        .from('join_requests')
        .select('*,users(id,email,display_name)')
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    if (route === 'approveJoinRequest' || route === 'rejectJoinRequest') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const joinRequestId = asString(payload.joinRequestId);
      const nextStatus = route === 'approveJoinRequest' ? 'active' : 'revoked';
      const { data: requestRow } = await service
        .from('join_requests')
        .select('*')
        .eq('id', joinRequestId)
        .eq('organization_id', ctx.orgId)
        .maybeSingle();
      if (!requestRow) {
        return jsonResponse(404, { ok: false, code: 'join_request_not_found', reason: 'join request not found' });
      }
      await service
        .from('join_requests')
        .update({
          status: nextStatus,
          reviewed_by_membership_id: ctx.membershipId,
          reviewed_at: new Date().toISOString(),
        })
        .eq('id', joinRequestId);
      const membershipPatch = {
        organization_id: ctx.orgId,
        user_id: requestRow.user_id,
        status: nextStatus,
        organization_role: 'member',
        role: 'member',
      };
      await service.from('memberships').upsert(membershipPatch, { onConflict: 'organization_id,user_id' });
      if (nextStatus === 'active') {
        await enqueueDispatch('join_request_approved', ctx.orgId, joinRequestId, [requestRow.user_id]);
      }
      return jsonResponse(200, { ok: true, result: { success: true, status: nextStatus } });
    }

    if (route === 'createOrganizationInvite') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const { data, error } = await service
        .from('organization_invites')
        .insert({
          organization_id: ctx.orgId,
          unit_id: asString(payload.unitId) || null,
          invite_label: asString(payload.inviteLabel) || null,
          role: asString(payload.role) || 'member',
          expires_at: asString(payload.expiresAt) || null,
          created_by_membership_id: ctx.membershipId,
        })
        .select('*')
        .single();
      if (error) throw error;
      return jsonResponse(201, { ok: true, result: data });
    }

    if (route === 'listOrganizationInvites') {
      ensureManager(ctx);
      const { data } = await service
        .from('organization_invites')
        .select('*')
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, { ok: true, result: data ?? [] });
    }

    ensureSignedIn(ctx);

    if (route === 'listUnits') {
      const access = await loadUnitAccessContext(service, ctx);
      return jsonResponse(200, {
        ok: true,
        result: filterAccessibleUnits(access.units, access.accessibleUnitIds),
      });
    }

    if (route === 'listUnitMemberships') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const unitId = asString(payload.unitId);
      if (!unitId) {
        return jsonResponse(400, { ok: false, code: 'unit_required', reason: 'unit required' });
      }
      const { data } = await service
        .from('unit_memberships')
        .select('id,unit_id,user_id,role,status,users(id,email,display_name)')
        .eq('unit_id', unitId)
        .order('created_at', { ascending: true });
      const mapped = (data ?? []).map((row) => {
        const user = firstRelation(row.users);
        return {
          id: row.id,
          unitId: row.unit_id,
          userId: row.user_id,
          role: row.role,
          status: row.status,
          email: user?.email ?? '',
          displayName: user?.display_name ?? user?.email ?? '',
        };
      });
      return jsonResponse(200, { ok: true, result: mapped });
    }

    if (route === 'changeCurrentUnit') {
      const payload = asMap(args[0]);
      const unitId = asString(payload.unitId);
      if (!unitId) {
        return jsonResponse(400, { ok: false, code: 'unit_required', reason: 'unit required' });
      }
      const access = await loadUnitAccessContext(service, ctx);
      const { data: unit } = await service
        .from('units')
        .select('id,organization_id')
        .eq('id', unitId)
        .eq('organization_id', ctx.orgId)
        .maybeSingle();
      if (!unit) {
        return jsonResponse(404, { ok: false, code: 'unit_not_found', reason: 'unit not found' });
      }
      ensureUnitAccessible(access, unitId);
      await service
        .from('users')
        .update({
          current_organization_id: ctx.orgId,
          current_unit_id: unitId,
          last_context_changed_at: new Date().toISOString(),
        })
        .eq('id', ctx.userId);
      return jsonResponse(200, { ok: true, result: { success: true, unitId } });
    }

    if (route === 'createUnit') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const name = asString(payload.name);
      if (!name) {
        return jsonResponse(400, { ok: false, code: 'name_required', reason: 'name required' });
      }
      const { data, error } = await service
        .from('units')
        .insert({
          organization_id: ctx.orgId,
          parent_unit_id: asString(payload.parentUnitId) || null,
          name,
          sort_order: Number(payload.sortOrder ?? 0),
          is_active: payload.isActive !== false,
        })
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('unit.create', ctx, 'unit', data.id, { name, parentUnitId: payload.parentUnitId ?? null });
      return jsonResponse(201, { ok: true, result: data });
    }

    if (route === 'updateUnit') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const unitId = asString(payload.unitId);
      const patch: Record<string, unknown> = {};
      if (payload.name !== undefined) patch.name = asString(payload.name);
      if (payload.parentUnitId !== undefined) patch.parent_unit_id = asString(payload.parentUnitId) || null;
      if (payload.sortOrder !== undefined) patch.sort_order = Number(payload.sortOrder ?? 0);
      if (payload.isActive !== undefined) patch.is_active = payload.isActive === true;
      const { data, error } = await service
        .from('units')
        .update(patch)
        .eq('id', unitId)
        .eq('organization_id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('unit.update', ctx, 'unit', unitId, patch);
      return jsonResponse(200, { ok: true, result: data });
    }

    if (route === 'assignUnitMember') {
      ensureManager(ctx);
      const payload = asMap(args[0]);
      const unitId = asString(payload.unitId);
      const userId = asString(payload.userId);
      const role = asString(payload.role) === 'manager' ? 'manager' : 'member';
      const status = asString(payload.status) || 'active';
      if (!unitId || !userId) {
        return jsonResponse(400, { ok: false, code: 'invalid_input', reason: 'unitId and userId required' });
      }
      const { data, error } = await service
        .from('unit_memberships')
        .upsert({
          unit_id: unitId,
          user_id: userId,
          role,
          status,
          granted_by_membership_id: ctx.membershipId,
        }, { onConflict: 'unit_id,user_id' })
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('unit.membership.assign', ctx, 'unit', unitId, { userId, role, status });
      return jsonResponse(200, { ok: true, result: data });
    }

    if (route === 'listMyTasks') {
      const access = await loadUnitAccessContext(service, ctx);
      const { data } = await service
        .from('tasks')
        .select(
          'id,title,description,status,priority,due_at,created_at,updated_at,unit_id,task_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes))',
        )
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, {
        ok: true,
        result: (data ?? []).filter((row) => isSharedResourceAccessible(access, asString(row.unit_id))),
      });
    }

    if (route === 'listCreatedTasks') {
      const access = await loadUnitAccessContext(service, ctx);
      const { data } = await service
        .from('tasks')
        .select(
          'id,title,description,status,priority,due_at,created_at,updated_at,unit_id,task_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes))',
        )
        .eq('organization_id', ctx.orgId)
        .eq('created_by_user_id', ctx.userId)
        .order('created_at', { ascending: false });
      return jsonResponse(200, {
        ok: true,
        result: (data ?? []).filter((row) => isSharedResourceAccessible(access, asString(row.unit_id))),
      });
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
      const access = await loadUnitAccessContext(service, ctx);
      const { data } = await service
        .from('tasks')
        .select(
          '*,task_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes)),task_assignees(user_id,users(id,email,display_name))',
        )
        .eq('id', taskId)
        .eq('organization_id', ctx.orgId)
        .maybeSingle();
      if (data && !isSharedResourceAccessible(access, asString(data.unit_id))) {
        return jsonResponse(403, { ok: false, code: 'task_forbidden', reason: 'forbidden' });
      }
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
          unit_id: asString(payload.unitId) || ctx.currentUnitId || null,
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
      const hasOwn = (key: string) => Object.prototype.hasOwnProperty.call(payload, key);
      const title = asString(payload.title);
      const description = asString(payload.description);
      const status = asString(payload.status);
      const priority = asString(payload.priority);
      const dueAtMs = Number(payload.dueAtMs ?? 0);

      if (hasOwn('title')) patch.title = title;
      if (hasOwn('description')) patch.description = description;
      if (hasOwn('status') && status) patch.status = status;
      if (hasOwn('unitId')) patch.unit_id = asString(payload.unitId) || null;
      if (hasOwn('priority')) {
        patch.priority = priority === 'low' || priority === 'high' ? priority : 'medium';
      }
      if (hasOwn('dueAtMs')) {
        patch.due_at = Number.isFinite(dueAtMs) && dueAtMs > 0
          ? new Date(dueAtMs).toISOString()
          : null;
      }

      if (Object.keys(patch).length === 0 && !hasOwn('assigneeUserIds')) {
        return jsonResponse(200, { ok: true, result: {} });
      }

      let data: Record<string, unknown> | null = null;
      if (Object.keys(patch).length > 0) {
        const updateResult = await service
          .from('tasks')
          .update(patch)
          .eq('id', taskId)
          .eq('organization_id', ctx.orgId)
          .select('*')
          .single();
        if (updateResult.error) throw updateResult.error;
        data = updateResult.data;
      }

      if (hasOwn('assigneeUserIds')) {
        const assignees = asList(payload.assigneeUserIds)
          .map((v) => asString(v))
          .filter((v) => v.length > 0);
        await service.from('task_assignees').delete().eq('task_id', taskId);
        if (assignees.length > 0) {
          await service.from('task_assignees').insert(
            assignees.map((userId) => ({
              task_id: taskId,
              user_id: userId,
            })),
          );
        }
      }

      await insertAuditLog('task.update', ctx, 'task', taskId, {
        ...patch,
        ...(hasOwn('assigneeUserIds') ? { assigneeUserIds: payload.assigneeUserIds } : {}),
      });

      if (data == null) {
        const selected = await service
          .from('tasks')
          .select('*')
          .eq('id', taskId)
          .eq('organization_id', ctx.orgId)
          .single();
        if (selected.error) throw selected.error;
        data = selected.data;
      }

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
      const currentUnitId = asString(payload.currentUnitId) || ctx.currentUnitId;
      const tab = asString(payload.tab) || 'current';
      const scope = asString(payload.scope) || 'shared';
      const keyword = asString(payload.keyword).toLowerCase();
      const unreadOnly = asBool(payload.unreadOnly);
      const access = await loadUnitAccessContext(service, ctx);
      const effectiveCurrentUnitId = ensureUnitAccessible(access, currentUnitId);
      const selectedUnitIds = effectiveCurrentUnitId
        ? (
          tab === 'upper'
            ? getAncestorUnitIds(access.units, effectiveCurrentUnitId)
            : tab === 'lower'
            ? getDescendantUnitIds(access.units, effectiveCurrentUnitId)
            : [effectiveCurrentUnitId]
        )
          .filter((unitId) => access.accessibleUnitIds.has(unitId))
        : [];

      let query = service
        .from('messages')
        .select('id,title,body,priority,is_pinned,folder_id,unit_id,message_scope,author_user_id,recipient_user_id,created_at,updated_at')
        .eq('organization_id', ctx.orgId)
        .eq('message_scope', scope === 'direct' ? 'direct' : 'shared')
        .order('is_pinned', { ascending: false })
        .order('created_at', { ascending: false });
      if (folderId) query = query.eq('folder_id', folderId);
      if (scope !== 'direct' && selectedUnitIds.length > 0) {
        query = query.in('unit_id', selectedUnitIds);
      }
      const { data } = await query;
      const messages = (data ?? []).filter((row) => {
        if ((row.message_scope ?? 'shared') === 'direct') {
          return row.author_user_id === ctx.userId || row.recipient_user_id === ctx.userId;
        }
        return isSharedResourceAccessible(access, asString(row.unit_id));
      });

      if (messages.length === 0) {
        return jsonResponse(200, { ok: true, result: [] });
      }

      const messageIds = messages.map((row) => row.id).filter((id) => !!id);
      const { data: readRows } = await service
        .from('message_reads')
        .select('message_id,membership_id,user_id')
        .in('message_id', messageIds);
      const readSharedIds = new Set(
        (readRows ?? [])
          .filter((row) => row.membership_id === ctx.membershipId)
          .map((row) => row.message_id),
      );
      const readDirectIds = new Set(
        (readRows ?? [])
          .filter((row) => row.user_id === ctx.userId)
          .map((row) => row.message_id),
      );

      const mapped = messages
        .map((row) => {
          const currentScope = asString(row.message_scope) || 'shared';
          const isRead = currentScope === 'direct'
            ? readDirectIds.has(row.id)
            : readSharedIds.has(row.id);
          return {
            ...row,
            isRead,
            isDirect: currentScope === 'direct',
          };
        })
        .filter((row) => {
          if (keyword.length === 0) return true;
          return asString(row.title).toLowerCase().includes(keyword)
            || asString(row.body).toLowerCase().includes(keyword);
        })
        .filter((row) => (unreadOnly ? !row.isRead : true));

      return jsonResponse(200, { ok: true, result: mapped });
    }

    if (route === 'getMessageById') {
      const messageId = asString(args[0]);
      const access = await loadUnitAccessContext(service, ctx);
      const { data: message } = await service
        .from('messages')
        .select(
          '*,message_attachments(attachment_id,attachments(id,file_name,content_type,size_bytes))',
        )
        .eq('organization_id', ctx.orgId)
        .eq('id', messageId)
        .maybeSingle();
      if (message && asString(message.message_scope) === 'direct') {
        const authorUserId = asString(message.author_user_id);
        const recipientUserId = asString(message.recipient_user_id);
        if (authorUserId !== ctx.userId && recipientUserId !== ctx.userId) {
          return jsonResponse(403, { ok: false, code: 'message_forbidden', reason: 'forbidden' });
        }
      } else if (message && !isSharedResourceAccessible(access, asString(message.unit_id))) {
        return jsonResponse(403, { ok: false, code: 'message_forbidden', reason: 'forbidden' });
      }
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
      const scope = asString(payload.scope) === 'direct' ? 'direct' : 'shared';
      const unitId = asString(payload.unitId) || ctx.currentUnitId || null;
      const access = await loadUnitAccessContext(service, ctx);
      const recipientUserIds = asList(payload.recipientUserIds)
        .map((value) => asString(value))
        .filter((value) => value.length > 0);

      if (scope === 'direct' && recipientUserIds.length == 0) {
        return jsonResponse(400, { ok: false, code: 'recipient_required', reason: 'recipient required' });
      }
      if (scope === 'shared') {
        ensureUnitAccessible(access, asString(unitId));
      }

      const targetRows = scope === 'direct'
        ? recipientUserIds.map((recipientUserId) => ({
          organization_id: ctx.orgId,
          folder_id: null,
          unit_id: unitId,
          message_scope: 'direct',
          author_membership_id: ctx.membershipId,
          author_user_id: ctx.userId,
          recipient_user_id: recipientUserId,
          title,
          body: bodyText,
        }))
        : [{
          organization_id: ctx.orgId,
          folder_id: asString(payload.folderId) || null,
          unit_id: unitId,
          message_scope: 'shared',
          author_membership_id: ctx.membershipId,
          author_user_id: ctx.userId,
          recipient_user_id: null,
          title,
          body: bodyText,
        }];

      const { data: insertedRows, error } = await service
        .from('messages')
        .insert(targetRows)
        .select('*');
      if (error) throw error;
      const message = (insertedRows ?? [])[0];
      if (!message) {
        throw new Error('message_create_failed');
      }

      const targetUsers = scope === 'direct'
        ? recipientUserIds
        : (
          await service
            .from('memberships')
            .select('user_id')
            .eq('organization_id', ctx.orgId)
            .eq('status', 'active')
        ).data?.map((row) => row.user_id) ?? [];

      await enqueueDispatch(
        scope === 'direct' ? 'new_direct_message' : 'new_message',
        ctx.orgId,
        message.id,
        targetUsers.filter((userId) => userId && userId !== ctx.userId),
      );
      await dispatchQueuedNotifications({
        sourceId: message.id,
        eventType: scope === 'direct' ? 'new_direct_message' : 'new_message',
      }).catch(() => undefined);

      await insertAuditLog('message.create', ctx, scope === 'direct' ? 'direct_message' : 'message', message.id, {
        title,
        scope,
        unitId,
        recipientUserIds,
      });
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
      const access = await loadUnitAccessContext(service, ctx);
      const { data: message } = await service
        .from('messages')
        .select('id,message_scope,unit_id,author_user_id,recipient_user_id')
        .eq('organization_id', ctx.orgId)
        .eq('id', messageId)
        .maybeSingle();
      if (!message) {
        return jsonResponse(404, { ok: false, code: 'message_not_found', reason: 'message not found' });
      }
      const isDirect = asString(message.message_scope) === 'direct';
      if (isDirect) {
        const authorUserId = asString(message.author_user_id);
        const recipientUserId = asString(message.recipient_user_id);
        if (authorUserId !== ctx.userId && recipientUserId !== ctx.userId) {
          return jsonResponse(403, { ok: false, code: 'message_forbidden', reason: 'forbidden' });
        }
      } else if (!isSharedResourceAccessible(access, asString(message.unit_id))) {
        return jsonResponse(403, { ok: false, code: 'message_forbidden', reason: 'forbidden' });
      }

      if (route === 'toggleMemoRead') {
        const { data: existingRead } = await service
          .from('message_reads')
          .select('id')
          .eq('message_id', messageId)
          .eq(isDirect ? 'user_id' : 'membership_id', isDirect ? ctx.userId : ctx.membershipId)
          .maybeSingle();
        if (existingRead) {
          await service.from('message_reads').delete().eq('id', existingRead.id);
          return jsonResponse(200, { ok: true, result: { isRead: false } });
        }
      }

      await service.from('message_reads').upsert({
        message_id: messageId,
        membership_id: isDirect ? null : ctx.membershipId,
        user_id: isDirect ? ctx.userId : null,
        read_at: new Date().toISOString(),
      });
      return jsonResponse(200, { ok: true, result: { isRead: true } });
    }

    if (route === 'markMemosReadBulk') {
      const messageIds = asList(args[0]).map((x) => asString(x)).filter((x) => x);
      const access = await loadUnitAccessContext(service, ctx);
      for (const messageId of messageIds) {
        const { data: message } = await service
          .from('messages')
          .select('message_scope,unit_id,author_user_id,recipient_user_id')
          .eq('organization_id', ctx.orgId)
          .eq('id', messageId)
          .maybeSingle();
        const isDirect = asString(message?.message_scope) === 'direct';
        if (isDirect) {
          const authorUserId = asString(message?.author_user_id);
          const recipientUserId = asString(message?.recipient_user_id);
          if (authorUserId !== ctx.userId && recipientUserId !== ctx.userId) {
            continue;
          }
        } else if (!isSharedResourceAccessible(access, asString(message?.unit_id))) {
          continue;
        }
        await service.from('message_reads').upsert({
          message_id: messageId,
          membership_id: isDirect ? null : ctx.membershipId,
          user_id: isDirect ? ctx.userId : null,
          read_at: new Date().toISOString(),
        });
      }
      return jsonResponse(200, { ok: true, result: { updated: messageIds.length } });
    }

    if (route === 'listActiveFolders' || (segments[0] === 'folders' && route === 'folders')) {
      const access = await loadUnitAccessContext(service, ctx);
      const { data } = await service
        .from('folders')
        .select('*')
        .eq('organization_id', ctx.orgId)
        .eq('is_active', true)
        .order('sort_order', { ascending: true });
      return jsonResponse(200, {
        ok: true,
        result: (data ?? []).filter((row) => isSharedResourceAccessible(access, asString(row.unit_id))),
      });
    }

    if (segments[0] === 'folders' && segments.length === 1 && method === 'POST') {
      ensureManager(ctx);
      const name = asString(body.name);
      if (!name) return jsonResponse(400, { ok: false, code: 'name_required', reason: 'folder name required' });
      const { data: inserted, error } = await service
        .from('folders')
        .insert({
          organization_id: ctx.orgId,
          unit_id: asString(body.unitId) || ctx.currentUnitId || null,
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

    if (segments[0] === 'templates' && segments.length === 2 && method === 'PATCH') {
      ensureManager(ctx);
      const templateId = segments[1];
      const patch: Record<string, unknown> = {};
      if (body.name !== undefined) patch.name = asString(body.name);
      if (body.titleFormat !== undefined) patch.title_format = asString(body.titleFormat);
      if (body.bodyFormat !== undefined) patch.body_format = asString(body.bodyFormat);
      const { data, error } = await service
        .from('templates')
        .update(patch)
        .eq('id', templateId)
        .eq('organization_id', ctx.orgId)
        .select('*')
        .single();
      if (error) throw error;
      await insertAuditLog('template.update', ctx, 'template', templateId, patch);
      return jsonResponse(200, { ok: true, result: data });
    }

    if (segments[0] === 'templates' && segments.length === 2 && method === 'DELETE') {
      ensureManager(ctx);
      const templateId = segments[1];
      const { error } = await service
        .from('templates')
        .delete()
        .eq('id', templateId)
        .eq('organization_id', ctx.orgId);
      if (error) throw error;
      await insertAuditLog('template.delete', ctx, 'template', templateId, {});
      return jsonResponse(200, { ok: true, result: { deleted: true } });
    }

    if (route === 'listActiveUsers') {
      ensureManager(ctx);
      const { data } = await service
        .from('memberships')
        .select('id,user_id,role,organization_role,status,users(id,email,display_name)')
        .eq('organization_id', ctx.orgId)
        .eq('status', 'active');
      const mapped = (data ?? []).map((row) => {
        const user = firstRelation(row.users);
        return {
          membershipId: row.id,
          userId: row.user_id,
          role: asString(row.organization_role) || mapLegacyRole(asString(row.role)),
          status: row.status,
          email: user?.email ?? '',
          displayName: user?.display_name ?? user?.email ?? '',
        };
      });
      return jsonResponse(200, { ok: true, result: mapped });
    }

    if (route === 'searchContent') {
      ensureSignedIn(ctx);
      const payload = asMap(args[0]);
      const query = asString(payload.query);
      const tab = asString(payload.tab) || 'all';
      const currentUnitId = asString(payload.currentUnitId) || ctx.currentUnitId;
      const terms = query
        .split(/\s+/)
        .map((term) => term.trim().toLowerCase())
        .filter((term) => term.length > 0);
      const access = await loadUnitAccessContext(service, ctx);
      const effectiveCurrentUnitId = currentUnitId && access.accessibleUnitIds.has(currentUnitId)
        ? currentUnitId
        : ctx.currentUnitId;
      const descendantUnitIds = effectiveCurrentUnitId
        ? getDescendantUnitIds(access.units, effectiveCurrentUnitId).filter((unitId) => access.accessibleUnitIds.has(unitId))
        : Array.from(access.accessibleUnitIds);

      const matchesAll = (...values: unknown[]) => {
        if (terms.length === 0) return true;
        const haystack = values
          .map((value) => asString(value))
          .filter((value) => value.length > 0)
          .join(' ')
          .toLowerCase();
        return terms.every((term) => haystack.includes(term));
      };

      const tasksPromise = tab === 'all' || tab === 'tasks'
        ? service
          .from('tasks')
          .select('id,title,description,status,due_at,unit_id,units(name,path_text)')
          .eq('organization_id', ctx.orgId)
          .order('updated_at', { ascending: false })
          .limit(50)
        : Promise.resolve({ data: [] as Record<string, unknown>[] });

      const messagesPromise = tab === 'all' || tab === 'messages'
        ? service
          .from('messages')
          .select('id,title,body,message_scope,unit_id,folder_id,author_user_id,recipient_user_id,created_at,units(name,path_text),folders(name),users!messages_author_user_id_fkey(display_name,email)')
          .eq('organization_id', ctx.orgId)
          .order('created_at', { ascending: false })
          .limit(80)
        : Promise.resolve({ data: [] as Record<string, unknown>[] });

      const usersPromise = tab === 'all' || tab === 'users'
        ? service
          .from('memberships')
          .select('user_id,organization_role,role,status,users(id,email,display_name,profile_image_url,current_unit_id)')
          .eq('organization_id', ctx.orgId)
          .eq('status', 'active')
        : Promise.resolve({ data: [] as Record<string, unknown>[] });

      const [tasksResult, messagesResult, usersResult] = await Promise.all([
        tasksPromise,
        messagesPromise,
        usersPromise,
      ]);

      const tasks = (tasksResult.data ?? [])
        .map((row) => {
          const unit = firstRelation(row.units as Record<string, unknown> | Array<Record<string, unknown>> | null);
          return {
            id: row.id,
            title: asString(row.title),
            description: asString(row.description),
            status: asString(row.status),
            dueAt: row.due_at ?? null,
            unitId: asString(row.unit_id),
            unitName: unit?.name ?? '',
            unitPathText: unit?.path_text ?? '',
          };
        })
        .filter((row) => (
          descendantUnitIds.length == 0
            || row.unitId.length == 0
            || descendantUnitIds.includes(row.unitId)
        ))
        .filter((row) => matchesAll(row.title, row.description, row.unitName, row.unitPathText));

      const messages = (messagesResult.data ?? [])
        .filter((row) => {
          const scope = asString(row.message_scope) || 'shared';
          if (scope === 'direct') {
            return row.author_user_id === ctx.userId || row.recipient_user_id === ctx.userId;
          }
          return descendantUnitIds.length == 0 || descendantUnitIds.includes(asString(row.unit_id));
        })
        .map((row) => {
          const unit = firstRelation(row.units as Record<string, unknown> | Array<Record<string, unknown>> | null);
          const folder = firstRelation(row.folders as Record<string, unknown> | Array<Record<string, unknown>> | null);
          const author = firstRelation(row.users as Record<string, unknown> | Array<Record<string, unknown>> | null);
          return {
            id: row.id,
            title: asString(row.title),
            body: asString(row.body),
            scope: asString(row.message_scope) || 'shared',
            folderName: folder?.name ?? '',
            unitId: asString(row.unit_id),
            unitName: unit?.name ?? '',
            unitPathText: unit?.path_text ?? '',
            authorName: author?.display_name ?? author?.email ?? '',
          };
        })
        .filter((row) => matchesAll(row.title, row.body, row.folderName, row.unitName, row.authorName));

      const users = (usersResult.data ?? [])
        .map((row) => {
          const user = firstRelation(row.users as Record<string, unknown> | Array<Record<string, unknown>> | null);
          const currentUnit = access.units.find((unit) => unit.id === asString(user?.current_unit_id));
          return {
            userId: row.user_id,
            displayName: user?.display_name ?? user?.email ?? '',
            email: user?.email ?? '',
            organizationRole: asString(row.organization_role) || mapLegacyRole(asString(row.role)),
            currentUnitName: currentUnit?.name ?? '',
            avatarUrl: user?.profile_image_url ?? '',
          };
        })
        .filter((row) => matchesAll(row.displayName, row.email, row.organizationRole, row.currentUnitName));

      return jsonResponse(200, {
        ok: true,
        result: {
          tasks,
          messages,
          users,
        },
      });
    }

    if (route === 'getUserProfile') {
      ensureSignedIn(ctx);
      const payload = asMap(args[0]);
      const userId = asString(payload.userId);
      if (!userId) {
        return jsonResponse(400, { ok: false, code: 'user_required', reason: 'user required' });
      }

      const { data: membership } = await service
        .from('memberships')
        .select('user_id,organization_role,role,status')
        .eq('organization_id', ctx.orgId)
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();
      if (!membership) {
        return jsonResponse(404, { ok: false, code: 'user_not_found', reason: 'user not found' });
      }

      const { data: user } = await service
        .from('users')
        .select('id,email,display_name,profile_image_url,current_unit_id')
        .eq('id', userId)
        .maybeSingle();
      if (!user) {
        return jsonResponse(404, { ok: false, code: 'user_not_found', reason: 'user not found' });
      }

      const { data: unitRows } = await service
        .from('unit_memberships')
        .select('unit_id,role,status,units(id,name,path_text)')
        .eq('user_id', userId)
        .eq('status', 'active');

      const currentUnitId = asString(user.current_unit_id);
      const membershipsMapped = (unitRows ?? []).map((row) => {
        const unit = firstRelation(row.units as Record<string, unknown> | Array<Record<string, unknown>> | null);
        return {
          unitId: row.unit_id,
          unitName: unit?.name ?? '',
          unitPathText: unit?.path_text ?? unit?.name ?? '',
          role: asString(row.role) || 'member',
          isCurrent: asString(row.unit_id) == currentUnitId,
        };
      });
      const currentUnit = membershipsMapped.find((row) => row.isCurrent)
        ?? membershipsMapped[0]
        ?? null;

      return jsonResponse(200, {
        ok: true,
        result: {
          userId: user.id,
          displayName: user.display_name ?? user.email ?? '',
          email: user.email ?? '',
          avatarUrl: user.profile_image_url ?? '',
          organizationRole: asString(membership.organization_role) || mapLegacyRole(asString(membership.role)),
          currentUnitName: currentUnit?.unitName ?? '',
          currentUnitPathText: currentUnit?.unitPathText ?? '',
          unitMemberships: membershipsMapped,
        },
      });
    }

    if (route === 'adminListUsers') {
      ensureManager(ctx);
      const { data } = await service
        .from('memberships')
        .select('id,organization_id,user_id,role,organization_role,status,users(id,email,display_name,created_at)')
        .eq('organization_id', ctx.orgId)
        .order('created_at', { ascending: false });
      const rows = (data ?? []).map((row) => {
        const user = firstRelation(row.users);
        return {
          membershipId: row.id,
          userId: row.user_id,
          email: user?.email ?? '',
          displayName: user?.display_name ?? user?.email ?? '',
          role: asString(row.organization_role) || mapLegacyRole(asString(row.role)),
          status: row.status,
          createdAt: user?.created_at ?? null,
        };
      });
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
        const normalizedRole = targetRole === 'owner' || targetRole === 'admin' ? targetRole : 'member';
        await service
          .from('memberships')
          .update({
            organization_role: normalizedRole,
            role: normalizedRole === 'owner' || normalizedRole === 'admin' ? 'admin' : 'member',
          })
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
      const access = await loadUnitAccessContext(service, ctx);
      const { data: attachment } = await service
        .from('attachments')
        .select('*')
        .eq('id', attachmentId)
        .eq('organization_id', ctx.orgId)
        .maybeSingle();
      if (!attachment) {
        return jsonResponse(404, { ok: false, code: 'attachment_not_found', reason: 'not found' });
      }
      if (attachment.message_id) {
        const { data: message } = await service
          .from('messages')
          .select('id,message_scope,author_user_id,recipient_user_id,unit_id')
          .eq('id', attachment.message_id)
          .eq('organization_id', ctx.orgId)
          .maybeSingle();
        const isDirect = asString(message?.message_scope) === 'direct';
        if (
          !message
          || (isDirect && message.author_user_id !== ctx.userId && message.recipient_user_id !== ctx.userId)
          || (!isDirect && !isSharedResourceAccessible(access, asString(message.unit_id)))
        ) {
          return jsonResponse(403, { ok: false, code: 'attachment_forbidden', reason: 'forbidden' });
        }
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
      await insertAuditLog('message.pin.toggle', ctx, 'message', messageId, { isPinned: data?.is_pinned ?? false });
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

      const readUserIds = new Set((reads ?? []).map((r) => firstRelation(r.memberships)?.user_id).filter(Boolean));
      const readUsers = (reads ?? []).map((r) => {
        const membership = firstRelation(r.memberships);
        const user = firstRelation(membership?.users);
        return {
          userId: membership?.user_id,
          email: user?.email ?? '',
          displayName: user?.display_name ?? '',
        };
      });
      const unreadUsers = (members ?? [])
        .filter((m) => !readUserIds.has(m.user_id))
        .map((m) => {
          const user = firstRelation(m.users);
          return {
            userId: m.user_id,
            email: user?.email ?? '',
            displayName: user?.display_name ?? '',
          };
        });

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
    const status = ['forbidden', 'access_denied', 'unit_forbidden', 'message_forbidden', 'task_forbidden', 'attachment_forbidden']
      .includes(message)
      ? 403
      : 500;
    return jsonResponse(status, {
      ok: false,
      code: message,
      reason: message,
    });
  }
});
